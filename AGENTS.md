# AGENTS.md

This file provides information for AI agents to understand and contribute to
this project.

## Project Overview

This repository contains a NixOS configuration managed with Nix Flakes. It is
designed to be modular and reusable across multiple hosts.

## Project Structure

- `flake.nix`: The main entry point for the Nix Flake. It defines the inputs,
outputs, and system configurations.
- `configuration.nix`: The base NixOS configuration that is shared across all
hosts.
- `hosts/`: Contains host-specific configurations. Each file corresponds to a
different machine.
  - `hosts/modules/`: Contains reusable modules for different types of
    hosts, such as "desktop", "laptop", or "server". These modules provide
    general settings for a class of machine.
- `home/`: Contains the home-manager configuration. This is primarily used
for hosts with a graphical user interface (GUI) and manages GUI-related
applications, dotfiles, and user-specific packages.
- `secrets/`: Contains secrets encrypted with `agenix`. These are decrypted
at build time.
- `derivations/`: Contains custom Nix derivations for packages not available
in nixpkgs or that require customization.
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
`hosts/new-host.nix`).
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
in `configuration.nix` or in a host-specific configuration file.
- User-specific packages should be added in the `home/` configuration using
home-manager.

## Pre-commit Hooks

This project uses `pre-commit-hooks.nix` to ensure code quality and
consistency. The hooks are defined in `flake.nix` and are run automatically on
every commit.

To run the hooks manually, you can use the `pre-commit` command, for example:
`pre-commit run --all-files`.
