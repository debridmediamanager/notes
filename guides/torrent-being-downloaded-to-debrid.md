---
label: Being downloaded to debrid
icon: download
order: 50
description: "What the green 'Torrent is being downloaded to debrid...' screen in Stremio means, how long it takes and what to do about it."
---

# What "Torrent is being downloaded to debrid" means

The green **Torrent is being downloaded to debrid...** screen means the release you picked isn't cached on your debrid service yet. Torrentio, the Stremio addon that shows it, has just added that torrent to your Real-Debrid, TorBox or other debrid account, and the service is downloading it now. Once that's done, the same result plays like any other.

## What to do

1. **Pick a cached result instead.** In Torrentio's list, `[RD+]` (or `[TB+]`, `[AD+]`, `[PM+]`) means cached, so it plays straight away. `[RD download]` means not cached. Those come after the cached ones.
2. **Or wait a few minutes, then press the same result again.** While it's still downloading you get the green screen again. Once it's done, it plays.
3. **Watch it download** on [Real-Debrid's torrents page](https://real-debrid.com/torrents), your [TorBox dashboard](https://torbox.app/dashboard) or the [DMM library](https://debridmediamanager.com/library). DMM shows each unfinished download's percentage, seeds and speed.
4. **Stuck at 0% with no seeds?** Nobody is sharing that release right now, so it may never finish. Pick another one.
5. **Don't want these results at all?** Open [Torrentio's configure page](https://torrentio.strem.fun/configure), set your debrid service and key as before, tick **Don't show download to debrid links** under **Options** and press **INSTALL**. You'll only see cached results.

## See what's cached before you press play

Sign in to [DMM](https://debridmediamanager.com/) with your debrid service and search the title. On its page, a green **Instant RD** button means Real-Debrid has that release cached, so it plays at once. **DL with RD** means it isn't cached and has to download first. Tap the **RD** chip above the results to hide everything that isn't cached. TorBox, AllDebrid, Premiumize and Offcloud get the same buttons (**Instant TB**, **DL with TB** and so on).

## Questions

### How long does it take?

It depends on how many people share that torrent. A popular release is usually ready in minutes: in our test on Premiumize, a 1.5 GB film was ready five minutes after the first press, downloading from three peers. A rarely shared one can be slow, and one nobody shares may never finish. The torrents page or dashboard shows the speed and how many seeds it found.

### Why does it happen on some results and not others?

Debrid services keep what their users download. If someone already fetched that exact release, it's cached and plays instantly. If nobody has, or the service has since dropped it, your account has to download it first. That's the difference between `[RD+]` and `[RD download]`. TorBox [explains how its cache works](https://support.torbox.app/en/articles/9923071-how-does-the-torbox-cache-work).

### Why did an `[RD+]` result show it?

Real-Debrid doesn't let addons ask what's cached. So on Real-Debrid, Torrentio's `+` means the release played for someone recently, not that Real-Debrid confirmed it just now. If Real-Debrid dropped it since, it downloads again. Pick another `+` result or wait.

### Is my debrid broken?

No. The green screen means your service took the torrent and is working on it. When something is actually wrong, Torrentio shows a red or yellow screen with other words, such as "Access denied" or "Some usage limit exceeded".

### My addon says something else

The exact words come from Torrentio and self-hosted copies of it. Other addons say the same thing their own way. AIOStreams shows "The file is being downloaded to your debrid. Try again later", Comet "The media you tried to play is not cached yet on this debrid service" and StremThru "Downloading to Store". Same cause, same fix.
