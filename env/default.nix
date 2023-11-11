let
  topLevel = import ../.;

  inherit (topLevel) pkgs;

  env = pkgs.buildEnv {
    name = "env";
    paths = with pkgs; [
      busybox
      nix
      cacert
      bashInteractive
    ];
  };

in {
  inherit env;
}
