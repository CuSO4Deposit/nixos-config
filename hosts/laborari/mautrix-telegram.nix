{ config, pkgs, ... }:
let
  stateDir = "/var/lib/mautrix-telegram";
in
{
  age.secrets."mautrix-telegram-nginx.conf" = {
    file = ../../secrets/mautrix-telegram-nginx.conf.age;
    owner = "nginx";
    group = "nginx";
  };

  environment.etc."mautrix-telegram/docker-compose.yml".text = ''
    services:
      mautrix-telegram:
        image: dock.mau.dev/mautrix/telegram:v26.11
        container_name: mautrix-telegram
        restart: unless-stopped
        network_mode: host
        environment:
          UID: "1000"
          GID: "100"
        env_file:
          - ${stateDir}/bridge.env
        volumes:
          - ${stateDir}/data:/data
  '';

  systemd.services.mautrix-telegram = {
    description = "Mautrix Telegram bridge";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "docker.service"
      "network-online.target"
    ];
    after = [
      "docker.service"
      "network-online.target"
    ];
    unitConfig.ConditionPathExists = "${stateDir}/synapse-ready";
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "mautrix-telegram";
      StateDirectoryMode = "0750";
      WorkingDirectory = "/etc/mautrix-telegram";
      ExecStart = "${pkgs.docker}/bin/docker compose up -d --remove-orphans";
      ExecStop = "${pkgs.docker}/bin/docker compose down";
    };
  };

  services.nginx.appendHttpConfig = ''
    include ${config.age.secrets."mautrix-telegram-nginx.conf".path};
  '';
}
