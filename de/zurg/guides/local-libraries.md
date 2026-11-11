# Lokale Debrid-Bibliotheken und portable zurg-Torrents {#local-debrid-libraries-and-portable-zurgtorrents}

Eine lokale Bibliothek bezieht ihre Mitgliedschaft aus portablen `.zurgtorrent`-Dateien. Sie erscheint in den üblichen WebDAV-, HTTP- und Provider-Verzeichnissen. Das Importieren von Dateien, das Auflisten und das Aktualisieren des Katalogs fügen keine Torrents hinzu und lösen keine Download-Links auf. Beim Abspielen wird die angeforderte Datei über dein konfiguriertes Konto aufgelöst.

## Eine Bibliothek exportieren {#export-a-library}

+++ Linux und macOS
```sh
./zurg --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++ Windows
```powershell
.\zurg.exe --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++

`--provider` ist der konfigurierte **Name** des Kontos, auch ein eigener Name. Lass es weg, um alle unterstützten Debrid-Kopien zu exportieren. Die Eingabe kann auch eine einzelne Laufzeit-Cachedatei, ein altes `dump/`-Verzeichnis oder ein bestehender portabler Katalog sein. Für eine lokale Bibliothek exportierst du deren Quellverzeichnis (`torrents/<account>`), das seine optionalen Verweise auf andere Anbieter beibehält.

Der Export läuft offline. Er prüft alle Eingaben und Zielkollisionen, bevor er etwas schreibt. Laufzeit-Einträge ohne ausgewählte Dateimetadaten meldet und überspringt er. Releases führt er anhand des Hashes zusammen und schreibt `<hash>.zurgtorrent`. Bereits vorhandene, identische Exporte kannst du gefahrlos wiederholen. Bei einer Massenmigration mit fehlerhaften alten Cache-Einträgen exportiert `--skip-invalid` die gültigen Einträge und meldet, wie viele ausgelassen wurden. Ohne diese Option bricht der erste ungültige Eintrag ab, bevor etwas geschrieben wird. `--replace` erlaubt das Ersetzen eines portablen Exports mit demselben Hash. Es erlaubt aber niemals das Überschreiben eines Laufzeit-Caches.

Nur die exportierten Dateien sind zum Teilen gedacht. `data/*.zurgtorrent` bleibt private Laufzeitdaten. Eine `.zurgbackup`-Datei enthält außerdem Kontozugangsdaten und ist ein Instanz-Backup, keine teilbare Bibliothek.

## Eine Bibliothek empfangen {#receive-a-library}

Lege die exportierten Dateien in `torrents/rd-local/` ab und konfiguriere dann das empfangende
Konto:

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: YOUR_OWN_TOKEN
    download_tokens: # Optional bandwidth fallback on another RD account.
      - SECOND_RD_TOKEN
    library:
      source: local
      # Optional; defaults to torrents/<account-name>.
      path: torrents/rd-local

  - name: tb-online
    type: torbox
    token: YOUR_OWN_TORBOX_TOKEN
    # Omitted library block means the provider owns this account's catalog.
