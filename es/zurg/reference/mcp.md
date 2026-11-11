# El endpoint MCP {#the-mcp-endpoint}

zurg puede responder a un agente de IA a través del [Model Context Protocol](https://modelcontextprotocol.io):
el cliente pregunta qué herramientas existen, zurg las describe y el agente las llama para leer la biblioteca, averiguar por qué una versión no se reproduce, repararla o controlar los servidores de medios. Son las mismas operaciones que muestran el panel y la CLI, pero como herramientas tipadas con esquemas en lugar de HTML y redirecciones 303.

El endpoint viene desactivado por defecto. Está protegido con la misma autenticación básica que el panel, y zurg se niega a servirlo si no hay ningún nombre de usuario configurado. Con uno vacío, todas las rutas del servidor son públicas, y estas herramientas borran versiones.

## Configuración {#configuration}

```yaml
mcp:
  enabled: true
```

Eso es todo para una instalación normal. El resto tiene valores por defecto que conviene conocer:

```yaml
mcp:
  enabled: true
  toolsets: [library, releases, repair]   # the default; see below
  read_only: false                        # withhold every tool that changes anything
  allow_unauthenticated: false            # serve /mcp with no username set
  allow_lifecycle: false                  # admit the tools that stop zurg or its mount
  page_limit: 50                          # items a listing returns by default; 500 is the cap
  max_result_kb: 256                      # ceiling on one result; a page over it is trimmed
  session_timeout_mins: 30                # -1 keeps sessions for the life of the process
```

Igual que los otros bloques de funciones, esto se lee una sola vez al iniciar: si lo cambias, hay que reiniciar.

## Conexión {#connecting}

### Por HTTP {#over-http}

El endpoint es `/mcp` en el puerto habitual de zurg, usando Streamable HTTP. Apunta un cliente a `http://<host>:9999/mcp` con las credenciales del panel.

```bash
npx @modelcontextprotocol/inspector
# Transport:  Streamable HTTP
# URL:        http://localhost:9999/mcp
# Header:     Authorization: Basic <base64 of user:password>
```

### Por stdio {#over-stdio}

Los clientes que solo hablan stdio usan el subcomando `zurg mcp`, que se conecta a una instancia de zurg que ya esté en ejecución:

```json
{
  "mcpServers": {
    "zurg": {
      "command": "/path/to/zurg",
      "args": ["mcp"],
      "cwd": "/path/to/your/zurg/directory"
    }
  }
}
```

El `cwd` importa: todas las rutas de zurg se resuelven desde el directorio de trabajo, y ahí es donde `zurg mcp` lee `config.yml` para obtener el puerto y las credenciales. Con eso no necesita argumentos. `--username` y `--password` reemplazan las credenciales locales. Un `--url` personalizado nunca hereda las credenciales del config local. Si ese endpoint las necesita, pásalas tú con ambos flags, así una contraseña local no se envía a otro host por accidente.

No arranca una segunda instancia. Una segunda zurg cargaría toda la biblioteca, usaría otro conjunto de slots de proveedor en cuentas que los cobran por uso y pelearía con la primera por el montaje. Por eso el comando es solo un pipe hacia el daemon, y no sirve nada si el daemon no está levantado. Sus diagnósticos van a stderr, porque stdout lleva el protocolo.

Una limitación: una notificación que el servidor lance fuera de cualquier llamada no cruza el bridge. El progreso y las líneas de log lanzadas *durante* una llamada viajan en la respuesta de esa misma llamada y llegan sin problema, y eso cubre todo lo que envía zurg.

## Conjuntos de herramientas {#toolsets}

Lo completo de zurg tiene unas cuantas cientos de herramientas, y eso es más de lo que un cliente maneja bien. Pasadas unas ochenta, un modelo elige la herramienta equivocada con más frecuencia, y solo los esquemas cuestan decenas de miles de tokens. Por eso `toolsets` selecciona grupos, y el valor por defecto es un subconjunto que funciona, no todo.

| Toolset | En el valor por defecto | Qué cubre |
|---|:-:|---|
| `library` | sí | Búsqueda, listados de directorios, recuentos de etiquetas |
| `releases` | sí | Un release en detalle: archivos, copias por cuenta, qué puede servir cada archivo |
| `repair` | sí | Qué está roto, si la reparación llegará a ello, forzar una reparación |
| `releases_write` | | Borrar, renombrar, etiquetar, forzar la visualización y escribir archivos `.strm` |
| `magic` | | El espacio de nombres `__magic__`: la disposición guardada, sus filas y mover cosas de sitio |
| `plex` | | Plex, Jellyfin y Emby: estado, emparejamiento y escaneo protegido |
| `providers` | | Las cuentas configuradas: qué puede hacer cada una, si responde y cuánto ha gastado |
| `usenet` | | El backend de NZB: cuentas de noticias, sondeos de artículos, daños y la caché de artículos |
| `clients` | | Los endpoints de SABnzbd, qBittorrent y Stremio con los que hablan Sonarr y Radarr |
| `diagnostics` | | El log, los contadores de bytes, la memoria y las goroutines |
| `config` | | Leer la configuración, detectar desviaciones y escribir un conjunto seleccionado de claves |
| `mount` | | El montaje de rclone: estado, olvidar listados en caché y reiniciarlo |
| `system` | | Datos de la compilación, `doctor`, el servicio, copias de seguridad y actualizaciones |

`toolsets: [all]` activa todos los grupos. Un nombre con el prefijo `-` resta, así que `[all, -config, -system]` es la superficie completa sin los dos que cambian la máquina y no la biblioteca. Un nombre no reconocido muestra un aviso al arrancar y se ignora: un error de escritura no debe quitarle el endpoint.

Las herramientas que detienen zurg, controlan su servicio o reinician el montaje no forman un grupo propio. Viven en `system` y `mount`, y siguen ocultas hasta que se active `allow_lifecycle`, pase lo que pase con `toolsets`.

Un grupo pequeño `server` —qué es esta compilación y si la biblioteca ha terminado de cargar— siempre está registrado, pase lo que pase con `toolsets`. Ocultarlo dejaría a un cliente sin forma de saber que todas las demás respuestas están actualmente incompletas.

## Lo que no hará sin que se lo pidas {#what-it-will-not-do-without-being-asked}

**Confirmación.** Una herramienta que quita algo describe lo que haría
y devuelve un token; solo actúa cuando se la vuelve a llamar con ese token. El
token se deriva del plan, así que una confirmación no puede aplicarse a otro
plan distinto: si la biblioteca cambió entre medias, la segunda llamada vuelve
a describir en lugar de hacer el cambio. Los tokens son de un solo uso, duran
dos minutos y no sobreviven a un reinicio.

**`read_only`.** Un único interruptor que oculta todas las herramientas que
cambian algo, sin importar lo que diga `toolsets`. La pregunta que realmente
se hace un operador es "¿puede esto romper mi biblioteca?", no "¿cuál de estas
herramientas escribe?". Esas herramientas se omiten de `tools/list`, así que
un cliente no puede elegir una capacidad que este endpoint nunca va a permitir.
La comprobación en el momento de la llamada se mantiene como defensa en
profundidad, por si la configuración activa cambia después de crear el servidor.

**`allow_lifecycle`.** Las herramientas que detienen zurg, controlan su
servicio o reinician el montaje se ocultan de la misma forma, detrás de un
interruptor aparte. Cada una puede hacer que toda la biblioteca desaparezca de
golpe, y las acciones de proceso/servicio no pueden informar de su propio
resultado porque pueden terminar el proceso que está respondiendo la llamada.

**Secretos.** Ningún resultado de herramienta incluye un token de proveedor,
una clave de API, una contraseña de servidor de noticias, un enlace de CDN ya
resuelto ni una URL firmada de `.strm`. La salida de los logs se censura al
salir. Un enlace resuelto puede canjearlo cualquiera que lo tenga contra la
cuenta que lo generó, y una transcripción no es un buen sitio para guardarlo.

**Tamaño.** Cada listado tiene dos límites: uno de página y otro de tamaño
máximo del resultado serializado. Una cuenta medida con esto tiene 84.000
releases, unos doce megabytes solo en nombres antes de listar un solo archivo.
Un resultado que supere el límite se recorta y se indica que ha sido recortado.

## Notas {#notes}

El endpoint hereda la autenticación básica del panel al estar registrado dentro de él.
Una solicitud de origen cruzado se rechaza: `/mcp` es para un agente local, no para una página web.
Un reverse proxy delante de zurg funciona: la comprobación de DNS-rebinding de la librería del protocolo
rechazaría un proxy que reenvía su propio `Host` mientras se conecta a `127.0.0.1`, así que zurg desactiva
esa comprobación y deja el control de acceso en manos de la autenticación básica.

`zurg mcp --help` muestra las opciones del puente. `zurg doctor` comprueba si el
endpoint responde.
