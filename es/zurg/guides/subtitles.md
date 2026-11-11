# Subtítulos con Bazarr {#subtitles-with-bazarr}

Bazarr encuentra subtítulos para lo que Sonarr y Radarr importan y guarda cada uno junto a su video. Con zurg, el video está en `__magic__`, y el subtítulo también. Las bibliotecas de Plex y Jellyfin que apuntan a `__magic__` lo leen como cualquier subtítulo en disco, y rex también lo muestra, como **English (SRT External)** en el menú de subtítulos.

Esto requiere zurg y rex de la nightly del 2026-10-24 o posterior.

Todo lo que aparece abajo se probó el 2026-10-23 con Radarr `6.3.0.10514`, la imagen actual de `lscr.io/linuxserver/bazarr`, zurg y rex de ese día, y una cuenta de Real-Debrid.

## Antes de empezar {#before-you-start}

Radarr (o Sonarr) ya importa a través de zurg, con su carpeta raíz dentro de `__magic__`, por ejemplo `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` en macOS, `Z:\__magic__\movies` en Windows). Si todavía no lo hace, sigue primero [Sonarr y Radarr para torrents](sonarr-radarr-torrents.md) o [para Usenet](sonarr-radarr.md).

## 1. Ejecuta Bazarr {#1-run-bazarr}

En un host Linux, dale a Bazarr el mismo volumen que Radarr, para que los dos vean la película en la misma ruta y no haga falta ningún path mapping:

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./bazarr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6767:6767
    restart: unless-stopped
```

El bind es la carpeta **de encima** del montaje de zurg (`/mnt`, que contiene `/mnt/zurg`), no el montaje en sí. Un contenedor que monta directamente el montaje se queda con un montaje muerto en cuanto zurg se reinicia, y cada lectura responde `Socket not connected`. [El paso de Docker de la guía de torrents](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker) explica por qué. `PUID` y `PGID` necesitan el mismo cuidado que con Whisparr: [mira ahí](whisparr.md#2-run-whisparr).

En macOS y Windows este archivo de compose no sirve, por la razón que explica el [paso 8 de la guía de Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). Ejecuta Bazarr desde el código fuente (`python bazarr.py`) en la misma máquina que Radarr y zurg, con el mismo usuario que zurg, siguiendo las páginas de Bazarr para [macOS](https://wiki.bazarr.media/Getting-Started/Installation/MacOS/macos/) y [Windows](https://wiki.bazarr.media/Getting-Started/Installation/Windows/source/). En Windows, sáltate el instalador de Bazarr: configura Bazarr como servicio de Windows, y un servicio no ve la unidad `Z:` de zurg ([por qué](sonarr-radarr.md#before-you-start)). Inicia `bazarr.py` desde tu propia sesión iniciada. Así verá cada película en la ruta que informa Radarr, y no hará falta ningún path mapping. Solo se ha probado la imagen de Docker de arriba.

Abre `http://<your server>:6767`.

## 2. Conéctalo a Radarr y Sonarr {#2-connect-it-to-radarr-and-sonarr}

**Settings → Radarr**: actívalo e introduce la dirección y el puerto de Radarr, además de la API key (en **Settings → General** de Radarr). Desde dentro de un contenedor usa la IP de la LAN del host, no `localhost`. Pulsa **Test** y luego **Save**. Sonarr funciona igual en **Settings → Sonarr**.

## 3. Idiomas {#3-languages}

**Settings → Languages**: añade los idiomas que quieras, crea un perfil de idiomas con ellos y márcalo como perfil predeterminado para películas y para series. Bazarr entonces pide subtítulos para todo lo que Radarr y Sonarr ya tienen.

## 4. Proveedores {#4-providers}

**Settings → Providers**: añade los sitios de subtítulos que busca Bazarr. Algunos necesitan una cuenta y otros no. Dos cosas que nos encontramos al probar:

- **subf2m** necesita un User-Agent en sus ajustes de proveedor. Sin él, Bazarr lo pausa durante 12 horas en la primera búsqueda.
- Bazarr pausa un proveedor que falla durante un rato, y si todos los proveedores están pausados, una búsqueda no encuentra nada. **System → Providers** los lista y permite restablecerlos.

## 5. Subtítulos incrustados {#5-embedded-subtitles}

Muchos lanzamientos ya traen una pista en inglés dentro del archivo de video. Bazarr considera que el inglés ya está y no descarga nada. Si aun así quieres un archivo de subtítulos, desactiva **Use Embedded Subtitles** en **Settings → Subtitles**.

## 6. Revisa uno {#6-check-one}

Desde la página **Movies** de Bazarr puedes ver qué le falta a cada película. Busca una desde ahí y el subtítulo aparecerá junto al video (en Windows, busca en la misma carpeta, dentro de `Z:\__magic__\movies`, en el Explorador):

```bash
$ ls "/mnt/zurg/__magic__/movies/Night of the Living Dead (1968)/"
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.en.hi.srt
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.mkv
```

El subtítulo es un archivo real en el disco de zurg, en `data/local/__magic__/` (consulta [Sidecars](magic.md#sidecars-nfo-posters-subtitles)). El video se sigue transmitiendo desde tu cuenta.

## En rex {#in-rex}

zurg envía a rex cada subtítulo que esté junto a un video en `__magic__`, sin importar a dónde hayan movido ese video Radarr o Sonarr. zurg busca subtítulos nuevos, modificados y eliminados una vez por minuto, así que un subtítulo que guarda Bazarr aparece en rex en un minuto más o menos, y uno que borres desaparece igual de rápido. No hace falta configurar nada más que `rex_url` en la configuración de zurg, que [la guía de rex](../../rex/with-zurg.md) ya te hace poner.

El nombre del archivo indica qué es el subtítulo, igual que lo lee Plex:

| Si el nombre del archivo termina en | rex muestra |
|---|---|
| `.srt` | Unknown (SRT External) |
| `.en.srt` | English (SRT External) |
| `.en.forced.srt` | English Forced (SRT External) |
| `.en.hi.srt`, `.en.sdh.srt`, `.en.cc.srt` | English SDH (SRT External) |

Se leen los archivos `.srt`, `.ass`, `.ssa`, `.smi` y `.txt`. El idioma puede ser un código de dos o tres letras (`en`, `eng`, `de`, `ger`). El nombre que va antes debe ser el mismo nombre del video, tal como lo escribe Bazarr.

Solo llegan a rex los subtítulos de `__magic__`. Uno guardado junto a un archivo en otra carpeta de zurg, como `/mnt/zurg/movies`, no se envía.

rex también puede buscar subtítulos por su cuenta: **Search Subtitles** en cualquier app de Plex, sin necesidad de Bazarr. Mira [los subtítulos de rex](../../rex/with-zurg.md#subtitles).
