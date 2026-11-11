# Настройка бинарника для Linux {#linux-binary-setup}

## Вариант в одну строку {#one-line-option}

Необязательный загрузчик sponsor ставит системные пакеты, скачивает подходящую сборку для вашего процессора и запускает настройку и диагностику:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Вход выполняется через GitHub, установка идёт в `~/zurg`. Существующие бинарники и конфиги остаются на месте. Для ручной установки или своего пути продолжайте ниже.

Бинарник zurg может сам собрать остальную часть установки. Он создаёт конфиг, скачивает подходящий для машины rclone (и ffprobe, если его ещё нет в вашем PATH), создаёт точку монтирования и регистрирует включённый сервис systemd.

Этот процесс проверен 4 сентября 2026 года на чистых серверах Ubuntu 24.04 ARM64 и x86_64.

## 1. Установите FUSE 3 {#1-install-fuse-3}

В Debian, Ubuntu и их производных:

```bash
sudo apt-get update
sudo apt-get install -y fuse3
```

В других дистрибутивах пакет тоже называется `fuse3`: `sudo dnf install fuse3` в Fedora, `sudo pacman -S fuse3` в Arch, `sudo zypper install fuse3` в openSUSE.

Проверь, что помощник и устройство на месте:

```bash
command -v fusermount3
test -c /dev/fuse
```

Если Plex, Jellyfin или другой процесс запускается от другого пользователя Unix, включи `allow_other` один раз:

```bash
echo user_allow_other | sudo tee -a /etc/fuse.conf
```

Без этой настройки монтирование всё равно работает, но открыть его сможет только та учётная запись, от которой запущен zurg. `zurg doctor` покажет эту разницу.

## 2. Скачайте zurg {#2-download-zurg}

