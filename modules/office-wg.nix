{
  config,
  ...
}:
{
  age.secrets = {
    "office.conf".file = ../secrets/office.conf.age;
  };

  networking.wg-quick.interfaces.wg0.configFile = config.age.secrets."office.conf".path;

  # configFile is a stable path under /run/agenix, so its contents changing
  # does not change the unit and systemd sees nothing to restart. Trigger off
  # a hash of the encrypted file instead, otherwise a rotated tunnel config
  # only takes effect on the next reboot.
  systemd.services.wg-quick-wg0.restartTriggers = [
    (builtins.hashFile "sha256" ../secrets/office.conf.age)
  ];
}
