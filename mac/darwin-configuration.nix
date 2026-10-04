# nix-darwin system configuration for the MacBook (nightcord-neo).
#
# Responsibilities split:
#   - nixpkgs      -> packages (CLI tools, libraries)
#   - nix-darwin   -> this file: system config, launchd, defaults, homebrew bridge
#   - home-manager -> mac/home.nix: user-level config (AeroSpace, ghostty, ...)

{
  pkgs,
  inputs,
  ...
}:

let
  proxy = "http://127.0.0.1:7890";
  socksProxy = "socks5://127.0.0.1:7890";
  noProxy = "127.0.0.1,localhost,::1,.local,10.20.0.0/24,192.168.31.0/24";
  common = import ../lib/common.nix;
in
{
  system.stateVersion = 6;
  system.primaryUser = "cuso4d";

  networking.hostName = "nightcord-neo";

  nix = {
    enable = true;
    package = pkgs.lixPackageSets.stable.lix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "cuso4d"
        "root"
      ];
      extra-substituters = [
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      ];
    };
    gc = {
      automatic = true;
      interval = [ { Weekday = 7; Hour = 3; Minute = 15; } ];
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    http_proxy = proxy;
    https_proxy = proxy;
    all_proxy = socksProxy;
    no_proxy = noProxy;
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "http_proxy https_proxy all_proxy no_proxy"
  '';

  # Give the nix-daemon the proxy environment variables.
  launchd.envVariables = {
    http_proxy = proxy;
    https_proxy = proxy;
    all_proxy = socksProxy;
    no_proxy = noProxy;
  };

  # home-manager (embedded as a nix-darwin module) derives the user's
  # home.username / home.homeDirectory from here.
  users.users.cuso4d = {
    name = "cuso4d";
    home = "/Users/cuso4d";
  };

  environment.systemPackages = with pkgs; [
    coreutils
    git
    gnumake
    jq
    (common.nvim inputs pkgs)
  ];

  fonts.packages = common.fonts pkgs;

  # GUI apps come from Homebrew casks (more reliable on macOS than nixpkgs).
  # AeroSpace lives in a third-party tap.
  homebrew = {
    enable = true;
    casks = [
      "nikitabobko/tap/aerospace"
      "ghostty"
      "firefox"
      "logseq"
      "clash-verge-rev"
    ];
    onActivation.extraEnv = {
      http_proxy = proxy;
      https_proxy = proxy;
      all_proxy = socksProxy;
      no_proxy = noProxy;
    };
  };

  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "Nlsv";
    finder.ShowPathbar = true;
  };
}
