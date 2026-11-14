# TorBox in DMM

DMM works with a paid TorBox plan: Essential, Standard or Pro. Paste your API key from [torbox.app/settings](https://torbox.app/settings) on DMM's **Connect Torbox** page, then search: releases TorBox already has get **Instant TB**. The free plan has no API access, so DMM can't use it, and sending Usenet releases to TorBox needs Pro.

## Sign in

1. On [debridmediamanager.com](https://debridmediamanager.com) press **Login with Torbox**. Already signed in with another service? Open **Debrid services** on the home page and press **Torbox Login**.
2. Press **Get API Key from Torbox**. It opens [torbox.app/settings](https://torbox.app/settings), where your API key is.
3. Paste the key into **API Key** and press **Save API Key**.

![DMM's Connect Torbox page turning down a free-plan key, key blurred](../assets/dmm-torbox/01-free-plan.webp)

Once you're in, the home page shows **Cast for TB** and **Requests**, and **Debrid services** lists your TorBox account with a ✓. Press it to see your plan and when it runs out, or to **Add another account** or **Logout**.

## What each plan can do

| | Free | Essential or Standard | Pro |
|---|---|---|---|
| Sign in to DMM | No | Yes | Yes |
| **Instant TB**, **DL with TB**, the library and **Cast (TB)** | No | Yes | Yes |
| Send Usenet releases to TorBox | No | No | Yes |
| Downloads at once (TorBox's active slots) | 1 | 3 or 5 | 10 |

Sign in with a free-plan key and DMM says **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** TorBox's own [pricing page](https://torbox.app/pricing) lists API access as not included on Free, and Usenet on Pro only.

## Find what TorBox already has

1. Search a movie or show and open it.
2. DMM asks TorBox which releases it has cached. Those show **Instant TB** and **Cast (TB)** and are listed first. The **TB ✓** chip above the results shows only those. It writes `is:tb` in the filter box; press it again to show everything.
3. Press **Instant TB**. The release is in your TorBox library right away.

![Night of the Living Dead (1968) on DMM with TorBox: Instant TB, Cast (TB) and DL with TB](../assets/dmm-torbox/02-results.webp)

Releases TorBox doesn't have show **DL with TB**. Pressing it makes TorBox download the release first, which uses one of your active slots while it downloads. **No seeders** next to the size means nobody shares it right now, so it may never finish. TorBox always adds the whole release: there's no picking single files.

## Your library

Press **Library**. It lists your TorBox torrents and web downloads.

- **TB Add** opens **Add to your TB library**. Paste magnet links, upload `.torrent` files, or paste direct download links, which TorBox fetches as web downloads.
- **Backup** saves your list to a file. **TB Restore** adds a saved list back.
- The rest works as for any service: see [your library](index.md#your-library).

Usenet downloads you sent to TorBox are not in DMM's library. Find them on TorBox's site, in the **DMM TB Library** row of DMM Cast in Stremio, or through zurg's [TorBox hosted Usenet](../zurg/providers/torbox-nzb.md).

## Watch in Stremio

Press **Cast for TB** on the home page and install the addon from there. Then press **Cast (TB)** on any release TorBox has cached. All the steps are in [DMM in Stremio](stremio.md).

In Stremio the addon is called **DMM Cast for TorBox**. Its **DMM TB Library** row lists your TorBox torrents plus your finished web and Usenet downloads.

## Send Usenet releases to TorBox (Pro)

1. Open a movie or show and press the **Usenet** tab.
2. With TorBox Pro the list is headed **Send to TorBox** and each release has a **TorBox** button. Press it.
3. DMM says what TorBox did with it:
   - **Usenet → TorBox: TorBox already had it, it is ready in your TorBox Usenet downloads.**
   - **Usenet → TorBox: TorBox is downloading it, usually ready within a few minutes.**
   - **Usenet → TorBox: queued, it starts when one of your TorBox active slots frees up.**

![DMM's Usenet tab with TorBox Pro: Send to TorBox](../assets/dmm-torbox/03-usenet-tab.webp)

Signed in to Real-Debrid too? The list is headed **Send to Real-Debrid or TorBox** and has both buttons. The file icon at the end of a row saves the NZB instead. New to Usenet? Start with [Usenet for beginners](../guides/usenet-for-beginners.md).

TorBox drops a Usenet download 30 days after it cached it. Send it again to get it back.

## Fill requests with TorBox

Real-Debrid users ask for releases on DMM's [request board](https://debridmediamanager.com/requests). Press **Requests** on the home page, then **Fulfil** on a release TorBox has cached. It goes from your TorBox to their Real-Debrid. Every 10 sends earn 7 days of DMM sponsor perks: see [earn it without paying](../guides/sponsorship.md#earn-it-without-paying).

## When something is wrong

| What you see | What to do |
|---|---|
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | That key is on TorBox's free plan. Upgrade or renew on TorBox, then sign in again. |
| **Failed to refresh torbox: Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Your paid plan has run out since you signed in. Renew it on TorBox. |
| **API Error: Request failed with status code 403. Status: 403** | TorBox didn't accept that key. Copy it again from [torbox.app/settings](https://torbox.app/settings), all of it. |
| No **TorBox** button on the Usenet tab | Sending Usenet releases to TorBox needs Pro. Essential and Standard don't get the button. |
| **Usenet → TorBox: TorBox Usenet needs a Pro plan** | TorBox turned the NZB down because the plan isn't Pro. |
| Only **DL with TB**, no **Instant TB** | TorBox has none of these releases cached. Press one and wait for it to download, or pick another release. |
| Only **Instant TB** releases show | The **TB ✓** chip is on (`is:tb` in the filter box). Press it again, or press **Reset**. |
| **No torrents found yet. Use Want above to have zurg fetch it once one turns up, or try the Usenet tab.** | DMM has no torrents for this title yet. New episodes can take a while. Try the **Usenet** tab or come back later. |
| In Stremio: **⚠️ TorBox refused your account** | TorBox takes the addon's key but won't serve the account, usually because the plan ran out. Check it at [torbox.app/settings](https://torbox.app/settings). Nothing needs to change on DMM. |
| zurg: `Acquisition: dmm-torbox refused the search: No TorBox key linked.` | The sponsor `tb/cached` feed on DMM's [Torznab page](https://debridmediamanager.com/torznab) needs your TorBox key linked under **Link a provider key** on that page. Being signed in to TorBox on DMM isn't enough. The `api_key` in zurg stays your DMM API key. |

Is TorBox itself down? Check [Is TorBox Down Or Just Me?](https://debridmediamanager.com/is-torbox-down-or-just-me). Stuck? Ask in the **dmm-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) says what to include.

## Questions

### Is TorBox support not on the free tier of zurg?

Right. zurg's free public build is Real-Debrid only. TorBox, the other services and Usenet are in zurg's nightly builds for sponsors. Your TorBox plan has to be paid as well, since zurg can't read a free account. Set it up with [TorBox with zurg](../zurg/providers/torbox.md).

### Zurg uses the wrong TorBox plan?

zurg nightlies before 3 October 2026 read TorBox's Pro plan as Standard and allowed 5 downloads at once instead of 10. Update zurg. TorBox's [limits with zurg](../zurg/providers/torbox-limits.md) has the rest.

### No search results with TB?

DMM's search is the same whichever service you sign in with. TorBox only decides which releases say **Instant TB**. If you see nothing, check that the **TB ✓** chip is off, reload the page, or press **Show More Results** at the bottom. A brand-new episode may have no torrents on DMM yet: try the **Usenet** tab.

### Can I use TorBox and Real-Debrid together?

Yes. Sign in to both and each release shows both services' buttons. A release TorBox has cached and Real-Debrid doesn't gets a **TB → RD** button, which sends it from TorBox to your Real-Debrid.

### Which TorBox plan do I need for DMM?

Any paid plan. Pick Pro if you want to send Usenet releases to TorBox or want 10 downloads at once.
