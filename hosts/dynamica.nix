{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  age.identityPaths = lib.map (x: "/home/${x}/.ssh/id_ed25519") (
    lib.attrNames (lib.attrsets.filterAttrs (n: v: v.isNormalUser) config.users.users)
  );
  imports = [
    ./dynamica-hardware-configuration.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  i18n.inputMethod = {
    enable = true;
    fcitx5.addons = with pkgs; [
      fcitx5-chinese-addons
      fcitx5-gtk
      fcitx5-mozc
      fcitx5-pinyin-zhwiki
      fcitx5-pinyin-moegirl
      fcitx5-tokyonight
    ];
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
  };

  networking.hostName = "nightcord-dynamica";
  networking.networkmanager.enable = true;
  networking.proxy.allProxy = "socks5://127.0.0.1:20170";
  networking.proxy.httpProxy = "socks5://127.0.0.1:20170";
  networking.proxy.httpsProxy = "socks5://127.0.0.1:20170";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.dconf.enable = true;
  programs.dconf.profiles = {
    user.databases = [
      {
        lockAll = true;
        settings = with lib.gvariant; {
          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = [
              pkgs.gnomeExtensions.kimpanel.extensionUuid
            ];
          };
          "org/gnome/desktop/interface".color-scheme = "prefer-dark";
          "org/gnome/desktop/interface".enable-hot-corners = false;
          "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-timeout = mkUint32 3600;
        };
      }
    ];
  };
  programs.hyprland.enable = true;

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

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
