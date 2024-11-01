{ stdenvNoCC
, python3
, scopeConfig
}:

stdenvNoCC.mkDerivation {
  name = "l4v-source";

  src = scopeConfig.l4vSource;

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  nativeBuildInputs = [
    python3
  ];

  postPatch = ''
    patchShebangs .

    substituteInPlace spec/haskell/Makefile \
      --replace-fail 'sandbox: .stack-work' 'sandbox:' \
      --replace-fail 'CABAL=stack exec -- ./stack-path cabal' 'CABAL=cabal'
  '';

  installPhase = ''
    cp -r . $out
  '';
}
