{
  config,
  pkgs,
  ...
}:
{
  age.secrets = {
    "office-vpn.ovpn".file = ../../secrets/office-vpn.ovpn.age;
    "office-vpn.auth".file = ../../secrets/office-vpn.auth.age;
  };

  environment.etc.openvpn.source = "${pkgs.update-systemd-resolved}/libexec/openvpn";

  services.openvpn.servers.office = {
    # service.openvpn.servers.<name>.authUserPass still do not allow paths.
    # This is a possible workaround provided by tbaumann in:
    # https://github.com/NixOS/nixpkgs/issues/312283#issuecomment-2116102594
    config = ''
      config ${config.age.secrets."office-vpn.ovpn".path}
      auth-user-pass ${config.age.secrets."office-vpn.auth".path}
    '';
  };
}
