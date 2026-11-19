"""Fixed-cPanel-root isolation/zip/asset test. No production credentials."""
import base64
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'setup'))
from build_fixed_root import build, verified_source
from test_setup_builder import SetupBuilderTest, HEAD


class FixedRootDeployTest(unittest.TestCase):
    def create_verified_fixture(self, directory):
        root = SetupBuilderTest().fixture(directory)
        (root / 'backend/.env.example').write_text('SCHOOLPDF_ED25519_UPDATE_PUBLIC_KEY=\n')
        public = root / 'backend/public'
        (public / '.htaccess').write_text('RewriteEngine On\n')
        (public / 'index.php').write_text('<?php echo "PRIVATE_INDEX_OK";')
        (public / 'install.php').write_text('<?php echo "PRIVATE_INSTALL_OK";')
        (public / 'robots.txt').write_text('Disallow: /private\n')
        (public / 'app-ads.txt').write_text('original seller config\n')
        for file in ('robots.txt', 'app-ads.txt'):
            self.assertTrue((public / file).exists())

        public_key = base64.b64encode(bytes(range(32))).decode('ascii')
        result = subprocess.run([
            sys.executable, str(ROOT / 'setup/build_setup.py'),
            '--root', str(root), '--git-sha', HEAD,
            '--trusted-update-public-key', public_key
        ], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        archive = root / 'setup/output/SchoolPDF-Setup-v1.1.2.zip'
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        checksum = root / 'setup/output/SchoolPDF-Setup-v1.1.2.sha256'
        evidence = root / 'setup/acceptance.json'
        evidence.write_text(json.dumps({
            'source_git_sha': HEAD, 'archive_sha256': digest,
            'exact_setup_zip_fresh_install': 'PASS',
            'migration_failure_isolated_recovery': 'PASS',
        }))
        return archive, checksum, evidence

    def test_verified_split_and_web_only_artifacts(self):
        with tempfile.TemporaryDirectory() as temp:
            archive, checksum, evidence = self.create_verified_fixture(temp)
            out = Path(temp) / 'out'
            web, full = build(ROOT, archive, checksum, evidence, out)
            with zipfile.ZipFile(web) as z:
                self.assertEqual(set(z.namelist()), {
                    '.htaccess', '.schoolpdf-bridge.php', 'index.php', 'install.php'
                })
                self.assertNotIn('.env', z.namelist())
                self.assertNotIn('vendor/autoload.php', z.namelist())
                self.assertIsNone(z.testzip())
            with zipfile.ZipFile(full) as z:
                names = z.namelist()
                self.assertIn('sclpdf/vendor/autoload.php', names)
                self.assertIn('sclpdf/SETUP_MANIFEST.json', names)
                self.assertIn('public_html/sclpdf.50sols.com/index.php', names)
                self.assertNotIn('public_html/sclpdf.50sols.com/vendor/autoload.php', names)
                self.assertFalse(any(x.startswith('public_html/') and
                                     '/sclpdf.50sols.com/' in x and x.endswith('.env') for x in names))
                self.assertIsNone(z.testzip())
            self.assertEqual(
                hashlib.sha256(full.read_bytes()).hexdigest(),
                (out / (full.name + '.sha256')).read_text().split()[0]
            )

            home = Path(temp) / 'hosting-account'
            home.mkdir()
            with zipfile.ZipFile(full) as z:
                z.extractall(home)
            private = home / 'sclpdf'
            webroot = home / 'public_html/sclpdf.50sols.com'
            (private / 'public/index.php').write_text('<?php echo "PRIVATE_INDEX_OK";')
            (private / 'public/install.php').write_text('<?php echo "PRIVATE_INSTALL_OK";')

            def call(web_script, uri):
                code = (
                    '$_SERVER["REQUEST_METHOD"]="GET";'
                    '$_SERVER["HTTP_HOST"]="sclpdf.50sols.com";'
                    '$_SERVER["REQUEST_URI"]=getenv("SCHOOLPDF_TEST_URI");'
                    'include $argv[1];'
                )
                return subprocess.run(
                    ['php', '-r', code, str(webroot / web_script)],
                    env={**os.environ, 'SCHOOLPDF_TEST_URI': uri},
                    capture_output=True, text=True
                )

            self.assertEqual(call('index.php', '/').stdout, 'PRIVATE_INDEX_OK')
            self.assertEqual(call('install.php', '/install').stdout, 'PRIVATE_INSTALL_OK')
            self.assertEqual(call('index.php', '/robots.txt').stdout, 'Disallow: /private\n')
            self.assertEqual(call('index.php', '/app-ads.txt').stdout, 'original seller config\n')
            (private / 'public/app-ads.txt').write_text('updated by admin\n')
            self.assertEqual(call('index.php', '/app-ads.txt').stdout, 'updated by admin\n')

            (private / '.env').write_text('VERY_SECRET_MARKER')
            result = call('index.php', '/assets/../.env')
            self.assertNotIn('VERY_SECRET_MARKER', result.stdout)
            self.assertIn('Invalid request path', result.stdout)
            assets = private / 'public/assets'
            assets.mkdir()
            (assets / 'forbidden.css').symlink_to(private / '.env')
            result = call('index.php', '/assets/forbidden.css')
            self.assertEqual(result.stdout, 'Public asset not found.')
            self.assertNotIn('VERY_SECRET_MARKER', result.stdout)

    def test_wrong_checksum_and_missing_acceptance_fail_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            archive, checksum, evidence = self.create_verified_fixture(temp)
            checksum.write_text('0' * 64 + '  ' + archive.name + '\n')
            with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
                verified_source(archive, checksum, evidence)
            checksum.write_text(hashlib.sha256(archive.read_bytes()).hexdigest()
                                + '  ' + archive.name + '\n')
            evidence.unlink()
            with self.assertRaisesRegex(ValueError, 'acceptance evidence'):
                verified_source(archive, checksum, evidence)

    def test_missing_private_root_does_not_fall_back_into_public_html(self):
        with tempfile.TemporaryDirectory() as temp:
            archive, checksum, evidence = self.create_verified_fixture(temp)
            web, _ = build(ROOT, archive, checksum, evidence, Path(temp) / 'out')
            webroot = Path(temp) / 'account/public_html/sclpdf.50sols.com'
            webroot.mkdir(parents=True)
            with zipfile.ZipFile(web) as z:
                z.extractall(webroot)
            response = subprocess.run(
                ['php', str(webroot / 'index.php')],
                capture_output=True, text=True
            )
            self.assertIn('private Laravel package missing or unsafe', response.stdout)
            self.assertNotIn('PRIVATE_INDEX_OK', response.stdout)


if __name__ == '__main__':
    unittest.main()
