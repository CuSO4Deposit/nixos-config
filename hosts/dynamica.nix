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
  age.identityPaths = lib.map (x: "/home/${x}/.ssh/id_ed25519") (
    lib.attrNames (lib.attrsets.filterAttrs (n: v: v.isNormalUser) config.users.users)
  );

  imports = [
    ./modules/desktop.nix
    ./modules/office-wg.nix
    ./dynamica-hardware-configuration.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  networking.hostName = "nightcord-dynamica";
  networking.networkmanager.enable = true;
  networking.proxy.allProxy = httpProxy;
  networking.proxy.httpProxy = httpProxy;
  networking.proxy.httpsProxy = httpProxy;

  services.v2raya.enable = true;

  time.timeZone = "Etc/UTC";

  # List packages installed in system profile. To search, run:
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
