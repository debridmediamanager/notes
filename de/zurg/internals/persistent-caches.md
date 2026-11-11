# Persistente Lese-Caches {#persistent-read-caches}

Importierte NZBs sowie Einträge von Real-Debrid, AllDebrid und TorBox behalten ihren Bibliothekszustand in `data/*.zurgtorrent`. Diese Dateien beschreiben die Bibliothek. Vorbereitungs- und Byte-Caches zum Lesen liegen direkt daneben, sodass das Ändern oder Entfernen eines abgeleiteten Caches die Bibliothek nicht neu schreibt und keine Tags, Namen oder Kontozuordnungen verloren gehen.

## Was einen Neustart übersteht {#what-survives-a-restart}

| Cache | Speicherort | Vermiedene Arbeit |
| --- | --- | --- |
| NZB-Dokument-Manifeste | `data/nzb-manifests/` | Unverändertes XML für Namen, Größen, Wiederherstellungs-Klassifizierung, Passwörter und Segmentanzahl erneut parsen |
| NZB-Artikelindizes | `data/nzb-index/` | Artikelreferenzen neu aufbauen; wird von den Modi `mmap` und `resident` genutzt |
| Dekodierte Usenet-Artikel | `data/bytecache/articles/` | Einen bereits gelesenen Artikel erneut abrufen und yEnc-dekodieren |
| Archiv-Layouts | `data/archive-layouts/` | Archiv-Header erneut lesen, um Volume-Spans, verschachtelte Einträge und gelernte ZIP-Offsets neu aufzubauen |
| Dekomprimierte Archivblöcke | `data/bytecache/decoded/` | Erneut dekodieren, um gespeicherte Byte-Bereiche nach einem Neustart oder Rückwärts-Seek zu erreichen |
| Provider-Status | `data/provider-cache/` | Ein unverändertes RD-Download-Fenster neu aufbauen oder eine neue TorBox-Regionstabelle abrufen |
| Download-Links | `data/linkcache/` | Eine noch gültige URL erneut auflösen |

Archiv-Layouts unterstützen gespeicherte und komprimierte RAR/ZIP-Einträge, verschachtelte Quellen,
verschlüsselte Spans und unterstützte geteilte Archive. Sie enthalten Quellreferenzen und Offsets, keine
laufenden HTTP-Reader. Aktuelle Provider-URLs werden beim Wiederherstellen angehängt.
Unvollständige Layouts mit fehlenden Volumes werden aus der Quelle neu aufgebaut. Gelernte ZIP-
Payload-Offsets werden nach dem ersten Lesen gespeichert, ohne bei einer Verzeichnisauflistung für jeden
Eintrag sofort einen Header abzurufen.

NZB-Manifeste werden anhand der Größe der Quelldatei, der Änderungszeit in Nanosekunden und der
Parser-Version geprüft. `mmap` stellt die Metadaten sofort wieder her und mappt den Artikelindex erst, wenn er
gebraucht wird. `resident` lädt diesen Index in den Heap-Speicher. `reparse` stellt die Metadaten zwar sofort
wieder her, parst das XML aber trotzdem erneut, wenn Artikelreferenzen benötigt werden.
Bestehende Bibliotheken erstellen ihre Manifeste beim ersten Scan mit dieser Version;
das Speichern beim Start greift bei den folgenden Scans und Neustarts.

Gleichzeitige Anfragen von AllDebrid und TorBox für dieselbe, noch nicht gecachte Datei eines Accounts
werden jetzt zu einer einzigen Auflösung zusammengefasst. Wenn ein Aufrufer abbricht, wird die Auflösung
eines anderen Aufrufers nicht abgebrochen. RD behält seine bestehende Zusammenfassung bei. TorBox nutzt
beim Auflösen einer Datei die bekannten Katalognamen und Größen, anstatt diese Details erneut abzurufen.

Provider-Detaildatensätze in `data/info/` werden nach dem ersten JSON-Dekodieren pro Prozess zwischengespeichert.
Bei jeder Wiederverwendung werden Dateiidentität, Größe und Änderungszeit geprüft, und es wird eine
unabhängige Kopie zurückgegeben. Bibliotheks- und Detaildateien werden atomar ersetzt.

## Speicherbudgets {#storage-budgets}

Diese optionalen Einstellungen auf oberster Ebene werden in MiB gemessen und greifen erst nach einem Neustart:

```yaml
nzb_article_disk_cache_mb: 512
archive_decoded_disk_cache_mb: 512
```

