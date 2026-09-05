{
  config,
  lib,
  ...
}:
let
  cfg = config.nightcord.syncthing;

  devices = {
    nightcord-laborari = {
      id = "CG46VTL-4S6UHK6-BGUEYCB-GDWHD5U-AIJI5H2-7TBF755-4WUKKMU-TMXH7AR";
      addresses = [ "tcp://10.20.0.2:22000" ];
    };
    nightcord-lexikos = {
      id = "H5X4BSS-HBCXSI7-B3NH6WM-VBL4CRD-IHBVA3P-KMDOK5T-VFRVGQT-RMDTEQL";
      addresses = [ "tcp://10.20.0.3:22000" ];
    };
    nightcord-proximo = {
      # Auto-generated in proximo's own state directory rather than from the shared
      # cert below, and it must stay that way: the phone has already accepted this
      # identity, and a new ID means re-pairing both phone folders by hand. Read with
      #   sudo syncthing device-id --home=/var/lib/syncthing/.config/syncthing
      id = "XIJLKKS-5V56VX7-UISFZU4-6NTEDGB-FRAB5FY-RFDOULH-OR3URBY-QYN34QJ";
      # laborari reaches proximo here; lexikos sees it as 192.168.1.104. Add that as a
      # second entry if lexikos fails to connect — syncthing tries each in turn.
      addresses = [ "tcp://10.20.0.1:22000" ];
    };
  };

  peerNames = builtins.filter (name: name != cfg.deviceName) (builtins.attrNames devices);

  # Hosts sharing the password store. The two laptops only — see the folder below.
  passwordHosts = [
    "nightcord-laborari"
    "nightcord-lexikos"
  ];

  # What each host archives, as `<device> -> [<source>]`. One syncthing folder per
  # (device, source) pair: send-only on the machine that produced it, receive-only on
  # proximo. Per-pair rather than one shared folder because ownership is what protects
  # the archive — in a single bidirectional folder any machine could delete another's
  # history, and every laptop would carry every other machine's snapshots.
  #
  # Declared for the whole fleet here, and not derived from `nightcord.archive.sources`,
  # because proximo must build the receiving end of folders whose producing host it cannot
  # evaluate. The two are cross-checked by an assertion below, so enabling a source and
  # forgetting this map fails the build rather than quietly filling an outbox nothing
  # collects.
  #
  # The phone's two folders are the same idea and live in redmi-backup.nix, which is
  # proximo's alone. Its paths keep an extra `app/` segment, since on a phone the
  # app-private directories are one kind of content among several (DCIM, Downloads);
  # on a PC there is no such distinction to draw.
  snapshotSources = {
    nightcord-laborari = [ "firefox" ];
    nightcord-lexikos = [ "firefox" ];
  };

  device = host: lib.removePrefix "nightcord-" host;

  # `redmi50-gadgetbridge` already established `<device>-<source>`; follow it.
  folderId = host: source: "${device host}-${source}";

  # On proximo every device sits directly under /data, one level, so a laptop and the
  # phone are siblings — they are the same kind of thing. Deliberately not a shared
  # `snapshots/` parent: that would put a category beside a device name, and /data
  # already holds a root-owned `.snapshots` (filesystem snapshots) to be confused with.
  archivePath = host: source: "/data/${device host}/${source}";

  # From archive.nix, which creates these directories, so the two cannot disagree.
  outboxPath = source: "${config.nightcord.archive.outboxRoot}/${source}";

  isProximo = cfg.deviceName == "nightcord-proximo";

  mySources = snapshotSources.${cfg.deviceName} or [ ];

  # trashcan versioning for the same reason the phone folders have it: this side must
  # never lose a snapshot because the producing side dropped it.
  archiveFolders = lib.listToAttrs (
    lib.flatten (
      lib.mapAttrsToList (
        host: sources:
        map (source: {
          name = archivePath host source;
          value = {
            id = folderId host source;
            label = "${device host} ${source}";
            devices = [ host ];
            type = "receiveonly";
            versioning = {
              type = "trashcan";
              params.cleanoutDays = "0";
            };
          };
        }) sources
      ) snapshotSources
    )
  );

  # Send-only so a change on proximo can never travel back and rewrite the source of
  # truth. One folder per source, so a later source cannot make this one resync.
  outboxFolders = lib.listToAttrs (
    map (source: {
      name = outboxPath source;
      value = {
        id = folderId cfg.deviceName source;
        label = "${source} outbox";
        devices = [ "nightcord-proximo" ];
        type = "sendonly";
      };
    }) mySources
  );