```

Bei Real-Debrid und AllDebrid nutzt `download_tokens` denselben lokalen Katalog wie
sein Provider-Eintrag. Der zweite RD-Account oben braucht kein Verzeichnis, und seine
Torrent-Bibliothek wird nicht importiert.
Das sind Ersatz-Zugangsdaten, die genutzt werden, wenn das Bandbreiten-Kontingent des aktiven Download-Tokens
aufgebraucht ist. Damit wird nicht jeder Download über den zweiten
Account geleitet. Wenn du stattdessen einen zweiten RD-Eintrag unter `providers` hinzufügst, entsteht ein eigener
Katalog mit eigenem Verzeichnis. Alle Zugangsdaten bleiben in der Konfiguration und sind
von portablen Exporten ausgeschlossen.

TorBox akzeptiert ebenfalls `download_tokens`, aber seine Token-Rotation ordnet die
gespeicherten Torrent-/Datei-IDs nicht den IDs auf dem anderen Account zu. Verwende für separate Accounts
jeweils eigene TorBox-Provider-Einträge, jeder mit eigenem lokalen Katalog.

Auch Premiumize-, Offcloud- und Debrid-Link-Accounts können eine lokale Bibliothek haben. Keiner davon hat eine
portable Datei-Referenz. Daher fügt jeder davon, wie TorBox, den Hash beim ersten
Abspielen seinem eigenen Account hinzu und gleicht die Dateien über Pfad und Größe ab. Verwende pro Account einen Provider-Eintrag.

Starte nach Änderungen an der Account-Konfiguration neu. Hinzugefügte, ersetzte und
entfernte Dateien werden vom normalen Aktualisierungszyklus erkannt. Jedes Verzeichnis wird
eine Ebene tief gescannt. Pfade müssen unterschiedliche Verzeichnisse unterhalb von `torrents/` sein, damit normale
Backups sie einschließen. Ein nicht lesbares Verzeichnis oder eine ungültige Ersetzung behält
den letzten gültigen Eintrag im Speicher und protokolliert das Problem. Nach einem Neustart muss eine
ungültige Datei korrigiert werden, bevor sie in den Katalog aufgenommen werden kann.

Dasselbe Manifest kann in das lokale Verzeichnis eines AllDebrid- oder TorBox-Accounts kopiert werden. Es enthält
die Inhalts-Identität, keinen Provider-Accountnamen. Derselbe
Hash über mehrere Accounts hinweg erscheint einmal mit mehreren Quellen und nutzt die vorhandene
Account-Priorität und Failover-Reihenfolge. Doppelte Dateien für einen Hash innerhalb eines
Verzeichnisses verwenden den ersten Dateinamen in sortierter Reihenfolge; behalte pro Hash ein Manifest bei.

Die Zugehörigkeit zum lokalen Katalog bleibt erhalten, wenn ein Torrent aus der Online-Bibliothek des Providers entfernt wird.
Umbenennungen, Tags, IMDb-IDs und Dateilöschungen werden in die Manifeste zurückgeschrieben.
Wenn du ein lokales Release entfernst, werden seine Quelldokumente entfernt; Provider-Torrents werden nicht gelöscht. Wenn du ein Release mit Online-Kopien entfernst, werden auch diese Online-Kopien gelöscht, so wie beim normalen Löschen eines ganzen Releases.

Lokale Accounts sind keine Ziele für Watchlists, Magnet-Uploads oder Torrent-Datei-Uploads. Füge Einträge durch den Import von Manifesten hinzu. `add_torrents: false` erlaubt RD/AD weiterhin, eine vorhandene geteilte Referenz einzulösen, verhindert aber, dass beim Abspielen eine provider-seitige Zuordnung erstellt wird, wenn eine benötigt wird.

## Ein Online-Konto in eine lokale Bibliothek auslagern {#offload-an-online-account-into-a-local-library}

AllDebrid erlaubt höchstens 1000 Magnets pro Konto, und auch Real-Debrid-Konten laufen irgendwann voll. Eine fertige Veröffentlichung braucht ihren Torrent nicht mehr auf dem Konto, um weiter abspielbar zu sein. Ein Real-Debrid-`/d/`-Link funktioniert weiter, nachdem der Torrent gelöscht wurde, und ein gesperrter AllDebrid-`/f/`-Link funktioniert weiter, nachdem das Magnet gelöscht wurde. Das Auslagern baut darauf auf. zurg schreibt eine fertige Veröffentlichung in eine lokale Bibliothek beim selben Dienst und löscht danach den Torrent vom Online-Konto, wodurch der Platz frei wird. Die Veröffentlichung behält ihren Ordner im Mount und wird über die gespeicherten Links abgespielt.

Richte zwei Einträge für dasselbe Konto ein, einen online und einen lokal:

```yaml
providers:
  - name: ad
    type: alldebrid
    token: YOUR_AD_TOKEN
    library:
      offload_to: ad-local     # the local entry below
      offload_after_mins: 30   # optional, 30 is the default

  - name: ad-local
    type: alldebrid
    token: YOUR_AD_TOKEN       # the same token
    library:
      source: local            # manifests live in torrents/ad-local/
