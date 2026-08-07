---
type: Architecture
title: Dockerfile
description: Dockerfile reference for komodo-periphery-sops-age, detailing base image, installation steps, build arguments, OCI labels, and multi-arch handling.
resource: file:///openwiki/architecture/dockerfile.md
tags: [architecture, dockerfile, docker, sops, age]
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
| Arg | Source | Required | Purpose |
|-----|--------|----------|---------|
| `TARGETARCH` | Buildx (auto) | Yes | Target architecture for multi-arch |
| `SOPS_VERSION` | Workflow | Yes | SOPS release version (e.g., `3.8.1`) |
| `AGE_VERSION` | Workflow | Yes | age release version (e.g., `1.2.0`) |
| `BASE_DIGEST` | Workflow | No | Base image digest for label |
| `BASE_VERSION` | Workflow | No | Base image version tag for label |

**Note:** `BASE_DIGEST` and `BASE_VERSION` default to empty strings so the Dockerfile builds locally without the workflow.

### Tool Installation (lines 23-43)

#### Architecture Mapping (lines 24-29)
```dockerfile
arch="${TARGETARCH:-amd64}";
case "$arch" in
amd64) sops_arch="amd64"; age_arch="amd64" ;;
arm64) sops_arch="arm64"; age_arch="arm64" ;;
*) echo "Unsupported TARGETARCH: $arch"; exit 1 ;;
esac;
```
- Maps Buildx `TARGETARCH` to release asset naming conventions
- Both SOPS and age use `amd64`/`arm64` in their release filenames
- Fails fast on unsupported architectures

#### SOPS Installation (lines 31-33)
```dockerfile
curl -fsSL -o /usr/local/bin/sops \
"https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${sops_arch}";
chmod +x /usr/local/bin/sops;
```
- Downloads **static binary** directly from GitHub releases
- Asset pattern: `sops-v{VERSION}.linux.{ARCH}`
- Installs to `/usr/local/bin/sops` (in PATH)

#### age Installation (lines 35-40)
```dockerfile
curl -fsSL -o /tmp/age.tar.gz \
"https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${age_arch}.tar.gz";
tar -xzf /tmp/age.tar.gz -C /tmp;
mv "/tmp/age/age" "/tmp/age/age-keygen" /usr/local/bin/;
chmod +x /usr/local/bin/age /usr/local/bin/age-keygen;
rm -rf /tmp/age /tmp/age.tar.gz;
```
- Downloads **tarball** containing both `age` and `age-keygen`
- Asset pattern: `age-v{VERSION}-linux-{ARCH}.tar.gz`
- Extracts, moves both binaries, cleans up

#### Verification (lines 42-43)
```dockerfile
sops --version --check-for-updates;
age --version
```
- Validates binaries execute correctly
- `--check-for-updates` exercises SOPS network stack (non-fatal)
- Output appears in build logs for verification

### OCI Labels (lines 45-49)
```dockerfile
LABEL org.opencontainers.image.base.name="ghcr.io/moghtech/komodo-periphery:2"
LABEL org.opencontainers.image.base.version="${BASE_VERSION}"
LABEL org.opencontainers.image.base.digest="${BASE_DIGEST}"
LABEL org.opencontainers.image.sops.version="${SOPS_VERSION}"
LABEL org.opencontainers.image.age.version="${AGE_VERSION}"
```
| Label | Value Source | Example |
|-------|--------------|---------|
| `org.opencontainers.image.base.name` | Constant | `ghcr.io/moghtech/komodo-periphery:2` |
| `org.opencontainers.image.base.version` | `BASE_VERSION` arg | `2.1.3` |
| `org.opencontainers.image.base.digest` | `BASE_DIGEST` arg | `sha256:abc123...` |
| `org.opencontainers.image.sops.version` | `SOPS_VERSION` arg | `3.8.1` |
| `org.opencontainers.image.age.version` | `AGE_VERSION` arg | `1.2.0` |

**Note:** `org.opencontainers.image.version` (the image's own version) is applied by the workflow via `docker/metadata-action`, not in the Dockerfile.

## Multi-Architecture Handling

The Dockerfile is architecture-agnostic except for the `TARGETARCH` mapping. Buildx handles:
- Cross-compilation via QEMU (for `arm64` on `amd64` runners)
- Manifest list creation combining both architectures
- Automatic `TARGETARCH` injection per platform

## Build Command (Workflow-Equivalent)

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg SOPS_VERSION=3.8.1 \
  --build-arg AGE_VERSION=1.2.0 \
  --build-arg BASE_DIGEST=sha256:... \
  --build-arg BASE_VERSION=2.1.3 \
  -t ghcr.io/smoochy/komodo-periphery-sops-age:2.1.3 \
  --push .
```

## Change Guidance

| Change | Location |
|--------|----------|
| Update base image | Line 2 (`FROM`) + workflow line 137 |
| Add system dependency | Lines 6-15 (apk/apt-get blocks) |
| Change SOPS download URL | Line 32 |
| Change age download URL | Line 36 |
| Add new binary to install | After line 40, before verification |
| Modify architecture support | Lines 25-29 (case statement) |
| Change install destination | Lines 32, 38 (`/usr/local/bin/`) |
| Add OCI label | Lines 45-49 (new LABEL line) |

## Validation Commands

```bash
# Build locally (single arch, no workflow)
docker build \
  --build-arg SOPS_VERSION=3.8.1 \
  --build-arg AGE_VERSION=1.2.0 \
  -t komodo-periphery-sops-age:local .

# Test binaries in built image
docker run --rm komodo-periphery-sops-age:local sops --version
docker run --rm komodo-periphery-sops-age:local age --version
docker run --rm komodo-periphery-sops-age:local age-keygen --version

# Inspect labels
docker inspect komodo-periphery-sops-age:local --format '{{json .Config.Labels}}' | jq
```

## Relationships

- **Consumed by** → [Build System](build-system.md) via `docker/build-push-action`
- **Receives versions from** → Build System (build args)
<!-- openwiki: broken internal link [reference/image-metadata.md] file "reference/image-metadata.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Produces** → [Image Metadata](reference/image-metadata.md) (labels)
- **Base image** → `ghcr.io/moghtech/komodo-periphery:2`
- **Upstream sources** → `getsops/sops` releases, `FiloSottile/age` releases