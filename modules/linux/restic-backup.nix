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
  imports = [
    ./notify.nix
    ./rclone-credentials.nix
    ./restic-restore-test.nix
  ];

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

    backupPrepareCommand = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Shell fragment run before each backup, before restic reads `paths`. Use it to
        snapshot live state (e.g. a `mariadb-dump`) into a directory that is itself in
        `paths`, so restic never reads a database mid-write.
      '';
    };

    backupCleanupCommand = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Shell fragment run after the backup, even when it failed. Use it to undo whatever
        `backupPrepareCommand` changed (e.g. re-enable saving on a Minecraft server).
      '';
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

    runCheck = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run `restic check` after each backup.";
    };

    checkOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--read-data-subset=5%" ];
      description = ''
        Options for `restic check`, run after each backup. The default reads a random 5%
        of pack data per run, so the repository is fully verified over time. Set to `[ ]`
        for a metadata-only check if the remote is slow.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nightcord.notify.enable = lib.mkDefault true;

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
        runCheck
        checkOpts
        ;
      extraBackupArgs = [
        "--compression"
        "max"
        "--tag"
        cfg.name
      ];
    }
    // lib.optionalAttrs (cfg.backupPrepareCommand != "") {
      inherit (cfg) backupPrepareCommand;
    }
    // lib.optionalAttrs (cfg.backupCleanupCommand != "") {
      inherit (cfg) backupCleanupCommand;
    };

    # restic's rclone backend execs `rclone`, but the generated unit only has ssh on
    # PATH. `path` is a list option, so this appends to it rather than replacing it.
    systemd.services."restic-backups-${cfg.name}" = {
      path = [ pkgs.rclone ];
      onFailure = lib.optional config.nightcord.notify.enable "nightcord-ntfy-alert@%N.service";
    };

    age.secrets."restic-password".file = ../../secrets/restic-password.age;
  };
}
