---
label: Plex watchlist
icon: eye
order: 57
---

# Plex watchlist acquisition

Plex watchlist is an adapter on the [shared acquisition engine](acquisition.md),
alongside Seerr. Existing `watchlist.enabled` and legacy Plex watchlist settings
keep working. The adapter resolves cloud-watchlist titles and uses the shared
Newznab executor to save NZBs. It starts after the library loads and needs an
`nzb` provider on the same zurg instance.

Progress lives in `data/acquisition.json`. The previous
`data/plex-watchlist.json` is imported once without deleting it. History, retry
deadlines, attempt counts and acquisitions waiting only for Plex removal survive
reboots. Both state files are included in normal backups. Keep `data/` and
`nzbs/` when recreating containers.

Successful acquisition removes an item from the watchlist, unless
`remove_after_grab: false` says otherwise; with it off the title stays and zurg
satisfies it in the background. `only_new_items` (on by default) means turning
the feature on starts watching the list rather than working through everything
already on it. Both are documented under
[what acquiring does to the source's own list](acquisition.md#what-acquiring-does-to-the-sources-own-list). Every planned season
must now be acquired before a show is removed; successful seasons are remembered
while missing ones retry. A season pack is preferred. The loose-episode fallback
acquires episodes found in indexer results, since the watchlist does not provide
an expected episode inventory. This is not continuous monitoring of future
episodes after the item leaves the watchlist.

Removal waits for the news servers. A watchlist entry is the only record that
you wanted a title — Plex keeps no history of a removed one — so it is not
deleted on the strength of an NZB nobody has checked. A release the accounts no
longer hold leaves the title where it is and is remembered as dead, so the
retry ranks the next candidate; a check that could not be made leaves the title
queued rather than deciding either way. See
[verifying a grab](acquisition.md#verifying-a-grab).

Failures retry with persistent backoff while the item remains on the list.
Once acquisition is recorded, failed or interrupted Plex removal retries only
that removal. Corrupt state is preserved and acquisition pauses until repaired
or restored. A write failure pauses acquisition until saving succeeds.

See [acquisition sources](acquisition.md) for configuration, retry intervals,
Seerr behavior and the adapter contract.
