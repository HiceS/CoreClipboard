#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ICON="${1:-$ROOT_DIR/CopyIcon.png}"
OUTPUT_ICNS="${2:-$ROOT_DIR/dist/AppIcon.icns}"
ICONSET_DIR="${OUTPUT_ICNS%.icns}.iconset"

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "missing source icon: $SOURCE_ICON" >&2
  exit 1
fi

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

write_icon() {
  local size="$1"
  local name="$2"
  sips -z "$size" "$size" "$SOURCE_ICON" --out "$ICONSET_DIR/$name" >/dev/null
}

write_icon 16 icon_16x16.png
write_icon 32 icon_16x16@2x.png
write_icon 32 icon_32x32.png
write_icon 64 icon_32x32@2x.png
write_icon 128 icon_128x128.png
write_icon 256 icon_128x128@2x.png
write_icon 256 icon_256x256.png
write_icon 512 icon_256x256@2x.png
write_icon 512 icon_512x512.png
write_icon 1024 icon_512x512@2x.png

mkdir -p "$(dirname "$OUTPUT_ICNS")"
xcrun iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

printf '%s\n' "$OUTPUT_ICNS"
