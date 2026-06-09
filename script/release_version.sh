#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/versioning.sh
source "$ROOT_DIR/script/versioning.sh"

usage() {
  cat <<EOF
usage: $0 [show|bump major|minor|patch]

Commands:
  show                 Print APP_VERSION and BUILD_NUMBER
  bump major|minor|patch
                       Increment VERSION and print the result
EOF
}

show_version() {
  local version build_number
  version="$(resolve_release_version)"
  build_number="$(resolve_build_number "$version")"
  printf 'APP_VERSION=%s\nBUILD_NUMBER=%s\n' "$version" "$build_number"
}

bump_version() {
  local release_type="$1"
  local version next_major next_minor next_patch
  version="$(read_version)"
  version_components "$version"

  next_major="$VERSION_MAJOR"
  next_minor="$VERSION_MINOR"
  next_patch="$VERSION_PATCH"

  case "$release_type" in
    major)
      next_major=$((VERSION_MAJOR + 1))
      next_minor=0
      next_patch=0
      ;;
    minor)
      next_minor=$((VERSION_MINOR + 1))
      next_patch=0
      ;;
    patch)
      next_patch=$((VERSION_PATCH + 1))
      ;;
    *)
      echo "unknown release type: $release_type" >&2
      usage >&2
      exit 2
      ;;
  esac

  version="$next_major.$next_minor.$next_patch"
  write_version "$version"
  show_version
}

command="${1:-show}"
case "$command" in
  show)
    show_version
    ;;
  bump)
    if [[ $# -ne 2 ]]; then
      usage >&2
      exit 2
    fi
    bump_version "$2"
    ;;
  --help|-h)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
