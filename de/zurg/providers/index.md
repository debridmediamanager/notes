# Anbieter {#providers}

Ein Provider ist ein Account, aus dem zurg seine Bibliothek aufbaut. Jeder Account ist ein Eintrag unter `providers:` in `config.yml`. Betreibe einen Account oder sechs. Ein Release, das bei mehr als einem davon liegt, wird nur einmal aufgeführt und von dem Account gelesen, der es gerade ausliefern kann.

| Dienst | `type` | Seite |
|---|---|---|
| Real-Debrid | `realdebrid` | [Real-Debrid](realdebrid.md) |
| TorBox | `torbox` | [TorBox](torbox.md) |
| AllDebrid | `alldebrid` | [AllDebrid](alldebrid.md) |
| Premiumize | `premiumize` | [Premiumize](premiumize.md) |
| Debrid-Link | `debridlink` | [Debrid-Link](debridlink.md) |
| Offcloud | `offcloud` | [Offcloud](offcloud.md) |
| Usenet | `nzb` | [Usenet](usenet.md) |
| TorBox hosted Usenet | `torbox_nzb` | [TorBox hosted Usenet](torbox-nzb.md) |

Drei Seiten gehen über die Einrichtung hinaus. [TorBox-Limits](torbox-limits.md) enthält die gemessenen Werte hinter der TorBox-Drosselung. [TorBox-Newsserver](torbox-news-server.md) und [ElfHosted-Newsserver](elfhosted-news-server.md) dokumentieren, was die Usenet-Accounts, die bei diesen Tarifen mitgeliefert werden, tatsächlich sind. Prüfe einen davon dort, bevor du einen Provider-Platz dafür belegst.

Jede Seite hier setzt die Container-Installation aus [Docker-Einrichtung](../setup/docker.md) voraus. `~/zurg` ist das Compose-Verzeichnis auf dem Host. `/config` ist dasselbe Verzeichnis, von innen im Container gesehen. Es gibt nur eine `config.yml`, und beide Namen führen zu ihr.

Bei einer Binär-Installation unter Linux, macOS oder Windows zeigt [Einrichtung](../setup/index.md), was an die Stelle von `docker compose restart zurg` und der `setup`-Zeile tritt. Die Prüfungen lassen sich genauso übertragen. Führe sie aus zurgs Ordner aus. Lies `logs/zurg.log` statt `docker compose logs` (in PowerShell: `Get-Content logs\zurg.log -Tail 100 -Wait`). Führe `./zurg doctor` (`.\zurg.exe doctor`) ohne `--working-dir /config` aus. Zeige dein eigenes Mount an statt `/zurg_mnt/zurg`: `/mnt/zurg`, `/Volumes/Zurg` oder `Z:\`, sofern du `mount_path` nicht geändert hast. Tippe in Windows PowerShell 5.1 `curl.exe` statt `curl`.

## Drei Wege, ein Konto hinzuzufügen {#three-ways-to-add-an-account}

Welche du nimmst, hängt davon ab, ob `config.yml` schon existiert.

### Bei einer frischen Installation das Setup verwenden {#on-a-fresh-install-use-setup}

`zurg setup` fragt, welche Anbieter du einrichten willst, und fragt dann nur nach deren Zugangsdaten. Die Accounts schreibt es **nur, wenn noch keine `config.yml` existiert**. Führst du es später erneut aus, aktualisiert es die Installation, ohne die Accounts anzurühren, die du schon hast.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

Die Auswahl akzeptiert Nummern oder Namen und nimmt auch mehrere auf einmal an.

```
Choose one or more providers in priority order:
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
Providers (comma-separated numbers or names): 2,4
```

Was du eintippst, landet weder in der Compose-Datei noch in deinem Shell-Verlauf. Der Token geht direkt in `config.yml`, und die Datei wird nur für den Besitzer lesbar geschrieben.

### Bei einer bestehenden Installation das Dashboard verwenden {#on-an-existing-install-use-the-dashboard}

Öffne `http://localhost:9999/config/` und klicke unter Essentials auf **Add provider**.
Wähle den Typ aus. Füge den Token ein. Speichere. Das Dashboard schreibt den Eintrag zurück in
dieselbe `config.yml` neben deiner Compose-Datei.

