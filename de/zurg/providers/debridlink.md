# Debrid-Link

`type: debridlink`

[Debrid-Link](https://debrid-link.com/id/diG1t)s Seedbox-Liste enthält jede Datei. Ein Bibliotheks-Refresh kostet einen paginierten Durchlauf statt einer Abfrage pro Release. Von den drei Cloud-Backends ist es das günstigste, um die Bibliothek synchron zu halten.

## API-Schlüssel holen {#get-the-api-key}

Melde dich an und öffne [debrid-link.fr/webapp/apikey](https://debrid-link.fr/webapp/apikey). Erstelle einen Schlüssel und kopiere ihn.

## Konfigurieren {#configure-it}

```yaml
zurg: v1
providers:
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Bei einer frischen Container-Installation lass das Setup die Datei schreiben.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider debridlink
```

Wenn bereits eine `config.yml` vorhanden ist, nutze **Add provider** im
Dashboard unter `http://localhost:9999/config/` oder bearbeite die Datei. Starte in beiden Fällen neu.

```bash
docker compose restart zurg
```

`DEBRIDLINK_TOKEN` wird von `zurg setup` gelesen und nicht vom laufenden Daemon.

## Ein Zugang pro Eintrag {#one-credential-per-entry}

Debrid-Link löst jede Datei über eine ID auf, die zum Listing-Konto gehört.
Es gibt keinen zweiten Schlüssel, auf den man wechseln könnte. `download_tokens` wird abgelehnt, und ebenso ein `strm_link_token`, der sich von `token` unterscheidet. Ein zweites Konto ist ein zweiter Eintrag mit eigenem `name`.

```yaml
providers:
  - type: debridlink
    name: dl-main
    token: FIRST_DEBRID_LINK_API_KEY
  - type: debridlink
    name: dl-second
    token: SECOND_DEBRID_LINK_API_KEY
```

## Was hier funktioniert {#what-works-here}

Bibliothek durchsuchen, gestreamte Lesezugriffe, umgeleitete Lesezugriffe, STRM, Magnet-Hinzufügen, `.torrent`-Uploads und Löschen funktionieren alle. Das Konto bekommt sein eigenes `__debridlink__`-Verzeichnis.

## Grenzen, die man kennen sollte {#limits-worth-knowing}

**20 aktive Slots.** Das ist die Obergrenze, ab der zurg das Hinzufügen weiterer Inhalte blockiert.

**8 gleichzeitige API-Anfragen.** Vier Volumes eines Multi-Volume-Archivs werden gleichzeitig aufgelöst.

**Inhalte laufen ab.** Ein Release, das nicht mehr verfügbar ist, gilt als erwartet und nicht als kaputt.

**Es gibt keine Cache-Prüfung.** Debrid-Link hat diesen Endpunkt eingestellt, und zurg nutzt ihn nicht. Ein Add mit cached-only kann einen Treffer nur anhand der Antwort auf das Hinzufügen selbst feststellen. Vor dem Hinzufügen zu fragen, ob etwas gecacht ist, kann dieses Backend nicht beantworten.

zurg ordnet die Fehlercodes des Dienstes der Aktion zu, die als Nächstes ansteht.

| Code von Debrid-Link | Was zurg macht |
|---|---|
| `badToken` oder `badSign` | Meldet ein ungültiges Zugangsdaten-Problem. Korrigiere den Key. |
| `floodDetected` | Pausiert das Konto für eine Stunde. |
| `maxTorrent` `maxData` `maxLink` und ihre `Host`-Varianten | Meldet ein aufgebrauchtes tägliches Kontingent für Adds oder Traffic. |
| `serverNotAllowed` `maintenanceHost` `maxTransfer` | Behandelt das Konto als vorübergehend nicht verfügbar. |
| `badId` | Behandelt den Torrent als nicht mehr vorhanden. |

!!!warning Eine Flood-Abweisung kostet eine Stunde
`floodDetected` sperrt das Konto für volle eine Stunde statt nur einer Minute. Das ist so gewollt. Wer in eine Flood-Abweisung hineinwiederholt, provoziert die nächste. Bevor du zurg neu startest, verteile alles, was den Dienst bisher bombardiert hat, zeitlich auf mehr Abstand.
!!!

## Prüfen, ob es funktioniert hat {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/debridlink/test
ls /zurg_mnt/zurg/__all__/ | head
```

Mit nur einem Account wird dessen eigener Ordner aus der Root-Auflistung des Mounts ausgelassen,
daher zeigt der Mount dieselben Dateien unter `__all__`.

## Wenn es schiefgeht {#when-it-goes-wrong}

**Eine Stunde lang passiert nichts.** Eine Flut an Ablehnungen. Siehe die Warnung oben.

**Grabs werden abgelehnt, Lesezugriffe funktionieren aber weiterhin.** Das tägliche Limit für Hinzufügungen oder Traffic ist aufgebraucht. Es wird nach dem eigenen Zeitplan des Dienstes zurückgesetzt.

**Hinzufügungen klappen, und dann passiert nichts.** Ohne Cache-Endpunkt gibt es keine Möglichkeit, im Voraus zu wissen, ob ein Hash schon gespeichert war. Ein nicht gecachter Eintrag wird wie jeder andere heruntergeladen.
