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
  pname = "unifi-mcp-relay";
  # renovate: datasource=pypi depName=unifi-mcp-relay versioning=pep440
  version = "0.1.2";
  pyproject = true;

  src = fetchPypi {
    inherit version;
    pname = "unifi_mcp_relay";
    hash = "sha256-t1ax/NAnJoFs62Zl2pnYaV5Da2NEbawAMeofCnaGRIE=";
  };

  build-system = with py; [
    hatchling
    py."hatch-vcs"
  ];

  dependencies = [
    py.aiohttp
    py.mcp
    py."python-dotenv"
    pkgs.${namespace}."unifi-mcp-shared"
    py.websockets
  ];

  pythonRelaxDeps = [ "mcp" ];

  pythonImportsCheck = [ "unifi_mcp_relay" ];

  meta = with lib; {
    description = "Relay that bridges local UniFi MCP servers to a Cloudflare Worker gateway";
    homepage = "https://github.com/sirkirby/unifi-mcp";
    license = licenses.mit;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
    mainProgram = "unifi-mcp-relay";
  };
}
