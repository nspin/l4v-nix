#!/usr/bin/env bash

set -eu -o pipefail

resources_dir=resources

solvers="cvc4 sonolar"

run_solver() {
    case $1 in
        cvc4)
            cvc4 --lang smt
            ;;
        sonolar)
            sonolar --input-format=smtlib2
            ;;
        *)
            echo !
            false
            ;;
    esac
}

for solver in $solvers; do
    echo ">>> getting model from $solver"
    cat $resources_dir/common.smt2 $resources_dir/get.smt2 | run_solver $solver
done

for run_solver in $solvers; do
    for use_model_from_solver in $solvers; do
        echo ">>> running $run_solver with model from $use_model_from_solver"
        cat $resources_dir/common.smt2 $resources_dir/check-$use_model_from_solver.smt2 | run_solver $run_solver
    done
done
