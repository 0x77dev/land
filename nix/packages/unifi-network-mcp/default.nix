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
  pname = "unifi-network-mcp";
  # renovate: datasource=pypi depName=unifi-network-mcp versioning=pep440
  version = "0.14.9";
  pyproject = true;

  src = fetchPypi {
    inherit version;
    pname = "unifi_network_mcp";
    hash = "sha256-r/VIIj9d1Gr6e9E8GmMe+Q2oUi9O6kIgaLDDxgzxlns=";
  };

  build-system = with py; [
    hatchling
    py."hatch-vcs"
  ];

  dependencies = [
    py.aiohttp
    py.aiounifi
    py.jsonschema
    py.mcp
    py.omegaconf
    py."python-dotenv"
    py.pyyaml
    py."typing-extensions"
    pkgs.${namespace}."unifi-core"
    pkgs.${namespace}."unifi-mcp-shared"
  ];

  pythonRelaxDeps = [ "mcp" ];

  pythonImportsCheck = [ "unifi_network_mcp" ];

  meta = with lib; {
    description = "UniFi Network MCP server";
    homepage = "https://github.com/sirkirby/unifi-mcp";
    license = licenses.mit;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
    mainProgram = "unifi-network-mcp";
  };
}
