# Live-TV mit rex {#live-tv-with-rex}

rex zeigt Addon-Kanäle in Plex Web und in Plex für Android unter **Live TV** an, mit einer Programmübersicht und What's On. Wähle einen
Kanal aus, dann startet die Wiedergabe sofort. [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) ist
sofort einsatzbereit, wenn du einen Live-Sports-Server hast. Für eine IPTV-M3U und eine XMLTV-Programmübersicht siehe [Anleitung: ein IPTV-Addon](addon-iptv.md).

Was du bekommst:

- **Eine Programmübersicht.** Jeder Kanal mit seiner Nummer, mit dem, was jetzt und als Nächstes läuft.
- **What's On.** Was gerade läuft, was später beginnt und die kommenden Filme.
- **Suche.** Der Name einer Sendung findet sie in Live TV und auch in deinen Bibliotheken.
- **Wiedergabe.** Wähle einen Kanal, dann läuft er live. Ein Kanal speichert keinen Fortsetzungspunkt und wird nie als gesehen markiert.
- **Eine Kanalliste wie bei einem TV-Anbieter.** rex-live-sports startet mit seiner US-Kanalliste: etwa 30 Sportsender mit Nummern, die sich nie ändern (ESPN ist 2, CBS ist 7), dazu der Spielplan von ESPN für die Spiele auf diesen Sendern und Slot-Kanäle (`NFL 1`, `NBA 1` und so weiter), die die Spiele des Tages vor ihrem Beginn auflisten und jedes Spiel live abspielen. Es gibt auch eine britische und eine deutsche Kanalliste.
- **Auch in der Bibliothek.** Die Kanäle bleiben in ihrer eigenen **Live Sports**-Bibliothek und sind pro Gruppe in einer Sammlung sortiert.

## Bevor du anfängst {#before-you-start}

