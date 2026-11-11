# Von InfiniDysk zu zurg migrieren {#migrating-from-infinidysk-to-zurg}

Lies zuerst [die gemeinsame Seite](index.md). Sie erklärt den Trash-Guard und warum deine Bibliothek in `__magic__` landet.

Gemessen gegen zurg mit denselben fünf Releases.

| | |
|---|---|
| zurg gewinnt | den Sample-Clip, die `.nfo` |
| zurg verliert | 5 hash-benannte par2-Volumes in verschleierten Releases |
| umbenannt | **jedes Release außer den Multi-Datei-Releases** |

!!!warning Das Umbenennen ist die ganze Migration
InfiniDysk benennt die Mediendatei eines Releases in den NZB-Dateinamen um, sobald das Release auf eine einzelne Nutzlast aufgelöst wird. Im Korpus vom 2026-09-01 wurden vier von fünf zu `ToyStory5.mkv`, `Obfuscated.mkv`, `FatherBrown.mp4` und `MandaloriaREMUX.mkv`. Nur das Staffelpaket mit zehn Episoden behielt seine Episodennamen.
Die Umbenennung greift auf jeder Ebene. `FatherBrown.mp4` liegt *innerhalb* des erhaltenen Verzeichnisses `Father.Brown.2013.S02E05.HDTV.x264-TLA/`.

zurg behält den Dateinamen des Uploaders bei. Der Release-Name kommt damit zurück, und jedes Release mit einer einzelnen Nutzlast ändert seinen Pfad. Dieser Name ist der String, den Plex und die \*arrs für Qualität, Gruppe und Episode auswerten.
!!!

Ein weiterer Unterschied ist klein, aber verwirrend, wenn man ihn unvorbereitet trifft. InfiniDysk legt das `Sample/`-Verzeichnis des Archivs an und lässt es **leer**. zurg legt den Sample-Clip darin ab.

Der Inhalt ist nicht der Grund für den Wechsel. Build `cd9b1205` hat alle fünf Releases des Referenzkorpus importiert, inklusive des Staffelpakets. Erwarte nicht, dass InfiniDysk etwas verwirft. Was du zurückbekommst, sind die Namen.

!!!warning Lauf niemals die WebDAV-Wurzel ab
Der `.ids`-Objektspeicher legt auf allen fünf Ebenen alle 16 Hex-Unterverzeichnisse an, unabhängig vom Inhalt. Das sind 16^5, also etwa 1,048,576 Verzeichnisse. Gib `find`, `du`, `rclone` und jedem Scanner explizit `/content`, `/nzbs` oder `/completed-symlinks` an. Niemals `/`.
!!!

## Wie deine Bibliothek danach aussieht {#what-your-library-looks-like-afterwards}

**Alles wird neu hinzugefügt**, weil der Bibliotheks-Root nach `__magic__` wechselt. Siehe [die gemeinsame Seite](index.md), warum es keinen günstigeren Weg gibt.

Das ist die Migration, bei der du am wenigsten verlierst und am meisten gewinnst. Fast alle Dateinamen werden besser. Aus `ToyStory5.mkv` wird `Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`, und ein \*arr, der aus `__magic__` neu importiert, kann endlich Qualität, Quelle, Gruppe und Edition direkt aus dem Dateinamen lesen. Nur die Staffel-Packs bleiben so, wie sie sind, und die werden schon richtig gelesen.

Liste die Releases auf, deren Namen sich ändern. Es werden die meisten sein.

```bash
ID=/mnt/remote/nzbdav                      # your InfiniDysk mount
find "$ID/content" -mindepth 3 -maxdepth 4 -type f | while IFS= read -r f; do
  rel=$(basename "$(dirname "$f")")
  b=$(basename "$f")
  [ "${b%.*}" = "$rel" ] && echo "RENAMED BY INFINIDYSK: $f"
done
```

Das `-maxdepth 4` ist wichtig, weil die Umbenennung eine Ebene innerhalb eines Archivverzeichnisses passieren kann.

!!!info Ob du davon etwas siehst, hängt von deinem Setup ab
Wenn Plex den Mount direkt liest, dann sind die oben genannten Namen das, was sich in deiner Bibliothek ändert. Das betrifft jedes Windows-Setup und jedes Linux- oder macOS-Setup ohne eine \*arr-Symlink-Farm.

Wenn Sonarr und Radarr eine Symlink-Bibliothek mit aktivem Umbenennen organisieren, **dann haben deine Dateinamen schon ihre Namen** und keiner der oben genannten Namen taucht in Plex auf. Was dir die Namen dann verraten, ist, wie gut das Parsing war, mit dem der \*arr gearbeitet hat. Das ist wichtig, wenn du neu importierst. Siehe [die gemeinsame Seite](index.md).
!!!

## Welche neuen Inhalte auftauchen {#what-new-content-shows-up}

