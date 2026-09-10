---
label: Persistent caches
icon: database
order: 85
---

# Persistent read caches

Imported NZBs, Real-Debrid, AllDebrid and TorBox entries all retain their library
state in `data/*.zurgtorrent`. These files describe the library. Read preparation
and byte caches live beside them so changing or evicting a derived cache does not
rewrite the library or lose tags, names and account associations.

## What survives a restart

| Cache | Location | Work avoided |
| --- | --- | --- |
| NZB document manifests | `data/nzb-manifests/` | Parsing unchanged XML for names, sizes, recovery classification, passwords and segment counts |
| NZB article indexes | `data/nzb-index/` | Rebuilding article references; used by both `mmap` and `resident` modes |
| Decoded Usenet articles | `data/bytecache/articles/` | Fetching and yEnc-decoding an article already read |
| Archive layouts | `data/archive-layouts/` | Re-reading archive headers to rebuild volume spans, nested entries and learned ZIP offsets |
| Decompressed archive blocks | `data/bytecache/decoded/` | Decoding again to reach retained byte ranges after a restart or backward seek |
| Provider state | `data/provider-cache/` | Rebuilding an unchanged RD downloads window or fetching a fresh TorBox region table |
| Delivery links | `data/linkcache/` | Resolving a still-valid URL again |

Archive layouts support stored and compressed RAR/ZIP entries, nested sources,
encrypted spans and supported split archives. They hold source references and
offsets, not live HTTP readers. Current provider URLs are attached on restore.
Incomplete layouts with missing volumes are rebuilt from source. Learned ZIP
payload offsets are persisted after the first read without eagerly fetching a
header for every entry during a directory listing.

NZB manifests are checked against the source file's size, nanosecond modification
time and parser version. `mmap` restores metadata immediately and maps the article
index when needed. `resident` loads that index into heap memory. `reparse` restores
metadata immediately but still parses XML when article references are needed.
Existing libraries build manifests during their first scan with this version;
the startup saving applies on subsequent scans and restarts.

AllDebrid and TorBox concurrent requests for the same uncached account/file now
share one resolution. Canceling one caller does not cancel another caller's
resolution. RD retains its existing coalescing. TorBox uses known catalog names
and sizes when resolving a file instead of fetching those details again.

Provider detail records in `data/info/` are memoized after the first JSON decode
per process. Every reuse checks file identity, size and modification time and
returns an independent copy. Library and detail files are replaced atomically.

## Storage budgets

These optional top-level settings are measured in MiB and take effect after a
restart:

```yaml
nzb_article_disk_cache_mb: 512
archive_decoded_disk_cache_mb: 512
```

Each cache defaults to 512 MiB across the instance. Zero disables that cache;
negative values are treated as zero. The budgets cover record bytes including
checksums, rather than filesystem allocation overhead. Oldest unused records are
evicted as new records arrive. Reducing a budget trims the existing cache during
initialization. Disabling it leaves existing files available for manual removal.

The article cache supplements the existing RAM cache. The archive cache retains
64 KiB decoded blocks and supplements each decoder's 64 MiB rolling RAM window.
Neither cache pre-downloads the library. A read outside retained decoded blocks
still needs decoding from the beginning of a compressed entry. Rclone's VFS cache
is separate and continues to serve complete cached ranges without entering these
paths; these caches also benefit direct HTTP/WebDAV reads.

Derived metadata grows with the library and is separate from these byte budgets.
NZB scans remove manifests and article indexes for removed documents. Obsolete
archive layout revisions can be removed with the instance stopped; they are
disposable and will be rebuilt when needed.

## Validation and recovery

New metadata records and byte blobs carry checksums. Damaged records and failed
cache writes fall back to the source. Article records only enter the disk cache
after a successful complete fetch, and are written after the article has been
handed to the read that fetched it, so a read never waits for the cache. A burst
offering more article writes than run at once drops the extra records instead of
holding a read up; a dropped record is fetched again when it is next wanted. Article identity includes the NZB revision,
server configuration, file and segment; archive identity includes the current
source references, sizes, account configuration, password and format version.
NZB source replacement invalidates archive layouts and decoded bytes as well.

The local source fingerprint assumes a replacement changes size or modification
time. It deliberately avoids hashing the entire XML on every startup. Preserving
both on a replacement requires removing the associated derived caches.

RD snapshots are accepted only for the same token and configured download limit,
within one hour, after a live probe agrees on the newest entry and total count.
A changed list triggers a full reconciliation. TorBox region tables retain their
existing six-hour lifetime. Delivery URL lifetimes and provider failure handling
are unchanged: a warm layout opens its payload before committing HTTP success,
allowing a revoked URL to take the normal resolution/retry path.

Delivery link mutations trigger a coalesced disk flush after approximately one
second. The five-minute retry and shutdown flush remain. Atomic replacement
prevents readers from observing partially written records; it is not an fsync
guarantee against power loss. New cache files use mode `0600` on Unix because
links and encrypted archive layouts can carry credentials or derived keys.
Windows uses the containing directory's ACLs instead of Unix permission bits.

## Backups with warm caches

The default backup still stores the authoritative state. To include the derived
caches and the instance-local rclone VFS cache:

```sh
./zurg backup --include-caches --out warm.zurgbackup
```

This can be much larger than a standard backup. It includes the roots listed
above, NZB naming/sizing/PAR2 caches and network-test state. Logs and Plex database
snapshots remain excluded. Rclone caches outside `data/rclone-cache/` are not
included. Stop the instance when a consistent snapshot of active caches matters.

Restore with the instance stopped using `./zurg restore-backup warm.zurgbackup`.
Backups preserve nanosecond source timestamps so unchanged NZBs can retain their
indexes and manifests. Restored caches still undergo normal validation and expiry
checks. Backups contain the config's tokens and cached credentials.

## Reproducible checks

`BenchmarkParsedDocumentStartup` compares XML parsing with each manifest restore
mode using 60 files and 30,000 segments. `BenchmarkDetailJSONRefresh` compares the
JSON read path with memoized access for a 1,000-file record. Both are local warm
filesystem benchmarks, not end-to-end production startup measurements.

Measured on an Apple M3 Pro with three 500 ms runs on 2026-09-05 (median per
operation):

| Operation | Time | Allocated bytes |
| --- | ---: | ---: |
| Parse the NZB XML | 43.49 ms | 20.27 MB |
| Restore metadata in `mmap` mode | 0.224 ms | 59 KB |
| Restore metadata and resident article index | 0.577 ms | 1.79 MB |
| Restore metadata in `reparse` mode | 0.199 ms | 59 KB |
| Read/decode a provider detail record | 0.538 ms | 784 KB |
| Reuse the detail record with a stat check and copy | 0.0084 ms | 59 KB |

The detail decode case clears the new memo before each call and includes its
population cost. These figures compare the two current access paths; they do
not estimate network latency or project a whole-library boot time.

Regression tests exercise restart reuse, corruption, source changes, account
isolation, concurrent resolution, byte identity at the beginning/middle/end,
backward seeks beyond the RAM window and URL revocation after layout restoration.

```sh
go test ./...
go test -race ./internal/debrid ./internal/nzb ./internal/rarstream ./internal/universal ./pkg/cachefile ./pkg/diskcache
go test ./internal/nzb ./internal/torrent -run '^$' -bench 'Benchmark(ParsedDocumentStartup|DetailJSONRefresh)$' -benchmem
make integration-test
```

The integration target requires its documented live test accounts and host
dependencies. A skipped integration script does not verify a cache change.
