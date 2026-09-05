#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS="$ROOT/.mpesa_keys"

if [[ ! -f "$KEYS" ]]; then
  echo "Missing $KEYS — create it with MPESA_CONSUMER_KEY/MPESA_CONSUMER_SECRET/MPESA_ENV" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a; source "$KEYS"; set +a

DART_DEFINES=(
  --dart-define=MPESA_CONSUMER_KEY="$MPESA_CONSUMER_KEY"
  --dart-define=MPESA_CONSUMER_SECRET="$MPESA_CONSUMER_SECRET"
  --dart-define=MPESA_ENV="${MPESA_ENV:-sandbox}"
  --dart-define=MPESA_PASSKEY="${MPESA_PASSKEY:-}"
  --dart-define=MPESA_SHORTCODE="${MPESA_SHORTCODE:-}"
  --dart-define=MPESA_CALLBACK_URL="${MPESA_CALLBACK_URL:-}"
  --dart-define=SUPABASE_FUNCTIONS_URL="${SUPABASE_FUNCTIONS_URL:-}"
  --dart-define=GITHUB_REPO="${GITHUB_REPO:-}"
)

cd "$ROOT"
flutter build apk --release "${DART_DEFINES[@]}" "$@"