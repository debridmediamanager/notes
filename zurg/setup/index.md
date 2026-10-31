---
label: Setup
icon: rocket
order: 90
---

# Setup

The binary installer is the shortest path on Linux, macOS and Windows. Docker remains available on a Linux host when a container fits better. Docker Desktop on macOS and Windows runs containers in a VM, so the mount cannot show up in Finder or Explorer: use the binary there.

## One-line convenience installers

The installers download a sponsor nightly. Sponsor on [gatekeeper](https://gatekeeper.debridmediamanager.com/) first. It gives your GitHub account access.

For a fresh sponsor install, choose the command for the host:

+++ Linux and macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```
+++ Docker on Linux
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```
+++ Windows
In PowerShell:
```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```
+++

The bootstrap checks platform prerequisites, signs in to GitHub for sponsor access, downloads the matching build and runs the provider chooser. Existing binaries and configs are preserved. Each guide below also keeps the complete manual route.

- [Linux](linux.md)
- [Docker](docker.md) (Linux hosts)
- [macOS](macos.md)
- [Windows](windows.md)

Once zurg is installed [Providers](../providers/index.md) covers pointing it at
an account. There is a page per service with the credential and the `config.yml`
entry and what that service does differently. Those pages are written for Docker. On a
binary install the provider's `config.yml` entry and the Dashboard steps are the same,
`./zurg service restart` (`.\zurg.exe service restart` on Windows) takes the place of
`docker compose restart zurg`, and their `docker compose run --rm zurg setup` line
becomes `./zurg setup` (`.\zurg.exe setup` on Windows) with the same flags except the
container's `--no-service --skip-downloads --mount-path /zurg_mnt/zurg`. A `--…-file` flag
then names a file on your machine instead of one under `/config`.
