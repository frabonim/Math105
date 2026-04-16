#!/usr/bin/env bash
set -euo pipefail

input_path="$1"
input_dir=$(dirname "$input_path")
input_file=$(basename "$input_path")
script_dir=$(cd "$(dirname "$0")" && pwd)

(
  cd "$input_dir"
  pandoc -s -t html5 --metadata=lang=en --lua-filter="$script_dir/pandoc/math105.lua" --include-in-header="$script_dir/pandoc/math105-header.html" --extract-media=media --resource-path=".:../figs:.." "$input_file"
) | pbcopy

echo "if no errors then html copied to clipboard"
