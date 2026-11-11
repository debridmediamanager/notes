# Las apps descargan desde tu proveedor {#apps-download-from-your-provider}

Normalmente rex lee cada película de tu fuente y la pasa a Plex. Si la fuente devuelve un enlace de archivo, como
un enlace de descarga de debrid, rex puede entregárselo a Plex. Plex entonces descarga el archivo y la máquina de rex no transporta ningún medio.

Funciona cuando Plex puede reproducir el archivo directamente. Cualquier cosa que rex deba convertir sigue pasando por rex o se rechaza si lo eliges así.

Probado el 2026-10-25 con zurg en Real-Debrid, Plezy y Plex para Android en un Pixel 6, y Plex Web en Chrome.

## Antes de empezar {#before-you-start}

**Mantén el modo proxy predeterminado para la reproducción compartida de debrid.** Las redirecciones no son una forma segura de compartir una cuenta de debrid:

- **Real-Debrid registra la IP pública de cada descargador.** Usar una misma cuenta desde varias IP provoca una advertencia por compartir la cuenta, incluso cuando el CDN sirve el archivo sin problemas. Mantén todo el uso de esa cuenta en una sola IP pública. Si una app remota descarga directamente mientras rex o su fuente sondea o convierte desde la IP del servidor, se incumple esa regla; que una reproducción salga bien no demuestra que sea seguro.
- **Las URL de descarga de TorBox contienen la clave API completa en `?token=`.** Redirigir da a cada cliente y a cada cuenta de usuario compartida acceso a todo, incluida la eliminación, no solo a ese archivo. Los registros del reproductor y el historial del navegador pueden guardar la clave. No entregues estos enlaces a clientes no confiables.

Continúa solo si estos riesgos te parecen aceptables. Mantener el modo proxy predeterminado de rex significa que rex sigue las redirecciones de la fuente por sí mismo, en lugar de pasarle el enlace del proveedor a la app.

