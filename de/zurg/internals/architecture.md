# Architektur {#architecture}

Eine Übersicht darüber, was zurg ist, wie die einzelnen Teile zusammenspielen und warum es jedes Paket gibt. Sie richtet sich an alle, die gleich am Code etwas ändern wollen: Sie benennt die tragenden Entscheidungen und die Invarianten, die man leicht übersieht und dadurch versehentlich kaputt macht.

Details zu einzelnen Paketen stehen in der `doc.go` des jeweiligen Pakets. Dieses Dokument ist die Ebene darüber: die Gesamtstruktur und die Überlegungen, aus denen sie folgt.

## Was zurg ist {#what-zurg-is}

Ein Go-Daemon, der die Torrent-Bibliothek eines Debrid-Kontos als virtuelles Dateisystem bereitstellt. Er speichert selbst keine Medien. Jeder Lesezugriff wird erst beim Abruf in einen HTTP-GET mit Range-Header gegen das CDN des Anbieters umgewandelt.

Er hält keine eigenen Inhalte und lehnt ein PUT ab. Was die Bytes betrifft, ist er also schreibgeschützt. Zwei Schreibvorgänge sind erlaubt: ein Rename, der nur einen Namen speichert und kein Konto anfasst ([renaming.md](../guides/renaming.md)), und ein DELETE, der das Release aus allen Konten entfernt, in denen es liegt. `__magic__` kommt innerhalb eines Namensraums als dritter Schreibvorgang hinzu, nämlich ein gespeichertes Layout ([magic.md](../guides/magic.md)). Das gilt überall darin außer unter `__magic__/__all__` und den Release-Ordnern direkt darin. Das ist der berechnete Spiegel, aus dem die Download-Clients importieren.

Vier Sichten auf dieselbe Bibliothek:

| Endpunkt | Für |
|---|---|
| `/dav/` | WebDAV, das rclone einbindet |
| `/http/` | HTML-Verzeichnisbrowser |
| `/infuse/` | WebDAV-Variante, die die Eigenheiten von Infuse berücksichtigt |
| `/strm/` | Signierte URLs in `.strm`-Dateien, für Player, die eine URL statt eines Mounts wollen |

rclone bindet `/dav/` per FUSE ein, daher sehen Plex, Jellyfin, Emby und Infuse einen ganz normalen Verzeichnisbaum.

Das Designproblem zieht sich durch das ganze Projekt: die Lücke zwischen dem, was ein Dateisystem verspricht (stabile Pfade, sofortiges `stat`, Bytes auf Abruf), und dem, was eine Debrid-API liefert: ratenbegrenztes JSON, Links, die verfallen, und überhaupt keine Dateisystem-Semantik. Fast jedes Paket existiert, um einen Teil dieser Lücke zu schließen.

```
media player
    │
    ├─ rclone FUSE ──► /dav/  ──┐
    └─ direct HTTP ──► /http/ ──┤
                                ▼
                    internal/handlers  (chi router, auth, routing)
                                │
                internal/dav ───┤─── internal/htmlindex     (listings)
                                │
                                ▼
                    internal/torrent   (the library, in memory)
                                │  resolve link for this file
                                ▼
                    internal/universal (byte path, proxy/redirect, RAR)
                                │
                                ▼
                    internal/debrid    (Provider dispatch)
                                │
        ┌───────────┬───────────┼────────────┬──────────┐
        ▼           ▼           ▼            ▼          ▼
   realdebrid    torbox     alldebrid       nzb ──► nntp ──► par2
        └───────────┴───────────┘            (Usenet, no debrid service)
                    │
              internal/rdclient  (host rotation, rate limit, retry, DNS)
```

## Startablauf {#boot-sequence}

`cmd/zurg` ist ein schlankes Cobra-CLI (serve, version, network-test, clear downloads/torrents, mount control, download requirements). Die eigentliche Arbeit passiert in `internal/app.go`, dessen `MainApp` bewusst eine gut lesbare Funktion ist:

1. Lege die Laufzeitverzeichnisse an (`logs`, `data`, `data/info`, `dump`, `strm`, `nzbs`) und den Logger.
2. `ensureConfigAndRequirements` — lade die Konfiguration und lade `ffprobe` und `rclone` herunter, falls sie fehlen (`internal/requirements`). Ein erster Start ohne Konfiguration schreibt eine Standardkonfiguration und hält dann an, außer der Token kam aus der Umgebung.
3. Initialisiere `strmlink` früh, damit ein nicht beschreibbares Datenverzeichnis jetzt gemeldet wird und nicht erst als `.strm`-Dateien, die nach dem nächsten Neustart nicht mehr aufgelöst werden.
4. Führe den **Netzwerk-Latenztest** gegen Real-Debrids Download-Hosts aus (`internal/rdclient`) oder lade sein gecachtes Ergebnis von der Festplatte, wenn es frisch genug ist. Dadurch werden die CDN-Hosts gereiht, und darauf greift später die Host-Rotation zu.
5. Baue jeden konfigurierten Provider aus der Registry, füge sie zu einem `debrid.Set` zusammen und behalte einen typisierten Verweis auf den ersten Real-Debrid-Provider. Das Dashboard, die Hosts-Seite und der Netzwerktest sprechen weiterhin gezielt mit RD.
6. Erstelle den `TorrentManager`. Er beginnt sofort im Hintergrund, die gecachte Bibliothek von der Festplatte zu laden, und aktualisiert sie danach.
7. Hänge den chi-Router an, starte den HTTP-Server und starte rclone, sobald der Server Verbindungen annimmt.
8. Warte auf SIGINT/SIGTERM/SIGQUIT. Bei einem Signal fährst du den HTTP-Server herunter, stoppst den Plex-Dienst und hängst rclone aus, jeweils mit einem Zeitbudget von 20 s.

