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
    sshTarget = true;
    zmxPrefix = "m";
    forwardAgent = true;
    forwardGpg = true;
  };

  spark = {
    hostname = "spark.osv.computer";
    aliases = [ "spark" ];
    sshTarget = true;
    zmxPrefix = "s";
    forwardAgent = true;
    forwardGpg = false;
  };

  beefy = {
    hostname = "beefy.0x77.computer";
    aliases = [ "beefy" ];
    sshTarget = true;
    zmxPrefix = "b";
    forwardAgent = true;
    forwardGpg = true;
  };

  ghost = {
    hostname = "ghost.0x77.computer";
    aliases = [ "ghost" ];
    sshTarget = true;
    zmxPrefix = "g";
    forwardAgent = false;
    forwardGpg = false;
  };

  timey = {
    hostname = "timey.0x77.computer";
    aliases = [ "timey" ];
    sshTarget = true;
    zmxPrefix = "t";
    forwardAgent = false;
    forwardGpg = false;
  };

  potato = {
    hostname = "potato.0x77.computer";
    aliases = [ "potato" ];
    sshTarget = false;
    zmxPrefix = null;
    forwardAgent = false;
    forwardGpg = false;
  };

  vasyl = {
    hostname = "vasyl.0x77.computer";
    aliases = [ "vasyl" ];
    sshTarget = false;
    zmxPrefix = null;
    forwardAgent = false;
    forwardGpg = false;
  };
}
