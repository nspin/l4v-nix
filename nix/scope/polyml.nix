{ stdenv, lib, fetchpatch, fetchFromGitHub, gmp, libffi }:

stdenv.mkDerivation rec {
  name = "polyml";

  src = fetchFromGitHub {
    owner = "seL4";
    repo = "polyml";
    rev = "cf46747fee61f6ed6ca49bc2e269d5d9960d5f7b";
    sha256 = "sha256-rPgiiIT3jKLojKjC7Q+7vilOyzbOhvaa4YSlh14ljoc=";
  };

  patches = [
    (fetchpatch {
      url = "https://src.fedoraproject.org/rpms/polyml/raw/4d8868ca5a1ce3268f212599a321f8011c950496/f/polyml-pthread-stack-min.patch";
      sha256 = "1h5ihg2sxld9ymrl3f2mpnbn2242ka1fsa0h4gl9h90kndvg6kby";
    })
  ];

  buildInputs = [ libffi gmp ];

  configureFlags = [
    "--enable-shared"
    "--with-system-libffi"
    "--with-gmp"
  ];
}
