# Von Plex zu rex wechseln {#move-from-plex-to-rex}

Du betreibst Plex Media Server und möchtest rex ausprobieren. Deine Plex-Apps bleiben gleich. Die Bibliotheksquelle und die Server-Adresse ändern sich.

## Was sich ändert {#what-changes}

| | Plex Media Server | rex |
|---|---|---|
| Where the library comes from | Plex scans folders on a disk or a mount | A source (your own app, rex-stremio or zurg) tells rex what it has. rex never scans a folder and needs no mount |
| What each file is | Plex matches it from its file name | The source works it out and tells rex. rex never reads a file name |
| A wrong match | Fix Match on the server | **Fix Match** in a Plex app, signed in as the account that owns rex. rex keeps your pick, and a source can take it back and keep it, as zurg does ([why titles are placed as they are](with-zurg.md#why-dmm-places-the-files)) |
| The account the server is on | Usually your own | A fresh Plex account made for rex, shared with your own |
| Music, Live TV and photos | From folders and a tuner | Only from a source that sends them, such as an addon ([Building rex addons](addons.md#music)) or zurg's comic books. Plex Web shows photos; Plex for Android does not |
| Recording TV | Yes | No |

## Einen Weg wählen {#pick-a-way}

| | Neben Plex | Statt Plex |
|---|---|---|
| Was du bekommst | rex neben deinem Plex. Deine Apps zeigen beide Server an | rex allein, auf dem üblichen Port von Plex |
| Gut für | rex ausprobieren, oder Plex für Fotos oder Musik von einer Festplatte behalten, oder TV aufnehmen | Endgültig umziehen |
| Auf demselben Rechner wie Plex | rex läuft auf Port `32500`, und deine Apps finden es über den Plex-Account, mit dem es geteilt ist | Plex wird gestoppt, rex übernimmt Port `32400`, und Apps zu Hause finden es von selbst |

Fang neben Plex an, auch wenn du es ersetzen willst: Zum Kopieren deines Sehverlaufs muss dein alter Plex-Server laufen. Mach Schritt 1 bis 3, nutz rex eine Weile, und mach Schritt 4, wenn du bereit bist.

## Schritt 1: rex neben Plex einrichten {#step-1-set-up-rex-beside-plex}

Richte rex mit der Quelle ein, die es füllt, wie in [rex mit deiner eigenen App](any-source.md), [rex mit deinen Stremio-Addons](stremio.md) oder [rex mit zurg](with-zurg.md), bis du etwas anschauen kannst. Nutzt du zurg schon für Plex? Dann überspring die Installation und aktualisiere es, wie Schritt 1 von rex mit zurg zeigt: zurg versorgt rex ab dem Nightly **2026.10.27**.

- **Läuft Plex auf demselben Rechner?** Setz rex auf Port `32500`, wie [Rex installieren](any-source.md#step-1-install-rex) es für diesen Fall beschreibt, und gib auch deiner Quelle diesen Port. Deine Apps zeigen dann zwei Server mit dem Namen des Rechners: rex ist der, der mit dir geteilt wird, daneben steht der Name des neuen Accounts. [Rex installieren](any-source.md#step-1-install-rex) erklärt, wie du ihn umbenennst.
- **Registriere rex mit einem neuen Plex-Account,** nicht mit dem, auf dem dein Plex-Server läuft, wie [Zu einem Plex-Account hinzufügen](any-source.md#step-3-add-it-to-a-plex-account) erklärt.
- **Unterwegs mit rex-direct?** Der Port 32400 deines Routers zeigt bereits auf Plex. Leite zusätzlich Port `32500` an den rex-Rechner weiter oder, [über IPv6](any-source.md#rex-direct-over-ipv6), lass `32500` zu ihm durch.

Nutzt du zurg? Solange beide laufen, versorgt zurg beide. Lass alles, was zurg für Plex hat, wie es ist (`plex_server_url`, `plex_token`, dein rclone-Mount und jedes Scan-Skript): Plex läuft weiter wie bisher, und `rex_url` fügt rex hinzu.

## Schritt 2: Deinen Wiedergabeverlauf übernehmen {#step-2-bring-your-watch-history}

Sobald deine Bibliothek in rex ist, kopiert [Bring your watch history](import-watched.md) dein Sehverlauf, die Stelle, an der du aufgehört hast, und deine Sternebewertungen vom Plex-Server. Mach das, solange Plex noch läuft. Jede Person, mit der du teilst, führt es für ihren eigenen Verlauf aus.

## Schritt 3: Deine Leute wieder einladen {#step-3-invite-your-people-again}

Deine Freunde und Familie wurden zu deinem Plex-Server eingeladen, nicht zu rex. rex ist ein neuer Server auf dem frischen Account. Lade sie also von dort ein, und sie nehmen die Einladung an wie bei jeder anderen Freigabe: [Share rex with family and friends](sharing.md).

## Schritt 4: Plex ausmustern (optional) {#step-4-retire-plex-optional}

Nur zum Ersetzen von Plex. Überspringen, um beides zu behalten.

**Plex endgültig beenden.** Unter Linux: `sudo systemctl disable --now plexmediaserver`. In Docker stoppst du den Container und nimmst ihn aus deiner Compose-Datei raus. Unter Windows und macOS beendest du Plex Media Server und entfernst ihn aus den Apps, die beim Anmelden starten.

**Verschiebe rex auf Port 32400**, falls es auf `32500` neben Plex auf demselben Rechner lief:

1. Nimm `--port 32500` aus rex' Startbefehl heraus (oder aus der Zeile `command:` in Docker) und starte rex neu, so wie [rex installieren](any-source.md#step-1-install-rex) es für dein System zeigt. Unter Windows lässt du Port 32400 und die beiden Discovery-Ports durch die Firewall, wie dieser Schritt es beschreibt.
2. Gib deiner Quelle die neue Adresse von rex, `http://192.168.1.20:32400` (die LAN-IP von rex), und starte sie neu: zurgs `rex_url`, oder **rex's address** auf der Einstellungsseite von rex-stremio.
3. Ändere `32500` zu `32400` überall sonst, wo du die Adresse von rex angegeben hast, z. B. in Kometa.
4. Bei rex-direct zeigst du die Portweiterleitung deines Routers auf Port 32400 auf den rex-Rechner und entfernst die für `32500`. Über IPv6 änderst du die Firewall-Regel von `32500` auf `32400` und startest rex neu, damit es seine IPv6-Adresse auf dem neuen Port anbietet.

rex antwortet dann auf Port 32400, und Plex-Apps zu Hause finden es selbstständig in deinem Netzwerk.

**Zurg im Einsatz? Räum seine Plex-Einstellungen auf.** zurgs Konfiguration zeigt womöglich noch auf den Plex, den du beendet hast:

| In zurgs `config.yml` | Was zu tun ist |
|---|---|
| `plex_server_url` und `plex_token` | Lösch beide, oder drücke im zurg-Dashboard (Konfigurationsseite, **Media Server Integration**) neben Plex auf **Remove**. Nutzt du zurgs [Plex-Watchlist](../zurg/guides/plex-watchlist.md)? Dann lösch nur `plex_server_url`: Die Watchlist wird mit `plex_token` von plex.tv gelesen und braucht keinen Plex-Server. Alternativ kannst du sie auf rex zeigen lassen: Drück dort **Re-Auth**, melde dich mit dem neuen Account an und wähle rex. zurg ab Version 2026.10.27 erkennt, dass der Server rex ist, und schickt ihm keine Scans, Plex-Abgleiche, Staffel-Korrekturen oder Plex-Einstellungsprüfungen mehr. Der Token gehört dann zum neuen Account, und eine Plex-Watchlist würde diesem Account folgen |
| `on_library_update` mit einem Plex-Scan, etwa `plex_update.sh` | Lösch es. rex erfährt von jeder Änderung direkt von zurg |
| `plex_database_path`, `plex_scan_check_url` und `plex_scan_check_token` | Lösch sie. Sie verweisen auf den Plex, den du beendet hast |
| Dein rclone-Mount (`rclone_enabled: true`, oder rclone, das du selbst betreibst) | Behalte ihn, wenn Sonarr, Radarr, Bazarr oder etwas anderes Dateien dort liest. War Plex der einzige Leser, kannst du ihn ausschalten: rex liest jede Datei direkt von zurg |

Starte zurg nach dem Bearbeiten der Konfiguration neu.

## Was mitkommt und was nicht {#what-comes-along-and-what-does-not}

| Kommt mit | Wie |
|---|---|
| Deine Filme und Serien | Deine Quelle schickt sie an rex. Mit zurg kommen sie vom selben Debrid-Konto, das Plex liest |
| Was du angesehen hast, wo du aufgehört hast, deine Sternebewertungen für Filme und Folgen | [Bring deinen Sehverlauf mit](import-watched.md), jede Person für sich |

| Kommt nicht mit | Warum |
|---|---|
| Fix Matches, die du in Plex gemacht hast | rex nutzt die Zuordnungen von Plex nicht. Deine Quelle sagt, was jede Datei ist; korrigiere, was falsch ist, mit **Fix Match** in rex |
| Sammlungen | Werden nicht kopiert. [Kometa mit rex](kometa.md) baut sie anhand deiner Kometa-Konfiguration neu auf |
| Poster und Artwork, die du ausgewählt hast | Bleiben nur auf dem alten Server erhalten |
| Playlists und die Liste des Serververlaufs | Bleiben nur auf dem alten Server erhalten |
| Zugriff für deine Freunde | Sie wurden auf den alten Server eingeladen. Lade sie erneut zu rex ein ([Schritt 3](#step-3-invite-your-people-again)) |
| Musik und Fotos auf einer Festplatte, Live-TV von einem Tuner und Aufnahmen | rex hat keinen Tuner und nimmt nichts auf; Musik, Fotos und Live-Sender kommen nur von einer Quelle, die sie liefert. Behalte Plex dafür neben rex |
| Dateien auf einer lokalen Festplatte | rex scannt keine Ordner. Eine App muss sie bereitstellen und rex davon erzählen: [rex mit deiner eigenen App](any-source.md) |
