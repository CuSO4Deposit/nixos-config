{ pkgs, ... }:
let
  # awatcher reads a single config.toml from ~/.config/awatcher
  awatcherConfig = (pkgs.formats.toml { }).generate "awatcher-config.toml" {
    server = {
      host = "127.0.0.1";
      port = 5600;
    };
    awatcher = {
      idle-timeout-seconds = 180;
      poll-time-idle-seconds = 4;
      poll-time-window-seconds = 1;
    };
  };
in
{
  # The bundled aw-watcher-window/aw-watcher-afk are X11-only, so use awatcher
  # instead. Do not enable the bundled two alongside it.
  services.activitywatch = {
    enable = true;
    watchers.awatcher = {
      package = pkgs.awatcher;
      executable = "awatcher";
    };
  };

  xdg.configFile."awatcher/config.toml".source = awatcherConfig;
}
