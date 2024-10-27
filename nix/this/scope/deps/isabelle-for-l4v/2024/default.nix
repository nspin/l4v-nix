{ isabelle }:

isabelle.overrideAttrs (attrs: {
  patches = (attrs.patches or []) ++ [
    ./permissions.patch
  ];
})
