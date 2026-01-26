# syntax=docker/dockerfile:1
FROM ghcr.io/moghtech/komodo-periphery:latest

USER root

RUN set -eux; \
    if command -v apk >/dev/null 2>&1; then \
    apk add --no-cache ca-certificates curl tar; \
    update-ca-certificates; \
    elif command -v apt-get >/dev/null 2>&1; then \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl tar; \
    rm -rf /var/lib/apt/lists/*; \
    update-ca-certificates || true; \
    fi

ARG TARGETARCH
ARG SOPS_VERSION
ARG AGE_VERSION
ARG BASE_DIGEST=""
ARG BASE_VERSION=""

RUN set -eux; \
    arch="${TARGETARCH:-amd64}"; \
    case "$arch" in \
    amd64) sops_arch="amd64"; age_arch="amd64" ;; \
    arm64) sops_arch="arm64"; age_arch="arm64" ;; \
    *) echo "Unsupported TARGETARCH: $arch"; exit 1 ;; \
    esac; \
    \
    curl -fsSL -o /usr/local/bin/sops \
    "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${sops_arch}"; \
    chmod +x /usr/local/bin/sops; \
    \
    curl -fsSL -o /tmp/age.tar.gz \
    "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${age_arch}.tar.gz"; \
    tar -xzf /tmp/age.tar.gz -C /tmp; \
    mv "/tmp/age/age" "/tmp/age/age-keygen" /usr/local/bin/; \
    chmod +x /usr/local/bin/age /usr/local/bin/age-keygen; \
    rm -rf /tmp/age /tmp/age.tar.gz; \
    \
    sops --version --check-for-updates; \
    age --version

LABEL org.opencontainers.image.base.name="ghcr.io/moghtech/komodo-periphery:latest"
LABEL org.opencontainers.image.base.version="${BASE_VERSION}"
LABEL org.opencontainers.image.base.digest="${BASE_DIGEST}"
LABEL org.opencontainers.image.sops.version="${SOPS_VERSION}"
LABEL org.opencontainers.image.age.version="${AGE_VERSION}"
