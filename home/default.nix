{
  config,
  pkgs,
  agenix,
  ...
}:
{
  home.homeDirectory = "/home/cuso4d";
  home.username = "cuso4d";
  home.file."${config.xdg.configHome}" = {
    force = true;
    source = ../files/.config;
    recursive = true;
  };
  home.packages = with pkgs; [
    # GUI
    evolution
    feishu
    (pkgs.callPackage ../derivations/feishu-fcitx5 { })
    filezilla
    ghostty
    grim
    keepassxc
    localsend
    logseq
    obs-studio
    qq
    slurp
    telegram-desktop
    vlc
    wechat
    wemeet
    (pkgs.callPackage ../derivations/wemeet-nvidia { })
    wofi
    zeal
    zotero

    # utils
    wl-clipboard
  ];

  imports = [
    ./dunst.nix
    ./hypridle.nix
    ./hyprland.nix
    ./hyprlock.nix
    ./hyprpaper.nix
    ./firefox.nix
    ./waybar.nix
    ./wofi.nix
    agenix.homeManagerModules.default
  ];

  programs.home-manager.enable = true;
  programs.zathura = {
    enable = true;
    mappings = {
      u = "scroll half-up";
      d = "scroll half-down";
      "<C-d>" = "toggle_page_mode";
    };
    options = {
      recolor = true;
      recolor-darkcolor = "#c0caf5";
      recolor-lightcolor = "#1a1b26";
      selection-clipboard = "clipboard";
    };
    package = pkgs.zathura.override {
      plugins = with pkgs.zathuraPkgs; [
        zathura_pdf_mupdf
      ];
    };
  };

  services.copyq = {
    enable = true;
    forceXWayland = false;
  };

  xdg.desktopEntries = {
    feishu-fcitx5 = {
      name = "FeishuFcitx5";
      exec = "feishu-fcitx5 %U";
      type = "Application";
      terminal = false;
    };
    wemeet-nvidia = {
      name = "WemeetAppNvidia";
      exec = "wemeet-nvidia %u";
      type = "Application";
      terminal = false;
    };
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Did you read the comment?
}
