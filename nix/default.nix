let
  pkgs = import ../nixpkgs {
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
