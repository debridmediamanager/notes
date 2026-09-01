---
label: Docker
icon: container
order: 90
---

# Docker Setup

This guide covers running zurg in Docker with host-visible FUSE mounts.

> **Note:** The integrated rclone mount feature requires zurg v0.10+. The Docker image `ghcr.io/debridmediamanager/zurg:latest` is sponsors-only. See the [Patreon](https://www.patreon.com/debridmediamanager) for access.

## Quick Start

### 1. One-time host setup

FUSE mount propagation from Docker requires the parent directory to be a shared bind mount. Run this once (it does not survive reboots on its own — see step 5 to persist):

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

### 2. Create docker-compose.yml

Create `~/zurg/docker-compose.yml`. There is nothing else to create — no config file, no state directories:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:latest
    container_name: zurg
    restart: unless-stopped
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    ports:
      - 9999:9999
    environment:
      - TOKEN=YOUR_RD_API_TOKEN
      - MOUNT_PATH=/zurg_mnt/zurg
    volumes:
      - ./:/config
      - /zurg_mnt:/zurg_mnt:rshared
```

> **Note:** `privileged: true` is NOT required. `cap_add: SYS_ADMIN` with `apparmor:unconfined` provides the minimum permissions needed for FUSE mounts.

### 3. Start zurg

```bash
cd ~/zurg
docker compose up -d
```

`config.yml` appears next to your compose file, carrying the token and the mount you asked for. Open it, or use the Dashboard at `http://localhost:9999/config/` — both edit the same file.

### 4. Verify the mount

```bash
ls -la /zurg_mnt/zurg/
```

You should see your directories (movies, shows, etc.). A large library takes a while to load on the first run; until it has, `/dav/movies/` answers 503 and the mount lists nothing.

### 5. Persist across reboots

The bind mount from step 1 does not survive reboots. Create a systemd service to apply it automatically:

```bash
sudo tee /etc/systemd/system/rshared-zurg-mnt.service << 'EOF'
[Unit]
Description=Make /zurg_mnt rshared for Docker FUSE mounts
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "mount --bind /zurg_mnt /zurg_mnt && mount --make-rshared /zurg_mnt"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable rshared-zurg-mnt.service
```

## What lives where

Everything zurg writes resolves against its working directory, and in the image that directory is `/config`. One bind mount therefore holds the entire install:

| Path | What it is |
|---|---|
| `config.yml` | The only source of truth for settings. Dashboard edits are written straight back into it |
| `data/` | Library cache, network test results, and the rclone VFS cache |
| `logs/` | zurg's log and rclone's |
| `dump/` | Torrent dumps, when enabled |
| `strm/` | `.strm` files, when `save_strm_files` is on |
| `nzbs/` | The watch directory for the Usenet backend |

Pulling a new image moves none of it.

### Seeding the config from the environment

`TOKEN` (or `RD_TOKEN`) and `MOUNT_PATH` are read **only on the run that creates `config.yml`**. `MOUNT_PATH` writes both `rclone_enabled: true` and `mount_path`, which is what makes a first run mount something without a Dashboard visit.

After that the file wins and the variables are ignored, for the same reason `log_level` in the config beats `LOG_LEVEL` in the environment: a value baked into a compose file must not silently undo a setting changed in the Dashboard. Startup logs a warning when a `MOUNT_PATH` is set and disagrees with the config, so the ignoring is visible rather than mysterious. To move the mount, edit `config.yml` or use the Dashboard.

### Upgrading from an install that mounted `/app`

Nothing to do, and nothing to change. Older setups bind-mounted `/app/config.yml`, `/app/data` and friends individually; the container still picks `/app` whenever any of those is present, so an image update finds the same config and the same library cache it had yesterday.

To move such an install onto the single-folder layout, stop the container, put the existing `config.yml` and `data/` into one directory, and mount that directory at `/config` instead.

## How It Works

Docker's mount namespace isolation normally prevents FUSE mounts inside containers from being visible on the host. The solution is to mount a parent directory into the container with `rshared` propagation:

1. Make `/zurg_mnt` a shared bind mount on the host (`mount --bind /zurg_mnt /zurg_mnt && mount --make-rshared /zurg_mnt`)
2. Bind `/zurg_mnt` into the container with `rshared` propagation
3. Configure zurg to mount rclone at `/zurg_mnt/zurg` inside the container
4. The FUSE mount propagates back to the host automatically

### Why NOT `/mnt/zurg:/mnt/zurg:rshared`?

Mounting the exact target path does NOT work. FUSE mount propagation only works when the FUSE mount is created on a **subdirectory** of the `rshared` bind mount. When you bind the exact path, the FUSE mount replaces the bind mount instead of propagating through it.

## Troubleshooting

### "Transport endpoint is not connected"

The FUSE mount has become stale:
```bash
sudo fusermount -uz /zurg_mnt/zurg
docker compose restart zurg
```

### "fuse device not found"

Load the FUSE kernel module:
```bash
sudo modprobe fuse
echo "fuse" | sudo tee /etc/modules-load.d/fuse.conf
```

### Mount is empty

1. Check container logs:
```bash
docker logs zurg 2>&1 | grep -i rclone
```

2. Verify the mount inside the container:
```bash
docker exec zurg ls /zurg_mnt/zurg
```

3. Verify WebDAV is accessible:
```bash
curl -s http://localhost:9999/dav/version.txt
```

4. Make sure you are NOT using `/zurg_mnt/zurg:/zurg_mnt/zurg:rshared` — this will NOT work. You must mount the **parent directory** (`/zurg_mnt`) with rshared propagation.

5. Make sure the host bind mount is active:
```bash
findmnt /zurg_mnt
```
If it doesn't show `/zurg_mnt` as a bind mount, re-run step 1 from the Quick Start.

### Mount appears twice in `mount` output

This is normal with rshared propagation - the mount is visible in both the container and host mount namespaces.

### Container keeps restarting

```bash
docker logs zurg
```

Common issues:
- Invalid Real-Debrid token
- Network connectivity problems
- Missing `/zurg_mnt` directory on host
