# El addon de Stremio {#the-stremio-addon}

zurg puede responder a Stremio como addon. Stremio pregunta por id de IMDb. zurg busca en tus indexadores Newznab y descarga el NZB de la versión elegida al backend de Usenet. Luego lo reproduce y lo repara como cualquier otra versión de zurg.
Todo lo que se reproduce de esta forma también se guarda en la biblioteca y aparece en Plex.

## Configuración {#configuration}

The addon needs an NZB account, `nzb` or
[`torbox_nzb`](../providers/torbox-nzb.md), which is what serves the bytes, and
at least one indexer. With `torbox_nzb`, a release TorBox already holds starts
within the addon's wait when no other NZB post is waiting; an uncached one must
finish on TorBox first, which is longer than a player waits.

```yaml
stremio:
  enabled: true
  # token: ""            # generated and kept in data/stremio-token when empty
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_KEY
    - name: second-indexer
      url: https://second-indexer.example
      api_key: YOUR_KEY
      api_path: /api/v1/api   # for an indexer that 404s the default /api
```

Todo eso está en la página de configuración bajo **Stremio Addon**: el interruptor, la lista de indexadores y el límite de resultados. La URL del addon aparece ahí con un botón de copiar, creada a partir de la dirección que abriste el panel. Esa es la dirección que debes usar: consulta [Instalarlo en otro dispositivo](#installing-it-on-another-device).

Al arrancar, zurg registra la URL del addon:

```
<zurg>/stremio/<token>/manifest.json
```

Pégala en Stremio (Addons → el cuadro de búsqueda acepta una URL). El token de la ruta es toda la autorización: los clientes de Stremio no envían autenticación propia, por eso las rutas quedan fuera de la autenticación básica, igual que los endpoints de SABnzbd. Trata la URL como si fuera una contraseña: los enlaces de reproducción que genera llevan tus api keys de indexadores, y cualquiera que tenga la URL puede gastar tus grabs de indexadores y tus conexiones a servidores de noticias.

## Instalarlo en otro dispositivo {#installing-it-on-another-device}

Stremio solo acepta un addon por `http` plano en el equipo donde corre Stremio. Eso significa `http://127.0.0.1` o `http://localhost` en la máquina de zurg.
En cualquier otro sitio necesita `https`. Una TV, un móvil o un segundo ordenador muestran
**failed to load manifest** con una dirección `http://`, aunque sí puedan llegar a zurg
sin problemas. Esto pasa también con una dirección LAN y con una dirección de Tailscale. La página de configuración
lo indica junto a la URL del addon siempre que la abras por `http` plano en una de esas direcciones.

zurg no sirve `https` por sí mismo. Pon delante algo que sí lo sirva.
Luego abre la página de configuración con la dirección `https` y copia la URL del addon desde ahí.
zurg construye la URL del addon y cada enlace de reproducción a partir de la dirección por la que llegó cada petición.
No hay ningún ajuste de URL pública y `base_url` no se usa aquí.
Un mismo zurg puede atender a un reproductor de la LAN y a otro remoto al mismo tiempo.

Lo que tengas delante tiene que decirle a zurg dos cosas.
El nombre viene de la cabecera `Host` o de `X-Forwarded-Host`.
El esquema viene de `X-Forwarded-Proto: https`.
Sin esa cabecera el addon carga, pero los enlaces de reproducción salen como `http://` y la reproducción falla.
Cada opción de abajo envía las dos.

Stremio usa dos rutas. `/stremio/` es el addon. `/strm/e/` es a donde manda el reproductor el vídeo cuando pulsas play.
Ambas funcionan sin la contraseña de zurg porque Stremio no puede enviarla.
El token de la URL del addon es lo que las protege.
Cuando pongas zurg en internet, publica solo esas dos rutas. Todo lo demás es tu panel y tu biblioteca.

### Tailscale Serve

The simplest option when every device that runs Stremio can run Tailscale. zurg
stays off the internet.

1. En la consola de administración de Tailscale, activa MagicDNS y HTTPS certificates.
2. Ejecuta esto en la máquina de zurg. Usa tu propio puerto si zurg no está en 9999.

   ```bash
   tailscale serve --bg 9999
   ```

   En Windows, ejecuta el mismo comando en PowerShell y, si responde access
   denied, en un PowerShell abierto como administrador. En Linux, pon `sudo` delante a menos que te hayas hecho operador de Tailscale
   (`sudo tailscale set --operator=$USER`). En macOS, si no se encuentra `tailscale`, la copia de la propia app de Tailscale es
   `/Applications/Tailscale.app/Contents/MacOS/Tailscale`.

3. Abre `https://<machine>.<tailnet>.ts.net/config/` y copia la URL del addon de la tarjeta **Stremio Addon**.

Tailscale obtiene el certificado y envía ambas cabeceras. `tailscale serve reset`
lo desactiva de nuevo.

Un dispositivo que no pueda ejecutar Tailscale puede usar Tailscale Funnel en su lugar. Pone la misma dirección en internet. Publica solo lo que Stremio necesita.

```bash
tailscale funnel --bg --set-path /stremio http://127.0.0.1:9999/stremio
tailscale funnel --bg --set-path /strm/e http://127.0.0.1:9999/strm/e
```

La página de configuración no está en esa dirección. Copia la URL del addon desde la página como la abres normalmente y cambia el inicio por `https://<machine>.<tailnet>.ts.net`.
Tailscale limita el ancho de banda que recibe un Funnel. Un remux 4K puede entrecortarse.

### Tu propio reverse proxy {#your-own-reverse-proxy}

¿Ya tienes un reverse proxy con un dominio y un certificado? Añade zurg ahí.
Caddy mantiene la cabecera `Host` y envía `X-Forwarded-Proto` por su cuenta.
Esto publica las dos rutas de Stremio y nada más.

```
zurg.example.com {
    handle /stremio/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle /strm/e/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle {
        respond 404
    }
}
```

nginx no envía ninguna de las dos cabeceras a menos que las pidas las dos.

```nginx
location ~ ^/(stremio|strm/e)/ {
    proxy_pass http://127.0.0.1:9999;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
}
```

Pon eso dentro del bloque `server` que ya escucha en 443 con tu certificado. `proxy_buffering off` deja que el stream de vídeo pase directamente, en lugar de pasar por los buffers de nginx.

### Cloudflare Tunnel

A tunnel con nombre le da a zurg una dirección `https` en un dominio que tengas en Cloudflare, sin abrir ningún puerto. Cloudflare conserva el encabezado `Host` y envía `X-Forwarded-Proto` por su cuenta. Enruta solo las rutas de Stremio en el `config.yml` del tunnel.

```yaml
ingress:
  - hostname: zurg.example.com
    path: ^/(stremio|strm/e)/
    service: http://127.0.0.1:9999
  - service: http_status:404
```

Antes, dos cosas que conviene saber. Cloudflare se rinde con una petición después de 100 segundos. La primera reproducción de un release puede tardar más que eso. Dale a play otra vez y arranca. Además, las condiciones de Cloudflare le permiten limitar cuentas que envían mucho video por su red sin un plan de pago. Cada reproducción pasa por el tunnel.

## Qué hace una reproducción {#what-a-play-does}

Elegir un stream es un grab: zurg descarga el NZB desde el indexador, lo deja en `nzbs/` (usando las mismas reglas de nombres que el endpoint de SABnzbd, así que un release que se ha grabado dos veces —o que ya ha grabado un *arr— se encuentra, no se duplica), espera a que la biblioteca lo liste y redirige el reproductor al endpoint firmado `/strm/e/`, por el que ya reproduce todo archivo `.strm`: lecturas por rangos, failover de cuentas, interiores de RAR/7z.

La primera reproducción de un release tarda más que un stream de debrid: hay que descargar y analizar el NZB, y leer el interior de un archivo comprimido. Normalmente son unos segundos, y hasta uno o dos minutos si se trata de un post ofuscado que necesita pasar por el paso de renombrado. Si una reproducción supera el tiempo de espera, responde 503 con un Retry-After; al pulsar play otra vez se llega al camino rápido. Las siguientes reproducciones son inmediatas.

Un release que aparece en la lista pero resulta no tener nada reproducible —normalmente porque ya ha salido del spool, o porque la comprobación del servidor de noticias ha marcado todos los archivos como rotos— no es el final del clic. La URL de reproducción lleva la petición con la que se generó, así que zurg vuelve a ordenar los releases del título e intenta las filas posteriores a la elegida, cada una por el mismo camino de grab y listado; el primero que se reproduce es al que redirige el reproductor. Recorre toda la respuesta y no solo las filas que mostró la lista: `max_results` es cuánto quiere desplazarse una persona, y si también limitaba la recuperación, un título mostrado diez filas abajo solo podría probar nueve, aunque la búsqueda ya hubiera encontrado más. Las filas *posteriores* a la elegida son a propósito: tienen la misma resolución y un tamaño menor, o la resolución inferior, nunca un release más grande que el usuario haya dejado pasar. Un fallback que todavía se está ingiriendo responde el mismo 503, y al pulsar play otra vez se resuelve: el release rechazado se descarta al instante y el fallback se encuentra por el camino rápido. Solo ese rechazo final pasa al siguiente; un 503 nunca lo hace. Cada intento gasta un grab del indexador y deja su release en la biblioteca como cualquier otro grab, así que la cadena está limitada por un presupuesto de veinticinco segundos y un tope de seis intentos. El presupuesto es el que manda porque los intentos no cuestan lo mismo: un release que ha salido del spool se rechaza en menos de un segundo, mientras que uno que se ingiere y abre un archivo antes de resultar vacío puede consumir casi todo el presupuesto por sí solo. Cuando todas las filas probadas son rechazadas, la respuesta es el 404 de siempre. Cada fallback se registra en el log a nivel info, con el release rechazado y el siguiente que se prueba.

Medido frente a otros tres addons de Stremio con backend en usenet el 7 de septiembre de 2026: stremio-addon-findings-2026-09-07.md. En resumen, el límite por resolución arregló lo que encontró la ronda anterior, pero la cobertura seguía reduciéndose a la mitad, porque un bucket de cinco filas no tiene a dónde ir cuando su primera entrada reproducible es un release que ya salió del spool. El fallback de arriba es la primera corrección de esa ronda; el bucket ha pasado de cinco a diez filas.

## Comportamiento de la búsqueda {#search-behaviour}

- Las búsquedas de películas usan `t=movie`, y las de episodios `t=tvsearch` con `season`/`ep`. Ambas se hacen por `imdbid`, solo con dígitos, porque varios indexadores devuelven cero resultados con la forma `tt`.
- Cada indexador recibe la petición de `search_limit` releases (por defecto 100). Todos los límites de abajo eligen entre lo que se pidió, así que es el techo de la respuesta.
- Los indexadores se buscan en paralelo. Si uno rechaza la petición (un límite de ráfaga, una clave caducada), pierde sus resultados, pero no toda la lista. Los rechazos se registran por indexador.
- Los resultados se deduplican por nombre de release y se ordenan primero por resolución y luego por tamaño. Se limitan a `max_results` (por defecto 10) *por resolución*. El límite cuenta por resolución porque el orden empieza por 2160p: un título popular tiene más releases UHD bajo el techo de tamaño que cualquier límite. Si contáramos en toda la lista, cada título popular se respondería solo con remuxes, sin importar lo que más encontrara la búsqueda.
- Lo que cada resolución conserva es una muestra repartida de sus tamaños, no sus más grandes: selecciones equidistantes desde el release más grande hasta el más pequeño, incluyendo siempre ambos extremos. Si te quedaras con los de arriba, un tier de 1080p de cinco serían cinco remuxes de entre 19 y 30 GB, y el encode de 4 GB que un móvil o un portátil reproduce directamente es justo lo que el límite elimina. Medido el 7 de septiembre de 2026, tres de las quince entradas de zurg para The Shawshank Redemption pesaban menos de 6 GB, frente a cuarenta de esos releases en los mismos indexadores. La lista sigue ordenada de mayor a menor tamaño dentro de cada resolución. Un release cuyo tamaño el indexador no indicó no tiene lugar en ese eje, así que solo ocupa el espacio que dejan los releases con tamaño.
- La descripción de cada stream incluye el nombre del release, su tamaño, el indexador que lo encontró y hace cuánto se publicó (`3d`, `126d`, `2y`), cuando el indexador lo indicó. Que el contenido caducara en el servidor de news fue la causa más común de fallo de reproducción en la ronda del 7 de septiembre, y la fecha de publicación es la única señal con la que el espectador puede evitarlo.
- Los releases más grandes que `max_size_gb` se descartan antes de ordenar, para un reproductor que no puede con un remux. Por defecto no hay límite: la muestra de arriba ya incluye, junto a los remuxes de cada resolución, su release más pequeño. Los tamaños que el indexador no indicó se mantienen. El filtro se aplica al mostrar la lista, así que cambiar el techo también afecta a títulos que ya están en caché.
- Los resultados se guardan en caché en disco (`data/stremio-cache/`, un archivo por título), así que volver a abrir un título no cuesta llamadas a los indexadores. Suelen tener cuota diaria, y Treasure Maps rechaza tras unas seis consultas seguidas. Cuánto dura una respuesta depende de cuántos resultados encontró la búsqueda, porque una lista escasa indica que las subidas siguen llegando o que un indexador estaba caído. Un resultado dura una hora, dos duran dos, hasta cuatro. Cinco o más es una respuesta asentada y dura `cache_hours` (por defecto 24, el único escalón configurable). Una respuesta vacía nunca se guarda en caché. Una lista de streams en caché incluye al final un elemento **refresh** que indica su antigüedad. Al abrirlo (se abre en el navegador, no en el reproductor) se borra la caché de ese título, y al volver a abrirlo se busca de nuevo. La caché sobrevive a los reinicios y las entradas caducadas se limpian solas.
- La temporada 0 (especiales) se rechaza en lugar de buscarse mal. La cobertura de la búsqueda por id depende del indexador: un release que el indexador solo encuentra por búsqueda de texto no aparecerá.
