# Die Debrid-Basislinie {#the-debrid-baseline}

Was zurg kostet und wie schnell es sich auf dem **Debrid**-Pfad anfühlt, also mit Real-Debrid, AllDebrid und TorBox. Hier gibt es keinen Konkurrenten. Der Herausforderer ist eine spätere zurg-Version, und diese Datei ist das, was sie schlagen muss.

- **Getestete Build-Version:** `23869fa4` (`2026.08.18.0140-nightly-48-g23869fa4`)
- **Gemessen:** 2026-08-19, auf `zen` (2 Kerne, 7,6 GB, Ubuntu 22.04)
- **Testaufbau:** `scripts/dbench/`, auf zen unter `~/dbench` installiert

## So liest man es {#how-to-read-it}

Die drei Anbieter sind auch keine drei Konkurrenten.
Ihre Bibliotheken unterscheiden sich um zwei Größenordnungen – 3416 Torrents auf Real-Debrid, 479 auf TorBox, 14 auf AllDebrid –, deshalb sagt eine absolute Cold-Build-Zeit mehr über den Account aus als über zurg.
Deshalb wird jede größenabhängige Zahl auch pro Torrent angegeben, und der Vergleich, der wirklich zählt, ist immer **dieser Build gegen den nächsten auf demselben Account**.

Was über Anbieter hinweg wirklich vergleichbar ist, ist die *Form* der Kosten: wie viele API-Aufrufe ein Backend pro Torrent braucht, ob es überhaupt für die Link-Prüfung bezahlt, und ob sein Change-Poll eine Seite oder ein Token ist.

## Konfiguration {#configuration}

Jede Instanz nutzt genau einen Provider, auf ihrem eigenen Port und mit ihrem eigenen Datenverzeichnis. Die
Abweichungen von den ausgelieferten Standardwerten gibt es nur dort, wo die Isolation sie erfordert:

| Einstellung | Testaufbau | Warum |
|---|---|---|
| `host` / `port` | `127.0.0.1`, 9991-9994 | vier Instanzen auf einem Host |
| `providers` | eine pro Instanz | Kosten einem Backend zuordnen |
| `rclone_enabled` | `false` | gemessen über HTTP, nie über FUSE |
| `directories` | ein `all`, ohne Filter | Kosten für das Auflisten hängen von der Bibliotheksgröße ab |
| `enable_repair` | `false` | Eine andere zurg-Instanz war mit demselben TorBox-Konto geladen, und nur eine Instanz darf ein Konto reparieren |

Alles andere bleibt absichtlich auf dem ausgelieferten Standardwert, auch zwei Einstellungen, die die Zahlen ungünstig beeinflussen und selbst Erkenntnisse sind:

- `log_level: DEBUG` — Der ausgelieferte Standardwert (`pkg/logutil/factory.go`).
- `torrents_rate_limit_per_minute: 75` — Der ausgelieferte Standardwert und die bindende Grenze beim Kaltstart eines Real-Debrid-Builds.

## Korpus {#corpus}

Zwölf Releases mit den **gleichen Infohashes bei allen drei Accounts**, damit ein Unterschied zwischen den Providern vom Provider kommt und nicht von der Datei. Die Größen reichen von einer 1,5-GB-Episode bis zu einem 334-GB-Remux-Pack. Bei den Formen gibt es Einzeldatei-Filme, Staffel-Packs und ein Serien-Pack mit 349 Dateien. Eintrag 0, `The Shawshank Redemption (1994) DS4K`, 7,31 GB, eine Datei, ist das Streaming-Testobjekt für die Latenz- und Durchsatz-Phasen.

Der Aufbau war der knifflige Teil und lohnt sich festzuhalten. Der TorBox-Cache überschneidet sich nur etwa 2 % mit der Real-Debrid-Bibliothek (3 Treffer bei 136 Abfragen). Deshalb musste der Korpus von der TorBox-Seite aus gefüllt werden und nicht von Real-Debrid aus. AllDebrid hatte nichts im Cache, nahm die Magnet-Links aber sofort an, 14 von 16. Real-Debrid brauchte zwischen den Hinzufügungen 20–45 s Abstand wegen der Drosselung bei 451 und hat zwei abgelehnt. Eine davon ist die dokumentierte deterministische Namenssperre (`Supergirl…WEB-DL…`). Die wurde beim ersten Versuch ohne Vorgeschichte abgelehnt, nachdem es drei Minuten lang ruhig war. Die andere blieb gedrosselt.

## API-Kosten messen {#measuring-api-cost}

zurg führt keinen Zähler für ausgehende Anfragen. `log_requests` überspringt bewusst zwei Real-Debrid-Endpunkte, `torrents/activeCount` und `torrents?limit=1&…`, die zusammen die gesamte Change-Detection-Abfrage ausmachen. Würde man die Zahl aus dem Log ermitteln, würden die Leerlaufkosten von Real-Debrid also als null erscheinen.

Deshalb zählen wir außerhalb des Prozesses. mitmproxy beendet die TLS-Verbindung, ein Addon schreibt pro Anfrage eine JSONL-Zeile, und die Instanz wird mit `HTTPS_PROXY` und `SSL_CERT_FILE` gestartet, die auf die abfangende CA zeigen. Go's x509-Loader berücksichtigt `SSL_CERT_FILE`. Das Vertrauen gilt also nur für diesen einen Prozess, und auf dem Host wird nichts verändert. Anfragen werden als `api`, `nettest`, `content` oder `other` klassifiziert.

