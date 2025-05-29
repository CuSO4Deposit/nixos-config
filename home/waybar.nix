{ config, lib, pkgs, ... }:
{
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
}
