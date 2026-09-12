---
label: Command line
icon: terminal
order: 85
---

# Command line

The zurg binary is the server and a set of tools. Run it with no command to start the server. Every command takes `--help` and prints the text this page is written from.

Run commands from the instance's working directory. zurg reads `./config.yml` there unless you pass `--config`. Its data and logs folders resolve against that directory too.

```
zurg [flags]
zurg [command]
```

## Flags every command takes

| Flag | What it does |
|---|---|
| `-c`, `--config` | The config file to read. Defaults to `./config.yml`. |
| `-v`, `--version` | Prints the build and exits. The output matches `zurg version`. |
| `-h`, `--help` | Prints help for zurg or for one command. |

## Setting up

### zurg setup

Writes a config and downloads rclone and ffprobe. Then it registers zurg to start on its own. It asks for anything it is missing. `--dry-run` prints the plan and changes nothing.

Keys and passwords are read from files. That keeps them out of your shell history.

| Flag | What it does |
|---|---|
| `--provider` | A provider to configure. Repeat it for more than one. One of realdebrid, torbox, alldebrid, nzb, premiumize, debridlink, offcloud. |
| `--realdebrid-token-file` | Reads the Real-Debrid token from this file. The same flag exists for `torbox`, `alldebrid`, `premiumize`, `debridlink` and `offcloud`. |
| `--nntp-host` | The news server for the `nzb` provider. |
| `--nntp-port` | Its port. Defaults to 563 with TLS and 119 without. |
| `--nntp-tls` | Uses TLS. On by default. |
| `--nntp-username` | The news account's username. |
| `--nntp-password-file` | Reads the news account's password from this file. |
| `--nntp-connections` | The news account's connection allowance. Defaults to 8. |
| `--mount-path` | Where the mount appears. Defaults to the convention for your platform. |
| `--port` | The HTTP port. Keeps the value in the config when you leave it out. |
| `--service-name` | The service or scheduled task name. Defaults to `zurg`. |
| `--service-scope` | `auto`, `user` or `system`. Defaults to `auto`. |
| `--service-user` | The user a system service runs as. |
| `--no-service` | Configures everything but does not register auto-start. |
| `--no-start` | Registers the service but does not start it. |
| `--skip-downloads` | Does not download rclone or ffprobe. |
| `--skip-prerequisites` | Skips the FUSE check for this platform. |
| `--non-interactive` | Fails instead of asking for missing input. |
| `--dry-run` | Prints the plan and changes nothing. |

Each platform has its own walkthrough.

- [Linux](../setup/linux.md)
- [macOS](../setup/macos.md)
- [Windows](../setup/windows.md)
- [Docker](../setup/docker.md)

### zurg doctor

Checks what setup put in place. It reads the config and looks for rclone and ffprobe. Then it checks the service and the HTTP endpoint and the mount. Run it first when something is not working.

| Flag | What it does |
|---|---|
| `--working-dir` | The instance's working directory. Defaults to the current one. |
| `--service-name` | The service name to check. Defaults to `zurg`. |
| `--service-scope` | `auto`, `user` or `system`. Defaults to `auto`. |

### zurg service

Installs and controls auto-start without running the rest of setup.

| Command | What it does |
|---|---|
| `zurg service install` | Installs auto-start and starts it. Pass `--start=false` to install without starting. |
| `zurg service uninstall` | Removes auto-start. The config and data stay. |
| `zurg service start` | Starts the installed service. |
| `zurg service stop` | Stops it. |
| `zurg service restart` | Restarts it. |
| `zurg service status` | Shows the auto-start status. |

Every one of them takes the same flags.

| Flag | What it does |
|---|---|
| `--name` | The service or scheduled task name. Defaults to `zurg`. |
| `--scope` | `auto`, `user` or `system`. Defaults to `auto`. |
| `--user` | The user a system service runs as. |
| `--working-dir` | The working directory the service starts in. |
| `--executable` | The zurg binary the service runs. |