Der Proxy liegt im Anfragepfad, deshalb nutzen wir ihn nur für die Phasen mit API-Kosten. Die Zeitmessungen laufen direkt. Bei TorBox, wo der gesamte Build aus vier Aufrufen besteht, kamen ein Lauf über den Proxy und ein direkter Lauf auf 3.0 s bzw. 4.0 s. In dieser Größenordnung liegt der Proxy also im Rauschen.

## Ergebnisse {#results}

Alle Zahlen stammen aus Build `23869fa4` auf zen, 2026-08-19. Latenz und Durchsatz stammen aus einem einzigen verschachtelten Durchlauf über dieselbe 7.31 GB große Datei – gleicher Infohash auf allen drei Konten, und `ffprobe` meldet über alle drei die identische Dauer von 8552.574 s, der Inhalt ist also tatsächlich byte-identisch.

### Kaltaufbau der Bibliothek {#cold-library-build}

Leere Caches zu einer kompilierten Bibliothek. Das ist die eine Zahl, die sich zwischen den Anbietern nicht vergleichen lässt: Die Konten unterscheiden sich um zwei Größenordnungen. Schau dir deshalb die Spalten pro Torrent an.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Torrents | 3,316 | 14 | 479 |
| Zeit bis kompiliert | **1,774 s** | 1.0 s | 3.0 s |
| Sekunden pro Torrent | 0.535 | 0.071 | 0.006 |
| API-Anfragen | **7,442** | 7 | 4 |
| API-Anfragen pro Torrent | **2.24** | 0.50 | 0.008 |
| Nicht-2xx-Antworten | **756 (10.2%)** | 0 | 0 |
| Empfangene API-Bytes | 2.87 MB | 27.9 KB | 298 KB |
| Netzwerktest-Anfragen beim Start | 88 | 88 | 88 |
| Peak RSS | 77 MB | 26 MB | 52 MB |
| CPU-Sekunden | 17.5 | 0.04 | 0.5 |

Die 7,442 Aufrufe von Real-Debrid teilen sich so auf: 3,414 `torrents/info`, also einer pro Torrent. Das lässt sich ohne `ListIncludesFiles` nicht vermeiden. Dazu kommen **3,992 `unrestrict/link`**, die proaktive Link-Prüfung. Real-Debrid ist das einzige Backend mit `StoredLinksCanRot: true`. Deshalb zahlt nur Real-Debrid diesen Preis. TorBox beantwortet den ganzen Scan mit einem einzigen `mylist`. Genau das bringt `ListIncludesFiles`.

Der Real-Debrid-Build wurde zweimal ausgeführt. Die beiden Läufe stimmen so genau überein, dass eine Verbesserung in einem künftigen Build kein Rauschen sein wird:

| | Lauf 1 | Lauf 2 |
|---|---|---|
| Zeit bis kompiliert | 1,774.5 s | 1,759.5 s |
| API-Anfragen | 7,442 | 7,391 |
| `unrestrict/link` | 3,992 | 3,933 |
| Nicht-2xx | 756 | 699 |
| CPU-Sekunden | 17.5 | 16.1 |

#### Was die Fehler sind {#what-the-failures-are}

Der zweite Lauf hat sein Flow-Log behalten, deshalb gibt es für die 699 eine Aufschlüsselung:

| Status | Anzahl | Endpunkt |
|---|---|---|
| 429 | 589 | `unrestrict/link` |
| 503 | 85 | `unrestrict/link` |
| 404 | **22** | `downloads/delete/{id}` |
| 451 | 3 | `unrestrict/link` |

Zwei getrennte Probleme, und keines davon ist „der Anbieter war wackelig“:

- **589 Rate-Limit-Ablehnungen**, alle bei `unrestrict/link`. `api_rate_limit_per_minute` steht standardmäßig auf 250 und hält unrestrict nicht innerhalb dessen, was Real-Debrid tatsächlich erlaubt. Dadurch sind grob 8 % des Kaltaufbaus Ablehnungen und Wiederholungen.
- **22 von 23 `downloads/delete`-Aufrufen haben 404 zurückgegeben.** Die Bereinigung, die die 3.992 Unrestricts ausgleichen soll, ist nicht nur selten, sie schlägt beim Ausführen fehl: Sie löscht IDs, die es nicht gibt. Jeder Unrestrict legt einen dauerhaften Eintrag in der Downloads-Liste des Kontos an, und nach diesen Scans hatte das Testkonto **12.469** Einträge.

Eine Zahl hat sich zwischen den Läufen verändert und ist noch nicht erklärt: Die HEAD-Abfragen gegen `*.download.real-debrid.com` waren im ersten Build 88 und im zweiten **3.426** (etwa eine pro Torrent). Sie korreliert damit, dass die Downloads-Liste gewachsen ist, und der zweite Lauf hat `/downloads` außerdem achtmal abgerufen gegenüber einmal beim ersten. Das ist aber eine Korrelation und keine Ursache. Das sollte geklärt werden, bevor man daran optimiert.

### Warmer Neustart {#warm-restart}

Die Kaltstartkosten fallen wirklich nur einmal an.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Zeit bis kompiliert | 4.0 s | 1.0 s | 2.0 s |
| API-Anfragen | 17 | 6 | 4 |
| Netzwerktest-Anfragen | 8 | 0 | 0 |
| Peak RSS | 77 MB | 27 MB | 39 MB |

1,774 s werden zu 4.0 s, und 7,442 Aufrufe werden zu 17.

### Ruhezustand {#idle-steady-state}

Zehn Minuten einer voll geladenen Bibliothek ohne Aktivität. Die Rangfolge richtet sich danach, wie günstig jedes Backend abgefragt werden kann. Das zeigt sehr deutlich, warum `LibraryFingerprinter` existiert.

