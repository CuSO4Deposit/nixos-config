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
          "${config.home.homeDirectory}/Pictures/Wallpapers/果ての望月_kirico_sk.jpg"
          "${config.home.homeDirectory}/Pictures/Wallpapers/ヒトリノ灯リ_kirico_sk.jpg"
        ];
      in
      {
        preload = wallpapers;
        wallpaper = builtins.map (x: ", " + x) wallpapers;
      };
  };
}
