# Usenet con zurg {#usenet-with-zurg}

El backend `nzb` de zurg convierte archivos `.nzb` en una biblioteca montada. No hay descargador ni carpeta de descargas completadas.

No se descarga nada antes de reproducir. Guarda los NZB, las cachés con límite de tamaño en `data/bytecache` y `data/par2`, además de los registros del índice. `nzb_article_disk_cache_mb` tiene 512 MiB por defecto. Al hacer un salto (seek), zurg solo descarga los artículos que cubren esos bytes. Un remux de 60 GB no necesita 60 GB de disco.

Usenet usa los mismos filtros de biblioteca, montaje e integración con servidores multimedia que los backends de debrid. Las publicaciones de Usenet pueden convivir con contenido de Real-Debrid o TorBox. También puedes usar solo Usenet.

**Se admiten varios proveedores de Usenet.** Una entrada `nzb` puede incluir cualquier número de cuentas de noticias: proveedores ilimitados, cuentas de bloque, las que tengas. zurg va probándolas una por una, artículo por artículo. Aquí esto importa más que la redundancia habitual: la retención es por proveedor, así que una segunda cuenta suele marcar la diferencia entre una descarga extra y reconstruir toda una publicación con PAR2. Consulta [Más de un proveedor de Usenet](#more-than-one-usenet-provider).

Esta guía cubre las cuentas de noticias, los NZB, el montaje y Plex.

| | |
|---|---|
| Referencia de configuración | [config.md → Usenet accounts](../reference/config.md#usenet-accounts) |
| Panel | `http://localhost:9999/config/` → Essentials → Providers |
| Dónde está el código | `internal/nzb` (backend), `internal/nntp` (cliente de noticias), `internal/par2` (cálculos de reparación) |
| Directorio de vigilancia | `nzbs/`, en el directorio de trabajo de zurg (`/config` en Docker) |
| Caché de reparación | `data/par2/` |
| Nombres de archivo resueltos | `data/nzb-names/`, así una publicación ofuscada se lee para obtener sus nombres una sola vez y no una vez por reinicio |
| Índice de artículos | `data/nzb-index/`, con `nzb_segments: mmap`, el valor por defecto en Linux, macOS y BSD |

---

## Lo que necesitas {#what-you-need}

- **Al menos una cuenta de proveedor de Usenet.** La retención es lo más importante: un proveedor de 4000+ días seguirá teniendo publicaciones que uno de 1000 días ya ha eliminado. Tu *límite de conexiones* del plan es el segundo dato que conviene conocer; es el que lee zurg.
- **Más cuentas, si tienes.** Un segundo proveedor ilimitado en un backbone distinto, o una cuenta barata de bloques para los huecos, es lo que más valor aporta a una configuración de Usenet; consulta [Más de un proveedor de Usenet](#more-than-one-usenet-provider).
- **Archivos NZB o algo que los descargue.** Descárgalos desde tu indexador y colócalos en `nzbs/`. O activa el [endpoint compatible con SABnzbd](sonarr-radarr.md) y deja que Sonarr y Radarr te los entreguen. Escribe en el mismo directorio. zurg también puede buscar por sí mismo en tus indexadores Newznab. Lo hace cuando pulsas reproducir en [Stremio](stremio.md). También lo hace con las peticiones de tu lista de seguimiento y de Seerr y los \*arrs a través de [adquisición](acquisition.md). Los torrents de una cuenta de debrid tienen un endpoint propio que habla [qBittorrent](sonarr-radarr-torrents.md).
- **zurg**, más `rclone` si quieres un montaje de sistema de archivos en lugar de WebDAV directamente. zurg descarga rclone por ti en la primera ejecución.

---

## 1. Configura tus cuentas de noticias {#1-configure-your-news-accounts}

Cada cuenta en zurg es una entrada bajo `providers:`. Una cuenta de Usenet se autentica con credenciales del servidor en lugar de un token de API, así que lleva un bloque `nntp` en vez de `token`:

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 30        # your plan's allowance — see below
      cache_size_mb: 512     # decoded articles held in memory, across all files
```

Eso es todo. Añade cuentas de debrid junto a ella si las tienes:

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: nzb
    nntp:
      host: news.example.com
      ...
```

| Clave | Por defecto | Notas |
|---|---|---|
| `host` | *(obligatorio)* | El servidor de noticias. Si falta o está vacío, zurg da error al arrancar. |
| `port` | `563` con TLS, `119` sin TLS | |
| `tls` | `false` | Actívalo. Un NNTP sin cifrar envía tu contraseña en texto plano y tus lecturas a cualquiera que esté en el camino. |
| `username` / `password` | `""` | |
| `connections` | `8` | **Ponlo al límite real de tu plan.** No es un límite de velocidad con el que haya que ser cortés: una sola conexión aporta una fracción del rendimiento del proveedor, así que zurg lee según este número. Si es muy bajo, el streaming va lento; si supera el límite del plan, el servidor empieza a rechazar conexiones. |
| `warm_connections` | `4` | Conexiones autenticadas e inactivas que se mantienen abiertas para que una lectura nunca espere a establecer una conexión nueva. Establecer una cuesta unos 0,8 s entre TCP, TLS, el saludo y `AUTHINFO`, y sin un mínimo se pagaba en la ruta de demanda después de cada arranque y cada periodo de inactividad. Salen de `connections` en vez de ser adicionales: el plan las cuenta como conexiones abiertas, y zurg las mantiene vivas con un `DATE` periódico, así que el mínimo está limitado por el límite permitido. `-1` no mantiene ninguna, que es lo que quiere un plan que se cobra por tiempo de conexión. El `warm_connections` de nivel superior define el valor por defecto para una cuenta que no indica ninguno; consulta [conexiones en espera](../reference/config.md#warm-connections). |
| `cache_size_mb` | `512` | Datos de artículos decodificados que se guardan en memoria, compartidos entre todos los archivos que se leen y no por archivo. |
| `servers` | `[]` | Cuentas de noticias adicionales; consulta [Más de un proveedor de Usenet](#more-than-one-usenet-provider). |

Dos reglas que el validador de configuración aplica:

- **Solo una entrada de proveedor `nzb` habilitada.** Dos escanearían el mismo directorio `nzbs/` y duplicarían cada versión. Esto no limita cuántos *proveedores de Usenet* puedes usar: las cuentas de noticias extra van bajo `nntp.servers` de esa única entrada, donde sirven la misma biblioteca en lugar de una segunda copia.
- **`watchlist: true` no puede apuntar a ella.** El backend de Usenet no puede añadir contenido, así que nunca puede ser la cuenta donde aterriza una adición a la lista de seguimiento de Plex.

### Más de un proveedor de Usenet {#more-than-one-usenet-provider}

La retención es por proveedor, y la diferencia entre una descarga extra y una reconstrucción PAR2 de toda la release es que otra cuenta todavía tenga el artículo. Por eso aquí una segunda cuenta vale más de lo que normalmente vale la redundancia.

Las claves que ya están en el bloque `nntp` describen la primera cuenta. Todo lo que esté bajo `servers` es otra cuenta. Las cuentas con el mismo `priority` se reparten la carga; un número más alto solo se consulta después de los más bajos, y una cuenta `backup` solo cuando todas las primarias hayan fallado en entregarlo. Una configuración existente con una sola cuenta sigue funcionando sin cambios:

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # first account: the workhorse
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com   # different backbone = different retention
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com              # metered — only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

Cada cuenta mantiene su propio límite de conexiones, y las lecturas se dimensionan según el **límite combinado de las cuentas que no son backup y que comparten la `priority` activa más baja** — 30 + 20 = 50 en el ejemplo anterior, donde ambas tienen la prioridad por defecto. Un segundo proveedor sin límite con la misma prioridad te da velocidad además de seguro de retención; una cuenta `backup` no aporta ninguna de las dos cosas, por diseño, ya que solo transporta lo que las primarias no pudieron suministrar, y contarla ampliaría cada ventana de lectura anticipada para una capacidad que la reproducción en régimen nunca usa.

Tres claves determinan a quién se consulta:

| Clave | Por defecto | Efecto |
|---|---|---|
| `name` | valor de `host` | Etiqueta la cuenta en los logs. |
| `priority` | `0` | Quién se consulta primero, de menor a mayor. Las cuentas con la misma prioridad se consultan en el orden en que están escritas, salvo que una con una conexión libre se prefiere a otra cuyo límite está agotado, así dos cuentas iguales reparten la carga en lugar de hacer cola en una. |
| `backup` | `false` | Marca una cuenta de bloques con cobro por volumen, que solo se consulta cuando todas las primarias han dicho que les falta el artículo, han enviado una copia dañada, han fallado a mitad de camino o no se pueden alcanzar. Que una primaria esté simplemente **ocupada** no basta: zurg espera a que se libere en lugar de gastar bytes medidos en algo que una cuenta sin límite podría haber servido. |
| `backbone` | `""` | Indica el spool de artículos al que resuelve una cuenta. Dos cuentas en el mismo backbone tienen los mismos artículos, así que, cuando una ya ha dicho que no tiene un artículo, las otras del mismo spool se omiten en lugar de pagar un viaje de ida y vuelta por la misma respuesta. |

Cada cuenta también mantiene su propio mínimo de conexiones calientes, sacado de su propio límite: un hueco de retención lleva una lectura directamente más allá de la primaria, así que la cuenta a la que se llega por primera vez es justo aquella cuya conexión nadie ha abierto todavía, y por tanto nadie ha pagado. Una cuenta de bloques de dos conexiones puede configurarse para no mantener ninguna con `warm_connections: -1`.

La reventa está muy extendida, así que merece la pena rellenar `backbone`: dos cuentas que compraste a empresas distintas pueden estar en el mismo spool, y sin esto cada fallo se pregunta dos veces. Agrúpalas con el nombre que quieras; la cadena solo se compara con otras entradas.

Al arrancar, zurg nombra cada cuenta que va a usar:

```
Usenet account nzb connected: nntps://unlimited.example.com:563 (30 connections) + nntps://second-unlimited.example.com:563 (20 connections) [usenetexpress] + nntps://block.example.com:563 (10 connections) [backup] [omicron]
```

El censo que decide si una release necesita reparación pregunta a cada cuenta antes de dar un artículo por desaparecido, y a cada una solo le pregunta por lo que sus predecesoras no tenían. Un fallo de transporte nunca se confunde con un artículo caducado: si una cuenta agotó el tiempo o soltó el artículo a mitad de descarga, ese fallo es lo que se reporta, así que un timeout nunca hace que se sirva silencio ni que se programe una reparación de algo que nunca se perdió. Una cuenta a la que no se pudo llegar en absoluto no cuenta: si otra cuenta dice que el artículo ya no está, se trata como desaparecido.

### Configurar proveedores en el Dashboard {#configuring-providers-in-the-dashboard}

`http://localhost:9999/config/` → **Essentials** → **Providers** hace lo mismo sin editar el YAML. La tabla muestra todas las cuentas en el orden del config:

```
#  Name        Type        Token                Flags
1  realdebrid  realdebrid  …DFFND4OA            —          [Edit] [Delete]
2  nzb         nzb         news.example.com     —          [Edit] [Delete]
```

En una fila `nzb`, la columna Token muestra el **host del news server** en lugar de una pista del token, porque no hay token que ocultar. Después aparece cuántos news servers adicionales tiene.

**Para añadir una cuenta de Usenet:**

1. Haz clic en **Add provider**.
2. Pon **Type** en `nzb`. Los campos de token desaparecen y en su lugar aparecen los campos NNTP.
3. Deja **Name** vacío a menos que quieras otro nombre distinto de `nzb`. Es el nombre del directorio de la cuenta, así que `usenet` daría `__usenet__` en el mount.
4. Rellena **NNTP host**, **Port**, **TLS** (marcado por defecto, déjalo activado), **Username**, **Password**, **Connections** (el placeholder es `8`; pon aquí el número real que permite tu plan) y **Cache size MB** (el placeholder es `512`).
5. Deja **Watchlist target** desmarcado. El backend no puede añadir contenido y, si lo marcas, el guardado se rechaza. **Disabled** mantiene la entrada en `config.yml` sin cargarla.
6. Haz clic en **Save**.

El formulario se valida como si el cambio ya estuviera aplicado, así que los errores aparecen como una alerta y no te dejan un config roto. Si intentas añadir un **segundo** proveedor `nzb`, se rechaza. El error te apunta a **Further news servers** (o a `nntp.servers`), que es donde van las cuentas de news adicionales.

**Para añadir otro news server**, ya sea una segunda cuenta o una cuenta de bloques en otro backbone, haz clic en **Edit** en la fila `nzb` y luego en **Add news server** dentro de **Further news servers**. Cada servidor tiene su propio **Name**, **NNTP host**, **Port**, **TLS**, **Username**, **Password**, **Connections**, **Priority**, **Backbone** y **Backup only**. **Remove server** elimina uno. **Save** escribe todos en `nntp.servers`.

**Para editar uno**, haz clic en **Edit** en su fila. El formulario carga todo menos las contraseñas, tanto la de la primera cuenta como las de cada news server adicional. Estas quedan en blanco y significan *mantener la existente*. Escribe una contraseña nueva solo si quieres cambiarla. Los ajustes para los que el formulario no tiene campo se mantienen tal como están en `config.yml`.

**Delete** pide confirmación y después elimina la entrada del proveedor de `config.yml`. No toca tu directorio `nzbs/`: los archivos NZB se quedan donde están y vuelven con el proveedor. El último proveedor activo no se puede eliminar ni desactivar.

Cada cambio aquí se escribe directamente en `config.yml` y muestra:

> Provider changes saved to config.yml — restart zurg to apply

Los cambios de proveedores **no** se recargan en caliente. Reinicia zurg antes de esperar que algo cambie.

## 2. Inicia zurg y confirma las cuentas {#2-start-zurg-and-confirm-the-accounts}

+++ Linux y macOS
```bash
./zurg
```
+++ Windows
```powershell
.\zurg.exe
```
+++

Si `zurg setup` instaló zurg para que arranque solo, reinícialo con `zurg service restart` en su lugar (`./zurg service restart`, o `.\zurg.exe service restart` en Windows).

zurg verifica las cuentas de Usenet una vez al arrancar, porque si la contraseña está mal, de otra forma aparece mucho después como que todos los archivos fallan al reproducirse:

```
Usenet account nzb connected: nntps://news.example.com:563 (30 connections)
```

Un fallo total es igual de evidente:

```
Cannot reach the news server for nzb: <reason>
```

Revisa primero el puerto y la combinación de TLS (`563`+`tls: true`, o `119`+`tls: false`), luego las credenciales y por último si el plan está realmente activo.

**Si tienes varias cuentas, lee las advertencias, no solo la línea de conectado.** Cada cuenta inalcanzable genera su propia advertencia, y el arranque sigue mientras *una* cuenta responda. El error de arriba aparece solo cuando todas las cuentas son inalcanzables. Así que un segundo proveedor caído parece un arranque correcto a menos que te fijes:

```
Usenet account block.example.com is not reachable: <reason>
```

---

## 3. Añade archivos NZB {#3-add-nzb-files}

zurg crea la carpeta de vigilancia `nzbs/` al iniciarse. Está en la carpeta desde la que se ejecuta zurg. Copia los archivos NZB dentro de ella.

+++ Linux y macOS
```bash
cp ~/Downloads/Some.Release.2024.2160p.nzb nzbs/
```
+++ Windows
```powershell
Copy-Item "$HOME\Downloads\Some.Release.2024.2160p.nzb" nzbs\
```
+++

En un segundo o dos, zurg detecta el archivo y lo lee, y la biblioteca lo muestra en cuanto termina la lectura. El log indica lo que leyó:

```
Loaded NZB Some.Release.2024.2160p.nzb: 94 files
```

### Qué tan rápido aparece {#how-quickly-it-appears}

zurg vigila `nzbs/` por sí mismo, con una comprobación cada segundo aproximadamente que cuesta una sola llamada al sistema sin importar cuántos NZB tenga el directorio. Por eso, un archivo que llega ahí se lee casi de inmediato, en lugar de esperar a la siguiente comprobación de cambios de la biblioteca. Una [release ofuscada](#obfuscated-releases) tarda un poco más, porque antes sus nombres de archivo reales hay que leerlos de sus propios artículos, normalmente en menos de un segundo, y aparece en cuanto termina ese proceso. Ninguna de las dos esperas depende ya de `check_for_changes_every_secs`. Antes sí dependía: una release ofuscada tardaba hasta dos intervalos completos en aparecer tras soltarla, uno para que se leyera el directorio y otro porque los nombres se resolvían justo después de la comprobación que la habría detectado. Con un intervalo de 10 segundos, eso suponía 17,7 segundos desde que se soltaba el archivo hasta que la release aparecía, de los cuales 0,67 segundos eran el trabajo real.

La comprobación periódica sigue ahí y sigue siendo la red de seguridad. Es la que detecta las dos cosas que un directorio vigilado no puede notificar por sí solo: un NZB **reemplazado en su sitio** con un nombre que ya tenía, y un sistema de archivos cuyas marcas de tiempo de directorio son demasiado gruesas para distinguir dos cambios hechos en el mismo segundo.

### Qué se detecta {#what-gets-picked-up}

- Archivos **directamente dentro de `nzbs/`** cuyo nombre termina en `.nzb`, sin distinguir mayúsculas de minúsculas.
- **Los subdirectorios se omiten.** `nzbs/movies/foo.nzb` es invisible. Usa una carpeta plana en lugar de organizar: la organización de la biblioteca viene de los filtros de directorio, no de esta carpeta.
- **Solo XML plano.** `.nzb.gz` no se descomprime ni se lee; descomprímelo antes.
- Un archivo que no se puede analizar se omite con una advertencia y no detiene el escaneo.

### Cómo se llama la release {#what-the-release-is-called}

El nombre que muestra zurg, y por tanto la carpeta que ve Plex, es:

1. el valor de `<meta type="name">` del propio NZB, si tiene uno y sobrevive a la sanitización, o si no,
2. **el nombre del archivo sin `.nzb`**.

Así que, la mayoría de las veces, *el nombre del archivo NZB es el nombre del lanzamiento*. Ponle al archivo el nombre que le pondrías al lanzamiento, porque es lo que tu servidor multimedia va a intentar encontrar:

```bash
# good
nzbs/Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb

# bad — Plex has nothing to work with
nzbs/indexer_download_48213.nzb
```

Dos lanzamientos distintos que acaben con el mismo nombre se diferencian por una etiqueta hash corta (`Some.Release {a1b2c3}`), igual que en cualquier otro punto de zurg.

### Releases protegidas con contraseña {#password-protected-releases}

Si el indexador guardó la contraseña del archivo en el bloque de metadatos del NZB, zurg la usa al transmitir desde el conjunto RAR:

```xml
<head>
  <meta type="password">thepassword</meta>
</head>
```

No hace falta nada más. Una versión protegida cuyo NZB no lleva metadatos de contraseña no se puede abrir.

### Releases ofuscadas {#obfuscated-releases}

Las publicaciones con nombres de archivo aleatorios se gestionan, con un coste que se paga una sola vez al escanear. zurg prueba primero la fuente más barata: el nombre de archivo que un artículo todavía declara en su propia cabecera yEnc, con un artículo por archivo. Si eso no basta, recurre al índice PAR2 de la release, que registra el nombre real de cada archivo frente al MD5 de sus primeros 16 KiB. El nombre y la longitud exacta están en la cabecera del artículo, así que el escaneo puede responder en cuanto llega esa cabecera, mientras el cuerpo sigue llenando la caché para una lectura posterior. Por tanto, una release ofuscada recibe nombre y tamaño de los mismos artículos. zurg registra lo que ha recuperado:

```
Recovered 27 filename(s) in Some.Release
```

Todo el proceso de renombrado tiene un límite de 90 segundos por NZB, así que un servidor inalcanzable retrasa un escaneo en lugar de bloquearlo. Los nombres se fijan *antes* de construir la biblioteca a partir de ellos, porque la biblioteca indexa los archivos por nombre y un renombrado posterior los haría perderse.

**Una publicación totalmente ofuscada no tiene un nombre real que recuperar.** Algunos publicadores ofuscan antes de crear el conjunto de recuperación, así que el índice PAR2 restaura nombres que también son aleatorios (`aJPSgA7eYizyzjJXT.part01.rar`), y el archivo dentro del archivo comprimido también es un hash. Nada en la publicación indica cuál es la release; solo lo sabe el propio nombre del NZB. Así que zurg presenta el contenido con el nombre de la release, igual que hace SABnzbd al terminar de descomprimir:

```
Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR/
└── Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR.mkv
```

Solo se renombra el archivo que claramente es la release: la entrada más grande del archivo comprimido, y solo cuando pesa al menos tres veces más que la siguiente. Además, su extensión no puede ser parte de una estructura de disco (`.vob`, `.m2ts`, `.mpls`) y su nombre no debe decir nada. Los subtítulos y las muestras que compartan su nombre lo siguen. Un archivo comprimido que contiene varios archivos de tamaño parecido, como un pack de temporada, se deja como está, porque ninguno de ellos es la release. Los nombres originales dentro del archivo comprimido siguen funcionando como direcciones, así que un reproductor que se inició antes de un nuevo escaneo no pierde el archivo.

### Reemplazar y eliminar {#replacing-and-removing}

- **Quitar** un NZB de `nzbs/` elimina el release de la biblioteca, borra su lector en caché y su caché de artículos, y olvida los bytes reparados que tenía guardados.
- **Borrar un release de Usenet desde el Dashboard borra el archivo `.nzb` del disco.** No hay otro lugar donde pueda estar. Esto no es lo mismo que borrar un torrent de una cuenta de debrid, donde el archivo se queda en el servicio.
- **Reemplazar un NZB sobrescribiéndolo es la forma lenta.** Escribir encima de un archivo no cambia el directorio, así que el watch de arriba no lo detecta. Lo que sí lo detecta es la comprobación periódica de cambios, que lee la fecha de modificación del archivo y lo vuelve a parsear: se ejecuta en la primera comprobación de `check_for_changes_every_secs` que llegue más de 15 segundos después de la última lectura del directorio (unos 30 segundos con el valor por defecto). Borrar el archivo viejo y añadir el nuevo se detecta en un segundo o dos, y es lo que hace de todos modos un indexador o el endpoint de SABnzbd.

## 4. Dónde aterrizan las releases en el montaje {#4-where-releases-land-in-the-mount}

Una release de Usenet es una entrada normal de la biblioteca, así que tus filtros `directories:` existentes se aplican a ella sin cambios:

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

Además de esos, la cuenta obtiene un directorio propio: `__nzb__` por defecto, o `__<name>__` si configuras `name:` en la entrada del proveedor. Ese directorio no es solo una vista: las lecturas dentro de él están **fijadas** a la cuenta de Usenet sin ningún failover, lo que lo convierte en el lugar adecuado para comprobar si la reproducción de Usenet funciona sin que una cuenta de debrid responda en silencio. Si Usenet es tu única cuenta, esa carpeta no aparece en el listado raíz del mount y `__all__` contiene los mismos archivos, así que prueba la reproducción dentro de `__all__` en el mount, o abre la ruta HTTP directa `http://localhost:9999/http/__nzb__/`.

Cuatro cosas específicas de Usenet que conviene saber al escribir filtros:

- **Los filtros de tags solo coinciden con contenido de Usenet una vez analizado.** Todos los tags `zurg_*` (resolución, HDR, bitrate, duración, idioma) provienen de ffprobe. zurg ejecuta ffprobe sobre los archivos de Usenet por sí mismo, a través de su propio servidor y a un ritmo que el servidor de noticias puede soportar, así que una release de Usenet recibe sus tags como cualquier otra una vez analizada. Hasta entonces, un directorio basado en `tags_match_any` no la incluye.
- **Los archivos `.par2` y `.sfv` están ocultos.** Son andamiaje de reparación; zurg los lee por su cuenta y ningún servidor multimedia los necesita, sobre todo ocho por cada pack de temporada. `.nfo` se mantiene, porque Kodi, Emby y Jellyfin lo leen.
- **Los conjuntos RAR son contenido, no archivos que descomprimir.** `.rar` y `.rNN` siguen visibles y un conjunto de volúmenes aparece en el mount como una *carpeta* cuyo contenido son los archivos que contiene: zurg transmite el vídeo directamente desde el archivo sin extraer nada. Una release que es *solo* un conjunto de volúmenes sustituye a su propio contenido, sin carpeta de archivo intermedia: el archivo de contenido queda directamente en la carpeta de la release, que es donde lo busca un servidor multimedia. Los archivos publicados junto al conjunto —el `.nfo`, el `.txt` del publicador, las imágenes y los subtítulos— también siguen listados ahí.
- **`force_select_playable_files` no se aplica.** Un post de Usenet es completo; no hay nada que seleccionar. Todos los archivos de contenido ya se ofrecen.

Revisa el resultado antes de involucrar a un servidor multimedia. `http://localhost:9999/http/` es un índice HTML sencillo de exactamente lo que mostrará el mount:

+++ Linux and macOS
```bash
curl -s http://localhost:9999/http/__nzb__/ | head
```
+++ Windows
Escribe `curl.exe`, no `curl`: en Windows PowerShell 5.1 `curl` es otro nombre de `Invoke-WebRequest`.

```powershell
curl.exe -s http://localhost:9999/http/__nzb__/ | Select-Object -First 10
```
+++

---

## 5. Monta con rclone {#5-mount-it-with-rclone}

### El camino fácil: deja que zurg ejecute rclone {#the-easy-path-let-zurg-run-rclone}

```yaml
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run
mount_path: "/mnt/zurg"        # /Volumes/Zurg on macOS, Z: on Windows
```

zurg inicia rclone con un perfil de VFS ya ajustado para su propio patrón de lectura (tamaño de buffer, tamaño de fragmentos, modo de caché, tiempo de caché de directorios, tiempos de espera), mantiene el montaje activo e invalida las entradas correctas de dircache cuando cambia la biblioteca. `mount_path` también es el prefijo que zurg usa para indicarle a Plex qué rutas escanear, así que debe configurarse aunque montes en otro lugar.

Verifica:

+++ Linux
```bash
ls /mnt/zurg/
ls /mnt/zurg/__all__/
```
+++ macOS
```bash
ls /Volumes/Zurg/
ls /Volumes/Zurg/__all__/
```
+++ Windows
Ejecútalo en una ventana de PowerShell en tu escritorio: la unidad solo es visible en la sesión de inicio de sesión que la montó ([las reglas de sesión](../setup/windows.md#keeping-it-running-the-session-rules)).

```powershell
Get-ChildItem Z:\
Get-ChildItem Z:\__all__\
```
+++

### El camino manual: tu propio rclone {#the-manual-path-your-own-rclone}

Si ya usas rclone, apunta un remote WebDAV a zurg:

```ini
[zurg]
type = webdav
url = http://localhost:9999/dav/
vendor = other
pacer_min_sleep = 0
```

+++ Linux
rclone no crea el punto de montaje, y `/mnt` pertenece a root:

```bash
sudo mkdir -p /mnt/zurg && sudo chown "$USER" /mnt/zurg
rclone mount zurg: /mnt/zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ macOS
Necesitas [macFUSE](../setup/macos.md#step-1-install-macfuse) y rclone desde [rclone.org](https://rclone.org/downloads/): el rclone de Homebrew no puede montar. rclone no crea el punto de montaje, y `/Volumes` pertenece a root:

```bash
sudo mkdir -p /Volumes/Zurg && sudo chown "$USER" /Volumes/Zurg
rclone mount zurg: /Volumes/Zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ Windows
Necesitas [WinFsp](https://winfsp.dev). La letra de unidad no debe estar en uso, y solo los programas de la sesión de inicio de sesión que ejecuta rclone la ven ([las reglas de sesión](../setup/windows.md#keeping-it-running-the-session-rules)).

```powershell
rclone mount zurg: Z: --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++

`--vfs-handle-caching 0` requiere rclone 1.74 o más reciente, y evita que rclone siga descargando durante cinco segundos más después de que un lector cierre un archivo. El README explica lo que cuesta omitirlo.

Aun así, configura `mount_path` en `config.yml` con la ruta donde lo montaste, o las notificaciones de escaneo del servidor de medios se construirán con el prefijo incorrecto.

### Docker

El directorio de trabajo de zurg en la imagen es `/config`, y tanto el directorio de vigilancia como la caché de reparación están dentro de él. Un solo bind mount se encarga de todo, junto con lo demás:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:latest
    volumes:
      - ./:/config
    ports:
      - 9999:9999
```

Si dejas un NZB en `./nzbs` en el host, zurg lo detecta dentro del contenedor sin necesidad de reiniciarlo.

Esto requiere un host Linux para el montaje. Docker Desktop en macOS y Windows ejecuta el contenedor dentro de una VM, y el montaje no llega a Finder, Explorer ni a un Plex instalado en el host. En esos sistemas usa el binario para [macOS](../setup/macos.md) o [Windows](../setup/windows.md) ([por qué](../setup/docker.md)).

> Las instalaciones hechas antes de que `/config` hiciera bind mount de `/app/config.yml`, `/app/nzbs` y `/app/data` por separado siguen funcionando exactamente igual. Consulta [docker.md](../setup/docker.md#upgrading-an-install-that-mounted-app).

---

## 6. Apunta Plex hacia él {#6-point-plex-at-it}

1. **Dale a zurg tus credenciales de Plex** para que pueda pedirle a Plex que escanee solo las rutas que cambiaron, en lugar de que tengas que esperar a un escaneo completo periódico. Lo más fácil es usar el flujo de autenticación de Plex en el Dashboard, que escribe los valores de vuelta en `config.yml`:

   ```yaml
   plex_server_url: "http://localhost:32400"
   plex_token: YOUR_PLEX_TOKEN
   ```

2. **Añade bibliotecas que apunten a subdirectorios del montaje**, nunca a la raíz del montaje:

   - Películas → `/mnt/zurg/movies` (`/Volumes/Zurg/movies` en macOS, `Z:\movies` en Windows)
   - Series → `/mnt/zurg/shows` (`/Volumes/Zurg/shows` en macOS, `Z:\shows` en Windows)

   En Windows, Plex solo ve `Z:` cuando se ejecuta en la misma sesión de inicio de sesión que zurg, que es lo que te da la tarea de inicio de sesión de `zurg setup`: mira [las reglas de sesión](../setup/windows.md#keeping-it-running-the-session-rules).

   La misma versión aparece en cada directorio cuyo filtro coincida con ella, y también en `__all__` y `__nzb__`. Si apuntas Plex a la raíz, escaneará el mismo archivo varias veces.

3. **Configura dos opciones de la biblioteca** en Edit → Advanced de cada biblioteca:

   - **Desmarca "Empty trash automatically after every scan".** Esta es la que importa. Si el montaje falla un momento mientras Plex está escaneando (un reinicio de zurg, un remontaje de rclone), Plex cree que todos los archivos se han borrado. Con el vaciado automático activado, se eliminan de forma permanente y de inmediato; con él desactivado, se quedan en la papelera y vuelven cuando el montaje se recupera. Esto ya le ha costado antes a una biblioteca de 30,000 elementos.
   - **Desmarca "Generate video preview thumbnails".** Cada miniatura es un salto a lo largo de todo el archivo; en Usenet eso equivale a leer la versión completa a través de tu cupo de conexión.

4. **Nunca reinicies zurg durante un escaneo de Plex.** Compruébalo antes:

   ```bash
   TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
   curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'
   curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l
   ```

   En Windows, en PowerShell desde la carpeta de zurg:

   ```powershell
   $TOKEN = ((Select-String -Path config.yml -Pattern '^plex_token:').Line -split '\s+')[1].Trim('"', "'")
   (Invoke-RestMethod "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN").MediaContainer.size
   @((Invoke-RestMethod "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN").MediaContainer.Directory | Where-Object refreshing -eq 1).Count
   ```

   Las sesiones con `size="0"` (`0` en Windows) y un contador que se actualiza y marca `0` significan que es seguro. Si la línea de sesiones no imprime nada, Plex rechazó el token o no respondió, y el `0` de debajo no significa nada: revisa `plex_token` antes de reiniciar. (PowerShell muestra el rechazo como un error `401`.) (Usa `grep -o … | wc -l`, no `grep -c`: grep devuelve un código de error distinto de cero cuando no encuentra nada, que es el caso *bueno*, y eso romperá una cadena `&&` justo antes del reinicio que estaba protegiendo.)

5. **Escaneos parciales.** `on_library_update` recibe cada ruta cambiada; `plex_update.sh` en la raíz del repositorio es el script de referencia:

   ```yaml
   on_library_update: sh plex_update.sh "$@"
   ```

   El script necesita `curl`, `xmllint` y `python3`, que tiene la imagen de Docker, y su línea `zurg_mount` debe apuntar a tu ruta de montaje. En Windows, el hook se ejecuta en PowerShell en lugar de `sh`, así que este script no funciona allí. Cada ruta cambiada llega como un elemento de `$args`, relativa al montaje y con barras normales (`movies/Big Buck Bunny`); pásalas a un script de PowerShell con `@args`:

   ```yaml
   on_library_update: '& C:\zurg\my_update.ps1 @args'
   ```

   zurg ya le pide a Plex que escanee las rutas cambiadas una vez completado el paso 1 y configurado `mount_path`, así que un hook solo hace falta para cualquier otra cosa.

**Lo que Plex no obtendrá del contenido de Usenet:** nada hasta que zurg lo haya analizado (mira la sección 4), así que Plex puede hacer su propio análisis en la primera reproducción, como haría con cualquier archivo local. Los tamaños de archivo se estabilizan poco después de que se escanee una versión: el primer listado puede mostrar una estimación barata basada en el número de artículos, y la longitud exacta llega después, desde el índice de recuperación cuando existe, y si no, desde un artículo por archivo. En un archivo grande de varios volúmenes cuyo índice de recuperación ya indica la longitud exacta de todos los archivos, un volumen verificado puede establecer el paso de artículos compartido; cada hermano comprueba esa inferencia con su propio encabezado antes de servir su primer byte. Cuando llega una longitud, la biblioteca recibe el aviso de que la versión cambió, de modo que tanto el montaje como Plex ven la longitud real. zurg calcula el tamaño de hasta ocho versiones a la vez (nunca más que las conexiones de la cuenta) en una cuenta de doce conexiones o menos, y más en una cuenta mayor (doce con 16 conexiones, dieciséis a partir de 20). Cuando la adquisición comprueba una versión con los servidores de noticias, esa comprobación se pone en cola junto a este cálculo de tamaños y a la lectura anticipada, y nunca usa la conexión reservada para una lectura que un reproductor está esperando.

### Jellyfin / Emby / Infuse

Jellyfin y Emby usan `jellyfin_server_url` / `jellyfin_token` y `emby_server_url` / `emby_token`, y reciben las mismas notificaciones de escaneo; mira [jellyfin.md](jellyfin.md). Infuse puede apuntar directamente a `http://<host>:9999/dav/` y así te saltas rclone por completo.

---

## 7. Cuando falta un artículo {#7-when-an-article-is-missing}

Esto es el modo de fallo que tiene Usenet y que el debrid no tiene. Los artículos caducan de la retención de un proveedor o se retiran, y una release puede aparecer listada sin problemas mientras algunos de sus artículos ya no están.

La respuesta de zurg, por orden de preferencia:

1. **Pedir a otro servidor de noticias.** Un artículo que un proveedor ya ha dejado caducar suele seguir estando en otro. Esto es una sola descarga: mira [Más de un proveedor de Usenet](#more-than-one-usenet-provider).
2. **Reconstruirlo con los archivos PAR2 de la propia release.** Para eso se publican. Cuesta leer *toda la release*: Reed-Solomon tiene que combinar todos los fragmentos que sobreviven para calcular el que falta. Así que en un post de 200 GB son 200 GB de lectura para recuperar unos pocos megabytes.
3. **Servir silencio.** Solo cuando ninguna de las dos opciones anteriores puede responder.

La reparación PAR2 es un trabajo en segundo plano, con un máximo de dos releases a la vez, y necesita:

```yaml
enable_repair: true            # the default; set false to turn PAR2 repair off
par2_patch_cache_mb: 512       # budget for data/par2/; -1 keeps repairs in memory only
```

Los bytes reconstruidos se escriben en `data/par2/<nzb-id>/` y se recuperan la próxima vez que se abre el archivo, así que reiniciar no obliga a releer toda la release. Solo se guardan los tramos que de verdad faltan (una release dañada suele costar unos pocos megabytes), y cuando se supera el presupuesto se eliminan primero las releases usadas menos recientemente. Cada tramo lleva la fecha de modificación del NZB con el que se reconstruyó, así que si vuelves a guardar el NZB, zurg descarta esos tramos en lugar de servir bytes en desplazamientos que quizá hayan cambiado.

Una reparación avisa de que empieza y luego indica lo que costó:

```
PAR2 repair of Some.Release: 5 slice(s) missing; reading the release to rebuild them
PAR2 repair of Some.Release rebuilt 5 slice(s) in 55s on the avx2 kernel, keeping 3.4 MiB of them (library holds 3.4 MiB in memory, 3.4 MiB on disk)
```

Hay dos cosas que conviene saber:

- **La reproducción siempre tiene prioridad sobre una reparación.** Las conexiones se reparten según quién está esperando: primero una lectura solicitada por ti, después la lectura anticipada y por último la reparación. Eso sí, una reparación tiene garantizado un cuarto del cupo frente a la lectura anticipada, así que el archivo que estás viendo puede seguir reparando el hueco en el que se ha atascado.
- **La reparación a nivel de biblioteca de zurg no puede ayudar aquí.** Ese mecanismo vuelve a añadir un torrent a la cuenta de la que procedía; un backend que no puede añadir contenido puede informar de que una release está rota, pero no arreglarla. En Usenet, PAR2 *es* la reparación.

Una release sin archivos PAR2 en su NZB y sin una segunda cuenta de noticias no tiene ninguna vía de recuperación. Eso depende del post, no de zurg.

## Rendimiento {#performance}

Medido contra una cuenta de noticias en vivo con un cupo de conexiones grande:

| | |
|---|---|
| Un solo stream, archivo directo | ~100 Mbit/s |
| Un solo stream, desde un conjunto RAR | 90–106 Mbit/s |
| Dos streams concurrentes, total agregado | ~124 Mbit/s |

El cupo de conexiones fija el primer techo de velocidad para un solo stream. zurg mantiene ese cupo lleno dimensionando la lectura anticipada tanto en artículos como en bytes: los posts de archivo con artículos pequeños reciben al menos 64 MiB de alcance, mientras que los posts de varios megabytes conservan la ventana de conexiones y pipeline que ya tenían. Así que:

- **Pon `connections` con el número real de tu plan.** Es la perilla que importa. Con ocho conexiones no vas a poder reproducir un remux.
- **Dos cuentas principales suman.** Las lecturas se reparten según el cupo combinado de las cuentas que no son `backup` y que comparten la `priority` activa más baja. Así que un segundo proveedor ilimitado con la misma prioridad sube el techo y, además, cubre los huecos de retención del primero. Una cuenta `backup` no cuenta para ese total.
- **`warm_connections` (4 por defecto) compra latencia, no velocidad.** Mantiene abiertas esa cantidad de conexiones, inactivas y ya autenticadas, para que la primera lectura tras arrancar o tras un rato de calma no pierda ~0.8 s marcando antes de recibir su primer byte: 1.5 s hasta el primer byte en frío frente a 0.15 s en caliente. Una vez que un stream está en marcha, no cambia nada.
- **Las conexiones nuevas que sí se hacen se quedan con un solo backend, así que sus sesiones TLS se reanudan.** Abrir una conexión nueva cuesta unos 0.8 s, medido contra un servidor de noticias en vivo el 2026-08-29: 106 ms de TCP, 213 ms de handshake TLS, 256 ms de saludo y 218 ms para los dos intercambios `AUTHINFO`. El nombre de host de un proveedor es una rotación (ese resuelve a 11 direcciones), y un ticket de sesión TLS solo sirve en la máquina que lo emitió. Por eso, volver a conectar con la dirección que el resolvedor nombró primero reanudó **0 de 3** sesiones, mientras que volver a conectar con la misma dirección reanudó **3 de 3**. Ahora cada cuenta vuelve a conectar con la dirección de su última conexión, lo que ahorra **110–140 ms en cada reconexión**. Una sesión reanudada tarda 109–141 ms, frente a 225–261 ms de una completa. Un servidor con un ida y vuelta de ~18 ms ahorra menos. El fijado se descarta y el nombre se vuelve a resolver en cuanto esa dirección deja de responder, así que nada queda atado a una máquina que el proveedor ya dio de baja. Un rechazo que llega hasta NNTP (la cuenta en su límite de conexiones, una contraseña rechazada) mantiene el fijado, porque es la respuesta de la cuenta y no del backend. Cada conexión registra sus fases a nivel debug, incluido `resumed=`.
- `cache_size_mb` (512 por defecto) se comparte entre todos los archivos que se leen. Súbelo si tienes varios streams concurrentes; no hace más rápido a un solo stream. Las lecturas especulativas pueden reservar como máximo la mitad de ese valor, repartida entre dos lectores como mucho, para dejar la otra mitad a los artículos ya consumidos o a punto de consumirse.
- Que un release venga empaquetado en RAR o publicado como archivos sueltos ya no importa mucho para la velocidad.

**Un artículo lento ya no frena el stream.** Una lectura secuencial que promedia ~90 MB/s todavía cae a 1–5 MB/s durante casi un segundo cada vez, y cada una de esas caídas tiene la misma causa: un artículo deja de llegar mientras las otras conexiones terminan los suyos y se quedan inactivas. Cuando una lectura lleva en un mismo artículo más tiempo del que ese lector ya aprendió a esperar, zurg pide el mismo artículo a una **segunda conexión** y sirve la respuesta que llegue primero. Un lote encadenado (pipeline) bloqueado puede retener varios artículos seguidos del cabezal de reproducción en el mismo socket muerto, así que de un mismo lector se pueden cubrir en paralelo hasta cinco artículos distintos, o uno o dos en un post cuyos artículos pesan menos de 1 MiB. Nunca se pide dos veces el mismo. La cuenta paga como máximo 20 peticiones de segunda conexión por minuto. El plazo sigue siendo el doble de la espera reciente del propio lector, nunca menos de 250 ms (125 ms en posts con artículos menores de 1 MiB) y nunca más de 2 s. Y solo se cubre una lectura que un cliente está esperando de verdad: la lectura anticipada, la precarga del siguiente volumen y la reparación no. Un artículo que los servidores acaban de *rechazar* tampoco se cubre, porque ese ya está esperando su propia confirmación un segundo después, y pedirlo dentro de esa ventana no demuestra nada. Cada cobertura escribe una línea a nivel debug indicando cuánto tiempo estuvo bloqueada la lectura, y la línea siguiente dice si la segunda petición ganó.

Para los rangos declarados, el artículo del cabezal de reproducción entra en el planificador de prioridades antes de que se ofrezcan los bytes posteriores. Las conexiones en pipeline reciben entonces rondas consecutivas de artículos, no bloques contiguos, así que los primeros artículos útiles se reparten por todo el cupo. Una petición de al menos 64 MiB se trata como reproducción y recibe el frente completo de rangos; una búsqueda pequeña sigue siendo una prueba y solo abre una rampa estrecha.

### Cruzar un límite de volumen {#crossing-a-volume-boundary}

Un archivo dentro de un conjunto RAR se sirve un volumen cada vez, y cada volumen es una lectura separada en la cuenta de noticias. zurg abre el siguiente volumen mientras el actual todavía se está reproduciendo y lee sus primeros cuatro megabytes, así que el cruce no empieza en frío. En un release publicado con volúmenes pequeños, esa cabecera no basta por sí sola: cuatro megabytes son unos diez artículos de un release con partes de ~395 KB, y los volúmenes de ~26 MB ponen un límite cada 1,7 segundos de reproducción. Así que el stream vaciaba la cabecera precalentada de la memoria en un cuarto de segundo y luego esperaba un viaje de ida y vuelta por todo lo que venía detrás. Medido en un Hetzner CCX23 con 10 conexiones el 8 de septiembre de 2026, ese release se reproducía a **14–16 MB/s**, mientras que un archivo normal en la misma cuenta alcanzaba **86–99 MB/s**. Su velocidad por segundo oscilaba entre 1 y 29 MB/s, y entre 46 y 55 de los 60 slots de lectura anticipada de la cuenta se quedaban sin usar.

Ahora zurg precalienta el siguiente volumen con una ventana de lectura anticipada completa en cuanto la reproducción se acerca a menos de 32 MiB del límite. Y un volumen en el que la reproducción acaba de entrar conserva la ventana que ya se había ganado, en lugar de volver a empezar en dos artículos. Un volumen que el cabezal de reproducción no va a alcanzar en varios segundos sigue precalentándose solo en su cabecera. Eso evita que un escaneo de biblioteca (un lector por cada entrada, con unos pocos megabytes de cada una) arrastre una ventana de cada siguiente volumen que nunca va a leer. No hace falta configurar nada, y no cambia el límite de memoria: una cuenta sigue usando dos ventanas de lectura anticipada a la vez, el volumen que se reproduce y el que se está precalentando, dentro de `cache_size_mb`.

Las reparaciones son lentas por naturaleza, porque leen el release entero, pero se ejecutan con prioridad de segundo plano y las limita el propio servidor de noticias, no la aritmética de zurg.

### Memoria: lo que cuesta un directorio de vigilancia {#memory-what-a-watch-directory-costs}

Un NZB es una lista de artículos, y una biblioteca grande tiene muchísimos artículos. Al analizar uno, se guardan en memoria sus message ids y sus desplazamientos para que una lectura pueda encontrarlos. Las versiones anteriores a esta mantenían todos ellos mientras el proceso estuviera activo. Medido en un directorio vigilado de 2.636 NZB, con 27,6 millones de elementos `<segment>`, eso son **1,52 GB de heap en uso**, unos 58 bytes por artículo, además de la caché de artículos. Casi nada de eso se usa de verdad: un listado solo necesita nombres, tamaños y recuentos, y solo un archivo que se está leyendo o reparando necesita saber cómo se llaman sus artículos.

`nzb_segments` decide si zurg los mantiene:

```yaml
nzb_segments: mmap             # mmap (default) | reparse | resident
nzb_segments_idle_secs: 120    # how long a release's articles are kept after the last read
```

- **`mmap`**: las listas se escriben en `data/nzb-index/<id>.bin` y ese archivo se mapea cuando hace falta, así que los bytes están en la caché de páginas y no en el heap de zurg, y el kernel los libera cuando hay presión de memoria. **Es el valor por defecto en Linux, macOS y BSD.** Ocupa más o menos el mismo espacio en disco que las listas.
- **`reparse`**: las listas se liberan cuando una release se ha asentado, y el NZB se vuelve a leer del disco cuando una lectura o una reparación las necesita. No ocupa nada de disco, y por eso se elige: en un host donde `data/` no puede crecer.
- **`resident`**: todas las listas de artículos en memoria, siempre. **El comportamiento anterior**, el que tenían todas las versiones previas. Sigue soportado, pero ya no es lo que obtienes por defecto.

Con cualquiera de los valores, un listado nunca carga nada: el nombre, el tamaño y el número de artículos de un archivo se responden sin que la lista de artículos esté cerca de la memoria, así que una actualización de la biblioteca, una comprobación de huellas y un *arr preguntando si un trabajo ya se ha asentado no cuestan nada. Lo que cuestan los modos perezosos es la primera lectura de una release que nadie ha tocado durante `nzb_segments_idle_secs` (un barrido se ejecuta cada 30 segundos). Además, el conjunto completo de archivos de una release se carga de una vez, así que recorrer en orden los volúmenes rar de un pack de temporada lo paga una sola vez.

Medido en una release de 60 archivos y 30.000 segmentos:

| | heap por release | primera lectura de una release inactiva | por artículo en la ruta de lectura |
|---|---|---|---|
| `resident` | 1,74 MB | — | 6 ns |
| `reparse` | 21,3 kB | 39 ms | 52 ns |
| `mmap` | 16,6 kB | 0,27 ms | 63 ns |

Cincuenta nanosegundos por artículo no son nada comparado con los milisegundos que cuesta obtener uno, así que las cifras de la ruta de lectura importan menos de lo que parecen. La que hay que sopesar es la recarga: `reparse` vuelve a leer y a analizar todo el documento XML, lo que en un pack de temporada son decenas de milisegundos antes de que se mueva el primer byte. `mmap` es una llamada a `mmap`, una cabecera de slice por archivo y un checksum del índice que acaba de mapear: 0,08 ms de los tres. Los otros 0,19 ms son el precio de detectar un byte defectuoso en lugar de servirlo como message id.

Y en una biblioteca completa en lugar de una sola release (2.636 NZB, 27,6 millones de artículos, el mismo binario ejecutado tres veces sobre el mismo corpus, en reposo después de un escaneo):

| | conjunto residente | heap en uso | CPU en reposo | apertura en frío, p50 | índice en disco |
|---|---|---|---|---|---|
| `resident` | 2.921 MB | 2.677 MB | 23 % | 806 ms | — |
| `reparse` | 1.188 MB | 987 MB | 31 % | 1.018 ms | — |
| `mmap` | **1.135 MB** | **921 MB** | 23 % | **694 ms** | 1.456 MB |

Las aperturas en caliente (1 ms), el rendimiento de streaming (38–39 MB/s) y el tiempo de arranque fueron indistinguibles entre los tres. `mmap` abre una release en frío *más rápido* que mantenerlo todo en memoria, porque con `resident` una release que nadie ha abierto en esta ejecución también hay que analizarla. Y mapear un arena ya escrito es una llamada al sistema, mientras que analizar es megabytes de XML.

El índice se reescribe cada vez que cambia el NZB, se repara solo si alguna vez no se puede leer (vuelve al NZB y lo escribe de nuevo) y se elimina cuando el NZB sale del directorio vigilado. Tanto su cabecera como su contenido llevan checksum, así que un byte defectuoso se detecta en lugar de servirse como un message id que nadie publicó. Su tamaño actual aparece en la portada del Dashboard, bajo **Article Index**, y en la línea que el backend registra al arrancar. En **Windows** no hay mapeo: el índice se leería al heap, lo que equivale a memoria residente *más* una recarga. Por eso el valor por defecto allí sigue siendo `resident`, y `reparse` es el modo perezoso que vale la pena elegir.

## Solución de problemas {#troubleshooting}

| Síntoma | Causa | Solución |
|---|---|---|
| `Cannot reach the news server for nzb` al arrancar | Combinación incorrecta de host/puerto/TLS, credenciales malas o un plan inactivo | `563` va con `tls: true`, `119` con `tls: false`; después revisa las credenciales |
| La biblioteca está vacía, no aparecen líneas `Loaded NZB` | `nzbs/` no existe o está en otro sitio | Es relativa al **directorio de trabajo** de zurg. Revisa `WorkingDirectory=` en tu unidad de systemd, o el directorio montado en `/config` en Docker, que es `nzbs/` junto al archivo compose. Solo una instalación anterior a `/config` vigila `/app/nzbs` |
| Un NZB nunca aparece | Está en un subdirectorio, se llama `.nzb.gz` o no se puede analizar | Muévelo directamente a `nzbs/` y descomprímelo; mira en el log si hay una advertencia `Skipping` |
| La release aparece con un nombre inútil | El nombre del archivo NZB es el nombre, si no hay un `<meta type="name">` | Renombra el `.nzb` con el nombre de la release |
| Los archivos tienen nombres aleatorios dentro de la release | Publicación ofuscada cuya recuperación falló | Busca `Recovered N filename(s)`; si el NZB no tiene archivos PAR2, no hay de dónde sacar los nombres reales |
| El vídeo sigue con un nombre aleatorio, aunque la carpeta sea la correcta | Publicación totalmente ofuscada, donde el archivo contiene varios ficheros de tamaño parecido | Solo se renombra un único contenido claro con el nombre de la release; un pack de temporada en un solo archivo conserva los nombres que le dio el archivo |
| La reproducción en streaming va lenta | `connections` se ha dejado en el valor por defecto, 8 | Ponlo al número que permite tu plan |
| La primera reproducción tras un rato sin uso tarda un segundo en empezar, y luego va bien | El mínimo de conexiones en caliente está desactivado, o lo ha dejado en cero una cuenta de una sola conexión | Deja `warm_connections` sin definir (por defecto es 4) y comprueba que ni él ni el `warm_connections` de nivel superior estén en negativo |
| El proveedor rechaza las conexiones | `connections` está por encima de lo que permite el plan | Bájalo a la cifra real |
| La reproducción se entrecorta o un hueco suena en silencio | Faltan artículos | Busca `PAR2 repair of …` en el log; confirma que `enable_repair: true`; añade [another Usenet provider](#more-than-one-usenet-provider) |
| Un hueco se queda en silencio y nunca aparece ninguna línea de reparación | `enable_repair` está desactivado, o el NZB no lleva archivos `.par2` | Pon `enable_repair: true`; si la publicación no tiene archivos de recuperación, solo otra cuenta de noticias puede ayudar |
| Un segundo proveedor nunca parece consultarse | Ambas cuentas tienen el mismo `backbone`, así que la segunda se omite en cuanto la primera dice que el artículo no existe | Corrige los valores de `backbone`; solo las cuentas que de verdad están en el mismo spool deben compartir nombre |
| Una de varias cuentas está caída, pero el arranque parecía correcto | El arranque solo falla cuando *todas* las cuentas son inaccesibles | Busca `is not reachable` en el log; cada cuenta mala avisa por su nombre |
| Una cuenta de bloque cobra por artículos que la cuenta ilimitada también tiene | Falta `backup: true` en ella | Actívalo; así, un primario simplemente ocupado ya no enviará las lecturas a la cuenta de pago por uso |
| Una release no aparece en una carpeta filtrada por etiquetas | Todavía no se ha analizado, así que no tiene etiquetas `zurg_*` | Espera al análisis, o ejecuta Analyze & Tag Library desde el Dashboard |
| Los archivos `.par2` no se ven en el montaje | Es intencionado: están ocultos como andamiaje de reparación | Nada que arreglar; zurg sigue leyéndolos |
| Cambiaste un proveedor en el Dashboard y no pasó nada | Los cambios de proveedor se escriben en `config.yml` pero no se recargan en caliente | Reinicia zurg; el aviso bajo la tabla de proveedores lo dice |
| Plex vació la biblioteca tras reiniciar zurg | Había un escaneo en curso mientras el montaje no estaba, con auto-empty-trash activado | Desactiva auto-empty y cierra las sesiones *y* actualiza el estado antes de cualquier reinicio |
| El tamaño de un archivo cambió un poco justo después de aparecer la release | El primer listado solo puede estimarlo a partir del número de artículos; la longitud exacta llega después, desde el índice PAR2 o desde la cabecera yEnc del propio archivo | Es lo esperado, y se estabiliza una sola vez: la longitud se guarda en `data/nzb-sizes/` y se mantiene hasta que cambie el NZB |

### Preguntar por un artículo concreto {#asking-about-one-article}

`GET /debug/nzb/probe` hace una sola consulta a las cuentas de noticias a través del pool que zurg ya está usando, con la prioridad que recibe una lectura de demanda. Existe porque la alternativa no funcionaba: una cuenta da ocho conexiones y zurg las tiene todas ocupadas, así que probar un post a mano significaba usar una segunda cuenta o parar el servidor, y parar el servidor destruye el estado que se quiere diagnosticar. En Windows, escribe `curl.exe` en lugar de `curl` en estos comandos.

```bash
# Is this article still there? A STAT, so nothing is transferred.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?message_id=abc@news.example'

# The same question addressed the way you have it: a release id from the
# library, a file index counting from zero, an article number counting from one.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&file=0&article=3'

# &body=1 fetches the one article and reports what actually arrived against what
# the article says should have. This is how a provider that strips trailing
# bytes is identified: `short: true` with `decoded_bytes` below `span_bytes`.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&article=3&body=1'
```

Responde con `{"probes": [...]}`, con un objeto por el proveedor `nzb`: `found`, `missing` y cuánto tardó. Pregunta a las cuentas de noticias en orden de prioridad hasta que una lo tiene (una cuenta de respaldo solo se consulta cuando fallan las principales). No dice qué cuenta de noticias tenía el artículo. Es de solo lectura: lo que descarga no entra en la caché de artículos, y un artículo que no encuentra no se registra como muerto, así que una prueba no puede silenciar un archivo que sí reproduce.

---

¿Sigues atascado? Pregunta en el foro **zurg-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) explica qué incluir.

## Ver también {#see-also}

- [config.md](../reference/config.md) — every option, including the [Usenet account reference](../reference/config.md#usenet-accounts) and the [directory filter reference](../reference/config.md#7-directories--filters)
- [plex.md](plex.md) — cómo zurg maneja el escaneo, la coincidencia y la limpieza de Plex
- [jellyfin.md](jellyfin.md) — integración con Jellyfin
- [docker.md](../setup/docker.md) — configuración de Docker, propagación de FUSE y solución de problemas
- [tags.md](../reference/tags.md) — el sistema de etiquetas
- [architecture.md](../internals/architecture.md) — `internal/nzb` y `internal/nntp` en contexto
