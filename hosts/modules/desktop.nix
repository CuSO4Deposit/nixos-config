{
  lib,
  pkgs,
  ...
}:
{
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_IM_MODULE = "fcitx";
    XMODIFERS = "@im=fcitx";
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    libnotify
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.ubuntu-mono
    noto-fonts-cjk-sans
  ];

  home-manager.users.cuso4d = {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
      };
    };
  };

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
}
