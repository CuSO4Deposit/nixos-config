{ ... }:
{
  xdg.configFile."herdr/config.toml" = {
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

      previous_tab = ["prefix+p", "alt+["]
      next_tab = ["prefix+n", "alt+]"]
      switch_tab = "ctrl+1..9"

      switch_workspace = "ctrl+alt+1..9"
      workspace_picker = ["prefix+w", "ctrl+alt+w"]
      goto = ["prefix+g", "ctrl+alt+g"]

      previous_agent = "alt+up"
      next_agent = "alt+down"

      new_tab = ["prefix+c", "ctrl+alt+c"]
      split_vertical = ["prefix+v", "ctrl+alt+v"]
      split_horizontal = ["prefix+minus", "ctrl+alt+minus"]
      close_pane = ["prefix+x", "ctrl+alt+x"]
      zoom = ["prefix+z", "ctrl+alt+z"]

      rename_tab = ["prefix+shift+t", "f2"]
      rename_workspace = ["prefix+shift+w", "shift+f2"]
    '';
  };
}
