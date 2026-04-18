{ ... }:
{
  imports = [
    ./desktop.nix
  ];

  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      turbo = "never";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandlePowerKey = "suspend";
  };
  # Conflicts with services.auto-cpufreq
  services.power-profiles-daemon.enable = false;
}
