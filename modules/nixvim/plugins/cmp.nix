{
  autoEnableSources = true;
  enable = true;
  settings = {
    sources = [
      { name = "nvim_lsp"; }
      { name = "luasnip"; }
      { name = "buffer"; }
      { name = "path"; }
      # { name = "cmdline"; } # This is causing unwanted completions. See
                              # https://github.com/hrsh7th/nvim-cmp/issues/1324
    ];
    mapping = {
      "<Enter>" = "cmp.mapping.confirm({ select = false })";
      "<S-Tab>" = ''
        cmp.mapping(function(fallback)
          local luasnip = require 'luasnip'
          if cmp.visible() then
	        cmp.select_prev_item()
          elseif luasnip.locally_jumpable(-1) then
	        luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" })'';
      "<Tab>" = ''
        cmp.mapping(function(fallback)
          local luasnip = require 'luasnip'
          if cmp.visible() then
	        cmp.select_next_item()
          elseif luasnip.locally_jumpable(1) then
            luasnip.jump(1)
          else
            fallback()
          end
        end, { "i", "s" })'';
    };
    snippet.expand = ''
      function(args)
        require('luasnip').lsp_expand(args.body)
      end
      '';
    window = let 
        cmp_config_window = ''function(opts)
        opts = opts or {}
        return {
          border = opts.border or 'rounded',
          winhighlight = opts.winhighlight or 'Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None',
          zindex = opts.zindex or 1001,
          scrolloff = opts.scrolloff or 0,
          col_offset = opts.col_offset or 0,
          side_padding = opts.side_padding or 1,
          scrollbar = opts.scrollbar == nil and true or opts.scrollbar,
        }
      end'';
      in {
      completions = {
        border = "rounded";
        col_offset = 0;
        side_padding = 1;
        scrollbar = true;
      };
      documentation = {
        border = "rounded";
        col_offset = 0;
        side_padding = 1;
        scrollbar = true;
      };
    };
  };
}
