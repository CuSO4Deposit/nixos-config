{
  config,
  lib,
  pkgs,
  ...
}:
let
  httpProxy = "http://192.168.1.102:20172";
in
{
  age.secrets = {
    "wg-proximo.conf".file = ../../secrets/wg-proximo.conf.age;
    "piwigo-db-password" = {
      file = ../../secrets/piwigo-db-password.age;
      owner = "mysql";
      group = "mysql";
    };
    "ghorg-github-token" = {
      file = ../../secrets/ghorg-github-token.age;
      owner = "ghorg";
      group = "ghorg";
    };
    "ghorg-github-token-sayori" = {
      file = ../../secrets/ghorg-github-token-sayori.age;
      owner = "ghorg";
      group = "ghorg";
    };
    "ghorg-work-0.yaml" = {
      file = ../../secrets/ghorg-work-0.yaml.age;
      owner = "ghorg";
      group = "ghorg";
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.conf.ens18.rp_filter" = 0;
  };
  boot.loader.systemd-boot.enable = true;

  imports = [
    # No sources of its own; imported so the option the syncthing assertion reads exists.
    ../../modules/linux/archive.nix
    ../../modules/linux/internal-dns.nix
    ../../modules/linux/mysql-backup.nix
    ../../modules/linux/rclone-webdav-mount.nix
    ../../modules/linux/restic-backup.nix
    ../../modules/linux/server.nix
    ../../modules/linux/syncthing.nix
    ../hardware-configuration/proximo.nix
    ./cgit.nix
    ./fava.nix
    ./minecraft-fabric.nix
    ./minecraft.nix
    ./minecraft2.nix
    ./nginx.nix
    ./observable.nix
    ./piwigo.nix
    ./redmi-backup.nix
    ./vita-grid.nix
  ];

  nightcord.minecraft2.enable = false;

  nightcord.syncthing.deviceName = "nightcord-proximo";

  nightcord.internal-dns = {
    enable = true;
    hostOverrides = { };
    laborariAddress = "10.20.0.2";
    proximoAddress = "127.0.0.1";
  };

  nightcord.rclone-webdav = {
    enable = true;
    remotePath = "/webdav";
  };

  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [
    80
    7777
  ];
  networking.firewall.interfaces.docker0.allowedTCPPorts = [
    3306
  ];
  networking.firewall.trustedInterfaces = [
    "wg0"
    "ens18"
  ];
  networking.hostName = "nightcord-proximo";
  networking.nat = {
    enable = true;
    externalInterface = "wg0";
    internalInterfaces = [ "ens18" ];
    internalIPs = [ "192.168.1.0/24" ];
  };
  networking.proxy.allProxy = httpProxy;
  networking.proxy.httpProxy = httpProxy;
  networking.proxy.httpsProxy = httpProxy;
  networking.proxy.noProxy = "127.0.0.1,localhost,.internal,192.168.1.102";
  networking.wg-quick.interfaces.wg0.configFile = config.age.secrets."wg-proximo.conf".path;

  # wg-quick's configFile mode leaves the interface behind if ExecStop fails
  # (e.g. /tmp with the generated config got cleaned), so the next start aborts
  # with "wg0 already exists". Delete any leftover interface before starting.
  systemd.services."wg-quick-wg0".serviceConfig.ExecStartPre = [
    "-${pkgs.iproute2}/bin/ip link del wg0"
  ];

  nightcord.restic-backup = {
    enable = true;

    # DB dump first, then quiesce: saving is disabled for as short a time as possible.
    backupPrepareCommand = ''
      ${config.nightcord.mysql-backup.backupPrepareCommand}
      ${config.nightcord.minecraft-fabric.backupPrepareCommand}
    '';

    backupCleanupCommand = config.nightcord.minecraft-fabric.backupCleanupCommand;

    # Received archives are second copies of data that can be lost with the originating
    # device; the rest lives only on proximo.
    paths = [
      config.nightcord.mysql-backup.dumpDir
      "/var/lib/minecraft"
      "/var/lib/minecraft2"
      "/var/lib/minecraft-fabric"
      "/data/redmi50"
      "/data/laborari"
      "/data/lexikos"
      # Piwigo's uploads are byte-identical to a subset of the digikam library (406/406
      # verified), so restic stores them once; keeping both avoids a re-upload on restore.
      "/data/images"
      "/data/piwigo/app/upload"
      # Piwigo state only: the app code is regenerable from the image.
      "/data/piwigo/app/_data"
      "/data/piwigo/app/local"
      # GitHub mirror of source across all machines; the re-clonable nixpkgs clone is
      # excluded below.
      "/data/ghorg"
      "/home/cuso4d/archive"
      "/home/cuso4d/.ssh"
      "/home/cuso4d/.config"
    ];

    exclude = [
      # A full nested nixpkgs clone (2.9G) is re-clonable; keep the rest of the mirror.
      "/data/ghorg/github.com/cuso4deposit/nixpkgs"
      "**/node_modules"
      "**/.venv"
      "**/__pycache__"
      "/home/cuso4d/.config/**/Cache"
      "/home/cuso4d/.config/**/cache"
    ];
  };

  # Versioning net against logical damage and accidental deletion. Not a copy: same disk,
  # so it complements the offsite repository but cannot replace it.
  services.snapper.configs.data = {
    SUBVOLUME = "/data";
    ALLOW_USERS = [ "cuso4d" ];
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = 0;
    TIMELINE_LIMIT_DAILY = 7;
    TIMELINE_LIMIT_WEEKLY = 4;
    TIMELINE_LIMIT_MONTHLY = 12;
    TIMELINE_LIMIT_YEARLY = 0;
  };

  services.ghorg = {
    enable = true;
    dataDir = "/data/ghorg";
    dataDirMode = "0750";
    startAt = "daily";

    jobs = {
      github-cuso4d = {
        settings = {
          cloneProtocol = "https";
          cloneType = "user";
          preserveDir = true;
          preserveScmHostname = true;
          scmType = "github";
        };
        tokenFile = config.age.secrets.ghorg-github-token.path;
        args = [
          "clone"
          "CuSO4Deposit"
        ];
      };
      github-sayori = {
        settings = {
          cloneProtocol = "https";
          cloneType = "user";
          preserveDir = true;
          preserveScmHostname = true;
          scmType = "github";
        };
        tokenFile = config.age.secrets.ghorg-github-token-sayori.path;
        args = [
          "clone"
          "raincloud-in-a-bottle"
        ];
      };
      work-0 = {
        configFile = config.age.secrets."ghorg-work-0.yaml".path;
        args = [
          "clone"
          "2985mN1"
        ];
      };
    };
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    settings.mysqld.skip-name-resolve = true;
  };

  services.nginx = {
    enable = true;
  };

  systemd.services."wg-quick-wg0".path = [
    pkgs.gawk
    pkgs.coreutils
  ];

  users.users."cuso4d".extraGroups = lib.mkAfter [
    "ghorg"
    "minecraft"
  ];
  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
