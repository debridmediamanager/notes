# Musik mit rex {#music-with-rex}

rex kann eine Musikbibliothek für Plexamp, Plex Web und Plex für Android bereitstellen. Ein Musik-Addon schickt jeden Song und sein
MusicBrainz-Release. Plex ergänzt Namen, Cover, Künstlerdetails, Genres und ähnliche Künstler.

Das bekommst du:

- **Alben, die Plex kennt.** Ein Album, das mit seinem MusicBrainz-Release gesendet wird, sieht so aus wie auf jedem Plex-Server, mit Plex-Cover und Titelnamen. Ein Album, das Plex nicht kennt, zeigt die Namen und Bilder, die das Addon schickt.
- **Originalqualität.** Songs werden in ihrem eigenen Format abgespielt, zum Beispiel FLAC.
- **Liedtexte und Lautheit**, wenn das Addon sie mitschickt: Liedtexte werden zusammen mit dem Song angezeigt, und rex gibt die Lautheit jedes Songs an die Apps weiter, so wie Plex es tut.
- **Deine eigenen Wiedergaben und Playlists.** Wiedergaben, Bewertungen und Playlists werden pro Plex-Konto gespeichert. Plexamp erstellt seine Smart Playlists auch auf rex.

## Bevor du anfängst {#before-you-start}

| Du brauchst | Warum |
|---|---|
| Ein rex-Nightly mit Datum 2026.11.02 oder neuer | Musik kam mit diesem Build dazu |
| rex eingerichtet wie in [rex mit deiner eigenen App](any-source.md) | Dort erscheint die Musikbibliothek |
| Ein Musik-Addon | Jedes Programm, das Songs über den Feed-API von rex schickt. Für einen Ordner mit Alben auf deinen eigenen Festplatten ist [Tutorial: ein Musik-Addon](addon-music.md) ein vollständiges Beispiel in einer einzigen Python-Datei |
| [Video konvertieren](any-source.md#converting-video-optional), optional | rex konvertiert einen Song nur dann, wenn eine App auf eine niedrigere Musikqualität als das Original eingestellt ist |

## Schritt 1: rex installieren und zu einem Plex-Konto hinzufügen {#step-1-install-rex-and-add-it-to-a-plex-account}

Folge [rex mit deiner eigenen App](any-source.md):

1. [Schritt 1. rex installieren](any-source.md#step-1-install-rex), inklusive dem Finden von rex' LAN-IP. Auf dieser Seite steht sie als `192.168.1.20`: Trage stattdessen deine eigene ein.
2. [Schritt 3. Zu einem Plex-Konto hinzufügen](any-source.md#step-3-add-it-to-a-plex-account): Registriere rex auf dem neuen Konto und teile es mit deinem eigenen.

## Schritt 2. Richte dein Musik-Addon auf rex aus {#step-2-point-your-music-addon-at-rex}

rex braucht eine Musikbibliothek für die Songs. Wenn dein Addon eine deklariert, legt rex sie an, sobald sich das Addon registriert. Wenn nicht, erstelle zuerst eine in einer Plex-App, die mit dem neuen Account angemeldet ist: **Add Library**, **Music**, ein beliebiger Ordner. Ein Song, der gesendet wird, bevor es eine Musikbibliothek gibt, wird abgelehnt.

Dann gib deinem Addon rex' Adresse, `http://192.168.1.20:32400`, so wie es in seiner eigenen Anleitung steht. Es registriert sich bei rex und sendet seine Alben.

**Was du sehen solltest.** Im rex-Log:

```
INFO    SOURCES PUT /rex/sources/<addon> -> 200
INFO    SECTION create Music (artist) for <addon>'s music
INFO    FEED <addon> upsert: ...
```

Die Zeile `SECTION create` erscheint nur, wenn das Addon die Bibliothek deklariert. Die Musikbibliothek taucht in rex auf, mit jedem Album unter seinem Künstler. Ein Song, den rex ablehnt, steht mit Grund im Log, zum Beispiel `no music library holds <file>`.

## Schritt 3. Teile die Musikbibliothek {#step-3-share-the-music-library}

Die Musikbibliothek ist neu, daher ist sie noch in keiner Freigabe. Melde dich mit dem neuen Konto an und füge sie in **Manage Library Access** zu deinem eigenen Konto und allen anderen Konten hinzu ([rex freigeben](sharing.md)).

## Schritt 4. Hör rein {#step-4-listen}

- **Plexamp**: Melde dich mit deinem eigenen Plex-Konto an und wähle die Musikbibliothek von rex als deine Bibliothek aus.
- **Plex Web und Plex für Android**: Die Musikbibliothek findest du zusammen mit den anderen Bibliotheken von rex.

**Was du sehen solltest.** Die Alben mit Plex-Covern und Titelnamen sowie der Künstler mit einem Foto. Drück auf Play.

## Was es nicht kann {#what-it-cannot-do}

- **Kein Radio, keine Mixe und keine Stationen.** Plexamps Radio, Mixe, Stationen und klanglich ähnliche Songs brauchen eine Analyse jedes Songs, und die macht rex nicht.
- **Kein eigener Musikordner.** rex scannt nichts und liest keine Tags. Ein Addon muss jeden Song schicken, zusammen mit dem MusicBrainz-Release seines Albums, damit Plex ihn benennen kann.
- **Zwei Kopien eines Albums sind zwei Alben**, wie auf jedem Plex-Server: Eine FLAC-Kopie und eine MP3-Kopie werden jeweils als eigenes Album angezeigt.
- **Getestet in Plexamp, Plex Web und Plex for Android.** Andere Plex-Apps und Plexamps Offline-Downloads wurden noch nicht ausprobiert.

Um dein eigenes Musik-Addon zu schreiben, fang mit [Tutorial: ein Musik-Addon](addon-music.md) an; unter [Rex-Addons bauen](addons.md#music) findest du jedes Feld.
