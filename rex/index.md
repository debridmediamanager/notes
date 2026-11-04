---
label: rex
icon: server
order: 80
---

# rex

[rex](https://rex.debridmediamanager.com) is a media server for the official Plex apps that owns no files. The apps see it as a normal server. Another program tells rex what is in your library and serves the files, and when you press play rex streams the file straight from that program. rex is free for personal use, and its [source code](https://github.com/debridmediamanager/rex) is public under the PolyForm Noncommercial license. It runs on Linux, macOS and Windows, and on Linux also as the Docker image `ghcr.io/debridmediamanager/rex:nightly` ([with your own app](any-source.md#run-rex-in-docker), [with zurg](with-zurg.md#run-rex-in-docker)).

- [rex questions](faq.md) answers what to know before you install
- [rex with your own app](any-source.md) sets rex up from scratch, filled by any app that serves files over HTTP and speaks rex's feed API
- [rex with your Stremio addons](stremio.md) fills rex from your Stremio addons' catalogs with rex-stremio, free and with no sponsorship
- [rex with zurg](with-zurg.md) sets rex up with zurg filling it from your debrid account or Usenet
- [Live TV with rex](live-tv.md) puts live channels in Plex Web's and Plex for Android's Live TV, with a guide, through rex-live-sports
- [Music with rex](music.md) gives Plexamp, Plex Web and Plex for Android a music library from a music addon
- [Move from Plex to rex](from-plex.md) runs rex beside or instead of your Plex server, and says what to keep and what to turn off
- [Share rex with family and friends](sharing.md) invites the people you watch with
- [Building rex addons](addons.md) brings home videos, recordings or Stremio catalogs into rex with a program of your own
- [Tutorial: home videos addon](addon-home-videos.md), [music addon](addon-music.md) and [IPTV addon](addon-iptv.md) build complete addons in one Python file each
- [More from your addon](addon-more.md) adds subtitles, extras, chapters, collections, playlists and the rest
- [Bring your watch history](import-watched.md) copies what you watched, where you stopped and your ratings from your old Plex server
- [Kometa with rex](kometa.md) builds collections and poster badges on your rex libraries
- [Apps download from your provider](direct-download.md) has Plex apps download from the link your source gives, such as your debrid service's, so the rex machine carries no movie
