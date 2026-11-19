# rex für Android {#rex-for-android}

rex ist ein Medienserver für die Plex-Apps, der selbst keine Dateien besitzt. rex für Android läuft auf einem Handy, Tablet, Android TV, Google TV oder Fire TV, ganz ohne Computer. Die Plex-Apps auf deinen Geräten finden ihn wie jeden anderen Plex-Server und spielen von dort ab.

Was abgespielt wird, kommt aus **Addons**. Los geht es mit den gemeinfreien Filmen des Internet Archive. Weitere Addons, etwa deine Stremio-Addons, YouTube und Spotify, installierst du direkt in der App, sobald du deren Repository hinzugefügt hast.

rex für Android ist kostenlos. Willst du deine Debrid-Konten und Usenet dort auch einbinden? zurg+rex, ein Plex-Server auf deinem Handy mit eingebautem zurg, gibt es gegen eine Sponsoring-Mitgliedschaft: siehe [zurg+rex für Android](../zurg/guides/android.md).

## Bevor du anfängst {#before-you-start}

| Du brauchst | Warum |
|---|---|
| Ein Gerät mit Android 8.0 oder neuer | Handy, Tablet, Android TV, Google TV oder Fire TV. Fire TVs mit Vega OS, wie der Fire TV Stick 4K Select, führen keine Android-Apps aus |
| Ein Plex-Konto | rex erscheint in den Plex-Apps, in denen du angemeldet bist. Ein kostenloses Konto reicht aus |
| Eine Plex-App auf dem Gerät, auf dem du schaust | Plex für Android, Android TV, iPhone, ein Smart-TV, Plex Web, Plexamp |

## Schritt 1: Die App holen {#step-1-get-the-app}

Wähle einen Weg. Jeder hält rex auf seine eigene Art auf dem neuesten Stand.

