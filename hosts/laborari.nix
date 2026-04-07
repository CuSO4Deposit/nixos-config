{
  lib,
  config,
  inputs,
  ...
}:
let
  httpProxy = "http://127.0.0.1:20172";
in
{
  imports = [
    ./modules/desktop.nix
    ./modules/internal-dns.nix
    ./modules/juicefs-mount.nix
    ./modules/minio-mount.nix
    ./modules/nix-auto-build
    ./modules/office-wg.nix
    ./modules/server.nix
    ./hardware-configuration/laborari.nix
  ];

  nightcord.internal-dns = {
    enable = true;
    laborariAddress = "10.20.0.2";
    proximoAddress = "10.20.0.1";
  };

  age.secrets = {
    "office-band.conf".file = ../secrets/office-band.conf.age;
    "wg-laborari.conf".file = ../secrets/wg-laborari.conf.age;
    "nix-cache-signing-key".file = ../secrets/nix-cache-signing-key.age;
    # Openclaw
    "openclaw-env" = {
      file = ../secrets/openclaw-env.age;
      owner = "cuso4d";
    };
    "telegram-bot-token" = {
      file = ../secrets/telegram-bot-token.age;
      owner = "cuso4d";
    };
    "telegram-bot-token-yoshino" = {
      file = ../secrets/telegram-bot-token-yoshino.age;
      owner = "cuso4d";
    };
    "zotero-api-key" = {
      file = ../secrets/zotero-api-key.age;
      owner = "cuso4d";
    };
    "zotero-user-id" = {
      file = ../secrets/zotero-user-id.age;
      owner = "cuso4d";
    };
  };

  boot.binfmt.emulatedSystems = [
    "loongarch64-linux"
  ];

  nix-auto-build = {
    enable = true;
    cachePath = "/mnt/minio/nix-cache-54168";
    cachePublicKey = "nix-cache.laborari:wPKpQRXxNF7jBk6A1vn26ObhXAEWN8jF0QCTkdT+qe0=";
  };
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  # OpenGL
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };
  home-manager.users.cuso4d = {
    imports = [
      inputs.nix-openclaw.homeManagerModules.openclaw
      ./modules/openclaw.nix
    ];

    programs.hyprlock.settings = {
      background = {
        brightness = lib.mkForce 0.5;
      };
    };
    programs.waybar.settings.mainBar = {
      network.interface = lib.mkForce "wlp3s0";
    };
  };

  juicefs-mount = {
    dbHost = "10.20.0.1";
    enable = true;
    waitServices = [
      "wg-quick-wg2.service"
    ];
  };

  rclone-minio.waitServices = [
    "wg-quick-wg0.service"
  ];

  networking.firewall.allowedTCPPorts = [ 22222 ];
  networking.firewall.allowedUDPPorts = [ 5182 ];
  networking.firewall.trustedInterfaces = [ "wg2" ];
  networking.hostName = "nightcord-laborari";
  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg2" ];
    externalInterface = "enp4s0";
  };
  networking.networkmanager.enable = true;
  networking.proxy.httpProxy = httpProxy;
  networking.proxy.httpsProxy = httpProxy;
  networking.proxy.noProxy = "127.0.0.1,localhost,mirrors.ustc.edu.cn,mirrors.tuna.tsinghua.edu.cn";
  networking.wg-quick.interfaces.wg1.configFile = config.age.secrets."office-band.conf".path;
  networking.wg-quick.interfaces.wg2.configFile = config.age.secrets."wg-laborari.conf".path;

  nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ];

  programs.steam.enable = true;

  services.openssh = {
    enable = true;
    ports = [ 22222 ];
    settings.KbdInteractiveAuthentication = false;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };
  services.terraria = {
    enable = true;
    port = 14141;
    password = "10001279";
    openFirewall = true;
    messageOfTheDay = "Welcome to Terraria 1.4.5! 我真幸运！";
    maxPlayers = 4;
    autoCreatedWorldSize = "medium";
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  services.v2raya.enable = true;

  time.timeZone = "Etc/UTC";

  users.users."guest" = {
    isNormalUser = true;
    home = "/home/guest";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIEu5dDs5aj4vo5cG7BFiGCDPAyQ6VEnijrO1X2m34v"
    ];
  };

  virtualisation.docker = {
    daemon.settings = {
      proxies = {
        http-proxy = httpProxy;
        https-proxy = httpProxy;
      };
      registry-mirrors = [
        "https://docker-0.unsee.tech"
        "https://docker.mirrors.kclab.cloud/"
        "https://docker.1panel.live"
      ];
    };
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
