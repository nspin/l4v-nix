{ lib
, linkFarm

, graphRefineSolverLists
, graphRefineWith
}:

let
  mk = { withSonolar ? true, withBitwuzla ? true }:
    let
      mkSuffix = solver: with_: lib.optionalString (!with_) "-without-${solver}";

      caseName = "all${mkSuffix "sonolar" withSonolar}${mkSuffix "bitwuzla" withBitwuzla}";

      solverListsScope = graphRefineSolverLists.overrideScope (self: super: {
        offlineSolverFilter = attr:
          lib.optionals
            (!(attr == "sonolar" && !withSonolar) && !(attr == "bitwuzla" && !withBitwuzla))
            (super.offlineSolverFilter attr);
      });

      solverList = solverListsScope.default;

      links = linkFarm "${caseName}-links" {
        all = graphRefineWith {
          name = caseName;
          args = [
            "trace-to:report.txt" "save-proofs:proofs.txt" "all"
          ];
        };
      };
    in {
      inherit caseName solverList links;
    };

in rec {
  cases = lib.listToAttrs (map (case: lib.nameValuePair case.caseName case) (lib.flatten
    (lib.forEach [ true false ] (withSonolar:
      (lib.forEach [ true false ] (withBitwuzla:
        lib.optionals
          (lib.any lib.id [
            (!withSonolar)
            (withSonolar && withBitwuzla)
          ])
          [
            (mk {
              inherit withSonolar withBitwuzla;
            })
          ]
      ))
    ))
  ));

  evidence = linkFarm "evidence" (lib.mapAttrs (_: v: v.links) cases);
}
