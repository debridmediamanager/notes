# Tutorial de macOS {#macos-tutorial}

## Opción de una sola línea {#one-line-option}

El arranque opcional para patrocinadores instala macFUSE si hace falta, descarga la versión para Intel o para Apple silicon y ejecuta el selector de proveedor y el diagnóstico:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Usa el inicio de sesión en el navegador de GitHub. macOS puede pedir aprobación en **System Settings > Privacy & Security** y, quizá, un reinicio. Los binarios y las configuraciones que ya tengas se mantienen. Sigue abajo para la ruta manual.

## Paso 1: Instalar macFUSE {#step-1-install-macfuse}

macFUSE permite que rclone monte el sistema de archivos virtual de zurg como un directorio real en tu Mac.

1. Descarga la última `.dmg` desde [macfuse.io](https://macfuse.io)
2. Abre la `.dmg` y ejecuta el instalador
3. Durante la instalación, macOS bloqueará la extensión del sistema. Ve a **System Settings > Privacy & Security**, desplázate hacia abajo y haz clic en **Allow**
4. **Reinicia tu Mac** (es necesario para que se cargue la extensión del kernel)

Después de reiniciar, abre **Terminal** (pulsa `Cmd + Space`, escribe "Terminal", pulsa Enter) y comprueba que macOS cargará macFUSE. Es la misma comprobación que hace `zurg setup`:

```bash
/Library/Filesystems/macfuse.fs/Contents/Resources/load_macfuse && echo "macFUSE is ready"
```

Si no aparece `macFUSE is ready`, macOS todavía no ha permitido la extensión. En Macs con Apple silicon, activa las extensiones de kernel de terceros en Recovery, permite macFUSE en **System Settings > Privacy & Security**, reinicia y vuelve a comprobarlo.

## Paso 2: Descargar zurg {#step-2-download-zurg}

Abre [GitHub Releases](https://github.com/debridmediamanager/zurg/releases) en un navegador donde hayas iniciado sesión con la cuenta de GitHub que tiene acceso a zurg. Toma la nightly más reciente. Es la pre-release que aparece arriba de la lista. Descarga su zip `darwin-arm64`, o `darwin-amd64` si tienes un Mac con Intel. No tomes la release que GitHub marca como **Latest**. Esa es la v1.0.0. Es más antigua que `zurg setup` y responde con `unknown command`.

Las nightlies son para patrocinadores. Hasta que tu cuenta de GitHub tenga acceso, esa página responde 404. Patrocina en [gatekeeper](https://gatekeeper.debridmediamanager.com/) para darle acceso. La versión pública gratuita es la v1.0.0 de [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). No tiene `zurg setup`. Configúrala a mano como explica [su README](https://github.com/debridmediamanager/zurg-public#readme) en lugar de seguir los pasos de abajo.

Luego descomprímelo.

```bash
mkdir -p ~/zurg && cd ~/zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
```

Verifica:

```bash
./zurg version
```

## Recomendado: deja que zurg termine la configuración {#recommended-let-zurg-finish-the-setup}

```bash
./zurg setup
./zurg doctor
```

`setup` te pregunta qué proveedores quieres configurar. Elige uno o varios de Real-Debrid, TorBox, AllDebrid, Usenet, Premiumize, Debrid-Link y Offcloud, en orden de prioridad. Por ejemplo, escribe `2,4` para TorBox seguido de Usenet. Solo pide las credenciales de los proveedores que elegiste, crea `config.yml` con modo `0600`, descarga rclone (y ffprobe, a menos que ya esté en tu PATH), prepara `/Volumes/Zurg` e instala el inicio automático.

Si el usuario actual tiene un dominio gráfico de launchd, elige un LaunchAgent. En un Mac sin interfaz gráfica y sin ningún usuario con sesión iniciada, instala un LaunchDaemon del sistema que sigue ejecutando zurg como el usuario actual. En esa ruta no hace falta el inicio de sesión automático.

La comprobación de requisitos distingue entre un paquete de macFUSE instalado y una extensión que macOS puede cargar de verdad. En Macs con Apple silicon, la primera instalación de macFUSE puede requerir un cambio de seguridad único en Recovery, aprobarlo en **System Settings > Privacy & Security** y reiniciar. Ningún instalador puede saltarse esas confirmaciones.

Puedes volver a ejecutar setup sin problemas. Actualiza el servicio de launchd generado, pero no reemplaza un `config.yml` que ya exista.

Antes de hacer streaming a través del montaje, abre `config.yml` o el Dashboard en `http://localhost:9999/config/` y configura tanto `--vfs-cache-max-size` como `--vfs-cache-min-free-space` en `rclone_extra_args`. Mantén el máximo por debajo de la mitad del espacio libre actual del disco y reserva al menos `20G` con la opción de espacio libre mínimo. Luego ejecuta `./zurg service restart`.

El resto de esta página explica la configuración y la configuración de Plex. Los pasos 3, 4, 5 y 7 son la alternativa manual y puedes saltarlos si `zurg setup` termina con éxito.

## Paso 3: Configurar zurg manualmente {#step-3-configure-zurg-manually}

Crea un archivo de configuración con tu token de API de Real-Debrid:

```bash
cd ~/zurg
cat > config.yml << 'EOF'
# Minimal config - use Dashboard at http://localhost:9999/config/ for more settings
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN_HERE

rclone_enabled: true
mount_path: /Volumes/Zurg

rclone_extra_args:
  - "--vfs-cache-max-size"
  - "100G"
  - "--vfs-cache-min-free-space"
  - "20G"

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
EOF
```

Reemplaza el token de ejemplo por tu token real de [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354):

```bash
sed -i '' "s|YOUR_RD_API_TOKEN_HERE|PASTE_YOUR_TOKEN_HERE|g" ~/zurg/config.yml
```

> **No elimines `mount_path`.** Sin él, rclone usaría `/Volumes/Zurg` en macOS, pero el escaneo del servidor multimedia solo se activa cuando `mount_path` está definido explícitamente. Si lo omites, Plex nunca recibe el aviso para actualizarse (Paso 6).

> **El tamaño de la caché es crítico.** La caché de VFS guarda fragmentos de los archivos que reproduces en tu disco local. Si llena el disco, el rendimiento de macOS baja mucho: Spotlight, Plex e incluso el propio sistema pueden dejar de responder. Configura siempre **ambos** límites:
>
> - `--vfs-cache-max-size` — límite máximo total de la caché. Ponlo en **no más del 50% de tu espacio libre en disco**. Compruébalo con `df -h /`.
> - `--vfs-cache-min-free-space` — deja de cachear cuando el espacio libre baja de este valor. Mantenlo en **20G o más** como red de seguridad.
>
> Por ejemplo, en un disco de 256GB con 100GB libres, usa `50G` como tamaño máximo y `20G` como espacio mínimo libre.

## Paso 4: Descargar las dependencias manualmente {#step-4-download-dependencies-manually}

zurg tiene un comando integrado que descarga rclone y ffprobe y actualiza `config.yml` con sus rutas:

```bash
cd ~/zurg
./zurg download-requirements
```

Crea el punto de montaje y el directorio de logs. `/Volumes` pertenece a root, así que zurg no puede crear `/Volumes/Zurg` por sí mismo. El directorio de logs tiene que existir antes de que launchd abra sus archivos de salida en el Paso 7:

```bash
sudo mkdir -p /Volumes/Zurg
sudo chown "$(whoami)" /Volumes/Zurg
mkdir -p ~/zurg/logs
```

Consulta [la referencia de configuración](../reference/config.md) para ver todas las opciones disponibles, o usa el Dashboard web en `http://localhost:9999/config/` después de iniciar zurg.

## Paso 5: Probar zurg manualmente {#step-5-test-zurg-manually}

Antes de configurar el inicio automático, comprueba que todo funciona:

```bash
cd ~/zurg && ./zurg
```

Deberías ver en el log cómo zurg arranca, se conecta a Real-Debrid y se monta con rclone. En otra ventana de la terminal, revisa:

```bash
# Check the HTTP endpoint
curl -s http://localhost:9999/http/version.txt

# Check the mount
ls /Volumes/Zurg/
# Expected: __all__  __downloads__  __unplayable__  movies  shows  version.txt
```

Si todo tiene buena pinta, detén zurg con `Ctrl+C`.

## Paso 6: Instalar Plex Media Server {#step-6-install-plex-media-server}

1. Descarga desde [plex.tv/media-server-downloads](https://www.plex.tv/media-server-downloads/) y selecciona **macOS** (Universal)
2. Abre el `.dmg` y arrastra **Plex Media Server** a `/Applications`
3. Inicia Plex Media Server desde Aplicaciones (o con Spotlight: `Cmd + Space` → "Plex Media Server")
4. Tu navegador debería abrir el asistente de configuración de Plex. Sigue los pasos para reclamar tu servidor
5. **Activa el inicio automático:** haz clic derecho en el icono de Plex en la barra de menús y marca **Launch at Login**
6. Obtén tu token de Plex. La forma más fácil:
   - Abre cualquier elemento multimedia en Plex Web
   - Haz clic en **Get Info** (o en **...** → **Get Info**)
   - Haz clic en **View XML**
   - Busca `X-Plex-Token=` en la barra de direcciones

Añade el token de Plex a tu configuración de zurg editando `config.yml`:

```yaml
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
```

## Paso 7: Configurar el inicio automático de zurg manualmente {#step-7-set-up-zurg-auto-start-manually}

macOS LaunchAgents inician los servicios automáticamente cuando inicias sesión. Plex ya se encarga de su propio inicio automático (Paso 6), así que solo necesitamos un LaunchAgent para zurg.

### LaunchAgent de zurg {#zurg-launchagent}

```bash
cat > ~/Library/LaunchAgents/com.zurg.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zurg</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/zurg/zurg</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${HOME}/zurg</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME}/zurg/logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME}/zurg/logs/launchd-stderr.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST
```

Ajustes clave:
- **RunAtLoad**: inicia zurg cuando inicias sesión
- **KeepAlive / SuccessfulExit: false**: si zurg se cierra por error, launchd lo reinicia automáticamente
- **ThrottleInterval: 10**: espera 10 segundos entre los intentos de reinicio

### Cargar el LaunchAgent {#load-the-launchagent}

```bash
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Verifica que esté registrado:

```bash
launchctl list | grep zurg
# Should show com.zurg with a PID
```

## Paso 8: Configurar las bibliotecas de Plex {#step-8-configure-plex-libraries}

Ahora que zurg está en marcha y el montaje está activo:

1. Abre [http://localhost:32400/web](http://localhost:32400/web)
2. Ve a **Settings** (icono de llave inglesa) → **Manage** → **Libraries**
3. Haz clic en **Add Library**

**Añadir biblioteca de películas:**
- Type: **Movies**
- Haz clic en **Browse for media folder**
- Navega hasta `/Volumes/Zurg/movies`
- Haz clic en **Add Library**

**Añadir biblioteca de series:**
- Type: **TV Shows**
- Haz clic en **Browse for media folder**
- Navega hasta `/Volumes/Zurg/shows`
- Haz clic en **Add Library**

**Ajustes recomendados de la biblioteca** (en Edit → Advanced de cada biblioteca):
- Desmarca **Empty trash automatically after every scan**: zurg gestiona el ciclo de vida del contenido
- Desmarca **Generate video preview thumbnails**: ahorra ancho de banda, ya que los archivos se transmiten desde Real-Debrid

## Paso 9: Comprobar que todo funciona {#step-9-verify-everything-works}

```bash
# 1. zurg is running
curl -s http://localhost:9999/http/version.txt && echo " - zurg is up"

# 2. Mount is active
ls /Volumes/Zurg/movies > /dev/null 2>&1 && echo "Mount is active"

# 3. Plex is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:32400/identity && echo " - Plex is up"

# 4. Processes
ps -eo pid,command | grep -E "[z]urg|[r]clone.*mount|[P]lex Media Server" | head -5

# 5. zurg service (for the manual LaunchAgent from Step 7: launchctl list | grep com.zurg)
cd ~/zurg && ./zurg service status
```

## Paso 10: Activar el inicio de sesión automático (opcional) {#step-10-enable-auto-login-optional}

Esto solo es necesario para la ruta manual de LaunchAgent. Un LaunchAgent requiere que un usuario inicie sesión después de cada reinicio. El instalador integrado usa un LaunchDaemon en un Mac sin pantalla (headless).

Si decides usar deliberadamente el LaunchAgent manual en un servidor sin pantalla, activa el inicio de sesión automático para que se inicie sin intervención:

1. Abre **Ajustes del Sistema**
2. Ve a **Usuarios y grupos**
3. Haz clic en **Inicio de sesión automático** y selecciona tu usuario
4. Introduce tu contraseña

> **Nota de seguridad:** El inicio de sesión automático significa que cualquiera con acceso físico al Mac puede acceder a tu cuenta. Úsalo solo en equipos que estén en un lugar de confianza.

---

## Gestionar los servicios {#managing-the-services}

Para una instalación creada con `zurg setup`, usa los mismos comandos en todas las plataformas:

```bash
cd ~/zurg
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` solo elimina el inicio automático. Deja en su sitio el binario, la configuración, los datos, los registros y la caché. Los comandos de launchctl de abajo son para el LaunchAgent manual del Paso 7 (`com.zurg`). `zurg setup` le pone su propio nombre, `com.zurg.zurg`.

### Iniciar / Detener / Reiniciar {#start--stop--restart}

```bash
# Stop zurg (and its rclone child process)
launchctl stop com.zurg

# Start zurg
launchctl start com.zurg

# Restart zurg
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Ver los registros {#view-logs}

```bash
# zurg logs
tail -50 ~/zurg/logs/zurg.log

# Rclone logs
tail -50 ~/zurg/logs/rclone.log
```

### Recargar tras cambiar la configuración {#reload-after-config-change}

Si editas un archivo `.plist`:

```bash
launchctl unload ~/Library/LaunchAgents/com.zurg.plist
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Si editas `config.yml`, simplemente reinicia zurg:

```bash
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Actualizar zurg {#update-zurg}

Una build de sponsor se reemplaza a sí misma:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` descarga la nightly más reciente. Luego comprueba que el nuevo binario informe la versión que esperaba, y solo después lo reemplaza mediante un rename, así que el proceso en ejecución nunca se sobrescribe. Si la build instalada ya es la más reciente, lo indica y no cambia nada.

`update` inicia sesión en GitHub con la cuenta que usaste para la instalación. El instalador guarda para eso la GitHub CLI en `~/zurg/bin`. Si `update` dice que no encontró ninguna credencial de GitHub, tu instalación es anterior a ese cambio. Ejecuta una vez la actualización del instalador y, a partir de ahí, todos los `zurg update` funcionarán. El mismo comando también actualiza una build demasiado antigua para tener `zurg update`.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

También puedes definir `GITHUB_TOKEN` en su lugar. Usa un token clásico con el scope `repo` de la cuenta de GitHub que tenga acceso a zurg.

Si lo haces a mano, descarga el zip `darwin-arm64` nuevo (`darwin-amd64` en un Mac Intel) desde [Releases](https://github.com/debridmediamanager/zurg/releases) de la misma forma que en el Paso 2, y luego:

```bash
cd ~/zurg
./zurg service stop && sleep 2     # manual LaunchAgent: launchctl stop com.zurg
rm -f zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
./zurg service start               # manual LaunchAgent: launchctl start com.zurg
```

Borra el binario viejo en lugar de sobrescribirlo en el mismo sitio. Reescribir el archivo mantiene el mismo inode e invalida su firma de código ad-hoc, y entonces macOS mata la nueva build al ejecutarla: el síntoma es que se cierra de inmediato sin ninguna salida. Por eso `zurg update` hace el cambio con un rename.

## Solución de problemas {#troubleshooting}

### "Operation not permitted" al montar {#operation-not-permitted-when-mounting}

macFUSE necesita que lo apruebes en Ajustes del Sistema:
1. Ve a **Ajustes del Sistema > Privacidad y seguridad**
2. Desplázate hacia abajo y busca un mensaje sobre una extensión del sistema bloqueada
3. Haz clic en **Permitir** y, luego, **reinicia** el equipo

### El montaje aparece como "not a directory" o se queda colgado {#mount-shows-as-not-a-directory-or-hangs}

El punto de montaje puede estar obsoleto por un fallo anterior:

```bash
umount -f /Volumes/Zurg 2>/dev/null
diskutil unmount force /Volumes/Zurg 2>/dev/null
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### zurg se reinicia continuamente (bucle de fallos) {#zurg-keeps-restarting-crash-loop}

Revisa los logs para ver el error:

```bash
tail -100 ~/zurg/logs/service-stderr.log   # manual LaunchAgent: launchd-stderr.log
```

Causas comunes:
- Sintaxis no válida en `config.yml`; valídala ejecutando `cd ~/zurg && ./zurg` manualmente
- Token de Real-Debrid caducado; consigue uno nuevo en [real-debrid.com/apitoken](http://real-debrid.com/?id=20476410)
- `/Volumes/Zurg` no existe o no pertenece a tu usuario; zurg no puede crearlo y falla con `ensure mount path: permission denied` (Paso 4)
- El puerto 9999 ya está en uso; compruébalo con `lsof -i :9999`

### macFUSE deja de funcionar tras una actualización de macOS {#macfuse-breaks-after-macos-update}

Las actualizaciones grandes de macOS a veces invalidan la extensión del kernel. Para reinstalar macFUSE:
1. Descarga la última versión desde [macfuse.io](https://macfuse.io)
2. Instálala
3. Aprueba la extensión en **System Settings > Privacy & Security**
4. Reinicia el equipo

### Todo funcionaba pero dejó de hacerlo tras reiniciar {#everything-was-working-but-stopped-after-reboot}

Si instalaste el LaunchAgent manual y el inicio de sesión automático no está activado, tienes que iniciar sesión antes de que arranque. Puedes:
- Activar el inicio de sesión automático (ver Paso 10)
- Conectarte por SSH: los LaunchAgents se cargarán en cuanto exista la sesión del usuario
- Usar VNC/Screen Sharing para iniciar sesión a distancia

Una instalación creada con `zurg setup` en un Mac sin pantalla usa un LaunchDaemon y no necesita iniciar sesión con interfaz gráfica. Compruébalo con `cd ~/zurg && ./zurg service status`.

¿Sigues atascado? Pregunta en el foro **zurg-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) explica qué incluir.

## Visión general de la arquitectura {#architecture-overview}

```
launchd (PID 1)

  com.zurg LaunchAgent
    └── ./zurg
          ├── HTTP/WebDAV server (:9999)
          ├── Dashboard UI (:9999/config/)
          ├── Real-Debrid API client
          └── rclone mount (child process)
                └── /Volumes/Zurg/
                      ├── movies/
                      └── shows/

  Plex Media Server (:32400)  — Launch at Login via menu bar
    ├── Movies library  → /Volumes/Zurg/movies
    └── Shows library   → /Volumes/Zurg/shows

  macFUSE kernel extension
    └── Enables FUSE mounts for rclone
```

## Referencia rápida {#quick-reference}

Ejecuta estos comandos en `~/zurg`. Las líneas `zurg service` son para una instalación hecha con `zurg setup`; el LaunchAgent manual usa los comandos de launchctl de [Managing the Services](#managing-the-services).

| Acción | Comando |
|--------|---------|
| Iniciar zurg | `./zurg service start` |
| Detener zurg | `./zurg service stop` |
| Reiniciar zurg | `./zurg service restart` |
| Revisar la instalación | `./zurg doctor` |
| Quitar el inicio automático | `./zurg service uninstall` |
| Ver los logs de zurg | `tail -f ~/zurg/logs/zurg.log` |
| Ver los logs de rclone | `tail -f ~/zurg/logs/rclone.log` |
| Revisar el montaje | `ls /Volumes/Zurg/` |
| Revisar el estado de zurg | `curl http://localhost:9999/http/version.txt` |
| Revisar el estado de Plex | `curl http://localhost:32400/identity` |
| Panel | `open http://localhost:9999/config/` |
| Forzar desmontaje | `umount -f /Volumes/Zurg` |