`ZURG_PPROF=1` aktiviert pprof auf `127.0.0.1:6060`. Das ist nur Loopback, denn Profiling einer laufenden Instanz ist die einzige Möglichkeit, CPU während eines Scan-Sturms zuzuordnen. Der Endpunkt darf aber niemals aus dem Netzwerk erreichbar sein.

## Ebene 1 — Konfiguration {#layer-1--config}

`internal/config` ist die einzige Quelle der Wahrheit; fast jedes andere Paket liest `ZurgConfigV1`. Typisierte Getter wenden Standardwerte an, wenn ein Feld null ist, sodass Aufrufer nie auf Abwesenheit prüfen müssen.

Der wichtigste Teil ist `filters.go`: eine verschachtelte AND/OR-Filtersprache, die jeden Torrent einem oder mehreren **virtuellen Verzeichnissen** zuweist. Damit wird aus einer flachen Torrent-Liste ein `movies/`, `shows/`, `anime/`, `recent/`.

Bedingungen decken den Torrent-Namen ab (`regex`, `contains`, `not_regex`), seine Größe, seine Dateien (`any_file_inside_regex`, `any_file_inside_size_gte`), seine Tags (`tags_match_any`, `tags_missing_all`), sein Alter (`added_within_hours`, `added_after`), abgeleitete Eigenschaften (`has_episodes`, `is_music`) und von welchem Konto er stammt (`provider`, `not_provider`). Daneben gibt es Anzeigeregeln pro Verzeichnis: `only_show_the_biggest_file`, Mindest- und Höchstgrößen.

Regexe, die pro Torrent und pro Zuweisungsdurchlauf verwendet werden, werden einmal auf Paketebene kompiliert – `MustCompile` pro Aufruf war beim Start messbar der größte Bremsklotz.

Die Konfiguration lässt sich live im Dashboard bearbeiten. `UpdateConfigFileAtomic` nimmt Änderungen auf Schlüsselebene vor, statt die Datei neu zu serialisieren, sodass Kommentare und unbekannte Schlüssel erhalten bleiben.

## Ebene 2 — Backend-Abstraktion {#layer-2--backend-abstraction}

`internal/debrid` ist das Rückgrat. Es enthält die Domänentypen, die alle anderen Pakete verwenden — `Torrent`, `TorrentInfo`, `File`, `Download`, `User` — sowie das `Provider`-Interface, das jedes Backend implementiert.

### Provider und Fähigkeiten {#provider-and-capabilities}

`Provider` bleibt klein: Torrents auflisten, Infos abrufen, löschen, einen Link auflösen, ihn prüfen, Bytes abrufen und den Kontostatus melden. Alles, was ein Dienst vernünftigerweise nicht können könnte, ist ein **optionales Capability-Interface**, das Aufrufer per Type-Assertion prüfen und bei dessen Fehlen auf einen Fallback ausweichen:

| Interface | Was es hinzufügt | Wer es braucht |
|---|---|---|
| `MagnetAdder` | Hinzufügen per Hash, Dateiauswahl, Anzahl aktiver Slots | Reparatur |
| `TorrentRestarter` | Fehlgeschlagenen Torrent direkt neu versuchen | Reparatur, günstigste Strategie |
| `HostRotator` | Den CDN-Host-Pool austauschen | Netzwerktest, `/hosts`-Seite |
| `DownloadLister` | Eine separate Liste der Hoster-Downloads | Das `__downloads__`-Verzeichnis |
| `ArchivePasswordKeeper` | Passwort für die Archive eines Releases | Nur Usenet |
| `PremiumMonitor` | Verbleibende Laufzeit des Tarifs | Warnung beim Start |

Daneben ist `Capabilities` die Selbstbeschreibung des Providers. Sie sagt nicht, was er kann, sondern innerhalb welcher Grenzen er betrieben werden muss. Das gibt es, weil sich das Bibliotheksverhalten von zurg rund um die Struktur von Real-Debrid entwickelt hat. Würde man diese Struktur fest einbauen, wäre jedes andere Backend entweder kaputt oder unnötig verschwenderisch.

Zwei Flags steuern bereits das echte Verhalten:

- **`ListIncludesFiles`** – Die Torrent-Liste enthält bereits die Details zu den einzelnen Dateien. Dadurch wird aus einem Kaltstart-Scan der Bibliothek, der bisher einen API-Aufruf pro Torrent brauchte, insgesamt nur ein einziger Aufruf. Das ist der mit Abstand größte Unterschied zwischen den Backends.
- **`StoredLinksCanRot`** – Ein gespeicherter Link kann absterben, während der Torrent noch gesund aussieht. Deshalb müssen Links geprüft werden. Das ist eine Eigenschaft von Real-Debrid und dazu eine teure. Bei einem Backend, das URLs erst auf Anfrage erzeugt, gibt es nichts zu prüfen. Dort entscheidet das Überspringen dieses Durchlaufs darüber, ob ein Scan kostenlos ist oder eine kontoweite Sperre auslöst.

Der Rest – `ServesLinksLocally`, `MaxActiveSlots`, `MaxConcurrentRequests`, `AddsPerHour`, `ContentExpires`, `SupportsFileSelection` – wird von jedem Backend angegeben und vom generischen Code gelesen. Der Nullwert ist bewusst die vorsichtigste Lesart. Ein Provider, der ein Feld vergisst, bekommt also vorsichtiges Verhalten statt einer Flut von Anfragen. Und wenn zurg einen Provider gar nicht auflösen kann, greift es auf `unknownProviderCaps` in `internal/torrent/providers.go` zurück. Dort ist diese vorsichtige Antwort einmal festgelegt, statt an jeder Aufrufstelle wiederholt zu werden.

