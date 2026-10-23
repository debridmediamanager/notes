# Building rex addons

[rex](https://rex.debridmediamanager.com) shows whatever its sources tell it about. zurg is one source. An **addon** is a small program of your own that is another: it brings something into your Plex apps that no Plex agent knows, such as a YouTube channel, home videos or recordings, and names it itself.

This page is for people who write addons. It covers what rex needs from one, how to name and dress what it brings, and the rules that trip people up. It ends with a worked example: the YouTube addon we run, which streams every video of a channel into a TV show, nothing downloaded.

An addon does three things:

- **Serves the bytes.** rex fetches every byte from your addon over HTTP when someone presses play: a file, or a stream rex is redirected to.
- **Tells rex what it has.** It sends rex a list over rex's feed API, and every change after that. rex never scans anything.
- **Names what it brings.** For things no agent knows, your addon sends the title, summary, date and artwork itself. Plex apps show them like any other library.

If what you bring are movies and shows Plex already knows (it has their IMDb or TMDB ids), you want [rex with your own app](rex-any-source.md) instead: Plex then names and describes everything for you.

## Before you start

| You need | Why |
|---|---|
| rex, set up as in [rex with your own app](rex-any-source.md) (steps 1 to 3) | That is where your addon's library shows up |
| A rex nightly from the night of October 23, 2026, or newer | `display` and HLS streams arrived then. Older builds reject what this page sends |
| FFmpeg where rex runs, if your addon serves streams | rex plays a stream by converting it (a copy, cheap). rex finds FFmpeg itself; see [rex](rex.md) |
| Your addon on the same machine as rex, or on your home network | rex's feed answers only private networks: loopback, `192.168.x.x`, `10.x.x.x`, Tailscale |

This page writes rex's address as `192.168.1.20:32400` and the addon's as `127.0.0.1:9981`. Put yours in their place. rex's full API reference is `docs/feed-api.md` in every rex download.

## Step 1. Serve the bytes

**What it does.** Gives every video a URL rex can read.

**Why it matters.** rex keeps no media. Each time someone presses play, rex reads the video from your addon.

Your addon is an HTTP server. A video lives at `<your address>/<path>`, and `path` is whatever you choose. There are two kinds:

| You serve | How | What rex does |
|---|---|---|
| **A file** (`.mkv`, `.mp4`, ...) | Answer `GET` with the file. Answer `Range` requests (`206`) so seeking is fast; without them rex reads from the start to every seek | Plex apps play it directly when they can, or rex converts it |
| **A stream** (HLS, `.m3u8`) | Answer `GET` with the playlist, or a redirect to it. Redirects are followed, and your login is never sent to another host | rex always converts it: a copy of the picture and sound into what the app plays. An app that reads the file directly is sent to that conversion |

Optional, but worth it:

- **A login.** Basic auth (`user`, `password`) or a bearer token. rex sends it only to your addon's own address.
- **Deletes.** When someone deletes a title in a Plex app, rex first sends your addon a WebDAV `DELETE` for the path. Answer `2xx` (deleted) or `404` (already gone) and rex removes the title. Anything else, and the Plex app says it could not be deleted.

## Step 2. Register with rex

**What it does.** Tells rex your addon's name, where its bytes are and which libraries it fills.

**Why it matters.** rex reads nothing from a source it does not know. Registering again changes nothing, so do it every time your addon starts.

```bash
curl -X PUT http://192.168.1.20:32400/rex/sources/myaddon \
  -H 'Content-Type: application/json' \
  -d '{"url": "http://127.0.0.1:9981", "mount": "/mnt/myaddon",
       "directories": [{"name": "kids", "shows": "Kids"}]}'
```

| Field | Meaning |
|---|---|
| `url` | Where your bytes are. A video's bytes are `GET <url>/<path>` |
| `user` and `password`, or `bearer` | Your addon's login, if it has one. Never inside `url` |
| `mount` | The folder prefix Plex apps show in Get Info. Nothing is read from it |
| `directories` | The libraries your addon fills. Each entry is a first path segment (`name`) and the library's title: `shows` for a TV library, `movies` for a movie library, or both. rex makes each library the first time; renaming it in Plex sticks |

A path's first segment picks its library: with the example above, every path that starts `kids/` lands in **Kids**. Use a different first segment for each library.

**What you should see.** rex answers with the source. rex's log says `SOURCES myaddon registered` and, the first time, `SECTION create Kids (show)`. The library appears in Plex apps under More within a second.

## Step 3. Describe each video

**What it does.** Builds the record rex keeps for each video: where it is, what it is, how it looks.

**Why it matters.** This record is all rex knows. A missing probe or a changing id causes most addon bugs.

```json
{
  "id": "yt-w264Mn-2MnQ",
  "path": "kids/ms-rachel/w264Mn-2MnQ.m3u8",
  "kind": "episode", "season": 1, "episode": 3,
  "name": "Ms Rachel",
  "release": "youtube:UCG2CL6EUjG8TVT1Tpl9nJdg",
  "media_info": { "...": "ffprobe's output, whole" },
  "display": {
    "title": "Learn to Talk for Babies and Toddlers",
    "summary": "...",
    "date": "2026-07-22",
    "thumb": "https://i.ytimg.com/vi/w264Mn-2MnQ/maxresdefault.jpg",
    "show": {"title": "Ms Rachel", "summary": "...", "poster": "https://...", "art": "https://..."},
    "season": {"poster": "https://..."}
  }
}
```

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Your key for this video, **for good**. rex keeps watch history on it |
| `path` | yes | Where its bytes are under your `url`. Its first segment picks the library |
| `media_info` | yes, in practice | ffprobe's `-show_format -show_streams` JSON for the video (for a stream, probe its URL). Without it the video is **held**: stored but not shown, because Plex apps will not play a video they know nothing about |
| `kind` | for a show | `episode` or `movie`. Without it nothing places the video: in a TV library it is an episode of a show named after `name`, numbered in file order; in a movie library a film titled as its file |
| `season`, `episode` | for an episode | Where it goes. Number episodes so a new one never shifts the others |
| `name` | for a show | The show's name, and what groups its episodes |
| `release` | no | Groups videos that belong together; give every episode of a show the same one |
| `size` | for a file | Bytes. rex uses it to answer seeks. Streams have none |
| `file` | no | What Get Info shows. Default `<mount>/<path>`. One video per file: see the rules below |
| `display` | for what no agent knows | Title, summary, date and artwork: Step 4 |

A stream's `path` and `file` end in `.m3u8`, and its `media_info` says `"format_name": "hls"`. rex accepts it only with both. Any other file must have a video extension.

## Step 4. Name and dress it

**What it does.** Gives Plex apps a title, summary, date and pictures for what no Plex agent knows.

**Why it matters.** Without `display`, an episode is "Episode 3" with a blank tile and a show has no poster.

| Field | Where it shows |
|---|---|
| `title`, `summary` | The video's title and summary, exactly as sent |
| `date` | Its release date (`YYYY-MM-DD`), and the year from it. Or the year alone (`YYYY`) for something known only by its year, such as an old film: Plex apps then show the year and no release day |
| `thumb` | A film's poster, or an episode's still |
| `art` | A film's background |
| `show.title`, `show.summary`, `show.poster`, `show.art` | The episode's show |
| `season.summary`, `season.poster` | The episode's season (the show's poster when there is none) |

