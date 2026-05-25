{ pkgs, ... }:
{
  systemd.services.v2raya-lan-http-proxy = {
    description = "Expose v2rayA HTTP proxy to proximo only";
    after = [ "v2raya.service" ];
    wants = [ "v2raya.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:20172,bind=192.168.1.102,reuseaddr,fork TCP:127.0.0.1:20172";
      Restart = "always";
      RestartSec = 2;
    };
  };
}
