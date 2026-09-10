# zurg for Android and Google TV

The Android app runs its bundled zurg engine on the device. One app adapts to
phones, tablets, Android TV and Google TV. Android 8.0 or newer is required.
Fire TV can sideload the same APK; use a WebDAV player when no system Files app
is installed. Usenet requires 64-bit Android.

## Install and set up

Download an Android APK from the private sponsor repository's nightly release.
Choose `arm64-v8a` for most recent phones and TV boxes, `armeabi-v7a` for older
32-bit devices, or `x86_64` for an emulator or compatible Chromebook. The phone
and TV interfaces are both included in every architecture's APK.

The app does not contain zurg itself. The engine that serves your library is a
second package you install from inside the app after signing in to GitHub, so
the app is not usable without a sponsor account. Setup walks you through it.

Allow installation from the app used to open the APK. Android or Play Protect
may ask you to confirm sideloading. The application ID is
`com.debridmediamanager.zurg`. Updates must retain the release signing identity.

1. Open zurg and sign in to GitHub, then install an engine version. The app
   cannot start a library until an engine is installed.
2. Add provider accounts and test the credentials. Account names distinguish
   multiple accounts at the same provider. Usenet connection limits include
   every other consumer of that account.
3. Choose Phone, Tablet, TV box or TV stick. The profiles set the engine's
   memory target and disk cache sizes. A Go heap target is not a hard RSS cap.
4. Allow notifications and background operation. Enable start after reboot if
   this device should always serve the library.
5. Start the library. A large account's first load can take several minutes.
   The notification and Status screen show when the directories are ready.

## Watch on this device

Use Library to browse folders and play a file. More offers another player or
an Android document URI. The chosen player can become the preferred player.
Files and document pickers expose the same library under the zurg storage root.
Files are streamed with random access; they are not downloaded in full first.
Open your player once and finish its setup before choosing it from Files.

For WebDAV players, add `http://127.0.0.1:9999/dav/` as a source. Use the port
shown in Status if you changed it. VLC, Kodi and Nova can browse a WebDAV source;
players that only accept individual URLs can be launched from Library. On TV,
use the D-pad and Select to move and activate controls, Back to return, and
Menu or More for release actions. Select a text field to edit it and press Back
to return to navigation. Long-press also opens More on a phone.

Repair, rename, tags, show all files and delete operate on the entire owning
release. Deletion asks for confirmation and deletes from its provider account.
MediaInfo uses the bundled ffprobe and opens the resulting video, audio and
subtitle details in the dashboard. No separate media tool installation is needed.

## Share over the local network

In Settings, enable **Expose on local network**. zurg generates credentials and
shows the device's LAN WebDAV address. Enter that address and those credentials
in a player on the other device. Keep the Android host powered and running.
HTTP basic authentication does not encrypt traffic; use a trusted local network.
Loopback is the default. Player intents never contain your server password.

## Settings, backups and updates

Settings covers connection, providers, library, repair, resources and logging.
Advanced accepts raw YAML and asks the bundled engine to validate it before
saving. Saving a running configuration asks before restarting the server.
Web dashboard opens the local dashboard for desktop integration settings.

Logs includes the engine's recent output and the supervisor's last 200 lines.
Shared logs redact configured secrets and URLs. Backups contain credentials and
library state, so save them privately. Stop zurg before restoring. Android
refuses backup links and special files, and restores to loopback first.

Updates checks the private sponsor repository. GitHub device sign-in requests
`repo` scope because the release assets are private. GitHub tokens are encrypted
with Android Keystore-backed preferences. A manually supplied token with read
access to the repository is also supported. If Android can no longer decrypt a
saved sign-in, Updates asks you to sign in again and preserves your library
configuration. Downloaded updates must match the
application ID and signing key and have a newer version code. The Android
installer asks before replacing the app.

Updating from a build that carried its own engine leaves the app without one.
Install an engine from Updates once, and your providers and library settings
carry over untouched.

The app and the engine update separately. Updates lists every engine version
the sponsor repository still publishes, marks the one you have, and installs any
of them. If a new nightly misbehaves on your device, install the one that worked
for you. Stop your library on Status before changing the engine. The app only
runs an engine package signed with its own key, and it checks that again on
every start.

The persistent notification has a Stop action. A Quick Settings tile also
starts or stops the server. Battery exemption helps with Android idle limits;
manufacturer-specific task killers may need additional settings from
[Don't kill my app](https://dontkillmyapp.com/).
