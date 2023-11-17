{ lib, stdenv

, runCommand
, python3Packages
, cmake, ninja, dtc, libxml2

, sources
, l4vConfig
}:

let
  src = runCommand "src" {} ''
    mkdir $out
    cp -r ${sources.seL4} $out/seL4
    cp -r ${sources.l4v} $out/l4v
  '';

in
stdenv.mkDerivation {
  name = "kernel";

  inherit src;

  nativeBuildInputs = [
    cmake ninja
    dtc libxml2
    python3Packages.sel4-deps
    l4vConfig.targetCC
    l4vConfig.targetBintools
  ];

  hardeningDisable = [ "all" ];

  buildCommand = ''
    export L4V_ARCH=${l4vConfig.arch}
    export TOOLPREFIX=${l4vConfig.targetPrefix}
    export KERNEL_CMAKE_EXTRA_OPTIONS=-DKernelOptimisation=${l4vConfig.optLevel}
    export KERNEL_BUILD_ROOT=$out

    cd ${src}/l4v/spec/cspec/c && make -f kernel.mk $KERNEL_BUILD_ROOT/kernel.elf
  '';
}
