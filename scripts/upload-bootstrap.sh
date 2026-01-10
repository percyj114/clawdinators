#!/usr/bin/env bash
set -euo pipefail

bucket="${S3_BUCKET:?S3_BUCKET required}"
region="${AWS_REGION:?AWS_REGION required}"
prefix="${BOOTSTRAP_PREFIX:-bootstrap/clawdinator-1}"

secrets_dir="${SECRETS_DIR:-nix/age-secrets}"
age_key_file="${AGE_KEY_FILE:-nix/keys/clawdinator.agekey}"
repo_seeds_dir="${REPO_SEEDS_DIR:-repo-seeds}"

if [ ! -f "${age_key_file}" ]; then
  echo "Missing age key: ${age_key_file}" >&2
  exit 1
fi

if [ ! -d "${secrets_dir}" ]; then
  echo "Missing secrets dir: ${secrets_dir}" >&2
  exit 1
fi

if [ ! -d "${repo_seeds_dir}" ]; then
  echo "Missing repo seeds dir: ${repo_seeds_dir}" >&2
  exit 1
fi

workdir="$(mktemp -d)"
cleanup() {
  rm -rf "${workdir}"
}
trap cleanup EXIT

staging="${workdir}/staging"
mkdir -p "${staging}/secrets"
cp "${age_key_file}" "${staging}/clawdinator.agekey"
cp -a "${secrets_dir}/." "${staging}/secrets/"

tar --zstd -cf "${workdir}/secrets.tar.zst" -C "${staging}" .
tar --zstd -cf "${workdir}/repo-seeds.tar.zst" -C "${repo_seeds_dir}" .

aws s3 cp "${workdir}/secrets.tar.zst" "s3://${bucket}/${prefix}/secrets.tar.zst" \
  --region "${region}" \
  --only-show-errors
aws s3 cp "${workdir}/repo-seeds.tar.zst" "s3://${bucket}/${prefix}/repo-seeds.tar.zst" \
  --region "${region}" \
  --only-show-errors

echo "Uploaded bootstrap artifacts to s3://${bucket}/${prefix}/"
