# Tencent WeMeet with working screen share on Hyprland/Wayland.
#
# Background (why all of this is needed):
#
#   * wemeet's Linux capture primitive is X11 XShm.  Under Wayland it only
#     works when it is told it runs under XWayland, via $WEMEET_XWAYLAND=1;
#     then it uses its *native* xdg-desktop-portal ScreenCast path
#     (WaylandScreenCastHelper) over PipeWire.
#
#   * The nixpkgs wrapper never sets $WEMEET_XWAYLAND, so the native path is
#     never taken (screen share stays on XShm and captures the empty XWayland
#     root window -> green).  It also adds an XShm LD_PRELOAD hook that we do
#     NOT want here (it would open a second portal session).
#
#   * The native path does `dlopen("libpipewire-0.3.so.0")`.  On NixOS that
#     library is not on wemeet's search path, so we add a PipeWire to
#     LD_LIBRARY_PATH.  The version matters: wemeet 3.26.10.401 is a prebuilt
#     binary and crashes inside pw_stream_queue_buffer with system PipeWire
#     1.6.9, while 1.4.10 works.  So `pipewire` is pinned to a known-good
#     version (passed in from the caller).
#
#   * Upstream Hunk 0 (Matheritasiv/wemeet-screenshare-patch) fixes a DBus race
#     in the native path: the portal `Start` call is issued before
#     `SelectSources` completes, which always fails on wlr/Hyprland backends
#     that block inside SelectSources.  Without it the first share fails/falls
#     back to X11.
#
#   * We run as an XWayland (xcb) client and keep WAYLAND_DISPLAY unset: running
#     as a native Wayland Qt client segfaults in
#     x_utils::SetWindowInputFocus()/WMQtUiUtil::ShowWindow(), which is also
#     what wemeet's own wemeetapp.sh fallback does.
# `wemeet` and `pipewire` are passed in pinned (see flake.nix / desktop.nix);
# they deliberately do NOT come from the floating system nixpkgs.
{
  pkgs,
  wemeet,
  pipewire,
}:

let
  wemeet-patched = wemeet.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.python3 ];
    postFixup = (old.postFixup or "") + ''
      python3 ${./patch-hunk0.py} $out/app/wemeet
    '';
  });
in
pkgs.writeShellScriptBin "wemeet-wayland" ''
  export WEMEET_XWAYLAND=1
  export QT_QPA_PLATFORM=xcb
  export XDG_SESSION_TYPE=x11
  unset WAYLAND_DISPLAY

  # let wemeet's screencast helper dlopen its (pinned) libpipewire-0.3.so.0
  export LD_LIBRARY_PATH=${pipewire}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

  exec ${wemeet-patched}/bin/wemeet "$@"
''
