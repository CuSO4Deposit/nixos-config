{
  config,
  lib,
  pkgs,
  ...
}:
let
  backupCfg = config.nightcord.restic-backup;
  cfg = config.nightcord.restic-restore-test;

  backup = config.services.restic.backups.${backupCfg.name};
in
{
  imports = [ ./notify.nix ];

  options.nightcord.restic-restore-test.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Run a monthly restore drill for the restic repository.";
  };

  config = lib.mkIf (backupCfg.enable && cfg.enable) {
    systemd.services."restic-restore-test-${backupCfg.name}" = {
      description = "Restore one file from the latest ${backupCfg.name} snapshot";
      onFailure = lib.optional config.nightcord.notify.enable "nightcord-ntfy-alert@%N.service";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment = {
        RESTIC_REPOSITORY = backup.repository;
        RESTIC_PASSWORD_FILE = backup.passwordFile;
        RCLONE_CONFIG = backup.rcloneConfigFile;
        RESTIC_CACHE_DIR = "/var/cache/restic-restore-test-${backupCfg.name}";
      };
      path = [
        pkgs.restic
        pkgs.rclone
        pkgs.jq
        pkgs.coreutils
      ];
      serviceConfig.Type = "oneshot";
      # `restic check` verifies pack data, but only a real restore exercises the
      # read path end to end. Dump one file from the newest snapshot to /dev/null.
      script = ''
        set -eu
        listing=$(mktemp)
        trap 'rm -f "$listing"' EXIT
        restic ls latest --json > "$listing"
        file=$(jq -r 'select(.struct_type == "node" and .type == "file") | .path' "$listing" | head -n1)
        [ -n "$file" ] || { echo "no file found in the latest snapshot" >&2; exit 1; }
        restic dump latest "$file" > /dev/null
        echo "restored $file"
      '';
    };

    systemd.timers."restic-restore-test-${backupCfg.name}" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "monthly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