Es gibt eine dritte Form, die keines der beiden Flags abbildet: Die Liste von AllDebrid enthält keine Dateien, aber der Endpunkt pro Torrent nimmt einen *Batch* an IDs entgegen. Das wird innerhalb des Providers gelöst und nicht über ein Capability, weil nur verändert wird, wie der Provider seine eigenen Anfragen verteilt. Der generische Refresh fragt weiterhin einen Torrent nach dem anderen ab und muss davon nichts wissen.

### Set

`Set` ist jeder konfigurierte Provider in der Reihenfolge der Config. Er ist die Grundlage für den Torrent-Manager, die Handler und das Dashboard, damit sie nicht von einem konkreten Client abhängen. Zwei Zugriffsmuster sind wichtig: **Fan-out**, wenn eine Operation gegen jeden Account läuft (etwa ein Library-Refresh), und **Dispatch**, wenn eine Operation genau den Account erreichen muss, dem ein Torrent gehört (löschen, auflösen, reparieren). Außerdem speichert er den Zustand der Account-Gesundheit bzw. Verfügbarkeit.

### Link-Cache {#link-cache}

`LinkCache` speichert aufgelöste URLs **pro Token**, nicht nur pro Link. Eine URL, die mit einem Token erzeugt wurde, gilt nur für das Kontingent genau dieses Tokens. Wenn ein Token seine Bandbreite ausgeschöpft hat, müssen deshalb alle seine Einträge komplett verworfen werden, anstatt sie mit dem nächsten Token in der Rotation weiterzuverwenden. Einträge laufen über den Zeitstempel `Generated` ab und nicht über die Einfügezeit. Links, die aus der eigenen Download-Liste des Anbieters vorgeladen wurden, verfallen also nach dem Zeitplan des Anbieters.

### Die Backends {#the-backends}

| Paket | Was es ist | Das solltest du wissen |
|---|---|---|
| `internal/realdebrid` | Real-Debrid, das ursprüngliche Backend | Drei getrennte HTTP-Clients: API mit Ratenbegrenzung, unrestrict mit Ratenbegrenzung, Download mit Host-Rotation. Zeitstempel in Paris-Ortszeit werden an der Paketgrenze normalisiert und fließen nie darüber hinaus. `DownloadTokenManager` rotiert Tokens, wenn eines abläuft. |
| `internal/torbox` | TorBox REST | Nutzt REST mit `bypass_cache=true` statt dem WebDAV von TorBox, dessen Ansicht 5–15 Minuten hinter der Realität herhinkt. Es gibt keinen Link pro Datei, deshalb werden Links als `torbox://<torrent-id>/<file-id>` synthetisiert. Die sind über Neustarts hinweg stabil und in Logs lesbar, was eine reine CDN-URL mit dem API-Key nicht wäre. Zwei hintereinandergeschaltete Limiter: die dokumentierten 300/min und ein deutlich strengerer für `requestdl`. Siehe [torbox-limits.md](../providers/torbox-limits.md). |
| `internal/alldebrid` | AllDebrid v4.1 | Formular-kodierte POSTs. Ein logischer Fehler kommt als HTTP **200** mit `status:"error"` zurück, daher verrät der HTTP-Status nie, ob ein Aufruf geklappt hat. Dateien liegen hinter `/magnet/files`, das einen Batch annimmt, deshalb werden gleichzeitige Lookups zu einzelnen Anfragen zusammengefasst. Der verschachtelte Dateibaum wird in Tiefensuche flachgeklopft, und diese Reihenfolge ist unverzichtbar. |
| `internal/nzb` | Usenet, überhaupt kein Debrid-Dienst | NZB-Dateien in `nzbs/` werden zu Torrents. Lesevorgänge holen Artikel und yEnc-dekodieren sie bei Bedarf. Links sehen so aus: `nzb://<nzb-id>/<file-index>`, und sie werden lokal ausgeliefert. Deshalb synthetisiert `DownloadFile` die HTTP-Antwort, statt sie weiterzuleiten. |
| `internal/nntp` | Schlanker Usenet-Client | Verbindungspool, begrenzt durch das Verbindungskontingent des Accounts, BODY/STAT über Message-ID, yEnc-Dekodierung. Eine einzelne Verbindung bringt nur einen Bruchteil des möglichen Durchsatzes, deshalb verteilen sich die Lesevorgänge einer Datei auf das gesamte Kontingent. |
| `internal/par2` | PAR2 / Reed-Solomon über GF(2^16) | Wenn ein Artikel vom Server verschwunden ist, rekonstruieren die eigenen Recovery-Volumes des Releases die Bytes, die er enthalten hat. Das ist auf eine bestimmte Art teuer: Die Rechnung braucht jeden überlebenden Slice jeder abgedeckten Datei, genau einmal. Deshalb läuft sie als Hintergrundjob, jeweils ein Release nach dem anderen, und liefert Byte-Bereichs-Patches, die Lesevorgänge an Stelle der Lücken ausliefern. |
| `internal/rdclient` | Gemeinsames HTTP auf niedriger Ebene | Host-Rotation über CDN-Endpunkte, nach Latenz sortiert, Token-Bucket-Ratenbegrenzung, Retry mit Backoff, Proxy-Unterstützung, eigenes DNS, Erzwingen von IPv4/IPv6, Bevorzugung geografisch fixierter CDNs. `IPRepository` verwaltet den Netzwerktest und dessen Cache auf der Festplatte. |

`internal/nzb` ist der Beweis, dass die Abstraktion trägt. Es implementiert
dieselbe Schnittstelle über ein lokales Verzeichnis und einen News-Server, und
das funktioniert, weil der eigentliche Vertrag der Schnittstelle *„eine GET-Anfrage mit Bereich mit Bytes beantworten“* ist, nicht *„ein CDN weiterleiten“*.

### Ein Backend hinzufügen {#adding-a-backend}

