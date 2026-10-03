---
type: "Reference"
title: "Workflows Reference"
openwiki_generated: true
verified:
  - by: openwiki/0.5.2
    at: 2026-09-18T09:31:26.072Z
sources:
  - id: openwiki-source-7a80b79a6fb3618cbfab08a2
    resource: repo://.github/workflows/build.yml
  - id: openwiki-source-e082dc1d961398caa2e27f47
    resource: repo://.github/workflows/openwiki-update.yaml
  - id: openwiki-source-ef9220e7890ed77ce753b739
    resource: repo://.github/workflows/sync_dockerhub_description.yml
generated: { by: "openwiki/0.6.1", at: "2026-10-02T10:58:29.290Z" }
---


# Workflows Reference

This page documents the three GitHub Actions workflows in this repository, their triggers, permissions, jobs, and key operational behaviors.

## Cross-Workflow Summary

| Workflow | File | Primary Purpose | Triggers | Key Outputs |
|----------|------|-----------------|----------|-------------|
| **Build** | `.github/workflows/build.yml` | Build, version selection, upstream change detection, multi-registry publish | Push to main (Dockerfile/paths), PR to main (same paths), Daily 03:00 UTC schedule, Manual dispatch | Multi-arch Docker image (linux/amd64, linux/arm64) to GHCR + Docker Hub mirror |
| **OpenWiki Update** | `.github/workflows/openwiki-update.yaml` | Automated documentation refresh via OpenWiki | Weekly schedule (Friday 05:00 UTC, even ISO weeks only), Manual dispatch | PR with updated OpenWiki pages |
| **Docker Hub Description Sync** | `.github/workflows/sync_dockerhub_description.yml` | Sync README.dockerhub.md to Docker Hub repository description | Push to main (README.md, README.dockerhub.md, workflow file), Manual dispatch | Updated Docker Hub repository description |

---

## Build Workflow (`.github/workflows/build.yml`)

**Workflow name:** `Create komodo-periphery image including Mozilla SOPS and age`

### Permissions

```yaml
permissions:
  contents: read
  packages: write
```

- `contents: read` — checkout repository
- `packages: write` — push to GHCR (GitHub Container Registry)

### Triggers

| Trigger | Condition | Behavior |
|---------|-----------|----------|
| `push` to `main` | Paths: `Dockerfile*`, `.dockerignore`, `.github/workflows/build.yml` | Full build and publish |
| `pull_request` to `main` | Same paths as push | Validation build only (no push) |
| `schedule` | Daily 03:00 UTC (`00 3 * * *`) | Upstream change check |
| `workflow_dispatch` | Optional `force=true` input | Manual rebuild (force bypasses change detection) |

**Key design:** Documentation-only changes (e.g., `README.md`) do **not** trigger builds due to path filtering.

### Jobs

#### `build` (single job, runs on `ubuntu-latest`)

**Step Sequence:**

1. **Checkout** — `actions/checkout@v7` with `fetch-depth: 0` for full history
2. **Classify Local Changes** — Determines if image-relevant files changed (`image_inputs_changed`, `workflow_changed` outputs)
3. **Setup QEMU** — `docker/setup-qemu-action@v4` for multi-arch emulation
4. **Setup Buildx** — `docker/setup-buildx-action@v4` for BuildKit
4. **Login to GHCR** — `docker/login-action@v4` (skipped for external PR forks)
5. **Setup crane** — `imjasonh/setup-crane@v0.7` for registry API operations
6. **Determine Optional Registry Targets** — Computes GHCR image name; detects Docker Hub credentials (`dockerhub_enabled`, `dockerhub_image` outputs)
7. **Decide Whether to Build** — Core logic: resolves base image digest, periphery tag, SOPS/age versions; compares against published image labels; determines `do_build` and `reasons_md`
8. **Metadata** (conditional: `do_build == true`) — `docker/metadata-action@v6` generates tags (major, minor, patch) and labels
9. **Build and Push** (conditional) — `docker/build-push-action@v7` multi-arch build with build args and cache; pushes only on non-PR events
10. **Login to Docker Hub** (conditional) — If Docker Hub secrets configured
11. **Mirror Image to Docker Hub** (conditional) — Uses `crane copy` to mirror three tags from GHCR to Docker Hub
12. **Write Build Summary** (always) — Job summary with publish reason, image refs, mirror status

### Version Selection & Change Detection (Decide Step)

The `decide` step performs:

1. **Base Image Resolution** — Fetches digest of `ghcr.io/moghtech/komodo-periphery:2`
2. **Periphery Tag Resolution** — Finds `x.y.z` tag matching base digest via OCI labels or tag scanning fallback
3. **Tool Version Selection** — Queries GitHub API for latest SOPS (`getsops/sops`) and age (`FiloSottile/age`) releases
4. **Current Version Reading** — Reads labels from published image (if exists): base digest, base version, SOPS version, age version
5. **Change Detection** — Compares selected vs. current versions/digests
6. **Forced Build Logic** — `workflow_dispatch` with `force=true`, PR with local changes, push with image input changes
7. **Decision** — `do_build=true` if forced OR upstream changed; generates markdown summary

### Tagging Strategy

Three tags derived from resolved Komodo Periphery version (`x.y.z`):

- **Major:** `X` (e.g., `2`)
- **Minor:** `X.Y` (e.g., `2.1`)
- **Patch:** `X.Y.Z` (e.g., `2.1.3`)

### Multi-Registry Publishing

| Registry | Condition | Method |
|----------|-----------|--------|
| GHCR (canonical) | Always on non-PR builds | `docker/build-push-action` push |
| Docker Hub (mirror) | `DOCKERHUB_USERNAME` + `DOCKERHUB_TOKEN` secrets set | `crane copy` from GHCR |

### Build Args Passed to Dockerfile

```
BASE_DIGEST=<base image digest>
BASE_VERSION=<periphery x.y.z tag>
SOPS_VERSION=<sops version>
AGE_VERSION=<age version>
```

### OCI Labels Applied

- `org.opencontainers.image.version` — periphery tag
- `org.opencontainers.image.base.name` — `ghcr.io/moghtech/komodo-periphery:2`
- `org.opencontainers.image.base.tag` — periphery tag
- `org.opencontainers.image.base.digest` — base image digest
- `org.opencontainers.image.base.version` — periphery tag
- `org.opencontainers.image.sops.version` — SOPS version
- `org.opencontainers.image.age.version` — age version

---

## OpenWiki Update Workflow (`.github/workflows/openwiki-update.yaml`)

**Workflow name:** `OpenWiki Update`

### Permissions

```yaml
permissions:
  contents: write
  pull-requests: write
```

- `contents: write` — push changes to `openwiki/update` branch
- `pull-requests: write` — create PR via `peter-evans/create-pull-request`

### Triggers

| Trigger | Condition | Behavior |
|---------|-----------|----------|
| `schedule` | Friday 05:00 UTC (`0 5 * * 5`) | **Gated** by ISO week parity (runs only on even weeks) |
| `workflow_dispatch` | Manual trigger | Always runs (bypasses parity gate) |

### ISO Week Parity Gate

GitHub cron cannot express "every other week." The workflow runs weekly but a **gate job** checks ISO week parity:

```bash
week=$(( 10#$(date -u +%V) % 2 ))
if [ "$week" -eq 0 ]; then
  echo "run=true"  # even ISO week → proceed
else
  echo "run=false" # odd ISO week → skip
fi
```

- **Even ISO week** (week % 2 == 0) → `update` job runs
- **Odd ISO week** → `update` job skipped with message
- **Manual dispatch** → always runs (`run=true` unconditionally)

### Jobs

#### `gate` (runs on `ubuntu-latest`)
- Outputs `run: "true"` or `"false"` based on parity check

#### `update` (needs: `gate`, runs if `gate.outputs.run == 'true'`)
**Steps:**

1. **Checkout** — `actions/checkout@v7` with `persist-credentials: true`
2. **Setup Node.js** — `actions/setup-node@v7` with Node 24
3. **Install OpenWiki** — `npm install --global openwiki`
4. **Pick Candidate Models** — Fetches `models-openwiki.json` from `smoochy/openrouter-model-list`, extracts all models with `sanity_ok: true` as fallback candidates
5. **Run OpenWiki** — Iterates candidate models; first successful `openwiki code --update --print` wins; tolerates empty responses (free tier load) by retrying next candidate
6. **Create OpenWiki Update PR** — `peter-evans/create-pull-request@v8` targeting `openwiki/update` branch

### OpenWiki Execution Environment

```env
OPENWIKI_TELEMETRY_DISABLED: "1"
OPENWIKI_PROVIDER: openrouter
OPENROUTER_API_KEY: ${{ secrets.OPENROUTER_API_KEY }}
OPENWIKI_PROVIDER_RETRY_ATTEMPTS: "10"     # Handle 429 rate limits
LANGSMITH_ENDPOINT: https://eu.api.smith.langchain.com
LANGSMITH_API_KEY: ${{ secrets.LANGSMITH_API_KEY }}
LANGCHAIN_PROJECT: openwiki
LANGCHAIN_TRACING_V2: "true"
```

