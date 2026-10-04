{
  pkgs,
  ...
}:

let
  common = import ../lib/common.nix;
  oh-cus-zsh = pkgs.callPackage ../derivations/oh-cus-zsh { };
in

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreSpace = true;
    };

    oh-my-zsh = {
      enable = true;
      package = oh-cus-zsh;
      inherit (common.ohMyZsh) plugins theme;
    };

    shellAliases = common.shellAliases;

    initContent = common.zshInit;
  };
}
