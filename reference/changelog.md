---
label: Changelog
icon: history
order: 60
---

# Changelog

## zurg update works after the one-line install

The one-line installers sign you in to GitHub through the GitHub CLI. They
downloaded it for that and deleted it again when they finished. `zurg update`
then looked for the GitHub CLI and found nothing. It stopped with "no GitHub
credential found" even though your sign-in was still saved. Ubuntu's own
GitHub CLI is too old to hand the sign-in over. Update stopped the same way
there too.

`zurg update` now also uses the GitHub CLI the installers keep in `bin` beside
zurg. A sign-in the GitHub CLI saved without a keyring now works even when the
CLI itself is gone. When it still finds nothing it prints the one command that
fixes it. Run the installer's update once and every later `zurg update` signs
in on its own.

## Many old Real-Debrid links failing at once is no longer called an outage

Real-Debrid links stop working a few months after they were made, so releases
added around the same time stop playing around the same time. When more than
five of them failed in one repair pass, zurg logged "suspected provider-wide
outage" and held back the repair of all but five, so a large batch stayed
broken much longer and looked like Real-Debrid was down. zurg now first asks
Real-Debrid for a release on the same account that still plays. If it plays,
the failing links are simply old and every release is repaired as usual. Only
when Real-Debrid refuses working links as well does zurg treat it as an outage
and wait.

## The dashboard's Emby session links open Emby's dashboard

The "active sessions" and "transcodes" links on the dashboard's Emby panel
opened `/web/#/dashboard`, which is Jellyfin's address for that page, and Emby
sat on its splash screen there forever. Both links now open
`/web/index.html#!/dashboard`, the address Emby uses itself. The Jellyfin
panel's links are unchanged.

## A missing .nfo no longer sends a Usenet release to repair

Old Usenet posts often lose their .nfo first while every video and archive
part is still there. zurg treated that as damage to the whole release. It
started a repair whenever it came across such an .nfo and that happened again
after every restart. Real repairs then waited behind hundreds of pointless
ones. Some releases that played fine were marked unrepairable and deleting the
.nfo was the only way back.

A missing .nfo or other small file kept beside the video now reads as blank
and asks for no repair. It no longer marks a release unrepairable. A damaged
video can be repaired again when the .nfo next to it is gone. Releases already
marked unrepairable this way are checked again within about a day and come
back on their own.

## Usenet files no longer play silence where a server sent another upload's article

Some news servers answer a request for one article of your file with an article
from a different upload that has the same number. zurg only caught this when
the other upload had fewer articles than your file. On shorter files such as
RAR volumes and short episodes it took the wrong article and played silence for
that stretch. The log called it `an internal mapping failure in zurg` and said
the offset `falls between two articles that are both present and neither
covers`. zurg now also checks the file size every article states. It refuses an
article from another file and asks your other news accounts for the real one.
Articles an older build already saved to its article cache are refused too.
With a single account the stretch still plays as silence. The log now says a
server sent another file's article instead of blaming zurg.

## Usenet connections come back at full speed after another app stops using the account

If your news provider ever turned zurg away for having too many connections,
for example while nzbdav or an earlier zurg was still holding some, zurg kept
adding connections one per second for as long as it ran, even once the room was
back. After every quiet spell a burst of grabs started again from the two warm
connections, so a 70-connection account took over a minute to get back to full
speed and imports queued behind it, with "waited 5s for a connection (queued
for the account's allowance)" in the debug log. Once the provider has accepted
a connection again and a minute has passed without another refusal, zurg now
opens what it needs straight away.

## The debug log says when a fetch waits for a connection with several news servers configured

With one news server, a fetch that waited more than five seconds for a
connection left a debug line saying so. With two or more it never did, so adding
a second server made the line disappear whether or not the waiting had stopped.
The line now appears for multi-server setups too and names the servers the fetch
was waiting on.

## A Usenet grab with no repair files and a dead first article fails at once

A release posted without PAR2 files whose first article was gone from every
news server was held for five minutes before Radarr or Sonarr heard it had
failed, waiting for a repair that had nothing to repair from. zurg now sees that
there is no recovery data and reports the grab failed straight away, so the
client blocklists it and moves on.

## A Usenet grab that repair fixed is no longer reported failed five minutes later

When a grab was missing a few articles and its PAR2 files could rebuild them,
zurg repaired it, but a read-ahead running during the repair could ask for the
missing articles again and be refused a moment after the repair finished. That
refusal put the release back on the damaged list, so the grab was held for five
minutes and then reported failed, and Radarr or Sonarr blocklisted a release
that played fine. A refusal for an article the repair has already rebuilt no
longer counts as damage.

## Upgraded downloads that came with an .nfo or subtitles are deleted too

With `magic.allow_delete` on a deleted video that was not inside a RAR archive
was deleted on its own. The `.nfo` and subtitles and poster posted beside it
kept the download in your library. Its NZB stayed in `nzbs/` and its torrent
stayed on your debrid account. Every upgrade of such a download left one
behind. Now the whole download is deleted once nothing in `__magic__` uses it
any more. A download stays while another episode of it is still in your
library or still waiting in its own folder to be imported. Subtitles Sonarr or
Radarr imported beside the video keep it until they are deleted too.

## Replaced and failed Usenet downloads no longer pile up

With `magic.allow_delete` on a deleted episode or movie that came out of a RAR
archive was only hidden. The download it came from stayed in the library and
its NZB stayed in `nzbs/` for good. Upgrading single episodes to a season pack
left one of these behind for every episode. Now the whole download is deleted
once nothing in `__magic__` uses it any more. A download stays while another
episode from the same archive is still in your library. It also stays while
its own folder still has something to import.

Sonarr and Radarr ask for the files of a failed download to be deleted when
they remove it. zurg kept the NZB anyway. It now deletes it when nothing was
imported from that release. A download that finished and was imported keeps
its NZB as before because the imported file still plays from it.

## zurg now says when the library has finished loading

Docker calls zurg healthy as soon as it is running. A large library can keep
loading for over an hour after that. Folders in the mount fail with
`Input/output error` the whole time and it looks like a broken install. The new
`/ready` address tells the two apart. It answers 503 until the library has
loaded and 200 once it has. It needs no password. Inside the container
`/app/healthcheck.sh --ready` checks the same thing. The container's own health
check still only asks whether zurg is running. That way a long first load
cannot get the container restarted or hold back a mount that depends on it. The
health check also reads the `PORT` environment variable now. A container that
set `PORT` used to be checked on the wrong port.

## Acquisition can skip releases by words in their names

Set `exclude_words` in the `acquisition:` block and zurg never takes a release
whose name has one of those words. `exclude_words: [DV, HDR10+]` keeps Dolby
Vision and HDR10+ off a TV that cannot play them and still takes 4K with plain
HDR. It works for the Plex watchlist, Seerr, Radarr and Sonarr, and for Usenet
and torrents. Whole words only. `DV` does not catch `DVDRip` or a movie called
Adventures. `DV` and `DoVi` and `Dolby Vision` all mean the same thing, and so
do `HDR10+` and `HDR10Plus`. Radarr and Sonarr are never asked about an
excluded release.

## Radarr and Sonarr can take the profile's best quality first

zurg normally takes the allowed release that is quickest to check. For a movie
that is usually a 1080p WEB-DL. The upgrade pass then moves toward your
profile's cutoff. Shows take a season pack before loose episodes. So a 1080p
pack could fill a season even when 2160p episodes were there. Set
`best_first: true` under `acquisition:` and the first grab follows your Radarr
or Sonarr quality profile instead. The best resolution it allows comes first.
Anything at or above the cutoff counts as good enough. When a release turns out
to be gone zurg works down the profile. The first file can take longer to
arrive because the best releases are often large multi-part posts. It is off by
default.

## Torrent results no longer crowd out NZBs where no account takes torrents

On an instance with an nzb provider and no debrid account that takes torrents,
acquisition still searched your Torznab indexers, and each torrent it found
used up one of the three releases a show's episode or season pack gets per
attempt. With `prefer: torrents`, or 4K torrents ranked above a 1080p NZB, the
NZBs were never tried and the episode failed. Torznab indexers are now skipped
there, with one line in the log saying so, and a release the instance has
nowhere to put never counts as a try. Movies no longer ask Radarr about such
torrents either.

## Acquisition no longer counts an NZB as done where nothing can play it

On an instance with a debrid account and no nzb provider, acquisition still
searched your Newznab indexers, and an NZB it grabbed was counted as done
without any check. A Plex watchlist title could come off the list for a file
nothing on that instance can play. Newznab indexers are now skipped there, with
one line in the log saying so, and an NZB is never counted as done on an
instance without an nzb provider.

## A release with nothing left to play is reported once instead of every day

When every playable file of a release had been deleted, zurg warned that it
"has no playable file that still reads" again every day. A library with a
hundred such releases logged a hundred of those warnings a day for releases
nobody had touched. The warning now appears once and the release is looked at
again only after something about it changes. Restoring a file still brings it
back straight away.

## Broken releases on AllDebrid and TorBox come back when the files still play

A release held only by AllDebrid, TorBox, Premiumize, Offcloud or Debrid-Link
could stay broken and hidden for weeks while the account was still serving it. Repair doesn't re-add releases
on those services by itself, because they remove content on purpose, and
nothing else ever checked whether the files had started working. Repair now
asks the account once a day whether a broken release's files still play and
puts back the ones that do, without adding anything. Anything the account has
really removed still needs the Repair button. The MCP repair outlook says
the same thing instead of telling you no sweep will ever act on it.

## Grabs TorBox queues for a free slot show as queued and finish

When every download slot on a TorBox account was busy, TorBox put new grabs
from Sonarr and Radarr in its queue, and zurg lost track of them. The grab
showed as fetching metadata for about ten minutes and then as an error, so
Sonarr and Radarr dropped it. When TorBox later downloaded it, nothing
imported it. zurg now follows a queued grab until TorBox starts it and on
until it finishes. While it waits it shows as queued, and the no-progress
timeout doesn't run until TorBox has started it.

## You can search for one release on the `__magic__` page

On a library Sonarr or Radarr organises, every import leaves a hidden job
folder behind, and the `__magic__` page lists only the first thousand stored
rows. The release you came looking for was usually not among them, so its
Unhide and Reset buttons were out of reach, and the note under the list
pointed at data/magic.json instead. Editing that file while zurg runs does
not work: zurg writes it out again from memory when it stops, so the rows come
back after a restart.

The stored rows and dangling pages now have a search box. Type a release name,
a path from your mount or a hash, and every row stored about that release is
listed with its buttons, however big the table is.

It is also how to bring back a release that is in `__all__` but never shows up
in `__magic__/__all__.` Deleting a release and adding it again, or reinserting
it from DMM, keeps its hash, so it comes back with everything `__magic__` had
stored about it, including the job folder that was deleted after its import.
Search for it and press Unhide on its release-tombstone row.

## `__magic__` on Windows stops growing its journal forever

On Windows, zurg logged `cannot truncate data\magic.journal ... Access is
denied.` every time it tried to tidy the file where `__magic__` records your
moves and folders. The file was never emptied, so it grew with every change
and every start read all of it again. After a few thousand changes in one run,
each further change also rewrote the whole saved layout. zurg now empties it
on Windows as it always did elsewhere, and the first start after updating
clears what has piled up. If tidying ever fails, zurg tries again after more
changes instead of on every one.

## Restoring a file over MCP puts its release back right away

Restoring a file with the `zurg_release_file_restore` MCP tool brought the file
back but left its release marked broken and in `__unplayable__` until the next
library refresh. It now does what the Restore button in the torrent manager
does: the release leaves `__unplayable__`, goes back into its folders with its
.strm files, and is saved that way. As before, it does not ask Plex, Jellyfin
or your on_library_update script to rescan.

## Bring back files a failed repair hid

Older builds marked a file deleted when a repair gave up on one account, even
when another account could still play it, and the release then vanished from
every folder. The torrent manager has a new "Deleted, still served" filter that
lists releases with nothing left to play whose deleted file an account still
serves. Hold its Restore button and zurg checks each file's link and puts the
ones that play back in their folders, the same as pressing Restore on each file.

zurg does not do this by itself. A file you deleted on purpose is stored exactly
the same way, so look through the list and restore only what you did not delete.
Releases that still play something are left out, since deleting an extra or an
episode is the usual deliberate delete.

## Acquisition looks past the first page of search results

Acquisition used to read only the first page an indexer returned. With DMM,
which returns ten results a page with the biggest first, a size limit could
remove every one of them, and the movie failed with "no eligible releases"
every few hours even though smaller releases were on the next pages. It now
keeps asking for more pages until it has enough releases that fit your limits,
up to ten pages. For shows, an episode that the season search didn't turn up,
usually an older one when the newest episode fills the results, is now
searched for on its own.

## Dead files in `__magic__` movie and show folders now drop out so Radarr and Sonarr notice

A file that Radarr or Sonarr had imported into a folder under `__magic__` kept
showing at its full size after the release stopped working, so a rescan still
saw it and the movie or episode never went back to wanted. It now leaves the
folder at the same moment it leaves every other listing: once repair can no
longer bring it back, or a day after it broke when repair is off. The next
rescan marks it missing and acquisition looks for a replacement. If the file
starts working again it reappears in the same place.

## Season Fix sorts multi-season packs and numbered extras

Season Fix now reads the season each file names for itself, so a pack like
`Full Metal Panic S2 - 01`, `Bakuman II - 01`, `KonoSuba 2 - 01` or
`Demon Slayer Mugen Train Arc - 01` puts every episode in its own season
instead of leaving Plex to stack all of them on season 1. Batches named in
romaji or with a suffix, such as `Sergeant Keroro 001-358` or
`Dragon Ball Z COMPLETE`, are recognised when their files share one title, and
names with underscores, `Ep01`, `1.01.` or a number inside the episode title
are read the way they were meant.

Numbered extras like `Special 01`, `OVA 01`, `- 11 (OVA)` and `24.5` recaps
used to sit on a real episode as a second version, and Play could pick the
extra. They are now renamed with Plex's `-other` suffix so they show up as
extras.

## A dead Real-Debrid link no longer holds a library scan for minutes

When Real-Debrid keeps answering a file with the same revoked link, zurg waits
it out for a few minutes, since that is normal right after a download is
removed. A file still refused that way after five minutes is now treated as a
broken link and sent to repair, instead of telling the reader to come back
again. Before, a single dead file could hold a Plex scan for about ten minutes.

## Failed and stuck Usenet jobs can be cleared from the `__magic__` page

A Failed or Stuck job in the SABnzbd list stayed there for good once Sonarr or
Radarr stopped using zurg as a download client. A restart did not clear it.
Deleting `data/sabnzbd-jobs.json` by hand was the only way. The jobs list on
the `__magic__` page now has a **Clear** button on every Failed or Stuck job and
a button above the list that clears them all. Hold it until the bar fills.
Queued and Completed jobs are never touched. The job's NZB is deleted as well
unless an import under `__magic__` still uses that release.

## The Stremio addon says when it needs https

Stremio only loads an addon over plain http on the computer it runs on. On a TV
or a phone or another computer an http address fails with "failed to load
manifest" even when the device can reach zurg. The config page now says so next
to the addon URL whenever you opened it over http on such an address. The
Stremio guide shows three ways to put zurg behind https. They are Tailscale
Serve, your own reverse proxy and a Cloudflare tunnel.

## Plex picks up a movie or episode as soon as Radarr or Sonarr imports it into `__magic__`

