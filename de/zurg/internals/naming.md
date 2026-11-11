# zurg-Benennung {#zurg-naming}

Fast alle Namen, die zurg anzeigt, werden berechnet und nie gespeichert. Der Ordnername eines Releases, der Dateiname einer Datei darin und der Dateiname auf der Festplatte für den Cache-Eintrag werden bei jeder Abfrage aus dem Torrent neu abgeleitet. Nichts schreibt diese Namen irgendwo fest und liest sie später wieder ein. Ein gespeicherter Name wäre eine zweite Sache, die man mit der Bibliothek synchron halten muss, und genau das geht bei einer Reparatur oder einer erneuten Auflösung eines NZB kaputt.

Die Ausnahme ist eine Umbenennung, die der Betreiber selbst angefordert hat. Die wird gespeichert, und zwar direkt am Release, und sie hat Vorrang vor allen Ableitungen unten. Abschnitt 9 enthält die Regeln, und die Anleitung zum Umbenennen ist die Fassung für Anwender. Alles andere auf dieser Seite beschreibt den Namen, den ein Release hat, wenn keine Umbenennung gesetzt ist.

Daraus folgt eine Konsequenz, die man gleich vorweg nennen sollte, weil sie die meisten Überraschungen bei allem verursacht, was zurg einbindet: Ein Ordner kann seinen Namen ändern, ohne dass ihn jemand „umbenannt“ hat. Die Eingaben haben sich geändert, also hat sich auch die Ausgabe geändert.

Diese Datei enthält die Regeln, nicht die Schwellenwerte. Wo eine Regel über eine Heuristik entschieden wird, nennt sie die Funktion, die das entscheidet, und hört dort auf. Diese Heuristiken sind an echten Releases abgestimmt und ändern sich, und wenn man sie hier abschreibt, hat man nur eine weitere Sache, die synchron gehalten werden muss. Code-Verweise sind paketrelativ.

## 1. Der Name des Release-Ordners {#1-the-release-folder-name}

`internal/torrent/key.go`, GetKey / GetKey_Original

Der Ordner unter `__all__/`, der `.zurgtorrent`-Dateiname, der Schlüssel, über den jede Suche läuft, und das, was zurg „access key“ nennt, sind alle ein und derselbe String. Er wird in dieser Reihenfolge festgelegt, der erste Treffer gewinnt:

  | Bedingung                                   | Ordnername                |
  |---------------------------------------------|---------------------------|
  | `ignore_renames: false`, Torrent.Rename gesetzt | Torrent.Rename        |
  | `retain_rd_torrent_name: true`              | Name, unverändert         |
  | `retain_folder_name_extension: true` UND    | Name, unverändert         |
  |   Name enthält OriginalName                 |                           |
  | sonst — beide Flags auf ihren Standardwerten | OriginalName, zuerst `.mp4` und dann |
  |                                             |   `.mkv` abgeschnitten    |

`retain_rd_torrent_name` wird zuerst geprüft und verdeckt `retain_folder_name_extension` komplett. Letzteres gilt nur dort, wo Name OriginalName als Teilstring enthält. Wenn nicht, wird trotzdem abgeschnitten.

Das Abschneiden ist `strings.TrimSuffix`, zweimal ausgeführt, also eigentlich drei Regeln in einer. Nur `.mp4` und `.mkv` fallen weg, daher bleiben `.avi`, `.ts`, `.iso` und Co. im Ordnernamen. Es wird zwischen Groß- und Kleinschreibung unterschieden, also behält `Movie.2019.MKV` sein `.MKV`. Und die beiden Durchläufe laufen nacheinander statt als Alternativen, sodass `Movie.2019.mkv.mp4` zu `Movie.2019` wird. Danach kann noch ein Suffix angehängt werden, siehe Abschnitt 4. Das Ergebnis ist immer eine einzelne Pfadkomponente und wird nie an `/` geteilt.

