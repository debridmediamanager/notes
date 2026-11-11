# Releases und Dateien umbenennen {#renaming-releases-and-files}

Der Mount von zurg ist auf genau eine Weise beschreibbar: Du kannst einen Release-Ordner oder eine Datei darin **umbenennen**, überall in der Bibliothek. Das ist standardmäßig aktiviert. Nichts wird kopiert, nichts wird heruntergeladen, und das Debrid-Konto wird nicht angefasst. Der neue Name wird neben dem Release gespeichert und hat Vorrang vor dem Namen, den zurg sonst berechnen würde.

Was du nicht tun kannst, ist etwas **verschieben**. Umbenennen und Verschieben sehen im Dateimanager nach derselben Geste aus, aber zurg behandelt sie als Gegensätze, aus einem Grund, den [der letzte Abschnitt](#why-a-move-is-refused-when-a-rename-is-not) erklärt.

Für ein gespeichertes *Layout* statt eines gespeicherten *Namens*, also Ordner, die du anordnest, oder ein \*arr, der per Verschieben importiert, siehe [`__magic__`](magic.md). Diese Seite handelt nur vom Namen.

## Umbenennen über den Mount {#renaming-through-the-mount}

Ein Umbenennen im Mount ist ein WebDAV-`MOVE`, dessen Ziel sich von der Quelle nur im letzten Pfadsegment unterscheidet. rclone macht aus einem Umbenennen im Mount (ein FUSE `rename(2)` bzw. das WinFsp-Pendant unter Windows) genau das. Deshalb landen `mv` oder `Rename-Item` im Mount, das Umbenennen im Finder, im Explorer oder in einem anderen Dateimanager und ein WebDAV-Client alle im selben Handler.

+++ Linux und macOS

```bash
mv "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show.S01E01.mkv" \
   "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show - s01e01.mkv"
```

Unter macOS ist der Mount `/Volumes/Zurg`, außer du hast `mount_path` geändert.

+++ Windows

```powershell
Rename-Item -LiteralPath "Z:\shows\Show.S01.1080p.WEB-DL\Show.S01E01.mkv" -NewName "Show - s01e01.mkv"
```

+++

Beide Ebenen funktionieren:

| Umbenennen | Gespeichert als |
|---|---|
| Ein Release-Ordner | `Torrent.Rename` |
| Eine Datei in einem Release | `File.Rename` |

Die Endpunkte `/dav/` und `/infuse/` akzeptieren `MOVE`. `/http/` nicht. Das ist ein reiner Lesebrowser und er antwortet außerhalb von `__magic__` mit `405`.

### Was ein Name erfüllen muss {#what-a-name-has-to-satisfy}

Ein neuer Name wird akzeptiert, wenn er nach dem Entfernen von Leerzeichen am Rand nicht leer ist, kein `/` oder `\` enthält, seinem eigenen `filepath.Clean` entspricht (wodurch auch `.` und `..` abgelehnt werden) und – bei einem Release-Ordner – nicht mit dem Zugriffsschlüssel eines *anderen* Hashes kollidiert. Ein Dateiname muss innerhalb seines eigenen Releases eindeutig sein.

| Ergebnis | Status |
|---|---|
| Umbenannt | `201` |
| Leerer Name, ein Trennzeichen darin oder ein Ziel, das nur einen Ordner benennt | `400` |
| Der Name ist bereits vergeben | `412` |
| Quelle nicht gefunden | `404` |
| Innerhalb eines Archivs oder abgelehnt (siehe unten) | `403` |

Eine Datei *innerhalb eines Archivs* umzubenennen ist nicht möglich. Der Inhalt des Archivs wird aus dem Archiv selbst erzeugt, es gibt also nichts, worauf man einen Namen schreiben könnte, und zurg lehnt das mit einem `403` ab, das besagt, dass Dateien innerhalb eines Archivs nicht umbenannt werden können.

## Umbenennen im Dashboard und über die API {#renaming-from-the-dashboard-and-the-api}

Die gleichen zwei Umbenennungen sind `POST`-Endpunkte, und jeder hat einen passenden Reset, der den gespeicherten Namen entfernt und das Release wieder auf seinen berechneten Namen zurücksetzt:

```
POST /manage/{torrentHash}/rename
POST /manage/{torrentHash}/clear-rename
POST /manage/{torrentHash}/files/{fileid}/rename
POST /manage/{torrentHash}/files/{fileid}/clear-rename
```

Über den Mount gibt es kein Gegenstück zu `clear-rename`. Eine Umbenennung zurück auf den Originalnamen speichert diesen Namen, entfernt aber das Override nicht.

### Der Staffel-Fix {#the-season-fix}

`GET /torrents/season-fix/plan` und `POST /torrents/season-fix/apply` sind ein Massen-Umbenennen von Dateien, das auf Plex' eigene Episodenzuordnung setzt, für Releases, deren Dateien auf eine Weise nummeriert sind, die nichts parsen kann. Der Plan ist nur lesend und gibt für jede Datei einen Grund für das Überspringen aus. Der Apply nimmt eine explizite Liste von Hashes entgegen statt eines Flags für „alles anwenden“. So bestätigst du, was du dir angeschaut hast.

## Was eine Umbenennung übersteht {#what-a-rename-survives}

Der gespeicherte Name gehört zum Release und wird in dessen `.zurgtorrent` mitgeschrieben. Dadurch bleibt er erhalten bei:

- **einem Library-Refresh**, auch wenn dabei die Dateieinträge des Releases neu aus der Auflistung des Anbieters aufgebaut werden.
- **einem Neustart.**
- **einer Reparatur**, bei der das Release unter einer neuen ID per Hash neu hinzugefügt wird.
- **einer Umbenennung des Torrents durch den Anbieter**, was Real-Debrid macht.

Er wandert auch mit: Eine exportierte `.zurgtorrent` enthält die Umbenennungen, sodass eine [lokale Bibliothek](local-libraries.md) so ankommt, wie du sie benannt hast.

Eine Sache übersteht er nicht: `ignore_renames: true`. Genau dafür gibt es diesen Schlüssel. zurg ignoriert dann alle gespeicherten Namen, zeigt den berechneten Namen an und lehnt neue Umbenennungen über den Mount ab. Die Umbenennungen werden dabei nicht gelöscht, nur ignoriert. Schaltest du den Schlüssel wieder aus, sind sie also wieder da.

## Was eine Umbenennung drumherum ändert {#what-a-rename-changes-around-it}

Eine Umbenennung ist eine Ansicht, aber mehrere Dinge werden aus dieser Ansicht gebaut, und sie werden mit ihr aktualisiert:

- **Das Mount.** Der Verzeichnis-Cache von rclone wird für den alten und den neuen Pfad ungültig gemacht, sodass die Änderung sofort sichtbar wird und du nicht auf das Ablaufen des Caches warten musst.
- **`.strm`-Dateien**, falls `save_strm_files` aktiviert ist. Die alten werden gelöscht und unter dem neuen Namen neu geschrieben.
- **Plex und Jellyfin** werden gebeten, das Release erneut anzuschauen.
- **Der lokale Cache-Eintrag.** Die `.zurgtorrent` wird unter dem neuen Namen geschrieben und die alte Datei gelöscht. Das Löschen ist wichtig: Bleibt sie übrig, lädt ein Neustart beide, die Hash-Kollision löst sich wieder auf die andere Kopie auf, und die Umbenennung wird stillschweigend rückgängig gemacht. Das war ein echter Bug, aufgetreten am 17.08.2026.
- **Die SABnzbd- und qBittorrent-Endpunkte.** Diese berechnen bei jeder Abfrage den Ordner neu, den sie an Sonarr und Radarr melden. Wird mitten im Import umbenannt, verschiebt sich der Pfad, aus dem sie importieren sollen, statt sie hängen zu lassen.

## Drei Fallen {#three-traps}

**Ein Umbenennen kann ein Release beim nächsten Refresh neu einsortieren.** Die Zugehörigkeit zu einem Verzeichnis wird bestimmt, indem die `directories:`-Filter auf den Namen des Releases angewendet werden, und die Filter sehen den *umbenannten* Namen. Das Umbenennen selbst wertet sie absichtlich nicht neu aus. Das Release bleibt in den Verzeichnissen, in denen es schon war. Der nächste Refresh tut es aber. Wenn also ein Filter auf etwas im Namen passt und dein neuer Name das nicht mehr enthält, wandert das Release später in ein anderes Verzeichnis, ohne dass dir beim Umbenennen etwas darauf hindeutet. Benenne deshalb vorsichtig um, wenn Filter auf Namen aufbauen.

**Eine Änderung der Dateiendung ändert, was die Datei ist.** Nichts hindert dich daran, `episode.mkv` in `episode.txt` umzubenennen. Nur Trennzeichen werden abgelehnt. Die Sichtbarkeit wird aber anhand des Namens beurteilt, den der Client sieht. Die umbenannte Datei kann deshalb aus `only_show_the_biggest_file` herausfallen, aus der Logik für abspielbare Dateien und aus dem Scan eines Medienservers.

**Eine `.strm`-URL, die schon an etwas anderes weitergegeben wurde, funktioniert danach nicht mehr.** Das signierte Token enthält den Zugriffsschlüssel und den Dateinamen. Eine URL, die vor dem Umbenennen kopiert wurde, liefert danach nichts mehr und antwortet mit `404`. Der eigene `.strm`-Baum von zurg wird zwar umgeschrieben, aber alles, wohin eine URL daraus kopiert wurde, nicht.

## So schaltest du es wieder ab {#turning-it-off}

| Schlüssel | Standard | Wirkung |
|---|---|---|
| `dav_allow_rename` | `true` | `false` lehnt ein Mount-`MOVE` mit `403` ab und nennt den Schlüssel im Body |
| `ignore_renames` | `false` | `true` ignoriert alle gespeicherten Umbenennungen, liefert berechnete Namen aus und lehnt neue Umbenennungen über den Mount mit `403` ab |
| `mount_read_only` | `false` | `true` startet rclone mit `--read-only`, sodass der Kernel den Schreibvorgang ablehnt, bevor zurg ihn sieht |

`dav_allow_rename` betrifft den Mount. Es steuert nicht die Dashboard-Endpunkte,
und es steuert auch keine Schreibvorgänge unter `__magic__`, die kein Debrid-Konto erreichen.
Eine Ausnahme ist das Mirror, und zwar nicht wegen dieses Schlüssels: `__magic__/__all__`
und die Release-Ordner direkt darin sind das eigene Layout der Bibliothek. Ein Schreibvorgang
auf einen davon wird deshalb abgelehnt, egal wie dieser Wert gesetzt ist. Innerhalb eines Release-Ordners ist es wieder normal.
`mount_read_only` hat im Kernel immer Vorrang vor allem anderen und ist außerdem der einzige Weg, ein Mount-`DELETE` zu stoppen. Warum das wichtiger ist als das Umbenennen, steht in [config.md](../reference/config.md).

## Warum ein Verschieben abgelehnt wird, ein Umbenennen aber nicht {#why-a-move-is-refused-when-a-rename-is-not}

| Versuch | Status |
|---|---|
| Ein Release-Ordner in ein anderes Verzeichnis | `403` |
| Eine Datei in ein anderes Release | `403` |
| Eine Datei in einen Unterordner des eigenen Releases | `400` |
| Ein Top-Level-Verzeichnis umbenannt oder verschoben | `405` |
| Alles aus `__magic__` heraus | `403` |
| Ein Schreibzugriff auf `__magic__/__all__` oder auf einen Namen direkt darin | `403` |

Die Regel dahinter ist jedes Mal dieselbe: **ein Umbenennen hat einen Ort, an dem es gespeichert werden kann, ein Verschieben nicht.**

Der Name eines Releases ist ein einzelner String am Release. Einen neuen zu schreiben ist also eine Feldzuweisung, die jede spätere Suche wieder liest. Ein Top-Level-Verzeichnis ist aber kein Ordner, sondern ein gespeicherter Filter, und seine Zugehörigkeit wird bei jedem Refresh aus der `directories:`-Konfiguration neu berechnet. Ein Release "in" `movies` zu verschieben würde nichts schreiben, weil nichts eine gespeicherte Antwort auf diese Frage liest. Der nächste Refresh würde die Zugehörigkeit aus den Filtern neu berechnen und es wieder rückgängig machen. Ablehnen ist hier die ehrliche Antwort. Dasselbe gilt für einen Unterordner innerhalb eines Releases, dessen Struktur aus der eigenen Dateiliste des Accounts stammt.

`__magic__` gibt es, weil gespeicherte Struktur wirklich nützlich ist, und es löst das Speicherproblem, statt so zu tun, als gäbe es keins: Ein Verschieben darin schreibt eine Zeile in eine kleine Tabelle, die über den Content-Hash geschlüsselt ist. Deshalb übersteht sie auch eine Reparatur, die das Release unter einer neuen ID wieder hinzufügt. Diese Tabelle ist absichtlich auf genau diesen einen Namespace beschränkt.

Es gibt noch einen zweiten Grund, die Liste der Ablehnungen nicht leichtfertig zu erweitern. [rclone-move-refusal.md](../internals/rclone-move-refusal.md) dokumentiert, was ein abgelehnter `MOVE` bei einem Client anrichtet, der damit nicht rechnet: Unter rclone 1.72.0 zeigt der VFS-Eintrag weiter auf das versuchte Ziel, und ein Aufrufer, der auf Kopieren-dann-Löschen zurückfällt, liest EOF und meldet Erfolg. Dadurch entsteht eine Datei mit null Bytes, von der er glaubt, sie geschrieben zu haben. Jede Ablehnung oben ist eine, die etwas überstehen muss.
