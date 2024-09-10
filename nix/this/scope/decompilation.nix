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
  # kernel = "${hol4}/examples/machine-code/graph/seL4-kernel/arm";

  # NOTE only change to this list since seL4-12.0.0 is the addition of "_start"
  # ignoreList = [
  #   "_start" "c_handle_fastpath_call" "c_handle_fastpath_reply_recv" "restore_user_context"
  # ];

  ignoreList = [
    "fastpath_restore"
    "restore_user_context"
    "_start"
    "arm_prefetch_abort_exception"
    "arm_data_abort_exception"
  ];

  # ignoreFile = runCommand "ignore" {} ''
  #   cat ${kernel}/kernel.sigs | cut -d ' ' -f 2 | grep -v memzero | tr '\n' ',' | sed 's/,$/\n/' > $out
  # '';

  # only = "dist_init";
  only = "doNormalTransfer";

  ignoreFile = runCommand "ignore" {} ''
    echo -n '${lib.concatStringsSep "," ignoreList}' > $out
    cat ${kernel}/kernel.sigs | cut -d ' ' -f 2 | grep -v ${only} | tr '\n' ',' | sed 's/,$/\n/' >> $out
  '';

  # ignoreFile = writeText "ignore" (lib.concatStringsSep "," ignoreList);

  scriptIn = writeText "x.sml" ''
    load "decompileLib";
    val _ = decompileLib.decomp "@path@" true "@ignore@";
  '';

  unchecked = runCommand "decompilation" {
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
    ${hol4}/bin/hol < $script | tee $target_dir/log.txt
    #  | grep 'Export FAILED'
    cp -r $target_dir $out
  '';
in
runCommand "decompilation-checked" {
  passthru = {
    inherit unchecked;
  };
} ''
  if grep 'Export FAILED' ${unchecked}/log.txt; then
    false
  fi

  cp -r ${unchecked} $out
''
