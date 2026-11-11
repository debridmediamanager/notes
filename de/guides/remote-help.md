# Hilfe zu zurg und rex holen {#getting-help-with-zurg-and-rex}

## Im Discord fragen {#ask-in-discord}

Erstelle im [Discord](https://discord.com/invite/7u4YjMThXP)-Forum einen Beitrag für das Tool, das du nutzt: **zurg-support**, **rex-support** oder **dmm-support**. Mach für jedes Problem einen eigenen Thread. Beschreib, was du gemacht hast, was du erwartet hast und was passiert ist. Füg die Details unten hinzu.

**Für zurg** klickst du auf **Export Logs** im zurg-Dashboard und fügst die Links ein, die es dir gibt. Dabei wird zurgs Log und Config hochgeladen, mit deinen Tokens, Passwörtern und API-Keys entfernt. Falls der Upload nicht klappt, gibt dir **Download Logs** dasselbe als Datei zum Anhängen. Füg außerdem die Ausgabe von `zurg doctor` ein:

| zurg läuft als | Ausführen |
|---|---|
| Die Binärdatei unter Linux oder macOS | `./zurg doctor` im zurg-Ordner |
| Die Binärdatei unter Windows | `.\zurg.exe doctor` im zurg-Ordner |
| Docker | `docker compose exec zurg /app/zurg doctor --working-dir /config` |

**Für rex** drückst du einmal auf **Play** bei dem, was fehlschlägt, und fügst dann das Ende von rex' Log ein. rex maskiert die Plex-Tokens darin.

| rex läuft als | Ausführen |
|---|---|
| Ein systemd-Dienst unter Linux | `journalctl --user -u rex -n 200 --no-pager` |
| launchd unter macOS | `tail -n 200 ~/rex/rex.log` |
| Task Scheduler unter Windows | `Get-Content $HOME\rex\rex.log -Tail 200` |
| Docker | `docker compose logs --tail=200 rex` |
| Ein Terminalfenster | Die letzten 200 Zeilen in diesem Fenster |

In einem langen Log sind die wichtigsten Zeilen die Fehler, die Warnungen und die Entscheidungen, die rex für jeden Abspielvorgang getroffen hat. Füg `| grep -E 'ERROR|WARN|upstream|DECISION'` an die Zeile für Linux, macOS oder Docker an, um nur diese zu sehen. Unter Windows führst du stattdessen `Select-String 'ERROR|WARN|upstream|DECISION' $HOME\rex\rex.log | Select-Object -Last 50` aus.

## Remote-Hilfe für Sponsoren {#remote-help-for-sponsors}

Wenn ein Thread das Problem nicht löst, kann ein Helfer in deinem Terminal tippen, während du zuschaust. **Remote-Hilfe für zurg und rex gibt es für Sponsoren, und sie ist kostenlos.** [Werde Sponsor auf gatekeeper](https://gatekeeper.debridmediamanager.com/). Verbinde dort Discord, um die Sponsor-Rolle zu bekommen, und frag dann in deinem Support-Thread.

Diese Seite richtet es mit [upterm](https://github.com/owenthereal/upterm) über `upterm.debridmediamanager.com` ein. Es funktioniert unter Linux, macOS und Windows.

Du brauchst kein Konto, kein Passwort, keine Router-Änderung und keine vorherige Installation. Die Befehle laden upterm herunter und starten es. Verfolge jeden Befehl im selben Terminal. Tippe `exit`, um die Sitzung zu beenden.

### 1. Rechner auswählen {#1-pick-the-machine}

Führe upterm auf dem Rechner aus, auf dem zurg oder rex läuft. Das kann ein Server sein und nicht der Computer, vor dem du sitzt.

| Wo es läuft | Was zu tun ist |
|---|---|
| Dieser Computer | Öffne hier ein Terminal und mach weiter mit Schritt 2. |
| Ein Cloud-Server wie Hetzner oder Oracle oder ein VPS | Verbinde dich zuerst per SSH damit. Dann nutze die Linux-Zeile aus Schritt 2 in diesem SSH-Fenster. |
| Ein NAS oder Server zu Hause wie Synology oder Unraid | Öffne dessen Terminal. Dann nutze dort die Linux-Zeile aus Schritt 2. |
| Docker | Nimm den Rechner, auf dem Docker läuft, und nicht einen Container. |

Du kannst auch unter Windows per SSH arbeiten. PowerShell hat `ssh` schon eingebaut.

```bash
ssh you@your-server
```

**Synology** hat SSH standardmäßig ausgeschaltet. Schalte es unter Systemsteuerung > Terminal & SNMP > Enable SSH service ein. Melde dich dann mit einem Admin-Konto an. Die NAS-Adresse findest du im Router oder in Synology Assistant.

Wenn Schritt 2 auf Synology `cannot create directory` ausgibt, schalte unter Systemsteuerung > Benutzer & Gruppe > Erweitert > Enable user home service ein und führe es noch einmal aus.

**Unraid** hat ein Terminal in seiner Weboberfläche. Klicke oben rechts auf das `>_`-Symbol.

### 2. Sitzung starten {#2-start-a-session}

Füge die Zeile für das System ein, das du in Schritt 1 gewählt hast.

#### Linux und macOS {#linux-and-macos}

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

#### Windows

Öffne PowerShell. Du musst sie nicht als Administrator starten.

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz" -UseBasicParsing; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

Auf einem ARM-Laptop wie einem Surface Pro X ersetzt du `amd64` durch `arm64`.

Beim ersten Mal fragt upterm, ob du `upterm.debridmediamanager.com` vertrauen möchtest. Tippe `yes` ein. Der Fingerabdruck, den es anzeigt, sollte dieser hier sein.

```
SHA256:r1LtSiydnfetLGxGt8hy+ULyqtN2KgnZSHtRgHzDr58
```

### 3. Die SSH-Zeile an deinen Helfer schicken {#3-send-the-ssh-line-to-your-helper}

upterm gibt ein paar Zeilen aus. Kopiere die Zeile unter **SSH**, die so aussieht.

```
ssh AbCdEfGhIjKlMnOpQrSt:dXB0ZXJt...@upterm.debridmediamanager.com -p 2222
```

**Schick sie per Privatnachricht.** Poste sie niemals in einem öffentlichen Kanal. Wer sie hat, kann auf deinem Rechner tippen.

Lass danach das Fenster offen und klick nicht hinein. Unter Windows kann ein Klick in einem PowerShell-Fenster die Ausführung darin anhalten, bis du `Esc` drückst. Alles, was dein Helfer in dieses Fenster tippt, siehst du in dem Moment, in dem er es tippt.

### 4. Sitzung beenden {#4-end-it}

**Schreib `exit` in dieses Fenster, wenn du fertig bist.** Die Sitzung endet und die Verbindung funktioniert sofort nicht mehr.

Das Fenster einfach zu schließen reicht nicht: die Sitzung läuft weiter. Wenn du das Fenster geschlossen hast, öffne ein neues Terminal, führe `~/upterm/upterm session list` aus (unter Windows `& "$env:LOCALAPPDATA\upterm\upterm.exe" session list`) und dann dasselbe Programm mit `session stop` und dem Namen, den es anzeigt.

Wenn du später wieder Hilfe brauchst, füge die Zeile aus Schritt 2 erneut ein. Jede Sitzung bekommt eine neue Zeile.

## Für Helfer {#for-helpers}

Führe die SSH-Zeile aus, die dir geschickt wurde. Jeder SSH-Schlüssel funktioniert. Falls du keinen hast, führe einmal `ssh-keygen -t ed25519` aus. Danach landest du im Terminal des Gegenübers: PowerShell unter Windows, die übliche Shell unter Linux und macOS.

Zum Kopieren einer Datei stört das `:` der Session-ID `scp`. Übergib sie deshalb als Benutzernamen: `scp -P 2222 -o User=<everything before the @> file upterm.debridmediamanager.com:file`.

Bitte die Person, `exit` einzutippen, wenn du fertig bist.
