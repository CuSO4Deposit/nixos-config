{ ... }:
{
  services.terraria = {
    enable = true;
    port = 15554;
    password = "untitled";
    openFirewall = true;
    messageOfTheDay = "私の声は、届かない――";
    maxPlayers = 4;
    worldPath = "/var/lib/terraria/kagirinaku_error_sekai_he.wld";
  };
}
