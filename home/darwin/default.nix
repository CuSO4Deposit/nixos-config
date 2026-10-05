# home-manager configuration for the MacBook (nightcord-neo).
#
# mainMod = Option (⌥), matching the physical "Win key" position on a PC
# keyboard. Command (⌘) is left untouched so Cmd+C/V/S keep working as copy /
# paste / save, exactly like macOS expects.
{
  pkgs,
  ...
}:

let
  common = import ../../lib/common.nix;
in
{
  imports = [
    ./zsh.nix
    ../common/firefox.nix
    ../common/opencode.nix
  ];

  home.stateVersion = "24.11";

  home.sessionVariables = common.envVars;

  home.packages = (common.cliPackages pkgs) ++ (with pkgs; [
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
