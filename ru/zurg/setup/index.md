# Настройка {#setup}

Бинарный установщик — самый короткий путь на Linux, macOS и Windows. Docker по-прежнему доступен на Linux-хосте, если контейнер подходит лучше. Docker Desktop на macOS и Windows запускает контейнеры в виртуальной машине, поэтому монтирование не появится в Finder или Explorer, а rex не сможет достучаться до zurg: там используйте бинарный файл.

## Установщики одной командой {#one-line-convenience-installers}

Установщики скачивают ночные сборки для спонсоров. Сначала станьте спонсором на [gatekeeper](https://gatekeeper.debridmediamanager.com/). Это даёт доступ вашему аккаунту GitHub.

Для новой установки для спонсоров выберите команду для вашей системы:

+++ Linux и macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```
+++ Docker на Linux
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```
+++ Windows
В PowerShell:
```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```
+++

Установочный скрипт проверяет требования платформы, входит в GitHub для доступа спонсора, скачивает подходящую сборку и запускает выбор провайдера. Существующие бинарники и конфиги сохраняются. В каждом руководстве ниже также приведён полный ручной путь установки.

- [Linux](linux.md)
- [Docker](docker.md) (хосты Linux)
- [macOS](macos.md)
- [Windows](windows.md)

После установки zurg раздел [Providers](../providers/index.md) расскажет, как подключить его к аккаунту. Для каждого сервиса есть отдельная страница с учётными данными, записью в `config.yml` и описанием того, чем этот сервис отличается. Эти страницы написаны для Docker. При установке из бинарников запись `config.yml` провайдера и шаги в Dashboard те же. Вместо `docker compose restart zurg` используйте `./zurg service restart` (`.\zurg.exe service restart` в Windows). Строка `docker compose run --rm zurg setup` превращается в `./zurg setup` (`.\zurg.exe setup` в Windows) с теми же флагами, кроме флагов контейнера `--no-service --skip-downloads --mount-path /zurg_mnt/zurg`. Флаг `--…-file` тогда указывает на файл на вашем компьютере, а не на файл внутри `/config`.
