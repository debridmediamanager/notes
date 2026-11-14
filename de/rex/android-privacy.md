# rex für Android: Datenschutzerklärung {#rex-for-android-privacy-policy}

*Zuletzt aktualisiert: 14. November 2026.*

rex für Android betreibt einen Medienserver auf deinem Gerät. Es gibt dafür bei uns kein Konto, keine Werbung und keine Analysen, und es sendet uns weder deine Bibliothek, dein Seh-Verhalten noch sonst etwas über dich, außer bei rex-direct und den Protokollen, die du selbst senden möchtest, beide weiter unten genannt.

## Was dein Gerät verlässt und wohin es geht {#what-leaves-your-device-and-where-it-goes}

| Wo | Was | Wann |
|---|---|---|
| **plex.tv** (Plex, Inc.) | Eine Anfrage für einen Anmeldecode mit einer zufälligen App-Kennung und dem Namen dieses Servers; danach, nachdem du sie bestätigt hast, eine einmalige Anfrage für einen Claim-Code | Wenn du Sign in to Plex auswählst |
| **plex.tv** | Der Name, die Kennung und die Version des Servers sowie die Adressen, unter denen die Plex-Apps ihn erreichen können | Während rex läuft und angemeldet ist, so wie jeder Plex-Server sich selbst meldet |
| **Plex's metadata service** | Die IDs der Titel, die deine Addons hinzufügen, um Poster und Beschreibungen abzurufen | Während rex läuft und angemeldet ist |
| **debridmediamanager.com** (rex-direct) | Die Kennung des Servers, das Server-Token, das Plex ihm gegeben hat, seine lokalen und öffentlichen IP-Adressen und sein Port | Nach der Anmeldung, danach alle 6 Stunden, damit die Plex-Apps rex auch außerhalb des Heimnetzes über HTTPS erreichen können |
| **logs.debridmediamanager.com** (support logs) | Die Versionen der App und von rex, das Gerätemodell, die Android-Version und der Prozessortyp, Port und Status von rex, für jedes Addon Name, Version, Repository, Status, Anzahl der Titel, letzte Synchronisierung und letzter Fehler, die Zeitzonen-Abweichung sowie die Logs der App von diesem und dem vorherigen Lauf, wobei Tokens, Schlüssel, Passwörter und die letzten beiden Teile öffentlicher IP-Adressen ausgeblendet werden. Niemals deine Addon-Einstellungen, dein Plex-Konto oder Tokens | Nur wenn du unter Send logs to support auf Send drückst, nachdem du alles gesehen hast. Du bekommst einen Code für den Support; nur Support-Mitarbeiter können ihn einsehen, und er wird nach 7 Tagen gelöscht |
| **Addon repositories you add** (such as github.com) | Eine Anfrage nach den Inhalten des Repositorys | Wenn du ein Repository hinzufügst oder aktualisierst |
| **Each addon's sites** | Was das Addon anfragt, zum Beispiel eine Katalogabfrage bei archive.org | Wenn ein Addon sich synchronisiert oder ein Titel abgespielt wird |

Dein Plex-Kontopasswort gelangt nie über die App: Du meldest dich auf Plex' eigener Seite an. Das Konto-Token, das die Anmeldung der App gibt, wird einmal verwendet, um den Server zu beanspruchen, und danach verworfen. rex behält nur das Server-Token, das Plex dafür ausstellt.

## Was auf deinem Gerät bleibt {#what-stays-on-your-device}

Deine Bibliotheken, der Wiedergabeverlauf, die Addon-Einstellungen (einschließlich aller Schlüssel, die du eingegeben hast) und die Logs. Die App behält die Logs dieses Durchlaufs und des vorherigen, damit ein Absturz sie nicht verliert. Logs verbergen Tokens, Schlüssel, Passwörter und den hinteren Teil öffentlicher IP-Adressen. Sie verlassen das Gerät nur, wenn du auf der Logs-Seite Share oder Send logs to support wählst. Beim Deinstallieren der App wird alles davon gelöscht.

## Add-ons {#addons}

Ein Addon ist Code von der Person, die es geschrieben hat. Es wird aus einem Repository installiert, das du hinzugefügt hast. Es läuft abgeschottet vom restlichen Gerät und kann nur die Seiten erreichen, die es nennt. rex zeigt dir diese Seiten, bevor du das Addon installierst. Installiere Addons nur von Leuten, denen du vertraust.

Ein Addon, das ein Konto auf der Website braucht, etwa YouTube, meldet sich mit einem Code an. Du gibst den Code auf der eigenen Seite der Website ein, deshalb geht dein Passwort nie durch die App. Der Token, den die Website dem Addon danach gibt, bleibt auf deinem Gerät und wird nur an diese Website zurückgeschickt. Wenn du das Addon entfernst, wird er gelöscht.

## Kinder {#children}

Die App richtet sich nicht an Kinder.

## Kontakt {#contact}

support@debridmediamanager.com