After Radarr or Sonarr moved a file into a folder under `__magic__`, zurg asked
Plex to scan the file itself. Plex only scans folders, so it answered as if
everything was fine and added nothing, and the movie stayed missing until
Plex's next scheduled scan. zurg now asks Plex to scan the folder the file
landed in. The same goes for the file an upgrade replaces, so the old version
drops out, and for the manual scan endpoints, the MCP `zurg_plex_scan_releases`
tool, scans after a rename or a file delete, and the paths handed to
`on_library_update`.

## The Manage page lists duplicate releases and which one Radarr or Sonarr uses

An upgrade leaves the release it replaced in your library, and grabs from
different indexers can leave more than one copy of a movie or a season. The
new Duplicates view on the Manage page groups releases that hold the same
movie or the same episodes and shows which one Radarr or Sonarr is using. zurg
works that out from where the file sits in `__magic__`, not from release names.
For a season it lists each episode more than one release holds and which
release Sonarr's file is in, so a pack Sonarr takes only a few episodes from
still shows as in use. Every other release is marked "No reference found" or
"Unknown", with the reason. Select the ones you want gone, and zurg reads
Radarr and Sonarr again before deleting, leaving out anything that has come
into use since. Nothing is ever deleted automatically.

## TorBox's busy download slots are counted the way TorBox counts them

Before repair or a first playback adds a torrent to TorBox, zurg checks whether
the account has a free download slot. It used to count every torrent that was
not fully downloaded. That missed torrents that are seeding, which TorBox
counts against your plan for up to 30 days, and it counted torrents whose
content had expired, which take no slot at all. Nine expired torrents in a
library could make repair on a Pro account wait as if every slot were busy.
zurg now counts exactly the torrents TorBox marks as active.

## TorBox can seed for private trackers

A new setting, `tb_seed_torrents`, decides whether the torrents zurg adds to
TorBox seed. It stays at `never` unless you change it, so nothing changes for
anyone who leaves it alone. Set it to `always` if a private tracker needs your
ratio, or to `auto` to let the seeding setting on your TorBox account decide.
It can be changed from the dashboard's Health & Repairs section and takes
effect on the next add.

A torrent that is seeding takes up one of your TorBox plan's active slots for
as long as it seeds, up to 30 days on Pro. When seeding torrents fill every
slot, new grabs and repairs on that account have to wait for one to free up.

## RAR sets whose volumes are named out of order now play

A release whose RAR volumes each carry a different name, such as a random name
per volume or `Movie 2026 part1.rar`, used to show up as one archive per
volume. The first one listed the film but it stopped working after its first
part, and the others showed nothing. zurg now reads where each volume belongs
from inside the volume itself and puts the set back together, which is what
renaming the volumes `part001.rar` onwards used to fix by hand. It only does
this when the volumes number themselves into one complete set. If one is
missing or two claim the same place, the release is left as it was and the log
says why. Compressed archives whose volumes are posted out of order now play
too.

## A Plex scan that is still analysing is no longer reported as stuck

Plex keeps a library scan's progress and current folder unchanged while it
analyses the files the scan found, which can take a long time on a large or
remote library. The dashboard used to call that a stuck scan and suggest
restarting Plex in the middle of it. zurg now listens to Plex's own update
feed and counts the items Plex reports working on, so only a scan that has
really stopped is flagged.

## Cached-only torrent uploads preserve the refusing add on rate-paced providers

A `.torrent` submitted in cached-only mode now reaches TorBox's refusing add
even when its hourly add limit wraps the backend. An uncached miss creates no
transfer and occupies no active slot; it still spends one of TorBox's 60
uncached adds per hour. Ordinary adds continue uploading the original file.
The qBittorrent guide now lists all six torrent-upload providers and explains
the distinct Debrid-Link and TorBox cached-only paths.

## A file you delete while it is being restored stays deleted

Deleting a file or release while a restore is still checking its link now waits
for that check and then wins. A library refresh that was already running can no
longer bring back a release you just deleted.

## A seek far into a compressed archive no longer hangs the reader

A file inside a compressed RAR or zip can only be decoded from its beginning,
so a read near the end of a large one used to wait for the whole archive with
no reply at all. Plex could sit on such a read for over an hour, which was
enough to lock up its database. zurg now answers within 20 seconds, keeps the
progress it made, and prepares the end of the file in the background so the
next read of it is immediate.

## Real-Debrid refusals follow the published filename rules

When Real-Debrid refuses to re-add a release during repair, zurg now checks the
release's name and its file names against the published filename rules. A
release the rules block is marked infringing for good. Any other refusal is
treated as Real-Debrid slowing down adds, and the release stays in line for the
next repair pass instead of being retired.

## Restoring a file puts it back where it belongs straight away

The Restore action on a release's manage page now re-files the release into its
directories, saves the recovered state and writes its STRM file as soon as the
file checks out. A restored file no longer sits in the unplayable directory
until the next provider refresh, and a release whose last broken file was
restored is no longer reported broken after a restart. Files you deleted still
stay deleted until you restore them.

## Reject foreign Usenet articles before serving bytes

Reject same-number Usenet articles whose positive yEnc total is below the NZB's highest listed number, including persisted cache and progressive paths, so valid account fallbacks supply the bytes.

## Preserve evidence-backed RD refusal classification

Keep quiet addMagnet 451 responses as release refusals unless account-local throttle evidence spans the operation, and preserve temporary errors through repair.

## Clarify expired broken-file read windows

Report an expired broken-file read retry window without claiming repair has given up.

## Expose recorded file health in MCP

Expose recorded per-file health counts in MCP release views and keep lazy file tables safe to inspect without claiming that a lifecycle state is a live serving probe.

## Handle duplicate sidecar operations

Recognize typed missing-source responses from duplicate WebDAV aliases while retaining genuine all-failed and permission errors.

## A re-grab under the same name is repaired instead of failed

Grabbing an NZB again under a name zurg already holds no longer checks and
repairs the old copy while the new one is being read in. The grab waits for the
new file, so a release with a missing article that PAR2 can rebuild is repaired
and completed rather than reported failed.

## Repair failures no longer masquerade as user deletions

Automatic repair failures now mark only the failing provider source as broken,
preserving healthy alternate copies and allowing later provider refreshes to
restore file visibility.

## Torrents without an IMDb id are identified by release name through DMM

With `dmm_metadata_secret` set, the IMDb job no longer needs an OpenSubtitles key. Torrents with no id, or only OpenSubtitles' miss marker, are identified at startup from an `imdb-tt…` tag in their name, or else by DMM's resolver, which answers only when one title matches exactly: fansub romanisations like "Kaijuu 8-gou" resolve through DMM's aliases to Kaiju No. 8, and a name several shows share is left alone. A torrent DMM cannot name keeps an empty id, so a Plex match can still fill it.

## A Radarr movie that no indexer knows by id is searched for by name

Plenty of Usenet posts are indexed with no IMDb or TMDB id. zurg searched for a
Radarr movie by id alone, so a documentary every indexer answered nothing for
by id failed with "no eligible releases", while Radarr's own search by name
found a clean release. When the id search finds nothing to take, zurg now
searches for the title and year as well, and Radarr's own parser still decides
whether each result is the movie. Only an id search that found nothing at all
is followed by one by name: a movie the id search does find is indexed by id,
and asking again by name would only fetch the same posts.

## NZBs found through Prowlarr can be downloaded

Prowlarr hands over every Usenet NZB by redirecting to the indexer, and it
will not let that be turned off. zurg followed a redirect only to the same
host, so with indexers configured through Prowlarr every NZB acquisition chose
failed with "answered 301 Moved Permanently" and nothing was ever acquired. The
redirect is now followed. The link's own API key still never reaches the other
host, and a redirect from HTTPS to plain HTTP is still refused.

## An indexer that refuses for hours no longer stalls acquisition

Prowlarr answers a search on an indexer it has disabled with `429` and a
`Retry-After` of many hours. zurg waited two minutes and asked again, three
times, so every search spent six minutes on that one indexer. Acquisition gave
up on each title after five, and threw away what every other indexer had
already answered, so nothing was acquired at all until the indexer came back.
An indexer asking to be left alone for longer than two minutes is now skipped
until the time it named, and searches go ahead on the others.

## A title deleted after acquisition is searched for again

When a file zurg's acquisition had placed for Sonarr or Radarr was deleted,
because it was not the version wanted or for any other reason, and the title
came back on the missing list, zurg answered "completed without a search, the
release was already held" and never looked for it again. zurg now checks the
season or movie folder in `__magic__` first. An episode or movie whose video is
no longer there is searched for again. One whose video is still there, which is
what happens while Sonarr has not rescanned yet, is left alone.

## "Scan in Plex" on the undetected list waits for the result

The hold-to-scan button on the undetected list reloaded the page two seconds
after it was pressed, while matching against Plex had not started yet. On a
large library that match takes minutes, so the list always came back unchanged
and the button looked like it did nothing. The button now shows that matching
is running, waits for it to finish, says how many releases it matched, and then
reloads.

## A release whose name ends in a space is matched to Plex

A release whose file name has a space before the extension, such as
`... [Hurtom] v2 .mkv`, gets a directory whose name ends in a space. Plex found
it, but zurg could never match it, so it stayed on the undetected list after
every scan. It is matched now.

## Deleting a file on the manage page keeps your place

Deleting, restoring, renaming or force-showing one file on a release's manage
page used to reload the page at the top, so pruning a big pack meant scrolling
back down after every click. The page now comes back at that file's row and
highlights it.

## The dashboard takes a mount path typed with quotes

A mount path pasted into the dashboard the way config.yml writes it, such as
`"/Users/me/Plex Media Server/ZurgMount"` or `'Z:\'`, was refused with "mount
path should be absolute" because the quotes were read as part of the path. The
dashboard now drops a matching pair of quotes around the value and saves the
path inside them.

## A failed Plex watchlist fetch says why

When Plex refuses a watchlist request, the log now carries Plex's own reason,
such as `unexpected status: 401: Invalid token`, instead of the status alone.
If you still see `Failed to fetch watchlist: ... unexpected status: 400`, that
wording comes from a build older than August. Update zurg: current builds ask
for the watchlist in pages Plex accepts.

## A release too damaged for repair's memory fails at once

When a Usenet release is missing more than PAR2 repair can hold in memory at
once, zurg now says so and stops, and Sonarr or Radarr pick another release.
It used to keep the grab waiting, then try again every few minutes, re-checking
the whole release each time for the same answer. Damage that is not yet
confirmed as gone, such as articles a server failed to answer, is still
retried.

## Setup gets past an empty config and says when the token prompt is hidden

`zurg setup`, and the installers that run it, refused to go on while an empty
`config.yml` was lying around, with an error that ended in a blank. An empty
config is now replaced. One with content in it is still never overwritten, and
the error now says which file it is and how to start over. The token prompt
says that what you type or paste stays hidden, which had looked like the
terminal refusing input. A typo in `config.yml` is now reported against
`config.yml`, not an internal "outbound identity config".

## A backup news server now fills in articles the main server answers wrongly

Some news servers, Frugal among them, answer a request for one article with a
piece of a different upload. zurg recognised the wrong piece but never asked
the backup server for the right one, so the gap played as silence or the file
would not open, even with a backup server that had it. zurg now asks the next
server, the way SABnzbd does.

## A RAR'd Usenet release reaches its directory without a restart

A release posted as a RAR set is sorted into directories by its volume names
until its archive has been opened, and by the files inside it after. Nothing
sorted it again once the archive was opened, so a directory that looks for a
`.mkv` or for episode numbers missed a freshly grabbed RAR'd release until
zurg restarted, and Plex and Jellyfin never saw it there. The release now moves
into the right directories as soon as its archive is first listed.

## A movie posted under a random name is named after its release

Some Usenet posts give the movie a random name, such as
`eq5KVi5Y3iTwFEn1Nub8yPY9yd6oUzTu.mkv`, and repeat it everywhere in the post
that could carry the real one. zurg kept that name, so Radarr and Sonarr had
nothing in the filename to go by. zurg now names the file after the release,
as SABnzbd does: only when it is clearly the one big file of the release, only
for a video file, and never for a disc structure or an archive. This applies
to releases grabbed from now on; one already in the library keeps its name.

## Size rules now apply to files inside archives

A Usenet movie posted as a RAR set is shown as the files inside the archive.
Those files skipped a directory's `only_show_the_biggest_file` and
`only_show_files_with_size_gte`/`_lte` settings, so anything else the post
carried stayed visible beside the movie. Many posts include a small image named
after the movie, a sheet of timestamped stills, and Jellyfin used it as the
poster. The size settings now apply to archive contents the same way they apply
to every other file.

## Usenet releases whose largest PAR2 file is over 512 MB can be repaired

When a release is missing pieces, zurg rebuilds them from the release's own
PAR2 files. It refused to read any PAR2 file bigger than 512 MB, and on a large
release that file holds more of the repair data than any other, and is often
the only one there is. Such a release could not be repaired however little of
it was missing, and zurg kept trying again, downloading all of its smaller PAR2
files each time before giving up. zurg now reads a PAR2 file of any size.
A release with more damage than one repair can hold in memory is turned down as
soon as the damage is counted, before any of its PAR2 files are downloaded.

## Sonarr can hand its missing episodes to zurg

zurg can now take its list from Sonarr too. Add a `sonarr` source under
`acquisition.sources` with Sonarr's URL and API key. zurg then works through
the episodes Sonarr is missing and the episode files it wants to upgrade. It
searches your indexers and checks that the news servers still hold the
release. It puts each episode in its season folder inside `__magic__` and asks
Sonarr to rescan the series. Sonarr needs no indexers or download client for
this.

A season that is missing whole and has finished airing can come as one season
pack. Anything else comes episode by episode. Every release goes through
Sonarr's own parser first. It has to be the right series and the right
episode, and it has to fit the series' quality profile. Upgrades replace only
the episode they upgrade. When one episode of a season has no release yet,
the others are placed anyway and Sonarr rescans for them. Daily and anime
series are skipped for now, with a note in the log. `docs/acquisition.md`
covers the Sonarr side of the setup.

## Acquisition works on many titles at once

Titles from a watchlist or a request service used to be acquired one after
another, so a long list took as long as all of its titles put together. zurg
now works on up to eight at a time, set by `acquisition.concurrency`. A title
that turns up late on the list no longer waits for the ones ahead of it to
finish.

A new release no longer sits for two minutes before zurg checks it. zurg
checks every second until the release appears in the library, for up to a
minute and a half. When the news servers no longer hold a release, zurg moves
straight on to the next candidate instead of retrying five minutes later.
Checking a release no longer has to fit in whatever time the search left over,
so a slow search on a long list no longer delays titles by minutes.
Upgrades to titles you already have wait until the missing titles from the
same list are done, so they never compete with them for indexer calls or news
connections.

## A Usenet release repaired with PAR2 stays repaired while it is read

When some articles of a release are gone from the news servers, zurg rebuilds
them from the release's PAR2 files and serves the rebuilt bytes. The part of
zurg that fetches ahead of the player did not know about the rebuilt pieces,
so it asked the servers for the missing articles again. They were still
missing, and zurg reported the release damaged again, even though every byte
it served was correct. A release repaired during an import could be failed
moments later, and a download client would throw away a good copy and grab
another. zurg no longer asks the servers for anything it has already rebuilt.

## Radarr can hand its wanted movies to zurg

