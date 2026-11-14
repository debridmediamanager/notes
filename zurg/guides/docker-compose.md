---
label: Docker Compose
icon: container
order: 62
description: "One tested docker-compose.yml that runs zurg, Plex Media Server and rex on one Linux machine, from install to playing in Plex, with fixes for the errors people hit."
---

# One Docker Compose file for zurg, Plex and rex

On a Linux machine, one `docker-compose.yml` can run zurg, Plex Media Server and rex side by side. zurg shows your library as folders under `/zurg_mnt/zurg`, Plex Media Server reads those folders, and rex gets the same library straight from zurg, no folders needed. Run zurg's Docker installer once, then swap its `docker-compose.yml` for the one below.

Want Plex Media Server or rex, not both? Leave the other one out of the file. Without Plex, also delete rex's `command:` line.

Docker Desktop on Windows or a Mac can't run this: zurg's folders never reach Explorer or Finder, and rex can't reach a zurg inside it. Use [zurg on Windows](../setup/windows.md) or [zurg on macOS](../setup/macos.md) there.

## Before you start

- **A Linux machine** that stays on. The installer adds Docker if it's missing.
- **A zurg sponsorship.** The zurg image is private. Sponsor on [gatekeeper](https://gatekeeper.debridmediamanager.com/) and it gives your GitHub account access.
- **Your Real-Debrid API token**, or the login for another service zurg supports: [Your Real-Debrid API token](../../guides/real-debrid-api-token.md).
- **For Plex Media Server**, your Plex account. **For rex**, a fresh Plex account made just for it: [rex with zurg](../../rex/with-zurg.md#before-you-start) says why.

## 1. Run zurg's Docker installer

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

It installs Docker if it's missing (it asks first), gets `/zurg_mnt` ready for zurg's folders now and after every reboot, signs you in to GitHub for the zurg image, writes `~/zurg/docker-compose.yml`, asks for your services and token, starts zurg and runs `zurg doctor`. [zurg's Docker setup](../setup/docker.md) does the same by hand.

**What you should see.**

```bash
ls /zurg_mnt/zurg
```

lists `__all__`, `__downloads__`, `__unplayable__`, `movies`, `shows` and `version.txt`.

## 2. Swap in the full file

```bash
cd ~/zurg
nano docker-compose.yml
```

Replace everything in it with this:

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

  plex:
    image: plexinc/pms-docker
    container_name: plex
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM=
    volumes:
      - ../plex/config:/config
      - ../plex/transcode:/transcode
      - /zurg_mnt:/zurg_mnt:rslave
    depends_on:
      zurg:
        condition: service_healthy

  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    command: --port 32500
    volumes:
      - ../rex/config:/config
```

- **zurg** is the installer's own service, unchanged.
- **plex** sees zurg's folders at the same path zurg uses, `/zurg_mnt/zurg`, so a scan zurg asks for names a folder Plex knows. `rslave` keeps the folders there when zurg restarts. Put your own time zone in `TZ`.
- **PLEX_CLAIM** signs Plex Media Server in to your account on its first start. Signed in to Plex, open [plex.tv/claim](https://www.plex.tv/claim), copy the code and paste it right after the `=`. It expires after a few minutes, so start the stack right away.
- **rex** is the service from [rex with zurg](../../rex/with-zurg.md#d2-start-rex-in-docker), on port 32500 because Plex Media Server holds 32400. Its files end up in `~/rex/config`, where rex with zurg looks for them.

Save it and start everything:

```bash
docker compose up -d
docker compose ps
```

If `docker` says permission denied, put `sudo` before every `docker` command on this page.

**What you should see.** Three containers: `plex` and `zurg` say `(healthy)`, `rex` says `Up`. Plex Media Server's own files go to `~/plex`.

## 3. Add zurg's folders in Plex

Open Plex Web at `http://<this machine's LAN IP>:32400/web`. Add a **Movies** library with the folder `/zurg_mnt/zurg/movies` and a **TV Shows** library with `/zurg_mnt/zurg/shows`.

So Plex hears about new things, open zurg's dashboard at `http://<this machine's LAN IP>:9999/config/` and press **Login with Plex** under **Media Server Integration**.

## 4. Set up rex

Follow [rex with zurg](../../rex/with-zurg.md) from [D3](../../rex/with-zurg.md#d3-add-it-to-a-plex-account) to [D5](../../rex/with-zurg.md#d5-watch), with `32500` wherever it says `32400`. For example zurg's line is `rex_url: http://192.168.1.20:32500`, with rex's LAN IP. Your Plex apps then list both servers: [step 2 of rex with zurg](../../rex/with-zurg.md#step-2-install-rex) says how to tell them apart.

## Updating

```bash
cd ~/zurg
docker compose pull
docker compose up -d
```

That updates zurg, Plex and rex together. Where rex with zurg runs `docker compose` in `~/rex`, run it here in `~/zurg` with `rex` at the end, so it touches rex alone: `docker compose stop rex` in place of `docker compose down`, `docker compose up -d rex` in place of `docker compose up -d`.

## When something is wrong

`docker compose logs --tail=100 zurg` (or `plex`, `rex`) shows what a container last said.

| What you see | What to do |
|---|---|
| The installer says `Host-visible Docker mounts require a Linux host. Use the binary installer on macOS or Windows.` | You're on a Mac or Windows. Install zurg with [its Windows](../setup/windows.md) or [macOS](../setup/macos.md) installer instead. |
| `Error response from daemon: error from registry: unauthorized` when Docker pulls zurg | This machine isn't signed in to GitHub's registry with an account that has zurg access. Sponsor on [gatekeeper](https://gatekeeper.debridmediamanager.com/), then run the installer again. To sign in by hand, see [zurg's Docker setup](../setup/docker.md#1-install-docker-and-unlock-the-image): the token needs both `read:packages` and `repo`. |
| `path /zurg_mnt is mounted on ... but it is not a shared mount` | `/zurg_mnt` isn't shared yet. Run `sudo mount --bind /zurg_mnt /zurg_mnt` and `sudo mount --make-rshared /zurg_mnt`, then `docker compose up -d`. The installer makes this stick after reboots; by hand, see [step 7 of zurg's Docker setup](../setup/docker.md#7-make-the-shared-parent-survive-reboots). |
| `zurg` keeps restarting, and its log ends with `Error: config ./config.yml is not valid YAML: yaml: unmarshal errors:` and `mapping key "..." already defined` | That setting is in zurg's config twice. Run `sudo nano ~/zurg/config.yml`, delete one of the two lines the error names, save, and run `docker compose restart zurg`. |
| zurg's log says `Mount verification failed: mount verification timeout: /zurg_mnt/zurg/version.txt not accessible after 60 attempts -- you appear to be running inside Docker, mount a parent directory with rshared propagation` | zurg's folders didn't come up. Check zurg's volume line is `/zurg_mnt:/zurg_mnt:rshared`, the parent and not `/zurg_mnt/zurg`, and that `/zurg_mnt` is shared (the row above). [Mount is empty](../setup/docker.md#mount-is-empty) has more checks. |
| Plex's libraries go empty after zurg restarts, and `docker exec plex ls /zurg_mnt/zurg` says `cannot access '/zurg_mnt/zurg': Transport endpoint is not connected` | Plex's volume line is missing `rslave`. It must read `/zurg_mnt:/zurg_mnt:rslave`. Fix it and run `docker compose up -d`. |
| rex stops with `rex: cannot bind 0.0.0.0:32400: Address already in use (os error 98) (another rex or Plex on this port? --port picks another)` | Plex Media Server already has port 32400. Keep `command: --port 32500` on rex. |
| `/zurg_mnt/zurg/movies` is empty, or says `Input/output error`, right after a start | zurg is still reading your account. `curl http://localhost:9999/ready` prints `ready` when it's done. Don't restart zurg meanwhile: that starts the reading over. |
| Titles show up in rex but nothing plays | The `upstream failed` row of [rex with zurg's When something is wrong](../../rex/with-zurg.md#when-something-is-wrong) checks whether rex can reach zurg. |
| The disk fills up | zurg keeps a copy of what was played in `~/zurg/data/rclone-cache`, up to 256G by default. [What lives where](../setup/docker.md#what-lives-where) shows how to cap it. |

Still stuck? Ask in the **zurg-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) says what to include.

## Questions

### Can you check my docker compose file?

Compare it with the one above. What matters most: zurg binds `/zurg_mnt` with `rshared`, Plex binds the same `/zurg_mnt` with `rslave`, and rex uses the `ghcr.io/debridmediamanager/rex` image with `network_mode: host`. A service named `rex` that runs `plexinc/pms-docker` is just a second Plex Media Server, not rex.

### Do I need a separate rclone container?

No. zurg runs rclone inside its own container and puts your library at `/zurg_mnt/zurg` itself.

### Can I use Plex Media Server and rex together?

Yes, that's what this file does. Plex Media Server plays from zurg's folders, and rex plays from zurg directly. Your Plex apps show both. Keep only the one you use if you'd rather not have both.

### Does this work on a NAS?

It was tested on a Linux PC, not on a NAS. The installer needs a terminal (SSH) with `sudo`, and FUSE (`/dev/fuse`). If step 1 ends with zurg's folders in `/zurg_mnt/zurg`, carry on with step 2.

### Which versions was this tested with?

zurg `2026.11.14.1134-nightly`, rex `2026.11.14.1123-nightly` and Plex Media Server `1.43.5.11079`, on 14 November 2026.
