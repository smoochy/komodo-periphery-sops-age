---
type: "Concept"
title: "Docker Hub Integration"
description: "Documents the Docker Hub mirror integration and repository description synchronization workflow for the komodo-periphery-sops-age image, covering registry paths, sync triggers, and keeping the Docker Hub description in sync with README.dockerhub.md."
tags: ["docker", "hub", "container", "mirror", "synchronization"]
verified:
  - by: openwiki/0.6.1
    at: 2026-10-02T10:58:29.290Z
sources:
  - id: openwiki-source-ef9220e7890ed77ce753b739
    resource: repo://.github/workflows/sync_dockerhub_description.yml
generated: { by: "openwiki/0.6.1", at: "2026-10-02T10:58:29.290Z" }
---
# Docker Hub Integration

**Docker Hub mirror**: `smoochy84/komodo-periphery-sops-age`

## Claim

- Statement: `README.dockerhub.md` is the source of truth for the Docker Hub repository description, and the sync workflow (`sync_dockerhub_description.yml`) uses this file to update the Docker Hub repository description.
- Evidence: 
  - `repo://.github/workflows/sync_dockerhub_description.yml` — The workflow uses `readme-filepath: ./README.dockerhub.md` and `short-description: "Komodo Periphery image with SOPS and age, rebuilt on upstream changes"` to update the Docker Hub description.
  - `repo://reference/workflows.md` — The workflows reference page confirms `README.dockerhub.md source of truth` and lists `README.dockerhub.md` as a trigger path for the sync workflow.

## Overview

This page documents the Docker Hub mirror integration and repository description synchronization for the **komodo-periphery-sops-age** image. The Docker Hub description is kept in sync with `README.dockerhub.md`, which serves as the source of truth for the Docker Hub repository description.

## Sync Workflow

The description synchronization is handled by the GitHub Actions workflow `.github/workflows/sync_dockerhub_description.yml`.

### Triggers

- **`push` to `main`**: When `README.md`, `README.dockerhub.md`, or the workflow file itself changes on the `main` branch, the description is automatically synced to Docker Hub.
- **`workflow_dispatch`**: Manual dispatch allows triggering a sync on demand.

### How It Works

1. The workflow checks for `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets.
2. If secrets are present, it uses the `peter-evans/dockerhub-description@v5` action to update the Docker Hub repository description.
3. The `short-description` field is set to: `"Komodo Periphery image with SOPS and age, rebuilt on upstream changes"`.
4. The `readme-filepath` is set to `./README.dockerhub.md`, meaning only the Docker Hub-specific README is used as the source.
5. `enable-url-completion` is enabled for improved Docker Hub URL handling.

### Required Secrets

| Secret | Purpose |
|--------|---------|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (not password) |

### Optional Variable

| Variable | Purpose | Default |
|----------|---------|---------|
| `DOCKERHUB_REPOSITORY` | Override repository (e.g., `org/repo`) | `${DOCKERHUB_USERNAME}/${REPOSITORY_NAME}` |

### Behavior When Secrets Missing

- The description update step is skipped.
- The workflow summary notes: "Set `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` repository secrets to enable it".
- The description remains unchanged.

## Registry Paths

- **Docker Hub mirror**: `smoochy84/komodo-periphery-sops-age`
- The image is also published to GitHub Container Registry (GHCR) at `ghcr.io/moghtech/komodo-periphery`.
- The build workflow (`.github/workflows/build.yml`) mirrors three tags (major, minor, patch) from GHCR to Docker Hub when Docker Hub credentials are configured.

## Relationship to Other Workflows

| Workflow | Relationship |
|----------|-------------|
| `.github/workflows/build.yml` | Builds and pushes images to GHCR and optionally mirrors to Docker Hub. Description sync is separate from image builds. |
| `.github/workflows/openwiki-update.yaml` | Automated documentation refresh via OpenWiki; unrelated to Docker Hub description. |
| `.github/workflows/sync_dockerhub_description.yml` | **This workflow** — syncs `README.dockerhub.md` to Docker Hub repository description. |

## README.dockerhub.md — Source of Truth

The `README.dockerhub.md` file (located at the repository root) is the source of truth for the Docker Hub repository description. It should contain Docker Hub-appropriate formatting and information. The sync workflow reads this file and uses its contents to update the Docker Hub repository description.

The `README.dockerhub.md` should not be confused with the main `README.md`; the sync workflow specifically targets `README.dockerhub.md` for Docker Hub-specific formatting.

## Operational Notes

- The description sync is **independent of image builds** — it only updates the description, not image tags or labels.
- Changes to `README.md` do not trigger the description sync; only changes to `README.dockerhub.md` (or the workflow file itself) on `main` will trigger a sync.
- The sync only runs when Docker Hub secrets are configured; without them, the step is gracefully skipped.
