{
  pkgs,
  ...
}:
let
  nowplaying = pkgs.writeShellApplication {
    name = "nowplaying-waybar";
    runtimeInputs = with pkgs; [
      curl
      jq
    ];
    text = ''
      url="''${NOWPLAYING_URL:-}"
      if [ -z "$url" ] && [ -r /run/agenix/nowplaying-url ]; then
        url="$(cat /run/agenix/nowplaying-url)"
      fi
      if [ -z "$url" ]; then
        echo '{"text":""}'
        exit 0
      fi

      resp="$(curl -fsS --max-time 5 -- "$url" 2>/dev/null)" || {
        echo '{"text":""}'
        exit 0
      }

      line="$(printf '%s' "$resp" | jq -r '.data.music | select(. != null and .songname != "") | [.artist, .songname, .album] | @tsv' 2>/dev/null)"
      if [ -z "$line" ]; then
        echo '{"text":""}'
        exit 0
      fi

      artist="$(printf '%s' "$line" | cut -f1)"
      song="$(printf '%s' "$line" | cut -f2)"
      album="$(printf '%s' "$line" | cut -f3)"
      tooltip="$song - $artist"
      if [ -n "$album" ]; then
        tooltip="$tooltip · $album"
      fi
      jq -nc --arg text "$song - $artist" --arg tooltip "$tooltip" '{text: $text, tooltip: $tooltip}'
    '';
  };
in
{
  home.packages = [ nowplaying ];

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
        disk = {
          interval = 30;
          format = " {percentage_used}%";
        };
        battery = {
          format = "{icon} {capacity}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
        };
        cpu = {
          format = " {}%";
        };
        memory = {
          format = " {percentage}%";
        };
        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "custom/nowplaying"
          "network"
          "wireplumber"
          "cpu"
          "memory"
          "disk"
          "battery"
        ];
        "custom/nowplaying" = {
          exec = "${nowplaying}/bin/nowplaying-waybar";
          return-type = "json";
          hide-empty-text = true;
          interval = 30;
          format = "♪ {text}";
          max-length = 50;
          escape = true;
        };
        network = {
          interface = "wlp2s0";
          format = "{ifname}";
          format-wifi = " {essid} ({signalStrength}%)";
          format-ethernet = "󰊗 {ipaddr}/{cidr}";
          format-disconnected = ""; # An empty format will hide the module.
          tooltip-format = "󰊗 {ifname} via {gwaddr}";
          tooltip-format-wifi = " {essid} ({signalStrength}%)";
          tooltip-format-ethernet = " {ifname}";
          tooltip-format-disconnected = "󰅛 Disconnected";
          max-length = 50;
        };
        wireplumber = {
          format = "{icon} {volume}%";
          format-icons = [
            ""
            ""
            ""
          ];
          format-muted = "";
          max-volume = 100;
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          scroll-step = 5.0e-2;
        };
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
      #custom-nowplaying,
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

      #custom-nowplaying {
          color: #7aa2f7;
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
}
