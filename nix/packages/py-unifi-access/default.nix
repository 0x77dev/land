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
  pname = "py-unifi-access";
  # renovate: datasource=pypi depName=py-unifi-access versioning=pep440
  version = "1.3.0";
  format = "wheel";

  src = fetchPypi {
    inherit version format;
    pname = "py_unifi_access";
    dist = "py3";
    python = "py3";
    hash = "sha256-lQcLdCO+uMUltraB+tV+C5lfSImi/6PLsITI/NuBzHQ=";
  };

  dependencies = with py; [
    aiohttp
    pydantic
  ];

  pythonImportsCheck = [ "unifi_access_api" ];

  meta = with lib; {
    description = "Async Python client for the UniFi Access local API with WebSocket event support";
    homepage = "https://pypi.org/project/py-unifi-access/";
    license = licenses.mit;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
  };
}
