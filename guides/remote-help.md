# Getting remote help

Sometimes the fastest fix is for a helper to type in your terminal while you watch. This page sets that up with [upterm](https://github.com/owenthereal/upterm). It works on Linux and macOS and Windows.

You need no account and no password and no router changes. You do not need to share an SSH key. Your helper only ever sees the one terminal window you open for them. The session ends when you type `exit`.

## 1. Pick the machine

Run upterm on the machine that runs zurg. If zurg is not installed yet then pick the machine it will run on. That is often not the computer in front of you.

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

## 2. Start a session

Paste the line for the system you picked in step 1.

### Linux and macOS

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --name zurg-help
```

### Windows

Open PowerShell. It does not need to run as administrator.

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz"; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --name zurg-help
```

On an ARM laptop like a Surface Pro X replace `amd64` with `arm64`.

## 3. Trust the server once

The first run asks whether to trust `uptermd.upterm.dev`. Type `yes`. The fingerprint it shows should match this one.

```
SHA256:9ajV8JqMe6jJE/s3TYjb/9xw7T0pfJ2+gADiBIJWDPE
```

## 4. Send the line to your helper

upterm prints a line that looks like this.

```
ssh AbCdEfGhIjKlMnOpQrSt@uptermd.upterm.dev
```

**Send it in a private message.** Never post it in a public channel. Anyone who has the line can get in.

## 5. Let them in

upterm asks `Accept connections? [y/n]`. Type `y` once you have sent the line. From then on you see everything your helper types as they type it. You can type too.

## 6. End it

**Type `exit` when you are done.** That ends the session and the line stops working right away.

Closing the window is not enough. The session keeps running in the background. If you closed it by accident then open a new terminal and stop it.

```bash
~/upterm/upterm session stop zurg-help
```

```powershell
& "$env:LOCALAPPDATA\upterm\upterm.exe" session stop zurg-help
```

The same command fixes `name is in use by a running session` when you start a new session.

To get help again later paste the line from step 2 again.

## For helpers

Join with the line you were sent.

```bash
ssh AbCdEfGhIjKlMnOpQrSt@uptermd.upterm.dev
```

Any SSH key works. If you have none run `ssh-keygen -t ed25519` once first. On Windows the session opens in PowerShell. On Linux and macOS it opens in their normal shell.

Ask them to type `exit` when you are done.
