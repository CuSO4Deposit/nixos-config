{
  pkgs,
  config,
  inputs,
  ...
}:
let
  pkgs-opencode = import inputs.nixpkgs-opencode {
    system = pkgs.stdenv.hostPlatform.system;
  };
  serper-mcp = pkgs.callPackage ../derivations/serper-search-scrape-mcp { };
  serper-mcp-with-key = pkgs.writeShellScriptBin "serper-mcp" ''
    secretFile=${config.age.secrets."serper-api-key".path}
    if [ -z "''${SERPER_API_KEY:-}" ]; then
      export SERPER_API_KEY="$(${pkgs.coreutils}/bin/cat "$secretFile" 2>/dev/null || true)"
    fi
    exec ${serper-mcp}/bin/serper-mcp "$@"
  '';
in
{
  age.secrets."serper-api-key" = {
    file = ../secrets/serper-api-key.age;
    owner = "cuso4d";
  };

  environment.systemPackages = [ pkgs.opencode ];

  nixpkgs.overlays = [
    (_: _: {
      # Pull opencode from a nixpkgs rev that already ships 1.18.31.
      # Remove once nixos-unstable catches up.
      opencode = pkgs-opencode.opencode;
    })
  ];

  # The opencode config itself lives in home/common/opencode.nix (shared with
  # macOS). Only the serper MCP is Linux-only because it needs an agenix secret.
  home-manager.users.cuso4d.nightcord.opencode.serperMcp = "${serper-mcp-with-key}/bin/serper-mcp";
}
