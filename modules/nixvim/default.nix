{ pkgs, ... }:

{
  autoCmd = [
    {
      command = "set filetype=markdown";
      event = [ "BufNewFile" "BufRead" ];
      pattern = [ "*.Avante" ];
    }
  ];

  colorschemes.tokyonight = {
    enable = true;
    settings = {
      cache = true;
      style = "night";
    };
  };

  enable = true;

  files."ftplugin/nix.lua" = {
    opts.expandtab = true;
    opts.shiftwidth = 2;
    opts.tabstop = 2;
  };

  globals = {
    mapleader = " ";
  };

  opts = {
    ambiwidth = "double"; # show east asian char as double width
    autochdir = true; # auto change shell dir when file changes
    autoindent = true;
    clipboard = "unnamed"; # use register "+"
    cursorcolumn = true; # highlight current column
    cursorline = true; # highlight current line
    expandtab = true; # input spaces instead of tabs
    list = true; # show trailing characters etc.
    listchars = "tab:>-,trail:-";
    mouse = ""; # disable mouse
    number = true; # show line number
    relativenumber = true; # show line number relative to cursor
    ruler = true; # show line and column number of cursor
    shiftwidth = 4; # tabstop
    smartindent = true;
    tabstop = 4;
    title = true;
  };

  plugins = let
    path = ./plugins;
    pluginNames = [
      "avante"
      "autoclose"
      "cmp"
      "cmp-buffer"
      "cmp-nvim-lsp"
      "cmp-path"
      "cmp_luasnip"
      "comment"
      # "hardtime"
      "illuminate"
      "indent-blankline"
      "lsp"
      "lspkind"
      "lualine"
      "luasnip"
      # "markview" # for avante.nvim. It doesn't work, why?
      # "nvim-surround" # not introduced in 24.05
      "rainbow-delimiters"
      # "twilight" # I want it fancier, dimming instead of gray
      "typst-vim"
      "treesitter"
      "wakatime"
    ];
  in
  builtins.listToAttrs (map (name: {
    name = name;
    value = import "${path}/${name}.nix";
  }) pluginNames);

  # extraPlugins = with pkgs.vimPlugins; [
    # nui-nvim # required by hardtime
    # plenary-nvim # required by hardtime
  # ];
}
