---
label: What each piece does
description: "One line for every piece of DMM, zurg and rex, from DMM Cast and the Kodi addon to rex-stremio, the Jellyfin and Emby plugins and the words you meet in the guides."
icon: list-unordered
order: 90
---

# What each piece does

The names don't say what anything does, so here is one line for each. Anything not marked **For sponsors** is free. To find which ones you need, use [Choose your setup](choose-your-setup.md).

## The three projects

| Name | What it does |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | A website for finding releases and adding them to your debrid account. It also searches Usenet and Easynews |
| [zurg](../zurg/index.md) | Every debrid account and Usenet as one library. Plex, Jellyfin and Emby read it as a folder, Infuse and Kodi over WebDAV, and rex gets it directly. Current builds are for sponsors |
| [rex](../rex/index.md) | A media server for the Plex apps with no files of its own. zurg or an addon tells it what there is. Free for personal use |

## Watching straight from DMM

No server needed for any of these.

| Name | What it does |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | A Stremio addon that plays releases from your debrid or Easynews account |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Browse, search and play from your debrid or Easynews account inside Kodi |
| DMM Watch | A button on DMM that opens a file in your own player, like VLC or Infuse |
| [DMM Music](https://debridmediamanager.com/music) | Play and download music from Real-Debrid in your browser |

## Feeding rex

| Name | What it does |
|---|---|
| [rex-stremio](../rex/stremio.md) | Turns your Stremio addons into rex libraries, so they play in Plex apps |
| [rex addons](../rex/addons.md) | Small programs that give rex something to play: YouTube, Spotify, IPTV, home videos, or whatever you write |
| [rex-live-sports](../rex/live-tv.md) | A rex addon that puts live sports channels and a guide in the Plex apps' Live TV |
| [rex-direct](../rex/any-source.md#rex-direct) | Gives your rex its own secure address, so Plex apps reach it away from home |
| [rex for Android](../rex/android.md) | rex and its addons on an Android phone or TV box, no computer |
| [zurg+rex for Android](../zurg/guides/android.md) | A Plex server on your phone: zurg and rex together on one Android device, with your debrid and Usenet library. For sponsors |

## Inside Jellyfin and Emby

| Name | What it does |
|---|---|
| [Debrid plugins](https://debridmediamanager.com/jellyfin) (RD zurg, AD zurg, TB zurg, PM zurg, OC zurg, DL zurg) | One plugin per debrid provider: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud and Debrid-Link. Your debrid library shows up in Jellyfin or [Emby](https://debridmediamanager.com/emby) with no zurg app or mount. For sponsors |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | A Jellyfin plugin that streams NZBs through your own Usenet account. For sponsors |

## Adding titles for you

| Name | What it does |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Press **Want** on DMM and your zurg fetches it, new episodes included. For sponsors |
| [Seerr through DMM](../dmm/seerr.md) | Family requests in Seerr go to your Wanted list. For sponsors |
| [Torznab](https://debridmediamanager.com/torznab) and [Newznab](https://debridmediamanager.com/newznab) | DMM as the indexer for Sonarr, Radarr and Prowlarr. For sponsors |
| zurg as the download client | zurg answers Sonarr and Radarr as qBittorrent for [torrents](../zurg/guides/sonarr-radarr-torrents.md) and SABnzbd for [Usenet](../zurg/guides/sonarr-radarr.md), so you run neither. For sponsors |
| [zurg's Stremio addon](../zurg/guides/stremio.md) | Searches Usenet when you press play in Stremio and streams it through zurg. For sponsors |
| [`__magic__`](../zurg/guides/magic.md) | A zurg folder you arrange yourself, or let Sonarr and Radarr arrange. For sponsors |

## The rest of DMM

| Name | What it does |
|---|---|
| Usenet tab | Sends a Usenet release to your Real-Debrid library, with no Usenet account. Sponsors go first and get a bigger daily allowance |
| [Request board](https://debridmediamanager.com/requests) | Ask for a release Real-Debrid doesn't have. Another DMM user moves it into your library. Fill 10 requests and get 7 days of the DMM sponsor perks |
| [Hash lists](https://debridmediamanager.com/hashlists) | Share a list of releases so others can add them to their own accounts |
| Browser extension | Adds DMM buttons to movie and TV sites and next to magnet links. For [Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm), [Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/) and [Safari](../dmm/safari.md) |
| [gatekeeper](https://gatekeeper.debridmediamanager.com) | The sponsor site. Sponsor there, link your Patreon or GitHub Sponsors pledge and get your DMM API key. [What a sponsorship gives you](sponsorship.md) |

## Words you'll see in the guides

| Word | What it means |
|---|---|
| Release | One copy of a film, episode or season as someone published it. A title usually has many, in different qualities |
| Debrid provider | A paid service that downloads torrents for you and lets you stream them: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | The provider already has the release, so it plays right away |
| Usenet | Another place to get releases. Use your own Usenet account, let TorBox Pro or Easynews do it, or have DMM send a result to Real-Debrid |
| Easynews | A paid Usenet service with its own search that plays files straight over the web |
| NZB | A small file that says where a Usenet release is, like a torrent file does for torrents |
| Indexer | A search site for releases. Sonarr and Radarr use one to find things |
| Sonarr, Radarr and Prowlarr | Apps that fetch titles for you: Sonarr for shows, Radarr for films. Prowlarr keeps their indexers in one place |
| Seerr | A request site for family and friends. Overseerr and Jellyseerr work the same way |
| Stremio and Kodi | Media player apps. Addons give them things to play |
| DMM API key | A sponsor's key from gatekeeper. Paste it where a guide asks, and keep it private like a password |
| Nightly | The newest build of zurg or rex, made every night. zurg's nightlies are for sponsors |
| WebDAV | A way to share files over the web. Infuse, Kodi and many TV players can open it |
| Mount | Makes zurg's folder look like a local drive, so Plex, Jellyfin or Emby can scan it |
| rclone | The tool zurg uses to make the mount. zurg's setup gets it for you |
| `.strm` | A small file that holds a link in place of the video, for players like Kodi |
| Source | Anything that tells rex what it has and serves the files: zurg, rex-stremio or an addon |
| Claim | Putting rex on a Plex account, so it can show titles and posters and Plex apps can find it |
| Plex Media Server vs Plex apps | The server holds your library. The apps on your TV and phone play it. rex replaces the server, not the apps |
