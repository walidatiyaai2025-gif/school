#!/usr/bin/env python3
"""Build a quarantined, NON-PRODUCTION School PDF installer preview.

Never use this script to bypass build_setup.py's production release gates.
The access code in this public-CI artifact is not a production secret.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import secrets
import sys
import zipfile

from build_setup import EMPTY_DIRS, files_to_package, sha256_bytes

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--git-sha', required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    backend = root / 'backend'
    sha = args.git_sha.lower()
    if not re.fullmatch(r'[a-f0-9]{40}', sha):
        parser.error('exact commit SHA required')
    version = (root / 'VERSION').read_text().strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        parser.error('invalid version')

    required = ('composer.lock', 'vendor/autoload.php', 'vendor/composer/installed.php',
                'public/install.php', 'bootstrap/app.php')
    for file in required:
        if not (backend / file).is_file():
            raise SystemExit(f'PREVIEW BLOCKED: missing {file}')
    for file in ('.env', 'setup-access.key', 'storage/app/private/install.lock'):
        if (backend / file).exists():
            raise SystemExit(f'PREVIEW BLOCKED: refusing live/secret {file}')
    if (root / 'setup/installer/install.php').read_bytes() != (backend / 'public/install.php').read_bytes():
        raise SystemExit('PREVIEW BLOCKED: web installer source mismatch')
    lock = json.loads((backend / 'composer.lock').read_text())
    if not any(p.get('name') == 'laravel/framework' for p in lock.get('packages', [])):
        raise SystemExit('PREVIEW BLOCKED: Laravel not in Composer lock')

    contents: dict[str, bytes] = {}
    for file, name in files_to_package(backend):
        if not file.is_file() or file.stat().st_size == 0:
            raise SystemExit(f'PREVIEW BLOCKED: missing/empty {name}')
        contents[name] = file.read_bytes()
    for path in EMPTY_DIRS:
        contents[f'{path}/.gitkeep'] = b''

    # The web installer generates its own site-local setup code on first HTTPS visit.
    contents['PREVIEW-NOT-FOR-PRODUCTION.txt'] = (
        'WARNING: NOT FOR PRODUCTION. This is a public CI preview, not a release.\n'
        'Fresh install, upgrade, recovery and signing acceptance are not all verified.\n'
        'A setup code bundled in a public GitHub artifact is NOT private.\n'
        'Never upload this archive to a live cPanel domain.\n'
        'Use only a throwaway, isolated environment to test the installer.\n'
    ).encode()
    manifest = {
        'project': 'School PDF',
        'version': version,
        'source_git_sha': sha,
        'artifact_kind': 'SETUP_PREVIEW_NON_PRODUCTION',
        'production_ready': False,
        'acceptance_checks': {'fresh_install': 'CI_SMOKE_ONLY',
                              'upgrade': 'NOT_VERIFIED', 'recovery': 'NOT_VERIFIED',
                              'signed_admin_updates': 'NOT_IMPLEMENTED'},
        'files': [{'path': name, 'sha256': sha256_bytes(data), 'bytes': len(data)}
                  for name, data in sorted(contents.items())],
    }
    contents['SETUP_MANIFEST.json'] = (json.dumps(manifest, indent=2) + '\n').encode()
    contents['BUILD_INFO.json'] = (json.dumps({
        'preview': True, 'production_ready': False, 'source_git_sha': sha,
        'composer_lock_sha256': sha256_bytes(contents['composer.lock']),
        'manifest_sha256': sha256_bytes(contents['SETUP_MANIFEST.json']),
    }, indent=2) + '\n').encode()
    out = root / 'setup/output'
    out.mkdir(parents=True, exist_ok=True)
    filename = f'SchoolPDF-Setup-v{version}-PREVIEW-UNVERIFIED.zip'
    archive = out / filename
    temp = archive.with_suffix('.zip.partial')
    try:
        with zipfile.ZipFile(temp, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
            for name, data in sorted(contents.items()):
                if name.startswith('/') or '..' in Path(name).parts:
                    raise ValueError(f'Unsafe archive path: {name}')
                z.writestr(name, data)
        with zipfile.ZipFile(temp) as z:
            if z.testzip() is not None:
                raise ValueError('Archive CRC verification failed')
            for name, data in contents.items():
                if z.read(name) != data:
                    raise ValueError('Archive read-back mismatch')
        temp.replace(archive)
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        (out / f'{filename}.sha256').write_text(f'{digest}  {filename}\n')
        print(f'PREVIEW ARTIFACT GENERATED: {archive}; SHA256 {digest}')
        print('NOT PRODUCTION READY. No release gates bypassed.')
        return 0
    finally:
        temp.unlink(missing_ok=True)


if __name__ == '__main__':
    sys.exit(main())
