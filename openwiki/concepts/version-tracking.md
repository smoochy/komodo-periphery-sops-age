---
type: Concept
title: Version Tracking & Change Detection
description: Document the version tracking and change detection logic that determines when builds run. Covers base image digest comparison, SOPS/age release comparison, and the decision logic for forced vs. skipped builds.
tags: [version-tracking, change-detection, ci-cd, build, sops, age]
verified:
  - by: openwiki/0.6.1
    at: 2026-10-02T10:58:29.290Z
sources:
  - id: openwiki-source-7a80b79a6fb3618cbfab08a2
    resource: repo://.github/workflows/build.yml
generated: { by: "openwiki/0.6.1", at: "2026-10-02T10:58:29.290Z" }
---

# Version Tracking & Change Detection

This page documents the version tracking and change detection logic that determines when builds run for the `komodo-periphery-sops-age` image. The logic compares currently published versions against newly resolved versions and decides whether a rebuild is necessary.

## Change Detection Rules

A rebuild is triggered when any of the following conditions are met:

| Check | Condition | Action |
|-------|-----------|--------|
| **Base image digest** | `CURRENT_BASE_DIGEST != BASE_DIGEST` | Rebuild |
| **SOPS version** | `CURRENT_SOPS_VERSION != SOPS_VERSION` | Rebuild |
| **age version** | `CURRENT_AGE_VERSION != AGE_VERSION` | Rebuild |

> **Note:** If `CURRENT_BASE_DIGEST` is empty (no prior published image), the comparison also triggers a rebuild.

## Current vs. Selected Version Comparison

The workflow maintains a persistent comparison between what was previously published and what is being selected in the current run:

### Base Image
- **Resolved:** `BASE_DIGEST` = `crane digest ghcr.io/moghtech/komodo-periphery:2`, `BASE_VERSION` = resolved `x.y.z` tag matching the digest
- **Current:** Read from OCI labels of the previously published image at `ghcr.io/smoochy/komodo-periphery-sops-age:<major>`
- **Comparison:** `CURRENT_BASE_DIGEST` vs `BASE_DIGEST`

### SOPS
- **Selected:** Latest release tag from `getsops/sops`, stripped of `v` prefix (e.g., `3.8.1`)
- **Current:** Read from OCI label `org.opencontainers.image.sops.version` of the previously published image
- **Comparison:** `CURRENT_SOPS_VERSION` vs `SOPS_VERSION`

### age
- **Selected:** Latest release tag from `FiloSottile/age`, stripped of `v` prefix (e.g., `1.2.0`)
- **Current:** Read from OCI label `org.opencontainers.image.age.version` of the previously published image
- **Comparison:** `CURRENT_AGE_VERSION` vs `AGE_VERSION`

## Forced vs. Skipped Build Decision

The final build decision combines upstream change detection with event-specific forced-build conditions:

### Change-Driven Rebuild
If any of the three change detection rules above evaluate to true, the build proceeds regardless of the triggering event.

### Forced Build Conditions
A build is forced regardless of upstream changes under these conditions:

| Event | Condition |
|-------|-----------|
| `workflow_dispatch` | `inputs.force == "true"` |
| `pull_request` | `image_inputs_changed == true` OR `workflow_changed == true` |
| `push` | `image_inputs_changed == true` |

> **Note on `push`:** A workflow-only change (`workflow_changed == true` but `image_inputs_changed == false`) does **not** force a build unless upstream (base/SOPS/age) changes are also detected. This prevents unnecessary rebuilds when only CI configuration changes.

### Final Decision Logic
```bash
if [ "$FORCED" = "true" ] || [ "$CHANGED" = "true" ]; then
  echo "do_build=true"
else
  echo "do_build=false"
  reasons+=("No upstream changes detected (base/SOPS/age unchanged)")
fi
```

## Change Detection Implementation (build.yml lines 131-155)

The `decide` step performs the following comparisons:

1. **Base image digest check:**
   ```bash
   if [ -z "$CURRENT_BASE_DIGEST" ] || [ "$CURRENT_BASE_DIGEST" != "$BASE_DIGEST" ]; then
     CHANGED=true
     reasons+=("komodo-periphery base changed: ${CURRENT_BASE_DIGEST:-(none)} -> ${BASE_DIGEST}")
   fi
   ```

2. **SOPS version check:**
   ```bash
   if [ "$CURRENT_SOPS_VERSION" != "$SOPS_VERSION" ]; then
     CHANGED=true
<!-- openwiki: broken internal link [${SOPS_RELEASE_URL}] file "${SOPS_RELEASE_URL}" does not exist. Fix the href or restore the target, then delete this comment. -->
     reasons+=("SOPS updated: ${CURRENT_SOPS_VERSION:-(none)} -> ${SOPS_VERSION} ([release notes](${SOPS_RELEASE_URL}))")
   fi
   ```

3. **age version check:**
   ```bash
   if [ "$CURRENT_AGE_VERSION" != "$AGE_VERSION" ]; then
     CHANGED=true
<!-- openwiki: broken internal link [${AGE_RELEASE_URL}] file "${AGE_RELEASE_URL}" does not exist. Fix the href or restore the target, then delete this comment. -->
     reasons+=("age updated: ${CURRENT_AGE_VERSION:-(none)} -> ${AGE_VERSION} ([release notes](${AGE_RELEASE_URL}))")
   fi
   ```

## Simulation Commands

The build system provides a local simulation script that exercises the change detection logic:

```bash
# Set GH_TOKEN with packages:read scope
BASE="ghcr.io/moghtech/komodo-periphery:2"
GH_API="https://api.github.com"
AUTH_HEADER="Authorization: Bearer ${GH_TOKEN}"

# 1. Resolve base digest
BASE_DIGEST=$(crane digest "$BASE")

# 2. Resolve periphery tag from OCI labels
BASE_CFG=$(crane config "$BASE")
PERIPHERY_TAG_RAW=$(echo "$BASE_CFG" | jq -r '.config.Labels["org.opencontainers.image.version"] // .config.Labels["org.label-schema.version"] // ""')
PERIPHERY_TAG="${PERIPHERY_TAG_RAW#v}"

# 3. Fetch upstream versions
SOPS_TAG=$(curl -fsSL -H "$AUTH_HEADER" -H "Accept: application/vnd.github+json" \
  "${GH_API}/repos/getsops/sops/releases/latest" | jq -r '.tag_name')
AGE_TAG=$(curl -fsSL -H "$AUTH_HEADER" -H "Accept: application/vnd.github+json" \
  "${GH_API}/repos/FiloSottile/age/releases/latest" | jq -r '.tag_name')
SOPS_VERSION=${SOPS_TAG#v}
AGE_VERSION=${AGE_TAG#v}

# 4. Check current published image
IMAGE="ghcr.io/smoochy/komodo-periphery-sops-age"
PERIPHERY_MAJOR_TAG=$(echo "$PERIPHERY_TAG" | cut -d. -f1)
CURRENT_IMAGE="${IMAGE}:${PERIPHERY_MAJOR_TAG}"

if crane manifest "$CURRENT_IMAGE" >/dev/null 2>&1; then
  cfg=$(crane config "$CURRENT_IMAGE")
  CURRENT_BASE_DIGEST=$(echo "$cfg" | jq -r '.config.Labels["org.opencontainers.image.base.digest"] // ""')
  CURRENT_SOPS_VERSION=$(echo "$cfg" | jq -r '.config.Labels["org.opencontainers.image.sops.version"] // ""')
  CURRENT_AGE_VERSION=$(echo "$cfg" | jq -r '.config.Labels["org.opencontainers.image.age.version"] // ""')
fi
```

## Relationships

<!-- openwiki: broken internal link [architecture/build-system.md] file "architecture/build-system.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Depends on** → [Build System](architecture/build-system.md) for the full workflow implementation
<!-- openwiki: broken internal link [architecture/overview.md] file "architecture/overview.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Informed by** → [Architecture Overview](architecture/overview.md) for component design context
<!-- openwiki: broken internal link [concepts/multi-arch.md] file "concepts/multi-arch.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Enables** → [Multi-Architecture Building](concepts/multi-arch.md) by ensuring versions are tracked across platforms
- **Implemented by** → `.github/workflows/build.yml` for the actual change detection and build decision logic

## Claims

- **Claim: change-detection-base-digest**  
  Statement: A rebuild is triggered when the current base image digest (CURRENT_BASE_DIGEST) differs from the newly resolved base image digest (BASE_DIGEST), or when CURRENT_BASE_DIGEST is empty (no prior published image exists).  
  Evidence: `repo://.github/workflows/build.yml#L138`, `repo://.github/workflows/build.yml#L126`

- **Claim: change-detection-sops-version**  
  Statement: A rebuild is triggered when the current SOPS version (CURRENT_SOPS_VERSION) differs from the newly resolved SOPS version (SOPS_VERSION).  
  Evidence: `repo://.github/workflows/build.yml#L144`, `repo://.github/workflows/build.yml#L116`

- **Claim: change-detection-age-version**  
  Statement: A rebuild is triggered when the current age version (CURRENT_AGE_VERSION) differs from the newly resolved age version (AGE_VERSION).  
  Evidence: `repo://.github/workflows/build.yml#L151`, `repo://.github/workflows/build.yml#L112`

- **Claim: forced-build-decision**  
  Statement: The final build decision follows: if FORCED is "true" OR CHANGED is "true", then do_build="true"; otherwise do_build="false" with a reason noting no upstream changes detected.  
  Evidence: `repo://.github/workflows/build.yml#L173-178`

- **Claim: forced-build-conditions**  
  Statement: The FORCED variable is set to "true" for workflow_dispatch with inputs.force="true", for pull_request when image_inputs_changed or workflow_changed is true, and for push when image_inputs_changed is true.  
  Evidence: `repo://.github/workflows/build.yml#L162-166`

- **Claim: change-detection-push-no-force**  
  Statement: On push events, a workflow-only change (workflow_changed == true but image_inputs_changed == false) does not force a build unless upstream changes (base/SOPS/age) are also detected.  
  Evidence: `repo://.github/workflows/build.yml#L168`

- **Claim: version-comparison-base**  
  Statement: The current base version (CURRENT_BASE_VERSION) is read from OCI labels org.opencontainers.image.base.version or org.opencontainers.image.base.tag of the previously published image, and compared against the freshly resolved BASE_VERSION from the base image's major channel digest.  
  Evidence: `repo://.github/workflows/build.yml#L127`

- **Claim: version-comparison-sops-age**  
  Statement: The current SOPS and age versions are read from their respective OCI labels (org.opencontainers.image.sops.version and org.opencontainers.image.age.version) of the previously published image.  
  Evidence: `repo://.github/workflows/build.yml#L128-129`
