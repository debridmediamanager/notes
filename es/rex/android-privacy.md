# rex para Android: política de privacidad {#rex-for-android-privacy-policy}

*Última actualización: 16 de noviembre de 2026.*

rex para Android ejecuta un servidor multimedia en tu dispositivo. No tiene cuenta con nosotros, ni anuncios, ni analíticas, y no nos envía tu biblioteca, lo que ves ni nada sobre ti, salvo por rex-direct y los registros que elijas enviar, ambos mencionados más abajo.

## Qué sale de tu dispositivo y adónde va {#what-leaves-your-device-and-where-it-goes}

| Dónde | Qué | Cuándo |
|---|---|---|
| **plex.tv** (Plex, Inc.) | Una solicitud de código de inicio de sesión (en un teléfono o tableta, y otra para la página de inicio de sesión de Plex) con un identificador de app aleatorio y el nombre de este servidor; luego, una vez que apruebas una, una solicitud única para un código de reclamación | Cuando eliges Sign in to Plex |
| **plex.tv** | El nombre del servidor, su identificador, la versión y las direcciones a las que pueden llegar las apps de Plex | Mientras rex se ejecuta y tiene sesión iniciada, como cualquier servidor de Plex se informa a sí mismo |
| **Servicio de metadatos de Plex** | Los ids de los títulos que añaden tus addons, para obtener pósters y descripciones | Mientras rex se ejecuta y tiene sesión iniciada |
| **debridmediamanager.com** (rex-direct) | El identificador del servidor, el token de servidor que le dio Plex, sus direcciones IP local y pública y su puerto | Una vez iniciada la sesión, y luego cada 6 horas, para que las apps de Plex puedan llegar a rex por HTTPS fuera de casa |
| **logs.debridmediamanager.com** (registros de soporte) | Las versiones de la app y de rex, el modelo del dispositivo, la versión de Android y el tipo de procesador, el puerto y el estado de rex, el nombre, la versión, el repositorio, el estado, la cantidad de títulos, la última sincronización y el último error de cada addon, el desfase de la zona horaria, y los registros de la app de esta ejecución y de la anterior, con los tokens, claves, contraseñas y las dos últimas partes de las direcciones IP públicas ocultas. Nunca tus ajustes de addons, tu cuenta de Plex ni tus tokens | Solo cuando pulsas Send bajo Send logs to support, después de ver todo. Recibes un código para dar a soporte; solo el personal de soporte puede leerlo, y se borra después de 7 días |
| **Repositorios de addons que añades** (como github.com) | Una solicitud del contenido del repositorio | Cuando añades o actualizas un repositorio |
| **Sitios de cada addon** | Lo que pide el addon, como una solicitud de catálogo a archive.org | Cuando un addon se sincroniza o se reproduce un título |

Tu contraseña de la cuenta de Plex nunca pasa por la app: inicias sesión en la página de Plex.
El token de cuenta que te da ese inicio de sesión se usa una sola vez para reclamar el servidor y luego se descarta. rex
solo conserva el token de servidor que Plex le emite.

## Qué se queda en tu dispositivo {#what-stays-on-your-device}

Tu biblioteca, el historial de reproducción, la configuración de los complementos (incluidas las claves que escribas) y los registros. La app guarda los registros de esta sesión y de la anterior para que un fallo no los pierda. Los registros ocultan tokens, claves, contraseñas y el final de las direcciones IP públicas, y solo salen del dispositivo si eliges Compartir o Enviar registros a soporte en la pantalla Registros. Al desinstalar la app se borra todo.

## Complementos {#addons}

Un addon es código de quien lo escribió, instalado desde un repositorio que tú añadiste. Se ejecuta aislado del resto de tu dispositivo y solo puede conectarse a los sitios que indica, que rex te muestra antes de instalarlo. Instala addons solo de personas en las que confíes.

Un addon que necesita una cuenta en su sitio web inicia sesión con un código: lo introduces en la propia página de ese sitio web, así que tu contraseña nunca pasa por la app. El token que el sitio web entrega después al addon se queda en tu dispositivo y solo vuelve a ese mismo sitio web. Al quitar el addon, se borra.

## Menores {#children}

La aplicación no está dirigida a menores de edad.

## Contacto {#contact}

support@debridmediamanager.com
