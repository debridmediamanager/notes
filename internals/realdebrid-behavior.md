---
label: Real-Debrid API notes
icon: note
order: 20
---

# Torrents

Real-debrid supports downloading unlimited number of torrent files and magnet links, also selecting which files in it that you want to download
If the torrent file or magnet link is already downloaded by another user, it is considered "cached" and Real-Debrid provides you the cached link already
If not, it will try to download the magnet link from public trackers or DHT/PEX
If it's a torrent file containing tracker info then it will use those tracker info which is useful for private trackers (unfortunately a lot of private trackers block real-debrid download servers)
If the torrent no longer have seeders or leechers and it's impossible to download all pieces of the torrent, then it will encounter an error
Once downloaded you will also get cached links that looks like https://real-debrid.com/d/DOWNLOADCODE
DOWNLOADCODE is exactly a 13 char unique ID of the specific file (anything after the 13th character is ignored)

# Selecting files

As mentioned, it is possible to select files that you only want to download inside a torrent
If a torrent contains files A B and C and you select A and B, it will only download A and B
The cached status of a torrent actually depends on this unique file selection
Going back to the torrent containing files A B and C, there are different cached status for A or B or B (single), A+B, B+C, A+C (pair), or A+B+C (all files)
Each unique selection redownloads the torrent again from trackers and returns a different cached link even if for the same file

# Cached Links

Cached links are non downloadable links and actually just serves as container for DOWNLOAD CODES in real-debrid
you will have to "unrestrict" or convert it to an actual downloadable or streamable link from real-debrid which expires after 7 days
Cached links last more than 7 days and if a torrent has working cached links (meaning it can be unrestricted successfully) that means it is still cached in real-debrid
It is not known but highly likely that the cache status of a torrent can be extended if more users unrestrict a cached link

Take note that the only way to verify if a cached link is working is by unrestricting it and checking the first byte of the unrestricted link using http Range header
Zurg supports both HEAD (default, fast) and Range-based (GET bytes=0-0, more thorough) verification via the use_range_verification config option

# Cached link sharing across accounts (measured 2026-08-19)

RD returns link IDs in two lengths, 13 chars (~70%) and 16 chars (~30%), and the extra 3 chars change WHO can unrestrict the link:
- Truncated to the first 13 chars, a /d/ link unrestricts from ANY premium account — not just the one that generated it. The caller's torrent library is untouched; the only side effect is an entry in the caller's downloads history.
- Sent with its full 16-char ID, the same link unrestricts ONLY from the generating account. Every other account gets "unavailable_file", even while the generating torrent is alive, even if the caller holds the same infohash in their own library, and regardless of the ip parameter.
So always truncate to 13 chars before unrestricting a stored link. Testing with untruncated IDs falsely "proves" that link sharing is impossible.

Cached links survive the generating account deleting its torrent — but they die of age. Sampled at scale: links minted 1-2 months ago all still unrestricted cross-account; links older than ~3 months all returned "hoster_unavailable". Separately, RD can evict the content itself from its cache (a hash proven cached one month can be downloading-from-0-seeders the next); then the link returns "unavailable_file" for everyone, including the generating account.

Decoding an unrestrict error on a stored cached link:
- 13-char link + hoster_unavailable  -> the link aged out; re-adding the torrent with the same selection mints fresh links (see repairing below)
- 13-char link + unavailable_file    -> RD evicted the content entirely; fresh links require a real re-download from seeders
- 16-char link + unavailable_file    -> says nothing about availability: you are simply not the generating account; truncate and retry

Unrestricted links (the *.download host URLs) are IP-bound by server-side tracking, not by refusal:
the CDN happily serves a foreign IP with a 206, but real-debrid records download IPs and multi-IP use
of one account's links earns an account-sharing warning. Pass the downloader's IP to unrestrict/link
(the ip parameter) so the link is minted for the IP that will pull the bytes.

# Repairing broken cached links

Sometimes a cached link or even the unrestricted link of a file inside a torrent is no longer working
This can be because of a unrestrict api error or the unrestricted link returns an HTTP error response
To fix this we have to re-download a torrent and generate new or fresh cached links
You can try redownloading the torrent with the same exact file selection, see if it generates new or fresh cached links
If that doesn't work, that means you have to do a different file selection on that torrent
For example, if only one file is broken in a torrent containing multiple files, then select just that broken file
If still returns a broken cached link, try adding another file into the selection
You do that until you get a fresh working cached link

# RAR behavior

Real-Debrid has this behavior of storing torrents in RAR files (no compression) if you select a non supported file type that cannot be streamed
Confirmed video file types: .avi .flv .m2ts .m4v .mkv .mov .mp4 .mpg .mpeg .ts .webm .wmv
Confirmed audio file types: .mp3 .flac .m4a
These file types when selected in real-debrid results to individual file links that are streamable
If you select anything else then it is guaranteed that real-debrid will store it in a RAR archive
If you select a .mkv video and a .sub subtitle then it will be rar'ed
Same if you select just the .jpg poster it will be rar'ed

A torrent, even with multiple files, if rar'ed will return just a single cached link (which points to the rar file)
If you only select confirmed video/audio file types, then it won't be rar'ed and you will get a cached link for each file you selected

# Deleting a downloads-list row revokes the URL it minted

Measured 2026-08-22 against the test account, one unrestrict per case.

An unrestrict mints a row in /downloads and a URL on one numbered host, e.g.
https://124-4.download.real-debrid.com/d/<13-char code>/<filename>. The code
is not host-scoped: before the row is deleted, the same code answers 200 on
44-4, 125-4 and its own 124-4 alike. The trailing filename segment is optional
throughout; zurg strips it and both forms answer identically.

DELETE /downloads/delete/<id> revokes that code, and what survives is decided
by which hosts have already served it:

  - Row deleted with the URL never fetched: every host answers 404 with
    X-Error: invalid_download_code. Still 404 30s later — it does not settle.
  - Row deleted after one fetch through 44-4: 44-4 keeps answering 200, while
    the minting host 124-4 and an untouched 125-4 both answer 404
    invalid_download_code.

So a fetch activates the code on the host that served it, and the row is what
keeps every other host serving. This is the opposite of the assumption the
downloads-list cleanup was written on, and it matters because zurg chooses the
download host per request (ensureReachableDownloadServer rewrites to one of the
N fastest hosts): the host a verification HEAD landed on is not the host the
next request picks. A resolution left in the link cache after its row is
deleted therefore answers 404 invalid_download_code on almost every later
request, which reads as a rotted link and marks a healthy release broken.

Re-unrestricting the same link after a delete is unaffected: it mints a new id
on a new host and works normally. Ids are not reused.
