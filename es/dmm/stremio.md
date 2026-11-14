# Usa DMM en Stremio con DMM Cast {#use-dmm-in-stremio-with-dmm-cast}

DMM Cast es el addon de Stremio de Debrid Media Manager. Así es como DMM aparece en Stremio: eliges un lanzamiento en DMM, pulsas **Cast** y Stremio lo muestra como un stream que se reproduce desde tu propia cuenta de debrid o Easynews. En resumen: inicia sesión en DMM, abre la página Cast de tu proveedor, instala el addon en Stremio y luego pulsa **Cast** en cualquier película o serie.

Cast aquí se refiere al addon de DMM. No es Chromecast ni la duplicación de pantalla.

## Lo que necesitas {#what-you-need}

- Un inicio de sesión en DMM con Real-Debrid, TorBox, AllDebrid, Premiumize, Offcloud, Debrid-Link o Easynews.
- Stremio. [Stremio Web](https://web.stremio.com) funciona sin una cuenta de Stremio.

No hace falta patrocinio.

## Configúralo {#set-it-up}

1. Inicia sesión en [debridmediamanager.com](https://debridmediamanager.com) con tu proveedor. Easynews inicia sesión en **Settings**.
2. En la página principal de DMM pulsa **Cast for RD**, **Cast for TB** y así sucesivamente. Si tienes varias cuentas iniciadas, aparece una fila **Cast** con un botón por proveedor. Cada proveedor tiene su propia página de Cast:

   | Proveedor | Página de Cast |
   |---|---|
   | Real-Debrid | [debridmediamanager.com/stremio](https://debridmediamanager.com/stremio) |
   | TorBox | [debridmediamanager.com/stremio-torbox](https://debridmediamanager.com/stremio-torbox) |
   | AllDebrid | [debridmediamanager.com/stremio-alldebrid](https://debridmediamanager.com/stremio-alldebrid) |
   | Premiumize | [debridmediamanager.com/stremio-premiumize](https://debridmediamanager.com/stremio-premiumize) |
   | Offcloud | [debridmediamanager.com/stremio-offcloud](https://debridmediamanager.com/stremio-offcloud) |
   | Debrid-Link | [debridmediamanager.com/stremio-debridlink](https://debridmediamanager.com/stremio-debridlink) |
   | Easynews | [debridmediamanager.com/stremio-easynews](https://debridmediamanager.com/stremio-easynews) |

   ![Página de Cast de DMM para Premiumize, con la dirección del addon difuminada](../assets/dmm-stremio/01-dmm-cast-page.webp)

3. Pulsa **Install (web)**. Se abre Stremio Web con el addon. Pulsa **Install** allí.

   ![Stremio Web pidiendo instalar DMM Cast](../assets/dmm-stremio/02-stremio-install.webp)

   Para otra versión de Stremio, copia la dirección que aparece debajo de los botones y añádela allí. En Stremio Web es **Addons** → **Add addon** → pegar → **Add** → **Install**. La dirección es privada de tu cuenta: nunca la compartas.

4. De vuelta en DMM, busca una película o serie y ábrela. Las versiones que tu proveedor ya tiene reciben un botón **Cast**: **Cast (RD)**, **Cast (TB)**, **Cast (AD)**, **Cast (PM)**, **Cast (OC)** o **Cast (DL)**. Púlsalo. DMM confirma con **Cast started in Stremio** (en una serie, **Casting succeeded.** y cuántos episodios envió) e intenta abrir el título en tu app de Stremio.

   ![Pulsando Cast (PM) en DMM](../assets/dmm-stremio/03-dmm-cast-button.webp)

5. Abre el título en Stremio. Tu cast aparece como **DMM Cast PM (Yours)** (RD, TB y así para otros proveedores). Púlsalo para reproducir.

   ![Stremio mostrando el cast como DMM Cast PM (Yours)](../assets/dmm-stremio/04-stremio-streams.webp)

## Qué más obtienes en Stremio {#what-else-you-get-in-stremio}

- **DMM Cast PM ✨ · Cast a file inside a torrent** en cada película y episodio. Abre ese título en DMM, así que puedes enviar una versión desde ahí.
- Hasta cinco streams más de los casts de otras personas y de versiones que tu proveedor ya tiene. Ajusta el número en **Other streams limit** en la página Cast. Los sponsors pueden subirlo a diez.
- Filas en el Board de Stremio: **DMM PM Movies** y **DMM PM TV Shows** contienen tus casts. **DMM PM Library** contiene todo lo de tu cuenta, y cada elemento se abre con sus archivos. Easynews no tiene fila de Library.
- ¿No quieres las filas? Instala el addon con **Without catalogs** → **Install (web)** en su lugar. Los streams siguen apareciendo.
- **Manage Casted Links** en la página Cast lista tus casts. Marca los que quieras quitar (o **Select All**) y pulsa **Delete Selected** para quitarlos de Stremio.
- **Hide "Cast a file inside a torrent" option** en la página Cast quita la fila ✨.

En Debrid-Link, hacer cast añade la versión a tu cuenta. Una que Debrid-Link todavía no tiene empieza una descarga real y usa uno de tus 50 torrents del día.

## Cuando algo va mal {#when-something-is-wrong}

| Lo que ves | Qué hacer |
|---|---|
| Solo aparece **DMM Cast PM ✨ · Cast a file inside a torrent** (RD, TB…), sin otros streams | Todavía no se ha hecho cast de nada para este título. Pulsa esa fila: abre el título en DMM. Pulsa **Cast** en una versión y luego abre el título en Stremio otra vez. |
| **⚠️ DMM Cast · Set up DMM Cast for Premiumize again** (o tu proveedor) como único stream | El addon en Stremio ya no coincide con tu inicio de sesión en DMM. Púlsalo para abrir tu página de Cast, inicia sesión, luego elimina el addon viejo de Stremio y vuelve a instalarlo desde esa página. |
| **Real-Debrid Required. You must be logged in with Real-Debrid to use the Stremio Cast feature.** (o TorBox, Easynews…) | No has iniciado sesión en ese proveedor en DMM, o abriste la página de Cast de otro proveedor. Pulsa **Login with …**, o usa el botón **Cast for …** en la página de inicio de DMM. |
| **No episodes in this release on Premiumize** | DMM no pudo relacionar los archivos de esa versión con los episodios. Haz cast de otra versión. |
| La dirección del addon pegada en la barra de búsqueda de la parte superior de Stremio Web no hace nada | Esa barra solo sirve para buscar. Usa **Addons** → **Add addon**. |

¿Te quedaste atascado? Pregunta en el foro **dmm-cast-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) explica qué incluir.

## Preguntas {#questions}

### ¿Puedo buscar en DMM desde Stremio? {#can-i-search-dmm-in-stremio}

No. DMM Cast no añade búsqueda a Stremio, y la búsqueda de Stremio no muestra nada de ahí. Busca en [debridmediamanager.com](https://debridmediamanager.com) y pulsa **Cast**. Desde un título que ya tengas abierto en Stremio, la fila ✨ te lleva a ese título en DMM.

### ¿Funciona en mi TV, Fire TV o teléfono? {#does-it-work-on-my-tv-fire-tv-or-phone}

Los casts se guardan en DMM, no en el dispositivo desde el que transmites. Cada Stremio que tenga la dirección de tu addon los muestra. Transmite desde tu teléfono o computadora y, luego, elige el stream **(Yours)** en Stremio donde quieras ver el contenido.

### ¿Qué proveedores funcionan? {#which-providers-work}

Real-Debrid, TorBox, AllDebrid, Premiumize, Offcloud, Debrid-Link y Easynews. Cada uno tiene su propia página de Cast y su propio addon. Instala uno por cada cuenta que quieras usar en Stremio.

### ¿Por qué Stremio muestra solo Cast y ningún stream? {#why-does-stremio-show-only-cast-and-no-stream}

Todavía no se ha asignado nada para ese título. Pulsa la fila ✨, asigna un release en DMM y luego vuelve a abrir el título en Stremio.

### ¿Puedo reproducir toda mi biblioteca de debrid en Stremio? {#can-i-play-my-whole-debrid-library-in-stremio}

Sí. La fila **DMM Library** en el Board de Stremio muestra todo lo de tu cuenta (no lo de Easynews). Abre un elemento para ver sus archivos.

### ¿Necesito un patrocinio? {#do-i-need-a-sponsorship}

No. Para DMM Cast, un patrocinio solo sube el **Other streams limit** de cinco a diez. Consigue tu API key de DMM en [gatekeeper](https://gatekeeper.debridmediamanager.com/) y pégala en **Settings** de DMM.
