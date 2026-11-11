# Контракт API SABnzbd, который используют Sonarr и Radarr (develop) {#sabnzbd-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Источник истины: файлы, загруженные с `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...` на **2026-08-22**. Каждый номер строки ниже взят из этих файлов.

Этот документ хранит объяснение того, почему `internal/sabnzbd` отвечает именно так, как отвечает. Ничего в этом пакете не меняй без абзаца ниже, который объясняет, что клиент делает с полем. Неверный тег структуры не вызывает ошибку: клиент просто читает ноль. А неверное значение enum бросает исключение внутри его десериализатора и роняет весь опрос. Как подключить Sonarr или Radarr к zurg, см. [sabnzbd.md](../guides/sonarr-radarr.md).

Если в разделе не сказано иное, **SAB-файлы двух репозиториев побайтово идентичны**, за исключением UTF-8 BOM и переименования `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie`, а номера строк совпадают один в один. Поэтому каждая ссылка `Sabnzbd*` относится к обоим репозиториям на одной и той же строке. Пути `src/NzbDrone.Core/Download/Clients/Sabnzbd/...` одинаковы в обоих. Проверенные различия записаны в §6.

Ничего здесь не является домыслом о самом SAB: каждое утверждение описывает поведение *клиента*. Там, где я указываю семантику Newtonsoft.Json или среды выполнения .NET (а не код Sonarr), я говорю об этом явно.

## 0. Правила уровня транспорта (их нужно знать в первую очередь) {#0-transport-level-rules-these-bite-first}

### 0.1 Формат URL {#01-url-shape}

`SabnzbdProxy.BuildRequest` (`SabnzbdProxy.cs:162-185`):

```csharp
private HttpRequestBuilder BuildRequest(string mode, SabnzbdSettings settings)
{
    var baseUrl = GetBaseUrl(settings, "api");                      // :164
    var requestBuilder = new HttpRequestBuilder(baseUrl)
        .Accept(HttpAccept.Json)                                    // :167  -> Accept: application/json
        .AddQueryParam("mode", mode);                               // :168
    requestBuilder.LogResponseContent = true;                       // :170
    if (settings.ApiKey.IsNotNullOrWhiteSpace())
        requestBuilder.AddSuffixQueryParam("apikey", settings.ApiKey);        // :174
    else
    {
        requestBuilder.AddSuffixQueryParam("ma_username", settings.Username); // :178
        requestBuilder.AddSuffixQueryParam("ma_password", settings.Password); // :179
    }
    requestBuilder.AddSuffixQueryParam("output", "json");           // :182
    return requestBuilder;
}
```

- Базовый URL: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-66`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; если в `UrlBase` нет ведущего `/`, он добавляется.
  Конечная точка — это тот же адрес + `/api` (`SabnzbdProxy.cs:38-44`).
- Суффиксные параметры всегда идут в конце, так что **`apikey` (или `ma_username`+`ma_password`) и `output=json`
  — это последние query-параметры** (`HttpRequestBuilder.cs:82` — `QueryParams.Concat(SuffixQueryParams)`).
- `Accept: application/json` в каждом запросе. `output=json` тоже в каждом запросе. Нигде нет пути с `output=xml`.
- API-ключ и имя пользователя с паролем **взаимно исключают друг друга**: если указан API-ключ, `ma_username`/`ma_password` не отправляются.

### 0.2 Всегда отвечает HTTP 200 — даже при ошибках {#02-always-answer-http-200--even-for-errors}

`HttpClient.Execute` выбрасывает исключение при любом статусе >= 400 (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`;
`HttpResponse.cs:54` — `HasHttpError => (int)StatusCode >= 400`; 429 превращается в `TooManyRequestsException`).
`SabnzbdProxy.ProcessRequest` (`SabnzbdProxy.cs:199-215`) преобразует это в
`DownloadClientException("Unable to connect to SABnzbd, {0}")`.

Сообщение `HttpException` выглядит так: `"HTTP request failed: [401:Unauthorized] [GET] at [url]"`
(`src/NzbDrone.Common/Http/HttpException.cs:18`). **Тела ответа в сообщении нет.** Поэтому 401 с
`{"error":"API Key Incorrect"}` не распознаётся в `TestAuthentication`
(`Sabnzbd.cs:424,429` сравнивают `ex.Message`), и тест подключения вместо этого показывает общее "Test was aborted due to an error". **Эмулируйте SAB: HTTP 200 + `{"status": false, "error": "..."}`.**

(Предыдущий перевод был отклонён: фрагменты кода не совпадают. Сохраните структуру точно.)

### 0.3 Настройки десериализатора (определяют все вопросы о именах полей и типах) {#03-deserializer-settings-drives-every-field-name-and-type-question}

Весь трафик SAB проходит через `NzbDrone.Common.Serializer.Json`
(`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`) — это **Newtonsoft**, а не System.Text.Json:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Что из этого следует (это семантика Newtonsoft, а не код Sonarr):

| Настройка | Что это значит для эмулятора |
|---|---|
| `CamelCasePropertyNamesContractResolver` | C#-свойство `Storage` связывается с `storage`, `PP` с `pp`, `Misc` с `misc`. Newtonsoft также делает сопоставление свойств без учёта регистра, так что настоящие ключи SAB в snake_case/нижнем регистре связываются в любом случае. |
| `StringEnumConverter` (глобальный) | Применяется к `SabnzbdDownloadStatus`, у которого **нет** конвертера на уровне свойства. Неизвестные имена enum вызывают `JsonSerializationException`. Целые числа тоже принимаются (`AllowIntegerValues` по умолчанию true). |
| `NullValueHandling.Ignore` | Работает и на **чтении**: JSON `null` оставляет член C# со значением из конструктора. Так что `"categories": null` сохраняет пустой список из конструктора, а `"misc": null` оставляет `Misc` равным null (значения по умолчанию в конструкторе нет) → NRE, см. §3.4. |
| `MissingMemberHandling` (по умолчанию `Ignore`) | Лишние поля в вашем payload безвредны. Отправляйте полное настоящее тело SAB. |
| `Culture` (по умолчанию `InvariantCulture`) | Числовые строки вроде `"1024.00"` должны использовать `.` как разделитель дробной части и не содержать разделителей тысяч. |

`Json.Deserialize<T>` пробрасывает дальше только `JsonReaderException`, но с более понятным сообщением (`Json.cs:39-50`);
`Json.TryDeserialize<T>` глотает **только** `JsonReaderException` и `JsonSerializationException`
(`Json.cs:99-117`). Всё остальное (например, `ArgumentException` из конвертера timeleft или NRE из конвертера priority) выходит наружу.

## 1. Каждый режим, каждый параметр, каждое используемое поле {#1-every-mode-every-parameter-every-field-consumed}

### 1.1 `mode=version` — `SabnzbdProxy.GetVersion` (`SabnzbdProxy.cs:85-95`)

Запрос: `GET /api?mode=version&apikey=KEY&output=json`

Модель ответа `SabnzbdVersionResponse` (`Responses/SabnzbdVersionResponse.cs:5`):

| JSON-ключ | Тип C# | Примечания |
|---|---|---|
| `version` | `string` | Единственное поле, которое читается. |

Читается через `Json.TryDeserialize`; если разбор не удался, `Version == null` (`SabnzbdProxy.cs:89-92`).

Разбор (`Sabnzbd.cs:334-366`), регулярка в `Sabnzbd.cs:38`:

```csharp
// patch can be a number (releases) or 'x' (git)
private static readonly Regex VersionRegex = new Regex(@"(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+|x)", RegexOptions.Compiled);
```

- Без привязки к началу и концу строки, поэтому `4.5.0RC1` и `2.0.0beta1` тоже разбираются (фикстура `SabnzbdFixture.cs:523,553`).
- `patch` может быть просто `x` (сборки из git), тогда он заменяется на `0` (`Sabnzbd.cs:351`).
- Версия из **двух компонентов** (`"4.5"`) не подходит → `null` → ошибка валидации.
- Строка `"develop"` (без учёта регистра) обрабатывается отдельно и становится `3.0.0` (`Sabnzbd.cs:355-362`), при этом выдаётся *предупреждение*, а не ошибка (`Sabnzbd.cs:380-387`).

Версия запрашивается повторно (второй запрос `mode=version`) через `HasVersion` в `Sabnzbd.cs:294-332` — она **не кэшируется**.

### 1.2 `mode=get_config` — `SabnzbdProxy.GetConfig` (`SabnzbdProxy.cs:97-104`)

Запрос: `GET /api?mode=get_config&apikey=KEY&output=json`

Используется `Json.Deserialize` (**не** Try): если тело некорректное, из `GetConfig` выбрасывается исключение.
Верхний уровень должен быть `{"config": {...}}` (`Responses/SabnzbdConfigResponse.cs:5`). Поля см. в §3.

### 1.3 `mode=fullstatus` — `SabnzbdProxy.GetFullStatus` (`SabnzbdProxy.cs:106-114`)

Запрос: `GET /api?mode=fullstatus&skip_dashboard=1&apikey=KEY&output=json`

Верхний уровень: `{"status": {...}}` (`Responses/SabnzbdFullStatusResponse.cs:5`). Читается только одно поле:

| Ключ JSON | C# | Источник |
|---|---|---|
| `completedir` | `string CompleteDir` | `SabnzbdFullStatus.cs:9-10` — обратите внимание: **`completedir`, без подчёркивания** |

Этот эндпоинт вызывается **только** тогда, когда `config.misc.complete_dir` **не** является абсолютным путём **и** версия SAB >= 2.0 (`Sabnzbd.cs:220-226`). Если `complete_dir` абсолютный, до этого эндпоинта дело не доходит, но реализовать его всё равно нужно.

Особенность, которую стоит знать: поскольку реальное тело ответа имеет вид `{"status": {...}}`, а `SabnzbdJsonError.Status` — это `string`, `TryDeserialize<SabnzbdJsonError>` в `CheckForError` падает с `JsonSerializationException` и переходит в ветку для обычного текста, которая задаёт `Status = "true"` (`SabnzbdProxy.cs:224-240`). Это безвредно, но из-за этого fullstatus никогда не сможет сообщить об ошибке через JSON-путь.

### 1.4 `mode=queue` (чтение) — `SabnzbdProxy.GetQueue` (`SabnzbdProxy.cs:116-130`) {#14-modequeue-read--sabnzbdproxygetqueue-sabnzbdproxycs116-130}

