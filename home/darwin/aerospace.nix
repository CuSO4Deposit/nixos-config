# AeroSpace tiling WM. Bindings are a port of home/linux/hyprland.nix
# (SUPER -> Option). The GUI app itself comes from the Homebrew cask in
# hosts/neo/default.nix; this is just the config.
{
  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;
}
