# Что делает каждая часть {#what-each-piece-does}

Названия сами по себе не говорят, что каждая из них делает, поэтому вот по одной строке на каждую. Всё, что не отмечено **For sponsors**, бесплатно. Чтобы понять, какие из них вам нужны, используйте [Choose your setup](choose-your-setup.md).

## Три проекта {#the-three-projects}

| Название | Что делает |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Сайт для поиска релизов и добавления их в ваш аккаунт debrid. Также ищет по Usenet и Easynews |
| [zurg](../zurg/index.md) | Все аккаунты debrid и Usenet как одна библиотека. Plex, Jellyfin и Emby читают её как папку, Infuse и Kodi через WebDAV, а rex получает её напрямую. Актуальные сборки доступны только спонсорам |
| [rex](../rex/index.md) | Медиасервер для приложений Plex, у которого нет собственных файлов. zurg или дополнение сообщает ему, что есть в наличии. Бесплатно для личного использования |

## Просмотр прямо из DMM {#watching-straight-from-dmm}

Для всех этих вариантов сервер не нужен.

| Name | What it does |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | Аддон для Stremio, который воспроизводит релизы из вашего аккаунта debrid или Easynews. Работает и в Nuvio |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Просмотр, поиск и воспроизведение из вашего аккаунта debrid или Easynews прямо в Kodi |
| DMM Watch | Кнопка в DMM, которая открывает файл в вашем плеере, например VLC или Infuse |

## Подключаем rex {#feeding-rex}

