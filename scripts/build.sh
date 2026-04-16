#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(pwd)
OUT_DIR="$ROOT_DIR/site"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

pages=()

while IFS= read -r -d '' tex_file; do
  rel_path="${tex_file#./}"
  rel_dir=$(dirname "$rel_path")
  src_name=$(basename "$rel_path")
  base_name="${src_name%.tex}"
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

  pandoc -s -t html5 -M lang=en --extract-media="$media_dir" --resource-path="$rel_dir:figs" "$rel_path" -o "$out_dir/$base_name.html"

  pages+=("$rel_dir/$base_name")
done < <(find . -mindepth 2 -name '*.tex' -not -path './site/*' -print0 | sort -z)

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
