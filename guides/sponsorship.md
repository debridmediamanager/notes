# What a sponsorship gives you

DMM is free. Sponsorships pay for its hosting and keep zurg and rex moving. This page lists every perk and where to set it up.

Sponsor on [gatekeeper](https://gatekeeper.debridmediamanager.com/). Sign in there to see your DMM API key. **Open DMM with this key** links it in that browser. Add the same key in the other services that ask for it. Keep it private because it works like a password.

Perks follow the sponsorship. When it ends DMM stops them on the next request. Jellyfin and Emby plugins you already installed keep working, but new downloads and updates stop. Gatekeeper revokes zurg access and the Discord role on its next check. **Reset key** stops the old key everywhere at once.

## zurg

| What you get | Where |
|---|---|
| Nightly builds with every provider and Usenet plus the Docker image | [zurg setup](../zurg/setup/index.md) after you accept the GitHub invitation |
| The zurg+rex Android app, a Plex server on your phone | [Android guide](../zurg/guides/android.md) after you accept the GitHub invitation |
| The full zurg source code | The private repository on GitHub |
| Every release named for rex and Plex | `dmm_api_key` in the [zurg config](../zurg/reference/config.md) |
| DMM media details without reading the file first and language checks before a release is added | Nothing beyond `dmm_api_key` |
| The `__magic__` folders sorted for you when enabled | [\_\_magic\_\_](../zurg/guides/magic.md) |
| Your DMM wanted list fetched by zurg | [DMM wanted list](../zurg/guides/dmm-wanted.md) |
| DMM's Usenet and torrent indexers searched when you have none of your own | `dmm_api_key` plus a Usenet provider or a debrid account that can add torrents |
| Releases picked by each title's original language | `original` in [audio and subtitle languages](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) |
| A wanted film no indexer carries streamed from its official YouTube upload | [Streaming a film from YouTube](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

The `dmm_api_key` features need a zurg nightly. The free public build does not include them.

## DMM

| What you get | Where |
|---|---|
| A wanted list that zurg fetches with new episodes and upgrades. Fill it from DMM or Kodi or Trakt and MDBList lists or a Radarr or Sonarr backup | [DMM wanted list](../zurg/guides/dmm-wanted.md) |
| Requests from Seerr or Overseerr or Jellyseerr land on your wanted list | [Seerr through DMM](../dmm/seerr.md) |
| Any Easynews result sent to your zurg in one click | The Easynews results on a film or show page on DMM |
| DMM as a Newznab indexer for Usenet | DMM's [Newznab page](https://debridmediamanager.com/newznab) |
| DMM as a Torznab indexer with cached-only feeds for Real-Debrid and AllDebrid and Debrid-Link and TorBox and Premiumize and Offcloud | DMM's [Torznab page](https://debridmediamanager.com/torznab). TorBox and Premiumize and Offcloud also need their linked service key |
| Seven Jellyfin plugins for debrid and Usenet libraries and six Emby plugins for debrid libraries with nothing mounted | DMM's [Jellyfin](https://debridmediamanager.com/jellyfin) and [Emby](https://debridmediamanager.com/emby) pages |
| Ten other streams per title in Stremio Cast and Kodi instead of five | DMM Settings for Real-Debrid, TorBox and AllDebrid; each provider's Cast page for the others |
| NZB uploads go first with 2 TB of Usenet a day instead of 300 GB | DMM's Usenet tab |
| The same priority and allowance for Sonarr and Radarr | Your DMM API key as the Password on DMM's [SABnzbd page](https://debridmediamanager.com/sabnzbd) |
| Three torrent uploads into Real-Debrid at once instead of one | The upload buttons on DMM search results and the library |
| Add to DMM Wanted and a Wanted folder inside Kodi | Pair Kodi on DMM's [Kodi page](https://debridmediamanager.com/kodi) |
| The DMM API for release names and cache checks and media details and metadata | [API docs](https://debridmediamanager.com/api-docs) |

## rex

rex is free and needs no sponsorship, on Android too: [rex for Android](../rex/android.md) runs rex and its addons on a phone or TV box. With a key [rex-stremio](../rex/stremio.md) adds debrid streams of torrents DMM already holds a probe of in seconds instead of probing each one. Paste it in rex-stremio's **DMM** field. It shares its probes of torrent files with DMM unless you turn that off.

## Help

| What you get | Where |
|---|---|
| Free remote help with zurg and rex in your own terminal while you watch | [Getting help](remote-help.md) |
| The Sponsor role on Discord | Connect Discord on gatekeeper |

## Earn it without paying

Fill requests on DMM's [request board](https://debridmediamanager.com/requests). Every 10 requests earn 7 days of the DMM perks above. Only one fill for the same person each day counts. Link the key from a free gatekeeper account on the board to collect them.

Earned time opens the DMM table above. It does not open the zurg nightly or source code or Discord role or remote help or the Android app. Those need a paid sponsorship. The `dmm_api_key` features also need a nightly.

Stuck? Ask in the **dmm-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP).
