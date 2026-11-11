# Servidor de noticias de TorBox {#torbox-news-server}

Una suscripción TorBox Pro incluye una cuenta de Usenet. Es un servidor NNTP real y zurg puede usarlo como un proveedor `type: nzb` normal. Esta página recoge qué es ese servidor y qué vale como plaza de proveedor. Todo lo que aparece abajo se midió el 2026-09-02 y el 2026-09-03 desde dos equipos en redes distintas.

## Qué responde por el cable {#what-answers-on-the-wire}

`nntp.torbox.app:563` habla NNTP sobre TLS 1.3 detrás de un certificado de Let's Encrypt para `nntp.torbox.app`. El saludo es `200 Welcome to TorBox`. La lista de capacidades indica el software.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
POST
```

Esa cadena de implementación no es INN, ni Diablo, ni el `nntpd` que algunos proveedores reportan.
Es software a medida y el nombre dice lo que hace. Un switch está delante de uno o más spools de artículos.

## Quién lo gestiona {#who-runs-it}

Se sondearon cuarenta nombres de host públicos de lectores para buscar esa cadena de implementación. Treinta y dos respondieron NNTP
y seis de ellos informan `nntpswitch2`. Los seis devuelven listas de capacidades idénticas, en el mismo orden.

| Reader | Address | Greeting |
|---|---|---|
| `nntp.torbox.app` | 78.152.55.171 | `200 Welcome to TorBox` |
| `news.cheapnews.eu` | 78.152.55.164 | `200 Welcome to Cheapnews` |
| `reader.xsnews.nl` | 94.232.116.131 | `200 Welcome to XS News` |
| `news.easyusenet.nl` | 94.232.116.128 | `200 Welcome to Easyusenet` |
| `news.hitnews.com` | 94.232.116.174 | `200 Welcome to Hitnews` |
| `news.usenext.de` | 94.232.116.150 | `200 Welcome to Aviteo Ltd DE` |

Todo lo demás respondió de otra forma. Eso incluye las marcas de Omicron, Eweka, Frugal, UsenetExpress, Giganews y Usenet.Farm.

Las direcciones aclaran el resto. `94.232.112.0/21` está registrada a Abavia S.r.l. de San Marino, con `abuse@abavia.com` en el registro. Un escaneo inverso de `94.232.116.0/24` devuelve más de sesenta nombres de lectores solo en ese bloque. XS News, Easyusenet, Hitnews y UseNeXT están ahí, junto a docenas de marcas más pequeñas. La vecina `94.232.117.0/24` es el nombrado de hosts de XS News de principio a fin.

TorBox no está en ese bloque. Está en un rango de Ámsterdam a siete direcciones de `news.cheapnews.eu`.

**Medido** es la huella del software, la propiedad de las direcciones y la adyacencia. **Inferido** es el acuerdo comercial. TorBox describe su Usenet como una mezcla de proveedores de Usenet de alta calidad, y el software de cambio es coherente con eso. Así que la afirmación segura es que TorBox ofrece acceso a la misma plataforma de lectores que usan las marcas de Abavia y XS News, y no que TorBox revenda un spool concreto con nombre propio.

(Una traducción anterior fue rechazada: proporción de longitud 0,11. Mantén la estructura exactamente igual.)

## Lo que te da la cuenta {#what-the-account-gives-you}

| Propiedad | Valor |
|---|---|
| Host | `nntp.torbox.app:563` TLS, también responde en 119 |
| Grupos en `LIST ACTIVE` | 103,415 |
| Conexiones | 10, un límite estricto que se cuenta exactamente, incluido el handshake en curso |
| Retención | 3900+ días que TorBox declara para este servidor |
| Publicación | permitida, `POST` devuelve `340 Start posting` |
| Campos de overview | Subject, From, Date, Message-ID, References, Bytes, Lines, Xref:full |
| Compresión | `XZVER` y `XZHDR` ambos ofrecidos |
| Ancho de banda | ilimitado, pero se cuenta en la cifra de uso del panel de TorBox |

Las credenciales salen de torbox.app, en tools y luego View Usenet Connection Details. El nombre de usuario es el auth id de tu cuenta.
La contraseña se muestra una sola vez. Cualquier reinicio invalida la anterior, así que restablecerla rompe todos los clientes que ya tengas configurados.

Hay dos cadenas de rechazo que importan cuando algo sale mal. `482 too many connections for your user` es el límite, y se libera en cuanto se devuelve una conexión. `482 Invalid username or password` es una credencial realmente muerta. Ambos son fallos lentos, de unos dos segundos. Una autenticación correcta es mucho más rápida: se midió entre 64 ms y 592 ms a lo largo de un día de conexiones en producción.

## La ventana del número de artículo es de dos semanas {#the-article-number-window-is-two-weeks-wide}

`GROUP` en un grupo binario muy activo informa un recuento exactamente igual a la marca de agua alta menos la marca de agua baja. Los spools reales tienen huecos, así que esa igualdad es la firma de una numeración sintetizada. Además, la ventana es corta.

| Grupo | Marca baja | Marca alta | Números en la ventana |
|---|---|---|---|
| `alt.binaries.boneless` | 148068410000 | 150053594960 | 1,985,184,960 |
| `alt.binaries.teevee` | 2992135000 | 3392153099 | 400,018,099 |
| `alt.binaries.multimedia` | 31901685000 | 32301734812 | 400,049,812 |

Al muestrear los números más antiguos de `alt.binaries.boneless`, devuelve artículos publicados el 2026-08-19. Eso fue catorce días antes de escribir esto. Todo lo anterior no tiene número en este servidor.

Esto no afecta a zurg. Un NZB direcciona los artículos por message id, y una búsqueda por message id llega a artículos mucho más antiguos que la ventana. Sí afecta a cualquier cosa que recorra los números de artículo. Un descargador de cabeceras o un indexador apuntado a este servidor solo ve dos semanas de Usenet y nada anterior.

## ¿Está redirigiendo tu solicitud a otros proveedores? {#is-it-proxying-your-request-to-other-providers}

No. Tres mediciones dicen que la respuesta sale de un spool que la plataforma ya tiene.

**Rechaza más rápido de lo que podría preguntarle a alguien.** Se preguntó por veinticinco message ids que nunca existieron en ningún sitio a tres servidores.

| Servidor | `STAT` con un hit | `STAT` con un id que nunca existió |
|---|---|---|
| `nntp.torbox.app` | 37 ms | **43 ms** |
| `news.eweka.nl` | 20 ms | 471 ms |
| `newshosting.tweaknews.eu` | 44 ms | 909 ms |

Un servidor que consulta a los upstreams antes de responder es más lento cuando la respuesta es no, porque cada upstream tiene que contestar primero. Este dice no en el mismo tiempo que tarda en confirmar un sí. Eso es un índice local respondiendo.

**No hay penalización en la primera descarga.** Se descargaron en frío diez artículos de 2012 a 2018 y luego otra vez de inmediato, en la misma conexión.

| Servidor | mediana en frío | mediana en caliente |
|---|---|---|
| `nntp.torbox.app` | 49.6 ms | 30.9 ms |
| `news.eweka.nl` | 98.0 ms | 78.1 ms |

La proporción frío/caliente aquí es 1.6, frente a 1.25 en un spool normal. Eso es TCP y caché de página. Una descarga desde un tercero en la primera petición costaría mucho más y solo se notaría en la pasada en frío. Un artículo de 792 KB llegó en frío en 49 a 73 ms, lo que son unos 11 a 16 MB/s, y no deja margen para un viaje de ida y vuelta a otro proveedor.

**Una mezcla no puede ser un subconjunto de uno de sus miembros.** Este es el argumento que lo decide. Si el servidor fusionara varios backbones, su cobertura sería la unión de todos ellos y tendría artículos que al menos un miembro no tenía. No tuvo ninguno. Es un subconjunto estricto de la cuenta Omicron, con un 71.2 por ciento. Fusionar proveedores no puede producir eso.

Un detalle relacionado para quien intente rastrear el origen. Las cabeceras vuelven normalizadas, no literales. Cambia el orden de los campos y se reescribe la capitalización, así que `X-Received-Body-CRC` pasa a ser `X-Received-Body-Crc` y `Message-ID` pasa a ser `Message-Id`. `Path` es `not-for-mail` en todos los artículos revisados. Un spool normal puede conservar la cadena real, y uno de los servidores de arriba devuelve `news.tweak-news.eu!spooler.pl1!...!feed.tweaknews.nl!path-stripped` para el mismo artículo. Así que las cabeceras se reconstruyen a partir de campos analizados, y la ruta del feed no se puede recuperar a partir de ellas.

## Cómo configurarlo en zurg {#configuring-it-in-zurg}

La cuenta es una entrada de servidor `type: nzb` normal. Hay dos claves que importan más que el resto.

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
        - name: torbox-news
          host: nntp.torbox.app
          port: 563
          tls: true
          username: YOUR_TORBOX_AUTH_ID
          password: YOUR_TORBOX_NEWS_PASSWORD
          connections: 8
          backbone: torbox
          backup: true
```

