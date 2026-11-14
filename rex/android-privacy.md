# rex for Android: privacy policy

*Last updated: 14 November 2026.*

rex for Android runs a media server on your device. It has no account with us, no ads and no
analytics, and it does not send us your library, your viewing or anything about you, except
for rex-direct and the logs you choose to send, both named below.

## What leaves your device, and where it goes

| Where | What | When |
|---|---|---|
| **plex.tv** (Plex, Inc.) | A sign-in code request with a random app identifier and this server's name; then, once you approve it, a one-time request for a claim code | When you choose Sign in to Plex |
| **plex.tv** | The server's name, identifier, version and the addresses the Plex apps can reach it at | While rex runs and is signed in, as any Plex server reports itself |
| **Plex's metadata service** | The ids of the titles your addons add, to fetch posters and descriptions | While rex runs and is signed in |
| **debridmediamanager.com** (rex-direct) | The server's identifier, the server token Plex gave it, its local and public IP addresses and its port | Once signed in, then every 6 hours, so the Plex apps can reach rex over HTTPS away from home |
| **logs.debridmediamanager.com** (support logs) | The app's and rex's versions, the device model, Android version and processor type, rex's port and state, each addon's name, version, repository, state, title count, last sync and last error, the time zone offset, and the app's logs of this run and the previous one, with tokens, keys, passwords and the last two parts of public IP addresses hidden. Never your addon settings, your Plex account or tokens | Only when you press Send under Send logs to support, after seeing all of it. You get a code to give support; only support staff can read it, and it is deleted after 7 days |
| **Addon repositories you add** (such as github.com) | A request for the repository's contents | When you add or refresh a repository |
| **Each addon's sites** | What the addon asks for, such as a catalog request to archive.org | When an addon syncs or a title plays |

Your Plex account password never passes through the app: you sign in on Plex's own page. The
account token that sign-in gives the app is used once to claim the server, then discarded. rex
keeps only the server token Plex issues for it.

## What stays on your device

Your libraries, watch history, addon settings (including any keys you type in) and logs. The
app keeps the logs of this run and the previous one so a crash doesn't lose them. Logs hide
tokens, keys, passwords and the end of public IP addresses, and they leave the device only if you
choose Share or Send logs to support on the Logs screen. Uninstalling the app deletes all of it.

## Addons

An addon is code from whoever wrote it, installed from a repository you added. It runs sealed
off from the rest of your device and can only reach the sites it names, which rex shows you
before you install it. Install addons only from people you trust.

## Children

The app is not directed at children.

## Contact

support@debridmediamanager.com