zurg can now take its list from Radarr. Add a `radarr` source under
`acquisition.sources` with Radarr's URL and API key, and zurg works through
the movies Radarr is missing or wants to upgrade. It searches your indexers,
checks that the news servers still hold the release, puts the video in the
movie's folder inside `__magic__` and asks Radarr to rescan that movie. Radarr
needs no indexers or download client for this. Every release zurg takes has
been through Radarr's own parser first, so it has to be the right movie and
fit the movie's quality profile: an allowed quality, the minimum custom format
score, the size limits, and upgrades only toward the cutoff. zurg takes the
first allowed release that is quickest to check, web releases first, and
leaves the profile's preferred qualities to the upgrade that follows. It asks
Radarr about a release only when it is about to check it, one at a time, and
never asks about one whose title names a resolution the profile has no quality
for, so a busy Radarr answers one to three questions for most movies instead
of one for every search result. If Radarr sees zurg's mount at a different
path, set `library_path` to where it sees `__magic__`. A new Acquisition page
on the dashboard shows every title zurg is working on, what it is doing right
now and where each release was placed. `docs/acquisition.md` covers the Radarr
side of the setup.

## Acquisition picks the Usenet release that is quickest to confirm

When zurg acquires a movie, it now looks first at the posts that hold a single
video file, which are far more often still complete on the news servers and
take two article reads to confirm. It reads each candidate's NZB before saving
anything, saves the first single-video post it finds, and only falls back to
multi-volume archive sets when none is on offer, smallest set first and no
more than six at a time. Results titled after one part of a split post are
skipped. In testing on the IMDb Top 100, choosing this way cut the NZBs zurg
had to fetch from 517 to 156. Searches and NZB downloads now share a limit of
requests in flight per indexer and wait out an indexer that says it is busy. A
movie request with no quality profile behind it still gets the resolution it
asked for first. Series acquisition is unchanged.

## Acquisition checks a release once zurg knows its sizes

zurg used to check a new release with the news servers the moment it appeared
in the library, while it was still reading the same release to learn its file
sizes. Both asked for the same articles over the same connections, so on a
long list both crawled. On a list of 99 movies the last one reached Radarr
after almost nine minutes. zurg now checks a release once its sizes are known,
the way it already does for Sonarr and Radarr through the SABnzbd endpoint,
checks no more than six releases at a time, and reuses the first article the
size check already downloaded when it still has it. A burst of saved releases now leads to one
library refresh instead of one per release.
Checking a release now goes ahead of the size checks of other releases, though
never ahead of playback, and an account with more than twelve connections now
learns the sizes of up to sixteen releases at a time instead of eight.

## A grabbed Usenet release with a few missing pieces is repaired before it is failed

Before telling Radarr or Sonarr that a download finished, zurg checks that
the release's pieces are still on the news servers. When that check found
something missing, zurg failed the download on the spot, even when the
release's own PAR2 files could have rebuilt what was gone. Radarr then threw
the release away and went looking for another, often a worse one. zurg now
rebuilds the missing pieces first and only reports the download failed if
that does not work. In a week of real grabs, most of the releases failed this
way had the PAR2 files that would have saved them.

## Damaged Usenet releases wait their turn for a repair instead of being failed

zurg repairs at most two damaged releases at a time, and a repair can take
anywhere from a couple of minutes to over an hour. A third damaged download
only had five minutes to get started before zurg told Radarr or Sonarr it
had failed, so when several arrived together, all but two were thrown away
without anyone trying to repair them, and the log said nothing about it.
zurg now keeps a download waiting while its repair is in line, for up to
three hours, and the log says when a repair is waiting for its turn.

## A Usenet download no longer waits for ever on file sizes nothing is going to learn

zurg holds a finished download back from Radarr and Sonarr until it knows each
file's exact size, because the clients check the size when they import. After
certain re-grabs, zurg could stop trying to learn the sizes while still waiting
for them, so the download sat in the queue until the client gave up, often two
hours later. zurg now sizes such a release again, and when no further sizing
is possible and the release's pieces are all on the news servers, it tells
the client the download is ready.

## Usenet releases whose poster renamed only the first archive volume play again

Some posters rename the first volume of an archive to the release name and
leave the rest under their original names, so a release arrives as
`Show.S02E03.part03.rar` plus `show.203.r00` to `show.203.r19`. zurg grouped
the volumes by name, saw two incomplete archives, and could open neither. It
now reads the first volume's header, recognises which volumes it belongs with,
and names it to match, so the episode plays and imports. A folder whose
archive really is missing a volume now says so with a clear message instead
of a generic server error.

## Obfuscated Usenet releases whose volumes are just numbered now play

Some releases hide every filename behind a random string and a number, so a
film arrives as `f342c135….01`, `….02` and so on, with the text files and
cover art numbered in among them. zurg did not recognise these as parts of
one archive, listed them as loose files, and Radarr and Sonarr found nothing
to import. zurg now reads the start of each numbered file, puts the archive's
parts together in the right order (even when the first part was posted last),
and leaves the text files and images out of it.

## Season-pack NZBs over 32 MB are accepted

zurg refused any NZB larger than 32 MB sent through its SABnzbd endpoint,
answering "request body too large". The NZBs for big season packs are often
bigger than that: a 526 GB season came as a 49 MB NZB. zurg now accepts NZBs up
to 256 MB. A 49 MB one with nearly half a million pieces loads in under half a
minute.

## Files from wrapped Usenet posts keep their real names

Some posting tools wrap each filename in the subject line, as in
`[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv]-[3/4]`, and leave the usual quoted
filename empty. zurg kept the wrapper as part of the name, so episodes were
listed as `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv`, which Sonarr and media
servers cannot match. zurg now takes the name out of the wrapper. Releases
already in the library are re-read once to pick up the corrected names.

## Downloads already reported failed no longer take repair slots from new ones

Once zurg tells Radarr or Sonarr that a download failed, the client throws it
away and looks for another. zurg kept trying to repair such downloads anyway,
every time it restarted, and those pointless repairs could hold both of its
repair slots while a fresh download that could still be saved waited. zurg now
stops repairing a download once it has reported it failed.

## Damage reports name every file

When a Usenet release was missing pieces, zurg's failure message listed the
damaged files by name, and a file the post itself never named showed up as a
blank: "across 4 file(s): , , , ". Such a file is now listed by its place in
the release, as in "file 12 of 73", so the message says which files are hit.

## Stremio skips a release whose video starts with nothing

When the start of a Usenet release's video is gone from the news servers,
zurg filled it with silence and handed it to Stremio as if it were fine, so
the player showed nothing and the film looked broken. zurg now looks at the
first bytes before it starts playback. If there is nothing real there, it
moves on to the next release in the list, the same way it already does for a
release with nothing playable in it. A film with a gap somewhere later still
plays.

## Broken files stay in the library while zurg will still retry them

When zurg could not repair a broken file on the first try, it took the file
out of the mount, even when it was going to try again a day later. Plex reads
a file that disappears as a deleted file, so a single library scan could move
episodes, seasons and whole shows to the trash. Now a broken file stays in the
mount for as long as zurg plans another repair attempt. It only leaves when
zurg is sure the content is gone, for example when the service refuses the
release outright or nothing playable is left in it.

## Radarr and Sonarr search again when a release they grab twice is dead

When the first release Radarr grabbed turned out to be dead, its next search
often picked the same release from another indexer, under the same name. zurg
filed that second grab under the job id of the first. Radarr and Sonarr
remember every download they have seen fail by that id, so they treated the new
grab as the old failure and never looked at it again: no failure, no blocklist,
no new search. The movie simply stopped. In a run of the IMDb Top 100 through
Radarr, 25 movies ended that way.

A grab of a release zurg has already answered for now gets a job id of its own,
the way SABnzbd itself names every download. When it is dead too, Radarr hears
the second failure, blocklists it and searches again.

## Dead Usenet releases are reported failed in minutes instead of up to half an hour

zurg checks a grabbed release's articles before telling Radarr or Sonarr it
finished, and it waits for the release's file sizes to settle before asking. A
dead post is exactly the release whose sizes never arrive, so the check sat
behind a thirty-minute wait while the client waited for news. Once zurg has
tried and failed to learn a release's sizes, it now checks the articles straight
away, and a release whose articles are gone is reported failed so the client
moves on to another one.

A release found damaged while being read was also held five minutes for a PAR2
repair, even with `enable_repair: false`, where no repair ever starts. That wait
is now skipped whenever no repair can run.

In a run of the IMDb Top 100 through Radarr with more than half the grabbed
releases dead, these two waits were most of the time a movie spent in zurg.

## A release that turns out damaged during import is failed, so Radarr grabs another

zurg checks one article per file before telling Radarr a release is ready, so a
release with a gap in the middle of a file can pass. When Radarr's import then
reached the gap, zurg refused to move the file, which is right, but it left the
download looking unfinished instead of failed. Radarr parked the movie as
"import blocked" and never looked for another copy. In a run of the IMDb Top
100 through Radarr, five movies got stuck that way.

The refused import now marks the download failed. Radarr blocklists that release
and searches for a different one.

## A fully obfuscated release no longer comes out with a nameless video file

When a Usenet post hides every filename, zurg works out what the main file is
from its first bytes and names it after the release, the way SABnzbd does. That
check came last in a pass with a ninety-second limit, and when grabs arrived in
a burst the limit could run out first. The video file was then published under
the release's name with no extension at all, which Radarr and Sonarr skip, so
the download sat in their queue waiting for a file they could import.

A release is now named again, up to three times, until zurg has been able to
look at the file, and only then shown to your library and your *arr. In a run
of the IMDb Top 100 through Radarr this was Seven Samurai, a 42 GB .mkv.

## Releases with accents or CJK in their filenames keep their whole names

A release whose files are named with anything outside plain English letters came
out of zurg with the front of every name missing. `Détective Conan S11E01 - 286
[MULTI] [AVC].mkv` was served as `tective Conan S11E01 - 286 [MULTI] [AVC].mkv`,
and a Chinese or Japanese title lost even more, because everything up to the last
such character was dropped.

Sonarr and Radarr could not do anything with what was left. A name like `tective
Conan S11E01` matches no series, so they fell back to the download's grab history,
refused to import on that alone, and parked the item with "release was matched to
series by ID. Automatic import is not possible." The release sat in the queue and
nothing moved it.

It could also cost you files. When the only thing telling two files apart sits
after the last accented character, both come out with the same name, and a name
is a path. One French release with ten repair volumes had all ten reduced to the
same name and published four files where the post holds thirteen, leaving the
repair data with no way to reach it.

zurg now reads every character above plain ASCII as part of the filename, which
is what it always is: the part counters, the `yEnc` marker, the brackets and the
file extensions posters write are all plain ASCII, so anything else belongs to
the title. Releases named in plain ASCII are unaffected and come out exactly as
before.

Releases already in your library keep the names they were filed under, since
zurg does not revisit a file list it has already recorded. Re-adding an affected
release picks up the corrected names.

## A name written in Japanese, Korean, Chinese, Thai or Arabic is left alone

zurg renames a file inside an archive when its name says nothing about what it
holds, so a release posted as a hash arrives under the release's own name
instead. Deciding that meant weighing capital letters against lower case, and a
great many scripts do not have either. A file called `오징어 게임 S01E01` counted
zero of each, failed the test for an ordinary name, and was renamed as though it
had been a hash, S01E01 and all. Han, kana, Hangul, Thai, Hebrew and Arabic were
all affected.

A letter with no upper or lower case now ends the question rather than failing
it. Names in those scripts are kept as posted, and hashes are still renamed
exactly as before.

zurg also now says so in the log when two files in one release end up with the
same name. A name is a path, so when that happens the release quietly offers
fewer files than it holds and the extra ones cannot be opened at all. Nothing
reported it before, which is why the accented-filename fault in the previous
entry went unseen: the only evidence was a folder listing with fewer rows in it
than expected.

## The filename fixes now reach releases you already have

The two entries above changed how zurg reads a filename out of a Usenet post,
but zurg keeps the result of reading each NZB and reuses it at every start
rather than working through your whole watch directory again. Those stored
results were still the old ones, so after upgrading, a release you already had
went on showing the same wrong name it had before. Only a newly added NZB got
the corrected one.

zurg now notices that it reads posts differently than the stored results were
written with, and reads them again. The first start after upgrading re-reads
every NZB in your watch directory once, which takes a little longer than usual
and then goes back to normal. Nothing is re-downloaded and no articles are
fetched; it is only re-reading files already on your disk.

If a release was affected, its files come back under the names the post gave
them. Your download client may still be holding the failed import from before,
so a release that has been sitting in Sonarr or Radarr unable to import needs
that queue item removed before it will try again.

## Titles with punctuation in them keep their whole names too

The filename fix further up this list stopped zurg cutting names at accented and
Chinese characters. It did not go far enough. zurg decided what a filename was
by listing the characters one is allowed to contain, and that list was missing
twenty ordinary marks, so a title carrying one was cut at it in exactly the same
way:

    Tom & Jerry - The Movie.1992.1080p.mkv   ->   Jerry - The Movie.1992.1080p.mkv
    Mairimashita! Iruma-kun (2026) [22].mp4  ->   Iruma-kun (2026) [22].mp4

`!`, `&`, `#`, `$`, `%`, `@`, `~`, `;`, `=` and `^` all did it.

Listing the characters a title may contain is a losing game, so zurg no longer
tries. A name is a filename, and the only characters that certainly cannot be in
one are those no filesystem accepts: `/ \ : * ? " < > |`. Everything else now
belongs to the title.

Checked against every NZB in a 6,800 release watch directory: of the subjects
that are a plain filename, twenty came out short before this change and two do
now, and both of those are an indexer's per-download stamp being removed, which
is what should happen to it.

## A release whose files were renamed picks the new names up on its own

The filename fixes above changed what zurg calls the files inside a Usenet
release, and a release already in your library did not always notice. zurg
matches a release it already knows against a fresh listing by the link it stored
for each file, and a Usenet link carries the file's position in the release. When
a corrected name sorts differently from the old one, that position moves, the
stored link no longer points at the same file, and there is nothing left to match
on, so the old name stayed.

It now falls back to the file's size, which does not change. Where exactly one
file in the release has that size, it is that file and the name is taken. Where
two files are the same size, nothing is renamed rather than guessing and filing
one episode under another's name.

Releases where the position did not move were already picking the new names up
and are unaffected, and so is every non-Usenet backend, whose links do not move
when a file is renamed.

## A file the mount cannot read stops holding everything else up

When a read failed for a reason zurg could not name, it told the client to try
again, and kept telling it that for as long as the file kept failing. rclone
takes that seriously: one read of such a file spent 55 seconds and three dozen
requests before giving up, and because rclone slows down its whole connection to
a server that keeps returning errors, the next healthy file took 3.66 seconds to
open instead of 0.04.

Now the retrying stops after a minute of the same failure. The read is answered
the way a read of a broken file already was, the file keeps its place in your
library listing, and the same read takes half a second.

zurg still tries the download every time, so a file that comes back is picked up
by the next read.

## The mount stops downloading once you stop reading

A library scan, a subtitle check or anything else that briefly touches a lot of
files was pulling far more from your debrid account than it read.

rclone 1.74 started keeping a file downloading for five seconds after the last
program closed it. Nothing was waiting on those bytes, and on a fast account
five seconds is a few hundred megabytes per file. Reading 1 MiB from each of
twenty files pulled 4.2 GiB where it used to pull 80 MiB.

zurg now turns that off. Mounts on rclone 1.73 and older are unaffected and
unchanged, because the option does not exist there.

