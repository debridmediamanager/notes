# Один файл Docker Compose для zurg, Plex и rex {#one-docker-compose-file-for-zurg-plex-and-rex}

На Linux-машине один `docker-compose.yml` может запустить zurg, Plex Media Server и rex вместе. zurg показывает вашу библиотеку в виде папок в `/zurg_mnt/zurg`, Plex Media Server читает эти папки, а rex получает ту же библиотеку напрямую от zurg, без всяких папок. Один раз запустите установщик zurg для Docker, а затем замените его `docker-compose.yml` на приведённый ниже.

Нужен только Plex Media Server или только rex, а не оба? Уберите лишний сервис из файла. Если Plex не нужен, удалите и строку `command:` у rex.

Docker Desktop на Windows или Mac этого не потянет: папки zurg не попадают в Explorer или Finder, а rex не может достучаться до zurg внутри Docker. Для этих систем используйте [zurg на Windows](../setup/windows.md) или [zurg на macOS](../setup/macos.md).

## Перед началом {#before-you-start}

- **Linux-машина**, которая работает постоянно. Установщик добавит Docker, если его нет.
- **Спонсорство zurg.** Образ zurg закрытый. Оформите спонсорство на [gatekeeper](https://gatekeeper.debridmediamanager.com/), и он даст доступ к вашему аккаунту GitHub.
- **Ваш API-токен Real-Debrid** или логин от другого сервиса, который поддерживает zurg: [Your Real-Debrid API token](../../guides/real-debrid-api-token.md).
- **Для Plex Media Server** нужен ваш аккаунт Plex. **Для rex** нужен новый аккаунт Plex, созданный специально для него: в [rex с zurg](../../rex/with-zurg.md#before-you-start) объясняется почему.

## 1. Запустите установщик zurg для Docker {#1-run-zurgs-docker-installer}

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Он установит Docker, если его нет (сначала спросит), подготовит `/zurg_mnt` для папок zurg сейчас и после каждой перезагрузки, войдёт в GitHub для образа zurg, создаст `~/zurg/docker-compose.yml`, запросит ваши сервисы и токен, запустит zurg и выполнит `zurg doctor`. [Настройка Docker для zurg](../setup/docker.md) делает то же самое вручную.

**Что вы должны увидеть.**

```bash
ls /zurg_mnt/zurg
```

выводится список: `__all__`, `__downloads__`, `__unplayable__`, `movies`, `shows` и `version.txt`.

## 2. Замените файл на полную версию {#2-swap-in-the-full-file}

```bash
cd ~/zurg
nano docker-compose.yml
```

Замените всё в нём на это:

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

  plex:
    image: plexinc/pms-docker
    container_name: plex
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM=
    volumes:
      - ../plex/config:/config
      - ../plex/transcode:/transcode
      - /zurg_mnt:/zurg_mnt:rslave
    depends_on:
      zurg:
        condition: service_healthy

  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    command: --port 32500
    volumes:
      - ../rex/config:/config
```

- **zurg** — это сервис установщика, без изменений.
- **plex** видит папки zurg по тому же пути, который использует zurg, `/zurg_mnt/zurg`, поэтому запрос сканирования от zurg называет папку, которую Plex знает. `rslave` сохраняет папки, когда zurg перезапускается. Укажите свой часовой пояс в `TZ`.
- **PLEX_CLAIM** подписывает Plex Media Server в вашу учётную запись при первом запуске. Войдите в Plex, откройте [plex.tv/claim](https://www.plex.tv/claim), скопируйте код и вставьте его сразу после `=`. Он истекает через несколько минут, поэтому запускайте стек сразу же.
- **rex** — это сервис из [rex с zurg](../../rex/with-zurg.md#d2-start-rex-in-docker), на порту 32500, потому что Plex Media Server занимает 32400. Его файлы попадают в `~/rex/config`, где rex с zurg их ищет.

Сохраните и запустите всё:

```bash
docker compose up -d
docker compose ps
```

Если `docker` выдаёт permission denied, добавьте `sudo` перед каждой командой `docker` на этой странице.

**Что вы должны увидеть.** Три контейнера: `plex` и `zurg` показывают `(healthy)`, `rex` показывает `Up`. Собственные файлы Plex Media Server попадают в `~/plex`.

## 3. Добавьте папки zurg в Plex {#3-add-zurgs-folders-in-plex}

Откройте Plex Web по адресу `http://<this machine's LAN IP>:32400/web`. Добавьте библиотеку **Movies** с папкой `/zurg_mnt/zurg/movies` и библиотеку **TV Shows** с папкой `/zurg_mnt/zurg/shows`, как показано в [Real-Debrid в Plex](../../guides/real-debrid-plex.md#3-add-the-folders-in-plex).

Чтобы Plex узнавал о новых файлах, откройте панель управления zurg по адресу `http://<this machine's LAN IP>:9999/config/` и нажмите **Login with Plex** в разделе **Media Server Integration** ([шаг 4 там](../../guides/real-debrid-plex.md#4-let-zurg-tell-plex-about-new-things)).

## 4. Настройте rex {#4-set-up-rex}

Следуйте [rex с zurg](../../rex/with-zurg.md) от [D3](../../rex/with-zurg.md#d3-add-it-to-a-plex-account) до [D5](../../rex/with-zurg.md#d5-watch), но вместо `32400` везде используйте `32500`. Например, строка в zurg будет выглядеть так: `rex_url: http://192.168.1.20:32500`, где указан LAN IP rex. После этого в ваших приложениях Plex будут отображаться оба сервера: [шаг 2 rex с zurg](../../rex/with-zurg.md#step-2-install-rex) объясняет, как их различить.

## Обновление {#updating}

```bash
cd ~/zurg
docker compose pull
docker compose up -d
```

Это обновляет zurg, Plex и rex вместе. Там, где rex с zurg запускает `docker compose` в `~/rex`, запускайте его здесь, в `~/zurg`, с `rex` в конце, чтобы затрагивался только rex: `docker compose stop rex` вместо `docker compose down`, `docker compose up -d rex` вместо `docker compose up -d`.

## Если что-то не работает {#when-something-is-wrong}

`docker compose logs --tail=100 zurg` (или `plex`, `rex`) показывает, что контейнер написал последним.

| Что вы видите | Что делать |
|---|---|
| Установщик выводит `Host-visible Docker mounts require a Linux host. Use the binary installer on macOS or Windows.` | У вас Mac или Windows. Установите zurg с помощью [установщика для Windows](../setup/windows.md) или [для macOS](../setup/macos.md). |
| `Error response from daemon: error from registry: unauthorized` при загрузке образа zurg через Docker | Этот компьютер не авторизован в реестре GitHub под аккаунтом, у которого есть доступ к zurg. Станьте спонсором на [gatekeeper](https://gatekeeper.debridmediamanager.com/), затем запустите установщик снова. Чтобы войти вручную, см. [настройку Docker для zurg](../setup/docker.md#1-install-docker-and-unlock-the-image): токену нужны и `read:packages`, и `repo`. |
| `path /zurg_mnt is mounted on ... but it is not a shared mount` | `/zurg_mnt` пока не общая точка монтирования. Выполните `sudo mount --bind /zurg_mnt /zurg_mnt` и `sudo mount --make-rshared /zurg_mnt`, затем `docker compose up -d`. Установщик делает это постоянным после перезагрузок; вручную см. [шаг 7 настройки Docker для zurg](../setup/docker.md#7-make-the-shared-parent-survive-reboots). |
| `zurg` постоянно перезапускается, а в логе в конце `Error: config ./config.yml is not valid YAML: yaml: unmarshal errors:` и `mapping key "..." already defined` | Эта настройка указана в конфиге zurg дважды. Выполните `sudo nano ~/zurg/config.yml`, удалите одну из двух строк, на которые указывает ошибка, сохраните и выполните `docker compose restart zurg`. |
| В логе zurg написано `Mount verification failed: mount verification timeout: /zurg_mnt/zurg/version.txt not accessible after 60 attempts -- you appear to be running inside Docker, mount a parent directory with rshared propagation` | Папки zurg не появились. Проверьте, что строка тома zurg выглядит как `/zurg_mnt:/zurg_mnt:rshared`, то есть указан родитель, а не `/zurg_mnt/zurg`, и что `/zurg_mnt` общий (строка выше). В [Монтирование пустое](../setup/docker.md#mount-is-empty) есть дополнительные проверки. |
| После перезапуска zurg библиотеки в Plex становятся пустыми, а `docker exec plex ls /zurg_mnt/zurg` выдаёт `cannot access '/zurg_mnt/zurg': Transport endpoint is not connected` | В строке тома Plex не хватает `rslave`. Она должна быть такой: `/zurg_mnt:/zurg_mnt:rslave`. Исправьте и выполните `docker compose up -d`. |
| rex останавливается с `rex: cannot bind 0.0.0.0:32400: Address already in use (os error 98) (another rex or Plex on this port? --port picks another)` | Plex Media Server уже занимает порт 32400. Оставьте `command: --port 32500` у rex. |
| `/zurg_mnt/zurg/movies` пустая или выдаёт `Input/output error` сразу после запуска | zurg всё ещё читает ваш аккаунт. `curl http://localhost:9999/ready` выведет `ready`, когда чтение закончится. Пока не перезапускайте zurg: чтение начнётся заново. |
| Названия видны в rex, но ничего не воспроизводится | Строка `upstream failed` в разделе [Если что-то не работает](../../rex/with-zurg.md#when-something-is-wrong) страницы rex с zurg проверяет, достаёт ли rex до zurg. |
| Диск заполняется | zurg хранит копию того, что уже проигрывалось, в `~/zurg/data/rclone-cache`, до 256G по умолчанию. В [Что где находится](../setup/docker.md#what-lives-where) показано, как ограничить размер. |

Всё ещё не получается? Спросите на форуме **zurg-support** в [Discord](https://discord.com/invite/7u4YjMThXP). В [Получение помощи](../../guides/remote-help.md) написано, что стоит приложить.

## Вопросы {#questions}

### Можете проверить мой файл docker compose? {#can-you-check-my-docker-compose-file}

В этом разговоре нет текста выше, с которым можно было бы сравнить. Пришлите документ, который нужно перевести или проверить, и я сделаю это. Заметки о монтировании я учту: zurg монтирует `/zurg_mnt` с `rshared`, Plex монтирует тот же `/zurg_mnt` с `rslave`, rex работает из образа `ghcr.io/debridmediamanager/rex` с `network_mode: host`, а сервис `rex` с образом `plexinc/pms-docker` — это второй Plex Media Server, а не rex.

### Нужен ли отдельный контейнер rclone? {#do-i-need-a-separate-rclone-container}

Нет. zurg сам запускает rclone внутри своего контейнера и монтирует твою библиотеку в `/zurg_mnt/zurg`.

### Можно ли использовать Plex Media Server и rex вместе? {#can-i-use-plex-media-server-and-rex-together}

Да, именно это делает этот файл. Plex Media Server воспроизводит из папок zurg, а rex воспроизводит напрямую из zurg. В ваших приложениях Plex будут показаны оба. Если не хотите иметь оба, оставьте только тот, которым пользуетесь.

### Работает ли это на NAS? {#does-this-work-on-a-nas}

Это было протестировано на Linux ПК, а не на NAS. Установщику нужен терминал (SSH) с `sudo` и FUSE (`/dev/fuse`). Если после шага 1 папки zurg оказались в `/zurg_mnt/zurg`, переходите к шагу 2.

### С какими версиями это тестировалось? {#which-versions-was-this-tested-with}

zurg `2026.11.14.1134-nightly`, rex `2026.11.14.1123-nightly` и Plex Media Server `1.43.5.11079`, 14 ноября 2026 года.
