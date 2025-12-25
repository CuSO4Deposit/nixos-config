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
    pname = "oh-cus-zsh";

    postInstall = ''
      mkdir -p $out/share/oh-my-zsh/themes
      cp ${cphoen-zsh-theme}/cphoen.zsh-theme $out/share/oh-my-zsh/themes/cphoen.zsh-theme
    '';
  }
)
