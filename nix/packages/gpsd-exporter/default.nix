{
  lib,
  namespace,
  buildGoModule,
  fetchFromGitHub,
  ...
}:

buildGoModule rec {
  pname = "gpsd-exporter";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "natesales";
    repo = "gpsd-exporter";
    rev = "v${version}";
    hash = "sha256-LdT+NIbjp6sjmVZxI8srU6jIvWTbZcaTtPlXUSwxuWg=";
  };

  vendorHash = "sha256-Sh1ezMMwoWjIQyquffud4upuZkukBLsVZAVdJyDWqrQ=";

  meta = with lib; {
    description = "Prometheus exporter for gpsd";
    homepage = "https://github.com/natesales/gpsd-exporter";
    license = licenses.mit;
    maintainers = with lib.${namespace}.maintainers; [ mykhailo ];
    mainProgram = "gpsd-exporter";
  };
}
