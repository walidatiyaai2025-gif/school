#!/usr/bin/env python3
from pathlib import Path
import subprocess,re,json,hashlib,yaml,sys
root=Path(__file__).resolve().parent.parent
php=list((root/'backend').rglob('*.php'))
for f in php:
    p=subprocess.run(['php','-l',str(f)],capture_output=True,text=True)
    if p.returncode:
        print('PHP parse failed:',f,p.stdout+p.stderr);sys.exit(1)
for f in (root/'.github/workflows').glob('*.yml'):
    assert yaml.safe_load(f.read_text())
for f in (root/'mobile/lib').rglob('*.dart'):
    for path in re.findall(r"import\s+['\"](\.{1,2}/[^'\"]+)['\"]",f.read_text()):
        assert (f.parent/path).is_file(),(f,path)
assert 'com.fiftysols.schoolpdf' in (root/'mobile/tool/patch_platforms.py').read_text()
assert (root/'backend/public/app-ads.txt').exists()
assert (root/'mobile/assets/branding/icon.png').is_file()
assert 'analyticsConsent = false' in (root/'mobile/lib/data/models.dart').read_text()
assert 'adult' in (root/'mobile/lib/services/telemetry_service.dart').read_text()
assert 'REMOTE_ADDR' in (root/'backend/app/Services/CountryResolver.php').read_text()
assert "where('country_code'" in (root/'backend/app/Jobs/SendCampaign.php').read_text()
print('PASS STATIC: PHP syntax',len(php),'files, YAML, Dart relative imports, source structure/security invariants')
