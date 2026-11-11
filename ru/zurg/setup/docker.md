# Установка через Docker {#docker-setup}

Этот гайд запускает zurg в Docker и открывает его FUSE-монтирование на Linux-хосте. Docker предоставляет zurg, rclone и
ffprobe. Встроенная команда `setup` создаёт конфиг. `doctor` проверяет установку.

Этот порядок действий проверен 4 сентября 2026 года с Docker Engine 29.1.1. Используйте самую свежую датированную ночную сборку, чтобы в образе был выбор провайдера, описанный ниже.

> **Образ для спонсоров:** `ghcr.io/debridmediamanager/zurg` доступен только спонсорам. Станьте спонсором на [gatekeeper](https://gatekeeper.debridmediamanager.com/). Это даёт вашему аккаунту GitHub доступ к образу.

> **Нужен Linux-хост:** монтирование, которое видно на хосте, зависит от распространения монтирования в Linux. Docker Desktop на macOS и Windows запускает контейнеры внутри виртуальной машины. Он не может передать это FUSE-монтирование в Finder или Explorer, а rex не может достучаться до zurg внутри неё, так что ничего не будет воспроизводиться. Используйте вместо этого гайд по бинарнику для [macOS](https://notes.debridmediamanager.com/ru/zurg/setup/macos/) или [Windows](https://notes.debridmediamanager.com/ru/zurg/setup/windows/). На Linux, если rex работает на другой машине, задайте контейнеру zurg `network_mode: host`, как показано в разделе [rex с zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex).

## Вариант в одну строку {#one-line-option}

On a fresh Linux host, the optional bootstrap can install Docker when you approve it, set up persistent FUSE mount propagation, log in to the sponsor registry, write the Compose project, run the provider chooser, and check the result:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Your existing Compose files and configs are kept as they are. The sections below show every step for those who prefer the manual route.

## Что делает установщик внутри контейнера {#what-the-installer-does-in-a-container}

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

- `setup` спрашивает, какие провайдеры настроить, запрашивает только их учётные данные и записывает `config.yml` с режимом `0600`.
- `--no-service` оставляет автозапуск политике Docker `restart: unless-stopped`, а не пытается установить systemd внутри Alpine.
- `--skip-downloads` использует rclone и ffprobe, которые уже установлены в образе.
- `--mount-path` записывает подкаталог, FUSE-монтирование которого будет передаваться обратно на хост.

Повторный запуск setup безопасен. Он проверяет и обновляет установку, но не заменяет существующий `config.yml`.

## 1. Установите Docker и разблокируйте образ {#1-install-docker-and-unlock-the-image}

Установи Docker Engine с плагином Compose на Linux-хост. Перед тем как продолжать, проверь обе команды:

```bash
docker version
docker compose version
```

Войди в GitHub Container Registry под своим именем пользователя GitHub. Когда появится запрос пароля, вставь классический personal access token с обоими скоупами: `read:packages` и `repo`. Образ лежит в приватном репозитории, и токен только с `read:packages` войдёт, но при загрузке образа всё равно упадёт:

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

Укажи в `ZURG_TAG` самый новый датированный релиз для спонсоров. Если хранить его в `.env`, у тебя будет понятная версия для отката, а обновления станут явными:

```bash
printf 'ZURG_TAG=YYYY.MM.DD.HHMM-nightly\n' > .env
```

Замени плейсхолдер на реальный тег релиза, прежде чем продолжать.

## 2. Настройте распространение монтирования FUSE {#2-prepare-fuse-mount-propagation}

Точку монтирования FUSE нужно создать внутри общего родительского монтирования. Выполните это один раз перед запуском первого контейнера:

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

Проверьте устройство и режим propagation:

```bash
test -c /dev/fuse
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

Вторая команда должна вывести `shared` в поле `PROPAGATION`.

## 3. Создайте проект compose {#3-create-the-compose-project}

```bash
mkdir -p ~/zurg
cd ~/zurg
```

Создайте `docker-compose.yml`:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:${ZURG_TAG}
    container_name: zurg
    restart: unless-stopped
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    ports:
      - 9999:9999
    volumes:
      - ./:/config
      - /zurg_mnt:/zurg_mnt:rshared
```

`privileged: true` не нужен. FUSE-устройство, capability `SYS_ADMIN` и профиль AppArmor unconfined — это более узкий набор, который действительно нужен для монтирования.

Не делайте bind для `/zurg_mnt/zurg` напрямую. FUSE-монтирование должно быть дочерним по отношению к bind с `rshared`, иначе событие монтирования не дойдёт до хоста.

Контейнеры, которые читают маунт, в первую очередь Sonarr и Radarr, следуют тому же правилу, только с другой стороны: подключите родительскую папку (`/zurg_mnt`) один раз, с `rslave`, и открывайте все папки через этот единственный bind. Если пробросить `__magic__/__all__` и `__magic__/tv` в \*arr двумя томами, каждый импорт превратится в копию всего файла. См. [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

## 4. Запустите встроенную настройку {#4-run-the-built-in-setup}

From `~/zurg` запусти:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

Выбери одного или нескольких провайдеров в порядке приоритета. Например, введи `2,4`, чтобы сначала шёл TorBox, а потом Usenet. Мастер настройки спросит только учётные данные, создаст `config.yml` в `~/zurg`, включит rclone и создаст `/zurg_mnt/zurg`. Ни один credential не сохраняется в compose-файле или в истории шелла.

Для автоматизации повтори `--provider` и передай флаги для конкретного провайдера: файл с токеном или `--nntp-*`. Мастер настройки при повторных запусках сохраняет существующий конфиг.

Мастер настройки записывает аккаунты только при запуске, который создаёт `config.yml`. Чтобы добавить провайдера в установку, где конфиг уже есть, используй **Add provider** в Dashboard или отредактируй файл, а потом перезапусти. У каждого сервиса есть своя страница с учётными данными, блоком конфига и важными лимитами: [Провайдеры](../providers/index.md).

## 5. Запустите zurg {#5-start-zurg}

```bash
docker compose up -d
docker compose logs -f --tail=100 zurg
```

Выйти из просмотра логов можно через `Ctrl+C`; контейнер при этом продолжит работать. Dashboard находится по адресу `http://localhost:9999/config/` и редактирует тот же `config.yml`, который лежит рядом с compose-файлом.

Большая библиотека может грузиться долго. Папки в маунте не показываются, пока загрузка не закончится. Они выглядят пустыми или выдают `Input/output error`, в то время как Dashboard и `version.txt` работают как обычно. Это значит, что zurg ещё загружается, а не что маунт сломан. [Up versus ready](#up-versus-ready) показывает, как понять, что загрузка завершена.

## 6. Проверьте с помощью doctor {#6-verify-with-doctor}

Когда библиотека будет готова, запустите ту же диагностическую утилиту, что используется при установке из бинарника:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`doctor` проверяет конфиг и его права, ffprobe, rclone, FUSE, HTTP-эндпоинт и монтирование, которое сообщает zurg. `WARN service zurg is not installed` в Docker ожидаем, потому что автозапуском управляет Compose. Предупреждения не приводят к ошибке команды, а вот любой `FAIL` приводит.

Убедитесь, что смонтированный раздел виден и за пределами контейнера:

```bash
cat /zurg_mnt/zurg/version.txt
ls -la /zurg_mnt/zurg/
```

## 7. Сделайте общий родительский каталог устойчивым к перезагрузкам {#7-make-the-shared-parent-survive-reboots}

Self-bind из шага 2 не переживает перезагрузку. Создайте на хосте systemd-юнит типа oneshot:

```bash
sudo tee /etc/systemd/system/rshared-zurg-mnt.service << 'EOF'
[Unit]
Description=Make /zurg_mnt rshared for Docker FUSE mounts
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "mount --bind /zurg_mnt /zurg_mnt && mount --make-rshared /zurg_mnt"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable rshared-zurg-mnt.service
```

После следующей перезагрузки хост подготовит общий родительский каталог раньше, чем Docker восстановит контейнер zurg.

## Up против ready {#up-versus-ready}

zurg отвечает на два разных вопроса по HTTP. Ни один из них не требует пароля, даже если задан `username`.

| Адрес | Отвечает 200, когда | Пока библиотека загружается |
|---|---|---|
| `/http/version.txt` | zurg запущен | 200 |
| `/ready` | библиотека полностью загружена | 503 с `Retry-After: 5` |

Health check контейнера обращается к первому адресу. `docker compose ps` показывает `healthy`, как только zurg запустился. Большая библиотека может загружаться ещё долго после этого. Если нужна вся библиотека, запрашивайте `/ready`. Когда загрузка закончится, он выведет `ready`.

```bash
curl -fsS http://localhost:9999/ready
docker compose exec zurg /app/healthcheck.sh --ready && echo ready
```

Скрипт может ждать готовности так.

```bash
until curl -fsS http://localhost:9999/ready >/dev/null; do sleep 10; done
```

### Почему проверка состояния не ждёт библиотеку {#why-the-health-check-does-not-wait-for-the-library}

Docker хранит один статус здоровья на каждый контейнер. Инструменты, которые его читают, понимают это как «жив ли zurg». autoheal и Docker Swarm перезапускают контейнер, который перешёл в unhealthy. `depends_on` с `condition: service_healthy` удерживает другие сервисы, пока zurg не станет healthy.

На больших библиотеках сообщали о холодном старте длительностью от 15 до 90 минут. Если бы проверка здоровья ждала загрузки библиотеки, все зависимые сервисы простаивали бы всё это время. Контейнер rclone перед zurg оставил бы свою папку монтирования пустой всё это время. Пустая папка выглядит для медиасервера как библиотека, которую удалили. Загрузка, которая дольше, чем повторы проверки здоровья, тоже получила бы статус unhealthy. Всё, что перезапускает unhealthy-контейнеры, тогда начало бы загрузку заново. Она так и не закончилась бы.

### Использование readiness с Compose {#using-readiness-with-compose}

Оставьте контейнер с монтированием на стандартной проверке здоровья (health check), чтобы монтирование поднималось, как только запущен zurg.

```yaml
services:
  rclone:
    depends_on:
      zurg:
        condition: service_healthy
```

Ждите `/ready` в том, кому нужна вся библиотека. Это может быть скрипт сканирования или задача импорта.

Можно сделать так, чтобы контейнер zurg сам отмечался как healthy только после загрузки библиотеки. Переопределите его health check в `docker-compose.yml` и задайте `start_period` больше, чем занимает самая медленная загрузка. Docker не учитывает ошибки внутри start period. Тогда все сервисы, которые зависят от zurg, тоже будут ждать библиотеку. Не комбинируйте это с autoheal.

```yaml
services:
  zurg:
    healthcheck:
      test: ["CMD", "/app/healthcheck.sh", "--ready"]
      interval: 30s
      timeout: 10s
      start_period: 3h
      retries: 3
```

## Управление и обновление zurg {#managing-and-updating-zurg}

Выполняйте эти команды из `~/zurg`:

```bash
docker compose ps
docker compose logs -f --tail=100 zurg
docker compose restart zurg
docker compose stop zurg
docker compose start zurg
```

Compose-проект берёт `ZURG_TAG` из `.env`. Установщик ставит туда `latest`, поэтому pull всегда приносит свежий nightly. Чтобы обновиться, сделай pull и пересоздай контейнер, а потом запусти doctor:

```bash
docker compose pull zurg
docker compose up -d zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`zurg update` здесь не подходит: команда отказывается работать внутри контейнера. Бинарник, который она записывает, лежит в слое контейнера и теряется, как только контейнер пересоздаётся. Тогда следующий `up` тихо вернёт старую сборку. Лучше загрузи образ заново. `--force` обходит этот отказ, но используй его только для контейнера, который ты собираешься сохранить.

Чтобы откатиться, укажи в `.env` в `ZURG_TAG` конкретный nightly-тег и выполни эти три команды ещё раз. Примонтированные конфиг, состояние библиотеки, логи и кэш при смене контейнера не затрагиваются.

`docker compose down` удаляет контейнер и сеть, но оставляет примонтированные файлы в `~/zurg` и родительскую точку монтирования `/zurg_mnt`.

## Что где находится {#what-lives-where}

Всё, что zurg пишет, разрешается относительно `/config`, поэтому одно монтирование `./:/config` хранит всю установку:

| Путь | Что это |
|---|---|
| `config.yml` | Настройки и учётные данные провайдеров; правки из Dashboard записываются сюда |
| `data/` | Состояние библиотеки, локальные файлы, сгенерированные ключи и кэш rclone VFS |
| `logs/` | Логи zurg и rclone |
| `dump/` | Дампы торрентов, если включено |
| `strm/` | Файлы `.strm`, если включена `save_strm_files` |
| `nzbs/` | Папка наблюдения для бэкенда Usenet |

Обновление или пересоздание образа не меняет ни один из этих файлов.

`data/rclone-cache` — единственная папка, которая растёт. Монтирование полностью скачивает каждый файл, который читает, и хранит его после окончания воспроизведения, до **256G** по умолчанию, поэтому на диске под монтирование нужно место под кэш помимо всего остального. Ограничение по возрасту в 72h на практике его не ограничивает: любое обращение к библиотеке, в том числе ночной проход медиасервера, считается обращением к файлу.

```bash
du -sh ./data/rclone-cache
```

Если на диске хоста столько места не найдётся, ограничь его меньше в `config.yml`:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Если поменять путь на хосте, который стоит за `/config`, кэш переименуется, а старая копия останется без дела. zurg подчистит такие «брошенные» деревья при следующем запуске и запишет в лог, сколько освободил.

См. [config.md](../reference/config.md#disk-the-mount-uses).

### Предварительная заполнение окружения для автоматической установки {#environment-seeding-for-unattended-installs}

Образ по-прежнему поддерживает старый путь первого запуска. Если `config.yml` не существует, `TOKEN` или `RD_TOKEN` задают аккаунт, а `MOUNT_PATH` включает монтирование. Эти переменные читаются только во время создания файла; при каждом последующем запуске побеждает файл.

Real-Debrid — единственный аккаунт, который запущенный контейнер задаёт таким способом. `TORBOX_TOKEN`, `ALLDEBRID_TOKEN`, `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN`, `OFFCLOUD_TOKEN` и `NNTP_HOST` читает `zurg setup`, поэтому они работают только в одноразовом контейнере настройки выше, а в блоке `environment:` сервиса ничего не делают.

Интерактивная команда `setup` предпочтительнее для человека за терминалом, потому что токен не попадает в compose-файл. Задание через переменные окружения остаётся полезным для автоматизации, которая уже хранит секреты в хранилище.

### Обновление установки, которая смонтировала `/app` {#upgrading-an-install-that-mounted-app}

Старые compose-проекты монтировали `/app/config.yml`, `/app/data` и другие пути по отдельности. Entrypoint по-прежнему выбирает `/app`, как только находит такую раскладку, поэтому после обновления образа контейнер продолжает использовать старые конфиг и кэш.

Чтобы перейти на раскладку с одной папкой, остановите контейнер, скопируйте существующие `config.yml`, `data/` и другие каталоги состояния в одну папку на хосте, а затем смонтируйте эту папку в `/config`.

## Устранение неполадок {#troubleshooting}

Начните с диагностики и текущих логов:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
docker compose logs --tail=200 zurg
```

### `unknown command "setup"` или `unknown command "doctor"` {#unknown-command-setup-or-unknown-command-doctor}

Контейнер появился раньше встроенного установщика. Используй `2026.09.04.1449-nightly` или более новый образ zurg с датой, а затем пересоздай контейнер:

```bash
docker compose pull zurg
docker compose up -d zurg
```

### `Transport endpoint is not connected`

Старое FUSE-монтирование устарело:

```bash
sudo umount -l /zurg_mnt/zurg
docker compose restart zurg
```

### Устройство FUSE недоступно {#fuse-device-is-unavailable}

Загрузите модуль сейчас и при последующих загрузках:

```bash
sudo modprobe fuse
echo fuse | sudo tee /etc/modules-load.d/fuse.conf
```

Затем убедитесь, что в сервисе compose всё ещё есть `/dev/fuse`, `SYS_ADMIN` и настройка AppArmor.

### Монтирование пустое {#mount-is-empty}

Проверяйте каждый уровень по порядку:

```bash
docker compose logs zurg 2>&1 | grep -i rclone
docker compose exec zurg ls -la /zurg_mnt/zurg
curl -fsS http://localhost:9999/http/version.txt
curl -fsS http://localhost:9999/ready
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

Путь на хосте должен быть общим bind mount, а том в compose должен монтировать родительскую папку как `/zurg_mnt:/zurg_mnt:rshared`.

Если `/ready` возвращает ошибку 503, библиотека ещё загружается, а монтирование в порядке. Пока загрузка не закончится, её папки показываются пустыми или с ошибкой `Input/output error`. Просто подождите и не перезапускайте zurg. Перезапуск начнёт загрузку заново.

### Монтирование появляется дважды в выводе `mount` {#mount-appears-twice-in-mount-output}

Это нормально. Тот же FUSE-монтаж виден и в пространстве имён контейнера, и в пространстве имён хоста, потому что propagation работает.

Всё ещё застряли? Спросите в форуме **zurg-support** на [Discord](https://discord.com/invite/7u4YjMThXP). В [Getting help](../../guides/remote-help.md) написано, что нужно указать.
