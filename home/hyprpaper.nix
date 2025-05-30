{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.hyprpaper = {
    enable = true;
    settings =
      let
        wallpapers = [
          "${config.home.homeDirectory}/Pictures/Wallpapers/果ての望月_kirico_sk_202505301047.jpg"
        ];
      in
      {
        preload = wallpapers;
        wallpaper = builtins.map (x: ", " + x) wallpapers;
      };
  };
}
