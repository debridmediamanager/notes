# zurg+rex para Android y Google TV {#zurgrex-for-android-and-google-tv}

zurg+rex es un servidor de Plex en tu teléfono. zurg trae tus cuentas de debrid y Usenet, y rex las sirve a todas las apps de Plex de tu casa, con pósters, temporadas y progreso de reproducción. Funciona en un teléfono, tablet, Android TV, Google TV o Fire TV, sin necesidad de ordenador.

Viene con un patrocinio. ¿No tienes patrocinio? [rex para Android](../../rex/android.md) es gratis y reproduce lo que traen sus addons.

| La app | En la app de Plex | En cualquier otra app de Plex |
|---|---|---|
| ![Estado en zurg+rex con la biblioteca lista y rex con sesión iniciada en Plex](../../assets/zurg/android-status.webp) | ![Big Buck Bunny en su página en la app de Plex, servido desde el mismo teléfono](../../assets/zurg/android-plex.webp) | ![La misma biblioteca de películas abiertas en la app Plezy](../../assets/zurg/android-plezy.webp) |

## Antes de empezar {#before-you-start}

| Necesitas | Por qué |
|---|---|
| Un dispositivo con Android 8.0 o más reciente | Teléfono, tableta, Android TV, Google TV o Fire TV. Usenet necesita un dispositivo de 64 bits |
| Un patrocinio con tu cuenta de GitHub vinculada | La app y su motor se descargan desde el repositorio del patrocinador. Patrocina y vincula GitHub en [gatekeeper](https://gatekeeper.debridmediamanager.com/) |
| Una cuenta de debrid o una cuenta de Usenet | Lo que zurg trae a la biblioteca. Los NZB alojados en TorBox (`torbox_nzb`) no están disponibles en Android |
| Una cuenta de Plex | rex aparece en las apps de Plex con la sesión iniciada. Una cuenta gratuita basta |
| Tu API key de DMM, desde gatekeeper (opcional) | Con ella, más títulos obtienen su nombre y póster |

## Paso 1. Descárgala {#step-1-download-it}

En el dispositivo, abre la [página de descarga](https://zurg.debridmediamanager.com/es/download.html#android), con la sesión iniciada en GitHub con tu cuenta de patrocinador, y elige el archivo para su procesador:

| Tu dispositivo | Archivo |
|---|---|
| La mayoría de teléfonos, tabletas y cajas de TV (64 bits) | `android-arm64-v8a.apk` |
| Teléfonos de 32 bits más antiguos y sticks de TV | `android-armeabi-v7a.apk` |
| Chromebooks y emuladores | `android-x86_64.apk` |

Un solo archivo funciona igual en teléfonos y en TVs.

**¿GitHub dice 404?** La cuenta con la que has iniciado sesión todavía no tiene acceso de patrocinador. Si acabas de patrocinar, primero [acepta la invitación](https://github.com/debridmediamanager/zurg/invitations); las invitaciones se envían en un máximo de 15 minutos.

## Paso 2. Instálala {#step-2-install-it}

Abre el archivo descargado y permite la instalación desde la app que lo abrió. Android o Play Protect pueden pedirte que confirmes.

**Lo que deberías ver.** **zurg+rex** en tu lista de apps.

## Paso 3. Inicia sesión en GitHub e instala el motor {#step-3-sign-in-to-github-and-install-the-engine}

Abre la app. Dice **Welcome to zurg+rex.**

1. Pulsa **Sign in with GitHub**. La app muestra un código: pulsa **Open GitHub**, introduce el código y aprueba. GitHub pide acceso a `repo` porque las versiones para patrocinadores son privadas.
2. **Instala el motor.** El motor son el propio zurg y rex, guardados en un paquete aparte para que se actualicen por separado de la app. Pulsa **Install**. Android pregunta antes de instalarlo: permítelo.

**Lo que deberías ver.** **Add your providers.**

## Paso 4. Añade tus proveedores {#step-4-add-your-providers}

1. Pulsa **Add an account** y elige el proveedor.
2. Para una cuenta de debrid, pega su token en **Provider token**. Para Usenet, rellena **NNTP server**, **Port**, **Username**, **Password** y **Connections**.
3. Pulsa **Test account** y luego **Add provider**.

Añade todas las cuentas que tengas; **Account name** sirve para distinguir dos cuentas de un mismo proveedor. El límite de conexiones de una cuenta de Usenet cuenta a todas las demás apps y dispositivos que la usen.

## Paso 5. Inicia tu biblioteca {#step-5-start-your-library}

1. Elige **Phone**, **Tablet**, **TV box** o **TV stick**. Las opciones más pequeñas usan menos memoria y cachés más pequeños.
2. Permite las notificaciones y deja que la app se ejecute en segundo plano. Activa **Start after reboot** si este dispositivo debe servir tu biblioteca todo el tiempo.
3. Pulsa **Start my library**.

**Lo que deberías ver.** **Status** muestra **Ready for your players** y cuenta tus releases. La primera carga de una cuenta grande puede tardar varios minutos.

## Paso 6. Inicia sesión en Plex {#step-6-sign-in-to-plex}

En **Status**, debajo de **rex for the Plex apps**, pulsa **Sign in to Plex**.

- **En un móvil o tableta** tu navegador abre la página de inicio de sesión de Plex. Inicia sesión ahí.
- **En una TV** la app muestra **On any device, go to plex.tv/link and enter** seguido de un código. Introdúcelo en tu móvil u ordenador.

Usa la cuenta con la que tienes iniciada sesión en tus apps de Plex.

**Qué deberías ver.** **Ready for the Plex app**, con un botón **Open Plex** cuando Plex esté en este dispositivo.

## Paso 7. Mira contenido en una app de Plex {#step-7-watch-in-a-plex-app}

Abre cualquier app de Plex con la misma cuenta: en este dispositivo, en tu TV, en otro móvil o en un ordenador de casa. Tu servidor aparece con el nombre de este dispositivo, con las bibliotecas **Debrid Movies** y **Debrid TV**. Pulsa reproducir.

rex convierte lo que un reproductor no puede reproducir, usando el codificador de vídeo del propio dispositivo.

## Obtén más títulos con nombre {#get-more-titles-named}

Abre **Settings**, **Library** y pega tu clave de API de DMM en **Dmm api key**, luego guarda. zurg entonces le pregunta a DMM qué es cada archivo. Sin la clave, zurg lo deduce a partir del nombre del lanzamiento, y menos títulos obtienen su nombre y póster.

Un título que aún parece incorrecto se puede corregir en una app de Plex: abre su menú **⋯** y elige **Fix Match**.

El campo está en las nightly desde el 14 de noviembre de 2026. En una más antigua, añade `dmm_api_key: YOUR_DMM_API_KEY` en **Settings**, **Advanced**. La misma clave sirve para leer tu [lista de deseados de DMM](dmm-wanted.md).

## Complementos {#addons}

Los addons añaden más contenido para ver en rex, además de tu biblioteca. Abre **Addons**: el addon de Internet Archive viene instalado y añade películas de dominio público, y el repositorio [rex-addons](https://github.com/debridmediamanager/rex-addons) ya aparece en la lista. Añade otro repositorio con su enlace, ábrelo e instala lo que ofrezca.

Cada addon indica a qué sitios web puede acceder, y una actualización que llegue a sitios nuevos te pide permiso antes. Instala addons solo de personas en las que confíes. **Log** muestra lo que un addon ha hecho recientemente. Al quitar un addon, solo se eliminan sus títulos.

## Otros reproductores en este dispositivo {#other-players-on-this-device}

No necesitas una app de Plex para ver.

- **Library** navega por tus carpetas y reproduce un archivo en el reproductor que elijas. **More** ofrece otro reproductor y las acciones de la release: repair, rename, tags, show all files y delete. Actúan sobre toda la release, y delete pide confirmación antes de borrarla de tu cuenta del proveedor.
- La app **Files** y los selectores de documentos muestran la misma biblioteca bajo la raíz de zurg. Abre tu reproductor una vez y termina su configuración antes de elegirlo desde Files.
- Reproductores WebDAV como VLC, Kodi y Nova usan `http://127.0.0.1:9999/dav/` como origen. **Status** muestra la dirección si cambiaste el puerto.

En una TV, muévete con el D-pad y Select, vuelve atrás con Back, y abre las acciones de una release con Menu o **More**. Selecciona un campo de texto para escribir en él y pulsa Back para seguir.

## Comparte con otros reproductores en casa {#share-with-other-players-at-home}

Las apps de Plex en casa no necesitan nada más: encuentran rex por sí solas. Para un reproductor WebDAV en otro dispositivo, abre **Settings**, **Connection** y activa **Expose on local network**. zurg crea un nombre de usuario y una contraseña y muestra la dirección que hay que introducir en ese reproductor.

Usa esto en una red en la que confíes: la contraseña viaja sin cifrar. Está desactivado hasta que lo actives.

## Mantenlo en funcionamiento {#keep-it-running}

- La notificación muestra el estado del servidor y tiene **Stop**. Un mosaico de Ajustes rápidos también lo inicia y lo detiene.
- Algunos teléfonos detienen las apps en segundo plano de todos modos. [Don't kill my app](https://dontkillmyapp.com/) explica lo que necesita la tuya.
- **Updates** busca una app nueva y un motor nuevo; se actualizan por separado. Si un nightly nuevo da problemas en tu dispositivo, pulsa **Show engine versions** e instala el que funcionaba. Detén tu biblioteca en **Status** primero.
- **Settings** tiene **Create backup** y **Restore backup**. Una copia de seguridad guarda tus contraseñas y tokens, así que mantenla en privado. Detén tu biblioteca antes de restaurar.
- Desactiva rex en **Settings**, **Connection**, **rex for the Plex apps**. Así zurg deja de alimentarlo.

## Qué envía la app y a dónde {#what-the-app-sends-and-where}

zurg+rex no tiene anuncios ni analítica. Esto es todo lo que sale de tu dispositivo:

| Dónde | Qué | Cuándo |
|---|---|---|
| GitHub | Tu inicio de sesión, luego las peticiones para las versiones de los patrocinadores | Cuando inicias sesión y cuando **Updates** comprueba si hay novedades |
| Tus proveedores | Tu token de cuenta o tu inicio de sesión de Usenet, y las peticiones para tu biblioteca y tus archivos | Mientras tu biblioteca está en funcionamiento |
| debridmediamanager.com | Los nombres de tus releases, para saber qué es cada uno, con tu clave API de DMM si la introdujiste | Mientras tu biblioteca funciona con rex activado |
| plex.tv y el servicio de metadatos de Plex | Una petición de código de inicio de sesión; luego el nombre y la dirección del servidor, y los ids de tus títulos, para obtener pósters y descripciones | Cuando inicias sesión en Plex, y mientras rex funciona con sesión iniciada |
| debridmediamanager.com (rex-direct) | El identificador de rex, el token de servidor que te dio Plex, sus direcciones IP y su puerto, para que las apps de Plex puedan conectarse por HTTPS | Una vez que has iniciado sesión en Plex, y después cada 6 horas |
| Los sitios web de cada addon y los repositorios que añades | Lo que pide el addon | Cuando un addon se sincroniza o se reproduce un título |
| logs.debridmediamanager.com | Versiones, modelo del dispositivo, los logs de la app y del motor, y tu configuración, con las claves, contraseñas y tokens sustituidos por `[redacted]` | Solo cuando pulsas **Send** en **Send logs to support**, después de revisar todo. Se borran a los 7 días |

Tu token de GitHub se guarda cifrado en el dispositivo. Al desinstalar la app se borra todo lo que guardaba.

## Límites {#limits}

- **El dispositivo es el servidor.** Mantenlo encendido, conectado y enchufado. Convertir vídeo es lento en una caja barata.
- **Se reproduce en casa.** Fuera de casa, las apps de Plex necesitan una dirección HTTPS que llegue al dispositivo, lo que requiere un port forward en tu router. Consulta [Use it outside your home](../../rex/with-zurg.md#use-it-outside-your-home-optional).
- **Usenet requiere Android de 64 bits.** Un dispositivo de 32 bits solo ejecuta bibliotecas de debrid.
- **No está en Google Play.** Se actualiza desde dentro de la app, en **Updates**.

## Solución de problemas {#troubleshooting}

| Lo que ves | Qué hacer |
|---|---|
| GitHub responde 404 en la página de descarga | Inicia sesión en GitHub con tu cuenta de patrocinador y [acepta la invitación](https://github.com/debridmediamanager/zurg/invitations). Aún no eres patrocinador: [gatekeeper](https://gatekeeper.debridmediamanager.com/) |
| **No engine is installed. zurg needs one before it can serve your library.** | Pulsa **Install an engine** y permite que Android lo instale |
| **No engine is available in the sponsor releases for this device yet.** | La nightly más reciente no tiene un engine para tu procesador. Pregunta en support |
| **This is a 32-bit device. Debrid libraries are supported; Usenet needs 64-bit Android.** | Añade una cuenta de debrid o usa un dispositivo de 64 bits para Usenet |
| **The Plex code expired. Ask for a new one.** | Pulsa **Sign in to Plex** otra vez e introduce el nuevo código en menos de 10 minutos |
| The server isn't in the Plex app | Inicia sesión en la app de Plex con la cuenta que usaste en el paso 6, y mantén ambos dispositivos en la misma red doméstica |
| Los títulos muestran un nombre de archivo y no tienen póster | Introduce tu API key de DMM (consulta [Get more titles named](#get-more-titles-named)), o usa **Fix Match** en una app de Plex |
| Se detiene cuando la pantalla se apaga | Vuelve a permitir el uso en segundo plano y consulta [Don't kill my app](https://dontkillmyapp.com/) |
| Una actualización deja la app sin engine | Instala un engine desde **Updates** una vez. Tus proveedores y ajustes se mantienen |

Si support pide logs, abre **Logs** y pulsa **Send logs to support**. Verás todo antes de que se envíe nada; luego pulsa **Send** y publica el código que obtengas.

¿Atascado? Pregunta en el foro **zurg-support** de [Discord](https://discord.com/invite/7u4YjMThXP).
