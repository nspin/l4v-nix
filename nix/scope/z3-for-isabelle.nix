{ gcc49Stdenv, fetchFromGitHub, python2 }:

gcc49Stdenv.mkDerivation rec {
  name = "z3-${version}";
  version = "4.4.0";

  src = fetchFromGitHub {
    owner  = "Z3Prover";
    repo   = "z3";
    rev    = "7f6ef0b6c0813f2e9e8f993d45722c0e5b99e152";
    sha256 = "1xllvq9fcj4cz34biq2a9dn2sj33bdgrzyzkj26hqw70wkzv1kzx";
  };

  buildInputs = [ python2 ];
  enableParallelBuilding = true;

  configurePhase = "python scripts/mk_make.py --prefix=$out && cd build";

  # z3's install phase is stupid because it tries to calculate the
  # python package store location itself, meaning it'll attempt to
  # write files into the nix store, and fail.
  soext = if gcc49Stdenv.system == "x86_64-darwin" then ".dylib" else ".so";
  installPhase = ''
    mkdir -p $out/bin $out/lib/${python2.libPrefix}/site-packages $out/include
    cp ../src/api/z3*.h       $out/include
    cp ../src/api/c++/z3*.h   $out/include
    cp z3                     $out/bin
    cp libz3${soext}          $out/lib
    cp libz3${soext}          $out/lib/${python2.libPrefix}/site-packages
    cp z3*.pyc                $out/lib/${python2.libPrefix}/site-packages
    cp ../src/api/python/*.py $out/lib/${python2.libPrefix}/site-packages
  '';
}
