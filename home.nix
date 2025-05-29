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
    # GUI
    ghostty
    logseq
    nur.repos.linyinfeng.wemeet
    wofi

    # utils
    wl-clipboard

    ### defined in programs
    # home-manager
    # firefox
  ];

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
  programs.home-manager.enable = true;
  
  programs.wofi = {
    enable = true;
    # https://github.com/Sit-Back/wofi-tokyonight/blob/0909aacff8d578777e2d2c261a40bf456226e4c8/style.css
    style = ''
      window {
          background-color: rgb(26, 27, 38);
          border-radius: 0.5em;
      }

      #input {
          padding: 0.7em;
          border-radius: 0.5em 0.5em 0 0;
          background-color: #2d2e40;
          color: #c0caf5;
          border: none;
      }

      #text {
          color: #c0caf5;
      }

      #entry {
          padding: 0.7em;
          color: #c0caf5;
      }

    #entry:selected {
          background-color: #7aa2f7;
      } 

    #text:selected {
          color: #eee;
          font-weight: bold;
      }
    '';
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        clock = {
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#a9b1d6'><b>{}</b></span>";
              days = "<span color='#c0caf5'><b>{}</b></span>";
              weeks = "<span color='#b4f9f8'><b>W{}</b></span>";
              weekdays = "<span color='#ffc777'><b>{}</b></span>";
              today = "<span color='#ff757f'><b><u>{}</u></b></span>";
            };
          };
          format = "{:%Y-%m-%d %H:%M %Z}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };
        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "clock"
        ];
      };
    };
    # https://github.com/stronk-dev/Tokyo-Night-Linux/blob/d553d015a0d3c1e9e41b72aab959ad89f91b457d/.config/waybar/style.css
    style = ''
#waybar {
    font-family: "UbuntuMono Nerd Font Propo", Cantarell, Noto Sans, sans-serif;
    font-size: 16px;
}

#window {
    padding: 0 10px;
}

window#waybar {
    border: none;
    border-radius: 0;
    box-shadow: none;
    text-shadow: none;
    transition-duration: 0s;
    color: rgba(217, 216, 216, 1);
    background: #1a1b26; 
} 

#workspaces {
    margin: 0 5px;
}

#workspaces button {
    padding: 0 8px;
    color: #565f89;
    border: 3px solid rgba(9, 85, 225, 0);
    border-radius: 10px;
    min-width: 33px;
}

#workspaces button.visible {
    color: #a9b1d6;
}

#workspaces button.focused {
    border-top: 3px solid #7aa2f7;
    border-bottom: 3px solid #7aa2f7;
}

#workspaces button.urgent {
    background-color: #a96d1f;
    color: white;
}

#workspaces button:hover {
    box-shadow: inherit;
    border-color: #bb9af7;
    color: #bb9af7;
}

/* Repeat style here to ensure properties are overwritten as there's no !important and button:hover above resets the colour */

#workspaces button.focused {
    color: #7aa2f7;
}
#workspaces button.focused:hover {
    color: #bb9af7;
}

#pulseaudio {
    /* font-size: 26px; */
}

#custom-recorder {
  font-size: 18px;
  margin: 2px 7px 0px 7px;
  color:#ee2e24;
}

#tray,
#mode,
#battery,
#temperature,
#cpu,
#memory,
#network,
#pulseaudio,
#idle_inhibitor,
#sway-language,
#backlight,
#custom-storage,
#custom-cpu_speed,
#custom-powermenu,
#custom-spotify,
#custom-weather,
#custom-mail,
#custom-media {
    margin: 0px 0px 0px 10px;
    padding: 0 5px;
    /* border-top: 3px solid rgba(217, 216, 216, 0.5); */
}

#clock {
    margin:     0px 16px 0px 10px;
    min-width:  140px;
}

#battery.warning {
    color: rgba(255, 210, 4, 1);
}

#battery.critical {
    color: rgba(238, 46, 36, 1);
}

#battery.charging {
    color: rgba(217, 216, 216, 1);
}

#custom-storage.warning {
    color: rgba(255, 210, 4, 1);
}

#custom-storage.critical {
    color: rgba(238, 46, 36, 1);
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: black;
    }
}
    '';
    systemd.enable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    settings = {
      animations = {
        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
        ];
        bezier = [
          "easeOutQuint, 0.23, 1, 0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear, 0, 0, 1, 1"
          "almostLinear, 0.5, 0.5, 0.75, 1.0"
          "quick, 0.15, 0, 0.1, 1"
        ];
        enabled = true;
      };
      bind = [
        "$mainMod, Q, exec, $terminal"
        "$mainMod, C, killactive"
        "$mainMod, escape, exit"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, T, togglefloating"
        "$mainMod, P, pseudo"
        "$mainMod, space, exec, $menu"
        "$mainMod, V, togglesplit"
        "$mainMod, F, exec, firefox"
        "$mainMod, M, fullscreen, 1"

        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"
        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, j, movefocus, d"
        "$mainMod SHIFT, h, movewindow, l"
        "$mainMod SHIFT, l, movewindow, r"
        "$mainMod SHIFT, k, movewindow, u"
        "$mainMod SHIFT, j, movewindow, d"

        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        "$mainMod, S, togglespecialworkspace, scratch"
        "$mainMod SHIFT, S, movetoworkspace, special:scratch"

        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        "$mainMod, mouse:272, movewindow"
        # invalid dispatcher, requested "resizewindow" does not exist
        # "$mainMod, mouse:273, resizewindow"
      ];
      decoration = {
        active_opacity = 1.0;
        blur = {
          enabled = true;
          passes = 1;
          size = 3;
          vibrancy = 0.1696;
        };
        inactive_opacity = 1.0;
        rounding = 10;
        rounding_power = 2;
        shadow = {
          color = "rgba(1a1a1aee)";
          enabled = true;
          range = 4;
          render_power = 3;
        };
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      env = [
        "XCURSOR_SIZE, 24"
        "HYPRCURSOR_SIZE, 24"
      ];
      exec-once = [
        # https://github.com/hyprwm/Hyprland/discussions/421#discussioncomment-12027361
        "fcitx5-remote -r"
        "fcitx5 -d --replace &"
        "fcitx5-remote -r"
      ];
      general = {
        allow_tearing = false;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        gaps_in = 5;
        gaps_out = 20;
        layout = "dwindle";
        resize_on_border = false;
      };
      gestures = {
        workspace_swipe = false;
      };
      input = {
        follow_mouse = 1;
        kb_layout = "us";
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
        };
      };
      master = {
        new_status = "master";
      };
      misc = {
        disable_hyprland_logo = false;
        force_default_wallpaper = -1;
      };
      monitor = ",prefered,auto,1";
      windowrule = [
        "suppressevent maximize, class:.*"
        # Fix some dragging issues with XWayland
        "nofocus, class:^$, title:^$, xwayland:1, floating:1, fullscreen:0, pinned:0"
      ];

      # variables
      "$fileManager" = "nautilus";
      "$menu" = "wofi --show=drun";
      "$mainMod" = "SUPER";
      "$terminal" = "ghostty";
    };
    systemd.enable = true;
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
