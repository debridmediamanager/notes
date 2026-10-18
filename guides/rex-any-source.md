# rex with your own app

[rex](https://rex.debridmediamanager.com) is a Plex Media Server that owns no files. The official Plex apps see it as a normal Plex server. Another program, which this page calls **your app**, tells rex what is in your library and serves the files. When you press play, rex streams the file straight from your app. Nothing is downloaded first.

This page takes you from nothing to playing a movie, one step at a time. It does not assume any particular app. It says exactly what rex expects from one, so you can check that yours does it, or build one. Every step says what it does, why it matters and what you should see before you move on.

Four things to know before you start:

- **Your app serves the files.** rex fetches every byte from your app over plain HTTP, the way a browser downloads a file. rex keeps no files and needs no disk or mount for media.
- **Your app tells rex what it has.** It sends rex a list of files over rex's feed API, and every change after that. rex never lists a folder or scans anything.
- **Your app decides what each file is.** It says whether a file is a movie or an episode, which title it belongs to (by IMDb and TMDB id) and, for an episode, its season and number. rex never guesses from a file name.
- **Plex describes it.** Once rex is on a Plex account, it shows each title with the name, poster, summary and episode names Plex's own metadata has for those ids.

rex has been in closed beta for sponsors since October 15 and reaches the public on October 31. See [rex.debridmediamanager.com](https://rex.debridmediamanager.com) for access.

## Before you start

| You need | Why |
|---|---|
| A Linux machine that stays on (Ubuntu 22.04 or newer) | rex is a server: your Plex apps reach it whenever you press play. macOS and Windows work too; this page shows Linux, and [Docker](#run-rex-in-docker) is further down |
| About 500 MB of RAM for a library of 40,000 titles | rex keeps the library in `rex.db` and holds only what it is serving in memory. Converting video wants more cores, or a graphics chip |
| A GitHub account with access to rex's sponsor releases | rex is a private GitHub release |
| An app that does what [What your app must do](#what-your-app-must-do) lists | That is where your library comes from |
| A fresh Plex account, made just for rex | rex gets every title, poster, summary and episode name from Plex once it is [added to a Plex account](#step-3-add-it-to-a-plex-account). Until then titles keep their file names and have no posters |

You do **not** need a TMDB key or your Plex token.

## What your app must do

Give this list to whoever makes your app. rex's own API reference is `docs/feed-api.md` in every rex download.

| Your app must | How | If it does not |
|---|---|---|
| Serve each file over HTTP | `GET <address>/<path>` answers the file. `Range` requests make seeking fast; redirects are followed. Basic auth or a bearer token is allowed | Nothing plays: rex logs 502 |
| Register with rex | `PUT /rex/sources/<name>` (letters, digits, `-` and `_`) with `{"url": ...}` and, if it has a login, `"user"` and `"password"` or `"bearer"`, never inside the url. Again whenever it starts | rex has nowhere to read from |
| Send every file it has | `POST /rex/feed/<name>/items`, a few hundred files a request, with each file's `size` in bytes, which rex uses to answer seeks | rex stays empty |
| Send each file's ffprobe output | ffprobe's `-show_format -show_streams` JSON, whole, as `media_info` | The file is **held**: stored but not shown, because Plex apps refuse to play a file without it |
| Say what each file is | `kind` (`movie`, `episode` or `extra`) and `ids`: the movie's or the **show's** `imdb` and `tmdb`, never an episode's. For an episode, `season` and `episode` on the item itself (beside `kind`, not inside `ids`), as TMDB numbers them; `episode_end` for a file holding several episodes | The file is unmatched: a film titled as its file, an episode in a show named after its release, numbered in file order |
| Keep the same `id` for a file forever | Even when it renames it | A renamed file becomes a new title and loses its watch history |
| Send changes as they happen | The same `POST` for new or changed files, `DELETE /rex/feed/<name>/items` for removed ones | The library goes stale |
| Send the whole library now and then | `PUT /rex/feed/<name>/snapshot`. rex removes whatever the snapshot does not name | Files your app lost track of stay in rex |
| Accept a WebDAV `DELETE` of a file | When someone deletes a title in a Plex app, rex asks your app to delete the file first | The title stays and the Plex app says it could not be deleted |

## Step 1. Install rex

**What it does.** Downloads rex into `~/rex` and starts it as a service that comes back after a reboot.

**Why it matters.** rex is what your Plex apps talk to. The first start creates `rex.db`, which holds your libraries, everything your app sends and your watch history.

rex's download uses the GitHub CLI. Install it (`sudo apt install -y gh`) and sign in once with `gh auth login`. Then:

```bash
mkdir -p ~/rex && cd ~/rex
TAG=$(gh api 'repos/debridmediamanager/rex/releases?per_page=1' --jq '.[0].tag_name')
gh release download "$TAG" -R debridmediamanager/rex -p '*-linux-amd64.tar.gz'
tar xzf rex-*-linux-amd64.tar.gz --strip-components=1 && rm rex-*-linux-amd64.tar.gz
sudo loginctl enable-linger "$USER"
```

This takes rex's newest build, a nightly until the next release. On an ARM machine (Raspberry Pi, Ampere) use `linux-arm64` in all three places. The last line keeps rex running when you log out.

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
UMask=0077

[Install]
WantedBy=default.target
```

`UMask=0077` makes the files rex writes readable by you only: `rex.db` will hold your app's login.

**Plex Media Server runs on the same machine?** End the `ExecStart` line with `--port 32500` and use `32500` wherever this page says `32400`: Plex already holds port 32400 and the ports apps use to find servers, and on any other port rex leaves those to Plex.

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
journalctl --user -u rex -f
```

**What you should see.**

```
INFO    no source yet: one registers at PUT /rex/sources/{name} (docs/feed-api.md)
INFO    claim state: unclaimed
INFO    rex on http://yourhost:32400  machine=...  items=0  parts=proxy
```

rex names itself after the machine; your Plex apps show that name. `no source yet` is right: no app has registered yet. Leave the log open.

## Step 2. See it work by hand

**What it does.** Plays the part of your app for one movie, with a throwaway file server and two `curl` commands.

**Why it matters.** It proves rex works on this machine before your app is involved. If this step works and your app does not, the problem is in your app. Skip it if your app is already set up.

You need `ffprobe`, `jq` and one video file. Put the file where a small web server can serve it:

```bash
sudo apt install -y ffmpeg jq
mkdir -p ~/rex-test/movies/Sintel.2010
cp /path/to/any-video.mkv ~/rex-test/movies/Sintel.2010/Sintel.2010.mkv
cd ~/rex-test
python3 -m http.server 8099 --bind 127.0.0.1 &
```

Register it with rex, under the name `test`:

```bash
curl -s -X PUT http://127.0.0.1:32400/rex/sources/test \
  -H 'Content-Type: application/json' -d '{"url": "http://127.0.0.1:8099"}'
```

Send rex the file. It says the file is the movie Sintel (IMDb `tt1727587`, TMDB `45745`) and carries ffprobe's output:

```bash
P=movies/Sintel.2010/Sintel.2010.mkv
jq -n --arg p "$P" --argjson size "$(stat -c%s "$P")" \
  --argjson probe "$(ffprobe -v quiet -print_format json -show_format -show_streams "$P")" \
  '{items: [{id: $p, path: $p, name: "Sintel.2010", size: $size,
             kind: "movie", ids: {imdb: "tt1727587", tmdb: 45745}, media_info: $probe}]}' \
| curl -s -X POST http://127.0.0.1:32400/rex/feed/test/items \
    -H 'Content-Type: application/json' --data-binary @-
```

**What you should see.** The answer is `{"created":1,"updated":0,"held":0,"unchanged":0}` and rex's log prints:

```
INFO    FEED identified "Sintel.2010" -> movie tmdb:45745 (placed)
INFO    FEED test upsert: 1 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

`placed` means rex took the title from what was sent, not from the file name. Sintel is now in **Debrid Movies**, playing from the little web server. Until [step 3](#step-3-add-it-to-a-plex-account) it shows as `Sintel.2010` with no poster.

**Clean up** before you go on: removing the test source removes everything it sent. The first request answers a `confirm` path; send a `DELETE` to that path within five minutes.

```bash
curl -s -X DELETE http://127.0.0.1:32400/rex/sources/test
curl -s -X DELETE "http://127.0.0.1:32400/rex/sources/test/confirm/<code from the answer>"
kill %1
```

**If not.**

- `"held":1`: `media_info` is missing or has no streams. Check that `ffprobe` printed JSON for the file.
- An answer with `rejected`: the file is not a video by its extension, is a sample, or has no `id` or `path`. rex's log names each and why.
- `404 no such source`: the `PUT /rex/sources/test` did not happen first.

## Step 3. Add it to a Plex account

**What it does.** Registers rex on a Plex account, as you would a real Plex Media Server, and shares it with your own account.

**Why it matters.** rex gets every title's name, poster, summary and episode names from Plex's own metadata, and it may only ask Plex once it is on an account. Do this before you connect your app, so every title arrives with its name and poster. What your app sends before the claim keeps its file name until rex names it in the background, about 300 titles an hour, and Fix Match has nothing to offer until then. It also removes the "unclaimed" notice and is needed before [using rex outside your home](#use-it-outside-your-home-optional).

**Use a fresh Plex account for this, not your own.** rex is not made by Plex, and Plex could take action against an account that registers it. Keep your real account, with its watch history, friends and any Plex Pass, out of reach: make a new free account at [plex.tv](https://www.plex.tv) with an email address you do not use elsewhere, register rex on that one, and share rex with your own account. You then watch signed in as yourself, the way you would watch a friend's server. If you skip this step entirely, rex still plays on your home network, with file names instead of posters, and anyone on your home network can browse it and play from it.

### Register rex on the fresh account

1. Sign in to [plex.tv](https://www.plex.tv) **as the fresh account**, open [plex.tv/claim](https://www.plex.tv/claim) and copy the code. It expires in four minutes.
2. On the rex machine:

   ```bash
   curl -X POST "http://127.0.0.1:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://127.0.0.1:32400/identity
   ```

**What you should see.** The second command shows `claimed="1"`, and `~/rex/claim_state.json` exists. Back that file up: without it rex has to be claimed again, and rex refuses a second claim while the file is there. From now on titles arrive with their names and posters, without a restart.

**If not.**

- The first command answers `409 Conflict` and rex logs `already claimed`: rex is on a Plex account already.
- It answers `500 Internal Server Error` and rex logs `claim exchange failed`: the code expired or was used. Get a new one from [plex.tv/claim](https://www.plex.tv/claim).

### Share it with your own account

1. Still signed in as the fresh account, open [app.plex.tv](https://app.plex.tv), then **Settings** (the wrench), **Manage Library Access** and **Grant Library Access**.
2. Enter your own account's username or email, pick the rex server and both libraries, **Debrid Movies** and **Debrid TV**, and send the invite.
3. Sign out, sign in as **yourself**, and accept the invite. It arrives by email and in app.plex.tv.
4. Tell plex.tv rex's LAN address, so Plex apps signed in as you know where to reach it. `hostname -I` shows the machine's IPs; use the one on your home network (usually `192.168.x.x` or `10.x.x.x`). Add it to the end of the `ExecStart` line in `rex.service` (in Docker, as `command: --announce-url http://192.168.1.20:32400`):

   ```ini
   ExecStart=%h/rex/rust/target/release/rex --catalog rex.db --announce-url http://192.168.1.20:32400
   ```

   ```bash
   systemctl --user daemon-reload && systemctl --user restart rex
   ```

   rex then logs a warning that a CDN may strip `Range`; it does not apply to a LAN address, Tailscale or Caddy.

**What you should see.** Signed in as yourself, Plex apps list the rex server beside your own servers, with both libraries. Your watch history on rex is your own: it is kept apart from the fresh account's. Share it the same way with anyone else in your household.

## Step 4. Connect your app

**What it does.** Points your app at rex. Your app registers, sends its whole library and then every change as it happens.

**Why it matters.** This is the only link between the two. rex has no setting for your app: your app finds rex, not the other way round.

Give your app rex's address: `http://127.0.0.1:32400` when both run on this machine, otherwise `http://<rex's LAN IP>:32400`. How you enter it depends on your app.

**What you should see.** rex's log prints, under the name your app registered as:

```
INFO    SOURCES PUT /rex/sources/myapp -> 200
INFO    FEED myapp upsert: 0 created, 0 updated, 200 held, 0 unchanged, 0 rejected
INFO    FEED identified "Some.Movie.2019.1080p" -> movie tmdb:12345 (placed)
INFO    FEED myapp upsert: 180 created, 0 updated, 20 held, 0 unchanged, 0 rejected
```

`held` files are waiting for their ffprobe output and appear as soon as your app sends it. Check what rex has from your app at any time:

```bash
curl -s http://127.0.0.1:32400/rex/sources                # the apps that registered, and their addresses
curl -s http://127.0.0.1:32400/rex/feed/myapp/items | head -c 600   # what is shown
curl -s http://127.0.0.1:32400/rex/feed/myapp/held  | head -c 600   # what waits for ffprobe output
```

**If not.**

- Nothing at all in rex's log: your app never reached rex. Check the address you gave it, and that rex's port is open between the two machines.
- Files arrive but no `identified` lines: your app sends no `kind` and `ids` (held files and unchanged re-sends print none either). Those titles stay unmatched until it does; you can still fix one by hand with **Fix Match** in a Plex app signed in as the fresh account. Your own account, which rex is shared with, is refused.
- `/rex/sources` shows an address rex cannot reach, such as a container's own address: your app has to register an address that works from the rex machine. Test it with `curl` from there.

## Step 5. Watch something

**What it does.** Opens rex in a Plex app, the same way you would open any Plex server.

**Why it matters.** This is the point of the whole setup. It also proves the last link: rex reading a file from your app while you watch.

Open a Plex app on a phone, TV or computer **on the same home network**. rex shows up under the machine's name, with **Debrid Movies** and **Debrid TV**. Pick a movie and press play.

At home nothing else is needed: Plex apps find rex with Plex's own local discovery and connect to it over your network. That needs the device on the same network as rex (not a guest Wi-Fi or a separate VLAN) and rex on port 32400. If you moved rex to 32500, apps find it only through the Plex account it is [shared with](#share-it-with-your-own-account). app.plex.tv in a web browser is the exception: it needs the HTTPS address from [Use it outside your home](#use-it-outside-your-home-optional), even at home.

**What you should see.** Posters, titles and years as on any Plex server. Playback starts within a few seconds.

Two things you may meet:

- **"yourhost server is unclaimed and not secure".** A Plex app says this about any server that is not on a Plex account. Do [step 3](#step-3-add-it-to-a-plex-account).
- **"This server is not powerful enough to convert video".** The app cannot play the file as it is, often a web browser meeting AC3 or DTS sound. Plex apps on TVs and phones play most files as they are. To play everything everywhere, set up [Converting video](#converting-video-optional).

Each file goes to **Debrid Movies** or **Debrid TV** by the `kind` your app sent. A file without one goes by its first folder: `shows` to Debrid TV, anything else to Debrid Movies.

**Back up** `~/rex/rex.db` (it holds your library, watch history and your app's login, so keep it private) and `claim_state.json`:

```bash
sudo apt install -y sqlite3    # once
sqlite3 ~/rex/rex.db ".backup $HOME/rex/rex.db.bak"
```

In Docker the files sit in `~/rex/config`, readable by root only. Back up from inside the container: `docker exec rex sqlite3 /config/rex.db ".backup /config/rex.db.bak"`.

You are done. The sections below are optional.

## Use it outside your home (optional)

**What it does.** Gives rex an HTTPS address that Plex apps away from home can reach, and tells plex.tv about it.

**Why it matters.** Away from home, app.plex.tv only connects to an HTTPS address, and the other Plex apps prefer one. A real Plex server can fall back to Plex's relay; rex cannot, so you choose how it is reached. rex must be [claimed](#step-3-add-it-to-a-plex-account) first. A claimed rex checks the Plex token on every request except `/identity` and its feed API (`/rex/...`), which is why a proxy that faces the internet must block `/rex/`.

**Plex Pass.** Away from home, Plex apps play only when the account you watch with has Plex Pass or a Remote Watch Pass, so you need one on your own account, not the fresh one. Plex checks this in the app, before rex sees any request. That is how Plex Web behaves; other Plex apps were not tested. At home, over the LAN address, Plex's rules ask for no pass. app.plex.tv in a browser uses the HTTPS address even at home, so it may ask for a pass there too.

Whichever you pick, every byte you watch away from home leaves through your home connection's **upload** speed. As a rough guide, a 20 Mbit/s upload carries one 1080p WEB-DL, not a remux.

| Your situation | Use | Why |
|---|---|---|
| You can install Tailscale on the devices you watch on | **[Tailscale serve](#tailscale-serve)** (best) | Nothing to open on your router, and it works behind any internet connection. The certificate renews by itself, and nobody outside your tailnet can reach rex |
| Devices without Tailscale (a friend's TV, a hotel), and your router has a public IP | **[Caddy](#caddy)** with your own domain, or with a free `sslip.io` name | A direct connection with nobody in between, and a free certificate that renews by itself. You forward port 443 |
| Your connection has no public IP (CGNAT) | **[Tailscale serve](#tailscale-serve)**, with Tailscale on every device you watch on | rex has no relay, and the tunnels below are not recommended |

Not recommended:

- **Cloudflare tunnel.** Every byte goes through Cloudflare, which also drops the `Range` of a file's first read, so every play start pulls the whole file from your app.
- **Tailscale Funnel.** It puts every byte through Tailscale's servers, with limited bandwidth, and it publishes all of rex, including the feed API. Anyone on the internet could add to or delete from your library.
- **Forwarding port 32400 on your router.** It publishes the same API to the internet. See [Keep the port private](#keep-the-port-private).

### Tailscale serve

Install [Tailscale](https://tailscale.com/download) on the rex machine and on the devices you watch on, signed in to the same account. Then on the rex machine:

```bash
sudo tailscale serve --bg 32400
```

It prints the address, for example `https://myhost.tailnet.ts.net`. Put it first in the `--announce-url` list from [step 3](#share-it-with-your-own-account), with `:443` added, before the LAN address:

```ini
ExecStart=%h/rex/rust/target/release/rex --catalog rex.db --announce-url https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

**Keep the LAN address in the list.** Once rex announces, Plex apps take its addresses from plex.tv, and plex.tv lists only what rex announces. Without the LAN address a TV at home that has no Tailscale cannot connect.

```bash
systemctl --user daemon-reload && systemctl --user restart rex
```

Everyone on your tailnet, including anyone you share this machine with, can use rex's feed API. Share the machine only with people you trust.

### Caddy

You need port 443 on your router forwarded to the rex machine, and a name for your home's IP address:

- **Your own domain:** an `A` record such as `rex.example.com` pointing at your home IP.
- **No domain:** use `1-2-3-4.sslip.io` with your public IP's numbers (`curl -s ifconfig.me` shows it). If your IP changes, update the name.

Install [Caddy](https://caddyserver.com/docs/install) and make `/etc/caddy/Caddyfile`:

```
rex.example.com {
	respond /rex/* 403
	reverse_proxy 127.0.0.1:32400
}
```

`respond /rex/* 403` keeps the feed API off the internet; your app still reaches rex directly. Then `sudo systemctl reload caddy`, add `--announce-url https://rex.example.com:443,http://192.168.1.20:32400` to `ExecStart` as above, with your LAN IP, and restart rex.

### What you should see

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://myhost.tailnet.ts.net/identity
```

answers `200`, and rex's log names the addresses it announces:

```
INFO    heartbeat every 600s for machine ... -> https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

rex prints this at every start. Trouble shows later as `heartbeat failed` or `announced but NOT visible`. Otherwise the server lists those addresses on plex.tv, and a Plex app away from home picks the one it can reach. If rex logs `waiting for a claim`, do [step 3](#step-3-add-it-to-a-plex-account) first.

## Converting video (optional)

**What it does.** Lets rex convert what a device cannot play, the way Plex does.

**Why it matters.** Without it a device that cannot play a file as it is gets "This server is not powerful enough to convert video". Web browsers hit this most, for example with AC3 or DTS sound.

Install jellyfin-ffmpeg 8 as a package (Ubuntu 22.04's own FFmpeg 4.4 is too old; this one goes in `/usr/lib/jellyfin-ffmpeg` beside any other) and point rex at it. The first line picks the build for your system: there are builds for Ubuntu 22.04, 24.04 and 26.04 and Debian 12 and 13, on amd64 or arm64, and on any other `curl` stops with an error.

```bash
DEB=jellyfin-ffmpeg8_8.1.3-1-$(. /etc/os-release; echo "$VERSION_CODENAME")_$(dpkg --print-architecture).deb
curl -fLO "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/$DEB"
sudo apt install -y "./$DEB" && rm "$DEB"
printf 'REX_TRANSCODER=/usr/lib/jellyfin-ffmpeg/ffmpeg\n' >> ~/rex/rex.env && chmod 600 ~/rex/rex.env
systemctl --user restart rex
```

With an Intel or AMD graphics chip, also run `sudo usermod -aG render "$USER"` and reboot so the service gets the group; in an LXC, pass the GPU through. On Intel, also run `echo LIBVA_DRIVER_NAME=iHD >> ~/rex/rex.env`; AMD needs no such line. The chip makes conversion fast; without one rex uses the processor. With no Intel or AMD chip, rex also tries an NVIDIA card's encoder. On Intel, `sudo apt install intel-opencl-icd` also converts HDR and Dolby Vision on the chip.

**What you should see.** rex's log has a `transcoder:` line naming the FFmpeg and the hardware it found (`hardware none` means the processor). A file that failed before now plays; the log shows what was converted, for example `video=copy h264 audio=ac3->aac`.

## Run rex in Docker

rex's image is private, like the download. Log in once with your GitHub username and a classic personal access token with the `read:packages` and `repo` scopes:

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

- `:nightly` follows the nightly builds; `latest` follows releases only.
- `network_mode: host` lets Plex apps on your network find rex by themselves, and lets rex reach your app at the address it registers, as from the machine itself.
- `./config` gets `rex.db` and, later, `claim_state.json`. They are readable by root only, because `rex.db` holds your app's login.
- Plex Media Server on the same machine? Add `command: --port 32500` and use `32500` wherever this page says `32400`. Flags you add later, such as `--announce-url`, go on that same `command:` line.

```bash
docker compose up -d
docker compose logs -f rex
```

You should see the same lines as [step 1](#step-1-install-rex). Then do steps 2 to 5 as above: your app uses `http://<the machine's LAN IP>:32400`, and the claim is the same `curl` on this machine. If your app runs in a container too, it must register an address rex can reach from the machine, not one only other containers can see.

Update with `docker compose pull && docker compose up -d`. The image carries no FFmpeg, so [converting video](#converting-video-optional) needs the install without Docker. HTTPS works as above: the options run on the machine itself, and `--announce-url ...` goes in `command`.

## Keep the port private

rex takes no password on its feed API. Anyone who can reach rex's port can register as an app, add to its library or remove what your app sent. Never forward port 32400 (or 32500) on your router, and keep `/rex/*` blocked in any proxy that faces the internet, as the [Caddy](#caddy) example does.

## Updating

Run the `TAG=`, `gh release download` and `tar` lines of [step 1](#step-1-install-rex) again in `~/rex` (they replace the program and `data/`, and leave `rex.db`, `rex.env` and `claim_state.json` alone), then `systemctl --user restart rex`.

## When something is wrong

| What you see | What to do |
|---|---|
| `/rex/sources` stays `{"size":0}` | Your app has not registered. Check the address it was given and that it can reach rex's port |
| A push answers `404 no such source` | Your app pushed before registering. It must `PUT /rex/sources/<name>` first |
| rex's log says `held ... no media_info yet` | Your app sent the file without ffprobe output. It appears once that arrives |
| Titles show file names and no posters | rex is not on a Plex account. Do [step 3](#step-3-add-it-to-a-plex-account). If rex was claimed after your app sent its library, they fill in by themselves, about 300 titles an hour |
| A title is in the wrong show, or a film is titled as its file | Your app sent no `kind` and `ids` for it, or the wrong ones. Fix it in your app, or use **Fix Match** in a Plex app signed in as the fresh account; a Fix Match stays as you set it |
| Nothing plays and rex's log shows 502 | rex cannot reach the address your app registered. `curl -s http://127.0.0.1:32400/rex/sources` shows it; test it with `curl` from the rex machine |
| Nothing plays, 401 or 403 | Your app refused its own login. Have it register again with the current one |
| A snapshot answers 409 `would remove more than half` | rex's guard against an app that sends a half-loaded library. If the removal is real, your app must send the whole snapshot again from part 0, with `"force": true` on its last part. Resending only the last part is refused, and sending it alone with `force` removes everything the earlier parts named |
| Deleting in a Plex app fails and rex logs `DELETE refused by the source` | Your app does not accept a `DELETE` of the file. Remove it in your app instead |
| "This server is not powerful enough to convert video" | The device cannot play the file as it is. Try a Plex app on a TV or phone, or set up [Converting video](#converting-video-optional) |
| After adding `--announce-url`, a device at home cannot connect | The LAN address is missing from `--announce-url`. Add `http://<LAN IP>:32400` after the HTTPS one |
| rex is not in the Plex apps away from home | Not claimed, no `--announce-url`, or the device cannot reach the HTTPS address |
| rex stops when you log out | Run `sudo loginctl enable-linger "$USER"` (step 1) |
