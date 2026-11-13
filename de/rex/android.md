# rex für Android {#rex-for-android}

rex ist ein Medienserver für die Plex-Apps, der selbst keine Dateien besitzt. rex für Android betreibt ihn auf einem Handy, Tablet, Android TV, Google TV oder Fire TV, ganz ohne Computer. Die Plex-Apps auf deinen Geräten finden ihn wie jeden anderen Plex-Server und spielen von ihm ab.

Was abgespielt wird, kommt aus **Addons**. Den Anfang machen die gemeinfreien Filme des Internet Archive. Weitere Addons, etwa deine Stremio-Addons, YouTube und Spotify, installierst du direkt in der App.

rex für Android ist kostenlos. Möchtest du deine Debrid-Konten und Usenet ebenfalls einbinden? zurg+rex, ein Plex-Server auf deinem Handy mit eingebautem zurg, gibt es mit einer Sponsoring-Bedingung: siehe [zurg+rex für Android](../zurg/guides/android.md).

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

Öffne **rex**. Der erste Bildschirm zeigt **Welcome to rex.**

1. Tippe auf **Allow notifications** und dann auf **Allow**. rex läuft im Hintergrund mit einer Benachrichtigung, über die du es beenden kannst.
2. Tippe auf **Let rex keep running in the background**. Wähle in der Liste, die sich öffnet, **rex** aus und tippe auf **Don't optimize**. Auf neueren Android-Versionen heißt es **Allow background usage** und dann **Unrestricted**. Geh zurück zu rex. Beide Schaltflächen beginnen jetzt mit einem ✓.
3. **Name** ist der Name, den die Plex-Apps für diesen Server anzeigen. Ändere ihn, wenn du möchtest.
4. Lass **Port** bei `32400`. Läuft auf diesem Gerät bereits ein anderer Plex-Server, zeigt rex **Another app here already uses this port, maybe a Plex server. Try 32500.** an. Gib `32500` ein.
5. Tippe auf **Start rex**.

**Das solltest du sehen.** **2 / 2** und **Sign in to Plex.**

## Schritt 4. Bei Plex anmelden {#step-4-sign-in-to-plex}

Drücke **Sign in to Plex**. rex zeigt einen Code: **On any phone or computer, go to plex.tv/link and enter** es.

