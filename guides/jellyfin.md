# Jellyfin Features & Capabilities

## Configuration & Storage
- Config keys ([`config.md`](../reference/config.md), `config.example.yml`): `jellyfin_server_url` (string, default `""`), `jellyfin_token` (string, default `""`). Both ship commented out in `config.example.yml` and are absent from `config.simple.yml`. `mount_path` must be set or media scanning (including Jellyfin) is disabled (`pkg/scan/scanner.go`).
- Values are persisted in `config.yml` via the dashboard (`updateConfigFileAtomic`); there is no separate Jellyfin data file. The fields and their `Get`/`Set` helpers live on `zurgConfig` in `internal/config/config.go`; `ZurgConfigV1` (`internal/config/filters.go`) embeds that struct inline.

## Authentication & Server Validation (QuickConnect)
- Dashboard QuickConnect flow:
  - `/jellyfin/check-server` verifies reachability via `System/Info/Public` and reports version/name and QuickConnect availability (`HandleJellyfinCheckServer`, `pkg/jellyfin/auth.go:CheckServerReachable/CheckQuickConnectEnabled`).
  - `/jellyfin/auth` initiates QuickConnect (`InitiateQuickConnect`), creates a cookie-scoped auth session (`pkg/jellyfin/auth_session.go`), and starts background polling.
  - `/jellyfin/auth/status` returns completion/error state while polling `/QuickConnect/Connect` + `/Users/AuthenticateWithQuickConnect` (`PollForQuickConnectAuth`, 60 attempts 5s apart before timing out).
  - `/jellyfin/server` saves server URL/token to config, reinitializes the Jellyfin client, and responds with success/warning if reinit failed (`HandleJellyfinServerSelect`).
  - `/jellyfin/logout` clears config, reinitializes the scanner without Jellyfin, and drops the cached dashboard status (`JellyfinStatusFetcher.ClearCache`).
- Auth session manager tracks QuickConnect sessions, stores secret/code/token/user info, cleans up after 10 minutes (swept every 5), and exposes thread-safe getters (`pkg/jellyfin/auth_session.go`; global instance in `auth_global.go`).
- The QuickConnect helpers in `pkg/jellyfin/auth.go` send an Emby-style `X-Emby-Authorization` header and run with TLS verification disabled to tolerate self-signed certs (`newHTTPClient`). The scan client does not: `mediabrowser.NewCore` builds a plain 30s-timeout `http.Client` (`pkg/mediabrowser/core.go`), so a server behind a self-signed cert pairs and validates fine but its section/refresh calls fail on TLS.
- Token validation endpoint `/System/Info` is used to confirm credentials before saving (`ValidateToken`).

## Jellyfin Client Capabilities (`pkg/jellyfin/client.go`)
- `Client` is a thin shell over the embedded `mediabrowser.Core` (`pkg/mediabrowser/core.go`), shared with `pkg/emby` because both servers descend from the same codebase. Its own methods are just `ProcessJob`, `GetSections`, `GetRunningTasks` and `GetServerStatus`; lifecycle, queue, auth header and stuck tracking all come from the core.
- Auth: the core stamps `X-MediaBrowser-Token: <token>` on every request (`SetAuthHeader`) — Emby's client differs only in using `X-Emby-Token`.
- Lifecycle: `NewClientWithLogger` builds the core (trims trailing slashes, warns and returns nil when the URL *or* token is empty), then `StartWorker` starts the dynamic scan worker unless `GO_TEST_MODE=1`; `Close` shuts worker and queue down.
- Scan queue: dynamic job queue + `common.DefaultWorkerConfig`; `GetJobQueueSize` is what the dashboard reads (via `MediaScanner.GetQueueSizes`). `GetJobQueue` is a compatibility stub that returns a slice of empty jobs sized to the queue.
- Load/stuck detection: `CheckServerLoad` polls `/ScheduledTasks`, watches running tasks whose name contains "scan", tracks per-task stuck counts, and reports busy when scans are active; `IsJobStuck` flags tasks exceeding the stuck threshold.
- Activity tracking: `GetRunningTasks` returns detailed `TaskActivity` structs with ID, Name, State, Progress (from `CurrentProgressPercentage`), Description, and stuck status for dashboard display.
- Server status: `GetServerStatus` polls `/Sessions` to count active streaming sessions, transcodes (non-direct video/audio), and bandwidth usage for dashboard display.
- Library discovery: `GetSections` calls `/Library/VirtualFolders`, returns sections with ID/Title/Path/Type, and augments each with an item count via `Items?ParentId=<id>&Recursive=true&Limit=0`.
- Refreshing: `ProcessJob` posts to `/Library/VirtualFolders/LibraryScan?itemId=<sectionKey>&path=<path>` with normalized forward-slash paths (Windows-safe), scanning only `job.Paths[0]`. It returns `ServerBusyError` on 503, a "library may have been deleted" error on 404, and the response body on any other 4xx/5xx. `RefreshSection` enqueues jobs.
- Helpers: `FindSectionNormalized` matches by path prefix (first match wins) and returns the path with its prefix rewritten to the library location's casing. The prefix test is case-insensitive on darwin and exact elsewhere (`pkg/common/pathutil.go`).