VERALTET. `retain_folder_name_extension` und `retain_rd_torrent_name` sind veraltet und werden irgendwann entfernt. Das Verhalten bleibt vorerst unverändert, und wenn du eine der beiden setzt, gibt es beim Start eine Warnung im Log. Beide richten die Bibliothek nach Name aus, und Name schreibt das Konto unter zurg um (Abschnitt 2). Die Standardwerte richten sie dagegen nach dem aus, was der Torrent selbst angibt, und das lässt das Konto in Ruhe. Auf einer Instanz, die Sonarr oder Radarr vorgeschaltet ist, also eine mit einem `sabnzbd:`- oder `qbittorrent:`-Block, sind die Standardwerte die einzig richtigen. Denn ein access key, der sich nach einem Import verschiebt, verliert den Release. `ignore_renames` ist nicht veraltet.

## 2. Woher Name und OriginalName kommen {#2-where-name-and-originalname-come-from}

  Real-Debrid   `internal/realdebrid/types.go`
                Name = `filename`, OriginalName = `original_filename`

  TorBox        `internal/torbox/types.go`, wireTorrent.originalName
                Name = `name`. OriginalName = das einzige Verzeichnis, unter dem alle Dateien liegen, sofern es genau eines gibt; Dateien auf oberster Ebene greifen auf `name` zurück, außer bei einer einzelnen losen Datei, deren eigener Name verwendet wird.

  AllDebrid     `internal/alldebrid/types.go`, originalName
                Gleiche Regel wie bei TorBox, angewendet auf die flache Dateiliste, mit Fallback auf den `filename` des Magnets.

  NZB           `internal/nzb/provider.go`
                Name und OriginalName sind beide releaseName, und der Hash des Torrents ist die Release-ID. Abschnitt 3.

Weil die Debrid-Backends OriginalName aus dem eigenen Stammordner des Torrents ableiten, erzeugen zwei Konten mit demselben Inhalt denselben Ordnernamen.

Was die beiden Felder von Real-Debrid bedeuten, gemessen am 2026-08-27 an einem Testkonto mit ~84k Torrents, wobei 252 davon schreibgeschützt über `GET /torrents/info` stichprobenartig geprüft wurden: `original_filename` war in jedem Fall der Name, den der Torrent selbst angab – der Pack- oder Ordnername – und nie der Name einer einzelnen Datei. `filename` ist das nicht. Es fällt auf den eigenen Basisnamen einer einzelnen Datei zusammen, und zwar genau dann, wenn bei einem Torrent mit mehreren Dateien genau eine Datei ausgewählt ist: 90 von 112 stichprobenartig geprüften Torrents in dieser Form, gegenüber 0 von 34 mit mehreren, aber nicht allen ausgewählten Dateien und 0 von 24 mit allen ausgewählten. Bei einem Pack mit 221 Dateien, von dem eine Episode ausgewählt war, lautete `original_filename` `Marvel Cinematic Universe MCU Collection 2008-2023 1080p jZQ`, während `filename` `Spider-Man.No.Way.Home.2021.1080p.BluRay.x264...-NOGRP.mkv` lautete. Der Standard liefert also den Pack-Namen, und `retain_rd_torrent_name: true` liefert den Namen der einzelnen Datei – deshalb ist das Flag veraltet: `filename` richtet sich nach dem Kontostatus, der Zugriffsschlüssel darf das aber nicht.

## 3. Benennung von NZB-Releases {#3-nzb-release-naming}

`internal/nzb/provider.go`, releaseName; `internal/nzb/parse.go`

