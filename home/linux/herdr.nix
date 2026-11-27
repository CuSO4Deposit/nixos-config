{ pkgs, ... }:
{
  imports = [ ../common/herdr ];

  systemd.user.services.herdr = {
    Unit = {
      Description = "Herdr terminal workspace server";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.herdr}/bin/herdr server";
      ExecStop = "${pkgs.herdr}/bin/herdr server stop";
      ExecCondition = "${pkgs.bash}/bin/bash -c '! ${pkgs.herdr}/bin/herdr status server >/dev/null 2>&1'";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.file.".zshrc.local".text = ''
    if [[ $HERDR_ENV == 1 ]]; then
      for _herdr_env in ''${(f)"$(${pkgs.systemd}/bin/systemctl --user show-environment 2>/dev/null)"}; do
        _herdr_key=''${_herdr_env%%=*}
        case $_herdr_key in
          DISPLAY|WAYLAND_DISPLAY|DBUS_SESSION_BUS_ADDRESS|HYPRLAND_INSTANCE_SIGNATURE|XDG_CURRENT_DESKTOP|XDG_RUNTIME_DIR|XDG_SESSION_TYPE|SSH_AUTH_SOCK)
            export "$_herdr_env"
            ;;
        esac
      done
      unset _herdr_env _herdr_key
    fi
  '';
}
