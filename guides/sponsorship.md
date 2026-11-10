---
label: Sponsorship
icon: heart
order: 40
---

# What a sponsorship gives you

DMM is free for everyone and stays free. A sponsorship pays its hosting and keeps zurg and rex in development. This page lists everything it opens and where each thing is set up.

Sponsor on [gatekeeper](https://gatekeeper.debridmediamanager.com/). It shows your DMM API key once you sign in. Its **Open DMM with this key** link turns the DMM perks on in that browser. Everything else takes the same key in its own settings. Keep the key private because it works like a password.

The perks follow the sponsorship. When it ends DMM stops them on the next request. The zurg repository and the Discord role go at gatekeeper's next check. Pressing **Reset key** on gatekeeper stops the old key everywhere at once.

## zurg

| What you get | Where |
|---|---|
| Nightly builds with every provider and Usenet plus the Docker image | [zurg setup](../zurg/setup/index.md) after you accept the GitHub invitation |
| The zurg+rex Android app | [Android guide](../zurg/guides/android.md) after you accept the GitHub invitation |
| The full zurg source code | The private repository on GitHub |
| Every release named for rex and Plex | `dmm_api_key` in the [zurg config](../zurg/reference/config.md) |
| Media details for your files from DMM without zurg reading them first and a release's languages checked before it is added | Nothing beyond `dmm_api_key` |
| The `__magic__` folders sorted for you once you turn them on | [\_\_magic\_\_](../zurg/guides/magic.md) |
| Your DMM wanted list fetched by zurg | [DMM wanted list](../zurg/guides/dmm-wanted.md) |
| DMM's Usenet and torrent indexers searched for you when you have no indexer of your own | Nothing beyond `dmm_api_key` once zurg has a Usenet provider or a debrid account to add torrents to |
| Releases picked by each title's original language | `original` in [audio and subtitle languages](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) |
| A wanted film no indexer carries streamed from its official YouTube upload | [Streaming a film from YouTube](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

The `dmm_api_key` features need a zurg nightly. The free public build does not have them.

## DMM

| What you get | Where |
|---|---|
| A wanted list that zurg fetches with new episodes and upgrades included. Fill it from DMM or Kodi or Trakt and MDBList lists or a Radarr or Sonarr backup | [DMM wanted list](../zurg/guides/dmm-wanted.md) |
| Requests from Seerr or Overseerr or Jellyseerr land on your wanted list | [Seerr through DMM](../dmm/seerr.md) |
| Any Easynews result sent to your zurg in one click | The Easynews results on a film or show page on DMM |
| DMM as a Newznab indexer for Usenet | DMM's [Newznab page](https://debridmediamanager.com/newznab) |
| DMM as a Torznab indexer with cached-only feeds for Real-Debrid and AllDebrid and Debrid-Link and TorBox and Premiumize and Offcloud | DMM's [Torznab page](https://debridmediamanager.com/torznab). The TorBox and Premiumize and Offcloud feeds need your key for that service linked there |
| Seven Jellyfin plugins for your debrid and Usenet libraries and six Emby plugins for your debrid libraries with nothing mounted | DMM's [Jellyfin](https://debridmediamanager.com/jellyfin) and [Emby](https://debridmediamanager.com/emby) pages |
| Ten other streams per title in Stremio Cast and Kodi instead of five | DMM Settings for Real-Debrid, TorBox and AllDebrid; each provider's Cast page for the others |
| Your NZB uploads go first with 2 TB of Usenet a day instead of 300 GB | DMM's Usenet tab |
| The same for what Sonarr and Radarr send | Your DMM API key as the Password on DMM's [SABnzbd page](https://debridmediamanager.com/sabnzbd) |
| Three torrent uploads into Real-Debrid at once instead of one | The upload buttons on DMM's search results and library |
| Add to DMM Wanted and a Wanted folder inside Kodi | Pair Kodi on DMM's [Kodi page](https://debridmediamanager.com/kodi) |
| Your settings restored on another device with only the sponsor key signed in | DMM Settings |
| The DMM API for your own tools with release names and cache checks and media details and metadata | [API docs](https://debridmediamanager.com/api-docs) |

## rex

rex is free and needs no sponsorship; its Android build comes only inside the sponsor-only zurg+rex app. With a key [rex-stremio](../rex/stremio.md) adds debrid streams of torrents DMM already holds a probe of to rex in seconds instead of probing each one. Paste the key in the **DMM** field on rex-stremio's settings page. It then shares its probes of torrent files with DMM unless you turn that off.

## Help

| What you get | Where |
|---|---|
| Free remote help with zurg and rex in your own terminal while you watch | [Getting help](remote-help.md) |
| The Sponsor role on Discord | Connect Discord on gatekeeper |

## Earn it without paying

Fill requests on DMM's [request board](https://debridmediamanager.com/requests). Every 10 requests you fill earn 7 days of the DMM perks above. Only one fill for the same person each day counts. Link the key from a free gatekeeper account on the board to collect them.

Earned time opens the DMM table above. It does not open the zurg nightly or the source code or the Discord role or remote help or the Android app. Those need a paid sponsorship. The `dmm_api_key` features in zurg need a nightly too.

Stuck? Ask in the **dmm-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP).