| Necesitas | Por qué |
|---|---|
| rex configurado como en [rex con tu propia app](any-source.md), [rex con tus addons de Stremio](stremio.md) o [rex con zurg](with-zurg.md), y una película que se reproduzca | Esta página cambia el comando de inicio de rex y, en algunas fuentes, una de las configuraciones de la fuente |
| rex nightly **2026.10.26 o posterior** | Las versiones anteriores no tienen esta configuración. Actualiza como en la sección [Actualización de rex](any-source.md#updating) |
| Una fuente que pueda responder con un enlace | rex solo puede pasar un enlace que la fuente le entregue. [Paso 1](#step-1-let-your-source-hand-out-links) indica qué fuentes lo hacen |

## Elige qué tan estricto {#choose-how-strict}

| | `redirect` | `redirect-only` |
|---|---|---|
| Una app reproduce el archivo tal cual está | La app descarga desde tu proveedor | La app descarga desde tu proveedor |
| Una app necesita que el archivo se convierta (menor calidad, audio que no puede reproducir, subtítulos incrustados) | rex lo convierte, leyendo el archivo desde tu fuente como antes | Rechazado: la app muestra un error |
| Archivos que tu fuente envía por sí misma, no como enlace (los archivos Usenet de zurg, por ejemplo) | Se reproduce a través de rex como antes | Rechazado |
| Plex Web | Se reproduce, a través de rex | Se rechaza cada archivo de Real-Debrid (más abajo) |

Elige `redirect` si quieres que todo siga reproduciéndose y ahorrar lo que puedas. Elige `redirect-only` si la máquina de rex nunca debe transportar una película, por ejemplo un VPS pequeño con límite de datos.

Elijas la opción que elijas, cada app y cada persona con la que compartas rex recibe el enlace que tu fuente le dio a rex para lo que reproduzcan, y el servicio detrás de ese enlace, tu servicio debrid por ejemplo, ve que cada uno de ellos lo descarga.

## Paso 1. Deja que tu fuente entregue los enlaces {#step-1-let-your-source-hand-out-links}

**Qué hace.** Tu fuente responde a cada lectura con un enlace al archivo en otro lugar (una redirección HTTP) en lugar del archivo en sí.

**Por qué importa.** rex solo puede pasar un enlace que su fuente le dé. Una fuente que envía el archivo en sí seguirá enviándolo a través de rex.

| Fuente | Qué hacer |
|---|---|
| [rex-stremio](stremio.md) | Nada: responde con el enlace que le dio un addon de streams. Un enlace que necesita sus propios headers, y una playlist en vivo, aún los envía él mismo |
| [zurg](with-zurg.md) | Activa `disable_stream_proxy`, más abajo. zurg no tiene enlace para un archivo de Usenet, así que siempre envía esos él mismo |
| [Tu propia app](any-source.md) | Responde al `GET` del archivo con un `302` o `307` hacia el enlace |

### zurg

El ajuste es de zurg, así que cualquier otra cosa que lea zurg (rclone, un servidor Plex o Jellyfin sobre el montaje de zurg) también recibe los enlaces; la [referencia de configuración de zurg](../zurg/reference/config.md) tiene los detalles.

+++ Linux y macOS
Mira si el ajuste ya está en la configuración de zurg:

```bash
grep -n '^disable_stream_proxy:' ~/zurg/config.yml
```

Si imprime una línea, cámbiala a `disable_stream_proxy: true` con `nano ~/zurg/config.yml`. Si no imprime nada, añádela:

```bash
printf '\ndisable_stream_proxy: true\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
Abre la configuración de zurg con `notepad $HOME\zurg\config.yml`. Si tiene una línea `disable_stream_proxy:`, cámbiala a `disable_stream_proxy: true`; si no, añade esa línea al final. Guárdalo y reinicia zurg:

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++ Docker
En la carpeta de zurg:

```bash
sudo grep -n '^disable_stream_proxy:' config.yml
```

Si imprime una línea, cámbiala con `sudo nano config.yml`. Si no:

```bash
printf '\ndisable_stream_proxy: true\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```
+++

**Qué deberías ver.** zurg vuelve a arrancar como de costumbre. Las películas siguen reproduciéndose a través de rex en este punto: rex sigue los enlaces por su cuenta hasta el paso 2.

## Paso 2. Deja que rex pase los enlaces {#step-2-let-rex-pass-the-links-on}

**Qué hace.** rex le pasa a la app el enlace que le dio tu fuente, en lugar de descargar la película por ella.

Añade `--part-mode redirect` (o `--part-mode redirect-only`) al final del comando de inicio de rex, luego reinicia rex y abre su log. [Instalar rex](any-source.md#step-1-install-rex) te muestra dónde está el comando de inicio en tu sistema y cómo reiniciar rex y ver su log. En Linux, la línea `ExecStart` de `~/.config/systemd/user/rex.service` quedará así, sin nada más en la línea:

```ini
ExecStart=%h/rex/rex --part-mode redirect
```

Mantén lo que ya haya en la línea, como `--port 32500` o `--announce-url ...`.

**Qué deberías ver.** La línea de inicio termina en `parts=redirect`:

```
INFO    rex on http://192.168.1.20:32400  machine=...  items=...  parts=redirect
```

Con `redirect-only` termina en `parts=redirect-only`, y unas líneas más arriba rex dice `transcoder off: --part-mode redirect-only`.

## Paso 3. Reproduce algo {#step-3-play-something}

Deja abierto el log de rex y reproduce una película en Plezy o en Plex para Android.

**Qué deberías ver.** Por cada lectura que hace la app, aparece una línea con el nombre del servidor de tu proveedor:

```
INFO    PART 1000010 range=bytes=0- -> 302 to 129-4.download.real-debrid.com
```

Eso es rex enviando la app al servidor del enlace, en este caso el de Real-Debrid. Si en cambio aparece una línea que termina en `-> 206 len=...`, significa que rex envió la película directamente: consulta [Si no funciona](#if-it-does-not-work).

## Qué hace cada app {#what-each-app-does}

| App | `redirect` | `redirect-only` |
|---|---|---|
| Plezy | Descargas desde tu proveedor | Descargas desde tu proveedor |
| Plex para Android, calidad original | Descargas desde tu proveedor, cuando rex le permite reproducir el archivo tal cual | Lo mismo |
| Plex para Android, una calidad inferior, o audio que no puede reproducir | rex lo convierte | "Playback Error: This item can't be played right now. Please try again." |
| Plex Web | Reproduce a través de rex | "Playback Error: This server is not powerful enough to convert video." |

Plex Web no puede usar los enlaces de Real-Debrid en absoluto: Real-Debrid marca sus archivos como descargas, no como vídeo, y el navegador se niega a reproducirlos. Con `redirect`, Plex Web pasa sin hacer ruido a una conversión a través de rex en menos de un segundo, así que sigue funcionando; con `redirect-only` no hay a qué recurrir.

## En Docker {#in-docker}

Si seguiste [rex en Docker](any-source.md#run-rex-in-docker), el paso 2 es una línea `command:` debajo de `rex:` en el `compose.yml` de rex, junto a `image:`:

```yaml
    command: --part-mode redirect
```

¿Ya tienes `command: --port 32500`? Cámbialo a `command: --port 32500 --part-mode redirect`. Luego ejecuta `docker compose up -d` en la carpeta de rex, y `docker compose logs -f rex` muestra la misma línea `parts=redirect`.

## Si no funciona {#if-it-does-not-work}

| Lo que ves | Qué significa |
|---|---|
| rex sale con `invalid choice` para `--part-mode` | rex es anterior a 2026.10.26. Actualízalo como en [la sección Updating de rex](any-source.md#updating) |
| El log de rex dice `-> 206 len=...` en cada lectura | La fuente sigue enviando el archivo en sí. Con zurg: falta `disable_stream_proxy: true` en la configuración de zurg, o no se reinició zurg después del paso 1 |
| `-> 206 len=...` solo en algunos títulos | La fuente envía esos archivos ella misma: los archivos Usenet de zurg, o los enlaces de rex-stremio que tiene que retransmitir |
| `-> 403: the source answered with the bytes, not a link` | `redirect-only` rechaza un archivo que la fuente envió directamente, por las mismas razones de arriba |
| No aparece ninguna línea `PART` mientras se reproduce una película | La app está reproduciendo una conversión, no el archivo original. Pon su calidad en Original |

¿Sigues atascado? Pregunta en el foro **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) explica qué incluir.

## Volver atrás {#going-back}

Quita `--part-mode ...` del comando de inicio de rex (o de la línea `command:` en Docker) y reinicia rex. Tu fuente puede seguir entregando enlaces: al quitar el ajuste de rex, rex los sigue por su cuenta. Con zurg, vuelve a poner `disable_stream_proxy` en `false` y reinicia zurg para que vuelva a pasar los archivos él mismo, tanto para rclone como para cualquier otro que los lea.
