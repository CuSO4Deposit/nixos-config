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
  };

  peerNames = builtins.filter (name: name != cfg.deviceName) (builtins.attrNames devices);
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
      cert = "/home/cuso4d/.config/syncthing/cert.pem";
      key = "/home/cuso4d/.config/syncthing/key.pem";
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        devices = lib.genAttrs peerNames (name: devices.${name});

        folders."/home/cuso4d/syncthing" = {
          id = "cuso4d-syncthing";
          label = "syncthing";
          devices = peerNames;
        };

        options.urAccepted = -1;
      };
    };

    networking.firewall.interfaces.wg2 = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [
        21027
        22000
      ];
    };

    systemd.tmpfiles.rules = [
      "d /home/cuso4d/syncthing 0750 cuso4d users -"
      "a+ /home/cuso4d - - - - u:syncthing:--x"
      "A+ /home/cuso4d/syncthing - - - - u:cuso4d:rwX,u:syncthing:rwX,d:u:cuso4d:rwX,d:u:syncthing:rwX"
    ];
  };
}
