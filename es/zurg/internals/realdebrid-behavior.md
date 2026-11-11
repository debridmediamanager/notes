# Torrents

Real-Debrid permite descargar un número ilimitado de archivos torrent y enlaces magnet, y también elegir qué archivos de ellos quieres descargar.
Si el archivo torrent o el enlace magnet ya fue descargado por otro usuario, se considera "cached" y Real-Debrid te proporciona directamente el enlace en caché.
Si no, intentará descargar el enlace magnet desde trackers públicos o mediante DHT/PEX.
Si se trata de un archivo torrent que contiene información de trackers, usará esa información, lo cual es útil para los trackers privados (por desgracia, muchos trackers privados bloquean los servidores de descarga de Real-Debrid).
Si el torrent ya no tiene seeders ni leechers y es imposible descargar todas las piezas del torrent, se producirá un error.
Una vez descargado, también obtendrás enlaces en caché con este aspecto: https://real-debrid.com/d/DOWNLOADCODE
DOWNLOADCODE es exactamente un ID único de 13 caracteres del archivo específico (cualquier cosa después del carácter 13 se ignora).

# Selección de archivos {#selecting-files}

As mentioned, it is possible to select files that you only want to download inside a torrent
Como ya se mencionó, es posible seleccionar solo los archivos que quieres descargar dentro de un torrent
If a torrent contains files A B and C and you select A and B, it will only download A and B
Si un torrent contiene los archivos A, B y C y seleccionas A y B, solo descargará A y B
The cached status of a torrent actually depends on this unique file selection
El estado de caché de un torrent depende en realidad de esta selección única de archivos
Going back to the torrent containing files A B and C, there are different cached status for A or B or B (single), A+B, B+C, A+C (pair), or A+B+C (all files)
Volviendo al torrent con los archivos A, B y C, hay distintos estados de caché para A, B, o B (single), A+B, B+C, A+C (pair), o A+B+C (all files)
Each unique selection redownloads the torrent again from trackers and returns a different cached link even if for the same file
Cada selección única vuelve a descargar el torrent desde los trackers y devuelve un enlace en caché distinto, aunque sea para el mismo archivo

# Enlaces en caché {#cached-links}

Los enlaces en caché no son descargables y en realidad solo sirven como contenedor de CÓDIGOS DE DESCARGA en Real-Debrid.
Tienes que "unrestrict" (desbloquear), o convertirlo, en un enlace real de descarga o de streaming de Real-Debrid, que caduca a los 7 días.
Los enlaces en caché duran más de 7 días. Si un torrent tiene enlaces en caché que funcionan (es decir, que se pueden desbloquear correctamente), eso significa que sigue en caché en Real-Debrid.
No se sabe con certeza, pero es muy probable que el estado de caché de un torrent se pueda extender si más usuarios desbloquean un enlace en caché.

Ten en cuenta que la única forma de verificar si un enlace en caché funciona es desbloqueándolo y comprobando el primer byte del enlace desbloqueado mediante la cabecera HTTP Range.
zurg admite tanto la verificación con HEAD (por defecto, rápida) como la verificación basada en Range (GET bytes=0-0, más exhaustiva) mediante la opción de configuración use_range_verification.

# Compartir enlaces en caché entre cuentas (medido el 2026-08-19) {#cached-link-sharing-across-accounts-measured-2026-08-19}

RD devuelve IDs de enlace en dos longitudes: 13 caracteres (~70%) y 16 caracteres (~30%). Esos 3 caracteres extra cambian QUIÉN puede desbloquear el enlace:
- Si lo recortas a los primeros 13 caracteres, un enlace /d/ se desbloquea desde CUALQUIER cuenta premium, no solo desde la que lo generó. La biblioteca de torrents de quien llama no se toca; el único efecto secundario es una entrada en el historial de descargas de quien llama.
- Si lo envías con su ID completo de 16 caracteres, ese mismo enlace solo se desbloquea desde la cuenta que lo generó. Todas las demás cuentas reciben "unavailable_file", incluso mientras el torrent que lo generó sigue activo, incluso si quien llama tiene el mismo infohash en su propia biblioteca, y sin importar el parámetro ip.

Por eso, siempre recorta a 13 caracteres antes de desbloquear un enlace guardado. Probar con IDs sin recortar "demuestra" falsamente que compartir enlaces es imposible.

Los enlaces en caché sobreviven a que la cuenta que los generó borre su torrent, pero caducan con la edad. Según un muestreo a gran escala: los enlaces generados hace 1-2 meses seguían desbloqueándose entre cuentas; los de más de unos ~3 meses devolvían todos "hoster_unavailable". Por separado, RD puede desalojar el contenido en sí de su caché (un hash confirmado como en caché hace un mes puede pasar a downloading con 0 seeders al mes siguiente). Entonces el enlace devuelve "unavailable_file" para todos, incluida la cuenta que lo generó.

Cómo interpretar un error de desbloqueo en un enlace en caché guardado:
- 13 caracteres + hoster_unavailable -> el enlace caducó; volver a añadir el torrent con la misma selección genera enlaces nuevos (ver reparación más abajo)
- 13 caracteres + unavailable_file -> RD desalojó el contenido por completo; los enlaces nuevos requieren una descarga real desde seeders
- 16 caracteres + unavailable_file -> no dice nada sobre la disponibilidad: simplemente no eres la cuenta que lo generó; recorta y vuelve a intentarlo

