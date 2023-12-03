{ lib
, runCommand
, cmake, ninja
, dtc, libxml2
, python3Packages
, perl

, sources
, scopeConfig
, standaloneCParser
, mltonForL4v
, isabelleForL4v

, withCParser ? false
}:

let
  files = [
    "kernel_all.c_pp"
    "kernel.elf"
    "kernel.elf.rodata"
    "kernel.elf.txt"
    "kernel.elf.symtab"
  ] ++ lib.optionals withCParser [
    "kernel.sigs"
  ];

  l4vPath = if withCParser then standaloneCParser else sources.l4v;

in
runCommand "kernel-${if withCParser then "with" else "without"}-cparser" {

  nativeBuildInputs = [
    cmake ninja
    dtc libxml2
    python3Packages.sel4-deps
    scopeConfig.targetCC
    scopeConfig.targetBintools
  ] ++ lib.optionals withCParser [
    perl
    mltonForL4v
    isabelleForL4v
  ];

  L4V_ARCH = scopeConfig.arch;
  L4V_FEATURES = scopeConfig.features;
  L4V_PLAT = scopeConfig.plat;
  TOOLPREFIX = scopeConfig.targetPrefix;

  OBJDUMP = "${scopeConfig.targetPrefix}objdump";

  L4V_REPO_PATH = l4vPath;
  SOURCE_ROOT = sources.seL4;

  KERNEL_CMAKE_EXTRA_OPTIONS = "-DKernelOptimisation=${scopeConfig.optLevel}";

} ''
  export HOME=$(mktemp -d --suffix=-home)

  ${lib.optionalString withCParser ''
    export ISABELLE_HOME=$(isabelle env sh -c 'echo $ISABELLE_HOME')
  ''}

  export KERNEL_BUILD_ROOT=$out

  make -f ${l4vPath + "/spec/cspec/c/kernel.mk"} \
    ${lib.concatMapStringsSep " " (file: "$KERNEL_BUILD_ROOT/${file}") files}
''
