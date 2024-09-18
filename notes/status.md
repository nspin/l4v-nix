### kernel
    - X64-O1 requires patch (uninitialized variables) (odd that not required for -O2)

### l4v
    - mcs fails because incomplete
    - AARCH64 fails

### decompiler
    - RISCV64-O2 fails:
        SRA instructions:
            Export FAILED for activateThread.
            Export FAILED for cap_get_capSizeBits.
            Export FAILED for restart.
            ...
            Failed to translate term: var_word "r15" s >> w2n (w2w (w2w (var_word "r14" s && 63w)))
            Failed to translate term: var_word "r14" s >> w2n (w2w (w2w (var_word "r12" s && 63w)))
            Failed to translate term: var_word "r15" s >> w2n (w2w (w2w (var_word "r13" s && 63w)))
    - ARM-O2 requires patch for BFI, should be generalized

### graph-refine
    - ARM-O1:
        - all but init_freemem (requires some patches)
            - branches:
                - coliasgroup/seL4:nspin/wip/init_freemem/*
    - ARM-O2
        - coverage alone fails for init_freemem and decodeARMMMUInvocation
        - multple NoSplit
        - multiple NOT proven
            - branches:
                coliasgroup/graph-refine:nspin/wip/o2/x
