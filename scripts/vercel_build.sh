#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.44.8"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export FLUTTER_SUPPRESS_ANALYTICS=true
export CI=true
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0=safe.directory
export GIT_CONFIG_VALUE_0='*'

if [[ ! -x "$ROOT/flutter/bin/flutter" ]]; then
  echo "Installing Flutter ${FLUTTER_VERSION}..."
  rm -rf "$ROOT/flutter"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$ROOT/flutter"
fi

export PATH="$ROOT/flutter/bin:$PATH"

flutter config --no-analytics --enable-web
flutter precache --web
flutter pub get
flutter build web --release --base-href /
