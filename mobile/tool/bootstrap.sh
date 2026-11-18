#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK not found. Install Flutter stable 3.47+ and rerun.' >&2
  exit 1
fi
flutter create --project-name school_pdf --platforms android,ios --org com.fiftysols .
python3 tool/patch_platforms.py
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
printf '\nFlutter project scaffolded and checks finished. Run: flutter run\n'
