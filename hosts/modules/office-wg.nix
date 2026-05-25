{
  config,
  ...
}:
{
  age.secrets = {
    "office.conf".file = ../../secrets/office.conf.age;
  };

  networking.wg-quick.interfaces.wg0.configFile = config.age.secrets."office.conf".path;
}
