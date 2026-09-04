---
type: Architecture
title: Dockerfile
description: Dockerfile reference for komodo-periphery-sops-age, detailing base image, installation steps, build arguments, OCI labels, and multi-arch handling.
tags: [architecture, dockerfile, docker, sops, age]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-04T09:25:18.613Z
sources:
  - id: openwiki-source-bb1ebe868e35e9e500714501
    resource: repo://Dockerfile
generated: { by: "openwiki/0.5.0", at: "2026-09-04T09:25:18.613Z" }
---

# Dockerfile Reference

This page documents the `Dockerfile` that constructs the komodo-periphery-sops-age image.

## Dockerfile Content

```dockerfile
# syntax=docker/dockerfile:1
FROM ghcr.io/moghtech/komodo-periphery:2

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

LABEL org.opencontainers.image.base.name="ghcr.io/moghtech/komodo-periphery:2"
LABEL org.opencontainers.image.base.version="${BASE_VERSION}"
LABEL org.opencontainers.image.base.digest="${BASE_DIGEST}"
LABEL org.opencontainers.image.sops.version="${SOPS_VERSION}"
LABEL org.opencontainers.image.age.version="${AGE_VERSION}"
```

## Line-by-Line Analysis

### Base Image (line 2)
```dockerfile
FROM ghcr.io/moghtech/komodo-periphery:2
```
- Uses the **major channel 2** of Komodo Periphery
- The workflow resolves the exact `x.y.z` tag at build time
- Base digest/version recorded in labels for traceability

### User Switch (line 4)
```dockerfile
USER root
```
- Required for package installation and binary placement in `/usr/local/bin`
- Base image may run as non-root; this elevates for build steps only

### System Dependencies (lines 6-15)
```dockerfile
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
```
- **Dual package manager support:** Works on Alpine (`apk`) and Debian/Ubuntu (`apt-get`) bases
- **Installs:** `ca-certificates` (TLS for downloads), `curl` (download), `tar` (extract age)
- **Cleanup:** Removes apt cache; Alpine's `--no-cache` avoids cache buildup

### Build Arguments (lines 17-21)
```dockerfile
ARG TARGETARCH
ARG SOPS_VERSION
ARG AGE_VERSION
ARG BASE_DIGEST=""
ARG BASE_VERSION=""
```
- **TARGETARCH:** Set by docker/build-push-action for multi-arch builds; defaults to `amd64` if not set (via `${TARGETARCH:-amd64}`).
- **SOPS_VERSION** and **AGE_VERSION:** Injected by the build workflow to pin specific tool versions.
- **BASE_DIGEST** and **BASE_VERSION:** Left empty by default; populated by the build workflow to record the base image's digest and version for traceability.

### Architecture Detection and Tool Installation (lines 23-43)
```dockerfile
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
```
- **Architecture mapping:** Converts `TARGETARCH` (e.g., `amd64`, `arm64`) to the asset naming used by SOPS and age.
- **SOPS installation:** Downloads the pre-built binary for the detected architecture, makes it executable, and verifies it.
- **age installation:** Downloads the tar.gz archive, extracts it, moves the `age` and `age-keygen` binaries to `/usr/local/bin`, and cleans up.
- **Version check:** Runs `sops --version --check-for-updates` and `age --version` to confirm installation and note any available updates (non-fatal).

### OCI Labels (lines 45-49)
```dockerfile
LABEL org.opencontainers.image.base.name="ghcr.io/moghtech/komodo-periphery:2"
LABEL org.opencontainers.image.base.version="${BASE_VERSION}"
LABEL org.opencontainers.image.base.digest="${BASE_DIGEST}"
LABEL org.opencontainers.image.sops.version="${SOPS_VERSION}"
LABEL org.opencontainers.image.age.version="${AGE_VERSION}"
```
- **base.name:** Notes the base image reference used.
- **base.version** and **base.digest:** Record the exact version and digest of the base image (set at build time).
- **sops.version** and **age.version:** Record the versions of the installed tools.