| Название | Что делает |
|---|---|
| [rex-stremio](../rex/stremio.md) | Превращает твои аддоны Stremio в библиотеки rex, чтобы они играли в приложениях Plex |
| [аддоны rex](../rex/addons.md) | Небольшие программы, которые дают rex что-то для воспроизведения: YouTube, Spotify, IPTV, домашние видео или всё, что ты сам напишешь |
| [rex-live-sports](../rex/live-tv.md) | Аддон rex, который добавляет каналы live-спорта и телепрограмму в Live TV приложений Plex |
| [rex-direct](../rex/any-source.md#rex-direct) | Даёт твоему rex собственный защищённый адрес, чтобы приложения Plex могли до него достучаться вне дома |
| [rex для Android](../rex/android.md) | rex и его аддоны на телефоне или ТВ-приставке с Android, без компьютера |
| [zurg+rex для Android](../zurg/guides/android.md) | Сервер Plex на телефоне: zurg и rex вместе на одном устройстве Android, с твоей библиотекой debrid и Usenet. Для спонсоров |

## Внутри Jellyfin и Emby {#inside-jellyfin-and-emby}

| Name | Что делает |
|---|---|
| [Debrid plugins](https://debridmediamanager.com/jellyfin) (RD zurg, AD zurg, TB zurg, PM zurg, OC zurg, DL zurg) | Один плагин на каждого провайдера дебрид: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud и Debrid-Link. Твоя библиотека дебрид появляется в Jellyfin или [Emby](https://debridmediamanager.com/emby) без приложения zurg и без монтирования. Для спонсоров |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Плагин для Jellyfin, который стримит NZB через твой собственный аккаунт Usenet. Для спонсоров |

## Добавляем тайтлы для вас {#adding-titles-for-you}

| Name | What it does |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Нажмите **Want** в DMM, и ваш zurg сам всё скачает, включая новые серии. Для спонсоров |
| [Seerr through DMM](../dmm/seerr.md) | Запросы семьи в Seerr попадают в ваш список Wanted. Для спонсоров |
| [Torznab](https://debridmediamanager.com/torznab) and [Newznab](https://debridmediamanager.com/newznab) | DMM как индексатор для Sonarr, Radarr и Prowlarr. Для спонсоров |
| zurg as the download client | zurg отвечает Sonarr и Radarr как qBittorrent для [торрентов](../zurg/guides/sonarr-radarr-torrents.md) и как SABnzbd для [Usenet](../zurg/guides/sonarr-radarr.md), так что ни то, ни другое запускать не нужно. Для спонсоров |
| [zurg's Stremio addon](../zurg/guides/stremio.md) | Ищет в Usenet, когда вы нажимаете play в Stremio, и стримит через zurg. Для спонсоров |
| [`__magic__`](../zurg/guides/magic.md) | Папка zurg, которую вы настраиваете сами или доверяете Sonarr и Radarr. Для спонсоров |

## Остальное в DMM {#the-rest-of-dmm}

| Name | What it does |
|---|---|
| Usenet tab | Sends a Usenet release to your Real-Debrid library, with no Usenet account. Sponsors go first and get a bigger daily allowance |
| [Request board](https://debridmediamanager.com/requests) | Попроси релиз, которого нет у Real-Debrid. Другой пользователь DMM перенесёт его в твою библиотеку. Заполни 10 запросов и получи 7 дней бонусов спонсора DMM |
| [Hash lists](https://debridmediamanager.com/hashlists) | Делись списком релизов, чтобы другие могли добавить их в свои аккаунты |
| Browser extension | Добавляет кнопки DMM на сайты с фильмами и сериалами и рядом с magnet-ссылками. Для [Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm), [Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/) и [Safari](../dmm/safari.md) |
| [gatekeeper](https://gatekeeper.debridmediamanager.com) | Сайт спонсоров. Стань спонсором там, привяжи свой план на Patreon или GitHub Sponsors и получи свой API-ключ DMM. [Что даёт спонсорство](sponsorship.md) |

## Слова, которые вы встретите в гайдах {#words-youll-see-in-the-guides}

| Слово | Что это значит |
|---|---|
| Релиз | Одна копия фильма, серии или сезона, как её опубликовал кто-то. У тайтла обычно много релизов в разном качестве |
| Debrid-провайдер | Платный сервис, который скачивает торренты за тебя и позволяет их стримить: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | У провайдера уже есть этот релиз, поэтому он запускается сразу |
| Usenet | Ещё одно место, откуда берутся релизы. Используй свой аккаунт Usenet, пусть это сделают TorBox Pro или Easynews, или отправь результат в Real-Debrid через DMM |
| Easynews | Платный сервис Usenet со своим поиском, который воспроизводит файлы прямо через веб |
| NZB | Небольшой файл, который указывает, где лежит релиз Usenet, так же как торрент-файл делает это для торрентов |
| Indexer | Поисковый сайт для релизов. Sonarr и Radarr используют его, чтобы что-то найти |
| Sonarr, Radarr и Prowlarr | Приложения, которые получают тайтлы за тебя: Sonarr для сериалов, Radarr для фильмов. Prowlarr хранит их индексеры в одном месте |
| Seerr | Сайт запросов для семьи и друзей. Overseerr и Jellyseerr работают так же |
| Stremio, Nuvio и Kodi | Приложения-медиаплееры. Аддоны дают им, что проигрывать. Nuvio принимает аддоны Stremio |
| DMM API key | Ключ спонсора от gatekeeper. Вставь его туда, где просит гайд, и храни в секрете, как пароль |
| Nightly | Самая новая сборка zurg или rex, которая делается каждую ночь. Ночные сборки zurg доступны только спонсорам |
| WebDAV | Способ делиться файлами через веб. Infuse, Kodi и многие ТВ-плееры умеют его открывать |
| Mount | Делает папку zurg похожей на локальный диск, чтобы Plex, Jellyfin или Emby могли её сканировать |
| rclone | Инструмент, который zurg использует для монтирования. Настройка zurg устанавливает его за тебя |
| `.strm` | Небольшой файл, который хранит ссылку вместо видео, для плееров вроде Kodi |
| Source | Всё, что сообщает rex, что у него есть, и отдаёт файлы: zurg, rex-stremio или аддон |
| Claim | Привязка rex к аккаунту Plex, чтобы он мог показывать тайтлы и постеры, а приложения Plex могли его найти |
| Plex Media Server vs Plex apps | Сервер хранит твою библиотеку. Приложения на телевизоре и телефоне её воспроизводят. rex заменяет сервер, а не приложения |
