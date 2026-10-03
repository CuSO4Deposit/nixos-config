# home-manager configuration for the MacBook (nightcord-neo).
#
# mainMod = Option (⌥), matching the physical "Win key" position on a PC
# keyboard. Command (⌘) is left untouched so Cmd+C/V/S keep working as copy /
# paste / save, exactly like macOS expects.

{
  pkgs,
  ...
}:

{
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    bat
    eza
    fd
    fzf
    ripgrep
    zoxide
  ];

  # AeroSpace tiling WM. Config is a direct port of ~/.nixos/home/hyprland.nix
  # bindings (SUPER -> Option).
  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

  # Terminal. GUI app itself comes from Homebrew cask; this is just the config.
  xdg.configFile."ghostty/config".text = ''
    font-family = UbuntuMono Nerd Font Mono
    font-size = 16
    theme = TokyoNight Night
  '';

  programs.home-manager.enable = true;
}
