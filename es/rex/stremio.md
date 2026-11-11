# rex con tus addons de Stremio {#rex-with-your-stremio-addons}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) convierte los catálogos de addons de Stremio en bibliotecas de rex. Las películas, las series y la TV en directo se reproducen luego en las apps de Plex. No se descarga nada. Cuando alguien pulsa play, rex-stremio pide un enlace al addon de streams y rex lo reproduce.

No necesitas ser patrocinador de DMM. rex y rex-stremio son gratuitos. Usa addons de streams que devuelvan enlaces, normalmente a través de tu propia cuenta de debrid.

Lo que obtienes:

- **Bibliotecas.** Las películas van a **Stremio Films**, las series a **Stremio Shows** y los canales de un addon de TV en directo a una biblioteca llamada **Live TV**, a menos que le pongas tú nombre a la biblioteca de un catálogo. Esa biblioteca es una lista de canales; no aparecen en la guía de Live TV de las apps de Plex.
- **Colecciones.** Asigna varios catálogos de películas a la misma biblioteca y marca **Catalogs as collections**: tendrás una biblioteca, una colección por catálogo, y una película que aparezca en varios de ellos solo estará una vez.
- **Plex pone los nombres que conoce.** Las películas y los episodios se envían a rex con sus IDs de IMDb, así que, una vez que rex esté en una cuenta de Plex, las apps muestran los títulos, pósters y sinopsis habituales. Los títulos que solo conoce un addon, y los canales en directo, conservan los nombres e imágenes del addon.

## Antes de empezar {#before-you-start}

