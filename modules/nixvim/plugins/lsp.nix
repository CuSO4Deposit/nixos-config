{
  enable = true;
  keymaps = {
    diagnostic = {
      "<leader>k" = "goto_prev";
      "<leader>j" = "goto_next";
    };
    extra = [
      {
        action = {
          __raw = ''function()
          local float = vim.diagnostic.config().float

          if float then
            local config = type(float) == "table" and float or {}
            config.scope = "line"

            vim.diagnostic.open_float(config)
          end
        end'';
          };
        key = "<leader>l";
      }
    ];
    lspBuf = {
      gd = "definition";
      gD = "declaration";
      gt = "type_definition";
      gi = "implementation";
      K = "hover";
      "<F2>" = "rename";
    };
  };
  servers = {
    clangd.enable = true;
    nixd.enable = true;
    tinymist = {
      enable = true;
      settings.offset_encoding = "utf-8";
    };
    pyright.enable = true;
  };
}
