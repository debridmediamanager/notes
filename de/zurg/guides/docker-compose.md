# Eine Docker-Compose-Datei für zurg, Plex und rex {#one-docker-compose-file-for-zurg-plex-and-rex}

Auf einem Linux-Rechner kann eine einzige `docker-compose.yml` zurg, Plex Media Server und rex nebeneinander betreiben. zurg zeigt deine Bibliothek als Ordner unter `/zurg_mnt/zurg` an, Plex Media Server liest diese Ordner, und rex holt sich dieselbe Bibliothek direkt von zurg, ganz ohne Ordner. Führe zuerst einmal den Docker-Installer von zurg aus und ersetze dann dessen `docker-compose.yml` durch die unten stehende.

Du willst nur Plex Media Server oder nur rex, nicht beides? Lass den anderen einfach aus der Datei weg. Ohne Plex löschst du außerdem die Zeile `command:` von rex.

Docker Desktop unter Windows oder auf einem Mac kann das nicht ausführen: Die Ordner von zurg erscheinen dort nie im Explorer oder Finder, und rex kann ein zurg darin nicht erreichen. Nutze dort stattdessen [zurg unter Windows](../setup/windows.md) oder [zurg unter macOS](../setup/macos.md).

## Bevor du anfängst {#before-you-start}

