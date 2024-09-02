{ }:

let
  nixpkgsSource =
    let
      rev = "12228ff1752d7b7624a54e9c1af4b222b3c1073b";
    in
      builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
        sha256 = "sha256:1dmng7f5rv4hgd0b61chqx589ra7jajsrzw21n8gp8makw5khvb2";
      };

  nixpkgs = import nixpkgsSource {};

in
nixpkgs.isabelle.overrideAttrs (attrs: {
  patches = (attrs.patches or []) ++ [
    # ./permissions.patch
  ];
})
