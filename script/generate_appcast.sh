#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/versioning.sh
source "$ROOT_DIR/script/versioning.sh"
# shellcheck source=script/sparkle_paths.sh
source "$ROOT_DIR/script/sparkle_paths.sh"

APP_NAME="CoreClipboard"
APP_VERSION="${APP_VERSION:-$(resolve_release_version)}"
BUILD_NUMBER="${BUILD_NUMBER:-$(resolve_build_number "$APP_VERSION")}"
DIST_DIR="$ROOT_DIR/dist"
DMG_PATH="${DMG_PATH:-$DIST_DIR/$APP_NAME-$APP_VERSION.dmg}"
RELEASE_NOTES_PATH="${RELEASE_NOTES_PATH:-$DIST_DIR/release-notes/$APP_VERSION.html}"
PUBLISH_DIR="$DIST_DIR/publish"
APPCAST_PATH="$PUBLISH_DIR/appcast.xml"
DOWNLOAD_BASE_URL="${DOWNLOAD_BASE_URL:-https://updates.coreclipboard.com/downloads}"
RELEASE_NOTES_BASE_URL="${RELEASE_NOTES_BASE_URL:-https://updates.coreclipboard.com/release-notes}"
APP_LINK_URL="${APP_LINK_URL:-https://updates.coreclipboard.com}"
SPARKLE_KEY_ACCOUNT="${SPARKLE_KEY_ACCOUNT:-coreclipboard}"
SPARKLE_PRIVATE_KEY_FILE="${SPARKLE_PRIVATE_KEY_FILE:-}"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "missing dmg: $DMG_PATH" >&2
  exit 1
fi

if [[ ! -f "$RELEASE_NOTES_PATH" ]]; then
  echo "missing release notes: $RELEASE_NOTES_PATH" >&2
  exit 1
fi

mkdir -p "$PUBLISH_DIR"

sign_tool="$(find_sparkle_tool sign_update)"
if [[ -n "$SPARKLE_PRIVATE_KEY_FILE" ]]; then
  sign_output="$("$sign_tool" --ed-key-file "$SPARKLE_PRIVATE_KEY_FILE" "$DMG_PATH")"
else
  sign_output="$("$sign_tool" --account "$SPARKLE_KEY_ACCOUNT" "$DMG_PATH")"
fi
signature="$(printf '%s\n' "$sign_output" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
file_length="$(printf '%s\n' "$sign_output" | sed -n 's/.*length="\([^"]*\)".*/\1/p')"
published_at="$(LC_ALL=C date -u +"%a, %d %b %Y %H:%M:%S +0000")"
dmg_name="$(basename "$DMG_PATH")"
release_notes_name="$(basename "$RELEASE_NOTES_PATH")"

if [[ -z "$signature" || -z "$file_length" ]]; then
  echo "failed to parse Sparkle signature output" >&2
  exit 1
fi

cat >"$APPCAST_PATH" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>CoreClipboard Updates</title>
    <link>$APP_LINK_URL</link>
    <description>Appcast for CoreClipboard</description>
    <language>en</language>
    <item>
      <title>Version $APP_VERSION</title>
      <link>$APP_LINK_URL</link>
      <sparkle:version>$BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>$APP_VERSION</sparkle:shortVersionString>
      <sparkle:releaseNotesLink>$RELEASE_NOTES_BASE_URL/$release_notes_name</sparkle:releaseNotesLink>
      <pubDate>$published_at</pubDate>
      <enclosure
        url="$DOWNLOAD_BASE_URL/$dmg_name"
        sparkle:edSignature="$signature"
        length="$file_length"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
EOF

printf '%s\n' "$APPCAST_PATH"
