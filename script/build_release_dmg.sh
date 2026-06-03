#!/usr/bin/env bash
set -euo pipefail

APP_NAME="CoreClipboard"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_STAGING_DIR="$DIST_DIR/dmg-staging"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
DEFAULT_SIGN_IDENTITY="Developer ID Application: SHAWN MICHAEL HICE (VY262TJ9SZ)"
DEFAULT_NOTARY_PROFILE="coreclipboard-notary"

SIGN_IDENTITY="${SIGN_IDENTITY:-$DEFAULT_SIGN_IDENTITY}"
NOTARY_PROFILE="${NOTARY_PROFILE:-$DEFAULT_NOTARY_PROFILE}"

usage() {
  cat <<EOF
usage: $0 [--skip-notarize] [--skip-staple] [--help]

Builds the signed app bundle, packages a DMG, notarizes it, staples it, and
validates the final result.

Environment variables:
  SIGN_IDENTITY   Code signing identity to use
  NOTARY_PROFILE  notarytool keychain profile to use
EOF
}

SKIP_NOTARIZE=0
SKIP_STAPLE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-notarize)
      SKIP_NOTARIZE=1
      ;;
    --skip-staple)
      SKIP_STAPLE=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ "$SKIP_STAPLE" -eq 1 && "$SKIP_NOTARIZE" -eq 0 ]]; then
  echo "warning: --skip-staple leaves a notarized DMG unstapled" >&2
fi

echo "==> Building signed app bundle"
SIGN_IDENTITY="$SIGN_IDENTITY" "$ROOT_DIR/script/build_and_run.sh" --bundle

echo "==> Packaging DMG"
rm -rf "$DMG_STAGING_DIR"
mkdir -p "$DMG_STAGING_DIR"
cp -R "$APP_BUNDLE" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "==> Signing DMG"
codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"

if [[ "$SKIP_NOTARIZE" -eq 0 ]]; then
  echo "==> Notarizing DMG with profile $NOTARY_PROFILE"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
fi

if [[ "$SKIP_STAPLE" -eq 0 && "$SKIP_NOTARIZE" -eq 0 ]]; then
  echo "==> Stapling notarization ticket"
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
fi

echo "==> Validating DMG"
spctl -a -vvv -t open --context context:primary-signature "$DMG_PATH"

echo "Release DMG ready at $DMG_PATH"