Los enlaces desbloqueados (las URL de host *.download) están ligados a la IP mediante seguimiento del lado del servidor, no por rechazo: el CDN sirve felizmente una IP ajena con un 206, pero real-debrid registra las IP de descarga, y usar los enlaces de una misma cuenta desde varias IP le acarrea una advertencia de compartir cuenta. Pasa la IP del descargador a unrestrict/link (el parámetro ip) para que el enlace se genere para la IP que va a descargar los bytes.

# Reparación de enlaces en caché rotos {#repairing-broken-cached-links}

A veces un enlace en caché, o incluso el enlace sin restricciones de un archivo dentro de un torrent, deja de funcionar
Esto puede deberse a un error de la API de unrestrict o a que el enlace sin restricciones devuelve una respuesta de error HTTP
Para arreglarlo, hay que volver a descargar el torrent y generar enlaces en caché nuevos o frescos
Puedes probar a volver a descargar el torrent con exactamente la misma selección de archivos, a ver si genera enlaces en caché nuevos o frescos
Si eso no funciona, significa que tienes que hacer una selección de archivos distinta en ese torrent
Por ejemplo, si solo un archivo está roto en un torrent con varios archivos, selecciona solo ese archivo roto
Si sigue devolviendo un enlace en caché roto, prueba a añadir otro archivo a la selección
Repite esto hasta que obtengas un enlace en caché nuevo que funcione

# Comportamiento de RAR {#rar-behavior}

Real-Debrid tiene este comportamiento de guardar los torrents en archivos RAR (sin compresión) si seleccionas un tipo de archivo no compatible que no se puede transmitir.
Tipos de archivo de video confirmados: .avi .flv .m2ts .m4v .mkv .mov .mp4 .mpg .mpeg .ts .webm .wmv
Tipos de archivo de audio confirmados: .mp3 .flac .m4a
Cuando seleccionas estos tipos de archivo, Real-Debrid da enlaces individuales a cada archivo, que sí se pueden transmitir.
Si seleccionas cualquier otra cosa, es seguro que Real-Debrid lo guardará en un archivo RAR.
Si seleccionas un video .mkv y un subtítulo .sub, se guardará en RAR.
Lo mismo pasa si solo seleccionas el póster .jpg: también se guardará en RAR.

Un torrent, aunque tenga varios archivos, si se guarda en RAR devolverá un único enlace en caché (que apunta al archivo RAR).
Si solo seleccionas tipos de archivo de video/audio confirmados, no se guardará en RAR y obtendrás un enlace en caché por cada archivo que hayas seleccionado.

# Eliminar una fila de la lista de descargas revoca la URL que generó {#deleting-a-downloads-list-row-revokes-the-url-it-minted}

Medido el 2026-08-22 en la cuenta de prueba, una unrestrict por caso.

Un unrestrict crea una fila en /downloads y una URL en un host numerado, por ejemplo https://124-4.download.real-debrid.com/d/<código de 13 caracteres>/<nombre de archivo>. El código no está ligado a un host: antes de borrar la fila, el mismo código responde 200 en 44-4, 125-4 y en su propio 124-4 por igual. El segmento final con el nombre de archivo es opcional en todos los casos; zurg lo quita y ambas formas responden igual.

DELETE /downloads/delete/<id> revoca ese código, y lo que sigue funcionando depende de qué hosts ya lo han servido:

  - Fila borrada con la URL nunca descargada: todos los hosts responden 404 con X-Error: invalid_download_code. Sigue dando 404 30 s después; no se estabiliza.
  - Fila borrada tras una descarga por 44-4: 44-4 sigue respondiendo 200, mientras que el host que lo generó, 124-4, y un 125-4 que no se usó responden ambos 404 invalid_download_code.

Es decir, una descarga activa el código en el host que la sirvió, y es la fila la que hace que los demás hosts sigan funcionando. Esto es justo lo contrario de lo que suponía la limpieza de la lista de descargas, y importa porque zurg elige el host de descarga en cada petición (ensureReachableDownloadServer reescribe a uno de los N hosts más rápidos): el host al que llegó un HEAD de verificación no es el que elegirá la siguiente petición. Así, una resolución que queda en la caché de enlaces después de borrar su fila responde 404 invalid_download_code en casi todas las peticiones posteriores, lo que parece un enlace caducado y marca como rota una release sana.

Volver a hacer unrestrict del mismo enlace tras un borrado acaba creando un id nuevo en un host nuevo, y funciona con normalidad. Los ids no se reutilizan.

Pero no al instante. La primera medición decía "sin efecto" porque se tomó minutos después. Volví a medir el 2026-08-23 en la cuenta de prueba: tras DELETE /downloads/delete/<id>, unrestrict/link siguió devolviendo el *mismo id muerto* durante 75 segundos, y no generó uno nuevo hasta t+81s.

De esto salen dos cosas, y ambas están en el código. downloadsCleanupMinAge mantiene una fila dos minutos antes de retirarla, así que una instancia hermana que resuelva el mismo enlace en esa ventana obtiene un código vivo. Y la cadena de reintentos de unrestrict de la ruta de servicio —cuatro intentos en unos seis segundos— cabe entera dentro de esa ventana, así que agotarla no dice nada sobre el archivo: cuando todas las resoluciones devuelven la misma URL que acaba de responder 404, zurg rechaza la lectura con un Retry-After en lugar de marcar la release como rota.
