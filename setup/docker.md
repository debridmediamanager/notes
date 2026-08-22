# Docker Setup

This guide covers running zurg in Docker with host-visible FUSE mounts.

> **Note:** The integrated rclone mount feature requires zurg v0.10+. The Docker image `ghcr.io/debridmediamanager/zurg:latest` is sponsors-only. See the [Patreon](https://www.patreon.com/debridmediamanager) for access.

## Quick Start

### 1. Create required directories

```bash
mkdir -p ~/zurg/{logs,data,dump,strm}
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
```

### 2. One-time host setup

FUSE mount propagation from Docker requires the parent directory to be a shared bind mount. Run this once (it does not survive reboots on its own — see step 6 to persist):

```bash
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

### 3. Configure your token

**Option A: Create config.yml** (full control)

Create `~/zurg/config.yml`:
```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
rclone_enabled: true
mount_path: /zurg_mnt/zurg

directories:
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - regex: /.*/

  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
```

**Option B: Use TOKEN env var** (zero-config)

Skip creating config.yml entirely. Set the `TOKEN` environment variable in docker-compose.yml (see step 4) and zurg will auto-create a default config with your token on first run. You can then customize settings via the Dashboard at `http://localhost:9999/config/`.

The generated config leaves `rclone_enabled` off and `mount_path` unset, so nothing appears at `/zurg_mnt/zurg` until you enable the rclone mount and point it at `/zurg_mnt/zurg` in the Dashboard. It is also written inside the container, so it is lost whenever the container is recreated — bind-mount `config.yml` (Option A) if you want Dashboard edits to survive.

### 4. Create docker-compose.yml

Create `~/zurg/docker-compose.yml`:
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
    healthcheck:
      test: curl -f localhost:9999/http/version.txt || exit 1
      interval: 10s
      timeout: 10s
      start_period: 60s
      retries: 1000
    ports:
      - 9999:9999
    volumes:
      # If using Option A (config.yml), mount it here:
      - ./config.yml:/app/config.yml
      # If using Option B (TOKEN env var), remove the config.yml mount above
      - ./logs:/app/logs
      - ./data:/app/data
      - ./dump:/app/dump
      - ./strm:/app/strm
      - /zurg_mnt:/zurg_mnt:rshared
    environment:
      - PUID=0
      - PGID=0
      # If using Option B, uncomment and set your token:
      # - TOKEN=YOUR_RD_API_TOKEN
```

> **Note:** `privileged: true` is NOT required. `cap_add: SYS_ADMIN` with `apparmor:unconfined` provides the minimum permissions needed for FUSE mounts.

### 5. Start zurg

```bash
cd ~/zurg
docker compose up -d
```

### 6. Verify the mount

```bash
ls -la /zurg_mnt/zurg/
```

You should see your directories (movies, shows, etc.).

### 7. Persist across reboots

The bind mount from step 2 does not survive reboots. Create a systemd service to apply it automatically:

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
If it doesn't show `/zurg_mnt` as a bind mount, re-run step 2 from the Quick Start.

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
