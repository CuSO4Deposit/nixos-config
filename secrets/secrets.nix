let
  proximo-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBnPi9CTg8uMgIFCr/sQxo8Fmn/wuJioDnb8SiVk7GUw";
  proximo-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEVOjjy6t6+Eo5CoGRAUM6VSO1Npik9E0UsOXIVMl90E";
  dynamica-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL/tpmLxVSyNLRsaUZmCaUC5uPmFhWl17fITU4LAKj+F";
  laborari-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzaVljG6lJvVE4u5h9p76FIgWm4HQuWjdBPD7P1bQ+t";
  lexikos-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqYxALoBtJ9fo0zLZComsvnfUgMtqnAMa12TaDUaIjA";
  hosts = [
    proximo-host
  ];
  users = [
    dynamica-user
    laborari-user
    proximo-user
    lexikos-user
  ];
  all = hosts ++ users;

  secrets = [
    "juicefs-password-env.age"
    "nix-cache-signing-key.age"
    "officeVPN.ovpn.age"
    "officeVPN.auth.age"
    "office.conf.age"
    "office-band.conf.age"
    "openclaw-env.age"
    "rclone.conf.age"
    "telegram-bot-token.age"
    "telegram-bot-token-yoshino.age"
    "wg-laborari.conf.age"
    "wg-lexikos.conf.age"
    "wg-proximo.conf.age"
    "zotero-api-key.age"
    "zotero-user-id.age"
  ];
in
builtins.listToAttrs (
  map (name: {
    name = "${name}";
    value = {
      publicKeys = all;
    };
  }) secrets
)
