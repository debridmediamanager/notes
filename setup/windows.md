---
label: Windows
icon: terminal
order: 70
---

# Windows Setup Guide

## Prerequisites

- **WinFsp**: Required for rclone FUSE mount. Install silently:
  ```powershell
  $url = "https://github.com/winfsp/winfsp/releases/download/v2.0/winfsp-2.0.23075.msi"
  Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\winfsp.msi" -UseBasicParsing
  Start-Process msiexec.exe -ArgumentList "/i", "$env:TEMP\winfsp.msi", "/qn", "/norestart" -Wait
  ```

## Cross-compile

```bash
GOOS=windows GOARCH=amd64 make build
```

Produces a PE32+ executable named `zurg` (rename to `zurg.exe` when copying to Windows).

## First run

On first run, zurg automatically:
1. Creates `data/`, `dump/`, `logs/`, `strm/`, `bin/` directories
2. Downloads `ffprobe.exe` from ffbinaries.com
3. Downloads `rclone.exe` from GitHub releases
4. Updates `config.yml` with `ffprobe_binary: bin\ffprobe.exe` and `rclone_binary: bin\rclone.exe`
5. Runs the network latency test (results cached to `data/network_test_results.json`)

## Config notes

Minimal Windows config:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_TOKEN
port: 9999
rclone_enabled: true
rclone_binary: bin\rclone.exe
mount_path: "Z:"
rclone_extra_args:
  - "--links"
ffprobe_binary: bin\ffprobe.exe
```

### Required: `--links` flag

rclone's union remote fails on Windows without `--links`:

```
ERROR : symlinks not supported without the --links flag: /
```

Add `--links` to `rclone_extra_args` to fix this. Zurg's union remote (local + webdav) triggers this because the local backend scans the `data/local` directory.

### `--network-mode` (not recommended)

Adding `--network-mode` to `rclone_extra_args` creates a WinFsp network share (`\\server\zurg{HASH}`) instead of a drive letter mount. The share is accessible via UNC path from any session, but:
- The auto-generated `{HASH}` suffix makes the UNC path unpredictable
- `net use Z: \\server\zurg{HASH}` fails with error 67 (network name not found)
- Not practical for drive letter mapping

## Session isolation problem

**This is the main blocker for a clean Windows setup.**

WinFsp/rclone mounts are scoped to the Windows session where the process runs. Windows has separate sessions:
- **Session 0**: Services and SSH connections
- **Session 1+**: Interactive desktop (console, RDP, Parsec)

A process started from SSH runs in session 0. Its rclone mount (e.g., `Z:`) is invisible to the desktop session (and vice versa). This means:
- `Start-Process` from SSH → mount invisible to desktop
- Scheduled task with `schtasks /run` from SSH → runs in session 0, mount invisible
- Scheduled task with `/IT` flag → correct at logon, but `schtasks /run` from SSH still targets session 0
- `Register-ScheduledTask` with `-LogonType Interactive` → same problem when triggered from SSH

### Approaches tried

| Approach | Result |
|----------|--------|
| `Start-Process` from SSH | Runs in session 0, mount invisible to desktop |
| Scheduled task (`/IT`, `Interactive` logon) | Correct at logon trigger, but `schtasks /run` from SSH still uses session 0 |
| `--network-mode` | Creates UNC share visible across sessions, but can't map to drive letter |
| PsExec `-i 1` | Launches in session 1, processes run in correct session, but mount still didn't appear (needs more investigation) |
| VBS in Startup folder | Works but requires manual double-click or re-login |

### Recommended next steps

1. **Native WebDAV mapping** (untested): Skip rclone entirely, run zurg as a background service, map WebDAV via `net use Z: http://localhost:9999/dav/`. Windows has a built-in WebDAV redirector (WebClient service). Persistent mappings (`/persistent:yes`) recreate at logon. May have performance limitations.

2. **Interactive launch from desktop**: Start zurg from the console session directly (double-click, startup folder, or Parsec). The logon-triggered scheduled task should work correctly for auto-start on actual login (not SSH-triggered).

3. **PsExec investigation**: `PsExec64.exe -i 1 -d -w C:\Users\ben\zurg zurg.exe` successfully launched processes in session 1, but the Z: mount wasn't visible in Explorer. May need `-s` flag or different user context. PsExec is at `bin\PsExec64.exe` (downloaded from Sysinternals).

## Current state on bp-00516

```
C:\Users\ben\zurg\
├── bin\
│   ├── ffprobe.exe      # auto-downloaded
│   ├── rclone.exe       # auto-downloaded
│   └── PsExec64.exe     # from Sysinternals
├── data\                # cached torrents, network test results, local union dir
├── dump\
├── logs\                # zurg.log, rclone.log
├── strm\
├── config.yml
└── zurg.exe             # cross-compiled from mac (GOOS=windows GOARCH=amd64)
```

WinFsp is installed. No scheduled tasks or startup scripts are configured. Zurg is not running.

## PowerShell over SSH gotchas

- `&&` is not a valid statement separator — use `;` instead
- `2>/dev/null` doesn't work — use `-ErrorAction SilentlyContinue` or `2>$null`
- `$_` and other special chars get eaten — use encoded commands or `.ps1` script files:
  ```bash
  sshpass -p 'pw' ssh user@host "powershell -ExecutionPolicy Bypass -File C:\path\script.ps1"
  ```
- Pipe `|` in string arguments (e.g., regex) gets interpreted by PowerShell — use script files for anything with special characters
- `Start-Process` processes get killed when the SSH session ends — use scheduled tasks or PsExec for persistence
