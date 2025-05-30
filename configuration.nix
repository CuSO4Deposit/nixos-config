# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # https://github.com/NixOS/nixpkgs/issues/158356#issuecomment-1556882689
  nix.settings.substituters = lib.mkForce [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];
  nix.settings.trusted-users = [
    "cuso4d"
    "root"
  ];

  environment.systemPackages =
    let
      oh-cus-zsh = pkgs.callPackage ./derivations/oh-cus-zsh { };
    in
    [
      inputs.cus-nixvim.packages."${pkgs.system}".nvim
      oh-cus-zsh
      pkgs.bat
      pkgs.busybox
      pkgs.curl
      pkgs.git
      pkgs.jq
      pkgs.nixfmt-rfc-style
      pkgs.tldr
    ];

  environment.variables.EDITOR = "nvim";

  fonts.packages = with pkgs; [
    nerd-fonts.ubuntu-mono
  ];

  users.users.cuso4d = {
    isNormalUser = true;
    home = "/home/cuso4d";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  users.defaultUserShell = pkgs.zsh;

  programs.direnv = {
    enable = true;
    loadInNixShell = true;
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
    silent = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  programs.zsh = {
    enable = true;

    interactiveShellInit = ''
      eval "$(direnv hook bash)"
    '';

    ohMyZsh =
      let
        oh-cus-zsh = pkgs.callPackage ./derivations/oh-cus-zsh { };
      in
      {
        enable = true;
        package = oh-cus-zsh;
        plugins = [ "git" ];
        theme = "cphoen";
      };

    shellAliases = {
      alg = "alias | grep";
      bat = "bat --theme=base16";
      c = "clear";
      cc0 = "curl https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt -o ./LICENSE";
      gmv = "git mv";
      nrb = "nixos-rebuild switch --flake .#$(hostname) --use-remote-sudo; mv flake.lock locks/$(hostname | cut -d '-' -f 2); git add .; git commit -v;";
      nrbt = "git add .; nixos-rebuild test --flake .#$(hostname) --use-remote-sudo;";
      sudonvim = "sudo -E -s nvim";
    };
  };
}
