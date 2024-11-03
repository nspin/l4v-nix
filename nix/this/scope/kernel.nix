{ lib
, runCommand
, cmake, ninja
, dtc, libxml2
, python3Packages
, perl

, patchedSeL4Source
, scopeConfig
, standaloneCParser
, isabelleForL4v
, mltonForL4v
}:

assert scopeConfig.optLevel != null;

runCommand "kernel" {

  nativeBuildInputs = [
    cmake ninja
    dtc libxml2
    python3Packages.sel4-deps
    scopeConfig.targetCC
    scopeConfig.targetBintools
    perl
    isabelleForL4v
    mltonForL4v
  ];

  L4V_ARCH = scopeConfig.arch;
  L4V_FEATURES = scopeConfig.features;
  L4V_PLAT = scopeConfig.plat;
  TOOLPREFIX = scopeConfig.targetPrefix;

  OBJDUMP = "${scopeConfig.targetPrefix}objdump";

  L4V_REPO_PATH = standaloneCParser;
  SOURCE_ROOT = patchedSeL4Source;

  CONFIG_OPTIMISATION = scopeConfig.optLevel;

} ''
  export HOME=$(mktemp -d --suffix=-home)

  export ISABELLE_HOME=$(isabelle env sh -c 'echo $ISABELLE_HOME')

  export KERNEL_BUILD_ROOT=build

  export KERNEL_EXPORT_DIR=$out

  make -f $L4V_REPO_PATH/spec/cspec/c/kernel.mk kernel_export
''
