# Von nzbdav zu zurg migrieren {#migrating-from-nzbdav-to-zurg}

Lies zuerst [die gemeinsame Seite](index.md). Sie erklärt den Trash-Guard und warum deine Bibliothek in `__magic__` landet.

Die letzte Version von nzbdav-dev ist v0.6.4 vom April 2026, und das Upstream-Repository wird nicht mehr gepflegt.
Diese Version funktioniert. Bei dieser Migration geht es darum, von nicht mehr gepflegter Software wegzukommen. Eine hastige Umstellung ist nicht nötig.

**Das ist die einfachste der fünf Migrationen.** Im Vergleich zu zurg mit denselben fünf Releases unterscheidet sich der Verzeichnisbaum von nzbdav in genau zwei Punkten.

| | |
|---|---|
| zurg bekommt | die `.nfo`-Datei des Releases |
| zurg verliert | 5 Hash-benannte par2-Volumes in verschleierten Releases |

**Nichts wird umbenannt.** Jeder Dateiname, den nzbdav ausliefert, ist auch bei zurg unter demselben Namen und in derselben Verzeichnisstruktur verfügbar. Das gilt auch innerhalb von RAR-Archiven. Die beiden Server stimmten bei allen 20 Nicht-par2-Dateien im Korpus überein.

!!!warning Das WebDAV-Root niemals durchlaufen
Der `.ids`-Objektspeicher von nzbdav erzeugt auf allen fünf Ebenen immer alle 16 Hex-Unterordner, unabhängig vom Inhalt.
Das sind 16^5, also etwa 1.048.576 Verzeichnisse.
Gib `find`, `du`, `rclone` und jedem Scanner immer ausdrücklich `/content`, `/nzbs` oder `/completed-symlinks` an. Niemals `/`.
!!!

## Wie deine Bibliothek danach aussieht {#what-your-library-looks-like-afterwards}

**Alles wird neu hinzugefügt**, weil der Bibliotheks-Root auf `__magic__` wechselt.
Es gibt keinen günstigeren und keinen teilweisen Weg. Warum, steht auf [der gemeinsamen Seite](index.md).

Die gute Nachricht: nzbdav ist die eine Migration, bei der sich **nichts außer dem Präfix ändert**. Jeder Dateiname, den zurg ausliefert, ist derselbe, den nzbdav ausgeliefert hat. Ein \*arr, der aus `__magic__` neu importiert, parst genau das, was er vorher geparst hat. Ein Ordner, den du von Hand sortierst, sieht genauso aus wie immer.

Das gilt für jedes Setup. Unter Windows und überall sonst, wo Plex den Mount direkt liest, sind die Dateinamen identisch. Wenn Sonarr und Radarr eine Symlink-Bibliothek organisieren, waren die Dateinamen schon immer ihre, und die Quelle, die sie parsen, bleibt unverändert. Diese Migration verändert also nichts daran, wie deine Bibliothek gelesen wird. Sie ändert nur, wo sie liegt.

## Welche neuen Inhalte auftauchen {#what-new-content-shows-up}

- Die `.nfo` in RAR-Releases.
- **Sample-Clips** in `Sample/`. nzbdav veröffentlicht das Verzeichnis und den
  Clip, und zurg genauso. Das ist *nicht* neu für dich. nzbdav ist der einzige
  Server von den vieren, der das schon hatte.
- Leere Ordner für Releases, deren Archivkette kaputt ist. nzbdav hat dafür
  nichts erstellt.
- par2 und sfv werden nicht mehr sichtbar.

Keiner davon erzeugt ein Plex-Element außer dem Sample-Clip, und den hat nzbdav dir schon gegeben. Wenn es dich vorher nicht gestört hat, ändert sich nichts.

## Hol deine NZBs raus {#get-your-nzbs-out}