Neues Paket: Implementiere `debrid.Provider`, rufe `debrid.Register` in `init` auf und füge einen Blank-Import in `internal/app.go` hinzu. Nichts in `internal/debrid` ändert sich.

## Ebene 3 — Die Bibliothek {#layer-3--the-library}

`internal/torrent` ist der Kern von zurg und das größte Paket. `TorrentManager`
hält die ganze Bibliothek in nebenläufigen `cmap`-Maps, damit Lesezugriffe ohne Sperren
auskommen. Er weist Torrents anhand der Filter aus der Konfiguration den Verzeichnissen zu, löst Links auf und
speichert sie zwischen, und er führt die Hintergrundjobs aus.

### Persistenz {#persistence}

Jeder Eintrag wird als JSON nach `data/<name>.zurgtorrent` geschrieben, und die Infos
zu jedem Torrent werden unter `data/info/` zwischengespeichert. Ein Neustart lädt alles von der Festplatte
und ist sofort wieder einsatzbereit. Danach wird aktualisiert. Das ist wichtig, weil ein kalter Scan
durch das Rate-Limit ausgebremst wird, nicht durch die CPU. Torrents, die das Konto verlassen haben,
können in `dump/` archiviert und als Verzeichnis `__dump__` angezeigt werden
(`load_dumped_torrents`).

Den Stand, den nichts anderes wiederherstellen kann (die Konfiguration, jede zurgtorrent-Datei, den `__magic__`-Speicher unter `data/local/` und die Quell-NZBs unter `nzbs/`), speichert ein einziges gestreamtes `.zurgbackup`.
`zurg backup` erstellt eins (ebenso wie die Seite Backup & Restore im Dashboard),
`zurg restore-backup <file>` entpackt es ins Arbeitsverzeichnis. `internal/backup` verwaltet das Format.
Ein Manifest ist der erste Eintrag, sodass eine Wiederherstellung prüft, was sie gerade enthält, bevor sie etwas schreibt.

Reservierte Verzeichnisnamen: `__all__`, `__unplayable__`, `__dump__`, `__downloads__` und pro Konto einer als `__<provider-name>__`.

### Torrent vs. TorrentCopy {#torrent-vs-torrentcopy}

Ein Release kann auf mehr als einem Account liegen. zurg zeigt es nur einmal an. Die Aufteilung:

- **Inhaltsfakten gehören zum Eintrag** (`Torrent`): Name, Hash, welche Dateien existieren, Tags, IMDB-ID, Rename.
- **Accountfakten gehören zu einer Kopie** (`TorrentCopy`): die Torrent-IDs, die dieser Account vergeben hat, die Links, die er ausgibt, sein eigener Broken-Status, seine Retry-Zähler.

Besonders die File-IDs gelten pro Account. Real-Debrid nummeriert Dateien innerhalb eines Torrents und markiert eine Teilmenge als selected. TorBox listet nur das, was es heruntergeladen hat, und nummeriert es auf eigene Weise. Deshalb speichert `FileSource` die `FileID` pro Provider. Repair baut seine Auswahl aus den IDs der Kopie, die es gerade repariert. Liest man die ID des falschen Accounts, werden die falschen Dateien erneut hinzugefügt.

Kopien werden in der Reihenfolge der Config gespeichert, und diese Reihenfolge ist die Präferenz. Lesevorgänge nehmen die erste gesunde Kopie und weichen bei Bedarf auf die nächste aus. Wenn du den Eintrag löschst, werden alle Kopien gelöscht. Ein Eintrag ohne Kopien existiert nicht.

### GetKey muss rein bleiben {#getkey-must-stay-pure}

`GetKey` ist der Name eines Torrents in der virtuellen Bibliothek: sein Verzeichniseintrag, sein `.zurgtorrent`-Dateiname und das Handle, über das jede Abfrage läuft. Er wird **bei jeder Abfrage neu berechnet und nie gespeichert**. Dadurch scheidet es aus, Namenskonflikte zu lösen, indem man prüft, was schon belegt ist. Die Antwort würde sich mit der Bibliothek ändern, und ein Torrent wäre unter dem Namen, unter dem er abgelegt wurde, nicht mehr auffindbar.

Das einzige Suffix gibt es für den selteneren Fall, dass zwei *verschiedene* Releases denselben Namen haben. Es ist ein Tag aus dem eigenen Hash des Inhalts und genauso eindeutig wie der Name selbst. Das Flag, das es aktiviert, wird vom Refresh-Durchlauf entschieden, der die ganze Bibliothek sehen kann, und am Torrent gespeichert.

### Hintergrundjobs {#background-jobs}

| Job | Datei | Was es macht |
|---|---|---|
| Refresh | `refresh.go` | Jeden Account abfragen, aufgelistete Instanzen zu Einträgen zusammenführen, Infos für neue abrufen, Verzeichnisse zuweisen und aufräumen (prune). Zwischen den vollen Abfragen wird ein günstiger Abruf eines einzelnen Elements als Änderungsprüfung genutzt. |
| Repair | `repair.go` | Kaputte Torrents finden und reparieren. |
| Downloads | `manager.go` | Die Liste der Hoster-Downloads in `__downloads__` aktualisieren. |
| Network test | `handlers` | Die CDN-Hosts regelmäßig neu bewerten. |

Das Intervall jedes Jobs lässt sich zur Laufzeit über einen Channel zurücksetzen. Wenn du die Konfiguration im Dashboard änderst, wirkt sich das also ohne Neustart aus.
Die Zeitstempel der letzten Ausführung werden gespeichert (`data/repair_timestamp`, `data/downloads_timestamp`), damit ein Neustart einen Job, der gerade gelaufen ist, nicht noch einmal startet.

### Reparatur {#repair}

Der zweitwichtigste Teil im Paket. Dateien tragen einen FSM-Zustand (`ok_file` / `broken_file`, über `pkg/fsm`), Torrents und Kopien haben jeweils ihren eigenen. Wenn Links keine Bytes mehr liefern, eskaliert die Reparatur über mehrere Strategien:

