---
type: Reference
title: komodo-periphery-sops-age Documentation
description: Entry point and task-routing map for the wiki. Routes readers to architecture, build system, image metadata, usage, operations, and workflows reference based on their goal.
tags: [quickstart, overview, navigation]
verified:
  - by: openwiki/0.5.2
    at: 2026-09-18T09:31:26.072Z
sources:
  - id: openwiki-source-7a80b79a6fb3618cbfab08a2
    resource: repo://.github/workflows/build.yml
  - id: openwiki-source-bb1ebe868e35e9e500714501
    resource: repo://Dockerfile
  - id: openwiki-source-23775c3de52f3ab95a13cb8b
    resource: repo://README.md
generated: { by: "openwiki/0.5.2", at: "2026-09-18T09:31:26.072Z" }
---

# komodo-periphery-sops-age Documentation

This knowledge base documents the **komodo-periphery-sops-age** repository, which builds and publishes a custom Docker image based on `ghcr.io/moghtech/komodo-periphery:2` with [SOPS](https://github.com/getsops/sops) and [age](https://github.com/FiloSottile/age) preinstalled.

## When to Read What

| Your Goal | Start Here |
|-----------|------------|
| **Understand the system architecture** | [Architecture Overview](architecture/overview.md) |
| **Learn how builds are triggered and versions selected** | [Build System](architecture/build-system.md) |
| **Inspect Dockerfile line-by-line** | [Dockerfile Reference](architecture/dockerfile.md) |
| **Find tag formats, OCI labels, version tracking** | [Image Metadata & Tags](reference/image-metadata.md) |
| **Read about all GitHub Actions workflows** | [Workflows Reference](reference/workflows.md) |
| **Pull, run, and verify the image** | [Usage Overview](usage/overview.md) |
<!-- openwiki: broken internal link [operations/overview.md] file "operations/overview.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **Trigger manual builds, troubleshoot, rotate secrets** | [Operations & Runbook](operations/overview.md) |

## Quick Navigation by Domain

| Domain | Pages | Key Source Files |
|--------|-------|------------------|
| **Architecture & Design** | [Architecture Overview](architecture/overview.md) • [Build System](architecture/build-system.md) • [Dockerfile](architecture/dockerfile.md) | `Dockerfile`, `.github/workflows/build.yml` |
| **Reference** | [Image Metadata & Tags](reference/image-metadata.md) • [Workflows Reference](reference/workflows.md) | `Dockerfile` (LABELs), `.github/workflows/build.yml`, `.github/workflows/openwiki-update.yaml`, `.github/workflows/sync_dockerhub_description.yml` |
| **Usage** | [Usage Overview](usage/overview.md) | `README.md` |
<!-- openwiki: broken internal link [operations/overview.md] file "operations/overview.md" does not exist. Fix the href or restore the target, then delete this comment. -->
| **Operations** | [Operations & Runbook](operations/overview.md) | `.github/workflows/build.yml`, `Dockerfile` |

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

---

*This documentation is generated and maintained by OpenWiki. Source of truth: repository code and workflows.*
