{ lib
, runCommand
, writeText
, python2Packages
, python3Packages
# , git
, strace

, sources
, l4vConfig
, graphRefineInputs
, graphRefineSolverLists
, currentGraphRefineSolverLists

, stdenv
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2

, mlton

, isabelleForL4v
, polymlForHol4
, hol4
, binaryVerificationInputs

, standaloneCParser
, simplExport
, isabelle2020ForL4v
}:

# TODO diff preprocessed kernels

let

in rec {

  kernel =
    let
      files = [
        "kernel_all.c_pp"
        "kernel.elf"
        "kernel.elf.rodata"
        "kernel.elf.txt"
        "kernel.elf.symtab"
        "kernel.sigs"
      ];
    in
      runCommand "kernel" {
        nativeBuildInputs = [
          cmake ninja
          dtc libxml2
          python3Packages.sel4-deps
          l4vConfig.targetCC
          l4vConfig.targetBintools

          isabelle2020ForL4v
        ];
      } ''
        export L4V_ARCH=${l4vConfig.arch}
        export TOOLPREFIX=${l4vConfig.targetPrefix}
        export KERNEL_CMAKE_EXTRA_OPTIONS=-DKernelOptimisation=${l4vConfig.optLevel}
        export KERNEL_BUILD_ROOT=$out

        export L4V_REPO_PATH=${standaloneCParser}
        export SOURCE_ROOT=${sources.seL4}

        export OBJDUMP=''${TOOLPREFIX}objdump

        export ISABELLE_HOME=$(isabelle env sh -c 'echo $ISABELLE_HOME')

        make -f ${standaloneCParser}/spec/cspec/c/kernel.mk \
          ${lib.concatMapStringsSep " " (file: "$KERNEL_BUILD_ROOT/${file}") files}
      '';

  cFunctionsTxt = "${binaryVerificationInputs}/proof/asmrefine/export/${l4vConfig.arch}/CFunDump.txt";

  ignore = [
    "_start" "c_handle_fastpath_call" "c_handle_fastpath_reply_recv" "restore_user_context"
  ];

  decompilationScriptIn = writeText "x.ml" ''
    load "decompileLib";
    val _ = decompileLib.decomp "@path@" true "${lib.concatStringsSep "," ignore}";
  '';

  decompilation = runCommand "decompilation" {
    nativeBuildInputs = [
      git
    ];
  }''
    hol_dir=$(pwd)/src/HOL4
    target_dir=$(pwd)/target
    script=$(pwd)/script

    mkdir $(dirname $hol_dir)
    ln -s ${hol4} $hol_dir

    mkdir $target_dir
    cp ${kernel}/{kernel.elf.txt,kernel.sigs} target

    substitute ${decompilationScriptIn} $script --subst-var-by path $target_dir/kernel

    cd $hol_dir/examples/machine-code/graph
    echo "decompiling..."
    $hol_dir/bin/hol < $script > $target_dir/log.txt
    cp -r $target_dir $out
  '';

  asmFunctionsTxt = "${decompilation}/kernel_mc_graph.txt";

  initialTargetDir =
    let
      files = [
        "kernel.elf.rodata"
        "kernel.elf.txt"
        "kernel.elf.symtab"
        "CFunctions.txt"
        "ASMFunctions.txt"
      ];
    in
      runCommand "current-graph-refine-initial-target-dir" {} ''
        mkdir $out
        cp ${kernel}/{kernel.elf.rodata,kernel.elf.txt,kernel.elf.symtab} $out
        cp ${cFunctionsTxt} $out/CFunctions.txt
        cp ${asmFunctionsTxt} $out/kernel_mc_graph.txt
      '';

  preparedTargetDir = runCommand "current-graph-refine-prepared-target-dir" {
    nativeBuildInputs = [
      python3Packages.python
    ];
  } ''
    cp -r --no-preserve=ownership,mode ${initialTargetDir} $out

    python3 ${sources.currentGraphRefineJustSeL4 + "/seL4-example/functions-tool.py"} \
      --arch ARM \
      --target-dir $out \
      --functions-list-out functions-list.txt.txt \
      --asm-functions-out ASMFunctions.txt \
      --stack-bounds-out StackBounds.txt
  '';

  defaultTargetDir = runCommand "target-dir" {} ''
    cp -r --no-preserve=mode,ownership ${preparedTargetDir} $out
    cp ${sources.currentGraphRefineJustSeL4 + "/seL4-example/target-ARM.py"} $out/target.py
  '';

  mk =
    { name ? null
    , extraNativeBuildInputs ? []
    , solverList ? currentGraphRefineSolverLists.default
    , targetDir ? defaultTargetDir
    , source ? sources.currentGraphRefineNoSeL4
    , args ? []
    , argLists ? [ args ]
    , wrapArgs ? ""
    , commands ? lib.flip lib.concatMapStrings argLists (argList: ''
        (time ${wrapArgs} python ${source}/graph-refine.py . ${lib.concatStringsSep " " argList}) 2>&1 | tee log.txt
      '')
    }:

    runCommand "current-graph-refine${lib.optionalString (name != null) "-${name}"}" {
      nativeBuildInputs = [
        python2Packages.python
        python2Packages.typing
        python2Packages.enum
        python2Packages.psutilForPython2
        git
      ] ++ extraNativeBuildInputs;
    } ''
      ln -s ${solverList} .solverlist
      cp -r --no-preserve=owner,mode ${targetDir} target
      cd target

      ${commands}

      cp -r . $out
    '';

  all = mk {
    name = "all";
    args = [
      "trace-to:report.txt"
      "all"
    ];
  };

  demo = mk {
    name = "demo";
    extraNativeBuildInputs = [
      # strace
    ];
    # wrapArgs = "strace -f -e trace=file";
    args = [
      # "verbose"
      "trace-to:report.txt"
      # "deps:Kernel_C.cancelAllIPC"

      # "create_kernel_untypeds"
      # "invokeTCB_WriteRegisters"
      # "decodeARMMMUInvocation"
      # "handleInterruptEntry"
      # "memcpy"

      # "init_freemem"

      "all"
    ];
  };

}
