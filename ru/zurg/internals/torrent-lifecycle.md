# Жизненный цикл торрента на Real-Debrid, AllDebrid и TorBox {#torrent-lifecycle-on-real-debrid-alldebrid-and-torbox}

Проверено 2026-08-30 на живых аккаунтах. Всё, что помечено **наблюдалось**, получено из захвата трафика. Всё, что помечено **выведено**, из захвата не получено, и в тексте написано почему.

zurg это нужно, потому что qBittorrent-прослойка должна сообщать Sonarr и Radarr, на каком этапе находится загрузка. Сейчас она не может. `TorrentInfo.Status` хранит словарь статусов Real-Debrid, а пакеты AllDebrid и TorBox переводят статусы в него ещё до того, как код zurg увидит торрент. TorBox `stalled (no seeds)` приходит как `queued`. Сидеров, скорость и eta вообще никуда не передаются. Поэтому таблицу стадий пришлось строить по сырым ответам из сети, а не по пакетам провайдеров, которые эти статусы уже приводят к одному виду.

Харнесс это `scripts/torrent_lifecycle_probe.py`. Он обращается напрямую к REST API, так что захваченные статусы идут от провайдера без изменений. При выходе он удаляет всё, что добавил, в том числе при Ctrl-C.

## Как это измерялось {#how-this-was-measured}

### Аккаунты {#the-accounts}

