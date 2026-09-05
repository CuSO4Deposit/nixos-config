{
  pkgs,
  inputs,
  ...
}:
let
  domain = "haitun.internal";
  port = 8110;
  psi-agent = inputs.psi-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  systemd.services.psi-agent = {
    description = "Haitun (psi-agent) gateway server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "cuso4d";
      WorkingDirectory = "/home/cuso4d/source/psi-agent";
      Environment = [
        "HOME=/home/cuso4d"
        "NO_PROXY=127.0.0.1,localhost"
      ];
      ExecStart = "${psi-agent}/bin/psi-agent gateway --gateway desktop --listen http://127.0.0.1:${toString port}";
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
    };
  };
}
