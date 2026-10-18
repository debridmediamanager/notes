# rex with zurg

[rex](https://rex.debridmediamanager.com) is a Plex Media Server that owns no files. The official Plex apps see it as a normal Plex server. zurg sends it your debrid library, and when you press play rex streams the file straight from zurg. Nothing is downloaded first.

This page takes you from nothing to playing a movie, one step at a time. Every step says what it does, why it matters and what you should see before you move on. If what you see does not match, stop there: the next step will not fix it.

![zurg registers with rex and sends it the library; Plex apps play through rex, which reads each file from zurg](../assets/rex/how-it-fits.svg)

Four things to know before you start:

- **zurg is the part that talks to your debrid service.** It lists what is in your account and serves the files.
- **rex is the part your Plex apps talk to.** It keeps no files and needs no disk for media. It does not need rclone or a mount.
- **zurg tells rex about itself.** You give zurg one line, the address of rex, and zurg does the rest. You never type zurg's details into rex.
- **zurg and DMM decide what each file is; Plex describes it.** zurg asks DMM which movie or episode each file is, and rex shows that title with the posters and summaries Plex's own metadata gives it once rex is on your Plex account. rex never guesses from a file name.

rex opens as a closed beta for sponsors on October 15 and reaches the public on October 31. See [rex.debridmediamanager.com](https://rex.debridmediamanager.com) for access.

## Before you start

| You need | Why |
|---|---|
| A Linux machine that stays on (Ubuntu 22.04 or newer). A Proxmox LXC works, unprivileged is fine | rex and zurg are servers: your Plex apps reach them whenever you press play. macOS and Windows work too; this page shows Linux, and [Docker](#run-rex-in-docker) is further down |
| About 4 cores, 8 GB of RAM and a 64 GB disk for a library of 10,000 items | rex keeps the library in memory and uses the most while it fills for the first time. zurg needs little |
| A debrid account (Real-Debrid, TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud) or Usenet | That is where your movies and shows actually live |
| A GitHub account with access to zurg's and rex's sponsor releases | Both are private GitHub releases. The zurg installer signs you in once and rex's download reuses that sign-in |
| Your DMM API key, from sponsoring DMM | zurg asks DMM what each file is. Without it every file is unmatched: films are titled as their file and episodes are numbered in file order |
| A Plex account | rex gets every title, poster, summary and episode name from Plex once it is [added to your account](#step-4-add-it-to-your-plex-account). Until then titles keep their file names and have no posters |

You do **not** need a TMDB key, your Plex token or the machine's IP address.

## Step 1. Install zurg

**What it does.** Downloads zurg, asks for your debrid account and starts zurg as a service that comes back after a reboot.

**Why it matters.** Everything rex shows comes from zurg. If zurg cannot see your library, rex never will.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
loginctl enable-linger "$USER"
```

The installer asks which services you use (type `1` for Real-Debrid) and then for your API token. The token is hidden while you paste it. zurg goes into `~/zurg`. The second line keeps your services running when you log out.

**What you should see.** The installer ends with a list of `PASS` lines and `==> zurg is installed in /home/you/zurg`. zurg then loads your library: a few seconds for a small account, about ten minutes for one with a thousand releases. Open zurg's dashboard at `http://<this machine>:9999`: **Library size** counts your items once it is done.

Already run zurg? `zurg update` and restart it. You need nightly **2026.10.17 or later**.

## Step 2. Install rex

**What it does.** Downloads rex into `~/rex` and starts it as a service.

**Why it matters.** rex is what your Plex apps talk to. The first start creates `rex.db`, which holds your libraries, everything zurg sends and your watch history.

```bash
mkdir -p ~/rex && cd ~/rex
export PATH="$PATH:$HOME/zurg/bin"
gh release download "$(gh release list -R debridmediamanager/rex -L 1 --json tagName -q '.[0].tagName')" \
  -R debridmediamanager/rex -p '*-linux-amd64.tar.gz'
tar xzf rex-*-linux-amd64.tar.gz --strip-components=1 && rm rex-*-linux-amd64.tar.gz
```

This takes rex's newest build, a nightly until the next release. On an ARM machine (Raspberry Pi, Ampere) use `linux-arm64`.

Now make it a service. Create `~/.config/systemd/user/rex.service`:

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/rex.service
```

```ini
[Unit]
Description=rex
After=network-online.target

[Service]
WorkingDirectory=%h/rex
EnvironmentFile=-%h/rex/rex.env
ExecStart=%h/rex/rust/target/release/rex --catalog rex.db
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

**Plex Media Server runs on the same machine?** End the `ExecStart` line with `--port 32500 --gdm off` and use `32500` wherever this page says `32400`: Plex already holds port 32400 and the ports apps use to find servers.

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
journalctl --user -u rex -f
```

**What you should see.**

```
INFO    seeded rex.db: an empty library named yourhost at /mnt/zurg, machine=...
INFO    no source yet: one registers at PUT /rex/sources/{name} (docs/feed-api.md)
INFO    claim state: unclaimed
INFO    rex on http://yourhost:32400  machine=...  items=0  parts=proxy
```

rex names itself after the machine; your Plex apps show that name. `no source yet` is right: zurg has not been told about rex. Leave the log open.

## Step 3. Connect zurg to rex

**What it does.** Tells zurg where rex is. zurg introduces itself to rex, sends its whole library, reads each file's video and audio details and sends those too, then every change as it happens.

**Why it matters.** This is the only link between the two. rex has no setting for zurg: if `rex_url` is missing, rex stays empty. Your DMM key is what tells rex which movie or episode each file is.

```bash
printf 'rex_url: http://127.0.0.1:32400\ndmm_api_key: your_dmm_key\n' >> ~/zurg/config.yml
systemctl --user restart zurg
```

**What you should see.** Once zurg has loaded the library again, zurg's log says `DMM placed N releases for rex` and rex's log prints:

```
INFO    SOURCES PUT /rex/sources/zurg -> 200
INFO    FEED zurg upsert: 0 created, 0 updated, 200 held, 0 unchanged, 0 rejected
INFO    FEED identified "Sintel.mp4" -> movie tmdb:45745 (placed)
INFO    FEED zurg upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

`held` means zurg has not read that file's details yet. zurg starts reading them as soon as its library has loaded, about 400 files a minute, and each title appears in rex as its details arrive. Anything you add to your debrid account later shows up by itself, usually within half a minute.

**If not.**

- Nothing at all in rex's log: zurg is older than 2026.10.17 (`zurg update`), or `rex_url` has a typo. `journalctl --user -u zurg -n 50` shows zurg's side.
- A title stays `held` and zurg logs `Cannot probe file ...`: the first read from the debrid service failed. zurg tries again by itself; **Analyze & Tag Library** under **Utilities** on zurg's dashboard tries at once.
- Titles arrive but no `identified` lines: `dmm_api_key` is missing, or zurg logs `DMM refused the API key for placement`, which means the key is not a sponsor's. Those titles stay unmatched until zurg can place them.

Two rules for this line:

- `127.0.0.1` is right when zurg and rex are on the same machine. Otherwise use rex's LAN IP, not a Tailscale address.
- Leave `plex_server_url` in zurg's config pointing at your real Plex, or empty. Pointed at rex, zurg learns rex's own matches and a wrong match could never be fixed.

Running several zurgs (one per debrid service)? Give each its own name with an extra line, `rex_source: rd`, `rex_source: tb` and so on. They fill the same two libraries.

### Why DMM places the files

File names often number episodes differently from the episode lists Plex apps show. DMM knows where each file really belongs:

| Release | Named | Where it really is |
|---|---|---|
| `[SubsPlease] Hibike Euphonium 3 - 01` | season 1, episode 1 | Sound! Euphonium season 3, episode 1 |
| `[HorribleSubs] One Piece - 486` | episode 486 | season 13, episode 486 |
| `Fairy.Tail.E236` | episode 236 | season 6, episode 10 |
| `Firefly.S01E02.The.Train.Job` (DVD order) | episode 2 | episode 1, "The Train Job" |

A file DMM cannot place yet stays unmatched: a film titled as its file, or an episode in a show named after its release, numbered in file order. zurg asks DMM about it again a day later, and you can fix it yourself with **Fix Match** in a Plex app. A title you corrected with Fix Match stays as you set it.

## Step 4. Add it to your Plex account

**What it does.** Registers rex on your Plex account, as you would a real Plex Media Server.

**Why it matters.** rex gets every title's name, poster, summary and episode names from Plex's own metadata, and it may only ask Plex once it is on your account. Until then your library shows file names and no posters, and Fix Match has nothing to offer. It also removes the "unclaimed" notice and is needed before [using rex outside your home](#use-it-outside-your-home-optional).

**At your own risk.** rex is not made by Plex, and Plex could take action against an account that registers it. If you skip this, rex still plays on your home network, with file names instead of posters.

1. Open [plex.tv/claim](https://www.plex.tv/claim) and copy the code. It expires in four minutes.
2. On the rex machine:

   ```bash
   curl -X POST "http://127.0.0.1:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://127.0.0.1:32400/identity
   ```

**What you should see.** The second command shows `claimed="1"`, and `~/rex/claim_state.json` exists. Posters and titles fill in without a restart. Back that file up and never claim the same server twice: if you lose it, you have to claim again.

## Step 5. Watch something

**What it does.** Opens rex in a Plex app, the same way you would open any Plex server.

**Why it matters.** This is the point of the whole setup. It also proves the last link: rex reading a file from zurg while you watch.

Open a Plex app on a phone, TV or computer **on the same home network**. rex shows up on its own under the machine's name, with **Debrid Movies** and **Debrid TV**. Pick a movie and press play.

At home nothing else is needed: Plex apps find rex with Plex's own local discovery and connect to it over your network, never through the internet. That discovery needs the device on the same network as rex (not a guest Wi-Fi or a separate VLAN) and rex on port 32400. If you moved rex to 32500 because Plex runs on the same machine, discovery is off, and apps find rex only after you [add it to your Plex account](#step-4-add-it-to-your-plex-account).

![rex's Debrid Movies library in Plex](../assets/rex/rex-movies.webp)

**What you should see.** Posters, titles and years as on any Plex server. Playback starts within a few seconds.

Two things you may meet:

- **"yourhost server is unclaimed and not secure".** A Plex app says this about any server that is not on a Plex account. Do [step 4](#step-4-add-it-to-your-plex-account), or press **Don't show this again**.
- **"This server is not powerful enough to convert video".** The app cannot play the file as it is, often a web browser meeting AC3 or DTS sound. Plex apps on TVs and phones play most files as they are. To play everything everywhere, set up [Converting video](#converting-video-optional).

![The unclaimed-server notice in Plex](../assets/rex/rex-unclaimed.webp)

zurg's folders other than `movies` and `shows`, such as `anime`, need nothing: each file goes to **Debrid Movies** or **Debrid TV** by what zurg says it is.

**Back up** `~/rex/rex.db` (it holds your library, watch history and zurg's login, so keep it private) and, once you have one, `claim_state.json`:

```bash
sudo apt install -y sqlite3    # once
sqlite3 ~/rex/rex.db ".backup $HOME/rex/rex.db.bak"
```

You are done. The sections below are optional.

## Use it outside your home (optional)

**What it does.** Gives rex an HTTPS address that Plex apps away from home can reach, and tells plex.tv about it.

**Why it matters.** Away from home, Plex apps only connect to an HTTPS address they can reach. A real Plex server can fall back to Plex's relay; rex cannot, so you choose how it is reached. rex must be [claimed](#step-4-add-it-to-your-plex-account) first. A claimed rex checks the Plex token on every request, so it works behind any of the HTTPS proxies below.

Whichever you pick, every byte you watch away from home leaves through your home connection's **upload** speed. A 20 Mbit/s upload carries one 1080p WEB-DL comfortably, not a remux.

### Which one to use

| Your situation | Use | Why |
|---|---|---|
| You can install Tailscale on the devices you watch on | **[Tailscale serve](#tailscale-serve)** (best) | Nothing to open on your router, and it works behind any internet connection. The certificate renews by itself, and nobody outside your tailnet can reach rex |
| Devices without Tailscale (a friend's TV, a hotel), and your router has a public IP | **[Caddy](#caddy)** with your own domain, or with a free `sslip.io` name | A direct connection with nobody in between, and a free certificate that renews by itself. You forward port 443 |
| Your connection has no public IP (CGNAT, common on mobile and some fibre providers) and Tailscale on every device is not an option | Nothing works well yet | rex has no relay. Tailscale serve is the way out |

Not recommended:

- **Cloudflare tunnel.** Every byte goes through Cloudflare, which also drops the `Range` of a file's first read, so every play start pulls the whole file from your debrid service.
- **Tailscale Funnel.** It puts every byte through Tailscale's servers, with limited bandwidth, and it publishes all of rex, including the API zurg pushes your library to. Anyone on the internet could add to or delete from that library.
- **Forwarding port 32400 on your router.** rex speaks HTTPS there only with a certificate for a name you own, and it publishes the same API to the internet. See [Keep the port private](#keep-the-port-private).

### Tailscale serve

Install [Tailscale](https://tailscale.com/download) on the rex machine and on the devices you watch on, signed in to the same account. Then on the rex machine:

```bash
sudo tailscale serve --bg 32400
```

It prints the address, for example `https://myhost.tailnet.ts.net`. Add it, and the machine's LAN address (`hostname -I` shows the IP), to the end of the `ExecStart` line in `rex.service`:

```ini
ExecStart=%h/rex/rust/target/release/rex --catalog rex.db --announce-url https://myhost.tailnet.ts.net,http://192.168.1.20:32400
```

**Keep the LAN address in the list.** Once rex announces, Plex apps take its addresses from plex.tv, and plex.tv lists only what rex announces. Without the LAN address a TV at home that has no Tailscale is sent only to the tailnet address and cannot connect.

```bash
systemctl --user daemon-reload && systemctl --user restart rex
```

Tailscale connects your devices to each other directly, so the stream does not pass through Tailscale's servers except on networks that block that. In Docker, run the same `tailscale serve` on the machine and put `--announce-url ...` in the compose file's `command:`.

### Caddy

You need port 443 on your router forwarded to the rex machine, and a name for your home's IP address:

- **Your own domain:** an `A` record such as `rex.example.com` pointing at your home IP.
- **No domain:** use `1-2-3-4.sslip.io` with your public IP's numbers (`curl -s ifconfig.me` shows it). It always resolves to that IP. If your IP changes, update the name.

Install [Caddy](https://caddyserver.com/docs/install) and make `/etc/caddy/Caddyfile`:

```
rex.example.com {
	respond /rex/* 403
	reverse_proxy 127.0.0.1:32400
}
```

`respond /rex/* 403` keeps the API zurg pushes to off the internet. zurg still reaches it at `http://127.0.0.1:32400`. Then:

```bash
sudo systemctl reload caddy
```

Caddy fetches a certificate on the first request and renews it by itself. Add `--announce-url https://rex.example.com,http://192.168.1.20:32400` to `ExecStart` as above, with your LAN IP, and restart rex.

### What you should see

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://myhost.tailnet.ts.net/identity
```

answers `200`, and rex's log names the address:

```
INFO    heartbeat every 600s for machine ... -> https://myhost.tailnet.ts.net
```

The server then lists that address on plex.tv, and a Plex app away from home picks it. If rex logs `waiting for a claim`, do the previous section first.

## Converting video (optional)

**What it does.** Lets rex convert what a device cannot play, the way Plex does.

**Why it matters.** Without it a device that cannot play a file as it is gets "This server is not powerful enough to convert video". Web browsers hit this most, for example with AC3 or DTS sound.

Install jellyfin-ffmpeg 8 as a package (Ubuntu's own FFmpeg 4.4 is too old; it goes in `/usr/lib/jellyfin-ffmpeg` beside it) and point rex at it:

```bash
curl -LO https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg8_8.1.3-1-jammy_amd64.deb
sudo apt install -y ./jellyfin-ffmpeg8_8.1.3-1-jammy_amd64.deb && rm jellyfin-ffmpeg8_8.1.3-1-jammy_amd64.deb
printf 'REX_TRANSCODER=/usr/lib/jellyfin-ffmpeg/ffmpeg\nLIBVA_DRIVER_NAME=iHD\n' >> ~/rex/rex.env && chmod 600 ~/rex/rex.env
systemctl --user restart rex
```

With an Intel or AMD graphics chip, also run `sudo usermod -aG render "$USER"` and reboot so the service gets the group; in an LXC, pass the GPU through. The chip makes conversion fast; without one rex uses the processor. On Intel, `sudo apt install intel-opencl-icd` also converts HDR and Dolby Vision on the chip.

**What you should see.** rex's log has a `transcoder:` line naming the FFmpeg and the hardware it found (`hardware none` means the processor). A file that failed before now plays; the log shows what was converted, for example `video=copy h264 audio=ac3->aac`.

## Run rex in Docker

The same setup with zurg and rex in containers on one Linux machine. The steps match the ones above; only how you start each part differs.

### D1. Install zurg in Docker

**What it does.** Runs zurg in a container whose mount shows up on the machine at `/zurg_mnt/zurg`.

**Why it matters.** As in step 1, everything rex shows comes from zurg.

Follow [zurg's Docker setup](../setup/docker.md). The one-line installer there does it all, and may first ask you to approve the `read:packages` and `repo` scopes for your GitHub sign-in with a one-time code in your browser. The manual steps on the same page do the same thing by hand.

**What you should see.** `docker compose exec zurg /app/zurg doctor --working-dir /config` ends in `PASS` lines (`WARN service zurg is not installed` is expected: Docker restarts zurg, not systemd), and

```bash
ls /zurg_mnt/zurg/movies /zurg_mnt/zurg/shows
```

lists your library.

### D2. Start rex in Docker

**What it does.** Runs rex from its image, keeping everything it saves in a folder beside the compose file.

**Why it matters.** It is [step 2](#step-2-install-rex) in one file: the image is the program and Docker keeps it running.

rex's image is private, like zurg's. Log in once with your GitHub username and a classic personal access token with the `read:packages` and `repo` scopes (the same login zurg's image uses):

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

Make a folder, for example `~/rex`, with this `compose.yml`:

```yaml
services:
  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./config:/config
```

- `network_mode: host` lets Plex apps on your network find rex by themselves, and lets rex reach zurg's container.
- `:nightly` is the newest build until the next release; `latest` follows releases only.
- `./config` gets `rex.db` and, later, `claim_state.json`. They are readable by root only, because `rex.db` holds zurg's login.
- Plex Media Server on the same machine? Add `command: --port 32500 --gdm off`.

```bash
docker compose up -d
docker compose logs -f rex
```

**What you should see.** The same lines as [step 2](#step-2-install-rex), with `seeded /config/rex.db` and `no source yet`. Leave the log open.

### D3. Connect zurg to rex

**What it does.** Same as [step 3](#step-3-connect-zurg-to-rex). zurg's config sits in zurg's compose folder and belongs to root, so:

```bash
cd ~/zurg
printf 'rex_url: http://192.168.1.20:32400\ndmm_api_key: your_dmm_key\n' | sudo tee -a config.yml
docker compose restart zurg
```

**What you should see.** `SOURCES PUT /rex/sources/zurg -> 200` in rex's log, and `curl -s http://127.0.0.1:32400/rex/sources` shows zurg at its **container** address, for example `http://192.168.32.2:9999/dav`. That is right: rex runs on the same machine and reaches the container there.

**zurg and rex on different machines?** rex cannot reach that container address. Give the zurg container `network_mode: host` (and remove its `ports:` lines) so it registers the machine's LAN IP instead.

### D4. Watch

rex's log names each title as zurg reads it, as in [step 3](#step-3-connect-zurg-to-rex). Claim it as in [step 4](#step-4-add-it-to-your-plex-account), with the same `curl` on this machine, then open a Plex app on your network as in [step 5](#step-5-watch-something).

**What you should see.** The titles appear in **Debrid Movies** and **Debrid TV**, and `docker compose restart rex` brings them back with `state file /config/rex.db: restored` and `source zurg: registered`.

### D5. Update

```bash
cd ~/rex && docker compose pull && docker compose up -d
```

rex comes back with the same library. `nightly` moves every night and `latest` with each release; pin a version to update only when you choose. For zurg, see [Managing and updating zurg](../setup/docker.md#managing-and-updating-zurg).

The image carries no FFmpeg, so [converting video](#converting-video-optional) needs the install without Docker. HTTPS works as above: the options run on the machine itself, and `--announce-url ...` goes in `command`.

## Keep the port private

rex takes no password from zurg. Anyone who can reach rex's port can add to its library or remove what zurg sent. Never forward port 32400 (or 32500) on your router, and keep `/rex/*` blocked in any proxy that faces the internet, as the [Caddy](#caddy) example does.

## Updating

- **zurg:** `zurg update`, then `systemctl --user restart zurg`.
- **rex:** run the `gh release download` and `tar` lines of [step 2](#step-2-install-rex) again in `~/rex` (they replace the program and `data/`, and leave `rex.db`, `rex.env` and `claim_state.json` alone), then `systemctl --user restart rex`.
- **Coming from an older rex?** `TMDB_KEY`, `REX_METADATA_URL` and `REX_METADATA_KEY` are no longer read; delete them from `rex.env` or leave them, rex starts either way. Add `dmm_api_key` to zurg and claim rex, or titles lose their posters and matches.

## When something is wrong

| What you see | What to do |
|---|---|
| `/rex/sources` stays `{"size":0}` | zurg is older than 2026.10.17, `rex_url` is wrong, or zurg's library is still loading. Run `zurg update` and look at `journalctl --user -u zurg -n 50` |
| rex's log says `held ... no media_info yet` and the library stays empty | zurg has not read the files yet. Wait for its library to load; if zurg logs `segmentation fault`, run `zurg update` and restart it |
| Titles show file names and no posters | rex is not on your Plex account. Do [step 4](#step-4-add-it-to-your-plex-account) |
| A title is in the wrong show, or a film is titled as its file | DMM has not placed it: check `dmm_api_key` in zurg's config. zurg asks again a day later; **Fix Match** in a Plex app fixes it now |
| Nothing plays and rex's log shows 502 | rex cannot reach the address zurg gave it. Run `curl` on that URL from the rex machine. In Docker, see the Docker section |
| Nothing plays, 401 or 403 | zurg refused its own login. Restart zurg so it sends rex the current one |
| "This server is not powerful enough to convert video" | The device cannot play the file as it is. Try a Plex app on a TV or phone, or set up [Converting video](#converting-video-optional) |
| rex exits with `unrecognized arguments` | Your `rex.service` or `run.sh` still passes `--sources` or a feed token from an older setup. Remove them |
| After adding `--announce-url`, a device at home cannot connect | The LAN address is missing from `--announce-url`. Add `http://<LAN IP>:32400` after the HTTPS one |
| rex is not in the Plex apps away from home | Not claimed, no `--announce-url`, or the device cannot reach the HTTPS address (a tailnet-only address needs Tailscale on that device) |
| The log says `waiting for a claim` | Claim it. It announces right away |
| zurg stops when you log out | Run `loginctl enable-linger "$USER"` (step 1) |
| zurg will not start after you edited `config.yml` | A zurg older than 2026.10.17 wrote the file without a final newline, so the added line joined the last one. Put it on its own line |
