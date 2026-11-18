from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

INSTALLER=Path(__file__).resolve().parents[2]/'backend/public/install.php'

class InstallerFailClosedTest(unittest.TestCase):
    def test_missing_dependencies_prevent_next(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); (root/'public').mkdir();
            shutil.copy2(INSTALLER,root/'public/install.php')
            (root/'storage/app/private').mkdir(parents=True)
            (root/'storage/framework').mkdir(parents=True)
            (root/'bootstrap/cache').mkdir(parents=True)
            r=subprocess.run(['php','-r',
              '$_SERVER["HTTPS"]="on"; $_SERVER["HTTP_HOST"]="sclpdf.50sols.com"; $_SERVER["REQUEST_METHOD"]="GET"; include $argv[1];',
              str(root/'public/install.php')],capture_output=True,text=True)
            self.assertEqual(r.returncode,0,r.stderr)
            self.assertIn('Composer dependencies',r.stdout)
            self.assertIn('disabled',r.stdout)
            self.assertIn('الاستضافة',r.stdout)

    def test_completed_install_blocks_entry(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); (root/'public').mkdir();
            shutil.copy2(INSTALLER,root/'public/install.php')
            (root/'storage/app/private').mkdir(parents=True)
            (root/'storage/app/private/install.lock').write_text('{"installed":true}')
            r=subprocess.run(['php',str(root/'public/install.php')],capture_output=True,text=True)
            self.assertIn('permanently locked',r.stdout)
            self.assertNotIn('DB Host',r.stdout)

    def test_public_preview_is_blocked_on_live_host(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            (root/'public').mkdir()
            shutil.copy2(INSTALLER,root/'public/install.php')
            (root/'PREVIEW-NOT-FOR-PRODUCTION.txt').write_text('nonproduction')
            r=subprocess.run(['php',str(root/'public/install.php')],
                capture_output=True,text=True)
            self.assertEqual(r.returncode,0,r.stderr)
            self.assertIn('blocked from live deployment',r.stdout)


if __name__=='__main__':unittest.main()
