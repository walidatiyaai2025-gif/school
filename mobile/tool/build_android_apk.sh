#!/usr/bin/env bash
# Local Android test APK build for School PDF. Requires installed Flutter + Android SDK.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null 2>&1 || { echo 'Flutter SDK is not installed/in PATH.' >&2; exit 1; }
flutter create --project-name school_pdf --platforms android --org com.fiftysols .
python3 tool/patch_platforms.py
flutter pub get
dart run flutter_launcher_icons -f tool/flutter_launcher_icons_android.yaml
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug --no-pub
test -s build/app/outputs/flutter-apk/app-debug.apk
mkdir -p dist
cp build/app/outputs/flutter-apk/app-debug.apk dist/SchoolPDF-v1.1.1-debug.apk
if command -v sha256sum >/dev/null 2>&1; then
  (cd dist && sha256sum SchoolPDF-v1.1.1-debug.apk > SHA256SUMS.txt)
elif command -v shasum >/dev/null 2>&1; then
  (cd dist && shasum -a 256 SchoolPDF-v1.1.1-debug.apk > SHA256SUMS.txt)
fi
echo "APK: $(pwd)/dist/SchoolPDF-v1.1.1-debug.apk"
