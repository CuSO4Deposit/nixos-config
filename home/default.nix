{
  config,
  pkgs,
  agenix,
  ...
}:
{
  home.homeDirectory = "/home/cuso4d";
  home.username = "cuso4d";
  home.file."${config.xdg.configHome}" = {
    force = true;
    source = ../files/.config;
    recursive = true;
  };
  home.packages = with pkgs; [
    # GUI
    evolution
    feishu
    filezilla
    ghostty
    grim
    keepassxc
    logseq
    obs-studio
    qq
    slurp
    telegram-desktop
    vlc
    wechat
    wemeet
    (pkgs.callPackage ../derivations/wemeet-nvidia { })
    wofi
    # zeal  # https://nixpkgs-tracker.ocfox.me/?pr=455354
    zotero

    # utils
    wl-clipboard
  ];

  imports = [
    ./dunst.nix
    ./hypridle.nix
    ./hyprland.nix
    ./hyprlock.nix
    ./hyprpaper.nix
    ./firefox.nix
    ./waybar.nix
    ./wofi.nix
    agenix.homeManagerModules.default
  ];

  programs.home-manager.enable = true;

  xdg.desktopEntries = {
    feishu-env = {
      name = "FeishuWithEnv";
      exec = "QT_QPA_PLATFORM=wayland QT_IM_MODULE=fcitx IM_MODULE_CLASSNAME=fcitx::QFcitxPlatformInputContext bytedance-feishu";
      terminal = false;
    };
    wemeet-nvidia = {
      name = "WemeetAppNvidia";
      exec = "wemeet-nvidia %u";
      type = "Application";
      terminal = false;
    };
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Did you read the comment?
}
