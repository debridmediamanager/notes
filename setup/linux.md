# Linux binary setup

## One-line option

The optional sponsor bootstrap installs the supported system packages, downloads the matching CPU build and runs setup plus diagnostics:

```bash
curl -fsSL https://zurg.debridmediamanager.com/install.sh | bash
```

It signs in through GitHub and keeps the install in `~/zurg`. Existing binaries and configs are preserved. Continue below for the manual route or a custom path.

The zurg binary can build the rest of its install itself. It writes the config, downloads the correct rclone and ffprobe binaries for the machine, creates the mount and registers an enabled systemd service.

This flow was verified on 4 September 2026 on fresh Ubuntu 24.04 ARM64 and x86_64 servers.

## 1. Install FUSE 3

On Debian, Ubuntu and their derivatives:

```bash
sudo apt-get update
sudo apt-get install -y fuse3
```

Check that the helper and device are present:

```bash
command -v fusermount3
test -c /dev/fuse
```

If Plex, Jellyfin or another process runs as a different Unix user, enable `allow_other` once:

```bash
echo user_allow_other | sudo tee -a /etc/fuse.conf
```

Without that setting the mount still works, but only the account running zurg can open it. `zurg doctor` reports the difference.

## 2. Download zurg

Download the matching Linux archive from the [sponsor releases](https://github.com/debridmediamanager/zurg/releases). Choose `linux-amd64` for an Intel or AMD machine and `linux-arm64` for an ARM machine.

Extract it into the directory that should hold the whole install:

```bash
mkdir -p ~/zurg
cd ~/zurg
# Put the downloaded zurg binary here, then:
chmod +x zurg
```

Everything zurg keeps stays beside that binary: `config.yml`, downloaded helpers, library state, logs and the rclone cache.

## 3. Run setup

```bash
cd ~/zurg
./zurg setup
```

Setup asks which providers to configure. Choose one or several in priority order:

```text
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
```

For example enter `2,4` for TorBox followed by Usenet. Setup asks only for the selected credentials. It then:

1. Creates and validates `config.yml`.
2. Restricts the config to its owner with mode `0600`.
3. Downloads native rclone and ffprobe binaries into `bin/`.
4. Enables the rclone mount at `/mnt/zurg`.
5. Installs and starts an enabled systemd service.

Use a mount inside your home directory when you do not have permission to create `/mnt/zurg`:

```bash
./zurg setup --mount-path "$HOME/zurg-mount"
```

Setup is safe to run again. It updates the generated service but does not replace an existing `config.yml`.

### Choosing the systemd scope

With a working systemd user manager the default `auto` scope installs `~/.config/systemd/user/zurg.service`. Otherwise setup installs `/etc/systemd/system/zurg.service` and asks sudo to run it as the current user.

Choose explicitly when needed:

```bash
./zurg setup --service-scope user
./zurg setup --service-scope system --service-user "$USER"
```

For a user service to start before the first login after a reboot, enable lingering:

```bash
loginctl show-user "$USER" -p Linger
sudo loginctl enable-linger "$USER"
```

Running setup as `root` on a server selects a system service owned by root.

## 4. Verify the install

```bash
./zurg doctor
curl -fsS http://127.0.0.1:9999/http/version.txt
ls /mnt/zurg/version.txt
```

`doctor` checks the config and its permissions, both downloaded tools, FUSE, the systemd unit, the HTTP endpoint and the mount reported by zurg.

A large Real-Debrid library takes time to build on its first run. The service can already be active while the first mount listing waits for that scan to finish.

## Managing zurg

Run these commands from the zurg directory:

```bash
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` removes only auto-start. The binary, config, data, logs and cache stay in place.

Follow logs for a user service:

```bash
journalctl --user -u zurg.service -f
```

For a system service:

```bash
sudo journalctl -u zurg.service -f
```

## Updating zurg

A sponsor build replaces itself:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` takes the newest nightly. It downloads it, checks the new binary reports the version it expected, and only then swaps it in by rename, so the running process is never overwritten. When the installed build is already the newest it says so and changes nothing. Credentials come from the GitHub CLI sign-in when there is one, and from `GITHUB_TOKEN` or `GH_TOKEN` otherwise.

On a build too old to carry the command, the installer does the same job and touches nothing else:

```bash
curl -fsSL https://zurg.debridmediamanager.com/install.sh | bash -s update
```

## Existing and unattended configs

Setup never replaces an existing `config.yml`. For unattended setup repeat `--provider` and supply the matching token-file or `--nntp-*` flags. `REALDEBRID_TOKEN`, `TORBOX_TOKEN`, `ALLDEBRID_TOKEN` and the `NNTP_*` variables work too. Run `./zurg setup --help` for the full list.

See the [configuration reference](../reference/config.md) for every setting.

## See also

- [Docker](docker.md) — container setup and FUSE mount propagation
- [macOS](macos.md) — the same binary installer with macFUSE and launchd
- [Windows](windows.md) — the same binary installer with WinFsp and an interactive scheduled task
