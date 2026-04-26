{
  lib,
  pkgs,
  namespace,
  fetchPypi,
  python313Packages,
  ...
}:
let
  py = python313Packages;
in
py.buildPythonApplication rec {
  pname = "unifi-access-mcp";
  # renovate: datasource=pypi depName=unifi-access-mcp versioning=pep440
  version = "0.2.1";
  pyproject = true;

  src = fetchPypi {
    inherit version;
    pname = "unifi_access_mcp";
    hash = "sha256-jqWk9F+MS7mTTmXsS+nlduqtyOdIo25p3aYOHo2preE=";
  };

  build-system = with py; [
    hatchling
    py."hatch-vcs"
  ];

  dependencies = [
    py.aiohttp
    py.jsonschema
    py.mcp
    py.omegaconf
    pkgs.${namespace}."py-unifi-access"
    py."python-dotenv"
    py.pyyaml
    py."typing-extensions"
    pkgs.${namespace}."unifi-core"
    pkgs.${namespace}."unifi-mcp-shared"
  ];

  pythonRelaxDeps = [ "mcp" ];

  pythonImportsCheck = [ "unifi_access_mcp" ];

  meta = with lib; {
    description = "UniFi Access MCP server";
    homepage = "https://github.com/sirkirby/unifi-mcp";
    license = licenses.mit;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
    mainProgram = "unifi-access-mcp";
  };
}
