{
  config,
  lib,
  pkgs,
  ...
}:
{
  networking.networkmanager.enable = true;
  networking.nameservers = [
    "8.8.8.8"
    "114.114.114.114"
  ];

  users.users.cuso4d.extraGroups = [
    "networkmanager"
  ];
}
