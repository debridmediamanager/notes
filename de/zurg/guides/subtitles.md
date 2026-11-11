# Untertitel mit Bazarr {#subtitles-with-bazarr}

Bazarr findet Untertitel für das, was Sonarr und Radarr importieren, und speichert jede Datei neben ihrem Video. Bei zurg liegt das Video in `__magic__`, und der Untertitel liegt dort ebenfalls. Plex- und Jellyfin-Bibliotheken, die auf `__magic__` zeigen, lesen ihn wie jeden anderen Untertitel auf der Festplatte, und rex zeigt ihn ebenfalls an, als **English (SRT External)** im Untertitelmenü.

Dafür brauchst du zurg und rex aus dem Nightly vom 2026-10-24 oder neuer.

Alles unten wurde am 2026-10-23 getestet, mit Radarr `6.3.0.10514`, dem aktuellen `lscr.io/linuxserver/bazarr`-Image, zurg und rex von diesem Tag und einem Real-Debrid-Konto.

## Bevor du anfängst {#before-you-start}

Radarr (oder Sonarr) importiert bereits über zurg, wobei sein Root-Ordner innerhalb von `__magic__` liegt, zum Beispiel `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` unter macOS, `Z:\__magic__\movies` unter Windows). Falls das noch nicht der Fall ist, richte zuerst [Sonarr & Radarr für Torrents](sonarr-radarr-torrents.md) oder [für Usenet](sonarr-radarr.md) ein.

## 1. Bazarr starten {#1-run-bazarr}

Auf einem Linux-Host gibst du Bazarr dasselbe Volume wie Radarr, damit beide den Film unter demselben Pfad sehen und keine Pfadzuordnung nötig ist:

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./bazarr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6767:6767
    restart: unless-stopped
```

Der Bind zeigt auf den Ordner **über** zurgs Mount (`/mnt`, der `/mnt/zurg` enthält), nicht auf den Mount selbst. Ein Container, der den Mount selbst bindet, behält nach einem zurg-Neustart einen toten Mount, und jeder Zugriff antwortet mit `Socket not connected`. [Der Docker-Schritt der Torrent-Anleitung](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker) erklärt, warum. Für `PUID` und `PGID` gilt dasselbe wie bei Whisparr: [siehe dort](whisparr.md#2-run-whisparr).

Auf macOS und Windows gilt diese Compose-Datei nicht, aus dem Grund, den [Schritt 8 der Usenet-Anleitung](sonarr-radarr.md#8-if-your-arr-is-in-docker) nennt. Starte Bazarr aus dem Quellcode (`python bazarr.py`) auf demselben Rechner wie Radarr und zurg, als derselbe Benutzer wie zurg. Folge dabei Bazarrs eigenen Seiten für [macOS](https://wiki.bazarr.media/Getting-Started/Installation/MacOS/macos/) und [Windows](https://wiki.bazarr.media/Getting-Started/Installation/Windows/source/). Unter Windows verwende nicht den Installer von Bazarr: Er richtet Bazarr als Windows-Dienst ein, und ein Dienst sieht zurgs `Z:`-Laufwerk nicht ([warum](sonarr-radarr.md#before-you-start)). Starte stattdessen `bazarr.py` aus deiner eigenen, angemeldeten Sitzung. Dann sieht Bazarr jeden Film unter dem Pfad, den Radarr meldet, und es ist keine Pfadzuordnung nötig. Getestet wurde nur das Docker-Image oben.

Öffne `http://<your server>:6767`.

## 2. Mit Radarr und Sonarr verbinden {#2-connect-it-to-radarr-and-sonarr}

**Settings → Radarr**: aktiviere es und trage Radarrs Adresse, Port und API-Key ein (zu finden unter Radarrs **Settings → General**). Aus einem Container heraus nimm die LAN-IP des Hosts, nicht `localhost`. Klick auf **Test** und dann auf **Save**. Sonarr funktioniert genauso unter **Settings → Sonarr**.

