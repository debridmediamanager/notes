---
label: DMM in Stremio
icon: play
order: 90
description: "How to watch what you find on Debrid Media Manager in Stremio with the DMM Cast addon, and what to do when it goes wrong."
---

# Use DMM in Stremio with DMM Cast

DMM Cast is Debrid Media Manager's Stremio addon. It is how DMM shows up in Stremio: you pick a release on DMM, press **Cast**, and Stremio lists it as a stream that plays from your own debrid or Easynews account. In short: sign in on DMM, open your provider's Cast page, install the addon in Stremio, then press **Cast** on any movie or show.

Cast here means the DMM addon. It is not Chromecast or screen mirroring.

## What you need

- A DMM sign-in with Real-Debrid, TorBox, AllDebrid, Premiumize, Offcloud, Debrid-Link or Easynews.
- Stremio. [Stremio Web](https://web.stremio.com) works without a Stremio account.

No sponsorship needed.

## Set it up

1. Sign in on [debridmediamanager.com](https://debridmediamanager.com) with your provider. Easynews signs in under **Settings**.
2. On DMM's home page press **Cast for RD**, **Cast for TB** and so on. With several accounts signed in, there is one **Cast** row with a button per provider. Each provider has its own Cast page:

   | Provider | Cast page |
   |---|---|
   | Real-Debrid | [debridmediamanager.com/stremio](https://debridmediamanager.com/stremio) |
   | TorBox | [debridmediamanager.com/stremio-torbox](https://debridmediamanager.com/stremio-torbox) |
   | AllDebrid | [debridmediamanager.com/stremio-alldebrid](https://debridmediamanager.com/stremio-alldebrid) |
   | Premiumize | [debridmediamanager.com/stremio-premiumize](https://debridmediamanager.com/stremio-premiumize) |
   | Offcloud | [debridmediamanager.com/stremio-offcloud](https://debridmediamanager.com/stremio-offcloud) |
   | Debrid-Link | [debridmediamanager.com/stremio-debridlink](https://debridmediamanager.com/stremio-debridlink) |
   | Easynews | [debridmediamanager.com/stremio-easynews](https://debridmediamanager.com/stremio-easynews) |

   ![DMM Cast page for Premiumize, with the addon address blurred](../assets/dmm-stremio/01-dmm-cast-page.webp)

3. Press **Install (web)**. Stremio Web opens with the addon. Press **Install** there.

   ![Stremio Web asking to install DMM Cast](../assets/dmm-stremio/02-stremio-install.webp)

   For another Stremio, copy the address shown under the buttons and add it there. In Stremio Web that is **Addons** → **Add addon** → paste → **Add** → **Install**. The address is private to your account: never share it.

4. Back on DMM, search for a movie or show and open it. Releases your provider already has get a **Cast** button: **Cast (RD)**, **Cast (TB)**, **Cast (AD)**, **Cast (PM)**, **Cast (OC)** or **Cast (DL)**. Press it. DMM confirms with **Cast started in Stremio** (on a show, **Casting succeeded.** and how many episodes it cast) and tries to open the title in your Stremio app.

   ![Pressing Cast (PM) on DMM](../assets/dmm-stremio/03-dmm-cast-button.webp)

5. Open the title in Stremio. Your cast is listed as **DMM Cast PM (Yours)** (RD, TB and so on for other providers). Press it to play.

   ![Stremio listing the cast as DMM Cast PM (Yours)](../assets/dmm-stremio/04-stremio-streams.webp)

## What else you get in Stremio

- **DMM Cast PM ✨ · Cast a file inside a torrent** on every movie and episode. It opens that title on DMM, so you can cast a release from there.
- Up to five more streams from other people's casts and from releases your provider already has. Set the number under **Other streams limit** on the Cast page. Sponsors can raise it to ten.
- Rows on Stremio's Board: **DMM PM Movies** and **DMM PM TV Shows** hold your casts. **DMM PM Library** holds everything in your account, and each item opens with its files. Easynews has no Library row.
- Don't want the rows? Install the addon with **Without catalogs** → **Install (web)** instead. The streams still show.
- **Manage Casted Links** on the Cast page lists your casts. Tick the ones to go (or **Select All**) and press **Delete Selected** to take them off Stremio.
- **Hide "Cast a file inside a torrent" option** on the Cast page removes the ✨ row.

On Debrid-Link, casting adds the release to your account. One that Debrid-Link does not have yet starts a real download and uses one of your 50 torrents for the day.

## When something is wrong

| What you see | What to do |
|---|---|
| Only **DMM Cast PM ✨ · Cast a file inside a torrent** (RD, TB…) shows, no other streams | Nothing has been cast for this title yet. Press that row: it opens the title on DMM. Press **Cast** on a release, then open the title in Stremio again. |
| **⚠️ DMM Cast · Set up DMM Cast for Premiumize again** (or your provider) as the only stream | The addon in Stremio no longer matches your DMM sign-in. Press it to open your Cast page, sign in, then remove the old addon from Stremio and install it again from that page. |
| **Real-Debrid Required. You must be logged in with Real-Debrid to use the Stremio Cast feature.** (or TorBox, Easynews…) | You are not signed in to that provider on DMM, or you opened another provider's Cast page. Press **Login with …**, or use the **Cast for …** button on DMM's home page. |
| **No episodes in this release on Premiumize** | DMM could not match that release's files to episodes. Cast a different release. |
| The addon address pasted into the search bar at the top of Stremio Web does nothing | That bar only searches. Use **Addons** → **Add addon**. |

Stuck? Ask in the **dmm-cast-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) says what to include.

## Questions

### Can I search DMM in Stremio?

No. DMM Cast adds no search to Stremio, and Stremio's search shows nothing from it. Search on [debridmediamanager.com](https://debridmediamanager.com) and press **Cast**. From a title you already have open in Stremio, the ✨ row takes you to that title on DMM.

### Does it work on my TV, Fire TV or phone?

Casts are kept on DMM, not on the device you cast from. Every Stremio that has your addon address lists them. Cast from your phone or computer, then pick the **(Yours)** stream in Stremio wherever you watch.

### Which providers work?

Real-Debrid, TorBox, AllDebrid, Premiumize, Offcloud, Debrid-Link and Easynews. Each has its own Cast page and its own addon. Install one for every account you want in Stremio.

### Why does Stremio show only Cast and no stream?

Nothing has been cast for that title yet. Press the ✨ row, cast a release on DMM, then open the title in Stremio again.

### Can I play my whole debrid library in Stremio?

Yes. The **DMM Library** row on Stremio's Board lists everything in your account (not on Easynews). Open an item to see its files.

### Do I need a sponsorship?

No. For DMM Cast, a sponsorship only raises **Other streams limit** from five to ten. Get your DMM API key on [gatekeeper](https://gatekeeper.debridmediamanager.com/) and paste it in DMM's **Settings**.
