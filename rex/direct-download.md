---
label: Apps download from your provider
icon: download
order: 55
---

# Apps download from your provider

Normally every movie you play goes through rex: rex reads it from your source and passes it to the Plex app. When your source answers with a link to the file instead, such as your debrid service's download link, rex can hand the app that link. The Plex app then downloads the file from there itself, and the rex machine carries none of the movie.

It works when the app plays the file as it is (direct play). Anything rex has to convert for an app still goes through rex, or, if you choose, is refused.

Tested on 2026-10-25 with zurg on Real-Debrid, Plezy and Plex for Android on a Pixel 6, and Plex Web in Chrome.

## Before you start

| You need | Why |
|---|---|
| rex set up as in [rex with your own app](any-source.md), [rex with your Stremio addons](stremio.md) or [rex with zurg](with-zurg.md), and a movie that plays | This page changes rex's start command and, for some sources, one of the source's settings |
| rex nightly **2026.10.26 or newer** | Older builds do not have this setting. Update as in [rex's Updating section](any-source.md#updating) |
| A source that can answer with a link | rex can only pass on a link the source gives it. [Step 1](#step-1-let-your-source-hand-out-links) says which sources do |

## Choose how strict

| | `redirect` | `redirect-only` |
|---|---|---|
| An app plays the file as it is | The app downloads from your provider | The app downloads from your provider |
| An app needs the file converted (a lower quality, audio it cannot play, burned-in subtitles) | rex converts it, reading the file from your source as before | Refused: the app shows an error |
| Files your source sends itself, not as a link (zurg's Usenet files, for one) | Play through rex as before | Refused |
| Plex Web | Plays, through rex | Every Real-Debrid file is refused (below) |

Pick `redirect` if you want everything to keep playing and save what you can. Pick `redirect-only` if the rex machine must never carry a movie, for example a small VPS with a data cap.

Whichever you pick, every app and person you share rex with gets the link your source gave rex for what they play, and the service behind that link, your debrid service for example, sees each of them download it.

## Step 1. Let your source hand out links

**What it does.** Your source answers each read with a link to the file elsewhere (an HTTP redirect) instead of the file itself.

**Why it matters.** rex can only pass on a link its source gives it. A source that sends the file itself keeps sending it through rex.

| Source | What to do |
|---|---|
| [rex-stremio](stremio.md) | Nothing: it answers with the link a stream addon gave. A link that needs headers of its own, and a live playlist, it still sends itself |
| [zurg](with-zurg.md) | Turn on `disable_stream_proxy`, below. zurg has no link for a Usenet file, so it always sends those itself |
| [Your own app](any-source.md) | Answer the file's `GET` with a `302` or `307` to the link |

### zurg

The setting is zurg's, so anything else reading zurg (rclone, a Plex or Jellyfin server on zurg's mount) gets the links too; zurg's [config reference](../zurg/reference/config.md) has the details.

+++ Linux and macOS
See whether the setting is already in zurg's config:

```bash
grep -n '^disable_stream_proxy:' ~/zurg/config.yml
```

If it prints a line, change it to `disable_stream_proxy: true` with `nano ~/zurg/config.yml`. If it prints nothing, add it:

```bash
printf '\ndisable_stream_proxy: true\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
Open zurg's config with `notepad $HOME\zurg\config.yml`. If it has a `disable_stream_proxy:` line, change it to `disable_stream_proxy: true`; if not, add that line at the end. Save it and restart zurg:

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++ Docker
In zurg's folder:

```bash
sudo grep -n '^disable_stream_proxy:' config.yml
```

If it prints a line, change it with `sudo nano config.yml`. If not:

```bash
printf '\ndisable_stream_proxy: true\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```
+++

**What you should see.** zurg starts again as usual. Movies still play through rex at this point: rex follows the links itself until step 2.

## Step 2. Let rex pass the links on

**What it does.** rex hands the app the link your source gave it, instead of downloading the movie for it.

End rex's start command with `--part-mode redirect` (or `--part-mode redirect-only`), then restart rex and open its log. [Install rex](any-source.md#step-1-install-rex) shows where the start command is on your system and how to restart rex and see its log. On Linux the `ExecStart` line in `~/.config/systemd/user/rex.service` then reads, with nothing else on it:

```ini
ExecStart=%h/rex/rust/target/release/rex --part-mode redirect
```

Keep anything already on the line, such as `--port 32500` or `--announce-url ...`.

**What you should see.** The start line ends in `parts=redirect`:

```
INFO    rex on http://192.168.1.20:32400  machine=...  items=...  parts=redirect
```

With `redirect-only` it ends in `parts=redirect-only`, and a few lines above it rex says `transcoder off: --part-mode redirect-only`.

## Step 3. Play something

Leave rex's log open and play a movie in Plezy or Plex for Android.

**What you should see.** For each read the app makes, a line naming your provider's server:

```
INFO    PART 1000010 range=bytes=0- -> 302 to 129-4.download.real-debrid.com
```

That is rex sending the app to the link's server, Real-Debrid's here. A line ending in `-> 206 len=...` instead means rex sent the movie itself: see [If it does not work](#if-it-does-not-work).

## What each app does

| App | `redirect` | `redirect-only` |
|---|---|---|
| Plezy | Downloads from your provider | Downloads from your provider |
| Plex for Android, Original quality | Downloads from your provider, when rex lets it play the file as it is | The same |
| Plex for Android, a lower quality, or audio it cannot play | rex converts it | "Playback Error: This item can't be played right now. Please try again." |
| Plex Web | Plays through rex | "Playback Error: This server is not powerful enough to convert video." |

Plex Web cannot use Real-Debrid's links at all: Real-Debrid marks its files as downloads, not video, and the browser refuses to play them. Under `redirect` Plex Web quietly falls back to a conversion through rex within a second, so it keeps working; under `redirect-only` there is nothing to fall back to.

## In Docker

If you followed [rex in Docker](any-source.md#run-rex-in-docker), step 2 is a `command:` line under `rex:` in rex's `compose.yml`, beside `image:`:

```yaml
    command: --part-mode redirect
```

Already have `command: --port 32500`? Make it `command: --port 32500 --part-mode redirect`. Then `docker compose up -d` in rex's folder, and `docker compose logs -f rex` shows the same `parts=redirect` line.

## If it does not work

| You see | What it means |
|---|---|
| rex exits with `invalid choice` for `--part-mode` | rex is older than 2026.10.26. Update it as in [rex's Updating section](any-source.md#updating) |
| rex's log says `-> 206 len=...` for every read | The source still sends the file itself. With zurg: `disable_stream_proxy: true` is missing from zurg's config, or zurg was not restarted after step 1 |
| `-> 206 len=...` only for some titles | The source sends those itself: zurg's Usenet files, or rex-stremio links it has to relay |
| `-> 403: the source answered with the bytes, not a link` | `redirect-only` refusing a file the source sent itself, for the same reasons as above |
| No `PART` lines at all while a movie plays | The app is playing a conversion, not the file itself. Set its quality to Original |

Still stuck? Ask in the **rex-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) says what to include.

## Going back

Remove `--part-mode ...` from rex's start command (or the `command:` line in Docker) and restart rex. Your source can keep handing out links: with the rex setting gone, rex follows them itself. With zurg, setting `disable_stream_proxy` back to `false` and restarting zurg makes it pass the files itself again, for rclone and anything else reading it too.
