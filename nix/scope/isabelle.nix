{ isabelleFromOldNixpkgs
, coreutils
, isabelle-sha1
}:

isabelleFromOldNixpkgs.overrideAttrs (attrs: {
  postPatch = attrs.postPatch + ''
    substituteInPlace \
      lib/Tools/env \
        --replace /usr/bin/env ${coreutils}/bin/env

    substituteInPlace \
      src/Pure/General/sha1.ML \
        --replace \
          '"$ML_HOME/" ^ (if ML_System.platform_is_windows then "sha1.dll" else "libsha1.so")' \
          '"${isabelle-sha1}/lib/libsha1.so"'
  '';
})
