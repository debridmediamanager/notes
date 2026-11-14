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

Du baust keine Bibliothek um, du baust sie neu auf. Und `__magic__` gibt den
\*arrs genau das, was die Symlink-Farm geliefert hat, nur ohne die Farm. Sie können
darin genauso frei verschieben und umbenennen wie vorher. Jeder Verschiebevorgang ist
ein Zeilenschreibvorgang statt einer Dateioperation.

!!!danger Lass niemals einen \*arr die alte Bibliothek nach `__magic__` verschieben
Wenn du den Root-Ordner einer Serie oder eines Films änderst, bieten Sonarr oder Radarr an, die Dateien zu **verschieben**.
Sag Nein. Ein Verschieben innerhalb von `__magic__` ist kostenlos. Ein Verschieben von irgendwo anders
überschreitet die Mount-Grenze, und dann wird kopiert. Dasselbe gilt für ein Verschieben zwischen zwei Volumes
desselben Mounts. Gib den \*arr in Docker ein einziges Volume, das den gesamten Mount von zurg enthält. Ein Kopieren
von einem Streaming-Mount zieht deine komplette Bibliothek über dein Usenet- oder Debrid-Kontingent herunter. Deine alte Bibliothek
ist ein Baum aus Symlinks, also wird alles kopiert, worauf sie zeigen.
!!!

Verschiebe stattdessen jede Datei selbst an ihren Platz. Jeder Verschiebevorgang ist ein einzelnes Umbenennen über
den Mount von zurg. Nichts wird kopiert und an deinem Account ändert sich nichts. Das Skript
erledigt das aus deiner alten Bibliothek aus Symlinks. Der Pfad eines Links unter dem alten
Root-Ordner ist der Ort, an dem Sonarr oder Radarr die Episode bzw. den Film erwartet. Das Ziel
des Links nennt die Datei. Jede Datei landet also unter dem neuen Root-Ordner
im selben Pfad, den ihr Link unter dem alten hatte. Die alte Bibliothek wird nur gelesen. Sie
funktioniert weiter, bis du die \*arr umstellst.

1. **Baue zurg neben dem alten Server auf**, so wie es auf seiner Seite beschrieben ist. Lass es zuerst die
   komplette Bibliothek auflisten.
2. **Schalte `__magic__` ein**, so wie es auf seiner Seite beschrieben ist. Lass Plex-Scans aus und
   pausiere die \*arr-Warteschlangen.
3. **Speichere die Funktion `zurg_path` von der Seite deines Servers** als
   `zurg_path.sh` neben dem Skript. Sie macht aus dem Ziel eines alten Links die
   Datei, die zurg ausliefert. Jeder Server legt seine Dateien anders ab.
4. **Führe das Skript** einmal pro Root-Ordner aus. Setze `OLD`, `NEW` und `LOG` für
   jeden davon. Hast du `sonarr4k` und `radarr4k` neben dem normalen Paar, brauchst du vier Durchläufe.

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

   Es gibt eine Zeile für jeden Link aus, den es unangetastet lässt.

   - `NOT IN ZURG` bedeutet, dass zurg die Datei zu einem Link nicht hat. Ihre NZB
     konnte nicht wiederhergestellt werden oder ihr Account ist nicht in der Konfiguration von zurg eingetragen.
   - `FAILED` ist ein Verschieben, das zurg abgelehnt hat. Ein zweiter Link auf eine Datei, die das Skript
     schon verschoben hat, gibt das aus, nachdem `mv` die Zeile `No such file
     or directory` ausgibt. Eine Datei kann in `__magic__` nur an einem Pfad liegen. Sie bleibt
     dort, wohin der erste Link sie gelegt hat.
   - `ALREADY THERE` ist ein Pfad, den der neue Root-Ordner schon enthält. Wenn du das Skript
     erneut startest, überspringt es alles, was es schon vorher platziert hat.

5. **Stelle jede \*arr um.** Wähle alle Serien oder alle Filme aus und bearbeite sie
   gemeinsam. Setze den Root-Ordner auf den neuen unter `__magic__`. Wenn gefragt wird, ob die Dateien
   verschoben werden sollen, antworte **No, I'll Move the Files Myself**. Das Skript
   hat sie bereits dorthin gebracht. Starte dann **Update All**, damit sie gefunden werden.
6. **Richte Plex auf die neuen Root-Ordner** und auf nichts anderes. Der nächste Kasten
   erklärt warum.

Jeder Verschiebevorgang hat auf einer Testbibliothek etwa 15 Millisekunden gedauert, und es wurde nichts kopiert.
Beobachte `data/local` im `/magic/`-Dashboard von zurg, während das Skript läuft. Der Wert wächst nur um
die Untertitel und andere kleine Dateien, die das Skript kopiert. Wächst die Zahl um Gigabytes, wird etwas kopiert.
Dann hör auf und schau nach.

Die alten Links funktionieren weiter. Eine verschobene Datei ist unter ihrem alten `__all__`-Pfad
genauso noch sichtbar wie unter dem neuen. Builds vor dem Nightly vom 2026.10.04 haben sie unter dem alten Pfad
bis zu 12 Stunden lang ausgeblendet, obwohl zurg sie dort noch auslieferte. Bei einem dieser Builds
startest du zurg einmal neu, wenn das Skript fertig ist. Halte Plex von den alten Ordnern und von `__all__` fern,
bis du das getan hast.

Die zurg-Seite dieser Anleitung wurde am 2026-10-03 getestet. Die \*arr-Seite ist die normale
Bearbeitung des Root-Ordners und wurde für diese Anleitung nicht getestet. Probiere es zuerst mit einer Serie.

!!!warning Richte jede Plex-Bibliothek auf ein Verzeichnis und nicht auf zwei
Eine Bibliothek, die ein Filterverzeichnis wie `movies`, `shows` oder
`__all__` **und** `__magic__` scannt, findet jede Episode doppelt. Und `__magic__`
enthält seinen eigenen `__all__`. Zeigst du eine Bibliothek auf die Wurzel des Namensraums, scannt sie also die ganze Bibliothek
zusammen mit dem, was du sortiert hast. Wähle eins. Nutzt du die \*arrs, richte Plex auf die Root-Ordner, die du angelegt hast,
also `__magic__/tv` und `__magic__/movies`. Durchsuchst du eine Bibliothek, die niemand sortiert, nimmst du die
Filterverzeichnisse und lässt `__magic__` weg.
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
