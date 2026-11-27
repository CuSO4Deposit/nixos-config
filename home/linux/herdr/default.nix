{ pkgs, ... }:
let
  desktopKeys = {
    global = {
      "alt-1" = "tab.select:1";
      "alt-2" = "tab.select:2";
      "alt-3" = "tab.select:3";
      "alt-4" = "tab.select:4";
      "alt-5" = "tab.select:5";
      "alt-6" = "tab.select:6";
      "alt-7" = "tab.select:7";
      "alt-8" = "tab.select:8";
      "alt-9" = "tab.select:9";

      "alt-shift-1" = "space.select:1";
      "alt-shift-2" = "space.select:2";
      "alt-shift-3" = "space.select:3";
      "alt-shift-4" = "space.select:4";
      "alt-shift-5" = "space.select:5";
      "alt-shift-6" = "space.select:6";
      "alt-shift-7" = "space.select:7";
      "alt-shift-8" = "space.select:8";
      "alt-shift-9" = "space.select:9";

      "alt-h" = "pane.go:left";
      "alt-j" = "pane.go:down";
      "alt-k" = "pane.go:up";
      "alt-l" = "pane.go:right";
      "alt-left" = "tab.prev";
      "alt-right" = "tab.next";
      "alt-shift-h" = "pane.swap:left";
      "alt-shift-j" = "pane.swap:down";
      "alt-shift-k" = "pane.swap:up";
      "alt-shift-l" = "pane.swap:right";

      "alt-[" = "tab.prev";
      "alt-]" = "tab.next";

      "alt-up" = "agent.prev";
      "alt-down" = "agent.next";
      "alt-shift-up" = "space.prev";
      "alt-shift-down" = "space.next";

      "alt-c" = "tab.new";
      "alt-shift-c" = "space.new";
      "alt-n" = "tab.rename";
      "alt-shift-n" = "space.rename";
      "alt-w" = "tab.close";
      "alt-shift-w" = "space.close";
      "ctrl-alt-v" = "pane.split:right";
      "ctrl-alt--" = "pane.split:down";
      "ctrl-alt-x" = "pane.close";
      "ctrl-alt-z" = "pane.zoom";
      "ctrl-alt-g" = "mod.open:picker";
      "ctrl-alt-w" = "mod.open:picker";

      "ctrl-+" = "app.zoom_in";
      "ctrl--" = "app.zoom_out";
      "ctrl-0" = "app.zoom_reset";
      "ctrl-=" = "app.zoom_in";
      "ctrl-pagedown" = "tab.next";
      "ctrl-pageup" = "tab.prev";
      "ctrl-tab" = "tab.next";
      "ctrl-shift-tab" = "tab.prev";
      "ctrl-shift-pagedown" = "space.next";
      "ctrl-shift-pageup" = "space.prev";
      "ctrl-?" = "app.help";
      "ctrl-shift-/" = "app.help";
      "ctrl-shift-?" = "app.help";
      "ctrl-shift-b" = "layout.toggle:sidebar";
      "ctrl-shift-n" = "space.new";
      "ctrl-shift-t" = "tab.new";
      "ctrl-shift-k" = "mod.open:picker";
      "ctrl-shift-p" = "app.palette";
      "ctrl-," = "app.settings";
      "ctrl-shift-o" = "pane.split:right";
      "ctrl-shift-e" = "pane.split:down";
      "ctrl-shift-x" = "pane.close";
      "ctrl-shift-z" = "pane.zoom";
      "ctrl-shift-l" = "layout.switch";
    };

    terminal = {
      "ctrl-backspace" = "send:\u0017";
      "ctrl-left" = "send:\u001bb";
      "ctrl-right" = "send:\u001bf";
      "ctrl-shift-c" = "terminal.copy";
      "ctrl-shift-v" = "terminal.paste";
      "ctrl-shift-f" = "terminal.search";
      "ctrl-v" = "terminal.paste_image";
      "ctrl-insert" = "terminal.copy";
      "shift-insert" = "terminal.paste";
    };
  };

  desktopTheme = {
    background = "#1a1b26";
    foreground = "#a9b1d6";
    selection = "#33467c";
    cursor = "#c0caf5";
    ansi = [
      "#15161e"
      "#f7768e"
      "#9ece6a"
      "#e0af68"
      "#7aa2f7"
      "#bb9af7"
      "#7dcfff"
      "#a9b1d6"
      "#414868"
      "#f7768e"
      "#9ece6a"
      "#e0af68"
      "#7aa2f7"
      "#bb9af7"
      "#7dcfff"
      "#c0caf5"
    ];
  };
in
{
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

  xdg.configFile = {
    "herdr/config.toml" = {
      force = true;
      text = ''
        onboarding = false

        [theme]
        name = "tokyo-night"
        auto_switch = false

        [ui]
        prompt_new_workspace_name = false
        prompt_new_tab_name = true

        [keys]
        focus_pane_left = ["prefix+h", "alt+h"]
        focus_pane_down = ["prefix+j", "alt+j"]
        focus_pane_up = ["prefix+k", "alt+k"]
        focus_pane_right = ["prefix+l", "alt+l"]

        previous_tab = ["prefix+p", "alt+left"]
        next_tab = ["prefix+n", "alt+right"]
        switch_tab = "alt+1..9"

        previous_agent = "alt+up"
        next_agent = "alt+down"
        previous_workspace = "alt+shift+up"
        next_workspace = "alt+shift+down"
        switch_workspace = "alt+shift+1..9"
        workspace_picker = ["prefix+w", "ctrl+alt+w"]
        goto = ["prefix+g", "ctrl+alt+g"]

        new_tab = ["prefix+c", "alt+c"]
        new_workspace = ["prefix+shift+n", "alt+shift+c"]
        close_tab = ["prefix+shift+x", "alt+w"]
        close_workspace = ["prefix+shift+d", "alt+shift+w"]
        split_vertical = ["prefix+v", "ctrl+alt+v"]
        split_horizontal = ["prefix+minus", "ctrl+alt+minus"]
        close_pane = ["prefix+x", "ctrl+alt+x"]
        zoom = ["prefix+z", "ctrl+alt+z"]

        rename_tab = ["prefix+shift+t", "alt+n"]
        rename_workspace = ["prefix+shift+w", "alt+shift+n"]
      '';
    };

    "herdr-app/keys.json" = {
      force = true;
      text = builtins.toJSON desktopKeys + "\n";
    };

    "herdr-app/settings.json" = {
      force = true;
      text =
        builtins.toJSON {
          zoom = 1.0;
          sounds.enabled = true;
          font = "UbuntuMono Nerd Font Mono";
          font_size = 16;
          font_ligatures = false;
          minimum_contrast = 1.0;
          appearance = "dark";
          theme = "tokyo-night";
        }
        + "\n";
    };

    "herdr-app/themes/tokyo-night.json" = {
      force = true;
      text = builtins.toJSON desktopTheme + "\n";
    };
  };
}
