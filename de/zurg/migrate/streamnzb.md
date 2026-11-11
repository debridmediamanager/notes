# Migration von streamnzb v5.1.0 zu zurg {#migrating-from-streamnzb-v510-to-zurg}

streamnzb ist ein Stremio-Addon. Wenn du auf Play drückst, sucht es in Newznab-Indexern und streamt das Ergebnis, das am besten passt.
Es wird nichts gespeichert. Es gibt keinen Dateisystem-WebDAV-Mount und keine Plex-Bibliothek.

Es gibt **also keine Bibliothek auf der Festplatte, die du sichern müsstest, und auch kein Plex-Wiedergabestatus steht auf dem Spiel**. Die Schritte zum Erhalt der Pfade aus den anderen Migrationsanleitungen sind hier nicht nötig.

zurg kann die Rolle auf zwei Arten übernehmen. Nutze eine davon oder beide.

- **Stremio behalten.** zurg hat ein eigenes [Stremio-Addon](../guides/stremio.md). Es sucht in deinen Newznab-Indexern, wenn du auf Play drückst, und streamt die Version, die du auswählst, über dein News-Konto. So funktioniert auch streamnzb. Dafür brauchst du nur zurg. Kein rclone und kein Medienserver. Jede Version, die auf diese Weise abgespielt wird, bleibt außerdem in zurgs Bibliothek.
- **Eine Bibliothek aufbauen.** zurg speichert die Releases, die es hat, in einer Bibliothek und hängt sie für Plex, Jellyfin oder Emby ein. Sonarr und Radarr können sie füllen. zurg selbst kann sie ebenfalls aus deiner Watchlist füllen.

Ein paar Dinge, die streamnzb hatte, haben kein zurg-Gegenstück. Diese Anleitung sagt, welche.

Diese Anleitung ist kürzer als ihre Geschwister, weil das Problem kleiner ist.

## Was neu gescannt werden muss und welche neuen Inhalte auftauchen {#what-needs-rescanning-and-what-new-content-shows-up}

Die zwei Fragen, die die [anderen Migrationsanleitungen](index.md) beantworten, passen hier nicht wirklich. Es lohnt sich, kurz zu erklären, warum, statt dich rätseln zu lassen.

**Es muss nichts neu gescannt werden, weil es nichts zu scannen gibt.** streamnzb hat keine Bibliothek, und Plex hat keine Einträge, die an einen Pfad gebunden sind. Deshalb ist die ganze Trash-Schutz-Logik auf der gemeinsamen Seite für dich nicht tragend. Es gibt kein altes Element, das man erhalten müsste, und nichts, das durch einen Fehler in den Papierkorb wandern könnte.

**Alles ist neuer Inhalt.** Was du in zurgs `nzbs/` ablegst, wird beim ersten Mal in eine leere Bibliothek gescannt. Richte deine Bibliotheken also so ein, wie du sie willst, bevor der erste Durchlauf startet, statt sie hinterher zu korrigieren. Zwei Einstellungen solltest du vorher setzen.

- [`only_show_the_biggest_file: true`](../reference/config.md) für die Verzeichnisse, die deine Medienbibliotheken scannen. Ohne diese Einstellung siehst du Sample-Clips, `.nfo`-Dateien und die `.url`-Werbedateien des Posters.
- „Generate video preview thumbnails“ auf **aus** für diese Bibliotheken. Auf einem Streaming-Mount liest jeder Thumbnail-Durchlauf die gesamte Release über dein Usenet-Kontingent. Ein erster Scan gibt Plex die ganze Bibliothek auf einmal.

---

## Die Modelländerung {#the-model-change}

