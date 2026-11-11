# Kommandozeile {#command-line}

Die zurg-Binary ist der Server und eine Sammlung von Werkzeugen. Starte sie ohne Befehl, um den Server zu starten. Jeder Befehl akzeptiert `--help` und gibt den Text aus, aus dem diese Seite geschrieben ist.

Führe Befehle aus dem Arbeitsverzeichnis der Instanz aus. zurg liest dort `./config.yml`, außer du übergibst `--config`. Auch seine Ordner für Daten und Logs beziehen sich auf dieses Verzeichnis.

```
zurg [flags]
zurg [command]
```

## Flags, die jeder Befehl akzeptiert {#flags-every-command-takes}

| Flag | Was er macht |
|---|---|
| `-c`, `--config` | Die Konfigurationsdatei, die gelesen wird. Standardmäßig `./config.yml`. |
| `-v`, `--version` | Gibt den Build aus und beendet sich. Die Ausgabe entspricht `zurg version`. |
| `-h`, `--help` | Zeigt die Hilfe für zurg oder für einen einzelnen Befehl an. |

## Einrichtung {#setting-up}

### zurg setup

Schreibt eine Konfiguration und lädt rclone und ffprobe herunter. Danach registriert es zurg, damit es von selbst startet. Es fragt nach allem, was fehlt. `--dry-run` zeigt den Plan an und ändert nichts.

Schlüssel und Passwörter werden aus Dateien gelesen. So landen sie nicht in deiner Shell-History.

| Flag | Was es macht |
|---|---|
| `--provider` | Ein Provider, der eingerichtet werden soll. Wiederhole die Option für mehr als einen. Einer von realdebrid, torbox, alldebrid, nzb, premiumize, debridlink, offcloud, torbox_nzb. torbox_nzb liest seinen Schlüssel aus `--torbox-token-file` oder `TORBOX_TOKEN`, so wie torbox es tut. |
| `--realdebrid-token-file` | Liest das Real-Debrid-Token aus dieser Datei. Dasselbe Flag gibt es für `torbox`, `alldebrid`, `premiumize`, `debridlink` und `offcloud`. |
| `--nntp-host` | Der News-Server für den Provider `nzb`. |
| `--nntp-port` | Sein Port. Standardmäßig 563 mit TLS und 119 ohne. |
| `--nntp-tls` | Verwendet TLS. Ist standardmäßig aktiv. |
| `--nntp-username` | Der Benutzername des News-Kontos. |
| `--nntp-password-file` | Liest das Passwort des News-Kontos aus dieser Datei. |
| `--nntp-connections` | Anzahl erlaubter Verbindungen des News-Kontos. Standardmäßig 8. |
| `--mount-path` | Der Ort, an dem der Mount erscheint. Standardmäßig die übliche Konvention für deine Plattform. |
| `--port` | Der HTTP-Port. Behält den Wert in der Konfiguration, wenn du ihn weglässt. |
| `--service-name` | Der Name des Dienstes oder der geplanten Aufgabe. Standardmäßig `zurg`. |
| `--service-scope` | `auto`, `user` oder `system`. Standardmäßig `auto`. |
| `--service-user` | Der Benutzer, unter dem ein Systemdienst läuft. |
| `--no-service` | Richtet alles ein, registriert aber keinen Autostart. |
| `--no-start` | Registriert den Dienst, startet ihn aber nicht. |
| `--skip-downloads` | Lädt rclone oder ffprobe nicht herunter. |
| `--skip-prerequisites` | Überspringt die FUSE-Prüfung für diese Plattform. |
| `--non-interactive` | Bricht ab, statt nach fehlenden Angaben zu fragen. |
| `--dry-run` | Zeigt den Plan an und ändert nichts. |

Jede Plattform hat ihre eigene Anleitung.

- [Linux](../setup/linux.md)
- [macOS](../setup/macos.md)
- [Windows](../setup/windows.md)
- [Docker](../setup/docker.md)

### zurg doctor

Prüft, was das Setup eingerichtet hat. Es liest die Konfiguration und sucht nach rclone und ffprobe. Danach prüft es den Dienst, den HTTP-Endpunkt und den Mount. Führ es zuerst aus, wenn etwas nicht funktioniert.

| Flag | Was es macht |
|---|---|
| `--working-dir` | Das Arbeitsverzeichnis der Instanz. Standard ist das aktuelle Verzeichnis. |
| `--service-name` | Der Name des Dienstes, der geprüft wird. Standard ist `zurg`. |
| `--service-scope` | `auto`, `user` oder `system`. Standard ist `auto`. |

### zurg service

Installiert und steuert den Autostart, ohne den Rest der Einrichtung auszuführen.

