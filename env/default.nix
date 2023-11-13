let
  nixpkgs = builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs.git";
    ref = "nixos-unstable";
    rev = "85f1ba3e51676fa8cc604a3d863d729026a6b8eb";
  };

  pkgs = import nixpkgs {};

in
pkgs.callPackage ./run-in-container.nix {}
