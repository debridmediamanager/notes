# rex mit deinen Stremio-Addons {#rex-with-your-stremio-addons}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) verwandelt Stremio-Addon-Kataloge in rex-Bibliotheken. Filme, Serien und Live-Kanäle lassen sich danach in Plex-Apps abspielen. Es wird nichts heruntergeladen. Wenn jemand auf Play drückt, fragt rex-stremio den Stream-Addon nach einem Link, und rex spielt ihn ab.

Dafür brauchst du kein DMM-Sponsoring. rex und rex-stremio sind kostenlos. Du brauchst Stream-Addons, die Links liefern, meist über dein eigenes Debrid-Konto.

Das bekommst du:

- **Libraries.** Filme landen in **Stremio Films**, Serien in **Stremio Shows** und die Kanäle eines Live-TV-Addons in einer Bibliothek namens **Live TV**, außer du benennst die Bibliothek eines Katalogs selbst. Diese Bibliothek ist eine Liste von Kanälen. Sie steht nicht im Live-TV-Guide der Plex-Apps.
- **Collections.** Gib mehreren Filmkatalogen dieselbe Bibliothek und setze den Haken bei **Catalogs as collections**. Dann gibt es eine Bibliothek, pro Katalog eine Collection, und ein Film, den mehrere Kataloge auflisten, ist nur einmal vorhanden.
- **Plex nutzt die Namen, die es kennt.** Filme und Episoden gehen mit ihren IMDb-IDs an rex. Sobald rex in einem Plex-Konto läuft, zeigen die Apps deshalb die üblichen Titel, Poster und Beschreibungen. Titel, die nur ein Addon kennt, und Live-Kanäle behalten die Namen und Bilder des Addons.

## Bevor du anfängst {#before-you-start}

