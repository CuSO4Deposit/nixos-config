{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nightcord.restic-backup;
in
{
  imports = [ ./rclone-credentials.nix ];

  options.nightcord.restic-backup = {
    enable = lib.mkEnableOption "restic backups to the shared WebDAV remote";

    name = lib.mkOption {
      type = lib.types.str;
      default = lib.removePrefix "nightcord-" config.networking.hostName;
      defaultText = lib.literalExpression ''lib.removePrefix "nightcord-" config.networking.hostName'';
      description = "Repository subdirectory under restic/ and the backup tag.";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Absolute paths to back up.";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "restic exclude patterns.";
    };

    pruneOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--keep-daily"
        "7"
        "--keep-weekly"
        "4"
        "--keep-monthly"
        "12"
      ];
      description = "Retention arguments passed to `restic forget --prune`.";
    };

    timerConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
      description = "systemd timer configuration for the backup.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The rclone.conf credential is declared by modules/rclone-credentials.nix,
    # imported above; this module does not depend on the FUSE mount existing.
    services.restic.backups.${cfg.name} = {
      repository = "rclone:webdav:/webdav/restic/${cfg.name}";
      rcloneConfigFile = config.age.secrets."rclone.conf".path;
      passwordFile = config.age.secrets."restic-password".path;
      initialize = true;
      inherit (cfg)
        paths
        exclude
        pruneOpts
        timerConfig
        ;
      extraBackupArgs = [
        "--compression"
        "max"
        "--tag"
        cfg.name
      ];
    };

    # The restic module only puts ssh on PATH; the rclone backend shells out to
    # an `rclone` binary, so make it visible to the unit.
    systemd.services."restic-backups-${cfg.name}".path = [ pkgs.rclone ];

    age.secrets."restic-password".file = ../secrets/restic-password.age;
  };
}
