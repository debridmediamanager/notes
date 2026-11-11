# E2E-Tests {#e2e-testing}

Ende-zu-Ende-Tests, um zu prüfen, ob zurg nach der Bereitstellung korrekt funktioniert.

## Plex-Wiedergabetest {#plex-playback-test}

Überprüft, ob Inhalte tatsächlich über Plex abspielbar sind, indem ein zufälliger Film ausgewählt und die gesamte Wiedergabe-Kette getestet wird.

### Test ausführen {#run-the-test}

```bash
./scripts/plex-e2e-test.sh
```

Das Skript liest `plex_server_url` und `plex_token` automatisch aus `config.yml`.

Um das mit eigenen Einstellungen zu überschreiben:
```bash
PLEX_URL="http://your-plex:32400" PLEX_TOKEN="your-token" ./scripts/plex-e2e-test.sh
```

### Was getestet wird {#what-it-tests}

| Schritt | Beschreibung |
|---------|--------------|
| 1 | Movies-Bibliothek über die Plex API finden |
| 2 | Gesamtzahl der Filme abrufen |
| 3 | Zufälligen Film auswählen |
| 4 | Stream-URL für den Film abrufen |
| 5 | Prüfen, ob der Stream erreichbar ist (HTTP 200) |
| 6 | 3 Sekunden Video mit ffmpeg dekodieren |
| 7 | Plex-Session-Tracking erstellen und prüfen |

### Erwartete Ausgabe {#expected-output}

```
=== Plex E2E Playback Test ===

[1/7] Finding Movies library...
  Library key: 15
[2/7] Getting movie count...
  Total movies: 1234
[3/7] Selecting random movie...
  Selected: 2 Fast 2 Furious (2003) (ratingKey: 756524)
[4/7] Getting stream URL...
  File size: 54GiB
[5/7] Verifying stream accessibility...
  HTTP Status: 200 OK
[6/7] Decoding video (3 seconds)...
  Decoded 72 frames successfully
[7/7] Testing Plex session tracking...
  Session created and tracked

=== TEST PASSED ===
Movie '2 Fast 2 Furious (2003)' is playable via Plex
```

### Voraussetzungen {#prerequisites}

- Plex-Server läuft und ist erreichbar
- `plex_server_url` und `plex_token` sind in `config.yml` konfiguriert
- `curl`, `jq` und `ffmpeg` sind installiert

### Fehlerbehebung {#troubleshooting}

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| No movie library found | Falscher Bibliothekstyp oder leer | Prüfe, ob Plex eine Bibliothek „Movies“ hat |
| Stream not accessible (HTTP 4xx) | Auth- oder Pfadproblem | Prüfe den Token und ob die Datei existiert |
| Failed to decode video frames | Beschädigte Datei oder Netzwerkproblem | Prüfe die zurg-Logs und probiere einen anderen Film |
| Session not detected | Plex-Sitzung abgelaufen | Prüfe die Plex-Logs |

## Integrationssuite {#integration-suite}

```bash
ssh zen
cd /path/to/isolated/zurg/source
make integration-test
```

**Führe es auf einem isolierten Ziel auf `zen` aus.** Installiere dort eine Go-Toolchain, shellcheck, rclone und die .NET-Move-Probe. Die Suite erstellt ihre eigenen zurg-Prozesse und Mounts; sie erfordert nicht, dass der normale zurg-Dienst oder Mount auf zen ersetzt wird. Verwende ein separates Quellverzeichnis, `TMPDIR`, eine eigene Konfiguration, einen eigenen Port und `MOUNT_PATH`. Prüfe die Scratch-Konfiguration, bevor du sie ausführst, und behalte `INTEGRATION_LOCK_FILE=/tmp/zurg-integration-rd.lock` auch bei einem privaten `TMPDIR` bei, damit andere Sitzungen weiterhin mit deiner serialisiert werden.

Tests, deren Voraussetzungen fehlen, können mit einem erfolgreichen Exit-Code überspringen. Lies ihre Ausgabe, um zu prüfen, dass FUSE, rclone, Plex und NNTP wirklich gelaufen sind.

| Test | Braucht FUSE | Braucht Plex | Braucht ein Usenet-Konto |
|------|:----------:|:----------:|:----------------------:|
| `refresh_repair_integration.sh` | | | |
| `network_test_cache_integration.sh` | | | |
| `rclone_mount_integration.sh` | ja | | |
| `magic_mount_integration.sh` | ja | | |
| `magic_move_refusal.sh` | ja | | |
| `magic_library_move_integration.sh` | ja | | |
| `plex_integration.sh` | ja | ja | |
| `nzb_bench_integration.sh` | | | ja |

