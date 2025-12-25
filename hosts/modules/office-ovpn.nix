{
  lib,
  config,
  pkgs,
  ...
}:
{
  age.identityPaths = lib.map (x: "/home/${x}/.ssh/id_ed25519") (
    lib.attrNames (lib.attrsets.filterAttrs (_: v: v.isNormalUser) config.users.users)
  );
  age.secrets = {
    "officeVPN.ovpn".file = ../../secrets/officeVPN.ovpn.age;
    "officeVPN.auth".file = ../../secrets/officeVPN.auth.age;
  };

  environment.etc.openvpn.source = "${pkgs.update-systemd-resolved}/libexec/openvpn";

  services.openvpn.servers.office = {
    # service.openvpn.servers.<name>.authUserPass still do not allow paths.
    # This is a possible workaround provided by tbaumann in:
    # https://github.com/NixOS/nixpkgs/issues/312283#issuecomment-2116102594
    config = ''
      config ${config.age.secrets."officeVPN.ovpn".path}
      auth-user-pass ${config.age.secrets."officeVPN.auth".path}
    '';
  };
}