## Media Scanner Integration (`pkg/scan/scanner.go`)
- Initializes the Jellyfin client when `mount_path`, server URL, and token are present; logs success and keeps the client nil on failures. No retry loop (unlike Plex), but manual reinit is supported.
- `TriggerScan` dispatches to Jellyfin alongside other servers; `triggerJellyfinScan` resolves sections via `FindSectionNormalized` using `mount_path`-prefixed paths and refreshes each path individually (non-batch mode, unlike Plex).
- `GetQueueSizes` returns Plex/Jellyfin/Emby queue lengths together, using -1 for a server that is not connected.
- `ReinitializeJellyfinClient` closes any existing client and rebuilds with current config (used after dashboard auth and on logout).

## Dashboard & Routes
- Router mounts Jellyfin endpoints: `/jellyfin/check-server`, `/jellyfin/auth`, `/jellyfin/auth/status`, `/jellyfin/server`, `/jellyfin/logout`, `/jellyfin/scan/{sectionID}`, `/jellyfin/scan-all` (`internal/handlers/router.go`).
- Dashboard modal (templates/scripts) drives QuickConnect, displays status/errors, and saves/removes credentials; queue size, library cards with scan buttons, and server activities surface in `dashboard.tmpl`.
- `JellyfinStatusFetcher` (`internal/handlers/dashboard/jellyfin_status.go`) fills the dashboard JSON from a background cache rather than blocking the page: it validates the token, marks connectivity, populates the library list (ID/Name/Path/Type/ItemCount), and collects running task activities plus session/transcode/bandwidth counts. Activities and sessions refresh every 30s; the full fetch, libraries included, every 5 minutes. `response.go` serves the cached copy (`JellyfinServerInfo`, `jellyfin_queue_size`).
- Library scan endpoints (`HandleJellyfinScan`, `HandleJellyfinScanAll`) queue refresh jobs for individual or all library sections, passing the library's own root location as the scan path and 503-ing when no Jellyfin client is configured (`internal/handlers/dashboard/dashboard.go`). The Plex equivalents queue a section-wide scan with no path.
- `jellyfin_server_url` and `jellyfin_token` are also writable through the generic config-update handlers, so they can be set without the QuickConnect modal (`handlers["jellyfin_server_url"]`/`["jellyfin_token"]` in `dashboard.go`; `updateJellyfinServerURL`/`updateJellyfinToken` in `scripts.tmpl`).

## Library Side Effects & Refresh
- Any library side effects (directory assignment changes, STRM sync, repairs) invoke `MediaScanner.TriggerScan`, which includes Jellyfin refreshes when the client is connected (`internal/torrent/hooks.go:TriggerLibrarySideEffects` → `pkg/scan/scanner.go`).
- The same call first forgets the affected rclone VFS dircache entries, so Jellyfin's scan sees the change rather than a listing cached for hours.
- STRM sync and `on_library_update` hooks run alongside the scan trigger (the hook debounced 500ms and deduped); Jellyfin receives mount_path-prefixed library paths in refresh jobs.

## Miscellaneous
- Emby is a sibling integration with its own config keys (`emby_server_url`, `emby_token`) and the same shared core, but no QuickConnect: `/emby/connect` takes a URL and API key directly, and there is no Emby status fetcher, so its dashboard card shows only the configured URL and queue size — no libraries, activities or sessions.
- Windows path normalization is tested to ensure backslashes are converted before sending refresh requests (`pkg/jellyfin/windows_path_test.go`); `find_section_test.go` covers prefix matching.
