let
  proximo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBnPi9CTg8uMgIFCr/sQxo8Fmn/wuJioDnb8SiVk7GUw";
  users = [
    proximo
  ];
in
{
  "firefox_bypass.age".publicKeys = users;
}
