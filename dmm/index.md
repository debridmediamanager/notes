---
label: DMM
icon: search
order: 70
---

# DMM

[Debrid Media Manager](https://debridmediamanager.com) is a website for finding movies and shows and keeping them as a library on your debrid account.

The DMM browser extension adds a button to IMDb, Trakt and other movie and TV sites that opens the title on DMM. To use it in Safari, see [DMM buttons in Safari](../guides/safari.md).

DMM also serves the other projects:

- **zurg** asks DMM which movie or episode each file is, using the DMM API key you get by sponsoring DMM. Without a key zurg works it out from the file names, and fewer titles match. [rex with zurg](../rex/with-zurg.md#why-dmm-places-the-files) shows what that changes.
- **Sonarr, Radarr and Prowlarr** can search DMM as an indexer: Torznab for torrents, Newznab for Usenet. Both need an active sponsorship. Setup is on DMM's own [Torznab](https://debridmediamanager.com/torznab) and [Newznab](https://debridmediamanager.com/newznab) pages.
- **Seerr, Overseerr and Jellyseerr** can use DMM as their Radarr and Sonarr, so requests land on your wanted list for zurg to fetch. Needs an active sponsorship. See [Seerr through DMM](seerr.md).
- **rex-direct** gives a claimed rex its own address and certificate from DMM. See [rex-direct](../rex/with-zurg.md#rex-direct).
