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
    ../modules/internal-dns.nix
    ../modules/juicefs-mount.nix
    ../modules/server.nix
    ../hardware-configuration/proximo.nix
    ./cgit.nix
    ./fava.nix
    ./minecraft.nix
    ./piwigo.nix
  ];

  nightcord.internal-dns = {
    enable = true;
    hostOverrides = { };
    laborariAddress = "10.20.0.2";
    proximoAddress = "127.0.0.1";
  };

  nightcord.juicefs-mount = {
    dbHost = "127.0.0.1";
    enable = true;
    waitServices = [
      "mysql.service"
    ];
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

  services.duplicity = {
    enable = true;
    include = [
      "/var/lib/minecraft"
    ];
    exclude = [
      "**"
    ];
    extraFlags = [
      "--no-encryption"
    ];
    frequency = "daily";
    targetUrl = "file:///mnt/jfs/duplicity/proximo";
    fullIfOlderThan = "1M";
    cleanup = {
      maxFull = 6;
    };
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
