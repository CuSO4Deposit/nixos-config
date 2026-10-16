{
  lib,
  pkgs,
  ...
}:
let
  fabric = pkgs.callPackage ../../derivations/minecraft-fabric { };

  dataDir = "/var/lib/minecraft-fabric";
  levelName = "MOTION_SICKNESS_DEMO_MC_WO_SITAI";
  port = 25565;

  cfgToString = v: if builtins.isBool v then lib.boolToString v else toString v;

  serverProperties = {
    allow-cheats = true;
    difficulty = "hard";
    gamemode = "survival";
    level-name = levelName;
    max-players = 4;
    motd = "点我放松一下";
    online-mode = false;
    server-port = port;
    white-list = false;
  };

  serverPropertiesFile = pkgs.writeText "fabric-server.properties" (
    "# server.properties managed by NixOS configuration\n"
    + lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "${n}=${cfgToString v}") serverProperties)
  );

  eulaFile = builtins.toFile "fabric-eula.txt" "eula=true\n";

  stopScript = pkgs.writeShellScript "minecraft-fabric-stop" ''
    echo stop > /run/minecraft-fabric.stdin

    while kill -0 "$1" 2> /dev/null; do
      sleep 1s
    done
  '';
in
{
  users.users.minecraft = {
    description = "Minecraft server service user";
    isSystemUser = true;
    group = "minecraft";
    home = dataDir;
    createHome = true;
  };
  users.groups.minecraft = { };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 minecraft minecraft - -"
    "d ${dataDir}/config 0750 minecraft minecraft - -"
  ];

  systemd.sockets.minecraft-fabric = {
    bindsTo = [ "minecraft-fabric.service" ];
    socketConfig = {
      ListenFIFO = "/run/minecraft-fabric.stdin";
      SocketMode = "0660";
      SocketUser = "minecraft";
      SocketGroup = "minecraft";
      RemoveOnStop = true;
      FlushPending = true;
    };
  };

  systemd.services.minecraft-fabric = {
    description = "Minecraft Server Service (Fabric + Numen, port ${toString port})";
    wantedBy = [ "multi-user.target" ];
    requires = [ "minecraft-fabric.socket" ];
    after = [
      "network.target"
      "minecraft-fabric.socket"
    ];

    preStart = ''
      rm -rf mods
      ln -s ${fabric.mods} mods

      ln -sf ${eulaFile} eula.txt

      cp -f ${serverPropertiesFile} server.properties
      chmod +w server.properties
    '';

    serviceConfig = {
      ExecStart = "${fabric.server}/bin/minecraft-fabric-server";
      ExecStop = "${stopScript} $MAINPID";
      Restart = "always";
      User = "minecraft";
      WorkingDirectory = dataDir;

      StandardInput = "socket";
      StandardOutput = "journal";
      StandardError = "journal";

      CapabilityBoundingSet = [ "" ];
      DeviceAllow = [ "" ];
      LockPersonality = true;
      PrivateDevices = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];
  networking.firewall.allowedUDPPorts = [ port ];
}
