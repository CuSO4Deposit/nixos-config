{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nightcord.mysql-backup;
in
{
  options.nightcord.mysql-backup = {
    dumpDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/restic-dumps";
      description = ''
        Directory the dump is written to. Add it to `nightcord.restic-backup.paths` so
        restic picks it up.
      '';
    };

    backupPrepareCommand = lib.mkOption {
      type = lib.types.lines;
      description = ''
        Dump every database to `dumpDir`. Compose it into the host's
        `nightcord.restic-backup.backupPrepareCommand`.
      '';
    };
  };

  config = {
    nightcord.mysql-backup.backupPrepareCommand = ''
      # Plain text, not gzip: restic compresses and content-dedups itself, and gzip
      # reshuffles after any change. --skip-dump-date keeps unchanged runs byte-identical.
      ${pkgs.coreutils}/bin/mkdir -p ${cfg.dumpDir} || exit 1
      if ! ${config.services.mysql.package}/bin/mariadb-dump \
        --all-databases --single-transaction --quick --skip-lock-tables --skip-dump-date \
        > ${cfg.dumpDir}/mysql-all.sql.tmp; then
        ${pkgs.coreutils}/bin/rm -f ${cfg.dumpDir}/mysql-all.sql.tmp
        echo "mariadb-dump failed" >&2
        exit 1
      fi
      ${pkgs.coreutils}/bin/mv ${cfg.dumpDir}/mysql-all.sql.tmp ${cfg.dumpDir}/mysql-all.sql || exit 1
    '';

    systemd.tmpfiles.rules = [ "d ${cfg.dumpDir} 0700 root root -" ];
  };
}
