{ pkgs }:
let
  # Feishu's generated launcher puts its whole dependency closure on
  # LD_LIBRARY_PATH, including a stale libnss.  Browsers spawned via xdg-open
  # inherit it and then load that libnss instead of their own, which makes
  # Firefox fail with "Couldn't load XPCOM".  Shadow xdg-open so external
  # applications are launched with a clean environment.
  xdgOpen = pkgs.writeShellScriptBin "xdg-open" ''
    unset LD_LIBRARY_PATH LD_PRELOAD
    exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
  '';
in
pkgs.writeShellScriptBin "feishu-fcitx5" ''
  export QT_IM_MODULE="wayland;fcitx"
  export XMODIFIERS=@im=fcitx
  export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
  export PATH="${xdgOpen}/bin:$PATH"
  # Do not exec through `zsh -l`: when Feishu is started from wofi the
  # environment lacks __NIXOS_SET_ENVIRONMENT_DONE, so the login shell
  # re-sources /etc/set-environment and overwrites PATH, dropping the
  # xdg-open shadow above (the terminal case already exported the guard,
  # which is why it worked there).
  exec ${pkgs.feishu}/opt/bytedance/feishu/bytedance-feishu "$@"
''
