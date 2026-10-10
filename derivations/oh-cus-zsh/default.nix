{ fetchFromCodeberg, oh-my-zsh, ... }:
oh-my-zsh.overrideAttrs (
  _: _:
  let
    cphoen-zsh-theme = fetchFromCodeberg {
      owner = "cocvu";
      repo = "cphoen.zsh-theme";
      rev = "10788c73e2f472164aa2ddd8dcbd338fe18d5fe3";
      hash = "sha256-MIU+rVTn+Cx+JXoAXw5VuuxcJCobZp3xe7amwzCXejI=";
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
