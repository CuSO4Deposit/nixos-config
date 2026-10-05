# nix-darwin system configuration for the MacBook (nightcord-neo).
#
# Responsibilities split:
#   - nixpkgs      -> packages (CLI tools, libraries)
#   - nix-darwin   -> this file: system config, launchd, defaults, homebrew bridge
#   - home-manager -> home/darwin/default.nix: user-level config (AeroSpace, ghostty, ...)

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
  common = import ../../lib/common.nix;
  serperMcp = import ../../lib/serper-mcp.nix {
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
    file = ../../secrets/nixvim-minuet-deepseek-api-key.age;
    mode = "0444";
  };

  age.secrets."serper-api-key" = {
    file = ../../secrets/serper-api-key.age;
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
  # AeroSpace lives in a third-party tap.
  homebrew = {
    enable = true;
    casks = [
      "nikitabobko/tap/aerospace"
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

  # Cask Firefox is launched via Finder/LaunchServices, so it does not inherit
  # home-manager's sessionVariables. Set MOZ_LEGACY_PROFILES in the user's
  # launchd (GUI) domain so Firefox accepts the read-only home-manager-managed
  # profiles.ini instead of repeatedly prompting to pick a profile.
  # See https://github.com/nix-community/home-manager/issues/3323
  launchd.user.agents.FirefoxEnv = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "launchctl setenv MOZ_LEGACY_PROFILES 1; launchctl setenv MOZ_ALLOW_DOWNGRADE 1"
      ];
      RunAtLoad = true;
    };
  };

  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "Nlsv";
    finder.ShowPathbar = true;
  };
}
