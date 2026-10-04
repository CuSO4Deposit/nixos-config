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

    xdg.configFile."opencode/AGENTS.md".text = ''
      # AGENTS.md

      ## Environment

      - Unless explicitly stated otherwise for the current task, the machine running
        this session is ${if local then "macOS (nix-darwin)" else "NixOS Linux"} with Nix Flakes enabled.
      - To use a tool that is not already installed, run it ad hoc with
        `${shellTool}<package> -c <command>` instead of installing it globally.
      - If several such tools are needed at once, combine them into a single
        invocation.

      ## Collaboration

      - Other people you collaborate with do not use NixOS.
      - Do not introduce NixOS-specific artifacts (e.g. `flake.nix`, `shell.nix`,
        `nix develop`/`nix-shell`), or change shared build/tooling files to depend on
        Nix, unless explicitly asked to.
    '';

    xdg.configFile."opencode/agents/research.md".text = ''
      ---
      description: Research and investigate codebases, gather context, and answer questions without making changes
      mode: subagent
      permission:
        edit: deny
        bash: allow
      ---

      You are a research agent. Your job is to explore codebases, gather context, read documentation, and provide thorough answers to questions.

      Focus on:
      - Reading and understanding code structure
      - Finding relevant files and patterns
      - Answering questions about how things work
      - Providing context for decision-making

      You do not make changes to files. You only read and report.
    '';

    xdg.configFile."opencode/agents/code.md".text = ''
      ---
      description: Write, edit, and implement code changes with full tool access
      mode: subagent
      permission:
        edit: allow
        bash: allow
      ---

      You are a code implementation agent. Your job is to write, edit, and implement code changes.

      Focus on:
      - Writing clean, correct code
      - Following existing project conventions
      - Making targeted, minimal changes
      - Ensuring changes are complete and working
    '';
  };
}
