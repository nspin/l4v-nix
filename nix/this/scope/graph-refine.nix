{ lib
, runCommand
, python2Packages
, python3Packages
, git

, scopeConfig
, kernel
, preprocessedKernelsAreEquivalent
, cFunctionsTxt
, asmFunctionsTxt
, graphRefineSolverLists
, graphRefineSource
}:

{ name ? null
, extraNativeBuildInputs ? []
, solverList ? graphRefineSolverLists.default
, source ? graphRefineSource
, args ? []
, argLists ? [ args ]
, dontDecorateCommands ? false
, decorateCommand ? if dontDecorateCommands then lib.id else (command: "(time ${command}) 2>&1 | tee log.txt")
, commands ? lib.flip lib.concatMapStrings argLists (argList: ''
    ${decorateCommand "python ${source}/graph-refine.py . ${lib.concatStringsSep " " argList}"}
  '')
, keepSMTDumps ? false
}:

let
  targetPy = source + "/seL4-example/target-${scopeConfig.arch}.py";

  preTargetDir = runCommand "graph-refine-initial-target-dir" {
    inherit preprocessedKernelsAreEquivalent;
  } ''
    mkdir $out
    cp ${kernel}/{kernel.elf.rodata,kernel.elf.txt,kernel.elf.symtab} $out
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
      --arch ${scopeConfig.arch} \
      --target-dir $out \
      --functions-list-out functions-list.txt \
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
      solverList
      preprocessedKernelsAreEquivalent
      preTargetDir
      targetDir
    ;
  };
} ''
  cp -r --no-preserve=owner,mode ${targetDir} target
  cd target
  ln -sf ${solverList} .solverlist

  ${commands}

  rm -f target.pyc

  ${lib.optionalString (!keepSMTDumps) ''
    rm -rf smt2
  ''}

  cp -r . $out
''
