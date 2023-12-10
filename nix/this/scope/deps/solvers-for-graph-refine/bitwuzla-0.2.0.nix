{ lib
, stdenv
, pkgsDynamic
, writeText
, fetchFromGitHub
, fetchurl
, pkg-config
, python3
, meson
, ninja
, git
, gmp
}:

# TODO tests

let
  cadicalSrc = fetchurl {
    url = "https://github.com/arminbiere/cadical/archive/rel-1.5.2.tar.gz";
    sha256 = "4a4251bf0191677ca8cda275cb7bf5e0cf074ae0056819642d5a7e5c1a952e6e";
  };

  kissatSrc = fetchurl {
    url = "https://github.com/arminbiere/kissat/archive/refs/tags/rel-3.0.0.tar.gz";
    sha256 = "230895b3beaec5f2c78f6cc520a7db94b294edf244cbad37e2ee6a8a63bd7bdf";
  };

  symfpuRev = "22d993d880f66b2e470c3928e0e61bdf61419702";

  symfpuSrc = fetchurl {
    url = "https://github.com/martin-cs/symfpu/archive/${symfpuRev}.tar.gz";
    sha256 = "sha256-tSHd//Man1y3p4xt1eZoTlY9jGe3fnGAh9Pvc5YlyAM=";
  };

  symfpuWrap = writeText "symfpu.wrap" ''
    [wrap-file]
    directory = symfpu-${symfpuRev}

    source_filename = ${symfpuSrc}

    patch_directory = symfpu

    [provide]
    symfpu = symfpu_dep
  '';

in
stdenv.mkDerivation rec {
  pname = "bitwuzla";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "bitwuzla";
    repo = "bitwuzla";
    rev = version;
    hash = "sha256-t5D85ZTd1Ro9OIeLTEUYKr7O1qtM9K21o6p1mwPQrK8=";
  };

  dontDisableStatic = true;

  nativeBuildInputs = [
    pkg-config
    python3
    meson
    ninja
    git
  ];

  buildInputs = [
    gmp
    pkgsDynamic.minisat
    pkgsDynamic.cryptominisat
    pkgsDynamic.picosat
  ];

  postPatch = ''
    patchShebangs .

    cp ${symfpuWrap} subprojects/symfpu.wrap

    sed -i \
      -e 's|^source_url = .*$||' \
      -e 's|^source_filename = .*$|source_filename = ${cadicalSrc}|' \
      subprojects/cadical.wrap

    sed -i \
      -e 's|^source_url = .*$||' \
      -e 's|^source_filename = .*$|source_filename = ${kissatSrc}|' \
      subprojects/kissat.wrap
  '';

  configurePhase = ''
    ./configure.py --prefix=$prefix --kissat
  '';

  buildPhase = ''
    cd build && ninja install
  '';
}
