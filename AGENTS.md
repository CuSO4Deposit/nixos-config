# AGENTS.md

This file provides information for AI agents to understand and contribute to
this project.

## Project Overview

This repository contains a NixOS configuration managed with Nix Flakes. It is
designed to be modular and reusable across multiple hosts.

## Project Structure

- `flake.nix`: The main entry point for the Nix Flake. It defines the inputs,
  outputs, and system configurations.
- `modules/`: Reusable system modules, split by platform:
  - `modules/linux/`: NixOS modules. `modules/linux/base.nix` is the base
    configuration shared across all NixOS hosts; the rest are host-class and
    feature modules (e.g. `desktop.nix`, `internal-dns.nix`).
  - Platform-neutral modules would live in `modules/common/` (none yet).
- `home/`: home-manager configuration, split by platform:
  - `home/common/`: shared modules (e.g. `firefox.nix`, `opencode.nix`).
  - `home/linux/`: Linux desktop home (Hyprland, Waybar, ...).
  - `home/darwin/`: macOS home (AeroSpace, ghostty, zsh).
- `hosts/`: Host-specific configuration, one directory per machine regardless
  of platform (NixOS hosts plus the macOS `hosts/neo/`).
  - `hosts/<machine>/default.nix`: system entry point for that machine.
  - `hosts/<machine>/home.nix`: per-machine home-manager overrides, where used.
- `secrets/`: Contains secrets encrypted with `agenix`. These are decrypted
  at build time.
- `derivations/`: Contains custom Nix derivations for packages not available
  in nixpkgs or that require customization.
- `locks/`: Stores a copy of `flake.lock` for each host after `just switch`.
  This tracks which exact flake revision is deployed on each machine.
- `justfile`: Provides convenient commands for common tasks.

## Common Tasks

This project uses `just` as a command runner.

- `just switch`: Apply the NixOS configuration to the current host. This is a
  shortcut for `nixos-rebuild switch --flake .#$(hostname) --sudo`.
- `just test`: Test the NixOS configuration for the current host. This is a
  shortcut for `nixos-rebuild test --flake .#$(hostname) --sudo`.
- `just switch-remote [host=<hostname>]`: Apply the NixOS configuration to a
  remote host. Defaults to `proximo`.
- `just test-remote [host=<hostname>]`: Test the NixOS configuration for a
  remote host. Defaults to `proximo`.

Aliases:

- `s`: `switch`
- `t`: `test`
- `sr`: `switch-remote`
- `tr`: `test-remote`

## Adding a New Host

1. Create a new file in the `hosts/` directory for the new host (e.g.,
   `hosts/new-host/default.nix`).
2. In `flake.nix`, add the new hostname to the appropriate list
   (`serverHostnames`, `wslHostnames`, or `desktopHostnames`).
3. The new host will be available as a NixOS configuration named
   `nightcord-new-host`.

## Managing Secrets with agenix

Secrets are managed using `agenix`. They are stored in the `secrets/` directory
in an encrypted format.

- To add a new secret, you need to encrypt it with the `agenix` command-line
  tool.
- The secrets are decrypted at build time and made available to the system.
- The public keys of the hosts that are allowed to decrypt the secrets are
  also managed by `agenix`.

## Adding New Packages

- System-wide packages can be added to the `environment.systemPackages` list
  in `modules/linux/base.nix` (NixOS) or in a host-specific configuration file.
- User-specific packages should be added in the `home/` configuration using
  home-manager.

## Pre-commit Hooks

This project uses `pre-commit-hooks.nix` to ensure code quality and
consistency. The hooks are defined in `flake.nix` and are run automatically on
every commit.

To run the hooks manually, you can use the `pre-commit` command, for example:
`pre-commit run --all-files`.

## Reserved Workspaces in Hyprland

- Workspace 101: Reserved for MagicMirror (Electron app running in Docker) on
  host `lexikos` only.
  Bound to `eDP-1` (laptop screen). Configured in `hosts/lexikos/default.nix`
  via a Hyprland `workspace` entry plus a `windowrule` that matches
  `class:Electron` + `title:MagicMirror` and makes it fullscreen on workspace 101.

