{ lib, pkgs, ... }:
{
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
        "$mainMod, S, exec, logseq"

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

        "$mainMod, -, togglespecialworkspace, scratch"
        "$mainMod SHIFT, -, movetoworkspace, special:scratch"

        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        "$mainMod, mouse:272, movewindow"
        # invalid dispatcher, requested "resizewindow" does not exist
        # "$mainMod, mouse:273, resizewindow"

        '', Print, exec, grim -g "$(slurp -d)" - | wl-copy''
      ];
      binde = [
        '', XF86AudioMute, exec, "wpctl set-volume @DEFAULT_AUDIO_SINK@ toggle"''
        '', XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+''
        '', XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-''
        '', XF86MonBrightnessUp, exec, brightnessctl set 5%+ -d intel_backlight ''
        '', XF86MonBrightnessDown, exec, brightnessctl set 5%- -d intel_backlight ''
        '', code:97, exec, brightnessctl set 5%- -d intel_backlight''

        # Another keybind for dynamica
        '', muhenkan, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-''
        '', henkan_mode, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+''
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
      input = {
        follow_mouse = 1;
        kb_layout = "us";
        numlock_by_default = true;
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
}
