---
label: Whisparr
icon: download
order: 74
---

# Whisparr

Whisparr is Radarr for adult films and scenes, and it uses zurg the same way Radarr does. zurg answers as its qBittorrent, adds what it grabs to your debrid account, and the import is a rename inside `__magic__`, so nothing is downloaded or copied to import.

Everything below was tested on 2026-10-23 with Whisparr `3.6.5.1886` (the `ghcr.io/hotio/whisparr:v3` image), Prowlarr, zurg built from that day's `main` and a Real-Debrid account. A 17 GB film was grabbed, imported and played back from the mount.

## Before you start

Set up zurg for Radarr first, with [Sonarr & Radarr for torrents](sonarr-radarr-torrents.md): an account that takes torrents, `__magic__` on and the qBittorrent endpoint on. Whisparr reuses all of it.

## 1. Whisparr's category in zurg

Whisparr sends its grabs under the category `whisparr`. Its **Test** button in step 3 creates that category in zurg, so nothing needs adding. To list it in `config.yml` anyway, add it beside the ones already there:

```yaml
qbittorrent:
  enabled: true
  categories: [tv-sonarr, radarr, whisparr]
```

## 2. Run Whisparr

On a Linux host, give Whisparr the same volume as Radarr, the folder **above** zurg's mount with `rslave` ([why](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)):

```yaml
services:
  whisparr:
    image: ghcr.io/hotio/whisparr:v3
    container_name: whisparr
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - ./whisparr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6969:6969
    restart: unless-stopped
```

`PUID` and `PGID` are the Linux user Whisparr runs as. zurg's own Docker image lets any user read its mount. A zurg installed as a plain binary does that only with `user_allow_other` enabled ([Linux setup](../setup/linux.md#1-install-fuse-3)); without it, set `PUID` and `PGID` to the user zurg runs as (`id -u` and `id -g` print it), or Whisparr sees the mount empty.

On macOS and Windows this compose file does not apply, for the reason the [Usenet guide's step 8](sonarr-radarr.md#8-if-your-arr-is-in-docker) gives. Install Whisparr as an ordinary app there, with the catches listed under [Before you start](sonarr-radarr.md#before-you-start) in that guide: the same user as zurg on macOS, the tray app and not the Windows service on Windows. Only the Docker image above was tested.

Open `http://<your server>:6969`.

## 3. Add zurg as the download client

**Settings → Download Clients → + → qBittorrent**, filled in exactly as for Radarr ([the fields](sonarr-radarr-torrents.md#what-to-put-in-each-field)), except **Category** is `whisparr`. Leave **Remove Completed** on. **Test**, then **Save**.

## 4. Add the root folder

Make the folder on the mount, then add it under **Settings → Media Management → Root Folders**:

+++ Linux

```bash
mkdir -p /mnt/zurg/__magic__/whisparr
```

+++ macOS

```bash
mkdir -p /Volumes/Zurg/__magic__/whisparr
```

+++ Windows

```powershell
New-Item -ItemType Directory -Force Z:\__magic__\whisparr
```

+++

It sits beside `__magic__/movies`, not inside it. Whisparr files each film under its studio, as `__magic__/whisparr/movies/<Studio>/<Title (Year)>/`.

## 5. Indexers

DMM's indexer has no adult category, so Whisparr needs other indexers. In Prowlarr, the public indexers **Knaben** and **The Pirate Bay** both worked. **XXXClub** is behind Cloudflare and Prowlarr cannot add it without a Cloudflare solver.

Then connect Prowlarr to Whisparr under Prowlarr's **Settings → Apps → + → Whisparr**, with Whisparr's address and API key (Whisparr's **Settings → General**). Prowlarr adds its indexers to Whisparr itself.

zurg only accepts releases your account already holds (`cached_only`, on by default). When it refuses one, Whisparr takes its next result.

## 6. Grab one

Add a film in Whisparr with **Start search for missing movie** ticked. When it works, Whisparr's history shows **Grabbed** and then **Imported** within seconds, and the film is on the mount:

```bash
$ ls "/mnt/zurg/__magic__/whisparr/movies/<Studio>/<Title (Year)>/"
<Title> 1080p.mkv
```

On macOS the path starts `/Volumes/Zurg`; on Windows look in `Z:\__magic__\whisparr\movies` in Explorer. Nothing lands in zurg's `data/local` folder. The file streams from your account.

## Watching it

Point a Plex or Jellyfin library at `/mnt/zurg/__magic__/whisparr` (`/Volumes/Zurg/__magic__/whisparr` on macOS, `Z:\__magic__\whisparr` on Windows) to keep these films in a library of their own.

In rex they appear in whichever library zurg's folders put them, like every other release, which on most setups is the movies library.
