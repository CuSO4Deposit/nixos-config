{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland;
    # https://mozilla.github.io/policy-templates
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
          # FoxyProxy Standard
          "https://addons.mozilla.org/firefox/downloads/latest/foxyproxy-standard/lateset.xpi"
          # KeePassXC-Browser
          "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/lateset.xpi"
          # uBlock Origin
          "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
          # Vimium
          "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi"
          # xBrowserSync
          "https://addons.mozilla.org/firefox/downloads/latest/xbs/latest.xpi"
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
        Locked = false;
        Mode = "none";
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
          order = [
            "DuckDuckGo Lite"
            "google"
            "Baidu"
            "bing"
            "Nix Packages"
          ];
          engines = {
            "DuckDuckGo Lite" = {
              urls = [
                {
                  template = "https://lite.duckduckgo.com/lite";
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.fetchurl {
                url = "https://duckduckgo.com/favicon.ico";
                sha256 = "sha256-2ZT4BrHkIltQvlq2gbLOz4RcwhahmkMth4zqPLgVuv0=";
              }}";
            };
            "Baidu" = {
              urls = [
                {
                  template = "https://www.baidu.com/s";
                  params = [
                    {
                      name = "wd";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.fetchurl {
                url = "https://www.baidu.com/favicon.ico";
                sha256 = "sha256-xwCIB5/pRBpybGbODnOuODFeyABR091ULEG4L6ChmTo=";
              }}";
              definedAliases = [ "@bd" ];
            };
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS Options" = {
              urls = [
                {
                  template = "https://search.nixos.org/options";
                  params = [
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };
          };
        };
        settings = {
          browser.contentblocking.category = "strict";
          # https://www.reddit.com/r/firefox/comments/kfyso6/possible_to_change_default_zoom_level_in/
          font.size.systemFontScale = 120;
          privacy.fingerprintProtection = true;
          privacy.sanitize.sanitizeOnShutdown = true;
          privacy.trackingprotection.emailtracking.enabled = true;
          privacy.trackingprotection.enabled = true;
        };
      };
    };
  };
}
