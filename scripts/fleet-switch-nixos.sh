#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <git-rev> [host1 host2 ...]" >&2
  echo "example: $0 ${GITHUB_SHA:-<sha>} clawdinator-1 clawdinator-2" >&2
  exit 2
fi

rev="$1"
shift

if [ "$#" -eq 0 ]; then
  # Canary order.
  hosts=(clawdinator-1 clawdinator-2)
else
  hosts=("$@")
fi

for host in "${hosts[@]}"; do
  echo "== deploy: ${host} @ ${rev} ==" >&2
  instance_id="$(bash scripts/aws-resolve-instance-id.sh "${host}")"

  # Run everything under bash -lc so PATH + profiles behave similarly to an interactive session.
  # We also force flakes enabled for safety.
  bash scripts/aws-ssm-run.sh "${instance_id}" \
    "bash -lc 'set -euo pipefail; export NIX_CONFIG=\"experimental-features = nix-command flakes\"; nixos-rebuild switch --accept-flake-config --flake github:openclaw/clawdinators/${rev}#${host}; systemctl is-active clawdinator; install -d -m 0755 /var/lib/clawd/deploy; date -Is > /var/lib/clawd/deploy/last-switch.time; echo ${rev} > /var/lib/clawd/deploy/last-switch.rev; test \"$(cat /run/current-system/configurationRevision 2>/dev/null || true)\" = \"${rev}\"'"

done