| Necesitas | Por qué |
|---|---|
| Una máquina que esté siempre encendida, con Linux o macOS, para rex y rex-stremio a la vez | rex-stremio es un programa de Python que funciona junto a rex. El servicio de abajo es para Linux; [Docker](#in-docker) también funciona |
| Python 3.9 o más reciente, `git` y `ffprobe` | rex-stremio revisa el stream de cada título una vez con ffprobe, porque rex necesita saber qué hay en un archivo antes de poder reproducirlo. Si tienes una clave de API de DMM, un stream de debrid de un torrent que DMM ya tiene analizado se salta esa revisión; cualquier otro se analiza |
| Complementos de stream que den enlaces, no torrents | rex reproduce archivos. Configura tu servicio de debrid en el complemento para que devuelva enlaces |
| Una cuenta nueva de Plex, creada solo para rex | Igual que en la configuración de rex: rex se reclama en ella y se comparte con la tuya |

## Paso 1. Instala rex y añádelo a una cuenta de Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Sigue [rex con tu propia app](any-source.md):

1. [Paso 1. Instala rex](any-source.md#step-1-install-rex), incluido encontrar la IP LAN de rex. Usa ese nombre en todos los comandos.
2. [Paso 3. Añádelo a una cuenta de Plex](any-source.md#step-3-add-it-to-a-plex-account): registra rex en la cuenta nueva y compártela con la tuya.

Salta los pasos 2 y 4 de esa guía: rex-stremio es tu app.

Los canales en vivo y los addons cuyos streams son listas `.m3u8` solo se reproducen con la conversión de vídeo de rex. Para esos, configura también [Converting video](any-source.md#converting-video-optional) en la máquina de rex. Las películas y episodios servidos como archivos (`.mkv`, `.mp4`) no necesitan nada más.

## Paso 2. Instala rex-stremio {#step-2-install-rex-stremio}

**Qué hace.** Descarga rex-stremio en `~/rex-stremio` en la máquina de rex y lo inicia como servicio.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-stremio
mkdir -p ~/.config/systemd/user
cp ~/rex-stremio/rex-stremio.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-stremio
journalctl --user -u rex-stremio -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-stremio
cd ~/rex-stremio && python3 rex_stremio.py
```

Sigue funcionando mientras la ventana de Terminal esté abierta.
+++

**Qué deberías ver.** Una línea como:

```
... INFO relay and settings on http://127.0.0.1:9982/, 0 catalog(s), rex at http://127.0.0.1:32400
```

La página de ajustes de rex-stremio y la dirección desde la que rex lee los vídeos están ambas en `127.0.0.1:9982`, así que solo esta máquina puede acceder a ellas.

## Paso 3. Añade tus addons {#step-3-add-your-addons}

Abre `http://127.0.0.1:9982/` en un navegador en la máquina de rex. ¿No tienes pantalla? Desde tu ordenador ejecuta `ssh -L 9982:127.0.0.1:9982 you@<rex's LAN IP>` y luego abre la misma dirección mientras SSH siga abierto.

1. En **Addons**, pega el enlace del manifest de un addon, como harías en Stremio, y pulsa **Add**. Hazlo para:
   - **Catalogs**, por ejemplo Cinemeta: `https://v3-cinemeta.strem.io/manifest.json`.
   - **Streams**: un addon que busca releases y los reproduce a través de tu servicio debrid. Abre su página de configuración, elige tu servicio debrid, pega su API key y copia el enlace del manifest que genera. Si solo ofrece resultados en caché, elígelo. El enlace contiene tu clave de debrid: no la compartas.

   ![Sección Addons de rex-stremio con Cinemeta y Public Domain Movies añadidos](../assets/rex/90-stremio-addons.webp)

2. En **Catalogs**, marca los catálogos que quieras. Indica la biblioteca en la que va cada uno y ajusta **How many** para elegir cuántas películas, episodios o canales tomar. Para una sola biblioteca con una colección por catálogo, asigna a los catálogos la misma biblioteca y marca **Catalogs as collections**.
3. En **Streams**, define la **Highest resolution** y el **Largest file** que quieres reproducir, o déjalos en any.
4. En **rex**, pon la dirección `http://<rex's LAN IP>:32400`.
5. Si patrocinas DMM, pega tu API key de DMM en **DMM** ([gatekeeper](https://gatekeeper.debridmediamanager.com/) la muestra una vez que patrocinas). Un stream de debrid de un torrent que DMM ya tiene comprobado se salta su verificación. Cualquier otro se comprueba, y lo que rex-stremio comprueba de los archivos de un torrent (nunca un stream HTTP normal ni una playlist HLS) se envía a DMM para el siguiente patrocinador (`share_probes: false` en `config.json` lo impide). Pulsa **Save and sync**.

![Secciones Catalogs, Streams, rex y DMM de rex-stremio, con el botón Save and sync](../assets/rex/91-stremio-catalogs-rex.webp)

**Lo que deberías ver.** En el registro de rex, igual que en el [paso 4 de rex con tu propia app](any-source.md#step-4-connect-your-app):

```
INFO    SOURCES PUT /rex/sources/stremio -> 200
INFO    FEED stremio upsert: ...
```

Los títulos aparecen en rex a medida que se comprueba cada uno, no cuando termina todo el catálogo, y rex-stremio comprueba varios a la vez. Vuelve a sincronizar cada seis horas y después de cada guardado.

## Paso 4. Comparte las nuevas bibliotecas y mira {#step-4-share-the-new-libraries-and-watch}

Las bibliotecas que crea rex-stremio son nuevas, así que tu propia cuenta todavía no puede verlas. Compártelas con tu cuenta como en el [paso 3](any-source.md#share-it-with-your-own-account), iniciando sesión con la cuenta nueva, y con cualquier otra persona con la que compartas rex.

Después, abre una app de Plex con tu cuenta y dale a play a algo. En ese momento, rex-stremio pide un enlace a tus addons de streams y rex lo reproduce. Para ver fuera de casa o en app.plex.tv, dale a rex una dirección propia: [Úsalo fuera de tu casa](any-source.md#use-it-outside-your-home-optional).

## En Docker {#in-docker}

rex-stremio tiene los comandos de Docker en su [README](https://github.com/debridmediamanager/rex-stremio#set-up). En un contenedor, rex lee los videos desde la dirección del contenedor en tu red en lugar de `127.0.0.1`, que el README muestra cómo configurar.

## Actualizar {#updating}

```bash
cd ~/rex-stremio && git pull && systemctl --user restart rex-stremio
```

En macOS, deténlo con Ctrl+C, ejecuta `git pull` en `~/rex-stremio` y vuelve a iniciarlo.

## Lo que no puede hacer {#what-it-cannot-do}

- **Los episodios se numeran como los numera Cinemeta.** En algunas series eso no coincide con la numeración de TMDB, que es la que sigue rex, así que un episodio puede acabar en el sitio equivocado.
- **El conteo cuenta episodios** en un catálogo de series, no series.
- **Activar o desactivar Catalogs as collections** envía los títulos a rex de nuevo como si fueran nuevos, así que puede que lo que ya viste en ellos no se conserve. Decídelo antes de empezar a ver.
- **Solo se listan catálogos de películas, series y canales**, y ninguno que necesite antes una búsqueda o un género.
- **Los canales en directo** no se pueden pausar mucho hacia atrás, reanudar más tarde ni marcar como vistos, y solo se reproducen en las apps que piden a rex que los convierta (las apps de Plex y Plezy; Plex Web no está probado). Los canales sin stream funcional o con DRM se dejan fuera.
- **Cualquiera que pueda llegar a la dirección de rex-stremio puede reproducir a través de ella.** Déjala en `127.0.0.1` a menos que rex se ejecute en otro equipo.

El README recoge el [resto de sus límites](https://github.com/debridmediamanager/rex-stremio#limits) y cada ajuste de `config.json`. Para crear tu propio addon, consulta [Cómo crear addons para rex](addons.md), que también explica cómo funciona rex-stremio por dentro.
