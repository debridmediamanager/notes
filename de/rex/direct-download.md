# Apps laden von deinem Anbieter herunter {#apps-download-from-your-provider}

Normalerweise liest rex jeden Film von deiner Quelle und gibt ihn an Plex weiter. Wenn die Quelle stattdessen einen Dateilink liefert, zum Beispiel einen Debrid-Download-Link, kann rex diesen direkt an Plex übergeben. Plex lädt die Datei dann selbst herunter, und auf der rex-Maschine liegen keine Medien.

Das funktioniert, wenn Plex die Datei direkt abspielen kann (direct play). Alles, was rex erst umwandeln muss, läuft weiterhin über rex oder wird abgelehnt, wenn du das so einstellst.

Getestet am 2026-10-25 mit zurg auf Real-Debrid, Plezy und Plex for Android auf einem Pixel 6 sowie Plex Web in Chrome.

## Bevor du anfängst {#before-you-start}

Behalte den Standard-Proxy-Modus für geteilte Debrid-Wiedergabe. Weiterleitungen sind keine sichere Methode, um ein Debrid-Konto zu teilen:

- **Real-Debrid verfolgt die öffentliche IP jedes Downloaders.** Die Nutzung eines Kontos über mehrere IPs führt zu einer Warnung wegen Kontoteilung, selbst wenn das CDN die Datei problemlos ausliefert. Halte jede Nutzung dieses Kontos auf einer öffentlichen IP. Wenn eine Remote-App direkt herunterlädt, während rex oder seine Quelle von der IP des Servers aus prüft oder konvertiert, verstößt das gegen diese Regel. Eine erfolgreiche Wiedergabe beweist nicht, dass alles sicher ist.
- **TorBox-Download-URLs enthalten den vollständigen API-Schlüssel in `?token=`.** Bei einer Weiterleitung hätte jeder Client und jedes geteilte Benutzerkonto Zugriff darauf, auch zum Löschen, nicht nur auf die einzelne Datei. Player-Logs und der Browserverlauf können den Schlüssel speichern. Gib diese Links nicht an nicht vertrauenswürdige Clients weiter.

Fahre nur fort, wenn du diese Risiken in Kauf nehmen kannst. Mit dem Standard-Proxy-Modus von rex folgt rex den Weiterleitungen der Quelle selbst, anstatt der App den Link des Providers zu übergeben.

