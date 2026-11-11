# TorBox gehostetes Usenet {#torbox-hosted-usenet}

`type: torbox_nzb`

Mit einem TorBox-Pro-Tarif übernimmt TorBox den Usenet-Teil für dich. zurg schickt die `.nzb`-Dateien aus seinem Watch-Verzeichnis an dein TorBox-Konto. TorBox holt jedes Release, repariert es und liefert es wie jeden anderen TorBox-Download aus. zurg zeigt das, was TorBox geholt hat, im Mount neben allem anderen. Du brauchst kein News-Server-Konto, und auf deinem Rechner werden keine Usenet-Artikel dekodiert.

Das hier ist nicht [der News-Server von TorBox](torbox-news-server.md). Das ist ein Login für das `nzb`-Backend, das die Artikel selbst liest und auf [Usenet](usenet.md) beschrieben wird. Es ist auch kein `torbox`-Eintrag. Der listet deine Torrents auf, und die Seite [TorBox](torbox.md) erklärt ihn.

## Was du brauchst {#what-you-need}

- **Ein TorBox Pro-Abo.** Ein niedrigerer Tarif nimmt keine NZBs an.
- **Dein TorBox-API-Key** von [torbox.app/settings](https://torbox.app/settings).
  Es ist derselbe Key, den ein `torbox`-Eintrag verwendet.
- **Eine aktuelle zurg-Nightly.** Nightlies setzen eine aktive Sponsoring-Mitgliedschaft voraus.
- **Ein normaler Host.** zurg+rex Android, ein Plex-Server auf deinem Handy, hat kein `torbox_nzb`-Backend. Auf einem Android-Gerät spielst du TorBox-gehostete NZBs stattdessen über DMMs TorBox Cast oder das Kodi-Addon ab.

## Konfigurieren {#configure-it}

Der Eintrag nimmt einen `token` entgegen; es gibt keinen `nntp`-Block. `watchlist` kann dafür nicht gesetzt werden, weil ein NZB-Konto keine Torrents hinzufügen kann.

```yaml
providers:
  - type: torbox_nzb
    token: YOUR_TORBOX_API_KEY
```

Bei einer frischen Container-Installation speicherst du zuerst deinen Schlüssel in `~/zurg/secrets/torbox` und lässt dann das Setup ihn einlesen.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox_nzb \
  --torbox-token-file /config/secrets/torbox
```

Bei einer Installation, die bereits eine `config.yml` hat, kannst du auch **Add provider** im Dashboard unter `http://localhost:9999/config/` verwenden und `torbox_nzb` auswählen. Starte zurg in beiden Fällen neu.

```bash
docker compose restart zurg
```

## So kommen NZBs rein {#how-nzbs-get-in}

Alles, was in einem `nzb`-Eintrag ankommt, läuft bei diesem hier auf die gleiche Weise ab. DMMs TorBox-Aktion ist der einzige Weg, der zurg umgeht.

- **Der Watch-Ordner.** Lege eine Datei in `nzbs/` neben der Konfiguration ab (`~/zurg/nzbs/` auf dem Host, `/config/nzbs/` im Container). zurg schickt sie an TorBox.
- **Sonarr und Radarr** über den SABnzbd-kompatiblen Endpunkt von zurg. Siehe [Sonarr and Radarr for Usenet](../guides/sonarr-radarr.md).
- **Acquisition.** Newznab-Indexer, DMM Wanted und Watchlists laden darüber herunter. Siehe [Acquisition](../guides/acquisition.md).
- **DMMs TorBox-Aktion** bei einem Usenet-Ergebnis schickt die NZB direkt an TorBox. Die Release-Liste erscheint auch in zurg, aber zurg hat dafür keine NZB gespeichert. Deshalb kann der Reparatur-Button sie nicht erneut holen, sobald TorBox sie verwirft.

Ein Post, den TorBox nicht abrufen kann, wird an Sonarr oder Radarr als fehlgeschlagener Download gemeldet. Der Client setzt das Release auf die Blockliste und sucht erneut.

## Was sich von `nzb` unterscheidet {#what-differs-from-nzb}

Hier ist die Übersetzung ins Deutsche:

- **Kein News-Account.** Es gibt kein Verbindungskontingent, das man festlegen müsste, und keine Aufbewahrungszeit der Provider, die man abwägen müsste. Der eigene Spool von TorBox entscheidet, woraus ein Post geladen werden kann.
- **Hier werden keine Artikel dekodiert.** TorBox lädt das gesamte Release. Artikel-Download, PAR2-Reparatur, der Artikel-Cache und Artikelprüfungen entfallen; der Disk-Cache für dekodierte Archive gilt weiterhin. Ein Grab gilt als fertig, sobald TorBox es geladen hat.
- **Ein 30-Tage-Cache.** Ein Release, das ein anderer bereits auf TorBox geladen hat, ist sofort verfügbar. TorBox entfernt ein Release 30 Tage nachdem es TorBox gecacht hat. Der Reparatur-Button im Dashboard lädt es erneut, indem er seine NZB noch einmal postet. Lass die Dateien deshalb in `nzbs/`. zurg postet nie von selbst erneut, da TorBox unbeaufsichtigte erneute Downloads als Missbrauch wertet.
- **Ein Slot pro NZB in Bearbeitung.** Ein Post, den TorBox noch lädt, belegt einen deiner aktiven Slots deines Tarifs. Ein `torbox`-Eintrag mit demselben Key nutzt für seine Torrents dieselben Slots.
- **60 Posts pro Stunde.** TorBox nimmt pro Key so viele neue NZBs pro Stunde an. Ein großer Rückstand, etwa ein volles `nzbs/` beim ersten Start, wird erst über Stunden abgearbeitet.

## Ein NZB-Konto pro Instanz {#one-nzb-account-per-instance}

Eine Instanz nimmt entweder einen `nzb`-Eintrag oder einen `torbox_nzb`-Eintrag, niemals beide. Beide würden jede Datei in `nzbs/` auflisten. Um beide zu betreiben, gib der anderen Art eine eigene Instanz mit eigenem Arbeitsverzeichnis. Mit `dmm_api_key` bei beiden [schaltest du die `dmm-wanted`-Quelle bei einer davon aus](../guides/dmm-wanted.md#two-zurgs-on-one-key), sonst wird jeder Wanted-Titel doppelt abgerufen. Beide können neben deinen Debrid-Konten laufen.

Das Stremio-Addon von zurg schickt seine Auswahl an das NZB-Konto, das die Instanz hat. Bei `torbox_nzb` startet eine Version, die TorBox bereits vorliegen hat, innerhalb der Wartezeit des Addons, solange kein anderer NZB-Post wartet. Eine nicht gecachte Version muss zuerst bei TorBox fertig werden, und das dauert länger, als ein Player wartet.

## Prüfen, ob es funktioniert hat {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox_nzb/test
ls /zurg_mnt/zurg/__all__/
curl -s http://localhost:9999/http/__torbox_nzb__/ | head
```

Bei nur einem Account wird dessen eigener Ordner aus der Root-Auflistung des Mounts weggelassen, sodass der Mount dieselben Dateien unter `__all__` zeigt. Der Verzeichnisname richtet sich nach dem Namen des Eintrags, der standardmäßig seinem Typ entspricht.
