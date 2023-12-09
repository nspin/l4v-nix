{ lib
, newScope
, writeText
, z3
, yices

, cvc4BinariesFromIsabelle
, cvc4Binaries
, cvc5Binary
, sonolarBinary
, mathsat5Binary

, graphRefineSource
}:

lib.makeScope newScope (self: with self;
  let
    mkEnum = variants: lib.listToAttrs (map (variant: lib.nameValuePair variant variant) variants);

  in {
    selectedCVC4Binary = cvc4BinariesFromIsabelle.v1_5_3;

    # lib.makeScope injects "packages" attr
    packages' = {
      inherit z3 yices;
      cvc4 = selectedCVC4Binary;
      cvc5 = cvc5Binary;
      sonolar = sonolarBinary;
      mathsat5 = mathsat5Binary;
    };

    executables = {
      cvc4 = "${packages'.cvc4}/bin/cvc4";
      cvc5 = "${packages'.cvc5}/bin/cvc5";
      sonolar = "${packages'.sonolar}/bin/sonolar";
      mathsat5 = "${packages'.mathsat5}/bin/mathsat";
      z3 = "${packages'.z3}/bin/z3";
      yices = "${packages'.yices}/bin/yices-smt2";
    };

    onlineCommands = {
      cvc4 = [ executables.cvc4 "--lang" "smt" "--incremental" "--tlimit=120" ];
    };

    offlineCommands = {
      cvc4 = [ executables.cvc4 "--lang" "smt" ];
      cvc5 = [ executables.cvc5 "--incremental" "--lang" "smt" "--tlimit=120" ];
      sonolar = [ executables.sonolar "----input-format=smtlib2" ];
      yices = [ executables.yices ];
    };

    formatSolverList =
      { strategy
      , modelStrategy
      , onlineSolverKey
      , onlineSolvers
      , offlineSolverKey
      , offlineSolvers
      }:

      writeText "solverlist" ''
        strategy: ${lib.concatStringsSep ", " (lib.forEach strategy ({ key, scope }: "${key} ${scope}"))}
        model-strategy: ${lib.concatStringsSep ", " modelStrategy}
        online-solver: ${onlineSolverKey}
        offline-solver: ${offlineSolverKey}
        ${lib.concatStrings (lib.flip lib.mapAttrsToList onlineSolvers (key: { config, command }: ''
          ${key}: online: ${lib.concatStringsSep ", " config}: ${lib.concatStringsSep " " command}
        ''))}
        ${lib.concatStrings (lib.flip lib.mapAttrsToList offlineSolvers (key: { config, command }: ''
          ${key}: offline: ${lib.concatStringsSep ", " config}: ${lib.concatStringsSep " " command}
        ''))}
      '';

    granularities = mkEnum [
      "machineWord"
      "byte"
    ];

    scopes = mkEnum [
      "all"
      "hyp"
    ];

    formatGranularity = granularity: {
      "${granularities.machineWord}" = "machine-word";
      "${granularities.byte}" = "byte";
    }.${granularity};

    configForGranularity = granularity: {
      "${granularities.machineWord}" = [];
      "${granularities.byte}" = [ "mem_mode=8" ];
    }.${granularity};

    strategyFilter = attr: granularity: [ scopes.all scopes.hyp ];

    modelStrategyFilter = attr: granularity: true;

    onlineSolver = {
      command = onlineCommands.cvc4;
      config = configForGranularity granularities.machineWord;
    };

    offlineSolverKey = {
      attr = "cvc4";
      granularity = granularities.machineWord;
    };

    offlineSolverFilter = attr: [ granularities.machineWord granularities.byte ];

    formatKey = { attr, granularity }: "${attr}-${formatGranularity granularity}";

    formatSolverListArgs =
      let
        formattedOnlineSolverKey = "the-online-solver";
      in {
        strategy = lib.flatten (lib.forEach (lib.attrNames onlineCommands) (attr:
          lib.forEach (lib.attrValues granularities) (granularity:
            lib.forEach (strategyFilter attr granularity) (scope: {
              key = formatKey { inherit attr granularity; };
              inherit scope;
            })
          )
        ));

        modelStrategy = lib.flatten (lib.forEach (lib.attrNames onlineCommands) (attr:
          lib.forEach (lib.attrValues granularities) (granularity:
            lib.optionals (modelStrategyFilter attr granularity) [
              (formatKey { inherit attr granularity; })
            ]
          )
        ));

        onlineSolverKey = formattedOnlineSolverKey;

        onlineSolvers = {
          "${formattedOnlineSolverKey}" = onlineSolver;
        };

        offlineSolverKey = formatKey offlineSolverKey;

        offlineSolvers = lib.listToAttrs (lib.concatLists (lib.flip lib.mapAttrsToList offlineCommands (attr: command:
          (lib.forEach (lib.attrValues granularities) (granularity:
            lib.nameValuePair (formatKey { inherit attr granularity; }) {
              inherit command;
              config = configForGranularity granularity;
            }
          ))
        )));
      };

    solverlist = formatSolverList formatSolverListArgs;

    default = solverlist;

    # default = mattSolverlist;

    mattSolverlist =
      let
        f = import (graphRefineSource + "/nix/solvers.nix");
        dir = (f { use_sonolar = true; }).solverlist;
      in
        "${dir}/.solverlist";
  }
)
