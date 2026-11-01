{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.nightcord.opencode;
  local = pkgs.stdenv.hostPlatform.isDarwin;
  shellTool = if local then "brew" else "nix shell nixpkgs#";
in

{
  options.nightcord.opencode.serperMcp = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Path to the serper MCP binary. Linux only (needs agenix).";
  };

  config = {
    xdg.configFile."opencode/tui.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/tui.json";
      theme = "tokyonight";
      leader_timeout = 2000;
      keybinds = {
        leader = "ctrl+x";
        command_list = "ctrl+p";
        editor_open = "ctrl+g";
        messages_first = "none";
        messages_last = "ctrl+alt+g";
      };
      scroll_speed = 3;
      scroll_acceleration = {
        enabled = false;
      };
      diff_style = "auto";
      mouse = true;
      attention = {
        enabled = true;
        notifications = true;
        sound = true;
        volume = 0.4;
        sound_pack = "opencode.default";
        sounds = {
          error = "./sounds/error.mp3";
        };
      };
    };

    xdg.configFile."opencode/opencode.jsonc".text = builtins.toJSON (
      {
        "$schema" = "https://opencode.ai/config.json";
        lsp = {
          pyright = {
            command = [
              "${pkgs.pyright}/bin/pyright-langserver"
              "--stdio"
            ];
            extensions = [
              ".py"
              ".pyi"
            ];
          };
        };
        formatter = {
          prettier = {
            command = [
              "${pkgs.prettier}/bin/prettier"
              "--write"
              "$FILE"
            ];
            extensions = [
              ".md"
              ".json"
              ".jsonc"
              ".yaml"
              ".yml"
              ".html"
              ".css"
            ];
          };
        };
      }
      // lib.optionalAttrs (cfg.serperMcp != null) {
        mcp.serper = {
          type = "local";
          command = [ cfg.serperMcp ];
        };
      }
    );

    xdg.configFile."opencode/AGENTS.md".source = pkgs.replaceVars ./AGENTS.md {
      platform = if local then "macOS (nix-darwin)" else "NixOS Linux";
      shellTool = shellTool;
    };

    xdg.configFile."opencode/agents/research.md".source = ./agents/research.md;

    xdg.configFile."opencode/agents/code.md".source = ./agents/code.md;
  };
}
