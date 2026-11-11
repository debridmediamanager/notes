# zurg

zurg legt deine Debrid-Konten und deine Usenet-Bibliothek in einem virtuellen Ordner zusammen. Es speichert keine lokalen
Videos. Erst wenn ein Player etwas anfordert, wird es geladen. Ein 60-GB-Remux belegt also nicht 60 GB auf deiner lokalen Festplatte.

Vier Zugänge zur selben Bibliothek:

| Endpoint | Für |
|---|---|
| `/dav/` | WebDAV, das rclone einbindet |
| `/http/` | HTML-Verzeichnisbrowser |
| `/infuse/` | WebDAV-Variante, angepasst an Infuses Eigenheiten |
| `/strm/` | Signierte URLs in `.strm`-Dateien, für Player, die eine URL statt einer Einbindung wollen |

## Einrichtung {#setup}

Bring zurg zum Laufen auf deinem Rechner.

- [Linux](setup/linux.md) — FUSE 3 und automatischer Start mit systemd
- [Docker](setup/docker.md) — ein Linux-Host mit einem vom Host sichtbaren Mount
- [macOS](setup/macos.md) — macFUSE und automatischer Start mit launchd
- [Windows](setup/windows.md) — WinFsp und eine Aufgabe für den Laufwerksbuchstaben

## Anbieter {#providers}

Verbinde zurg mit einem Account. Jede Seite behandelt die Zugangsdaten und den Eintrag in der `config.yml`. Die Beispiele nutzen Docker. Eine Binary-Installation nutzt denselben Config-Eintrag. Die Befehle findest du unter [Einrichtung](setup/index.md).

| Seite | Was daran anders ist |
|---|---|
| [Real-Debrid](providers/realdebrid.md) | Auswahl pro Datei, `__downloads__`, Wahl des CDN-Hosts, ein separates `.strm`-Token |
| [TorBox](providers/torbox.md) | Eine Anfrage pro Bibliotheksaktualisierung, und eine Obergrenze für aktive Slots statt einer für die Bandbreite |
| [AllDebrid](providers/alldebrid.md) | Dateilisten kommen von einem eigenen Endpunkt, daher füllt sich ein erster Scan nach und nach |
| [Premiumize](providers/premiumize.md) | Abgeschlossene Übertragungen plus die übrig gebliebenen Cloud-Dateien, mit ihren Ordnern |
| [Debrid-Link](providers/debridlink.md) | Die Seedbox-Liste enthält jede Datei, und es gibt keine Cache-Prüfung |
| [Offcloud](providers/offcloud.md) | Größen werden am Auslieferungsserver geprüft, Ordnerpfade stammen aus zwischengespeicherten Metadaten |
| [Usenet](providers/usenet.md) | Der `nzb`-Typ als Provider-Eintrag. Kein Token, stattdessen ein Watch-Verzeichnis |
| [TorBox limits](providers/torbox-limits.md) | Die gemessenen Werte hinter der TorBox-Drosselung und wie zurg sich daran orientiert |
| [TorBox news server](providers/torbox-news-server.md) · [ElfHosted news server](providers/elfhosted-news-server.md) | Was die mitgelieferten Usenet-Konten auf der Leitung tatsächlich sind |

Die [gemeinsame Seite](providers/index.md) beschreibt die drei Wege, einen Account in Docker hinzuzufügen, und die Regeln, die der Config-Loader durchsetzt.

## Anleitungen {#guides}

Mit der Bibliothek arbeiten.

