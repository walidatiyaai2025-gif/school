#!/usr/bin/env bash
set -euo pipefail
SRC="${SCHOOLPDF_SOURCE_DIR:-$HOME/Desktop/SchoolPDF}"
DEST="${SCHOOLPDF_GIT_DIR:-$HOME/Desktop/SchoolPDF-GitHub}"
REPO="https://github.com/walidatiyaai2025-gif/school.git"

test -f "$SRC/backend/composer.json" || { echo "Missing: $SRC/backend/composer.json" >&2; exit 1; }
test -f "$SRC/backend/composer.lock" || { echo "Missing: $SRC/backend/composer.lock (keep locally tested dependencies)" >&2; exit 1; }
test -f "$SRC/mobile/pubspec.yaml" || { echo "Missing: $SRC/mobile/pubspec.yaml" >&2; exit 1; }

if [ -e "$DEST" ] && [ ! -d "$DEST/.git" ]; then
  echo "Target exists and is not a Git clone: $DEST. Choose another SCHOOLPDF_GIT_DIR." >&2
  exit 1
fi

if [ ! -d "$DEST/.git" ]; then
  git clone "$REPO" "$DEST"
else
  origin="$(git -C "$DEST" remote get-url origin)"
  case "$origin" in
    "$REPO"|"git@github.com:walidatiyaai2025-gif/school.git") ;;
    *) echo "Wrong Git remote: $origin" >&2; exit 1 ;;
  esac
  if ! git -C "$DEST" diff --quiet || ! git -C "$DEST" diff --cached --quiet; then
    echo "Target has uncommitted changes; resolve them before running import." >&2
    exit 1
  fi
  git -C "$DEST" fetch origin main
  git -C "$DEST" rebase origin/main || { echo "Git rebase conflict. No push attempted; inspect $DEST." >&2; exit 1; }
fi

rsync -av \
  --exclude='.git/' --exclude='.env' --exclude='.env.*' --exclude='vendor/' \
  --exclude='node_modules/' --exclude='.dart_tool/' \
  --exclude='build/' --exclude='Pods/' --exclude='.gradle/' \
  --exclude='dist/' --exclude='__pycache__/' \
  --exclude='*.apk' --exclude='*.aab' --exclude='*.ipa' \
  --exclude='*.p8' --exclude='*.p12' --exclude='*.pem' \
  --exclude='*.jks' --exclude='*.keystore' \
  --exclude='*service-account*.json' --exclude='*firebase-adminsdk*.json' \
  "$SRC/" "$DEST/"

cd "$DEST"
git add -A
if git diff --cached --name-only | grep -Ei '(^|/)\.env$|(^|/)vendor/|(^|/)node_modules/|firebase-adminsdk|service-account|(^|/).*\.(pem|p8|p12|jks|keystore)$'; then
  echo "Security stop: sensitive paths are staged. No commit or push was performed." >&2
  exit 1
fi

if git diff --cached --quiet; then
  echo "No new file changes; checking for pending local commits."
else
  git diff --cached --stat
  git commit -m "feat: import School PDF Flutter Laravel Firebase and setup source"
fi
# Always push: a previous run may have committed locally but failed to upload.
git push origin main
git rev-parse HEAD
echo "Source upload complete. CI/release readiness must be checked separately."
