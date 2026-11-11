#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> [1/5] Building mdBook static assets..."
if command -v mdbook >/dev/null 2>&1; then
  mdbook build
elif [ -d "book" ] && [ -f "book/index.html" ]; then
  echo "Notice: 'mdbook' command not found, using existing 'book/' directory."
else
  echo "Error: mdbook not found and 'book/' directory is missing or incomplete." >&2
  exit 1
fi

echo "==> [2/5] Ensuring app launcher icons are generated..."
if [ ! -f "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" ]; then
  ./scripts/generate-icons.sh
fi

echo "==> [3/5] Syncing web assets to Capacitor Android..."
export XDG_STATE_HOME="${XDG_STATE_HOME:-/tmp}"
npx cap sync android

echo "==> [4/5] Preparing release keystore..."
KEYSTORE_PATH="${REPO_ROOT}/android/release.keystore"
KEYSTORE_PASS="broclette123"
KEY_ALIAS="broclette"

if [ ! -f "$KEYSTORE_PATH" ]; then
  echo "Generating local self-signed release keystore..."
  keytool -genkeypair -v \
    -keystore "$KEYSTORE_PATH" \
    -storepass "$KEYSTORE_PASS" \
    -alias "$KEY_ALIAS" \
    -keypass "$KEYSTORE_PASS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Broclette, OU=Broclette, O=Broclette, L=Wallis, C=CH"
fi

VERSION_NAME="${1:-1.0}"
VERSION_CODE="${2:-1}"

echo "==> [5/5] Building signed Release APK (VersionName: $VERSION_NAME, VersionCode: $VERSION_CODE)..."
cd "${REPO_ROOT}/android"
chmod +x gradlew

if [ -d "/tmp/tools/jdk-21" ]; then
  export JAVA_HOME="/tmp/tools/jdk-21"
  export PATH="/tmp/tools/jdk-21/bin:$PATH"
fi

if [ -z "${ANDROID_HOME:-}" ] && [ -z "${ANDROID_SDK_ROOT:-}" ] && [ ! -f "local.properties" ]; then
  if [ -d "/tmp/tools/android-sdk" ]; then
    export ANDROID_HOME="/tmp/tools/android-sdk"
  elif [ -d "$HOME/Android/Sdk" ]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
  fi
fi

./gradlew assembleRelease \
  -PRELEASE_STORE_FILE="${KEYSTORE_PATH}" \
  -PRELEASE_STORE_PASSWORD="${KEYSTORE_PASS}" \
  -PRELEASE_KEY_ALIAS="${KEY_ALIAS}" \
  -PRELEASE_KEY_PASSWORD="${KEYSTORE_PASS}" \
  -PAPP_VERSION_NAME="${VERSION_NAME}" \
  -PAPP_VERSION_CODE="${VERSION_CODE}"

APK_SRC="${REPO_ROOT}/android/app/build/outputs/apk/release/app-release.apk"
APK_DEST="${REPO_ROOT}/broclette.apk"

if [ -f "$APK_SRC" ]; then
  cp "$APK_SRC" "$APK_DEST"
  echo "==> SUCCESS! Signed release APK generated at: $APK_DEST"
else
  echo "Error: Expected APK not found at $APK_SRC" >&2
  exit 1
fi
