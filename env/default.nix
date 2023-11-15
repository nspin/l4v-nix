let
  pkgs = import ../nixpkgs {};

  runInContainer = pkgs.callPackage ./run-in-container.nix {};

  probe = pkgs.callPackage ./probe.nix {};

in
runInContainer // probe
