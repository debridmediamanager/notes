# Bring deinen Wiedergabeverlauf zu rex {#bring-your-watch-history-to-rex}

rex startet ohne Wiedergabeverlauf. Es kann gesehene Titel, Fortsetzungspunkte und Sternebewertungen von einem anderen Plex-Server kopieren.
Gesehene Titel bleiben gesehen. Teilweise gesehene Titel landen wieder in **Continue Watching**. Serien und Staffeln zählen ihre Folgen neu.

Führe es einmal von einem beliebigen Computer zu Hause aus. Jeder, der rex benutzt, kann seinen eigenen Verlauf importieren.

## Bevor du anfängst {#before-you-start}

| Du brauchst | Warum |
|---|---|
| rex eingerichtet, mit deiner Bibliothek darin, wie in [rex mit deiner eigenen App](any-source.md), [rex mit deinen Stremio-Addons](stremio.md) oder [rex mit zurg](with-zurg.md) | rex kopiert den Verlauf nur auf Titel, die es schon hat. Wenn deine Bibliothek noch aufgebaut wird, führe den Import später erneut aus: Er fügt nur hinzu, was neu ist |
| rex Nightly **2026.10.31 oder neuer** | Aktualisieren wie im Abschnitt [rex's Updating section](any-source.md#updating) |
| Dein alter Plex-Server, läuft | rex liest den Verlauf von dort. Starte ihn wieder, falls du ihn beim Wechsel zu rex angehalten hast |
| Ein Computer in deinem Heimnetzwerk, mit `curl` | Der Import läuft nur aus deinem Heimnetzwerk. Windows 10 und 11, macOS und Linux haben alle `curl` |

## 1. Kopiere die Adresse deines alten Servers {#1-copy-your-old-servers-address}

1. Öffne [app.plex.tv](https://app.plex.tv) in einem Browser und melde dich als **dich selbst** an, also mit dem Konto, dessen Verlauf du übernehmen willst.
2. Wähle deinen alten Server aus und öffne irgendeinen Film darauf.
3. Klicke auf **⋯** (More) und dann auf **Get Info**.
4. Klicke im **Media Info**-Feld, das sich öffnet, unten links auf **View XML**. Ein neuer Tab öffnet sich, voller Text.

   ![Das Media-Info-Feld, das Get Info öffnet, mit View XML unten links](../assets/rex/40-plex-get-info.webp)
5. Kopiere die **ganze Adresse** aus der Adressleiste dieses Tabs.

Sie sieht so aus, alles in einer Zeile, und endet mit `X-Plex-Token=` gefolgt von einem Code:

```
https://192-168-1-5.0123456789abcdef.plex.direct:32400/library/metadata/1234?checkFiles=1&includeAllConcerts=1&X-Plex-Token=AbCdEfGh1234567890xy
```

Dieser Code ist dein **Plex-Token** für diesen Server. Er funktioniert wie ein Passwort für dein Plex-Konto: Füge ihn niemals in Discord, einen Support-Beitrag oder einen Screenshot ein.

**Kein View XML in Schritt 4?** Plex Web zeigt es nur bei Servern, die dir gehören. Bei einem Server, den dir jemand geteilt hat, gibt es das nicht. Nutze stattdessen die Entwicklertools deines Browsers auf deinem alten Server, wie in [Schritt 2](#2-get-your-token-on-rex), und wähle eine Anfrage an deinen alten Server aus (ihre Adresse enthält `plex.direct`). Klicke sie mit der rechten Maustaste an und kopiere ihre Adresse: **Copy**, **Copy URL** in Chrome und Edge, **Copy Value**, **Copy URL** in Firefox. Diese Adresse brauchst du. Sie enthält `X-Plex-Token=` und den Code sowie weitere `X-Plex-`-Teile. Füge alles ein.

## 2. Hol dir deinen Token auf rex {#2-get-your-token-on-rex}

rex wird mit dir geteilt, deshalb gibt es bei **Get Info** auf rex kein **View XML**: Plex Web zeigt es nur dem Besitzer eines Servers. Lies stattdessen den Token aus deinem Browser aus, so wie app.plex.tv ihn an rex schickt:

1. Öffne app.plex.tv, bleib als du selbst angemeldet, und öffne die Entwicklertools deines Browsers: **F12** oder **⌥ ⌘ I** auf einem Mac. In Safari musst du zuerst unter **Settings**, **Advanced** die Option **Show features for web developers** aktivieren.
2. Öffne den Tab **Network** und tippe `X-Plex-Token` in das Filterfeld.
3. Öffne einen beliebigen Film auf dem Server **rex**. Die Liste füllt sich mit Anfragen.
4. Klicke eine an, deren Adresse zu rex gehört: Bei rex-direct steht darin `rex-direct.debridmediamanager.com`, oder es ist die HTTPS-Adresse, die du selbst eingerichtet hast. Nicht eine an `plex.tv`.
5. Kopiere den Wert von `X-Plex-Token`: Chrome und Edge zeigen ihn unter **Payload**, Firefox unter **Request**. Oder kopiere die Adresse der Anfrage und nimm den Teil nach `X-Plex-Token=` bis zum nächsten `&`.

Das ist ein anderer Code als der in Schritt 1: Jeder Server gibt deinem Konto einen eigenen. rex nutzt diesen, um zu wissen, wessen Verlauf es ist.

## 3. Starte den Import {#3-run-the-import}

Führe das auf einem Computer zu Hause aus, nachdem du deine beiden Werte eingesetzt hast. `192.168.1.20` ist die LAN-IP von rex, wie in den Setup-Anleitungen. Ersetze sie durch deine eigene.

```bash
curl -d "ADDRESS-FROM-STEP-1" "http://192.168.1.20:32400/rex/import-watched?X-Plex-Token=TOKEN-FROM-STEP-2"
```

Unter Windows öffnest du **PowerShell** und tippst `curl.exe` statt `curl`. Lass beide Paare doppelter Anführungszeichen stehen: Die Adresse aus Schritt 1 enthält `&`-Zeichen, die den Befehl ohne die Anführungszeichen kaputt machen.

Es dauert ein paar Sekunden, bei einer großen Bibliothek länger: rex liest jeden Film und jede Episode auf dem alten Server.

**Was du sehen solltest.** Eine Zeile wie diese:

```json
{"watched":412,"inProgress":7,"rated":38,"alreadyHere":0,"notInRex":55}
```

| Number | Means |
|---|---|
| `watched` | Titel, die rex als gesehen markiert hat, mit Abspielanzahl und Datum vom alten Server |
| `inProgress` | Titel, die du angefangen hattest: Sie werden dort fortgesetzt, wo du aufgehört hast |
| `rated` | Titel, die ihre Sternebewertung bekommen haben |
| `alreadyHere` | Titel, die du bereits in rex gesehen oder angefangen hattest. rex behält, was es schon hat, und ändert dort nichts |
| `notInRex` | Titel, zu denen der alte Server einen Verlauf hat, den rex nicht hat, oder nicht als derselbe Titel |

Öffne deine Plex-App erneut (oder lade app.plex.tv neu), um es zu sehen.

## Führ ihn jederzeit erneut aus {#run-it-again-any-time}

Ein erneuter Lauf ändert nichts an dem, was du schon hast. Führe ihn also aus, wann immer mehr von deiner Bibliothek angekommen ist. Ein zweiter Lauf direkt nach dem ersten zeigt `"watched":0` und die bisherigen unter `alreadyHere`.

## Was nicht kopiert wird {#what-is-not-copied}

- Verlauf von anderen Leuten auf deinem alten Server. Jede Person führt den Import mit ihren eigenen zwei Tokens aus.
- Die Wiedergabeverlaufsliste des Servers, Playlists und Sammlungen.
- Sternebewertungen für ganze Serien und Staffeln. Bewertungen für Filme und Episoden werden kopiert.
- Titel in einer Bibliothek, deren agent auf dem alten Server nicht **Plex Movie** oder **Plex TV Series** ist (die älteren agents, wie Plex Movie (Legacy) und TheTVDB). rex findet einen Titel anhand der ID, die die aktuellen Plex-agents ihm geben. Die älteren vergeben eine andere ID, deshalb zählen diese Titel unter `notInRex`.

## Wenn es nicht funktioniert {#if-it-does-not-work}

| Was du siehst | Was du tun solltest |
|---|---|
| `that address has no X-Plex-Token: copy it whole from the tab View XML opens` | Die eingefügte Adresse endet vor dem Token. Kopiere sie erneut aus der Adressleiste oder den Entwicklertools und füge die ganze Adresse ein |
| `send the address View XML opens on your old Plex server, starting http:// or https://` | In den Anführungszeichen nach `-d` steht etwas anderes als die Adresse |
| `... refused the token: copy the address from View XML again` | Der alte Server hat das Token nicht akzeptiert. Mache Schritt 1 noch einmal, mit den Entwicklertools, falls der Server mit dir geteilt ist |
| `could not reach https://...` | rex konnte keine Verbindung zu deinem alten Server aufbauen. Er muss laufen, und **der rex-Rechner** muss ihn erreichen: rex liest von ihm, nicht von deinem Computer |
| `run the import from your home network` | Du hast den Befehl an die externe Adresse von rex geschickt. Verwende die LAN-IP von rex, wie in Schritt 3 |
| Eine `Unauthorized`-Seite | rex hat das Token aus Schritt 2 nicht akzeptiert. Kopiere es erneut aus einer Anfrage an rex, nicht an `plex.tv` |
| `notInRex` ist viel höher als erwartet | Der Großteil deiner Bibliothek ist noch nicht in rex, oder deine alte Bibliothek nutzt einen älteren Agenten von Plex. Starte es noch einmal, sobald deine Bibliothek angekommen ist |

Immer noch nicht weiter? Frag im **rex-support**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP). [Hilfe bekommen](../guides/remote-help.md) erklärt, was du angeben solltest.