| | API-Aufrufe/Min | API-Bytes/Min | CPU s / 10 Min | Peak RSS | Was gesendet wird |
|---|---|---|---|---|---|
| AllDebrid | **4.0** | **867** | 0.20 | 28 MB | ein Live-Mode-Delta pro Abfrage, leer wenn unverändert |
| TorBox | 7.9 | 43.6 KB | 0.33 | 53 MB | blättert durch `mylist` — kein Delta-Feed, keine Cache-Validatoren |
| Real-Debrid | 11.4 | 59.8 KB | 0.43 | 85 MB | `torrents?limit=1` + `activeCount`, plus `/downloads` |

Real-Debrid verbraucht 32 seiner 114 Aufrufe für das erneute Auflisten von `/downloads` – dieselbe Liste, die beim Kaltaufbau auf 12.469 Einträge angewachsen ist.

Dass die Zählung über einen Proxy statt über `log_requests` läuft, hat ebenfalls damit zu tun: 80 der 114 Leerlauf-Aufrufe von Real-Debrid gehen an die zwei Endpunkte, die `ShouldSkipLogging` unterdrückt. Das Log hätte die Leerlaufkosten also praktisch auf null geschätzt.

### Auflistung {#listing}

Nirgends ein Engpass, egal wie groß die Bibliothek ist.

| | Real-Debrid (3,312) | AllDebrid (14) | TorBox (479) |
|---|---|---|---|
| PROPFIND ganze Bibliothek, Depth 1 | 26 ms / 1.17 MB | 1 ms / 5.1 KB | 7 ms / 172 KB |
| HTML-Index | 14 ms / 645 KB | 1 ms / 2.4 KB | 3 ms / 90 KB |
| PROPFIND ein Release, Depth 1 | 1 ms | 11 ms | 3 ms |

### Auf Play drücken {#press-play}

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Kaltes Öffnen, 1 MB | 1.294 s | **0.476 s** | 0.565 s |
| Zeit bis zum ersten Byte, 64 MB | **0.158 s** | 0.203 s | 0.208 s |
| Scrub, Median aus 8 | 0.343 s | **0.259 s** | 0.356 s |
| Warmes erneutes Lesen, 64 MB | 2.065 s | 2.163 s | **1.960 s** |
| ffprobe | 1.98 s | 1.34 s | **0.99 s** |
| RSS | 75 MB | **30 MB** | 50 MB |

**Das warme erneute Lesen ist genauso langsam wie das kalte Lesen.** Beim Usenet-Pfad kommt
ein wiederholtes Lesen in 0.05-0.17 s aus dem 512-MB-LRU zurück. Hier kostet es dagegen einen
vollen Abruf, weil der Debrid-Pfad den CDN-Traffic nur durchreicht und nichts zwischenspeichert. Mit `rclone_enabled: false`
läuft das nur über zurg allein. In einer normalen Installation fängt der VFS-Cache von rclone das ab. Als Eigenschaft von zurg selbst gibt es aber gar keinen Warm-Pfad.

### Durchsatz {#throughput}

256 MB sequentielle Lesevorgänge, drei Wiederholungen, Reihenfolge wechselt zwischen den Wiederholungen.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Mittelwert MB/s | 25.75 | 27.21 | **35.96** |
| Min-Max MB/s | 20.09-29.57 | 17.52-32.21 | **34.31-37.57** |
| CPU s pro GB | 7.8 | **5.3** | 7.9 |
| TTFB-Median | 1.023 s | **0.267 s** | 0.489 s |
| Peak RSS | 88 MB | **29 MB** | 55 MB |
| Abgeschlossene Lesevorgänge | 3/3 | 3/3 | 3/3 |

TorBox ist sowohl am schnellsten als auch mit Abstand am stabilsten. Die anderen beiden schwanken
zwischen den Wiederholungen um 40%. Der TTFB-Median von Real-Debrid unter Last ist viermal so hoch wie der von AllDebrid.

### Wohin der Kaltstart-Öffnen tatsächlich geht {#where-cold-open-actually-goes}

`apiref.py` misst den eigenen Anteil des Anbieters: den Aufruf, der eine gespeicherte Datei in eine abrufbare URL umwandelt, und das erste Byte von dieser URL. zurg ist dabei nicht im Spiel. Es lief zweimal. Der erste Lauf kommt noch vor dem AllDebrid-Fix, deshalb hat diese Zeile nur eine Messung.

| | resolve | CDN TTFB | Anbieter gesamt | zurg Kaltstart | Anteil von zurg |
|---|---|---|---|---|---|
| Real-Debrid, Lauf 1 | 0.133 s | 0.267 s | 0.400 s | 1.294 s | **0.89 s** |
| Real-Debrid, Lauf 2 | 0.157 s | 0.383 s | 0.540 s | 1.294 s | **0.75 s** |
| AllDebrid | 0.139 s | 0.333 s | 0.472 s | 0.476 s | 0.00 s |
| TorBox, Lauf 1 | 0.260 s | 0.277 s | 0.537 s | 0.565 s | 0.03 s |
| TorBox, Lauf 2 | 0.270 s | 0.381 s | 0.651 s | 0.565 s | ~0 |

Die Anbieter-Werte und die zurg-Werte stammen aus unterschiedlichen Momenten. Die Subtraktion ist deshalb eher ein Richtwert als exakt. Das Muster bleibt in beiden Läufen gleich: AllDebrid und TorBox kosten praktisch nichts zusätzlich zu dem, was der Anbieter selbst braucht. Real-Debrid kommt 0.75 bis 0.89 s obendrauf. Diese Lücke ist das eindeutigste Ziel, an dem wir ansetzen sollten.