## 3. Sprachen {#3-languages}

**Settings → Languages**: füg die Sprachen hinzu, die du willst, erstell damit ein Sprachprofil und stell es als Standardprofil für Filme und für Serien ein. Bazarr fragt dann nach Untertiteln für alles, was Radarr und Sonarr schon haben.

## 4. Provider {#4-providers}

**Settings → Providers**: füge die Untertitel-Seiten hinzu, in denen Bazarr sucht. Manche brauchen ein Konto, manche nicht. Zwei Dinge sind uns beim Testen aufgefallen:

- **subf2m** braucht in seinen Provider-Einstellungen einen User-Agent. Ohne ihn pausiert Bazarr den Provider bei der ersten Suche für 12 Stunden.
- Bazarr pausiert einen Provider eine Zeit lang, wenn er fehlschlägt. Sind alle Provider pausiert, findet eine Suche nichts. **System → Providers** zeigt sie an und setzt sie zurück.

## 5. Eingebettete Untertitel {#5-embedded-subtitles}

Viele Releases haben bereits eine englische Spur in der Videodatei. Bazarr zählt das als vorhandenes Englisch und lädt dann nichts herunter. Wenn du trotzdem eine Untertiteldatei willst, schalte unter **Settings → Subtitles** die Option **Use Embedded Subtitles** aus.

## 6. Eine prüfen {#6-check-one}

Die **Movies**-Seite von Bazarr zeigt, welche Untertitel bei jedem Film fehlen. Suche von dort aus nach einem Film, dann liegt der Untertitel neben dem Video (unter Windows findest du ihn im Explorer im selben Ordner unter `Z:\__magic__\movies`):

```bash
$ ls "/mnt/zurg/__magic__/movies/Night of the Living Dead (1968)/"
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.en.hi.srt
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.mkv
```

Der Untertitel ist eine echte Datei auf der Festplatte von zurg, in `data/local/__magic__/` (siehe [Sidecars](magic.md#sidecars-nfo-posters-subtitles)). Das Video wird weiterhin aus deinem Konto gestreamt.

## In rex

zurg schickt rex jede Untertitel-Datei, die neben einem Video in `__magic__` liegt, egal wohin Radarr oder Sonarr das Video verschoben haben. zurg prüft einmal pro Minute, ob Untertitel neu, geändert oder entfernt wurden. Ein Untertitel, den Bazarr speichert, erscheint deshalb innerhalb von etwa einer Minute in rex, und einer, den du löschst, verschwindet genauso schnell. Du musst nichts weiter einrichten als `rex_url` in zurgs Konfiguration, das du [in der rex-Anleitung](../../rex/with-zurg.md) bereits gesetzt hast.

Der Dateiname sagt, um welche Untertitel es sich handelt, so wie Plex Untertitelnamen liest:

| Dateiname endet auf | rex zeigt |
|---|---|
| `.srt` | Unknown (SRT External) |
| `.en.srt` | English (SRT External) |
| `.en.forced.srt` | English Forced (SRT External) |
| `.en.hi.srt`, `.en.sdh.srt`, `.en.cc.srt` | English SDH (SRT External) |

`.srt`-, `.ass`-, `.ssa`-, `.smi`- und `.txt`-Dateien werden gelesen. Der Sprachcode kann zwei oder drei Buchstaben haben (`en`, `eng`, `de`, `ger`). Der Name davor muss der eigene Name des Videos sein, so wie Bazarr ihn schreibt.

Nur Untertitel in `__magic__` landen bei rex. Einer, der neben einer Datei in einem anderen zurg-Ordner gespeichert ist, etwa `/mnt/zurg/movies`, wird nicht übertragen.

rex kann Untertitel auch selbst suchen: **Search Subtitles** in jeder Plex-App, ganz ohne Bazarr. Siehe [Untertitel in rex](../../rex/with-zurg.md#subtitles).
