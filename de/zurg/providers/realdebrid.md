# Real-Debrid

`type: realdebrid`

zurg hat als [Real-Debrid](http://real-debrid.com/?id=20476302)-Server angefangen und kennt Real-Debrid immer noch am besten. Es ist das einzige Backend mit Dateiauswahl pro Datei, einer separaten `__downloads__`-Liste, CDN-Host-Auswahl und einem eigenen `.strm`-Token.

## API-Token holen {#get-the-api-token}

Melde dich an und öffne [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354).
Der Token ist eine lange Hex-Zeichenfolge. Kopiere die ganze Zeichenfolge.

!!!warning Schalte zuerst das automatische Remote Traffic aus
Stelle auf deiner [Kontoseite](http://real-debrid.com/?id=20476410) sicher, dass **Use my
Remote Traffic automatically when needed** nicht angehakt ist. Ist sie aktiv, verbraucht
dein Remote-Traffic-Kontingent beim normalen Streaming, ohne dass du etwas davon merkst.
!!!

## Konfigurieren {#configure-it}

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/zurg_mnt/zurg"
```

Bei einer frischen Container-Installation lässt du das einfach vom Setup für dich schreiben.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider realdebrid
```

Bei einer Installation, die bereits eine `config.yml` hat, nutzt du das Dashboard unter `http://localhost:9999/config/` oder bearbeitest die Datei. Danach neu starten.

```bash
docker compose restart zurg
```

### Der einzige Anbieter, den ein Container aus der Umgebung vorbefüllen kann {#the-one-provider-a-container-can-seed-from-the-environment}

Real-Debrid ist das einzige Konto, für das der laufende Daemon selbst eine Konfiguration anlegt. `TOKEN` oder `RD_TOKEN` im `environment:`-Block deiner Compose-Datei befüllt `config.yml` bei dem Durchlauf, der die Datei erstellt. `MOUNT_PATH` befüllt den Mount.

```yaml
    environment:
      - TOKEN=YOUR_RD_API_TOKEN
      - MOUNT_PATH=/zurg_mnt/zurg
```

Beide werden **nur** beim ersten Start gelesen. Sobald die Datei existiert, ist sie die einzige Quelle der Wahrheit. Eine veraltete Variable kann einen Mount-Pfad, den du im Dashboard gesetzt hast, niemals stillschweigend überschreiben. Beim Start gibt es eine Warnung, wenn ein `MOUNT_PATH` aus diesem Grund ignoriert wird.

## Zusätzliche Schlüssel, die dieses Backend verwendet {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: realdebrid
    token: PRIMARY_RD_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
    download_tokens:
      - SECOND_RD_TOKEN
      - THIRD_RD_TOKEN
```

`download_tokens` sind Backup-API-Tokens für denselben Dienst. Sie springen ein, wenn das Bandbreitenkontingent des aktiven Tokens aufgebraucht ist. Sie nutzen den Katalog dieses Eintrags, und ihre eigenen Torrent-Bibliotheken werden nie importiert.

`strm_link_token` löst die Lesezugriffe auf `/strm/` auf, damit ein Player, der eine `.strm`-Datei öffnet, nicht das Token belastet, mit dem dein Live-Mount gerade streamt. Ist es nicht gesetzt, greift es auf `token` zurück.

Beides lohnt sich hier, weil Real-Debrid eines der beiden Backends ist, die überhaupt Zugangsdaten rotieren.

## Was Real-Debrid anders macht als die anderen {#what-real-debrid-does-that-the-others-do-not}

- **Auswahl pro Datei.** Beim Hinzufügen einer Veröffentlichung kann nur ein Teil davon geladen werden. Deshalb hat `force_select_playable_files` etwas, woran es ansetzen kann, und die Reparatur kann sich auf die defekten Dateien beschränken, statt die ganze Veröffentlichung erneut hinzuzufügen.
- **Eine zweite Liste namens downloads.** `__downloads__` im Mount-Root ist die Liste der Unrestricted-Links, die es nur bei Real-Debrid gibt. Sie in Bulk zu leeren braucht ein Web-Session-Cookie. Deshalb ist der Dashboard-Button der einzige Weg. Eine Installation ohne Real-Debrid-Konto bekommt eine entsprechende Meldung statt einer falschen Erfolgsmeldung.
- **Auswahl des CDN-Hosts.** `rd_cdn_host_preference` wählt zwischen Real-Debrids eigener Wahl, seinen Cloudflare-Pendants und einem bestimmten Land. Siehe [CDN und Host-Auswahl](../reference/config.md#cdn--host-selection).
- **Reparatur.** Ein Real-Debrid-Link, der zu einer Datei gespeichert ist, kann aufhören zu funktionieren, während der Torrent weiterhin als gesund gemeldet wird. Genau deshalb hat zurg ein Reparatur-Subsystem, und es ist das einzige Backend, das es braucht.

## Grenzen, die man kennen sollte {#limits-worth-knowing}

**Zwei Adds auf einem Account brauchen 20 Sekunden Abstand.** Gemessen an der
live API am 2026-08-17. Sechs saubere Release-Namen, im Abstand von zehn Sekunden
hinzugefügt, wurden sechsmal von sechs abgelehnt. Dieselben sechs mit zwanzig
Sekunden Abstand wurden sechsmal von sechs akzeptiert. zurg verteilt seine eigenen
Adds so, dass dieser Mindestabstand eingehalten wird.

**Ein abgelehnter Add sieht genau so aus wie ein blockierter Dateiname.** Real-Debrid
antwortet in beiden Fällen mit `451 infringing_file`. Das Throttling hat außerdem
ein Gedächtnis. Einmal ausgelöst, lehnt es noch minutenlang Anfragen ab, obwohl
nichts mehr los ist. Bei einem Reparatur-Durchlauf im Produktivbetrieb verging
deshalb vier Stunden lang kein einziger Add, weil zu Beginn drei Adds innerhalb
von dreizehn Sekunden aufeinander folgten.

**Manche Releases werden schon wegen ihres Namens abgelehnt.** Seit dem 14. Oktober
2026 sind das elf Zeichenfolgen. WEB-DL, WEB.x264 und WEB.H264 zählen nur in genau
dieser Schreibweise, sodass web-dl, Web-Dl und das WEB.h264 der Scene durchgehen.
WEBRip, BDRip, HDRip, DVDRip, HDTV.x264, HDTV.XviD, BluRay.x264 und p.BluRay.DTS
zählen in jeder Schreibweise. Bei dem letzten muss direkt davor ein p stehen, wie
in 1080p.BluRay.DTS. Ein 2002.BluRay.DTS-Release ist in Ordnung. Nur der genaue
Trenner zählt. WEB.DL, WEB-x264 und BluRay-x264 gehen alle durch. Ein Release, das
einen dieser Namen trägt, wird bei der ersten Anfrage jedes Mal abgelehnt, egal
was dahintersteckt. Eine Datei innerhalb eines Releases, dessen eigener Name passt,
wird zwar akzeptiert, lässt sich aber nicht streamen. zurg kennt die Muster und
verwirft solche Grabs lokal, statt einen Add-Slot und zwei Wiederholungen mit je
60 Sekunden Wartezeit für einen sicheren Fehlschlag zu verbrauchen.

**Eine zweite Kopie von Inhalten, die der Account schon hat, wird nie heruntergeladen.**
Real-Debrid nimmt den Add an und holt danach nichts dafür. Die Instanz bleibt dauerhaft
bei 0 Prozent mit 0 Seedern stehen.

**Die Torrent-Liste enthält keine Dateidetails.** Für jeden Torrent ist ein eigener
Info-Aufruf nötig. Deshalb legt zurg einen Info-Cache auf der Festplatte an. Ein
erster Scan einer großen Bibliothek ist der teure Fall, und der Cache sorgt dafür,
dass dieser Aufwand nicht immer wieder anfällt.

Drei Schlüssel steuern die API-Taktung, und die Standardwerte passen für einen
gewöhnlichen Account.

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

## Prüfen, ob es funktioniert hat {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/realdebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

Bei nur einem Account wird dessen eigener Ordner aus der Root-Ansicht des Mounts ausgelassen,
daher zeigt der Mount dieselben Dateien unter `__all__` an.

## Wenn es schiefgeht {#when-it-goes-wrong}

**`RD Permission denied` im Log.** Der Schlüssel wurde widerrufen oder ersetzt. Hol dir einen neuen unter [real-debrid.com/apitoken](http://real-debrid.com/?id=20476302) und aktualisiere den Eintrag im Dashboard oder in `config.yml`.

**Jeder Abruf kommt mit 451 zurück.** Entweder ist der Release-Name einer, den Real-Debrid komplett ablehnt, oder die Hinzufügungen kamen zu dicht hintereinander und die Drosselung greift noch. Das legt sich durch Ruhe und nicht durch Wiederholungsversuche.

**Beim ersten Start zeigt der Mount nichts an.** Eine große Bibliothek braucht eine Weile zum Laden. `/dav/movies/` antwortet mit 503, bis sie fertig geladen ist.

**Links bestehen die Prüfung und liefern danach nichts aus.** Aktiviere `use_range_verification`, damit zurg mit einem ranged GET über ein Byte prüft statt mit einem `HEAD`. Manche Netzwerke und manche Real-Debrid-Server beantworten ein `HEAD` falsch.
