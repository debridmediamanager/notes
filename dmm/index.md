---
label: DMM
icon: search
order: 70
description: "What Debrid Media Manager (DMM) is and how to use it: sign in with your debrid service, search a movie or show, add a release to your library and play it."
---

# What is DMM and how do I use it?

[Debrid Media Manager](https://debridmediamanager.com) (DMM) is a free website for finding movies and shows and adding them to your debrid account: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud or Debrid-Link. You sign in with that account, search a title and press **Instant RD** (or your service's button) on a release. It's in your library straight away, ready to watch from DMM, in Stremio or Kodi, or in Plex through [zurg](../zurg/index.md).

DMM is open source and not part of Real-Debrid or any other service. The files stay with your debrid service.

## Sign in

1. Open [debridmediamanager.com](https://debridmediamanager.com) and press your service: **Login with Real Debrid**, **Login with AllDebrid**, **Login with Torbox**, **Login with Premiumize**, **Login with Offcloud** or **Login with Debrid-Link**.
2. On Real-Debrid, press **Sign in with Real-Debrid**. DMM shows a code: press **Open real-debrid.com/device**, enter the code there and approve. The DMM page finishes on its own. You can also paste your API token from [real-debrid.com/apitoken](https://real-debrid.com/apitoken) under **or paste an API key** and press **Save API Key**.
3. Other services: follow their login page. Where it asks for an API key, copy it from your account on that service, paste it and press **Save API Key**.

![DMM's sign-in page](../assets/dmm-index/01-sign-in.webp)

Got another service too? Open **Debrid services** on DMM's home page and press its **Login** button, for example **AllDebrid Login**.

Only have Easynews? Press **Login with Easynews**. You can search Easynews and cast it to Stremio, but the library needs a debrid account. Sponsors can also sign in with **Login with DMM key**.

## Search a movie or show

1. Type a title in **Search movies & shows...** on the home page. Pick one from the suggestions, or press **Search** for the full list.
2. Press the poster. The title's page lists the releases DMM found.
3. Press your service's chip above the results (**RD**, **PM** and so on) to show only releases it already has.

![DMM's home page after signing in](../assets/dmm-index/02-home.webp)

## What the buttons on a release mean

![Releases of Sintel on DMM, signed in with Premiumize](../assets/dmm-index/03-results.webp)

| Button | What it does |
|---|---|
| **Instant RD** (**Instant TB**, **Instant AD**, **Instant PM**, **Instant OC**, **Instant DL**) | Your service already has this release. Press it and it's in your library at once. |
| **DL with RD** (**DL with TB** and so on; **Add to DL** on Debrid-Link) | Your service doesn't have it yet. Pressing it adds it anyway and the service downloads it first. Pick an **Instant** one if you want to watch now. [Why this happens](../guides/torrent-being-downloaded-to-debrid.md). |
| **RD (100%)** (**PM (100%)** and so on) | It's in your library. The number is how far the download got. Press it to remove it from your library. |
| **Check RD** (**Check AD**, **Check DL**) | Asks that service whether it has this release cached right now. |
| **Cast (RD)** (**Cast (PM)** and so on) | Sends the release to Stremio. See [DMM in Stremio](stremio.md). |
| **Watch** | Opens a **Ready to play** tab. Press **Play** and your player opens. Pick the player under **Settings** → **Video player**. |
| **Copy** | Copies the release's magnet link and says **Magnet link copied.** With **Download .magnet files instead of copy** ticked in **Settings**, it reads **Download** and saves a .magnet file. |
| **Report** | Flags a bad release: **XXX / Porn Content**, **Incorrect IMDB ID**, **Malware / Executable File**, and on shows **Tagged for Wrong Season**. |

The **Usenet** tab next to **Torrents** lists Usenet releases of the same title. **NZB** downloads one. Sending them to your library needs Real-Debrid or TorBox. Have Easynews? Add it in **Settings** and it's searched here too.

## Your library

Press **Library** on the home page. It lists everything in the accounts you signed in with: name, size, status and when it was added.

![The library's search box and buttons](../assets/dmm-index/04-library.webp)

- Search with **search by filename/hash/id, supports regex**, or narrow it with **Movies**, **TV shows** and **Others**.
- Press a row for its details and its **Hashlist**, **Delete**, **Cast** and **Copy** buttons. The icons at the end of each row do the same.
- **Backup** saves your list to a `.dmm.json` file. **RD Restore** (**PM Restore** and so on) adds a saved list back.
- **Share List** turns what's shown, or what you selected, into a hash list other people can add to their own accounts.
- **Delete List** deletes everything shown, after a **Yes, delete!** check. Search or select first.

## Where to go next

- [DMM in Stremio](stremio.md): watch what you find in Stremio with the DMM Cast addon.
- ["Torrent is being downloaded to debrid"](../guides/torrent-being-downloaded-to-debrid.md): what that screen in Stremio means and how DMM shows what's cached.
- [DMM buttons in Safari](safari.md): the browser extension adds a DMM button to IMDb, Trakt and other movie and TV sites.

DMM also serves the other projects:

- **zurg** asks DMM which movie or episode each file is. A sponsor gets the DMM API key from [gatekeeper](https://gatekeeper.debridmediamanager.com/). Without it zurg relies on file names and fewer titles match. [rex with zurg](../rex/with-zurg.md#why-dmm-places-the-files) explains the difference.
- **Sonarr Radarr and Prowlarr** can search DMM as a Torznab torrent indexer or Newznab Usenet indexer. Both need an active sponsorship and the DMM API key. Set them up on the [Torznab](https://debridmediamanager.com/torznab) and [Newznab](https://debridmediamanager.com/newznab) pages.
- **Your wanted list**: press **Want** or follow a Trakt or MDBList list. zurg fetches it and new episodes as they air. Sponsorship required. See [DMM wanted list](../zurg/guides/dmm-wanted.md).
- **Seerr Overseerr and Jellyseerr** can use DMM as Radarr and Sonarr. Requests then land on your wanted list for zurg to fetch. Sponsorship required. See [Seerr through DMM](seerr.md).
- **rex-direct** gives a claimed rex its own address and certificate. See [rex-direct](../rex/any-source.md#rex-direct).

Everything a sponsorship opens and where each thing is set up is on [What a sponsorship gives you](../guides/sponsorship.md).

## When something is wrong

| What you see | What to do |
|---|---|
| **Real-Debrid rejected that API key.** | The token you pasted isn't a working one. Copy it again from [real-debrid.com/apitoken](https://real-debrid.com/apitoken), or press **Sign in with Real-Debrid** instead. |
| **That code expired before it was approved. Try again.** | The Real-Debrid code timed out. Press **Sign in with Real-Debrid** again and approve the new code sooner. |
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | TorBox's free plan can't be used with DMM. Upgrade it, or sign in with another service. |
| Only **DL with RD** buttons, no **Instant RD** | Your service has none of these releases cached. Press one and wait for it to download, or try another release. |

Stuck? Ask in the **dmm-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) says what to include.

## Questions

### What actually is DMM?

A search site for your debrid account. It finds releases of a movie or show, tells you which ones your service already has, and adds the one you pick to your account. DMM itself stores no files.

### How do I use it?

Sign in with your debrid service, search a title, open it and press **Instant RD** (or your service's **Instant** button) on a release. Then press **Watch**, cast it to Stremio, or let zurg put it in Plex.

### Is DMM made by Real-Debrid?

No. DMM is an open-source project that works with Real-Debrid and five other services. People often search for it as "Real-Debrid Media Manager".

### Is it free?

Yes. You need your own debrid account, which is a paid service. A DMM sponsorship adds extras like the wanted list and the indexers: see [What a sponsorship gives you](../guides/sponsorship.md).

### Which services work?

Real-Debrid, AllDebrid, TorBox (paid plans), Premiumize, Offcloud and Debrid-Link. Easynews works for search and casting, not for the library.
