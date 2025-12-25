{ fetchgit, oh-my-zsh, ... }:
oh-my-zsh.overrideAttrs (
  _: _:
  let
    cphoen-zsh-theme = fetchgit {
      deepClone = false;
      hash = "sha256-MIU+rVTn+Cx+JXoAXw5VuuxcJCobZp3xe7amwzCXejI=";
      rev = "10788c73e2f472164aa2ddd8dcbd338fe18d5fe3";
      url = "https://codeberg.org/cocvu/cphoen.zsh-theme";
    };
  in
  {
    # https://github.com/NixOS/nixpkgs/blob/b27ba4eb322d9d2bf2dc9ada9fd59442f50c8d7c/pkgs/by-name/oh/oh-my-zsh/package.nix#L36
    pname = "oh-cus-zsh";
    installPhase = ''
      runHook preInstall

      outdir=$out/share/oh-my-zsh
      template=templates/zshrc.zsh-template

      mkdir -p $outdir
      cp -r * $outdir
      cd $outdir

      rm LICENSE.txt
      rm -rf .git*

      chmod -R +w templates

      # Change the path to oh-my-zsh dir and disable auto-updating.
      sed -i -e "s#ZSH=\$HOME/.oh-my-zsh#ZSH=$outdir#" \
             -e 's/\# \(DISABLE_AUTO_UPDATE="true"\)/\1/' \
       $template

      chmod +w oh-my-zsh.sh

      # Both functions expect oh-my-zsh to be in ~/.oh-my-zsh and try to
      # modify the directory.
      cat >> oh-my-zsh.sh <<- EOF

      # Undefine functions that don't work on Nix.
      unfunction uninstall_oh_my_zsh
      unfunction upgrade_oh_my_zsh
      EOF

      # Look for .zsh_variables, .zsh_aliases, and .zsh_funcs, and source
      # them, if found.
      cat >> $template <<- EOF

      # Load the variables.
      if [ -f ~/.zsh_variables ]; then
          . ~/.zsh_variables
      fi

      # Load the functions.
      if [ -f ~/.zsh_funcs ]; then
        . ~/.zsh_funcs
      fi

      # Load the aliases.
      if [ -f ~/.zsh_aliases ]; then
          . ~/.zsh_aliases
      fi
      EOF

      # Load my theme.
      cp ${cphoen-zsh-theme}/cphoen.zsh-theme $outdir/themes

      runHook postInstall
    '';
  }
)
