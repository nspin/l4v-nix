{ lib
, writeText
, this
}:

with this;

let

in rec {
  x = writeText "x" (toString [
    byConfig.arm.gcc49.o0.graphRefineInputs
    byConfig.arm.gcc49.o1.graphRefineInputs
    byConfig.arm.gcc49.o2.graphRefineInputs
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
