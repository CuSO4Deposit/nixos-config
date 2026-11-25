{ ... }:
let
  desktopKeys = {
    global = {
      "alt-1" = "space.select:1";
      "alt-2" = "space.select:2";
      "alt-3" = "space.select:3";
      "alt-4" = "space.select:4";
      "alt-5" = "space.select:5";
      "alt-6" = "space.select:6";
      "alt-7" = "space.select:7";
      "alt-8" = "space.select:8";
      "alt-9" = "space.select:9";

      "ctrl-alt-1" = "space.select:1";
      "ctrl-alt-2" = "space.select:2";
      "ctrl-alt-3" = "space.select:3";
      "ctrl-alt-4" = "space.select:4";
      "ctrl-alt-5" = "space.select:5";
      "ctrl-alt-6" = "space.select:6";
      "ctrl-alt-7" = "space.select:7";
      "ctrl-alt-8" = "space.select:8";
      "ctrl-alt-9" = "space.select:9";

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

      "ctrl-1" = "tab.select:1";
      "ctrl-2" = "tab.select:2";
      "ctrl-3" = "tab.select:3";
      "ctrl-4" = "tab.select:4";
      "ctrl-5" = "tab.select:5";
      "ctrl-6" = "tab.select:6";
      "ctrl-7" = "tab.select:7";
      "ctrl-8" = "tab.select:8";
      "ctrl-9" = "tab.select:9";
      "alt-[" = "tab.prev";
      "alt-]" = "tab.next";

      "alt-up" = "space.prev";
      "alt-down" = "space.next";

      "alt-c" = "tab.new";
      "alt-shift-c" = "space.new";
      "alt-n" = "tab.rename";
      "alt-shift-n" = "space.rename";
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
      "ctrl-shift-w" = "tab.close";
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
  xdg.configFile = {
    "herdr/config.toml" = {
      force = true;
      text = ''
        onboarding = false

        [theme]
        name = "tokyo-night"
        auto_switch = false

        [ui]
        prompt_new_workspace_name = true
        prompt_new_tab_name = true

        [keys]
        focus_pane_left = ["prefix+h", "alt+h"]
        focus_pane_down = ["prefix+j", "alt+j"]
        focus_pane_up = ["prefix+k", "alt+k"]
        focus_pane_right = ["prefix+l", "alt+l"]

        previous_tab = ["prefix+p", "alt+left"]
        next_tab = ["prefix+n", "alt+right"]
        switch_tab = "ctrl+1..9"

        previous_workspace = "alt+up"
        next_workspace = "alt+down"
        switch_workspace = "ctrl+alt+1..9"
        workspace_picker = ["prefix+w", "ctrl+alt+w"]
        goto = ["prefix+g", "ctrl+alt+g"]

        new_tab = ["prefix+c", "alt+c"]
        new_workspace = ["prefix+shift+n", "alt+shift+c"]
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
