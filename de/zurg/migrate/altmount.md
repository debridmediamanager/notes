# Von AltMount zu zurg migrieren {#migrating-from-altmount-to-zurg}

Lies [die gemeinsame Seite](index.md) zuerst. Sie erklärt den Trash-Wächter und warum deine Bibliothek in `__magic__` landet.

AltMount liefert den saubersten Baum der fünf. Genau eine Datei pro Release. Keine Thumbnails, keine Werbung, kein Sample und keine Reste. Die Migration ist entsprechend klein, weil es dort kaum etwas gibt, worüber man sich streiten könnte.

Gemessen an zurg bei denselben fünf Releases.

| | |
|---|---|
| zurg bekommt zusätzlich | den Sample-Clip, die `.nfo`, `thumbnail.jpg`, die `.url`-Werbedateien, das innere Verzeichnis des Archivs, **und jedes Release, das AltMount abgelehnt hat** |
| zurg verliert | nichts |
| umbenannt | **nur Archiv-Releases (RAR)** |

!!!info Nur der Archiv-Pfad benennt um
Bei drei unabhängigen Durchläufen mit Build `0614008b` behielten die einfachen Einzeldatei-Releases den Dateinamen des Posters. Das gilt auch für eines, dessen interner Name vom NZB-Namen abweicht, und für ein vollständig verschleiertes. Nur das Release, das aus einem RAR entpackt werden musste, kam als `<NZB name>.mp4` heraus.

Ältere AltMount-Builds haben mehr umbenannt als das. Prüf deinen eigenen Baum, bevor du der Liste unten vertraust. Der eine Befehl unter „Wie deine Bibliothek danach aussieht“ sagt dir das in Sekunden.
!!!

## Das größere Problem ist, was AltMount nie importiert hat {#the-bigger-issue-is-what-altmount-never-imported}

AltMount hat bei jedem von vier Durchläufen ein 10-Folgen-Staffelpaket abgelehnt. Die Artikel waren vorher nachweislich auf dem News-Server vorhanden.

```
fast-fail segment check inconclusive: 93 segment(s) remained
unverified after 3 attempts: context deadline exceeded
```

Die Prüfung ist nicht deterministisch. Dasselbe Release kam einmal mit 196 nicht verifizierten Segmenten zurück, dann mit 93 und dann mit 76. Außerdem hängt sie von der Größe ab. Mit `import.segment_sample_percentage: 1` werden 1 % der Segmente geprüft, daher braucht ein größeres Release mehr STATs, um innerhalb der Frist fertig zu werden. Beim Test gegen einen *schnelleren* News-Host wurden sogar mehr Releases abgelehnt statt weniger. Dieser Durchlauf hat sowohl das Staffelpaket als auch einen 41-GB-Remux verloren. Die Latenz ist also nicht die Erklärung.

Für dich heißt das praktisch Folgendes: **Die Releases, die AltMount stillschweigend nie veröffentlicht hat, sind genau die, die zurg hinzufügen wird.** Dafür gibt es in Plex bisher keinen Eintrag, also geht nichts verloren und nichts ist gefährdet. Sie tauchen einfach auf. Wenn deine Bibliothek kleiner ist als deine NZB-Sammlung, liegt es daran.

Wenn AltMount während der Migration weiter importieren soll, kannst du `segment_sample_percentage` senken. Das habe ich hier aber nicht getestet.

## Wie deine Bibliothek danach aussieht {#what-your-library-looks-like-afterwards}

**Alles wird neu hinzugefügt**, weil die Bibliotheks-Wurzel nach `__magic__` wandert. Warum es keinen günstigeren Weg gibt, steht auf [der gemeinsamen Seite](index.md).

Beim Umzug ändert sich nicht viel. Einzeldateien behalten den Dateinamen, den AltMount ihnen gegeben hat, dadurch sieht der Großteil der Bibliothek gleich aus. **Archiv-Releases tauchen unter dem Namen des Posters auf**, eine Ebene tiefer. Für einen \*arr ist das eindeutig besser. Der Name `father.brown.2013.s02e05.hdtv.x264-tla.mp4` enthält die Qualität, die Quelle und die Gruppe, die `FatherBrown.mp4` weggeworfen hat.

