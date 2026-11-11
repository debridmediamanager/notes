# Einrichtung {#setup}

Der Binary-Installer ist der kürzeste Weg unter Linux, macOS und Windows. Docker bleibt auf einem Linux-Host verfügbar, wenn ein Container besser passt. Docker Desktop auf macOS und Windows führt Container in einer VM aus. Dadurch kann der Mount nicht in Finder oder Explorer erscheinen, und rex kann zurg nicht erreichen. Nimm dort deshalb das Binary.

## Ein-Zeilen-Installationsskripte {#one-line-convenience-installers}

Die Installer laden einen Sponsor-Nightly-Build herunter. Werde zuerst auf [gatekeeper](https://gatekeeper.debridmediamanager.com/) Sponsor. Dadurch bekommt dein GitHub-Konto Zugriff.

Für eine frische Sponsor-Installation wählst du den Befehl für dein System:

+++ Linux und macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```
+++ Docker unter Linux
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```
+++ Windows
In PowerShell:
```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```
+++

Das Bootstrap-Skript prüft die Voraussetzungen deines Systems, meldet sich bei GitHub an, um den Sponsor-Zugriff zu prüfen, lädt den passenden Build herunter und startet die Anbieter-Auswahl. Vorhandene Binaries und Konfigurationen bleiben erhalten. Jede Anleitung unten beschreibt auch den vollständigen manuellen Weg.

- [Linux](linux.md)
- [Docker](docker.md) (Linux-Systeme)
- [macOS](macos.md)
- [Windows](windows.md)

Sobald zurg installiert ist, erklärt dir [Anbieter](../providers/index.md), wie du es mit einem Konto verbindest.
Dort gibt es für jeden Dienst eine eigene Seite mit den Zugangsdaten, dem `config.yml`-Eintrag und den Unterschieden dieses Dienstes.
Diese Seiten sind für Docker geschrieben. Bei einer Binary-Installation sind der `config.yml`-Eintrag des Anbieters und die Schritte im Dashboard dieselben.
Statt `docker compose restart zurg` verwendest du `./zurg service restart` (unter Windows `.\zurg.exe service restart`).
Die Zeile `docker compose run --rm zurg setup` wird zu `./zurg setup` (unter Windows `.\zurg.exe setup`), mit denselben Flags wie im Container, nur ohne `--no-service --skip-downloads --mount-path /zurg_mnt/zurg`.
Ein `--…-file`-Flag verweist dann auf eine Datei auf deinem Rechner statt auf eine Datei unter `/config`.
