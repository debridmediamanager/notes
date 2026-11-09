---
label: Bring your watch history
icon: history
order: 85
---

# Bring your watch history to rex

rex starts with no watch history. It can copy watched titles resume points and star ratings from another Plex server.
Watched titles stay watched. Part-watched titles return to **Continue Watching**. Shows and seasons count their episodes again.

Run it once from any computer at home. Everyone who uses rex can import their own history.

## Before you start

| You need | Why |
|---|---|
| rex set up, with your library in it, as in [rex with your own app](any-source.md), [rex with your Stremio addons](stremio.md) or [rex with zurg](with-zurg.md) | rex copies history only onto titles it already has. If your library is still filling, run the import again later: it only adds what is new |
| rex nightly **2026.10.31 or newer** | Update as in [rex's Updating section](any-source.md#updating) |
| Your old Plex server, running | rex reads the history from it. Start it again if you stopped it when you moved to rex |
| A computer on your home network, with `curl` | The import only runs from your home network. Windows 10 and 11, macOS and Linux all have `curl` |

## 1. Copy your old server's address

1. Open [app.plex.tv](https://app.plex.tv) in a browser and sign in as **yourself**, the account whose history you want.
2. Pick your old server and open any movie on it.
3. Click **⋯** (More), then **Get Info**.
4. Click **View XML** at the bottom left of the **Media Info** box that opens. A new tab opens, full of text.

   ![The Media Info box that Get Info opens, with View XML at the bottom left](../assets/rex/40-plex-get-info.webp)
5. Copy the **whole address** from that tab's address bar.

It looks like this, all on one line, and it ends with `X-Plex-Token=` followed by a code:

```
https://192-168-1-5.0123456789abcdef.plex.direct:32400/library/metadata/1234?checkFiles=1&includeAllConcerts=1&X-Plex-Token=AbCdEfGh1234567890xy
```

That code is your **Plex token** for that server. It works like a password for your Plex account: never paste it into Discord, a support post or a screenshot.

**No View XML in step 4?** Plex Web shows it only on a server you own, so a server someone shared with you has none. Use the browser's developer tools on your old server instead, as in [step 2](#2-get-your-token-on-rex), and pick a request to your old server (its address has `plex.direct` in it). Right-click it and copy its address: **Copy**, **Copy URL** in Chrome and Edge, **Copy Value**, **Copy URL** in Firefox. That address is the one you need. It has `X-Plex-Token=` and the code among other `X-Plex-` parts: paste all of it.

## 2. Get your token on rex

rex is shared with you, so **Get Info** on rex has no **View XML**: Plex Web shows it only to a server's owner. Read the token from your browser instead, as app.plex.tv sends it to rex:

1. In app.plex.tv, still signed in as yourself, open the browser's developer tools: **F12**, or **⌥ ⌘ I** on a Mac. In Safari, first turn on **Show features for web developers** in **Settings**, **Advanced**.
2. Open the **Network** tab and type `X-Plex-Token` in its filter box.
3. Open any movie on the **rex** server. The list fills with requests.
4. Click one whose address is rex's: with rex-direct it has `rex-direct.debridmediamanager.com` in it, or it is the HTTPS address you set up yourself. Not one to `plex.tv`.
5. Copy the value of `X-Plex-Token`: Chrome and Edge show it under **Payload**, Firefox under **Request**. Or copy the request's address and take the part after `X-Plex-Token=` up to the next `&`.

It is a different code from the one in step 1: each server gives your account its own. rex uses this one to know whose history it is.

## 3. Run the import

On a computer at home, run this with your two values pasted in. `192.168.1.20` stands for rex's LAN IP, as in the setup guides: put yours in its place.

```bash
curl -d "ADDRESS-FROM-STEP-1" "http://192.168.1.20:32400/rex/import-watched?X-Plex-Token=TOKEN-FROM-STEP-2"
```

On Windows, open **PowerShell** and type `curl.exe` instead of `curl`. Keep both pairs of double quotes: the address from step 1 contains `&` characters, which break the command without them.

It takes a few seconds, longer for a large library: rex reads every movie and episode on the old server.

**What you should see.** One line like this:

```json
{"watched":412,"inProgress":7,"rated":38,"alreadyHere":0,"notInRex":55}
```

| Number | Means |
|---|---|
| `watched` | Titles rex marked watched, with the old server's play count and date |
| `inProgress` | Titles you were part-way through: they resume where you stopped |
| `rated` | Titles that got their star rating |
| `alreadyHere` | Titles you had already watched or started on rex. rex keeps what it has and changes nothing there |
| `notInRex` | Titles the old server has history for that rex does not have, or not as the same title |

Open your Plex app again (or reload app.plex.tv) to see it.

## Run it again any time

Running it again changes nothing you already have, so run it whenever more of your library has arrived. A second run straight after the first shows `"watched":0` and the earlier ones under `alreadyHere`.

## What is not copied

- History of anyone else on your old server. Each person runs the import with their own two tokens.
- The server's play history list, playlists and collections.
- Star ratings on whole shows and seasons. Ratings on movies and episodes are copied.
- Titles in a library whose agent on the old server is not **Plex Movie** or **Plex TV Series** (the older agents, such as Plex Movie (Legacy) and TheTVDB). rex finds a title by the id Plex's current agents give it, and the older ones give another, so these count under `notInRex`.

## If it does not work

| What you see | What to do |
|---|---|
| `that address has no X-Plex-Token: copy it whole from the tab View XML opens` | The pasted address stops before the token. Copy it again, from the address bar or the developer tools, and paste all of it |
| `send the address View XML opens on your old Plex server, starting http:// or https://` | Something other than the address went into the quotes after `-d` |
| `... refused the token: copy the address from View XML again` | The old server did not accept the token. Do step 1 again, with the developer tools if the server is shared with you |
| `could not reach https://...` | rex could not connect to your old server. It has to be running, and **the rex machine** has to reach it: rex reads from it, not your computer |
| `run the import from your home network` | You sent the command to rex's outside address. Use rex's LAN IP, as in step 3 |
| An `Unauthorized` page | rex did not accept the token from step 2. Copy it again, from a request to rex, not to `plex.tv` |
| `notInRex` is much higher than you expect | Most of your library is not in rex yet, or your old library uses one of Plex's older agents. Run it again once your library has arrived |

Still stuck? Ask in the **rex-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) says what to include.
