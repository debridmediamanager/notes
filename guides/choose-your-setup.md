---
label: Choose your setup
icon: workflow
order: 100
---

# Which setup should I use?

**Start with the app you want to watch in.** You do not need to install everything. DMM helps you find and choose releases; a provider supplies the files; zurg can turn those files into a shared library; rex presents a library to Plex apps. Several routes skip one or more of those pieces.

This is a map of the supported route families, checked against the projects on **8 November 2026**. It includes alternatives outside the stack where they remove a step. It is not a promise that every third-party addon, TV model or combination works. Follow the linked setup guide for your chosen route and its tested limits.

## Pick by what you already use

On a phone, swipe a table sideways to see all its columns.

| I have / want… | Choose this route | Why choose it? | What you take on |
|---|---|---|---|
| Stremio and a debrid account; no server to maintain | **DMM Cast → Stremio**, or your existing stream addon | Watch through your account without running zurg, rex or a media server | The addon and provider must supply a playable stream; the device handles playback |
| Kodi and a debrid or Easynews account | **DMM's Kodi addon → your account** | Browse, search and play inside Kodi; pair from your phone | Kodi does the playback. A sponsor's Wanted list still needs zurg to fulfil requests |
| One movie to watch in my usual player | **DMM Watch → external player** | No library server needed | Install a supported player and choose a file it can play |
| Infuse, Kodi or another WebDAV player | **Provider WebDAV**, if it meets your needs; otherwise **zurg → WebDAV player** | Browse a cloud library without Plex, Jellyfin, Emby or rex | zurg needs a running host; direct provider WebDAV depends on that provider's offering |
| Plex Media Server already working | **zurg → mounted folder → Plex Media Server → Plex app** | Keep your server, its libraries and existing workflows | Run zurg and a filesystem mount alongside the server; scans read remote files |
| Plex apps, but no wish to maintain a mounted library | **zurg → rex → Plex app** | zurg supplies the library to rex without a mount or Plex Media Server | Both services stay running; check rex's app compatibility and account guidance |
| Stremio addons, but I prefer Plex apps | **Addons → rex-stremio → rex → Plex app** | Turn addon catalogs into Plex libraries; zurg is optional | Run rex and rex-stremio; stream addons must return playable URLs, not raw torrents |
| Jellyfin and only its clients need the library | **Provider plugin inside Jellyfin → Jellyfin app** | No separate zurg service or mount | Jellyfin 12 and the matching plugin(s); plugins have their own archive limits |
| Emby and only its clients need the library | **Provider plugin inside Emby → Emby app** | Keep everything inside the existing Emby server | Use the supported Emby version; these six plugins cover debrid, not direct Usenet |
| Jellyfin/Emby plus other players or an arr stack sharing the files | **zurg → mount → Jellyfin/Emby** | One library can serve more than one consumer | Maintain the mount and server paths; use each server's clients to watch |
| My own Usenet account and Stremio | **Newznab indexer → zurg's Stremio addon → Stremio** | Search at playback time and stream through your news account | A running zurg, indexer access and NNTP credentials; another device needs a reachable HTTPS addon address |
| An Android/Google TV device, without another computer | **zurg Android → player on that device** | Run the library engine on the device you watch on | Sponsor access, sideloading and background operation; Usenet needs 64-bit Android |
| Files already on a disk/NAS | **Existing media server or network player**; **HTTP source → rex** if you want rex | Keep using the files you own; no debrid or Usenet account needed | rex needs an adapter that publishes metadata and serves the files; it does not scan disks |

