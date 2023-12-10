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
, bitwuzla_0_2_0

, graphRefineSource
}:

# TODO
# It doesn't seem like these support arrays as arguments to functions, but worth investigating further:
# - boolector
# - bitwuzla 0.1.0

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
      bitwuzla = bitwuzla_0_2_0;
    };

    executables = lib.mapAttrs (lib.const lib.singleton) {
      cvc4 = "${packages'.cvc4}/bin/cvc4";
      cvc5 = "${packages'.cvc5}/bin/cvc5";
      sonolar = "${packages'.sonolar}/bin/sonolar";
      mathsat5 = "${packages'.mathsat5}/bin/mathsat";
      z3 = "${packages'.z3}/bin/z3";
      yices = "${packages'.yices}/bin/yices-smt2";
      bitwuzla = "${packages'.bitwuzla}/bin/bitwuzla";
    };


    offlineCommands = {
      cvc4 = executables.cvc4 ++ [ "--lang" "smt" ];
      cvc5 = executables.cvc5 ++ [ "--lang" "smt" ];
      sonolar = executables.sonolar ++ [ "--input-format=smtlib2" ];
      mathsat5 = executables.mathsat5 ++ [ "-input=smt2" ];
      z3 = executables.z3 ++ [ "-smt2" "-in" ];
      yices = executables.yices;
      bitwuzla = executables.bitwuzla;
    };

    onlineCommands = {
      cvc4 = offlineCommands.cvc4 ++ [ "--incremental" "--tlimit=${cvc4TLimit}" ];
      cvc5 = offlineCommands.cvc5 ++ [ "--incremental" "--tlimit=${cvc5TLimit}" ];
      z3 = offlineCommands.z3;
      yices = offlineCommands.yices ++ [ "--incremental" ];
      bitwuzla = offlineCommands.bitwuzla;
    };

    cvc4TLimit = "120";
    cvc5TLimit = "120";

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
      command = onlineCommands.yices;
      config = configForGranularity granularities.machineWord;
    };

    offlineSolverKey = {
      attr = "yices";
      granularity = granularities.machineWord;
    };

    offlineSolverFilter = attr: [
      granularities.machineWord
      granularities.byte
    ];

    formatKey = { attr, granularity }: "${attr}-${formatGranularity granularity}";

    formatSolverListArgs =
      let
        formattedOnlineSolverKey = "the-online-solver";
      in {
        strategy = lib.flatten (lib.forEach (lib.attrNames offlineCommands) (attr:
          lib.forEach (offlineSolverFilter attr) (granularity:
            lib.forEach (strategyFilter attr granularity) (scope: {
              key = formatKey { inherit attr granularity; };
              inherit scope;
            })
          )
        ));

        modelStrategy = lib.flatten (lib.forEach (lib.attrNames offlineCommands) (attr:
          lib.forEach (offlineSolverFilter attr) (granularity:
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
          (lib.forEach (offlineSolverFilter attr) (granularity:
            lib.nameValuePair (formatKey { inherit attr granularity; }) {
              inherit command;
              config = configForGranularity granularity;
            }
          ))
        )));
      };

    solverList = formatSolverList formatSolverListArgs;

    default = solverList;

    # default = mattSolverlist;

    mattSolverlist =
      let
        f = import (graphRefineSource + "/nix/solvers.nix");
        dir = (f { use_sonolar = true; }).solverlist;
      in
        "${dir}/.solverlist";
  }
)
