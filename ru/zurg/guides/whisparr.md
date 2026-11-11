# Whisparr

Whisparr — это Radarr для взрослых фильмов и сцен. Он использует zurg как свой клиент qBittorrent. Grab-ы уходят на твой аккаунт debrid. Импорт лишь переименовывает путь внутри `__magic__`; ничего не скачивается и не копируется.

Всё ниже протестировано 2026-10-23 с Whisparr `3.6.5.1886` (образ `ghcr.io/hotio/whisparr:v3`), Prowlarr, zurg, собранным из сегодняшней ветки `main`, и аккаунтом Real-Debrid. Фильм на 17 GB был захвачен, импортирован и воспроизведён с маунта.

## Перед началом {#before-you-start}

Сначала настрой zurg для Radarr по гайду [Sonarr и Radarr для торрентов](sonarr-radarr-torrents.md): нужен аккаунт, который принимает торренты, включённый `__magic__` и включённый эндпоинт qBittorrent. Whisparr использует всё то же самое.

## 1. Категория Whisparr в zurg {#1-whisparrs-category-in-zurg}

Whisparr отправляет свои загрузки в категорию `whisparr`. Его кнопка **Test** на шаге 3 создаёт эту категорию в zurg, так что ничего добавлять не нужно. Если всё же хочешь указать её в `config.yml`, добавь её рядом с уже имеющимися:

```yaml
qbittorrent:
  enabled: true
  categories: [tv-sonarr, radarr, whisparr]
```

## 2. Запуск Whisparr {#2-run-whisparr}

На Linux-хосте дай Whisparr тот же том, что и Radarr: папку **над** точкой монтирования zurg, с `rslave` ([почему](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)):

```yaml
services:
  whisparr:
    image: ghcr.io/hotio/whisparr:v3
    container_name: whisparr
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - ./whisparr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6969:6969
    restart: unless-stopped
```

`PUID` и `PGID` - это Linux-пользователь, от которого работает Whisparr. Docker-образ zurg позволяет читать своё монтирование любому пользователю. Установленный как обычный бинарник zurg делает так только если запущен от root или включён `user_allow_other` ([настройка Linux](../setup/linux.md#1-install-fuse-3)). Если это не так, укажи в `PUID` и `PGID` пользователя, от которого запущен zurg (`id -u` и `id -g` выведут его), иначе Whisparr увидит монтирование пустым.

На macOS и Windows этот compose-файл не подходит, по причине из [шага 8 руководства по Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). Установи Whisparr там как обычное приложение, учитывая подводные камни из раздела [Перед началом](sonarr-radarr.md#before-you-start) этого руководства: на macOS - тот же пользователь, что и у zurg, а на Windows - трей-приложение, а не служба Windows. Протестирован только Docker-образ выше.

Открой `http://<your server>:6969`.

## 3. Добавление zurg как клиента загрузки {#3-add-zurg-as-the-download-client}

**Settings → Download Clients → + → qBittorrent**, заполните точно так же, как для Radarr ([поля](sonarr-radarr-torrents.md#what-to-put-in-each-field)), только **Category** укажите `whisparr`. Оставьте **Remove Completed** включённым. Нажмите **Test**, затем **Save**.

## 4. Добавление корневой папки {#4-add-the-root-folder}

Создайте папку на маунте, а затем добавьте её в **Settings → Media Management → Root Folders**:

+++ Linux

```bash
mkdir -p /mnt/zurg/__magic__/whisparr
```

+++ macOS

```bash
mkdir -p /Volumes/Zurg/__magic__/whisparr
```

+++ Windows

```powershell
New-Item -ItemType Directory -Force Z:\__magic__\whisparr
```

+++

Она лежит рядом с `__magic__/movies`, а не внутри неё. Whisparr раскладывает фильмы по студиям, по пути `__magic__/whisparr/movies/<Studio>/<Title (Year)>/`.

## 5. Индексаторы {#5-indexers}

У индексера DMM нет категории для взрослых, поэтому Whisparr нужны другие индексеры. В Prowlarr работали публичные индексеры **Knaben** и **The Pirate Bay**. **XXXClub** стоит за Cloudflare, и Prowlarr не может его добавить без Cloudflare-решателя.

Затем подключи Prowlarr к Whisparr: в Prowlarr открой **Settings → Apps → + → Whisparr** и укажи адрес Whisparr и API-ключ (он в **Settings → General** в Whisparr). Prowlarr сам добавит свои индексеры в Whisparr.

zurg принимает только релизы, которые уже есть в твоём аккаунте (`cached_only`, включено по умолчанию). Если zurg отказывается от релиза, Whisparr берёт следующий результат.

## 6. Загрузка одного файла {#6-grab-one}

Добавь фильм в Whisparr с включённой опцией **Start search for missing movie**. Если всё сработало, в истории Whisparr за несколько секунд появятся **Grabbed**, а затем **Imported**, и фильм будет в смонтированной папке:

```bash
$ ls "/mnt/zurg/__magic__/whisparr/movies/<Studio>/<Title (Year)>/"
<Title> 1080p.mkv
```

На macOS путь начинается с `/Volumes/Zurg`. На Windows открой в Explorer `Z:\__magic__\whisparr\movies`. В папку `data/local` у zurg ничего не попадает. Файл стримится прямо из твоего аккаунта.

## Просмотр {#watching-it}

Укажите в библиотеке Plex или Jellyfin путь `/mnt/zurg/__magic__/whisparr` (`/Volumes/Zurg/__magic__/whisparr` на macOS, `Z:\__magic__\whisparr` на Windows), и эти фильмы будут храниться в отдельной библиотеке.

В rex они появляются в той библиотеке, куда их отправляют папки zurg, как и любые другие релизы. На большинстве установок это библиотека фильмов.
