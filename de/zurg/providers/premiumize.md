# Premiumize

`type: premiumize`

Premiumize hängt sowohl abgeschlossene Transfers **als auch** die Cloud-Dateien ein, die übrig bleiben, nachdem die Transferliste geleert wurde. Verschachtelte Ordner behalten ihre Pfade. Eine Bibliothek, die du auf Premiumize sortiert hast, erscheint im Mount so, wie du sie hinterlassen hast.

## API-Schlüssel holen {#get-the-api-key}

Melde dich an und öffne [premiumize.me/account](https://www.premiumize.me/account). Den API-Schlüssel findest du auf dieser Seite.

## Konfigurieren {#configure-it}

```yaml
zurg: v1
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Bei einer frischen Container-Installation lässt du das Setup es schreiben.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider premiumize
```

Bei einer Installation, die bereits eine `config.yml` hat, benutzt du im Dashboard unter `http://localhost:9999/config/` den Button **Add provider** oder bearbeitest die Datei direkt. In beiden Fällen startest du danach neu.

```bash
docker compose restart zurg
```

`PREMIUMIZE_TOKEN` wird von `zurg setup` gelesen und nicht vom laufenden Daemon. Wenn du es einfach so in einem compose `environment:`-Block stehen lässt, passiert damit gar nichts.

## Ein Zugang pro Eintrag {#one-credential-per-entry}

Premiumize-Datei-IDs gehören zu dem Konto, das sie angelegt hat. Es gibt keinen zweiten Schlüssel, auf den man umschalten könnte. `download_tokens` wird rundweg abgelehnt, und ebenso ein `strm_link_token`, der sich von `token` unterscheidet. Ein zweites Premiumize-Konto ist ein zweiter Eintrag mit eigenem `name`.

```yaml
providers:
  - type: premiumize
    name: pm-main
    token: FIRST_PREMIUMIZE_API_KEY
  - type: premiumize
    name: pm-second
    token: SECOND_PREMIUMIZE_API_KEY
```

Der Loader ist hier ausdrücklich. Er ignoriert die Schlüssel nicht stillschweigend, sondern verweigert die Konfiguration und nennt den betroffenen Eintrag.

## Was hier funktioniert {#what-works-here}

Bibliothek durchsuchen, gestreamte Lesevorgänge, umgeleitete Lesevorgänge, STRM, Magnet-Links, `.torrent`-Uploads und Löschen funktionieren alle. Der Account bekommt, wie jeder andere auch, ein eigenes `__premiumize__`-Verzeichnis.

## Hashes werden auf der Festplatte gespeichert {#hashes-are-remembered-on-disk}

Hashes, die über zurg geliefert werden, landen in
`data/premiumize/<account>/sources.json` innerhalb des `/config`-Binds. Der Abgleich zwischen Accounts übersteht einen Neustart und auch das Leeren der Liste abgeschlossener Transfers.

Cloud-Inhalte, die du auf anderem Weg importiert hast, haben keinen gespeicherten Hash. Sie werden trotzdem gestreamt. Sie lassen sich aber nicht über den Hash reparieren, und man kann sie über den Hash auch keinem anderen Account zuordnen.

!!!warning Einen Transfer zu löschen, löscht auch seine Dateien
Wenn du einen Premiumize-Transfer über zurg löschst, werden auch die Dateien gelöscht, die zu diesem Transfer gehören. Das ist Premiumizes eigenes Verhalten und nichts, was zurg zusätzlich einbaut.
!!!

## Grenzen, die man kennen sollte {#limits-worth-knowing}

**Cloud-Speicher und Fair Use sind die eigenen Limits des Accounts.** zurg hebt
sie nicht an und umgeht sie auch nicht.

**8 gleichzeitige API-Anfragen.** Vier Volumes eines Multi-Volume-Archivs werden
gleichzeitig aufgelöst.

**Inhalte laufen ab.** Ein Release, das nicht mehr verfügbar ist, ist ein
erwartetes Ergebnis und kein Fehler. Repair lässt es in Ruhe, außer du bittest
ausdrücklich darum.

**Die Torrent-Liste enthält keine Dateidetails.** Jedes Release braucht beim
ersten Mal eine eigene Abfrage.

zurg ordnet die Fehlercodes des Dienstes dem zu, was als Nächstes passieren
sollte.

| Code von Premiumize | Was zurg macht |
|---|---|
| `authentication_failed` | Meldet einen ungültigen Zugang. Korrigiere den Key. |
| `rate_limit_reached` | Pausiert den Account für eine Minute. |
| `account_limit_reached` oder `service_limit_reached` | Meldet ein aufgebrauchtes Kontingent. |
| `service_down` | Behandelt den Account als vorübergehend nicht verfügbar. |
| `not_found` | Behandelt den Torrent als nicht mehr vorhanden. |

## Prüfen, ob es funktioniert hat {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/premiumize/test
ls /zurg_mnt/zurg/__all__/ | head
```

Bei nur einem Account wird dessen eigener Ordner aus der Root-Auflistung des Mounts weggelassen,
sodass der Mount dieselben Dateien unter `__all__` zeigt.

## Wenn es schiefgeht {#when-it-goes-wrong}

**Alles schlägt mit einem ungültigen Zugangsschlüssel fehl.** Erstelle den Schlüssel unter
[premiumize.me/account](https://www.premiumize.me/account) neu und aktualisiere den Eintrag.
Beachte, dass Premiumize bei einem fehlenden und einem falschen Schlüssel dieselbe Antwort gibt. Die
Meldung verrät dir nicht, welcher der beiden Fälle vorliegt.

**Eine Version lässt sich streamen, aber nicht reparieren.** Sie hat keinen gespeicherten Hash. Das heißt,
sie ist auf einem anderen Weg als über zurg in dein Konto gekommen. Siehe oben.

**Lesevorgänge pausieren jeweils eine Minute lang.** Das Rate Limit wurde erreicht, und zurg hat das Konto
absichtlich pausiert. Es macht danach von allein weiter.

**Erzeugte URLs funktionieren für jeden, der sie hat.** Delivery-URLs und der Zugriff über `.strm` solltest
du privat halten. Das Kontingent, das sie verbrauchen, ist das deines eigenen Kontos.
