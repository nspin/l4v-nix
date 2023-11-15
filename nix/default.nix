let
  pkgs = import ../nixpkgs {
    overlays = [
      (import ./overlay)
    ];
    config = {
      permittedInsecurePackages = [
        "python-2.7.18.7"
      ];
    };
  };
in pkgs.this.default // {
  inherit pkgs;
}
