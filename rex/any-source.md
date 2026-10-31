# rex with your own app

[rex](https://rex.debridmediamanager.com) is a media server for the official Plex apps that owns no files. The official Plex apps see it as a normal Plex server. Another program, which this page calls **your app**, tells rex what is in your library and serves the files. When you press play, rex streams the file straight from your app. Nothing is downloaded first.

This page takes you from nothing to playing a movie, one step at a time. It does not assume any particular app. It says exactly what rex expects from one, so you can check that yours does it, or build one. Every step says what it does, why it matters and what you should see before you move on.

Four things to know before you start:

- **Your app serves the files.** rex fetches every byte from your app over HTTP or HTTPS, the way a browser downloads a file. rex keeps no files and needs no disk or mount for media.
- **Your app tells rex what it has.** It sends rex a list of files over rex's feed API, and every change after that. rex never lists a folder or scans anything.
- **Your app decides what each file is.** It says whether a file is a movie or an episode, which title it belongs to (by IMDb and TMDB id) and, for an episode, its season and number. rex never guesses from a file name.
- **Plex describes it.** Once rex is on a Plex account, it shows each title with the name, poster, summary and episode names Plex's own metadata has for those ids. For things no Plex agent knows, your app names them itself: see [Building rex addons](addons.md).

rex is free for personal use (PolyForm Noncommercial): no sponsor tier and no account needed to download it. See [rex.debridmediamanager.com](https://rex.debridmediamanager.com).

## Before you start

| You need | Why |
|---|---|
| rex's nightly dated 2026.10.25 or newer | Step 1 downloads the newest |
| A machine that stays on: Linux (Ubuntu 22.04 or newer), macOS, or Windows (64 bit) | rex is a server: your Plex apps reach it whenever you press play. Where the commands differ, a step has a tab for each system. [Docker](#run-rex-in-docker) is further down, for Linux |
| 1 GB of RAM | With 4,062 movies and 656 shows (34,678 episodes), rex used under 500 MB while it started and about 730 MB while the library was browsed. Converting video takes more, and more cores or a graphics chip |
| An app that does what [What your app must do](#what-your-app-must-do) lists | That is where your library comes from |
| Your app pushing from this machine, your home network or Tailscale | rex takes the feed only from there ([Keep the port private](#keep-the-port-private)). An app on a seedbox or a cloud server cannot push to rex unless that server is on your tailnet; the files themselves can be served from anywhere rex reaches |
| Files on this machine's disks? Something that serves them over HTTP and pushes them | rex never reads a disk. [Step 2](#step-2-see-it-work-by-hand) does it by hand for one file; otherwise keep Plex for those |
| Usenet? A source that reads it, such as zurg | rex never talks to a Usenet provider. zurg is a source that does: see [rex with zurg](with-zurg.md) |
| A fresh Plex account, made just for rex | rex gets every title, poster, summary and episode name from Plex once it is [added to a Plex account](#step-3-add-it-to-a-plex-account). Until then titles keep their file names and have no posters |

## What your app must do

Give this list to whoever makes your app. rex's own API reference is [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

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

**What it does.** Downloads rex into `~/rex` (`$HOME\rex` on Windows) and starts it as a service, with everything the later steps need. The steps after this one need no restart; only the optional sections further down do.

**Why it matters.** rex is what your Plex apps talk to. The first start creates `rex.db`, which holds your libraries, everything your app sends and your watch history.

+++ Linux and macOS
```bash
mkdir -p ~/rex && cd ~/rex
TAG=$(curl -fsSL 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1' | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
P=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -fL "https://github.com/debridmediamanager/rex/releases/download/$TAG/rex-$TAG-$P.tar.gz" | tar xz --strip-components=1
```
+++ Windows
In PowerShell:

```powershell
New-Item -ItemType Directory -Force $HOME\rex | Out-Null; cd $HOME\rex
$tag = (Invoke-RestMethod 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1')[0].tag_name
curl.exe -fLO "https://github.com/debridmediamanager/rex/releases/download/$tag/rex-$tag-windows-amd64.zip"
tar -xf "rex-$tag-windows-amd64.zip" --strip-components=1; Remove-Item "rex-$tag-windows-amd64.zip"
```
+++

This takes rex's newest build, usually a nightly, for your machine.

Find rex's LAN IP, its address on your home network. On Linux `hostname -I` prints several: take the one on your home network, not one starting with `172.17.` (Docker) or `100.` (Tailscale). On macOS `ipconfig getifaddr en0` prints it (`en1` if that prints nothing). On Windows `ipconfig` lists it as **IPv4 Address** under your Wi-Fi or Ethernet adapter. **This page writes it as `192.168.1.20` everywhere: put yours in its place.** Plex apps, your app and your own commands all reach rex there.

**Plex Media Server runs on the same machine?** End rex's start command below with `--port 32500` and use `32500` wherever this page says `32400`, the Windows firewall rule included: Plex already holds port 32400 and the ports apps use to find servers, and on any other port rex leaves those to Plex.

Now make it a service:

+++ Linux
Create `~/.config/systemd/user/rex.service`:

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

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
sudo loginctl enable-linger "$USER"
journalctl --user -u rex -f
```

rex's **start command** is the `ExecStart` line, and keys go in `~/rex/rex.env`, one `NAME=value` a line. After a change, `systemctl --user daemon-reload && systemctl --user restart rex` restarts rex. `journalctl --user -u rex -f` shows its log. `loginctl enable-linger` keeps rex running when you log out.
+++ macOS
`run.sh` starts rex in its folder, and a LaunchAgent starts `run.sh` when you log in:

```bash
cp ~/rex/examples/run.sh.example ~/rex/run.sh
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.rex.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.rex</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$HOME/rex/run.sh</string></array>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$HOME/rex/rex.log</string>
  <key>StandardErrorPath</key><string>$HOME/rex/rex.log</string>
</dict></plist>
PLIST
launchctl load ~/Library/LaunchAgents/com.rex.plist
tail -F ~/rex/rex.log
```

rex's **start command** is the last line of `~/rex/run.sh`, and keys go in `~/rex/rex.env`, one `NAME=value` a line. After a change, `launchctl kickstart -k gui/$(id -u)/com.rex` restarts rex. `tail -f ~/rex/rex.log` shows its log.

rex runs while you are logged in to the Mac. For a Mac that restarts by itself, turn on automatic login (**System Settings**, **Users & Groups**). If the macOS firewall is on, allow rex when macOS asks, or add `~/rex/rust/target/release/rex` under the firewall's **Options**.
+++ Windows
Open PowerShell **as administrator** and go to rex's folder with `cd $HOME\rex`. First make `run.cmd`, which starts rex in its folder and writes its log to `rex.log`. Notepad offers to create the file:

```powershell
notepad run.cmd
```

```bat
@echo off
cd /d "%~dp0"
rust\target\release\rex.exe 2>> rex.log
```

Save it. Then let your network through Windows Firewall to rex's port and the two discovery ports, and start rex now and whenever you log in:

```powershell
New-NetFirewallRule -DisplayName rex -Protocol TCP -LocalPort 32400
New-NetFirewallRule -DisplayName "rex discovery" -Protocol UDP -LocalPort 32410,32414
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask rex -Action (New-ScheduledTaskAction -Execute "$HOME\rex\run.cmd") -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) -Settings $settings
Start-ScheduledTask rex; Start-Sleep 3
Get-Content rex.log -Wait
```

rex's **start command** is the `rex.exe` line of `run.cmd`, and keys go above it, one `set NAME=value` a line. After a change, `Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex` restarts rex. `Get-Content $HOME\rex\rex.log -Wait` shows its log.

rex runs while you are logged in to Windows, in a window of its own: leave it open. In PowerShell, type `curl.exe` wherever this page says `curl`: Windows PowerShell's own `curl` is a different command.
+++

**What you should see.** Among the first lines:

```
INFO    seeded rex.db: an empty library named yourhost, machine=...
INFO    no source yet: a source registers itself once pointed at this server (PUT /rex/sources/{name}, docs/feed-api.md)
INFO    claim state: unclaimed
INFO    rex on http://192.168.1.20:32400  machine=...  items=0  parts=proxy
```

rex names itself after the machine; your Plex apps show that name. `no source yet` is right: no app has registered yet. Leave the log open.

## Step 2. See it work by hand

**What it does.** Plays the part of your app for one movie, with a throwaway file server and two `curl` commands.

**Why it matters.** It proves rex works on this machine before your app is involved. If this step works and your app does not, the problem is in your app. Skip it if your app is already set up.

You need `ffprobe`, a small web server and one video file. You register the file's folder with rex under the name `test`, then send rex the file, saying it is the movie Sintel (IMDb `tt1727587`, TMDB `45745`) with ffprobe's output.

+++ Linux and macOS
Install `ffprobe` and `jq` (`sudo apt install -y ffmpeg jq` on Linux, `brew install ffmpeg jq` on macOS). Put the file where a small web server can serve it:

```bash
mkdir -p ~/rex-test/movies/Sintel.2010
cp /path/to/any-video.mkv ~/rex-test/movies/Sintel.2010/Sintel.2010.mkv
cd ~/rex-test
python3 -m http.server 8099 --bind 127.0.0.1 &
```

Register it with rex:

```bash
curl -s -X PUT http://192.168.1.20:32400/rex/sources/test \
  -H 'Content-Type: application/json' -d '{"url": "http://127.0.0.1:8099"}'
```

Send rex the file:

```bash
P=movies/Sintel.2010/Sintel.2010.mkv
jq -n --arg p "$P" \
  --argjson probe "$(ffprobe -v quiet -print_format json -show_format -show_streams "$P")" \
  '{items: [{id: $p, path: $p, kind: "movie", ids: {imdb: "tt1727587", tmdb: 45745}, media_info: $probe}]}' \
| curl -s -X POST http://192.168.1.20:32400/rex/feed/test/items \
    -H 'Content-Type: application/json' --data-binary @-
```
+++ Windows
Install `ffprobe` and Python with `winget install Gyan.FFmpeg` and `winget install Python.Python.3.13`, then open a new PowerShell window. Put the file where a small web server can serve it:

```powershell
New-Item -ItemType Directory -Force $HOME\rex-test\movies\Sintel.2010 | Out-Null
Copy-Item C:\path\to\any-video.mkv $HOME\rex-test\movies\Sintel.2010\Sintel.2010.mkv
cd $HOME\rex-test
$server = Start-Process py '-m http.server 8099 --bind 127.0.0.1' -WindowStyle Hidden -PassThru
```

Register it with rex:

```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/test -ContentType application/json -Body '{"url": "http://127.0.0.1:8099"}'
```

Send rex the file:

```powershell
$p = 'movies/Sintel.2010/Sintel.2010.mkv'
$probe = ffprobe -v quiet -print_format json -show_format -show_streams $p | Out-String | ConvertFrom-Json
$item = @{ id = $p; path = $p; kind = 'movie'; ids = @{ imdb = 'tt1727587'; tmdb = 45745 }; media_info = $probe }
Invoke-RestMethod -Method Post http://192.168.1.20:32400/rex/feed/test/items -ContentType application/json -Body (ConvertTo-Json @{ items = @($item) } -Depth 20)
```

PowerShell shows rex's answers as lists rather than JSON.
+++

**What you should see.** The answer is `{"created":1,"updated":0,"held":0,"unchanged":0}` and rex's log prints:

```
INFO    FEED identified "Sintel.2010" -> movie tmdb:45745 (placed)
INFO    FEED test upsert: 1 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Sintel is now in **Movies**, playing from the little web server. No Plex app can open rex before [step 3](#step-3-add-it-to-a-plex-account), so this step checks the feed only.

**Clean up** before you go on: removing the test source removes everything it sent. The first request answers a `confirm` path; send a `DELETE` to that path within five minutes.

+++ Linux and macOS
```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/test
curl -s -X DELETE "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
kill %1
```
+++ Windows
```powershell
Invoke-RestMethod -Method Delete http://192.168.1.20:32400/rex/sources/test
Invoke-RestMethod -Method Delete "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
Stop-Process -InputObject $server
```
+++

**If not.**

- `"held":1`: `media_info` is missing or has no streams. Check that `ffprobe` printed JSON for the file.
- An answer with `rejected`: the file is not a video by its extension, is a sample, has no `id` or `path`, has a malformed path, or another `id` already has its path. The answer and rex's log give each reason.
- `404 no such source`: the `PUT /rex/sources/test` did not happen first.

## Step 3. Add it to a Plex account

**What it does.** Registers rex on a Plex account, as you would a real Plex Media Server, and shares it with your own account.

**Why it matters.** rex gets every title's name, poster, summary and episode names from Plex's own metadata, and it may only ask Plex once it is on an account. What your app sends before the claim is named as soon as it lands, and Fix Match has nothing to offer until then. It also removes the "unclaimed" notice and is needed before [using rex outside your home](#use-it-outside-your-home-optional).

**Use a fresh Plex account for this, not your own.** rex is not made by Plex, and Plex could take action against an account that registers it. Keep your real account, with its watch history, friends and any Plex Pass, out of reach: make a new free account at [plex.tv](https://www.plex.tv) with an email address you do not use elsewhere, register rex on that one, and share rex with your own account. You then watch signed in as yourself, the way you would watch a friend's server. rex plays nothing until this step is done.

### Register rex on the fresh account

1. Sign in to [plex.tv](https://www.plex.tv) **as the fresh account**, open [plex.tv/claim](https://www.plex.tv/claim) and copy the code. It expires after about five minutes.
2. On the rex machine (`curl.exe` on Windows):

   ```bash
   curl -X POST "http://192.168.1.20:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://192.168.1.20:32400/identity
   ```

**What you should see.** The second command shows `claimed="1"`, and `claim_state.json` exists in rex's folder. Back that file up: without it rex has to be claimed again, and rex refuses a second claim while the file is there. From now on titles arrive with their names and posters, without a restart.

**If not.**

- The first command answers `409` with `rex: already claimed`: rex is on a Plex account already.
- It answers `500 Internal Server Error` and rex logs `claim exchange failed`: the code expired or was used. Get a new one from [plex.tv/claim](https://www.plex.tv/claim).

### Share it with your own account

1. Still signed in as the fresh account, open [app.plex.tv](https://app.plex.tv), then **Settings** (the wrench), **Manage Library Access** and **Grant Library Access**.
2. Enter your own account's username or email, pick the rex server and both libraries, **Movies** and **TV Shows**, and send the invite.
3. Sign out, sign in as **yourself**, and accept the invite. It arrives by email and in app.plex.tv.

![Manage Library Access in app.plex.tv's settings, with the Grant Library Access button](../assets/rex/20-plex-manage-library-access.webp)

![The Grant Library Access dialog with the rex server's Movies and TV Shows ticked](../assets/rex/21-plex-grant-library-access.webp)

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

`held` files are waiting for their ffprobe output and appear as soon as your app sends it. Check what rex has from your app at any time (on Windows, `curl.exe` without `| head -c 600`):

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

![A Plex app showing the rex server's Movies and TV Shows in the sidebar beside a grid of films](../assets/rex/10-plex-server-libraries.webp)

At home nothing else is needed: Plex apps find rex with Plex's own local discovery and connect to it over your network. That needs the device on the same network as rex (not a guest Wi-Fi or a separate VLAN). Discovery runs on UDP ports 32410 and 32414, so a firewall on the rex machine must let those in (on Windows, step 1's firewall rules do). rex answers discovery when it uses port 32400. If you moved rex to 32500 because Plex runs on the same machine, discovery is left to that Plex, and apps find rex through the Plex account it is [shared with](#share-it-with-your-own-account). app.plex.tv in a web browser is the exception: it needs the HTTPS address from [Use it outside your home](#use-it-outside-your-home-optional), even at home. `http://192.168.1.20:32400/web` is not Plex Web: rex has no web app of its own, and that page only says whether rex is claimed and where to watch.

**What you should see.** Posters, titles and years as on any Plex server. Playback starts within a few seconds.

Two things you may meet:

- **"yourhost server is unclaimed and not secure".** A Plex app says this about any server that is not on a Plex account, and rex plays nothing until it is on one. Do [step 3](#step-3-add-it-to-a-plex-account).
- **"This server is not powerful enough to convert video".** The app cannot play the file as it is, often a web browser meeting AC3 or DTS sound. Plex apps on TVs and phones play most files as they are. To play everything everywhere, set up [Converting video](#converting-video-optional).

**Deleting deletes at your app.** Signed in as the fresh account, **Delete** on a title in a Plex app has rex ask your app to delete the file, as [What your app must do](#what-your-app-must-do) says. The accounts rex is shared with cannot delete. To turn deleting off: in app.plex.tv as the fresh account, open **Settings**, the rex server's **Library**, **Show Advanced**, untick **Allow media deletion** and save.

![The rex server's Library settings with Show Advanced open and Allow media deletion outlined](../assets/rex/32-plex-allow-media-deletion.webp)

A file your app removes goes to the library's trash as it would in Plex: it stays, unavailable, with its watch history, and comes back as it was if your app sends it again. **Empty Trash** on the library removes it for good, and **Empty trash automatically after every scan** (Settings, Library), which is off, does that by itself.

Each file goes to **Movies** or **TV Shows** by the `kind` your app sent. A file without one goes by its first folder: `shows` to TV Shows, anything else to Movies.

To give a folder libraries of its own, your app adds `directories` to its registration, naming the first folder of the files' paths and the libraries' titles: `{"url": ..., "directories": [{"name": "anime", "shows": "Anime", "movies": "Anime Movies"}]}`, either title alone being fine. rex makes them when your app registers and moves what that folder already has into them as it was: watch history, Fix Match and edits included. A malformed entry is skipped and listed under `ignored` in the answer, with why. Rename them in a Plex app as you like. Delete one and it stays deleted, its files going back to Movies or TV Shows, until you add it again with **Add Library**, whose folder list shows your app's folders. [Libraries a source declares](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md#libraries-a-source-declares) has the rules.

**Back up** `rex.db` in rex's folder (it holds your library, watch history and your app's login, so keep it private), `claim_state.json` and, once rex-direct has given rex a name, `rex-direct.json` (its certificate key):

+++ Linux and macOS
```bash
sudo apt install -y sqlite3    # once, on Linux; macOS has it
mkdir -p ~/rex-backup
sqlite3 ~/rex/rex.db ".backup $HOME/rex-backup/rex.db"
cp ~/rex/*.json ~/rex-backup/
```
+++ Windows
Windows has no `sqlite3`, so stop rex for a moment and copy `rex.db` with the two files beside it that start the same way:

```powershell
Stop-Process -Name rex; Start-Sleep 1
New-Item -ItemType Directory -Force $HOME\rex-backup | Out-Null
Copy-Item $HOME\rex\rex.db*, $HOME\rex\*.json $HOME\rex-backup
Start-ScheduledTask rex
```
+++

In Docker the files sit in `~/rex/config`, readable by root only. Back up from inside the container with `docker exec rex sqlite3 /config/rex.db ".backup /config/rex.db.bak"`, then `mkdir -p ~/rex-backup && sudo cp ~/rex/config/rex.db.bak ~/rex/config/*.json ~/rex-backup/`.

[Restore a backup](#restore-a-backup) puts them back.

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

If your router forwards a different outside port to rex, add the key `REX_DIRECT_PORT=<that port>` as [step 1](#step-1-install-rex) shows for your system and restart rex. The port forward does not open the feed API: see [Keep the port private](#keep-the-port-private).

### Tailscale serve

Install [Tailscale](https://tailscale.com/download) on the rex machine and on the devices you watch on, signed in to the same account. Then on the rex machine:

```bash
sudo tailscale serve --bg 32400
```

On Windows, run it in PowerShell as administrator without `sudo`. On macOS, use the Tailscale app's [command-line tool](https://tailscale.com/kb/1080/cli) without `sudo`.

It prints the address, for example `https://myhost.tailnet.ts.net`. Give it to rex with `:443` added: end rex's start command from [step 1](#step-1-install-rex) with `--announce-url https://myhost.tailnet.ts.net:443`, and restart rex.

Everyone on your tailnet, including anyone you share this machine with, can use rex's feed API. Share the machine only with people you trust.

### Caddy

You need port 443 on your router forwarded to the rex machine, and a name for your home's IP address:

- **Your own domain:** an `A` record such as `rex.example.com` pointing at your home IP.
- **No domain:** use `1-2-3-4.sslip.io` with your public IP's numbers (`curl -s ifconfig.me` shows it). If your IP changes, update the name.

Install [Caddy](https://caddyserver.com/docs/install) and give it this Caddyfile (`/etc/caddy/Caddyfile` with Caddy's Linux package; on macOS and Windows a file named `Caddyfile` in a folder of its own, which `caddy run` in that folder reads):

```
rex.example.com {
	respond /rex/* 403
	reverse_proxy 192.168.1.20:32400
}
```

`respond /rex/* 403` keeps the feed API off the internet; your app still reaches rex directly. Then reload Caddy (`sudo systemctl reload caddy` with the Linux package). On macOS and Windows, start `caddy run` in its folder instead and keep it running the way [step 1](#step-1-install-rex) keeps rex; on Windows, also let TCP port 443 through the firewall as step 1 does for 32400. Then end rex's start command with `--announce-url https://rex.example.com:443`, and restart rex.

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

Run it as a service: on Linux, for example `~/.config/systemd/user/frpc.service` with `ExecStart=%h/frp/frpc -c %h/frp/frpc.toml` and `Restart=always`; on macOS and Windows, start `frpc -c frpc.toml` the way [step 1](#step-1-install-rex) starts rex. Then end rex's start command with `--announce-url https://1-2-3-4.sslip.io:443`, add the key `REX_DIRECT_URL=off` (rex-direct cannot work without a public IP at home, so plex.tv should not list it), and restart rex.

### What you should see

```bash
curl -s https://myhost.tailnet.ts.net/identity
```

shows a short XML page with rex's `machineIdentifier` on a computer at home; `curl` shows nothing when the address or its certificate is wrong. Use your own address: with rex-direct it is the one in rex's `rex-direct: https://...` log line, with `/identity` added. Open the same address in a phone's browser with Wi-Fi off: it shows a short XML page with no certificate warning. With Tailscale serve, both the computer and the phone need Tailscale on.

With rex-direct or Caddy, if the phone gets it and the computer at home does not, your router does not send connections back inside. Point the name at rex's LAN IP in your home network's DNS (your router's, or Pi-hole's; a router with DNS rebind protection needs an exception for it) and the rex machine answers it at home with the same certificate. If the phone fails too, the port is not forwarded, your connection is behind CGNAT, or rex-direct's certificate is still being issued (rex's log says so while it is).

rex's log names the addresses it announces:

```
INFO    heartbeat every 600s for machine ... -> https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

rex prints this at every start. Trouble shows later as `heartbeat failed` or `announced but NOT visible`. Otherwise the server lists those addresses on plex.tv, and a Plex app away from home picks the one it can reach. If rex logs `waiting for a claim`, do [step 3](#step-3-add-it-to-a-plex-account) first.

## Your watch history from another Plex server (optional)

Watched on another Plex server before? Once your library is in rex, [Bring your watch history](import-watched.md) copies what you watched, where you stopped and your star ratings from it, for each person on their own.

## Converting video (optional)

**What it does.** Lets rex convert what a device cannot play, the way Plex does.

**Why it matters.** Without it a device that cannot play a file as it is gets "This server is not powerful enough to convert video". Web browsers hit this most, for example with AC3 or DTS sound.

Install **jellyfin-ffmpeg** 8, not the `ffmpeg` your system offers: it is the build rex is measured with and the only one that converts every Dolby Vision file, tonemaps HDR on the graphics chip and draws subtitles there. Another FFmpeg converts ordinary video and rex's log says what it lacks (Ubuntu 22.04's own also seeks a few seconds off). rex finds it on its own.

+++ Linux
The package goes in `/usr/lib/jellyfin-ffmpeg` beside any other FFmpeg. The first line picks the build for your system: there are builds for Ubuntu 22.04, 24.04 and 26.04 and Debian 12 and 13, on amd64 or arm64, and on any other `curl` stops with an error.

```bash
DEB=jellyfin-ffmpeg8_8.1.3-1-$(. /etc/os-release; echo "$VERSION_CODENAME")_$(dpkg --print-architecture).deb
curl -fLO "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/$DEB"
sudo apt install -y "./$DEB" && rm "$DEB"
systemctl --user restart rex
```

On another Linux, unpack jellyfin-ffmpeg's portable build into `~/rex/ffmpeg`, where rex looks for it, and restart rex. It uses your system's own graphics driver, so on an older system it converts on the processor only; use the package wherever there is one.

```bash
B=$( [ "$(uname -m)" = aarch64 ] && echo linuxarm64 || echo linux64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
```

With an Intel or AMD graphics chip, also run `sudo usermod -aG render "$USER"` and reboot so the service gets the group; in an LXC, pass the GPU through. The chip makes conversion fast; without one rex uses the processor. With no Intel or AMD chip, rex also tries an NVIDIA card's encoder. On Intel, `sudo apt install intel-opencl-icd` also converts HDR and Dolby Vision on the chip, at about real time for 4K on a small Intel; without it they are converted on the processor, which a low-power Intel cannot do in real time at 4K.
+++ macOS
The portable build goes into `~/rex/ffmpeg`, where rex looks for it:

```bash
B=$( [ "$(uname -m)" = arm64 ] && echo macarm64 || echo mac64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
launchctl kickstart -k gui/$(id -u)/com.rex
```

On a Mac rex always converts on the processor: it has no way to use a Mac's graphics chip.
+++ Windows
The portable build goes into an `ffmpeg` folder in rex's folder, where rex looks for it:

```powershell
cd $HOME\rex
curl.exe -fLO https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Expand-Archive jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip ffmpeg
Remove-Item jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex
```

On Windows rex converts on an NVIDIA card's encoder when there is one, and on the processor otherwise.
+++

**What you should see.** rex's log has a `transcoder:` line naming the FFmpeg and the hardware it found (`hardware none` means the processor). A file that failed before now plays; the log shows what was converted, for example `video=copy h264 audio=ac3->aac`.

Subtitles in a converted file: an image subtitle is burned into the picture and a subtitle you uploaded comes along. Plex for Android and iOS also keep a text subtitle as a track; other apps get it drawn into the picture. Converted offline downloads still omit text subtitles.

## Subtitles

**What it does.** Search Subtitles in a Plex app finds subtitles from Plex's own provider once rex is claimed. rex checks the one you pick against the file and fixes its timing when it runs late or was made for another frame rate. When your Plex account is set to show subtitles and a title has none in your language, rex looks for one for up to 3 seconds before it starts.

**Why it matters.** Plex's own first result is often out of sync with the file.

![The Subtitles search dialog in a Plex app, listing English results for Sintel](../assets/rex/51-plex-search-subtitles.webp)

There is nothing to set up. rex checks a subtitle against the file's own text subtitle when it has one. A file without one is checked against its sound when you press play, which needs [Converting video](#converting-video-optional) set up and reads six 90-second pieces of the file.

**What you should see.** rex's log has a `SUBTITLE measured` line for each subtitle it checks, and `SUBTITLE applied ... corrected by` when it fixed one.

## Movie and TV capabilities

Downloads, intro and credits detection, seek thumbnails and the other Plex server features rex has, and their settings, are in [rex's setup guide](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities). Music, Live TV and DVR are not supported.

## Run rex in Docker

These steps are for a Linux machine. On macOS and Windows, Docker Desktop runs containers inside a virtual machine, so host networking, LAN discovery and the graphics chip do not work there as they do on Linux: use the steps above instead.

rex's Docker image is private, so pulling it may be refused. The download in [step 1](#step-1-install-rex) works for everyone: if the pull is refused, use the steps above.

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

rex never updates itself. Run the download block of [step 1](#step-1-install-rex) again (it replaces the program and `data/`, and leaves `rex.db`, your keys, `claim_state.json` and `rex-direct.json` alone), then restart rex as step 1 shows. On Windows, run `Stop-Process -Name rex` before the download block, as Windows does not let a running `rex.exe` be replaced, and `Start-ScheduledTask rex` after it.

## Later: restore, move, remove

### Restore a backup

Stop rex, delete `rex.db` and the `rex.db-wal` and `rex.db-shm` beside it, put your backup's files in rex's folder and start rex. Leaving the old `rex.db-wal` in place undoes the restore.

+++ Linux
```bash
systemctl --user stop rex
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
systemctl --user start rex
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
launchctl load ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
```powershell
Stop-Process -Name rex; Start-Sleep 1
Remove-Item $HOME\rex\rex.db*
Copy-Item $HOME\rex-backup\* $HOME\rex
Start-ScheduledTask rex
```
+++ Docker
```bash
cd ~/rex && docker compose down
sudo rm -f config/rex.db config/rex.db-wal config/rex.db-shm
sudo cp ~/rex-backup/rex.db.bak config/rex.db && sudo cp ~/rex-backup/*.json config/
docker compose up -d
```
+++

### Move rex to another machine

Back up as in [step 5](#step-5-watch-something), then stop rex on the old machine for good, as the first block of [Remove rex](#remove-rex) does. On the new one, do [step 1](#step-1-install-rex), but copy your backup's files into rex's folder before you make it a service. It is the same server to your Plex apps, still claimed and shared. Then:

- Give your app the new LAN IP, as in [step 4](#step-4-connect-your-app).
- Move your router's port forward to the new machine. The rex-direct name stays the same and follows a new public IP by itself. Tailscale serve and Caddy are set up again on the new machine.

### The fresh Plex account is gone

If the account rex is claimed with is lost or banned, make another fresh account, stop rex, delete `claim_state.json` in rex's folder, start rex and do [step 3](#step-3-add-it-to-a-plex-account) again: claim, then share with everyone again. The library, Fix Match, edits and the rex-direct name stay, and each person's watch history comes back once rex is shared with their account again.

### Which rex do I run?

rex has no version command. The nightly's date is in the name of the download (`2026.10.30.0040-nightly`), and the program file carries the same date: `ls -l ~/rex/rust/target/release/rex` (on Windows `(Get-Item $HOME\rex\rust\target\release\rex.exe).LastWriteTime`). The Plex version your apps show is not rex's: rex reports the current Plex Media Server version on purpose, so the apps treat it as up to date, and **Check for Updates** always says it is.

### Remove rex

Stop rex for good:

+++ Linux
```bash
systemctl --user disable --now rex && rm ~/.config/systemd/user/rex.service
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist && rm ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
In PowerShell as administrator:

```powershell
Unregister-ScheduledTask rex -Confirm:$false; Stop-Process -Name rex
Remove-NetFirewallRule -DisplayName rex, "rex discovery"
```
+++ Docker
```bash
cd ~/rex && docker compose down
```
+++

Then stop your app pushing to rex. In app.plex.tv as the fresh account, open **Settings**, **Authorized Devices**, filter by **Servers** and remove rex. Remove your router's port forward, and delete rex's folder.

### Getting help

Ask in the DMM [Discord](https://discord.com/invite/7u4YjMThXP)'s **rex-support** forum: [Getting help](../guides/remote-help.md) says what to include, and how sponsors get remote help.

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
| A device at home cannot connect, and rex's `heartbeat ... ->` line shows no `http://192.168.1.20:32400` | rex announces the private address of the network it reaches the internet through; behind a VPN or a Tailscale exit node that is not your home network. End rex's start command ([step 1](#step-1-install-rex)) with `--announce-url http://192.168.1.20:32400` and restart rex |
| Another machine cannot reach rex on Windows, although step 1's firewall rules exist | If you ever clicked **Cancel** when Windows asked whether to allow rex, Windows saved a rule that blocks it, and that wins over the port rules. Remove it in PowerShell as administrator: <code>Get-NetFirewallApplicationFilter -Program "$HOME\rex\rust\target\release\rex.exe" &#124; Get-NetFirewallRule &#124; Where-Object Action -eq Block &#124; Remove-NetFirewallRule</code> |
| rex is not in the Plex apps away from home | Not claimed, or the device cannot reach the HTTPS address |
| rex exits with `argument --announce-url: '...' is not an http:// or https:// address` | Give `--announce-url` the address alone, such as `https://myhost.tailnet.ts.net:443`: no brackets, quotes or link around it |
| rex stops when you log out | On Linux, run `sudo loginctl enable-linger "$USER"` (step 1). On macOS and Windows, rex as step 1 sets it up runs while you are logged in |
