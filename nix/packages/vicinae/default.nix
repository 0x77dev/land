{
  inputs,
  stdenv,
  ...
}:
inputs.vicinae.packages.${stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
  postPatch = (oldAttrs.postPatch or "") + ''
    substituteInPlace src/server/src/server.cpp \
      --replace-fail \
      "static constexpr QFont::Weight UI_FONT_WEIGHT = QFont::Medium;" \
      "static constexpr QFont::Weight UI_FONT_WEIGHT = QFont::Normal;"
  '';
})
