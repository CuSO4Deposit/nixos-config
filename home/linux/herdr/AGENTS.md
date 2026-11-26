# Herdr Keybindings

- Keep keybindings consistent between `herdr/config.toml` and
  `herdr-app/keys.json`. Herdr calls a workspace, `herdr-app`
  calls it a space.
- Herdr uses `Alt` as its main modifier. Use main-modifier combinations for
  direct shortcuts; do not bind bare keys outside Herdr's prefix mode.
- Follow the letter-key patterns in `home/linux/hyprland.nix`, including its
  `HJKL` directional order, while keeping modifiers that work inside Herdr's
  terminal host.
- For corresponding tab and workspace actions, use the tab binding as the base
  and add Shift to the workspace binding.

TUI syntax uses `+` separators such as `alt+g`; `herdr-app` syntax uses `-`
separators such as `alt-g`.
