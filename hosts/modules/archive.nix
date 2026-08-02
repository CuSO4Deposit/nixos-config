{
  config,
  lib,
  pkgs,
  ...
}:
# Periodic immutable snapshots of live local state, delivered to proximo by syncthing
# and read there by CPI.
#
# The phone's exports need none of this: its apps write a finished, timestamped zip and
# syncthing carries it. On a PC nothing produces such a file, so each source needs three
# things done to it — brought to a consistent state, named so the archive can be ordered,
# and moved into the outbox only once whole. This module owns the second and third for
# every source, and each source supplies only the first.
#
# That split is the point. The filename is a contract with CPI, which parses the host and
# timestamp out of it to accumulate across machines; the atomic move is what keeps a
# half-written file from propagating over a send-only sync. Both must be identical for
# every source, and a second hand-written timer would drift from the first.
let
  cfg = config.nightcord.archive;

  hostName = config.networking.hostName;

  sourceType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        stem = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = ''
            Leading component of the archived filename, before the host. Defaults to the
            source name; set it when the app's own word for the data differs, as Firefox's
            `places` does from `firefox`.
          '';
        };

        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Extra tools `produce` and `verify` need on PATH.";
        };

        produce = lib.mkOption {
          type = lib.types.lines;
          description = ''
            Shell fragment that writes one file to `$out`, a path in a scratch directory
            `$work` that is removed afterwards. Must exit non-zero if it cannot produce a
            consistent artifact — this is the only place that knows what consistency means
            for its source.
          '';
        };

        verify = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = ''
            Shell fragment checking the artifact at `$out`, exiting non-zero to reject it.
            Runs before compression. Optional, but a source whose failure mode is a
            plausible-looking short file should have one: the generic emptiness check
            below cannot tell a truncated database from a small one.
          '';
        };

        extension = lib.mkOption {
          type = lib.types.str;
          description = "Extension describing the artifact, e.g. `sqlite` or `txt`.";
        };

        compress = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to xz the artifact, appending `.xz`. Leave off for something already
            compressed, such as a git bundle, where it would only cost time.
          '';
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "cuso4d";
          description = "User to run as. Usually the one whose home holds the data.";
        };

        schedule = lib.mkOption {
          type = lib.types.str;
          default = "daily";
          description = "systemd OnCalendar expression.";
        };
      };
    }
  );

  outboxOf = source: "${cfg.outboxRoot}/${source}";

  runner =
    name: source:
    pkgs.writeShellApplication {
      name = "archive-${name}";
      runtimeInputs =
        with pkgs;
        [
          coreutils
          xz
        ]
        ++ source.packages;
      text = ''
        # Usage: archive-${name} <outbox-dir> <host>
        #
        # Writes `${source.stem}-<host>-<utc>.${source.extension}${lib.optionalString source.compress ".xz"}`.
        #
        # The name is the archive's only ordering key: mtime does not survive syncthing,
        # so it carries the host that produced it and a basic-format UTC timestamp, which
        # sorts lexicographically in time order. UTC because hosts need not share a
        # timezone and an offset would break that sort.
        outbox=''${1:?usage: archive-${name} <outbox-dir> <host>}
        host=''${2:?usage: archive-${name} <outbox-dir> <host>}

        work=$(mktemp -d)
        trap 'rm -rf "$work"' EXIT
        out="$work/${source.stem}.${source.extension}"

        ${source.produce}

        [ -f "$out" ] || { echo "produce wrote no $out" >&2; exit 1; }
        # A zero-length artifact means the source step failed quietly. Anything subtler
        # is the source's own `verify` to catch.
        [ -s "$out" ] || { echo "produce wrote an empty $out" >&2; exit 1; }

        ${lib.optionalString (source.verify != "") source.verify}

        stamp=$(date -u +%Y%m%dT%H%M%SZ)
        name="${source.stem}-$host-$stamp.${source.extension}"
        ${lib.optionalString source.compress ''
          # -6 rather than -9: on a places.sqlite it is both smaller (2041780 vs 2045600
          # bytes) and faster. xz because CPI must read the archive with nothing but the
          # standard library, which has lzma but not zstd.
          xz -6 "$out"
          out="$out.xz"
          name="$name.xz"
        ''}

        # Move in only once complete, and never overwrite: the outbox is the source of
        # truth for a send-only sync, so a half-written file there would propagate. Two
        # runs in the same second are the only collision possible.
        if [ -e "$outbox/$name" ]; then
          echo "$outbox/$name already exists; refusing to overwrite" >&2
          exit 1
        fi
        mv "$out" "$outbox/$name"
        echo "wrote $name ($(stat -c%s "$outbox/$name") bytes)" >&2
      '';
    };
in
{
  options.nightcord.archive = {
    outboxRoot = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/snapshot-outbox";
      readOnly = true;
      description = ''
        Where snapshots wait to be collected, one subdirectory per source. Read by the
        syncthing module, which makes each subdirectory a send-only folder — so this is
        stated once here rather than written literally in both places, where the two could
        drift into syncing an empty directory while snapshots accumulated beside it.
      '';
    };

    sources = lib.mkOption {
      type = lib.types.attrsOf sourceType;
      default = { };
      description = ''
        Local state to snapshot periodically, keyed by source name. The name becomes a
        syncthing folder (`<host>-<source>`) and a directory on proximo
        (`/data/<host>/<source>`), so it should read as a kind of data rather than as the
        tool that produced it.
      '';
    };
  };

  config = lib.mkIf (cfg.sources != { }) {
    systemd.services = lib.mapAttrs' (
      name: source:
      lib.nameValuePair "archive-${name}" {
        description = "Snapshot ${name} into the sync outbox";
        serviceConfig = {
          Type = "oneshot";
          User = source.user;
          # The outbox is owned by syncthing and group-writable; this is what lets a
          # snapshot land there without loosening the directory itself.
          SupplementaryGroups = [ "syncthing" ];
          UMask = "0027";
          ExecStart = "${runner name source}/bin/archive-${name} ${outboxOf name} ${hostName}";
        };
      }
    ) cfg.sources;

    systemd.timers = lib.mapAttrs' (
      name: source:
      lib.nameValuePair "archive-${name}" {
        description = "Snapshot ${name} on a schedule";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = source.schedule;
          # A laptop is often asleep at the scheduled time. Without this a closed lid
          # simply skips the day, and for a source that rotates or expires, that day is
          # then gone for good.
          Persistent = true;
          RandomizedDelaySec = "30m";
        };
      }
    ) cfg.sources;

    systemd.tmpfiles.rules = [
      "d ${cfg.outboxRoot} 0755 syncthing syncthing -"
    ]
    ++ lib.mapAttrsToList (name: _: "d ${outboxOf name} 0770 syncthing syncthing -") cfg.sources;
  };
}
