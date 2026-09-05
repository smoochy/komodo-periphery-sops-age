---
type: Reference
title: komodo-periphery-sops-age Documentation
description: Entry point for the komodo-periphery-sops-age OpenWiki knowledge base. Covers repository purpose, key components, and navigation to detailed documentation.
tags: [quickstart, overview, navigation]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-04T09:25:18.613Z
sources:
  - id: openwiki-source-7a80b79a6fb3618cbfab08a2
    resource: repo://.github/workflows/build.yml
  - id: openwiki-source-bb1ebe868e35e9e500714501
    resource: repo://Dockerfile
  - id: openwiki-source-23775c3de52f3ab95a13cb8b
    resource: repo://README.md
generated: { by: "openwiki/0.5.0", at: "2026-09-04T09:25:18.613Z" }
---

# komodo-periphery-sops-age Documentation

This knowledge base documents the **komodo-periphery-sops-age** repository, which builds and publishes a custom Docker image based on `ghcr.io/moghtech/komodo-periphery:2` with [SOPS](https://github.com/getsops/sops) and [age](https://github.com/FiloSottile/age) preinstalled.

## Quick Navigation

| Area | Page | Key Source Files |
|------|------|------------------|
| **Architecture & Design** | [Architecture Overview](architecture/overview.md) | `Dockerfile`, `.github/workflows/build.yml` |
| **Build System** | [Build System](architecture/build-system.md) | `.github/workflows/build.yml` |
| **Dockerfile Details** | [Dockerfile](architecture/dockerfile.md) | `Dockerfile` |
| **Image Tags & Metadata** | [Image Metadata](reference/image-metadata.md) | `Dockerfile` (LABELs), `.github/workflows/build.yml` |
| **Usage & Examples** | [Usage](usage/overview.md) | `README.md` |

## Repository Purpose

This project provides a maintained Docker image variant of Komodo Periphery with **SOPS** and **age** preinstalled, enabling encrypted configuration workflows without maintaining a custom build pipeline.

**Published Registries:**
- **GHCR (canonical):** `ghcr.io/smoochy/komodo-periphery-sops-age`
- **Docker Hub (mirror):** `smoochy84/komodo-periphery-sops-age`

## Key Components

1. **Dockerfile** - Defines the image construction: base image, dependency installation, SOPS/age downloads, OCI labels
2. **Build Workflow** (`.github/workflows/build.yml`) - Orchestrates version selection, upstream change detection, multi-arch build, and multi-registry publish
3. **Wiki Update Workflow** (`.github/workflows/openwiki-update.yaml`) - Scheduled documentation refresh

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

---

*This documentation is generated and maintained by OpenWiki. Source of truth: repository code and workflows.*
