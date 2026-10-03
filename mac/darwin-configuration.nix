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

{
  system.stateVersion = 6;
  system.primaryUser = "cuso4d";

  networking.hostName = "nightcord-neo";

  # Determinate Nix manages the Nix installation and its daemon. nix-darwin's
  # native Nix management conflicts with it, so hand Nix over to Determinate.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

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
    ];
  };

  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "Nlsv";
    finder.ShowPathbar = true;
  };
}
