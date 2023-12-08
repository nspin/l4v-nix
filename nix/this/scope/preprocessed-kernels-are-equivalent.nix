{ lib
, runCommand

, scopeConfig
, simplExport
, kernel
}:

# TODO
# The following args are a hack to handle the possible '/* disabled: CONFIG_KERNEL_OPT_LEVEL_O[12] */' difference:
# --ignore-matching-lines='^/\*[^*]*\*/$'
# --ignore-matching-lines='^$'

runCommand "preprocessed-kernels-are-equivalent" {} ''
  f() {
    diff "$@" \
      --ignore-matching-lines='^#' \
      --ignore-matching-lines='^/\*[^*]*\*/$' \
      --ignore-matching-lines='^$' \
      ${kernel}/kernel_all.c_pp \
      ${simplExport}/spec/cspec/c/build/${scopeConfig.arch}/kernel_all.c_pp
  }

  # Show both diff and paths if different
  f || f -q

  touch $out
''
