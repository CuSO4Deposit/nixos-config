{ ... }:
{
  networking.networkmanager.enable = true;
  services.fail2ban.enable = true;
  users.users.cuso4d.extraGroups = [
    "networkmanager"
  ];
}
