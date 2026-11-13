# rex con tu propia app {#rex-with-your-own-app}

[rex](https://rex.debridmediamanager.com/es/) es un servidor de medios para las apps oficiales de Plex que no es dueño de ningún archivo. Las apps oficiales de Plex lo ven como un servidor Plex normal. Otro programa, que esta página llama **tu app**, le dice a rex qué hay en tu biblioteca y sirve los archivos. Cuando le das a reproducir, rex transmite el archivo directamente desde tu app. No se descarga nada antes.

Esta página te lleva de cero a reproducir una película, paso a paso. No asume ninguna app en concreto. Dice exactamente qué espera rex de una app, para que puedas comprobar que la tuya lo hace, o crear una. Cada paso dice qué hace, por qué importa y qué deberías ver antes de seguir.

Cuatro cosas que conviene saber antes de empezar:

- **Tu app sirve los archivos.** rex obtiene cada byte de tu app por HTTP o HTTPS, igual que un navegador descarga un archivo. rex no guarda archivos y no necesita disco ni montaje para los medios.
- **Tu app le dice a rex lo que tiene.** Le envía a rex una lista de archivos a través de la API de feed de rex, y cada cambio posterior. rex nunca lista una carpeta ni escanea nada.
- **Tu app decide qué es cada archivo.** Indica si un archivo es una película o un episodio, a qué título pertenece (por id de IMDb y TMDB) y, en el caso de un episodio, su temporada y número. rex nunca adivina a partir del nombre del archivo.
- **Plex lo describe.** Una vez que rex está en una cuenta de Plex, muestra cada título con el nombre, el póster, el resumen y los nombres de los episodios que los metadatos propios de Plex tienen para esos ids. Para las cosas que ningún agente de Plex conoce, tu app les pone nombre por sí misma: consulta [Crear addons para rex](addons.md).

rex es gratis para uso personal (PolyForm Noncommercial): no hay nivel de patrocinador y no necesitas cuenta para descargarlo. Consulta [rex.debridmediamanager.com](https://rex.debridmediamanager.com/es/). ¿Solo tienes un móvil o una caja de TV? [rex para Android](https://github.com/debridmediamanager/rex-android) ejecuta rex y sus addons en él.

## Antes de empezar {#before-you-start}

| Lo que necesitas | Por qué |
|---|---|
| La compilación nightly de rex con fecha 2026.10.25 o posterior | El paso 1 descarga la más reciente |
| Una máquina que se mantenga encendida: Linux (Ubuntu 22.04 o posterior), macOS o Windows (64 bits) | rex es un servidor: tus apps de Plex lo contactan cada vez que pulsas play. Cuando los comandos cambian según el sistema, un paso tiene una pestaña para cada uno. [Docker](#run-rex-in-docker) aparece más abajo, para Linux |
| 1 GB de RAM | Con 4.062 películas y 656 series (34.678 episodios), rex usó menos de 500 MB mientras arrancaba y unos 730 MB mientras se navegaba la biblioteca. Convertir vídeo consume más, y necesitas más núcleos o un chip gráfico |
| Una app que haga lo que lista [Lo que tu app debe hacer](#what-your-app-must-do) | De ahí sale tu biblioteca |
| Tu app enviando desde esta máquina, tu red doméstica o Tailscale | rex solo acepta el feed desde ahí ([Mantén el puerto privado](#keep-the-port-private)). Una app en un seedbox o en un servidor en la nube no puede enviar a rex a menos que ese servidor esté en tu tailnet; los archivos sí pueden servirse desde cualquier lugar al que rex llegue |
| ¿Archivos en los discos de esta máquina? Algo que los sirva por HTTP y los envíe | rex nunca lee un disco. [Paso 2](#step-2-see-it-work-by-hand) lo hace a mano para un archivo; para lo demás, mantén Plex para esos |
| ¿Usenet? Una fuente que lo lea, como zurg | rex nunca habla con un proveedor de Usenet. zurg es una fuente que sí lo hace: mira [rex con zurg](with-zurg.md) |
| Una cuenta nueva de Plex, creada solo para rex | rex toma de Plex cada título, póster, resumen y nombre de episodio una vez que se [añade a una cuenta de Plex](#step-3-add-it-to-a-plex-account). Hasta entonces, los títulos conservan sus nombres de archivo y no tienen pósteres |

## Lo que tu app debe hacer {#what-your-app-must-do}

Pásale esta lista a quien haga tu app. La referencia de la API de rex está en [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

| Tu app debe | Cómo | Si no lo hace |
|---|---|---|
| Sirve cada archivo por HTTP | `GET <address>/<path>` responde con el archivo. Las peticiones `Range` hacen que buscar sea rápido; las redirecciones se siguen. Se admite autenticación básica o un bearer token | Nada se reproduce: rex registra 502 |
| Regístrate en rex | `PUT /rex/sources/<name>` (letras, dígitos, `-` y `_`) con `{"url": ...}` y, si tiene inicio de sesión, `"user"` y `"password"` o `"bearer"`, nunca dentro de la url. Otra vez cada vez que se inicie | rex no tiene de dónde leer |
| Envía todos los archivos que tiene | `POST /rex/feed/<name>/items`, unos cientos de archivos por petición | rex se queda vacío |
| Envía la salida de ffprobe de cada archivo | La salida JSON de `-show_format -show_streams` de ffprobe, completa, como `media_info` | El archivo queda **retenido**: se guarda pero no se muestra, porque las apps de Plex se niegan a reproducir un archivo sin ella |
| Indica qué es cada archivo | `kind` (`movie`, `episode` o `extra`) e `ids`: el `imdb` o `tmdb` de la película o de la **serie** (basta con uno), nunca el de un episodio. Para un episodio, `season` y `episode` en el propio elemento (junto a `kind`, no dentro de `ids`), con la numeración de TMDB; `episode_end` para un archivo que contiene varios episodios | El archivo no se empareja: una película con el título de su archivo, un episodio en una serie con el nombre de su release, numerado según el orden del archivo |
| Mantén el mismo `id` para un archivo para siempre | Incluso si lo renombra | Un archivo renombrado se convierte en un título nuevo y pierde su historial de visualización |
| Envía los cambios en cuanto ocurren | El mismo `POST` para archivos nuevos o cambiados, `DELETE /rex/feed/<name>/items` para los eliminados | La biblioteca queda desactualizada |
| Envía la biblioteca completa de vez en cuando | `PUT /rex/feed/<name>/snapshot`. rex elimina lo que el snapshot no nombra | Los archivos que tu app ha perdido de vista se quedan en rex |
| Acepta un `DELETE` de WebDAV de un archivo | Cuando alguien borra un título en una app de Plex, rex primero le pide a tu app que borre el archivo | El título se queda y la app de Plex dice que no se pudo borrar |

## Paso 1. Instala rex {#step-1-install-rex}

**Qué hace.** Descarga rex en `~/rex` (`$HOME\rex` en Windows) y lo arranca como servicio, con todo lo que necesitan los pasos siguientes. Los pasos siguientes no necesitan reiniciar; solo las secciones opcionales de más abajo sí.

**Por qué importa.** rex es con lo que hablan tus apps de Plex. El primer inicio crea `rex.db`, que guarda tus bibliotecas, todo lo que envía tu app y tu historial de reproducción.

En Linux también puedes ejecutar la imagen de Docker de rex: mira [Ejecutar rex en Docker](#run-rex-in-docker).

+++ Linux y macOS
```bash
mkdir -p ~/rex && cd ~/rex
TAG=$(curl -fsSL 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1' | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
P=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -fL "https://github.com/debridmediamanager/rex/releases/download/$TAG/rex-$TAG-$P.tar.gz" | tar xz --strip-components=1
```
+++ Windows
En PowerShell:

```powershell
New-Item -ItemType Directory -Force $HOME\rex | Out-Null; cd $HOME\rex
$tag = (Invoke-RestMethod 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1')[0].tag_name
curl.exe -fLO "https://github.com/debridmediamanager/rex/releases/download/$tag/rex-$tag-windows-amd64.zip"
tar -xf "rex-$tag-windows-amd64.zip" --strip-components=1; Remove-Item "rex-$tag-windows-amd64.zip"
```
+++

Esto descarga la versión más reciente de rex, normalmente una nightly, para tu equipo.

Busca la IP LAN de rex, su dirección en tu red doméstica. En Linux, `hostname -I` muestra varias: quédate con la de tu red doméstica, no con una que empiece por `172.17.` (Docker) o `100.` (Tailscale). En macOS, `ipconfig getifaddr en0` la muestra (`en1` si no muestra nada). En Windows, `ipconfig` la lista como **IPv4 Address** bajo tu adaptador Wi-Fi o Ethernet. **Esta página la escribe como `192.168.1.20` en todas partes: pon la tuya en su lugar.** Las apps de Plex, tu app y tus propios comandos llegan a rex ahí.

**¿Plex Media Server corre en el mismo equipo?** Termina el comando de inicio de rex de abajo con `--port 32500` y usa `32500` donde un comando o ajuste diga `32400`, incluida la regla del firewall de Windows: Plex ya usa el puerto 32400 y los puertos que las apps usan para encontrar servidores, y en cualquier otro puerto rex deja esos a Plex. Tus apps mostrarán entonces dos servidores con el nombre del equipo: rex es el que se comparte contigo, con el nombre de la cuenta nueva al lado. Cuando rex esté en su cuenta de Plex ([paso 3](#step-3-add-it-to-a-plex-account)), puedes cambiarle el nombre: con sesión iniciada en Plex con esa cuenta, abre **Settings** de rex, **General**, cambia **Friendly name** y guarda, luego reinicia rex como abajo. Las apps de Plex lo mostrarán con el nombre nuevo tras el reinicio.

Ahora hazlo un servicio:

+++ Linux
Crea `~/.config/systemd/user/rex.service`:

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/rex.service
```

```ini
[Unit]
Description=rex
After=network-online.target

[Service]
WorkingDirectory=%h/rex
EnvironmentFile=-%h/rex/rex.env
ExecStart=%h/rex/rex
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
sudo loginctl enable-linger "$USER"
journalctl --user -u rex -f
```

El **comando de inicio** de rex es la línea `ExecStart`, y las claves van en `~/rex/rex.env`, una `NAME=value` por línea. Tras un cambio, `systemctl --user daemon-reload && systemctl --user restart rex` reinicia rex. `journalctl --user -u rex -f` muestra su log. `loginctl enable-linger` mantiene rex en marcha cuando cierras sesión.
+++ macOS
`run.sh` inicia rex en su carpeta, y un LaunchAgent inicia `run.sh` cuando inicias sesión:

```bash
cp ~/rex/examples/run.sh.example ~/rex/run.sh
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.rex.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.rex</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$HOME/rex/run.sh</string></array>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$HOME/rex/rex.log</string>
  <key>StandardErrorPath</key><string>$HOME/rex/rex.log</string>
</dict></plist>
PLIST
launchctl load ~/Library/LaunchAgents/com.rex.plist
tail -F ~/rex/rex.log
```

El **comando de inicio** de rex es la última línea de `~/rex/run.sh`, y las claves van en `~/rex/rex.env`, una `NAME=value` por línea. Tras un cambio, `launchctl kickstart -k gui/$(id -u)/com.rex` reinicia rex. `tail -f ~/rex/rex.log` muestra su log.

rex funciona mientras tengas sesión iniciada en el Mac. Para un Mac que se reinicia solo, activa el inicio de sesión automático (**System Settings**, **Users & Groups**). Si el firewall de macOS está activado, permite rex cuando macOS lo pida, o añade `~/rex/rex` en **Options** del firewall.
+++ Windows
Abre PowerShell **como administrador** y ve a la carpeta de rex con `cd $HOME\rex`. Primero crea `run.cmd`, que inicia rex en su carpeta y escribe su log en `rex.log`. El Bloc de notas ofrece crear el archivo:

```powershell
notepad run.cmd
```

```bat
@echo off
cd /d "%~dp0"
rex.exe 2>> rex.log
```

Guárdalo. Luego deja pasar tu red por Windows Firewall al puerto de rex y a los dos puertos de descubrimiento, e inicia rex ahora y cada vez que inicies sesión:

```powershell
New-NetFirewallRule -DisplayName rex -Protocol TCP -LocalPort 32400
New-NetFirewallRule -DisplayName "rex discovery" -Protocol UDP -LocalPort 32410,32414
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask rex -Action (New-ScheduledTaskAction -Execute "$HOME\rex\run.cmd") -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) -Settings $settings
Start-ScheduledTask rex; Start-Sleep 3
Get-Content rex.log -Wait
```

El **comando de inicio** de rex es la línea `rex.exe` de `run.cmd`, y las claves van encima, una `set NAME=value` por línea. Tras un cambio, `Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex` reinicia rex. `Get-Content $HOME\rex\rex.log -Wait` muestra su log.

¿Iniciaste rex a mano en PowerShell? Entonces su log solo está en esa ventana, sin `rex.log`, y ninguna tarea lo inicia tras reiniciar. rex guarda su base de datos y su vinculación en la carpeta desde la que arranca, así que un rex iniciado desde otra carpeta es un servidor nuevo, sin reclamar. Deténlo con Ctrl+C y luego inícialo de nuevo desde la carpeta de rex con los mismos flags, o mejor, configura la tarea de arriba.

rex funciona mientras tengas sesión iniciada en Windows, en una ventana propia: déjala abierta. En PowerShell, escribe `curl.exe` donde esta página diga `curl`: el `curl` propio de Windows PowerShell es otro comando.
+++

**Qué deberías ver.** Entre las primeras líneas:

```
INFO    seeded rex.db: an empty library named yourhost, machine=...
INFO    no source yet: a source registers itself once pointed at this server (PUT /rex/sources/{name}, docs/feed-api.md)
INFO    claim state: unclaimed
INFO    rex on http://192.168.1.20:32400  machine=...  items=0  parts=proxy
```

rex se llama como el equipo; tus apps de Plex muestran ese nombre. `no source yet` es lo correcto: todavía ninguna app se ha registrado. Deja el log abierto.

## Paso 2. Mira cómo funciona a mano {#step-2-see-it-work-by-hand}

**Qué hace.** Hace de tu app para una sola película, con un servidor de archivos temporal y dos comandos `curl`.

**Por qué importa.** Comprueba que rex funciona en esta máquina antes de meter tu app en el asunto. Si este paso funciona y tu app no, el problema está en tu app. Sáltatelo si tu app ya está configurada.

Necesitas `ffprobe`, un servidor web pequeño y un archivo de vídeo. Registras la carpeta del archivo en rex con el nombre `test` y luego le envías a rex el archivo, indicando que es la película Sintel (IMDb `tt1727587`, TMDB `45745`) junto con la salida de ffprobe.

+++ Linux y macOS
Instala `ffprobe` y `jq` (`sudo apt install -y ffmpeg jq` en Linux, `brew install ffmpeg jq` en macOS). Pon el archivo donde un servidor web pequeño pueda servirlo:

```bash
mkdir -p ~/rex-test/movies/Sintel.2010
cp /path/to/any-video.mkv ~/rex-test/movies/Sintel.2010/Sintel.2010.mkv
cd ~/rex-test
python3 -m http.server 8099 --bind 127.0.0.1 &
```

Regístralo en rex:

```bash
curl -s -X PUT http://192.168.1.20:32400/rex/sources/test \
  -H 'Content-Type: application/json' -d '{"url": "http://127.0.0.1:8099"}'
```

Envíale el archivo a rex:

```bash
P=movies/Sintel.2010/Sintel.2010.mkv
jq -n --arg p "$P" \
  --argjson probe "$(ffprobe -v quiet -print_format json -show_format -show_streams "$P")" \
  '{items: [{id: $p, path: $p, kind: "movie", ids: {imdb: "tt1727587", tmdb: 45745}, media_info: $probe}]}' \
| curl -s -X POST http://192.168.1.20:32400/rex/feed/test/items \
    -H 'Content-Type: application/json' --data-binary @-
```
+++ Windows
Instala `ffprobe` y Python con `winget install Gyan.FFmpeg` y `winget install Python.Python.3.13`, y luego abre una ventana nueva de PowerShell. Pon el archivo donde un servidor web pequeño pueda servirlo:

```powershell
New-Item -ItemType Directory -Force $HOME\rex-test\movies\Sintel.2010 | Out-Null
Copy-Item C:\path\to\any-video.mkv $HOME\rex-test\movies\Sintel.2010\Sintel.2010.mkv
cd $HOME\rex-test
$server = Start-Process py '-m http.server 8099 --bind 127.0.0.1' -WindowStyle Hidden -PassThru
```

Regístralo en rex:

```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/test -ContentType application/json -Body '{"url": "http://127.0.0.1:8099"}'
```

Envíale el archivo a rex:

```powershell
$p = 'movies/Sintel.2010/Sintel.2010.mkv'
$probe = ffprobe -v quiet -print_format json -show_format -show_streams $p | Out-String | ConvertFrom-Json
$item = @{ id = $p; path = $p; kind = 'movie'; ids = @{ imdb = 'tt1727587'; tmdb = 45745 }; media_info = $probe }
Invoke-RestMethod -Method Post http://192.168.1.20:32400/rex/feed/test/items -ContentType application/json -Body (ConvertTo-Json @{ items = @($item) } -Depth 20)
```

PowerShell muestra las respuestas de rex como listas en lugar de JSON.
+++

**Qué deberías ver.** La respuesta es `{"created":1,"updated":0,"held":0,"unchanged":0}` y el log de rex muestra:

```
INFO    FEED identified "Sintel.2010" -> movie tmdb:45745 (placed)
INFO    FEED test upsert: 1 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Sintel ya está en **Movies**, reproduciéndose desde el pequeño servidor web. Ninguna app de Plex puede abrir rex antes del [paso 3](#step-3-add-it-to-a-plex-account), así que este paso solo comprueba el feed.

**Limpieza** antes de seguir: al eliminar la fuente de prueba se borra todo lo que envió. La primera petición responde con una ruta `confirm`; envía un `DELETE` a esa ruta dentro de cinco minutos.

+++ Linux y macOS
```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/test
curl -s -X DELETE "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
kill %1
```
+++ Windows
```powershell
Invoke-RestMethod -Method Delete http://192.168.1.20:32400/rex/sources/test
Invoke-RestMethod -Method Delete "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
Stop-Process -InputObject $server
```
+++

**Si no funciona.**

- `"held":1`: `media_info` falta o no tiene streams. Comprueba que `ffprobe` imprimió JSON para el archivo.
- Una respuesta con `rejected`: el archivo no es un vídeo por su extensión, es una muestra, no tiene `id` o `path`, la ruta está mal formada, o otro `id` ya tiene esa ruta. La respuesta y el log de rex indican cada motivo.
- `404 no such source`: el `PUT /rex/sources/test` no se hizo antes.

## Paso 3. Añádelo a una cuenta de Plex {#step-3-add-it-to-a-plex-account}

**Qué hace.** Registra rex en una cuenta de Plex, igual que lo harías con un Plex Media Server real, y lo comparte con tu propia cuenta.

**Por qué importa.** rex obtiene el nombre, el póster, la sinopsis y los nombres de los episodios de cada título a partir de los metadatos de Plex, y solo puede consultarlos una vez que está en una cuenta. Lo que tu app envía antes de la reclamación se nombra en cuanto llega, y Fix Match no ofrece nada hasta entonces. También elimina el aviso de "no reclamado" y es necesario antes de [usar rex fuera de tu casa](#use-it-outside-your-home-optional).

**Usa una cuenta nueva de Plex para esto, no la tuya.** rex no lo hace Plex, y Plex podría tomar medidas contra una cuenta que lo registre. Mantén tu cuenta real, con su historial de reproducción, sus amigos y cualquier Plex Pass, fuera de peligro: crea una cuenta gratuita nueva en [plex.tv](https://www.plex.tv) con una dirección de correo que no uses en ningún otro sitio, registra rex en esa cuenta y comparte rex con tu propia cuenta. Así reproduces con tu sesión iniciada como tú mismo, igual que verías el servidor de un amigo. rex no reproduce nada hasta que se completa este paso.

### Registra rex en la cuenta nueva {#register-rex-on-the-fresh-account}

1. Inicia sesión en [plex.tv](https://www.plex.tv) **con la cuenta nueva**, abre [plex.tv/claim](https://www.plex.tv/claim) y copia el código. Caduca en unos cinco minutos.
2. En la máquina de rex (`curl.exe` en Windows):

   ```bash
   curl -X POST "http://192.168.1.20:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://192.168.1.20:32400/identity
   ```

**Lo que deberías ver.** El segundo comando muestra `claimed="1"`, y el archivo `claim_state.json` existe en la carpeta de rex. Haz una copia de seguridad de ese archivo: sin él, rex tiene que volver a vincularse, y rex rechaza una segunda vinculación mientras el archivo esté ahí. A partir de ahora, los títulos llegan con su nombre y sus pósters, sin necesidad de reiniciar.

**Si no.**

- El primer comando responde `409` con `rex: already claimed`: rex ya está vinculado a una cuenta de Plex.
- Responde `500 Internal Server Error` y rex registra `claim exchange failed`: el código caducó o ya se usó. Consigue uno nuevo en [plex.tv/claim](https://www.plex.tv/claim).

### Compártelo con tu propia cuenta {#share-it-with-your-own-account}

1. Sigue con la cuenta nueva, abre [app.plex.tv](https://app.plex.tv) y luego **Settings** (la llave inglesa), **Manage Library Access** y **Grant Library Access**.
2. Escribe el nombre de usuario o el correo de tu cuenta, elige el servidor de rex y las dos bibliotecas, **Movies** y **TV Shows**, y envía la invitación.
3. Cierra sesión, entra como **tú** y acepta la invitación. Llega por correo y en app.plex.tv.

![Manage Library Access in app.plex.tv's settings, with the Grant Library Access button](../assets/rex/20-plex-manage-library-access.webp)

![The Grant Library Access dialog with the rex server's Movies and TV Shows ticked](../assets/rex/21-plex-grant-library-access.webp)

**Qué deberías ver.** Con tu cuenta, las apps de Plex muestran el servidor de rex junto a tus propios servidores, con las dos bibliotecas. Tu historial de reproducción en rex es tuyo: se guarda aparte del de la cuenta nueva. Compártelo de la misma forma con cualquier otra persona de tu casa.

## Paso 4. Conecta tu app {#step-4-connect-your-app}

**Qué hace.** Apunta tu app a rex. Tu app se registra, envía toda su biblioteca y después cada cambio en cuanto ocurre.

**Por qué importa.** Este es el único vínculo entre los dos. rex no tiene ninguna opción para tu app: tu app encuentra a rex, y no al revés.

Dale a tu app la dirección de rex, `http://192.168.1.20:32400`. Cómo la introduces depende de tu app.

**Qué deberías ver.** El log de rex muestra, bajo el nombre con el que tu app se registró:

```
INFO    SOURCES myapp registered at http://192.168.1.20:8080
INFO    SOURCES PUT /rex/sources/myapp -> 200
INFO    FEED myapp upsert: 0 created, 0 updated, 200 held, 0 unchanged, 0 rejected
INFO    FEED identified "Some.Movie.2019.1080p" -> movie tmdb:12345 (placed)
INFO    FEED myapp upsert: 180 created, 0 updated, 20 held, 0 unchanged, 0 rejected
```

rex lee cada archivo desde la dirección de la línea `registered at`, así que tiene que poder llegar a tu app ahí. rex vuelve a registrar esa línea solo cuando cambia la dirección. Los archivos `held` esperan la salida de ffprobe y aparecen en cuanto tu app la envía. Puedes revisar en cualquier momento lo que rex tiene de tu app (en Windows, usa `curl.exe` sin `| head -c 600`):

```bash
curl -s http://192.168.1.20:32400/rex/sources                # the apps that registered, and their addresses
curl -s http://192.168.1.20:32400/rex/feed/myapp/items | head -c 600   # what is shown
curl -s http://192.168.1.20:32400/rex/feed/myapp/held  | head -c 600   # what waits for ffprobe output
```

**Si no.**

- No aparece nada en el log de rex: tu app nunca llegó a rex. Revisa la dirección que le diste y que el puerto de rex esté abierto entre las dos máquinas.
- Llegan archivos pero no aparecen líneas `identified`: tu app no envía `kind` ni `ids` (los archivos `held` y los reenvíos sin cambios tampoco muestran nada). Esos títulos quedan sin emparejar hasta que lo haga. Aun así puedes corregir uno a mano con **Fix Match** en una app de Plex con sesión iniciada en la cuenta nueva. Tu propia cuenta, con la que se comparte rex, se rechaza.
- Aparecen títulos pero no se reproduce nada: rex no puede llegar a tu app en la dirección de `registered at`. La fila `upstream failed` de [Cuando algo va mal](#when-something-is-wrong) lo comprueba.

## Paso 5. Mira algo {#step-5-watch-something}

**Qué hace.** Abre rex en una app de Plex, igual que harías con cualquier servidor de Plex.

**Por qué importa.** Este es el objetivo de toda la configuración. Además, confirma el último eslabón: que rex lea un archivo desde tu app mientras miras.

Abre una app de Plex en un teléfono, una TV o un ordenador **en la misma red doméstica**. rex aparece con el nombre de la máquina, con **Movies** y **TV Shows**. Elige una película y pulsa play.

![Una app de Plex mostrando las bibliotecas Movies y TV Shows del servidor rex en la barra lateral, junto a una cuadrícula de películas](../assets/rex/10-plex-server-libraries.webp)

En casa no hace falta nada más: las apps de Plex encuentran rex con el descubrimiento local propio de Plex y se conectan a él por tu red. Para eso el dispositivo debe estar en la misma red que rex (no en una red de invitados ni en una VLAN separada). El descubrimiento usa los puertos UDP 32410 y 32414, así que un cortafuegos en la máquina de rex debe permitirlos (en Windows, las reglas de cortafuegos del paso 1 lo hacen). rex responde al descubrimiento cuando usa el puerto 32400. Si cambiaste rex al 32500 porque Plex corre en la misma máquina, el descubrimiento lo gestiona ese Plex, y las apps encuentran rex a través de la cuenta de Plex con la que está [compartido](#share-it-with-your-own-account). app.plex.tv en un navegador web también funciona en casa, por la dirección HTTPS que [rex-direct](#rex-direct) le da a rex una vez reclamado (rex nightly 2026.11.02 o posterior). La primera vez, Chrome pregunta si app.plex.tv puede acceder a dispositivos de tu red local: permítelo. `http://192.168.1.20:32400/web` no es Plex Web: rex no tiene app web propia, y esa página solo indica si rex está reclamado y dónde ver.

**Lo que deberías ver.** Pósters, títulos y años como en cualquier servidor de Plex. La reproducción empieza en pocos segundos.

Dos cosas con las que te puedes encontrar:

- **"yourhost server is unclaimed and not secure".** Una app de Plex dice esto de cualquier servidor que no está en una cuenta de Plex, y rex no reproduce nada hasta que esté en una. Haz el [paso 3](#step-3-add-it-to-a-plex-account).
- **"This server is not powerful enough to convert video".** Si todos los títulos fallan en todos los dispositivos, mira el log de rex justo después de pulsar Play: `upstream failed` o `502` ahí significan que rex no puede alcanzar tu app, y FFmpeg no lo arreglará. La fila `upstream failed` de [Cuando algo va mal](#when-something-is-wrong) dice qué hacer. Si solo fallan algunos archivos, a menudo solo en un navegador web, el dispositivo no puede reproducirlos tal cual, normalmente por sonido AC3 o DTS. Las apps de Plex en TVs y teléfonos reproducen la mayoría de archivos tal cual. Para reproducir todo en todas partes, configura [Conversión de vídeo](#converting-video-optional).

**Borrar borra en tu app.** Con la cuenta nueva, **Delete** en un título de una app de Plex hace que rex pida a tu app que borre el archivo, como dice [Lo que tu app debe hacer](#what-your-app-must-do). Las cuentas con las que rex está compartido no pueden borrar. Para desactivar el borrado: en app.plex.tv con la cuenta nueva, abre **Settings**, la **Library** del servidor rex, **Show Advanced**, desmarca **Allow media deletion** y guarda.

![Los ajustes de Library del servidor rex con Show Advanced abierto y Allow media deletion resaltado](../assets/rex/32-plex-allow-media-deletion.webp)

Un archivo que tu app elimina va a la papelera de la biblioteca, como en Plex: se queda, no disponible, con su historial de reproducción, y vuelve tal como estaba si tu app lo envía de nuevo. **Empty Trash** en la biblioteca lo elimina para siempre, y **Empty trash automatically after every scan** (Settings, Library), que está desactivado, lo hace por sí solo.

Cada archivo va a **Movies** o **TV Shows** según el `kind` que envíe tu app. Un archivo sin `kind` va según su primera carpeta: `shows` a TV Shows, cualquier otra a Movies.

Para dar a una carpeta sus propias bibliotecas, tu app añade `directories` a su registro, indicando la primera carpeta de las rutas de los archivos y los títulos de las bibliotecas: `{"url": ..., "directories": [{"name": "anime", "shows": "Anime", "movies": "Anime Movies"}]}`, siendo válido un solo título. rex las crea cuando tu app se registra y mueve lo que esa carpeta ya tenga dentro, tal cual: historial de reproducción, Fix Match y ediciones incluidos. Una entrada mal formada se omite y aparece en `ignored` en la respuesta, con el motivo. Renómbralas en una app de Plex como quieras. Si borras una, queda borrada y sus archivos vuelven a Movies o TV Shows, hasta que la añadas otra vez con **Add Library**, cuya lista de carpetas muestra las carpetas de tu app. [Bibliotecas que declara una fuente](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md#libraries-a-source-declares) tiene las reglas.

**Haz copia de seguridad** de `rex.db` en la carpeta de rex (contiene tu biblioteca, el historial de reproducción y el inicio de sesión de tu app, así que mantenlo privado), `claim_state.json` y, una vez que rex-direct le haya dado un nombre a rex, `rex-direct.json` (su clave de certificado):

+++ Linux and macOS
```bash
sudo apt install -y sqlite3    # once, on Linux; macOS has it
mkdir -p ~/rex-backup
sqlite3 ~/rex/rex.db ".backup $HOME/rex-backup/rex.db"
cp ~/rex/*.json ~/rex-backup/
```
+++ Windows
Windows no tiene `sqlite3`, así que detén rex un momento y copia `rex.db` junto con los dos archivos al lado que empiezan igual:

```powershell
Stop-Process -Name rex; Start-Sleep 1
New-Item -ItemType Directory -Force $HOME\rex-backup | Out-Null
Copy-Item $HOME\rex\rex.db*, $HOME\rex\*.json $HOME\rex-backup
Start-ScheduledTask rex
```
+++

En Docker los archivos están en `~/rex/config`, legibles solo por root. Haz la copia desde dentro del contenedor con `docker exec rex sqlite3 /config/rex.db ".backup /config/rex.db.bak"`, y luego `mkdir -p ~/rex-backup && sudo cp ~/rex/config/rex.db.bak ~/rex/config/*.json ~/rex-backup/`.

[Restaurar una copia](#restore-a-backup) las devuelve a su sitio.

Ya está. Las secciones siguientes son opcionales.

## Úsalo fuera de casa (opcional) {#use-it-outside-your-home-optional}

**Qué hace.** Le da a rex una dirección HTTPS a la que pueden acceder las apps de Plex fuera de casa, y se la comunica a plex.tv.

**Por qué importa.** Fuera de casa, app.plex.tv solo se conecta a una dirección HTTPS, y las otras apps de Plex también prefieren una. Un servidor Plex normal puede recurrir al relay de Plex; rex no puede, así que tú eliges cómo se accede a él. Primero hay que [reclamar](#step-3-add-it-to-a-plex-account) rex. Un proxy que da a internet debe bloquear `/rex/`: mira [Mantén el puerto privado](#keep-the-port-private).

**Plex Pass.** Plex Web reproduce fuera de casa sin Plex Pass ni Remote Watch Pass en ninguna de las dos cuentas. Las otras apps de Plex no se han probado fuera de casa.

Elijas la opción que elijas, cada byte que veas fuera de casa sale por la velocidad de **subida** de tu conexión de casa. Como referencia aproximada, una subida de 20 Mbit/s da para un 1080p WEB-DL, no para un remux.

| Tu situación | Usa | Por qué |
|---|---|---|
| Tu router tiene IP pública y puedes abrir un puerto | **[rex-direct](#rex-direct)** (lo más sencillo) | Activado por defecto: un solo puerto abierto. DMM le da a rex un nombre y un certificado, y mantiene el nombre apuntando a tu IP de casa |
| Puedes instalar Tailscale en los dispositivos desde los que ves contenido | **[Tailscale serve](#tailscale-serve)** (lo mejor) | No hay que abrir nada en el router, y funciona detrás de cualquier conexión a internet. El certificado se renueva solo, y nadie fuera de tu tailnet puede acceder a rex |
| Dispositivos sin Tailscale (la tele de un amigo, un hotel), y tu router tiene IP pública | **[Caddy](#caddy)** con tu propio dominio, o con un nombre gratuito `sslip.io` | Conexión directa sin nadie en medio, y un certificado gratuito que se renueva solo. Abres el puerto 443 |
| Tu conexión no tiene IPv4 pública (CGNAT o DS-Lite, habitual en cable, móvil y algunos proveedores de fibra) pero sí tiene IPv6 | **[rex-direct sobre IPv6](#rex-direct-over-ipv6)** | Sin abrir puertos en el router ni alquilar nada: permites el puerto 32400 por IPv6. Los dispositivos desde los que veas también necesitan IPv6, algo que tienen la mayoría de las redes móviles |
| Tu conexión no tiene IP pública, o ves contenido en redes sin IPv6, y dispositivos sin Tailscale | **[Un VPS pequeño](#a-small-vps)** | rex no tiene relay y no lo tendrá. Un VPS de alquiler tiene la IP pública y un túnel lleva todo hasta rex, con todo el ancho de banda del VPS |

No recomendado:

- **Túnel de Cloudflare.** Cada byte pasa por Cloudflare, que además descarta el `Range` de la primera lectura de un archivo, así que cada inicio de reproducción descarga el archivo entero en tu app.
- **Tailscale Funnel, ngrok y otros túneles alojados.** Limitan el ancho de banda o los datos mensuales, que una película consume enseguida. Tailscale Funnel además publica todo rex, incluida la API del feed: cualquiera en internet podría añadir o borrar cosas de tu biblioteca.
- **Abrir el puerto 32400 sin rex-direct ni un certificado propio.** Las apps de Plex recibirían una dirección HTTP sin cifrar, que app.plex.tv rechaza.

### rex-direct

rex-direct es la respuesta de DMM a plex.direct, y viene activado por defecto. En tu router, reenvía el puerto 32400 (TCP) a la máquina donde está rex. Eso es todo, sin necesidad de reiniciar nada.

Una vez reclamado, DMM le da a rex dos nombres: `<hash>.rex-direct.debridmediamanager.com`, que apunta a la IP pública de tu casa, y `lan.<hash>.rex-direct.debridmediamanager.com`, que apunta a la IP de rex en tu red local, y ambos tienen certificado. El primer certificado tarda unos minutos; el log de rex indica que se está emitiendo y luego muestra cada nombre en una línea `rex-direct:`. Un cambio de IP de tu casa y las renovaciones de certificados se detectan solos. Una misma cuenta de Plex puede tener hasta diez nombres de rex-direct. En casa, las apps de Plex, incluida app.plex.tv, pueden usar el nombre `lan.`, que llega a rex directamente por tu red, así que el reenvío de puerto solo hace falta fuera de casa. En app.plex.tv, permite el acceso a dispositivos de tu red local cuando Chrome lo pida; si no, vuelve al nombre público, que sí necesita el reenvío de puerto. [Lo que deberías ver](#what-you-should-see) comprueba ambos nombres.

Si tu router reenvía a rex un puerto externo distinto, añade la clave `REX_DIRECT_PORT=<that port>` como indica el [paso 1](#step-1-install-rex) para tu sistema, y reinicia rex. El reenvío de puerto no abre la API del feed: consulta [Mantén el puerto privado](#keep-the-port-private).

### rex-direct sobre IPv6 {#rex-direct-over-ipv6}

Para una conexión sin IPv4 público (CGNAT o DS-Lite) que sí tiene IPv6. Una vez que DMM se ha conectado a rex por su dirección IPv6 y ha encontrado allí el mismo servidor, apunta también a esa dirección el nombre rex-direct de rex. Necesitas rex nightly 2026.11.08 o posterior y, en Docker, red del host (host networking).

IPv6 no tiene reenvío de puertos ni mapeo de puertos: rex debe usar el mismo puerto por dentro y por fuera, así que deja `REX_DIRECT_PORT` sin definir. En el firewall de tu router, permite las conexiones TCP entrantes al puerto 32400 hacia la máquina de rex por IPv6. rex ofrece su IPv6 un minuto después de arrancar (o de ser reclamado) y luego cada 6 horas, así que añade la regla antes de iniciar rex, o reinicia rex después de añadirla. Un minuto más o menos después, su log muestra ambas direcciones:

```
rex-direct: https://<hash>.rex-direct.debridmediamanager.com:32400 -> <IPv4> and <IPv6>
```

Si no aparece ninguna línea con `and <IPv6>` en unos pocos minutos, DMM no pudo llegar a rex por IPv6: revisa la regla del firewall y que rex en Docker use red del host. En Windows, rex ofrece la dirección IPv6 temporal de Windows, que Windows reemplaza aproximadamente cada día: desactiva las direcciones temporales con `netsh interface ipv6 set privacy state=disabled` en un PowerShell como administrador, y luego reinicia rex para que ofrezca la estable. El `<IPv4>` de esa línea es la dirección compartida de tu proveedor y no llega a rex, así que los dispositivos desde los que veas el contenido también necesitan IPv6. La mayoría de las redes móviles lo tienen; una red de hotel u oficina solo con IPv4 no podrá llegar a rex de esta forma.

### Tailscale serve

Instala [Tailscale](https://tailscale.com/download) en la máquina de rex y en los dispositivos desde los que ves contenido, con la sesión iniciada en la misma cuenta. Luego, en la máquina de rex:

```bash
sudo tailscale serve --bg 32400
```

En Windows, ejecútalo en PowerShell como administrador sin `sudo`. En macOS, usa la [herramienta de línea de comandos](https://tailscale.com/kb/1080/cli) de la app de Tailscale sin `sudo`.

Te muestra la dirección, por ejemplo `https://myhost.tailnet.ts.net`. Dásela a rex añadiendo `:443`: termina el comando de inicio de rex del [paso 1](#step-1-install-rex) con `--announce-url https://myhost.tailnet.ts.net:443` y reinicia rex.

Todos en tu tailnet, incluidas las personas con las que compartas esta máquina, pueden usar la API de feed de rex. Comparte la máquina solo con personas de confianza.

### Caddy

Necesitas reenviar el puerto 443 de tu router a la máquina de rex, y un nombre para la IP de tu casa:

- **Tu propio dominio:** un registro `A`, como `rex.example.com`, que apunte a la IP de tu casa.
- **Sin dominio:** usa `1-2-3-4.sslip.io` con los números de tu IP pública (`curl -s ifconfig.me` la muestra). Si tu IP cambia, actualiza el nombre.

Instala [Caddy](https://caddyserver.com/docs/install) y dale este Caddyfile (`/etc/caddy/Caddyfile` con el paquete de Caddy para Linux; en macOS y Windows, un archivo llamado `Caddyfile` en su propia carpeta, que `caddy run` lee desde esa carpeta):

```
rex.example.com {
	respond /rex/* 403
	reverse_proxy 192.168.1.20:32400
}
```

`respond /rex/* 403` evita que la API de feeds quede expuesta a internet; tu app sigue conectándose a rex directamente. Luego recarga Caddy (`sudo systemctl reload caddy` con el paquete de Linux). En macOS y Windows, inicia `caddy run` en su carpeta y mantenlo en marcha igual que el [paso 1](#step-1-install-rex) mantiene rex; en Windows, además permite el puerto TCP 443 en el firewall, como hace el paso 1 con el 32400. Después termina el comando de inicio de rex con `--announce-url https://rex.example.com:443` y reinicia rex.

### Un VPS pequeño {#a-small-vps}

Para una conexión sin IP pública, o cuando miras en redes sin IPv6, el VPS transporta todo el streaming, en lugar de [rex-direct sobre IPv6](#rex-direct-over-ipv6). rex no tiene relay ni lo tendrá, así que un servidor que alquiles hace de tu router: tiene la IP pública, y un túnel desde la máquina de rex lleva todo hasta rex. Sirve cualquier VPS con IPv4 pública, por unos pocos euros al mes. **Elige uno cuyo tráfico mensual cubra lo que ves fuera de casa:** cada byte pasa por él, y un plan con poco límite de datos se quedará sin cuota.

Necesitas la IP del VPS (`1.2.3.4` más abajo), los puertos 443, 80 y 7000 abiertos en él, y una cadena aleatoria larga para el túnel (`openssl rand -hex 32`).

**En el VPS**, instala [frp](https://github.com/fatedier/frp/releases) (el programa `frps`) y [Caddy](https://caddyserver.com/docs/install). Crea `frps.toml`:

```toml
bindPort = 7000
auth.token = "your-long-random-string"
proxyBindAddr = "127.0.0.1"
```

`proxyBindAddr` mantiene el extremo del túnel en el loopback del VPS, así que internet solo llega a rex a través de Caddy. Crea `/etc/caddy/Caddyfile`, con la IP del VPS como `1-2-3-4.sslip.io` (un nombre gratuito que siempre apunta a esa IP) o con tu propio dominio apuntando a ella:

```
1-2-3-4.sslip.io {
	respond /rex/* 403
	reverse_proxy 127.0.0.1:32400
}
```

`respond /rex/* 403` evita que la API del feed quede expuesta a internet. Inicia `frps -c frps.toml` como servicio y ejecuta `sudo systemctl reload caddy`.

**En la máquina de rex**, instala también frp (el programa `frpc`) y crea `frpc.toml`:

```toml
serverAddr = "1.2.3.4"
serverPort = 7000
auth.token = "your-long-random-string"

[[proxies]]
name = "rex"
type = "tcp"
localIP = "192.168.1.20"
localPort = 32400
remotePort = 32400
```

Ejecútalo como servicio: en Linux, por ejemplo `~/.config/systemd/user/frpc.service` con `ExecStart=%h/frp/frpc -c %h/frp/frpc.toml` y `Restart=always`; en macOS y Windows, inicia `frpc -c frpc.toml` del mismo modo que [paso 1](#step-1-install-rex) inicia rex. Después, añade `--announce-url https://1-2-3-4.sslip.io:443` al final del comando de inicio de rex, añade la clave `REX_DIRECT_URL=off` (detrás de CGNAT, la IPv4 del nombre rex-direct no llega a rex, así que plex.tv no debería listarla) y reinicia rex. Así, app.plex.tv en casa también pasará por el VPS; las demás apps de Plex en casa seguirán conectándose directamente a rex.

### Lo que deberías ver {#what-you-should-see}

```bash
curl -s https://lan.<hash>.rex-direct.debridmediamanager.com:32400/identity
```

muestra una página XML corta con el `machineIdentifier` de rex en un ordenador de casa; `curl` no muestra nada cuando la dirección o su certificado están mal. Usa tu propia dirección: rex la registra al arrancar como `rex-direct: https://lan.<hash>.rex-direct.debridmediamanager.com:32400 -> 192.168.1.20 (LAN)` (con `REX_DIRECT_URL=off` no aparece ninguna). Abre tu dirección externa con `/identity` añadido en el navegador de un teléfono con el Wi-Fi apagado: con rex-direct es la otra línea `rex-direct:` de rex, y con Tailscale serve `https://myhost.tailnet.ts.net`, que el teléfono abre solo con Tailscale encendido. Debe mostrar una página XML corta sin aviso de certificado.

Si el teléfono falla, el puerto no está reenviado (o, [sobre IPv6](#rex-direct-over-ipv6), no se deja entrar), tu conexión está detrás de CGNAT sin IPv6, rex solo se alcanza por IPv6 y la red del teléfono no tiene IPv6, o el certificado de rex-direct todavía se está emitiendo (el log de rex lo dice mientras tanto).

El log de rex nombra las direcciones que anuncia:

```
INFO    heartbeat every 600s for machine ... -> https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

rex imprime esto en cada arranque. Los problemas aparecen luego como `heartbeat failed` o `announced but NOT visible`. Si no, el servidor muestra esas direcciones en plex.tv, y una app de Plex fuera de casa elige la que pueda alcanzar. Si rex registra `waiting for a claim`, haz primero el [paso 3](#step-3-add-it-to-a-plex-account).

## Tu historial de visualización de otro servidor de Plex (opcional) {#your-watch-history-from-another-plex-server-optional}

¿Ya lo viste en otro servidor de Plex? Una vez que tu biblioteca esté en rex, [Trae tu historial de visualización](import-watched.md) copia lo que viste, dónde te quedaste y tus calificaciones con estrellas, para cada persona por separado.

## Convertir vídeo (opcional) {#converting-video-optional}

**Qué hace.** Permite que rex convierta lo que un dispositivo no puede reproducir, igual que hace Plex.

**Por qué importa.** Sin esto, un dispositivo que no puede reproducir un archivo tal como está muestra "This server is not powerful enough to convert video". Los navegadores web son los que más lo sufren, por ejemplo con sonido AC3 o DTS. Cuando todos los títulos fallan en todos los dispositivos, la causa es otra: consulta el [paso 5](#step-5-watch-something).

Instala **jellyfin-ffmpeg** 8, no el `ffmpeg` que ofrece tu sistema: es la versión con la que se mide rex y la única que convierte todos los archivos Dolby Vision, aplica tone mapping a HDR en la gráfica y dibuja los subtítulos allí. Otro FFmpeg convierte vídeo normal, y el log de rex indica qué le falta (el de Ubuntu 22.04 también se desplaza unos segundos al buscar). rex lo encuentra por su cuenta.

+++ Linux
El paquete va en `/usr/lib/jellyfin-ffmpeg`, junto a cualquier otro FFmpeg. La primera línea elige la versión para tu sistema: hay builds para Ubuntu 22.04, 24.04 y 26.04 y Debian 12 y 13, en amd64 o arm64, y en cualquier otro `curl` se detiene con un error.

```bash
DEB=jellyfin-ffmpeg8_8.1.3-1-$(. /etc/os-release; echo "$VERSION_CODENAME")_$(dpkg --print-architecture).deb
curl -fLO "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/$DEB"
sudo apt install -y "./$DEB" && rm "$DEB"
systemctl --user restart rex
```

En otro Linux, descomprime la build portable de jellyfin-ffmpeg en `~/rex/ffmpeg`, donde rex la busca, y reinicia rex. Usa el driver gráfico del propio sistema, así que en un sistema antiguo solo convierte con el procesador; usa el paquete siempre que exista.

```bash
B=$( [ "$(uname -m)" = aarch64 ] && echo linuxarm64 || echo linux64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
```

Con una gráfica Intel o AMD, ejecuta también `sudo usermod -aG render "$USER"` y reinicia para que el servicio obtenga el grupo; en un LXC, pasa la GPU al contenedor. La gráfica hace la conversión rápida; sin ella, rex usa el procesador. Si no hay gráfica Intel ni AMD, rex también intenta el codificador de una tarjeta NVIDIA. En Intel, `sudo apt install intel-opencl-icd` también convierte HDR y Dolby Vision en la gráfica, a casi tiempo real para 4K en un Intel pequeño; sin él, se convierten en el procesador, que un Intel de bajo consumo no puede hacer en tiempo real a 4K.
+++ macOS
La build portable va en `~/rex/ffmpeg`, donde rex la busca:

```bash
B=$( [ "$(uname -m)" = arm64 ] && echo macarm64 || echo mac64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
launchctl kickstart -k gui/$(id -u)/com.rex
```

En un Mac, rex siempre convierte en el procesador: no tiene forma de usar la gráfica de un Mac.
+++ Windows
La build portable va en una carpeta `ffmpeg` dentro de la carpeta de rex, donde rex la busca:

```powershell
cd $HOME\rex
curl.exe -fLO https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Expand-Archive jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip ffmpeg
Remove-Item jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex
```

En Windows, rex convierte con el codificador de una tarjeta NVIDIA cuando la hay, y con el procesador en caso contrario.
+++

**Qué deberías ver.** El log de rex tiene una línea `transcoder:` que indica el FFmpeg y el hardware que encontró (`hardware none` significa procesador); `transcoder off` al arrancar significa que no encontró ninguno. Un archivo que antes fallaba ahora se reproduce; el log muestra qué se convirtió, por ejemplo `video=copy h264 audio=ac3->aac`.

Subtítulos en un archivo convertido: un subtítulo de imagen se quema en la imagen y un subtítulo que subiste se mantiene. Plex para Android e iOS también conserva un subtítulo de texto como pista; las demás apps lo dibujan en la imagen. Las descargas sin conexión convertidas siguen sin incluir subtítulos de texto.

## Subtítulos {#subtitles}

**Qué hace.** La búsqueda de subtítulos en una app de Plex encuentra subtítulos del proveedor propio de Plex una vez que rex está vinculado. rex comprueba el que elijas contra el archivo y corrige su sincronización cuando va retrasado o cuando está hecho para otra tasa de fotogramas. Si tu cuenta de Plex está configurada para mostrar subtítulos y un título no tiene ninguno en tu idioma, rex busca uno durante hasta 3 segundos antes de empezar.

**Por qué importa.** El primer resultado del propio Plex suele estar desincronizado con el archivo.

![El cuadro de diálogo Subtitles search en una app de Plex, mostrando resultados en inglés para Sintel](../assets/rex/51-plex-search-subtitles.webp)

No hay nada que configurar. rex comprueba un subtítulo contra el subtítulo de texto propio del archivo cuando lo tiene. Un archivo sin uno se comprueba contra su audio cuando pulsas play, lo que necesita tener configurado [Converting video](#converting-video-optional) y lee seis fragmentos de 90 segundos del archivo.

**Qué deberías ver.** El log de rex tiene una línea `SUBTITLE measured` por cada subtítulo que comprueba, y `SUBTITLE applied ... corrected by` cuando corrigió uno.

## Capacidades de películas y series {#movie-and-tv-capabilities}

Las descargas, la detección de intro y créditos, las miniaturas de búsqueda y el resto de funciones de servidor Plex que tiene rex, junto con sus ajustes, están en [la guía de configuración de rex](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities). La música y la TV en directo llegan desde fuentes que las envíen ([límites de rex](https://github.com/debridmediamanager/rex#limits)), como [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) para canales en directo. No hay DVR, así que nada se graba. Las fotos solo llegan desde una fuente que envíe imágenes ([API de feed](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md#photos)), como los cómics de zurg. Plex Web las muestra; Plex para Android no muestra ninguna biblioteca de fotos.

Mantén el modo de proxy predeterminado para la reproducción compartida con debrid. Real-Debrid registra la IP pública de cada descargador; usar una misma cuenta desde varias IP acaba con una advertencia de compartición, aunque las descargas funcionen. Las URL de descarga de TorBox contienen la clave de API completa, así que redirigir da acceso a todos los clientes y cuentas de usuario compartidas, incluido el borrado. Lee los [riesgos de la redirección y su configuración](direct-download.md#before-you-start) antes de dejar que las apps descarguen directamente del proveedor.

## Ejecuta rex en Docker {#run-rex-in-docker}

Estos pasos son para una máquina Linux. En macOS y Windows, Docker Desktop ejecuta los contenedores dentro de una máquina virtual, así que host networking, el descubrimiento en la LAN y la gráfica no funcionan igual que en Linux: usa los pasos de arriba en su lugar.

Crea una carpeta, por ejemplo `~/rex`, con este `compose.yml`:

```yaml
services:
  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./config:/config
```

- ¿Gráfica Intel o AMD? Añade `devices: ["/dev/dri:/dev/dri"]` para que rex convierta el vídeo con ella.
- `network_mode: host` permite que las apps de Plex de tu red encuentren rex por sí solas, y que rex alcance tu app en la dirección que registra, como si fuera desde la propia máquina.
- `./config` guarda `rex.db` y, más adelante, `claim_state.json`. Solo root puede leerlos, porque `rex.db` contiene el login de tu app.
- ¿Plex Media Server en la misma máquina? Añade `command: --port 32500` y usa `32500` donde algún comando o ajuste diga `32400`.

```bash
docker compose up -d
docker compose logs -f rex
```

Deberías ver las mismas líneas que en el [paso 1](#step-1-install-rex). Luego haz los pasos 2 a 5 como arriba. Si tu app también corre en un contenedor, debe registrar una dirección que rex pueda alcanzar desde la máquina, no una que solo vean otros contenedores.

Actualiza con `docker compose pull && docker compose up -d`. La imagen incluye jellyfin-ffmpeg, así que [convertir vídeo](#converting-video-optional) solo necesita que le pases la gráfica. HTTPS funciona como arriba: Tailscale, Caddy y frp corren en la propia máquina, y `--announce-url ...` va en el `command:` del archivo compose.

## Mantén el puerto privado {#keep-the-port-private}

rex no pide contraseña en su API de feed. Solo responde a esa API desde esta máquina, desde tu red doméstica (10.x, 172.16-31.x, 192.168.x, 169.254.x y direcciones IPv6 privadas) y desde Tailscale (100.64-127.x). A cualquier otro le responde como si la API no existiera. Por eso, reenviar el puerto de rex en [rex-direct](#rex-direct), o dejarlo entrar por IPv6, no la abre. Un router que da a los visitantes externos su propia dirección hace que parezcan locales, y eso expone el feed a internet. Tu app debe, por tanto, enviar desde una de esas redes. Detrás de un router doméstico, un dispositivo con una dirección IPv6 dentro del rango de tu red doméstica también cuenta, así que un nombre de host que resuelva a la IPv6 de rex funciona en casa. En un VPS, referencia a rex mediante una dirección de una red privada. Un proxy en la máquina de rex parece local para rex, así que mantén `/rex/*` bloqueado en cualquier proxy que dé a internet, como hace el ejemplo de [Caddy](#caddy).

## Actualizar {#updating}

rex nunca se actualiza solo. Vuelve a ejecutar el bloque de descarga del [paso 1](#step-1-install-rex) (reemplaza el programa y `data/`, y deja intactos `rex.db`, tus claves, `claim_state.json` y `rex-direct.json`), y luego reinicia rex como indica el paso 1. En Windows, ejecuta `Stop-Process -Name rex` antes del bloque de descarga, porque Windows no permite reemplazar un `rex.exe` que está en ejecución, y `Start-ScheduledTask rex` después. Si rex sale con `unrecognized arguments`, borra de su comando de inicio los flags que indica el error: rex ya no los tiene.

## Más adelante: restaurar, mover, eliminar {#later-restore-move-remove}

### Restaurar una copia de seguridad {#restore-a-backup}

Detén rex, borra `rex.db` y los archivos `rex.db-wal` y `rex.db-shm` que están junto a él, copia los archivos de tu copia de seguridad a la carpeta de rex e inicia rex. Dejar el `rex.db-wal` antiguo en su sitio deshace la restauración.

+++ Linux
```bash
systemctl --user stop rex
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
systemctl --user start rex
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
launchctl load ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
```powershell
Stop-Process -Name rex; Start-Sleep 1
Remove-Item $HOME\rex\rex.db*
Copy-Item $HOME\rex-backup\* $HOME\rex
Start-ScheduledTask rex
```
+++ Docker
```bash
cd ~/rex && docker compose down
sudo rm -f config/rex.db config/rex.db-wal config/rex.db-shm
sudo cp ~/rex-backup/rex.db.bak config/rex.db && sudo cp ~/rex-backup/*.json config/
docker compose up -d
```
+++

### Mueve rex a otra máquina {#move-rex-to-another-machine}

Haz una copia de seguridad como en el [paso 5](#step-5-watch-something), y luego detén rex en la máquina antigua de forma definitiva, como indica el primer bloque de [Eliminar rex](#remove-rex). En la nueva, sigue el [paso 1](#step-1-install-rex), pero copia los archivos de tu copia de seguridad en la carpeta de rex antes de convertirlo en un servicio. Para tus apps de Plex sigue siendo el mismo servidor, todavía reclamado y compartido. Después:

- Pon en tu app la nueva IP de la LAN, como en el [paso 4](#step-4-connect-your-app).
- Mueve el port forward de tu router a la nueva máquina, o la regla del firewall de IPv6, antes de que rex arranque ahí. El nombre de rex-direct sigue igual y se actualiza solo si cambia la IP pública. Tailscale serve y Caddy se vuelven a configurar en la nueva máquina.

### Mueve rex a otra cuenta de Plex {#move-rex-to-another-plex-account}

Si la cuenta con la que reclamaste rex se pierde o se bloquea, o quieres usar rex en otra cuenta, crea otra cuenta nueva, detén rex, borra `claim_state.json` en la carpeta de rex, inicia rex y repite el [paso 3](#step-3-add-it-to-a-plex-account): reclamar y luego compartir otra vez con todos. Si todavía puedes entrar en la cuenta vieja, quita rex también ahí: en app.plex.tv abre **Settings**, **Authorized Devices**, filtra por **Servers** y elimínalo. Esos dos pasos son todo el proceso para desreclamar. rex no tiene cierre de sesión: la petición de cierre de sesión de Plex (`DELETE /myplex/account`) responde 200 y deja rex reclamado. La biblioteca, Fix Match, las ediciones y el nombre de rex-direct se mantienen, y el historial de reproducción de cada persona vuelve cuando rex se comparte otra vez con su cuenta.

### ¿Qué rex ejecuto? {#which-rex-do-i-run}

rex no tiene un comando de versión. La fecha de la versión nightly está en el nombre de la descarga (`2026.10.30.0040-nightly`), y el archivo del programa tiene la misma fecha: `ls -l ~/rex/rex` (en Windows, `(Get-Item $HOME\rex\rex.exe).LastWriteTime`). La versión de Plex que muestran tus apps no es la de rex: rex informa a propósito la versión actual de Plex Media Server, para que las apps la traten como actualizada, y **Check for Updates** siempre dice que lo está.

### Elimina rex {#remove-rex}

Detén rex para siempre:

+++ Linux
```bash
systemctl --user disable --now rex && rm ~/.config/systemd/user/rex.service
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist && rm ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
En PowerShell como administrador:

```powershell
Unregister-ScheduledTask rex -Confirm:$false; Stop-Process -Name rex
Remove-NetFirewallRule -DisplayName rex, "rex discovery"
```
+++ Docker
```bash
cd ~/rex && docker compose down
```
+++

Luego deja de enviar contenido a rex desde tu app. En app.plex.tv, con la cuenta nueva, abre **Settings**, **Authorized Devices**, filtra por **Servers** y elimina rex. Quita el reenvío de puertos de tu router (o la regla del firewall de IPv6) y borra la carpeta de rex.

### Obtener ayuda {#getting-help}

Pregunta en el foro **rex-support** del [Discord](https://discord.com/invite/7u4YjMThXP) de DMM: [Obtener ayuda](../guides/remote-help.md) explica qué incluir y cómo los patrocinadores reciben ayuda remota.

## Cuando algo va mal {#when-something-is-wrong}

| Lo que ves | Qué hacer |
|---|---|
| `/rex/sources` se queda en `{"size":0}` | Tu app no se ha registrado. Revisa la dirección que le diste y que pueda llegar al puerto de rex |
| Un push responde `404 no such source` | Tu app hizo push antes de registrarse. Debe hacer `PUT /rex/sources/<name>` primero |
| El log de rex dice `held ... no media_info yet` | Tu app envió el archivo sin la salida de ffprobe. Aparece cuando esa salida llega |
| Los títulos muestran nombres de archivo y no hay pósters | rex no está en una cuenta de Plex. Haz el [paso 3](#step-3-add-it-to-a-plex-account). Si rex se reclamó después de que tu app enviara su biblioteca, se nombran solos en cuanto llegue la reclamación |
| Un título está en la serie equivocada, o una película aparece con el nombre de su archivo | Tu app no envió `kind` e `ids` para ese título, o envió los incorrectos. Corrígelo en tu app, o usa **Fix Match** en una app de Plex con sesión en la cuenta nueva; un Fix Match se mantiene como lo configuraste |
| Todos los títulos fallan en todos los dispositivos, a menudo con "This server is not powerful enough to convert video", y el log de rex muestra `upstream failed` o `502` justo después de pulsar Play (con FFmpeg configurado, `TRANSCODE ... exited` con una conexión rechazada o agotada) | rex no puede llegar a tu app en la dirección que registró, y FFmpeg no lo arregla. `curl -s http://192.168.1.20:32400/rex/sources` muestra esa dirección como la `url` de tu app. En la máquina de rex, ejecuta `curl -I` sobre ella: cualquier respuesta HTTP, incluida `401`, está bien; `Failed to connect` significa que rex no puede llegar a tu app ahí. Tu app debe registrar una dirección que funcione desde la máquina de rex: una dirección `172.` es la de un contenedor, a la que rex solo llega desde la misma máquina Linux. Las versiones nuevas lo dicen claramente: rex registra `SOURCES <name>: cannot reach ... from this machine` |
| El log de rex muestra `upstream failed: no source ... configured` | rex no tiene ningún registro de tu app. Haz que se registre de nuevo: reinicia rex |
| El log de rex muestra `part ... is unavailable upstream` | Tu app respondió 404 para ese archivo: ya no lo tiene |
| Nada se reproduce, 401 o 403 | Tu app rechazó su propio inicio de sesión. Haz que se registre de nuevo con el actual |
| Un snapshot responde 409 `would remove more than half` | Es la protección de rex contra una app que envía una biblioteca a medio cargar. Si la eliminación es real, tu app debe enviar todo el snapshot otra vez desde la parte 0, con `"force": true` en su última parte. Reenviar solo la última parte se rechaza, y enviarla como un snapshot nuevo con `force` elimina todo lo que nombraron las partes anteriores |
| Borrar en una app de Plex falla y rex registra `DELETE refused by the source` | Tu app no acepta un `DELETE` del archivo. Elimínalo desde tu app |
| Solo algunos archivos fallan con "This server is not powerful enough to convert video", a menudo solo en un navegador web | El dispositivo no puede reproducir el archivo tal cual. Prueba una app de Plex en una TV o un teléfono, o configura [Convertir vídeo](#converting-video-optional) |
| Un archivo Dolby Vision falla y el log de rex dice `DoVi (Profile 5) color space is not supported` | rex no tiene FFmpeg, o tiene uno que no es jellyfin-ffmpeg. Instala jellyfin-ffmpeg como indica [Convertir vídeo](#converting-video-optional), y deja activado **Enable HDR tone mapping** (Settings, Transcoder) |
| rex se cierra con `cannot bind ...:32400 (another rex or Plex on this port? ...)` | Otro programa ocupa el puerto. Si es Plex Media Server en esta máquina, usa `--port 32500` como indica el [paso 1](#step-1-install-rex). Si es otro rex, como uno que iniciaste a mano, detén ese |
| Un dispositivo en casa no puede conectarse, y la línea `heartbeat ... ->` de rex no muestra `http://192.168.1.20:32400` | rex anuncia la dirección privada de la red por la que llega a internet; detrás de una VPN o de un exit node de Tailscale, esa no es tu red de casa. Añade `--announce-url http://192.168.1.20:32400` al final del comando de inicio de rex ([paso 1](#step-1-install-rex)) y reinicia rex |
| En casa, app.plex.tv no llega a rex, y la dirección `lan.` de [Lo que deberías ver](#what-you-should-see) no responde | Algunos routers y filtros DNS bloquean un nombre público que apunta a una dirección de casa (protección contra DNS rebinding). Permite `rex-direct.debridmediamanager.com` ahí, como los usuarios de Plex permiten `plex.direct` |
| Otra máquina no llega a rex en Windows, aunque existan las reglas de firewall del paso 1 | Si alguna vez hiciste clic en **Cancel** cuando Windows preguntó si permitir rex, Windows guardó una regla que lo bloquea, y esa regla gana a las reglas de puerto. Elimínala en PowerShell como administrador: <code>Get-NetFirewallApplicationFilter -Program "$HOME\rex\rex.exe" &#124; Get-NetFirewallRule &#124; Where-Object Action -eq Block &#124; Remove-NetFirewallRule</code> (si rex está en otro sitio, usa su propia ruta) |
| rex no aparece en las apps de Plex fuera de casa | No está reclamado, o el dispositivo no llega a la dirección HTTPS ([rex-direct sobre IPv6](#rex-direct-over-ipv6) necesita IPv6 en la red de ese dispositivo) |
| rex se cierra con `argument --announce-url: '...' is not an http:// or https:// address` | Pon en `--announce-url` solo la dirección, como `https://myhost.tailnet.ts.net:443`: sin corchetes, comillas ni enlace alrededor |
| rex se detiene al cerrar sesión | En Linux, ejecuta `sudo loginctl enable-linger "$USER"` (paso 1). En macOS y Windows, rex, tal como lo configura el paso 1, se ejecuta mientras tienes la sesión iniciada |
