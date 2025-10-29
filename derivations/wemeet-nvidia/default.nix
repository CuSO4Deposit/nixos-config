{ pkgs }:
pkgs.writeShellScriptBin "wemeet-nvidia" ''
  export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
  exec ${pkgs.wemeet}/bin/wemeet-xwayland "$@"
''
