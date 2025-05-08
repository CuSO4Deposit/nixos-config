{ config, pkgs, ... }:

{
  home.homeDirectory = "/home/cuso4d";
  home.username = "cuso4d";

  home.file."${config.xdg.configHome}" = {
    force = true;
    source = ./files/.config;
    recursive = true;
  };
  home.packages = with pkgs; [
    ghostty
    librewolf-wayland
    logseq
    nur.repos.linyinfeng.wemeet
  ];

  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your configuration is 
  # compatible with. This helps avoid breakage when a new Home Manager release 
  # introduces backwards incompatible changes. 
  #
  # You should not change this value, even if you update Home Manager. If you do 
  # want to update the value, then make sure to first check the Home Manager 
  # release notes. 
  home.stateVersion = "24.11"; # Did you read the comment?
}