```

Neue Veröffentlichungen kommen weiterhin auf `ad` an. Nach jeder vollständigen Auflistung dieses Kontos und alle fünf Minuten verschiebt zurg die Veröffentlichungen, die die Bedingungen erfüllen, eine nach der anderen.

Eine Veröffentlichung erfüllt die Bedingungen, wenn:

- Sie ist seit `offload_after_mins` auf dem Konto vollständig. Gezählt wird ab dem Moment, in dem dieser zurg-Prozess sie zum ersten Mal als vollständig gesehen hat. Ein Neustart startet die Wartezeit wieder von vorn.
- Jede Datei hat einen funktionierenden Link auf diesem Konto, den ein anderes Konto einlösen könnte. Eine Veröffentlichung, bei der auch nur einer Datei so ein Link fehlt, bleibt online.
- Sie ist gesund, wird nicht repariert, und keine Instanz davon wird noch heruntergeladen. Kein Reparaturdurchlauf und kein Download-Client hält ihren Torrent fest.
- Kein qBittorrent-Job von Sonarr oder Radarr listet sie noch auf. Schalte Remove Completed Downloads in den *arr-Apps ein, damit ein Job nach dem Import entfernt wird. Sonst bleibt die Veröffentlichung online, bis du den Job entfernst.
- Acquisition hat sie nicht in der letzten Stunde hinzugefügt.
- Das Verschieben ändert kein Verzeichnis, in dem sie liegt, und behält ihren Ordnernamen. Ein Verzeichnis mit einem `provider:`-Filter, der das Online-Konto nennt, würde sie verlieren, deshalb bleibt eine solche Veröffentlichung online.

Die Reihenfolge ist festgelegt. Das Manifest `<hash>.zurgtorrent` wird zuerst in die lokale Bibliothek geschrieben, danach kommt die Veröffentlichung in die lokale Bibliothek, und erst dann wird der Torrent vom Online-Konto gelöscht. Lässt sich das Manifest nicht schreiben, wird nichts gelöscht. Schlägt das Löschen fehl, bleibt die Online-Kopie neben der lokalen, und beim nächsten Refresh zeigt sich, ob der Torrent noch da ist. Ein Manifest, das die lokale Bibliothek für die Veröffentlichung schon hat, wird an Ort und Stelle aktualisiert statt doppelt geschrieben. Die Links des Online-Kontos darin werden aktualisiert, Namen und Änderungen folgen der Veröffentlichung, so wie der Mount sie zeigt, und die Links des anderen Dienstes bleiben erhalten.

Die Veröffentlichung verlässt `__ad__` und erscheint unter `__ad-local__`. Jedes andere Verzeichnis, `__all__` und deine eigenen eingeschlossen, listet sie weiterhin unter demselben Namen. Es wird kein Medienserver-Scan gestartet, weil sich nichts geändert hat, was ein Medienserver indexiert. Richte Plex und andere Medienserver auf diese Verzeichnisse statt auf ein kontospezifisches.

Wenn beide Einträge auf demselben Token liegen, kann die lokale Wiedergabe eine Veröffentlichung wieder demselben Konto hinzufügen (siehe unten), und dieser Torrent taucht dann in der Online-Auflistung auf. zurg lagert nie eine Veröffentlichung aus, deren Online-Torrent so eine Hinzufügung ist, und auch nicht, während die lokale Wiedergabe gerade eine hinzufügt, weil das Löschen die Wiedergabe zerstören würde, die sie gerade erst bekommen hat.

Nur Real-Debrid und AllDebrid können auslagern. TorBox, Premiumize, Offcloud und Debrid-Link haben keinen Link, der den Torrent überlebt. Deshalb fügt ihre lokale Wiedergabe den Torrent wieder hinzu, und ein Auslagern würde keinen Platz freigeben. zurg lehnt `offload_to` bei diesen Konten ab.

Im Dashboard kannst du auch einzelne Veröffentlichungen verschieben. Auf der Seite einer Veröffentlichung zeigt die Tabelle Accounts neben jeder Real-Debrid- oder AllDebrid-Kopie den Button Move to local library, wenn eine lokale Bibliothek desselben Typs existiert, auch ohne `offload_to`. Kann die Veröffentlichung noch nicht verschoben werden, ist der Button deaktiviert und sagt, warum. Die Kontoeinstellungen auf der Konfigurationsseite bieten dieselbe Auswahl und zeigen, wie viele Veröffentlichungen seit dem Start von zurg verschoben wurden, sowie den letzten Fehler.

## Was in der Datei steckt {#what-travels-in-the-file}

Das versionierte JSON-Format hat `format: "zurgtorrent"` und die numerische `version: 1`.
Es enthält den Infohash, die Release-Namen, den Zeitstempel des Hinzufügens, den Rename, die Tags, die IMDb-ID
und die ausgewählten Dateipfade, Größen und optionalen Renames. Referenzen sind optional:

| Anbieter | Übertragbare Referenz | Wiedergabe |
|---|---|---|
| Real-Debrid | Kanonische 13-stellige `https://real-debrid.com/d/...` | Mit den Zugangsdaten und der Download-IP des Empfängers auflösen. |
| AllDebrid | Gesperrte `https://alldebrid.com/f/...` | Mit den Zugangsdaten des Empfängers entsperren. |
| TorBox | Hash und Dateipfade/Größen | Beim ersten Abspielen einen Torrent auf der Seite des Empfängers besorgen und dessen Dateien anhand von Pfad und Größe zuordnen. |
| Premiumize, Offcloud, Debrid-Link | Hash und Dateipfade/Größen | Beim ersten Abspielen den Hash im Konto des Empfängers hinzufügen und dessen Dateien anhand von Pfad und Größe zuordnen. |

