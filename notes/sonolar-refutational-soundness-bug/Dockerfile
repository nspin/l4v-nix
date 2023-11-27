FROM debian:bookworm

RUN apt-get update -q && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    make \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /work/bin

WORKDIR /work

ENV PATH="/work/bin:$PATH"

RUN set -eux; \
    path="/work/bin/cvc4"; \
    url="http://cvc4.cs.stanford.edu/downloads/builds/x86_64-linux-opt/cvc4-1.5-x86_64-linux-opt"; \
    curl -L "$url" -o "$path"; \
    chmod +x "$path"

RUN set -eux; \
    path="/work/bin/sonolar"; \
    intermediate_path="sonolar.d"; \
    mkdir "$intermediate_path"; \
    url="https://www.informatik.uni-bremen.de/agbs/florian/sonolar/sonolar-2014-12-04-x86_64-linux.tar.gz"; \
    curl -L "$url" | tar -xz -C "$intermediate_path"; \
    cp "$intermediate_path"/*/bin/sonolar "$path"; \
    rm -r "$intermediate_path"; \
    chmod +x "$path"

COPY . .
