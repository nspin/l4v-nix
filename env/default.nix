let
  topLevel = import ../.;

  inherit (topLevel) pkgs;

  env = pkgs.buildEnv {
    name = "env";
    paths = with pkgs; [
      bashInteractive
      nix
      cacert
      busybox
    ];
  };

in {
  inherit env;
}
