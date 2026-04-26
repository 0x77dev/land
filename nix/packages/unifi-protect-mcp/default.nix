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
  uiprotectPackage = py.uiprotect.overridePythonAttrs (_: {
    doCheck = false;
    doInstallCheck = false;
  });
in
py.buildPythonApplication rec {
  pname = "unifi-protect-mcp";
  # renovate: datasource=pypi depName=unifi-protect-mcp versioning=pep440
  version = "0.3.2";
  pyproject = true;

  src = fetchPypi {
    inherit version;
    pname = "unifi_protect_mcp";
    hash = "sha256-RmrlsOEyGfdlchLr0UddOXA47divbVPMizSfYOzLOFw=";
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
    py."python-dotenv"
    py.pyyaml
    py."typing-extensions"
    uiprotectPackage
    pkgs.${namespace}."unifi-core"
    pkgs.${namespace}."unifi-mcp-shared"
  ];

  pythonRelaxDeps = [ "mcp" ];

  pythonImportsCheck = [ "unifi_protect_mcp" ];

  meta = with lib; {
    description = "UniFi Protect MCP server";
    homepage = "https://github.com/sirkirby/unifi-mcp";
    license = licenses.mit;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
    mainProgram = "unifi-protect-mcp";
  };
}
