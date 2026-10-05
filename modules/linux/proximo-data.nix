{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.nightcord.rclone-proximo-data = {
    remoteName = lib.mkOption {
      type = lib.types.str;
      default = "proximo-data";
      description = "remote name in rclone.conf";
    };
    remotePath = lib.mkOption {
      type = lib.types.str;
      default = "/data";
      description = "remote path to mount from proximo";
    };
    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/data";
    };
    waitServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "network-online.target" ];
    };
  };

  config = {
    systemd.tmpfiles.rules = [
      "d ${config.nightcord.rclone-proximo-data.mountPoint} 0700 cuso4d users -"
    ];

    age.secrets."rclone.conf".file = ../../secrets/rclone.conf.age;

    systemd.services.rclone-proximo-data-mount = {
      description = "Rclone Mount Proximo /data Service";
      wants = [ "network-online.target" ] ++ config.nightcord.rclone-proximo-data.waitServices;
      after = [ "network-online.target" ] ++ config.nightcord.rclone-proximo-data.waitServices;

      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.fuse}/bin/fusermount -uz ${config.nightcord.rclone-proximo-data.mountPoint} || true'";

        ExecStart = pkgs.writeShellScript "mount-rclone-proximo-data" ''
          ${pkgs.rclone}/bin/rclone mount \
            ${config.nightcord.rclone-proximo-data.remoteName}:${config.nightcord.rclone-proximo-data.remotePath} \
            ${config.nightcord.rclone-proximo-data.mountPoint} \
            --config ${config.age.secrets."rclone.conf".path} \
            --vfs-cache-mode writes \
            --vfs-cache-max-size 1G \
            --allow-other \
            --uid 1000 \
            --gid 100 \
            --umask 0077 \
            --buffer-size 32M
        '';

        ExecStop = "${pkgs.fuse}/bin/fusermount -uz ${config.nightcord.rclone-proximo-data.mountPoint}";

        Restart = "on-failure";
        RestartSec = "15";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