Die Release-ID, die auch ihr Hash ist, ist `hex(sha1(lowercase(nzb filename)))`
— also aus dem Dateinamen und nicht aus dem Inhalt. So verliert ein erneut gespeicherter NZB nicht den Torrent, der daraus gebaut wurde.
Der Ordnername ist dieser DATEINAME ohne Erweiterung, außer der Stamm sieht wie ein Hash aus oder verschwindet beim Bereinigen komplett. In dem Fall wird stattdessen der Name aus den `<head>`-Metadaten der NZB verwendet.
Der Dateiname hat Vorrang, weil er der Name ist, den der Indexer vergeben, der Downloader gespeichert und die Automatisierung beim Suchen nach dem Release verwendet. Indexer posten Releases außerdem oft neu, mit einer Betreffzeile im Metadatenblock. `stemLooksJunk`, `looksLikeHash` und `sanitizeReleaseName` in `internal/nzb/parse.go` klären alle drei Fragen. Behandle sie einfach als Black Box.

## 4. Die drei Namenszusätze {#4-the-three-name-suffixes}

Es gibt drei Suffix-Formate. Sie haben nichts miteinander zu tun.

  ` {xxxxxx}`   Bei einem Release-Ordner, wenn zwei VERSCHIEDENE Releases denselben Namen haben:
                sechs Hex-Zeichen aus dem eigenen Infohash dieses Releases. Innerhalb der
                Gruppe behält das ZULETZT HINZUGEFÜGTE Release den nackten Namen, und
                jedes andere bekommt das Tag. Entschieden wird einmal pro Refresh durch einen Durchlauf,
                der die ganze Bibliothek sehen kann und als KeySuffixed gespeichert wird, damit
                GetKey eine reine Funktion des Torrents bleibt
                (`internal/torrent/key.go`, disambiguateNames). Ein RD-Torrent
                und ein NZB desselben Releases sind hier zwei verschiedene Releases,
                da der Hash eines NZB ein sha1 seines Dateinamens ist.

  ` (tag).ext`  Bei einer DATEI, deren Basisname innerhalb eines Releases mehrfach vorkommt, da zurg
                den Baum eines Torrents in ein einziges Verzeichnis einebnet. Das Tag ist
                das Verzeichnis, das die kollidierenden Dateien bereits unterscheidet —
                die flachste Pfadkomponente, die sich innerhalb der Gruppe unterscheidet, sonst
                sechs Hex-Zeichen aus sha1 über den Pfad der Datei. Welche Tiefe infrage kommt und was
                eine Komponente in einen Dateinamen übernehmen darf, sind `dupeTags` und `sanitizeTag` in
                `internal/torrent/dupenames.go`; behandle beide als undurchsichtig. Die
                Gruppe umfasst jede Datei der Auflistung, ausgewählt oder nicht, damit eine Datei,
                die nicht mehr ausgewählt ist, weiterhin auf den Schlüssel aufgelöst wird, unter dem sie
                abgelegt wurde. `__magic__` ist die einzige Ausnahme: es zeigt den echten Baum
                des Releases ohne Tags, weil dort die Verzeichnisse die Dateien unterscheiden — Abschnitt 8.

  `_xxxxxxxx`   Bei einem Dateinamen AUF DER FESTPLATTE, dessen Eingabe irgendein Nicht-ASCII-Zeichen
                enthielt: acht Hex-Zeichen aus sha256 dieser Eingabe.
                Abschnitt 6. Erscheint nie im Mount.

## 5. Dateinamen innerhalb eines Releases {#5-file-names-inside-a-release}

`internal/torrent/manager.go`. VisibleName(key, file) ist die einzige Stelle, die festlegt, welchen Namen das Mount anzeigt und auf welchen Namen eine Suche passen muss: ein File.Rename, falls vorhanden und `ignore_renames` auf false steht, sonst der SelectedFiles-Schlüssel, der bereits die Kennzeichnung aus Abschnitt 4 enthält. GetFilename gibt stattdessen `filepath.Base(file.Path)` zurück und wirft damit diese Kennzeichnung weg. Anzeige und Suche müssen beide über VisibleName laufen, sonst findet eine Anfrage für einen gekennzeichneten Namen nichts, während N Dateien denselben blanken Namen teilen.

