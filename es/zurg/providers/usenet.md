# Usenet

`type: nzb`

Usenet es un tipo de proveedor, pero no un servicio de debrid. No hay token de API ni biblioteca remota. Tú dejas archivos `.nzb` en un directorio de vigilancia y zurg convierte cada uno en un release. Los artículos se descargan de tu servidor de noticias y se decodifican en el momento en que un reproductor pide esos bytes.

Esta página solo cubre la entrada del proveedor y los detalles de Docker. Todo lo demás sobre cómo usar Usenet con zurg está en [Usenet con zurg](../guides/usenet.md). Es la guía completa con cuentas de noticias y NZB, además del montaje y Plex. Es la página que conviene leer en segundo lugar.

## Configúrala {#configure-it}

No hay ningún `token`. Lo que hace válida la entrada es un bloque `nntp` con un host.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
mount_path: "/zurg_mnt/zurg"
```

Pon `connections` con lo que tu plan permite de verdad. zurg lee a ese número porque una conexión solo transporta una fracción del ancho de banda del plan. El streaming aprovecha todo lo que permite el plan en lugar de pedir un artículo a la vez. Si te pasas de lo que permite el plan, las conexiones se rechazan.

En una instalación nueva en contenedor, el setup te pedirá todo esto.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb
```

Para una instalación desatendida, la contraseña viene de un archivo y todo lo demás viene de los flags.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb \
  --nntp-host news.example.com \
  --nntp-username YOUR_USENET_USERNAME \
  --nntp-password-file /config/secrets/nntp \
  --nntp-connections 8
```

`--nntp-tls` toma true por defecto y `--nntp-port` toma 563 con TLS o 119 sin TLS.

En una instalación que ya tiene un `config.yml`, usa **Add provider** en el Dashboard en `http://localhost:9999/config/` o edita el archivo. Reinicia en cualquier caso.

```bash
docker compose restart zurg
```

## Dónde van los NZB en un contenedor {#where-the-nzbs-go-in-a-container}

El directorio de vigilancia es `nzbs/`, junto a la configuración. Eso quiere decir `~/zurg/nzbs/` en el host y `/config/nzbs/` dentro del contenedor. Es el mismo directorio. Pon los archivos desde el host.

```bash
mkdir -p ~/zurg/nzbs
cp /path/to/some.nzb ~/zurg/nzbs/
ls /zurg_mnt/zurg/__all__/
```

Con una sola cuenta, su propia carpeta `__nzb__` no aparece en el listado raíz del montaje, así que busca dentro de `__all__`. El directorio de vigilancia se revisa cada 15 segundos más o menos. Como está dentro del bind `./:/config`, sobrevive a un `docker compose pull` y a la recreación del contenedor, igual que todo lo demás.

## Reglas específicas de este tipo {#rules-specific-to-this-type}

- **Solo una entrada `nzb` habilitada.** Dos escanearían el mismo directorio y duplicarían cada release. Más servidores de noticias van bajo `nntp.servers` de esa única entrada. Así sirven la misma biblioteca en lugar de una segunda copia. Una entrada `nzb` junto a una de [`torbox_nzb`](torbox-nzb.md) también se rechaza por la misma razón.
- **`watchlist: true` se rechaza.** A un servidor de noticias nunca se le envía un torrent.
- **`add_torrents` se ignora** y al arrancar aparece un aviso por la misma razón.
- **`download_tokens` y `strm_link_token` no hacen nada.** No hay ninguna credencial que rotar.
- **El directorio es `__nzb__`** porque el nombre por defecto es el tipo. Pon `name: usenet` en la entrada si prefieres navegar por `__usenet__`.

## Un segundo servidor de noticias vale más de lo que parece {#a-second-news-server-is-worth-more-than-it-looks}

La retención depende de cada proveedor. Un artículo que un servidor ya ha dado de baja a menudo sigue estando en otro. Sin una segunda cuenta, la única forma de recuperar un artículo muerto es PAR2, y eso cuesta leer **toda la release** entera. Así que un segundo servidor marca la diferencia entre descargar un solo artículo y tener que volver a leerlo todo.

Las cuentas extra van dentro de `nntp.servers` de esta entrada, en lugar de en una segunda entrada `nzb`. `priority`, `backup` y `backbone` deciden a quién se le pregunta y en qué orden. Las lecturas se controlan con la capacidad combinada de las cuentas que no están marcadas como `backup`. La configuración completa de ejemplo y para qué sirve cada clave están en [Usenet con zurg](../guides/usenet.md#more-than-one-usenet-provider).

## Comprueba que funcionó {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/nzb/test
docker compose logs --tail=100 zurg
ls /zurg_mnt/zurg/__all__/
```

Con una sola cuenta, su propia carpeta se deja fuera del listado raíz del montaje, así que el montaje muestra los mismos archivos bajo `__all__`.

La comprobación aquí se autentica contra el servidor de noticias usando como máximo una conexión del pool existente. No hay ninguna API de cuenta a la que consultar.

## Cuando algo sale mal {#when-it-goes-wrong}

Dos síntomas pertenecen a la entrada del proveedor en sí, no a la biblioteca.

**Las lecturas se cortan y zurg baja a un artículo por vez.** `pipeline_depth` está
más alto de lo que el servidor tolera. zurg lo reduce por su cuenta y avisa. Configúralo a
`1` de forma explícita para un servidor que no puede manejar varios comandos en vuelo.

**El rendimiento es bajo en un enlace de alta latencia.** No definas `socket_receive_buffer_kb`.
Un búfer fijado es uno que el kernel deja de ajustar. En Linux eso mantiene la
ventana de recepción cerca de 64 KiB y cuesta la mayor parte del rendimiento de la cuenta.

Todo lo demás tiene una fila en la tabla de solución de problemas de [Usenet con zurg](../guides/usenet.md#troubleshooting). Las conexiones rechazadas, el streaming lento, un proveedor que nunca recibe consultas y una edición en el Dashboard que eliminó `nntp.servers` están todos ahí.
