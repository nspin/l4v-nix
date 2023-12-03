{ lib
, runCommand
, python2Packages
, python3Packages
, git

, sources
, scopeConfig
, kernelWithCParser
, preprocessedKernelsAreEquivalent
, cFunctionsTxt
, asmFunctionsTxt
, graphRefineSolverLists
}:

{ name ? null
, extraNativeBuildInputs ? []
, solverList ? graphRefineSolverLists.default
, source ? sources.graphRefine
, args ? []
, keepSMTDumps ? false
, commands ? ''
    (time python ${source}/graph-refine.py . ${lib.concatStringsSep " " args}) 2>&1 | tee log.txt
  ''
}:

let
  targetPy = source + "/seL4-example/target-${scopeConfig.arch}.py";

  preTargetDir = runCommand "graph-refine-initial-target-dir" {
    inherit preprocessedKernelsAreEquivalent;
  } ''
    mkdir $out
    cp ${kernelWithCParser}/{kernel.elf.rodata,kernel.elf.txt,kernel.elf.symtab} $out
    cp ${cFunctionsTxt} $out/CFunctions.txt
    cp ${asmFunctionsTxt} $out/kernel_mc_graph.txt
    cp ${targetPy} $out/target.py
  '';

  targetDir = runCommand "graph-refine-prepared-target-dir" {
    nativeBuildInputs = [
      python3Packages.python
    ];
  } ''
    cp -r --no-preserve=ownership,mode ${preTargetDir} $out

    python3 ${source + "/seL4-example/functions-tool.py"} \
      --arch ARM \
      --target-dir $out \
      --functions-list-out functions-list.txt.txt \
      --asm-functions-out ASMFunctions.txt \
      --stack-bounds-out StackBounds.txt
  '';

in
runCommand "graph-refine${lib.optionalString (name != null) "-${name}"}" {
  nativeBuildInputs = [
    python2Packages.python
    python2Packages.typing
    python2Packages.enum
    python2Packages.psutilForPython2
    git
  ] ++ extraNativeBuildInputs;

  passthru = {
    inherit
      preprocessedKernelsAreEquivalent
      preTargetDir
      targetDir
    ;
  };
} ''
  ln -s ${solverList} .solverlist
  cp -r --no-preserve=owner,mode ${targetDir} target
  cd target

  ${commands}

  rm -f target.pyc

  ${lib.optionalString (!keepSMTDumps) ''
    rm -rf smt2
  ''}

  cp -r . $out
''
