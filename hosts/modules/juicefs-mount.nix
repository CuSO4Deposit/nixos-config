{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.juicefs-mount = {
    dbHost = lib.mkOption {
      type = lib.types.str;
      default = "10.20.0.1";
    };
    waitServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "network-online.target" ];
    };
  };

  config = {
    system.activationScripts.makeJfsMountPoint = ''
      mkdir -p /mnt/jfs
    '';

    systemd.tmpfiles.rules = [
      "d /mnt/jfs 0700 cuso4d users -"
    ];

    age.secrets.juicefs-password-env.file = ../../secrets/juicefs-password-env.age;

    systemd.services.juicefs-mount = {
      description = "JuiceFS Mount Service";
      wants = [ "network-online.target" ] ++ config.juicefs-mount.waitServices;
      after = [ "network-online.target" ] ++ config.juicefs-mount.waitServices;

      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.fuse}/bin/fusermount -uz /mnt/jfs || true'";
        ExecStart = pkgs.writeShellScript "mount-juicefs" ''
          . ${config.age.secrets.juicefs-password-env.path}

          ${pkgs.juicefs}/bin/juicefs mount \
            "mysql://juicefs:$JUICEFS_PASS@tcp(${config.juicefs-mount.dbHost}:3306)/juicefs" \
            /mnt/jfs
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -uz /mnt/jfs";
        Restart = "on-failure";
        RestartSec = "10";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
