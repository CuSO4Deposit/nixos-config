{ pkgs }:
pkgs.writeShellScriptBin "feishu-fcitx5" ''
  export QT_IM_MODULE="wayland;fcitx"
  export XMODIFIERS=@im=fcitx
  export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
  exec zsh -l -c ${pkgs.feishu}/opt/bytedance/feishu/bytedance-feishu "$@"
''