If you run your own rclone rather than zurg's mount, add `--vfs-handle-caching 0`
to your mount command on rclone 1.74 or newer. The README covers it.

## A release that loses one archive volume no longer loses the rest

Usenet releases posted as a multi part rar or 7z set could stop importing
altogether. Sonarr and Radarr sat on "Waiting for import" and never moved off
it, and the release's folder would turn up holding only the rar parts, or stop
existing at all.

When zurg could not read one volume of a set it put that volume aside and let
the next listing go on without it. That listing found the set one volume short,
stopped at the volume behind it and put that one aside too. A release lost its
volumes one listing at a time, roughly one every ten minutes, and once it had
none left it dropped out of the library and out of the folder the download
client imports from. A path that is not there is not an empty folder to Sonarr,
it is an import that fails forever.

A volume known to be unreadable now stays in its set. Every listing stops at
the same volume and says the same thing about it, so a release that is missing
part of its post is reported as such once, and your client can blocklist it and
go looking for another copy. Releases whose volumes are all readable are
unaffected.

## Scans follow the library into its new home under `__magic__`

The mirror of your library moved from `__magic__` down to `__magic__/__all__` in
2026.09.17.2240-nightly. Part of zurg went on naming the old spot.

When a new release arrived, the scan zurg asked Plex or Jellyfin for pointed at
a folder that had not existed since that release, so nothing was ever queued and
new content waited for the media server's own scheduled scan. Anyone running an
`on_library_update` script was handed the same path.

Both now name the folder your download client was told to import from, and so
does the listing zurg drops from the mount's cache when a release arrives or
leaves.

## The watchlist can take torrents now, from Torznab indexers

Until now a watchlist or Seerr request could only be satisfied from Usenet. Add
`type: torznab` to an indexer and zurg will search it too, and a torrent result
is handed to a debrid account instead of being written to `nzbs/`.

**It is only ever given to an account that already has it cached.** Every
account that takes adds is offered the hash, because the caches are
independent, and the first that already holds the release takes it. A miss
everywhere is just a candidate that did not work out, so zurg moves down to the
next release, which may be another torrent or an NZB. Nothing is downloaded
onto your account, no uncached add allowance is spent, and nothing is left
running for something nobody is waiting on.

When both kinds of indexer could answer, `prefer` decides which is reached for
first. It is `usenet` unless you say otherwise, so an install that had only
Newznab indexers behaves exactly as it did. `torrents` reverses it and `best`
takes whatever the ranking puts first, torrent or not.

A torrent grab waits to be checked like any other, but it is asked a different
question. The account already said it holds the content, so what is checked is
that the release reached your library with files in it, and one that lists
empty is set aside so the next release gets its turn.

You can also run acquisition with Torznab indexers alone, without an `nzb`
provider.

## An agent reading the library no longer calls every release empty

zurg's MCP listings measure a release's size only when they are asked to,
because walking the file table of a whole library costs real time. For the
releases they had not measured they reported the size and the file count as
zero, and nothing in the answer told a reader that zero meant "not measured"
rather than "nothing there". An agent asked to list a directory would say a
6.6 GB film held no files, while the tool for a single release had the right
answer the whole time.

A listing that did not measure now leaves both numbers out instead of
reporting zero. Ask for them with `with_size`, by sorting on size, or with a
size filter. `zurg_library_search` takes `with_size` as well, which it could
not before, so getting sizes no longer costs you a narrowed or reordered
result.

## zurg doctor says whether the MCP endpoint is answering

`zurg doctor` checked that the dashboard's port answered and stopped there,
which says nothing about `/mcp`. An endpoint that the config switches on but
the server then refuses to serve, which is what happens when `username` is
empty, looked healthy from outside and explained itself in one line of the
startup log and nowhere else.

When `mcp.enabled` is set, `doctor` now speaks the protocol to `/mcp` and
reports what came back: answering, refusing the configured credentials, or
enabled but not served. An instance with the endpoint off is not asked about
it and gets no line.

## Opening the MCP endpoint in a browser now tells you what it is

Loading `/mcp` in a browser answered "Bad Request: GET requires an
Mcp-Session-Id header", which is a correct answer to a question nobody asked.
The endpoint now describes itself when a browser opens it: what it speaks, the
address to point a client at, the snippet for the stdio bridge, which build
this is, and every tool it is currently offering, grouped by toolset and marked
where a tool describes what it would do and waits to be confirmed.

That list is what registration actually produced rather than a second copy kept
by hand, so a tool withheld by `read_only`, by your toolsets or by the lifecycle
switch is not advertised as one you can call. The page also says so when the
endpoint is being served without authentication.

No client is affected. The page is served only to a GET that asks for HTML and
carries no session, which is a browser and never an MCP client, and a client's
own GET opens the event stream exactly as before.

## Usenet playback fills the connection allowance sooner

Usenet reads now put the article at the playhead into the account scheduler
before offering the rest of a requested range. When a large range is split
across pipelined connections, consecutive articles are dealt across those
connections instead of giving the first connection the first four, the second
connection the next four, and so on. The first useful articles therefore come
back in the first connection round rather than waiting behind later bytes.

Small-article archive posts get a read-ahead window spanning at least 64 MiB;
modern posts with multi-megabyte articles keep their existing window. The
larger article count does not widen memory use: speculative bodies are limited
to two readers and half of `cache_size_mb` (256 MiB at the default), while the
article cache retains its existing hard limit. Playback-sized requests begin at
64 MiB instead of 128 MiB, so a 90 MiB player buffer no longer falls onto the
seek/probe path; small seeks still do.

A stalled pipelined batch may hedge up to five distinct articles at once. The
existing account limit of twenty second asks per minute is unchanged, and
read-ahead, repairs and other work with no client blocked on it are still never
hedged.

Opening multi-volume archives is cheaper too. When PAR2 has already supplied
the exact length of every volume, one volume's verified yEnc header can supply
the common article stride for a large sibling set. Each sibling verifies that
inference from its own header before serving its first byte, so resolution no
longer pays one serial article per volume without trusting inferred geometry
for data. Filename recovery likewise answers from the yEnc header instead of
waiting for the rest of that article to download.

## Saved .strm files follow a Base URL change

Changing Base URL left every `.strm` already in `strm/` pointing at the old
address, and restarting did not help, because zurg only ever wrote the files
that were missing. Now a `.strm` whose URL differs from the one zurg would
write is rewritten in place. That happens at every start, and straight away
when Base URL is changed on the dashboard or `save_strm_files` is switched on
there. Files that are already right are left alone, so a media server does not
re-read the whole folder on every scan.

Jellyfin keeps the URL it read from a `.strm` and picks up the new one at its
next library scan. A `.strm` still holding an account link from an older build is
rewritten too, to the form that fails over between accounts and survives
repairs. A `.strm` edited by hand inside `strm/` is overwritten, so point
Base URL at the address you want instead.

## Turning the Plex watchlist on no longer empties it

Enabling the watchlist used to read your whole list as a backlog and work
through it, deleting each title as it went. One first run took 121 titles off a
163-item list in about four minutes. Plex keeps no record of a removed
watchlist entry, so the only way back was a snapshot taken beforehand, and
nothing in the config or the logs said this was about to happen.

Two settings now decide what acquiring does to the list, which is yours rather
than zurg's.

**`watchlist.only_new_items`** is on by default. Turning the watchlist on now
starts watching it. Whatever is already on the list is taken as handled, and
what you add afterwards is acquired. It applies once, at the first run, and
never over a queue that already exists, so an install that has been working
through a watchlist carries on exactly as before.

**`watchlist.remove_after_grab`** is on by default, which is what the feature
has always done, so nothing changes for you unless you ask. Turn it off to keep
your watchlist a watchlist. It stays a list you browse to decide what to watch,
and zurg satisfies it in the background without ever editing it. A title left
in place costs nothing to re-check, because the receipt already covers it and
no indexer is asked about it again.

Both are on the config page, and both take effect at the next restart. An
acquisition source you spell out under `acquisition.sources` can set either per
source. They mean nothing to a Seerr source, which owns no list zurg writes to.

## Watchlist and Seerr requests wait for the news servers before they are cleared

A grab used to be finished the moment its NZB reached the watch directory. The
indexer answered, the answer parsed as an NZB and the file was written. Those
are three facts about the indexer and none about the post. The request was then
cleared on the strength of them, which for a Plex watchlist means the entry is
deleted, and Plex keeps no record of a removed one. A dead post therefore took
the only record that you wanted the title, before anything had read a byte of
it. One run over a 163-item watchlist removed 121 titles and 12 of the releases
behind them could not be read.

Each acquired release is now put to the news servers before anything is
acknowledged, the same check the SABnzbd endpoint has made since the 08.28
nightly. There are three answers and they are kept apart.

- **The articles are gone.** The grab does not count. The title stays on your
  watchlist, the request stays open, and the release is remembered as dead so
  the next attempt ranks the next candidate instead of settling on the one
  already sitting in your library. A release known dead costs nothing at all.
  It is not fetched and takes no place among the three candidates an attempt
  tries, so a run of dead posts at the top of a ranking is walked through
  rather than retried for ever. A season pack found dead puts its whole season
  back to being wanted, so the loose episodes get taken instead.
- **The servers could not be asked.** A pool that is down, an account
  throttling, or simply a library that has not listed the new NZB yet. Nothing
  was established, so nothing is decided. The request waits and is asked again,
  and waiting costs it no retry attempt. A release that still cannot be checked
  after about two hours is set aside the way a dead one is, and the next
  release gets its turn. The title is never cleared on a release nobody could
  check.
- **The release is there.** Exactly as before.

An install with no Usenet account has nothing to ask and is unaffected.

## Checking a big release no longer runs out of time on a slow news server

Before a grab is reported finished, zurg asks the news servers about every file
in it. It asked about one file at a time. Some accounts answer those questions
slowly and strictly in turn, so sending them all at once down one connection is
no faster. Frugal's newswest took over five seconds per file, which made a
133-volume 4K release about twelve minutes of questions, and every check is
given five. The check could never finish, so Sonarr and Radarr waited three
hours and then saw the grab failed, and the watchlist waited for ever.

The files are now asked about several at a time, using every connection the
account has except the one kept free for playback, so the more connections your
account allows the quicker a big release is checked. Measured against the same
133-volume release that could never be checked before: under two minutes on
twelve connections. On four connections it still runs out of time, because the
questions themselves are what take the while. A small release is no slower than
before.

A release the check cannot get through in time is not left to block the title
any more. The watchlist sets it aside the way it sets aside a dead one and
tries the next release, and the SABnzbd endpoint reports it failed as it always
has, so Sonarr and Radarr go and find another.

## Cached-only grabs on TorBox no longer download the releases they were meant to skip

TorBox has a flag that makes an add refuse anything it does not already hold. It is in their
API but in none of their documentation, and zurg was not using it: a cached-only grab added the
torrent, waited to see whether it completed, and deleted it again when it turned out to be a
real download. That spent one of the account's sixty hourly adds, occupied a transfer slot, and
pulled bytes for a release the *arr had already been told to skip.

Cached-only grabs now ask for the content and are refused in under a second if TorBox does not
have it, with nothing left on the account. A miss still costs one of those sixty hourly adds, so
zurg paces them as before. And a hit is still checked rather than believed: TorBox's cache can
say yes to content it then fails to serve, so the release has to finish before zurg reports it.

## Cached-only grabs on Debrid-Link no longer spend the daily add allowance

Debrid-Link accepts a bare info hash as well as a magnet, and only adds the
hash when it already has the content. zurg was sending a magnet, which is an
instruction to fetch: every cached-only miss was accepted, charged against the
account's 50 uncached adds a day and one of its 20 transfer slots, and then
deleted again to get the allowance back. Fifty misses and the account could
add nothing else until the daily reset.

Cached-only grabs now send the hash. A miss is refused outright in about a
tenth of a second and leaves the account untouched, so an *arr can work through
a long release list without spending anything on the ones nobody has. This
holds for grabs that arrive as a .torrent file too: the file exists to spare a
service the metadata lookup a bare hash forces on it, and a cache question
needs none of that.

## Debrid-Link rate-limit lockouts are backed off from again

Debrid-Link answers its hour-long, per-endpoint lockout with HTTP 503 and the
reason in the body. zurg treated every 503 as the service being briefly down,
so it never read the reason and kept retrying an endpoint that had already
said to wait an hour. It now recognises the lockout and stays off that endpoint
until it clears.

## `__magic__` now mirrors your library at `__magic__/__all__`, leaving its root to you

The namespace used to mirror `__all__` at its own root, which made the folder a
download client imports from the same folder every release already sits in. A
Sonarr or Radarr root folder had to be nested *inside* the download folder to
dodge the two health checks that arrangement raises, and a manual import
pointed at the download folder walked the whole library looking for one release.

The mirror has moved one level down. `__magic__/__all__` is the library as
`__all__` lists it and is what `sabnzbd.complete_dir` and
`qbittorrent.save_path` now compute; the root of `__magic__` is yours, for the
`tv`, `movies` and `anime` folders you point the \*arrs at. The two are
siblings, so neither contains the other and neither client warns.

**This changes paths.** If you set `sabnzbd.complete_dir` or
`qbittorrent.save_path` by hand — the container mapping case — append
`/__all__` to it. If you pointed a Plex or Jellyfin library at `__magic__`
itself rather than at a folder inside it, its paths move by one level; point it
at `__magic__/__all__` or at the folder you import into. Your root folders do
not move, and nothing stored in the table moves: placements are paths under
folders you made, and tombstones are keyed on the release, so an existing
layout is untouched. A grab already in flight when you upgrade carries the old
path and needs re-grabbing.

Nothing can be written into `__magic__/__all__`: a row there would be a second
address for a release that already has one, so a MOVE, MKCOL or DELETE aimed at
it is refused. Writing *inside* a release folder is unchanged, which is where
an \*arr puts the .nfo beside a file it imported.

## Export Logs now tells you where your links went and how long they last

Export Logs tries several paste hosts and hands you the first one that takes
the file. It never said which one, and they are not interchangeable: the
preferred host keeps a paste for 180 days and renews it every time somebody
reads it, while the fallback drops it after three. Same-looking link, and a
report filed on a Friday was two dead links by Monday with nothing to explain
why. The links now come with the host that holds them and the deadline that
comes with it.

The reason you were landing on the fallback is the second half of this. The
preferred host blocks an address that uploads a few times in quick succession,
and an export publishes two files per click, so a run of bug reports got the
address turned away — after which every request from that box was refused,
including reading back a paste it had already stored. zurg walked both halves
of every later export into it anyway and logged each one as an upload that had
failed, which pointed at the file instead of at the address. A host that
refuses the box is now left alone for a day and the log says that is what
happened.

## Uploading debug info no longer publishes your indexer and download-client keys

Export Logs redacts every credential it finds before sending the config to a
paste host, but it was only looking at the top level. The keys inside the
nested blocks went out in the clear: your Newznab indexer API keys — from both
the Stremio and the watchlist lists — the Stremio addon token, the SABnzbd and
qBittorrent API keys, the zrok account token and the Plex scan token. The
indexer keys are the sharp one: those are your Usenet account, not zurg's.

They are redacted now. Provider tokens and news-server passwords were never
affected.

## zurg can be driven by an AI agent

There is a new endpoint at `/mcp` speaking the Model Context Protocol, so a
client like Claude can search the library, work out why a release will not
play, and repair it — as typed tools rather than by reading the dashboard's
HTML.

