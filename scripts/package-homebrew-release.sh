#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-1.0.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT/.build/homebrew-derived-data"
DIST_DIR="$ROOT/dist"
APP_PATH="$DERIVED_DATA/Build/Products/Release/Guderian.app"
ZIP_PATH="$DIST_DIR/Guderian-$VERSION.zip"

mkdir -p "$DIST_DIR"

xcodebuild \
  -project "$ROOT/Guderian.xcodeproj" \
  -scheme Guderian \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app was not built at $APP_PATH" >&2
  exit 1
fi

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$APP_PATH"
elif ! codesign --verify --deep --strict "$APP_PATH" >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_PATH"
fi

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_PATH"
fi

ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Package: $ZIP_PATH"
echo "SHA256: $(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
