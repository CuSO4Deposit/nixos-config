let
  proximo-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBnPi9CTg8uMgIFCr/sQxo8Fmn/wuJioDnb8SiVk7GUw";
  proximo-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEVOjjy6t6+Eo5CoGRAUM6VSO1Npik9E0UsOXIVMl90E";
  dynamica-user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL/tpmLxVSyNLRsaUZmCaUC5uPmFhWl17fITU4LAKj+F";
  hosts = [
    proximo-host
  ];
  users = [
    dynamica-user
    proximo-user
  ];
  all = hosts ++ users;
in
{
}
