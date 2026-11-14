# Usenet for beginners: what to buy and how it fits with zurg

To stream Usenet with zurg you need a **Usenet provider** account, which holds the files, and **NZB files**, which say where each release is. An **indexer** is a search site for NZBs, but you don't have to buy one: DMM's **Usenet** tab finds NZBs for any movie or show. zurg then plays the release straight from your provider, with nothing downloaded first.

## The three pieces

| Piece | What it is | Do you pay for it? |
|---|---|---|
| Provider, or news server | The service that stores the posts. You get a server address, a username, a password and a number of connections. zurg reads from it. | Yes. It's the one thing you have to buy. |
| NZB | A small file that lists the pieces of one release, like a `.torrent` file does for torrents. | No. |
| Indexer | A search site that makes NZBs. Sonarr, Radarr and Prowlarr search one. | Optional. |

A release on Usenet is posted as thousands of small pieces. The NZB lists them, your provider serves them, and zurg puts them back together into the video your player asks for.

## What you need

1. **A zurg sponsorship.** Usenet is in zurg's nightly builds, which come with a [sponsorship](sponsorship.md). The free public zurg is Real-Debrid only.
2. **One Usenet provider account.** Two numbers matter when you compare plans:
   - **Retention**: how many days back the server keeps posts. Older films and shows need more.
   - **Connections**: how many the plan allows at once. zurg reads at that number, so put your plan's real figure in its config.
3. **NZBs.** Save them from DMM's Usenet tab, get them from your own indexer, or let Sonarr, Radarr or zurg find them.

You don't need:

- **A download client** like SABnzbd or NZBGet. zurg streams the release. For Sonarr and Radarr, zurg acts as SABnzbd itself: see [Sonarr & Radarr for Usenet](../zurg/guides/sonarr-radarr.md).
- **Disk for whole releases.** zurg fetches only the parts that cover what's playing. A 60 GB remux doesn't need 60 GB of disk.
- **Tools to unpack or repair.** zurg plays from inside RAR sets and rebuilds missing parts from the release's PAR2 files itself.
- **A debrid account.** Usenet works on its own, or beside Real-Debrid and TorBox in the same zurg library.
- **An indexer membership**, at least to start. See [the indexer question](#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers) below.

Worth adding later: **a second provider.** A post one provider has lost is often still on another. When one doesn't have a piece, zurg asks the next. With only one, zurg has to read the whole release to rebuild that piece. See [a second news server](../zurg/providers/usenet.md#a-second-news-server-is-worth-more-than-it-looks).

## How zurg plays it

1. An NZB lands in zurg's `nzbs/` folder. You put it there, or Sonarr, Radarr or zurg itself does.
2. Within a second or two zurg reads it and lists the release in its library, named after the NZB.
3. You press play in Plex, Jellyfin or rex. zurg fetches the pieces for that spot from your provider and hands them over. Skip ahead and it fetches from there.

Nothing waits for a download to finish. To set it up step by step, follow [Usenet with zurg](../zurg/guides/usenet.md). The provider settings and Docker details are on [Usenet provider](../zurg/providers/usenet.md).

## Where DMM fits

Every movie and show page on [DMM](https://debridmediamanager.com) has a **Usenet** tab next to **Torrents**. It lists Usenet releases of that title from DMM's indexers. Anyone signed in to DMM can use it.

![DMM's Usenet tab for Night of the Living Dead (1968), signed in with TorBox Pro](../assets/usenet-for-beginners/01-dmm-usenet-tab.webp)

What a row can do depends on what you're signed in with:

| Button | What it does | Needs |
|---|---|---|
| The file icon at the end, or **NZB** when it's the only button | Saves the NZB, named after the release, with the indexer's watermark taken out. Put it in zurg's `nzbs/` folder. | A DMM sign-in |
| **Send** | DMM fetches the release from Usenet and adds it to your Real-Debrid library. You need no Usenet account for this. | Real-Debrid |
| **TorBox** | Sends the NZB to TorBox, which downloads the release for you. | TorBox Pro, see [TorBox in DMM](../dmm/torbox.md) |

Sponsors get two more:

- **zurg searches DMM's indexers for you.** With your DMM API key in zurg's config as `dmm_api_key` and no indexers of your own, zurg searches DMM's when it fetches your [DMM wanted list](../zurg/guides/dmm-wanted.md) or your [watchlist](../zurg/guides/acquisition.md).
- **DMM as a Newznab indexer** for Sonarr, Radarr and Prowlarr. Set it up on DMM's [Newznab page](https://debridmediamanager.com/newznab). Each key gets 30 searches and 15 grabs a minute, and 250 grabs a day.

## When something is wrong

| What you see | What to do |
|---|---|
| zurg log: `Cannot reach the news server for nzb` | zurg can't sign in to your provider. Check the server address, username and password. Port `563` goes with `tls: true`, port `119` with `tls: false`. |
| zurg log: `Usenet account <name> is not reachable` | One of several accounts failed and the others keep working. Fix that account's details. |
| Your provider refuses connections, for example `502 Too many connections` | `connections` in zurg's config is higher than your plan allows, or another app uses the same login. Lower it to your plan's number. |
| A release shows up as `indexer_download_48213` or similar | zurg names a release after its NZB file. Rename the `.nzb` to the release name. |
| A file inside the release has a random name | The post hid its file names and zurg couldn't get them back. Pick another release. |
| zurg log: `rar: RAR4 header-encrypted archives are not supported` | That release's archive is locked in an old format zurg can't open. Pick another release. |
| Playback stutters or a gap plays silent | Pieces of the release are gone from your provider. zurg rebuilds them from PAR2 files when the post has them. A second provider fixes most of these. |
| DMM: **No Usenet results found.** | DMM's indexers have nothing for this title. Try the **Torrents** tab, or your own indexer. |

The full troubleshooting table is on [Usenet with zurg](../zurg/guides/usenet.md#troubleshooting). Stuck? Ask in the **zurg-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](remote-help.md) says what to include.

## Questions

### Can someone explain the Usenet system to me?

Usenet is a network of news servers that store posts. A release is posted as thousands of small pieces. A provider sells you access to its servers, an NZB lists the pieces of one release, and an indexer is where you search for NZBs. zurg takes an NZB and plays the release straight from your provider.

### Do you have to have lifetime memberships with the Usenet indexers?

No. You don't need any indexer to start: DMM's Usenet tab finds NZBs for you, and a sponsor's zurg can search DMM's indexers itself. If you want your own indexer for more results, any Newznab indexer works in zurg, Sonarr and Radarr, whichever plan you pick.

### How are the files supposed to be named for Usenet?

Name the NZB after the release, like `Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb`. zurg uses that name for the release's folder, and that's what Plex and the others match on. An NZB that carries a name inside it uses that one instead. DMM's NZB button already saves the file under the release name.

### Does zurg do Usenet?

Yes, in the nightly builds for sponsors. Give it your provider's details, drop NZBs into `nzbs/` and they play. [Usenet with zurg](../zurg/guides/usenet.md) walks through it.

### What is TorBox NNTP?

TorBox's Pro plan has two Usenet features. Its pricing page shows Usenet on Pro only (checked 14 November 2026).

- **Hosted Usenet downloads.** TorBox downloads the whole release for you and serves it like any other TorBox download. Send NZBs from DMM's Usenet tab or from zurg's `torbox_nzb` provider. You need no news server login. See [TorBox hosted Usenet](../zurg/providers/torbox-nzb.md).
- **A news server login (NNTP).** Use it in zurg like any provider. It allows 10 connections. Measured in September 2026, it found less of a real library than three other paid providers, so it works best as a spare. See [TorBox news server](../zurg/providers/torbox-news-server.md).

### Can I use one Usenet account in two places?

Better not. Two apps on one login share its connections and push each other off: the server can drop the older connection to let the newer one in. Some providers' terms forbid sharing an account. Give each zurg its own account.
