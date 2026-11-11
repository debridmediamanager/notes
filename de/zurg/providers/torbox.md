# TorBox

`type: torbox`

[TorBox](https://torbox.app/subscription?referral=74ffa560-7381-4a18-adb1-cef97378c670) ist die günstigste Bibliothek für zurg zum Synchronisieren und lässt sich beim Lesen am leichtesten drosseln. Seine Torrent-Liste enthält bereits alle Dateien. Eine Bibliotheksaktualisierung kostet eine einzige Anfrage statt einer pro Torrent. Sein Endpunkt zur Linkauflösung ist ein festes Kontingent und keine Rate. zurg geht damit bewusst vorsichtig um.

## API-Schlüssel holen {#get-the-api-key}

Melde dich an und öffne [torbox.app/settings](https://torbox.app/settings). Der API-Key
steht auf dieser Seite.

**Ein kostenloses Konto funktioniert nicht mit zurg.** TorBox beantwortet jede Bibliotheksanfrage mit einem kostenlosen Key mit `PLAN_RESTRICTED_FEATURE`, deshalb kann zurg nicht lesen, was auf dem Konto liegt. Nutze einen bezahlten Tarif. Ein bezahlter Tarif, der ausläuft, wird genauso zu einem kostenlosen.

## Konfigurieren {#configure-it}

```yaml
zurg: v1
providers:
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Bei einer frischen Container-Installation lässt du das Setup es schreiben.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox
```

Wenn schon eine `config.yml` vorhanden ist, nutze im Dashboard unter `http://localhost:9999/config/` den Button **Add provider** oder bearbeite die Datei. In beiden Fällen musst du danach neu starten.

```bash
docker compose restart zurg
```

!!!warning Ein TorBox-Key in deiner Compose-Umgebung bringt allein nichts
`TORBOX_TOKEN` wird von `zurg setup` gelesen und nicht vom laufenden Daemon. Nur Real-Debrids `TOKEN` legt beim ersten Start eine Config an. Gib den Key an einen Setup-Container weiter oder füge den Account im Dashboard hinzu.
!!!

Für eine unbeaufsichtigte Installation gib dem Setup eine Datei an statt einer Umgebungsvariable.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

## Zwei Schlüssel, die hier nicht gelten {#two-keys-that-do-not-apply-here}

`download_tokens` wird akzeptiert, funktioniert auf Real-Debrid aber nicht so, wie es soll.
Ein Wechsel zu einem zweiten Key ordnet die Torrent- und Datei-IDs nicht neu zu. Bei TorBox gehören diese IDs dem Konto, das sie aufgelistet hat. Ein zweites TorBox-Konto braucht einen eigenen Eintrag mit eigenem `name`.

```yaml
providers:
  - type: torbox
    name: tb-main
    token: FIRST_TORBOX_API_KEY
  - type: torbox
    name: tb-second
    token: SECOND_TORBOX_API_KEY
```

`strm_link_token` wird akzeptiert, aber nicht verwendet. TorBox erzeugt bei jeder Anfrage eine neue Download-URL. Es gibt keine langlebige Zugangsdaten, an die eine `.strm`-Datei sich binden könnte.

## Aktive Slots sind die eigentliche Grenze {#active-slots-are-the-real-ceiling}

TorBox' wichtigste Einschränkung ist, wie viele Torrents gleichzeitig herunterladen oder seeden dürfen. Bei Real-Debrid ist es die Bandbreite. Bei TorBox sind es die Slots.

| Plan | Aktive Slots |
|---|---|
| Free | 1, aber zurg kann keinen Free-Key nutzen (siehe oben) |
| Essential | 3 |
| Standard | 5 |
| Pro | 10 |

zurg liest den Plan aus dem Account aus und richtet das Hinzufügen weiterer Torrents danach aus. Bei einem Account, dessen Plan zurg nicht auslesen kann, wird mit 3 Slots gerechnet.

Alles andere, das Torrents hinzufügt, rechnest du gegen dasselbe Budget. Sonarr und Radarr, die über den qBittorrent-Endpunkt greifen, ein Reparatur-Durchlauf und eine Watchlist belegen alle dieselben Slots.

## Grenzen, die man kennen sollte {#limits-worth-knowing}

**Die Link-Auflösung ist ein Budget von etwa hundert Aufrufen und keine Rate.**
Gemessen am 30.08.2026. Eine 429 mit `Retry-After: 300` kam bei kumulativem Aufruf 100, als die Aufrufe so schnell wie möglich abgesetzt wurden. Sie kam bei Aufruf 94, als sie auf einen pro Sekunde gedrosselt waren. Die Sperre gilt für das ganze Konto. Sie blockiert den gesamten Mount für fünf Minuten und nicht nur den Lesevorgang, der sie ausgelöst hat.

Daraus folgen zwei Dinge, und zurg erledigt beides von selbst.

- Es wird nie eine Datei aufgelöst, nach der niemand gefragt hat. Jedes andere Backend bekommt einen Vorsprung auf die nächste Episode. TorBox kann sich das Raten nicht leisten, weil ein Media-Server beim Analysieren einer Bibliothek jede Datei genau einmal öffnet, und jeder dieser Zugriffe ist ein Kaltstart.
- Die Volumes eines Multi-Volume-Archivs werden strikt nacheinander aufgelöst. Schneller zu sein würde das Limit ein Vielfaches verbrauchen und die Volumes hinter einem kaputten erst kaufen, bevor jemand bemerkt, dass sie nicht gebraucht werden.

**60 nicht gecachte Adds pro Stunde.** Gecachte Adds fallen stattdessen unter das Minuten-Budget.

**300 Anfragen pro Minute über alle Endpunkte für einen Key.** zurg drosselt sich auf 300 minus 60, damit die Wiederholungen, die der HTTP-Client selbst macht, einen budgetierten Schwall nicht über die echte Obergrenze drücken.

**Die 21. Verbindung zu einem CDN-Host bekommt eine 429.** Gemessen am 23.08.2026, indem alle 500 ms eine Verbindung geöffnet und gehalten wurde. Das Limit gilt pro Host und nicht pro Key. Verteilt man Lesezugriffe auf die Flotte von TorBox, umgeht man es; häuft man sie alle auf einem Knoten, nicht. zurg stellt ab der 20. Verbindung in eine Warteschlange, statt neue aufzubauen. So wird die Ablehnung zu einer kurzen lokalen Wartezeit.

**Inhalte werden nach dem Aufbewahrungszeitraum des Tarifs entfernt.** Ein Torrent, der verschwunden ist, ist erwartet und nicht kaputt. Repair lässt ihn in Ruhe, außer du fragst gezielt danach.

**Es gibt keine Auswahl einzelner Dateien.** Ein Add holt den gesamten Torrent, und Repair fügt das Release komplett wieder hinzu.

Das vollständige Bild mit Quellen findest du unter [TorBox-Limits](torbox-limits.md).

## Eine CDN-Region auswählen {#choosing-a-cdn-region}

```yaml
tb_cdn_host_preference: "auto"
```

`auto` lässt TorBox seine eigene Wahl unverändert. `force_location_<region>` liefert Downloads aus dieser Region. Nur Regionen, die gerade einen Delivery-Node anbieten, lassen sich erzwingen, und die Auswahlliste im Dashboard zeigt genau diese an. Greif hier nicht zu `cdn_host_preference`. Dieser Schlüssel gilt nur für Real-Debrid, und seine Werte sind Real-Debrid-Standortcodes.

## Prüfen, ob es funktioniert hat {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
ls /zurg_mnt/zurg/__all__/ | head
```

Bei nur einem Account wird dessen eigener Ordner aus der Root-Ansicht des Mounts ausgelassen,
daher zeigt der Mount dieselben Dateien unter `__all__`.

## Wenn es schiefgeht {#when-it-goes-wrong}

**Das Log zeigt `Account <name> refused zurg` oder wiederholt `TorBox rejected the API key`.**
Der Plan ist abgelaufen, und der Schlüssel läuft jetzt im kostenlosen Plan. Ab Nightly 2026.10.11.2240
lädt zurg deine anderen Accounts ohne diesen. Die Karte des Accounts auf dem Dashboard
zeigt `Refused: the account's plan does not include API access`. Seine Releases bleiben
aufgelistet, lassen sich aber nicht abspielen, und wegen des Problems wird nichts gelöscht oder in den Papierkorb verschoben.
zurg fragt TorBox alle 10 Minuten erneut an und nimmt den Account wieder auf, sobald der Plan bezahlt ist.
Auf älteren Nightlies wurde die gesamte Bibliothek nie fertig geladen, sodass auch Inhalte aus deinen anderen Accounts nicht mehr angezeigt wurden.
Aktualisiere zurg oder verlängere den Plan. Auch möglich: den `torbox`-Provider in `config.yml` auskommentieren und zurg neu starten.

**Die Wiedergabe stoppt jeweils für fünf Minuten.** Das requestdl-Kontingent ist aufgebraucht, und der 429-Fehler gilt für den gesamten Account. Irgendetwas löst mehr Links auf, als nötig wären.
Der übliche Auslöser ist ein Medienserver, der das gesamte Mount auf einmal scannt. Richte ihn auf ein einzelnes Verzeichnis statt auf alle.

**Neue Grabs werden nicht mehr angenommen.** Entweder sind alle aktiven Slots belegt, oder das stündliche Limit für Hinzufügungen ist aufgebraucht. Beides löst sich von selbst, und erneutes Versuchen hilft nicht.

**Ein Release listet weniger Dateien, als du erwartest.** `__torbox__` zeigt nur das, was TorBox tatsächlich vorhält. Hat ein anderer Account das Release vollständig, dann liefert der Rest des Mounts trotzdem alles aus.

**Ein Torrent ist verschwunden.** Aufbewahrung. Siehe oben. zurg fügt ihn nicht ohne dein Zutun wieder hinzu, weil die erneute Suche das Budget des Accounts ohne Gegenleistung verbrauchen würde.
