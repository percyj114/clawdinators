{ lib, modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/amazon-image.nix")
    ../modules/clawdinator.nix
    ./clawdinator-common.nix
  ];

  networking.hostName = "clawdinator-1";
  time.timeZone = "UTC";
  system.stateVersion = "26.05";

  nix.package = pkgs.nixVersions.stable;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.grub.device = lib.mkForce "/dev/nvme0n1";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLItFT3SVm5r7gELrfRRJxh6V2sf/BIx7HKXt6oVWpB"
  ];

  networking.firewall.allowedTCPPorts = [ 22 ];

  clawdinator.bootstrapPrefix = "bootstrap/clawdinator-1";
  clawdinator.discordTokenSecret = "clawdinator-discord-token-1";

  # Publish PR intent artifacts from EFS to the public bucket.
  # (Timer + oneshot service; safe to run without stopping the gateway.)
  services.clawdinator.publicS3 = {
    enable = true;
    bucket = "openclaw-pr-intent";
    region = "eu-central-1";
    sourceDir = "/memory/pr-intent";
    # schedule = "*:0/10"; # default
  };

}
