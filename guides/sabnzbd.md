---
label: Sonarr & Radarr
icon: arrow-switch
order: 80
---

# Pointing Sonarr and Radarr at zurg

zurg can answer Sonarr and Radarr as though it were a SABnzbd. They hand it an NZB, it writes the file into `nzbs/` for the Usenet backend, and once the release is in the library the job reports **Completed** with a folder under `__magic__` to import from. The import is a rename inside the mount — a row in the `__magic__` table — so nothing is downloaded to import and nothing is copied.

This is the Usenet half only. SABnzbd carries NZBs and nothing else; a torrent equivalent would be a different API and is not implemented.

## What it needs

Three things, and it is worth checking all three before configuring anything in the \*arr:

1. **An `nzb` provider**, so there is somewhere for the NZB to go and something to read it. See [usenet.md](usenet.md).
2. **`magic.enabled: true`**, so there is somewhere to import from. Without it the completed directory does not exist and every import fails. zurg says so at startup. See [magic.md](magic.md) for what that namespace is and why an import into it costs nothing.
3. **The mount visible to the \*arr**, at the path zurg reports. See [Remote path mapping](#remote-path-mapping) if the \*arr runs in a container.

## Configuring zurg

```yaml
sabnzbd:
  enabled: true
  api_key: ""          # left empty, zurg generates one and logs it
  categories: [tv, movies]
  complete_dir: ""     # defaults to <mount_path>/__magic__
```

With `api_key` empty, zurg generates a key on first start, writes it to `data/sabnzbd-apikey` so it survives restarts, and logs it once:

```
SABnzbd: generated API key 2f0c… — paste it into Sonarr or Radarr, or pin it as sabnzbd.api_key in config.yml
```

The endpoint answers at `/api` and at `/sabnzbd/api` on zurg's normal port, and **it is not behind zurg's basic auth**. Neither \*arr ever sends basic auth to a download client, and their HTTP layer treats a 401 as "unable to connect" with nothing actionable in it — so the API key is the whole gate. Treat the endpoint the way you treat the rest of zurg's port: on a trusted network, or behind something that is.

## Configuring Sonarr and Radarr

**Settings → Download Clients → + → SABnzbd**

| Field | Value |
|---|---|
| Host | the host zurg runs on |
| Port | zurg's port (`9999` by default) |
| URL Base | leave empty (or `/sabnzbd`; both work) |
| API Key | the key from above |
| Username / Password | leave empty — the API key and these are mutually exclusive, and only the key is accepted |
| Category | `tv` in Sonarr, `movies` in Radarr, matching `sabnzbd.categories` |
| Use SSL | only if zurg is behind TLS |

Then **Test**. A green tick means all four of the client's checks passed: the version, the API key, the global config and the category.

**Settings → Media Management → Root Folders → Add**

Make the folder first, on the mount, then add it:

```bash
mkdir -p /mnt/zurg/__magic__/tv
mkdir -p /mnt/zurg/__magic__/movies
```

Add `/mnt/zurg/__magic__/tv` to Sonarr and `/mnt/zurg/__magic__/movies` to Radarr.

The root folder must be **inside** `__magic__`, not `__magic__` itself and not `/mnt/zurg`. Both clients warn when a root folder *is* the download client's output folder, and Radarr also warns when a root folder *contains* it — `/mnt/zurg` contains `__magic__`, so pointing a root folder there raises a health check on every start. A root folder inside the output folder is the one arrangement neither complains about, and it is also where an import naturally lands.

## What happens on a grab

1. Sonarr grabs a release and POSTs the NZB to `/api?mode=addfile`. zurg sanitises the filename, writes `nzbs/<name>.nzb`, and answers with an `nzo_id`.
2. The file is never renamed afterwards. The Usenet backend derives a release's identity from the NZB's filename, so a rename would orphan the release and every placement made out of it.
3. zurg asks the library to re-read the watch directory immediately, rather than waiting for the next change poll. The re-read is scoped to the Usenet accounts — nothing else could have changed — and a burst of grabs costs two passes, not one per grab.
4. Until the library lists the release, the job is in `mode=queue` as **Queued**. Sonarr shows it in Activity → Queue.
5. Once the library lists it, the job moves to `mode=history` as **Completed**, with `storage` pointing at `<complete_dir>/<the release's folder name>`.
6. Sonarr imports: it walks into that folder through the mount, finds the episode, and **moves** it to the series folder under the root folder. That move is a `MOVE` under `__magic__`, which rewrites one row. No bytes are read.
7. Sonarr then deletes the job folder and calls `mode=history&name=delete`. The folder delete becomes a `__magic__` tombstone — the release stays in `__all__` and in every filter directory — and the job record goes.

The folder name is read off the library at every poll, so renaming the release in zurg's dashboard, a repair that rebuilds it, or the suffix zurg adds when two releases share a name all move the job with them.

## What works, and what does not

Works:

- The connection test, all four checks, in both clients.
- Grabbing, queue, history, import by rename, and the post-import cleanup.
- Re-grabbing the same release: the job id is derived from the NZB's filename, so it names the same job rather than a second one.
- Removing a job from the queue, with or without deleting the NZB.
- `mode=addurl`, for a human or an automation that passes a URL instead of uploading. Neither \*arr uses it.

Does not, and the first one matters most:

- **The failure signal is partial.** A release the library holds but nothing importable in — every file broken, deleted, or filtered away, or nothing there but repair scaffolding and sidecars, which is what an NZB of nothing but recovery volumes is — is reported **Failed** with a `fail_message`, and both clients blocklist it and grab an alternative. A RAR set is content, not scaffolding: zurg streams the video out of it, and the PAR2 volumes posted beside it change nothing — unless it is an archive zurg cannot stream at all, one of nothing but compressed entries, which is reported Failed once something has opened it and found that out. What is *not* checked is whether the articles are still on the news server: a dead post reports **Completed** like any other and fails on the first read of the file, which Sonarr sees as an import failure rather than a download failure, so it neither blocklists nor re-grabs. Until that lands, a release that will not play is one to blocklist by hand. (The mechanism is designed and the seam is already there: `STAT` the first and last article of each file at add time, and report `Release.Listable` false — the same field the empty-release case uses.)
- **No progress.** A job is queued or it is completed; there is no percentage in between, because there is no download to measure. The queue reports the NZB's own declared size so the entry is not blank.
- **No pause, no resume, no speed limits, no priorities, no post-processing scripts.** SABnzbd has all of these and zurg has nothing to apply them to.
- **`del_files` on a history delete is ignored.** Sonarr sends it after every successful import, meaning "the job folder is yours again" — but on zurg the file it just imported is still served out of that NZB, and deleting it would take away the thing that was imported. The folder the client wanted gone is gone: it deleted that itself, through the mount.
- **Basic auth cannot be used for this endpoint.** See above.

## Remote path mapping

If the \*arr runs in a container that mounts the library somewhere other than zurg does, the path zurg reports is not a path the \*arr can open — and every import fails with "download doesn't contain intermediate path" or a remote-path health check.

Two ways to fix it, and either is fine:

- **Set `sabnzbd.complete_dir`** to the path *the \*arr* sees. This is the simpler one when a single \*arr, or several that agree, mount the library at the same place:

  ```yaml
  sabnzbd:
    complete_dir: "/data/zurg/__magic__"
  ```

- **Add a remote path mapping** in the \*arr (Settings → Download Clients → Remote Path Mappings), from zurg's host and its `/mnt/zurg/__magic__` to whatever the container sees. Use this when different clients mount it differently.

Whichever you choose, the folder must exist and be listable where the \*arr runs. It does not need to be writable for the health check to pass — but the import itself writes, so in practice it must be.

### Bind the mount's parent, not the mountpoint

A containerised \*arr needs one more thing, and it does not go wrong until the first time zurg restarts. Restarting zurg unmounts `/mnt/zurg` and mounts it again, and a container that bound **the mountpoint itself** keeps the fuse connection it was started with — which is now dead. Every read in the container then answers `Socket not connected`, and because Sonarr and Radarr check free space on the root folder before they grab, *every release is rejected*:

```
FreeSpaceSpecification: Socket not connected
```

Nothing in either client says the mount is stale, the folder still appears in the container, and an interactive grab pushed straight at the client still works — so what it looks like is an \*arr that has quietly stopped searching.

Bind the **parent** of the mountpoint with `rslave`, and the remount arrives as a sub-mount event the container follows:

```yaml
    volumes:
      - type: bind
        source: /mnt          # the parent, not /mnt/zurg
        target: /mnt
        bind:
          propagation: rslave
```

The same rule, in the other direction, is why zurg's own container binds a parent with `rshared` — see [docker.md](../setup/docker.md#mount-is-empty). To check a container after a zurg restart:

```bash
docker exec sonarr df -h /mnt/zurg     # a size, not "Socket not connected"
```

## Watching it from the dashboard

zurg's [`__magic__` page](../reference/config.md#the-__magic__-page) at `/magic/` lists every NZB the endpoint has been handed: the `nzo_id` the client knows it by, the name it was grabbed under, its category, when it arrived, and whether the library lists the release yet — which is exactly what separates a **Queued** job from a **Completed** one. Once it is completed, the release's folder name is shown, which is the folder the \*arr imports from.

The list is read-only. A job is removed by the client that created it, and the record is kept for a week after that so a poll racing the delete answers the same way twice. The same page is where the placements those imports created are visible, and where one can be reset.

## Troubleshooting

| What the \*arr says | What it means |
|---|---|
| "Unable to connect to SABnzbd" | zurg is not reachable at that host and port, or something in front of it answered a non-200. Check that `sabnzbd.enabled` is true — while it is off, `/api` is a plain 404. |
| "API Key Incorrect" / "API Key Required" | The key does not match. It is in `config.yml` if you set one, and in `data/sabnzbd-apikey` if zurg generated it. |
| "Test was aborted due to an error" | Something other than an authentication failure. zurg logs every request it refused; look for `SABnzbd:` in the log. |
| "Category ... does not exist" (a warning) | The category configured in the \*arr is not in `sabnzbd.categories`. Add it — the categories all resolve to the same directory, so the list exists only to satisfy this check. |
| "Downloads in root folder" (a health check) | A root folder is at or above `__magic__`. Move it inside — `__magic__/tv`, not `__magic__` and not `/mnt/zurg`. |
| "Remote path mapping" / "download doesn't contain intermediate path" | See [Remote path mapping](#remote-path-mapping). |
| A job sits queued forever | The release never appeared in the library. Check that the NZB parsed — zurg logs `Loaded NZB <name>: N files` — and that the `nzb` provider is configured; with none, zurg says so at startup and nothing will ever read what the endpoint writes. |
| A job reports Failed with "The release arrived with no files that can be read" | The library holds the release but there is nothing in it to import — every file broken, deleted, or filtered away, or nothing there but `.par2`, `.sfv` and sidecars. An NZB of nothing but recovery volumes is exactly this. |

## Files it touches

| Path | What it is |
|---|---|
| `nzbs/<name>.nzb` | The NZB itself, named once and never renamed. |
| `data/sabnzbd-jobs.json` | Which NZBs were grabbed, under which category, and when. Written whole on every change. |
| `data/sabnzbd-apikey` | A generated API key, so it survives a restart. Not written when `sabnzbd.api_key` is set. |

The exact shapes zurg answers with, and why each one is what it is, are recorded in [sabnzbd-client-contract.md](../internals/sabnzbd-client-contract.md) — read that before changing a field name. What the imports land in is [magic.md](magic.md).
