{ config, lib, pkgs, secrets, ... }:
{
  imports = [ ../modules/clawdinator.nix ];

  networking.hostName = "clawdinator-1";
  time.timeZone = "UTC";
  system.stateVersion = "26.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
    disk.clawd = {
      type = "disk";
      device = "/dev/disk/by-id/scsi-0HC_Volume_${config.networking.hostName}";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/var/lib/clawd";
        mountOptions = [ "nofail" "x-systemd.device-timeout=10" ];
      };
    };
  };

  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 18789 ];

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets."clawdinator-github-app.pem".file =
    "${secrets}/clawdinator-github-app.pem.age";
  age.secrets."clawdis-anthropic-api-key".file =
    "${secrets}/clawdis-anthropic-api-key.age";
  age.secrets."clawdinator-discord-token".file =
    "${secrets}/clawdinator-discord-token.age";

  services.clawdinator = {
    enable = true;
    instanceName = "CLAWDINATOR-1";
    memoryDir = "/var/lib/clawd/memory";

    config = {
      gateway.mode = "server";
      agent.workspace = "/var/lib/clawd/workspace";
      agent.maxConcurrent = 4;
      routing.queue = {
        mode = "interrupt";
        bySurface = {
          discord = "queue";
          telegram = "interrupt";
          whatsapp = "interrupt";
          webchat = "queue";
        };
      };
      identity.name = "CLAWDINATOR-1";
      skills.allowBundled = [ "github" "clawdhub" ];
      discord = {
        enabled = true;
        dm.enabled = false;
        guilds = {
          "<GUILD_ID>" = {
            requireMention = true;
            channels = {
              "<CHANNEL_NAME>" = { allow = true; requireMention = true; };
            };
          };
        };
      };
    };

    anthropicApiKeyFile = "/run/agenix/clawdis-anthropic-api-key";
    discordTokenFile = "/run/agenix/clawdinator-discord-token";

    githubApp = {
      enable = true;
      appId = "2607181";
      installationId = "102951645";
      privateKeyFile = "/run/agenix/clawdinator-github-app.pem";
      schedule = "hourly";
    };

    selfUpdate.enable = true;
    selfUpdate.flakePath = "/var/lib/clawd/repo";
    selfUpdate.flakeHost = "clawdinator-1";
  };
}