| | streamnzb | zurg |
|---|---|---|
| Content acquisition | Durchsucht Newznab-Indexer pro Play-Anfrage | Das [Stremio-Addon](../guides/stremio.md) durchsucht Newznab-Indexer pro Play-Anfrage. Eine Bibliothek füllt sich außerdem aus `.nzb`-Dateien und dem SABnzbd-Endpunkt sowie über [Beschaffung](../guides/acquisition.md) |
| Ranking and selection | jhin-Traits und Filterprofile sowie eine AvailNZB-Prüfung | Zuerst die Auflösung, dann eine Verteilung von Größen innerhalb jeder Auflösung. Keine Traits und keine Filterprofile |
| Retention | Nichts wird behalten. Jeder Play ist eine neue Suche | Persistente Bibliothek. Ein über das Addon abgespieltes Release bleibt darin |
| Client | Stremio. Das Addon ist zugleich der Metadatenanbieter | Stremio über das zurg-Addon, das nur Streams beantwortet. Jeder Medienserver über den Mount. Oder WebDAV direkt für Infuse |
| Filesystem | Keines | rclone-FUSE-Mount plus WebDAV plus ein einfacher HTTP-Index |
| Archives | RAR und 7z **nur STORE**. Komprimierte Releases lassen sich nicht abspielen | Komprimierte RAR und 7z werden transparent gestreamt |
| Obfuscated posts | Abgelehnt | Namen werden aus yEnc-Headern und PAR2 wiederhergestellt. Der Inhalt wird unter dem Release-Namen angeboten |
| Damaged posts | Übersprungen über AvailNZB | PAR2-Reparatur baut fehlende Artikel neu auf. Das Addon überspringt ein Release, dessen Anfang fehlt, und probiert das nächste |
| SABnzbd API | Nein. Stattdessen gibt es einen NNTP-Proxy auf 119 | Ja, und optional. Jeder Grab wird gegen die News-Server geprüft. Ein toter Post wird aus PAR2 neu aufgebaut, wo das möglich ist, und als Failed gemeldet, wo nicht |

Im Alltag kann Stremio so bleiben, wie es ist. Füg das zurg-Addon hinzu und wähl einen Titel wie bisher. zurg durchsucht deine Indexer und spielt ab, was du auswählst. Die [Stremio-Seite](../guides/stremio.md) erklärt die Einrichtung. Der erste Play eines Releases wartet, während zurg die NZB holt und das Release auflistet. Das dauert meist ein paar Sekunden. Jeder spätere Play dieses Releases startet sofort.

Eine Bibliothek für deinen Medienserver braucht etwas, das sie füllt.

- **Der SABnzbd-Endpunkt.** Wenn du `sabnzbd.enabled: true` setzt, antwortet zurg Sonarr und Radarr als Download-Client. Der Import ist ein Umbenennen innerhalb von `__magic__`. Der Grab landet in `__magic__/__all__`. Beim Import wird die Datei von dort in den Root-Ordner verschoben, den du daneben angelegt hast. Nichts wird kopiert. Die meisten Bibliothekseinrichtungen sollten das nutzen. Siehe [Sonarr &
  Radarr](../guides/sonarr-radarr.md). zurg prüft jeden Grab gegen die News-Server, bevor es ihn als fertig meldet. Es fragt den Anfang und das Ende jeder Datei ab. Außerdem lädt es den ersten Artikel jeder Datei herunter. Das sind bis zu vierundsechzig davon, plus ein paar mehr bei einem Release mit nur wenigen Dateien. Manche News-Server melden noch, dass ein Artikel existiert, nachdem sein Inhalt entfernt wurde, und nur ein Download zeigt das. zurg baut ein Release mit fehlenden Artikeln aus seinen PAR2-Dateien neu auf, wo es kann. Eines, das es nicht neu aufbauen kann, wird als **Failed** gemeldet. Der \*arr setzt es dann auf die Blockliste und holt ein anderes.
