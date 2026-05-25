{ pkgs, ... }:
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
}
