{
  ...
}:
let
  phoneDeviceId = "UX3KZRG-WXDUHTN-PHLCOS3-JLBK6JX-LH4EKR4-EYOOVNY-YBA3TKL-GKL4UAM";

  backupFolders = {
    "/data/redmi50/app/nodomain.freeyourgadget.gadgetbridge" = {
      id = "redmi50-gadgetbridge";
      label = "Redmi 50 gadgetbridge";
    };
    "/data/redmi50/app/InfinityLoop1309.NewPipeEnhanced" = {
      # Must match the folder ID configured on the phone (redmi50-pipepipe).
      id = "redmi50-pipepipe";
      label = "Redmi 50 pipepipe";
    };
  };
in
{
  # The mesh itself — device identities, the laptops' folders, and the receive-only
  # counterparts of their snapshot outboxes — comes from the shared module. This file
  # adds only the phone, which is proximo's alone: no other host talks to it.
  services.syncthing = {
    settings = {
      devices.redmi50 = {
        id = phoneDeviceId;
      };

      folders = builtins.mapAttrs (_path: f: {
        inherit (f) id label;
        devices = [ "redmi50" ];
        type = "receiveonly";

        # `receiveonly` stops this side from pushing changes to the phone; it does
        # not stop it from accepting deletions. Uninstalling the app or clearing its
        # export directory would propagate here and remove archives that only exist
        # here — for PipePipe those hold play timestamps the app itself has already
        # overwritten, so there is nothing to re-export them from.
        #
        # trashcan rather than staggered: staggered thins old versions of a file,
        # which suits something rewritten in place. Exports are immutable and
        # uniquely named, so each path only ever has one version and there is
        # nothing to thin — the only event to survive is deletion. cleanoutDays 0
        # keeps them indefinitely, which is affordable because duplicity already
        # holds these same files and the retention question is settled there.
        versioning = {
          type = "trashcan";
          params.cleanoutDays = "0";
        };
      }) backupFolders;

      # The phone announces itself on the LAN rather than at a fixed address, so this
      # is the one host in the mesh that needs local discovery. Set here because the
      # shared module leaves it at its default for the laptops, which reach each other
      # over wireguard at known addresses.
      options.localAnnounceEnabled = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /data/redmi50 0750 syncthing syncthing -"
    "d /data/redmi50/app 0750 syncthing syncthing -"
  ]
  ++ map (path: "d ${path} 0750 syncthing syncthing -") (builtins.attrNames backupFolders);

  users.users.cuso4d.extraGroups = [ "syncthing" ];

  networking.firewall.interfaces.ens18 = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      21027
      22000
    ];
  };
}