**Запрос:** `GET /api?mode=queue&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- `category` добавляется **только если** настроенная категория не пустая (`SabnzbdProxy.cs:122-125`).
- Вызывающие методы:
  - `Sabnzbd.GetQueue()` использует `start=0, limit=0` (`Sabnzbd.cs:57`). SAB воспринимает `limit=0` как «все».
  - `Sabnzbd.GetCategories()` использует `start=0, limit=1` на пути для версий до 2.0 (`Sabnzbd.cs:229`).
  - `Sabnzbd.RemoveItem()` вызывает этот запрос ещё раз, чтобы понять, очередь это или история (`Sabnzbd.cs:199`).
- Разбор ответа: `Json.Deserialize<SabnzbdQueue>(JObject.Parse(response).SelectToken("queue").ToString())` (`SabnzbdProxy.cs:129`). **Если верхнего ключа `queue` нет, будет NRE.**

`SabnzbdQueue` (`SabnzbdQueue.cs`):

| Ключ JSON | C# | Тип | Для чего используется |
|---|---|---|---|
| `my_home` | `DefaultRootFolder` | `string` | Только в SAB < 2.0, чтобы разрешить относительный `complete_dir` (`Sabnzbd.cs:230`). Комментарий в `SabnzbdQueue.cs:8`: "Removed in Sabnzbd 2.0.0, see mode=fullstatus instead." |
| `paused` | `Paused` | `bool` | Глобальная пауза. Учитывается вместе с приоритетом слота (`Sabnzbd.cs:78`). |
| `slots` | `Items` | `List<SabnzbdQueueItem>` | |

`SabnzbdQueueItem` (`SabnzbdQueueItem.cs`):

| Ключ JSON | Член C# | Тип C# | Реальный тип JSON в SAB | Примечания |
|---|---|---|---|---|
| `status` | `Status` | `SabnzbdDownloadStatus` | string | Глобальный `StringEnumConverter`. Неизвестное значение ⇒ `JsonSerializationException` ⇒ весь `GetQueue` падает с ошибкой. |
| `index` | `Index` | `int` | number | Читается, но нигде не используется. |
| `timeleft` | `Timeleft` | `TimeSpan` через `SabnzbdQueueTimeConverter` | string | См. §1.4.1. |
| `mb` | `Size` | `decimal` | **string** (`"1024.00"`) | **Мегабайты.** `TotalSize = (long)(Size * 1024 * 1024)` (`Sabnzbd.cs:72`). |
| `mbleft` | `Sizeleft` | `decimal` | **string** | **Мегабайты.** `RemainingSize = (long)(Sizeleft * 1024 * 1024)` (`Sabnzbd.cs:73`). |
| `filename` | `Title` | `string` | string | Становится `DownloadClientItem.Title` (`Sabnzbd.cs:71`). |
| `priority` | `Priority` | `SabnzbdPriority` через `SabnzbdPriorityTypeConverter` | string (`"Normal"`) | См. §2. |
| `cat` | `Category` | `string` | string | **`cat` в очереди, `category` в истории.** |
| `mbleft`/`percentage` | `Percentage` | `int` | **string** (`"50"`) | Читается, но нигде не используется. |
| `nzo_id` | `Id` | `string` | string | ID загрузки, по которому Sonarr/Radarr находят всё остальное. |

#### 1.4.1 Формат `timeleft` — `SabnzbdQueueTimeConverter` (`JsonConverters/SabnzbdQueueTimeConverter.cs:15-28`) {#141-timeleft-format--sabnzbdqueuetimeconverter-jsonconverterssabnzbdqueuetimeconvertercs15-28}

```csharp
var split = reader.Value.ToString().Split(':').Select(int.Parse).ToArray();
switch (split.Length)
{
    case 4: return new TimeSpan((split[0] * 24) + split[1], split[2], split[3]);   // d:h:m:s
    case 3: return new TimeSpan(split[0], split[1], split[2]);                     // h:m:s
    default: throw new ArgumentException("Expected either 0:0:0:0 or 0:0:0 format, but received: " + reader.Value);
}
```

- **Ровно 3 или 4 целых числа, разделённых двоеточием.** `"0:08:32"`, `"40:12:14"`, `"1:16:12:14"` подходят (фикстура `SabnzbdQueueTimeConverterFixture.cs:14-20`); `"1"`, `"0:1"`, `"0:0:0:0:1"` выбрасывают исключение (`:28-35`). Ведущие нули допустимы (`int.Parse`).
- Выброшенное `ArgumentException` **не** перехватывается ни `Json.TryDeserialize`, ни `Json.Deserialize`.
- **Пустая строка** `""` разбивается на `[""]`, и `int.Parse` выбрасывает `FormatException`. Никогда не передавайте `""`.
- Если `timeleft` не указан вовсе, всё в порядке: конвертер не вызывается, а `Timeleft` остаётся `TimeSpan.Zero`.

### 1.5 `mode=queue&name=delete` — `SabnzbdProxy.RemoveFromQueue` (`SabnzbdProxy.cs:64-72`)

```
GET /api?mode=queue&name=delete&del_files={0|1}&value={nzo_id}&apikey=KEY&output=json
```

`del_files = deleteData ? 1 : 0` (`SabnzbdProxy.cs:68`). **В пути очереди нет параметра `archive`.**
Тело ответа проходит только через `CheckForError`; ничего не десериализуется.

### 1.6 `mode=history` (чтение) — `SabnzbdProxy.GetHistory` (`SabnzbdProxy.cs:132-146`) {#16-modehistory-read--sabnzbdproxygethistory-sabnzbdproxycs132-146}

Запрос: `GET /api?mode=history&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- Вызывающий код: `Sabnzbd.GetHistory()` с `start=0, limit=_configService.DownloadClientHistoryLimit`
  (`Sabnzbd.cs:110`). По умолчанию **60** в обоих репозиториях
  (Sonarr `src/NzbDrone.Core/Configuration/ConfigService.cs:184`, Radarr `:236`).
- Извлечение: `SelectToken("history")` (`SabnzbdProxy.cs:145`). Верхний уровень должен быть `{"history": {...}}`.

`SabnzbdHistory` (`SabnzbdHistory.cs`): `paused` (`bool`, не используется), `slots` → `Items`.

`SabnzbdHistoryItem` (`SabnzbdHistoryItem.cs`):

| Ключ JSON | Член C# | Тип C# | Примечания |
|---|---|---|---|
| `fail_message` | `FailMessage` | `string` | Становится `DownloadClientItem.Message` (`Sabnzbd.cs:132`) и задаёт особый случай Warning (§1.6.1). |
| `bytes` | `Size` | `long` | **БАЙТЫ, а не МБ**. `TotalSize = sabHistoryItem.Size` передаётся как есть (`Sabnzbd.cs:128`). Это самое большое отличие от `mode=queue`. |
| `category` | `Category` | `string` | Обратите внимание: `category`, тогда как очередь использует `cat`. |
| `nzb_name` | `NzbName` | `string` | Читается, но нигде не используется. |
| `download_time` | `DownloadTime` | `int` (секунды) | Читается, но нигде не используется. |
| `storage` | `Storage` | `string` | Путь к выходной папке. См. §1.6.2. Именно этот путь потом удаляется через `rm -rf`. |
| `status` | `Status` | `SabnzbdDownloadStatus` | Глобальный `StringEnumConverter`. |
| `nzo_id` | `Id` | `string` | |
| `name` | `Title` | `string` | |

**Ни один член модели SAB не имеет типа `DateTime`, поэтому формат даты ничем не ограничен.**
`completed` / `last_history_update` (unix epoch в настоящем SAB) никогда не читаются. Единственные значения времени, которые действительно важны, это `timeleft` (§1.4.1) и `download_time` (нечитаемое целое число секунд).

#### 1.6.1 Статус из истории → `DownloadItemStatus` (`Sabnzbd.cs:116-158`) {#161-history-status--downloaditemstatus-sabnzbdcs116-158}

```
Deleted                                   -> skipped entirely (Sabnzbd.cs:116-119)
Failed  + fail_message == "Unpacking failed, write error or disk is full?"
        (InvariantCultureIgnoreCase)      -> DownloadItemStatus.Warning     (:140-144)
Failed  (any other message)               -> DownloadItemStatus.Failed      (:147)
Completed                                 -> DownloadItemStatus.Completed   (:152)
anything else (Verifying/Moving/...)      -> DownloadItemStatus.Downloading (:157)
```

Каждый элемент истории получает `RemainingSize = 0`, `RemainingTime = TimeSpan.Zero`, `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:129-135`).

Сам `DownloadItemStatus` (`src/NzbDrone.Core/Download/DownloadItemStatus.cs:3-11`): `Queued=0, Paused=1, Downloading=2, Completed=3, Failed=4, Warning=5`.

#### 1.6.2 `storage` → `OutputPath` (`Sabnzbd.cs:160-176`)

```csharp
var outputPath = _remotePathMappingService.RemapRemoteToLocal(Settings.Host, new OsPath(sabHistoryItem.Storage));

if (!outputPath.IsEmpty)
{
    historyItem.OutputPath = outputPath;

    var parent = outputPath.Directory;
    while (!parent.IsEmpty)
    {
        if (parent.FileName == sabHistoryItem.Title)
        {
            historyItem.OutputPath = parent;
        }

        parent = parent.Directory;
    }
}
```

Цикл идёт **до самого корня** и оставляет *самого верхнего* предка, у которого последний сегмент совпадает с `name`. Зачем это нужно: если `storage` указывает на файл внутри папки задачи, цикл поднимается до папки задачи (фикстура `SabnzbdFixture.cs:376-391`). Если `storage` уже является папкой задачи, подходящего предка нет, и `OutputPath == storage`. Это как раз то, что нужно.

**Рекомендация для эмулятора: укажите в `storage` сам путь к папке задачи.**

Пустой `storage` ⇒ `OutputPath` остаётся пустым ⇒ `CompletedDownloadService.ValidatePath` выдаёт предупреждение "Download doesn't contain intermediate path, Skipping." (Sonarr `CompletedDownloadService.cs:299-303`).

### 1.7 `mode=history&name=delete` — `SabnzbdProxy.RemoveFromHistory` (`SabnzbdProxy.cs:74-83`)

```
GET /api?mode=history&name=delete&del_files={0|1}&value={nzo_id}&archive={0|1}&apikey=KEY&output=json
```

```csharp
request.AddQueryParam("del_files", deleteData ? 1 : 0);          // :78
request.AddQueryParam("value", id);                              // :79
request.AddQueryParam("archive", deletePermanently ? 0 : 1);     // :80   <-- inverted
```

и вызывающий код (`Sabnzbd.cs:208`):

```csharp
_proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
```

Итак, `deletePermanently == (status is Failed)`, и поэтому:

| Статус элемента | `del_files` | `archive` |
|---|---|---|
| Completed | 1 | **1** (архивировать) |
| Failed | 1 | **0** (безвозвратное удаление) |

На первый взгляд это читается наоборот, но именно так код и работает.

### 1.8 `mode=addfile` — `SabnzbdProxy.DownloadNzb` (`SabnzbdProxy.cs:46-62`)

```
POST /api?mode=addfile&cat={category}&priority={int}&apikey=KEY&output=json
Content-Type: multipart/form-data; boundary=...
  part: Content-Disposition: form-data; name="name"; filename="<CleanFileName(Release.Title)>.nzb"
        Content-Type: application/x-nzb
```

