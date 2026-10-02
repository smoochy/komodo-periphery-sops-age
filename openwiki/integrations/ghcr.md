---
type: "Concept"
title: "GHCR Integration"
description: "Documents GitHub Container Registry publishing and integration for the komodo-periphery-sops-age image, covering registry paths, publishing logic, and mirroring to Docker Hub."
tags: ["ghcr", "container", "registry", "mirror", "crane"]
verified:
  - by: openwiki/0.6.1
    at: 2026-10-02T10:58:29.290Z
sources:
  - id: openwiki-source-7a80b79a6fb3618cbfab08a2
    resource: repo://.github/workflows/build.yml
generated: { by: "openwiki/0.6.1", at: "2026-10-02T10:58:29.290Z" }
---
# GHCR Integration

**GHCR canonical**: `ghcr.io/smoochy/komodo-periphery-sops-age`

This page documents GitHub Container Registry publishing and integration for the **komodo-periphery-sops-age** image. It covers registry paths, publishing logic, and mirroring to Docker Hub.

## Claim

- Statement: The build workflow publishes the komodo-periphery-sops-age image to GHCR at `ghcr.io/smoochy/komodo-periphery-sops-age` with three tags (major, minor, patch) and mirrors all three to Docker Hub when `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets are configured.
- Evidence: 
  - `repo://.github/workflows/build.yml` — The `decide` step sets `do_build=true` when upstream changes are detected, then `docker/build-push-action` pushes to GHCR with tags `major`, `minor`, `patch`. The `dockerhub-mirror` step uses `crane copy` to mirror all three tags from GHCR to Docker Hub when secrets are present.
  - `repo://reference/workflows.md` — Confirms the tagging strategy (major/minor/patch) and that Docker Hub mirroring uses `crane copy` from GHCR.
  - `repo://architecture/build-system.md` — Documents the version selection, change detection, and multi-registry publishing logic including the `crane copy` mirroring command.

## Registry Paths

| Registry | Path | Purpose |
|----------|------|---------|
| **GHCR (canonical)** | `ghcr.io/smoochy/komodo-periphery-sops-age` | Primary registry for published images |
| **Base image** | `ghcr.io/moghtech/komodo-periphery:2` | Upstream Komodo Periphery base image |
| **Docker Hub mirror** | `smoochy84/komodo-periphery-sops-age` | Mirrored repository on Docker Hub |

## Publishing Logic

The build workflow (`.github/workflows/build.yml`) handles multi-registry publishing:

1. **Build and push to GHCR** — On successful builds (non-PR events), the image is pushed to GHCR with three tags:
   - **Major**: `X` (e.g., `2`)
   - **Minor**: `X.Y` (e.g., `2.1`)
   - **Patch**: `X.Y.Z` (e.g., `2.1.3`)

2. **Version selection** — The `decide` step resolves:
   - Base image digest from `ghcr.io/moghtech/komodo-periphery:2`
   - Periphery tag (`x.y.z`) matching the base digest via OCI labels or tag scanning
   - Latest SOPS and age versions from upstream GitHub releases

3. **Build args passed to Dockerfile** — `BASE_DIGEST`, `BASE_VERSION`, `SOPS_VERSION`, `AGE_VERSION` are baked as OCI labels

4. **Change detection** — Build is triggered when:
   - Base image digest changes
   - SOPS version changes
   - age version changes
   - Or forced via `workflow_dispatch` with `force=true`, PR with image inputs changed, or push with image input changes

## Mirror to Docker Hub

When `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets are configured, the build workflow mirrors all three tags from GHCR to Docker Hub using `crane copy`:

```bash
for tag in "${PERIPHERY_MAJOR_TAG}" "${PERIPHERY_MINOR_TAG}" "${PERIPHERY_TAG}"; do
  crane copy "${src_base}:${tag}" "${dst_base}:${tag}"
done
```

- **Source**: `ghcr.io/smoochy/komodo-periphery-sops-age:${tag}`
- **Destination**: `smoochy84/komodo-periphery-sops-age:${tag}` (or overridden via `DOCKERHUB_REPOSITORY`)
- **Conditional**: Only runs when `do_build == 'true'`, not a pull request, and both Docker Hub secrets are set

## Relationship to Other Workflows

| Workflow | Relationship |
|----------|-------------|
| `.github/workflows/build.yml` | Builds and pushes images to GHCR and mirrors to Docker Hub |
| `.github/workflows/sync_dockerhub_description.yml` | Syncs `README.dockerhub.md` to Docker Hub repository description (independent of image builds) |
| `.github/workflows/openwiki-update.yaml` | Automated documentation refresh via OpenWiki (unrelated to image publishing) |

## Operational Notes

- The Docker Hub mirror is **independent of description sync** — mirroring updates image tags; description sync updates only the repository short description
- Three tags (major, minor, patch) are always mirrored together when the build completes
- Without `DOCKERHUB_USERNAME` + `DOCKERHUB_TOKEN`, the mirror step is gracefully skipped and the workflow summary notes the missing secrets
- The canonical GHCR repository is `ghcr.io/smoochy/komodo-periphery-sops-age`
