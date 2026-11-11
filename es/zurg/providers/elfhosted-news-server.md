# Servidor de noticias de ElfHosted {#elfhosted-news-server}

ElfHosted incluye una cuenta de Usenet en sus planes del addon de Stremio y la llama Usenet Essential. Esta página registra qué es ese servidor. Todo lo que aparece abajo se midió el 2026-09-04 desde un único host. La cuenta en sí no se pudo medir, porque la única credencial que ElfHosted publicó alguna vez está caducada, y ese es el primer hallazgo.

## Qué responde por el cable {#what-answers-on-the-wire}

`news.elfhosted.com` resuelve a `94.232.116.124` y habla NNTP sobre TLS 1.3 en el puerto 563, con un certificado de Let's Encrypt para `news.elfhosted.com`. El certificado solo tiene ese nombre y no tiene ningún otro, y se emitió el 2026-08-17. El mismo servidor responde en texto plano por el puerto 119 con el mismo saludo. El saludo es `200 Welcome to elfhosted`.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
AUTHINFO USER
```

Es la misma cadena `nntpswitch2` que informa el [lector de TorBox](torbox-news-server.md). Esta lista es la de la sesión sin autenticar, así que termina en `AUTHINFO USER` y no en `POST`. `HELP` responde sin credenciales y lista el conjunto completo de comandos, incluidos `POST`, `IHAVE`, `XPAT` y `XGTITLE`, así que la ausencia de `POST` se debe a la sesión y no al servidor.

Solo tres comandos funcionan antes de autenticarse, y ninguno más.

| Comando | Respuesta |
|---|---|
| `DATE` | `111 20260903225242` |
| `HELP` | `100 Help follows.` |
| `CAPABILITIES` | `101 Capabilities.` |
| `MODE READER` | `480 Authentication required for command.` |
| `GROUP` and `LIST` and `STAT` and `POST` | `480 Authentication required for command.` |

## Quién lo gestiona {#who-runs-it}

`news.elfhosted.com` está dentro del propio bloque de lectores de Abavia. La página de TorBox tenía que deducir el operador a partir de la adyacencia. Esta no.

`94.232.116.124` está en `94.232.112.0/21`, `AS48345 AS-ABAVIA`, registrada a Abavia S.r.l. de San
Marino. Un barrido inverso de `94.232.116.0/24` devuelve 79 nombres. Cuarenta y cinco de ellos responden por NNTP en el 563
y los cuarenta y cinco informan `nntpswitch2 (local-dev)` con listas de capacidades idénticas byte a byte y en el mismo
orden. Los routers de borde de Abavia están en el mismo /24, y también los alimentadores de XS News, el servidor web y el servidor de nombres.

| Dirección | Lector | Saludo |
|---|---|---|
| `94.232.116.122` | `reader2.newsxs.nl` | `200 Welcome to Newsxs` |
| `94.232.116.124` | `news.elfhosted.com` | `200 Welcome to elfhosted` |
| `94.232.116.125` | `reader.spotnews.nl` | `200 Welcome to Spotnews` |
| `94.232.116.128` | `reader.easyusenet.nl` | `200 Welcome to Easyusenet` |
| `94.232.116.131` | `reader.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.135` | `reader-usenetfarm.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.136` | `reader.torrentclaw.com` | `200 Welcome to TorrentClaw` |
| `94.232.116.140` | `reader.usenet.nl` | `200 Usenet.nl S.r.l.` |
| `94.232.116.147` | `giganews.hostredirects.com` | `200 Welcome to giganews` |
| `94.232.116.150` | `news.usenext.de` | `200 Welcome to Aviteo Ltd DE` |
| `94.232.116.174` | `news.hitnews.com` | `200 Welcome to Hitnews` |

ElfHosted está a cuatro direcciones de Easyusenet, a siete de XS News y a doce de TorrentClaw, que es otro addon de Stremio que funciona como fachada de la misma plataforma.

No hay multiplexación basada en nombres. Conectarse a la dirección con un servername de `reader.xsnews.nl`, o con uno que ni siquiera existe, devuelve el mismo certificado y el mismo saludo `200 Welcome to elfhosted`. Una dirección por marca.

TorBox no está en este bloque. Está en `78.152.55.171`, en `AS3257 GTT` en los Países Bajos. Así que la atribución a ElfHosted es la más sólida de las dos. TorBox ejecuta el mismo software junto a una marca de esta familia. ElfHosted lo ejecuta en el propio espacio de direcciones de Abavia.

**Medido** es la huella del software, la propiedad de las direcciones, el certificado y la ausencia de multiplexación basada en nombres. **Inferido** es que el spool que hay detrás es de Abavia y no una mezcla que ElfHosted haya montado por su cuenta. Nada en el cable distingue una cosa de la otra sin una credencial.

## La credencial publicada ya no funciona {#the-published-credential-is-dead}

| Campo | Como se publicó, 2025-12-20 |
|---|---|
| Host | `news.elfhosted.com` |
| Port | 563 SSL |
| Username | `elfie` |
| Password | `elfie` |
| Connections | 100 |
| Coste | ninguno hasta febrero de 2026 |

El 2025-12-20 ElfHosted anunció acceso NNTP incluido con NzbDav como prueba de concepto de dos meses con un proveedor de infraestructura Usenet sin nombre, y publicó una credencial compartida en el anuncio.

Se configuraba previamente en NzbDav para los usuarios nuevos. El post decía que el acuerdo se revisaría al terminar la prueba de concepto. Y así fue. La credencial ya no autentica.

```
200 Welcome to elfhosted
381 Need more.
482 Invalid username or password
```

En este software, `482 Invalid username or password` es la respuesta de que la credencial está muerta, no el límite de conexiones, que dice `482 too many connections for your user`. Los tiempos también coinciden. Cinco intentos con un usuario que nunca existió y dos con `elfie` son el mismo rechazo en el mismo paquete.

| Intento de conexión | Respuesta | Tiempo |
|---|---|---|
| Usuario aleatorio, cinco intentos | `482 Invalid username or password` | mediana 2066 ms, rango de 2043 a 2070 |
| `elfie` y `elfie`, dos intentos | `482 Invalid username or password` | 2043 ms y 2212 ms |

Aquí, una credencial retirada y un usuario que nunca se emitió no se distinguen, ni en el código ni en los tiempos. Unos dos segundos es lo que tarda este software en decir que no, igual que hace el lector de TorBox.

Así que la cifra de 100 conexiones describe una oferta que ya terminó. Es el único número que ElfHosted ha publicado sobre este servidor, y no se aplica a nada que puedas comprar hoy. Es de suponer que el plan Usenet Essential de pago emite una credencial por cliente, pero eso no se puede comprobar desde fuera.

El mismo anuncio publicó un endpoint Newznab interno en `elfhosted-internal.zyclops` que acepta cualquier API key y se puede filtrar para ver solo los resultados sanos de un backbone concreto. Ese endpoint es lo que quiere decir tienda de ElfHosted cuando afirma que un plan Usenet incluye el indexador. Muestra señales de disponibilidad y salud, no contenido, y ellos mismos lo describen como una bola de cristal para la salud de la infraestructura, no como un mapa del tesoro. Aun así, un plan necesita un indexador real junto a él.

## Lo que no se pudo medir {#what-could-not-be-measured}

Todo lo que decide si vale la pena llenar un slot de proveedor. Todo eso necesita una credencial.

| Propiedad | Estado |
|---|---|
| Límite de conexiones | desconocido, el 100 se aplicó solo a la prueba de concepto retirada |
| Retención | nunca publicada |
| Grupos en `LIST ACTIVE` | necesita autenticación |
| Ventana de números de artículo | necesita autenticación |
| Cobertura frente a otros backbones | necesita autenticación |
| Throughput de una sola conexión | necesita autenticación |
| Publicación | el servidor ofrece `POST`, la cuenta es desconocida |

Una prueba de siete días cuesta un dólar y da la credencial. Ejecutar el mismo barrido de 531 message id que usó la [página de TorBox](torbox-news-server.md#what-it-actually-holds), dentro de esa semana, respondería a cada una de las filas de arriba.

## Lo que ya te dice la plataforma {#what-the-platform-already-tells-you}

Dos datos sí se trasladan desde las mediciones de TorBox, y uno no.

Se trasladan: la semántica de los rechazos y el momento en que ocurren. Es el mismo software, así que da las mismas respuestas. Por tanto, `482 Invalid username or password` también significa una credencial muerta aquí, y el límite es otra cadena.

Se traslada: la ventana de números de artículo. Un lector `nntpswitch2` genera números de artículo sobre una ventana corta, así que cualquier cosa que recorra números en lugar de message ids ve dos semanas de Usenet. Es una propiedad de la plataforma y no de una cuenta concreta. Las lecturas de NZB que usan message ids no se ven afectadas.

No se traslada: la cobertura. El lector de TorBox se midió como un subconjunto estricto de una cuenta de Omicron, con un 71,2 % y cero artículos propios en 531. Eso fue el endpoint de TorBox y no este, y TorBox ni siquiera está en este bloque. Es el precedente más cercano, con el mismo software y el mismo operador, pero no es una medición de ElfHosted. Trátalo como la hipótesis que hay que comprobar, no como la respuesta.

## Cómo configurarlo en zurg {#configuring-it-in-zurg}

Si obtienes una credencial, es una entrada de servidor `type: nzb` normal junto al primario.

```yaml
providers:
  - type: nzb
    nntp:
      host: your-primary.example.com
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 40
      backbone: primary-backbone
      servers:
        - name: elfhosted-news
          host: news.elfhosted.com
          port: 563
          tls: true
          username: YOUR_ELFHOSTED_USERNAME
          password: YOUR_ELFHOSTED_PASSWORD
          connections: 8
          backbone: abavia
          backup: true
