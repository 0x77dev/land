{
  lib,
  namespace,
  ...
}:
let
  shared = lib.${namespace}.shared.home-config { inherit lib; };
in
{
  programs = {
    home-manager.enable = true;

    # Use local LM Studio for openclaw
    # Explicit instance works around upstream defaultInstance missing nixMode
    openclaw = {
      instances.default = { };
      config = {
        agents.defaults = {
          model.primary = "lmstudio/zai-org/glm-4.7-flash";
          models."lmstudio/zai-org/glm-4.7-flash" = { };
        };
        models.providers."lmstudio" = {
          baseUrl = "http://localhost:1234/v1";
          apiKey = "lm-studio";
          api = "openai-completions";
          models = [
            {
              id = "zai-org/glm-4.7-flash";
              name = "GLM 4.7 Flash";
              input = [ "text" ];
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
          ];
        };
      };
    };
  };

  inherit (shared) home;
  modules.home = shared.modules.home // {
    secrets.backend = "age";
    ai.enable = true;
    cloud.enable = true;
    fonts.enable = true;
    ghostty.enable = true;
    git.enable = true;
    ide.enable = true;
    media.enable = true;
    mobile.enable = true;
    network.enable = true;
    nix.enable = true;
    openclaw.enable = true;
    p2p.enable = true;
    reverse-engineering.enable = true;
    comms.enable = true;
    security-tools.enable = true;
    shell.enable = true;
    ssh.enable = true;
    gpg.enable = true;
  };
}
