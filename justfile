# List recipes.
default:
  just --list

# Switch the current host, snapshot flake.lock to locks/<host>, and commit.
switch:
  nixos-rebuild switch --flake .#$(hostname) --sudo
  mkdir -p locks
  cp flake.lock locks/$(hostname | cut -d'-' -f2)/flake.lock
  git add .
  git commit -v

# Activate the current host for this boot only; does not commit.
test:
  git add .
  nixos-rebuild test --flake .#$(hostname) --sudo

# Switch `neo` with darwin-rebuild, reload AeroSpace, snapshot the lock, and commit.
switch-mac:
  sudo darwin-rebuild switch --flake .#nightcord-neo
  aerospace reload-config || true
  mkdir -p locks/neo
  cp flake.lock locks/neo/flake.lock
  git add .
  git commit -v

# Build `neo` without activating it.
test-mac:
  darwin-rebuild build --flake .#nightcord-neo

# Build the current host with --max-jobs 1.
build-runner-1:
  nixos-rebuild build --flake .#$(hostname) --sudo --max-jobs 1

# Switch another NixOS host over ssh (default `proximo`), snapshot the lock, and commit.
switch-remote host="proximo":
  nixos-rebuild switch --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}}
  mkdir -p locks
  cp flake.lock locks/{{host}}/flake.lock
  git add .
  git commit -v

# Activate another NixOS host over ssh for this boot only (default `proximo`).
test-remote host="proximo":
    git add .
    nixos-rebuild test --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}}

# The target needs only Nix; the home-manager CLI is not required.

# Build, copy over ssh, and activate a standalone home-manager generation on a non-NixOS host (default `racknerd`); commits.
switch-hm host="racknerd":
  #!/usr/bin/env bash
  set -euo pipefail
  git add .
  p=$(nix build --no-link --print-out-paths '.#homeConfigurations."CuSO4D@{{host}}".activationPackage')
  nix copy --to ssh://{{host}} "$p"
  ssh {{host}} "export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus; $p/activate"
  mkdir -p locks/{{host}}
  cp flake.lock locks/{{host}}/flake.lock
  git add .
  git commit -v

# Switch the current host reusing the lock built by the internal cache; commits.
switch-cached:
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild switch --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file
  mkdir -p locks
  cp flake.lock locks/$(hostname | cut -d'-' -f2)/flake.lock
  git add -A flake.lock locks/$(hostname | cut -d'-' -f2)
  git commit -v

# Test the current host against the internal cache's lock.
test-cached:
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild test --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file

# Switch a remote NixOS host reusing the internal cache's lock (default `proximo`); commits.
switch-remote-cached host="proximo":
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild switch --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}} --no-update-lock-file --no-write-lock-file
  mkdir -p locks
  cp flake.lock locks/{{host}}/flake.lock
  git add -A flake.lock locks/{{host}}
  git commit -v

# Test a remote NixOS host against the internal cache's lock (default `proximo`).
test-remote-cached host="proximo":
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild test --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}} --no-update-lock-file --no-write-lock-file

# Rebuild without consulting the internal binary cache. Use when the cache is
# unreachable (dead office tunnel / hung MinIO mount): a stalled substituter
# otherwise costs a per-narinfo timeout and the build appears to hang. Pins the
# lock to locks/<host> so no input is refetched. `substituters` must be set
# explicitly rather than clearing `extra-substituters`, which nix ignores here.
NOCACHE_OPTS := "--option substituters 'https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store' --option extra-substituters ''"

# Test the current host without the internal cache, using locks/<host>.
test-nocache:
  cp locks/$(hostname | cut -d'-' -f2)/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild test --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file {{NOCACHE_OPTS}}

# Switch the current host without the internal cache, using locks/<host>; commits.
switch-nocache:
  cp locks/$(hostname | cut -d'-' -f2)/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild switch --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file {{NOCACHE_OPTS}}

alias s := switch
alias t := test
alias sm := switch-mac
alias tm := test-mac
alias br1 := build-runner-1
alias sr := switch-remote
alias tr := test-remote
alias sc := switch-cached
alias tc := test-cached
alias src := switch-remote-cached
alias trc := test-remote-cached
alias srh := switch-hm
alias snc := switch-nocache
alias tnc := test-nocache
