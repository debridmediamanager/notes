# rex für Android {#rex-for-android}

rex ist ein Medienserver für die Plex-Apps, der selbst keine Dateien besitzt. rex für Android läuft auf einem Handy, Tablet, Android TV, Google TV oder Fire TV, ganz ohne Computer. Die Plex-Apps auf deinen Geräten finden ihn wie jeden anderen Plex-Server und spielen von dort ab.

Was abgespielt wird, kommt aus **Addons**. Los geht es mit den gemeinfreien Filmen des Internet Archive. Weitere Addons, etwa deine Stremio-Addons, YouTube und Spotify, installierst du direkt in der App, sobald du deren Repository hinzugefügt hast.

rex für Android ist kostenlos. Willst du deine Debrid-Konten und Usenet dort auch einbinden? zurg+rex, ein Plex-Server auf deinem Handy mit eingebautem zurg, gibt es gegen eine Sponsoring-Mitgliedschaft: siehe [zurg+rex für Android](../zurg/guides/android.md).

## Bevor du anfängst {#before-you-start}

| Du brauchst | Warum |
|---|---|
| Ein Gerät mit Android 8.0 oder neuer | Handy, Tablet, Android TV, Google TV oder Fire TV |
| Ein Plex-Konto | rex erscheint in den Plex-Apps, in denen du angemeldet bist. Ein kostenloses Konto reicht |
| Eine Plex-App auf dem Gerät, auf dem du schaust | Plex für Android, Android TV, iPhone, ein Smart-TV, Plex Web, Plexamp |

Die App ist noch nicht im Google Play Store. Du installierst die App-Datei (APK) selbst.

## Schritt 1. Herunterladen {#step-1-download-it}

| Dein Gerät | Download |
|---|---|
| Die meisten Handys, Tablets und TV-Boxen (64-Bit) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| Ältere oder günstigere 32-Bit-Boxen, darunter Fire TV Sticks | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| Emulatoren auf einem PC | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

Auf dem Gerät lädst du die Datei für den Prozessor herunter. Jeder Link zeigt immer auf die neueste Version.

