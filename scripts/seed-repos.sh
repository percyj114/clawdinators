#!/usr/bin/env bash
set -euo pipefail

list_file="$1"
base_dir="$2"

if [ ! -f "$list_file" ]; then
  echo "seed-repos: missing repo list: $list_file" >&2
  exit 1
fi

mkdir -p "$base_dir"

while IFS=$'\t' read -r name url branch; do
  [ -z "${name:-}" ] && continue
  [ -z "${url:-}" ] && continue

  dest="$base_dir/$name"
  if [ ! -d "$dest/.git" ]; then
    if [ -n "${branch:-}" ]; then
      git clone --depth 1 --branch "$branch" "$url" "$dest"
    else
      git clone --depth 1 "$url" "$dest"
    fi
    continue
  fi

  git -C "$dest" fetch --all --prune
  if [ -n "${branch:-}" ]; then
    git -C "$dest" checkout "$branch"
    git -C "$dest" reset --hard "origin/$branch"
  else
    git -C "$dest" reset --hard "origin/HEAD"
  fi
done < "$list_file"