`force_location_integration.sh` ist **nicht** Teil der Suite. Es prüft etwas über den Netzwerkpfad dieses Hosts zu Real-Debrids CDN und nicht über zurg. Deshalb schlägt es dort fehl, wo dieser Pfad nicht antworten kann, unabhängig von der getesteten Änderung. Führe es bewusst mit `make force-location-test` aus, auf einem Host mit funktionierendem IPv4 zur erzwungenen Region. Siehe [Force-Location-Integrationstest](#force-location-integration-test).

Die fünf Tests, die Real-Debrid nutzen, greifen auf dasselbe Konto zu. Siehe [das Konto wird geteilt](#the-real-debrid-test-account-is-shared). Der Benchmark nutzt stattdessen ein Newsserver-Konto und berührt Real-Debrid überhaupt nicht. Er nimmt aber dieselbe hostweite Sperre wie der Rest: Ein Lauf, der neben den Lesevorgängen einer anderen Suite gemessen wird, misst am Ende die andere Suite.

Der Mount-Test läuft auch auf einem Mac, wenn macFUSE installiert ist. Er wurde auf macFUSE und auf Linux `fusermount` verifiziert. Der Plex-Test braucht `plex_server_url` und `plex_token` in seiner Scratch-Konfiguration, und Plex muss jedes übergeordnete Verzeichnis des Scratch-Mounts durchqueren können. Ein Mount unter einem privaten Home-Verzeichnis kann für den Testbenutzer funktionieren, während er für Plex unzugänglich bleibt.

`make integration-test` baut zurg, führt shellcheck über die Skripte aus, den Selbsttest von `lib.sh` und die Unit-Tests von `integration/nzbbench`. Danach startet es alle sieben, vom billigsten zum teuersten: Netzwerk-Testcache, rclone-Mount, Plex, `__magic__`-Mount, .NET-Move-Verweigerung, Refresh/Repair und zuletzt den Usenet-Benchmark. Die letzten beiden sind die teuersten. Refresh/Repair wartet einen vollständigen Bibliotheks-Scan ab, und der Benchmark liest zweimal Gigabytes von einem Newsserver. Deshalb soll ein Fehler in einem der anderen Tests nicht erst nach diesem Warten auffallen.
`make integration-test-media` führt die rclone-, Plex- und `__magic__`-Mount-Tests aus, und `make nzb-bench-test` nur den Benchmark.

Jedes Skript besitzt ein Arbeitsverzeichnis unter `$TMPDIR`, seinen eigenen Port und schreibt dort das zurg-Log. Die Suite läuft mit `STREAM_LOGS=false`, daher erreichen nur die eigenen Assertions des Tests das Terminal. Setze `STREAM_LOGS=true`, um zurgs Log auf stderr beim Debuggen zu verfolgen.

Gemeinsame Hilfsfunktionen liegen in `integration/lib.sh` (Prozesssteuerung, die Real-Debrid-API, Abfragen der Bibliothek auf dem Datenträger) und `integration/lib_media.sh` (FUSE und Plex). Füge einen neuen Test hinzu, indem du sie einbindest, statt ein anderes Skript zu kopieren. `integration/lib_test.sh` deckt die Hilfsfunktionen selbst ab: kein Konto, kein Netzwerk, etwa eine Sekunde. `integration/nzb_bench_timing_gate_test.sh` deckt ab, wie der Benchmark-Wrapper den Exit-Code des Tools in das Vokabular der Suite übersetzt. Es läuft auf einem gekürzten echten Bericht aus `integration/testdata/`. Beide laufen unter `make test-integration-lib`.

### Das Real-Debrid-Testkonto wird gemeinsam genutzt {#the-real-debrid-test-account-is-shared}

Die Suite steuert einen Real-Debrid-Testaccount, und dieser Account ist nicht privat.
Die produktive zurg-Instanz von `zen` beobachtet dieselbe Bibliothek. Sie listet und aktualisiert deshalb genau die Torrents, die ein Test gerade hinzugefügt hat. Jede Instanz auf dem Account **mit aktiviertem Repair** prüft, repariert und räumt sie außerdem auf.

Beide Fehler unten wurden am 2026-08-23 diagnostiziert, als die zurg-Instanz von `macmini` auf diesem Account mit Repair alle 10 Minuten lief. Diese Instanz wurde am 2026-08-29 gestoppt, und niemand überwacht sie. Die Läufe von zen nutzen `enable_repair: false`. Seit dem 2026-09-01 hat deshalb keiner der beiden Fehler noch eine aktive Ursache. Sie kommen sofort zurück, sobald Repair irgendwo auf diesem Account eingeschaltet wird. Deshalb gilt die Serialisierung unten weiterhin.

Was das für einen Lauf bedeutet, nachdem vier der sechs Skripte sowohl mit dem getesteten Build *als auch* mit seiner Baseline fehlschlugen:

- **Ein Fixture, das nie auftaucht.** Real-Debrid dedupliziert Download-IDs pro Link. Wenn du einen Downloads-Eintrag löschst, wird der Code für alle widerrufen, die ihn halten.
  Das Cleanup einer anderen Instanz widerruft den Code, den dieser Lauf gerade aufgelöst hat. Die Verifikation dieses Laufs antwortet mit `404 invalid_download_code`, und zurg markiert die Datei als defekt. Ein defekter Torrent wird in jeder Auflistung versteckt. Der Test meldet dann `zurg serves the fixture over HTTP but it never appeared under .../mnt/movies within 180s`. Das klingt nach einem Mount- oder dircache-Fehler, ist aber keins von beidem.
- **Ein Löschvorgang, der rückgängig gemacht wird.** Eine reparierende Instanz fügt einen Torrent wieder hinzu, den dieser Lauf gerade gelöscht hat. Deshalb schlägt `refresh never dropped <hash> after it was deleted from the account` fehl, obwohl die Bibliothek den Zustand korrekt meldet.

Vor allem Delete- und Repair-Assertions leiden darunter. Bevor du eine Änderung verantwortlich machst, lies den Fehlerkontext weiter unten. Und wenn ein Lauf sauber sein muss, stoppe zuerst das Repair der anderen Instanzen.

**Nie dürfen zwei dieser Skripte gleichzeitig laufen**, weder auf diesem Host noch aus einer anderen Sitzung auf ihm. Sie teilen sich das minütliche API-Budget des Accounts. Ein Paar bekommt daher `API rate limit (code=34)`, und Assertions schlagen wegen des Traffics fehl statt wegen des Verhaltens (gemessen auf `fun` mit zwei parallelen Läufen). Außerdem löscht jedes Skript Torrents *anhand des Hashes*. Das Cleanup des einen Laufs löscht daher bereitwillig das Fixture des anderen. Deshalb nimmt jedes Skript eine hostweite Sperre am Anfang von `main`, vor dem ersten API-Aufruf, und hält sie bis zum Beenden.

| Variable | Standard | Beschreibung |
|----------|---------|-------------|
| `INTEGRATION_LOCK_FILE` | `$TMPDIR/zurg-integration-rd.lock` | Die Sperre. `flock`, wo vorhanden, sonst ein pid-markiertes `.d`-Verzeichnis (macOS liefert kein `flock` mit) |
| `INTEGRATION_LOCK_WAIT` | `0` | Sekunden, die auf einen laufenden Lauf gewartet wird. `0` lehnt sofort ab, und das willst du auch – die Alternative wäre, eine Stunde hinter einem kalten Scan zu warten |

Eine Sperre, die von einem abgebrochenen Lauf übrig blieb, wird automatisch freigegeben. Das Verzeichnis enthält die pid des Halters, und `flock` gibt der Kernel selbst frei. Die Sperre sagt zen oder macmini natürlich nichts. Sie hält nur die Läufe dieses Hosts voneinander getrennt.

**Eine Fehlermeldung lesen.** Jedes `fail` gibt jetzt aus dem zurg-Log dieses Laufs Folgendes aus: die Anzahl jedes gemeinsamen Account-Symptoms (`invalid_download_code`, `hoster_unavailable`, Rate-Limit-Zeilen, `code=34`, `Link verification failed`, `keeping files as broken`, `broken_file]`, `Deleted downloads entry`), dann die letzten zehn dieser Zeilen und danach die letzten paar Zeilen, die das getestete Fixture nennen. Die Zeile `none present, so this failure is probably zurg's own and not the account's` sagt dir, dass du stattdessen den Code ansehen sollst.

`docs/realdebrid-behavior.txt` erklärt die Link-Semantik dahinter: welche Links über welchen Account eingelöst werden und warum `unavailable_file` und `hoster_unavailable` unterschiedliche Bedeutungen haben.

### Laufzeit {#runtime}

Der erste Lauf gegen ein bestimmtes Arbeitsverzeichnis zahlt für einen Kaltstart-Scan der Bibliothek: einen info-Aufruf und eine Link-Prüfung pro Torrent, getaktet durch das API-Kontingent des Kontos. Bei einem Konto mit ein paar Tausend Torrents sind das zig Minuten. Dieses Konto hatte am 2026-08-29 3,361 Torrents, genug, um anhaltend `code=34` auszulösen und ein Skript etwa zwanzig Minuten lang zu beschäftigen. Das Arbeitsverzeichnis behält drei Caches zwischen den Läufen, damit spätere Läufe sie überspringen: `info/`, `linkcache/` und die Ergebnisse der Netzwerktests. Lösche das Arbeitsverzeichnis, um den Kaltpfad zu erzwingen.

`linkcache/` ist das, was `internal/debrid.LinkCache` persistiert, eine Datei pro Provider-Instanz. Dieser Teil entfernt die zwanzig Minuten: Beim ersten Auftauchen eines Torrents wird einer seiner Links zur Prüfung aufgelöst, also ein `unrestrict/link`-Aufruf pro Torrent bei leerem Cache, und mit warmem Cache kostenlos. Der Nutzen ist durch die 4h-TTL des Caches begrenzt. Ein Suite-Lauf am nächsten Tag ist wieder kalt. Er verkürzt also die Iteration, nicht den ersten Lauf.

Weder `info/` noch `linkcache/` ist frei von Links, und beide enthalten Codes, die eine andere Instanz auf dem geteilten Konto widerrufen kann. Eine `.zurginfo` ist ein unverändertes `TorrentInfo`, enthält also die Real-Debrid-`/d/`-Codes des Torrents, und `linkcache/` enthält, wohin diese aufgelöst wurden. Beide bleiben trotzdem erhalten. Sie neu aufzubauen kostet die zig Minuten, und ein widerrufener Eintrag ist keine falsche Antwort: Die Prüfung bekommt `404 invalid_download_code`, zurg invalidiert diesen Eintrag und prägt ihn neu, sodass nur die widerrufenen Einträge einen Aufruf kosten. Erwarte jeden Lauf einige davon, und erwarte, dass der Speedup je nach Anzahl schwankt.

Ein Fixture ist noch enger: `clean_state_for_hash` löscht die `info/`-Einträge, deren Hash passt, sodass deren Linkliste immer frisch vom Konto geholt wird. `linkcache/` ist nach Link statt nach Hash geschlüsselt und wird nicht pro Fixture geleert, daher kann die *Auflösung* eines dieser Links noch vom vorherigen Lauf stammen. Das stützt hier keine Assertion, denn die Fixtures testen Refresh, Routing, den Mount und die Reparatur. Eine veraltete Auflösung schlägt bei der Prüfung fehl und wird neu geprägt, bevor einer von ihnen sie sieht.

### Refresh/Repair-Integrationstest {#refreshrepair-integration-test}

```bash
./integration/refresh_repair_integration.sh
```

Die automatische Reparatur bleibt in der Scratch-Konfiguration deaktiviert. Die beiden expliziten `/manage/{hash}/repair`-Anfragen umgehen diese Einstellung und reparieren ihre Fixtures.
Eine unbeaufsichtigte Reparatur zu aktivieren würde außerdem nicht zusammenhängende Einträge im geteilten Konto scannen und verändern und so das API-Budget verbrauchen, das die Assertions brauchen.
`refresh_repair_config_test.sh` prüft die generierte Konfiguration ohne Provider-Traffic, und zwar mit dem geschwärzten Scratch-Input aus dem Fehlerfall vom 2026-09-10.

| Szenario | Beschreibung |
|----------|-------------|
| 1. Automatische Aktualisierung (Hinzufügen) | Fügt einen Torrent über die RD-API hinzu und wartet, bis die Refresh-Schleife ihn bemerkt — kein Neustart, sonst würde man den Cold-Load-Pfad testen |
| 2. Verzeichniszuweisung & Routing | Prüft, ob Dateien in den virtuellen HTTP/DAV-Verzeichnissen erscheinen |
| 3. Persistenz (Neustart) | Startet zurg neu und bestätigt, dass der gecachte Zustand erhalten bleibt |
| 4. Automatische Aktualisierung (Entfernung) | Löscht den Torrent und wartet, bis die Bereinigung veralteter Schlüssel ihn entfernt |
| 5. Reparatur-Auslöser | Löst eine Reparatur über die Manage API aus, prüft, dass zurg im Log vermerkt hat, dass die Anfrage angenommen wurde, und wartet auf `ok_torrent` mit 0 defekten Dateien |
| 6. Reparaturprüfung | Repariert einen zweiten Torrent und lädt eine Videodatei daraus per Range-Anfrage |

#### Umgebungsvariablen {#environment-variables}

| Variable | Default | Beschreibung |
|----------|---------|-------------|
| `PORT` | `12345` | Port für die Test-zurg-Instanz |
| `CONFIG_PATH` | `config.yml` | Config, aus der die Zugangsdaten übernommen werden: das `token` des `realdebrid`-Providers sowie die obersten `username`/`password` |
| `TEST_HASH` | *(eingebaut)* | Torrent-Hash für die Refresh-Tests |
| `REPAIR_TEST_HASH` | *(eingebaut)* | Torrent-Hash mit kaputten Teilen für die Repair-Tests |
| `VERIFY_TEST_HASH` | *(eingebaut)* | Torrent-Hash für die Repair-Verifizierungstests |
| `READY_TIMEOUT` | `120` | Sekunden, die auf die Bereitschaft von zurg gewartet wird |
| `INITIAL_SCAN_TIMEOUT` | `3600` | Sekunden, die auf den ersten vollständigen Refresh-Durchlauf gewartet wird |
| `REFRESH_TIMEOUT` | `120` | Sekunden, die darauf gewartet wird, dass ein Refresh eine Hinzufügung oder Entfernung erkennt |
| `REPAIR_TIMEOUT` | `300` | Sekunden, die darauf gewartet wird, dass ein Repair abgeschlossen ist |
| `STREAM_LOGS` | `true` | Folgt dem Log von zurg auf stderr |
| `ZURG_BIN` | `$(pwd)/zurg` | Pfad zur zurg-Binary — absolut, weil zurg aus dem Arbeitsverzeichnis gestartet wird |
| `WORK_DIR` | `$TMPDIR/zurg-refresh-repair` | Arbeitsverzeichnis (bleibt zwischen den Durchläufen erhalten) |
| `WORK_DIR_CLEANUP` | `false` | Löscht das Arbeitsverzeichnis beim Beenden, wodurch die Caches verloren gehen, die spätere Durchläufe verkürzen |

### Force-Location-Integrationstest {#force-location-integration-test}

```bash
make force-location-test
```

Kein Teil von `make integration-test`, sondern wird bewusst separat ausgeführt. Gemessen am
`fun` 2026-08-29 lösten die erzwungenen `nyk`-Hosts zu AAAA-Records auf, die der
Download-Client über `tcp4` anspricht, sodass jeder HEAD mit `no suitable address
found` endete. Bei drei Wiederholungen je Anfrage bleibt der Bibliotheks-Scan, auf den dieser Test wartet, rund eine Stunde lang hängen, bevor
er an dem Netzwerk des Hosts statt an zurg scheitert.
Er überspringt bereits, wenn eine Region ungesund ist (siehe unten), aber diese Prüfung deckt nicht
den Fall ab, dass ein Host eine *gesunde* Region nicht über IPv4 erreichen kann.

Befüllt einen Netzwerk-Testcache, der auf `LOCATION` (Standard `nyk`) festgelegt ist, und prüft dann,
dass ein über den `/strm/`-Endpunkt von zurg aufgelöster Link zu einem Download-Host
an diesem Standort weiterleitet. `MAX_GEO_PROBES` (Standard `4`) begrenzt, wie viele Geo-Server
der Seed-Schritt höchstens prüft.

Wenn `cdn_host_preference` gesetzt ist, läuft jeder Link, den zurg prüft, über die erzwungene
Region. Ist diese ungesund, bleibt die Liste leer, und der Fehler sieht aus wie
ein zurg-Bug. Daher prüft der Test zuerst die Region und überspringt sie – statt
fehlzuschlagen –, wenn Real-Debrid dafür keinen Link erstellt oder der Host, den es zurückgibt,
keine Daten ausliefert.

(Eine frühere Übersetzung wurde abgelehnt: Die Code-Spans stimmten nicht überein. Behalte die Struktur genau bei.)

### Network-Test-Cache-Integrationstest {#network-test-cache-integration-test}

```bash
./integration/network_test_cache_integration.sh
```

Lässt zurg zweimal laufen: Beim ersten Start muss der Latenz-Test durchlaufen und `data/network_test_results.json` schreiben. Beim zweiten Start muss die Datei geladen werden, und es darf kein neuer Test laufen.

### Rclone-Mount-Integrationstest {#rclone-mount-integration-test}

```bash
./integration/rclone_mount_integration.sh
```

Geht den Weg durch, den ein Player tatsächlich nimmt: FUSE → zurg HTTP → Real-Debrid

| Schritt | Prüfung |
|---------|---------|
| 2 | zurg startet seinen eigenen Mount und loggt `Mount verification successful` |
| 3 | die konfigurierten Verzeichnisse sind an der Mount-Wurzel sichtbar |
| 4a–4c | die Fixture wird in der Bibliothek gefunden, über HTTP ausgeliefert und erreicht den Mount. Das ist in Stufen aufgeteilt, damit ein Fehler den kaputten Schritt nennt und nicht nur "not in the mount" |
| 5 | das Lesen der Datei über FUSE liefert echte Bytes |
| 6 | das Herunterfahren von zurg gibt den Mount wieder frei |

Schritt 4c ist die VFS-dircache-Prüfung: Die Fixture erreicht den Mount nur, wenn die Verzeichnisliste neu geladen wurde und nicht aus einer Liste stammt, die schon vor dem Eintreffen des Torrents zwischengespeichert war.

Die Bibliothek wird über einen Regex eingegrenzt, der aus dem eigenen Namen der Fixture gebaut wird. So enthält der Mount nur ein Release statt des ganzen Accounts. `MOUNT_PATH` ist standardmäßig `$WORK_DIR/mnt`, niemals der Produktivpfad `/mnt/zurg`. `RCLONE_BIN` ist standardmäßig `$(pwd)/bin/rclone`.

### Plex-Integrationstest {#plex-integration-test}

```bash
./integration/plex_integration.sh
```

| Schritt | Prüfung |
|---------|---------|
| 2 | zurg schreibt `Successfully connected to Plex server` ins Log |
| 3 | das Fixture landet in der Bibliothek, und wenn es zusätzlich im Mount auftaucht, muss es lesbar sein (Plex liest es als eigener Benutzer) |
| 4 | eine neue Wegwerf-Sektion wird über `$MOUNT_PATH/movies` angelegt |
| 5 | zurg löst seinen Bibliothekspfad auf diese Sektion auf und reiht einen Refresh **für den Pfad des Fixtures** ein |
| 6 | Plex hat das Element am Ende indiziert |

Dass das Fixture im Mount erscheint, ist hier eine Voraussetzung und nicht die Prüfung:
Ist Plex konfiguriert, führt zurg außerdem seinen Matcher über die gesamte Plex-Bibliothek aus,
was mit dem Refresh konkurriert, sodass die VFS-Auflistung weit hinterherhinken kann.
Der Test weist darauf hin und macht nach `MOUNT_VISIBLE_TIMEOUT` (Standard `420`) weiter —
die Schritte 5 und 6 schlagen ohnehin fehl, wenn Plex die Datei nicht sehen kann, und dass die Invalidierung funktioniert, zu prüfen ist Aufgabe des Mount-Tests. `PLEX_URL` und `PLEX_TOKEN` überschreiben
die `plex_server_url`/`plex_token` aus der Konfiguration.

Plex scannt eine neue Sektion automatisch und kann fertig sein, bevor das Anlegen zurückkehrt.
Der Test meldet diese anfängliche Anzahl; Schritt 5 prüft unabhängig davon, dass zurg
nach einer expliziten Manage-Anfrage den richtigen Pfad einreiht.

Die Sektion wird mit `agent=tv.plex.agents.none` und dem `Plex Video
Files`-Scanner angelegt, sodass Plex lokal indiziert, ohne einen Online-Metadaten-
Agenten zu fragen, und sie wird beim Beenden wieder gelöscht – auch bei einem Fehler, über den EXIT-
Trap. Bei SIGKILL läuft allerdings nichts mehr, also nach einem abgebrochenen Lauf nur die eigene Sektion prüfen und entfernen. Das Harness lässt bereits vorhandene Sektionen in Ruhe, weil sie zu einer anderen Sitzung gehören könnten. Bestehende Bibliotheken werden nie angefasst.

Schritt 5 bittet zurg, die Nebenwirkungen über `POST /manage/{hash}/scan` auszuführen, statt auf einen Refresh-Durchlauf zu warten. Der Trigger für die Verzeichniszuweisung feuert einmal, sobald ein Torrent entdeckt wird, und das passiert zwangsläufig, bevor die Sektion existiert; auf den nächsten vollständigen Durchlauf zu warten, kostet bei einem Konto mit einigen tausend Torrents mehrere Dutzend Minuten.
Die getestete Zuordnung bleibt unverändert – zurg muss seinen Bibliothekspfad trotzdem selbst auf die richtige Sektion auflösen.

### Usenet-Benchmark-Regression {#usenet-benchmark-regression}

```bash
./integration/nzb_bench_integration.sh
make nzb-bench-test
```

Nichts anderes in der Suite liest ein Byte über NNTP. Eine Änderung am Artikel-Fetcher, am yEnc-Decoder, an der PAR2-Reparatur oder am Archiv-Reader könnte den Durchsatz halbieren, den Speicherbedarf verdoppeln oder Stille ausliefern, wo ein Artikel fehlt, und jeder andere Test würde trotzdem bestehen. Dieser liest vier vorbereitete Releases über ein temporäres zurg und prüft sowohl die Zahlen als auch die Bytes.

**Warum ein A/B-Vergleich und keine gespeicherte Zahl.** Der Durchsatz auf einem Live-News-Server schwankt im Lauf eines Abends um 10–20 %. Sechs Lesevorgänge desselben Releases lagen in einer Sitzung zwischen 34 und 50 MB/s. Ein enges Toleranzband gegenüber einem Wert von letzter Woche würde also am Wetter scheitern, nicht am Code. Der Test misst deshalb zwei Binaries im selben Zeitfenster auf demselben Host. Die Reihenfolge wechselt von Durchlauf zu Durchlauf, damit das Aufwärmen auf Seite des Providers beiden zugutekommt. Verglichen werden die Mediane.

A ist die Baseline: standardmäßig der neueste `*-nightly`-Tag, der von `HEAD` aus erreichbar ist. Er wird mit `git archive` extrahiert und einmal gebaut, danach unter dem Work-Dir zwischengespeichert, damit spätere Läufe ihn wiederverwenden. B ist der Kandidat, also das `zurg`, das dieses Repo gerade gebaut hat. **Eine Metrik schlägt fehl, wenn B um mehr als 5 % schlechter ist als A** (`BENCH_TOLERANCE`). Besser wird als Verbesserung gemeldet. Fehlt eine Metrik auf einer Seite, ist sie `n/a` und keine Regression.

Pro Durchlauf misst der Test einen Kaltstart, die Zeit bis zum ersten Byte, einen Lesevorgang von 64 MiB und dasselbe 64 MiB noch einmal warm gelesen, einen Scrub über acht Punkte und einen Lesevorgang von 256 MiB. Dazu kommen CPU-Sekunden pro Gigabyte und Peak-RSS (nur Linux, beides aus `/proc`) sowie die Containerdauer, die `ffprobe` liefert.

Korrektheit wird nur am Kandidaten geprüft, nie über die Uhr. Jeder Lesevorgang protokolliert einen md5-Wert, der einer hinterlegten Konstante entsprechen und zwischen beiden Binaries übereinstimmen muss. Das beschädigte Release darf nur die Originalbytes oder Stille ausliefern, sonst nichts. Danach muss die Reparatur das Original erreichen und auch nach einem Neustart noch korrekt sein.

Der Korpus liegt eingecheckt unter `integration/nzbbench/corpus/`: sechs NZBs für sechs Fragen.

| NZB | Was es ist | Wofür es da ist |
|-----|------------|-----------------|
| `ToyStory5.nzb` | ein 6,61 GB WEB-DL mit 1.576 × 4 MiB Artikeln | alle Durchsatz- und Latenzwerte sowie die ffprobe-Prüfung |
| `ToyStory5Damaged.nzb` | dasselbe Release, bei dem die Message-ID von Artikel 21 verfälscht ist, sodass jeder Server mit `430` antwortet | das Loch muss die Originalbytes oder Stille liefern, alles andere ist ein Korrektheitsfehler. Danach muss PAR2 es reparieren, und die Reparatur muss einen Neustart überstehen |
| `Obfuscated.nzb` | derselbe Film, verteilt auf sieben Dateien unter `<hex> [n/7] yEnc`, dessen echter Name nur aus dem PAR2-Index hervorgeht | die Benennungsprüfung: Er muss unter dem echten `.mkv`-Namen in der richtigen Größe erscheinen, und keine `.par2`-Datei darf sichtbar sein |
| `FatherBrown.nzb` | ein 11-teiliges RAR mit einer Episode, einem Verzeichnis `Sample/` und einer nfo | der Archiv-Reader: Die Ordnerstruktur muss erhalten bleiben, und Lesevorgänge innerhalb des Archivs bekommen eine eigene Durchsatzzahl (`rar_read_MBps`, ein Lesevorgang pro Durchlauf) |
| `WrongTurn3.nzb.gz` | ein 58 GB großes gespeichertes 7z in 54 Volumes zu je 1 GiB (das letzte kürzer) plus sieben PAR2-Dateien, ein vollständiger UHD-BluRay-Baum. Gzip-komprimiert, weil die NZB unkomprimiert 7 MB groß ist | der Split-7z-Reader: Die Volumes müssen zusammengefügt und der Header am Ende des letzten Volumes gelesen werden, bevor irgendetwas aufgelistet wird. Gemessen wird diese Auflistung (`sevenzip_list_s`, eine pro Durchlauf aus einem geleerten Layout). Der 57,6 GB große Feature-Stream muss danach bei 8 GiB 16 MiB mit dem hinterlegten md5 liefern. Das ist eine Korrektheitsprüfung, keine Zeitmessung. Es gibt keine Durchsatzzahl: Bei diesem Provider fehlt in jedem Volume dieses Releases etwa ein Fünftel der Artikel, und ein zeitgemessenes Lesen würde nur das Suchen nach Löchern messen |
| `NestedRar.nzb` | ein Repost mit zwei CDs in XviD: ein äußerer RAR5-Volume-Satz, dessen Member die Volumes von zwei weiteren RAR-Sätzen in `CD1/` und `CD2/` sind, dazu ein Clip in `Sample/` und eine nfo | der Reader für verschachtelte Archive: Beide inneren Sätze müssen geöffnet werden. Der flache Test verweigert zwei vergleichbare Sätze, und die Verzeichnisse des Posters sind das, was sie gruppiert. Beide Filme müssen mit ihrer echten Größe aufgelistet werden und haben eine eigene Durchsatzzahl (`nested_read_MBps`, ein Lesevorgang pro Durchlauf) |

**Ein Account, eine Instanz.** Eine zweite zurg-Instanz auf demselben News-Account konkurriert mit der ersten um deren Verbindungskontingent, und der Server weist die *ältere* ab. Auf `fun` belegt die produktive `zurg-usenet` alle Verbindungen, die der Plan des Accounts erlaubt. Deshalb läuft der Benchmark mit 10 Verbindungen (`BENCH_NNTP_CONNECTIONS`). Eine Ablehnung mit `Too many connections` wird als **Skip, nicht als Fehler** gemeldet. Dasselbe gilt für einen nicht erreichbaren Server oder ein abgelehntes `AUTHINFO`. Die Umgebung konnte die Frage nicht beantworten, deshalb sagt der Test das, statt dem Build die Schuld zu geben.

Mit den vier Standard-Durchläufen dauert das etwa 15–20 Minuten, dazu kommen einmalig ein paar Minuten, wenn die Baseline zum ersten Mal gebaut werden muss.

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `PORT` | `12358` | Port für die zurg-Instanzen des Benchmarks (jeweils eine zur Zeit) |
| `WORK_DIR` | `$TMPDIR/zurg-nzb-bench` | Enthält die generierte Konfiguration, die Run-Verzeichnisse und Logs beider Binaries, `report.json` und das zwischengespeicherte Baseline-Binary. Bleibt zwischen Läufen erhalten. Das gespeicherte `data/` sorgt dafür, dass spätere Durchläufe einen Neustart messen und kein Neulernen von Null |
| `BENCH_ENV_FILE` | `~/.config/zurg/bench-account.env` | Account-Datei, wird eingelesen, wenn sie existiert. Enthält `KEY=value`-Zeilen für die `BENCH_NNTP_*`-Variablen. **Der unterstützte Weg, dem Benchmark einen eigenen Account zu geben.** So bleiben Zugangsdaten aus dem Repo und aus der Shell-History heraus |
| `CONFIG_PATH` | `config.yml` | Konfiguration, aus der der News-Account übernommen wird, wenn weder Umgebung noch Account-Datei einen angeben: der `nntp:`-Block des ersten Providers mit `type: nzb`. Die Übernahme wird verweigert, wenn dieser Account hier bereits offene Verbindungen hat (siehe unten) |
| `BENCH_NNTP_HOST` / `_PORT` / `_TLS` / `_USER` / `_PASS` | *(aus `BENCH_ENV_FILE`, dann `CONFIG_PATH`)* | Der News-Account. Ein exportierter Wert schlägt die Account-Datei. Wird nichts gefunden, gibt es einen Skip |
| `BENCH_NNTP_CONNECTIONS` | `10` | Verbindungen, die der Benchmark öffnet. Das ist eine Obergrenze: Ein Account, der für weniger konfiguriert ist, behält seine eigene Zahl |
| `BENCH_ALLOW_SHARED_ACCOUNT` | *(nicht gesetzt)* | Auf `1` setzen, um einen übernommenen Account zu benchmarken, der bereits offene Verbindungen hat. Nur, wenn du sicher bist, dass der Account genug Luft hat |
| `BASELINE_REF` | neuester `*-nightly` von `HEAD` aus erreichbar | Womit verglichen wird. Wird nach einem Best-Effort-`git fetch --tags` aufgelöst |
| `BASELINE_BIN` | *(aus `BASELINE_REF` gebaut)* | Eine vorgebaute Baseline, die unverändert verwendet wird. Der Weg, gegen etwas zu vergleichen, das hier nicht mehr baut |
| `BENCH_REPS` | `4` | Durchläufe pro Binary. Die Mediane werden über diese gebildet |
| `BENCH_TOLERANCE` | `0.05` | Wie viel schlechter B sein darf, bevor es eine Regression ist |
| `BENCH_SKIP` | *(keine)* | Kommagetrennte Liste der Phasen, die ausgelassen werden: `repair`, `obfuscated`, `rar`, `ffprobe`. `ffprobe` wird automatisch hinzugefügt, wenn es weder im `PATH` noch in `bin/` liegt |
| `REPORT_JSON` | `$WORK_DIR/report.json` | Wo der Bericht abgelegt wird |
| `STREAM_LOGS` | `true` | Verfolgt die `zurg.log` des Kandidaten auf stderr. Der Fortschritt des Tools selbst wird in beiden Fällen ausgegeben |

`report.json` enthält jede Zeile pro Durchlauf für beide Binaries, die Mediane, die Urteile pro Metrik, die `version`-Ausgabe beider Binaries sowie Host und OS. So lässt sich jede Zahl darin gegen den Code lesen, der sie erzeugt hat. Um Zahlen aufzuzeichnen, ohne etwas zu vergleichen, ruft man das Tool direkt mit einem einzigen `--bin` auf. Es misst, schreibt das JSON und endet mit Exit-Code 0:

```bash
cd integration/nzbbench && go build -o /tmp/nzbbench . && cd -
/tmp/nzbbench --config /path/to/a-config-with-an-nzb-provider.yml --port 12358 \
  --corpus integration/nzbbench/corpus --work /tmp/nzbbench-record \
  --bin candidate=./zurg --out /tmp/record.json
```

Die Config muss deine eigene sein: Die, die der Wrapper erzeugt, enthält das Passwort des Usenet-Accounts im Klartext und wird am Ende des Laufs gelöscht.

`integration/nzbbench/README.md` dokumentiert die eigenen Flags und Exit-Codes des Tools.

**Die Exit-Codes von `nzb_bench_integration.sh`.** `0` Der Vergleich wurde durchgeführt und hat bestanden, oder der Host konnte gar nicht benchmarken und der Lauf wurde übersprungen; `1` eine funktionale Assertion ist fehlgeschlagen oder eine Metrik hat sich verschlechtert; `4` alle funktionalen Assertions haben bestanden, aber das Timing-Gate wurde **nicht bewertet** -- der News-Server hat während des Fensters die Stabilitätsgrenze des Tools überschritten, daher wurde der Vergleich von Durchsatz und Latenz verworfen. 4 ist bewusst weder die 1 eines kaputten Builds noch die 0 eines Skips: Über die Performance wurde nichts entschieden, die Antwort lautet, in einem ruhigeren Zeitfenster erneut zu laufen. Der Lauf gibt außerdem ein Banner aus, das das Gate und die Streuwerte nennt, die es gebrochen haben. `make integration-test` wandelt jede fehlschlagende Rezeptzeile in den eigenen Exit-Code 2 von make um. Ein Suite-Lauf zeigt also ein non-zero make plus dieses Banner an, statt der Zeile „All integration tests passed.“ des Targets. Wenn etwas bei genau 4 verzweigen muss, ruf das Skript direkt auf.

### Voraussetzungen {#prerequisites-1}

- Real-Debrid-Token in `config.yml` (als `realdebrid`-Provider) oder `RD_TOKEN`
- `curl`, `python3` und ein gebautes zurg-Binary
- `shellcheck` für `make lint-integration` (wird mit einem Hinweis übersprungen, wenn es fehlt)
- Für die Mount- und Plex-Tests: `fusermount`/macFUSE, ein rclone-Binary und
  `user_allow_other` in `/etc/fuse.conf`, damit Plex auf den Mount zugreifen kann
- Für den Move-Refusal-Check: das korrigierte rclone aus `scripts/build-rclone-move-fix.sh`, gesetzt
  sowohl über `RCLONE_BIN` als auch über `RCLONE_TEST_BIN`. Ein neueres, unverändertes
  Upstream-rclone reicht nicht aus. Siehe [die MOVE-Regression](rclone-move-refusal.md).
  Stelle einen fertig gebauten Helfer über `DOTNET_MOVE_PROBE_BIN` bereit oder nutze Docker, um ihn zu bauen.
  Wenn du ihn als unprivilegierter Container-User baust, gib .NET ein beschreibbares `XDG_DATA_HOME`
  sowie Verzeichnisse für seinen CLI- und NuGet-Cache.
- Für den Usenet-Benchmark: ein Newskonto sowie Go, `git`, `tar` und `make` –
  er baut seine Baseline aus einem `git archive` eines Nightly-Tags

### Dem Benchmark ein eigenes News-Konto geben {#give-the-benchmark-its-own-news-account}

Ein Verbindungskontingent gehört zum **Konto**, nicht zu einem Prozess. Richtest du den Benchmark auf das Konto, auf dem bereits eine Produktiv-Instanz läuft, überschreiten beide zusammen das Limit. Dann lehnt der Server den *älteren* Verbindungsinhaber ab: die Produktiv-Instanz, die nichts vom Benchmark weiß, der das verursacht hat.

Deshalb greift der Benchmark nur als Ausweichlösung auf `CONFIG_PATH` zurück und **weigert sich, ein Konto zu übernehmen, auf dem auf diesem Host bereits Verbindungen offen sind**. Gib ihm ein eigenes Konto in `~/.config/zurg/bench-account.env`:

```
BENCH_NNTP_HOST=news.example.net
BENCH_NNTP_PORT=563
BENCH_NNTP_TLS=true
BENCH_NNTP_USER=...
BENCH_NNTP_PASS=...
BENCH_NNTP_CONNECTIONS=25
```

Wähle ein Konto mit Reserve, von der nichts abhängt. Am besten ein Server, dessen gemessene Obergrenze weit über dem liegt, was irgendeine Instanz konfiguriert hat, damit ein Benchmark keinen Leser aushungern kann.

Was du in der Kommandozeile exportierst, hat weiterhin Vorrang vor der Datei. Mit `BENCH_ALLOW_SHARED_ACCOUNT=1` umgehst du die Weigerung, wenn du dich vergewissert hast, dass der Spielraum tatsächlich vorhanden ist.

### Nicht in der Suite {#not-in-the-suite}

`rename_integration.sh`, `tag_stats_integration.sh` und
`test_repair_verification.sh` werden nicht von `make integration-test` ausgeführt. Sie haben noch ihre eigenen Kopien der Hilfsfunktionen von vor `lib.sh`. Portiere sie auf `lib.sh` und gib ihnen nicht kollidierende Ports, bevor du sie einbindest.
