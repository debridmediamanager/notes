# Plex-Funktionen & Möglichkeiten {#plex-features--capabilities}

Läuft rex neben Plex Media Server oder anstelle davon? [Von Plex zu rex wechseln](../../rex/from-plex.md) erklärt, was du in zurg behalten solltest, deinen rclone-Mount eingeschlossen, und welche Plex-Einstellungen von zurg du entfernen solltest.

## Konfiguration & Speicher {#configuration--storage}
- Konfigurationsschlüssel aus [`config.md`](../reference/config.md)/`config.example.yml`: `plex_server_url`, `plex_token`, `plex_match_every_mins` (Standard 1440), `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` (die veraltete Schreibweise von `watchlist.check_every_secs`, Standard 60s), `mount_path` (erforderlich für Abgleich und Aufbau der Scan-Pfade). Über das Dashboard gesetzte Einstellungen werden über den Config-Writer (`updateConfigFileAtomic`) direkt in `config.yml` gespeichert.
- Das Watchlist-Intervall fällt bei jedem Wert von 0 oder darunter auf den Standardwert zurück (`GetWatchlistCheckEverySecs`). `plex_match_every_mins` fällt nur dann zurück, wenn der Wert genau `0` ist (`intOr`, `internal/config/config.go`). Keines von beiden lässt sich deaktivieren. Das Dashboard lehnt alles unter 1 ab (`internal/handlers/dashboard/dashboard.go`). Ein negativer Wert für `plex_match_every_mins` in `config.yml` stoppt zurg beim Start mit `is negative; use 0 for the default`. Der Abgleich wird dadurch nicht abgeschaltet.
- Die Watchlist-Beschaffung wird über den Block `watchlist:` konfiguriert: `enabled`, `check_every_secs`, `indexers`, `max_size_gb`, `max_season_size_gb` und `quality` (Standard `best`). Ist `indexers` leer, werden die Indexer aus `stremio.indexers` übernommen. Die flachen Schlüssel `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` und `watchlist_quality` gelten weiterhin als veraltete Schreibweisen des ersten, zweiten und letzten dieser Einträge. Siehe [config.md](../reference/config.md#watchlist).
- `mount_path` ist außerdem das Präfix für Scan-Pfade, die an Plex und den verwalteten rclone-Mount gesendet werden ([`config.md`](../reference/config.md), `pkg/scan/scanner.go`).
- Der Hook `on_library_update` erhält jeden geänderten Pfad als Argument. Er wird um 500 ms verzögert und doppelte Einträge werden entfernt. Es läuft immer nur eine Ausführung gleichzeitig. So lassen sich Plex-Autoscan-Skripte einbinden (`internal/torrent/hooks.go`).

## Authentifizierung & Server-Erkennung {#authentication--server-discovery}
- Ablauf im Web-Dashboard: `/plex/auth` erstellt eine PIN-Session (`pkg/plex/auth.go`, `CreatePlexAuthURL`), speichert sie in `pkg/plex/auth_session.go` (automatische Bereinigung nach 10 Minuten, Prüfung alle 5) und fragt über `/plex/auth/status` ab, ob die Autorisierung abgeschlossen ist (`PollForAuthToken`, 60 Versuche im Abstand von 5 Sekunden, bevor es zum Timeout kommt).
- `/plex/callback` zeigt eine Fortschrittsseite, die nach erfolgter Autorisierung `/plex/servers` aufruft, um die Server aufzulisten, und `/plex/server` zum Auswählen eines Servers. (`internal/handlers/dashboard/dashboard.go`)
- Server-Erkennung (`pkg/plex/auth.go`): Holt die Plex-Ressourcen mit HTTP- und HTTPS-Endpunkten, filtert Relay-Verbindungen heraus, wenn eine direkte Verbindung existiert, verarbeitet IPv6-Adressen und prüft jeden Eintrag über `/identity` (TLS-Verifizierung deaktiviert). Berücksichtigt werden nur Server, die dem Konto **gehören** (`device.Owned`, `auth.go`). Geteilte Server tauchen nie auf. Einträge, die die Prüfung nicht bestehen, werden aus der Antwort entfernt, statt mit gesetztem `last_error` zurückgegeben zu werden (`enrichServersWithIdentity`, `auth.go`).
- Beim Auswählen eines Servers werden `plex_server_url` und `plex_token` in der Konfiguration gespeichert, der Plex-Client neu initialisiert, der Matcher-Scheduler (neu) gestartet, ein Match-Trigger ausgelöst und der zwischengespeicherte Dashboard-Status aktualisiert (`HandlePlexServerSelect`, `internal/handlers/dashboard/dashboard.go`). `/plex/logout` löscht die gespeicherten Werte und den Status-Cache.

## Plex-Client-Funktionen (`pkg/plex/client.go`) {#plex-client-capabilities-pkgplexclientgo}
- Lebenszyklus der Verbindung: Option für verzögerten Start (`WithDeferredStart`), `ValidateConnection`-Schutz gegen `/identity`, sauberes `Close`. Es gibt keine Restart-API. `RestartAllowed`/`RestartReason` im Dashboard werden aus der Server-URL abgeleitet (lokal/LAN vs. remote) und dienen nur der Anzeige (`internal/handlers/dashboard/plex_status.go:getPlexConnectionDetails`).
- Scan-Queue: dynamische Job-Queue/Worker (`common.DynamicJobQueue`). `ProcessJob` ruft `GET /library/sections/{key}/refresh` mit Plex-Headern auf und übergibt pro Job **höchstens einen** `path`-Query-Parameter. Mehr als einer wird direkt abgelehnt (`client.go`). Ein Job ohne Pfad ist ein Refresh der gesamten Section. 503 wird zu einem Server-busy-Fehler, 404 meldet die Bibliothek als in Plex gelöscht. `GetJobQueueSize` zeigt den Rückstau.
- Last- und Stuck-Erkennung: `CheckServerLoad` liest `/activities` aus und verfolgt den Fortschritt von `library.update.section` pro UUID. Ein geänderter Fortschritt *oder* Untertitel zählt als Fortschritt. `IsJobStuck` markiert veraltete Jobs anhand von `librarySectionID`, mit Title als Ersatz. `GetServerActivitiesDetails` legt dieselben Tracker an und räumt sie auch wieder auf, denn `CheckServerLoad` läuft nur, solange der Worker einen Job in der Queue hat. Ein Scan, den Plex von selbst gestartet hat, bekam früher gar keinen Tracker. Deshalb konnte er nie als hängend gemeldet werden, und seine verstrichene Zeit war bei jedem Refresh null. Beide Wege behalten die Historie nur für `library.update.section`. Alles andere hier zu tracken würde mit dem Prune des Workers flackern.
- **Der Aktivitäts-Untertitel ist nicht die Datei, auf die ein hängender Scan wartet.** Gemessen auf dem plex503-Rig, 2026-09-15: Der `library.update.section`-Untertitel ist der Aufzählungszeiger des Scanners und läuft den Lesevorgängen voraus. Bei drei vom Mount abgelehnten Dateien nannte er eine vierte Datei, die nie angefragt worden war. Die blockierte Datei nannte er nur 290 ms eines 56-s-Zyklus lang. Das Dashboard zeigt ihn als "Plex reports" an und verknüpft ihn nicht mit einem Release. Worauf der Scan tatsächlich wartet, kommt aus zurgs eigenen Ablehnungen (`internal/universal/refused_reads.go`), denn nur diese Seite weiß es. Das Korpus liegt in `internal/handlers/dashboard/testdata/plex503-*`.
- Bibliotheksabfragen: `GetSections` (Film- und Serien-Sections mit Pfaden), `GetSectionItemCount`, `FindSectionNormalized` (gleicht einen Pfad mit einem Section-Pfad ab und korrigiert das Präfix auf die Schreibweise der Bibliothek), `GetAllMediaItemsConcurrent` (gebündelter, paralleler Abruf mit `includeGuids`, um Pfade, GUIDs und IMDB-IDs zu sammeln) und `GetShowLevelIMDBIndex` (IDs auf Serienebene für TV-Sections, damit Episoden sie erben können).
- Metadaten- und Matching-Helfer (`pkg/plex/match.go`): `GetMetadataSummary` (`GET /library/metadata/{ratingKey}`), `GetMatchCandidates` (`GET /library/metadata/{ratingKey}/matches?manual=1`, mit Überschreibungen für Titel/Jahr/Sprache), `LookupMetadataByGUID`/`LookupRatingKeyByGUID` (`GET /library/all?guid=…`), `ApplyManualMatch` (`PUT /library/metadata/{ratingKey}/match`) sowie GUID-Parsing (`ExtractIMDBIDFromGUID`, `ExtractTMDBIDFromGUID`, `ExtractTVDBIDFromGUID`, `ExtractAnyIDFromGUIDs`; die Typen `MatchResult`/`MatchSelection`).
- Server-Infos: `GetServerIdentityOnly` und `GetServerDetails` (Machine-ID/Version; letztere summiert außerdem Sessions/Transcodes/Bandbreite), `GetStreamingSessions`, `GetTranscodeSessions`, `GetServerActivitiesDetails` (mit Stuck-Status annotiert).
- Wiedergabeverlauf: `GetWatchHistory` (`GET /status/sessions/history/all`), `GetMetadataBatch` (kommagetrennte Rating-Keys gegen `/library/metadata`) und `GetWatchHistoryWithMetadata` (`pkg/plex/history.go`). Letztere speist die Statistiken in `pkg/plex/stats.go`.

## Media-Scanner-Integration (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- Initialisiert den Plex-Client, sobald `mount_path`, `plex_server_url` und `plex_token` gesetzt sind. Danach wird alle 5s erneut versucht, bis die Verbindung steht, und dabei werden die `OnPlexReconnected`-Callbacks aufgerufen.
- `TriggerScan` gruppiert die Pfade pro Plex-Section (über `FindSectionNormalized`) und legt für jeden Pfad mit mount_path-Präfix einen Refresh-Job in die Warteschlange. Der Fortschritt wird alle 50 Pfade protokolliert. Jellyfin und Emby werden ebenfalls unterstützt, sie bekommen den nicht gruppierten Pfad. Ein Pfad, der in keiner Section landet, wird nur dann gemeldet, wenn *keiner* der Pfade im Batch gepasst hat. Sonst ist es nur eine Debug-Zeile. So löst ein Torrent, der sowohl in einem Bibliotheksordner als auch in einem nur-zurg-Ordner (recent, music, …) liegt, keine Warnung aus.
- `ReinitializePlexClient` erlaubt es, Server und Tokens per Dashboard-Update live auszutauschen.
- `GetQueueSizes` zeigt die Warteschlangentiefe von Plex für UI und Monitoring an.

## Abgleich & Metadaten-Synchronisierung (`internal/plex/matcher.go`, `internal/plex/schedule.go`) {#matching--metadata-sync-internalplexmatchergo-internalplexschedulego}
- Voraussetzungen: Du brauchst eine konfigurierte Plex-URL und ein Token, `mount_path` und einen laufenden `scanner.PlexClient`. Fehlt etwas davon, gibt die Funktion klare Fehlermeldungen zurück.
- Der einzige Plex-Status, den ein Torrent speichert, ist `PlexRatingKey` (bei Serien auf Show-Ebene) und `IMDBID` (`internal/torrent/torrent_types.go`). Plex-GUIDs werden während des Laufs zur ID-Extraktion und für Berichte genutzt, aber nie gespeichert.
- Datensammlung: Es werden alle Torrents aus der Verzeichnis-Map und alle Plex-Items über `GetAllMediaItemsConcurrent` geladen. Davor läuft ein `GetShowLevelIMDBIndex`-Durchlauf, damit Episoden die IMDB-, TVDB- und TMDB-ID der Show übernehmen und nicht eine eigene auf Episodenebene. Items werden über `GrandparentRatingKey` indiziert, wenn er vorhanden ist.
- Sync-Schritte:
  - Jeder gespeicherte Rating-Key wird gegen die frisch geladenen Plex-Items geprüft. Ein Key, den Plex nicht mehr kennt, wird zusammen mit der IMDB-ID des Torrents gelöscht, und der Torrent kommt zurück in die Warteschlange fürs Matching.
  - Pfadbasiertes Matching für Torrents ohne Rating-Key: `buildPlexDirIndex` indexiert jede kleingeschriebene Pfadkomponente jeder Plex-Datei. Dann wird der `GetKey` des Torrents darin nachgeschlagen (O(1), der erste Eintrag gewinnt). Torrents, deren zugewiesene Verzeichnisse zu keinem Plex-Section-Location passen, werden vorher übersprungen.
  - IMDB-Nachtrag: zuerst aus dem bereits geladenen Batch (ohne API-Aufrufe), danach pro Torrent über `GetMetadataSummary` (maximal 20 gleichzeitig).
  - Erkennt Plex-Items ohne Torrents.
  - Schickt an DMM nur die Hash+IMDB-Paare, die du von Hand gesetzt hast, nie IDs, die Plex nur geraten hat. DMM nimmt sie ohne Key an, und `dmm_api_key` wird mitgeschickt, wenn sie gesetzt ist (`sendHashImdbPairs` → `TorrentManager.SendHashImdbPairs`, `internal/torrent/mediainfo.go`).
- `MatchSingleTorrent` führt denselben Pfad-Lookup für einen einzelnen Torrent aus, etwa direkt nach einem gezielten Scan. Hat der Torrent schon einen Rating-Key, tut die Funktion nichts.
- Berichte: Es wird `logs/match_report.txt` geschrieben. Die Datei fasst Anzahlen, nicht zugeordnete Torrents, übersprungene Torrents, Plex-Items ohne Torrents und Matches ohne IMDB-ID zusammen.
- Zeitplan (`internal/plex/schedule.go`): Jeder abgeschlossene Lauf schreibt einen Zeitstempel nach `data/plex_match_timestamp`. Beim Start läuft `StartMatchingJob` sofort nur dann, wenn dieser Stempel fehlt oder älter als `plex_match_every_mins` ist. Ansonsten wartet er den Rest des Intervalls ab. Er hört auf manuelle Auslöser über `TorrentManager.PlexMatchTrigger`, auf Änderungen des Intervalls zur Laufzeit über `ResetPlexMatchTicker` und startet den Job bis zu dreimal neu, falls er in Panik gerät.
- Manueller Auslöser: Der Endpunkt `/plex/match-torrents` schiebt einen Auftrag in den Trigger-Kanal und lehnt ab, solange ein Lauf noch läuft. `/plex/match-torrents/status` meldet, ob gerade ein Lauf aktiv ist (`internal/handlers/utilities.go`).

## Manueller Abgleich & Verwaltungs-UI (`internal/handlers/manage`) {#manual-matching--manage-ui-internalhandlersmanage}
- Die Torrent-Listenfilter zeigen Plex-Status für schnelle Ansichten an: `plex_matched`, `plex_in_library_not_matched`, `plex_no_imdb`, `plex_missing_metadata` (`torrent_list_state.go`).
- Seite für manuelles Zuordnen pro Torrent unter `/manage/{hash}/plex-match`:
  - Der Torrent muss bereits einen `PlexRatingKey` haben (wird vom Matcher gesetzt). Fehlt er, zeigt die Seite „torrent is not linked to Plex“ an. `resolvePlexRatingKey` prüft diesen Schlüssel mit `GetMetadataSummary`, füllt eine fehlende IMDB-ID aus diesen Daten nach und ermittelt bei einem veralteten Schlüssel über `LookupRatingKeyByGUID` einen neuen. Dabei wird die gespeicherte `tt…`/`tvdb://`/`tmdb://`-ID des Torrents verwendet (`internal/handlers/manage/handler.go`).
  - Ruft die Kandidaten für das manuelle Zuordnen in Plex ab, optional mit überschriebenem Titel, Jahr oder Sprache (44 Sprachoptionen, Standard `en-US`). Die Treffer werden angezeigt, die aktuelle Auswahl ist hervorgehoben (`torrent_matches.go`).
  - Beim Anwenden einer Zuordnung (`HandleApplyPlexMatch`) ruft der Code `ApplyManualMatch` auf. Danach sucht er den Rating Key über die gewählte GUID neu, weil Plex ihn neu vergeben kann. Anschließend aktualisiert er Rating Key und IMDB-ID des Torrents (inklusive einer optionalen, vom Nutzer angegebenen IMDB-ID), speichert die Änderungen und leitet mit einer Erfolgs- oder Fehlermeldung weiter.

## Watchlist-Beschaffung {#watchlist-acquisition}

- Die Plex-Watchlist ist ein Adapter in `internal/acquisition/plex`. Er läuft auf dem gemeinsamen Acquisition-Dienst neben Seerr. Deine bestehenden Watchlist-Einstellungen funktionieren weiterhin. Adapter kannst du außerdem unter `acquisition.sources` konfigurieren.
- Der Client nutzt `discover.provider.plex.tv` und lädt jeweils 100 Einträge pro Seite. Das Plex-Token wird für jede Anfrage neu gelesen. Eine erneute Authentifizierung greift dadurch, ohne dass du den Adapter neu starten musst.
- Der gemeinsame Executor holt Filme oder jede geplante Staffel von Newznab- und Torznab-Indexern. Dabei bevorzugt er Staffel-Packs. Bei TV-Suchen probiert er zuerst TVDB und erst dann IMDb, weil die Zuordnungen der Indexer unterschiedlich sind.
- Fortschritt, Retry-Fristen und Belege pro Episode bleiben nach einem Neustart in `data/acquisition.json` erhalten. Das frühere Plex-Ledger wird automatisch importiert.
- Das Entfernen erfolgt, sobald alle geplanten Ziele beschafft wurden. Fehlgeschlagene Anfragen bleiben auf der Watchlist und werden mit persistentem Backoff erneut versucht. Ein Retry, der nur das Entfernen betrifft, beschafft nicht noch einmal. Grenzen findest du unter [Plex-Watchlist-Beschaffung](plex-watchlist.md), die gemeinsame Konfiguration unter [Acquisition-Quellen](acquisition.md).

## Dashboard & API-Endpunkte (`internal/handlers/router.go`, `internal/handlers/dashboard`) {#dashboard--api-endpoints-internalhandlersroutergo-internalhandlersdashboard}
- Routen: `/plex/auth`, `/plex/callback`, `/plex/auth/status`, `/plex/servers`, `/plex/server`, `/plex/logout`, `/plex/match-torrents`, `/plex/match-torrents/status`, `/plex/scan/{sectionKey}`, `/plex/scan-all`, `/plex-stats`, `/plex-stats/data`, `/plex-stats/image`, `/manage/{hash}/plex-match`.
- Das Dashboard zeigt Plex-Serverinfos und Status über `PlexStatusFetcher` an, und zwar mit zwei Timern: Alle 30 Sekunden werden Streaming-Sitzungen, Transcodes, Bandbreite und Server-Aktivitäten aktualisiert (`GetStreamingSessions`/`GetTranscodeSessions`/`GetServerActivitiesDetails`). Alle 5 Minuten läuft ein vollständiger Abruf, der zusätzlich die Identität erneut einliest (`GetServerIdentityOnly`), die Bibliotheksbereiche und die Anzahl der Einträge pro Bereich. Scan-Aktivitäten werden anhand des Dateinamens mit der Torrent-Liste abgeglichen, damit das Dashboard eine Aktivität mit einem Torrent-Hash verknüpfen kann.
- Die Endpunkte für Bereichs- und Gesamt-Scans stellen eine **vollständige** Aktualisierung des Bereichs in die Warteschlange (`RefreshSection(key, nil)`, ohne Pfad), für einen oder alle Bereiche. Sie greifen nicht auf STRM-Dateien zu und lösen keine Bibliotheks-Nebeneffekte aus (`HandlePlexScan`/`HandlePlexScanAll`).

## Plex Wrapped (`internal/handlers/dashboard/plex_wrapped.go`)
- `/plex-stats` rendert einen 9-Folien-Jahresrückblick aus dem Wiedergabeverlauf der letzten 12 Monate in Plex. `/plex-stats/data` gibt dieselben Statistiken als JSON zurück, `/plex-stats/image` rendert ein teilbares PNG über headless chromedp (`square` 1080x1080 als Standard, `instagram` 1080x1920, `facebook` 1200x630).
- Die Statistiken werden höchstens einmal alle 24h abgerufen (`?refresh=true` erzwingt einen neuen Abruf). Es werden maximal 10000 Verlaufseinträge berücksichtigt. Die Daten werden sowohl im Arbeitsspeicher als auch auf der Festplatte unter `data/plex_wrapped_cache.json` zwischengespeichert und beim Start wieder geladen. Während ein Abruf läuft, zeigt die Seite einen Ladezustand an, statt zu blockieren.

## Bibliotheks-Nebenwirkungen & Aktualisierungs-Links {#library-side-effects--refresh-links}
- Bibliotheks-Nebeneffekte werden ausgelöst, wenn sich Verzeichniszuweisungen ändern, bei Umbenennungen, Löschungen und Dateireparaturen: `TriggerLibrarySideEffects` invalidiert den rclone-VFS-Dircache für die betroffenen Pfade (damit die Medienserver keine veraltete Liste scannen), ruft `MediaScanner.TriggerScan` auf (was den Plex-Refresh anstößt) und führt den `on_library_update`-Hook des Benutzers aus (`internal/torrent/hooks.go`).
- Die Refresh-Pipeline führt STRM-Generierung und Nebeneffekte erst aus, nachdem die Initialisierung abgeschlossen ist, damit keine verfrühten Plex-Scans passieren (`internal/torrent/refresh.go`).

## Infrastruktur & Skripte {#infrastructure--scripts}
- Beispiel für einen Nginx-vhost zum Weiterleiten des Plex-Traffics (`nginx/plex.conf`).
- `plex_update.sh` ist das Referenzskript für Teil-Scans für `on_library_update: sh plex_update.sh "$@"`. Leg es neben `docker-compose.yml` ab. Dessen Ordner wird unter `/config` eingebunden, daher liegt das Skript schon im Container. Unter Windows läuft der Hook über PowerShell statt über `/bin/sh` (`pkg/script/script.go`), deshalb läuft dieses Skript dort nicht. Die PowerShell-Variante zeigt [Usenet → Point Plex at it](usenet.md#6-point-plex-at-it).
- `integration/plex_integration.sh` läuft unter `make integration-test` und `make integration-test-media`. Wenn auf dem Host kein Plex-Server läuft, wird laut übersprungen. Schau dir daher die Ausgabe an und nicht den Exit-Code. `scripts/plex-e2e-test.sh` ist ein eigenständiger Wiedergabetest, der `plex_server_url` und `plex_token` aus `config.yml` liest.

## Empfohlene Plex-Einstellungen {#recommended-plex-settings}

Die Standardwerte von Plex gehen davon aus, dass lokale Festplatten immer da sind und sich problemlos lesen lassen. Ein zurg-Mount ist beides nicht: Seine Daten kommen per HTTP von einem Anbieter, und er kann kurz nicht lesbar sein, während rclone sich wieder verbindet. Mehrere Plex-Standardwerte sind unter diesen Bedingungen sogar schädlich.

zurg gleicht diese Einstellungen bei jedem Plex-Statusabruf ab. `plex_settings_policy` legt fest, wie weit das geht: `off`, `warn`, `guard` (Standard) oder `enforce`. Die Liste steht in `pkg/plex/settings.go` (`RecommendedSettings`), die Richtlinie in `pkg/plex/reconcile.go`.

Eine Einstellung, die der Server nicht meldet, wird übersprungen. So wird eine Plex-Version, der eine Einstellung fehlt, nicht als falsch konfiguriert gemeldet.

Neun der sechzehn Werte unten weichen vom Plex-Standard ab. Die anderen sieben stimmen mit dem Standard überein und sind Schutzregeln statt Korrekturen. Sie greifen nur bei Betreibern, die eine davon selbst aktiviert haben. Bei diesen Zeilen steht in beiden Spalten derselbe Wert. Das ist kein Fehler: Plex liefert `GenerateBIFBehavior` mit `never` aus, der Server, mit dem diese Werte gemessen wurden, stand aber auf `scheduled`. Plex meldet den eigenen Standard pro Einstellung in `/:/prefs`. Deshalb wird die Spalte „Plex ships“ direkt vom Server gelesen und nicht angenommen (gemessen am 2026-09-05 mit Plex 1.42.2).

### Eine Einstellung abwählen {#opting-out-of-one-setting}

`plex_settings_policy` ist gestuft, und die Stufe ist nicht immer die Frage, die gestellt wird. Ein Betreiber, dessen Dateien zwischen Bibliotheksordnern wandern (etwa beim tag-gesteuerten Sortieren), ist darauf angewiesen, dass Plex seinen eigenen Papierkorb leert, um den übriggebliebenen Eintrag zu entfernen. `guard` schaltet das aus. Wenn du auf `warn` wechselst, um es zurückzubekommen, verlierst du auch die Filesystem-Event-Guards. Die liegen auf derselben Stufe, und du wolltest sie gar nicht ändern.

`plex_settings_ignore` benennt Einstellungen einzeln:

```yaml
plex_settings_policy: guard
plex_settings_ignore:
  - autoEmptyTrash
```

Diesen Eintrag schreibt das Dashboard für dich. Auf der Konfigurationsseite gibt es über den Library-Trash-Sweep-Einstellungen einen Schalter **Let Plex Empty Its Own Trash**. Er fügt `autoEmptyTrash` hier hinzu oder entfernt es wieder und lässt den Rest der Liste unverändert. Wenn du ihn einschaltest, wirkt das beim nächsten Neustart.

Eine ignorierte Einstellung wird weiterhin gelesen und weiterhin im Dashboard und in `zurg plex-settings` angezeigt (mit `skip` markiert). Es wird also nichts versteckt. Sie wird nur nie geschrieben, nie als Problem gezählt und nie hinter dem Trash-Banner des Dashboards gezeigt. IDs werden ohne Berücksichtigung von Groß- und Kleinschreibung abgeglichen. Eine ID, die keine Einstellung in den Tabellen unten benennt, wird beim Start gemeldet, und die Einstellung bleibt überwacht, denn ein Tippfehler darf nicht wie ein Opt-out wirken.

Eine Sicherheitseinstellung zu ignorieren geschieht auf eigene Gefahr. zurg weist beim Start einmal darauf hin, nicht bei jeder Aktualisierung. `autoEmptyTrash` ist besonders heikel, denn damit wird eine Bibliothek geleert, wenn ein Scan auf einen Mount trifft, der kurz ausgefallen war. Wenn du es ignorierst, gibst du außerdem die Aufräumaufgabe an Plex zurück. Details dazu unten.

### Wer leert den Papierkorb {#who-empties-the-trash}

Wenn du `autoEmptyTrash` ausschaltest, bleibt eine Aufgabe liegen. Plex wurde angewiesen, Einträge nicht zu entfernen, deren Dateien weg sind, und zurg hat das eigene Entfernen lange nur auf Wunsch gemacht. Ohne Einstellungen hat sich deshalb eine Bibliothek mit toten Einträgen gefüllt, und niemand hat sie aufgeräumt. Keine Seite lag falsch, aber die Lücke war echt: Sie zeigt sich, wenn eine Datei in einen anderen Bibliotheksordner wandert und der alte Eintrag für immer bleibt.

zurg übernimmt jetzt die Aufgabe, die es abgegeben hat. Wenn `plex_trash_sweep_every_mins` nicht gesetzt ist, entfernt der [Papierkorb-Sweep](../internals/plex-trash-sweep.md) Einträge alle 60 Minuten, aber nur, wenn sonst niemand das tut. Wenn Plex seinen eigenen Papierkorb noch leert, etwa weil `plex_settings_policy` auf `off` oder `warn` steht oder weil `autoEmptyTrash` in `plex_settings_ignore` steht, hält sich zurg zurück und überlässt es Plex. Zwei Aufräumer an einer Bibliothek sind der Weg, auf dem ein Streit zwischen ihnen zur Löschung wird.

Der Sweep ist viel enger als Plex' eigenes Leeren, und genau deshalb bevorzugen wir ihn: Er entfernt jeweils einen Eintrag, nie einen, der noch eine Datei hat, nur von einem Mount, der in diesem Moment lesbar ist, höchstens 50 Entfernungen und 10 % des Papierkorbs pro Durchlauf. Einträge, zu denen er kein Urteil hat, bleiben zuerst 14 Tage lang als defekt sichtbar. Er braucht außerdem `plex_database_path`, läuft also nur dort, wo Plex auf diesem Host läuft, und wo zurg das Mount selbst betreibt (`rclone_enabled` mit gesetztem `mount_path`). zurg liest diese Datenbank mit dem Programm `Plex SQLite`, das Plex installiert, und findet es dort, wo Plex' Installer es auf Linux, macOS und Windows ablegt. Du musst also nur `plex_database_path` setzen:

+++ Linux
```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ macOS
```yaml
plex_database_path: "/Users/YOU/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ Windows
```yaml
plex_database_path: 'C:\Users\YOU\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db'
```
Die einfachen Anführungszeichen beibehalten: In doppelten Anführungszeichen liest YAML einen Backslash als Escape-Zeichen. Setze `plex_sqlite_binary` nur für Plex an einem anderen Ort, etwa bei einem 32-Bit-Plex: `'C:\Program Files (x86)\Plex\Plex Media Server\Plex SQLite.exe'`.
+++

Ersetze `YOU` durch deinen Benutzernamen: zurg erweitert weder `~` noch `%LOCALAPPDATA%`. Der Sweep gleicht die Pfade, die Plex speichert, mit `mount_path` ab, das auch einen Laufwerksbuchstaben wie `Z:` verarbeitet (`pkg/utils/path_within.go`).

Um das Entfernen auszuschalten und den Papierkorb selbst zu leeren, schreibe `plex_trash_sweep_every_mins: 0`. Das ist das ausdrückliche Nein und unterscheidet sich davon, den Schlüssel wegzulassen.

Dieser Schlüssel schaltet nur das eigene Entfernen von zurg aus. Er gibt Plex seine Einstellung nicht zurück. Unter `guard` schreibt zurg weiterhin `autoEmptyTrash` auf off, also leert Plex seinen Papierkorb nach einem Scan weiterhin nicht, und die Einträge sammeln sich ohne Aufräumer an. Nutze den Schalter im Dashboard oder `plex_settings_ignore`, um Plex die Aufgabe zurückzugeben.

### Sicherheit — korrigiert unter `guard` und `enforce` {#safety--corrected-under-guard-and-enforce}

Diese verlieren Daten statt Zeit, deshalb schreibt die Standardrichtlinie sie fest vor, anstatt nur zu warnen. Nur `autoEmptyTrash` wird mit dem gefährlichen Wert ausgeliefert. Die anderen drei stehen bereits auf dem Wert, den zurg haben möchte, und sind nur da, um einen Betreiber zu erwischen, der eine davon eingeschaltet hat.

| Einstellung | Plex-Standard | zurg will | Warum |
|---|---|---|---|
| `autoEmptyTrash` | `1` | `0` | Plex leert seinen Papierkorb nach jedem Scan. Wenn der Mount während eines Scans kurz nicht lesbar ist, gelten alle Dateien als gelöscht, und Plex entfernt sie dauerhaft, statt sie im Papierkorb zu lassen, wo sie mit dem Mount wieder auftauchen würden. |
| `FSEventLibraryUpdatesEnabled` | `0` | `0` | Ereignisgesteuerte Updates verpassen genau das, was sich hier tatsächlich ändert. zurgs Baum ändert sich auf seiner eigenen Seite, und das läuft nie durch den lokalen Kernel. Deshalb wird kein Ereignis ausgelöst, und die Bibliothek veraltet still und leise. Die Ereignisse, die ankommen, sind Schreibvorgänge *durch* den Mount, die landen, während ein Verzeichnis noch zusammengebaut wird. |
| `FSEventLibraryPartialScanEnabled` | `0` | `0` | Ein partieller Scan läuft über genau diese Ereignisse. Er wird also bei den Schreibvorgängen durch den Mount ausgelöst, genau dann, wenn ein Verzeichnis halb geschrieben ist, und nie bei den Änderungen auf der Gegenseite, die tatsächlich einen Scan bräuchten. |
| `ButlerTaskBackupDatabase` | `1` | `1` | Das nächtliche Datenbank-Backup ist das Einzige, was eine Bibliothek wiederherstellt, die Plex bereits gelöscht hat. |

Die beiden `FSEvent`-Begründungen wurden nach Messungen auf allen Plattformen, auf die zurg mountet, neu geschrieben. Der frühere Wortlaut besagte, ein FUSE-Mount "gebe sie nicht zuverlässig aus, daher erzeuge dies Scans zu Zeitpunkten, die niemand angefordert hat". Beide Hälften davon sind falsch.

Gemessen am 2026-09-05: Auf jeder Plattform wurde mit der API überwacht, die der jeweilige Medienserver tatsächlich verwendet. Getestet wurde gegen einen rclone-Mount, dessen Backing-Verzeichnis direkt verändert werden konnte. **A** ist ein Schreibvorgang durch den Mount. **B** ist dieselbe Datei, die auf der Gegenseite erscheint, so wie es passiert, wenn sich zurgs eigener Baum ändert.

| Plattform | Mount | Überwacht mit | A: durch den Mount | B: auf der Gegenseite geändert |
|---|---|---|---|---|
| Linux | `fuse.rclone` | inotify | `CREATE` `OPEN` `ATTRIB` `CLOSE_WRITE` | **keine Ereignisse** |
| Docker | gleicher Mount, per Bind-Mount in einen Container eingebunden | inotify, im Container | dieselben vier, im Container gesehen | **keine Ereignisse** |
| macOS | macFUSE | FSEvents | `Created IsFile` | **keine Ereignisse** |
| Windows | WinFsp | `ReadDirectoryChangesW` | `Created` `Changed` | **keine Ereignisse** |

Jede Plattform lieferte A. Ein gleichzeitiger Kontrolllauf auf einem nativen Dateisystem (APFS, NTFS) erzeugte dieselben Ereignisse, also funktionierten die Watcher. Keine Plattform lieferte B, obwohl die Datei nach Ablauf des Verzeichnis-Caches durch den Mount sichtbar war.

Der Fehlermodus ist also das Gegenteil dessen, was behauptet wurde. Ein ereignisgesteuertes Update wird bei Schreibvorgängen *durch* den Mount ausgelöst, etwa wenn ein \*arr-Import in einem noch zusammengebauten Verzeichnis landet. Und es wird nie für die Änderungen auf der Gegenseite ausgelöst, die der eigentliche Grund für einen Scan sind. Ereignisse sind nicht unzuverlässig. Sie melden nur die falsche Hälfte dessen, was auf einem Debrid-Mount passiert.

### Bandbreite — nur unter `enforce` korrigiert {#bandwidth--corrected-under-enforce-only}

Auf lokalem Speicher ist das harmlos. Über einen Debrid-Mount dagegen ist jedes Byte eine Anfrage an den Anbieter, und das passiert für die ganze Bibliothek. Analysen, deren Ergebnis *sichtbar* ist, also Scrubbing-Vorschauen, Kapitelbilder, Lautstärkeangleichung und Sonic-Analyse, landen stattdessen in der Stufe darunter für Geschmackssachen. Dort greift `enforce` nicht ein.

| Einstellung | Plex-Standard | zurg will |
|---|---|---|
| `ButlerTaskDeepMediaAnalysis` | `1` | `0` |
| `ButlerTaskUpgradeMediaAnalysis` | `1` | `0` |
| `GenerateAdMarkerBehavior` | `scheduled` | `never` |
| `GenerateVADBehavior` | `never` | `never` |
| `GenerateIndexFilesDuringAnalysis` | `0` | `0` |
| `ButlerTaskGenerateMediaIndexFiles` | `0` | `0` |

### Geschmack — wird immer gemeldet, nie korrigiert {#taste--always-reported-never-corrected}

Es steckt hinter jedem dieser Werte eine Funktion. zurg zeigt also, was der Wert kostet, und lässt die Wahl offen. Eine Funktion ungefragt abzuschalten würde dem Betreiber etwas wegnehmen, das er sehen kann. Das steht nicht in zurgs Ermessen, auch wenn dadurch Bandbreite gespart würde. Bei den ersten beiden behält die günstigere Option die Funktion und verschiebt die Arbeit ins Wartungsfenster. Bei den restlichen geht es um die Wahl zwischen Funktion und Bandbreite.

| Einstellung | Plex-Standard | zurg empfiehlt | Warum |
|---|---|---|---|
| `GenerateIntroMarkerBehavior` | `asap` | `scheduled` oder `never` | `asap` dekodiert jede Datei, sobald sie ankommt, also außerhalb jedes Wartungsfensters. `scheduled` behält den Skip Intro-Button und verschiebt die Arbeit ins Fenster. |
| `GenerateCreditsMarkerBehavior` | `asap` | `scheduled` oder `never` | Dasselbe, für Skip Credits. |
| `GenerateBIFBehavior` | `never` | `never` | Dekodiert das ganze Video, um die Bildleiste zu erstellen, die beim Spulen angezeigt wird. Für die Wiedergabe wird sie nicht gebraucht. |
| `GenerateChapterThumbBehavior` | `scheduled` | `never` | Dekodiert die Datei, um pro Kapitel ein Bild zu holen, das neben jedem Eintrag in der Kapitelliste steht. |
| `LoudnessAnalysisBehavior` | `scheduled` | `never` | Dekodiert den Ton jeder Datei komplett, um ihn zu messen, damit die Lautstärke zwischen Titeln und Folgen angeglichen werden kann. |
| `MusicAnalysisBehavior` | `scheduled` | `never` | Dekodiert jeden Titel. Das sind viele kleine Dateien, deshalb ist das die Anzahl an Anfragen, die einem Konto das Rate-Limit einbringt. Dafür gibt es die Klanganalyse: Mischungen aus ähnlichen Titeln und den Visualisierer. |

### Das Wartungsfenster {#the-maintenance-window}

zurg fasst `ButlerStartHour`/`ButlerEndHour` nicht an, weil es keine Stunde gibt, die für alle passt. Es lohnt sich, sie von Hand zu setzen: Plex hat standardmäßig 02:00–05:00, und ein Zeitfenster, das sich mit den Stunden überschneidet, in denen jemand schaut, macht jede Wartungsaufgabe zu einem Stillstand. Was in der Bandbreiten-Stufe übrig bleibt, läuft innerhalb dieses Fensters.

### Einen laufenden Durchlauf stoppen {#stopping-a-pass-already-in-flight}

Eine geänderte Einstellung gilt nur für künftige Läufe, nicht für den bereits laufenden. Plex Media Server startet seine Scanner-Kindprozesse neu, also bringt es nichts, sie zu beenden:

+++ Linux und macOS
```bash
curl -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
+++ Windows
```powershell
curl.exe -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
In Windows PowerShell 5.1 ist `curl` nur ein anderer Name für `Invoke-WebRequest`, also schreib `curl.exe`.
+++

Setze zuerst `$TOKEN` auf dein Plex-Token: `TOKEN=your-token` in einer Shell, `$TOKEN = 'your-token'` in PowerShell.
