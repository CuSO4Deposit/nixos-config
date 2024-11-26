# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:


{
  imports = [
  ];

  wsl.enable = true;
  wsl.defaultUser = "cuso4d";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];  

  environment.systemPackages = [
    pkgs.bat
    pkgs.curl
    pkgs.git
    pkgs.oh-my-zsh
    pkgs.zsh
  ];

  environment.variables.EDITOR = "nvim";

  users.users.cuso4d = {
    isNormalUser = true;
    home = "/home/cuso4d";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  users.defaultUserShell = pkgs.zsh;

  programs.direnv = {
      enable = true;
      silent = true;
  };

  programs.nixvim = (import ./modules/nixvim) pkgs;

  programs.zsh = {
    enable = true;

    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "kphoen";
    };

    shellAliases = {
      alg = "alias | grep";
      c = "clear";
      sudonvim = "sudo -E -s nvim";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
