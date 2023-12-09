{ lib
, runCommand
, writeText
, git

, hol4
, kernel
}:

# TODO
# prefix with "time" invocation

let
  ignoreList = [
    "_start" "c_handle_fastpath_call" "c_handle_fastpath_reply_recv" "restore_user_context"
  ];

  # ignoreFile = runCommand "ignore" {} ''
  #   cat ${kernel}/kernel.sigs | cut -d ' ' -f 2 | grep -v memzero | tr '\n' ',' | sed 's/,$/\n/' > $out
  # '';

  ignoreFile = writeText "ignore" (lib.concatStringsSep "," ignoreList);

  scriptIn = writeText "x.sml" ''
    load "decompileLib";
    val _ = decompileLib.decomp "@path@" true "@ignore@";
  '';

in
runCommand "decompilation" {
  nativeBuildInputs = [
    git
  ];
}''
  target_dir=$(pwd)/target
  script=$(pwd)/script

  mkdir $target_dir
  cp ${kernel}/{kernel.elf.txt,kernel.sigs} target

  substitute ${scriptIn} $script \
    --subst-var-by path $target_dir/kernel \
    --subst-var-by ignore $(cat ${ignoreFile})

  cd ${hol4}/examples/machine-code/graph
  echo "decompiling..."
  ${hol4}/bin/hol < $script > $target_dir/log.txt
  cp -r $target_dir $out
''
