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

  notify = pkgs.writeShellApplication {
    name = "nightcord-ntfy-send";
    runtimeInputs = [
      pkgs.curl
      pkgs.coreutils
    ];
    text = ''
      # Usage: nightcord-ntfy-send <title> [body] [priority] [tags]
      title=''${1:?usage: nightcord-ntfy-send <title> [body] [priority] [tags]}
      body=''${2:-}
      priority=''${3:-default}
      tags=''${4:-}

      topic=$(cat ${secretsDir}/ntfy-topic)
      exec curl -fsS \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -H "Tags: $tags" \
        -d "$body" \
        "https://ntfy.sh/$topic"
    '';
  };

  ntfyAlert = pkgs.writeShellScript "nightcord-ntfy-alert" ''
    set -u
    unit="''${1:?usage: nightcord-ntfy-alert <unit>}.service"
    host=$(${pkgs.coreutils}/bin/uname -n)
    status=$(${pkgs.systemd}/bin/systemctl --user show --value -p Result -p ExecMainStatus "$unit" | ${pkgs.coreutils}/bin/paste -sd' ' -)
    log=$(${pkgs.systemd}/bin/journalctl --user -u "$unit" -n 5 --no-pager -o cat 2>/dev/null || true)
    body=$(${pkgs.coreutils}/bin/printf 'status: %s\n%s' "$status" "$log")
    exec ${notify}/bin/nightcord-ntfy-send "FAILED: $host $unit" "$body" high rotating_light
  '';
in
{
  home = {
    username = "CuSO4D";
    homeDirectory = "/home/cuso4d";
    stateVersion = "24.11";
    packages = with pkgs; [
      restic
      rclone
      notify
    ];
  };

  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';

  age.secretsDir = secretsDir;
  age.secretsMountPoint = "${secretsDir}.d";
  age.secrets."rclone.conf".file = ../../secrets/rclone.conf.age;
  age.secrets."restic-password".file = ../../secrets/restic-password.age;
  age.secrets."ntfy-topic".file = ../../secrets/ntfy-topic.age;

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
    Unit.OnFailure = [ "nightcord-ntfy-alert@%N.service" ];
  };

  systemd.user.services."nightcord-ntfy-alert@" = {
    Unit.Description = "Send an ntfy notification for failed unit %i";
    Service = {
      Type = "oneshot";
      ExecStart = "${ntfyAlert} %i";
    };
  };
}
