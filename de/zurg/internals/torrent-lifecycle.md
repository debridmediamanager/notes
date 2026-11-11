# Lebenszyklus eines Torrents bei Real-Debrid, AllDebrid und TorBox {#torrent-lifecycle-on-real-debrid-alldebrid-and-torbox}

Gemessen am 2026-08-30 gegen Live-Accounts. Alles, was unten als **beobachtet** markiert ist, stammt aus einem Mitschnitt. Alles, was als **abgeleitet** markiert ist, nicht. Dort steht dann auch der Grund.

zurg braucht das, weil der qBittorrent-Shim Sonarr und Radarr sagen muss, in welcher Phase ein Download gerade ist. Das kann er heute nicht. `TorrentInfo.Status` enthält das Statusvokabular von Real-Debrid, und die AllDebrid- und TorBox-Pakete übersetzen in dieses Vokabular, bevor zurgs eigener Code einen Torrent überhaupt sieht. TorBox `stalled (no seeds)` kommt als `queued` an. Seeder, Geschwindigkeit oder eta werden gar nicht übertragen. Die Phasentabelle musste deshalb aus dem Wire-Format aufgebaut werden und nicht aus den Provider-Paketen, die es vorher schon vereinheitlichen.

Das Harness ist `scripts/torrent_lifecycle_probe.py`. Es spricht direkt die rohen REST-APIs an, damit die Mitschnitte den Wire-Status enthalten. Es löscht alles, was es hinzufügt, auch wenn du mit Ctrl-C abbrichst.

## So haben wir gemessen {#how-this-was-measured}

### Die Konten {#the-accounts}

