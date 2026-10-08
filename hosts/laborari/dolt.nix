{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.dolt ];

  systemd.tmpfiles.rules = [
    "d /home/cuso4d/.local/share/cuso4d 0700 cuso4d users -"
  ];
  nightcord.restic-backup.paths = [ "/home/cuso4d/.local/share/cuso4d" ];
}
