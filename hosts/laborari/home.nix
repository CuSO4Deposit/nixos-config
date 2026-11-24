{ lib, pkgs, ... }:
{
  home.packages = [
    pkgs.herdr
    pkgs.herdr-desktop
  ];

  programs.hyprlock.settings = {
    background = {
      brightness = lib.mkForce 0.5;
    };
  };
  programs.waybar.settings.mainBar = {
    network.interface = lib.mkForce "wlp3s0";
  };
}
