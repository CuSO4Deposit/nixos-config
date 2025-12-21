{ pkgs }:
let
  fava-with-dashboards = pkgs.python313.withPackages (
    ps: with ps; [
      fava
      fava-dashboards
    ]
  );
in
pkgs.writeShellApplication {
  name = "fava-with-dashboards";
  runtimeInputs = [ fava-with-dashboards ];
  text = ''
    exec ${fava-with-dashboards}/bin/fava "$@"
  '';
}
