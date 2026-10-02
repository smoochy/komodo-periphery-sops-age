---
type: Concept
title: Multi-Architecture Building
description: Document the multi-architecture build strategy supporting linux/amd64 and linux/arm64 platforms. Covers architecture mapping, QEMU emulation, and single manifest list publishing.
tags: [architecture, multi-arch, docker, buildx, qemu]
verified:
  - by: openwiki/0.6.1
    at: 2026-10-02T10:58:29.290Z
sources:
  - id: openwiki-source-7a80b79a6fb3618cbfab08a2
    resource: repo://.github/workflows/build.yml
  - id: openwiki-source-bb1ebe868e35e9e500714501
    resource: repo://Dockerfile
generated: { by: "openwiki/0.6.1", at: "2026-10-02T10:58:29.290Z" }
---
# Multi-Architecture Building

This page documents the multi-architecture build strategy for the **komodo-periphery-sops-age** Docker image, supporting `linux/amd64` and `linux/arm64` platforms.

## Architecture Mapping

The build maps target architectures to the appropriate binary architectures for SOPS and age:

| Target Arch | SOPS arch | age arch |
|-------------|-----------|----------|
| `amd64` | `amd64` | `amd64` |
| `arm64` | `arm64` | `arm64` |

**Claim: Architecture mapping is deterministic per target platform**
- Statement: For target `linux/amd64`, SOPS and age binaries are downloaded as `amd64` variants; for `linux/arm64`, they are downloaded as `arm64` variants. The mapping is `amd64→sops/age amd64, arm64→sops/age arm64`.
- Evidence: 
  - `repo://Dockerfile#L46-L50` — the `case` statement sets `sops_arch` and `age_arch` based on `TARGETARCH`
  - `repo://.github/workflows/build.yml#L343` — platforms declaration `linux/amd64,linux/arm64`

## Buildx and QEMU

[docker/build-push-action](https://github.com/docker/build-push-action) with Buildx handles cross-compilation via QEMU emulation. The workflow declares:

```
Platforms: linux/amd64,linux/arm64
```

**Claim: Buildx uses QEMU for cross-compilation**
- Statement: `docker/build-push-action` with Buildx handles cross-compilation between `linux/amd64` and `linux/arm64` using QEMU emulation. No separate emulation layer is required in the Dockerfile.
- Evidence: 
  - `repo://.github/workflows/build.yml#L208` — `Platforms: linux/amd64,linux/arm64` passed to build-push-action
  - `repo://.github/workflows/build.yml#L343` — platforms listed in the workflow configuration

## Dockerfile Architecture Handling

The Dockerfile receives `TARGETARCH` as a build argument and uses a `case` statement to set the appropriate architecture variables for binary downloads:

```dockerfile
ARG TARGETARCH
...
RUN set -eux; \
    arch="${TARGETARCH:-amd64}"; \
    case "$arch" in \
    amd64) sops_arch="amd64"; age_arch="amd64" ;; \
    arm64) sops_arch="arm64"; age_arch="arm64" ;; \
    *) echo "Unsupported TARGETARCH: $arch"; exit 1 ;; \
    esac; \
```

**Claim: Dockerfile architecture case statement correctly maps TARGETARCH**
- Statement: The Dockerfile `case` statement on `TARGETARCH` sets `sops_arch` and `age_arch` to match the target, producing `linux/amd64` binaries for `amd64` target and `linux/arm64` binaries for `arm64` target.
- Evidence: 
  - `repo://Dockerfile#L46-L50` — exact `case` statement with `amd64`/`arm64` branches

## Platforms Supported

- `linux/amd64` - x86_64 architecture
- `linux/arm64` - AArch64 / ARM64 architecture

**Claim: Supported platforms are exactly linux/amd64 and linux/arm64**
- Statement: The multi-architecture build explicitly supports exactly two platforms: `linux/amd64` and `linux/arm64`. No other platforms are configured or tested.
- Evidence: 
  - `repo://.github/workflows/build.yml#L208` — `Platforms: linux/amd64,linux/arm64`
  - `repo://Dockerfile#L46-L49` — case statement only handles `amd64` and `arm64`, exits on unsupported

## Single Manifest List

Per tag, a single OCI manifest list is published that references the appropriate platform-specific manifests. This allows consumers to pull the image using the tag and receive the correct platform variant based on their runtime architecture.

**Claim: Single manifest list published per tag**
- Statement: For each tag (major, minor, patch), a single OCI manifest list is published to the container registry. The manifest list contains references to the platform-specific image manifests (`linux/amd64` and `linux/arm64`). Consumers pulling by tag receive the correct variant for their architecture.
- Evidence: 
  - `repo://.github/workflows/build.yml#L210` — `Tags` from `metadata-action` applied to the manifest list output
  - `repo://.github/workflows/build.yml#L208` — `Platforms: linux/amd64,linux/arm64` causes build-push-action to generate a multi-arch manifest list

## Relationships

<!-- openwiki: broken internal link [architecture/overview.md] file "architecture/overview.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Depends on** → [Architecture Overview](architecture/overview.md) for high-level design context
<!-- openwiki: broken internal link [architecture/dockerfile.md] file "architecture/dockerfile.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Implemented by** → [Dockerfile Reference](architecture/dockerfile.md) for line-by-line binary download logic
<!-- openwiki: broken internal link [architecture/build-system.md] file "architecture/build-system.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Configured by** → [Build System](architecture/build-system.md) for workflow-level platform configuration and publishing