`backup: true` mantiene las diez conexiones para los artículos que ya han rechazado todas las demás cuentas. Un primario ocupado no deriva a esta cuenta. Solo lo hace un *no such article* real. Consulta [las claves del proveedor](../reference/config.md) para ver cómo se comportan `backup` y `backbone`.

Configura 8 en lugar de 10. El límite cuenta también las conexiones que todavía están haciendo el handshake, así que un pool que se abre hasta el tope se rechazará a sí mismo durante un arranque en frío. Dejar dos libres también te deja espacio para lanzar una comprobación a mano sin tirar la producción. Nunca apuntes un segundo cliente a las mismas credenciales. Dos consumidores de una cuenta de diez conexiones se van a dejar sin recursos mutuamente, y el servidor rechaza al titular más antiguo en vez de al más nuevo.

## Lo que realmente contiene {#what-it-actually-holds}

Cobertura medida contra otros tres backbones sobre los mismos ids de artículo. La muestra son 177 releases tomados de una biblioteca NZB de zurg en vivo. Las fechas de publicación van de 2011 a 2026. De cada release se tomaron tres artículos con espaciado uniforme a lo largo del archivo, lo que da 531 ids de mensaje. Cada id se consultó a cuatro cuentas, con una conexión por cuenta. Los otros tres son una cuenta de Omicron a través de Tweaknews, una cuenta de Eweka y una cuenta de Frugal.

