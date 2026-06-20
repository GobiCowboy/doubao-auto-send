#!/bin/zsh
set -euo pipefail

APP_NAME="AutoSend"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SWIFT_DIR="$PROJECT_DIR/Swift"
BUILD_DIR="$(cd "$SWIFT_DIR" && swift build -c release --show-bin-path)"
APP_BUNDLE="$SWIFT_DIR/$APP_NAME.app"
ZIP_PATH="$SWIFT_DIR/$APP_NAME.zip"
INSTALL_BUNDLE="/Applications/$APP_NAME.app"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-Apple-Notary}"

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo "SIGNING_IDENTITY is required, for example: Developer ID Application: Your Name (TEAMID)" >&2
  exit 1
fi

rm -rf "$APP_BUNDLE" "$ZIP_PATH"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "$SWIFT_DIR/Info.plist" "$APP_BUNDLE/Contents/"
cp "$SWIFT_DIR/Resources/"*.icns "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true

codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_BUNDLE"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
spctl -a -vv -t exec "$APP_BUNDLE"

rm -rf "$INSTALL_BUNDLE"
ditto "$APP_BUNDLE" "$INSTALL_BUNDLE"

echo "\n✅ Notarized app is ready: $APP_BUNDLE"
echo "✅ Installed to: $INSTALL_BUNDLE"
