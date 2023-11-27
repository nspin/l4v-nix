{ stdenv, lib, fetchpatch, fetchFromGitHub, gmp, libffi_3_3 }:

stdenv.mkDerivation rec {
  name = "polyml";
  version = "5.8.2";

  src = fetchFromGitHub {
    owner = "polyml";
    repo = "polyml";
    rev = "v${version}";
    sha256 = "sha256-/oL5hY0CP+aDDpCje4Si3rh1Vh4Gv3KUSjOnZwJSdG8=";
  };

  patches = [
    (fetchpatch {
      url = "https://src.fedoraproject.org/rpms/polyml/raw/4d8868ca5a1ce3268f212599a321f8011c950496/f/polyml-pthread-stack-min.patch";
      sha256 = "1h5ihg2sxld9ymrl3f2mpnbn2242ka1fsa0h4gl9h90kndvg6kby";
    })
  ];

  buildInputs = [ libffi_3_3 gmp ];

  configureFlags = [
    "--enable-shared"
    "--with-gmp"
    "--with-system-libffi"
  ];
}