- **Acquisition.** zurg kann Anfragen selbst holen. Sie kommen von deiner Plex-Watchlist sowie von Seerr und den \*arrs. Es durchsucht deine Newznab-Indexer und prüft jeden Grab auf die gleiche Weise. Siehe [Beschaffung](../guides/acquisition.md).
- **Manuell ablegen.** Lade die `.nzb` von der Website deines Indexers herunter und kopiere sie in `nzbs/`. Der Name ist fest, das Verzeichnis wird etwa alle 15 Sekunden neu gescannt, und Dateien werden nie verschoben oder verbraucht. Das funktioniert immer und ist die ehrliche Grundlage.
- **Sonarr und Radarr "Usenet Blackhole".** Die \*arrs lassen sich mit einem Blackhole-Download-Client einrichten, dessen *Nzb Folder* zurgs `nzbs/` ist. So bekommst du die Such- und Grab-Automatisierung zurück, ohne Endpunkt, allerdings mit einem Haken. Der \*arr wartet, bis ein fertiger Download in seinem Überwachungsordner auftaucht, und importiert ihn dann. zurg erzeugt nie einen, weil das Release stattdessen im Mount erscheint. Deshalb zeigt die Warteschlange des \*arr den Eintrag als nie fertig an. Du bekommst automatische NZB-Lieferung statt der Import- und Umbenennungs-Pipeline des \*arr. Die \*arr-Seite dessen wurde für die Anleitung nicht erneut geprüft. Die zurg-Seite ist im Code geprüft, unter `internal/nzb/provider.go:30`.
- **Der eigene RSS- oder Warenkorb-Download eines Indexers in ein Verzeichnis.** Das hängt komplett vom Indexer ab und davon, dass du den Abruf scriptest. Ungeprüft, und nur erwähnt, weil manche Indexer das anbieten.

**Benenne die Datei, bevor du sie ablegst.** Der Release-Ordner im Mount wird nach dem *Dateinamen* der NZB benannt. Der `<meta type="name">`-Header wird nur verwendet, wenn der Dateiname wie ein Hash aussieht. Das wurde am 2026-08-19 auf allen fünf Servern gemessen. Eine Datei namens `indexer_download_48213.nzb` gibt Plex nichts zum Abgleichen, also benenne sie zuerst in den Release-Namen um. Das heißt auch, dass du den Ordnernamen voll in der Hand hast. Zwei verschiedene Releases mit demselben Namen bekommen das Suffix ` {shorthash}`.

## Konfiguration, die übernommen wird {#configuration-that-carries-over}

Zwei Dinge werden übertragen. Das erste ist der Usenet-Provider. streamnzb richtet Provider unter **Settings → Providers** ein, mit Host, Port, Benutzername, Passwort und Verbindungen. Umgebungsvariablen funktionieren ebenfalls. Dasselbe Konto wird zum `nntp`-Block in zurg.

Vorher in streamnzb. Das ist die Umgebungsvariablen-Form mit den dokumentierten Schlüsselnamen.

```
PROVIDER_1_HOST=news.example.com
PROVIDER_1_PORT=563
PROVIDER_1_SSL=true
PROVIDER_1_USERNAME=USERNAME
PROVIDER_1_PASSWORD=PASSWORD
PROVIDER_1_CONNECTIONS=30
PROVIDER_1_PRIORITY=1
```

Danach in zurgs `config.yml`.

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true            # streamnzb's SSL flag
      username: USERNAME
      password: PASSWORD
      connections: 30      # your plan's real allowance and the tuning knob
      cache_size_mb: 512
