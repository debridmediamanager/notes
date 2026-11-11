# Configuración con Docker {#docker-setup}

Esta guía ejecuta zurg en Docker y expone su montaje FUSE en un host Linux. Docker aporta zurg, rclone y ffprobe. El comando integrado `setup` crea la configuración y `doctor` comprueba la instalación.

Este flujo se verificó el 4 de septiembre de 2026 con Docker Engine 29.1.1. Usa la compilación nightly con fecha más reciente para que la imagen tenga el selector de proveedores de abajo.

> **Imagen para patrocinadores:** `ghcr.io/debridmediamanager/zurg` es solo para patrocinadores. Hazte patrocinador en [gatekeeper](https://gatekeeper.debridmediamanager.com/). Así tu cuenta de GitHub obtiene acceso a la imagen.

> **Se requiere un host Linux:** el montaje visible desde el host que aparece abajo depende de la propagación de montajes de Linux. Docker Desktop ejecuta los contenedores dentro de una VM en macOS y Windows: no puede propagar este montaje FUSE a Finder ni al Explorador de archivos, y rex no puede acceder a un zurg que esté dentro de esa VM, así que nada se reproduciría allí. Usa la guía del binario para [macOS](https://notes.debridmediamanager.com/es/zurg/setup/macos/) o [Windows](https://notes.debridmediamanager.com/es/zurg/setup/windows/) en ese sistema. En Linux, con rex en otra máquina, pon al contenedor de zurg `network_mode: host`, como muestra [rex con zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex).

## Opción de una sola línea {#one-line-option}

On a fresh Linux host, the optional bootstrap can install Docker when you approve it, configure persistent FUSE mount propagation, sign in to the sponsor registry, write the Compose project, run the provider chooser, and verify the result:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Your existing Compose files and configs are kept. The sections below show every step for those who prefer the manual route.

## Lo que hace el instalador en un contenedor {#what-the-installer-does-in-a-container}

Las banderas son intencionales:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

- `setup` pregunta qué proveedores configurar, solo pide sus credenciales y escribe `config.yml` con modo `0600`.
- `--no-service` deja el inicio automático en manos de la política `restart: unless-stopped` de Docker, en lugar de intentar instalar systemd dentro de Alpine.
- `--skip-downloads` usa rclone y ffprobe que ya están instalados en la imagen.
- `--mount-path` registra el subdirectorio cuyo montaje FUSE se propagará de vuelta al host.

Volver a ejecutar setup es seguro. Valida y actualiza la instalación, pero no reemplaza un `config.yml` existente.

## 1. Instala Docker y desbloquea la imagen {#1-install-docker-and-unlock-the-image}

Instala Docker Engine con el plugin de Compose en el host Linux. Comprueba que ambos comandos funcionan antes de seguir:

```bash
docker version
docker compose version
```

Inicia sesión en GitHub Container Registry con tu nombre de usuario de GitHub. Cuando te pida la contraseña, pega un personal access token clásico con los scopes `read:packages` y `repo`. La imagen pertenece a un repositorio privado, y un token solo con `read:packages` puede iniciar sesión pero aun así fallará al hacer pull:

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

Pon `ZURG_TAG` con la release fechada más reciente para sponsors. Guardarlo en `.env` te da un punto de retorno conocido para volver atrás y hace que las actualizaciones sean explícitas:

```bash
printf 'ZURG_TAG=YYYY.MM.DD.HHMM-nightly\n' > .env
```

Reemplaza el placeholder por el tag real de la release antes de seguir.

## 2. Prepara la propagación del montaje FUSE {#2-prepare-fuse-mount-propagation}

El montaje FUSE debe crearse debajo de un montaje padre compartido. Ejecuta esto una vez antes de que arranque el primer contenedor:

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

Verifica el dispositivo y el modo de propagación:

```bash
test -c /dev/fuse
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

El segundo comando debería mostrar `shared` bajo `PROPAGATION`.

## 3. Crea el proyecto de Compose {#3-create-the-compose-project}

```bash
mkdir -p ~/zurg
cd ~/zurg
```

Crea `docker-compose.yml`:

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

`privileged: true` no es necesario. El dispositivo FUSE, la capacidad `SYS_ADMIN` y el perfil de AppArmor sin confinar son el conjunto más restringido que usa el montaje.

No hagas bind de `/zurg_mnt/zurg` directamente. El montaje FUSE tiene que ser hijo del bind `rshared` para que su evento de montaje llegue al host.

Los contenedores que leen el montaje, sobre todo Sonarr y Radarr, siguen la misma regla desde el otro lado: haz bind del padre (`/zurg_mnt`) una sola vez, con `rslave`, y accede a cada carpeta a través de ese único bind. Montar `__magic__/__all__` y `__magic__/tv` en un \*arr como dos volúmenes convierte cada importación en una copia de todo el archivo. Consulta [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

## 4. Ejecuta la configuración integrada {#4-run-the-built-in-setup}

Desde `~/zurg` ejecuta:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

Elige uno o varios proveedores en orden de prioridad. Por ejemplo, escribe `2,4` para TorBox seguido de Usenet. La configuración solo pide las credenciales de cada uno, crea `config.yml` en `~/zurg`, activa rclone y crea `/zurg_mnt/zurg`. Ninguna credencial se guarda en el archivo compose ni en el historial de la shell.

Para automatizarlo, repite `--provider` y pasa los flags específicos de cada proveedor para el archivo de token o `--nntp-*`. La configuración conserva un config existente en las ejecuciones posteriores.

La configuración escribe las cuentas solo en la ejecución que crea `config.yml`. Para añadir una a una instalación que ya tiene config, usa **Add provider** del Dashboard o edita el archivo y reinicia. Cada servicio tiene su propia página con la credencial, el bloque de config y los límites que conviene conocer: [Providers](../providers/index.md).

## 5. Inicia zurg {#5-start-zurg}

```bash
docker compose up -d
docker compose logs -f --tail=100 zurg
```

Sal del visor de logs con `Ctrl+C`; el contenedor sigue funcionando. El Dashboard está en `http://localhost:9999/config/` y edita el mismo `config.yml` que está junto al archivo compose.

Una biblioteca grande puede tardar un rato en cargarse. Las carpetas del montaje no se listan hasta que termina. Aparecen vacías o como `Input/output error` mientras el Dashboard y `version.txt` funcionan con normalidad. Eso significa que zurg todavía está cargando y no que el montaje esté roto. [Up versus ready](#up-versus-ready) muestra cómo saber cuándo termina la carga.

## 6. Verifica con doctor {#6-verify-with-doctor}

Una vez que la biblioteca esté lista, ejecuta la misma herramienta de diagnóstico que usa una instalación con binario:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`doctor` revisa la configuración y sus permisos, ffprobe, rclone, FUSE, el endpoint HTTP y el montaje que reporta zurg. `WARN service zurg is not installed` es lo esperado en Docker porque Compose se encarga del inicio automático. Las advertencias no hacen que el comando falle; cualquier `FAIL` sí.

Confirma que el montaje propagado también es visible fuera del contenedor:

```bash
cat /zurg_mnt/zurg/version.txt
ls -la /zurg_mnt/zurg/
```

## 7. Haz que el directorio padre compartido sobreviva a los reinicios {#7-make-the-shared-parent-survive-reboots}

El bind a sí mismo del paso 2 no sobrevive a un reinicio. Crea una unidad oneshot de systemd en el host:

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

En el siguiente reinicio, el host prepara el directorio padre compartido antes de que Docker restaure el contenedor de zurg.

## Up frente a ready {#up-versus-ready}

zurg responde a dos preguntas distintas por HTTP. Ninguna necesita contraseña, aunque `username` esté configurado.

| Dirección | Responde 200 cuando | Mientras la biblioteca carga |
|---|---|---|
| `/http/version.txt` | zurg está en marcha | 200 |
| `/ready` | la biblioteca terminó de cargar | 503 con `Retry-After: 5` |

El health check del contenedor consulta la primera. `docker compose ps` muestra `healthy` en cuanto zurg está en marcha. Una biblioteca grande puede seguir cargando durante mucho tiempo después de eso. Consulta `/ready` cuando necesites la biblioteca completa. Responde `ready` cuando la carga termina.

```bash
curl -fsS http://localhost:9999/ready
docker compose exec zurg /app/healthcheck.sh --ready && echo ready
```

Un script puede esperar así.

```bash
until curl -fsS http://localhost:9999/ready >/dev/null; do sleep 10; done
```

### Por qué el health check no espera a la biblioteca {#why-the-health-check-does-not-wait-for-the-library}

Docker guarda un estado de salud por contenedor. Las herramientas que lo leen lo interpretan como "¿está zurg vivo?". autoheal y Docker Swarm reinician un contenedor que pasa a unhealthy. `depends_on` con `condition: service_healthy` retiene a otros servicios hasta que zurg esté healthy.

Se han reportado arranques en frío de 15 a 90 minutos en bibliotecas grandes. Un health check que esperara a la biblioteca retendría a cada servicio dependiente durante todo ese tiempo. Un contenedor rclone delante de zurg dejaría su carpeta de montaje vacía todo ese tiempo. Una carpeta vacía parece, para un servidor multimedia, una biblioteca que se ha borrado. Una carga que durara más que los reintentos del health check también se marcaría como unhealthy. Cualquier cosa que reinicie contenedores unhealthy volvería entonces a empezar la carga desde cero. Nunca terminaría.

### Usar readiness con Compose {#using-readiness-with-compose}

Mantén un contenedor de montaje con el health check por defecto para que su montaje esté listo en cuanto zurg esté en marcha.

```yaml
services:
  rclone:
    depends_on:
      zurg:
        condition: service_healthy
```

Espera a `/ready` en lo que necesite la biblioteca completa. Puede ser un script de escaneo o un trabajo de importación.

Puedes hacer que el propio contenedor de zurg solo se marque como healthy cuando la biblioteca ya se haya cargado. Sobrescribe su health check en `docker-compose.yml` y pon `start_period` más largo que tu carga más lenta. Docker no cuenta los fallos dentro del start period. Así, todos los servicios que dependen de zurg también esperan a la biblioteca. No combines esto con autoheal.

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

## Gestionar y actualizar zurg {#managing-and-updating-zurg}

Ejecuta estos comandos desde `~/zurg`:

```bash
docker compose ps
docker compose logs -f --tail=100 zurg
docker compose restart zurg
docker compose stop zurg
docker compose start zurg
```

El proyecto de compose sigue `ZURG_TAG` de `.env`, que el instalador deja en `latest` para que un pull siempre traiga la nightly más reciente. Para actualizar, haz pull y recrea el contenedor, y luego ejecuta doctor:

```bash
docker compose pull zurg
docker compose up -d zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`zurg update` no es la vía aquí: se niega a ejecutarse dentro de un contenedor. El binario que escribe vive en la capa del contenedor y se pierde en cuanto el contenedor se recrea, así que el siguiente `up` volvería a la build antigua sin avisar. Mejor haz pull de la imagen. `--force` anula esa negativa para un contenedor que quieras conservar.

Para volver atrás, pon `ZURG_TAG` en `.env` con una etiqueta nightly concreta y ejecuta esos tres comandos otra vez. La configuración, el estado de la biblioteca, los logs y la caché montados con bind no se mueven con el contenedor.

`docker compose down` elimina el contenedor y la red, pero deja los archivos montados con bind en `~/zurg` y el directorio padre del montaje en `/zurg_mnt`.

## Dónde está cada cosa {#what-lives-where}

Todo lo que zurg escribe se resuelve contra `/config`, así que el único montaje `./:/config` contiene la instalación:

| Ruta | Qué es |
|---|---|
| `config.yml` | Ajustes y credenciales de los proveedores; los cambios del Dashboard se guardan aquí |
| `data/` | Estado de la biblioteca, archivos locales, claves generadas y la caché VFS de rclone |
| `logs/` | Logs de zurg y rclone |
| `dump/` | Volcados de torrents, cuando está activado |
| `strm/` | Archivos `.strm`, cuando `save_strm_files` está activado |
| `nzbs/` | Directorio de vigilancia para el backend de Usenet |

Descargar o recrear la imagen no cambia ninguno de estos archivos.

`data/rclone-cache` es el que crece. El montaje descarga completo cada archivo que lee y lo conserva después de que termine la reproducción, hasta **256G** por defecto, así que el directorio montado necesita espacio para la caché además de todo lo demás. El límite de edad de 72h, en la práctica, no lo acota: cualquier cosa que lea la biblioteca, incluido el barrido nocturno de un servidor multimedia, cuenta como tocar el archivo.

```bash
du -sh ./data/rclone-cache
```

Limítalo más en `config.yml` si el disco del host no puede con tanto:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Si cambias la ruta del host detrás de `/config`, la caché se renombra y deja la copia anterior huérfana. zurg recupera esos árboles huérfanos en el siguiente inicio y registra lo que liberó. Consulta [config.md](../reference/config.md#disk-the-mount-uses).

### Precarga de entorno para instalaciones desatendidas {#environment-seeding-for-unattended-installs}

La imagen todavía admite la ruta de primer arranque anterior. Si no existe ningún `config.yml`, `TOKEN` o `RD_TOKEN` configuran la cuenta y `MOUNT_PATH` activa el montaje. Esas variables solo se leen mientras se crea el archivo; en cada arranque posterior manda el archivo.

Real-Debrid es la única cuenta que el contenedor en ejecución configura de esta forma. `TORBOX_TOKEN`, `ALLDEBRID_TOKEN`, `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN`, `OFFCLOUD_TOKEN` y `NNTP_HOST` los lee `zurg setup`, así que surten efecto en el contenedor de configuración puntual de arriba y no hacen nada si están en el bloque `environment:` del servicio.

El comando interactivo `setup` es preferible para una persona frente a una terminal, porque el token nunca entra en el archivo de compose. La configuración por variables de entorno sigue siendo útil para la automatización que ya tiene un almacén de secretos.

### Actualizar una instalación que montó `/app` {#upgrading-an-install-that-mounted-app}

Los proyectos de compose antiguos montaban por separado `/app/config.yml`, `/app/data` y otras rutas. El entrypoint sigue eligiendo `/app` siempre que encuentra ese esquema, así que al descargar una imagen más nueva se sigue usando la configuración y la caché antiguas.

Para adoptar el esquema de carpeta única, detén el contenedor, copia el `config.yml` existente, la carpeta `data/` y otros directorios de estado en un mismo directorio del host, y luego monta ese directorio en `/config`.

## Solución de problemas {#troubleshooting}

Empieza con el diagnóstico y los logs actuales:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
docker compose logs --tail=200 zurg
```

### `unknown command "setup"` o `unknown command "doctor"` {#unknown-command-setup-or-unknown-command-doctor}

El contenedor es anterior al instalador integrado. Usa `2026.09.04.1449-nightly` o una imagen de zurg con fecha más reciente, y luego vuelve a crearlo:

```bash
docker compose pull zurg
docker compose up -d zurg
```

### `Transport endpoint is not connected`

El montaje FUSE antiguo está obsoleto:

```bash
sudo umount -l /zurg_mnt/zurg
docker compose restart zurg
```

### El dispositivo FUSE no está disponible {#fuse-device-is-unavailable}

Carga el módulo ahora y en los siguientes arranques:

```bash
sudo modprobe fuse
echo fuse | sudo tee /etc/modules-load.d/fuse.conf
```

Después, confirma que el servicio de compose sigue incluyendo `/dev/fuse`, `SYS_ADMIN` y la configuración de AppArmor.

### El montaje está vacío {#mount-is-empty}

Revisa cada capa en orden:

```bash
docker compose logs zurg 2>&1 | grep -i rclone
docker compose exec zurg ls -la /zurg_mnt/zurg
curl -fsS http://localhost:9999/http/version.txt
curl -fsS http://localhost:9999/ready
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

La ruta del host debe ser un bind mount compartido, y el volumen de compose debe montar el directorio padre como `/zurg_mnt:/zurg_mnt:rshared`.

Si `/ready` falla con el error 503, la biblioteca todavía se está cargando y el montaje está bien. Sus carpetas aparecen vacías o muestran `Input/output error` hasta que termine la carga. Espera en lugar de reiniciar zurg, porque al reiniciar la carga empieza de nuevo.

### El montaje aparece dos veces en la salida de `mount` {#mount-appears-twice-in-mount-output}

Eso es normal. El mismo montaje FUSE se ve en los espacios de montaje del contenedor y del host porque la propagación está funcionando.

¿Sigues atascado? Pregunta en el foro **zurg-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) explica qué incluir.
