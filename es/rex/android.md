# rex para Android {#rex-for-android}

rex es un servidor multimedia para las apps de Plex que no posee ningún archivo. rex para Android lo ejecuta en un teléfono, tableta, Android TV, Google TV o Fire TV, sin necesidad de computadora. Las apps de Plex de tus dispositivos lo encuentran como cualquier servidor de Plex y reproducen desde él.

Lo que se reproduce viene de **addons**. Empieza con las películas de dominio público del Internet Archive. Más addons, como tus addons de Stremio, YouTube y Spotify, se instalan desde dentro de la app.

rex para Android es gratis. ¿Quieres también tus cuentas de debrid y Usenet? zurg+rex, un servidor de Plex en tu teléfono con zurg integrado, llega con un patrocinio: consulta [zurg+rex para Android](../zurg/guides/android.md).

## Antes de empezar {#before-you-start}

| Necesitas | Por qué |
|---|---|
| Un dispositivo con Android 8.0 o más reciente | Teléfono, tablet, Android TV, Google TV o Fire TV |
| Una cuenta de Plex | rex aparece en las apps de Plex con las que inicias sesión. Una cuenta gratuita basta |
| Una app de Plex en el dispositivo con el que ves contenido | Plex para Android, Android TV, iPhone, una smart TV, Plex Web, Plexamp |

Todavía no está en Google Play. Tú mismo instalas el archivo de la app (APK).

## Paso 1. Descárgala {#step-1-download-it}

En el dispositivo, descarga el archivo para su procesador. Cada enlace siempre apunta a la versión más reciente:

| Tu dispositivo | Descarga |
|---|---|
| La mayoría de teléfonos, tablets y cajas de TV (64 bits) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| Cajas de 32 bits más antiguas o baratas, entre ellas los Fire TV Stick | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| Emuladores en una PC | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