Alle Versionen und ihre Änderungen findest du auf [der Releases-Seite](https://github.com/debridmediamanager/rex-android/releases).

Du bist dir nicht sicher? Probier zuerst `arm64-v8a` aus. Eine Datei funktioniert auf Handys und TVs gleichermaßen.

## Schritt 2. Installieren {#step-2-install-it}

Öffne die heruntergeladene Datei. Android fragt zuerst:

1. Es heißt, dass **Installation unbekannter Apps aus dieser Quelle nicht erlaubt ist**. Drücke auf **Einstellungen**, aktiviere **Von dieser Quelle zulassen** und geh zurück.
2. Drücke auf **Installieren**.

Auf einer TV-Box ohne Browser lädst du die Datei mit einer Downloader-App herunter, die APK-Dateien öffnen kann.

**Was du sehen solltest.** **rex** in deiner App-Liste.

## Schritt 3. rex starten {#step-3-start-rex}

**Öffne rex.** Der erste Bildschirm zeigt **Welcome to rex.**

1. Tippe auf **Allow notifications** und dann auf **Allow**. rex läuft im Hintergrund mit einer Benachrichtigung, über die du es beenden kannst.
2. Tippe auf **Let rex keep running in the background**. Wähle in der Liste, die sich öffnet, **rex** aus und tippe auf **Don't optimize**. Auf neueren Android-Versionen heißt es **Allow background usage**, dann **Unrestricted**. Geh zurück zu rex. Beide Schaltflächen beginnen jetzt mit einem ✓.
3. **Name** ist der Name, unter dem die Plex-Apps diesen Server anzeigen. Ändere ihn, wenn du möchtest.
4. Lass **Port** auf `32400`. Läuft auf diesem Gerät bereits ein anderer Plex-Server, zeigt rex **Another app here already uses this port, maybe a Plex server. Try 32500.** an. Gib `32500` ein.
5. Tippe auf **Start rex**.

**Was du sehen solltest.** **2 / 2** und **Sign in to Plex.**

| Der erste Bildschirm | Die Seite des Films in der Plex-App (Schritt 5) |
|---|---|
| ![Der erste Bildschirm von rex für Android mit den Feldern Name und Port und Start rex](../assets/rex/android-setup.webp) | ![Ein Stummfilm von 1916 aus dem Internet Archive auf seiner Seite in Plex für Android](../assets/rex/android-plex-film.webp) |

## Schritt 4. Bei Plex anmelden {#step-4-sign-in-to-plex}

Drücke **Sign in to Plex**. rex zeigt einen Code an: **On any phone or computer, go to plex.tv/link and enter** it.

- **Auf einem Handy oder Tablet** öffnet dein Browser außerdem eine Plex-Seite, auf der **rex for Android would like to sign in to your Plex account** steht. Melde dich dort an.
- **Auf einem Fernseher** rufe [plex.tv/link](https://plex.tv/link) auf deinem Handy oder Computer auf, melde dich an und gib den Code ein.

Nimm das Konto, mit dem deine Plex-Apps angemeldet sind. Du kannst **Skip for now** drücken und dich später über **Status** anmelden.

![rex for Android on a TV showing the code to enter at plex.tv/link](../assets/rex/android-tv-signin.webp)

**Was du sehen solltest.** **Signed in. rex shows up in the Plex apps as** den Namen deines Servers. Drücke **Done**. **Status** zeigt **RUNNING** und **Ready for the Plex apps.**

## Schritt 5. In einer Plex-App ansehen {#step-5-watch-in-a-plex-app}

Öffne eine beliebige Plex-App, die mit demselben Konto angemeldet ist. Wenn Plex auf diesem Gerät installiert ist, gibt es unter **Status** einen Button **Open Plex**.

In der Plex-App für Android öffnest du **Libraries**, dann **All Libraries** und darunter **Movies** unter dem Namen deines Servers. Andere Plex-Apps zeigen sie ebenfalls unter dem Namen des Servers an.

Die erste Synchronisierung des Internet Archive dauert eine Weile: etwa eine halbe Stunde auf unserem Testgerät, weil rex jeden Film prüft. **Status** zeigt **Syncing**, bis sie fertig ist, und danach die Anzahl, zum Beispiel **Ready · 97 titles**. Drück dann auf Play bei einem beliebigen Film.

![Die Plex-App auf einem TV, die einen Chaplin-Kurzfilm von 1914 aus rex auf demselben TV abspielt](../assets/rex/android-tv-playing.webp)

## Add-ons {#addons}

**Addons** listet alles auf, was du installiert hast. Jeder zeigt seine Titel und wann er zuletzt synchronisiert wurde. Die Buttons sind **Sync now**, **Settings**, **Log** und **Remove**; auf dem Handy kannst du die Buttonleiste seitlich wischen, um alle zu sehen. Mit dem Schalter **Enabled** schaltest du einen Addon aus, ohne ihn zu entfernen.

Addons kommen aus **repositories**: Git-Repositories, die Addons enthalten. Die App hat [rex-addons](https://github.com/debridmediamanager/rex-addons) schon von Anfang an hinzugefügt. Es bietet die gemeinfreien Filme des Internet Archive, die direkt installiert sind. Für mehr füge [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons) hinzu (siehe unten **Add a repository**). Es bietet:

| Addon | Was es bringt |
|---|---|
| Stremio addons | Die Film- und Serienkataloge deiner Stremio-Addons, abgespielt über die Streams, die deine Stream-Addons liefern |
| YouTube | Deine YouTube-Playlists. Du meldest dich mit einem Code an |
| Spotify | Deine Spotify-Bibliothek als Musik für Plex und Plexamp. Braucht das YouTube-Addon, angemeldet |

**Installieren.** Unter **Repositories** drückst du neben einem Repository auf **Addons** und dann unter dem Addon auf **Install**. rex zeigt dir, welche Websites es erreichen kann, und fragt noch einmal nach. Danach beginnt die Synchronisierung.

**Anmelden.** Ein Addon, das dein Konto braucht, zeigt **Sign in to start.** Drück auf seinen Button **Sign in**: Ruf auf einem beliebigen Gerät die Seite auf, die dort genannt wird, und gib den angezeigten Code ein.

**Ein Repository hinzufügen.** Unter **Add a repository** tippst du seinen Link ein (`github.com/user/repo` reicht) und drückst auf **Add**. Installiere nur Addons von Leuten, denen du vertraust. Um dein eigenes Addon zu schreiben, schau dir [rex-addons](https://github.com/debridmediamanager/rex-addons) an.

## Auf anderen Geräten zu Hause ansehen {#watch-on-other-devices-at-home}

Jede Plex-App, die mit demselben Konto angemeldet ist, findet rex in deinem Heimnetzwerk anhand seines Namens: dein Fernseher, ein anderes Handy, Plex Web auf einem Computer. **Status** zeigt dir die Adresse von rex im Heimnetz, zum Beispiel `http://192.168.1.20:32400`.

Wenn du Familie und Freunde mit ihren eigenen Plex-Konten schauen lassen willst, lies [Share rex with family and friends](sharing.md).

## Im Dauerbetrieb lassen {#keep-it-running}

- rex läuft, solange das Gerät eingeschaltet ist. Mit **Stop** in der Benachrichtigung beendest du es; unter **Status** gibt es **Start**, **Stop** und **Restart**.
- Schalte in **Settings** die Option **Start when this device turns on** ein. Andernfalls öffnest du rex nach einem Neustart und drückst auf **Start**.
- Manche Handys beenden Hintergrund-Apps trotzdem. [Don't kill my app](https://dontkillmyapp.com/) erklärt, was deine App dafür braucht.
- Um den Server umzubenennen, öffne in einer Plex-App **Settings**, **General** und ändere **Friendly name**.

## Limits

- **Es läuft zu Hause.** Unterwegs brauchen Plex-Apps eine HTTPS-Adresse, die das Gerät erreicht. Dafür musst du in deinem Router eine Portweiterleitung zu diesem Gerät einrichten. Siehe [Use it outside your home](any-source.md#use-it-outside-your-home-optional).
- **Das Gerät ist der Server.** Lass es eingeschaltet, per WLAN oder Ethernet verbunden und am Strom. Wenn Video für einen Player umgewandelt werden muss, der eine Datei nicht abspielen kann, nutzt das die eigene Hardware des Geräts. Auf einem günstigen Gerät kann das langsam sein.
- **Nur was Addons liefern.** Auf dem Gerät selbst liegt keine Dateibibliothek.
- **Noch nicht im Google Play Store.** Zum Aktualisieren installierst du die neue Datei aus [den Releases](https://github.com/debridmediamanager/rex-android/releases/latest) über die alte. rex startet danach von selbst neu. Deine Anmeldung und deine Addons bleiben erhalten.

## Fehlerbehebung {#troubleshooting}

| Was du siehst | Was du tun solltest |
|---|---|
| **App not installed as app isn't compatible with your phone.** | Du hast die falsche Datei für den Prozessor gewählt. Probiere die andere aus der Tabelle in Schritt 1 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | Gib `32500` als Port ein |
| **Use a number from 1024 to 65535** | Der Port muss eine Zahl in diesem Bereich sein |
| Der Server erscheint nicht in der Plex-App | Melde die Plex-App mit demselben Konto an, das du in Schritt 4 verwendet hast, und stelle sicher, dass beide Geräte im selben Heimnetzwerk sind |
| Die Bibliothek ist leer | Die erste Synchronisierung läuft noch: Warte, bis **Status** eine Anzahl an Titeln anzeigt |
| **Sign in needed** unter einem Addon | Drücke auf dessen **Sign in**-Schaltfläche und gib den Code ein |
| **Needs an update** unter einem Addon | Diese Version der App kann diese Version des Addons nicht mehr ausführen. Aktualisiere dessen Repository und drücke auf **Update**. Die Titel bleiben in der Zwischenzeit erhalten |
| **That isn't a repository link. Try github.com/user/repo.** | Gib den Link zum Repository ein, zum Beispiel `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | Der Link ist falsch oder das Repository ist privat. Prüfe ihn in einem Browser |
| rex stoppt, wenn der Bildschirm aus ist | Richte die Hintergrundeinstellung aus Schritt 3 erneut ein und lies dir [Beende meine App nicht](https://dontkillmyapp.com/) durch |

**Logs** zeigt, was rex und die Addons zuletzt gemeldet haben, wobei Schlüssel und Passwörter verborgen sind. Wenn der Support nach Logs fragt, drücke auf **Send logs to support**: Du siehst alles, bevor etwas gesendet wird. Drücke dann auf **Send** und poste den Code, den du bekommst.

Was die App sendet und wohin, steht in der [Datenschutzerklärung](android-privacy.md).

Hängst du fest? Frag im Forum **rex-support** auf [Discord](https://discord.com/invite/7u4YjMThXP).
