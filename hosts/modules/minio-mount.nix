{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.rclone-minio = {
    remoteName = lib.mkOption {
      type = lib.types.str;
      default = "minio";
      description = "remote name in rclone.conf";
    };
    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/minio";
    };
    waitServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "network-online.target" ];
    };
  };

  config = {
    systemd.tmpfiles.rules = [
      "d ${config.rclone-minio.mountPoint} 0700 cuso4d users -"
    ];

    age.secrets."rclone.conf".file = ../../secrets/rclone.conf.age;

    systemd.services.rclone-minio-mount = {
      description = "Rclone Mount MinIO Service";
      wants = [ "network-online.target" ] ++ config.rclone-minio.waitServices;
      after = [ "network-online.target" ] ++ config.rclone-minio.waitServices;

      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.fuse}/bin/fusermount -uz ${config.rclone-minio.mountPoint} || true'";

        ExecStart = pkgs.writeShellScript "mount-rclone" ''
          ${pkgs.rclone}/bin/rclone mount \
            ${config.rclone-minio.remoteName}: \
            ${config.rclone-minio.mountPoint} \
            --config ${config.age.secrets."rclone.conf".path} \
            --vfs-cache-mode writes \
            --vfs-cache-max-size 1G \
            --allow-other \
            --umask 0077 \
            --buffer-size 32M
        '';

        ExecStop = "${pkgs.fuse}/bin/fusermount -uz ${config.rclone-minio.mountPoint}";

        Restart = "on-failure";
        RestartSec = "15";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