Todas las versiones y sus cambios están en [la página de releases](https://github.com/debridmediamanager/rex-android/releases).

¿No estás seguro? Prueba primero con `arm64-v8a`. Un solo archivo funciona tanto en teléfonos como en TV.

## Paso 2. Instálala {#step-2-install-it}

Abre el archivo descargado. Android te pregunta primero:

1. Te dice que **no puede instalar aplicaciones desconocidas desde esta fuente**. Pulsa **Settings**, activa **Allow from this source** y vuelve atrás.
2. Pulsa **Install**.

En una caja de TV sin navegador, descarga el archivo con una app de descargas que pueda abrir APK.

**Lo que deberías ver.** **rex** en tu lista de aplicaciones.

## Paso 3. Inicia rex {#step-3-start-rex}

Abre **rex**. La primera pantalla dice **Welcome to rex.**

1. Pulsa **Allow notifications** y luego **Allow**. rex se ejecuta en segundo plano con una notificación, y desde ahí puedes detenerlo.
2. Pulsa **Let rex keep running in the background**. En la lista que se abre, elige **rex** y selecciona **Don't optimize**. En Android más reciente, es **Allow background usage** y luego **Unrestricted**. Vuelve a rex. Ahora ambos botones empiezan con un ✓.
3. **Name** es el nombre que las apps de Plex muestran para este servidor. Cámbialo si quieres.
4. Deja **Port** en `32400`. Si ya hay otro servidor de Plex ejecutándose en este dispositivo, rex muestra **Another app here already uses this port, maybe a Plex server. Try 32500.** Escribe `32500`.
5. Pulsa **Start rex**.

**Lo que deberías ver.** **2 / 2** y **Sign in to Plex**.

## Paso 4. Inicia sesión en Plex {#step-4-sign-in-to-plex}

Pulsa **Sign in to Plex**. rex muestra un código: **On any phone or computer, go to plex.tv/link and enter** it.

- **En un teléfono o tableta** tu navegador también abre una página de Plex que dice **rex for Android would like to sign in to your Plex account**. Inicia sesión ahí.
- **En un TV** ve a [plex.tv/link](https://plex.tv/link) desde tu teléfono o computadora, inicia sesión e introduce el código.

Usa la cuenta con la que tus apps de Plex tienen sesión iniciada. Puedes pulsar **Skip for now** e iniciar sesión más tarde desde **Status**.

**Lo que deberías ver.** **Signed in. rex shows up in the Plex apps as** el nombre de tu servidor. Pulsa **Done**. **Status** dice **RUNNING** y **Ready for the Plex apps.**

## Paso 5. Mira en una app de Plex {#step-5-watch-in-a-plex-app}

Abre cualquier app de Plex con la misma cuenta. Si Plex está en este dispositivo, **Status** tiene un botón **Open Plex**.

En Plex para Android, abre **Libraries**, luego **All Libraries** y después **Movies** bajo el nombre de tu servidor. Otras apps de Plex también muestran la biblioteca bajo el nombre del servidor.

La primera sincronización de Internet Archive tarda un rato: unos treinta minutos en nuestro dispositivo de prueba, mientras rex comprueba cada película. **Status** muestra **Syncing** hasta que termina, y luego el recuento, como **Ready · 97 titles**. Dale a play a cualquier película.

## Complementos {#addons}

**Addons** muestra lo que tienes instalado. Cada uno enseña sus títulos y cuándo se sincronizó por última vez. Sus botones son **Sync now**, **Settings**, **Log** y **Remove**; en el móvil, desliza la fila de botones hacia los lados para verlos todos. El interruptor **Enabled** apaga un addon sin quitarlo.

Los addons vienen de **repositories**: repositorios de git que contienen addons. La app empieza con [rex-addons](https://github.com/debridmediamanager/rex-addons) añadido, que ofrece:

| Addon | Qué trae |
|---|---|
| Internet Archive | Películas de dominio público. Instalado desde el principio |
| Stremio addons | El catálogo de películas y series de tus addons de Stremio, reproducido desde los streams que te dan tus addons de streams |
| YouTube | Tus listas de reproducción de YouTube. Inicias sesión con un código |
| Spotify | Tu biblioteca de Spotify como música para Plex y Plexamp. Necesita el addon de YouTube, con sesión iniciada |

**Instala uno.** En **Repositories**, pulsa **Addons** junto a un repositorio, luego **Install** debajo del addon. rex muestra a qué sitios web puede acceder y te vuelve a preguntar una vez, y después empieza a sincronizarlo.

**Inicia sesión.** Un addon que necesita tu cuenta dice **Sign in to start.** Pulsa su botón **Sign in**: ve a la página que indica en cualquier dispositivo e introduce el código que aparece.

**Añade un repositorio.** En **Add a repository**, escribe su enlace (`github.com/user/repo` basta) y pulsa **Add**. Instala solo desde personas en las que confíes. Para escribir tu propio addon, mira [rex-addons](https://github.com/debridmediamanager/rex-addons).

## Mira en otros dispositivos de tu casa {#watch-on-other-devices-at-home}

Cada app de Plex que haya iniciado sesión con la misma cuenta encuentra rex en tu red doméstica por su nombre: tu TV, otro móvil, Plex Web en un ordenador. **Status** muestra la dirección de rex en casa, como `http://192.168.1.20:32400`.

Si quieres que tu familia vea contenido con sus propias cuentas de Plex, consulta [Comparte rex con familia y amigos](sharing.md).

## Mantenlo en funcionamiento {#keep-it-running}

- rex se ejecuta mientras el dispositivo está encendido. El botón **Stop** de la notificación lo detiene; **Status** tiene **Start**, **Stop** y **Restart**.
- En **Settings**, activa **Start when this device turns on**. Si no, abre rex y pulsa **Start** después de reiniciar.
- Algunos teléfonos siguen deteniendo las apps en segundo plano. [Don't kill my app](https://dontkillmyapp.com/) explica lo que necesita la tuya.
- Para cambiar el nombre del servidor, abre **Settings**, **General** en una app de Plex y cambia **Friendly name**.

## Límites {#limits}

- **Se reproduce en casa.** Fuera de casa, las apps de Plex necesitan una dirección HTTPS que llegue al dispositivo, y eso requiere un reenvío de puertos en tu router hacia él. Consulta [Usar fuera de tu casa](any-source.md#use-it-outside-your-home-optional).
- **El dispositivo es el servidor.** Mantenlo encendido, conectado por Wi-Fi o Ethernet, y enchufado. Convertir vídeo para un reproductor que no puede reproducir un archivo usa el hardware del propio dispositivo y puede ir lento en una caja barata.
- **Solo lo que traen los addons.** No tiene una biblioteca de archivos en el propio dispositivo.
- **Todavía no está en Google Play.** Para actualizar, instala el archivo nuevo desde [las releases](https://github.com/debridmediamanager/rex-android/releases/latest) encima del anterior, y luego abre rex y pulsa **Start**. Tu inicio de sesión y tus addons se mantienen.

## Solución de problemas {#troubleshooting}

| Lo que ves | Qué hacer |
|---|---|
| **App not installed as app isn't compatible with your phone.** | Elegiste el archivo equivocado para el procesador. Prueba con el otro de la tabla del Paso 1 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | Escribe `32500` como puerto |
| **Use a number from 1024 to 65535** | El puerto debe ser un número en ese rango |
| The server isn't in the Plex app | Inicia sesión en la app de Plex con la misma cuenta que usaste en el Paso 4, y mantén ambos dispositivos en la misma red doméstica |
| The library is empty | La primera sincronización sigue en marcha: espera hasta que **Status** muestre un número de títulos |
| **Sign in needed** under an addon | Pulsa su botón **Sign in** e introduce el código |
| **That isn't a repository link. Try github.com/user/repo.** | Escribe el enlace del repositorio, como `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | El enlace está mal o el repositorio es privado. Compruébalo en un navegador |
| rex stops when the screen is off | Repite el ajuste de segundo plano del Paso 3, y consulta [Don't kill my app](https://dontkillmyapp.com/) |

**Logs** muestra lo que rex y los addons han dicho recientemente, con las claves y contraseñas ocultas. Si el soporte te pide los logs, pulsa **Send logs to support**: verás todo antes de que se envíe nada, luego pulsa **Send** y publica el código que recibas.

¿Atascado? Pregunta en el foro **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP).
