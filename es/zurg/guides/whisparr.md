# Whisparr

Whisparr es Radarr para películas y escenas para adultos. Usa zurg como su cliente de qBittorrent. Los envíos van a tu cuenta de debrid. Importar solo renombra una ruta dentro de `__magic__`; no se descarga ni se copia nada.

Todo lo que aparece a continuación se probó el 2026-10-23 con Whisparr `3.6.5.1886` (la imagen `ghcr.io/hotio/whisparr:v3`), Prowlarr, zurg compilado desde la rama `main` de ese día y una cuenta de Real-Debrid. Se envió una película de 17 GB, se importó y se reprodujo desde el montaje.

(Una traducción anterior fue rechazada: los fragmentos de código no coinciden. Mantén la estructura exactamente igual.)

## Antes de empezar {#before-you-start}

Configura primero zurg para Radarr, con [Sonarr y Radarr para torrents](sonarr-radarr-torrents.md): una cuenta que acepte torrents, `__magic__` activado y el endpoint de qBittorrent activado. Whisparr reutiliza todo esto.

## 1. La categoría de Whisparr en zurg {#1-whisparrs-category-in-zurg}

Whisparr envía sus descargas bajo la categoría `whisparr`. Su botón **Test** del paso 3 crea esa categoría en zurg, así que no hace falta añadir nada. Para listarla en `config.yml` de todos modos, añádela junto a las que ya están:

```yaml
qbittorrent:
  enabled: true
  categories: [tv-sonarr, radarr, whisparr]
```

## 2. Ejecuta Whisparr {#2-run-whisparr}

En un host Linux, dale a Whisparr el mismo volumen que a Radarr: la carpeta **por encima** del montaje de zurg, con `rslave` ([por qué](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)):

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

`PUID` y `PGID` son el usuario de Linux con el que se ejecuta Whisparr. La imagen Docker de zurg deja que cualquier usuario lea su montaje. Un zurg instalado como binario normal solo lo permite si se ejecuta como root o con `user_allow_other` activado ([Configuración de Linux](../setup/linux.md#1-install-fuse-3)). Si no, pon `PUID` y `PGID` con el usuario que ejecuta zurg (`id -u` e `id -g` lo muestran), o Whisparr verá el montaje vacío.

En macOS y Windows este archivo compose no aplica, por el motivo que explica el [paso 8 de la guía de Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). Instala Whisparr como una aplicación normal en esos sistemas, con los detalles que aparecen en [Antes de empezar](sonarr-radarr.md#before-you-start) de esa guía: el mismo usuario que zurg en macOS, y la aplicación de la bandeja y no el servicio de Windows en Windows. Solo se ha probado la imagen Docker de arriba.

Abre `http://<your server>:6969`.

## 3. Añade zurg como cliente de descarga {#3-add-zurg-as-the-download-client}

**Settings → Download Clients → + → qBittorrent**, rellénalo exactamente igual que para Radarr ([los campos](sonarr-radarr-torrents.md#what-to-put-in-each-field)), excepto **Category**, que es `whisparr`. Deja **Remove Completed** activado. **Test** y luego **Save**.

## 4. Añade la carpeta raíz {#4-add-the-root-folder}

Crea la carpeta en el montaje y luego agrégala en **Settings → Media Management → Root Folders**:

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

Va al lado de `__magic__/movies`, no dentro de esa carpeta. Whisparr guarda cada película bajo su estudio, como `__magic__/whisparr/movies/<Studio>/<Title (Year)>/`.

## 5. Indexadores {#5-indexers}

DMM no tiene una categoría para adultos en su indexador, así que Whisparr necesita otros indexadores. En Prowlarr, los indexadores públicos **Knaben** y **The Pirate Bay** funcionaron bien. **XXXClub** está detrás de Cloudflare, y Prowlarr no puede añadirlo sin un solucionador de Cloudflare.

Luego conecta Prowlarr con Whisparr en **Settings → Apps → + → Whisparr** de Prowlarr, con la dirección de Whisparr y la clave API (en **Settings → General** de Whisparr). Prowlarr añade sus indexadores a Whisparr por sí mismo.

zurg solo acepta las versiones que tu cuenta ya tiene (`cached_only`, activado por defecto). Cuando rechaza una, Whisparr toma su siguiente resultado.

## 6. Descarga uno {#6-grab-one}

Añade una película en Whisparr con **Start search for missing movie** marcado. Cuando funcione, el historial de Whisparr mostrará **Grabbed** y luego **Imported** en cuestión de segundos, y la película estará en el montaje:

```bash
$ ls "/mnt/zurg/__magic__/whisparr/movies/<Studio>/<Title (Year)>/"
<Title> 1080p.mkv
```

En macOS la ruta empieza por `/Volumes/Zurg`; en Windows busca `Z:\__magic__\whisparr\movies` en Explorer. No aparece nada en la carpeta `data/local` de zurg. El archivo se transmite desde tu cuenta.

## Viéndolo {#watching-it}

Apunta una biblioteca de Plex o Jellyfin a `/mnt/zurg/__magic__/whisparr` (`/Volumes/Zurg/__magic__/whisparr` en macOS, `Z:\__magic__\whisparr` en Windows) para tener estas películas en una biblioteca propia.

En rex aparecen en la biblioteca donde las ponen las carpetas de zurg, igual que cualquier otra versión, que en la mayoría de configuraciones es la biblioteca de películas.
