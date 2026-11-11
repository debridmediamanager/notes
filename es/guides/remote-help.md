# Obtener ayuda con zurg y rex {#getting-help-with-zurg-and-rex}

## Pregunta en Discord {#ask-in-discord}

Publica en el foro de [Discord](https://discord.com/invite/7u4YjMThXP) lo que uses: **zurg-support**, **rex-support** o **dmm-support**. Abre un hilo por cada problema. Di qué hiciste, qué esperabas y qué pasó. Añade los detalles de abajo.

**Para zurg**, haz clic en **Export Logs** en el panel de zurg y pega los enlaces que te dé. Sube el log y la configuración de zurg con tus tokens, contraseñas y claves de API eliminados. Si no puede subirlos, **Download Logs** te da lo mismo como archivo para adjuntar. Pega también lo que imprime `zurg doctor`:

| zurg se ejecuta como | Ejecuta |
|---|---|
| El binario en Linux o macOS | `./zurg doctor` en la carpeta de zurg |
| El binario en Windows | `.\zurg.exe doctor` en la carpeta de zurg |
| Docker | `docker compose exec zurg /app/zurg doctor --working-dir /config` |

**Para rex**, pulsa Play una vez sobre lo que falla y pega el final del log de rex. rex enmascara los tokens de Plex en él.

| rex se ejecuta como | Ejecuta |
|---|---|
| Un servicio systemd en Linux | `journalctl --user -u rex -n 200 --no-pager` |
| launchd en macOS | `tail -n 200 ~/rex/rex.log` |
| Task Scheduler en Windows | `Get-Content $HOME\rex\rex.log -Tail 200` |
| Docker | `docker compose logs --tail=200 rex` |
| Una ventana de terminal | Las últimas 200 líneas de esa ventana |

En un log largo, las líneas más importantes son los errores, las advertencias y lo que rex decidió para cada reproducción. Añade `| grep -E 'ERROR|WARN|upstream|DECISION'` a la línea de Linux, macOS o Docker para mostrar solo esas, o en Windows ejecuta `Select-String 'ERROR|WARN|upstream|DECISION' $HOME\rex\rex.log | Select-Object -Last 50`.

## Ayuda remota para patrocinadores {#remote-help-for-sponsors}

Cuando un hilo no lo soluciona, un ayudante puede escribir en tu terminal mientras tú miras. **La ayuda remota con zurg y rex es solo para patrocinadores y es gratuita.** [Hazte patrocinador en gatekeeper](https://gatekeeper.debridmediamanager.com/). Conecta Discord allí para obtener el rol de patrocinador y luego pregunta en tu hilo de soporte.

Esta página lo configura con [upterm](https://github.com/owenthereal/upterm) a través de `upterm.debridmediamanager.com`. Funciona en Linux, macOS y Windows.

No necesitas contraseña de cuenta, cambios en el router ni instalaciones previas. Los comandos descargan e inician upterm. Sigue cada comando en la misma terminal. Escribe `exit` para terminar la sesión.

### 1. Elige la máquina {#1-pick-the-machine}

Ejecuta upterm en la máquina que ejecuta zurg o rex. Puede que sea un servidor y no el ordenador que tienes delante.

| Dónde se ejecuta | Qué hacer |
|---|---|
| Este ordenador | Abre una terminal aquí y ve al paso 2. |
| Un servidor en la nube como Hetzner, Oracle o un VPS | Conéctate primero por SSH. Después usa la línea de Linux del paso 2 en esa ventana de SSH. |
| Un NAS o servidor en casa como Synology o Unraid | Abre su terminal. Después usa la línea de Linux del paso 2 ahí. |
| Docker | Usa la máquina que ejecuta Docker y no un contenedor. |

También puedes usar SSH desde Windows. PowerShell trae `ssh` integrado.

```bash
ssh you@your-server
```

**Synology** tiene SSH desactivado por defecto. Actívalo en Control Panel > Terminal & SNMP > Enable SSH service. Después inicia sesión con una cuenta de administrador. Usa la dirección del NAS que aparece en tu router o en Synology Assistant.

Si en el paso 2 aparece `cannot create directory` en Synology, activa Control Panel > User & Group > Advanced > Enable user home service y vuelve a ejecutarlo.

**Unraid** tiene una terminal en su página web. Haz clic en el icono `>_` de la parte superior derecha.

### 2. Inicia una sesión {#2-start-a-session}

Pega la línea del sistema que elegiste en el paso 1.

#### Linux y macOS {#linux-and-macos}

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

#### Windows

Abre PowerShell. No necesita ejecutarse como administrador.

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz" -UseBasicParsing; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

En un portátil ARM como el Surface Pro X, reemplaza `amd64` por `arm64`.

La primera vez, upterm te pregunta si quieres confiar en `upterm.debridmediamanager.com`. Escribe `yes`. La huella digital que muestra debería ser esta.

```
SHA256:r1LtSiydnfetLGxGt8hy+ULyqtN2KgnZSHtRgHzDr58
```

### 3. Envía la línea SSH a tu ayudante {#3-send-the-ssh-line-to-your-helper}

upterm muestra unas pocas líneas. Copia la que aparece debajo de **SSH**, que tiene este aspecto.

```
ssh AbCdEfGhIjKlMnOpQrSt:dXB0ZXJt...@upterm.debridmediamanager.com -p 2222
```

**Envíalo en un mensaje privado.** Nunca lo publiques en un canal público. Cualquiera que lo tenga puede escribir en tu equipo.

Luego deja la ventana abierta y no hagas clic dentro de ella: en Windows, un clic en una ventana de PowerShell puede pausar lo que se ejecuta en ella hasta que pulses `Esc`. Verás todo lo que escribe tu ayudante a medida que lo escribe en esa ventana.

### 4. Termina la sesión {#4-end-it}

**Escribe `exit` en esa ventana cuando termines.** La sesión termina y la línea deja de funcionar al instante.

Cerrar la ventana no basta: la sesión sigue activa. Si la cerraste, abre una nueva terminal, ejecuta `~/upterm/upterm session list` (en Windows, `& "$env:LOCALAPPDATA\upterm\upterm.exe" session list`) y luego el mismo programa con `session stop` y el nombre que te muestre.

Para pedir ayuda otra vez más adelante, pega de nuevo la línea del paso 2. Cada sesión tiene una línea nueva.

## Para ayudantes {#for-helpers}

Ejecuta la línea SSH que te enviaron. Sirve cualquier clave SSH; si no tienes ninguna, ejecuta primero `ssh-keygen -t ed25519` una vez. Entrarás en su terminal: PowerShell en Windows, y su shell habitual en Linux y macOS.

Para copiar un archivo, el `:` del ID de sesión confunde a `scp`, así que pásalo como usuario: `scp -P 2222 -o User=<everything before the @> file upterm.debridmediamanager.com:file`.

Pídeles que escriban `exit` cuando termines.
