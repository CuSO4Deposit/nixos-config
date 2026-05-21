{ config, pkgs, ... }:
let
  domain = "opencode.internal";
  port = 4096;
in
{
  systemd.services.opencode-web = {
    description = "OpenCode web interface";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "cuso4d";
      WorkingDirectory = "/home/cuso4d";
      Environment = [
        "HOME=/home/cuso4d"
        "NO_PROXY=127.0.0.1,localhost"
      ];
      EnvironmentFile = config.age.secrets."opencode-server-password".path;
      ExecStart = "${pkgs.opencode}/bin/opencode web --hostname 127.0.0.1 --port ${toString port} --cors https://${domain}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  services.nginx.virtualHosts."${domain}" = {
    listen = [
      {
        addr = "127.0.0.1";
        port = 80;
      }
      {
        addr = "10.20.0.2";
        port = 80;
      }
    ];
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}
