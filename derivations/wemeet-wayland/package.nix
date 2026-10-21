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
#   * Incoming screen shares are rendered by libxcast's EGL renderer, which
#     asks EGL for a 32-bit ARGB config but hands EGL a 24-bit X11 window.
#     NVIDIA's EGL strictly rejects that mismatch (eglCreateWindowSurface ->
#     0x3005) so received shares render black; Mesa's EGL tolerates it.  We
#     therefore run this process on a pinned Mesa (software rasterizer).  Mesa
#     must be 26.0.x: 26.1/26.2 regressed eglGetDisplay (0x300c -> join error
#     5021) with current NVIDIA drivers.
#
#   * We run as an XWayland (xcb) client and keep WAYLAND_DISPLAY unset: running
#     as a native Wayland Qt client segfaults in
#     x_utils::SetWindowInputFocus()/WMQtUiUtil::ShowWindow(), which is also
#     what wemeet's own wemeetapp.sh fallback does.
#
# Current limitation: stopping a share and starting another one may still crash
# inside libxcast/pipewire (the helper does not reset its capture/stream state
# cleanly).
#
# `wemeet`, `pipewire` and `mesa` are pinned by `default.nix` (which imports the
# fixed nixpkgs inputs); they deliberately do NOT come from the floating system
# nixpkgs.  Do not call this file directly unless you are intentionally
# overriding that version triple.
{
  pkgs,
  wemeet,
  pipewire,
  mesa,
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
  export LD_LIBRARY_PATH=${pipewire}/lib:${mesa}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

  # Render incoming video through the pinned Mesa EGL (see header).
  export __EGL_VENDOR_LIBRARY_FILENAMES=${mesa}/share/glvnd/egl_vendor.d/50_mesa.json
  export LIBGL_ALWAYS_SOFTWARE=1

  exec ${wemeet-patched}/bin/wemeet "$@"
''
