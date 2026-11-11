# Línea de comandos {#command-line}

El binario de zurg es el servidor y un conjunto de herramientas. Ejecútalo sin ningún comando para iniciar el servidor. Todos los comandos aceptan `--help` y muestran el texto en el que se basa esta página.

Ejecuta los comandos desde el directorio de trabajo de la instancia. zurg lee `./config.yml` desde ahí, a menos que pases `--config`. Sus carpetas de datos y de registros también se resuelven respecto a ese directorio.

```
zurg [flags]
zurg [command]
```

## Flags que aceptan todos los comandos {#flags-every-command-takes}

| Flag | Qué hace |
|---|---|
| `-c`, `--config` | El archivo de configuración que se lee. Por defecto es `./config.yml`. |
| `-v`, `--version` | Muestra la versión del build y termina. La salida coincide con `zurg version`. |
| `-h`, `--help` | Muestra la ayuda de zurg o de un comando concreto. |

## Configuración {#setting-up}

### zurg setup

Escribe una configuración, descarga rclone y ffprobe y, después, registra zurg para que arranque solo. Si le falta algo, te lo pide. `--dry-run` muestra el plan y no cambia nada.

Las claves y contraseñas se leen de archivos. Así no quedan en el historial de tu shell.

| Flag | Qué hace |
|---|---|
| `--provider` | Un proveedor a configurar. Repítelo para más de uno. Uno de realdebrid, torbox, alldebrid, nzb, premiumize, debridlink, offcloud, torbox_nzb. torbox_nzb lee su clave de `--torbox-token-file` o `TORBOX_TOKEN`, igual que torbox. |
| `--realdebrid-token-file` | Lee el token de Real-Debrid de este archivo. El mismo flag existe para `torbox`, `alldebrid`, `premiumize`, `debridlink` y `offcloud`. |
| `--nntp-host` | El servidor de noticias para el proveedor `nzb`. |
| `--nntp-port` | Su puerto. Por defecto es 563 con TLS y 119 sin TLS. |
| `--nntp-tls` | Usa TLS. Está activado por defecto. |
| `--nntp-username` | El nombre de usuario de la cuenta de noticias. |
| `--nntp-password-file` | Lee la contraseña de la cuenta de noticias de este archivo. |
| `--nntp-connections` | El número de conexiones que permite la cuenta de noticias. Por defecto es 8. |
| `--mount-path` | Dónde aparece el montaje. Por defecto usa la convención de tu plataforma. |
| `--port` | El puerto HTTP. Si lo omites, mantiene el valor que ya está en la configuración. |
| `--service-name` | El nombre del servicio o de la tarea programada. Por defecto es `zurg`. |
| `--service-scope` | `auto`, `user` o `system`. Por defecto es `auto`. |
| `--service-user` | El usuario con el que se ejecuta un servicio de sistema. |
| `--no-service` | Configura todo, pero no registra el arranque automático. |
| `--no-start` | Registra el servicio, pero no lo inicia. |
| `--skip-downloads` | No descarga rclone ni ffprobe. |
| `--skip-prerequisites` | Omite la comprobación de FUSE para esta plataforma. |
| `--non-interactive` | Falla en lugar de pedirte lo que falte. |
| `--dry-run` | Muestra el plan y no cambia nada. |

Cada plataforma tiene su propia guía paso a paso.

- [Linux](../setup/linux.md)
- [macOS](../setup/macos.md)
- [Windows](../setup/windows.md)
- [Docker](../setup/docker.md)

### zurg doctor

Revisa lo que dejó puesto la configuración. Lee el archivo de configuración y busca rclone y ffprobe. Después comprueba el servicio, el endpoint HTTP y el montaje. Ejecútalo primero cuando algo no funcione.

| Flag | Qué hace |
|---|---|
| `--working-dir` | El directorio de trabajo de la instancia. Por defecto, el actual. |
| `--service-name` | El nombre del servicio a comprobar. Por defecto, `zurg`. |
| `--service-scope` | `auto`, `user` o `system`. Por defecto, `auto`. |

### zurg service

Instala y controla el inicio automático sin ejecutar el resto de la configuración.

| Command | What it does |
|---|---|
| `zurg service install` | Instala el inicio automático y lo arranca. Pasa `--start=false` para instalarlo sin arrancarlo. |
| `zurg service uninstall` | Elimina el inicio automático. La configuración y los datos se mantienen. |
| `zurg service start` | Arranca el servicio instalado. |
| `zurg service stop` | Lo detiene. |
| `zurg service restart` | Lo reinicia. |
| `zurg service status` | Muestra el estado del inicio automático. |

