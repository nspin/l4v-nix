let
  pkgs = import ../nixpkgs {
    overlays = [
      (import ./overlay.nix)
    ];
    config = {
      allowUnfree = true;
      allowBroken = true;
      oraclejdk.accept_license = true;
    };
  };
in pkgs.this // {
  inherit pkgs;
}