| Anbieter | Account | Warum dieser |
|---|---|---|
| Real-Debrid | ein Testaccount | kein laufendes zurg nutzt ihn, also hat während des Laufs nichts anderes daran gerührt |
| AllDebrid | ein Test-Key | der Account hatte schon andere Magnets, deshalb wurden nur IDs gelöscht, die der Lauf selbst angelegt hat |
| TorBox | ein Live-Key | **eine andere zurg-Instanz lief mit demselben Account**, das ist keine Fußnote. Siehe [Gefahren](#hazards-found-on-the-way) |

Die Zugangsdaten kommen aus `RD_TOKEN` `AD_KEY` `TB_KEY` in der Umgebung. Nichts schreibt
sie in einen Mitschnitt.

### Die Torrents {#the-torrents}

Alles legal. FOSS-Images und Filme Public Domain. Jeder Info-Hash, der aus einer `.torrent`-Datei stammt, wurde vom Harness aus der Datei neu berechnet und nicht abgetippt. Die Swarm-Größen stammen aus Tracker-Scrapes vom selben Tag.

| Fall | Torrent | Info-Hash | Größe | Tracker-Seeder | Webseeds |
|---|---|---|---|---|---|
| gecached | Big Buck Bunny | `dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c` | 264 MiB | n/a | n/a |
| gecached | Sintel | `08ada5a7a6183aae1e09d831df6748d566095a10` | 123 MiB | n/a | n/a |
| gecached | ubuntu-26.04.1-desktop-amd64.iso | `5b1e0d988fc7a0c9e99bd852071681a59974b39f` | 6.04 GiB | 22 bis 27 | keine |
| ungecached | debian-13.6.0-arm64-DVD-1.iso | `4d38178b8f08447ea8609e844b0071354ed65887` | 3.72 GiB | 212 | 2 |
| ungecached | debian-13.2.0-amd64-DVD-1.iso | `7f23b66ebc763f6d931e999583adfd22a7d796fa` | 3.71 GiB | 328 | 2 |
| Webseed | Prelinger `205882_Home_Movie_005588` | `69e7bba940b3c2edf7ce517330e3ca904877d8d1` | 0.71 GiB | 0 Seeder und 0 Leecher | 3 |
| ohne Seeder | ubuntu-16.04.6-desktop-i386.iso | `c16796a74dc24cc7c6df2f7b66b861e22dec69b1` | 1.56 GiB | 0 | keine |
| ohne Seeder | ubuntu-24.04-beta-live-server-s390x.iso | `8e693ebcdda44f741e2034cedbb552e93944143d` | 1.18 GiB | 0 | keine |
| ohne Metadaten | zufällig 40-hex | `3f9c1a77b0e4d2568af3c01e9b7d4a5268c1f0e3` | keine | keine | keine |

Die Nullen sind echt und kein toter Tracker. `torrent.ubuntu.com` wurde für alle drei Ubuntu-Einträge in derselben Schleife zweimal gescrapt. Für 26.04.1 lieferte es erst 22, dann 27 Seeder, während es für die zwei ohne Seeder ein leeres `d5:filesdee` zurückgab. Dasselbe gilt für `bt1.archive.org` und das Prelinger-Item.

TorBox `checkcached` wurde nach jedem Hash gefragt, bevor irgendetwas hinzugefügt wurde. Von den dreien ist es der einzige nicht-destruktive Cache-Test. Es meldete gecached für die drei gecachten Zeilen und ungecached für die anderen sechs. Genau diese Aufteilung behaupten die Fallnamen.

### Abfrageintervall und Limits {#poll-cadence-and-caps}

3 s für die ersten 2 Minuten, danach 15 s. 1 s für den Cached-Fall, weil der gesamte Lebenszyklus dort schon innerhalb eines normalen Polls vorbei sein kann. Für die Kampagne begrenze ich das auf 15 Minuten pro Torrent statt des Standardwerts des Skripts von 30. Der vorgeschlagene Standard-Timeout des Shims liegt bei 10 Minuten, und ein Torrent, der bei 15 Minuten noch in Bewegung ist, liegt schon außerhalb des einzigen Zeitfensters, auf das es ankommt. Hinzufügungen bei Real-Debrid liegen mindestens 20 s auseinander.

Jeder Provider lief als eigener Prozess mit eigenem Ausgabeverzeichnis. So bleibt der Abstand zwischen den Real-Debrid-Hinzufügungen innerhalb eines Prozesses korrekt, und alle drei können gleichzeitig laufen.

---

## Real-Debrid

### Endpunkte {#endpoints}

```
POST   /rest/1.0/torrents/addMagnet          magnet=magnet:?xt=urn:btih:<hash>   -> 201 {"id","uri"}
POST   /rest/1.0/torrents/selectFiles/{id}   files=all                           -> 204
GET    /rest/1.0/torrents/info/{id}                                              -> 200 object
DELETE /rest/1.0/torrents/delete/{id}                                            -> 204
```

### Beobachtete Statuswerte {#status-values-observed}

`waiting_files_selection` `magnet_conversion` `magnet_error` `queued` `downloading` `uploading`
`downloaded`

Hier nicht beobachtet. `compressing` `virus` `error` `dead`. Dafür bräuchte diese Kampagne Inhalte, die sie auf legalem Weg gar nicht hätte erzeugen können.

### Welche Felder in welchem Status vorhanden sind {#which-wire-fields-exist-in-which-status}

Dieses Thema ist wichtiger als das Vokabular. Felder kommen und gehen. Ein Mapper, der `speed` in jedem Zustand liest, liest in der Hälfte der Fälle einen fehlenden Schlüssel.

| Feld | magnet_conversion | queued | downloading | uploading | downloaded |
|---|---|---|---|---|---|
| `status` | ja | ja | ja | ja | ja |
| `progress` | 0 | 0 | **Gleitkomma-Prozent** 0 bis 100 | **startet bei 0 neu** und steigt bis 100 | 100 |
| `seeders` | ja | **fehlt** | ja | **fehlt** | **fehlt** |
| `speed` | **fehlt** | **fehlt** | ja, Bytes pro Sekunde | ja, im Mitschnitt immer 0 | **fehlt** |
| `bytes` / `original_bytes` | 0 | echte Größe | echte Größe | echte Größe | echte Größe |
| `filename` | `"Magnet"` | echter Name | echter Name | echter Name | echter Name |
| `files` | `[]` | gefüllt | gefüllt | gefüllt | gefüllt |
| `links` | `[]` | `[]` | `[]` | füllt sich während der Phase | gefüllt |
| `ended` | fehlt | fehlt | fehlt | fehlt | vorhanden |

`progress` ist eine **Gleitkommazahl** und keine Ganzzahl. Der Mitschnitt enthält 0.4, 0.8 und 1.4 neben 100.
Eine Stall-Erkennung, die auf ganze Prozent rundet, hält ein 100-GB-Release bei 1 MB/s für hängen geblieben.

`progress` **läuft absichtlich rückwärts**. Es wird auf 0 zurückgesetzt, wenn der Status auf `uploading` wechselt, und steigt danach wieder bis 100.
Bewegung muss als Phasenwechsel oder als Anstieg von progress definiert werden, niemals als monoton steigender Prozentwert.

`seeders` verschwindet, statt auf null zu gehen, sobald der Torrent `downloading` verlässt. Genauso `speed`.
Ein Mapper muss einen fehlenden Schlüssel als unbekannt behandeln und nicht als null.

### Was jeder Fall gemacht hat {#what-each-case-did}

| Fall | Torrent | Übergänge mit Sekunden ab Hinzufügen | Ergebnis |
|---|---|---|---|
| gecacht | Big Buck Bunny | `downloaded`@0.0 | fertig in 1.32 s von Anfang bis Ende |
| gecacht | Sintel | `downloaded`@0.0 | fertig in 0.73 s |
| gecacht | Ubuntu 26.04.1 | `downloaded`@0.0 | fertig in 0.32 s |
| nicht gecacht | Debian 13.6.0 arm64 DVD-1 | `downloaded`@0.0 | bereits auf diesem Konto gecacht |
| nicht gecacht | Debian 13.2.0 amd64 DVD-1 | `queued`@0.0 `downloading`@3.1 `uploading`@166.5 `downloaded`@196.8 | fertig. 3.71 GiB in 197 s |
| Webseed | Prelinger home movie | `magnet_conversion`@0.0 `magnet_error`@318.0 | fehlgeschlagen |
| ohne Seeds | ubuntu-16.04.6-desktop-i386 | `queued`@0.0 `downloading`@3.1 `uploading` `downloaded`@166.8 | fertig. Der Fall ließ sich nicht reproduzieren |
| ohne Seeds | ubuntu-24.04-beta-live-server-s390x | `queued`@0.0 `downloading`@3.1 und danach nichts mehr | **nach 907.6 s immer noch `downloading`, abgebrochen**. Das ist das Hängen-Muster |
| ohne Metadaten | zufällige 40-Hex | `magnet_conversion`@0.0 `magnet_error`@317.9 | fehlgeschlagen |

### Die Latenz beim Hinzufügen aus dem Cache {#the-cached-add-latency}

Das ist die Zahl, auf der der Cached-only-Modus des Shims aufbaut.

| Torrent | addMagnet liefert | selectFiles liefert | erster `/torrents/info` | Status |
|---|---|---|---|---|
| Big Buck Bunny | t=0 | t+1.211 s | t+1.318 s | `downloaded` |
| Sintel | t=0 | t+0.632 s | t+0.729 s | `downloaded` |
| Ubuntu 26.04.1 | t=0 | t+0.215 s | t+0.320 s | `downloaded` |

**Beobachtet.** Ein gecachtes Torrent ist beim allerersten Abruf nach `selectFiles` schon `downloaded`. Die gesamte synchrone Dauer besteht aus zwei Round-Trips. Es durchläuft nie `queued` und nie `downloading`.

Ein zweiter Lauf hat `/torrents/info` alle 0,25 s abgefragt, und zwar sowohl in der Lücke zwischen `addMagnet` und `selectFiles` als auch danach. Genau das macht `--rd-select-detail`, und das klärt den Ablauf.

| Torrent | Status vor `selectFiles` | `selectFiles` | Erster Abruf danach | addMagnet bis `downloaded` |
|---|---|---|---|---|
| Big Buck Bunny | `waiting_files_selection` mit 3 aufgelisteten Dateien und leerem `links` | 204 bei t+1.314 s | `downloaded` `progress` 100 `links` 1 | **1.535 s** |
| Sintel | `waiting_files_selection` mit 11 aufgelisteten Dateien | 204 bei t+0.627 s | `downloaded` `progress` 100 `links` 1 | **0.841 s** |
| Ubuntu 26.04.1 | `waiting_files_selection` mit 1 aufgelisteter Datei | 204 bei t+0.219 s | `downloaded` `progress` 100 `links` 1 | **0.430 s** |

Der komplette Cached-Ablauf ist also `waiting_files_selection`, dann direkt `downloaded`, und dazwischen passiert nichts. Die Dateiliste ist schon vor `selectFiles` da. `links` füllt `selectFiles`.

**Das Probe-Fenster für Cached-only kann eine einzige Abfrage sein.** Von Anfang bis Ende dauerte es 0,43 s bis 1,54 s über drei Torrents mit 123 MiB, 264 MiB und 6,04 GiB. Ein Fenster von zwei Sekunden bei einem Abfrageintervall von einer Viertelsekunde ist großzügig bemessen.

Gegenüber den 100 s, die Sonarr und Radarr für einen `torrents/add`-Aufruf erlauben (siehe [qbittorrent-client-contract.md §1.7a](qbittorrent-client-contract.md)), kostet ein Cached-only-Probe-Fenster von ein paar Sekunden praktisch nichts. Einen Grund, es im zweistelligen Sekundenbereich anzusetzen, gibt es nicht.

### Eigenheiten, mit denen ein Stage-Mapper klarkommen muss {#quirks-a-stage-mapper-has-to-survive}

- **`selectFiles` antwortet mit 404, während der Torrent noch in `magnet_conversion` steckt, und die Fehlermeldung lügt.**
  Der Body ist `{"error":"parameter_missing","error_code":1,"error_details":"{files} is missing"}`, obwohl
  `files=all` gesendet wurde. Es gibt einfach noch keine Dateien zum Auswählen. Das ist kein Fehler beim
  Hinzufügen, und der Torrent bleibt am Leben. Beide Durchläufe, die darauf gestoßen sind, lebten noch weitere 318 s.
- **Der Hash eines Private-Tracker-Torrents kann sofort verworfen werden, statt erst nach 318 s.** Der Hash hinter dem qBittorrent-Bericht vom
  2026-08-31 (ein CiNEPHiLES-Remux von einem UNIT3D-Indexer, `45e1ec0d…`) lieferte `magnet_error` mit null Dateien beim
  ersten Abruf nach addMagnet, also kein `magnet_conversion`-Zeitfenster überhaupt, Sekunden nach dem Hinzufügen. Ob Real-Debrid den Hash erkannt oder schnell abgelehnt hat, ist von außen gleich: Ein privater Hash hat keinen DHT-Schwarm, also kann addMagnet dafür nie gelingen, und selectFiles auf der toten Instanz antwortet mit dem lügenden 404 von oben.
- **`addTorrent` überspringt bei nicht gecachten Inhalten nichts, bei gecachten dagegen alles.** Eine `.torrent`-Datei, die für Inhalte hochgeladen wurde, die Real-Debrid nicht hat (ein archive.org Big Buck Bunny, geseedet, aber nicht gecacht), ging wie ein nackter Magnet in `magnet_conversion`. Die Metadaten der Datei werden nicht zur Auflösung genutzt. Eine gecachte Datei (ein Ubuntu-ISO) lieferte beim ersten Abruf `waiting_files_selection` mit ihrer Dateiliste, wurde ausgewählt und war innerhalb von zwei Sekunden `downloaded`, ohne `magnet_conversion` je zu durchlaufen. Der Nutzen des Uploads liegt also in der sofortigen Hash→Cache-Abfrage. Genau dadurch lässt sich das Release eines Private-Trackers hinzufügen, wenn der Inhalt gecacht ist, und als Magnet nie.
- **Die Metadatenauflösung gibt nach 318 s auf.** Zwei unabhängige Durchläufe gingen von `magnet_conversion` zu `magnet_error` bei 317.9 s bzw. 318.0 s. Das ist die Grenze, an die ein Magnet ohne erreichbare Peers stößt. Es ist dasselbe, ob für den Hash ein Torrent existiert oder nicht.
- **`seeders` lügt während `magnet_conversion`.** Der zufällige 40-stellige Hash meldete bei 80.9 s `seeders: 1`. Dafür existiert kein Torrent.
- **`ended` bei einem frisch hinzugefügten gecachten Torrent trägt ein altes Datum.** Die Mitschnitte enthalten `2025-12-28` und `2026-07-28` für Torrents, die am 2026-08-30 hinzugefügt wurden. Das ist der Zeitpunkt, an dem Real-Debrid den Inhalt zum ersten Mal hatte, nicht der, an dem diese Instanz fertig wurde. Berechne daraus kein Alter.
- **Ein Magnet ohne Peers stirbt bei der Metadatenauflösung und erreicht nie den Webseed.** Real-Debrid berücksichtigt Webseeds, sobald es den Torrent hat. Den Torrent von einem Magnet ohne Peers zu holen, kann es aber nicht. Ein Item, das nur einen Webseed hat und als Magnet hinzugefügt wird, endet also mit `magnet_error`. Das ist ein Metadatenfehler und kein Webseed-Fehler, und von `/torrents/info` aus sehen beide gleich aus.

---

## AllDebrid

### Endpunkte {#endpoints-1}

`v4` und `v4.1` sind nicht austauschbar, und dieser Unterschied hat uns in dieser Kampagne erwischt.

```
POST /v4/magnet/upload      magnets[]=magnet:?xt=urn:btih:<hash>   -> 200, per-magnet `ready` flag
POST /v4/magnet/upload/file multipart files[]=<the .torrent>       -> 200, per-file `ready` flag
GET  /v4.1/magnet/status?id=<id>                                   -> 200, data.magnets is an OBJECT
GET  /v4.1/magnet/status                                           -> 200, data.magnets is a LIST
POST /v4/magnet/delete      id=<id>                                -> 200
```

**Der File-Upload antwortet unter `files`, nicht unter `magnets`.** Die Felder pro Eintrag sind gleich: `id`, `hash`,
`name`, `ready`, optional ein `error` pro Eintrag. Das `ready`-Flag unten ist also in beiden Fällen die Cache-Antwort. Ein Decoder, der für die Magnet-Antwort geschrieben wurde, liest aber eine leere Liste.

**Und nur die Datei-Variante beschreibt ein Release, das AllDebrid ohne Swarm beschreiben kann.** Gemessen am 2026-09-01 auf dem Testaccount, mit zwei gleich aufgebauten synthetischen privaten Torrents, deren Hashes noch nie ein Swarm gesehen hat. Als Dateien hochgeladen kamen sie mit ihren echten Namen und echten Größen zurück (`"name":"zurg.private.ad.probe","size":65536`) und wurden als `In queue` gelistet, wobei die Uhr noch nicht lief. Als nackter `magnets[]`-Hash geschickt lautete die Antwort `"name":"noname","size":0`. AllDebrid hat es angenommen und nichts darüber gewusst. Genau so landet jedes Release eines privaten Trackers, das über den Hash hinzugefügt wird.

**`/v4/magnet/status` gibt es nicht mehr.** Mit oder ohne id antwortet er mit HTTP 200 und `{"status":"error","error":{"code":"DISCONTINUED"},"deprecated":true}`. `/v4/magnet/upload` und `/v4/magnet/delete` funktionieren noch. Die Annahme im Plan, dass der v4-Status-Endpoint genutzt und v4.1 zum Vergleich einmal abgefragt werden könnte, ist also falsch herum. v4.1 ist der einzige Status-Endpoint. Das Harness protokolliert pro Torrent genau einen v4-Lesezugriff, damit der Mitschnitt den Beweis liefert und nicht nur die Behauptung.

Die Authentifizierung läuft über `Authorization: Bearer <apikey>`. Ein `agent`-Parameter wird nicht benötigt.

### Beobachtete Statuswerte {#status-values-observed-1}

| `statusCode` | `status` | Gesehen |
|---|---|---|
| 0 | `In queue` | ja |
| 1 | `Downloading` | ja |
| 2 | `Compressing / Moving` | **nein** |
| 3 | `Uploading` | ja |
| 4 | `Ready` | ja |
| 5 und höher | die Fehlercodes | **nein** |

### Welche Felder in welchem Status vorhanden sind {#which-wire-fields-exist-in-which-status-1}

| Feld | In queue (0) | Downloading (1) | Uploading (3) | Ready (4) |
|---|---|---|---|---|
| `status` / `statusCode` | ja | ja | ja | ja |
| `version` | 1 | 2 | 2 | 2 |
| `filename` | `"noname"`, bis die Metadaten da sind | echter Name, sobald die Metadaten da sind | echter Name | echter Name |
| `size` | 0, bis die Metadaten da sind | echte Größe | echte Größe | echte Größe |
| `downloaded` | 0 | **der Fortschrittswert, in Bytes** | entspricht `size` | **fehlt** |
| `downloadSpeed` | 0 | ja, Bytes pro Sekunde | 0 | **fehlt** |
| `seeders` | 0 | ja | 0 | **fehlt** |
| `uploaded` / `uploadSpeed` | 0 | 0 | **der Fortschrittswert für diese Phase** | **fehlt** |
| `processingPerc` | 0 | 0 | 0 | **fehlt** |
| `files` / `nbLinks` | fehlt | fehlt | fehlt | vorhanden |
| `completionDate` | 0 | 0 | 0 | gesetzt |

**Irgendwo gibt es keinen Prozentwert.** Der Fortschritt bei AllDebrid ist `downloaded / size`, und beide Werte sind ganze Zahlen in Bytes. `processingPerc` blieb bei jedem Status und in jedem Mitschnitt bei 0.

`Uploading` bedeutet, dass AllDebrid den fertigen Download in den eigenen Speicher verschiebt. Dafür gibt es einen eigenen Fortschrittszähler in `uploaded` und `uploadSpeed`, und `downloadSpeed` ist die ganze Zeit 0. Eine Stall-Regel, die nur `downloaded` überwacht, stuft eine gesunde `Uploading`-Phase als hängend ein.

### Was jeder Fall gemacht hat {#what-each-case-did-1}

| Fall | Torrent | `ready` beim Hochladen | Übergänge mit Sekunden ab Hinzufügen | Ergebnis |
|---|---|---|---|---|
| gecached | Big Buck Bunny | true | `Ready`@0.0 | fertig in 0.11 s |
| gecached | Sintel | true | `Ready`@0.0 | fertig in 0.12 s |
| gecached | Ubuntu 26.04.1 | true | `Ready`@0.0 | fertig in 0.11 s |
| ungecached | Debian 13.6.0 arm64 DVD-1 | true | `Ready`@0.0 | war schon gecached |
| ungecached | Debian 13.2.0 amd64 DVD-1 | false | `In queue`@0.0 `Downloading`@12.5 mit allen Zählern bei null bis 634.9 `Uploading`@650.1 `Ready`@876.9 | fertig in 877 s |
| webseed | Prelinger home movie | false | `In queue`@0.0 `Downloading`@6.3 und danach alle Zähler bei null | **abgebrochen bei 907.8 s, immer noch `Downloading`** |
| seedless | ubuntu-16.04.6-desktop-i386 | false | `In queue`@0.0 `Downloading`@9.4 mit allen Zählern bei null bis 589.6 `Uploading`@619.9 `Ready`@650.2 | fertig in 650 s |
| seedless | ubuntu-24.04-beta-live-server-s390x | false | `In queue`@0.0 `Downloading`@3.2 und danach alle Zähler bei null | **abgebrochen bei 907.0 s, immer noch `Downloading`** |
| nometa | zufällige 40-Hex | false | `In queue`@0.0 `Downloading`@9.4 und danach alle Zähler bei null | **abgebrochen bei 907.4 s, immer noch `Downloading`** |

Ein separater Lauf gegen Debian 13.3.0 arm64 DVD-1 (`6aa9b0a4709a0d6c4982fd0363614d9006877223`) hat einen kompletten ungecachten Lebenszyklus erfasst und dient als Referenzablauf.

| Sekunden | Status | Was sich bewegt hat |
|---|---|---|
| 0.0 | `In queue` 0 version 1 | `filename` ist `"noname"` und `size` ist 0 |
| 2.2 | `Downloading` 1 version 2 | immer noch kein Name und keine Größe |
| 4.3 | `Downloading` | `filename` und `size` werden aufgelöst |
| 6.5 bis 55.1 | `Downloading` | `downloaded` steigt bis auf `size`. `downloadSpeed` erreicht einen Spitzenwert von etwa 110 MB/s. `seeders` 8 bis 9 |
| 57.2 | `Uploading` 3 | `downloadSpeed` fällt auf 0. `uploadSpeed` und `uploaded` beginnen zu steigen |
| 65.6 | `Ready` 4 | `files` und `nbLinks` erscheinen. Sechs Fortschrittsfelder verschwinden |

3.72 GiB in 65.6 s.

### AllDebrid meldet gar keinen Fortschritt, während ein Job auf seine eigene Infrastruktur wartet {#alldebrid-reports-no-progress-at-all-while-a-job-waits-for-its-own-infrastructure}

Das ist der Befund, der das Timeout-Design am stärksten verändert, und wir mussten zwei unabhängige Durchläufe machen, bis wir ihm trauen konnten.

`Downloading` mit `statusCode` 1 kommt wenige Sekunden nach dem Upload. Danach meldet AllDebrid eine Zeit lang `downloaded` 0, `downloadSpeed` 0, `seeders` 0, `uploaded` 0, `uploadSpeed` 0 und `processingPerc` 0. Außerdem setzt es `size` wieder auf 0 und `filename` wieder auf den Info-Hash zurück, auch wenn beide Werte vorher schon richtig gemeldet waren.

| Durchlauf | Wie lange alle Zähler auf null blieben | Was danach passierte |
|---|---|---|
| Debian 13.2.0 amd64 DVD-1 | **622 s** von 12.5 s bis 634.9 s | 3.71 GiB in 15 s heruntergeladen, dann `Uploading`, dann `Ready` bei 876.9 s |
| ubuntu-16.04.6-desktop-i386 | **580 s** von 9.4 s bis 589.6 s | 1.56 GiB in 30 s heruntergeladen, dann `Uploading`, dann `Ready` bei 650.2 s |

Beide sind fertig geworden. Keiner von beiden hat in den ersten zehn Minuten auch nur ein einziges Byte Bewegung gemeldet.

**Ein Timeout ohne Bewegung von zehn Minuten würde gesunde AllDebrid-Jobs abbrechen.** Der vorgeschlagene Standardwert `download_timeout_mins` von 10 liegt in beiden Durchläufen genau in diesem Fenster. Entweder muss das Timeout länger sein als dieses Fenster, oder AllDebrid-`Downloading` mit `size` 0 muss als eigene Stufe gelten, für die die Uhr nicht läuft. Dass Name und Größe fehlen, zeigt, dass der Job zugewiesen, aber noch nicht gestartet ist. Das ist kein Fehler.

Ein Durchlauf, der sofort gestartet ist, zeigt den Gegensatz. Debian 13.3.0 arm64 DVD-1 ging von `In queue` in 6.5 s zu echten Byte-Zählern über. Die Wartezeit ist also eine Warteschlange und kein fester Verzug.

### Das `ready`-Flag ist eine echte Cache-Antwort {#the-ready-flag-is-a-real-cache-answer}

`ready` im `/v4/magnet/upload`-Response war für jeden Hash true, den TorBox ebenfalls als cached gemeldet hat, und false für die zwei, die die Kampagne heruntergeladen hat. AllDebrid hat keine separate Cache-Abfrage, daher ist dieses Flag das gesamte Cache-Signal. zurg gibt es jetzt aus beiden Add-Pfaden weiter, dem des Magnets und dem des Datei-Uploads, als `MagnetResponse.Cached` mit gesetztem `CacheKnown`. So wird ein Backend, das nicht antworten kann, nie mit einem Backend verwechselt, das einen Miss meldet.

**Ein false-`ready` bedeutet, dass der Magnet bereits hinzugefügt ist.** Es gibt keine Möglichkeit, AllDebrid zu fragen, ob ein Hash gecached ist, ohne ihn hinzuzufügen. Ein reiner Cache-Pfad bei AllDebrid muss den Miss deshalb wieder löschen.

## TorBox

### Endpunkte {#endpoints-2}

```
GET  /v1/api/torrents/checkcached?hash=<hash>&format=list
POST /v1/api/torrents/createtorrent      magnet=…&seed=3&allow_zip=false   -> {"success":true,"data":{"torrent_id":N}}
POST /v1/api/torrents/createtorrent      multipart file=<the .torrent>    -> the same shape; `detail` says whether it was cached
GET  /v1/api/torrents/mylist?id=<id>&bypass_cache=true
POST /v1/api/torrents/controltorrent     {"torrent_id":N,"operation":"delete"}
```

### Beobachtete Statuswerte {#status-values-observed-2}

`metaDL` `checking` `stalledDL` `stalled (no seeds)` `downloading` `processing`
`uploading (no peers)` `uploading` `cached`

`processing` und `checking` und `stalledDL` stehen **nicht in zurgs Übersetzungstabelle**
(`internal/torbox/types.go` `normalizeStatus`). Alle drei fallen in den Default-Zweig und werden
als `downloading` gemeldet.

`checking` ist die Phase, in der TorBox auf die Metadaten wartet, und nicht die, in der ein Hash geprüft wird. Ein Magnet, dessen Swarm
nie antwortet, geht auf `metaDL`, dann auf `checking` und bleibt dort hängen. Der zufällige 40-stellige Hex-Hash stand bei der 910-s-Grenze noch immer auf
`checking`, und das Prelinger-Item ohne Peers bei 911 s genauso. TorBox gibt nie auf, so wie Real-Debrid es bei 318 s tut.

**Das Hochladen der `.torrent`-Datei überspringt diese Wartezeit komplett, und genau darin liegt der ganze Unterschied für das Release eines privaten Trackers.** Gemessen am 2026-09-01 auf dem oben genannten Konto, mit demselben synthetischen privaten Torrent, der auf beide Arten gesendet wurde. Als Hash: angenommen mit einer `torrent_id`, danach `checking` mit `name` auf den nackten Hash gesetzt, `size: -1`, `files: null` und `eta: 8640000` — TorBox sucht nach einem Swarm, der nicht im DHT steht. Das macht es bis zur Grenze, ohne dazu etwas zu melden. Als Datei, bei `POST /torrents/createtorrent` mit den Bytes in einem multipart-`file`-Teil: drei Sekunden später zurückgelesen mit dem eigenen Namen des Torrents, der echten Größe und `stalled (no seeds)` — derselbe Inhalt, den niemand hält, der jetzt aber beschrieben ist. Die Phase ist der Punkt. `checking` mit `size: -1` wird auf `StageResolvingMetadata` abgebildet, was heißt, dass noch gearbeitet wird und man nichts abschließend sagen kann. `stalled (no seeds)` wird auf `StageStalledNoPeers` abgebildet, und damit kann der qBittorrent-Endpunkt etwas anfangen. Ein gecachtes Release kam innerhalb derselben drei Sekunden als `done` mit 100 % und seiner Dateiliste zurück. Der Teilname ist entscheidend: Eine Datei unter einem anderen Namen wird gar nicht gesehen, und der Endpunkt antwortet mit `MISSING_REQUIRED_OPTION`, "You must provide either a file or magnet link".

(Eine frühere Übersetzung wurde abgelehnt: Code-Spans stimmen nicht überein (` maps to `). Behalte die Struktur exakt bei.)

### Welche Felder in welchem Status vorhanden sind {#which-wire-fields-exist-in-which-status-2}

TorBox sendet in jedem Zustand dieselben Schlüssel und ändert nur die Werte. Deshalb ist es das einfachste der drei zum Lesen.
Die Werte tragen die Bedeutung.

| State | `download_finished` | `download_present` | `cached` | `active` | `progress` | `eta` | `size` |
|---|---|---|---|---|---|---|---|
| `metaDL` | false | false | false | true | 0 | 8640000 | 0 |
| `checking` | false | false | false | true | 0 | 8640000 | **-1** |
| `stalledDL` | false | false | false | true | winzig | 8640000 | echt |
| `stalled (no seeds)` | false | false | false | true | 0 | 8640000 | echt |
| `downloading` | false, dann **true** | false | false | true | Bruchteil | Sekunden | echt |
| `processing` | **true** | **false** | false | true | 1 | Sekunden | echt |
| `uploading (no peers)` | **true** | **false** | false | true | 1 | 2591994 | echt |
| `uploading` | true | **true** | true | true | 1 | 0 | echt |
| `cached` | true | true | true | false | 1 | 0 | echt |

Feldnamen. Der Plan hat alle diese Namen als ungeprüft aufgeführt.

| Was | TorBox-Feld | Form |
|---|---|---|
| progress | `progress` | **Bruchteil von eins**, kein Prozentwert. `0.0793719` |
| seeders | `seeds` | Ganzzahl |
| leechers | `peers` | Ganzzahl |
| download rate | `download_speed` | Bytes pro Sekunde |
| upload rate | `upload_speed` | Bytes pro Sekunde |
| eta | `eta` | Sekunden. `8640000` ist der Platzhalter für „unbekannt“ |
| bytes fetched | `total_downloaded` | Ganzzahl |
| swarm health | `availability` | Float. Geht in `uploading (no peers)` auf **-1** |
| where the data is | `download_path` | null, bis die Daten vorhanden sind |

`8640000` sind 100 Tage. So zeigt TorBox an, dass es den Wert nicht kennt. Es ist außerdem dieselbe Konstante, die der Shim von zurg heute an Sonarr übergibt, wenn es nichts zu melden hat.

### Was jeder Fall gemacht hat {#what-each-case-did-2}

| Fall | Torrent | `checkcached` | Übergänge mit Sekunden ab Hinzufügen | Ergebnis |
|---|---|---|---|---|
| gecached | Big Buck Bunny | true | `cached`@0.0 | fertig in 0.83 s |
| gecached | Sintel | true | `cached`@0.0 | fertig in 0.94 s |
| gecached | Ubuntu 26.04.1 | true | `cached`@0.0 | fertig in 0.69 s |
| ungecached | Debian 13.6.0 arm64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@7.3 `downloading`@24.1 dann **weg**@48.6 | vom anderen zurg bei 86.7 % gelöscht |
| ungecached | Debian 13.2.0 amd64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@13.8 `downloading`@27.8 `processing`@69.4 `downloading`@72.7 `uploading (no peers)`@83.1 dann **weg**@86.7 | vom anderen zurg gelöscht |
| webseed | Prelinger home movie | false | `metaDL`@0.0 `checking`@23.3 und sonst nichts mehr | **bei 911.3 s in `checking` abgebrochen**. TorBox hat den Webseed nicht verwendet |
| seedlos | ubuntu-16.04.6-desktop-i386 | false | `metaDL`@0.0 `checking`@10.5 `downloading`@20.6 `processing`@184.4 dann **weg**@200.4 | vom anderen zurg bei `processing` gelöscht |
| seedlos | ubuntu-24.04-beta-live-server-s390x | false | `metaDL`@0.0 `checking`@18.9 `stalled (no seeds)`@169.3 `downloading`@230.9 dann **weg**@462.3 | vom anderen zurg bei 91.9 Prozent gelöscht |
| ohne Metadaten | zufällige 40-stellige Hex-Zahl | false | `metaDL`@0.0 `checking`@10.2 und sonst nichts mehr | **bei 910.3 s in `checking` abgebrochen** |

Ein separater Lauf mit einem Poll-Intervall von 0.5 s gegen Debian 13.5.0 amd64 netinst
(`58846860f0a766f8a42b0bb214d8c713fdf1b167`) hat lange genug durchgehalten, um fertig zu werden, und ist die Referenzsequenz.

| Sekunden | Status | `download_finished` | `download_present` | `progress` |
|---|---|---|---|---|
| 0.0 | `stalledDL` | false | false | 0.000289735 |
| 16.3 | `downloading` | false | false | 0.0608651 |
| 54.8 | `processing` | **true** | **false** | 1 |
| 59.1 | `downloading` | **true** | **false** | 0.997972 |
| 64.4 | `uploading` | true | **true** | 1 |

754 MiB in 64.4 s.

Lies die letzten drei Zeilen zweimal. TorBox setzt `download_finished` auf true und `progress` auf 1 etwa
zehn Sekunden **bevor** die Daten vorhanden sind. Danach fällt es zurück auf `downloading` mit einem Fortschrittswert, der niedriger ist als der gerade gemeldete. Sowohl `progress` als auch `download_state` springen bei einem gesunden Download rückwärts.

---

(Eine frühere Übersetzung wurde abgelehnt: Die Code-Spans stimmten nicht überein. Behalte die Struktur exakt bei.)

## Die Stage-Tabelle {#the-stage-table}

Das Stage-Enum, das der Shim sprechen wird, ist `resolving-metadata` `queued` `downloading` `stalled-no-peers`
`finalizing` `done` `failed` und der leere String für unbekannt.

### Real-Debrid

| Roher `status` | Stage | Basis |
|---|---|---|
| `magnet_conversion` | `resolving-metadata` | **beobachtet**. `bytes` 0 und `files` leer und `filename` ist der wörtliche Wert `"Magnet"` |
| `waiting_files_selection` | `queued` | **beobachtet** mit `--rd-select-detail`. Dateien sind bereits aufgelistet. `links` ist leer |
| `queued` | `queued` | **beobachtet**. Echte Größe und echter Name sind bereits bekannt. Kein `seeders` und kein `speed` |
| `downloading` | `downloading` | **beobachtet** |
| `downloading` mit `seeders` 0 | `stalled-no-peers` | **beobachtet**. 904 s mit `progress` 0 und `seeders` 0 und `speed` 0 über 92 Abfragen |
| `compressing` | `finalizing` | **abgeleitet**. Nicht gesehen |
| `uploading` | `finalizing` | **beobachtet**. Der Fortschritt beginnt wieder bei 0 und `seeders` verschwindet |
| `downloaded` | `done` | **beobachtet** |
| `magnet_error` | `failed` | **beobachtet** nach 318 s in `magnet_conversion` |
| `error` `virus` `dead` | `failed` | **abgeleitet**. Nicht gesehen |

### AllDebrid

| `statusCode` | Stage | Basis |
|---|---|---|
| 0 `In queue` | `queued` | **beobachtet**. Dauert ein paar Sekunden. `filename` kann noch `"noname"` sein und `size` 0 |
| 1 `Downloading` mit `size` 0 | `queued` | **beobachtet**. Nicht `downloading` und nicht `stalled-no-peers`. AllDebrid hat den Job angenommen und noch nicht gestartet. In zwei Durchläufen blieb er 622 s bzw. 580 s hängen und wurde danach fertig |
| 1 `Downloading` mit einer echten `size` | `downloading` | **beobachtet** |
| 1 `Downloading` mit `seeders` 0 und flachem `downloaded` | `stalled-no-peers` | **nicht beobachtet und nicht sicher ableitbar**. Siehe unten |
| 2 `Compressing / Moving` | `finalizing` | **abgeleitet**. Nicht gesehen |
| 3 `Uploading` | `finalizing` | **beobachtet**. `uploaded` und `uploadSpeed` zeigen hier den Fortschritt, und `downloadSpeed` ist 0 |
| 4 `Ready` | `done` | **beobachtet** |
| 5 und höher | `failed` | **abgeleitet**. Nicht gesehen |

**AllDebrid hat kein beobachtbares Stall-Muster.** Ein Job, den AllDebrid in die Warteschlange gestellt hat, und ein Job, bei dem AllDebrid nicht vorankommt, sehen auf der Leitung identisch aus. Beide haben `statusCode` 1 mit `size` 0 und allen Zählern auf null. Der Prelinger-Eintrag saß genau in diesem Zustand die volle 907.8-s-Obergrenze lang, und zwei andere Torrents hingen zehn Minuten lang so fest und waren danach fertig. Die AllDebrid-Antwort verrät also nicht, welcher der beiden Fälle vorliegt. Ein Stall-Urteil bei AllDebrid kann deshalb nur aus einer Uhr stammen.

### TorBox

Diese Tabelle übersetzen wir nicht vollständig, weil die Zeilen unten ein paar Punkte enthalten, die ich unverändert lassen muss. Hier die Übersetzung:

| Roher `download_state` | Stufe | Grundlage |
|---|---|---|
| `metaDL` | `resolving-metadata` | **beobachtet**. `size` 0 und `name` gleich dem Hash |
| `checking` | `resolving-metadata` | **beobachtet**. `size` **-1**, solange der Zustand anhält. Hier wartet TorBox auf den Torrent und nicht auf eine Hash-Prüfung. Steht heute nicht in zurgs Tabelle |
| `stalledDL` | `stalled-no-peers` | **beobachtet**. Steht heute nicht in zurgs Tabelle |
| `stalled (no seeds)` | `stalled-no-peers` | **beobachtet**. Der Name übertreibt. Zwei Aufnahmen hatten im selben Zustand `seeds` 1 und 2. zurg ordnet ihn heute `queued` zu |
| `downloading` | `downloading` | **beobachtet** |
| `processing` | `finalizing` | **beobachtet**. Steht heute nicht in zurgs Tabelle |
| `uploading (no peers)` | `finalizing` | **beobachtet**, wenn `download_present` false ist |
| `uploading` | `done` | **beobachtet**, wenn `download_present` true ist |
| `cached` `completed` `seeding` | `done` | `cached` **beobachtet**. Die anderen beiden **abgeleitet** |
| `expired` `reported missing` `failed` `error` `missingfiles` | `failed` | **abgeleitet**. Keiner gesehen |

**Das Paar `download_finished` und `download_present` ersetzt den Zustandsstring nicht.** Sowohl `processing` als auch `uploading (no peers)` und ein Teil von `downloading` haben `download_finished: true` mit `download_present: false`. Diese Kombination ist eine normale Finalisierungsphase und kein toter Torrent. Siehe den Hinweis unten.

---

## Was sich nicht messen ließ {#what-could-not-be-measured}

- **Der Fall ohne Seeder ließ sich bei einem von zwei Kandidaten reproduzieren.** Beide hatten null Tracker-Peers.
  ubuntu-16.04.6-desktop-i386 wurde trotzdem bei allen drei Anbietern heruntergeladen, weil DHT Peers lieferte, die der
  Tracker nicht kannte. ubuntu-24.04-beta-live-server-s390x blieb bei Real-Debrid für die volle
  Obergrenze hängen, und das ist die Hänger-Beobachtung von oben. Eine Null bei einer Tracker-Abfrage ist ein schwacher Hinweis. Behalte zwei
  Kandidaten im Fall. Real-Debrid hatte die Metadaten für beide in jedem Fall und meldete `bytes` und
  `filename` schon beim allerersten `queued`-Abruf korrekt.
- **Real-Debrid `compressing` wurde nie beobachtet.** Jeder abgeschlossene Lauf ging von `downloading` direkt zu
  `uploading`.
- **AllDebrid-Statuscode 2 wurde nie beobachtet.** Jede Aufnahme ging von 1 direkt zu 3.
- **Kein Anbieter wurde in seine eigenen Fehlerzustände gedrängt.** Real-Debrid `error`, `virus` und
  `dead` sowie jeder AllDebrid-Code über 4 und jeder TorBox-Fehlerzustand sind alle nicht gemessen.
  Um sie auszulösen, braucht man Inhalte, die gesperrt, infiziert oder abgelaufen sind, und nicht ein FOSS-ISO.
- **TorBox ließ sich selten bis zum Ende verfolgen.** Vier Kampagnen-Torrents und ein Folgetest wurden mitten im Download von der
  anderen zurg auf dem Konto gelöscht. Siehe die Gefahr unten. Nur ein 754 MiB großes Image wurde fertig, bevor
  dieser Prozess das nächste Mal abfragte.

---

## Gefahren, die wir unterwegs gefunden haben {#hazards-found-on-the-way}

### Ein zweites zurg auf dem TorBox-Konto löscht gesunde Downloads {#a-second-zurg-on-the-torbox-account-deletes-healthy-downloads}

Eine andere zurg-Instanz wurde mit demselben TorBox-Konto geladen. Ihre Config lautet

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

**Fünf** Test-Torrents wurden gelöscht, obwohl sie normal heruntergeladen wurden. Das ist auf beiden Seiten **beobachtet**. Der Testaufbau hat gesehen, wie jeder Torrent verschwand, und das Journal der anderen Instanz nennt den Grund.

```
Aug 30 12:43:26 zurg-host zurg: INFO manager Deleting torrent 86695315 because it encountered an error status: error
Aug 30 12:43:27 zurg-host zurg: DEBUG torbox Deleted TorBox torrent id=86695315
Aug 30 12:44:56 zurg-host zurg: INFO manager Deleting torrent 86695708 because it encountered an error status: error
Aug 30 12:47:41 zurg-host zurg: INFO manager Deleting torrent 86697191 because it encountered an error status: error
```

Die fünf sind `86695315` `86695708` `86697191` `86702627` `86704212`. Alle trugen denselben Grund. Keiner war defekt.

Der Mechanismus ist die zweite Regel in `normalizeStatus` in `internal/torbox/types.go`.

```go
if w.DownloadFinished && !w.DownloadPresent {
    return "error"
}
```

Diese Kombination ist eine normale Abschlussphase bei TorBox. Die Messung mit 0.5 s zeigt, wie lang sie dauert. Bei einem 754 MiB großen Image lag das Zeitfenster von `download_finished` auf true bis `download_present` auf true bei **9.6 Sekunden**. Bei einem 3.7 GiB großen Image waren es mindestens 17 s, und der Aufräumlauf fiel genau hinein. Die andere zurg fragt die Bibliothek etwa alle 15 s ab. Ob ein gesunder TorBox-Download seine eigene Fertigstellung übersteht, ist fast wie ein Münzwurf.

Drei Folgen. Ein TorBox-Download, den ein Nutzer in der TorBox-Oberfläche fertig werden sieht, kann aus seiner zurg-Bibliothek verschwunden sein. `delete_error_torrents` ist dokumentiert als Löschen von Torrents, die der Anbieter als defekt meldet, und hier löscht es welche, die der Anbieter als in Ordnung meldet. Und jede Messung bei TorBox auf diesem Konto läuft gegen diesen Aufräumlauf um die Wette.

**Hier nicht behoben.** Phase 0 misst nur. Die Korrektur gehört zur Arbeit an den Stufen. Dort wird aus `download_finished && !download_present` der Status `finalizing` statt `failed`.

### Ein zweites zurg auf dem AllDebrid-Konto ist glimpflich davongekommen {#a-second-zurg-on-the-alldebrid-account-got-away-with-it}

Der AllDebrid-Schlüssel, den diese Kampagne benutzt hat, wurde auch von einer anderen zurg-Instanz geladen, mit denselben drei Sweep-Einstellungen wie beim TorBox-Schlüssel.

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

Keine AllDebrid-Probe wurde gelöscht. Der Grund steht im Code, nicht im Zufall. `normalizeStatus` in `internal/alldebrid/types.go` ordnet nur Statuscodes ab 5 aufwärts dem Status `error` zu und hat keine strukturelle Regel vom Typ `download_finished && !download_present`. Ein gesunder AllDebrid-Download kann also nie als kaputt gelesen werden. Der TorBox-Fehler ist diese eine zusätzliche Regel und nicht das Aufräumen an sich.

Real-Debrid ist der Sonderfall. Keine andere zurg-Instanz war mit dem Testaccount geladen. Niemand hat es aufgeräumt, und nichts hat eingegriffen.

### TorBox antwortet auf ein Löschen einer unbekannten ID mit HTTP 500 {#torbox-answers-a-delete-for-an-unknown-id-with-http-500}

```
POST /v1/api/torrents/controltorrent  {"torrent_id":86695315,"operation":"delete"}
-> HTTP 500 {"success":false,"error":"DATABASE_ERROR","detail":"There was an error processing your request. Please try again later."}
```

`GET /torrents/mylist?id=<gone>` antwortet genauso. Ein Torrent, der nicht mehr existiert, lässt sich anhand des Statuscodes allein also nicht von einem TorBox-Ausfall unterscheiden. zurg meldet das als `account temporarily unavailable`. Das Journal der anderen Instanz zeigt, dass sie das Löschen einer bereits gelöschten ID alle 15 s wiederholt. Der Harness umgeht das, indem er nach einem fehlgeschlagenen Löschen `mylist` abfragt und einen nicht mehr vorhandenen Torrent als gelöscht behandelt.

### Real-Debrid-Drosselung ist nicht aufgetreten {#real-debrid-throttling-did-not-appear}

Neun Adds mit 20 s Abstand ergaben über die gesamte Kampagne null 451 und null 429. Das passt zu der Notiz in der `CLAUDE.md` im Hauptverzeichnis, dass 6 Adds mit 10 s Abstand 0/6 ergaben und dieselben 6 mit 20 s 6/6. Der 20-s-Mindestabstand bringt also echten Nutzen und ist kein Aberglaube.

## Die Messkampagne erneut ausführen {#re-running-the-campaign}

```bash
export RD_TOKEN=…   # a Real-Debrid test account
export AD_KEY=…     # AllDebrid test
export TB_KEY=…     # TorBox

# 1. check the catalog still resolves and the swarms are still what the tables claim
./scripts/torrent_lifecycle_probe.py --inspect-torrents

# 2. non-destructive. Confirms the cached/uncached split before anything is added
./scripts/torrent_lifecycle_probe.py --cache-probe

# 3. record what each account holds now, so step 6 has something to compare against
./scripts/torrent_lifecycle_probe.py --list

# 4. the campaign. One process per provider, each with its own output directory
for p in rd ad tb; do
  LIFECYCLE_OUTDIR=~/lifecycle/$p ./scripts/torrent_lifecycle_probe.py \
    --provider $p --case all --cap-mins 15 > ~/lifecycle/$p.out 2>&1 &
done

# 5. the two follow-ups the campaign cannot do
./scripts/torrent_lifecycle_probe.py --provider rd --case cached --rd-select-detail
./scripts/torrent_lifecycle_probe.py --provider tb --case adhoc --fast-poll 0.5 --fast-window 480 \
  --extra-hash 58846860f0a766f8a42b0bb214d8c713fdf1b167:debian-netinst

# 6. verify nothing was left behind
./scripts/torrent_lifecycle_probe.py --cleanup-only
./scripts/torrent_lifecycle_probe.py --list
```

Führe es von einem Rechner mit Heim-Internetanschluss aus. AllDebrid antwortet `NO_SERVER` auf IPs aus Rechenzentren.

Schritt 6 ist nicht optional, und Schritt 3 ist das, was ihn sinnvoll macht. Nach der Kampagne vom 2026-08-30 war
keine einzige der 34 Instanz-IDs, die das Test-Harness beansprucht hatte, mehr auf einem der drei Konten übrig. Auch keiner der neun Probe-Hashes.

Bevor du TorBox anfasst, prüfe, ob eine andere zurg mit demselben Konto geladen ist. Lies deren Sweep-Einstellungen und erwarte den oben beschriebenen Sweep.

```bash
grep -E "delete_error_torrents|stalled_download_mins|enable_repair" config.yml
```

Ändere es nie. Ein Probe, das mitten im Lauf verschwindet, ist eine Information.
