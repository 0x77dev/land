{ ... }: {
  users.groups.github-runner = { };

  users.users.github-runner = {
    isSystemUser = true;
    group = "github-runner";
    home = "/home/github-runner";
    createHome = true;
  };

  services.github-runners.land = {
    enable = true;
    url = "https://github.com/0x77dev/land";
    name = "tomato";
    tokenFile = "/run/secrets/github-runner/token";
    user = "github-runner";
    group = "github-runner";
    replace = true;
    extraLabels = [ "home-lab" ];
  };
}
