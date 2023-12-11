FROM trustworthysystems/l4v-binary_decomp:2020_10_29

ARG UID
ARG GID

RUN set -eux; \
    if ! getent group $GID; then \
        groupadd -g $GID x; \
    fi; \
    if ! getent passwd $UID; then \
        useradd -u $UID -g $GID -m -p x x; \
    fi;

RUN chown -R $UID:$GID /isabelle

WORKDIR /work

RUN chown $UID .

USER $UID:$GID

RUN ln -s /isabelle ~/.isabelle

RUN set -eux; \
    repo init -u https://github.com/seL4/verification-manifest.git -m 12.0.0.xml; \
    repo sync;

RUN set -eux; \
    cd graph-refine; \
    git checkout seL4-12.0.0; \
    cd ../l4v; \
    git checkout 6700d97b7f0593dbf5d8145ee43f1e151553dea0;

RUN ./graph-refine/scripts/setup-HOL4.sh

# see l4v/README.md and graph-refine/seL4-example/configure_default.sh
RUN set -eux; \
    cd l4v; \
    mkdir -p ~/.isabelle/etc; \
    cp misc/etc/settings ~/.isabelle/etc/settings; \
    ./isabelle/bin/isabelle components -a; \
    ./isabelle/bin/isabelle jedit -bf; \
    ./isabelle/bin/isabelle build -bv HOL-Word;

ENV L4V_ARCH=ARM

RUN CONFIG_OPTIMISATION_LEVEL=-O1 make -C graph-refine/seL4-example target/${L4V_ARCH}-O1/CFunctions.txt
RUN CONFIG_OPTIMISATION_LEVEL=-O2 make -C graph-refine/seL4-example target/${L4V_ARCH}-O2/CFunctions.txt
RUN CONFIG_OPTIMISATION_LEVEL=-O1 make -C graph-refine/seL4-example target/${L4V_ARCH}-O1/ASMFunctions.txt
RUN CONFIG_OPTIMISATION_LEVEL=-O2 make -C graph-refine/seL4-example target/${L4V_ARCH}-O2/ASMFunctions.txt

RUN ln -s /smtsolvers/solverlist .solverlist

RUN CONFIG_OPTIMISATION_LEVEL=-O1 make -C graph-refine/seL4-example StackBounds coverage target/${L4V_ARCH}-O1/demo-report.txt

# TODO broken
# RUN CONFIG_OPTIMISATION_LEVEL=-O2 make -C graph-refine/seL4-example StackBounds coverage target/${L4V_ARCH}-O2/demo-report.txt

COPY Makefile.inside Makefile
