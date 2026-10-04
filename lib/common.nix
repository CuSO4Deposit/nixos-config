{
  username = "cuso4d";

  envVars = {
    EDITOR = "nvim";
    LESS = "-R -F -X";
  };

  shellAliases = {
    a = "opencode --auto"; # a for agent
    alg = "alias | grep";
    bat = "bat --theme=base16";
    c = "clear";
    cc0 = "curl https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt -o ./LICENSE";
    glr = "git pull --rebase";
    gmv = "git mv";
    gs = "git status --short --branch";
    j = "just";
    n = "nvim";
    nf = "nf"; # nf for nix flake, shell function to use my flake
    qa = "mkdir -p /tmp/agent && opencode --auto /tmp/agent";
    rgp = "rgp"; # rgp for ripgrep with pager
    sudonvim = "sudo -E -s nvim";
  };

  ohMyZsh = {
    plugins = [
      "direnv"
      "git"
    ];
    theme = "cphoen";
  };

  gitSettings = {
    init.defaultBranch = "main";
    rerere.enabled = true;
  };

  cliPackages = pkgs: with pkgs; [
    bat
    claude-code
    codex
    curl
    glow
    just
    mosh
    nixfmt
    ripgrep
    tldr
    yq
  ];

  fonts = pkgs: with pkgs; [
    nerd-fonts.ubuntu-mono
    noto-fonts-cjk-sans
  ];

  nvim = inputs: pkgs: inputs.cus-nixvim.packages."${pkgs.stdenv.hostPlatform.system}".nvim;

  zshInit = ''
    # Remove command lines from the history list when the first character on the line is a space,
    # or when one of the expanded aliases contains a leading space.
    setopt HIST_IGNORE_SPACE


    check_dirs_empty() {
      for dir in "$@"; do
        if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
          echo -e "\e[1;33mwarning: $dir is not empty.\e[0m"
        fi
      done
    }

    check_dirs_empty "$HOME/Downloads" "$HOME/empty"


    check_git_worktree_clean() {
      for dir in "$@"; do
        pushd $dir >/dev/null 2>&1 || continue
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          if git status --porcelain | grep -q .; then
            echo -e "\e[1;33mwarning: git tree $dir is dirty.\e[0m"
          fi
        fi
        popd >/dev/null 2>&1
      done
    }

    check_git_worktree_clean $HOME/temp $HOME/.nixos

    check_nix_auto_build() {
      local sf="/var/lib/nix-auto-build/status.json"
      [ -f "$sf" ] || return
      local failed=$(jq -r '.hosts|to_entries[]|select(.value.status=="failed")|.key' "$sf" 2>/dev/null)
      if [ -n "$failed" ]; then
        echo -e "\e[1;31mnix-auto-build: build failed for:\e[0m"
        echo "$failed" | while read h; do echo "  - $h"; done
      elif [ "$(jq -r '[.hosts[].status]|all(.=="success")' "$sf" 2>/dev/null)" = "true" ]; then
        echo -e "\e[1;32mnix-auto-build: all hosts built successfully ($(jq -r .last_run "$sf")). Run 'just switch-cached' to apply.\e[0m"
      fi
    }
    check_nix_auto_build

    rgp() { command rg --color=always "$@" | less -R; }

    SAVEHIST=50000

    # Run / develop / shell into my own flakes.
    #   nf run <attr> [args...]   -> nix run -- args
    #   nf dev [attr]             -> nix develop
    #   nf shell <attr>...        -> nix shell
    #   nf show                   -> nix flake show
    # Bare `nf run` / `nf dev` list what the default repo offers.
    : ''${MYFLAKE:=github:CuSO4Deposit/nur}

    _nf_list() { # $1 = packages | devShells | apps
      local system
      system=$(nix eval --raw --impure --expr builtins.currentSystem 2>/dev/null)
      nix flake show --json "$MYFLAKE" 2>/dev/null \
        | jq -r --arg s "$system" --arg k "$1" '.[$k][$s] // {} | keys[]'
    }

    nf() {
      local cmd=""
      if [ $# -gt 0 ]; then cmd=$1; shift; fi
      case "$cmd" in
        r|run)
          if [ -z "''${1:-}" ]; then
            echo "packages in $MYFLAKE:"; _nf_list packages
            echo; echo "usage: nf run <attr> [args...]"
            return
          fi
          nix run "$MYFLAKE#$1" -- "''${@:2}"
          ;;
        d|dev)
          if [ -z "''${1:-}" ]; then
            echo "devShells in $MYFLAKE:"; _nf_list devShells
            echo; echo "usage: nf dev [attr]"
            return
          fi
          nix develop "$MYFLAKE#$1"
          ;;
        s|shell)
          if [ -z "''${1:-}" ]; then
            echo "packages in $MYFLAKE:"; _nf_list packages
            echo; echo "usage: nf shell <attr>..."
            return
          fi
          local a=() x
          for x in "$@"; do a+=("$MYFLAKE#$x"); done
          nix shell "''${a[@]}"
          ;;
        ""|l|list|show) nix flake show "$MYFLAKE" ;;
        *) print -r -- "usage: nf {run <attr> [args...]|dev [attr]|shell <attr>...|show}" ;;
      esac
    }
  '';
}