Archiv-Releases findest du, indem du nach einem Mount-Ordner suchst, dessen einzige Datei nach dem Ordner benannt ist.

```bash
AM=/mnt/altmount
for d in "$AM"/*/; do
  r=$(basename "$d")
  for f in "$d"*; do
    b=$(basename "$f")
    [ "${b%.*}" = "$r" ] && echo "RENAMED BY ALTMOUNT: $f"
  done
done
```

!!!info Ob du davon etwas siehst, hängt von deinem Setup ab
Wenn Plex den Mount direkt liest, dann sind die oben genannten Namen das, was sich in deiner Bibliothek ändert. Das gilt für jedes Windows-Setup und für jedes Linux- oder macOS-Setup ohne eine \*arr-Symlink-Farm.

Wenn Sonarr und Radarr eine Symlink-Bibliothek mit aktiviertem Umbenennen organisieren, dann **sind deine Dateinamen schon deren Namen** und keiner der oben genannten Namen erscheint in Plex. Was die Namen dann verraten, ist, wie gut das Parsing war, mit dem der \*arr gearbeitet hat. Das ist wichtig, wenn du neu importierst. Siehe [die gemeinsame Seite](index.md).
!!!

## Welche neuen Inhalte auftauchen {#what-new-content-shows-up}

AltMount veröffentlicht nichts davon, daher gilt für dich alles aus der Liste auf der gemeinsamen Seite.

- **Sample-Clips** im Ordner `Sample/`. Das ist der eine Punkt, den es sich zu konfigurieren lohnt. Setze [`only_show_the_biggest_file: true`](../reference/config.md), wenn du nicht möchtest, dass ein 9 MB großes Sample als zweite Version auftaucht.
- `thumbnail.jpg`, die `.nfo` und die `.url`-Werbedateien des Posters. Das sind alles harmlose Dateien ohne Funktion.
- **Ganze Releases, die AltMount abgelehnt hat**, tauchen als neue Bibliothekseinträge auf.
- Leere Ordner, wo eine Archivkette unterbrochen ist.

## Hol deine NZBs raus {#get-your-nzbs-out}

AltMount hat jede NZB, die du ihm gegeben hast, übernommen. Das Original wurde verschoben, und eine komprimierte Kopie liegt unter
`<config>/.nzbs/<category>/<queueID>-<name>.nzbz`. Die Zuordnung vom Mount-Ordner zur `.nzbz`-Datei steht in den `.meta`-Dateien unter
`<config>/metadata/complete/<Release>/`. Diese sind binär, beginnen mit der Magic `AM3`, und der `.nzbz`-Pfad steht darin als einfacher String.

zurg will eine `.nzb` pro Release, benannt nach dem Release und flach in `nzbs/`. Unterordner werden übersprungen. Der Verzeichnisname `metadata/complete/<Release>` *ist* der Mount-Ordnername, und genau diesen Namen soll die Datei bekommen.

```bash
AM=/path/to/altmount/config          # holds altmount.db, .nzbs/, metadata/
OUT=./recovered-nzbs
mkdir -p "$OUT"
for dir in "$AM"/metadata/complete/*/; do
  release=$(basename "$dir")
  meta=$(find "$dir" -maxdepth 1 -name '*.meta' | head -1)
  [ -n "$meta" ] || { echo "NO META: $release" >&2; continue; }
  nzbz=$(strings "$meta" | grep -m1 '\.nzbz$')
  case "$nzbz" in "") echo "NO NZBZ REF: $release" >&2; continue ;;
                  /*) src=$nzbz ;; *) src="$AM/$nzbz" ;; esac
  [ -f "$src" ] || { echo "NZBZ MISSING: $release" >&2; continue; }
  [ -e "$OUT/$release.nzb" ] && { echo "NAME COLLISION: $release" >&2; continue; }
  if zcat "$src" > "$OUT/$release.nzb" 2>/dev/null && grep -q '<nzb' "$OUT/$release.nzb"; then
    echo "OK: $release"
  else
    rm -f "$OUT/$release.nzb"
    echo "NOT A GZIPPED NZB: $release. Use the API export instead" >&2
  fi
done
```

