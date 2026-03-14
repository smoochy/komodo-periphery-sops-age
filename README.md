# komodo-periphery-sops-age

[![README Style](https://img.shields.io/badge/README%20style-standard-2ea44f)](https://github.com/RichardLitt/standard-readme)
[![CI](https://github.com/smoochy/komodo-periphery-sops-age/actions/workflows/build.yml/badge.svg)](https://github.com/smoochy/komodo-periphery-sops-age/actions)

[![Buy me uptime](https://img.shields.io/badge/Buy%20me%20uptime%20%F0%9F%96%A5%EF%B8%8F-smoochy84-E9C46A?logo=buymeacoffee&logoColor=000000)](https://www.buymeacoffee.com/smoochy84)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-smoochy-7CC6FE?logo=ko-fi&logoColor=000000)](https://ko-fi.com/smoochy)

> A custom [Komodo](https://github.com/moghtech/komodo) Periphery image with [SOPS](https://github.com/getsops/sops) and [age](https://github.com/FiloSottile/age), published to GHCR with a public Docker Hub mirror and rebuilt automatically when upstream components change.

This repository publishes a Docker image based on
`ghcr.io/moghtech/komodo-periphery:latest` with `sops`, `age`, and
`age-keygen` preinstalled. It is intended for self-hosted environments that
want a ready-to-use Periphery image for encrypted secrets and configuration
handling without maintaining a custom build pipeline from scratch.

Registries:

- GHCR (canonical): `ghcr.io/smoochy/komodo-periphery-sops-age`
- Docker Hub (public mirror): `smoochy84/komodo-periphery-sops-age`

If this project helps your deployment workflow, you can support ongoing
maintenance for a project I maintain in my spare time via Ko-fi or Buy Me a
Coffee.

## Table of Contents

- [Background](#background)
- [What This Repository Does](#what-this-repository-does)
- [When Builds Run](#when-builds-run)
- [Dockerfile](#dockerfile)
- [GitHub Actions Workflow](#github-actions-workflow)
- [Job Summary](#job-summary)
- [Image Metadata](#image-metadata)
- [Image Tags](#image-tags)
- [Install](#install)
- [Usage](#usage)
- [Transparency](#transparency)
- [Security](#security)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [License](#license)

## Background

Komodo Periphery does not include every tool needed for encrypted
configuration workflows out of the box. This project provides a maintained
image variant with SOPS and age preinstalled so those workflows can be used
directly.

## What This Repository Does

- Builds a custom Docker image based on `ghcr.io/moghtech/komodo-periphery:latest`
- Adds:
  - `sops`
  - `age`
  - `age-keygen`
- Publishes the image to:
  - GHCR (canonical):
    - `ghcr.io/smoochy/komodo-periphery-sops-age:latest`
    - `ghcr.io/smoochy/komodo-periphery-sops-age:<komodo-version>`
  - Docker Hub (public mirror):
    - `smoochy84/komodo-periphery-sops-age:latest`
    - `smoochy84/komodo-periphery-sops-age:<komodo-version>`
- Tracks upstream updates and rebuilds only when needed

## When Builds Run

The workflow is triggered in three ways:

1. Push to `main`, but only when one of these files changes:
   - `Dockerfile*`
   - `.dockerignore`
   - `.github/workflows/build.yml`

   This prevents rebuilds for documentation-only changes such as `README.md`.

2. Scheduled run:
   - Runs a daily check for upstream changes such as the base digest, SOPS
     release, and age release
   - Builds only if something changed

3. Manual run with `workflow_dispatch`:
   - Optional `force=true` input to rebuild even if nothing changed

## Dockerfile

The `Dockerfile`:

- Uses `ghcr.io/moghtech/komodo-periphery:latest` as the base image
- Installs minimal dependencies such as `curl`, `tar`, and CA certificates
- Downloads and installs:
  - SOPS from `getsops/sops` GitHub releases
  - age and `age-keygen` from `FiloSottile/age` GitHub releases
- Supports multi-arch builds for:
  - `linux/amd64`
  - `linux/arm64`
- Stores the selected versions as OCI labels

The Dockerfile does not decide which versions to install. Version selection is
done by the workflow and passed in via build args.

## GitHub Actions Workflow

`build.yml` does the following:

1. Logs into GHCR and sets up Buildx.
2. Fetches upstream versions using authenticated GitHub API calls.
3. Reads metadata from the currently published image when it exists.
4. Compares:
   - komodo-periphery base digest
   - SOPS latest release version
   - age latest release version
5. Builds once, pushes to GHCR, and mirrors the published tags to Docker Hub
   when Docker Hub secrets are configured.
6. Publishes only when:
   - a push-triggered run happens
   - an upstream change is detected
   - a manual run is forced

## Job Summary

Every workflow run writes a summary that includes:

- The reason the build ran
- Which upstream component changed
- Direct links to upstream release notes for SOPS and age
- The selected versions for this run
- The current versions from the already published image
- Whether the Docker Hub mirror was updated or skipped

This makes it obvious why a new image was published and what changed.

## Image Metadata

Each published image includes OCI labels used for traceability and change
detection, for example:

- `org.opencontainers.image.base.tag`
- `org.opencontainers.image.base.digest`
- `org.opencontainers.image.sops.version`
- `org.opencontainers.image.age.version`

## Image Tags

This image is published with:

- `latest`: always points to the newest build
- `<x.y.z>`: matches the upstream Komodo Periphery version tag and is useful
  for reproducible deployments pinned to a specific Komodo release

## Install

Pull the published image from GHCR (canonical) or Docker Hub (public mirror):

```bash
docker pull ghcr.io/smoochy/komodo-periphery-sops-age:latest
```

```bash
docker pull smoochy84/komodo-periphery-sops-age:latest
```

If you need a specific Komodo release, pull the matching version tag instead:

```bash
docker pull ghcr.io/smoochy/komodo-periphery-sops-age:<x.y.z>
```

```bash
docker pull smoochy84/komodo-periphery-sops-age:<x.y.z>
```

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

The same tags are mirrored to Docker Hub at
[smoochy84/komodo-periphery-sops-age](https://hub.docker.com/r/smoochy84/komodo-periphery-sops-age).

## Transparency

The code, documentation, and related project materials in this repository were
created and refined with AI assistance. All generated output was reviewed and
adapted before publication.

## Security

- No secrets are baked into the image
- GitHub Actions uses the built-in `GITHUB_TOKEN` for:
  - GHCR authentication
  - authenticated GitHub API calls
- Optional Docker Hub publishing uses `DOCKERHUB_USERNAME` and
  `DOCKERHUB_TOKEN` repository secrets
- Only release metadata is queried from upstream projects

## Maintainers

- smoochy

## Contributing

Issues and pull requests are welcome. Keep Dockerfile, workflow, and README
changes aligned so the published image behavior remains easy to audit.

## License

[MIT](./LICENSE) 2026 [smoochy](https://github.com/smoochy)
