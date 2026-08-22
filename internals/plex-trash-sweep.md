---
label: Plex trash sweep
icon: trash
order: 60
---

# Aligning the Plex trash sweep with zurg's own file status

## Purpose of this document

The Plex trash sweep currently decides what to remove from a Plex library using
**file absence plus an age timer**. zurg already knows something far better —
whether the content behind that file is repairable or permanently dead — and does
not consult it.

This document is the plan for replacing the timer with that knowledge. It exists
to be reviewed **before** any code is written, because the change decides what
gets deleted from a media library and the current behaviour is wrong in both
directions: it waits two weeks to remove content that is known dead on day one,
and it deletes content that zurg is still actively repairing.

It records what was verified in the code and on a live library, what is being
proposed, and what is deliberately left alone. Everything stated as fact below was
checked against the running system on 2026-08-16, not inferred from naming.

Scope: `internal/plexsweep`, `internal/plexdb`, and a new read-only query into
`internal/torrent`. No change to repair behaviour itself.

---

## 1. Background — what shipped, and why it needs revisiting

Four commits landed the sweep:

| Commit | What |
|---|---|
| `4737b677` | Warn when Plex's `autoEmptyTrash` is on |
| `020042a3` | The sweeper: detection, guards, repair, per-item removal |
| `51cc9f69` | Dashboard config UI and documentation |
| `1a481a8f` | Count repairs against the cap, not just removals |
| `c6f41621` | `plex_trash_sweep_min_age_days`, default 14 |

The sweep's governing invariant is unchanged and stays: **nothing that still has a
file is ever removed.** Items with a live file are repaired, or left alone with
their trash icon. Shows and seasons with live episodes are never touched. Removal
is per item, never Plex's section-wide `emptyTrash`.

What is being revisited is only the rule for *when a genuinely-absent entry may be
removed*.

### The timer is a proxy for a question zurg can answer directly

`plex_trash_sweep_min_age_days` waits 14 days before removing an entry, on the
reasoning that the red trash icon is the only notice an operator gets that content
went missing, and purging the entry destroys that notice.

The intent is right; the mechanism is a guess. It is wrong in both directions:

- A torrent marked `infringing torrent` is **known dead immediately**. Making its
  Plex entry linger a fortnight helps nobody — waiting cannot bring it back.
- A torrent still being retried may take **longer than 14 days** to come back. The
  timer deletes its entry while zurg is still working on it. This is the worse
  error, because it destroys a library entry for content that then returns.

---

## 2. Verified facts

### 2.1 zurg's state model

Three file states and two torrent states exist (counted across
`internal/torrent`, excluding tests):

| Level | States |
|---|---|
| `File.State` | `ok_file`, `broken_file`, `deleted_file` |
| `Torrent.State` | `ok_torrent`, `broken_torrent` |

Both are `pkg/fsm` machines. `FSMWithTime` records the unix timestamp of each
transition and supports `SinceWhen`, so "how long has this been broken" is already
answerable without adding anything.

**One broken file condemns the whole torrent.**
`MarkFileBrokenAndEnqueueRepair` (`internal/torrent/hooks.go:215-234`):

```go
changed := file.State.Set("broken_file", torrent.State.GetMutex()) == nil
...
if err := torrent.State.Set("broken_torrent"); err == nil {
    t.repairLog.Infof("Torrent state changed: %s [? -> broken_torrent] (has broken file)", ...)
}
```

The log says *"has broken file"*, singular. One of ten broken and ten of ten broken
produce an identical torrent state. Nothing aggregates the file states.

**`Unfixable` aggregates over accounts, not files.**
`markAsUnrepairable` (`internal/torrent/unplayable_unrepairable.go:44-71`):

```go
if cp != nil {
    cp.SetUnrepairableReasonIfEmpty(reason)      // one account's copy
    entryCondemned = t.repairableCopy(torrent) == nil
}
if entryCondemned {
    torrent.SetUnrepairableReasonIfEmpty(reason) // the entry
}
```

The entry is condemned when **no repair-capable copy remains**. Deliberately not
"every copy carries a reason" — a copy that could never be repaired anyway (the
Usenet backend has no magnet adder) would otherwise keep a dead release eligible
for repair forever. `File` carries no unrepairable field at all
(`internal/torrent/file_types.go`).

