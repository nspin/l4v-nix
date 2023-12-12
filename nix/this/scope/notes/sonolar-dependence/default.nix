{ lib
, linkFarm

, graphRefineSolverLists
, graphRefineWith
}:

let
  mk = { withSonolar ? true }:
    let
      caseName = "${if withSonolar then "with" else "without"}-sonolar";

      solverListsScope = graphRefineSolverLists.overrideScope (self: super: {
        offlineSolverFilter = attr:
          lib.optionals
            (!(attr == "sonolar" && !withSonolar))
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
  cases = lib.listToAttrs (map (case: lib.nameValuePair case.caseName case) (lib.flatten (lib.forEach [ true false ] (withSonolar: [
    (mk {
      inherit withSonolar;
    })
  ]))));

  evidence = linkFarm "evidence" (lib.mapAttrs (_: v: v.links) cases);
}
