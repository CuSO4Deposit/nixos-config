{
  inputs,
  pkgs,
  ...
}:
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
            groups = {
              vercel-githubio = [
                "API"
                "API Next"
                "AI Chat"
                "Blog"
                "Status"
              ];
              racknerd = [
                "Bookmark"
                "RSS"
                "RSSHub"
                "Wakapi"
                "ef-3-e69-f0"
              ];
            };
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
  };
}
