{
  config,
  pkgs,
  ...
}:
let
  name = "racknerd";

  # agenix's HM module defaults `age.secretsDir` to a literal
  # `$XDG_RUNTIME_DIR/...` path: tmpfs, and not usable as a Nix path. Pin it
  # somewhere real under $HOME instead.
  secretsDir = "${config.home.homeDirectory}/.local/share/agenix";

  dumpDir = "/home/cuso4d/backup-dumps";
in
{
  home = {
    username = "CuSO4D";
    homeDirectory = "/home/cuso4d";
    stateVersion = "24.11";
    packages = with pkgs; [
      restic
      rclone
    ];
  };

  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';

  age.secretsDir = secretsDir;
  age.secretsMountPoint = "${secretsDir}.d";
  age.secrets."rclone.conf".file = ../../secrets/rclone.conf.age;
  age.secrets."restic-password".file = ../../secrets/restic-password.age;

  services.restic.enable = true;
  services.restic.backups.${name} = {
    repository = "rclone:webdav:/webdav/restic/${name}";
    rcloneOptions.config = "${secretsDir}/rclone.conf";
    passwordFile = "${secretsDir}/restic-password";
    initialize = true;

    paths = [
      dumpDir

      "/home/cuso4d/snac2/data"

      "/home/cuso4d/substore/data"
      "/home/cuso4d/srvbox_monitor/config"
      "/home/cuso4d/maubot/config.yaml"
      "/home/cuso4d/maubot/plugins"
      "/home/cuso4d/microblog"

      "/home/cuso4d/biliup-rs/biliup/cookies.json"
      "/home/cuso4d/biliup-rs/biliup/config.yaml"
    ];

    # Snapshot live state before each run. Live sqlite files and the miniflux
    # postgres volume (which a user-level restic cannot reach) must not be
    # copied mid-write.
    backupPrepareCommand = ''
      set -euo pipefail
      mkdir -p ${dumpDir}

      /usr/bin/docker exec miniflux-db-1 pg_dump -U miniflux miniflux \
        | /usr/bin/gzip > ${dumpDir}/miniflux.sql.gz.tmp
      mv ${dumpDir}/miniflux.sql.gz.tmp ${dumpDir}/miniflux.sql.gz

      /usr/bin/sqlite3 /home/cuso4d/linkding/data/db.sqlite3        ".backup ${dumpDir}/linkding.db"
      /usr/bin/sqlite3 /home/cuso4d/linkding/data/tasks.sqlite3     ".backup ${dumpDir}/linkding-tasks.db"
      /usr/bin/sqlite3 /home/cuso4d/wakapi/wakapi-db-data/wakapi.db ".backup ${dumpDir}/wakapi.db"
      /usr/bin/sqlite3 /home/cuso4d/maloja/mljdata/malojadb.sqlite  ".backup ${dumpDir}/maloja.db"
      /usr/bin/sqlite3 /home/cuso4d/maloja/mljdata/auth/auth.sqlite ".backup ${dumpDir}/maloja-auth.db"
      /usr/bin/sqlite3 /home/cuso4d/maubot/maubot.db                ".backup ${dumpDir}/maubot.db"
    '';

    pruneOpts = [
      "--keep-daily"
      "7"
      "--keep-weekly"
      "4"
      "--keep-monthly"
      "12"
    ];
    extraBackupArgs = [
      "--compression"
      "max"
      "--tag"
      name
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  systemd.user.services."restic-backups-${name}" = {
    Unit.Wants = [ "agenix.service" ];
    Unit.After = [ "agenix.service" ];
  };
}
