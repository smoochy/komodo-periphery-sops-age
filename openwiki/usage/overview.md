---
type: Usage
title: Usage Overview
description: Installation, usage examples, and verification steps for the komodo-periphery-sops-age Docker image.
resource: file:///openwiki/usage/overview.md
tags: [usage, docker, sops, age, examples]
---

# Usage Overview

This page provides practical guidance for pulling, running, and verifying the komodo-periphery-sops-age image.

## Quick Start

### Pull the Image

```bash
# Latest major version (recommended for production)
docker pull ghcr.io/smoochy/komodo-periphery-sops-age:2

# Specific minor version
docker pull ghcr.io/smoochy/komodo-periphery-sops-age:2.1

# Specific patch version (immutable)
docker pull ghcr.io/smoochy/komodo-periphery-sops-age:2.1.3

# Docker Hub mirror (if GHCR unavailable)
docker pull smoochy84/komodo-periphery-sops-age:2
```

### Verify Installation

```bash
# Check SOPS version
docker run --rm ghcr.io/smoochy/komodo-periphery-sops-age:2 sops --version

# Check age version
docker run --rm ghcr.io/smoochy/komodo-periphery-sops-age:2 age --version

# Check age-keygen version
docker run --rm ghcr.io/smoochy/komodo-periphery-sops-age:2 age-keygen --version
```

## Common Usage Patterns

### 1. Decrypt SOPS Files with age

```bash
# Generate an age key pair (once)
docker run --rm -v "$PWD:/work" ghcr.io/smoochy/komodo-periphery-sops-age:2 \
  age-keygen -o /work/age-key.txt

# Encrypt a file for that key
docker run --rm -v "$PWD:/work" ghcr.io/smoochy/komodo-periphery-sops-age:2 \
  sops --encrypt --age "$(cat /work/age-key.txt | grep 'public key:' | cut -d: -f2 | xargs)" \
  --input-type yaml --output-type yaml /work/secrets.yaml > /work/secrets.enc.yaml

# Decrypt the file
docker run --rm -v "$PWD:/work" -e SOPS_AGE_KEY_FILE=/work/age-key.txt \
  ghcr.io/smoochy/komodo-periphery-sops-age:2 \
  sops --decrypt /work/secrets.enc.yaml
```

### 2. Use as Komodo Periphery Base

The image **is** a Komodo Periphery image with extra tools. Use it anywhere you'd use the base:

```yaml
# docker-compose.yml
services:
  periphery:
    image: ghcr.io/smoochy/komodo-periphery-sops-age:2
    # ... rest of your periphery config
```

### 3. CI/CD Pipeline Integration

```yaml
# .github/workflows/deploy.yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/smoochy/komodo-periphery-sops-age:2
    steps:
      - uses: actions/checkout@v4
      - name: Decrypt secrets
        run: |
          echo "${{ secrets.AGE_PRIVATE_KEY }}" > /tmp/age-key.txt
          export SOPS_AGE_KEY_FILE=/tmp/age-key.txt
          sops --decrypt secrets.enc.yaml > secrets.yaml
      - name: Deploy
        run: komodo deploy --config secrets.yaml
```

### 4. Interactive Shell

```bash
# Drop into a shell with all tools available
docker run --rm -it -v "$PWD:/work" ghcr.io/smoochy/komodo-periphery-sops-age:2 sh

# Inside container:
# sops --version
# age --version
# komodo --version  # base periphery command
```

## Image Verification

### Check Image Labels (Version Metadata)

```bash
# Via crane (no pull needed)
crane config ghcr.io/smoochy/komodo-periphery-sops-age:2 | jq '.config.Labels'

# Via docker (after pull)
docker inspect ghcr.io/smoochy/komodo-periphery-sops-age:2 --format '{{json .Config.Labels}}' | jq
```

Expected labels:
```json
{
  "org.opencontainers.image.version": "2.1.3",
  "org.opencontainers.image.base.name": "ghcr.io/moghtech/komodo-periphery:2",
  "org.opencontainers.image.base.digest": "sha256:...",
  "org.opencontainers.image.sops.version": "3.8.1",
  "org.opencontainers.image.age.version": "1.2.0"
}
```

### Verify Binary Integrity

```bash
# SOPS should report version and check for updates (non-fatal)
docker run --rm ghcr.io/smoochy/komodo-periphery-sops-age:2 sops --version --check-for-updates

# age should report version
docker run --rm ghcr.io/smoochy/komodo-periphery-sops-age:2 age --version

# age-keygen should report version
docker run --rm ghcr.io/smoochy/komodo-periphery-sops-age:2 age-keygen --version
```

## Tag Selection Guide

| Use Case | Recommended Tag | Reason |
|----------|-----------------|--------|
| Production (stable) | `:2` (major) | Auto-updates on base minor/patch; tested compatibility |
| Pinned minor | `:2.1` | Locks minor version; gets base patches + tool updates |
| Fully pinned | `:2.1.3` | Immutable; exact reproducibility |
| CI/CD (reproducible) | `:2.1.3` | Guarantees same base+tools every run |
| Development | `:2` | Latest tools and base patches |

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `SOPS_AGE_KEY_FILE` | Path to age private key for decryption | `/run/secrets/age-key.txt` |
| `SOPS_AGE_KEY` | Age public key for encryption (inline) | `age1xxx...` |
| `SOPS_CONFIG_FILE` | Custom `.sops.yaml` path | `/config/.sops.yaml` |

## Troubleshooting

### "No such image" / Pull Fails

```bash
# Try Docker Hub mirror
docker pull smoochy84/komodo-periphery-sops-age:2

# Check available tags
crane ls ghcr.io/smoochy/komodo-periphery-sops-age
```

### SOPS/age Version Mismatch

```bash
# Check what versions are actually in the image
docker run --rm ghcr.io/smoochy/komodo-periphery-sops-age:2 sops --version
docker run --rm ghcr.io/smoochy/komodo-periphery-sops-age:2 age --version

# Compare with image labels
crane config ghcr.io/smoochy/komodo-periphery-sops-age:2 | jq '.config.Labels["org.opencontainers.image.sops.version"]'
```

### Permission Denied on Mounted Files

```bash
# Run as root (image default) or fix ownership
docker run --rm -u root -v "$PWD:/work" ghcr.io/smoochy/komodo-periphery-sops-age:2 sops -d /work/file.yaml
```

## Advanced: Building Locally

```bash
# Build with specific versions (matching a published tag)
docker buildx build \
  --platform linux/amd64 \
  --build-arg SOPS_VERSION=3.8.1 \
  --build-arg AGE_VERSION=1.2.0 \
  --build-arg BASE_DIGEST=$(crane digest ghcr.io/moghtech/komodo-periphery:2) \
  --build-arg BASE_VERSION=2.1.3 \
  -t komodo-periphery-sops-age:local \
  --load .
```

## Relationships

<!-- openwiki: broken internal link [architecture/overview.md] file "architecture/overview.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Image source** → [Architecture Overview](architecture/overview.md)
<!-- openwiki: broken internal link [reference/image-metadata.md] file "reference/image-metadata.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Tag/label details** → [Image Metadata](reference/image-metadata.md)
<!-- openwiki: broken internal link [architecture/build-system.md] file "architecture/build-system.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Build process** → [Build System](architecture/build-system.md)
<!-- openwiki: broken internal link [operations/overview.md] file "operations/overview.md" does not exist. Fix the href or restore the target, then delete this comment. -->
- **Operations/debugging** → [Operations](operations/overview.md)