- Поле multipart называется буквально `name`, а у части есть `filename` (`SabnzbdProxy.cs:53`, `HttpRequestBuilder.cs:379-395`, формируется в `:180-195`).
- Имя файла берётся из `FileNameBuilder.CleanFileName(release.Title) + ".nzb"` (Sonarr `src/NzbDrone.Core/Download/UsenetClientBase.cs:43`, Radarr `:43`).
- **`cat` игнорирует аргумент `category` метода** и читает настройки напрямую (`SabnzbdProxy.cs:50`: `request.AddQueryParam("cat", settings.TvCategory);` — Radarr: `settings.MovieCategory`). Безвредно, потому что вызывающий код передаёт то же значение.
- `priority` — это сырой `int` из `SabnzbdPriority` (см. §2), выбирается по свежести релиза:
  Sonarr `Sabnzbd.cs:43` `remoteEpisode.IsRecentEpisode() ? Settings.RecentTvPriority : Settings.OlderTvPriority`;
  Radarr `Sabnzbd.cs:43` `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie ? RecentMoviePriority : OlderMoviePriority`.
- Ответ `SabnzbdAddResponse` (`Responses/SabnzbdAddResponse.cs`):

| Ключ JSON | C# | Тип |
|---|---|---|
| `status` | `Status` | `bool` — парсится, но потом **никогда не читается** |
| `nzo_ids` | `Ids` | `List<string>`, в конструкторе инициализируется пустым списком |

  Читается через `TryDeserialize`; если не получилось, используется синтетический `{Status=true, Ids=[]}` (`SabnzbdProxy.cs:55-59`).
  Затем `Sabnzbd.cs:47-52`:

```csharp
if (response == null || response.Ids.Empty())
{
    throw new DownloadClientRejectedReleaseException(remoteEpisode.Release, "SABnzbd rejected the NZB for an unknown reason");
}

return response.Ids.First();
```

  **`nzo_ids` должен быть непустым массивом строк.** `"nzo_ids": null` равнозначен отсутствию поля (`NullValueHandling.Ignore` оставляет пустой список из конструктора) и падает точно так же.

### 1.9 Статус очереди → `DownloadItemStatus` (`Sabnzbd.cs:60-103`) {#19-queue-status--downloaditemstatus-sabnzbdcs60-103}

```
Deleted                                       -> skipped (Sabnzbd.cs:62-65)
(queue.paused && slot.priority != Force) || slot.status == Paused
                                              -> Paused, and RemainingTime forced to null (:78-84)
Queued | Grabbing | Propagating               -> Queued        (:85-90)
everything else                               -> Downloading   (:93)
```

Также `Sabnzbd.cs:96-100`: название, которое начинается с буквального `"ENCRYPTED /"`, очищается от этих
11 символов, а элемент помечается `IsEncrypted = true`.

Каждому элементу очереди присваивается `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:75-76`).

### 1.10 Фильтр категорий на стороне клиента (`Sabnzbd.cs:186-195`) {#110-client-side-category-filter-sabnzbdcs186-195}

```csharp
foreach (var downloadClientItem in GetQueue().Concat(GetHistory()))
{
    if (downloadClientItem.Category == Settings.TvCategory ||
        (downloadClientItem.Category == "*" && Settings.TvCategory.IsNullOrWhiteSpace()))
    {
        yield return downloadClientItem;
    }
}
```

Строгое сравнение строк. Элемент с категорией `*` принимается только тогда, когда настроенная категория пустая.

### 1.11 Режимы, которые есть в прокси, но никогда не вызываются {#111-modes-that-exist-in-the-proxy-but-are-never-called}

- `mode=retry&value={id}` (`SabnzbdProxy.cs:148-160`, ответ `{status, nzo_id}` →
  `Responses/SabnzbdRetryResponse.cs`). У `ISabnzbdProxy.RetryDownload` **нет вызывающего кода** ни в одном из репозиториев.
- `Responses/SabnzbdCategoryResponse.cs` (`{"categories": [...]}`, то есть `mode=get_cats`) **полностью не используется** ни в одном из репозиториев.
- `Sabnzbd.ValidatePath` (`Sabnzbd.cs:576-592`) приватный и никогда не вызывается (мёртвый код).

## 2. `SabnzbdDownloadStatus` и `SabnzbdPriority` — точный состав членов, обработка unknown/null {#2-sabnzbddownloadstatus-and-sabnzbdpriority--exact-members-unknownnull-handling}

### 2.1 `SabnzbdPriority.cs` (полный файл) {#21-sabnzbdprioritycs-complete-file}

```csharp
namespace NzbDrone.Core.Download.Clients.Sabnzbd
{
    public enum SabnzbdPriority
    {
        Default = -100,
        Paused  = -2,
        Low     = -1,
        Normal  = 0,
        High    = 1,
        Force   = 2
    }
}
```

`JsonConverters/SabnzbdPriorityTypeConverter.cs:14-21`:

```csharp
public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
{
    var queuePriority = reader.Value.ToString();

    Enum.TryParse(queuePriority, out SabnzbdPriority output);

    return output;
}
```

- `Enum.TryParse<T>(string, out T)` — это перегрузка, **чувствительная к регистру** (семантика .NET).
  `"Normal"` распарсится, а `"normal"` — **нет**. И при ошибке `output` становится
  `default(SabnzbdPriority) == 0 == Normal`, так что неправильный регистр тихо превращается в Normal.
  `"Force"` важен (см. §1.9), а `"force"` не работает.
- Числовые строки тоже парсятся: `"2"` → `Force`, `"-100"` → `Default`. И JSON-число `2` работает
  (`reader.Value.ToString()` == `"2"`).
- **`"priority": null` выбрасывает `NullReferenceException`** (`reader.Value.ToString()` на null).
  Это *не* ловит `Json.TryDeserialize`. Уберите ключ или передайте нормальное значение.
- Если не указывать `priority`, всё в порядке: конвертер не вызывается, поле остаётся `Normal` (0).
- Конвертер зарегистрирован только для `SabnzbdQueueItem.Priority` (`SabnzbdQueueItem.cs:21`);
  у элементов истории приоритета нет.
- Эти же целые числа Sonarr/Radarr отправляют обратно в `&priority=` при `mode=addfile`
  (в `SabnzbdSettings.cs` и `Recent*Priority`, и `Older*Priority` по умолчанию равны
  `(int)SabnzbdPriority.Default` = `-100`).

### 2.2 `SabnzbdDownloadStatus.cs` (полный файл), порядок объявления = неявные значения 0..15 {#22-sabnzbddownloadstatuscs-complete-file-declaration-order--implicit-values-015}

```csharp
namespace NzbDrone.Core.Download.Clients.Sabnzbd
{
    public enum SabnzbdDownloadStatus
    {
        Grabbing,       // 0
        Queued,         // 1
        Paused,         // 2
        Checking,       // 3
        Downloading,    // 4
        QuickCheck,     // 5
        Verifying,      // 6
        Repairing,      // 7
        Fetching,       // 8  -- comment in file: "Fetching additional blocks"
        Extracting,     // 9
        Moving,         // 10
        Running,        // 11 -- comment in file: "Running PP Script"
        Completed,      // 12
        Failed,         // 13
        Deleted,        // 14
        Propagating     // 15
    }
}
```

- **Отдельного конвертера для свойства нет.** Глобально зарегистрированный `StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }` (`Json.cs:32`) обрабатывает его.
- **Неизвестное имя вызывает исключение** (Newtonsoft `EnumUtils.ParseEnum` → `JsonSerializationException`). Так как `GetQueue`/`GetHistory` используют `Json.Deserialize` (а не Try), падает весь вызов очереди или истории. **Никогда не отправляй статус, которого нет в этом списке.**
- Отправляй канонические написания SAB точно как выше (`"Downloading"`, `"QuickCheck"`, `"Completed"`, `"Failed"`, `"Propagating"`, ...). Сопоставление enum в Newtonsoft откатывается к регистронезависимому, но полагаться стоит только на точный регистр.
- Целые числа тоже принимаются (`AllowIntegerValues` по умолчанию true), но лучше их не использовать.
- JSON `null` для `status` игнорируется из-за `NullValueHandling.Ignore`, и поле остаётся `Grabbing` (0): слот очереди молча становится `Queued`, а слот истории молча становится `Downloading`. Всегда отправляй явный статус.

---

## 3. `get_config`: что именно читается и правила валидации {#3-get_config-exactly-what-is-read-and-the-validation-rules}

### 3.1 Модель — `SabnzbdCategory.cs` {#31-the-model--sabnzbdcategorycs}

В этом одном файле лежат `SabnzbdConfig`, `SabnzbdConfigMisc`, `SabnzbdCategory` **и** `SabnzbdSorter`.
В **обоих репозиториях** нет файла **`SabnzbdConfig.cs`** (проверено через список GitHub contents API для `src/NzbDrone.Core/Download/Clients/Sabnzbd`).

```csharp
public class SabnzbdConfig                                   // SabnzbdCategory.cs:8
{
    public SabnzbdConfig()                                   // :10-15
    {
        Categories = new List<SabnzbdCategory>();
        Servers    = new List<object>();
        Sorters    = new List<SabnzbdSorter>();
    }

    public SabnzbdConfigMisc      Misc       { get; set; }   // :17   <-- NOT initialised
    public List<SabnzbdCategory>  Categories { get; set; }   // :18
    public List<object>           Servers    { get; set; }   // :19
    public List<SabnzbdSorter>    Sorters    { get; set; }   // :20
}
```

### 3.2 `config.misc.*` — полный набор читаемых ключей (`SabnzbdCategory.cs:23-37`) {#32-configmisc--the-complete-set-of-keys-read-sabnzbdcategorycs23-37}

| Ключ JSON | Тип C# | Читается в | Назначение |
|---|---|---|---|
| `complete_dir` | `string` | `Sabnzbd.cs:218` | Основа для пути каждой категории. |
| `tv_categories` | `string[]` | `Sabnzbd.cs:265, 493` | |
| `enable_tv_sorting` | `bool` | `Sabnzbd.cs:265, 493` | |
| `movie_categories` | `string[]` | `Sabnzbd.cs:269, 502` | |
| `enable_movie_sorting` | `bool` | `Sabnzbd.cs:269, 502` | |
| `date_categories` | `string[]` **через `SabnzbdStringArrayConverter`** | `Sabnzbd.cs:273, 511` | |
| `enable_date_sorting` | `bool` | `Sabnzbd.cs:273, 511` | |
| `pre_check` | `bool` | `Sabnzbd.cs:443` | |
| `history_retention` | `string` | `Sabnzbd.cs:540, 561-573` | Устаревший, SAB < 4.3. |
| `history_retention_option` | `string` | `Sabnzbd.cs:541, 544` | SAB >= 4.3. |
| `history_retention_number` | `int` | `Sabnzbd.cs:542, 553` | SAB >= 4.3. |

`SabnzbdStringArrayConverter` (`JsonConverters/SabnzbdStringArrayConverter.cs:25-39`) — применяется только
к `date_categories` (`SabnzbdCategory.cs:30`):

```csharp
if (reader.TokenType == JsonToken.String || reader.TokenType == JsonToken.Null)
{
    return new string[] { JValue.Load(reader).ToObject<string>() };
}
else if (reader.TokenType == JsonToken.StartArray)
{
    return JArray.Load(reader).ToObject<string[]>();
}
else
{
    throw new JsonReaderException("Expected array");
}
```

