{ ... }:
{
  networking.hosts = {
    "10.20.0.2" = [ "nix-auto-build.internal" ];
  };
}