1. **Im Betrieb neu starten** (`TorrentRestarter`): die günstigste Variante. Es wird kein neuer Upload gebraucht, kein Add-Slot verbraucht, und der Torrent behält seine ID. Dadurch bleibt der Bibliothekseintrag erhalten und wird nicht gelöscht und neu entdeckt. Der Refresh stößt das für einen fehlgeschlagenen Torrent an, den er auf dem Account findet, aber nur auf einer Instanz, die überhaupt auf fehlgeschlagene Torrents reagieren darf: `enable_repair` oder `delete_error_torrents`. Sind beide aus, bleibt der Account unverändert (`mayRestartFailedTorrents`).
2. **Die defekten Dateien neu herunterladen**: nur die defekten Dateien werden erneut ausgewählt.
3. **Neu einfügen**: den Magnet-Link erneut hinzufügen und frische Links einsammeln.
4. **Archivieren**: der letzte Ausweg für Releases, die sich nicht retten lassen.
5. **Einem Account anbieten, der es nicht hat** (`repair_across_accounts.go`): Die Dienste haben unabhängige Caches. Ein Release, das ein Account gelöscht hat oder anhand des Dateinamens ablehnt, kann also auf einem anderen Account im Cache liegen. Sobald kein Account mit dem Release es mehr reparieren kann, werden die konfigurierten Accounts, die es nicht haben, der Reihe nach gefragt. Der erste, der den Hash schon hat, übernimmt es. Die Auflistung danach hängt es als zweite Kopie an den Eintrag, über den normalen `absorbCopy`-Pfad. Dabei wird das Urteil des Eintrags selbst zurückgesetzt. Es wird immer nur mit Cache-Treffern gearbeitet, über `AddIfCached`, niemals über `restrict_repair_to_cached`. Ein Add, den der Account erst holen müsste, wird zurückgezogen und wieder gelöscht. Das ist also eine Reparatur und nie ein erneuter Download. Ein Account, der nicht antwortet, wird zurückgestellt, und zwar von einem Tag bis etwa zwei Wochen. Ein Durchlauf macht höchstens zehn Angebote. Dadurch lohnt es sich, das ungefragt gegen eine Bibliothek mit verurteilten Releases laufen zu lassen.

Drumherum gibt es exponentielles Backoff, Wiederholungsobergrenzen pro Kopie (`RepairCycles`, `AssignRetries`, dauerhaft gespeichert, damit die Obergrenzen Neustarts überstehen), stündliche Add-Budget-Grenzen aus `Capabilities.AddsPerHour`, Prüfungen der aktiven Slots, Deduplizierung über eine set-basierte Warteschlange und eine heuristische Erkennung über den gesamten Durchlauf hinweg. Sie wertet eine Welle von Fehlern „Hoster nicht verfügbar“ als einen einzigen Ausfall des Anbieters und nicht als N kaputte Torrents. Nicht reparierbare Urteile werden pro Kopie gespeichert und wandern nur dann auf den Eintrag, wenn *jede* Kopie eines hat. Ein dauerhafter Fehler bei Real-Debrid sagt nichts über die TorBox-Kopie aus.

Ein Operator kann eine Reparatur manuell erzwingen. Das erzwungene Vorhaben hängt am Torrent und nicht am Kontext. Der Grund: Eine Anfrage, die mitten in einem Durchlauf eintrifft, wird in die Warteschlange gestellt und später unter dem eigenen Kontext des Durchlaufs abgearbeitet. Der Button erreicht auch Schritt 5, und zwar in dieser Reihenfolge. Zuerst löscht er alle Urteile zu dem Release, damit der Account, der es hat, genau wie vorher erneut versucht wird. Das Angebot kommt nur dann zum Zug, wenn dieser Versuch scheitert. Weil dabei die Urteile gelöscht werden, ist ein benannter Torrent berechtigt, wenn der Durchlauf seine verurteilten Einträge einsammelt, und wird erst durch die gerade gelaufene Reparatur erneut verurteilt. Er wird also nach dieser Reparatur eingesammelt und nicht in der Schleife. Sonst wäre der einzige Pfad, auf dem jemand wartet, genau der Pfad, der nie ein Angebot macht.

### Alles Übrige im Paket {#everything-else-in-the-package}

`mediainfo.go` (ffprobe-Analyse, liefert Dauer- und Codec-Tags), `tags.go`,
`rename.go` (Umbenennungen, die eine Aktualisierung überstehen müssen), `delete.go`, `strm.go`
(erzeugt `.strm`-Dateien für die gesamte Bibliothek), `hooks.go` (Benutzer-Skripte für Lebenszyklus-Ereignisse), `assign_links.go`, `unrestrict.go`, `opensubtitles.go`,
`provider_directories.go`, `reset_all.go`.

## Ebene 4 — Auslieferung {#layer-4--serving}

### Router

`internal/handlers` baut den chi-Router auf und verknüpft alles. Die nicht standardmäßigen WebDAV-Methoden (`PROPFIND`, `MKCOL`, `MOVE`) werden beim `init` bei chi registriert. Basic Auth umschließt alles *außer* `version.txt` und `/ready` (damit Health Checks funktionieren) und die `.strm`-Endpunkte. Ein Medienplayer, der eine `.strm` öffnet, hat nämlich keine Zugangsdaten anzubieten. Stattdessen autorisiert das signierte Token im Pfad den Zugriff.

