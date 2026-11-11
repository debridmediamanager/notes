# macOS-Tutorial {#macos-tutorial}

## Einzeilige Option {#one-line-option}

Das optionale Sponsor-Bootstrap installiert macFUSE bei Bedarf, lädt den Build für Intel oder Apple Silicon herunter und startet
den Provider-Auswahldialog sowie die Diagnose:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Es nutzt die Anmeldung über den Browser bei GitHub. macOS muss unter **System Settings > Privacy & Security** möglicherweise noch
bestätigt werden, und danach ist eventuell ein Neustart nötig. Vorhandene Binaries und Konfigurationen bleiben erhalten. Weiter unten findest du den manuellen Weg.

## Schritt 1: macFUSE installieren {#step-1-install-macfuse}

macFUSE lässt rclone das virtuelle Dateisystem von zurg als echtes Verzeichnis auf deinem Mac einbinden.

1. Lade die neueste `.dmg` von [macfuse.io](https://macfuse.io) herunter.
2. Öffne die `.dmg` und starte den Installer.
3. Während der Installation blockiert macOS die Systemerweiterung. Gehe zu **Systemeinstellungen > Datenschutz & Sicherheit**, scrolle nach unten und klicke auf **Allow**.
4. **Starte deinen Mac neu** (das ist nötig, damit die Kernel-Erweiterung geladen wird).

Öffne nach dem Neustart das **Terminal** (drücke `Cmd + Space`, tippe „Terminal“ und drücke Enter) und prüfe, ob macOS macFUSE laden wird. Das ist dieselbe Prüfung, die `zurg setup` macht:

```bash
/Library/Filesystems/macfuse.fs/Contents/Resources/load_macfuse && echo "macFUSE is ready"
```

Wenn `macFUSE is ready` nicht erscheint, hat macOS die Erweiterung noch nicht erlaubt. Auf Macs mit Apple Silicon aktivierst du in der Recovery die Kernel-Erweiterungen von Drittanbietern. Erlaube dann macFUSE unter **Systemeinstellungen > Datenschutz & Sicherheit**, starte neu und prüfe noch einmal.

## Schritt 2: zurg herunterladen {#step-2-download-zurg}

Öffne [GitHub Releases](https://github.com/debridmediamanager/zurg/releases) in einem Browser, in dem du mit dem GitHub-Konto angemeldet bist, das Zugriff auf zurg hat. Nimm den neuesten Nightly-Build. Das ist das Pre-Release ganz oben in der Liste. Lade die ZIP-Datei `darwin-arm64` herunter, oder `darwin-amd64` auf einem Intel-Mac. Nimm nicht das Release, das GitHub als **Latest** markiert. Das ist v1.0.0. Es ist älter als `zurg setup` und antwortet darauf mit `unknown command`.

Nightlies sind für Sponsoren gedacht. Solange dein GitHub-Konto keinen Zugriff hat, zeigt diese Seite 404 an. Werde Sponsor auf [gatekeeper](https://gatekeeper.debridmediamanager.com/), dann bekommt das Konto Zugriff. Die kostenlose öffentliche Version ist v1.0.0 von [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). Sie hat kein `zurg setup`. Richte sie von Hand ein, so wie es [die README](https://github.com/debridmediamanager/zurg-public#readme) erklärt, statt den Schritten unten zu folgen.

Entpacke sie dann.

```bash
mkdir -p ~/zurg && cd ~/zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
```

Prüfen:

```bash
./zurg version
```

## Empfohlen: zurg die Einrichtung fertigstellen lassen {#recommended-let-zurg-finish-the-setup}

Aus dem entpackten Verzeichnis führst du aus:

```bash
./zurg setup
./zurg doctor
```

`setup` fragt, welche Provider du einrichten willst. Wähle einen oder mehrere von Real-Debrid, TorBox, AllDebrid, Usenet, Premiumize, Debrid-Link und Offcloud, in der gewünschten Prioritätsreihenfolge. Gibst du zum Beispiel `2,4` ein, ist TorBox zuerst dran und danach Usenet. Es fragt nur die Zugangsdaten für die ausgewählten Provider ab, erstellt `config.yml` mit dem Modus `0600`, lädt rclone (und ffprobe, falls es nicht schon in deinem PATH liegt) herunter, bereitet `/Volumes/Zurg` vor und richtet den Autostart ein.

Ist für den aktuellen Benutzer eine grafische launchd-Domain vorhanden, nimmt es einen LaunchAgent. Auf einem Mac ohne Desktop und ohne angemeldeten GUI-Benutzer installiert es einen systemweiten LaunchDaemon, der zurg trotzdem als aktueller Benutzer startet. Für diesen Weg ist keine automatische Anmeldung nötig.

Die Prüfung der Voraussetzungen unterscheidet zwischen einem installierten macFUSE-Paket und einer Erweiterung, die macOS tatsächlich laden kann. Auf Apple-Silicon-Macs kann die erste macFUSE-Installation eine einmalige Änderung der Sicherheitseinstellungen in der macOS-Wiederherstellung, eine Freigabe unter **System Settings > Privacy & Security** und einen Neustart erfordern. Kein Installer kann diese Bestätigungen umgehen.

Setup kannst du gefahrlos erneut ausführen. Dabei wird der generierte launchd-Dienst aktualisiert, eine vorhandene `config.yml` bleibt aber unverändert.

Bevor du über den Mount streamst, öffne `config.yml` oder das Dashboard unter `http://localhost:9999/config/` und setze unter `rclone_extra_args` sowohl `--vfs-cache-max-size` als auch `--vfs-cache-min-free-space`. Die maximale Größe sollte unter der Hälfte des aktuell freien Speicherplatzes liegen. Mit der Einstellung für den minimal freien Speicherplatz reservierst du mindestens `20G`. Starte danach `./zurg service restart`.

Der Rest dieser Seite erklärt die Konfiguration und die Plex-Einrichtung. Die Schritte 3, 4, 5 und 7 sind die manuelle Alternative und können übersprungen werden, wenn `zurg setup` erfolgreich war.

## Schritt 3: zurg manuell konfigurieren {#step-3-configure-zurg-manually}

Erstelle eine Konfigurationsdatei mit deinem Real-Debrid-API-Token:

```bash
cd ~/zurg
cat > config.yml << 'EOF'
# Minimal config - use Dashboard at http://localhost:9999/config/ for more settings
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN_HERE

rclone_enabled: true
mount_path: /Volumes/Zurg

rclone_extra_args:
  - "--vfs-cache-max-size"
  - "100G"
  - "--vfs-cache-min-free-space"
  - "20G"

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
EOF
```

Ersetze den Platzhalter-Token durch deinen echten Token von [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354):

```bash
sed -i '' "s|YOUR_RD_API_TOKEN_HERE|PASTE_YOUR_TOKEN_HERE|g" ~/zurg/config.yml
```

> **Lass `mount_path` nicht weg.** rclone würde ohne diese Angabe auf macOS `/Volumes/Zurg` verwenden. Das Scannen durch den Medienserver ist aber nur aktiv, wenn `mount_path` explizit gesetzt ist. Lässt du es weg, bekommt Plex nie Bescheid, dass es aktualisieren soll (Schritt 6).

> **Die Cache-Größe ist entscheidend.** Der VFS-Cache speichert Teile der gestreamten Dateien auf deiner lokalen Festplatte. Wenn er die Festplatte füllt, wird macOS stark ausgebremst. Dann können Spotlight, Plex und sogar das System selbst nicht mehr reagieren. Setze immer **beide** Grenzen:
>
> - `--vfs-cache-max-size`: harte Obergrenze für die Gesamtgröße des Caches. Setze sie auf **maximal 50 % deines freien Speicherplatzes**. Prüfe den Wert mit `df -h /`.
> - `--vfs-cache-min-free-space`: stoppt das Caching, sobald der freie Speicherplatz unter diesen Wert fällt. Lass ihn bei **20G oder höher** als Sicherheitsnetz.
>
> Beispiel: Bei einer 256-GB-Festplatte mit 100 GB frei verwendest du `50G` als maximale Größe und `20G` als minimalen freien Speicherplatz.

## Schritt 4: Abhängigkeiten manuell herunterladen {#step-4-download-dependencies-manually}

zurg hat einen eingebauten Befehl, der rclone und ffprobe herunterlädt und `config.yml` mit deren Pfaden aktualisiert:

```bash
cd ~/zurg
./zurg download-requirements
```

Erstelle den Mount-Punkt und das Log-Verzeichnis. `/Volumes` gehört root, daher kann zurg `/Volumes/Zurg` nicht selbst anlegen. Das Log-Verzeichnis muss existieren, bevor launchd seine Ausgabedateien in Schritt 7 öffnet:

```bash
sudo mkdir -p /Volumes/Zurg
sudo chown "$(whoami)" /Volumes/Zurg
mkdir -p ~/zurg/logs
```

Alle verfügbaren Optionen findest du in der [Konfigurationsreferenz](../reference/config.md). Alternativ kannst du nach dem Start von zurg das Web-Dashboard unter `http://localhost:9999/config/` nutzen.

## Schritt 5: zurg manuell testen {#step-5-test-zurg-manually}

Bevor du den Autostart einrichtest, prüf, ob alles funktioniert:

```bash
cd ~/zurg && ./zurg
```

Du solltest Log-Ausgaben sehen, die zeigen, wie zurg startet, sich mit Real-Debrid verbindet und per rclone eingebunden wird. Prüf in einem zweiten Terminalfenster:

```bash
# Check the HTTP endpoint
curl -s http://localhost:9999/http/version.txt

# Check the mount
ls /Volumes/Zurg/
# Expected: __all__  __downloads__  __unplayable__  movies  shows  version.txt
```

Wenn alles gut aussieht, beende zurg mit `Ctrl+C`.

## Schritt 6: Plex Media Server installieren {#step-6-install-plex-media-server}

1. Lade es von [plex.tv/media-server-downloads](https://www.plex.tv/media-server-downloads/) herunter und wähle **macOS** (Universal)
2. Öffne die `.dmg` und ziehe **Plex Media Server** nach `/Applications`
3. Starte Plex Media Server aus dem Programme-Ordner (oder über Spotlight: `Cmd + Space` → „Plex Media Server“)
4. Dein Browser sollte sich mit dem Plex-Einrichtungsassistenten öffnen. Folge ihm, um deinen Server zu beanspruchen
5. **Autostart aktivieren:** Klicke mit der rechten Maustaste auf das Plex-Symbol in der Menüleiste und setze den Haken bei **Launch at Login**
6. Hol dir dein Plex-Token. Am einfachsten geht das so:
   - Öffne ein beliebiges Medium in Plex Web
   - Klicke auf **Get Info** (oder **...** → **Get Info**)
   - Klicke auf **View XML**
   - Suche in der Adresszeile nach `X-Plex-Token=`

Trage das Plex-Token in deine zurg-Konfiguration ein, indem du `config.yml` bearbeitest:

```yaml
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
```

## Schritt 7: zurg-Autostart manuell einrichten {#step-7-set-up-zurg-auto-start-manually}

macOS-LaunchAgents starten Dienste automatisch, wenn du dich anmeldest. Plex kümmert sich schon selbst um den Autostart (Schritt 6), deshalb brauchen wir nur einen LaunchAgent für zurg.

### zurg LaunchAgent

```bash
cat > ~/Library/LaunchAgents/com.zurg.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zurg</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/zurg/zurg</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${HOME}/zurg</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME}/zurg/logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME}/zurg/logs/launchd-stderr.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST
```

Wichtige Einstellungen:
- **RunAtLoad** — startet zurg, wenn du dich anmeldest
- **KeepAlive / SuccessfulExit: false** — wenn zurg abstürzt, startet launchd es automatisch neu
- **ThrottleInterval: 10** — wartet 10 Sekunden zwischen den Neustartversuchen

### Den LaunchAgent laden {#load-the-launchagent}

```bash
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Prüfe, ob es registriert ist:

```bash
launchctl list | grep zurg
# Should show com.zurg with a PID
```

## Schritt 8: Plex-Bibliotheken einrichten {#step-8-configure-plex-libraries}

Jetzt, wo zurg läuft und das Mount aktiv ist:

1. Öffne [http://localhost:32400/web](http://localhost:32400/web)
2. Gehe zu **Settings** (Schraubenschlüssel-Symbol) → **Manage** → **Libraries**
3. Klicke auf **Add Library**

**Movies-Bibliothek hinzufügen:**
- Type: **Movies**
- Klicke auf **Browse for media folder**
- Navigiere zu `/Volumes/Zurg/movies`
- Klicke auf **Add Library**

**TV-Shows-Bibliothek hinzufügen:**
- Type: **TV Shows**
- Klicke auf **Browse for media folder**
- Navigiere zu `/Volumes/Zurg/shows`
- Klicke auf **Add Library**

**Empfohlene Bibliothekseinstellungen** (unter Edit → Advanced der jeweiligen Bibliothek):
- Deaktiviere **Empty trash automatically after every scan** — zurg verwaltet den Lebenszyklus der Inhalte
- Deaktiviere **Generate video preview thumbnails** — spart Bandbreite, da die Dateien von Real-Debrid gestreamt werden

## Schritt 9: Prüfen, ob alles funktioniert {#step-9-verify-everything-works}

```bash
# 1. zurg is running
curl -s http://localhost:9999/http/version.txt && echo " - zurg is up"

# 2. Mount is active
ls /Volumes/Zurg/movies > /dev/null 2>&1 && echo "Mount is active"

# 3. Plex is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:32400/identity && echo " - Plex is up"

# 4. Processes
ps -eo pid,command | grep -E "[z]urg|[r]clone.*mount|[P]lex Media Server" | head -5

# 5. zurg service (for the manual LaunchAgent from Step 7: launchctl list | grep com.zurg)
cd ~/zurg && ./zurg service status
```

## Schritt 10: Automatische Anmeldung aktivieren (optional) {#step-10-enable-auto-login-optional}

Das ist nur für den manuellen LaunchAgent-Weg nötig. Ein LaunchAgent verlangt, dass sich ein Benutzer nach jedem Neustart anmeldet. Der eingebaute Installer nutzt stattdessen einen LaunchDaemon auf einem Headless-Mac.

Wenn du den manuellen LaunchAgent bewusst auf einem Headless-Server verwendest, aktiviere die automatische Anmeldung, damit er ohne Eingriff startet:

1. Öffne **Systemeinstellungen**
2. Gehe zu **Benutzer & Gruppen**
3. Klicke auf **Automatische Anmeldung** und wähle deinen Benutzer aus
4. Gib dein Passwort ein

> **Sicherheitshinweis:** Bei automatischer Anmeldung kann jeder, der physischen Zugang zum Mac hat, auf dein Konto zugreifen. Nutze das nur auf Geräten an einem vertrauenswürdigen Ort.

---

## Die Dienste verwalten {#managing-the-services}

Bei einer Installation, die mit `zurg setup` erstellt wurde, verwendest du auf allen Plattformen dieselben Befehle:

```bash
cd ~/zurg
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` entfernt nur den Autostart. Die Binärdatei, Konfiguration, Daten, Logs und der Cache bleiben erhalten. Die launchctl-Befehle unten gelten für den manuellen LaunchAgent aus Schritt 7 (`com.zurg`). `zurg setup` verwendet dafür den eigenen Namen `com.zurg.zurg`.

### Starten / Stoppen / Neustarten {#start--stop--restart}

```bash
# Stop zurg (and its rclone child process)
launchctl stop com.zurg

# Start zurg
launchctl start com.zurg

# Restart zurg
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Logs anzeigen {#view-logs}

```bash
# zurg logs
tail -50 ~/zurg/logs/zurg.log

# Rclone logs
tail -50 ~/zurg/logs/rclone.log
```

### Nach Konfigurationsänderung neu laden {#reload-after-config-change}

Wenn du eine `.plist`-Datei bearbeitest:

```bash
launchctl unload ~/Library/LaunchAgents/com.zurg.plist
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Wenn du `config.yml` bearbeitest, starte zurg einfach neu:

```bash
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### zurg aktualisieren {#update-zurg}

Eine Sponsor-Build ersetzt sich selbst:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` holt sich die neueste Nightly. Es lädt sie herunter, prüft, ob das neue Binary die erwartete Version meldet, und tauscht es erst dann per Umbenennen aus, sodass der laufende Prozess nie überschrieben wird. Ist die installierte Build schon die neueste, sagt es das und ändert nichts.

`update` meldet sich bei GitHub mit dem Konto an, das du bei der Installation benutzt hast. Dafür legt der Installer die GitHub CLI in `~/zurg/bin` ab. Sagt `update`, es habe kein GitHub-Credential gefunden, dann ist deine Installation älter als diese Änderung. Führe einmal das Update des Installers aus, danach funktioniert jedes `zurg update`. Derselbe Befehl aktualisiert auch eine Build, die zu alt ist, um `zurg update` zu haben.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

Alternativ kannst du auch `GITHUB_TOKEN` setzen. Nimm dafür ein klassisches Token mit dem Scope `repo` aus dem GitHub-Konto, das Zugriff auf zurg hat.

Von Hand lädst du die neue `darwin-arm64`-ZIP-Datei (`darwin-amd64` auf einem Intel-Mac) von [Releases](https://github.com/debridmediamanager/zurg/releases) genauso herunter wie in Schritt 2, danach:

```bash
cd ~/zurg
./zurg service stop && sleep 2     # manual LaunchAgent: launchctl stop com.zurg
rm -f zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
./zurg service start               # manual LaunchAgent: launchctl start com.zurg
```

Lösche die alte Binary, statt sie an Ort und Stelle zu überschreiben. Das Neuschreiben der Datei behält dieselbe Inode und macht die Ad-hoc-Code-Signatur ungültig. macOS beendet die neue Build dann beim Start, und das Symptom ist ein sofortiger Abbruch ganz ohne Ausgabe. Genau deshalb tauscht `zurg update` per Umbenennen.

## Fehlerbehebung {#troubleshooting}

### "Operation not permitted" beim Mounten {#operation-not-permitted-when-mounting}

macFUSE muss in den Systemeinstellungen freigegeben werden:
1. Öffne **Systemeinstellungen > Datenschutz & Sicherheit**
2. Scrolle nach unten und suche nach einer Meldung zu einer blockierten Systemerweiterung
3. Klicke auf **Erlauben** und starte dann den Rechner **neu**

### Mount wird als "not a directory" angezeigt oder hängt {#mount-shows-as-not-a-directory-or-hangs}

Der Mount-Punkt ist möglicherweise veraltet, weil es vorher abgestürzt ist:

```bash
umount -f /Volumes/Zurg 2>/dev/null
diskutil unmount force /Volumes/Zurg 2>/dev/null
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### zurg startet immer wieder neu (Crash-Schleife) {#zurg-keeps-restarting-crash-loop}

Schau in die Logs nach dem Fehler:

```bash
tail -100 ~/zurg/logs/service-stderr.log   # manual LaunchAgent: launchd-stderr.log
```

Häufige Ursachen:
- Ungültige Syntax in `config.yml` — prüfe sie manuell mit `cd ~/zurg && ./zurg`
- Abgelaufener Real-Debrid-Token — hol dir einen neuen auf [real-debrid.com/apitoken](http://real-debrid.com/?id=20476410)
- `/Volumes/Zurg` fehlt oder gehört nicht deinem Benutzer — zurg kann es nicht anlegen und bricht mit `ensure mount path: permission denied` ab (Schritt 4)
- Port 9999 ist schon belegt — prüfe das mit `lsof -i :9999`

### macFUSE funktioniert nach macOS-Update nicht mehr {#macfuse-breaks-after-macos-update}

Größere macOS-Updates machen die Kernel-Erweiterung manchmal unbrauchbar. Installiere macFUSE dann neu:
1. Lade die neueste Version von [macfuse.io](https://macfuse.io) herunter
2. Installiere sie
3. Erlaube die Erweiterung in **System Settings > Privacy & Security**
4. Starte deinen Mac neu

### Alles lief, aber nach dem Neustart ging es nicht mehr {#everything-was-working-but-stopped-after-reboot}

Wenn du das manuelle LaunchAgent installiert hast und die automatische Anmeldung nicht aktiviert ist, musst du dich anmelden, bevor es startet. Entweder:
- Aktiviere die automatische Anmeldung (siehe Schritt 10)
- Verbinde dich per SSH — die LaunchAgents werden automatisch geladen, sobald die Benutzersitzung existiert
- Melde dich über VNC/Screen Sharing aus der Ferne an

Eine Installation, die `zurg setup` auf einem Mac ohne Bildschirm erstellt, nutzt einen LaunchDaemon und braucht keine grafische Anmeldung. Prüfe das mit `cd ~/zurg && ./zurg service status`.

Immer noch Probleme? Frag im **zurg-support**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) erklärt, was du angeben solltest.

## Architekturübersicht {#architecture-overview}

```
launchd (PID 1)

  com.zurg LaunchAgent
    └── ./zurg
          ├── HTTP/WebDAV server (:9999)
          ├── Dashboard UI (:9999/config/)
          ├── Real-Debrid API client
          └── rclone mount (child process)
                └── /Volumes/Zurg/
                      ├── movies/
                      └── shows/

  Plex Media Server (:32400)  — Launch at Login via menu bar
    ├── Movies library  → /Volumes/Zurg/movies
    └── Shows library   → /Volumes/Zurg/shows

  macFUSE kernel extension
    └── Enables FUSE mounts for rclone
```

## Kurzübersicht {#quick-reference}

Führe diese Befehle in `~/zurg` aus. Die Zeilen mit `zurg service` gelten für eine Installation, die mit `zurg setup` erstellt wurde. Der manuelle LaunchAgent nutzt die launchctl-Befehle unter [Dienste verwalten](#managing-the-services).

| Aktion | Befehl |
|--------|--------|
| zurg starten | `./zurg service start` |
| zurg stoppen | `./zurg service stop` |
| zurg neu starten | `./zurg service restart` |
| Installation prüfen | `./zurg doctor` |
| Autostart entfernen | `./zurg service uninstall` |
| zurg-Logs anzeigen | `tail -f ~/zurg/logs/zurg.log` |
| rclone-Logs anzeigen | `tail -f ~/zurg/logs/rclone.log` |
| Mount prüfen | `ls /Volumes/Zurg/` |
| zurg-Status prüfen | `curl http://localhost:9999/http/version.txt` |
| Plex-Status prüfen | `curl http://localhost:32400/identity` |
| Dashboard | `open http://localhost:9999/config/` |
| Erzwungen aushängen | `umount -f /Volumes/Zurg` |
