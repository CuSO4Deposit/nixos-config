{ lib, pkgs, ... }:
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
        text_trim = true;
      };
      background = {
        monitor = "";
        blur_passes = 1;
        brightness = 0.5;
        path = lib.mkDefault "screenshot";
      };
      input-field = {
        monitor = "";
      };
    };
  };
}
