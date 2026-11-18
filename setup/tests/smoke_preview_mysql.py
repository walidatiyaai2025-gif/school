#!/usr/bin/env python3
"""Exercise the actual extracted preview ZIP installer against an isolated CI MariaDB."""
from __future__ import annotations

import base64
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[2]


def check(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def main() -> None:
    version = (ROOT / 'VERSION').read_text().strip()
    archive = ROOT / 'setup/output' / f'SchoolPDF-Setup-v{version}-PREVIEW-UNVERIFIED.zip'
    checksum = (archive.with_name(archive.name + '.sha256')).read_text().split()[0]
    check(hashlib.sha256(archive.read_bytes()).hexdigest() == checksum, 'SHA mismatch')
    with tempfile.TemporaryDirectory(prefix='schoolpdf-preview-smoke-') as dirname:
        temp = Path(dirname)
        app = temp / 'app'
        app.mkdir()
        with zipfile.ZipFile(archive) as z:
            check(z.testzip() is None, 'bad zip')
            names = z.namelist()
            check('vendor/autoload.php' in names, 'missing production Composer dependencies')
            check('SETUP_MANIFEST.json' in names, 'missing manifest')
            check('.env' not in names, 'secret .env included')
            check(not any(n.startswith('/') or '..' in Path(n).parts for n in names), 'unsafe zip path')
            z.extractall(app)
        manifest = json.loads((app / 'SETUP_MANIFEST.json').read_text())
        check(manifest['production_ready'] is False, 'preview incorrectly marked as production')
        check((app / 'vendor/autoload.php').exists(), 'autoload missing')
        (temp / 'sessions').mkdir()
        session = 'ci' + uuid.uuid4().hex
        php = 'php'
        script = app / 'public/install.php'
        php_code = (
            'ini_set("session.save_path",getenv("SCHOOLPDF_SESSION_DIR"));'
            'session_id(getenv("SCHOOLPDF_SESSION_ID"));'
            '$_SERVER["HTTPS"]="on";'
            '$_SERVER["HTTP_HOST"]="sclpdf.50sols.com";'
            '$_SERVER["REQUEST_METHOD"]=getenv("SCHOOLPDF_HTTP_METHOD");'
            'if ($_SERVER["REQUEST_METHOD"]==="POST") '
            '$_POST=json_decode(base64_decode(getenv("SCHOOLPDF_FORM")),true);'
            'include $argv[1];'
        )
        env = os.environ.copy()
        env.update({
            'SCHOOLPDF_SESSION_DIR': str(temp / 'sessions'),
            'SCHOOLPDF_SESSION_ID': session,
            'SCHOOLPDF_HTTP_METHOD': 'GET',
        })

        def invoke() -> subprocess.CompletedProcess:
            return subprocess.run([php, '-r', php_code, str(script)], env=env,
                                  text=True, capture_output=True, timeout=90)

        # Installer enables PHP strict sessions. Pre-create the fixture session so
        # PHP accepts the supplied ID instead of rotating it on the first GET.
        init = subprocess.run([php, '-r',
            'ini_set("session.save_path",getenv("SCHOOLPDF_SESSION_DIR"));'
            'session_id(getenv("SCHOOLPDF_SESSION_ID"));session_start();session_write_close();'],
            env=env, text=True, capture_output=True, timeout=20)
        check(init.returncode == 0, 'could not establish isolated PHP session')
        page = invoke()
        check(page.returncode == 0, f'GET installer crashed: {page.stderr[:400]}')
        csrf = re.search(r'name="csrf" value="([a-f0-9]{64})"', page.stdout)
        check(csrf is not None, 'missing CSRF')
        ready = re.search(r'data-next="p2"([^>]*)>', page.stdout)
        check(ready is not None and 'disabled' not in ready.group(1), 'installer checks not ready')

        password = os.environ['SCHOOLPDF_TEST_DB_PASSWORD']
        username = os.environ['SCHOOLPDF_TEST_DB_USERNAME']
        database = os.environ['SCHOOLPDF_TEST_DB_DATABASE']
        form = {
            'csrf': csrf.group(1),
            'access_code': (app / 'setup-access.key').read_text().strip(),
            'db_host': '127.0.0.1', 'db_port': '3306',
            'db_database': database, 'db_username': username,
            'db_password': password, 'admin_name': 'Preview Test Admin',
            'admin_email': 'ci-preview@example.invalid',
            'admin_password': 'ci-Only-LongPassword_3497!',
        }
        env['SCHOOLPDF_HTTP_METHOD'] = 'POST'
        env['SCHOOLPDF_FORM'] = base64.b64encode(json.dumps(form).encode()).decode()
        result = invoke()
        check(result.returncode == 0, f'POST crashed: {result.stderr[-500:]}')
        if 'تم التثبيت وقفل المعالج بنجاح' not in result.stdout:
            errors = re.findall(r'<p class="alert">([^<]+)</p>', result.stdout)
            print('Installer safe diagnostics:', {
                'errors': errors[:4],
                'env_created': (app / '.env').exists(),
                'install_lock_created': (app / 'storage/app/private/install.lock').exists(),
                'stderr_tail': result.stderr[-400:],
            }, file=sys.stderr)
            raise RuntimeError('installer did not finish successfully; review CI isolated logs')
        check((app / 'storage/app/private/install.lock').exists(), 'setup lock missing')
        check((app / '.env').exists(), 'env missing')
        check(not (app / 'setup-access.key').exists(), 'setup key not removed')
        check(form['admin_password'] not in (app / '.env').read_text(), 'plaintext admin password leaked')

        env['SCHOOLPDF_HTTP_METHOD'] = 'GET'
        locked = invoke()
        check('permanently locked' in locked.stdout, 'installer not fail-closed')
        verify = (
            '$db=new PDO("mysql:host=127.0.0.1;dbname=".getenv("SCHOOLPDF_TEST_DB_DATABASE"),'
            'getenv("SCHOOLPDF_TEST_DB_USERNAME"),getenv("SCHOOLPDF_TEST_DB_PASSWORD"));'
            '$u=$db->query("SELECT role,password FROM users WHERE email=\'ci-preview@example.invalid\'")->fetch(PDO::FETCH_ASSOC);'
            'if (!$u || $u["role"]!=="super_admin" || !password_verify("ci-Only-LongPassword_3497!",$u["password"])) exit(2);'
            'if (!$db->query("SELECT COUNT(*) FROM migrations")->fetchColumn()) exit(3);'
            'echo "mysql-install-ok";'
        )
        query = subprocess.run([php, '-r', verify], env=env, text=True,
                               capture_output=True, timeout=30)
        check(query.returncode == 0 and 'mysql-install-ok' in query.stdout,
              'database migrations / super admin verification failed')
        # Verify the real installed Laravel code can snapshot live file state and
        # MariaDB content without SSH, including an integrity-checked private ZIP.
        backup_php = (
            'require $argv[1]."/vendor/autoload.php";'
            '$app=require $argv[1]."/bootstrap/app.php";'
            r'$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();'
            r'$b=$app->make(App\Services\SystemBackupManager::class);'
            '$result=$b->create();'
            '$manifest=$b->verify($result["id"]);'
            'if (!isset($manifest["database_tables"]["users"]) || '
            '!in_array(".env",array_column($manifest["files"],"path"),true)) exit(9);'
            'echo "BACKUP_OK";'
        )
        backup_result = subprocess.run([php, '-r', backup_php, str(app)], env=env,
            text=True, capture_output=True, timeout=120)
        check(backup_result.returncode == 0 and 'BACKUP_OK' in backup_result.stdout,
            f'isolated private backup verification failed: {backup_result.stderr[-450:]}')
        print('PASS: real installed archive backup, MariaDB row export, .env retention,')
        print('private backup manifest and SHA-256 verification')
        from signed_upgrade_smoke import run_signed_upgrade_smoke
        run_signed_upgrade_smoke(app, env, php)
        print('PASS: exact preview ZIP extraction, integrity, isolated MySQL install,')
        print('hashed super admin, completed lock, and repeated-install denial')
        print('Production upgrade, recovery and signing gates remain NOT VERIFIED.')


if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        print(f'ISOLATED FRESH INSTALL SMOKE FAILED: {type(exc).__name__}: {exc}', file=sys.stderr)
        raise SystemExit(1)
