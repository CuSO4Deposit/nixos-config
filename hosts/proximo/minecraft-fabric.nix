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

  # Single source for the console socket: the socket unit, stop script, and backup
  # hooks all derive from it.
  fifo = "/run/minecraft-fabric.stdin";

  cfgToString = v: if builtins.isBool v then lib.boolToString v else toString v;

  serverProperties = {
    allow-cheats = true;
    difficulty = "hard";
    enforce-secure-profile = false;
    enforce-whitelist = true;
    gamemode = "survival";
    level-name = levelName;
    max-players = 4;
    motd = "点我放松一下";
    online-mode = false;
    server-port = port;
    white-list = true;
  };

  serverPropertiesFile = pkgs.writeText "fabric-server.properties" (
    "# server.properties managed by NixOS configuration\n"
    + lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "${n}=${cfgToString v}") serverProperties)
  );

  whitelistFile = pkgs.writeText "fabric-whitelist.json" (
    builtins.toJSON [
      {
        name = "CuSO4D";
        uuid = "e6b625a9-7682-37d5-a116-bc7a19425cde";
      }
      {
        name = "CorundumBlock";
        uuid = "42fcf111-7ee6-32dd-9e54-d6a6dadb19c0";
      }
    ]
  );

  eulaFile = builtins.toFile "fabric-eula.txt" "eula=true\n";

  stopScript = pkgs.writeShellScript "minecraft-fabric-stop" ''
    echo stop > ${fifo}

    while kill -0 "$1" 2> /dev/null; do
      sleep 1s
    done
  '';
in
{
  options.nightcord.minecraft-fabric = {
    backupPrepareCommand = lib.mkOption {
      type = lib.types.lines;
      description = ''
        Quiesce the server for a backup: stop autosaving, then force a synchronous flush
        to disk. Compose it into the host's `nightcord.restic-backup.backupPrepareCommand`.
      '';
    };

    backupCleanupCommand = lib.mkOption {
      type = lib.types.lines;
      description = ''
        Undo `backupPrepareCommand`. Compose it into the host's
        `nightcord.restic-backup.backupCleanupCommand`; it runs even when the backup failed,
        so saving is never left disabled.
      '';
    };
  };

  config = {
    nightcord.minecraft-fabric = {
      backupPrepareCommand = ''
        # Fatal on failure, not skipped: an unreachable live server is exactly when its
        # files are unsafe to read.
        if ${pkgs.systemd}/bin/systemctl is-active --quiet minecraft-fabric.service; then
          ${pkgs.coreutils}/bin/timeout 5 ${pkgs.bash}/bin/bash -c 'echo "save-off" > ${fifo}' \
            || { echo "minecraft: save-off failed" >&2; exit 1; }
          ${pkgs.coreutils}/bin/timeout 5 ${pkgs.bash}/bin/bash -c 'echo "save-all flush" > ${fifo}' \
            || { echo "minecraft: save-all failed" >&2; exit 1; }
          ${pkgs.coreutils}/bin/sleep 5
        fi
      '';

      backupCleanupCommand = ''
        # Runs from postStop, so it also covers a failed or interrupted backup.
        if ${pkgs.systemd}/bin/systemctl is-active --quiet minecraft-fabric.service; then
          ${pkgs.coreutils}/bin/timeout 5 ${pkgs.bash}/bin/bash -c 'echo "save-on" > ${fifo}' \
            || echo "minecraft: save-on failed" >&2
        fi
      '';
    };

    users.users.minecraft = {
      description = "Minecraft server service user";
      isSystemUser = true;
      group = "minecraft";
      home = dataDir;
      homeMode = "0750";
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
        ListenFIFO = fifo;
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

        cp -f ${whitelistFile} whitelist.json
        chmod +w whitelist.json
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
  };
}
