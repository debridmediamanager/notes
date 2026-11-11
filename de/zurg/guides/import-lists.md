# Einer Liste in Sonarr und Radarr folgen {#following-a-list-in-sonarr-and-radarr}

Sonarr und Radarr können einer Liste von Serien oder Filmen folgen. Jeder Titel darauf wird hinzugefügt und gesucht. Wenn zurg der Download-Client ist, landet jeder Download in deinem Debrid-Konto und wird wie jeder andere in `__magic__` importiert. Eine Liste ist also ein ganzer Bibliotheksbereich, der sich selbst füllt. Eine Horror-Liste ergibt einen Horror-Bereich, und neue Titel erscheinen, wenn die Liste wächst.

Diese Seite setzt voraus, dass die \*arrs bereits über zurg laden. Falls nicht, fang mit [Sonarr & Radarr für Torrents](sonarr-radarr-torrents.md) an.

## MDBList statt IMDb verwenden {#use-mdblist-and-not-imdb}

Beide Apps zeigen noch einen IMDb-Listentyp an, und keine funktioniert mehr mit einer normalen IMDb-Liste.

- Radarr lehnt eine Listen-ID der Form `ls12345678` ab. Akzeptiert werden nur `top250`, `popular` oder eine Benutzer-Watchlist `ur12345678`.
- Sonarr akzeptiert die ID, bekommt dann aber eine leere Antwort von IMDb. Der Test-Button zeigt `Imdb call resulted in an unexpected StatusCode [Accepted]`.

[MDBList](https://mdblist.com) ist der Umweg für beide Probleme. Die Seite stellt jede Liste als JSON-Feed bereit, den beide Apps über ihren Typ Custom List einlesen. Filme und Serien liegen auf getrennten Listen, du fügst also eine zu jeder App hinzu.

## 1. Eine Liste auswählen {#1-pick-a-list}

Öffentliche Listen brauchen kein Konto. Suche auf MDBList nach dem Genre, das du willst, und öffne eine Liste. Zwei Horror-Listen, die Stand Oktober 2026 funktionieren:

| Liste | Enthält | Feed-URL |
|---|---|---|
| Horror | Filme | `https://mdblist.com/lists/garycrawfordgc/horror/json` |
| Horror Shows | Serien | `https://mdblist.com/lists/garycrawfordgc/horror-shows/json` |

Die Feed-URL ist die Seitenadresse der Liste mit `/json` am Ende. Öffne sie zuerst im Browser. Du solltest eine Textseite sehen, die mit `[{"id":` beginnt.

Um eine eigene Liste zu erstellen, melde dich bei MDBList an und lege eine neue an. Sie kann sich nach Filtern richten, etwa einem Genre und einer Mindestbewertung, oder eine IMDb-Liste kopieren, die du schon hast. Die Feed-URL funktioniert genauso.

## 2. In Radarr hinzufügen {#2-add-it-to-radarr}

**Settings → Import Lists → + → Custom Lists**

| Field | Value |
|---|---|
| Name | beliebig, zum Beispiel `Horror` |
| Enable | an |
| Enable Automatic Add | an |
| Search on Add | lies zuerst die Warnung unten |
| Monitor | Movie Only |
| Root Folder | dein Filme-Ordner innerhalb von `__magic__`, zum Beispiel `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` unter macOS, `Z:\__magic__\movies` unter Windows) |
| Quality Profile | das, das du benutzt |
| List URL | die URL des Film-Feeds |

Drück auf **Test** und dann auf **Save**.

## 3. In Sonarr hinzufügen {#3-add-it-to-sonarr}

**Settings → Import Lists → + → Custom List**

| Feld | Wert |
|---|---|
| Name | beliebig, zum Beispiel `Horror Shows` |
| Enable Automatic Add | an |
| Monitor | All Episodes, oder Pilot Episode, um eine Serie erst einmal auszuprobieren |
| Root Folder | dein TV-Ordner innerhalb von `__magic__`, zum Beispiel `/mnt/zurg/__magic__/tv` (auf macOS `/Volumes/Zurg/__magic__/tv`, unter Windows `Z:\__magic__\tv`) |
| Quality Profile | das, das du verwendest |
| Series Type | Standard |
| Season Folder | an |
| Search for Missing Episodes | lies zuerst die Warnung unten |
| List URL | die URL des Serien-Feeds |

Klick auf **Test** und dann auf **Save**.

## Große Listen holen alles auf einmal {#big-lists-grab-everything-at-once}

Eine Liste mit eingeschaltetem Search on add sucht jeden Titel in dem Moment, in dem sie synchronisiert wird. Die Filmliste oben enthält 400 Titel und die Serienliste 148 Serien mit allen Folgen. Das sind auf einmal sehr viele Suchanfragen. Dein Debrid-Konto und deine Indexer bekommen das deutlich zu spüren, und ein Indexer mit Rate-Limit fängt dann an, Suchanfragen abzulehnen.

Es gibt zwei sanftere Wege.

- Lass Search on add ausgeschaltet. Die Titel werden hinzugefügt und überwacht, aber nicht gesucht. Such die gewünschten Titel danach einzeln über die Seite Movies oder Series.
- Fang mit einer kurzen Liste an. Füge die große Liste erst hinzu, wenn der erste Schwung angekommen ist.

Die Apps synchronisieren Listen außerdem nach ihrem eigenen Zeitplan. **System → Tasks → Import List Sync** startet eine Synchronisierung sofort.

## Eine Liste entfernen {#removing-a-list}

Das Löschen einer Liste stoppt, dass neue Titel hereinkommen. Was sie bereits hinzugefügt hat, bleibt erhalten. Unter **Settings → Import Lists** entscheidet die **Clean Library Level**, was mit Titeln passiert, die von einer Liste verschwinden. Lass sie auf Disabled, außer du möchtest, dass die Apps Dinge für dich entfernen.
