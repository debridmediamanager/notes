# Какую схему выбрать? {#which-setup-should-i-use}

**[Найдите свою настройку с помощью интерактивной анкеты](https://debridmediamanager.com/choose-your-setup).** Ответьте на несколько вопросов о ваших аккаунтах в плеерах и хостинге. Анкета подскажет подходящие маршруты, требования и ссылки на настройку. Вход в аккаунт не нужен.

**Начните с приложения, в котором хотите смотреть.** Вам не нужны все компоненты. DMM помогает выбирать релизы. Провайдер предоставляет файлы. zurg может превратить их в общую библиотеку. rex показывает библиотеку приложениям Plex. Некоторые маршруты обходятся без части компонентов.

Эта схема охватывает поддерживаемые маршруты, проверенные **10 ноября 2026**. Она включает внешние альтернативы, которые убирают один из шагов. Сторонние дополнения и устройства могут работать иначе. Следуйте по ссылке на руководство и его проверенным ограничениям.

## Выбирайте по тому, чем вы уже пользуетесь {#pick-by-what-you-already-use}

На телефоне прокрутите таблицу в сторону, чтобы увидеть все её столбцы.

| I have / want… | Choose this route | Why choose it? | What you take on |
|---|---|---|---|
| Stremio and a debrid or Easynews account; no server to maintain | **DMM Cast → Stremio**, or your existing stream addon | Watch through your account without running zurg, rex or a media server | The addon and provider must supply a playable stream; the device handles playback |
| Kodi and a debrid, Easynews or TorBox Pro account | **DMM's Kodi addon → your account** | Browse, search and play inside Kodi; pair from your phone. The addon's TorBox library includes hosted NZB downloads | Kodi does the playback. A sponsor's Wanted list still needs zurg to fulfil requests |
| One movie to watch in my usual player | **DMM Watch → external player** | No library server needed | Install a supported player and choose a file it can play |
| Infuse, Kodi or another WebDAV player | **Provider WebDAV** with no host; **zurg → WebDAV player** when a host can stay on | Browse a cloud library without Plex, Jellyfin, Emby or rex | Real-Debrid, AllDebrid, Premiumize, TorBox and Debrid-Link serve their own WebDAV, with their own folder layout. Offcloud has none, so it needs zurg. zurg needs a host that stays on while you watch |
| Plex Media Server already working | **zurg → mounted folder → Plex Media Server → Plex app** | Keep your server, its libraries and existing workflows | Run zurg and a filesystem mount alongside the server; scans read remote files |
| Plex apps, but no wish to maintain a mounted library | **zurg → rex → Plex app** | zurg supplies the library to rex without a mount or Plex Media Server | Both services stay running; check rex's app compatibility and account guidance |
| Stremio addons, but I prefer Plex apps | **Addons → rex-stremio → rex → Plex app** | Turn addon catalogs into Plex libraries; zurg is optional | Run rex and rex-stremio; stream addons must return playable URLs, not raw torrents |
| Jellyfin is how my players access the library | **Provider plugin inside Jellyfin → compatible client** | No separate zurg service or mount | Jellyfin 12 and the matching plugin(s); plugins have their own archive limits |
| Emby is how my players access the library | **Provider plugin inside Emby → compatible client** | Keep everything inside the existing Emby server | Use the supported Emby version; these six plugins cover debrid, not direct Usenet |
| Jellyfin/Emby plus consumers needing their own filesystem/WebDAV access | **zurg → mount → Jellyfin/Emby** | One library can serve more than one consumer | Maintain the mount and server paths; other consumers can use zurg directly |
| NZB files, my own Usenet account and Jellyfin | **NZB plugin inside Jellyfin → compatible client** | Stream NZBs without a separate zurg service | NNTP access and the supported Jellyfin version; the plugin excludes compressed/encrypted archive members and does not repair with PAR2 |
| A hardware player that reads SMB shares | **zurg → mount → host's SMB share → player** | Keep the player's native file browser and playback | The host supplies SMB; zurg itself supplies WebDAV, not an SMB server |
| My own Usenet account and Stremio | **Newznab indexer → zurg's Stremio addon → Stremio** | Search at playback time and stream through your news account | A running zurg, indexer access and NNTP credentials; another device needs a reachable HTTPS addon address |
| An Android/Google TV device, without another computer | **zurg+rex Android → player on that device, or the Plex apps on it and around your home** | Run zurg and rex on an Android device, your own Plex server on your phone or TV box, for that screen and the Plex apps around your home | Sponsor access, sideloading and background operation; Usenet needs 64-bit Android; TorBox hosted NZBs are not available on Android |
| Files already on a disk/NAS | **Existing media server or network player**; **HTTP source → rex** if you want rex | Keep using the files you own; no debrid or Usenet account needed | rex needs metadata submitted through its feed API and HTTP access to the files; the feed producer and file server can be separate. rex does not scan disks |
| Streamable HTTP media or my own HTTP server | **HTTP source + rex feed → rex → Plex apps**, or a compatible player directly | Use an existing source without debrid or zurg | rex needs a feed producer to submit identity and media details; a bare URL does not provide that metadata |

Начните отсюда: [DMM Cast](https://debridmediamanager.com/stremio/) · [Kodi](https://debridmediamanager.com/kodi) · [DMM Settings](https://debridmediamanager.com/settings) · [zurg setup](../zurg/setup/index.md) · [rex with zurg](../rex/with-zurg.md) · [rex with Stremio addons](../rex/stremio.md) · [Jellyfin plugins](https://debridmediamanager.com/jellyfin) · [Emby plugins](https://debridmediamanager.com/emby) · [zurg's Stremio addon](../zurg/guides/stremio.md) · [Android](../zurg/guides/android.md) · [rex with any source](../rex/any-source.md).

Ссылка Cast начинается с Real-Debrid. Если вы используете другой аккаунт, откройте страницу настройки для [TorBox](https://debridmediamanager.com/stremio-torbox/), [AllDebrid](https://debridmediamanager.com/stremio-alldebrid/), [Premiumize](https://debridmediamanager.com/stremio-premiumize/), [Offcloud](https://debridmediamanager.com/stremio-offcloud/), [Debrid-Link](https://debridmediamanager.com/stremio-debridlink/) или [Easynews](https://debridmediamanager.com/stremio-easynews/). Cast здесь означает **DMM addon**. Это не Chromecast и не зеркалирование экрана.

## Карта воспроизведения {#the-playback-map}

Стрелки означают «поставляет библиотеку или воспроизводимый поток для». Это не схема маршрутизации пакетов: в зависимости от маршрута плеер может забирать данные у провайдера, а сервер может передавать байты сам.

[Открыть карту воспроизведения в полном размере](../assets/setup-routes/playback.svg), чтобы увеличить её или сохранить.

```mermaid
flowchart TD
    A[Debrid account] --> B[DMM Cast]
    E[Easynews account] --> B
    B --> C[Stremio]
    A --> K[DMM Kodi addon]
    E --> K
    K --> KD[Kodi]
    A --> D[Provider WebDAV, when offered]
    D --> W[WebDAV or SMB player]
    D --> KD
    A --> V[DMM Watch]
    E --> V
    V --> F[External player]
    A --> Z[zurg]
    N[Own Usenet account] --> Z
    T2[TorBox hosted NZBs] --> Z
    T2 --> TC[TorBox Cast]
    TC --> C
    T2 --> K
    Z --> W[WebDAV or SMB player]
    Z --> F
    Z --> KD
    Z --> ZA[Stremio NZB search addon]
    ZA --> C
    Z --> M[Filesystem mount]
    M --> SMB[Host SMB share]
    SMB --> W
    M --> S[Plex Media Server, Jellyfin or Emby]
    S --> P[Compatible server clients]
    Z --> R[rex]
    T[Stremio catalogs and URL stream addons] --> X[rex-stremio]
    X --> R
    H[Other HTTP source with rex feed] --> R
    R --> Q[Plex apps]
```

Ветке поиска NZB в Stremio нужен аккаунт NZB (`nzb` или `torbox_nzb` для релизов, которые уже есть у TorBox) и индексатор Newznab. Размещённые на TorBox NZB тоже воспроизводятся через TorBox Cast или аддон Kodi, без zurg. Ветке mount-to-SMB нужна отдельная общая папка, настроенная на хосте.

Два маленьких маршрута стоит держать отдельно:

[Открыть карту плагинов в полном размере](../assets/setup-routes/plugins.svg).

```mermaid
flowchart LR
    D[Debrid account] --> J[Plugin inside Jellyfin or Emby]
    J --> A[Compatible server clients]
    U[NZBs and own news account] --> N[NZB plugin inside Jellyfin]
    N --> F[Compatible Jellyfin clients]
```

Плагины — это отдельные интеграции. «zurg» в названии плагина **не** означает, что нужно запускать приложение zurg. Также это не гарантирует те же возможности. Библиотека торрентов в плагине TorBox отделена от размещённого backend NZB в zurg.

## Выберите, откуда берутся файлы {#choose-where-the-files-come-from}

An **indexer** finds releases. A **torrent or NZB** describes how to fetch one. A **provider** supplies the bytes. A **player** decodes them. Access to one does not include the others.

| Input | What obtains/serves the video? | What you need | When it is useful |
|---|---|---|---|
| Cached torrent, magnet or torrent file | Your debrid provider | Аккаунт, который поддерживает выбранная тобой интеграция | Often the shortest wait when the exact release is already available |
| Uncached torrent | The debrid provider downloads it first | Аккаунт, который принимает торрент, доступные источники и место в его лимитах | A release you want is not cached; expect a wait and possible failure |
| NZB, using your own news accounts | zurg's **direct Usenet** backend, or Jellyfin's NZB plugin, reads articles as needed | NZB, доступ к NNTP и выбранная тобой интеграция; доступ к индексатору, если хочешь поиск | Choose your providers/backbones, use fallback accounts, avoid storing whole videos locally |
| NZB, using TorBox's hosted service | **TorBox fetches and repairs it**, then serves the completed files | TorBox Pro; отправь через DMM или через бэкенд zurg **TorBox hosted NZB** | You want NZBs without managing news-server credentials or local decoding |
| DMM Usenet result sent to Real-Debrid | DMM's hosted transfer service fetches it and passes it to **your Real-Debrid library** | Real-Debrid и доступный лимит передач DMM | You already watch through RD and want that release there; no personal NNTP account required |
| Easynews search result | Easynews serves a direct HTTP download/stream | Твой собственный аккаунт Easynews | Watch or Cast from DMM, or use its Easynews Cast/Kodi route, without building an NZB library |
| Direct HTTP(S) download link | A compatible player/HTTP source, or a provider supporting that download | Доступ к самому медиа-URL; подходящий аккаунт провайдера, если импортируешь или разблокируешь его там | You already have a file URL rather than a torrent/NZB |
| Files on your disk or NAS | Your file/media server | Локальное хранилище и плеер, который может до него достучаться | Offline ownership, home videos, or keeping an existing collection |

zurg supports **Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud and Debrid-Link**. You can combine accounts in one library. Caches quotas and file availability still differ. A cached badge is evidence, not a playback guarantee. See [providers](../zurg/providers/index.md).

### «Usenet без аккаунта Usenet»: какой путь выбрать? {#usenet-without-a-usenet-account-which-route}

[Открыть карту Usenet в полном размере](../assets/setup-routes/usenet.svg).

```mermaid
flowchart TD
    N[NZB or Usenet search result] --> O{Who fetches it?}
    O --> A[Your news accounts]
    A --> J[Jellyfin NZB plugin]
    J --> F[Compatible Jellyfin clients]
    A --> Z[zurg direct Usenet]
    Z --> V[Your chosen zurg playback route]
    O --> T[TorBox Pro hosted Usenet]
    T --> B[TorBox completed files]
    B --> C[DMM TorBox Cast, the Kodi addon or zurg hosted NZB library]
    O --> D[DMM hosted transfer]
    D --> R[Your Real-Debrid library]
    R --> P[Your chosen RD playback route]
```

**Выбирайте TorBox hosted NZB**, когда хотите, чтобы TorBox сам скачивал и восстанавливал файлы. DMM отправляет туда NZB. Текущие ночные сборки zurg используют тип провайдера `torbox_nzb` и принимают NZB из каталога наблюдения и интерфейса SABnzbd. [TorBox hosted Usenet](../zurg/providers/torbox-nzb.md) описывает настройку zurg. Если релиза нет в кэше, перед воспроизведением нужно дождаться окончания загрузки. Загрузки делят слоты с торрентами. Сохранённые файлы могут истечь, и zurg не обещает загрузить истёкший релиз заново. Сохраните NZB на случай повторной загрузки.

**Выбирайте прямой Usenet**, когда zurg должен читать через ваши собственные аккаунты новостных серверов, включая резервные и блочные аккаунты. Для этого используется `nzb` с учётными данными NNTP. Сюда же относится логин на новостной сервер TorBox. Это отдельно от TorBox hosted NZB. См. [TorBox NNTP](../zurg/providers/torbox-news-server.md) и [его тарифы](https://torbox.app/pricing).

**Один экземпляр zurg использует либо `nzb`, либо `torbox_nzb`.** Оба управляют каталогом наблюдения за NZB. Запускайте оба с отдельными экземплярами и рабочими каталогами. Если `dmm_api_key` указан в обоих, [отключите источник `dmm-wanted` в одном из них](../zurg/guides/dmm-wanted.md#two-zurgs-on-one-key), иначе каждый релиз из Wanted будет загружаться дважды. Любой из них может работать вместе с торрент-провайдерами. Аддон zurg для Stremio отправляет свой выбор на тот NZB-аккаунт, который есть у экземпляра. При `torbox_nzb` запуск происходит только для релиза, который TorBox уже хранит, и только в пределах времени ожидания аддона и если нет другой ожидающей NZB-отправки.

**Выбирайте DMM → Real-Debrid**, когда хотите, чтобы релиз попал в вашу библиотеку RD. Это хостируемая передача с очередями и лимитами. Загрузка того, чего нет в кэше, занимает время. Real-Debrid и другие debrid-провайдеры не получают встроенной поддержки NNTP через это. Результат в DMM и [страница Transfers](https://debridmediamanager.com/transfers) показывают прогресс.

Easynews **Watch** и **Cast** воспроизводят его HTTP-файлы, а **Download NZB** сохраняет NZB релиза. **Send to zurg** отправляет этот NZB в ваш список Wanted спонсора. Для этого нужен настроенный NZB-бэкенд. Вход Easynews в DMM не настраивает NZB-аккаунт zurg.

### А что со ссылками HTTP? {#what-about-http-links}

DMM-диалог **Add** для TorBox принимает прямые ссылки HTTP(S) как веб-загрузки. zurg показывает их в `__downloads__`. Элемент там не становится автоматически распознанным элементом библиотеки rex. Там могут появляться и unrestricted-загрузки Real-Debrid. DMM TorBox Cast включает завершённые веб-загрузки, загрузки из Usenet и торренты. Веб-страницы всё равно могут требовать другую интеграцию из-за логинов, истекающих ссылок, DRM или собственного плеера.

**rex поддерживает потоковые медиафайлы по HTTP(S) через свой feed API.** [Источник или аддон](../rex/any-source.md) передаёт адрес медиафайла и метаданные. Затем rex делает его доступным в приложениях Plex. Файловый сервер и поставщик фида могут быть разными сервисами. Аккаунт zurg или debrid-сервиса не нужен. [rex-stremio](../rex/stremio.md) делает это для совместимых аддонов Stremio. Сырые магнет-ссылки и стримы, доступные только через торрент, не работают. Для HLS нужна настройка FFmpeg в rex. rex использует идентификацию, которую передаёт источник.

## Решите, как добавляются тайтлы {#decide-how-titles-get-added}

Получение и воспроизведение — это отдельные решения. Можно изменить способ запроса тайтла, не меняя приложение, в котором вы смотрите.

| Как вы выбираете тайтлы | Маршрут | Зачем это нужно? |
|---|---|---|
| Выберите точный релиз | DMM search/library → provider; или NZB → выбранный вами NZB-бэкенд | Сами контролируете издание, размер и релиз |
| Нажмите Want или подпишитесь на список Trakt/MDBList | [DMM Wanted](../zurg/guides/dmm-wanted.md) → zurg acquisition | Автоматические фильмы и новые серии без Sonarr/Radarr; нужно спонсорство |
| Семейные запросы в Seerr/Overseerr/Jellyseerr | [Seerr через DMM](../dmm/seerr.md) → Wanted → zurg | Знакомый интерфейс запросов без arr-сервера; нужно спонсорство. Seerr нужно настроить с сервером Plex, Jellyfin или Emby |
| Уже есть списки Plex или свой стек запросов | [zurg acquisition](../zurg/guides/acquisition.md) | Оставьте текущий источник запросов; настройте его поиск и целевые провайдеры |
| Нужны подробный мониторинг и профили качества в Sonarr/Radarr | DMM или ваши индексаторы → arr → интерфейс download-client zurg → библиотека | Решения arr и его workflow импорта остаются за ним; больше сервисов и настройки путей |
| Хотите выбирать только при нажатии Play | DMM Cast/Kodi, другой stream-аддон или поиск zurg в Stremio | Не нужно заранее собирать управляемую библиотеку всех тайтлов |

Для рекомендуемого маршрута DMM + zurg через arr **DMM — это индексатор, а zurg — клиент загрузки**. DMM предлагает [Torznab](https://debridmediamanager.com/torznab) и [Newznab](https://debridmediamanager.com/newznab). Оба требуют активного спонсорства. Prowlarr необязателен. zurg предоставляет интерфейсы [qBittorrent](../zurg/guides/sonarr-radarr-torrents.md) и [SABnzbd](../zurg/guides/sonarr-radarr.md). Отдельные приложения-загрузчики рядом с zurg не нужны. [zurg также умеет искать для arr](../zurg/guides/sonarr-radarr-fetch.md).

Если нужны **полные локальные копии**, скачайте файлы у провайдера или через zurg. Также можно использовать функцию офлайн-загрузки плеера или обычный загрузчик и дисковую библиотеку. Проверяйте квоты и воспроизводите сохранённые файлы без сети. Виртуальные файлы zurg, ссылки `.strm` и [локальные каталоги debrid](../zurg/guides/local-libraries.md) — не офлайн-копии. Локальные каталоги хранят только записи. Воспроизведение всё равно зависит от провайдера.

## Компромиссы, которые важно знать до установки {#the-tradeoffs-that-matter-before-installing}

| Вопрос | Что влияет на выбор |
|---|---|
| Должна ли другая машина оставаться включённой? | Хостируемые маршруты Cast/Kodi, WebDAV провайдера и DMM Watch не требуют собственного сервера. zurg, rex, rex-stremio и плагины медиасервера нужны, чтобы их хост работал, пока ты смотришь. zurg+rex на Android может сделать Android-устройство хостом для zurg и rex; rex-stremio и плагины медиасервера всё равно требуют обычный хост. Арендованный или управляемый хост меняет того, кто его обслуживает, но не сам маршрут. |
| Сможет ли телевизор проиграть файл? | Маршруты WebDAV и через аддоны зависят от кодеков, аудио и субтитров на стороне плеера. zurg только отдаёт байты, он не перекодирует видео. Plex Media Server, Jellyfin, Emby или rex с FFmpeg могут конвертировать при необходимости, если позволяют подходящее железо и возможности сервера/приложения. |
| Сколько места на диске? | Стриминг позволяет не хранить всю коллекцию целиком. Заложи место для баз данных, постеров, кешей и любой работы по ремонту, перекодированию или офлайн-загрузке. «Без полной загрузки заранее» не значит «ноль использования диска». |
| Кто платит за трафик? | Квоты трафика провайдера всё равно действуют. Серверный прокси передаёт трафик воспроизведения и использует свой исходящий канал; прямое воспроизведение переносит соединение на зрителя. Анализ библиотеки тоже может читать удалённые файлы. |
| Будет ли работать вне дома? | Хостируемые аддоны не открывают твой сервер наружу. Свои сервисы нужен безопасно доступный адрес; один только адрес в LAN удалённо работать не будет. См. [удалённый доступ к rex](../rex/any-source.md#use-it-outside-your-home-optional) и [инструкцию по HTTPS для Stremio](../zurg/guides/stremio.md#installing-it-on-another-device). |
| Может ли семья пользоваться одновременно? | Проверь правила провайдера по IP и количеству одновременных подключений, а также модель общего доступа на сервере. Использование Real-Debrid должно оставаться на одном публичном IP; прямые ссылки для разных домохозяйств могут нарушать это правило, даже если их выдала центральная библиотека. Не включай редиректы, пока не поймёшь, откуда берутся загрузки. |
| За что я плачу? | Подписки провайдеров, доступ к индексаторам, спонсорство DMM, хостинг и покупки плееров/серверов держи отдельно. Базовый сайт DMM и rex для личного использования бесплатны, как и [rex для Android](../rex/android.md). Актуальные ночные сборки zurg и распространение плагинов DMM — это преимущества спонсорства; Wanted и API индексаторов DMM тоже требуют спонсорства. rex-stremio его не требует. [Что даёт спонсорство](sponsorship.md) перечисляет все преимущества и где их настроить. |
| Гарантирует ли запись в каталоге воспроизведение? | Нет. Каталоги аддонов описывают тайтлы; облачные файлы могут истечь; у торрентов может не быть источников; статьи Usenet могут отсутствовать. Выбирай маршрут, поведение которого при сбое и ожидании тебя устраивает. |

Совместимым клиентом сервера может быть и стороннее приложение. [Infuse подключается к Plex, Emby и Jellyfin](https://support.firecore.com/hc/en-us/articles/360006462093-Streaming-from-Plex-Emby-and-Jellyfin). Отдельное монтирование zurg может не понадобиться. Проверяй аддон и клиент вместе.

Infuse поддерживает [WebDAV и другим сетевым шарам](https://support.firecore.com/hc/en-us/articles/215090977-Streaming-From-a-Mac-PC-or-NAS). Файл `.strm` даёт совместимому плееру, например Kodi, URL. Это не замена универсальному монтированию. Проверяй клиент и ожидай другого поведения прокси и переключения на резерв. Не используй `.strm` как обычную настройку Plex Media Server.

Есть также [старый бесплатный релиз zurg](https://github.com/debridmediamanager/zurg-public/releases). Он работает только с Real-Debrid и использует другой формат конфигурации. Мультипровайдерные маршруты Usenet и Android, описанные здесь, используют ночные сборки для спонсоров.

**У rex свои границы совместимости.** Это независимый сервер приложений Plex. Он не является Plex Media Server или плагином Plex. Список проверенных устройств для удалённого перекодирования и рекомендацию по новому аккаунту смотри в [FAQ](../rex/faq.md). Обычный сервер Plex может работать рядом с rex.

## Потребности, которые могут изменить путь {#needs-that-can-change-the-route}

| Мне ещё нужно… | Что выбрать или проверить |
|---|---|
| Локальные файлы и облачные тайтлы вместе | Оставь свой текущий сервер Plex/Jellyfin/Emby и добавь маунт или подходящий плагин. rex умеет объединять несколько источников фидов, включая HTTP-источник для локальных файлов, но метаданные всё равно нужны им самим. |
| Автоматические файлы субтитров | Субтитров от плеера или встроенных может хватить. Если ты используешь arr-связку, [Bazarr с zurg](../zurg/guides/subtitles.md) записывает локальные сопутствующие файлы рядом с виртуальными видео. Эти файлы не доходят до DMM Cast, аддона Kodi, DMM Watch и аддона zurg для Stremio, но доходят до Kodi как источник zurg WebDAV. В rex есть Search Subtitles и без Bazarr. |
| История просмотров при смене сервера | Перед переключением прочитай [переход с Plex](../rex/from-plex.md) и [импорт статуса просмотра](../rex/import-watched.md). Смена источника сама по себе не переносит историю всех приложений. |
| Поделиться подборкой с человеком, у которого свой аккаунт | Хешлисты DMM позволяют делиться выбором релизов, чтобы другие добавили их в свои аккаунты. Они не передают твои учётные данные и не обеспечивают воспроизведение. Совместный доступ к серверу — это другой путь, и на него действуют свои правила шеринга и правила провайдера. |
| VPS или удалённый хост с ограниченной пропускной способностью | Проверь, проксирует ли маршрут воспроизведение или перенаправляет его. [Настройки rex для direct-download](../rex/direct-download.md) описывают доступные варианты. Перенаправления меняют публичный IP загрузчика и могут раскрыть URL провайдера. |

## Другие медиа и существующие настройки {#other-media-and-existing-setups}

- **Музыка:** [DMM Music](https://debridmediamanager.com/music/) даёт воспроизведение и загрузку с Real-Debrid прямо в браузере. [Источники музыки rex](../rex/music.md) подключаются к Plexamp и поддерживаемым приложениям Plex. Источником может быть аддон или zurg, настроенный для музыки. Не предполагайте, что аддон для фильмов и сериалов тоже даёт музыку.
- **Live TV:** [маршрут rex для Live TV](../rex/live-tv.md) даёт каналы и программу передач в поддерживаемых приложениях. Live-каналы из rex-stremio образуют библиотеку каналов, а это не тот же интерфейс программы передач. Проверьте, доступен ли источник. rex не поддерживает запись DVR.
- **Домашние видео, записи и фото:** используйте существующий медиасервер или [источник rex, которым вы управляете](../rex/addons.md). [Пошаговое руководство по домашним видео](../rex/addon-home-videos.md) показывает второй вариант. zurg также может передавать комиксы в rex как фото, но поддержка в приложениях различается.
- **Уже установленные аддоны Kodi/Stremio:** если ваш аддон уже даёт нужный вам опыт, оставьте его. DMM может стать местом, где вы выбираете и управляете релизами, не заменяя ваш плеер. Поддержка провайдеров, Usenet и HTTP в аддонах различается, и маршрут DMM не гарантирует совместимость со всеми аддонами.
- **Уже установлен другой монтировщик или загрузчик debrid:** прежде чем переключаться, посмотрите [варианты миграции](../zurg/migrate/index.md). Работающая настройка не требует дополнительного слоя только потому, что он существует.
- **Нативные приложения в разработке:** Usenet TV не является выпущенной настройкой из магазина приложений, которую здесь стоит рекомендовать. Yomu TV — отдельный проект для чтения и аудиокниг, а не маршрут для этого стека фильмов и сериалов. Ни то, ни другое не требуется для указанных выше маршрутов.

## Пять типичных стартовых вариантов {#five-common-starting-points}

1. **«У меня есть Stremio и RD.»** Начните с DMM Cast. Добавляйте zurg, только если нужна общая библиотека, автоматизация или другой клиент, которому он требуется.
2. **«У меня есть TorBox Pro, и я хочу NZB из этого поста.»** Отправьте NZB в TorBox через DMM. Для просмотра в Stremio используйте TorBox Cast, для Kodi — аддон Kodi, а для выбранного маршрута к библиотеке или плееру — размещённый бэкенд zurg для NZB.
3. **«У меня уже есть Jellyfin.»** Начните с плагина для вашего провайдера. Выбирайте отдельный zurg, если нужна его общая файловая система, автоматизация или более широкие возможности бэкенда.
4. **«Хочу приложения Plex, без монтирования и с моими текущими аддонами.»** Используйте rex-stremio вместе с rex. Используйте zurg как источник, если нужно открыть вашу управляемую библиотеку debrid/Usenet. Оба источника могут питать один и тот же rex.
5. **«У меня есть аккаунты новостных серверов, и я хочу Sonarr/Radarr.»** Используйте DMM Newznab или ваши текущие индексаторы, маршрут NZB/SABnzbd от zurg и маршрут воспроизведения из первой таблицы. Для постоянных локальных файлов выбирайте обычный загрузчик или явно сохраняйте полные копии: одни только виртуальные импорты не дают файлов для офлайн-доступа.

Всё ещё не уверены? Напишите **ваше устройство или плеер, существующие аккаунты, можно ли оставить хост включённым и нужно ли воспроизведение по запросу или автоматическая библиотека**. Обычно эти ответы определяют маршрут. В разделе [Getting help](remote-help.md) написано, где задать вопрос.
