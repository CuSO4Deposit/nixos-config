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

    targets = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.str;
              description = ''
                Destination identifier. The `webdav` target keeps the historical unit name
                (`restic-backups-<name>`), so existing probes keep working; every other
                target is suffixed (`restic-backups-<name>-<id>`).
              '';
            };
            repository = lib.mkOption {
              type = lib.types.str;
              description = "restic repository URL, e.g. `rclone:rustfs:/bucket/restic/<name>`.";
            };
            rcloneConfigFile = lib.mkOption {
              type = lib.types.str;
              description = "Path to the rclone config for this repository.";
            };
            passwordFile = lib.mkOption {
              type = lib.types.str;
              description = "Path to the restic repository password.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Backup destinations. Empty means the single shared WebDAV remote, which is the
        historical behaviour. Add entries once a second site (e.g. RustFS) is online; the
        same `paths` fan out to every target.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    let
      webdavTarget = {
        id = "webdav";
        repository = "rclone:webdav:/webdav/restic/${cfg.name}";
        rcloneConfigFile = config.age.secrets."rclone.conf".path;
        passwordFile = config.age.secrets."restic-password".path;
      };

      targets = if cfg.targets == [ ] then [ webdavTarget ] else cfg.targets;

      unitName = t: if t.id == "webdav" then cfg.name else "${cfg.name}-${t.id}";
    in
    {
      services.restic.backups = lib.listToAttrs (
        map (t: {
          name = unitName t;
          value = {
            repository = t.repository;
            rcloneConfigFile = t.rcloneConfigFile;
            passwordFile = t.passwordFile;
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
          }
          // lib.optionalAttrs (cfg.backupPrepareCommand != "") {
            inherit (cfg) backupPrepareCommand;
          }
          // lib.optionalAttrs (cfg.backupCleanupCommand != "") {
            inherit (cfg) backupCleanupCommand;
          };
        }) targets
      );

      # restic's rclone backend execs `rclone`, but the generated unit only has ssh on
      # PATH. `path` is a list option, so this appends to it rather than replacing it.
      systemd.services = lib.genAttrs (map (t: "restic-backups-${unitName t}") targets) (_: {
        path = [ pkgs.rclone ];
      });

      age.secrets."restic-password".file = ../../secrets/restic-password.age;
    }
  );
}
