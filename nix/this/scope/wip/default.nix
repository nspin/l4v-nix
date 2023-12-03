{ lib
, pkgs
, callPackage
, runCommand
, writeText
, writeScript
, writeShellApplication
, runtimeShell
, breakpointHook
, bashInteractive
, strace

, sources
, graphRefine
, graphRefineWith
, graphRefineSolverLists

, this
}:

let
  tmpSource = lib.cleanSource ../../../../tmp/graph-refine;

in rec {

  prime = writeText "prime" (toString (lib.flatten [
    all
  ]));

  # gcc49GraphRefineInputs =
  #   lib.forEach (lib.attrNames this.optLevels)
  #     (optLevel: this.byConfig.arm.gcc49.${optLevel}.graphRefineInputsViaMake);

  all = this.mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = this.byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in
      lib.optionals scope.scopeConfig.bvSupport [
        scope.graphRefine.all
      ]
  );

}
