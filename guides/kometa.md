# Kometa with rex

[Kometa](https://kometa.wiki) builds collections, puts badges on posters (4K, HDR, ratings) and fills in ratings and genres on a Plex server. rex answers Kometa the way a Plex server does, so the same config works on your rex libraries.

Everything below was tested on 2026-10-23 with Kometa 2.5.3 (the `kometateam/kometa` Docker image), and a claimed rex holding films and a show.

## Before you start

| You need | Why |
|---|---|
| rex set up and added to a Plex account, as in [rex step 3](rex.md#step-3-add-it-to-a-plex-account) | Kometa edits the library, and only the account rex is registered on may do that. An unclaimed rex serves nobody |
| rex 2026-10-24 nightly or later | Update as in [rex's Updating section](rex.md#updating) |
| Docker on any machine that can reach rex | Kometa runs as a container. Kometa's own docs cover [other ways to install it](https://kometa.wiki/en/latest/kometa/install/overview/) |
| A free TMDb API key | Kometa needs one for itself, even though rex does not. Make one under **Settings → API** on themoviedb.org, as [TMDb's getting started page](https://developer.themoviedb.org/docs/getting-started) describes |

## 1. Get rex's token

Kometa signs in to rex with a Plex token. Use the token rex was given when you registered it. On the rex machine:

```bash
grep -o '"token": "[^"]*"' ~/rex/claim_state.json
```

With [rex in Docker](rex.md#run-rex-in-docker) the file is root-only: `sudo grep -o '"token": "[^"]*"' ~/rex/config/claim_state.json`.

**What you should see.** One line, `"token": "..."`. Copy what is between the second pair of quotes. Treat it like a password: it opens the whole server. If you ever register rex again, it changes and Kometa needs the new one.

**Not your own account's token.** In [step 3](rex.md#share-it-with-your-own-account) your own account got rex as a share. A share can watch but not edit, so with its token Kometa stops with `Plex Token is read only`, or, if the share allows downloads, fails at its first change.

## 2. Write Kometa's config

Make a folder for Kometa, for example `~/kometa/config`, and put this in `~/kometa/config/config.yml`:

```yaml
libraries:
  Movies:
    collection_files:
      - default: genre
    overlay_files:
      - default: resolution
      - default: ratings
        template_variables:
          rating1: critic
          rating1_image: tmdb
    operations:
      mass_critic_rating_update: tmdb
  TV Shows:
    overlay_files:
      - default: resolution
plex:
  url: http://192.168.1.20:32400
  token: the token from step 1
tmdb:
  apikey: your TMDb API key
```

- `url` is rex's LAN IP and port, the address from [rex step 2](rex.md#step-2-install-rex). Not `127.0.0.1` or `localhost`: inside Kometa's container those point at the container itself.
- The names under `libraries:` must match rex's libraries exactly: **Movies** and **TV Shows**, plus any you added or renamed. Leave out a library you do not want Kometa to touch.

This is a small start. Kometa's docs list [every default collection and overlay](https://kometa.wiki/en/latest/defaults/guide/), and your own collection files work too.

## 3. Run it once

```bash
docker run --rm -v ~/kometa/config:/config kometateam/kometa:latest --run
```

`--run` makes Kometa do one pass now and exit. Without it Kometa stays running and waits for its daily schedule.

**What you should see.** In Kometa's output, for each library:

```
Movies Library Connection Successful
...
Overlays Applied: Overlay File (0) 1080P, Overlay File (1) Rating1Fresh
```

In a Plex app, the movie library has a **Collections** tab with the genre collections, and the posters carry their badges. Your own account and everyone else you shared rex with see the same collections and badges. A first run on a large library takes a while: Kometa reads every title and redraws every poster it badges.

## If it does not work

| Kometa says | What it means |
|---|---|
| `Plex Token is read only. Please get a new token` | rex is not added to a Plex account yet, or the token is your own account's rather than the one from step 1 |
| Kometa connects, then every change fails | The token is your own account's. Use the one from step 1 |
| `url_poster failed to update poster` | The rex machine cannot reach the site the image is on |
| `Plex URL is probably invalid` or a timeout | `url` does not reach rex from where Kometa runs. Open `http://192.168.1.20:32400/identity` from that machine: it should show rex's `machineIdentifier` |
| `Plex Error: Plex Library '...' not found. Options: [...]` | A name under `libraries:` does not match. Copy one from the list it prints |

## What Kometa can and cannot see

Kometa matches titles by the TMDb, TVDb and IMDb ids rex shows for them. A title rex could not identify, still showing its file name and no poster, has none, so Kometa leaves it out of anything built from those ids. Fix Match it in a Plex app first.

Tested on rex: collections by title search, by TMDb id and smart collections; the genre default collections with their posters; the resolution and ratings overlays; and critic rating and genre updates from TMDb. Not tested yet: playlists, music libraries and Kometa's other operations. If one fails, Kometa's own log names the request that did, and that is worth reporting on Discord.