### zurg download-requirements

Downloads rclone and ffprobe into a folder and writes their paths into the config. Setup does this for you unless you pass `--skip-downloads`.

| Flag | What it does |
|---|---|
| `--dir` | Where the binaries go. Defaults to `bin`. |
| `--rclone-version` | An rclone release such as `1.67.0`. Defaults to `latest`. |
| `--ffprobe-version` | An ffprobe release. Defaults to `latest`. |

### zurg update

Replaces the binary with the newest sponsor nightly. Inside a container it refuses because the next recreate would throw the new binary away. Pull a new image there instead. `--force` updates anyway.

### zurg version

Prints the build. `zurg --version` prints the same thing.

## Backups

### zurg backup

Writes a `.zurgbackup` file holding what nothing else can rebuild. That is the config with its tokens and every `data/*.zurgtorrent` with its tags and account links. It also holds the `__magic__` store under `data/local/` and the source NZBs under `nzbs/`. Caches and Plex snapshots and logs are left out so the backup stays the size of what it protects.

The instance does not need to be running. That makes it safe to schedule. The file is a gzip tar with your tokens inside. Store it like a password.

| Flag | What it does |
|---|---|
| `-o`, `--out` | Where to write it. Defaults to `zurg-<timestamp>.zurgbackup` in the current directory. |
| `--include-caches` | Also packs derived metadata and cached bytes for a warm restore. Plex snapshots and logs stay out. This can be large. |

### zurg restore-backup

Unpacks a `.zurgbackup` into the current directory. Every file goes back to the path it came from. Stop zurg first. The restore writes files a running instance is writing too.

```
zurg restore-backup my-backup.zurgbackup
```

A config already in the directory is left alone. That file carries the tokens the whole library hangs on. Pass `--force-config` to overwrite it.

## Measuring

### zurg benchmark-my-setup

Reads real bytes the way a player would and reports the spread rather than one figure. It runs in three phases. First each account on its own. That is the number to hold against what the service promises. Then every account at once. Accounts that each do 70 MiB/s alone and 25 MiB/s together share one saturated uplink. Last it reads through the rclone mount. The gap to the first phase is what FUSE and the VFS cost.

Samples land at random offsets. Every layer underneath caches and rereading one offset would measure the cache instead of the link.

It adds and deletes nothing. It does spend your bandwidth. Each account reads the sample size times the iteration count twice. The mount phase comes on top.

| Flag | What it does |
|---|---|
| `-n`, `--iterations` | Samples per account per phase. Defaults to 3. |
| `--sample-mb` | MiB read per sample. Defaults to 128. Use 1024 to get past rclone's read-chunk ramp for a sustained mount figure. |
| `--provider` | Benchmarks only these accounts by name. Repeatable. |
| `--skip-concurrent` | Skips the all-accounts phase. |
| `--skip-mount` | Skips the mount phase. |
| `--json` | Prints the report as JSON. |

### zurg network-test

Measures how quickly this host reaches each Real-Debrid download server over IPv4 and over IPv6. The results go to `logs/network-test.log` and into `data/` where the server reads them to pick its hosts. Set `PROXY` in the environment to test through a proxy.

| Flag | What it does |
|---|---|
| `-t`, `--test-url` | A file URL whose path is fetched from every server instead of Real-Debrid's own speed test file. |

## Plex