### Alle drei Anbieter in einer Instanz {#all-three-providers-in-one-instance}

Die zusammengeführte Instanz enthält alle Accounts gleichzeitig, und das Testkorpus liegt absichtlich auf allen dreien. So wird der Fall getestet, in dem ein Release von mehreren Accounts gehalten wird.

| | Nur Real-Debrid | Alle drei zusammengeführt |
|---|---|---|
| Gesehene Torrents | 3,316 | 3,781 |
| Eindeutige Releases | 3,318 | 3,778 |
| Zeit bis zum Kompilieren | 1,774 s | 1,775 s |
| API-Anfragen | 7,442 | 7,491 |
| Peak RSS | 77 MB | 82 MB |
| PROPFIND ganze Bibliothek | 26 ms / 1.17 MB | 23 ms / 1.34 MB |

TorBox und AllDebrid zu einer Real-Debrid-Instanz hinzuzufügen kostet fast nichts: 465 zusätzliche Torrents für 49 zusätzliche API-Aufrufe und 5 MB RSS, und keine messbare Zeit. Die Zusammenführung ist echt. 3,809 Torrents über die drei Accounts getrennt werden hier zu 3,781, das Korpus schrumpft also von drei Kopien auf eine.

### Erkennung von Hinzufügungen und Löschungen {#add-and-delete-detection}

Wie lange es vom Änderungsereignis beim Anbieter bis zur Übereinstimmung des Mounts dauert.

| | Delete erkannt | Add erkannt |
|---|---|---|
| Real-Debrid | 18.7 s | 12.7 s |
| AllDebrid | 16.5 s | 14.4 s |

Beide liegen innerhalb eines Durchlaufs von `check_for_changes_every_secs` plus einer Aktualisierung. Keiner von beiden wartet also auf `library_resync_every_mins`. TorBox wurde nicht getestet: Das Probe-Release liegt dort dauerhaft auf dem Konto, und ein Löschen ist nicht rückgängig zu machen, ohne es neu hinzuzufügen. Das könnte aber nicht im Cache sein.

### Anbieterausfall, CDN ist erreichbar {#provider-outage-cdn-up}

`ca/outage.py` lässt jeden Provider-API-Aufruf mit 503 antworten, während Content-Anfragen weiterhin durchgehen. Danach wird zurg mitten in den Ausfall gestartet.

| | Lesen vorher | Bibliothek während Ausfall aufgebaut | Lesen während Ausfall |
|---|---|---|---|
| Real-Debrid | 206, 1.60 s | nie (180 s) | Timeout nach 120 s |
| AllDebrid | 206, 0.44 s | nie (180 s) | Timeout nach 120 s |
| TorBox | 206, 1.53 s | nie (180 s) | 400 in 0.035 s |

**Wenn zurg gestartet wird, während sein Provider down ist, entsteht ein leerer Mount.** Das ist das Szenario, auf das es im Betrieb ankommt: Ein Host startet neu, während Real-Debrid gerade 503 liefert. Genau diese Bedingung hat im August auf `fun` zehntausende Plex-Einträge gelöscht. Ein kurzzeitig leerer Mount wird beim Scan als „alle Dateien wurden gelöscht“ gelesen. Der Schutz dagegen liegt in Plex (`autoEmptyTrash 0`), nicht in zurg.

Real-Debrid und AllDebrid lassen den Reader außerdem bis zu seinem eigenen Timeout warten, statt sofort zu fehlschlagen. TorBox antwortet in 35 ms.

### Ein vorübergehender 503-Fehler lässt Releases als leere Ordner zurück {#a-transient-503-leaves-releases-as-empty-folders}

Der deutlichste Fehler des Laufs, und er wurde nur zufällig entdeckt.

Von den 3.316 Torrents eines Real-Debrid-Kaltaufbaus **antworteten 85 Anfragen mit 503**, und
**84 Torrents landeten in `broken_torrent`**. Ein Release in diesem Zustand wird im
Mount zwar noch aufgelistet, sein Verzeichnis ist aber **leer**. Das haben wir per PROPFIND an zwei davon geprüft: Beide hatten laut gespeichertem Datensatz 10 bzw. 3 ausgewählte Dateien, geliefert wurde aber keine.

Von selbst behebt sich das nicht. Der Bench läuft mit `enable_repair: false`, und diese Releases waren auch mehr als eine Stunde und mehrere Neustarts später noch kaputt.

Mit eingeschalteter Reparatur, dem mitgelieferten Standard, kommt man zwar durch sie hindurch, aber langsam. Bei einem von Hand ausgelösten Durchlauf sieht das so aus:

| Verstrichene Zeit | Defekt | In Reparatur |
|---|---|---|
| 0 min | 85 | 0 |
| ~2 min | 77 | 2 |
| ~15 min | 73 | 4 |

Zwölf Releases in einer Viertelstunde, und die Rate fällt nach den ersten Minuten ab. Bei diesem Verlauf braucht die Behebung eines kompletten Kaltaufbau-Schadens über eine Stunde, und jedes Release, das noch nicht drangekommen ist, bleibt die ganze Zeit ein leerer Ordner.

Die Schwere hängt also von einer Einstellung ab:

- Mit eingeschalteter Reparatur (Standard) kostet ein 503 während eines Scans ein Release seine Dateien, bis ein Reparaturdurchlauf es erreicht – bei einer vollen Bibliothek in der Größenordnung einer Stunde.
- Mit ausgeschalteter Reparatur ist das Release dauerhaft ein leerer Ordner.

