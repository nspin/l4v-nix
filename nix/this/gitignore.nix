{ lib
, fetchFromGitHub
}:

let
  gitignoreSrc = fetchFromGitHub {
    owner = "hercules-ci";
    repo = "gitignore.nix";
    rev = "637db329424fd7e46cf4185293b9cc8c88c95394";
    sha256 = "sha256-HG2cCnktfHsKV0s4XW83gU3F57gaTljL9KNSuG6bnQs=";
  };
in

# let
#   gitignoreSrc = ../../tmp/gitignore.nix;
# in

import gitignoreSrc { inherit lib; }
