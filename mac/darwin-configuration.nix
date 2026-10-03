# nix-darwin system configuration for the MacBook (nightcord-neo).
#
# Responsibilities split:
#   - nixpkgs      -> packages (CLI tools, libraries)
#   - nix-darwin   -> this file: system config, launchd, defaults, homebrew bridge
#   - home-manager -> mac/home.nix: user-level config (AeroSpace, ghostty, ...)

{
  pkgs,
  ...
}:

let
  # Clash Verge Rev's mixed-port (HTTP + SOCKS) listener. Everything is pointed
  # at it through environment variables on purpose; we use neither the macOS
  # system proxy nor TUN mode.
  proxy = "http://127.0.0.1:7897";
  socksProxy = "socks5://127.0.0.1:7897";
  noProxy = "127.0.0.1,localhost,::1,.local,10.20.0.0/24,192.168.31.0/24";
in
{
  system.stateVersion = 6;
  system.primaryUser = "cuso4d";

  networking.hostName = "nightcord-neo";

  # Determinate Nix manages the Nix installation and its daemon. nix-darwin's
  # native Nix management conflicts with it, so hand Nix over to Determinate.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  # Proxy: point CLI tools (nix, git, curl, brew, ...) at Clash Verge Rev via
  # environment variables. `environment.variables` is sourced by shells, while
  # `security.sudo.extraConfig` keeps the values across `sudo` so root-side
  # flake fetching also goes through the proxy.
  environment.variables = {
    http_proxy = proxy;
    https_proxy = proxy;
    all_proxy = socksProxy;
    no_proxy = noProxy;
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "http_proxy https_proxy all_proxy no_proxy"
  '';

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
  ];

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
    # `brew bundle` runs under sudo during activation, which strips the proxy
    # variables from environment.variables; inject them again for downloads.
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