| Befehl | Was er macht |
|---|---|
| `zurg service install` | Installiert den Autostart und startet den Dienst. Mit `--start=false` wird nur installiert, ohne zu starten. |
| `zurg service uninstall` | Entfernt den Autostart. Die Konfiguration und die Daten bleiben erhalten. |
| `zurg service start` | Startet den installierten Dienst. |
| `zurg service stop` | Stoppt ihn. |
| `zurg service restart` | Startet ihn neu. |
| `zurg service status` | Zeigt den Status des Autostarts an. |

Alle diese Befehle akzeptieren dieselben Flags.

| Flag | Was er macht |
|---|---|
| `--name` | Der Name des Dienstes oder der geplanten Aufgabe. Standard ist `zurg`. |
| `--scope` | `auto`, `user` oder `system`. Standard ist `auto`. |
| `--user` | Der Benutzer, unter dem ein Systemdienst läuft. |
| `--working-dir` | Das Arbeitsverzeichnis, in dem der Dienst startet. |
| `--executable` | Die zurg-Binärdatei, die der Dienst ausführt. |

### zurg download-requirements

Lädt rclone und ffprobe in einen Ordner herunter und trägt ihre Pfade in die Konfiguration ein. Setup erledigt das für dich, außer du übergibst `--skip-downloads`.

| Flag | Was es macht |
|---|---|
| `--dir` | Wohin die Binaries kommen. Standardmäßig `bin`. |
| `--rclone-version` | Eine rclone-Version wie `1.67.0`. Standardmäßig `latest`. |
| `--ffprobe-version` | Eine ffprobe-Version. Standardmäßig `latest`. |

### zurg update

