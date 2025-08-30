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
    filezilla
    ghostty
    grim
    logseq
    netease-cloud-music-gtk
    obs-studio
    slurp
    telegram-desktop
    # feishu crashes in hyprland with unknown reason. Before I fix this, use
    #   this to run a feishu web app (feishu does not support firefox)
    ungoogled-chromium
    vlc
    wechat-uos
    wemeet
    wofi
    zeal-qt6
    zotero

    # utils
    wl-clipboard
  ];

  imports = [
    ./dunst.nix
    ./hyprland.nix
    ./hyprpaper.nix
    ./firefox.nix
    ./waybar.nix
    ./wofi.nix
    agenix.homeManagerModules.default
  ];

  programs.home-manager.enable = true;

  xdg.desktopEntries = {
    feishu-web = {
      name = "feishu-web";
      exec = "chromium --no-proxy-server feishu.cn/messages";
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
