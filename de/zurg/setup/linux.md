# Linux-Binary-Setup {#linux-binary-setup}

## Einzeilige Option {#one-line-option}

Die optionale Sponsor-Bootstrap installiert Systempakete, lädt den passenden CPU-Build herunter und führt Setup und Diagnose aus:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Sie meldet sich über GitHub an und installiert nach `~/zurg`. Vorhandene Binaries und Konfigurationen bleiben erhalten. Weiter unten findest du den manuellen Weg oder einen eigenen Pfad.

Das zurg-Binary kann den Rest der Installation selbst übernehmen. Es schreibt die Konfiguration, lädt den passenden rclone (und ffprobe, sofern nicht schon eines in deinem PATH liegt) für das System herunter, legt den Mount an und registriert einen aktivierten systemd-Dienst.

Dieser Ablauf wurde am 4. September 2026 auf frischen Ubuntu-24.04-Servern mit ARM64 und x86_64 getestet.

## 1. FUSE 3 installieren {#1-install-fuse-3}

Auf Debian, Ubuntu und deren Ableitungen:

```bash
sudo apt-get update
sudo apt-get install -y fuse3
```

Andere Distributionen nennen das Paket ebenfalls `fuse3`: `sudo dnf install fuse3` auf Fedora, `sudo pacman -S fuse3` auf Arch, `sudo zypper install fuse3` auf openSUSE.

Prüfe, ob der Helfer und das Gerät vorhanden sind:

```bash
command -v fusermount3
test -c /dev/fuse
```

Wenn Plex, Jellyfin oder ein anderer Prozess unter einem anderen Unix-Benutzer läuft, aktiviere `allow_other` einmalig:

```bash
echo user_allow_other | sudo tee -a /etc/fuse.conf
```

Ohne diese Einstellung funktioniert der Mount trotzdem, aber nur das Konto, unter dem zurg läuft, kann darauf zugreifen. `zurg doctor` zeigt dir den Unterschied an.

## 2. zurg herunterladen {#2-download-zurg}

