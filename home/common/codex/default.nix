{ config, ... }:

{
  home.file.".codex/AGENTS.md".source = config.nightcord.agents.instructions;
}