Änderungen an Providern brauchen einen Neustart, bevor sie wirken. Das Dashboard weist darauf hin,
und der Neustart ist ein einziger Befehl.

```bash
docker compose restart zurg
```

### Oder config.yml von Hand bearbeiten {#or-edit-configyml-by-hand}

Die Datei ist `~/zurg/config.yml` auf dem Host. Füg den Eintrag hinzu und starte neu.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

`mount_path` ist `/zurg_mnt/zurg` in einem Container, und die Compose-Datei muss `/zurg_mnt:/zurg_mnt:rshared` binden, damit das Mount auf dem Host ankommt. Das steht auf der [Docker-Setup](../setup/docker.md)-Seite, und genau das ist der Teil einer Container-Installation, der sich von einer Binary-Installation unterscheidet.

## Unbeaufsichtigte Installationen {#unattended-installs}

Jeder Provider hat ein Flag für die Token-Datei und eine Umgebungsvariable. Wiederhole `--provider` für jedes Konto, das du einbinden willst.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

| `type` | Flag | Umgebungsvariable |
|---|---|---|
| `realdebrid` | `--realdebrid-token-file` | `REALDEBRID_TOKEN` oder `TOKEN` oder `RD_TOKEN` |
| `torbox` | `--torbox-token-file` | `TORBOX_TOKEN` |
| `alldebrid` | `--alldebrid-token-file` | `ALLDEBRID_TOKEN` |
| `premiumize` | `--premiumize-token-file` | `PREMIUMIZE_TOKEN` |
| `debridlink` | `--debridlink-token-file` | `DEBRIDLINK_TOKEN` |
| `offcloud` | `--offcloud-token-file` | `OFFCLOUD_TOKEN` |
| `nzb` | `--nntp-password-file` mit `--nntp-host` und `--nntp-username` | `NNTP_HOST` und Co. |
| `torbox_nzb` | `--torbox-token-file` | `TORBOX_TOKEN` |

`torbox_nzb` wird nie allein aus `TORBOX_TOKEN` oder `--torbox-token-file` abgeleitet. Übergib es explizit mit `--provider torbox_nzb`.

Mit `--non-interactive` und ohne `--provider` nimmt das Setup alle diese Variablen, die gesetzt sind.

!!!warning Nur Real-Debrid wird vom laufenden Container angelegt
Der zurg-Daemon selbst liest `TOKEN`, `RD_TOKEN` und `MOUNT_PATH` bei dem Lauf, der `config.yml` erstellt. Mehr ist es nicht. `TORBOX_TOKEN` und die restlichen Variablen liest `zurg setup`. Wenn du eine davon in deinen `environment:`-Block der compose-Datei schreibst und den Container startest, passiert damit allein nichts. Führe das Setup aus oder füge das Konto im Dashboard hinzu.
!!!

## Was jeder Eintrag akzeptiert {#what-every-entry-accepts}

| Schlüssel | Was er macht |
|---|---|
| `type` | Pflichtfeld. Einer der acht oben genannten Typen. |
| `name` | Standardmäßig `type`. Unterscheidet zwei Konten beim selben Dienst. |
| `token` | Der API-Schlüssel. Wird von `nzb` nicht verwendet. |
| `disabled` | Deaktiviert das Konto, ohne die Zugangsdaten zu löschen. |
| `watchlist` | Markiert das Konto, bei dem neue Torrent-Hinzufügungen zuerst versucht werden. |
| `add_torrents` | Auf `false` gesetzt, liefert das Konto weiterhin Daten, bekommt aber nie etwas Neues zugewiesen. |
| `warm_connections` | Pro Host offen gehaltene Verbindungen, damit ein Lesevorgang nicht erst eine neue aufbauen muss. |