TorBox trifft es noch härter. Es meldet `StoredLinksCanRot: false`, daher prüft refresh seine Links nie erneut. Es gibt keinen Weg, einen defekten Zustand zu beheben, außer über die Reparatur. Das einzige TorBox-Release, das beim Ausfalltest als defekt markiert wurde, war auch 68 Minuten und mehrere Neustarts später noch defekt, obwohl der Anbieter es als `cached`, `download_present`, mit einer Datei und 7,31 GB meldete.

### Lese-Integrität {#read-integrity}

Bei einem ersten Durchsatztest-Lauf hat ein AllDebrid-Lesevorgang 263.798.425 Bytes für einen Bereich von 268.435.456 Bytes zurückgegeben, mit einem 206 und ohne Fehler. Er **ließ sich nicht reproduzieren**: Acht Wiederholungen jeweils bei Real-Debrid und AllDebrid haben jedes Mal den vollständigen Bereich geliefert. Wir haben das als einmaligen Ausreißer notiert und nicht als Fehler, behalten es aber im Auge.

## Unter Plex-Last {#under-plexs-load}

Bis hierher wurde jeweils ein Leser nach dem anderen bedient, und so verhält sich ein Medienserver nicht. Plex scannt – Tausende Dateien, von jeder ein bisschen – und Plex streamt, und beides läuft gleichzeitig. Diese Phasen messen den Mount unter beidem.

**Lies die Gesamtwerte als Eigenschaft von zen, nicht von zurg.** Jedes Ziel stagniert bei 73-78 MB/s, egal welcher Anbieter und welcher Modus, und das ist die Leitung des Hosts. Verallgemeinern lassen sich die *Abschlussraten* und die Fehlermuster je Anbieter; die Obergrenze ist lokal.

### Mehrere Leser, verschiedene Dateien, ein Anbieter {#multiple-readers-different-files-one-provider}

96 MB pro Stream, unterschiedliche Dateien.

| streams | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 1 | 44.8 | 52.1 | 45.6 | 51.8 |
| 2 | 72.3 | 63.5 | 71.4 | 69.8 |
| 4 | 73.7 | 64.2 | 74.6 | 70.2 |
| 8 | 73.6 | 73.4 | 65.5 | 75.1 |
| 12 | 77.1 | 73.8 | 76.3 | 77.1 |

Gesamtdurchsatz in MB/s. Die Leitung ist ab zwei Streams voll; darüber teilen sich mehr Leser einfach dieselbe Bandbreite. Der Median pro Stream fällt von ~45 MB/s bei einem auf ~8 MB/s bei zwölf.

Die interessante Spalte ist die Abschlussquote:

| streams | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 4 | 4/4 | **2/4** | 4/4 | 4/4 |
| 8 | 8/8 | **3/8** | 8/8 | 8/8 |
| 12 | 10/12 | **4/12** | 9/12 | 10/12 |

**AllDebrid bricht bei vier gleichzeitigen unterschiedlichen Dateien die Lesevorgänge nicht mehr ab.** Die Bytes fließen weiter – der Gesamtdurchsatz bleibt auf dem Host-Limit –, aber einzelne Streams werden nicht fertig, und der Median pro Stream fällt bei acht und zwölf auf null, mit TTFB-Medianen über 3 s. Alles andere hält bis zwölf, wo bei allen vier ein oder zwei ausfallen.

> **Zurückgezogen am 2026-08-23. Das ist kein Concurrency-Limit des Providers.** Erneut getestet, direkt gegen die APIs mit auf Abspielbitrate begrenzter Rate statt volle Pulle durch zurg, löste AllDebrid **4/8/12/16/24 gleichzeitige unterschiedliche Links zu 100%** auf und hielt **24/24** Live-Streams durch. Die oben genannten Fehler waren **drei null-geroutete AllDebrid-CDN-Hosts** – `l4m5n6.debrid.it`, `o7p8q9.debrid.it`, `c1uw74.debrid.it`, die alle auf `0.0.0.0` auflösen und **15,6 % der aufgelösten Links** ausmachen. Der erste ist derselbe Host, der weiter unten als einmaliger toter Link vermerkt ist; er ist kein Einzelfall.
>
> Ein toter Host schlägt nur fehl, wenn seine Datei im Batch ist. Deshalb steigt die Fehlerzahl mit N und sieht genau wie eine Concurrency-Grenze aus. **Jede Staffelung, die mit steigendem N immer mehr unterschiedliche Dateien zieht, reproduziert dieses falsche Ergebnis.**
>
> Die gesamte Abschlussspalte hier ist aus demselben Grund methodisch eingeschränkt: Diese Läufe zogen mit voller Kraft über eine gesättigte Leitung mit 73–78 MB/s, also misst sie **Bandbreitenanteil, nicht ein Provider-Limit**. Die tatsächlichen Host-Grenzen pro Provider, alle undokumentiert, sind Real-Debrid **32** (am TCP-Layer abgebrochen), AllDebrid **32** (HTTP 429), TorBox **20** pro `nexus-NNN`-Host (HTTP 429, pro Host statt pro IP) und keine Grenze bei Premiumize bei 64 gefunden.
>
> Ein Vorbehalt, damit man die Zurückziehung nicht überinterpretiert: Ein null-gerouteter Host schlägt in ~0,1 s fehl, während die TTFB-Mediane oben über 3 s liegen. Das ist ein langsamer Fehler mit anderer Signatur, also war wahrscheinlich auch Bandbreitenmangel im Spiel. Beides spricht gegen eine Provider-Begrenzung.
>
> **Die daraus folgende Lösung:** Einen Verbindungsfehler auf einem AllDebrid-CDN-Host als wiederholbar behandeln, indem der Link **neu entsperrt** wird – ein frischer `/link/unlock` liefert einen anderen Host –, und nicht die Concurrency reduzieren. Ein DNS-Lookup, der `0.0.0.0` ablehnt, fängt jeden hier beobachteten Fall ab und kostet nichts.