Скачайте подходящий архив для Linux со страницы [релизов для спонсоров](https://github.com/debridmediamanager/zurg/releases). Выберите `linux-amd64` для машины с процессором Intel или AMD и `linux-arm64` для машины с ARM.

Берите самый новый nightly. Это предрелиз вверху списка. Не берите релиз, который GitHub помечает **Latest**. Это v1.0.0. Он старше `zurg setup` и отвечает на него `unknown command`.

Nightly-сборки доступны только спонсорам. Пока у вашего аккаунта GitHub нет доступа, эта страница отвечает 404. Станьте спонсором на [gatekeeper](https://gatekeeper.debridmediamanager.com/), чтобы получить доступ. Бесплатная публичная сборка — v1.0.0 из [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). В ней нет `zurg setup`. Настраивайте её вручную, как описано в [её README](https://github.com/debridmediamanager/zurg-public#readme), а не по шагам ниже.

Распакуйте архив в каталог, который должен содержать всю установку:

```bash
mkdir -p ~/zurg
cd ~/zurg
# Put the downloaded zurg binary here, then:
chmod +x zurg
```

Всё, что zurg хранит, лежит рядом с этим бинарником: `config.yml`, загруженные вспомогательные программы, состояние библиотеки, логи и кеш rclone.

## 3. Запустите настройку {#3-run-setup}

```bash
cd ~/zurg
./zurg setup
```

Установка спрашивает, каких провайдеров настроить. Выберите одного или нескольких в порядке приоритета:

```text
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
```

Например, введите `2,4` для TorBox, а затем Usenet. Установка спрашивает только учётные данные для выбранных провайдеров. Затем она:

1. Создаёт и проверяет `config.yml`.
2. Ограничивает доступ к конфигу только его владельцу, режим `0600`.
3. Скачивает нативный rclone в `bin/`, а также ffprobe, если его нет в вашем PATH.
4. Включает монтирование rclone в `/mnt/zurg`.
5. Устанавливает и запускает включённый сервис systemd.

Если у вас нет прав на создание `/mnt/zurg`, используйте монтирование внутри домашней директории:

```bash
./zurg setup --mount-path "$HOME/zurg-mount"
```

Установку можно безопасно запускать повторно. Она обновляет сгенерированный сервис, но не заменяет существующий `config.yml`.

### Выбор области systemd {#choosing-the-systemd-scope}

При работающем менеджере пользователя systemd режим `auto` по умолчанию установит `~/.config/systemd/user/zurg.service`. Если его нет, setup установит `/etc/systemd/system/zurg.service` и попросит sudo запустить его от имени текущего пользователя.

Если нужно, выберите режим явно:

```bash
./zurg setup --service-scope user
./zurg setup --service-scope system --service-user "$USER"
```

Чтобы пользовательский сервис запускался после перезагрузки ещё до первого входа в систему, включите lingering:

```bash
loginctl show-user "$USER" -p Linger
sudo loginctl enable-linger "$USER"
```

Если запустить setup от имени `root` на сервере, будет выбран системный сервис, принадлежащий root.

## 4. Проверьте установку {#4-verify-the-install}

```bash
./zurg doctor
curl -fsS http://127.0.0.1:9999/http/version.txt
ls /mnt/zurg/version.txt
```

`doctor` проверяет конфиг и его права доступа, оба скачанных инструмента, FUSE, юнит systemd, HTTP-эндпоинт и монтирование, которое показывает zurg.

Большой библиотеке Real-Debrid нужно время, чтобы собраться при первом запуске. Сервис может уже быть active, пока первый листинг монтирования ждёт, когда закончится это сканирование.

`version.txt` отвечает, как только zurg запущен. Большая библиотека продолжает загружаться и после этого. Её папки показываются пустыми или как `Input/output error`, пока загрузка не закончится. `/ready` подскажет, когда это произойдёт.

```bash
curl -fsS http://127.0.0.1:9999/ready
```

## Диск, который использует mount {#disk-the-mount-uses}

Кэш монтирования сохраняет каждый файл, который он читает, в `~/zurg/data/rclone-cache`. Он хранит весь файл и после окончания воспроизведения. Если ничего не делать, кэш вырастет до **256G** и так и останется. Он не очищается, когда видео останавливается. Лимит по возрасту в 72h тоже не спасёт. rclone считает файл использованным каждый раз, когда его кто-то читает, а ночное обслуживание медиасервера читает всю библиотеку.

Посмотри, что в нём лежит.

```bash
du -sh ~/zurg/data/rclone-cache
```

Если 256G — это больше, чем может выделить диск, уменьши лимит в `config.yml`.

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

После этого перезапусти zurg. Чтобы очистить кэш вручную, сначала останови zurg, а потом выполни это.

```bash
rm -rf ~/zurg/data/rclone-cache/vfs/* ~/zurg/data/rclone-cache/vfsMeta/*
```

Если перенести каталог zurg, кэш переименуется, а старая копия останется. zurg освободит их при следующем запуске и запишет в лог, сколько места высвободил. Подробности и способ отключения — в [справочнике по конфигурации](../reference/config.md#disk-the-mount-uses).

## Управление zurg {#managing-zurg}

Выполните эти команды из каталога zurg:

```bash
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` удаляет только автозапуск. Бинарный файл, конфиг, данные, логи и кэш остаются на месте.

Чтобы следить за логами для пользовательского сервиса:

```bash
journalctl --user -u zurg.service -f
```

Для системного сервиса:

```bash
sudo journalctl -u zurg.service -f
```

## Обновление zurg {#updating-zurg}

Сборка для спонсоров обновляет себя сама:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` берёт самую новую ночную сборку. Он скачивает её, проверяет, что новый бинарник сообщает ту версию, которую ожидалось, и только потом подменяет им старый, переименованием, поэтому работающий процесс никогда не перезаписывается. Если установленная сборка уже самая новая, команда так и говорит и ничего не меняет.

`update` входит в GitHub под тем аккаунтом, который использовался при установке. Для этого установщик хранит GitHub CLI в `~/zurg/bin`. Если `update` сообщает, что не нашёл GitHub-учётных данных, значит, установка старше этого изменения. Выполните обновление через установщик один раз, и после этого каждая `zurg update` будет работать. Эта же команда обновит и сборку, которая слишком старая для `zurg update`. Она только заменяет бинарник и ничего больше не трогает.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

Если на сервере нет GitHub CLI, вместо него можно задать `GITHUB_TOKEN`. Используйте classic-токен с областью `repo` от аккаунта GitHub, у которого есть доступ к zurg.

## Существующие и автоматические конфиги {#existing-and-unattended-configs}

Настройка никогда не заменяет существующий `config.yml`. Для неинтерактивной настройки повторите `--provider` и укажите соответствующие флаги с файлом токена или `--nntp-*`. Также работают переменные `REALDEBRID_TOKEN`, `TORBOX_TOKEN`, `ALLDEBRID_TOKEN` и `NNTP_*`. Полный список выводит `./zurg setup --help`.

Все настройки описаны в [справочнике по конфигурации](../reference/config.md).

Всё ещё не получается? Спросите в форуме **zurg-support** на [Discord](https://discord.com/invite/7u4YjMThXP). В [разделе о помощи](../../guides/remote-help.md) написано, что нужно указать.

## См. также {#see-also}

- [Docker](docker.md): настройка контейнера и проброс FUSE-монтирования
- [macOS](macos.md): тот же бинарный установщик с macFUSE и launchd
- [Windows](windows.md): тот же бинарный установщик с WinFsp и интерактивной запланированной задачей
