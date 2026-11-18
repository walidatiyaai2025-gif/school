import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

SCRIPT=Path(__file__).resolve().parents[1]/'build_setup.py'
HEAD='a'*40
GATES=['laravel_tests','security_checks','fresh_install','upgrade','recovery']

class SetupBuilderTest(unittest.TestCase):
    def fixture(self, parent):
        root=Path(parent)
        (root/'VERSION').write_text('1.1.2')
        backend=root/'backend'
        for dirname in ('app','bootstrap','config','database/migrations','public',
                        'resources','routes','vendor','vendor/composer',
                        'vendor/laravel/framework/src/Illuminate/Foundation'):
            (backend/dirname).mkdir(parents=True,exist_ok=True)
        for name in ('artisan','composer.json','.env.example','public/install.php',
                     'bootstrap/app.php','vendor/autoload.php',
                     'vendor/composer/installed.php',
                     'vendor/laravel/framework/src/Illuminate/Foundation/Application.php'):
            (backend/name).write_text('fixture (not a production dependency)')
        (backend/'composer.lock').write_text(json.dumps({'packages':[{'name':'laravel/framework','version':'v12.0.0'}]}))
        (backend/'public/brand-icon.png').write_bytes(b'fake icon')
        (root/'setup').mkdir(exist_ok=True)
        (root/'setup/ci-evidence.json').write_text(json.dumps({
            'git_sha':HEAD,'passed':True,'checks':{gate:'PASS' for gate in GATES}
        }))
        return root

    def run_builder(self,root,*args):
        return subprocess.run([sys.executable,str(SCRIPT),'--root',str(root),'--git-sha',HEAD,*args],capture_output=True,text=True)

    def test_unlocked_source_refuses_build(self):
        with tempfile.TemporaryDirectory() as d:
            root=self.fixture(d)
            (root/'backend/composer.lock').unlink()
            r=self.run_builder(root)
            self.assertEqual(r.returncode,2)
            self.assertIn('composer.lock',r.stderr)
            self.assertFalse(list((root/'setup').glob('**/SchoolPDF-Setup*.zip')))

    def test_unverified_ci_gate_blocks_release(self):
        with tempfile.TemporaryDirectory() as d:
            root=self.fixture(d)
            p=root/'setup/ci-evidence.json'
            data=json.loads(p.read_text());data['checks']['upgrade']='NOT_RUN';p.write_text(json.dumps(data))
            r=self.run_builder(root)
            self.assertEqual(r.returncode,2)
            self.assertIn('upgrade',r.stderr)

    def test_secrets_not_bundled(self):
        with tempfile.TemporaryDirectory() as d:
            root=self.fixture(d)
            (root/'backend/.env').write_text('SECRET!')
            r=self.run_builder(root)
            self.assertEqual(r.returncode,2)
            self.assertIn('REFUSED',r.stderr)

    def test_safe_content_and_valid_checksum(self):
        with tempfile.TemporaryDirectory() as d:
            root=self.fixture(d)
            (root/'backend/storage/app/private').mkdir(parents=True)
            (root/'backend/storage/app/private/prod-data.txt').write_text('sensitive upload')
            r=self.run_builder(root)
            self.assertEqual(r.returncode,0,r.stderr)
            archive=root/'setup/output/SchoolPDF-Setup-v1.1.2.zip'
            self.assertTrue(archive.is_file())
            checksum=(root/'setup/output/SchoolPDF-Setup-v1.1.2.sha256').read_text().split()[0]
            self.assertEqual(checksum,hashlib.sha256(archive.read_bytes()).hexdigest())
            with zipfile.ZipFile(archive) as z:
                names=z.namelist()
                self.assertIn('vendor/autoload.php',names)
                self.assertNotIn('setup-access.key',names)
                self.assertIn('SETUP_MANIFEST.json',names)
                self.assertNotIn('storage/app/private/prod-data.txt',names)
                self.assertNotIn('.env',names)
                self.assertNotIn('public/.env',names)
                self.assertEqual(z.testzip(),None)
                self.assertTrue(all(not n.startswith('/') and '..' not in Path(n).parts for n in names))
                self.assertEqual(json.loads(z.read('BUILD_INFO.json'))['source_git_sha'],HEAD)

    def test_setup_embeds_only_the_trusted_public_update_key(self):
        import base64
        with tempfile.TemporaryDirectory() as d:
            root=self.fixture(d)
            public=base64.b64encode(bytes(range(32))).decode('ascii')
            (root/'backend/.env.example').write_text('SCHOOLPDF_ED25519_UPDATE_PUBLIC_KEY=\n')
            r=self.run_builder(root,'--trusted-update-public-key',public)
            self.assertEqual(r.returncode,0,r.stderr)
            archive=root/'setup/output/SchoolPDF-Setup-v1.1.2.zip'
            with zipfile.ZipFile(archive) as z:
                environment=z.read('.env.example').decode()
                self.assertIn('SCHOOLPDF_ED25519_UPDATE_PUBLIC_KEY="'+public+'"',environment)
                self.assertEqual(environment.count('SCHOOLPDF_ED25519_UPDATE_PUBLIC_KEY='),1)
                self.assertEqual(json.loads(z.read('SETUP_MANIFEST.json'))['signed_updates'],True)
                self.assertNotIn('setup-access.key',z.namelist())

    def test_symlinks_are_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root=self.fixture(d)
            (root/'backend/public/linked-config').symlink_to(root/'backend/composer.json')
            r=self.run_builder(root)
            self.assertEqual(r.returncode,2)
            self.assertIn('symlink',r.stderr)

if __name__=='__main__':
    unittest.main()
