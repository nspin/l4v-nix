{ lib
, writeText
, writeScript
, writeShellApplication
, runtimeShell
, yices

, cvc4Binary
, sonolarBinary

}:

# TODO
# - tune
# - figure out why are cvc4 >= 1.6 and cvc5 so slow
# - figure out why cvc5 throws ConversationProblem
# - figure out why sonolar with mem_mode = 8 doesn't work
# - z3 offline

let
  cvc4BinaryExe = "${cvc4Binary.v1_5}/bin/cvc4";
  sonolarBinaryExe = "${sonolarBinary}/bin/sonolar";
  yicesSmt2Exe = "${yices}/bin/yices-smt2";

  wrap = writeScript "wrap" ''
    #!${runtimeShell}

    set -u -o pipefail

    t=$(date +%s.%6N)
    d=tmp/tlogs/$t

    mkdir -p $d

    echo $t >&2

    echo $$ > $d/pid.txt
    echo "$@" > $d/args.txt

    "$@" < <(tee $d/in.smt2) > >(tee $d/out.smt2)
    ret=$?

    echo $ret > $d/ret.txt

    exit $ret
  '';

in rec {
  default = original;

  original = writeText "solverlist" ''
    CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    CVC4: offline: ${cvc4BinaryExe} --lang smt
    SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
      config: mem_mode = 8
  '';

  new = writeText "solverlist" ''
    CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    CVC4: offline: ${cvc4BinaryExe} --lang smt
    Yices: offline: ${yicesSmt2Exe}
    CVC4-word8: offline: ${cvc4BinaryExe} --lang smt
      config: mem_mode = 8
    Yices-word8: offline: ${yicesSmt2Exe}
      config: mem_mode = 8
  '';
    # TODO
    # SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
    #   config: mem_mode = 8

  wip1 = writeText "solverlist" ''
    CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    # SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    # CVC4: offline: ${cvc4BinaryExe} --lang smt
    SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
      config: mem_mode = 8
  '';
    # SONOLAR: offline: ${sonolarBinaryExe}
    # SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2

  wip2 = writeText "solverlist" ''
    CVC4: online: ${wrap} ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    CVC4: offline: ${cvc4BinaryExe} --lang smt
    Yices: offline: ${yicesSmt2Exe}
    CVC4-word8: offline: ${cvc4BinaryExe} --lang smt
      config: mem_mode = 8
    Yices-word8: offline: ${yicesSmt2Exe}
      config: mem_mode = 8
  '';

  wip3 = writeText "solverlist" ''
    CVC4: online: ${wrap} ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    CVC4: offline: ${cvc4BinaryExe} --lang smt
    SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
      config: mem_mode = 8
  '';
}
