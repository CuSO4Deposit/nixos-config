{
  config,
  lib,
  ...
}:
let
  cfg = config.nightcord.internal-cache;
in
{
  options.nightcord.internal-cache = {
    # Served by atticd on laborari. narinfo comes from its local database, so a
    # dead office tunnel still answers fast; only NAR downloads fall back. Set
    # this to false to build from the upstream mirrors instead.
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use the internal nix binary cache as a substituter.";
    };

    url = lib.mkOption {
      type = lib.types.str;
      default = "http://attic.internal/nightcord";
      description = "Base URL of the internal binary cache.";
    };

    publicKey = lib.mkOption {
      type = lib.types.str;
      default = "nightcord:U5PWPoUzUBFcnJ/a7mWP2zbg0hGjbKJbJqeKSbE/s/M=";
      description = "Public key the internal cache signs its store paths with.";
    };
  };

  config = {
    nix.settings = lib.mkMerge [
      (lib.mkIf cfg.enable {
        extra-substituters = [ cfg.url ];
        extra-trusted-public-keys = [ cfg.publicKey ];
      })
      {
        # Never let one unresponsive substituter hold a build hostage. Nix
        # defaults stalled-download-timeout to 300s, which is applied per
        # narinfo request, so a hung cache costs minutes per store path.
        # Twenty seconds is well past a healthy LAN response and short enough
        # that a dead cache degrades into a fallback instead of a hang.
        connect-timeout = 5;
        stalled-download-timeout = 20;
        # Keep going when a substituter misbehaves rather than aborting.
        fallback = true;
      }
    ];
  };
}