```

Ein zweiter streamnzb-Provider wie `PROVIDER_2_*` kommt unter `nntp.servers`. zurg probiert dort Konten nacheinander durch, Artikel für Artikel. `priority` wird direkt übernommen. zurg kennt zwei Konzepte, die streamnzb nicht hat. Mit `backup: true` markierst du ein volumenbasiertes Block-Konto, das nur dann abgefragt wird, wenn alle primären Server *no such article* melden. Mit `backbone` sorgst du dafür, dass zwei Konten auf demselben Spool nicht dieselbe Anfrage doppelt stellen. Es ist nur ein `nzb`-Provider-Eintrag erlaubt. Weitere Newsserver-Konten gehören darin und nicht daneben.

Das zweite sind deine Indexer. Sie kommen unter `stremio.indexers` mit derselben URL und demselben API-Key. Die Acquisition verwendet dieselbe Liste, wenn sie keine eigene hat.

```yaml
stremio:
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
```

Sonst wird nichts aus streamnzbs `data/config.json` übernommen. Die Blöcke `streams` und `filter_profiles` haben bestimmt, was das streamnzb-Addon angeboten hat. Das zurg-Addon hat pro Titel eine einzige Liste und eine eigene Rangfolge. Die nächstliegenden Stellschrauben sind zwei. `max_size_gb` verwirft Releases oberhalb einer Größe weg. `max_results` legt fest, wie viele Releases pro Auflösung behalten werden. Den Rest findest du auf der [Stremio-Seite](../guides/stremio.md).

## Wiedergabeverlauf {#watch-history}

streamnzb speichert den Wiedergabeverlauf jedes Streams in seiner Datenbank. Standardmäßig ist das SQLite unter `data/streamnzb.db`, optional geht auch Postgres. Daraus baut es die Zeilen Continue Watching und Because You Watched. In der Doku heißt der Inhalt "Bibliothek, Such- und Wiedergabeverlauf, schlechte Releases und Metriken".

**Davon lässt sich nichts in eine Plex-Bibliothek übernehmen.** Der Plex-Wiedergabestatus liegt pro Eintrag in Plex' eigener Datenbank und hängt an Einträgen, die zuerst in einer Bibliothek vorhanden sein müssen. Auf keiner Seite gibt es einen Importer. Eigentlich ist das gar kein echter Datenverlust, sondern eher ein Unterschied im Modell. Die Verlaufszeilen von streamnzb verweisen auf Suchen und Streams, nicht auf Dateien. Wenn du den Datensatz vor der Außerbetriebnahme sichern willst, dann ist die Datenbank einfaches SQLite und du kannst sie direkt auslesen.

```bash
sqlite3 data/streamnzb.db .tables
sqlite3 data/streamnzb.db "select * from <table> limit 20;"
```

Die genauen Tabellennamen sind nicht dokumentiert und für diese Anleitung nicht geprüft. Mit `.tables` findest du sie heraus. Bei Postgres liegen dieselben Daten in der Datenbank, auf die `DATABASE_URL` zeigt. Der Wiedergabestatus in deinem neuen Setup beginnt bei null und wird ab dem ersten Abspielen in Plex aufgebaut.

---

## Was du gewinnst {#what-you-gain}

- **Eine echte Bibliothek.** Plex, Jellyfin und Emby scannen ein Dateisystem und speichern Metadaten und den Wiedergabestatus über alle Clients hinweg, die sie unterstützen. Nicht nur Stremio.
- **PAR2-Reparatur.** Ein Release mit fehlenden Artikeln wird im Hintergrund aus seinen eigenen Wiederherstellungsdateien neu aufgebaut. streamnzb hat auf ein kaputtes Release so reagiert, dass es übersprungen wird. zurg repariert es.
- **Verschleierte Releases.** zurg holt die echten Dateinamen aus den yEnc-Headern und dem PAR2-Index und stellt eine vollständig verschleierte Nutzlast unter dem Release-Namen bereit. Beim Test auf dem Prüfstand wurde aus `Obfuscated.nzb` eine saubere `Toy.Story.5.2026...KyoGo.mkv`. streamnzb lehnt solche Releases einfach ab.
- **Komprimierte RAR- und 7z-Archive.** streamnzb streamt nur STORE-Archive, und in der README steht ausdrücklich: "Compressed RAR releases will not play". zurg streamt Videos aus komprimierten Archiven und bildet dabei die innere Verzeichnisstruktur nach.
- **Zweite Wiedergabe startet sofort.** streamnzb sucht und prüft bei jeder Wiedergabe neu. zurg merkt sich, was du schon abgespielt hast. Ein Release, das schon in der Bibliothek liegt, startet sofort. Alles, was Sonarr oder Radarr holen, ist von Anfang an in diesem Zustand.
- **Tiefe Unterstützung für mehrere Accounts.** Prioritäten, nach Verbrauch abgerechnete `backup`-Accounts, `backbone`-Deduplizierung und ein Reparaturweg, wenn jeder Account fehlt.

## Was du verlierst {#what-you-lose}

Stell sie nicht kleiner dar, als sie waren. Sie waren das Produkt.

- **jhin und Filterprofile.** Das Addon von zurg durchsucht auch deine Indexer. Es sortiert nur nach Auflösung und Größe. Es gibt keine jhin-Eigenschaften, Filterprofile oder Bewertungen.
- **Die AvailNZB-Prüfung.** zurg fragt bei niemandem sonst nach, ob ein Release noch verfügbar ist. Das Addon findet das heraus, indem es den Anfang des ausgewählten Releases liest. Ist dieser Anfang weg, springt es zum nächsten Release in der Liste. Ein Grab von Sonarr oder Radarr wird gegen deine News-Server geprüft, bevor es als fertig gilt. Schäden weiter hinten in einer Datei fallen auf, sobald ein Lesezugriff sie erreicht. Die PAR2-Reparatur baut sie dann wieder auf, sofern der Post genug Wiederherstellungsdaten enthält. Am 2026-08-19 wurde ein RAR-Set, dem ganze Volumes fehlten, als leerer Ordner angezeigt statt als Fehler.
- **Kataloge und Zeilen von streamnzb.** Die eingebauten Kataloge und Metadaten sowie die Zeilen Continue Watching und Because You Watched kamen aus dem eigenen Verlauf von streamnzb. Das Addon von zurg liefert nur Streams. Ein Media-Server hat für eine Bibliothek seine eigenen Versionen dieser Zeilen.
- **Der NNTP-Proxy auf Port 119.** Wenn SABnzbd oder NZBGet streamnzb als News-Server eingetragen hatten, brauchen sie wieder echte Zugangsdaten des Anbieters.

---

## zurg aufsetzen {#standing-up-zurg}

Eine funktionierende, nur-Usenet-`config.yml`.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30          # the plan's full allowance once streamnzb is gone
      cache_size_mb: 512

enable_repair: true            # PAR2 repair does not run without this
par2_patch_cache_mb: 512

stremio:                       # keeps Stremio working. Leave it out for a library alone
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY

mount_path: "/mnt/zurg"
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run

directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

Verwende keine `tags_match_any`-Filter für Usenet-Inhalte. Die `zurg_*`-Tags stammen von ffprobe, und ffprobe läuft auf diesem Backend nie. Ein solches Verzeichnis enthält daher nie eine Usenet-Veröffentlichung. Filtere stattdessen nach Namen, Dateiendungen, Größen und `has_episodes`.

Starte es dann.

```bash
./zurg               # startup verifies the news account and says so, loudly, and makes nzbs/
ls /mnt/zurg/__all__/
```

Wenn Usenet dein einziges Konto ist, wird der Ordner `__nzb__` nicht in der Root-Auflistung des Mounts angezeigt, `__all__` enthält aber dieselben Dateien. Teste die Wiedergabe also unter `__all__` im Mount oder öffne den direkten HTTP-Pfad `http://localhost:9999/http/__nzb__/`. Unterordner von `nzbs/` werden übersprungen, und `.nzb.gz` wird nicht gelesen.

