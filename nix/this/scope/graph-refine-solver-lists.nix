{ lib
, sources
}:

rec {

  default = matt;

  mattFn = import (sources.graphRefine + "/nix/solvers.nix");

  mattDir = (mattFn { use_sonolar = false; }).solverlist;

  matt = "${mattDir}/.solverlist";

}