So the three levels answer three different questions, and **none of them answers
scope**:

| Level | Tells you | Cannot tell you |
|---|---|---|
| `File.State` | this file is ok / broken / deleted | whether it is permanently dead |
| `TorrentCopy.UnrepairableReason` | this account's copy is dead | anything about other accounts |
| `Torrent.UnrepairableReason` | no account can repair this | how much of the release is affected |

### 2.2 Live measurements (fun, 2026-08-16)

zurg library: **6,339 torrents — 6,141 `ok_torrent`, 198 `broken_torrent`.**

Of the 198 broken, **195 carry an `Unfixable` reason**:

| Reason | Count |
|---|---|
| stalled download | 76 |
| infringing torrent | 74 |
| repair failed | 30 |
| duplicate file IDs (pack torrent) | 7 |
| rar'ed by RD | 2 |
| repair failed, no seeders | 2 |
| the lone cached file is broken | 1 |
| invalid file ids | 1 |
| repair failed, download status: error | 1 |
| provider cannot re-add torrents | 1 |

**3 are broken without a reason** — still repairable.

**But `Unfixable` is not the same as dead.** zurg already sorts these reasons into
permanent and recoverable (`internal/torrent/unrepairable_reasons.go:44-70`).
`permanentReasons` holds nine verdicts no retry can change — infringing,
unsupported, unavailable, invalid, too big, not allowed, no repairable files, no
seeders, invalid file ids — plus any reason prefixed `repair failed, download
status:`. Everything else, including the two largest buckets above, is explicitly
temporary: `stalled download`, `repair failed`, `duplicate file IDs`,
`rar'ed by RD`, `not cached`, `the lone cached file is broken`,
`full torrent repair failed`.

Applying that split to the counts above:

| | Count |
|---|---|
| Permanently unrepairable | **78** |
| Unrepairable but recoverable | **117** |
| Broken, no reason yet | 3 |

An unrecognised reason (`provider cannot re-add torrents`, 1 here) is in neither
list, and `IsPermanentlyUnrepairable` returns false for it — the conservative
answer, which is the one we want.

This is the single most important finding for the design: **a rule keyed on
"`Unfixable` is set" would remove Plex entries for 195 releases, when only 78 are
actually dead.**

Crucially, where those broken torrents sit relative to the mount:

| | Count | What Plex sees |
|---|---|---|
| Broken, **still on the mount** | 148 | File appears to exist → never tombstoned. No trash icon; it fails only on playback |
| Broken, **gone from the mount** | 50 | File missing → tombstoned → **these are the sweep's candidates** |

This is the key measurement. It means the sweep only ever meets the second group,
and for that group zurg usually already holds a verdict.

Plex side, same host: 1,122 trashed leaves, of which **0** are past the 14-day
window (oldest tombstone 2026-08-11). Plus 4 empty show shells and 38 empty season
shells.

---

## 3. The gap

`broken_torrent` means "at least one thing is wrong". That is the wrong
granularity for the sweep.

Concretely: a ten-episode pack where one episode's file is permanently gone, but
the torrent stays repairable overall. Asking the torrent gives "still repairable",
so the sweep would keep that dead episode's Plex entry **forever**.

There is no state meaning *"this entire release is dead"* as distinct from
*"something in this release is broken"*.

---

## 4. Design

### 4.1 Do not add a fourth persisted state

The obvious move is a new torrent state — `dead_torrent`, or similar. **Rejected.**

Every site that transitions a torrent would have to maintain it, and a stale
"all files broken" flag is worse than no flag at all, because it *authorises
removals*. The information already exists in the file states; it simply is not
aggregated.

Instead, derive it:

```go
// AllFilesBroken reports whether nothing in this release still reads.
// Derived from the file states rather than stored, so it cannot go stale
// and needs no migration or new transitions.
func (t *Torrent) AllFilesBroken() bool
```

Cheap, always consistent, and surfaceable in the dashboard without persistence.

Definition to settle during implementation: `deleted_file` must count as
not-reading alongside `broken_file`, and a torrent with **zero** files must return
false rather than vacuously true — an empty release is not evidence of death.

