#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/versioning.sh
source "$ROOT_DIR/script/versioning.sh"

CHANGELOG_PATH="${CHANGELOG_PATH:-$ROOT_DIR/CHANGELOG.md}"
APP_VERSION="${APP_VERSION:-$(resolve_release_version)}"
DIST_DIR="$ROOT_DIR/dist"
OUTPUT_DIR="$DIST_DIR/release-notes"
OUTPUT_PATH="$OUTPUT_DIR/$APP_VERSION.html"

if [[ ! -f "$CHANGELOG_PATH" ]]; then
  echo "missing changelog: $CHANGELOG_PATH" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

release_section="$(awk -v version="$APP_VERSION" '
  $0 ~ "^## " version "([[:space:]]+-.*)?$" { in_section=1; next }
  in_section && /^## / { exit }
  in_section { print }
' "$CHANGELOG_PATH")"

if [[ -z "$release_section" ]]; then
  echo "unable to find changelog section for version $APP_VERSION" >&2
  exit 1
fi

{
  printf '%s\n' '<!DOCTYPE html>'
  printf '%s\n' '<html lang="en"><head><meta charset="utf-8"><title>CoreClipboard '"$APP_VERSION"'</title></head><body>'
  printf '<h1>CoreClipboard %s</h1>\n' "$APP_VERSION"

  current_list=0
  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      if [[ "$current_list" -eq 1 ]]; then
        printf '%s\n' '</ul>'
        current_list=0
      fi
      continue
    fi

    if [[ "$line" == '### '* ]]; then
      if [[ "$current_list" -eq 1 ]]; then
        printf '%s\n' '</ul>'
        current_list=0
      fi
      printf '<h2>%s</h2>\n' "${line#\#\#\# }"
      continue
    fi

    if [[ "$line" == '- '* ]]; then
      if [[ "$current_list" -eq 0 ]]; then
        printf '%s\n' '<ul>'
        current_list=1
      fi
      printf '<li>%s</li>\n' "${line#- }"
      continue
    fi

    if [[ "$current_list" -eq 1 ]]; then
      printf '%s\n' '</ul>'
      current_list=0
    fi
    printf '<p>%s</p>\n' "$line"
  done <<<"$release_section"

  if [[ "$current_list" -eq 1 ]]; then
    printf '%s\n' '</ul>'
  fi

  printf '%s\n' '</body></html>'
} >"$OUTPUT_PATH"

printf '%s\n' "$OUTPUT_PATH"
