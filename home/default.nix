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
    ghostty
    grim
    logseq
    nur.repos.linyinfeng.wemeet
    slurp
    telegram-desktop
    wechat-uos
    wofi
    wpsoffice-cn

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
