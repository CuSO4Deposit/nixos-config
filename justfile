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
  git add .
  nixos-rebuild switch --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file
  mkdir -p locks
  mv flake.lock locks/$(hostname | cut -d'-' -f2)
  git add .
  git commit -v

test-cached:
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add .
  nixos-rebuild test --flake .#$(hostname) --sudo --no-update-lock-file --no-write-lock-file

switch-remote-cached host="proximo":
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add .
  nixos-rebuild switch --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}} --no-update-lock-file --no-write-lock-file
  mkdir -p locks
  mv flake.lock locks/{{host}}
  git add .
  git commit -v

test-remote-cached host="proximo":
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  git add .
  nixos-rebuild test --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}} --no-update-lock-file --no-write-lock-file

alias s := switch
alias t := test
alias br1 := build-runner-1
alias sr := switch-remote
alias tr := test-remote
alias sc := switch-cached
alias tc := test-cached
alias src := switch-remote-cached
alias trc := test-remote-cached
