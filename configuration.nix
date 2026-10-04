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

let
  common = import ./lib/common.nix;
in
{
  imports = [
    ./modules/internal-cache.nix
  ];

  age.identityPaths = lib.map (x: "/home/${x}/.ssh/id_ed25519") (
    lib.attrNames (lib.attrsets.filterAttrs (_: v: v.isNormalUser) config.users.users)
  );

  environment.systemPackages = (common.cliPackages pkgs) ++ (with pkgs; [
    at
    busybox
    git
    jq
    (common.nvim inputs pkgs)
  ]);

  environment.variables = common.envVars;

  age.secrets."nixvim-minuet-deepseek-api-key" = {
    file = ./secrets/nixvim-minuet-deepseek-api-key.age;
    mode = "0444";
  };

  environment.etc."zshenv.local".text = ''
    secret_path=${config.age.secrets."nixvim-minuet-deepseek-api-key".path}
    if [ -r "$secret_path" ]; then
      export NIXVIM_MINUET_DEEPSEEK_API_KEY="$(cat "$secret_path")"
    fi
  '';
  environment.etc."profile.local".text = ''
    secret_path=${config.age.secrets."nixvim-minuet-deepseek-api-key".path}
    if [ -r "$secret_path" ]; then
      export NIXVIM_MINUET_DEEPSEEK_API_KEY="$(cat "$secret_path")"
    fi
  '';

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
  # extra-substituters / extra-trusted-public-keys for the internal cache live
  # in modules/internal-cache.nix so a host can opt out of it.
  nix.settings.trusted-users = [
    "cuso4d"
    "root"
  ];

  nixpkgs.config.allowUnfree = true;

  # OOM configuration: prevent nix-daemon from freezing the system
  # https://discourse.nixos.org/t/nix-build-ate-my-ram/35752
  systemd = {
    slices."nix-daemon".sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "50%";
    };
    services."nix-daemon".serviceConfig = {
      Slice = "nix-daemon.slice";
      OOMScoreAdjust = 1000;
      CPUWeight = 50;
    };
  };

  services.atd.enable = true;
  services.openssh = {
    enable = true;
    settings.KbdInteractiveAuthentication = false;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };
  services.resolved = {
    enable = true;
  };

  users.users.cuso4d = {
    isNormalUser = true;
    home = "/home/cuso4d";
    # 0700 would zero the POSIX ACL mask on /home/cuso4d (the group-class
    # bits ARE the mask), silently dropping the u:syncthing:--x traverse
    # entry set via tmpfiles and breaking Syncthing. 0710 keeps mask=--x so
    # syncthing can traverse into ~/syncthing; other stays --- for privacy.
    homeMode = "710";
    extraGroups = [
      "docker"
      "wheel"
      "networkmanager"
    ];
    linger = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJD6JpxiKFEThom4/HMchI8S08+Tuxvp04xSLxtMMLH cuso4d"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgnoIeHJv3VVT9SgOELc0rlnPz+cv4uA2yESbLdJ7Vv cuso4d"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILAuc62mBhz6WsjQ8A18hy4LhtmZpBtj/6vMsAUF0/gm cuso4d"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzaVljG6lJvVE4u5h9p76FIgWm4HQuWjdBPD7P1bQ+t cuso4d"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF4rWlDqIGqCRsXaF/QuYuMrWIvQ1fFLr8XyxCFQl07q cuso4d@nightcord-lexikos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKJS3aK2ZMI10D0zQaLXzWXwxbWAUqvO55IYCBoAYFz1 cuso4d@nightcord-dynamica"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEVOjjy6t6+Eo5CoGRAUM6VSO1Npik9E0UsOXIVMl90E cuso4d@nightcord-proximo"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE2iNJhvz4sWKAi1p8Y1VYjw7cORp1rMryDQRPO8lYOj cuso4d@nightcord-redivia"
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
    config = common.gitSettings;
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
      set -s extended-keys on
      set -as terminal-features ',xterm*:extkeys'
    '';
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      tokyo-night-tmux
    ];
  };

  programs.zsh = {
    autosuggestions.enable = true;
    enable = true;
    histSize = 50000;

    interactiveShellInit = common.zshInit;

    ohMyZsh = {
      enable = true;
      package = pkgs.callPackage ./derivations/oh-cus-zsh { };
      inherit (common.ohMyZsh) plugins theme;
    };

    shellAliases = common.shellAliases;
    syntaxHighlighting.enable = true;
  };

  virtualisation.docker.enable = true;
}
