# Von decypharr zu zurg migrieren {#migrating-from-decypharr-to-zurg}

Lies zuerst [die gemeinsame Seite](index.md). Dort wird erklärt, wie der trash guard funktioniert und warum deine Bibliothek in `__magic__` landet.

decypharr und zurg lösen dasselbe Problem, und ihre Root-Layouts sind ähnlich. Ein großer Teil der Einrichtung lässt sich daher übernehmen.

| decypharr | zurg |
|---|---|
| `__all__/<job>/<file>` | `__all__/<name>/<file>` |
| `version.txt` | `version.txt` |
| `__bad__/` | `__unplayable__/` |
| `torrents/` | ein `directories:`-Eintrag mit `not_provider: nzb` |
| `nzbs/<job>/` | ein `directories:`-Eintrag mit `provider: nzb` oder das eingebaute `__nzb__` |

Die **Debrid-Seite brauchst du nicht anzupassen**. Beide Server listen dieselben Accounts auf und zeigen die Dateinamen des Torrents so, wie sie sind. Diese Pfade sind identisch, sobald zurg am Mountpoint von decypharr sitzt. Alles Weitere in dieser Anleitung betrifft die Usenet-Seite.

Zwei Dinge solltest du klären, bevor du anfängst.

- **Anbieter.** Sie begrenzen die Migration nicht. zurg hat ein Backend für jeden Dienst, den decypharr unterstützt. Premiumize- und Debrid-Link-Accounts werden genauso übernommen wie die übrigen. Für jeden gibt es eine eigene Seite unter [Anbieter](../providers/index.md).
- **Ändere vor der Migration nicht decypharrs `folder_naming`.** Die Option benennt auf einmal jeden Ordner in der Bibliothek um. Dadurch stimmt jedes Symlink-Ziel und jeder Mount-direct-Plex-Pfad nicht mehr.

## Was sich auf der Usenet-Seite unterscheidet {#what-differs-on-the-usenet-side}

Im Vergleich zu zurg bei denselben fünf Releases:

| | |
|---|---|
| zurg hat zusätzlich | `thumbnail.jpg`, den Sample-Clip, die `.nfo`, die `.url`-Werbedateien, das innere Verzeichnis des Archivs, **und das verschleierte Release, das decypharr weggelassen hat** |
| zurg verliert | nichts |
| umbenannt | Einzeldatei-Releases und Archiv-Releases |

**Einzeldatei-Releases** werden von decypharr nach dem Job benannt. Du bekommst
`ToyStory5/ToyStory5.mkv`, wo zurg den Namen des Uploaders behält und
`ToyStory5/Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv` ausgibt.

**Archiv-Releases** sind der interessante Fall und lohnt sich zu verstehen, weil
er zwei Symptome auf einmal erklärt. Die entstehen bei decypharr.

```
FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLAfather.brown.2013.s02e05.hdtv.x264-tla.mp4
```

Das ist der Name des inneren Verzeichnisses im Archiv und der Name der Datei selbst, zusammengehängt
**ohne Trennzeichen**. Das ist ein Pfad-Join, bei dem das `/` verloren gegangen ist. Das fehlende Verzeichnis und der kaputte Dateiname sind also derselbe Fehler und nicht zwei. 
zurg bildet die echte Struktur nach, unter `FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown.….mp4`.

**Multi-File-Releases und Staffel-Packs behalten ihre echten Dateinamen auf beiden Seiten.** Sie werden automatisch zugeordnet, sobald der Ordnername passt.

## Wie deine Bibliothek danach aussieht {#what-your-library-looks-like-afterwards}

**Alles wird neu hinzugefügt**, weil die Bibliothekswurzel nach `__magic__` wechselt. Warum es keinen günstigeren Weg gibt, steht auf [der gemeinsamen Seite](index.md).

Der Gewinn liegt bei den Namen. Jede Release mit einer einzigen Datei kommt jetzt unter dem Dateinamen des Uploaders zurück und nicht mehr unter dem Jobnamen. Aus `ToyStory5/ToyStory5.mkv` wird also `Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`. Aus diesem String lesen Sonarr, Radarr und Plex Qualität, Quelle, Gruppe und Edition heraus. Archiv-Releases haben keinen zusammengeschweißten Namen mehr und liegen im eigenen Verzeichnis des Archivs. Releases mit mehreren Dateien und Staffelpakete werden schon richtig gelesen und bleiben unverändert.

Liste die Releases auf, deren Namen sich ändern.

