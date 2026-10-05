{ pkgs, ... }:
# Firefox history as an archive source. See archive.nix for what the surrounding
# machinery does; this file is only the part that knows about Firefox.
#
# places.sqlite cannot be read in place. Firefox opens it with
# `PRAGMA locking_mode=exclusive`, so while the browser runs even a read-only connection
# fails with `database is locked` — `VACUUM INTO` and the online backup API both refuse
# (verified on lexikos with Firefox up).
#
# Copying the file and its `-wal` sidecar and reading the copy does work, for the same
# reason a crash is survivable: a WAL database plus its log recovers to the last committed
# transaction, and sqlite replays the log when it opens the copy. Copying only
# places.sqlite also "works", and that is the trap this recipe exists to avoid — it
# silently drops whatever is still in the log (three visits when measured, though the log
# had 4MB of room to hold far more) and reports no error at all.
#
# Worth snapshotting because places expires old visits once the database passes its size
# budget, so an old snapshot is the only record of what Firefox has since discarded. The
# live database on lexikos reaches back only to 2025-10.
{
  nightcord.archive.sources.firefox = {
    # `places`, the app's own name for this database, rather than `firefox`: the file is
    # one of several things Firefox stores, and a later cookies or forms snapshot should
    # not have to rename this one to stay distinguishable.
    stem = "places";

    # `.bin` carries the sqlite3 CLI; the default output is the library only.
    packages = [ pkgs.sqlite.bin ];

    extension = "sqlite";

    produce = ''
      # home/firefox.nix names the profile after the username (`profiles.<username>` in
      # home-manager), so this path is the same on every host.
      profile=/home/cuso4d/.mozilla/firefox/cuso4d
      db="$profile/places.sqlite"
      [ -f "$db" ] || { echo "no places.sqlite at $db" >&2; exit 1; }

      # Main file first, log second: a visit committed between the two copies then lands
      # in the log rather than being lost, which is recoverable. A missing `-wal` is not
      # an error — Firefox checkpoints and removes it when idle — but a present one that
      # we skipped would silently cost data, so it is copied whenever it exists.
      cp "$db" "$work/live.sqlite"
      if [ -f "$db-wal" ]; then
        cp "$db-wal" "$work/live.sqlite-wal"
      fi

      # Replays the log and rewrites the database compactly, leaving no sidecar. Doing it
      # here rather than shipping the pair keeps the archive one file per snapshot, which
      # is what lets CPI treat a snapshot as a unit.
      sqlite3 "$work/live.sqlite" "VACUUM INTO '$out'"
    '';

    verify = ''
      # A truncated copy would otherwise be indistinguishable from a real one until
      # something tried to read it, long after the live database had moved on.
      check=$(sqlite3 "$out" "pragma integrity_check;")
      if [ "$check" != "ok" ]; then
        echo "integrity check failed: $check" >&2
        exit 1
      fi

      # No visits means the copy went wrong, not that nothing was browsed: an empty
      # history would still have the table.
      visits=$(sqlite3 "$out" "select count(*) from moz_historyvisits;")
      if [ "$visits" -eq 0 ]; then
        echo "snapshot has no visits; refusing to archive it" >&2
        exit 1
      fi
      echo "$visits visits" >&2
    '';
  };
}