Bei der gemessenen v0.3.2-Installation war die `.nzbz` eine gzip-Kopie der importierten NZB. Die Quelle enthält außerdem einen zstd-protobuf-Pfad für diese Dateien, deshalb ist die Prüfung mit `zcat` und `grep` nicht übertrieben. Was abgelehnt wird, geht stattdessen über die API. `GET /api/files/export-nzb?path=<virtual path>` erzeugt aus dem Store eine originalgetreue NZB neu, und `POST /api/files/export-batch` gibt eine ZIP zurück. Beide brauchen einen JWT statt des API-Schlüssels.

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

Virtuelle Pfade holst du dir aus der Dateiansicht der AltMount-UI oder aus `/api/files/info`, statt das Format zu raten. Der Download heißt `<queueID>-<name>.nzb`. Benenne ihn in `<Release>.nzb` um, damit zurg den Ordner richtig benennt.

Eine Plausibilitätsprüfung: Die Anzahl der wiederhergestellten `.nzb`-Dateien sollte der Anzahl der Verzeichnisse `metadata/complete/*/` entsprechen.

## zurg parallel aufbauen {#build-zurg-alongside}

AltMount läuft die ganze Zeit weiter. Starte zurg auf Port 9999. Es gibt keinen Konflikt mit AltMounts 8585.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy host/port/TLS/credentials from AltMount
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l
```

Erwarte hier **mehr** Ordner als bei AltMount. Das ist die Klasse der refused-import-Einträge, die jetzt auftauchen.

## Umschalten {#cut-over}

Ein Weg, egal was du gerade hast. Hier werden keine Bytes verschoben.

**1. Schalte `__magic__` ein** und starte neu. Die Routen werden beim Start registriert, daher braucht ein Schalter im Dashboard einen Neustart, bevor der Namespace antwortet.

```yaml
magic:
  enabled: true
```

**2. Lege die Stammordner an.** Sie kommen in die Wurzel von `__magic__`, neben das `__all__`, das zurg dort behält. Nicht `__magic__/__all__`, nicht `__magic__` selbst und nicht die Mount-Wurzel. Beide *arrs melden dafür einen Health-Check; Geschwisterordner lösen keinen aus.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` spiegelt die Bibliothek, damit jedes Release schon da ist, bevor du etwas sortierst.

