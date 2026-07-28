# This is the single source of truth for fleet names, addresses, and per-machine
# trust flags; consumers filter by capability (`sshTarget`, `forwardGpg`) instead
# of hand-maintaining lists.
_: {
  muscle = {
    hostname = "muscle.osv.computer";
    aliases = [
      "muscle"
      "muscle.0x77.computer"
    ];
    tailnet = "muscle.axolotl-sole.ts.net";
    sshTarget = true;
    zmxPrefix = "m";
    forwardAgent = true;
    forwardGpg = true;
  };

  spark = {
    hostname = "spark.osv.computer";
    aliases = [ "spark" ];
    tailnet = "spark.axolotl-sole.ts.net";
    sshTarget = true;
    zmxPrefix = "s";
    forwardAgent = true;
    forwardGpg = false;
  };

  beefy = {
    hostname = "beefy.0x77.computer";
    aliases = [ "beefy" ];
    tailnet = null;
    sshTarget = true;
    zmxPrefix = "b";
    forwardAgent = true;
    forwardGpg = true;
  };

  ghost = {
    hostname = "ghost.0x77.computer";
    aliases = [ "ghost" ];
    tailnet = null;
    sshTarget = true;
    zmxPrefix = "g";
    forwardAgent = false;
    forwardGpg = false;
  };

  timey = {
    hostname = "timey.0x77.computer";
    aliases = [ "timey" ];
    tailnet = null;
    sshTarget = true;
    zmxPrefix = "t";
    forwardAgent = false;
    forwardGpg = false;
  };

  potato = {
    hostname = "potato.0x77.computer";
    aliases = [ "potato" ];
    tailnet = null;
    sshTarget = false;
    zmxPrefix = null;
    forwardAgent = false;
    forwardGpg = false;
  };

  vasyl = {
    hostname = "vasyl.0x77.computer";
    aliases = [ "vasyl" ];
    tailnet = null;
    sshTarget = false;
    zmxPrefix = null;
    forwardAgent = false;
    forwardGpg = false;
  };
}
