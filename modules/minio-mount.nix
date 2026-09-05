{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.nightcord.rclone-minio = {
    # The S3 endpoint only resolves through the office WireGuard tunnel, so a
    # broken wg0 turns this mount into a hung FUSE endpoint that blocks every
    # reader of mountPoint. Set this to false to bring the host up without it.
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to mount the MinIO S3 bucket over rclone.";
    };
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

  config = lib.mkIf config.nightcord.rclone-minio.enable {
    systemd.tmpfiles.rules = [
      "d ${config.nightcord.rclone-minio.mountPoint} 0700 cuso4d users -"
    ];

    age.secrets."rclone.conf".file = ../secrets/rclone.conf.age;

    systemd.services.rclone-minio-mount = {
      description = "Rclone Mount MinIO Service";
      wants = [ "network-online.target" ] ++ config.nightcord.rclone-minio.waitServices;
      after = [ "network-online.target" ] ++ config.nightcord.rclone-minio.waitServices;

      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.fuse}/bin/fusermount -uz ${config.nightcord.rclone-minio.mountPoint} || true'";

        ExecStart = pkgs.writeShellScript "mount-rclone" ''
          ${pkgs.rclone}/bin/rclone mount \
            ${config.nightcord.rclone-minio.remoteName}: \
            ${config.nightcord.rclone-minio.mountPoint} \
            --config ${config.age.secrets."rclone.conf".path} \
            --vfs-cache-mode writes \
            --vfs-cache-max-size 1G \
            --allow-other \
            --umask 0077 \
            --buffer-size 32M
        '';

        ExecStop = "${pkgs.fuse}/bin/fusermount -uz ${config.nightcord.rclone-minio.mountPoint}";

        Restart = "on-failure";
        RestartSec = "15";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
