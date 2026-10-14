{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  common = import ../../lib/common.nix;
  pkgs-logseq-electron-39 = import inputs.nixpkgs-logseq-electron-39 {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  # Pinned nixpkgs providing wemeet 3.26.10.401 (see flake.nix).
  pkgs-wemeet = import inputs.nixpkgs-wemeet {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  # Pinned nixpkgs providing the wemeet-compatible PipeWire (see flake.nix).
  pkgs-pipewire-compat = import inputs.nixpkgs-pipewire-compat {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  pkgs-zotero = import inputs.nixpkgs-zotero {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  options.nightcord.proxy = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "http://127.0.0.1:20172";
    description = "HTTP proxy address used by this host.";
  };

  imports = [
    ./opencode.nix
  ];

  config = {
    age.secrets."nowplaying-url" = {
      file = ../../secrets/nowplaying-url.age;
      mode = "0444";
    };

    nixpkgs.overlays = [
      (_final: prev: {
        # Pin Logseq to the selected nixpkgs revision, but keep the Electron
        # downgrade scoped to Logseq itself so other Electron apps still follow
        # the normal package set.
        logseq = pkgs-logseq-electron-39.logseq.override {
          electron = pkgs-logseq-electron-39.electron_39;
        };
        # WeMeet with working Wayland screen share (Hunk 0 + native portal +
        # pinned PipeWire). See derivations/wemeet-wayland for the full story.
        # Both wemeet and pipewire are pinned to fixed revisions, independent of
        # the floating `nixpkgs` input.
        wemeet-wayland = prev.callPackage ../../derivations/wemeet-wayland {
          wemeet = pkgs-wemeet.wemeet;
          pipewire = pkgs-pipewire-compat.pipewire;
        };
        # Pin Zotero to a nixpkgs revision that still ships Firefox ESR 140.
        # Newer nixpkgs bumped firefox-esr to 153, which Zotero 10.x can't be
        # built against. Drop this once NixOS/nixpkgs#569006 lands.
        zotero = pkgs-zotero.zotero;
      })
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_IM_MODULE = "fcitx";
      XMODIFERS = "@im=fcitx";
    };

    environment.systemPackages = with pkgs; [
      brightnessctl
      libnotify
      pavucontrol # Pipewire graphical tool
    ];

    fonts.packages = common.fonts pkgs;

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
        qt6Packages.fcitx5-chinese-addons
        fcitx5-gtk
        fcitx5-mozc
        fcitx5-pinyin-zhwiki
        fcitx5-pinyin-moegirl
        fcitx5-tokyonight
        kdePackages.fcitx5-qt
      ];
      type = "fcitx5";
      fcitx5.waylandFrontend = true;
    };

    networking.firewall = {
      allowedTCPPorts = [
        53317 # LocalSend
      ];
      allowedUDPPorts = [
        53317 # LocalSend
      ];
    };

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
            "org/gnome/desktop/interface".font-name = "Noto Sans CJK SC, 13";
            "org/gnome/desktop/peripherals/keyboard".numlock-state = true;
            # Automatic Screen Blank (in seconds). (Set to 0 to disable)
            "org/gnome/desktop/session".idle-delay = mkUint32 600;
            # Automatic Suspend: Off (set it to "suspend" to turn on)
            "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
            # Power Button Bahavior: Power Off (other options: suspend, hibernate, nothing)
            "org/gnome/settings-daemon/plugins/power".power-button-action = "interactive";
          };
        }
      ];
    };
    programs.hyprland.enable = true;

    services.xserver.enable = true;
    services.orca.enable = false;
    services.displayManager.gdm = {
      autoSuspend = false;
      enable = true;
    };
    services.desktopManager.gnome.enable = true;
    services.gnome.gcr-ssh-agent.enable = false;

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

    # Enable hyprlock to perform authentication
    security.pam.services.hyprlock.enable = true;

    # Enable touchpad support (enabled default in most desktopManager).
    services.libinput.enable = true;
    # https://www.reddit.com/r/NixOS/comments/qfe9yr/how_can_i_wake_it_up_from_suspension_and/
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="enabled"
    '';
  };
}
