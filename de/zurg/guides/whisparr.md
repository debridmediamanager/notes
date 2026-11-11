# Whisparr

Whisparr ist Radarr für Erwachsenenfilme und -szenen. Es nutzt zurg als seinen qBittorrent-Client. Grabs gehen auf dein Debrid-Konto. Der Import benennt nur einen Pfad in `__magic__` um; es wird nichts heruntergeladen oder kopiert.

Alles unten wurde am 2026-10-23 getestet, mit Whisparr `3.6.5.1886` (das Image `ghcr.io/hotio/whisparr:v3`), Prowlarr, zurg aus dem `main`-Branch von diesem Tag und einem Real-Debrid-Konto. Ein 17 GB großer Film wurde gegrabbt, importiert und vom Mount abgespielt.

## Bevor du anfängst {#before-you-start}

Richte zuerst zurg für Radarr ein, mit [Sonarr & Radarr for torrents](sonarr-radarr-torrents.md): ein Konto, das Torrents annimmt, `__magic__` aktiviert und der qBittorrent-Endpunkt aktiviert. Whisparr nutzt alles davon mit.

## 1. Whisparr-Kategorie in zurg {#1-whisparrs-category-in-zurg}

Whisparr schickt seine Downloads unter der Kategorie `whisparr`. Der **Test**-Button in Schritt 3 legt diese Kategorie in zurg an, du musst also nichts hinzufügen. Wenn du sie trotzdem in `config.yml` auflisten willst, füge sie einfach neben den vorhandenen hinzu:

```yaml
qbittorrent:
  enabled: true
  categories: [tv-sonarr, radarr, whisparr]
```

## 2. Whisparr starten {#2-run-whisparr}

Auf einem Linux-Host gibst du Whisparr dasselbe Volume wie Radarr, den Ordner **oberhalb** von zurgs Mount, mit `rslave` ([warum](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)):

```yaml
services:
  whisparr:
    image: ghcr.io/hotio/whisparr:v3
    container_name: whisparr
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - ./whisparr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6969:6969
    restart: unless-stopped
```

`PUID` und `PGID` sind der Linux-Benutzer, unter dem Whisparr läuft. Das zurg-Docker-Image erlaubt jedem Benutzer, den Mount zu lesen. Ein als normales Binary installiertes zurg macht das nur, wenn es als root läuft oder `user_allow_other` aktiviert ist ([Linux-Einrichtung](../setup/linux.md#1-install-fuse-3)). Andernfalls setzt du `PUID` und `PGID` auf den Benutzer, unter dem zurg läuft (`id -u` und `id -g` zeigen ihn an). Sonst sieht Whisparr den Mount leer.

Unter macOS und Windows gilt diese Compose-Datei nicht, aus dem Grund, den [Schritt 8 des Usenet-Leitfadens](sonarr-radarr.md#8-if-your-arr-is-in-docker) nennt. Installiere Whisparr dort als normale App, mit den Stolperfallen, die unter [Bevor du anfängst](sonarr-radarr.md#before-you-start) in diesem Leitfaden stehen: auf macOS derselbe Benutzer wie zurg, unter Windows die Tray-App und nicht der Windows-Dienst. Getestet wurde nur das Docker-Image oben.

Öffne `http://<your server>:6969`.

## 3. zurg als Download-Client hinzufügen {#3-add-zurg-as-the-download-client}

**Settings → Download Clients → + → qBittorrent**, genauso ausfüllen wie bei Radarr ([die Felder](sonarr-radarr-torrents.md#what-to-put-in-each-field)), nur dass **Category** `whisparr` ist. Lass **Remove Completed** aktiviert. **Test** klicken, dann **Save**.

## 4. Root-Ordner hinzufügen {#4-add-the-root-folder}

Erstell den Ordner auf dem Mount und füge ihn dann unter **Settings → Media Management → Root Folders** hinzu:

+++ Linux

```bash
mkdir -p /mnt/zurg/__magic__/whisparr
```

+++ macOS

```bash
mkdir -p /Volumes/Zurg/__magic__/whisparr
```

+++ Windows

```powershell
New-Item -ItemType Directory -Force Z:\__magic__\whisparr
```

+++

Er liegt neben `__magic__/movies`, nicht darin. Whisparr legt jeden Film unter seinem Studio ab, als `__magic__/whisparr/movies/<Studio>/<Title (Year)>/`.

## 5. Indexer {#5-indexers}

Der Indexer von DMM hat keine Kategorie für Erwachseneninhalte, deshalb braucht Whisparr andere Indexer. In Prowlarr haben die öffentlichen Indexer **Knaben** und **The Pirate Bay** beide funktioniert. **XXXClub** liegt hinter Cloudflare, und Prowlarr kann ihn ohne einen Cloudflare-Solver nicht hinzufügen.

Verbinde danach Prowlarr mit Whisparr unter **Settings → Apps → + → Whisparr** in Prowlarr, mit der Adresse und dem API-Key von Whisparr (zu finden unter **Settings → General** in Whisparr). Prowlarr fügt seine Indexer selbst zu Whisparr hinzu.

zurg akzeptiert nur Releases, die dein Konto bereits gespeichert hat (`cached_only`, standardmäßig aktiviert). Lehnt zurg eines ab, nimmt Whisparr das nächste Ergebnis.

## 6. Eines holen {#6-grab-one}

Füge in Whisparr einen Film hinzu, bei dem **Start search for missing movie** angehakt ist. Wenn es klappt, zeigt die Historie von Whisparr innerhalb von Sekunden **Grabbed** und dann **Imported** an, und der Film liegt auf dem Mount:

```bash
$ ls "/mnt/zurg/__magic__/whisparr/movies/<Studio>/<Title (Year)>/"
<Title> 1080p.mkv
```

Auf macOS beginnt der Pfad mit `/Volumes/Zurg`. Unter Windows schaust du im Explorer unter `Z:\__magic__\whisparr\movies`. Im Ordner `data/local` von zurg landet nichts. Die Datei wird aus deinem Account gestreamt.

## Anschauen {#watching-it}

Richte eine Plex- oder Jellyfin-Bibliothek auf `/mnt/zurg/__magic__/whisparr` (`/Volumes/Zurg/__magic__/whisparr` unter macOS, `Z:\__magic__\whisparr` unter Windows), damit diese Filme in einer eigenen Bibliothek bleiben.

In rex landen sie in der Bibliothek, in die die Ordner von zurg sie einsortieren, genau wie jede andere Veröffentlichung. Bei den meisten Setups ist das die Filmbibliothek.
