FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    sudo \
    man \
    procps \
    rsync \
    file \
    less \
    vim \
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ARG UID
ARG GID

RUN set -eux; \
    if [ $UID -eq 0 ]; then \
        if [ $GID -ne 0 ]; then \
            echo "error: \$UID == 0 but \$GID != 0" >&2; \
            exit 1; \
        fi; \
    else \
        if getent passwd $UID; then \
            echo "error: \$UID $UID already exists" >&2; \
            exit 1; \
        fi; \
        if ! getent group $GID; then \
            groupadd --gid $GID x; \
        fi; \
        useradd --uid $UID --gid $GID --groups sudo --create-home x; \
    fi;

USER $UID

ENV NIX_BUILD_SHELL=bash

RUN ( \
        echo 'set show-mode-in-prompt on'; \
        echo 'set editing-mode vi'; \
    ) >> ~/.inputrc

WORKDIR /work/l4v
