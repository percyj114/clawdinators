# OpenTofu (AWS Infra)

Goal: manage the CLAWDINATOR fleet infrastructure (S3 image bucket, VM import role, EFS, EC2 instances, and control-plane Lambda).

The shared image bucket is not image-only. It also stores bootstrap bundles, age-encrypted secrets, and Terraform remote state. Raw image uploads therefore use a prefix-scoped lifecycle rule: only top-level `clawdinator-nixos-*` objects expire automatically. Bootstrap, secrets, and state are intentionally retained.

## Prereqs
- AWS credentials with permissions to manage IAM (use your homelab-admin key locally).
- Fleet registry: `nix/instances.json` (authoritative instance list).

## Usage

```sh
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=eu-central-1
export TF_VAR_aws_region=eu-central-1
export TF_VAR_manage_instances=true
export TF_VAR_ami_id=ami-...   # required when manage_instances is true
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"   # required when manage_instances is true
```

### Remote state (S3 + Dynamo)

```sh
tofu init \
  -backend-config="bucket=clawdinator-images-eu1-20260107165216" \
  -backend-config="key=state/clawdinators.tfstate" \
  -backend-config="region=eu-central-1" \
  -backend-config="dynamodb_table=clawdinator-terraform-locks"
```

### Apply

```sh
tofu apply
```

## Control-plane API (optional)
Enable only when tokens are available:

```sh
export TF_VAR_control_api_enabled=true
export TF_VAR_control_api_token=...
export TF_VAR_github_token=...
```

## Outputs
- `bucket_name`
- `pr_intent_bucket_name`
- `aws_region`
- `ci_user_name`
- `access_key_id`
- `secret_access_key`
- `instance_ids`
- `instance_public_ips`
- `instance_public_dns`
- `efs_file_system_id`
- `efs_security_group_id`
- `control_api_url`
- `control_invoker_access_key_id`
- `control_invoker_secret_access_key`

## CI wiring
- Set GitHub Actions secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION`
  - `S3_BUCKET`
  - `CLAWDINATOR_SSH_PUBLIC_KEY`
  - `CONTROL_API_TOKEN`
  - `CLAWDINATOR_WORKFLOW_TOKEN`
  - `CLAWDINATOR_CONTROL_AWS_ACCESS_KEY_ID`
  - `CLAWDINATOR_CONTROL_AWS_SECRET_ACCESS_KEY`

## Runtime bootstrap
- Instances get an IAM role with read access to `s3://${S3_BUCKET}/bootstrap/*` for secrets + repo seeds.

## Retention contract
- Raw image uploads whose keys start with `clawdinator-nixos-` expire automatically after 14 days.
- Because bucket versioning is enabled, noncurrent raw-image versions are also expired so the bytes actually disappear.
- The CI IAM user can prune old CLAWDINATOR AMIs and their backing snapshots.
- Normal deploys still use the latest self-owned AMI tagged `clawdinator=true`.
