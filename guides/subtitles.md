---
label: Subtitles with Bazarr
icon: comment
order: 75
---

# Subtitles with Bazarr

Bazarr finds subtitles for what Sonarr and Radarr import and saves each one next to its video. With zurg the video sits in `__magic__`, and so does the subtitle. Plex and Jellyfin libraries pointed at `__magic__` read it like any subtitle on disk, and rex shows it too, as **English (SRT External)** in the subtitle menu.

This needs zurg and rex from the 2026-10-24 nightly or later.

Everything below was tested on 2026-10-23 with Radarr `6.3.0.10514`, the current `lscr.io/linuxserver/bazarr` image, zurg and rex of that day, and a Real-Debrid account.

## Before you start

Radarr (or Sonarr) already imports through zurg, with its root folder inside `__magic__`, for example `/mnt/zurg/__magic__/movies`. If it does not yet, follow [Sonarr & Radarr for torrents](sonarr-radarr-torrents.md) or [for Usenet](sonarr-radarr.md) first.

## 1. Run Bazarr

Give Bazarr the same volume as Radarr, so the two see the movie at the same path and no path mapping is needed:

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./bazarr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6767:6767
    restart: unless-stopped
```

The bind is the folder **above** zurg's mount (`/mnt`, holding `/mnt/zurg`), not the mount itself. A container that binds the mount itself keeps a dead mount once zurg restarts, and every read answers `Socket not connected`. [The torrent guide's Docker step](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker) explains why.

Open `http://<your server>:6767`.

## 2. Connect it to Radarr and Sonarr

**Settings → Radarr**: turn it on and enter Radarr's address, port and API key (Radarr's **Settings → General**). From inside a container use the host's LAN IP, not `localhost`. **Test**, then **Save**. Sonarr is the same under **Settings → Sonarr**.

## 3. Languages

**Settings → Languages**: add the languages you want, make a language profile with them, and set it as the default profile for movies and for series. Bazarr then asks for subtitles for everything Radarr and Sonarr already hold.

## 4. Providers

**Settings → Providers**: add the subtitle sites Bazarr searches. Some need an account and some do not. Two things we hit while testing:

- **subf2m** needs a User-Agent in its provider settings. Without one Bazarr pauses it for 12 hours on the first search.
- Bazarr pauses a provider that fails for a while, and if every provider is paused a search finds nothing. **System → Providers** lists them and resets them.

## 5. Embedded subtitles

Many releases already carry an English track inside the video file. Bazarr counts that as English being there and downloads nothing. If you want a subtitle file anyway, turn off **Use Embedded Subtitles** under **Settings → Subtitles**.

## 6. Check one

Bazarr's **Movies** page shows what each film is missing. Search one from there, and the subtitle lands beside the video:

```bash
$ ls "/mnt/zurg/__magic__/movies/Night of the Living Dead (1968)/"
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.en.hi.srt
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.mkv
```

The subtitle is a real file on zurg's disk, in `data/local/__magic__/` (see [Sidecars](magic.md#sidecars-nfo-posters-subtitles)). The video still streams from your account.

## In rex

zurg sends rex every subtitle that sits beside a video in `__magic__`, wherever Radarr or Sonarr moved that video. zurg looks for new, changed and removed subtitles once a minute, so a subtitle Bazarr saves shows up in rex within about a minute, and one you delete goes away just as fast. Nothing needs setting up beyond `rex_url` in zurg's config, which [the rex guide](rex.md) already has you set.

The file name says what the subtitle is, the same way Plex reads subtitle names:

| File name ends in | rex shows |
|---|---|
| `.srt` | Unknown (SRT External) |
| `.en.srt` | English (SRT External) |
| `.en.forced.srt` | English Forced (SRT External) |
| `.en.hi.srt`, `.en.sdh.srt`, `.en.cc.srt` | English SDH (SRT External) |

`.srt`, `.ass`, `.ssa`, `.smi` and `.txt` files are read. The language can be a two or three letter code (`en`, `eng`, `de`, `ger`). The name before it must be the video's own name, as Bazarr writes it.

Only subtitles in `__magic__` reach rex. One saved next to a file in another of zurg's folders, such as `/mnt/zurg/movies`, is not sent.

rex can also find subtitles itself: **Search Subtitles** in any Plex app, with no Bazarr at all. See [rex's subtitles](rex.md#subtitles).
