# Fixed-version entry point for wemeet-wayland.
#
# The working combination is a *triple*, not three independent choices:
#
#   wemeet 3.26.10.401  +  pipewire 1.4.10  +  mesa 26.0.2  (+ Hunk 0)
#
#   * wemeet 3.26.10.401 is the version the Hunk 0 byte offsets were verified
#     against.
#   * pipewire 1.4.10 is the last version whose process callback wemeet's
#     capture path survives (1.6.x crashes in pw_stream_queue_buffer).
#   * mesa 26.0.x is needed to render incoming video (NVIDIA EGL rejects
#     wemeet's 32-bit config against a 24-bit window) while 26.1/26.2 regressed
#     eglGetDisplay (0x300c -> join error 5021) on current NVIDIA drivers.
{ pkgs, inputs }:

let
  # wemeet stays on the current nixpkgs build (same .deb, current runtime
  # closure); only the two version-sensitive libraries come from the older rev.
  pkgs-wemeet = import inputs.nixpkgs-wemeet {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  pkgs-wemeet-compat = import inputs.nixpkgs-wemeet-compat {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
pkgs.callPackage ./package.nix {
  wemeet = pkgs-wemeet.wemeet;
  pipewire = pkgs-wemeet-compat.pipewire;
  mesa = pkgs-wemeet-compat.mesa;
}
