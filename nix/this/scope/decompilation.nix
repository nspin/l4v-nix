{ lib
, runCommand
, writeText
, git

, hol4
, kernelWithCParser
}:

let
  ignore = [
    "_start" "c_handle_fastpath_call" "c_handle_fastpath_reply_recv" "restore_user_context"
  ];

  scriptIn = writeText "x.ml" ''
    load "decompileLib";
    val _ = decompileLib.decomp "@path@" true "${lib.concatStringsSep "," ignore}";
  '';

in
runCommand "decompilation" {
  nativeBuildInputs = [
    git
  ];
}''
  hol_dir=$(pwd)/src/HOL4
  target_dir=$(pwd)/target
  script=$(pwd)/script

  mkdir $(dirname $hol_dir)
  ln -s ${hol4} $hol_dir

  mkdir $target_dir
  cp ${kernelWithCParser}/{kernel.elf.txt,kernel.sigs} target

  substitute ${scriptIn} $script --subst-var-by path $target_dir/kernel

  cd $hol_dir/examples/machine-code/graph
  echo "decompiling..."
  $hol_dir/bin/hol < $script > $target_dir/log.txt
  cp -r $target_dir $out
''
