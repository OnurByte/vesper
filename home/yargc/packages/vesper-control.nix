{
  bluez,
  flatpak,
  hyprland,
  lib,
  libsecret,
  makeWrapper,
  networkmanager,
  qrencode,
  rustc,
  stdenv,
  systemd,
}:
stdenv.mkDerivation {
  pname = "vesper-control";
  version = "0.5.0";

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
    rustc
  ];

  buildPhase = ''
    runHook preBuild
    cp ${./vesper-control.rs} vesper-control.rs
    cp ${./vesper-control-router.rs} vesper-control-router.rs
    rustc --edition=2021 -C opt-level=2 vesper-control.rs -o vesper-control-core
    rustc --edition=2021 -C opt-level=2 vesper-control-router.rs -o vesper-control
    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    rustc --edition=2021 --test vesper-control.rs -o vesper-control-tests
    ./vesper-control-tests
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 vesper-control $out/bin/vesper-control
    install -Dm755 vesper-control-core $out/bin/vesper-control-core

    runtimePath=${lib.makeBinPath [
      bluez
      flatpak
      hyprland
      libsecret
      networkmanager
      qrencode
      systemd
    ]}

    # Liquid Glass remains an independently installed sibling application.
    # Keep the caller's profile PATH so its versioned CLI is discoverable.
    wrapProgram $out/bin/vesper-control \
      --prefix PATH : "$out/bin:$runtimePath"
    wrapProgram $out/bin/vesper-control-core \
      --prefix PATH : "$runtimePath"
    runHook postInstall
  '';

  meta = {
    description = "Native Vesper settings control plane";
    license = lib.licenses.mit;
    mainProgram = "vesper-control";
    platforms = lib.platforms.linux;
  };
}
