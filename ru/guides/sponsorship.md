# Что даёт спонсорство {#what-a-sponsorship-gives-you}

DMM бесплатный. Спонсорство оплачивает хостинг и помогает zurg и rex работать дальше. На этой странице перечислены все бонусы и то, где их настроить.

Стань спонсором на [gatekeeper](https://gatekeeper.debridmediamanager.com/). Войди там, чтобы увидеть свой API-ключ DMM. **Open DMM with this key** привязывает ключ в этом браузере. Добавь тот же ключ в других сервисах, которые его запрашивают. Храни его в секрете, он работает как пароль.

Бонусы идут вместе со спонсорством. Когда оно заканчивается, DMM перестаёт их выдавать при следующем запросе. Плагины Jellyfin и Emby, которые ты уже установил, продолжат работать, но новые загрузки и обновления прекратятся. Gatekeeper отключит доступ zurg и роль в Discord при следующей проверке. **Reset key** сразу отключает старый ключ везде.

## zurg

| Что вы получаете | Где |
|---|---|
| Ночные сборки со всеми провайдерами и Usenet, а также образ Docker | [настройка zurg](../zurg/setup/index.md) после того, как вы примете приглашение на GitHub |
| Android-приложение zurg+rex, Plex-сервер прямо на телефоне | [руководство для Android](../zurg/guides/android.md) после того, как вы примете приглашение на GitHub |
| Полный исходный код zurg | Приватный репозиторий на GitHub |
| Каждый релиз с именем для rex и Plex | `dmm_api_key` в [конфиге zurg](../zurg/reference/config.md) |
| Данные о медиа из DMM без чтения файла заранее и проверки языков перед добавлением релиза | Ничего сверх `dmm_api_key` |
| Папки `__magic__`, которые сортируются автоматически, если включены | [\_\_magic\_\_](../zurg/guides/magic.md) |
| Ваш список желаемого из DMM, который забирает zurg | [список желаемого DMM](../zurg/guides/dmm-wanted.md) |
| Поиск по индексаторам Usenet и торрентов DMM, если у вас нет своих | `dmm_api_key` плюс провайдер Usenet или аккаунт debrid, который умеет добавлять торренты |
| Релизы, подобранные по оригинальному языку каждого тайтла | `original` в [аудио- и субтитровых языках](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) |
| Фильм, которого нет ни у одного индексатора, стримится с его официальной загрузки на YouTube | [Стриминг фильма с YouTube](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

Функции `dmm_api_key` требуют ночной сборки zurg. Бесплатная публичная сборка их не включает.

## DMM

| Что ты получаешь | Где |
|---|---|
| Список желаемого, который zurg сам собирает с новыми сериями и апгрейдами. Наполнить его можно из DMM, Kodi, списков Trakt и MDBList или из бэкапа Radarr или Sonarr | [DMM wanted list](../zurg/guides/dmm-wanted.md) |
| Запросы из Seerr, Overseerr или Jellyseerr попадают в твой список желаемого | [Seerr through DMM](../dmm/seerr.md) |
| Любой результат Easynews отправляется в твой zurg одним кликом | Результаты Easynews на странице фильма или сериала в DMM |
| DMM как индексатор Newznab для Usenet | [страница Newznab](https://debridmediamanager.com/newznab) в DMM |
| DMM как индексатор Torznab с лентами только для кэшированного для Real-Debrid, AllDebrid, Debrid-Link, TorBox, Premiumize и Offcloud | [страница Torznab](https://debridmediamanager.com/torznab) в DMM. Для TorBox, Premiumize и Offcloud также нужен ключ привязанного сервиса |
| Семь плагинов Jellyfin для дебрид- и Usenet-библиотек и шесть плагинов Emby для дебрид-библиотек без смонтированного хранилища | Страницы [Jellyfin](https://debridmediamanager.com/jellyfin) и [Emby](https://debridmediamanager.com/emby) в DMM |
| Десять других потоков на тайтл в Stremio Cast и Kodi вместо пяти | Настройки DMM Settings для Real-Debrid, TorBox и AllDebrid; страница Cast каждого провайдера для остальных |
| Загрузки NZB идут первыми, с 2 ТБ Usenet в день вместо 300 ГБ | Вкладка Usenet в DMM |
| Такой же приоритет и лимит для Sonarr и Radarr | Твой API-ключ DMM в поле Password на [странице SABnzbd](https://debridmediamanager.com/sabnzbd) в DMM |
| Три торрент-загрузки в Real-Debrid одновременно вместо одной | Кнопки загрузки в результатах поиска DMM и в библиотеке |
| Add to DMM Wanted и папка Wanted внутри Kodi | Подключи Kodi на [странице Kodi](https://debridmediamanager.com/kodi) в DMM |
| API DMM для названий релизов, проверки кэша, данных о медиа и метаданных | [API docs](https://debridmediamanager.com/api-docs) |

## rex

rex бесплатный и не требует спонсорства, в том числе на Android: [rex for Android](https://github.com/debridmediamanager/rex-android) запускает rex и его дополнения на телефоне или ТВ-приставке. С ключом [rex-stremio](../rex/stremio.md) добавляет потоки debrid для торрентов, по которым DMM уже имеет результат проверки, за считаные секунды вместо проверки каждого торрента по отдельности. Вставьте его в поле **DMM** в rex-stremio. Он делится своими результатами проверки торрент-файлов с DMM, если вы не отключите это.

## Помощь {#help}

| Что вы получаете | Где |
|---|---|
| Бесплатную удалённую помощь с zurg и rex прямо в вашем терминале, пока вы смотрите | [Получение помощи](remote-help.md) |
| Роль Sponsor в Discord | Подключите Discord в gatekeeper |

## Получите это без оплаты {#earn-it-without-paying}

Выполняйте запросы на [доске запросов](https://debridmediamanager.com/requests) DMM. За каждые 10 выполненных запросов вы получаете 7 дней перков DMM, которые указаны выше. Засчитывается только одно выполнение для одного и того же человека в день. Чтобы получить их, привяжите ключ из бесплатного аккаунта gatekeeper на доске.

Заработанное время открывает таблицу DMM, которая указана выше. Оно не открывает ночные сборки zurg, исходный код, роль в Discord, удалённую помощь или приложение для Android. Для этого нужно платное спонсорство. Функции `dmm_api_key` также требуют ночную сборку.

Застряли? Спросите в форуме **dmm-support** на [Discord](https://discord.com/invite/7u4YjMThXP).
