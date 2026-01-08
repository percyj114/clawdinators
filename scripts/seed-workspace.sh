#!/usr/bin/env bash
set -euo pipefail

src="$1"
dst="$2"

if [ ! -d "$src" ]; then
  echo "seed-workspace: missing template dir: $src" >&2
  exit 1
fi

mkdir -p "$dst"

shopt -s nullglob
for file in "$src"/*.md; do
  name="$(basename "$file")"
  install -m 0644 "$file" "$dst/$name"
done

rm -f "$dst/BOOTSTRAP.md"
