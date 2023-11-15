{ stdenv, fetchFromGitHub, python2 }:

stdenv.mkDerivation rec {
  pname = "z3";
  version = "4.4.0";

  src = fetchFromGitHub {
    owner  = "Z3Prover";
    repo   = "z3";
    rev    = "z3-${version}";
    sha256 = "1xllvq9fcj4cz34biq2a9dn2sj33bdgrzyzkj26hqw70wkzv1kzx";
  };

  nativeBuildInputs = [ python2 ];

  configurePhase = ''
    python scripts/mk_make.py --prefix=$out
    cd build
  '';

  installPhase = ''
    install -D -t $out/bin z3
    install -D -t $out/lib libz3.*
  '';

  enableParallelBuilding = true;
}
