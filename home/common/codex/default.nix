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
  catalogPath = "${config.home.homeDirectory}/.codex/deepseek-models.json";
  # Derive metadata for the provider's models from the installed codex catalog so
  # the entry keeps a version-matched instructions template.
  deepseekCatalog = pkgs.runCommand "deepseek-models.json" { } ''
    export HOME="$TMPDIR"
    export CODEX_HOME="$TMPDIR/codex-home"
    mkdir -p "$CODEX_HOME"
    printf 'model = "deepseek-flash"\n' > "$CODEX_HOME/config.toml"
    ${pkgs.codex}/bin/codex debug models > "$TMPDIR/bundled.json"
    ${pkgs.jq}/bin/jq -f ${./deepseek-catalog.jq} "$TMPDIR/bundled.json" > $out
  '';
  baseSeed = pkgs.writeText "codex-config-seed.toml" ''
    model = "deepseek-flash"
  '';
  common = {
    approval_policy = "never";
    sandbox_mode = "danger-full-access";
    model_reasoning_effort = "high";

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
  };
  profileFor = {
    deepseek = {
      model_provider = deepseekProvider;
      model_catalog_json = catalogPath;
    };
    gpt = {
      model = "gpt-6-astra";
      model_provider = gptProvider;
      model_reasoning_effort = "medium";
    };
  };
  mkProfile =
    name:
    (pkgs.formats.toml { }).generate "${name}.config.toml" (
      lib.recursiveUpdate common profileFor.${name}
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
      ".codex/themes/tokyonight-night.tmTheme".source = ./tokyonight-night.tmTheme;
      ".codex/deepseek-models.json".source = deepseekCatalog;
    }
    // lib.listToAttrs (
      map (name: {
        name = ".codex/${name}.config.toml";
        value.source = mkProfile name;
      }) (lib.attrNames profileFor)
    );

    # config.toml belongs to codex once it exists; only seed it on first run.
    home.activation.codexSeedConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      config_file="${config.home.homeDirectory}/.codex/config.toml"
      if [ -L "$config_file" ]; then
        run rm -f "$config_file"
      fi
      if [ ! -e "$config_file" ]; then
        run ${pkgs.coreutils}/bin/install -m 600 ${baseSeed} "$config_file"
      fi
    '';
  };
}
