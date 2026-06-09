#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

find_sparkle_framework() {
  local framework
  framework="$(find "$ROOT_DIR/.build" -path '*/Sparkle.framework' -type d -print | head -n 1)"

  if [[ -z "$framework" ]]; then
    echo "unable to locate Sparkle.framework under $ROOT_DIR/.build" >&2
    exit 1
  fi

  printf '%s' "$framework"
}

find_sparkle_tool() {
  local tool_name="$1"
  local tool_path
  tool_path="$(find "$ROOT_DIR/.build" -path "*/$tool_name" -type f -print | head -n 1)"

  if [[ -z "$tool_path" ]]; then
    echo "unable to locate Sparkle tool: $tool_name" >&2
    exit 1
  fi

  printf '%s' "$tool_path"
}
