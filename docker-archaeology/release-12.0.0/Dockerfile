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
ENV CONFIG_OPTIMISATION_LEVEL=-O1
ENV TARGET_NAME=${L4V_ARCH}${CONFIG_OPTIMISATION_LEVEL}
ENV TARGET_DIR=target/${TARGET_NAME}

RUN make -C graph-refine/seL4-example ${TARGET_DIR}/CFunctions.txt

RUN make -C graph-refine/seL4-example ${TARGET_DIR}/ASMFunctions.txt

RUN ln -s /smtsolvers/solverlist .solverlist

RUN make -C graph-refine/seL4-example StackBounds

RUN make -C graph-refine/seL4-example coverage

RUN make -C graph-refine/seL4-example ${TARGET_DIR}/demo-report.txt

# RUN make -C graph-refine/seL4-example report

COPY Makefile.inside Makefile

# RUN make
