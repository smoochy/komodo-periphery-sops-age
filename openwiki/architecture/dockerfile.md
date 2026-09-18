---
type: Architecture
title: Dockerfile Reference
description: Line-by-line Dockerfile documentation covering base image, system dependencies, architecture-specific binary downloads, runtime verification, and OCI labels.
tags: [architecture, dockerfile, docker, sops, age]
verified:
  - by: openwiki/0.5.2
    at: 2026-09-18T09:31:26.072Z
sources:
  - id: openwiki-source-bb1ebe868e35e9e500714501
    resource: repo://Dockerfile
generated: { by: "openwiki/0.5.2", at: "2026-09-18T09:31:26.072Z" }
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
- **Why dual support exists:** The base image `ghcr.io/moghtech/komodo-periphery:2` may change its underlying distribution between releases. Using runtime detection (`command -v`) ensures the Dockerfile works regardless of whether the base is Alpine-based or Debian-based.
- **Installs:** `ca-certificates` (TLS for downloads), `curl` (download), `tar` (extract age)
- **Cleanup:** Removes apt cache; Alpine's `--no-cache` avoids cache buildup
- **`update-ca-certificates`** ensures the downloaded binaries can verify TLS certificates from GitHub releases

### Build Arguments (lines 17-21)

```dockerfile
ARG TARGETARCH
ARG SOPS_VERSION
ARG AGE_VERSION
ARG BASE_DIGEST=""
ARG BASE_VERSION=""
```

| Argument | Source | Purpose |
|----------|--------|---------|
| `TARGETARCH` | `docker/build-push-action` (auto-set for multi-arch builds) | Determines which architecture-specific binaries to download |
| `SOPS_VERSION` | Build workflow (resolved from GitHub releases) | Pins SOPS version |
| `AGE_VERSION` | Build workflow (resolved from GitHub releases) | Pins age version |
| `BASE_DIGEST` | Build workflow (from `crane digest`) | Records base image digest for traceability |
| `BASE_VERSION` | Build workflow (resolved x.y.z tag) | Records base image version for traceability |

- **`TARGETARCH`** is automatically set by Buildx for each platform (e.g., `amd64`, `arm64`). Defaults to `amd64` via `${TARGETARCH:-amd64}` for local single-arch builds.
- **`BASE_DIGEST`** and **`BASE_VERSION`** default to empty strings; the build workflow populates them.

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

#### Architecture Mapping Table

| `TARGETARCH` | `sops_arch` | `age_arch` | SOPS Asset Pattern | age Asset Pattern |
|--------------|-------------|------------|-------------------|-------------------|
| `amd64` | `amd64` | `amd64` | `sops-vX.Y.Z.linux.amd64` | `age-vX.Y.Z-linux-amd64.tar.gz` |
| `arm64` | `arm64` | `arm64` | `sops-vX.Y.Z.linux.arm64` | `age-vX.Y.Z-linux-arm64.tar.gz` |
| (other) | — | — | **Fails build** | **Fails build** |

- **Architecture mapping:** Converts `TARGETARCH` (e.g., `amd64`, `arm64`) to the asset naming used by SOPS and age. Both projects use identical naming for these two architectures.
- **SOPS installation:** Downloads the pre-built binary for the detected architecture directly to `/usr/local/bin/sops`, makes it executable.
- **age installation:** Downloads the tar.gz archive, extracts it to `/tmp`, moves both `age` and `age-keygen` binaries to `/usr/local/bin/`, then cleans up temporary files.
- **Version check (verification step):** Runs `sops --version --check-for-updates` and `age --version` to confirm installation succeeded. The `--check-for-updates` flag on SOPS prints a non-fatal notice if a newer version exists; it does **not** fail the build. This step ensures the binaries are functional and reports their versions in build logs.

### OCI Labels (lines 45-49)

```dockerfile
LABEL org.opencontainers.image.base.name="ghcr.io/moghtech/komodo-periphery:2"
LABEL org.opencontainers.image.base.version="${BASE_VERSION}"
LABEL org.opencontainers.image.base.digest="${BASE_DIGEST}"
LABEL org.opencontainers.image.sops.version="${SOPS_VERSION}"
LABEL org.opencontainers.image.age.version="${AGE_VERSION}"
```

- **`base.name`:** Notes the base image reference used (the major channel tag).
- **`base.version`** and **`base.digest`:** Record the exact version and digest of the base image (set at build time from workflow outputs).
- **`sops.version`** and **`age.version`:** Record the versions of the installed tools.
- These labels are consumed by the build workflow for change detection (comparing current published labels vs. newly resolved versions).

## Build Argument Flow

The build arguments are supplied by the GitHub Actions workflow. See [Build System](../architecture/build-system.md) for how the workflow:

1. Resolves the base image digest and version tag
2. Fetches latest SOPS and age releases from GitHub
3. Passes all values as `--build-arg` to `docker/build-push-action`
4. Bakes them into OCI labels via the Dockerfile `LABEL` instructions

## Multi-Architecture Support

The Dockerfile is designed for multi-arch builds (`linux/amd64`, `linux/arm64`). The `TARGETARCH` build arg is automatically provided by Buildx for each platform. The case statement maps Docker's architecture identifiers to the asset naming conventions used by the upstream projects.

## Related Pages

- [Build System](../architecture/build-system.md) — How build args are supplied and versions selected
- [Architecture Overview](../architecture/overview.md) — High-level component diagram
- [Image Metadata & Tags](../reference/image-metadata.md) — Tagging strategy and OCI labels
