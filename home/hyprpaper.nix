{
  config,
  osConfig,
  ...
}:
{
  services.hyprpaper = {
    enable = true;
    settings =
      let
        hostname = osConfig.networking.hostName;
        wallpaperPath =
          if hostname == "nightcord-laborari" then
            "${config.home.homeDirectory}/Pictures/Wallpapers/ヒトリノ灯リ_kirico_sk.jpg"
          else if hostname == "nightcord-dynamica" then
            "${config.home.homeDirectory}/Pictures/Wallpapers/果ての望月_kirico_sk.jpg"
          else if hostname == "nightcord-lexikos" then
            "${config.home.homeDirectory}/Pictures/Wallpapers/多分やさしい夜_kirico_sk.jpg"
          else
            "";
      in
      {
        wallpaper = {
          monitor = "";
          path = wallpaperPath;
        };
        splash = false;
      };
  };
}
