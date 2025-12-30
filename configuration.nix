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
    at
    bat
    busybox
    curl
    gemini-cli
    git
    inputs.cus-nixvim.packages."${pkgs.stdenv.hostPlatform.system}".nvim
    jq
    juicefs
    just
    nixfmt-rfc-style
    qwen-code
    tldr
  ];

  environment.variables.EDITOR = "nvim";

  networking.resolvconf.enable = !(config.services.resolved.enable);

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

  nixpkgs.config.allowUnfree = true;

  services.atd.enable = true;
  services.orca.enable = false;
  services.resolved = {
    enable = true;
    extraConfig = ''
      [Resolve]
      Cache=no-negative
    '';
    dnssec = "false";
    dnsovertls = "false";
    fallbackDns = [
      "8.8.8.8"
      "114.114.114.114"
    ];
  };

  users.users.cuso4d = {
    isNormalUser = true;
    home = "/home/cuso4d";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJD6JpxiKFEThom4/HMchI8S08+Tuxvp04xSLxtMMLH cuso4d"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgnoIeHJv3VVT9SgOELc0rlnPz+cv4uA2yESbLdJ7Vv cuso4d"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILAuc62mBhz6WsjQ8A18hy4LhtmZpBtj/6vMsAUF0/gm cuso4d"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzaVljG6lJvVE4u5h9p76FIgWm4HQuWjdBPD7P1bQ+t cuso4d"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKJS3aK2ZMI10D0zQaLXzWXwxbWAUqvO55IYCBoAYFz1 cuso4d@nightcord-dynamica"
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
    extraConfig = ''
      set -g mouse on
    '';
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      tokyo-night-tmux
    ];
  };

  programs.zsh = {
    enable = true;

    interactiveShellInit = ''
      eval "$(direnv hook zsh)"

      # Remove command lines from the history list when the first character on the line is a space,
      # or when one of the expanded aliases contains a leading space. 
      setopt HIST_IGNORE_SPACE


      check_dirs_empty() {
        for dir in "$@"; do
          if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
            echo -e "\e[1;33mwarning: $dir is not empty.\e[0m"
          fi
        done
      }

      check_dirs_empty "$HOME/Downloads" "$HOME/empty"


      check_git_worktree_clean() {
        for dir in "$@"; do
          pushd $dir >/dev/null 2>&1 || continue
          if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            if git status --porcelain | grep -q .; then
              echo -e "\e[1;33mwarning: git tree $dir is dirty.\e[0m"
            fi
          fi
          popd >/dev/null 2>&1
        done
      }

      check_git_worktree_clean $HOME/temp $HOME/.nixos
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
      glr = "git pull --rebase";
      gmv = "git mv";
      gs = "git status --short --branch";
      j = "just";
      sudonvim = "sudo -E -s nvim";
    };
  };

  virtualisation.docker.enable = true;
}