- **Beispielclips.** Die `Sample/`-Ordner, die du schon hast, sind nicht mehr leer. Das ist die Einstellung, die sich am meisten lohnt. Setz [`only_show_the_biggest_file: true`](../reference/config.md), wenn du nicht willst, dass ein 9 MB großes Sample als zweite Version der Episode auftaucht.
- Die `.nfo` in RAR-Releases. Ohne Wirkung bei Plex' Standard-Agents.
- Leere Ordner, wo eine Archivkette unterbrochen ist. InfiniDysk hat dafür nichts angelegt.
- **par2- und sfv-Dateien werden nicht mehr sichtbar.** Das betrifft auch die Hash-benannten Volumes in verschleierten Releases. Sie haben keine Medienendung, deshalb listet Plex sie nicht auf. Wenn irgendwelche Tools von dir außer Plex diese Dateien durchsucht haben, fällt das jetzt auf.

## Hol deine NZBs raus {#get-your-nzbs-out}

zurg wird von einem Verzeichnis mit `.nzb`-Dateien gespeist. Eine pro Release, benannt nach dem Release-Ordner. InfiniDysks WebDAV `/nzbs/<category>/` spiegelt die Warteschlange und ist lesbar.

```bash
mkdir -p ~/recovered-nzbs
rclone copy infinidysk:nzbs ~/recovered-nzbs/ --include '*.nzb'   # scoped to /nzbs, never the root
find ~/recovered-nzbs -name '*.nzb' | wc -l
```

Ob abgeschlossene Jobs unter `/nzbs` aufgelistet bleiben, nachdem sie fertig sind, ist **nicht verifiziert**. Der Ordner spiegelt die Warteschlange, und dein Verlauf könnte tiefer gehen als die Warteschlange. Für alles, was fehlt: Die NZB-Metadaten, die InfiniDysk zum erneuten Mounten behält, liegen in `{CONFIG_PATH}/blobs/`. Das Blob-Format ist nicht verifiziert, also prüf es, bevor du dich darauf verlässt.

```bash
for f in "$CONFIG_PATH"/blobs/*; do head -c 32 "$f" | grep -q '<?xml' && echo "NZB: $f"; done
```

Wenn Blobs auf deiner Installation kein einfaches XML sind, dann ist der Download-Verlauf deines Indexers der Fallback.

Erstelle danach für jeden Release-Ordner, den du wirklich hast, eine Datei `<release>.nzb`.

```bash
find "$ID/content" -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | awk -F/ '{print $1 "\t" $2}' > releases.tsv
```

NZBs, die du aus `/nzbs/<category>/` holst, haben meist schon den richtigen Namen. Daher kommt ja der Ordnername. Zwei zurg-Namensregeln solltest du trotzdem gegen die Liste prüfen.

- zurg entfernt eine abschließende `.mkv` oder `.mp4` vom Ordnernamen. Endet ein Release-Ordner so, dann setz `retain_folder_name_extension: true`.
- Haben zwei verschiedene Releases denselben Namen, bekommt einer von ihnen das Suffix ` {shorthash}`. Finde sie mit `cut -f2 releases.tsv | sort | uniq -d`. InfiniDysk hatte dasselbe Problem auf andere Weise. Ein erneuter Import einer NZB erzeugte dort `<Release> (2)`.

## zurg parallel aufbauen {#build-zurg-alongside}

InfiniDysk läuft während der ganzen Zeit weiter.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from InfiniDysk's provider settings
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
enable_repair: true
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp ~/recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l          # should approach your release count
```

`__all__` enthält jede Veröffentlichung, unabhängig von den Verzeichnisfiltern.

## Umschalten {#cut-over}

Nimm einen dieser Wege, je nachdem, was du heute hast. Hier werden keine Daten verschoben.

**1. Schalte `__magic__` ein** und starte neu. Die Routen werden beim Start registriert. Deshalb muss der Namespace nach einem Dashboard-Schalter erst nach einem Neustart antworten.

```yaml
magic:
  enabled: true
```

**2. Lege die Root-Ordner an.** Sie kommen in die Root-Ebene von `__magic__`, neben das `__all__`, das zurg dort behält. Nicht `__magic__/__all__`, nicht `__magic__` selbst und auch nicht die Mount-Wurzel. Beide \*arrs melden für diese Orte einen Health-Check-Fehler. Geschwisterordner lösen keinen aus.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` spiegelt die Bibliothek, damit jede Veröffentlichung schon da ist, bevor du etwas sortierst.

