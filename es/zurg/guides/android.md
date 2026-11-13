# zurg+rex para Android y Google TV {#zurgrex-for-android-and-google-tv}

The aplicación de Android ejecuta un motor de zurg en el dispositivo y rex junto a él: tu propio servidor de Plex en tu teléfono o en tu caja de TV, para las apps de Plex. Una sola app funciona en teléfonos, tabletas, Android TV y Google TV.
Se requiere Android 8.0 o más reciente. Fire TV puede instalar el mismo APK por sideload. Usa un reproductor WebDAV cuando no tenga una app Files del sistema. Usenet requiere Android de 64 bits; los NZB alojados en TorBox (`torbox_nzb`) no están disponibles en Android.

## Instalar y configurar {#install-and-set-up}

[Descarga un APK](https://zurg.debridmediamanager.com/es/download.html#android) desde la versión nightly del repositorio privado de patrocinadores. Elige `arm64-v8a` para la mayoría de móviles y cajas de TV, `armeabi-v7a` para dispositivos antiguos de 32 bits o `x86_64` para un emulador o un Chromebook compatible. Todos los APK incluyen las interfaces de móvil y de TV.

La app no incluye zurg en sí. Después de iniciar sesión en GitHub, instalas el motor desde dentro de la app. Se necesita una cuenta de patrocinador. Patrocina en [gatekeeper](https://gatekeeper.debridmediamanager.com/) para dar acceso a tu cuenta de GitHub. Setup te guía en el proceso.

Permite la instalación desde la app que uses para abrir el APK. Android o Play Protect podrían pedirte que confirmes la instalación de una app externa. El ID de la aplicación es `com.debridmediamanager.zurg`. Las actualizaciones deben conservar la identidad de firma de la versión publicada.

1. Abre zurg e inicia sesión en GitHub, luego instala una versión del motor. La app no puede iniciar una biblioteca hasta que haya un motor instalado.
2. Añade las cuentas de los proveedores y prueba las credenciales. Los nombres de cuenta distinguen varias cuentas del mismo proveedor. Los límites de conexión de Usenet incluyen a todos los demás consumidores de esa cuenta.
3. Elige Phone, Tablet, TV box o TV stick. Los perfiles establecen el objetivo de memoria del motor y los tamaños de la caché de disco. Un objetivo de heap de Go no es un límite fijo de RSS.
4. Permite las notificaciones y la ejecución en segundo plano. Activa start after reboot si este dispositivo debe servir la biblioteca siempre.
5. Inicia la biblioteca. La primera carga de una cuenta grande puede tardar varios minutos. La notificación y la pantalla Status muestran cuándo están listos los directorios.

## Ver en este dispositivo {#watch-on-this-device}

Usa Library para explorar carpetas y reproducir un archivo. More ofrece otro reproductor o un URI de documento de Android. El reproductor elegido puede convertirse en el reproductor preferido.
Files y los selectores de documentos muestran la misma biblioteca bajo la raíz de almacenamiento de zurg.
Los archivos se transmiten con acceso aleatorio; no se descargan completos antes de reproducirse.
Abre tu reproductor una vez y termina su configuración antes de elegirlo desde Files.

Para los reproductores WebDAV, añade `http://127.0.0.1:9999/dav/` como fuente. Si cambiaste el puerto, usa el que aparece en Status. VLC, Kodi y Nova pueden explorar una fuente WebDAV; los reproductores que solo aceptan URL individuales se pueden abrir desde Library. En la TV, usa el D-pad y Select para moverte y activar los controles, Back para volver, y Menu o More para las acciones del release. Selecciona un campo de texto para editarlo y pulsa Back para volver a la navegación. En un teléfono, la pulsación larga también abre More.

Repair, rename, tags, show all files y delete afectan a todo el release que los contiene. Delete pide confirmación y borra el contenido de la cuenta del proveedor.
MediaInfo usa el ffprobe incluido y muestra los detalles de vídeo, audio y subtítulos en el panel. No necesitas instalar ninguna herramienta multimedia por separado.

## Ver en las apps de Plex {#watch-in-the-plex-apps}

Desde la nightly del 10 de noviembre de 2026, la app también ejecuta rex (en los dispositivos de 64 bits de esa nightly, y en todos los dispositivos compatibles a partir de la nightly del 11 de noviembre), un servidor de medios para las apps de Plex, y le indica a zurg que lo use. Así tu biblioteca aparece en las apps oficiales de Plex y en Plezy, tanto en este dispositivo como en otros de tu casa. Cuando tu biblioteca esté en marcha, Status muestra **rex for the Plex apps**: elige **Sign in to Plex** y aprueba el inicio de sesión (en una TV, introduce el código en plex.tv/link). El servidor aparece en Plex con el nombre de este dispositivo. rex convierte lo que un reproductor no puede reproducir usando el codificador por hardware del dispositivo. Para desactivar rex, ve a Settings, Connection; zurg dejará entonces de enviarle contenido.

## Compartir por la red local {#share-over-the-local-network}

En Ajustes, activa **Expose on local network**. zurg genera credenciales y muestra la dirección WebDAV de la LAN del dispositivo. Introduce esa dirección y esas credenciales en un reproductor del otro dispositivo. Mantén el host Android encendido y en funcionamiento. La autenticación básica HTTP no cifra el tráfico; usa una red local de confianza. Loopback es la opción por defecto. Los intents del reproductor nunca contienen la contraseña de tu servidor.

## Ajustes, copias de seguridad y actualizaciones {#settings-backups-and-updates}

Settings cubre la conexión, los proveedores, la biblioteca, la reparación, los recursos y los registros.
Advanced acepta YAML sin procesar y pide al motor instalado que lo valide antes de
guardarlo. Settings no tiene un campo para tu clave de API de DMM: añade
`dmm_api_key: YOUR_DMM_API_KEY` en Advanced para la [lista de deseados de DMM](dmm-wanted.md)
y para el nombrado de releases de DMM. Si guardas una configuración mientras el servidor está en marcha, la app te pregunta antes de reiniciarlo.
Web dashboard abre el panel local para los ajustes de integración con el escritorio.

Logs incluye la salida reciente del motor y las últimas 200 líneas del supervisor.
Los registros compartidos ocultan los secretos y las URL configurados. Las copias de seguridad contienen credenciales y el estado de la biblioteca, así que guárdalas en un lugar privado. Detén zurg antes de restaurar. Android rechaza los enlaces de copia de seguridad y los archivos especiales, y restaura primero en loopback.

Updates comprueba el repositorio privado de patrocinadores. El inicio de sesión de dispositivo de GitHub solicita el scope `repo`, porque los assets de las releases son privados. Los tokens de GitHub se cifran con preferencias respaldadas por Android Keystore. También se admite un token que tú mismo proporciones, siempre que tenga acceso de lectura al repositorio. Si Android ya no puede descifrar un inicio de sesión guardado, Updates te pide que vuelvas a iniciar sesión y conserva la configuración de tu biblioteca. Las actualizaciones descargadas deben coincidir con el application ID y la clave de firma, y tener un version code más nuevo. El instalador de Android pide confirmación antes de reemplazar la app.

Si actualizas desde una compilación que incluía su propio motor, la app se queda sin motor. Instala un motor desde Updates una sola vez, y tus proveedores y la configuración de tu biblioteca se mantendrán sin cambios.

La app y el motor se actualizan por separado. Updates lista las versiones del motor entre las 30 releases más recientes del repositorio de patrocinadores, marca la que tienes instalada e instala cualquiera de ellas. Si una nueva nightly da problemas en tu dispositivo, instala la que te funcionaba. Detén tu biblioteca en Status antes de cambiar el motor. La app solo ejecuta un paquete de motor firmado con su propia clave, y lo vuelve a comprobar en cada inicio.

La notificación persistente tiene una acción Stop. Un mosaico de Quick Settings también inicia o detiene el servidor. La exención de batería ayuda con los límites de inactividad de Android; los gestores de tareas específicos de cada fabricante pueden necesitar ajustes adicionales de [Don't kill my app](https://dontkillmyapp.com/).
