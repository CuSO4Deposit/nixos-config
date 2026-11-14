# AGENTS.md

NixOS and nix-darwin configuration, managed as a Nix Flake. Hosts are declared
in `flake.nix` and configured under `hosts/<name>/`.

## Commands

`just` wraps the rebuild and deploy flows; run it with no arguments to list
recipes, aliases, and their descriptions. Do not run them unless asked.

Other checks:

- Format: `nix shell nixpkgs#nixfmt-rfc-style -c nixfmt <files>`.
- Pre-commit hooks come from `cachix/git-hooks.nix`:
  `nix develop -c pre-commit run --all-files`.
- Verify an option by evaluating it, not by reading the file:
  `nix eval --json '.#nixosConfigurations.nightcord-<host>.config.<option>'`.

## Layout

- A module is `<name>.nix`; a module with data files is `<name>/default.nix`
  (e.g. `home/linux/wofi/`, `home/common/opencode/`). Import the directory.
- A new host is `hosts/<name>/default.nix` plus the name in one of
  `serverHostnames`, `wslHostnames`, `desktopHostnames` in `flake.nix`. Its
  configuration is `nightcord-<name>`.
- Secrets are `secrets/*.age`. Declare recipients in `secrets/agenix-rules.nix`
  and encrypt with `agenix -e <file>` from inside `secrets/`.

## Hosts

- Internal WireGuard network: `proximo` `10.20.0.1`, `laborari` `10.20.0.2`,
  `lexikos` `10.20.0.3`.
- Workspace 101 on `lexikos` is reserved for MagicMirror; `hosts/lexikos/`
  holds the `workspace` and `windowrule` entries.

## Backups (restic)

- `nightcord.restic-backup` (`modules/linux/restic-backup.nix`) writes one
  repository per host to `rclone:webdav:/webdav/restic/<name>` as unit
  `restic-backups-<host>`. Do not rename the unit: vita-grid probes it.
- restic deduplicates and compresses chunks itself. Do not pre-compress data
  or dumps, and write SQL dumps as plain text with `--skip-dump-date`.
- Dump live databases instead of copying their files:
  `mariadb-dump --all-databases --single-transaction --quick --skip-lock-tables`.
  Dump into a directory that is itself in `paths`, and rename atomically.
- `backupPrepareCommand` runs as systemd `preStart`; `backupCleanupCommand`
  runs as `postStop`, including when the backup fails. Use them to quiesce and
  resume.
- A backup hook belongs to the module that owns the resource, exposed as an
  option and composed explicitly in the host. e.g. `minecraft-fabric.nix` exposes
  `nightcord.minecraft-fabric.backupPrepareCommand`, `mysql-backup.nix` exposes
  `nightcord.mysql-backup.dumpDir`. The host's
  `nightcord.restic-backup.backupPrepareCommand` references them.
  Keep service internals (the console FIFO, the MariaDB client) in the owning
  module; a path hardcoded in the host drifts silently when the service changes.

## Agent workflow

- Stop after each step of a multi-step plan and let the user review and commit.
  Do not proceed automatically.
- Do not commit unless asked.
- Re-check the user's stated scope before adding paths or data sources; do not
  expand scope by inference.
