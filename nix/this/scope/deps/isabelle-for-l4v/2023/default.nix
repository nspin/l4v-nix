{
}:

let
  nixpkgsSource = builtins.fetchGit rec {
    url = "https://github.com/coliasgroup/nixpkgs.git";
    ref = "refs/tags/keep/${builtins.substring 0 32 rev}";
    rev = "f507b81f8df7572500fa1393c9aee9ce51182708";
  };

  nixpkgs = import nixpkgsSource {};

in
nixpkgs.isabelle.overrideAttrs (attrs: {
  patches = (attrs.patches or []) ++ [
    ./permissions.patch
  ];
})