```bash
MOUNT=/mnt/decypharr
for d in "$MOUNT"/__all__/*/; do
  job=$(basename "$d")
  n=$(find "$d" -type f | wc -l)
  [ "$n" -eq 1 ] && echo "RENAMED BY DECYPHARR: $job"
done
```

!!!info Ob du davon etwas siehst, hängt von deinem Setup ab
Wenn Plex das Mount direkt liest, dann ändern sich in deiner Bibliothek genau die oben genannten Namen. Das betrifft jedes Windows-Setup und jedes Linux- oder macOS-Setup ohne eine Symlink-Farm für \*arr.

Wenn Sonarr und Radarr eine Symlink-Bibliothek mit aktiver Umbenennung organisieren, dann **stimmen deine Dateinamen schon mit deren überein** und keiner der oben genannten Namen taucht in Plex auf. Was die Namen dir dann verraten, ist, wie gut das Parsing war, auf dem der \*arr aufgebaut hat. Das ist wichtig, wenn du neu importierst. Siehe [der gemeinsamen Seite](index.md).
!!!

## Welche neuen Inhalte auftauchen {#what-new-content-shows-up}

- **Beispielclips** in `Sample/`. Das ist der eine Punkt, der sich lohnt zu konfigurieren. Setze
  [`only_show_the_biggest_file: true`](../reference/config.md), wenn du nicht willst, dass ein 9 MB großer Sample-Clip als zweite Version auftaucht.
- `thumbnail.jpg`, die `.nfo` und die `.url`-Werbedateien des Posters. Alles harmlos.
- **Verschleierte Releases, die decypharr abgelegt hat**, tauchen als neue Bibliothekseinträge auf.
  decypharr hat für einen komplett hash-benannten Post gar nichts veröffentlicht.
  zurg löst ihn auf den echten Release-Namen auf und stellt ihn bereit.
- Leere Ordner, wo eine Archivkette unterbrochen ist.

## Deine NZBs zurückholen {#get-your-nzbs-back}

**decypharr kann sie dir nicht zurückgeben.** Es behält pro Job einen komprimierten Binärblob unter `usenet/meta/<uuid>.meta` und ein Verzeichnis `usenet/nzbs/`, das auf der Testmaschine leer war. Ein dokumentierter Export existiert nicht. Ob sich die `.meta`-Blobs wieder in NZBs zurückverwandeln lassen, ist nicht geprüft. Behandle die Originale als unwiederbringlich verloren.

Was du hast, sind die Jobnamen. Auf beiden Servern *ist* der Name des Job-Ordners der NZB-Dateiname. Die Ordnerliste ist also deine Einkaufsliste.

```bash
MOUNT=/mnt/decypharr
ls "$MOUNT/nzbs" > nzb-jobs.txt      # the usenet jobs
wc -l nzb-jobs.txt
```

Hol für jeden Job die NZB erneut von deinem Indexer, indem du nach dem Ordnernamen suchst. Dann **benenne die Datei genau in diesen Namen plus `.nzb` um**, bevor du sie in das Verzeichnis `nzbs/` von zurg legst. Der Dateiname ist der Ordnername, und der Ordnername sorgt dafür, dass der Pfad stabil bleibt.

Zwei Regeln dabei.

- **Überspringe jedes Release, das ein Debrid-Konto bereits hat.** Der Symlink wird über die Torrent-Kopie aufgelöst. Fügst du die NZB zusätzlich hinzu, sieht zurg zwei verschiedene Releases mit demselben Namen und hängt einem davon einen Hash-Suffix an, etwa `Some.Release {a1b2c3}`. Dadurch bricht alles, was auf den nackten Namen zeigt.
- Ein Release, das dein Indexer nicht mehr führt, ist einfach weg. Bei `autoEmptyTrash` auf `0` bleibt das Plex-Element im Papierkorb, bis du entscheidest, es zu löschen.

## zurg parallel aufbauen {#build-zurg-alongside}

Lass zurg neben decypharr auf einem eigenen Mountpoint laufen. Beide dürfen gleichzeitig dieselben Debrid-Konten auflisten, weil das Auflisten nur lesend erfolgt.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_TOKEN
  # - type: alldebrid / torbox as you have them
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30                # your plan's real allowance
retain_rd_torrent_name: false        # align with decypharr's folder_naming
retain_folder_name_extension: false  # true if your folders carry .mkv/.mp4
mount_path: "/mnt/zurg-staging"
rclone_enabled: true
rclone_binary: bin/rclone
directories:                         # optional: mirror decypharr's top level
  torrents:
    filters:
      - not_provider: nzb
  nzbs:
    filters:
      - provider: nzb
