{
  lib,
  stdenv,
}:
let
  src = lib.fileset.toSource {
    root = ./.;
    fileset = ./static/index.html;
  };
in
stdenv.mkDerivation {
  pname = "vesper-startpage";
  version = "0.1.0";
  inherit src;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 static/index.html $out/share/vesper-startpage/index.html
    runHook postInstall
  '';

  meta = {
    description = "Standalone Vesper startpage HTML";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