### 4.2 Ask the file, fall back to the torrent

The sweep resolves a Plex path to a zurg file, then applies:

| zurg's verdict | Sweep |
|---|---|
| file is `ok_file` | **keep** — it is not really gone |
| `broken_file`, torrent has no unrepairable reason | **keep** — repair may restore it, however long that takes |
| `broken_file`, reason set but **not** permanent | **keep** — zurg still considers it recoverable |
| `broken_file`, reason is **permanently** unrepairable | **remove** — no retry can change this verdict |
| zurg has no torrent for this path | **fall back to the age window** |

The permanence test is `IsPermanentlyUnrepairable(reason)`
(`internal/torrent/unrepairable_reasons.go:59`), used exactly as `ForceRepairTorrent`
uses it. Reusing it rather than re-deriving a list matters: a reason added to
`permanentReasons` later must change the sweep's behaviour automatically, and an
unrecognised reason must stay non-permanent.

`AllFilesBroken()` does **not** authorise removal on its own — a wholly broken
release with a recoverable reason is still being worked on. It refines reporting
and the dashboard, and distinguishes "one episode of ten is gone" from "the whole
pack is gone" for a human reading the log.

The last row is why `plex_trash_sweep_min_age_days` stays. Once a torrent is gone
from the account entirely its `.zurgtorrent` goes with it, and zurg has no opinion
left to offer. The timer stops being the primary rule and becomes the fallback for
exactly the case where nothing better exists.

This also demotes the setting in the UI, which resolves the separate complaint
that its label ("Keep Broken Entries Visible") describes a side effect rather than
the action.

### 4.3 Path → torrent → file lookup

The existing Plex matcher goes the *other* way: `buildPlexDirIndex`
(`internal/plex/matcher.go:539`) indexes Plex path components and looks them up by
torrent key. The sweep needs the inverse, built from the same idea:

1. Build `map[strings.ToLower(GetKey(torrent))] *Torrent` from
   `DirectoryMap.Get(INT_ALL)`.
2. For a Plex path, split into components with the same normalisation as
   `splitPathComponents` (`matcher.go:525`) and look each up. The release
   directory is the component that hits.
3. Within that torrent, match the remaining path tail against `File.Path`
   (`internal/debrid/types.go:133`) to reach the specific file.

Reasons this must go through `TorrentManager` and not string-match
`data/*.zurgtorrent`: disambiguated names (`Some.Release {a1b2c3}`), multi-account
copies, and renames all resolve correctly only through `GetKey`.

**A failed lookup is not a licence to delete.** Unresolvable → treat as "zurg has
no opinion" → age-window fallback.

### 4.4 What does not change

- The invariant: nothing with a live file is removed.
- Shows and seasons with live descendants are never touched.
- Per-item `DELETE`, never `emptyTrash`.
- Guards: rclone managed and running, mount reads, Plex not scanning.
- Snapshot before any change; caps over repairs *and* removals.

The new rules only ever make the sweep **more** conservative or **more** precise —
they never authorise a removal the current code would refuse.

---

## 5. Implementation plan

| # | Step | Files |
|---|---|---|
| 0 | Confirm the permanent/recoverable split is the right gate with a dry-run count against a live library before anything deletes | — |
| 1 | `AllFilesBroken()` + unit tests (empty release, mixed, all broken, all deleted) | `internal/torrent/` |
| 2 | Read-only status lookup: path → torrent → file, returning a small verdict value | new file in `internal/torrent/` or `internal/plexsweep/` |
| 3 | Define the verdict type (`StatusOK`, `StatusRecoverable`, `StatusPermanentlyDead`, `StatusUnknown`) so the sweep never handles zurg internals directly | `internal/plexsweep` |
| 4 | Wire the lookup into `Sweeper` behind an interface, as `Mount`/`Library`/`Trash` already are | `internal/plexsweep/sweep.go` |
| 5 | Apply the decision table; keep the age window as the `StatusUnknown` fallback | `internal/plexsweep/sweep.go` |
| 6 | Inject the `TorrentManager` at the call site | `internal/app.go` |
| 7 | Tests: one per row of the decision table, plus a lookup-failure test proving unresolvable never removes | `internal/plexsweep/sweep_test.go` |
| 8 | Docs: `docs/config.md`, `config.example.yml`, `docs/CHANGELOG.md`, and re-word the dashboard label | docs + templates |

