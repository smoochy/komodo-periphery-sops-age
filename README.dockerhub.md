# komodo-periphery-sops-age

[![CI](https://github.com/smoochy/komodo-periphery-sops-age/actions/workflows/build.yml/badge.svg)](https://github.com/smoochy/komodo-periphery-sops-age/actions/workflows/build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/smoochy84/komodo-periphery-sops-age?logo=docker)](https://hub.docker.com/r/smoochy84/komodo-periphery-sops-age)
[![Docker Stars](https://img.shields.io/docker/stars/smoochy84/komodo-periphery-sops-age?logo=docker)](https://hub.docker.com/r/smoochy84/komodo-periphery-sops-age)

[![Buy me uptime](https://img.shields.io/badge/Buy%20me%20uptime%20%F0%9F%96%A5%EF%B8%8F-smoochy84-E9C46A?logo=buymeacoffee&logoColor=000000)](https://www.buymeacoffee.com/smoochy84)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-smoochy-7CC6FE?logo=ko-fi&logoColor=000000)](https://ko-fi.com/smoochy)

Komodo Periphery image with `sops`, `age`, and `age-keygen` preinstalled,
rebuilt automatically when upstream components change.

## Quick pull

```bash
docker pull smoochy84/komodo-periphery-sops-age:latest
```

## What you get

- `sops` for encrypted configuration and secret management workflows
- `age` and `age-keygen` ready to use inside the container
- Multi-arch images for `linux/amd64` and `linux/arm64`
- Automatic rebuilds when Komodo Periphery, SOPS, or age changes upstream

## Tags

- `latest`
- `<x.y.z>` matching the upstream Komodo Periphery release

## Why this image

- Avoid maintaining a separate bootstrap image for secret tooling
- Keep encrypted deployment workflows ready out of the box
- Track upstream changes automatically
- Use reproducible version tags for pinned deployments

## Full documentation

See the GitHub repository for install details, workflow behavior, and example
usage:

<https://github.com/smoochy/komodo-periphery-sops-age>

## Support

If this image saves you time or helps your setup, you can support ongoing
maintenance for a project I maintain in my spare time via Ko-fi or Buy Me a
Coffee.
