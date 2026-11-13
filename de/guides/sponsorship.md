# Was dir eine Sponsoring gibt {#what-a-sponsorship-gives-you}

DMM ist kostenlos. Sponsoring bezahlt das Hosting und hält zurg und rex am Laufen. Diese Seite listet jeden Vorteil auf und zeigt, wo du ihn einrichtest.

Werde Sponsor auf [gatekeeper](https://gatekeeper.debridmediamanager.com/). Melde dich dort an, um deinen DMM-API-Key zu sehen. **Open DMM with this key** verknüpft ihn im Browser. Trag denselben Key in den anderen Diensten ein, die danach fragen. Behalte ihn für dich, denn er funktioniert wie ein Passwort.

Vorteile hängen am Sponsoring. Endet es, stoppt DMM sie bei der nächsten Anfrage. Jellyfin- und Emby-Plugins, die du schon installiert hast, funktionieren weiter, aber neue Downloads und Updates hören auf. Gatekeeper entzieht beim nächsten Check den zurg-Zugang und die Discord-Rolle. **Reset key** macht den alten Key auf einen Schlag überall ungültig.

## zurg

| Was du bekommst | Wo |
|---|---|
| Nightly-Builds mit allen Providern und Usenet sowie das Docker-Image | [zurg-Setup](../zurg/setup/index.md), nachdem du die GitHub-Einladung angenommen hast |
| Die zurg+rex-Android-App, ein Plex-Server auf deinem Handy | [Android-Anleitung](../zurg/guides/android.md), nachdem du die GitHub-Einladung angenommen hast |
| Der komplette zurg-Quellcode | Das private Repository auf GitHub |
| Jedes Release, das nach rex und Plex benannt ist | `dmm_api_key` in der [zurg-Konfiguration](../zurg/reference/config.md) |
| DMM-Mediendetails ohne vorheriges Lesen der Datei und Sprachprüfungen, bevor ein Release hinzugefügt wird | Nichts außer `dmm_api_key` |
| Die `__magic__`-Ordner, wenn aktiviert, für dich sortiert | [\_\_magic\_\_](../zurg/guides/magic.md) |
| Deine DMM-Wunschliste, die von zurg abgerufen wird | [DMM-Wunschliste](../zurg/guides/dmm-wanted.md) |
| DMMs Usenet- und Torrent-Indexer werden durchsucht, wenn du keine eigenen hast | `dmm_api_key` plus ein Usenet-Provider oder ein Debrid-Konto, das Torrents hinzufügen kann |
| Releases werden nach der Originalsprache jedes Titels ausgewählt | `original` in [Audio- und Untertitelsprachen](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) |
| Ein gewünschter Film, den kein Indexer hat, wird von seinem offiziellen YouTube-Upload gestreamt | [Einen Film von YouTube streamen](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

Die `dmm_api_key`-Funktionen brauchen einen zurg-Nightly-Build. Die kostenlose öffentliche Version enthält sie nicht.

## DMM

_ignore

Wait, I need to check the input: it's a Markdown table. Translate into German, keeping structure, names in English, URLs unchanged.

| Was du bekommst | Wo |
|---|---|
| Eine Wunschliste, die zurg mit neuen Folgen und Upgrades abruft. Befülle sie aus DMM oder Kodi oder Trakt- und MDBList-Listen oder einem Radarr- oder Sonarr-Backup | [DMM-Wunschliste](../zurg/guides/dmm-wanted.md) |
| Anfragen von Seerr oder Overseerr oder Jellyseerr landen auf deiner Wunschliste | [Seerr über DMM](../dmm/seerr.md) |
| Jedes Easynews-Ergebnis mit einem Klick an deinen zurg schicken | Die Easynews-Ergebnisse auf einer Film- oder Serienseite auf DMM |
| DMM als Newznab-Indexer für Usenet | DMMs [Newznab-Seite](https://debridmediamanager.com/newznab) |
| DMM als Torznab-Indexer mit nur gecachten Feeds für Real-Debrid und AllDebrid und Debrid-Link und TorBox und Premiumize und Offcloud | DMMs [Torznab-Seite](https://debridmediamanager.com/torznab). TorBox, Premiumize und Offcloud brauchen zusätzlich ihren verknüpften Dienstschlüssel |
| Sieben Jellyfin-Plugins für Debrid- und Usenet-Bibliotheken und sechs Emby-Plugins für Debrid-Bibliotheken, ohne dass etwas eingebunden ist | DMMs [Jellyfin](https://debridmediamanager.com/jellyfin)- und [Emby](https://debridmediamanager.com/emby)-Seiten |
| Zehn weitere Streams pro Titel in Stremio Cast und Kodi statt fünf | DMM-Einstellungen für Real-Debrid, TorBox und AllDebrid; die Cast-Seite des jeweiligen Anbieters für die anderen |
| NZB-Uploads kommen zuerst, mit 2 TB Usenet pro Tag statt 300 GB | DMMs Usenet-Tab |
| Dieselbe Priorität und dasselbe Kontingent für Sonarr und Radarr | Dein DMM-API-Schlüssel als Password auf DMMs [SABnzbd-Seite](https://debridmediamanager.com/sabnzbd) |
| Drei Torrent-Uploads gleichzeitig zu Real-Debrid statt einem | Die Upload-Buttons in den DMM-Suchergebnissen und in der Bibliothek |
| Add to DMM Wanted und ein Wanted-Ordner in Kodi | Kodi auf DMMs [Kodi-Seite](https://debridmediamanager.com/kodi) koppeln |
| Die DMM-API für Release-Namen, Cache-Prüfungen, Medieninfos und Metadaten | [API-Dokumentation](https://debridmediamanager.com/api-docs) |

## rex

rex ist kostenlos und braucht keine Sponsoring-Anmeldung, auch auf Android: [rex für Android](../rex/android.md) betreibt rex und seine Addons auf einem Handy oder einer TV-Box. Mit einem Schlüssel fügt [rex-stremio](../rex/stremio.md) Debrid-Streams von Torrents hinzu, für die DMM bereits eine Prüfung hat, und zwar in Sekunden statt jeden einzelnen zu prüfen. Füge ihn im Feld **DMM** von rex-stremio ein. Es teilt seine Prüfungen von Torrent-Dateien mit DMM, es sei denn, du schaltest das aus.

## Hilfe {#help}

| Was du bekommst | Wo |
|---|---|
| Kostenlose Hilfe per Fernzugriff bei zurg und rex direkt in deinem Terminal, während du zuschaust | [Hilfe bekommen](remote-help.md) |
| Die Sponsor-Rolle auf Discord | Discord auf gatekeeper verbinden |

## Verdiene es dir ohne Bezahlung {#earn-it-without-paying}

Erfülle Anfragen auf dem [Anfrage-Board](https://debridmediamanager.com/requests) von DMM. Für jede 10 Anfragen gibt es 7 Tage der DMM-Vorteile von oben. Pro Person zählt pro Tag nur eine Erfüllung. Verknüpfe den Key von einem kostenlosen gatekeeper-Account auf dem Board, um sie zu sammeln.

Die verdiente Zeit schaltet die DMM-Tabelle von oben frei. Sie schaltet nicht den zurg-Nightly, den Quellcode, die Discord-Rolle, die Fernhilfe oder die Android-App frei. Dafür brauchst du ein bezahltes Sponsoring. Die `dmm_api_key`-Funktionen brauchen außerdem einen Nightly.

Hängst du fest? Frag im **dmm-support**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP) nach.