| Du brauchst | Warum |
|---|---|
| rex eingerichtet wie in [rex mit deiner eigenen App](any-source.md), [rex mit deinen Stremio-Addons](stremio.md) oder [rex mit zurg](with-zurg.md), und einen Film, der abspielt | Diese Seite ändert den Startbefehl von rex und bei manchen Quellen eine Einstellung der Quelle |
| rex-Nightly **2026.10.26 oder neuer** | Ältere Builds haben diese Einstellung nicht. Aktualisiere wie im Abschnitt [Updating](any-source.md#updating) von rex |
| Eine Quelle, die mit einem Link antworten kann | rex kann nur einen Link weitergeben, den die Quelle ihm gibt. [Schritt 1](#step-1-let-your-source-hand-out-links) sagt, welche Quellen das können |

## Wähle, wie streng {#choose-how-strict}

| | `redirect` | `redirect-only` |
|---|---|---|
| Eine App spielt die Datei so ab, wie sie ist | Die App lädt von deinem Anbieter herunter | Die App lädt von deinem Anbieter herunter |
| Eine App braucht die Datei konvertiert (eine niedrigere Qualität, Audio, das sie nicht abspielen kann, eingebrannte Untertitel) | rex konvertiert sie und liest die Datei wie bisher von deiner Quelle | Abgelehnt: Die App zeigt einen Fehler an |
| Dateien, die deine Quelle selbst schickt und nicht als Link (zum Beispiel zurgs Usenet-Dateien) | Wie bisher über rex abspielen | Abgelehnt |
| Plex Web | Spielt, über rex | Jede Real-Debrid-Datei wird abgelehnt (siehe unten) |

Wähl `redirect`, wenn alles weiter abspielen soll und du trotzdem Bandbreite sparen willst. Wähl `redirect-only`, wenn die rex-Maschine niemals einen Film transportieren darf, zum Beispiel ein kleiner VPS mit einem Datenlimit.

Egal, was du wählst: Jede App und jede Person, mit der du rex teilst, bekommt den Link, den deine Quelle rex für das gibt, was sie abspielen. Der Dienst hinter diesem Link, zum Beispiel dein Debrid-Dienst, sieht dann, wie jede dieser Personen die Datei herunterlädt.

## Schritt 1. Lass deine Quelle Links ausgeben {#step-1-let-your-source-hand-out-links}

**Was es macht.** Deine Quelle beantwortet jeden Lesevorgang mit einem Link zur Datei woanders (einer HTTP-Weiterleitung), statt mit der Datei selbst.

**Warum es wichtig ist.** rex kann nur einen Link weitergeben, den ihm seine Quelle gibt. Eine Quelle, die die Datei selbst schickt, wird weiterhin über rex geleitet.

| Quelle | Was zu tun ist |
|---|---|
| [rex-stremio](stremio.md) | Nichts: sie antwortet mit dem Link, den ein Stream-Addon geliefert hat. Ein Link, der eigene Header braucht, und ein Live-Playlist werden weiterhin von ihr selbst gesendet |
| [zurg](with-zurg.md) | Aktiviere `disable_stream_proxy`, siehe unten. zurg hat keinen Link für eine Usenet-Datei, daher sendet es diese immer selbst |
| [Deine eigene App](any-source.md) | Beantworte das `GET` der Datei mit einem `302` oder `307` zum Link |

### zurg

Die Einstellung gehört zu zurg, daher bekommt alles andere, das von zurg liest (rclone, ein Plex- oder Jellyfin-Server auf zurgs Mount), die Links ebenfalls. Die [Konfigurationsreferenz](../zurg/reference/config.md) von zurg hat die Details.

+++ Linux und macOS
Prüfe, ob die Einstellung schon in zurgs Konfiguration steht:

```bash
grep -n '^disable_stream_proxy:' ~/zurg/config.yml
```

Wenn eine Zeile ausgegeben wird, ändere sie mit `nano ~/zurg/config.yml` zu `disable_stream_proxy: true`. Wenn nichts ausgegeben wird, füge sie hinzu:

```bash
printf '\ndisable_stream_proxy: true\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
Öffne zurgs Konfiguration mit `notepad $HOME\zurg\config.yml`. Wenn sie eine Zeile `disable_stream_proxy:` hat, ändere sie zu `disable_stream_proxy: true`; wenn nicht, füge diese Zeile am Ende hinzu. Speichere sie und starte zurg neu:

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++ Docker
Im zurg-Ordner:

```bash
sudo grep -n '^disable_stream_proxy:' config.yml
```

Wenn eine Zeile ausgegeben wird, ändere sie mit `sudo nano config.yml`. Wenn nicht:

```bash
printf '\ndisable_stream_proxy: true\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```
+++

**Was du sehen solltest.** zurg startet wie gewohnt wieder. Filme laufen zu diesem Zeitpunkt noch über rex: rex folgt den Links bis Schritt 2 selbst.

## Schritt 2. Lass rex die Links weitergeben {#step-2-let-rex-pass-the-links-on}

**Was es macht.** rex gibt der App den Link, den deine Quelle ihr geliefert hat, anstatt den Film für sie herunterzuladen.

Hänge `--part-mode redirect` (oder `--part-mode redirect-only`) an das Ende des Startbefehls von rex an, starte rex dann neu und öffne sein Log. [rex installieren](any-source.md#step-1-install-rex) zeigt dir, wo der Startbefehl auf deinem System steht und wie du rex neu startest und sein Log ansiehst. Unter Linux steht in der Zeile `ExecStart` in `~/.config/systemd/user/rex.service` danach, und sonst nichts:

```ini
ExecStart=%h/rex/rex --part-mode redirect
```

Behalte alles, was schon in der Zeile steht, etwa `--port 32500` oder `--announce-url ...`.

**Was du sehen solltest.** Die Startzeile endet mit `parts=redirect`:

```
INFO    rex on http://192.168.1.20:32400  machine=...  items=...  parts=redirect
```

Mit `redirect-only` endet sie mit `parts=redirect-only`, und ein paar Zeilen darüber schreibt rex `transcoder off: --part-mode redirect-only`.

## Schritt 3. Etwas abspielen {#step-3-play-something}

Lass das Log von rex offen und spiel einen Film in Plezy oder Plex für Android ab.

**Was du sehen solltest.** Für jeden Lesezugriff, den die App macht, erscheint eine Zeile mit dem Server deines Anbieters:

```
INFO    PART 1000010 range=bytes=0- -> 302 to 129-4.download.real-debrid.com
```

Das bedeutet, dass rex die App an den Server des Links weitergeleitet hat, hier also an den von Real-Debrid. Steht stattdessen eine Zeile, die mit `-> 206 len=...` endet, hat rex den Film selbst gesendet: siehe [Wenn es nicht funktioniert](#if-it-does-not-work).

## Was jede App macht {#what-each-app-does}

| App | `redirect` | `redirect-only` |
|---|---|---|
| Plezy | Downloads von deinem Anbieter | Downloads von deinem Anbieter |
| Plex for Android, Original quality | Downloads von deinem Anbieter, wenn rex die Datei unverändert abspielen lässt | Dasselbe |
| Plex for Android, eine niedrigere Qualität oder Audio, das es nicht abspielen kann | rex konvertiert sie | "Playback Error: This item can't be played right now. Please try again." |
| Plex Web | Wird über rex abgespielt | "Playback Error: This server is not powerful enough to convert video." |

Plex Web kann die Links von Real-Debrid gar nicht nutzen: Real-Debrid markiert seine Dateien als Downloads, nicht als Video, und der Browser weigert sich, sie abzuspielen. Unter `redirect` wechselt Plex Web innerhalb einer Sekunde unbemerkt zu einer Konvertierung über rex, dadurch funktioniert es weiterhin. Unter `redirect-only` gibt es keinen Ausweg, auf den es zurückfallen könnte.

## In Docker

Wenn du [rex in Docker](any-source.md#run-rex-in-docker) gefolgt bist, ist Schritt 2 eine `command:`-Zeile unter `rex:` in der `compose.yml` von rex, neben `image:`:

```yaml
    command: --part-mode redirect
```

Hast du schon `command: --port 32500`? Dann ändere sie zu `command: --port 32500 --part-mode redirect`. Danach `docker compose up -d` im Ordner von rex ausführen, und `docker compose logs -f rex` zeigt dieselbe `parts=redirect`-Zeile.

## Wenn es nicht funktioniert {#if-it-does-not-work}

| Was du siehst | Was es bedeutet |
|---|---|
| rex beendet sich mit `invalid choice` bei `--part-mode` | rex ist älter als 2026.10.26. Aktualisiere es, wie im Abschnitt [Updating](any-source.md#updating) von rex beschrieben |
| Das Log von rex zeigt `-> 206 len=...` bei jedem Lesevorgang | Die Quelle schickt die Datei noch selbst. Bei zurg: `disable_stream_proxy: true` fehlt in der zurg-Konfiguration, oder zurg wurde nach Schritt 1 nicht neu gestartet |
| `-> 206 len=...` nur bei manchen Titeln | Diese schickt die Quelle selbst: zurgs Usenet-Dateien oder rex-stremio-Links, die rex weiterleiten muss |
| `-> 403: the source answered with the bytes, not a link` | `redirect-only` lehnt eine Datei ab, die die Quelle selbst geschickt hat, aus denselben Gründen wie oben |
| Keine `PART`-Zeilen, während ein Film läuft | Die App spielt eine Konvertierung ab, nicht die Datei selbst. Stelle die Qualität auf Original ein |

Immer noch fest? Frag im Forum **rex-support** auf [Discord](https://discord.com/invite/7u4YjMThXP). [Hilfe bekommen](../guides/remote-help.md) erklärt, was du angeben solltest.

## Zurück {#going-back}

Entferne `--part-mode ...` aus dem Startbefehl von rex (oder aus der Zeile `command:` bei Docker) und starte rex neu. Deine Quelle kann weiterhin Links ausgeben: Ohne die rex-Einstellung folgt rex diesen Links selbst. Bei zurg setzt du `disable_stream_proxy` wieder auf `false` und startest zurg neu. Dann gibt zurg die Dateien wieder selbst aus, auch für rclone und alles andere, das darauf zugreift.
