{ lib, stdenv
, python2Packages

, sources
, graphRefineInputs
, graphRefineSolverLists
, l4vConfig
}:

{ name ? null
, solverList ? graphRefineSolverLists.default
, targetDir ? "${graphRefineInputs}/${l4vConfig.arch}${l4vConfig.optLevel}"
, commands ? [ [] ]
}:

let
  psutil = python2Packages.psutil.overridePythonAttrs (_attrs: {
    disabled = false;
    doCheck = false;
  });

in
stdenv.mkDerivation {
  name = "graph-refine${lib.optionalString (name != null) "-${name}"}";

  nativeBuildInputs = [
    python2Packages.python
    psutil
  ];

  buildCommand = ''
    ln -s ${solverList} .solverlist
    cp -r --no-preserve=owner,mode ${targetDir} target
    cd target

    ${lib.flip lib.concatMapStrings commands (args: ''
      time python ${sources.graphRefineNoSeL4}/graph-refine.py . ${lib.concatStringsSep " " args}
    '')}

    cp -r . $out
  '';
}
