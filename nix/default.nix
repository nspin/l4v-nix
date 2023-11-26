let
  pkgs = import ../nixpkgs/pkgs/top-level {
    localSystem = "x86_64-linux";
    overlays = [
      (import ./overlay)
    ];
    config = {
      permittedInsecurePackages = [
        pkgs.python2.name
      ];
    };
  };
in pkgs.this.default // {
  inherit pkgs;
}
