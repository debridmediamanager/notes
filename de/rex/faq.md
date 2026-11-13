# rex-Fragen {#rex-questions}

Kurze Antworten auf das, was Leute fragen, bevor sie rex installieren, und kurz danach. Jede Antwort verlinkt auf die Anleitung, in der die Details stehen.

## Bevor du installierst {#before-you-install}

### Was ist rex? {#what-is-rex}

Ein Medienserver für die offiziellen Plex-Apps, der keine Dateien besitzt. Deine Apps sehen einen weiteren Plex-Server mit Postern, Staffeln, Wiedergabeverlauf und Weiterschauen. Eine **Quelle** teilt rex mit, was in der Bibliothek liegt, und liefert jede Datei aus. rex streamt sie, wenn du auf Abspielen drückst. Vorher wird nichts heruntergeladen.

Es ist ein eigenständiger Server. Es ist kein Plugin für den Plex Media Server und braucht auch keines. Wenn du beides willst, betreib es neben Plex. [rex installieren](any-source.md#step-1-install-rex) erklärt die Begriffe, und [Von Plex zu rex wechseln](from-plex.md) behandelt beide Wege.

### Was kostet es? {#what-does-it-cost}

rex ist für den persönlichen Gebrauch kostenlos und hat keine Bezahlversion. Der Quellcode ist öffentlich unter der PolyForm Noncommercial-Lizenz verfügbar. Kommerzielle Nutzung ist nicht erlaubt. Jede Version ist auf [GitHub Releases](https://github.com/debridmediamanager/rex/releases) öffentlich verfügbar, und die Android-App ist [rex für Android](android.md).

Manches drumherum kann etwas kosten:

| | |
|---|---|
| [rex-stremio](stremio.md), deine eigene App oder ein Addon als Quelle | Kostenlos |
| zurg nightly, eine Quelle für eine Debrid- oder Usenet-Bibliothek | Ein Vorteil für [DMM-Sponsoren](https://gatekeeper.debridmediamanager.com) |
| Ein DMM-API-Schlüssel, für die genauen Treffer von DMM in zurg | Optional, ebenfalls über das Sponsoring von DMM |
| rex' Docker-Image | Kostenlos und öffentlich, für Linux: [rex in Docker](any-source.md#run-rex-in-docker) |

### Ist mein Plex-Konto gefährdet? {#is-my-plex-account-at-risk}

rex wird nicht von Plex entwickelt, und Plex könnte gegen einen Account vorgehen, der rex registriert. Erstelle deshalb einen **neuen, kostenlosen Plex-Account nur für rex** und teile ihn dann mit deinem eigenen Account. Dein Verlauf, deine Freunde und dein Plex Pass bleiben auf deinem eigenen Account. [Zu einem Plex-Account hinzufügen](any-source.md#step-3-add-it-to-a-plex-account) zeigt dir, wie das geht. Nutze rex auf eigene Gefahr.

### Welche Plex-Apps funktionieren? {#which-plex-apps-work}

| App | Getestet |
|---|---|
| Plex Web (app.plex.tv) | Am meisten: Durchsuchen, Wiedergabe, Konvertieren, Untertitel, Musik, Live-TV und Wiedergabe unterwegs mit kostenlosen Konten auf beiden Seiten |
| Plex for Android (Handy) | Auf einem Pixel 6: Wiedergabe, Konvertieren und [Herunterladen von deinem Anbieter](direct-download.md). Auf einem Emulator: Musik und Live-TV |
| Plexamp | Auf einem Android-Emulator: Durchsuchen und Abspielen einer Musikbibliothek, mit Künstlerbildern und Playlists |
| Plex for iOS | Auf einem iPad: Wiedergabe und Konvertieren. Dolby Vision hat einen App-Fehler (siehe unten) |
| Plex for Apple TV | Wiedergabe, einschließlich Live-Kanäle in einer Bibliothek |
| Plex Desktop | Plex for Mac: Wiedergabe und Konvertieren |
| Plezy | Auf einem Pixel 6: Wiedergabe und Herunterladen von deinem Anbieter |
| Plex HTPC | Noch nicht getestet |
| Plex for Android TV, NVIDIA Shield, Google TV | Noch nicht getestet |
| Plex for Roku | Noch nicht getestet |
| Smart-TV-Apps (Samsung, LG und andere) | Noch nicht getestet |
| Infuse | Noch nicht getestet |

Unterwegs wurde nur Plex Web getestet.

### Spielt es 4K, HDR und Dolby Vision ab? {#does-it-play-4k-hdr-and-dolby-vision}

Ja. Dateien werden in ihrer Originalqualität abgespielt: rex gibt die Datei unverändert an die App weiter, und die App entscheidet, was sie anzeigen kann. Wenn eine App eine Datei nicht so abspielen kann, wie sie ist, konvertiert rex sie, sofern FFmpeg eingerichtet ist ([Video konvertieren](any-source.md#converting-video-optional)). Bei einer Konvertierung werden HDR und Dolby Vision in ein Standardbild umgewandelt (Settings, Transcoder, **Enable HDR tone mapping**, standardmäßig aktiviert), wo möglich über den Grafikchip. Mit installierter Intel-OpenCL-Laufzeit konvertiert ein kleiner Intel-Rechner (ein J4105) 4K-HDR10 und Dolby Vision Profil 5 ungefähr in Echtzeit auf 1080p. Ohne FFmpeg zeigt eine Datei, die die App nicht abspielen kann, die Meldung "This server is not powerful enough to convert video". Wenn jeder Titel auf jedem Gerät diese Meldung zeigt, ist FFmpeg nicht die Lösung: siehe [Nothing plays](#nothing-plays-or-every-app-says-it-is-not-powerful-enough).

**Plex for iOS und Dolby Vision.** Plex for iOS 2026.20.0 bleibt bei 0:00 hängen, wenn es eine Dolby-Vision-Datei unverändert abspielt. Ein echter Plex Media Server, der dieselbe Datei ausliefert, hängt auf die gleiche Weise, der Fehler liegt also in der App. HDR10- und SDR-4K-Dateien werden abgespielt.

### Brauche ich Plex Pass? {#do-i-need-plex-pass}

Nein. rex teilt den Plex-Apps mit, dass das Konto, auf dem es angemeldet ist, Plex Pass hat. Dadurch funktionieren Wiedergabe außerhalb des eigenen WLANs und Videokonvertierung auch mit kostenlosen Konten. Wiedergabe außerhalb des eigenen WLANs wurde in Plex Web mit einem kostenlosen Konto auf beiden Seiten getestet. Andere Apps wurden außerhalb des eigenen WLANs noch nicht getestet. Filmversionen, das Dashboard, Downloads, das Überspringen von Intro und Abspann sowie der Rest der [Movie and TV capabilities](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities) funktionieren ebenfalls. Eine App kann trotzdem eigene Regeln anwenden.

### Kann ich zum Offline-Ansehen herunterladen? {#can-i-download-for-offline-viewing}

Die **Downloads** in den Plex-Apps sind da. rex bereitet den Download auf seinem eigenen Rechner vor, entweder als Originaldatei oder konvertiert mit FFmpeg, und hält sie in einem Ordner neben `rex.db`, bis die App sie abholt. Das Konto, bei dem rex registriert ist, kann immer herunterladen. Wer mit dir geteilt wird, braucht erlaubte Downloads in seiner Freigabe ([rex teilen](sharing.md#what-each-person-may-see-and-do)). Die App kann trotzdem ihre eigenen Regeln anwenden. Eine konvertierte Datei lässt Text-Untertitel weg. Ein Download auf dem Handy zu speichern und offline anzuschauen, wurde noch nicht getestet.

### Können mehrere Leute es nutzen, jeder mit eigenem Verlauf? {#can-several-people-use-it-each-with-their-own-history}

Ja. Jeder, mit dem du rex teilst, meldet sich mit seinem eigenen Konto an und bekommt seinen eigenen Wiedergabestatus, „Weiterschauen“, Bewertungen und Playlists. Jeder kann seinen Verlauf von einem alten Plex-Server übernehmen ([Bring your watch history](import-watched.md)). [Share rex with family and friends](sharing.md) erklärt die Schritte, einschließlich verwalteter Benutzer für Kinder.

### Welche Hardware braucht es? {#what-hardware-does-it-need}

Ein Rechner, der dauerhaft läuft, mit Linux (amd64 oder arm64, glibc 2.35 oder neuer, also Ubuntu 22.04 und höher), macOS (Intel oder Apple Silicon) oder 64-Bit-Windows. Auf einem Android-Handy, -Tablet oder einer TV-Box laufen rex und seine Addons kostenlos mit [rex für Android](android.md), und die nur für Sponsoren gedachte zurg+rex-App, ein Plex-Server auf deinem Handy, betreibt zurg und rex zusammen (siehe den [Android-Guide](../zurg/guides/android.md)).

**Arbeitsspeicher:** Gib ihm 1 GB. Bei einer Bibliothek mit 4.062 Filmen und 656 Serien brauchte rex beim Start weniger als 500 MB und beim Durchsuchen der Bibliothek etwa 730 MB. Video konvertieren braucht zusätzlich mehr.

**Festplatte:** Für Filme nichts. rex speichert seine Bibliothek in `rex.db`. Downloads und die Bilder, die die Analyse erstellt (Vorschaubilder zum Spulen, Kapitelbilder), landen ebenfalls daneben, wenn du sie nutzt.

**Konvertieren:** Nur mit FFmpeg. Ein Grafikchip macht es schnell: Ein 1080p-Film, konvertiert auf einem kleinen Intel-Chip, startet in etwa 2 Sekunden. Welche Chips rex auf welchem System nutzt, steht unter [By platform](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#by-platform): Auf macOS konvertiert rex immer mit dem Prozessor.

### Liest es meine lokalen Dateien? {#does-it-read-my-local-files}

Nein. rex scannt nie einen Ordner oder eine Festplatte und braucht kein Mount. Jede Datei kommt über HTTP von einer Quelle. Dateien auf deiner eigenen Festplatte können trotzdem rein: Irgendetwas muss sie ausliefern und rex davon erzählen, wie [rex mit deiner eigenen App](any-source.md) zeigt.

### Funktioniert es mit Usenet? {#does-it-work-with-usenet}

Ja, über eine Quelle, die Usenet liest, zum Beispiel zurg. rex spricht nie direkt mit einem Usenet-Anbieter: Die Quelle liest die Dateien und stellt sie rex wie jede andere Datei bereit. Richte zurg dafür mit [Usenet](../zurg/guides/usenet.md) ein und verbinde es mit rex, wie in [rex mit zurg](with-zurg.md) beschrieben.

### Brauche ich zurg? {#do-i-need-zurg}

Nein. zurg ist nur eine Quelle von mehreren. rex akzeptiert alles, was mit seiner Feed-API spricht:

- [rex mit deiner eigenen App](any-source.md): jede App, die Dateien über HTTP bereitstellt
- [rex mit deinen Stremio-Addons](stremio.md): Kataloge aus Stremio-Addons
- [rex mit zurg](with-zurg.md): dein Debrid-Konto oder Usenet
- [Eigene rex-Addons bauen](addons.md): Heimvideos, Aufnahmen oder Kanäle, mit einem eigenen Programm, und drei [Tutorials](addon-home-videos.md) als Einstieg

Mehrere Quellen können dieselben Bibliotheken für Movies und TV befüllen.

### Muss ich einen Port weiterleiten? {#do-i-need-to-forward-a-port}

Nicht zu Hause. Plex-Apps in deinem Heimnetzwerk finden rex ohne Router-Änderung. app.plex.tv funktioniert auch über die HTTPS-Adresse, die [rex-direct](any-source.md#rex-direct) für einen verknüpften rex angibt.

rex braucht eine eigene Adresse für die Nutzung unterwegs oder für einen anderen Haushalt. Der einfachste Weg ist eine einzige Portweiterleitung ([rex-direct](any-source.md#rex-direct)). Mit IPv6 und ohne öffentliche IPv4 nutzt du [rex-direct über IPv6](any-source.md#rex-direct-over-ipv6). [Tailscale serve](any-source.md#tailscale-serve) braucht keine Portweiterleitung auf Geräten, auf denen Tailscale läuft. [Außerhalb deines Zuhauses nutzen (optional)](any-source.md#use-it-outside-your-home-optional) vergleicht die Optionen.

### Was macht es nicht? {#what-does-it-not-do}

Es gibt keinen Tuner und keinen DVR. Musik, Live-TV und Fotos brauchen eine Quelle, die sie liefert. Siehe [Musik mit rex](music.md) und [Live-TV mit rex](live-tv.md). zurg liefert Comics als Fotos, die Plex Web anzeigt. Plexamp-Radiomixe und -Sender fehlen. rex hat kein Relay, daher braucht die Nutzung von unterwegs eine eigene Adresse ([Von außerhalb deines Zuhauses nutzen](any-source.md#use-it-outside-your-home-optional)).

## Nach der Installation {#after-you-install}

### Warum zeigt die App eine Plex-Version und "Check for Updates"? {#why-does-the-app-show-a-plex-version-and-check-for-updates}

rex stellt sich den Apps und plex.tv als Plex Media Server vor, deshalb zeigen die Apps eine Plex-Media-Server-Versionsnummer an. Diese Nummer gehört nicht zu rex. **Check for Updates** meldet immer, dass der Server auf dem neuesten Stand ist: rex aktualisiert sich nie selbst. Um rex zu aktualisieren, lade dir einen neueren Nightly herunter, wie unter [Updating](any-source.md#updating) beschrieben.

### Warum zeigt mein Browser unter port 32400/web keine Bibliothek an? {#why-does-my-browser-at-port-32400web-not-open-a-library}

rex hat keine eigene Web-App. Wenn du `http://<rex's LAN IP>:32400/web` öffnest, siehst du eine kurze Statusseite. Schau dir deine Inhalte in einer Plex-App an oder im Browser unter [app.plex.tv](https://app.plex.tv).

![Die Seite, die rex unter /web anzeigt, solange sie noch nicht beansprucht ist](../assets/rex/80-rex-web-page.webp)

### Was verlässt meinen Rechner? {#what-leaves-my-machine}

**plex.tv, beim Start und einmal am Tag, ob registriert oder nicht:** die ID, der Name und die Version des Servers, damit rex in Plex' öffentlicher Liste der Releases nach der neuesten Versionsnummer schauen kann.
**plex.tv, sobald der Server mit einem Plex-Konto verbunden ist:** der Claim, die Adressen des Servers (seine LAN-Adresse und seine HTTPS-Adressen) und die Namen deiner Bibliotheken.
**Plex' Metadatendienst, sobald registriert:** die ID jedes Titels, um Name, Poster, Zusammenfassung und Episoden abzurufen. Eine Untertitelsuche, über **Search Subtitles** oder die automatische Untertiteleinstellung einer Person, sendet den Dateinamen und den Fingerprint.
**Artwork-Hosts, wenn eine App sie anzeigt:** Anfragen für die Poster und Bilder, die deine Quellen angeben.
**DMM, für rex-direct, sobald registriert und danach alle 6 Stunden:** die ID des Servers, sein Token im Plex-Konto und seine LAN-IP. DMM prüft bei plex.tv, dass der Server dir gehört, sieht deine öffentliche IP und zeigt deine rex-direct-Namen auf sie und auf die LAN-IP. Hat der Rechner eine globale IPv6-Adresse, schickt rex sie auch, eine Minute nach dem Start (oder nach dem Claim) und danach alle 6 Stunden. Jedes Mal verbindet sich DMM damit, um zu prüfen, dass sie auf denselben Server zeigt. Abschalten mit `REX_DIRECT_URL=off`.
**Deine Quellen, wenn du abspielst oder löschst:** Anfragen für die Dateien, die du abspielst, und Löschvorgänge (siehe unten).
**Dein alter Plex-Server, nur wenn du [deinen Wiedergabeverlauf übernimmst](import-watched.md):** Anfragen für deinen Wiedergabeverlauf.
**Webhooks, nur wenn du welche einrichtest:** Ereignisse an die Adressen, die du festlegst.

rex fragt niemanden, was ein Release ist: Die Quelle entscheidet und sagt es rex. zurg zum Beispiel fragt DMM ([Warum DMM die Dateien platziert](with-zurg.md#why-dmm-places-the-files)).

### Löscht das Löschen in einer Plex-App die Datei? {#does-deleting-in-a-plex-app-delete-the-file}

Ja. Wenn du in einer Plex-App mit dem Account, bei dem rex registriert ist, einen Film oder eine Episode löschst, löscht das auch die Dateien an der Quelle, so wie ein Plex-Server Dateien von seiner Festplatte löscht. Eine Quelle bei einem Debrid-Account, etwa zurg, löscht sie dort. Wenn die Quelle das verweigert, bleibt der Titel erhalten und die App zeigt an, dass er nicht gelöscht werden konnte. Personen, mit denen du teilst, können nicht löschen. [Löschen in einer Plex-App](any-source.md#step-5-watch-something) erklärt, wie du das ausschaltest.

### Nichts wird abgespielt, oder jede App sagt, dass es nicht leistungsfähig genug ist {#nothing-plays-or-every-app-says-it-is-not-powerful-enough}

Schau dir rex' Log direkt an, nachdem du auf Play gedrückt hast. Steht dort `upstream failed` oder `502`, kann rex deine Quelle nicht unter der Adresse erreichen, die die Quelle ihm gegeben hat. FFmpeg zu installieren hilft dagegen nicht. Die übliche Ursache ist zurg in Docker Desktop unter Windows oder macOS. Die Zeile `upstream failed` in [rex mit zurg](with-zurg.md#when-something-is-wrong) oder [rex mit deiner eigenen App](any-source.md#when-something-is-wrong) prüft die Adresse und sagt dir, was du ändern musst. Fallen nur manche Dateien aus, oft nur im Webbrowser, kann dein Gerät sie so nicht abspielen. Dann richte [Videokonvertierung](any-source.md#converting-video-optional) ein.

### Ein Titel wird falsch zugeordnet. Wie behebe ich das? {#a-title-is-matched-wrong-how-do-i-fix-it}

Die Quelle entscheidet, was jede Datei ist, und rex zeigt diesen Titel an. Melde dich mit dem Konto an, bei dem rex registriert ist, und nutze **Fix Match**: rex behält deine Auswahl, und eine Quelle kann sie auslesen, um sie als Zuordnung für dieses Release zu behalten, so wie zurg es tut ([Why DMM places the files](with-zurg.md#why-dmm-places-the-files)).

### Wo bekomme ich Hilfe? {#where-do-i-get-help}

[Hilfe bekommen](../guides/remote-help.md) sagt dir, wo du fragen kannst und was du angeben solltest: den **rex-support**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP) und Remote-Hilfe für Sponsoren.
