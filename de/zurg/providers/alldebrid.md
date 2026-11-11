# AllDebrid

`type: alldebrid`

[AllDebrid](https://alldebrid.com/?uid=1kk5i&lang=en) ist das andere Backend, das Zugangsdaten rotiert. Deshalb haben `download_tokens`
und ein separater `.strm`-Token hier beide eine Bedeutung. Die Dateilisten kommen von einem eigenen Endpunkt und nicht aus der Magnet-Liste. Das verändert, wie sich ein erster Scan einer großen Bibliothek anfühlt.

## API-Schlüssel holen {#get-the-api-key}

Melde dich an und öffne [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i).
Erstelle einen Schlüssel und kopiere ihn.

## Konfigurieren {#configure-it}

```yaml
zurg: v1
providers:
  - type: alldebrid
    token: YOUR_ALLDEBRID_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Bei einer frischen Container-Installation lässt du das Setup es schreiben.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider alldebrid
```

Bei einer Installation, die schon eine `config.yml` hat, nutzt du **Add provider** im Dashboard unter `http://localhost:9999/config/` oder bearbeitest die Datei. Starte in beiden Fällen neu.

```bash
docker compose restart zurg
```

`ALLDEBRID_TOKEN` wird von `zurg setup` gelesen und nicht vom laufenden Daemon. Wenn du es in den `environment:`-Block deiner Compose-Datei schreibst und den Container startest, passiert dadurch allein nichts.

## Zusätzliche Schlüssel, die dieses Backend verwendet {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: alldebrid
    token: PRIMARY_AD_API_KEY
    strm_link_token: AD_KEY_FOR_STRM
    download_tokens:
      - SECOND_AD_API_KEY
```

`download_tokens` sind Backup-Keys für denselben Dienst. Sie springen ein, wenn das
Bandbreitenkontingent des aktiven Keys aufgebraucht ist. Sie nutzen den Katalog
dieses Eintrags, und ihre eigenen Bibliotheken werden nie importiert.

`strm_link_token` löst die Zugriffe auf `/strm/` auf, damit ein Player, der eine
`.strm` öffnet, nicht den Key belastet, über den dein Live-Mount streamt. Ist er
nicht gesetzt, wird stattdessen `token` verwendet.

## Der erste Scan füllt sich nach und nach {#the-first-scan-fills-in-gradually}

AllDebrid v4.1 hat die Dateidetails aus der Magnet-Liste in einen eigenen Endpoint verschoben. Wenn du deine Magnets auflistest, sagt das zurg nicht, was darin steckt. Für jedes Release ist eine eigene Abfrage nötig.

Die gute Nachricht: Diese Abfrage musst du **einmal für immer** machen und nicht einmal pro Neustart. Der Dateibaum eines Magnets ist unveränderlich, sobald er Ready ist. Deshalb ist der Info-Cache von zurg auf der Festplatte dafür dauerhaft. Ein Batcher vor dem Endpoint übernimmt den ersten Scan. Beim ersten Start siehst du also, wie eine große Bibliothek stückweise erscheint, und danach passiert das nie wieder.

## Grenzen, die man kennen sollte {#limits-worth-knowing}

**Keine veröffentlichte Obergrenze für aktive Magnets.** zurg erfindet keine. Die Reparatur wartet nie auf Platz, der nie knapp war.

**600 Anfragen pro Minute für einen Schlüssel.** Das ist das dokumentierte Budget. zurg drosselt sich auf 600 minus 100, damit die Wiederholungen, die der HTTP-Client selbst ausführt, eine Anfragenspitze nicht über die echte Grenze hinaus treiben. In der Praxis ist die Parallelität die bindende Grenze, und sie ist auf 12 begrenzt, um die dokumentierten 12 Anfragen pro Sekunde nachzubilden.

**Die 33. Verbindung zu einem Delivery-Server bekommt einen 429.** Gemessen am 2026-08-23, indem alle 500 ms eine Verbindung geöffnet und gehalten wurde. AllDebrid erzeugt bei jedem Unlock einen neuen Delivery-Hostnamen. Das greift also nur, wenn mehrere Lesevorgänge zufällig denselben Host teilen. zurg stellt ab 32 Verbindungen in eine Warteschlange, statt neue aufzubauen.

**Es gibt keine Auswahl einzelner Dateien.** Beim Hinzufügen eines Magnets wird alles geladen, und die Reparatur fügt das komplette Release erneut hinzu.

**Inhalte verschwinden von selbst.** Magnets werden mit der Zeit aus einem Konto entfernt, und ein Link kann vom Hoster gelöscht werden. Ein Release, das verschwunden ist, ist ein erwartbares Ergebnis und keine Beschädigung. Die Reparatur lässt es in Ruhe, außer du forderst sie ausdrücklich an.

**Gespeicherte Links verfallen nicht.** Die gesperrten Links, die zu einer Datei gespeichert sind, werden aus dem aktuellen Zustand des Magnets neu erzeugt. Der Status des Magnets selbst verrät bereits, ob die Daten da sind. zurg verbraucht bei jedem Kaltscan nicht für jeden Torrent einen Unlock, nur um herauszufinden, was der Status ohnehin schon sagt.

## Prüfen, ob es funktioniert hat {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/alldebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

Bei nur einem Account wird dessen eigener Ordner aus der Root-Auflistung des Mounts ausgelassen,
daher zeigt der Mount dieselben Dateien unter `__all__`.

## Wenn es schiefgeht {#when-it-goes-wrong}

**`AllDebrid rejected the API key` im Log.** Der Schlüssel wurde widerrufen oder neu erzeugt. Hol dir einen neuen unter [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i) und aktualisiere den Eintrag.

**Eine kalte Bibliothek erscheint langsam.** Das ist zu erwarten. Siehe den Abschnitt oben. Es ist eine Abfrage pro Release, und sie wiederholt sich nicht.

**Ein Release spielt woanders im Mount ab, liefert unter `__alldebrid__` aber 404.** Die Defekt-Erkennung läuft pro Account, und dieses Verzeichnis legt die Lesezugriffe auf genau diesen einen Account fest. Ein anderer Account hat wahrscheinlich eine funktionierende Kopie.
