# zurg+rex für Android und Google TV {#zurgrex-for-android-and-google-tv}

Die Android-App betreibt eine zurg-Engine direkt auf dem Gerät und rex daneben: Dein eigener Plex-Server auf deinem Telefon oder deiner TV-Box, für die Plex-Apps. Eine App funktioniert auf Telefonen, Tablets, Android TV und Google TV. Android 8.0 oder neuer ist erforderlich. Fire TV kann dieselbe APK per Sideload installieren. Verwende einen WebDAV-Player, wenn er keine systemeigene Files-App hat. Usenet erfordert 64-Bit-Android; TorBox-gehostete NZBs (`torbox_nzb`) sind auf Android nicht verfügbar.

## Installieren und einrichten {#install-and-set-up}

[Lade eine APK](https://zurg.debridmediamanager.com/de/download.html#android) aus dem nightly Release des privaten Sponsor-Repositorys herunter. Wähle `arm64-v8a` für
die meisten Handys und TV-Boxen, `armeabi-v7a` für ältere 32-Bit-Geräte oder `x86_64` für einen Emulator oder
ein kompatibles Chromebook. Jede APK enthält die Oberflächen für Handy und TV.

Die App enthält zurg selbst nicht. Nach der Anmeldung bei GitHub installierst du die Engine direkt
in der App. Ein Sponsor-Konto ist erforderlich. Werde Sponsor auf [gatekeeper](https://gatekeeper.debridmediamanager.com/),
damit dein GitHub-Konto Zugriff bekommt. Setup führt dich durch die Schritte.

Erlaube die Installation für die App, mit der du die APK öffnest. Android oder Play Protect
fragen möglicherweise nach einer Bestätigung der Installation aus unbekannten Quellen. Die Application ID lautet
`com.debridmediamanager.zurg`. Updates müssen die Release-Signatur beibehalten.

1. Öffne zurg und melde dich bei GitHub an, installiere dann eine Engine-Version. Die App
   kann eine Bibliothek erst starten, wenn eine Engine installiert ist.
2. Füge Anbieter-Konten hinzu und teste die Zugangsdaten. Kontonamen unterscheiden
   mehrere Konten bei demselben Anbieter. Usenet-Verbindungslimits gelten für alle anderen Nutzer dieses Kontos.
3. Wähle Phone, Tablet, TV box oder TV stick. Die Profile legen das Speicherziel der Engine
   und die Größe des Disk-Caches fest. Ein Go-Heap-Ziel ist keine harte RSS-Grenze.
4. Erlaube Benachrichtigungen und Hintergrundbetrieb. Aktiviere start after reboot, wenn dieses Gerät
   die Bibliothek immer bereitstellen soll.
5. Starte die Bibliothek. Das erste Laden eines großen Kontos kann mehrere Minuten dauern.
   Die Benachrichtigung und der Status-Bildschirm zeigen an, wann die Verzeichnisse bereit sind.

## Auf diesem Gerät ansehen {#watch-on-this-device}

Verwende Library, um Ordner zu durchsuchen und eine Datei abzuspielen. Unter More findest du einen anderen Player oder eine Android-Dokument-URI. Der gewählte Player kann zum bevorzugten Player werden.
Dateien und Dokumentauswahl zeigen dieselbe Bibliothek unter dem zurg-Speicherstamm.
Dateien werden mit wahlfreiem Zugriff gestreamt. Sie werden nicht zuerst komplett heruntergeladen.
Öffne deinen Player einmal und schließe seine Einrichtung ab, bevor du ihn unter Files auswählst.

Für WebDAV-Player fügst du `http://127.0.0.1:9999/dav/` als Quelle hinzu. Falls du den Port geändert hast, nimm den Port, der unter Status angezeigt wird. VLC, Kodi und Nova können eine WebDAV-Quelle durchsuchen. Player, die nur einzelne URLs annehmen, kannst du aus Library starten. Auf dem TV bewegst du dich mit dem D-Pad und aktivierst Steuerelemente mit Select, mit Back kehrst du zurück. Mit Menu oder More öffnest du die Release-Aktionen. Wähle ein Textfeld aus, um es zu bearbeiten, und drücke Back, um zur Navigation zurückzukehren. Auf dem Handy öffnest du More auch mit einem langen Tipp.

Repair, rename, tags, show all files und delete wirken auf das gesamte zugehörige Release. Beim Löschen wirst du um Bestätigung gebeten, und es wird aus deinem Konto beim Anbieter gelöscht.
MediaInfo verwendet das mitgelieferte ffprobe und zeigt die ermittelten Video-, Audio- und Untertiteldetails im Dashboard an. Eine separate Installation eines Medientools ist nicht nötig.

## In den Plex-Apps ansehen {#watch-in-the-plex-apps}

Ab dem Nightly vom 10. November 2026 startet die App zusätzlich rex (auf 64-Bit-Geräten in diesem Nightly, auf allen unterstützten Geräten ab dem Nightly vom 11. November), einen Medienserver für die Plex-Apps, und verbindet zurg damit. So erscheint deine Bibliothek in den offiziellen Plex-Apps und in Plezy, auf diesem Gerät und auf anderen in deinem Haushalt. Sobald deine Bibliothek läuft, zeigt Status **rex for the Plex apps** an: Wähle **Sign in to Plex** und bestätige die Anmeldung (auf einem Fernseher gibst du den Code unter plex.tv/link ein). Der Server erscheint in Plex unter dem Namen dieses Geräts. rex wandelt alles, was ein Player nicht abspielen kann, mit dem Hardware-Encoder des Geräts um. Schalte rex unter Settings, Connection aus; dann liefert zurg keine Inhalte mehr an rex.

## Im lokalen Netzwerk teilen {#share-over-the-local-network}

In den Einstellungen aktivierst du **Expose on local network**. zurg erzeugt Zugangsdaten und zeigt dir die LAN-WebDAV-Adresse des Geräts an. Trage diese Adresse und die Zugangsdaten in einem Player auf dem anderen Gerät ein. Lass das Android-Gerät eingeschaltet und laufen.
HTTP-Basisauthentifizierung verschlüsselt den Datenverkehr nicht; nutze daher ein vertrauenswürdiges lokales Netzwerk.
Loopback ist die Standardeinstellung. Player-Intents enthalten niemals dein Server-Passwort.

## Einstellungen, Backups und Updates {#settings-backups-and-updates}

Settings umfasst Verbindung, Provider, Bibliothek, Reparatur, Ressourcen und Logging.
Advanced akzeptiert rohes YAML und lässt die installierte Engine es vor dem Speichern prüfen. Settings hat kein Feld für deinen DMM-API-Schlüssel. Füge stattdessen `dmm_api_key: YOUR_DMM_API_KEY` in Advanced hinzu, damit die [DMM-Wunschliste](dmm-wanted.md) und die Benennung der Releases von DMM funktionieren. Wenn du eine laufende Konfiguration speicherst, fragt die App nach, bevor der Server neu startet.
Web dashboard öffnet das lokale Dashboard für die Einstellungen der Desktop-Integration.

Logs zeigt die letzte Ausgabe der Engine und die letzten 200 Zeilen des Supervisors.
Geteilte Logs schwärzen konfigurierte Geheimnisse und URLs. Backups enthalten Zugangsdaten und den Bibliotheksstatus, also bewahre sie privat auf. Stoppe zurg, bevor du ein Backup wiederherstellst. Android verweigert Backup-Links und Sonderdateien und stellt zuerst auf loopback wieder her.

Updates prüft das private Sponsor-Repository. Die Anmeldung per GitHub-Gerätecode fordert den Scope `repo` an, weil die Release-Assets privat sind. GitHub-Tokens werden in Einstellungen gespeichert, die mit dem Android Keystore verschlüsselt sind. Du kannst auch manuell ein Token angeben, das Lesezugriff auf das Repository hat. Wenn Android eine gespeicherte Anmeldung nicht mehr entschlüsseln kann, fordert Updates dich auf, dich erneut anzumelden. Deine Bibliothekskonfiguration bleibt dabei erhalten. Heruntergeladene Updates müssen zur Application ID und zum Signaturschlüssel passen und einen neueren Versionscode haben. Der Android-Installer fragt dich, bevor er die App ersetzt.

Wenn du von einem Build aktualisierst, der eine eigene Engine mitgebracht hat, hat die App danach keine Engine mehr. Installiere einmal eine Engine über Updates. Deine Provider- und Bibliothekseinstellungen bleiben dabei unverändert erhalten.

App und Engine werden getrennt aktualisiert. Updates listet die Engine-Versionen aus den 30 neuesten Releases des Sponsor-Repositorys auf, markiert die Version, die du gerade hast, und installiert jede davon. Wenn ein neuer Nightly-Build auf deinem Gerät Probleme macht, installiere die Version, mit der es bei dir funktioniert hat. Stoppe deine Bibliothek unter Status, bevor du die Engine wechselst. Die App startet nur ein Engine-Paket, das mit ihrem eigenen Schlüssel signiert ist, und prüft das bei jedem Start erneut.

Die dauerhafte Benachrichtigung hat eine Stop-Aktion. Eine Kachel in den Quick Settings startet oder stoppt den Server ebenfalls. Battery exemption hilft bei den Ruhemodus-Limits von Android. Hersteller-spezifische Task-Killer brauchen unter Umständen zusätzliche Einstellungen, siehe [Don't kill my app](https://dontkillmyapp.com/).
