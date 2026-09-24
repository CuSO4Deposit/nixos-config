{
  config,
  pkgs,
  ...
}:
{
  age.secrets = {
    "office.conf".file = ../secrets/office.conf.age;
  };

  networking.wg-quick.interfaces.wg0.configFile = config.age.secrets."office.conf".path;

  # wg-quick's configFile mode copies the config into the unit's private /tmp and
  # ExecStop runs `wg-quick down /tmp/wg0.conf`. If /tmp gets cleaned while the
  # tunnel is up, the stop fails and leaves wg0 behind, so the next start aborts
  # with "wg0 already exists". Delete any leftover interface before starting.
  systemd.services.wg-quick-wg0.serviceConfig.ExecStartPre = [
    "-${pkgs.iproute2}/bin/ip link del wg0"
  ];

  # configFile is a stable path under /run/agenix, so its contents changing
  # does not change the unit and systemd sees nothing to restart. Trigger off
  # a hash of the encrypted file instead, otherwise a rotated tunnel config
  # only takes effect on the next reboot.
  systemd.services.wg-quick-wg0.restartTriggers = [
    (builtins.hashFile "sha256" ../secrets/office.conf.age)
  ];
}
