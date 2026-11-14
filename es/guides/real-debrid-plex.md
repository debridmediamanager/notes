# Una biblioteca de Real-Debrid en Plex con zurg {#a-real-debrid-library-in-plex-with-zurg}

zurg muestra todo lo de tu cuenta de Real-Debrid como carpetas en tu ordenador, ya organizadas en `movies` y `shows`. Añade esas dos carpetas a Plex Media Server y toda tu biblioteca de Real-Debrid se reproduce en todas las apps de Plex, en streaming desde Real-Debrid y sin descargar nada antes. Instalas zurg una sola vez; trae su propio rclone, así que no hay que configurar nada más.

¿No quieres ejecutar Plex Media Server ni una unidad montada? [rex con zurg](../rex/with-zurg.md) muestra la misma biblioteca a las apps de Plex sin necesidad de ninguna de las dos cosas.

## Lo que necesitas {#what-you-need}

- **Un patrocinio.** La versión nightly de zurg es solo para patrocinadores. Patrocina en [gatekeeper](https://gatekeeper.debridmediamanager.com/) y tu cuenta de GitHub tendrá acceso a la descarga. [Qué te da un patrocinio](sponsorship.md) explica el resto.
- **Una cuenta premium de Real-Debrid** y su token de API: [Tu token de API de Real-Debrid](real-debrid-api-token.md) te dice dónde encontrarlo.
- **Plex Media Server en el mismo equipo que zurg.** Plex lee los archivos de las carpetas de zurg, así que tiene que poder verlas. Después, cualquier app de Plex puede reproducir el contenido.
- **Un equipo que se mantenga encendido**: Windows 10 u 11, Linux, un Mac, o un equipo Linux con Docker.

## 1. Instala zurg {#1-install-zurg}

Cada página de instalación empieza con un instalador de una sola línea. Cuando aparezca `Choose one or more providers in priority order:`, escribe `1` para Real-Debrid y luego pega tu token.

| Tu computadora | Instálalo con | Tu biblioteca aparece en |
|---|---|---|
| Windows | [zurg en Windows](../zurg/setup/windows.md) | `Z:\movies` y `Z:\shows` |
| Linux | [zurg en Linux](../zurg/setup/linux.md) | `/mnt/zurg/movies` y `/mnt/zurg/shows` |
| Mac | [zurg en macOS](../zurg/setup/macos.md) | `/Volumes/Zurg/movies` y `/Volumes/Zurg/shows` |
| Linux con Docker | [Un solo archivo de Docker Compose](../zurg/guides/docker-compose.md), que ejecuta Plex Media Server junto a zurg | `/zurg_mnt/zurg/movies` y `/zurg_mnt/zurg/shows` |

El instalador termina con `zurg doctor`, una lista de líneas `PASS`.

## 2. Revisa las carpetas {#2-check-the-folders}

Abre la unidad o carpeta de zurg. Deberías ver `movies`, `shows`, `__all__`, `__downloads__`, `__unplayable__` y `version.txt`.

El primer inicio lee toda tu cuenta de Real-Debrid. Hasta que termine, las carpetas se quedan vacías. Para comprobarlo, abre `http://localhost:9999/ready` en el navegador: dirá `ready` cuando tu biblioteca esté cargada.

## 3. Añade las carpetas en Plex {#3-add-the-folders-in-plex}

In Plex Web, pulsa **Add Library**, el botón junto al nombre de tu servidor en la barra lateral:

1. Elige **Movies** y pulsa **Next**.
2. Pulsa **Browse for media folder** y elige la carpeta `movies` de zurg de la tabla de arriba, como `Z:\movies` en Windows.
3. Pulsa **Add Library**.

Haz lo mismo con **TV Shows** y la carpeta `shows`. Plex entonces escanea las dos y rellena los pósters y los títulos.

## 4. Haz que zurg avise a Plex de las novedades {#4-let-zurg-tell-plex-about-new-things}

Plex no se da cuenta cuando algo nuevo llega a tu cuenta de Real-Debrid. zurg se lo puede avisar. Abre el panel de zurg en `http://localhost:9999/config/`, ve a **Media Server Integration** y pulsa **Login with Plex**. Inicia sesión en Plex y elige tu servidor.

![La sección Media Server Integration del panel de zurg, con el botón Login with Plex](../assets/real-debrid-plex/01-zurg-login-with-plex.webp)

A partir de ese momento, zurg le pide a Plex que escanee cada carpeta que cambia. También desactiva algunos ajustes de Plex que son arriesgados en una biblioteca en streaming, como **Empty trash automatically after every scan**: [Recommended Plex Settings](../zurg/guides/plex.md#recommended-plex-settings) los enumera.

## Cuando algo va mal {#when-something-is-wrong}

| Lo que ves | Qué hacer |
|---|---|
| Plex no encuentra nada, o las carpetas de zurg están vacías | zurg todavía está leyendo tu cuenta. Espera hasta que `http://localhost:9999/ready` diga `ready`, y luego vuelve a escanear en Plex. |
| En Windows no hay unidad `Z:`, o Plex no encuentra `Z:\movies` | `Z:` pertenece a tu sesión de escritorio de Windows, y el instalador de zurg lo inicia ahí cuando inicias sesión. Un PowerShell abierto como administrador tampoco lo ve. [When something is wrong on Windows](../zurg/setup/windows.md#when-something-is-wrong) cubre cada caso. |
| En Linux, Plex ve una carpeta vacía o no puede abrirla, y `./zurg doctor` dice `user_allow_other is not enabled in /etc/fuse.conf; the mount will be visible only to the zurg service user` | Plex se ejecuta con un usuario distinto al de zurg. Permite el acceso a otros usuarios con <code>echo user_allow_other &#124; sudo tee -a /etc/fuse.conf</code>, y luego ejecuta `./zurg service restart` en la carpeta de zurg. |
| En Docker, las bibliotecas de Plex se quedan vacías después de que zurg se reinicia, y `docker exec plex ls /zurg_mnt/zurg` dice `Transport endpoint is not connected` | Dale al contenedor de Plex la carpeta de zurg con `rslave`: `/zurg_mnt:/zurg_mnt:rslave`. [One Docker Compose file](../zurg/guides/docker-compose.md) lo incluye. |
| Aparecen cosas nuevas en las carpetas de zurg pero no en Plex | Haz el paso 4. Hasta entonces, pulsa **Scan Library Files** en la biblioteca de Plex. |
| zurg dice `bad_token` | El token de Real-Debrid está mal o incompleto. [Your Real-Debrid API token](real-debrid-api-token.md#when-something-is-wrong) tiene la solución. |
| Tu disco se llena | zurg guarda una copia de lo que reproduces, hasta 256G por defecto. Limítalo como indica [Keeping the cache small](../zurg/setup/windows.md#keeping-the-cache-small) (Windows) o [Disk the mount uses](../zurg/setup/linux.md#disk-the-mount-uses) (Linux). |

¿Sigues atascado? Pregunta en el foro **zurg-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](remote-help.md) explica qué incluir.

## Preguntas {#questions}

### ¿Hay una guía para configurar DMM, zurg y rclone para hacer streaming en Plex? {#is-there-a-guide-to-set-up-dmm-zurg-and-rclone-to-stream-in-plex}

Esta página. No tienes que configurar rclone tú mismo: el instalador de zurg lo descarga y zurg lo ejecuta. DMM es donde encuentras lanzamientos y los añades a tu cuenta de Real-Debrid ([Qué es DMM y cómo usarlo](../dmm/index.md)). Después zurg los muestra en sus carpetas y Plex los detecta.

### ¿Las películas se descargan a mi ordenador? {#do-the-movies-download-to-my-computer}

No. Plex lee cada archivo de Real-Debrid a través de zurg cuando le das a play. zurg guarda una caché de lo que se ha reproducido, y puede crecer mucho: mira la fila de disco de arriba.

### ¿Puedo prescindir de Plex Media Server? {#can-i-skip-plex-media-server}

Sí, con rex. [rex con zurg](../rex/with-zurg.md) muestra tu biblioteca de zurg en las apps de Plex, sin Plex Media Server y sin montaje. También puedes usar ambos: [Un solo archivo de Docker Compose](../zurg/guides/docker-compose.md) ejecuta zurg, Plex Media Server y rex en una misma máquina.

### ¿También funciona con TorBox o Usenet? {#does-it-work-with-torbox-or-usenet-too}

Sí. El instalador de zurg también ofrece TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud y Usenet, y los coloca todos en las mismas carpetas `movies` y `shows`. [Providers](../zurg/providers/index.md) tiene una página para cada uno.
