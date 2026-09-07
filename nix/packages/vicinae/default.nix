{
  inputs,
  stdenv,
  ...
}:
inputs.vicinae.packages.${stdenv.hostPlatform.system}.default
