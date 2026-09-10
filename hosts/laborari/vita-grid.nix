{
  inputs,
  pkgs,
  ...
}:
let
  sensorIO = {
    sda = 21;
    scl = 22;
    offLux = 50;
  };
  boardBase = {
    version = 1;
    poll.interval = 5;
    led = {
      pin = 4;
      count = 64;
      serpentine = true;
    };
    brightness.level = 2;
    colors = {
      ok = [
        0
        255
        0
      ];
      warn = [
        255
        255
        0
      ];
      error = [
        255
        0
        0
      ];
      absent = [
        255
        0
        0
      ];
    };
    blink.intervalMs = 500;
    mapping = [
      {
        name = "API";
        index = 0;
      }
      {
        name = "Blog";
        index = 1;
      }
      {
        name = "Status";
        index = 2;
      }
      {
        name = "Bookmark";
        index = 3;
      }
      {
        name = "RSS";
        index = 4;
      }
      {
        name = "RSSHub";
        index = 5;
      }
      {
        name = "Wakapi";
        index = 6;
      }
      {
        name = "ef-3-e69-f0";
        index = 7;
      }
      {
        name = "laborari";
        index = 8;
      }
      {
        name = "laborari:duplicity";
        index = 9;
      }
      {
        name = "laborari:nix-auto-build";
        index = 10;
      }
      {
        name = "laborari:terraria";
        index = 11;
      }
      {
        name = "laborari:terraria2";
        index = 12;
      }
      {
        name = "laborari:syncthing";
        index = 13;
      }
      {
        name = "laborari:rclone-minio-mount";
        index = 14;
      }
      {
        name = "lexikos:duplicity";
        index = 16;
      }
      {
        name = "lexikos:v2raya";
        index = 17;
      }
      {
        name = "lexikos:mm-config-extract";
        index = 18;
      }
      {
        name = "proximo:duplicity";
        index = 24;
      }
      {
        name = "proximo:minecraft";
        index = 25;
      }
      {
        name = "proximo:minecraft2";
        index = 26;
      }
      {
        name = "proximo:piwigo";
        index = 27;
      }
      {
        name = "proximo:observable";
        index = 28;
      }
      {
        name = "proximo:ghorg";
        index = 29;
      }
      {
        name = "proximo:syncthing";
        index = 30;
      }
      {
        name = "proximo:nginx";
        index = 31;
      }
    ];
  };
  mkBoard =
    hasSensor:
    boardBase
    // {
      bh1750 = sensorIO // {
        enabled = hasSensor;
      };
    };
in
{
  services.vitaGrid.package = inputs.vita-grid.packages.${pkgs.stdenv.hostPlatform.system}.vita-grid;
  services.vitaGrid.statusd = {
    enable = true;
    configFile = pkgs.writeText "vita-grid-statusd.json" (
      builtins.toJSON {
        listen = ":8081";
        probes = [
          {
            name = "duplicity";
            kind = "systemd-result";
            target = "duplicity.service";
            timer = "duplicity.timer";
            maxAge = "26h";
          }
          {
            name = "nix-auto-build";
            kind = "systemd-result";
            target = "nix-auto-build.service";
            timer = "nix-auto-build.timer";
            maxAge = "26h";
          }
          {
            name = "terraria";
            kind = "systemd-active";
            target = "terraria.service";
          }
          {
            name = "terraria2";
            kind = "systemd-active";
            target = "terraria2.service";
          }
          {
            name = "syncthing";
            kind = "systemd-active";
            target = "syncthing.service";
          }
          {
            name = "rclone-minio-mount";
            kind = "systemd-active";
            target = "rclone-minio-mount.service";
          }
        ];
      }
    );
  };
  services.vitaGrid.aggregator = {
    enable = true;
    proxy = "http://127.0.0.1:20172";
    configFile = pkgs.writeText "vita-grid-aggregator.json" (
      builtins.toJSON {
        listen = ":8080";
        refresh = 300;
        sources = [
          {
            type = "upptime";
            repo = "CuSO4Deposit/literate-journey";
            branch = "master";
            refresh = 3600;
            sites = [
              {
                name = "API";
                file = "api";
              }
              {
                name = "API Next";
                file = "api-next";
              }
              {
                name = "AI Chat";
                file = "ai-chat";
              }
              {
                name = "Blog";
                file = "blog";
              }
              {
                name = "Status";
                file = "status";
              }
              {
                name = "Bookmark";
                file = "bookmark";
              }
              {
                name = "RSS";
                file = "rss";
              }
              {
                name = "RSSHub";
                file = "rss-hub";
              }
              {
                name = "Wakapi";
                file = "wakapi";
              }
              { file = "ef-3-e69-f0"; }
            ];
          }
          {
            type = "statusd";
            url = "http://127.0.0.1:8081";
            host = "laborari";
            refresh = 10;
          }
          {
            type = "statusd";
            url = "http://10.20.0.3:8081";
            host = "lexikos";
            refresh = 10;
          }
          {
            type = "statusd";
            url = "http://10.20.0.1:8081";
            host = "proximo";
            refresh = 10;
          }
        ];
      }
    );
    boards = {
      laborari = mkBoard false;
      lexikos = mkBoard true;
    };
  };
}
