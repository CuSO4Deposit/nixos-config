{
  config,
  lib,
  pkgs,
  ...
}:
{
  age.secrets = {
    firefox_bypass.file = ./firefox_bypass.age;
  };
}