Start here: [DMM Cast](https://debridmediamanager.com/stremio/) · [Kodi](https://debridmediamanager.com/kodi) · [DMM Settings / player choice](https://debridmediamanager.com/settings) · [zurg setup](../zurg/setup/index.md) · [rex with zurg](../rex/with-zurg.md) · [rex with Stremio addons](../rex/stremio.md) · [Jellyfin plugins](https://debridmediamanager.com/jellyfin) · [Emby plugins](https://debridmediamanager.com/emby) · [zurg's Stremio addon](../zurg/guides/stremio.md) · [Android](../zurg/guides/android.md) · [rex with any source](../rex/any-source.md).

The Cast link starts with Real-Debrid. DMM also has Cast setup pages for [TorBox](https://debridmediamanager.com/stremio-torbox/), [AllDebrid](https://debridmediamanager.com/stremio-alldebrid/), [Premiumize](https://debridmediamanager.com/stremio-premiumize/), [Offcloud](https://debridmediamanager.com/stremio-offcloud/), [Debrid-Link](https://debridmediamanager.com/stremio-debridlink/) and [Easynews](https://debridmediamanager.com/stremio-easynews/). Use the one for your account. Cast here means the **DMM addon**, not Chromecast or screen mirroring.

## The playback map

Arrows mean “supplies a library or playable stream to.” They are not a packet-routing diagram: depending on the route, the player may fetch from the provider or the server may carry the bytes.

[Open the playback map full size](../assets/setup-routes/playback.svg) to zoom or save it.

```mermaid
flowchart TD
    A[Debrid account] --> B[DMM Cast]
    E[Easynews account] --> B
    B --> C[Stremio]
    B --> K[DMM Kodi addon]
    A --> Z[zurg]
    N[Own Usenet or TorBox hosted NZBs] --> Z
    Z --> W[WebDAV player]
    Z --> M[Filesystem mount]
    M --> S[Plex Media Server, Jellyfin or Emby]
    S --> P[That server's apps]
    Z --> R[rex]
    T[Stremio catalogs and URL stream addons] --> X[rex-stremio]
    X --> R
    H[Other HTTP source with rex feed] --> R
    R --> Q[Plex apps]
```

Two smaller routes are worth keeping separate:

[Open the plugin map full size](../assets/setup-routes/plugins.svg).

```mermaid
flowchart LR
    D[Debrid account] --> J[Plugin inside Jellyfin or Emby]
    J --> A[That server's apps]
    U[NZBs and own news account] --> N[NZB plugin inside Jellyfin]
    N --> F[Jellyfin apps]
```

The plugins are independently implemented integrations. “zurg” in their names does **not** mean you must run the separate zurg application, or that every feature of that application exists in a plugin. The TorBox plugin's torrent-library support, for example, is not a promise of parity with zurg's hosted-NZB backend.

## Choose where the files come from

An **indexer** finds releases. A **torrent or NZB** describes how to fetch one; it is not the video. A **provider** supplies the bytes. A **player** decodes them. Buying access to one of these does not automatically buy the others.

| Input | What obtains/serves the video? | What you need | When it is useful |
|---|---|---|---|
| Cached torrent, magnet or torrent file | Your debrid provider | An account supported by your chosen integration | Often the shortest wait when the exact release is already available |
| Uncached torrent | The debrid provider downloads it first | An account that accepts the torrent, available sources and room within its limits | A release you want is not cached; expect a wait and possible failure |
| NZB, using your own news accounts | zurg's **direct Usenet** backend reads articles as needed | NZBs, NNTP access and zurg; indexer access if you want search | Choose your providers/backbones, use fallback accounts, avoid storing whole videos locally |
| NZB, using TorBox's hosted service | **TorBox fetches and repairs it**, then serves the completed files | TorBox Pro; submit through DMM or zurg's **TorBox hosted NZB** backend | You want NZBs without managing news-server credentials or local decoding |
| DMM Usenet result sent to Real-Debrid | DMM's hosted transfer service fetches it and passes it to **your Real-Debrid library** | Real-Debrid and an available DMM transfer allowance | You already watch through RD and want that release there; no personal NNTP account required |
| Easynews search result | Easynews serves a direct HTTP download/stream | Your own Easynews account | Watch/download from DMM, or use its Easynews Cast/Kodi route, without building an NZB library |
| Direct HTTP(S) download link | A compatible player, HTTP source, or TorBox web download | Access to the actual media URL; TorBox account if importing it there | You already have a file URL rather than a torrent/NZB |
| Files on your disk or NAS | Your file/media server | Local storage and a player that can reach it | Offline ownership, home videos, or keeping an existing collection |

zurg's debrid integrations cover **Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud and Debrid-Link**. You can combine accounts in one zurg library. That does not make providers' caches, quotas or file availability identical. A cached badge is useful evidence, not a guarantee that your account can play the file now. See [providers](../zurg/providers/index.md).

### “Usenet without a Usenet account”: which route?

[Open the Usenet map full size](../assets/setup-routes/usenet.svg).

```mermaid
flowchart TD
    N[NZB or Usenet search result] --> O{Who fetches it?}
    O --> A[Your news accounts]
    A --> Z[zurg direct Usenet]
    Z --> V[Your chosen zurg playback route]
    O --> T[TorBox Pro hosted Usenet]
    T --> B[TorBox completed files]
    B --> C[DMM TorBox Cast or zurg hosted NZB library]
    O --> D[DMM hosted transfer]
    D --> R[Your Real-Debrid library]
    R --> P[Your chosen RD playback route]
```

**Choose TorBox hosted NZBs** if you want TorBox to do the downloading and repair. In DMM, the TorBox action on Usenet results sends the NZB to that service. In current zurg nightlies, the provider type is `torbox_nzb`; it also accepts NZBs from the watch directory, acquisition and the SABnzbd-compatible interface. A cache miss must finish downloading on TorBox before it plays. Active downloads share the account's slots with torrents, and retained files can expire. Keep the NZBs for re-fetching; zurg does not promise to re-download expired releases unattended.

**Choose direct Usenet** if you want zurg to read through your own news accounts, including fallback/block accounts. It uses `nzb`, with NNTP credentials. A TorBox news-server login also belongs to this route: [TorBox NNTP](../zurg/providers/torbox-news-server.md) is distinct from its hosted NZB downloader. [TorBox's own tools page](https://torbox.app/tools) describes that NNTP offering; [its plans](https://torbox.app/pricing) describe hosted-service entitlements.

**One zurg instance uses either `nzb` or `torbox_nzb`, not both.** Both own the NZB watch directory. To run both, use separate zurg instances and separate working directories. Either can sit beside torrent-provider accounts. zurg's Stremio addon can submit to the selected NZB backend too; an uncached hosted download may take longer than a playback request waits, so it is not a guarantee of instant play.

**Choose DMM → Real-Debrid** if the desired end result is a release in your RD library. This is a hosted transfer, with queues and allowances; an uncached job takes time. It does not give Real-Debrid native NNTP support, and it does not mean every debrid provider accepts NZBs. The DMM result and [Transfers page](https://debridmediamanager.com/transfers) show the job's progress.

Easynews adds another choice: its **Watch**, **Download** and **Cast** actions use Easynews's HTTP files. **Send to zurg** instead places that release's NZB on your sponsor Wanted list for zurg to fetch. The latter needs a configured NZB backend; an Easynews web login in DMM does not configure zurg's news servers.

### What about HTTP links?

DMM's TorBox **Add** dialog accepts direct HTTP(S) download links as web downloads. zurg can expose TorBox web downloads, and DMM's TorBox Cast catalog includes completed web and Usenet downloads as well as torrents. This does not make an arbitrary website page a video: login pages, expiring URLs, DRM and a site's own player can require a different integration.

For rex, an HTTP URL alone is not a library. A [source or addon](../rex/any-source.md) must describe the item through the feed API and serve playable bytes. [rex-stremio](../rex/stremio.md) does that for compatible Stremio addons. Raw magnets and torrent-only streams do not work through it; HLS streams need rex's FFmpeg setup. rex does not identify releases or search filenames to decide what a file is: its source supplies that identity.

## Decide how titles get added

Acquisition and playback are separate choices. You can change how a title is requested without replacing the app you watch in.

| How you choose titles | Route | Why use it? |
|---|---|---|
| Pick the exact release | DMM search/library → provider; or an NZB → your selected NZB backend | Control the edition, size and release yourself |
| Press Want, or follow a Trakt/MDBList list | [DMM Wanted](../zurg/guides/dmm-wanted.md) → zurg acquisition | Automatic films and new episodes without running Sonarr/Radarr; sponsorship required |
| Family requests in Seerr/Overseerr/Jellyseerr | [Seerr through DMM](../dmm/seerr.md) → Wanted → zurg | Familiar request UI without an arr server; sponsorship required |
| Already have Plex watchlists or a request stack | [zurg acquisition](../zurg/guides/acquisition.md) | Keep the existing request source; configure its search and provider targets |
| Want detailed monitoring and quality profiles in Sonarr/Radarr | DMM or your indexers → arr → zurg download-client interface → library | Keep arr's decisions and import workflow; more services and path setup |
| Want to choose only when pressing Play | DMM Cast/Kodi, another stream addon, or zurg's Stremio search | No need to pre-build a managed library of every title |

For arr, **DMM is the indexer; zurg is the download client**. DMM offers [Torznab for torrents](https://debridmediamanager.com/torznab) and [Newznab for Usenet](https://debridmediamanager.com/newznab), both requiring active sponsorship. Prowlarr is optional. zurg exposes a [qBittorrent-compatible interface for torrents](../zurg/guides/sonarr-radarr-torrents.md) and a [SABnzbd-compatible interface for NZBs](../zurg/guides/sonarr-radarr.md). Those are interfaces built into zurg; they do not require those two downloader applications alongside it. [zurg can also help search for arr](../zurg/guides/sonarr-radarr-fetch.md).

If you want **complete local copies** instead, keep a conventional downloader and disk-based library. zurg's virtual files, `.strm` links and [local debrid catalogs](../zurg/guides/local-libraries.md) are not offline copies. A local debrid catalog stores the library's records locally; playback still depends on the provider.

## The tradeoffs that matter before installing

| Question | What changes your choice |
|---|---|
| Must another machine stay on? | Hosted Cast/Kodi routes do not need your own server. zurg, rex, rex-stremio and media-server plugins do need their host while you watch. zurg Android can make the viewing device that host. A rented/managed host changes who runs it, not the underlying route. |
| Will my TV play the file? | WebDAV and addon routes depend on the player's codecs, audio and subtitles. zurg serves bytes; it is not a video transcoder. Plex Media Server, Jellyfin, Emby or rex with FFmpeg can convert when needed, with appropriate hardware and server/app capabilities. |
| How much disk space? | Streaming avoids storing the whole collection. Allow space for databases, artwork, caches and any repair, transcode or offline-download work. “No full download first” does not mean zero disk use. |
| Who pays for bandwidth? | Provider traffic quotas still apply. A server proxy carries playback traffic and uses its outgoing bandwidth; direct playback shifts the connection to the viewer. Library analysis can read remote files too. |
| Will it work away from home? | Hosted addons avoid exposing your own server. Self-hosted services need a securely reachable address; a LAN address alone will not work remotely. See [rex remote access](../rex/any-source.md#use-it-outside-your-home-optional) and the [Stremio HTTPS guidance](../zurg/guides/stremio.md#installing-it-on-another-device). |
| Can family use it simultaneously? | Check your provider's IP/concurrency rules and the server's sharing model. Real-Debrid use must stay on one public IP; direct links to different households can violate that even when a central library supplied them. Do not enable redirects without understanding where the downloads originate. |
| What do I pay for? | Keep provider subscriptions, indexer access, DMM sponsorship, hosting and player/server purchases separate. DMM's basic website and rex for personal use are free. Current zurg nightlies and DMM's plugin distribution are sponsor benefits; Wanted and DMM's indexer APIs also need sponsorship. rex-stremio does not require it. |
| Does a catalog entry guarantee playback? | No. Addon catalogs describe titles; cloud files can expire; torrents can lack sources; Usenet articles can be missing. Pick the route whose failure and waiting behavior you are comfortable with. |

Infuse supports [WebDAV and other network shares](https://support.firecore.com/hc/en-us/articles/215090977-Streaming-From-a-Mac-PC-or-NAS). A `.strm` file is another way to hand a compatible player such as Kodi a URL. It is not a universal substitute for a mount: check the client, and expect different proxy/failover behavior. Do not choose `.strm` as the normal Plex Media Server setup.

There is also a [legacy free zurg release](https://github.com/debridmediamanager/zurg-public/releases). It is Real-Debrid-only, with a different configuration format; the current multi-provider, Usenet and Android routes here refer to sponsor nightlies.

**rex has its own compatibility boundary.** It is an independent server for Plex apps, not Plex Media Server or a Plex plugin. Use its [FAQ](../rex/faq.md) for tested devices, transcoding, remote use and the fresh-account recommendation. Not every Plex app has been tested, and Plex's services and apps can change. A traditional Plex server can remain alongside rex.

## Other media and existing setups

- **Music:** [rex music sources](../rex/music.md) feed Plexamp and supported Plex apps. A source can be an addon or zurg configured for music. Do not assume a movie/TV addon supplies music too.
- **Live TV:** [rex's Live TV route](../rex/live-tv.md) provides channels and a guide in the documented apps. Live channels from rex-stremio instead form a library of channels; that is not the same guide interface. Check source availability. rex does not provide DVR recording.
- **Home videos, recordings and photos:** use an existing media server, or a [rex source you control](../rex/addons.md). The [home-video tutorial](../rex/addon-home-videos.md) shows the latter. zurg can also supply comic books as photos to rex; app support differs.
- **Existing Kodi/Stremio addons:** if yours already gives the experience you want, keep it. DMM can be the place you select and manage releases without replacing your player. Addon support for providers, Usenet and HTTP varies; the DMM route is not a compatibility promise for all addons.
- **Another debrid mount/downloader already installed:** see [migration choices](../zurg/migrate/index.md) before switching. A working setup does not need another layer solely because it exists.
- **Native apps in development:** Usenet TV is not a released app-store setup to recommend here. Yomu TV is a separate reading/audiobook project, not a route for this movie/TV stack. Neither is required for the routes above.

## Five common starting points

1. **“I have Stremio and RD.”** Start with DMM Cast. Add zurg only when you want a shared library, automation or another consumer that needs it.
2. **“I have TorBox Pro and want the NZBs in that post.”** Send the NZB to TorBox through DMM. Use TorBox Cast to watch in Stremio, or zurg's hosted NZB backend to feed your chosen library/player route.
3. **“I already have Jellyfin.”** Start with the plugin for your provider. Choose separate zurg when you need its shared filesystem, automation or broader backend capabilities.
4. **“I want Plex apps, no mounts, and my existing addons.”** Use rex-stremio with rex. Use zurg as a source instead when the thing you want to expose is your managed debrid/Usenet library. Both sources can feed the same rex.
5. **“I have news accounts and want Sonarr/Radarr.”** Use DMM Newznab or your existing indexers, zurg's NZB/SABnzbd route and a playback route from the first table. Keep a normal downloader instead if permanent local files are the goal.

Still unsure? Tell us **your device/player, accounts you already have, whether a host can stay on, and whether you want on-demand playback or an automatically managed library**. Those four answers usually decide the route. [Getting help](remote-help.md) says where to ask.
