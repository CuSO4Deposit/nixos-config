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
  serper-mcp-with-key = import ../../lib/serper-mcp.nix {
    inherit pkgs;
    secretPath = config.age.secrets."serper-api-key".path;
  };
in
{
  age.secrets."serper-api-key" = {
    file = ../../secrets/serper-api-key.age;
    owner = "cuso4d";
  };

  environment.systemPackages = [ pkgs.opencode ];

  nixpkgs.overlays = [
    (_: _: {
      opencode = pkgs-opencode.opencode;
    })
  ];

  home-manager.users.cuso4d.nightcord.opencode.serperMcp = "${serper-mcp-with-key}/bin/serper-mcp";
}
