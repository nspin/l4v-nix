let
  topLevel = import ../.;

  inherit (topLevel) pkgs;

  env = pkgs.buildEnv {
    name = "env";
    paths = with pkgs; [
      nix
      cacert
      busybox
      bashInteractive
    ];
  };

in {
  inherit env;
}
