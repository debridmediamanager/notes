# Configuración del binario para Linux {#linux-binary-setup}

## Opción de una sola línea {#one-line-option}

El arranque opcional para patrocinadores instala paquetes del sistema, descarga la versión de CPU correcta y ejecuta la configuración y los diagnósticos:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Inicia sesión con GitHub e instala en `~/zurg`. Los binarios y configuraciones existentes se mantienen en su sitio. Sigue abajo para la ruta manual o una ruta personalizada.

El binario de zurg puede crear el resto de su instalación por sí mismo. Escribe la configuración, descarga el rclone correcto (y ffprobe, salvo que ya haya uno en tu PATH) para la máquina, crea el montaje y registra un servicio de systemd habilitado.

Este flujo se verificó el 4 de septiembre de 2026 en servidores Ubuntu 24.04 ARM64 y x86_64 recién instalados.

## 1. Instalar FUSE 3 {#1-install-fuse-3}

En Debian, Ubuntu y sus derivadas:

```bash
sudo apt-get update
sudo apt-get install -y fuse3
```

Otras distribuciones también llaman al paquete `fuse3`: `sudo dnf install fuse3` en Fedora, `sudo pacman -S fuse3` en Arch, `sudo zypper install fuse3` en openSUSE.

Comprueba que el ayudante y el dispositivo estén presentes:

```bash
command -v fusermount3
test -c /dev/fuse
```

Si Plex, Jellyfin u otro proceso se ejecuta con otro usuario de Unix, activa `allow_other` una sola vez:

```bash
echo user_allow_other | sudo tee -a /etc/fuse.conf
```

Sin esa opción el montaje sigue funcionando, pero solo la cuenta que ejecuta zurg puede abrirlo. `zurg doctor` te indica la diferencia.

## 2. Descargar zurg {#2-download-zurg}

