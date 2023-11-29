FROM debian as repo-fetch

RUN apt-get update -q && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    openssh-client \
    python3 \
    python-is-python3 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ~/bin

RUN set -eux; \
    export REPO=$(mktemp /tmp/repo.XXXXXXXXX); \
    curl -o ${REPO} https://storage.googleapis.com/git-repo-downloads/repo; \
    gpg --recv-keys 8BB9AD793E8E6153AF0F9A4416530D5E920F5C65; \
    curl -s https://storage.googleapis.com/git-repo-downloads/repo.asc | gpg --verify - ${REPO} && install -m 755 ${REPO} ~/bin/repo

ENV PATH=/root/bin:${PATH}

WORKDIR /work

RUN set -eux; \
    repo init -u https://github.com/seL4/verification-manifest.git -m 11.0.0.xml; \
    repo sync

FROM trustworthysystems/l4v-binary_decomp:2019_11_29

COPY --from=repo-fetch /work /work

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

RUN chown -R $UID .

USER $UID:$GID

RUN ln -s /isabelle ~/.isabelle

RUN bash ./graph-refine/scripts/setup-HOL4.sh

# see l4v/README.md and graph-refine/seL4-example/configure_default.sh
RUN set -eux; \
    cd l4v; \
    mkdir -p ~/.isabelle/etc; \
    cp misc/etc/settings ~/.isabelle/etc/settings; \
    ./isabelle/bin/isabelle components -a; \
    ./isabelle/bin/isabelle jedit -bf; \
    ./isabelle/bin/isabelle build -bv HOL-Word;

ENV L4V_ARCH=ARM

# it's broken
ENV SKIP_SOLV_TEST=1

RUN make -C graph-refine/seL4-example CFunctions.txt

RUN make -C graph-refine/seL4-example ASMFunctions.txt

RUN make -C graph-refine/seL4-example kernel.elf.rodata kernel.elf.symtab

RUN ln -s /smtsolvers/solverlist .solverlist

RUN set -eux; \
    cd graph-refine; \
    git checkout 4954637c0b906ded2a8fcb1f08faedd9d2940b2e;

RUN set -eux; \
    cd graph-refine/seL4-example; \
    python ../graph-refine.py .

# RUN make -C graph-refine/seL4-example StackBounds.txt

# RUN make -C graph-refine/seL4-example demo-report.txt

# # RUN make -C graph-refine/seL4-example report

COPY Makefile.inside Makefile

# RUN make all
