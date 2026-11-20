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
    base_version = json.loads(installer_lock.read_text())['version']
    major, minor, patch = (int(x) for x in base_version.split('.'))
    next_version = f'{major}.{minor}.{patch+1}'
    recovery_version = f'{major}.{minor}.{patch+2}'
    e['SCHOOLPDF_SMOKE_NEXT_VERSION'] = next_version

    def sign_package(name: str, target: str, payload: dict[str, bytes],
                     source_version: str = base_version) -> Path:
        manifest = {
            'kind': 'schoolpdf-update', 'project': 'School PDF',
            'target_version': target,
            'minimum_supported_version': source_version,
            'supported_base_versions': [source_version],
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
    doomed = sign_package('fail-before-migrations.zip',next_version,{
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
    assert json.loads(installer_lock.read_text())['version'] == base_version
    assert not (app / 'storage/framework/down').exists(), 'maintenance was not cleared'

    # Second attempt: legitimate signed update, preserving live admin and data.
    safe = sign_package('signed-upgrade.zip',next_version,{good_file:good_data})
    result = run_php(manager + r'''
$s=$m->stage($argv[2]);
$r=$m->install($s["id"]);
if (($r["version"]??"")!==getenv("SCHOOLPDF_SMOKE_NEXT_VERSION")) exit(4);
echo "UPGRADE_OK";''', safe)
    assert result.returncode == 0 and 'UPGRADE_OK' in result.stdout, (
        f'signed upgrade failed: {result.stderr[-400:]} {result.stdout[-200:]}')
    assert (app / good_file).read_bytes() == good_data
    assert json.loads(installer_lock.read_text())['version'] == next_version
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
foreach ($all as $item) {
    $manifest=$b->verify($item["id"]);
    foreach ($manifest["files"] as $entry) {
        if (str_starts_with($entry["path"],"storage/app/private/system-updates/")) exit(17);
    }
}
echo "BACKUP_RESTORABLE";''',safe)
    assert verify.returncode == 0 and 'BACKUP_RESTORABLE' in verify.stdout, (
        f'backup integrity failed: {verify.stderr[-400:]}')
    # A MySQL migration can commit DDL before failing. Prove the system
    # refuses blind rollback, retains maintenance and can recover into a
    # completely separate empty MariaDB database and files directory.
    upload_path = app / 'storage/app/private/ci-upload-retention.bin'
    upload_path.write_bytes(b'SchoolPDF customer upload survives recovery\n')
    env_snapshot = (app / '.env').read_bytes()
    migration_path = 'database/migrations/2026_11_18_999999_ci_recovery_failure.php'
    migration = b'''<?php
use Illuminate\\Database\\Migrations\\Migration;
use Illuminate\\Database\\Schema\\Blueprint;
use Illuminate\\Support\\Facades\\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('ci_recovery_partial',function(Blueprint $t){$t->id();});
    throw new \\RuntimeException('CI deliberately fails after DDL');
  }
  public function down(): void { Schema::dropIfExists('ci_recovery_partial'); }
};
'''
    # Correct PHP namespace syntax when evaluating escaped Python bytes.
    migration = migration.replace(b'\\\\', b'\\')
    broken = sign_package('ci-migration-failure.zip',recovery_version,
                          {migration_path:migration}, source_version=next_version)
    partial = run_php(manager + r'''
try {
    $staged=$m->stage($argv[2]);
    $m->install($staged["id"]);
    exit(11);
} catch (RuntimeException $e) {
    if (($m->progress()["phase"]??"")!=="RECOVERY_REQUIRED") exit(12);
    echo "MIGRATION_RECOVERY_REQUIRED";
}''',broken)
    assert partial.returncode == 0 and 'MIGRATION_RECOVERY_REQUIRED' in partial.stdout, (
        f'migration failure not safely contained: {partial.stderr[-450:]} {partial.stdout[-200:]}')
    assert (app / 'storage/framework/down').exists(), 'partial migration unexpectedly reopened site'
    assert json.loads(installer_lock.read_text())['version'] == next_version
    assert upload_path.read_bytes() == b'SchoolPDF customer upload survives recovery\n'

    restore_root = app.parent / 'recovered-files'
    restore_root.mkdir()
    restore_php = r'''
$b=$app->make(App\Services\SystemBackupManager::class);
$archives=$b->availableBackups();
$id=null;
foreach($archives as $item) {
    $manifest=$b->verify($item["id"]);
    if (($manifest["version"]??"")===getenv("SCHOOLPDF_SMOKE_NEXT_VERSION") &&
        isset($manifest["files"])) { $id=$item["id"]; break; }
}
if (!$id) exit(13);
$target=new PDO(
 "mysql:host=127.0.0.1;port=".getenv("SCHOOLPDF_TEST_RESTORE_PORT").
 ";dbname=".getenv("SCHOOLPDF_TEST_RESTORE_DATABASE"),
 getenv("SCHOOLPDF_TEST_DB_USERNAME"),getenv("SCHOOLPDF_TEST_DB_PASSWORD"),
 [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]
);
$recovery=$app->make(App\Services\BackupRecoveryVerifier::class);
$result=$recovery->restoreIntoEmptyTargets($id,$target,$argv[3]);
if (($result["version"]??"")!==getenv("SCHOOLPDF_SMOKE_NEXT_VERSION") ||
    ($result["tables"]??0)<5 || ($result["files"]??0)<10) exit(14);
$u=$target->query("SELECT role FROM users WHERE email='ci-preview@example.invalid'")->fetchColumn();
if ($u!=="super_admin") exit(15);
$c=$target->query("SHOW TABLES LIKE 'ci_recovery_partial'")->fetchColumn();
if ($c!==false) exit(16);
echo "DISPOSABLE_DATABASE_RESTORE_PASS";
'''
    code = (
        'require $argv[1]."/vendor/autoload.php";'
        '$app=require $argv[1]."/bootstrap/app.php";'
        r'$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();'
        + restore_php
    )
    restored = subprocess.run([php,'-r',code,str(app),str(broken),str(restore_root)],
        env=e, capture_output=True, text=True, timeout=180)
    assert restored.returncode == 0 and 'DISPOSABLE_DATABASE_RESTORE_PASS' in restored.stdout, (
        f'actual separate MariaDB restore failed: {restored.stderr[-500:]} {restored.stdout[-300:]}')
    assert (restore_root / '.env').read_bytes() == env_snapshot, 'restored .env differs'
    assert (restore_root / 'storage/app/private/ci-upload-retention.bin').read_bytes() == upload_path.read_bytes()
    assert json.loads((restore_root / 'storage/app/private/install.lock').read_text())['version'] == next_version
    print('PASS: failure AFTER MySQL DDL, maintenance lock retained, verified')
    print('database and uploaded files restored into SEPARATE clean targets.')
    print('Production signer provisioning remains a distinct release gate.')

    print('PASS: detached Ed25519 update; backup; partial-file rollback;')
    print(f'live data/config preservation; upgrade {base_version}→{next_version}; replay blocked.')

