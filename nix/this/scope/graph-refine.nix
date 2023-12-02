{ lib
, runCommand
, python2Packages

, sources
, l4vConfig
, graphRefineSolverLists

, graphRefineInputsViaMake

, kernelWithCParser
, preprocessedKernelsAreIdentical
, cFunctionsTxt
, asmFunctionsTxt
}:

let
  baseTargetDirWithGraphRefineInputsViaMake =
    let
      files = [
        "kernel.elf.symtab"
        "kernel.elf.rodata"
        "CFunctions.txt"
        "ASMFunctions.txt"
        "target.py"
      ];
    in
      runCommand "base-target-dir" {} ''
        install -D -t $out \
          ${graphRefineInputsViaMake}/${l4vConfig.arch}${l4vConfig.optLevel}/{${lib.concatStringsSep "," files}}
      '';

  targetPy = sources.graphRefineJustSeL4 + "/seL4-example/target.py";

  baseTargetDirWithDecomposition = runCommand "base-target-dir" {
    inherit preprocessedKernelsAreIdentical;
  } ''
    mkdir $out
    cp ${kernelWithCParser}/{kernel.elf.rodata,kernel.elf.txt,kernel.elf.symtab} $out
    cp ${cFunctionsTxt} $out/CFunctions.txt
    cp ${asmFunctionsTxt} $out/ASMFunctions.txt
    cp ${targetPy} $out/target.py
  '';

  # baseTargetDir = baseTargetDirWithGraphRefineInputsViaMake;
  baseTargetDir = baseTargetDirWithDecomposition;

in

{ name ? null
, extraNativeBuildInputs ? []
, solverList ? graphRefineSolverLists.default
, targetDir ? baseTargetDir
, source ? sources.graphRefineNoSeL4
, args ? []
, argLists ? [ args ]
, commands ? lib.flip lib.concatMapStrings argLists (argList: ''
    (time python ${source}/graph-refine.py . ${lib.concatStringsSep " " argList}) 2>&1 | tee log.txt
  '')
}:

runCommand "graph-refine${lib.optionalString (name != null) "-${name}"}" {
  nativeBuildInputs = [
    python2Packages.python
    python2Packages.psutilForPython2
  ] ++ extraNativeBuildInputs;
} ''
  ln -s ${solverList} .solverlist
  cp -r --no-preserve=owner,mode ${targetDir} target
  cd target

  ${commands}

  cp -r . $out
''
