{ lib, stdenv
, python2Packages
, strace

, sources
, graphRefineInputs
, graphRefineSolverLists
, l4vConfig
}:

{ name ? null
, extraNativeBuildInputs ? []
, solverList ? graphRefineSolverLists.default
, targetDir ? "${graphRefineInputs}/${l4vConfig.arch}${l4vConfig.optLevel}"
, source ? sources.graphRefineNoSeL4
, args ? []
, argLists ? [ args ]
, commands ? lib.flip lib.concatMapStrings argLists (argList: ''
    time python ${source}/graph-refine.py . ${lib.concatStringsSep " " argList} 2>&1 | tee log.txt
  '')
}:

stdenv.mkDerivation {
  name = "graph-refine${lib.optionalString (name != null) "-${name}"}";

  nativeBuildInputs = [
    python2Packages.python
    python2Packages.psutilForPython2
  ] ++ extraNativeBuildInputs;

  buildCommand = ''
    ln -s ${solverList} .solverlist
    cp -r --no-preserve=owner,mode ${targetDir} target
    cd target

    ${commands}

    cp -r . $out
  '';
}
