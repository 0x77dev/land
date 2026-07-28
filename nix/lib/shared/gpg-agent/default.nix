# Single source of truth for the gpg-agent socket paths shared by the ssh and
# zmx home modules. Local paths are where the client's agent listens; remote
# paths are the Linux destinations used when forwarding the agent onward.
_:
{
  isDarwin,
  homeDirectory,
}:
{
  localAgentExtraSocket =
    if isDarwin then
      "${homeDirectory}/.gnupg/S.gpg-agent.extra"
    else
      "/run/user/1000/gnupg/S.gpg-agent.extra";
  localAgentSshSocket =
    if isDarwin then
      "${homeDirectory}/.gnupg/S.gpg-agent.ssh"
    else
      "/run/user/1000/gnupg/S.gpg-agent.ssh";

  remoteAgentSocket = "/run/user/1000/gnupg/S.gpg-agent";
  remoteAgentSshSocket = "/run/user/1000/gnupg/S.gpg-agent.ssh";
}
