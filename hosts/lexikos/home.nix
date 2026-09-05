{ lib, ... }:
{
  wayland.windowManager.hyprland.settings = {
    bind = lib.mkAfter [
      {
        _args = [
          "XF86MonBrightnessUp"
          (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("brightnessctl set 5%+ -d nvidia_0")'')
          { repeating = true; }
        ];
      }
      {
        _args = [
          "XF86MonBrightnessDown"
          (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("brightnessctl set 5%- -d nvidia_0")'')
          { repeating = true; }
        ];
      }
    ];
    monitor = lib.mkForce [
      {
        output = "eDP-1";
        mode = "preferred";
        position = "0x0";
        scale = 1;
      }
      {
        output = "HDMI-A-1";
        mode = "preferred";
        position = "1920x0";
        scale = 1;
      }
    ];
    workspace_rule = lib.mkAfter [
      {
        workspace = "101";
        monitor = "eDP-1";
        default = true;
        persistent = true;
      }
    ];
    window_rule = lib.mkAfter [
      {
        # MagicMirror fullscreen on eDP-1 (workspace 101 is default on eDP-1)
        name = "magicmirror-fullscreen";
        match = {
          class = "Electron";
          title = "MagicMirror.*";
        };
        fullscreen = 1;
      }
    ];
  };
  programs.waybar.settings.mainBar = {
    network.interface = lib.mkForce "wlp4s0";
  };
}
