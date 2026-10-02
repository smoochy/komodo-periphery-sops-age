---
type: Quickstart
title: Documentation Quickstart
description: Entry point and task-routing map for the wiki. Routes readers to architecture, concepts, workflows, operations, integrations, and testing pages based on their goal. Provides a 'When to Read What' table for common objectives.
tags: [quickstart, overview, navigation]
verified:
  - by: openwiki/0.6.1
    at: 2026-10-02T10:58:29.290Z
sources:
  - id: openwiki-source-7a80b79a6fb3618cbfab08a2
    resource: repo://.github/workflows/build.yml
  - id: openwiki-source-bb1ebe868e35e9e500714501
    resource: repo://Dockerfile
  - id: openwiki-source-23775c3de52f3ab95a13cb8b
    resource: repo://README.md
generated: { by: "openwiki/0.6.1", at: "2026-10-02T10:58:29.290Z" }
---

# Documentation Quickstart

This knowledge base documents the **komodo-periphery-sops-age** repository, which builds and publishes a custom Docker image based on `ghcr.io/moghtech/komodo-periphery:2` with [SOPS](https://github.com/getsops/sops) and [age](https://github.com/FiloSottile/age) preinstalled.

## When to Read What

| Your Goal | Start Here |
|-----------|------------|
| **Understand the system architecture** | [Architecture Overview](architecture/overview.md) |
| **Learn how builds are triggered and versions selected** | [Build System](architecture/build-system.md) |
| **Inspect Dockerfile line-by-line** | [Dockerfile Reference](architecture/dockerfile.md) |
| **Multi-architecture building (amd64/arm64)** | [Multi-Architecture Building](concepts/multi-arch.md) |
<!-- openwiki: broken internal link [concepts/oci-labeling.md] file "concepts/oci-labeling.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **OCI label scheme and version tracking** | [OCI Labeling Strategy](concepts/oci-labeling.md) |
| **Version tracking and change detection logic** | [Version Tracking & Change Detection](concepts/version-tracking.md) |
| **Docker Hub mirror integration** | [Docker Hub Integration](integrations/docker-hub.md) |
| **GitHub Container Registry publishing** | [GHCR Integration](integrations/ghcr.md) |
<!-- openwiki: broken internal link [operations/overview.md] file "operations/overview.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **Operations & Runbook** | [Operations Overview](operations/overview.md) |
| **Change detection and build skip logic** | [Change Detection Validation](testing/validation.md) |
<!-- openwiki: broken internal link [testing/verification.md] file "testing/verification.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **Verification commands and validation steps** | [Verification & Validation](testing/verification.md) |
<!-- openwiki: broken internal link [workflows/build.md] file "workflows/build.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **Build Workflow reference** | [Build Workflow](workflows/build.md) |
<!-- openwiki: broken internal link [workflows/openwiki-update.md] file "workflows/openwiki-update.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **OpenWiki Update Workflow** | [OpenWiki Update Workflow](workflows/openwiki-update.md) |
| **Pull, run, and verify the image** | [Usage Overview](usage/overview.md) |

## Quick Navigation by Domain

| Domain | Pages | Key Source Files |
|--------|-------|------------------|
| **Architecture & Design** | [Architecture Overview](architecture/overview.md) • [Build System](architecture/build-system.md) • [Dockerfile](architecture/dockerfile.md) | `Dockerfile`, `.github/workflows/build.yml` |
<!-- openwiki: broken internal link [concepts/oci-labeling.md] file "concepts/oci-labeling.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **Concepts** | [Multi-Architecture Building](concepts/multi-arch.md) • [OCI Labeling Strategy](concepts/oci-labeling.md) • [Version Tracking & Change Detection](concepts/version-tracking.md) | — |
| **Integrations** | [Docker Hub Integration](integrations/docker-hub.md) • [GHCR Integration](integrations/ghcr.md) | — |
<!-- openwiki: broken internal link [operations/overview.md] file "operations/overview.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **Operations** | [Operations Overview](operations/overview.md) | `.github/workflows/build.yml`, `Dockerfile` |
<!-- openwiki: broken internal link [testing/verification.md] file "testing/verification.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **Testing** | [Change Detection Validation](testing/validation.md) • [Verification & Validation](testing/verification.md) | — |
<!-- openwiki: broken internal link [workflows/build.md] file "workflows/build.md" does not exist. Fix the href or restore the target, then delete this comment. -->
<!-- openwiki: broken internal link [workflows/openwiki-update.md] file "workflows/openwiki-update.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **Workflows** | [Build Workflow](workflows/build.md) • [OpenWiki Update Workflow](workflows/openwiki-update.md) | `.github/workflows/build.yml`, `.github/workflows/openwiki-update.yaml` |
| **Usage** | [Usage Overview](usage/overview.md) | `README.md` |

## Repository Purpose

This project provides a maintained Docker image variant of Komodo Periphery with **SOPS** and **age** preinstalled, enabling encrypted configuration workflows without maintaining a custom build pipeline.

**Published Registries:**
- **GHCR (canonical):** `ghcr.io/smoochy/komodo-periphery-sops-age`
- **Docker Hub (mirror):** `smoochy84/komodo-periphery-sops-age`

## Key Components

1. **Dockerfile** - Defines the image construction: base image, dependency installation, SOPS/age downloads, OCI labels
2. **Build Workflow** (`.github/workflows/build.yml`) - Orchestrates version selection, upstream change detection, multi-arch build, and multi-registry publish
3. **Wiki Update Workflow** (`.github/workflows/openwiki-update.yaml`) - Scheduled documentation refresh
4. **Docker Hub Sync Workflow** (`.github/workflows/sync_dockerhub_description.yml`) - Keeps Docker Hub description in sync with README

## When Builds Run

The build workflow triggers on:
- **Push to main** - Only when `Dockerfile*`, `.dockerignore`, or `.github/workflows/build.yml` change
- **Schedule** - Daily 03:00 UTC check for upstream changes (base image digest, SOPS release, age release)
- **Manual dispatch** - Optional `force=true` to rebuild regardless of changes

## Image Tagging Strategy

Each build publishes three tags derived from the resolved Komodo Periphery version (`x.y.z`):
- **Major:** `X` (e.g., `2`)
- **Minor:** `X.Y` (e.g., `2.1`)
- **Patch:** `X.Y.Z` (e.g., `2.1.3`)

## Validation Commands

```bash
# Verify image exists and inspect labels
docker pull ghcr.io/smoochy/komodo-periphery-sops-age:2
docker inspect ghcr.io/smoochy/komodo-periphery-sops-age:2 --format '{{json .Config.Labels}}' | jq

# Verify SOPS and age versions inside container
docker run --rm ghcr.io/smoochy/komodo-periphery-sops-age:2 sops --version
docker run --rm ghcr.io/smoochy/komodo-periphery-sops-age:2 age --version
```

## Change Guidance

| Change Type | Start Here | Key Files to Modify |
|-------------|------------|---------------------|
| Update SOPS/age versions | Build workflow version selection | `.github/workflows/build.yml` (lines 192-196) |
| Change base image channel | Build workflow BASE constant | `.github/workflows/build.yml` (line 137) |
| Modify installation logic | Dockerfile RUN steps | `Dockerfile` (lines 23-43) |
| Add new registry | Build workflow registry setup | `.github/workflows/build.yml` (steps: registries, dockerhub_mirror) |
| Adjust build triggers | Workflow `on:` section | `.github/workflows/build.yml` (lines 4-30) |
| Update wiki content | Wiki update workflow | `.github/workflows/openwiki-update.yaml` |

*This documentation is generated and maintained by OpenWiki. Source of truth: repository code and workflows.*
