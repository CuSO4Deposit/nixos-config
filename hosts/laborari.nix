{
  lib,
  config,
  pkgs,
  ...
}:
let
  httpProxy = "http://127.0.0.1:20172";
in
{
  imports = [
    ./modules/desktop.nix
    ./modules/juicefs-mount.nix
    ./modules/server.nix
    ./modules/office-wg.nix
    ./laborari-hardware-configuration.nix
  ];

  age.secrets = {
    "office-band.conf".file = ../secrets/office-band.conf.age;
    "wg-laborari-priv".file = ../secrets/wg-laborari-priv.age;
  };

  boot.binfmt.emulatedSystems = [
    "loongarch64-linux"
  ];
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

  juicefs-mount.dbHost = "10.20.0.1";
  juicefs-mount.waitServices = [
    "wireguard-wg2.service"
  ];

  networking.firewall.allowedTCPPorts = [ 22222 ];
  networking.hostName = "nightcord-laborari";
  networking.networkmanager.enable = true;
  networking.proxy.httpProxy = httpProxy;
  networking.proxy.httpsProxy = httpProxy;
  networking.wg-quick.interfaces.wg1.configFile = config.age.secrets."office-band.conf".path;
  networking.wireguard.interfaces.wg2 =
    let
      serverIP = "114.214.194.90";
    in
    {
      ips = [ "10.20.0.2/24" ];
      privateKeyFile = config.age.secrets.wg-laborari-priv.path;
      peers = [
        {
          publicKey = "cXhF0ScyBIIbKcf8GX1ct5YJZWdtAYzFqWRlGlB0mDY=";
          endpoint = "${serverIP}:5182";
          allowedIPs = [ "0.0.0.0/0" ];
          persistentKeepalive = 25;
        }
      ];
      preSetup = ''
        GW=$(${pkgs.iproute2}/bin/ip route show dev enp4s0 | ${pkgs.gawk}/bin/awk '/default/ {print $3}')
        if [ -z "$GW" ]; then
          GW=$(${pkgs.iproute2}/bin/ip route show dev wlp3s0 | ${pkgs.gawk}/bin/awk '/default/ {print $3}')
        fi

        echo "WireGuard Escape Route: via $GW"
        if [ -n "$GW" ]; then
          ${pkgs.iproute2}/bin/ip route add "${serverIP}" via $GW || ${pkgs.iproute2}/bin/ip route replace "${serverIP}" via $GW
        fi
      '';
      postSetup = ''
        LOCAL_GW=$(${pkgs.iproute2}/bin/ip route show dev enp4s0 | ${pkgs.gawk}/bin/awk '/default/ {print $3}')
        if [ -z "$LOCAL_GW" ]; then
          LOCAL_GW=$(${pkgs.iproute2}/bin/ip route show dev wlp3s0 | ${pkgs.gawk}/bin/awk '/default/ {print $3}')
        fi

        for range in 114.214.160.0/19 114.214.192.0/18 202.38.64.0/19 210.45.64.0/20 210.45.112.0/20 211.86.144.0/20 222.195.64.0/19 210.72.22.0/24 202.141.160.0/19 218.22.21.0/27 218.104.71.160/28; do
          ${pkgs.iproute2}/bin/ip route add $range via $LOCAL_GW
        done
      '';
      postShutdown = ''
        ${pkgs.iproute2}/bin/ip route del "${serverIP}" || true
      '';
    };

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

  users.users."cuso4d".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF4rWlDqIGqCRsXaF/QuYuMrWIvQ1fFLr8XyxCFQl07q cuso4d@nightcord-lexikos"
  ];

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
