"""Unit-level cryptographic and package integrity tests, never release evidence."""
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

from test_setup_builder import SetupBuilderTest

SCRIPT=Path(__file__).resolve().parents[1]/'build_signed_update.py'

class SignedUpdateBuilderTest(unittest.TestCase):
    def fixture(self, path):
        return SetupBuilderTest().fixture(path)

    def signer(self):
        php = (
            '$p=sodium_crypto_sign_keypair();'
            'echo json_encode(['
            'base64_encode(sodium_crypto_sign_secretkey($p)),'
            'base64_encode(sodium_crypto_sign_publickey($p))]);'
        )
        result=subprocess.run(['php','-r',php],capture_output=True,text=True,check=True)
        return json.loads(result.stdout)

    def build(self, root, key=None, lock_sha=None):
        env=os.environ.copy()
        env.pop('SCHOOLPDF_RELEASE_ED25519_KEY_B64',None)
        if key:
            env['SCHOOLPDF_RELEASE_ED25519_KEY_B64']=key
        if lock_sha is None:
            lock_sha=hashlib.sha256((root/'backend/composer.lock').read_bytes()).hexdigest()
        return subprocess.run([sys.executable,str(SCRIPT),
            '--root',str(root),'--git-sha','a'*40,'--from-version','1.1.1',
            '--verified-base-lock-sha',lock_sha],env=env,capture_output=True,text=True)

    def test_refuses_unsigned_release(self):
        with tempfile.TemporaryDirectory() as directory:
            root=self.fixture(directory)
            result=self.build(root)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('protected GitHub release signing key',result.stderr)
            self.assertFalse(list((root/'setup/output').glob('*.zip')))

    def test_rejects_unknown_base_lock(self):
        with tempfile.TemporaryDirectory() as directory:
            root=self.fixture(directory)
            private,_=self.signer()
            result=self.build(root,private,'0'*64)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('production dependencies changed',result.stderr)

    def test_signs_exact_manifest_and_excludes_live_data(self):
        with tempfile.TemporaryDirectory() as directory:
            root=self.fixture(directory)
            (root/'backend/storage/app/private').mkdir(parents=True)
            (root/'backend/storage/app/private/user-upload.pdf').write_bytes(b'user content')
            private,public=self.signer()
            result=self.build(root,private)
            self.assertEqual(result.returncode,0,result.stderr)
            archive=root/'setup/output/SchoolPDF-Update-v1.1.2.zip'
            self.assertTrue(archive.is_file())
            with zipfile.ZipFile(archive) as z:
                self.assertIsNone(z.testzip())
                names=z.namelist()
                self.assertIn('payload/vendor/autoload.php',names)
                self.assertNotIn('payload/.env.example',names)
                self.assertNotIn('payload/storage/app/private/user-upload.pdf',names)
                manifest=z.read('manifest.json')
                signature=base64.b64decode(z.read('signature.ed25519'),validate=True)
                parsed=json.loads(manifest)
                self.assertEqual(parsed['target_version'],'1.1.2')
                self.assertEqual(parsed['supported_base_versions'],['1.1.1'])
                self.assertEqual(parsed['git_sha'],'a'*40)
                self.assertEqual(len(signature),64)
                verify=subprocess.run(['php','-r',
                    '$sig=base64_decode(getenv("SIG"),true);'
                    '$key=base64_decode(getenv("PUB"),true);'
                    'exit(sodium_crypto_sign_verify_detached($sig,stream_get_contents(STDIN),$key)?0:1);'],
                    input=manifest,env={**os.environ,'SIG':base64.b64encode(signature).decode(),'PUB':public},
                    capture_output=True)
                self.assertEqual(verify.returncode,0)
            self.assertNotIn(private,archive.read_bytes().decode('latin1','ignore'))
            sha=(root/'setup/output/SchoolPDF-Update-v1.1.2.zip.sha256').read_text().split()[0]
            self.assertEqual(sha,hashlib.sha256(archive.read_bytes()).hexdigest())

if __name__=='__main__':
    unittest.main()
