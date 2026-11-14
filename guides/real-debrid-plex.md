---
label: Real-Debrid in Plex
icon: play
order: 48
description: "How to get your Real-Debrid library into Plex with zurg: what you need, the install for Windows, Linux, macOS or Docker, adding the 'movies' and 'shows' folders in Plex, and fixes for the usual problems."
---

# A Real-Debrid library in Plex with zurg

zurg shows everything in your Real-Debrid account as folders on your computer, already sorted into `movies` and `shows`. Add those two folders to Plex Media Server and your whole Real-Debrid library plays in every Plex app, streamed from Real-Debrid with nothing downloaded first. You install zurg once; it brings its own rclone, so there's nothing else to set up.

Rather not run Plex Media Server or a mounted drive? [rex with zurg](../rex/with-zurg.md) shows the same library to the Plex apps without either.

## What you need

- **A sponsorship.** zurg's nightly is for sponsors. Sponsor on [gatekeeper](https://gatekeeper.debridmediamanager.com/) and it gives your GitHub account access to the download. [What a sponsorship gives you](sponsorship.md) has the rest.
- **A Real-Debrid premium account** and its API token: [Your Real-Debrid API token](real-debrid-api-token.md) says where to find it.
- **Plex Media Server on the same computer as zurg.** Plex reads the files from zurg's folders, so it has to see them. Any Plex app can then watch.
- **A computer that stays on**: Windows 10 or 11, Linux, a Mac, or a Linux machine with Docker.

## 1. Install zurg

Each setup page starts with a one-line installer. When it says `Choose one or more providers in priority order:`, type `1` for Real-Debrid, then paste your token.

| Your computer | Install with | Your library shows up at |
|---|---|---|
| Windows | [zurg on Windows](../zurg/setup/windows.md) | `Z:\movies` and `Z:\shows` |
| Linux | [zurg on Linux](../zurg/setup/linux.md) | `/mnt/zurg/movies` and `/mnt/zurg/shows` |
| Mac | [zurg on macOS](../zurg/setup/macos.md) | `/Volumes/Zurg/movies` and `/Volumes/Zurg/shows` |
| Linux with Docker | [One Docker Compose file](../zurg/guides/docker-compose.md), which runs Plex Media Server beside zurg | `/zurg_mnt/zurg/movies` and `/zurg_mnt/zurg/shows` |

The installer ends with `zurg doctor`, a list of `PASS` lines.

## 2. Check the folders

Open zurg's drive or folder. You should see `movies`, `shows`, `__all__`, `__downloads__`, `__unplayable__` and `version.txt`.

The first start reads your whole Real-Debrid account. Until that's done the folders stay empty. To check, open `http://localhost:9999/ready` in a browser: it says `ready` once your library is in.

## 3. Add the folders in Plex

In Plex Web, press **Add Library**, the button beside your server's name in the sidebar:

1. Pick **Movies** and press **Next**.
2. Press **Browse for media folder** and pick zurg's `movies` folder from the table above, such as `Z:\movies` on Windows.
3. Press **Add Library**.

Do the same with **TV Shows** and the `shows` folder. Plex then scans both and fills in posters and titles.

## 4. Let zurg tell Plex about new things

Plex doesn't notice when something new lands in your Real-Debrid account. zurg can tell it. Open zurg's dashboard at `http://localhost:9999/config/`, go to **Media Server Integration** and press **Login with Plex**. Sign in to Plex and pick your server.

![The Media Server Integration section of zurg's dashboard, with the Login with Plex button](../assets/real-debrid-plex/01-zurg-login-with-plex.webp)

From then on zurg asks Plex to scan each folder that changes. It also turns off a few Plex settings that are risky on a streamed library, such as **Empty trash automatically after every scan**: [Recommended Plex Settings](../zurg/guides/plex.md#recommended-plex-settings) lists them.

## When something is wrong

| What you see | What to do |
|---|---|
| Plex finds nothing, or zurg's folders are empty | zurg is still reading your account. Wait until `http://localhost:9999/ready` says `ready`, then scan again in Plex. |
| On Windows there's no `Z:` drive, or Plex can't find `Z:\movies` | `Z:` belongs to your Windows desktop session, and zurg's installer starts zurg there when you log in. A PowerShell opened as administrator doesn't see it either. [When something is wrong on Windows](../zurg/setup/windows.md#when-something-is-wrong) covers each case. |
| On Linux, Plex sees an empty folder or can't open it, and `./zurg doctor` says `user_allow_other is not enabled in /etc/fuse.conf; the mount will be visible only to the zurg service user` | Plex runs as a different user than zurg. Let other users in with <code>echo user_allow_other &#124; sudo tee -a /etc/fuse.conf</code>, then run `./zurg service restart` in zurg's folder. |
| In Docker, Plex's libraries go empty after zurg restarts, and `docker exec plex ls /zurg_mnt/zurg` says `Transport endpoint is not connected` | Give Plex's container zurg's folder with `rslave`: `/zurg_mnt:/zurg_mnt:rslave`. [One Docker Compose file](../zurg/guides/docker-compose.md) has it. |
| New things show up in zurg's folders but not in Plex | Do step 4. Until then, press **Scan Library Files** on the library in Plex. |
| zurg says `bad_token` | The Real-Debrid token is wrong or cut short. [Your Real-Debrid API token](real-debrid-api-token.md#when-something-is-wrong) has the fix. |
| Your disk fills up | zurg keeps a copy of what you play, up to 256G by default. Cap it as [Keeping the cache small](../zurg/setup/windows.md#keeping-the-cache-small) (Windows) or [Disk the mount uses](../zurg/setup/linux.md#disk-the-mount-uses) (Linux) shows. |

Still stuck? Ask in the **zurg-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](remote-help.md) says what to include.

## Questions

### Is there a guide to set up DMM, zurg and rclone to stream in Plex?

This page. You don't set up rclone yourself: zurg's installer downloads it and zurg runs it. DMM is where you find releases and add them to your Real-Debrid account ([What DMM is and how to use it](../dmm/index.md)). zurg then shows them in its folders and Plex picks them up.

### Do the movies download to my computer?

No. Plex reads each file from Real-Debrid through zurg when you press play. zurg does keep a cache of what was played, and it can grow large: see the disk row above.

### Can I skip Plex Media Server?

Yes, with rex. [rex with zurg](../rex/with-zurg.md) shows your zurg library in the Plex apps, with no Plex Media Server and no mount. You can also run both: [One Docker Compose file](../zurg/guides/docker-compose.md) runs zurg, Plex Media Server and rex on one machine.

### Does it work with TorBox or Usenet too?

Yes. zurg's installer also offers TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud and Usenet, and puts them all in the same `movies` and `shows` folders. [Providers](../zurg/providers/index.md) has a page for each.