Zwei Routing-Lektionen stehen in den Kommentaren, und man sollte sie sich besser gleich merken: chi wendet einen Regex-Pfadparameter **innerhalb eines einzelnen Segments** an. Deshalb passte eine Datei, die über ein Archiv adressiert wird (`<archive>.rar/<inner>.mkv`), oder ein verschachteltes Verzeichnis darin auf keine Route. Beide brauchten Wildcards am Ende. Außerdem wird ein Pfad innerhalb eines Torrents zwischen Auflistung und Download anhand des abschließenden Schrägstrichs unterschieden, sobald die Route nicht mehr darauf achtet, wie tief der Pfad ist.

### Auflistungen {#listings}

`internal/dav` erzeugt PROPFIND-XML und verarbeitet DELETE, MOVE (Umbenennungen, mit Prüfung über Verzeichnisse und Torrents hinweg) sowie die Infuse-Varianten.

`pkg/dav` erstellt das XML selbst mit optimiertem String-Aufbau statt XML-Marshalling, wandelt RFC 3339 in RFC 1123 um, wie es WebDAV-Clients verlangen, und maskiert Pfade sowohl für URL als auch für XML.

`internal/htmlindex` stellt denselben Baum als HTML für `/http/` dar.

Beide wenden dieselben Sichtbarkeitsregeln an (nur die größte Datei, Größenschwellen, Status kaputt/gelöscht), und beide fassen mehrteilige RAR-Archive zusammen, sodass nur der erste Teil sichtbar ist.

### Der Byte-Pfad {#the-byte-path}

`internal/universal` ist der Teil, in dem aus einer Anfrage Bytes werden:

- Die Auflösung von Links wird mit `singleflight` dedupliziert. Hundert gleichzeitige Reads derselben Datei kosten also nur eine einzige Auflösung.
- Proxy oder Redirect, abhängig von `disable_stream_proxy`. Ausnahme: Ein lokal ausgelieferter Link (`ServesLinksLocally`) wird nie weitergeleitet, weil der Client nichts hat, was er öffnen könnte.
- Erneutes Unrestrict bei einem kaputten Link, aber nur bis zu einer kleinen Obergrenze.
- Ein Netzwerkfehler-Cooldown pro Datei: Nach 3 Fehlern in Folge wird die Datei für 5 Minuten geparkt. Das verhindert, dass ein nicht erreichbarer CDN-Host zu einer endlosen Retry-Schleife wird.
- Kurze Wartezeiten während eines Rate-Limit-Fensters, statt Fehler zu werfen. Wenn Reads während des kurzen Cooldowns fehlschlagen, wird ein gedrosselter Account über rclones VFS zu einem Fehlersturm: hängende Waiter, Reader im D-State, ein blockierter Media-Server. Deshalb ist ein gehaltener Read die günstigere Lösung. Längere Cooldown-Klassen schlagen weiterhin sofort fehl.
- Bandbreitenzählung pro Token, wobei die Zähler um Mitternacht CET zurückgesetzt werden, passend zum täglichen Traffic-Reset von Real-Debrid.

### Archive {#archives}

`internal/rarstream` parst RAR4-, RAR5- und ZIP-Header über Byte-Range-Anfragen (HTTP 206), baut eine Chunk-Map über alle Volumes hinweg auf und setzt den Inhalt einer einzelnen Datei im laufenden Betrieb wieder zusammen. **Keine Dekomprimierung**: Es werden nur gespeicherte Daten unterstützt, und genau so sind Scene-Releases aufgebaut. `VolumeKey` und `IsVolume` normalisieren die vielen Namensschemata für mehrteilige Archive (`.part001.rar`, `.r00`, `.rar`), die `dav` und `htmlindex` nutzen, um Volumes zu einem einzigen Eintrag zusammenzufassen. Listings werden am Torrent zwischengespeichert und mit der `ListingVersion` des Parsers markiert. Ein Listing, das von einem anderen Parser erzeugt wurde, wird deshalb verworfen und nicht ausgeliefert.

### STRM

`internal/strmlink` kodiert und signiert die URL, die eine `.strm` enthält. Die reine Real-Debrid-Lösung, die dabei ersetzt wird, war nur durch Zufall sicher: Die URL enthielt den 13-stelligen Download-Code von RD, und wer ihn besaß, *war* damit schon autorisiert. Andere Backends adressieren Dateien über trivial aufzählbare IDs (`torbox://17/3`). Mit dem gleichen Aufbau könnte also jeder, der den Port erreichen kann, CDN-URLs für das Konto erzeugen oder die Usenet-Server-Verbindungen des Kontos verbrauchen. Ein HMAC über ein Geheimnis in `data/strm_secret` schließt diese Lücke: Ein Token, das zurg nicht selbst geschrieben hat, wird nicht aufgelöst. Das Geheimnis muss den Prozess überdauern. Jede `.strm`-Datei, die schon geschrieben wurde, bleibt nur so lange gültig, wie ihr Signierschlüssel gültig ist.

### Dashboard und Verwaltung {#dashboard-and-management}

`internal/handlers/dashboard` rendert die Web-UI aus eingebetteten Templates,
die beim Start vorgeparst werden, damit ein Syntaxfehler sofort auffällt und nicht erst beim Request.
Seiten: Live-Status der Torrents, ein interaktiver YAML-Config-Editor, Host-Latenz,
Verzeichnisverwaltung, Provider-Verwaltung, Verbindungsstatus der Media-Server,
Konto- und Premium-Infos, Bandbreite, rclone-Status und Plex-„Wrapped"-Statistiken.
Die Status-Abfragen für jeden Media-Server laufen parallel, damit die Seiten flott laden.

`internal/handlers/manage` ist die Bedienoberfläche für die Operationen pro Torrent: Tags, Dateilisten mit Statusdetails, Plex-Matching, Umbenennungen, Löschen, Wiederherstellen und Force-Show pro Datei, Massenlöschen und Scan.