It is off by default. Turn it on with `mcp: {enabled: true}` and point a client
at `http://your-zurg:9999/mcp` using the same username and password the
dashboard takes. Clients that only speak stdio use `zurg mcp`, which bridges to
the instance already running rather than starting a second one.

Alongside the tools it offers zurg's own documentation and its live state as
things a client can read directly, and six prompts for the procedures worth
following exactly — diagnosing a release that will not play, preparing a Plex
scan safely, triaging what repair has given up on.

It knows what it is not allowed to do quietly. Anything that takes something
away describes what it would do first and acts only when you confirm that exact
plan; `read_only: true` withholds every tool that changes anything; and the
tools that could stop zurg or its mount stay behind their own switch. No result
carries a token, a password or a resolved link.

See [the MCP server](mcp.md).

## zurg says when your build is out of date

Nothing in zurg ever mentioned how old a build was, which is how a defect fixed in August reached a bug report in September with the fix already three weeks old and nobody in the thread with a reason to suspect it. Once a day zurg now asks the public repository for its newest release and, if this build predates it, writes one line naming the release, its date and yours. It is quiet the rest of the time: nothing is printed when you are current, nothing is printed when GitHub cannot be reached, and a build that does not know when it was made, which is the Docker image, is not guessed about. Sponsors on a nightly are always ahead of the last public release and never see it at all. The answer is cached for a day so a restart costs no request, a refusal is not retried until tomorrow, and the whole thing is off with `disable_update_check: true`.

## A dead link inside an archived release stops being declared healthy every sweep

When a release is served as a single archive and repair cannot narrow a re-add any further, zurg checks whether the archive itself still reads and, if it does, lifts the broken marks on the release instead of condemning it. It lifted all of them, including the marks on files the account addresses directly with links of their own. A verified archive link proves the archive reads and proves nothing whatever about those. So a file whose link the account had stopped serving was put back to healthy on the strength of an unrelated read, the next sweep unrestricted it and found it dead again, the release was condemned again, and the pass that condemned it ended by restoring it again. On a 64-file release with 9 links the account had stopped serving, that ran 111 times in a week, twice inside the same 40 seconds, at two magnet adds a pass. The reprieve now covers only the files the archive actually serves, which are the ones carrying no link of their own. A file the account addresses keeps the verdict its own link earned and goes to repair, which is the only path that can mint it a working one.

## Downloads that only partly arrive no longer sit in the queue for ever

When some of a release's files could not be read, zurg kept its download in the
queue waiting for exact file sizes it was never going to learn, and the check
that would have found the problem only ran once those sizes had arrived. Sonarr
and Radarr showed such a download at 0% with no time left, for as long as zurg
kept running, and never blocklisted the release or searched for another one.

zurg now asks the news servers about a release that has been waiting thirty
minutes, and reports the download failed if its articles are gone, or if the
servers could not be asked at all. A release whose sizes really are still on
the way is unaffected and is still held back until they arrive.

## A release one account gave up on can be repaired from another

The debrid services keep independent caches. A release Real-Debrid has purged,
or one it refuses on the filename alone, can be sitting cached on AllDebrid
right now under the same hash. Until now zurg could not use that. Repair always
re-added a release to the account it came from, so once that account had given
up there was nothing left to try, and the release stayed dead in your library
while another account you already pay for was holding it.

Now a release that every account holding it has given up on gets offered to
your other accounts. The first one that already has it takes it, and the
release comes back with both accounts behind it, failing over between them like
any release two accounts hold. There is nothing to turn on: if you have a second
account configured and repair is enabled, this is what repair does when it runs
out of other options.

An account is only ever handed content it already holds. If it would have to
fetch the release, the add is withdrawn and deleted again, so nothing downloads
anything and no transfer allowance is spent. An account that answers no is asked
again a day later, then two days, then four, up to about a fortnight, so a
release that is gone for good stops costing anything to keep asking about.

## Cached-only grabs are judged by your account, not by a cache lookup

In cached-only mode zurg used to ask TorBox, Premiumize and Offcloud whether a
release was in their cache and hand that answer straight back to Sonarr. Those
endpoints answer a different question than the one being asked. They say the
content sits in the service's cache, not that your account ends up holding it,
and nothing looked at the torrent afterwards. A yes that turned into a download
reached Sonarr as the instant grab it had just been promised, which is the one
thing cached-only exists to prevent.

Every account is judged the same way now. The torrent is added, the instance is
watched, and only one that finishes inside the window counts as cached.
Anything else is deleted again and the grab is refused, which is what makes
Sonarr move on to the next release in its list. The cost is that a miss on
those three services now spends an add slot, where a cache lookup used to spend
nothing.

## An AllDebrid backup key no longer answers for your library

`download_tokens` on an AllDebrid account are separate AllDebrid accounts, held
for their download allowance. Once the account's own key hit its limit and went
out of rotation, every other call went out on the backup key as well: the magnet
listing, a release's file list, adds, deletes, restarts, the saved links behind
`__downloads__` and the change-detection probe. So the library refresh could
list the backup account's magnets and adopt them as yours, a delete could be
sent to an account that had never held that magnet and come back looking like
it had already been removed, and once every key was capped the catalog went
dark entirely over what is only a limit on bytes. Only unlocking a link rotates
now. Everything that is about your account is asked of your account.

## A healthy release stops flapping in and out of the Broken list

A release whose account keeps offering one dead link could sit in the dashboard's Broken list half of every hour while every file in it played perfectly. Repair drops a link that has answered `hoster_unavailable` for three cycles so it can re-address the release instead, and remembers the drop so the next listing cannot hand the corpse back. That memory was then wiped by the wrong thing: any repair that ended well cleared it, including the passes that mint nothing and only establish that the addressing the entry already holds still reads. "The archive that serves it still reads" is the extreme case — it proves the one link serving the release works, and says nothing whatever about a link the account refused. So the give-up was forgotten, the next refresh adopted the same dead link, repair failed to assign it again and condemned the entry again, on a thirty-minute cycle that could not end. Measured on a live library over three days: one release re-condemned 129 times, 556 condemnations across the library in a week, each cycle spending two to four magnet adds. Only a repair that actually re-addressed the release forgets a give-up now, and a manual repair still forgets every one of them, so an operator can hand a link back by hand.

## A release served as one archive is no longer marked broken every sweep

Some releases are served as a single archive: the `.rar` carries the account's only link and every episode inside it is listed as a file of its own with no link anywhere. The repair sweep asked the account about those interior files regardless. There was nothing to ask with, so no account was consulted and nothing was measured — and the answer came back "file is broken" all the same, which the sweep wrote onto each file and used to condemn the whole release. What followed cost two magnet adds: the account was asked for just the broken files, answered with the same single archive link it had always had, and the archive fallback then verified that link and restored every file that had just been condemned. Measured on a live library: 44 episodes of one 4.9 GB archive through that cycle every half hour. A file no account holds a link for is now left alone, and the archive's own file is judged exactly as before — when the link that actually serves the release stops resolving, that file goes broken and the release with it.

## Traffic goes back to your own account's token once its allowance resets

A Real-Debrid account that spends its daily allowance moves its traffic onto
the first `download_tokens` entry that still has one, and the watcher puts the
account's own token back in the rotation as soon as it can serve bytes again.
Getting a token back did not get the traffic back. The rotation answered from
wherever it had stopped and only asked whether that one token was capped, so
the backup account went on taking every byte for the rest of the day with the
counter on the main account already at zero. The order in `download_tokens` is
a preference now rather than a position to walk through: whichever token is
nearest the front and able to serve is the one that serves, so the main
account picks its traffic back up within a minute of its counter resetting.

## An rclone remote pointed at the wrong address now says so

If the url of an rclone webdav remote is missing the `/dav/` on the end, every listing failed with "couldn't list files: 405 Method Not Allowed" and nothing anywhere said why. The dashboard answered normally in a browser, so zurg looked healthy, and zurg's own log stayed silent about the client that was failing every few seconds. zurg now answers a WebDAV request that arrives outside `/dav/` with the address to use instead, which rclone prints as part of its own error, and writes one warning naming the client that sent it.

## Windows installs now send media server scans again

A `mount_path` of `Z:`, which is what `zurg setup` writes on Windows, built scan
paths relative to the current directory on the drive rather than to its root, so
every path missed the library section it belonged to and no scan was ever sent.
The warning that followed asked the operator to check a `mount_path` that was
already correct. Existing configs need no edit.

## Bulk scan reads the Plex library once instead of once per torrent

Matching after a dashboard bulk scan re-read the whole Plex library for every
torrent in the batch, so scanning a large library aimed hundreds of identical
full-library fetches at a Plex server that was usually busy scanning.

## Windows library paths match regardless of case

A Plex, Jellyfin or Emby library recorded as `Z:\Movies` no longer misses the
`Z:\movies` zurg builds from its own directory name. NTFS is case-insensitive,
so the two name one directory; matching them exactly dropped the scan and
reported the mount_path as wrong.

## A file that stops serving no longer stalls a Plex scan

A broken file kept its place in the directory listing and answered reads with
`503 File temporarily unavailable (being repaired)` until something lifted the
verdict — with repair running, until the repair concluded. Plex blocks on a
503, so one such file stalls a library scan and a library that collects them
never finishes scanning at all, while Jellyfin walks past them and looks fine.

Those are two separate decisions and they now have separate answers. The entry
still stays listed for as long as it might come back, because an entry that
disappears from a folder reads to a media scanner as a deletion and gets the
item trashed — nothing about that changes. What changes is the read: it is
answered 503 for a minute after the file stops serving and 404 after that. A
minute is what a client can use, since rclone retries a 503 and gives up on a
read at about that point, so a short blip is still absorbed and the read
succeeds, while past it the 503 was failing the read anyway and costing every
scan behind it.

Measured against a real Plex on a fifteen-film library with ten files refused
and every file still listed: reads answering 404 finished the scan in 5
seconds, and a 503 that never lifted had found three of the fifteen when the
run was cut off at ten minutes.

## New SABnzbd jobs no longer wait behind a full library's size checks

When zurg restarted with a large Usenet library, it queued a size check for every release and forgot which failed checks were still inside their one-hour retry delay. A newly grabbed release could then sit behind thousands of background checks while Sonarr or Radarr waited for its exact file sizes. Size checks now use a fixed worker queue, a release with a waiting SABnzbd job moves to the front, and both completed checks and retry delays survive a restart in `data/nzb-sizes/`. While work is queued, zurg reports the waiting, client-priority and running counts once a minute.

## Downloads a client never clears no longer stop new ones from being imported

zurg shows Sonarr, Radarr and other download clients a page of finished downloads, and keeps each one on that page until the client removes it. Clients only remove what they import or fail, so an import they block, such as a title they cannot match, stayed on the page for good. Once the page filled with those, every newly finished download waited in the queue and was never imported. A download that has sat on the page for ten minutes without being removed now gives its place to one that is waiting, the way SABnzbd drops older rows off its history page as newer ones arrive. Nothing changes while the page has room, and grabbing a release again gives it a place of its own.

## A download looked up by its id is found as soon as it finishes

Tools that ask zurg about one download at a time by its id, such as LazyLibrarian, are now told it finished as soon as it has, even while the page of finished downloads Sonarr and Radarr read is full. Before, such a download could look unfinished to them until a place on that page opened up.

## Season fix has a page in the dashboard

The library-wide rename that files fansub-numbered episodes under the names
Plex reads has been reachable only as two HTTP endpoints since it shipped:
`/torrents/season-fix/plan` and `/torrents/season-fix/apply`, with no control
anywhere in the dashboard and a single paragraph in the naming reference. A
feature nobody can find does not exist, and this one had been asked for in the
wishlist channel as recently as this month by people who had no idea it was
already built.

`/season-fix/` now explains what the pass does, shows the canonical form it
produces against the fansub name it replaces, and says where the season shape
comes from: Plex's own metadata provider, never the local library, since a
library that has collapsed the seasons is the thing being fixed. It lists what
the mapper refuses to touch and why, because a scan that comes back nearly
empty is the conservative answer working rather than a fault.

Scanning stays behind a button — planning walks every torrent and asks Plex
about each matched show, so opening the page does not start it. Results group
by show with every rename shown old to new and the skipped files behind a
disclosure. An entry flagged as a probable wrong-show match arrives unticked
and says so again in the confirmation, so applying everything at once cannot
quietly rename a release matched to the wrong series.

## Play a compressed release that is split across several volumes

A release that was packed with compression rather than stored whole stopped at
the end of its first volume. Every file inside it listed with the right name and
size and then refused to play, leaving a bad header CRC in the log. zurg now
carries the unpacking across each volume join, so these releases play from start
to finish.

## Start up quickly when your account holds failed torrents

Every library refresh re-checked each torrent your debrid service had marked
failed, one request at a time, and the service allows only a few of those per
second. On an account holding a few hundred of them that alone took over a
minute, on every refresh, and your library stayed unreadable for that long after
each start. That is long enough for Plex to scan a folder that is not there yet
and mark everything in it unavailable. zurg now reads what it already knows
about a failed torrent from disk, and asks the service again only when the
service says the torrent is no longer failed.

## Stop re-asking AllDebrid about magnets it has already refused to retry

When a magnet fails, zurg asks AllDebrid to fetch it again. AllDebrid refuses
some of those, and the refusal was not counted against the two attempts a
torrent gets, so the same magnet was asked about on every library refresh for
as long as zurg ran. The answer is now remembered for an hour, and for the
status the account gave it, so a magnet that changes gets asked afresh. The
count of attempts is also written to disk, instead of being forgotten on every
restart and spent all over again.

## Keep the link steady for a release your account holds twice

A release added twice to one account has two of everything, including two
download links per file. zurg kept one link per account, so each copy replaced
the other's on every refresh and the entry never settled. Nothing was
unplayable, but the log filled with re-pointing and the library was rewritten
to disk every few seconds. zurg now leaves the link alone when it can only see
part of what the account holds.

## Faster change checks on TorBox when the account holds failed torrents

TorBox has no way to ask whether an account changed, so zurg reads a small page
of the newest torrents and watches the ones that have not finished. A torrent
TorBox has failed never finishes, so a single old failure made every check read
a much larger page, for the rest of the account's life. Failed torrents are no
longer watched for movement they cannot make.

## A release your *arr could not import is no longer deleted by the attempt

When zurg refuses to move a release out of the Usenet staging folder because it
cannot be read from the news servers, Sonarr and Radarr do not simply give up.
.NET answers a failed move by copying the file and then deleting the original,
and zurg was honouring that delete, so the release vanished and an empty file
was left where it had been imported to. The delete that follows a refused move
is now refused for the same reason, and the release stays put.

## Usenet reads tell a slow batch from a stalled one

zurg asks a second news connection for an article whose wait has run long and takes whichever answer lands first. Deciding that the wait had run long was done on a clock, and an ordinary batch of large articles on a fast account was asked for twice while its first article was still arriving.

That call now comes from the bytes on the wire. A news connection already refreshes its own timeout every time bytes arrive, and the reader sees that evidence too. A batch half way through a large article is left alone however long that article takes. Only a batch whose bytes have stopped is asked for elsewhere.

When a connection takes a batch of articles and then answers none of them, zurg asks another connection for the whole rest of that batch at once instead of finding each missing article on its own. The quiet connection is never cut off, so its articles still count if they arrive. Only the articles that never arrived are asked for again, at most once per batch. The articles nearest the playhead go first, and one second ask is always left in hand so the next read that stands still can still ask for its own article.

