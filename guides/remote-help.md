---
label: Getting help
icon: people
order: 30
---

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
| A service | `journalctl --user -u rex -n 200 --no-pager` |
| Docker | `docker compose logs --tail=200 rex` |

## Remote help for sponsors

When a thread does not get it fixed, a helper can type in your terminal while you watch. **Remote help with zurg and rex is offered only to sponsors, and it is free: there is no charge on top of the sponsorship.** [Become a sponsor on gatekeeper](https://gatekeeper.debridmediamanager.com/), connect your Discord account there to get the sponsor role, then ask for remote help in your support thread.

The rest of this page sets it up with [sshx](https://sshx.io), through our own server at `sshx.debridmediamanager.com`. It works on Linux and macOS and Windows.

You need no account and no password and no router changes, and nothing to install first: the lines below download sshx and start it. Your helper types in a terminal on your machine from their browser. The session ends when you press `Ctrl+C`.

### 1. Pick the machine

Run sshx on the machine that runs zurg. If zurg is not installed yet then pick the machine it will run on. That is often not the computer in front of you.

| Where zurg runs | What to do |
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
mkdir -p ~/sshx && cd ~/sshx && curl -fsSL "https://s3.amazonaws.com/sshx/sshx-$(uname -m | sed 's/arm64/aarch64/;s/armv7l/armv7/')-$(uname -s | sed 's/Linux/unknown-linux-musl/;s/Darwin/apple-darwin/')$(uname -m | grep -q armv7 && echo eabihf).tar.gz" | tar -xz && ./sshx --server https://sshx.debridmediamanager.com
```

#### Windows

Open PowerShell. It does not need to run as administrator.

```powershell
$d = "$env:LOCALAPPDATA\sshx"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://s3.amazonaws.com/sshx/sshx-x86_64-pc-windows-msvc.zip -OutFile "$d\sshx.zip"; Expand-Archive -Force "$d\sshx.zip" $d; & "$d\sshx.exe" --server https://sshx.debridmediamanager.com
```

On an ARM laptop like a Surface Pro X replace `x86_64` with `aarch64`.

### 3. Send the link to your helper

sshx prints a link that looks like this.

```
➜  Link:  https://sshx.debridmediamanager.com/s/AbCdEfGhIj#KlMnOpQrStUvWx
```

**Send it in a private message.** Never post it in a public channel. Anyone who has the link can type on your machine, and sshx does not ask before letting them in.

Your own window only shows the link. To watch what your helper types, open the same link in your browser. You can type there too.

### 4. End it

**Press `Ctrl+C` in the window that shows the link when you are done.** That ends the session and the link stops working. Typing `exit` there does nothing.

Closing that window also stops your helper from typing. `Ctrl+C` is cleaner because it closes the session on the server at once.

To get help again later paste the line from step 2 again. Each session gets a new link.

## For helpers

Open the link you were sent in a browser and enter a name. The page starts empty: click the **+** button at the top (Create new terminal) to open a terminal on their machine. On Windows it is Git Bash if they have Git for Windows and Command Prompt otherwise; type `powershell` to switch. On Linux and macOS it is their normal shell.

Ask them to press `Ctrl+C` when you are done.