Vollständige Beschreibungen und alles Weitere finden sich in der
[Konfigurationsreferenz](../reference/config.md#accounts).

## Regeln, die der Loader durchsetzt {#rules-the-loader-enforces}

- Namen müssen eindeutig sein. Zwei Real-Debrid-Konten brauchen `name: rd-main` und `name: rd-backup`, sonst schlägt das Laden fehl.
- Der Name `e` ist für das Routing von `.strm`-Links reserviert. Wähle einen anderen.
- Höchstens ein Eintrag darf `watchlist: true` setzen.
- `watchlist: true` und `add_torrents: false` im selben Eintrag werden abgelehnt.
- Es wird nur ein aktivierter `nzb`- oder `torbox_nzb`-Eintrag unterstützt. Weitere News-Server gehören unter `nntp.servers` eines `nzb`-Eintrags.
- Wenn alle Einträge deaktiviert sind, schlägt das Laden fehl.
- Premiumize, Debrid-Link und Offcloud lehnen `download_tokens` und ein `strm_link_token`, das sich von `token` unterscheidet, ab. Ihre Datei-IDs gehören zu einem Konto, deshalb braucht ein zweites Konto einen zweiten Eintrag.

## Prüfen, ob es funktioniert hat {#check-it-worked}

Fang mit dem Log und der Diagnose an.

```bash
docker compose logs -f --tail=100 zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`WARN service zurg is not installed` ist in Docker erwartet, weil Compose den Autostart übernimmt. Warnungen lassen doctor nicht fehlschlagen. Ein `FAIL` schon.

Prüf dann den Account selbst, entweder im Dashboard oder in der Shell.

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
```

`{"success":true}` heißt, dass sich die Zugangsdaten erfolgreich authentifiziert haben. Der Name im Pfad ist das `name` des Accounts. Standardmäßig ist das sein `type`. Falls du in `config.yml` einen `username` gesetzt hast, füg `-u user:pass` hinzu. Ohne einen sind das Dashboard und seine API auf dem Port offen, den du veröffentlicht hast.

Zum Schluss schaust du dir die Bibliothek auf dem Mount an.

```bash
ls /zurg_mnt/zurg/__all__/
```

Jeder konfigurierte Account bekommt ein `__<name>__`-Verzeichnis. Es enthält alles, was dieser Account hat, und es legt Lesezugriffe auf genau diesen Account fest. `__torbox__/Some.Release/` streamt nur von TorBox und von nirgendwo anders. Der Ordner eines einzelnen Accounts fehlt in der Root-Auflistung des Mounts, weil `__all__` dieselbe Bibliothek ist. Direkte HTTP- und WebDAV-Pfade wie `/http/__torbox__/` antworten weiterhin. Über den Mount lösen sie sich nicht mehr auf. Stell jede Bibliothek oder jedes Skript, das `__<name>__` benutzt hat, stattdessen auf `__all__` um.

Eine große Bibliothek braucht beim ersten Laden eine Weile. Bis sie fertig ist, antwortet `/dav/movies/` mit 503, und der Mount zeigt möglicherweise gar nichts an.

## Mehrere Konten betreiben {#running-several-accounts}

Die Reihenfolge ist nur an einer Stelle wichtig. Die Reihenfolge der `providers:`-Liste bestimmt, in welcher Reihenfolge Accounts ausprobiert werden, die Adds annehmen. Ein Account mit `watchlist: true` wird immer zuerst probiert, egal wo er in der Liste steht. Beim Auflisten und Lesen hat die Reihenfolge keine besondere Bedeutung.

Zwei Dinge solltest du wissen, bevor du Plex oder Jellyfin auf das Ergebnis zeigen lässt.

- Dasselbe Release taucht in deinen gefilterten Verzeichnissen **und** in jedem `__<name>__`-Verzeichnis auf, das es enthält. Zeig Plex oder Jellyfin auf einen Teil des Mounts statt auf alles, sonst scannen sie denselben Inhalt mehrfach.
- Innerhalb eines `__<name>__`-Verzeichnisses gibt es kein stilles Failover. Eine Datei, die bei einem Account tot ist, liefert dort einen 404 und wird stattdessen unter dem Verzeichnis eines anderen Accounts abgespielt. Der Rest des Mounts liefert sie weiterhin normal aus.
