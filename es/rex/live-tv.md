# Live TV con rex {#live-tv-with-rex}

rex muestra los canales de los complementos en **Live TV** de Plex Web y de Plex para Android, con una guía y What's On. Elige un canal y se reproduce al instante. [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) está listo para usar con un servidor de deportes en vivo. Para una guía XMLTV y una lista M3U de IPTV, consulta [Tutorial: un complemento de IPTV](addon-iptv.md).

Esto es lo que obtienes:

- **Una guía.** Cada canal con su número, con lo que se emite ahora y lo siguiente.
- **What's On.** Lo que se emite en este momento, lo que empieza más tarde y las películas que vienen.
- **Búsqueda.** El nombre de un programa lo encuentra en Live TV y también en tus bibliotecas.
- **Reproducción.** Elige un canal y se reproduce en directo. Un canal no guarda punto de reanudación y nunca se marca como visto.
- **Una parrilla, como la de un proveedor de TV.** rex-live-sports empieza con su parrilla de EE. UU.: unas 30 cadenas deportivas con números que nunca cambian (ESPN es el 2, CBS el 7), el calendario de ESPN con los partidos que se emiten en ellas, y canales de ranura (`NFL 1`, `NBA 1` y así sucesivamente) que listan los partidos del día antes de que empiecen y reproducen cada uno en directo. También hay parrillas para el Reino Unido y Alemania.
- **La biblioteca también.** Los canales se quedan en su propia biblioteca **Live Sports**, ordenados en una colección por grupo.

## Antes de empezar {#before-you-start}