### Die erste Plex-Bibliothek {#the-first-plex-library}

Verweise Bibliotheken auf **Unterordner** des Mounts, zum Beispiel `/mnt/zurg/movies` und `/mnt/zurg/shows`. Nie auf das Root-Verzeichnis. Dieselbe Veröffentlichung taucht unter `__all__` und in jedem passenden Verzeichnis auf, das Root würde also mehrfach gescannt.
Wenn Usenet dein einziger Account ist, fehlt `__nzb__` in der Root-Auflistung des Mounts und lässt sich darüber nicht auflösen, weil `__all__` dieselben Dateien enthält.
Gib zurg `plex_server_url` und `plex_token`, damit es Teil-Scans anfordern kann.

Zwei Bibliothekseinstellungen sind vom allerersten Scan an wichtig, egal ob die Bibliothek neu ist oder nicht. Der Fehler, gegen den sie schützen, ist, dass der Mount *während* eines Scans kurz ausfällt.

1. **Deaktiviere "Empty trash automatically after every scan"**, sodass `autoEmptyTrash` auf 0 steht. Wenn der Mount mitten im Scan verschwindet, schließt Plex daraus, dass alle Dateien gelöscht wurden. Dafür reicht schon ein Neustart von zurg oder ein rclone-Remount. Ist das automatische Leeren aktiv, werden die Dateien sofort und endgültig entfernt. Ist es aus, liegen sie im Papierkorb und kommen mit dem Mount wieder zurück. Das hat in der Vergangenheit schon Zehntausende Einträge gekostet.
2. **Deaktiviere "Generate video preview thumbnails".** Bei Usenet liest jeder Thumbnail-Durchlauf die gesamte Veröffentlichung komplett durch und verbraucht dafür dein Datenvolumen.

