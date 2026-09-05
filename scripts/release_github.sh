#!/usr/bin/env bash
# Usage: ./scripts/release_github.sh [notes...]
# Uploads the current built APK as a GitHub release tagged with the pubspec version.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

REPO="${GITHUB_REPO:-shelad3/rems}"
APK=build/app/outputs/flutter-apk/app-release.apk

[ -f "$APK" ] || { echo "APK not found. Run ./build_apk.sh first." >&2; exit 1; }

VER="$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)"
TAG="v$VER"
NOTES="${*:-REMS v$VER — new build}"

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "Release $TAG already exists — deleting it first."
  gh release delete "$TAG" --repo "$REPO" --yes
fi

gh release create "$TAG" "$APK" \
  --repo "$REPO" \
  --title "REMS v$VER" \
  --notes "$NOTES"

echo "Published $REPO@$TAG ($APK)"