Ersetzt die Binärdatei durch das neueste Sponsor-Nightly. Das GitHub-Konto, das dafür verwendet wird, braucht Sponsor-Zugang über [gatekeeper](https://gatekeeper.debridmediamanager.com/). In einem Container verweigert es den Dienst, weil das nächste Neuerstellen die neue Binärdatei wieder verwerfen würde. Zieh stattdessen dort ein neues Image. `--force` aktualisiert trotzdem.

Es meldet sich über die GitHub CLI bei GitHub an. Das ist entweder die, die in deinem PATH liegt, oder die, die die Installer im `bin`-Ordner neben zurg ablegen. Eine Anmeldung, die die GitHub CLI ohne Keyring gespeichert hat, funktioniert auch dann, wenn die CLI selbst nicht mehr da ist. `GITHUB_TOKEN` funktioniert ebenfalls. Findet es keines davon, gibt es den Installer-Befehl aus, mit dem du die GitHub CLI wieder einrichtest.

### zurg version

Gibt den Build aus. `zurg --version` gibt dasselbe aus.

## Backups

### zurg backup

Schreibt eine `.zurgbackup`-Datei mit allem, was sonst niemand neu aufbauen kann. Dazu gehören die Config mit deinen Tokens und jede `data/*.zurgtorrent` mit ihren Tags und Konto-Verknüpfungen. Außerdem enthält sie den `__magic__`-Speicher unter `data/local/` und die Quell-NZBs unter `nzbs/`. Caches, Plex-Snapshots und Logs werden weggelassen, damit das Backup nur so groß wird wie das, was es schützt.

Die Instanz muss nicht laufen. Deshalb kannst du das Backup problemlos per Zeitplan ausführen. Die Datei ist ein gzip-tar mit deinen Tokens drin. Bewahre sie wie ein Passwort auf.

| Flag | Was es macht |
|---|---|
| `-o`, `--out` | Wohin geschrieben wird. Standard ist `zurg-<timestamp>.zurgbackup` im aktuellen Verzeichnis. |
| `--include-caches` | Packt zusätzlich abgeleitete Metadaten und Cache-Daten für einen warmen Neustart mit ein. Plex-Snapshots und Logs bleiben draußen. Das kann sehr groß werden. |

### zurg restore-backup

Entpackt ein `.zurgbackup` in das aktuelle Verzeichnis. Jede Datei landet wieder an ihrem ursprünglichen Pfad. Stoppe zuerst zurg. Die Wiederherstellung schreibt Dateien, die eine laufende Instanz ebenfalls schreibt.

```
zurg restore-backup my-backup.zurgbackup
```

Eine Config, die schon im Verzeichnis liegt, bleibt unangetastet. Die Datei enthält die Tokens, an denen die ganze Bibliothek hängt. Übergib `--force-config`, um sie zu überschreiben.

## Messen {#measuring}

### zurg benchmark-my-setup

Liest echte Daten so, wie es ein Player tun würde, und zeigt die Streuung statt einer einzelnen Zahl. Es läuft in drei Phasen. Zuerst jeder Account für sich allein. Das ist die Zahl, die du mit dem vergleichen solltest, was der Dienst verspricht. Dann alle Accounts gleichzeitig. Accounts, die einzeln jeweils 70 MiB/s schaffen, aber zusammen nur 25 MiB/s, teilen sich einen ausgelasteten Uplink. Zum Schluss liest es über den rclone-Mount. Der Unterschied zur ersten Phase ist das, was FUSE und das VFS kosten.

Die Samples werden an zufälligen Offsets gelesen. Jede darunterliegende Schicht cached, und würde man immer wieder denselben Offset lesen, würde man den Cache statt der Verbindung messen.

Es fügt nichts hinzu und löscht nichts. Es verbraucht aber deine Bandbreite. Jeder Account liest die Sample-Größe mal die Anzahl der Iterationen, und zwar zweimal. Die Mount-Phase kommt noch obendrauf.

| Flag | Was es macht |
|---|---|
| `-n`, `--iterations` | Samples pro Account und Phase. Standardmäßig 3. |
| `--sample-mb` | MiB, die pro Sample gelesen werden. Standardmäßig 128. Nimm 1024, um über den read-chunk ramp von rclone hinauszukommen und einen dauerhaften Wert für den Mount zu bekommen. |
| `--provider` | Testet nur diese Accounts anhand des Namens. Kann mehrfach angegeben werden. |
| `--skip-concurrent` | Überspringt die Phase mit allen Accounts. |
| `--skip-mount` | Überspringt die Mount-Phase. |
| `--json` | Gibt den Bericht als JSON aus. |

### zurg network-test

Misst, wie schnell dieser Host jeden Real-Debrid-Download-Server über IPv4 und über IPv6 erreicht. Die Ergebnisse landen in `logs/network-test.log` und in `data/`, wo der Server sie liest, um seine Hosts auszuwählen. Setze `PROXY` in der Umgebung, um über einen Proxy zu testen.

| Flag | Was es macht |
|---|---|
| `-t`, `--test-url` | Eine Datei-URL, deren Pfad von jedem Server statt von Real-Debrids eigener Speedtest-Datei abgerufen wird. |

## Plex

Diese drei arbeiten mit dem Plex-Server auf diesem Host. Konfiguriere zuerst Plex. Siehe [Plex-Integration](config.md#plex-integration).

### zurg plex-settings

Meldet die Plex-Einstellungen, die für einen Mount wichtig sind, und behebt, was die Policy erlaubt. Plex geht bei seinen Standardwerten von lokalen Festplatten aus. Eine davon löscht die Bibliothek, wenn ein Scan auf einen kurzen Aussetzer trifft. Andere sorgen dafür, dass Plex jede seiner Dateien dekodiert. [plex.md](../guides/plex.md#recommended-plex-settings) erklärt jede einzelne.

| Flag | Was es macht |
|---|---|
| `-p`, `--policy` | `off`, `warn`, `guard` oder `enforce` für diesen Lauf. Standardmäßig wird `plex_settings_policy` aus der Konfiguration verwendet. Wenn du eine strengere angibst, siehst du vorab eine Vorschau, bevor du sie übernimmst. |

### zurg plex-drift

Liest die Plex-Datenbank, ohne sie zu verändern, und prüft jede Datei, auf die sie verweist, unter dem Mount. Es meldet die Dateien, die nicht mehr da sind. Führe es vor einem Bibliotheks-Scan aus. Ein Scan, der auf diese Dateien stößt, löscht sie aus Plex. Wenn du die Anzahl vorher kennst, ist der Scan eine bewusste Entscheidung und kein Glücksspiel.

Du brauchst `plex_database_path`, und Plex muss auf demselben Host laufen.

### zurg plex-backups

Listet die Plex-Datenbank-Snapshots auf, die zurg speichert, neueste zuerst. Jede Zeile zeigt, wann der Snapshot erstellt wurde, seine Größe und wie viele Einträge jede Bibliothek zu diesem Zeitpunkt enthielt. Die Anzahlen stammen direkt aus den Snapshots selbst. Die Liste zeigt also, was jeder einzelne tatsächlich wiederherstellen kann. [Plex Library Maintenance](config.md#plex-library-maintenance-same-host-only) erklärt, wann zurg sie anlegt.

## Teilen {#sharing}

### zurg export-torrents

Schreibt portable `.zurgtorrent`-Dateien, die deine Releases beschreiben, ohne dass dein Konto darin steht. Es werden keine Zugangsdaten hineingeschrieben. Auch keine Torrent-IDs, kein Reparaturstatus und keine CDN-Links. Es wird kein Anbieter kontaktiert.

Es liest `data/*.zurgtorrent` oder eine alte Dump-Datei. Übergib eine Datei oder einen Ordner, um nur diese zu exportieren. Der Empfänger legt die Dateien in `torrents/<their-account>/` ab und setzt dieses Konto auf `library.source: local`. [portable-libraries.md](../guides/local-libraries.md) erklärt die Empfängerseite.

| Flag | Was es macht |
|---|---|
| `--provider` | Exportiert die Releases, die auf diesem konfigurierten Konto liegen. |
| `--output` | Wohin die portablen Dateien geschrieben werden. |
| `--replace` | Ersetzt einen bestehenden Export mit demselben Hash. |
| `--skip-invalid` | Überspringt und zählt Einträge, die sich beim Massenexport nicht lesen lassen. |

### zurg nzb-share

Erstellt eine Freigabe Ihrer NZBs, die Sie veröffentlichen können. Das Ergebnis ist ein Ordner mit einer `manifest.json` und einer `.nzb.gz` pro Release, benannt nach dem Inhaltshash. Jede NZB wird zuerst bereinigt. Kommentare, DOCTYPEs und Wasserzeichen-Metadaten werden entfernt. Ebenso die ursprünglichen Dateinamen. Poster und Datumsangaben fallen auch weg, und jede Datei bekommt dieselbe feste Newsgroup, weil manche Indexer alle drei bei jedem Download ändern. Account-Stempel, die ein Indexer in einem Subject, einem Titel oder einem Passwort versteckt, werden abgeschnitten. Was Sie veröffentlichen, nennt das Release und nie den Account, der es heruntergeladen hat. Echte Archivpasswörter bleiben erhalten, weil Empfänger sie brauchen, um das Release zu lesen.

Veröffentlichen Sie den Ordner auf einem beliebigen statischen Hosting. Ein Git-Repository funktioniert. Ebenso eine Pages-Seite oder `rclone serve`. Das Protokoll darüber, was entfernt wurde, bleibt auf Ihrem Rechner und wird hier ausgegeben. Es enthält genau die Kennungen, die die Bereinigung entfernen soll.

| Flag | Was es macht |
|---|---|
| `--from` | Der Watch-Ordner, der geteilt wird. Wird rekursiv durchsucht. Standardwert ist `nzbs`. |
| `--out` | Der Ausgabeordner. Standardwert ist `nzb-share-<timestamp>`. |
| `--title` | Ein Titel, der im Manifest gespeichert wird. |
| `--filter` | Teilt nur Quellpfade, die auf diesen regulären Ausdruck passen. |

Das Dashboard kann eine Freigabe ebenfalls bereitstellen. Siehe [Öffentliche NZB-Freigabe](config.md#public-nzb-sharing).

### zurg nzb-sync

Holt eine geteilte Bibliothek in deinen Watch-Ordner. Es folgt der `manifest.json` einer Freigabe, entweder über eine URL oder einen lokalen Pfad. Jede NZB wird vor dem Schreiben gegen den Hash im Manifest geprüft. Die Dateien selbst holen deine eigenen Usenet-Accounts.

```
zurg nzb-sync https://example.com/share/manifest.json
```

Es fügt nur hinzu. Einträge, die du schon hast, werden übersprungen, und eine Freigabe löscht nie etwas. Zwei Freigaben mit denselben Releases werden über den Content-Hash dedupliziert.

| Flag | Was es macht |
|---|---|
| `--into` | Der Watch-Ordner, in den geschrieben wird. Standard ist `nzbs`. |
| `--dry-run` | Zeigt an, was geschrieben würde, und schreibt nichts. |

## Ein Real-Debrid-Konto leeren {#clearing-a-real-debrid-account}

Diese beiden Befehle löschen alles einer Art aus einem Real-Debrid-Konto. Das lässt sich nicht rückgängig machen. Sie funktionieren nur bei Real-Debrid.

Beide fragen nach dem `auth`-Cookie einer angemeldeten Real-Debrid-Browsersitzung statt nach deinem API-Token. Sie geben eine Zeile JavaScript aus, mit der du ihn anzeigen lässt. Führe diese in der Browser-Konsole auf real-debrid.com aus und füge das Ergebnis ein.

| Befehl | Was er macht |
|---|---|
| `zurg clear-torrents` | Löscht jeden Torrent im Konto. |
| `zurg clear-downloads` | Löscht jeden Download im Konto. Das sind die entsperrten Links. |

## Shell-Vervollständigung {#shell-completion}

`zurg completion bash` gibt ein Completion-Skript für bash aus. Dasselbe funktioniert für `zsh`, `fish` und `powershell`. `zurg completion <shell> --help` zeigt dir, wohin du es speichern musst.
