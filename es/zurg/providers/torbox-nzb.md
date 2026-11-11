# TorBox alojado Usenet {#torbox-hosted-usenet}

`type: torbox_nzb`

Con un plan TorBox Pro, TorBox hace la parte de Usenet por ti. zurg publica los archivos `.nzb` de su directorio de vigilancia en tu cuenta de TorBox. TorBox descarga cada release, la repara y la sirve como cualquier otra descarga de TorBox. zurg muestra lo que TorBox ha descargado en el montaje junto a todo lo demás. No necesitas una cuenta de servidor de noticias y ningún artículo de Usenet se decodifica en tu máquina.

Esto no es el [servidor de noticias de TorBox](torbox-news-server.md). Ese es un inicio de sesión para el backend `nzb`, que lee los artículos por sí mismo y se explica en [Usenet](usenet.md). Tampoco es una entrada `torbox`. Esa lista tus torrents, y la página de [TorBox](torbox.md) la explica.

## Lo que necesitas {#what-you-need}

- **Un plan TorBox Pro.** Un plan inferior no acepta NZB.
- **Tu clave API de TorBox** desde [torbox.app/settings](https://torbox.app/settings).
  Es la misma clave que usa una entrada `torbox`.
- **Una versión nightly reciente de zurg.** Las nightly requieren una suscripción de patrocinio activa.
- **Un host normal.** zurg+rex en Android, un servidor Plex en tu teléfono, no tiene backend `torbox_nzb`. En un dispositivo Android, reproduce los NZB alojados en TorBox a través de TorBox Cast de DMM o del addon de Kodi.

## Configúrala {#configure-it}

The entry toma un `token`; no hay bloque `nntp`. No se puede definir `watchlist` en él, porque una cuenta NZB no puede añadir torrents.

```yaml
providers:
  - type: torbox_nzb
    token: YOUR_TORBOX_API_KEY
```

En una instalación nueva del contenedor, guarda primero tu clave en `~/zurg/secrets/torbox` y luego deja que el setup la lea.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox_nzb \
  --torbox-token-file /config/secrets/torbox
```

En una instalación que ya tiene un `config.yml` también puedes usar **Add provider** en el Dashboard en `http://localhost:9999/config/` y elegir `torbox_nzb`. Reinicia zurg de cualquiera de las dos formas.

```bash
docker compose restart zurg
```

## Cómo entran los NZB {#how-nzbs-get-in}

Todo lo que llega a una entrada `nzb` llega a esta de la misma manera; la acción TorBox de DMM es el único camino que se salta zurg.

- **El directorio de vigilancia.** Suelta un archivo en `nzbs/` junto a la configuración (`~/zurg/nzbs/` en el host, `/config/nzbs/` en el contenedor). zurg lo envía a TorBox.
- **Sonarr y Radarr** a través del endpoint compatible con SABnzbd de zurg. Consulta [Sonarr and Radarr for Usenet](../guides/sonarr-radarr.md).
- **Adquisición.** Los indexadores Newznab, DMM Wanted y las watchlists lo alimentan. Consulta [Acquisition](../guides/acquisition.md).
- **La acción TorBox de DMM** sobre un resultado de Usenet envía el NZB directamente a TorBox. La release también aparece en zurg, pero zurg no guarda ningún NZB de ella, así que el botón de reparación no puede volver a descargarla una vez que TorBox la elimine.

Si TorBox no puede obtener un post, se lo notifica a Sonarr o Radarr como una descarga fallida. El cliente pone la release en la lista de bloqueo y vuelve a buscar.

## Qué difiere de `nzb` {#what-differs-from-nzb}

- **Sin cuenta de noticias.** No hay límite de conexiones que ajustar ni retención de proveedores que tener en cuenta. El propio spool de TorBox decide de qué posts se puede descargar.
- **Aquí no se decodifica ningún artículo.** TorBox descarga la release completa. La descarga de artículos, la reparación con PAR2, la caché de artículos y las comprobaciones de artículos no aplican; la caché de disco de los archivos descomprimidos sí. Una captura se comprueba por si TorBox la ha descargado.
- **Caché de 30 días.** Una release que otra persona ya descargó en TorBox está lista al instante. TorBox elimina una release 30 días después de haberla cacheado. El botón de reparar del panel la vuelve a descargar enviando su NZB otra vez, así que guarda los archivos en `nzbs/`. zurg nunca vuelve a enviar nada por su cuenta, porque TorBox considera abuso las descargas repetidas sin supervisión.
- **Un slot por NZB en curso.** Un post que TorBox todavía está descargando ocupa uno de los slots activos de tu plan. Una entrada `torbox` con la misma clave usa los mismos slots para sus torrents.
- **60 posts por hora.** TorBox acepta esa cantidad de NZB nuevos por hora y por clave. Un gran acumulado, como un `nzbs/` completo en el primer arranque, se vacía a lo largo de varias horas.

## Una cuenta NZB por instancia {#one-nzb-account-per-instance}

Una instancia toma una entrada `nzb` o una entrada `torbox_nzb`, nunca ambas. Si pusieras las dos, cada archivo de `nzbs/` aparecería listado dos veces. Para usar ambas, dale a la otra clase una instancia propia con su propio directorio de trabajo. Si ambas tienen `dmm_api_key`, [desactiva la fuente `dmm-wanted` en una de ellas](../guides/dmm-wanted.md#two-zurgs-on-one-key), o cada título de Wanted se pedirá dos veces. Cualquiera de las dos puede convivir con tus cuentas de debrid.

El addon de Stremio de zurg envía su elección a la cuenta NZB que tenga la instancia. Con `torbox_nzb`, si TorBox ya tiene un release, arranca dentro del tiempo de espera del addon siempre que no haya otra publicación NZB en espera. Si no está en caché, TorBox tiene que terminar primero la descarga, y eso tarda más de lo que el reproductor espera.

## Comprueba que funcionó {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox_nzb/test
ls /zurg_mnt/zurg/__all__/
curl -s http://localhost:9999/http/__torbox_nzb__/ | head
```

Con una sola cuenta, su propia carpeta se omite del listado raíz del montaje, así que el montaje muestra los mismos archivos bajo `__all__`. El nombre del directorio sigue al nombre de la entrada, que por defecto es su tipo.
