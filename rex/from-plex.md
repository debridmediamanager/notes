---
label: Move from Plex to rex
icon: arrow-switch
order: 87
---

# Move from Plex to rex

You run Plex Media Server today and want to try rex. This page moves you over. The Plex apps stay the same; what changes is where the library comes from and which server your apps talk to.

## What changes

| | Plex Media Server | rex |
|---|---|---|
| Where the library comes from | Plex scans folders on a disk or a mount | A source (your own app, rex-stremio or zurg) tells rex what it has. rex never scans a folder and needs no mount |
| What each file is | Plex matches it from its file name | The source works it out and tells rex. rex never reads a file name |
| A wrong match | Fix Match on the server | **Fix Match** in a Plex app, signed in as the account that owns rex. rex keeps your pick, and a source can take it back and keep it, as zurg does ([why titles are placed as they are](with-zurg.md#why-dmm-places-the-files)) |
| The account the server is on | Usually your own | A fresh Plex account made for rex, shared with your own |
| Music, photos, Live TV and DVR | Yes | No. Movies and TV shows only |

## Pick a way

| | Beside Plex | Instead of Plex |
|---|---|---|
| What you get | rex next to your Plex. Your apps list both servers | rex alone, on Plex's usual port |
| Good for | Trying rex, or keeping Plex for music, photos or Live TV | Moving for good |
| On the same machine as Plex | rex runs on port `32500`, and your apps find it through the Plex account it is shared with | Plex is stopped, rex takes port `32400` and apps at home find it by themselves |

Start beside Plex even if you mean to replace it: copying your watch history needs your old Plex server running. Do steps 1 to 3, use rex for a while, and do step 4 when you are ready.

## Step 1. Set up rex beside Plex

Set rex up with the source that will fill it, as in [rex with your own app](any-source.md), [rex with your Stremio addons](stremio.md) or [rex with zurg](with-zurg.md), up to watching something. Already run zurg for Plex? Skip installing it and update it as step 1 of rex with zurg shows: zurg feeds rex from nightly **2026.10.27** on.

- **Plex runs on the same machine?** Put rex on port `32500`, as [Install rex](any-source.md#step-1-install-rex) says for that case, and give your source that port too.
- **Register rex on a fresh Plex account,** not the one your Plex server is on, as [Add it to a Plex account](any-source.md#step-3-add-it-to-a-plex-account) explains.
- **Away from home with rex-direct?** Your router's port 32400 already goes to Plex. Forward port `32500` to the rex machine as well.

Using zurg? While both run, zurg feeds both. Leave everything zurg has for Plex as it is (`plex_server_url`, `plex_token`, your rclone mount and any scan script): Plex keeps working as before, and `rex_url` adds rex.

## Step 2. Bring your watch history

Once your library is in rex, [Bring your watch history](import-watched.md) copies what you watched, where you stopped and your star ratings from your Plex server. Do it while Plex still runs. Each person you share with runs it for their own history.

## Step 3. Invite your people again

Your friends and family were invited to your Plex server, not to rex. rex is a new server, on the fresh account, so invite them from there and they accept as with any share: [Share rex with family and friends](sharing.md).

## Step 4. Retire Plex (optional)

Only to replace Plex. Skip this to keep both.

**Stop Plex for good.** On Linux, `sudo systemctl disable --now plexmediaserver`. In Docker, stop its container and take it out of your compose file. On Windows and macOS, quit Plex Media Server and take it out of the apps that start when you log in.

**Move rex to port 32400** if it was on `32500` beside Plex on the same machine:

1. Take `--port 32500` out of rex's start command (or the `command:` line in Docker) and restart rex, as [Install rex](any-source.md#step-1-install-rex) shows for your system. On Windows, let 32400 and the two discovery ports through the firewall as that step does.
2. Give your source rex's new address, `http://192.168.1.20:32400` (rex's LAN IP), and restart it: zurg's `rex_url`, or **rex's address** on rex-stremio's settings page.
3. Change `32500` to `32400` anywhere else you gave rex's address, such as Kometa.
4. With rex-direct, point your router's port 32400 forward at the rex machine and remove the `32500` one.

rex then answers on port 32400 and Plex apps at home find it on your network by themselves.

**Using zurg? Tidy its Plex settings.** zurg's config may still point at the Plex you stopped:

| In zurg's `config.yml` | What to do |
|---|---|
| `plex_server_url` and `plex_token` | Delete both, or press **Remove** beside Plex on zurg's dashboard (config page, **Media Server Integration**). Using zurg's [Plex watchlist](../zurg/guides/plex-watchlist.md)? Delete only `plex_server_url`: the watchlist is read from plex.tv with `plex_token` and needs no Plex server. You can instead point them at rex: press **Re-Auth** there, sign in as the fresh account and pick rex. zurg 2026.10.27 and newer sees that the server is rex and sends it no scans, Plex matching, season fix or Plex settings checks. The token is then the fresh account's, so a Plex watchlist would follow that account |
| `on_library_update` running a Plex scan, such as `plex_update.sh` | Delete it. rex hears of every change from zurg directly |
| `plex_database_path`, `plex_scan_check_url` and `plex_scan_check_token` | Delete them. They name the Plex you stopped |
| Your rclone mount (`rclone_enabled: true`, or rclone you run yourself) | Keep it if Sonarr, Radarr, Bazarr or anything else reads files there. If Plex was the only reader, you can turn it off: rex reads each file from zurg directly |

Restart zurg after editing its config.

## What comes along and what does not

| Comes along | How |
|---|---|
| Your movies and shows | Your source sends them to rex. With zurg they come from the same debrid account Plex read |
| What you watched, where you stopped, your star ratings on movies and episodes | [Bring your watch history](import-watched.md), each person on their own |

| Does not come along | Why |
|---|---|
| Fix Matches you made on Plex | rex does not use Plex's matches. Your source says what each file is; fix what it gets wrong with **Fix Match** in rex |
| Collections | Not copied. [Kometa with rex](kometa.md) builds them again from your Kometa config |
| Posters and artwork you picked | Kept on the old server only |
| Playlists, and the server's play history list | Kept on the old server only |
| Your friends' access | They were invited to the old server. Invite them to rex ([step 3](#step-3-invite-your-people-again)) |
| Music and photo libraries, Live TV and DVR | rex has movies and TV shows only. Keep Plex beside rex for them |
| Files on a local disk | rex scans no folders. An app has to serve them and tell rex about them: [rex with your own app](any-source.md) |
