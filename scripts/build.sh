#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(pwd)
OUT_DIR="$ROOT_DIR/site"
PANDOC_FILTER="$ROOT_DIR/pandoc/math105.lua"
PANDOC_HEADER="$ROOT_DIR/pandoc/math105-header.html"
HTML_PREP="$ROOT_DIR/scripts/prepare_html_source.py"
MATHJAX_URL="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

pages=()

while IFS= read -r -d '' tex_file; do
  rel_path="${tex_file#./}"
  rel_dir=$(dirname "$rel_path")
  src_name=$(basename "$rel_path")
  base_name="${src_name%.tex}"
  prepared_name="__${base_name}.html-prep.tex"
  out_dir="$OUT_DIR/$rel_dir"
  media_dir="$out_dir/media/$base_name"
  temp_dir=$(mktemp -d)

  mkdir -p "$out_dir" "$media_dir"

  echo "Building $rel_path"

  (
    cd "$ROOT_DIR/$rel_dir"
    pdflatex -interaction=nonstopmode -halt-on-error -output-directory "$temp_dir" "$src_name"
    pdflatex -interaction=nonstopmode -halt-on-error -output-directory "$temp_dir" "$src_name"
  )

  mv "$temp_dir/$base_name.pdf" "$out_dir/$base_name.pdf"
  rm -rf "$temp_dir"

  (
    cd "$ROOT_DIR/$rel_dir"
    python3 "$HTML_PREP" "$src_name" "$prepared_name"
    pandoc -s -t html5 --mathjax="$MATHJAX_URL" -M lang=en --lua-filter="$PANDOC_FILTER" --include-in-header="$PANDOC_HEADER" --extract-media="$media_dir" --resource-path=".:../figs:.." "$prepared_name" -o "$out_dir/$base_name.html"
    python3 "$HTML_PREP" "$src_name" "$prepared_name" --clean
  )

  python3 - <<'PY' "$out_dir/$base_name.html" "$out_dir/" "$rel_dir/"
from pathlib import Path
import sys

html_path = Path(sys.argv[1])
abs_prefix = sys.argv[2]
rel_prefix = sys.argv[3]
content = html_path.read_text()
content = content.replace(abs_prefix, "")
content = content.replace('src="' + rel_prefix + 'media/', 'src="media/')
html_path.write_text(content)
PY

  pages+=("$rel_dir/$base_name")
done < <(find . -mindepth 2 -name '*.tex' -not -path './site/*' -not -name '__*.html-prep.tex' -not -name '*_tikz_*.tex' -print0 | sort -z)

index_file="$OUT_DIR/index.html"

{
  printf '%s\n' '<!DOCTYPE html>'
  printf '%s\n' '<html lang="en">'
  printf '%s\n' '<head>'
  printf '%s\n' '  <meta charset="utf-8" />'
  printf '%s\n' '  <meta name="viewport" content="width=device-width, initial-scale=1" />'
  printf '%s\n' '  <title>Math105</title>'
  printf '%s\n' '  <style>body{font-family:system-ui,sans-serif;max-width:48rem;margin:2rem auto;padding:0 1rem;line-height:1.5}li{margin:0.5rem 0}</style>'
  printf '%s\n' '</head>'
  printf '%s\n' '<body>'
  printf '%s\n' '  <h1>Math105</h1>'
  printf '%s\n' '  <p>Published lesson files.</p>'
  printf '%s\n' '  <ul>'

  for page in "${pages[@]}"; do
    printf '    <li><a href="%s.html">%s</a> (<a href="%s.pdf">PDF</a>)</li>\n' "$page" "$page" "$page"
  done

  printf '%s\n' '  </ul>'
  printf '%s\n' '</body>'
  printf '%s\n' '</html>'
} > "$index_file"

touch "$OUT_DIR/.nojekyll"
