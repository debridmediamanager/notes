# TorBox en DMM {#torbox-in-dmm}

DMM funciona con un plan de pago de TorBox: Essential, Standard o Pro. Pega tu clave de API desde [torbox.app/settings](https://torbox.app/settings) en la página **Connect Torbox** de DMM y luego busca: los lanzamientos que TorBox ya tiene aparecen como **Instant TB**. El plan gratuito no tiene acceso a la API, así que DMM no puede usarlo, y enviar lanzamientos de Usenet a TorBox requiere Pro.

## Iniciar sesión {#sign-in}

1. En [debridmediamanager.com](https://debridmediamanager.com) pulsa **Login with Torbox**. ¿Ya iniciaste sesión con otro servicio? Abre **Debrid services** en la página de inicio y pulsa **Torbox Login**.
2. Pulsa **Get API Key from Torbox**. Se abre [torbox.app/settings](https://torbox.app/settings), donde está tu API key.
3. Pega la clave en **API Key** y pulsa **Save API Key**.

![Página Connect Torbox de DMM rechazando una clave de plan gratuito, clave difuminada](../assets/dmm-torbox/01-free-plan.webp)

Una vez dentro, la página de inicio muestra **Cast for TB** y **Requests**, y **Debrid services** lista tu cuenta de TorBox con un ✓. Púlsala para ver tu plan y cuándo caduca, o para **Add another account** o **Logout**.

## Qué puede hacer cada plan {#what-each-plan-can-do}

| | Free | Essential o Standard | Pro |
|---|---|---|---|
| Iniciar sesión en DMM | No | Sí | Sí |
| **Instant TB**, **DL with TB**, la biblioteca y **Cast (TB)** | No | Sí | Sí |
| Enviar releases de Usenet a TorBox | No | No | Sí |
| Descargas simultáneas (slots activos de TorBox) | 1 | 3 o 5 | 10 |

Si inicias sesión con una clave del plan gratuito, DMM muestra **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** La [página de precios](https://torbox.app/pricing) de TorBox indica que el acceso a la API no está incluido en el plan Free, y que Usenet solo está en el plan Pro.

## Encuentra lo que TorBox ya tiene {#find-what-torbox-already-has}

1. Busca una película o serie y ábrela.
2. DMM le pregunta a TorBox qué releases tiene en caché. Esos aparecen con **Instant TB** y **Cast (TB)** y se listan primero. El chip **TB ✓** encima de los resultados muestra solo esos. Escribe `is:tb` en el cuadro de filtro; pulsa de nuevo para ver todo.
3. Pulsa **Instant TB**. El release queda en tu biblioteca de TorBox al momento.

![Night of the Living Dead (1968) on DMM with TorBox: Instant TB, Cast (TB) and DL with TB](../assets/dmm-torbox/02-results.webp)

Los releases que TorBox no tiene aparecen con **DL with TB**. Al pulsarlo, TorBox descarga primero el release, lo que usa uno de tus slots activos mientras se descarga. **No seeders** junto al tamaño significa que nadie lo comparte ahora mismo, así que puede que nunca termine. TorBox siempre añade el release completo: no hay forma de elegir archivos sueltos.

## Tu biblioteca {#your-library}

Pulsa **Library**. Lista tus torrents y descargas web de TorBox.

- **TB Add** abre **Add to your TB library**. Pega enlaces magnet, sube archivos `.torrent` o pega enlaces de descarga directa, que TorBox obtiene como descargas web.
- **Backup** guarda tu lista en un archivo. **TB Restore** vuelve a añadir una lista guardada.
- Lo demás funciona igual que con cualquier servicio: consulta [your library](index.md#your-library).

Las descargas de Usenet que enviaste a TorBox no aparecen en la biblioteca de DMM. Búscalas en el sitio de TorBox, en la fila **DMM TB Library** de DMM Cast en Stremio, o a través de [TorBox alojado en Usenet](../zurg/providers/torbox-nzb.md) de zurg.

## Mira en Stremio {#watch-in-stremio}

Pulsa **Cast for TB** en la página principal e instala el addon desde ahí. Luego pulsa **Cast (TB)** en cualquier release que TorBox tenga en caché. Todos los pasos están en [DMM en Stremio](stremio.md).

En Stremio, el addon se llama **DMM Cast for TorBox**. Su fila **DMM TB Library** muestra tus torrents de TorBox más tus descargas web y de Usenet terminadas.

## Envía lanzamientos de Usenet a TorBox (Pro) {#send-usenet-releases-to-torbox-pro}

1. Abre una película o serie y pulsa la pestaña **Usenet**.
2. Con TorBox Pro, la lista aparece encabezada como **Send to TorBox** y cada versión tiene un botón **TorBox**. Púlsalo.
3. DMM te dice lo que TorBox hizo con ella:
   - **Usenet → TorBox: TorBox already had it, it is ready in your TorBox Usenet downloads.**
   - **Usenet → TorBox: TorBox is downloading it, usually ready within a few minutes.**
   - **Usenet → TorBox: queued, it starts when one of your TorBox active slots frees up.**

![Pestaña Usenet de DMM con TorBox Pro: Send to TorBox](../assets/dmm-torbox/03-usenet-tab.webp)

¿También tienes sesión iniciada en Real-Debrid? La lista aparece encabezada como **Send to Real-Debrid or TorBox** y tiene ambos botones. El icono de archivo al final de una fila guarda el NZB en su lugar. ¿Nuevo en Usenet? Empieza con [Usenet para principiantes](../guides/usenet-for-beginners.md).

TorBox elimina una descarga de Usenet 30 días después de haberla guardado en caché. Envíala de nuevo para recuperarla.

## Completa solicitudes con TorBox {#fill-requests-with-torbox}

Los usuarios de Real-Debrid piden lanzamientos en el [tablero de solicitudes](https://debridmediamanager.com/requests) de DMM. Pulsa **Requests** en la página de inicio y luego **Fulfil** en un lanzamiento que TorBox tenga en caché. Se envía desde tu TorBox a su Real-Debrid. Cada 10 envíos te dan 7 días de ventajas de patrocinador de DMM: consulta [gánalo sin pagar](../guides/sponsorship.md#earn-it-without-paying).

## Cuando algo va mal {#when-something-is-wrong}

| Lo que ves | Qué hacer |
|---|---|
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Esa clave es del plan gratuito de TorBox. Mejora o renueva el plan en TorBox y luego vuelve a iniciar sesión. |
| **Failed to refresh torbox: Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Tu plan de pago se ha agotado desde que iniciaste sesión. Renuévalo en TorBox. |
| **API Error: Request failed with status code 403. Status: 403** | TorBox no aceptó esa clave. Cópiala de nuevo desde [torbox.app/settings](https://torbox.app/settings), completa. |
| No hay botón **TorBox** en la pestaña Usenet | Enviar releases de Usenet a TorBox necesita Pro. Essential y Standard no tienen ese botón. |
| **Usenet → TorBox: TorBox Usenet needs a Pro plan** | TorBox rechazó el NZB porque el plan no es Pro. |
| Solo **DL with TB**, sin **Instant TB** | TorBox no tiene en caché ninguno de estos releases. Pulsa uno y espera a que se descargue, o elige otro release. |
| Solo aparecen releases **Instant TB** | El chip **TB ✓** está activado (`is:tb` en el cuadro de filtro). Púlsalo de nuevo o pulsa **Reset**. |
| **No torrents found yet. Use Want above to have zurg fetch it once one turns up, or try the Usenet tab.** | DMM todavía no tiene torrents para este título. Los episodios nuevos pueden tardar un poco. Prueba la pestaña **Usenet** o vuelve más tarde. |
| En Stremio: **⚠️ TorBox refused your account** | TorBox acepta la clave del addon pero no sirve la cuenta, normalmente porque el plan se agotó. Revísalo en [torbox.app/settings](https://torbox.app/settings). No hace falta cambiar nada en DMM. |
| zurg: `Acquisition: dmm-torbox refused the search: No TorBox key linked.` | El feed patrocinado `tb/cached` de la [página Torznab](https://debridmediamanager.com/torznab) de DMM necesita que vincules tu clave de TorBox en **Link a provider key** de esa misma página. Tener la sesión iniciada en TorBox dentro de DMM no basta. El `api_key` en zurg sigue siendo tu clave API de DMM. |

¿TorBox está caído? Compruébalo en [Is TorBox Down Or Just Me?](https://debridmediamanager.com/is-torbox-down-or-just-me). ¿Sigues atascado? Pregunta en el foro **dmm-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Obtener ayuda](../guides/remote-help.md) explica qué incluir.

## Preguntas {#questions}

### ¿El nivel gratuito de zurg no admite TorBox? {#is-torbox-support-not-on-the-free-tier-of-zurg}

Bien. La versión pública gratuita de zurg solo funciona con Real-Debrid. TorBox, los demás servicios y Usenet están en las compilaciones nocturnas de zurg para patrocinadores. Tu plan de TorBox también tiene que ser de pago, ya que zurg no puede leer una cuenta gratuita. Configúralo con [TorBox con zurg](../zurg/providers/torbox.md).

### ¿Zurg usa el plan equivocado de TorBox? {#zurg-uses-the-wrong-torbox-plan}

zurg, las nightlies anteriores al 3 de octubre de 2026 leen el plan Pro de TorBox como Standard y permiten 5 descargas a la vez en lugar de 10. Actualiza zurg. Los [límites de TorBox con zurg](../zurg/providers/torbox-limits.md) tienen el resto.

### ¿Sin resultados de búsqueda con TB? {#no-search-results-with-tb}

DMM Search es igual sin importar con qué servicio inicies sesión. TorBox solo decide qué lanzamientos muestran **Instant TB**. Si no ves nada, revisa que el chip **TB ✓** esté desactivado, recarga la página o pulsa **Show More Results** al final. Un episodio recién estrenado puede no tener torrents en DMM todavía: prueba la pestaña **Usenet**.

### ¿Puedo usar TorBox y Real-Debrid a la vez? {#can-i-use-torbox-and-real-debrid-together}

Sí. Inicia sesión en ambos servicios y cada versión muestra los botones de los dos. Si TorBox tiene una versión en caché y Real-Debrid no, aparece un botón **TB → RD**, que la envía de TorBox a tu Real-Debrid.

### ¿Qué plan de TorBox necesito para DMM? {#which-torbox-plan-do-i-need-for-dmm}

Cualquier plan de pago. Elige Pro si quieres enviar lanzamientos de Usenet a TorBox o quieres 10 descargas a la vez.
