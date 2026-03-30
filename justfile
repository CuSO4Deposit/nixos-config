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
  nixos-rebuild switch --flake .#$(hostname) --sudo
  mkdir -p locks
  mv flake.lock locks/$(hostname | cut -d'-' -f2)
  git add .
  git commit -v

test-cached:
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  nixos-rebuild test --flake .#$(hostname) --sudo

switch-remote-cached host="proximo":
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  nixos-rebuild switch --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}}
  mkdir -p locks
  mv flake.lock locks/{{host}}
  git add .
  git commit -v

test-remote-cached host="proximo":
  cp /var/lib/nix-auto-build/flake.lock flake.lock
  nixos-rebuild test --flake .#nightcord-{{host}} --sudo --ask-sudo-password --target-host {{host}}

alias s := switch
alias t := test
alias sr := switch-remote
alias tr := test-remote
alias sc := switch-cached
alias tc := test-cached
alias src := switch-remote-cached
alias trc := test-remote-cached
