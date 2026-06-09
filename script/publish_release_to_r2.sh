#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/versioning.sh
source "$ROOT_DIR/script/versioning.sh"

APP_NAME="CoreClipboard"
APP_VERSION="${APP_VERSION:-$(resolve_release_version)}"
DIST_DIR="$ROOT_DIR/dist"
DMG_PATH="${DMG_PATH:-$DIST_DIR/$APP_NAME-$APP_VERSION.dmg}"
RELEASE_NOTES_PATH="${RELEASE_NOTES_PATH:-$DIST_DIR/release-notes/$APP_VERSION.html}"
APPCAST_PATH="${APPCAST_PATH:-$DIST_DIR/publish/appcast.xml}"

: "${R2_BUCKET_NAME:?set R2_BUCKET_NAME}"
: "${R2_ACCOUNT_ID:?set R2_ACCOUNT_ID}"
: "${R2_ACCESS_KEY_ID:?set R2_ACCESS_KEY_ID}"
: "${R2_SECRET_ACCESS_KEY:?set R2_SECRET_ACCESS_KEY}"

AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-https://$R2_ACCOUNT_ID.r2.cloudflarestorage.com}"
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="auto"

aws --endpoint-url "$AWS_ENDPOINT_URL" s3 cp "$DMG_PATH" "s3://$R2_BUCKET_NAME/downloads/$(basename "$DMG_PATH")"
aws --endpoint-url "$AWS_ENDPOINT_URL" s3 cp "$RELEASE_NOTES_PATH" "s3://$R2_BUCKET_NAME/release-notes/$(basename "$RELEASE_NOTES_PATH")" --content-type text/html
aws --endpoint-url "$AWS_ENDPOINT_URL" s3 cp "$APPCAST_PATH" "s3://$R2_BUCKET_NAME/appcast.xml" --content-type application/xml

printf 'Uploaded %s, %s, and %s to %s\n' \
  "$(basename "$DMG_PATH")" \
  "$(basename "$RELEASE_NOTES_PATH")" \
  "$(basename "$APPCAST_PATH")" \
  "$R2_BUCKET_NAME"
