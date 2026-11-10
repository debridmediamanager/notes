# Music with rex

rex can hold a music library for Plexamp Plex Web and Plex for Android. A music addon sends each song and its
MusicBrainz release. Plex fills in names covers artist details genres and similar artists.

What you get:

- **Albums Plex knows.** An album sent with its MusicBrainz release looks as it would on any Plex server, with Plex's cover and track names. One Plex does not know shows the names and pictures the addon sends.
- **Original quality.** Songs play in their own format, such as FLAC.
- **Lyrics and loudness**, when the addon sends them: lyrics show with the song, and rex passes each song's loudness to the apps, as Plex does.
- **Your own plays and playlists.** Plays, ratings and playlists are kept per Plex account. Plexamp makes its smart playlists on rex too.

## Before you start

| You need | Why |
|---|---|
| A rex nightly dated 2026.11.02 or newer | Music came in that build |
| rex set up as in [rex with your own app](any-source.md) | That is where the music library shows up |
| A music addon | Any program that sends songs over rex's feed API. For a folder of albums on your own disks, [Tutorial: a music addon](addon-music.md) is a complete one in one Python file |
| [Converting video](any-source.md#converting-video-optional), optional | rex converts a song only for an app set to a lower music quality than the original |

## Step 1. Install rex and add it to a Plex account

Follow [rex with your own app](any-source.md):

1. [Step 1. Install rex](any-source.md#step-1-install-rex), including finding rex's LAN IP. This page writes it as `192.168.1.20`: put yours in its place.
2. [Step 3. Add it to a Plex account](any-source.md#step-3-add-it-to-a-plex-account): register rex on the fresh account and share it with your own.

## Step 2. Point your music addon at rex

rex needs a music library for the songs. If your addon declares one, rex makes it when the addon registers. If it does not, add one first in a Plex app signed in as the fresh account: **Add Library**, **Music**, any folder. A song sent before there is a music library is refused.

Then give your addon rex's address, `http://192.168.1.20:32400`, the way its own instructions say. It registers itself with rex and sends its albums.

**What you should see.** In rex's log:

```
INFO    SOURCES PUT /rex/sources/<addon> -> 200
INFO    SECTION create Music (artist) for <addon>'s music
INFO    FEED <addon> upsert: ...
```

The `SECTION create` line shows only when the addon declares the library. The music library appears in rex, with each album under its artist. A song rex refuses is in the log with why, such as `no music library holds <file>`.

## Step 3. Share the music library

The music library is new, so it is in nobody's share yet. Signed in as the fresh account, add it to your own account's share and to everyone else's in **Manage Library Access** ([Share rex](sharing.md)).

## Step 4. Listen

- **Plexamp**: sign in with your own Plex account and pick rex's music library as your library.
- **Plex Web and Plex for Android**: the music library is with rex's other libraries.

**What you should see.** The albums with Plex's covers and track names, and the artist with a photo. Press play.

## What it cannot do

- **No radio, mixes or stations.** Plexamp's radio, mixes, stations and sonically similar songs need an analysis of every song that rex does not do.
- **No music folder of its own.** rex scans nothing and reads no tags. An addon has to send each song, with its album's MusicBrainz release for Plex to name it.
- **Two copies of an album are two albums**, as on any Plex server: a FLAC copy and an MP3 copy each show as their own album.
- **Tested in Plexamp, Plex Web and Plex for Android.** Other Plex apps, and Plexamp's offline downloads, have not been tried.

To write a music addon of your own, start from [Tutorial: a music addon](addon-music.md); [Building rex addons](addons.md#music) has every field.
