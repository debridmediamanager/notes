# DMM hash lists: añade la biblioteca de otra persona a la tuya {#dmm-hash-lists-add-someones-library-to-yours}

Una hash list es una lista de releases que alguien compartió desde su biblioteca de debrid a través de DMM. Ábrela, inicia sesión en DMM con tu servicio de debrid y pulsa el botón de tu servicio: los releases se añaden a tu propia cuenta. Las listas compartidas están en [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com), y puedes compartir la tuya desde **Library** de DMM con **Share List**.

Una lista contiene nombres de releases, sus hashes y sus tamaños. No incluye archivos ni cuentas.

## Buscar una lista {#find-a-list}

- En la página de inicio de DMM, pulsa **Hash lists**. Se abre [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com) con una lista aleatoria. **Previous hash list**, **Random hash list** y **Next hash list** sirven para moverte entre listas.
- La gente publica listas en el foro **hashlists** de [Discord](https://discord.com/invite/7u4YjMThXP). Cada una es un enlace como `https://hashlists.debridmediamanager.com/<id>.html`. Al abrirlo, se abre la lista en DMM.

## Añadir una lista a tu biblioteca {#add-a-list-to-your-library}

1. Abre la lista. Si dice **Login to RD/AD/TB/PM/OC/DL to download**, primero inicia sesión en [DMM](https://debridmediamanager.com) en el mismo navegador (consulta [cómo iniciar sesión](index.md#sign-in)) y luego vuelve a abrir la lista.
2. DMM comprueba qué releases ya tiene tu servicio. Solo muestra esos y deja fuera lo que ya está en tu biblioteca. La caja verde **hidden** cuenta lo que dejó fuera.
3. Filtra si quieres:
   - **Movies** y **TV Shows** muestran un tipo. Los números cuentan títulos, no archivos.
   - **One per title** mantiene el mejor release de cada título.
   - El chip verde **other files** junto a un título muestra todos sus releases.
   - **quick search on filename, hash, or id; supports regex** busca en la lista.
4. Pulsa el botón de una fila (**RD**, **TB**, **AD**, **PM**, **OC** o **DL**) para añadir ese release.
5. O pulsa **RD Download** (**TB Download**, **PM Download** y así sucesivamente) para añadir todos los releases mostrados. El número que aparece es la cantidad. DMM te pregunta antes, por ejemplo **Add 11 releases to Premiumize?**: pulsa **Add 11** para empezar.

![Una lista compartida de hashes de películas abiertas en DMM, con sesión iniciada en Premiumize](../assets/dmm-hashlists/01-hash-list.webp)

**Show All** también muestra los releases que tu servicio no tiene, y **Show Instant** vuelve a mostrar solo los que están en caché.

**RD Download** solo añade releases que Real-Debrid ya tiene, uno por minuto, porque Real-Debrid pausa las cuentas que añaden más rápido. Sesenta releases tardan unas dos horas... 

Corrección: sesenta releases tardan unas dos horas no, tardan unos sesenta minutos. Las adiciones se ejecutan en la página, así que mantén la pestaña abierta hasta que diga **Started 60 downloads.** TorBox y AllDebrid omiten lo que no tienen en caché.

## Comparte tu propia biblioteca {#share-your-own-library}

1. En la página principal de DMM, pulsa **Library**.
2. Busca o marca las versiones que quieras compartir. Si no marcas ninguna, se comparte todo lo que se muestra.
3. Pulsa **Share List** (dice **Share (3)** si marcaste tres). Escribe un nombre en **Enter a title for the hash list** y pulsa **OK**.
4. DMM abre la nueva dirección de tu lista en hashlists.debridmediamanager.com. Puede mostrar un 404 durante uno o dos minutos mientras se publica. Recarga la página y luego comparte esa dirección.

![The title prompt after pressing Share List](../assets/dmm-hashlists/02-share-list.webp)

Las listas compartidas son públicas. Cualquiera que tenga la dirección puede abrirlas, y **Random hash list** puede mostrar la tuya a desconocidos. Solo se incluyen nombres, hashes y tamaños: nunca tu cuenta, tu clave ni una dirección de tracker.

Para compartir una sola versión sin publicar nada, pulsa el icono de compartir al final de su fila en la biblioteca (o **Hashlist** en sus detalles). DMM abre una lista de una sola versión. Copia la dirección de esa página y envíala.

## Cuando algo va mal {#when-something-is-wrong}

| Lo que ves | Qué hacer |
|---|---|
| **Login to RD/AD/TB/PM/OC/DL to download** | No has iniciado sesión en DMM en este navegador. Inicia sesión y luego vuelve a abrir la lista. |
| Todo está **hidden** y la lista parece vacía | Las filas ocultas ya están en tu biblioteca, o tu servicio no las tiene. Pulsa **Show All**. |
| **This hash list is still being published; refresh in a minute or two.** | La lista se compartió hace un momento. Espera un minuto o dos y recarga. |
| **0 files** y sin filas | Esa lista está vacía. Pulsa **Next hash list** o **Random hash list**. |
| **Everything already downloaded** | Todos los lanzamientos mostrados ya están en tu biblioteca. |
| **Torrent not instant in TorBox; skipped.** o **Torrent not instant in AD; skipped.** | Tu servicio no tiene ese torrent en caché, así que DMM lo omitió en lugar de iniciar una descarga. |
| **Skipping 3 items with no info hash — they cannot be shared.** | Esas filas (por ejemplo, las descargas web de TorBox) no tienen hash que compartir. El resto de la lista se comparte. |
| **Failed to generate hash list; try again soon.** | Falló la publicación de la lista. Inténtalo de nuevo más tarde. |

¿Sigues atascado? Pregunta en el foro **dmm-support** de [Discord](https://discord.com/invite/7u4YjMThXP).

## Preguntas {#questions}

### ¿Cómo añado listas de hashes a mi propia biblioteca? {#how-do-i-add-hash-lists-to-my-own-library}

Abre la lista, inicia sesión en DMM con tu servicio debrid y luego pulsa el botón de tu servicio en una fila, o **RD Download** (o el **Download** de tu servicio) para todo lo que se muestra. Consulta [Add a list to your library](#add-a-list-to-your-library).

### ¿Por qué aparecen ocultos todos los elementos de mi lista de hashes? {#why-are-all-the-items-in-my-hash-list-hidden}

DMM oculta lo que ya está en tu biblioteca y lo que tu servicio no tiene en caché. La casilla **hidden** indica cuántos son. **Show All** muestra el resto.

### ¿Por qué las series de TV no aparecen en una lista de hashes? {#why-dont-tv-shows-show-up-in-a-hash-list}

Pulsa **TV Shows** en la parte superior de la lista. Si dice **0 TV Shows**, esa lista no tiene series: la mayoría de las listas compartidas son de películas. Las series que tu servicio no tiene también quedan ocultas, así que prueba con **Show All**.

### ¿Por qué añadir una lista de hashes es tan lento? {#why-is-adding-a-hash-list-so-slow}

En Real-Debrid, DMM añade una versión cada minuto para que Real-Debrid no pause tu cuenta. Los otros servicios van más rápido.

### ¿Existe una API para consultar las listas de hashes? {#is-there-an-api-to-query-the-hash-lists}

No hay API de búsqueda. Cada lista compartida es un archivo en el [repositorio de hashlists](https://github.com/debridmediamanager/hashlists) público de GitHub. Cada página apunta a DMM con la lista metida en el enlace después de `#` (JSON comprimido con lz-string, con nombres, hashes y tamaños). Una lista muy grande está al lado como `lists/<id>.txt`.

### ¿Compartir una lista comparte también mi cuenta? {#does-sharing-a-list-share-my-account}

No. Una lista solo tiene nombres de lanzamientos, hashes y tamaños.