Descarga el archivo Linux correspondiente desde las [releases para patrocinadores](https://github.com/debridmediamanager/zurg/releases). Elige `linux-amd64` si tu equipo es Intel o AMD, y `linux-arm64` si es ARM.

Usa la nightly más reciente. Es la pre-release que aparece arriba de la lista. No uses la release que GitHub marca como **Latest**. Esa es v1.0.0. Es más antigua que `zurg setup` y responde `unknown command` cuando la usas.

Las nightlies son solo para patrocinadores. Hasta que tu cuenta de GitHub tenga acceso, esa página responde 404. Patrocina en [gatekeeper](https://gatekeeper.debridmediamanager.com/) para darle acceso. La build pública gratuita es v1.0.0 y está en [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). No tiene `zurg setup`. Configúrala a mano como explica [su README](https://github.com/debridmediamanager/zurg-public#readme), en lugar de seguir los pasos de abajo.

Descomprímelo en el directorio que debería contener toda la instalación:

```bash
mkdir -p ~/zurg
cd ~/zurg
# Put the downloaded zurg binary here, then:
chmod +x zurg
```

Todo lo que zurg guarda se queda junto a ese binario: `config.yml`, los helpers descargados, el estado de la biblioteca, los logs y la caché de rclone.

## 3. Ejecutar la configuración {#3-run-setup}

```bash
cd ~/zurg
./zurg setup
```

La configuración te pregunta qué proveedores quieres configurar. Elige uno o varios en orden de prioridad:

```text
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
```

Por ejemplo, escribe `2,4` para TorBox seguido de Usenet. La configuración solo te pide las credenciales de los proveedores seleccionados. Después:

1. Crea y valida `config.yml`.
2. Restringe el archivo de configuración a su propietario con el modo `0600`.
3. Descarga un rclone nativo en `bin/`, y ffprobe también, a menos que ya tengas uno en tu PATH.
4. Activa el montaje de rclone en `/mnt/zurg`.
5. Instala e inicia un servicio de systemd habilitado.

Usa un montaje dentro de tu directorio personal si no tienes permiso para crear `/mnt/zurg`:

```bash
./zurg setup --mount-path "$HOME/zurg-mount"
```

La configuración se puede volver a ejecutar sin problema. Actualiza el servicio generado, pero no reemplaza un `config.yml` existente.

### Elegir el alcance de systemd {#choosing-the-systemd-scope}

Con el gestor de usuario de systemd funcionando, el alcance predeterminado `auto` instala `~/.config/systemd/user/zurg.service`. Si no, la configuración instala `/etc/systemd/system/zurg.service` y pide sudo para ejecutarlo como el usuario actual.

Elige de forma explícita cuando haga falta:

```bash
./zurg setup --service-scope user
./zurg setup --service-scope system --service-user "$USER"
```

Para que un servicio de usuario se inicie antes del primer inicio de sesión tras un reinicio, activa el lingering:

```bash
loginctl show-user "$USER" -p Linger
sudo loginctl enable-linger "$USER"
```

Ejecutar la configuración como `root` en un servidor selecciona un servicio de sistema propiedad de root.

## 4. Verificar la instalación {#4-verify-the-install}

```bash
./zurg doctor
curl -fsS http://127.0.0.1:9999/http/version.txt
ls /mnt/zurg/version.txt
```

`doctor` revisa la configuración y sus permisos, las dos herramientas descargadas, FUSE, la unidad de systemd, el endpoint HTTP y el montaje que informa zurg.

Una biblioteca grande de Real-Debrid tarda en armarse en la primera ejecución. El servicio puede estar ya activo mientras el primer listado del montaje espera a que termine ese escaneo.

`version.txt` responde en cuanto zurg está en marcha. Una biblioteca grande sigue cargando después de eso. Sus carpetas aparecen vacías o como `Input/output error` hasta que termina. `/ready` te dice cuándo está lista.

```bash
curl -fsS http://127.0.0.1:9999/ready
```

## Disco que usa el montaje {#disk-the-mount-uses}

El montaje guarda en caché cada archivo que lee dentro de `~/zurg/data/rclone-cache`. Conserva el archivo completo una vez termina la reproducción.

Si no haces nada, esa caché crece hasta **256G** y se queda ahí. No se borra cuando un video se detiene. El límite de antigüedad de 72h tampoco te salvará, porque rclone considera que un archivo ha sido usado cada vez que algo lo lee, y el mantenimiento nocturno del servidor de medios lee toda la biblioteca.

Revisa qué contiene.

```bash
du -sh ~/zurg/data/rclone-cache
```

Si 256G es más de lo que el disco puede permitirse, límítalo más bajo en `config.yml`.

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Reinicia zurg después. Para vaciarla a mano, detén zurg primero y luego ejecuta esto.

```bash
rm -rf ~/zurg/data/rclone-cache/vfs/* ~/zurg/data/rclone-cache/vfsMeta/*
```

Mover el directorio de zurg renombra la caché y deja la copia antigua. zurg las recupera en el siguiente inicio y registra lo que liberó. Los detalles y cómo desactivarlo están en [la referencia de configuración](../reference/config.md#disk-the-mount-uses).

## Administrar zurg {#managing-zurg}

Ejecuta estos comandos desde el directorio de zurg:

```bash
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` solo elimina el inicio automático. El binario, la configuración, los datos, los logs y la caché se mantienen en su sitio.

Para seguir los logs de un servicio de usuario:

```bash
journalctl --user -u zurg.service -f
```

Para un servicio de sistema:

```bash
sudo journalctl -u zurg.service -f
```

## Actualizar zurg {#updating-zurg}

Una compilación para patrocinadores se reemplaza a sí misma:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` toma la nightly más reciente. La descarga, comprueba que el nuevo binario informa la versión que esperaba y solo entonces lo sustituye mediante un renombrado, así que el proceso en ejecución nunca se sobrescribe. Si la compilación instalada ya es la más reciente, lo indica y no cambia nada.

`update` inicia sesión en GitHub con la cuenta que usaste para la instalación. El instalador guarda la GitHub CLI en `~/zurg/bin` para ello. Si `update` dice que no encontró ninguna credencial de GitHub, tu instalación es anterior a ese cambio. Ejecuta una vez la actualización del instalador y, a partir de ahí, cada `zurg update` funcionará. El mismo comando también actualiza una compilación demasiado antigua para tener `zurg update`. Solo sustituye el binario y no toca nada más.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

En un servidor sin la GitHub CLI puedes definir `GITHUB_TOKEN` en su lugar. Usa un token clásico con el alcance `repo` de la cuenta de GitHub que tiene acceso a zurg.

## Configuraciones existentes y desatendidas {#existing-and-unattended-configs}

El setup nunca reemplaza un `config.yml` existente. Para un setup desatendido, repite `--provider` y proporciona los flags de archivo de token o `--nntp-*` correspondientes. Las variables `REALDEBRID_TOKEN`, `TORBOX_TOKEN`, `ALLDEBRID_TOKEN` y `NNTP_*` también funcionan. Ejecuta `./zurg setup --help` para ver la lista completa.

Consulta la [referencia de configuración](../reference/config.md) para ver todos los ajustes.

¿Sigues atascado? Pregunta en el foro **zurg-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Cómo pedir ayuda](../../guides/remote-help.md) explica qué incluir.

## Ver también {#see-also}

- [Docker](docker.md) — configuración del contenedor y propagación del montaje FUSE
- [macOS](macos.md) — el mismo instalador del binario con macFUSE y launchd
- [Windows](windows.md) — el mismo instalador del binario con WinFsp y una tarea programada interactiva
