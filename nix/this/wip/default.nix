{ lib
, writeText
, this
}:

with this;

let

in rec {
  workingSet = writeText "x" (toString [
    byConfig.arm.gcc49.o0.graphRefine.justStackBounds
    byConfig.arm.gcc49.o1.graphRefine.justStackBounds
    byConfig.arm.gcc49.o2.graphRefine.justStackBounds
  ]);

  graphRefineInputs = writeText "all-graph-refine-inputs" (toString (mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in
      lib.optionals scope.l4vConfig.bvSupport [
        scope.graphRefineInputs
      ]
  )));
}
