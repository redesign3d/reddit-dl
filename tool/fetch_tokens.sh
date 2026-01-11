#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$root_dir/assets/tokens"

curl -L "https://raw.githubusercontent.com/jcmrs/claude-visual-style-guide/main/src/claude-design-tokens.json" \
  -o "$root_dir/assets/tokens/claude-design-tokens.json"

curl -L "https://raw.githubusercontent.com/jcmrs/claude-visual-style-guide/main/src/styles/globals.css" \
  -o "$root_dir/assets/tokens/claude-globals.css"
