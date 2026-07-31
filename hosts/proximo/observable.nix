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
      Environment = [ "CPI_GADGETBRIDGE_EXPORTS=${bandExports}" ];
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
