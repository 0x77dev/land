{
  lib,
  namespace,
  fetchPypi,
  python313Packages,
  ...
}:
let
  py = python313Packages;
in
py.buildPythonPackage rec {
  pname = "unifi-mcp-shared";
  # renovate: datasource=pypi depName=unifi-mcp-shared versioning=pep440
  version = "0.3.0";
  pyproject = true;

  src = fetchPypi {
    inherit version;
    pname = "unifi_mcp_shared";
    hash = "sha256-VrMXci4JQm6r59qBC+OmATEipg+d+n7DpsAqrHaLLA4=";
  };

  build-system = with py; [
    hatchling
    py."hatch-vcs"
  ];

  dependencies = [
    py.jsonschema
    py.mcp
    py.omegaconf
    py."python-dotenv"
    py.pyyaml
  ];

  pythonRelaxDeps = [ "mcp" ];

  pythonImportsCheck = [ "unifi_mcp_shared" ];

  meta = with lib; {
    description = "Shared MCP server patterns for permissions, confirmation, lazy loading, and config";
    homepage = "https://github.com/sirkirby/unifi-mcp";
    license = licenses.mit;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
  };
}
