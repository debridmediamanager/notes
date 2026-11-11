# zurg

zurg собирает ваши дебрид-аккаунты и библиотеку Usenet в одну виртуальную папку. Локальное видео он не хранит. Ничего не скачивается, пока плеер не запросит файл. Ремукс на 60 ГБ не занимает 60 ГБ на локальном диске.

Четыре способа открыть одну и ту же библиотеку:

| Endpoint | Для чего |
|---|---|
| `/dav/` | WebDAV, то, что монтирует rclone |
| `/http/` | HTML-браузер директорий |
| `/infuse/` | Вариант WebDAV с учётом особенностей Infuse |
| `/strm/` | Подписанные URL внутри файлов `.strm`, для плееров, которым нужен URL, а не монтирование |

## Настройка {#setup}

Запустите zurg на своём компьютере.

- [Linux](setup/linux.md) — FUSE 3 и автозапуск через systemd
- [Docker](setup/docker.md) — хост Linux с монтированием, видимым с хоста
- [macOS](setup/macos.md) — macFUSE и автозапуск через launchd
- [Windows](setup/windows.md) — WinFsp и задача с буквой диска

## Провайдеры {#providers}

Подключите zurg к аккаунту. На каждой странице описаны учётные данные и запись в `config.yml`. В примерах используется Docker. Установка из бинарного файла использует ту же запись в конфиге. Команды см. в разделе [Настройка](setup/index.md).

| Страница | Чем она отличается |
|---|---|
| [Real-Debrid](providers/realdebrid.md) | Выбор отдельных файлов, `__downloads__`, выбор CDN-хоста, отдельный токен для `.strm` |
| [TorBox](providers/torbox.md) | Один запрос на обновление библиотеки и ограничение по активным слотам, а не по скорости |
| [AllDebrid](providers/alldebrid.md) | Списки файлов приходят с отдельного эндпоинта, поэтому первое сканирование заполняется постепенно |
| [Premiumize](providers/premiumize.md) | Завершённые загрузки и файлы в облаке, которые остались, с сохранёнными папками |
| [Debrid-Link](providers/debridlink.md) | Список seedbox содержит все файлы, и проверки кэша нет |
| [Offcloud](providers/offcloud.md) | Размеры проверяются на сервере доставки, пути к папкам берутся из кэшированных метаданных |
| [Usenet](providers/usenet.md) | Тип `nzb` как запись провайдера. Токена нет, вместо него каталог наблюдения |
| [Лимиты TorBox](providers/torbox-limits.md) | Измеренные цифры, на которых основано ограничение TorBox, и то, как zurg подстраивается под них |
| [Новостной сервер TorBox](providers/torbox-news-server.md) · [Новостной сервер ElfHosted](providers/elfhosted-news-server.md) | Как устроены встроенные аккаунты Usenet на уровне протокола |

[Общая страница](providers/index.md) описывает три способа добавить аккаунт в Docker и правила, которые проверяет загрузчик конфига.

## Руководства {#guides}

- [Usenet](guides/usenet.md) — бэкенд `nzb` от начала до конца: новостные аккаунты, NZB, маунт, Plex
- [Sonarr и Radarr для Usenet](guides/sonarr-radarr.md) — \*arr-приложения ищут, а zurg отвечает им как SABnzbd, поэтому импорт — это просто переименование, а не загрузка
- [Sonarr и Radarr для торрентов](guides/sonarr-radarr-torrents.md) — то же самое, только zurg отвечает как qBittorrent; Prowlarr тоже
- [zurg ищет для Sonarr и Radarr](guides/sonarr-radarr-fetch.md). Radarr и Sonarr ведут список, а zurg сам находит релиз и кладёт его на место. В обоих случаях не нужны ни индексаторы, ни клиент загрузки.
- [`__magic__`](guides/magic.md) — единственная папка, структура которой сохраняется, а значит, расставляете её вы сами; ваша библиотека раскладывается по названиям для Kodi и Plex
- [Переименование](guides/renaming.md) — переименуйте релиз или файл в любом месте библиотеки. Перемещение отклоняется, и на странице написано почему
- [Plex](guides/plex.md) — что zurg делает с токеном Plex, а что намеренно не делает
- [Jellyfin](guides/jellyfin.md) — то же самое, но для Jellyfin
- [rex с zurg](../rex/with-zurg.md) — медиасервер для приложений Plex, который не владеет файлами, а наполняется zurg из вашего аккаунта debrid. Подробнее в [rex](../rex/index.md)
- [Аддон Stremio](guides/stremio.md) — Stremio ищет через ваши индексаторы и воспроизводит прямо из бэкенда Usenet
- [Watchlist и Seerr](guides/acquisition.md) получает то, что вы запросили, через ваши индексаторы
- [Plex watchlist](guides/plex-watchlist.md) — сторона Plex для того же самого
- [Список желаемого DMM](guides/dmm-wanted.md) получает то, на что вы нажали Want в DMM, и больше ничего настраивать не нужно
- [Локальные библиотеки](guides/local-libraries.md) воспроизводят общий список релизов через ваш аккаунт
- [Android и Google TV](guides/android.md) — вся библиотека на телефоне или ТВ-приставке

## Миграция {#migrating}

Перенесите существующую библиотеку на zurg без повторной загрузки и повторного сканирования.

- [Из AltMount](migrate/altmount.md)
- [Из decypharr](migrate/decypharr.md)
- [Из InfiniDysk](migrate/infinidysk.md)
- [Из nzbdav](migrate/nzbdav.md)
- [Из streamnzb](migrate/streamnzb.md)

## Справочник {#reference}

- [Конфигурация](reference/config.md) — каждая опция в `config.yml`
- [Командная строка](reference/cli.md) перечисляет каждую команду и флаг, которые принимает бинарник
- [Исходящая идентификация](reference/outbound-identity.md) рассказывает, что zurg сообщает о себе сервисам, к которым обращается
- [MCP-сервер](reference/mcp.md) позволяет ИИ-агенту управлять zurg через Model Context Protocol
- [Теги](reference/tags.md) — что присваивается торренту и зачем
- [Журнал изменений](reference/changelog.md) — что и когда изменилось

## Внутреннее устройство {#internals}

Как устроен zurg, что на нём измеряли и заметки по проектным решениям в сложных местах.

- [Architecture](internals/architecture.md) — общая структура и инварианты, которые легко сломать
- [Debrid baseline](internals/debrid-baseline.md) — во что обходится zurg и насколько он быстрый на RD, AD и TorBox
- [Torrent lifecycle](internals/torrent-lifecycle.md) — что каждый аккаунт реально сообщает во время загрузки, замерено вживую
- [SABnzbd client contract](internals/sabnzbd-client-contract.md) — точный формат ответов, который ожидают Sonarr и Radarr
- [Plex trash sweep](internals/plex-trash-sweep.md) · [Stream timeout regression](internals/stream-timeout-regression.md) · [Directory config UI/UX](internals/uiux.md)
- [E2E testing](internals/e2e-test.md) · [Real-Debrid API notes](internals/realdebrid-behavior.md)
- [qBittorrent client contract](internals/qbittorrent-client-contract.md) · [Persistent caches](internals/persistent-caches.md)
- [Naming](internals/naming.md) · [rclone move refusal](internals/rclone-move-refusal.md)

---

zurg распространяется спонсорам: [GitHub Releases](https://github.com/debridmediamanager/zurg/releases)
· [Sponsor](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP)