zurg bekommt seine Eingaben aus einem Verzeichnis mit `.nzb`-Dateien, und nzbdav hat alle deine noch unter
`/nzbs/<category>/`. **Kopiere sie. Verschiebe sie nicht.** Wenn du etwas aus `/nzbs/` löschst, wird der Job
abgebrochen.

```bash
mkdir -p ~/migration/nzbs
for cat in uncategorized movies tv audio software; do
  rclone copy "nzbdav:/nzbs/$cat" ~/migration/nzbs/ --include '*.nzb'
done
ls ~/migration/nzbs | wc -l
```

Beide Server benennen den Release-Ordner nach dem *Dateinamen* der NZB. Die Stämme, die du wiederhergestellt hast, sollten also den Ordnern entsprechen, die nzbdav ausliefert. Prüfe das und benenne alle um, die abweichen.

```bash
rclone lsf "nzbdav:/content/movies" --dirs-only | sed 's:/$::' | sort > ~/migration/folders-old.txt
ls ~/migration/nzbs | sed 's/\.nzb$//' | sort > ~/migration/stems.txt
diff ~/migration/folders-old.txt ~/migration/stems.txt
```

Zwei zurg-Benennungsregeln lohnt es sich, mit dieser Liste abzugleichen.

- zurg entfernt ein abschließendes `.mkv` oder `.mp4` aus einem Ordnernamen. Wenn ein Stamm so endet,
  setze `retain_folder_name_extension: true`.
- Zwei verschiedene Releases mit demselben Stamm bekommen bei einem davon das Suffix ` {shorthash}`. Finde sie jetzt mit `ls ~/migration/nzbs | sed 's/\.nzb$//' | sort |
  uniq -d`.

## zurg parallel aufbauen {#build-zurg-alongside}

nzbdav läuft die ganze Zeit weiter. Kopier seinen provider-Block in die zurg-Konfiguration.
Gib zurg einen eigenen Mountpoint. Leg die NZBs ab und lass es scannen. Das watch-Verzeichnis wird etwa alle 15 Sekunden überprüft.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from nzbdav's provider settings
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
mkdir -p nzbs && cp ~/migration/nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l     # should approach your release count
```

## Umschalten {#cut-over}

Ein Weg, egal was du heute hast. Hier werden keine Bytes verschoben.

**1. Schalte `__magic__` ein** und starte neu. Die Routen werden beim Start registriert, daher braucht ein Dashboard-Schalter einen Neustart, bevor der Namespace antwortet.

```yaml
magic:
  enabled: true
```

**2. Lege die Stammordner an.** Sie kommen in die Wurzel von `__magic__`, neben das `__all__`, das zurg dort behält. Nicht `__magic__/__all__`, nicht `__magic__` selbst und auch nicht die Mount-Wurzel. Beide \*arrs melden dafür einen Health-Check; Geschwister lösen keinen aus.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` spiegelt die Bibliothek, damit jede Veröffentlichung schon da ist, bevor du etwas sortierst.

