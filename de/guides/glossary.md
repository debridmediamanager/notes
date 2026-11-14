# Was jedes Teil macht {#what-each-piece-does}

Die Namen sagen nicht direkt, was sie tun, daher hier je eine Zeile zu jedem. Alles, was nicht mit **For sponsors** markiert ist, ist kostenlos. Welche du brauchst, findest du unter [Choose your setup](choose-your-setup.md).

## Die drei Projekte {#the-three-projects}

| Name | Was es macht |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Eine Website, um Releases zu finden und sie zu deinem Debrid-Konto hinzuzufügen. Sie durchsucht auch Usenet und Easynews |
| [zurg](../zurg/index.md) | Jedes Debrid-Konto und Usenet als eine einzige Bibliothek. Plex, Jellyfin und Emby lesen sie als Ordner, Infuse und Kodi über WebDAV, und rex greift direkt darauf zu. Aktuelle Builds sind für Sponsoren gedacht |
| [rex](../rex/index.md) | Ein Medienserver für die Plex-Apps ohne eigene Dateien. zurg oder ein Addon sagt ihm, was verfügbar ist. Kostenlos für den persönlichen Gebrauch |

## Direkt in DMM streamen {#watching-straight-from-dmm}

Für keines dieser Tools wird ein Server benötigt.

| Name | Was es macht |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | Ein Stremio-Addon, das Releases aus deinem Debrid- oder Easynews-Konto abspielt. Es funktioniert auch in Nuvio |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Durchsuche, suche und spiele Inhalte aus deinem Debrid- oder Easynews-Konto direkt in Kodi ab |
| DMM Watch | Ein Button in DMM, der eine Datei in deinem eigenen Player öffnet, zum Beispiel VLC oder Infuse |

## rex mit Inhalten füttern {#feeding-rex}

