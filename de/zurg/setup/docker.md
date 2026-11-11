# Docker-Einrichtung {#docker-setup}

Diese Anleitung betreibt zurg in Docker und stellt dessen FUSE-Mount auf einem Linux-Host bereit. Docker liefert zurg, rclone und
ffprobe mit. Der eingebaute `setup`-Befehl erstellt die Konfiguration. `doctor` prüft die Installation.

Dieser Ablauf wurde am 4. September 2026 mit Docker Engine 29.1.1 getestet. Verwende den neuesten datierten Nightly-Build, damit das Image die Anbieterauswahl unten enthält.

> **Sponsor-Image:** `ghcr.io/debridmediamanager/zurg` ist nur für Sponsoren. Werde Sponsor auf [gatekeeper](https://gatekeeper.debridmediamanager.com/). Dadurch bekommt dein GitHub-Konto Zugriff auf das Image.

> **Linux-Host erforderlich:** Der unten gezeigte Host-Mount hängt von der Mount-Propagation unter Linux ab. Docker Desktop führt Container unter macOS und Windows in einer VM aus. Dort kann dieser FUSE-Mount nicht in Finder oder Explorer weitergegeben werden, und rex kann einen zurg darin nicht erreichen, daher würde dort nichts abspielen. Nutze auf einem dieser Systeme stattdessen die Binary-Anleitung für [macOS](https://notes.debridmediamanager.com/de/zurg/setup/macos/) oder [Windows](https://notes.debridmediamanager.com/de/zurg/setup/windows/). Wenn du unter Linux rex auf einer anderen Maschine nutzt, setze für den zurg-Container `network_mode: host`, wie [rex mit zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex) zeigt.

## Einzeilige Option {#one-line-option}

Auf einem frischen Linux-Host kann das optionale Bootstrap-Skript, wenn du zustimmst, Docker installieren, die persistente FUSE-Mount-Propagation einrichten, sich bei der Sponsor-Registry anmelden, das Compose-Projekt schreiben, den Provider-Chooser starten und das Ergebnis prüfen:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Bestehende Compose-Dateien und Konfigurationen bleiben erhalten. Die folgenden Abschnitte zeigen jeden Schritt für alle, die lieber den manuellen Weg gehen.

## Was der Installer im Container macht {#what-the-installer-does-in-a-container}

Die Flags sind bewusst so gewählt:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

- `setup` fragt, welche Anbieter konfiguriert werden sollen, fragt nur deren Zugangsdaten ab und schreibt `config.yml` mit dem Modus `0600`.
- `--no-service` überlässt den Autostart der Docker-Richtlinie `restart: unless-stopped`, statt zu versuchen, systemd in Alpine zu installieren.
- `--skip-downloads` verwendet rclone und ffprobe, die bereits im Image installiert sind.
- `--mount-path` speichert das Unterverzeichnis, dessen FUSE-Mount wieder auf den Host durchgereicht wird.

Setup erneut auszuführen ist unbedenklich. Es prüft und aktualisiert die Installation, ersetzt aber keine bestehende `config.yml`.

## 1. Docker installieren und das Image freischalten {#1-install-docker-and-unlock-the-image}

Installiere Docker Engine mit dem Compose-Plugin auf dem Linux-Host. Prüfe beide Befehle, bevor du weitermachst:

```bash
docker version
docker compose version
```

Melde dich mit deinem GitHub-Benutzernamen bei der GitHub Container Registry an. Wenn du nach dem Passwort gefragt wirst, füge ein klassisches Personal Access Token mit den Scopes `read:packages` und `repo` ein. Das Image gehört zu einem privaten Repository, und ein Token nur mit `read:packages` kann sich zwar anmelden, aber das Pullen schlägt trotzdem fehl:

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

Setze `ZURG_TAG` auf das neueste datierte Sponsor-Release. Wenn du es in `.env` ablegst, hast du ein bekanntes Rollback-Ziel und Upgrades werden nachvollziehbar:

```bash
printf 'ZURG_TAG=YYYY.MM.DD.HHMM-nightly\n' > .env
```

Ersetze den Platzhalter durch den tatsächlichen Release-Tag, bevor du weitermachst.

## 2. FUSE-Mount-Propagation vorbereiten {#2-prepare-fuse-mount-propagation}

Der FUSE-Mount muss unterhalb eines gemeinsamen übergeordneten Mounts angelegt werden. Führe das einmal aus, bevor der erste Container startet:

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

Prüfe das Gerät und den Propagationsmodus:

```bash
test -c /dev/fuse
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

Der zweite Befehl sollte unter `PROPAGATION` den Wert `shared` anzeigen.

## 3. Das Compose-Projekt anlegen {#3-create-the-compose-project}

```bash
mkdir -p ~/zurg
cd ~/zurg
```

Erstelle `docker-compose.yml`:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:${ZURG_TAG}
    container_name: zurg
    restart: unless-stopped
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    ports:
      - 9999:9999
    volumes:
      - ./:/config
      - /zurg_mnt:/zurg_mnt:rshared
```

`privileged: true` ist nicht nötig. Das FUSE-Gerät, die `SYS_ADMIN`-Capability und das uneingeschränkte AppArmor-Profil sind der engere Satz, den der Mount tatsächlich braucht.

Binde `/zurg_mnt/zurg` nicht direkt. Der FUSE-Mount muss ein Kind des `rshared`-Binds sein, damit sein Mount-Event beim Host ankommt.

Container, die den Mount lesen, allen voran Sonarr und Radarr, folgen derselben Regel von der anderen Seite: Binde das übergeordnete Verzeichnis (`/zurg_mnt`) einmal mit `rslave` ein und greife auf jeden Ordner über diesen einen Bind zu. Wenn du `__magic__/__all__` und `__magic__/tv` als zwei Volumes in einen \*arr bindest, wird jeder Import zu einer Kopie der ganzen Datei. Siehe [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

(Eine frühere Übersetzung wurde abgelehnt: Die Code-Spans stimmten nicht überein. Behalte die Struktur genau bei.)

## 4. Das integrierte Setup ausführen {#4-run-the-built-in-setup}

Aus `~/zurg` ausführen:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

Wähle einen oder mehrere Anbieter in Prioritätsreihenfolge. Zum Beispiel gibst du `2,4` ein, für TorBox gefolgt von Usenet. Das Setup fragt nur nach den Zugangsdaten, erstellt `config.yml` in `~/zurg`, aktiviert rclone und legt `/zurg_mnt/zurg` an. Kein Zugangsdatensatz wird in der Compose-Datei oder im Shell-Verlauf gespeichert.

Für die Automatisierung wiederholst du `--provider` und übergibst die anbieterspezifischen Token-Datei- oder `--nntp-*`-Flags. Das Setup behält eine bestehende Konfiguration bei späteren Durchläufen bei.

Das Setup schreibt die Accounts nur beim Durchlauf, der `config.yml` erstellt. Um einen Anbieter zu einer Installation hinzuzufügen, die bereits eine Konfiguration hat, nutze **Add provider** im Dashboard oder bearbeite die Datei und starte danach neu. Jeder Dienst hat eine eigene Seite mit den Zugangsdaten, dem Konfigurationsblock und den wichtigen Grenzen: [Providers](../providers/index.md).

## 5. zurg starten {#5-start-zurg}

```bash
docker compose up -d
docker compose logs -f --tail=100 zurg
```

Verlasse die Log-Ansicht mit `Ctrl+C`; der Container läuft weiter. Das Dashboard erreichst du unter `http://localhost:9999/config/`, und es bearbeitet dieselbe `config.yml`, die neben der Compose-Datei liegt.

Eine große Bibliothek kann eine Weile zum Laden brauchen. Ordner im Mount lassen sich erst auflisten, wenn das Laden fertig ist. Bis dahin erscheinen sie leer oder als `Input/output error`, während das Dashboard und `version.txt` ganz normal funktionieren. Das heißt, zurg lädt noch und der Mount ist nicht kaputt. [Up versus ready](#up-versus-ready) zeigt dir, wie du erkennst, wann das Laden abgeschlossen ist.

## 6. Mit doctor überprüfen {#6-verify-with-doctor}

Sobald die Bibliothek bereit ist, führe dasselbe Diagnosetool aus, das auch bei einer Binärinstallation verwendet wird:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`doctor` prüft die Konfiguration und deren Berechtigungen, ffprobe, rclone, FUSE, den HTTP-Endpunkt und den Mount, den zurg meldet. `WARN service zurg is not installed` ist in Docker normal, weil Compose den Autostart übernimmt. Warnungen lassen den Befehl nicht fehlschlagen, jedes `FAIL` dagegen schon.

Prüfe, ob der propagierte Mount auch außerhalb des Containers sichtbar ist:

```bash
cat /zurg_mnt/zurg/version.txt
ls -la /zurg_mnt/zurg/
```

## 7. Den gemeinsamen Elternordner reboot-fest machen {#7-make-the-shared-parent-survive-reboots}

Der Self-Bind aus Schritt 2 übersteht keinen Neustart. Erstelle auf dem Host eine systemd-oneshot-Unit:

```bash
sudo tee /etc/systemd/system/rshared-zurg-mnt.service << 'EOF'
[Unit]
Description=Make /zurg_mnt rshared for Docker FUSE mounts
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "mount --bind /zurg_mnt /zurg_mnt && mount --make-rshared /zurg_mnt"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable rshared-zurg-mnt.service
```

Beim nächsten Neustart bereitet der Host das gemeinsame Elternverzeichnis vor, bevor Docker den zurg-Container wiederherstellt.

## Up versus ready

zurg beantwortet zwei verschiedene Fragen über HTTP. Keine davon braucht ein Passwort, auch wenn `username` gesetzt ist.

| Adresse | Antwortet mit 200, wenn | Während die Bibliothek lädt |
|---|---|---|
| `/http/version.txt` | zurg läuft | 200 |
| `/ready` | die Bibliothek fertig geladen ist | 503 mit `Retry-After: 5` |

Der Health-Check des Containers fragt die erste Adresse ab. `docker compose ps` zeigt `healthy`, sobald zurg läuft. Eine große Bibliothek kann danach noch lange weiterladen. Frag `/ready` ab, wenn du die komplette Bibliothek brauchst. Es gibt `ready` aus, sobald das Laden fertig ist.

```bash
curl -fsS http://localhost:9999/ready
docker compose exec zurg /app/healthcheck.sh --ready && echo ready
```

Ein Skript kann so darauf warten.

```bash
until curl -fsS http://localhost:9999/ready >/dev/null; do sleep 10; done
```

### Warum der Health Check nicht auf die Bibliothek wartet {#why-the-health-check-does-not-wait-for-the-library}

Docker speichert pro Container einen einzigen Health-Status. Die Tools, die ihn auslesen, gehen davon aus, dass er bedeutet „läuft zurg noch?“. autoheal und Docker Swarm starten ein Container neu, sobald er unhealthy wird. `depends_on` mit `condition: service_healthy` hält andere Dienste so lange zurück, bis zurg healthy ist.

Für große Bibliotheken wurden Kaltstarts von 15 bis 90 Minuten gemeldet. Ein Health-Check, der auf die Bibliothek wartet, würde jeden abhängigen Dienst so lange zurückhalten. Ein rclone-Container vor zurg würde seinen Mount-Ordner die ganze Zeit leer lassen. Ein leerer Ordner sieht für einen Medienserver aus wie eine gelöschte Bibliothek. Eine Ladezeit, die länger dauert als die Retries des Health-Checks, würde außerdem als unhealthy markiert. Alles, was unhealthy Container neu startet, würde dann das Laden von vorne beginnen. Es käme nie zum Ende.

### Readiness mit Compose verwenden {#using-readiness-with-compose}

Lass einen Mount-Container beim Standard-Health-Check, damit sein Mount hochkommt, sobald zurg läuft.

```yaml
services:
  rclone:
    depends_on:
      zurg:
        condition: service_healthy
```

Warte auf `/ready` in allem, was die ganze Bibliothek braucht. Das kann ein Scan-Skript oder ein Import-Job sein.

Du kannst den zurg-Container selbst nur dann als healthy melden lassen, wenn die Bibliothek geladen ist. Überschreibe seinen Health-Check in `docker-compose.yml` und setze `start_period` länger als dein langsamster Ladevorgang. Docker zählt Fehler innerhalb der start period nicht mit. Jeder Dienst, der von zurg abhängt, wartet dann ebenfalls auf die Bibliothek. Kombiniere das nicht mit autoheal.

```yaml
services:
  zurg:
    healthcheck:
      test: ["CMD", "/app/healthcheck.sh", "--ready"]
      interval: 30s
      timeout: 10s
      start_period: 3h
      retries: 3
```

## zurg verwalten und aktualisieren {#managing-and-updating-zurg}

Führe diese Befehle in `~/zurg` aus:

```bash
docker compose ps
docker compose logs -f --tail=100 zurg
docker compose restart zurg
docker compose stop zurg
docker compose start zurg
```

Das Compose-Projekt liest `ZURG_TAG` aus `.env`. Der Installer setzt den Wert auf `latest`, damit ein Pull immer die neueste Nightly holt. Zum Aktualisieren ziehst du das Image neu, erstellst den Container neu und führst danach doctor aus:

```bash
docker compose pull zurg
docker compose up -d zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`zurg update` ist hier nicht der richtige Weg, und innerhalb eines Containers läuft es ohnehin nicht. Das Binary, das es schreibt, liegt in der Container-Schicht und geht verloren, sobald der Container neu erstellt wird. Dann würde das nächste `up` stillschweigend wieder mit dem alten Build laufen. Zieh stattdessen das Image. `--force` überschreibt die Sperre für einen Container, den du behalten willst.

Um zurückzurollen, setzt du `ZURG_TAG` in `.env` auf einen bestimmten Nightly-Tag und führst die drei Befehle erneut aus. Die eingebundene Config, der Bibliotheksstatus, die Logs und der Cache bleiben beim Wechsel des Containers unverändert.

`docker compose down` entfernt den Container und das Netzwerk, lässt aber die eingebundenen Dateien in `~/zurg` und den übergeordneten Mountpunkt `/zurg_mnt` stehen.

## Was wo liegt {#what-lives-where}

Alles, was zurg schreibt, landet unter `/config`. Deshalb enthält der eine Bind `./:/config` die komplette Installation:

| Pfad | Was es ist |
|---|---|
| `config.yml` | Einstellungen und Zugangsdaten der Anbieter; Änderungen im Dashboard werden hier zurückgeschrieben |
| `data/` | Bibliotheksstatus, lokale Dateien, generierte Schlüssel und der rclone-VFS-Cache |
| `logs/` | zurg- und rclone-Logs |
| `dump/` | Torrent-Dumps, wenn aktiviert |
| `strm/` | `.strm`-Dateien, wenn `save_strm_files` aktiviert ist |
| `nzbs/` | Watch-Verzeichnis für das Usenet-Backend |

Ein Pull oder das Neuerstellen des Images ändert keine dieser Dateien.

`data/rclone-cache` ist der Ordner, der wächst. Der Mount lädt jede Datei, die er liest, komplett herunter und behält sie auch nach dem Ende der Wiedergabe, standardmäßig bis zu **256G**. Das Bind-Verzeichnis braucht also zusätzlich zu allem anderen Platz für den Cache. Das 72h-Alter-Limit begrenzt ihn in der Praxis nicht – alles, was auf die Bibliothek zugreift, zählt als Zugriff auf die Datei, auch der nächtliche Durchlauf eines Media-Servers.

```bash
du -sh ./data/rclone-cache
```

Begrenze ihn niedriger in `config.yml`, wenn die Festplatte des Hosts so viel nicht entbehren kann:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Wenn du den Host-Pfad hinter `/config` änderst, wird der Cache umbenannt und die alte Kopie bleibt zurück. zurg räumt solche verwaisten Verzeichnisse beim nächsten Start auf und loggt, wie viel Platz es freigegeben hat. Siehe [config.md](../reference/config.md#disk-the-mount-uses).

### Umgebungsvariablen für unbeaufsichtigte Installationen vorab setzen {#environment-seeding-for-unattended-installs}

Das Image unterstützt weiterhin den älteren Erststart-Weg. Wenn keine `config.yml` existiert, legen `TOKEN` oder `RD_TOKEN` den Account an und `MOUNT_PATH` aktiviert den Mount. Diese Variablen werden nur gelesen, solange die Datei erstellt wird. Die Datei gewinnt bei jedem späteren Start.

Real-Debrid ist der einzige Account, den der laufende Container auf diese Weise anlegt. `TORBOX_TOKEN`, `ALLDEBRID_TOKEN`, `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN`, `OFFCLOUD_TOKEN` und `NNTP_HOST` werden von `zurg setup` gelesen. Sie wirken also im oben genannten einmaligen Setup-Container und tun nichts, wenn sie im `environment:`-Block des Dienstes stehen.

Der interaktive Befehl `setup` ist für Leute am Terminal die bessere Wahl, weil das Token nie in der Compose-Datei landet. Die Umgebungsvariablen-Variante bleibt nützlich für Automatisierung, die bereits einen Secret-Store hat.

### Upgrade einer Installation, die `/app` gemountet hat {#upgrading-an-install-that-mounted-app}

Ältere Compose-Projekte haben `/app/config.yml`, `/app/data` und andere Pfade einzeln eingebunden. Das Entrypoint wählt weiterhin `/app`, sobald es dieses Layout findet. Ein neueres Image verwendet dann also weiterhin die alte Konfiguration und den alten Cache.

Um auf das Ein-Ordner-Layout umzustellen, stoppe den Container. Kopiere danach die vorhandene `config.yml`, den Ordner `data/` und die anderen Statusordner in ein Verzeichnis auf dem Host. Binde dieses Verzeichnis anschließend unter `/config` ein.

## Fehlerbehebung {#troubleshooting}

Fang mit der Diagnose und den aktuellen Logs an:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
docker compose logs --tail=200 zurg
```

### `unknown command "setup"` oder `unknown command "doctor"` {#unknown-command-setup-or-unknown-command-doctor}

Der Container ist älter als der eingebaute Installer. Nutze `2026.09.04.1449-nightly` oder ein neueres datiertes zurg-Image und erstelle ihn dann neu:

```bash
docker compose pull zurg
docker compose up -d zurg
```

### `Transport endpoint is not connected`

Das alte FUSE-Mount ist veraltet:

```bash
sudo umount -l /zurg_mnt/zurg
docker compose restart zurg
```

### FUSE-Gerät ist nicht verfügbar {#fuse-device-is-unavailable}

Lade das Modul jetzt und auch bei späteren Starts:

```bash
sudo modprobe fuse
echo fuse | sudo tee /etc/modules-load.d/fuse.conf
```

Prüfe danach, ob der Compose-Service noch `/dev/fuse`, `SYS_ADMIN` und die AppArmor-Einstellung enthält.

### Mount ist leer {#mount-is-empty}

Prüfe jede Ebene der Reihe nach:

```bash
docker compose logs zurg 2>&1 | grep -i rclone
docker compose exec zurg ls -la /zurg_mnt/zurg
curl -fsS http://localhost:9999/http/version.txt
curl -fsS http://localhost:9999/ready
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

Der Host-Pfad muss ein geteilter Bind-Mount sein, und das Compose-Volume muss das übergeordnete Verzeichnis als `/zurg_mnt:/zurg_mnt:rshared` einbinden.

Wenn `/ready` mit Fehler 503 fehlschlägt, lädt die Bibliothek noch und der Mount ist in Ordnung. Die Ordner werden so lange leer angezeigt oder zeigen `Input/output error`, bis das Laden fertig ist. Warte einfach darauf, statt zurg neu zu starten. Ein Neustart fängt das Laden von vorne an.

### Mount erscheint zweimal in der `mount`-Ausgabe {#mount-appears-twice-in-mount-output}

Das ist normal. Das gleiche FUSE-Mount ist im Container und im Host-Mount-Namespace sichtbar, weil die Propagation funktioniert.

Immer noch hängen geblieben? Frag im **zurg-support**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) sagt dir, was du angeben solltest.
