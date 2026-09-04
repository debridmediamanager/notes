# Docker setup

This guide runs zurg in Docker while making its FUSE mount visible on the Linux host. Docker supplies zurg, rclone and ffprobe and keeps the container running. The built-in `setup` command creates the config and the built-in `doctor` command checks the finished install.

The container setup flow was verified on 4 September 2026 with Docker Engine 29.1.1. Use the newest dated nightly release so the image contains the provider chooser described below.

> **Sponsor image:** `ghcr.io/debridmediamanager/zurg` is sponsors-only. See [Patreon](https://www.patreon.com/debridmediamanager) for access.

> **Linux host required:** the host-visible mount below depends on Linux mount propagation. Docker Desktop runs containers inside a VM on macOS and Windows and cannot propagate this FUSE mount into Finder or Explorer. Use the [macOS](macos.md) or [Windows](windows.md) binary guide when the media server runs on either host.

## One-line option

On a fresh Linux host the optional bootstrap can install Docker when approved, configure persistent FUSE propagation, authenticate to the sponsor registry, create the Compose project and run the provider chooser:

```bash
curl -fsSL https://zurg.debridmediamanager.com/install-docker.sh | bash
```

Existing Compose files and configs are preserved. Continue below for the complete manual route.

## What the installer does in a container

The flags are deliberate:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

- `setup` asks which providers to configure, prompts only for their credentials and writes `config.yml` with mode `0600`.
- `--no-service` leaves auto-start to Docker's `restart: unless-stopped` policy instead of trying to install systemd inside Alpine.
- `--skip-downloads` uses the rclone and ffprobe already installed in the image.
- `--mount-path` records the subdirectory whose FUSE mount will propagate back to the host.

Running setup again is safe. It validates and updates the install but does not replace an existing `config.yml`.

## 1. Install Docker and unlock the image

Install Docker Engine with the Compose plugin on the Linux host. Check both commands before continuing:

```bash
docker version
docker compose version
```

Sign in to GitHub Container Registry with your GitHub username. When prompted for the password, paste a personal access token with `read:packages` access:

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

Set `ZURG_TAG` to the newest dated sponsor release. Keeping it in `.env` gives you a known rollback target and makes upgrades explicit:

```bash
printf 'ZURG_TAG=YYYY.MM.DD.HHMM-nightly\n' > .env
```

Replace the placeholder with the actual release tag before continuing.

## 2. Prepare FUSE mount propagation

The FUSE mount must be created below a shared parent mount. Run this once before the first container starts:

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

Verify the device and propagation mode:

```bash
test -c /dev/fuse
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

The second command should report `shared` under `PROPAGATION`.

## 3. Create the compose project

```bash
mkdir -p ~/zurg
cd ~/zurg
```

Create `docker-compose.yml`:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:${ZURG_TAG}
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
    volumes:
      - ./:/config
      - /zurg_mnt:/zurg_mnt:rshared
```

`privileged: true` is not required. The FUSE device, `SYS_ADMIN` capability and unconfined AppArmor profile are the narrower set used by the mount.

Do not bind `/zurg_mnt/zurg` directly. The FUSE mount must be a child of the `rshared` bind for its mount event to reach the host.

## 4. Run the built-in setup

From `~/zurg` run:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

Choose one or several providers in priority order. For example enter `2,4` for TorBox followed by Usenet. Setup asks only for their credentials, creates `config.yml` in `~/zurg`, enables rclone and creates `/zurg_mnt/zurg`. No credential is stored in the compose file or shell history.

For automation repeat `--provider` and pass the provider-specific token-file or `--nntp-*` flags. Setup preserves an existing config on later runs.

## 5. Start zurg

```bash
docker compose up -d
docker compose logs -f --tail=100 zurg
```

Leave the log view with `Ctrl+C`; the container keeps running. The Dashboard is at `http://localhost:9999/config/` and edits the same `config.yml` stored beside the compose file.

A large library can take a while to load on its first run. Until it has, `/dav/movies/` answers 503 and the mount may list nothing.

## 6. Verify with doctor

Once the library is ready, run the same diagnostic tool used by a binary install:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`doctor` checks the config and its permissions, ffprobe, rclone, FUSE, the HTTP endpoint and the mount reported by zurg. `WARN service zurg is not installed` is expected in Docker because Compose owns auto-start. Warnings do not make the command fail; any `FAIL` does.

Confirm that the propagated mount is also visible outside the container:

```bash
cat /zurg_mnt/zurg/version.txt
ls -la /zurg_mnt/zurg/
```

## 7. Make the shared parent survive reboots

The self-bind from step 2 does not survive a reboot. Create a systemd oneshot unit on the host:

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

On the next reboot the host prepares the shared parent before Docker restores the zurg container.

## Managing and updating zurg

Run these from `~/zurg`:

```bash
docker compose ps
docker compose logs -f --tail=100 zurg
docker compose restart zurg
docker compose stop zurg
docker compose start zurg
```

To upgrade, replace the dated image tag in `docker-compose.yml`, then recreate the container and run doctor:

```bash
docker compose pull zurg
docker compose up -d zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

To roll back, restore the previous tag and run those three commands again. The bind-mounted config, library state, logs and cache do not move with the container.

`docker compose down` removes the container and network but leaves the bind-mounted files in `~/zurg` and the mount parent at `/zurg_mnt`.

## What lives where

Everything zurg writes resolves against `/config`, so the single `./:/config` bind holds the install:

| Path | What it is |
|---|---|
| `config.yml` | Settings and provider credentials; Dashboard edits write back here |
| `data/` | Library state, local files, generated keys and the rclone VFS cache |
| `logs/` | zurg and rclone logs |
| `dump/` | Torrent dumps when enabled |
| `strm/` | `.strm` files when `save_strm_files` is enabled |
| `nzbs/` | Watch directory for the Usenet backend |

Pulling or recreating the image changes none of these files.

### Environment seeding for unattended installs

The image still supports the older first-run path. If no `config.yml` exists, `TOKEN` or `RD_TOKEN` seeds the account and `MOUNT_PATH` enables the mount. Those variables are read only while the file is being created; the file wins on every later start.

The interactive `setup` command is preferred for a person at a terminal because the token never enters the compose file. Environment seeding remains useful for automation that already has a secret store.

### Upgrading an install that mounted `/app`

Older compose projects bind-mounted `/app/config.yml`, `/app/data` and other paths separately. The entrypoint still selects `/app` whenever it finds that layout, so pulling a newer image keeps using the old config and cache.

To adopt the single-folder layout, stop the container, copy the existing `config.yml`, `data/` and other state directories into one host directory, then bind that directory at `/config`.

## Troubleshooting

Start with the diagnostic and the current logs:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
docker compose logs --tail=200 zurg
```

### `unknown command "setup"` or `unknown command "doctor"`

The container predates the built-in installer. Use `2026.09.04.1449-nightly` or a newer dated zurg image, then recreate it:

```bash
docker compose pull zurg
docker compose up -d zurg
```

### `Transport endpoint is not connected`

The old FUSE mount is stale:

```bash
sudo fusermount -uz /zurg_mnt/zurg
docker compose restart zurg
```

### FUSE device is unavailable

Load the module now and on later boots:

```bash
sudo modprobe fuse
echo fuse | sudo tee /etc/modules-load.d/fuse.conf
```

Then confirm the compose service still includes `/dev/fuse`, `SYS_ADMIN` and the AppArmor setting.

### Mount is empty

Check each layer in order:

```bash
docker compose logs zurg 2>&1 | grep -i rclone
docker compose exec zurg ls -la /zurg_mnt/zurg
curl -fsS http://localhost:9999/http/version.txt
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

The host path must be a shared bind mount and the compose volume must bind the parent as `/zurg_mnt:/zurg_mnt:rshared`.

### Mount appears twice in `mount` output

That is normal. The same FUSE mount is visible in the container and host mount namespaces because propagation is working.
