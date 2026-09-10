# Empty imports after a refused move

Reproduced with rclone 1.72.0, a local-first union, VFS full caching and the
.NET 6 `File.Move(source, destination)` used by Sonarr 4.0.19.2979.

When the backend refuses a MOVE, rclone's `vfs.File.rename` leaves the file's
directory and name pointing at the attempted destination. .NET then falls back
to a copy. Creating its destination creates an empty VFS cache entry; opening
the source reaches that same entry, so the copy reads EOF and reports success.
The reproduction expected 4096 bytes and received zero. Changing the WebDAV
refusal from 409 to 422 did not change the outcome.

The patch in `scripts/patches/rclone-v1.72.0-rename.patch` restores the original
directory and name when the immediate rename fails. It includes an upstream
VFS regression test. The mount test exercises the full WebDAV, union, FUSE and
.NET path with a fake archive and no provider credentials. Its damage verdict
is injected while the fixture bytes remain readable: .NET may copy those bytes
successfully, but must not turn them into an empty file.

Build a new binary alongside the installed one:

```sh
./scripts/build-rclone-move-fix.sh /absolute/path/to/rclone-fixed
RCLONE_TEST_BIN=/absolute/path/to/rclone-fixed ./integration/magic_move_refusal.sh
```

The build pins upstream commit `38ab3dd5b1df946aecf5bd085c671c86f46f68eb` (1.72.0).
It runs the VFS rename tests before building. The mount test requires Linux
FUSE and Docker, or a self-contained `DOTNET_MOVE_PROBE_BIN` built from
`integration/dotnet-move-probe`. It intentionally fails against the unpatched
binary. `make integration-test` includes this check; point `RCLONE_TEST_BIN`
and `RCLONE_BIN` at the corrected binary when running the suite.

Installation requires restarting the mount using the deployment's normal
media-server guards. Keep the previous binary for rollback. Existing empty
files on a union's local upstream survive a mount restart; preserve and remove
only confirmed empty import artifacts there. Restarting clears the stale VFS
nodes, but does not repair missing Usenet articles.

This correction does not suppress .NET's copy fallback or make damaged content
readable. zurg's availability check before SABnzbd completion and its refused
MOVE remain separate protections. Availability sampling is not a full-file
verification; see `sabnzbd-client-contract.md`.
