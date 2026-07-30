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
  services.syncthing = {
    enable = true;
    openDefaultPorts = false;
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices.redmi50 = {
        id = phoneDeviceId;
      };

      folders = builtins.mapAttrs (_path: f: {
        inherit (f) id label;
        devices = [ "redmi50" ];
        type = "receiveonly";
      }) backupFolders;

      options = {
        localAnnounceEnabled = true;
        globalAnnounceEnabled = false;
        natEnabled = false;
        relaysEnabled = false;
        urAccepted = -1;
      };
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
