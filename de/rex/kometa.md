# Kometa mit rex {#kometa-with-rex}

[Kometa](https://kometa.wiki) erstellt Sammlungen, setzt Badges auf Poster (4K, HDR, Bewertungen) und ergänzt Bewertungen und Genres auf einem Plex-Server. rex antwortet Kometa so, wie es ein Plex-Server tun würde, daher funktioniert dieselbe Konfiguration auch für deine rex-Bibliotheken.

Alles unten wurde am 2026-10-23 mit Kometa 2.5.3 (das Docker-Image `kometateam/kometa`) und einem beanspruchten rex getestet, auf dem ein paar Filme und eine Serie liegen.

## Bevor du anfängst {#before-you-start}

| Du brauchst | Warum |
|---|---|
| rex ist eingerichtet und mit einem Plex-Konto verbunden, siehe [Add it to a Plex account](any-source.md#step-3-add-it-to-a-plex-account) | Kometa bearbeitet die Bibliothek, und das darf nur das Konto, mit dem rex registriert ist. Ein nicht verknüpftes rex nützt niemandem |
| rex nightly **2026.10.24 oder neuer** | Aktualisieren wie im Abschnitt [rex's Updating section](any-source.md#updating) beschrieben |
| Docker auf einem Rechner, der rex erreichen kann | Kometa läuft als Container. Die eigene Doku von Kometa beschreibt [andere Installationswege](https://kometa.wiki/en/latest/kometa/install/overview/) |
| Einen kostenlosen TMDb-API-Key | Kometa braucht ihn für sich selbst, auch wenn rex keinen braucht. Du erstellst ihn unter **Settings → API** auf themoviedb.org, so wie es [TMDb's getting started page](https://developer.themoviedb.org/docs/getting-started) erklärt |

## 1. rex-Token holen {#1-get-rexs-token}

Kometa meldet sich mit einem Plex-Token bei rex an. Nimm das Token, das rex bei der Registrierung bekommen hat. Auf dem rex-Rechner:

+++ Linux und macOS
```bash
grep -o '"token": "[^"]*"' ~/rex/claim_state.json
```
+++ Windows
```powershell
(Select-String '"token": "[^"]*"' $HOME\rex\claim_state.json).Matches.Value
```
+++

Bei [rex in Docker](any-source.md#run-rex-in-docker) ist die Datei nur für root lesbar: `sudo grep -o '"token": "[^"]*"' ~/rex/config/claim_state.json`.

**Das solltest du sehen.** Eine Zeile, `"token": "..."`. Kopiere alles zwischen dem zweiten Paar Anführungszeichen. Behandle es wie ein Passwort: Damit kann man den ganzen Server öffnen. Wenn du rex irgendwann neu registrierst, ändert sich das Token, und Kometa braucht dann das neue.

**Nicht das Token deines eigenen Kontos.** Bei [Teile es mit deinem eigenen Konto](any-source.md#share-it-with-your-own-account) hat dein eigenes Konto rex als Freigabe bekommen. Eine Freigabe kann nur ansehen, nicht bearbeiten. Mit diesem Token bricht Kometa mit `Plex Token is read only` ab. Wenn die Freigabe Downloads erlaubt, scheitert Kometa erst bei der ersten Änderung.

## 2. Kometa-Konfiguration schreiben {#2-write-kometas-config}

Erstelle einen Ordner für Kometa, zum Beispiel `~/kometa/config` (`$HOME\kometa\config` unter Windows), und lege darin eine `config.yml` mit diesem Inhalt an:

```yaml
libraries:
  Movies:
    collection_files:
      - default: genre
    overlay_files:
      - default: resolution
      - default: ratings
        template_variables:
          rating1: critic
          rating1_image: tmdb
    operations:
      mass_critic_rating_update: tmdb
  TV Shows:
    overlay_files:
      - default: resolution
plex:
  url: http://192.168.1.20:32400
  token: the token from step 1
tmdb:
  apikey: your TMDb API key
```

- `url` ist die LAN-IP von rex und der Port, also die Adresse aus [Installation von rex](any-source.md#step-1-install-rex). Nicht `127.0.0.1` oder `localhost`: Im Container von Kometa zeigen diese auf den Container selbst.
- Die Namen unter `libraries:` müssen genau mit den Bibliotheken in rex übereinstimmen: **Movies** und **TV Shows**, plus alle, die du hinzugefügt oder umbenannt hast. Lass eine Bibliothek weg, wenn Kometa sie nicht anfassen soll.

Das ist nur ein kleiner Einstieg. Die Kometa-Doku listet [jede Standard-Collection und jedes Overlay](https://kometa.wiki/en/latest/defaults/guide/), und deine eigenen Collection-Dateien funktionieren auch.

## 3. Einmal ausführen {#3-run-it-once}

+++ Linux und macOS
```bash
docker run --rm -v ~/kometa/config:/config kometateam/kometa:latest --run
```
+++ Windows
```powershell
docker run --rm -v "$HOME\kometa\config:/config" kometateam/kometa:latest --run
```
+++

Mit `--run` führt Kometa jetzt einen Durchlauf aus und beendet sich danach. Ohne diese Option läuft Kometa weiter und wartet auf seinen täglichen Zeitplan.

**Was du sehen solltest.** In der Ausgabe von Kometa, für jede Bibliothek:

```
Movies Library Connection Successful
...
Overlays Applied: Overlay File (0) 1080P, Overlay File (1) Rating1Fresh
```

In einer Plex-App hat die Filmbibliothek einen **Collections**-Tab mit den Genre-Collections, und die Poster zeigen ihre Badges. Dein eigenes Konto und alle anderen, mit denen du rex geteilt hast, sehen dieselben Collections und Badges. Der erste Durchlauf bei einer großen Bibliothek dauert eine Weile: Kometa liest jeden Titel ein und zeichnet jedes Poster neu, das es mit Badges versieht.

## Wenn es nicht funktioniert {#if-it-does-not-work}

| Kometa meldet | Was es bedeutet |
|---|---|
| `Plex Token is read only. Please get a new token` | rex ist noch nicht zu einem Plex-Konto hinzugefügt, oder das Token gehört zu deinem eigenen Konto und nicht zu dem aus Schritt 1 |
| Kometa verbindet sich, aber jede Änderung schlägt fehl | Das Token gehört zu deinem eigenen Konto. Verwende das aus Schritt 1 |
| `url_poster failed to update poster` | Der rex-Rechner kann die Seite, auf der das Bild liegt, nicht erreichen |
| `Plex URL is probably invalid` oder ein Timeout | `url` erreicht rex nicht von dem Ort aus, an dem Kometa läuft. Öffne `http://192.168.1.20:32400/identity` auf diesem Rechner: Es sollte rex' `machineIdentifier` anzeigen |
| `Plex Error: Plex Library '...' not found. Options: [...]` | Ein Name unter `libraries:` stimmt nicht. Kopiere einen aus der Liste, die er ausgibt |

Noch Probleme? Frag im Forum **rex-support** auf [Discord](https://discord.com/invite/7u4YjMThXP). [Hilfe bekommen](../guides/remote-help.md) erklärt, was du angeben solltest.

## Was Kometa sehen kann und was nicht {#what-kometa-can-and-cannot-see}

Kometa ordnet Titel anhand der TMDb-, TVDb- und IMDb-IDs zu, die rex dafür anzeigt. Ein Titel, den seine Quelle nicht identifizieren konnte, der noch seinen Dateinamen zeigt und kein Poster hat, hat keine solchen IDs. Deshalb lässt Kometa ihn bei allem weg, was aus diesen IDs aufgebaut wird. Korrigiere ihn zuerst in einer Plex-App mit Fix Match.

Getestet mit rex: Sammlungen über die Titelsuche, über TMDb-IDs und Smart Collections; die Standard-Genre-Sammlungen mit ihren Postern; die Overlays für Auflösung und Bewertungen; sowie Aktualisierungen von Kritikerbewertungen und Genres aus TMDb. Noch nicht getestet: Playlists, Musikbibliotheken und die anderen Vorgänge von Kometa. Wenn etwas fehlschlägt, nennt das Log von Kometa die Anfrage, die fehlgeschlagen ist. Das lohnt sich, auf Discord zu melden.
