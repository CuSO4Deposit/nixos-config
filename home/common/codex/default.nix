{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.nightcord.codex;
  provider = "penguin-gpt";
  profile = "gpt-6-1-sol";
  configFile = (pkgs.formats.toml { }).generate "config.toml" (
    {
      model = "gpt-6-astra";
      model_provider = provider;
      model_reasoning_effort = "medium";
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

      model_providers.${provider} = {
        name = "Penguin API";
        base_url = "https://penguinapi.vip/v1";
        env_key = "PENGUIN_OPENAI_API_KEY";
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
  profileFile = (pkgs.formats.toml { }).generate "${profile}.config.toml" {
    model = "gpt-6.1-sol";
    model_provider = provider;
  };
in
{
  options.nightcord.codex.serperMcp = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Path to the serper MCP binary, set by hosts that provision the API key.";
  };

  config = {
    home.file.".codex/AGENTS.md".source = config.nightcord.agents.instructions;
    home.file.".codex/config.toml".source = configFile;
    home.file.".codex/${profile}.config.toml".source = profileFile;
    home.file.".codex/themes/tokyonight-night.tmTheme".source = ./tokyonight-night.tmTheme;
  };
}
