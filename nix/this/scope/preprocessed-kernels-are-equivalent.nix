{ lib
, runCommand

, scopeConfig
, simplExport
, kernelWithCParser
}:

# TODO
# --ignore-matching-lines='^$' is a hack to handle the possible '/* disabled: CONFIG_KERNEL_OPT_LEVEL_O[12] */' difference.

runCommand "preprocessed-kernels-are-identical" {} ''
  f() {
    diff "$@" \
      --ignore-matching-lines='^#' \
      --ignore-matching-lines='^/\*[^*]*\*/$' \
      --ignore-matching-lines='^$' \
      ${kernelWithCParser}/kernel_all.c_pp \
      ${simplExport}/spec/cspec/c/build/${scopeConfig.arch}/kernel_all.c_pp
  }

  # Show both diff and paths if different
  f || f -q

  touch $out
''
