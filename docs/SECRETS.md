# Secrets Wiring

Principle: secrets never land in git. One secret per file, decrypted at runtime.

Infrastructure (OpenTofu):
- `HCLOUD_TOKEN` via environment variable (required).
- Do NOT commit `*.tfvars` with secrets.

Runtime (CLAWDINATOR):
- Discord bot token (required, per instance).
- GitHub token (required): GitHub App installation token (preferred) or a read-only PAT.
- Anthropic API key (required for Claude models).

Explicit token files (standard):
- `services.clawdinator.discordTokenFile`
- `services.clawdinator.anthropicApiKeyFile`
- `services.clawdinator.githubPatFile` (PAT path, if not using GitHub App; exports `GITHUB_TOKEN` + `GH_TOKEN`)

GitHub App (preferred):
- Private key PEM decrypted to `/run/agenix/clawdinator-github-app.pem`.
- App ID + Installation ID in `services.clawdinator.githubApp.*`.
- Timer mints short-lived tokens into `/run/clawd/github-app.env` with `GITHUB_TOKEN` + `GH_TOKEN`.

Agenix (local secrets repo):
- Store encrypted files in `../nix/nix-secrets` (relative to this repo).
- Decrypt on host with agenix; point NixOS options at `/run/agenix/*`.
- Required files (minimum): `clawdinator-github-app.pem.age`, `clawdinator-discord-token.age`, `clawdis-anthropic-api-key.age`.

Example NixOS wiring (agenix):
```
{ inputs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  age.secrets."clawdinator-github-app.pem".file =
    "${inputs.secrets}/clawdinator-github-app.pem.age";
  age.secrets."clawdis-anthropic-api-key".file =
    "${inputs.secrets}/clawdis-anthropic-api-key.age";
  age.secrets."clawdinator-discord-token".file =
    "${inputs.secrets}/clawdinator-discord-token.age";

  services.clawdinator.githubApp.privateKeyFile =
    "/run/agenix/clawdinator-github-app.pem";
  services.clawdinator.anthropicApiKeyFile =
    "/run/agenix/clawdis-anthropic-api-key";
  services.clawdinator.discordTokenFile =
    "/run/agenix/clawdinator-discord-token";
}
```