Jeder Cache ist standardmäßig auf 512 MiB für die gesamte Instanz eingestellt. Null deaktiviert den jeweiligen Cache, negative Werte werden wie null behandelt. Die Budgets zählen die Datensatzbytes inklusive Prüfsummen und nicht den Overhead der Dateisystem-Allokation. Die ältesten ungenutzten Datensätze fliegen raus, sobald neue Datensätze ankommen. Wenn du ein Budget verkleinerst, wird der bestehende Cache beim Start gekürzt. Schaltest du einen Cache aus, bleiben vorhandene Dateien erhalten, du kannst sie also selbst löschen.

Der Artikel-Cache ergänzt den bestehenden RAM-Cache. Der Archiv-Cache hält 64 KiB große dekodierte Blöcke vor und ergänzt das 64 MiB große gleitende RAM-Fenster jedes Decoders. Keiner der beiden Caches lädt die Bibliothek im Voraus herunter. Ein Lesezugriff außerhalb der gespeicherten dekodierten Blöcke muss trotzdem vom Anfang eines komprimierten Eintrags aus dekodiert werden. Rclones VFS-Cache ist davon getrennt und liefert weiterhin vollständig gecachte Bereiche aus, ohne diese Pfade zu nutzen. Diese Caches helfen auch bei direkten HTTP/WebDAV-Zugriffen.

Ein komprimierter Eintrag kann nur vom Anfang aus dekodiert werden. Ein Lesezugriff weit hinten in einem Eintrag bedeutet also, dass zuerst das ganze Archiv geladen wird. zurg hält so einen Zugriff 20 Sekunden lang offen und antwortet danach mit `503`, statt den Client ohne Antwort zu lassen. Was der Decoder bis dahin erreicht hat, bleibt erhalten. Ein Player, der einen Vorwärts-Seek wiederholt, kommt dadurch jedes Mal ein Stück weiter. Ein Zugriff nahe dem Ende eines Eintrags, der abgelehnt wird, startet außerdem eine einzige Hintergrund-Dekodierung dieses Eintrags, immer einen Eintrag nach dem anderen. Dabei werden die letzten 8 MiB des Eintrags in `data/bytecache/decoded-tails/` gespeichert. Danach wird das Dateiende sofort gelesen, was ein Medienserver braucht, wenn er eine Datei analysiert. Dieser Speicher nutzt wieder dasselbe Budget wie `archive_decoded_disk_cache_mb` und wird zusammen mit diesem abgeschaltet.

Abgeleitete Metadaten wachsen mit der Bibliothek und zählen nicht zu diesen Bytebudgets. NZB-Scans entfernen Manifeste und Artikelindizes für gelöschte Dokumente. Veraltete Revisionen des Archiv-Layouts können bei gestoppter Instanz entfernt werden. Sie sind wegwerfbar und werden bei Bedarf neu erstellt.

## Validierung und Wiederherstellung {#validation-and-recovery}

Neue Metadaten-Einträge und Byte-Blobs bekommen Prüfsummen. Beschädigte Einträge und fehlgeschlagene Cache-Schreibvorgänge greifen auf die Quelle zurück. Artikel-Einträge landen nur dann im Disk-Cache, wenn der Abruf vollständig erfolgreich war. Geschrieben werden sie erst, nachdem der Artikel an den Lesevorgang übergeben wurde, der ihn abgerufen hat. So wartet ein Lesevorgang nie auf den Cache. Kommen mehr Artikel-Schreibvorgänge auf einmal an, als gleichzeitig laufen dürfen, werden die überzähligen Einträge verworfen, statt einen Lesevorgang aufzuhalten. Ein verworfener Eintrag wird beim nächsten Bedarf erneut abgerufen. Die Identität eines Artikels umfasst die NZB-Revision, die Server-Konfiguration, Datei und Segment. Die Identität eines Archivs umfasst die aktuellen Quellverweise, Größen, Kontokonfiguration, Passwort und Format-Version. Ein Austausch der NZB-Quelle macht auch Archiv-Layouts und dekodierte Bytes ungültig.

Der lokale Quell-Fingerabdruck geht davon aus, dass sich bei einem Austausch Größe oder Änderungszeit ändern. Absichtlich wird nicht bei jedem Start das gesamte XML gehasht. Wenn bei einem Austausch beides gleich bleibt, müssen die zugehörigen abgeleiteten Caches entfernt werden.

RD-Snapshots werden nur akzeptiert, wenn Token und konfiguriertes Download-Limit gleich sind, sie nicht älter als eine Stunde sind und ein Live-Probe den neuesten Eintrag und die Gesamtanzahl bestätigt. Ändert sich die Liste, wird ein vollständiger Abgleich ausgelöst. TorBox-Regionstabellen behalten ihre bisherige Lebensdauer von sechs Stunden. Die Lebensdauer von Delivery-URLs und die Fehlerbehandlung der Anbieter bleiben unverändert: Ein warmes Layout öffnet seine Nutzlast, bevor es HTTP-Erfolg festschreibt. So kann eine widerrufene URL den normalen Pfad für Auflösung und Wiederholung nehmen.

