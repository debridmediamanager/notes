# Провайдеры {#providers}

Провайдер — это один аккаунт, из которого zurg собирает твою библиотеку. Каждый аккаунт — это одна запись под `providers:` в `config.yml`. Можно подключить один аккаунт, а можно и шесть. Если релиз есть сразу в нескольких аккаунтах, он покажется в библиотеке один раз и будет читаться из того аккаунта, который в данный момент может его отдать.

| Сервис | `type` | Страница |
|---|---|---|
| Real-Debrid | `realdebrid` | [Real-Debrid](realdebrid.md) |
| TorBox | `torbox` | [TorBox](torbox.md) |
| AllDebrid | `alldebrid` | [AllDebrid](alldebrid.md) |
| Premiumize | `premiumize` | [Premiumize](premiumize.md) |
| Debrid-Link | `debridlink` | [Debrid-Link](debridlink.md) |
| Offcloud | `offcloud` | [Offcloud](offcloud.md) |
| Usenet | `nzb` | [Usenet](usenet.md) |
| TorBox hosted Usenet | `torbox_nzb` | [TorBox hosted Usenet](torbox-nzb.md) |

Три страницы уходят глубже настройки. В [Лимиты TorBox](torbox-limits.md) собраны измеренные цифры по ограничению скорости TorBox. На страницах [Новостной сервер TorBox](torbox-news-server.md) и [Новостной сервер ElfHosted](elfhosted-news-server.md) описано, что на самом деле представляют собой Usenet-аккаунты, которые идут в комплекте с этими тарифами. Прежде чем тратить на что-то слот провайдера, сначала посмотри там.

Все страницы здесь предполагают установку в контейнере по инструкции [Настройка Docker](../setup/docker.md). `~/zurg` — это каталог с compose-файлом на хосте. `/config` — тот же каталог, но изнутри контейнера. Файл `config.yml` один, и до него можно добраться по обоим путям.

При установке бинарника на Linux, macOS или Windows в разделе [Установка](../setup/index.md) описано, что заменяет `docker compose restart zurg` и строку `setup`. Проверки переводятся так же. Запускай их из папки zurg. Читай `logs/zurg.log` вместо `docker compose logs` (в PowerShell — `Get-Content logs\zurg.log -Tail 100 -Wait`). Запускай `./zurg doctor` (`.\zurg.exe doctor`) без `--working-dir /config`. Смотри свою точку монтирования вместо `/zurg_mnt/zurg`: `/mnt/zurg`, `/Volumes/Zurg` или `Z:\`, если только ты не менял `mount_path`. В Windows PowerShell 5.1 пиши `curl.exe`, а не `curl`.

## Три способа добавить аккаунт {#three-ways-to-add-an-account}

Какой из них нужен, зависит от того, существует ли уже `config.yml`.

### На новой установке используйте setup {#on-a-fresh-install-use-setup}

`zurg setup` спрашивает, какие провайдеры настроить, и запрашивает только их учётные данные. Он записывает аккаунты **только тогда, когда `config.yml` ещё не существует**. Если запустить его снова позже, он обновит установку и не тронет уже имеющиеся аккаунты.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

В выборе можно указать номера или названия, и можно выбрать сразу несколько.

```
Choose one or more providers in priority order:
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
Providers (comma-separated numbers or names): 2,4
```

Всё, что вы вводите, не попадает ни в compose-файл, ни в историю shell. Токен сразу записывается в `config.yml`, а файл сохраняется с правами только для владельца.

### На существующей установке используйте Dashboard {#on-an-existing-install-use-the-dashboard}

Откройте `http://localhost:9999/config/` и нажмите **Add provider** в разделе Essentials.
Выберите тип. Вставьте токен. Сохраните. Dashboard запишет запись обратно в тот же `config.yml`, что лежит рядом с вашим compose-файлом.

Изменения провайдеров вступают в силу только после перезапуска. Dashboard об этом сообщает, а сам перезапуск делается одной командой.

```bash
docker compose restart zurg
```

### Или отредактируйте config.yml вручную {#or-edit-configyml-by-hand}

Файл `~/zurg/config.yml` на хосте. Добавь запись и перезапусти.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

`mount_path` в контейнере — `/zurg_mnt/zurg`, а в compose-файле нужно прописать `/zurg_mnt:/zurg_mnt:rshared`, чтобы маунт был виден на хосте. Это описано на странице [Docker setup](../setup/docker.md). Это единственная часть установки в контейнере, которая отличается от установки из бинарника.

## Установки без присмотра {#unattended-installs}

Каждый провайдер имеет флаг для файла с токеном и переменную окружения. Повторяй `--provider` для каждого аккаунта, который хочешь подключить.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

| `type` | Флаг | Переменная окружения |
|---|---|---|
| `realdebrid` | `--realdebrid-token-file` | `REALDEBRID_TOKEN` или `TOKEN` или `RD_TOKEN` |
| `torbox` | `--torbox-token-file` | `TORBOX_TOKEN` |
| `alldebrid` | `--alldebrid-token-file` | `ALLDEBRID_TOKEN` |
| `premiumize` | `--premiumize-token-file` | `PREMIUMIZE_TOKEN` |
| `debridlink` | `--debridlink-token-file` | `DEBRIDLINK_TOKEN` |
| `offcloud` | `--offcloud-token-file` | `OFFCLOUD_TOKEN` |
| `nzb` | `--nntp-password-file` с `--nntp-host` и `--nntp-username` | `NNTP_HOST` и остальные |
| `torbox_nzb` | `--torbox-token-file` | `TORBOX_TOKEN` |

