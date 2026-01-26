# komodo-periphery-sops-age

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)
[![CI](https://github.com/smoochy/komodo-periphery-sops-age/actions/workflows/build.yml/badge.svg)](https://github.com/smoochy/komodo-periphery-sops-age/actions)

> Custom **[Komodo](https://github.com/moghtech/komodo) Periphery** image with **[SOPS](https://github.com/getsops/sops)** and **[age](https://github.com/FiloSottile/age)**, automatically rebuilt when upstream components change.

This repository builds and publishes a Docker image based on
`ghcr.io/moghtech/komodo-periphery:latest`, with **Mozilla SOPS** and **age**
preinstalled.

The CI rebuilds the image **only when necessary** and writes a Job Summary that
explains *why* a build happened (including links to upstream release notes).

---

## Table of Contents

- [komodo-periphery-sops-age](#komodo-periphery-sops-age)
  - [Table of Contents](#table-of-contents)
  - [Background](#background)
  - [What this repository does](#what-this-repository-does)
  - [When builds run](#when-builds-run)
  - [Dockerfile](#dockerfile)
  - [GitHub Actions workflow](#github-actions-workflow)
  - [Job Summary](#job-summary)
  - [Image metadata](#image-metadata)
  - [Image tags](#image-tags)
  - [Usage](#usage)
  - [Security](#security)
  - [Maintainers](#maintainers)
  - [License](#license)

---

## Background

Komodo Periphery does not ship with encryption tooling by default.
For setups that rely on encrypted configuration or secrets, **SOPS** and **age**
are commonly used.

This project provides a Komodo Periphery image that already includes both tools,
and keeps it up to date automatically.

---

## What this repository does

- Builds a custom Docker image:
  - Base: `ghcr.io/moghtech/komodo-periphery:latest`
  - Adds:
    - `sops`
    - `age`
    - `age-keygen`
- Publishes the image to **GitHub Container Registry (GHCR)** with `ghcr.io/smoochy/komodo-periphery-sops-age:latest` or
    `ghcr.io/smoochy/komodo-periphery-sops-age:<komodo-version>` like
    `ghcr.io/smoochy/komodo-periphery-sops-age:latest:1.19.5`. You can find the images
  [at this link](https://github.com/smoochy/komodo-periphery-sops-age/pkgs/container/komodo-periphery-sops-age).
- Tracks upstream updates and rebuilds only when needed.

---

## When builds run

The workflow is triggered in three ways:

1. **Push to `main`**, but *only* when one of these files changes:
   - `Dockerfile*`
   - `.dockerignore`
   - `.github/workflows/build.yml`

   This prevents rebuilds for documentation-only changes (for example `README.md`).

2. **Scheduled run** (cron)
   - Runs a daily check for upstream changes (base digest, SOPS release, age release).
   - Builds only if something changed.

3. **Manual run** (`workflow_dispatch`)
   - Optional `force=true` input to rebuild even if nothing changed.

---

## Dockerfile

The `Dockerfile`:

- Uses `ghcr.io/moghtech/komodo-periphery:latest` as base.
- Installs minimal dependencies (`curl`, `tar`, CA certificates).
- Downloads and installs:
  - SOPS from `getsops/sops` GitHub releases
  - age (and `age-keygen`) from `FiloSottile/age` GitHub releases
- Supports multi-arch builds for:
  - `linux/amd64`
  - `linux/arm64`
- Stores the selected versions as OCI labels (see [Image metadata](#image-metadata)).

The Dockerfile does **not** decide which versions to install. Version selection
is done by the workflow and passed in via build args.

---

## GitHub Actions workflow

`build.yml` does the following:

1. Logs into GHCR and sets up Buildx
2. Fetches upstream versions using **authenticated GitHub API calls**
3. Reads the metadata from the currently published image (if it exists)
4. Compares:
   - komodo-periphery base **digest**
   - SOPS **latest release version**
   - age **latest release version**
5. Builds and pushes only when:
   - a push-triggered run happens (filtered by `paths`), or
   - an upstream change is detected, or
   - a manual run is forced

---

## Job Summary

Every workflow run writes a summary that includes:

- The reason the build ran (push, schedule, manual, forced)
- Which upstream component changed (base, SOPS, age)
- Direct links to upstream release notes (SOPS and age)
- The **selected** versions for this run
- The **current** versions from the already published image

This makes it obvious *why* a new image was published and what changed.

---

## Image metadata

Each published image includes OCI labels used for traceability and change
detection, for example:

- `org.opencontainers.image.base.tag`
- `org.opencontainers.image.base.digest`
- `org.opencontainers.image.sops.version`
- `org.opencontainers.image.age.version`

---

## Image tags

This image is published with:

- `latest`
  - Always points to the newest build.
- `<x.y.z>`
  - Matches the upstream Komodo Periphery version tag that `ghcr.io/moghtech/komodo-periphery:x.y.z` points to.
  - Useful for reproducible deployments pinned to a specific Komodo release.

---

## Usage

Example `docker-compose.yml`:

```yaml
services:
  periphery:
    image: ghcr.io/smoochy/komodo-periphery-sops-age:latest
```

or

```yaml
services:
  periphery:
    image: ghcr.io/smoochy/komodo-periphery-sops-age:1.19.5
```

If the image is private, authenticate once on the host:

```bash
docker login ghcr.io
```

---

## Security

- No secrets are baked into the image.
- GitHub Actions uses the built-in `GITHUB_TOKEN` for:
  - GHCR authentication
  - authenticated GitHub API calls (avoids low unauthenticated rate limits)
- Only release metadata is queried from upstream projects.

---

## Maintainers

- smoochy

---

## License

MIT