JSON **строка** превращается в массив из одного элемента; **null** превращается в `[null]` (массив из одного элемента, содержащий
null); **массив** десериализуется обычным образом; всё остальное (число, объект) выбрасывает исключение. Комментарий в документации на `:7-9`: "On some properties sab serializes array of single item as plain string."

### 3.3 `config.categories[]` — `SabnzbdCategory` (`SabnzbdCategory.cs:39-48`)

| Ключ JSON | C# | Читается в |
|---|---|---|
| `priority` | `int Priority` | не читается |
| `pp` | `string PP` | не читается (camelCase от `PP` это `pp`) |
| `name` | `string Name` | `Sabnzbd.cs:251, 255, 458` |
| `script` | `string Script` | не читается |
| `dir` | `string Dir` | `Sabnzbd.cs:238` (`Dir.TrimEnd('*')`), `Sabnzbd.cs:462` (`Dir.EndsWith("*")`) |

`FullPath` (`OsPath`) вычисляется, а не десериализуется.

Сборка пути — `Sabnzbd.GetCategories` (`Sabnzbd.cs:216-244`):

```csharp
var completeDir = new OsPath(config.Misc.complete_dir);

if (!completeDir.IsRooted)
{
    if (HasVersion(2, 0))
    {
        var status = _proxy.GetFullStatus(Settings);
        completeDir = new OsPath(status.CompleteDir);
    }
    else
    {
        var queue = _proxy.GetQueue(0, 1, Settings);
        var defaultRootFolder = new OsPath(queue.DefaultRootFolder);
        completeDir = defaultRootFolder + completeDir;
    }
}

foreach (var category in config.Categories)
{
    var relativeDir = new OsPath(category.Dir.TrimEnd('*'));
    category.FullPath = completeDir + relativeDir;
    yield return category;
}
```

`OsPath.operator+` (`src/NzbDrone.Common/Disk/OsPath.cs:420-448`) возвращает `left`, когда `right.IsEmpty`,
поэтому `dir: ""` даёт ровно `FullPath == complete_dir`. `IsRooted` для пути Unix-типа — это `_path.StartsWith("/")` (`OsPath.cs:142-145`); тип пути определяется по строке (`OsPath.cs:43-60`): ведущий `/` ⇒ Unix, `\` или буква диска ⇒ Windows. Путь Unix-типа, переданный Sonarr, запущенному на Windows, не проходит `CompletedDownloadService.ValidatePath` (`:305-310`).

### 3.4 Две ловушки с NRE (и что на самом деле безопасно) {#34-the-two-nre-landmines-and-what-is-actually-safe}

| Структура payload | Результат |
|---|---|
| **`"misc"` отсутствует или `null`** | `Misc` остаётся null (конструктор не задаёт значение по умолчанию, при чтении действует `NullValueHandling.Ignore`) → **NullReferenceException в `Sabnzbd.cs:218`**, появляется как "Test was aborted due to an error: …" и как записанная ошибка в проверках работоспособности. |
| **категория с `"dir"`, которого нет, или `null`** | `Dir` равен null → **NullReferenceException в `Sabnzbd.cs:238`** (`category.Dir.TrimEnd('*')`) и снова в `:462` (`category.Dir.EndsWith("*")`). |
| `"categories": null` или отсутствует | Безопасно. Пустой список из конструктора сохраняется. `GetStatus` тогда не находит категорию, и `OutputRootFolders` остаётся пустым. |
| `"sorters": null` или отсутствует | Безопасно. Пустой список из конструктора, `config.Sorters.Any(...)` в `Sabnzbd.cs:484` работает. |
| `"servers": null` или отсутствует | Безопасно и никогда не читается (`List<object>`, `SabnzbdCategory.cs:19`). |
| `"tv_categories"/"movie_categories"/"date_categories": null` | Безопасно: `ContainsCategory` возвращает `true` для null/пустого значения (§3.5), но это важно, только если соответствующий `enable_*_sorting` равен true. |

**Правило: всегда передавайте `misc` как объект, а каждую категорию с строковым `dir` (используйте `""`).**

### 3.5 `ContainsCategory` (`Sabnzbd.cs:523-536`)

```csharp
private bool ContainsCategory(IEnumerable<string> categories, string category)
{
    if (categories == null || categories.Empty())
    {
        return true;          // <-- null/empty means "all categories"
    }

    if (category.IsNullOrWhiteSpace())
    {
        category = "Default";
    }

    return categories.Contains(category);
}
```

Подтверждено фикстурами: `enable_tv_sorting=true` + `tv_categories=null` **не проходит** (`SabnzbdFixture.cs:636-645`), а + `tv_categories=[]` тоже **не проходит** (`:647-656`). `TvCategory=null` + `tv_categories=["Default"]` не проходит (`:680-691`).

### 3.6 `Test()` — точный порядок и правила (`Sabnzbd.cs:286-292`) {#36-test--the-exact-order-and-rules-sabnzbdcs286-292}

```csharp
protected override void Test(List<ValidationFailure> failures)
{
    failures.AddIfNotNull(TestConnectionAndVersion());
    failures.AddIfNotNull(TestAuthentication());
    failures.AddIfNotNull(TestGlobalConfig());
    failures.AddIfNotNull(TestCategory());
}
```

Это обёртка `DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`). Она ловит любое исключение, которое вылетело наружу, и добавляет `"Test was aborted due to an error: " + ex.Message`.

**`TestConnectionAndVersion()` (`Sabnzbd.cs:368-414`)** — 1 × `mode=version`:

1. Версия не парсится → ошибка в поле `Version` (`DownloadClientSabnzbdValidationUnknownVersion`).
2. `rawVersion == "develop"` (без учёта регистра) → **предупреждение** в `Version`, `IsValid` остаётся true (фикстура `SabnzbdFixture.cs:566-577`).
3. `version.Major >= 1` → проходит (`:389-392`).
4. Иначе `version.Minor >= 7` → проходит (`:394-397`).
5. Иначе ошибка: нужная версия `"0.7.0"` (`:399-404`).
   Таблица фикстуры (`SabnzbdFixture.cs:549-564`): `0.6.9`→false, `0.7.0`/`0.8.0`/`1.0.0`/`1.0.0RC1`/`1.1.x`→true.
6. Любое исключение → ошибка в поле `Host` ("unable to connect"), детали = `ex.Message` (`:406-413`).

**`TestAuthentication()` (`Sabnzbd.cs:416-438`)** — 1 × `mode=get_config`. Ловит исключение и сверяет `ex.Message` через `ContainsIgnoreCase`:

| Найденная подстрока | Поле с ошибкой |
|---|---|
| `API Key Incorrect` | `APIKey` — `DownloadClientValidationApiKeyIncorrect` |
| `API Key Required` | `APIKey` — `DownloadClientValidationApiKeyRequired` |
| всё остальное | **пробрасывается дальше** → общая ошибка "Test was aborted due to an error: …" |

Так как `CheckForError` оборачивает тело в `"Error response received from SABnzbd: {error}"` (`SabnzbdProxy.cs:244`), сопоставление работает, когда твоя строка `error` *содержит* `API Key Incorrect` / `API Key Required`, то есть формулировку самого SAB.

**`TestGlobalConfig()` (`Sabnzbd.cs:440-453`)** — 1 × `mode=get_config`, плюс 1 × `mode=version`, только если `pre_check` равен true:

```csharp
var config = _proxy.GetConfig(Settings);
if (config.Misc.pre_check && !HasVersion(1, 1))
{
    return new NzbDroneValidationFailure("", "…CheckBeforeDownload")
    {
        InfoLink = _proxy.GetBaseUrl(Settings, "config/switches/"),
        …
    };
}
```

Порог: **SAB >= 1.1.0** (`HasVersion(major:1, minor:1, patch:0)`, `Sabnzbd.cs:294-332`). `pre_check: false` пропускает всю эту ветку, включая лишний запрос `mode=version`.

**`TestCategory()` (`Sabnzbd.cs:455-521`)** — 1 × `mode=get_config` (это уже *третий*), плюс всё, что нужно `GetCategories`. Проверки идут в таком порядке, первое совпадение побеждает:

1. Найденная категория (`Name == Settings.TvCategory` / `MovieCategory`), у которой `dir` **заканчивается на `*`** → предупреждение в `TvCategory`/`MovieCategory` "enable job folders", InfoLink `config/categories/` (`:460-469`).
2. Найденной категории нет, **и** настроенная категория не пустая → предупреждение `DownloadClientValidationCategoryMissing`, InfoLink `config/categories/` (`:471-481`).
3. `config.Sorters.Any(s => s.is_active && ContainsCategory(s.sort_cats, cat))` → предупреждение, InfoLink `config/sorting/` (`:483-491`). Комментарий в коде на `:483`: *«New in SABnzbd 4.1, but on older versions this will be empty and not apply»* (то есть: появилось в SABnzbd 4.1, а в старых версиях поле будет пустым и ничего не даст).
4. `misc.enable_tv_sorting && ContainsCategory(misc.tv_categories, cat)` → предупреждение (`:493-500`).
5. `misc.enable_movie_sorting && ContainsCategory(misc.movie_categories, cat)` → предупреждение (`:502-509`).
6. `misc.enable_date_sorting && ContainsCategory(misc.date_categories, cat)` → предупреждение (`:511-518`).

`SabnzbdSorter` (`SabnzbdCategory.cs:50-66`): читаются `sort_cats` (`List<string>`, в конструкторе пустой) и `is_active` (`bool`). Остальные поля есть в модели, но никогда не читаются: `name`, `order`, `min_size`, `multipart_label`, `sort_string`, `sort_type` (`List<int>`).

**Заметка про трафик:** все четыре метода `Test*` делают свои запросы, ничего не кешируется. Один тест соединения выдаёт примерно **2 × `mode=version` и 3 × `mode=get_config`** (четвёртый запрос version, если `pre_check` равен true).

### 3.7 История хранения в `config.misc` → `RemovesCompletedDownloads` (`Sabnzbd.cs:538-574`) {#37-configmisc-history-retention--removescompleteddownloads-sabnzbdcs538-574}

```csharp
var retention = config.Misc.history_retention;
var option    = config.Misc.history_retention_option;
var number    = config.Misc.history_retention_number;

switch (option)
{
    case "all":                                     return false;
    case "number-archive": case "number-delete":    return true;
    case "days-archive":   case "days-delete":      return number < 14;
    case "all-archive":    case "all-delete":       return true;
}