| Necesitas | Por qué |
|---|---|
| Una nightly de rex con fecha 2026.11.02 o posterior | La TV en vivo llegó en esa versión |
| rex configurado como en [rex con tu propia app](any-source.md), con [Conversión de video](any-source.md#converting-video-optional) | rex convierte cada canal mientras lo ves (una copia, barata) |
| Un servidor de deportes en vivo, en la máquina de rex o en tu red de casa | rex-live-sports toma sus canales de ahí |
| Docker | Sirve para live-sports en el Paso 2. Su [README](https://github.com/yowmamasita/live-sports-public) tiene las otras formas |
| Python 3.9 o posterior, `git`, `ffmpeg` y `ffprobe` en la máquina de rex | rex-live-sports revisa el stream de cada canal con ffprobe y dibuja su póster con ffmpeg |

## Paso 1. Instala rex y añádelo a una cuenta de Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Sigue [rex con tu propia app](any-source.md):

1. [Paso 1. Instala rex](any-source.md#step-1-install-rex), incluido encontrar la IP LAN de rex. Esta página la escribe como `192.168.1.20`: pon la tuya en su lugar.
2. [Paso 3. Añádelo a una cuenta de Plex](any-source.md#step-3-add-it-to-a-plex-account): registra rex en la cuenta nueva y compártelo con la tuya.
3. [Convertir vídeo](any-source.md#converting-video-optional).

Salta los pasos 2 y 4 de ahí: rex-live-sports es tu app.

## Paso 2. Inicia un servidor de deportes en vivo {#step-2-start-a-live-sports-server}

**Qué hace.** Ejecuta live-sports, que busca canales deportivos y revisa cada pocos minutos cuáles están emitiendo.

```bash
docker run -d --name live-sports --restart unless-stopped -p 8765:8765 ghcr.io/yowmamasita/live-sports:latest
```

**Qué deberías ver.** `http://192.168.1.20:8765` muestra el panel de live-sports en el navegador. La primera revisión de cada canal tarda unos pocos minutos.

## Paso 3. Instala rex-live-sports {#step-3-install-rex-live-sports}

**Qué hace.** Descarga rex-live-sports en `~/rex-live-sports` en la máquina de rex y lo inicia.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

En `config.json`, pon `live_sports_url` en `http://192.168.1.20:8765` y `rex_url` en `http://192.168.1.20:32400`. Luego:

```bash
mkdir -p ~/.config/systemd/user
cp ~/rex-live-sports/rex-live-sports.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-live-sports
journalctl --user -u rex-live-sports -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

En `config.json`, pon `live_sports_url` en `http://192.168.1.20:8765` y `rex_url` en `http://192.168.1.20:32400`. Luego:

```bash
python3 rex_live_sports.py
```

Se queda corriendo mientras la ventana de Terminal esté abierta.
+++

**Qué deberías ver.** Una línea como:

```
INFO relay on http://127.0.0.1:9983/, live-sports at http://192.168.1.20:8765, rex at http://192.168.1.20:32400
```

Hasta que termine la primera comprobación de live-sports, registra `live-sports lists no channel that plays yet`. Después, la primera sincronización comprueba el stream de cada canal de la parrilla que live-sports tiene, unos 60 segundos para 30, y registra:

```
INFO pushed 38 of 30 channels, 38 with their Live TV channel: ...
```

Eso corresponde a los 30 canales de la parrilla que live-sports tiene, más los huecos con un partido ese día. Vuelve a sincronizar cada cinco minutos y solo comprueba los canales que no ha visto ese día.

## Paso 4. Comparte la biblioteca y abre Live TV {#step-4-share-the-library-and-open-live-tv}

La biblioteca **Live Sports** es nueva, así que todavía no está en el acceso compartido de nadie. Con la cuenta nueva iniciada, añádela al acceso compartido de tu propia cuenta y al de los demás en **Manage Library Access** ([Comparte rex](sharing.md)). Un acceso compartido permite a su cuenta ver Live TV, a menos que lo hayas desactivado para esa cuenta.

Luego abre una app de Plex con tu cuenta:

- **Plex Web**: **Live TV & DVR** está en la barra lateral, con las bibliotecas de rex.
- **Plex para Android**: la pestaña **Live TV** abajo, con rex seleccionado arriba; **Live TV & DVR** también aparece listado con las bibliotecas de rex.

**Lo que deberías ver.** **Guide** y **What's On** arriba. La guía muestra cada canal con su número y lo que se emite en él. Elige un programa y pulsa **Watch Now**.

## Canales, números y guías {#channels-numbers-and-guides}

`config.json` indica la parrilla: `lineups/us.json` tal cual, `lineups/uk.json` o `lineups/de.json` para las cadenas del Reino Unido o de Alemania. Un canal de la parrilla está en su número, y live-sports tiene una copia que sí se reproduce. Una cadena de EE. UU. toma sus partidos del calendario de ESPN (`Chicago Bears at Seattle Seahawks`, desde el saque inicial y durante la duración habitual del deporte: NFL, fútbol americano universitario, NBA, NHL, MLB, las grandes ligas europeas, MLS y F1). ESPN solo nombra cadenas de EE. UU., así que las cadenas del Reino Unido y de Alemania usan en su lugar la guía que [epgshare01](https://epgshare01.online/) tiene para un canal con su mismo nombre, como hace cada canal alrededor de sus partidos. Un canal que ninguna guía incluye muestra su propio nombre en bloques de seis horas.

Las ranuras van después de las cadenas: `NFL 1` a `NFL 10` en `700.1` a `700.10`, `NBA 1` a `NBA 6` desde `701.1` en adelante, luego NHL, MLB, Soccer y F1. Cada partido del día va a la primera ranura libre de su deporte, así que la guía lo muestra antes de que empiece. Desde 15 minutos antes del saque inicial hasta que termina, la ranura reproduce el stream de live-sports que lo contiene, encontrado por los nombres de ambos equipos. Entre partidos, una ranura no reproduce nada. Una ranura aparece por primera vez cuando reproduce un partido.

Sin parrilla (`"lineup": ""` en `config.json`), en su lugar aparecen todos los canales de los grupos `Live:` y `Sports` de live-sports, numerados por grupo: `100.1`, `100.2` para el primer grupo, `101.1` para el siguiente, por encima de los números bajos que usa un sintonizador u otra fuente. Un canal conserva su número mientras live-sports lo liste al menos una vez a la semana. Los canales de Pluto TV usan su propia programación y quedan fuera salvo que los pidas: `"groups": ["Live:", "Sports", "Pluto:"]`. Todas las opciones están en el [README](https://github.com/debridmediamanager/rex-live-sports#settings) de rex-live-sports.

## Actualizar {#updating}

```bash
cd ~/rex-live-sports && git pull && systemctl --user restart rex-live-sports
```

En macOS, deténlo con Ctrl+C, ejecuta `git pull` en `~/rex-live-sports` y vuélvelo a iniciar.

## Lo que no puede hacer {#what-it-cannot-do}

- **Nada se graba.** Plex Web y Plex para Android no muestran el botón Grabar.
- **Las guías se emparejan por nombre.** Un canal puede obtener la guía de otra señal de la misma marca, y muchos canales de eventos no tienen ninguna.
- **Una franja busca el stream de un partido por los equipos de su nombre.** Un stream con otro nombre (`nfl ravens`) no se encuentra, y un partido que ningún stream tiene aparece en la guía pero no se reproduce.
- **Plex clasifica como película un programa sin número de episodio**, como hace con cualquier guía de TV, así que las coincidencias también aparecen en las películas de What's On.
- **La TV en vivo se probó en Plex Web y Plex para Android.** Otras apps de Plex no se han probado.
- **Cualquiera que pueda llegar a la dirección de rex-live-sports puede reproducir a través de ella.** Mantén `listen` en `127.0.0.1`.

Para añadir tus propios canales, con una guía que ya tengas, consulta [Crear addons de rex](addons.md#live-tv).
