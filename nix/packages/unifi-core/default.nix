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
  pname = "unifi-core";
  # renovate: datasource=pypi depName=unifi-core versioning=pep440
  version = "0.1.2";
  pyproject = true;

  src = fetchPypi {
    inherit version;
    pname = "unifi_core";
    hash = "sha256-1LFIRIA3Cjenw+2M9tDBWeF3/L/lJT6ZtwgNi7ntbUY=";
  };

  build-system = with py; [
    hatchling
    py."hatch-vcs"
  ];

  dependencies = with py; [
    aiohttp
    pyyaml
  ];

  pythonImportsCheck = [ "unifi_core" ];

  meta = with lib; {
    description = "UniFi controller connectivity helpers for auth, detection, retry, and exceptions";
    homepage = "https://github.com/sirkirby/unifi-mcp";
    license = licenses.mit;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
  };
}