| Du brauchst | Warum |
|---|---|
| Einen Rechner, der dauerhaft läuft, Linux oder macOS, für rex und rex-stremio zusammen | rex-stremio ist ein einzelnes Python-Programm und läuft neben rex. Der Dienst weiter unten ist für Linux; [Docker](#in-docker) funktioniert auch |
| Python 3.9 oder neuer, `git` und `ffprobe` | rex-stremio prüft den Stream jedes Titels einmal mit ffprobe, weil rex wissen muss, was in einer Datei steckt, bevor es sie abspielen kann. Mit einem DMM-API-Schlüssel hat ein Debrid-Stream eines Torrents, den DMM bereits kennt, schon eine Prüfung, die diesen Schritt überspringt; alles andere wird geprüft |
| Stream-Addons, die Links liefern, keine Torrents | rex spielt Dateien ab. Stelle in dem Addon deinen Debrid-Dienst ein, damit es Links liefert |
| Ein neues Plex-Konto, nur für rex angelegt | Wie im rex-Setup: rex wird auf diesem Konto beansprucht und mit deinem eigenen geteilt |

## Schritt 1: rex installieren und zu einem Plex-Konto hinzufügen {#step-1-install-rex-and-add-it-to-a-plex-account}

Folge [rex mit deiner eigenen App](any-source.md):

1. [Schritt 1. rex installieren](any-source.md#step-1-install-rex), einschließlich dem Herausfinden der LAN-IP von rex. Verwende diesen Namen in jedem Befehl.
2. [Schritt 3. Zu einem Plex-Konto hinzufügen](any-source.md#step-3-add-it-to-a-plex-account): Registriere rex auf dem neuen Konto und teile es mit deinem eigenen.

Überspringe dort die Schritte 2 und 4: rex-stremio ist deine App.

Live-Kanäle und Addons, deren Streams `.m3u8`-Playlists sind, laufen nur über die Videokonvertierung von rex. Richte dafür außerdem [Converting video](any-source.md#converting-video-optional) auf dem rex-Rechner ein. Filme und Episoden, die als Dateien (`.mkv`, `.mp4`) ausgeliefert werden, brauchen nichts weiter.

## Schritt 2. rex-stremio installieren {#step-2-install-rex-stremio}

**Was es macht.** Lädt rex-stremio nach `~/rex-stremio` auf dem rex-Rechner herunter und startet es als Dienst.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-stremio
mkdir -p ~/.config/systemd/user
cp ~/rex-stremio/rex-stremio.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-stremio
journalctl --user -u rex-stremio -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-stremio
cd ~/rex-stremio && python3 rex_stremio.py
```

Es läuft, solange das Terminal-Fenster offen bleibt.
+++

**Was du sehen solltest.** Eine Zeile etwa so:

```
... INFO relay and settings on http://127.0.0.1:9982/, 0 catalog(s), rex at http://127.0.0.1:32400
```

Die Einstellungsseite von rex-stremio und die Adresse, von der rex Videos liest, liegen beide auf `127.0.0.1:9982`. Dadurch kommt nur dieser Rechner daran.

## Schritt 3. Deine Addons hinzufügen {#step-3-add-your-addons}

Öffne `http://127.0.0.1:9982/` in einem Browser auf dem rex-Rechner. Kein Bildschirm vorhanden? Dann führe auf deinem Computer `ssh -L 9982:127.0.0.1:9982 you@<rex's LAN IP>` aus und öffne dieselbe Adresse, während SSH geöffnet bleibt.

1. Füge unter **Addons** den Manifest-Link eines Addons ein, so wie du es in Stremio tun würdest, und drücke **Add**. Mach das für:
   - **Catalogs**, zum Beispiel Cinemeta: `https://v3-cinemeta.strem.io/manifest.json`.
   - **Streams**: ein Addon, das Releases findet und sie über deinen Debrid-Dienst abspielt. Öffne seine Konfigurationsseite, wähle deinen Debrid-Dienst, füge seinen API-Schlüssel ein und kopiere den Manifest-Link, den es erzeugt. Wenn es nur gecachte Ergebnisse anbietet, wähle diese Option. Der Link enthält deinen Debrid-Schlüssel, also behalte ihn für dich.

   ![Der Abschnitt Addons in rex-stremio mit hinzugefügtem Cinemeta und Public Domain Movies](../assets/rex/90-stremio-addons.webp)

2. Unter **Catalogs** aktivierst du die Kataloge, die du willst. Benenne die Bibliothek, in die jeder kommt, und lege mit **How many** fest, wie viele Filme, Episoden oder Kanäle übernommen werden. Für eine Bibliothek mit einer Sammlung pro Katalog gibst du den Katalogen dieselbe Bibliothek und aktivierst **Catalogs as collections**.
3. Unter **Streams** legst du die **Highest resolution** und **Largest file** fest, die abgespielt werden sollen, oder lässt sie auf any.
4. Unter **rex** stellst du die Adresse auf `http://<rex's LAN IP>:32400`.
5. Wenn du DMM unterstützt, füge deinen DMM-API-Schlüssel unter **DMM** ein ([gatekeeper](https://gatekeeper.debridmediamanager.com/) zeigt ihn dir, sobald du unterstützt). Ein Debrid-Stream eines Torrents, den DMM bereits als Probe hat, überspringt die Prüfung. Alles andere wird geprüft, und was rex-stremio an den Dateien eines Torrents prüft (nie ein einfacher HTTP-Stream oder eine HLS-Playlist), geht zurück an DMM für den nächsten Unterstützer (`share_probes: false` in `config.json` verhindert das). Drücke **Save and sync**.

![Die Abschnitte Catalogs, Streams, rex und DMM in rex-stremio mit dem Button Save and sync](../assets/rex/91-stremio-catalogs-rex.webp)

**Was du sehen solltest.** Im Log von rex, so wie in [Schritt 4 von rex mit deiner eigenen App](any-source.md#step-4-connect-your-app):

```
INFO    SOURCES PUT /rex/sources/stremio -> 200
INFO    FEED stremio upsert: ...
```

Titel erscheinen in rex, sobald jeder geprüft wird, und nicht erst, wenn der ganze Katalog fertig ist. rex-stremio prüft mehrere gleichzeitig. Es synchronisiert alle sechs Stunden erneut und nach jedem Speichern.

## Schritt 4. Die neuen Bibliotheken teilen und anschauen {#step-4-share-the-new-libraries-and-watch}

Die Bibliotheken, die rex-stremio erstellt, sind neu. Dein eigenes Konto kann sie deshalb noch nicht sehen. Teile sie mit deinem eigenen Konto, so wie in [Schritt 3](any-source.md#share-it-with-your-own-account), und melde dich dabei mit dem neuen Konto an. Teile sie außerdem mit allen anderen, mit denen du rex teilst.

Öffne dann eine Plex-App als du selbst und starte etwas zum Abspielen. Genau in diesem Moment fragt rex-stremio deine Stream-Addons nach einem Link, und rex spielt ihn ab. Um unterwegs oder in app.plex.tv zu schauen, gib rex eine eigene Adresse: [Außerhalb deines Zuhauses nutzen](any-source.md#use-it-outside-your-home-optional).

## In Docker

rex-stremios [README](https://github.com/debridmediamanager/rex-stremio#set-up) enthält die Docker-Befehle. In einem Container liest rex die Videos über die Adresse des Containers in deinem Netzwerk statt über `127.0.0.1`, wie die README zeigt, wie du sie einstellst.

## Aktualisieren {#updating}

```bash
cd ~/rex-stremio && git pull && systemctl --user restart rex-stremio
```

Unter macOS stoppst du es mit Ctrl+C, führst `git pull` in `~/rex-stremio` aus und startest es dann wieder.

## Was es nicht kann {#what-it-cannot-do}

- **Episoden werden so nummeriert, wie Cinemeta sie nummeriert.** Bei ein paar Serien weicht das von der TMDB-Nummerierung ab, der rex folgt. Dadurch kann eine Episode an der falschen Stelle landen.
- **Die Anzahl zählt bei einem Serien-Katalog Episoden**, nicht Serien.
- **Das Ein- und Ausschalten von Catalogs as collections** schickt die Titel erneut als neue an rex. Was du darauf schon geschaut hast, wird deshalb möglicherweise nicht übernommen. Entscheide dich, bevor du anfängst zu schauen.
- **Es werden nur Film-, Serien- und Kanal-Kataloge aufgelistet**, und keine, die zuerst eine Suche oder ein Genre brauchen.
- **Live-Kanäle lassen sich nicht weit zurückspulen, später fortsetzen oder als gesehen markieren.** Sie laufen nur in Apps, die rex bitten, sie umzuwandeln (die Plex-Apps und Plezy; Plex Web ist nicht getestet). Kanäle ohne funktionierenden Stream oder mit DRM werden weggelassen.
- **Jeder, der die Adresse von rex-stremio erreichen kann, kann darüber abspielen.** Lass sie auf `127.0.0.1`, es sei denn, rex läuft woanders.

Das README listet die [restlichen Grenzen](https://github.com/debridmediamanager/rex-stremio#limits) und jede Einstellung in `config.json` auf. Um ein eigenes Addon zu bauen, schau in [Eigene rex-Addons bauen](addons.md) nach. Dort wird auch erklärt, wie rex-stremio intern funktioniert.
