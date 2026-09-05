{ ... }:
{
  imports = [
    ./desktop.nix
    ./quiet-on-lock.nix
  ];

  nightcord.quiet-on-lock.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandlePowerKey = "suspend";
  };
}
