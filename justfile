default:
  just --list

switch:
  nixos-rebuild switch --flake .#$(hostname) --sudo
  mkdir -p locks
  cp flake.lock locks/$(hostname | cut -d'-' -f2)/flake.lock
  git add .
  git commit -v

test:
  git add .
  nixos-rebuild test --flake .#$(hostname) --sudo

build-runner-1:
  nixos-rebuild build --flake .#$(hostname) --sudo --max-jobs 1

switch-remote host="proximo":
  nixos-rebuild switch --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}}
  mkdir -p locks
  cp flake.lock locks/{{host}}/flake.lock
  git add .
  git commit -v

test-remote host="proximo":
    git add .
    nixos-rebuild test --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}}

# Remote hosts that are not NixOS (e.g. racknerd) can't take a nixosConfiguration.
# Build the standalone home-manager generation here, copy the closure over ssh and
# activate it there. Only Nix is required on the target; the home-manager CLI is not.
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

switch-cached:
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild switch --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file
  mkdir -p locks
  cp flake.lock locks/$(hostname | cut -d'-' -f2)/flake.lock
  git add -A flake.lock locks/$(hostname | cut -d'-' -f2)
  git commit -v

test-cached:
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild test --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file

switch-remote-cached host="proximo":
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild switch --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}} --no-update-lock-file --no-write-lock-file
  mkdir -p locks
  cp flake.lock locks/{{host}}/flake.lock
  git add -A flake.lock locks/{{host}}
  git commit -v

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

test-nocache:
  cp locks/$(hostname | cut -d'-' -f2)/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild test --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file {{NOCACHE_OPTS}}

switch-nocache:
  cp locks/$(hostname | cut -d'-' -f2)/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild switch --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file {{NOCACHE_OPTS}}

alias s := switch
alias t := test
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
