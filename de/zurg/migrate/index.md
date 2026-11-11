# Migration zu zurg {#migrating-to-zurg}

Lies zuerst diese Seite. Sie gilt für jede Migration und enthält den größten Teil dessen, was du brauchst. Die Seiten zu einzelnen Servern sind kurz, weil diese hier den gemeinsamen Teil übernimmt.

## Die Kurzfassung {#the-short-version}

**zurg veröffentlicht jede Mediendatei, die der Server, den du verlässt, veröffentlicht, und noch mehr.** Gemessen wurde das am 01.09.2026. Dieselben fünf Releases gingen in alle fünf Server, und die Mounts wurden mit `tree` ausgelesen. Hier ist [der vollständige Vergleich](https://github.com/debridmediamanager/usenet-streaming-benchmark). Das Einzige, was zurg *weniger* veröffentlicht, sind par2-Paritätsdateien. Plex macht daraus nie ein Bibliothekselement.

Du wirst also **keine Inhalte verlieren**. Manche davon tauchen unter einem anderen Dateinamen auf. Darum geht es auf dieser Seite. Plex bindet ein Bibliothekselement an einen Dateipfad. Eine Datei mit neuem Pfad ist ein neues Element.

Was du eintauschst, sind nicht die Dateien. Es ist die **Kuration**.

| Bleibt erhalten | Geht mit dem alten Element verloren |
|---|---|
| Gesehen-Markierungen, Abspielzähler, Fortsetzungspositionen | Mitgliedschaft in Collections |
| Benutzerbewertungen | Playlist-Einträge (sie speichern Element-IDs) |
| Die Dateien selbst | Ausgewählte Poster, Artwork und manuelle Korrekturen beim Abgleich |
| | `added_at`. Deine Bibliothek überflutet Recently Added |

Der Wiedergabestatus bleibt erhalten, weil `metadata_item_settings` über Konto und `plex://`-GUID zugeordnet wird, nicht über Pfad oder Element-ID. Er hängt sich wieder an, wenn das neue Element dieselbe GUID bekommt. Falls Plex das neu hinzugefügte Element falsch zuordnet, kommt der Status nicht zurück. Prüfe nach dem ersten Scan ein paar Elemente.

Diesen Tausch kannst du vollständig vermeiden, dafür zahlst du einen Preis. Du kannst `media_parts.file` in der Plex-Datenbank umschreiben, dann sterben die Zeilen nie. Oder du baust einen Symlink-Shim-Baum, der jeden alten Pfad über dem zurg-Mount nachbildet. Beides funktioniert. Beides ist nicht unterstützte Eingriffe in ein undokumentiertes Schema, das sich zwischen Plex-Versionen ändert. Ein halb angewendetes Umschreiben ist schlimmer als beide Ergebnisse, die es verhindern sollte.

Diese Anleitungen gehen den einfachen Weg und sagen dir genau, was er kostet.

## Deine Bibliothek landet in `__magic__` und nicht in einer Symlink-Farm {#your-library-lands-in-__magic__-and-not-in-a-symlink-farm}

Jeder Server auf dieser Liste gibt seine Bibliothek über eine Farm aus Symlinks an die \*arrs weiter. **zurg macht das nicht, und du solltest nicht versuchen, so eine Farm nachzubauen.** Stattdessen gibt es [`__magic__`](../guides/magic.md). Das ist das eine Verzeichnis, dessen Pfade *gespeichert* statt *berechnet* werden. Ein Verschieben darin schreibt nur eine Zeile in einer kleinen Tabelle neu. Es werden keine Daten verschoben und nichts kopiert. Das Release bleibt dort, wo es im Account liegt. Zeig Sonarr und Radarr darauf, und sie können organisieren und umbenennen, wie sie wollen, ohne dass es etwas kostet.

Das ist nicht nur ein Teil weniger, das sich bewegen kann. Es ist eine Schicht, die nicht so kaputtgehen kann wie die alte. Ein Symlink muss auf einen echten Pfad zeigen. Das naheliegende Ziel ist `__all__/<release>/<file>`, und dieser Pfad wird *berechnet*. Er ändert sich, wenn das Release umbenannt wird. Er ändert sich noch einmal, wenn zwei Releases kollidieren und zurg einem von beiden ein `{shorthash}`-Suffix anhängt. Jede dieser Änderungen lässt einen Link unbemerkt ins Leere zeigen. Eine `__magic__`-Platzierung hängt dagegen am Content-Hash des Releases plus dem Pfad der Datei darin. Deshalb übersteht sie eine Umbenennung. Sie übersteht ein `{shorthash}`-Suffix. Sie übersteht auch ein Repair, das das Release unter einer völlig neuen ID wieder hinzufügt.

Egal, was du heute hast: **die Pfade ändern sich, und die Bibliothek wird neu hinzugefügt.** Das gilt für eine Symlink-Bibliothek von \*arr und für Plex, das direkt auf den alten Mount zeigt. Das ist der oben genannte Kompromiss, und er ist die ganze Kostenseite jeder Migration hier.

## Was du heute hast, hängt von deiner Plattform ab {#what-you-have-today-depends-on-your-platform}

Das entscheidet, ob die Umbenennungstabellen auf den folgenden Seiten deine Plex-Bibliothek beschreiben oder nur die Quelle, aus der sie gebaut wurde. Kläre das, bevor du sie liest.

### Linux und macOS. Deine \*arrs haben schon alles umbenannt {#linux-and-macos-your-arrs-already-renamed-everything}

Die Symlink-Strategie ist das dokumentierte Setup für alle vier Server hier, und sie gibt es nur auf diesen Plattformen. Der Server stellt `completed-symlinks/<category>/<release>/<file>.rclonelink` bereit. Dann macht `rclone mount
--links` daraus für jede Datei einen echten Symlink. Dann importieren **Sonarr und Radarr aus dieser Farm in eine Bibliothek unter Pfaden, die sie selbst festlegen.** Der Mount ist die Quelle, nicht die Bibliothek.

Zwei Folgen.

- **Die Pfade, die Plex hat, gehören immer dem \*arr. Immer. Root-Ordner, dann Serienordner, dann Staffelordner. Keiner davon enthält einen Release-Namen.**
- **Die Dateinamen gehören auch dem \*arr, wenn du das Umbenennen eingeschaltet gelassen hast. Gemeint sind "Rename Episodes" und "Rename Movies". Mit ausgeschaltetem Umbenennen sind es die Namen des Quellservers, und die Tabellen auf den folgenden Seiten beschreiben genau das, was du siehst.**

Wenn du die \*arrs mit eingeschaltetem Umbenennen laufen lässt, beschreiben die Tabellen zum Umbenennen pro Server **nicht** deine Bibliothek. Sie beschreiben, was der \*arr beim Import bekommen hat. Das ist trotzdem wichtig. Ein besserer Quelldateiname ist ein besseres Parsing, und du importierst gleich neu.

### Windows. Überhaupt keine Symlink-Schicht {#windows-no-symlink-layer-at-all}

Eine Symlink-Farm braucht `rclone mount --links`, und das gibt es bei einer Windows-Einrichtung nicht.
Der Mount ist ein Laufwerksbuchstabe über WinFsp, und Plex und die \*arrs zeigen direkt darauf. Also **zeigt Plex die eigenen Dateinamen des Servers an**, und die Tabellen zum Umbenennen beschreiben genau, was du an Änderungen sehen wirst.
Auf der Seite [Windows-Einrichtung](../setup/windows.md) findest du Infos zum Laufwerksbuchstaben und zur Regel für die Sitzung.

Die Shell-Befehle auf den Seiten zu den einzelnen Servern sind für Linux und macOS geschrieben (unter macOS liest du `/mnt/zurg` als `/Volumes/Zurg`). Unter Windows liest du `/mnt/zurg` als `Z:\`, beendest den alten Server egal wie du ihn gestartet hast, und legst Ordner an und verschiebst Dateien in `__magic__` mit den PowerShell-Befehlen aus [der Anleitung zu `__magic__`](../guides/magic.md).

### Wenn du von einer Symlink-Bibliothek kommst {#coming-off-a-symlink-library}

You are not moving a library. You are rebuilding one. And `__magic__` gives the
\*arrs exactly what the symlink farm gave them without the farm. They move and
rename inside it as freely as before. Each move is a row write instead of a
file operation.

!!!danger Never let an \*arr move the old library into `__magic__`
Changing a series or movie root folder makes Sonarr or Radarr offer to **move**
the files. Say no. A move inside `__magic__` is free. A move from anywhere else crosses the
mount boundary and that is a copy. So is a move between two volumes of the same
mount. In Docker give the \*arr one volume that holds zurg's whole mount. A copy off a streaming mount pulls your
entire library down through your news or debrid allowance. Your old library is
a tree of symlinks so what gets copied is every target they resolve to.
!!!

Move each file into place yourself instead. Every move is one rename through
zurg's mount. Nothing is copied and nothing on your account changes. The script
below does it from your old library of symlinks. A link's path under the old
root folder is where Sonarr or Radarr expects the episode or film. Its target
names the file. So each file lands at the same path under the new root folder
that its link had under the old one. The old library is only read. It keeps
working until you switch the \*arr over.

1. **Build zurg beside the old server** as its page shows. Let it list the
   whole library first.
2. **Turn on `__magic__`** as its page shows. Keep Plex scans off and the
   \*arr queues paused.
3. **Save the `zurg_path` function from your server's page** as
   `zurg_path.sh` beside the script. It turns an old link's target into the
   file zurg serves. Each server lays its files out differently.
4. **Run the script** once per root folder. Set `OLD` and `NEW` and `LOG` for
   each one. A setup with `sonarr4k` and `radarr4k` beside the regular pair
   needs four runs.

   ```bash
   #!/bin/bash
   # adopt.sh — move every file an old root folder links to into __magic__.
   # One rename per file through zurg's mount. Nothing is copied or downloaded.
   # The old root folder is only read. GNU find and bash required.
   ZURG=/mnt/zurg                  # zurg's own mount
   OLD=/data/media/tv              # the old root folder, a tree of symlinks
   NEW="$ZURG/__magic__/tv"        # the new root folder inside __magic__
   LOG=./adopt-tv.log              # what went where
   . ./zurg_path.sh                # the zurg_path function from your server's page
   find "$OLD" -type l | while IFS= read -r link; do
     dest="$NEW/${link#"$OLD"/}"
     [ -e "$dest" ] && { echo "ALREADY THERE: $dest"; continue; }
     src=$(zurg_path "$(readlink "$link")")
     [ -n "$src" ] && [ -f "$src" ] || { echo "NOT IN ZURG: $link"; continue; }
     mkdir -p "$(dirname "$dest")"
     if mv "$src" "$dest"; then
       printf '%s\t%s\n' "$src" "$dest" >> "$LOG"
     else
       echo "FAILED: $link"
     fi
   done
   # Real files such as subtitles are small. They are copied and land on zurg's own disk.
   find "$OLD" -type f -size -32M | while IFS= read -r file; do
     dest="$NEW/${file#"$OLD"/}"
     [ -e "$dest" ] || { mkdir -p "$(dirname "$dest")" && cp "$file" "$dest"; }
   done
   ```

   It prints a line for every link it leaves alone.

   - `NOT IN ZURG` is a link to a file zurg does not have. Its NZB could not be
     recovered or its account is not in zurg's config.
   - `FAILED` is a move zurg refused. A second link to a file the script
     already moved prints this after a line from `mv` that says `No such file
     or directory`. A file can sit at only one path in `__magic__`. It stays
     where the first link put it.
   - `ALREADY THERE` is a path the new root folder already holds. Running the
     script again skips everything it placed before.

5. **Switch each \*arr over.** Select every series or every movie and edit them
   together. Set the root folder to the new one under `__magic__`. When it asks
   whether to move the files answer **No, I'll Move the Files Myself**. The
   script already put them there. Then run **Update All** so it finds them.
6. **Point Plex at the new root folders** and at nothing else. The next box
   says why.

Each move took about 15 milliseconds on a test library and nothing was copied.
Watch `data/local` on zurg's `/magic/` dashboard while the script runs. It
grows only by the subtitles and other small files the script copies. A number
that grows by gigabytes means something is being copied. Stop and look.

The old links keep working. A moved file still shows at its old `__all__` path
as well as at its new one. Builds before the 2026.10.04 nightly hid it at the
old path for up to 12 hours even though zurg still served it there. On one of
those builds restart zurg once the script is done. Keep Plex away from the old
folders and from `__all__` until you have.

The zurg side of this was measured on 2026-10-03. The \*arr side is its
ordinary root folder edit and was not tested for this guide. Do one series
first.

!!!warning Point each Plex library at one directory and not two
A library that scans a filter directory such as `movies` or `shows` or
`__all__` **and** scans `__magic__` finds every episode twice — and `__magic__`
holds its own `__all__`, so pointing a library at the root of the namespace
scans the whole library along with what you organised. Pick one. If you use the
\*arrs then point Plex at the root folders you made, `__magic__/tv` and
`__magic__/movies`. If you browse a library nobody organises then pick the
filter directories and leave `__magic__` off.
!!!

## Die eine Sicherung, die du nicht überspringen darfst {#the-one-guard-you-must-not-skip}

**`autoEmptyTrash` muss auf `0` stehen, bevor du irgendetwas anfasst.**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Unter Windows, in PowerShell:

```powershell
$TOKEN = 'your-plex-token'
((Invoke-RestMethod "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN").MediaContainer.Setting | Where-Object id -eq autoEmptyTrash).value
# set it if needed:
curl.exe -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Plex zeigt die Einstellung als `0` oder `false` an, wenn sie aus ist.

Plex löscht nur weich. Bei `0` landet ein Eintrag, dessen Datei nicht mehr existiert, im Papierkorb und kommt zurück, wenn die Datei wieder da ist. Bei `1` ist er sofort und endgültig weg, sobald ein Scan es bemerkt. Ein Mount, der während eines Scans zehn Sekunden lang hakt, nimmt dir damit die ganze Bibliothek mit. Das hat schon einmal zehntausende Einträge gekostet.

Bei diesen vereinfachten Anleitungen macht diese Einstellung mehr Arbeit als früher und nicht weniger. **Der Papierkorb ist der Ort, an dem deine alten Einträge warten, während du die neuen prüfst.** Leere ihn erst, wenn du zufrieden bist, und nicht vorher. Das ist der Schritt, der den Verlust real macht, und er ist das Einzige in all diesen Anleitungen, was sich nicht rückgängig machen lässt.

Wenn du schon dabei bist, schalte außerdem **"Generate video preview thumbnails"** für die betroffenen Bibliotheken aus. Bei einem Streaming-Mount ist jeder Thumbnail-Durchlauf ein vollständiges Lesen des Releases über dein Usenet- oder Debrid-Kontingent. Eine Migration übergibt Plex auf einmal sehr viele neue Einträge.

## Was jede Migration bringt {#what-every-migration-gains}

Zwei davon sind neue Dateien, die in Ordnern auftauchen, die Plex sowieso schon scannt. Es lohnt sich, sie zu kennen, bevor sie dich überraschen.

- **Beispielclips.** zurg ist das einzige der fünf Tools, das die Beispieldatei aus dem `Sample/`-Ordner eines RAR-Releases ausliefert. Plex könnte eine 9 MB große `-sample.mp4` als Extra oder als zweite Version der Episode erkennen. Wenn dir das nicht gefällt, setze
  [`only_show_the_biggest_file: true`](../reference/config.md) auf den Ordnern, die deine Medienbibliotheken scannen.
- **`.nfo`-Dateien.** zurg ist das einzige, das sie behält. Unter den Standard-Agenten von Plex haben sie keine Wirkung. Der XBMC and NFO agent liest sie, wenn du ihn verwendest.
- **`thumbnail.jpg` und `.url`-Werbung.** Harmlos. `thumbnail.jpg` ist kein Dateiname, den Plex für Poster verwendet, und die `.url`-Dateien sind Werbung des Poster-Anbieters.
- **Leere Ordner**, wenn die Archivkette eines Releases unterbrochen ist. Plex ignoriert Ordner ohne Medien darin.
- **par2- und sfv-Dateien verschwinden.** zurg blendet sie aus, indem es den tatsächlichen Dateityp liest und nicht den Dateinamen. Plex hat sie nie als Medien aufgeführt, deshalb merkst du davon in deiner Bibliothek nichts. Nur Tools, die diese Dateien durchsucht haben, sind betroffen.

## Die Anleitungen {#the-guides}

- [Von AltMount](altmount.md). Benennt nur Archiv-Releases um
- [Von decypharr](decypharr.md). Benennt Einzeldatei- und Archiv-Releases um
- [Von InfiniDysk](infinidysk.md). Benennt Einzeldatei- und Archiv-Releases um
- [Von nzbdav](nzbdav.md). Benennt nichts um und ist der einfachste der fünf
- [Von streamnzb](streamnzb.md). Keine Bibliothek zum Migrieren. zurg hat ein eigenes Stremio-Addon

Willst du von Plex weg, statt zu zurg? [Von Plex zu rex wechseln](../../rex/from-plex.md) behält zurg und deine Plex-Apps bei und lässt rex neben deinem Plex-Server oder anstelle davon laufen.

Das Benennungsverhalten auf jeder Seite wurde am 2026-09-01 an einem Korpus mit fünf Releases gemessen. Die Builds waren zurg `bda7e3c3`, AltMount `0614008b`, InfiniDysk `cd9b1205`, nzbdav `794948be` und decypharr `0dd1cbbd`. Ein Build, der älter oder neuer ist als diese, benennt Dinge möglicherweise anders. Prüfe vor dem Vertrauen auf eine Rescan-Liste insgesamt ein paar Releases gegen deinen eigenen Tree.
