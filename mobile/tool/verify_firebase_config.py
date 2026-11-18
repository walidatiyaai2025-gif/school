#!/usr/bin/env python3
"""Offline check of the supplied Firebase client configurations. No network use."""
from pathlib import Path
import json
import plistlib

root = Path(__file__).resolve().parent.parent
android_path = root / 'config/firebase/google-services.json'
ios_path = root / 'config/firebase/GoogleService-Info.plist'
options_path = root / 'lib/firebase_options.dart'

android = json.loads(android_path.read_text(encoding='utf-8'))
with ios_path.open('rb') as handle:
    ios = plistlib.load(handle)
client = android['client'][0]
expected_package = 'com.fiftysols.schoolpdf'
expected_project = 'schoolpdf-50sols'
assert client['client_info']['android_client_info']['package_name'] == expected_package
assert ios['BUNDLE_ID'] == expected_package
assert android['project_info']['project_id'] == ios['PROJECT_ID'] == expected_project
assert android['project_info']['project_number'] == ios['GCM_SENDER_ID']
assert client['api_key'][0]['current_key'] and ios['API_KEY']
options = options_path.read_text(encoding='utf-8')
assert client['client_info']['mobilesdk_app_id'] in options
assert ios['GOOGLE_APP_ID'] in options
assert expected_package in options
assert expected_project in options
assert 'private_key' not in android and 'private_key' not in ios
print('PASS: Firebase Android and iOS client config, IDs, sender and generated Dart options')