**3. Sortiere es.** Ein `mv` innerhalb von `__magic__` schreibt eine Zeile und verschiebt keine Bytes.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Wenn Sonarr und Radarr deine alte Bibliothek sortiert haben, verschiebe sie mit einem Skript.** Es benennt jede Datei, auf die die alte Bibliothek verlinkt, in einen neuen Stammordner unter `__magic__` um. Jede landet an dem Pfad, den der *arr schon erwartet. Nichts wird kopiert. Danach stellst du den Stammordner des *arr um, ohne dass er etwas verschiebt. Die Schritte und das Skript stehen auf [der gemeinsamen Seite](index.md#coming-off-a-symlink-library). Lass einen *arr die Dateien nie selbst verschieben. Das überquert die Mount-Grenze. Dann wird kopiert, und deine Bibliothek wird neu heruntergeladen.

Das Skript braucht eine Funktion `zurg_path` für die Links von AltMount. Speichere sie als `zurg_path.sh` neben dem Skript und setze `OLDMOUNT` auf den Ort, an dem AltMount eingehängt ist.

```bash
OLDMOUNT=/mnt/altmount          # AltMount's mount, where the old links point
zurg_path() {
  case "$1" in "$OLDMOUNT"/*) ;; *) return ;; esac   # not a link into AltMount
  local name=${1##*/} f videos
  local release; release=$(basename "$(dirname "$1")")
  [ -f "$ZURG/__all__/$release/$name" ] && { echo "$ZURG/__all__/$release/$name"; return; }
  # AltMount named a lone video or an unpacked archive after the release. Take its one video.
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Die Funktion erwartet den Release-Ordner direkt über der Datei im Ziel jedes Links. Den genauen Pfad, den die Links von AltMount nutzen, habe ich für diese Anleitung nicht geprüft. Führe deshalb zuerst `readlink` auf einen Link aus. Wenn AltMount eine einzelne Videodatei oder ein entpacktes Archiv nach dem Release benannt hat, nimmt die Funktion das eine Video, das zurg in diesem Release ausliefert. Ein Release mit mehr als einem Video wird nie geraten. Dann gibt sie `NOT IN ZURG` aus.

**4. Zeige Plex auf die Stammordner, die du angelegt hast** — `__magic__/tv` und `__magic__/movies` — und nur auf diese. Nie auf die Wurzel von `__magic__`, die die ganze Bibliothek auch unter `__magic__/__all__` enthält, und nie auf `__magic__` *und* ein Filterverzeichnis, sonst wird jede Episode zweimal gefunden. Prüfe, dass `autoEmptyTrash` auf `0` steht. Füge den neuen Ort hinzu und starte einen Scan. Entferne dann den alten. Das ist dein Bibliothekspfad des *arr oder der AltMount-Mount, falls Plex ihn direkt gelesen hat.

**5. Leere den Papierkorb**, wenn du ein paar Einträge stichprobenartig geprüft hast. Der Wiedergabestatus kommt über den GUID-Abgleich zurück. Sammlungen und Cover-Bilder nicht.

```bash
sudo systemctl stop altmount
```

Lass AltMount bis dahin laufen. Es kostet nichts, und es ist dein Rollback. Wenn du fertig bist, stoppe es.

## Danach {#afterwards}

Entfernen Sie AltMount nicht, bevor Sie von einer repräsentativen
Stichprobe gestreamt haben. Sein Konfigurationsverzeichnis enthält den
`.nzbz`-Speicher, und das ist die einzige andere Kopie deiner NZBs.

Jetzt zur Beschaffung. zurg hat einen optionalen
[SABnzbd-kompatiblen Endpunkt](../guides/sonarr-radarr.md), über den Sonarr und
Radarr Downloads anfordern können. Er ersetzt AltMount als deren Download-Client.
zurg prüft jeden Grab, bevor er als fertig gemeldet wird. Dabei fragt er die
News-Server nach Anfang und Ende jeder Datei. Außerdem lädt er den ersten Artikel
jeder Datei herunter. Das sind bis zu vierundsechzig davon plus ein paar mehr
bei einem Release mit nur wenigen Dateien. Manche News-Server behaupten noch,
dass ein Artikel existiert, nachdem sein Inhalt entfernt wurde, und das zeigt
erst ein Download. zurg baut ein Release wo möglich aus seinen PAR2-Dateien
wieder auf, bei denen Artikel fehlen. Eines, das sich nicht reparieren lässt,
wird als **Failed** gemeldet. Die \*arrs setzen es dann auf die Blockliste und
holen sich ein anderes. Die Prüfung ist eine Stichprobe und nicht der ganze
Post. Ein Post, dem ein Stück fehlt, das die Stichprobe nicht erreicht hat, wird
trotzdem als Completed gemeldet und schlägt beim Lesen der Stelle mit der Lücke
fehl. Halte die Root-Ordner der \*arrs innerhalb von `__magic__`. Ein Root-Ordner
irgendwo anders bekommt bei jedem Import eine vollständige Kopie. Gib dem \*arr in
Docker ein einziges Volume, das das gesamte Mount von zurg enthält. Ein
Download-Ordner und Root-Ordner auf zwei Volumes kopieren ebenfalls bei jedem
Import.
Siehe
[ein Volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
