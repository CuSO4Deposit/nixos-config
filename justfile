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

alias s := switch
alias t := test
