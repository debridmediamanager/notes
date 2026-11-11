# Mehr von deinem Addon {#more-from-your-addon}

[Wie du rex-Addons baust](addons.md) erklärt die Grundlagen. Diese Seite ergänzt Untertitel, Trailer, Kapitel, Sammlungen,
Playlists, Künstlerbilder, bekannte Filme, große Bibliotheken, Fixes und Entfernen. Jeder Abschnitt fügt Felder zu
[Schritt 5](addons.md#step-5-send-it) hinzu. Probier sie in den Anleitungen zu [Heimvideos](addon-home-videos.md), [Musik](addon-music.md)
oder [IPTV](addon-iptv.md) aus.

Jedes Beispiel wurde an rex Nightly-Build 2026.11.02 gesendet. Die vollständige Referenz findest du unter [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Filme und Serien, die Plex kennt {#films-and-shows-plex-knows}

**Was es tut.** Plex zeigt den Titel eines Films oder einer Episode mit Namen, Poster, Besetzung, Zusammenfassung und Bewertungen an, statt deines `display`.

Sende `kind` und die IDs des Titels: eine IMDb-ID (`tt...`) oder TMDB-ID des Films bzw. der **Serie** bei einer Episode, dazu `season` und `episode` mit der Nummerierung von TMDB:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv",
 "kind": "movie", "ids": {"tmdb": 10378}, "media_info": { "...": "ffprobe's output" }}
```

**Was du sehen solltest.** Der Film ist **Big Buck Bunny (2008)** mit Plex' Artwork, egal wie die Datei heißt. rex liest nichts aus Dateinamen: Was du sendest, wird auch angezeigt. [rex mit deiner eigenen App](any-source.md) erklärt das ausführlich, Episoden eingeschlossen.

## Untertitel {#subtitles}

**Was es macht.** Bietet Untertiteldateien an, die neben einem Video liegen und als dessen Untertitel gelten. Man kann sie auswählen, herunterladen oder einbrennen, genau wie einen hochgeladenen Untertitel.

```json
"subtitles": [{"path": "films/Big Buck/film.en.srt", "language": "en", "size": 82}]
```

| Feld | Bedeutung |
|---|---|
| `path` | Wo die Datei auf deinem Addon liegt, genau wie bei einem Video. Ihre Endung bestimmt das Format: `srt`, `ass`, `ssa`, `smi`, `txt` oder `psb` |
| `language` | `en` oder `eng`, so wie du es kennst. rex liest die Sprache nicht aus dem Dateinamen |
| `forced`, `hearing_impaired` | `true`, um sie entsprechend zu markieren |
| `size` | Ihre Größe in Bytes. rex liest die Datei nur dann neu ein, wenn ihr Pfad neu ist oder sich ihre Größe geändert hat |

**Was du sehen solltest.** Das Video zeigt einen Untertitel **English (SRT External)** an. Wenn du `subtitles` weglässt, bleibt das erhalten, was du vorher gesendet hast. `[]` entfernt deine Untertitel (ein hochgeladener oder heruntergeladener Untertitel bleibt erhalten). Eine Datei, die rex nicht lesen kann, wird ausgelassen und protokolliert, das Video wird trotzdem übernommen.

## Trailer und andere Extras {#trailers-and-other-extras}

**Was es macht.** Legt einen Trailer, eine Featurette oder eine gelöschte Szene unter den passenden Film oder die passende Serie, in **Extras**, statt sie als eigenen Titel anzulegen.

```json
{"id": "films/Big Buck/trailer.mp4", "path": "films/Big Buck/trailer.mp4",
 "kind": "extra", "extra_type": "trailer", "media_info": { "...": "ffprobe's output" }}
```

Ein Extra gehört zum Titel der anderen Videos in seinem `release` (standardmäßig sein Ordner). `extra_type` ist `trailer`, `deleted`, `featurette`, `behindthescenes`, `interview`, `scene`, `short`, `opening`, `ending` oder `other`. rex entscheidet nie anhand von Name oder Ordner, dass ein Video ein Extra ist: Nur `kind: "extra"` macht eins daraus.

**Was du sehen solltest.** Auf der Seite des Films wird der Trailer unter Extras angezeigt, und die Bibliothek listet ihn nicht auf.

## Kapitel {#chapters}

**Was es macht.** Damit können Leute im Player zwischen Kapiteln springen.

Führe `ffprobe` zusätzlich mit `-show_chapters` aus und schick die Ausgabe unverändert:

```bash
ffprobe -v error -print_format json -show_format -show_streams -show_chapters film.mkv
```

**Was du sehen solltest.** Die Kapitel des Videos mit ihren Namen und Zeiten. Um Kapitel zu Videos hinzuzufügen, die rex schon kennt, schick deren Probes erneut mit `-show_chapters` im nächsten Snapshot.

## Sammlungen und Wiedergabelisten {#collections-and-playlists}

**Was es macht.** Gruppiert Titel deiner Bibliothek in Sammlungen und Songs oder Videos in Wiedergabelisten. Dein Addon erstellt und aktualisiert sie.

```json
"collections": ["Summer 2026"],
"playlists": {"Road trip": 1}
```

| Feld | Bedeutung |
|---|---|
| `collections` | Die Sammlungen, in denen der Titel ist, nach Name. Jede wird beim ersten Mal angelegt, wenn ein Titel sie nennt |
| `playlists` | Die Wiedergabelisten, in denen die Datei ist, nach Titel, mit ihrer Position in jeder ab 1. Jede ist eine Wiedergabeliste des Server-Besitzers: Audio, wenn ihr erster Song ein Track ist, sonst Video |

Änderungen von Nutzern bleiben erhalten: Ein Titel, den jemand aus einer Sammlung entfernt hat, bleibt draußen. Ein Song, den jemand zu deiner Wiedergabeliste hinzugefügt hat, behält seinen Platz. Und eine Wiedergabeliste, die jemand umbenannt hat, bleibt seine. Lässt du das Feld weg, bleibt das erhalten, was du vorher geschickt hast. `[]` (oder `{}` bei Wiedergabelisten) entfernt die Datei aus allem, wohin dein Addon sie gelegt hat.

**Was du sehen solltest.** Der Collections-Tab der Bibliothek zeigt **Summer 2026**. Playlists zeigt **Road trip**, in deiner Reihenfolge.

## Künstlerbilder {#artist-pictures}

**Was es macht.** Zeigt deine Bilder für die Künstler an, die dein Musik-Addon schickt, auch für Künstler, die Plex kennt und selbst mit einem Bild versehen würde.

Registriere mit `"artwork": "source"` und schicke das Bild bei jedem Track:

```json
"display": {"artist": {"title": "Radiohead", "poster": "http://127.0.0.1:9982/music/Radiohead/artist.jpg"}}
```

Ohne `artwork: "source"` behält ein Künstler, den Plex kennt, das Bild von Plex, und `display.artist` wird nur für Künstler angezeigt, die Plex nicht kennt. In beiden Fällen bleibt ein Bild, das jemand in einer Plex-App ausgewählt oder hochgeladen hat, erhalten.

## Große Bibliotheken: Probes nur einmal senden {#big-libraries-send-probes-once}

**Was es macht.** Erlaubt, dass ein Snapshot mit tausenden Videos fast keine `ffprobe`-Ausgabe senden muss, damit er klein und schnell bleibt.

Sende `probe`, einen kurzen eigenen Text, der sich immer dann ändert, wenn sich der Probe eines Videos ändert (ein Hash der `ffprobe`-Ausgabe funktioniert). Sobald rex ein Video mit diesem `probe` hat, sende nur noch das `probe`, ohne `media_info`:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv", "kind": "movie", "ids": {"tmdb": 10378}, "probe": "v1"}
```

rex antwortet mit `"unchanged": 1`. Wenn rex dieses `probe` nicht kennt (ein neues Video oder eines, dessen Probe sich geändert hat), ändert es nichts und fordert es an:

```json
{"created": 0, "updated": 0, "held": 0, "unchanged": 0, "wants": ["films/Big Buck/film.mkv"]}
```

Sende diese Einträge dann erneut mit ihrem `media_info`. Ein Snapshot zählt einen gewünschten Eintrag als gesendet, deshalb wird er dafür nie entfernt. Prüfe, ob dein rex das unterstützt: In der Antwort auf [Registrierung](addons.md#step-2-register-with-rex) steht `"features": ["probe_digest"]`.

## Was Leute gefixt haben: Fix Match {#what-people-fixed-fix-match}

**Was es macht.** Sagt deinem Addon, welche seiner Videos jemand in einer Plex-App von Hand zugeordnet hat (Fix Match), damit es sie von da an direkt senden kann.

```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/matches
```

```json
{"size": 1, "matches": [{"release": "films/Mystery Reel", "ids": {"tmdb": 45745, "imdb": "tt1727587", "tvdb": 9413}, "kind": "movie", "matched_at": 1793751999}]}
```

Jeder Eintrag besteht aus einem `release` (einem Ordner, außer du sendest `release`) und den IDs des Films oder der Serie, dem er zugeordnet wurde. rex behält die Zuordnung, egal was du als Nächstes sendest, daher geht nichts kaputt, wenn du das ignorierst. Wenn du es liest, kann dein Addon `kind` und `ids` selbst senden und sich die Korrektur merken, falls die Zeilen von rex jemals neu aufgebaut werden. Wenn nichts zugeordnet ist, lautet die Antwort `{"size": 0}`.

## Dein Addon entfernen {#removing-your-addon}

**Was es macht.** Entfernt dein Addon und alles, was es an rex geschickt hat, ohne dessen Dateien anzufassen.

Dafür sind zwei Anfragen nötig: Die erste zeigt, wie viel gelöscht würde, und liefert einen Link, der fünf Minuten gültig ist. Die zweite löscht es dann.

```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon
# {"confirm": "/rex/sources/myaddon/confirm/eae4...", "items": 4, "expires_in": 300}
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon/confirm/eae4...
# {"deleted": true, "removed": 4}
```

Der Watch-History-Verlauf wird mit den Zeilen gelöscht. Wenn du das Addon später wieder registrierst und neu sendest, fängt alles bei null an, mit neuen Zeilen. Wenn du ein Addon stattdessen durch eine neue Version **ersetzen** willst, behalte den Namen, die IDs und die ersten Segmente seiner Pfade bei. Die neue Version aktualisiert dann dieselben Zeilen. Bibliotheken löscht rex nie. Wenn du sie loswerden willst, lösche sie in einer Plex-App.

## Wer an rex senden darf {#who-may-send-to-rex}

rex-Feed (`/rex/sources` und `/rex/feed`) braucht kein Token. Er antwortet nur Programmen auf rex' eigenem Rechner, in deinem Heimnetz (`192.168.x.x`, `10.x.x.x`, `172.16-31.x.x` und private IPv6-Adressen) und über Tailscale (`100.64-127.x.x`). Für alle anderen existiert er nicht, auch wenn du rex' Port für rex-direct weiterleitest oder ihn über IPv6 erreichbar machst. Ein Reverse Proxy auf rex' Rechner erreicht ihn als lokales Programm. Blockiere `/rex/` dort also, wenn du einen Proxy vor rex schaltest.