```

Prüfe danach, ob die Debrid-Seite passt, bevor du weitermachst.

```bash
ls /mnt/decypharr/__all__      | sort > decypharr-jobs.txt
ls /mnt/zurg-staging/__all__   | sort > zurg-jobs.txt
diff decypharr-jobs.txt zurg-jobs.txt
```

Manchmal unterscheiden sich die Torrent-Ordner *systematisch*. Eine Dateiendung ist vorhanden oder fehlt. Statt des Originalnamens taucht der RD-Umbenennungsname auf. In dem Fall schaltest du `retain_rd_torrent_name` oder `retain_folder_name_extension` um und scannst neu, statt etwas von Hand zu korrigieren. Ordner, die nur auf der decypharr-Seite existieren, sind die Usenet-Jobs. Die Ordnernamen von Premiumize und Debrid-Link wurden nicht mit denen von decypharr verglichen. Prüfe die Ordner dieser Konten hier also ebenfalls.

## Umschalten {#cut-over}

**1. Schalte `__magic__` ein** und starte neu. Die Routen werden beim Start registriert. Deshalb braucht ein Schalter im Dashboard einen Neustart, bevor der Namespace antwortet.

```yaml
magic:
  enabled: true
```

**2. Lege die Root-Ordner an.** Sie kommen in die Root von `__magic__`, neben das `__all__`, das zurg dort behält. Nicht `__magic__/__all__`, nicht `__magic__` selbst und nicht der Mount-Root. Beide \*arrs melden dafür einen Health-Check. Geschwisterordner lösen keinen aus.

In Docker müssen die \*arrs `__all__` und diese Root-Ordner über ein Volume erreichen. decypharr-Setups binden oft einen Downloads-Ordner und einen Medien-Ordner getrennt ein. Zwei Volumes machen jeden Import zu einer vollständigen Kopie. Binde stattdessen einmal das übergeordnete Verzeichnis des zurg-Mounts ein. Die [Anleitung](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) zeigt, wie das geht.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` spiegelt die Bibliothek, damit jedes Release schon da ist, bevor du etwas organisierst.

