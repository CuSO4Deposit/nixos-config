{
  enable = true;
  settings = {
    vendors = {
      deepseek = {
        __inherited_from = "openai";
        api_key_name = "DEEPSEEK_API_KEY";
        endpoint = "https://api.deepseek.com";
        model = "deepseek-coder";
        temperature = 0;
        stream = true;
      };
    };
    diff = {
      autojump = true;
      debug = false;
      list_opener = "copen";
    };
    highlights = {
      diff = {
        current = "DiffText";
        incoming = "DiffAdd";
      };
    };
    hints = {
      enabled = true;
    };
    mappings = {
      diff = {
        both = "cb";
        next = "]x";
        none = "c0";
        ours = "co";
        prev = "[x";
        theirs = "ct";
      };
    };
    provider = "deepseek";
    windows = {
      sidebar_header = {
        align = "center";
        rounded = true;
      };
      width = 30;
      wrap = true;
    };
  };
}

