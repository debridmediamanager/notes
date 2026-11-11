# Configuración {#setup}

El instalador binario es la forma más corta en Linux, macOS y Windows. Docker sigue disponible en un host Linux cuando un contenedor encaja mejor. Docker Desktop en macOS y Windows ejecuta los contenedores en una VM, así que el montaje no aparece en Finder ni en el Explorador de archivos, y rex no puede llegar a zurg: en esos sistemas usa el binario.

## Instaladores de una línea {#one-line-convenience-installers}

Los instaladores descargan la build nightly para sponsors. Hazte sponsor primero en [gatekeeper](https://gatekeeper.debridmediamanager.com/). Así tu cuenta de GitHub obtiene acceso.

Para una instalación nueva de sponsor, elige el comando para tu host:

+++ Linux y macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```
+++ Docker en Linux
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```
+++ Windows
En PowerShell:
```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```
+++

El bootstrap revisa los requisitos previos de la plataforma, inicia sesión en GitHub para el acceso de sponsor, descarga la build correspondiente y ejecuta el selector de proveedores. Los binarios y las configuraciones existentes se conservan. Cada guía de abajo también incluye la ruta manual completa.

- [Linux](linux.md)
- [Docker](docker.md) (hosts Linux)
- [macOS](macos.md)
- [Windows](windows.md)

Una vez instalado zurg, [Proveedores](../providers/index.md) explica cómo apuntarlo a una cuenta. Hay una página por servicio con la credencial, la entrada de `config.yml` y lo que ese servicio hace de forma diferente. Esas páginas están escritas para Docker. En una instalación con binario, la entrada de `config.yml` del proveedor y los pasos del Dashboard son los mismos. `./zurg service restart` (`.\zurg.exe service restart` en Windows) ocupa el lugar de `docker compose restart zurg`, y la línea `docker compose run --rm zurg setup` pasa a ser `./zurg setup` (`.\zurg.exe setup` en Windows) con los mismos flags, excepto `--no-service --skip-downloads --mount-path /zurg_mnt/zurg` del contenedor. Un flag `--…-file` entonces nombra un archivo en tu máquina en lugar de uno bajo `/config`.
