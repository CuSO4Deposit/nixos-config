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
    http = {
      enable = lib.mkEnableOption "an rclone HTTP server for one bucket of the remote";
      addr = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:8089";
        description = "listen address (--addr), keep it on loopback and front it with a reverse proxy";
      };
      remotePath = lib.mkOption {
        type = lib.types.str;
        description = "bucket or prefix to serve";
      };
    };
  };

  config = lib.mkIf config.nightcord.rclone-minio.enable {
    systemd.tmpfiles.rules = [
      "d ${config.nightcord.rclone-minio.mountPoint} 0700 cuso4d users -"
    ];

    age.secrets."rclone.conf".file = ../../secrets/rclone.conf.age;

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

    systemd.services.rclone-minio-http = lib.mkIf config.nightcord.rclone-minio.http.enable {
      description = "Rclone HTTP file server for MinIO";
      wants = [ "network-online.target" ] ++ config.nightcord.rclone-minio.waitServices;
      after = [ "network-online.target" ] ++ config.nightcord.rclone-minio.waitServices;
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "serve-rclone-http" ''
          ${pkgs.rclone}/bin/rclone serve http \
            ${config.nightcord.rclone-minio.remoteName}:${config.nightcord.rclone-minio.http.remotePath} \
            --config ${config.age.secrets."rclone.conf".path} \
            --addr ${config.nightcord.rclone-minio.http.addr} \
            --read-only
        '';
        Restart = "on-failure";
        RestartSec = "15";
      };
    };
  };
}