// TODO: Remove these checks once support for SABnzbd < 4.3 is removed
if (retention.IsNullOrWhiteSpace()) { return false; }
if (retention.EndsWith("d")) { int.TryParse(retention[..^1], out var daysRetention); return daysRetention < 14; }
return retention != "0";
```

`true` вызывает **предупреждение** проверки состояния
(`HealthCheck/Checks/DownloadClientRemovesCompletedDownloadsCheck.cs:44-53`).
Покрытие фикстур `SabnzbdFixture.cs:455-510`: устаревшие `"0"`/`""`/`null`/`"15d"` → false;
`"-1"`/`"15"`/`"3"`/`"3d"` → true.

**Самый чистый ответ для эмулятора: `history_retention_option: "all"`, `history_retention_number: 0`,
`history_retention: "0"`.**

### 3.8 `SortingMode` и его проверка состояния (`Sabnzbd.cs:263-279`) {#38-sortingmode-and-its-health-check-sabnzbdcs263-279}

`GetStatus` задаёт `SortingMode` равным `"TV"`, `"Movie"` или `"Date"`, используя те же предикаты
`enable_*_sorting && ContainsCategory(...)`. Любое непустое значение вызывает предупреждение в
`HealthCheck/Checks/DownloadClientSortingCheck.cs:45-55`. Оставь все три `enable_*_sorting` со значением false.

### 3.9 `IsLocalhost` (`Sabnzbd.cs:260`)

```csharp
IsLocalhost = Settings.Host == "127.0.0.1" || Settings.Host == "localhost"
```

Порядковое сравнение, с учётом регистра; `::1`, `Localhost` и любое имя хоста **не** считаются. Это влияет на то, какое сообщение `RemotePathMappingCheck` вы получите (см. §6.2).

---

## 4. Обработка ошибок — `CheckForError` (`SabnzbdProxy.cs:222-246`) {#4-error-handling--checkforerror-sabnzbdproxycs222-246}

```csharp
private void CheckForError(HttpResponse response)
{
    if (!Json.TryDeserialize<SabnzbdJsonError>(response.Content, out var result))
    {
        // Handle plain text responses from SAB
        result = new SabnzbdJsonError();

        if (response.Content.StartsWith("error", StringComparison.InvariantCultureIgnoreCase))
        {
            result.Status = "false";
            result.Error = response.Content.Replace("error: ", "");
        }
        else
        {
            result.Status = "true";
        }

        result.Error = response.Content.Replace("error: ", "");   // :239 — assigned in BOTH branches
    }

    if (result.Failed)
    {
        throw new DownloadClientException("Error response received from SABnzbd: {0}", result.Error);
    }
}
```

`SabnzbdJsonError` (`SabnzbdJsonError.cs`, полностью):

```csharp
public string Status { get; set; }
public string Error  { get; set; }

public bool Failed => !string.IsNullOrWhiteSpace(Status) &&
                      Status.Equals("false", StringComparison.InvariantCultureIgnoreCase);
```

Правила, точно:

- `CheckForError` запускается на **каждом** ответе, до любой десериализации, зависящей от режима
  (`SabnzbdProxy.cs:217`).
- `Status` объявлен как `string`, но SAB присылает JSON **булево значение**. Newtonsoft приводит `false` → `"False"`,
  и `Failed` сравнивает это без учёта регистра. Работают и `false` (булево), и `"false"` (строка).
- Ответ **без верхнеуровневого `status`** (например, `{"version": …}`, `{"queue": {...}}`,
  `{"history": {...}}`, `{"config": {...}}`) оставляет `Status` равным null → `Failed` false → ошибки нет.
- `status: true` → `"True"` → не ошибка.
- **Тело не в формате JSON**: `TryDeserialize` возвращает false (он перехватывает `JsonReaderException` и
  `JsonSerializationException`, `Json.cs:107-116`), и запускается ветка для простого текста. Если тело начинается
  с `error` (без учёта регистра), то `Status = "false"` и выбрасывается
  `DownloadClientException("Error response received from SABnzbd: {body with 'error: ' stripped}")`.
  Любое другое тело не в формате JSON → `Status = "true"` → **считается успехом**, и затем десериализация,
  зависящая от режима, падает по своим причинам.
- **JSON-тело, в котором `status` является объектом** (`mode=fullstatus`), тоже идёт по ветке простого текста,
  потому что токен `StartObject` не может заполнить свойство `string`. `Status` становится `"true"`.
- Обратите внимание на лишнее присваивание `result.Error = …` на `:239`: `Error` задаётся даже в ветке успеха. Это ни на что не влияет
  (`Error` никто не читает, если только `Failed` не истинно).

Сопоставление исключений в `ProcessRequest` (`SabnzbdProxy.cs:187-220`):

| Поймано | Выброшено |
|---|---|
| `HttpException` (любой не-2xx, включая 401/403/404/500) | `DownloadClientException("Unable to connect to SABnzbd, {0}")` |
| `HttpRequestException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |
| `WebException` с `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, certificate validation failed.")` |
| любой другой `WebException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |

**Точные строки ошибок авторизации**, которые сопоставляются (`Sabnzbd.cs:424, 429`, точные литералы, сравниваются
через `ContainsIgnoreCase` с текстом исключения):

- `"API Key Incorrect"`
- `"API Key Required"`

Больше ничего не классифицируется. Выдавайте их дословно как значение `error` в ответе **HTTP 200**.

**Почему нельзя возвращать не-200:** `HttpClient.Execute` выбрасывает исключение раньше, чем запускается `CheckForError`
(`HttpClient.cs:106-121`). Текст получившегося `HttpException` содержит только статус, метод и URL, но не тело
(`HttpException.cs:18`), поэтому сопоставление `"API Key Incorrect"` / `"API Key Required"` не сработает. Пользователь увидит
"Unable to connect to SABnzbd" или "Test was aborted due to an error" вместо понятного сообщения, а каждая проверка
работоспособности будет считать клиент недоступным.

---

## 5. Последовательность действий после импорта {#5-the-post-import-sequence}

### 5.1 Кто вызывает `RemoveItem` и с какими параметрами {#51-who-calls-removeitem-and-with-what}

- `DownloadEventHub` (`src/NzbDrone.Core/Download/DownloadEventHub.cs`, одинаковый в обоих репозиториях, кроме BOM):

- `Handle(DownloadCompletedEvent)` (`:48-69`): вызывает `MarkItemAsImported` (SAB выбрасывает `NotSupportedException` — `DownloadClientBase.cs:189-192` — это пишется в лог на уровне debug и игнорируется), затем выходит раньше, если элемент уже `Removed`, `!CanBeRemoved` или всё ещё `Downloading`, и выходит раньше, если не задано `definition.RemoveCompletedDownloads`.
- `Handle(DownloadFailedEvent)` (`:26-46`): зависит от `definition.RemoveFailedDownloads`.
- `Handle(DownloadCanBeRemovedEvent)` (`:71-85`): зависит от `definition.RemoveCompletedDownloads`.
- Все три обработчика в итоге вызывают `RemoveFromDownloadClient` (`:87-103`):

```csharp
_logger.Debug("[{0}] Removing download from {1} history", …);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);   // :92 -- deleteData is ALWAYS true
trackedDownload.DownloadItem.Removed = true;
```

Значения `DownloadClientDefinition` по умолчанию (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17-18`):

```csharp
public bool RemoveCompletedDownloads { get; set; } = true;
public bool RemoveFailedDownloads    { get; set; } = true;
```

Ручной путь через API, `DELETE /api/v3/queue/{id}?removeFromClient=true`, тоже передаёт `true` (Sonarr `src/Sonarr.Api.V3/Queue/QueueController.cs:342`). **Нигде в коде нет вызова, который передаёт `deleteData: false`.**

### 5.2 `Sabnzbd.RemoveItem` (`Sabnzbd.cs:197-214`) — точная последовательность {#52-sabnzbdremoveitem-sabnzbdcs197-214--the-exact-sequence}

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    var queueClientItem = GetQueue().SingleOrDefault(v => v.DownloadId == item.DownloadId);   // extra mode=queue

    if (queueClientItem == null)
    {
        if (deleteData && item.Status == DownloadItemStatus.Completed)
        {
            DeleteItemData(item);                                                             // rm -rf, see 5.3
        }

        _proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
    }
    else
    {
        _proxy.RemoveFromQueue(item.DownloadId, deleteData, Settings);
    }
}
```

Итак, последовательность запросов после импорта к эмулятору выглядит так:

1. `GET /api?mode=queue&start=0&limit=0&category=tv&apikey=…&output=json` (чтобы решить, очередь это или история)
2. **локальное удаление папки вывода с файловой системы** (§5.3) — до любого следующего HTTP-запроса
3. `GET /api?mode=history&name=delete&del_files=1&value={nzo_id}&archive=1&apikey=…&output=json`

Для **неудачного** элемента: локального удаления нет (статус `Failed`, а не `Completed`), и **`archive=0`** —
инверсия в `SabnzbdProxy.cs:80` (`archive = deletePermanently ? 0 : 1`, где `deletePermanently == (status is Failed)`).

### 5.3 `DeleteItemData` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`)

```csharp
protected virtual void DeleteItemData(DownloadClientItem item)
{
    if (item == null) { return; }

    if (item.OutputPath.IsEmpty)
    {
        _logger.Trace("[{0}] Doesn't have an outputPath, skipping delete data.", item.Title);
        return;
    }

    try
    {
        if (_diskProvider.FolderExists(item.OutputPath.FullPath))
        {
            _logger.Debug("[{0}] Deleting folder '{1}'.", item.Title, item.OutputPath);
            _diskProvider.DeleteFolder(item.OutputPath.FullPath, true);        // :129  recursive == true
        }
        else if (_diskProvider.FileExists(item.OutputPath.FullPath))
        {
            _logger.Debug("[{0}] Deleting file '{1}'.", item.Title, item.OutputPath);
            _diskProvider.DeleteFile(item.OutputPath.FullPath);                 // :135
        }
        else
        {
            _logger.Trace("[{0}] File or folder '{1}' doesn't exist, skipping cleanup.", item.Title, item.OutputPath);
        }
    }
    catch (Exception ex)
    {
        _logger.Warn(ex, string.Format("[{0}] Error occurred while trying to delete data from '{1}'.", item.Title, item.OutputPath));
    }
}
```

- **Да, он рекурсивно удаляет папку вывода.** `DeleteFolder(path, recursive: true)` в `:129`.
- `OutputPath` здесь — это `storage` элемента истории после ремаппинга удалённого пути и подъёма до папки задания
  (§1.6.2). Для плоской magic-директории это значит `rm -rf /mnt/zurg/__magic__/__all__/<Title>`.
- За удаление отвечает переключатель **Remove Completed Downloads** в клиенте загрузки
  (`DownloadClientDefinition.RemoveCompletedDownloads`, по умолчанию **true**), *а не* настройка на стороне SAB
  и *не* `del_files`. Отдельного переключателя «delete data» в UI нет.
- Ошибки перехватываются и выводятся как предупреждение. Если маунт только для чтения, в логе будет шум, но импорт не сломается.
- Покрытие фикстурами `SabnzbdFixture.cs:693-803`: папка удаляется рекурсивно, файл удаляется, ничего не происходит, если путь не существует, и вообще ничего не делается (даже проверка `FolderExists`), когда `deleteData` равен false.

(Предыдущий перевод был отклонён: кодовые фрагменты не совпадают. Сохраните структуру в точности.)

### 5.4 Режим переноса: файл перемещается или копируется? {#54-transfer-mode-is-the-file-moved-or-copied}

`Sabnzbd` ставит `CanMoveFiles = true` для **каждого** элемента, и в очереди (`Sabnzbd.cs:76`), и в истории (`Sabnzbd.cs:135`). Путь автоматического импорта такой: `CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, …)` (Sonarr `CompletedDownloadService.cs:148-151`), а дальше:

