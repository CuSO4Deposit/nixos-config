{
  config,
  inputs,
  pkgs,
  ...
}:
let
  # Syncthing's target for the phone's PipePipe exports. Filenames carry a
  # timestamp, so each export arrives as a new file and snapshots accumulate —
  # which is what lets a watch timeline be reconstructed at all, since the app
  # itself only remembers the last time each video was played.
  exports = "/data/redmi50/app/InfinityLoop1309.NewPipeEnhanced/PipePipeData-*.zip";

  # Gadgetbridge's backups arrive the same way. Accumulation matters for a different
  # reason here: the rows are immutable and one backup already holds the full history,
  # but the band only buffers about a week, so a stretch that was never synced is gone
  # for good. Keeping every backup is what bounds the damage from a missed sync.
  bandExports = "/data/redmi50/app/nodomain.freeyourgadget.gadgetbridge/gadgetbridge_*.zip";

  # The laptops' places.sqlite snapshots, one file per machine per run, delivered by the
  # per-(device, source) folders in modules/syncthing.nix. A glob across devices rather
  # than a path: Firefox is the one source that genuinely runs on several machines, and
  # CPI reads the host out of each filename to keep them apart. Naming a single device
  # here would publish one laptop's browsing as if it were the whole record — a complete
  # looking site that is quietly missing half its history.
  #
  # Kept in step with `archivePath` there, which is `/data/<device>/<source>`. A mismatch
  # fails the build loudly: the loaders exit non-zero when the glob matches nothing.
  firefoxExports = "/data/*/firefox/places-*.sqlite.xz";

  publishDir = "/var/lib/observable-cuso4d";
  configDir = "/var/lib/observable-cuso4d/config";

  builder = inputs.observable-cuso4d.packages.${pkgs.stdenv.hostPlatform.system}.site;
in
{
  services.nginx.virtualHosts."observable.internal" = {
    root = "${publishDir}/current";
    locations."/".extraConfig = ''
      # Framework generates clean URLs by dropping the .html extension.
      try_files $uri $uri.html $uri/index.html =404;
    '';
  };

  age.secrets."observable-cuso4d-env" = {
    file = ../../secrets/observable-cuso4d-env.age;
    owner = "cuso4d";
    group = "users";
  };

  systemd.tmpfiles.rules = [
    "d ${publishDir} 0750 cuso4d nginx -"
    "d ${configDir} 0700 cuso4d users -"
  ];

  systemd.services.observable-cuso4d = {
    description = "Rebuild the cuso4d dashboards from archived exports";
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "cuso4d";
      # Reading the archive needs the syncthing group; nginx must be able to read
      # what gets published.
      SupplementaryGroups = [
        "syncthing"
        "nginx"
      ];
      UMask = "0027";
      # Both optional to the builder, which drops a source's pages when its variable is
      # unset. Set here rather than in the secret because a path under /data names
      # nothing personal; CPI_LOCAL_TZ is in the secret precisely because it does.
      Environment = [
        "CPI_GADGETBRIDGE_EXPORTS=${bandExports}"
        "CPI_FIREFOX_EXPORTS=${firefoxExports}"
      ];
      EnvironmentFile = config.age.secrets."observable-cuso4d-env".path;
      ExecStart = ''
        ${builder}/bin/observable-cuso4d-build '${exports}' '${publishDir}/current' '${configDir}'
      '';
    };
  };

  systemd.timers.observable-cuso4d = {
    description = "Rebuild the cuso4d dashboards daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      # Catch up after downtime instead of silently skipping a day.
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
