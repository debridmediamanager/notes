---
label: More from your addon
icon: tools
order: 66
---

# More from your addon

[Building rex addons](addons.md) covers what every addon needs. This page covers what an addon can add once it works: subtitles, trailers and other extras, chapters, collections, playlists, artist pictures, films Plex already knows, big libraries, reading back what people fixed, and removing an addon. Each section adds fields to the items you already send in [Step 5](addons.md#step-5-send-it); the tutorials ([home videos](addon-home-videos.md), [music](addon-music.md), [IPTV](addon-iptv.md)) are a good place to try them.

Every example here was sent to a rex nightly 2026.11.02, and the answers shown are what it gave. The full reference is rex's [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Films and shows Plex knows

**What it does.** Has Plex name a film or episode, with its poster, cast, summary and ratings, instead of your `display`.

Send `kind` and the title's ids: an IMDb (`tt...`) or TMDB id of the film, or of the **show** for an episode, with `season` and `episode` on TMDB's numbering:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv",
 "kind": "movie", "ids": {"tmdb": 10378}, "media_info": { "...": "ffprobe's output" }}
```

**What you should see.** The film is **Big Buck Bunny (2008)** with Plex's artwork, whatever the file is called. rex reads nothing from names: what you send is what it shows. [rex with your own app](any-source.md) covers this in full, episodes included.

## Subtitles

**What it does.** Offers subtitle files that sit beside a video as its subtitles, which people pick, download or burn in as they do an uploaded one.

```json
"subtitles": [{"path": "films/Big Buck/film.en.srt", "language": "en", "size": 82}]
```

| Field | Meaning |
|---|---|
| `path` | Where the file is on your addon, as a video's. Its extension is its format: `srt`, `ass`, `ssa`, `smi`, `txt` or `psb` |
| `language` | `en` or `eng`, as you know it. rex reads no language from the file's name |
| `forced`, `hearing_impaired` | `true` to mark it so |
| `size` | Its size in bytes. rex reads the file again only when its path is new or its size changed |

**What you should see.** The video lists an **English (SRT External)** subtitle. Leaving `subtitles` out keeps what you sent before; `[]` removes yours (an upload or a downloaded subtitle stays). A file rex cannot read is left out and logged, and the video is still taken.

## Trailers and other extras

**What it does.** Puts a trailer, a featurette or a deleted scene under its film or show, in **Extras**, instead of making it a title of its own.

```json
{"id": "films/Big Buck/trailer.mp4", "path": "films/Big Buck/trailer.mp4",
 "kind": "extra", "extra_type": "trailer", "media_info": { "...": "ffprobe's output" }}
```

An extra belongs to the title of the other videos in its `release` (by default its folder). `extra_type` is `trailer`, `deleted`, `featurette`, `behindthescenes`, `interview`, `scene`, `short`, `opening`, `ending` or `other`. rex never decides a video is an extra by its name or folder: only `kind: "extra"` makes one.

**What you should see.** The film's page shows the trailer under Extras, and the library does not list it.

## Chapters

**What it does.** Lets people jump between chapters in the player.

Run `ffprobe` with `-show_chapters` as well, and send its output as it is:

```bash
ffprobe -v error -print_format json -show_format -show_streams -show_chapters film.mkv
```

**What you should see.** The video's chapters, with their names and times. To add chapters to videos rex already has, send their probes again with `-show_chapters` in the next snapshot.

## Collections and playlists

**What it does.** Groups titles into collections of their library, and songs or videos into playlists, made and kept up to date by your addon.

```json
"collections": ["Summer 2026"],
"playlists": {"Road trip": 1}
```

| Field | Meaning |
|---|---|
| `collections` | The collections the title is in, by name. Each is made the first time a title names it |
| `playlists` | The playlists the file is in, by title, with its place in each from 1. Each is a playlist of the server owner's, audio when its first song is a track and video otherwise |

People keep their changes: a title someone took out of a collection stays out, a song someone added to your playlist keeps its place, and a playlist someone renamed stays theirs. Leaving the field out keeps what you sent before; `[]` (or `{}` for playlists) takes the file out of everything your addon put it in.

**What you should see.** The library's Collections tab lists **Summer 2026**; Playlists lists **Road trip**, in your order.

## Artist pictures

**What it does.** Shows your pictures for the artists your music addon sends, even for artists Plex knows and would picture itself.

Register with `"artwork": "source"`, and send the picture on each track:

```json
"display": {"artist": {"title": "Radiohead", "poster": "http://127.0.0.1:9982/music/Radiohead/artist.jpg"}}
```

Without `artwork: "source"`, an artist Plex knows keeps Plex's picture and `display.artist` shows only for artists Plex does not know. Either way, a picture someone picked or uploaded in a Plex app stays.

## Big libraries: send probes once

**What it does.** Lets a snapshot of thousands of videos send almost no `ffprobe` output, so it is small and quick.

Send `probe`, a short text of your own that changes whenever the video's probe would (a hash of its `ffprobe` output works). Once rex has a video with that `probe`, send the `probe` alone, without `media_info`:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv", "kind": "movie", "ids": {"tmdb": 10378}, "probe": "v1"}
```

rex answers `"unchanged": 1`. When it does not have that `probe` (a new video, or one whose probe changed), it changes nothing and asks for it:

```json
{"created": 0, "updated": 0, "held": 0, "unchanged": 0, "wants": ["films/Big Buck/film.mkv"]}
```

Send those items again with their `media_info`. A snapshot counts a wanted item as sent, so it is never removed for it. Check that your rex takes it: the answer to [registering](addons.md#step-2-register-with-rex) lists `"features": ["probe_digest"]`.

## What people fixed: Fix Match

**What it does.** Tells your addon which of its videos someone matched by hand in a Plex app (Fix Match), so it can send them right from then on.

```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/matches
```

```json
{"size": 1, "matches": [{"release": "films/Mystery Reel", "ids": {"tmdb": 45745, "imdb": "tt1727587", "tvdb": 9413}, "kind": "movie", "matched_at": 1793751999}]}
```

Each entry is a `release` (a folder, unless you send `release`) and the ids of the film or show it was matched to. rex keeps the match whatever you send next, so nothing breaks if you ignore this; reading it lets your addon send `kind` and `ids` itself, and remember the fix if rex's rows are ever rebuilt. With nothing matched the answer is `{"size": 0}`.

## Removing your addon

**What it does.** Takes your addon and everything it sent out of rex, without touching its files.

It takes two requests: the first says how much would go and gives a link valid for five minutes, the second removes it.

```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon
# {"confirm": "/rex/sources/myaddon/confirm/eae4...", "items": 4, "expires_in": 300}
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon/confirm/eae4...
# {"deleted": true, "removed": 4}
```

Watch history goes with the rows. Registering and sending again later starts from nothing, with new rows. To **replace** an addon with a new version instead, keep its name, its ids and its paths' first segments: the new one then updates the same rows. Libraries are never deleted by rex; delete them in a Plex app if you want them gone.

## Who may send to rex

rex's feed (`/rex/sources` and `/rex/feed`) takes no token. It answers only programs on rex's own machine, your home network (`192.168.x.x`, `10.x.x.x`, `172.16-31.x.x` and private IPv6 addresses) and Tailscale (`100.64-127.x.x`); to anyone else it does not exist, even after you forward rex's port for rex-direct or let it in over IPv6. A reverse proxy on rex's machine reaches it as a local program, so block `/rex/` there if you put one in front of rex.
