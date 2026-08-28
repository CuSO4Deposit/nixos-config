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
            name = "v2raya";
            kind = "systemd-active";
            target = "v2raya.service";
          }
          {
            name = "mm-config-extract";
            kind = "systemd-result";
            target = "mm-config-extract.service";
            timer = "mm-config-extract.timer";
            maxAge = "1h";
          }
        ];
      }
    );
  };
}