Sonarr `src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152`
(Radarr `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, логика та же самая):

```csharp
bool copyOnly;
switch (importMode)
{
    default:
    case ImportMode.Auto: copyOnly = downloadClientItem is { CanMoveFiles: false }; break;
    case ImportMode.Move: copyOnly = false; break;
    case ImportMode.Copy: copyOnly = true;  break;
}
```

`CanMoveFiles: true` ⇒ `copyOnly == false` ⇒ **`TransferMode.Move`**
(`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`). Импорт с `copyOnly` использовал бы `TransferMode.HardLinkOrCopy`, если включена опция "Use Hardlinks instead of Copy", иначе `TransferMode.Copy` (`:94-108`).

`TransferMode` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`) помечен как `[Flags]`:
`None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy = Copy|HardLink`.

### 5.5 Если Move не удался, будет ли копирование? — **Нет. Неудачное перемещение означает неудачный импорт.** {#55-does-a-failed-move-fall-back-to-a-copy--no-a-failed-move-is-a-failed-import}

`src/NzbDrone.Common/Disk/DiskTransferService.cs` (побайтово идентичен в обоих репозиториях, проверено).
`TransferFile`, `:256-392`; ветка `TransferMode.Move` в `:360-389`:

```csharp
if (mode.HasFlag(TransferMode.Move))
{
    if (isBtrfs || isZfs)
    {
        if (isSameMount && _diskProvider.TryRenameFile(sourcePath, targetPath)) { return TransferMode.Move; }
        if (_diskProvider.TryCreateRefLink(sourcePath, targetPath)) { _diskProvider.DeleteFile(sourcePath); return TransferMode.Move; }
    }

    if (isCifs && !isSameMount)                                        // :378
    {
        _logger.Trace("On cifs mount. Starting verified copy [{0}] to [{1}].", sourcePath, targetPath);
        TryCopyFileVerified(sourcePath, targetPath, originalSize);
        _logger.Trace("Copy successful, deleting source [{0}].", sourcePath);
        _diskProvider.DeleteFile(sourcePath);
        return TransferMode.Move;
    }

    TryMoveFileVerified(sourcePath, targetPath, originalSize);         // :387
    return TransferMode.Move;
}
```

- **Единственный** запасной вариант с копированием — это особый случай `isCifs && !isSameMount` в `:378-385`, который завязан на `targetMount.DriveFormat == "cifs"` (`:342`). Он выбирается *заранее* по формату диска, а не в ответ на ошибку.
- `TryMoveFileVerified` (`:487-503`) перехватывает исключение, вызывает `RollbackPartialMove` (если только это не `FileAlreadyExistsException`) и **пробрасывает** его дальше:

```csharp
private void TryMoveFileVerified(string sourcePath, string targetPath, long originalSize)
{
    try
    {
        _diskProvider.MoveFile(sourcePath, targetPath);
        VerifyFile(sourcePath, targetPath, originalSize, "move");
    }
    catch (Exception ex)
    {
        if (ex is not FileAlreadyExistsException) { RollbackPartialMove(sourcePath, targetPath); }
        throw;
    }
}
```

- `VerifyFile` (`:505-524`) сравнивает размер назначения с размером источника, ждёт 3 с (`WaitForIO`, `:467-471`), проверяет ещё раз и затем бросает `IOException("File move incomplete, data loss may have occurred. [{target}] was {n} bytes long instead of the expected {m}.")`.
- Этот `IOException` поднимается через `EpisodeFileMovingService.TransferFile` (`:151`) в общий `catch (Exception e)` в `ImportApprovedEpisodes.cs:218-222` (Radarr `:197-201`) и превращается в `ImportResult(importDecision, "Failed to import episode")` / `"Failed to import movie"`. **Копирование не пробуется.**
- Другие предварительные проверки с `IOException` в том же методе: источник совпадает с назначением (`:270`, `:277`) и «Destination cannot be a child of the source» (`:312-315`).

Важная оговорка: это особенность рантайма .NET, а не код Sonarr. `DiskProviderBase.MoveFileInternal` (`src/NzbDrone.Common/Disk/DiskProviderBase.cs:293-301`) — это обычный `File.Move`, а .NET в Unix при `EXDEV` от `rename()` переключается на копирование с последующим удалением. Поэтому перемещение между файловыми системами обычно всё равно проходит успешно, но это запасной вариант рантайма, а не Sonarr. А вот не пройдут: назначение, размер которого отличается от источника, и любое исключение, которое само `File.Move` выдаёт (EACCES, EPERM, EROFS на источнике и т. п.).

`TransferFolder` (`:44-137`) используется в других путях кода. Обрати внимание на `:124-131`: после перемещения папки он не удаляет источник, если в нём осталось больше 100 МБ файлов (`IOException("Large files still exist in {sourcePath} after folder move, not deleting source folder")`).

## 6. Две проверки состояния {#6-the-two-health-checks}

### 6.1 `DownloadClientRootFolderCheck` — **единственное место, где Sonarr и Radarr действительно отличаются** {#61-downloadclientrootfoldercheck--the-one-place-sonarr-and-radarr-genuinely-differ}

Sonarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = status.OutputRootFolders.Where(folder => rootFolders.Any(r => r.Path.PathEquals(folder.FullPath)));
```

Radarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = rootFolders.Where(r => status.OutputRootFolders.Any(folder => r.Path.PathEquals(folder.FullPath) || r.Path.IsParentPath(folder.FullPath)));
```

`IsParentPath` (`src/NzbDrone.Common/Extensions/PathExtensions.cs:123-140`) идёт **вверх** от дочернего пути:

```csharp
public static bool IsParentPath(this string parentPath, string childPath)
{
    var parent = new OsPath(parentPath);
    var child  = new OsPath(childPath);

    while (child.Directory != OsPath.Null)
    {
        if (child.Directory.Equals(parent, true)) { return true; }
        child = child.Directory;
    }

    return false;
}
```

Поэтому `r.Path.IsParentPath(folder.FullPath)` даёт true, когда **корневая папка является предком папки вывода загрузок**, то есть папка вывода лежит *внутри* корневой папки. Это строгая проверка на предка (она начинается с `child.Directory`); равенство обрабатывается отдельно через `PathEquals`.

**Прямой ответ на вопрос о предикате:**

| Связь (папка вывода O и корневая папка R) | Sonarr | Radarr |
|---|---|---|
| O == R | **предупреждение** | **предупреждение** |
| O внутри R (R является предком O) | без предупреждения | **предупреждение** |
| O является родителем R (O является предком R) | без предупреждения | **без предупреждения** |
| не связаны | без предупреждения | без предупреждения |

При `complete_dir = /mnt/zurg/__magic__/__all__` и `dir: ""` (так что `OutputRootFolders == ["/mnt/zurg/__magic__/__all__"]`):

- Sonarr выдаёт предупреждение, только если корневая папка в точности `/mnt/zurg/__magic__/__all__`.
- Radarr выдаёт предупреждение, если корневая папка — `/mnt/zurg/__magic__/__all__`, `/mnt/zurg/__magic__`, `/mnt/zurg` или `/mnt`.
- Ни один не выдаёт предупреждение, если корневая папка — `/mnt/zurg/__magic__/tv`: зеркало и корневые папки лежат на одном уровне, то есть пара не связана, и ни одно правило не срабатывает. Корневая папка *внутри* папки вывода (`/mnt/zurg/__magic__/__all__/anything`) тоже не вызвала бы предупреждения, но пространство имён не позволяет хранить ничего на такой глубине, так что такая конфигурация невозможна.

`PathEquals` (`PathExtensions.cs:55-73`) нормализует Unicode, использует `DiskProviderBase.PathStringComparison`
(`OrdinalIgnoreCase` в Windows, `Ordinal` в остальных системах — `src/NzbDrone.Common/Disk/DiskProviderBase.cs:17-23`) и повторяет проверку с `CleanFilePath()` (не чувствительно к завершающему слэшу).

Обе версии перезапускаются при `ProviderUpdatedEvent` / `ProviderDeletedEvent` / `ModelEvent<RootFolder>` / `ModelEvent<RemotePathMapping>`; Radarr добавляет `[CheckOn(typeof(ProviderAddedEvent<IDownloadClient>))]`
на `:17`. Результат — `HealthCheckResult.Warning` с якорем `#downloads-in-root-folder`. Сообщение
подставляет `folder.FullPath` в Sonarr и `folder.Path` в Radarr (`:60` в обеих). Обе молча
пропускают `DownloadClientException` и `HttpRequestException` (запись в debug-лог), а любое другое исключение
логируют как ошибку.

### 6.2 `RemotePathMappingCheck` — путь локального клиента (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs`) {#62-remotepathmappingcheck--the-local-client-path-srcnzbdronecorehealthcheckchecksremotepathmappingcheckcs}

Короткое замыкание на `:51-54`: если `EnableCompletedDownloadHandling` выключен, проверка ничего не делает.

Для каждого `folder` из `client.GetStatus().OutputRootFolders`:

1. **`!folder.IsValid`** (`:68`) — `OsPath.IsValid` = `_path.IsPathValid(PathValidationType.CurrentOs)`
   (`OsPath.cs:228`). На не-Windows это сводится к `path.StartsWith("/")` плюс проверке через `Path.GetInvalidPathChars()` (`PathExtensions.cs:143-182`, `:403-411`). Ошибки, по порядку:
   - `!status.IsLocalhost` → `RemotePathMappingWrongOSPathHealthCheckMessage` (ключ в Radarr: `RemotePathMappingCheckWrongOSPath`), якорь `#bad-remote-path-mapping`
   - `_osInfo.IsDocker` → …`BadDockerPath`, якорь `#docker-bad-remote-path-mapping`
   - иначе → …`LocalWrongOSPath`, якорь `#bad-download-client-settings`
2. **`!_diskProvider.FolderExists(folder.FullPath)`** (`:115`):
   - `_osInfo.IsDocker` → …`DockerFolderMissing`, `#docker-bad-remote-path-mapping`
   - `!status.IsLocalhost` → …`LocalFolderMissing`, `#bad-remote-path-mapping`
   - иначе → …`GenericPermissions`, `#permissions-error`

**Для локального клиента (`IsLocalhost` true, не Docker) проверка сводится к двум требованиям:**
путь к корневой папке вывода, который сообщает клиент, должен быть абсолютным *для той ОС, на которой работают Sonarr/Radarr*, и
он должен **существовать как папка на хосте Sonarr/Radarr**. `/mnt/zurg/__magic__/__all__` должен быть виден
процессу *arr, а не только эмулятору. **Проверки на запись здесь нет.**

Событийная перегрузка (`:178-368`) срабатывает на `EpisodeImportFailedEvent` (в Radarr:
`MovieImportFailedEvent`) и, что важно, снова вызывает `client.GetItems()`, чтобы найти `OutputPath` неудавшейся загрузки (`:232`).