A read also stops treating the wait it spent on a second ask as its own normal speed. It learns the time zurg was willing to wait and no more. On an account where every article legitimately takes a second or more, the threshold now settles near what that account really delivers instead of falling to its shortest setting and asking twice for most articles.

## Usenet read-ahead keeps its window full across articles and volumes

Read-ahead used to stop asking for new bytes while an earlier article was late, so one slow article drained the window it had built. zurg now keeps a bounded window of requested bytes in flight anyway, and one batch of articles can span the join between two stored RAR volumes instead of ending at it.

The window takes at most a quarter of the RAM cache you configured and never more than 128 MiB, so a smaller cache gets a smaller window. Requests keep their own cancellation and their account's connection and cache limits.

## Usenet playback costs less CPU on older processors

The read cache checksums every record it stores. On Intel and AMD processors that have SSE4.1 but not AVX, SHA-256 runs with no hardware help at all, and that cost showed up during playback. zurg now uses a faster 256-bit checksum on those processors. Records carry a version so damage is still detected, an existing cache stays readable, and every other processor keeps SHA-256.

## NZB shares no longer point back to the account that grabbed them

Some indexers stamp every download with details that lead back to your account, and part of that sat in fields a share kept. One hides a fresh token in the release title and often in the password, and changes the poster, the date and the newsgroup on every file. Another puts your account number at the front of one file's subject. A third puts an account marker in every poster. `zurg nzb-share` now drops posters and dates, gives every file the same fixed newsgroup, cuts the subject stamp and ignores a token wherever it sits. When the name and the title disagree, the name wins. Two people who grabbed the same release now publish the same file. Shares also stop leaving out NZBs saved in the Latin-1 encoding, and stop doubling the backslashes some subjects carry.

