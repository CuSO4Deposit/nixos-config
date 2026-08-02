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

  # Hosts that take Firefox snapshots. Each gets its own folder: one send-only copy on
  # the machine that produced it, one receive-only copy on proximo. Per-host rather than
  # one shared folder because ownership is what protects the archive — in a single
  # bidirectional folder any machine could delete another's history, and every laptop
  # would carry every other machine's snapshots.
  snapshotHosts = [
    "nightcord-laborari"
    "nightcord-lexikos"
  ];

  outbox = "/var/lib/snapshot-outbox";

  folderId = host: "snapshots-${lib.removePrefix "nightcord-" host}";

  isProximo = cfg.deviceName == "nightcord-proximo";

  # On proximo, one receive-only folder per producing host, all under /data/snapshots.
  # trashcan versioning for the same reason the phone folders have it: this side must
  # never lose a snapshot because the producing side dropped it.
  archiveFolders = lib.listToAttrs (
    map (host: {
      name = "/data/snapshots/${lib.removePrefix "nightcord-" host}";
      value = {
        id = folderId host;
        label = "snapshots ${lib.removePrefix "nightcord-" host}";
        devices = [ host ];
        type = "receiveonly";
        versioning = {
          type = "trashcan";
          params.cleanoutDays = "0";
        };
      };
    }) snapshotHosts
  );

  # On a producing host, exactly one send-only folder: its own. Send-only so a change
  # on proximo can never travel back and rewrite the source of truth.
  outboxFolder = lib.optionalAttrs (builtins.elem cfg.deviceName snapshotHosts) {
    ${outbox} = {
      id = folderId cfg.deviceName;
      label = "snapshot outbox";
      devices = [ "nightcord-proximo" ];
      type = "sendonly";
    };
  };
in
{
  options.nightcord.syncthing = {
    deviceName = lib.mkOption {
      type = lib.types.enum (builtins.attrNames devices);
      description = "This host's Syncthing device name.";
    };
  };

  config = lib.mkIf (cfg.deviceName != null) {
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
          // outboxFolder
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
      # The outbox is written by the snapshot timer and read by syncthing, so it is
      # owned by syncthing and group-writable for the timer's user. Under /var/lib
      # rather than the home directory to keep it clear of the ACL dance above.
      ++ lib.optionals (builtins.elem cfg.deviceName snapshotHosts) [
        "d ${outbox} 0770 syncthing syncthing -"
      ]
      ++ lib.optionals isProximo (
        [ "d /data/snapshots 0750 syncthing syncthing -" ]
        ++ map (
          host: "d /data/snapshots/${lib.removePrefix "nightcord-" host} 0750 syncthing syncthing -"
        ) snapshotHosts
      );
  };
}