Ни одна проверка здоровья не требует, чтобы папка вывода была *доступна для записи*. `FolderWritable`
(`DiskProviderBase.cs:126-143` в Sonarr / `:127-144` в Radarr), который записывает и удаляет `sonarr_write_test.txt` / `radarr_write_test.txt`, используется в
`RootFolderService.Add` (Sonarr `src/NzbDrone.Core/RootFolders/RootFolderService.cs:117-120`) и в `DownloadClientBase.TestFolder` (`:167-187`), а **`TestFolder` никогда не вызывается SAB-клиентом**.

## 7. Sonarr и Radarr — полный diff {#7-sonarr-vs-radarr--the-complete-diff}

Каждый загруженный файл был сверен через diff. Результаты:

**Побайтово идентичны, кроме UTF-8 BOM в копиях Sonarr** (поэтому номера строк совпадают точно):

`SabnzbdCategory.cs` (BOM нет ни в одной из версий, действительно идентичен), `SabnzbdDownloadStatus.cs`,
`SabnzbdPriority.cs`, `SabnzbdFullStatus.cs`, `SabnzbdJsonError.cs`, `SabnzbdQueue.cs`,
`SabnzbdQueueItem.cs`, `SabnzbdHistory.cs`, `SabnzbdHistoryItem.cs`,
`JsonConverters/*.cs` (все три), `Responses/*.cs` (все шесть),
`src/NzbDrone.Common/Disk/DiskTransferService.cs`, `src/NzbDrone.Core/Download/DownloadEventHub.cs`.

**Отличаются только переименованием `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` (количество строк не меняется, номера строк те же):**

- `Sabnzbd.cs` — `:40-52` (`AddFromNzbFile`; проверка свежести в Radarr это `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie`, а в Sonarr `remoteEpisode.IsRecentEpisode()`), `:190`, `:251`, `:265/269/273`, `:458`, а также каждое имя поля `NzbDroneValidationFailure` в `TestCategory` (`"TvCategory"` → `"MovieCategory"`).
- `SabnzbdProxy.cs` — `:50`, `:122-124`, `:138-140`.
- `SabnzbdSettings.cs` — значения по умолчанию `TvCategory = "tv"` против `MovieCategory = "movies"`; `RecentTvPriority`/`OlderTvPriority` против `RecentMoviePriority`/`OlderMoviePriority` (оба по умолчанию `(int)SabnzbdPriority.Default`). Во всём остальном валидатор идентичен: `Host` должен быть валидным, `Port` 1–65535, `ApiKey` обязателен, если username пустой, `Username`/`Password` обязательны, если ApiKey пустой, категория `NotEmpty` **как предупреждение**.
- `UsenetClientBase.cs` — Radarr дополнительно ставит `request.AllowAutoRedirect = true` (`:51`) и обрабатывает HTTP `410 Gone` так же, как `404` (`:63`), при загрузке NZB с индексера. **Это касается индексера, а не SAB.**
- `DownloadClientBase.cs` — только сами слова "Sonarr"/"Radarr" в тексте деталей `TestFolder`.
- `RemotePathMappingCheck.cs` — имена ключей локализации (`RemotePathMapping*HealthCheckMessage` против `RemotePathMappingCheck*`), `EpisodeImportFailedEvent` против `MovieImportFailedEvent`, а также дополнительный `[CheckOn(ProviderAddedEvent<IDownloadClient>)]` в Radarr. **Предикаты идентичны.**
- `DiskProviderBase.cs` — тестовый файл `FolderWritable` `sonarr_write_test.txt` против `radarr_write_test.txt` (Sonarr `:132`, Radarr `:133`).

**Реальное различие в поведении — ровно одно:**

- **`DownloadClientRootFolderCheck.cs:51`.** Sonarr выдаёт предупреждение только при `PathEquals`; Radarr также предупреждает, когда корневая папка является родительской для выходной папки. Полная таблица в §6.1.

Всё остальное — режимы, параметры, формы JSON, перечисления, конвертеры, `CheckForError`, `RemoveItem`, `DeleteItemData`, режим передачи, `DiskTransferService` — идентично. **Один эмулятор обслуживает оба.**

Значения конфигурации по умолчанию одинаковы в обоих: `DownloadClientHistoryLimit = 60`, `RemoveCompletedDownloads = true`, `RemoveFailedDownloads = true`.

---

## 8. Минимальные, но полные примеры payload {#8-minimal-but-complete-example-payloads}

Дано: `complete_dir = /mnt/zurg/__magic__/__all__`; категории `*`, `tv`, `movies`, все с `dir: ""`.
Каждый ответ — **HTTP 200** с `Content-Type: application/json`.

Итоговые `OutputRootFolders`: `dir: ""` ⇒ `FullPath == complete_dir` ⇒ `/mnt/zurg/__magic__/__all__`
для Sonarr (категория `tv`) и для Radarr (категория `movies`).

### 8.1 `mode=version`

```json
{
  "version": "4.3.3"
}
```

Должен быть `major.minor.(patch|x)`. `4` ≥ 1 проходит `TestConnectionAndVersion` (`Sabnzbd.cs:389-392`);
≥ 2.0 также означает, что `GetCategories` использовал бы `fullstatus`, а не `queue.my_home`, если бы `complete_dir`
был относительным (он не такой).

### 8.2 `mode=get_config`

```json
{
  "config": {
    "misc": {
      "complete_dir": "/mnt/zurg/__magic__/__all__",
      "pre_check": false,
      "enable_tv_sorting": false,
      "tv_categories": [],
      "enable_movie_sorting": false,
      "movie_categories": [],
      "enable_date_sorting": false,
      "date_categories": [],
      "history_retention": "0",
      "history_retention_option": "all",
      "history_retention_number": 0
    },
    "servers": [],
    "categories": [
      { "name": "*",      "order": 0, "pp": "3", "script": "None", "dir": "", "newzbin": "", "priority": 0 },
      { "name": "tv",     "order": 1, "pp": "3", "script": "None", "dir": "", "newzbin": "", "priority": 0 },
      { "name": "movies", "order": 2, "pp": "3", "script": "None", "dir": "", "newzbin": "", "priority": 0 }
    ],
    "sorters": []
  }
}
```

Почему каждое значение такое:

- `misc` должен быть объектом: **обязательно**, иначе NRE (§3.4).
- у каждой категории должен быть **строковый** `dir`: **обязательно**, иначе NRE в `Sabnzbd.cs:238` и `:462`.
- `dir` **не** должен заканчиваться на `*`, иначе появится предупреждение "enable job folders" (`Sabnzbd.cs:462-469`).
- все три `enable_*_sorting: false` убирают и предупреждения `TestCategory` (`Sabnzbd.cs:493-518`), и `DownloadClientSortingCheck`. Учтите, что `tv_categories: []` вместе с `enable_tv_sorting: true` **провалит** проверку, потому что `ContainsCategory` для пустого списка возвращает true (`Sabnzbd.cs:525-528`, фикстура `SabnzbdFixture.cs:647-656`).
- `sorters: []`: `config.Sorters.Any(s => s.is_active && …)` возвращает false (`Sabnzbd.cs:484`).
- `pre_check: false` пропускает запрос-ответ `HasVersion(1,1)` в `TestGlobalConfig` (`Sabnzbd.cs:443`).
- `history_retention_option: "all"` → `RemovesCompletedDownloads == false` (`Sabnzbd.cs:546-547`) → предупреждения health-check не будет.
- `complete_dir` абсолютный → `IsRooted` true → `mode=fullstatus` / `queue.my_home` вообще не запрашиваются (`Sabnzbd.cs:220`).

### 8.3 `mode=fullstatus&skip_dashboard=1`

```json
{
  "status": {
    "completedir": "/mnt/zurg/__magic__/__all__",
    "version": "4.3.3",
    "uptime": "1d",
    "color_scheme": "Auto",
    "darwin": false,
    "nt": false,
    "pid": 1,
    "new_release": "",
    "new_rel_url": "",
    "active_lang": "en",
    "my_home": "/mnt/zurg",
    "my_lcldata": "/config",
    "webdir": "",
    "loglevel": "1",
    "folders": [],
    "configfn": "/config/sabnzbd.ini",
    "warnings": [],
    "servers": [],
    "localipv4": "127.0.0.1",
    "publicipv4": "",
    "ipv6": null,
    "dnslookup": "ok"
  }
}
```

Читается только `completedir` (`SabnzbdFullStatus.cs:9-10`). Ключ-обёртка **обязательно** должен называться `status` (`Responses/SabnzbdFullStatusResponse.cs:5`).

### 8.4 Ответ `mode=addfile` {#84-modeaddfile-response}

```json
{
  "status": true,
  "nzo_ids": ["SABnzbd_nzo_abc12345"]
}
```

`nzo_ids` должен быть **непустым массивом строк** (`Sabnzbd.cs:47-52`). `status` парсится
(`Responses/SabnzbdAddResponse.cs:13`), но нигде не читается, так что оставь его `true`, чтобы `CheckForError` видел `"True"`.

### 8.5 `mode=queue&start=0&limit=0&category=tv` — один слот Downloading {#85-modequeuestart0limit0categorytv--one-downloading-slot}

```json
{
  "queue": {
    "status": "Downloading",
    "speedlimit": "0",
    "speedlimit_abs": "",
    "paused": false,
    "noofslots_total": 1,
    "noofslots": 1,
    "limit": 0,
    "start": 0,
    "finish": 0,
    "have_warnings": "0",
    "cache_art": "0",
    "cache_size": "0 B",
    "finishaction": null,
    "queue_details": "0",
    "my_home": "/mnt/zurg",
    "my_lcldata": "/config",
    "mb": "1024.00",
    "mbleft": "512.00",
    "size": "1.0 GB",
    "sizeleft": "512.0 MB",
    "kbpersec": "1024.00",
    "speed": "1.0 M",
    "timeleft": "0:08:32",
    "eta": "12:34 Fri 22 Aug",
    "diskspace1": "1000.00",
    "diskspace2": "1000.00",
    "diskspacetotal1": "2000.00",
    "diskspacetotal2": "2000.00",
    "diskspace1_norm": "1000.0 G",
    "diskspace2_norm": "1000.0 G",
    "slots": [
      {
        "status": "Downloading",
        "index": 0,
        "password": "",
        "avg_age": "2d",
        "script": "None",
        "direct_unpack": null,
        "mb": "1024.00",
        "mbleft": "512.00",
        "mbmissing": "0.00",
        "size": "1.0 GB",
        "sizeleft": "512.0 MB",
        "filename": "Some.Show.S01E01.1080p.WEB-DL.H264-GRP",
        "labels": [],
        "priority": "Normal",
        "cat": "tv",
        "timeleft": "0:08:32",
        "percentage": "50",
        "nzo_id": "SABnzbd_nzo_abc12345",
        "unpackopts": "3"
      }
    ]
  }
}
```

Жёсткие требования:

