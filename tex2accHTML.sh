#!/usr/bin/env bash
set -euo pipefail

input_path="$1"
input_dir=$(dirname "$input_path")
input_file=$(basename "$input_path")
base_name="${input_file%.tex}"
prepared_name="__${base_name}.html-prep.tex"
script_dir=$(cd "$(dirname "$0")" && pwd)

(
  cd "$input_dir"
  python3 "$script_dir/scripts/prepare_html_source.py" "$input_file" "$prepared_name"
  pandoc -s -t html5 --mathjax --metadata=lang=en --lua-filter="$script_dir/pandoc/math105.lua" --include-in-header="$script_dir/pandoc/math105-header.html" --extract-media=media --resource-path=".:../figs:.." "$prepared_name"
  python3 "$script_dir/scripts/prepare_html_source.py" "$input_file" "$prepared_name" --clean
) | pbcopy

echo "if no errors then html copied to clipboard"
