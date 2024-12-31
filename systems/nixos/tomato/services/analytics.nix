{ pkgs, ... }: {
  services.plausible = {
    enable = true;
    server = {
      listenAddress = "0.0.0.0";
      port = 8181;
      baseUrl = "https://plausible.0x77.computer";
      disableRegistration = "invite_only";
      secretKeybaseFile = "/data/.secret/plausible/secret";
    };
    adminUser = {
      name = "Mykhailo";
      email = "mykhailo@0x77.dev";
      passwordFile = "/data/.secret/plausible/admin_password";
      activate = true;
    };
    mail = {
      email = "plausible@system.0x77.dev";
      smtp = {
        hostAddr = "smtp.resend.com";
        hostPort = 465;
        enableSSL = true;
        user = "resend";
        passwordFile = "/data/.secret/resend/api_key";
      };
    };
  };
}
