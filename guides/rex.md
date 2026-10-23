---
label: rex
icon: server
order: 45
---

# rex with zurg

[rex](https://rex.debridmediamanager.com) is a Plex Media Server that owns no files. The official Plex apps see it as a normal Plex server. Any app can fill it ([rex with your own app](rex-any-source.md)); this page sets it up with zurg, which sends it your debrid library, and when you press play rex streams the file straight from zurg. Nothing is downloaded first.

This page takes you from nothing to playing a movie, one step at a time. Every step says what it does, why it matters and what you should see before you move on. If what you see does not match, stop there: the next step will not fix it.

![zurg registers with rex and sends it the library; Plex apps play through rex, which reads each file from zurg](../assets/rex/how-it-fits.svg)

Four things to know before you start:

- **zurg is the part that talks to your debrid service.** It lists what is in your account and serves the files.
- **rex is the part your Plex apps talk to.** It keeps no files and needs no disk for media. It does not need rclone or a mount.
- **zurg tells rex about itself.** You give zurg the address of rex, and zurg does the rest. You never type zurg's details into rex.
- **zurg and DMM decide what each file is; Plex describes it.** zurg asks DMM which movie or episode each file is, and rex shows that title with the posters and summaries Plex's own metadata gives it once rex is on a Plex account. rex never guesses from a file name.

rex opened as a closed beta for sponsors on October 15 and reaches the public on October 31. See [rex.debridmediamanager.com](https://rex.debridmediamanager.com) for access.

## Before you start

| You need | Why |
|---|---|
| A Linux machine that stays on (Ubuntu 22.04 or newer). A Proxmox LXC works, unprivileged is fine, once FUSE is turned on for it (Options > Features > FUSE): zurg's installer stops without `/dev/fuse` | rex and zurg are servers: your Plex apps reach them whenever you press play. macOS and Windows work too; this page shows Linux, and [Docker](#run-rex-in-docker) is further down |
| 2 GB of RAM for a library of 40,000 titles | rex keeps the library in `rex.db` and uses about 400-800 MB once running, more while it starts. zurg needs little |
| A debrid account (Real-Debrid, TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud) or Usenet | That is where your movies and shows actually live |
| A GitHub account with access to zurg's and rex's sponsor releases | Both are private GitHub releases. The zurg installer signs you in once and rex's download reuses that sign-in |
| Your DMM API key, from sponsoring DMM (optional) | zurg asks DMM what each file is. Without it zurg works it out from the release name, through DMM's free title search: fewer titles match, and an anime numbered across the whole series stays in file order |
| A fresh Plex account, made just for rex | rex gets every title, poster, summary and episode name from Plex once it is [added to a Plex account](#step-3-add-it-to-a-plex-account). Until then titles keep their file names and have no posters |

You do **not** need a TMDB key or your Plex token.

## Step 1. Install zurg

**What it does.** Downloads zurg, asks for your debrid account and starts zurg as a service that comes back after a reboot.

**Why it matters.** Everything rex shows comes from zurg. If zurg cannot see your library, rex never will.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
sudo loginctl enable-linger "$USER"
```

The installer asks which services you use (type `1` for Real-Debrid) and then for your API token. The token is hidden while you paste it. zurg goes into `~/zurg`. The second line keeps your services running when you log out.

**What you should see.** The installer ends with a list of `PASS` lines and `==> zurg is installed in /home/you/zurg`. zurg then loads your library: a few seconds for a small account, about ten minutes for one with a thousand releases on Real-Debrid. Open zurg's dashboard at `http://<this machine>:9999`: **Library Size** counts your items once it is done.

Already run zurg? Update and restart it with `cd ~/zurg && ./zurg update && ./zurg service restart`. You need nightly **2026.10.19 or later**.

## Step 2. Install rex

**What it does.** Downloads rex into `~/rex` and starts it as a service, with everything the later steps need. Nothing after this step restarts rex.

**Why it matters.** rex is what your Plex apps talk to. The first start creates `rex.db`, which holds your libraries, everything zurg sends and your watch history.

```bash
mkdir -p ~/rex && cd ~/rex
export PATH="$PATH:$HOME/zurg/bin"
TAG=$(gh api 'repos/debridmediamanager/rex/releases?per_page=1' --jq '.[0].tag_name')
gh release download "$TAG" -R debridmediamanager/rex -p '*-linux-amd64.tar.gz'
tar xzf rex-*-linux-amd64.tar.gz --strip-components=1 && rm rex-*-linux-amd64.tar.gz
```

This takes rex's newest build, usually a nightly. On an ARM machine (Raspberry Pi, Ampere) use `linux-arm64` in all three places.

Find rex's LAN IP: `hostname -I` prints several, so take the one on your home network, not one starting with `172.17.` (Docker) or `100.` (Tailscale). **This page writes it as `192.168.1.20` everywhere: put yours in its place.** Plex apps, zurg and your own commands all reach rex there.

Now make it a service. Create `~/.config/systemd/user/rex.service`:

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/rex.service
```

```ini
[Unit]
Description=rex

[Service]
WorkingDirectory=%h/rex
EnvironmentFile=-%h/rex/rex.env
ExecStart=%h/rex/rust/target/release/rex --catalog rex.db --announce-url http://192.168.1.20:32400
UMask=0077
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
INFO    seeded rex.db: an empty library named yourhost at /mnt/rex, machine=...
INFO    no source yet: one registers at PUT /rex/sources/{name} (docs/feed-api.md)
INFO    claim state: unclaimed
INFO    rex on http://yourhost:32400  machine=...  items=0  parts=proxy
```

rex names itself after the machine; your Plex apps show that name. `no source yet` is right: zurg has not been told about rex. A `WARNING` that a CDN may strip `Range` is about the LAN IP and can be ignored. Leave the log open.

## Step 3. Add it to a Plex account

**What it does.** Registers rex on a Plex account, as you would a real Plex Media Server, and shares it with your own account.

**Why it matters.** rex gets every title's name, poster, summary and episode names from Plex's own metadata, and it may only ask Plex once it is on an account. Do it now, before zurg sends anything: titles that arrive after the claim come with their posters, while titles sent before it fill in slowly, about 300 films or shows an hour. It also makes Fix Match work, removes the "unclaimed" notice and is needed before [using rex outside your home](#use-it-outside-your-home-optional).

**Use a fresh Plex account for this, not your own.** rex is not made by Plex, and Plex could take action against an account that registers it. Keep your real account, with its watch history, friends and any Plex Pass, out of reach: make a new free account at [plex.tv](https://www.plex.tv) with an email address you do not use elsewhere, register rex on that one, and share rex with your own account. You then watch signed in as yourself, the way you would watch a friend's server. rex plays nothing until this step is done.

### Register rex on the fresh account

1. Sign in to [plex.tv](https://www.plex.tv) **as the fresh account**, open [plex.tv/claim](https://www.plex.tv/claim) and copy the code. It expires after about five minutes.
2. On the rex machine:

   ```bash
   curl -X POST "http://192.168.1.20:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://192.168.1.20:32400/identity
   ```

**What you should see.** The second command shows `claimed="1"`, and `~/rex/claim_state.json` exists. Back that file up: without it you have to claim again with a new code. While it exists, rex refuses a second claim.

### Share it with your own account

1. Still signed in as the fresh account, open [app.plex.tv](https://app.plex.tv), then **Settings** (the wrench), **Manage Library Access** and **Grant Library Access**.
2. Enter your own account's username or email, pick the rex server and both libraries, **Movies** and **TV Shows**, and send the invite.
3. Sign out, sign in as **yourself**, and accept the invite. It arrives by email and in app.plex.tv.

rex tells plex.tv the address from step 2 the moment it is claimed, with no restart.

**What you should see.** Signed in as yourself, Plex apps list the rex server beside your own servers, with both libraries, empty until the next step. Your watch history on rex is your own: it is kept apart from the fresh account's. Share it the same way with anyone else in your household.

## Step 4. Connect zurg to rex

**What it does.** Tells zurg where rex is. zurg introduces itself to rex, sends its whole library, reads each file's video and audio details and sends those too, then every change as it happens.

**Why it matters.** This is the only link between the two. rex has no setting for zurg: if `rex_url` is missing, rex stays empty. Your DMM key lets zurg ask DMM which movie or episode each file is; without one zurg works it out from the name, and fewer titles match.

First check whether zurg's config already has either line:

```bash
grep -n '^rex_url:\|^dmm_api_key:' ~/zurg/config.yml
```

If it prints a line, that key is already set: change it there with `nano ~/zurg/config.yml` and leave it out of the `printf` below. Without a DMM key, leave `dmm_api_key` out. zurg will not start with the same key twice, and zurg's dashboard writes `dmm_api_key` into this file when you enter your key there.

```bash
printf '\nrex_url: http://192.168.1.20:32400\ndmm_api_key: your_dmm_key\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```

**What you should see.** Once zurg has loaded the library again, zurg's log (`~/zurg/logs/zurg.log`) says `DMM placed N releases for rex` (without a DMM key: `Placed N releases for rex by their names`) and rex's log prints:

```
INFO    SOURCES PUT /rex/sources/zurg -> 200
INFO    FEED zurg upsert: 0 created, 0 updated, 200 held, 0 unchanged, 0 rejected
INFO    FEED identified "Sintel.mp4" -> movie tmdb:45745 (placed)
INFO    FEED zurg upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

`held` means zurg has not read that file's details yet. zurg starts reading them as soon as its library has loaded, one release at a time, and a season pack's episodes arrive together. With a DMM key, up to about 20 releases a minute come from DMM's stored details. A large library fills over several hours. Each title appears in rex as its details arrive. Anything you add to your debrid account later shows up by itself once zurg has read it.

**If not.**

- Nothing at all in rex's log: zurg is still loading its library, zurg is older than 2026.10.19 (update it as in [step 1](#step-1-install-zurg)), or `rex_url` has a typo. `grep 'rex feed' ~/zurg/logs/zurg.log | tail -n 5` shows zurg's side: with no `rex feed: pushing the library to ...` line zurg did not read `rex_url`, and `rex feed: snapshot failed, retrying in ...` means it cannot reach rex at that address.
- A title stays `held` and zurg logs `Cannot probe file ...`: the first read from the debrid service failed. zurg tries again by itself; **Analyze & Tag Library** under **Utilities** on zurg's dashboard tries at once.
- Titles arrive but no `identified` lines: zurg could not match them by name, and with `dmm_api_key` set it logs `DMM refused the API key for placement` when the key is not a sponsor's. zurg then matches by name and tries the key again a day later, or at once when it restarts.

Leave `plex_server_url` in zurg's config pointing at your real Plex, or empty. Pointed at rex, zurg would take rex's own matches and give them to DMM as the answer, wrong ones included.

Running several zurgs (one per debrid service)? Give each its own name with an extra line, `rex_source: rd`, `rex_source: tb` and so on. They fill the same libraries.

### Why DMM places the files

File names often number episodes differently from the episode lists Plex apps show. DMM knows where each file really belongs:

| Release | Named | Where it really is |
|---|---|---|
| `[Erai-raws] Hibike Euphonium 3 - 01` | season 1, episode 1 | Sound! Euphonium season 3, episode 1 |
| `[HorribleSubs] One Piece - 486` | episode 486 | season 13, episode 486 |
| `Firefly.S01E02.The.Train.Job` (DVD order) | episode 2 | episode 1, "The Train Job" |

A file zurg cannot place stays unmatched: a film titled as its file, or an episode in a show named after its release, numbered in file order. With a DMM key zurg asks DMM about it again a day later, and you can fix it yourself with **Fix Match** in a Plex app, signed in as the fresh account that owns rex (rex refuses it to the accounts it is shared with). A title you corrected with Fix Match stays as you set it.

## Step 5. Watch something

**What it does.** Opens rex in a Plex app, the same way you would open any Plex server.

**Why it matters.** This is the point of the whole setup. It also proves the last link: rex reading a file from zurg while you watch.

Open a Plex app (not a web browser) on a phone, TV or computer **on the same home network**. rex shows up on its own under the machine's name, with **Movies** and **TV Shows**. Pick a movie and press play.

At home nothing else is needed: Plex apps find rex with Plex's own local discovery and connect to it over your network. That needs the device on the same network as rex (not a guest Wi-Fi or a separate VLAN). Discovery runs on UDP ports 32410 and 32414, so a firewall on the rex machine must let those in. rex answers discovery when it uses port 32400. If you moved rex to 32500 because Plex runs on the same machine, discovery is left to that Plex, and apps find rex through the Plex account it is [shared with](#share-it-with-your-own-account). app.plex.tv in a web browser is the exception: it needs the HTTPS address from [Use it outside your home](#use-it-outside-your-home-optional), even at home.

![rex's Movies library in Plex](../assets/rex/rex-movies.webp)

**What you should see.** Posters, titles and years as on any Plex server, and the movie plays.

Two things you may meet:

- **"yourhost server is unclaimed and not secure".** A Plex app says this about any server that is not on a Plex account, and rex plays nothing until it is on one. Do [step 3](#step-3-add-it-to-a-plex-account). Do not press **Claim it now** while signed in as yourself: it registers rex on your own account.
- **"This server is not powerful enough to convert video".** The app cannot play the file as it is, often a web browser meeting AC3 or DTS sound. Plex apps on TVs and phones play most files as they are. To play everything everywhere, set up [Converting video](#converting-video-optional).

![The unclaimed-server notice in Plex](../assets/rex/rex-unclaimed.webp)

zurg's folders other than `movies` and `shows`, such as `anime`, need nothing: each file goes to **Movies** or **TV Shows** by what zurg says it is. A file zurg cannot tell is an episode waits in **Movies**.

To give one of those folders libraries of its own, add `rex_shows` and/or `rex_movies` under it in `~/zurg/config.yml`, beside its filters, then restart zurg (`cd ~/zurg && ./zurg service restart`). This needs zurg's next nightly after 2026-10-22 (update it as in [step 1](#step-1-install-zurg)):

```yaml
directories:
  anime:
    rex_shows: Anime
    rex_movies: Anime Movies
```

Once zurg has loaded, rex makes **Anime** and **Anime Movies** and moves what it already showed from `anime` into them as it was: watch history, Fix Match and edits included. An open Plex Web lists them at once under **More** in its sidebar, where you can pin them. Share them with your own account as in [step 3](#share-it-with-your-own-account). Rename them in a Plex app as you like. Delete one and it stays deleted, its files going back to **Movies** or **TV Shows**, until you add it again with **Add Library**: its folder list shows `/mnt/zurg/anime`. A mistyped line is skipped and zurg's log (`~/zurg/logs/zurg.log`) says why. If rex refuses one, rex's log says why.

**Back up** `~/rex/rex.db` (it holds your library, watch history and zurg's login, so keep it private) and, once you have one, `claim_state.json`:

```bash
sudo apt install -y sqlite3    # once
sqlite3 ~/rex/rex.db ".backup $HOME/rex/rex.db.bak"
```

In Docker the files sit in `~/rex/config`, readable by root only. Back up from inside the container: `docker exec rex sqlite3 /config/rex.db ".backup /config/rex.db.bak"`.

You are done. The sections below are optional.

## Use it outside your home (optional)

**What it does.** Gives rex an HTTPS address that Plex apps away from home can reach, and tells plex.tv about it.

**Why it matters.** app.plex.tv only connects to an HTTPS address, even at home, and the other Plex apps prefer one away from home. A real Plex server can fall back to Plex's relay; rex cannot, so you choose how it is reached. rex must be [claimed](#step-3-add-it-to-a-plex-account) first. A claimed rex checks the Plex token on every request except a few public pages (`/identity`, `/web`) and its feed API (`/rex/feed/` and `/rex/sources`), which answers only this machine, your home network and Tailscale. A proxy on the rex machine counts as home, which is why a proxy that faces the internet must block `/rex/`.

**Plex Pass.** With the October 21 remote-playback update, Plex Web 4.163.0 plays away from home without a Plex Pass or Remote Watch Pass on either the fresh claiming account or your viewing account. rex advertises that capability locally; it changes no subscription at plex.tv. Older builds can still show Plex's paywall. Other Plex apps have not been playback-tested.

Whichever you pick, every byte you watch away from home leaves through your home connection's **upload** speed. A 20 Mbit/s upload carries one 1080p WEB-DL comfortably, not a remux.

### Which one to use

| Your situation | Use | Why |
|---|---|---|
| Your router has a public IP and you can forward a port | **[rex-direct](#rex-direct)** (simplest) | On by default: one port forward. DMM gives rex a name and a certificate, and keeps the name pointed at your home IP |
| You can install Tailscale on the devices you watch on | **[Tailscale serve](#tailscale-serve)** (best) | Nothing to open on your router, and it works behind any internet connection. The certificate renews by itself, and nobody outside your tailnet can reach rex |
| Devices without Tailscale (a friend's TV, a hotel), and your router has a public IP | **[Caddy](#caddy)** with your own domain, or with a free `sslip.io` name | A direct connection with nobody in between, and a free certificate that renews by itself. You forward port 443 |
| Your connection has no public IP (CGNAT, common on mobile and some fibre providers), and devices without Tailscale | **[A small VPS](#a-small-vps)** | rex has no relay and will not get one. A VPS you rent has the public IP and a tunnel carries everything to rex, at the VPS's full bandwidth |

Not recommended:

- **Cloudflare tunnel.** Every byte goes through Cloudflare, which also drops the `Range` of a file's first read, so every play start pulls the whole file from your debrid service.
- **Tailscale Funnel, ngrok and other hosted tunnels.** They cap bandwidth or monthly data, which a film runs through quickly. Tailscale Funnel also publishes all of rex, including the API zurg pushes to: anyone on the internet could add to or delete from that library.
- **Forwarding port 32400 without rex-direct or a certificate of your own.** Plex apps would get a plain HTTP address, which app.plex.tv refuses.

### rex-direct

rex-direct is DMM's answer to plex.direct, and it is on by default. On your router, forward port 32400 (TCP) to the rex machine. That is all, with nothing to restart.

Once claimed, rex gets its own name from DMM, `<hash>.rex-direct.debridmediamanager.com`, pointed at your home's public IP, and a certificate for that name alone. The first certificate takes a few minutes; rex's log says it is being issued and then shows the name in a `rex-direct:` line. rex then announces `https://<hash>.rex-direct.debridmediamanager.com:32400` after the LAN IP. rex asks DMM again every six hours, so a new home IP is picked up by itself, and a renewed certificate too. One Plex account can hold up to ten rex-direct names. At home, Plex apps can pick this name over the LAN IP, and unless you also set up Tailscale serve or Caddy, app.plex.tv in a browser has no other address it can use. So at home your router has to send the connection straight back to rex, or your home DNS has to point the name at rex: [What you should see](#what-you-should-see) checks which.

If your router forwards a different outside port to rex, add `REX_DIRECT_PORT=<that port>` to `rex.env` and restart rex. To use another provider, set `REX_DIRECT_URL` to its `https://` address (`docs/rex-direct-api.md` in rex's repository is the contract), or `REX_DIRECT_URL=off` to turn it off. The port forward does not open the API zurg pushes to: see [Keep the port private](#keep-the-port-private).

### Tailscale serve

Install [Tailscale](https://tailscale.com/download) on the rex machine and on the devices you watch on, signed in to the same account. Then on the rex machine:

```bash
sudo tailscale serve --bg 32400
```

It prints the address, for example `https://myhost.tailnet.ts.net`. Put it first in the `--announce-url` list from [step 2](#step-2-install-rex), with `:443` added, before the LAN IP:

```ini
ExecStart=%h/rex/rust/target/release/rex --catalog rex.db --announce-url https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

**Keep the LAN IP in the list.** Once rex announces, Plex apps take its addresses from plex.tv, and plex.tv lists only what rex announces. Without the LAN IP a TV at home that has no Tailscale can be sent only to the tailnet address and fail to connect.

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
	reverse_proxy 192.168.1.20:32400
}
```

`respond /rex/* 403` keeps the API zurg pushes to off the internet. zurg still reaches it at `http://192.168.1.20:32400`. Then:

```bash
sudo systemctl reload caddy
```

Caddy fetches a certificate when it loads the file and renews it by itself. Make the `ExecStart` list `--announce-url https://rex.example.com:443,http://192.168.1.20:32400`, and restart rex as above.

### A small VPS

For a connection with no public IP (CGNAT). rex has no relay and will not get one, so a server you rent stands in for your router: it has the public IP, and a tunnel from the rex machine carries everything to rex. Any VPS with a public IPv4 works, a few euros a month. **Pick one whose monthly traffic covers what you watch away from home:** every byte passes through it, and a plan with a small data cap will run out. Tested 2026-10-19 with a stand-in VPS: playback and seeking pass through unchanged.

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

`respond /rex/* 403` keeps the API zurg pushes to off the internet. Start `frps -c frps.toml` as a service and run `sudo systemctl reload caddy`.

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

Run it as a service, for example `~/.config/systemd/user/frpc.service` with `ExecStart=%h/frp/frpc -c %h/frp/frpc.toml` and `Restart=always`. Then put the VPS's name first in the `--announce-url` list, add `REX_DIRECT_URL=off` to `~/rex/rex.env` (rex-direct cannot work without a public IP at home, so plex.tv should not list it), and restart rex:

```ini
ExecStart=%h/rex/rust/target/release/rex --catalog rex.db --announce-url https://1-2-3-4.sslip.io:443,http://192.168.1.20:32400
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

With an Intel or AMD graphics chip, also run `sudo usermod -aG render "$USER"` and reboot so the service gets the group; in an LXC, pass the GPU through. The chip makes conversion fast; without one rex uses the processor. With no Intel or AMD chip, rex also tries an NVIDIA card's encoder. On Intel, `sudo apt install intel-opencl-icd` also converts HDR and Dolby Vision on the chip, at about real time for 4K on a small Intel (builds newer than 2026.10.22.0040-nightly); without it they are converted on the processor, which a low-power Intel cannot do in real time at 4K.

**What you should see.** rex's log has a `transcoder:` line naming the FFmpeg and the hardware it found (`hardware none` means the processor). A file that failed before now plays; the log shows what was converted, for example `video=copy h264 audio=ac3->aac 6ch`.

Subtitles in a converted file: an image subtitle is burned into the picture and a subtitle you uploaded comes along. Plex for Android and iOS also keep a text subtitle as a track; other apps get it drawn into the picture. Converted offline downloads still omit text subtitles.

## Subtitles

**What it does.** Search Subtitles in a Plex app finds subtitles from Plex's own provider once rex is claimed. rex checks the one you pick against the file and fixes its timing when it runs late or was made for another frame rate. When your Plex account is set to show subtitles and a title has none in your language, rex looks for one for up to 3 seconds before it starts.

**Why it matters.** We tested 120 files. Where a subtitle's timing could be checked, Plex's own first result was in sync for about half of them and rex's pick was right for about three in four.

There is nothing to set up. rex checks a subtitle against the file's own text subtitle when it has one, which takes a few small reads. A file without one is checked against its sound when you press play, which needs [Converting video](#converting-video-optional) set up and reads six 90-second pieces of the file.

**What you should see.** rex's log has a `SUBTITLE measured` line for each subtitle it checks, and `SUBTITLE applied ... corrected by` when it fixed one.

## Movie and TV capabilities

Use a build newer than 2026.10.22.0040-nightly, or build current `main`. Older downloads do not gain it from a claim change.

Movie-edition editing and the full server Dashboard work with a free claiming account. rex also implements account-owned Downloads with restart recovery, local intro and credits analysis, chapter and 10-second seek thumbnails, subtitle adjustment, hardware and HDR controls, dialogue enhancement and loudness normalization, remote stream limits, tighter local sharing restrictions, local webhooks and source-provided cinema trailers and pre-rolls. `docs/setup.md` in your rex download ("Movie and TV capabilities") gives the settings and owner APIs.

Generation needs FFmpeg and reads source media, uses CPU and keeps files beside the state database. It defaults to off; run Analyze manually or opt in to generation on source additions. Keep `<state>.analysis` and `<state>.downloads` with the state database for durable results.

These are server capabilities, not a Plex subscription. Client account checks, app Downloads eligibility, cloud rollouts and Plex Home membership remain unchanged. Music, Live TV and DVR are not supported.

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

Already run zurg in Docker? rex needs zurg 2026.10.19 or later: `cd ~/zurg && docker compose pull zurg && docker compose up -d zurg`. If `ZURG_TAG` in `~/zurg/.env` names a dated build, set it to `latest` first.

### D2. Start rex in Docker

**What it does.** Runs rex from its image, keeping everything it saves in a folder beside the compose file.

**Why it matters.** It is [step 2](#step-2-install-rex) in one file: the image is the program and Docker keeps it running.

rex's image is private, like zurg's. zurg's Docker installer usually logged Docker in to `ghcr.io` already, and that login works for rex too. If pulling rex is refused, log in once with your GitHub username and a classic personal access token with the `read:packages` and `repo` scopes (the same login zurg's image uses):

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

If `docker ps` says permission denied, put `sudo` before every `docker` command on this page. Docker keeps its login per user, so log in as the same user that runs `docker compose`.

Make a folder, for example `~/rex`, with this `compose.yml`:

```yaml
services:
  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    command: --announce-url http://192.168.1.20:32400
    volumes:
      - ./config:/config
```

- `command:` is [step 2](#step-2-install-rex)'s.
- `network_mode: host` lets Plex apps on your network find rex by themselves, and lets rex reach zurg's container.
- `:nightly` follows the nightly builds; `latest` follows releases only.
- Intel or AMD graphics chip? Add `devices: ["/dev/dri:/dev/dri"]` so rex converts video on it.
- `./config` gets `rex.db` and, later, `claim_state.json`. They are readable by root only, because `rex.db` holds zurg's login.
- Plex Media Server on the same machine? Add `--port 32500` to `command:` and use `32500` wherever this page says `32400`.

```bash
docker compose up -d
docker compose logs -f rex
```

**What you should see.** The same lines as [step 2](#step-2-install-rex), with `seeded /config/rex.db` and `no source yet`. Leave the log open.

### D3. Add it to a Plex account

**What it does.** [Step 3](#step-3-add-it-to-a-plex-account) for the container, done before zurg sends anything so titles arrive with their posters.

Follow step 3: its `curl` commands work as written on this machine. `claim_state.json` appears in `~/rex/config`.

### D4. Connect zurg to rex

**What it does.** Same as [step 4](#step-4-connect-zurg-to-rex). zurg's config sits in zurg's compose folder and belongs to root. Check it first, as in step 4:

```bash
cd ~/zurg
sudo grep -n '^rex_url:\|^dmm_api_key:' config.yml
```

If it prints a line, change that key there with `sudo nano config.yml` and leave it out of the `printf`. Then:

```bash
printf '\nrex_url: http://192.168.1.20:32400\ndmm_api_key: your_dmm_key\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```

**What you should see.** `SOURCES PUT /rex/sources/zurg -> 200` in rex's log, and `curl -s http://192.168.1.20:32400/rex/sources` shows zurg at its **container** address, for example `http://172.18.0.2:9999/dav`. That is right: rex runs on the same machine and reaches the container there.

**zurg and rex on different machines?** rex cannot reach that container address. Give the zurg container `network_mode: host` (and remove its `ports:` lines) so it registers the machine's LAN IP instead.

### D5. Watch

rex's log names each title as zurg reads it, as in [step 4](#step-4-connect-zurg-to-rex). Open a Plex app on your network as in [step 5](#step-5-watch-something).

**What you should see.** The titles appear in **Movies** and **TV Shows**, and `docker compose restart rex` brings them back with `state file /config/rex.db: restored` and `source zurg: registered`.

### D6. Update

```bash
cd ~/rex && docker compose pull && docker compose up -d
```

rex comes back with the same library. `nightly` moves with each nightly build and `latest` with each release; pin a version to update only when you choose. For zurg, see [Managing and updating zurg](../setup/docker.md#managing-and-updating-zurg).

The image carries jellyfin-ffmpeg, so [converting video](#converting-video-optional) needs only the graphics chip handed in (images newer than 2026.10.22.0040-nightly). HTTPS works as above: the options run on the machine itself, and `--announce-url ...` goes in `command`.

## Keep the port private

rex takes no password from zurg. It answers the API zurg pushes to only from this machine, your home network and Tailscale, so forwarding rex's port for [rex-direct](#rex-direct) does not open it. A router that gives outside visitors its own address makes them look local, and that opens the feed to the internet. A proxy on the rex machine looks local to rex, so keep `/rex/*` blocked in any proxy that faces the internet, as the [Caddy](#caddy) example does.

## Updating

- **zurg:** `cd ~/zurg && ./zurg update && ./zurg service restart`.
- **rex:** run the first block of [step 2](#step-2-install-rex) again (it replaces the program and `data/`, and leaves `rex.db`, `rex.env` and `claim_state.json` alone), then `systemctl --user restart rex`.
- **Coming from an older rex?** `TMDB_KEY`, `REX_METADATA_URL` and `REX_METADATA_KEY` are no longer read; delete them from `rex.env` or leave them, rex starts either way. Claim rex, or titles lose their posters and matches; add `dmm_api_key` to zurg for DMM's matches.

## When something is wrong

| What you see | What to do |
|---|---|
| `/rex/sources` stays `{"size":0,"sources":[]}` | zurg is older than 2026.10.19, `rex_url` is wrong, or zurg's library is still loading. Update zurg as in [step 1](#step-1-install-zurg) and look at `tail -n 50 ~/zurg/logs/zurg.log` |
| rex's log says `held ... no media_info yet` and the library stays empty | zurg has not read the files yet. Wait for its library to load; if zurg logs `segmentation fault`, update and restart it as in [step 1](#step-1-install-zurg) |
| Titles show file names and no posters | rex is not on a Plex account: do [step 3](#step-3-add-it-to-a-plex-account). If you claimed it after zurg sent them, they fill in by themselves, about 300 films or shows an hour |
| A film is titled as its file, or an episode sits in a show named after its release | zurg could not place it. Without `dmm_api_key` that is a name its title search did not find; with it, DMM has not placed it yet and zurg asks again a day later. **Fix Match** fixes it by hand |
| A title is in the wrong show or matched to the wrong film | DMM placed it wrong, and zurg does not ask again. Use **Fix Match** in a Plex app, signed in as the fresh account that owns rex; rex refuses it (403) to the accounts it is shared with |
| Nothing plays and rex's log shows 502 | rex cannot reach the address zurg gave it. Run `curl` on that URL from the rex machine. In Docker, see the Docker section |
| Nothing plays and rex's log shows `PART ... upstream 401` or `403` | zurg refused its own login. Restart zurg (`cd ~/zurg && ./zurg service restart`) so it sends rex the current one |
| "This server is not powerful enough to convert video" | The device cannot play the file as it is. Try a Plex app on a TV or phone, or set up [Converting video](#converting-video-optional) |
| rex exits with `unrecognized arguments` | Your `rex.service` or `run.sh` still passes `--sources` from an older setup. Remove it; an old `REX_FEED_TOKEN` in `rex.env` is ignored |
| After adding an HTTPS address, a device at home cannot connect | The LAN IP is missing from `--announce-url`. Add `http://192.168.1.20:32400` after the HTTPS one |
| rex is not in the Plex apps away from home | Not claimed, no `--announce-url`, or the device cannot reach the HTTPS address (a tailnet-only address needs Tailscale on that device) |
| The log says `waiting for a claim` | Claim it. It announces right away |
| zurg stops when you log out | Run `sudo loginctl enable-linger "$USER"` (step 1) |
| zurg will not start after you edited `config.yml` | A zurg older than 2026.10.17 wrote the file without a final newline, so the added line joined the last one: put it on its own line. Or the key was already in the file and zurg reports `mapping key "..." already defined`: delete one of the two |
