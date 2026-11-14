{
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  local = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  options.nightcord.agents.instructions = lib.mkOption {
    type = lib.types.path;
    readOnly = true;
    description = "Shared AGENTS.md rendered for this host.";
    default = pkgs.replaceVars ./AGENTS.md {
      platform = if local then "macOS (nix-darwin)" else "NixOS Linux";
      shellTool = if local then "brew" else "nix shell nixpkgs#";
      hostname = lib.removePrefix "nightcord-" osConfig.networking.hostName;
    };
  };
}