Every field is optional. Pictures are `http://` or `https://` URLs. rex fetches them itself: from the public internet, or from your addon's own address (the `url` you registered), with your addon's login. Any other address on your home network is refused. So an addon can serve its own pictures, such as a frame from each home video. A 2:3 picture makes the best poster, a 16:9 one the best still and background.

How rex treats them:

- **Only for what nothing names.** A video sent with `ids` Plex knows is shown as Plex describes it, and `display` is ignored.
- **Later sends update.** Send a video again with a new `display` and its row, show and season change in place; apps redraw new pictures. A show keeps the title it was made with.
- **People win.** A field someone edited and locked in a Plex app keeps their value, and a poster they uploaded stays.
- **It is checked.** A picture that is no http(s) URL, or a date of another shape, refuses the video and says which field.

## Step 5. Send it

**What it does.** Sends rex your videos: everything now and then, changes as they happen.

**Why it matters.** rex shows exactly what you sent last.

| To | Send | rex answers |
|---|---|---|
| Add or change videos | `POST /rex/feed/myaddon/items` with `{"items": [...]}` | How many were `created`, `updated`, `held`, `unchanged`, and every `rejected` one with its reason |
| Remove videos | `DELETE /rex/feed/myaddon/items` with `{"ids": [...]}` | How many went to the trash |
| Send everything | `PUT /rex/feed/myaddon/snapshot` with `{"items": [...]}`. In parts: `"session"` (any text), `"part"` from 0, `"complete": true` on the last | The same counts, and what it `removed`: every video of yours the snapshot did not name |

