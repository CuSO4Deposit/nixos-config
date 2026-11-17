{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.nightcord.codex;
  home = config.home.homeDirectory;
  gptProvider = "penguin-gpt";
  deepseekProvider = "deepseek";
  bundledModels = pkgs.writeShellScript "codex-bundled-models" ''
    export HOME="$TMPDIR"
    export CODEX_HOME="$TMPDIR/codex-home"
    mkdir -p "$CODEX_HOME"
    printf 'model = "deepseek-flash"\n' > "$CODEX_HOME/config.toml"
    ${pkgs.codex}/bin/codex debug models
  '';
  deepseekCatalog = pkgs.runCommand "deepseek-models.json" { } ''
    ${bundledModels} > "$TMPDIR/bundled.json"
    ${pkgs.jq}/bin/jq -f ${./deepseek-catalog.jq} "$TMPDIR/bundled.json" > $out
  '';
  gptCatalog = pkgs.runCommand "gpt-models.json" { } ''
    ${bundledModels} > "$TMPDIR/bundled.json"
    ${pkgs.jq}/bin/jq -f ${./gpt-catalog.jq} "$TMPDIR/bundled.json" > $out
  '';
  settings = {
    model = "deepseek-flash";
    model_provider = deepseekProvider;
    model_reasoning_effort = "high";
    model_catalog_json = "${home}/.codex/deepseek-models.json";
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
      wire_api = "responses";
    };

    features = {
      multi_agent = true;
      terminal_resize_reflow = true;
    };
  }
  // lib.optionalAttrs (cfg.serperMcp != null) {
    mcp_servers.serper.command = cfg.serperMcp;
  };
  gptWrapper = pkgs.writeShellScriptBin "codex-gpt" ''
    exec ${pkgs.codex}/bin/codex \
      -c 'model_provider="${gptProvider}"' \
      -c 'model="gpt-6-astra"' \
      -c 'model_catalog_json="${home}/.codex/gpt-models.json"' \
      -c 'model_reasoning_effort="medium"' \
      "$@"
  '';
in
{
  options.nightcord.codex.serperMcp = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Path to the serper MCP binary, set by hosts that provision the API key.";
  };

  config = {
    programs.codex = {
      enable = true;
      package = null;
      mutableSettings = true;
      inherit settings;
    };

    home.packages = [ gptWrapper ];

    home.file = {
      ".codex/AGENTS.md".source = config.nightcord.agents.instructions;
      ".codex/themes/tokyonight-night.tmTheme".source = ./tokyonight-night.tmTheme;
      ".codex/deepseek-models.json".source = deepseekCatalog;
      ".codex/gpt-models.json".source = gptCatalog;
    };
  };
}