| Du brauchst | Warum |
|---|---|
| Ein rex-Nightly mit dem Datum 2026.11.02 oder neuer | Live-TV kam in diesem Build dazu |
| rex eingerichtet wie in [rex mit deiner eigenen App](any-source.md), mit [Video-Konvertierung](any-source.md#converting-video-optional) | rex konvertiert jeden Kanal, während du zuschaust (eine Kopie, günstig) |
| Ein Live-Sport-Server, auf der rex-Maschine oder in deinem Heimnetzwerk | rex-live-sports nimmt seine Kanäle von dort |
| Docker | Wird in Schritt 2 für live-sports gebraucht. Seine [README](https://github.com/yowmamasita/live-sports-public) beschreibt die anderen Möglichkeiten |
| Python 3.9 oder neuer, `git`, `ffmpeg` und `ffprobe` auf der rex-Maschine | rex-live-sports prüft den Stream jedes Kanals mit ffprobe und zeichnet sein Poster mit ffmpeg |

## Schritt 1: rex installieren und zu einem Plex-Konto hinzufügen {#step-1-install-rex-and-add-it-to-a-plex-account}

Folge [rex mit deiner eigenen App](any-source.md):

1. [Schritt 1. rex installieren](any-source.md#step-1-install-rex), inklusive dem Herausfinden der LAN-IP von rex. Auf dieser Seite steht sie als `192.168.1.20`: Trag an ihrer Stelle deine eigene IP ein.
2. [Schritt 3. Zu einem Plex-Konto hinzufügen](any-source.md#step-3-add-it-to-a-plex-account): registriere rex auf dem neuen Konto und teile es mit deinem eigenen.
3. [Video konvertieren](any-source.md#converting-video-optional).

Überspring dort Schritt 2 und 4: rex-live-sports ist deine eigene App.

## Schritt 2: Einen Live-Sport-Server starten {#step-2-start-a-live-sports-server}

**Was es macht.** Führt live-sports aus, das Sport-Kanäle findet und alle paar Minuten prüft, welche davon gerade laufen.

```bash
docker run -d --name live-sports --restart unless-stopped -p 8765:8765 ghcr.io/yowmamasita/live-sports:latest
```

**Was du sehen solltest.** `http://192.168.1.20:8765` zeigt das Dashboard von live-sports im Browser. Die erste Prüfung jedes Kanals dauert ein paar Minuten.

## Schritt 3: rex-live-sports installieren {#step-3-install-rex-live-sports}

**Was es macht.** Lädt rex-live-sports nach `~/rex-live-sports` auf dem rex-Rechner herunter und startet es.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

Setz in `config.json` `live_sports_url` auf `http://192.168.1.20:8765` und `rex_url` auf `http://192.168.1.20:32400`. Dann:

```bash
mkdir -p ~/.config/systemd/user
cp ~/rex-live-sports/rex-live-sports.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-live-sports
journalctl --user -u rex-live-sports -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

Setz in `config.json` `live_sports_url` auf `http://192.168.1.20:8765` und `rex_url` auf `http://192.168.1.20:32400`. Dann:

```bash
python3 rex_live_sports.py
```

Es läuft, solange das Terminal-Fenster offen bleibt.
+++

**Was du sehen solltest.** Eine Zeile etwa so:

```
INFO relay on http://127.0.0.1:9983/, live-sports at http://192.168.1.20:8765, rex at http://192.168.1.20:32400
```

Bis live-sports die erste Prüfung abgeschlossen hat, steht im Log `live-sports lists no channel that plays yet`. Danach prüft der erste Sync den Stream jedes Lineup-Kanals, den live-sports hat, das dauert etwa eine Minute bei 30 Kanälen, und schreibt:

```
INFO pushed 38 of 30 channels, 38 with their Live TV channel: ...
```

Das sind die 30 Lineup-Kanäle, die live-sports hat, plus die Slots mit einem Spiel an diesem Tag. Danach synchronisiert es alle fünf Minuten neu und prüft nur die Kanäle, die es an diesem Tag noch nicht gesehen hat.

## Schritt 4: Bibliothek teilen und Live-TV öffnen {#step-4-share-the-library-and-open-live-tv}

Die **Live Sports**-Bibliothek ist neu, daher ist sie noch in keiner Freigabe. Melde dich mit dem frischen Konto an und füge sie unter **Manage Library Access** zu deiner eigenen Freigabe hinzu und zu allen anderen ([rex teilen](sharing.md)). Eine Freigabe erlaubt dem Konto, Live TV zu schauen, außer du hast das für das Konto ausgeschaltet.

Öffne dann eine Plex-App als du selbst:

- **Plex Web**: **Live TV & DVR** steht in der Seitenleiste, mit den Bibliotheken von rex.
- **Plex for Android**: der Tab **Live TV** unten, mit rex oben ausgewählt. **Live TV & DVR** ist ebenfalls mit den Bibliotheken von rex aufgeführt.

**Das solltest du sehen.** Oben stehen **Guide** und **What's On**. Der Guide zeigt jeden Sender mit seiner Nummer und dem, was gerade läuft. Wähle eine Sendung aus und drücke auf **Watch Now**.

## Kanäle, Nummern und Programmführer {#channels-numbers-and-guides}

`config.json` legt das Lineup fest: `lineups/us.json` wie kopiert, `lineups/uk.json` oder `lineups/de.json` für die Sender aus Großbritannien oder Deutschland. Ein Lineup-Kanal ist unter seiner Nummer vorhanden, während live-sports eine Kopie davon hat, die abgespielt wird. Ein US-Sender bekommt seine Spiele aus dem Spielplan von ESPN (`Chicago Bears at Seattle Seahawks`, ab Anpfiff für die übliche Spieldauer der Sportart; NFL, College Football, NBA, NHL, MLB, die großen europäischen Ligen, MLS und F1). ESPN nennt nur US-Sender, deshalb bekommen die Sender aus Großbritannien und Deutschland stattdessen die Programmübersicht, die [epgshare01](https://epgshare01.online/) für einen Kanal mit ihrem Namen hat, so wie jeder Kanal rund um seine Spiele. Ein Kanal, den keine Übersicht auflistet, zeigt seinen eigenen Namen in Blöcken von sechs Stunden.

Die Slots kommen nach den Sendern: `NFL 1` bis `NFL 10` auf `700.1` bis `700.10`, `NBA 1` bis `NBA 6` ab `701.1`, dann NHL, MLB, Soccer und F1. Jedes Spiel des Tages landet im ersten freien Slot seiner Sportart, damit die Übersicht es schon vor dem Anpfiff zeigt. Von 15 Minuten vor Anpfiff bis zum Spielende spielt der Slot den live-sports-Stream ab, der das Spiel hat. Er wird anhand der Namen beider Teams gefunden. Zwischen den Spielen spielt ein Slot nichts ab. Ein Slot taucht erst auf, wenn er zum ersten Mal ein Spiel abspielt.

Ohne Lineup (`"lineup": ""` in `config.json`) sind stattdessen alle Kanäle der live-sports-Gruppen `Live:` und `Sports` vorhanden, nummeriert nach Gruppe: `100.1`, `100.2` für die erste Gruppe, `101.1` für die nächste, damit sie nicht mit den niedrigen Nummern kollidieren, die ein Tuner oder eine andere Quelle nutzt. Ein Kanal behält seine Nummer, solange live-sports ihn mindestens einmal pro Woche auflistet. Pluto-TV-Kanäle bekommen den eigenen Programmplan von Pluto TV und sind nur dabei, wenn du sie ausdrücklich anforderst: `"groups": ["Live:", "Sports", "Pluto:"]`. Alle Einstellungen findest du in der [README](https://github.com/debridmediamanager/rex-live-sports#settings) von rex-live-sports.

## Aktualisieren {#updating}

```bash
cd ~/rex-live-sports && git pull && systemctl --user restart rex-live-sports
```

Unter macOS stoppst du es mit Ctrl+C, führst `git pull` in `~/rex-live-sports` aus und startest es dann wieder.

## Was es nicht kann {#what-it-cannot-do}

Hier ist die Übersetzung ins Deutsche:

- **Nichts wird aufgenommen.** Plex Web und Plex für Android zeigen keine Aufnahme-Schaltfläche.
- **Programmdaten werden über den Namen zugeordnet.** Ein Kanal kann die Programmdaten eines anderen Feeds derselben Marke bekommen, und viele Event-Kanäle haben gar keine.
- **Ein Slot findet den Stream eines Spiels anhand der Teamnamen in seinem Namen.** Ein Stream mit einem anderen Namen (`nfl ravens`) wird nicht gefunden, und ein Spiel, für das kein Stream existiert, steht zwar im Programm, lässt sich aber nicht abspielen.
- **Plex behandelt eine Sendung ohne Episodennummer als Film**, wie bei jedem TV-Programm, daher erscheinen die Treffer auch unter den Filmen von What's On.
- **Live-TV wurde in Plex Web und Plex für Android getestet.** Andere Plex-Apps wurden noch nicht ausprobiert.
- **Wer die Adresse von rex-live-sports erreichen kann, kann darüber abspielen.** Lass `listen` auf `127.0.0.1`.

Wenn du eigene Kanäle mit einer Programmübersicht hinzufügen willst, die du schon hast, schau dir [Building rex addons](addons.md#live-tv) an.
