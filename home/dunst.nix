{ config, lib, pkgs, ... }:
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        background = "#24283b";
        foreground = "#cocaf5";
        font = "UbuntuMono Nerd Font Propo 16";
        height = "(0, 300)";
        origin = "top-center";
        # transparency = 10; # X11 only
        width = 300;
      };
    };
    waylandDisplay = "true";
  };
}
