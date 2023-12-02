{ lib
, runCommand
, cmake, ninja
, dtc, libxml2
, python3Packages
, perl

, sources
, l4vConfig
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
    l4vConfig.targetCC
    l4vConfig.targetBintools
  ] ++ lib.optionals withCParser [
    perl
    mltonForL4v
    isabelleForL4v
  ];
} ''
  export L4V_ARCH=${l4vConfig.arch}
  export TOOLPREFIX=${l4vConfig.targetPrefix}
  export KERNEL_CMAKE_EXTRA_OPTIONS=-DKernelOptimisation=${l4vConfig.optLevel}
  export KERNEL_BUILD_ROOT=$out

  export L4V_REPO_PATH=${l4vPath}
  export SOURCE_ROOT=${sources.seL4}

  export OBJDUMP=''${TOOLPREFIX}objdump

  ${lib.optionalString withCParser ''
    export HOME=$(mktemp -d --suffix=-home)
    export ISABELLE_HOME=$(isabelle env sh -c 'echo $ISABELLE_HOME')
  ''}

  make -f ${l4vPath + "/spec/cspec/c/kernel.mk"} \
    ${lib.concatMapStringsSep " " (file: "$KERNEL_BUILD_ROOT/${file}") files}
''