**3. Sortiere sie.** Ein `mv` innerhalb von `__magic__` schreibt nur eine Zeile und verschiebt keine Bytes.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Wenn Sonarr und Radarr deine alte Bibliothek sortiert haben, dann zieh sie mit einem Skript hierher um.** Es benennt jede Datei, auf die die alte Bibliothek verlinkt, in einen neuen Stammordner unter `__magic__` um. Jede landet an dem Pfad, den der \*arr schon erwartet. Nichts wird kopiert. Danach stellst du den Stammordner des \*arr um, ohne dass er etwas verschiebt. Die Schritte und das Skript stehen auf [der gemeinsamen Seite](index.md#coming-off-a-symlink-library). Lass einen \*arr die Dateien nie selbst verschieben. Das geht über die Mount-Grenze hinweg. Dann wird kopiert, und deine Bibliothek wird neu heruntergeladen.

Das Skript braucht eine `zurg_path`-Funktion für die Links von nzbdav. Speichere sie als `zurg_path.sh` daneben und setze `OLDMOUNT` auf den Ort, an dem nzbdav gemountet ist.

```bash
OLDMOUNT=/mnt/nzbdav            # nzbdav's mount, where the old links point
# The map from each .ids name to its release and file. Built once while nzbdav runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # A file under another name. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Die Links von nzbdav zeigen in seinen `.ids`-Speicher, und zurg hat so etwas nicht. Deshalb liest die Funktion den `completed-symlinks`-Baum von nzbdav einmal aus, um herauszufinden, für welche Veröffentlichung und Datei jeder `.ids`-Name steht. Lass nzbdav laufen, bis das Skript fertig ist. nzbdav benennt nichts um, also ist jeder Name, den es findet, einer, den zurg ausliefert.

**Zeig Plex auf die Stammordner, die du angelegt hast** — `__magic__/tv` und `__magic__/movies` — und nur auf diese. Nie auf die Wurzel von `__magic__`, denn dort liegt auch die ganze Bibliothek unter `__magic__/__all__`, und nie auf `__magic__` *und* einen Filterordner, sonst wird jede Episode doppelt gefunden. Prüfe, dass `autoEmptyTrash` auf `0` steht. Füge den neuen Speicherort hinzu und scanne. Dann entferne den alten. Das ist der Bibliothekspfad deines \*arr oder der nzbdav-Mount, falls Plex direkt darauf zugreift.

**5. Leere den Papierkorb**, sobald du ein paar Einträge stichprobenartig geprüft hast. Der Wiedergabestatus kommt über den GUID-Abgleich zurück. Sammlungen und Poster-Auswahl nicht.

Lass nzbdav bis dahin laufen. Es kostet nichts und ist dein Rollback. Wenn du fertig bist, stopp es.

```bash
sudo systemctl stop nzbdav
```

## Danach {#afterwards}

Behalte das Config-Verzeichnis von nzbdav, bis du von einer repräsentativen
Stichprobe gestreamt hast. Es ist die einzige andere Kopie deiner NZBs.

Jetzt zur Beschaffung. zurg hat einen optionalen [SABnzbd-kompatiblen
Endpunkt](../guides/sonarr-radarr.md), über den Sonarr und Radarr Grabs
ausführen können. Er ersetzt nzbdav als Download-Client der beiden. Der Grab
landet in `__magic__/__all__`, und der Import verschiebt ihn per Umbenennen
heraus. Es wird nichts kopiert. zurg prüft jeden Grab, bevor er als fertig
gemeldet wird. Dabei fragt er die News-Server nach Anfang und Ende jeder Datei.
Außerdem lädt er den ersten Artikel jeder Datei herunter. Das sind bis zu
vierundsechzig davon, plus ein paar mehr bei einem Release mit nur wenigen
Dateien. Manche News-Server melden noch, dass ein Artikel existiert, obwohl
sein Inhalt längst entfernt wurde. Das zeigt nur ein tatsächlicher Download.
zurg baut ein Release mit fehlenden Artikeln wieder auf, wenn es das über die
PAR2-Dateien schafft. Eins, das sich nicht wiederherstellen lässt, wird als
**Failed** gemeldet. Dann setzt der \*arr es auf die Blockliste und holt sich
einen anderen. Die Prüfung ist nur eine Stichprobe und nicht der ganze Post.
Ein Post, dem ein Stück fehlt, das die Stichprobe nicht erreicht hat, wird
trotzdem als Completed gemeldet und fällt beim Lesen auf die Lücke auf.

Halte die Root-Ordner der \*arrs innerhalb von `__magic__`. Ein Root-Ordner
irgendwo anders erzeugt bei jedem Import eine vollständige Kopie. Bei Docker
gib dem \*arr ein einziges Volume, das den gesamten Mount von zurg enthält.
Ein Download-Ordner und Root-Ordner auf zwei verschiedenen Volumes kopieren
ebenfalls bei jedem Import. Siehe
[ein Volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
