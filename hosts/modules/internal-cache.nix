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
    # The internal cache is served by nginx on laborari straight out of the
    # rclone MinIO mount. When the office WireGuard tunnel is down the S3
    # endpoint stops resolving, the FUSE mount starts returning EIO, and nginx
    # blocks on every file read instead of answering 404. Nix then waits out
    # its full stall timeout for each individual .narinfo, which makes any
    # build effectively hang. Set this to false to take the cache out of the
    # substituter list entirely and build straight from the upstream mirrors.
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use the internal nix binary cache as a substituter.";
    };

    url = lib.mkOption {
      type = lib.types.str;
      default = "http://nix-auto-build.internal";
      description = "Base URL of the internal binary cache.";
    };

    publicKey = lib.mkOption {
      type = lib.types.str;
      default = "nix-cache.laborari:wPKpQRXxNF7jBk6A1vn26ObhXAEWN8jF0QCTkdT+qe0=";
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
