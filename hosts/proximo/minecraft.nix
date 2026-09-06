{ pkgs, lib, ... }:
let
  authmeJar = pkgs.fetchurl {
    url = "https://github.com/AuthMe/AuthMeReloaded/releases/download/6.0.0/AuthMe-6.0.0-Paper.jar";
    hash = "sha256-WJSPy8aXSXUGJX0J2KeQm/SN5q7+e+xrpatMQb5Bt7g=";
  };
  skinsRestorerJar = pkgs.fetchurl {
    url = "https://github.com/SkinsRestorer/SkinsRestorer/releases/download/15.12.5/SkinsRestorer.jar";
    hash = "sha256-vxP/7pu0iBQbfsmWA+vIq6xomTPXLbFeZk/rC03u/GA=";
  };

  plugins = dataDir: [
    "d ${dataDir}/plugins 0750 minecraft minecraft - -"
    "L+ ${dataDir}/plugins/AuthMe.jar - - - - ${authmeJar}"
    "L+ ${dataDir}/plugins/SkinsRestorer.jar - - - - ${skinsRestorerJar}"
  ];

  # ---- DSMP  ----
  dsmpDir = "/var/lib/minecraft2";
  dsmpProperties = {
    allow-cheats = true;
    difficulty = "hard";
    gamemode = "survival";
    level-name = "DSMP";
    max-players = 4;
    motd = "D is for Depoze";
    online-mode = false;
    server-port = 25566;
    white-list = false;
  };

  cfgToString = v: if builtins.isBool v then lib.boolToString v else toString v;

  eulaFile = builtins.toFile "eula.txt" ''
    # eula.txt managed by NixOS Configuration
    eula=true
  '';

  dsmpPropertiesFile = pkgs.writeText "dsmp-server.properties" (
    "# server.properties managed by NixOS configuration\n"
    + lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "${n}=${cfgToString v}") dsmpProperties)
  );

  dsmpStop = pkgs.writeShellScript "minecraft2-stop" ''
    echo stop > /run/minecraft2.stdin

    # Wait for the server PID to disappear before returning, so systemd
    # doesn't attempt to SIGKILL it mid-save.
    while kill -0 "$1" 2> /dev/null; do
      sleep 1s
    done
  '';
in
{
  services.minecraft-server = {
    declarative = true;
    enable = true;
    eula = true;
    openFirewall = true;
    jvmOpts = "-Xmx1024M -Xms1024M";
    serverProperties = {
      allow-cheats = true;
      difficulty = "hard";
      gamemode = "survival";
      level-name = "MOTION_SICKNESS_DEMO_MC_WO_SITAI";
      max-players = 4;
      motd = "点我放松一下";
      online-mode = false;
      server-port = 25565;
      white-list = false;
    };
    package = pkgs.papermc;
    whitelist = {
      "CuSO4D" = "0f5f4275-656f-41e4-b2ef-1a7914c2e5df";
    };
  };

  systemd.tmpfiles.rules =
    plugins "/var/lib/minecraft"
    ++ [
      "d ${dsmpDir} 0750 minecraft minecraft - -"
    ]
    ++ plugins dsmpDir;

  # Second instance. `services.minecraft-server` is a singleton,
  # so this mirrors the upstream unit (same papermc launcher, FIFO console for
  # a graceful stop, declarative eula.txt/server.properties) against its own
  # data dir, reusing the `minecraft` user created by the first instance.
  systemd.sockets.minecraft2 = {
    bindsTo = [ "minecraft2.service" ];
    socketConfig = {
      ListenFIFO = "/run/minecraft2.stdin";
      SocketMode = "0660";
      SocketUser = "minecraft";
      SocketGroup = "minecraft";
      RemoveOnStop = true;
      FlushPending = true;
    };
  };

  systemd.services.minecraft2 = {
    description = "Minecraft Server Service (DSMP, port 25566)";
    wantedBy = [ "multi-user.target" ];
    requires = [ "minecraft2.socket" ];
    after = [
      "network.target"
      "minecraft2.socket"
    ];

    preStart = ''
      ln -sf ${eulaFile} eula.txt
      cp -f ${dsmpPropertiesFile} server.properties
      # Paper rewrites server.properties on start; the store file is read-only.
      chmod +w server.properties
    '';

    serviceConfig = {
      ExecStart = "${pkgs.papermc}/bin/minecraft-server -Xmx2048M -Xms2048M";
      ExecStop = "${dsmpStop} $MAINPID";
      Restart = "always";
      User = "minecraft";
      WorkingDirectory = dsmpDir;

      StandardInput = "socket";
      StandardOutput = "journal";
      StandardError = "journal";

      # Hardening, kept in step with the upstream minecraft-server unit.
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

  networking.firewall.allowedTCPPorts = [ 25566 ];
  networking.firewall.allowedUDPPorts = [ 25566 ];
}
