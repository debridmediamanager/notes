---
label: rex
icon: server
order: 45
---

# rex with zurg

[rex](https://rex.debridmediamanager.com) is a Plex Media Server that owns no files. The official Plex apps see it as a normal Plex server. zurg sends it your debrid library, and when you press play rex streams the file straight from zurg. Nothing is downloaded first.

This page sets up both from scratch on one machine. It takes about 15 minutes, plus a few hours for a big library to fill.

![zurg registers with rex and sends it the library; Plex apps play through rex, which reads each file from zurg](../assets/rex/how-it-fits.svg)

- zurg tells rex where its files are and sends it every movie and episode with its media details.
- rex keeps no files and reads no disk. You do not need rclone or a FUSE mount for rex.
- You configure nothing about zurg on rex's side. zurg needs one line: `rex_url`.

rex opens as a closed beta for sponsors on October 15 and reaches the public on October 31. See [rex.debridmediamanager.com](https://rex.debridmediamanager.com) for access.

## What you need

| | |
|---|---|
| A machine | Linux (Ubuntu 22.04 or newer), macOS or Windows. A Proxmox LXC works, unprivileged is fine |
| Its size | For a library of about 10,000 items: 4 cores, 8 GB of RAM and a 64 GB disk. rex keeps the library in memory and uses more while it fills the first time. zurg uses little |
| zurg | A sponsor nightly from **2026.10.15 or later**. Older builds never tell rex where their files are, and the public v1.0.0 cannot feed rex at all |
| rex | v0.3.0 or newer: the download (step 2) or the [Docker image](#run-rex-in-docker) |
| A TMDB key | Free. Make one at [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api) and copy the **API Key** |
| Your Plex token | Not needed |

## 1. Install zurg

Follow the [Linux](../setup/linux.md), [macOS](../setup/macos.md), [Windows](../setup/windows.md) or [Docker](../setup/docker.md) setup, or use the one-line installer:

```bash
curl -fsSL https://zurg.debridmediamanager.com/install.sh | bash
```

Already have zurg? Update it:

```bash
zurg update
```

The config `zurg setup` writes has two directories, `movies` and `shows`. Keep those names. rex puts files under `movies/` into its Movies library and files under `shows/` into TV, and refuses anything else unless you tell it about the other directories first (step 3).

Check that zurg is up and its library has loaded:

```bash
curl -s http://127.0.0.1:9999/dav/
```

It lists `movies/` and `shows/`. While the library is still loading it answers 503.

## 2. Get rex

Running Docker on Linux? Use the [Docker image](#run-rex-in-docker) instead and skip steps 2, 4 and 8.

Download the build for your machine from [rex's releases](https://github.com/debridmediamanager/rex/releases): Linux (amd64 and arm64, Ubuntu 22.04 or newer), macOS (Intel and Apple Silicon) or Windows (64 bit). You need **v0.3.0 or newer**. v0.2.0 cannot take a library from zurg this way.

```bash
mkdir -p ~/rex && cd ~/rex
tar xzf ~/Downloads/rex-v0.3.0-linux-amd64.tar.gz --strip-components=1
```

On Windows unpack the zip into a folder of its own and use `rust\target\release\rex.exe` wherever this page says `rust/target/release/rex`.

rex is now at `~/rex/rust/target/release/rex`. Always start it from `~/rex`, because it reads its `data/` folder from there.

Put your keys in `~/rex/rex.env`:

```bash
TMDB_KEY=your_tmdb_api_key
```

```bash
chmod 600 ~/rex/rex.env
```

Optional lines for the same file:

| Line | What it does |
|---|---|
| `REX_METADATA_URL=https://debridmediamanager.com` and `REX_METADATA_KEY=<your DMM key>` | Sponsors only. rex reads posters and episode lists from DMM first, where most shows are already cached. `TMDB_KEY` then becomes optional |
| `REX_ANIME_LISTS=on` | Places fansub releases (`Hibike Euphonium 3 - 01`) on the right TMDB season and episode |
| `REX_IMDB_EPISODES=on` | Places long shows that TMDB files as one season, like Detective Conan, on the right episode |

## 3. Name your directories before the first start

The first start creates `rex.db` with two libraries: Movies for `movies/` and TV for `shows/`. From then on rex keeps those libraries. A directory you add later needs a library of its own.

If zurg only has `movies` and `shows`, skip this step.

If zurg has more, for example an `anime` directory, create the libraries yourself before the first start:

```bash
cd ~/rex
rust/target/release/rex catalog --seed --name myrex --out rex.db \
  --movies movies --shows shows --shows anime
```

## 4. Start rex

```bash
cd ~/rex
set -a; . ./rex.env; set +a
rust/target/release/rex --catalog rex.db --friendly-name myrex \
  --zurg-mount /mnt/zurg \
  --owner-username <your Plex username> --owner-email <your Plex email>
```

- `--friendly-name` is the server name the Plex apps show.
- `--zurg-mount` is zurg's `mount_path`. In Docker that is usually `/zurg_mnt/zurg`.
- **Plex Media Server runs on the same machine?** Add `--port 32500 --gdm off`. Plex already uses port 32400 and the ports apps use to find servers on your network.

Check that it answers:

```bash
curl -s http://127.0.0.1:32400/identity
curl -s http://127.0.0.1:32400/rex/sources
```

The second line shows `{"size":0}` until zurg connects.

## 5. Point zurg at rex

Add this to zurg's `config.yml` and restart zurg:

```yaml
rex_url: http://<rex's LAN IP>:32400
```

That one line is all rex needs. Optional lines:

```yaml
rex_source: rd                # the name rex knows this zurg by. Give each zurg its own when you run several
dmm_api_key: <your DMM key>   # sponsors: zurg takes media details DMM already has instead of reading the file
```

Three things to get right:

- **Leave out `rex_feed_token`.** It is only for rex builds from before 2026-10-15.
- **Keep `plex_server_url` on your real Plex**, or leave it empty. If it points at rex, zurg learns rex's own matches and a wrong match can never be corrected.
- **rex must be able to reach zurg.** zurg tells rex its address: the address zurg uses to reach rex. On one machine or one home network that just works. If zurg runs in Docker and rex runs on another machine, give the zurg container `network_mode: host`, or rex gets the container's internal address and cannot play anything.

Once zurg's library has loaded, it connects to rex and sends the whole library, then every change as it happens. It sends the whole library again every 6 hours.

**A movie or episode only shows up once zurg has read its media details.** zurg does that by itself for new releases, half an hour after it starts and then once a day. To fill an existing library now, press **Analyze & Tag Library** on zurg's dashboard. It reads about 50 files a minute, so 10,000 items take a few hours. After a zurg restart, press it again; it skips what is done.

Check it:

```bash
curl -s http://127.0.0.1:32400/rex/sources
curl -s http://127.0.0.1:32400/rex/feed/zurg/items | head -c 500
```

The first line now lists zurg with a `url` ending in `/dav`. Use the name you set in `rex_source` in place of `zurg` in the second line.

Open a Plex app on the same network. rex shows up on its own when it runs on port 32400. Until you claim it in step 6, anyone on your home network can browse it. It does not answer Tailscale addresses or a host name, so use its LAN IP.

## 6. Add it to your Plex account (optional)

This step is at your own risk. rex is not made by Plex, and Plex could take action against an account that registers it. Skip it and rex only answers on your home network.

1. Open [plex.tv/claim](https://www.plex.tv/claim) and copy the code. It expires in four minutes.
2. Send it to rex:

   ```bash
   curl -X POST "http://127.0.0.1:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://127.0.0.1:32400/identity
   ```

   The second line now says `claimed="1"`.
3. Back up `~/rex/claim_state.json`. Claim each server only once. If you lose this file you have to claim again.

Once claimed, rex also matches your titles with Plex's own metadata, using the server's token from the claim.

## 7. Use it outside your home (optional)

app.plex.tv and Plex apps away from home only connect to an HTTPS address that is reachable from the internet. rex has no relay, so give it a certificate for a host name you own. With Tailscale:

```bash
sudo tailscale cert myhost.tailnet.ts.net
openssl pkcs8 -topk8 -nocrypt -in myhost.tailnet.ts.net.key -out myhost.pkcs8.key
```

Then add to the start command:

```bash
--tls-cert myhost.tailnet.ts.net.crt --tls-key myhost.pkcs8.key \
--announce-url https://myhost.tailnet.ts.net:32400,http://192.168.1.10:32400
```

The first address is the HTTPS one, the second your LAN address. HTTPS and plain HTTP share the port, so zurg keeps using `http://`.

Do not put a Cloudflare tunnel in front of rex. Cloudflare drops the range of the first read, so every play start pulls the whole file from your debrid service.

## 8. Keep it running

Copy the example script and fill in your name, mount, port, Plex username and email, and the announce addresses (or delete the `ANNOUNCE` lines):

```bash
cd ~/rex && cp examples/run.sh.example run.sh && chmod +x run.sh
```

Create `~/.config/systemd/user/rex.service`:

```ini
[Unit]
Description=rex
After=network-online.target

[Service]
WorkingDirectory=%h/rex
ExecStart=%h/rex/run.sh
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
loginctl enable-linger "$USER"
journalctl --user -u rex -f
```

On Windows use `rust\target\release\rex.exe` everywhere and start it from Task Scheduler ("At startup"). On macOS: `launchctl submit -l com.rex -o rex.log -e rex.err -- /bin/bash "$PWD/run.sh"`.

Back up `rex.db` with `sqlite3 ~/rex/rex.db ".backup rex.db.bak"`, together with `claim_state.json`. `rex.db` holds your watch state and zurg's login, so keep it private.

## Run rex in Docker

`ghcr.io/debridmediamanager/rex` carries the same Linux build as the release, for amd64 and arm64. Like zurg's sponsor image it is private, so log in once with your GitHub username and a classic personal access token with the `read:packages` and `repo` scopes:

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

Make a folder for it with this `compose.yml`:

```yaml
services:
  rex:
    image: ghcr.io/debridmediamanager/rex:latest
    container_name: rex
    restart: unless-stopped
    network_mode: host
    environment:
      TMDB_KEY: your_tmdb_api_key
    volumes:
      - ./config:/config
    command: >
      --friendly-name myrex --zurg-mount /zurg_mnt/zurg
      --owner-username <your Plex username> --owner-email <your Plex email>
```

- Everything rex keeps (`rex.db`, `claim_state.json`) lands in `./config`. Back up that folder.
- `network_mode: host` lets Plex apps on your network find rex on their own and lets rex reach zurg the same way it would without Docker.
- `--zurg-mount` is zurg's `mount_path`; `/zurg_mnt/zurg` is what zurg's Docker setup uses.
- Plex Media Server on the same machine? Add `--port 32500 --gdm off` to `command`.

zurg has `anime` or other directories? Name them before the first start (step 3):

```bash
docker compose run --rm rex catalog --seed --name myrex --out /config/rex.db \
  --movies movies --shows shows --shows anime
```

Start it and follow the log:

```bash
docker compose up -d
docker compose logs -f rex
```

The first start logs `seeded /config/rex.db`. Then carry on with [step 5](#5-point-zurg-at-rex): `rex_url` is `http://<this machine's LAN IP>:32400`. The claim in step 6 is the same `curl` on this machine. For step 7, put the certificate files in `./config` and add `--tls-cert /config/<name>.crt --tls-key /config/<name>.pkcs8.key --announce-url ...` to `command`.

To update:

```bash
docker compose pull && docker compose up -d
```

`latest` follows each release; pin a version such as `ghcr.io/debridmediamanager/rex:0.3.0` to update only when you choose. The image carries no FFmpeg, so [converting video](#converting-video-optional) stays off in it.

## Keep the port private

rex takes no password from zurg. Anyone who can reach rex's port can add to its library or remove what zurg sent. Never forward port 32400 (or 32500) on your router without the HTTPS setup in step 7.

## When something is wrong

| What you see | What to do |
|---|---|
| `/rex/sources` stays `{"size":0}` | zurg is older than 2026.10.15, `rex_url` is wrong, or zurg's library is still loading. Run `zurg update` and check zurg's log |
| Nothing plays, rex's log shows 502 | rex cannot reach the `url` zurg gave it. Run `curl` on that URL from the rex machine. In Docker, see step 5 |
| Nothing plays, 401 or 403 | zurg refused its own login. Restart zurg so it sends rex the current one |
| `rejected: no movie or show library holds ...` | zurg has a directory rex has no library for. See step 3, or add a library on that directory in Plex |
| The library stays empty | zurg has not read the media details yet. Press **Analyze & Tag Library** |
| rex exits with `unrecognized arguments` | Your start script still passes `--sources` or a feed token from an older setup. Remove them |
| rex is not in the Plex apps away from home | Not claimed, no `--announce-url`, or the HTTPS address is not reachable from the internet |
| The log says `waiting for a claim` | Claim it (step 6). It announces right away |

## Converting video (optional)

rex plays files in their original quality. To convert what a device cannot play, point `REX_TRANSCODER` at an FFmpeg. Use jellyfin-ffmpeg 8, not Ubuntu's FFmpeg 4.4. A graphics chip makes it fast; in an LXC that means passing the GPU through. rex's `docs/setup.md` has the details.
