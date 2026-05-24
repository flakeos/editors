{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "editors";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ../.;
    filter = path: type:
      (lib.hasPrefix (toString ./.. + "/config") path) ||
      path == toString ./../editors.json;
  };

  installPhase = ''
    cp -r config $out
    cp editors.json $out/
  '';

  meta = {
    description = "VSCode-family editor configuration manager";
    longDescription = ''
      Multi-editor configuration for VSCode, VSCodium, Cursor, Windsurf, and
      Antigravity. Manages settings, keybindings, tasks, launch configs,
      snippets, and extensions declaratively through Nix.
    '';
    homepage = "https://github.com/alessioattila/editors";
    platforms = lib.platforms.all;
    license = lib.licenses.mit;
  };
}