## 6. Dateinamen auf dem Datenträger {#6-on-disk-filenames}

`internal/torrent/utils.go`, sanitizeFilename: schwer nachvollziehbar. Es wird NUR auf Dateien angewendet, die zurg auf dem Host schreibt (`data/<name>.zurgtorrent` und den STRM-Baum), nie auf das, was der Mount ausliefert. Es ist deutlich aggressiver als alles oben. Ein Release, dessen Mount-Ordner `Три богатыря` heißt, hat eine Cache-Datei, deren Name aus einer Reihe Unterstriche besteht, gefolgt vom Suffix `_xxxxxxxx`. So bleibt sie vom nächsten kyrillischen Titel unterscheidbar. Das ist ein anderer Namensraum, und er soll nicht übereinstimmen.

## 7. Inhalte von Archiven {#7-archive-interiors}

Ein Release, das aus einem RAR-, ZIP- oder 7z-Archiv kommt, zeigt den Inhalt des Archivs statt seiner Volumes. Dabei ändern zwei Regeln, wie diese Einträge heißen.

`stripRedundantRoot` (`internal/universal/rar_streamer.go`) entfernt führende Verzeichnisse, die das ganze Archiv umschließen. `payloadRenames` (`internal/universal/deobfuscate.go`) zeigt eine einzelne verschleierte Nutzdatei unter dem Namen des RELEASEs an und verschiebt dabei alle Einträge, die denselben Stamm haben. Was als verschleiert gilt, bestimmt `looksObfuscated` in derselben Datei. Das ist zurgs Portierung des Tests von SABnzbd, und genau wie die Schutzprüfungen drumherum ist er undurchsichtig. Auf der Festplatte wird nichts umbenannt, und `archiveName` löst auch die eigene Schreibweise des Archivs auf.

## 8. Verzeichnisnamen {#8-directory-names}

`internal/torrent/manager.go`, `internal/torrent/provider_directories.go`

Eingebaut und reserviert:

    __all__          jedes Release
    __unplayable__   Releases ohne abspielbare Inhalte
    __dump__         aussortierte Torrents
    __downloads__    die Downloads-Ansicht
    __magic__        das beschreibbare Overlay, das einzige Verzeichnis, dessen Aufbau gespeichert statt berechnet wird. Sein eigenes `__all__` spiegelt die Bibliothek – jedes Release, das `__all__` enthält, jeweils als Verzeichnisbaum, den die `File.Path`-Werte seiner Dateien beschreiben, statt flach (`internal/magic/tree.go`) – und alles neben diesem Spiegel ist das, was der Nutzer gespeichert hat. Der Spiegel wird berechnet, deshalb darf nichts in ihn geschrieben werden; `MirrorDirectory` in `internal/magic/resolve.go` benennt ihn
    int__all__       interner Hash-Index

`__downloads__` und `__magic__` sind keine Filter, daher werden sie von Hand an die Root-Auflistung angehängt, und `__magic__` erscheint nur, wenn magic aktiviert ist. Jeder Name, der mit `int__` beginnt, wird in der Root-Auflistung komplett übersprungen.

Pro Konto gibt es noch einen weiteren, `"__" + account name + "__"` – `__realdebrid__`, `__torbox__`, `__nzb__` –, der aus dem providers-Block erstellt wird. Er bestimmt auch, woher Lesezugriffe kommen: Eine Datei, die unter `__torbox__` geöffnet wird, wird von TorBox ausgeliefert, auch wenn ein anderes Konto dasselbe Release hat und laut Konfigurationsreihenfolge gewinnen würde. Ein Konto, dessen Name mit einem reservierten kollidieren würde, bekommt keines, und zurg gibt eine Warnung aus. Alles andere auf der Root-Ebene ist ein Schlüssel aus dem `directories:`-Block, unverändert.

## 9. Vom Nutzer umbenannt {#9-user-renames}