Lade das passende Linux-Archiv von den [Sponsor-Releases](https://github.com/debridmediamanager/zurg/releases) herunter. Wähle `linux-amd64` für einen Intel- oder AMD-Rechner und `linux-arm64` für einen ARM-Rechner.

Nimm die neueste Nightly. Sie ist das Pre-Release ganz oben in der Liste. Nimm nicht das Release, das GitHub als **Latest** markiert. Das ist v1.0.0. Es ist älter als `zurg setup` und antwortet darauf mit `unknown command`.

Nightlies sind für Sponsoren. Solange dein GitHub-Konto keinen Zugriff hat, zeigt diese Seite 404 an. Werde Sponsor auf [gatekeeper](https://gatekeeper.debridmediamanager.com/), um Zugriff zu bekommen. Der kostenlose öffentliche Build ist v1.0.0 aus [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). Er hat kein `zurg setup`. Richte ihn manuell ein, wie es [seine README](https://github.com/debridmediamanager/zurg-public#readme) erklärt, statt den Schritten unten zu folgen.

Entpacke es in das Verzeichnis, das die ganze Installation enthalten soll:

```bash
mkdir -p ~/zurg
cd ~/zurg
# Put the downloaded zurg binary here, then:
chmod +x zurg
```

Alles, was zurg speichert, bleibt neben dieser Binärdatei: `config.yml`, heruntergeladene Helfer, Bibliotheksstatus, Logs und der rclone-Cache.

## 3. Setup ausführen {#3-run-setup}

```bash
cd ~/zurg
./zurg setup
```

Das Setup fragt, welche Anbieter du konfigurieren willst. Wähle einen oder mehrere in Prioritätsreihenfolge:

```text
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
```

Gibst du zum Beispiel `2,4` ein, wird TorBox gefolgt von Usenet gewählt. Das Setup fragt nur nach den ausgewählten Zugangsdaten. Danach:

1. Erstellt und prüft `config.yml`.
2. Beschränkt die Konfiguration mit dem Modus `0600` auf den Besitzer.
3. Lädt einen nativen rclone nach `bin/` herunter, und ffprobe ebenfalls, außer eines ist bereits in deinem PATH.
4. Aktiviert den rclone-Mount unter `/mnt/zurg`.
5. Installiert und startet einen aktivierten systemd-Dienst.

Wenn du keine Berechtigung hast, `/mnt/zurg` anzulegen, verwende einen Mount in deinem Home-Verzeichnis:

```bash
./zurg setup --mount-path "$HOME/zurg-mount"
```

Das Setup kannst du gefahrlos erneut ausführen. Es aktualisiert den erzeugten Dienst, ersetzt aber keine vorhandene `config.yml`.

### Den systemd-Scope auswählen {#choosing-the-systemd-scope}

Mit einem funktionierenden systemd-User-Manager installiert die Standardeinstellung `auto` den Dienst unter `~/.config/systemd/user/zurg.service`. Andernfalls legt das Setup `/etc/systemd/system/zurg.service` an und bittet per sudo darum, ihn als aktueller Benutzer auszuführen.

Wenn nötig, kannst du die Variante selbst festlegen:

```bash
./zurg setup --service-scope user
./zurg setup --service-scope system --service-user "$USER"
```

Damit ein User-Dienst nach einem Neustart schon vor dem ersten Login startet, aktiviere Lingering:

```bash
loginctl show-user "$USER" -p Linger
sudo loginctl enable-linger "$USER"
```

Wenn du das Setup auf einem Server als `root` ausführst, wird ein System-Dienst gewählt, der root gehört.

## 4. Installation überprüfen {#4-verify-the-install}

```bash
./zurg doctor
curl -fsS http://127.0.0.1:9999/http/version.txt
ls /mnt/zurg/version.txt
```

`doctor` prüft die Konfiguration und ihre Berechtigungen, beide heruntergeladenen Tools, FUSE, die systemd-Unit, den HTTP-Endpunkt und den Mount, den zurg meldet.

Eine große Real-Debrid-Bibliothek braucht beim ersten Start etwas Zeit, bis sie aufgebaut ist. Der Dienst kann schon aktiv sein, während die erste Mount-Auflistung noch auf das Ende dieses Scans wartet.

`version.txt` antwortet, sobald zurg läuft. Eine große Bibliothek lädt danach aber weiter. Ihre Ordner erscheinen so lange leer oder als `Input/output error`, bis sie fertig ist. `/ready` sagt dir, wann es so weit ist.

```bash
curl -fsS http://127.0.0.1:9999/ready
```

## Festplatte, die der Mount nutzt {#disk-the-mount-uses}

Der Mount speichert jede Datei, die er liest, unter `~/zurg/data/rclone-cache` zwischen. Nach dem Ende der Wiedergabe behält er die ganze Datei.

Lässt du ihn so, wächst dieser Cache auf **256G** an und bleibt dort. Er wird auch nicht geleert, wenn ein Video stoppt. Auch die Altersgrenze von 72h hilft dir da nicht weiter. rclone zählt eine Datei als frisch genutzt, sobald sie irgendjemand liest, und der nächtliche Wartungslauf deines Medienservers liest die komplette Bibliothek.

Schau nach, was darin liegt.

```bash
du -sh ~/zurg/data/rclone-cache
```

Wenn dir 256G zu viel für die Festplatte sind, setz das Limit in `config.yml` niedriger.

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Starte danach zurg neu. Um den Cache von Hand zu leeren, beende zurg zuerst und führe dann dies aus.

```bash
rm -rf ~/zurg/data/rclone-cache/vfs/* ~/zurg/data/rclone-cache/vfsMeta/*
```

Verschiebst du das zurg-Verzeichnis, wird der Cache umbenannt und die alte Kopie bleibt liegen. zurg räumt diese beim nächsten Start auf und protokolliert, was es freigegeben hat. Details und die Möglichkeit, das abzuschalten, stehen in [der Konfigurationsreferenz](../reference/config.md#disk-the-mount-uses).

## zurg verwalten {#managing-zurg}

Führe diese Befehle im zurg-Verzeichnis aus:

```bash
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` entfernt nur den Autostart. Die Binärdatei, Konfiguration, Daten, Logs und der Cache bleiben erhalten.

Logs für einen Benutzerdienst live verfolgen:

```bash
journalctl --user -u zurg.service -f
```

Für einen Systemdienst:

```bash
sudo journalctl -u zurg.service -f
```

## zurg aktualisieren {#updating-zurg}

Ein Sponsor-Build ersetzt sich selbst:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` nimmt den neuesten Nightly-Build. Er lädt ihn herunter, prüft, ob das neue Binary die erwartete Version meldet, und tauscht es erst dann durch Umbenennen aus, sodass der laufende Prozess nie überschrieben wird. Ist der installierte Build bereits der neueste, sagt er das und ändert nichts.

`update` meldet sich bei GitHub mit dem Konto an, das du für die Installation verwendet hast. Dafür bewahrt der Installer die GitHub CLI in `~/zurg/bin` auf. Wenn `update` meldet, dass es keine GitHub-Zugangsdaten gefunden hat, ist deine Installation älter als diese Änderung. Führe einmal das Update des Installers aus, dann funktioniert jedes `zurg update` danach. Derselbe Befehl aktualisiert auch einen Build, der zu alt ist, um `zurg update` zu haben. Er tauscht nur das Binary aus und fasst sonst nichts an.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

Auf einem Server ohne GitHub CLI kannst du stattdessen `GITHUB_TOKEN` setzen. Verwende ein klassisches Token mit dem Scope `repo` aus dem GitHub-Konto, das Zugriff auf zurg hat.

## Bestehende und unbeaufsichtigte Konfigurationen {#existing-and-unattended-configs}

Setup ersetzt nie eine bestehende `config.yml`. Für unbeaufsichtigtes Setup wiederholst du `--provider` und gibst die passenden Token-Datei- oder `--nntp-*`-Flags an. `REALDEBRID_TOKEN`, `TORBOX_TOKEN`, `ALLDEBRID_TOKEN` und die `NNTP_*`-Variablen funktionieren auch. Führe `./zurg setup --help` aus, um die vollständige Liste zu sehen.

Alle Einstellungen findest du in der [Konfigurationsreferenz](../reference/config.md).

Immer noch festgefahren? Frag im **zurg-support**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) sagt dir, was du angeben solltest.

## Siehe auch {#see-also}

- [Docker](docker.md) — Container-Setup und FUSE-Mount-Propagation
- [macOS](macos.md) — derselbe Binary-Installer mit macFUSE und launchd
- [Windows](windows.md) — derselbe Binary-Installer mit WinFsp und einer interaktiven geplanten Aufgabe
