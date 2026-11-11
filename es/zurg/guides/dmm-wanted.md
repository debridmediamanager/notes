# Trae lo que quieras desde DMM {#fetch-what-you-want-from-dmm}

Pulsa **Want** en una película o serie en [Debrid Media Manager](https://debridmediamanager.com),
y tu zurg la descarga. No hace falta configurar Sonarr ni Radarr, ni montar nada.
Las series siguen recibiendo sus nuevos episodios conforme se emiten.

Es para patrocinadores: zurg lee tu lista con tu clave de API de DMM.

## Lo que necesitas {#what-you-need}

- Un nightly de zurg del 2026-10-25 o posterior.
- Tu API key de DMM en el `config.yml` de zurg. Es la key que [gatekeeper](https://gatekeeper.debridmediamanager.com/) te muestra una vez que te haces sponsor:

  ```yaml
  dmm_api_key: YOUR_DMM_API_KEY
  ```

- Algo a lo que zurg pueda conectarse para descargar: una cuenta de debrid que acepte torrents, un proveedor `nzb` o `torbox_nzb` para Usenet, o ambos.

Eso es todo lo que necesitas configurar. zurg lee tu lista una vez por minuto desde el momento en que arranca.

## Añadir títulos {#adding-titles}

1. Pega la misma clave en la página de [Settings](https://debridmediamanager.com/settings) de DMM.
2. Abre una película y pulsa **Want**. En la página de una temporada de una serie, **Want S2** añade esa temporada
   y **Want all seasons** añade la serie completa, incluidas las temporadas nuevas.
3. Tu lista está en [debridmediamanager.com/wanted](https://debridmediamanager.com/wanted).
   Ahí aparece cuándo tu zurg la leyó por última vez y cuándo obtuvo cada película. Las listas largas
   se muestran de 120 títulos por página.

Las solicitudes de Seerr, Overseerr o Jellyseerr también pueden aparecer en esta misma lista: consulta
[Seerr a través de DMM](../../dmm/seerr.md).

## Seguir una lista {#following-a-list}

Pega la página de una lista de Trakt o MDBList en tu [lista de deseados](https://debridmediamanager.com/wanted)
y pulsa **Follow**. Cada película y serie de esa lista queda marcada como deseada, y DMM vuelve a leerla cada seis horas, así que lo que se añada a la lista más adelante también queda marcado como deseado. Páginas que acepta:

- `https://trakt.tv/users/<user>/lists/<list>` y `https://trakt.tv/lists/<id>`
- `https://trakt.tv/users/<user>/watchlist`, si ese perfil de Trakt es público
- `https://mdblist.com/lists/<user>/<list>`

En las páginas de Trakt de DMM, tu watchlist y cada una de tus listas tienen un botón **Follow with Want** que hace lo mismo.

Una watchlist de IMDb, Letterboxd, Rotten Tomatoes o Plex: en mdblist.com, crea una [lista externa](https://docs.mdblist.com/docs/external_lists) a partir de su URL y sigue esa. MDBList la mantiene sincronizada con el origen.

Qué hace seguir una lista:

- Una serie se marca completa, incluidas las temporadas nuevas.
- Solo se añaden los títulos nuevos en la lista desde la última lectura. Si quitas un título de tu lista de deseados, se queda quitado, y si un título sale de la lista, sigue marcado como deseado. **Unfollow** mantiene lo que la lista añadió.
- La página muestra cada lista con cuántos títulos tiene, cuántos ha añadido hasta ahora y cuándo se leyó por última vez. **Read again** la lee en ese momento. Los títulos sin id de IMDb se dejan fuera, y el contador indica cuántos son.
- Tu lista admite 10.000 títulos pendientes de obtener: todas las series y cada película que zurg aún no haya obtenido o que esté esperando para mejorar. Las películas que zurg ya ha obtenido no cuentan. Un título que no cabe se añade en una lectura posterior, cuando haya espacio.

## Pasar desde Radarr o Sonarr {#moving-from-radarr-or-sonarr}

Traiga todo lo que todavía están buscando:

1. En Radarr o Sonarr, abra **System → Backup**, pulse **Backup Now** y descargue el zip. Las copias programadas de su carpeta `Backups` también sirven.
2. En su [lista de pendientes](https://debridmediamanager.com/wanted), pulse **Import a Radarr or Sonarr backup** y elija el zip. Luego haga lo mismo con la copia de la otra aplicación.

Esto es lo que se trae:

- De Radarr, cada película monitorizada que no tenga archivo y que ya haya alcanzado su disponibilidad mínima. Las películas sin id de IMDb se dejan fuera; la página indica cuántas son.
- De Sonarr, cada serie monitorizada con episodios ya emitidos que faltan, solo con esas temporadas.
- Los títulos que ya están en su lista se quedan como están.

Solo se sube la base de datos que hay dentro del zip. El resto de la copia, incluida la clave de API de la aplicación, se queda en su ordenador.

Dos cosas no se traen:

- **Perfiles de calidad.** zurg elige las versiones según sus propios [ajustes de adquisición](acquisition.md#configuration). Radarr normalmente rechaza las copias de cámara y telesync; para excluirlas, añádalas a [`exclude_words`](acquisition.md#excluding-releases-by-name):

  ```yaml
  acquisition:
    exclude_words: [CAM, CAMRip, HDCAM, TS, HDTS, TELESYNC, TC, HDTC, TELECINE]
  ```

- **Números de temporada de Sonarr, cuando no coinciden.** Su lista numera las temporadas como TMDB. Sonarr sigue a TheTVDB, que divide algunos animes de larga duración en más temporadas, así que una temporada de Sonarr que TMDB no tiene no se busca. Revise esas series en su página de DMM y pulse **Want** en las temporadas que le falten.

## Qué descarga zurg {#what-zurg-fetches}

- **Una película** una sola vez. Después sale de la lista que lee zurg. Una película descargada por debajo de la resolución a la que apunta `quality` (2160p para `best`) se queda en la lista: zurg descarga una copia mejor cuando sale una y borra la que había descargado antes. Una copia que añadiste tú mismo se conserva. `upgrades: false` bajo `acquisition:` en la configuración de zurg desactiva esto. `/wanted` muestra lo que zurg ha descargado y la resolución que todavía está esperando, salvo con la lista de resoluciones de abajo.
- **Una película en 1080p y en 4K**, si quieres las dos, por ejemplo para que un televisor 1080p reproduzca una sin tener que transcodificar el archivo 4K. Necesita la nightly del 2026-10-31 o una posterior. Enumera las resoluciones en la configuración de zurg:

  ```yaml
  acquisition:
    quality: [1080p, 4k]
  ```

  Así zurg guarda una copia de cada película en cada una de ellas. Cada copia toma la mejor versión en o por debajo de su propia resolución y se actualiza por su cuenta, de modo que la copia 1080p nunca se convierte en una 2160p. Mientras no haya ninguna versión mejor que 1080p, ambas suelen tomar la misma y obtienes un solo archivo. `720p` también se puede incluir. Las series siguen teniendo una sola copia, elegida como si hubieras escrito solo la resolución más alta. Las películas que zurg descargó antes de añadir la lista se vuelven a descargar en cada resolución; zurg nunca borra la copia anterior, así que bórrala tú mismo si ya no la quieres. Las reglas completas están en [una copia en cada una de varias resoluciones](acquisition.md#a-copy-at-each-of-several-resolutions).
- **Una serie**: cada episodio emitido de las temporadas que elegiste, como pack de temporada cuando uno cubre la temporada entera y como episodios sueltos cuando aún está en emisión. Sigue buscando nuevos episodios hasta que quites la serie. Los especiales no se descargan.

Las versiones llegan desde Usenet como NZB y desde torrents que tu cuenta de debrid ya tiene en caché; los torrents no cacheados nunca se añaden. Si no has configurado ningún indexador, zurg busca en los de DMM. La calidad, los límites de tamaño, las palabras que evitar y los idiomas de audio y subtítulos que debe tener una versión son los [ajustes de adquisición](acquisition.md#configuration) de zurg, los mismos para todas las fuentes.

## Verlo en Kodi o Plex {#watching-it-in-kodi-or-plex}

Con `__magic__` activado, zurg guarda lo que descarga por título, en `__magic__/__movies__` y `__magic__/__shows__`, con nombres que Kodi y Plex reconocen. Apunta una biblioteca de Películas y una de Series a esas dos carpetas, o con `magic.anime` también una biblioteca de Anime en `__magic__/__anime__`: consulta [`__movies__` and `__shows__`](magic.md#__movies__-and-__shows__-sorted-by-title).

```yaml
magic:
  enabled: true
```

## Dos zurg con una misma clave {#two-zurgs-on-one-key}

Cada zurg lee la misma lista, así que dos de ellos obtienen cada título dos veces. Deja la lista activada en uno y desactívala en los demás:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

## Cuando deja de funcionar {#when-it-stops}

Si tu patrocinio caduca o restableces tu clave, zurg registra que DMM rechazó la clave y vuelve a preguntar cada hora. Lo que ya se descargó sigue en tu biblioteca.

Más detalles: [DMM wanted list](acquisition.md#dmm-wanted-list) en la referencia de adquisición.
