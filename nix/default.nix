let
  pkgs = import ../nixpkgs {
    overlays = [
      (import ./overlay)
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
