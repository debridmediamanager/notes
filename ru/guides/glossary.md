# Что делает каждая часть {#what-each-piece-does}

Названия сами по себе не говорят, что каждое делает, поэтому вот краткое описание каждого. Чтобы понять, какие из них вам нужны, воспользуйтесь разделом [Choose your setup](choose-your-setup.md).

## Три проекта {#the-three-projects}

| Название | Что делает |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Сайт для поиска релизов и добавления их в ваш аккаунт debrid. Также ищет по Usenet и Easynews. Бесплатно |
| [zurg](../zurg/index.md) | Все аккаунты debrid и Usenet в одной папке. Plex, Jellyfin, Emby, Infuse и rex читают эту папку как обычный диск. Для спонсоров |
| [rex](../rex/index.md) | Медиасервер, который не владеет никакими файлами. Его источники сообщают, что у них есть, и любое приложение Plex его воспроизводит. Бесплатно для личного использования |

## Просмотр прямо из DMM {#watching-straight-from-dmm}

Для всех этих не нужен сервер.

| Name | What it does |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio/) | Аддон для Stremio, который воспроизводит релизы из вашего аккаунта debrid или Easynews |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Просмотр, поиск и воспроизведение из вашего аккаунта debrid или Easynews прямо в Kodi |
| DMM Watch | Кнопка в DMM, которая открывает файл в вашем плеере, например VLC или Infuse |
| [DMM Music](https://debridmediamanager.com/music/) | Воспроизведение и загрузка музыки из Real-Debrid прямо в браузере |

## Подключаем rex {#feeding-rex}

| Name | What it does |
|---|---|
| [rex-stremio](../rex/stremio.md) | Превращает ваши аддоны Stremio в библиотеки rex, чтобы они воспроизводились в приложениях Plex. Бесплатно |
| [rex addons](../rex/addons.md) | Небольшие программы, которые дают rex что-то для воспроизведения: YouTube, Spotify, IPTV, домашние видео или всё, что вы напишете сами |
| [rex for Android](../rex/android.md) | rex и его аддоны на телефоне или ТВ-приставке с Android, без компьютера. Бесплатно. Для вашей библиотеки debrid и Usenet спонсоры используют zurg+rex |
| [zurg+rex for Android](../zurg/guides/android.md) | Сервер Plex на вашем телефоне: zurg и rex вместе на одном устройстве Android. Для спонсоров |

## Внутри Jellyfin и Emby {#inside-jellyfin-and-emby}

| Название | Что делает |
|---|---|
| [RD, AD, TB, PM, OC и DL zurg](https://debridmediamanager.com/jellyfin) | Отдельный плагин для каждого дебрид-провайдера. Ваша дебрид-библиотека появляется в Jellyfin или [Emby](https://debridmediamanager.com/emby) без приложения zurg и без монтирования. Для спонсоров |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Плагин для Jellyfin, который стримит NZB через ваш собственный аккаунт Usenet. Для спонсоров |

## Добавляем тайтлы для вас {#adding-titles-for-you}

| Название | Что делает |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Нажмите **Want** в DMM, и ваш zurg загрузит это, включая новые серии. Для спонсоров |
| [Seerr через DMM](../dmm/seerr.md) | Запросы семьи в Seerr попадают в ваш список Wanted. Для спонсоров |
| [Torznab и Newznab](https://debridmediamanager.com/torznab) | DMM как индексатор для Sonarr, Radarr и Prowlarr, с zurg как клиентом загрузки. Для спонсоров |
| [Stremio-аддон zurg](../zurg/guides/stremio.md) | Ищет в Usenet, когда вы нажимаете play в Stremio, и стримит через zurg |
| [`__magic__`](../zurg/guides/magic.md) | Папка zurg, которую вы настраиваете сами или доверяете Sonarr и Radarr |

## Остальное в DMM {#the-rest-of-dmm}

| Название | Что делает |
|---|---|
| [Доска запросов](https://debridmediamanager.com/requests) | Попросите релиз, которого нет в Real-Debrid. Другой пользователь DMM перенесёт его в вашу библиотеку. За выполненные запросы дают бонусы спонсора DMM |
| [Списки хешей](https://debridmediamanager.com/hashlists) | Делитесь списком релизов, чтобы другие могли добавить их в свои аккаунты |
| [Расширение для браузера](../dmm/safari.md) | Добавляет кнопки DMM на сайты с фильмами и сериалами и рядом с magnet-ссылками |
| [Страница спонсора](https://gatekeeper.debridmediamanager.com) | Здесь вы спонсируете проект и привязываете свой Patreon или GitHub Sponsors. [Что даёт спонсорство](sponsorship.md) |

## Слова, которые вы встретите в гайдах {#words-youll-see-in-the-guides}

| Слово | Что это значит |
|---|---|
| Debrid-провайдер | Платный сервис, который скачивает торренты за тебя и даёт их стримить: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Кэшировано | У провайдера уже есть этот релиз, так что он начинает играть сразу |
| Usenet | Ещё одно место, откуда берут релизы. Нужен аккаунт у Usenet-провайдера или TorBox Pro, чтобы он всё делал за тебя |
| NZB | Небольшой файл, в котором указано, где лежит релиз Usenet, как торрент-файл для торрентов |
| Индексер | Поисковый сайт с релизами. Sonarr и Radarr используют его, чтобы что-то найти |
| WebDAV | Способ делиться файлами через веб. Infuse, Kodi и многие TV-плееры умеют его открывать |
| Монтирование | Делает папку zurg похожей на локальный диск, чтобы Plex, Jellyfin или Emby могли её сканировать |
| Plex Media Server против приложений Plex | Сервер хранит твою библиотеку. Приложения на телевизоре и телефоне её проигрывают. rex заменяет сервер, а не приложения |