```

Empieza con 8 conexiones y súbelas solo después de medir el límite real. El 100 publicado
está retirado, y un pool que abre más allá de un límite desconocido se rechazará a sí mismo durante un arranque en frío. Pon
`backbone: abavia` en lugar de un nombre de marca, porque XS News, Easyusenet, Hitnews, UseNeXT
y este son la misma plataforma, y tratarlos como backbones distintos permitiría que un pool contara
un mismo spool como varios. `backup: true` lo mantiene para los artículos que ya han sido rechazados por todos los primarios.

No apuntes un segundo cliente a una misma credencial. El servidor rechaza al titular más antiguo en lugar de al más nuevo, así que un segundo consumidor le cuesta la conexión al primero.

## ¿Merece la pena ocupar un puesto? {#is-it-worth-a-slot}

No se puede comprar por separado. Viene con un plan de addon de Stremio de nueve dólares al mes, que
también incluye un addon alojado, una instancia de NzbDav y una cuenta de TorBox Essentials. Como una partida
más dentro de ese plan, no te cuesta nada extra, y eso es lo mejor que se puede decir de ella sin
una credencial.

Si ya tienes una cuenta de Omicron y Eweka y Frugal, añadir un cuarto lector de esta plataforma es la misma
apuesta que hizo la página de TorBox y perdió. Esa apuesta no se ha medido aquí, así que es una
suposición previa y no un veredicto. Lo que la resolvería es un dólar, una semana y el
barrido de ids 531.