Änderungen an Delivery-Links lösen etwa eine Sekunde später einen zusammengefassten Disk-Flush aus. Der Wiederholungsversuch nach fünf Minuten und der Flush beim Herunterfahren bleiben bestehen. Das atomare Ersetzen verhindert, dass Leser halb geschriebene Einträge sehen. Es ist aber keine fsync-Garantie gegen Stromausfall. Neue Cache-Dateien bekommen unter Unix den Modus `0600`, weil Links und verschlüsselte Archiv-Layouts Zugangsdaten oder abgeleitete Schlüssel enthalten können. Unter Windows werden stattdessen die ACLs des übergeordneten Verzeichnisses verwendet, statt Unix-Berechtigungsbits.

## Backups mit warmen Caches {#backups-with-warm-caches}

Das Standard-Backup speichert weiterhin den maßgeblichen Zustand. Um auch die abgeleiteten Caches und den instanzlokalen rclone-VFS-Cache mitzunehmen:

```sh
./zurg backup --include-caches --out warm.zurgbackup
```

Das kann deutlich größer sein als ein Standard-Backup. Es enthält die oben aufgelisteten Wurzelverzeichnisse, die NZB-Namens-, Größen- und PAR2-Caches sowie den Status der Netzwerktests. Logs und Plex-Datenbank-Snapshots bleiben ausgeschlossen. Rclone-Caches außerhalb von `data/rclone-cache/` sind nicht enthalten. Stoppe die Instanz, wenn ein konsistenter Snapshot der aktiven Caches wichtig ist.

Stell das Backup wieder her, während die Instanz gestoppt ist, mit `./zurg restore-backup warm.zurgbackup`.
Backups behalten die Quell-Zeitstempel in Nanosekunden, damit unveränderte NZBs ihre Indizes und Manifeste behalten können. Wiederhergestellte Caches durchlaufen trotzdem die normalen Prüfungen zur Validierung und zum Ablauf. Backups enthalten die Tokens und zwischengespeicherten Zugangsdaten aus der Config.

## Reproduzierbare Prüfungen {#reproducible-checks}

`BenchmarkParsedDocumentStartup` vergleicht das XML-Parsing mit jedem Manifest-Wiederherstellungsmodus, bei 60 Dateien und 30.000 Segmenten. `BenchmarkDetailJSONRefresh` vergleicht den JSON-Lesepfad mit gememoiztem Zugriff für einen Datensatz mit 1.000 Dateien. Beide sind lokale Benchmarks auf einem warmen Dateisystem, keine End-to-End-Messungen des Starts in der Produktion.

Gemessen auf einem Apple M3 Pro mit drei Läufen à 500 ms am 2026-09-05 (Median pro Operation):

| Operation | Zeit | Allokierte Bytes |
| --- | ---: | ---: |
| NZB-XML parsen | 43.49 ms | 20.27 MB |
| Metadaten im `mmap`-Modus wiederherstellen | 0.224 ms | 59 KB |
| Metadaten und residenten Artikelindex wiederherstellen | 0.577 ms | 1.79 MB |
| Metadaten im `reparse`-Modus wiederherstellen | 0.199 ms | 59 KB |
| Provider-Detaildatensatz lesen/dekodieren | 0.538 ms | 784 KB |
| Detaildatensatz mit stat-Check und Kopie wiederverwenden | 0.0084 ms | 59 KB |

Der Detail-Decode-Fall leert den neuen Memo-Cache vor jedem Aufruf und enthält daher auch die Kosten für das Befüllen. Diese Werte vergleichen die beiden aktuellen Zugriffspfade. Sie schätzen keine Netzwerklatenz und rechnen keine Startzeit für die ganze Bibliothek hoch.

Die Regressionstests decken Neustart-Wiederverwendung, Korruption, Quelländerungen, Kontotrennung, gleichzeitige Auflösung, Byte-Identität am Anfang, in der Mitte und am Ende, Rückwärts-Seeks über das RAM-Fenster hinaus und den Widerruf von URLs nach der Wiederherstellung des Layouts ab.

```sh
go test ./...
go test -race ./internal/debrid ./internal/nzb ./internal/rarstream ./internal/universal ./pkg/cachefile ./pkg/diskcache
go test ./internal/nzb ./internal/torrent -run '^$' -bench 'Benchmark(ParsedDocumentStartup|DetailJSONRefresh)$' -benchmem
make integration-test
```

Das Integrationsziel braucht seine dokumentierten Live-Testkonten und Host-Abhängigkeiten. Ein übersprungenes Integrationsskript verifiziert keine Cache-Änderung.
