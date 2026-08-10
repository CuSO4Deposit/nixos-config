default:
  just --list

switch:
  nixos-rebuild switch --flake .#$(hostname) --sudo
  mkdir -p locks
  mv flake.lock locks/$(hostname | cut -d'-' -f2)
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
  mv flake.lock locks/{{host}}
  git add .
  git commit -v

test-remote host="proximo":
    git add .
    nixos-rebuild test --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}}

switch-cached:
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add flake.lock
  nixos-rebuild switch --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file
  mkdir -p locks
  mv flake.lock locks/$(hostname | cut -d'-' -f2)
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
  mv flake.lock locks/{{host}}
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
alias snc := switch-nocache
alias tnc := test-nocache
