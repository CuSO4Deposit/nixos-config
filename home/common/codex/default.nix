{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.nightcord.codex;
  gptProvider = "penguin-gpt";
  deepseekProvider = "deepseek";
  profileNames = [
    "gpt-6-astra"
    "gpt-6-1-sol"
    "deepseek-v4-pro"
  ];
  profileFor = {
    gpt-6-astra = {
      model = "gpt-6-astra";
      model_provider = gptProvider;
      model_reasoning_effort = "medium";
    };
    gpt-6-1-sol = {
      model = "gpt-6.1-sol";
      model_provider = gptProvider;
      model_reasoning_effort = "medium";
    };
    deepseek-v4-pro = {
      model = "deepseek-v4-pro";
      model_provider = deepseekProvider;
      model_reasoning_effort = "high";
    };
  };
  mkProfile = name: (pkgs.formats.toml { }).generate "${name}.config.toml" profileFor.${name};
  configFile = (pkgs.formats.toml { }).generate "config.toml" (
    {
      model = "deepseek-flash";
      model_provider = deepseekProvider;
      model_reasoning_effort = "high";
      approval_policy = "never";
      sandbox_mode = "danger-full-access";

      tui = {
        theme = "tokyonight-night";
        status_line = [
          "model"
          "current-dir"
          "git-branch"
          "context-used"
        ];
      };

      model_providers.${gptProvider} = {
        name = "Penguin API";
        base_url = "https://penguinapi.vip/v1";
        env_key = "PENGUIN_OPENAI_API_KEY";
      };
      model_providers.${deepseekProvider} = {
        name = "DeepSeek";
        base_url = "https://api.deepseek.com/v1";
        env_key = "DEEPSEEK_API_KEY";
      };

      features = {
        multi_agent = true;
        terminal_resize_reflow = true;
      };
    }
    // lib.optionalAttrs (cfg.serperMcp != null) {
      mcp_servers.serper.command = cfg.serperMcp;
    }
  );
in
{
  options.nightcord.codex.serperMcp = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Path to the serper MCP binary, set by hosts that provision the API key.";
  };

  config = {
    home.file = {
      ".codex/AGENTS.md".source = config.nightcord.agents.instructions;
      ".codex/config.toml".source = configFile;
      ".codex/themes/tokyonight-night.tmTheme".source = ./tokyonight-night.tmTheme;
    }
    // lib.listToAttrs (
      map (name: {
        name = ".codex/${name}.config.toml";
        value.source = mkProfile name;
      }) profileNames
    );
  };
}
