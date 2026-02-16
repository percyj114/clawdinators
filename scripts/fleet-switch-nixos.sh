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
  # Execute remote switch logic from a committed script (no inline deployment logic).
  remote_script_url="https://raw.githubusercontent.com/openclaw/clawdinators/${rev}/scripts/remote-fleet-switch-host.sh"
  remote_switch_cmd="$(printf 'set -euo pipefail; curl -fsSL %q -o /tmp/remote-fleet-switch-host.sh; chmod 700 /tmp/remote-fleet-switch-host.sh; /tmp/remote-fleet-switch-host.sh %q %q' "${remote_script_url}" "${rev}" "${host}")"

  bash scripts/aws-ssm-run.sh "${instance_id}" \
    "bash -lc $(printf '%q' "${remote_switch_cmd}")"

done
