# =============================================================================
#  VOXD packaging builder
#
#  Build:
#    docker build -t voxd-builder .
#
#  Extract packages:
#    docker run --rm -v $PWD/dist:/out voxd-builder
#
#  Or with custom version / arch:
#    docker run --rm -v $PWD/dist:/out \
#      -e VERSION=1.5.0 -e ARCH=arm64 voxd-builder
# =============================================================================

FROM debian:bookworm-slim AS nfpm-builder
# Use a stable version tag to avoid depending on GitHub redirect-to-latest
ARG NFPM_VERSION=2.46.3
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL \
      "https://github.com/goreleaser/nfpm/releases/download/v${NFPM_VERSION}/nfpm_${NFPM_VERSION}_Linux_x86_64.tar.gz" \
      -o /tmp/nfpm.tar.gz \
    && tar -xzf /tmp/nfpm.tar.gz -C /usr/local/bin/ nfpm \
    && rm /tmp/nfpm.tar.gz \
    && chmod +x /usr/local/bin/nfpm

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=nfpm-builder /usr/local/bin/nfpm /usr/local/bin/nfpm

WORKDIR /workspace
COPY . .

ARG VERSION=1.4.1
ARG ARCH=amd64
ENV VERSION=${VERSION} ARCH=${ARCH}

RUN mkdir -p dist \
    && sed -i "s/^version = .*/version = \"$VERSION\"/" pyproject.toml \
    && nfpm pkg --packager deb -f packaging/nfpm.yaml --target dist/

# Default: copy .deb to mounted /out/
CMD ["sh", "-c", "cp -v dist/voxd_${VERSION}-1_${ARCH}.deb /out/"]