**3. Organisiere es.** Ein `mv` innerhalb von `__magic__` schreibt nur eine Zeile und bewegt keine Bytes.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Wenn Sonarr und Radarr deine alte Bibliothek organisiert haben, verschiebe sie mit einem einzigen Skript.** Es benennt jede Datei, auf die deine alte Bibliothek verlinkt, in einen neuen Root-Ordner unter `__magic__` um. Jede landet an dem Pfad, den der \*arr bereits erwartet. Nichts wird kopiert. Danach stellst du den Root-Ordner des \*arr um, ohne dass er etwas verschiebt. Die Schritte und das Skript findest du auf [der gemeinsamen Seite](index.md#coming-off-a-symlink-library). Lass einen \*arr die Dateien niemals selbst verschieben. Das überschreitet die Mount-Grenze. Es wird zu einer Kopie, und dabei wird deine Bibliothek heruntergeladen.

Das Skript braucht eine Funktion `zurg_path` für die Links von decypharr. Speichere sie als `zurg_path.sh` daneben und setze `OLDMOUNT` auf den Ort, an dem decypharr gemountet ist.

```bash
OLDMOUNT=/mnt/decypharr         # decypharr's mount, where the old links point
zurg_path() {
  local rel=${1#"$OLDMOUNT"/__all__/}
  [ "$rel" = "$1" ] && return   # not a link into decypharr
  local job=${rel%%/*} name=${1##*/} f videos
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # decypharr welded an archive's inner folder and file into one name.
  for f in "$ZURG/__all__/$job"/*/*; do
    [ "$(basename "$(dirname "$f")")$(basename "$f")" = "$name" ] && { echo "$f"; return; }
  done
  # decypharr named a lone video after the job. Take the job's one video.
  case "$name" in "$job".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$job" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Ein Link auf ein Debrid-Release oder ein NZB-Release mit mehreren Dateien verweist auf beiden Servern auf dieselbe Datei. decypharr hat zwei Arten von NZB-Releases umbenannt. Es hat ein einzelnes Video nach dem Job benannt und den Ordner und die Datei eines Archivs zu einem Namen zusammengeklebt. Die Funktion findet die Kopie von zurg für beide Fälle. Ein Job mit mehr als einem Video wird nie geraten. Stattdessen gibt er `NOT IN ZURG` aus.

**4. Zeige Plex auf die Root-Ordner, die du angelegt hast** — `__magic__/tv` und `__magic__/movies` — und nur auf diese. Niemals auf die Root von `__magic__`, denn dort liegt zusätzlich die ganze Bibliothek unter `__magic__/__all__`. Und niemals `__magic__` *und* ein Filterverzeichnis zusammen, sonst wird jede Episode zweimal gefunden. Prüfe, dass `autoEmptyTrash` auf `0` steht. Füge den neuen Speicherort hinzu und starte einen Scan. Entferne danach den alten. Das ist dein Bibliothekspfad des \*arr oder der decypharr-Mount, falls Plex ihn direkt gelesen hat.

**5. Leere den Papierkorb**, sobald du ein paar Einträge stichprobenartig geprüft hast. Der Wiedergabestatus kommt über den GUID-Abgleich zurück. Sammlungen und Cover-Auswahl nicht.

Lass decypharr bis dahin laufen. Es kostet nichts und ist dein Rückweg. Lösche auch nicht seine Konfiguration oder die Zustände in `db/` und `usenet/`. Wenn du fertig bist, stoppe es.

```bash
sudo systemctl stop decypharr
```

## Danach {#afterwards}

**Automatisierung bleibt erhalten, in beide Richtungen.** zurg hat einen optionalen [SABnzbd-kompatiblen Endpunkt](../guides/sonarr-radarr.md), damit Sonarr und Radarr ihm eine NZB übergeben können. Außerdem gibt es einen optionalen [qBittorrent-kompatiblen Endpunkt](../guides/sonarr-radarr-torrents.md), damit sie ihm einen Magnet-Link oder eine `.torrent`-Datei für ein Debrid-Konto geben können. Beide importieren über ein Umbenennen aus `__magic__/__all__`. Deine Optionen:

- **NZBs.** Schalte `sabnzbd.enabled` ein und richte die \*arrs auf zurg aus. zurg prüft jede Anfrage, bevor es sie als fertig meldet. Dabei fragt es die News-Server nach Anfang und Ende jeder Datei. Außerdem lädt es den ersten Artikel jeder Datei herunter. Bei einem Release mit nur wenigen Dateien sind das bis zu vierundsechzig plus ein paar weitere. Manche News-Server melden noch, dass ein Artikel existiert, obwohl sein Inhalt entfernt wurde. Das zeigt sich erst beim Herunterladen. zurg baut ein Release, dem Artikel in seinen PAR2-Dateien fehlen, wo möglich wieder zusammen. Eines, das sich nicht reparieren lässt, wird als **Failed** gemeldet. Der \*arr setzt es dann auf die Blockliste und holt ein anderes. Die Prüfung ist eine Stichprobe und nicht der ganze Post. Ein Post, dem ein Stück fehlt, das die Stichprobe nicht erreicht hat, wird trotzdem als Completed gemeldet und schlägt erst beim Lesen der Lücke fehl.
- **Torrents.** Schalte `qbittorrent.enabled` ein und trage es als zweiten Download-Client ein. Das Release eines privaten Trackers funktioniert, wenn der Indexer eine `.torrent`-Datei statt eines reinen Magnet-Links ausgibt. Die Datei übergibt den Hash direkt an die Cache-Suche des Kontos.
- **Einzelne Hinzufügungen.** Das Dashboard von zurg hat keinen Hinzufügen-Button. Füge einen Magnet-Link oder eine `.torrent`-Datei über den qBittorrent-Endpunkt mit der Kategorie eines \*arr hinzu, dann geht sie an dieses \*arr. [Ein Release von Hand hinzufügen](../guides/sonarr-radarr-torrents.md#11-adding-a-release-by-hand) zeigt, wie das geht. Ein über DMM hinzugefügter Magnet-Link und eine in `nzbs/` abgelegte NZB erscheinen beide in zurg. Keines von beiden erreicht Sonarr oder Radarr allein. Die eigene [Beschaffung](../guides/acquisition.md) von zurg holt Anfragen ebenfalls selbst. Sie kommen aus deiner Plex-Watchlist sowie von Seerr und den \*arrs. Es holt NZBs von Newznab-Indexern und Torrents von Torznab-Indexern, wenn dein Konto sie bereits im Cache hat.
- **Hybrid.** Behalte decypharr rein als Download-Client der \*arrs, der in dieselben Debrid-Konten schreibt, während zurg den Mount bereitstellt. Beide greifen auf dasselbe Konto zu, sodass zurg übernimmt, was decypharr hinzufügt. Der Importschritt des \*arr braucht dann ein Remote-Pfad-Mapping auf den Baum von zurg. Dieser Baum und die Root-Ordner müssen sich in einem Volume befinden. Teste zuerst eine einzelne Anfrage.
