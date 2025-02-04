{ lib
, runCommand
, writeText
, writeScript
, runtimeShell

, graphRefine
, graphRefineSolverLists
, graphRefineWith
, sonolarBinary
}:

let
  inherit (graphRefineSolverLists.offlineCommands) yices cvc5;

  outputFor = name: command: runCommand "${name}-output.smt2" {} ''
    ${lib.concatStringsSep " " command} < ${./input.smt2} > $out
  '';

  output = {
    yices = outputFor "yices" yices;
    cvc5 = outputFor "cvc5" cvc5;
  };

  diff = runCommand "diff" {} ''
    diff ${output.yices} ${output.cvc5}
  '';
in {
  inherit output diff;
}