- **Auf einem Handy oder Tablet** öffnet dein Browser außerdem eine Plex-Seite, auf der **rex for Android would like to sign in to your Plex account** steht. Melde dich dort an.
- **Auf einem TV** gehe auf deinem Handy oder Computer zu [plex.tv/link](https://plex.tv/link), melde dich an und gib den Code ein.

Nimm das Konto, mit dem deine Plex-Apps angemeldet sind. Du kannst **Skip for now** drücken und dich später unter **Status** anmelden.

**Was du sehen solltest.** **Signed in. rex shows up in the Plex apps as** der Name deines Servers. Drücke **Done**. **Status** zeigt **RUNNING** und **Ready for the Plex apps.**

## Schritt 5. In einer Plex-App ansehen {#step-5-watch-in-a-plex-app}

Öffne eine beliebige Plex-App, die mit demselben Konto angemeldet ist. Wenn Plex auf diesem Gerät installiert ist, gibt es unter **Status** einen Button **Open Plex**.

Öffne in der Plex-App für Android **Libraries** und dann **All Libraries**. Darunter findest du **Movies** unter dem Namen deines Servers. Andere Plex-Apps zeigen sie ebenfalls unter dem Namen des Servers an.

Die erste Synchronisierung des Internet Archive dauert eine Weile: etwa eine halbe Stunde auf unserem Testgerät, während rex jeden Film prüft. **Status** zeigt **Syncing**, bis sie fertig ist, und danach die Anzahl, zum Beispiel **Ready · 97 titles**. Drück auf Play bei einem beliebigen Film.

## Add-ons {#addons}

**Addons** listet auf, was du installiert hast. Jeder zeigt seine Titel und wann er zuletzt synchronisiert wurde. Die Buttons heißen **Sync now**, **Settings**, **Log** und **Remove**; auf dem Handy wischst du die Buttonzeile seitlich, um alle zu sehen. Mit dem Schalter **Enabled** schaltest du einen Addon aus, ohne ihn zu entfernen.

Addons kommen aus **repositories**: Git-Repositories, die Addons enthalten. Die App hat bereits [rex-addons](https://github.com/debridmediamanager/rex-addons) hinzugefügt, das Folgendes anbietet:

| Addon | Was es bringt |
|---|---|
| Internet Archive | Filme ohne Urheberrecht. Ist von Anfang an installiert |
| Stremio addons | Die Film- und Serien-Kataloge deiner Stremio-Addons, abgespielt von den Streams, die deine Stream-Addons liefern |
| YouTube | Deine YouTube-Playlists. Du meldest dich mit einem Code an |
| Spotify | Deine Spotify-Bibliothek als Musik für Plex und Plexamp. Braucht das YouTube-Addon, angemeldet |

**Ein Addon installieren.** Unter **Repositories** drückst du neben einem Repository auf **Addons** und dann unter dem Addon auf **Install**. rex zeigt dir, welche Websites es erreichen kann, und fragt noch einmal nach. Dann startet die Synchronisierung.

**Anmelden.** Ein Addon, das dein Konto braucht, zeigt **Sign in to start.** an. Drück auf seinen Button **Sign in**: Geh auf der genannten Seite auf einem beliebigen Gerät und gib den angezeigten Code ein.

**Ein Repository hinzufügen.** Unter **Add a repository** tippst du den Link ein (`github.com/user/repo` reicht) und drückst auf **Add**. Installiere nur Addons von Leuten, denen du vertraust. Wenn du dein eigenes Addon schreiben willst, schau dir [rex-addons](https://github.com/debridmediamanager/rex-addons) an.

## Auf anderen Geräten zu Hause ansehen {#watch-on-other-devices-at-home}

Jede Plex-App, die mit demselben Konto angemeldet ist, findet rex in deinem Heimnetzwerk anhand seines Namens: dein Fernseher, ein anderes Handy, Plex Web auf einem Computer. **Status** zeigt dir die Adresse von rex im Heimnetz, zum Beispiel `http://192.168.1.20:32400`.

Wenn du Familie und Freunde mit ihren eigenen Plex-Konten schauen lassen willst, lies [Share rex with family and friends](sharing.md).

## Im Dauerbetrieb lassen {#keep-it-running}

- rex läuft, solange das Gerät eingeschaltet ist. Mit **Stop** in der Benachrichtigung beendest du es; unter **Status** gibt es **Start**, **Stop** und **Restart**.
- Schalte in **Settings** die Option **Start when this device turns on** ein. Andernfalls öffnest du rex nach einem Neustart und drückst auf **Start**.
- Manche Handys beenden Hintergrund-Apps trotzdem. [Don't kill my app](https://dontkillmyapp.com/) erklärt, was deine App dafür braucht.
- Um den Server umzubenennen, öffne in einer Plex-App **Settings**, **General** und ändere **Friendly name**.

## Limits

- **Es läuft zu Hause.** Außerhalb deines Zuhauses brauchen die Plex-Apps eine HTTPS-Adresse, die das Gerät erreicht. Dafür musst du an deinem Router eine Portweiterleitung auf das Gerät einrichten. Siehe [Use it outside your home](any-source.md#use-it-outside-your-home-optional).
- **Das Gerät ist der Server.** Lass es eingeschaltet, per WLAN oder Ethernet verbunden und am Strom. Wenn Video für einen Player umgewandelt werden muss, der eine Datei nicht abspielen kann, nutzt das die eigene Hardware des Geräts. Bei einem günstigen Gerät kann das langsam sein.
- **Nur was die Addons liefern.** Auf dem Gerät selbst liegt keine Dateibibliothek.
- **Noch nicht im Google Play Store.** Zum Aktualisieren installierst du die neue Datei aus [den Releases](https://github.com/debridmediamanager/rex-android/releases/latest) über die alte. Danach öffnest du rex und tippst auf **Start**. Deine Anmeldung und deine Addons bleiben erhalten.

## Fehlerbehebung {#troubleshooting}

| Was du siehst | Was zu tun ist |
|---|---|
| **App not installed as app isn't compatible with your phone.** | Du hast die falsche Datei für den Prozessor gewählt. Probier die andere aus der Tabelle in Schritt 1 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | Gib `32500` als Port ein |
| **Use a number from 1024 to 65535** | Der Port muss eine Zahl in diesem Bereich sein |
| The server isn't in the Plex app | Melde die Plex-App mit demselben Konto an, das du in Schritt 4 benutzt hast, und lass beide Geräte im selben Heimnetzwerk |
| The library is empty | Die erste Synchronisierung läuft noch: warte, bis **Status** eine Anzahl an Titeln anzeigt |
| **Sign in needed** under an addon | Drück auf dessen Button **Sign in** und gib den Code ein |
| **That isn't a repository link. Try github.com/user/repo.** | Gib den Link zum Repository ein, zum Beispiel `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | Der Link ist falsch oder das Repository ist privat. Prüf ihn im Browser |
| rex stops when the screen is off | Stell die Hintergrund-Einstellung aus Schritt 3 noch mal ein und schau dir [Don't kill my app](https://dontkillmyapp.com/) an |

**Logs** zeigt, was rex und die Addons zuletzt gemeldet haben, mit ausgeblendeten Keys und Passwörtern. Wenn der Support nach Logs fragt, drück auf **Send logs to support**: Du siehst alles, bevor etwas gesendet wird. Dann drück auf **Send** und poste den Code, den du bekommst.

Nicht weiterkommen? Frag im Forum **rex-support** auf [Discord](https://discord.com/invite/7u4YjMThXP).
