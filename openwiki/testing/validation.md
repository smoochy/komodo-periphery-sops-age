---
type: Concept
title: Change Detection Validation
description: Document the change detection and build skip logic validation. Helps coding agents understand when builds are skipped and the invariants that govern forced vs. natural builds.
tags: [change-detection, build-validation, ci-cd, version-tracking]
verified:
  - by: openwiki/0.6.1
    at: 2026-10-02T10:58:29.290Z
sources:
  - id: openwiki-source-7a80b79a6fb3618cbfab08a2
    resource: repo://.github/workflows/build.yml
generated: { by: "openwiki/0.6.1", at: "2026-10-02T10:58:29.290Z" }
---

# Change Detection Validation

This page documents the change detection and build skip logic validation. It explains when builds are skipped and the invariants that govern forced versus natural builds.

## Core Principles

Change detection compares published labels versus selected versions to determine whether a rebuild is necessary. The system follows these invariants:

- **Manual dispatch with `force=true`** bypasses all change detection and forces a build.
- **Path filtering** ensures that documentation-only changes (e.g., `README.md`) do not trigger builds.
- **`do_build=true`** if and only if the build was forced OR upstream changes were detected.

## Change Detection Logic

The workflow evaluates three independent change detection rules. A rebuild is triggered when **any** of these rules evaluate to true:

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

## Claims

- **Claim: change-detection-1**
  Statement: Change detection compares published OCI labels against newly resolved versions to determine if a rebuild is necessary
  Evidence: `repo://.github/workflows/build.yml#L138-L144`

- **Claim: change-detection-2**
  Statement: Manual dispatch with force=true bypasses all change detection and forces a build regardless of upstream changes
  Evidence: `repo://.github/workflows/build.yml#L58`

- **Claim: change-detection-3**
  Statement: Path filtering ensures that documentation-only changes (e.g., README.md) do not trigger builds
  Evidence: `repo://.github/workflows/build.yml#L52`

- **Claim: change-detection-4**
  Statement: do_build=true if and only if the build was forced OR upstream changes (base/SOPS/age) were detected
  Evidence: `repo://.github/workflows/build.yml#L92`
```

## Change Detection Implementation

The `decide` step in the build workflow performs the following comparisons:

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
<!-- openwiki: broken internal link [${RELEASE_URL}] file "${RELEASE_URL}" does not exist. Fix the href or restore the target, then delete this comment. -->
     reasons+=("age updated: ${CURRENT_AGE_VERSION:-(none)} -> ${AGE_VERSION} ([release notes](${RELEASE_URL}))")
   fi
   ```

## Path Filtering

The workflow uses `paths` filtering to prevent documentation-only changes from triggering builds. The `paths` filter ensures only changes to the Dockerfile, `.dockerignore`, or the workflow itself cause a build. This applies to both `push` and `pull_request` triggers.

## Summary of Build Triggers

| Trigger Type | Condition for `do_build=true` |
|--------------|-------------------------------|
| `push` to `main` | `image_inputs_changed == true` OR upstream (base/SOPS/age) changed |
| `pull_request` to `main` | `image_inputs_changed == true` OR `workflow_changed == true` OR upstream changed |
| `schedule` (daily) | Upstream (base/SOPS/age) changed |
| `workflow_dispatch` | `force == "true"` OR upstream changed |