in
{
  options.nightcord.syncthing = {
    deviceName = lib.mkOption {
      type = lib.types.enum (builtins.attrNames devices);
      description = "This host's Syncthing device name.";
    };
  };

  config = lib.mkIf (cfg.deviceName != null) {
    # The two halves of a delivery must agree: a source that snapshots with no folder to
    # carry it fills a directory nobody reads, and a folder with no source stays empty
    # while looking configured. Neither shows up as a failure at runtime.
    assertions = [
      {
        assertion =
          lib.sort lib.lessThan (builtins.attrNames config.nightcord.archive.sources)
          == lib.sort lib.lessThan mySources;
        message =
          "nightcord.archive.sources on ${cfg.deviceName} is "
          + "${lib.concatStringsSep ", " (builtins.attrNames config.nightcord.archive.sources)}"
          + " but modules/syncthing.nix lists ${lib.concatStringsSep ", " mySources}"
          + " for it. Update snapshotSources so the snapshots have a folder to travel in.";
      }
    ];

    services.syncthing = {
      enable = true;
      openDefaultPorts = false;
      # Identity from a file the two laptops share, so a reinstall keeps the same
      # device ID. Not on proximo: its identity was generated in its own state
      # directory and the phone has already accepted it.
      cert = lib.mkIf (!isProximo) "/home/cuso4d/.config/syncthing/cert.pem";
      key = lib.mkIf (!isProximo) "/home/cuso4d/.config/syncthing/key.pem";
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        devices = lib.genAttrs peerNames (name: devices.${name});

        folders =
          # The password store, bidirectional between the two laptops. Absent on
          # proximo entirely: it is a server reachable from the office VPN, it holds
          # nothing else that could unlock the store, and it has no such directory.
          # Declaring it there would have syncthing create and serve an empty folder.
          lib.optionalAttrs (builtins.elem cfg.deviceName passwordHosts) {
            "/home/cuso4d/syncthing" = {
              id = "cuso4d-syncthing";
              label = "syncthing";
              devices = builtins.filter (name: name != cfg.deviceName) passwordHosts;
            };
          }
          // outboxFolders
          // lib.optionalAttrs isProximo archiveFolders;

        options = {
          globalAnnounceEnabled = false;
          natEnabled = false;
          relaysEnabled = false;
          urAccepted = -1;
        };
      };
    };

    networking.firewall.interfaces.wg2 = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [
        21027
        22000
      ];
    };

    systemd.tmpfiles.rules =
      lib.optionals (!isProximo) [
        "d /home/cuso4d/syncthing 0750 cuso4d users -"
        "a /home/cuso4d - - - - u::rwx,u:syncthing:--x,g::---,m::--x,o::---"
        "A /home/cuso4d/syncthing - - - - u::rwx,u:cuso4d:rwX,u:syncthing:rwX,g::r-X,m::rwX,o::---,d:u::rwx,d:u:cuso4d:rwX,d:u:syncthing:rwX,d:g::rwX,d:m::rwX,d:o::---"
      ]
      # The outbox directories themselves belong to archive.nix, which creates one per
      # source it defines.
      ++ lib.optionals isProximo (
        lib.flatten (
          lib.mapAttrsToList (
            host: sources:
            [
              "d /data/${device host} 0750 syncthing syncthing -"
            ]
            ++ map (source: "d ${archivePath host source} 0750 syncthing syncthing -") sources
          ) snapshotSources
        )
      );
  };
}
