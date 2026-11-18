#!/usr/bin/env python3
"""Create the cPanel one-ZIP installer from a *tested*, locked Laravel tree.

This builder intentionally refuses to invent a vendor directory, lockfile, CI result,
or release SHA. Run it in a build runner with Composer, not on production hosting.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PAYLOAD_DIRS = (
    'app', 'bootstrap', 'config', 'database/migrations', 'public',
    'resources', 'routes', 'vendor',
)
PAYLOAD_FILES = ('artisan', 'composer.json', 'composer.lock', '.env.example')
EMPTY_DIRS = (
    'bootstrap/cache', 'storage/app/private', 'storage/framework/cache/data',
    'storage/framework/sessions', 'storage/framework/views', 'storage/logs',
)
DENY_FILENAMES = {
    '.env', 'setup-access.key', 'install.lock', 'setup.mutex',
    'id_rsa', 'firebase-admin.json', 'firebase-service-account.json',
}
DENY_SUFFIXES = {'.pem', '.p8', '.p12', '.key', '.sqlite', '.log'}


def sha256_bytes(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()


def validate(root: Path, head: str, evidence_file: Path) -> list[str]:
    backend = root / 'backend'
    missing = []
    for p in (backend / 'composer.lock', backend / 'vendor/autoload.php',
              backend / 'vendor/composer/installed.php',
              backend / 'vendor/laravel/framework/src/Illuminate/Foundation/Application.php',
              backend / 'public/install.php', backend / 'bootstrap/app.php'):
        if not p.is_file() or not p.stat().st_size:
            missing.append(f'MISSING: {p.relative_to(root)}')
    if not re.fullmatch(r'[0-9a-f]{40}', head, flags=re.IGNORECASE):
        missing.append('MISSING: verified exact 40-character Git commit SHA')
    if (backend / '.env').exists():
        missing.append('REFUSED: backend/.env exists; production secrets must never be packaged')
    if (backend / 'setup-access.key').exists():
        missing.append('REFUSED: source installation access key already exists')
    if (backend / 'storage/app/private/install.lock').exists():
        missing.append('REFUSED: source is an already-installed site')
    installer_review_copy = root / 'setup/installer/install.php'
    if installer_review_copy.is_file() and (backend / 'public/install.php').is_file():
        if installer_review_copy.read_bytes() != (backend / 'public/install.php').read_bytes():
            missing.append('INSTALLER MISMATCH: setup/installer/install.php differs from backend/public/install.php')
    lock = backend / 'composer.lock'
    if lock.is_file():
        try:
            packages = json.loads(lock.read_text(encoding='utf-8')).get('packages', [])
            if not any(p.get('name') == 'laravel/framework' for p in packages):
                missing.append('INVALID: composer.lock does not lock laravel/framework')
        except (ValueError, OSError):
            missing.append('INVALID: unreadable composer.lock')
    if evidence_file.is_file():
        try:
            evidence = json.loads(evidence_file.read_text(encoding='utf-8'))
            if evidence.get('git_sha', '').lower() != head.lower() or evidence.get('passed') is not True:
                missing.append('INVALID: CI acceptance evidence does not match exact commit / PASS')
            required = ('laravel_tests', 'security_checks', 'fresh_install', 'upgrade', 'recovery')
            for test in required:
                if evidence.get('checks', {}).get(test) != 'PASS':
                    missing.append(f'NOT VERIFIED: CI gate {test}')
        except (ValueError, OSError):
            missing.append('INVALID: CI evidence unreadable')
    else:
        missing.append('MISSING: exact-head CI acceptance evidence (fresh install, upgrade, recovery)')
    return missing


def files_to_package(backend: Path):
    for name in PAYLOAD_FILES:
        yield backend / name, name
    for dirname in PAYLOAD_DIRS:
        d = backend / dirname
        if not d.is_dir():
            raise ValueError(f'MISSING DIRECTORY: {dirname}')
        for f in sorted(d.rglob('*')):
            if f.is_symlink():
                raise ValueError(f'REFUSED: symlink in release payload: {f}')
            if f.is_file():
                rel = f.relative_to(backend)
                if (f.name in DENY_FILENAMES or f.suffix.lower() in DENY_SUFFIXES
                        or '.git' in rel.parts or 'node_modules' in rel.parts):
                    raise ValueError(f'REFUSED: prohibited item in payload: {rel}')
                yield f, rel.as_posix()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--git-sha', default=os.environ.get('GITHUB_SHA', ''))
    parser.add_argument('--evidence', type=Path, default=None)
    parser.add_argument('--trusted-update-public-key', default='',
        help='Base64-encoded Ed25519 verification key derived from CI signer')
    parser.add_argument('--check-only', action='store_true')
    args = parser.parse_args()
    root = args.root.resolve()
    evidence = args.evidence or (root / 'setup/ci-evidence.json')
    version = (root / 'VERSION').read_text(encoding='utf-8').strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        parser.error('VERSION must use semantic versioning')
    failures = validate(root, args.git_sha, evidence)
    if failures:
        for problem in failures:
            print(problem, file=sys.stderr)
        print('RELEASE BLOCKED. No Setup ZIP generated.', file=sys.stderr)
        return 2
    if args.check_only:
        print('SOURCE PRECONDITIONS PASS; no ZIP generated.')
        return 0
    payload = {}
    try:
        for path, name in files_to_package(root / 'backend'):
            if not path.is_file() or path.stat().st_size == 0:
                raise ValueError(f'MISSING / EMPTY: {name}')
            payload[name] = path.read_bytes()
    except (OSError, ValueError) as exc:
        print(f'RELEASE BLOCKED: {exc}', file=sys.stderr)
        return 2
    # Setup secrets are generated only on the destination host, never in a release ZIP.
    # Inject only the public release-verification key into .env.example.
    # The installer copies this into the installed .env without exposing the secret signer.
    if args.trusted_update_public_key:
        import base64
        try:
            raw_key = base64.b64decode(args.trusted_update_public_key, validate=True)
            if len(raw_key) != 32:
                raise ValueError('Ed25519 public key must be 32 bytes')
        except (ValueError, base64.binascii.Error) as exc:
            raise SystemExit('RELEASE BLOCKED: invalid trusted update verification key') from exc
        template = payload['.env.example'].decode('utf-8')
        line = 'SCHOOLPDF_ED25519_UPDATE_PUBLIC_KEY="' + args.trusted_update_public_key + '"'
        if re.search(r'(?m)^SCHOOLPDF_ED25519_UPDATE_PUBLIC_KEY=.*$', template):
            template = re.sub(r'(?m)^SCHOOLPDF_ED25519_UPDATE_PUBLIC_KEY=.*$', lambda match: line, template)
        else:
            template = template.rstrip('\n') + '\n' + line + '\n'
        payload['.env.example'] = template.encode('utf-8')
    for d in EMPTY_DIRS:
        payload[f'{d}/.gitkeep'] = b''
    file_manifest = [
        {'path': name, 'sha256': sha256_bytes(content), 'bytes': len(content)}
        for name, content in sorted(payload.items())
    ]
    metadata = {
        'project': 'School PDF', 'kind': 'fresh-install', 'version': version,
        'git_sha': args.git_sha.lower(), 'php': '>=8.2',
        'required_extensions': ['pdo_mysql', 'mbstring', 'fileinfo', 'openssl', 'sodium', 'zip'],
        'features': ['web-installer', 'super-admin', 'country-push-dashboard', 'app-ads-txt'],
        'acceptance_checks': json.loads(evidence.read_text(encoding='utf-8'))['checks'],
        'signed_updates': bool(args.trusted_update_public_key),
        'files': file_manifest,
    }
    payload['SETUP_MANIFEST.json'] = (json.dumps(metadata, indent=2, ensure_ascii=False) + '\n').encode()
    payload['BUILD_INFO.json'] = (json.dumps({
        'version': version, 'source_git_sha': args.git_sha.lower(),
        'lock_sha256': sha256_bytes(payload['composer.lock']),
        'manifest_sha256': sha256_bytes(payload['SETUP_MANIFEST.json']),
    }, indent=2) + '\n').encode()
    payload['START_HERE.txt'] = (
        'School PDF cPanel fresh installation. Keep this ZIP and setup-access.key PRIVATE.\n'
        'Upload and extract outside public web root, point DocumentRoot to public/,\n'
        'then visit https://sclpdf.50sols.com/install.\n'
        'Create MySQL database/user first, then read setup-access.key from File Manager after /install.\n'
        'After installation, remove unused installation artifacts from your hosting account.\n'
    ).encode()
    out_dir = root / 'setup/output'
    out_dir.mkdir(parents=True, exist_ok=True)
    final = out_dir / f'SchoolPDF-Setup-v{version}.zip'
    temp = out_dir / (final.name + '.partial')
    try:
        with zipfile.ZipFile(temp, mode='w', compression=zipfile.ZIP_DEFLATED, compresslevel=7) as z:
            for name, content in sorted(payload.items()):
                if name.startswith('/') or '..' in Path(name).parts:
                    raise ValueError(f'Unsafe entry: {name}')
                entry = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
                entry.compress_type = zipfile.ZIP_DEFLATED
                entry.external_attr = (0o100640 << 16)
                z.writestr(entry, content)
        with zipfile.ZipFile(temp) as z:
            for item in z.infolist():
                if z.read(item) != payload[item.filename]:
                    raise ValueError(f'ZIP verify failed: {item.filename}')
        temp.replace(final)
        digest = sha256_bytes(final.read_bytes())
        (out_dir / f'SchoolPDF-Setup-v{version}.sha256').write_text(f'{digest}  {final.name}\n')
        (out_dir / f'SchoolPDF-Setup-v{version}-BUILD_INFO.json').write_bytes(payload['BUILD_INFO.json'])
        print(f'RELEASE CANDIDATE GENERATED: {final}\nSHA256: {digest}')
        print('Setup access code will be generated on the hosting server, outside public/.')
        return 0
    finally:
        temp.unlink(missing_ok=True)


if __name__ == '__main__':
    raise SystemExit(main())