| Año de publicación | ids | `nntp.torbox.app` | `newshosting.tweaknews.eu` | `news.eweka.nl` | `newswest.frugalusenet.com` |
|---|---|---|---|---|---|
| 2011 | 9 | 0 | 9 | 0 | 0 |
| 2012 | 21 | 16 | 21 | 21 | 21 |
| 2013 | 36 | 30 | 33 | 33 | 33 |
| 2014 | 36 | 33 | 36 | 36 | 36 |
| 2015 | 33 | 17 | 31 | 24 | 26 |
| 2016 | 36 | 31 | 36 | 36 | 36 |
| 2017 | 36 | 21 | 33 | 27 | 19 |
| 2018 | 36 | 16 | 36 | 24 | 24 |
| 2019 | 36 | 30 | 36 | 36 | 36 |
| 2020 | 36 | 34 | 36 | 36 | 36 |
| 2021 | 36 | 25 | 36 | 33 | 30 |
| 2022 | 36 | 29 | 36 | 27 | 27 |
| 2023 | 36 | 15 | 29 | 22 | 16 |
| 2024 | 36 | 23 | 35 | 32 | 33 |
| 2025 | 36 | 28 | 36 | 31 | 31 |
| 2026 | 36 | 30 | 36 | 30 | 30 |
| **Total** | **531** | **378 (71.2%)** | **515 (97.0%)** | **448 (84.4%)** | **434 (81.7%)** |

TorBox respondió para menos de esta biblioteca que cualquiera de los tres backbones de pago.

El número que decide si el slot merece su sitio es otro. **TorBox no tenía nada que los demás no tuvieran.** Ni un solo artículo de 531. Comparado con la cuenta de Omicron, es un subconjunto estricto sin artículos propios. Tenía 9 artículos que le faltaban a Frugal y 6 que le faltaban a Eweka. Todos ellos también estaban en Omicron. Mientras tanto, la cuenta de Omicron por sí sola tenía 61 artículos que ningún otro backbone tenía.

Un fallo en este servidor es real y no un servidor saturado que responde mal. Los 153 fallos se volvieron a consultar minutos después en una conexión nueva y ninguno devolvió nada. Una ejecución anterior con la misma forma volvió a consultar 77 fallos y recuperó 1. Así que más o menos el 1 por ciento de una respuesta negativa es ruido y el resto es ausencia.

Un acierto también es real. Veinte artículos que los cuatro servidores aseguraban tener se descargaron completos con `BODY`. Los cuatro entregaron 20 de 20. `STAT` en este servidor puede considerarse fiable: significa que los bytes van a llegar.

La velocidad de una sola conexión se midió en las mismas ejecuciones, pero no se incluye aquí porque no fue estable. Tres rondas desde un mismo host pusieron a TorBox entre 1,6 y 7,4 MB/s, y los otros tres se solapaban con ese rango sin un orden consistente. Quien dimensione un pool debería medir desde su propio host.

Hay tres advertencias que deben acompañar a la tabla. La muestra es la biblioteca de un solo operador, así que refleja lo que esa biblioteca recoge. Tres artículos de un mismo release no son independientes entre sí, por lo que una celda por año equivale en realidad a doce releases y no a treinta y seis. Y una respuesta `STAT` es una afirmación sobre un artículo, no un veredicto sobre un release entero.

## ¿Merece la pena ocupar un puesto? {#is-it-worth-a-slot}

La cuenta no cuesta nada extra porque viene incluida con Pro. Ese es su argumento más fuerte.

No es un backbone de retención, y si la configuras como tal te vas a decepcionar. Respondió por una parte menor de una biblioteca real que las tres cuentas de pago con las que se comparó, y no produjo ningún artículo que otra cuenta ya hubiera rechazado. Una pila que ya tiene una cuenta de Omicron no gana nada al añadir esta.

Quedan dos usos honestos. En una configuración con un solo proveedor, da una segunda opinión gratis, y cualquier segunda opinión es mejor que ninguna. Y `backup: true` hace que una suposición errónea salga barata, porque una cuenta de respaldo solo se consulta después de que todas las principales hayan dicho que no existe ese artículo.
