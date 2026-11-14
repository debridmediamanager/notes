# rex for Android

rex is a media server for the Plex apps that owns no files. rex for Android runs it on a phone, tablet, Android TV, Google TV or Fire TV, with no computer. The Plex apps on your devices find it like any Plex server and play from it.

What it plays comes from **addons**. It starts with the Internet Archive's public domain films. More addons, such as your Stremio addons, YouTube and Spotify, install from inside the app once you add their repository.

rex for Android is free. Want your debrid accounts and Usenet in it too? zurg+rex, a Plex server on your phone with zurg built in, comes with a sponsorship: see [zurg+rex for Android](../zurg/guides/android.md).

## Before you start

| You need | Why |
|---|---|
| A device with Android 8.0 or newer | Phone, tablet, Android TV, Google TV or Fire TV |
| A Plex account | rex shows up in the Plex apps signed in to it. A free account is enough |
| A Plex app on the device you watch on | Plex for Android, Android TV, iPhone, a smart TV, Plex Web, Plexamp |

It is not on Google Play yet. You install the app file (APK) yourself.

## Step 1. Download it

On the device, download the file for its processor. Each link is always the newest version:

| Your device | Download |
|---|---|
| Most phones, tablets and TV boxes (64-bit) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| Older or cheaper 32-bit boxes, Fire TV Sticks among them | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| Emulators on a PC | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

Every version and its changes are on [the releases page](https://github.com/debridmediamanager/rex-android/releases).

Not sure? Try `arm64-v8a` first. One file works on phones and TVs alike.

## Step 2. Install it

Open the downloaded file. Android asks first:

1. It says it **isn't allowed to install unknown apps from this source**. Press **Settings**, turn on **Allow from this source** and go back.
2. Press **Install**.

On a TV box without a browser, download the file with a downloader app that can open APKs.

**What you should see.** **rex** in your list of apps.

## Step 3. Start rex

Open **rex**. The first screen says **Welcome to rex.**

1. Press **Allow notifications**, then **Allow**. rex runs in the background with a notification you can stop it from.
2. Press **Let rex keep running in the background**. In the list that opens, pick **rex** and choose **Don't optimize**. On newer Android it is **Allow background usage**, then **Unrestricted**. Go back to rex. Both buttons now start with a ✓.
3. **Name** is what the Plex apps call this server. Change it if you like.
4. Leave **Port** at `32400`. If another Plex server already runs on this device, rex says **Another app here already uses this port, maybe a Plex server. Try 32500.** Type `32500`.
5. Press **Start rex**.

**What you should see.** **2 / 2** and **Sign in to Plex.**

## Step 4. Sign in to Plex

Press **Sign in to Plex**. rex shows a code: **On any phone or computer, go to plex.tv/link and enter** it.

- **On a phone or tablet** your browser also opens a Plex page that says **rex for Android would like to sign in to your Plex account**. Sign in there.
- **On a TV** go to [plex.tv/link](https://plex.tv/link) on your phone or computer, sign in and enter the code.

Use the account your Plex apps are signed in to. You can press **Skip for now** and sign in later from **Status**.

**What you should see.** **Signed in. rex shows up in the Plex apps as** your server's name. Press **Done**. **Status** says **RUNNING** and **Ready for the Plex apps.**

## Step 5. Watch in a Plex app

Open any Plex app signed in to the same account. If Plex is on this device, **Status** has an **Open Plex** button.

In Plex for Android open **Libraries**, **All Libraries**, then **Movies** under your server's name. Other Plex apps list it under the server's name too.

The Internet Archive's first sync takes a while: about half an hour on our test device, while rex checks each film. **Status** shows **Syncing** until it is done and then the count, like **Ready · 97 titles**. Press play on any film.

## Addons

**Addons** lists what you installed. Each shows its titles and when it last synced. Its buttons are **Sync now**, **Settings**, **Log** and **Remove**; on a phone, swipe the row of buttons sideways to see them all. The **Enabled** switch turns an addon off without removing it.

Addons come from **repositories**: git repositories that hold addons. The app starts with [rex-addons](https://github.com/debridmediamanager/rex-addons) added, which offers Internet Archive's public domain films, installed from the start. For more, add [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons) (see **Add a repository** below), which offers:

| Addon | What it brings |
|---|---|
| Stremio addons | Your Stremio addons' film and series catalogs, played from the streams your stream addons give |
| YouTube | Your YouTube playlists. You sign in with a code |
| Spotify | Your Spotify library as music for Plex and Plexamp. Needs the YouTube addon, signed in |

**Install one.** Under **Repositories**, press **Addons** next to a repository, then **Install** under the addon. rex shows which websites it can reach and asks once more, then starts syncing it.

**Sign in.** An addon that needs your account says **Sign in to start.** Press its **Sign in** button: go to the page it names on any device and enter the code shown.

**Add a repository.** Under **Add a repository**, type its link (`github.com/user/repo` is enough) and press **Add**. Install only from people you trust. To write your own addon see [rex-addons](https://github.com/debridmediamanager/rex-addons).

## Watch on other devices at home

Every Plex app signed in to the same account finds rex on your home network by its name: your TV, another phone, Plex Web on a computer. **Status** shows rex's address at home, like `http://192.168.1.20:32400`.

To let family watch with their own Plex accounts, see [Share rex with family and friends](sharing.md).

## Keep it running

- rex runs while the device is on. The notification's **Stop** stops it; **Status** has **Start**, **Stop** and **Restart**.
- In **Settings**, turn on **Start when this device turns on**. Otherwise open rex and press **Start** after a restart.
- Some phones still stop background apps. [Don't kill my app](https://dontkillmyapp.com/) explains what yours needs.
- To rename the server, open **Settings**, **General** in a Plex app and change **Friendly name**.

## Limits

- **It plays at home.** Away from home, Plex apps need an HTTPS address that reaches the device, which needs a port forward on your router to it. See [Use it outside your home](any-source.md#use-it-outside-your-home-optional).
- **The device is the server.** Keep it on, on Wi-Fi or Ethernet, and plugged in. Converting video for a player that can't play a file uses the device's own hardware and can be slow on a cheap box.
- **Only what addons bring.** It has no library of files on the device itself.
- **Not on Google Play yet.** To update, install the new file from [the releases](https://github.com/debridmediamanager/rex-android/releases/latest) over the old one, then open rex and press **Start**. Your sign-in and addons stay.

## Troubleshooting

| What you see | What to do |
|---|---|
| **App not installed as app isn't compatible with your phone.** | You picked the wrong file for the processor. Try the other one from the table in Step 1 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | Type `32500` as the port |
| **Use a number from 1024 to 65535** | The port must be a number in that range |
| The server isn't in the Plex app | Sign the Plex app in to the same account you used in Step 4, and keep both devices on the same home network |
| The library is empty | The first sync is still running: wait until **Status** shows a number of titles |
| **Sign in needed** under an addon | Press its **Sign in** button and enter the code |
| **That isn't a repository link. Try github.com/user/repo.** | Type the repository's link, such as `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | The link is wrong or the repository is private. Check it in a browser |
| rex stops when the screen is off | Redo Step 3's background setting, and see [Don't kill my app](https://dontkillmyapp.com/) |

**Logs** shows what rex and the addons said lately, with keys and passwords hidden. If support asks for logs, press **Send logs to support**: you see everything before anything is sent, then press **Send** and post the code you get.

What the app sends and where is in its [privacy policy](android-privacy.md).

Stuck? Ask in the **rex-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP).
