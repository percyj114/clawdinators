#!/usr/bin/env bash
set -euo pipefail

info=/etc/clawdinator/build-info.json
if [ ! -f "$info" ]; then
  echo "missing $info" >&2
  exit 1
fi

now="$(date +%s)"

human_age_from_epoch() {
  local then_ts="$1"
  if [ -z "$then_ts" ]; then
    printf '%s' "unknown"
    return 0
  fi

  # Accept either "null" or non-numeric.
  if [ "$then_ts" = "null" ]; then
    printf '%s' "unknown"
    return 0
  fi
  if ! [[ "$then_ts" =~ ^[0-9]+$ ]]; then
    printf '%s' "unknown"
    return 0
  fi

  local delta=$((now - then_ts))
  if [ "$delta" -lt 0 ]; then
    delta=0
  fi
  local d=$((delta / 86400))
  local h=$(((delta % 86400) / 3600))
  local m=$(((delta % 3600) / 60))
  if [ "$d" -gt 0 ]; then
    printf '%sd%sh%sm' "$d" "$h" "$m"
  elif [ "$h" -gt 0 ]; then
    printf '%sh%sm' "$h" "$m"
  else
    printf '%sm' "$m"
  fi
}

human_age_from_iso() {
  local iso="$1"
  if [ -z "$iso" ]; then
    printf '%s' "unknown"
    return 0
  fi
  local epoch
  epoch="$(date -d "$iso" +%s 2>/dev/null || true)"
  human_age_from_epoch "$epoch"
}

deployed_rev="$(cat /run/current-system/configurationRevision 2>/dev/null || true)"
if [ -z "$deployed_rev" ]; then
  deployed_rev="$(nixos-version --json 2>/dev/null | jq -r '.configurationRevision // empty' || true)"
fi
if [ -z "$deployed_rev" ]; then
  deployed_rev="unknown"
fi

desired_rev="$(jq -r '.clawdinators.rev // empty' "$info")"
if [ -z "$desired_rev" ]; then
  desired_rev="unknown"
fi

nix_openclaw_rev="$(jq -r '.nixOpenclaw.rev // empty' "$info")"
nix_openclaw_lm="$(jq -r '.nixOpenclaw.lastModified // empty' "$info")"

nixpkgs_rev="$(jq -r '.nixpkgs.rev // empty' "$info")"
nixpkgs_lm="$(jq -r '.nixpkgs.lastModified // empty' "$info")"

openclaw_rev="$(jq -r '.openclaw.rev // empty' "$info")"

last_switch_time=""
if [ -f /var/lib/clawd/deploy/last-switch.time ]; then
  last_switch_time="$(tr -d '\n' </var/lib/clawd/deploy/last-switch.time)"
fi
last_switch_rev=""
if [ -f /var/lib/clawd/deploy/last-switch.rev ]; then
  last_switch_rev="$(tr -d '\n' </var/lib/clawd/deploy/last-switch.rev)"
fi

echo "clawdinators: $deployed_rev (desired: $desired_rev)"
if [ -n "$last_switch_time" ]; then
  echo "  deployed: $last_switch_time ($(human_age_from_iso "$last_switch_time") ago)"
fi
if [ -n "$last_switch_rev" ]; then
  echo "  last-switch.rev: $last_switch_rev"
fi

echo "nix-openclaw: $nix_openclaw_rev (lock age: $(human_age_from_epoch "$nix_openclaw_lm"))"
echo "nixpkgs:     $nixpkgs_rev (lock age: $(human_age_from_epoch "$nixpkgs_lm"))"

echo "openclaw:    $openclaw_rev"

# Optional: enrich OpenClaw with commit timestamp/age via GitHub API (requires auth).
if [ -n "$openclaw_rev" ] && command -v gh >/dev/null 2>&1; then
  if gh auth status -h github.com >/dev/null 2>&1; then
    openclaw_date="$(gh api \
      -H 'Accept: application/vnd.github+json' \
      "/repos/openclaw/openclaw/commits/${openclaw_rev}" \
      --jq '.commit.committer.date' 2>/dev/null || true)"
    if [ -n "$openclaw_date" ]; then
      echo "  commit:   $openclaw_date ($(human_age_from_iso "$openclaw_date") ago)"
    fi
  fi
fi

if [ "$#" -ge 1 ] && [ "$1" = "--json" ]; then
  jq -c '.' "$info"
fi
