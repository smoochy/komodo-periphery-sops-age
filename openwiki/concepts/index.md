# Files

- [Multi-Architecture Building](multi-arch.md) - Document the multi-architecture build strategy supporting linux/amd64 and linux/arm64 platforms. Covers architecture mapping, QEMU emulation, and single manifest list publishing.
- [Version Tracking & Change Detection](version-tracking.md) - Document the version tracking and change detection logic that determines when builds run. Covers base image digest comparison, SOPS/age release comparison, and the decision logic for forced vs. skipped builds.
