#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="CoreClipboard"
BUNDLE_ID="com.hices.CoreClipboard"
MIN_SYSTEM_VERSION="14.0"
FEED_URL="${SPARKLE_FEED_URL:-https://updates.coreclipboard.com/appcast.xml}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/versioning.sh
source "$ROOT_DIR/script/versioning.sh"
# shellcheck source=script/sparkle_paths.sh
source "$ROOT_DIR/script/sparkle_paths.sh"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
SPARKLE_PUBLIC_KEY_FILE="${SPARKLE_PUBLIC_KEY_FILE:-$ROOT_DIR/SPARKLE_PUBLIC_ED_KEY}"
APP_ICON_SOURCE="${APP_ICON_SOURCE:-$ROOT_DIR/CopyIcon.png}"
APP_ICON_NAME="AppIcon"
APP_ICON_PATH="$DIST_DIR/$APP_ICON_NAME.icns"
APP_VERSION="$(resolve_release_version)"
BUILD_NUMBER="$(resolve_build_number "$APP_VERSION")"
SPARKLE_PUBLIC_KEY=""

if [[ -f "$SPARKLE_PUBLIC_KEY_FILE" ]]; then
  SPARKLE_PUBLIC_KEY="$(tr -d '\r\n' <"$SPARKLE_PUBLIC_KEY_FILE")"
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --product "$APP_NAME"
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"
SPARKLE_FRAMEWORK="$(find_sparkle_framework)"
"$ROOT_DIR/script/generate_app_icon.sh" "$APP_ICON_SOURCE" "$APP_ICON_PATH" >/dev/null

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
mkdir -p "$APP_FRAMEWORKS"
mkdir -p "$APP_RESOURCES"
ditto "$SPARKLE_FRAMEWORK" "$APP_FRAMEWORKS/Sparkle.framework"
cp "$APP_ICON_PATH" "$APP_RESOURCES/$APP_ICON_NAME.icns"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>$APP_ICON_NAME</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>SUFeedURL</key>
  <string>$FEED_URL</string>
  <key>SUPublicEDKey</key>
  <string>$SPARKLE_PUBLIC_KEY</string>
</dict>
</plist>
PLIST

if [[ "$SIGN_IDENTITY" != "-" ]]; then
  sign_args=(--force --options runtime --timestamp --sign "$SIGN_IDENTITY")
else
  sign_args=(--force --sign "$SIGN_IDENTITY")
fi

while IFS= read -r nested_code; do
  codesign "${sign_args[@]}" "$nested_code"
done < <(find "$APP_CONTENTS" \
  \( -name "*.xpc" -o -name "*.framework" -o -name "*.app" -o -name "Autoupdate" \) \
  -print | awk '{ print length, $0 }' | sort -rn | cut -d" " -f2-)

codesign "${sign_args[@]}" "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  --bundle|bundle)
    ;;
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--bundle|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
