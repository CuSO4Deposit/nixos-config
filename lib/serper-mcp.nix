{ pkgs, secretPath }:
let
  serper-mcp = pkgs.callPackage ../derivations/serper-search-scrape-mcp { };
in
pkgs.writeShellScriptBin "serper-mcp" ''
  if [ -z "''${SERPER_API_KEY:-}" ]; then
    export SERPER_API_KEY="$(${pkgs.coreutils}/bin/cat ${secretPath} 2>/dev/null || true)"
  fi
  exec ${serper-mcp}/bin/serper-mcp "$@"
''