- **Eine Linux-Maschine**, die dauerhaft läuft. Der Installer fügt Docker hinzu, falls es fehlt.
- **Eine zurg-Sponsorschaft.** Das zurg-Image ist privat. Werde auf [gatekeeper](https://gatekeeper.debridmediamanager.com/) Sponsor, dann bekommt dein GitHub-Konto Zugriff.
- **Dein Real-Debrid-API-Token** oder die Zugangsdaten für einen anderen Dienst, den zurg unterstützt: [Your Real-Debrid API token](../../guides/real-debrid-api-token.md).
- **Für Plex Media Server** dein Plex-Konto. **Für rex** ein neues Plex-Konto, das nur dafür angelegt wird: [rex with zurg](../../rex/with-zurg.md#before-you-start) erklärt, warum.

## 1. Starte zurgs Docker-Installer {#1-run-zurgs-docker-installer}

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Es installiert Docker, falls es fehlt (vorher wird nachgefragt), macht `/zurg_mnt` bereit für zurgs Ordner, jetzt und nach jedem Neustart, meldet dich bei GitHub für das zurg-Image an, schreibt `~/zurg/docker-compose.yml`, fragt nach deinen Diensten und deinem Token, startet zurg und führt `zurg doctor` aus. [zurgs Docker-Einrichtung](../setup/docker.md) macht dasselbe von Hand.

**Was du sehen solltest.**

```bash
ls /zurg_mnt/zurg
```

zeigt `__all__`, `__downloads__`, `__unplayable__`, `movies`, `shows` und `version.txt` an.

## 2. Ersetze alles durch die vollständige Datei {#2-swap-in-the-full-file}

```bash
cd ~/zurg
nano docker-compose.yml
```

Ersetze alles darin durch Folgendes:

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

  plex:
    image: plexinc/pms-docker
    container_name: plex
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM=
    volumes:
      - ../plex/config:/config
      - ../plex/transcode:/transcode
      - /zurg_mnt:/zurg_mnt:rslave
    depends_on:
      zurg:
        condition: service_healthy

  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    command: --port 32500
    volumes:
      - ../rex/config:/config
```

- **zurg** ist der eigene Dienst des Installers, unverändert.
- **plex** sieht die Ordner von zurg unter demselben Pfad wie zurg, `/zurg_mnt/zurg`. So landet ein Scan, den zurg anfordert, in einem Ordner, den Plex kennt. `rslave` hält die Ordner dort, wenn zurg neu startet. Trage deine eigene Zeitzone in `TZ` ein.
- **PLEX_CLAIM** meldet Plex Media Server beim ersten Start mit deinem Konto an. Melde dich bei Plex an, öffne [plex.tv/claim](https://www.plex.tv/claim), kopiere den Code und füge ihn direkt nach dem `=` ein. Er läuft nach wenigen Minuten ab, also starte den Stack gleich.
- **rex** ist der Dienst aus [rex mit zurg](../../rex/with-zurg.md#d2-start-rex-in-docker), auf Port 32500, weil Plex Media Server den Port 32400 belegt. Seine Dateien landen in `~/rex/config`, dort sucht rex mit zurg sie.

Speichere die Datei und starte alles:

```bash
docker compose up -d
docker compose ps
```

Wenn `docker` mit permission denied fehlschlägt, schreibe vor jeden `docker`-Befehl auf dieser Seite `sudo`.

**Was du sehen solltest.** Drei Container: `plex` und `zurg` zeigen `(healthy)`, `rex` zeigt `Up`. Die eigenen Dateien von Plex Media Server landen in `~/plex`.

## 3. Füge zurgs Ordner in Plex hinzu {#3-add-zurgs-folders-in-plex}

Öffne Plex Web unter `http://<this machine's LAN IP>:32400/web`. Füge eine **Movies**-Bibliothek mit dem Ordner `/zurg_mnt/zurg/movies` und eine **TV Shows**-Bibliothek mit `/zurg_mnt/zurg/shows` hinzu, so wie [Real-Debrid in Plex](../../guides/real-debrid-plex.md#3-add-the-folders-in-plex) es zeigt.

Damit Plex von neuen Inhalten erfährt, öffne das zurg-Dashboard unter `http://<this machine's LAN IP>:9999/config/` und drücke unter **Media Server Integration** auf **Login with Plex** ([Schritt 4 dort](../../guides/real-debrid-plex.md#4-let-zurg-tell-plex-about-new-things)).

## 4. Richte rex ein {#4-set-up-rex}

Folge [rex mit zurg](../../rex/with-zurg.md) von [D3](../../rex/with-zurg.md#d3-add-it-to-a-plex-account) bis [D5](../../rex/with-zurg.md#d5-watch), aber überall wo `32400` steht, nimmst du `32500`. Zum Beispiel lautet die zurg-Zeile `rex_url: http://192.168.1.20:32500`, mit der LAN-IP von rex. Deine Plex-Apps zeigen danach beide Server an: [Schritt 2 von rex mit zurg](../../rex/with-zurg.md#step-2-install-rex) erklärt, wie du sie auseinanderhältst.

## Aktualisieren {#updating}

```bash
cd ~/zurg
docker compose pull
docker compose up -d
```

Das aktualisiert zurg, Plex und rex gemeinsam. Wenn rex zusammen mit zurg `docker compose` in `~/rex` ausführt, führe es hier in `~/zurg` aus und hänge `rex` am Ende an, damit nur rex betroffen ist: `docker compose stop rex` statt `docker compose down`, `docker compose up -d rex` statt `docker compose up -d`.

## Wenn etwas nicht stimmt {#when-something-is-wrong}

`docker compose logs --tail=100 zurg` (oder `plex`, `rex`) zeigt, was ein Container zuletzt ausgegeben hat.

| Was du siehst | Was zu tun ist |
|---|---|
| Der Installer zeigt `Host-visible Docker mounts require a Linux host. Use the binary installer on macOS or Windows.` | Du nutzt einen Mac oder Windows. Installiere zurg stattdessen mit dem [Windows](../setup/windows.md)- oder [macOS](../setup/macos.md)-Installer. |
| `Error response from daemon: error from registry: unauthorized` beim Herunterladen von zurg durch Docker | Dieser Rechner ist nicht bei GitHubs Registry mit einem Konto angemeldet, das Zugriff auf zurg hat. Werde Sponsor auf [gatekeeper](https://gatekeeper.debridmediamanager.com/) und führe dann den Installer erneut aus. Zum manuellen Anmelden siehe [zurgs Docker-Setup](../setup/docker.md#1-install-docker-and-unlock-the-image): der Token braucht sowohl `read:packages` als auch `repo`. |
| `path /zurg_mnt is mounted on ... but it is not a shared mount` | `/zurg_mnt` ist noch nicht geteilt. Führe `sudo mount --bind /zurg_mnt /zurg_mnt` und `sudo mount --make-rshared /zurg_mnt` aus und danach `docker compose up -d`. Der Installer sorgt dafür, dass das nach Neustarts bleibt. Manuell siehe [Schritt 7 von zurgs Docker-Setup](../setup/docker.md#7-make-the-shared-parent-survive-reboots). |
| `zurg` startet ständig neu, und das Log endet mit `Error: config ./config.yml is not valid YAML: yaml: unmarshal errors:` und `mapping key "..." already defined` | Diese Einstellung steht zweimal in zurgs Konfiguration. Führe `sudo nano ~/zurg/config.yml` aus, lösche eine der beiden Zeilen, die der Fehler nennt, speichere und führe `docker compose restart zurg` aus. |
| zurgs Log zeigt `Mount verification failed: mount verification timeout: /zurg_mnt/zurg/version.txt not accessible after 60 attempts -- you appear to be running inside Docker, mount a parent directory with rshared propagation` | zurgs Ordner sind nicht hochgekommen. Prüfe, ob die Volume-Zeile von zurg `/zurg_mnt:/zurg_mnt:rshared` lautet, also das übergeordnete Verzeichnis und nicht `/zurg_mnt/zurg`, und ob `/zurg_mnt` geteilt ist (die Zeile oben). [Mount is empty](../setup/docker.md#mount-is-empty) enthält weitere Prüfungen. |
| Plex-Bibliotheken sind leer, nachdem zurg neu gestartet wurde, und `docker exec plex ls /zurg_mnt/zurg` sagt `cannot access '/zurg_mnt/zurg': Transport endpoint is not connected` | In Plex' Volume-Zeile fehlt `rslave`. Sie muss `/zurg_mnt:/zurg_mnt:rslave` lauten. Korrigiere sie und führe `docker compose up -d` aus. |
| rex stoppt mit `rex: cannot bind 0.0.0.0:32400: Address already in use (os error 98) (another rex or Plex on this port? --port picks another)` | Plex Media Server belegt bereits Port 32400. Behalte `command: --port 32500` bei rex. |
| `/zurg_mnt/zurg/movies` ist leer oder zeigt `Input/output error` direkt nach einem Start | zurg liest dein Konto noch ein. `curl http://localhost:9999/ready` gibt `ready` aus, wenn es fertig ist. Starte zurg in der Zwischenzeit nicht neu, sonst fängt das Einlesen wieder von vorne an. |
| Titel erscheinen in rex, aber nichts lässt sich abspielen | Die Zeile `upstream failed` im Abschnitt „When something is wrong“ von [rex mit zurg](../../rex/with-zurg.md#when-something-is-wrong) prüft, ob rex zurg erreichen kann. |
| Die Festplatte läuft voll | zurg speichert eine Kopie von allem, was abgespielt wurde, in `~/zurg/data/rclone-cache`, standardmäßig bis zu 256G. [What lives where](../setup/docker.md#what-lives-where) zeigt, wie du das begrenzt. |

Immer noch hängen geblieben? Frag im Forum **zurg-support** auf [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) sagt, was du angeben solltest.

## Fragen {#questions}

### Kannst du meine Docker-Compose-Datei prüfen? {#can-you-check-my-docker-compose-file}

Vergleiche es mit dem oben stehenden. Am wichtigsten ist: zurg bindet `/zurg_mnt` mit `rshared`, Plex bindet dasselbe `/zurg_mnt` mit `rslave`, und rex verwendet das Image `ghcr.io/debridmediamanager/rex` mit `network_mode: host`. Ein Dienst namens `rex`, der `plexinc/pms-docker` ausführt, ist nur ein zweiter Plex Media Server, nicht rex.

(Eine frühere Übersetzung wurde abgelehnt: Code-Spans unterscheiden sich (`plexinc/pms-docker`). Behalte die Struktur exakt bei.)

### Brauche ich einen separaten rclone-Container? {#do-i-need-a-separate-rclone-container}

Nein. zurg startet rclone in seinem eigenen Container und stellt deine Bibliothek selbst unter `/zurg_mnt/zurg` bereit.

### Kann ich Plex Media Server und rex zusammen nutzen? {#can-i-use-plex-media-server-and-rex-together}

Ja, genau das macht diese Datei. Plex Media Server spielt aus den Ordnern von zurg ab, und rex spielt direkt von zurg. Deine Plex-Apps zeigen dann beide an. Behalte nur die, die du nutzt, wenn du nicht beide haben willst.

### Funktioniert das auf einem NAS? {#does-this-work-on-a-nas}

Es wurde auf einem Linux-PC getestet, nicht auf einem NAS. Der Installer braucht ein Terminal (SSH) mit `sudo` und FUSE (`/dev/fuse`). Wenn Schritt 1 damit endet, dass die Ordner von zurg in `/zurg_mnt/zurg` liegen, machen Sie mit Schritt 2 weiter.

### Mit welchen Versionen wurde das getestet? {#which-versions-was-this-tested-with}

zurg `2026.11.14.1134-nightly`, rex `2026.11.14.1123-nightly` und Plex Media Server `1.43.5.11079`, am 14. November 2026.
