{ lib
, fetchurl
}:

rec {
  x = fetchurl {
    url = "https://isabelle.in.tum.de/components/cakeml-2.0.tar.gz";
    sha1 = "f92cff635dfba5d4d77f469307369226c868542c";
  };
}
