{ lib, pkgs, ... }:
let
  lua = lib.generators.mkLuaInline;

  exec = command: lua "hl.dsp.exec_cmd(${builtins.toJSON command})";
  dispatch = expr: lua "hl.dsp.${expr}";
  mkBind = key: dispatcher: {
    _args = [
      key
      dispatcher
    ];
  };
  mkBindWith = key: dispatcher: options: {
    _args = [
      key
      dispatcher
      options
    ];
  };
  mkEnv = name: value: {
    _args = [
      name
      value
    ];
  };
  mkCurve = name: x1: y1: x2: y2: {
    _args = [
      name
      {
        type = "bezier";
        points = [
          [
            x1
            y1
          ]
          [
            x2
            y2
          ]
        ];
      }
    ];
  };
  mkAnimation =
    leaf: enabled: speed: bezier: style:
    {
      inherit
        leaf
        enabled
        speed
        bezier
        ;
    }
    // lib.optionalAttrs (style != null) { inherit style; };
  startupHook =
    commands:
    lua (
      "function()\n"
      + lib.concatMapStrings (command: "  hl.exec_cmd(${builtins.toJSON command})\n") commands
      + "end"
    );
in
{
  wayland.windowManager.hyprland = {
    configType = "lua";
    enable = true;
    package = pkgs.hyprland;
    settings = {
      config = {
        animations.enabled = true;
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
          preserve_split = true;
        };
        general = {
          allow_tearing = false;
          border_size = 2;
          col = {
            active_border = {
              colors = [
                "rgba(33ccffee)"
                "rgba(00ff99ee)"
              ];
              angle = 45;
            };
            inactive_border = "rgba(595959aa)";
          };
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
      };
      curve = [
        (mkCurve "easeOutQuint" 0.23 1 0.32 1)
        (mkCurve "easeInOutCubic" 0.65 0.05 0.36 1)
        (mkCurve "linear" 0 0 1 1)
        (mkCurve "almostLinear" 0.5 0.5 0.75 1.0)
        (mkCurve "quick" 0.15 0 0.1 1)
      ];
      animation = [
        (mkAnimation "global" true 10 "default" null)
        (mkAnimation "border" true 5.39 "easeOutQuint" null)
        (mkAnimation "windows" true 4.79 "easeOutQuint" null)
        (mkAnimation "windowsIn" true 4.1 "easeOutQuint" "popin 87%")
        (mkAnimation "windowsOut" true 1.49 "linear" "popin 87%")
        (mkAnimation "fadeIn" true 1.73 "almostLinear" null)
        (mkAnimation "fadeOut" true 1.46 "almostLinear" null)
        (mkAnimation "fade" true 3.03 "quick" null)
        (mkAnimation "layers" true 3.81 "easeOutQuint" null)
        (mkAnimation "layersIn" true 4 "easeOutQuint" "fade")
        (mkAnimation "layersOut" true 1.5 "linear" "fade")
        (mkAnimation "fadeLayersIn" true 1.79 "almostLinear" null)
        (mkAnimation "fadeLayersOut" true 1.39 "almostLinear" null)
        (mkAnimation "workspaces" true 1.94 "almostLinear" "fade")
        (mkAnimation "workspacesIn" true 1.21 "almostLinear" "fade")
        (mkAnimation "workspacesOut" true 1.94 "almostLinear" "fade")
      ];
      bind = [
        (mkBind "SUPER + Q" (exec "ghostty"))
        (mkBind "SUPER + C" (dispatch "window.close()"))
        (mkBind "SUPER + escape" (dispatch "exit()"))
        (mkBind "SUPER + E" (exec "nautilus"))
        (mkBind "SUPER + T" (dispatch ''window.float({ action = "toggle" })''))
        (mkBind "SUPER + P" (dispatch "window.pseudo()"))
        (mkBind "SUPER + space" (exec "wofi --show=drun"))
        (mkBind "SUPER + V" (dispatch ''layout("togglesplit")''))
        (mkBind "SUPER + F" (exec "firefox"))
        (mkBind "SUPER + M" (dispatch ''window.fullscreen({ mode = "maximized", action = "toggle" })''))
        (mkBind "SUPER + S" (exec "logseq"))
        (mkBind "SUPER + backspace" (exec "loginctl lock-session"))
        (mkBind "SUPER + SHIFT + backspace" (exec "loginctl lock-session && systemctl suspend"))

        (mkBind "SUPER + left" (dispatch ''focus({ direction = "left" })''))
        (mkBind "SUPER + right" (dispatch ''focus({ direction = "right" })''))
        (mkBind "SUPER + up" (dispatch ''focus({ direction = "up" })''))
        (mkBind "SUPER + down" (dispatch ''focus({ direction = "down" })''))
        (mkBind "SUPER + SHIFT + left" (dispatch ''window.move({ direction = "left" })''))
        (mkBind "SUPER + SHIFT + right" (dispatch ''window.move({ direction = "right" })''))
        (mkBind "SUPER + SHIFT + up" (dispatch ''window.move({ direction = "up" })''))
        (mkBind "SUPER + SHIFT + down" (dispatch ''window.move({ direction = "down" })''))
        (mkBind "SUPER + h" (dispatch ''focus({ direction = "left" })''))
        (mkBind "SUPER + l" (dispatch ''focus({ direction = "right" })''))
        (mkBind "SUPER + k" (dispatch ''focus({ direction = "up" })''))
        (mkBind "SUPER + j" (dispatch ''focus({ direction = "down" })''))
        (mkBind "SUPER + SHIFT + h" (dispatch ''window.move({ direction = "left" })''))
        (mkBind "SUPER + SHIFT + l" (dispatch ''window.move({ direction = "right" })''))
        (mkBind "SUPER + SHIFT + k" (dispatch ''window.move({ direction = "up" })''))
        (mkBind "SUPER + SHIFT + j" (dispatch ''window.move({ direction = "down" })''))

        (mkBind "SUPER + 1" (dispatch ''focus({ workspace = "1" })''))
        (mkBind "SUPER + 2" (dispatch ''focus({ workspace = "2" })''))
        (mkBind "SUPER + 3" (dispatch ''focus({ workspace = "3" })''))
        (mkBind "SUPER + 4" (dispatch ''focus({ workspace = "4" })''))
        (mkBind "SUPER + 5" (dispatch ''focus({ workspace = "5" })''))
        (mkBind "SUPER + 6" (dispatch ''focus({ workspace = "6" })''))
        (mkBind "SUPER + 7" (dispatch ''focus({ workspace = "7" })''))
        (mkBind "SUPER + 8" (dispatch ''focus({ workspace = "8" })''))
        (mkBind "SUPER + 9" (dispatch ''focus({ workspace = "9" })''))
        (mkBind "SUPER + 0" (dispatch ''focus({ workspace = "10" })''))

        (mkBind "SUPER + SHIFT + 1" (dispatch ''window.move({ workspace = "1" })''))
        (mkBind "SUPER + SHIFT + 2" (dispatch ''window.move({ workspace = "2" })''))
        (mkBind "SUPER + SHIFT + 3" (dispatch ''window.move({ workspace = "3" })''))
        (mkBind "SUPER + SHIFT + 4" (dispatch ''window.move({ workspace = "4" })''))
        (mkBind "SUPER + SHIFT + 5" (dispatch ''window.move({ workspace = "5" })''))
        (mkBind "SUPER + SHIFT + 6" (dispatch ''window.move({ workspace = "6" })''))
        (mkBind "SUPER + SHIFT + 7" (dispatch ''window.move({ workspace = "7" })''))
        (mkBind "SUPER + SHIFT + 8" (dispatch ''window.move({ workspace = "8" })''))
        (mkBind "SUPER + SHIFT + 9" (dispatch ''window.move({ workspace = "9" })''))
        (mkBind "SUPER + SHIFT + 0" (dispatch ''window.move({ workspace = "10" })''))

        (mkBind "SUPER + minus" (dispatch ''workspace.toggle_special("scratch")''))
        (mkBind "SUPER + SHIFT + minus" (dispatch ''window.move({ workspace = "special:scratch" })''))

        (mkBind "SUPER + mouse_down" (dispatch ''focus({ workspace = "e+1" })''))
        (mkBind "SUPER + mouse_up" (dispatch ''focus({ workspace = "e-1" })''))
        (mkBindWith "SUPER + mouse:272" (dispatch "window.drag()") { mouse = true; })

        (mkBind "Print" (exec ''grim -g "$(slurp -d)" - | wl-copy''))
        (mkBindWith "XF86AudioMute" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ toggle") {
          repeating = true;
        })
        (mkBindWith "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+") {
          repeating = true;
        })
        (mkBindWith "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") {
          repeating = true;
        })
        (mkBindWith "XF86MonBrightnessUp" (exec "brightnessctl set 5%+ -d intel_backlight") {
          repeating = true;
        })
        (mkBindWith "XF86MonBrightnessDown" (exec "brightnessctl set 5%- -d intel_backlight") {
          repeating = true;
        })
        (mkBindWith "code:97" (exec "brightnessctl set 5%- -d intel_backlight") { repeating = true; })
        (mkBindWith "muhenkan" (exec "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-") {
          repeating = true;
        })
        (mkBindWith "henkan_mode" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") { repeating = true; })
      ];
      env = [
        (mkEnv "XCURSOR_SIZE" "24")
        (mkEnv "HYPRCURSOR_SIZE" "24")
      ];
      on = {
        _args = [
          "hyprland.start"
          (startupHook [
            # https://github.com/hyprwm/Hyprland/discussions/421#discussioncomment-12027361
            "fcitx5-remote -r"
            "fcitx5 -d --replace &"
            "fcitx5-remote -r"
            # https://wiki.hypr.land/Hypr-Ecosystem/hypridle/#configuration
            "hypridle"
          ])
        ];
      };
      device = {
        name = "wacom-one-by-wacom-s-pen";
        output = "HDMI-A-1";
      };
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };
      window_rule = [
        {
          # Ignore maximize requests from all apps.
          name = "suppress-maximize-events";
          match.class = ".*";
          suppress_event = "maximize";
        }
        {
          # Fix some dragging issues with XWayland
          name = "fix-xwayland-drags";
          match = {
            class = "^$";
            title = "^$";
            xwayland = true;
            float = true;
            fullscreen = false;
            pin = false;
          };
          "no_focus" = true;
        }
      ];

    };
    systemd.enable = true;
  };
}
