{ stdenv
, python3
, rawSources
, l4vConfig
}:

stdenv.mkDerivation {
  name = "l4v-source";

  src = rawSources.l4v;

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  nativeBuildInputs = [
    python3
  ];

  patches = [
    ./improve-psutil-check.patch
  ];

  postPatch = ''
    patchShebangs .

    for x in tools/c-parser/tools/{mllex,mlyacc}/Makefile; do
      substituteInPlace $x --replace /bin/echo echo
    done

    substituteInPlace spec/haskell/Makefile \
      --replace 'sandbox: .stack-work' 'sandbox:' \
      --replace 'CABAL=stack exec -- ./stack-path cabal' 'cabal'
  '';

  installPhase = ''
    cp -r . $out
  '';
}
