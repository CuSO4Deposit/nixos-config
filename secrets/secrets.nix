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

  # Host-specific key groups
  proximo = [
    proximo-host
    proximo-user
  ];
  laborari = [ laborari-user ];
  lexikos = [ lexikos-user ];
  dynamica = [ dynamica-user ];
  desktops = [
    dynamica-user
    laborari-user
    lexikos-user
  ];
in
{
  # proximo only
  "ghorg-github-token.age".publicKeys = proximo;
  "ghorg-github-token-sayori.age".publicKeys = proximo;
  "ghorg-work-0.yaml.age".publicKeys = proximo;
  "wg-proximo.conf.age".publicKeys = proximo;
  "piwigo-db-password.age".publicKeys = proximo ++ laborari;

  # laborari only
  "cloudflare-origin-cert.pem.age".publicKeys = laborari;
  "cloudflare-origin-key.pem.age".publicKeys = laborari;
  "nix-cache-signing-key.age".publicKeys = laborari;
  "opencode-nginx.conf.age".publicKeys = laborari;
  "opencode-server-password.age".publicKeys = laborari;
  "piwigo-nginx.conf.age".publicKeys = laborari;
  "wg-laborari.conf.age".publicKeys = laborari;

  # lexikos only
  "wg-lexikos.conf.age".publicKeys = lexikos;

  # shared across multiple hosts
  "juicefs-password-env.age".publicKeys = proximo ++ laborari ++ lexikos;
  "office.conf.age".publicKeys = dynamica ++ laborari ++ lexikos;
  "office-band.conf.age".publicKeys = laborari ++ lexikos;
  "officeVPN.ovpn.age".publicKeys = all;
  "officeVPN.auth.age".publicKeys = all;
  "rclone.conf.age".publicKeys = laborari ++ lexikos;

  # openclaw / desktop hosts
  "openclaw-env.age".publicKeys = desktops;
  "telegram-bot-token.age".publicKeys = desktops;
  "telegram-bot-token-yoshino.age".publicKeys = desktops;
  "telegram-bot-token-yuuka.age".publicKeys = desktops;
  "zotero-api-key.age".publicKeys = desktops;
  "zotero-user-id.age".publicKeys = desktops;
}
