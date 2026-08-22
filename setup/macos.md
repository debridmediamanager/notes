# macOS Tutorial

## Step 1: Install macFUSE

macFUSE lets rclone mount zurg's virtual filesystem as a real directory on your Mac.

1. Download the latest `.dmg` from [macfuse.io](https://macfuse.io)
2. Open the `.dmg` and run the installer
3. During installation, macOS will block the system extension. Go to **System Settings > Privacy & Security**, scroll down, and click **Allow**
4. **Reboot your Mac** (required for the kernel extension to load)

After rebooting, open **Terminal** (press `Cmd + Space`, type "Terminal", press Enter) and verify:

```bash
kextstat | grep macfuse
# Should output a line containing: io.macfuse.filesystems.macfuse
```

## Step 2: Download Zurg

Download the latest zurg binary from [GitHub Releases](https://github.com/debridmediamanager/zurg/releases). That repository is sponsors-only, so download it in a browser where you are signed in — the API is not reachable without a token. Pick the newest release and grab the `darwin-arm64` zip (`darwin-amd64` on an Intel Mac).

Then unpack it:

```bash
mkdir -p ~/zurg && cd ~/zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip
chmod +x zurg
```

Verify:

```bash
./zurg version
```

## Step 3: Configure Zurg

Create a config file with your Real-Debrid API token:

```bash
cd ~/zurg
cat > config.yml << 'EOF'
# Minimal config - use Dashboard at http://localhost:9999/config/ for more settings
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN_HERE

rclone_enabled: true
mount_path: /Volumes/Zurg

rclone_extra_args:
  - "--vfs-cache-max-size"
  - "100G"
  - "--vfs-cache-min-free-space"
  - "20G"

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
EOF
```

Replace the placeholder token with your actual token from [real-debrid.com/apitoken](http://real-debrid.com/?id=440161):

```bash
sed -i '' "s|YOUR_RD_API_TOKEN_HERE|PASTE_YOUR_TOKEN_HERE|g" ~/zurg/config.yml
```

> **Do not drop `mount_path`.** rclone would fall back to `/Volumes/Zurg` on macOS without it, but media-server scanning is only enabled when `mount_path` is set explicitly — leave it out and Plex never gets told to refresh (Step 6).

> **Cache sizing is critical.** The VFS cache stores chunks of streamed files on your local disk. If it fills your drive, macOS performance will degrade severely — Spotlight, Plex, and even the OS itself can become unresponsive. Always set **both** limits:
>
> - `--vfs-cache-max-size` — hard cap on total cache size. Set this to **no more than 50% of your free disk space**. Check with `df -h /`.
> - `--vfs-cache-min-free-space` — stops caching when free space drops below this. Keep at **20G or higher** as a safety net.
>
> For example, on a 256GB drive with 100GB free, use `50G` max size and `20G` min free space.

## Step 4: Download Dependencies

Zurg has a built-in command that downloads rclone and ffprobe and updates `config.yml` with their paths:

```bash
cd ~/zurg
./zurg download-requirements
```

Create the mount point and the log directory. `/Volumes` is owned by root, so zurg cannot create `/Volumes/Zurg` itself; the log directory has to exist before launchd opens its output files in Step 7:

```bash
sudo mkdir -p /Volumes/Zurg
sudo chown "$(whoami)" /Volumes/Zurg
mkdir -p ~/zurg/logs
```

See [the configuration reference](../reference/config.md) for all available options, or use the web Dashboard at `http://localhost:9999/config/` after starting zurg.

## Step 5: Test Zurg

Before setting up auto-start, verify everything works:

```bash
cd ~/zurg && ./zurg
```

You should see log output showing zurg starting up, connecting to Real-Debrid, and mounting via rclone. In another terminal window, check:

```bash
# Check the HTTP endpoint
curl -s http://localhost:9999/http/version.txt

# Check the mount
ls /Volumes/Zurg/
# Expected: __all__  __downloads__  __realdebrid__  __unplayable__  movies  shows  version.txt
```

If everything looks good, stop zurg with `Ctrl+C`.

## Step 6: Install Plex Media Server

1. Download from [plex.tv/media-server-downloads](https://www.plex.tv/media-server-downloads/) — select **macOS** (Universal)
2. Open the `.dmg` and drag **Plex Media Server** into `/Applications`
3. Launch Plex Media Server from Applications (or Spotlight: `Cmd + Space` → "Plex Media Server")
4. Your browser should open to the Plex setup wizard — follow it to claim your server
5. **Enable auto-start:** Right-click the Plex icon in the menu bar and check **Launch at Login**
6. Get your Plex token — the easiest way:
   - Open any media item in Plex Web
   - Click **Get Info** (or **...** → **Get Info**)
   - Click **View XML**
   - Look for `X-Plex-Token=` in the URL bar

Add the Plex token to your zurg config by editing `config.yml`:

```yaml
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
```

## Step 7: Set Up Zurg Auto-Start

macOS LaunchAgents start services automatically when you log in. Plex already handles its own auto-start (Step 6), so we only need a LaunchAgent for zurg.

### Zurg LaunchAgent

```bash
cat > ~/Library/LaunchAgents/com.zurg.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zurg</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/zurg/zurg</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${HOME}/zurg</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME}/zurg/logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME}/zurg/logs/launchd-stderr.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST
```

Key settings:
- **RunAtLoad** — starts zurg when you log in
- **KeepAlive / SuccessfulExit: false** — if zurg crashes, launchd automatically restarts it
- **ThrottleInterval: 10** — waits 10 seconds between restart attempts

### Load the LaunchAgent

```bash
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Verify it is registered:

```bash
launchctl list | grep zurg
# Should show com.zurg with a PID
```

## Step 8: Configure Plex Libraries

Now that zurg is running and the mount is active:

1. Open [http://localhost:32400/web](http://localhost:32400/web)
2. Go to **Settings** (wrench icon) → **Manage** → **Libraries**
3. Click **Add Library**

**Add Movies library:**
- Type: **Movies**
- Click **Browse for media folder**
- Navigate to `/Volumes/Zurg/movies`
- Click **Add Library**

**Add TV Shows library:**
- Type: **TV Shows**
- Click **Browse for media folder**
- Navigate to `/Volumes/Zurg/shows`
- Click **Add Library**

**Recommended library settings** (under each library's Edit → Advanced):
- Uncheck **Empty trash automatically after every scan** — zurg manages content lifecycle
- Uncheck **Generate video preview thumbnails** — saves bandwidth since files are streamed from Real-Debrid

## Step 9: Verify Everything Works

```bash
# 1. Zurg is running
curl -s http://localhost:9999/http/version.txt && echo " - Zurg is up"

# 2. Mount is active
ls /Volumes/Zurg/movies > /dev/null 2>&1 && echo "Mount is active"

# 3. Plex is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:32400/identity && echo " - Plex is up"

# 4. Processes
ps -eo pid,command | grep -E "[z]urg|[r]clone.*mount|[P]lex Media Server" | head -5

# 5. Zurg LaunchAgent
launchctl list | grep zurg
```

## Step 10: Enable Auto-Login (Optional)

By default, macOS requires a user to log in after each reboot before LaunchAgents start. If this Mac is a headless server, enable auto-login so everything starts unattended:

1. Open **System Settings**
2. Go to **Users & Groups**
3. Click **Automatic login** and select your user
4. Enter your password

> **Security note:** Auto-login means anyone with physical access to the Mac can access your account. Only use this on machines in a trusted location.

---

## Managing the Services

### Start / Stop / Restart

```bash
# Stop zurg (and its rclone child process)
launchctl stop com.zurg

# Start zurg
launchctl start com.zurg

# Restart zurg
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### View Logs

```bash
# Zurg logs
tail -50 ~/zurg/logs/launchd-stdout.log

# Rclone logs
tail -50 ~/zurg/logs/rclone.log
```

### Reload After Config Change

If you edit a `.plist` file:

```bash
launchctl unload ~/Library/LaunchAgents/com.zurg.plist
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

If you edit `config.yml`, just restart zurg:

```bash
launchctl stop com.zurg && launchctl start com.zurg
```

### Update Zurg

Download the new `darwin-arm64` zip from [Releases](https://github.com/debridmediamanager/zurg/releases) the same way as in Step 2, then:

```bash
cd ~/zurg
launchctl stop com.zurg && sleep 2
rm -f zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip
chmod +x zurg
launchctl start com.zurg
```

Delete the old binary rather than overwriting it in place. Rewriting the file keeps the same inode and invalidates its ad-hoc code signature, and macOS then kills the new build on exec — the symptom is an immediate exit with no output at all.

## Troubleshooting

### "Operation not permitted" when mounting

macFUSE needs to be approved in System Settings:
1. Go to **System Settings > Privacy & Security**
2. Scroll down and look for a blocked system extension message
3. Click **Allow**, then **reboot**

### Mount shows as "not a directory" or hangs

The mount point may be stale from a previous crash:

```bash
umount -f /Volumes/Zurg 2>/dev/null
diskutil unmount force /Volumes/Zurg 2>/dev/null
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Zurg keeps restarting (crash loop)

Check the logs for the error:

```bash
tail -100 ~/zurg/logs/launchd-stderr.log
```

Common causes:
- Invalid `config.yml` syntax — validate with `cd ~/zurg && ./zurg` manually
- Expired Real-Debrid token — get a new one from [real-debrid.com/apitoken](http://real-debrid.com/?id=440161)
- `/Volumes/Zurg` missing or not owned by your user — zurg cannot create it and fails with `ensure mount path: permission denied` (Step 4)
- Port 9999 already in use — check with `lsof -i :9999`

### macFUSE breaks after macOS update

Major macOS updates sometimes invalidate the kernel extension. Reinstall macFUSE:
1. Download the latest version from [macfuse.io](https://macfuse.io)
2. Install it
3. Approve the extension in **System Settings > Privacy & Security**
4. Reboot

### Everything was working but stopped after reboot

If auto-login is not enabled, you must log in to the Mac for LaunchAgents to start. Either:
- Enable auto-login (see Step 10)
- SSH in — the LaunchAgents will already be loaded once the user session exists
- Use VNC/Screen Sharing to log in remotely

## Architecture Overview

```
launchd (PID 1)

  com.zurg LaunchAgent
    └── ./zurg
          ├── HTTP/WebDAV server (:9999)
          ├── Dashboard UI (:9999/config/)
          ├── Real-Debrid API client
          └── rclone mount (child process)
                └── /Volumes/Zurg/
                      ├── movies/
                      └── shows/

  Plex Media Server (:32400)  — Launch at Login via menu bar
    ├── Movies library  → /Volumes/Zurg/movies
    └── Shows library   → /Volumes/Zurg/shows

  macFUSE kernel extension
    └── Enables FUSE mounts for rclone
```

## Quick Reference

| Action | Command |
|--------|---------|
| Start zurg | `launchctl start com.zurg` |
| Stop zurg | `launchctl stop com.zurg` |
| Restart zurg | `launchctl stop com.zurg && sleep 2 && launchctl start com.zurg` |
| View zurg logs | `tail -f ~/zurg/logs/launchd-stdout.log` |
| View rclone logs | `tail -f ~/zurg/logs/rclone.log` |
| Check mount | `ls /Volumes/Zurg/` |
| Check zurg health | `curl http://localhost:9999/http/version.txt` |
| Check Plex health | `curl http://localhost:32400/identity` |
| Dashboard | `open http://localhost:9999/config/` |
| Force unmount | `umount -f /Volumes/Zurg` |
