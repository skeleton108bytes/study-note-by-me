#!/usr/bin/env bash
set -e

rm -rf site && mkdir -p site
cp style.css site/
[ -d notes/images ] && cp -r notes/images site/images

count=0
INDEX=$(mktemp)

# 1. Convert each note (including subfolders)
while IFS= read -r -d '' f; do
  rel="${f#notes/}"              # e.g. Ielts/Line graph.md
  out="site/${rel%.md}.html"     # e.g. site/Ielts/Line graph.html
  name=$(basename "$f" .md)
  dir=$(dirname "$rel")
  mkdir -p "$(dirname "$out")"

  # depth prefix so CSS and images resolve from subfolders
  if [ "$dir" = "." ]; then root=""; else root="../"; fi

  # Convert Obsidian image embeds ![[img.png]] or ![[img.png|300]]
  sed -E "s#!\[\[([^]|]+)(\|[^]]*)?\]\]#![](<${root}images/\1>)#g" "$f" | \
  pandoc -f gfm+wikilinks_title_after_pipe+yaml_metadata_block \
    --template=template.html \
    --lua-filter=links.lua \
    -M title="$name" \
    -M root="$root" \
    -o "$out"

  echo "$rel" >> "$INDEX"
  count=$((count+1))
done < <(find notes -name "*.md" -print0 | sort -z)

# 2. Generate the index page, grouped by folder
{
  current=""
  while IFS= read -r rel; do
    dir=$(dirname "$rel")
    if [ "$dir" != "$current" ]; then
      current="$dir"
      [ "$dir" != "." ] && printf '\n## %s\n\n' "$dir"
    fi
    name=$(basename "$rel" .md)
    href="${rel%.md}.html"
    href="${href// /%20}"
    echo "- [$name]($href)"
  done < <(sort "$INDEX")
} | pandoc -f gfm --template=template.html \
    -M title="Study Notes" -M root="" -o site/index.html

rm -f "$INDEX"
echo "Build finished: $count notes"