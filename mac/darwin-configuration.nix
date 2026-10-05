# nix-darwin system configuration for the MacBook (nightcord-neo).
#
# Responsibilities split:
#   - nixpkgs      -> packages (CLI tools, libraries)
#   - nix-darwin   -> this file: system config, launchd, defaults, homebrew bridge
#   - home-manager -> mac/home.nix: user-level config (Karabiner, ghostty, ...)

{
  pkgs,
  inputs,
  config,
  ...
}:

let
  proxy = "http://127.0.0.1:7890";
  socksProxy = "socks5://127.0.0.1:7890";
  noProxy = "127.0.0.1,localhost,::1,.local,10.20.0.0/24,192.168.31.0/24";
  common = import ../lib/common.nix;
  serperMcp = import ../lib/serper-mcp.nix {
    inherit pkgs;
    secretPath = config.age.secrets."serper-api-key".path;
  };
in
{
  system.stateVersion = 6;
  system.primaryUser = "cuso4d";

  networking.hostName = "nightcord-neo";

  nix = {
    enable = true;
    package = pkgs.lixPackageSets.stable.lix;
    # Proxy env for both shells and the nix-daemon.
    envVars = {
      http_proxy = proxy;
      https_proxy = proxy;
      all_proxy = socksProxy;
      no_proxy = noProxy;
    };
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
      interval = [
        {
          Weekday = 7;
          Hour = 3;
          Minute = 15;
        }
      ];
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (_: _: {
      # Match the NixOS hosts: opencode from a nixpkgs rev that ships 1.18.31.
      opencode = (import inputs.nixpkgs-opencode { system = pkgs.stdenv.hostPlatform.system; }).opencode;
    })
  ];

  security.sudo.extraConfig = ''
    Defaults env_keep += "http_proxy https_proxy all_proxy no_proxy"
  '';

  age.identityPaths = [ "/Users/cuso4d/.ssh/id_ed25519" ];

  age.secrets."nixvim-minuet-deepseek-api-key" = {
    file = ../secrets/nixvim-minuet-deepseek-api-key.age;
    mode = "0444";
  };

  age.secrets."serper-api-key" = {
    file = ../secrets/serper-api-key.age;
    mode = "0444";
  };

  home-manager.users.cuso4d.nightcord.opencode.serperMcp = "${serperMcp}/bin/serper-mcp";

  environment.etc."zshenv.local".text = ''
    secret_path=${config.age.secrets."nixvim-minuet-deepseek-api-key".path}
    if [ -r "$secret_path" ]; then
      export NIXVIM_MINUET_DEEPSEEK_API_KEY="$(cat "$secret_path")"
    fi
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
    (common.nvim inputs pkgs)
  ];

  fonts.packages = common.fonts pkgs;

  # GUI apps come from Homebrew casks (more reliable on macOS than nixpkgs).
  # FlashSpace handles virtual workspaces (native show/hide, so hidden apps stop
  # rendering); window layout is the built-in macOS tiling, triggered by the
  # Option+vim/arrow keys via Karabiner.
  homebrew = {
    enable = true;
    casks = [
      "flashspace"
      "karabiner-elements"
      "ghostty"
      "firefox"
      "logseq"
      "clash-verge-rev"
      "keepassxc"
      "localsend"
      "telegram"
      "vlc"
      "zotero"
      "feishu"
      "wechat"
      "qq"
      "tencent-meeting"
    ];
    onActivation.extraEnv = {
      http_proxy = proxy;
      https_proxy = proxy;
      all_proxy = socksProxy;
      no_proxy = noProxy;
    };
  };

  system.defaults = {
    WindowManager = {
      StandardHideWidgets = true;
      StageManagerHideWidgets = true;
    };
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "Nlsv";
    finder.ShowPathbar = true;
  };
}
