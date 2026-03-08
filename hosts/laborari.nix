{
  lib,
  pkgs,
  config,
  ...
}:
let
  httpProxy = "http://127.0.0.1:20172";
in
{
  imports = [
    ./modules/desktop.nix
    ./modules/juicefs-mount.nix
    ./modules/minio-mount.nix
    ./modules/office-wg.nix
    ./modules/server.nix
    ./hardware-configuration/laborari.nix
  ];

  age.secrets = {
    "office-band.conf".file = ../secrets/office-band.conf.age;
    "wg-laborari.conf".file = ../secrets/wg-laborari.conf.age;
  };

  boot.binfmt.emulatedSystems = [
    "loongarch64-linux"
  ];
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
  networking.wg-quick.interfaces.wg1.configFile = config.age.secrets."office-band.conf".path;
  networking.wg-quick.interfaces.wg2.configFile = config.age.secrets."wg-laborari.conf".path;

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

  # Forward v2raya proxy to docker bridge so containers can reach it
  systemd.services.v2raya-docker-forward = {
    description = "Forward v2raya proxy to docker0 bridge";
    after = [
      "network.target"
      "v2raya.service"
      "docker.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:20172,bind=172.17.0.1,fork,reuseaddr TCP:127.0.0.1:20172";
      Restart = "on-failure";
      DynamicUser = true;
    };
  };
  networking.firewall.interfaces."docker0".allowedTCPPorts = [ 20172 ];

  virtualisation.oci-containers = {
    backend = "docker";
    containers.openclaw = {
      image = "ghcr.io/openclaw/openclaw:main-amd64";
      volumes = [
        "/home/cuso4d/openclaw/data:/home/node/.openclaw"
        "/home/cuso4d/openclaw/secrets/telegram-bot-token:/run/secrets/telegram-bot-token:ro"
      ];
      environmentFiles = [
        "/home/cuso4d/openclaw/secrets/.env"
      ];
      environment = {
        HTTP_PROXY = "http://172.17.0.1:20172";
        HTTPS_PROXY = "http://172.17.0.1:20172";
        NO_PROXY = "127.0.0.1,localhost";
      };
      ports = [
        "127.0.0.1:18789:18789"
        "127.0.0.1:18791:18791"
      ];
      extraOptions = [ "--pull=never" ];
    };
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

  # List packages installed in system profile. To search, run:
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
