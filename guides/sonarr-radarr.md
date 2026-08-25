---
label: Sonarr & Radarr
icon: arrow-switch
order: 80
---

# Sonarr and Radarr, step by step

Point Sonarr and Radarr at zurg and they grab from Usenet without a Usenet client — no download, no unpack, no disk. Every step below, with the screen you should be looking at.

Everything below was captured against zurg `nightly-993-g99bcf9a4`, Sonarr `4.0.19.2979` and Radarr `6.3.0.10514`, on a live install with a real Usenet account. Host and user names have been changed to `yowmamasita@zurg-server`; nothing else in the captured output was altered, and API keys shown are illustrative.

## Before you start

Three things have to be true. Check all three now — every one of them fails later as something that looks unrelated.

1. **zurg has an `nzb` provider.** Without one there is nothing to read what the endpoint writes, and every job sits queued for ever. zurg says so at startup. See [Usenet](usenet.md).
2. **`magic.enabled` is `true`.** Without it the completed directory does not exist and every import fails. See [`__magic__`](magic.md).
3. **The mount is visible to the \*arr** at the path zurg reports. If Sonarr runs in a container, read [step 8](#8-if-your-arr-is-in-docker) before you configure anything.

Check the first two straight out of the config file, in zurg's working directory:

```bash
$ grep -A6 '^providers:' config.yml
providers:
- type: nzb
  nntp:
    host: news.eweka.nl
    port: 563
    tls: true
    username: <redacted>
    password: <redacted>

$ grep -A4 '^magic:' config.yml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

`allow_delete: false` is the safe default and does not affect imports — a delete inside `__magic__` hides the entry rather than removing content from the account.

## 1. Turn the endpoint on

Two ways, same result. Both write to `config.yml` and both need a restart: the routes that serve `__magic__` and the SABnzbd endpoint are registered once, when zurg starts.

### Option A — the dashboard

Open zurg's dashboard, click **Config**, and scroll to **\_\_magic\_\_ & Download Clients**. Turn on **Serve \_\_magic\_\_** and **SABnzbd Endpoint**, then set **SABnzbd Categories** to `tv, movies`.

![The zurg dashboard's Quick Links](../assets/sonarr-radarr/44-zurg-dashboard-home.webp)

**Config** is where the setting lives; **Magic** is where you will watch grabs arrive later.

![The __magic__ and download clients block on the config page](../assets/sonarr-radarr/40-zurg-config-magic-sabnzbd.webp)

Leave **SABnzbd Completed Directory** empty unless your \*arr mounts zurg somewhere other than zurg does — see [step 8](#8-if-your-arr-is-in-docker). The orange **Restart Required** chip is telling the truth: nothing here takes effect until zurg restarts.

### Option B — `config.yml`

Add the block by hand and restart zurg.

```yaml
magic:
  enabled: true

sabnzbd:
  enabled: true
  api_key: ""          # empty = zurg generates one and keeps it
  categories: [tv, movies]
  complete_dir: ""     # empty = <mount_path>/__magic__
```

**The categories are not folders.** They all resolve to the same place — a job's folder is the release's own folder under `__magic__`. The list exists only so Sonarr and Radarr stop warning about a category they cannot find. If Sonarr's category is `tv`, `tv` must be in this list.

Restart zurg, then confirm the provider took:

![The providers block on the zurg config page](../assets/sonarr-radarr/43-zurg-config-providers.webp)

One `nzb` row is all the endpoint needs.

## 2. Find the API key

The API key is the entire authentication on this endpoint, so get it right once and don't paste it anywhere public.

**If you left `api_key` empty**, zurg generated one on first start, wrote it to `data/sabnzbd-apikey`, and logged it once:

```bash
$ cat data/sabnzbd-apikey
a7f3c81e94d6b25f0c8e3a71d495b6e2

$ journalctl -u zurg-usenet | grep 'generated API key'
SABnzbd: generated API key a7f3c81e… — paste it into Sonarr or Radarr,
or pin it as sabnzbd.api_key in config.yml
```

Illustrative key — yours will differ. The file survives restarts, so the key is stable once generated.

**If you set `api_key` yourself**, it is in `config.yml` and no file is written. The dashboard tells you which of the two you are in, at the bottom of the block in step 1 — it reads either *pinned in config.yml under `sabnzbd.api_key`* or *generated and kept in `data/sabnzbd-apikey`*.

**This endpoint is outside zurg's basic auth.** Neither Sonarr nor Radarr ever sends basic auth to a download client, and their HTTP layer turns a 401 into "unable to connect" with nothing actionable in it — so zurg deliberately exempts `/api`. The API key is the whole gate. Treat the port the way you treat the rest of zurg's: on a trusted network, or behind something that is.

## 3. Prove it answers

Do this before touching Sonarr. It takes ten seconds and it separates "zurg is wrong" from "the \*arr is wrong" for the rest of the setup.

```bash
$ SAB=a7f3c81e94d6b25f0c8e3a71d495b6e2
$ ZURG=192.168.88.245:9996

$ curl -s "http://$ZURG/api?mode=version&apikey=$SAB&output=json"
{"version":"4.5.1"}

$ curl -s "http://$ZURG/api?mode=get_config&apikey=$SAB&output=json" \
    | jq '.config.misc.complete_dir, [.config.categories[].name]'
"/mnt/zurg_usenet/__magic__"
[ "*", "tv", "movies" ]
```

`complete_dir` is the path zurg will hand the clients — check now that it is a path *they* can open.

Then check that a wrong key is actually refused:

```bash
$ curl -s "http://$ZURG/api?mode=queue&apikey=wrongkey&output=json"
{"status":false,"error":"API Key Incorrect"}

$ curl -s "http://$ZURG/api?mode=queue&output=json"
{"status":false,"error":"API Key Required"}
```

**`mode=version` is not an authentication test.** It answers `{"version":"4.5.1"}` even with a wrong key — that is how real SABnzbd behaves, and zurg copies it. Use `mode=queue` or `mode=get_config` when what you actually want to test is the key.

Both URL shapes work, so either is fine in the client's **URL Base** field:

| Path | URL Base in Sonarr / Radarr | Answers |
|---|---|---|
| `/api` | *(leave empty)* | yes |
| `/sabnzbd/api` | `/sabnzbd` | yes |

If `/api` returns a plain **404**, `sabnzbd.enabled` is still false or zurg has not been restarted since you changed it.

## 4. Make the root folders

Make them before you add them, because the \*arr's Add Root Folder dialog browses the live filesystem and will not offer a folder that does not exist.

```bash
$ mkdir -p /mnt/zurg_usenet/__magic__/tv /mnt/zurg_usenet/__magic__/movies

$ ls -d /mnt/zurg_usenet/__magic__/tv /mnt/zurg_usenet/__magic__/movies
/mnt/zurg_usenet/__magic__/movies
/mnt/zurg_usenet/__magic__/tv
```

Substitute your own `mount_path` for `/mnt/zurg_usenet`. The folder names are yours to choose; `tv` and `movies` just match the categories.

**The root folder must be inside `__magic__`, not at it and not above it.** Use `__magic__/tv`. **Not** `__magic__` itself and **not** `/mnt/zurg_usenet`. Both clients raise a health check when a root folder *is* the download client's output folder, and Radarr also raises one when a root folder *contains* it. A root folder one level inside the output folder is the single arrangement neither complains about — and it is where an import naturally lands anyway.

This is what getting it wrong looks like. Both are real, from the two clients:

![Sonarr health check warning about a root folder at __magic__](../assets/sonarr-radarr/30-sonarr-health-rootfolder-warning.webp)

Sonarr with `/mnt/zurg_usenet/__magic__` added as a root folder — it warns because the root folder *is* the output folder.

![Radarr health check warning about a root folder above __magic__](../assets/sonarr-radarr/31-radarr-health-rootfolder-warning.webp)

Radarr with `/mnt/zurg_usenet` added — it warns for the parent too, which Sonarr does not. Move the root folder inside `__magic__` and both warnings go.

## 5. Add the client in Sonarr

A brand-new Sonarr blocks everything behind a first-run screen. Pick **Forms (Login Page)**, set a username and password, and click **Save**.

![Sonarr's first-run authentication screen](../assets/sonarr-radarr/01-sonarr-firstrun-auth.webp)

It will not let you past until **Authentication Method** is something other than None.

![The same screen filled in](../assets/sonarr-radarr/02-sonarr-firstrun-auth-filled.webp)

After Save you are signed out once and land on the login page.

![Sonarr's login page](../assets/sonarr-radarr/04-sonarr-login.webp)

### Settings → Download Clients

Go to **Settings → Download Clients**. On a fresh install there is nothing here but the **+** card.

![Sonarr's empty download clients page](../assets/sonarr-radarr/05-sonarr-downloadclients-empty.webp)

Click the **+** under "Download Clients" — not the one further down under "Remote Path Mappings".

Choose **SABnzbd** from the **Usenet** column.

![The add download client picker with SABnzbd visible](../assets/sonarr-radarr/06-sonarr-add-client-picker.webp)

zurg impersonates SABnzbd specifically, so nothing else in this list will work.

The dialog opens with SABnzbd's own defaults — `localhost`, port `8080`, no key.

![The untouched SABnzbd download client dialog](../assets/sonarr-radarr/07-sonarr-sab-dialog-empty.webp)

### What to put in each field

| Field | Value | Why |
|---|---|---|
| Name | `zurg (Usenet)` | Anything. It is only a label. |
| Enable | on | Leave it checked. |
| Host | `192.168.88.245` | The host zurg runs on, as *the \*arr* can reach it. In Docker, see the warning below. |
| Port | `9996` | zurg's normal port — `9999` on a default install. |
| Use SSL | off | Only if you put zurg behind TLS yourself. |
| API Key | from step 2 | The whole gate. |
| Username | empty | Mutually exclusive with the key. Only the key is accepted. |
| Password | empty | Same. |
| Category | `tv` | Must appear in `sabnzbd.categories`. |
| Recent / Older Priority | Default | zurg has nothing to apply a priority to. |
| Remove Completed | on | Lets the client clean up its own job records. Leave it on. |
| Remove Failed | on | Same. |

![The SABnzbd dialog filled in](../assets/sonarr-radarr/08-sonarr-sab-dialog-filled.webp)

The API key shown is illustrative — paste your own.

**In Docker, "localhost" and the hostname both lie.** Inside a container, `localhost` is the container, and the machine's own hostname usually resolves to `127.0.1.1` — which is also the container. Use the host's **LAN or Tailscale IP**, never `localhost` and never the bare hostname, even when both work fine from your shell.

Click **Test**. A green tick means all four of the client's checks passed: version, API key, global config, and the category.

![The dialog footer showing a successful test](../assets/sonarr-radarr/09-sonarr-sab-test-ok.webp)

Now click **Save**.

![The saved download client card in Sonarr](../assets/sonarr-radarr/10-sonarr-downloadclient-saved.webp)

## 6. Add the root folder in Sonarr

Go to **Settings → Media Management** and scroll to the bottom.

![The empty root folders section in Sonarr](../assets/sonarr-radarr/11-sonarr-rootfolders-empty.webp)

Click **Add Root Folder**. A file browser opens on the container's filesystem.

![Sonarr's file browser at the filesystem root](../assets/sonarr-radarr/12-sonarr-rootfolder-dialog.webp)

Type the path into the box at the top. If the mount is genuinely visible to Sonarr, the releases inside `__magic__` appear as you type — which is the fastest proof you will get that the bind mount is correct.

![The file browser listing releases inside __magic__](../assets/sonarr-radarr/13-sonarr-rootfolder-browse.webp)

If this is empty or errors, stop and fix the mount before going further.

![The path finished at __magic__/tv](../assets/sonarr-radarr/14-sonarr-rootfolder-typed.webp)

Finish the path at `__magic__/tv` and click **Ok**.

![The root folder added, showing free space and unmapped folders](../assets/sonarr-radarr/15-sonarr-rootfolder-added.webp)

**Free Space** reading a plausible number means Sonarr can stat the mount; **Unmapped Folders** counts releases already sitting there.

## 7. Do the same in Radarr

Identical, with two values changed: the category is `movies` and the root folder is `__magic__/movies`.

![Radarr's login page](../assets/sonarr-radarr/20-radarr-login.webp)

Radarr's first run works the same way — set Forms auth, then sign in.

![Radarr's add download client picker](../assets/sonarr-radarr/21-radarr-add-client-picker.webp)

**Settings → Download Clients → +**, then **SABnzbd** under Usenet.

![Radarr's SABnzbd dialog filled in with the movies category](../assets/sonarr-radarr/22-radarr-sab-dialog-filled.webp)

Same host, same port, same key. Only **Category** differs — `movies`, not `tv`.

![Radarr's dialog footer showing a successful test](../assets/sonarr-radarr/23-radarr-sab-test-ok.webp)

**Test**, green tick, **Save**.

![The saved download client card in Radarr](../assets/sonarr-radarr/24-radarr-downloadclient-saved.webp)

Then **Settings → Media Management → Root Folders → Add Root Folder**, and add `/mnt/zurg_usenet/__magic__/movies`.

**One zurg, two clients, one queue.** zurg's queue and history are filtered by category and nothing else. Two Sonarrs both using `tv` will see each other's jobs; Sonarr on `tv` and Radarr on `movies` will not. Keep one client per category and this never comes up.

## 8. If your \*arr is in Docker

Two separate problems, and the second one does not bite until the first time zurg restarts.

### The path zurg reports must be a path the client can open

If the container mounts the library somewhere other than zurg does, every import fails with *download doesn't contain intermediate path* or a remote-path health check. Fix it either way — both are fine:

- **Set `sabnzbd.complete_dir`** to the path *the client* sees. Simplest when one client, or several that agree, mount the library at the same place.
- **Add a remote path mapping** in the \*arr. Use this when different clients mount it differently.

```yaml
sabnzbd:
  complete_dir: "/data/zurg/__magic__"   # what the *arr sees, not what zurg sees
```

For the second, go to **Settings → Download Clients** and use the **+** under **Remote Path Mappings** — the lower one on the page, not the one you used in step 5.

![The add remote path mapping dialog](../assets/sonarr-radarr/16-sonarr-remote-path-mapping.webp)

**Host** must be exactly the host string you typed into the download client. **Remote Path** is what zurg reports; **Local Path** is where the client sees it.

### Bind the mount's parent, not the mountpoint

This is the one that costs an afternoon. Restarting zurg unmounts `/mnt/zurg_usenet` and mounts it again. A container that bound **the mountpoint itself** keeps the fuse connection it was started with — which is now dead. Every read then answers `Socket not connected`, and because both clients check free space on the root folder before they grab, *every release is silently rejected*:

```
FreeSpaceSpecification: Socket not connected
```

Nothing in either client says the mount is stale, the folder still appears inside the container, and an interactive grab pushed straight at the client still works. What it looks like is an \*arr that has quietly stopped searching.

Bind the **parent** with `rslave`, and the remount arrives as a sub-mount event the container follows:

```yaml
    volumes:
      - type: bind
        source: /mnt          # the parent, not /mnt/zurg_usenet
        target: /mnt
        bind:
          propagation: rslave
```

Check a container after any zurg restart. You want a size, not an error:

```bash
$ docker exec radarr df -h /mnt/zurg_usenet
Filesystem      Size  Used Avail Use% Mounted on
zurg{PGSq4}:    1.0P     0  1.0P   0% /mnt/zurg_usenet
```

The petabyte is zurg reporting a virtual filesystem, not a disk — that is expected, and it is what satisfies the \*arr's free-space check.

## 9. Watch one grab go through

Add one thing, grab it by hand, and follow it the whole way. Everything below is a real grab through the setup above.

### Grab it

Open a movie (or an episode), click **Interactive Search**, and pick a release.

![Radarr's interactive search results](../assets/sonarr-radarr/60-radarr-interactive-search.webp)

The **Source** column reads `nzb` — that is the protocol zurg can take.

Click the circled-arrow button at the end of the row to grab it. If the release does not match cleanly, the client asks you to confirm the mapping first:

![Radarr's Override and Grab dialog](../assets/sonarr-radarr/60b-radarr-override-and-grab.webp)

**Override and Grab** appears when the client wants you to confirm what the release is. Check the mapping and click **Grab Release**. A normal automatic grab never shows this.

### It lands in the queue

![Radarr's queue immediately after the grab](../assets/sonarr-radarr/61-radarr-queue-01.webp)

**Activity → Queue** immediately after the grab. Note the progress bar: it is full, and **Time Left** is a dash. There is no download to measure, so a job is queued or completed and nothing in between. *The other rows here belong to a second Radarr pointed at the same zurg on the same category* — see the note in step 7.

### zurg writes the NZB and reads it

```
Aug 25 14:44:03 zurg-server zurg[3034965]: INFO  nzb  Loaded NZB
  Last.Week.Tonight.with.John.Oliver.S13E22.480p.WEB.x264-RMTeam.nzb: 4 files
Aug 25 14:50:28 zurg-server zurg[3034965]: INFO  nzb  Loaded NZB
  Untold.The.Testimony.of.Vince.Young.2026.1080p.NF.WEB-DL.DD+5.1.Atmos.H.264-playWEB.nzb: 9 files
```

`Loaded NZB … : N files` is the line that says the NZB parsed. If a job sits queued for ever, this line is what is missing.

### The import happens

![Radarr's history showing Grabbed then Movie Imported](../assets/sonarr-radarr/62-radarr-history.webp)

**Activity → History**. Two events, seconds apart: **Grabbed**, then **Movie Imported**.

![The Radarr movie page showing Downloaded status](../assets/sonarr-radarr/63-radarr-movie-imported.webp)

**Status: Downloaded**, **Size 4.7 GiB** — and nothing was downloaded.

### Prove the file is real

The import moved the file into the root folder. Read both ends of it and ask ffprobe what it is:

```bash
$ ls -la "/mnt/zurg_usenet/__magic__/movies/Untold - The Testimony of Vince Young (2026)/"
-rw-r--r-- 1 yowmamasita yowmamasita 4920958828 Aug 25 14:53 Untold.The.Testimony…playWEB.mkv

$ dd if="$F" bs=1M count=1 >/dev/null
1048576 bytes (1.0 MB, 1.0 MiB) copied, 0.0429446 s, 24.4 MB/s

$ ffprobe -v error -show_entries format=duration,size,format_name \
    -of default=noprint_wrappers=1 "$F"
format_name=matroska,webm
duration=4709.440000
size=4920958828
```

A 78-minute Matroska, streamed out of Usenet articles on demand. The bytes arrive when something reads them, not when the \*arr imports.

## Watching from zurg's side

zurg's `/magic/` page lists every NZB the endpoint has ever been handed. It is read-only — a job is removed by the client that created it, and the record is kept for a week after that so a poll racing a delete answers the same way twice.

![The __magic__ page header showing placements and tombstones](../assets/sonarr-radarr/41-zurg-magic-header.webp)

**Placements** are files the clients moved; **tombstones** are the job folders they deleted afterwards. A rising **sidecars** number is the warning sign: it means a client is copying rather than moving.

![The SABnzbd jobs table on the __magic__ page](../assets/sonarr-radarr/42-zurg-magic-sabnzbd-jobs.webp)

**State** is the whole story — **Queued** means the library has not listed the release yet, **Completed** means it has, and **Release** names the folder the client imports from.

That **Release** column is read off the library at every poll, not stored. Rename the release in zurg's dashboard, let a repair rebuild it, or let zurg add a suffix because two releases share a name — the job follows it.

## What works, and what does not

Works:

- The connection test, all four checks, in both clients.
- Grabbing, queue, history, import by rename, and the post-import cleanup.
- Re-grabbing the same release. The job id comes from the NZB's filename, so it names the same job rather than a second one.
- Removing a job from the queue, with or without deleting the NZB.
- `mode=addurl`, for a human or an automation passing a URL instead of uploading. Neither \*arr uses it.

Does not:

- **No progress.** A job is queued or completed; there is no percentage between, because there is no download to measure. The queue reports the NZB's declared size so the row is not blank.
- **No pause, resume, speed limit, priority or post-processing script.** SABnzbd has all of these; zurg has nothing to apply them to.
- **`del_files` on a history delete is ignored.** The client means "the job folder is yours again", but the file it just imported is still served out of that NZB. The folder it wanted gone is gone — it deleted that itself, through the mount.
- **Basic auth cannot protect this endpoint.** The API key is the only gate.

**The failure signal is partial.** A release with nothing importable in it — every file broken, deleted or filtered away, or nothing but `.par2`, `.sfv` and sidecars — is reported **Failed**, and both clients blocklist it and grab an alternative. A RAR set is content, not scaffolding: zurg streams the video straight out of it.

What is *not* checked is whether the articles still exist on your news server. A dead post reports **Completed** like any other and fails on the first read, which Sonarr sees as an *import* failure rather than a *download* failure — so it neither blocklists nor re-grabs. Until that lands, a release that will not play is one to blocklist by hand.

## Troubleshooting

| What the \*arr says | What it means |
|---|---|
| "Unable to connect to SABnzbd" | zurg is not reachable at that host and port, or something in front of it answered a non-200. Check `sabnzbd.enabled` — while it is off, `/api` is a plain 404. In Docker, check you did not use `localhost` or the bare hostname. |
| "API Key Incorrect" / "API Key Required" | The key does not match. It is in `config.yml` if you set one, in `data/sabnzbd-apikey` if zurg generated it. |
| "Test was aborted due to an error" | Something other than an authentication failure. zurg logs every request it refused — grep the log for `SABnzbd:`. |
| "Category … does not exist" | The category in the \*arr is not in `sabnzbd.categories`. Add it and restart zurg. |
| "Downloads in root folder" | A root folder is at or above `__magic__`. Move it inside — `__magic__/tv`, not `__magic__` and not `/mnt/zurg_usenet`. |
| "Remote path mapping" / "download doesn't contain intermediate path" | The path zurg reports is not a path the client can open. See [step 8](#8-if-your-arr-is-in-docker). |
| Every release rejected, nothing in the log | A stale bind mount. Run `docker exec <client> df -h <mount>`; if it says `Socket not connected`, bind the parent with `rslave` and recreate the container. |
| A job stays queued for a poll or two after the release appears | Expected, and it settles once per release. An NZB does not state how long a file is; the estimate is being replaced by the exact length from the PAR2 index or one article's own header. Reporting Completed early is what makes the client throw *File move incomplete, data loss may have occurred*. |
| A job sits queued for ever | The release never appeared in the library. Check that the NZB parsed — `Loaded NZB <name>: N files` in the log — and that the `nzb` provider is configured at all. |
| "The release arrived with no files that can be read" | The library holds the release but there is nothing importable in it. An NZB of nothing but recovery volumes is exactly this. |

### Where the state lives

| Path | What it is |
|---|---|
| `nzbs/<name>.nzb` | The NZB itself, named once and never renamed — the Usenet backend derives the release's identity from that filename, so renaming it orphans the release and every placement made out of it. |
| `data/sabnzbd-jobs.json` | Which NZBs were grabbed, under which category, and when. |
| `data/sabnzbd-apikey` | A generated API key. Not written when `sabnzbd.api_key` is set. |
| `data/magic.json` | The `__magic__` table — every placement and tombstone the imports created. |
