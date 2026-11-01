---
label: Music with rex
icon: unmute
order: 88
---

# Music with rex

rex can hold a music library that Plexamp, Plex Web and Plex for Android play. rex reads no music folder and no tags. A music addon tells rex about each song and which album it is on, by the album's MusicBrainz release, and Plex fills in the rest: album and song names, covers, the artist's photo and biography, genres and similar artists.

What you get:

- **Albums Plex knows.** An album sent with its MusicBrainz release looks as it would on any Plex server, with Plex's cover and track names. One Plex does not know shows the names and pictures the addon sends.
- **Original quality.** Songs play as they are, FLAC included. An app set to a lower quality gets the song converted, when FFmpeg is set up.
- **Lyrics and loudness**, when the addon sends them: lyrics show with the song, and Plexamp gets each song's loudness for its levelling.
- **Your own plays and playlists.** Plays, ratings and playlists are kept per Plex account, Plexamp's own smart playlists included.

## Before you start

| You need | Why |
|---|---|
| A rex nightly dated 2026.11.02 or newer | Music came in that build |
| rex set up as in [rex with your own app](any-source.md) | That is where the music library shows up |
| A music addon | Any program that sends songs over rex's feed API. [Building rex addons](addons.md#music) says what it sends, if you write your own |
| [Converting video](any-source.md#converting-video-optional), optional | Only for an app set to a lower music quality than the original |

## Step 1. Install rex and add it to a Plex account

Follow [rex with your own app](any-source.md):

1. [Step 1. Install rex](any-source.md#step-1-install-rex), including finding rex's LAN IP. This page writes it as `192.168.1.20`: put yours in its place.
2. [Step 3. Add it to a Plex account](any-source.md#step-3-add-it-to-a-plex-account): register rex on the fresh account and share it with your own.

## Step 2. Point your music addon at rex

Give your addon rex's address, `http://192.168.1.20:32400`, the way its own instructions say. It registers itself with rex and sends its albums.

rex needs a music library for them. A music addon usually declares one, and rex makes it the first time the addon registers. If yours does not, add one in a Plex app signed in as the fresh account: **Add Library**, **Music**, any folder.

**What you should see.** In rex's log:

```
INFO    SOURCES PUT /rex/sources/<addon> -> 200
INFO    FEED <addon> upsert: ...
```

The music library appears in rex, with each album under its artist. A song rex refuses is in the log with why, such as `no music library holds <file>` when there is no music library yet.

## Step 3. Share the music library

The music library is new, so your own account cannot see it yet. Signed in as the fresh account, share it with your own account as in [step 3](any-source.md#share-it-with-your-own-account), and with anyone else you share rex with.

## Step 4. Listen

- **Plexamp**: sign in with your own Plex account and pick rex's music library as your library.
- **Plex Web and Plex for Android**: the music library is with rex's other libraries.

**What you should see.** The albums with Plex's covers and track names, and the artist with a photo. Press play.

## What it cannot do

- **No radio, mixes or stations.** Plexamp's radio, mixes, stations and sonically similar songs need an analysis of every song that rex does not do.
- **No music folder of its own.** rex scans nothing and reads no tags. An addon has to send each song, with its album's MusicBrainz release for Plex to name it.
- **Two copies of an album are two albums**, as on any Plex server: a FLAC copy and an MP3 copy each show as their own album.
- **Tested in Plexamp, Plex Web and Plex for Android.** Other Plex apps, and Plexamp's offline downloads, have not been tried.

To write a music addon of your own, see [Building rex addons](addons.md#music).