- Верхнеуровневый ключ `queue` (`SabnzbdProxy.cs:129`, `SelectToken("queue")`).
- `slots[].status` ∈ 16 имён `SabnzbdDownloadStatus`, с точным регистром.
- `slots[].mb` / `mbleft` — это **мегабайты**, десятичные числа в инвариантной культуре. Подходят и строки, и числа (Newtonsoft приводит типы сам); настоящий SAB отдаёт строки.
- `slots[].timeleft` должен быть строго `h:m:s` или `d:h:m:s`, никогда не `""`.
- `slots[].priority` — `"Normal"`, `"High"`, `"Low"`, `"Force"`, `"Paused"`, `"Default"` (с учётом регистра) или числовой эквивалент. **Никогда не `null`** (будет NRE).
- `slots[].cat` (а не `category`) должен совпадать с категорией, настроенной в клиенте, иначе элемент отфильтруется в `Sabnzbd.cs:190`.
- `queue.paused` должен быть `false`, если вы не хотите именно паузу: `true` помечает каждый слот, кроме `Force`, как Paused и с пустым ETA (`Sabnzbd.cs:78-84`).

Итоговый `DownloadClientItem`: `TotalSize = 1024 * 1024 * 1024`, `RemainingSize = 512 * 1024 * 1024`, `RemainingTime = 00:08:32`, `Status = Downloading`, `CanBeRemoved = CanMoveFiles = true`.

### 8.6 `mode=history&start=0&limit=60&category=tv` — один слот Completed и один Failed {#86-modehistorystart0limit60categorytv--one-completed-and-one-failed-slot}

```json
{
  "history": {
    "noofslots": 2,
    "ppslots": 0,
    "day_size": "1.0 G",
    "week_size": "7.0 G",
    "month_size": "30.0 G",
    "total_size": "1.0 T",
    "last_history_update": 1755835200,
    "version": "4.3.3",
    "slots": [
      {
        "id": 1,
        "completed": 1755834000,
        "name": "Some.Show.S01E02.1080p.WEB-DL.H264-GRP",
        "nzb_name": "Some.Show.S01E02.1080p.WEB-DL.H264-GRP.nzb",
        "category": "tv",
        "pp": "3",
        "script": "None",
        "report": "",
        "url": "",
        "status": "Completed",
        "nzo_id": "SABnzbd_nzo_def67890",
        "storage": "/mnt/zurg/__magic__/__all__/Some.Show.S01E02.1080p.WEB-DL.H264-GRP",
        "path": "/mnt/zurg/__magic__/__all__/Some.Show.S01E02.1080p.WEB-DL.H264-GRP",
        "script_log": "",
        "script_line": "",
        "download_time": 120,
        "postproc_time": 3,
        "stage_log": [],
        "downloaded": 1073741824,
        "completeness": 100,
        "fail_message": "",
        "url_info": "",
        "bytes": 1073741824,
        "meta": null,
        "series": "",
        "md5sum": "",
        "password": "",
        "action_line": "",
        "size": "1.0 GB",
        "loaded": false,
        "retry": 0,
        "has_rating": false
      },
      {
        "id": 2,
        "completed": 1755833000,
        "name": "Some.Show.S01E03.1080p.WEB-DL.H264-GRP",
        "nzb_name": "Some.Show.S01E03.1080p.WEB-DL.H264-GRP.nzb",
        "category": "tv",
        "pp": "3",
        "script": "None",
        "report": "",
        "url": "",
        "status": "Failed",
        "nzo_id": "SABnzbd_nzo_ghi13579",
        "storage": "",
        "path": "",
        "script_log": "",
        "script_line": "",
        "download_time": 0,
        "postproc_time": 0,
        "stage_log": [],
        "downloaded": 0,
        "completeness": 0,
        "fail_message": "Article download failed, out of retention",
        "url_info": "",
        "bytes": 0,
        "meta": null,
        "series": "",
        "md5sum": "",
        "password": "",
        "action_line": "",
        "size": "0 B",
        "loaded": false,
        "retry": 0,
        "has_rating": false
      }
    ]
  }
}
```

Жёсткие требования:

- ключ верхнего уровня `history` (`SabnzbdProxy.cs:145`).
- `slots[].bytes` — это **BYTES** (число в JSON → `long`). Не отправляйте сюда MB: очередь использует MB, а история использует байты (`Sabnzbd.cs:72-73` против `:128`).
- `slots[].category` (а не `cat`).
- `slots[].storage` — это сама папка задания. Она становится `OutputPath`, а для элемента со статусом Completed именно её рекурсивно удаляет `DeleteItemData` (§5.3). Это должен быть абсолютный путь, корректный для ОС, на которой работает Sonarr/Radarr, и он должен существовать там (`RemotePathMappingCheck`, §6.2).
- `slots[].status` пишется точно, с учётом регистра. Элементы `Deleted` полностью отбрасываются (`Sabnzbd.cs:116-119`).
- `fail_message`, равный ровно `"Unpacking failed, write error or disk is full?"`, понижает элемент Failed до `Warning` вместо `Failed` (`Sabnzbd.cs:140-144`). Для настоящей ошибки используйте что-то другое.
- Radarr: `category` должен быть `movies` (или то, что вы настроили), а `name` должен парситься как фильм.

### 8.7 Ответ с ошибкой (для любого mode) {#87-error-response-any-mode}

```json
{
  "status": false,
  "error": "API Key Incorrect"
}
```

**HTTP 200.** `status` может быть логическим `false` или строкой `"false"`; оба варианта подходят под `SabnzbdJsonError.Failed` (`SabnzbdJsonError.cs:10-11`). Клиент выбрасывает `DownloadClientException("Error response received from SABnzbd: API Key Incorrect")` (`SabnzbdProxy.cs:244`), который распознаёт `TestAuthentication` (`Sabnzbd.cs:424`). Если ключ не передан, используется `"API Key Required"` (`Sabnzbd.cs:429`). Любая другая строка `error` выводится как есть, но не классифицируется.

---

## 9. Чеклист реализации (12 пунктов) {#9-implementation-checklist-12-points}

1. Один маршрут: `GET|POST {UrlBase}/api`, диспетчеризация по `mode`. **Всегда HTTP 200, всегда JSON.**
2. Реализуйте `version`, `get_config`, `queue` (чтение + `name=delete`), `history` (чтение + `name=delete`), `addfile`, `fullstatus`. Необязательно `retry` (сейчас это мёртвый код). `get_cats` никогда не вызывается.
3. Принимайте авторизацию либо через `apikey=`, **либо** через `ma_username=`+`ma_password=`. Отклоняйте с 200 + `{"status":false,"error":"API Key Incorrect"}` / `"API Key Required"`, но никогда не с 401/403.
4. Учитывайте `category=` в `queue`/`history` (клиенты ещё и фильтруют на своей стороне по точному совпадению строки, `Sabnzbd.cs:190`).
5. Размеры в `queue` указываются в **MB** (`mb`, `mbleft`), а в `history` в **BYTES** (`bytes`). Никогда их не путайте. В queue используется `cat`, в history используется `category`.
6. `timeleft` всегда в формате `h:m:s` или `d:h:m:s`, никогда не пустой и не отсутствующий в виде пустой строки. Нигде не парсится поле даты, так что поля с эпохой могут быть в любом формате.
7. Значения `status` должны браться из списка `SabnzbdDownloadStatus` из 16 элементов, с точным регистром (неизвестное имя выбросит исключение и уронит весь вызов queue/history). `priority` должен быть именем из `SabnzbdPriority` (с точным регистром) или его целым числом; **никогда `null`** (NRE в конвертере).
8. `config.misc` должен быть объектом; у каждой категории должно быть **непустое строковое поле `dir`**, которое не заканчивается на `*`. `categories`/`sorters`/`servers` могут быть null или отсутствовать, а `misc` и `dir` — нет.
9. Держите `enable_tv_sorting`, `enable_movie_sorting`, `enable_date_sorting` и `pre_check` все в `false`, а `history_retention_option: "all"`, чтобы тест подключения и все проверки состояния проходили чисто.
10. `storage` у завершённого слота в history — это папка задания. Ожидайте, что *arr выполнит `rm -rf` для неё после успешного импорта (настройки по умолчанию), и что медиафайл сначала будет **перемещён** из неё. Если magic-директория только для чтения, удаление тихо провалится (только предупреждение в логе), но *перемещение* импортируемого файла должно пройти успешно, иначе импорт полностью провалится (§5.5).
11. Не размещайте корневые папки *arr по пути `/mnt/zurg/__magic__/__all__` или выше, если хотите, чтобы `DownloadClientRootFolderCheck` в Radarr молчал (Sonarr смотрит только на точное совпадение). Размещайте их рядом с зеркалом — `/mnt/zurg/__magic__/tv`, `/mnt/zurg/__magic__/movies`, то есть вне выходной папки, а не выше или ниже неё.
12. `/mnt/zurg/__magic__/__all__` должна существовать как директория **на хосте Sonarr/Radarr**, а не только там, где работает эмулятор, иначе `RemotePathMappingCheck` выдаст ошибку. Ей не обязательно быть доступной для записи.

## Настройка большего окна завершения {#configuring-a-larger-completion-window}

Оба клиента по умолчанию используют `DownloadClientHistoryLimit` равным 60. Когда zurg сохраняет завершённые лишние задания в `queue`, он повторяет это окно. Если поднять только лимит клиента, некоторые задания попадут и в очередь, и в историю, и тогда приоритет будет у очереди.

При большом бэклоге задайте `sabnzbd.history_limit` в zurg и `DownloadClientHistoryLimit` в клиентах одинаковым, например 500. Так за один опрос будет видно больше завершённых и неудачных заданий. Если несколько клиентов используют разные значения, оставьте в zurg самое маленькое из лимитов клиентов. Этот расширенный параметр клиента не отображается в ресурсе конфигурации клиента загрузки Sonarr v4 API. Перед правкой сохранённой конфигурации клиента сделайте резервную копию и остановите клиент.

```yaml
sabnzbd:
  enabled: true
  history_limit: 500
```

По умолчанию остаётся 60; нулевое и отрицательное значение тоже означает значение по умолчанию. Диагностический запрос истории с другим лимитом никогда не меняет настроенное окно. Предупреждения о том, что клиент не может обработать задание, всё равно нужно проверять. Большее окно позволит другим заданиям дойти до импорта, пока эти предупреждения занимают места в истории.

Проверка доступности перед завершением берёт первые шестнадцать статей и последнюю статью каждого файла с содержимым. Так ловится пропавшая статья в заголовке медиафайла, которую не замечала прежняя проверка только по первой статье. Для каждого файла с содержимым загружается первая статья, чтобы проверить идентичность статьи и то, что тело всё ещё отдаётся сервером (провайдер может ответить на STAT для статьи, тело которой он уже удалил). Если в релизе файлов меньше шестнадцати, добираются случайно выбранные статьи, до шестнадцати тел на релиз. Всего загружается не больше шестидесяти четырёх тел; тело, которое уже есть в кэше статей, повторно не запрашивается. Остальная часть выборки проверяется через STAT. Это не проверяет каждую статью и не доказывает, что медиафайл декодируется.

Запросы STAT группируются по файлам, поэтому выборка тратит одно резервирование соединения из пула вместо семнадцати. Лимит соединений аккаунта при этом не повышается. Если пакет не удался, проверка переходит к отдельным запросам STAT.

Ошибки сервера оставляют задание в очереди на повтор. Подтверждённо отсутствующие статьи приводят к неудачной загрузке до первого уведомления о завершении.
