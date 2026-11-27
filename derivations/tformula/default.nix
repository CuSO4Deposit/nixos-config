{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_24,
  python3,
}:
buildNpmPackage rec {
  pname = "tformula";
  version = "0.3.1";

  src = fetchurl {
    url = "https://github.com/mikewang817/TFormula/archive/refs/tags/v${version}.tar.gz";
    hash = "sha256-cOL69A5WvCRXdVP/ZKhNJYNCB8iAy+eGGxgp2ZbRbvI=";
  };

  npmDepsHash = "sha256-MmMWgOyWDmxKFNk49Ygy29Mh36QR/za9v9kdDWngA+E=";
  nodejs = nodejs_24;
  nativeBuildInputs = [ python3 ];

  meta = with lib; {
    description = "Render LaTeX from CLI agents directly in Kitty graphics terminals";
    homepage = "https://github.com/mikewang817/TFormula";
    license = licenses.mit;
    mainProgram = "tformula";
  };
}
