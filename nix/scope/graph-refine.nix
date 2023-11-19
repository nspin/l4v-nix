{ lib, stdenv
, python2Packages

, sources
, graphRefineInputs
, graphRefineSolverLists
, l4vConfig
}:

{ name ? null
, source ? sources.graphRefineNoSeL4
, solverList ? graphRefineSolverLists.default
, targetDir ? "${graphRefineInputs}/${l4vConfig.arch}${l4vConfig.optLevel}"
, commands ? [ [] ]
}:

stdenv.mkDerivation {
  name = "graph-refine${lib.optionalString (name != null) "-${name}"}";

  nativeBuildInputs = [
    python2Packages.python
    python2Packages.psutilForPython2
  ];

  buildCommand = ''
    ln -s ${solverList} .solverlist
    cp -r --no-preserve=owner,mode ${targetDir} target
    cd target

    ${lib.flip lib.concatMapStrings commands (args: ''
      time python ${source}/graph-refine.py . ${lib.concatStringsSep " " args}
    '')}

    cp -r . $out
  '';
}