| Weg | Geeignet für |
|---|---|
| Google Play | Telefone, Tablets, Android TV und Google TV. Kommt bald |
| [Amazon Appstore](https://www.amazon.com/dp/B0HRQM5GGW) | Fire TV und Fire-Tablets |
| [Obtainium](#with-obtainium) | Telefone und Tablets. Es sagt dir Bescheid, wenn ein Update da ist |
| [Downloader](#with-downloader-on-fire-tv) | Fire TV und TV-Boxen |
| [Die Datei von GitHub](#the-file-from-github) | Jedes Gerät. Updates installierst du selbst |

**Die Wege lassen sich nicht mischen.** Google Play, der Amazon Appstore und die Datei von GitHub (die auch Obtainium und Downloader installieren) sind unterschiedlich signiert, daher kann das eine das andere nicht aktualisieren. Zum Wechseln deinstallierst du rex, führst Schritt 2 und 3 erneut aus und installierst deine Addons wieder.

**Sie starten mit unterschiedlichen Addons.** Die Datei von GitHub startet mit dem hinzugefügten [rex-addons](https://github.com/debridmediamanager/rex-addons)-Repository. Die Store-Versionen starten nur mit dem Internet-Archive-Addon; füge rex-addons selbst hinzu (siehe [Add-ons](#addons)), wenn du es willst.

### Mit Obtainium {#with-obtainium}

[Obtainium](https://obtainium.imranr.dev/) installiert Apps von GitHub und hält sie aktuell.

1. Installiere Obtainium und öffne es einmal.
2. Öffne auf demselben Gerät [rex.debridmediamanager.com/obtainium](https://rex.debridmediamanager.com/de/obtainium). Obtainium öffnet sich und fragt, ob du **Import app** ausführen willst. Tippe auf **Continue**.
3. Tippe auf **rex** und dann auf **Install**. Obtainium wählt die Datei für den Prozessor deines Geräts aus.
4. Beim ersten Mal öffnet Android **Install unknown apps** für Obtainium. Aktiviere **Allow from this source** und geh zurück.
5. Tippe auf **Install**. Wenn Play Protect **App scan recommended** anzeigt, tippe auf **Scan app** und dann auf **Install**.

Wenn eine neue Version erscheint, zeigt Obtainium neben rex **Update** an.

### Mit Downloader auf dem Fire TV {#with-downloader-on-fire-tv}

1. Auf dem Fire TV installierst du **Downloader** von AFTVnews aus dem Appstore.
2. Öffne die App, wähle das Adressfeld aus und gib den Code `6291659` (oder `rex.debridmediamanager.com/tv`) ein. Drücke auf **Next**. Dann wird `rex-android-armeabi-v7a.apk` heruntergeladen.
3. Drücke auf **Install**. Beim ersten Mal öffnet der Fire TV stattdessen **Developer options**. Wähle **Install unknown apps** und dann **Downloader**, damit dort **ON** steht. Drücke zweimal Zurück und dann noch einmal auf **Install**.
4. Drücke auf **Install** und dann auf **Open**.

Zum Aktualisieren führst du die Schritte 2 bis 4 einfach noch einmal aus.

### Die Datei von GitHub {#the-file-from-github}

Lade auf dem Gerät die Datei für den Prozessor herunter. Jeder Link zeigt immer auf die neueste Version:

| Dein Gerät | Download |
|---|---|
| Die meisten Handys, Tablets und TV-Boxen (64-bit) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| Fire TV und ältere oder günstigere 32-bit-Boxen | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| Emulatoren auf einem PC | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

Alle Versionen und ihre Änderungen findest du auf [der Releases-Seite](https://github.com/debridmediamanager/rex-android/releases). Du bist dir nicht sicher? Probier zuerst `arm64-v8a`. Eine Datei funktioniert auf Handys und Fernsehern gleichermaßen.

Öffne die heruntergeladene Datei. Android sagt, dass es **keine unbekannten Apps aus dieser Quelle installieren darf**. Tippe auf **Einstellungen**, aktiviere **Von dieser Quelle zulassen**, geh zurück und tippe auf **Installieren**.

Zum Aktualisieren installierst du die neue Datei einfach über die alte. rex startet dann von selbst neu, und deine Anmeldung und Add-ons bleiben erhalten.

**Was du sehen solltest.** **rex** in deiner Liste der Apps.

## Schritt 2: rex starten {#step-2-start-rex}

**rex** öffnen. Auf dem ersten Bildschirm steht **Welcome to rex.**

1. Auf **Allow notifications** tippen, dann auf **Allow**. rex läuft im Hintergrund mit einer Benachrichtigung, über die du es beenden kannst.
2. Auf **Let rex keep running in the background** tippen. In der Liste, die sich öffnet, **rex** auswählen und **Don't optimize** wählen. Bei neueren Android-Versionen heißt es **Allow background usage**, dann **Unrestricted**. Zurück zu rex gehen. Beide Schaltflächen beginnen jetzt mit einem ✓.
3. **Name** ist der Name, unter dem die Plex-Apps diesen Server anzeigen. Ändere ihn, wenn du möchtest.
4. **Port** auf `32400` belassen. Wenn auf diesem Gerät schon ein anderer Plex-Server läuft, zeigt rex **Another app here already uses this port, maybe a Plex server. Try 32500.** an. Dann `32500` eingeben.
5. Auf **Start rex** tippen.

**Das solltest du sehen.** **2 / 2** und **Sign in to Plex.**

| Der erste Bildschirm | Die Seite des Films in der Plex-App (Schritt 4) |
|---|---|
| ![Der erste Bildschirm von rex für Android mit den Feldern Name und Port und Start rex](../assets/rex/android-setup.webp) | ![Ein Stummfilm von 1916 aus dem Internet Archive auf seiner Seite in Plex für Android](../assets/rex/android-plex-film.webp) |

## Schritt 3: Bei Plex anmelden {#step-3-sign-in-to-plex}

Drücke **Sign in to Plex**. rex zeigt einen Code an: **On any phone or computer, go to plex.tv/link and enter** it.

- **Auf einem Handy oder Tablet** öffnet dein Browser außerdem eine Plex-Seite, auf der **rex for Android would like to sign in to your Plex account** steht. Melde dich dort an.
- **Auf einem Fernseher** rufe [plex.tv/link](https://plex.tv/link) auf deinem Handy oder Computer auf, melde dich an und gib den Code ein.

Nimm das Konto, mit dem deine Plex-Apps angemeldet sind. Du kannst **Skip for now** drücken und dich später über **Status** anmelden.

![rex for Android on a TV showing the code to enter at plex.tv/link](../assets/rex/android-tv-signin.webp)

**Was du sehen solltest.** **Signed in. rex shows up in the Plex apps as** den Namen deines Servers. Drücke **Done**. **Status** zeigt **RUNNING** und **Ready for the Plex apps.**

## Schritt 4: In einer Plex-App ansehen {#step-4-watch-in-a-plex-app}

Öffne eine beliebige Plex-App, die mit demselben Konto angemeldet ist. Wenn Plex auf diesem Gerät installiert ist, gibt es unter **Status** einen Button **Open Plex**.

In der Plex-App für Android öffnest du **Libraries**, dann **All Libraries** und darunter **Movies** unter dem Namen deines Servers. Andere Plex-Apps zeigen sie ebenfalls unter dem Namen des Servers an.

Die erste Synchronisierung des Internet Archive dauert eine Weile: etwa eine halbe Stunde auf unserem Testgerät, weil rex jeden Film prüft. **Status** zeigt **Syncing**, bis sie fertig ist, und danach die Anzahl, zum Beispiel **Ready · 97 titles**. Drück dann auf Play bei einem beliebigen Film.

![Die Plex-App auf einem TV, die einen Chaplin-Kurzfilm von 1914 aus rex auf demselben TV abspielt](../assets/rex/android-tv-playing.webp)

## Add-ons {#addons}

**Addons** listet alles auf, was du installiert hast. Jeder Addon zeigt seine Titel und wann er zuletzt synchronisiert wurde. Seine Schaltflächen sind **Sync now**, **Settings**, **Log** und **Remove**; auf dem Handy wischst du die Reihe der Schaltflächen seitlich, um alle zu sehen. Mit dem Schalter **Enabled** schaltest du einen Addon aus, ohne ihn zu entfernen.

Addons kommen aus **repositories**: Git-Repositories, in denen Addons liegen. Der Internet-Archive-Addon ist schon installiert. Für mehr füge [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons) hinzu (siehe unten **Add a repository**), das Folgendes bietet:

| Addon | Was er bringt |
|---|---|
| Stremio addons | Die Film- und Serienkataloge deiner Stremio-Addons, abgespielt über die Streams, die deine Stream-Addons liefern |
| YouTube | Deine YouTube-Playlists. Du meldest dich mit einem Code an |
| Spotify | Deine Spotify-Bibliothek als Musik für Plex und Plexamp. Benötigt den YouTube-Addon, angemeldet |

**Einen installieren.** Unter **Repositories** drückst du neben einem Repository auf **Addons** und dann unter dem Addon auf **Install**. rex zeigt dir, welche Websites es erreichen kann, und fragt noch einmal nach, dann startet die Synchronisierung.

**Anmelden.** Ein Addon, das dein Konto braucht, zeigt **Sign in to start.** an. Drück auf seine Schaltfläche **Sign in**: Geh auf der genannten Seite auf einem beliebigen Gerät und gib den angezeigten Code ein.

**Ein Repository hinzufügen.** Unter **Add a repository** tippst du den Link ein (`github.com/user/repo` reicht) und drückst auf **Add**. Installiere nur Addons von Leuten, denen du vertraust. Um selbst einen Addon zu schreiben, siehe [rex-addons](https://github.com/debridmediamanager/rex-addons).

## Auf anderen Geräten zu Hause ansehen {#watch-on-other-devices-at-home}

Jede Plex-App, die mit demselben Konto angemeldet ist, findet rex in deinem Heimnetzwerk anhand seines Namens: dein Fernseher, ein anderes Handy, Plex Web auf einem Computer. **Status** zeigt dir die Adresse von rex im Heimnetz, zum Beispiel `http://192.168.1.20:32400`.

Wenn du Familie und Freunde mit ihren eigenen Plex-Konten schauen lassen willst, lies [rex mit Familie und Freunden teilen](sharing.md).

## Im Dauerbetrieb lassen {#keep-it-running}

- rex läuft, solange das Gerät eingeschaltet ist. Mit **Stop** in der Benachrichtigung beendest du es; unter **Status** gibt es **Start**, **Stop** und **Restart**.
- Schalte in **Settings** die Option **Start when this device turns on** ein. Andernfalls öffnest du rex nach einem Neustart und drückst auf **Start**.
- Manche Handys beenden Hintergrund-Apps trotzdem. [Don't kill my app](https://dontkillmyapp.com/) erklärt, was deine App dafür braucht.
- Um den Server umzubenennen, öffne in einer Plex-App **Settings**, **General** und ändere **Friendly name**.

## Limits

- **Es läuft zu Hause.** Unterwegs brauchen die Plex-Apps eine HTTPS-Adresse, die das Gerät erreicht. Dafür muss an deinem Router eine Portweiterleitung auf das Gerät eingerichtet sein. Siehe [Use it outside your home](any-source.md#use-it-outside-your-home-optional).
- **Das Gerät ist der Server.** Lass es eingeschaltet, per WLAN oder Ethernet verbunden und am Strom. Wenn Videos für einen Player umgewandelt werden müssen, der eine Datei nicht abspielen kann, nutzt das die eigene Hardware des Geräts. Auf einem günstigen Gerät kann das langsam sein.
- **Nur das, was Addons liefern.** Auf dem Gerät selbst liegt keine Dateibibliothek.

## Fehlerbehebung {#troubleshooting}

| Was du siehst | Was du tun solltest |
|---|---|
| **App not installed as app isn't compatible with your phone.** | Du hast die falsche Datei für den Prozessor gewählt. Probier die andere aus der Tabelle unter [Die Datei von GitHub](#the-file-from-github) |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | Gib `32500` als Port ein |
| **Use a number from 1024 to 65535** | Der Port muss eine Zahl in diesem Bereich sein |
| Der Server ist nicht in der Plex-App | Melde die Plex-App mit demselben Konto an, das du in Schritt 3 benutzt hast, und lass beide Geräte im selben Heimnetzwerk |
| Die Bibliothek ist leer | Die erste Synchronisierung läuft noch: Warte, bis **Status** eine Anzahl an Titeln zeigt |
| **Sign in needed** under an addon | Drück auf den Button **Sign in** des Addons und gib den Code ein |
| **Needs an update** under an addon | Diese Version der App kann diese Kopie des Addons nicht mehr ausführen. Aktualisiere dessen Repository und drück auf **Update**. Die Titel bleiben in der Zwischenzeit erhalten |
| **That isn't a repository link. Try github.com/user/repo.** | Gib den Link des Repositorys ein, zum Beispiel `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | Der Link ist falsch oder das Repository ist privat. Prüf ihn im Browser |
| rex stoppt, wenn der Bildschirm aus ist | Stell die Hintergrund-Einstellung aus Schritt 2 noch einmal ein und schau dir [Don't kill my app](https://dontkillmyapp.com/) an |

**Logs** zeigt, was rex und die Addons zuletzt gemeldet haben, wobei Schlüssel und Passwörter verborgen sind. Wenn der Support nach Logs fragt, drück auf **Send logs to support**: Du siehst alles, bevor etwas gesendet wird. Drück dann auf **Send** und poste den Code, den du bekommst.

Was die App sendet und wohin, steht in der [Datenschutzerklärung](android-privacy.md).

Nicht weiter? Frag im Forum **rex-support** auf [Discord](https://discord.com/invite/7u4YjMThXP).
