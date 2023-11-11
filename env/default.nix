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

  # image = pkgs.dockerTools.buildImage {
  #   name = "minimal";
  #   tag = "latest";
  # }
in {
  inherit env;
}
