{ pkgs, ... }:
{
  systemd.timers."cannot-sleep-m9" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "15:00:00";
      Unit = "cannot-sleep-m9.service";
    };
  };
  systemd.services."cannot-sleep-m9" = {
    # https://web.archive.org/web/20250805104854/https://forum.endeavouros.com/t/notify-when-network-is-up/69894/4
    script = ''
      systemd-run --user --machine=cuso4d@.host --user ${pkgs.libnotify}/bin/notify-send -t 10000 "This is ena..." "You cannot go to sleep! m9"
    '';
  };
}