### Model Fallback Logic

- Fetches score-sorted models from `openrouter-model-list`
- Keeps **all** `sanity_ok` models as candidates (not just top-1) because `sanity_ok` only proves a smoke call succeeded
- Iterates until one succeeds or all exhausted

---

## Sync Docker Hub Description Workflow (`.github/workflows/sync_dockerhub_description.yml`)

**Workflow name:** `Sync Docker Hub description`

### Permissions

```yaml
permissions:
  contents: read
```

Minimal read-only access; Docker Hub auth via secrets.

### Triggers

| Trigger | Paths | Behavior |
|---------|-------|----------|
| `push` to `main` | `README.md`, `README.dockerhub.md`, `.github/workflows/sync_dockerhub_description.yml` | Sync description |
| `workflow_dispatch` | — | Manual sync |

### Jobs

#### `sync` (runs on `ubuntu-latest`)

**Steps:**

1. **Checkout** — `actions/checkout@v7`
2. **Check Docker Hub Secrets** — Verifies `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets exist; computes repository name (`DOCKERHUB_REPOSITORY` var or `${USERNAME}/${REPO_NAME}`)
3. **Update Docker Hub Description** (conditional: secrets present) — Uses `peter-evans/dockerhub-description@v5`:
   - `username`: `${{ secrets.DOCKERHUB_USERNAME }}`
   - `password`: `${{ secrets.DOCKERHUB_TOKEN }}`
   - `repository`: computed from step 2
   - `short-description`: "Komodo Periphery image with SOPS and age, rebuilt on upstream changes"
   - `readme-filepath`: `./README.dockerhub.md`
   - `enable-url-completion`: `true`
4. **Write Summary** (always) — Job summary indicating success or skip reason

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

- Step 2 outputs `enabled=false`
- Description update step skipped
- Summary notes: "Set `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` repository secrets to enable it"

---

## Operational Notes

### Build Workflow — Daily Schedule vs. Manual Trigger

- **Daily 03:00 UTC**: Checks upstream (base image, SOPS, age). Only builds if something changed.
- **Manual `force=true`**: Bypasses change detection, rebuilds with current upstream versions.

### OpenWiki Update — Why Biweekly?

- Reduces API usage and PR noise
- ISO week parity provides deterministic every-other-week cadence without complex cron
- Manual dispatch available for immediate updates

### Docker Hub Description — Separate from Build

- Syncs `README.dockerhub.md` (not `README.md`) for Docker Hub-specific formatting
- Runs independently of image builds
- Only updates description, not image tags

### Secret Requirements Summary

| Workflow | Required Secrets |
|----------|------------------|
| `build.yml` | `GITHUB_TOKEN` (implicit), `DOCKERHUB_USERNAME` + `DOCKERHUB_TOKEN` (optional, for Docker Hub mirror) |
| `openwiki-update.yaml` | `OPENROUTER_API_KEY`, `LANGSMITH_API_KEY` |
| `sync_dockerhub_description.yml` | `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` |

---

## Related Documentation

<!-- openwiki: broken internal link [/openwiki/architecture/build-system.md] link "/openwiki/architecture/build-system.md" is root-absolute, which no real consumer resolves against the repository root (not a coding agent reading the page, not GitHub's Markdown renderer, not a local viewer); use a path relative to this file instead. Fix the href or restore the target, then delete this comment. -->
- [Build System Architecture](/openwiki/architecture/build-system.md) — Deep dive on build workflow internals
<!-- openwiki: broken internal link [/openwiki/quickstart.md] link "/openwiki/quickstart.md" is root-absolute, which no real consumer resolves against the repository root (not a coding agent reading the page, not GitHub's Markdown renderer, not a local viewer); use a path relative to this file instead. Fix the href or restore the target, then delete this comment. -->
- [Quickstart](/openwiki/quickstart.md) — Repository overview and navigation
<!-- openwiki: broken internal link [/openwiki/reference/image-metadata.md] link "/openwiki/reference/image-metadata.md" is root-absolute, which no real consumer resolves against the repository root (not a coding agent reading the page, not GitHub's Markdown renderer, not a local viewer); use a path relative to this file instead. Fix the href or restore the target, then delete this comment. -->
- [Image Metadata Reference](/openwiki/reference/image-metadata.md) — OCI labels and tag scheme