- [Usenet](guides/usenet.md) — das `nzb`-Backend von Anfang bis Ende: News-Accounts, NZBs, der Mount, Plex
- [Sonarr & Radarr für Usenet](guides/sonarr-radarr.md) — die \*arrs suchen, und zurg antwortet als SABnzbd, damit Importe nur ein Umbenennen statt ein Download sind
- [Sonarr & Radarr für Torrents](guides/sonarr-radarr-torrents.md) — dasselbe, nur antwortet zurg als qBittorrent; Prowlarr auch
- [zurg sucht für Sonarr & Radarr](guides/sonarr-radarr-fetch.md). Radarr und Sonarr behalten die Liste, und zurg findet und platziert das Release. In keinem von beiden gibt es Indexer oder Download-Clients.
- [`__magic__`](guides/magic.md) — das eine Verzeichnis, dessen Layout gespeichert wird und deshalb von dir selbst angeordnet werden kann, mit deiner Bibliothek nach Titel abgelegt für Kodi und Plex
- [Umbenennen](guides/renaming.md) — benenne ein Release oder eine Datei irgendwo in der Bibliothek um. Ein Verschieben wird abgelehnt, und die Seite erklärt warum
- [Plex](guides/plex.md) — was zurg mit einem Plex-Token macht und was es bewusst nicht macht
- [Jellyfin](guides/jellyfin.md) — dasselbe für Jellyfin
- [rex mit zurg](../rex/with-zurg.md) — ein Medienserver für die Plex-Apps, der keine Dateien besitzt und von zurg aus deinem Debrid-Konto gefüllt wird. Mehr dazu in [rex](../rex/index.md)
- [Das Stremio-Addon](guides/stremio.md) — Stremio sucht in deinen eigenen Indexern und spielt direkt aus dem Usenet-Backend ab
- [Watchlist und Seerr](guides/acquisition.md) holt, was du anforderst, über deine eigenen Indexer
- [Plex-Watchlist](guides/plex-watchlist.md) ist die Plex-Seite davon
- [DMM-Wunschliste](guides/dmm-wanted.md) holt, worauf du bei DMM Want drückst, ohne dass du sonst etwas einrichten musst
- [Lokale Bibliotheken](guides/local-libraries.md) spielt eine geteilte Liste von Releases über dein eigenes Konto ab
- [Android und Google TV](guides/android.md) betreibt die ganze Bibliothek auf einem Handy oder einer TV-Box

## Migration {#migrating}

Eine bestehende Bibliothek auf zurg umziehen, ohne neu herunterzuladen oder neu zu scannen.

- [Von AltMount](migrate/altmount.md)
- [Von decypharr](migrate/decypharr.md)
- [Von InfiniDysk](migrate/infinidysk.md)
- [Von nzbdav](migrate/nzbdav.md)
- [Von streamnzb](migrate/streamnzb.md)

## Referenz {#reference}

- [Konfiguration](reference/config.md) — jede Option in `config.yml`
- [Kommandozeile](reference/cli.md) listet jeden Befehl und jedes Flag, das das Binary annimmt
- [Ausgehende Identität](reference/outbound-identity.md) erklärt, was zurg den Diensten, die es aufruft, über sich selbst mitteilt
- [MCP-Server](reference/mcp.md) lässt einen KI-Agenten zurg über das Model Context Protocol steuern
- [Tags](reference/tags.md) — was einem Torrent zugewiesen wird und warum
- [Changelog](reference/changelog.md) — was wann geändert wurde

## Interna {#internals}

Wie zurg aufgebaut ist, wie es gemessen wurde und die Designnotizen zu den kniffligen Stellen.

- [Architektur](internals/architecture.md) — die Gesamtstruktur und die Invarianten, die leicht kaputtgehen
- [Debrid-Baseline](internals/debrid-baseline.md) — was zurg kostet und wie schnell es sich über RD, AD und TorBox anfühlt
- [Torrent-Lebenszyklus](internals/torrent-lifecycle.md) — was jeder Account während eines Downloads tatsächlich meldet, live gemessen
- [SABnzbd-Client-Vertrag](internals/sabnzbd-client-contract.md) — die genauen Formate, die Sonarr und Radarr erwarten
- [Plex-Trash-Sweep](internals/plex-trash-sweep.md) · [Stream-Timeout-Regression](internals/stream-timeout-regression.md) · [Verzeichniskonfiguration UI/UX](internals/uiux.md)
- [E2E-Tests](internals/e2e-test.md) · [Real-Debrid-API-Hinweise](internals/realdebrid-behavior.md)
- [qBittorrent-Client-Vertrag](internals/qbittorrent-client-contract.md) · [Persistente Caches](internals/persistent-caches.md)
- [Benennung](internals/naming.md) · [rclone-Move-Verweigerung](internals/rclone-move-refusal.md)

---

zurg wird an Sponsoren verteilt: [GitHub Releases](https://github.com/debridmediamanager/zurg/releases)
· [Sponsor](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP)