Es werden keine Kontonamen, Zugangsdaten, Anbieter-Torrent-/Datei-IDs, CDN-URLs, MediaInfo-Eingabe-URLs, Plex-IDs, Reparaturstatus oder Löschwarteschlangen exportiert.
Der Importer lehnt unbekannte Felder sowie URLs mit Zugangsdaten oder unerwartete Referenz-URLs ab.
Beim Prüfen eines Manifests ruft er keine URLs ab.
Usenet behält sein `.nzb`-Quellformat; NZB-Laufzeit-Caches lassen sich nicht als übertragbare Torrents exportieren.

## Wiedergabe und Grenzen {#playback-and-limits}

Lokales Tracking ändert, wer den Katalog besitzt. Es garantiert aber nicht, dass ein Anbieter die Daten noch hat oder sie ausliefern kann. Zugriff auf den Account, erlaubte Netzwerkstandorte, aktive Slots, Kontingente und Rate Limits gelten weiterhin.

RD und AD nutzen geteilte, gesperrte Referenzen, wenn vorhanden. Nur-Hash-Manifeste und eine RD-Referenz, die die API eindeutig als fehlend meldet,
können Inhalte auf dem Account des Empfängers anlegen. TorBox braucht immer diese Account-Zuordnung und verwendet zuerst einen passenden Torrent,
der schon auf dem Account des Empfängers liegt. Adds nutzen das bestehende Pacing des Anbieters und werden pro Account nacheinander abgearbeitet. Meldet der Account seine Slot-Anzahl, oder kennt zurg sie, wird ein Add auf einen vollen Account abgelehnt, und die nächste Playback-Anfrage nach einer Minute versucht es erneut. AllDebrid, Premiumize und Offcloud melden keine Anzahl, also läuft der Add los, und ein voller Account lehnt ihn ab. Ein unsicherer Add wird 30 Minuten zurückgehalten, bevor ein neuer Versuch startet; ein Torrent in Vorbereitung wird erst dann geprüft, wenn die Wiedergabe erneut angefragt wird.

Empfänger-IDs und aufgelöste native Datei-Handles bleiben privat in `data/local-torrents/`. Dieser Eintrag übersteht einen Neustart und ist in normalen Backups enthalten. zurg löscht diese Zuordnungen nie automatisch: Ein idempotenter Add hat unter Umständen einen Torrent zurückgegeben, den der Empfänger schon besaß. Auch Offloading lässt sie in Ruhe. Bei Anbieterfehlern bleibt der lokale Eintrag sichtbar, und zurg wartet ab, statt eine Hintergrundreparatur zu starten oder bei jedem Scan einen Add zu wiederholen.

Lokale Archiv-Releases listen ihre Quell-Volumes auf, ohne automatisch zu entpacken oder im Hintergrund zu prüfen. Ein explizit angegebener Pfad innerhalb eines Archivs kann trotzdem den Archiv-Reader aufrufen. Automatisches MediaInfo-Probing und Prefetch der nächsten Datei sind bei Einträgen mit lokalen Kopien deaktiviert.

## Einen alten Dump migrieren {#migrate-an-old-dump}

Exportiere `dump/` mit dem oben genannten Befehl, lege die Ergebnisse im Verzeichnis `torrents/<name>/` des empfangenden Accounts ab und aktiviere `library.source: local`. Deaktiviere `load_dumped_torrents` nach der Migration. Der alte, optionale `__dump__`-Reader bleibt aus Kompatibilitätsgründen erhalten; neue lokale Bibliotheken verwenden ihn nicht. Runtime-Caches ohne Account-Typ müssen von einer Instanz neu exportiert werden, die deren Provider kennt, bevor sie geteilt werden können.

Backups, die von diesem Build geschrieben werden, verwenden Format 2, um die neuen dauerhaften Wurzeln einzuschließen. Der Restore-Befehl liest weiterhin Backups im Format 1. Ältere Builds verweigern Format 2, statt eine lokale Bibliothek stillschweigend zu verwerfen.
