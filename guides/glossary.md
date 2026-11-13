# What each piece does

The names don't say what anything does, so here is one line for each. To find which ones you need, use [Choose your setup](choose-your-setup.md).

## The three projects

| Name | What it does |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | A website for finding releases and adding them to your debrid account. It also searches Usenet and Easynews. Free |
| [zurg](../zurg/index.md) | Every debrid account and Usenet in one folder. Plex, Jellyfin, Emby, Infuse and rex read that folder like a normal drive. For sponsors |
| [rex](../rex/index.md) | A media server that owns no files. Its sources tell it what they have and every Plex app plays it. Free for personal use |

## Watching straight from DMM

No server needed for any of these.

| Name | What it does |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio/) | A Stremio addon that plays releases from your debrid or Easynews account |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Browse, search and play from your debrid or Easynews account inside Kodi |
| DMM Watch | A button on DMM that opens a file in your own player, like VLC or Infuse |
| [DMM Music](https://debridmediamanager.com/music/) | Play and download music from Real-Debrid in your browser |

## Feeding rex

| Name | What it does |
|---|---|
| [rex-stremio](../rex/stremio.md) | Turns your Stremio addons into rex libraries, so they play in Plex apps. Free |
| [rex addons](../rex/addons.md) | Small programs that give rex something to play: YouTube, Spotify, IPTV, home videos, or whatever you write |
| [rex for Android](../rex/android.md) | rex and its addons on an Android phone or TV box, no computer. Free. For your debrid and Usenet library, sponsors use zurg+rex |
| [zurg+rex for Android](../zurg/guides/android.md) | A Plex server on your phone: zurg and rex together on one Android device. For sponsors |

## Inside Jellyfin and Emby

| Name | What it does |
|---|---|
| [RD, AD, TB, PM, OC and DL zurg](https://debridmediamanager.com/jellyfin) | One plugin per debrid provider. Your debrid library shows up in Jellyfin or [Emby](https://debridmediamanager.com/emby) with no zurg app or mount. For sponsors |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | A Jellyfin plugin that streams NZBs through your own Usenet account. For sponsors |

## Adding titles for you

| Name | What it does |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Press **Want** on DMM and your zurg fetches it, new episodes included. For sponsors |
| [Seerr through DMM](../dmm/seerr.md) | Family requests in Seerr go to your Wanted list. For sponsors |
| [Torznab and Newznab](https://debridmediamanager.com/torznab) | DMM as the indexer for Sonarr, Radarr and Prowlarr, with zurg as the download client. For sponsors |
| [zurg's Stremio addon](../zurg/guides/stremio.md) | Searches Usenet when you press play in Stremio and streams it through zurg |
| [`__magic__`](../zurg/guides/magic.md) | A zurg folder you arrange yourself, or let Sonarr and Radarr arrange |

## The rest of DMM

| Name | What it does |
|---|---|
| [Request board](https://debridmediamanager.com/requests) | Ask for a release Real-Debrid doesn't have. Another DMM user moves it into your library. Filling requests earns the DMM sponsor perks |
| [Hash lists](https://debridmediamanager.com/hashlists) | Share a list of releases so others can add them to their own accounts |
| [Browser extension](../dmm/safari.md) | Adds DMM buttons to movie and TV sites and next to magnet links |
| [Sponsor page](https://gatekeeper.debridmediamanager.com) | Where you sponsor and link your Patreon or GitHub Sponsors pledge. [What a sponsorship gives you](sponsorship.md) |

## Words you'll see in the guides

| Word | What it means |
|---|---|
| Debrid provider | A paid service that downloads torrents for you and lets you stream them: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | The provider already has the release, so it plays right away |
| Usenet | Another place to get releases. You need a Usenet provider account, or TorBox Pro to do it for you |
| NZB | A small file that says where a Usenet release is, like a torrent file does for torrents |
| Indexer | A search site for releases. Sonarr and Radarr use one to find things |
| WebDAV | A way to share files over the web. Infuse, Kodi and many TV players can open it |
| Mount | Makes zurg's folder look like a local drive, so Plex, Jellyfin or Emby can scan it |
| Plex Media Server vs Plex apps | The server holds your library. The apps on your TV and phone play it. rex replaces the server, not the apps |