`torbox_nzb` никогда не определяется автоматически только по `TORBOX_TOKEN` или `--torbox-token-file`. Передай `--provider torbox_nzb`.

С `--non-interactive` и без `--provider` настройка возьмёт те переменные из списка выше, которые заданы.

!!!warning Запущенный контейнер заполняет только Real-Debrid
Сам демон zurg читает `TOKEN`, `RD_TOKEN` и `MOUNT_PATH` только при запуске, который создаёт `config.yml`. Это весь список. `TORBOX_TOKEN` и остальные читает `zurg setup`. Если добавить одну из них в блок `environment:` в compose-файле и запустить контейнер, это само по себе ничего не даст. Запусти setup или добавь аккаунт в Dashboard.
!!!

## Что принимает каждая запись {#what-every-entry-accepts}

| Ключ | Что делает |
|---|---|
| `type` | Обязательный. Один из восьми типов выше. |
| `name` | По умолчанию равен `type`. Отличает два аккаунта одного сервиса друг от друга. |
| `token` | API-ключ. Не используется для `nzb`. |
| `disabled` | Отключает аккаунт, не удаляя учётные данные. |
| `watchlist` | Помечает аккаунт, на котором в первую очередь пробуются новые добавления торрентов. |
| `add_torrents` | Если задать `false`, аккаунт продолжает отдавать данные, но ему больше ничего не добавляется. |
| `warm_connections` | Количество соединений, которые держатся открытыми для каждого хоста, чтобы чтение не тратило время на установку соединения. |

Полные описания и всё остальное есть в
[справочнике по конфигурации](../reference/config.md#accounts).

## Правила, которые проверяет загрузчик {#rules-the-loader-enforces}

- Имена должны быть уникальными. Если у тебя два аккаунта Real-Debrid, нужны `name: rd-main` и `name: rd-backup`, иначе загрузка не пройдёт.
- Имя `e` зарезервировано для маршрутизации ссылок `.strm`. Выбери другое.
- Только одна запись может иметь `watchlist: true`.
- Запись с `watchlist: true` и `add_torrents: false` одновременно не принимается.
- Поддерживается только одна включённая запись `nzb` или `torbox_nzb`. Дополнительные новостные серверы добавляй в `nntp.servers` записи `nzb`.
- Если все записи отключены, загрузка не пройдёт.
- Premiumize, Debrid-Link и Offcloud не принимают `download_tokens` и `strm_link_token`, отличающийся от `token`. Их ID файлов привязаны к одному аккаунту, поэтому второй аккаунт нужно добавлять отдельной записью.

## Проверьте, что всё работает {#check-it-worked}

Начни с лога и диагностики.

```bash
docker compose logs -f --tail=100 zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`WARN service zurg is not installed` в Docker — это нормально, потому что автозапуском управляет Compose. Предупреждения не заставляют doctor завершиться с ошибкой. Ошибка появляется только при `FAIL`.

Затем проверь сам аккаунт — из Dashboard или из терминала.

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
```

`{"success":true}` значит, что учётные данные прошли аутентификацию. Имя в пути — это `name` аккаунта. По умолчанию оно совпадает с его `type`. Добавь `-u user:pass`, если ты задал `username` в `config.yml`. Если его нет, Dashboard и его API открыты на порту, который ты опубликовал.

И наконец посмотри библиотеку на маунте.

```bash
ls /zurg_mnt/zurg/__all__/
```

Для каждого настроенного аккаунта создаётся папка `__<name>__`. В ней лежит всё, что есть у этого аккаунта, и чтение идёт только через него. `__torbox__/Some.Release/` стримится только с TorBox и больше ни с какого сервиса. Папка отдельного аккаунта не показывается в корневом списке маунта, потому что `__all__` — та же самая библиотека. Прямые HTTP- и WebDAV-пути вроде `/http/__torbox__/` по-прежнему отвечают. Через маунт они больше не открываются. Если какая-то библиотека или скрипт использовал `__<name>__`, замени его на `__all__`.

Большая библиотека при первой загрузке грузится какое-то время. Пока она не закончит, `/dav/movies/` отвечает 503, а маунт может не показывать ничего.

## Запуск нескольких аккаунтов {#running-several-accounts}

Порядок имеет значение только в одном месте. Порядок списка `providers:` определяет, в каком порядке пробуются аккаунты для добавления. Аккаунт с `watchlist: true` пробуется первым, где бы он ни стоял в списке. Для просмотра списка и чтения порядок не даёт никаких преимуществ.

Перед тем как подключать медиасервер к результату, стоит знать две вещи.

- Один и тот же релиз появляется в ваших отфильтрованных каталогах **и** в каждом каталоге `__<name>__`, где он лежит. Указывайте Plex или Jellyfin на одну часть монтирования, а не на всё сразу, иначе сервер просканирует одно и то же содержимое несколько раз.
- Внутри каталога `__<name>__` автоматического переключения на другой аккаунт нет. Если файл мёртв на одном аккаунте, там он вернёт 404, а воспроизведётся из каталога другого аккаунта. Остальная часть монтирования отдаёт его как обычно.
