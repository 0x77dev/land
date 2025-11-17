{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    aichat
    ollama
    opencode
  ];
}