These three work against the Plex server on this host. Configure Plex first. See [Plex Integration](config.md#plex-integration).

### zurg plex-settings

Reports the Plex settings that matter for a mount and fixes what the policy allows. Plex's defaults assume local disks. One of them deletes the library when a scan meets a blip. Others make Plex decode every file it has. [plex.md](../guides/plex.md#recommended-plex-settings) explains each one.

| Flag | What it does |
|---|---|
| `-p`, `--policy` | `off`, `warn`, `guard` or `enforce` for this run. Defaults to `plex_settings_policy` from the config. Passing a stricter one previews it before you adopt it. |

### zurg plex-drift

Reads Plex's database without writing to it and checks every file it points to under the mount. It reports the ones that are gone. Run it before a library scan. A scan that meets those files turns them into deletions. Knowing the count first makes the scan a decision and not a gamble.

It needs `plex_database_path` and Plex on the same host.

### zurg plex-backups

Lists the Plex database snapshots zurg holds with the newest first. Each row shows when it was taken and its size and how many items each library held at that moment. The counts come out of the snapshots themselves. So the list shows what each one can actually restore. [Plex Library Maintenance](config.md#plex-library-maintenance-same-host-only) covers when zurg takes them.

## Sharing

### zurg export-torrents

Writes portable `.zurgtorrent` files that describe your releases without your account in them. No credentials go in. No torrent ids and no repair state and no CDN links either. No provider is contacted.

It reads `data/*.zurgtorrent` or an old dump file. Pass a file or folder to export only those. The recipient puts the files in `torrents/<their-account>/` and sets that account to `library.source: local`. [portable-libraries.md](../guides/local-libraries.md) covers the receiving side.

| Flag | What it does |
|---|---|
| `--provider` | Exports the releases held by this configured account. |
| `--output` | Where the portable files go. |
| `--replace` | Replaces an existing export of the same hash. |
| `--skip-invalid` | Skips and counts entries it cannot read during a bulk export. |

### zurg nzb-share

Builds a share of your NZBs that you can publish. The result is a folder with a `manifest.json` and one `.nzb.gz` per release named by content hash. Every NZB is cleaned first. Comments and DOCTYPEs and watermark metadata go. So do the original file names. Posters and dates go too, and every file gets the same fixed newsgroup, because some indexers change all three on every download. Account stamps an indexer hides in a subject, a title or a password are cut. What you publish names the release and never the account that downloaded it. Real archive passwords stay because recipients need them to read the release.

Publish the folder anywhere static. A git repository works. So does a Pages site or `rclone serve`. The audit of what was stripped stays on your machine and prints here. It holds the very identifiers the clean exists to remove.

| Flag | What it does |
|---|---|
| `--from` | The watch folder to share. Walked recursively. Defaults to `nzbs`. |
| `--out` | The output folder. Defaults to `nzb-share-<timestamp>`. |
| `--title` | A title recorded in the manifest. |
| `--filter` | Shares only source paths that match this regular expression. |

The dashboard can serve a share too. See [Public NZB sharing](config.md#public-nzb-sharing).

### zurg nzb-sync

Pulls a shared library into your watch folder. It follows a share's `manifest.json` from a URL or a local path. Each NZB is checked against the hash in the manifest before it is written. Your own news accounts fetch the bytes.

```
zurg nzb-sync https://example.com/share/manifest.json
```

It only adds. Entries you already have are skipped and a share never deletes anything. Two shares of the same releases dedupe by content hash.

| Flag | What it does |
|---|---|
| `--into` | The watch folder to write into. Defaults to `nzbs`. |
| `--dry-run` | Reports what it would write and writes nothing. |

## Clearing a Real-Debrid account

These two delete everything of one kind from a Real-Debrid account. They cannot be undone. They work on Real-Debrid only.

Both ask for the `auth` cookie of a logged-in Real-Debrid browser session rather than your API token. They print a line of JavaScript that shows it. Run that in the browser console on real-debrid.com and paste the result.

| Command | What it does |
|---|---|
| `zurg clear-torrents` | Deletes every torrent in the account. |
| `zurg clear-downloads` | Deletes every download in the account. Those are the unrestricted links. |

## Shell completion

`zurg completion bash` prints a completion script for bash. The same works for `zsh` and `fish` and `powershell`. `zurg completion <shell> --help` says where to put it.