Die Duplikat-Ansicht dafür ist `internal/duplicates`. `internal/arrinventory` und die `Inventory`-Reader neben den Radarr- und Sonarr-Adaptern lesen jede Datei, die ein \*arr verwaltet, nur lesend und unabhängig von der Beschaffung. `magic.Resolver.HolderOf` verfolgt den Pfad jeder Datei zurück zu dem Release, aus dem sie stammt, und das Paket gruppiert Releases, die denselben Film oder dieselben Episoden enthalten könnten.
Für die Gruppierung werden Namen, IMDb-IDs und der \*arr-Verlauf verwendet.
Ob ein Release in Benutzung ist, wird allein anhand der verfolgten Pfade entschieden.

`internal/static` bettet CSS, Favicon, Logo und robots.txt mit `go:embed` ein, damit das Binary ohne externe Dateien auskommt.

## Ebene 5 — Das Mount {#layer-5--the-mount}

`internal/rclone` überwacht rclone als Subprozess: Es baut den Mount-Befehl (ein WebDAV-Remote, das auf zurgs eigenes `/dav/` zeigt), startet und stoppt ihn, prüft alle 30 s den Zustand mit exponentiellem Neustart-Backoff (1 s → 60 s) und startet ihn bei Fehlern neu.

Beim Start wird ein temporärer RC-Port im Bereich 49152–65535 gewählt, für die Invalidierung des VFS-Caches und für Statusabfragen. Diese Invalidierung ist an zwei Zeitpunkten wichtig: sobald die gecachte Bibliothek fertig geladen ist, und noch einmal nach dem ersten vollständigen Refresh. Sonst bleiben die unvollständigen Verzeichnislisten, die der Mount mitten im Laden erwischt hat, für die gesamte Dauer von `--dir-cache-time` hängen.

Zugangsdaten werden über eine Umgebungsvariable übergeben, niemals auf der Kommandozeile. `Controller` ist das Interface, das Handler und das Dashboard nutzen. `Runner` und `Command` abstrahieren die Prozessverwaltung für Tests.

## Ebene 6 — Medienserver {#layer-6--media-servers}

Zwei verschiedene Dinge tragen das Wort „Plex“:

- **`pkg/plex`, `pkg/jellyfin`, `pkg/emby`** sind Clients für Medienserver. Jeder erfüllt `common.MediaServerWorker`. `pkg/common` stellt den gemeinsamen Job-Lebenszyklus bereit: eine unbegrenzte, dynamische Warteschlange, die Verfolgung der Wiederholungsversuche pro Job, exponentielles Backoff mit Jitter, einen Circuit Breaker nach aufeinanderfolgenden Fehlern und die Erkennung hängender Jobs. Außerdem enthält es die Pfad-Hilfsfunktionen für das case-insensitive APFS von macOS. `pkg/scan` liegt darüber als einheitlicher `MediaScanner`. Er leitet einen Job zum Aktualisieren eines Pfads an den Server weiter, dem dieser Pfad gehört, und meldet die Warteschlangenlänge pro Server.
- **`internal/plex`** enthält das zurg-spezifische Verhalten. Der `Matcher` ordnet Torrents Plex-Bibliothekseinträgen zu. Dafür nutzt er Dateipfade, IMDB-IDs und TVDb/TMDb-IDs. Er läuft regelmäßig in Worker-Pools mit gecachten Metadaten und trägt gefundene IMDB-IDs nachträglich in die Torrents ein.
- **`internal/acquisition`** verwaltet die persistente Acquisition-Warteschlange und den gemeinsamen Executor. Der holt NZBs von Newznab-Indexern und gecachte Torrents von Torznab-Indexern. Die Plex-Watchlist, Seerr, Radarr und Sonarr sind Quell-Adapter. Sie wandeln Anfragen in Ziele für Filme, Staffeln oder Episoden um. `data/acquisition.json` speichert Wiederholungs-Deadlines und den Fortschritt pro Ziel über Neustarts hinweg. Konfiguration und Adapter-Verträge findest du unter [Acquisition-Quellen](../guides/acquisition.md).

`pkg/mediabrowser` enthält die Typen, die Emby und Jellyfin gemeinsam nutzen.

## Ebene 7 — Support {#layer-7--support}

| Package | Purpose |
|---|---|
| `pkg/fsm` | Zwei Varianten einer kleinen State Machine: `FSMWithExternalMutex` für den Fall, dass die FSM in etwas eingebettet ist, das schon gesperrt ist, und `FSMWithTime` für den Fall, dass sie ein eigenes Lock und einen Zeitstempel für den Übergang braucht (damit `SinceWhen` beantworten kann, "wie lange ist das schon kaputt"). |
| `pkg/logutil` | Zap mit doppelter Ausgabe: farbige Konsole und eine rotierende Datei (10 MB × 20 über lumberjack). Die Verbosität kommt aus `log_level` in config.yml. Fehlt das, wird die Umgebungsvariable `LOG_LEVEL` verwendet und danach DEBUG. Das Level liegt in einem gemeinsamen `zap.AtomicLevel`, damit das Dashboard alle Logger auf einmal neu setzen kann, ohne Neustart. Enthält außerdem das Auslesen der Logs für den Dashboard-Viewer und für Export Logs. |
| `pkg/utils` | Speichern der blockierten Hosts, Regeln für die Sichtbarkeit von Dateien, Schwärzen von Tokens, Erkennung von Video/Audio, `.strm`-Benennung und `GetZurgBaseURL` (berücksichtigt `X-Forwarded-*` hinter einem Reverse Proxy). |
| `pkg/script` | Führt die benutzerdefinierten Lifecycle-Event-Skripte aus. Unter Windows PowerShell, sonst `/bin/sh`. |
| `pkg/dmm` | Client für die Such-API von debridmediamanager.com, gedrosselt auf die serverseitige Grenze von 1 Anfrage pro 2 Sekunden. Wird vom Watchlist-Monitor genutzt. |
| `internal/version` | Build-Metadaten, die über ldflags eingebunden werden. Außerdem das ASCII-Banner unter `/http/version.txt`. |
| `internal/requirements` | Lädt beim ersten Start die passenden `ffprobe`- und `rclone`-Versionen für die Plattform von GitHub-Releases herunter und schreibt *relative* Pfade in config.yml, damit die Config portabel bleibt. Nicht unterstützte Plattformen geben eine Warnung aus, statt abzubrechen. |
| `internal/clear` | Löscht in großen Mengen RD-Downloads und Torrents, indem es die Weboberfläche mit einem Auth-Cookie steuert. Wiederholt das, bis alles leer ist. |
| `internal/handlers/tmplcache` | Template-Caching für das Dashboard. |

