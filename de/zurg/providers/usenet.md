# Usenet

`type: nzb`

Usenet ist ein Provider-Typ, aber kein Debrid-Dienst. Es gibt kein API-Token und keine
Remote-Bibliothek. Du legst `.nzb`-Dateien in ein Watch-Verzeichnis, und zurg macht
daraus für jede Datei ein Release. Die Artikel werden von deinem News-Server geladen
und erst dann dekodiert, wenn ein Player diese Bytes anfordert.

Diese Seite behandelt nur den Provider-Eintrag und die Docker-Details. Alles andere
zum Betrieb von Usenet mit zurg steht in [Usenet mit zurg](../guides/usenet.md).
Das ist die komplette Schritt-für-Schritt-Anleitung mit News-Accounts, NZBs, dem Mount
und Plex. Lies sie als Zweites.

## Konfigurieren {#configure-it}

Es gibt kein `token`. Ein `nntp`-Block mit einem Host macht den Eintrag gültig.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
mount_path: "/zurg_mnt/zurg"
```

Setze `connections` auf das, was dein Tarif tatsächlich erlaubt. zurg liest mit dieser Anzahl,
weil eine einzelne Verbindung nur einen Bruchteil des Durchsatzes eines Tarifs schafft.
Streaming nutzt das volle Kontingent aus, statt Artikel nacheinander zu holen. Wer mehr
als das erlaubte Maximum nutzt, bekommt Verbindungen verweigert.

Bei einer frischen Container-Installation fragt das Setup nach allem.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb
```

Für eine unbeaufsichtigte Installation kommt das Passwort aus einer Datei, alles andere
kommt aus Flags.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb \
  --nntp-host news.example.com \
  --nntp-username YOUR_USENET_USERNAME \
  --nntp-password-file /config/secrets/nntp \
  --nntp-connections 8
```

`--nntp-tls` ist standardmäßig true, und `--nntp-port` ist standardmäßig 563 mit TLS bzw. 119
ohne.

Wenn schon eine `config.yml` vorhanden ist, nutze **Add provider** im Dashboard unter
`http://localhost:9999/config/` oder bearbeite die Datei. In beiden Fällen danach neu starten.

```bash
docker compose restart zurg
```

## Wohin die NZBs im Container kommen {#where-the-nzbs-go-in-a-container}

Das Watch-Verzeichnis ist `nzbs/` neben der Konfiguration. Auf dem Host ist das `~/zurg/nzbs/`, im Container `/config/nzbs/`. Es ist dasselbe Verzeichnis. Leg die Dateien vom Host aus hinein.

```bash
mkdir -p ~/zurg/nzbs
cp /path/to/some.nzb ~/zurg/nzbs/
ls /zurg_mnt/zurg/__all__/
```

Wenn du nur einen Account hast, wird dessen eigener `__nzb__`-Ordner nicht in der Root-Auflistung des Mounts angezeigt. Schau deshalb unter `__all__` nach. Das Watch-Verzeichnis wird etwa alle 15 Sekunden eingelesen. Da es innerhalb des `./:/config`-Bind-Mounts liegt, bleibt es bei einem `docker compose pull` und beim Neuerstellen des Containers erhalten, genau wie alles andere.

## Regeln speziell für diesen Typ {#rules-specific-to-this-type}

- **Nur ein aktivierter `nzb`-Eintrag.** Zwei würden dasselbe Verzeichnis scannen und jede Veröffentlichung doppelt anlegen. Weitere News-Server gehören unter `nntp.servers` in genau diesen einen Eintrag. Dort bedienen sie dieselbe Bibliothek, statt eine zweite Kopie davon anzulegen. Ein `nzb`-Eintrag neben einem [`torbox_nzb`](torbox-nzb.md)-Eintrag wird aus demselben Grund abgelehnt.
- **`watchlist: true` wird abgelehnt.** Ein News-Server bekommt nie einen Torrent.
- **`add_torrents` wird ignoriert.** Beim Start gibt es dazu eine Warnung, aus demselben Grund.
- **`download_tokens` und `strm_link_token` haben keine Wirkung.** Es gibt kein Zugangsdatum, das du rotieren müsstest.
- **Das Verzeichnis heißt `__nzb__`,** weil der Name standardmäßig dem Typ entspricht. Setze `name: usenet` im Eintrag, wenn du lieber `__usenet__` durchsuchen möchtest.

## Ein zweiter News-Server bringt mehr, als es aussieht {#a-second-news-server-is-worth-more-than-it-looks}

Retention gilt pro Anbieter. Ein Artikel, den ein Server schon hat verfallen lassen, ist sehr oft
noch auf einem anderen vorhanden. Ohne zweiten Account bleibt für einen toten Artikel nur PAR2, und dafür muss das **komplette Release** einmal gelesen werden. Ein zweiter Server ist also der Unterschied zwischen dem Holen eines einzelnen Artikels und dem erneuten Lesen von allem.

Zusätzliche Accounts kommen unter diesen Eintrag bei `nntp.servers`, nicht in einen zweiten `nzb`-Eintrag. `priority`, `backup` und `backbone` bestimmen, wer angefragt wird und in welcher Reihenfolge. Lesevorgänge laufen mit dem zusammengerechneten Kontingent aller Accounts, die nicht als `backup` markiert sind. Die Beispielkonfiguration und was jeder Schlüssel bringt, steht in [Usenet mit zurg](../guides/usenet.md#more-than-one-usenet-provider).

## Prüfen, ob es funktioniert hat {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/nzb/test
docker compose logs --tail=100 zurg
ls /zurg_mnt/zurg/__all__/
```

Mit nur einem Account wird dessen eigener Ordner in der Root-Auflistung des Mounts weggelassen, daher zeigt der Mount dieselben Dateien unter `__all__` an.

Die Prüfung hier meldet sich am News-Server an und verwendet dafür höchstens eine Verbindung aus dem bestehenden Pool. Eine Account-API, über die man das abfragen könnte, gibt es nicht.

## Wenn es schiefgeht {#when-it-goes-wrong}

Zwei Symptome betreffen den Provider-Eintrag selbst und nicht die Bibliothek.

**Lesefehler, und zurg fällt auf jeweils einen Artikel zurück.** `pipeline_depth` ist höher, als der Server verträgt. zurg reduziert den Wert selbst und gibt eine Warnung aus. Setze ihn für einen Server, der nicht mehrere Befehle gleichzeitig verarbeiten kann, explizit auf `1`.

**Der Durchsatz ist auf einer Verbindung mit hoher Latenz schlecht.** Lass `socket_receive_buffer_kb` ungesetzt. Ein fester Puffer ist einer, den der Kernel nicht mehr anpasst. Unter Linux hält er das Empfangsfenster bei etwa 64 KiB und kostet dir den größten Teil des Durchsatzes deines Accounts.

Alles andere steht in der Tabelle zur Fehlerbehebung unter [Usenet mit zurg](../guides/usenet.md#troubleshooting). Abgelehnte Verbindungen, langsames Streaming, ein Provider, der nie angefragt wird, und eine Änderung im Dashboard, die `nntp.servers` entfernt hat, sind dort alle aufgeführt.
