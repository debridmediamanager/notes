# AllDebrid

`type: alldebrid`

[AllDebrid](https://alldebrid.com/?uid=1kk5i&lang=en) es el otro backend que rota credenciales. Así que `download_tokens`
y un token `.strm` aparte significan algo aquí. Sus listas de archivos vienen de
un endpoint propio en lugar de la lista de magnets. Eso cambia lo que se siente
un primer escaneo de una biblioteca grande.

## Obtén la clave de API {#get-the-api-key}

Inicia sesión y abre [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i).
Genera una clave y cópiala.

## Configúrala {#configure-it}

```yaml
zurg: v1
providers:
  - type: alldebrid
    token: YOUR_ALLDEBRID_API_KEY
mount_path: "/zurg_mnt/zurg"
```

En una instalación nueva en contenedor, deja que el setup lo escriba.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider alldebrid
```

En una instalación que ya tiene un `config.yml`, usa **Add provider** en el Dashboard en `http://localhost:9999/config/` o edita el archivo. Reinicia de cualquier forma.

```bash
docker compose restart zurg
```

`ALLDEBRID_TOKEN` lo lee `zurg setup` y no el daemon que está corriendo. Ponerlo en el bloque `environment:` de tu compose e iniciar el contenedor no hace nada por sí solo.

## Claves extra que usa este backend {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: alldebrid
    token: PRIMARY_AD_API_KEY
    strm_link_token: AD_KEY_FOR_STRM
    download_tokens:
      - SECOND_AD_API_KEY
```

`download_tokens` son claves de respaldo del mismo servicio. Toman el relevo cuando se agota el ancho de banda permitido de la clave activa. Usan el catálogo de esta entrada y sus bibliotecas propias nunca se importan.

`strm_link_token` resuelve las lecturas que llegan a `/strm/` para que un reproductor que abre un `.strm` no gaste la clave que usa tu montaje en vivo. Si no está definido, se usa `token` en su lugar.

## El primer escaneo se llena poco a poco {#the-first-scan-fills-in-gradually}

AllDebrid v4.1 movió los detalles de los archivos de la lista de magnets a un endpoint aparte. Listar tus magnets no le dice a zurg qué contienen. Cada release necesita una consulta.

La buena noticia es que esa consulta solo hace falta **una vez para siempre** y no una vez por reinicio. El árbol de archivos de un magnet no cambia en cuanto está Ready. Por eso la caché de información de zurg en disco es permanente para él. Un batcher delante del endpoint se encarga del escaneo inicial. Lo que ves en la primera ejecución es una biblioteca grande que aparece por partes, y luego ya no vuelve a hacerlo.

## Límites que conviene conocer {#limits-worth-knowing}

**Sin límite publicado de imanes activos.** zurg no inventa uno. La reparación
nunca espera por espacio que nunca fue escaso.

**600 peticiones por minuto para una clave.** Ese es el presupuesto documentado. zurg
se autorregula a 600 menos 100, para que los reintentos que su propio cliente HTTP
hace por su cuenta no empujen una ráfaga por encima del límite real. La concurrencia es la
restricción vinculante en la práctica y está limitada a 12, para igualar las 12 peticiones
por segundo documentadas.

**La conexión número 33 a un mismo servidor de descarga recibe un 429.** Medido el 2026-08-23
abriendo una conexión cada 500 ms y manteniéndola. AllDebrid genera un nombre de host
de descarga nuevo en cada desbloqueo. Por eso esto solo se aplica cuando varias lecturas
coinciden en el mismo host. zurg pone en cola las conexiones a partir de la 32 en lugar de abrir más.

**No existe selección por archivo.** Al añadir un imán se descarga todo, y
la reparación vuelve a añadir la publicación completa.

**El contenido desaparece por sí solo.** Los imanes se eliminan de una cuenta con el tiempo
y el alojador puede dar de baja un enlace. Que una publicación haya desaparecido es un
resultado esperado y no una corrupción. La reparación no la toca salvo que lo pidas.

**Los enlaces guardados no caducan.** Los enlaces bloqueados registrados para un archivo se
regeneran a partir del estado actual del imán. El propio estado del imán ya indica si los datos
están disponibles. zurg no gasta un desbloqueo por torrent en cada escaneo en frío
solo para averiguar lo que el estado ya decía gratis.

## Comprueba que funcionó {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/alldebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

Con una sola cuenta, su propia carpeta se deja fuera del listado raíz del montaje, así que el montaje muestra los mismos archivos bajo `__all__`.

## Cuando algo sale mal {#when-it-goes-wrong}

**`AllDebrid rejected the API key` en el log.** La clave fue revocada o regenerada. Consigue una nueva en [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i) y actualiza la entrada.

**Una biblioteca fría aparece despacio.** Es lo esperado. Mira la sección de arriba. Es una sola consulta por release y no se repite.

**Un release se reproduce en otra parte del mount pero da 404 bajo `__alldebrid__`.** La rotura se evalúa por cuenta, y ese directorio fija las lecturas a esta cuenta. Otra cuenta tiene una copia buena.