`internal/torrent/rename.go`, `internal/torrent/rename_bulk.go`

Eine Umbenennung ist nur eine Ansicht und ändert nichts am Debrid-Konto. Sie wird als Torrent.Rename oder File.Rename gespeichert und hat Vorrang vor allen oben beschriebenen Ableitungen, bis `ignore_renames: true` dafür sorgt, dass zurg sie komplett ignoriert.

Eine Torrent-Umbenennung wird nur akzeptiert, wenn der Name nach dem Trimmen nicht leer ist, kein `/` oder `\` enthält und dem eigenen `filepath.Clean` entspricht (das lehnt auch `.` und `..` ab). Außerdem darf er nicht mit einem vorhandenen Zugriffsschlüssel kollidieren, der zu einem anderen Hash gehört. Beim Anwenden werden die Verzeichnis-Maps neu zugeordnet, die `.zurgtorrent` mit dem neuen Namen geschrieben und die Datei mit dem alten Namen GELÖSCHT. Bleibt sie liegen, lädt ein Neustart beide Dateien und die Umbenennung wird stillschweigend wieder rückgängig gemacht.

Der Season-Fix (`/torrents/season-fix/plan` und `/apply`) ist eine Massen-Umbenennung von Dateien, die sich nach der eigenen Episodenzuordnung von Plex richtet. Plan ist rein lesend und gibt für jede Datei einen Grund für das Überspringen aus. Apply nimmt eine explizite Liste von Hashes entgegen und keinen Alle-anwenden-Schalter. Das Dashboard steuert beides über `/season-fix/`. Dort stehen auch die Zuordnungsregeln und die Gründe zum Überspringen, damit du als Betreiber alles nachlesen kannst.

## 10. Folgen für alles, was mit zurg verbunden ist {#10-consequences-for-anything-integrating-with-zurg}

Wenn du einen Pfad aus dem Namen des Torrents baust (eine Symlink-Sammlung, ein Remote-Pfad-Mapping, ein Skript), geht das auf diese Arten schief:

  a. Die Endung. Nur `.mkv` und `.mp4` werden abgeschnitten, und zwar case-sensitiv. Jeder andere Container behält seine Endung im Ordnernamen.

  b. Das Umbenennen. `Torrent.Rename` hat Vorrang vor dem abgeleiteten Namen, und wenn RD einen Torrent selbst umbenennt, ändert sich `Name` ohne dein Zutun.

  c. Das Hash-Suffix. Wenn zwei verschiedene Releases denselben Namen haben, bekommt einer von ihnen ` {a1b2c3}` angehängt. Welcher das ist, wechselt, sobald Inhalte hinzukommen.

  d. Die Tag-Kennzeichnung bei doppelten Dateien. Eine Datei, deren Basisname innerhalb eines Releases mehrfach vorkommt, wird als `name (tag).ext` ausgeliefert, wobei das Tag eine Verzeichniskomponente oder ein Pfad-Hash ist. `filepath.Base(file.Path)` reproduziert das nicht.

  e. Das Umbenennen im Archiv. Eine verschleierte Nutzdatei in einem Archiv wird unter dem Release-Namen angezeigt, nicht unter ihrem eigenen.

  f. NZB-Namen stammen vom DATEINAMEN der `.nzb`-Datei, nicht von irgendetwas darin, es sei denn, der Dateiname ist ein Hash. Benenne die Datei, benenne den Ordner.

  g. Bereinigte Dateinamen auf der Festplatte sind ein anderer Namensraum als die Namen im Mount, und bei Releases mit Nicht-ASCII-Zeichen stimmen sie absichtlich nicht überein.

Der zuverlässige Weg, ein Release aufzulösen, ist über den Hash, und dann fragst du zurg, wie es heißt. Den Namen selbst zusammenzubauen ist Raten, und jede Regel oben ist eine Möglichkeit, wie das Raten danebenliegen kann.
