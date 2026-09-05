#!/usr/bin/env bash
# Usage: ./scripts/bump_version.sh [patch|minor|major|x.y.z]
# Rewrites the version line in pubspec.yaml and bumps the build number.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

VER="$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}')"
CUR="${VER%+*}"
BUILD="${VER#*+}"

case "${1:-patch}" in
  patch) NEW="$(echo "$CUR" | awk -F. '{print $1"."$2"."$3+1}')" ;;
  minor) NEW="$(echo "$CUR" | awk -F. '{print $1"."$2+1".0"}')" ;;
  major) NEW="$(echo "$CUR" | awk -F. '{print $1+1".0.0"}')" ;;
  v*)    NEW="${1#v}" ;;
  *)     NEW="$1" ;;
esac

if [[ "$NEW" == "$CUR" ]]; then
  NBUILD=$((BUILD + 1))
else
  NBUILD=1
fi

sed -i "s/^version: .*/version: $NEW+$NBUILD/" pubspec.yaml
echo "pubspec.yaml -> version: $NEW+$NBUILD"