# Local debrid libraries and portable zurgtorrents

A local library takes its membership from portable `.zurgtorrent` files. It
appears in the normal WebDAV, HTTP and provider directories. Importing files,
listing them and refreshing the catalog do not add torrents or resolve download
links. Playback resolves the requested file through your configured account.

## Export a library

From the exporting instance's working directory:

```sh
./zurg --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```

`--provider` is the configured account **name**, including a custom name. Omit
it to export all supported debrid copies. The input can also be one runtime
cache file, a legacy `dump/` directory, or an existing portable catalog.
For a local library, export its source directory (`torrents/<account>`), which
preserves its optional references to other providers.

Export is offline. It validates all inputs and destination collisions before
writing, reports and skips runtime entries without selected file metadata, merges releases by hash, and writes `<hash>.zurgtorrent`. Existing
identical exports are safe to repeat. For a bulk migration containing malformed
legacy cache entries, `--skip-invalid` exports the valid entries and reports how
many were omitted. Without it, the first invalid entry aborts before any writes. `--replace` permits replacing a portable
export of the same hash; it never authorizes overwriting a runtime cache.

Only the exported files are intended for sharing. `data/*.zurgtorrent` remains
private runtime state. A `.zurgbackup` also contains account credentials and is
an instance backup, not a shareable library.

## Receive a library

Put the exported files in `torrents/rd-local/`, then configure the receiving
account:

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: YOUR_OWN_TOKEN
    download_tokens: # Optional bandwidth fallback on another RD account.
      - SECOND_RD_TOKEN
    library:
      source: local
      # Optional; defaults to torrents/<account-name>.
      path: torrents/rd-local

  - name: tb-online
    type: torbox
    token: YOUR_OWN_TORBOX_TOKEN
    # Omitted library block means the provider owns this account's catalog.
```

On Real-Debrid and AllDebrid, `download_tokens` uses the same local catalog as
its provider entry. The second RD account above needs no directory, and its
torrent library is not imported.
These are fallback credentials used when the active download token's bandwidth
allowance is exhausted; they do not force every download through the second
account. Adding a second RD entry under `providers` instead creates a separate
catalog with its own directory. All credentials remain in the config and are
excluded from portable exports.

TorBox also accepts `download_tokens`, but its token rotation does not map the
stored torrent/file IDs to IDs on the other account. Use separate TorBox
provider entries for separate accounts, each with its own local catalog.

Premiumize, Offcloud and Debrid-Link accounts can hold a local library too. None of them has a
portable file reference. So like TorBox each one adds the hash to its own account on first
playback and matches the files by path and size. Use one provider entry per account.

Restart after changing account configuration. File additions, replacements and
removals are picked up by the normal refresh loop. Each directory is scanned
one level deep. Paths must be distinct directories below `torrents/`, so normal
backups include them. An unreadable directory or invalid replacement retains
the last valid in-memory entry and logs the problem. After restarting, an
invalid file must be fixed before it can enter the catalog.

The same manifest can be copied into an AllDebrid or TorBox account's local
directory. It contains content identity, not a provider account name. The same
hash across accounts appears once with several sources, using the existing
account preference and failover order. Duplicate files for a hash within one
directory use the first filename in sorted order; keep one manifest per hash.

Local catalog membership survives removal from the provider's online library.
Renames, tags, IMDb IDs and file deletions are saved back into the manifests.
Removing a local release removes its source documents; it does not delete
provider torrents. Removing a release with online copies also deletes those
online copies, as the normal whole-release delete does.

Local accounts are not targets for watchlists, magnet uploads or torrent-file
uploads. Add entries by importing manifests. `add_torrents: false` still lets
RD/AD redeem an existing shared reference but prevents playback from creating a
provider-side attachment when one is needed.

## What travels in the file

The versioned JSON format has `format: "zurgtorrent"` and numeric `version: 1`.
It carries the infohash, release names, added timestamp, rename, tags, IMDb ID,
and selected file paths, sizes and optional renames. References are optional:

| Provider | Portable reference | Playback |
|---|---|---|
| Real-Debrid | Canonical 13-character `https://real-debrid.com/d/...` | Resolve with the recipient's credentials and download IP. |
| AllDebrid | Locked `https://alldebrid.com/f/...` | Unlock with the recipient's credentials. |
| TorBox | Hash and file paths/sizes | Obtain a recipient-side torrent on first playback and match its files by path and size. |
| Premiumize, Offcloud, Debrid-Link | Hash and file paths/sizes | Add the hash on the recipient's account on first playback and match its files by path and size. |

No account names, credentials, provider torrent/file IDs, CDN URLs, MediaInfo
input URLs, Plex IDs, repair state or deletion queues are exported. The importer
rejects unknown fields and credential-bearing or unexpected reference URLs.
It does not fetch URLs while validating a manifest. Usenet keeps its `.nzb`
source format; NZB runtime caches cannot be exported as portable torrents.

## Playback and limits

Local tracking changes who owns the catalog. It does not guarantee that a
provider still has the bytes or can serve them. Account access, allowed network
locations, active slots, quotas and rate limits still apply.

RD and AD use shared locked references when present. Hash-only manifests, and
an RD reference the API definitively reports missing, can establish content on
the recipient's account. TorBox always needs that account attachment and first reuses a matching torrent already on the recipient account. Adds use
the existing provider pacing and are serialized per account. An add waits for a free
slot when the account reports its slot count or zurg knows it. AllDebrid, Premiumize and
Offcloud report none, so the add goes ahead and a full account refuses it. An uncertain add is held for 30 minutes before another attempt; a
preparing torrent is checked only when playback is requested again.

Recipient IDs and resolved native file handles stay privately in
`data/local-torrents/`. That record survives a restart and is included in normal
backups. Zurg never deletes those attachments automatically: an idempotent add
may have returned a torrent the recipient already owned. Provider failures
leave the local entry visible and back off rather than starting background
repair or repeating an add for every scan.

Local archive releases list their source volumes without automatic extraction
or background inspection. An explicit path inside an archive can still invoke
the archive reader. Automatic MediaInfo probing and next-file prefetch are
suppressed on entries with local copies.

## Migrate an old dump

Export `dump/` with the command above, put the results in the receiving
account's `torrents/<name>/` directory and enable `library.source: local`.
Turn off `load_dumped_torrents` after migration. The old opt-in `__dump__`
reader remains for compatibility; new local libraries do not use it. Runtime
caches lacking an account type need to be re-exported from an instance that
knows their provider before they can be shared.

Backups written by this build use format 2 to include the new durable roots.
The restore command still reads format 1 backups. Older builds refuse format 2
rather than silently dropping a local library.
