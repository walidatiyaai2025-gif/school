#!/usr/bin/env python3
"""Build a signed, full-payload ZIP update from one tested exact Git commit.

The private Ed25519 secret is read exclusively from the CI secret environment.
An update MUST specify a genuinely supported previous release; callers must
run the extracted upgrade ZIP through acceptance tests against that release.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile

from build_setup import ROOT, files_to_package, sha256_bytes


def _load_key_php() -> str:
    """Validate a canonical Ed25519 secret or derive it from a 32-byte seed.

    Both representations are private. Do not emit or package either one.
    For a 64-byte secret, validate the embedded public half against its seed:
    libsodium would otherwise accept a mismatched secret that can sign data
    which the corresponding public key cannot verify.
    """
    return (
        '$raw=base64_decode(trim((string)getenv("SCHOOLPDF_RELEASE_ED25519_KEY_B64")),true);'
        'if($raw===false)exit(4);'
        'if(strlen($raw)===SODIUM_CRYPTO_SIGN_SEEDBYTES){'
        '$k=sodium_crypto_sign_secretkey(sodium_crypto_sign_seed_keypair($raw));'
        '}elseif(strlen($raw)===SODIUM_CRYPTO_SIGN_SECRETKEYBYTES){'
        '$k=$raw;'
        '$seed=substr($k,0,SODIUM_CRYPTO_SIGN_SEEDBYTES);'
        '$canonical=sodium_crypto_sign_secretkey(sodium_crypto_sign_seed_keypair($seed));'
        'if(!hash_equals($canonical,$k))exit(5);'
        '}else{exit(4);}'
    )


def signing_key():
    if not os.environ.get('SCHOOLPDF_RELEASE_ED25519_KEY_B64', '').strip():
        raise RuntimeError('BLOCKED: protected GitHub release signing key is not configured')
    php = _load_key_php() + (
        'echo base64_encode(sodium_crypto_sign_publickey_from_secretkey($k));'
    )
    p = subprocess.run(['php', '-r', php], capture_output=True, text=True, timeout=15)
    try:
        valid = p.returncode == 0 and len(base64.b64decode(p.stdout, validate=True)) == 32
    except (ValueError, base64.binascii.Error):
        valid = False
    if not valid:
        raise RuntimeError(
            'BLOCKED: invalid protected Ed25519 signer; supply a base64 32-byte '
            'seed or a canonical base64 64-byte secret in GitHub Actions secrets'
        )
    return p.stdout


def sign(raw: bytes) -> str:
    # Always validate before signing; never use a corrupt 64-byte secret.
    signing_key()
    php = _load_key_php() + (
        'echo base64_encode(sodium_crypto_sign_detached(stream_get_contents(STDIN),$k));'
    )
    p = subprocess.run(['php', '-r', php], input=raw, capture_output=True, timeout=15)
    if p.returncode:
        raise RuntimeError('BLOCKED: release manifest signing failed')
    signature = p.stdout.decode('ascii')
    if len(base64.b64decode(signature, validate=True)) != 64:
        raise RuntimeError('BLOCKED: malformed release signature')
    return signature

def main() -> int:
    parser=argparse.ArgumentParser()
    parser.add_argument('--root',type=Path,default=ROOT)
    parser.add_argument('--git-sha',required=True)
    parser.add_argument('--from-version',required=True,
                        help='Specific previous version with a CI-proven supported upgrade')
    parser.add_argument('--verified-base-lock-sha',required=True,
                        help='SHA256 of supported base composer.lock from genuine previous release')
    args=parser.parse_args()
    root=args.root.resolve()
    version=(root/'VERSION').read_text().strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or \
       not re.fullmatch(r'\d+\.\d+\.\d+',args.from_version) or \
       not re.fullmatch(r'[0-9a-f]{40}',args.git_sha) or \
       not re.fullmatch(r'[0-9a-f]{64}',args.verified_base_lock_sha):
        parser.error('Exact versions, previous lock SHA and Git commit are mandatory')
    if tuple(map(int,args.from_version.split('.')))>=tuple(map(int,version.split('.'))):
        parser.error('Update must advance version')
    public=signing_key()
    backend=root/'backend'
    current_lock=hashlib.sha256((backend/'composer.lock').read_bytes()).hexdigest()
    if current_lock!=args.verified_base_lock_sha:
        raise RuntimeError('BLOCKED: production dependencies changed; requires a separately verified upgrade path')
    payload={}
    for source,name in files_to_package(backend):
        if name=='.env.example' or name.startswith('bootstrap/cache/'):
            continue
        payload[name]=source.read_bytes()
    files=[{'path':name,'sha256':sha256_bytes(blob),'bytes':len(blob)}
           for name,blob in sorted(payload.items())]
    notes=(root/'setup/RELEASE_NOTES_AR.md').read_text()
    manifest={'kind':'schoolpdf-update','project':'School PDF',
        'target_version':version,'minimum_supported_version':args.from_version,
        'supported_base_versions':[args.from_version],'min_php':'8.2',
        'git_sha':args.git_sha,'release_notes':notes,
        'production_lock_sha256':current_lock,'files':files}
    raw=json.dumps(manifest,sort_keys=True,ensure_ascii=False,separators=(',',':')).encode()
    signature=sign(raw)
    out=root/'setup/output'
    out.mkdir(parents=True,exist_ok=True)
    name=f'SchoolPDF-Update-v{version}.zip'
    path=out/name
    temp=out/(name+'.partial')
    try:
        with zipfile.ZipFile(temp,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=7) as z:
            z.writestr('manifest.json',raw)
            z.writestr('signature.ed25519',signature)
            for filename,blob in sorted(payload.items()):
                z.writestr('payload/'+filename,blob)
        with zipfile.ZipFile(temp) as z:
            if z.testzip() is not None:
                raise RuntimeError('ZIP integrity failure')
            if z.read('manifest.json')!=raw:
                raise RuntimeError('Manifest extraction failure')
            if z.read('signature.ed25519')!=signature.encode():
                raise RuntimeError('Detached signature extraction failure')
        temp.replace(path)
        digest=hashlib.sha256(path.read_bytes()).hexdigest()
        (out/(name+'.sha256')).write_text(digest+'  '+name+'\n')
        (out/'SchoolPDF-Release-Public-Key.txt').write_text(public+'\n')
        print('SIGNED UPDATE ZIP GENERATED:',path)
        print('SHA256:',digest)
        return 0
    finally:
        temp.unlink(missing_ok=True)


if __name__=='__main__':
    try:
        raise SystemExit(main())
    except (RuntimeError,ValueError,OSError) as exc:
        print(str(exc),file=sys.stderr)
        raise SystemExit(2)
