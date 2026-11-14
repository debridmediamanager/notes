# zurg+rex für Android und Google TV {#zurgrex-for-android-and-google-tv}

zurg+rex ist ein Plex-Server auf deinem Handy. zurg bindet deine Debrid-Konten und Usenet ein, und rex stellt sie jeder Plex-App in deinem Zuhause zur Verfügung, mit Postern, Staffeln und Wiedergabefortschritt. Es läuft auf einem Handy, Tablet, Android TV, Google TV oder Fire TV, ganz ohne Computer.

Es kommt mit einer Sponsoring-Bedingung. Kein Sponsoring? [rex für Android](../../rex/android.md) ist kostenlos und spielt ab, was seine Addons liefern.

| Die App | In der Plex-App | In jeder anderen Plex-App |
|---|---|---|
| ![Status in zurg+rex mit fertiger Bibliothek und bei Plex angemeldetem rex](../../assets/zurg/android-status.webp) | ![Big Buck Bunny auf seiner Seite in der Plex-App, ausgeliefert vom selben Handy](../../assets/zurg/android-plex.webp) | ![Dieselbe Bibliothek mit offenen Filmen in der Plezy-App](../../assets/zurg/android-plezy.webp) |

## Bevor du anfängst {#before-you-start}

| Du brauchst | Warum |
|---|---|
| Ein Gerät mit Android 8.0 oder neuer | Handy, Tablet, Android TV, Google TV oder Fire TV. Usenet braucht ein 64-Bit-Gerät |
| Eine Sponsorschaft mit verknüpftem GitHub-Konto | Die App und ihre Engine werden aus dem Sponsor-Repository heruntergeladen. Werde Sponsor und verknüpfe GitHub auf [gatekeeper](https://gatekeeper.debridmediamanager.com/) |
| Ein Debrid-Konto oder ein Usenet-Konto | Das bringt zurg in deine Bibliothek. TorBox-gehostete NZBs (`torbox_nzb`) sind auf Android nicht verfügbar |
| Ein Plex-Konto | rex erscheint in den Plex-Apps, in denen du angemeldet bist. Ein kostenloses Konto reicht |
| Dein DMM-API-Schlüssel von gatekeeper (optional) | Damit bekommen mehr Titel ihren Namen und ihr Poster |

## Schritt 1. Herunterladen {#step-1-download-it}

Öffne auf dem Gerät die [Download-Seite](https://zurg.debridmediamanager.com/de/download.html#android), melde dich mit deinem Sponsor-Konto bei GitHub an und wähle die Datei für den Prozessor deines Geräts:

| Dein Gerät | Datei |
|---|---|
| Die meisten Handys, Tablets und TV-Boxen (64-Bit) | `android-arm64-v8a.apk` |
| Ältere 32-Bit-Handys und TV-Sticks | `android-armeabi-v7a.apk` |
| Chromebooks und Emulatoren | `android-x86_64.apk` |

Ein und dieselbe Datei funktioniert auf Handys und TVs gleichermaßen.

**GitHub zeigt 404?** Dem Konto, mit dem du angemeldet bist, fehlt noch der Sponsor-Zugang. Hast du gerade erst gesponsert, [nimm zuerst die Einladung an](https://github.com/debridmediamanager/zurg/invitations). Einladungen werden innerhalb von 15 Minuten verschickt.

## Schritt 2. Installieren {#step-2-install-it}

Öffne die heruntergeladene Datei und erlaube die Installation über die App, die sie geöffnet hat. Android oder Play Protect fragen dich eventuell nach einer Bestätigung.

**Was du sehen solltest.** **zurg+rex** in deiner App-Liste.

## Schritt 3. Bei GitHub anmelden und die Engine installieren {#step-3-sign-in-to-github-and-install-the-engine}

Öffne die App. Dort steht **Welcome to zurg+rex.**

1. Drück auf **Sign in with GitHub**. Die App zeigt dir einen Code: Drück auf **Open GitHub**, gib den Code ein und bestätige. GitHub fragt nach `repo`-Zugriff, weil die Sponsor-Releases privat sind.
2. **Installiere die Engine.** Die Engine sind zurg und rex selbst. Sie liegen in einem eigenen Paket, damit sie unabhängig von der App aktualisiert werden. Drück auf **Install**. Android fragt vor der Installation nach: erlaube es.

**Was du sehen solltest.** **Add your providers.**

## Schritt 4. Deine Anbieter hinzufügen {#step-4-add-your-providers}

1. Drück auf **Add an account** und wähl den Anbieter aus.
2. Für ein Debrid-Konto fügst du das Token in **Provider token** ein. Für Usenet trägst du **NNTP server**, **Port**, **Username**, **Password** und **Connections** ein.
3. Drück auf **Test account** und danach auf **Add provider**.

Du kannst so viele Konten hinzufügen, wie du hast. **Account name** hilft dir, zwei Konten beim selben Anbieter auseinanderzuhalten. Das Verbindungslimit eines Usenet-Kontos zählt alle anderen Apps und Geräte mit, die es benutzen.

## Schritt 5. Deine Bibliothek starten {#step-5-start-your-library}

1. Wähle **Phone**, **Tablet**, **TV box** oder **TV stick**. Kleinere Auswahlen brauchen weniger Speicher und kleinere Caches.
2. Erlaube Benachrichtigungen und lass die App im Hintergrund laufen. Aktiviere **Start after reboot**, wenn dieses Gerät immer deine Bibliothek bereitstellen soll.
3. Drücke **Start my library**.

**Was du sehen solltest.** **Status** zeigt **Ready for your players** und zählt deine Releases. Beim ersten Laden eines großen Accounts können mehrere Minuten vergehen.

## Schritt 6. Bei Plex anmelden {#step-6-sign-in-to-plex}

Unter **Status** klickst du bei **rex for the Plex apps** auf **Sign in to Plex**.

- **Auf dem Handy oder Tablet** öffnet dein Browser die Anmeldeseite von Plex. Melde dich dort an.
- **Auf einem Fernseher** zeigt die App **On any device, go to plex.tv/link and enter** und darunter einen Code. Gib diesen Code auf deinem Handy oder Computer ein.

Nimm das Konto, mit dem deine Plex-Apps angemeldet sind.

**Was du sehen solltest.** **Ready for the Plex app**, mit einem **Open Plex**-Button, wenn Plex auf diesem Gerät installiert ist.

## Schritt 7. In einer Plex-App ansehen {#step-7-watch-in-a-plex-app}

Öffne eine beliebige Plex-App, die mit demselben Konto angemeldet ist: auf diesem Gerät, deinem Fernseher, einem anderen Handy oder einem Computer zu Hause. Dein Server wird unter dem Namen dieses Geräts angezeigt, mit den Bibliotheken **Debrid Movies** und **Debrid TV**. Drück auf Play.

rex wandelt um, was ein Player nicht abspielen kann, und nutzt dafür den eigenen Video-Encoder des Geräts.

## Weitere Titel suchen namens {#get-more-titles-named}

Öffne **Settings**, **Library** und füge deinen DMM-API-Key in **Dmm api key** ein, dann speichere. zurg fragt dann bei DMM nach, was jede Datei ist. Ohne den Key ermittelt zurg das anhand des Release-Namens, und dann bekommen weniger Titel ihren Namen und ihr Poster.

Ein Titel, der immer noch falsch aussieht, lässt sich in einer Plex-App korrigieren: Öffne sein **⋯**-Menü und wähle **Fix Match**.

Das Feld gibt es in Nightlies ab dem 14. November 2026. In einer älteren Version füge `dmm_api_key: YOUR_DMM_API_KEY` in **Settings**, **Advanced** hinzu. Derselbe Key liest auch deine [DMM-Wunschliste](dmm-wanted.md).

## Add-ons {#addons}

Addons bringen dir neben deiner Bibliothek noch mehr zum Anschauen in rex. Öffne **Addons**: Das Internet-Archive-Addon ist schon installiert und ergänzt gemeinfreie Filme, und das Repository [rex-addons](https://github.com/debridmediamanager/rex-addons) ist bereits eingetragen. Füge über seinen Link ein weiteres Repository hinzu, öffne es und installiere, was es anbietet.

Jedes Addon zeigt an, welche Websites es erreichen kann, und ein Update, das neue Websites erreicht, fragt vorher nach. Installiere Addons nur von Leuten, denen du vertraust. Ein Addon, das dein Konto braucht, zeigt dir einen Code, den du auf seiner Website eingeben musst. Die Anmeldung, die es dabei erhält, bleibt auf diesem Gerät. **Log** zeigt, was ein Addon zuletzt gemacht hat. Wenn du ein Addon entfernst, verschwinden nur seine Titel.

## Andere Player auf diesem Gerät {#other-players-on-this-device}

Du brauchst keine Plex-App, um zu schauen.

- **Library** durchsucht deine Ordner und spielt eine Datei im Player deiner Wahl ab. **More** bietet einen anderen Player und die Aktionen für das Release: repair, rename, tags, show all files und delete. Sie wirken auf das ganze Release, und delete fragt vorher nach und löscht es aus deinem Provider-Konto.
- Die **Files**-App und Dateiauswahl-Dialoge zeigen dieselbe Bibliothek unter dem zurg-Root. Öffne deinen Player einmal und schließe seine Einrichtung ab, bevor du ihn in Files auswählst.
- WebDAV-Player wie VLC, Kodi und Nova nehmen `http://127.0.0.1:9999/dav/` als Quelle. **Status** zeigt die Adresse an, falls du den Port geändert hast.

Auf einem Fernseher bewegst du dich mit dem D-Pad und Select, gehst mit Back zurück und öffnest die Aktionen eines Releases mit Menu oder **More**. Wähle ein Textfeld aus, um darin zu tippen, und drücke Back, um weiterzumachen.

## Mit anderen Playern im Haushalt teilen {#share-with-other-players-at-home}

Plex-Apps zu Hause brauchen nichts weiter: Sie finden rex von selbst. Für einen WebDAV-Player auf einem anderen Gerät öffnen Sie **Settings**, **Connection** und schalten **Expose on local network** ein. zurg erstellt einen Benutzernamen und ein Passwort und zeigt die Adresse, die Sie in diesen Player eingeben.

Nutzen Sie das nur in einem Netzwerk, dem Sie vertrauen: Das Passwort wird unverschlüsselt übertragen. Die Funktion ist standardmäßig aus, und Sie müssen sie erst einschalten.

## Im Dauerbetrieb lassen {#keep-it-running}

- Die Benachrichtigung zeigt den Status des Servers und hat **Stop**. Eine Schnelleinstellungs-Kachel startet und stoppt ihn ebenfalls.
- Manche Handys beenden Hintergrund-Apps trotzdem. [Don't kill my app](https://dontkillmyapp.com/) erklärt, was deine App braucht.
- **Updates** sucht nach einer neuen App und einer neuen Engine; sie werden getrennt aktualisiert. Wenn ein neuer Nightly-Build auf deinem Gerät Probleme macht, drück **Show engine versions** und installiere die Version, die funktioniert hat. Stoppe deine Bibliothek vorher auf **Status**.
- **Settings** hat **Create backup** und **Restore backup**. Ein Backup enthält deine Passwörter und Tokens, also halte es privat. Stoppe deine Bibliothek, bevor du wiederherstellst.
- Schalte rex in **Settings**, **Connection**, **rex for the Plex apps** aus. zurg füttert es dann nicht mehr.

## Was die App sendet und wohin {#what-the-app-sends-and-where}

zurg+rex hat keine Werbung und keine Analytics. Das ist alles, was dein Gerät verlässt:

| Wohin | Was | Wann |
|---|---|---|
| GitHub | Deine Anmeldung, danach Anfragen für die Sponsor-Releases | Wenn du dich anmeldest und wenn **Updates** nach neuen Versionen sucht |
| Deine Anbieter | Dein Konto-Token oder dein Usenet-Login sowie Anfragen für deine Bibliothek und Dateien | Solange deine Bibliothek läuft |
| debridmediamanager.com | Die Namen deiner Releases, damit erkannt wird, was jedes davon ist, mit deinem DMM-API-Key, falls du einen eingegeben hast | Solange deine Bibliothek mit aktiviertem rex läuft |
| plex.tv und Plex-Metadatendienst | Eine Anfrage für den Anmeldecode; danach der Name und die Adresse des Servers sowie die IDs deiner Titel, um Poster und Beschreibungen zu laden | Wenn du dich bei Plex anmeldest und solange rex angemeldet läuft |
| debridmediamanager.com (rex-direct) | Die Kennung von rex, das Server-Token, das Plex ihm gegeben hat, seine IP-Adressen und sein Port, damit Plex-Apps per HTTPS darauf zugreifen können | Nach der Anmeldung bei Plex, danach alle 6 Stunden |
| Die Websites der einzelnen Addons und die Repositories, die du hinzufügst | Was das Addon anfordert | Wenn ein Addon synchronisiert oder ein Titel abgespielt wird |
| logs.debridmediamanager.com | Versionen, Gerätemodell, die Logs von App und Engine sowie deine Konfiguration, wobei Schlüssel, Passwörter und Token durch `[redacted]` ersetzt werden | Nur wenn du unter **Send logs to support** auf **Send** drückst, nachdem du alles gesehen hast. Wird nach 7 Tagen gelöscht |

Dein GitHub-Token wird verschlüsselt auf dem Gerät gespeichert. Wenn du die App deinstallierst, wird alles gelöscht, was sie gespeichert hat.

## Limits

Du hast eine Liste, also gehe ich nach den Regeln vor: Formatierung und Link bleiben unverändert, Button-Namen bleiben englisch.

- **Das Gerät ist der Server.** Lass es eingeschaltet, verbunden und am Strom. Videos zu konvertieren dauert auf einer günstigen Box lange.
- **Zu Hause wird es abgespielt.** Unterwegs brauchen die Plex-Apps eine HTTPS-Adresse, die das Gerät erreicht. Dafür musst du einen Port-Forward auf deinem Router einrichten. Siehe [Use it outside your home](../../rex/with-zurg.md#use-it-outside-your-home-optional).
- **Usenet braucht 64-Bit-Android.** Ein 32-Bit-Gerät unterstützt nur Debrid-Bibliotheken.
- **Nicht im Google Play Store.** Es aktualisiert sich innerhalb der App, unter **Updates**.

## Fehlerbehebung {#troubleshooting}

| Was du siehst | Was du tun kannst |
|---|---|
| GitHub zeigt auf der Download-Seite 404 an | Melde dich mit deinem Sponsor-Account bei GitHub an und [nimm die Einladung an](https://github.com/debridmediamanager/zurg/invitations). Noch kein Sponsor: [gatekeeper](https://gatekeeper.debridmediamanager.com/) |
| **No engine is installed. zurg needs one before it can serve your library.** | Drücke **Install an engine** und erlaube Android, ihn zu installieren |
| **No engine is available in the sponsor releases for this device yet.** | Die neueste Nightly hat keine Engine für deinen Prozessor. Frag im Support nach |
| **This is a 32-bit device. Debrid libraries are supported; Usenet needs 64-bit Android.** | Füge ein Debrid-Konto hinzu oder nutze ein 64-Bit-Gerät für Usenet |
| **The Plex code expired. Ask for a new one.** | Drücke erneut **Sign in to Plex** und gib den neuen Code innerhalb von 10 Minuten ein |
| Der Server erscheint nicht in der Plex-App | Melde die Plex-App mit dem Account an, den du in Schritt 6 benutzt hast, und halte beide Geräte im selben Heimnetzwerk |
| Titel zeigen einen Dateinamen und kein Poster | Gib deinen DMM-API-Schlüssel ein (siehe [Get more titles named](#get-more-titles-named)) oder nutze **Fix Match** in einer Plex-App |
| **Needs an update** bei einem Addon | Diese Version der App kann diese Kopie des Addons nicht mehr ausführen. Aktualisiere das Repository und drücke **Update**. Die Titel bleiben solange erhalten |
| Es stoppt, wenn der Bildschirm aus ist | Erlaube die Hintergrundnutzung wieder und schau dir [Don't kill my app](https://dontkillmyapp.com/) an |
| Ein Update lässt die App ohne Engine zurück | Installiere einmal eine Engine über **Updates**. Deine Anbieter und Einstellungen bleiben erhalten |

Wenn der Support nach Logs fragt, öffne **Logs** und drücke **Send logs to support**. Du siehst alles, bevor etwas gesendet wird. Drücke dann **Send** und poste den Code, den du bekommst.

Hängst du fest? Frag im Forum **zurg-support** auf [Discord](https://discord.com/invite/7u4YjMThXP).
