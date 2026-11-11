# Hol dir, was du willst, aus DMM {#fetch-what-you-want-from-dmm}

Klicke bei einem Film oder einer Serie in [Debrid Media Manager](https://debridmediamanager.com) auf **Want**, und dein zurg holt sie sich. Du musst weder Sonarr noch Radarr einrichten, und es gibt nichts zu mounten. Serien bekommen ihre neuen Folgen automatisch, sobald sie ausgestrahlt werden.

Das ist für Sponsoren gedacht: zurg liest deine Liste mit deinem DMM-API-Schlüssel.

## Was du brauchst {#what-you-need}

- Ein zurg-Nightly von 2026-10-25 oder neuer.
- Dein DMM-API-Key in der `config.yml` von zurg. Das ist der Key, den dir [gatekeeper](https://gatekeeper.debridmediamanager.com/) anzeigt, sobald du sponserst:

  ```yaml
  dmm_api_key: YOUR_DMM_API_KEY
  ```

- Etwas, worauf zurg zugreifen kann: ein Debrid-Konto, das Torrents annimmt, ein `nzb`- oder `torbox_nzb`-Provider für Usenet oder beides.

Das war's schon. zurg liest deine Liste ab dem Start einmal pro Minute ein.

## Titel hinzufügen {#adding-titles}

1. Füge denselben Schlüssel auf der [Settings](https://debridmediamanager.com/settings)-Seite von DMM ein.
2. Öffne einen Film und drücke **Want**. Auf der Staffelseite einer Serie fügt **Want S2** genau diese Staffel hinzu, und **Want all seasons** fügt die ganze Serie hinzu, inklusive neuer Staffeln.
3. Deine Liste findest du unter [debridmediamanager.com/wanted](https://debridmediamanager.com/wanted). Dort steht, wann dein zurg sie zuletzt gelesen hat und wann er jeden Film abgerufen hat. Lange Listen werden mit 120 Titeln pro Seite angezeigt.

Anfragen aus Seerr, Overseerr oder Jellyseerr können auf derselben Liste landen: siehe [Seerr through DMM](../../dmm/seerr.md).

## Einer Liste folgen {#following-a-list}

Füge die Seite einer Trakt- oder MDBList-Liste auf deiner [Wunschliste](https://debridmediamanager.com/wanted) ein
und drücke auf **Follow**. Jeder Film und jede Serie darin wird als gewünscht markiert, und DMM liest die Liste alle sechs Stunden neu ein.
Was später dazukommt, wird also auch gewünscht. Diese Seiten werden unterstützt:

- `https://trakt.tv/users/<user>/lists/<list>` und `https://trakt.tv/lists/<id>`
- `https://trakt.tv/users/<user>/watchlist`, sofern dieses Trakt-Profil öffentlich ist
- `https://mdblist.com/lists/<user>/<list>`

Auf den eigenen Trakt-Seiten von DMM hat deine Watchlist und jede deiner Listen einen Button **Follow with Want**, der dasselbe macht.

Für eine IMDb-, Letterboxd-, Rotten-Tomatoes- oder Plex-Watchlist: Erstelle auf mdblist.com aus deren URL eine [externe Liste](https://docs.mdblist.com/docs/external_lists) und folge dieser. MDBList hält sie mit der Quelle synchron.

Was Folgen bewirkt:

- Eine Serie wird komplett gewünscht, inklusive neuer Staffeln.
- Es werden nur Titel hinzugefügt, die seit dem letzten Einlesen neu auf der Liste stehen. Einen Titel, den du von deiner Wunschliste entfernst, bleibt entfernt, und ein Titel, der die Liste verlässt, bleibt gewünscht. **Unfollow** behält, was die Liste hinzugefügt hat.
- Die Seite zeigt jede Liste mit der Anzahl ihrer Titel, wie viele davon bisher hinzugefügt wurden und wann sie zuletzt eingelesen wurde. **Read again** liest sie jetzt neu ein. Titel ohne IMDb-ID werden ausgelassen, und die Anzahl zeigt, wie viele das sind.
- Deine Liste hat Platz für 10.000 Titel, die noch geholt werden müssen: jede Serie und jeder Film, den zurg noch nicht geholt hat oder auf ein Upgrade wartet. Von zurg bereits geholte Filme zählen nicht. Ein Titel, der nicht mehr hineinpasst, wird bei einem späteren Einlesen hinzugefügt, sobald wieder Platz ist.

## Von Radarr oder Sonarr umsteigen {#moving-from-radarr-or-sonarr}

Hol alles zurück, was noch fehlt:

1. Öffne in Radarr oder Sonarr **System → Backup**, drücke **Backup Now** und lade die
   ZIP-Datei herunter. Die geplanten Backups im Ordner `Backups` funktionieren auch.
2. Drücke auf deiner [Wunschliste](https://debridmediamanager.com/wanted) auf **Import a Radarr or
   Sonarr backup** und wähle die ZIP-Datei aus. Mach dann dasselbe mit dem Backup der anderen App.

Was übernommen wird:

- Aus Radarr jeder überwachte Film ohne Datei, der seine minimale Verfügbarkeit erreicht hat. Filme ohne IMDb-ID werden ausgelassen; die Seite zeigt an, wie viele es sind.
- Aus Sonarr jede überwachte Serie mit fehlenden ausgestrahlten Episoden, und zwar nur diese Staffeln.
- Titel, die schon auf deiner Liste stehen, bleiben unverändert.

Nur die Datenbank in der ZIP-Datei wird hochgeladen. Der Rest des Backups, einschließlich des API-Schlüssels der App, bleibt auf deinem Computer.

Zwei Dinge werden nicht übernommen:

- **Qualitätsprofile.** zurg wählt Releases nach seinen eigenen [Beschaffungseinstellungen](acquisition.md#configuration). Radarr lehnt Kamera- und Telesync-Kopien meist ab. Um sie auch hier fernzuhalten, füge sie zu [`exclude_words`](acquisition.md#excluding-releases-by-name) hinzu:

  ```yaml
  acquisition:
    exclude_words: [CAM, CAMRip, HDCAM, TS, HDTS, TELESYNC, TC, HDTC, TELECINE]
  ```

- **Die Staffelnummern von Sonarr, wo sie abweichen.** Deine Liste nummeriert Staffeln wie TMDB. Sonarr richtet sich nach TheTVDB, das manche langlaufenden Animes in mehr Staffeln aufteilt. Eine Sonarr-Staffel, die TMDB nicht hat, wird daher nicht geladen. Prüfe diese Serien auf ihrer DMM-Seite und drücke bei den fehlenden Staffeln auf **Want**.

## Was zurg abruft {#what-zurg-fetches}

- **Ein Film** einmal. Danach verschwindet er aus der Liste, die zurg liest. Ein Film, der unter der `quality`, auf die gezielt wird (2160p bei `best`), geholt wurde, bleibt dagegen auf der Liste: zurg holt eine bessere Kopie, sobald eine erscheint, und entfernt die vorher geholte. Eine Kopie, die du selbst hinzugefügt hast, bleibt erhalten. `upgrades: false` unter `acquisition:` in zurgs Config schaltet das aus. `/wanted` zeigt, was zurg geholt hat und welche Auflösung es noch erwartet, außer bei der unten stehenden Liste von Auflösungen.
- **Ein Film in 1080p und in 4K**, falls du beides willst, zum Beispiel damit ein 1080p-Fernseher eine Datei abspielt, ohne dass die 4K-Datei transkodiert werden muss. Benötigt den Nightly von 2026-10-31 oder neuer. Trag die Auflösungen in zurgs Config ein:

  ```yaml
  acquisition:
    quality: [1080p, 4k]
  ```

  zurg behält dann von jedem Film eine Kopie in jeder dieser Auflösungen. Jede Kopie nimmt die beste Veröffentlichung bei oder unter ihrer eigenen Auflösung und wird unabhängig aktualisiert, sodass die 1080p-Kopie nie zu einer 2160p-Kopie wird. Solange keine Veröffentlichung besser als 1080p verfügbar ist, nehmen beide meist dieselbe Veröffentlichung, und du bekommst nur eine Datei. `720p` kann ebenfalls aufgelistet werden. Serien bekommen weiterhin nur eine Kopie, ausgewählt so, als hättest du nur die höchste Auflösung angegeben. Filme, die zurg schon vor dem Hinzufügen der Liste geholt hat, werden in jeder Auflösung erneut geholt; zurg entfernt die alte Kopie nicht, also lösch sie selbst, wenn du sie nicht mehr willst. Die vollständigen Regeln stehen unter [eine Kopie in mehreren Auflösungen](acquisition.md#a-copy-at-each-of-several-resolutions).
- **Eine Serie**: jede bereits ausgestrahlte Folge der Staffeln, die du ausgewählt hast, als Staffelpaket, wenn ein Paket die ganze Staffel abdeckt, und als einzelne Folgen, solange sie noch läuft. Es prüft weiter auf neue Folgen, bis du die Serie entfernst. Specials werden nicht geholt.

Veröffentlichungen kommen aus Usenet als NZBs und aus Torrents, die dein Debrid-Konto schon gecacht hat; nicht gecachte Torrents werden nie hinzugefügt. Wenn du keine Indexer eingerichtet hast, durchsucht zurg die von DMM. Qualität, Größenlimits, zu meidende Wörter sowie die Audio- und Untertitelsprachen, die eine Veröffentlichung haben muss, legst du in zurgs [Acquisition-Einstellungen](acquisition.md#configuration) fest, die für alle Quellen gleich sind.

## Schauen in Kodi oder Plex {#watching-it-in-kodi-or-plex}

Mit `__magic__` aktiviert legt zurg die Dateien, die es abruft, nach Titel sortiert ab, und zwar in `__magic__/__movies__` und `__magic__/__shows__`. Die Namen sind so gewählt, dass Kodi und Plex sie richtig zuordnen. Richte eine Filmbibliothek und eine Serienbibliothek auf diese beiden Ordner aus. Wenn du `magic.anime` nutzt, kannst du zusätzlich eine Anime-Bibliothek auf `__magic__/__anime__` einrichten: siehe [`__movies__` and `__shows__`](magic.md#__movies__-and-__shows__-sorted-by-title).

```yaml
magic:
  enabled: true
```

## Zwei zurgs mit einem Schlüssel {#two-zurgs-on-one-key}

Jede zurg liest dieselbe Liste, daher holen sich zwei davon jeden Titel doppelt. Behalte die Liste bei einer und schalte sie bei den anderen aus:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

## Wenn es aufhört {#when-it-stops}

Wenn dein Sponsoring ausläuft oder du deinen Schlüssel zurücksetzt, protokolliert zurg, dass DMM den Schlüssel abgelehnt hat, und fragt jede Stunde erneut nach. Was bereits abgerufen wurde, bleibt in deiner Bibliothek.

Mehr Details: [DMM wanted list](acquisition.md#dmm-wanted-list) in der Referenz zur Akquise.
