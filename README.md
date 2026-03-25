# komodo-periphery-sops-age

[![README Style](https://img.shields.io/badge/README%20style-standard-2ea44f)](https://github.com/RichardLitt/standard-readme)
[![CI](https://github.com/smoochy/komodo-periphery-sops-age/actions/workflows/build.yml/badge.svg)](https://github.com/smoochy/komodo-periphery-sops-age/actions)

[![Buy me uptime](https://img.shields.io/badge/Buy%20me%20uptime%20%F0%9F%96%A5%EF%B8%8F-smoochy84-E9C46A?logo=buymeacoffee&logoColor=000000)](https://www.buymeacoffee.com/smoochy84)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-smoochy-7CC6FE?logo=ko-fi&logoColor=000000)](https://ko-fi.com/smoochy)

> A custom [Komodo](https://github.com/moghtech/komodo) Periphery image with [SOPS](https://github.com/getsops/sops) and [age](https://github.com/FiloSottile/age), published to GHCR with a public Docker Hub mirror and rebuilt automatically when upstream components change.

This repository publishes a Docker image based on `ghcr.io/moghtech/komodo-periphery:2` with `sops`, `age`, and `age-keygen` preinstalled. It is intended for self-hosted environments that want a ready-to-use Periphery image for encrypted secrets and configuration handling without maintaining a custom build pipeline from scratch.

Registries:

- GHCR (canonical): `ghcr.io/smoochy/komodo-periphery-sops-age`
- Docker Hub (public mirror): `smoochy84/komodo-periphery-sops-age`

If this project helps your deployment workflow, you can support ongoing maintenance for a project I maintain in my spare time via Ko-fi or Buy Me a Coffee.

## Table of Contents

- [komodo-periphery-sops-age](#komodo-periphery-sops-age)
  - [Table of Contents](#table-of-contents)
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

Komodo Periphery does not include every tool needed for encrypted configuration workflows out of the box. This project provides a maintained image variant with SOPS and age preinstalled so those workflows can be used directly.

## What This Repository Does

- Builds a custom Docker image based on `ghcr.io/moghtech/komodo-periphery:2`
- Adds:
  - `sops`
  - `age`
  - `age-keygen`
- Publishes the image to:
  - GHCR (canonical):
    - `ghcr.io/smoochy/komodo-periphery-sops-age:<major>`
    - `ghcr.io/smoochy/komodo-periphery-sops-age:<major.minor>`
    - `ghcr.io/smoochy/komodo-periphery-sops-age:<major.minor.patch>`
  - Docker Hub (public mirror):
    - `smoochy84/komodo-periphery-sops-age:<major>`
    - `smoochy84/komodo-periphery-sops-age:<major.minor>`
    - `smoochy84/komodo-periphery-sops-age:<major.minor.patch>`
- Tracks upstream updates and rebuilds only when needed

## When Builds Run

The workflow is triggered in three ways:

1. Push to `main`, but only when one of these files changes:
   - `Dockerfile*`
   - `.dockerignore`
   - `.github/workflows/build.yml`

   This prevents rebuilds for documentation-only changes such as `README.md`.

2. Scheduled run:
   - Runs a daily check for upstream changes such as the base digest, SOPS release, and age release
   - Builds only if something changed

3. Manual run with `workflow_dispatch`:
   - Optional `force=true` input to rebuild even if nothing changed

## Dockerfile

The `Dockerfile`:

- Uses `ghcr.io/moghtech/komodo-periphery:2` as the base image
- Installs minimal dependencies such as `curl`, `tar`, and CA certificates
- Downloads and installs:
  - SOPS from `getsops/sops` GitHub releases
  - age and `age-keygen` from `FiloSottile/age` GitHub releases
- Supports multi-arch builds for:
  - `linux/amd64`
  - `linux/arm64`
- Stores the selected versions as OCI labels

The Dockerfile does not decide which versions to install. Version selection is done by the workflow and passed in via build args.

## GitHub Actions Workflow

`build.yml` does the following:

1. Logs into GHCR and sets up Buildx.
2. Fetches upstream versions using authenticated GitHub API calls.
3. Reads metadata from the currently published image when it exists.
4. Compares:
   - komodo-periphery base digest
   - SOPS latest release version
   - age latest release version
5. Builds once, pushes to GHCR, and mirrors the published tags to Docker Hub when Docker Hub secrets are configured.
6. Publishes only when:
   - a push-triggered run happens
   - an upstream change is detected
   - a manual run is forced
7. Publishes three SemVer tags for the selected Komodo release:
   - the floating major tag, for example `2`
   - the floating major/minor tag, for example `2.0`
   - the exact release tag, for example `2.0.0`

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

Each published image includes OCI labels used for traceability and change detection, for example:

- `org.opencontainers.image.base.tag`
- `org.opencontainers.image.base.digest`
- `org.opencontainers.image.sops.version`
- `org.opencontainers.image.age.version`

## Image Tags

This image is published with:

- `<x>`: tracks the current upstream Komodo major line, for example `2`
- `<x.y>`: tracks the current upstream Komodo minor line, for example `2.0`
- `<x.y.z>`: matches the exact upstream Komodo Periphery release and is useful for reproducible deployments pinned to a specific Komodo release

The exact `<x.y.z>` tag is resolved from the digest currently served by `ghcr.io/moghtech/komodo-periphery:2`. For the current upstream v2 release, that means the custom image publishes `2`, `2.0`, and `2.0.0`.

## Install

Pull the published image from GHCR (canonical) or Docker Hub (public mirror):

```bash
docker pull ghcr.io/smoochy/komodo-periphery-sops-age:2
```

If you want to follow the Komodo v2 line without pinning to one exact patch release, use the floating major tag:

```bash
docker pull smoochy84/komodo-periphery-sops-age:2
```

```bash
docker pull ghcr.io/smoochy/komodo-periphery-sops-age:2.0
```

```bash
docker pull smoochy84/komodo-periphery-sops-age:2.0
```

If you need a specific Komodo release, pull the matching exact version tag instead:

```bash
docker pull ghcr.io/smoochy/komodo-periphery-sops-age:<x.y.z>
```

```bash
docker pull smoochy84/komodo-periphery-sops-age:<x.y.z>
```

If you are upgrading an existing Komodo v1 deployment to v2, [follow the official Komodo upgrade guide](https://komo.do/docs/releases/v2.0.0#upgrading-to-komodo-v2).

## Usage

Example `docker-compose.yml`:

```yaml
services:
  periphery:
    image: ghcr.io/smoochy/komodo-periphery-sops-age:2
```

or

```yaml
services:
  periphery:
    image: ghcr.io/smoochy/komodo-periphery-sops-age:2.0.0
```

The same tags are mirrored to Docker Hub at [smoochy84/komodo-periphery-sops-age](https://hub.docker.com/r/smoochy84/komodo-periphery-sops-age).

## Transparency

The code, documentation, and related project materials in this repository were created and refined with AI assistance. All generated output was reviewed and adapted before publication.

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

Issues and pull requests are welcome. Keep Dockerfile, workflow, and README changes aligned so the published image behavior remains easy to audit.

## License

[MIT](./LICENSE) 2026 [smoochy](https://github.com/smoochy)
