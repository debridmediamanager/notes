# Offcloud

`type: offcloud`

Offcloud löst Dateihandles über den Cloud-Explore-Endpunkt auf. Dateigrößen werden gegen den Auslieferungsserver geprüft und nicht einfach der Auflistung geglaubt. Zwischengespeicherte Torrent-Metadaten liefern die Ordnerpfade überall dort, wo sie sich eindeutig zuordnen lassen.

## API-Schlüssel holen {#get-the-api-key}

Melde dich an und öffne [offcloud.com/#/account](https://offcloud.com/#/account). Der API-Key steht auf dieser Seite.

## Konfigurieren {#configure-it}

```yaml
zurg: v1
providers:
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Bei einer frischen Container-Installation lass das Setup es schreiben.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider offcloud
```

Bei einer Installation, die schon eine `config.yml` hat, nutze **Add provider** im Dashboard unter
`http://localhost:9999/config/` oder bearbeite die Datei. Starte in beiden Fällen neu.

```bash
docker compose restart zurg
```

`OFFCLOUD_TOKEN` wird von `zurg setup` gelesen und nicht vom laufenden Daemon.

## Ein Zugang pro Eintrag {#one-credential-per-entry}

Offcloud-Datei-Handles gehören zu dem Account, der sie aufgelistet hat. Es gibt keinen
zweiten Schlüssel, auf den man wechseln könnte. `download_tokens` wird abgelehnt, und ein
`strm_link_token`, das sich von `token` unterscheidet, genauso. Ein zweiter Account ist ein zweiter Eintrag mit eigenem `name`.

```yaml
providers:
  - type: offcloud
    name: oc-main
    token: FIRST_OFFCLOUD_API_KEY
  - type: offcloud
    name: oc-second
    token: SECOND_OFFCLOUD_API_KEY
```

## Was hier funktioniert {#what-works-here}

Bibliothek durchsuchen, gestreamte Lesezugriffe, umgeleitete Lesezugriffe, STRM, Magnet-Hinzufügungen, `.torrent`-Uploads und Löschen funktionieren alle. Das Konto bekommt ein eigenes `__offcloud__`-Verzeichnis.

## Grenzen, die man kennen sollte {#limits-worth-knowing}

**8 gleichzeitige API-Anfragen.** Vier Teile eines mehrteiligen Archivs werden
auf einmal aufgelöst.

**Inhalte laufen ab.** Ein Release, das nicht mehr da ist, gilt als erwartet und
nicht als kaputt. Repair lässt es in Ruhe, solange du nichts anderes sagst.

**Die Torrent-Liste enthält keine Dateidetails.** Jedes Release kostet beim
ersten Mal eine eigene Abfrage.

**Eine mehrdeutige Dateiliste ist ein Fehler und kein Raten.** Manchmal lassen
sich die gecachten Torrent-Metadaten nicht eindeutig einem einzigen Release
zuordnen. zurg meldet das, statt Ordnerpfade zu wählen, die vielleicht zu
etwas anderem gehören.

**Fehlerhafte Magnets werden lokal abgelehnt.** Sie erreichen den Dienst gar
nicht. Ein schlechter Magnet kostet also nichts.

Offclouds Fehlercodes sind recht dünn. `NOAUTH` ist der einzige Code, mit dem
zurg etwas anfangen kann, und er bedeutet, dass die Zugangsdaten abgelehnt
wurden. Alles andere kommt als Ablehnung ohne Grund an.

## Prüfen, ob es funktioniert hat {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/offcloud/test
ls /zurg_mnt/zurg/__all__/ | head
```

Bei nur einem Konto wird dessen eigener Ordner aus der Root-Ansicht des Mounts weggelassen,
daher zeigt der Mount dieselben Dateien unter `__all__` an.

## Wenn es schiefgeht {#when-it-goes-wrong}

**`NOAUTH` im Log.** Der Schlüssel wurde widerrufen oder neu erzeugt. Hol dir einen neuen unter [offcloud.com/#/account](https://offcloud.com/#/account) und trag ihn im Eintrag ein.

**`API refused request` ohne weitere Angaben.** Offcloud hat nicht gesagt, warum. Prüf den Account im Browser, bevor du davon ausgehst, dass zurg schuld ist.

**Ein Release zeigt keine Ordner.** Die gecachten Torrent-Metadaten ließen sich keinem einzelnen Release eindeutig zuordnen. Die Dateien lassen sich trotzdem streamen. Sie liegen nur flach.

**Generierte URLs funktionieren für jeden, der sie hat.** Delivery-URLs werden erneuert, wenn ihr Cache abläuft oder wenn ein Lesezugriff sie ungültig macht. Das Kontingent, das sie verbrauchen, ist das deines Accounts. Halte sie und den Zugriff auf `.strm` privat.
