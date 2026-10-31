---
label: DMM
icon: search
order: 70
---

# DMM

[Debrid Media Manager](https://debridmediamanager.com) is a website for finding movies and shows and keeping them as a library on your debrid account.

The DMM browser extension adds a button to IMDb, Trakt and other movie and TV sites that opens the title on DMM. To use it in Safari, see [DMM buttons in Safari](safari.md).

DMM also serves the other projects:

- **zurg** asks DMM which movie or episode each file is, using the DMM API key [gatekeeper](https://gatekeeper.debridmediamanager.com/) shows you once you sponsor DMM. Without a key zurg works it out from the file names, and fewer titles match. [rex with zurg](../rex/with-zurg.md#why-dmm-places-the-files) shows what that changes.
- **Sonarr, Radarr and Prowlarr** can search DMM as an indexer: Torznab for torrents, Newznab for Usenet. Both need an active sponsorship and take your DMM API key, which [gatekeeper](https://gatekeeper.debridmediamanager.com) shows once you press **Connect GitHub** (Patreon sponsors link Patreon after that). Setup is on DMM's own [Torznab](https://debridmediamanager.com/torznab) and [Newznab](https://debridmediamanager.com/newznab) pages.
- **Your wanted list**: press **Want** on a film or show, or follow a Trakt or MDBList list, and zurg fetches it, with new episodes as they air. Needs an active sponsorship. See [DMM wanted list](../zurg/guides/dmm-wanted.md).
- **Seerr, Overseerr and Jellyseerr** can use DMM as their Radarr and Sonarr, so requests land on your wanted list for zurg to fetch. Needs an active sponsorship. See [Seerr through DMM](seerr.md).
- **rex-direct** gives a claimed rex its own address and certificate from DMM. See [rex-direct](../rex/with-zurg.md#rex-direct).

Stuck? Ask in the **dmm-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) says what to include.
