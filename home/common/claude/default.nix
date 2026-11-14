{ config, ... }:

{
  home.file.".claude/CLAUDE.md".source = config.nightcord.agents.instructions;
}
