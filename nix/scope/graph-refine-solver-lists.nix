{ lib
, writeText
, writeShellApplication
, yices

, cvc4Binary
, sonolarBinary

, expect
, python3
, mkShell
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

  cvc4OnlineWrapper = writeShellApplication {
    name = "x";
    checkPhase = "";
    runtimeInputs = [ python3 ];
    text = ''
      # echo YYYYYYYYY >&2
      t=$(date +"%T.%6N")
      # t=xxx
      # echo XXXXXXXXX "$t" >&2
      # cat | tee in."$t".smt2 | cat | ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000 "$@" | cat
      cat | cat | ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
      # ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000 "$@" | tee out."$t".smt2
      # ${expect}/bin/unbuffer -p tee in."$t".smt2 | ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000 "$@"
      #  | tee out."$t".smt2
      # exec bash -c "set -o pipefail; tee in.$t.smt2 | ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000 $@"
      # exec python3 -u ${script}
    '';
  };

  script = writeText "x.py" ''
    import time
    import subprocess
    from threading import Thread

    p = subprocess.Popen(
      ["${cvc4BinaryExe}", "--incremental", "--lang", "smt", "--tlimit=5000"]
      stdin=subprocess.PIPE,
    )

    def f(p):
      import sys
      for line in sys.stdin:
        p.stdin.write(line)

    Thread(target=f, args=p).start()

    p.wait()
  '';

  cvc4OnlineWrapperExe = "${cvc4OnlineWrapper}/bin/x";

  sonolarWrapper = writeShellApplication {
    name = "x";
    text = ''
      t=$(date +"%T.%6N")
      echo "$t" >&2
      cat | tee -a in."$t".smt2 | ${sonolarBinaryExe} --input-format=smtlib2
    '';
  };

  sonolarWrapperExe = "${sonolarWrapper}/bin/x";

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
    # SONOLAR: offline: ${sonolarWrapperExe} --input-format=smtlib2
    # CVC4: offline: ${cvc4BinaryExe} --lang smt
    SONOLAR-word8: offline: ${sonolarWrapperExe} --input-format=smtlib2
      config: mem_mode = 8
  '';
    # SONOLAR: offline: ${sonolarWrapperExe}
    # SONOLAR: offline: ${sonolarWrapperExe} --input-format=smtlib2

  wip2 = writeText "solverlist" ''
    # CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    CVC4: online: ${cvc4OnlineWrapperExe}
    SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    CVC4: offline: ${cvc4BinaryExe} --lang smt
    Yices: offline: ${yicesSmt2Exe}
    CVC4-word8: offline: ${cvc4BinaryExe} --lang smt
      config: mem_mode = 8
    Yices-word8: offline: ${yicesSmt2Exe}
      config: mem_mode = 8
  '';

  s = mkShell {
    nativeBuildInputs = [
      cvc4Binary.v1_5
    ];
  };
}
