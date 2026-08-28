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
            name = "minecraft";
            kind = "systemd-active";
            target = "minecraft-server.service";
          }
          {
            name = "piwigo";
            kind = "systemd-active";
            target = "docker-piwigo.service";
          }
          {
            name = "observable";
            kind = "systemd-result";
            target = "observable-cuso4d.service";
            timer = "observable-cuso4d.timer";
            maxAge = "26h";
          }
          {
            name = "ghorg";
            kind = "systemd-result";
            target = "ghorg.service";
            timer = "ghorg.timer";
            maxAge = "26h";
          }
          {
            name = "syncthing";
            kind = "systemd-active";
            target = "syncthing.service";
          }
          {
            name = "nginx";
            kind = "systemd-active";
            target = "nginx.service";
          }
        ];
      }
    );
  };
}
