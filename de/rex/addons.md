# Eigene rex-Addons bauen {#building-rex-addons}

[rex](https://rex.debridmediamanager.com/de/) zeigt das, was seine Quellen ihm über deren Inhalte erzählen. Eine Quelle teilt rex über die Feed-API mit, was sie hat, und liefert die Dateien, wenn rex sie anfordert. rex behandelt jede Quelle gleich. Ein **Addon** ist eine Quelle, die du selbst schreibst, etwa für Heimvideos, Aufnahmen, Stremio-Kataloge, [Musik](#music) oder [Live-Kanäle](#live-tv).

Diese Seite zeigt, was rex von einem Addon braucht, wie du seine Einträge benennst und welche Regeln wichtig sind. Am Ende steht [rex-stremio](https://github.com/debridmediamanager/rex-stremio) als Beispiel in einer einzigen Datei.

Ein Addon macht drei Dinge:

- **Liefert die Daten.** rex holt jedes Byte über HTTP von deinem Addon, sobald jemand auf Play drückt: eine Datei oder einen Stream, auf den rex weitergeleitet wird.
- **Sagt rex, was es hat.** Es schickt rex eine Liste über die Feed-API von rex und danach jede Änderung. rex scannt nie selbst etwas.
- **Benennt, was es mitbringt.** Bei Inhalten, die kein Agent kennt, schickt dein Addon Titel, Beschreibung, Datum und Artwork selbst mit. Plex-Apps zeigen sie wie jede andere Bibliothek.

Wenn du Filme und Serien mitbringst, die Plex schon kennt (es hat deren IMDb- oder TMDB-IDs), brauchst du stattdessen [rex mit deiner eigenen App](any-source.md). Plex benennt und beschreibt dann alles für dich.

Um die Kataloge deiner Stremio-Addons in rex zu holen, musst du nichts schreiben: rex-stremio ist fertig. Du fügst die Links deiner Addons auf der Einstellungsseite ein und setzt Haken bei den Katalogen, die du willst.

Wenn du keinen Server schreiben und betreiben möchtest, nimm stattdessen ein JavaScript-Addon für [rex-addons](https://github.com/debridmediamanager/rex-addons): eine `manifest.json` und eine `main.js`, geteilt über ein Git-Repository. Es läuft auch in der [zurg+rex Android-App](../zurg/guides/android.md). Es läuft in einer Sandbox, die nur die Websites erreicht, die es auflistet, und deine Dateien nicht lesen kann. Es eignet sich also für Inhalte aus dem Internet, nicht für einen Ordner auf deiner Festplatte. [Ein Addon schreiben](https://github.com/debridmediamanager/rex-addons/blob/main/docs/writing-addons.md) zeigt, wie. Die Addons auf dieser Seite können in jeder Sprache geschrieben sein, deine eigenen Dateien ausliefern und alles tun, was du brauchst.

**Lieber mit funktionierendem Code anfangen?** Drei Tutorials bauen jeweils ein vollständiges Addon in einer einzigen Python-Datei, nur mit der Standardbibliothek, und erklären, was jeder Teil macht:

| Tutorial | Bringt in rex |
|---|---|
| [Heimvideos](addon-home-videos.md) | Einen Ordner mit deinen eigenen Videos, als Bibliothek mit Titeln, Daten und Postern aus den Videos |
| [Musik](addon-music.md) | Einen Ordner mit Alben, die Plex über MusicBrainz benennt, mit Liedtexten |
| [IPTV](addon-iptv.md) | Eine M3U-Playlist und ihren XMLTV-Guide, als Live-TV-Kanäle mit Programmübersicht |

Diese Seite erklärt jeden Schritt, den diese Tutorials gehen. [Mehr aus deinem Addon](addon-more.md) ergänzt Untertitel, Trailer, Kapitel, Sammlungen, Playlists und vieles mehr.

## Bevor du anfängst {#before-you-start}

| Du brauchst | Warum |
|---|---|
| rex, eingerichtet wie in [rex mit deiner eigenen App](any-source.md) (Schritt 1 bis 3) | Dort taucht die Bibliothek deines Addons auf |
| Ein rex-Nightly mit Datum 2026.10.25 oder neuer, oder 2026.11.02 oder neuer für [Music](#music) und [Live TV](#live-tv) | Diese Seite ist dafür geschrieben |
| FFmpeg dort, wo rex läuft, falls dein Addon Streams liefert | rex spielt einen Stream ab, indem er ihn konvertiert (ein Kopieren, also günstig). rex findet FFmpeg selbst; siehe [Video konvertieren](any-source.md#converting-video-optional) |
| Dein Addon auf demselben Rechner wie rex oder in deinem Heimnetzwerk | Der Feed von rex antwortet nur diesen: siehe [Port privat halten](any-source.md#keep-the-port-private) |

Diese Seite schreibt die Adresse von rex als `192.168.1.20:32400` und die des Addons als `127.0.0.1:9981`. Setze deine eigenen Werte an deren Stelle. Die vollständige API-Referenz von rex findest du unter [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Schritt 1. Die Bytes ausliefern {#step-1-serve-the-bytes}

**Was es macht.** Gibt jedem Video eine URL, die rex lesen kann.

**Warum es wichtig ist.** rex speichert keine Medien. Jedes Mal, wenn jemand auf Play drückt, liest rex das Video von deinem Addon.

Dein Addon ist ein HTTP-Server. Ein Video liegt unter `<your address>/<path>`, und `path` wählst du selbst. Es gibt zwei Arten:

| Du lieferst | Wie | Was rex macht |
|---|---|---|
| **Eine Datei** (`.mkv`, `.mp4`, ...) | Beantworte `GET` mit der Datei. Beantworte `Range`-Anfragen (`206`), damit das Spulen schnell geht. Ohne sie liest rex bei jedem Spulen vom Anfang bis zur Position | Plex-Apps spielen sie direkt ab, wenn sie das können, oder rex konvertiert sie |
| **Einen Stream** (HLS, `.m3u8`) | Beantworte `GET` mit der Playlist oder mit einer Weiterleitung dorthin. Weiterleitungen werden gefolgt, und dein Login wird nie an einen anderen Host geschickt | rex konvertiert ihn immer: eine Kopie von Bild und Ton in das Format, das die App abspielt. Eine App, die die Datei direkt liest, wird zu dieser Konvertierung geschickt |

Optional, aber lohnenswert:

- **Ein Login.** Basic Auth (`user`, `password`) oder ein Bearer-Token. rex schickt ihn nur an die eigene Adresse deines Addons.
- **Löschen.** Wenn jemand einen Titel in einer Plex-App löscht, schickt rex deinem Addon zuerst ein WebDAV-`DELETE` für den Pfad. Antwortest du mit `2xx` (gelöscht) oder `404` (schon weg), entfernt rex den Titel. Bei allem anderen sagt die Plex-App, dass er nicht gelöscht werden konnte.

## Schritt 2. Bei rex registrieren {#step-2-register-with-rex}

**Was es macht.** Sagt rex den Namen deines Addons, wo seine Daten liegen und welche Bibliotheken es befüllt.

**Warum es wichtig ist.** rex liest nichts von einer Quelle, die es nicht kennt. Erneutes Registrieren ändert nichts, also mach es jedes Mal, wenn dein Addon startet.

+++ Linux und macOS
```bash
curl -X PUT http://192.168.1.20:32400/rex/sources/myaddon \
  -H 'Content-Type: application/json' \
  -d '{"url": "http://127.0.0.1:9981",
       "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++ Windows
```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/myaddon -ContentType application/json `
  -Body '{"url": "http://127.0.0.1:9981", "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++

| Feld | Bedeutung |
|---|---|
| `url` | Wo deine Daten liegen. Die Daten eines Videos sind `GET <url>/<path>` |
| `user` und `password`, oder `bearer` | Der Login deines Addons, falls es einen gibt. Niemals innerhalb von `url` |
| `directories` | Die Bibliotheken, die dein Addon befüllt. Jeder Eintrag ist ein erstes Pfadsegment (`name`) und der Titel der Bibliothek: `shows` für eine TV-Bibliothek, `movies` für eine Film-Bibliothek, `music` für eine Musik-Bibliothek, oder mehrere. rex legt jede Bibliothek beim ersten Mal an; wenn du sie in Plex umbenennst, bleibt der Name so |
| `trash` | `false` löscht, was dein Addon entfernt (ein Snapshot, der es weglässt, oder ein `DELETE`), statt es in rex' Papierkorb zu verschieben |

Das erste Pfadsegment bestimmt die Bibliothek: Mit dem Beispiel oben landet jeder Pfad, der mit `kids/` beginnt, in **Kids**. Verwende für jede Bibliothek ein anderes erstes Segment.

**Was du sehen solltest.** rex antwortet mit der Quelle. Das Log von rex zeigt `SOURCES myaddon registered at http://127.0.0.1:9981` und beim ersten Mal `SECTION create Kids (show) for myaddon's kids`. Die Bibliothek erscheint innerhalb einer Sekunde in den Plex-Apps unter More.

## Schritt 3. Jedes Video beschreiben {#step-3-describe-each-video}

**Was es tut.** Baut den Datensatz auf, den rex für jedes Video speichert: wo es liegt, was es ist und wie es aussieht.

**Warum es wichtig ist.** Dieser Datensatz ist alles, was rex weiß. Ein fehlendes Probe oder eine sich ändernde ID verursacht die meisten Addon-Fehler.

```json
{
  "id": "home-2026-07-22-beach",
  "path": "kids/summer-2026/beach.mp4",
  "kind": "episode", "season": 1, "episode": 3,
  "name": "Summer 2026",
  "media_info": { "...": "ffprobe's output, whole" },
  "display": {
    "title": "First day at the beach",
    "summary": "...",
    "date": "2026-07-22",
    "thumb": "http://127.0.0.1:9981/kids/summer-2026/beach.jpg",
    "show": {"title": "Summer 2026", "summary": "...", "poster": "https://...", "art": "https://..."},
    "season": {"poster": "https://..."}
  }
}
```

| Feld | Pflicht | Bedeutung |
|---|---|---|
| `id` | ja | Dein Schlüssel für dieses Video, **dauerhaft**. rex speichert den Wiedergabeverlauf darunter |
| `path` | ja | Wo seine Daten unter deiner `url` liegen. Das erste Segment wählt die Bibliothek |
| `media_info` | ja, praktisch | Die ffprobe-JSON-Ausgabe von `-show_format -show_streams` für das Video (bei einem Stream probst du seine URL). Ohne sie wird eine Datei **zurückgehalten**: gespeichert, aber nicht angezeigt, weil Plex-Apps kein Video abspielen, das sie nicht kennen. Ein Stream (`.m3u8`) ohne sie wird mit `not a video file` abgelehnt, also schick einen Stream erst, wenn du ihn geprobt hast |
| `kind` | bei einer Serie | `episode` oder `movie`. Ohne sie wird das Video nirgends einsortiert: In einer Serienbibliothek ist es eine Episode einer Serie mit dem Namen aus `name`, nummeriert in Dateireihenfolge. In einer Filmbibliothek ist es ein Film, der wie seine Datei heißt |
| `season`, `episode` | bei einer Episode | Wohin sie gehört. Nummeriere Episoden so, dass eine neue nie die anderen verschiebt |
| `name` | nein | Der Name der Serie und das, was ihre Episoden gruppiert. Standard: der Name ihres Ordners (bei einem Pfad ohne Ordner der Dateiname) |
| `release` | nein | Gruppiert Videos, die zusammengehören. Standard: der Ordner des Videos |
| `display` | bei allem, was kein Agent kennt | Titel, Zusammenfassung, Datum und Artwork: Schritt 4 |

Der `path` eines Streams endet auf `.m3u8`, und seine `media_info` enthält `"format_name": "hls"`. rex akzeptiert ihn nur mit beidem. Jede andere Datei braucht eine Video-Endung.

## Schritt 4. Benennen und aufhübschen {#step-4-name-and-dress-it}

Was es tut. Gibt Plex-Apps einen Titel, eine Zusammenfassung, ein Datum und Bilder für alles, was kein Plex-Agent kennt.

Warum das wichtig ist. Ohne `display` steht bei einer Episode nur „Episode 3“ mit einer leeren Kachel, und eine Serie hat kein Poster.

| Feld | Wo es angezeigt wird |
|---|---|
| `title`, `summary` | Der Titel und die Zusammenfassung des Videos, genau so wie gesendet |
| `date` | Sein Veröffentlichungsdatum (`YYYY-MM-DD`) und das Jahr daraus. Oder nur das Jahr (`YYYY`) bei etwas, das nur über sein Jahr bekannt ist, etwa ein alter Film: Plex-Apps zeigen dann das Jahr und keinen Veröffentlichungstag |
| `thumb` | Das Poster eines Films oder das Standbild einer Episode |
| `art` | Der Hintergrund eines Films |
| `show.title`, `show.summary`, `show.poster`, `show.art` | Die Serie der Episode |
| `season.summary`, `season.poster` | Die Staffel der Episode (das Serien-Poster, wenn es keins gibt) |

Jedes Feld ist optional. Bilder sind `http://`- oder `https://`-URLs. rex holt sie selbst ab: aus dem öffentlichen Internet oder von der eigenen Adresse deines Addons (die `url`, die du registriert hast), mit dem Login deines Addons. Jede andere Adresse in deinem Heimnetz wird abgelehnt. So kann ein Addon eigene Bilder ausliefern, zum Beispiel ein Standbild aus jedem Heimvideo. Ein 2:3-Bild eignet sich am besten als Poster, ein 16:9-Bild am besten als Standbild und Hintergrund.

So behandelt rex sie:

- **Nur wenn nichts benannt ist.** Ein Video, das mit `kind` und `ids` gesendet wird, die Plex kennt, wird so angezeigt, wie Plex es beschreibt, und `display` wird ignoriert.
- **Spätere Sendungen aktualisieren.** Sendest du ein Video erneut mit einem neuen `display`, ändern sich seine Zeile, Serie und Staffel direkt; Apps zeichnen die neuen Bilder neu. Eine Serie behält den Titel, mit dem sie angelegt wurde.
- **Menschen haben Vorrang.** Ein Feld, das jemand in einer Plex-App bearbeitet und gesperrt hat, behält seinen Wert, und ein Poster, das jemand hochgeladen hat, bleibt erhalten.
- **Es wird geprüft.** Ein Bild, das keine http(s)-URL ist, oder ein Datum in einem anderen Format lehnt das Video ab und nennt das betroffene Feld.

## Schritt 5. Abschicken {#step-5-send-it}

**Was es macht.** Schickt rex deine Videos: alles auf einmal ab und zu, und Änderungen, sobald sie passieren.

**Warum es wichtig ist.** rex zeigt dir genau, was du zuletzt geschickt hast.

| Zum Ziel | Senden | rex antwortet |
|---|---|---|
| Videos hinzufügen oder ändern | `POST /rex/feed/myaddon/items` mit `{"items": [...]}` | Wie viele `created`, `updated`, `held`, `unchanged` waren, und jedes `rejected` Video mit seinem Grund |
| Videos entfernen | `DELETE /rex/feed/myaddon/items` mit `{"ids": [...]}` | Wie viele `trashed`, `deleted`, `released` (gehaltene wurden vergessen) und `unknown` waren |
| Alles senden | `PUT /rex/feed/myaddon/snapshot` mit `{"items": [...]}`. In Teilen: `"session"` (beliebiger Text), `"part"` ab 0, `"complete": true` beim letzten | Dieselben Zählungen und was es `removed` hat: jedes deiner Videos, das im Snapshot nicht genannt wurde |

Sende pro Anfrage ein paar hundert Videos. Ein Snapshot, der nichts nennt, entfernt auch nichts. Und einer, der mehr als die Hälfte deiner Videos entfernen würde, wird abgelehnt, es sei denn, der letzte Teil enthält `"force": true`. So kann ein Addon, das den Überblick verloren hat, deine Bibliothek nicht aus Versehen leeren.

**Was du sehen solltest.**

+++ Linux und macOS
```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/items | head -c 400   # what rex shows, with each ratingKey
curl -s http://192.168.1.20:32400/rex/feed/myaddon/held                  # what waits for a probe
```
+++ Windows
```powershell
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/items   # what rex shows, with each ratingKey
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/held    # what waits for a probe
```
+++

Das Log von rex nennt jedes abgelehnte Video und den Grund: `FEED myaddon rejected <id>: <reason>`.

## Musik {#music}

**Was es macht.** Bringt Alben in eine Musikbibliothek, die Plexamp, Plex Web und Plex für Android abspielen.

**Warum das wichtig ist.** Plex benennt Musik anhand des MusicBrainz-Releases des Albums. Schickst du diese ID, füllt Plex alle Titel, Cover, Künstlerfotos und Biografien selbst aus.

Schick jede Audiodatei als Track:

```json
{
  "id": "albums/in-rainbows/01",
  "path": "music/Radiohead/In Rainbows/01 - 15 Step.flac",
  "kind": "track",
  "ids": {"mbid": "3b408cb5-7d51-4188-b07c-fabcf308cda3"},
  "disc": 1, "track": 1,
  "media_info": { "...": "ffprobe's output, whole" }
}
```

| Field | Bedeutung |
|---|---|
| `kind` | `track` |
| `path` | Eine Audiodatei: `.flac`, `.mp3`, `.m4a`, `.aac`, `.ogg`, `.oga`, `.opus`, `.wav`, `.alac`, `.aif`, `.aiff`, `.wma`, `.ape`, `.wv`, `.dsf` oder `.mka` |
| `ids.mbid` | Die MusicBrainz-**Release**-ID des Albums des Tracks: die ID in einem `musicbrainz.org/release/<id>`-Link, nicht die einer Release Group oder einer Recording. Oder `ids.plex`, Plex' eigene Album-GUID (`plex://album/<id>`) |
| `disc`, `track` | Wo der Track auf diesem Release liegt. Der Track, den Plex unter diesen Nummern führt, wird angezeigt |
| `release` | Zu welcher Kopie des Albums der Track gehört. Standard: sein Ordner. Jede Kopie ist ein eigenes Album, da Plex zwei Kopien als zwei Alben listet. Schick also für die Dateien einer Kopie, die in Disc-Ordnern (`CD1/`, `CD2/`) liegen, ein gemeinsames `release` |
| `display` | Für Musik, die Plex nicht kennt: den `title` des Tracks, seinen `artist` (`title`, `summary`, `poster`, `art`) und sein `album` (`title`, `summary`, `poster`, `date`) |
| `lyrics` | Liedtextdateien neben dem Track in deinem Addon: `[{"path": "music/.../01 - 15 Step.lrc", "size": 147}]`. Eine `.lrc` (Text mit Zeitangaben) oder eine `.txt`, angezeigt als Liedtext |
| `loudness` | Nur wenn dein Addon die Lautstärke misst, mit Plex-Namen: `gain`, `albumGain`, `peak`, `albumPeak`, `albumRange`, `loudness` und `lra`, die Ein- und Ausblendungen `startRamp` und `endRamp` und `levels`, die Lautstärke alle 100 ms. rex misst selbst nichts |

- **Zuerst eine Musikbibliothek.** Leg eine in Schritt 2 an (`"directories": [{"name": "music", "music": "Music"}]`) oder füg in einer Plex-App eine Musikbibliothek hinzu. Ein Track, den keine Musikbibliothek aufnimmt, wird abgelehnt: `no music library holds <file>`.
- **Die Release-ID finden.** Such bei MusicBrainz nach Albumtitel und Künstler (`https://musicbrainz.org/ws/2/release?query=release:%22In%20Rainbows%22%20AND%20artist:Radiohead&fmt=json`) und wähl ein offizielles Release mit deiner Trackanzahl. Oft passen mehrere (eines pro Land), und jedes davon nennt das Album. MusicBrainz beantwortet pro Adresse nur eine Anfrage pro Sekunde und lehnt mehr ab. Außerdem verlangt es einen User-Agent mit dem Namen deines Addons. Frag einmal pro Album und heb die Antwort auf.
- **rex liest keine Tags.** Titel, Cover, Genres und ähnliche Künstler kommen von Plex. Ein Track, dessen Release Plex nicht kennt, zeigt dein `display`, gruppiert unter dem Künstler und Album, die du angibst. Ohne das zeigt er seinen Dateinamen unter `[Unknown Artist]`.
- **Es wird unverändert abgespielt.** FFmpeg brauchst du nicht, außer eine App verlangt eine niedrigere Qualität als das Original. Dann konvertiert rex mit FFmpeg, wie Plex es auch tut.
- **Nicht vorhanden.** Plexamps Radio, Mixe, Sender und klanglich ähnliche Tracks brauchen eine Analyse, die rex nicht macht.

**Was du sehen solltest.** Das Album in der Musikbibliothek mit Plex' Cover und Tracknamen, und seinen Künstler mit einem Foto. In Plexamp wählst du die Musikbibliothek von rex als Bibliothek aus.

## Live-TV {#live-tv}

**Was es macht.** Macht einen Livestream zu einem Kanal von **Live TV** in Plex Web und Plex für Android, mit einem TV-Guide, What's On und einer Kanalnummer.

**Warum es wichtig ist.** Ein Livestream allein ist nur eine Zeile in einer Bibliothek. Mit einem `channel` finden die Leute ihn so, wie sie auch Fernsehen finden: im Guide, nach dem, was gerade läuft.

Sende den Livestream wie in Schritt 3 (eine `.m3u8` mit ihrem Probe), zusammen mit einem `channel`:

```json
"channel": {
  "number": "100.1",
  "title": "Rex News",
  "guide": [
    {"start": "2026-11-01T18:00:00Z", "end": "2026-11-01T19:00:00Z",
     "title": "Evening News", "summary": "The day's headlines.", "categories": ["News"]},
    {"start": "2026-11-01T19:00:00Z", "end": "2026-11-01T19:45:00Z",
     "title": "The Pilot", "type": "episode", "show": "Rex Stories", "season": 1, "episode": 1,
     "categories": ["Drama"]}
  ]
}
```

| Feld | Bedeutung |
|---|---|
| `number` | Die Nummer des Kanals im Guide (`100.1`, `704`): Buchstaben, Ziffern, `.`, `-` und `_`. Wähle Nummern, die andere Addons nicht nutzen. Der erste Kanal, der mit einer Nummer gesendet wird, behält sie |
| `title` | Sein Name im Guide. Standard: der `display`-Titel des Streams |
| `call_sign` | Sein Kurzname. Standard: `title` |
| `guide` | Was läuft: `start` und `end` (Epoch-Sekunden oder ISO 8601 mit `Z` oder einem Offset), `title`, und optional `summary`, `categories`, `thumb` und `previously_shown` (`true` für eine Wiederholung). Eine Episode bekommt `"type": "episode"` mit `show`, `season` und `episode`, und der Guide gruppiert sie unter ihrer Serie |

- **Sende den Guide von ein paar Stunden zurück bis so weit voraus, wie du ihn kennst** (etwa eine Woche, wie es TV-Guide-Dateien machen), und sende ihn erneut, wenn er sich ändert. rex zeigt eine Sendung bis drei Stunden nach ihrem Ende an. Jedes Senden ersetzt den Guide des Kanals. Ein Senden ohne `channel` behält ihn. `"channel": null` beendet den Kanal.
- **FFmpeg wird benötigt**, wie bei jedem Stream: rex wandelt den Kanal um, während jemand zuschaut.
- **Nichts wird aufgenommen.** Plex Web und Plex für Android haben keinen Record-Button.
- **Kanäle, die enden.** Registriere mit `"trash": false` (Schritt 2), damit ein entfernter Kanal gelöscht und nicht in rex' Papierkorb behalten wird.
- **Was eine Kategorie bewirkt.** Eine Episode in `Sports` oder `News` erscheint in den Regalen Sports und News von What's On. Eine Sendung ohne `type` wird als Film angezeigt, so wie Plex es bei jedem TV-Guide macht.

**Was du sehen solltest.** In Plex Web oder Plex für Android steht **Live TV** im Menü der App, der Kanal steht im Guide unter seiner Nummer, und der Stream läuft, wenn du ihn öffnest. Das Log von rex nennt einen abgelehnten Kanal und den Grund, zum Beispiel `channel.guide[3]: end must be after start`.

[rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) macht all das für die Kanäle eines Live-Sport-Servers: Es nummeriert sie nach Gruppe ab `100.1`, behält die Nummer jedes Kanals bei und bezieht deren Guides von Pluto TV und den kostenlosen XMLTV-Dateien von epgshare01.

## Die Regeln, über die man stolpert {#the-rules-that-trip-people-up}

| Regel | Was passiert, wenn du sie brichst |
|---|---|
| **Eine ID bleibt für immer.** Änderst du sie, ist das Video ein neuer Titel | Wiedergabeverlauf und Bearbeitungen bleiben in der alten Zeile, die der nächste Snapshot entfernt |
| **Ein Video, ein Pfad.** Zwei IDs dürfen nicht denselben `path` haben | Die zweite wird abgelehnt: `... is already <id>'s file` |
| **Die Bytes einer Datei sind pro ID festgelegt.** rex behält die Streams der ersten Analyse; eine spätere Analyse ändert nur die Kapitel. Nur ein Stream (`.m3u8`) übernimmt eine neue Analyse, wenn deren Streams abweichen | Ändern sich die Bytes einer Datei (anderes Format, eine korrigierte Hochladung), vergib eine neue ID und einen neuen Pfad |
| **Analysiere alles.** Ohne `media_info` gibt es kein Video | Eine Datei wartet in `held`, bis ein Versand eine liefert; ein Stream wird abgelehnt |
| **Behalte den Quellnamen bei.** Zeilen gehören zu (source, id) | Ein anderer Name startet eine leere Quelle; die Zeilen der alten bleiben, bis du sie löschst |
| **Snapshots sind vollständig.** Fehlt in einem Snapshot ein Kanal, wird er entfernt | Sende nach einem teilweisen Fehler keinen Snapshot: überspring diese Runde |

Um ein Addon (oder ein Skript), das bereits eine Bibliothek gefüllt hat, zu **ersetzen**, behalte seinen Quellnamen, seine IDs und das erste Pfadsegment bei. Dein erster Versand aktualisiert dann seine Zeilen direkt, inklusive Wiedergabeverlauf, statt neue anzulegen.

## Beispiel: rex-stremio {#example-rex-stremio}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) verwandelt die Kataloge deiner Stremio-Addons in rex-Bibliotheken: Filme in eine Filmbibliothek, Serien in eine TV-Bibliothek, Live-Kanäle in eine Bibliothek namens Live TV (nicht der Live-TV-Guide). Es macht die Schritte 1 bis 5 und besteht aus einer einzigen Python-Datei, nur mit der Standardbibliothek. Es nimmt keine Löschungen an: Die Titel eines Katalogs gehören nicht ihm zum Löschen.

**Registering.** Jeder Katalog, den du anhakst, benennt eine Bibliothek: Stremio Films, Stremio Shows oder Live TV, sofern du sie nicht umbenennst. rex-stremio registriert sich als `stremio` mit einem Verzeichnis pro Bibliothek, benannt nach ihr (`stremio-films`), und meldet diese Bibliothek als `shows`-Titel des Verzeichnisses für Serienkataloge oder als `movies`-Titel für Film- und Live-TV-Kataloge.

**Serving.** Die Links von Stream-Addons laufen ab, daher speichert rex-stremio keine Links. Es stellt eine URL pro Titel bereit, `/<directory>/<catalog>/<id>.<ext>`, und antwortet darauf mit einer Weiterleitung zu einem Link, den es in diesem Moment anfordert:

```python
url = app.sync.resolve(vid)   # ask every stream addon, rank, take the first link that opens
self.send_response(302)
self.send_header("Location", url)
```

Es fragt jedes Addon, das den Titel anbietet (`/stream/<movie or series>/<id>.json`), filtert nur einfache `http(s)`-Links (der `infoHash` eines Torrents ist keine Datei, die rex lesen kann), wirft alles weg, was über deinen Auflösungs- oder Größenlimits liegt, und probiert den Rest mit der höchsten Auflösung zuerst. Der Link, der funktioniert, wird bis eine Stunde vor seinem Ablauf zwischengespeichert (bei Links ohne Ablaufangabe eine Stunde lang). rex folgt der Weiterleitung und liest die Datei direkt vom Link, mit Spulen. Ein Link, der eigene Header braucht, wird von rex-stremio selbst weitergereicht. Eine HLS-Master-Playlist liefert es nur mit ihrer besten Variante.

**Probing.** Einmal pro Titel führt rex-stremio ffprobe auf seine eigene URL aus, damit `media_info` genau beschreibt, was rex lesen wird, und speichert das Ergebnis. Es prüft `probe_workers` Titel gleichzeitig (standardmäßig 4) und fragt trotzdem jeden Addon-Host höchstens einmal pro `stream_interval_seconds`. Der Stream, aus dem die Probe stammte, wird gemerkt und bei jeder Wiedergabe zuerst versucht. So wird abgespielt, was rex mitgeteilt wurde. Der Container der Probe bestimmt die Dateiendung im Pfad: `.mkv`, `.mp4`, `.ts`, `.avi` oder `.m3u8` für HLS.

**Stored probes.** Mit einem DMM-API-Key (`dmm_api_key` oder **DMM** auf der Einstellungsseite) überspringt ein Torrent-Stream ffprobe, wenn DMM bereits eine Probe seiner Datei hat. Der Hash des Torrents kommt aus dem `infoHash` des Streams oder aus seinem Link (die Debrid-Links von Torrentio enthalten ihn im Pfad). rex-stremio liest die Dateigröße aus der Antwort des Links auf ein Ein-Byte-`Range`-Request und fragt DMMs `POST /api/sponsor/mediainfo` für bis zu 100 Hashes auf einmal ab. Es übernimmt die Probe von DMM nur, wenn genau eine Datei dieses Releases diese Größe hat, und zusätzlich den Namen, wenn der Stream seine Datei benennt. Alles andere wird wie oben geprobt, und diese Probe geht zurück an DMM (`POST /api/sponsor/probes`: der Hash des Torrents, die Dateigröße, ihr Name, falls der Stream ihn nennt, und die Ausgabe von ffprobe ohne die Adresse, von der gelesen wurde), damit der nächste Sponsor, der die Datei trifft, sie überspringen kann. DMM behält die erste Probe einer Datei und beantwortet zuerst die eigenen Snapshots von zurg. `share_probes: false` behält sie bei rex-stremio; DMMs Probes werden trotzdem genutzt. Die Probe einer Playlist wird nie gesendet.

**Naming.** Jeder Film und jede Episode geht mit `kind` und ihrer IMDb-ID in `ids` an rex, sodass Plex sie benennt, wie in [rex with your own app](any-source.md) beschrieben. Titel, Zusammenfassung, Datum und Poster des Katalogs stehen in `display`, das nur angezeigt wird, bis Plex sie benennt. Ein Live-Kanal oder ein Titel, den nur sein Addon kennt, hat keine IMDb-ID, daher benennt ihn allein `display`.

**Numbering.** Ein Film ist ein Film. Staffeln und Episoden einer Serie kommen von Cinemeta, dessen IDs die von IMDb sind, und behalten dessen Nummern, sodass eine neue Episode die anderen nie verschiebt. rex ordnet sie nach den Nummern von TMDB ein. Wo Cinemetas Nummern davon abweichen, landet eine Episode daher an der falschen Stelle.

**Ids.** Eine ID besteht aus dem Katalog plus der IMDb-ID (und Staffel und Episode), zum Beispiel `st-<catalog>-tt0111161`. Sie ändert sich nie, daher sind ein Film in zwei Katalogen zwei Einträge. Mit eingeschaltetem **Catalogs as collections** ist ein Film oder eine Serie, die mehrere Kataloge derselben Bibliothek auflisten, dort ein einziger Titel, und zwar in der Collection jedes Katalogs.

**Sending.** Alle sechs Stunden und nach jedem Speichern: zuerst die Registrierung, dann jeder Titel, sobald er geprüft ist (`POST .../items`, bis zu 20 Titel oder was alle 5 Sekunden bereitliegt), danach ein Snapshot jedes Katalogs in Teilen zu je 200. Der erste Snapshot nach einem Speichern trägt `"force": true`, weil das Abhaken von Katalogen mehr als die Hälfte entfernen kann. Wenn ein Katalog leer oder nur teilweise antwortet, sendet die Runde keinen Snapshot: Sie fügt hinzu und aktualisiert, entfernt aber nichts, und erst eine spätere vollständige Runde entfernt, was wirklich verschwunden ist.

## Fehlerbehebung {#troubleshooting}

| Du siehst | Warum | Lösung |
|---|---|---|
| `rejected`: `not a video file` | Der Dateiname hat keine Videoendung, oder es ist eine `.m3u8`, deren Probe nicht `hls` ist | Benenne Streams als `.m3u8` und schick ihre Probe mit. Ein Song braucht `"kind": "track"` |
| `rejected`: `no music library holds <file>` | Keine Musikbibliothek nimmt den Track auf | Deklariere eine mit `music` in Schritt 2 |
| Alben zeigen deine Dateinamen unter `[Unknown Artist]` | Keine `ids.mbid`, oder eine Release-ID, die Plex nicht kennt, und kein `display` | Schick die MusicBrainz-Release-ID des Albums oder `display` |
| Ein Album zeigt die falschen Tracks | `ids.mbid` verweist auf eine andere Edition, zum Beispiel eine Deluxe-Version mit mehr Tracks | Wähle ein Release mit deiner Anzahl an Tracks |
| Ein Kanal fehlt im Live-TV-Guide | Kein `channel`; er wurde abgelehnt, und rex' Log sagt warum (`channel.guide[...]`); oder ein anderer Kanal hat die Nummer schon, was nicht geloggt wird | Korrigiere das Feld, das im Log genannt wird, oder wähle eine freie Nummer |
| Live TV fehlt in einer Plex-App | Noch kein Item mit `channel` geschickt, oder die App wurde nicht getestet | Schick einen `channel` und nutze Plex Web oder Plex for Android, die getesteten Apps |
| Ein Video taucht nie auf | Es wird zurückgehalten (sein `media_info` hat keine Streams, oder eine Datei wurde ohne gesendet), oder ein Stream ohne `media_info` wurde abgelehnt | Lass es proben und schick es erneut |
| `rejected`: `... is already <id>'s file` | Eine andere ID hat diesen `path` | Behalte pro Pfad nur eine ID |
| Ein Snapshot antwortet mit `409`: `the snapshot would remove more than half of this source's items` | Dein Snapshot lässt mehr als die Hälfte dessen weg, was rex von dir hat: eine fehlende Festplatte, ein fehlgeschlagenes Listing oder eine echte Aufräumaktion | Behebe, was verschwunden ist. Wenn du es so gewollt hast, schick den letzten Teil des Snapshots mit `"force": true` |
| Episoden heißen "Episode 1" und die Kacheln sind leer | Kein `display` | Schick `display` mit jedem Video |
| Ein Film, den du mit seiner IMDb-ID schickst, behält deinen `display`-Titel statt dem von Plex | rex fragt Plex erst nach Titeln, wenn es beansprucht wurde | Beanspruche rex: [Schritt 3 von rex mit deiner eigenen App](any-source.md#step-3-add-it-to-a-plex-account) |
| Bilder werden nicht angezeigt | Die URL liegt in deinem Heimnetz, aber nicht unter der bei deinem Addon registrierten `url`, oder sie ist nicht http(s) | Liefere sie von der eigenen Adresse deines Addons aus oder hoste sie im öffentlichen Internet. |
| Wiedergabe schlägt mit 502 im rex-Log fehl | Dein Addon hat nicht geantwortet, oder die Seite des Streams hat es abgelehnt | Prüfe zuerst das eigene Log deines Addons |
| Ein in einer Plex-App gelöschter Titel bleibt bestehen | Dein Addon hat das `DELETE` mit etwas anderem als `2xx` oder `404` beantwortet | Lösche ihn auf deiner Seite und antworte dann mit `2xx` |
| Ein gelöschter Titel kommt zurück | Dein Addon schickt das Video immer noch | Hör auf, Gelöschtes zu schicken |

Immer noch fest? Frag im Forum **rex-support** auf [Discord](https://discord.com/invite/7u4YjMThXP). [Hilfe bekommen](../guides/remote-help.md) beschreibt, was du angeben solltest.
