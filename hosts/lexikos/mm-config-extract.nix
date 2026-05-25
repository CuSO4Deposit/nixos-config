{ pkgs, ... }:
{
  systemd.timers."mm-config-extract" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "10min";
      Unit = "mm-config-extract.service";
    };
  };
  systemd.services."mm-config-extract" = {
    path = with pkgs; [
      bash
      gawk
      coreutils
      gnugrep
    ];
    script = ''
      bash /home/cuso4d/source/mm-config/scripts/extract-bestbefore.sh
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "cuso4d";
    };
  };
}