Send a few hundred videos per request. A snapshot that names nothing removes nothing, and one that would remove more than half of your videos is refused unless its last part says `"force": true`: an addon that lost track of things cannot empty your library by accident.

**What you should see.**

```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/items | head -c 400   # what rex shows, with each ratingKey
curl -s http://192.168.1.20:32400/rex/feed/myaddon/held                  # what waits for a probe
```

rex's log names every refused video and why: `FEED myaddon rejected <id>: <reason>`.

## The rules that trip people up

| Rule | What happens if you break it |
|---|---|
| **An id is forever.** Change it and the video is a new title | Watch history and edits stay on the old row, which the next snapshot removes |
| **One video, one file.** Two ids may not share a `file` | The second is rejected: `<file> is already <id>'s file` |
| **A video's bytes are fixed per id.** rex keeps the streams it was first probed with | If the bytes change (another format, a fixed upload), give the video a new id and file |
| **Probe everything.** No `media_info`, no video | It waits in `held` until a send brings one |
| **Keep the source name.** Rows belong to (source, id) | Another name starts an empty source; the old one's rows stay until you delete it |
| **Snapshots are complete.** One that misses a channel removes it | Do not send a snapshot after a partial failure: skip that round |

To **replace** an addon (or a script) that already filled a library, keep its source name, ids, `mount` and first path segment. Your first send then updates its rows in place, watch history and all, instead of making new ones.

## Example: the YouTube addon

We run an addon that turns YouTube channels into TV shows. It is one Python file, about 350 lines, and does Steps 1 to 5. It does not take deletes: YouTube videos are not ours to delete.

**Serving.** YouTube's links expire after a few hours and only work from the address that asked for them, so the addon stores no links. It serves a URL per video, `/<library>/<channel>/<video>.m3u8`, and answers it with a redirect to YouTube's current stream, asked of [yt-dlp](https://github.com/yt-dlp/yt-dlp) at that moment and cached until shortly before it expires:

```python
url = run([yt_dlp, "-f", "b[protocol^=m3u8][vcodec^=avc1]", "-g", watch_url])   # 1080p H.264 + AAC
self.send_response(302)
self.send_header("Location", url)
```

rex follows the redirect, and its FFmpeg reads the stream straight from YouTube. The format is YouTube's best stream with picture and sound together: 1080p H.264 with AAC for most channels.

**Probing.** Once per video, the addon runs ffprobe on its own URL, so `media_info` describes exactly what rex will read, and caches the result.

**Naming.** yt-dlp lists the channel (`--flat-playlist -J`) and describes each video (`-j`): title, description, upload date, thumbnails. They become `display`. The channel's name, description, avatar and banner become the show's, unless the addon's settings give a poster of its own.

**Numbering.** Episodes are numbered by upload date, oldest first, so a new upload is the next episode and no number moves. Everything goes in Season 1, or a season per year, or every video becomes a film.

**Sending.** Every few hours: register, then one snapshot of every channel. A channel that fails that round skips the snapshot, so its episodes are not removed.

**What YouTube adds.** YouTube asks addresses that fetch a lot to "sign in to confirm you're not a bot", and then nothing plays. The addon gives yt-dlp a signed-in account's cookies. Sign the account out in the browser they came from and the cookies stop working.

## Troubleshooting

| You see | Why | Fix |
|---|---|---|
| `rejected`: `not a video file` | The file name has no video extension, or an `.m3u8` whose probe is not `hls` | Name streams `.m3u8` and send their probe |
| A video never shows up | It is held: no `media_info`, or one with no streams | Probe it and send it again |
| `rejected`: `... is already <id>'s file` | Another id has that `file` | Keep one id per file |
| Episodes titled "Episode 1" and blank tiles | No `display` | Send `display` with each video |
| Pictures do not show | The URL is on your home network but not under your addon's registered `url`, or is not http(s) | Serve them from your addon's own address, or host them on the public internet. Pictures from your addon's address need a rex from October 23, 2026 or newer |
| Playing fails with 502 in rex's log | Your addon did not answer, or the stream's site refused it | Check your addon's own log first |
| A title deleted in a Plex app stays | Your addon answered the `DELETE` with something other than `2xx` or `404` | Delete it on your side, then answer `2xx` |
| A deleted title comes back | Your addon still sends the video | Stop sending what was deleted |
