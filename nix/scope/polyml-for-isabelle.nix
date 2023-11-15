{ stdenv, lib, fetchpatch, fetchFromGitHub, gmp, libffi }:

stdenv.mkDerivation rec {
  pname = "polyml";
  version = "5.8.1";

  buildInputs = [ libffi gmp ];

  src = fetchFromGitHub {
    owner = "polyml";
    repo = "polyml";
    rev = "v${version}";
    sha256 = "0gcx2fjiwsiazlyfhm7zlrd563blc4fy9w2mspib9divbavaxin6";
  };

  patches = [
    (fetchpatch {
      url = "https://src.fedoraproject.org/rpms/polyml/raw/4d8868ca5a1ce3268f212599a321f8011c950496/f/polyml-pthread-stack-min.patch";
      sha256 = "1h5ihg2sxld9ymrl3f2mpnbn2242ka1fsa0h4gl9h90kndvg6kby";
    })
  ];

  configureFlags = [
    "--disable-shared"
    "--enable-intinf-as-int"
    "--with-gmp"
    # "--with-system-libffi"
  ];
}
