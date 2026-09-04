# Setup

The binary installer is the shortest path on Linux, macOS and Windows. Docker remains available when a container fits the host better.

## One-line convenience installers

For a fresh sponsor install, choose the command for the host:

```bash
# Linux or macOS
curl -fsSL https://zurg.debridmediamanager.com/install.sh | bash

# Docker on Linux
curl -fsSL https://zurg.debridmediamanager.com/install-docker.sh | bash
```

```powershell
# Windows PowerShell
irm https://zurg.debridmediamanager.com/install.ps1 | iex
```

The bootstrap checks platform prerequisites, signs in to GitHub for sponsor access, downloads the matching build and runs the provider chooser. Existing binaries and configs are preserved. Each guide below also keeps the complete manual route.

- [Linux](linux.md)
- [Docker](docker.md)
- [macOS](macos.md)
- [Windows](windows.md)
