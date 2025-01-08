FROM ghcr.io/blinklabs-io/haskell:9.6.4-3.10.2.0-1 AS cardano-cli-build
# Install cardano-cli
ARG CLI_VERSION=10.2.0.0
ENV CLI_VERSION=${CLI_VERSION}
RUN echo "Building tags/${CLI_VERSION}..." \
    && echo tags/cardano-cli-${CLI_VERSION} > /CARDANO_BRANCH \
    && git clone https://github.com/input-output-hk/cardano-cli.git \
    && cd cardano-cli \
    && git fetch --all --recurse-submodules --tags \
    && git tag \
    && git checkout tags/cardano-cli-${CLI_VERSION} \
    && echo "with-compiler: ghc-${GHC_VERSION}" >> cabal.project.local \
    && echo "tests: False" >> cabal.project.local \
    && cabal update \
    && cabal build all \
    && mkdir -p /root/.local/bin/ \
    && cp -p dist-newstyle/build/$(uname -m)-linux/ghc-${GHC_VERSION}/cardano-cli-${CLI_VERSION}/x/cardano-cli/build/cardano-cli/cardano-cli /root/.local/bin/ \
    && rm -rf /root/.cabal/packages \
    && rm -rf /usr/local/lib/ghc-${GHC_VERSION}/ /usr/local/share/doc/ghc-${GHC_VERSION}/ \
    && rm -rf /code/cardano-cli/dist-newstyle/ \
    && rm -rf /root/.cabal/store/ghc-${GHC_VERSION}

FROM debian:bookworm-slim AS cardano-cli
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
COPY --from=cardano-cli-build /usr/local/lib/ /usr/local/lib/
COPY --from=cardano-cli-build /usr/local/include/ /usr/local/include/
COPY --from=cardano-cli-build /root/.local/bin/cardano-* /usr/local/bin/
RUN apt-get update -y && \
  apt-get install -y \
    bc \
    curl \
    iproute2 \
    jq \
    libffi8 \
    libgmp10 \
    liblmdb0 \
    libncursesw5 \
    libnuma1 \
    libsystemd0 \
    libssl3 \
    libtinfo6 \
    llvm-14-runtime \
    netbase \
    pkg-config \
    procps \
    socat \
    sqlite3 \
    wget \
    zlib1g && \
  rm -rf /var/lib/apt/lists/* && \
  chmod +x /usr/local/bin/*
ENTRYPOINT ["/usr/local/bin/cardano-cli"]
