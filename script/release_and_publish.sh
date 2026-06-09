#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/versioning.sh
source "$ROOT_DIR/script/versioning.sh"

usage() {
  cat <<EOF
usage: $0 [--bump major|minor|patch] [--skip-publish]

Builds the signed release DMG, generates release notes and appcast metadata,
and optionally uploads the release to Cloudflare R2.
EOF
}

SKIP_PUBLISH=0
BUMP_KIND=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bump)
      BUMP_KIND="${2:-}"
      shift
      ;;
    --skip-publish)
      SKIP_PUBLISH=1
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

if [[ -n "$BUMP_KIND" ]]; then
  "$ROOT_DIR/script/release_version.sh" bump "$BUMP_KIND" >/dev/null
fi

APP_VERSION="$(resolve_release_version)"
BUILD_NUMBER="$(resolve_build_number "$APP_VERSION")"

APP_VERSION="$APP_VERSION" BUILD_NUMBER="$BUILD_NUMBER" "$ROOT_DIR/script/build_release_dmg.sh"
APP_VERSION="$APP_VERSION" BUILD_NUMBER="$BUILD_NUMBER" "$ROOT_DIR/script/generate_release_notes.sh"
APP_VERSION="$APP_VERSION" BUILD_NUMBER="$BUILD_NUMBER" "$ROOT_DIR/script/generate_appcast.sh"

if [[ "$SKIP_PUBLISH" -eq 0 ]]; then
  APP_VERSION="$APP_VERSION" BUILD_NUMBER="$BUILD_NUMBER" "$ROOT_DIR/script/publish_release_to_r2.sh"
fi

printf 'Release ready for %s (%s)\n' "$APP_VERSION" "$BUILD_NUMBER"