### Mehrere Leser, eine Datei {#multiple-readers-one-file}

Gleiche Stufen, eine Datei, unterschiedliche Offsets: das Read-ahead-plus-seek-Muster.

| Streams | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| 4 | 4/4 | 4/4 | 4/4 |
| 8 | 8/8 | 8/8 | 8/8 |
| 12 | 10/12 | 9/12 | 10/12 |

AllDebrid ist hier **in Ordnung**: 4/4 und 8/8. Bei verschiedenen Dateien waren es dagegen 2/4 und 3/8.
Diese Umkehrung ist die Diagnose: Das Limit liegt nicht an der Bandbreite und nicht an einem Pro-Torrent-Limit,
sondern an der gleichzeitigen **Link-Auflösung**. Verschiedene Dateien bedeuten verschiedene Unlocks. Eine Datei wird einmal aufgelöst und streamt danach einfach.

> **Zurückgezogen am 2026-08-23**: Die Umkehrung hat eine einfachere Erklärung. Verschiedene Dateien laufen über verschiedene CDN-Hosts, und drei davon waren bei AllDebrid per Null-Route abgeschaltet. Eine einzelne Datei wird auf einen Host aufgelöst und funktioniert entweder oder nicht. Die Link-Auflösung selbst wurde bei 24 gleichzeitigen Anfragen als fehlerfrei gemessen. Siehe die Notiz oben.

### Mehrere Leser über verschiedene Anbieter {#multiple-readers-across-different-providers}

Das ist der Mixed-Provider-Fall, und dafür braucht es einen Korpus, den der gemischte Fall nicht liefern kann. Da die zusammengeführte Instanz ein Release mit mehreren Accounts aus `Sources[0]` bedient, landet jeder Lesezugriff auf dem gespeicherten Korpus bei Real-Debrid. Der Pool hier ist deshalb provider-*exklusiv*: 8 Dateien, die nur Real-Debrid hat, 7 nur AllDebrid, 8 nur TorBox.

| Streams (pro Provider) | Gesamt-MB/s | abgeschlossen | RD | AD | TB |
|---|---|---|---|---|---|
| 3 (je 1) | 55.3 | 2/3 | 28.8 | — | 27.9 |
| 6 (je 2) | 66.9 | 5/6 | 16.1 | 13.3 | 21.5 |
| 12 (je 4) | 75.9 | 11/12 | 7.4 | 8.4 | 9.0 |

Die Spalten pro Provider zeigen die Mediane pro Stream in MB/s.

Lesezugriffe auf verschiedenen Accounts laufen tatsächlich parallel, aber sie treffen auf dieselbe Host-Obergrenze von 76 MB/s, die ein einzelner Provider schon allein erreicht. **Auf diesem Host bringt das Mischen von Backends keine zusätzliche Bandbreite.** Ob es anderswo etwas bringt, hängt davon ab, ob man eine Leitung hat, die breiter ist als das, was ein Provider auslasten kann, und zen hat so eine Leitung nicht. Was es stattdessen bringt, ist Verfügbarkeit, und auch die nur teilweise, wie der Failover-Abschnitt weiter unten zeigt.

Der eine, immer wiederkehrende Fehler ist eine einzelne AllDebrid-Datei, deren CDN-Hostname `l4m5n6.debrid.it` auf **0.0.0.0** auflöst. Das ist AllDebrid, das einen toten Link ausliefert, nicht zurg. zurg verliert aber etwa 4 s bei drei Wiederholungen, bevor es mit 500 antwortet, und weil die Datei auf keinem anderen Account liegt, gibt es nichts, worauf es zurückfallen kann.

### Failover: nur aus einer Richtung {#failover-only-from-one-direction}

Da die zusammengeführte Instanz keine Last verteilen kann, besteht ihr eigentlicher Nutzen darin, dass ein Konto mit Problemen trotzdem weiterläuft. `ca/cdnfail.py` sperrt das CDN eines einzelnen Kontos und lässt alle APIs und die anderen Konten unberührt. Die Bibliothek lädt also weiterhin, nur die Dateiinhalte sind betroffen. Die gelesenen Releases stammen aus dem Vergleichskorpus, und alle drei Konten haben jedes davon.

| CDN taken down | reads served | what the read did |
|---|---|---|
| Real-Debrid | 2/2 | fell back to AllDebrid, 0.6 s |
| AllDebrid | **0/3** | one attempt at AllDebrid, 503, then **500 to the client in 0.1 s** |

**Ein Failover passiert nur, wenn das ausfallende Konto Real-Debrid ist.** Der Grund ist eine Fähigkeit, die die anderen Backends nicht setzen. Refresh prüft Links nur dann proaktiv, wenn `StoredLinksCanRot` auf true steht, und das gilt ausschließlich für Real-Debrid:

```
Link verification failed during refresh for /A.Business.Proposal…: (code: 503)
```

Dadurch wird die Quelle herabgestuft, und danach wechseln die Lesezugriffe sauber auf ein anderes Konto. AllDebrid und TorBox werden nie geprüft. Ein toter CDN bei einem dieser beiden fällt deshalb nie auf, die Quelle wird nie herabgestuft, und jeder Lesezugriff auf dieses Release liefert 500, solange der Zustand andauert.

