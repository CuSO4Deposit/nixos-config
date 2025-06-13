{
  lib,
  config,
  pkgs,
  ...
}:
let
  httpProxy = "http://127.0.0.1:20172";
  socks5Proxy = "socks5://127.0.0.1:20170";
in
{
  age.identityPaths = lib.map (x: "/home/${x}/.ssh/id_ed25519") (
    lib.attrNames (lib.attrsets.filterAttrs (n: v: v.isNormalUser) config.users.users)
  );
  age.secrets = {
    "officeVPN.ovpn".file = ../secrets/officeVPN.ovpn.age;
    "officeVPN.auth".file = ../secrets/officeVPN.auth.age;
  };

  imports = [
    ./modules/desktop.nix
    ./laborari-hardware-configuration.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  environment.etc.openvpn.source = "${pkgs.update-resolv-conf}/libexec/openvpn";

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

  networking.hostName = "nightcord-laborari";
  networking.networkmanager.enable = true;
  networking.proxy.allProxy = socks5Proxy;
  networking.proxy.httpProxy = socks5Proxy;
  networking.proxy.httpsProxy = socks5Proxy;

  programs.steam.enable = true;

  services.openvpn.servers.office = {
    # service.openvpn.servers.<name>.authUserPass still do not allow paths.
    # This is a possible workaround provided by tbaumann in:
    # https://github.com/NixOS/nixpkgs/issues/312283#issuecomment-2116102594
    config = ''
      config ${config.age.secrets."officeVPN.ovpn".path}
      auth-user-pass ${config.age.secrets."officeVPN.auth".path}
    '';
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  services.v2raya.enable = true;

  time.timeZone = "Etc/UTC";

  virtualisation.docker = {
    daemon.settings = {
      proxies = {
        http-proxy = httpProxy;
        https-proxy = httpProxy;
      };
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