| Провайдер | Аккаунт | Почему именно этот |
|---|---|---|
| Real-Debrid | тестовый аккаунт | никакой запущенный zurg его не использует, так что во время прогона ничего другого его не трогало |
| AllDebrid | тестовый ключ | на аккаунте уже были другие magnet-ссылки, поэтому удалялись только те id, которые создал прогон |
| TorBox | боевой ключ | **к тому же аккаунту был подключён ещё один экземпляр zurg**, и это не сноска. См. [Hazards](#hazards-found-on-the-way) |

Учётные данные берутся из `RD_TOKEN` `AD_KEY` `TB_KEY` в окружении. Ничего не записывает их в
capture.

### Торренты {#the-torrents}

Всё законно. Образы FOSS и фильм в общественном достоянии. Каждый info hash, взятый из `.torrent`, был пересчитан из файла самим харнессом, а не введён вручную. Размеры роя — это данные скрейпа трекера, снятые в тот же день.

| Кейс | Торрент | Info hash | Размер | Сиды на трекере | Веб-сиды |
|---|---|---|---|---|---|
| в кэше | Big Buck Bunny | `dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c` | 264 MiB | н/д | н/д |
| в кэше | Sintel | `08ada5a7a6183aae1e09d831df6748d566095a10` | 123 MiB | н/д | н/д |
| в кэше | ubuntu-26.04.1-desktop-amd64.iso | `5b1e0d988fc7a0c9e99bd852071681a59974b39f` | 6.04 GiB | от 22 до 27 | нет |
| не в кэше | debian-13.6.0-arm64-DVD-1.iso | `4d38178b8f08447ea8609e844b0071354ed65887` | 3.72 GiB | 212 | 2 |
| не в кэше | debian-13.2.0-amd64-DVD-1.iso | `7f23b66ebc763f6d931e999583adfd22a7d796fa` | 3.71 GiB | 328 | 2 |
| веб-сид | Prelinger `205882_Home_Movie_005588` | `69e7bba940b3c2edf7ce517330e3ca904877d8d1` | 0.71 GiB | 0 сидов и 0 личеров | 3 |
| без сидов | ubuntu-16.04.6-desktop-i386.iso | `c16796a74dc24cc7c6df2f7b66b861e22dec69b1` | 1.56 GiB | 0 | нет |
| без сидов | ubuntu-24.04-beta-live-server-s390x.iso | `8e693ebcdda44f741e2034cedbb552e93944143d` | 1.18 GiB | 0 | нет |
| без метаданных | случайные 40 hex | `3f9c1a77b0e4d2568af3c01e9b7d4a5268c1f0e3` | нет | нет | нет |

Нули настоящие, а не признак мёртвого трекера. `torrent.ubuntu.com` опрашивали дважды для всех трёх записей Ubuntu в одном цикле: для 26.04.1 он ответил сначала 22, потом 27 сидов, а для двух записей без сидов отвечал пустым `d5:filesdee`. То же самое с `bt1.archive.org` и элементом Prelinger.

TorBox `checkcached` проверили по каждому хэшу до добавления чего-либо. Это единственный из трёх способов проверки кэша, который ничего не меняет. Он сказал «в кэше» для трёх строк с кэшем и «не в кэше» для остальных шести. Именно такое разделение и заявлено в названиях кейсов.

### Частота опроса и лимиты {#poll-cadence-and-caps}

3 s на первые 2 минуты, потом 15 s. 1 s для кэшированного случая, потому что весь жизненный цикл там может
завершиться внутри одного обычного опроса. Лимит 15 минут на торрент для кампании, а не значение по умолчанию в скрипте, равное 30. Предлагаемый в shim таймаут по умолчанию составляет 10 минут, а торрент, который всё ещё движется на 15-й минуте, уже вышел за единственное окно, которое имеет значение. Добавления в Real-Debrid разносятся минимум на 20 s друг от друга.

Каждый провайдер запускался как отдельный процесс со своим выходным каталогом. Это сохраняет честное соблюдение интервала между добавлениями в Real-Debrid внутри одного процесса и позволяет всем трём работать одновременно.

## Real-Debrid

### Эндпоинты {#endpoints}

```
POST   /rest/1.0/torrents/addMagnet          magnet=magnet:?xt=urn:btih:<hash>   -> 201 {"id","uri"}
POST   /rest/1.0/torrents/selectFiles/{id}   files=all                           -> 204
GET    /rest/1.0/torrents/info/{id}                                              -> 200 object
DELETE /rest/1.0/torrents/delete/{id}                                            -> 204
```

### Наблюдаемые значения статуса {#status-values-observed}

`waiting_files_selection` `magnet_conversion` `magnet_error` `queued` `downloading` `uploading`
`downloaded`

Здесь не наблюдается. `compressing` `virus` `error` `dead`. Для них нужен контент, которого у этой кампании не было законного способа получить.

### Какие поля ответа есть в каком статусе {#which-wire-fields-exist-in-which-status}

| Поле | magnet_conversion | queued | downloading | uploading | downloaded |
|---|---|---|---|---|---|
| `status` | да | да | да | да | да |
| `progress` | 0 | 0 | **float, процент от 0 до 100** | **сбрасывается в 0** и растёт до 100 | 100 |
| `seeders` | да | **отсутствует** | да | **отсутствует** | **отсутствует** |
| `speed` | **отсутствует** | **отсутствует** | да, байт в секунду | да, в захвате всегда 0 | **отсутствует** |
| `bytes` / `original_bytes` | 0 | реальный размер | реальный размер | реальный размер | реальный размер |
| `filename` | `"Magnet"` | реальное имя | реальное имя | реальное имя | реальное имя |
| `files` | `[]` | заполнено | заполнено | заполнено | заполнено |
| `links` | `[]` | `[]` | `[]` | заполняется на этом этапе | заполнено |
| `ended` | отсутствует | отсутствует | отсутствует | отсутствует | есть |

Это важнее, чем словарный запас. Поля появляются и исчезают. Маппер, который читает `speed` в каждом состоянии, в половине случаев получит отсутствующий ключ.

`progress` — это **float**, а не целое число. В захвате есть значения 0.4, 0.8 и 1.4 наряду с 100.
Детектор зависания, который округляет процент до целого, посчитает релиз на 100 ГБ зависшим при скорости 1 МБ/с.

`progress` **намеренно идёт назад**. Он сбрасывается в 0, когда статус переходит в `uploading`, и снова растёт до 100.
Движение нужно определять как смену этапа или рост progress, а не как монотонный процент.

`seeders` исчезает, а не становится нулём, когда торрент выходит из `downloading`. То же самое относится и к `speed`.
Маппер должен считать отсутствующий ключ неизвестным значением, а не нулём.

### Что делал каждый кейс {#what-each-case-did}

| Случай | Торрент | Переходы с секундами от добавления | Вердикт |
|---|---|---|---|
| кэш | Big Buck Bunny | `downloaded`@0.0 | готово за 1.32 s от начала до конца |
| кэш | Sintel | `downloaded`@0.0 | готово за 0.73 s |
| кэш | Ubuntu 26.04.1 | `downloaded`@0.0 | готово за 0.32 s |
| без кэша | Debian 13.6.0 arm64 DVD-1 | `downloaded`@0.0 | уже закэширован на этом аккаунте |
| без кэша | Debian 13.2.0 amd64 DVD-1 | `queued`@0.0 `downloading`@3.1 `uploading`@166.5 `downloaded`@196.8 | готово. 3.71 GiB за 197 s |
| webseed | домашнее видео Prelinger | `magnet_conversion`@0.0 `magnet_error`@318.0 | ошибка |
| без сидов | ubuntu-16.04.6-desktop-i386 | `queued`@0.0 `downloading`@3.1 `uploading` `downloaded`@166.8 | готово. Случай не воспроизвёлся |
| без сидов | ubuntu-24.04-beta-live-server-s390x | `queued`@0.0 `downloading`@3.1 и ничего после этого | **обрезано на 907.6 s, всё ещё `downloading`**. Это похоже на зависание |
| без метаданных | случайный 40-hex | `magnet_conversion`@0.0 `magnet_error`@317.9 | ошибка |

### Задержка добавления кешированного торрента {#the-cached-add-latency}

Это число, на котором держится режим shim в cached-only.

| Torrent | addMagnet возвращает | selectFiles возвращает | первый `/torrents/info` | status |
|---|---|---|---|---|
| Big Buck Bunny | t=0 | t+1.211 s | t+1.318 s | `downloaded` |
| Sintel | t=0 | t+0.632 s | t+0.729 s | `downloaded` |
| Ubuntu 26.04.1 | t=0 | t+0.215 s | t+0.320 s | `downloaded` |

**Наблюдаем.** Закэшированный торрент уже `downloaded` при самом первом чтении после `selectFiles`. Весь синхронный отрезок занимает два round trip. Он не проходит ни `queued`, ни `downloading`.

Во втором прогоне мы опрашивали `/torrents/info` с интервалом 0,25 s и между `addMagnet` и `selectFiles`, и после него. Так работает `--rd-select-detail`, и это окончательно проясняет картину.

| Torrent | Status до `selectFiles` | `selectFiles` | Первое чтение после него | addMagnet до `downloaded` |
|---|---|---|---|---|
| Big Buck Bunny | `waiting_files_selection`, в списке 3 файла, `links` пустой | 204 в t+1.314 s | `downloaded`, `progress` 100, `links` 1 | **1.535 s** |
| Sintel | `waiting_files_selection`, в списке 11 файлов | 204 в t+0.627 s | `downloaded`, `progress` 100, `links` 1 | **0.841 s** |
| Ubuntu 26.04.1 | `waiting_files_selection`, в списке 1 файл | 204 в t+0.219 s | `downloaded`, `progress` 100, `links` 1 | **0.430 s** |

Итак, полная последовательность для закэшированного торрента такая: `waiting_files_selection`, затем `downloaded`, и ничего между ними. Список файлов уже есть до `selectFiles`. `links` заполняет именно `selectFiles`.

**Окно проверки cached-only может быть одним опросом.** От 0,43 s до 1,54 s от начала до конца на трёх торрентах размером 123 MiB, 264 MiB и 6.04 GiB. Окно в две секунды при опросе раз в четверть секунды с запасом.

Sonarr и Radarr дают на вызов `torrents/add` 100 s (см. [qbittorrent-client-contract.md §1.7a](qbittorrent-client-contract.md)). На этом фоне окно проверки cached-only в пару секунд ничего не стоит. Причин ставить его в десятки секунд нет.

### Особенности, с которыми должен справляться маппер стадий {#quirks-a-stage-mapper-has-to-survive}

- **`selectFiles` отвечает 404, пока торрент ещё в `magnet_conversion`, и ошибка врёт.** Тело ответа: `{"error":"parameter_missing","error_code":1,"error_details":"{files} is missing"}`, хотя `files=all` был отправлен. Файлов просто ещё нет, чтобы их выбрать. Это не сбой добавления, и торрент остаётся живым. Оба прогона, где это случилось, прожили ещё 318 s.
- **Хеш приватного трекера может быть сразу признан мёртвым, а не через 318 s.** Хеш из отчёта qBittorrent от 2026-08-31 (ремукс CiNEPHiLES с индексатора UNIT3D, `45e1ec0d…`) при первом чтении после addMagnet, через несколько секунд после добавления, вернул `magnet_error` с нулём файлов. Окна `magnet_conversion` не было вообще. Узнал ли Real-Debrid хеш или быстро отказал, наблюдаемый результат один и тот же: у приватного хеша нет DHT-роя, поэтому addMagnet для него never не может пройти, а selectFiles на мёртвом экземпляре отвечает тем самым обманчивым 404.
- **`addTorrent` ничего не пропускает для некэшированного контента, но всё пропускает для кэшированного.** `.torrent`, загруженный для контента, которого нет у Real-Debrid (Big Buck Bunny с archive.org, раздаётся, но не в кэше), попал в `magnet_conversion`, как голая магнит-ссылка: метаданные файла для разрешения не использовались. Кэшированный (Ubuntu ISO) сразу при первом чтении ответил `waiting_files_selection` со списком файлов, был выбран и за две секунды перешёл в `downloaded`, вообще не проходя через `magnet_conversion`. Значит, польза загрузки файла в том, что он даёт мгновенную проверку хеша по кэшу. Именно поэтому релиз с приватного трекера можно добавить, если контент в кэше, и никогда нельзя добавить как магнит.
- **Разрешение метаданных сдаётся через 318 s.** Два независимых прогона перешли из `magnet_conversion` в `magnet_error` на 317.9 s и 318.0 s. Это предел, на котором останавливается магнит без доступных пиров. Так происходит независимо от того, существует ли торрент для этого хеша.
- **`seeders` врёт во время `magnet_conversion`.** Случайный 40-символьный хеш показал `seeders: 1` на 80.9 s. Торрента для него не существует.
- **`ended` у только что добавленного кэшированного торрента несёт старую дату.** В захваченных данных для торрентов, добавленных 2026-08-30, стоят `2025-12-28` и `2026-07-28`. Это момент, когда Real-Debrid впервые получил контент, а не когда этот экземпляр его закончил. Не вычисляй по ней возраст.
- **Магнит без пиров умирает на этапе разрешения метаданных и до веб-сида не доходит.** Real-Debrid учитывает веб-сиды, как только получил торрент. Но получить торрент из магнита без пиров он не может. Поэтому элемент, который состоит только из веб-сида и добавлен как магнит, заканчивается `magnet_error`. Это ошибка метаданных, а не веб-сида, и из `/torrents/info` они выглядят одинаково.

## AllDebrid

### Эндпоинты {#endpoints-1}

`v4` и `v4.1` не взаимозаменяемы, и эта разница аукнулась в этой кампании.

```
POST /v4/magnet/upload      magnets[]=magnet:?xt=urn:btih:<hash>   -> 200, per-magnet `ready` flag
POST /v4/magnet/upload/file multipart files[]=<the .torrent>       -> 200, per-file `ready` flag
GET  /v4.1/magnet/status?id=<id>                                   -> 200, data.magnets is an OBJECT
GET  /v4.1/magnet/status                                           -> 200, data.magnets is a LIST
POST /v4/magnet/delete      id=<id>                                -> 200
```

**Загрузка файла отвечает в поле `files`, а не `magnets`.** Поля у каждой записи те же: `id`, `hash`, `name`, `ready` и необязательный `error` для записи. Поэтому флаг `ready` ниже в любом случае является ответом кэша, но декодер, написанный под ответ для magnet, прочитает пустой список.

**И файл — единственная форма релиза, которую AllDebrid может описать без swarm.** Замерено 01.09.2026 на тестовом аккаунте: два синтетических приватных торрента одинаковой формы, хеши которых ни один swarm никогда не видел. Загруженные как файлы, они вернулись с настоящими именами и настоящими размерами (`"name":"zurg.private.ad.probe","size":65536`), в списке имели статус `In queue`, а таймер ещё не был запущен. Отправленный голым хешем в `magnets[]` ответ был `"name":"noname","size":0`. AllDebrid принял его и ничего о нём не знал. Так выглядит любой релиз с приватного трекера, добавленный по хешу.

**`/v4/magnet/status` больше не работает.** С id и без него он отвечает HTTP 200 с телом `{"status":"error","error":{"code":"DISCONTINUED"},"deprecated":true}`. `/v4/magnet/upload` и `/v4/magnet/delete` при этом работают. Значит, предположение плана о том, что можно использовать статусный эндпоинт v4, а v4.1 опросить один раз для сравнения, было перевёрнуто с ног на голову. v4.1 — единственный статусный эндпоинт. Харнесс записывает одно чтение v4 на каждый торрент, чтобы запись (capture) содержала доказательство, а не утверждение.

Авторизация: `Authorization: Bearer <apikey>`. Параметр `agent` не нужен.

### Наблюдаемые значения статуса {#status-values-observed-1}

| `statusCode` | `status` | Seen |
|---|---|---|
| 0 | `In queue` | yes |
| 1 | `Downloading` | yes |
| 2 | `Compressing / Moving` | **no** |
| 3 | `Uploading` | yes |
| 4 | `Ready` | yes |
| 5 and above | the error codes | **no** |

### Какие поля ответа есть в каком статусе {#which-wire-fields-exist-in-which-status-1}

| Поле | In queue (0) | Downloading (1) | Uploading (3) | Ready (4) |
|---|---|---|---|---|
| `status` / `statusCode` | да | да | да | да |
| `version` | 1 | 2 | 2 | 2 |
| `filename` | `"noname"` до получения метаданных | настоящее имя после получения метаданных | настоящее имя | настоящее имя |
| `size` | 0 до получения метаданных | настоящий размер | настоящий размер | настоящий размер |
| `downloaded` | 0 | **значение прогресса в байтах** | равно `size` | **отсутствует** |
| `downloadSpeed` | 0 | да, в байтах в секунду | 0 | **отсутствует** |
| `seeders` | 0 | да | 0 | **отсутствует** |
| `uploaded` / `uploadSpeed` | 0 | 0 | **значение прогресса для этой фазы** | **отсутствует** |
| `processingPerc` | 0 | 0 | 0 | **отсутствует** |
| `files` / `nbLinks` | отсутствуют | отсутствуют | отсутствуют | есть |
| `completionDate` | 0 | 0 | 0 | заполнено |

**Процентов нигде нет.** Прогресс на AllDebrid считается как `downloaded / size`, и оба значения — целые числа в байтах. `processingPerc` оставался 0 во всех состояниях во всех снимках.

`Uploading` — это когда AllDebrid переносит готовую загрузку в своё хранилище. У этой фазы свой счётчик прогресса в `uploaded` и `uploadSpeed`, а `downloadSpeed` всё это время равен 0. Если правило для определения зависания смотрит только на `downloaded`, оно сочтёт нормально идущую фазу `Uploading` зависшей.

### Что делал каждый кейс {#what-each-case-did-1}

| Случай | Торрент | `ready` при загрузке | Переходы с секундами от добавления | Итог |
|---|---|---|---|---|
| в кэше | Big Buck Bunny | true | `Ready`@0.0 | готово за 0.11 с |
| в кэше | Sintel | true | `Ready`@0.0 | готово за 0.12 с |
| в кэше | Ubuntu 26.04.1 | true | `Ready`@0.0 | готово за 0.11 с |
| не в кэше | Debian 13.6.0 arm64 DVD-1 | true | `Ready`@0.0 | уже в кэше |
| не в кэше | Debian 13.2.0 amd64 DVD-1 | false | `In queue`@0.0 `Downloading`@12.5 со всеми счётчиками на нуле до 634.9 `Uploading`@650.1 `Ready`@876.9 | готово за 877 с |
| webseed | Prelinger home movie | false | `In queue`@0.0 `Downloading`@6.3 и все счётчики на нуле после этого | **обрезано на 907.8 с, всё ещё `Downloading`** |
| seedless | ubuntu-16.04.6-desktop-i386 | false | `In queue`@0.0 `Downloading`@9.4 со всеми счётчиками на нуле до 589.6 `Uploading`@619.9 `Ready`@650.2 | готово за 650 с |
| seedless | ubuntu-24.04-beta-live-server-s390x | false | `In queue`@0.0 `Downloading`@3.2 и все счётчики на нуле после этого | **обрезано на 907.0 с, всё ещё `Downloading`** |
| nometa | случайный 40-hex | false | `In queue`@0.0 `Downloading`@9.4 и все счётчики на нуле после этого | **обрезано на 907.4 с, всё ещё `Downloading`** |

Отдельный прогон для Debian 13.3.0 arm64 DVD-1 (`6aa9b0a4709a0d6c4982fd0363614d9006877223`) зафиксировал полный жизненный цикл незакэшированного торрента и служит эталонной последовательностью.

| Секунды | Состояние | Что изменилось |
|---|---|---|
| 0.0 | `In queue` 0 версия 1 | `filename` равен `"noname"`, а `size` равен 0 |
| 2.2 | `Downloading` 1 версия 2 | всё ещё нет имени и размера |
| 4.3 | `Downloading` | `filename` и `size` появляются |
| от 6.5 до 55.1 | `Downloading` | `downloaded` растёт до `size`. `downloadSpeed` достигает пика около 110 МБ/с. `seeders` от 8 до 9 |
| 57.2 | `Uploading` 3 | `downloadSpeed` падает до 0. `uploadSpeed` и `uploaded` начинают расти |
| 65.6 | `Ready` 4 | появляются `files` и `nbLinks`. Шесть полей прогресса исчезают |

3.72 GiB за 65.6 с.

### AllDebrid не показывает никакого прогресса, пока задача ждёт собственную инфраструктуру {#alldebrid-reports-no-progress-at-all-while-a-job-waits-for-its-own-infrastructure}

Это находка, которая сильнее всего меняет дизайн таймаута, и поверить в неё удалось только после двух независимых прогонов.

`Downloading` со `statusCode` 1 появляется через несколько секунд после загрузки. Некоторое время после этого AllDebrid сообщает `downloaded` 0, `downloadSpeed` 0, `seeders` 0, `uploaded` 0, `uploadSpeed` 0 и `processingPerc` 0. Он также сбрасывает `size` обратно в 0, а `filename` обратно в info hash, даже если до этого уже сообщил оба значения правильно.

| Прогон | Сколько времени все счётчики оставались нулевыми | Что случилось дальше |
|---|---|---|
| Debian 13.2.0 amd64 DVD-1 | **622 с** с 12.5 с до 634.9 с | 3.71 GiB скачано за 15 с, затем `Uploading`, затем `Ready` на 876.9 с |
| ubuntu-16.04.6-desktop-i386 | **580 с** с 9.4 с до 589.6 с | 1.56 GiB скачано за 30 с, затем `Uploading`, затем `Ready` на 650.2 с |

Оба завершились успешно. Ни в одном не было ни одного байта движения первые десять минут.

**Таймаут на отсутствие движения в десять минут отменил бы здоровые задания AllDebrid.** Предложенное значение по умолчанию `download_timeout_mins`, равное 10, попадает в это окно в обоих из двух случаев. Либо таймаут должен быть длиннее, либо AllDebrid `Downloading` с `size` 0 должен считаться отдельным этапом, на который таймер не распространяется. Потеря имени и размера — это способ AllDebrid показать, что задание назначено, но ещё не запущено, а не ошибка.

Контрастом служит прогон, который стартовал сразу. Debian 13.3.0 arm64 DVD-1 перешёл из `In queue` к реальным счётчикам байтов за 6.5 с. Значит, ожидание — это очередь, а не фиксированная задержка.

### Флаг `ready` — это настоящий ответ кеша {#the-ready-flag-is-a-real-cache-answer}

Поле `ready` в ответе `/v4/magnet/upload` было true для каждого хэша, который TorBox тоже считал закешированным, и false для двух, которые кампания скачала. У AllDebrid нет отдельной проверки кеша, так что этот флаг и есть весь сигнал о кеше. zurg теперь передаёт его из обоих путей добавления, из магнет-ссылки и из загрузки файла, как `MagnetResponse.Cached` с установленным `CacheKnown`. Так бэкенд, который не может ответить, никогда не примут за бэкенд, который сообщает о промахе.

**Ложное `ready` означает, что магнет уже добавлен.** Спросить AllDebrid, закеширован ли хэш, не добавив его, нельзя. Путь «только закешированное» на AllDebrid должен удалять промах.

## TorBox

### Эндпоинты {#endpoints-2}

```
GET  /v1/api/torrents/checkcached?hash=<hash>&format=list
POST /v1/api/torrents/createtorrent      magnet=…&seed=3&allow_zip=false   -> {"success":true,"data":{"torrent_id":N}}
POST /v1/api/torrents/createtorrent      multipart file=<the .torrent>    -> the same shape; `detail` says whether it was cached
GET  /v1/api/torrents/mylist?id=<id>&bypass_cache=true
POST /v1/api/torrents/controltorrent     {"torrent_id":N,"operation":"delete"}
```

### Наблюдаемые значения статуса {#status-values-observed-2}

`metaDL` `checking` `stalledDL` `stalled (no seeds)` `downloading` `processing`
`uploading (no peers)` `uploading` `cached`

`processing`, `checking` и `stalledDL` **отсутствуют в таблице переводов zurg**
(`internal/torbox/types.go`, `normalizeStatus`). Все три попадают в ветку по умолчанию и отображаются
как `downloading`.

`checking` — это этап, на котором TorBox ждёт метаданные, а не проверяет хеш. Если рой (swarm) для magnet-ссылки не отвечает, статус переходит из `metaDL` в `checking` и там и остаётся. Случайный 40-hex хеш всё ещё был в `checking` на лимите 910 с, и элемент Prelinger без пиров в 911 с тоже. TorBox никогда не сдаётся так, как Real-Debrid в 318 с.

**Загрузка `.torrent` пропускает это ожидание целиком, и именно в этом вся разница для релиза с приватного трекера.** Измерено 2026-09-01 на аккаунте выше: один и тот же синтетический приватный торрент отправлялся двумя способами. Как хеш: принят с `torrent_id`, затем `checking` с `name`, равным голому хешу, `size: -1`, `files: null` и `eta: 8640000` — TorBox ищет рой, которого нет в DHT, и будет так делать до лимита, ничего об этом не сообщая. Как файл, на `POST /torrents/createtorrent` с байтами в multipart-части `file`: через три секунды в ответе было собственное имя торрента, его реальный размер и `stalled (no seeds)` — тот же контент, который никто не раздаёт, но теперь он описан. Важен именно этап. `checking` с `size: -1` соответствует `StageResolvingMetadata`, что означает «работа идёт, выводов делать нельзя»; `stalled (no seeds)` соответствует `StageStalledNoPeers`, с которым может работать эндпоинт qBittorrent. Закэшированный релиз через те же три секунды вернулся как `done` со 100% и списком файлов. Имя части имеет значение: файл, отправленный под любым другим именем, вообще не виден, и эндпоинт отвечает `MISSING_REQUIRED_OPTION`, "You must provide either a file or magnet link".

(Предыдущий вариант перевода был отклонён: кодовые фрагменты различаются (` maps to `). Сохраните структуру в точности.)

### Какие поля ответа есть в каком статусе {#which-wire-fields-exist-in-which-status-2}

TorBox отдаёт один и тот же набор ключей в каждом состоянии и меняет только значения. Поэтому его проще всего читать из трёх. Смысл несут значения.

| Состояние | `download_finished` | `download_present` | `cached` | `active` | `progress` | `eta` | `size` |
|---|---|---|---|---|---|---|---|
| `metaDL` | false | false | false | true | 0 | 8640000 | 0 |
| `checking` | false | false | false | true | 0 | 8640000 | **-1** |
| `stalledDL` | false | false | false | true | крошечное | 8640000 | реальный |
| `stalled (no seeds)` | false | false | false | true | 0 | 8640000 | реальный |
| `downloading` | false, потом **true** | false | false | true | доля | секунды | реальный |
| `processing` | **true** | **false** | false | true | 1 | секунды | реальный |
| `uploading (no peers)` | **true** | **false** | false | true | 1 | 2591994 | реальный |
| `uploading` | true | **true** | true | true | 1 | 0 | реальный |
| `cached` | true | true | true | false | 1 | 0 | реальный |

Имена полей. В плане все они были помечены как непроверенные.

| Что | Поле TorBox | Формат |
|---|---|---|
| progress | `progress` | **доля от единицы**, а не процент. `0.0793719` |
| seeders | `seeds` | целое число |
| leechers | `peers` | целое число |
| скорость загрузки | `download_speed` | байт в секунду |
| скорость отдачи | `upload_speed` | байт в секунду |
| eta | `eta` | секунды. `8640000` означает «неизвестно» |
| скачано байт | `total_downloaded` | целое число |
| здоровье роя | `availability` | float. Становится **-1** в `uploading (no peers)` |
| где данные | `download_path` | null, пока данные не появились |

`8640000` — это 100 дней. Так TorBox сообщает, что не знает значение. Это та же константа, которую прослойка zurg сейчас отдаёт Sonarr, когда ей нечего сообщить.

### Что делал каждый кейс {#what-each-case-did-2}

| Случай | Торрент | `checkcached` | Переходы с секундами от добавления | Вердикт |
|---|---|---|---|---|
| кэширован | Big Buck Bunny | true | `cached`@0.0 | готово за 0.83 s |
| кэширован | Sintel | true | `cached`@0.0 | готово за 0.94 s |
| кэширован | Ubuntu 26.04.1 | true | `cached`@0.0 | готово за 0.69 s |
| не кэширован | Debian 13.6.0 arm64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@7.3 `downloading`@24.1 и потом **gone**@48.6 | удалён другим zurg на 86.7% |
| не кэширован | Debian 13.2.0 amd64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@13.8 `downloading`@27.8 `processing`@69.4 `downloading`@72.7 `uploading (no peers)`@83.1 и потом **gone**@86.7 | удалён другим zurg |
| webseed | Prelinger home movie | false | `metaDL`@0.0 `checking`@23.3 и больше ничего не появилось | **обрезан на 911.3 s в `checking`**. TorBox не использовал webseed |
| без сидов | ubuntu-16.04.6-desktop-i386 | false | `metaDL`@0.0 `checking`@10.5 `downloading`@20.6 `processing`@184.4 и потом **gone**@200.4 | удалён другим zurg на `processing` |
| без сидов | ubuntu-24.04-beta-live-server-s390x | false | `metaDL`@0.0 `checking`@18.9 `stalled (no seeds)`@169.3 `downloading`@230.9 и потом **gone**@462.3 | удалён другим zurg на 91.9 процента |
| без метаданных | случайный 40-hex | false | `metaDL`@0.0 `checking`@10.2 и больше ничего не появилось | **обрезан на 910.3 s в `checking`** |

Отдельный прогон с опросом раз в 0.5 s по Debian 13.5.0 amd64 netinst
(`58846860f0a766f8a42b0bb214d8c713fdf1b167`) продержался достаточно долго, чтобы дойти до готово, и служит эталонной последовательностью.

| Секунды | Состояние | `download_finished` | `download_present` | `progress` |
|---|---|---|---|---|
| 0.0 | `stalledDL` | false | false | 0.000289735 |
| 16.3 | `downloading` | false | false | 0.0608651 |
| 54.8 | `processing` | **true** | **false** | 1 |
| 59.1 | `downloading` | **true** | **false** | 0.997972 |
| 64.4 | `uploading` | true | **true** | 1 |

754 MiB за 64.4 s.

Перечитайте последние три строки дважды. TorBox ставит `download_finished` в true, а `progress` в 1 примерно за десять секунд **до** того, как данные появляются на месте. Потом состояние возвращается к `downloading`, а progress показывает число меньше того, что только что было выдано. И `progress`, и `download_state` идут назад даже на здоровой загрузке.

---

## Таблица стадий {#the-stage-table}

Стадии, которые будет отдавать shim: `resolving-metadata` `queued` `downloading` `stalled-no-peers`
`finalizing` `done` `failed`, а пустая строка означает неизвестную стадию.

### Real-Debrid

| Исходный `status` | Стадия | Основание |
|---|---|---|
| `magnet_conversion` | `resolving-metadata` | **наблюдалось**. `bytes` 0, `files` пусто, а `filename` — буквально `"Magnet"` |
| `waiting_files_selection` | `queued` | **наблюдалось** с `--rd-select-detail`. Файлы уже перечислены. `links` пуст |
| `queued` | `queued` | **наблюдалось**. Реальный размер и реальное имя уже известны. Нет `seeders` и нет `speed` |
| `downloading` | `downloading` | **наблюдалось** |
| `downloading` с `seeders` 0 | `stalled-no-peers` | **наблюдалось**. 904 с с `progress` 0, `seeders` 0 и `speed` 0 за 92 опроса |
| `compressing` | `finalizing` | **выведено**. Не наблюдалось |
| `uploading` | `finalizing` | **наблюдалось**. Progress начинается с 0 заново, а `seeders` пропадает |
| `downloaded` | `done` | **наблюдалось** |
| `magnet_error` | `failed` | **наблюдалось** через 318 с в `magnet_conversion` |
| `error` `virus` `dead` | `failed` | **выведено**. Не наблюдалось |

### AllDebrid

| `statusCode` | Стадия | Основание |
|---|---|---|
| 0 `In queue` | `queued` | **наблюдалось**. Длится несколько секунд. `filename` может быть всё ещё `"noname"`, а `size` равен 0 |
| 1 `Downloading` при `size` 0 | `queued` | **наблюдалось**. Не `downloading` и не `stalled-no-peers`. AllDebrid принял задачу и ещё не начал её. Держалась 622 с и 580 с в двух запусках, которые потом завершились |
| 1 `Downloading` при реальном `size` | `downloading` | **наблюдалось** |
| 1 `Downloading` при `seeders` 0 и неизменном `downloaded` | `stalled-no-peers` | **не наблюдалось и не может быть надёжно выведено**. См. ниже |
| 2 `Compressing / Moving` | `finalizing` | **выведено**. Не наблюдалось |
| 3 `Uploading` | `finalizing` | **наблюдалось**. Прогресс здесь показывают `uploaded` и `uploadSpeed`, а `downloadSpeed` равен 0 |
| 4 `Ready` | `done` | **наблюдалось** |
| 5 и выше | `failed` | **выведено**. Не наблюдалось |

**У AllDebrid нет наблюдаемого признака зависания.** Задача, которую AllDebrid поставил в очередь, и задача, по которой AllDebrid не может продвинуться, выглядят одинаково в ответах по сети. В обоих случаях `statusCode` равен 1, `size` равен 0, а все счётчики на нуле.
Элемент Prelinger провёл в таком состоянии весь лимит в 907.8 с, а два других торрента провели в нём по десять минут каждый и потом завершились. Поэтому ничто в ответе AllDebrid не отличает одно от другого, и вердикт о зависании для AllDebrid может опираться только на таймер.

### TorBox

| Сырое `download_state` | Этап | Основание |
|---|---|---|
| `metaDL` | `resolving-metadata` | **наблюдалось**. `size` 0, а `name` совпадает с хешем |
| `checking` | `resolving-metadata` | **наблюдалось**. Пока это длится, `size` **-1**. Вот здесь TorBox ждёт торрент, а не проверяет хеш. В таблице zurg пока нет |
| `stalledDL` | `stalled-no-peers` | **наблюдалось**. В таблице zurg пока нет |
| `stalled (no seeds)` | `stalled-no-peers` | **наблюдалось**. Название преувеличивает. В двух захватах в этом состоянии `seeds` был 1 и 2. zurg пока сопоставляет его с `queued` |
| `downloading` | `downloading` | **наблюдалось** |
| `processing` | `finalizing` | **наблюдалось**. В таблице zurg пока нет |
| `uploading (no peers)` | `finalizing` | **наблюдалось**, когда `download_present` равен false |
| `uploading` | `done` | **наблюдалось**, когда `download_present` равен true |
| `cached` `completed` `seeding` | `done` | `cached` **наблюдалось**. Остальные два **выведены** |
| `expired` `reported missing` `failed` `error` `missingfiles` | `failed` | **выведено**. Ни одного не видели |

**Пара `download_finished` и `download_present` не заменяет строку состояния.** Оба
`processing`, `uploading (no peers)` и часть `downloading` имеют `download_finished: true` и
`download_present: false`. Это сочетание — обычная фаза finalizing, а не мёртвый торрент. См.
предупреждение ниже.

---

## Что не удалось измерить {#what-could-not-be-measured}

- **Случай без сидов удалось воспроизвести на одном кандидате из двух.** У обоих было ноль пиров по данным трекера.
  ubuntu-16.04.6-desktop-i386 всё равно скачался на всех трёх провайдерах, потому что DHT дал пиров, которых трекер не знал. ubuntu-24.04-beta-live-server-s390x завис на Real-Debrid на весь лимит, и это и есть наблюдение о зависании выше. Ноль в ответе трекера — слабый признак. Оставь в кейсе два кандидата. Real-Debrid в любом случае получил метаданные для обоих и правильно вернул `bytes` и `filename` уже в самом первом ответе `queued`.
- **Статус `compressing` у Real-Debrid не наблюдался ни разу.** Каждый завершённый запуск переходил из `downloading` сразу в `uploading`.
- **Код статуса 2 у AllDebrid не наблюдался ни разу.** Каждый замер шёл сразу с 1 на 3.
- **Ни один провайдер не был доведён до своих ошибок.** Статусы `error`, `virus` и `dead` у Real-Debrid, все коды AllDebrid выше 4 и все состояния сбоя у TorBox пока не проверены. Чтобы их получить, нужен контент, который заблокирован, заражён или просрочен, а не FOSS-образ ISO.
- **Торрент на TorBox редко удавалось довести до конца.** Четыре торрента кампании и один дополнительный удалил другой zurg на том же аккаунте прямо во время загрузки. См. опасность ниже. Только образ на 754 MiB успел закончиться до того, как этот процесс опросил состояние в следующий раз.

## Опасности, найденные по ходу {#hazards-found-on-the-way}

### Второй zurg на аккаунте TorBox удаляет здоровые загрузки {#a-second-zurg-on-the-torbox-account-deletes-healthy-downloads}

Запущен ещё один экземпляр zurg с тем же аккаунтом TorBox. Его конфиг выглядит так:

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

**Пять** тестовых торрентов удалились, хотя качались нормально. Это **наблюдается** с обеих сторон. Тестовый стенд увидел, как каждый торрент пропадает, а журнал другого экземпляра объясняет почему.

```
Aug 30 12:43:26 zurg-host zurg: INFO manager Deleting torrent 86695315 because it encountered an error status: error
Aug 30 12:43:27 zurg-host zurg: DEBUG torbox Deleted TorBox torrent id=86695315
Aug 30 12:44:56 zurg-host zurg: INFO manager Deleting torrent 86695708 because it encountered an error status: error
Aug 30 12:47:41 zurg-host zurg: INFO manager Deleting torrent 86697191 because it encountered an error status: error
```

Этими пятью были `86695315` `86695708` `86697191` `86702627` `86704212`. У всех была одна и та же причина. Ни один из них не был сломан.

Механизм — второе правило в `normalizeStatus` в `internal/torbox/types.go`.

```go
if w.DownloadFinished && !w.DownloadPresent {
    return "error"
}
```

Эта комбинация — обычная фаза финализации в TorBox. Захват с шагом 0.5 с даёт на это цифру. На образе 754 MiB окно от момента, когда `download_finished` стал true, до момента, когда `download_present` стал true, составило **9.6 секунды**. На образе 3.7 GiB — не меньше 17 с, и проверка попала внутрь этого окна. Другой экземпляр zurg опрашивает библиотеку примерно каждые 15 с. Выживет ли здоровая загрузка TorBox после собственного завершения, — это почти как подбросить монетку.

Из этого три следствия. Загрузка TorBox, которую пользователь видит завершённой в интерфейсе TorBox, может пропасть из его библиотеки zurg. `delete_error_torrents` описана как удаление торрентов, которые провайдер считает сломанными, а здесь она удаляет те, которые провайдер считает исправными. И любые измерения TorBox на этом аккаунте идут наперегонки с этой очисткой.

**Здесь не исправляем.** Фаза 0 — это измерения. Исправление относится к работе над этапами. Там `download_finished && !download_present` должно становиться `finalizing`, а не `failed`.

### Второй zurg на аккаунте AllDebrid обошёлся без последствий {#a-second-zurg-on-the-alldebrid-account-got-away-with-it}

Ключ AllDebrid, которым пользовался эта кампания, также загрузил другой экземпляр zurg, с теми же тремя настройками sweep, что и для TorBox.

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

Ни одна проба AllDebrid не была удалена. Причина в коде, а не в везении. `normalizeStatus` в `internal/alldebrid/types.go` относит к `error` только коды статуса 5 и выше и не содержит структурного правила вида `download_finished && !download_present`. Поэтому здоровая загрузка AllDebrid никогда не будет распознана как сломанная. Ошибка TorBox заключается в этом одном дополнительном правиле, а не в sweep вообще.

Real-Debrid стоит особняком. С тестовым аккаунтом не был загружен ни один другой zurg. Ничего его не сканировало, и ничто не мешало.

### TorBox отвечает HTTP 500 на удаление неизвестного id {#torbox-answers-a-delete-for-an-unknown-id-with-http-500}

```
POST /v1/api/torrents/controltorrent  {"torrent_id":86695315,"operation":"delete"}
-> HTTP 500 {"success":false,"error":"DATABASE_ERROR","detail":"There was an error processing your request. Please try again later."}
```

`GET /torrents/mylist?id=<gone>` отвечает так же. Поэтому торрент, которого больше нет, по коду статуса не отличить от сбоя TorBox. zurg сообщает об этом как `account temporarily unavailable`. В журнале другого экземпляра видно, что он каждые 15 с повторяет удаление уже удалённого id. Харнесс обходит это так: после неудачного удаления запрашивает `mylist` и считает пропавший торрент удалённым.

### Троттлинга Real-Debrid не обнаружено {#real-debrid-throttling-did-not-appear}

Девять добавлений с интервалом 20 с не дали ни одного 451 и ни одного 429 за всю кампанию. Это совпадает с заметкой в корневом `CLAUDE.md`: 6 добавлений с интервалом 10 с дали 0/6, а те же 6 с интервалом 20 с дали 6/6. Минимум в 20 с действительно работает и не является суеверием.

## Повторный запуск кампании {#re-running-the-campaign}

```bash
export RD_TOKEN=…   # a Real-Debrid test account
export AD_KEY=…     # AllDebrid test
export TB_KEY=…     # TorBox

# 1. check the catalog still resolves and the swarms are still what the tables claim
./scripts/torrent_lifecycle_probe.py --inspect-torrents

# 2. non-destructive. Confirms the cached/uncached split before anything is added
./scripts/torrent_lifecycle_probe.py --cache-probe

# 3. record what each account holds now, so step 6 has something to compare against
./scripts/torrent_lifecycle_probe.py --list

# 4. the campaign. One process per provider, each with its own output directory
for p in rd ad tb; do
  LIFECYCLE_OUTDIR=~/lifecycle/$p ./scripts/torrent_lifecycle_probe.py \
    --provider $p --case all --cap-mins 15 > ~/lifecycle/$p.out 2>&1 &
done

# 5. the two follow-ups the campaign cannot do
./scripts/torrent_lifecycle_probe.py --provider rd --case cached --rd-select-detail
./scripts/torrent_lifecycle_probe.py --provider tb --case adhoc --fast-poll 0.5 --fast-window 480 \
  --extra-hash 58846860f0a766f8a42b0bb214d8c713fdf1b167:debian-netinst

# 6. verify nothing was left behind
./scripts/torrent_lifecycle_probe.py --cleanup-only
./scripts/torrent_lifecycle_probe.py --list
```

Запускайте его с машины с residential-выходом. AllDebrid отвечает `NO_SERVER` на IP-адреса датацентров.

Шаг 6 не является необязательным, а шаг 3 нужен для того, чтобы он имел смысл. После кампании 2026-08-30 ни один из 34 instance id, которые захватил harness, не остался ни на одном из трёх аккаунтов. Не осталось и ни одного из девяти probe-хешей.

Прежде чем трогать TorBox, проверьте, не запущен ли с этим же аккаунтом какой-либо другой zurg. Прочитайте его настройки sweep и ожидайте sweep, описанный выше.

```bash
grep -E "delete_error_torrents|stalled_download_mins|enable_repair" config.yml
```

Никогда не меняйте его. Probe, который исчезает в процессе работы, — это данные.
