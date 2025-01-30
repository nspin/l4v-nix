{ lib
, makeRustPlatform

, bvSandboxSource
}:

let
  fenixRev = "9af557bccdfa8fb6a425661c33dbae46afef0afa";
  fenixSource = fetchTarball "https://github.com/nix-community/fenix/archive/${fenixRev}.tar.gz";
  fenix = import fenixSource {};

  rustToolchain = fenix.fromToolchainFile {
    file = src + "/rust-toolchain.toml";
    sha256 = "sha256-3jVIIf5XPnUU1CRaTyAiO0XHVbJl12MSx3eucTXCjtE=";
  };

  rustPlatform = makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };

  src = lib.cleanSourceWith rec {
    src = bvSandboxSource + "/rust";
    filter = name: type:
      let
        root = src.origSrc or src;
        rel = lib.removePrefix "${toString root}/" (toString name);
      in
        lib.elem rel [
          "crates"
          "Cargo.lock"
          "Cargo.toml"
          "rust-toolchain.toml"
        ] || lib.hasPrefix "crates/" rel;
  };

in
rustPlatform.buildRustPackage {
  name = "bv-sandbox-rust";
  inherit src;
  cargoLock.lockFile = src + "/Cargo.lock";
  doCheck = false;
}
