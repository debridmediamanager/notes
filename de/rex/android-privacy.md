# rex für Android: Datenschutzerklärung {#rex-for-android-privacy-policy}

*Zuletzt aktualisiert: 16. November 2026.*

rex für Android betreibt auf deinem Gerät einen Medienserver. Es gibt dafür kein Konto bei uns, keine Werbung und keine Analyse. Wir erhalten weder deine Bibliothek noch deine Wiedergabe oder sonstige Informationen über dich. Eine Ausnahme bilden rex-direct und die Logs, die du absichtlich an uns schickst; beide werden unten genannt.

## Was dein Gerät verlässt und wohin es geht {#what-leaves-your-device-and-where-it-goes}

| Wo | Was | Wann |
|---|---|---|
| **plex.tv** (Plex, Inc.) | Eine Anfrage für einen Anmeldecode (auf einem Telefon oder Tablet, ein zweiter für Plex' Anmeldeseite) mit einer zufälligen App-Kennung und dem Namen dieses Servers; danach, sobald Sie eine davon bestätigen, eine einmalige Anfrage für einen Claim-Code | Wenn Sie Sign in to Plex wählen |
| **plex.tv** | Der Name des Servers, seine Kennung, seine Version und die Adressen, unter denen die Plex-Apps ihn erreichen können | Während rex läuft und angemeldet ist, so wie jeder Plex-Server sich selbst meldet |
| **Plex' Metadatendienst** | Die IDs der Titel, die Ihre Addons hinzufügen, um Poster und Beschreibungen abzurufen | Während rex läuft und angemeldet ist |
| **debridmediamanager.com** (rex-direct) | Die Kennung des Servers, das Server-Token, das Plex ihm gegeben hat, seine lokalen und öffentlichen IP-Adressen und sein Port | Nach der Anmeldung, dann alle 6 Stunden, damit die Plex-Apps rex auch von unterwegs per HTTPS erreichen können |
| **logs.debridmediamanager.com** (Support-Logs) | Die Versionen der App und von rex, das Gerätemodell, die Android-Version und der Prozessortyp, Port und Status von rex, für jedes Addon Name, Version, Repository, Status, Anzahl der Titel, letzte Synchronisierung und letzter Fehler, der Zeitzonenversatz sowie die Logs der App von diesem und dem vorherigen Lauf, wobei Tokens, Schlüssel, Passwörter und die letzten beiden Teile öffentlicher IP-Adressen ausgeblendet werden. Niemals Ihre Addon-Einstellungen, Ihr Plex-Konto oder Tokens | Nur wenn Sie unter Send logs to support auf Send drücken, nachdem Sie alles gesehen haben. Sie erhalten einen Code für den Support; nur Support-Mitarbeiter können ihn lesen, und er wird nach 7 Tagen gelöscht |
| **Addon-Repositories, die Sie hinzufügen** (etwa github.com) | Eine Anfrage nach den Inhalten des Repositorys | Wenn Sie ein Repository hinzufügen oder aktualisieren |
| **Die Seiten jedes Addons** | Was das Addon anfragt, etwa eine Katalogabfrage bei archive.org | Wenn ein Addon synchronisiert oder ein Titel abgespielt wird |

Ihr Plex-Kontopasswort gelangt nie über die App: Sie melden sich auf Plex' eigener Seite an. Das Konto-Token, das die Anmeldung der App gibt, wird einmal verwendet, um den Server zu beanspruchen, und danach verworfen. rex speichert nur das Server-Token, das Plex dafür ausstellt.

## Was auf deinem Gerät bleibt {#what-stays-on-your-device}

Deine Bibliotheken, der Wiedergabeverlauf, die Addon-Einstellungen (einschließlich aller Schlüssel, die du eingegeben hast) und die Logs. Die App behält die Logs dieses Durchlaufs und des vorherigen, damit ein Absturz sie nicht verliert. Logs verbergen Tokens, Schlüssel, Passwörter und den hinteren Teil öffentlicher IP-Adressen. Sie verlassen das Gerät nur, wenn du auf der Logs-Seite Share oder Send logs to support wählst. Beim Deinstallieren der App wird alles davon gelöscht.

## Add-ons {#addons}

Ein Addon ist Code von der Person, die es geschrieben hat, installiert aus einem Repository, das du hinzugefügt hast. Es läuft abgeschottet vom Rest deines Geräts und kann nur die Seiten erreichen, die es nennt. rex zeigt dir diese Seiten, bevor du es installierst. Installiere Addons nur von Leuten, denen du vertraust.

Ein Addon, das ein Konto auf seiner Website braucht, meldet sich mit einem Code an: Du gibst ihn auf der eigenen Seite der Website ein, sodass dein Passwort nie durch die App läuft. Das Token, das die Website dem Addon danach gibt, bleibt auf deinem Gerät und geht nur zurück an diese Website. Wenn du das Addon entfernst, wird es gelöscht.

## Kinder {#children}

Die App richtet sich nicht an Kinder.

## Kontakt {#contact}

support@debridmediamanager.com
