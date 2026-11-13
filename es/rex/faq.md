# preguntas sobre rex {#rex-questions}

Respuestas cortas a lo que la gente pregunta antes de instalar rex, y poco después. Cada respuesta enlaza a la guía que tiene los detalles.

## Antes de instalar {#before-you-install}

### ¿Qué es rex? {#what-is-rex}

Un servidor de medios para las apps oficiales de Plex que no es dueño de ningún archivo. Tus apps ven un servidor de Plex más, con pósteres, temporadas, historial de reproducción y Continue Watching. Una **fuente** le dice a rex qué hay en la biblioteca y sirve cada archivo. rex lo transmite cuando pulsas reproducir. No se descarga nada antes.

Es un servidor propio. No es un plugin de Plex Media Server y no lo necesita. Ejecútalo junto a Plex si quieres usar los dos. [Instala rex](any-source.md#step-1-install-rex) explica los nombres y [Pasa de Plex a rex](from-plex.md) cubre ambas rutas.

### ¿Cuánto cuesta? {#what-does-it-cost}

rex es gratis para uso personal y no tiene un plan de pago. Su código fuente es público bajo la licencia PolyForm Noncommercial. No se permite el uso comercial. Cada versión está publicada en [GitHub Releases](https://github.com/debridmediamanager/rex/releases), y la app de Android es [rex para Android](android.md).

Lo que hay alrededor puede tener algún costo:

| | |
|---|---|
| [rex-stremio](stremio.md), tu propia app o un addon como fuente | Gratis |
| zurg nightly, una fuente para una biblioteca de debrid o Usenet | Una ventaja para los [patrocinadores de DMM](https://gatekeeper.debridmediamanager.com) |
| Una API key de DMM, para las coincidencias exactas de DMM en zurg | Opcional, también al patrocinar DMM |
| La imagen Docker de rex | Gratis y pública, para Linux: [rex en Docker](any-source.md#run-rex-in-docker) |

### ¿Corre peligro mi cuenta de Plex? {#is-my-plex-account-at-risk}

rex no lo hace Plex y Plex podría tomar medidas contra una cuenta que lo registre. Usa una **cuenta gratuita nueva de Plex** creada solo para rex y luego compártela con tu cuenta. Tu historial, tus amigos y tu Plex Pass se quedan en tu cuenta. [Añádelo a una cuenta de Plex](any-source.md#step-3-add-it-to-a-plex-account) te explica el proceso paso a paso. Usa rex bajo tu propia responsabilidad.

### ¿Qué apps de Plex funcionan? {#which-plex-apps-work}

Hasta qué punto se ha probado cada app de Plex con rex:

| App | Probada |
|---|---|
| Plex Web (app.plex.tv) | La más: navegación, reproducción, conversión, subtítulos, música, Live TV y reproducción fuera de casa con cuentas gratuitas en ambos lados |
| Plex para Android (teléfono) | En un Pixel 6: reproducción, conversión y [descarga desde tu proveedor](direct-download.md). En un emulador: música y Live TV |
| Plexamp | En un emulador de Android: navegación y reproducción de una biblioteca de música, con fotos de artistas y listas de reproducción |
| Plex para iOS | En un iPad: reproducción y conversión. Dolby Vision tiene un bug de la app (abajo) |
| Plex para Apple TV | Reproducción, incluidos los canales en directo de una biblioteca |
| Plex Desktop | Plex para Mac: reproducción y conversión |
| Plezy | En un Pixel 6: reproducción y descarga desde tu proveedor |
| Plex HTPC | Aún no probada |
| Plex para Android TV, NVIDIA Shield, Google TV | Aún no probada |
| Plex para Roku | Aún no probada |
| Apps de Smart TV (Samsung, LG y otras) | Aún no probadas |
| Infuse | Aún no probada |

Fuera de casa, solo se ha probado Plex Web.

### ¿Reproduce 4K, HDR y Dolby Vision? {#does-it-play-4k-hdr-and-dolby-vision}

Sí. Los archivos se reproducen con su calidad original: rex entrega el archivo tal cual a la app, y la app decide lo que puede mostrar. Cuando una app no puede reproducir un archivo tal cual, rex lo convierte, si FFmpeg está configurado ([Conversión de vídeo](any-source.md#converting-video-optional)). Una conversión convierte HDR y Dolby Vision en una imagen estándar (Settings, Transcoder, **Enable HDR tone mapping**, activado por defecto), en la gráfica donde sea posible. Con el runtime de OpenCL de Intel instalado, una máquina Intel pequeña (un J4105) convierte 4K HDR10 y Dolby Vision perfil 5 a 1080p a aproximadamente tiempo real. Sin FFmpeg, un archivo que la app no puede reproducir muestra "This server is not powerful enough to convert video". Cuando todos los títulos muestran eso en todos los dispositivos, FFmpeg no es la solución: vea [Nada se reproduce](#nothing-plays-or-every-app-says-it-is-not-powerful-enough).

**Plex para iOS y Dolby Vision.** Plex para iOS 2026.20.0 se queda en 0:00 cuando reproduce un archivo Dolby Vision tal cual. Un Plex Media Server real que sirve el mismo archivo se atasca de la misma forma, así que el fallo está en la app. Los archivos 4K HDR10 y SDR sí se reproducen.

### ¿Necesito Plex Pass? {#do-i-need-plex-pass}

No. rex le dice a las apps de Plex que la cuenta en la que está registrado tiene Plex Pass, así que reproducir fuera de casa y convertir vídeo funcionan con cuentas gratuitas. Reproducir fuera de casa se comprobó en Plex Web con una cuenta gratuita en ambos lados; otras apps no se han probado fuera de casa. Las ediciones de películas, el Dashboard, las Descargas, el salto de intros y créditos y el resto de [funciones de películas y series](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities) también funcionan. Una app puede seguir aplicando sus propias reglas.

### ¿Puedo descargar para verlo sin conexión? {#can-i-download-for-offline-viewing}

Las **Downloads** de las apps de Plex están disponibles. rex prepara la descarga por su cuenta, ya sea el archivo original o convertido con FFmpeg, y la guarda en una carpeta junto a `rex.db` hasta que la app la descarga. La cuenta en la que está registrado rex siempre puede descargar. Quien comparta contigo necesita que las descargas estén permitidas en su compartido ([Compartir rex](sharing.md#what-each-person-may-see-and-do)). La app también puede aplicar sus propias reglas. Una descarga convertida no incluye los subtítulos de texto. Guardar una descarga en un teléfono y verla sin conexión todavía no se ha probado.

### ¿Pueden usarlo varias personas, cada una con su propio historial? {#can-several-people-use-it-each-with-their-own-history}

Sí. Cada persona con la que compartes rex inicia sesión con su propia cuenta y tiene su propio estado de visto, Continue Watching, valoraciones y listas de reproducción. Cada una puede copiar su historial desde un servidor Plex antiguo ([Trae tu historial de visualización](import-watched.md)). [Comparte rex con familia y amigos](sharing.md) tiene los pasos, incluidas las cuentas gestionadas para niños.

### ¿Qué hardware necesita? {#what-hardware-does-it-need}

Una máquina que esté siempre encendida, con Linux (amd64 o arm64, glibc 2.35 o más reciente, es decir, Ubuntu 22.04 o superior), macOS (Intel o Apple Silicon) o Windows de 64 bits. En un teléfono, tablet o caja TV con Android, [rex para Android](android.md) ejecuta rex y sus addons gratis, y la app solo para patrocinadores zurg+rex, un servidor Plex en tu teléfono, ejecuta zurg y rex juntos (consulta la [guía de Android](../zurg/guides/android.md)).

**Memoria:** asigna 1 GB. Con una biblioteca de 4.062 películas y 656 series, rex usó menos de 500 MB al arrancar y unos 730 MB mientras se navegaba la biblioteca. La conversión de vídeo necesita más además de eso.

**Disco:** ninguno para las películas. rex guarda su biblioteca en `rex.db`. Las descargas y las imágenes que genera el análisis (vistas previas de búsqueda, imágenes de capítulos) también se guardan junto a él, si las usas.

**Conversión:** solo con FFmpeg. Un chip gráfico la hace rápida: una película en 1080p convertida en un chip Intel pequeño empieza en unos 2 segundos. Qué chips usa rex en cada sistema está en [Por plataforma](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#by-platform): en macOS siempre convierte con el procesador.

### ¿Lee mis archivos locales? {#does-it-read-my-local-files}

No. rex nunca escanea una carpeta ni un disco y no necesita montaje. Cada archivo llega desde una fuente por HTTP. Los archivos de tu propio disco también pueden entrar: algo tiene que servirlos y avisarle a rex sobre ellos, como muestra [rex con tu propia app](any-source.md).

### ¿Funciona con Usenet? {#does-it-work-with-usenet}

Sí, a través de una fuente que lee Usenet, como zurg. rex nunca se comunica con un proveedor de Usenet: la fuente lee los archivos y se los sirve a rex como cualquier otro archivo. Configura zurg para ello con [Usenet](../zurg/guides/usenet.md) y apúntalo a rex como se explica en [rex with zurg](with-zurg.md).

### ¿Necesito zurg? {#do-i-need-zurg}

No. zurg es solo una fuente entre otras. rex acepta cualquier cosa que hable su API de feeds:

- [rex con tu propia app](any-source.md): cualquier app que sirva archivos por HTTP
- [rex con tus addons de Stremio](stremio.md): catálogos de addons de Stremio
- [rex con zurg](with-zurg.md): tu cuenta de debrid o Usenet
- [Crear addons para rex](addons.md): videos caseros, grabaciones o canales, con un programa propio, y tres [tutoriales](addon-home-videos.md) para empezar

Varias fuentes pueden llenar las mismas bibliotecas de Movies y TV.

### ¿Tengo que abrir un puerto? {#do-i-need-to-forward-a-port}

No estás en casa. Las apps de Plex en tu red doméstica encuentran rex sin cambiar el router. app.plex.tv también funciona con la dirección HTTPS que [rex-direct](any-source.md#rex-direct) da a un rex reclamado.

rex necesita una dirección propia para ver contenido fuera de casa o para otro hogar. La forma más sencilla es un solo reenvío de puerto ([rex-direct](any-source.md#rex-direct)). Con IPv6 y sin IPv4 pública, usa [rex-direct sobre IPv6](any-source.md#rex-direct-over-ipv6). [Tailscale serve](any-source.md#tailscale-serve) no necesita reenvío de puerto en los dispositivos que ejecutan Tailscale. [Usarlo fuera de tu casa (opcional)](any-source.md#use-it-outside-your-home-optional) compara las opciones.

### ¿Qué no hace? {#what-does-it-not-do}

No hay tuner ni DVR. La música, la TV en vivo y las fotos necesitan una fuente que las envíe. Consulta [Música con rex](music.md) y [TV en vivo con rex](live-tv.md). zurg envía los cómics como fotos, que Plex Web muestra. Las mezclas de radio y las estaciones de Plexamp no están disponibles. rex no tiene relay, así que el uso remoto necesita su propia dirección ([Úsalo fuera de tu casa](any-source.md#use-it-outside-your-home-optional)).

## Después de instalar {#after-you-install}

### ¿Por qué la app muestra una versión de Plex y "Check for Updates"? {#why-does-the-app-show-a-plex-version-and-check-for-updates}

rex se presenta a las apps y a plex.tv como un Plex Media Server, así que las apps muestran un número de versión de Plex Media Server. Ese número no es el de rex. **Check for Updates** siempre responde que el servidor está actualizado: rex nunca se actualiza solo. Para actualizar rex, descarga una nightly más reciente como se explica en [Updating](any-source.md#updating).

### ¿Por qué mi navegador en port 32400/web no abre una biblioteca? {#why-does-my-browser-at-port-32400web-not-open-a-library}

rex no tiene una app web propia. Al abrir `http://<rex's LAN IP>:32400/web` se muestra una página de estado breve. Mira el contenido en una app de Plex o en el navegador en [app.plex.tv](https://app.plex.tv).

![La página que muestra rex en /web mientras todavía no está reclamada](../assets/rex/80-rex-web-page.webp)

### ¿Qué sale de mi equipo? {#what-leaves-my-machine}

- **plex.tv, al inicio y una vez al día, registrado o no:** el id, el nombre y la versión del servidor, para leer la lista pública de versiones de Plex y saber cuál es el número de versión más reciente.
- **plex.tv, una vez registrado en una cuenta de Plex:** el claim, las direcciones del servidor (su dirección LAN y sus direcciones HTTPS) y los nombres de sus bibliotecas.
- **El servicio de metadatos de Plex, una vez registrado:** el id de cada título, para obtener su nombre, póster, resumen y episodios. Una búsqueda de subtítulos, con **Search Subtitles** o con el ajuste automático de subtítulos de una persona, envía el nombre del archivo y su huella digital.
- **Hosts de imágenes, cuando una app los muestra:** peticiones de los pósteres e imágenes que indiquen tus fuentes.
- **DMM, para rex-direct, una vez registrado y después cada 6 horas:** el id del servidor, su token en la cuenta de Plex y su IP LAN. DMM comprueba con plex.tv que el servidor es tuyo, ve tu IP pública y apunta tus nombres de rex-direct hacia ella y hacia la IP LAN. Si la máquina tiene una dirección IPv6 global, rex también la envía, un minuto después de arrancar (o de ser reclamado) y luego cada 6 horas, y cada vez que DMM se conecta a ella para comprobar que llega al mismo servidor. Desactívalo con `REX_DIRECT_URL=off`.
- **Tus fuentes, cuando reproduces o borras:** peticiones de los archivos que reproduces, y borrados (más abajo).
- **Tu antiguo servidor de Plex, solo cuando [traes tu historial de visualizaciones](import-watched.md):** peticiones de tu historial de visualizaciones.
- **Webhooks, solo si configuras alguno:** eventos, a las direcciones que pongas.

rex no le pregunta a nadie qué es una versión: la fuente lo decide y se lo dice a rex. zurg, por ejemplo, le pregunta a DMM ([Por qué DMM coloca los archivos](with-zurg.md#why-dmm-places-the-files)).

### ¿Borrar desde una app de Plex borra el archivo? {#does-deleting-in-a-plex-app-delete-the-file}

Sí. Borrar una película o un episodio desde una app de Plex, con la sesión iniciada en la cuenta en la que está registrado rex, borra sus archivos en el origen, igual que un servidor de Plex borra archivos de su disco. Si el origen es una cuenta de debrid, como zurg, los borra allí. Si el origen se niega, el título se queda y la app dice que no se pudo borrar. Las personas con las que compartes no pueden borrar. [Borrar desde una app de Plex](any-source.md#step-5-watch-something) explica cómo desactivarlo.

### No reproduce nada, o todas las apps dicen que no es lo bastante potente {#nothing-plays-or-every-app-says-it-is-not-powerful-enough}

Mira el log de rex justo después de pulsar Play. Si aparece `upstream failed` o `502`, rex no puede alcanzar tu fuente en la dirección que la fuente le indicó, y instalar FFmpeg no lo arregla. La causa habitual es zurg en Docker Desktop en Windows o macOS. La fila `upstream failed` de [rex con zurg](with-zurg.md#when-something-is-wrong) o [rex con tu propia app](any-source.md#when-something-is-wrong) comprueba la dirección y te dice qué cambiar. Si solo fallan algunos archivos, a menudo solo en un navegador web, el dispositivo no puede reproducirlos tal cual están: configura [Conversión de vídeo](any-source.md#converting-video-optional).

### Un título se asocia mal. ¿Cómo lo arreglo? {#a-title-is-matched-wrong-how-do-i-fix-it}

El origen decide qué es cada archivo, y rex muestra ese título. Inicia sesión con la cuenta en la que está registrado rex y usa **Fix Match**: rex guarda tu elección, y un origen puede leerla para conservarla como la coincidencia de ese lanzamiento, como hace zurg ([Por qué DMM coloca los archivos](with-zurg.md#why-dmm-places-the-files)).

### ¿Dónde consigo ayuda? {#where-do-i-get-help}

[Obtener ayuda](../guides/remote-help.md) indica dónde preguntar y qué incluir: el foro **rex-support** en [Discord](https://discord.com/invite/7u4YjMThXP), y la ayuda remota para patrocinadores.
