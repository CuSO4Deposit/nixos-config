{
  lib,
  config,
  pkgs,
  ...
}:
let
  httpProxy = "http://127.0.0.1:20172";
  socks5Proxy = "socks5://127.0.0.1:20173";
in
{
  imports = [
    ./modules/laptop.nix
    ./modules/office-wg.nix
    ./lexikos-hardware-configuration.nix
  ];

  age.secrets = {
    "office-band.conf".file = ../secrets/office-band.conf.age;
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

  home-manager.users.cuso4d.wayland.windowManager.hyprland.settings = {
    binde = lib.mkAfter [
      '', XF86MonBrightnessUp, exec, brightnessctl set 5%+ -d nvidia_0 ''
      '', XF86MonBrightnessDown, exec, brightnessctl set 5%- -d nvidia_0 ''
    ];
    monitor = lib.mkForce [
      "eDP-1,prefered,0x0,1"
      "HDMI-A-1,prefered,1920x0,1"
    ];
  };

  networking.hostName = "nightcord-lexikos";
  networking.networkmanager.enable = true;
  networking.proxy.allProxy = socks5Proxy;
  networking.proxy.httpProxy = socks5Proxy;
  networking.proxy.httpsProxy = socks5Proxy;
  networking.wg-quick.interfaces.wg1.configFile = config.age.secrets."office-band.conf".path;

  programs.steam.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  services.v2raya.enable = true;

  time.timeZone = "Etc/UTC";

  virtualisation.docker = {
    daemon.settings = {
      proxies = {
        http-proxy = httpProxy;
        https-proxy = httpProxy;
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