Und starte zurg niemals neu, während Plex scannt. Der Vorab-Check und beide Einstellungen müssen 0 ergeben.

```bash
TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

Verwende `grep -o … | wc -l` statt `grep -c`. grep beendet sich mit einem Fehlercode, wenn nichts gefunden wird, und genau das ist hier der *gute* Fall. Dann bricht es eine `&&`-Kette oder ein `set -e`-Skript ab, direkt vor dem Neustart, den es eigentlich absichern sollte.

Die Dateigrößen pendeln sich etwas ein, nachdem eine Veröffentlichung zum ersten Mal aufgelistet wurde. Eine NZB verrät nicht, wie lang eine Datei ist. Deshalb schätzt die erste Auflistung die Größe aus den Artikelgrößen, die die NZB enthält. Diese Schätzung kann bis zu etwa 3 Prozent zu hoch liegen. zurg ermittelt danach im Hintergrund die exakte Länge und behält sie. Ein Scan, der vorher lief, sieht die Schätzung. Plex wertet die Datei dann als geändert und analysiert sie einmal erneut. Es wird nichts gelöscht.

## Beide parallel laufen lassen {#running-both-side-by-side}

Auf den Ports gibt es keine Konflikte. streamnzb belegt 7000 und 119, zurg belegt 9999. Der sinnvolle Übergang ist daher, streamnzb weiter für Stremio laufen zu lassen, während sich die zurg-Bibliothek füllt.

Die einzige gemeinsame Ressource ist der Usenet-Account. **Beide greifen auf dasselbe Verbindungskontingent zu, und der Provider erzwingt es über beide hinweg.** Ein Tarif mit 50 Verbindungen kann nicht streamnzb mit 50 und zurg mit 30 betreiben. Die überschüssigen Verbindungen werden abgelehnt, und auf der zurg-Seite sieht das dann nach langsamen oder hängenden Streams aus. Teile das ausdrücklich auf. Probier `PROVIDER_1_CONNECTIONS=20` in streamnzb gegen `connections: 30` in zurg. Gib zurg das volle Kontingent, wenn streamnzb ausgemustert wird, denn der Durchsatz eines einzelnen Streams bei zurg wird durch diese Zahl bestimmt.

Wenn du streamnzb abschaltest, entferne sein Stremio-Addon aus deinen Clients. Behalte eine Kopie von `data/`, falls du den Verlauf willst. Seine `config.json` und `streamnzb.db` sind sein gesamter Zustand. Danach richtest du alles, was den NNTP-Proxy auf 119 nutzt, direkt auf deinen Provider um.
