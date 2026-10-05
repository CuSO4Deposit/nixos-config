# home-manager configuration for the MacBook (nightcord-neo).
#
# mainMod = Option (⌥), matching the physical "Win key" position on a PC
# keyboard. Command (⌘) is left untouched so Cmd+C/V/S keep working as copy /
# paste / save, exactly like macOS expects.
{
  pkgs,
  lib,
  ...
}:

let
  common = import ../lib/common.nix;
in
{
  imports = [
    ./zsh.nix
    ../home/common/firefox.nix
    ../home/common/opencode.nix
  ];

  home.stateVersion = "24.11";

  home.sessionVariables = common.envVars;

  home.packages =
    (common.cliPackages pkgs)
    ++ (with pkgs; [
      eza
      fd
      fzf
      htop
      opencode
      zoxide
    ]);

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = common.gitSettings;
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    mouse = true;
    extraConfig = ''
      set -s extended-keys on
      set -as terminal-features ',xterm*:extkeys'
    '';
    plugins = with pkgs.tmuxPlugins; [
      tokyo-night-tmux
    ];
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

  # Karabiner-Elements remaps Option+hjkl/m/c to the built-in macOS window
  # tiling shortcuts (Fn+Control+arrow/F/C), so the old AeroSpace muscle memory
  # still works. FlashSpace owns workspaces; the native tiler owns layout.
  xdg.configFile."karabiner/karabiner.json".source = ./karabiner.json;

  # Terminal. GUI app itself comes from Homebrew cask; this is just the config.
  xdg.configFile."ghostty/config".text = ''
    font-family = UbuntuMono Nerd Font Mono
    font-size = 16
    theme = TokyoNight Night
  '';

  # Desktop wallpaper. The image lives in ~/Pictures and is intentionally not
  # committed to git; desktoppr writes it via the private API, so unlike
  # osascript it needs no Automation permission.
  home.activation.setWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "$HOME/Pictures/wallpaper.jpeg" ]; then
      ${pkgs.desktoppr}/bin/desktoppr "$HOME/Pictures/wallpaper.jpeg" || true
    fi
  '';

  # FlashSpace is split on purpose:
  #   - settings.json is pure config (global settings + hotkeys). We never
  #     change it at runtime, so it is declarative via a read-only store
  #     symlink. Edit it here and `sm`.
  #   - profiles.json mixes config with *runtime data*: each workspace's app
  #     membership is added/reassigned while running. That's data, not config,
  #     so it is NOT managed here — FlashSpace owns
  #     ~/.config/flashspace/profiles.json and may rewrite it freely.
  xdg.configFile."flashspace/settings.json".source = ./flashspace-settings.json;

  programs.home-manager.enable = true;
}
