# rex with your own app

[rex](https://rex.debridmediamanager.com) is a Plex Media Server that owns no files. The official Plex apps see it as a normal Plex server. Another program, which this page calls **your app**, tells rex what is in your library and serves the files. When you press play, rex streams the file straight from your app. Nothing is downloaded first.

This page takes you from nothing to playing a movie, one step at a time. It does not assume any particular app. It says exactly what rex expects from one, so you can check that yours does it, or build one. Every step says what it does, why it matters and what you should see before you move on.

Four things to know before you start:

- **Your app serves the files.** rex fetches every byte from your app over HTTP or HTTPS, the way a browser downloads a file. rex keeps no files and needs no disk or mount for media.
- **Your app tells rex what it has.** It sends rex a list of files over rex's feed API, and every change after that. rex never lists a folder or scans anything.
- **Your app decides what each file is.** It says whether a file is a movie or an episode, which title it belongs to (by IMDb and TMDB id) and, for an episode, its season and number. rex never guesses from a file name.
- **Plex describes it.** Once rex is on a Plex account, it shows each title with the name, poster, summary and episode names Plex's own metadata has for those ids. For things no Plex agent knows, your app names them itself: see [Building rex addons](addons.md).

rex has been in closed beta for sponsors since October 15 and reaches the public on October 31. See [rex.debridmediamanager.com](https://rex.debridmediamanager.com) for access.

## Before you start

| You need | Why |
|---|---|
| rex's nightly dated 2026.10.25 or newer | Step 1 downloads the newest |
| A Linux machine that stays on (Ubuntu 22.04 or newer) | rex is a server: your Plex apps reach it whenever you press play. macOS and Windows work too; this page shows Linux, and [Docker](#run-rex-in-docker) is further down |
| 1 GB of RAM for a library of 40,000 titles | rex keeps the library in `rex.db` and uses about 450 MB with 40,000 titles, starting included. Converting video takes more, and more cores or a graphics chip |
| A GitHub account with access to rex's sponsor releases | rex is a private GitHub release |
| An app that does what [What your app must do](#what-your-app-must-do) lists | That is where your library comes from |
| A fresh Plex account, made just for rex | rex gets every title, poster, summary and episode name from Plex once it is [added to a Plex account](#step-3-add-it-to-a-plex-account). Until then titles keep their file names and have no posters |

## What your app must do

Give this list to whoever makes your app. rex's own API reference is `docs/feed-api.md` in every rex download.

| Your app must | How | If it does not |
|---|---|---|
| Serve each file over HTTP | `GET <address>/<path>` answers the file. `Range` requests make seeking fast; redirects are followed. Basic auth or a bearer token is allowed | Nothing plays: rex logs 502 |
| Register with rex | `PUT /rex/sources/<name>` (letters, digits, `-` and `_`) with `{"url": ...}` and, if it has a login, `"user"` and `"password"` or `"bearer"`, never inside the url. Again whenever it starts | rex has nowhere to read from |
| Send every file it has | `POST /rex/feed/<name>/items`, a few hundred files a request | rex stays empty |
| Send each file's ffprobe output | ffprobe's `-show_format -show_streams` JSON, whole, as `media_info` | The file is **held**: stored but not shown, because Plex apps refuse to play a file without it |
| Say what each file is | `kind` (`movie`, `episode` or `extra`) and `ids`: the movie's or the **show's** `imdb` or `tmdb` (either is enough), never an episode's. For an episode, `season` and `episode` on the item itself (beside `kind`, not inside `ids`), as TMDB numbers them; `episode_end` for a file holding several episodes | The file is unmatched: a film titled as its file, an episode in a show named after its release, numbered in file order |
| Keep the same `id` for a file forever | Even when it renames it | A renamed file becomes a new title and loses its watch history |
| Send changes as they happen | The same `POST` for new or changed files, `DELETE /rex/feed/<name>/items` for removed ones | The library goes stale |
| Send the whole library now and then | `PUT /rex/feed/<name>/snapshot`. rex removes whatever the snapshot does not name | Files your app lost track of stay in rex |
| Accept a WebDAV `DELETE` of a file | When someone deletes a title in a Plex app, rex asks your app to delete the file first | The title stays and the Plex app says it could not be deleted |

## Step 1. Install rex

**What it does.** Downloads rex into `~/rex` and starts it as a service that comes back after a reboot, with everything the later steps need. The steps after this one need no restart; only the optional sections further down do.

**Why it matters.** rex is what your Plex apps talk to. The first start creates `rex.db`, which holds your libraries, everything your app sends and your watch history.

rex's download uses the GitHub CLI. Install it (`sudo apt install -y gh`) and sign in once with `gh auth login`. Then:

```bash
mkdir -p ~/rex && cd ~/rex
TAG=$(gh api 'repos/debridmediamanager/rex/releases?per_page=1' --jq '.[0].tag_name')
A=$(dpkg --print-architecture)
gh release download "$TAG" -R debridmediamanager/rex -p "*-linux-$A.tar.gz"
tar xzf rex-*-linux-$A.tar.gz --strip-components=1 && rm rex-*-linux-$A.tar.gz
sudo loginctl enable-linger "$USER"
```

This takes rex's newest build, usually a nightly, for your machine's processor. The last line keeps rex running when you log out.

Find rex's LAN IP: `hostname -I` prints several, so take the one on your home network (usually `192.168.x.x` or `10.x.x.x`). **This page writes it as `192.168.1.20` everywhere: put yours in its place.** Plex apps, your app and your own commands all reach rex there.

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
ExecStart=%h/rex/rust/target/release/rex
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

**Plex Media Server runs on the same machine?** End the `ExecStart` line with `--port 32500` and use `32500` wherever this page says `32400`: Plex already holds port 32400 and the ports apps use to find servers, and on any other port rex leaves those to Plex.

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
journalctl --user -u rex -f
```

**What you should see.** Among the first lines:

```
INFO    seeded rex.db: an empty library named yourhost, machine=...
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
curl -s -X PUT http://192.168.1.20:32400/rex/sources/test \
  -H 'Content-Type: application/json' -d '{"url": "http://127.0.0.1:8099"}'
```

Send rex the file. It says the file is the movie Sintel (IMDb `tt1727587`, TMDB `45745`) and carries ffprobe's output:

```bash
P=movies/Sintel.2010/Sintel.2010.mkv
jq -n --arg p "$P" \
  --argjson probe "$(ffprobe -v quiet -print_format json -show_format -show_streams "$P")" \
  '{items: [{id: $p, path: $p, kind: "movie", ids: {imdb: "tt1727587", tmdb: 45745}, media_info: $probe}]}' \
| curl -s -X POST http://192.168.1.20:32400/rex/feed/test/items \
    -H 'Content-Type: application/json' --data-binary @-
```

**What you should see.** The answer is `{"created":1,"updated":0,"held":0,"unchanged":0,"rejected":[]}` and rex's log prints:

```
INFO    FEED identified "Sintel.2010" -> movie tmdb:45745 (placed)
INFO    FEED test upsert: 1 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Sintel is now in **Movies**, playing from the little web server. No Plex app can open rex before [step 3](#step-3-add-it-to-a-plex-account), so this step checks the feed only.

**Clean up** before you go on: removing the test source removes everything it sent. The first request answers a `confirm` path; send a `DELETE` to that path within five minutes.

```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/test
curl -s -X DELETE "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
kill %1
```

**If not.**

- `"held":1`: `media_info` is missing or has no streams. Check that `ffprobe` printed JSON for the file.
- An answer with `rejected`: the file is not a video by its extension, is a sample, has no `id` or `path`, or has a malformed path. The answer and rex's log give each reason.
- `404 no such source`: the `PUT /rex/sources/test` did not happen first.

## Step 3. Add it to a Plex account

**What it does.** Registers rex on a Plex account, as you would a real Plex Media Server, and shares it with your own account.

**Why it matters.** rex gets every title's name, poster, summary and episode names from Plex's own metadata, and it may only ask Plex once it is on an account. What your app sends before the claim is named as soon as it lands, and Fix Match has nothing to offer until then. It also removes the "unclaimed" notice and is needed before [using rex outside your home](#use-it-outside-your-home-optional).

**Use a fresh Plex account for this, not your own.** rex is not made by Plex, and Plex could take action against an account that registers it. Keep your real account, with its watch history, friends and any Plex Pass, out of reach: make a new free account at [plex.tv](https://www.plex.tv) with an email address you do not use elsewhere, register rex on that one, and share rex with your own account. You then watch signed in as yourself, the way you would watch a friend's server. rex plays nothing until this step is done.

### Register rex on the fresh account

1. Sign in to [plex.tv](https://www.plex.tv) **as the fresh account**, open [plex.tv/claim](https://www.plex.tv/claim) and copy the code. It expires after about five minutes.
2. On the rex machine:

   ```bash
   curl -X POST "http://192.168.1.20:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://192.168.1.20:32400/identity
   ```

**What you should see.** The second command shows `claimed="1"`, and `~/rex/claim_state.json` exists. Back that file up: without it rex has to be claimed again, and rex refuses a second claim while the file is there. From now on titles arrive with their names and posters, without a restart.

**If not.**

- The first command answers `409` with `rex: already claimed`: rex is on a Plex account already.
- It answers `500 Internal Server Error` and rex logs `claim exchange failed`: the code expired or was used. Get a new one from [plex.tv/claim](https://www.plex.tv/claim).

### Share it with your own account

1. Still signed in as the fresh account, open [app.plex.tv](https://app.plex.tv), then **Settings** (the wrench), **Manage Library Access** and **Grant Library Access**.
2. Enter your own account's username or email, pick the rex server and both libraries, **Movies** and **TV Shows**, and send the invite.
3. Sign out, sign in as **yourself**, and accept the invite. It arrives by email and in app.plex.tv.

**What you should see.** Signed in as yourself, Plex apps list the rex server beside your own servers, with both libraries. Your watch history on rex is your own: it is kept apart from the fresh account's. Share it the same way with anyone else in your household.

## Step 4. Connect your app

**What it does.** Points your app at rex. Your app registers, sends its whole library and then every change as it happens.

**Why it matters.** This is the only link between the two. rex has no setting for your app: your app finds rex, not the other way round.

Give your app rex's address, `http://192.168.1.20:32400`. How you enter it depends on your app.

**What you should see.** rex's log prints, under the name your app registered as:

```
INFO    SOURCES PUT /rex/sources/myapp -> 200
INFO    FEED myapp upsert: 0 created, 0 updated, 200 held, 0 unchanged, 0 rejected
INFO    FEED identified "Some.Movie.2019.1080p" -> movie tmdb:12345 (placed)
INFO    FEED myapp upsert: 180 created, 0 updated, 20 held, 0 unchanged, 0 rejected
```

`held` files are waiting for their ffprobe output and appear as soon as your app sends it. Check what rex has from your app at any time:

```bash
curl -s http://192.168.1.20:32400/rex/sources                # the apps that registered, and their addresses
curl -s http://192.168.1.20:32400/rex/feed/myapp/items | head -c 600   # what is shown
curl -s http://192.168.1.20:32400/rex/feed/myapp/held  | head -c 600   # what waits for ffprobe output
```

**If not.**

- Nothing at all in rex's log: your app never reached rex. Check the address you gave it, and that rex's port is open between the two machines.
- Files arrive but no `identified` lines: your app sends no `kind` and `ids` (held files and unchanged re-sends print none either). Those titles stay unmatched until it does; you can still fix one by hand with **Fix Match** in a Plex app signed in as the fresh account. Your own account, which rex is shared with, is refused.
- `/rex/sources` shows an address rex cannot reach, such as a container's own address: your app has to register an address that works from the rex machine. Test it with `curl` from there.

## Step 5. Watch something

**What it does.** Opens rex in a Plex app, the same way you would open any Plex server.

**Why it matters.** This is the point of the whole setup. It also proves the last link: rex reading a file from your app while you watch.

Open a Plex app on a phone, TV or computer **on the same home network**. rex shows up under the machine's name, with **Movies** and **TV Shows**. Pick a movie and press play.

At home nothing else is needed: Plex apps find rex with Plex's own local discovery and connect to it over your network. That needs the device on the same network as rex (not a guest Wi-Fi or a separate VLAN). Discovery runs on UDP ports 32410 and 32414, so a firewall on the rex machine must let those in. rex answers discovery when it uses port 32400. If you moved rex to 32500 because Plex runs on the same machine, discovery is left to that Plex, and apps find rex through the Plex account it is [shared with](#share-it-with-your-own-account). app.plex.tv in a web browser is the exception: it needs the HTTPS address from [Use it outside your home](#use-it-outside-your-home-optional), even at home.

**What you should see.** Posters, titles and years as on any Plex server. Playback starts within a few seconds.

Two things you may meet:

- **"yourhost server is unclaimed and not secure".** A Plex app says this about any server that is not on a Plex account, and rex plays nothing until it is on one. Do [step 3](#step-3-add-it-to-a-plex-account).
- **"This server is not powerful enough to convert video".** The app cannot play the file as it is, often a web browser meeting AC3 or DTS sound. Plex apps on TVs and phones play most files as they are. To play everything everywhere, set up [Converting video](#converting-video-optional).

Each file goes to **Movies** or **TV Shows** by the `kind` your app sent. A file without one goes by its first folder: `shows` to TV Shows, anything else to Movies.

To give a folder libraries of its own, your app adds `directories` to its registration, naming the first folder of the files' paths and the libraries' titles: `{"url": ..., "directories": [{"name": "anime", "shows": "Anime", "movies": "Anime Movies"}]}`, either title alone being fine. rex makes them when your app registers and moves what that folder already has into them as it was: watch history, Fix Match and edits included. A malformed entry is skipped and listed under `ignored` in the answer, with why. Rename them in a Plex app as you like. Delete one and it stays deleted, its files going back to Movies or TV Shows, until you add it again with **Add Library**, whose folder list shows your app's folders. `docs/feed-api.md` has the rules, under "Libraries a source declares".

**Back up** `~/rex/rex.db` (it holds your library, watch history and your app's login, so keep it private) and `claim_state.json`:

```bash
sudo apt install -y sqlite3    # once
sqlite3 ~/rex/rex.db ".backup $HOME/rex/rex.db.bak"
```

In Docker the files sit in `~/rex/config`, readable by root only. Back up from inside the container: `docker exec rex sqlite3 /config/rex.db ".backup /config/rex.db.bak"`.

You are done. The sections below are optional.

## Use it outside your home (optional)

**What it does.** Gives rex an HTTPS address that Plex apps away from home can reach, and tells plex.tv about it.

**Why it matters.** app.plex.tv only connects to an HTTPS address, even at home, and the other Plex apps prefer one away from home. A real Plex server can fall back to Plex's relay; rex cannot, so you choose how it is reached. rex must be [claimed](#step-3-add-it-to-a-plex-account) first. A proxy that faces the internet must block `/rex/`: see [Keep the port private](#keep-the-port-private).

**Plex Pass.** Plex Web plays away from home without a Plex Pass or Remote Watch Pass on either account. Other Plex apps have not been tested away from home.

Whichever you pick, every byte you watch away from home leaves through your home connection's **upload** speed. As a rough guide, a 20 Mbit/s upload carries one 1080p WEB-DL, not a remux.

| Your situation | Use | Why |
|---|---|---|
| Your router has a public IP and you can forward a port | **[rex-direct](#rex-direct)** (simplest) | On by default: one port forward. DMM gives rex a name and a certificate, and keeps the name pointed at your home IP |
| You can install Tailscale on the devices you watch on | **[Tailscale serve](#tailscale-serve)** (best) | Nothing to open on your router, and it works behind any internet connection. The certificate renews by itself, and nobody outside your tailnet can reach rex |
| Devices without Tailscale (a friend's TV, a hotel), and your router has a public IP | **[Caddy](#caddy)** with your own domain, or with a free `sslip.io` name | A direct connection with nobody in between, and a free certificate that renews by itself. You forward port 443 |
| Your connection has no public IP (CGNAT, common on mobile and some fibre providers), and devices without Tailscale | **[A small VPS](#a-small-vps)** | rex has no relay and will not get one. A VPS you rent has the public IP and a tunnel carries everything to rex, at the VPS's full bandwidth |

Not recommended:

- **Cloudflare tunnel.** Every byte goes through Cloudflare, which also drops the `Range` of a file's first read, so every play start pulls the whole file from your app.
- **Tailscale Funnel, ngrok and other hosted tunnels.** They cap bandwidth or monthly data, which a film runs through quickly. Tailscale Funnel also publishes all of rex, including the feed API: anyone on the internet could add to or delete from your library.
- **Forwarding port 32400 without rex-direct or a certificate of your own.** Plex apps would get a plain HTTP address, which app.plex.tv refuses.

### rex-direct

rex-direct is DMM's answer to plex.direct, and it is on by default. On your router, forward port 32400 (TCP) to the rex machine. That is all, with nothing to restart.

Once claimed, rex gets its own name from DMM, `<hash>.rex-direct.debridmediamanager.com`, pointed at your home's public IP, and a certificate for that name alone. The first certificate takes a few minutes; rex's log says it is being issued and then shows the name in a `rex-direct:` line. A new home IP and certificate renewals are picked up by themselves. One Plex account can hold up to ten rex-direct names. At home, Plex apps can pick this name over the LAN IP, and unless you also set up Tailscale serve or Caddy, app.plex.tv in a browser has no other address it can use. So at home your router has to send the connection straight back to rex, or your home DNS has to point the name at rex: [What you should see](#what-you-should-see) checks which.

If your router forwards a different outside port to rex, add `REX_DIRECT_PORT=<that port>` to `rex.env` and restart rex. The port forward does not open the feed API: see [Keep the port private](#keep-the-port-private).

### Tailscale serve

Install [Tailscale](https://tailscale.com/download) on the rex machine and on the devices you watch on, signed in to the same account. Then on the rex machine:

```bash
sudo tailscale serve --bg 32400
```

It prints the address, for example `https://myhost.tailnet.ts.net`. Give it to rex with `:443` added, on the `ExecStart` line from [step 1](#step-1-install-rex):

```ini
ExecStart=%h/rex/rust/target/release/rex --announce-url https://myhost.tailnet.ts.net:443
```

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
	reverse_proxy 192.168.1.20:32400
}
```

`respond /rex/* 403` keeps the feed API off the internet; your app still reaches rex directly. Then `sudo systemctl reload caddy`, end the `ExecStart` line with `--announce-url https://rex.example.com:443`, and restart rex as above.

### A small VPS

For a connection with no public IP (CGNAT). rex has no relay and will not get one, so a server you rent stands in for your router: it has the public IP, and a tunnel from the rex machine carries everything to rex. Any VPS with a public IPv4 works, a few euros a month. **Pick one whose monthly traffic covers what you watch away from home:** every byte passes through it, and a plan with a small data cap will run out.

You need the VPS's IP (`1.2.3.4` below), ports 443, 80 and 7000 open on it, and a long random string for the tunnel (`openssl rand -hex 32`).

**On the VPS**, install [frp](https://github.com/fatedier/frp/releases) (the `frps` program) and [Caddy](https://caddyserver.com/docs/install). Make `frps.toml`:

```toml
bindPort = 7000
auth.token = "your-long-random-string"
proxyBindAddr = "127.0.0.1"
```

`proxyBindAddr` keeps the tunnel's end on the VPS's loopback, so the internet reaches rex only through Caddy. Make `/etc/caddy/Caddyfile`, with the VPS's IP as `1-2-3-4.sslip.io` (a free name that always points at that IP) or your own domain pointed at it:

```
1-2-3-4.sslip.io {
	respond /rex/* 403
	reverse_proxy 127.0.0.1:32400
}
```

`respond /rex/* 403` keeps the feed API off the internet. Start `frps -c frps.toml` as a service and run `sudo systemctl reload caddy`.

**On the rex machine**, install frp too (the `frpc` program) and make `frpc.toml`:

```toml
serverAddr = "1.2.3.4"
serverPort = 7000
auth.token = "your-long-random-string"

[[proxies]]
name = "rex"
type = "tcp"
localIP = "192.168.1.20"
localPort = 32400
remotePort = 32400
```

Run it as a service, for example `~/.config/systemd/user/frpc.service` with `ExecStart=%h/frp/frpc -c %h/frp/frpc.toml` and `Restart=always`. Then give rex the VPS's name with `--announce-url`, add `REX_DIRECT_URL=off` to `~/rex/rex.env` (rex-direct cannot work without a public IP at home, so plex.tv should not list it), and restart rex:

```ini
ExecStart=%h/rex/rust/target/release/rex --announce-url https://1-2-3-4.sslip.io:443
```

### What you should see

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://myhost.tailnet.ts.net/identity
```

answers `200` on a computer at home. Use your own address: with rex-direct it is the one `journalctl --user -u rex | grep 'rex-direct: https'` prints (in Docker, `docker logs rex 2>&1 | grep 'rex-direct: https'`), with `/identity` added. Open the same address in a phone's browser with Wi-Fi off: it shows a short XML page with no certificate warning. With Tailscale serve, both the computer and the phone need Tailscale on.

With rex-direct or Caddy, if the phone gets it and the computer at home does not, your router does not send connections back inside. Point the name at rex's LAN IP in your home network's DNS (your router's, or Pi-hole's; a router with DNS rebind protection needs an exception for it) and the rex machine answers it at home with the same certificate. If the phone fails too, the port is not forwarded, your connection is behind CGNAT, or rex-direct's certificate is still being issued (rex's log says so while it is).

rex's log names the addresses it announces:

```
INFO    heartbeat every 600s for machine ... -> https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

rex prints this at every start. Trouble shows later as `heartbeat failed` or `announced but NOT visible`. Otherwise the server lists those addresses on plex.tv, and a Plex app away from home picks the one it can reach. If rex logs `waiting for a claim`, do [step 3](#step-3-add-it-to-a-plex-account) first.

## Converting video (optional)

**What it does.** Lets rex convert what a device cannot play, the way Plex does.

**Why it matters.** Without it a device that cannot play a file as it is gets "This server is not powerful enough to convert video". Web browsers hit this most, for example with AC3 or DTS sound.

Install **jellyfin-ffmpeg** 8, not the `ffmpeg` your system offers: it is the build rex is measured with and the only one that converts every Dolby Vision file, tonemaps HDR on the graphics chip and draws subtitles there. Another FFmpeg converts ordinary video and rex's log says what it lacks (Ubuntu 22.04's own also seeks a few seconds off). The package goes in `/usr/lib/jellyfin-ffmpeg` beside any other FFmpeg, and rex finds it on its own. The first line picks the build for your system: there are builds for Ubuntu 22.04, 24.04 and 26.04 and Debian 12 and 13, on amd64 or arm64, and on any other `curl` stops with an error.

```bash
DEB=jellyfin-ffmpeg8_8.1.3-1-$(. /etc/os-release; echo "$VERSION_CODENAME")_$(dpkg --print-architecture).deb
curl -fLO "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/$DEB"
sudo apt install -y "./$DEB" && rm "$DEB"
systemctl --user restart rex
```

On another Linux, unpack jellyfin-ffmpeg's portable build into `~/rex/ffmpeg`, where rex looks for it, and restart rex. It uses your system's own graphics driver, so on an older system it converts on the processor only; use the package wherever there is one. On Windows or macOS, download the portable build for your machine from [jellyfin-ffmpeg's release page](https://github.com/jellyfin/jellyfin-ffmpeg/releases/tag/v8.1.3-1) (`win64-clang` for Windows, `macarm64` for Apple Silicon, `mac64` for an Intel Mac) and unpack it into an `ffmpeg` folder inside rex's folder. rex finds it there.

```bash
B=$( [ "$(uname -m)" = aarch64 ] && echo linuxarm64 || echo linux64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
```

With an Intel or AMD graphics chip, also run `sudo usermod -aG render "$USER"` and reboot so the service gets the group; in an LXC, pass the GPU through. The chip makes conversion fast; without one rex uses the processor. With no Intel or AMD chip, rex also tries an NVIDIA card's encoder. On Intel, `sudo apt install intel-opencl-icd` also converts HDR and Dolby Vision on the chip, at about real time for 4K on a small Intel; without it they are converted on the processor, which a low-power Intel cannot do in real time at 4K.

**What you should see.** rex's log has a `transcoder:` line naming the FFmpeg and the hardware it found (`hardware none` means the processor). A file that failed before now plays; the log shows what was converted, for example `video=copy h264 audio=ac3->aac`.

Subtitles in a converted file: an image subtitle is burned into the picture and a subtitle you uploaded comes along. Plex for Android and iOS also keep a text subtitle as a track; other apps get it drawn into the picture. Converted offline downloads still omit text subtitles.

## Subtitles

**What it does.** Search Subtitles in a Plex app finds subtitles from Plex's own provider once rex is claimed. rex checks the one you pick against the file and fixes its timing when it runs late or was made for another frame rate. When your Plex account is set to show subtitles and a title has none in your language, rex looks for one for up to 3 seconds before it starts.

**Why it matters.** Plex's own first result is often out of sync with the file.

There is nothing to set up. rex checks a subtitle against the file's own text subtitle when it has one. A file without one is checked against its sound when you press play, which needs [Converting video](#converting-video-optional) set up and reads six 90-second pieces of the file.

**What you should see.** rex's log has a `SUBTITLE measured` line for each subtitle it checks, and `SUBTITLE applied ... corrected by` when it fixed one.

## Movie and TV capabilities

Downloads, intro and credits detection, seek thumbnails and the other Plex server features rex has, and their settings, are in `docs/setup.md` in your rex download ("Movie and TV capabilities"). Music, Live TV and DVR are not supported.

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

- Intel or AMD graphics chip? Add `devices: ["/dev/dri:/dev/dri"]` so rex converts video on it.
- `network_mode: host` lets Plex apps on your network find rex by themselves, and lets rex reach your app at the address it registers, as from the machine itself.
- `./config` gets `rex.db` and, later, `claim_state.json`. They are readable by root only, because `rex.db` holds your app's login.
- Plex Media Server on the same machine? Add `command: --port 32500` and use `32500` wherever this page says `32400`.

```bash
docker compose up -d
docker compose logs -f rex
```

You should see the same lines as [step 1](#step-1-install-rex). Then do steps 2 to 5 as above. If your app runs in a container too, it must register an address rex can reach from the machine, not one only other containers can see.

Update with `docker compose pull && docker compose up -d`. The image carries jellyfin-ffmpeg, so [converting video](#converting-video-optional) needs only the graphics chip handed in. HTTPS works as above: Tailscale, Caddy and frp run on the machine itself, and `--announce-url ...` goes in the compose file's `command:`.

## Keep the port private

rex takes no password on its feed API. It answers that API only from this machine, your home network (10.x, 172.16-31.x, 192.168.x, 169.254.x and private IPv6 addresses) and Tailscale (100.64-127.x), and to everyone else answers as if the API were not there, so forwarding rex's port for [rex-direct](#rex-direct) does not open it. A router that gives outside visitors its own address makes them look local, and that opens the feed to the internet. Your app must therefore push from one of those networks. A proxy on the rex machine looks local to rex, so keep `/rex/*` blocked in any proxy that faces the internet, as the [Caddy](#caddy) example does.

## Updating

Run the first block of [step 1](#step-1-install-rex) again in `~/rex` (it replaces the program and `data/`, and leaves `rex.db`, `rex.env` and `claim_state.json` alone), then `systemctl --user restart rex`.

## When something is wrong

| What you see | What to do |
|---|---|
| `/rex/sources` stays `{"size":0}` | Your app has not registered. Check the address it was given and that it can reach rex's port |
| A push answers `404 no such source` | Your app pushed before registering. It must `PUT /rex/sources/<name>` first |
| rex's log says `held ... no media_info yet` | Your app sent the file without ffprobe output. It appears once that arrives |
| Titles show file names and no posters | rex is not on a Plex account. Do [step 3](#step-3-add-it-to-a-plex-account). If rex was claimed after your app sent its library, they are named by themselves once the claim lands |
| A title is in the wrong show, or a film is titled as its file | Your app sent no `kind` and `ids` for it, or the wrong ones. Fix it in your app, or use **Fix Match** in a Plex app signed in as the fresh account; a Fix Match stays as you set it |
| Nothing plays and rex's log shows 502 | rex cannot reach the address your app registered. `curl -s http://192.168.1.20:32400/rex/sources` shows it; test it with `curl` from the rex machine |
| Nothing plays, 401 or 403 | Your app refused its own login. Have it register again with the current one |
| A snapshot answers 409 `would remove more than half` | rex's guard against an app that sends a half-loaded library. If the removal is real, your app must send the whole snapshot again from part 0, with `"force": true` on its last part. Resending only the last part is refused, and sending it as a new snapshot of its own with `force` removes everything the earlier parts named |
| Deleting in a Plex app fails and rex logs `DELETE refused by the source` | Your app does not accept a `DELETE` of the file. Remove it in your app instead |
| "This server is not powerful enough to convert video" | The device cannot play the file as it is. Try a Plex app on a TV or phone, or set up [Converting video](#converting-video-optional) |
| A device at home cannot connect, and rex's `heartbeat ... ->` line shows no `http://192.168.1.20:32400` | rex announces the private address of the network it reaches the internet through; behind a VPN or a Tailscale exit node that is not your home network. Add `--announce-url http://192.168.1.20:32400` to the `ExecStart` line and restart rex |
| rex is not in the Plex apps away from home | Not claimed, or the device cannot reach the HTTPS address |
| rex stops when you log out | Run `sudo loginctl enable-linger "$USER"` (step 1) |
