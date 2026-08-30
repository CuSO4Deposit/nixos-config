{ pkgs, ... }:
let
  authmeJar = pkgs.fetchurl {
    url = "https://github.com/AuthMe/AuthMeReloaded/releases/download/6.0.0/AuthMe-6.0.0-Paper.jar";
    hash = "sha256-WJSPy8aXSXUGJX0J2KeQm/SN5q7+e+xrpatMQb5Bt7g=";
  };
  skinsRestorerJar = pkgs.fetchurl {
    url = "https://github.com/SkinsRestorer/SkinsRestorer/releases/download/15.12.5/SkinsRestorer.jar";
    hash = "sha256-vxP/7pu0iBQbfsmWA+vIq6xomTPXLbFeZk/rC03u/GA=";
  };
in
{
  services.minecraft-server = {
    declarative = true;
    enable = true;
    eula = true;
    openFirewall = true;
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

  systemd.tmpfiles.rules = [
    "d /var/lib/minecraft/plugins 0750 minecraft minecraft - -"
    "L+ /var/lib/minecraft/plugins/AuthMe.jar - - - - ${authmeJar}"
    "L+ /var/lib/minecraft/plugins/SkinsRestorer.jar - - - - ${skinsRestorerJar}"
  ];
}
