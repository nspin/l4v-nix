{ lib
, sources
}:

rec {

  default = matt;

  mattFn = import (sources.currentGraphRefine + "/nix/solvers.nix");

  mattDir = (mattFn { use_sonolar = false; }).solverlist;

  matt = "${mattDir}/.solverlist";

}
