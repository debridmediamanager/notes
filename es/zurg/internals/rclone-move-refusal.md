# Importaciones vacías tras un movimiento rechazado {#empty-imports-after-a-refused-move}

Reproducido con rclone 1.72.0, una unión local-first, VFS full caching y el `File.Move(source, destination)` de .NET 6 que usa Sonarr 4.0.19.2979.

Cuando el backend rechaza un MOVE, `vfs.File.rename` de rclone deja el directorio y el nombre del archivo apuntando al destino intentado. Entonces .NET recurre a una copia. Al crear su destino se genera una entrada de caché VFS vacía; al abrir el origen se llega a esa misma entrada, así que la copia lee EOF e informa de éxito. La reproducción esperaba 4096 bytes y recibió cero. Cambiar la respuesta de rechazo de WebDAV de 409 a 422 no cambió el resultado.

El parche en `scripts/patches/rclone-v1.72.0-rename.patch` restaura el directorio y el nombre originales cuando falla el rename inmediato. Incluye una prueba de regresión de VFS upstream. La prueba de montaje recorre todo el camino de WebDAV, unión, FUSE y .NET con un archivo falso y sin credenciales de proveedor. Su veredicto de daño se inyecta mientras los bytes del fixture siguen siendo legibles: .NET puede copiar esos bytes con éxito, pero no debe convertirlos en un archivo vacío.

Compila un binario nuevo junto al instalado:

```sh
./scripts/build-rclone-move-fix.sh /absolute/path/to/rclone-fixed
RCLONE_TEST_BIN=/absolute/path/to/rclone-fixed ./integration/magic_move_refusal.sh
```

La compilación fija el commit upstream `38ab3dd5b1df946aecf5bd085c671c86f46f68eb` (1.72.0). Ejecuta las pruebas de rename de VFS antes de compilar. La prueba de montaje requiere FUSE de Linux y Docker, o un `DOTNET_MOVE_PROBE_BIN` autocontenido compilado desde `integration/dotnet-move-probe`. Falla a propósito con el binario sin parchear. `make integration-test` incluye esta comprobación; apunta `RCLONE_TEST_BIN` y `RCLONE_BIN` al binario corregido al ejecutar la suite.

La instalación requiere reiniciar el montaje usando las salvaguardas habituales de tu servidor de medios en el despliegue. Guarda el binario anterior por si necesitas volver atrás. Los archivos vacíos que ya existan en el upstream local de una unión sobreviven a un reinicio del montaje; consérvalos y elimina solo los artefactos de importación vacíos confirmados. Reiniciar limpia los nodos VFS obsoletos, pero no repara los artículos de Usenet que faltan.

Esta corrección no suprime la copia de respaldo de .NET ni hace legible el contenido dañado. La comprobación de disponibilidad de zurg antes de la finalización en SABnzbd y su MOVE rechazado siguen siendo protecciones separadas. El muestreo de disponibilidad no es una verificación de archivo completo; consulta `sabnzbd-client-contract.md`.

El parche fijado también incluye la corrección de alias de archivo que usa la unión integrada. Con `action_policy: all`, tanto local como WebDAV pueden recibir una operación sobre archivo. Un Move o Remove local exitoso emparejado con un 404 de WebDAV solo se acepta tras una búsqueda nueva que demuestre que el origen del upstream fallido ya no existe; las operaciones con todos los upstreams fallidos, un origen que aún existe, un directorio padre de destino inexistente y otros errores de I/O o de permisos siguen siendo fallos. El binario resultante informa `v1.72.0-zurg-rename-sidecar-fix` para distinguirlo de la compilación original solo de VFS.