Todos ellos aceptan las mismas opciones.

| Flag | What it does |
|---|---|
| `--name` | El nombre del servicio o de la tarea programada. Por defecto es `zurg`. |
| `--scope` | `auto`, `user` o `system`. Por defecto es `auto`. |
| `--user` | El usuario con el que se ejecuta un servicio del sistema. |
| `--working-dir` | El directorio de trabajo en el que arranca el servicio. |
| `--executable` | El binario de zurg que ejecuta el servicio. |

### zurg download-requirements

Descarga rclone y ffprobe en una carpeta y escribe sus rutas en la configuración. El setup lo hace por ti a menos que pases `--skip-downloads`.

| Flag | Qué hace |
|---|---|
| `--dir` | Dónde se guardan los binarios. Por defecto es `bin`. |
| `--rclone-version` | Una versión de rclone, como `1.67.0`. Por defecto es `latest`. |
| `--ffprobe-version` | Una versión de ffprobe. Por defecto es `latest`. |

### zurg update

Reemplaza el binario con la nightly más reciente para patrocinadores. La cuenta de GitHub que usa necesita acceso de patrocinador desde [gatekeeper](https://gatekeeper.debridmediamanager.com/). Dentro de un contenedor se niega a actualizar, porque la próxima recreación tiraría el binario nuevo a la basura. En ese caso, descarga una imagen nueva. `--force` actualiza de todos modos.

Inicia sesión en GitHub a través de GitHub CLI. Es el que está en tu PATH o el que los instaladores guardan en `bin` junto a zurg. Un inicio de sesión que GitHub CLI guardó sin keyring funciona incluso cuando la CLI en sí ya no está. `GITHUB_TOKEN` también funciona. Si no encuentra ninguno, muestra el comando del instalador que vuelve a poner GitHub CLI.

### zurg version

Muestra la versión de compilación. `zurg --version` muestra lo mismo.

## Obtener ayuda {#getting-help}

### soporte de zurg {#zurg-support}

Envía tu log y tu config al soporte de DMM e imprime un código de soporte, como `K7QM-3XPD`. Publica el código en tu hilo de soporte en Discord. Se guarda durante 7 días y solo el soporte de DMM puede abrirlo.

Envía lo mismo que **Export Logs** en el panel, así que úsalo cuando zurg no arranque o no puedas acceder al panel. Ejecútalo desde el directorio de trabajo de zurg: lee `config.yml` (o `--config`) y `logs/zurg.log` desde ahí. En Docker, ejecuta `docker exec <container> /app/docker-entrypoint.sh support`, que elige el directorio correcto por ti. Si el contenedor no se mantiene activo, ejecuta `docker run --rm -v <your config folder>:/config ghcr.io/debridmediamanager/zurg:<tag> support` con la misma carpeta que montas para zurg.

Antes de enviar se eliminan los tokens, contraseñas, enlaces de descarga y tus propios nombres de host, del mismo modo que lo hace el panel. Una config que no se puede cargar no se envía; en su lugar se envía el error que devuelve. Si un log es muy largo, se recorta desde el extremo más antiguo para que quepa, y el paquete lo indica.

Si el servidor de soporte de DMM no responde o rechaza la subida, zurg te dice por qué y envía los dos archivos a servicios públicos de pegado, imprimiendo sus enlaces. Si no se puede enviar nada, escribe los mismos archivos ya redactados en `zurg-debug.tar.gz` para que lo adjuntes a tu hilo.

## Copias de seguridad {#backups}

### zurg backup

Escribe un archivo `.zurgbackup` con lo que nada más puede reconstruir. Es decir, la configuración con sus tokens y cada `data/*.zurgtorrent` con sus etiquetas y enlaces a las cuentas. También incluye el almacén `__magic__` que está en `data/local/` y los NZB de origen que están en `nzbs/`. Las cachés, las instantáneas de Plex y los logs se dejan fuera para que la copia de seguridad ocupe solo lo que protege.

La instancia no necesita estar en marcha. Así que es seguro programarlo. El archivo es un tar comprimido con gzip y tiene tus tokens dentro. Guárdalo como si fuera una contraseña.

| Flag | Qué hace |
|---|---|
| `-o`, `--out` | Dónde escribirlo. Por defecto es `zurg-<timestamp>.zurgbackup` en el directorio actual. |
| `--include-caches` | Incluye también los metadatos derivados y los bytes en caché para un arranque en caliente. Las instantáneas de Plex y los logs siguen fuera. Puede ocupar mucho espacio. |

### zurg restore-backup

Descomprime un `.zurgbackup` en el directorio actual. Cada archivo vuelve a la ruta de la que salió. Detén zurg antes. La restauración escribe archivos que una instancia en ejecución también está escribiendo.

```
zurg restore-backup my-backup.zurgbackup
```

Si ya hay un config en el directorio, se deja como está. Ese archivo guarda los tokens de los que depende toda la biblioteca. Pasa `--force-config` para sobrescribirlo.

## Medición {#measuring}

### zurg benchmark-my-setup

Lee bytes reales tal como lo haría un reproductor e informa de la dispersión en lugar de una sola cifra. Funciona en tres fases. Primero, cada cuenta por separado. Ese es el número que hay que comparar con lo que promete el servicio. Después, todas las cuentas a la vez. Las cuentas que cada una alcanza 70 MiB/s por su cuenta y 25 MiB/s juntas comparten un enlace de subida saturado. Por último, lee a través del montaje de rclone. La diferencia respecto a la primera fase es lo que cuestan FUSE y VFS.

Las muestras se toman en desplazamientos aleatorios. Cada capa de por debajo hace caché, y releer siempre el mismo desplazamiento mediría la caché en lugar del enlace.

No añade ni borra nada. Sí gasta tu ancho de banda. Cada cuenta lee el tamaño de muestra por el número de iteraciones dos veces. La fase de montaje se suma a eso.

| Flag | Qué hace |
|---|---|
| `-n`, `--iterations` | Muestras por cuenta y por fase. Por defecto 3. |
| `--sample-mb` | MiB leídos por muestra. Por defecto 128. Usa 1024 para superar la rampa de read-chunk de rclone y obtener una cifra sostenida del montaje. |
| `--provider` | Evalúa solo estas cuentas por nombre. Se puede repetir. |
| `--skip-concurrent` | Omite la fase de todas las cuentas. |
| `--skip-mount` | Omite la fase de montaje. |
| `--json` | Muestra el informe en formato JSON. |

### zurg network-test

Mide qué tan rápido este host llega a cada servidor de descarga de Real-Debrid por IPv4 y por IPv6. Los resultados se guardan en `logs/network-test.log` y en `data/`, donde el servidor los lee para elegir sus hosts. Define `PROXY` en el entorno para hacer la prueba a través de un proxy.

| Flag | What it does |
|---|---|
| `-t`, `--test-url` | Una URL de archivo cuya ruta se descarga desde cada servidor en lugar del archivo de prueba de velocidad propio de Real-Debrid. |

## Plex

Estos tres funcionan con el servidor de Plex de este host. Configura Plex primero. Consulta [Integración con Plex](config.md#plex-integration).

### zurg plex-settings

Informa de los ajustes de Plex que importan para un montaje y corrige lo que permite la política. Los valores por defecto de Plex asumen discos locales. Uno de ellos borra la biblioteca cuando un escaneo se topa con un fallo momentáneo. Otros hacen que Plex decodifique todos los archivos que tiene. [plex.md](../guides/plex.md#recommended-plex-settings) explica cada uno.

| Flag | What it does |
|---|---|
| `-p`, `--policy` | `off`, `warn`, `guard` o `enforce` para esta ejecución. Por defecto usa `plex_settings_policy` de la configuración. Si pasas una más estricta, la previsualiza antes de que la adoptes. |

### zurg plex-drift

Lee la base de datos de Plex sin escribir en ella y comprueba cada archivo al que apunta dentro del montaje. Informa de los que ya no existen. Ejecútalo antes de un escaneo de la biblioteca. Un escaneo que se encuentre con esos archivos los convierte en eliminaciones. Saber primero cuántos son hace que el escaneo sea una decisión y no una apuesta.

Necesita `plex_database_path` y Plex en el mismo host.

### zurg plex-backups

Muestra las instantáneas de la base de datos de Plex que zurg guarda, de la más nueva a la más antigua. Cada fila indica cuándo se tomó, su tamaño y cuántos elementos tenía cada biblioteca en ese momento. Los recuentos se obtienen de las propias instantáneas, así que la lista muestra lo que realmente puede restaurar cada una. [Mantenimiento de la biblioteca de Plex](config.md#plex-library-maintenance-same-host-only) explica cuándo zurg las toma.

## Compartir {#sharing}

### zurg export-torrents

Escribe archivos `.zurgtorrent` portables que describen tus lanzamientos sin tu cuenta dentro. No se guarda ninguna credencial. Tampoco ids de torrents, ni estado de reparación, ni enlaces de CDN. No se contacta a ningún proveedor.

Lee `data/*.zurgtorrent` o un archivo de volcado antiguo. Pasa un archivo o carpeta para exportar solo esos. El destinatario pone los archivos en `torrents/<their-account>/` y configura esa cuenta como `library.source: local`. [bibliotecas portables](../guides/local-libraries.md) explica la parte del receptor.

| Flag | Qué hace |
|---|---|
| `--provider` | Exporta los lanzamientos de esta cuenta configurada. |
| `--output` | Dónde se guardan los archivos portables. |
| `--replace` | Reemplaza una exportación existente con el mismo hash. |
| `--skip-invalid` | Omite y cuenta las entradas que no puede leer durante una exportación masiva. |

### zurg nzb-share

Crea una copia compartible de tus NZB que puedes publicar. El resultado es una carpeta con un `manifest.json` y un `.nzb.gz` por cada release, con nombre según su hash de contenido. Cada NZB se limpia primero. Se eliminan los comentarios, los DOCTYPE y los metadatos de marca de agua. También se quitan los nombres de archivo originales. Los posters y las fechas se eliminan, y cada archivo recibe el mismo newsgroup fijo, porque algunos indexadores cambian los tres en cada descarga. Se cortan las marcas de cuenta que un indexador oculta en un subject, un title o una contraseña. Lo que publicas nombra el release y nunca la cuenta que lo descargó. Las contraseñas reales de los archivos se mantienen, porque los destinatarios las necesitan para leer el release.

Publica la carpeta en cualquier sitio estático. Sirve un repositorio de git. También sirve un sitio de Pages o `rclone serve`. La auditoría de lo que se eliminó se queda en tu equipo y se imprime aquí. Contiene justamente los identificadores que la limpieza existe para quitar.

| Flag | Qué hace |
|---|---|
| `--from` | La carpeta de vigilancia que se comparte. Se recorre recursivamente. Por defecto `nzbs`. |
| `--out` | La carpeta de salida. Por defecto `nzb-share-<timestamp>`. |
| `--title` | Un título que se registra en el manifest. |
| `--filter` | Comparte solo las rutas de origen que coincidan con esta expresión regular. |

El dashboard también puede servir una compartición. Consulta [Compartir NZB públicamente](config.md#public-nzb-sharing).

### zurg nzb-sync

Extrae una biblioteca compartida a tu carpeta de vigilancia. Sigue el `manifest.json` de un share desde una URL o una ruta local. Cada NZB se comprueba contra el hash del manifest antes de escribirse. Tus propias cuentas de noticias descargan los datos.

```
zurg nzb-sync https://example.com/share/manifest.json
```

Solo añade. Las entradas que ya tienes se omiten y un share nunca borra nada. Dos shares de los mismos releases se deduplican por hash de contenido.

| Flag | Qué hace |
|---|---|
| `--into` | La carpeta de vigilancia donde escribir. Por defecto `nzbs`. |
| `--dry-run` | Informa de lo que escribiría y no escribe nada. |

## Vaciar una cuenta de Real-Debrid {#clearing-a-real-debrid-account}

Estos dos comandos borran todo de un tipo concreto de una cuenta de Real-Debrid. No se pueden deshacer. Solo funcionan con Real-Debrid.

Ambos piden la cookie `auth` de una sesión del navegador iniciada en Real-Debrid, en lugar de tu token de API. Imprimen una línea de JavaScript que la muestra. Ejecútala en la consola del navegador en real-debrid.com y pega el resultado.

| Comando | Qué hace |
|---|---|
| `zurg clear-torrents` | Borra todos los torrents de la cuenta. |
| `zurg clear-downloads` | Borra todas las descargas de la cuenta. Son los enlaces desrestringidos. |

## Autocompletado de la shell {#shell-completion}

`zurg completion bash` imprime un script de autocompletado para bash. Lo mismo funciona para `zsh`, `fish` y `powershell`. `zurg completion <shell> --help` te dice dónde ponerlo.
