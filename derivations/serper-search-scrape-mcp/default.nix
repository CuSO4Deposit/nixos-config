{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "serper-search-scrape-mcp-server";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "marcopesani";
    repo = "mcp-server-serper";
    rev = "f18d0b108fe38110dc15ccbfe6278bb5f45a53a1";
    sha256 = "sha256-IuaonubqkdIY72dPKSihmIZrWzYjFvaK4EKqLipYjhA=";
  };

  npmDepsHash = "sha256-FpiS33BI3HoAtXm7Su7TjHLbdhJ5hEdMLURRFUX2zNM=";

  dontNpmBuild = true;

  meta = with lib; {
    description = "MCP server providing Google Search and web scraping via the Serper API";
    homepage = "https://github.com/marcopesani/mcp-server-serper";
    license = licenses.mit;
  };
}