Zwei weitere Punkte zeigt das:

- **Der Lesepfad hat überhaupt kein Fallback inline.** Ein 503 vom CDN des gewählten Kontos wird in 0.1 s direkt zu einem 500 für den Client. Die anderen Konten, die dieselbe Datei haben, werden nicht versucht. Die Wiederherstellung übernimmt allein der Hintergrund-Refresh. Daher gibt es selbst im Real-Debrid-Fall ein Zeitfenster, in dem Lesezugriffe fehlschlagen.
- Derselbe fehlende Mechanismus steckt hinter dem TorBox-Release, das 68 Minuten lang `broken_torrent` blieb. Niemand prüft einen TorBox- oder AllDebrid-Link erneut. Deshalb wird ein fehlerhafter Zustand nie gelöscht, und eine Erholung wird nie bemerkt.

### Ein toter Link vom Anbieter {#a-dead-link-from-the-provider}

Eine AllDebrid-Datei im exklusiven Pool ist jedes Mal fehlgeschlagen, wenn darauf zugegriffen wurde, bei jedem Scan-Durchlauf und jedem Mixed-Reader-Durchlauf. Ihr CDN-Hostname wird auf eine Null-Route aufgelöst:

```
$ getent hosts l4m5n6.debrid.it
::              l4m5n6.debrid.it
0.0.0.0
```

AllDebrid hat einen Link ausgegeben, der auf `0.0.0.0` zeigt. Dieser Teil liegt beim Anbieter, nicht bei zurg. Der Teil von zurg ist, was es dagegen unternimmt: drei Versuche in etwa 4 s, dann ein 500. Die Datei liegt auf keinem anderen Konto, es gab also nichts, worauf man hätte ausweichen können. Aber das Failover-Ergebnis oben zeigt, dass es ohnehin nicht ausgewichen wäre.

> **2026-08-23: nicht nur ein Host, nicht nur eine Datei.** Drei AllDebrid-CDN-Hostnamen waren gleichzeitig auf eine Null-Route gesetzt, `l4m5n6.debrid.it`, `o7p8q9.debrid.it`, `c1uw74.debrid.it`. Das machte **5 von 32 Links in der einen Stichprobe und 4 von 32 in einer anderen aus, bei nicht zusammenhängenden Inhalten**. AllDebrid gibt dieselben toten Hosts für verschiedene Dateien aus und tat das auch noch Tage nach diesem Lauf. Das ist ein dauerhaftes Loch in seiner Flotte, und genau das hat die zurückgezogene Erkenntnis zur Concurrency oben verursacht.
>
> Drei Versuche und ein 500 sind die falsche Reaktion. **Stattdessen neu entsperren**: `/link/unlock` liefert einen anderen Host zurück. Und vorab einen DNS-Lookup machen, der `0.0.0.0` ablehnt. Das fängt jeden beobachteten Fall ohne Kosten ab.

### Scannen {#scanning}

`ffprobe` über den gesamten 23-Dateien-Mischpool, was dem Ablauf einer Plex-Analyse entspricht.

| Parallelität | Dateien/Min | Median pro Datei | Maximum pro Datei | CPU s |
|---|---|---|---|---|
| 1 | 43.7 | 1.16 s | 3.11 s | 2.22 |
| 4 | 112.0 | 1.67 s | 4.19 s | 1.29 |
| 8 | 142.3 | 1.87 s | 6.67 s | 1.16 |

Das Scannen lässt sich gut parallelisieren: Von einem Thread auf acht steigt der Durchsatz um das 3.3-Fache, während die Latenz pro Datei nur um 60 % zunimmt. Für die Real-Debrid-Bibliothek mit 3.316 Releases bedeutet das etwa **76 Minuten mit einem Thread und 23 Minuten mit acht**, jeweils ohne Plex' eigene Arbeit.

### Streamen während des Scannens {#streaming-while-scanning}

Der Fall, vor dem man sich fürchten sollte: Ein Scan gegen einen gerade fehlerhaften Mount hat `fun` zehntausende Plex-Einträge gekostet.

| Scan-Parallelität | Stream allein | Stream während Scan | gehalten | Scan-Dauer |
|---|---|---|---|---|
| 4 | 57.7 MB/s | 66.5 MB/s | 115% | 11.8 s |
| 8 | 67.8 MB/s | 66.8 MB/s | 98.5% | 9.7 s |

**Ein Scan bringt einen Stream nicht zum Erliegen.** Der Zuschauer behält praktisch seinen ganzen Durchsatz, und die Zeit bis zum ersten Byte wird sogar besser (von 1.18 s auf 0.15 s), weil die Verbindung dann schon warm ist. Hier verhält sich der Debrid-Pfad einmal besser, als man befürchtet hat.

## Fehler, die dieser Durchlauf aufgedeckt hat {#defects-this-run-surfaced}

