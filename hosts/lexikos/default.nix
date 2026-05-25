{
  config,
  pkgs,
  pkgs-nvidia-x11-580-95,
  ...
}:
{
  imports = [
    ../modules/internal-dns.nix
    ../modules/juicefs-mount.nix
    ../modules/laptop.nix
    ../modules/office-wg.nix
    ../modules/proximo-data.nix
    ../hardware-configuration/lexikos.nix
  ];

  nightcord.internal-dns = {
    enable = true;
    hostOverrides = { };
    laborariAddress = "10.20.0.2";
    proximoAddress = "192.168.1.104";
  };

  age.secrets = {
    "office-band.conf".file = ../../secrets/office-band.conf.age;
    "wg-lexikos.conf".file = ../../secrets/wg-lexikos.conf.age;
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  boot.kernelPackages = pkgs-nvidia-x11-580-95.linuxPackages;

  environment.systemPackages = with pkgs; [
    digikam
    hmcl
    kdePackages.kdenlive
  ];

  # https://nixos.wiki/wiki/Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AntoEnable = true;
      };
    };
  };
  # OpenGL
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = true;
    package = pkgs-nvidia-x11-580-95.linuxPackages.nvidiaPackages.production;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  home-manager.users.cuso4d = {
    imports = [ ../modules/home/lexikos.nix ];
  };

  nightcord.juicefs-mount = {
    dbHost = "192.168.1.104";
    enable = true;
    waitServices = [ "wg-quick-wg2.service" ];
  };

  nightcord.proxy = "http://127.0.0.1:20172";

  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 192.168.1.104 --dport 20172 -j ACCEPT
  '';
  networking.firewall.trustedInterfaces = [ "wg2" ];
  networking.hostName = "nightcord-lexikos";
  networking.networkmanager.enable = true;
  networking.proxy.allProxy = config.nightcord.proxy;
  networking.proxy.httpProxy = config.nightcord.proxy;
  networking.proxy.httpsProxy = config.nightcord.proxy;
  networking.wg-quick.interfaces.wg1.configFile = config.age.secrets."office-band.conf".path;
  networking.wg-quick.interfaces.wg2.configFile = config.age.secrets."wg-lexikos.conf".path;

  programs.steam.enable = true;

  services.blueman.enable = true;

  services.duplicity = {
    enable = true;
    include = [
      "/home/cuso4d/.local/share/Terraria" # Terraria Local Players and Worlds
      "/home/cuso4d/.local/share/Steam/userdata/1113845821/105600" # Terraria Steam Remote
      "/home/cuso4d/.local/share/hmcl" # Minecraft Player and Mod Data
      "/home/cuso4d/Pictures" # Pictures
    ];
    exclude = [
      "**"
    ];
    extraFlags = [
      "--no-encryption"
    ];
    frequency = "daily";
    targetUrl = "file:///mnt/jfs/duplicity/lexikos";
    fullIfOlderThan = "1M";
    cleanup = {
      maxFull = 6;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  services.v2raya.enable = true;
  systemd.services.v2raya-lan-http-proxy = {
    description = "Expose v2rayA HTTP proxy to proximo only";
    after = [ "v2raya.service" ];
    wants = [ "v2raya.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:20172,bind=192.168.1.102,reuseaddr,fork TCP:127.0.0.1:20172";
      Restart = "always";
      RestartSec = 2;
    };
  };

  systemd.timers."cannot-sleep-m9" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "15:00:00";
      Unit = "cannot-sleep-m9.service";
    };
  };
  systemd.services."cannot-sleep-m9" = {
    # https://web.archive.org/web/20250805104854/https://forum.endeavouros.com/t/notify-when-network-is-up/69894/4
    script = ''
      systemd-run --user --machine=cuso4d@.host --user ${pkgs.libnotify}/bin/notify-send -t 10000 "This is ena..." "You cannot go to sleep! m9"
    '';
  };

  systemd.timers."mm-config-extract" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "10min";
      Unit = "mm-config-extract.service";
    };
  };
  systemd.services."mm-config-extract" = {
    path = with pkgs; [
      bash
      gawk
      coreutils
      gnugrep
    ];
    script = ''
      bash /home/cuso4d/source/mm-config/scripts/extract-bestbefore.sh
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "cuso4d";
    };
  };

  time.timeZone = "Etc/UTC";

  virtualisation.docker = {
    daemon.settings = {
      proxies = {
        http-proxy = config.nightcord.proxy;
        https-proxy = config.nightcord.proxy;
      };
      registry-mirrors = [
        "https://docker-0.unsee.tech"
        "https://docker.1panel.live"
      ];
    };
    enable = true;
  };

  # List packages installed in system profile. To search, run:
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
