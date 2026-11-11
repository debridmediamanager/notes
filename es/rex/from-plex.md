# Pasar de Plex a rex {#move-from-plex-to-rex}

Ejecutas Plex Media Server y quieres probar rex. Tus apps de Plex siguen igual. Lo que cambia es el origen de la biblioteca y la dirección del servidor.

## Qué cambia {#what-changes}

| | Plex Media Server | rex |
|---|---|---|
| De dónde viene la biblioteca | Plex escanea carpetas de un disco o de un mount | Una fuente (tu propia app, rex-stremio o zurg) le dice a rex qué tiene. rex nunca escanea una carpeta y no necesita ningún mount |
| Qué es cada archivo | Plex lo identifica por su nombre de archivo | La fuente lo averigua y se lo dice a rex. rex nunca lee un nombre de archivo |
| Una coincidencia incorrecta | Fix Match en el servidor | **Fix Match** en una app de Plex, con sesión iniciada con la cuenta que es dueña de rex. rex guarda tu elección, y una fuente puede quitarla y conservarla, como hace zurg ([por qué los títulos se colocan como están](with-zurg.md#why-dmm-places-the-files)) |
| La cuenta en la que está el servidor | Normalmente la tuya | Una cuenta nueva de Plex creada para rex, compartida con la tuya |
| Música, TV en vivo y fotos | Desde carpetas y un sintonizador | Solo desde una fuente que las envíe, como un addon ([Building rex addons](addons.md#music)) o los cómics de zurg. Plex Web muestra fotos; Plex para Android no |
| Grabar TV | Sí | No |

## Elige una forma {#pick-a-way}

| | Junto a Plex | En lugar de Plex |
|---|---|---|
| Qué obtienes | rex junto a tu Plex. Tus apps muestran ambos servidores | rex solo, en el puerto habitual de Plex |
| Ideal para | Probar rex, o conservar Plex para fotos o música en un disco, o para grabar TV | Mudarte de forma definitiva |
| En la misma máquina que Plex | rex funciona en el puerto `32500`, y tus apps lo encuentran a través de la cuenta de Plex con la que se comparte | Plex se detiene, rex toma el puerto `32400` y las apps de casa lo encuentran por sí solas |

Empieza junto a Plex incluso si piensas reemplazarlo: copiar tu historial de reproducción necesita que tu servidor Plex antiguo esté en marcha. Haz los pasos 1 al 3, usa rex durante un tiempo y haz el paso 4 cuando estés listo.

## Paso 1. Instala rex junto a Plex {#step-1-set-up-rex-beside-plex}

Configura rex con la fuente que lo va a alimentar, como en [rex with your own app](any-source.md), [rex with your Stremio addons](stremio.md) o [rex with zurg](with-zurg.md), hasta poder ver algo. ¿Ya tienes zurg funcionando para Plex? Sáltate la instalación y actualízalo como indica el paso 1 de rex with zurg: zurg alimenta a rex desde la versión nightly **2026.10.27** en adelante.

- **¿Plex funciona en la misma máquina?** Pon rex en el puerto `32500`, como indica [Install rex](any-source.md#step-1-install-rex) para ese caso, y dale ese mismo puerto a tu fuente. Tus apps entonces mostrarán dos servidores con el nombre de la máquina: rex es el que se comparte contigo, con el nombre de la cuenta nueva al lado. [Install rex](any-source.md#step-1-install-rex) explica cómo cambiarle el nombre.
- **Registra rex en una cuenta nueva de Plex,** no en la que está tu servidor de Plex, como explica [Add it to a Plex account](any-source.md#step-3-add-it-to-a-plex-account).
- **¿Estás fuera de casa con rex-direct?** El puerto 32400 de tu router ya apunta a Plex. Redirige también el puerto `32500` a la máquina de rex, o, [over IPv6](any-source.md#rex-direct-over-ipv6), permite el `32500` hacia ella.

¿Usas zurg? Mientras ambos funcionen, zurg alimenta a los dos. Deja todo lo que zurg tiene para Plex como está (`plex_server_url`, `plex_token`, tu montaje de rclone y cualquier script de escaneo): Plex seguirá funcionando igual, y `rex_url` añade rex.

## Paso 2. Trae tu historial de reproducción {#step-2-bring-your-watch-history}

Una vez que tu biblioteca esté en rex, [Importa tu historial de visualización](import-watched.md) copia lo que viste, dónde te quedaste y tus calificaciones con estrellas desde tu servidor de Plex. Hazlo mientras Plex sigue en funcionamiento. Cada persona con la que compartes lo ejecuta para su propio historial.

## Paso 3. Vuelve a invitar a tu gente {#step-3-invite-your-people-again}

Tus amigos y tu familia fueron invitados a tu servidor de Plex, no a rex. rex es un servidor nuevo, en la cuenta nueva, así que invítalos desde ahí y ellos aceptan igual que con cualquier otro recurso compartido: [Comparte rex con familia y amigos](sharing.md).

## Paso 4. Retira Plex (opcional) {#step-4-retire-plex-optional}

Solo si quieres reemplazar Plex. Sáltate esto si quieres mantener ambos.

**Deja de usar Plex para siempre.** En Linux, `sudo systemctl disable --now plexmediaserver`. En Docker, detén su contenedor y sácalo de tu archivo compose. En Windows y macOS, cierra Plex Media Server y quítalo de las apps que se inician al iniciar sesión.

**Mueve rex al puerto 32400** si estaba en `32500` junto a Plex en la misma máquina:

1. Quita `--port 32500` del comando de inicio de rex (o de la línea `command:` en Docker) y reinicia rex, como muestra [Instalar rex](any-source.md#step-1-install-rex) para tu sistema. En Windows, deja pasar el 32400 y los dos puertos de descubrimiento por el firewall como indica ese paso.
2. Dale a tu fuente la nueva dirección de rex, `http://192.168.1.20:32400` (la IP LAN de rex), y reinícialo: `rex_url` de zurg, o **rex's address** en la página de ajustes de rex-stremio.
3. Cambia `32500` por `32400` en cualquier otro lugar donde hayas puesto la dirección de rex, como Kometa.
4. Con rex-direct, apunta el reenvío del puerto 32400 de tu router a la máquina con rex y elimina el de `32500`. Por IPv6, cambia la regla del firewall de `32500` a `32400` y reinicia rex, para que ofrezca su IPv6 en el nuevo puerto.

Así, rex responde en el puerto 32400 y las apps de Plex en casa lo encuentran solas en tu red.

**¿Usas zurg? Ordena sus ajustes de Plex.** La configuración de zurg puede seguir apuntando al Plex que paraste:

| En el `config.yml` de zurg | Qué hacer |
|---|---|
| `plex_server_url` y `plex_token` | Bórralos, o pulsa **Remove** junto a Plex en el dashboard de zurg (página de configuración, **Media Server Integration**). ¿Usas el [watchlist de Plex de zurg](../zurg/guides/plex-watchlist.md)? Borra solo `plex_server_url`: la watchlist se lee de plex.tv con `plex_token` y no necesita un servidor Plex. También puedes apuntarla a rex: pulsa **Re-Auth** ahí, inicia sesión con la cuenta nueva y elige rex. zurg 2026.10.27 y posteriores ve que el servidor es rex y no le envía escaneos, emparejamiento de Plex, arreglo de temporadas ni comprobaciones de ajustes de Plex. El token será entonces el de la cuenta nueva, así que un watchlist de Plex seguirá a esa cuenta |
| `on_library_update` con un escaneo de Plex, como `plex_update.sh` | Bórralo. rex se entera de cada cambio directamente desde zurg |
| `plex_database_path`, `plex_scan_check_url` y `plex_scan_check_token` | Bórralos. Hacen referencia al Plex que paraste |
| Tu montaje de rclone (`rclone_enabled: true`, o rclone que ejecutes tú) | Mantenlo si Sonarr, Radarr, Bazarr u otra app lee archivos ahí. Si Plex era el único que los leía, puedes apagarlo: rex lee cada archivo directamente desde zurg |

Reinicia zurg después de editar su configuración.

## Qué se traslada y qué no {#what-comes-along-and-what-does-not}

| Viene contigo | Cómo |
|---|---|
| Tus películas y series | Tu fuente las envía a rex. Con zurg vienen de la misma cuenta de debrid que lee Plex |
| Lo que has visto, dónde lo dejaste y tus valoraciones con estrellas de películas y episodios | [Trae tu historial de visualización](import-watched.md), cada persona por separado |

| No viene contigo | Por qué |
|---|---|
| Las correcciones de coincidencias que hiciste en Plex (Fix Matches) | rex no usa las coincidencias de Plex. Tu fuente indica qué es cada archivo; corrige lo que falle con **Fix Match** en rex |
| Colecciones | No se copian. [Kometa con rex](kometa.md) las vuelve a crear a partir de tu configuración de Kometa |
| Pósteres y carátulas que elegiste | Se quedan solo en el servidor antiguo |
| Listas de reproducción y la lista de historial de reproducción del servidor | Se quedan solo en el servidor antiguo |
| El acceso de tus amigos | Fueron invitados al servidor antiguo. Invítalos a rex ([paso 3](#step-3-invite-your-people-again)) |
| Música y fotos en un disco, TV en vivo desde un sintonizador y grabaciones | rex no tiene sintonizador y no graba nada; la música, las fotos y los canales en vivo solo vienen de una fuente que los envíe. Mantén Plex junto a rex para ello |
| Archivos en un disco local | rex no escanea carpetas. Una app tiene que servirlos e informar a rex de ellos: [rex con tu propia app](any-source.md) |
