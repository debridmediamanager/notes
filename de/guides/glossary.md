# Was jedes Teil macht {#what-each-piece-does}

Die Namen sagen nicht direkt, was sie tun. Deshalb hier eine Zeile zu jedem. Welche du brauchst, findest du unter [Choose your setup](choose-your-setup.md).

## Die drei Projekte {#the-three-projects}

| Name | Was es macht |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Eine Website, um Releases zu finden und sie zu deinem Debrid-Konto hinzuzufügen. Sie durchsucht auch Usenet und Easynews. Kostenlos |
| [zurg](../zurg/index.md) | Jedes Debrid-Konto und Usenet in einem Ordner. Plex, Jellyfin, Emby, Infuse und rex lesen diesen Ordner wie ein normales Laufwerk. Für Sponsoren |
| [rex](../rex/index.md) | Ein Medienserver, der keine Dateien besitzt. Seine Quellen sagen ihm, was sie haben, und jede Plex-App spielt ihn ab. Kostenlos für den persönlichen Gebrauch |

## Direkt in DMM streamen {#watching-straight-from-dmm}

Für keines davon ist ein Server nötig.

| Name | Was es macht |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio/) | Ein Stremio-Addon, das Releases aus deinem Debrid- oder Easynews-Konto abspielt |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Durchsuche, suche und spiele Inhalte aus deinem Debrid- oder Easynews-Konto direkt in Kodi ab |
| DMM Watch | Ein Button in DMM, der eine Datei in deinem eigenen Player öffnet, zum Beispiel VLC oder Infuse |
| [DMM Music](https://debridmediamanager.com/music/) | Spiele Musik von Real-Debrid direkt im Browser ab und lade sie herunter |

## rex mit Inhalten füttern {#feeding-rex}

| Name | Was es macht |
|---|---|
| [rex-stremio](../rex/stremio.md) | Macht deine Stremio-Addons zu rex-Bibliotheken, damit sie in Plex-Apps abgespielt werden. Kostenlos |
| [rex-Addons](../rex/addons.md) | Kleine Programme, die rex etwas zum Abspielen geben: YouTube, Spotify, IPTV, Heimvideos oder was du selbst schreibst |
| [rex für Android](../rex/android.md) | rex und seine Addons auf einem Android-Handy oder einer TV-Box, ohne Computer. Kostenlos. Für deine Debrid- und Usenet-Bibliothek nutzen Sponsoren zurg+rex |
| [zurg+rex für Android](../zurg/guides/android.md) | Ein Plex-Server auf deinem Handy: zurg und rex zusammen auf einem Android-Gerät. Für Sponsoren |

## In Jellyfin und Emby {#inside-jellyfin-and-emby}

| Name | Was es macht |
|---|---|
| [RD, AD, TB, PM, OC und DL zurg](https://debridmediamanager.com/jellyfin) | Ein Plugin pro Debrid-Anbieter. Deine Debrid-Bibliothek erscheint in Jellyfin oder [Emby](https://debridmediamanager.com/emby), ohne zurg-App oder Mount. Für Sponsoren |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Ein Jellyfin-Plugin, das NZBs über dein eigenes Usenet-Konto streamt. Für Sponsoren |

## Titel für dich hinzufügen {#adding-titles-for-you}

| Name | Was es macht |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Drück in DMM auf **Want**, und dein zurg holt es sich, inklusive neuer Folgen. Für Sponsoren |
| [Seerr through DMM](../dmm/seerr.md) | Anfragen der Familie in Seerr landen auf deiner Wanted-Liste. Für Sponsoren |
| [Torznab and Newznab](https://debridmediamanager.com/torznab) | DMM als Indexer für Sonarr, Radarr und Prowlarr, mit zurg als Download-Client. Für Sponsoren |
| [zurg's Stremio addon](../zurg/guides/stremio.md) | Sucht auf Usenet, wenn du in Stremio auf Play drückst, und streamt es über zurg |
| [`__magic__`](../zurg/guides/magic.md) | Ein zurg-Ordner, den du selbst sortierst oder von Sonarr und Radarr sortieren lässt |

## Der Rest von DMM {#the-rest-of-dmm}

| Name | Was es macht |
|---|---|
| [Anfrageboard](https://debridmediamanager.com/requests) | Frag nach einem Release, das Real-Debrid nicht hat. Ein anderer DMM-Nutzer verschiebt es in deine Bibliothek. Erfüllte Anfragen bringen dir die Vorteile für DMM-Sponsoren |
| [Hash-Listen](https://debridmediamanager.com/hashlists) | Teile eine Liste mit Releases, damit andere sie in ihre eigenen Konten hinzufügen können |
| [Browser-Erweiterung](../dmm/safari.md) | Fügt DMM-Buttons auf Film- und Serienseiten sowie neben Magnet-Links hinzu |
| [Sponsorenseite](https://gatekeeper.debridmediamanager.com) | Hier wirst du Sponsor und verknüpfst dein Patreon- oder GitHub-Sponsors-Abo. [Was dir eine Sponsoring-Mitgliedschaft bringt](sponsorship.md) |

## Begriffe, die dir in den Anleitungen begegnen {#words-youll-see-in-the-guides}

| Begriff | Bedeutung |
|---|---|
| Debrid provider | Ein kostenpflichtiger Dienst, der Torrents für dich herunterlädt und dir das Streamen ermöglicht: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | Der Anbieter hat das Release schon, also startet die Wiedergabe sofort |
| Usenet | Eine weitere Quelle für Releases. Du brauchst einen Usenet-Provider-Account oder TorBox Pro, das es für dich erledigt |
| NZB | Eine kleine Datei, die angibt, wo ein Usenet-Release zu finden ist, so wie eine Torrent-Datei das bei Torrents macht |
| Indexer | Eine Suchseite für Releases. Sonarr und Radarr nutzen sie, um Inhalte zu finden |
| WebDAV | Eine Methode, Dateien über das Web freizugeben. Infuse, Kodi und viele TV-Player können darauf zugreifen |
| Mount | Lässt den Ordner von zurg wie ein lokales Laufwerk aussehen, damit Plex, Jellyfin oder Emby ihn scannen können |
| Plex Media Server vs Plex apps | Der Server speichert deine Bibliothek. Die Apps auf deinem TV und Handy spielen sie ab. rex ersetzt den Server, nicht die Apps |
