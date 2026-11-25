#!/usr/bin/env bash
# GitHub Android emulator end-to-end Release process startup regression.
# Runs from repo root, as one shell command inside android-emulator-runner.
set -euo pipefail
cd "$(dirname "$0")/../.."
package="com.fiftysols.schoolpdf"
activity="$package/.MainActivity"
failures=0
for variant in NoAds PlayLike; do
  apk="mobile/dist/SchoolPDF-v1.1.5-build6-${variant}-QA-Release.apk"
  test -s "$apk"
  echo "::group::Android QA Release startup: $variant"
  adb install -r "$apk"
  adb shell pm clear "$package" >/dev/null
  for cycle in 1 2; do
    adb shell am force-stop "$package" || true
    adb logcat -c || true
    output="schoolpdf-release-${variant,,}-cycle-${cycle}.log"
    if ! adb shell am start -W -n "$activity"; then
      echo "::error::Activity launch failed for $variant on cycle $cycle"
      failures=$((failures + 1))
    fi
    sleep 15
    adb logcat -d -v time > "$output"
    if ! adb shell pidof "$package" >/dev/null; then
      echo "::error::Release process not alive for $variant cycle $cycle"
      failures=$((failures + 1))
    fi
    # Save enough context to distinguish native crash from Dart/unhandled/plugin startup.
    if grep -Eq 'FATAL EXCEPTION|Fatal signal [0-9]+|Dart Unhandled Exception|NoClassDefFoundError|ClassNotFoundException' "$output"; then
      echo "::warning::Potential fatal exception or class-loading error in $output"
      grep -n -A 16 -B 3 -E 'FATAL EXCEPTION|Fatal signal [0-9]+|Dart Unhandled Exception|NoClassDefFoundError|ClassNotFoundException' "$output" | head -n 90 || true
    fi
    if grep -F -q 'Process: com.fiftysols.schoolpdf' "$output"; then
      echo "::error::AndroidRuntime fatal process traceback for $variant cycle $cycle"
      failures=$((failures + 1))
    fi
    echo "Release process checked; variant=$variant cycle=$cycle log=$output"
  done
  echo "::endgroup::"
done
if (( failures > 0 )); then
  echo "::error::School PDF Release startup checks failed ($failures); inspect uploaded logcat evidence."
  exit 1
fi
echo "Release startup passed in both ad-disabled and Play-like variants across two cold starts each."