**3. Sortiere.** Ein `mv` innerhalb von `__magic__` schreibt nur einen Eintrag und verschiebt keine Daten.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Wenn Sonarr und Radarr deine alte Bibliothek sortiert haben, holst du sie mit einem Skript herein.** Es benennt jede Datei, auf die die alte Bibliothek verlinkt, in einen neuen Root-Ordner unter `__magic__` um. Jede landet an dem Pfad, den der \*arr schon erwartet. Nichts wird kopiert. Danach änderst du den Root-Ordner des \*arr, ohne dass er etwas verschiebt. Die Schritte und das Skript findest du [auf der gemeinsamen Seite](index.md#coming-off-a-symlink-library). Lass einen \*arr die Dateien nie selbst verschieben. Dabei wird die Mount-Grenze überschritten. Das ist eine Kopie, und sie lädt deine Bibliothek komplett herunter.

Das Skript braucht eine Funktion `zurg_path` für die Links von InfiniDysk. Speichere sie als `zurg_path.sh` neben dem Skript und setze `OLDMOUNT` auf den Ort, an dem InfiniDysk eingehängt ist.

```bash
OLDMOUNT=/mnt/remote/infinidysk # InfiniDysk's mount, where the old links point
# The map from each .ids name to its release and file. Built once while InfiniDysk runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # InfiniDysk named a lone video after the release. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Die Links von InfiniDysk zeigen in seinen `.ids`-Speicher, und zurg hat so etwas nicht. Deshalb liest die Funktion einmal den `completed-symlinks`-Baum von InfiniDysk aus. So erfährt sie, welche Veröffentlichung und welche Datei hinter jedem `.ids`-Namen steckt. Lass InfiniDysk laufen, bis das Skript fertig ist. Hat InfiniDysk ein einzelnes Video nach der Veröffentlichung benannt, nimmt die Funktion das eine Video, das zurg in dieser Veröffentlichung ausliefert. Eine Veröffentlichung mit mehr als einem Video wird nie geraten. Stattdessen gibt das Skript `NOT IN ZURG` aus.

**4. Zeige Plex auf die Root-Ordner, die du angelegt hast**, also `__magic__/tv` und `__magic__/movies`, und nur auf diese. Nie auf die Root-Ebene von `__magic__`. Dort liegt auch die ganze Bibliothek unter `__magic__/__all__`, und dann würde jede Episode zweimal gefunden. Auch `__magic__` *und* ein Filterordner zusammen sind tabu, aus demselben Grund. Prüfe, dass `autoEmptyTrash` auf `0` steht. Füge den neuen Ort hinzu und starte einen Scan. Danach entfernst du den alten. Das ist der Bibliothekspfad deines \*arr oder der InfiniDysk-Mount, falls Plex ihn direkt gelesen hat.

**5. Leere den Papierkorb**, sobald du ein paar Einträge stichprobenartig geprüft hast. Der Wiedergabestatus kommt über den GUID-Abgleich zurück. Sammlungen und Cover-Bilder-Auswahl nicht.

Lass InfiniDysk bis dahin laufen. Es kostet nichts, und es ist dein Rückweg. Wenn du fertig bist, stoppe es.

```bash
sudo systemctl stop infinidysk infinidysk-rclone-mount
```

## Danach {#afterwards}

Behalte `{CONFIG_PATH}/blobs/` und dein wiederhergestelltes NZB-Set, bis du von einer repräsentativen Stichprobe gestreamt hast.

Jetzt zur Beschaffung. zurg hat einen optionalen [SABnzbd-kompatiblen Endpunkt](../guides/sonarr-radarr.md), über den Sonarr und Radarr Downloads holen können. Er ersetzt InfiniDysk als deren Download-Client. Der Grab landet in `__magic__/__all__`, und der Import verschiebt ihn per Umbenennung heraus. Es wird nichts kopiert.
zurg prüft jeden Grab, bevor er als fertig gemeldet wird. Dafür fragt zurg die Newsserver nach Anfang und Ende jeder Datei. Außerdem lädt es den ersten Artikel jeder Datei herunter. Das sind bis zu vierundsechzig davon plus ein paar mehr bei einem Release mit nur wenigen Dateien. Manche Newsserver behaupten noch, dass ein Artikel existiert, obwohl sein Inhalt entfernt wurde, und nur ein Download zeigt das. zurg baut ein Release mit fehlenden Artikeln nach Möglichkeit aus dessen PAR2-Dateien wieder auf. Eines, das sich nicht wiederherstellen lässt, wird als **Failed** gemeldet. Dann setzen die \*arrs es auf die Blockliste und holen sich ein anderes.
Die Prüfung ist eine Stichprobe und nicht der ganze Post. Ein Post, der eine Lücke hat, die die Stichprobe nicht erreicht hat, wird trotzdem als Completed gemeldet und schlägt erst beim Lesen fehl, das auf die Lücke trifft.
Halte die Root-Ordner der \*arrs innerhalb von `__magic__`. Ein Root-Ordner irgendwo anders erzeugt bei jedem Import eine vollständige Kopie. In Docker gib dem \*arr ein einziges Volume, das das gesamte Mount von zurg enthält. Ein Download-Ordner und Root-Ordner auf zwei Volumes kopieren bei jedem Import ebenfalls. Siehe [ein Volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
