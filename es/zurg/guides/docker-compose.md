# Un solo archivo de Docker Compose para zurg, Plex y rex {#one-docker-compose-file-for-zurg-plex-and-rex}

En una máquina Linux, un solo `docker-compose.yml` puede ejecutar zurg, Plex Media Server y rex al mismo tiempo. zurg muestra tu biblioteca como carpetas dentro de `/zurg_mnt/zurg`, Plex Media Server lee esas carpetas y rex obtiene la misma biblioteca directamente desde zurg, sin necesidad de carpetas. Ejecuta el instalador de Docker de zurg una vez y luego sustituye su `docker-compose.yml` por el que tienes abajo.

¿Quieres Plex Media Server o rex, pero no los dos? Deja el otro fuera del archivo. Si no usas Plex, también borra la línea `command:` de rex.

Docker Desktop en Windows o en un Mac no puede ejecutar esto: las carpetas de zurg nunca llegan al Explorador ni al Finder, y rex no puede acceder a un zurg que esté dentro de él. Usa [zurg en Windows](../setup/windows.md) o [zurg en macOS](../setup/macos.md) en esos casos.

## Antes de empezar {#before-you-start}

- **Una máquina Linux** que esté siempre encendida. El instalador añade Docker si no está.
- **Un patrocinio de zurg.** La imagen de zurg es privada. Patrocina en [gatekeeper](https://gatekeeper.debridmediamanager.com/) y eso le da acceso a tu cuenta de GitHub.
- **Tu token de API de Real-Debrid**, o el inicio de sesión de otro servicio compatible con zurg: [Tu token de API de Real-Debrid](../../guides/real-debrid-api-token.md).
- **Para Plex Media Server**, tu cuenta de Plex. **Para rex**, una cuenta de Plex nueva creada solo para eso: [rex con zurg](../../rex/with-zurg.md#before-you-start) explica el motivo.

## 1. Ejecuta el instalador de Docker de zurg {#1-run-zurgs-docker-installer}

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Instala Docker si no lo tienes (te pregunta antes), deja `/zurg_mnt` listo para las carpetas de zurg, tanto ahora como después de cada reinicio, te inicia sesión en GitHub para descargar la imagen de zurg, escribe `~/zurg/docker-compose.yml`, te pide tus servicios y tu token, arranca zurg y ejecuta `zurg doctor`. [La configuración de Docker de zurg](../setup/docker.md) hace lo mismo, pero a mano.

**Lo que deberías ver.**

```bash
ls /zurg_mnt/zurg
```

lista `__all__`, `__downloads__`, `__unplayable__`, `movies`, `shows` y `version.txt`.

## 2. Reemplaza por el archivo completo {#2-swap-in-the-full-file}

```bash
cd ~/zurg
nano docker-compose.yml
```

Reemplaza todo lo que hay en él por esto:

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

- **zurg** es el servicio del instalador, sin cambios.
- **plex** ve las carpetas de zurg en la misma ruta que usa zurg, `/zurg_mnt/zurg`, así que un escaneo que pide zurg nombra una carpeta que Plex conoce. `rslave` mantiene las carpetas ahí cuando zurg se reinicia. Pon tu propia zona horaria en `TZ`.
- **PLEX_CLAIM** inicia sesión de Plex Media Server en tu cuenta en su primer arranque. Con la sesión iniciada en Plex, abre [plex.tv/claim](https://www.plex.tv/claim), copia el código y pégalo justo después del `=`. Caduca en unos pocos minutos, así que arranca el stack enseguida.
- **rex** es el servicio de [rex con zurg](../../rex/with-zurg.md#d2-start-rex-in-docker), en el puerto 32500 porque Plex Media Server usa el 32400. Sus archivos acaban en `~/rex/config`, donde rex con zurg los busca.

Guárdalo y arranca todo:

```bash
docker compose up -d
docker compose ps
```

Si `docker` dice permission denied, pon `sudo` delante de cada comando `docker` de esta página.

**Lo que deberías ver.** Tres contenedores: `plex` y `zurg` dicen `(healthy)`, `rex` dice `Up`. Los archivos propios de Plex Media Server van a `~/plex`.

## 3. Agrega las carpetas de zurg en Plex {#3-add-zurgs-folders-in-plex}

Abre Plex Web en `http://<this machine's LAN IP>:32400/web`. Añade una biblioteca **Movies** con la carpeta `/zurg_mnt/zurg/movies` y una biblioteca **TV Shows** con `/zurg_mnt/zurg/shows`, tal como aparece en [Real-Debrid en Plex](../../guides/real-debrid-plex.md#3-add-the-folders-in-plex).

Para que Plex se entere de las novedades, abre el panel de zurg en `http://<this machine's LAN IP>:9999/config/` y pulsa **Login with Plex** en **Media Server Integration** ([paso 4 de esa guía](../../guides/real-debrid-plex.md#4-let-zurg-tell-plex-about-new-things)).

## 4. Configura rex {#4-set-up-rex}

Sigue [rex con zurg](../../rex/with-zurg.md) desde [D3](../../rex/with-zurg.md#d3-add-it-to-a-plex-account) hasta [D5](../../rex/with-zurg.md#d5-watch), con `32500` donde dice `32400`. Por ejemplo, la línea de zurg es `rex_url: http://192.168.1.20:32500`, con la IP de LAN de rex. Tus apps de Plex entonces muestran los dos servidores: [paso 2 de rex con zurg](../../rex/with-zurg.md#step-2-install-rex) explica cómo distinguirlos.

## Actualizar {#updating}

```bash
cd ~/zurg
docker compose pull
docker compose up -d
```

Eso actualiza zurg, Plex y rex a la vez. Donde rex con zurg ejecuta `docker compose` en `~/rex`, ejecútalo aquí en `~/zurg` con `rex` al final, para que solo toque rex: `docker compose stop rex` en lugar de `docker compose down`, `docker compose up -d rex` en lugar de `docker compose up -d`.

## Cuando algo va mal {#when-something-is-wrong}

`docker compose logs --tail=100 zurg` (o `plex`, `rex`) muestra lo último que dijo un contenedor.

| Lo que ves | Qué hacer |
|---|---|
| El instalador dice `Host-visible Docker mounts require a Linux host. Use the binary installer on macOS or Windows.` | Estás en un Mac o en Windows. Instala zurg con [su instalador de Windows](../setup/windows.md) o de [macOS](../setup/macos.md). |
| `Error response from daemon: error from registry: unauthorized` cuando Docker descarga zurg | Esta máquina no ha iniciado sesión en el registro de GitHub con una cuenta que tenga acceso a zurg. Hazte patrocinador en [gatekeeper](https://gatekeeper.debridmediamanager.com/) y luego vuelve a ejecutar el instalador. Para iniciar sesión a mano, mira [la configuración de Docker de zurg](../setup/docker.md#1-install-docker-and-unlock-the-image): el token necesita tanto `read:packages` como `repo`. |
| `path /zurg_mnt is mounted on ... but it is not a shared mount` | `/zurg_mnt` todavía no está compartido. Ejecuta `sudo mount --bind /zurg_mnt /zurg_mnt` y `sudo mount --make-rshared /zurg_mnt`, y después `docker compose up -d`. El instalador hace que esto se mantenga tras los reinicios; a mano, mira [el paso 7 de la configuración de Docker de zurg](../setup/docker.md#7-make-the-shared-parent-survive-reboots). |
| `zurg` no para de reiniciarse, y su log termina con `Error: config ./config.yml is not valid YAML: yaml: unmarshal errors:` y `mapping key "..." already defined` | Esa opción está repetida en la configuración de zurg. Ejecuta `sudo nano ~/zurg/config.yml`, borra una de las dos líneas que nombra el error, guarda y ejecuta `docker compose restart zurg`. |
| El log de zurg dice `Mount verification failed: mount verification timeout: /zurg_mnt/zurg/version.txt not accessible after 60 attempts -- you appear to be running inside Docker, mount a parent directory with rshared propagation` | Las carpetas de zurg no se han levantado. Comprueba que la línea del volumen de zurg sea `/zurg_mnt:/zurg_mnt:rshared`, con el padre y no `/zurg_mnt/zurg`, y que `/zurg_mnt` esté compartido (la fila de arriba). [El montaje está vacío](../setup/docker.md#mount-is-empty) tiene más comprobaciones. |
| Las bibliotecas de Plex se quedan vacías después de que zurg se reinicie, y `docker exec plex ls /zurg_mnt/zurg` dice `cannot access '/zurg_mnt/zurg': Transport endpoint is not connected` | A la línea del volumen de Plex le falta `rslave`. Debe leer `/zurg_mnt:/zurg_mnt:rslave`. Corrígelo y ejecuta `docker compose up -d`. |
| rex se para con `rex: cannot bind 0.0.0.0:32400: Address already in use (os error 98) (another rex or Plex on this port? --port picks another)` | Plex Media Server ya usa el puerto 32400. Mantén `command: --port 32500` en rex. |
| `/zurg_mnt/zurg/movies` está vacía, o dice `Input/output error`, justo después de arrancar | zurg todavía está leyendo tu cuenta. `curl http://localhost:9999/ready` imprime `ready` cuando termina. No reinicies zurg mientras tanto: eso hace que la lectura empiece de nuevo. |
| Los títulos aparecen en rex pero nada se reproduce | La fila `upstream failed` de [rex con zurg, en Cuando algo va mal](../../rex/with-zurg.md#when-something-is-wrong) comprueba si rex puede llegar a zurg. |
| El disco se llena | zurg guarda una copia de lo reproducido en `~/zurg/data/rclone-cache`, hasta 256G por defecto. [Qué hay en cada sitio](../setup/docker.md#what-lives-where) explica cómo limitarlo. |

¿Sigues atascado? Pregunta en el foro **zurg-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Cómo pedir ayuda](../../guides/remote-help.md) explica qué incluir.

## Preguntas {#questions}

### ¿Puedes revisar mi archivo de docker compose? {#can-you-check-my-docker-compose-file}

Compáralo con el de arriba. Lo más importante: zurg monta `/zurg_mnt` con `rshared`, Plex monta el mismo `/zurg_mnt` con `rslave`, y rex usa la imagen `ghcr.io/debridmediamanager/rex` con `network_mode: host`. Un servicio llamado `rex` que ejecuta `plexinc/pms-docker` es solo un segundo Plex Media Server, no rex.

### ¿Necesito un contenedor de rclone aparte? {#do-i-need-a-separate-rclone-container}

No. zurg ejecuta rclone dentro de su propio contenedor y monta tu biblioteca en `/zurg_mnt/zurg` por sí mismo.

### ¿Puedo usar Plex Media Server y rex juntos? {#can-i-use-plex-media-server-and-rex-together}

Sí, eso es lo que hace este archivo. Plex Media Server reproduce desde las carpetas de zurg, y rex reproduce directamente desde zurg. Tus apps de Plex muestran las dos. Si prefieres no tenerlas las dos, deja solo la que uses.

### ¿Esto funciona en un NAS? {#does-this-work-on-a-nas}

Se probó en un PC con Linux, no en un NAS. El instalador necesita una terminal (SSH) con `sudo` y FUSE (`/dev/fuse`). Si el paso 1 termina con las carpetas de zurg en `/zurg_mnt/zurg`, continúa con el paso 2.

### ¿Con qué versiones se probó esto? {#which-versions-was-this-tested-with}

zurg `2026.11.14.1134-nightly`, rex `2026.11.14.1123-nightly` y Plex Media Server `1.43.5.11079`, del 14 de noviembre de 2026.
