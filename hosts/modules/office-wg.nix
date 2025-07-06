{
  lib,
  config,
  pkgs,
  ...
}:
{
  age.identityPaths = lib.map (x: "/home/${x}/.ssh/id_ed25519") (
    lib.attrNames (lib.attrsets.filterAttrs (n: v: v.isNormalUser) config.users.users)
  );
  age.secrets = {
    "office.conf".file = ../../secrets/office.conf.age;
  };

  networking.wg-quick.interfaces.wg0.configFile = config.age.secrets."office.conf".path;
}
