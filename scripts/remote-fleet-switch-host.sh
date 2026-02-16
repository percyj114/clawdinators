#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <git-rev> <host>" >&2
  exit 2
fi

rev="$1"
host="$2"

export NIX_CONFIG="experimental-features = nix-command flakes"

nixos-rebuild switch --accept-flake-config --flake "github:openclaw/clawdinators/${rev}#${host}"
systemctl is-active clawdinator

install -d -m 0755 /var/lib/clawd/deploy
date -Is > /var/lib/clawd/deploy/last-switch.time
echo "${rev}" > /var/lib/clawd/deploy/last-switch.rev

current_rev="$(cat /run/current-system/configurationRevision 2> /dev/null || true)"
if [ -z "${current_rev}" ]; then
  current_rev="$(nixos-version --json 2> /dev/null | sed -n 's/.*"configurationRevision":"\([^"]*\)".*/\1/p' | head -n 1 || true)"
fi

if [ "${current_rev}" != "${rev}" ]; then
  echo "configurationRevision mismatch: expected ${rev}, got ${current_rev:-<empty>}" >&2
  exit 1
fi