What the clean removes is in [`zurg nzb-share`](cli.md#zurg-nzb-share).

## Local libraries add the hash on AllDebrid, Premiumize and Offcloud

A local library whose manifest has no portable link adds the hash to your account on first play. A manifest exported from TorBox is always like that. So is one whose AllDebrid link has expired. On AllDebrid and Premiumize and Offcloud every such play failed with "provider did not report an active torrent allowance". zurg wanted the account to report its torrent slot limit before adding. Those three never report one. zurg now falls back to the declared slot count the way repair does. With neither it adds the hash and lets the provider refuse a full account.

## Offcloud files report their length

Resolving an Offcloud file left its length unset. A local library checks that length against its manifest. So it refused every Offcloud play with "resolved file size does not match the portable manifest". Ordinary playback also lost the range handling that needs a length. zurg now asks the delivery server for the length the way the Offcloud listing already does.

## zurg runs on Android phones and Google TV

A new Android app hosts your library on the device itself. It adapts to phones and tablets as well as Android TV and Google TV. It needs Android 8.0 or newer and Usenet needs 64-bit Android. The app walks you through provider accounts and a device profile and then starts the library. You browse it in the app or in Android's Files and play in the external player you choose with full seeking. A TV remote drives every screen. MediaInfo works on the device with no extra tools. The library can also be shared with other devices on your local network behind a password. That password never travels to a player.

The APKs are on the sponsor nightly releases. The app does not carry zurg itself. After you sign in to GitHub it installs the zurg engine as a second package. The app and the engine update separately. Updates lists every engine version still published so a nightly that misbehaves on your device can be rolled back to one that worked. Anyone who installed the first Android build needs to install an engine from Updates once. Providers and library settings carry over untouched.

The engine for 64-bit ARM devices now looks up provider addresses through Android's own resolver. The first build's engine could fail to reach any provider at all.

Setup and player notes are in [Android](../guides/android.md).

## A new NZB shows up in the library within seconds

An NZB dropped into the watch directory used to wait for the next periodic change check. An obfuscated release then waited a second interval while its real filenames were read. At the default interval that added up to 20 to 30 seconds with a Sonarr or Radarr grab sitting at Queued the whole time.

zurg now checks the watch directory itself once a second. It does not rely on filesystem events and so it behaves the same on a NAS or inside a container. A release is listed the moment its names have been read. A season pack of twenty releases still costs one listing. The periodic check stays as the backstop for an NZB replaced under a name it already had.

## Usenet streams hold their speed

A file inside a RAR set reaches the news account one volume at a time. zurg opens the next volume early so the crossing does not start cold. It used to warm only the first four megabytes. On a release cut into small volumes that meant a boundary every second or two of playback and a stall at each one. One such release streamed at 14 to 16 MB/s where a plain file on the same account ran at 86 to 99 MB/s. The next volume is now warmed a full read-ahead window deep once the stream comes within 32 MiB of it. A volume the stream has just crossed into keeps the read-ahead it earned. A volume nothing is near is still warmed only at its head. That keeps a library scan from pulling data it will never read.

A steady read also spent about one second in twenty crawling on a single slow article while every other connection waited behind it. zurg now asks a second connection for that one article once the wait runs long and uses whichever answer lands first. It only does this for a read a player is waiting on. Read-ahead and repair are never doubled up. It is capped at twenty extra requests a minute per account.

The read a player is waiting on now comes first in more places. Read-ahead no longer takes an account's last free connection. The sizing pass at startup leaves one free too. A read uses connections the account already holds instead of opening its own. It waits for a connection already being opened rather than paying for another. The article a player is stuck on can jump ahead of queued fetches for later bytes. In one measurement the first byte of a read arrived in 177 ms instead of 354 ms. Warm-up and keep-alives and reads also share one connection limit now. zurg never opens more connections than the account allows.

Saving a decoded article to the disk cache no longer holds up the read that fetched it. The write used to sit inside a lock every other read needed. It now happens after the bytes reach the player. A burst larger than the cache can keep up with skips the extra records rather than slow playback. An existing cache carries over as it is.

## Sonarr and Radarr stop waiting on grabs that can never finish

The SABnzbd endpoint used to leave some jobs queued forever. The client never blocklisted them and never grabbed another release. Each case below is now reported Failed with a message that says why. Failed is what makes Sonarr and Radarr blocklist the release and search again.

A release can leave the library after its grab. It may be deleted from the dashboard or removed from the watch directory or dropped by every account. The job used to sit at 0% with nothing that would ever move it. It now fails once the release has been gone for fifteen minutes. Nothing fails in the first fifteen minutes after a restart while the library is still loading.

A grab can land on a release an earlier import already emptied. That happens when an upgrade deletes the imported file and a search picks the same release again. zurg used to answer Completed and point the client at a folder with nothing left in it. A later grab of an emptied release now fails at once. A folder that stays empty for fifteen minutes fails its job too. That covers a folder emptied by a move done by hand or by an import filed under another job. The grab doing the import still reads Completed while it finishes.

Some releases never finish their article check. zurg asks the news servers whether a release's articles are still there before it reports a grab finished. A check that could not complete used to be retried every minute without end. It now fails after thirty attempts in a row that span at least three hours. A news account that is down for an hour does not get every waiting job blocklisted. A check that finally answers resets the count.

Some releases do not hold their whole archive. A set can have no volume holding the start of the file. It can be missing a volume from the middle. It can start somewhere other than its first volume. Sonarr used to be pointed at a folder it could never import from and retried it forever. The grab now fails. The verdict is tied to the exact volumes it was reached on. A PAR2 repair or a re-grab or a second account holding the missing volumes gets the release looked at again.

## Backup download tokens take over when the daily allowance runs out

Real-Debrid refuses a download once a token has spent its daily allowance. zurg is meant to retire that token and move on to the next entry in `download_tokens`. That stopped happening during playback when proxied streams moved to a new HTTP client. The refusal came back as an ordinary response and nothing marked the token spent. Every backup token sat unused and every read spent the capped one again.

The refusal is now recognised wherever zurg meets it. That means playback and also the refresh loop and repair. Both of those check links whether or not anything is playing. A refusal that arrives without Real-Debrid's usual header retires the token as well.

A retired token is tested once a minute so it can return as soon as its allowance does. That test used a link cached under the retired token itself. Nothing refills that cache once the token stops serving. So the test found nothing and the token stayed out until the nightly reset or a restart. It now borrows a link from whichever token is still serving.

The nightly reset was a day late. Real-Debrid resets allowances a few minutes after midnight CET. zurg skipped the first midnight after every start and reset at the second. An account that had spent its allowance kept serving from its backup token for an extra day. zurg also worked out that midnight from the host's own date. West of Europe that left the reset at whatever hour zurg happened to start. Every reset is now scheduled from the date in CET.

## A magnet grab keeps its release name on the debrid account

Sonarr and Radarr hand the qBittorrent endpoint the indexer's whole magnet. zurg used to cut it down to the info hash before adding it. The display name and the trackers never reached the account. On a magnet-only indexer the display name is the only place the release name exists. An uncached torrent then sat in the account's list under a 40-character hash. For a torrent nobody seeds that is the only name it ever gets.

The magnet now reaches the account as the client sent it. Repair and the Plex watchlist and portable libraries still add the bare hash because they have no name to pass on.

## The .strm dump holds only files a player can open

`save_strm_files` used to write a .strm for every selected file of a release. Subtitles and posters and NFOs and PAR2 volumes each became a library entry that opens to nothing. TorBox and AllDebrid mark every file selected. So does a Usenet post with its repair files beside the video. Now only recognised video and audio get a .strm along with anything named in `addl_playable_extensions`. A video inside a RAR set is still written while the volumes around it are not. Entries written by earlier builds are removed the next time the release is walked.

Several write paths also told the media server to scan before the .strm files existed. Plex or Jellyfin or Emby could look at an empty folder and index nothing. Nothing would ask it to look again until the release changed. The files are now written first on every path.

## Moving the zurg folder no longer strands the mount cache

The rclone mount keeps what it reads in `data/rclone-cache`. rclone names that cache after its own configuration. The configuration includes the full path of zurg's `data/local` folder. Moving the zurg folder or changing `union_writable` gave the cache a new name. The old tree stayed on disk where no size cap counted it and nothing cleaned it. A few moves could leave terabytes behind.

At mount start zurg now asks rclone which cache tree is live and deletes the others. It logs what it freed. It skips the sweep when `rclone_extra_args` sets its own `--cache-dir`. Set `rclone_cache_reclaim: false` to keep the old trees.

The live cache is also bigger than most people expect. It grows to 256G by default and stays there. A media server's nightly pass touches every file and so the 72-hour age limit almost never evicts anything. Plan around the size cap. How to lower it is in [the configuration reference](config.md#disk-the-mount-uses).

## Posters and .nfo files keep landing in `__magic__`

A client that writes through zurg's mount puts new files in `data/local`. That is the folder where `__magic__` keeps its sidecars. zurg counted every file there against `sidecar_budget_mb`. A few videos an \*arr wrote through the mount could use up the whole budget. Every .nfo and poster after that was refused as though the tree were full. Raising the budget never helped. A file larger than `sidecar_max_mb` cannot have come through zurg's sidecar path. Those files no longer count against the budget. zurg names them once at startup because they still take up disk space.

Deleting a `__magic__` path that is already gone now succeeds. The mount can remove a shared sidecar from both of its sides without breaking an import's cleanup.

## A Stremio play tries the next release when the first has aged off

A Stremio click used to mean one release. If that release held nothing playable the play failed with a 404. The usual cause is a post that has aged off the news server. The stream list might have shown a dozen other releases.

A refused play now tries up to two more rows from the same ranked list. It starts after the row you picked. So the fallback is the same resolution and smaller or the tier below. It is never a bigger release you passed over. A release that is still being fetched answers 503 as before and pressing play again picks it up. Each try spends an indexer grab and leaves that release in the library. Play links made before this change behave as they always did.

## Stremio lists show every resolution and a spread of sizes

The stream list's cap used to count across the whole list. 4K results sort first and a popular title has more of them than the cap. The list could fill with 20 to 40 GB remuxes and hide every 1080p and 720p release the search had found. `stremio.max_results` now counts per resolution and defaults to 5. A value you set by hand keeps its number and now applies to each resolution.

Within a resolution the list used to keep only the largest releases. The 4 GB encode a phone or laptop would play was the one that got cut. Each resolution now keeps evenly spaced picks from its largest release down to its smallest. Both ends are always included.

Each stream's description now ends with how long ago the release was posted. It reads `3d` or `126d` or `2y`. Age is the best clue that a post may have aged off the news server. Results cached before this change show no age until that title's cache is refreshed.

The addon's manifest now carries the real build version instead of `0.1.0`. `zurg --version` prints the same build details as `zurg version` and needs no config file.

## Healthy releases stop disappearing from the library

A failed connection or DNS lookup at the Real-Debrid API now marks the account temporarily unavailable. It used to mark healthy files broken. They then sat waiting for repair after the network came back.

Cleanup after a library refresh used to wait behind background media analysis. By the time it ran a newer refresh could have added a release back. The late cleanup then removed it again. Cleanup now finishes before a refresh returns. Media analysis still runs in the background.

## Kodi can browse the WebDAV share

WebDAV listings now give the full path of every folder and file with the `/dav/` prefix included. Kodi and other strict players used to drop that prefix and could not open folders or media. Names with escaped characters and paths inside archives keep their addresses.

## A busy news server no longer puts holes in a stream

A news server can answer "no such article" for an article it holds while it is busy. zurg used to confirm that answer a few hundred milliseconds later on the same connection. It then served the span as zeros and wrote the article off for a day. One 32 MiB read came back with 384,000 zero bytes from an article the server served correctly a minute later.

A refused article is now asked about once more a second later. The second ask goes over a different connection where one is free. The read waits for that answer instead of filling the gap. An article that really is gone is still served as silence and repaired as before. A damaged release therefore takes about a second longer to reach that silence.

An article whose connection goes quiet is also asked again once on another connection. It used to fail the whole response. A RAR stream answered 500 for an article the provider was only slow to send.

## Choose how zurg identifies itself to the services it calls

Requests to debrid services and indexers now use a generic browser User-Agent by default. Subtitle lookups use it too and no longer send `zurg v0`. Those requests also drop origin and referrer headers along with zurg's own headers. That holds through redirects. A redirect cannot leak the previous URL's private path or API key.

`user_agent` sets a different agent and `omit_user_agent` sends none. The `outbound_*` keys set the client and device names that Plex and Jellyfin and Emby see. All of them are on the dashboard under Network & Connectivity and take effect after a restart. Usenet connections send no software identifier at all. This removes zurg's own identifiers. It does not make you anonymous.

The details are in [Outbound identity](outbound-identity.md).

## zurg empties the Plex trash by default

zurg turns off Plex's "Empty trash automatically after every scan". Otherwise a scan that meets a briefly unreadable mount deletes the library instead of parking it. What that left behind went unnoticed. Plex no longer collected dead entries and zurg's own removal was opt-in. So by default nothing collected them. Entries whose files were long gone piled up. The most visible case was a file moved between library folders whose old entry stayed forever.

With `plex_trash_sweep_every_mins` unset the trash sweep now runs every 60 minutes. It stands down when Plex is still emptying its own trash. It removes one entry at a time and never one that still has a file. It only runs against a mount that reads. Anything it cannot judge stays visible as broken for 14 days first. Write `plex_trash_sweep_every_mins: 0` to keep removal off and empty the trash yourself.

That setting does not hand trash emptying back to Plex. The config page now has a Let Plex Empty Its Own Trash switch for that. The risk it carries is written beside it.

Restoring works now too. Plex skips an ordinary scan of a folder it has already scanned. A trashed show whose files were all back could stay trashed through scan after scan. The sweep now asks Plex for a forced scan of that folder. A scan started by hand from the dashboard also reaches the `__magic__` paths a Usenet library is indexed from. It used to find no Plex section and do nothing.

How the two collectors share the job is in [Plex](../guides/plex.md#who-empties-the-trash).

## Damaged archives list the right bytes or nothing at all

Some damaged RAR sets used to list a video that played the wrong bytes. A set missing a volume from the middle served the rest of the file shifted with a tail of zeros. Such a set is now refused. A set whose first header could not be read had its later bytes shifted. zurg now reads the continuation headers first so every offset holds. Files after the movie in the last volume are kept too. A RAR4 end marker used to be mistaken for encryption. Split sets with padded end blocks lost their first volume. They now list the complete video.

An NZB with 10% or more of its articles missing is refused before anything is served. Content that PAR2 has already rebuilt still plays.

Existing archive listings are rebuilt so these fixes reach releases already in the library.

## Large libraries can give idle memory back

`library_detail` decides whether every release's file list stays in memory. `resident` keeps them all and stays the default. `lazy` releases file lists nobody has read for `library_detail_idle_secs`. Listings stay available and a file list comes back from disk when something reads it. `auto` does the same only under sustained memory pressure on the host or container. Large season packs hold much less memory under either. A compressed recovery copy protects a file list if its disk cache is damaged. Unsaved changes are never released. The dashboard offers all three modes. A change needs a restart.

Startup also uses less memory with a large Real-Debrid download history. Saving and loading that history and the library caches no longer makes extra copies of them.

The trade-offs are in [the configuration reference](config.md#library-detail).

## Plex watchlist and Seerr requests share one queue

The `acquisition:` block feeds Plex watchlist items and Seerr requests into one queue. Both are searched on your Newznab indexers and land in the Usenet backend. Seerr requests are followed only once approved. Only the requested seasons are grabbed. A 4K request is kept apart from a 1080p one. Open Seerr requests are rechecked for newly aired episodes.

Progress now survives a restart. That covers retry deadlines and attempt counts and which episodes are done. An interrupted acquisition picks up where it stopped. One that already finished only retries removing the item from the watchlist and does not search again. The saved state is part of normal backups. Existing `watchlist:` settings keep working unchanged.

Setup is in [Acquisition](../guides/acquisition.md).

## Debrid libraries can live in portable local files

A debrid account can now take its library from a folder of `.zurgtorrent` files instead of from the account's own list. `zurg export-torrents` writes an existing library out as those files. They describe the content and carry no credentials or download links. So a library can be shared. The person receiving it plays through their own account and their provider's limits still apply. Importing and listing and refreshing the files adds nothing to the account.

Existing configs keep working. New backups use format 2 and need this build or newer to restore.

Export and setup are in [Local libraries](../guides/local-libraries.md).

## Read caches survive a restart

zurg now keeps its read caches on disk across restarts. That covers parsed NZBs and decoded Usenet articles. It also covers archive layouts and decoded archive blocks and delivery links. After a restart zurg does not have to parse every NZB or read every archive header again. Each byte cache is capped at 512 MiB by default. `zurg backup --include-caches` adds them to a backup for a warm restore.

Requests for the same AllDebrid or TorBox file at the same moment now share one link lookup.

Settings and limits are in [Persistent caches](../internals/persistent-caches.md).

## Usenet grabs are checked more closely before they read Completed

Before a grab reads Completed zurg asks the news server about the first sixteen articles and the last article of each content file. It used to check only the first. That missed gaps in the media header. The checks go out as one batch per file so large archives no longer run out of time.

A release whose missing articles PAR2 has fully rebuilt now imports. It used to fail because the original articles were still gone from the server. A partial repair still does not count.

`sabnzbd.history_limit` can now match a larger history limit in Sonarr or Radarr. A big backlog of finished jobs then drains in larger batches. Both ends must use the same number. The default stays sixty.

## `enforce` leaves the Plex features you can see alone

`plex_settings_policy: enforce` no longer turns off scrubbing previews or chapter pictures. Nor does it turn off volume levelling or sonic analysis. Each of them decodes whole files and that costs bandwidth on a debrid mount. Each also gives you something you can see. They now sit with Skip Intro and Skip Credits as a matter of taste. zurg still reports what each one costs. It just stops making the choice for you. The bandwidth group now holds only analysis whose output nobody looks at.

## Expired debrid links recover without failing playback

A TorBox link whose signed token has gone stale now gets a fresh one. Readers waiting on the same file share that one lookup. Repeated failures pause playback without marking the file broken.

When a TorBox or Real-Debrid or AllDebrid download server asks zurg to wait it now waits as long as it is told. It also stops retrying a server that keeps refusing. That holds for playback and link checks and archive reads. A revoked link opened through `__downloads__` gets a fresh one too.

## zurg updates itself

`zurg update` replaces the running binary with the newest sponsor nightly. It reads the release feed with the GitHub CLI sign-in when one exists and `GITHUB_TOKEN` or `GH_TOKEN` otherwise, checks the download runs and reports the expected version before anything is replaced, and swaps the binary in by rename so an update cannot fail while zurg is running. A build already on the newest nightly, or ahead of it, is left alone. Inside a container the command refuses and points at the image pull instead, since a replaced binary there is lost on the next recreate; `--force` overrides. The installers gained a matching `update` mode for builds too old to carry the command.

Per platform: [Linux](../setup/linux.md#updating-zurg), [macOS](../setup/macos.md#update-zurg), [Windows](../setup/windows.md#updating-zurg), [Docker](../setup/docker.md).

## One Plex setting can be opted out of the policy

`plex_settings_ignore` names Plex preferences zurg leaves alone whatever `plex_settings_policy` says. It exists for the setup that genuinely wants one of them: a library whose files move between folders depends on Plex emptying its own trash to clear the entry left behind, and the default policy turns that off — while dropping to `warn` to get it back would also give up the filesystem-event guards beside it. An ignored setting is still read and still reported, on the dashboard and as `skip` in `zurg plex-settings`; it is only never written, never warned about, and never behind the trash banner. Ignoring a safety setting is at your own risk and zurg says so once at startup; an id that names nothing is reported and leaves the setting guarded, so a typo cannot read as an opt-out.

The settings themselves, and what each policy level does with them, are in [Plex](../guides/plex.md#recommended-plex-settings).

## One-line installers for every supported host

Fresh installs now have optional one-line bootstraps for Linux, macOS, Windows and Docker on Linux. They check or install platform prerequisites, use GitHub's browser sign-in for sponsor access, download the correct architecture, and hand off to `zurg setup` and `zurg doctor`. Existing binaries and configs are preserved, and every manual guide remains available.

## Setup asks which providers to configure

Fresh `zurg setup` installs no longer assume Real-Debrid. The interactive installer asks for one or more providers in priority order and collects only the selected credentials. Non-interactive installs can repeat `--provider` and use provider-specific token-file flags or environment variables. Existing configs are still preserved and the legacy Real-Debrid `--token-file`, `TOKEN` and `RD_TOKEN` inputs remain compatible when supplied explicitly.

## A burst larger than Sonarr's history window no longer loses imports

Sonarr and Radarr ask SABnzbd for every queued job but only the newest sixty history entries. That usually describes a real downloader well: completions arrive gradually and the client removes each one after importing it. A cached NZB library is different. A bulk season search can finish hundreds of individual episode jobs before the client's next poll, and zurg used to remove all of them from the queue while returning only sixty in history. Every job past that page was absent from both responses, so the client never imported or failed it and its release remained at the root of `__magic__` indefinitely.

zurg now keeps finished jobs beyond that visible page in the queue. As the client imports and removes the first sixty, the next completions advance into history. A season grabbed as individual episodes therefore drains in bounded batches instead of racing a fixed-size window; a season pack still behaves as one job.

## A delete through the mount always works, and `dav_allow_delete` is gone

Deleting a file from a media server pointed at the mount used to do nothing visible: zurg refused the WebDAV DELETE with a 403, rclone turned that into an I/O error, and the client reported a failure with no cause attached — Plex answers a plain `400 Bad Request` and logs nothing, so the button simply did not work and nothing said why. The key that allowed it, `dav_allow_delete`, is removed; a DELETE through the mount is now honoured everywhere, with no configuration. A config file that still sets the key is not an error — unknown keys are ignored — it just no longer does anything.

What the key was guarding has not gone away, so it is worth stating plainly: rclone has no way to express "overwrite" and flushes a rewritten file as DELETE followed by PUT, which means a program that rewrites a file in place — an `.nfo` writer, a trickplay pass, an \*arr rename, a stray `touch` — deletes the release from the debrid account rather than replacing a file, and the mount carries rclone's own credentials so nothing upstream can tell that apart from a deliberate delete. The PUT half is still refused, which is what keeps the sequence from completing quietly. If anything writes into your mount, set `mount_read_only: true`, which fails the write at the kernel before it reaches zurg at all.

## The Plex watchlist acquires through your Newznab indexers

The watchlist monitor now works, and it works off your own indexers. The old version searched through a DMM API key — and silently stopped working when Plex moved the watchlist to its discover host, since the endpoint it polled started answering 404. It now polls the right host, and every new watchlist item is searched on the Newznab indexers you already configured: a movie becomes the best matching release, a show is acquired season by season **preferring season packs** over loose episodes — a season nobody posted a pack of falls back to the loose episodes, best release per episode — and a chosen release whose NZB link fails to fetch (an indexer's burst-limit 429, say) falls to the next-ranked candidate rather than costing the item. The chosen NZB drops into the Usenet backend through the same naming rules as the SABnzbd endpoint and the Stremio addon, so the three surfaces find each other's grabs instead of duplicating them. An item leaves the watchlist only after something was actually acquired — the old order removed first and asked questions later, so any failure quietly ate the item off your list.

Configure it with the new `watchlist:` block: `enabled`, `check_every_secs` (default 60), `indexers` (empty borrows `stremio.indexers`), `max_size_gb` (default 40, movies and single episodes), `max_season_size_gb` (default 100, season packs) and `quality` (`best`, `4k`, `1080p`, `720p`, `smallest`). The legacy `plex_watchlist_*` keys keep their meaning. A `plex_token` is all the Plex it needs — the monitor talks to Plex's cloud service, so it runs fine on an instance with no `plex_server_url`. TV searches lead with the TVDB id and retry once by IMDb id when that finds nothing — indexers key TV on TVDB, and their show-level IMDb mapping is patchy enough that a heavily indexed show can answer an imdbid search with zero results.

Every key is on the config page under **Plex Watchlist**, and in [the configuration reference](../reference/config.md#watchlist).

## A Stremio addon over your Newznab indexers

zurg can now answer Stremio directly. Turn on the `stremio:` block, list your Newznab indexers, and paste the logged `/stremio/<token>/manifest.json` URL into Stremio: the client asks for streams by IMDb id, zurg searches the indexers (movies by `t=movie`, episodes by `t=tvsearch` with season and episode), and the results come back ranked resolution-first as playable streams. Picking one pulls the NZB into the Usenet backend — through the same naming rules as the SABnzbd endpoint, so a release grabbed twice is found rather than duplicated — and plays it through the signed `/strm/e/` endpoint, ranges, failover and archive interiors included. Everything played lands in the library, so it shows up in Plex like any other release.

The token in the path is the whole authorization, generated and kept in `data/stremio-token` when the config names none. Search results are cached in `data/stremio-cache` so reopening a title costs no indexer calls, for a lifetime that scales with how much the search found — an hour per result up to four, `stremio.cache_hours` (default 24) from five, never for an empty answer — and a cached stream list carries a refresh item that clears the cache for that title. Releases larger than `stremio.max_size_gb` (default 40) are dropped from the list, so a full-disc remux does not outrank every playable option.

The whole thing, including what the first play costs: [The Stremio addon](../guides/stremio.md).

## One folder is the whole Docker install, and it mounts on the first run

The documented way to start zurg in Docker was one `docker run` with a `TOKEN` in it, and it produced a container that mounted nothing. The config it generated left `rclone_enabled` off and `mount_path` unset, so `/zurg_mnt/zurg` stayed empty until someone found the two controls in the Dashboard — and that config was written inside the container, so the next `docker pull` threw the answer away along with the library cache. The quick start needed a footnote listing both of those, which is a quick start admitting it does not work.

`MOUNT_PATH` now seeds `rclone_enabled: true` and `mount_path` into the config on the run that creates it, next to what `TOKEN` already seeded. The image's working directory is `/config`, and everything zurg keeps resolves against it — `config.yml`, `data/`, `logs/`, `dump/`, `strm/`, `nzbs/` and the rclone cache — so a single `-v ~/zurg:/config` holds the entire install and an image update moves none of it. A first run is one command and ends with a mounted library rather than a Dashboard errand.

Both variables are read **only when there is no config file yet**, and are ignored ever after. That is the same rule `log_level` already has against `LOG_LEVEL`, for the same reason: a `MOUNT_PATH` left behind in a compose file must never quietly undo a mount path changed later in the Dashboard. Startup now warns when one is set and disagrees with the config, so an operator redeploying against no effect is told why.

Installs made against the old layout are untouched. Docker creates the target of every bind mount, so `/app/config.yml`, `/app/data` or `/app/logs` being present is the old layout announcing itself, and the container keeps using `/app` when it sees any of them. The full setup, and what breaks a host-visible mount, is in [Docker](../setup/docker.md).

## TorBox and AllDebrid are handed the `.torrent` too, so a private grab is not left hanging

The `.torrent` file an \*arr sends started travelling with the add last release, but only Real-Debrid could take one — the other two accounts were still handed the info hash alone, which for a private tracker's release is the one form of it they cannot use. Nothing failed, which is what made it hard to see: measured against the live TorBox account, a hash with no public swarm was accepted with a torrent id and then sat in `checking` reporting `size: -1`, no file list and a hundred-day estimate, exactly as reported from a TorrentLeech grab that "just hangs, nothing downloads". The same release's file was answered at once with its real name, its real size and its file list, and the qBittorrent endpoint could get on with the job.

Both accounts now take the file. TorBox's `createtorrent` and AllDebrid's `magnet/upload/file` both accept it in place of the magnet and answer in the shape the magnet add already answered in, so nothing downstream of the add changes — AllDebrid still reports on the upload itself whether it already held the content, which is the only cache answer that account ever gives. Verified live through zurg's own add path on both: a cached release uploaded and read back `done` at 100% with its file list within seconds, and one nobody holds read back named, sized, and stalled for want of peers — a state the endpoint can act on, where the hash's was a torrent that never resolves and never finishes.

One refusal is now legible as well. A TorBox call refused with a 4xx reached the caller as the shared HTTP client's bare "unexpected status code: 400", because the response body — where TorBox puts its own error code and detail — was dropped in favour of that error. So a `.torrent` TorBox will not act on was reported to the \*arr as a status number and nothing else. The body is now read first, and the account's own reason travels with the refusal.

What this means when you set the indexers up: [Sonarr & Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## Compressed archive entries stream, decoded on demand

A compressed RAR or deflate zip entry can't answer a ranged read the way a stored one does — its bytes exist only behind a decoder that must run from the entry's start — so zurg refused them: a compressed-only release answered 415, and compressed siblings of stored entries were skipped. That was the honest answer for a streamer, but it hid the bulk of Usenet's older catalog: every poster who packed with compression, whole and entire.

These entries are now served by decoding forward on demand into a bounded in-memory window — nothing written to disk, nothing decoded that no read asked for. Sequential playback, the pattern a player generates, lands at the window's edge and advances it a little per read; a seek backwards past what the window kept restarts the decode from the entry's start. The whole entry's bytes are what unrar would extract: a real compressed RAR4 volume's three jpg entries decode byte-exact against the same fixture read by an independent decoder pass, md5 for md5.

Walking a split set's volumes needed rardecode's volume chain, which opens `.part02.rar` from the filesystem; zurg's volumes live behind ranged network readers. The decoder is now vendored under `internal/rardecode` (MIT, upstream v1.1.3) with one change — `OpenReaderOver` takes an opener, so each next volume comes from the set by the name the archive itself derives. Listings change shape accordingly: a compressed-only release presents its payload (`stream_compressed_archives: false` restores the old refusals), and a mixed archive lists its compressed siblings beside its stored ones. Listing version 15.

## Sonarr and Radarr can grab torrents, and Prowlarr can push them

zurg can answer the \*arrs as though it were a qBittorrent. They hand it a magnet or a `.torrent`, it adds the info hash to a debrid account — Real-Debrid, TorBox or AllDebrid, whichever is configured — and once the release is in the library the torrent reports finished with a folder under `__magic__` to import from. The import is the same rename the SABnzbd endpoint has always given Usenet grabs: a row in the `__magic__` table, no bytes moved.

The endpoint registers at `/api/v2` and `/qbittorrent/api/v2`, off until asked for, gated by an API key the clients send as a bearer token. A grab is offered to every account that takes torrents in the order of `providers:`, and a grab that stops moving — no stage change, no rise in progress, for `qbittorrent.download_timeout_mins` minutes, fifteen by default — comes off its account and is tried on the next. `0` takes only content an account already holds cached and refuses the rest inside the add, which is the one refusal the \*arrs act on. What the account is doing with a download is mapped onto the states the clients understand, with the rate and the swarm and the time left where the account reports them.

One honest limitation: qBittorrent's API has no way to say a download failed, so a release no account would take reaches the client as a warning rather than a blocklist entry — visible in the queue with the reason attached, but never re-grabbed unattended. The SABnzbd endpoint does not have this problem.

Prowlarr speaks to the same endpoint for what a download client is to it: pushing a release to the account by hand. Nothing imports behind a Prowlarr push — that is what the \*arrs are for.

Full walkthrough, captured against a live install: [Sonarr & Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## `__magic__`, a directory you can organise

Every directory zurg serves is a saved filter. A release is in `movies` because it matches the movies filter, and it is in `__all__`, in `recent` and in `movies` all at once — so there has never been anywhere in the library to *put* something. That is fine until a program wants to move a file. Radarr and Sonarr import by moving, and a mount that cannot receive a move leaves them copying instead: every import pulls the whole release down from the debrid host or from Usenet, which is the one thing the mount exists to avoid.

`__magic__` is a new top-level directory that starts as an exact copy of `__all__` — every release as a folder, holding exactly what `__all__/<release>/` holds, a virtualised archive's contents included — and inside which anything can be moved anywhere. `mkdir -p /mnt/zurg/__magic__/tv/Show/Season 01` and `mv` an episode into it, and the episode is there: no bytes moved, no torrent renamed, nothing re-downloaded, and `__all__` unchanged. A move rewrites one row in a small table, and that table keys on the release's content hash and on the file's own path inside it, so a repair that re-adds the release and rebuilds every id around it does not lose where you put things. Renaming a release from the dashboard does not either.

Moves go both ways. A file can be moved *into* a release folder as well as out of one, and the folder lists it beside the release's own entries — which is what a program that puts something back into the folder it is importing from needs to see. Where a name arrives from two places at once the deliberate one wins: what you moved beats what the release calls that name, which beats a file sitting in `data/local`, and the loser is not listed rather than listed twice.

Deleting is the other half, and by default it hides rather than destroys. An `rm` inside `__magic__` takes the entry out of `__magic__` and leaves it in `__all__` and in every filter directory, so a client reorganising a library cannot lose any of it — and a release folder can vanish the same way, which is what lets Sonarr delete the job folder after an import without touching the release it just imported from. `magic.allow_delete: true` opts into the stronger meaning for files, where the content goes too; a release folder and a directory only ever hide, whatever that is set to.

It is off by default, because it is a writable tree and an \*arr pointed at the wrong root folder can reorganise a library:

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

The two `sidecar_` keys are for clients that mount `/dav` directly rather than through zurg's own mount. Those send zurg the `PUT` of a new `.nfo`, poster or subtitle track, and it now writes the body into `data/local/__magic__/…` — the same tree zurg's own mount already writes such files to — so the two views show one directory instead of two, and the file reads back with ranges, a length and a modification time like any other. The caps keep that from quietly becoming a general file store: a file over `sidecar_max_mb` is refused with 413, and one that would take the tree past `sidecar_budget_mb` with 507. Nothing the library answers for can be written over — a release folder, an entry of one, or a path something was moved to is a 403 — and a move never destroys a real file to make room for a row.

Two things are worth knowing before pointing anything at it. The filter directories are untouched by design, so a release moved inside `__magic__` is still in `recent` and `movies` under its own name — point a media server at `__magic__` **or** at the filters, not at both. And the mount has always been writable in one direction: anything genuinely new written into it — an `.nfo`, a subtitle, a poster — lands in zurg's own `data/local` and is merged into the listing, which is why sidecars beside a release simply work and why an \*arr's root-folder write test passes.

`dav_allow_rename` and `dav_allow_delete` have nothing to do with any of this. Those guard the path that renames and deletes what the debrid account holds, and a write under `__magic__` reaches no account. `mount_read_only: true` still overrides everything.

The dashboard has a page for it, at `/magic/`. It shows every row the table holds — grouped by release, saying what each one is, which file of which release it came from and where that file is served from now — along with how many rows there are, what the journal and the snapshot take on disk, and how much of `sidecar_budget_mb` the real files beside the library are using. It also reports the size of the whole of `data/local`, which is the number that says whether something is importing by copying: a client that copies instead of moving puts the bytes there, and nothing else on the dashboard would ever show it.

Three of the states it shows could not be reached from a client at all. A placement can be **reset**, and the file goes back to where the library puts it; a tombstone can be **unhidden**, and the entry is listed again; and a **dangling** row — one whose release, or whose file inside it, the library no longer holds — can be dropped, one at a time or all at once. That last one is new ground: such a row resolves to nothing, so no client can list it, move it or delete it, and it is deliberately kept rather than dropped because a repair that brings the release back brings the placement back with it. Until now there was nowhere to clean one up. Sidecars are listed too, with the same classification applied to them: a real file in a folder nothing accounts for any more — an `.nfo` beside a release that has left the library, or inside a placement that has been forgotten — is shown as **orphaned** and counted apart from the rest. Nothing is swept, for the reason a dangling row is not: the file is still yours, and a repair that brings the release back accounts for the folder again. Deleting one there really deletes the file, exactly as a `DELETE` through the mount does. Every one of those buttons tells the mount to forget the listings it changed, because it caches a directory for twelve hours with polling off.

`magic:` and `sabnzbd:` are both editable from the config page now, and both are marked **Restart Required** because they mean it: the routes that serve `__magic__` and the SABnzbd endpoint are decided once, at startup, out of exactly these values. Turning one on writes it to `config.yml` and changes nothing about the run that answered — and the `__magic__` page says so in as many words rather than rendering an empty namespace as though everything were fine.

### Sonarr and Radarr can now hand zurg an NZB

The reason `__magic__` exists is so an \*arr has somewhere to import from, and zurg now speaks the other half of that: an endpoint at `/api` that answers Sonarr and Radarr as though it were a SABnzbd. Point them at zurg's host and port, paste the API key, and grabs land in `nzbs/` for the Usenet backend. Once the release is in the library the job reports Completed with a folder under `__magic__`, and the import is a rename inside the mount — one row in the table, no bytes read, nothing pulled down from Usenet to put it in a series folder.

```yaml
sabnzbd:
  enabled: true
  api_key: ""          # left empty, zurg generates one and logs it once
  categories: [tv, movies]
  complete_dir: ""     # defaults to <mount_path>/__magic__; set it to what a containerised *arr sees
```

Off by default, and it needs both halves to be useful: an `nzb` provider to read the NZB, and `magic.enabled` to have anywhere to import from. The endpoint is not behind zurg's basic auth, because neither \*arr ever sends any to a download client and their HTTP layer reads a 401 as "unable to connect" — the API key is the whole gate, so treat that port accordingly. Root folders go **inside** `__magic__` (`__magic__/tv`, `__magic__/movies`), never at it or above it, or the clients' root-folder health check has something to say.

One thing to know before switching a library over: **the failure signal is partial**. A release the library holds but nothing importable in — every file broken, deleted or filtered away, or nothing there but repair scaffolding and sidecars, which is what an NZB of only recovery volumes is — is reported `Failed`, which is what makes both clients blocklist it and grab an alternative. A RAR set counts as content, since zurg streams the video straight out of it — unless it is one zurg cannot stream at all, holding nothing but compressed entries, which is reported Failed from the moment something has opened it and found that out. That verdict is kept with the release, because learning it costs a read of every volume in the set. What is not reported is a post whose articles have aged off the news server: zurg does not check that yet, so a dead release reports Completed like any other and fails on the first read, and Sonarr sees an import failure rather than a download failure. That one is still a manual call. Everything else in the flow works, including the post-import cleanup: the job folder Sonarr deletes becomes a tombstone and the release stays in `__all__`.

A grab does not wait for the next change poll: zurg re-reads the watch directory as soon as it has written into it, and only the Usenet accounts — a season pack is twenty grabs in a few seconds, and re-listing a debrid library of tens of thousands of torrents to notice a local file would be twenty times the wrong work. If no `nzb` provider is configured at all, zurg now says so at startup rather than accepting grabs nothing will ever read.

The `__magic__` page lists the jobs, read-only: the `nzo_id` each client knows a grab by, its category, when it arrived, whether the library lists the release yet, and — once it does — the folder the \*arr imports from.

Full setup, including remote path mapping for containerised \*arrs and what each connection-test error means, is in `docs/sabnzbd.md`.

## The mount reaches more of the bandwidth it has

Reading a file through the rclone mount was slower than fetching the same bytes over HTTP, and the reason was how a read starts rather than how it runs. The first chunk was requested at 4 MB and doubled from there, so a read that began at a cold offset spent most of its life below the speed the connection could actually carry — and every seek starts a fresh read. The first chunk is now requested at 32 MB.

Measured on a host with about 70 MB/s of usable download bandwidth, with each setting sampled in turn so a slow minute could not land on just one of them: median mount throughput on Real-Debrid went from 49 to 57 MB/s, and TorBox moved the same way. AllDebrid gains less here because its limit is per connection rather than per account.

Chunk size is the whole of the effect — the FUSE read-ahead was raised alongside it in testing and changed nothing. It also costs no extra bandwidth: the chunk size is how much is *asked* for, not how much is transferred, and rclone stops pulling when playback stops. A 4 MB read still fetched 6 MB, the same as with read-ahead switched off entirely, so a library that is browsed and sampled rather than watched end to end downloads no more than before.

Nothing to change — the new value ships as the default, and `rclone_extra_args` still overrides it.

## `zurg benchmark-my-setup` answers how fast the setup actually is

Until now the only way to know whether a slow stream was the account, the host, or the mount was to guess. The new command reads real bytes over the same path a player uses and reports the distribution — min, median, average, max, and time to first byte — rather than one figure that any single unlucky sample could have produced.

It runs three phases. Each account on its own, which is the number to hold against what the service promises. Then every configured account at the same time, which is the only phase that can tell a slow provider from a saturated uplink: accounts that each sustain 70 MiB/s alone but 25 MiB/s together are one bottleneck, not three problems, and the report says which of the two it is looking at. Then the same read through the rclone mount, where the gap against the first phase is what FUSE and the VFS cost. The mount phase is skipped when `rclone_enabled` is off.

Samples are placed at random offsets, and that is not a detail. Every layer underneath caches — rclone's VFS keeps what it has fetched, a debrid CDN edge keeps what it has served — so re-reading one offset measures those caches instead of the link. On a live setup the same file reported 47 MiB/s cold and 285 MiB/s on the second read of the same region.

Sample size changes what the mount figure means, so the report says so. rclone opens a file at `vfs_read_chunk_size` and doubles from there, so a short sample spends most of its life still ramping: measured on one setup, 47 MiB/s at a 256 MiB sample against 88 MiB/s at 1 GiB, with HTTP steady at ~70 either way. The default 128 MiB is the seek-and-scrub number; `--sample-mb 1024` is the sustained ceiling. Neither is wrong, and the run tells you which one you just took.

`-n` sets iterations, `--provider` restricts the run to named accounts, `--skip-mount` and `--skip-concurrent` drop a phase, and `--json` emits the report for scripting. It spends real bandwidth from the operator's own accounts — iterations x sample size per account, twice, plus the mount phase. Run it from the zurg directory: the NZB backend reads its `nzbs/` folder relative to the working directory, and an account that lists nothing is reported as that rather than as an account with no large files.

## Working Real-Debrid releases are no longer marked broken after a link check

Since the nightly of 2026-08-20, a healthy library could fill the log with `Link verification failed during refresh` and `keeping files as broken`, each one carrying a `404 Not Found` and `invalid_download_code` against a download host. Nothing was actually wrong with the releases.

That nightly added a tidy-up for the rows Real-Debrid mints in My Downloads: every link zurg verifies creates one, and left alone the list grows by a row per torrent per cold build until startup is paging tens of thousands of them. The tidy-up deletes those rows in the background, on the understanding that a row and the URL it minted are separate things.

They are not. Deleting the row revokes the download code, and the only thing that keeps it alive is a host that has already fetched it — measured 2026-08-22, a code minted on `124-4` and fetched once through `44-4` still answered `200` on `44-4` while both `124-4` and an untouched `125-4` answered `404 invalid_download_code`. zurg picks the download host per request, from the fastest few, so the host that verified a link is rarely the host that asks for it next. The resolution stayed cached for four hours, and every request against it in that window came back `404` — read as a link that had rotted, and the release marked broken.

A resolution now leaves the link cache at the moment its row is queued for deletion, so nothing replays a URL that is on its way out; the next request resolves a fresh one. The rows are still cleaned up. Releases wrongly marked broken recover on the next refresh — nothing to re-add or re-scan.

## Shows named by air date are filed as shows, not movies

A programme with no season and episode numbers is named by the date it aired instead — `WWE SmackDown 2026-08-21`, and every daily and late-night show after it. Nothing in the episode test knew that convention. It looked for `S01E01`, for a season or episode number written out, for an anime release's hash, and failing all of those it looked for a run of numbered files to read as a sequence. A daily release is a single file carrying a single date, so the answer was no, and the release fell through to the first directory that would take it — in most configurations, movies.

The air date now counts as the marker it is, written `2026-08-21`, `2026.08.21`, `2026 08 21`, `2026_08_21` or `20260821`. Only real dates qualify: the month has to be one of twelve and the day one of thirty-one, so a year sitting beside a resolution — `Movie.2026.05.1080p` — is never read as one. Measured against a 6755-release library, no film changes directory; measured against 4734 real daily-show releases, 4633 are now recognised. The rest are older scene names that abbreviate the year to two digits or put it last, which cannot be told apart from an audio channel layout with any confidence worth having.

A library already on disk re-files itself at startup, so the next restart is enough — nothing to re-scan or re-import.
