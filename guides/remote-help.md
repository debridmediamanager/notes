# Getting help with zurg and rex

## Ask in Discord

Post in the [Discord](https://discord.com/invite/7u4YjMThXP) forum for what you are using: **zurg-support**, **rex-support** or **dmm-support**. Open one thread per problem. Say what you did, what you expected and what happened instead, and include the following.

**For zurg**, click **Export Logs** on zurg's dashboard and paste the links it gives you. It uploads zurg's log and config with your tokens, passwords and API keys removed. If it cannot upload, **Download Logs** gives you the same thing as a file to attach. Also paste what `zurg doctor` prints:

| zurg runs as | Run |
|---|---|
| The binary on Linux or macOS | `./zurg doctor` in zurg's folder |
| The binary on Windows | `.\zurg.exe doctor` in zurg's folder |
| Docker | `docker compose exec zurg /app/zurg doctor --working-dir /config` |

**For rex**, paste the end of rex's log. rex masks Plex tokens in it.

| rex runs as | Run |
|---|---|
| A systemd service on Linux | `journalctl --user -u rex -n 200 --no-pager` |
| launchd on macOS | `tail -n 200 ~/rex/rex.log` |
| Task Scheduler on Windows | `Get-Content $HOME\rex\rex.log -Tail 200` |
| Docker | `docker compose logs --tail=200 rex` |
| A terminal window | The last 200 lines in that window |

## Remote help for sponsors

When a thread does not get it fixed, a helper can type in your terminal while you watch. **Remote help with zurg and rex is offered only to sponsors, and it is free: there is no charge on top of the sponsorship.** [Become a sponsor on gatekeeper](https://gatekeeper.debridmediamanager.com/), connect your Discord account there to get the sponsor role, then ask for remote help in your support thread.

The rest of this page sets it up with [upterm](https://github.com/owenthereal/upterm), through our own server at `upterm.debridmediamanager.com`. It works on Linux and macOS and Windows.

You need no account and no password and no router changes, and nothing to install first: the lines below download upterm and start it. Your helper types in your terminal while you watch it in the same window. The session ends when you type `exit`.

### 1. Pick the machine

Run upterm on the machine that runs what you need help with, zurg or rex. If it is not installed yet then pick the machine it will run on. That is often not the computer in front of you.

| Where it runs | What to do |
|---|---|
| This computer | Open a terminal here and go to step 2. |
| A cloud server like Hetzner or Oracle or a VPS | SSH into it first. Then use the Linux line in step 2 in that SSH window. |
| A NAS or server at home like Synology or Unraid | Open its terminal. Then use the Linux line in step 2 there. |
| Docker | Use the machine that runs Docker and not a container. |

You can SSH from Windows too. PowerShell has `ssh` built in.

```bash
ssh you@your-server
```

**Synology** has SSH off by default. Turn it on in Control Panel > Terminal & SNMP > Enable SSH service. Then log in with an admin account. Use the NAS address from your router or from Synology Assistant.

If step 2 says `cannot create directory` on Synology then turn on Control Panel > User & Group > Advanced > Enable user home service and run it again.

**Unraid** has a terminal in its web page. Click the `>_` icon at the top right.

### 2. Start a session

Paste the line for the system you picked in step 1.

#### Linux and macOS

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

#### Windows

Open PowerShell. It does not need to run as administrator.

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz" -UseBasicParsing; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

On an ARM laptop like a Surface Pro X replace `amd64` with `arm64`.

The first time, upterm asks whether to trust `upterm.debridmediamanager.com`. Type `yes`. The fingerprint it shows should be this one.

```
SHA256:r1LtSiydnfetLGxGt8hy+ULyqtN2KgnZSHtRgHzDr58
```

### 3. Send the SSH line to your helper

upterm prints a few lines. Copy the one under **SSH**, which looks like this.

```
ssh AbCdEfGhIjKlMnOpQrSt:dXB0ZXJt...@upterm.debridmediamanager.com -p 2222
```

**Send it in a private message.** Never post it in a public channel. Anyone who has it can type on your machine.

Then leave the window open and do not click inside it: on Windows a click in a PowerShell window can pause what runs in it until you press `Esc`. You see everything your helper types in that window as they type it.

### 4. End it

**Type `exit` in that window when you are done.** That ends the session and the line stops working at once.

Closing the window is not enough: the session keeps running. If you closed it, open a new terminal, run `~/upterm/upterm session list` (on Windows `& "$env:LOCALAPPDATA\upterm\upterm.exe" session list`) and then the same program with `session stop` and the name it shows.

To get help again later paste the line from step 2 again. Each session gets a new line.

## For helpers

Run the SSH line you were sent. Any SSH key works; if you have none, run `ssh-keygen -t ed25519` once first. You land in their terminal: PowerShell on Windows, their normal shell on Linux and macOS.

To copy a file, the session ID's `:` confuses `scp`, so pass it as the user instead: `scp -P 2222 -o User=<everything before the @> file upterm.debridmediamanager.com:file`.

Ask them to type `exit` when you are done.