Ordering note: steps 1–3 are pure additions with no behaviour change and can land
as one commit; step 5 is the only one that changes what gets deleted.

---

## 6. Risks and open questions

1. **Wiring order.** Confirmed: `startPlexTrashSweep` is called at
   `internal/app.go:268`, and `TorrentManager` is constructed at
   `internal/app.go:285` — after it. The call must move after it, or take a setter. Needs
   checking that nothing else depends on the current position.
2. **Lookup ambiguity.** Two torrents whose keys collide with the same path
   component. Resolution: if more than one candidate matches, treat as
   `StatusUnknown` rather than picking one.
3. **`only_show_the_biggest_file`.** The movies directory hides files, so a Plex
   path may name a file that is not the one zurg would serve. The lookup must not
   assume the Plex filename appears in `File.Path` verbatim.
4. **Cost.** Building the key index on every sweep is O(library). At 6,339
   torrents that is trivial, and the sweep runs daily. Build per sweep, not per
   item.
5. ~~**Does `Unfixable` ever clear?**~~ **Resolved: yes.**
   `refresh.go:851-857` clears it when a torrent verifies clean and returns to
   `ok_torrent` ("all links intact, no broken files"), and `repair.go:165-181`
   clears it — entry and every copy — when a repair is forced. So a recovered
   release does not carry a stale condemnation, and the design does not need to
   defend against one.
6. **The 148 broken-but-present torrents.** Out of scope here: Plex never
   tombstones them, so the sweep never sees them. Worth noting that they are
   invisible to both Plex and this feature until playback fails.

---

## 7. How it was implemented (2026-08-16)

Landed as `feat: decide plex trash sweep removals from zurg's repair verdicts`.
Where the implementation settled a question this document left open, or departed
from §4, the decision and its reason:

- **The lookup matches the path's parent directory exactly** against
  `DirectoryMap[INT_ALL]`, instead of scanning every path component (§4.3). The
  mount lays a release out flat — `<library dir>/<key>/<visible name>` — and
  Plex recorded the path from the mount, which serves the key verbatim. An
  exact miss answers unknown, and the key-collision ambiguity (risk 2)
  disappears: exact keys cannot collide.
- **Row 1 of the decision table changed.** An `ok_file` that is nonetheless
  absent from the mount is a file the filters hide, not "not really gone" —
  keeping it forever would leave a permanent trash icon after a filter change.
  It falls back to the age window instead.
- **`deleted_file` counts alongside `broken_file`** in every rule, not just in
  `AllFilesBroken()` — the table's rows read "not `ok_file`".
- **Multi-version items are judged as a unit** (the table was per-file, the
  sweep's unit is a Plex item with parts): one recoverable part keeps the whole
  item; the item is dead only when every part is; any other mix falls to the
  age window.
- **A filename that resolves to a torrent but not to a file** (rename, archive
  listing, `only_show_the_biggest_file` — risk 3) is dead only when the entry's
  reason is permanent **and** `AllFilesBroken()`; recoverable when the torrent
  is broken without a permanent verdict; otherwise unknown. An unmatched name
  is never condemned by association while any file still reads.
- **Wiring (risk 1):** `startPlexTrashSweep` moved below the manager's
  construction in `internal/app.go`; nothing depended on its old position. The
  verdicts reach the sweep behind `plexsweep.Verdicts`, implemented by
  `TorrentManager.FileStatusForMountPath`. Before the first refresh populates
  `INT_ALL`, every lookup answers unknown and the sweep behaves exactly as the
  age-window version did.

## 8. Explicitly out of scope

- **Empty show and season shells.** The sweep removes leaves only, so a fully-dead
  show leaves a husk (4 shows, 38 seasons on fun today). Real, separate, needs
  ordering care: remove leaves, re-check the parent, remove only at zero children.
- Any change to repair behaviour, the repair queue, or when zurg marks something
  unrepairable.
- Plex's own `autoEmptyTrash`, already handled by the warning in `4737b677`.
- fun's existing 1,122-entry backlog, deliberately left for a manual decision.
