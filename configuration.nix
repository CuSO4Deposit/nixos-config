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
  environment.systemPackages = with pkgs; [
    bat
    busybox
    curl
    git
    inputs.cus-nixvim.packages."${pkgs.system}".nvim
    jq
    nixfmt-rfc-style
    tldr
  ];

  environment.variables.EDITOR = "nvim";

  fonts.packages = with pkgs; [
    nerd-fonts.ubuntu-mono
  ];

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
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  programs.htop = {
    enable = true;
    settings = {
      hide_kernel_threads = true;
      hide_userland_threads = true;
      highlight_base_name = true;
      highlight_megabytes = true;
      show_program_path = false;
      tree_view = false;
    };
  };

  programs.tmux = {
    clock24 = true;
    enable = true;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      tokyo-night-tmux
    ];
  };

  programs.zsh = {
    enable = true;

    interactiveShellInit = ''
      eval "$(direnv hook zsh)"
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
      # https://wszqkzqk.github.io/2024/03/09/WPS-Fcitx5/
      wps = ''XMODIFIERS="@im=fcitx" GTK_IM_MODULE="fcitx" QT_IM_MODULE="fcitx" SDL_IM_MODULE=fcitx wps'';
    };
  };
}
