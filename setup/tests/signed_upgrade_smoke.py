#!/usr/bin/env python3
"""Exercise signed ZIP update with true file rollback on an isolated installed app.

Uses a disposable Ed25519 keypair, NEVER a production signer. No key is printed
or included in any uploaded CI artifact.
"""
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import zipfile


def run_signed_upgrade_smoke(app: Path, env: dict, php: str) -> None:
    key_result = subprocess.run([php, '-r', (
        '$p=sodium_crypto_sign_keypair();'
        'echo json_encode([base64_encode(sodium_crypto_sign_publickey($p)),'
        'base64_encode(sodium_crypto_sign_secretkey($p))]);'
    )], capture_output=True, text=True, check=True)
    pub, secret = json.loads(key_result.stdout)
    e = env.copy()
    e['SCHOOLPDF_TEST_SIGN_PUBLIC'] = pub
    e['SCHOOLPDF_TEST_SIGN_SECRET'] = secret
    e.pop('SCHOOLPDF_FORM', None)
    installer_lock = app / 'storage/app/private/install.lock'
    assert json.loads(installer_lock.read_text())['version'] == '1.1.2'

    def sign_package(name: str, target: str, payload: dict[str, bytes]) -> Path:
        manifest = {
            'kind': 'schoolpdf-update', 'project': 'School PDF',
            'target_version': target,
            'minimum_supported_version': '1.1.2',
            'supported_base_versions': ['1.1.2'],
            'min_php': '8.2',
            'git_sha': os.environ.get('GITHUB_SHA','a'*40).lower(),
            'release_notes': 'CI-only signed upgrade acceptance',
            'files': [
                {'path': relative, 'bytes': len(data),
                 'sha256': hashlib.sha256(data).hexdigest()}
                for relative, data in payload.items()
            ],
        }
        manifest_bytes = json.dumps(manifest, sort_keys=True, separators=(',', ':')).encode()
        signed = subprocess.run([php, '-r',
            '$k=base64_decode(getenv("SCHOOLPDF_TEST_SIGN_SECRET"));'
            'echo base64_encode(sodium_crypto_sign_detached(stream_get_contents(STDIN),$k));'],
            input=manifest_bytes, capture_output=True, check=True, env=e)
        path = app.parent / name
        with zipfile.ZipFile(path, 'w', compression=zipfile.ZIP_DEFLATED) as z:
            z.writestr('manifest.json', manifest_bytes)
            z.writestr('signature.ed25519', signed.stdout)
            for relative, data in payload.items():
                z.writestr('payload/' + relative, data)
        return path

    def run_php(source: str, archive: Path):
        code = (
            'require $argv[1]."/vendor/autoload.php";'
            '$app=require $argv[1]."/bootstrap/app.php";'
            r'$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();'
            '$app["config"]->set("schoolpdf.update_public_key",getenv("SCHOOLPDF_TEST_SIGN_PUBLIC"));'
            + source
        )
        return subprocess.run([php,'-r',code,str(app),str(archive)],
                              env=e, capture_output=True, text=True, timeout=180)

    manager = r'$m=$app->make(App\Services\SystemUpdateManager::class);'
    good_file = 'app/Support/CIUpgradeSmoke.php'
    good_data = b'<?php // safe signed upgrade fixture\n'
    bad_file = 'app/Models/User.php/cannot-create.php'

    # First attempt: after one file is added, a second destination is
    # impossible because User.php is a regular file, not a directory.
    doomed = sign_package('fail-before-migrations.zip','1.1.3',{
        good_file:good_data,
        bad_file:b'<?php // deliberately unreachable\n',
    })
    failed = run_php(manager + r'''
try {
    $s=$m->stage($argv[2]);
    $m->install($s["id"]);
    exit(2);
} catch (RuntimeException $e) {
    if (($m->progress()["phase"]??"")!=="FAILED_BEFORE_MIGRATIONS") exit(3);
    echo "ROLLBACK_OK";
}''', doomed)
    assert failed.returncode == 0 and 'ROLLBACK_OK' in failed.stdout, (
        f'pre-migration recovery failed: {failed.stderr[-400:]} {failed.stdout[-200:]}')
    assert not (app / good_file).exists(), 'partial update file was not rolled back'
    assert json.loads(installer_lock.read_text())['version'] == '1.1.2'
    assert not (app / 'storage/framework/down').exists(), 'maintenance was not cleared'

    # Second attempt: legitimate signed update, preserving live admin and data.
    safe = sign_package('signed-upgrade.zip','1.1.3',{good_file:good_data})
    result = run_php(manager + r'''
$s=$m->stage($argv[2]);
$r=$m->install($s["id"]);
if (($r["version"]??"")!=="1.1.3") exit(4);
echo "UPGRADE_OK";''', safe)
    assert result.returncode == 0 and 'UPGRADE_OK' in result.stdout, (
        f'signed upgrade failed: {result.stderr[-400:]} {result.stdout[-200:]}')
    assert (app / good_file).read_bytes() == good_data
    assert json.loads(installer_lock.read_text())['version'] == '1.1.3'
    assert not (app / 'storage/framework/down').exists(), 'maintenance left enabled'
    assert (app / '.env').exists(), '.env lost during upgrade'

    # Reject replay/downgrade even if the signature and file hashes are valid.
    replay = run_php(manager + r'''
try { $m->inspect($argv[2]); exit(5); }
catch (RuntimeException $e) { echo "REPLAY_BLOCKED"; }''',safe)
    assert replay.returncode == 0 and 'REPLAY_BLOCKED' in replay.stdout, (
        'replay/downgrade accepted')

    # The backup must be readable and provably contain the original live site.
    verify = run_php(r'''
$b=$app->make(App\Services\SystemBackupManager::class);
$all=$b->availableBackups();
if (count($all)<2) exit(6);
foreach ($all as $item) $b->verify($item["id"]);
echo "BACKUP_RESTORABLE";''',safe)
    assert verify.returncode == 0 and 'BACKUP_RESTORABLE' in verify.stdout, (
        f'backup integrity failed: {verify.stderr[-400:]}')
    print('PASS: detached Ed25519 update; backup; partial-file rollback;')
    print('live data/config preservation; upgrade 1.1.2→1.1.3; replay blocked.')
    print('CAUTION: database migration recovery and production signing NOT verified.')
