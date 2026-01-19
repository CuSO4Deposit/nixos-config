{
  lib,
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

  # List packages installed in system profile. To search, run:
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