| Name | Was es macht |
|---|---|
| [rex-stremio](../rex/stremio.md) | Macht deine Stremio-Addons zu rex-Bibliotheken, damit sie in den Plex-Apps abgespielt werden können |
| [rex addons](../rex/addons.md) | Kleine Programme, die rex etwas zum Abspielen geben: YouTube, Spotify, IPTV, Heimvideos oder was auch immer du schreibst |
| [rex-live-sports](../rex/live-tv.md) | Ein rex-Addon, das Live-Sport-Kanäle und einen Programmführer in die Live-TV-Funktion der Plex-Apps bringt |
| [rex-direct](../rex/any-source.md#rex-direct) | Gibt deinem rex eine eigene sichere Adresse, damit die Plex-Apps auch von unterwegs drankommen |
| [rex for Android](../rex/android.md) | rex und seine Addons auf einem Android-Handy oder einer TV-Box, ohne Computer |
| [zurg+rex for Android](../zurg/guides/android.md) | Ein Plex-Server auf deinem Handy: zurg und rex zusammen auf einem Android-Gerät, mit deiner Debrid- und Usenet-Bibliothek. Für Sponsoren |

## In Jellyfin und Emby {#inside-jellyfin-and-emby}

| Name | Was es macht |
|---|---|
| [Debrid-Plugins](https://debridmediamanager.com/jellyfin) (RD zurg, AD zurg, TB zurg, PM zurg, OC zurg, DL zurg) | Ein Plugin pro Debrid-Anbieter: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud und Debrid-Link. Deine Debrid-Bibliothek erscheint in Jellyfin oder [Emby](https://debridmediamanager.com/emby), ganz ohne zurg-App oder Mount. Für Sponsoren |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Ein Jellyfin-Plugin, das NZBs über dein eigenes Usenet-Konto streamt. Für Sponsoren |

## Titel für dich hinzufügen {#adding-titles-for-you}

| Name | Was es macht |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Drück in DMM auf **Want**, und dein zurg holt es, inklusive neuer Folgen. Für Sponsoren |
| [Seerr über DMM](../dmm/seerr.md) | Anfragen der Familie in Seerr landen auf deiner Wanted-Liste. Für Sponsoren |
| [Torznab](https://debridmediamanager.com/torznab) und [Newznab](https://debridmediamanager.com/newznab) | DMM als Indexer für Sonarr, Radarr und Prowlarr. Für Sponsoren |
| zurg als Download-Client | zurg antwortet Sonarr und Radarr als qBittorrent für [Torrents](../zurg/guides/sonarr-radarr-torrents.md) und als SABnzbd für [Usenet](../zurg/guides/sonarr-radarr.md), dadurch brauchst du keins von beiden. Für Sponsoren |
| [zurgs Stremio-Addon](../zurg/guides/stremio.md) | Sucht auf Usenet, wenn du in Stremio auf Play drückst, und streamt es über zurg. Für Sponsoren |
| [`__magic__`](../zurg/guides/magic.md) | Ein zurg-Ordner, den du selbst einrichtest oder von Sonarr und Radarr einrichten lässt. Für Sponsoren |

## Der Rest von DMM {#the-rest-of-dmm}

| Name | Was es macht |
|---|---|
| Usenet-Tab | Schickt ein Usenet-Release in deine Real-Debrid-Bibliothek, ohne Usenet-Konto. Sponsoren kommen zuerst dran und bekommen ein größeres tägliches Kontingent |
| [Request-Board](https://debridmediamanager.com/requests) | Frag ein Release an, das Real-Debrid nicht hat. Ein anderer DMM-Nutzer verschiebt es in deine Bibliothek. Erfüll 10 Requests und bekomm 7 Tage lang die DMM-Sponsor-Vorteile |
| [Hash-Listen](https://debridmediamanager.com/hashlists) | Teil eine Liste mit Releases, damit andere sie in ihre eigenen Konten hinzufügen können |
| Browser-Erweiterung | Fügt DMM-Buttons auf Film- und Serien-Seiten sowie neben Magnet-Links hinzu. Für [Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm), [Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/) und [Safari](../dmm/safari.md) |
| [gatekeeper](https://gatekeeper.debridmediamanager.com) | Die Sponsor-Seite. Werd dort Sponsor, verknüpf dein Patreon- oder GitHub-Sponsors-Abo und bekomm deinen DMM-API-Key. [Was dir eine Sponsorschaft bringt](sponsorship.md) |

## Begriffe, die dir in den Anleitungen begegnen {#words-youll-see-in-the-guides}

| Begriff | Was es bedeutet |
|---|---|
| Release | Eine Kopie eines Films, einer Folge oder einer Staffel, so wie jemand sie veröffentlicht hat. Ein Titel hat meist viele, in verschiedenen Qualitäten |
| Debrid provider | Ein kostenpflichtiger Dienst, der Torrents für dich herunterlädt und dir das Streamen ermöglicht: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | Der Anbieter hat das Release schon, also startet es sofort |
| Usenet | Eine weitere Quelle für Releases. Nutze dein eigenes Usenet-Konto, lass TorBox Pro oder Easynews das erledigen oder lass DMM ein Ergebnis an Real-Debrid schicken |
| Easynews | Ein kostenpflichtiger Usenet-Dienst mit eigener Suche, der Dateien direkt über das Web abspielt |
| NZB | Eine kleine Datei, die sagt, wo ein Usenet-Release liegt, so wie eine Torrent-Datei das bei Torrents macht |
| Indexer | Eine Suchseite für Releases. Sonarr und Radarr nutzen sie, um Dinge zu finden |
| Sonarr, Radarr and Prowlarr | Apps, die Titel für dich holen: Sonarr für Serien, Radarr für Filme. Prowlarr verwaltet ihre Indexer an einem Ort |
| Seerr | Eine Anfrage-Seite für Familie und Freunde. Overseerr und Jellyseerr funktionieren genauso |
| Stremio, Nuvio and Kodi | Mediaplayer-Apps. Addons liefern ihnen die Inhalte zum Abspielen. Nuvio nutzt Stremio-Addons |
| DMM API key | Ein Schlüssel für Sponsoren von gatekeeper. Füge ihn dort ein, wo eine Anleitung es verlangt, und behalte ihn wie ein Passwort für dich |
| Nightly | Die neueste Version von zurg oder rex, jede Nacht gebaut. zurgs Nightlies sind für Sponsoren |
| WebDAV | Eine Methode, Dateien über das Web zu teilen. Infuse, Kodi und viele TV-Player können sie öffnen |
| Mount | Lässt den zurg-Ordner wie ein lokales Laufwerk aussehen, damit Plex, Jellyfin oder Emby ihn scannen können |
| rclone | Das Tool, mit dem zurg den Mount erstellt. zurgs Setup besorgt es für dich |
| `.strm` | Eine kleine Datei, die einen Link statt des Videos enthält, für Player wie Kodi |
| Source | Alles, was rex mitteilt, was vorhanden ist, und die Dateien bereitstellt: zurg, rex-stremio oder ein Addon |
| Claim | Rex mit einem Plex-Konto verbinden, damit es Titel und Poster anzeigen kann und Plex-Apps es finden |
| Plex Media Server vs Plex apps | Der Server enthält deine Bibliothek. Die Apps auf deinem TV und Handy spielen sie ab. rex ersetzt den Server, nicht die Apps |