1. **Ein vorübergehendes 503 hinterlässt ein Release als leeren Ordner.** 85 x 503 während eines kalten Builds haben 84 Releases in `broken_torrent` gebracht, und ein kaputtes Release wird ohne Dateien aufgelistet. Mit deaktivierter Reparatur verschwindet es nie; mit aktivierter wird es erst gelöscht, wenn ein Durchlauf es erreicht. Bei TorBox gibt es gar keinen Weg zur erneuten Prüfung (`StoredLinksCanRot: false`), und das eine dort kaputte Release war 68 Minuten später immer noch kaputt, obwohl der Anbieter es als gecacht und vorhanden meldete.
2. **Das Aufräumen der Download-Einträge ist kaputt, und die Kosten summieren sich.** 3,992 `unrestrict/link`-Aufrufe stehen 23 `downloads/delete`-Aufrufen gegenüber, und **22 von diesen 23 gaben 404 zurück**. Die Bereinigung löscht also IDs, die es nicht gibt. Das Konto ist über zwei weitere kalte Builds von 12.469 Einträgen auf **18.768** gewachsen, und zurg lädt beim Start die ganze Liste seitenweise zu je 5.000. Dadurch wird aus dem Leck ein Startaufwand, der mit ihm wächst.
3. **589 Ratenlimit-Ablehnungen in einem kalten Build.** Alle betreffen `unrestrict/link`, etwa 8% des Durchlaufs. Der Standardwert `api_rate_limit_per_minute: 250` hält unrestrict nicht innerhalb des echten Limits von Real-Debrid. Diese Ablehnungen und die 503er sind dasselbe Ereignis, das Punkt 1 auslöst.
4. **Ein Start während eines Anbieter-Ausfalls ergibt ein leeres Mount**, und ein Lesezugriff auf Real-Debrid oder AllDebrid hängt dann, bis das eigene Timeout des Clients greift, statt sofort zu scheitern. TorBox antwortet in 35 ms mit 400.
5. ~~**AllDebrid bringt keine gleichzeitigen Lesezugriffe auf verschiedene Dateien mehr zu Ende.**~~ **Zurückgezogen am 23.08.2026 — siehe den Hinweis unter „Mehrere Leser, verschiedene Dateien" weiter oben.** Die Ursache waren drei null-geroutete AllDebrid-CDN-Hosts mit 15,6% der Links, kein Concurrency-Limit. Direkt nachgetestet löst AD 24 gleichzeitige verschiedene Links zu 100% auf und hält 24/24 Streams. Der ursprüngliche Text bleibt unten zur Dokumentation erhalten.

   2 von 4, 3 von 8, 4 von 12. Dieselben Stufen bei *einer einzelnen* Datei sind in Ordnung (4/4, 8/8). Die Grenze liegt also bei der gleichzeitigen Link-Auflösung, nicht bei der Bandbreite oder einem Limit pro Torrent. Vier gleichzeitig laufende Dateien sind für einen Haushalt ein ganz normaler Abend.
6. **Ein Release mit mehreren Konten wird immer vom selben Konto ausgeliefert.** `File.PrimarySource` gibt `Sources[0]` zurück, die Wahl fällt also auf das Konto, das zuerst gesehen wurde. Geprüft: 7 von 7 Korpus-Releases wurden von Real-Debrid ausgeliefert, obwohl AllDebrid und TorBox identische Kopien hatten. Es wählt nie das schnellere oder weniger ausgelastete Konto.
7. **Failover funktioniert nur in eine Richtung und nie inline.** Als Real-Debrids CDN Anfragen ablehnte, wechselten Lesezugriffe zu AllDebrid. Als das CDN von AllDebrid ablehnte, wurden 0 von 3 Lesezugriffen bedient, und jeder gab in 0,1 s 500 zurück, ohne die beiden Konten zu versuchen, die dieselbe Datei hatten. Nur Real-Debrid setzt `StoredLinksCanRot`, also werden nur dessen Links beim Aktualisieren erneut geprüft, und nur dessen Fehler stufen eine Quelle herab. Der Lesepfad versucht bei einem Fehler nie ein zweites Konto.
8. **Der Netzwerktest beim Start läuft für jedes Backend.** 88 HEAD-Anfragen an Real-Debrid-Download-Hosts laufen auf einer reinen TorBox- und einer reinen AllDebrid-Instanz, die das Ergebnis gar nicht brauchen.
9. **Der eigene PROPFIND-href einer Collection liefert 404.** zurg gibt `<d:href>/all/…</d:href>` aus und lässt das `/dav`-Präfix weg. Ein Abruf dieses Pfads gibt 404 zurück. Kinder werden als nackte relative hrefs ausgegeben, sodass nur der Selbsteintrag falsch ist. RFC 4918 verlangt einen href, den ein Client auflösen kann. rclone und Plex kommen nur damit klar, weil sie ihn nicht verwenden.
10. **`user`/`user/me` wird bei jedem Start dreimal aufgerufen**, kalt oder warm, bei TorBox und AllDebrid gleichermaßen.

## Keine Fehler, aber gut zu wissen {#not-defects-but-worth-knowing}

- **Real-Debrid dedupliziert nicht nach Infohash.** Wenn du einen Magnet-Link hinzufügst, der schon im Konto liegt, entsteht ein *zweiter* Eintrag. Deshalb ergeben die 3.416 Torrents nur 3.318 eindeutige Releases, und dadurch war die erste Delete-Detection-Prüfung ungültig: Sie hat das Duplikat gelöscht, das sie gerade erst angelegt hatte, und daraus den Schluss gezogen, dass nie etwas erkannt wurde.
- **`torrents_rate_limit_per_minute` ist standardmäßig auf 75 gesetzt.** Dieser Wert begrenzt den Kaltaufbau bei Real-Debrid. Das ist ein bewusst gewählter Standard und kein Fehler, aber genau dieser Wert bestimmt die 29 Minuten.

## Erneut ausführen {#rerunning}

```bash
cd ~/dbench && ./runall.sh          # p1..p6
./p7.py adddel rd,ad && ./p7.py outage rd,ad,tb
./apiref.py rd,ad,tb                # provider-side reference latency
./report.py                         # tables
```

Starte niemals zwei Instanzen gleichzeitig, und vergleiche Zahlen nur aus einem einzigen verschachtelten Durchlauf. Der Durchsatz der Anbieter schwankt über den Abend hinweg stark.
