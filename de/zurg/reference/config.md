# zurg-Konfigurationsdokumentation {#zurg-configuration-documentation}

Diese Dokumentation beschreibt alle verfügbaren Konfigurationsoptionen für zurg. Trage diese Optionen in deiner `config.yml`-Datei ein.

> **Tipp:** Die meisten Einstellungen kannst du über das **Dashboard** unter `http://localhost:9999/config/` vornehmen. Die Weboberfläche ist einfacher, um Einstellungen anzuzeigen und zu ändern, ohne die Konfigurationsdatei direkt zu bearbeiten.

## Migration von einer Konfiguration vor `providers` {#migrating-from-a-pre-providers-config}

Wenn deine Konfiguration vor der Unterstützung für mehrere Accounts geschrieben wurde, startet sie trotzdem. Die Schlüssel `token:`, `download_tokens:` und `strm_link_token:` auf oberster Ebene werden so gelesen, wie sie nur gemeint sein konnten: als ein einziger Real-Debrid-Account. Beim Start erscheint dann eine Warnung, dass sie veraltet sind. Sie in einen `providers`-Eintrag zu verschieben ist die einzige Änderung, die deine Konfigurationsdatei braucht, und zwar wann immer du dazu kommst. Kein anderer Schlüssel wurde umbenannt, anders typisiert oder entfernt.

