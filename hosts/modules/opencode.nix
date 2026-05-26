{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.opencode ];

  home-manager.users.cuso4d = {
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
