---
label: Android and Google TV
icon: device-mobile
order: 40
---

# zurg+rex for Android and Google TV

zurg+rex is a Plex server on your phone. zurg brings in your debrid accounts and Usenet, and rex serves them to every Plex app in your home, with posters, seasons and watch progress. It runs on a phone, tablet, Android TV, Google TV or Fire TV, with no computer.

It comes with a sponsorship. No sponsorship? [rex for Android](../../rex/android.md) is free and plays what its addons bring.

| The app | In the Plex app | In any other Plex app |
|---|---|---|
| ![Status in zurg+rex with the library ready and rex signed in to Plex](../../assets/zurg/android-status.webp) | ![Big Buck Bunny on its page in the Plex app, served from the same phone](../../assets/zurg/android-plex.webp) | ![The same library of open movies in the Plezy app](../../assets/zurg/android-plezy.webp) |

## Before you start

| You need | Why |
|---|---|
| A device with Android 8.0 or newer | Phone, tablet, Android TV, Google TV or Fire TV. Usenet needs a 64-bit device |
| A sponsorship with your GitHub account linked | The app and its engine download from the sponsor repository. Sponsor and link GitHub on [gatekeeper](https://gatekeeper.debridmediamanager.com/) |
| A debrid account or a Usenet account | What zurg brings in. TorBox hosted NZBs (`torbox_nzb`) are not available on Android |
| A Plex account | rex shows up in the Plex apps signed in to it. A free account is enough |
| Your DMM API key, from gatekeeper (optional) | With it, more titles get their name and poster |

## Step 1. Download it

On the device, open the [download page](https://zurg.debridmediamanager.com/download.html#android), signed in to GitHub with your sponsor account, and pick the file for its processor:

| Your device | File |
|---|---|
| Most phones, tablets and TV boxes (64-bit) | `android-arm64-v8a.apk` |
| Older 32-bit phones and TV sticks | `android-armeabi-v7a.apk` |
| Chromebooks and emulators | `android-x86_64.apk` |

One file works on phones and TVs alike.

**GitHub says 404?** The account you are signed in with has no sponsor access yet. If you just sponsored, [accept the invite](https://github.com/debridmediamanager/zurg/invitations) first; invites go out within 15 minutes.

## Step 2. Install it

Open the downloaded file and allow installation from the app that opened it. Android or Play Protect may ask you to confirm.

**What you should see.** **zurg+rex** in your list of apps.

## Step 3. Sign in to GitHub and install the engine

Open the app. It says **Welcome to zurg+rex.**

1. Press **Sign in with GitHub**. The app shows a code: press **Open GitHub**, enter the code and approve. GitHub asks for `repo` access because the sponsor releases are private.
2. **Install the engine.** The engine is zurg and rex themselves, kept in a package of their own so they update apart from the app. Press **Install**. Android asks before installing it: allow it.

**What you should see.** **Add your providers.**

## Step 4. Add your providers

1. Press **Add an account** and pick the provider.
2. For a debrid account, paste its token into **Provider token**. For Usenet, fill in **NNTP server**, **Port**, **Username**, **Password** and **Connections**.
3. Press **Test account**, then **Add provider**.

Add as many accounts as you have; **Account name** tells two accounts at one provider apart. A Usenet account's connection limit counts every other app and device using it.

## Step 5. Start your library

1. Choose **Phone**, **Tablet**, **TV box** or **TV stick**. Smaller choices use less memory and smaller caches.
2. Allow notifications and let the app run in the background. Turn on **Start after reboot** if this device should always serve your library.
3. Press **Start my library**.

**What you should see.** **Status** says **Ready for your players** and counts your releases. A large account's first load can take several minutes.

## Step 6. Sign in to Plex

On **Status**, under **rex for the Plex apps**, press **Sign in to Plex**.

- **On a phone or tablet** your browser opens Plex's sign-in page. Sign in there.
- **On a TV** the app shows **On any device, go to plex.tv/link and enter** a code. Enter it on your phone or computer.

Use the account your Plex apps are signed in to.

**What you should see.** **Ready for the Plex app**, with an **Open Plex** button when Plex is on this device.

## Step 7. Watch in a Plex app

Open any Plex app signed in to the same account: on this device, your TV, another phone or a computer at home. Your server is listed under this device's name, with the libraries **Debrid Movies** and **Debrid TV**. Press play.

rex converts what a player cannot play, using the device's own video encoder.

## Get more titles named

Open **Settings**, **Library** and paste your DMM API key into **Dmm api key**, then save. zurg then asks DMM what each file is. Without the key, zurg works it out from the release name, and fewer titles get their name and poster.

A title that still looks wrong can be corrected in a Plex app: open its **⋯** menu and choose **Fix Match**.

The field is in nightlies from 14 November 2026. In an older one, add `dmm_api_key: YOUR_DMM_API_KEY` in **Settings**, **Advanced**. The same key reads your [DMM wanted list](dmm-wanted.md).

## Addons

Addons bring more to watch into rex, beside your library. Open **Addons**: the Internet Archive addon comes installed and adds public domain films, and the [rex-addons](https://github.com/debridmediamanager/rex-addons) repository is already listed. Add another repository by its link, open it and install what it offers.

Each addon says which websites it can reach, and an update that reaches new ones asks first. Install addons only from people you trust. **Log** shows what an addon did lately. Removing an addon takes only its titles away.

## Other players on this device

You don't need a Plex app to watch.

- **Library** browses your folders and plays a file in the player you pick. **More** offers another player and the release's actions: repair, rename, tags, show all files and delete. They act on the whole release, and delete asks first and deletes it from your provider account.
- The **Files** app and document pickers show the same library under the zurg root. Open your player once and finish its setup before choosing it from Files.
- WebDAV players such as VLC, Kodi and Nova take `http://127.0.0.1:9999/dav/` as a source. **Status** shows the address if you changed the port.

On a TV, move with the D-pad and Select, go back with Back, and open a release's actions with Menu or **More**. Select a text field to type in it and press Back to move on.

## Share with other players at home

Plex apps at home need nothing more: they find rex by themselves. For a WebDAV player on another device, open **Settings**, **Connection** and turn on **Expose on local network**. zurg makes a username and password and shows the address to enter in that player.

Use this on a network you trust: the password travels unencrypted. It is off unless you turn it on.

## Keep it running

- The notification shows the server's state and has **Stop**. A Quick Settings tile starts and stops it too.
- Some phones stop background apps anyway. [Don't kill my app](https://dontkillmyapp.com/) explains what yours needs.
- **Updates** checks for a new app and a new engine; they update separately. If a new nightly misbehaves on your device, press **Show engine versions** and install the one that worked. Stop your library on **Status** first.
- **Settings** has a **Create backup** and **Restore backup**. A backup holds your passwords and tokens, so keep it private. Stop your library before restoring.
- Turn rex off in **Settings**, **Connection**, **rex for the Plex apps**. zurg then stops feeding it.

## What the app sends and where

zurg+rex has no ads and no analytics. This is everything that leaves your device:

| Where | What | When |
|---|---|---|
| GitHub | Your sign-in, then requests for the sponsor releases | When you sign in and when **Updates** checks |
| Your providers | Your account token or Usenet login, and requests for your library and files | While your library runs |
| debridmediamanager.com | The names of your releases, to learn what each one is, with your DMM API key if you entered it | While your library runs with rex on |
| plex.tv and Plex's metadata service | A sign-in code request; then the server's name, address and the ids of your titles, to fetch posters and descriptions | When you sign in to Plex, and while rex runs signed in |
| debridmediamanager.com (rex-direct) | rex's identifier, the server token Plex gave it, its IP addresses and port, so Plex apps can reach it over HTTPS | Once signed in to Plex, then every 6 hours |
| Each addon's websites and the repositories you add | What the addon asks for | When an addon syncs or a title plays |
| logs.debridmediamanager.com | Versions, device model, the app's and engine's logs and your config, with keys, passwords and tokens replaced by `[redacted]` | Only when you press **Send** under **Send logs to support**, after seeing all of it. Deleted after 7 days |

Your GitHub token is stored encrypted on the device. Uninstalling the app deletes everything it kept.

## Limits

- **The device is the server.** Keep it on, connected and plugged in. Converting video is slow on a cheap box.
- **It plays at home.** Away from home, Plex apps need an HTTPS address that reaches the device, which needs a port forward on your router. See [Use it outside your home](../../rex/with-zurg.md#use-it-outside-your-home-optional).
- **Usenet needs 64-bit Android.** A 32-bit device runs debrid libraries only.
- **Not on Google Play.** It updates from inside the app, under **Updates**.

## Troubleshooting

| What you see | What to do |
|---|---|
| GitHub answers 404 on the download page | Sign in to GitHub with your sponsor account and [accept the invite](https://github.com/debridmediamanager/zurg/invitations). Not a sponsor yet: [gatekeeper](https://gatekeeper.debridmediamanager.com/) |
| **No engine is installed. zurg needs one before it can serve your library.** | Press **Install an engine** and allow Android to install it |
| **No engine is available in the sponsor releases for this device yet.** | The newest nightly has no engine for your processor. Ask in support |
| **This is a 32-bit device. Debrid libraries are supported; Usenet needs 64-bit Android.** | Add a debrid account, or use a 64-bit device for Usenet |
| **The Plex code expired. Ask for a new one.** | Press **Sign in to Plex** again and enter the new code within 10 minutes |
| The server isn't in the Plex app | Sign the Plex app in to the account you used in Step 6, and keep both devices on the same home network |
| Titles show a file name and no poster | Enter your DMM API key (see [Get more titles named](#get-more-titles-named)), or use **Fix Match** in a Plex app |
| It stops when the screen is off | Allow background use again and see [Don't kill my app](https://dontkillmyapp.com/) |
| An update leaves the app without an engine | Install an engine from **Updates** once. Your providers and settings stay |

If support asks for logs, open **Logs** and press **Send logs to support**. You see everything before anything is sent, then press **Send** and post the code you get.

Stuck? Ask in the **zurg-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP).
