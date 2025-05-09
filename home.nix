{ config, pkgs, ... }:

{
  home.homeDirectory = "/home/cuso4d";
  home.username = "cuso4d";

  home.file."${config.xdg.configHome}" = {
    force = true;
    source = ./files/.config;
    recursive = true;
  };
  home.packages = with pkgs; [
    ghostty
    logseq
    nur.repos.linyinfeng.wemeet
    wl-clipboard

    ### defined in programs
    # home-manager
    # firefox
  ];

  programs.home-manager.enable = true;
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland;
    policies = {
      AppUpdateURL = "https://localhost";
      DisableAppUpdate = true;
      DisplayBookmarksToolbar = "never";
      DisableDeveloperTools = false;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableProfileImport = false;
      DisableSetDesktopBackground = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      Extensions = {
        Install = [
          # Dark Reader
          "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi"
          # uBlock Origin
          "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
          # Vimium
          "https://addons.mozilla.org/firefox/downloads/file/4458679/vimium_ff-latest.xpi"
        ];
        Uninstall = [
          "amazondotcom@search.mozilla.org"
          "ebay@search.mozilla.org"
          "twitter@search.mozilla.org"
        ];
      };
      FirefoxSuggest = {
        ImproveSuggest = false;
        Locked = true;
        SponsoredSuggestions = false;
        WebSuggestions = false;
      };
      NoDefaultBookmarks = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      Proxy = {
        HTTPProxy = "127.0.0.1:20171";
        Locked = true;
        Mode = "manual";
        SOCKSProxy = "127.0.0.1:20170";
        SOCKSVersion = 5;
      };
    };
    profiles = {
      ${config.home.username} = {
        isDefault = true;
        search = {
          default = "DuckDuckGo Lite";
          force = true;
          order = [ "DuckDuckGo Lite" "google" "Baidu" "bing" "Nix Packages" ];
          engines = {
            "DuckDuckGo Lite" = {
              urls = [{
                template = "https://lite.duckduckgo.com/lite";
                params = [
                  { name = "q"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.fetchurl {
                url = "https://duckduckgo.com/favicon.ico";
                sha256 = "sha256-2ZT4BrHkIltQvlq2gbLOz4RcwhahmkMth4zqPLgVuv0=";
              }}";
            };
            "Baidu" = {
              urls = [{
                template = "https://www.baidu.com/s";
                params = [
                  { name = "wd"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.fetchurl {
                url = "https://www.baidu.com/favicon.ico";
                sha256 = "sha256-xwCIB5/pRBpybGbODnOuODFeyABR091ULEG4L6ChmTo=";
              }}";
              definedAliases = [ "@bd" ];
            };
            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "channel"; value = "unstable"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
          };
        };
        settings = {
          browser.contentblocking.category = "strict";
          privacy.fingerprintProtection = true;
          privacy.sanitize.sanitizeOnShutdown = true;
          privacy.trackingprotection.emailtracking.enabled = true;
          privacy.trackingprotection.enabled = true;
        };
      };
    };
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
