let
  topLevel = import ../.;

  inherit (topLevel) pkgs;

  env = pkgs.buildEnv {
    name = "env";
    paths = with pkgs; [
      nix
      cacert
      bashInteractive
      busybox
    ];
  };

in {
  inherit env;
}