## Querschnittsentscheidungen {#cross-cutting-decisions}

**Capabilities statt `if provider == "realdebrid"`.** Alles, was Real-Debrids Aufbau voraussetzt, gehört hinter ein Capability-Flag und nicht hinter eine Typprüfung. Diese Regel sorgt dafür, dass der Torrent-Manager backend-unabhängig bleibt.

**Der Vertrag des Interfaces sind Bytes, kein Proxying.** `Provider` verspricht nie einen entfernten CDN, sondern nur, dass ein GET mit Range-Header beantwortet werden kann. Deshalb passt auch ein Usenet-Backend dazu. Die zwei Stellen, an denen die CDN-Annahme doch durchgesickert ist (Weiterleitungen und das Übergeben einer URL an ffprobe, das etwas braucht, was ein externes Programm öffnen kann), sind jetzt beide durch `ServesLinksLocally` abgesichert.

**Die positionelle Link-Zuordnung ist tragend.** `TorrentInfo.Links[i]` gehört zur i-ten **ausgewählten** Datei in `TorrentInfo.Files`. Ein Provider, der für eine Datei keinen Link erzeugen kann, muss sie als *nicht ausgewählt* melden und darf sie nicht einfach weglassen. Sonst löst jede spätere Datei stillschweigend auf den falschen Link auf. Jedes Backend muss das einhalten.

**Ein Torrent gehört genau zu einem Account.** Jeder Aufruf, der an einen Dienst geht, muss über den Provider des Torrents laufen (`ProviderFor`, `resolveLink`, `verifyLink`, `DeleteByID`) und nie über den primären Provider. Wer das falsch macht, löscht im falschen Account.

**Die Festplatte ist eine echte Ebene.** `.zurgtorrent`-Einträge, `data/info/`-Details pro Torrent, Ergebnisse und Zeitstempel von Netzwerktests, Job-Zeitstempel, das Signing-Secret für STRM, RAR-Listen-Caches und gesperrte Hosts. Ein Neustart setzt also dort fort, wo er aufgehört hat, statt alles neu zu scannen.

**Alles wird gedrosselt.** Token-Buckets pro Provider, Parallelitätsgrenzen, stündliche Add-Limits, Link-TTLs, Cooldowns pro Datei und Rate-Limit-Sperren. Gerade bei TorBox ist die Link-Auflösung die knappste Ressource, und der Link-Cache davor ist der Grund, warum ein Bibliotheksscan überhaupt bezahlbar ist.

**Lesen ist lock-frei, Schreiben ist eng begrenzt.** Concurrent Maps halten die Verzeichnis-, Torrent- und Datei-Bäume. Änderungen werden über Locks pro Torrent geschützt (`copiesMu`, `tagsMutex`, `operationsMutex`, `archiveCacheMutex`) und nicht über ein globales Lock.

**`rdclient` wird geteilt, aber seine Regeln sind die von Real-Debrid.** Die Fehlerklassifizierung und die Retry-Regeln stammen von RD. Es meldet jede Antwort außerhalb von 2xx als Fehler, gibt aber trotzdem die Response zurück. Ein Provider, der den Status braucht, etwa ein 429 mit `Retry-After`, muss deshalb zuerst `resp` prüfen und erst dann `err`.

## Bauen, testen, deployen {#build-test-deploy}

- **Build**: `make build`. Version, Commit und Build-Zeit werden per
  ldflags in `internal/version` eingetragen.
- **Unit-Tests**: `go test ./...`. Pre-commit führt gofmt, golangci-lint,
  `go test -short` und eine vollständige Qualitätstestsuite aus.
- **Integrationstests**: `make integration-test`, die günstigsten zuerst, mit
  `refresh_repair` ganz zum Schluss, weil dieser Test auf einen kompletten
  Bibliotheks-Scan wartet. Führ sie auf einem Host aus, auf dem Go, rclone, FUSE
  und Plex zusammen laufen. Auf anderen Systemen werden die Mount- und Plex-Tests
  zwar laut übersprungen, das Programm endet aber trotzdem mit Exit-Code 0. Lies
  deshalb die Ausgabe und nicht nur den Exit-Code. Siehe [e2e-test.md](e2e-test.md).
- **Docker**: zweistufiger Alpine-Build; das Runtime-Image bringt zusätzlich ffmpeg,
  rclone, fuse3 und einen Healthcheck mit.
- **Deploy**: `make deploy USER=… HOST=… DIR=…`. Dabei werden Plex und die
  zurg-Dienste gestoppt, das Binary ausgetauscht, gewartet, bis `version.txt` mit 200
  antwortet, und danach Plex neu gestartet.

## Wo du zuerst schauen solltest {#where-to-look-first}

Die Kommentare in dieser Codebasis erklären durchgehend *warum* etwas so ist. Meistens steckt dahinter der Fehler, der den Code überhaupt nötig gemacht hat. Jedes Paket hat eine `doc.go`. Wenn du etwas änderst, lies zuerst die `doc.go` dieses Pakets und den Blockkommentar über dem Typ, den du anfasst. Dort stehen die Einschränkungen, die man aus den Signaturen nicht sieht.