## Internal WireGuard Network

The following hosts are mutually reachable through the internal WireGuard
network:

- `laborari`: `10.20.0.2`
- `proximo`: `10.20.0.1`
- `lexikos`: `10.20.0.3`

## Backups (restic)

- `nightcord.restic-backup` (`modules/linux/restic-backup.nix`) writes one
  repository per host to `rclone:webdav:/webdav/restic/<name>`, as unit
  `restic-backups-<host>`. Do not rename the unit: vita-grid probes that name.
  A second site (RustFS) is **not** implemented yet; add the fan-out when it is
  actually online, not speculatively (YAGNI).
- restic is incremental, content-deduplicating, and compresses each chunk
  itself. Do not pre-compress data or dumps: it reduces deduplication, because a
  small change reshuffles the compressed stream. Write SQL dumps as plain text
  and pass `--skip-dump-date`.
- Back up live databases by dumping, not by copying files:
  `mariadb-dump --all-databases --single-transaction --quick --skip-lock-tables`.
  Dump into a directory that is itself in `paths`, and rename atomically.
- `backupPrepareCommand` runs as systemd `preStart`; `backupCleanupCommand`
  runs as `postStop`, including when the backup fails. Use them to
  quiesce/resume.
- Backup hooks belong in the module that owns the resource, exposed as an option
  and composed explicitly in the host. Examples: `minecraft-fabric.nix` exposes
  `nightcord.minecraft-fabric.backupPrepareCommand` / `backupCleanupCommand`,
  and `modules/linux/mysql-backup.nix` exposes
  `nightcord.mysql-backup.backupPrepareCommand` and `nightcord.mysql-backup.dumpDir`.
  The host's `nightcord.restic-backup.backupPrepareCommand` references them, and
  its `paths` includes `dumpDir`. Keep service internals (the console FIFO, the
  MariaDB client) inside the owning module; do not hardcode them in the host — a
  hardcoded path silently drifts if the service changes it.
- A missing source path makes restic exit 3 ("does not exist, skipping") and
  the unit show failed, even though the rest is backed up. Only list paths that
  exist on that host.
- GitHub-hosted content is not backed up separately. `ghorg` (`/data/ghorg`)
  mirrors GitHub source and _is_ backed up; exclude only the nested
  re-clonable clone (`cuso4deposit/nixpkgs`).
- `/data` btrfs snapshots come from `services.snapper.configs.data`. They are a
  versioning safety net, not a backup copy.

## Agent workflow

- After each step of a multi-step plan, stop and let the user review and commit.
  Do not proceed to the next step automatically.
- Do not commit unless asked.
- Keep plans and notes in `~/temp`, not in this repository. The backup plan is
  `~/temp/BACKUP.md`; ad-hoc temp files use `YYYY-MM-DD_snake_case.ext`.
- Re-check the user's stated scope before adding paths or data sources; do not
  expand scope by inference.

## Nix module pitfalls

- If a module declares a top-level `options` or `config` attribute, every other
  setting must be inside an explicit `config = { ... };`. Otherwise evaluation
  fails with `unsupported attribute '...' ... This is caused by introducing a
top-level 'config' or 'options' attribute`.
- Verify a change by evaluating the option, not by inspecting the file alone:
  `nix eval --json '.#nixosConfigurations.nightcord-<host>.config.services.restic.backups.<host>.paths'`
- Format with `nixfmt`:
  `nix shell nixpkgs#nixfmt-rfc-style -c nixfmt <files>`.

## Session environment

- From `laborari`, `lexikos` and `proximo` are reachable with
  `ssh -o BatchMode=yes`; `dynamica` and `neo` are not.
- WebDAV is mounted at `/mnt/work0` on `laborari`.
  `/run/agenix/rclone.conf` is root-only, so inspect repositories through the
  mount.
- `sudo` requires a password, so root-only checks (e.g. the MariaDB socket
  dump) cannot be verified locally and must be confirmed after deploy.
- A legacy `duplicity` tree also exists on WebDAV
  (`duplicity/{laborari,lexikos,proximo}`); it is not managed by this repository.