Es ist aber nicht die einzige Änderung. Ein paar Direktiven behalten ihren Namen und ihren Wert, entscheiden aber etwas anderes als früher, weil sich der Code, der sie liest, verschoben hat. Diese sind unten unter [Was sich beim Upgrade sonst noch ändert](#what-else-changes-when-you-upgrade) gesammelt. Ein Blick lohnt sich, wenn du nach Archiven, Tags oder dem Zeitpunkt filterst, zu dem ein Release hinzugefügt wurde.

### Die eine Änderung, die du vornehmen musst {#the-one-change-to-make}

Ein einzelnes Real-Debrid-Konto bestand früher aus drei Schlüsseln auf oberster Ebene. Alle drei stehen jetzt in einem einzigen `providers`-Eintrag.

Vorher:

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
download_tokens:
  - ANOTHER_RD_API_TOKEN
strm_link_token: RD_TOKEN_FOR_STRM
```

Nachher:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    download_tokens:
      - ANOTHER_RD_API_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
```

Lösch die alten Schlüssel, sobald sie verschoben sind. Bleiben sie neben einem `providers`-Block stehen, der Real-Debrid bereits konfiguriert, werden sie ignoriert, und beim Start erscheint eine Warnung. So können die beiden nie stillschweigend widersprüchlich sein, welcher Token gerade aktiv ist. An deiner Datei musst du sonst nichts ändern. Alle anderen Schlüssel behalten ihren Namen und ihre Bedeutung, und eine Konfiguration, deren einziger Zugang `token:` war, braucht nur diese Änderung.

Du musst das nicht machen. Eine nicht migrierte Konfiguration startet trotzdem: Die drei Schlüssel werden als ein Real-Debrid-Konto namens `realdebrid` gelesen, und beim Start wird angezeigt, welche Schlüssel gelesen wurden und was stattdessen geschrieben werden sollte. Sie sind veraltet, aber nicht mehr unterstützt. Neue Kontofunktionen sind nur über einen `providers`-Eintrag erreichbar.

Die Umgebungsvariablen `TOKEN` / `RD_TOKEN` funktionieren weiterhin und erstellen beim ersten Start weiterhin automatisch eine Konfiguration.

### Was dadurch möglich wird, das du vielleicht willst {#what-became-possible-that-you-may-want}

Nichts davon ist nötig. Das hat dir der `providers`-Block gebracht:

| Jetzt verfügbar | Wo |
|---|---|
| TorBox-, AllDebrid- und Usenet-Backends, zusätzlich zu Real-Debrid oder anstelle davon | [Konten](#accounts) |
| Mehrere Konten desselben Dienstes, unterschieden über `name` | [Konten](#accounts) |
| `disabled: true`, um ein Konto zu pausieren, ohne seine Zugangsdaten zu löschen | [Konten](#accounts) |
| `watchlist: true`, um festzulegen, auf welchem Konto neue Torrent-Hinzufügungen zuerst versucht werden | [Konten](#accounts) |
| `provider:` / `not_provider:`-Verzeichnisfilter und Verzeichnisse pro Konto | [Verzeichnisse](#7-directories--filters) |
| `rd_cdn_host_preference` und `tb_cdn_host_preference` für die CDN-Auswahl pro Dienst | [CDN & Host Selection](#cdn--host-selection) |

Zwei kleinere Änderungen, die du kennen solltest:

- `cdn_host_preference` funktioniert weiterhin und bezieht sich immer noch auf Real-Debrid. Es ist jetzt ein Alias für `rd_cdn_host_preference`, und dieser hat Vorrang, wenn beide gesetzt sind.
- Plex-Zugangsdaten aus dem Auth-Flow des Dashboards werden als `plex_server_url` und `plex_token` zurück in `config.yml` geschrieben. Früher lagen sie in `data/plex.json`.

### Manuell oder über das Dashboard migrieren {#migrating-by-hand-vs-by-dashboard}

Das Dashboard kann das für dich erledigen. Eine nicht migrierte Konfiguration lädt trotzdem, also ist der Editor für die Provider erreichbar, und er listet das Real-Debrid-Konto auf, als das deine Schlüssel auf oberster Ebene gelesen wurden. Wenn du ein beliebiges Konto speicherst, werden diese Schlüssel auf der Festplatte in den `providers`-Block verschoben.

Du kannst auch die Datei von Hand bearbeiten und neu starten, das bewirkt dasselbe. Das ist außerdem die einzige Option, wenn die Konfiguration gar nicht mehr lädt.

Eine Sache akzeptiert das Dashboard nicht mehr: `POST /config` hat früher `token`, `download_tokens` und `strm_link_token` als Schlüssel auf oberster Ebene angenommen. Jetzt antwortet es mit `400 Unknown config option`. Zugangsdaten bearbeitest du stattdessen pro Konto. Wer diese drei Schlüssel per Skript setzt, muss das anpassen.

### Was sich beim Upgrade sonst noch ändert {#what-else-changes-when-you-upgrade}

**Filter sehen jetzt in Archive hinein.** `any_file_inside_regex`, `any_file_inside_contains`, `any_file_inside_size_gte`/`_lte`, deren `not_`-Varianten, `has_episodes` und `is_music` wurden früher auf das Archiv selbst angewendet: ein Eintrag namens `Show.part01.rar` mit der Größe des Volumes. Sobald zurg ein Archiv aufgelistet hat, werden sie auf den Inhalt angewendet, also auf die echten Dateinamen und deren echte Größen. Die Größe des Archivs selbst wird bewusst *nicht* mehr verwendet, weil sie alles darin in den Schatten stellte. Ein Staffel-Pack, das als eine riesige Datei galt, passt jetzt auf `has_episodes`. `any_file_inside_regex: /\.mkv$/i` greift dort, wo es vorher nicht gegriffen hat, und `any_file_inside_not_regex` greift nicht mehr dort, wo es vorher gegriffen hat. Außerdem erreicht ein Release, dessen Dateien alle `.rar`/`.r00`/`.par2` sind, jetzt überhaupt die Filter. Vorher ging es direkt nach `__unplayable__`.

Das gilt Release für Release und nicht auf einmal. Es betrifft nur Archive, die zurg bereits aufgelistet hat, und Listings von einem älteren Parser werden verworfen. Ein Release wechselt also beim ersten Öffnen. Wenn ein Verzeichnis von dir auf das alte Verhalten angewiesen ist, formuliere es über den Archivnamen mit `regex`/`not_regex`. Die matchen weiterhin auf den Release-Namen.

**Tag-Filter fangen Releases nicht mehr ab, die nie geprobt wurden.** Die `zurg_*`-Tags kommen von ffprobe. Wenn sich nichts proben ließ, landeten alle Tier-Tabellen am Ende und das Release bekam trotzdem `zurg_sdr`, `zurg_very_low_video_bitrate`, `zurg_very_low_audio_bitrate` und `zurg_0to20mins_duration` verpasst. Das beschrieb eine Datei, die niemand gemessen hatte. Diese Tags werden nicht mehr vergeben. Ein Filter, der eines dieser vier Tags nennt, ändert seine Bedeutung für nicht prober­bare Releases. `has_tag`/`tags_match_all`/`tags_match_any` fangen sie dann nicht mehr ab. Und das ist die Richtung, auf die du achten solltest: `not_has_tag`, `tags_missing_all` und `tags_missing_any` **fangen sie jetzt** ab. Filter mit anderen Tiers bleiben unverändert.

**`added_within_hours` / `added_within_days` / `added_after` / `added_before` lesen für Duplikate einen älteren Zeitstempel.** Ist ein Release mehrfach vorhanden, meldet der Eintrag jetzt die früheste Hinzufügezeit statt der zuerst gesehenen. Eine zweite Kopie eines alten Releases wirkt deshalb nicht mehr wie neu hinzugefügt. Ein Verzeichnis im Stil von `recent` kann dadurch ein Release verlieren, das es vorher behalten hat.

**Der Mount cacht Verzeichnislistings jetzt 12 Stunden lang.** `check_for_changes_every_secs` hat früher rclones `--dir-cache-time` gesetzt, sodass Listings standardmäßig alle 15 Sekunden abliefen. Jetzt gelten sie 12h, und zurg vergisst die betroffenen Einträge explizit, sobald sich die Bibliothek ändert. Dadurch bleiben Scans deines Media-Servers schnell. Wenn du zurück willst, überschreibe es direkt. `rclone_extra_args` gewinnt gegen jedes eingebaute Flag:

```yaml
rclone_extra_args: ["--dir-cache-time", "15s"]
```

**Jeder Account bekommt ein Verzeichnis `__<account>__`.** Es wird aus dem `providers`-Block erstellt und nicht aus `directories`. Es enthält alles, was dieser Account hält, ignoriert deine Verzeichnisfilter und bindet Lesezugriffe an genau diesen Account. `directories` kann es nicht unterdrücken. Bei mehr als einem Account wird es im Mount-Root aufgelistet. Builds vor Nightly 2026.10.24.0551 haben den Ordner eines einzelnen Accounts dort ebenfalls gelistet. Ab diesem Nightly fehlt er im Root-Listing des Mounts, weil `__all__` dieselbe Bibliothek ist. Direkte HTTP- und WebDAV-Pfade wie `/http/__realdebrid__/` antworten weiterhin. Über den Mount lösen sie sich ebenfalls nicht mehr auf. Zeige jede Bibliothek oder jedes Skript, das `__<name>__` verwendet hat, stattdessen auf `__all__`.

**Zwei Releases mit gleichem Namen sind jetzt zwei Einträge.** Früher wurden sie zusammengeführt, wodurch still die Dateien des einen Releases in das andere einflossen. Das Release, das den reinen Namen nicht behält, bekommt als Suffix sechs Zeichen seines Info-Hashes angehängt, zum Beispiel `Movie.2024 {a1b2c3}`. Auf diesen Suffix matchen `regex`, `not_regex`, `contains` und `not_contains`. Ein verankertes Muster verfehlt ihn daher. Außerdem werden Einträge, die wegen eines doppelten Basisnamens disambiguiert wurden, beim Upgrade einmalig umbenannt: von einer vom Account vergebenen Datei-ID zu einem aus dem Pfad abgeleiteten Tag.

**Die `.strm`-Dateien ändern ihre Form.** Mit `serve_strm_files` ändern sich Inhalt und gemeldete Größe jeder `.strm`-Datei, die der Mount ausliefert. Die URL zeigt jetzt auf den Bibliothekseintrag statt auf den Link eines einzelnen Accounts. Dadurch greift Failover, und die URL übersteht Repairs. Dein Media-Server sieht also jede `.strm` als geändert. Mit `save_strm_files` werden die bereits geschriebenen Dateien beim ersten Start von zurg unter denselben Namen an Ort und Stelle neu geschrieben. Beim nächsten Scan übernimmt der Media-Server die neue URL. Die neue Form wird mit einem Geheimnis unter `data/strm_secret` signiert. Lässt sich das nicht schreiben, loggt zurg eine Warnung und startet trotzdem. Die Links lösen dann nach dem nächsten Neustart nicht mehr auf. Das solltest du nicht ignorieren.

**`load_dumped_torrents` lädt kein `dump/` aus der Zeit vor dem Upgrade.** Gecachte Torrents tragen jetzt den Account, aus dem sie stammen. Solche ohne diesen Stempel werden übersprungen. Der Haupt-Cache importiert beim nächsten Refresh wieder vom Account. Hinter `dump/` steht aber kein Account. Dort bleibt also alles leer, und das Log zeigt eine Warnung. Wenn du das brauchst, exportiere die Daten aus einer laufenden Instanz neu.

**Repair nimmt einen anderen Weg, wenn `restrict_repair_to_cached` und `only_full_torrent_repair` auf false stehen.** Beide Schlüssel bleiben bei `true` unverändert. Bei ausgeschalteten Optionen, also im Standard, wurden die Strategien pro Datei und gebündelt durch ein einziges erneutes Hinzufügen ersetzt. Dabei werden die kaputten Dateien namentlich angegeben. Die Absicht bleibt gleich, aber die Anfragen an den Account sind andere.

**Kleinere Änderungen.** `ignore_renames` bestimmt jetzt auch den Namen der `.zurgtorrent`-Datei auf der Festplatte. Beim Laden migriert sie sich selbst. `retries_until_failed` begrenzt jetzt die Fair-Use-Wiederholungen von Real-Debrid. Vorher wurde dort endlos wiederholt. `auto_analyze_new_torrents: false` und ein fehlendes `ffprobe_binary` unterdrücken nicht mehr die Cache-Bereinigung. Die wurde früher mit der Analyse zusammen übersprungen. Ein Größenfilter, der das erste Volume eines Archivs ausschließt, blendet jetzt das ganze Archiv aus. Früher fiel er auf ein späteres Volume zurück. Unauthentifizierte statische Assets gelten nun für `/static/*` statt nur für `/static/css/*`. Keine bisher geschützte Route ist dadurch öffentlich geworden.

## Windows-Konfiguration {#windows-configuration}

Beim Ausführen von zurg unter Windows müssen Pfade anders formatiert werden:

```yaml
# Mount path - use drive letter with escaped backslash or forward slash
mount_path: "P:\\"       # Drive letter (escaped backslash)
mount_path: "P:/"        # Drive letter (forward slash also works)

# Binary paths - use forward slashes for paths to executables
ffprobe_binary: "Q:/zurg/bin/ffprobe.exe"
rclone_binary: "Q:/zurg/bin/rclone.exe"

# Alternative: use double forward slashes (also valid)
ffprobe_binary: "Q://zurg//bin//ffprobe.exe"
rclone_binary: "Q://zurg//bin//rclone.exe"
```

**Wichtige Punkte für Windows:**
- Setze alle Pfade in Anführungszeichen
- Verwende für `mount_path` einen Laufwerksbuchstaben wie `P:\` (in YAML als `P:\\` geschrieben) oder `P:/`
- Bei Binärpfaden funktionieren Schrägstriche `/` und vermeiden Probleme mit dem Escapen
- Achte darauf, dass die Endung `.exe` bei ausführbaren Dateien angegeben ist

## 1. Grundlagen (zuerst einrichten) {#1-essentials-setup-first}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `zurg` | string | *(erforderlich)* | Versions-Kennung der Konfiguration. Muss auf `v1` gesetzt sein; jeder andere Wert (auch ein fehlender Schlüssel) lässt das Laden fehlschlagen. |
| `providers` | list | *(erforderlich)* | Deine Debrid- und Usenet-Konten, jeweils ein Eintrag. Siehe unten [Konten](#accounts). Die alten Top-Level-Schlüssel `token`, `download_tokens` und `strm_link_token` (vor `providers`) sind veraltet: Sie werden weiterhin geladen, und zwar als ein einzelnes Real-Debrid-Konto, beim Start erscheint aber eine Warnung. Ein `providers`-Block, der bereits Real-Debrid konfiguriert, hat Vorrang, und der übrige Schlüssel wird ignoriert. |
| `mount_path` | string | je nach Betriebssystem | Der Dateisystempfad, unter dem dein rclone-Mount liegt. zurg nutzt ihn, damit Medienserver (Plex, Jellyfin, Emby) die Dateien finden. Wird auch als Mount-Punkt verwendet, wenn `rclone_enabled` auf `true` steht. Standard ist `/mnt/zurg` (Linux), `/Volumes/Zurg` (macOS) oder `Z:` (Windows). Docker-Nutzer sollten dies auf `/zurg_mnt/zurg` setzen, zusammen mit dem Volume-Mount `/zurg_mnt:/zurg_mnt:rshared` (siehe [docker.md](../setup/docker.md)). |
| `base_url` | string | `""` | Die von außen erreichbare URL deiner zurg-Instanz. Sie wird in STRM-Dateien eingebettet, damit Medienserver Inhalte streamen können. Ist sie nicht gesetzt, enthalten STRM-Dateien `localhost`-URLs, die von anderen Geräten aus nicht funktionieren. Nutze deine Tailscale-IP, deine LAN-IP oder eine Domain hinter einem Reverse-Proxy. Beispiel: `http://100.x.x.x:9999` |

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/mnt/zurg"
base_url: "http://192.168.0.123:9999"
```

### Konten {#accounts}

Jeder Eintrag in `providers` ist ein Konto. Beliebig viele können parallel laufen, zum Beispiel Real-Debrid, TorBox, AllDebrid, Premiumize, Debrid-Link und Offcloud zusammen oder mehrere Konten beim selben Dienst.

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `type` | string | *(erforderlich)* | Welches Backend das Konto nutzt: `realdebrid`, `torbox`, `alldebrid`, `premiumize`, `debridlink`, `offcloud`, `nzb` oder `torbox_nzb` ([TorBox gehostetes Usenet](../providers/torbox-nzb.md)). |
| `name` | string | Wert von `type` | Unterscheidet dieses Konto von anderen desselben Typs. Es ist der Name, den der `provider`-Filter, das [Verzeichnis pro Konto](#per-account-directories), Cache-Pfade und das Dashboard verwenden. Namen müssen über alle Einträge hinweg eindeutig sein, und `e` ist für das STRM-Link-Routing reserviert. |
| `token` | string | *(erforderlich)* | Der API-Token oder Schlüssel des Kontos. Einen Real-Debrid-Token holst du unter http://real-debrid.com/?id=20475782, einen TorBox-Token unter https://torbox.app/settings, einen AllDebrid-Token unter https://alldebrid.com/apikeys?uid=1kk5i. Wird von `nzb` nicht verwendet, denn dieser authentifiziert sich über `nntp`. Ein Real-Debrid-Token kann auch über die Umgebungsvariable `TOKEN` oder `RD_TOKEN` angegeben werden, damit beim ersten Start automatisch eine Konfiguration entsteht. |
| `download_tokens` | list | `[]` | **Real-Debrid und AllDebrid:** Backup-API-Tokens für denselben Dienst, die genutzt werden, wenn das Bandbreitenkontingent des aktiven Tokens aufgebraucht ist. Sie verwenden den Katalog dieses Eintrags, inklusive eines [lokalen Katalogs](#local-debrid-catalogs), ohne die Torrent-Bibliotheken der zusätzlichen Konten zu importieren. **TorBox:** wird akzeptiert, aber die Rotation ordnet kontospezifische Torrent-/Datei-IDs nicht neu zu. Verwende für verschiedene Konten separate Provider-Einträge. Wird von NZB nicht genutzt. Premiumize, Debrid-Link und Offcloud brauchen separate Konto-Einträge, weil ihre gespeicherten Datei-IDs zum auflistenden Konto gehören. |
| `strm_link_token` | string | `""` | Ein separater API-Token, der die Zugriffe auf den Endpunkt `/strm/` auflöst. So verbraucht ein Player beim Öffnen einer `.strm` nicht den Token, über den das aktive Mount streamt. Fällt auf `token` zurück, wenn nichts gesetzt ist. **Real-Debrid und AllDebrid**, die beiden Backends, die Zugangsdaten rotieren, und deshalb die beiden, bei denen ein eigener Schlüssel für den `.strm`-Traffic Sinn ergibt. Wird bei `torbox`- und `nzb`-Einträgen akzeptiert, aber nicht genutzt. Premiumize, Debrid-Link und Offcloud akzeptieren hier nur den eigenen `token` des Kontos. |
| `disabled` | bool | `false` | Behält ein Konto in der Konfiguration, ohne es zu laden. Sind alle Einträge deaktiviert, schlägt das Laden fehl. |
| `watchlist` | bool | `false` | Markiert das Konto, das bei neuen Torrent-Hinzufügungen zuerst probiert wird. Das betrifft die Download-Client-Endpunkte und die Torznab-Indexer von acquisition. Höchstens ein Eintrag darf es setzen, und nie ein `nzb`- oder `torbox_nzb`-Eintrag. Ohne gesetzten Eintrag wird das erste Konto genutzt, das Torrents hinzufügen kann. NZBs von acquisition gehen an das Usenet-Backend und nie an dieses Konto. Siehe [Watchlist](#watchlist). |
| `add_torrents` | bool | `true` | Ob diesem Konto überhaupt neue Torrents angeboten werden: die, die die Download-Client-Endpunkte bekommen, und die, die acquisition von Torznab-Indexern übernimmt. Setze es auf `false` für ein Archivkonto oder eines, dessen Kontingent anderweitig vergeben ist. Es liefert und liest weiter seine Bibliothek, aber es wird nie etwas Neues darauf gelegt. **Die Reihenfolge der `providers:`-Liste ist die Reihenfolge, in der die Konten probiert werden, die neue Hinzufügungen annehmen.** Dieser Schlüssel und diese Reihenfolge gehören daher zusammen. Ein Konto mit `watchlist: true` wird unabhängig von seiner Position zuerst probiert. Kann nicht zusammen mit `watchlist: true` im selben Eintrag gesetzt werden. Bei einem `nzb`-Eintrag wird er mit einer Warnung beim Start ignoriert, weil ein News-Server nie einen Torrent bekommt. Siehe [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see). |
| `warm_connections` | int | `1` | Wie viele Verbindungen dieses Konto zu jedem Host, den es bisher genutzt hat, offen und per Handshake aufgebaut hält, damit ein Lesezugriff nicht erst eine öffnen muss. Maximal 4. `-1` hält keine offen. Wird bei einem `nzb`-Eintrag ignoriert, dessen Untergrenze pro Konto gilt und unter [`nntp.warm_connections`](../guides/usenet.md) steht. Siehe [warme Verbindungen](#warm-connections). |
| `nntp` | block | *(erforderlich für `nzb`)* | News-Server-Zugangsdaten. Erforderlich für den Typ `nzb` und wird von allen anderen Typen ignoriert. |

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    strm_link_token: YOUR_RD_API_TOKEN_FOR_STRM
    download_tokens:
      - ANOTHER_RD_API_TOKEN
      - ANOTHER_RD_API_TOKEN_2
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    watchlist: true
  - type: realdebrid
    name: rd-backup
    token: YET_ANOTHER_RD_API_TOKEN
    disabled: true
```

Die `download_tokens`-Einstellung von TorBox bietet nicht den Wiedergabe-Fallback über mehrere Konten, den RD- und AD-Locked-Links erlauben. Der Resolver tauscht den API-Schlüssel aus, behält aber die Torrent-/Datei-IDs aus der bestehenden Quelle. Separate TorBox-Provider-Einträge halten die IDs und den Katalog jedes Kontos unabhängig. Für eine lokale Bibliothek lege die portablen Manifeste im eigenen Quellverzeichnis jedes Eintrags ab.

#### TorBox-Seeding {#torbox-seeding}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `tb_seed_torrents` | string | `never` | Ob die Torrents, die zurg zu einem TorBox-Konto hinzufügt, geseedet werden. `never` schaltet das Seeding bei jedem Hinzufügen aus. `auto` überlässt die Entscheidung der Seeding-Einstellung in deinem TorBox-Konto. `always` schaltet das Seeding bei jedem Hinzufügen ein. Gilt für jedes TorBox-Konto in der Konfiguration und wirkt sich auf das nächste Hinzufügen aus, sobald es geändert wird. Jeder andere Wert verhindert, dass zurg startet. |

```yaml
tb_seed_torrents: never
```

Lass es auf `never`, solange du es nicht brauchst. Es ist für private Tracker gedacht, die dein Ratio zählen. Ein Release, das über den [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see)-Endpunkt als `.torrent`-Datei abgerufen wird, wird mit dieser Einstellung hinzugefügt. Bei `always` (oder `auto` bei einem Konto, das auf Seeding eingestellt ist) lädt TorBox es daher zurück in den Swarm des Trackers hoch. Auch das Importieren in Sonarr oder Radarr verhindert das nicht: Ein fertiger Download, den der Client entfernt, bleibt im Konto.

**Ein Seeding-Torrent belegt einen deiner aktiven Slots auf deinem Tarif, solange er seedet.** TorBox zählt einen seedenden Torrent genauso wie einen, der gerade heruntergeladen wird. Die Tarife erlauben 3, 5 oder 10 gleichzeitig (Essential, Standard, Pro) und seeden bis zu 24 Stunden, 14 Tage bzw. 30 Tage. Sobald alle Slots von seedenden Torrents belegt sind, stocken neue Abrufe und Reparaturen auf diesem Konto, bis ein Slot frei wird – entweder wenn die Seeding-Zeit eines Torrents abläuft oder wenn du ihn bei TorBox löschst. Seeding zählt außerdem als Upload auf die Fair-Use-Limits von TorBox. Bei `never` passiert all das nicht, deshalb ist es die Standardeinstellung.

`auto` schickt TorBox gar keine Seeding-Vorgabe, sodass die Seeding-Einstellung deines Kontos gilt. Bei einem Konto, bei dem niemand sie geändert hat, ist das TorBox' eigenes Auto. `always` und `never` überschreiben die Kontoeinstellung für die Torrents, die zurg hinzufügt, und lassen alles andere im Konto unverändert.

#### Usenet-Konten {#usenet-accounts}

Der `nzb`-Typ ist Usenet und kein Debrid-Dienst: `.nzb`-Dateien, die in das Verzeichnis `nzbs/` gelegt werden, werden zu Torrents in der Bibliothek, und Lesezugriffe werden erfüllt, indem Artikel von deinem News-Server geholt und bei Bedarf dekodiert werden. Es wird nur ein aktivierter `nzb`-Eintrag unterstützt, da beide dasselbe Verzeichnis durchsuchen würden. Weitere News-Server trägst du stattdessen unter `nntp.servers` dieses Eintrags ein. Sie liefern dann dieselbe Bibliothek und nicht eine zweite Kopie davon. Ein `nzb`-Eintrag neben einem [`torbox_nzb`](../providers/torbox-nzb.md)-Eintrag wird aus demselben Grund abgelehnt. Betreibe diesen Typ in einer eigenen Instanz mit eigenem Arbeitsverzeichnis.

| Option | Typ | Standard | Beschreibung |
|--------|-----|----------|--------------|
| `host` | string | *(erforderlich)* | Der Hostname des News-Servers, z. B. `news.example.com`. |
| `port` | int | `563` mit TLS, `119` ohne | Der Port des News-Servers. |
| `tls` | bool | `false` | Verpackt die Verbindung in TLS. |
| `username` | string | `""` | Der Benutzername des Kontos. |
| `password` | string | `""` | Das Passwort des Kontos. |
| `connections` | int | `8` | Die gleichzeitig erlaubte Verbindungsanzahl des Kontos. zurg liest mit dieser Anzahl. Eine Verbindung schafft nur einen Bruchteil der Bandbreite deines Tarifs, deshalb lastet Streaming das Kontingent erst aus, wenn es alle Verbindungen nutzt und nicht nur einen Artikel nach dem anderen holt. Wenn du mehr einstellst, als dein Tarif erlaubt, werden Verbindungen abgelehnt. Trage deshalb den tatsächlichen Wert ein. |
| `pipeline_depth` | int | `4` | Wie viele Artikel zurg gleichzeitig auf einer Verbindung anfordert. Das Maximum ist 8. Setze den Wert auf `1`, wenn dein Server nicht mehrere Befehle gleichzeitig verarbeiten kann. zurg setzt ihn selbst auf 1 zurück und gibt eine Warnung aus, wenn Batches immer wieder abbrechen. |
| `socket_receive_buffer_kb` | int | nicht gesetzt | Legt den Kernel-Empfangspuffer jeder Verbindung auf diese Anzahl KiB fest. Lass die Option ungesetzt. Ein festgelegter Puffer wird vom Kernel nicht mehr angepasst. Unter Linux hält das das Empfangsfenster bei etwa 64 KiB und kostet über eine Leitung mit spürbarer Latenz den größten Teil der Bandbreite des Kontos. Die Option ist nur für Kernel gedacht, die nie anpassen oder deren Obergrenze zu niedrig eingestellt ist. |
| `cache_size_mb` | int | `512` | Wie viele dekodierte Artikeldaten im Speicher gehalten werden. Der Wert gilt für alle gelesenen Dateien zusammen und nicht pro Datei. |
| `servers` | list | `[]` | Weitere News-Konten, auf die pro Artikel zurückgegriffen wird. Siehe [mehr als ein News-Server](#more-than-one-news-server). |

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
```

##### Mehr als ein News-Server {#more-than-one-news-server}

Die Aufbewahrungsdauer gilt pro Anbieter. Ein Artikel, den ein Server schon gelöscht hat, ist sehr oft noch auf einem anderen. Ohne zweiten Account bleibt zur Reparatur eines verlorenen Artikels nur PAR2, und dafür muss das **gesamte Release** einmal komplett gelesen werden. Ein zweiter Server macht also den Unterschied zwischen dem Laden eines einzelnen Artikels und dem erneuten Lesen von allem.

Die Schlüssel oben beschreiben den ersten Account. Alles unter `servers` ist ein weiterer Account, der nur dann gefragt wird, wenn die davor den Artikel nicht hatten. Eine bestehende Konfiguration mit nur einem Server funktioniert unverändert weiter.

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `name` | string | Wert von `host` | Benennt den Account in den Logs. |
| `host`, `port`, `tls`, `username`, `password`, `connections`, `pipeline_depth`, `warm_connections`, `socket_receive_buffer_kb` | | | Wie oben. Jeder Account hat sein eigenes Verbindungskontingent. Pipelining und Empfangspuffer werden pro Account gesetzt, weil die Verträglichkeit dafür vom Server abhängt. |
| `priority` | int | `0` | Wer zuerst gefragt wird, niedrigster Wert zuerst. Accounts mit gleicher Priorität werden in der geschriebenen Reihenfolge gefragt. Ein Account mit freier Verbindung wird aber einem vorgezogen, dessen Kontingent aufgebraucht ist. So teilen sich zwei gleichwertige Accounts die Last. |
| `backup` | bool | `false` | Markiert einen Backup-Account, der erst dann abgefragt wird, wenn jeder Hauptaccount mit *no such article* geantwortet hat. Ein Hauptaccount, der **ausgelastet** ist, reicht dafür nicht: zurg wartet darauf, statt volumenabgerechnete Bytes für etwas auszugeben, das ein unbegrenzter Account auch geliefert hätte. |
| `backbone` | string | `""` | Der Artikel-Spool, auf den dieser Account verweist. Zwei Accounts mit demselben Backbone haben dieselben Artikel. Hat einer einen Artikel als fehlend gemeldet, wird der andere übersprungen, statt dieselbe Frage erneut zu stellen. |

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # the first account
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com          # only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

Die Vollständigkeitsprüfung, die entscheidet, ob ein Release repariert werden muss, fragt jeden Account, bevor ein Artikel als fehlend gilt. So löst ein Release, das bei einem Anbieter Lücken hat, keine PAR2-Rekonstruktion aus, wenn ein anderer Anbieter es noch liefern kann.

Ein Schlüssel auf oberster Ebene bestimmt, was Reparaturen zurücklassen:

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `par2_patch_cache_mb` | int | `512` | Wie viel von `data/par2/` die durch PAR2-Reparatur wiederhergestellten Bytes belegen dürfen. Diese Bytes sind das Einzige, was ein Leser beim News-Server nicht noch einmal anfordern kann, denn die Artikel, die sie enthalten, sind weg. Sie zu behalten heißt, dass ein Neustart nicht das komplette erneute Lesen des Releases kostet, nur um dieselben paar Megabyte zurückzuholen. Gespeichert werden nur die Bereiche der verlorenen Artikel, das sind einstellige Megabyte pro beschädigtem Release. Wird das Budget überschritten, fliegen ganze Releases raus, zuerst die am längsten nicht genutzten (LRU). Ein negativer Wert schaltet das Speichern aus, und Reparaturen bleiben für die Laufzeit des Prozesses im Arbeitsspeicher. |

Zwei weitere regeln, was eine geparste NZB im Speicher kostet:

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `nzb_segments` | string | `mmap` unter Linux/macOS/BSD, `resident` unter Windows | Wie die Artikelliste einer geparsten NZB gehalten wird. **Erfordert einen Neustart.** `mmap` schreibt die Listen nach `data/nzb-index/<id>.bin` und mappt diese Datei bei Bedarf. So liegen die Bytes im Seiten-Cache statt im Heap von zurg. `reparse` gibt sie frei, sobald das Release zur Ruhe gekommen ist, und liest die NZB von der Platte neu, wenn ein Lesezugriff oder eine Reparatur sie braucht. Das kostet keinen Plattenplatz. `resident` behält alle davon für die Laufzeit des Prozesses im Speicher. Das ist **das bisherige Verhalten** und das, was jeder frühere Build getan hat. Unbekannte Werte nehmen den Standard und werden in einer Startwarnung genannt. Der tatsächlich aktive Modus wird beim Start in jedem Fall geloggt. |
| `nzb_segments_idle_secs` | int | `120` | Wie lange die Artikelliste eines Releases nach dem letzten Zugriff behalten wird, in den lazy Modi. **Erfordert einen Neustart.** Eine Prüfung läuft alle 30 Sekunden. Daher sind 10 das kürzeste Fenster, das sie einhalten kann, und die Untergrenze im Dashboard. Wird bei `resident` ignoriert, weil dieser Modus nie etwas freigibt. `0` nimmt den Standard. |

Der Kompromiss sollte klar gesagt werden, denn er ist nicht der übliche Speicher-gegen-Tempo. Eine Auflistung (ein Bibliotheks-Refresh, eine Fingerprint-Prüfung, ein *arr, der fragt, ob ein Job fertig ist) berührt in keinem Modus je einen Artikel. Name, Größe und Artikelanzahl einer Datei werden direkt aus dem Eintrag beantwortet. Die lazy Modi kosten das *erste* Lesen eines Releases, das für `nzb_segments_idle_secs` lang nicht angefasst wurde. Dafür sparen sie den Heap, den die Artikellisten sonst die restliche Zeit belegen. Gemessen an einem Release mit 60 Dateien und 30.000 Segmenten (Apple M3 Pro):

| | Heap pro Release, eingependelt | erster Lesezugriff auf ein inaktives Release | pro Artikel auf dem Lesepfad |
|---|---|---|---|
| `resident` | 1.74 MB (58 B/Segment) | — | 6 ns |
| `reparse` | 21.3 kB (0.71 B/Segment) | 39 ms | 52 ns |
| `mmap` | 16.6 kB (0.55 B/Segment) | 0.27 ms | 63 ns |

Zwei Drittel des `mmap`-Neuladens entfallen auf die Prüfsumme über den gerade gemappten Index. Das Mapping selbst dauert 0.08 ms. Die Prüfsumme ist es aber wert: Ohne sie würde ein einzelnes fehlerhaftes Byte in einem Arena als Message-ID ausgeliefert, die niemand gepostet hat. Der News-Server antwortet dann mit einem toten Artikel, und jede Schicht darüber liest das als Schaden am Release.

Und auf einer echten Bibliothek (2,636 NZBs, 27.6 Millionen Segmente, dasselbe Binary dreimal auf demselben Bestand laufen gelassen, im Leerlauf nach einem Scan):

| | Resident-Speicher | aktiver Heap | CPU im Leerlauf | Kaltstart, p50 | Index auf der Platte |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

Warme Öffnungen, Streaming-Durchsatz und Startzeit waren nicht zu unterscheiden. `mmap` ist der Standard, wo es ein echtes Mapping gibt, weil es bei allem außer dem Plattenplatz gewinnt. Das gilt auch für den Kaltstart, denn ein geschriebenes Arena zu mappen ist ein einzelner Systemaufruf, während die NZB erneut zu parsen Megabyte an XML bedeutet. Es kostet etwa 55 Byte Platz pro Artikel und beim Scan einen zusätzlichen Schreibvorgang pro Release. Der Index wird neu geschrieben, sobald sich die NZB ändert, und entfernt, wenn die NZB verschwindet. Wähle `reparse` auf einem Host, auf dem `data/` nicht wachsen darf. Unter Windows gibt es kein Mapping. Der Index würde dort in den Heap eingelesen, und das wäre Resident-Speicher *plus* ein Neuladen. Deshalb bleibt der Standard dort `resident`, und `reparse` ist der lazy Modus, den du dort wählen solltest.

## 2. Medienserver-Integration {#2-media-server-integration}

Verbinde zurg mit deinem Medienserver, damit Bibliotheksaktualisierungen, Metadaten-Abgleich und Watchlist-Überwachung automatisch funktionieren.

### Premiumize, Debrid-Link und Offcloud {#premiumize-debrid-link-and-offcloud}

```yaml
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY_OR_OAUTH_TOKEN
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_TOKEN
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
```

Diese Backends unterstützen das Durchsuchen der Bibliothek, gestreamte und umgeleitete Lesezugriffe, STRM, Magnet-Hinzufügungen, `.torrent`-Uploads und das Löschen. Jedes Konto erscheint außerdem in seinem eigenen Verzeichnis `__<name>__`. Konten fügst du über das Dashboard oder `zurg setup` hinzu. Bei einer unbeaufsichtigten Einrichtung funktionieren `--premiumize-token-file`, `--debridlink-token-file` und `--offcloud-token-file` oder alternativ `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN` und `OFFCLOUD_TOKEN`.

Premiumize mountet abgeschlossene Transfers und Cloud-Dateien, die nach dem Leeren der Transferliste erhalten bleiben. Verschachtelte Ordner behalten ihre Pfade. Hashes, die du über zurg angibst, werden unter `data/premiumize/<account>/sources.json` gespeichert. So bleibt der Abgleich zwischen Konten auch nach einem Neustart oder dem Leeren abgeschlossener Transfers erhalten. Importierte Cloud-Inhalte ohne gespeicherten Hash werden weiterhin gestreamt, können aber weder über den Hash repariert noch anhand des Hashes einem anderen Konto zugeordnet werden. Wenn du einen Premiumize-Transfer über zurg löschst, werden auch die Dateien gelöscht, die zu diesem Transfer gehören. Cloud-Speicher und Fair-Use-Kontingente bleiben die eigenen Limits deines Kontos.

Debrid-Link listet den Seedbox-Inhalt seitenweise auf und löst jede Datei über ihre ID auf. Der veraltete Cache-Endpunkt wird nicht verwendet. Ein Hinzufügen, das nur aus dem Cache kommen darf, kann einen Treffer nur anhand der Antwort auf das Hinzufügen feststellen. Tägliche Limits bei Hinzufügungen und Traffic werden als Kontolimits gemeldet. Nach einer Flood-Ablehnung pausiert das Backend.

Offcloud löst Dateihandles über den Cloud-Explore-Endpunkt auf. Dateigrößen werden gegen den Delivery-Server geprüft. Zwischengespeicherte Torrent-Metadaten liefern Ordnerpfade, wenn sie eindeutig zugeordnet werden können. Eine mehrdeutige Dateiliste wird als Fehler gemeldet. Fehlerhafte Magnets werden vor dem Absenden abgelehnt.

Delivery-URLs werden aktualisiert, wenn ihr Cache abläuft oder ein Lesezugriff sie ungültig macht. Halte generierte URLs und STRM-Zugriffe privat. Provider-Kontingente gehören dem Konto, das die Bytes ausliefert. Diese drei Backends verwenden pro Kontoeintrag genau eine Zugangsdaten und rotieren nicht über die Datei-IDs eines anderen Kontos.

### Plex-Integration {#plex-integration}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `plex_server_url` | string | `""` | URL deines Plex-Servers. Erforderlich für Plex-Matching und Watchlist-Funktionen. Beispiel: `http://localhost:32400` |
| `plex_token` | string | `""` | Dein Plex-Authentifizierungstoken. Erforderlich zusammen mit `plex_server_url`. |
| `plex_scan_check_url` | string | Wert von `plex_server_url` | Der Plex-Server, bei dem zurg nachfragt, ob gerade ein Bibliotheks-Scan läuft, bevor es den Mount neu startet. Solange einer läuft, wartet zurg. Verschwindet ein Mount mitten in einem Scan, wirft Plex alles weg, was es nicht sehen konnte. Setze diesen Wert auf einer Instanz, die keine eigene Plex-Integration betreibt. Meist hat man eine Instanz pro Anbieter. Würdest du `plex_server_url` dort setzen, würde auch das Plex-Matching starten. |
| `plex_scan_check_token` | string | Wert von `plex_token` | Das Token für `plex_scan_check_url`. |
| `plex_match_every_mins` | int | `1440` | Wie oft (in Minuten) zurg deine Plex-Bibliothek scannt, um Torrents mit Plex-Einträgen abzugleichen. So funktionieren Dinge wie die Anzeige, welche Torrents zu welchen Plex-Medien gehören. Minimum 1; `0` nutzt den Standardwert. Setzt voraus, dass `mount_path` gesetzt ist. |
| `plex_watchlist_enabled` | bool | `false` | Veraltete Schreibweise von `watchlist.enabled` (siehe [Watchlist](#watchlist)); wird weiterhin berücksichtigt. |
| `plex_watchlist_check_every_secs` | int | — | Veraltete Schreibweise von `watchlist.check_every_secs`; wird weiterhin berücksichtigt, wenn der Block keinen Wert setzt. |
| `watchlist_quality` | string | `"best"` | Veraltete Schreibweise von `watchlist.quality`; wird weiterhin berücksichtigt, wenn der Block keinen Wert setzt. |
| `plex_settings_policy` | string | `"guard"` | Wie weit zurg die Plex-Einstellungen korrigieren darf, die für einen Debrid-Mount wichtig sind. Eine von `off` (nichts anfassen), `warn` (alles melden, nichts ändern), `guard` (nur Einstellungen korrigieren, bei denen ein falscher Wert eine Bibliothek kostet, den Rest melden) oder `enforce` (zusätzlich Einstellungen korrigieren, durch die Plex ganze Dateien dekodiert, für ein Ergebnis, das niemand sieht). Alles mit einer sichtbaren Funktion dahinter — Skip Intro, Skip Credits, Vorschaubilder beim Spulen, Kapitelbilder, Lautstärkeangleichung, Sonic Analysis — wird nur gemeldet. Siehe [Plex-Einstellungen](../guides/plex.md#recommended-plex-settings). |
| `plex_settings_ignore` | list | — | Plex-Präferenz-IDs, die zurg unabhängig von der Richtlinie in Ruhe lässt. Groß- und Kleinschreibung wird ignoriert. Das gilt pro Einstellung, nicht pro Stufe, sodass das Abmelden von einer die anderen daneben nicht aufgibt. Eine ID, die zurg nicht kennt, wird beim Start gemeldet und ändert nichts. Der Schalter **Let Plex Empty Its Own Trash** im Dashboard schreibt `autoEmptyTrash` in diese Liste. Siehe [Eine Einstellung ausschließen](../guides/plex.md#opting-out-of-one-setting). |

> **Hinweis:** Plex konfigurierst du am besten über den Authentifizierungsablauf im Dashboard (Web-UI). Dabei werden `plex_server_url` und `plex_token` zurück in `config.yml` geschrieben. Die oben genannten Schlüssel werden für die manuelle Konfiguration weiterhin unterstützt.

```yaml
plex_server_url: "http://localhost:32400"
plex_token: "your-plex-token"
plex_match_every_mins: 1440
```

### rex

zurg kann eine [rex](../../rex/with-zurg.md) füllen, einen Medienserver für die offiziellen Plex-Apps, der jede Datei aus zurg einliest.

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `rex_url` | string | `""` | URL der rex, die ihre Bibliothek aus diesem zurg aufbaut, zum Beispiel `http://192.168.1.20:32400`. Wenn du im Dashboard bei der Plex-Anmeldung eine rex auswählst, setzt zurg hier die Adresse, unter der rex Quellen annimmt (ihre LAN- oder Tailscale-Adresse, nur HTTP), und der Feed startet ohne Neustart. Setze sie von Hand, wenn du eine rex ohne Plex-Anmeldung füttern willst. zurg schiebt dann seine Bibliothek an rex: jede Videodatei in einem konfigurierten Verzeichnis, jede Audiodatei in einem mit `rex_music` und die Comics in einem mit `rex_photos`, mit Pfad, Größe, IMDb-ID und den Medieninformationen, die ffprobe ausgelesen hat. Das passiert, sobald die Bibliothek geladen ist, alle `rex_snapshot_every_hours` und jedes Mal, wenn ein Release hinzugefügt, analysiert, umbenannt, verschoben oder gelöscht wird. rex kann eine Datei nicht abspielen, bevor ffprobe sie analysiert hat. Deshalb schaltet das Setzen von `rex_url` `auto_analyze_new_torrents` ein, egal was dieser Schlüssel sagt. Dann analysiert zurg den Rest der Bibliothek, sobald sie geladen ist, und danach täglich. Jede Prüfung liest vom Konto, das das Release hat. Halte die Verzeichnisse also eng und lass `tags_*`-Filter weg, wenn du keine Bibliothek willst, die du nie ansiehst, denn sonst wird jedes Release im Konto analysiert und das kostet Datenverkehr. Eine Aktualisierung sucht außerdem die IMDb-ID jedes neuen Releases über `dmm_api_key`, bevor sie es einsortiert (siehe `dmm_api_key`, wie DMM Releases platziert). Untertitel, die ein \*arr oder Bazarr in `__magic__` neben einem Video ablegt, gehen mit ihm an rex (siehe [`__magic__`](../guides/magic.md)). zurg sagt rex, wo die Dateien zu lesen sind: sein WebDAV unter `http://<address>:<port>/dav`, mit `username` und `password`, wenn sie gesetzt sind. Die Adresse ist `host`, wenn dort eine einzelne Adresse steht. Ansonsten, also im Standard, ist es die Adresse, über die zurgs Verbindung zu rex hinausgeht, und rex muss zurg dort erreichen können. In einem Container ist das die eigene Adresse des Containers, und die erreicht rex nur von derselben Linux-Maschine aus. Unter Windows und macOS installierst du zurg deshalb mit dem Installer statt in Docker Desktop. Unter Linux gibst du dem zurg-Container, wenn rex auf einer anderen Maschine läuft, `network_mode: host` ([rex mit zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex)). Eine rex, die nicht erreichbar ist, wird erneut versucht und bekommt danach die ganze Bibliothek. Auf sie wartet nichts. Solange `plex_server_url` diese selbe rex ist, wird kein Plex-Scan geschickt. Nach jedem Snapshot und alle zehn Minuten liest zurg die in rex gemachten Fix Matches für seine Releases und behält jedes als die von Hand gesetzte ID des Releases. Ausnahme: Du hast seitdem auf der Verwaltungsseite eine andere ID gesetzt. DMM platziert das Release dann anhand dieser ID. Um einem Verzeichnis eigene Bibliotheken in rex zu geben, setze dort [`rex_shows`, `rex_movies`, `rex_music` oder `rex_photos`](#directory-options). Lass `rex_url` leer, wenn du keine rex betreibst. |
| `rex_source` | string | `"zurg"` | Der Quellname, unter dem rex dieses zurg kennt. Gib jedem zurg, das dieselbe rex füttert, einen eigenen Namen. |
| `rex_snapshot_every_hours` | int | `6` | Wie oft die ganze Bibliothek erneut an rex geschickt wird. So wird alles repariert, was ein verpasster Versand zurückgelassen hat. Der Standard passt zu jedem Setup. |

```yaml
rex_url: "http://192.168.1.20:32400"
```

### Watchlist

Füge etwas zu deiner Plex-Watchlist hinzu, und zurg holt es sich. Jeder neue Watchlist-Eintrag wird bei deinen Indexern gesucht. Ein Newznab-Indexer liefert eine NZB. Sie landet im Usenet-Backend genauso wie ein Sonarr-Grab oder ein Stremio-Play. Alle drei teilen sich dieselben Benennungsregeln, damit sie die Grabs der anderen finden und nicht doppelt laden. Ein Torznab-Indexer liefert einen Torrent. Er wird nur dann zu einem Debrid-Konto hinzugefügt, wenn dieses Konto ihn bereits gecacht hat. `prefer` legt fest, welche Art zuerst probiert wird, wenn Releases in derselben Auflösung zur Wahl stehen. Ein Film wird als ein einzelner Release geholt. Eine Serie wird Staffel für Staffel geholt, und Staffel-Packs kommen vor einzelnen Episoden. Für eine Staffel, zu der niemand ein Pack gepostet hat, werden die einzelnen Episoden genommen, die die Suche gefunden hat, jeweils der beste Release. Der Eintrag verschwindet erst dann aus der Watchlist, wenn der dahinterliegende Release geprüft wurde und `remove_after_grab` es erlaubt. Fehlgeschlagene Einträge bleiben auf der Liste. Sie werden nach 5, 10 und 15 Minuten erneut versucht, dann nach einer Stunde, danach in immer größeren Abständen. Ein Titel, der zwei Wochen lang fehlgeschlagen ist, wird pausiert, bis du ihn auf der Acquisition-Seite wieder fortsetzt. Siehe [Persistenz und Wiederherstellung](../guides/acquisition.md#persistence-and-recovery).

Es braucht einen `plex_token` und mindestens einen Indexer. Hat sie keine eigene Liste, leiht sie sich die des Stremio-Addons. Der Monitor spricht mit Plex' Cloud-Dienst, daher ist `plex_server_url` nicht nötig. NZBs brauchen einen `nzb`- oder `torbox_nzb`-Provider auf derselben Instanz. Torrents brauchen ein Debrid-Konto, das sie annimmt. Eins von beiden reicht.

Alle Optionen unten findest du auf der Konfigurationsseite unter **Plex Watchlist**, inklusive der Indexer-Liste. Das Dashboard schreibt diesen Block statt der alten flachen Schlüssel. Wenn du den Monitor dort ausschaltest, wird auch `plex_watchlist_enabled` gelöscht, da dieser Schlüssel per ODER mit dem Schalter verknüpft ist.

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `enabled` | bool | `false` | Startet den Monitor. Der alte Schlüssel `plex_watchlist_enabled` zählt weiterhin. |
| `check_every_secs` | int | `60` | Wie oft die Watchlist im Cloud-Dienst von Plex abgefragt wird. |
| `indexers` | list | `[]` | Zu durchsuchende Indexer, jeweils mit `name`, `url`, `api_key` sowie optional `api_path` und `type`. `type: torznab` kennzeichnet einen Torrent-Indexer. Fehlt der Eintrag, gilt `newznab`. Gleiche Form wie `stremio.indexers`, das komplett übernommen wird, wenn diese Liste leer ist. |
| `prefer` | string | `"usenet"` | Welche Art zuerst versucht wird, wenn sowohl eine NZB als auch ein Torrent in derselben Auflösung infrage kommen. Zuerst entscheidet die Auflösung, daher kommt ein 2160p-Torrent vor einer 1080p-NZB. `usenet` probiert zuerst NZBs, `torrents` zuerst Torrents, und `best` überlässt die Entscheidung allein der Rangliste. Siehe [Newznab und Torznab](../guides/acquisition.md#newznab-and-torznab). |
| `max_size_gb` | int | `0` | Releases, die größer sind, werden bei Filmen und einzelnen Episoden verworfen, bei Staffel-Packs, die pro Episode mehr als diesen Wert belegen. `0` bedeutet keine Grenze, daher nimmt `best` auch ein Full-Disc-Remux. Releases, deren Größe der Indexer nicht angegeben hat, bleiben erhalten. |
| `max_season_size_gb` | int | `0` | Eine Obergrenze für jede Staffel, die ein Staffel-Pack enthält, pro benannter Staffel. `0` bedeutet keine Grenze: Ein Pack wird nur über `max_size_gb` pro Episode begrenzt, sofern das gesetzt ist, damit das Remux einer langen Staffel weiterhin zählt. |
| `quality` | string | `"best"` | Welcher Release gewinnt: `best` (zuerst Auflösung, dann Größe), `4k`, `1080p`, `720p` (bevorzugt diese Auflösung, fällt sonst auf best zurück) oder `smallest`. Der alte Schlüssel `watchlist_quality` zählt weiterhin. Hier nur ein Wert; nur `acquisition.quality` nimmt eine Liste (siehe [Acquisition-Quellen](#acquisition-sources)). |

Der Block `acquisition` nimmt außerdem `concurrency` (Standard `8`, `1` bis `200`) an, also wie viele Titel gleichzeitig gesucht, geprüft und abgelegt werden, sowie `indexer_concurrency` (Standard `3`, `1` bis `16`), also wie viele Anfragen gleichzeitig an einen Indexer gehen. Halte letzteren Wert niedrig, wenn ein Indexer-Schlüssel geteilt wird.

`exclude_words` gibt es in diesem Block nicht. Um Wörter wie `DV` oder `HDR10+` aus den Watchlist-Grabs herauszuhalten, füge einen `acquisition:`-Block hinzu, der nur `exclude_words` enthält. Alle oben genannten Einstellungen gelten weiterhin. Siehe [Releases nach Namen ausschließen](../guides/acquisition.md#excluding-releases-by-name).

```yaml
plex_token: "your-plex-token"
watchlist:
  enabled: true
  check_every_secs: 60
  quality: best
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: your-api-key
```

### Erwerbsquellen {#acquisition-sources}

`acquisition.sources` listet die Dienste auf, für die zurg Inhalte beschafft, jeweils in der gemeinsamen Warteschlange, die unter [Beschaffungsquellen](../guides/acquisition.md) beschrieben ist. Die Sucheinstellungen (`indexers`, `quality`, `prefer`, `max_size_gb`, `max_season_size_gb`) stehen neben `sources` im `acquisition:`-Block und fallen auf den `watchlist:`-Block oben zurück. Nur `acquisition.quality` akzeptiert außerdem eine Liste von Auflösungen, zum Beispiel `[1080p, 4k]`: zurg behält dann für jeden Film auf der DMM-Wunschliste eine Kopie in jeder dieser Auflösungen. Serien auf dieser Liste und alle anderen Quellen nehmen dagegen die höchste Auflösung der Liste als ihre einzige `quality`. Siehe [Eine Kopie in mehreren Auflösungen](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

`best_first` gehört nur zum `acquisition:`-Block und ist standardmäßig aus. Eingeschaltet sorgt es dafür, dass der erste Download einer `radarr`- oder `sonarr`-Quelle der Reihenfolge der Präferenzen im Qualitätsprofil folgt. Die beste erlaubte Auflösung kommt zuerst. Alles, was den Cutoff erreicht oder übertrifft, zählt als Cutoff. Schlägt ein Release fehl, geht zurg im Profil eine Stufe tiefer. Ist es aus, nimmt ein Film das erlaubte Release, dessen Prüfung am wenigsten kostet. Eine Serie nimmt die `quality`, die an erster Stelle steht. Der Upgrade-Durchlauf strebt danach den Cutoff an. Das beste Release ist öfter ein großes Archivset, deshalb kommt die erste Datei meist später an. Siehe [Das beste Profil-Release zuerst nehmen](../guides/acquisition.md#taking-the-profiles-best-first).

`exclude_words` (Liste, Standard leer) steht ebenfalls dort und hat keinen Fallback auf die Watchlist. Ein Release, dessen Name eines dieser Wörter enthält, wird nie übernommen, egal aus welcher Quelle. Der Abgleich erfolgt nach ganzen Wörtern und ignoriert Groß- und Kleinschreibung, daher erfasst `DV` nicht `DVDRip`. `DV`, `DoVi` und `Dolby Vision` zählen als ein Wort, ebenso `HDR10+` und `HDR10Plus`. `HDR10` und `HDR10+` sind verschiedene Wörter. Ein Eintrag ohne Buchstaben oder Ziffern wird beim Start abgelehnt. Die vollständigen Regeln und wie sie mit Radarr- und Sonarr-Profilen zusammenspielen, stehen unter [Releases nach Name ausschließen](../guides/acquisition.md#excluding-releases-by-name).

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `name` | string | erforderlich | Buchstaben, Ziffern, `_` und `-`, eindeutig. Kennzeichnet die gespeicherte Warteschlange der Quelle, daher stabil halten. |
| `type` | string | erforderlich | `plex_watchlist`, `seerr`, `radarr` oder `sonarr`. |
| `enabled` | bool | `false` | Eine deaktivierte Quelle bleibt in der Datei erhalten und wird nicht abgefragt. Eine deaktivierte `radarr`- oder `sonarr`-Quelle wird trotzdem schreibgeschützt von der [Duplikatansicht](../guides/acquisition.md#finding-duplicate-releases) der Verwaltungsseite gelesen. |
| `check_every_secs` | int | `60` | Wie oft die Quelle abgefragt wird. |
| `url` | | | Für `seerr`, `radarr` und `sonarr`: die HTTP(S)-Basis-URL des Dienstes, ohne Zugangsdaten, Query oder Fragment. Eine Basis-URL mit nachgestelltem `/api/v1` (Seerr) bzw. `/api/v3` (Radarr, Sonarr) wird ebenfalls akzeptiert. |
| `api_key` | | | Für `seerr`, `radarr` und `sonarr`: den API-Key des Dienstes. Wird als Header gesendet, nie in einer URL, und in geteilten Logs und Configs geschwärzt. |
| `library_path` | string | `mount_path` + `/__magic__` | Nur `radarr` und `sonarr`: wo der \*arr das `__magic__`-Verzeichnis von zurg sieht, zum Beispiel `/data/zurg/__magic__` bei einem Container, der zurg unter `/data/zurg` einbindet. Ein Film- oder Serienordner darunter wird im `__magic__` am selben relativen Pfad abgelegt; ein Ordner woanders wird übersprungen. Muss absolut sein; Windows-Pfade wie `Z:\__magic__` werden akzeptiert. zurg vergleicht den Pfad außerdem damit, wo der \*arr den Download-Ordner eines zurg-Download-Clients sieht, und meldet ein Layout, das Importe zu Kopien macht; siehe [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). |
| `remove_after_grab` | bool | `true` | Nur `plex_watchlist`; ohne Wirkung für `seerr`, `radarr` und `sonarr`. |
| `only_new_items` | bool | `true` | Nur `plex_watchlist`; ohne Wirkung für `seerr`, `radarr` und `sonarr`, bei denen gewünschte Einträge immer bearbeitet werden. |

```yaml
acquisition:
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
  sources:
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /data/zurg/__magic__
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /data/zurg/__magic__
```

### Plex-Bibliothekswartung (nur gleicher Host) {#plex-library-maintenance-same-host-only}

Diese Optionen brauchen Plex auf demselben Rechner wie zurg, weil sie direkt auf dessen Datenbankdatei zugreifen. `plex_server_url` zeigt oft auf einen anderen Host oder Container, und kein HTTP-Endpunkt kann diese Datei herausgeben. Deshalb werden sie über einen expliziten Pfad gesteuert und bleiben aus, bis du einen setzt.

zurg **liest** diese Datenbank nur, über ein Handle mit reinem Lesezugriff. Es schreibt nie hinein und stoppt Plex auch nie. Die einzige Datei, die zurg anlegt, ist ein Snapshot in seinem eigenen `data/plex-backups/`, niemals im Verzeichnis von Plex.

| Option | Typ | Standard | Beschreibung |
|--------|-----|----------|--------------|
| `plex_database_path` | string | `""` | Vollständiger Pfad zu `com.plexapp.plugins.library.db`. Ist er leer, werden alle Funktionen in diesem Abschnitt ausgeschaltet. |
| `plex_sqlite_binary` | string | dort, wo Plex es installiert: `/usr/lib/plexmediaserver/Plex SQLite` unter Linux, `/Applications/Plex Media Server.app/Contents/MacOS/Plex SQLite` unter macOS, `%ProgramFiles%\Plex\Plex Media Server\Plex SQLite.exe` unter Windows | Plex bringt seine eigene SQLite-Version mit. Ein normales `sqlite3` kann bei dieser Datenbank fehlschlagen oder sie beschädigen. |
| `plex_backups_keep` | int | `5` | Anzahl der aufbewahrten Snapshots. Jeder hat die Größe der gesamten Datenbank. Ein ausdrückliches `0` beobachtet nur und erstellt nie einen Snapshot. |
| `plex_backups_every_mins` | int | `15` | Mindestabstand zwischen Snapshots, damit ein zurg in einer Absturzschleife die Datenbank nicht bei jedem Neustart kopiert. |
| `plex_trash_sweep_every_mins` | int | nicht gesetzt (siehe Hinweis) | Wie oft Plex-Einträge entfernt werden, deren Dateien aus dem Mount verschwunden sind. Ist der Wert nicht gesetzt, entscheidet zurg selbst: Die Entfernung läuft alle 60 Minuten, wenn sonst nichts den Papierkorb von Plex leert, und setzt aus, sobald Plex selbst leert. Ein ausdrückliches `0` schaltet die eigene Entfernung von zurg aus und überlässt den Papierkorb dir. Eine negative Zahl schaltet die gesamte Bereinigung aus, einschließlich der Reparatur. `0` gibt das Leeren des Papierkorbs durch Plex **nicht** zurück; dafür sind `plex_settings_ignore` und der Schalter **Let Plex Empty Its Own Trash** im Dashboard zuständig. Siehe [Wer leert den Papierkorb](../guides/plex.md#who-empties-the-trash). |
| `plex_trash_sweep_max_items` | int | `50` | Höchstzahl an Einträgen, die eine Bereinigung entfernen darf. Wird sie überschritten, bricht die Bereinigung ab, ohne etwas zu entfernen. |
| `plex_trash_sweep_max_percent` | int | `10` | Dieselbe Grenze als Prozentwert dessen, was im Papierkorb liegt, sodass sie mit der Größe der Bibliothek mitwächst. |
| `plex_trash_sweep_min_age_days` | int | `14` | Wie lange ein Eintrag sein rotes Papierkorb-Symbol behält, bevor die Bereinigung ihn entfernen darf. Das ist der Ersatzwert für Einträge, zu denen zurg kein Urteil hat. Eine Veröffentlichung, von der zurg weiß, dass sie dauerhaft tot ist, wird ohne Wartezeit entfernt. Eine, die noch repariert wird, bleibt unabhängig vom Alter. Ein ausdrückliches `0` entfernt sofort, sobald die anderen Schutzmechanismen es erlauben. |

**Warum Snapshots**: Da Plex ohnehin jede Nacht ein Backup anlegt, ist die Gefahr etwas anderes. Der Mount wird gestört, während Plex gerade scannt, und dann kann eine Bibliothek in Sekunden leer sein. Ein nächtliches Backup kann in diesem Moment 24 Stunden alt sein. Eines, das kurz bevor zurg den Mount anfasst entsteht, ist dagegen nur Sekunden alt.

#### Was die Papierkorb-Bereinigung niemals entfernt {#what-the-trash-sweep-will-never-remove}

Der Papierkorb von Plex ist keine Liste mit Dingen, die gelöscht werden dürfen. Es ist eine Liste mit Kandidaten, und ein großer Teil davon ist falsch:

- **Ein Eintrag, der noch eine Datei hat.** Plex markiert einen ganzen Film als gelöscht, sobald eine seiner Versionen verschwindet. Deshalb hat ein Eintrag im Papierkorb oft Versionen, die noch abspielbar sind. Der Sweep entfernt stattdessen die Geister-Version. Dadurch kommt der Eintrag mit Sammlungen, Artwork, Wiedergabestatus und `added_at` wieder aus dem Papierkorb heraus. Schlägt diese Reparatur aus irgendeinem Grund fehl, wird der Eintrag **in Ruhe gelassen**. Er bleibt in deiner Bibliothek mit seinem Papierkorb-Symbol. Er wird **niemals gelöscht**.
- **Eine Serie oder Staffel, deren Episoden noch da sind.** Diese haben selbst gar keine Dateien. Deshalb kann nichts am Mount rechtfertigen, sie zu entfernen.
- **Alles, bei dem der Sweep kurz vor dem Entfernen nicht einzeln bestätigt hat, dass die Datei fehlt.**

Das Entfernen läuft einzeln pro Eintrag und nicht über `emptyTrash` von Plex. `emptyTrash` gilt für den gesamten Bereich und würde genau die oben genannten Einträge erwischen. Das ist genau das, was der Sweep auf keinen Fall tun darf.

#### zurg weiß bereits, ob etwas zurückkommt {#zurg-already-knows-whether-it-is-coming-back}

Für jede fehlende Datei fragt der Sweep zuerst zurgs eigenen Reparaturstatus ab, bevor er zum Timer greift.

| zurgs Urteil | Der Sweep |
|---|---|
| die Datei ist noch lesbar (die Filter verstecken sie vor dem Mount) | fällt auf das Altersfenster zurück |
| kaputt, und die Reparatur hat noch nicht aufgegeben | **behält den Eintrag**, egal wie lange die Reparatur dauert |
| kaputt mit einem dauerhaft nicht reparierbaren Grund (infringing, invalid, not allowed, …) | **entfernt ihn sofort**, denn Warten bringt ihn nicht zurück |
| kein Urteil: der Torrent ist ganz aus dem Account verschwunden, oder der Pfad lässt sich nicht auflösen | fällt auf das Altersfenster zurück |

Ein Element mit mehreren Versionen wird als Ganzes bewertet: Ist eine Version noch in Reparatur, bleibt der ganze Eintrag erhalten. Ein Eintrag gilt nur dann als tot, wenn alle Versionen tot sind. Ein fehlgeschlagener Abruf ist nie ein Freibrief zum Löschen. Alles, was zurg nicht bestätigen kann, wird wie bisher über das Altersfenster unten behandelt.

#### Das Papierkorb-Symbol ist ein Status, also wartet die Entfernung {#the-trash-icon-is-a-status-so-removal-waits}

Plex kennt drei Zustände, und nur der mittlere fällt als Problem auf:

| Zustand | Was du siehst |
|---|---|
| Aktiv | ein normaler Eintrag, der abspielt |
| **Im Papierkorb** | der Eintrag ist **weiterhin in deiner Bibliothek und wird weiterhin mitgezählt**, ausgegraut mit einem **roten Papierkorb-Symbol**, und lässt sich nicht abspielen |
| Entfernt | nichts — der Eintrag ist komplett aus Plex verschwunden |

Das Papierkorb-Symbol ist der einzige Hinweis, dass Inhalte fehlen. Wenn du den Eintrag entfernst, verschwindet dieser Hinweis gleich mit: Der Eintrag wirkt nicht mehr kaputt, er existiert einfach nicht mehr. Deshalb bleibt ein Eintrag, zu dem zurg kein Urteil hat, unangetastet, bis er `plex_trash_sweep_min_age_days` Tage lang das Symbol getragen hat. In diesem Zeitfenster kannst du ihn sehen und neu beschaffen. Alles, was danach noch kaputt ist, war Müll, den es sich zu entfernen lohnt.

Außerdem ist es eine dritte Sicherheitsebene neben den Limits und dem Mount-Check: Ein vorübergehendes Mount-Problem löst sich lange vor Ablauf des Zeitfensters von selbst.

Die Wartezeit gilt **nur für das Entfernen**. Eine Reparatur bringt ein abspielbares Element zurück in deine Bibliothek, deshalb passiert sie ohnehin beim nächsten Sweep. Warten würde nur bedeuten, dass ein funktionierendes Element ohne Grund das Papierkorb-Symbol trägt.

Keiner dieser Zustände fasst Dateien an. Die Datei war bereits vom Mount verschwunden, und genau das hat den Tombstone ausgelöst. In deinem Debrid-Konto wird nie etwas gelöscht.

#### Wann es sich weigert zu laufen {#when-it-refuses-to-run}

- zurg verwaltet rclone nicht (`rclone_enabled: false`). Deshalb kann zurg für einen Mount, den es nicht selbst besitzt, nicht bürgen. „Die Datei fehlt“ sagt in diesem Fall also nichts aus.
- rclone läuft nicht, oder der Mount lässt sich nicht lesen. Die Prüfung öffnet eine Datei und liest sie, statt `stat` aufzurufen. Denn ein `stat` wird aus rclones Verzeichnis-Cache beantwortet und klappt noch lange, nachdem das Lesen schon nicht mehr funktioniert.
- Plex scannt gerade. Ein laufender Scan entscheidet noch, was fehlt.
- Eine der beiden Obergrenzen würde überschritten. Das ist der wichtigste Punkt: **Ein Mount, der leer, aber lesbar zurückkommt, besteht alle anderen Prüfungen** und lässt die ganze Bibliothek wie gelöscht aussehen. Wird eine Obergrenze überschritten, bricht der Sweep komplett ab, entfernt nichts und schreibt das ins Log.

Vor dem Entfernen wird ein Snapshot erstellt. Schlägt der Snapshot fehl, bricht der Sweep ab.

> **Ausschalten:** Setze `plex_trash_sweep_every_mins: 0`. Den Schlüssel einfach zu entfernen ist nicht dasselbe: Dann entscheidet zurg anhand dessen, ob Plex seinen eigenen Papierkorb leert. Nach einer Änderung ist ein Neustart von zurg nötig. Damit wird nur das Entfernen durch zurg abgeschaltet. Soll Plex seinen Papierkorb wieder selbst leeren, nutze den Schalter **Let Plex Empty Its Own Trash** im Dashboard oder trag `autoEmptyTrash` in `plex_settings_ignore` ein.

```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plex_trash_sweep_every_mins: 360
plex_trash_sweep_min_age_days: 14
plex_trash_sweep_max_items: 50
plex_trash_sweep_max_percent: 10
```

Der Pfad hier ist der Ort, an dem das Linux-Paket die Datenbank ablegt. Unter macOS und Windows schreibst du den Pfad vollständig aus, da zurg `~` oder `%LOCALAPPDATA%` nicht auflöst. `plex_sqlite_binary` hat bereits als Standard den Ort, an dem Plex es auf jedem System installiert.

| Plex auf | `plex_database_path` |
|---|---|
| macOS | `/Users/you/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db` |
| Windows | `C:\Users\you\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db` |

Setze einen Windows-Pfad in YAML in einfache Anführungszeichen, damit die Backslashes so bleiben, wie sie geschrieben sind.

> **Passende Plex-Einstellung, außerhalb von zurg:** Schalte in Plex unter *Settings → Library → Empty trash automatically after every scan* die Option **aus**. Sie ist in Plex standardmäßig aktiviert und auf einem zurg-Mount riskant: Ein Scan, der auf einen kurz nicht lesbaren Mount trifft, löscht die Bibliothek dauerhaft, statt sie in den Papierkorb zu legen, wo sie mit dem Mount wieder auftauchen würde. zurg schaltet die Option im Standard-Policy `guard` selbst ab und sagt das im Dashboard und im Log. Wenn deine Dateien zwischen Bibliotheksordnern wandern und du diese Aufräumfunktion brauchst, gibt dir der Schalter **Let Plex Empty Its Own Trash** auf der Konfigurationsseite sie wieder an Plex zurück, auf eigenes Risiko.

### Andere Integrationen {#other-integrations}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `jellyfin_server_url` | string | `""` | URL deines Jellyfin-Servers. Aktiviert Benachrichtigungen zur Bibliotheksaktualisierung, sobald zurg Änderungen erkennt. Beispiel: `http://localhost:8096` |
| `jellyfin_token` | string | `""` | Jellyfin-API-Token zur Authentifizierung. |
| `emby_server_url` | string | `""` | URL deines Emby-Servers. Aktiviert Benachrichtigungen zur Bibliotheksaktualisierung, sobald zurg Änderungen erkennt. Beispiel: `http://localhost:8096` |
| `emby_token` | string | `""` | Emby-API-Token zur Authentifizierung. |
| `dmm_api_key` | string | `""` | Dein DMM-API-Key. [gatekeeper](https://gatekeeper.debridmediamanager.com/) zeigt ihn dir einmal an, sobald du sponserst. DMM sortiert dann deine Dateien ein und füllt deine Wunschliste. |
| `dmm_metadata_secret` | string | `""` | Geheimer Schlüssel für die interne Metadaten-API von DMM. Wenn gesetzt, werden Torrents ohne IMDb-ID (oder nur mit der Fehlmarkierung von OpenSubtitles) beim Start anhand ihres Release-Namens über DMM identifiziert. DMM antwortet nur, wenn genau ein Titel exakt passt. Torrents, die DMM nicht benennen kann, behalten eine leere ID, damit der Plex-Matcher sie trotzdem füllen kann. |

```yaml
jellyfin_server_url: "http://localhost:8096"
jellyfin_token: ""
emby_server_url: "http://localhost:8096"
emby_token: ""
dmm_api_key: ""
```

## 3. Wiedergabe & Dateistruktur {#3-playback--file-structure}

Steuert, welche Dateien dein Medienserver sieht und wie Inhalte gestreamt werden.

### Streaming-Modus {#streaming-mode}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `disable_stream_proxy` | bool | `false` | Wenn true, wird ein **Mount**-Lesezugriff mit einer Weiterleitung auf die eigene Download-URL des Accounts beantwortet, statt über zurg weitergeleitet zu werden. Das reduziert die CPU- und Bandbreitenlast von zurg, aber der Client muss die Server des Accounts direkt erreichen können. Wird ignoriert bei einem Backend, dessen Links lokal bereitgestellt werden: Eine Usenet-Datei hat keine URL, die man herausgeben könnte, deshalb wird sie immer weitergeleitet. **Lies die Anbieter-Risiken unten, bevor du das aktivierst.** |
| `serve_strm_files` | bool | `false` | Wenn true, liefert zurg `.strm`-Dateien anstelle der echten Videodateien im WebDAV-Mount aus. Medienserver wie Plex/Jellyfin lesen die `.strm`-Datei, um die Streaming-URL zu bekommen. **Wichtig:** Wenn das aktiviert ist, werden die echten Videodateien versteckt und durch `.strm`-Einträge ersetzt. |
| `save_strm_files` | bool | `false` | Wenn true, schreibt zurg `.strm`-Dateien in ein `strm/`-Verzeichnis neben dem zurg-Binary. Nützlich für Setups, in denen du dauerhafte STRM-Dateien auf der Festplatte haben willst (z. B. für den manuellen Import in einen Medienserver). Verwendet `base_url` für die URLs in den Dateien. Nur Dateien, die ein Player öffnen kann, bekommen eine: erkanntes Video und Audio plus alles, was `addl_playable_extensions` nennt. Untertitel, Poster, NFOs und PAR2-Volumes bleiben also draußen, und alle, die eine ältere Version dort geschrieben hat, werden beim nächsten Durchlauf des Releases entfernt. Eine `.strm`, deren URL nicht mehr stimmt, weil sich `base_url` geändert hat oder eine ältere Version sie geschrieben hat, wird beim nächsten Start direkt überschrieben, oder sofort, wenn `base_url` im Dashboard geändert wird. Dateien, die schon stimmen, werden nicht angefasst, damit ein Medienserver nicht bei jedem Scan den ganzen Ordner neu einliest. |

```yaml
disable_stream_proxy: false
serve_strm_files: false
save_strm_files: false
```

**Behalte Mount-Lesezugriffe weitergeleitet (der Standard) für geteilte Debrid-Wiedergabe.** Real-Debrid verfolgt die öffentliche IP jedes Downloaders. Mehrere IPs für einen Account führen zu einer Warnung zur Kontoteilung, selbst wenn der Download klappt. Halte jede Nutzung dieses Accounts auf einer öffentlichen IP, inklusive Server-Checks und Konvertierungen, nicht nur Player-Downloads. TorBox-Download-URLs enthalten den vollständigen API-Schlüssel in `?token=`. Eine Weiterleitung gibt also jedem Client und jedem geteilten Benutzer-Account Zugriff, auch zum Löschen. Player-Logs und Browserverlauf können ihn speichern. Gib TorBox-Links nicht an nicht vertrauenswürdige Clients.

Diese Risiken gelten sowohl für Mount-Weiterleitungen mit `disable_stream_proxy: true` als auch für `/strm/`-Weiterleitungen. Wenn du `disable_stream_proxy: false` lässt, wird die `.strm`-Wiedergabe **nicht** proxied und ist auch nicht sicher für die Freigabe an Dritte.

#### Was `disable_stream_proxy` erreicht und was nicht {#what-disable_stream_proxy-does-and-does-not-reach}

Es betrifft nur den Mount. Der `/strm/`-Endpunkt wird bei keinem Backend erreicht:

| Zugriff kommt über | Real-Debrid / TorBox / AllDebrid | Usenet |
|---|---|---|
| Mount, Proxy an (Standard) | über zurg weitergeleitet | weitergeleitet |
| Mount, Proxy aus | `302` zur URL des Accounts | weitergeleitet — es gibt keine URL, zu der umgeleitet werden könnte |
| Eine `.strm`-Datei, egal welche Einstellung | `307` zur URL des Accounts | weitergeleitet |

Eine `.strm`-Datei wird von einem Player geöffnet, zu dem zurg keine Session hat. Der Endpunkt kann deshalb nur eine URL zurückgeben, die der Player selbst abrufen kann. Die Proxy-Option zu aktivieren leitet diesen Traffic nicht über zurg. Wichtig zu wissen ist die Folge: Zugriffe, die über `.strm`-Dateien kommen, werden nicht mitgezählt (keine Bandbreitenstatistik), es gibt keinen Failover auf einen anderen Account mitten im Stream und keine Erkennung kaputter Links. Bei einem Mount-Zugriff ist das alles vorhanden. Eine Bibliothek, die hauptsächlich über `.strm`-Dateien läuft, merkt deshalb kaum einen Effekt von `disable_stream_proxy`, egal wie die Einstellung steht.

`serve_strm_files` und `disable_stream_proxy` sind voneinander unabhängig, entgegen dem, was ältere Versionen dieser Seite sagten. Eine `.strm`-Datei wird als Text ausgeliefert, bevor überhaupt über das Streaming entschieden wird. Beide Optionen können also zusammen aktiv sein. Mit eingeschaltetem `serve_strm_files` kommt aber jede Wiedergabe am `/strm/`-Endpunkt an, also genau in der Zeile der Tabelle, in der `disable_stream_proxy` nichts ändert.

### Dateifilterung & Erkennung {#file-filtering--detection}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `addl_playable_extensions` | list | `[]` | Dateiendungen, die zurg zusätzlich zu den eingebauten Video-/Audioformaten als abspielbare Medien behandeln soll. Punkte, Anführungszeichen und Groß-/Kleinschreibung werden vom Dashboard vereinheitlicht. Füge Endungen wie `m3u` oder `cbz` hinzu, wenn du diese Dateien sichtbar und auswählbar haben willst. |
| `force_select_playable_files` | bool | `false` | Wenn true, wählt zurg automatisch alle abspielbaren Dateien in einem Torrent aus, auch wenn sie ursprünglich nicht ausgewählt waren. Funktioniert sowohl mit den eingebauten Video-Endungen als auch mit `addl_playable_extensions`. Nützlich, wenn Torrents nicht ausgewählte Videodateien enthalten, auf die du zugreifen willst. |
| `delete_torrent_if_extensions_found` | list | `[]` | Wenn eine Datei im Torrent eine dieser Endungen hat, wird der gesamte Torrent von RD gelöscht. Nützlich, um Torrents automatisch zu entfernen, die unerwünschte Inhalte enthalten, wie `.rar`-Archive (nicht die von RD entpackten) oder `.zipx`-Dateien. |
| `stream_compressed_archives` | bool | `true` | Stellt eine Datei, die in einem komprimierten Archiv verpackt ist, bereit, indem sie beim Lesen dekodiert wird. Der Decoder hält ein begrenztes Fenster im Speicher. Setze `false`, um komprimierte Archive abzulehnen, so wie es ältere Builds getan haben. |

Eingebaute abspielbare Formate sind `.avi`, `.flv`, `.m2ts`, `.m4v`, `.mkv`, `.mov`, `.mp4`, `.mpg`, `.mpeg`, `.ts`, `.webm`, `.wmv`, `.mp3`, `.flac`, `.m4a` und `.m4b`.

```yaml
addl_playable_extensions:
  - m3u
  - cbz
force_select_playable_files: false
delete_torrent_if_extensions_found:
  - zipx
  - rar
```

### Metadaten & Benennung {#metadata--naming}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `retain_folder_name_extension` | bool | `false` | **Veraltet, wird entfernt.** Wenn true, ist der Ordnername der `Name` des Accounts, unverändert mit Endung, statt `OriginalName` mit abgeschnittenem `.mp4` bzw. `.mkv` am Ende. Das gilt nur dort, wo `Name` `OriginalName` als Teilstring enthält. Überall sonst wird trotzdem abgeschnitten. `retain_rd_torrent_name` wird zuerst geprüft und überdeckt diese Option komplett. |
| `retain_rd_torrent_name` | bool | `false` | **Veraltet, wird entfernt.** Wenn true, ist der Ordnername der `Name` des Accounts (Real-Debrids `filename`). Wenn false, ist es `OriginalName` (`original_filename`), also der Name, den der Torrent selbst angibt. Das ist bei einem Pack mit nur einer ausgewählten Datei wichtig: Real-Debrid reduziert `filename` auf den Basisnamen dieser einen Datei, während `original_filename` beim Pack-Namen bleibt. Also **gibt `false` den Pack-Namen aus und `true` den Namen der einzelnen Datei**. |
| `ignore_renames` | bool | `false` | Wenn true, ignoriert zurg alle Rename-Metadaten in Torrents und verwendet die ursprünglichen Dateinamen. Aktiviere das, wenn umbenannte Dateien beim Abgleich durch deinen Medienserver Probleme machen. Nicht veraltet. |

```yaml
retain_folder_name_extension: false   # deprecated
retain_rd_torrent_name: false         # deprecated
ignore_renames: false
```

Beide veralteten Flags legen die Bibliothek anhand von `Name` ab, den der Account unter zurg nachträglich umschreibt. Die Standardwerte nutzen dagegen den Namen, den der Torrent selbst angibt, und der Account lässt diesen in Ruhe. Wenn du eine der Optionen setzt, schreibt zurg beim Start eine Warnung ins Log. Auf einer Instanz, die Sonarr oder Radarr vorgeschaltet ist (also mit einem `sabnzbd:`- oder `qbittorrent:`-Block), sind die Standardwerte die einzig richtigen. Ein Zugriffsschlüssel, der sich nach einem Import ändert, lässt das Release verloren gehen. Das Verhalten bleibt in dieser Version unverändert: Bei niemandem ändern sich Ordnernamen. `docs/naming.txt` enthält alle Namensregeln.

### Schreibvorgänge im Mount {#mount-writes}

: Hier die Übersetzung:

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `dav_allow_rename` | bool | `true` | Wenn false ist, wird ein WebDAV MOVE über den Mount mit 403 abgelehnt. Standardmäßig aktiviert: Umbenennen eines Torrents oder einer Datei ist genau dafür da, und dabei geht nichts kaputt. |

**Ein WebDAV DELETE über den Mount wird immer ausgeführt – dafür gibt es keinen Schlüssel.** Er entfernt eine Datei aus der Bibliothek und, sobald nichts mehr übrig ist, das Release von jedem Debrid-Konto, das es hat. Überleg dir gut, was das kostet, bevor du einen Schreibvorgang auf den Mount richtest: rclone schreibt eine überschriebene Datei als DELETE gefolgt von PUT, also löscht alles, was eine Datei an Ort und Stelle neu schreibt (ein `.nfo`-Writer, ein Trickplay-Durchlauf, ein \*arr-Umbenennen, ein versehentliches `touch`), Inhalte, statt sie zu ersetzen. Und der Mount nutzt die eigenen Zugangsdaten von rclone, daher kann die Authentifizierung die beiden Fälle nicht unterscheiden. Nur dass der PUT-Teil abgelehnt wird, verhindert, dass diese Abfolge still durchläuft. `mount_read_only: true` sorgt dafür, dass ein DELETE gar nicht erst bei zurg ankommt.

Eine abgelehnte Schreiboperation antwortet mit **403** und protokolliert den Konfigurationsschlüssel, der sie erlauben würde. So sagt ein Client, dessen Schreibvorgang nicht mehr funktioniert, in `logs/zurg.log`, woran es liegt.

Eine Nebenwirkung solltest du kennen: Wenn ein Programm über den FUSE-Mount schreibt, behält der VFS-Cache von rclone die geänderte Kopie und wiederholt den abgelehnten Upload mit einem Backoff. Der Mount zeigt dann die lokal geänderte Datei, bis der Cache-Eintrag verworfen wird. Die Datei auf dem Server bleibt die ganze Zeit unverändert. `mount_read_only: true` vermeidet das komplett, weil der Schreibvorgang schon auf Kernel-Ebene scheitert, bevor rclone irgendetwas zwischenspeichert.

```yaml
dav_allow_rename: true
```

Siehe auch `mount_read_only`, das den Schreibvorgang schon im Kernel ablehnt, bevor er zurg erreicht.

### Cache für Verzeichnislisten {#directory-listing-cache}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `disable_listing_cache` | bool | `false` | Wenn true, wird jede Verzeichnisliste bei jeder Anfrage von Grund auf neu gerendert. Lass es aus: Mit diesem Wert rendert ein `PROPFIND Depth:1` von `__all__` jedes Mal die gesamte Bibliothek neu, gemessen 59 ms für 6,120 Releases, 121 ms für 2,636 Usenet-Releases, 148 ms für `__magic__/__all__`. Und ein Medienserver-Scan fragt immer wieder dieselbe Liste ab. |

```yaml
disable_listing_cache: false
```

Der Cache speichert das letzte Rendering jedes obersten Verzeichnisses, und zwar eines pro Mount-Variante (`/dav`, `/infuse`, `/http`). Er gibt es zurück, bis sich die Bibliothek ändert. Was als Änderung gilt, ist kein Rätselraten: Es ist genau die Menge an Ereignissen, die rclone ohnehin dazu bringt, seine eigene zwischengespeicherte Kopie derselben Liste zu vergessen. Dazu gehören ein hinzugefügtes, entferntes, umbenanntes oder neu einsortiertes Release sowie eine Datei, die kaputtgeht oder wieder heilt. rclone hält diese Listen **zwölf Stunden** lang. Eine hier ausgelieferte Liste ist also nie älter als die, die der Mount ohnehin ausliefert. Zur Sicherheit gibt es zusätzlich eine harte Obergrenze von 60 Sekunden.

`__magic__/__all__` ist der Spiegel und die einzige Liste im Namespace, die sich zum Cachen lohnt, weil die Wurzel darüber nur den Spiegel und ein paar Zeilen enthält. Diese Liste verfolgt außerdem das gespeicherte Layout. Ein \*arr-Import invalidiert daher nur diese eine Liste und lässt das Rendering aller anderen Verzeichnisse unverändert. `__downloads__` und `Depth: 0`-Anfragen werden gar nicht gecacht.

Antworten enthalten einen `X-Zurg-Listing: hit`- oder `miss`-Header, damit du eine laufende Installation messen kannst:

```bash
curl -s -o /dev/null -D - -X PROPFIND -H 'Depth: 1' http://localhost:9999/dav/__all__/ | grep -i x-zurg-listing
```

### `__magic__`, ein Verzeichnis, das du organisieren kannst {#__magic__-a-directory-you-can-organise}

Jedes andere Verzeichnis ist ein gespeicherter Filter. Ein Release liegt in `movies`, weil es zum movies-Filter passt. Deshalb gibt es in der Bibliothek keine Stelle, an die man etwas *legen* könnte. `__magic__` ist die Ausnahme: `__magic__/__all__` ist eine exakte Kopie von `__all__`, und das Root-Verzeichnis daneben gehört dir. Alles kann aus dem Spiegel an eine beliebige andere Stelle im Namensraum verschoben werden. Ein Verschieben schreibt eine Zeile in `data/magic.journal`, die dann in `data/magic.json` zusammengeführt wird. Dabei werden keine Bytes bewegt und kein Torrent umbenannt. Die Zeilen werden über den Content-Hash des Releases geschlüsselt. Eine Reparatur, die das Release neu aufbaut, verliert deshalb nicht, wohin du Dinge gelegt hast. So können Radarr und Sonarr per Umbenennen statt per Kopieren importieren.

Die ausführliche Beschreibung, inklusive dessen, was eine Reparatur übersteht und was jede Ablehnung bedeutet, steht in [docs/magic.md](../guides/magic.md).

| Option | Typ | Standard | Beschreibung |
|--------|-----|----------|--------------|
| `magic.enabled` | bool | `false` | `__magic__` überhaupt ausliefern. Standardmäßig aus: Es ist ein beschreibbarer Baum, und ein \*arr, der auf das falsche Root-Verzeichnis zeigt, kann eine Bibliothek umorganisieren. Ohne verschobene Einträge liest sich das eigene `__all__` genau wie das der Bibliothek, und das Root-Verzeichnis enthält sonst nichts. |
| `magic.allow_delete` | bool | `false` | Wenn true, löscht ein DELETE auf eine **Datei** unter `__magic__` auch den Inhalt, so wie ein DELETE auf dem Mount selbst es immer tut. Standardmäßig blendet ein Löschen nur aus: Der Eintrag verschwindet aus `__magic__` und bleibt in `__all__` und in jedem Filterverzeichnis. Ein Release-Ordner und ein Verzeichnis löschen nie Inhalte, egal wie dies eingestellt ist, denn Sonarr löscht nach jedem Import den Job-Ordner. Das Löschen eines Videos oder eines Eintrags in einem Archiv löscht auch das gesamte Release, sobald nichts mehr unter `__magic__` einen Teil davon verwendet. |
| `magic.sidecar_max_mb` | int | `32` | Die größte einzelne Datei, die ein Client per `PUT` nach `__magic__` schreiben darf. Darüber wird der Schreibvorgang mit **413** abgelehnt. |
| `magic.sidecar_budget_mb` | int | `2048` | Die größte Größe, auf die der gesamte Sidecar-Baum anwachsen darf. Darüber wird ein Schreibvorgang mit **507 Insufficient Storage** abgelehnt. Das sagt mehr als 413: Wenn du etwas löschst, gelingt dieselbe Anfrage. Die Summe wird beim Start durch Durchlaufen des Baums ermittelt, damit ein Neustart das Kontingent nicht einem bereits vollen Baum zurückgibt, und erneut vor jeder Ablehnung. Der Baum ist dasselbe Verzeichnis `data/local`, in das zurg's eigener Mount schreibt. Deshalb darf eine dort hinter zurg's Rücken entfernte Datei nicht weiter angerechnet werden. Null oder ein negativer Wert nimmt den Standard; es gibt keine Möglichkeit, auf eine Obergrenze zu verzichten. |

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

`dav_allow_rename` gilt hier nicht, ebenso wenig der ungesicherte Löschpfad des Mounts. Diese decken die Routen ab, die umbenennen und zerstören, was das Debrid-Konto hält. Ein Schreibvorgang unter `__magic__` erreicht kein Konto. `mount_read_only: true` setzt trotzdem alles außer Kraft, auf Kernel-Ebene.

Zwei Dinge sollte man wissen. Die Filterverzeichnisse bleiben bewusst unangetastet. Ein Release, das du innerhalb von `__magic__` verschoben hast, ist deshalb weiterhin unter seinem eigenen Namen in `recent` und `movies` zu finden. Richte einen Medienserver auf `__magic__` **oder** auf die Filter, nicht auf beide. Und alles wirklich Neue, das in den Mount geschrieben wird (eine `.nfo`, ein Untertitel, ein Poster), landet in zurg's eigenem `data/local` und wird in die Auflistung zusammengeführt. Deshalb funktionieren Sidecars neben einem Release einfach.

#### Begleitdateien und wofür die beiden Obergrenzen da sind {#sidecar-files-and-what-the-two-caps-are-for}

Der eingebundene Mount ist eine Union, deren erster Upstream `data/local` ist. Wenn ein Programm also eine neue Datei auf dem Mount anlegt, schreibt rclone sie dorthin, und zurg wird nie gefragt. Diesen Baum begrenzt nichts, außer [`union_writable: server`](#rclone-settings) dreht die Reihenfolge der Union um. Dann kommt das Anlegen als `PUT` bei zurg an und wird außerhalb von `__magic__` abgelehnt, innerhalb davon durch die beiden Limits begrenzt.

Bei der Standardreihenfolge sind die beiden Limits für die andere Art Client gedacht: einen, der `/dav` direkt einbindet, ohne Union davor. Diese schicken zurg das `PUT`, und zurg schreibt den Body nach `data/local/__magic__/<path>`, genau das Verzeichnis, das auch die Union ausliefert. So zeigen beide Sichten ein Verzeichnis statt zwei. Ohne Obergrenze wäre das ein allgemeiner Dateispeicher, erreichbar über WebDAV. Genau das sollen `sidecar_max_mb` und `sidecar_budget_mb` verhindern.

Aus dem, was `__magic__` ist, folgen zwei Regeln. Beide sind Ablehnungen, die ein Client zu sehen bekommen kann:

- **Der Spiegel gehört der Bibliothek.** `__magic__/__all__` und die Release-Ordner direkt darin werden berechnet. Deshalb ist ein `MOVE`, `MKCOL` oder `DELETE` auf eines davon **403**: Ein Eintrag dort wäre eine zweite Adresse für ein Release, das bereits eine hat. Tiefer liegt der eigene Ordner eines Releases. Dort ist ein Schreibvorgang so normal wie überall sonst, denn dort legt ein \*arr die `.nfo` neben eine Datei ab, die es importiert hat.
- **Nichts, wofür die Bibliothek antwortet, darf überschrieben werden.** Ein Release-Ordner, ein Eintrag darin und ein Pfad, auf dem ein Move etwas abgelegt hat, werden alle aus der Bibliothek gerendert. Ein `PUT` oder ein `MOVE` einer echten Datei auf einen davon ist deshalb **403**. Dazu gehört auch ein Name innerhalb eines Release-Ordners, den das Release nicht hat: Die Auflistung des Ordners gehört dem Release, also würde eine Datei zwischen dessen Einträgen von niemandem aufgelistet.
- **Ein Platzieren zerstört nie eine echte Datei.** Wenn etwas, das die Bibliothek hält, auf einen Pfad verschoben werden soll, den ein Sidecar belegt, wird das abgelehnt, statt zu überschreiben, auch mit `Overwrite: T`. Dasselbe gilt für ein Verzeichnis mit echten Dateien, das in die andere Richtung verschoben wird: Es darf nicht auf einen Pfad umbenannt werden, für den die Bibliothek antwortet. Seine Dateien würden sonst in einem Ordner landen, der das Release auflistet und sonst nichts.

Ein `DELETE` auf ein Sidecar löscht es wirklich. Das ist der einzige Ort in `__magic__`, an dem ein Löschen kein Tombstone ist: Ein Tombstone blendet einen Eintrag aus, den die Bibliothek anderswo noch hat. Die Bytes eines Sidecars liegen aber nur in `data/local` und nirgends sonst.

#### Die Seite `__magic__` {#the-__magic__-page}

Das Dashboard hat eine eigene Seite für den Namespace unter `/magic/`. Sie ist aus den Schnelllinks des Dashboards erreichbar, sobald `__magic__` konfiguriert oder bereitgestellt wird. Hier ist die Tabelle sichtbar, und zwei ihrer Zustände sind nur über diese Seite erreichbar.

Die Seite zeigt, wie viele Zeilen gespeichert sind: Placements, Tombstones und Verzeichnisse, jeweils getrennt gezählt. Außerdem zeigt sie, wie viel Platz Journal und Snapshot auf der Festplatte belegen, wie viel von `sidecar_budget_mb` der Sidecar-Baum nutzt und die Größe des gesamten `data/local`. Diese letzte Zahl solltest du im Auge behalten. Ein Client, der kopiert statt zu verschieben, legt die Daten dort ab. Wenn `data/local` in den Gigabyte-Bereich wächst, importiert etwas in die falsche Richtung. Die Zeilen selbst sind nach Release gruppiert. Bei einer sehr großen Tabelle wird die Seite gekürzt, und sie sagt dir, um wie viel. Die Zahlen oben beziehen sich immer auf die ganze Tabelle.

Die Liste der gespeicherten Zeilen zeigt die ersten tausend Zeilen. Ein \*arr hinterlässt bei jedem Import einen Tombstone. Bei einer aufgeräumten Bibliothek liegen deshalb die meisten Zeilen hinter dieser Grenze. Ein Suchfeld auf den Seiten mit gespeicherten Zeilen und verwaisten Einträgen findet ein Release anhand seines Namens, eines Pfads im Mount oder seines Hashes. Es listet dann jede Zeile auf, die dazu gespeichert ist, mit ihren Buttons. `data/magic.json` ist dafür kein Ausweg: zurg schreibt die Datei beim Beenden aus dem Speicher heraus. Eine Zeile, die du während zurg läuft von Hand aus der Datei löschst, kommt deshalb wieder zurück.

Es gibt drei Buttons, die alle über dieselbe Operation laufen. Eine Zeile hört auf zu existieren:

- **Reset** bei einem Placement: Die Datei oder der Ordner wird dorthin zurückgesetzt, wohin die Bibliothek sie legt.
- **Unhide** bei einem Tombstone: Der Eintrag wird wieder in `__magic__` aufgelistet. Zum Ausblenden wurde nichts zerstört. Ein Release in `__all__`, das auch nach Löschen und erneutem Hinzufügen nie in `__magic__/__all__` auftaucht, hat einen Release-Tombstone. Seine Zeilen sind über seinen Hash geschlüsselt, und den ändert ein erneutes Hinzufügen nicht. Suche danach und hebe das Ausblenden dieser Zeile auf.
- **Delete** bei einer **verwaisten** Zeile, also einer, deren Release oder deren Datei darin die Bibliothek nicht mehr hat. Eine solche Zeile löst zu nichts auf. Deshalb lässt sie sich über den Mount nicht auflisten, verschieben oder löschen. Sie wird behalten statt verworfen, weil eine Reparatur, die das Release wiederherstellt, es auch wieder an den Ort bringt, den du festgelegt hast. Bis zu dieser Seite gab es keine Möglichkeit, sie aufzuräumen. **Clear all dangling rows** räumt alle auf einmal weg.

Sidecars werden ebenfalls aufgelistet. Die, **zu denen nichts mehr gehört**, stehen getrennt von den übrigen und werden gezählt. Das sind die Sidecar-Gegenstücke zu verwaisten Zeilen: eine `.nfo` oder ein Poster, das neben einem Release geschrieben wurde, das inzwischen die Bibliothek verlassen hat, oder in einem Ordner, dessen Placement vergessen wurde. Sie werden weiterhin ausgeliefert. Eine echte Datei ist das Letzte, worauf ein `__magic__`-Pfad auflöst, und nichts darüber beansprucht den Namen mehr. Verloren geht also nur der Grund, aus dem sie angelegt wurden. zurg entfernt so eine Datei nie selbst: Eine Datei, die neben einem gelöschten Release liegt, gehört immer noch dir, und eine Reparatur, die das Release zurückbringt, ordnet den Ordner wieder zu. Ein Verzeichnis, das du selbst für Sidecars angelegt hast, und zwar über den Mount statt über zurg, wird hier genauso angezeigt, weil dabei ebenfalls keine Zeile entsteht.

Eine Sidecar-Datei auf dieser Seite zu löschen, entfernt die Datei wirklich, genauso wie ein `DELETE` über den Mount. Jeder Button ändert, was der Mount für die betroffenen Pfade zwischengespeichert hat, denn der Mount hält eine Verzeichnisliste zwölf Stunden lang, wenn Polling ausgeschaltet ist.

Wenn der SABnzbd-Endpunkt aktiv ist, listet die Seite außerdem die Jobs auf, die er übergeben bekommen hat: die ID, unter der der Client den Job kennt, seine Kategorie, ob das Release schon in der Bibliothek angekommen ist, und den Ordner, aus dem nach der Ankunft importiert wird. Sonarr und Radarr entfernen ihre eigenen Jobs selbst. Ein Job im Status Failed oder Stuck, den keiner der beiden je entfernen wird, lässt sich hier löschen. Das ist der Fall, wenn zurg nicht mehr ihr Download-Client ist. Siehe [sabnzbd.md](../guides/sonarr-radarr.md).

Sowohl der Block `magic:` als auch der Block `sabnzbd:` lassen sich auf der [Konfigurationsseite](#sabnzbd-the-download-client-sonarr-and-radarr-see) vollständig bearbeiten. Beide zeigen **Restart Required**, und das meint es wörtlich: Die Routen, die `__magic__` und den SABnzbd-Endpunkt ausliefern, werden einmal beim Start registriert, und zwar aus diesen Werten. Wenn du eines davon einschaltest, wird das in `config.yml` gespeichert, ändert aber nichts am laufenden Betrieb, der gerade antwortet. Die `__magic__`-Seite sagt dir das auch, statt einen leeren Namespace anzuzeigen.

### `sabnzbd`, der Download-Client, den Sonarr und Radarr sehen {#sabnzbd-the-download-client-sonarr-and-radarr-see}

zurg kann Sonarr und Radarr so antworten, als wäre es ein SABnzbd. Sie übergeben ihm eine NZB, er schreibt die Datei für das Usenet-Backend in `nzbs/`, und sobald das Release in der Bibliothek liegt, meldet der Job **Completed** mit einem Job-Ordner unter `__magic__/__all__`, aus dem importiert werden kann. Zum Importieren muss nichts heruntergeladen werden: der \*arr benennt die Datei innerhalb des Mounts um, was eine Zeile in der `__magic__`-Tabelle ist.

Damit das nützlich ist, braucht es beide Teile: einen `nzb`-Provider oder einen `torbox_nzb`-Provider, der die NZB annimmt, und `magic.enabled`, damit es einen Ort zum Importieren gibt. Ohne Aktivierung ist es aus. Die vollständige Einrichtung, einschließlich dessen, was im \*arr einzutragen ist, steht in [docs/sabnzbd.md](../guides/sonarr-radarr.md).

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `sabnzbd.enabled` | bool | `false` | Registriert den Endpunkt unter `/api` und `/sabnzbd/api`. Solange das aus ist, existieren beide Routen nicht. |
| `sabnzbd.api_key` | string | generiert | Der einzige Schutz für den Endpunkt. Sonarr und Radarr senden keine Basic Auth, daher liegen diese Routen außerhalb davon, und der Schlüssel übernimmt diese Rolle. Ist der Block aktiviert und der Wert leer, erzeugt zurg einen Schlüssel, speichert ihn in `data/sabnzbd-apikey`, damit er einen Neustart übersteht, und schreibt ihn beim Start einmal ins Log. |
| `sabnzbd.categories` | list | `[tv, movies]` | Die Kategorien, die den Clients gemeldet werden. Alle verweisen auf dasselbe Verzeichnis, daher gibt es sie nur, damit ein Client nicht vor einer Kategorie warnt, die er nicht findet. Trage ein, was du im \*arr konfiguriert hast. `*` wird immer ebenfalls gemeldet. |
| `sabnzbd.history_limit` | int | `60` | Wie viele History-Einträge Sonarr und Radarr lesen. zurg hält fertige Jobs über diesem Limit in der Warteschlange, bis ein Platz frei wird. Das passiert, wenn der Client einen davon löscht oder wenn einer zehn Minuten ungelöscht liegt, während Jobs warten. Stelle es auf den Wert von `DownloadClientHistoryLimit` im Client ein, falls du den erhöht hast. `0` behält den Standardwert 60 bei. |
| `sabnzbd.complete_dir` | string | `<mount_path>/__magic__/__all__` | Das den Clients gemeldete Verzeichnis für abgeschlossene Downloads. Es muss der Pfad sein, den **der \*arr** sieht. Das ist nicht unbedingt der Pfad von zurg, wenn der \*arr in einem Container läuft, der die Bibliothek an einer anderen Stelle einhängt. Außerdem muss es auf demselben Volume liegen wie die Root-Ordner, sonst wird jeder Import zu einer Kopie. Siehe [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). |

```yaml
sabnzbd:
  enabled: true
  api_key: ""
  categories: [tv, movies]
  complete_dir: ""
```

Der API-Schlüssel ist die gesamte Authentifizierung. Behandle den Endpunkt deshalb wie den Rest des zurg-Ports: nur in einem vertrauenswürdigen Netzwerk oder hinter etwas, das ihn absichert. Basic Auth lässt sich dafür nicht verwenden. Die Clients schicken sie nie, und ein 401 wird dem Nutzer als „unable to connect“ gemeldet statt als Authentifizierungsfehler.

### `qbittorrent`, der Torrent-Download-Client, den Sonarr und Radarr sehen {#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see}

zurg kann auf Anfragen von Sonarr und Radarr antworten, als wäre es ein qBittorrent. Sie übergeben ihm einen Magnet-Link oder eine `.torrent`, und zurg fügt den Info-Hash einem Debrid-Konto hinzu. Sobald das Release in der Bibliothek liegt, meldet der Torrent **finished** mit einem Ordner unter `__magic__/__all__`, aus dem importiert werden kann. Zum Importieren wird nichts heruntergeladen. Der \*arr benennt die Datei innerhalb des Mounts um, und das ist eine Zeile in der Tabelle `__magic__`.

Zwei Teile machen das nützlich. Ein Konto, das Torrents hinzufügen kann, liest den Magnet-Link, und `magic.enabled` gibt dem \*arr einen Ort, von dem er importieren kann. Die Option ist aus, bis du sie einschaltest. Die komplette Einrichtung, inklusive dessen, was im \*arr eingetragen werden muss, steht in [docs/qbittorrent.md](../guides/sonarr-radarr-torrents.md).

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `qbittorrent.enabled` | bool | `false` | Registriert den Endpunkt unter `/api/v2` und `/qbittorrent/api/v2`. Solange er aus ist, existiert keine der beiden Routen. |
| `qbittorrent.api_key` | string | generiert | Das einzige Schutzelement des Endpunkts. Die Clients senden ihn als Bearer-Token, wenn ihr Feld **API Key** gesetzt ist, und akzeptieren ihn als Passwort bei `auth/login`, wenn das Feld leer ist. Bleibt der Wert leer, während der Block aktiviert ist, erzeugt zurg einen Schlüssel, speichert ihn in `data/qbittorrent-apikey`, damit er einen Neustart übersteht, und schreibt ihn beim Start einmal ins Log. |
| `qbittorrent.categories` | list | `[tv-sonarr, radarr]` | Die Kategorien, die den Clients gemeldet werden, also die beiden, die die \*arrs standardmäßig mitbringen. Alle zeigen auf dasselbe Verzeichnis. Die Liste dient nur dazu, dass ein Client nicht warnt, weil er eine Kategorie nicht finden kann. |
| `qbittorrent.save_path` | string | `<mount_path>/__magic__/__all__` | Der Speicherpfad, der den Clients gemeldet wird, und der übergeordnete Ordner aller Ordner, aus denen sie importieren. Es muss der Pfad sein, den **der \*arr** sieht. Dieser ist nicht zwingend der von zurg, wenn der \*arr in einem Container läuft, der die Bibliothek an einer anderen Stelle einhängt. Der Pfad muss auf demselben Volume liegen wie die Root-Ordner, sonst wird bei jedem Import kopiert statt verschoben. Siehe [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). Wenn du beide Endpunkte betreibst, setze `sabnzbd.complete_dir` auf denselben Wert. |
| `qbittorrent.download_timeout_mins` | int | `15` | Wie lange ein Grab ohne Bewegung laufen darf, also ohne Statuswechsel und ohne steigenden Fortschritt, bevor das Konto aufgegeben wird und das nächste Konto, das Torrents annimmt, probiert wird. `0` bedeutet Cached-only: Ein Grab wird nur an ein Konto angenommen, das den Inhalt bereits hat. Andernfalls wird es schon beim Hinzufügen abgelehnt, und genau diese Ablehnung reagieren Sonarr und Radarr darauf. Eine negative Zahl gibt nie auf. Siehe [Timeouts und Cached-only-Modus](../guides/sonarr-radarr-torrents.md#timeouts-and-cached-only-mode). |

```yaml
qbittorrent:
  enabled: true
  api_key: ""
  categories: [tv-sonarr, radarr]
  save_path: ""
  download_timeout_mins: 15
```

Fünfzehn Minuten sind ein gemessener Wert und keine frei gewählte Zahl. AllDebrid legt einen gesunden Job in seine eigene Warteschlange, bei der alle Zähler auf null stehen, bevor er auch nur ein Byte überträgt. Zwei von zwei Testläufen blieben dort 580 bzw. 622 Sekunden hängen. Die Mitschnitte findest du in [docs/torrent-lifecycle.md](../internals/torrent-lifecycle.md).

Welches Konto einen Grab bekommt, entscheiden [`add_torrents`](#accounts) und die Reihenfolge der `providers:`-Liste. Ein Grab, das in der Zeitüberschreitung hängen blieb oder das ein Konto aufgegeben hat, wird von diesem Konto gelöscht, bevor das nächste probiert wird. Nur eine Instanz, die zurg selbst für diesen Grab hinzugefügt hat und die nie fertig wurde, kommt überhaupt als Kandidat infrage. Kein anderer Aufruf dieses Endpunkts löscht etwas aus einem Debrid-Konto.

Der API-Key ist die gesamte Authentifizierung. Behandle den Endpunkt so wie den restlichen Port von zurg. Setze ihn in ein vertrauenswürdiges Netzwerk oder hinter etwas, das vertrauenswürdig ist. Basic Auth kann dafür nicht verwendet werden. Die Clients senden den Key nie, und eine 401-Antwort werten sie als harten Authentifizierungsfehler, den sie nie wiederholen.

### Das `stremio`-Addon {#the-stremio-addon}

zurg kann ein Stremio-Addon sein, das deine eigenen Newznab-Indexer durchsucht und über das Usenet-Backend abspielt. Dafür brauchst du einen NZB-Account, `nzb` oder [`torbox_nzb`](../providers/torbox-nzb.md), und mindestens einen Indexer. Bei `torbox_nzb` startet ein Release, das TorBox schon hat, innerhalb der Wartezeit des Addons, wenn kein anderer NZB-Post wartet. Ein Release, das noch nicht zwischengespeichert ist, muss dagegen erst bei TorBox fertig werden, und das dauert länger, als ein Player wartet. Das Addon ist aus, bis du es einschaltest. Einrichtung und was ein Abspielvorgang macht, stehen in [stremio.md](../guides/stremio.md).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stremio.enabled` | bool | `false` | Registriert die Addon-Routen unter `/stremio/`. Solange es aus ist, antworten sie mit 404. |
| `stremio.token` | string | generated | Das Pfadsegment, das jede Addon-Route absichert. Es ist die gesamte Autorisierung. Bleibt es leer, erzeugt zurg einen und speichert ihn in `data/stremio-token`. |
| `stremio.indexers` | list | `[]` | Newznab-Endpunkte zum Durchsuchen. Jeder Eintrag hat `name`, `url`, `api_key` und optional `api_path`. |
| `stremio.max_results` | int | `10` | Wie viele Releases jede Auflösung nach dem Ranking behält. Die Obergrenze gilt pro Auflösung. Jede Stufe behält eine Verteilung vom größten bis zum kleinsten Release. `0` nimmt den Standardwert. |
| `stremio.search_limit` | int | `100` | Wie viele Releases jeder Indexer pro Suche angefragt bekommt. Alle anderen Limits wählen aus dem, was hier angefragt wurde, deshalb ist es die Obergrenze für die gesamte Antwort. `0` nimmt den Standardwert. |
| `stremio.max_size_gb` | int | `0` | Wirft Releases weg, die größer sind als dieser Wert, bevor gerankt wird, für einen Player, der kein Remux verträgt. `0`, der Standardwert, wirft keine weg. Releases ohne angegebene Größe bleiben erhalten. |
| `stremio.cache_hours` | int | `24` | Wie lange eine vollständige Antwort mit fünf oder mehr Ergebnissen aus `data/stremio-cache` ausgeliefert wird, bevor die Indexer erneut gefragt werden. Dünnere Antworten werden kürzer aufbewahrt. Eine leere Antwort wird nie gespeichert. `0` nimmt den Standardwert. |

### Medienanalyse {#media-analysis}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `auto_analyze_new_torrents` | bool | `false` | Wenn true, führt zurg bei jedem neu hinzugefügten Torrent automatisch ffprobe aus, um Mediendaten zu extrahieren (Auflösung, Codecs, Dauer, Audio- und Untertitelspuren). Diese Metadaten werden von tag-basierten Verzeichnisfiltern wie `zurg_4k`, `zurg_aud_eng` und den Dauerstufen genutzt. Deaktiviere die Option, wenn du keine tag-basierten Filter verwendest oder bei neuen Hinzufügungen weniger CPU-Last willst. |
| `ffprobe_binary` | string | `"ffprobe"` | Pfad zur ffprobe-Programmdatei. Nur nötig, wenn ffprobe nicht im PATH deines Systems liegt. Wird für die Medienanalyse verwendet. |

```yaml
auto_analyze_new_torrents: true
ffprobe_binary: "ffprobe"
```

## 4. Gesundheit & Reparaturen (Automatisierung) {#4-health--repairs-automation}

Der Abschnitt „einstellen und vergessen“. Hier legst du fest, wie zurg deine Bibliothek gesund hält, indem kaputte Torrents automatisch erkannt und repariert werden.

| Option | Typ | Standard | Beschreibung |
|--------|-----|----------|--------------|
| `enable_repair` | bool | `true` | Aktiviert die automatische Torrent-Reparatur. Nicht gesetzt bedeutet aktiviert. Wenn ein Torrent nicht mehr verfügbar ist (z. B. weil er aus dem RD-Cache entfernt wurde), versucht zurg, einen Ersatz zu finden und hinzuzufügen. Bei AllDebrid startet zurg außerdem einen Magnet neu, der aus einem Grund fehlgeschlagen ist, den ein zweiter Versuch beheben kann, etwa keine Peers oder ein Tracker-Fehler, statt ihn als fehlgeschlagen liegen zu lassen. **Wichtig:** Nur eine zurg-Instanz sollte die Reparatur aktiviert haben, sonst gibt es Konflikte. Wenn dieser Wert und `delete_error_torrents` beide aus sind, lässt zurg fehlgeschlagene Torrents genau so auf deinem Konto, wie sie sind, und protokolliert sie nur. |
| `repair_every_mins` | int | `60` | Wie oft (in Minuten) zurg nach kaputten Torrents sucht, die repariert werden müssen. Niedrigere Werte erkennen Probleme schneller, erhöhen aber die API-Nutzung. |
| `repair_timeout_mins` | int | `30` | Maximale Zeit (in Minuten), die zurg auf das Ende einer Reparatur wartet. Dauert eine Reparatur länger, wird der Torrent als kaputt markiert und bis zum nächsten Reparaturzyklus übersprungen. |
| `stalled_download_mins` | int | `10` | Mindestzahl an Minuten, nach denen ein ladender Torrent als hängen gilt. Der tatsächliche Grenzwert ist `max(GB_downloaded, stalled_download_mins)`, große Downloads bekommen also automatisch mehr Zeit. Erhöhe diesen Wert bei langsamen oder wenig geseedeten Torrents (z. B. von öffentlichen Trackern), die mehr Zeit zum Fertigwerden brauchen. |
| `restrict_repair_to_cached` | bool | `false` | Wenn true, nutzt zurg für Reparaturen nur Torrents, die bereits auf Real-Debrid gecacht sind. Das macht Reparaturen schneller, weil nichts heruntergeladen werden muss, kann aber fehlschlagen, wenn es keine gecachte Alternative gibt. Wenn false, kann zurg auch nicht gecachte Torrents hinzufügen, die erst heruntergeladen werden müssen. |
| `only_full_torrent_repair` | bool | `false` | Wenn true, fügt die Reparatur den gesamten Torrent mit seiner ursprünglichen Dateiauswahl wieder ein oder gibt auf. Schlägt dieser erste Schritt fehl, wird der Torrent sofort als kaputt markiert, und die Archiv- und Einzeldatei-Strategien, die sonst folgen würden, werden übersprungen. |
| `check_for_changes_every_secs` | int | `15` | Wie oft (in Sekunden) zurg Real-Debrid abfragt, um Änderungen an der Bibliothek zu erkennen (neue Torrents, entfernte Torrents, Statusänderungen). Niedrigere Werte bedeuten schnellere Updates in deinem Media-Server, aber mehr API-Aufrufe. |
| `library_resync_every_mins` | int | `10` | Wie oft die Änderungsprüfung aus einer vollständigen Liste neu aufgebaut wird statt aus einer günstigen Probe. Das ist ein Sicherheitsnetz, das Abweichungen auffängt, die eine Probe übersehen kann. Es bestimmt nicht, wie oft zurg abfragt. Real-Debrid geht einen eigenen Weg und ignoriert diesen Wert. |
| `library_detail` | string | `resident` | `resident` hält Dateidetails im Speicher. `lazy` gibt inaktive Details frei. `auto` gibt inaktive Details nur bei anhaltendem Speicherdruck frei. Alle Provider teilen sich diese instanzweite Einstellung. Neustart erforderlich. Siehe [Library detail](#library-detail). |
| `library_detail_idle_secs` | int | `300` | Mindestzeit ohne Lesezugriff auf die Details, bevor `lazy` oder `auto` eine Tabelle freigeben dürfen. Die Prüfung läuft alle 30 Sekunden. Wird bei `resident` ignoriert. Null oder ungültige Werte verwenden 300. Neustart erforderlich. |
| `downloads_every_mins` | int | `720` | Wie oft (in Minuten) zurg deine RD-Downloads (Unrestricted-Links, File-Locker-Links) neu abruft und einbindet. Dabei handelt es sich um Nicht-Torrent-Downloads von RD. |
| `delete_error_torrents` | bool | `false` | Wenn true, löscht zurg automatisch Torrents von RD, die sich im Fehlerzustand befinden (z. B. tote Torrents, die sich nicht herunterladen lassen). Das hält deine RD-Bibliothek sauber, bedeutet aber, dass der Torrent dauerhaft entfernt wird. Bei AllDebrid wird ein fehlgeschlagener Magnet, den ein zweiter Versuch beheben kann, neu gestartet statt gelöscht, auch wenn die Reparatur aus ist. Gelöscht wird er nur, wenn der Neustart nicht hilft. |
| `on_library_update` | string | `""` | Ein Shell-Befehl, der jedes Mal ausgeführt wird, wenn zurg Änderungen an der Bibliothek erkennt. Jeder geänderte Verzeichnispfad wird als Argument übergeben. Wird häufig genutzt, um für bestimmte Ordner Plex- oder Jellyfin-Bibliotheksscans auszulösen, damit Updates schneller kommen. |

```yaml
enable_repair: true
repair_every_mins: 60
repair_timeout_mins: 30
stalled_download_mins: 10
restrict_repair_to_cached: false
only_full_torrent_repair: false
check_for_changes_every_secs: 15
library_detail: resident
library_detail_idle_secs: 300
downloads_every_mins: 720
delete_error_torrents: false
on_library_update: |
  for arg in "$@"
  do
      echo "detected update on: $arg"
  done
```

### Reparatur über mehrere Konten hinweg {#repairing-across-accounts}

Jede andere Repair-Strategie fügt ein Release wieder in das Konto ein, aus dem es stammt. Das passt, solange dieses Konto den Inhalt noch liefern kann. Für einen Fall ist das aber falsch.

Die Dienste führen eigene Caches. Ein Release, das Real-Debrid entfernt hat, oder eines, das es allein wegen des Dateinamens ablehnt, kann auf AllDebrid genau jetzt gecacht liegen, unter demselben Info-Hash. Mit dem Release ist alles in Ordnung. Nur das Konto ist das Problem.

Wenn also ein Release von jedem Konto aufgegeben wurde, das es hat, bietet zurg es den konfigurierten Konten an, die es nicht haben. Die Reihenfolge richtet sich nach der Reihenfolge im `providers`-Block. Das erste Konto, das es bereits gecacht hat, übernimmt es. zurg listet dieses Konto, und das Release bekommt eine zweite Kopie, wie jedes Release mit mehreren Konten: mit eigenen Datei-IDs, eigenen Links und Read-Failover zwischen beiden. Die Bewertung des Eintrags wird automatisch zurückgesetzt, sobald eine reparierbare Kopie existiert.

Es gibt dafür keine Einstellung. Ein zweites Konto einzurichten ist die Entscheidung. zurg listet es bereits, liefert daraus und leitet Reads dorthin um. Dieses Konto nach einem Release zu fragen, das das erste Konto nicht liefern kann, ist derselbe Mechanismus. Es folgt `enable_repair` wie jede andere Reparatur.

Auch der Repair-Button eines Releases macht das, und zwar in dieser Reihenfolge: Zuerst wird das Konto erneut versucht, das das Release hat, genau wie bisher. Das Release wird nur dann herumgereicht, wenn dieser Versuch fehlschlägt. Das ist der einzige Weg, der funktioniert, wenn der Repair-Durchlauf komplett ausgeschaltet ist.

Eine Add-Schleife wird durch die Form des Angebots verhindert, nicht durch einen Schalter:

- **Ein Konto bekommt nur Inhalte, die es schon hat.** Das Angebot ist ein Add, das zurückgezogen und wieder gelöscht wird, sofern das Konto es nicht innerhalb von fünfzehn Sekunden fertigstellt. Ein Konto, das das Release erst aus dem Swarm holen müsste, bleibt genau so, wie es vorgefunden wurde, und verbraucht kein Transfer-Kontingent. Das ist eine Reparatur, kein erneuter Download. `restrict_repair_to_cached` steuert das nicht und wird hier nie gelesen. Dieser Schlüssel betrifft die Reparatur der eigenen Kopie eines Kontos. Dieser Weg ist unabhängig von seinem Wert immer nur für Gecachtes.
- **Nur ein Release, das niemand mehr liefern kann.** Ein funktionierendes Release wird nie kopiert, und auch keines, das die Reparatur noch nicht aufgegeben hat.
- **Ein Konto, das Nein sagt, wird immer seltener gefragt.** Die Wartezeit nach einer Absage beginnt bei einem Tag und verdoppelt sich mit jeder weiteren Absage, bis auf etwa zwei Wochen. Ein Release, das diese Woche nur nicht im Cache ist, wird innerhalb weniger Tage wieder gefunden. Eines, das endgültig weg ist, wird zu einer Anfrage alle zwei Wochen. Ohne diesen Rückgang würde Always-on für jedes tote Release auf jedem Konto täglich ein Add bedeuten, und zwar für immer.
- **Höchstens zehn Releases pro Durchlauf.** Der erste Durchlauf nach dem Hinzufügen eines zweiten Kontos arbeitet einen Rückstau deshalb über Stunden ab und nicht in einem einzigen Schwall.

Ein Konto, das bereits eine Kopie des Releases hat, bekommt nie eine zweite Instanz davon, egal wie kaputt die vorhandene Kopie ist. Für dieses Konto sind die eigenen Reparatur-Strategien von repair zuständig. Bei Real-Debrid lädt ein doppeltes Add außerdem nie etwas herunter. Releases, deren Schlüssel kein BitTorrent-Info-Hash ist, wie ihn das Usenet-Backend für seine eigenen verwendet, werden nie irgendwo angeboten.

Das ist die einzige Stelle, an der zurg einem Konto ohne Aufforderung etwas hinzufügt, dessen Inhalte ablaufen. Repair fügt ein Release auf einem Timer nicht erneut in ein solches Konto ein, denn das erneute Abrufen von Inhalten, die der Dienst bewusst entfernt hat, gilt bei diesen Diensten als Missbrauch. Ein Angebot aus dem Cache ist aber nicht dasselbe: Es wird nichts abgerufen, kein Kontingent verbraucht, und der beanspruchte Inhalt liegt bereits im Cache des Dienstes, weil ihn jemand anderes dorthin gelegt hat.

### Bibliotheksdetails {#library-detail}

**`library_detail: resident` bleibt der Standard.** Wähle einen Modus und die Leerlaufzeit
auf der Konfigurationsseite des Dashboards oder in `config.yml`. Beide Einstellungen
greifen erst nach einem Neustart von zurg; wenn du sie nur speicherst, wird eine
laufende Bibliothek nicht teilweise umgestellt. Die Richtlinie gilt für jeden Provider
in der Instanz.

| Modus | Verhalten | Abwägung |
|---|---|---|
| `resident` | Hält die Dateidetails jeder Release im Speicher. | Vorhersehbarer Zugriff ohne Neuladen der Details; der höchste Speicherverbrauch. |
| `lazy` | Gibt Details nach `library_detail_idle_secs` ohne Nutzung frei. | Senkt den Leerlauf-Speicherverbrauch, auch wenn genug RAM vorhanden ist; der Zugriff auf kalte Details kostet ein Neuladen. |
| `auto` | Behält Details, solange genug Speicher frei ist, und gibt bei anhaltendem Druck die ältesten inaktiven Tabellen frei. | Reagiert auf die Laufzeitbedingungen; bringt Drucküberwachung mit sich und eine weniger vorhersehbare Ladezeit beim Neuladen. |

Namen, Größen, Umbenennungen und Sichtbarkeit bleiben in jedem Modus für die
Auflistungen verfügbar. Beim Öffnen oder Reparieren einer Datei werden freigegebene
Details bei Bedarf neu aufgebaut. `auto` lädt die Bibliothek nicht proaktiv neu, wenn
der Druck endet: Details kommen zurück, sobald sie genutzt werden, und bleiben im
Speicher, bis Druck und Leerlauffenster die Freigabe wieder erlauben.

#### Automatische Erkennung von Druck {#automatic-pressure-detection}

`auto` prüft alle 30 Sekunden. Wenn zwei Messwerte, die mindestens 30 Sekunden auseinanderliegen, bei **90 %** oder mehr eines gemessenen Budgets liegen, startet die Bereinigung. Sie arbeitet in Stapeln von höchstens **128 inaktiven Tabellen** pro Durchlauf. Die Bereinigung läuft weiter, bis die Auslastung auf **80 %** oder darunter sinkt. Danach pausiert sie mindestens eine Minute, bevor sie eine neue Runde in Betracht zieht. Kurze Spitzen lösen keine Bereinigung aus. Das konfigurierte Zeitfenster für Inaktivität gilt immer.

Die engste verfügbare Messung bestimmt die Entscheidung:

- **Host-Speicher:** Gesamtspeicher minus verfügbarer Speicher, einschließlich der Schätzung des Betriebssystems für freigebbare Caches. Ein voller Dateisystem-Cache allein bedeutet noch keinen RAM-Mangel.
- **Linux-Container und Dienstlimits:** cgroup v2 `memory.max` und `memory.high` oder cgroup v1 `memory.limit_in_bytes`, jeweils mit der eigenen Auslastung jedes sichtbaren Vorfahren. Kalter Datei-Cache wird nicht mitgezählt. Container-Limits werden zur Laufzeit neu eingelesen. Private cgroup-Namespaces können Limits oberhalb der sichtbaren Wurzel verbergen.
- **Ein explizites Laufzeitbudget:** Ein positives `memory_limit_mb` in MiB wird mit dem von Go verwalteten Speicher verglichen. Wenn `GOMEMLIMIT` gesetzt ist, hat es Vorrang. `GOMEMLIMIT=off` schaltet genau dieses Signal ab. Der Druck durch Host und Container gilt weiterhin. Die automatische Go-Obergrenze, die sich aus den Usenet-Caches ableitet, wird ignoriert. Sie steigt mit dem laufenden Heap und misst nicht den verfügbaren RAM.

Für die Aktivierung von `auto` brauchst du kein zusätzliches Budget:

```yaml
library_detail: auto
library_detail_idle_secs: 300
# Optional explicit Go runtime budget, also used by the collector:
# memory_limit_mb: 1024
```

Ohne brauchbare Messung pausiert die automatische Bereinigung. Das ist eine schrittweise Speicheroptimierung, **keine harte Speichergrenze**. Aktive Dateien, ungespeicherte Änderungen, Wiederherstellungs-Snapshots und andere Caches können den Speicher dominieren. Plötzliche Speicherspitzen können schneller sein als der Sweeper. `memory_limit_mb` bleibt ein weiches Limit für den Garbage Collector. Wenn du es unter die Menge der aktiven Daten setzt, kann es zu übermäßig häufiger Garbage Collection kommen.

#### Datenintegrität und Kosten {#data-integrity-and-cost}

Auslagerung behält neben dem bestehenden Dump `data/*.zurgtorrent` auch einen komprimierten Wiederherstellungs-Snapshot. Ein Neuladen von der Festplatte muss mit diesem Snapshot übereinstimmen. Fehlt der Dump, ist er beschädigt oder wurde er ersetzt, stellt zurg den Snapshot wieder her und hält das Release im Speicher (resident). Danach versucht zurg erneut, die wiederhergestellten Daten zu speichern. Auch `auto` versucht erneut, untätige geänderte Tabellen (dirty) zu speichern, sobald der Druck nachgelassen hat, und zwar in einem eigenen, begrenzten Speicherdurchlauf. Dateischreibvorgänge und Zustandsänderungen holen die Zuständigkeit sofort zurück, auch Schreibvorgänge über einen Zeiger, den ein Stream über eine Auslagerung hinweg hält. Fehlgeschlagene Speichervorgänge lassen Änderungen im Speicher und als geändert (dirty) markiert. Überlappende Schreibvorgänge werden nicht von einem älteren Speichervorgang bestätigt. Damit Änderungen einen Prozessende überstehen, ist trotzdem ein erfolgreicher Speichervorgang nötig.

Gemessen auf einem Mac mit Apple Silicon und Go 1.26.4, mit 500 Releases pro Typ über die Konvertierungs- und Speicherpfade, einschließlich des Wiederherstellungs-Snapshots:

| Typ | Resident-Bytes/Eintrag | Lazy-Bytes/Eintrag | Reduktion | Durchschnittliche Neuaufbauzeit |
|---|---:|---:|---:|---:|
| Real-Debrid-Film, 3 Dateien | 3,662 | 2,845 | 22% | 88 µs |
| Real-Debrid-Staffelpaket, 24 Dateien | 15,670 | 7,366 | 53% | 371 µs |
| TorBox, 2 Dateien | 3,019 | 2,680 | 11% | 56 µs |
| AllDebrid, 1 Datei | 2,580 | 2,516 | 2% | 55 µs |
| RAR-Satz, 7 Teile | 5,343 | 3,303 | 38% | 109 µs |

Das sind die gehaltenen Heap-Werte pro Release, nicht der RSS des gesamten Prozesses. Beim Neuaufbau werden zuletzt geschriebene lokale Dateien gelesen. Kalter oder entfernter Speicher kann länger dauern. Wähle `lazy` für eine gleichmäßige Freigabe im Leerlauf oder `auto`, um nur unter Last Speicher freizugeben. Behalte `resident`, wenn vorhersehbare Zugriffszeiten wichtiger sind als RAM. Kleine Releases sparen wenig, und der Wiederherstellungs-Snapshot verbraucht bewusst Speicher, um Daten zu schützen. Diese Messwerte beschreiben ausgelagerte Einträge sowohl in `lazy` als auch in `auto`. Der automatische Modus behält zu jedem Zeitpunkt unter Umständen mehr Einträge im Speicher.

## 5. Netzwerk & Konnektivität (Technisch) {#5-network--connectivity-technical}

Infrastruktur-Einstellungen, mit denen du steuerst, wie zurg sich bindet, sich authentifiziert und sich mit dem Netzwerk verbindet.

### Server-Bindung {#server-binding}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `host` | string | `"[::]"` | Das Netzwerkinterface, an das gebunden wird. `[::]` lauscht auf allen Interfaces (IPv4 und IPv6). Nutze `0.0.0.0` für nur IPv4 oder eine bestimmte IP, wenn der Zugriff auf ein einzelnes Interface beschränkt werden soll. |
| `port` | string | `"9999"` | Der Port, auf dem zurg lauscht. Wenn die Umgebungsvariable `PORT` gesetzt ist, überschreibt sie diesen Wert. Das ist praktisch für Container-Deployments. |

```yaml
host: "[::]"
port: 9999
```

### Warme Verbindungen {#warm-connections}

Eine Verbindung zu einem Debrid-Dienst zu öffnen ist teuer, sie zu nutzen dagegen fast kostenlos. Gemessen von einem Live-Host am 2026-08-29 kostet eine frische Verbindung zu einem Real-Debrid-Download-Host einen TCP-Roundtrip und danach 68–85 ms TLS-Handshake, bevor auch nur ein Byte der Datei angefragt wurde. Und das HTTP-Transportmodul von zurg öffnet nichts, bis ein Lesevorgang es braucht. Eine ungenutzte Verbindung wird nach 90 Sekunden wieder geschlossen. Bei allem außer einer stark genutzten Bibliothek zahlt der Lesevorgang nach einer ruhigen Phase das auf dem eigenen Weg des Zuschauers.

Eine warme Untergrenze nimmt diese Wartezeit von diesem Weg: Jedes Konto hält eine festgelegte Anzahl Verbindungen vorab bereit, bereits aufgebaut und per Handshake verbunden. So hat das Transportmodul eine parat, wenn ein Lesevorgang eintrifft.

| Option | Typ | Standard | Beschreibung |
|--------|-----|----------|--------------|
| `warm_connections` | int | *(nicht gesetzt)* | Die Untergrenze für jedes Konto, das keine eigene angibt. Ohne Angabe behält jedes Backend seinen Standard: 1 pro Host für ein Debrid-Konto, 2 pro Konto für ein News-Konto. `-1` schaltet das Vorwärmen überall ab. Die eigene `warm_connections` eines Kontos hat immer Vorrang, auch vor einem globalen `-1`. |

```yaml
warm_connections: 2        # every account keeps 2, unless it says otherwise

providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    warm_connections: 4    # this one keeps 4 to each host it uses
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    warm_connections: -1   # and this one keeps none
```

**Wie viel das bringt, hängt vom Host ab, und bei den Debrid-Diensten ist es weniger, als es klingt.** Eine Verbindung, über die nichts gesendet wurde, ist das Erste, was diese Dienste schließen, und sie tun es schnell. Gemessen von einem Live-Host am 2026-08-29, indem eine stille Verbindung offen gehalten und gewartet wurde, bis sie getrennt wird:

| Host | Stille Verbindung | Nach dem Ausliefern einer Anfrage |
|---|---|---|
| ein Real-Debrid-Download-Host | nach 30s geschlossen | sofort geschlossen |
| `api.alldebrid.com` | nach 15s geschlossen | nach 4 Min. noch offen |
| `api.torbox.app` | nach 15s geschlossen | nach 4 Min. noch offen |
| `api.real-debrid.com` | nach 4s geschlossen | nach 5s geschlossen |

Eine Untergrenze lohnt sich also nur für einen Download-Host und kaum für etwas anderes. Die Real-Debrid-API lässt sich gar nicht vorwärmen: Keine Untergrenze kommt gegen einen Verbindungsabbruch nach vier Sekunden an, ohne künstlichen Traffic zu erzeugen, um die Verbindung am Leben zu halten, und das tut zurg nicht. Statt es anzunehmen, **misst die Untergrenze**: Sie beendet ihre eigenen Verbindungen nach 15 Sekunden und prüft dabei, ob jede davon noch lebte. Ein Host, der sie immer schließt, bevor ein Lesevorgang sie nutzen könnte, wird aufgegeben, und seine Lesevorgänge werden wie bisher neu aufgebaut. Dafür muss nichts konfiguriert werden, und eine Untergrenze, die in einer ruhigen Bibliothek ungenutzt bleibt, wird dabei nicht mit so einem Host verwechselt.

Zwei weitere Punkte sollte man kennen, bevor man sie erhöht:

- **Die Untergrenze eines Debrid-Kontos gilt pro Host, die eines News-Kontos pro Konto.** Ein Debrid-Konto wird über viele Hosts angesprochen, einen API-Hostnamen und einen Download-Host pro Link. Welche das sind, lässt sich erst sagen, wenn ein Link erzeugt wurde. Deshalb werden die Hosts warm gehalten, die das Konto tatsächlich benutzt hat. Höchstens 16 werden gleichzeitig gehalten, und einer, der 10 Minuten ungenutzt bleibt, wird entfernt. Ein News-Konto ist ein einziger Host, der in der Konfiguration genannt wird, und hält seine Sitzung so lange, wie es der Tarif erlaubt. Deshalb zahlt sich genau diese Untergrenze zuverlässig aus. Siehe [Usenet](../guides/usenet.md).
- **Warme Verbindungen sind echte Verbindungen und zählen auf das Limit pro Host, das der Anbieter überwacht:** 32 bei Real-Debrid und AllDebrid, 20 bei TorBox. Deshalb ist die Untergrenze für Debrid auf 4 begrenzt. Bei dieser Größe bleibt das Limit praktisch intakt, während eine große Untergrenze es für Sockets verbrauchen würde, die nichts transportieren.

Die Untergrenze ist deaktiviert, wenn `proxy` gesetzt ist. Ein HTTP- oder SOCKS-Proxy bewirkt, dass zurg den Proxy anwählt statt des Hosts, und auf der anderen Seite gibt es nichts, das sich lohnt offen zu halten.

### Authentifizierung & Proxy {#authentication--proxy}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `username` | string | `""` | HTTP-Basic-Auth-Benutzername. Wenn zusammen mit `password` gesetzt, benötigen alle Anfragen an zurg (Dashboard, WebDAV, API) eine Authentifizierung. Leer lassen, um die Authentifizierung zu deaktivieren. |
| `password` | string | `""` | HTTP-Basic-Auth-Passwort. Muss zusammen mit `username` gesetzt werden. |
| `proxy` | string | `""` | Leitet den gesamten ausgehenden Netzwerkverkehr von zurg über einen Proxy. Unterstützt die Protokolle `http://`, `https://` und `socks5://`. Nützlich, wenn dein Internetanbieter Real-Debrid-Verkehr blockiert oder drosselt. Beispiel: `socks5://user:pass@host:port`. Wenn dieser Schlüssel leer ist, wird die Umgebungsvariable `PROXY` verwendet. |

```yaml
username: ""
password: ""
proxy: "http://[username:password@]host:port"
```

### Rclone-Einstellungen {#rclone-settings}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `rclone_enabled` | bool | `false` | Wenn true gesetzt ist, verwaltet zurg den rclone-Mount automatisch. Damit musst du rclone nicht separat starten: zurg startet, überwacht und startet den rclone-Prozess bei Bedarf neu. Der Mount nutzt `mount_path` als Mount-Punkt. |
| `rclone_binary` | string | `"rclone"` | Pfad zur rclone-Programmdatei. Nur nötig, wenn rclone nicht im PATH deines Systems liegt. |
| `rclone_extra_args` | list | `[]` | Zusätzliche Kommandozeilen-Flags, die an den rclone-Mount-Befehl übergeben werden. Damit überschreibst du zurgs auf Benchmarks optimierte VFS-Standardwerte (siehe Tabelle unten). Jeder Eintrag ist ein einzelner Flag-String. Die RC-Einstellungen und die Backend-Flags `--union-*`/`--webdav-*` werden abgelehnt: zurg baut diese selbst, und ein Flag würde über das überschreiben, was zurg baut (`union_writable` würde dann nicht mehr den Mount beschreiben). |
| `mount_read_only` | bool | `false` | Wenn true, wird der Mount mit rclones `--read-only` gestartet. Dann lehnt der Kernel einen Schreibzugriff ab, bevor er überhaupt zu zurg gelangt. Nichts anderes sperrt ein DELETE auf dem Mount, deshalb ist dies der einzige Weg, eines abzulehnen. Clients, die direkt mit dem WebDAV-Endpunkt sprechen, werden davon allerdings nicht erfasst. Außerdem verhindert es, dass ein versehentlicher Schreibvorgang im lokalen Union-Upstream des Mounts landet. Du kannst es pro Flag überschreiben mit `rclone_extra_args: ["--read-only=false"]`. |
| `rclone_cache_reclaim` | bool | `true` | Ob zurg die VFS-Cache-Bäume löscht, die von einer früheren Mount-Konfiguration übrig geblieben sind. rclone benennt seinen Cache nach dem Remote, und dieser Name wird aus den Union-Upstreams gehasht, die den absoluten Pfad von `data/local` enthalten. Wenn du also das zurg-Verzeichnis verschiebst oder `union_writable` umstellst, wird der Cache umbenannt, und der alte Baum bleibt verwaist zurück. Dort zählt ihn kein Limit, und kein Aufräumer schaut vorbei. Beim Mount-Start fragt zurg den laufenden rclone, welcher Baum aktiv ist, entfernt die übrigen und protokolliert, was er freigegeben hat. Er tut nichts, solange der aktive Baum nicht dort liegt, wo rclone ihn angibt. Das Aufräumen wird komplett übersprungen, wenn `rclone_extra_args` `--cache-dir` setzt. Setze den Wert auf `false`, um alle verwaisten Bäume zu behalten. Siehe [Festplattenspeicher, den der Mount nutzt](#disk-the-mount-uses). |
| `union_writable` | string | `"local"` | In welchen Union-Upstream des eingebetteten Mounts eine neu erstellte Datei geschrieben wird. `local`, der Standard, legt sie direkt im lokalen Upstream (`data/local`) ab, ohne dass zurg davon etwas mitbekommt. `server` setzt den WebDAV-Upstream an erste Stelle, sodass das Erstellen bei zurg ankommt: Außerhalb von `__magic__` wird es abgelehnt, innerhalb wird es als größenbegrenzte Sidecar-Datei geschrieben. Ein abgelehnter Schreibvorgang landet nie auf der Festplatte. rclones VFS-Cache nimmt ihn zwar an und versucht den Upload mit Backoff erneut. Dadurch ist er durch das Cache-Limit begrenzt und in `logs/rclone.log` sichtbar, während die lokale Reihenfolge unbegrenzte Bytes in `data/local` abgelegt hätte. Ein Haken bei `server`: Das Umbenennen einer Sidecar-Datei über den Mount kann einen Fehler melden, weil die Datei in beiden Upstreams sichtbar ist und rclone die Verschiebung auf beide anwendet. Verschiebungen fertiger Releases innerhalb von `__magic__`, also der \*arr-Import-Pfad, sind davon nicht betroffen. Der Wechsel auf `server` ändert nur, wohin *neue* Dateien geschrieben werden, und sonst nichts. Was die lokale Reihenfolge bereits in `data/local` geschrieben hat, bleibt, bis du es löschst. Die Zeile, die zurg beim Start protokolliert, nennt den aktiven Modus (`new files go to zurg over WebDAV (union_writable: server)`). Darauf solltest du achten, nicht auf das Vorhandensein des Pfads `data/local`, denn der ist unter beiden Reihenfolgen Teil der Union. |

```yaml
rclone_enabled: false
rclone_binary: "rclone"
rclone_extra_args: []
mount_read_only: false
rclone_cache_reclaim: true
union_writable: "local"
```

#### Benchmark-optimierte Standardwerte {#benchmark-optimized-defaults}

zurg verwendet per Benchmark getestete rclone-VFS-Einstellungen, die für Streaming-Performance optimiert sind:

| Einstellung | Standard | Warum |
|---------|---------|-----|
| `--buffer-size` | 256M | Großer Puffer für flüssiges Streaming |
| `--vfs-read-chunk-size` | 32M | Wie lange ein frischer Lesevorgang im Hochlauf steckt. Der erste Chunk wird mit dieser Größe geholt und verdoppelt sich danach. Bei 4M verbrachte ein Lesevorgang von einem kalten Offset den größten Teil seiner Zeit unter der Leitungsrate. Das ist eine Anfragegröße, keine erzwungene Übertragung: rclone hört trotzdem auf zu laden, sobald der Leser aufhört. |
| `--vfs-read-chunk-size-limit` | 512M | Wo die Verdopplung oben endet. Chunking ist standardmäßig aktiv, daher ist das eine Obergrenze, die der Hochlauf erreicht, und kein Wert, den ein Override erst einschaltet. |
| `--vfs-read-ahead` | 128M | Ausgleich zwischen Puffer- und Bandbreiteneffizienz |
| `--max-read-ahead` | 1M | Ein kleiner FUSE-Kernel-Puffer reduziert kleine Lesevorgänge. Wird unter Windows nicht übergeben. |
| `--vfs-read-wait` | 5ms | Kritisch: Höhere Werte verursachen starke Verlangsamungen |
| `--vfs-cache-mode` | full | Volles Caching für die beste Performance. Nicht immer der richtige Kompromiss für einen Player, der den Mount über eine Freigabe liest. Siehe [Wann der Cache mehr kostet, als er bringt](#when-the-cache-costs-more-than-it-buys). |
| `--vfs-cache-max-size` | 256G | Harte Obergrenze für den VFS-Cache auf der Festplatte. Kein Konfigurationsschlüssel, überschreibe ihn mit `rclone_extra_args`. |
| `--vfs-cache-min-free-space` | 10G | Stoppt das Caching, bevor die Cache-Festplatte voll ist |
| `--vfs-cache-max-age` | 72h | Wie lange eine unberührte gecachte Datei behalten wird. „Unberührt" ist das entscheidende Wort, und ein Medienserver lässt fast nichts unberührt. Siehe [Vom Mount genutzter Speicherplatz](#disk-the-mount-uses). |
| `--vfs-cache-poll-interval` | 1m | Schnelle Cache-Aktualisierungen |
| `--vfs-fast-fingerprint` | an | Identifiziert Dateien, ohne sie zu hashen |
| `--dir-cache-time` | 12h | Verzeichnislisten bleiben stundenlang gültig. zurg verwirft betroffene Einträge über die RC-API, wenn sich die Bibliothek ändert, damit Medienserver-Scans warm bleiben. |
| `--attr-timeout` | 60s | Bibliotheksdateien sind unveränderlich, und Zustandsänderungen verwerfen die betroffenen Einträge explizit. Begrenzt, damit eine veraltete Größe nicht über einen Scan-Durchlauf hinaus lebt. |
| `--poll-interval` | 0 | Die Überwachung von Änderungen ist Aufgabe von zurg, nicht von rclone |
| `--timeout` | 5m | IO-Leerlauf-Timeout |
| `--no-modtime` / `--no-checksum` | an | Beides ist für eine Debrid-Bibliothek nicht sinnvoll, und sie anzufordern kostet Anfragen |
| `--async-read` | rclone-Standard (an), nicht übergeben | zurg setzt dieses Flag nicht auf der Kommandozeile, und rclone setzt es standardmäßig auf true. Der Mount liest also asynchron, und jede Zahl auf dieser Seite wurde so gemessen. Ein Tuning-Feld hat einmal behauptet, es zu deaktivieren. Es hat aber nur das nackte Flag angehängt, das den Standard setzt, den es ohnehin schon hatte. Zum tatsächlichen Abschalten: `rclone_extra_args: ["--async-read=false"]`. |
| `--low-level-retries` | 3 | rclones VFS-Downloader startet einen fehlgeschlagenen Lesevorgang pro Open bereits zehnmal neu, und jeder Neustart wird vom Backend-Pacer so oft wiederholt. Bei rclones Standard von 10 wären das 100 Anfragen für ein einziges Open einer Datei, die zurg absichtlich mit 503 beantwortet. |
| `--retries` | 1 | Gesamtbudget des Befehls. Bei einem Mount, der nie beendet wird, vervielfacht es nur einen Startfehler. |
| `--vfs-handle-caching` | 0, ab rclone 1.74+ an | rclone 1.74 hat begonnen, die Downloader einer Datei noch fünf Sekunden nach dem letzten Schließen am Leben zu halten. Dadurch kostet ein Zugriff auf eine Datei fünf Sekunden dessen, was die Verbindung tragen kann, und nicht nur das, was tatsächlich gelesen wurde. Gemessen an einem 50-MB/s-Server zog ein einziger 1-MiB-Lesevorgang 245–250 MiB statt 3–6 MiB, und ein Durchlauf über zwanzig Dateien ging von 80 MiB auf 4,2 GiB. Die Nachfrist existiert für `serve nfs`, das zurg nie startet. Ältere rclone-Versionen kennen dieses Flag nicht und verweigern den Start bei einem unbekannten Flag. Daher fragt zurg zuerst die Version des Binarys ab und übergibt unterhalb von 1.74 nichts. |
| `--log-level` | NOTICE | rclones eigene Ausführlichkeit, wird immer übergeben |
| `--cache-dir` | `data/rclone-cache` | Relativ zum Arbeitsverzeichnis aufgelöst |
| `--log-file` | `logs/rclone.log` | Relativ zum Arbeitsverzeichnis aufgelöst |

`--vfs-cache-max-size`, `--vfs-cache-min-free-space`, `--low-level-retries`, `--retries`, `--vfs-handle-caching`, `--log-level`, `--cache-dir` und `--log-file` sind Konstanten in `internal/rclone/manager.go`. Jede andere Zeile stammt aus `tuneVFSOptions` in `internal/rclone/tuning.go`, `--vfs-cache-max-age` und `--vfs-cache-poll-interval` eingeschlossen, trotz der Namen.

### Festplatte, die der Mount nutzt {#disk-the-mount-uses}

`--vfs-cache-mode full` bedeutet, dass eine Datei, die über den Mount gelesen wird, **komplett** nach `data/rclone-cache` heruntergeladen wird und dort auch nach dem Ende der Wiedergabe liegen bleibt. Es ist kein kleiner Zwischenspeicher für die Wiedergabe, der sich leert, sobald das Video stoppt. Ohne Eingriff wächst der Cache bis `--vfs-cache-max-size` an, was standardmäßig **256G** ist, und bleibt dann so groß.

Zwei Grenzen sollen das begrenzen, in der Praxis wirkt aber nur eine:

- `--vfs-cache-max-size` (256G) ist die eigentliche Grenze. Setze sie auf höchstens die Hälfte des freien Speicherplatzes auf der Festplatte, auf der `data/` liegt.
- `--vfs-cache-max-age` (72h) wirft eine Datei raus, die drei Tage lang von niemandem angefasst wurde. rclone misst das anhand seiner eigenen Aufzeichnung in `data/rclone-cache/vfsMeta/` und nicht am atime des Dateisystems, und **alles, was die Bibliothek liest, aktualisiert diesen Wert**. Ein Plex-Server mit aktivierten geplanten Aufgaben liest während seines nächtlichen Wartungsfensters jede gecachte Datei. Deshalb hatte am 09.09.2026 eine Instanz mit 362 Dateien im Cache bei jeder einzelnen den ATime vom selben Morgen. Seit Monaten war nichts herausgefallen, und es würde auch nie etwas herausfallen. Verlass dich also nicht auf das Alter, sondern plane mit der Größenbegrenzung.

Setze die Grenze mit `rclone_extra_args` herunter:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

`--vfs-cache-min-free-space` (standardmäßig 10G) stoppt das Caching, wenn die Festplatte so voll wird. Halte den Wert deutlich über null, wenn du die Festplatte mit anderen Dingen teilst.

Um den Cache von Hand zu leeren, stoppe zuerst zurg und lösche danach beide Verzeichnisse:

```bash
rm -rf data/rclone-cache/vfs/* data/rclone-cache/vfsMeta/*
```

Miss die Größe mit `du -sh data/rclone-cache`. Teilweise heruntergeladene Einträge sind Sparse-Dateien. Eine Angabe, die die scheinbare Dateigröße zählt, zeigt deshalb deutlich mehr an, als die Festplatte tatsächlich belegt.

#### Wann der Cache mehr kostet, als er bringt {#when-the-cache-costs-more-than-it-buys}

`full` ist der richtige Standard für einen Medienserver auf demselben Host: Er liest eine Datei
einmal, und alles danach ist lokal. Für einen Hardware-Player, der das Mount
über eine Dateifreigabe liest, ist es nicht automatisch die richtige Wahl.

Bei `full` muss ein Lesezugriff auf der Festplatte landen, bevor er beim Leser ankommt,
und geholt wird die ganze Datei statt nur der Teil, den du gerade schaust. Setzt du eine
Freigabe davor, schreibt rclone noch auf die Festplatte, während diese schon den Player
bedient. Ein Zidoo-Player, der eine Windows-Freigabe las, ruckelte bei jedem Titel, bis der
Cache ausgeschaltet wurde, und lief danach sauber (gemeldet am 2026-08-30). Der oben
beschriebene Mechanismus ist die plausible Erklärung für diesen Bericht und nicht etwas,
das hier gemessen wurde. Probier ihn daher zuerst aus, wenn ein
direkt lesender Client auf einem Mount ruckelt, den ein Medienserver auf demselben Host
ohne Probleme abspielt:

```yaml
rclone_extra_args:
  - "--vfs-cache-mode"
  - "off"
```

Was das kostet, ist real. Ohne lokale Kopie liest ein Seek erneut vom Anbieter, ein zweites
Abspielen lädt die Datei erneut herunter, und nach einem Neustart bleibt nichts erhalten.
Außerdem ändert es, was das Mount als Schreibvorgang akzeptiert. Lass den Standard also
in Ruhe auf einem Host, auf dem ein \*arr über das Mount importiert — siehe
[qbittorrent.md](../guides/sonarr-radarr-torrents.md).

#### Verwaiste Caches nach einem Umzug {#caches-stranded-by-a-move}

rclone benennt seinen Cache nach dem Remote, das es cacht, und dieser Name enthält einen Hash der Remote-Konfiguration. zurgs Remote ist ein Union, dessen Upstreams den absoluten Pfad von `data/local` enthalten. Deshalb ändert sich der Name, wenn sich die Konfiguration ändert:

| Union-Upstreams | Cache-Verzeichnis |
|---|---|
| `/home/you/zurg/data/local :webdav:` | `vfs/zurg{QaSkn}` |
| `:webdav: /home/you/zurg/data/local` (`union_writable: server`) | `vfs/zurg{HdSp7}` |
| `/other/root/data/local :webdav:` (zurg verschoben) | `vfs/zurg{Psid2}` |

rclone berücksichtigt immer nur das Verzeichnis, das es gerade benutzt. Ein Verzeichnis unter einem alten Namen wird bei keinem Limit mitgezählt, von keinem Aufräumer besucht und von niemandem gelöscht. Verschiebst du also das zurg-Verzeichnis oder kommt ein externes Laufwerk unter einem neuen Mount-Punkt zurück, bleibt ein ganzer Cache liegen. Mehrere solche Verschiebungen führen dazu, dass eine Installation mit 256G-Limit am Ende mehrere Terabyte belegt.

zurg räumt diese Verzeichnisse beim Mount-Start auf: Es fragt das laufende rclone, welches Verzeichnis gerade aktiv ist, löscht den Rest und protokolliert, wie viel Platz frei wurde. Es macht nichts, solange das aktive Verzeichnis nicht dort auf der Festplatte liegt, wo rclone es angibt. Und es überspringt das Aufräumen komplett, wenn `rclone_extra_args` `--cache-dir` setzt, weil ein Verzeichnis, das du selbst gewählt hast, eventuell von einem anderen zurg mitbenutzt wird. Mit `rclone_cache_reclaim: false` schaltest du das ab und behältst alle verwaisten Verzeichnisse.

Vier weitere Optionen werden je nach Plattform ergänzt, alle davon unter Linux: `--allow-other` und `--allow-non-empty` immer, `--uid` und `--gid` nur, wenn die IDs des laufenden Benutzers gelesen werden können. `--max-read-ahead` wird überall außer unter Windows übergeben, und `--read-only` immer dann, wenn [`mount_read_only`](#rclone-settings) gesetzt ist.

Die Werte für Puffer und Lese-Wartezeit wurden per Benchmark auf einer 600-Mbps-Leitung ermittelt. Dabei kamen ~533 Mbps Durchsatz bei kaltem Cache und ~235 ms TTFB heraus. Die Lese-Chunk-Größe haben wir später auf einem Host mit ~70 MB/s nachgemessen: Gepaart und verschachtelt stieg der Median-Durchsatz auf Real-Debrid von 49.1 -> 56.5 MB/s, als wir sie von 4M auf 32M umstellten. Auf TorBox ging es genauso.

**Standardwerte überschreiben** mit `rclone_extra_args`:
```yaml
rclone_extra_args:
  - "--buffer-size=128M"        # Use less memory
  - "--vfs-read-chunk-size=2M"  # Smaller chunks
```

RC-Flags (`--rc`, `--rc-addr` und alles andere, das mit `rc-` beginnt) werden abgelehnt. zurg betreibt die rclone-Fernsteuerung selbst, um den VFS-Cache zu invalidieren, wenn sich die Bibliothek ändert.

### User-Agent & Netzwerk {#user-agent--network}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `user_agent` | Zeichenkette | Chrome UA | Gemeinsamer HTTP-User-Agent für Provider, Indexer, ffprobe und ausgehende Integrationen. Leer stellt den generischen Browser-Standard wieder her; explizit angegebene eigene Werte werden so gesendet, wie sie eingegeben wurden. Erfordert einen Neustart. Siehe [Identität ausgehender Anfragen](outbound-identity.md). |
| `omit_user_agent` | Boolean | `false` | Unterdrückt den HTTP-User-Agent (ffprobe verwendet dann einen leeren Wert). Überschreibt `user_agent`. Anfragen an GitHub senden trotzdem einen, da GitHub Anfragen ohne ihn ablehnt. Erfordert einen Neustart. |
| `outbound_client_name` | Zeichenkette | `"Media Client"` | Produkt-/Client-Name für Media-Server-Integrationen, sofern unterstützt. Leer stellt den Standard wieder her. Erfordert einen Neustart. |
| `outbound_client_id` | Zeichenkette | `"media-client"` | Plex-Client-Kennung, einschließlich Anmeldung für Media-Server-Integrationen, sofern unterstützt. Leer stellt den Standard wieder her. Erfordert einen Neustart. |
| `outbound_client_version` | Zeichenkette | `"1.0"` | Client-Version für Media-Server-Integrationen, sofern unterstützt. Leer stellt den Standard wieder her. Erfordert einen Neustart. |
| `outbound_device_name` | Zeichenkette | `"Media Client"` | Gerätename für Media-Server-Integrationen, sofern unterstützt. Leer stellt den Standard wieder her. Erfordert einen Neustart. |
| `outbound_device_id` | Zeichenkette | `"media-client"` | Jellyfin/Emby-Geräte-Kennung für Media-Server-Integrationen, sofern unterstützt. Leer stellt den Standard wieder her. Erfordert einen Neustart. |
| `outbound_platform` | Zeichenkette | `"Desktop"` | Plex-Plattform für Media-Server-Integrationen, sofern unterstützt. Leer stellt den Standard wieder her. Erfordert einen Neustart. |
| `force_ipv6` | bool | `false` | Erzwingt, dass alle Netzwerktests von zurg und die Host-Auswahl IPv6 verwenden. Aktiviere dies, wenn dein Netzwerk eine bessere IPv6-Verbindung zu den RD-Servern hat (z. B. drosseln manche ISPs IPv4, aber nicht IPv6). |
| `unrestrict_ip` | Zeichenkette | `""` | Die IP-Adresse, die beim Entsperren von Download-Links an RD übergeben wird. Nützlich in Setups mit mehreren Netzwerken, wenn Downloads für eine bestimmte IP (z. B. eine VPN-Exit-IP) statt für die IP erstellt werden sollen, auf der zurg läuft. |
| `dns_servers` | Liste | `[]` (System-DNS) | Eigene DNS-Server zur Auflösung von RD-Hostnamen. Nützlich, wenn dein System-DNS langsam, unzuverlässig oder von deinem ISP blockiert ist. Leer lassen, um den System-Resolver zu verwenden. Muss den Port enthalten (z. B. `1.1.1.1:53`). |
| `network_test_every_mins` | Ganzzahl | `1440` | Wie oft (in Minuten) zurg den Netzwerk-Latenztest erneut ausführt, um die schnellsten RD-Download-Server zu finden. Kann nicht deaktiviert werden – Werte `<= 0` werden als `1440` behandelt. Ergebnisse werden in `data/network_test_results.json` und `data/network_test_timestamp` zwischengespeichert. Beim Neustart wird der Netzwerktest übersprungen, wenn der Cache aktuell genug ist. |

```yaml
user_agent: "Mozilla/5.0 ..."
force_ipv6: false
unrestrict_ip: ""
network_test_every_mins: 1440
dns_servers:
  - "1.1.1.1:53"   # Cloudflare
  - "8.8.8.8:53"   # Google
```

### Öffentliches NZB-Teilen {#public-nzb-sharing}

Eine NZB-Freigabe ist eine URL, die ein Empfänger abruft. Sie bringt also nur etwas, wenn er diesen Host erreichen kann, und das kann ein zurg hinter einem NAT zu Hause nicht garantieren. Diese zwei Schlüssel leiten die URL stattdessen über einen [zrok](https://zrok.io)-Dienst: zurg baut die Verbindung zum Dienst ausgehend auf und liefert die Freigabe darüber aus. **Es öffnet sich also kein lokaler Port**, und auf diesem Host antwortet nichts Neues. Der Tunnel transportiert nur die zwei token-geschützten Freigabe-Routen, nie das Dashboard und nie die Bibliothek.

Sind beide Schlüssel leer und gibt es keine aktivierte Umgebung unter `data/zrok`, bleibt die Freigabe in dem Netz, in dem dieser Host ohnehin hängt, und es wird nirgendwohin verbunden. Das ist der Standard. Beachte aber die zweite Hälfte: Sobald eine Umgebung *aktiviert* wurde, bedeutet ein leerer `zrok_account_token` nicht mehr „nur lokal“. Die Aktivierung schaltet die Freigabe ein, und das bleibt gespeichert. Um die öffentliche Freigabe wieder abzuschalten, entfernst du `data/zrok`.

Erstellen, Ausliefern und Widerrufen von Freigaben funktionieren in beiden Fällen gleich. Das Freigabe-Token im Pfad ist die Autorisierung, sowohl für die lokale URL als auch für die öffentliche.

Die öffentliche URL übersteht einen Neustart: Die Freigabe auf Dienstseite wird gesucht und wieder angebunden, statt neu erstellt zu werden. Eine erneute Aktivierung übersteht sie dagegen nicht. Eine neue Umgebung bekommt eine neue Freigabe, und URLs, die unter der alten ausgegeben wurden, werden nicht mehr aufgelöst. Das passiert, wenn du `data/zrok` entfernst, und auch, wenn die dort gespeicherte Identität fehlt oder nicht lesbar ist. Eine erneute Aktivierung ist dann der einzige Weg zurück.

Entfernst du `data/zrok` von Hand, bleibt die Umgebung samt Freigabe im zrok-Konto registriert. Die Identität, mit der sie sich hätten freigeben lassen, hast du ja gerade gelöscht. Wenn der Müll stört, räum im zrok-Console auf. Das Löschen ist auch kein Weg, die Freigabe im laufenden Betrieb abzuschalten: Ein laufender zurg hält die Verbindung, über die er gerade ausliefert, und die alte URL funktioniert weiter, bis der Prozess neu startet. zurg gibt eine Umgebung selbst frei, wenn er sie ersetzt. Er weigert sich aber, eine Umgebung zu ersetzen, die er beim Dienst nicht freigeben konnte. Das gilt auch für eine, deren Dateien er auf der Platte findet, aber nicht lesen kann. Eine Aktivierung darüber würde bei jedem Neustart eine lebende Umgebung zurücklassen.

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `zrok_account_token` | string | `""` | Das zrok-Aktivierungstoken, mit dem die öffentliche Freigabe eingeschaltet wird. Kostenlos bei [myzrok.io](https://myzrok.io) für den gehosteten Dienst; bei einem eigenen Controller beim jeweiligen Betreiber. Wird **nur für die erste Aktivierung** gebraucht. Die Aktivierung löst es einmal ein und speichert es zusammen mit der Umgebungsidentität unter `data/zrok`. Jeder spätere Aufruf authentifiziert sich mit dieser gespeicherten Kopie. Der Schlüssel kann danach also aus `config.yml` entfernt werden, und die öffentliche Freigabe kommt trotzdem beim nächsten Neustart hoch. Beachte, was das für das Geheimnis heißt: Den Schlüssel aus der Config zu nehmen, entfernt das Token nicht vom Host. Es gibt zwei Gründe, ihn trotzdem drin zu lassen. Erstens ist eine Aktivierung, die *fehlgeschlagen* ist, etwa wegen eines abgelehnten Tokens oder eines nicht erreichbaren Dienstes, nicht abgeschlossen, und der neue Versuch braucht den Schlüssel. Zweitens braucht auch jede spätere *erneute* Aktivierung ihn. Eine Instanz, bei der er entfernt wurde und die danach die Identität unter `data/zrok` verliert, kann sich nicht selbst helfen. Ein erneuertes Token wird von hier übernommen und auf die gespeicherte Umgebung angewendet, Identität und öffentliche URL bleiben dabei erhalten. |
| `zrok_api_endpoint` | string | `""` | Der zrok-Dienst, mit dem gesprochen wird, für selbst gehostete Installationen. Leer lässt den Standard des SDK, `https://api-v2.zrok.io` (der gehostete Dienst). Wird **nur zum Zeitpunkt der Aktivierung** gelesen. Sobald `data/zrok` eine aktivierte Umgebung enthält, gewinnt der dort gespeicherte Endpunkt. Wer eine schon aktivierte zurg auf einen anderen Dienst zeigen lassen will, muss also `data/zrok` löschen und neu aktivieren. Das ist ohnehin der ehrliche Weg, denn die Identität gehört zu dem Dienst, der sie ausgestellt hat. Dieser Schlüssel ersetzt `zrok_account_token` nicht: Die erste Aktivierung braucht trotzdem ein Token von dem Dienst, den er benennt. Die Umgebungsvariable `ZROK2_API_ENDPOINT` des SDK hat im selben Moment Vorrang vor diesem Schlüssel. |

Bei einem selbst gehosteten Dienst spaltet sich die Erreichbarkeit in zwei Richtungen, und nur eine davon liegt bei dir: **diese zurg** erreicht die Controller-API, dafür reicht eine Tailnet-Adresse. **Deine Empfänger** erreichen dagegen das Frontend des Dienstes. Ein Dienst, der nur in deinem eigenen Tailnet erreichbar ist, liefert deshalb nur URLs aus, die nur dein eigenes Tailnet öffnen kann.

Zwei weitere Dinge muss ein selbst gehosteter Dienst passend einstellen. Die Freigabe-URL ist die, die der Dienst für sein Frontend ankündigt. Eine nackte Adresse ohne Schema wird als `https` angenommen. Ein Frontend, das nur HTTP spricht, braucht daher TLS davor oder eine angekündigte URL mit eigenem Schema und Port. Außerdem wird die Freigabe in dem Namespace erstellt, den das zrok-SDK auflöst. Das ist `public`, sofern das SDK über `ZROK2_DEFAULT_NAMESPACE` nichts anderes sagt. zurg setzt keines von beiden fest. Ein Dienst, dessen Namespace anders heißt, muss das deshalb über diese Variable mitteilen.

```yaml
zrok_account_token: ""   # the enable token, needed for the first enable only
zrok_api_endpoint: ""    # self-hosted only; empty = the hosted service
```

## 6. Performance & Tuning (Fortgeschritten) {#6-performance--tuning-advanced}

Diese Einstellungen musst du selten anfassen, es sei denn, du debuggst etwas oder optimierst für deine konkreten Netzwerkbedingungen.

### Persistente Lese-Caches {#persistent-read-caches}

Zwei Byte-Caches überstehen einen Neustart. Beide werden über die ganze Instanz geteilt, und jeder hat sein eigenes Speicherlimit auf der Festplatte in MiB. Eine Änderung wirkt erst nach einem Neustart.

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `nzb_article_disk_cache_mb` | int | `512` | Dekodierte Usenet-Artikel, die in `data/bytecache/articles/` gespeichert werden. Ein Artikel, der einmal gelesen wurde, wird beim nächsten Mal von der Festplatte geliefert. `0` schaltet das ab. |
| `archive_decoded_disk_cache_mb` | int | `512` | Entpackte Archiv-Blöcke, die in `data/bytecache/decoded/` gespeichert werden. Ein Rücksprung beim Spulen oder ein Neustart dekodiert den Eintrag nicht wieder von vorne. Für `data/bytecache/decoded-tails/` wird dasselbe Limit noch einmal genutzt. Dort werden die letzten 8 MiB eines komprimierten Eintrags gespeichert, sobald etwas darauf zugegriffen hat. `0` schaltet beide ab. |

Wenn ein Limit voll ist, fliegen zuerst die ältesten ungenutzten Einträge raus. [persistent-caches.md](../internals/persistent-caches.md) beschreibt jeden Cache, der einen Neustart überlebt.

### CDN- & Host-Auswahl {#cdn--host-selection}

> **Verwandt:** Der Netzwerk-Latenztest, der die schnellsten Hosts ermittelt, läuft regelmäßig nach [`network_test_every_mins`](#user-agent--network) (Standard: alle 1440 Minuten / 24 Stunden).

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `rd_cdn_host_preference` | string | `"auto"` | Legt fest, welche RD-Download-Server zurg bevorzugt. `auto` nimmt, was RD bereitstellt. `force_cloudflare` schreibt den Host auf seinen `.cloud`-Zwilling um. Der erreicht dieselbe Maschine über Cloudflare, was hilfreich ist, wenn die direkten IPs blockiert sind. `force_numbered` nutzt die nummerierten Hosts von RD direkt. `force_location_<location>` (z. B. `force_location_syd`, `force_location_fra`) leitet über die Server eines bestimmten Landes. |
| `cdn_host_preference` | string | — | Veralteter Alias für `rd_cdn_host_preference`. Er bleibt aus Kompatibilitätsgründen erhalten und gilt nur für Real-Debrid. Wenn beide gesetzt sind, gewinnt der explizite Wert. |
| `tb_cdn_host_preference` | string | `"auto"` | TorBox-CDN-Region. `auto` lässt die Wahl von TorBox unangetastet. `force_location_<region>` liefert Downloads aus dieser Region. Erzwingen lassen sich nur Regionen, die aktuell einen Auslieferungsknoten anbieten. Die Auswahlliste im Dashboard zeigt genau diese an. Kein Fallback auf den alten Schlüssel: Seine Werte sind Real-Debrid-Standortcodes und haben hier keine Bedeutung. |
| `number_of_hosts` | int | `0` (alle) | Begrenzt zurg auf die N schnellsten Download-Hosts. Nach dem Geschwindigkeitstest der verfügbaren Hosts nutzt zurg nur die besten N. Setze `0`, um alle verfügbaren Hosts zu nutzen. Ein Wert wie `3` verteilt die Verbindungen weniger, stellt aber sicher, dass du immer die schnellsten Server nutzt. |

```yaml
rd_cdn_host_preference: "auto"
tb_cdn_host_preference: "auto"
number_of_hosts: 3
```

> **`force_cloudflare` und `force_location_*` schließen sich gegenseitig aus.** RD veröffentlicht einen `.cloud`-Zwilling nur für seine nummerierten Hosts. Stand 09.08.2026 (Messung) haben alle 25 nummerierten Subdomains einen, keine der 22 länderspezifischen. Ein Konto mit aktiviertem Cloudflare in den RD-Kontoeinstellungen bekommt daher immer einen nummerierten Host, und keine Standortvorgabe kann dafür berücksichtigt werden. zurg erkennt das beim Start anhand des Links, den es entsperrt. Dann überspringt es die Geo-Prüfungen, die nicht klappen können, und protokolliert den Grund, falls trotzdem ein Standort konfiguriert ist.

> **Hinweis zur Überprüfung von `force_location_*`:** Wenn du eine Geo-Standortvorgabe wie `force_location_nyk` nutzt, normalisiert der RD-API-Endpunkt `/rest/1.0/downloads` die Download-URLs auf nummerierte Server (z. B. `128-4.download.real-debrid.com`). Die Unrestrict-Antwort lieferte aber tatsächlich einen Geo-Server (z. B. `nyk7-4.download.real-debrid.com`). Der Download-Code bettet den nummerierten Server selbst ein (z. B. Code `...4128` entspricht Server `128-4`). Um zu prüfen, ob das Geo-Routing funktioniert, schau in die Logs von zurg oder in die rohe Unrestrict-Antwort. Verlass dich **nicht** auf die RD-Downloads-API.

### Rate-Limits {#rate-limits}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `api_rate_limit_per_minute` | int | `250` | Maximale Anzahl RD-API-Aufrufe pro Minute für allgemeine Vorgänge (alles außer dem Auflisten von Torrents). RD legt eigene Limits fest. Damit verhindert zurg, dass diese erreicht werden und du vorübergehend gesperrt wirst. Erhöhe den Wert nur, wenn du sicher bist, dass dein RD-Tarif das erlaubt. |
| `torrents_rate_limit_per_minute` | int | `75` | Maximale Anzahl RD-API-Aufrufe pro Minute speziell für den Endpunkt `/torrents`, mit dem deine Torrent-Liste abgerufen wird. Das ist getrennt, weil das Auflisten von Torrents der häufigste API-Aufruf ist und ein eigenes Aufrufverhalten hat. |
| `fetch_torrents_page_size` | int | `5000` | Wie viele Torrents pro Seite abgerufen werden, wenn du deine RD-Bibliothek synchronisierst. Größere Werte bedeuten weniger API-Aufrufe, aber größere Antworten. Wenn du eine sehr große Bibliothek hast (10.000+ Torrents), verkürzt ein höherer Wert die Synchronisationszeit. |

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

### Link-Überprüfung {#link-verification}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `use_range_verification` | bool | `false` | Legt fest, wie zurg prüft, ob Download-Links noch gültig sind. Bei false nutzt zurg eine `HEAD`-Anfrage (leichtgewichtig, es werden keine Daten übertragen). Bei true nutzt es einen `Range`-Header (`GET bytes=0-0`), der nur 1 Byte herunterlädt. Aktiviere das, wenn dein Netzwerk oder die RD-Server nicht richtig auf HEAD-Anfragen reagieren und deshalb fälschlicherweise Links als ungültig gelten. |

```yaml
use_range_verification: false
```

### Timeouts & Wiederholungen {#timeouts--retries}

| Option | Typ | Standard | Beschreibung |
|--------|-----|----------|--------------|
| `api_timeout_secs` | int | `60` | Maximale Sekunden, die auf die Antwort eines RD-API-Aufrufs gewartet wird. Erhöhe den Wert, wenn du eine langsame Verbindung hast und API-Aufrufe ins Timeout laufen. |
| `download_timeout_secs` | int | `15` | Maximale Sekunden, die beim Testen von Download-Links gewartet wird (wird bei Host-Geschwindigkeitstests und bei der Link-Überprüfung verwendet). Das ist nicht das Timeout für die eigentlichen Datei-Downloads. |
| `retries_until_failed` | int | `2` | Wie oft ein fehlgeschlagener API-Aufruf erneut versucht wird, bevor aufgegeben und als fehlgeschlagen markiert wird. Höhere Werte machen den Ablauf robuster gegen kurzzeitige RD-Ausfälle, verzögern aber die Erkennung von Fehlern. |
| `retry_503_errors` | bool | `false` | Wenn true, werden Anfragen erneut gesendet, die von RD eine 503-Antwort (Service Unavailable) bekommen. RD liefert 503 während Wartungsarbeiten oder bei Überlastung. Aktiviere das, wenn du häufig 503-Fehler hast, die sich schnell von selbst lösen. |

```yaml
api_timeout_secs: 60
download_timeout_secs: 15
retries_until_failed: 2
retry_503_errors: false
```

### Downloads & Debugging

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `get_downloads_limit` | int | `-1` | Maximale Anzahl der RD-Download-Einträge (keine Torrents), die abgerufen werden. `-1` bedeutet keine Begrenzung (alle abrufen), `0` überspringt das Abrufen von Downloads ganz, und eine positive Zahl begrenzt es. Nützlich, wenn du RD's direktes Link-Unrestricting nutzt und diese Dateien in zurg sehen willst. Lässt du den Schlüssel weg, gilt `-1`. Ein ausdrücklich gesetztes `0` wird als "cache none" berücksichtigt und beim Start mit einer Warnung im Log quittiert, weil das meist eine Konfiguration von vor der Bedeutungsänderung von `0` ist. |
| `load_dumped_torrents` | bool | `false` | Wenn true, lädt zurg beim Start die Torrent-Daten aus dem Ordner `dump/`. Das ist ein Wiederherstellungsmechanismus. Hat zurg den Torrent-Zustand früher gespeichert (z. B. bei einem Absturz), stellt dieser Schalter den Zustand wieder her, ohne alles erneut von RD abzurufen. |
| `log_requests` | bool | `false` | Wenn true, schreibt zurg detaillierte Statistiken für jede Download-Anfrage ins Log (Dateipfad, Antwortzeit, übertragene Bytes). Hilfreich beim Debuggen von Streaming-Problemen oder um Zugriffsmuster zu verstehen. Erzeugt viel Logvolumen, also in der Produktion ausschalten. |
| `log_level` | string | `DEBUG` | Wie viele Details geloggt werden: `DEBUG`, `INFO`, `WARN`, `ERROR` oder `FATAL`. Änderst du es im Dashboard, wirkt das sofort, ohne Neustart, und es setzt jede Komponente gleichzeitig neu. Es überschreibt die Umgebungsvariable `LOG_LEVEL`, sodass das Dashboard-Steuerelement auch in einem Container funktioniert, in dem eine solche Variable fest eingebaut ist. Lässt du den Schlüssel weg, gehört die Wahl wieder `LOG_LEVEL`. Ein Wert, der keine gültige Stufe nennt, wird beim Start mit einer Warnung ignoriert statt zum Abbruch zu führen. |
| `traffic_alert_gb` | int | `0` | Warnt, wenn ein Debrid-Konto an einem Tag mehr als diese Anzahl GiB über zurg überträgt (der Tag wird um 00:05 CET zurückgesetzt, passend zum Kontingent von Real-Debrid). Die Warnung nennt die Dateien, die in dieser Stunde am meisten genutzt wurden, und wer sie gelesen hat. So siehst du einen Bibliotheks-Scan oder einen Client, der ganze Dateien lädt, während es passiert. zurg schreibt außerdem zu jeder vollen Stunde eine Zusammenfassung der größten Dateien dieser Stunde ins Log, und eine Zeile für jeden einzelnen Lesevorgang ab 1 GiB, egal ob der Alarm gesetzt ist oder nicht. `0` schaltet den Alarm aus. |
| `traffic_alert_webhook` | string | — | Ein Discord-Webhook, an den der Traffic-Alarm ebenfalls gesendet wird. Halte ihn geheim: Jeder mit der URL kann in diesen Kanal posten. |

```yaml
get_downloads_limit: -1
load_dumped_torrents: false
log_requests: false
log_level: DEBUG
traffic_alert_gb: 500
```

## 7. Verzeichnisse & Filter {#7-directories--filters}

Definiere virtuelle Verzeichnisse, die deine Torrents anhand flexibler Filterregeln sortieren. Jedes Verzeichnis erscheint als Ordner in deinem Mount und zeigt nur die Torrents an, die zu seinen Filtern passen.

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true

  # ... (see config.example.yml for full examples)
```

### Verzeichnisoptionen {#directory-options}

| Option | Typ | Standard | Beschreibung |
|--------|------|---------|-------------|
| `group` | string | der eigene Name des Verzeichnisses | Verzeichnisse mit derselben Gruppe konkurrieren um jeden Torrent: Er landet im ersten Verzeichnis, dessen Filter passen, und in keinem anderen der Gruppe. Verzeichnisse in verschiedenen Gruppen bekommen jeweils eine eigene Kopie. |
| `group_order` | int | `0` (wird als `1` behandelt) | Priorität innerhalb der Gruppe: Niedrigere kommen zuerst. Bei Gleichstand entscheidet der Verzeichnisname. |
| `filters` | list | `[]` | Die Regeln, die festlegen, was hierhin gehört. Ein Torrent passt zum Verzeichnis, wenn **irgendein** Eintrag in der Liste passt. Eine leere oder fehlende Liste passt auf jeden Torrent. |
| `only_show_the_biggest_file` | bool | `false` | Zeigt nur die größte Datei jedes Torrents und blendet Samples, Extras und Begleitdateien aus. |
| `only_show_files_with_size_lte` | int | `0` (aus) | Blendet Dateien aus, die größer als diese Anzahl Bytes sind. |
| `only_show_files_with_size_gte` | int | `0` (aus) | Blendet Dateien aus, die kleiner als diese Anzahl Bytes sind. |
| `rex_shows` | string | `""` (keine) | Mit `rex_url`: der Titel einer TV-Bibliothek in rex, die die Episoden dieses Verzeichnisses zeigt. |
| `rex_movies` | string | `""` (keine) | Mit `rex_url`: der Titel einer Filmbibliothek in rex, die die Filme dieses Verzeichnisses zeigt, sowie alle Dateien, bei denen rex nicht erkennen kann, ob es eine Episode ist. |
| `rex_music` | string | `""` (keine) | Mit `rex_url`: der Titel einer Musikbibliothek in rex, die die Audiodateien dieses Verzeichnisses zeigt (`.flac`, `.mp3`, `.m4a`, `.m4b`), Hörbücher eingeschlossen. Ohne sie landet keine Audiodatei in rex. |
| `rex_photos` | string | `""` (keine) | Mit `rex_url`: der Titel einer Fotobibliothek in rex, die die Comics (`.cbz`, `.cbr`) dieses Verzeichnisses zeigt. Jeder Comic ist ein Album seiner Seiten, das Plex Web durchblättert und als Diashow abspielt. Plex für Android zeigt keine Fotobibliothek. Die Comics bleiben Dateien auf dem Mount. |

Eine Datei, die in zurg ausdrücklich sichtbar erzwungen wurde, ignoriert alle drei Sichtbarkeitsoptionen.

### Filterbedingungen {#filter-conditions}

| Bedingung | Typ | Beschreibung |
|-----------|------|-------------|
| `id` | string | Die ID des Torrents. Entscheidend: Nichts anderes im selben Eintrag wird berücksichtigt. |
| `regex` | string | Der Torrent-Name passt zum Muster. |
| `not_regex` | string | Der Torrent-Name passt nicht zum Muster. |
| `contains` | string | Der Torrent-Name enthält den Text (Groß-/Kleinschreibung wird ignoriert). |
| `contains_strict` | string | Der Torrent-Name enthält den Text (Groß-/Kleinschreibung wird beachtet). |
| `not_contains` | string | Der Torrent-Name enthält den Text nicht (Groß-/Kleinschreibung wird ignoriert). |
| `not_contains_strict` | string | Der Torrent-Name enthält den Text nicht (Groß-/Kleinschreibung wird beachtet). |
| `size_gte` | int | Die Gesamtgröße des Torrents beträgt mindestens so viele Bytes. |
| `size_lte` | int | Die Gesamtgröße des Torrents beträgt höchstens so viele Bytes. |
| `any_file_inside_regex` | string | Irgendeine Datei im Torrent passt zum Muster. |
| `any_file_inside_not_regex` | string | Irgendeine Datei im Torrent passt nicht zum Muster. |
| `any_file_inside_contains` | string | Irgendeine Datei enthält den Text (Groß-/Kleinschreibung wird ignoriert). |
| `any_file_inside_contains_strict` | string | Irgendeine Datei enthält den Text (Groß-/Kleinschreibung wird beachtet). |
| `any_file_inside_not_contains` | string | Irgendeine Datei enthält den Text nicht (Groß-/Kleinschreibung wird ignoriert). |
| `any_file_inside_not_contains_strict` | string | Irgendeine Datei enthält den Text nicht (Groß-/Kleinschreibung wird beachtet). |
| `any_file_inside_size_gte` | int | Irgendeine Datei ist mindestens so viele Bytes groß. |
| `any_file_inside_size_lte` | int | Irgendeine Datei ist höchstens so viele Bytes groß. |
| `added_within_hours` | int | Der Torrent wurde innerhalb dieser Anzahl von Stunden hinzugefügt. |
| `added_within_days` | int | Der Torrent wurde innerhalb dieser Anzahl von Tagen hinzugefügt. |
| `added_after` | string | Der Torrent wurde am oder nach diesem Datum hinzugefügt. Format `YYYY-MM-DD` oder `YYYY-MM-DD HH:MM`. |
| `added_before` | string | Der Torrent wurde vor diesem Datum hinzugefügt, gleiche Formate. Zusammen mit `added_after` müssen beide zutreffen. |
| `has_episodes` | bool | Episodenerkennung: Staffel-/Episodenmarkierungen oder CRC-Hashes in den Torrent- oder Dateinamen oder eine Reihe nummerierter Dateien. Ein Torrent, dessen größte Datei mindestens das 5-Fache der zweitgrößten ist, wird als Film mit Extras gelesen und abgelehnt. |
| `is_music` | bool | Irgendeine Datei endet auf `.m3u`, `.mp3`, `.flac`, `.m4a` oder `.m4b`. |
| `has_tag` | string | Der Torrent hat dieses Tag. Wirkt als Gate: Ohne dieses Tag kann nichts anderes im Eintrag passen. |
| `not_has_tag` | string | Der Torrent hat dieses Tag nicht und wirkt genauso als Gate. |
| `tags_match_all` | list | Alle aufgelisteten Tags sind vorhanden (Groß-/Kleinschreibung wird ignoriert). |
| `tags_match_any` | list | Mindestens ein aufgelistetes Tag ist vorhanden. |
| `tags_missing_all` | list | Keines der aufgelisteten Tags ist vorhanden. |
| `tags_missing_any` | list | Mindestens ein aufgelistetes Tag fehlt. |
| `provider` | string | Die Veröffentlichung wird von diesem Konto gehalten, benannt über dessen `name` im providers-Block. Ein Gate, kein Treffer: Zusammen mit einer anderen Bedingung müssen beide zutreffen. Allein angewendet nimmt es den gesamten Account ins Verzeichnis auf. |
| `not_provider` | string | Kein Konto, das die Veröffentlichung hält, ist dieses. Wirkt genauso als Gate. |
| `and` | list | Jede verschachtelte Bedingung muss zutreffen. |
| `or` | list | Mindestens eine verschachtelte Bedingung muss zutreffen. |

Tags stammen aus der Medienanalyse — siehe [tags.md](tags.md) für die vollständige Liste.

Muster werden als `/expression/flags` geschrieben, wobei die Flags beliebige Kombinationen aus `i` (Groß-/Kleinschreibung ignorieren), `m` (mehrzeilig), `s` (Punkt passt auf Zeilenumbruch) und `x` (erweitert) sind. Ein Wert ohne Schrägstriche wird als reiner Go-Regulärausdruck kompiliert.

Bedingungen innerhalb eines Filtereintrags werden **nicht** standardmäßig mit UND verknüpft. Die meisten passen auf den Eintrag, sobald eine davon zutrifft. Verwende einen expliziten `and:`-Block, wenn du alle davon meinst:

```yaml
directories:
  anime:
    group: media
    group_order: 10
    filters:
      - and:
          - has_episodes: true
          - any_file_inside_regex: /^\[/
          - not_regex: /\[One Pace\]/
```

### Verzeichnisse pro Konto {#per-account-directories}

Neben `__all__` bekommt jeder konfigurierte Account ein eigenes Verzeichnis, benannt nach ihm: `__realdebrid__`, `__torbox__`, `__alldebrid__`, `__nzb__`. Diese Verzeichnisse sind nicht konfiguriert. Sie erscheinen, weil der Account existiert, und verschwinden, wenn er entfernt wird. Bei nur einem Account fehlt dessen eigener Ordner in der Root-Auflistung des Mounts, und `__all__` enthält dieselben Dateien. Direkte HTTP- und WebDAV-Pfade wie `/http/__realdebrid__/` antworten weiterhin. Über den Mount werden sie nicht mehr aufgelöst. Zeig jede Bibliothek oder jedes Skript, das `__<name>__` verwendet hat, stattdessen auf `__all__`.

Jedes Verzeichnis enthält alles, was der jeweilige Account hat. Anders als ein gefiltertes Verzeichnis bestimmt es aber auch, wohin Lesezugriffe gehen. Ein Release, das zwei Accounts besitzen, ist ein einziger Eintrag in der Bibliothek. Ohne diese Funktion würde jede Kopie vom Account streamen, der im `providers`-Block zuerst sortiert ist:

```
__realdebrid__/Some.Release/movie.mkv   → streamed from Real-Debrid
__torbox__/Some.Release/movie.mkv       → streamed from TorBox
```

Der Pin schließt die anderen Accounts aus, statt den genannten nur zu bevorzugen. Es gibt kein stilles Failover: Kann TorBox die Datei nicht liefern, schlägt das Lesen unter `__torbox__` fehl, statt still mit den Bytes von Real-Debrid zu antworten. Lesezugriffe an anderen Stellen des Mounts sind nicht betroffen und laufen weiterhin ganz normal mit Failover.

Dass Accounts nicht identische Inhalte haben, hat zwei Folgen:

- Ein Verzeichnis listet nur die Dateien auf, die sein Account tatsächlich hat. Wenn TorBox nur einen Teil eines Releases geladen hat, den Real-Debrid komplett hat, zeigt `__torbox__` nur diesen Teil.
- Ob eine Datei defekt ist, wird pro Account beurteilt. Eine Datei, die auf Real-Debrid tot, auf TorBox aber intakt ist, liefert unter `__realdebrid__` einen 404-Fehler und spielt unter `__torbox__`. Der Rest des Mounts liefert sie weiterhin aus.

Der Verzeichnisname stammt vom `name` des Accounts, der standardmäßig seinem `type` entspricht. Zwei Accounts auf demselben Dienst brauchen unterschiedliche Namen (`rd-main`, `rd-backup`) und bekommen dann jeweils ein eigenes Verzeichnis. Das Usenet-Backend heißt standardmäßig `nzb` und erscheint daher als `__nzb__`. Wenn du lieber `__usenet__` durchsuchen willst, setz `name: usenet` bei diesem Provider-Eintrag.

Du kannst einen Account später umbenennen. zurg sieht dann dieselben Releases unter dem neuen Namen und verschiebt sie dorthin. Das alte Verzeichnis verschwindet mit dem alten Namen. Wenn ein Medienserver dieses Verzeichnis liest, zeig ihn vor dem Umbenennen auf das neue.

Dasselbe Release erscheint unter jedem Account, der es hat, und außerdem in deinen gefilterten Verzeichnissen. Zeig einen Medienserver deshalb auf einen Teil des Mounts statt auf alles. Sonst scannt er denselben Inhalt mehrfach.

Ein Account, der nach einem Verzeichnis benannt ist, das zurg schon verwendet (`all`, `unplayable`, `dump`, `downloads`), bekommt kein eigenes Verzeichnis. zurg gibt beim Start eine Warnung aus und übernimmt das bestehende Verzeichnis nicht.

### Lokale Debrid-Kataloge {#local-debrid-catalogs}

Jeder Debrid-Provider-Eintrag akzeptiert einen optionalen `library`-Block:

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: PRIMARY_RD_TOKEN
    download_tokens: # Optional bandwidth fallback.
      - SECOND_RD_TOKEN
    library:
      source: local
      path: torrents/rd-local
```

`source` ist standardmäßig `provider`. Mit `local` bestimmen portable `.zurgtorrent`-Dateien, welche Inhalte zur Bibliothek gehören, und die Wiedergabe nutzt die Zugangsdaten dieses Kontos. `path` ist standardmäßig `torrents/<resolved-account-name>` und muss unter `torrents/` bleiben. Dasselbe Quellverzeichnis kann nicht zu zwei aktivierten Konten gehören. NZB-Provider behalten ihre bestehende `nzbs/`-Bibliothek.

In diesem Beispiel verwenden beide RD-Tokens den einen Katalog in `torrents/rd-local/`. Das zweite Token braucht weder einen Provider-Eintrag noch ein Verzeichnis, und seine Torrent-Bibliothek wird nicht importiert. `download_tokens` behält sein Bandbreiten-Fallback-Verhalten; es zwingt nicht jeden Download über das zweite Token. Zwei getrennte local-Provider-Einträge besitzen dagegen zwei unterschiedliche Katalogverzeichnisse, selbst wenn beide Real-Debrid sind. Zugangsdaten bleiben in der Konfiguration und werden niemals in portable Dateien exportiert.

Mehr dazu in [portable Bibliotheken](../guides/local-libraries.md) zum Offline-Export, zur Migration aus `dump/`, zum Teilen und zu den Wiedergabe-Grenzen.

#### Einen Online-Account in eine lokale Bibliothek auslagern {#offloading-an-online-account-into-a-local-library}

Ein Real-Debrid- oder AllDebrid-Konto, das seinen Katalog selbst besitzt (kein `source` oder `source: provider`), kann seine fertigen Releases in eine lokale Bibliothek verschieben und vom Konto löschen. Dadurch werden deren Slots wieder frei:

```yaml
providers:
  - name: rd
    type: realdebrid
    token: YOUR_RD_TOKEN
    library:
      offload_to: rd-local      # a local entry of the same type
      offload_after_mins: 30    # optional, 30 is the default

  - name: rd-local
    type: realdebrid
    token: YOUR_RD_TOKEN        # the same account
    library:
      source: local
```

| Schlüssel | Standard | Bedeutung |
|---|---|---|
| `library.offload_to` | keiner | Name eines aktivierten `source: local`-Eintrags desselben Typs. Nur `realdebrid`- und `alldebrid`-Konten akzeptieren ihn, da nur deren Links nach dem Löschen des Torrents weiter funktionieren. Er darf nicht auf das Konto selbst verweisen. |
| `library.offload_after_mins` | `30` | Wie lange ein Release auf dem Konto vollständig sein muss, bevor es automatisch verschoben wird. Gezählt wird ab dem Zeitpunkt, an dem zurg es zum ersten Mal als vollständig gesehen hat. Ein Neustart startet die Wartezeit daher neu. Benötigt `offload_to`. |

Ein Release wird nur verschoben, wenn jede Datei einen Link hat, den ein anderes Konto einlösen könnte, nichts es gerade repariert oder herunterlädt, kein Sonarr- oder Radarr-Job im qBittorrent-Endpoint es noch auflistet und das Verschieben seinen Ordnernamen und alle Verzeichnisse, in denen es liegt, beibehält. Sein Ordner bleibt an seinem bisherigen Ort, und es wird kein Medienserver-Scan gestartet. Auf der Release-Seite im Dashboard kannst du ein einzelnes Release von Hand verschieben, mit oder ohne `offload_to`. Die Reihenfolge der Schritte, was passiert, wenn einer fehlschlägt, und wie lokale Wiedergabe bei einem geteilten Token geschützt ist, findest du unter
[portable Bibliotheken](../guides/local-libraries.md#offload-an-online-account-into-a-local-library).
