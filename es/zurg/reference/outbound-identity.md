# Identidad de la solicitud saliente {#outbound-request-identity}

`user_agent` controla el User-Agent HTTP compartido para las APIs de debrid y las lecturas de CDN,
las búsquedas de Newznab, las descargas de NZB, OpenSubtitles, las sondas de ffprobe,
las integraciones con servidores de medios, las descargas de dependencias, las actualizaciones
y las exportaciones opcionales de compartir o de registros. El valor por defecto es un agente
de navegador genérico. Si lo dejas en blanco, se restaura ese valor; un valor personalizado
explícito se envía tal cual lo escribiste, aunque identifique la aplicación.
`omit_user_agent: true` hace que los clientes HTTP de Go no envíen la cabecera User-Agent y le da
a ffprobe un agente vacío, anulando la cadena configurada. Algunos servicios pueden rechazar
las peticiones sin agente. GitHub rechaza todas con un 403, así que las peticiones a GitHub
(`zurg update` y las descargas de rclone y ffprobe) siguen llevando el agente configurado,
o el agente de navegador genérico si no hay ninguno definido.

Plex, Jellyfin y Emby también requieren metadatos de cliente y dispositivo. Configúralos con
`outbound_client_name`, `outbound_client_id`, `outbound_client_version`,
`outbound_device_name`, `outbound_device_id` y `outbound_platform`. Los valores por defecto son
`Media Client`, `media-client`, `1.0`, `Media Client`, `media-client` y `Desktop`, respectivamente.
Plex usa el ID de cliente para las peticiones de autenticación, escaneo y metadatos; Jellyfin y Emby
usan el ID de dispositivo en sus metadatos de autenticación. Los campos solo se usan donde el
protocolo los admite. Cambiar los IDs puede hacer que aparezca como un cliente o dispositivo
distinto en el servidor de medios.

Todos estos ajustes están disponibles en Network & Connectivity en el panel. El panel muestra los
valores guardados con los valores por defecto ya resueltos. Reiniciar aplica los ajustes juntos;
guardar no cambia la identidad en ejecución. Los valores deben ser ASCII imprimible, de como
máximo 2048 caracteres; los campos de cliente y dispositivo no pueden contener comillas ni barras
invertidas. Los tokens de autenticación y los nombres de cabeceras del protocolo no cambian,
incluida la credencial `X-Zurg-Token` que DMM requiere.

Los clientes de proveedores e indexadores eliminan las cabeceras `Referer`, `Origin` y `X-Zurg*`
antes de enviar las peticiones, incluidas las redirecciones. Las redirecciones no pueden revelar,
mediante un Referer, las rutas privadas de las URL anteriores ni los parámetros de API key en la
query. La autenticación, las peticiones de rango, las cookies de proveedor y los límites de
redirección se mantienen. No se añaden identificadores de cliente o dispositivo de la aplicación
a estas peticiones.

NNTP envía `AUTHINFO USER`, `AUTHINFO PASS`, `BODY`, `STAT`, `DATE` y `QUIT` según haga falta,
sin ningún comando de identificación de software. No hay ningún ID de software NNTP que configurar.
Los nombres de usuario y las contraseñas siguen en la configuración NNTP de cada proveedor. Las
pruebas de transcripciones TLS y en texto plano cubren la autenticación, el acceso a artículos, el
keep-alive y el cierre.

Esto reduce al mínimo los identificadores explícitos de la aplicación; no proporciona anonimato.
Los servicios remotos siguen viendo credenciales, IPs de origen, contenido solicitado y tiempos.
El comportamiento de TLS y HTTP, las identidades personalizadas, las API keys registradas por la
aplicación y los patrones de acceso (incluidos los enlaces de prueba de red de Real-Debrid) pueden
permitir correlacionar actividad. Las URL suministradas externamente, los metadatos de torrents,
los IDs de artículos, los payloads de compartir y el contenido de los registros o la configuración
exportados no se reescriben. Las URL de descarga de software identifican el software que se
solicita. Los reproductores externos y las herramientas lanzadas por separado usan sus propios
ajustes.

Las pruebas de regresión a nivel de socket cubren los valores por defecto, los agentes personalizados
y omitidos, las redirecciones, la autenticación conservada y los metadatos del servidor de medios.
Las pruebas de configuración y de panel cubren la validación, los ciclos de ida y vuelta de YAML y
la aplicación de los ajustes al reiniciar.
