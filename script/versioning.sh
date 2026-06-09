#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${VERSION_FILE:-$ROOT_DIR/VERSION}"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

read_version() {
  if [[ ! -f "$VERSION_FILE" ]]; then
    echo "missing version file: $VERSION_FILE" >&2
    exit 1
  fi

  trim "$(tr -d '\r' <"$VERSION_FILE")"
}

validate_version() {
  local version="$1"
  if [[ ! "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "invalid semantic version: $version" >&2
    exit 1
  fi
}

version_components() {
  local version="$1"
  validate_version "$version"
  IFS='.' read -r VERSION_MAJOR VERSION_MINOR VERSION_PATCH <<<"$version"
  export VERSION_MAJOR VERSION_MINOR VERSION_PATCH
}

build_number_for_version() {
  local version="$1"
  version_components "$version"

  if (( VERSION_MINOR > 99 || VERSION_PATCH > 99 )); then
    echo "minor and patch versions must stay below 100 to derive build numbers" >&2
    exit 1
  fi

  printf '%d' "$((VERSION_MAJOR * 10000 + VERSION_MINOR * 100 + VERSION_PATCH))"
}

resolve_release_version() {
  local version="${APP_VERSION:-$(read_version)}"
  validate_version "$version"
  printf '%s' "$version"
}

resolve_build_number() {
  local version="$1"
  local build_number="${BUILD_NUMBER:-$(build_number_for_version "$version")}"

  if [[ ! "$build_number" =~ ^[0-9]+$ ]]; then
    echo "build number must be numeric: $build_number" >&2
    exit 1
  fi

  printf '%s' "$build_number"
}

write_version() {
  local version="$1"
  validate_version "$version"
  printf '%s\n' "$version" >"$VERSION_FILE"
}
