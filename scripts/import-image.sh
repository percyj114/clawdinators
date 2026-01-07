#!/usr/bin/env bash
set -euo pipefail

image_url="${1:-}"
if [ -z "${image_url}" ]; then
  echo "Usage: import-image.sh <image-url>" >&2
  exit 1
fi

location="${HCLOUD_LOCATION:-nbg1}"
description="${IMAGE_DESCRIPTION:-clawdinator-nixos}"
labels="${IMAGE_LABELS:-clawdinator=true}"

docker run --rm \
  -e HCLOUD_TOKEN="${HCLOUD_TOKEN:?HCLOUD_TOKEN required}" \
  ghcr.io/apricote/hcloud-upload-image:latest \
  upload \
  --image-url "${image_url}" \
  --architecture x86 \
  --compression zstd \
  --location "${location}" \
  --description "${description}" \
  --labels "${labels}"
