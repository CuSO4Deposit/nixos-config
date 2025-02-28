# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, inputs, ... }:


{
  imports = [
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # https://github.com/NixOS/nixpkgs/issues/158356#issuecomment-1556882689
  nix.settings.substituters = lib.mkForce [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];  
  nix.settings.trusted-users = [ "cuso4d" "root" ];

  environment.systemPackages = [
    inputs.nixvim.packages."${pkgs.system}".nvim
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

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

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
}
