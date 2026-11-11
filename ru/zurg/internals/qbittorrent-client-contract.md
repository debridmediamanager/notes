# Контракт Web API qBittorrent, который используют Sonarr и Radarr (develop) {#qbittorrent-web-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Источник истины: файлы, загруженные с `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...`
и с `qbittorrent/qBittorrent/master` на **2026-08-27**. Каждый номер строки ниже взят из
этих файлов.

Это торрент-аналог [контракта клиента sabnzbd](sabnzbd-client-contract.md). Там описано, почему `internal/sabnzbd` отвечает именно так, как отвечает; этот документ — спецификация, которой должен соответствовать shim для qBittorrent *до* того, как его начнут писать. Так grab, опрос, импорт **с перемещением** и очистка после импорта будут работать в обоих клиентах. Там, где клиенты используют общие механизмы (HTTP-слой, JSON-сериализатор, `DiskTransferService`, проверки работоспособности), этот документ ссылается на те же строки и отсылает к ним, а не повторяет анализ.

Если в разделе не сказано иное, **файлы qBittorrent в двух репозиториях идентичны, за исключением переименования `Tv*` → `Movie*`**, и:

| File | Line numbers |
|---|---|
| `QBittorrent.cs` (746 lines in both) | **совпадают построчно** |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **побайтово идентичны**, совпадают построчно |
| `QBittorrentSettings.cs` (91 lines in both) | совпадают построчно |
| `QBittorrentProxyV2.cs`, `QBittorrentProxyV1.cs` | В Sonarr есть пустая строка на 13-й позиции, которой нет в Radarr (проверено: Sonarr `:12` — это комментарий `// API https://…`, `:13` — пустая строка, `:14` — `public class QBittorrentProxyV2`; объявление класса в Radarr — `:13`). **Строка N в Sonarr = строка N−1 в Radarr для N ≥ 14.** |
| `QBittorrentProxySelector.cs` | то же самое, начиная со строки 3 |
| `QBittorrentFixture.cs` | переупорядочен, а не сдвинут — ссылки приведены для каждого репозитория отдельно |

Пути имеют вид `src/NzbDrone.Core/Download/Clients/QBittorrent/...` в обоих репозиториях. Ссылки ниже — это номера строк **Sonarr**, если не отмечено иное. Полный diff — в §9.

Здесь нет домыслов о самом qBittorrent: каждое утверждение описывает то, что делает *клиент*. Если утверждение касается поведения самого qBittorrent, оно ссылается на `qbittorrent/qBittorrent` master; если речь идёт о поведении среды выполнения .NET или Newtonsoft, об этом сказано прямо.

---

## 0. Правила уровня транспорта (их нужно знать в первую очередь) {#0-transport-level-rules-these-bite-first}

### 0.1 Клиент выбирает v1 или v2 до того, как делает что-либо ещё {#01-the-client-picks-v1-or-v2-before-it-does-anything-else}

`QBittorrentProxySelector.FetchProxy` (`QBittorrentProxySelector.cs:80-95`):

```csharp
if (_proxyV2.IsApiSupported(settings)) { return Tuple.Create(_proxyV2, _proxyV2.GetApiVersion(settings)); }
if (_proxyV1.IsApiSupported(settings)) { return Tuple.Create(_proxyV1, _proxyV1.GetApiVersion(settings)); }
throw new DownloadClientException("Unable to determine qBittorrent API version");
```

`QBittorrentProxyV2.IsApiSupported` (`QBittorrentProxyV2.cs:28-70`) делает **неаутентифицированный**
запрос `GET /api/v2/app/webapiVersion` с `SuppressHttpError = true` и решает так:

| Ответ | Результат |
|---|---|
| `404` | не v2 → переход к v1 |
| `403` | **v2 поддерживается** (`:44-47`) — это ответ «ещё не залогинен» |
| `401` | `DownloadClientException("Failed to connect to qBittorrent. Check your settings and qBittorrent configuration.")` (`:49-52`) |
| любой другой `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` (`:54-57`) |
| `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to qBittorrent, certificate validation failed.")` (`:63-66`) |
| `200` | v2 поддерживается |

`QBittorrentProxyV1.IsApiSupported` (`QBittorrentProxyV1.cs:27-59`) делает то же самое, но для
`GET /version/api` — обрати внимание, **без ведущего `/api/v2`**, и 401 там отдельно не обрабатывается.

Пара `(proxy, version)` кэшируется на **10 минут** по ключу `{Host}_{Port}`
(`QBittorrentProxySelector.cs:68-78`). `GetProxy(settings, force: true)` сбрасывает этот кэш; тест подключения
делает именно это (`QBittorrent.cs:435`, `:519`), и это проверяет фикстура (Sonarr `QBittorrentFixture.cs:986-998`, Radarr `:984-996`).

**Шим должен отвечать на `/api/v2/app/webapiVersion` и никогда не выставлять маршруты v1.** v1 — это API до 4.1
(`/version/api`, `/query/torrents`, `/command/download`, …). Для нового решения это балласт, и он вообще не может
обслужить путь импорта: `GetLabels` выбрасывает `NotSupportedException("qBittorrent api v1 does not support getting all torrent categories")`
(`QBittorrentProxyV1.cs:236-239`), а `SetTorrentSeedingConfiguration` ничего не делает (`:241-244`).
Остальной документ описывает только API v2; карта маршрутов v1 приведена в §1.17 для полноты картины.

### 0.2 Форма URL {#02-url-shape}

`QBittorrentProxyV2.BuildRequest` (`QBittorrentProxyV2.cs:341-359`):

```csharp
var requestBuilder = new HttpRequestBuilder(settings.UseSsl, settings.Host, settings.Port, settings.UrlBase)
{
    LogResponseContent = true,
    StoreRequestCookie = false
};
```

- Базовый URL: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-65`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; если у `UrlBase` нет ведущего `/`, он добавляется.
- `Resource("/api/v2/…")` (`HttpRequestBuilder.cs:244-256`) убирает ведущий `/` и дописывает путь, так что полный URL выглядит так: `{scheme}://{host}:{port}{urlBase}/api/v2/{group}/{method}`.
- **Заголовка `Accept` нет.** `BuildRequest` никогда не вызывает `.Accept(...)`, а конструктор `HttpRequest` задаёт `Headers.Accept` только если `httpAccept != null` (`src/NzbDrone.Common/Http/HttpRequest.cs:14,30-32`). Не завязывайся на `Accept`.
- `StoreRequestCookie = false`: хранилищем cookie управляет прокси, а не HTTP-слой.

(Предыдущий перевод был отклонён: фрагменты кода не совпали. Сохрани структуру в точности.)

### 0.3 GET с query или POST с form — и когда form становится multipart {#03-get-with-query-vs-post-with-form--and-when-the-form-becomes-multipart}

Запросы только для чтения используют `AddQueryParam` (`HttpRequestBuilder.cs:306-317`) с GET. Запросы, которые что-то меняют, используют
`.Post()` плюс `AddFormParameter` / `AddFormUpload`.

`ApplyFormData` (`HttpRequestBuilder.cs:150-242`) выбирает кодировку:

```csharp
var shouldSendAsMultipart = FormData.Any(v => v.ContentType != null || v.FileName != null || v.ContentData.Length > 1024);
```

- Любой `AddFormUpload` (который задаёт `FileName` и `ContentType`) включает **`multipart/form-data`**
  (`:379-395`, `:220`).
- **Любое отдельное значение формы длиннее 1024 байт тоже включает multipart** (`:162`). Magnet-ссылка с длинным списком трекеров переходит эту границу, поэтому `POST /api/v2/torrents/add` приходит либо как `application/x-www-form-urlencoded`, *либо* как `multipart/form-data`, в зависимости от magnet-ссылки. **Шим должен разбирать оба формата на этом маршруте.**
- Во всех остальных случаях: `application/x-www-form-urlencoded`, значения экранируются через
  `Uri.EscapeDataString(Encoding.UTF8.GetString(...))` (`:230`).

Писатель multipart написан вручную (`:164-227`) и пишет `Content-Disposition: form-data; name="…"` (плюс `; filename="…"` и строку `Content-Type:` для загрузок), пустую строку, сырые байты, затем `\r\n`. Граница — `-----------------------------{ticks:x14}` (`:166`).

**Форматирование булевых значений — ловушка.** `AddFormParameter` сохраняет `Convert.ToString(value, CultureInfo.InvariantCulture)` (`HttpRequestBuilder.cs:373`), а `Convert.ToString(bool)` в .NET даёт **`"True"` / `"False"` с заглавной буквы**. Так что `request.AddFormParameter("stopped", false)` (`QBittorrentProxyV2.cs:258`) отправляет в сеть `stopped=False`, а не `stopped=false`. Настоящий qBittorrent с этим справляется, потому что `Utils::String::parseBool` (`src/base/utils/string.cpp:108-116`) сравнивает без учёта регистра. **Шим должен принимать и `True`/`False`, и `true`/`false`.** Там, где клиент прописывает строку жёстко, она в нижнем регистре — `deleteFiles` равен `"true"` (`QBittorrentProxyV2.cs:198`), а `value` в `setForceStart` равен `"true"`/`"false"` (`:337`) — поэтому оба написания действительно встречаются.

Числа проходят через тот же путь с инвариантной культурой, поэтому `ratioLimit=1.5` всегда использует `.` как разделитель дробной части (`QBittorrentProxyV2.cs:234`, `HttpRequestBuilder.cs:373`).

### 0.4 Аутентификация — три уровня, и все они могут быть включены одновременно {#04-authentication--three-layers-all-of-which-can-be-live-at-once}

`BuildRequest` (`QBittorrentProxyV2.cs:349-356`):

```csharp
if (settings.ApiKey.IsNotNullOrWhiteSpace())
    requestBuilder.Headers["Authorization"] = $"Bearer {settings.ApiKey}";
else if (settings.Username.IsNotNullOrWhiteSpace() || settings.Password.IsNotNullOrWhiteSpace())
    requestBuilder.NetworkCredential = new BasicNetworkCredential(settings.Username, settings.Password);
```

1. **API key** → `Authorization: Bearer <key>` в каждом запросе, а `ProcessRequest` использует короткий путь, который вообще не логинится (`:371-395`). `QBittorrentSettingsValidator` не даёт задать username/password вместе с ключом (`QBittorrentSettings.cs:16-21`).
2. **Username/password** → `BasicNetworkCredential`, который `ManagedHttpDispatcher` превращает в **предварительный** заголовок `Authorization: Basic base64(user:pass)` в *каждом* запросе, включая сам `auth/login` (`src/NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:81-89`, комментарий: "Manually set header to avoid initial challenge response").
3. **Cookie session** → `AuthenticateClient` (`QBittorrentProxyV2.cs:430-494`).

`AuthenticateClient`, дословно:

```csharp
if (settings.Username.IsNullOrWhiteSpace() || settings.Password.IsNullOrWhiteSpace())
{
    if (reauthenticate) { throw new DownloadClientAuthenticationException("Failed to authenticate with qBittorrent."); }
    return;                                                             // :432-440
}

var authKey = $"{requestBuilder.BaseUrl}:{settings.Username}:{settings.Password}";   // :442
var cookies = _authCookieCache.Find(authKey);

if (cookies == null || reauthenticate)
{
    _authCookieCache.Remove(authKey);
    var authLoginRequest = BuildRequest(settings).Resource("/api/v2/auth/login")
        .Post()
        .AddFormParameter("username", settings.Username ?? string.Empty)
        .AddFormParameter("password", settings.Password ?? string.Empty)
        .Build();                                                       // :450-456
    ...
    if (response.Content.IsNotNullOrWhiteSpace() && response.Content != "Ok.")
    {
        // returns "Fails." on bad login
        throw new DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.");   // :479-484
    }
    cookies = response.GetCookies();                                    // :488
    _authCookieCache.Set(authKey, cookies);
}
requestBuilder.SetCookies(cookies);                                     // :493
```

Что это значит для шима:

- `POST /api/v2/auth/login`, тело `username=…&password=…`, `application/x-www-form-urlencoded`.
- Отвечай **HTTP 200** с телом ровно `Ok.` и заголовком `Set-Cookie: SID=…`. Так ведёт себя настоящий qBittorrent (вики, *Login*: "Upon success, the response will contain a cookie with your SID", то есть при успехе ответ содержит cookie с твоим SID).
- **Пустое тело тоже принимается** (`:479` выходит раньше из-за `IsNotNullOrWhiteSpace`). Всё остальное, например `"Fails."`, `"ok"` или JSON, считается ошибкой аутентификации. v1-прокси строже и требует ровно `Ok.` (`QBittorrentProxyV1.cs:371`).
- При HTTP-ошибке от `auth/login`: 401 или 403 → `DownloadClientAuthenticationException`, всё остальное → `DownloadClientException` (`:463-473`). `WebException` → `DownloadClientUnavailableException`.
- Cookie кэшируется по ключу `{baseUrl}:{user}:{pass}` на время жизни записи кэша процесса и обновляется только тогда, когда запрос вернул 403 (§0.5).
- **`Referer` и `Origin` никогда не отправляются.** Вики советует API-клиентам их задавать ("Note: Set `Referer` or `Origin` header to the exact same domain and port as used in the HTTP query `Host` header"), но Sonarr этого не делает. Шим не должен их требовать.
- Если **никакие учётные данные не заданы**, `AuthenticateClient` сразу возвращается и ничего не отправляет: ни логина, ни cookie, ни `Authorization`. Шим без авторизации работает.

### 0.5 Какие HTTP-статусы считаются ошибками {#05-which-http-statuses-are-treated-as-errors}

`HttpClient.Execute` (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`) выбрасывает исключение, когда
`response.HasHttpError` — `(int)StatusCode >= 400` (`src/NzbDrone.Common/Http/HttpResponse.cs:54`) —
если только не задано `SuppressHttpError` или статус не входит в `SuppressHttpErrorStatusCodes`. 429 превращается в
`TooManyRequestsException` (`:115`); всё остальное — в `HttpException` (`:119`).

`QBittorrentProxyV2.ProcessRequest` (`:369-428`) потом оборачивает это. Есть два разных пути:

**Путь с API-ключом** (`:371-395`):

| Статус | Результат |
|---|---|
| 401, 403 | `DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.")` |
| любой другой `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` |
| любое другое исключение | `DownloadClientException("Failed to connect to qBittorrent, please check your settings.")` |

**Путь с cookie** (`:397-427`):

```csharp
AuthenticateClient(requestBuilder, settings);
var request = requestBuilder.Build();
request.LogResponseContent = true;
request.SuppressHttpErrorStatusCodes = new[] { HttpStatusCode.Forbidden };   // :401

var response = _httpClient.Execute(request);
if (response.StatusCode == HttpStatusCode.Forbidden)                          // :407
{
    AuthenticateClient(requestBuilder, settings, true);                       // :411  re-login
    request = requestBuilder.Build();                                         // :413
    response = _httpClient.Execute(request);                                  // :415
}
return response.Content;
```

- **403 означает «сессия истекла, войди заново»** — один раз его подавляют, клиент заново логинится и
  повторяет запрос. Это тот самый цикл, который создаёт истечение сессии у самого qBittorrent, и shim может
  использовать его так же.
- **Повторный запрос строится заново из builder**, а в builder нет `SuppressHttpErrorStatusCodes` — это поле
  задаётся на *запросе* в `:401`, а не на builder. Поэтому второй 403 выбрасывает `HttpException` и
  превращается в `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` — **а не**
  в ошибку аутентификации. Shim, который всегда отвечает 403, даёт в интерфейсе запутанную ошибку подключения,
  а не «Authentication Failure».
- Если учётные данные не настроены, попытка повторного логина в `:411` сразу выбрасывает
  `DownloadClientAuthenticationException` (`:434-437`).

**Каждый успешный вызов должен возвращать HTTP 200 с точно тем телом, которое ожидает клиент.** В этом API
нигде нет JSON-обёртки для ошибок; в отличие от SAB, здесь ошибки передаются HTTP-статусами.

### 0.6 Настройки десериализатора {#06-deserializer-settings}

Все payload-ы qBittorrent проходят через `NzbDrone.Common.Serializer.Json`
(`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`), то есть через **Newtonsoft**, тот же экземпляр, что использует клиент SAB. Поэтому [sabnzbd-client-contract.md §0.3](sabnzbd-client-contract.md) применяется без изменений:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Что это значит конкретно для моделей qBittorrent:

| Член модели | Привязывается к | Почему |
|---|---|---|
| `QBittorrentTorrent.Hash/Name/Size/Progress/Eta/State/Label/Category/Ratio` | `hash`, `name`, `size`, `progress`, `eta`, `state`, `label`, `category`, `ratio` | резолвер camelCase; Newtonsoft также сопоставляет без учёта регистра |
| `SavePath`, `ContentPath`, `RatioLimit`, `SeedingTime`, `SeedingTimeLimit`, `InactiveSeedingTimeLimit`, `LastActivity` | `save_path`, `content_path`, `ratio_limit`, `seeding_time`, `seeding_time_limit`, `inactive_seeding_time_limit`, `last_activity` | явный `[JsonProperty]` (`QBittorrentTorrent.cs:24-45`) |
| `QBittorrentLabel.Name/SavePath` | `name`, `savePath` | **без** `[JsonProperty]` — резолвер camelCase. В `torrents/categories` qBittorrent действительно использует camelCase, в отличие от всего остального |
| `QBittorrentPreferences.*` | все явные `[JsonProperty]` в snake_case (`QBittorrentPreferences.cs:16-44`) | |
| `QBittorrentMaxRatioAction` | `max_ratio_act` | конвертера на уровне свойства нет, поэтому действует глобальный `StringEnumConverter`. `AllowIntegerValues` по умолчанию true, поэтому **отправляйте целое число**, как это делает настоящий qBittorrent. Строка должна быть в camelCase (`"pause"`, `"remove"`), а неизвестное имя вызывает исключение |

`NullValueHandling.Ignore` действует и при **чтении**: JSON `null` оставляет член со значением из конструктора. С учётом значений по умолчанию, объявленных в моделях, **отсутствующее или null** поле — это не то же самое, что ноль:

| Поле | Значение по умолчанию, если отсутствует/null | Ссылка |
|---|---|---|
| `ratio_limit` | `-2f` | `QBittorrentTorrent.cs:33` |
| `seeding_time_limit` | `-2` | `:39` |
| `inactive_seeding_time_limit` | `-2` | `:42` |
| `seeding_time` | `null` (`long?`) | `:36` |
| `queueing_enabled` | **`true`** | `QBittorrentPreferences.cs:41` |
| всё остальное | значение CLR по умолчанию (`0`, `false`, `null`) | |

`Eta` — это `System.Numerics.BigInteger` (`QBittorrentTorrent.cs:17`, комментарий "QBit contains a bug exceeding ulong limits"); в фикстуре Sonarr зафиксировано, что `18446744073709335000` парсится (Sonarr `QBittorrentFixture.cs:974-984`, Radarr `:973-982`).

`Json.Deserialize<T>` перебрасывает `JsonReaderException` с более понятным сообщением (`Json.cs:39-50`). Ни один из вызовов прокси qBittorrent не использует `TryDeserialize`, поэтому **некорректное или не того вида тело ответа выбрасывает исключение из прокси** и становится необработанным исключением в месте вызова — для `GetItems()` это обрывает весь опрос.

### 0.7 Все проверки `version >=` в одном месте {#07-every-version--gate-in-one-place}

`ProxyApiVersion` — это `_proxySelector.GetApiVersion(Settings)` (`QBittorrent.cs:50`), то есть закешированное значение `app/webapiVersion`. Проверки:

| Порог | Где | Эффект ниже порога |
|---|---|---|
| `>= 1.5` | `QBittorrent.cs:436` | Тест не проходит: "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| `>= 1.6` | `:445` | Тест не проходит, если настроена категория: "Category is not supported" |
| `>= 2.0` | `:379` (`GetStatus`), `:520` (`TestCategory`) | Путь `savePath` категории не читается, а категории не проверяются и не создаются |
| `>= 2.6.1` | `:314` | `OutputPath` **не** берётся из `content_path`; вместо этого `GetImportItem` обходит `torrents/files` (§4.2) |
| `>= 2.8.1` | `:79`, `:136` | Лимиты раздачи нельзя передать через `torrents/add`; они применяются потом, через `torrents/setShareLimits` |
| `>= 2.11.0` | `QBittorrentProxyV2.cs:253` | `torrents/add` отправляет `paused=` вместо `stopped=` |

`Version.Parse` (`QBittorrentProxyV2.cs:75`) требует **как минимум `major.minor`**: голая строка `"2"` вызывает `FormatException`. Это исключение возникает вне всех `try` в прокси, поэтому оно полностью выходит из `GetApiVersion`. Сообщайте что-то вроде `2.11.2`.

**Рекомендуемое значение для шима: `2.11.2`.** Оно проходит все пороговые проверки, переводит `content_path` на путь `torrents/info` (единственный разумный маршрут импорта) и выбирает для add вариант `stopped=` из qBittorrent 5.x.

---

## 1. Все эндпоинты в порядке, в котором их вызывает клиент {#1-every-endpoint-in-the-order-the-client-calls-them}

Интерфейс: `IQBittorrentProxy` (`QBittorrentProxySelector.cs:9-30`). Реализация: `QBittorrentProxyV2`. Каждый вызов в `QBittorrent.cs` перечислен в `:49-741`.

### 1.1 `GET /api/v2/app/webapiVersion` — `GetApiVersion` (`QBittorrentProxyV2.cs:72-78`)

Запрос: без параметров. Сначала отправляется без авторизации (как проба прокси, §0.1), затем с авторизацией.

Ответ: **обычный текст**, строка с версией, которую разбирает `Version.Parse`. Не JSON, без кавычек.

Вызывается из: проба прокси (`:31`), `GetItems` (`QBittorrent.cs:220`), `GetStatus` (`:374`), `TestConnection` (`:435`), `TestCategory` (`:519`) и, что легко пропустить, `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:253`). Это значит, что **перед каждым `torrents/add` выполняется отдельный обмен с `app/webapiVersion`**, если начальное состояние Start или Stop (то есть почти всегда, кроме случая, когда пользователь выбрал Force Start).

### 1.2 `GET /api/v2/app/version` — `GetVersion` (`QBittorrentProxyV2.cs:80-87`)

Ответ: обычный текст, `v` убирается из начала (`:83`). Комментарий: `// eg "4.2alpha"`.

**Никогда не вызывается.** Он есть в интерфейсе (`QBittorrentProxySelector.cs:13`), но нигде в `QBittorrent.cs` не вызывается (проверено по всем ссылкам `Proxy.`/`_proxySelector.` в `:49-741`). Реализуй его всё равно: это ничего не стоит, а человек, который будет копаться в шиме, точно до него дотянется.

### 1.3 `POST /api/v2/auth/login`

Описано в §0.4. Форма: `username`, `password`. Ответ `200` + `Ok.` + `Set-Cookie: SID=…`.

### 1.4 `GET /api/v2/app/preferences` — `GetConfig` (`QBittorrentProxyV2.cs:89-95`)

Запрос: без параметров. Ответ: один JSON-объект, десериализуемый в `QBittorrentPreferences`.

**Каждый ключ, который читает клиент** (`QBittorrentPreferences.cs:14-45`). Остальное содержимое тела не смотрится, а лишние ключи игнорируются:

| Ключ JSON | C# | Тип | Где читается |
|---|---|---|---|
| `save_path` | `SavePath` | `string` | `GetStatus` → `OutputRootFolders` (`QBittorrent.cs:377`) |
| `max_ratio_enabled` | `MaxRatioEnabled` | `bool` | `HasReachedSeedLimit` (`:639`), `RemovesCompletedDownloads` (`:415`) |
| `max_ratio` | `MaxRatio` | `float` | `HasReachedSeedLimit` (`:641`) |
| `max_seeding_time_enabled` | `MaxSeedingTimeEnabled` | `bool` | `HasReachedSeedingTimeLimit` (`:663`), `RemovesCompletedDownloads` (`:415`) |
| `max_seeding_time` | `MaxSeedingTime` | `long`, **в минутах** | `:665`, `:415` |
| `max_inactive_seeding_time_enabled` | `MaxInactiveSeedingTimeEnabled` | `bool` | `HasReachedInactiveSeedingTimeLimit` (`:727`) |
| `max_inactive_seeding_time` | `MaxInactiveSeedingTime` | `long`, **в минутах** | `:729` |
| `max_ratio_act` | `MaxRatioAction` | enum как int: `Pause=0, Remove=1, EnableSuperSeeding=2, DeleteFiles=3` (`QBittorrentPreferences.cs:5-11`) | `RemovesCompletedDownloads` (`:415`) |
| `queueing_enabled` | `QueueingEnabled` | `bool`, **по умолчанию `true`** | `TestPrioritySupport` (`:572`) |
| `dht` | `DhtEnabled` | `bool` | `AddFromMagnetLink` (`:73`), ветка `metaDL` (`:288`) |

Вызывается из: `AddFromMagnetLink` (`:73`), `GetItems` (`:221`), `GetStatus` (`:375`), `TestConnection` (`:467`), `TestPrioritySupport` (`:570`). Результат **не кешируется**, поэтому запрашивается при каждом опросе.

`RemovesCompletedDownloads` (`QBittorrent.cs:412-416`) — это производный флаг:

```csharp
var minimumRetention = 60 * 24 * 14; // 14 days in minutes
return (config.MaxRatioEnabled || (config.MaxSeedingTimeEnabled && config.MaxSeedingTime < minimumRetention))
    && (config.MaxRatioAction == QBittorrentMaxRatioAction.Remove || config.MaxRatioAction == QBittorrentMaxRatioAction.DeleteFiles);
```

Он используется и в проверке подключения (`:468`), и в health check `DownloadClientRemovesCompletedDownloadsCheck` (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:44-53`). При `max_ratio_enabled: false` и `max_seeding_time_enabled: false` он будет false, каким бы ни было значение `max_ratio_act`, но всё равно отправляйте `max_ratio_act: 0`.

### 1.5 `GET /api/v2/torrents/categories` — `GetLabels` (`QBittorrentProxyV2.cs:221-225`)

Запрос: без параметров.

Ответ: JSON-**объект** `{"<name>": {"name": "...", "savePath": "..."}}`, который десериализуется в `Dictionary<string, QBittorrentLabel>`. Обрати внимание на **camelCase `savePath`**, см. §0.6 и пример *Get all categories* в вики. Массив здесь вызовет исключение.

Посмотри на две вещи:

1. `TestCategory` (`QBittorrent.cs:525-553`): только наличие ключа (§6.3).
2. `GetStatus` (`:379-402`): `savePath` настроенной категории становится корневой папкой вывода для клиента загрузки (download client):

```csharp
if (Proxy.GetLabels(Settings).TryGetValue(Settings.TvCategory, out var label) && label.SavePath.IsNotNullOrWhiteSpace())
{
    var savePath = label.SavePath;
    if (savePath.StartsWith("//"))                       // :385  treated as a Windows UNC path
    {
        savePath = savePath.Replace('/', '\\');          // :388
    }
    var labelDir = new OsPath(savePath);
    destDir = labelDir.IsRooted ? labelDir : destDir + labelDir;   // :393-400
}
```

**Относительный** `savePath` добавляется к глобальному `save_path`, а абсолютный (с корнем) его заменяет. `savePath`, который начинается с `//`, превращается в UNC-путь с обратными слэшами. Фикстура Sonarr фиксирует `"//server/store/downloads"` → `\\server\store\downloads` (Sonarr `QBittorrentFixture.cs:563-589`, Radarr `:562-588`). **Никогда не выдавай ведущий `//`.**

Самый простой правильный ответ: `"savePath": ""`. Тогда корневая папка остаётся глобальным `save_path`.

### 1.6 `POST /api/v2/torrents/createCategory` — `AddLabel` (`QBittorrentProxyV2.cs:213-219`)

Форма: `category=<name>`. **`savePath` не отправляется** — клиент никогда не задаёт путь сохранения для категории.
Тело ответа игнорируется; важен только статус без ошибки.

Вызывается только из `TestCategory` (`QBittorrent.cs:529`, `:543`), когда категории нет.
`torrents/editCategory` и `torrents/removeCategories` **никогда не вызываются**.

### 1.7 `POST /api/v2/torrents/add` — `AddTorrentFromUrl` / `AddTorrentFromFile`

`AddTorrentFromUrl` (`QBittorrentProxyV2.cs:146-166`): поле формы **`urls`** = magnet-URI.
`AddTorrentFromFile` (`:168-188`): загрузка формы **`torrents`**, имя файла
`{CleanFileName(release title)}.torrent` (`TorrentClientBase.cs:199`),
`Content-Type: application/octet-stream` (`HttpRequestBuilder.cs:379`).

Оба затем добавляют `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:243-284`):

| Поле формы | Значение | Условие | Строка |
|---|---|---|---|
| `category` | `Settings.TvCategory` / `MovieCategory` | категория не пустая | `:245-248` |
| `stopped` (webapi `>= 2.11.0`) или `paused` (ниже) | `False` для Start, `True` для Stop | `InitialState` равен Start или Stop — **Force Start не отправляет ни то, ни другое** | `:251-264` |
| `sequentialDownload` | `True` | настройка `SequentialOrder` включена | `:266-269` |
| `firstLastPiecePrio` | `True` | настройка `FirstAndLast` включена | `:271-274` |
| `contentLayout` | `"Original"` или `"Subfolder"` | настройка `ContentLayout` равна Original или Subfolder; **Default ничего не отправляет** | `:276-283` |

а также, если заданы лимиты раздачи *и* webapi `>= 2.8.1` (`QBittorrent.cs:79`, `:136`), добавляется `AddTorrentSeedingFormParameters(request, seedConfiguration)` (`QBittorrentProxyV2.cs:227-241`):

| Поле формы | Значение | Условие |
|---|---|---|
| `ratioLimit` | `seedConfiguration.Ratio` или `-2` | только если не `-2` (`:232`) |
| `seedingTimeLimit` | `seedConfiguration.SeedTime.TotalMinutes` или `-2` | только если не `-2` (`:237`) |

**Всё остальное, что вики описывает для `torrents/add`, никогда не отправляется**: ни `savepath`, ни `cookie`, ни `tags`, ни `skip_checking`, ни `root_folder`, ни `rename`, ни `upLimit`, ни `dlLimit`, ни `autoTMM`. У add нет параметра `priority` — приоритет в очереди задаётся отдельным вызовом `topPrio` (§1.10).

Обработка ответа (`:159-165`, `:181-187`):

```csharp
var result = ProcessRequest(request, settings);
// Note: Older qbit versions returned nothing, so we can't do != "Ok." here.
if (result == "Fails.") { throw new DownloadClientException("Download client failed to add torrent by url"); }
```

Итак: **ответ 200 с любым телом, кроме буквального `Fails.`, — это успех.** `Ok.` — обычный ответ.
HTTP 415 (в вики: "torrent file is not valid") превращается в `DownloadClientException` через `:389`.

**ID загрузки не приходит из этого вызова.** Он вычисляется на стороне клиента, до запроса:

- magnet → `MagnetLink.Parse(magnetUrl).InfoHash.ToHex()` (`TorrentClientBase.cs:224`)
- `.torrent` → `_torrentFileInfoReader.GetHashFromTorrentFile(torrentFile)` (`:200`)

а `AddFromMagnetLink` / `AddFromTorrentFile` возвращают тот же `hash` без изменений (`QBittorrent.cs:130`, `:187`). **Шим должен привязывать торрент именно к этому infohash**, иначе Sonarr теряет захват релиза — `TorrentClientBase.cs:206-212` и `:238-244` лишь пишут строку Debug-лога об этом.
Для магнет-ссылок сначала проверяется предусловие DHT:

```csharp
if (!Proxy.GetConfig(Settings).DhtEnabled && !magnetLink.Contains("&tr="))
    throw new NotSupportedException("Magnet Links without trackers not supported if DHT is disabled");   // :73-76
```

Вызывающий код превращает это в `ReleaseDownloadException("Magnet not supported by download client…")`, если нет запасного варианта `.torrent` (`TorrentClientBase.cs:111-119`). **Сообщайте `dht: true`.**

После добавления `WaitForTorrent` (`QBittorrent.cs:190-214`) опрашивает `IsTorrentLoaded` **10 раз с паузой 100 мс** — но только если есть дополнительные действия (лимиты раздачи после добавления, верхний приоритет или force start; `:86`, `:143`). В его сообщении об ошибке сказано "within 500 ms", но цикл на самом деле 10 × 100 мс; в любом случае он сдаётся и возвращает hash (`:212-213`).

### 1.7a Сколько клиент ждёт ответа на `torrents/add` — **100 секунд**, измерено 2026-08-30 {#17a-how-long-the-client-waits-for-torrentsadd--100-seconds-measured-2026-08-30}

Прочитано из `Sonarr/Sonarr@32a5d492` и `Radarr/Radarr@40bb746c` (обе ветки `develop`) на 2026-08-30. Это задаёт верхнюю границу всего, что shim делает синхронно внутри вызова add, поэтому стоит опираться на эти ссылки, а не на предположения.

На пути qBittorrent никакой таймаут не задаётся, поэтому значение проходит через четыре слоя и в итоге получается ровно 100 с:

| Шаг | Sonarr `path:line` | Radarr `path:line` | Что делает |
|---|---|---|---|
| сам вызов add | `QBittorrentProxyV2.cs:146-150`, `:168-172` | `:145-149`, `:167-171` | формирует запрос, таймаут не задаёт |
| builder | `NzbDrone.Common/Http/HttpRequestBuilder.cs:104-116` | тот же файл `:104-116` | в `Apply()` нет строки `RequestTimeout`, и такого свойства в классе нет |
| значение по умолчанию | `NzbDrone.Common/Http/HttpRequest.cs:52` | `:54` | авто-свойство никогда не присваивается в конструкторе, поэтому это `TimeSpan.Zero` |
| dispatcher | `NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:70-79` | `:68-77` | `Zero` превращается в `cts.CancelAfter(TimeSpan.FromSeconds(100))` |

```csharp
using var cts = new CancellationTokenSource();
if (request.RequestTimeout != TimeSpan.Zero) { cts.CancelAfter(request.RequestTimeout); }
else { /* The default for System.Net.Http.HttpClient */ cts.CancelAfter(TimeSpan.FromSeconds(100)); }
```

`RequestTimeout` и `Timeout` нигде не встречаются в `src/NzbDrone.Core/Download/Clients/QBittorrent/` ни в одном из репозиториев, а `HttpRequestBuilder` не даёт способа их задать. Значит, shim нельзя дать больше времени через конфигурацию.

Из этого следуют пять выводов.

- **100 с задаёт токен отмены Sonarr, а не таймер .NET.** Базовый обработчик создаётся с `Timeout = Timeout.InfiniteTimeSpan` (`ManagedHttpDispatcher.cs:183` в Sonarr, `:180` в Radarr), так что единственное ограничение здесь — токен. Он передаётся и в `SendAsync`, и в `ReadAsByteArrayAsync` (`:115`, `:127`), то есть покрывает подключение, тело запроса, заголовки ответа и тело ответа.
- **Таймаут пользователю показывается как ошибка соединения.** При истечении времени поднимается `new WebException("Http request timed out", …)` (`:142-145`), а `ProcessRequest` оборачивает его в `DownloadClientException("Failed to connect to qBittorrent, please check your settings.", ex)` (`QBittorrentProxyV2.cs:424-427`). Поэтому shim, который блокируется дольше 100 с, выглядит как неправильно настроенный, а не как медленный, и *arr никогда не узнаёт, что добавление ещё выполняется.
- **Отдельного таймаута на подключение нет, и для multipart-загрузки бюджет не увеличивается.** `SocketsHttpHandler.ConnectTimeout` не задаётся. Единственное исключение — ограничение в 2 с на первую попытку по IPv6 за всё время работы процесса (`ManagedHttpDispatcher.cs:23`, `:288-295`). После неё попытка переходит на IPv4, но всё равно укладывается в те же 100 с. Загрузка `.torrent` целиком буферизуется в байтовый массив (`HttpRequestBuilder.cs:220-221`, `ManagedHttpDispatcher.cs:103`) и отправляется под тем же токеном.
- **300 с есть, но это другой путь.** `HttpClient.cs:285` задаёт `request.RequestTimeout = TimeSpan.FromSeconds(300)` внутри `DownloadFileAsync`, который скачивает `.torrent` с индексатора. До вызовов клиента загрузки это значение не доходит.
- **Deluge показывает, что переопределить значение можно, а qBittorrent этим не пользуется.** `DelugeProxy.cs:222` делает `requestBuilder.PostProcess += r => r.RequestTimeout = TimeSpan.FromSeconds(15)`. В `BuildRequest` qBittorrent такой строки нет, и это прямое свидетельство того, что 100 с унаследованы, а не выбраны осознанно.

**Radarr устроен так же.** Сравнение блока таймаута (Radarr `:68-78` с Sonarr `:70-80`) даёт полностью совпадающий результат, а единственное различие в цепочке — Radarr передаёт в `WebException` `ex`, тогда как Sonarr передаёт `ex.InnerException`.

**Что это значит для shim.** Все синхронные решения, которые принимаются внутри `torrents/add`, делят один бюджет в 100 с, и *arr не может отличить «всё ещё работает» от «недоступен». Таймаут на одну попытку, умноженный на число опрашиваемых провайдеров, плюс окно проверки только по кешу должны оставаться заметно меньше этих 100 с. Измеренные задержки провайдеров, на которых строится этот бюджет, описаны в [жизненный цикл торрента](torrent-lifecycle.md).

Одно дополнение для полноты. 100 с действуют на каждый вызов dispatcher, поэтому каждый переход по цепочке автоматического редиректа получает новый бюджет (`HttpClient.cs:43` ограничивает цепочку пятью переходами). Стратегия повторов из `DownloadClientBase.cs:30-44` здесь **не** применяется: она используется только при загрузке `.torrent` с индексатора (`TorrentClientBase.cs:142-144`).

### 1.8 `GET /api/v2/torrents/properties?hash=<hash>` — `IsTorrentLoaded` / `GetTorrentProperties`

`IsTorrentLoaded` (`QBittorrentProxyV2.cs:110-126`) вызывает его с `LogHttpError = false` и считает **любое** исключение признаком того, что торрент не загружен.

`GetTorrentProperties` (`:128-135`) десериализует ответ в `QBittorrentTorrentProperties` (`QBittorrentTorrent.cs:48-57`). **Тут три поля, и используются только два:**

| Ключ JSON | C# | Используется для |
|---|---|---|
| `hash` | `Hash` | читается, но никогда не используется |
| `save_path` | `SavePath` | путь `GetImportItem` для версий до 2.6.1 (`QBittorrent.cs:354`) |
| `seeding_time` | `SeedingTime` (`long`, **секунды**) | `FetchTorrentDetails` (`:739-744`) |

**Регистр хешей здесь непоследователен, и это важно.** Все остальные вызовы приводят хеш к нижнему регистру (`item.DownloadId.ToLower()` в `:335`, `:346`, `:353`; `hash.ToLower()` в `:97`, `:109`, `:121`, `:198`), а `FetchTorrentDetails` передает `torrent.Hash` **как есть** (`:741`), то есть то, что шим вернул в `torrents/info`. Настоящий qBittorrent возвращает хеши в нижнем регистре, поэтому здесь проблем не бывает. Но фикстура Sonarr закрепляет эту несимметричность: она мокает `GetTorrentProperties("HASH", …)` с значением в верхнем регистре (Sonarr `QBittorrentFixture.cs:669-675`, Radarr `:668-674`). **Возвращайте хеши в нижнем регистре из `torrents/info` и сравнивайте `?hash=` без учета регистра.**

`FetchTorrentDetails` вызывается только из `HasReachedSeedingTimeLimit` (`:700`), а тот дергается, только когда реально действует лимит времени раздачи. Значит, шим, который не объявляет никаких лимитов, во время опроса этот вызов вообще не увидит. Но он все равно нужен для `IsTorrentLoaded`, то есть для проверки готовности после добавления: **404 для неизвестного хеша, 200 + JSON для известного.**

Результат кешируется на 5 минут для каждой комбинации `{Host}{Port}{Hash}` (`:678`, `:689`, `:695`, `:708`). Фикстура проверяет, что при двух опросах подряд данные запрашиваются один раз, а не два (Sonarr `QBittorrentFixture.cs:905-920`, Radarr `:904-919`).

### 1.9 `POST /api/v2/torrents/setShareLimits` — `SetTorrentSeedingConfiguration` (`:286-308`)

Форма: `hashes=<lowercase hash>`, затем `AddTorrentSeedingFormParameters(request, seedConfiguration, always: true)`
— при `always: true` всегда отправляются **оба** параметра, `ratioLimit` и `seedingTimeLimit`, даже если они равны `-2`
(`:232`, `:237`). `inactiveSeedingTimeLimit` никогда не отправляется.

**404** проглатывается (`:298-307`, комментарий: "setShareLimits was added in api v2.0.1"). Любая другая ошибка пробрасывается дальше, но место вызова ловит её и пишет предупреждение в лог
(`QBittorrent.cs:95-102`, `:152-159`).

Этот путь используется, только если индексер передаёт конфигурацию сидирования *и* webapi `< 2.8.1`. На шиме, который отдаёт `2.11.2`, лимиты шаринга передаются через `torrents/add`, и для граба этот путь вообще не используется. Реализуйте его как no-op, который возвращает 200.

### 1.10 `POST /api/v2/torrents/topPrio` — `MoveTorrentToTopInQueue` (`:310-330`)

Форма: `hashes=<lowercase hash>`.

**409 Conflict** игнорируется (`:320-329`, комментарий: "qBittorrent rejects all Prio commands with 409:
Conflict if Options -> BitTorrent -> Torrent Queueing is not enabled"). Прокси v1 вместо этого игнорирует **403** (`QBittorrentProxyV1.cs:255-264`). Всё остальное перехватывается и логируется как предупреждение в месте вызова (`QBittorrent.cs:107-114`, `:164-171`). Фикстура проверяет, что ошибка здесь не должна проваливать grab (Sonarr `QBittorrentFixture.cs:525-542`, Radarr `:524-541`).

Это вызывается только тогда, когда настройка приоритета Recent/Older равна `First` (`QBittorrentPriority.First = 1`, `QBittorrentPriority.cs:5-6`). По умолчанию стоит `Last = 0`.

### 1.11 `POST /api/v2/torrents/setForceStart` — `SetForceStart` (`:332-339`)

Форма: `hashes=<lowercase hash>`, `value=true` (буквальная строка в нижнем регистре, `:337`).

Вызывается только когда `InitialState` равен `ForceStart` (`QBittorrentState.cs:10-11`, `QBittorrent.cs:82`, `:117-127`). Ошибки перехватываются и выводятся как предупреждения (`:123-126`).

### 1.12 `GET /api/v2/torrents/info[?category=<cat>]` — `GetTorrents` (`:97-108`)

**Единственный параметр, который когда-либо отправляется, — это `category`, и только когда настройка не пустая**
(`:100-103`). Никаких `filter`, никаких `hashes`, никаких `sort`, никаких `reverse`, никаких `limit`, никаких `offset`, никаких `tag`.
Клиент **не** фильтрует по категории повторно после этого, в отличие от SAB-клиента, который фильтрует дважды. Так что shim, который игнорирует `category`, отдаст Radarr торренты Sonarr.

Поле `category` в ответе важно по второй причине: торрент, для которого у \*arr **нет истории grab-ов**, пропускается сразу, если только у него её нет:
`CompletedDownloadService.Check` (`CompletedDownloadService.cs:84-88`):

```csharp
if (historyItem == null && trackedDownload.DownloadItem.Category.IsNullOrWhiteSpace())
{
    trackedDownload.Warn("Download wasn't grabbed by Sonarr and not in a category, Skipping.");
    return;
}
```

`Category` — это `category`, если она не пустая, иначе `label` (`QBittorrent.cs:231`).

Ответ: JSON-**массив**. Каждое используемое поле и то, во что оно превращается:

| Ключ JSON | Тип C# | Единицы | Во что превращается |
|---|---|---|---|
| `hash` | `string` | | `DownloadId = torrent.Hash.ToUpper()` (`QBittorrent.cs:230`) — **в верхнем регистре**, а при каждом последующем вызове передаётся обратно в нижнем |
| `name` | `string` | | `Title = torrent.Name` (`:232`) — см. §7.1, что он запускает |
| `size` | `long` | байты | `TotalSize` (`:233`); также `RemainingSize = (long)(size * (1.0 - progress))` (`:235`) |
| `progress` | `double` | 0..1 | `RemainingSize` (`:235`) |
| `eta` | `BigInteger` | секунды | `RemainingTime` через `GetRemainingTime` (`:236`, `:614-628`) |
| `state` | `string` | | `Status`, `Message` и половина условия `CanMoveFiles` (`:242-312`) — §2 |
| `category` | `string` | | `Category`, предпочтительно (`:231`) |
| `label` | `string` | | `Category`, запасной вариант, если `category` пустая (`:231`). Поле из версий до 3.3.5; qBittorrent 5 его не отдаёт |
| `ratio` | `float` | | `SeedRatio` (`:237`), `HasReachedSeedLimit` (`:634`, `:641`) |
| `ratio_limit` | `float`, по умолчанию `-2` | | `HasReachedSeedLimit` (`:632-645`) |
| `seeding_time_limit` | `long`, по умолчанию `-2` | **минуты** | `HasReachedSeedingTimeLimit` (`:659-670`) |
| `inactive_seeding_time_limit` | `long`, по умолчанию `-2` | **минуты** | `HasReachedInactiveSeedingTimeLimit` (`:723-736`) |
| `last_activity` | `long` | **unix-секунды** | `HasReachedInactiveSeedingTimeLimit` (`:736`) |
| `seeding_time` | `long?`, по умолчанию null | секунды | `HasReachedSeedingTimeLimit` (`:672-676`) — комментарий в `QBittorrentTorrent.cs:36` говорит, что он "not provided by the list api", но клиент использует его, если он есть, что экономит один запрос `torrents/properties` |
| `save_path` | `string` | | сравнивается с `content_path` (`:316`) |
| `content_path` | `string` | | `OutputPath` на webapi `>= 2.6.1` (`:318`) — §4 |

`GetRemainingTime` (`:614-628`):

```csharp
if (torrent.Eta < 0 || torrent.Eta > 365 * 24 * 3600) { return null; }   // > 31,536,000 s
if (torrent.Eta == 8640000) { return null; }                            // qBittorrent's "unknown"
return TimeSpan.FromSeconds((int)torrent.Eta);
```

и у элемента со статусом Completed `RemainingTime` после этого принудительно становится `TimeSpan.Zero` (`:273`).

`torrents/info` запрашивается при каждом `RefreshMonitoredDownloads` (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:94`), а также ставится в очередь команд с задержкой 5 секунд после соответствующих событий (`:53`).

### 1.13 `GET /api/v2/torrents/files?hash=<hash>` — `GetTorrentFiles` (`:137-144`)

JSON-массив, который десериализуется в `List<QBittorrentTorrentFile>`. У каждого элемента ровно одно поле: `Name` (`QBittorrentTorrent.cs:59-62`), привязанное к `name`. Это путь к файлу **относительно пути сохранения**, с разделителями `/` на всех ОС («QBittorrent returns `/` path separators even on windows», `QBittorrent.cs:358`).

Вызывается только из `GetImportItem` (`:346`) и только тогда, когда `OutputPath` всё ещё пуст. То есть на webapi `< 2.6.1` или когда `content_path` вернулся пустым. Поля `index`, `size`, `progress`, `priority`, `is_seed`, `piece_range` и `availability` все игнорируются.

Пустой массив **обрабатывается отдельно**: вызывается `_logger.Debug("No files found for torrent {0} in qBittorrent")`, и элемент возвращается без изменений (`:347-351`). После этого он не проходит `ValidatePath`.

### 1.14 `POST /api/v2/torrents/setCategory` — `SetTorrentLabel` (`:204-211`)

Формат: `hashes=<lowercase hash>`, `category=<post-import category>`.

Вызывается только из `MarkItemAsImported` (`QBittorrent.cs:52-69`) и только тогда, когда необязательная настройка `TvImportedCategory` / `MovieImportedCategory` не пустая и отличается от основной категории. `DownloadClientException` перехватывается и выводится как предупреждение:
"Failed to set post-import torrent label \"{0}\" for {1} in qBittorrent. Does the label exist?"
(`:62-67`). §5.1.

### 1.15 `POST /api/v2/torrents/delete` — `RemoveTorrent` (`:190-202`)

Форма: `hashes=<lowercase hash>`, и `deleteFiles=true` **только когда `removeData` равен true**
(`:196-199`), то есть буквальная строка в нижнем регистре, а не `Convert.ToString(bool)`.

`QBittorrent.RemoveItem` (`:333-336`) — это вся реализация:

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    Proxy.RemoveTorrent(item.DownloadId.ToLower(), deleteData, Settings);
}
```

**Он не вызывает `DeleteItemData`.** В этом и отличие от клиента SAB, который удаляет папку задания сам,
через файловую систему
(`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`; см.
[sabnzbd-client-contract.md §5.3](sabnzbd-client-contract.md)). Здесь удаление данных полностью
на стороне самого клиента загрузки. §5.

### 1.16 Эндпоинты, которые клиент никогда не трогает {#116-endpoints-the-client-never-touches}

Вообще не выводятся в интерфейсе, поэтому никогда не вызываются: `torrents/pause`, `torrents/resume`, `torrents/stop`,
`torrents/start`, `torrents/setLocation`, `torrents/rename`, `torrents/recheck`,
`torrents/reannounce`, `torrents/filePrio`, `torrents/setDownloadLimit`, `torrents/setUploadLimit`,
`torrents/toggleSequentialDownload`, `torrents/setAutoManagement`, `torrents/editCategory`,
`torrents/removeCategories`, теги, RSS, поиск, `app/setPreferences`, `app/defaultSavePath`,
`app/shutdown`, `sync/maindata`, `transfer/*`, `auth/logout`. Приостановка и возобновление есть только в виде поля формы `paused=`/`stopped=` в `torrents/add`.

Есть в интерфейсе, но никогда не вызывается из `QBittorrent.cs`: `GetVersion` (§1.2).

### 1.17 Карта маршрутов v1 (для полноты; не реализовывать) {#117-the-v1-route-map-for-completeness-do-not-implement}

`QBittorrentProxyV1.cs`: `/version/api` (`:30`, `:64`, клиент добавляет префикс `"1."` к тому, что приходит в ответ, `:65`), `/version/qbittorrent` (`:73`), `/query/preferences` (`:81`),
`/query/torrents?label=&category=` (`:89-94`, **оба** параметра), `/query/propertiesGeneral/{hash}`
(`:103`, `:120`), `/query/propertiesFiles/{hash}` (`:128`), `/command/download` (`:136`),
`/command/upload` (`:166`), `/command/delete` или `/command/deletePerm` (`:196`, разница между delete и deleteFiles — это два разных маршрута, а не параметр),
`/command/setCategory` с запасным вариантом `/command/setLabel` при 404 (`:205-225`), `/command/addCategory` (`:230`),
`/command/topPrio` (`:248`), `/command/setForceStart` (`:269`), `/login` (`:345`).

## 2. `state` → `DownloadItemStatus`

`QBittorrent.GetItems` (`:247-312`). Состояния — это собственные строки qBittorrent, которые формирует `torrentStateToString` (`qBittorrent/src/webui/api/serialize/serialize_torrent.cpp:44-87`).

| `state` | `DownloadItemStatus` | `Message` | Строка |
|---|---|---|---|
| `error` | **Warning** | "qBittorrent is reporting an error" | `:249-252` |
| `stoppedDL` | Paused | — | `:254` |
| `pausedDL` | Paused | — | `:255` (qBittorrent < 5) |
| `queuedDL` | Queued | — | `:259` |
| `checkingDL` | Queued | — | `:260` |
| `checkingUP` | Queued | — | `:261` |
| `checkingResumeData` | Queued | — | `:262` |
| `pausedUP` | **Completed** | — | `:266` (qBittorrent < 5) |
| `stoppedUP` | **Completed** | — | `:267` |
| `uploading` | Completed | — | `:268` |
| `stalledUP` | Completed | — | `:269` |
| `queuedUP` | Completed | — | `:270` |
| `forcedUP` | Completed | — | `:271` |
| `stalledDL` | **Warning** | "The download is stalled with no connections" | `:276-279` |
| `missingFiles` | **Warning** | "qBittorrent is reporting missing files" | `:281-284` |
| `metaDL` | Queued **если `dht: true`**, иначе Warning | "qBittorrent is downloading metadata" / "qBittorrent cannot resolve magnet link with DHT disabled" | `:286-299` |
| `forcedMetaDL` | то же, что `metaDL` | то же | `:287` |
| `forcedDL` | Downloading | — | `:301` |
| `moving` | Downloading | — | `:302` |
| `downloading` | Downloading | — | `:303` |
| **всё остальное** | **Downloading** | "Unknown download state: {state}" | `:307-311` |

Что shim должен учитывать:

- **Неизвестное состояние не вызывает исключение.** Оно пишет в лог `_logger.Info($"Unknown download state: {torrent.State}")` и проваливается в Downloading (`:307-311`). Это противоположность клиенту SAB, где неизвестное имя статуса вызывает исключение внутри десериализатора и роняет весь опрос. Но всё равно: отправляйте только имена из этой таблицы.
- **Импортировать можно только состояния Completed.** `CompletedDownloadService.Check` сразу выходит, если не выполнено `Status == Completed` (`src/NzbDrone.Core/Download/CompletedDownloadService.cs:68-71`).
- **Каждое состояние Completed сбрасывает `RemainingTime` в ноль** (`:273`, комментарий «qBittorrent sends eta=8640000 for completed torrents»).
- `metaDL` / `forcedMetaDL` — это фаза «magnet, метаданных пока нет». **Таймаута в клиенте нет**: он остаётся в Queued, пока shim продолжает отдавать `metaDL`, и сам по себе никогда не превращается в ошибку. Перевести его в Warning может только `dht: false` в `app/preferences` (`:288`). Обработка неудачных загрузок в Sonarr реагирует на возраст граба, а не на это состояние.
- `stalledDL` — это *предупреждение*, которое оператор видит для торрента, который не двигается. Shim без понятия пиров никогда не должен его использовать: Warning на отслеживаемой загрузке попадает в очередь как проблема, и именно его проверяет `FailedDownloadService`.
- `error` и `missingFiles` намеренно сделаны Warning, «so failed download handling isn't triggered» (`:249`). Если shim хочет, чтобы Sonarr занёс релиз в блоклист и запросил его заново, для этого Warning **не** подходит.

## 3. Перемещение или копирование — точное условие и порядок действий {#3-move-vs-copy--the-exact-condition-and-the-recipe}

### 3.1 Условие {#31-the-gate}

`QBittorrent.cs:240-245`, дословно, включая комментарий, который это объясняет:

```csharp
// Avoid removing torrents that haven't reached the global max ratio.
// Removal also requires the torrent to be paused, in case a higher max ratio was set on the torrent itself (which is not exposed by the api).
item.CanMoveFiles = item.CanBeRemoved =
    item.DownloadClientInfo.RemoveCompletedDownloads &&
    torrent.State is "pausedUP" or "stoppedUP" &&
    HasReachedSeedLimit(torrent, config);
```

Три условия, все обязательны:

1. **`RemoveCompletedDownloads`** — настройка на стороне *arr для каждого клиента, а не то, что говорит qBittorrent.
   `DownloadClientDefinition.RemoveCompletedDownloads` по умолчанию **`true`**
   (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17`), в интерфейсе называется
   "Remove Completed". Если пользователь её выключит, **импорты превращаются в копии**, и прослойка с этим ничего не может сделать. (Move превращается в копию и по второй причине, которую прослойка тоже не видит: контейнер \*arr видит папку загрузок и корневую папку через два тома, и там `rename()` отвечает `EXDEV`, а `File.Move` в .NET копирует и потом удаляет. zurg считывает оба параметра из API источника получения и потом принимает копию; см. `internal/arrlayout` и `internal/handlers/magic_copies.go`.)
2. **`state` равен ровно `pausedUP` или `stoppedUP`.** `uploading`, `stalledUP`, `queuedUP` и `forcedUP` — это Completed, но не перемещаемые. Это закреплено фикстурой (Sonarr `QBittorrentFixture.cs:680-689`, Radarr `:679-688`).
3. **`HasReachedSeedLimit(torrent, config)`**.

### 3.2 `HasReachedSeedLimit` (`:630-653`)

```csharp
if (torrent.RatioLimit >= 0)
{
    if (torrent.RatioLimit - torrent.Ratio <= 0.001f) { return true; }        // :632-638
}
else if (torrent.RatioLimit == -2 && config.MaxRatioEnabled)
{
    if (config.MaxRatio - torrent.Ratio <= 0.001f) { return true; }           // :639-645
}

if (HasReachedSeedingTimeLimit(torrent, config) || HasReachedInactiveSeedingTimeLimit(torrent, config)) { return true; }
return false;
```

- Торрент с **per-torrent `ratio_limit >= 0`** побеждает сразу, и глобальный лимит не проверяется. В собственной модели qBittorrent `ratio_limit` равен `-2`, если используется глобальный лимит, и `-1`, если лимита нет (`QBittorrentTorrent.cs:32`; wiki, *Set torrent share limit*).
- `-1` (без лимита) не подходит ни под одну ветку: `-1 >= 0` ложно, и `-1 == -2` тоже ложно. Поэтому торрент без лимита **никогда** не может быть перенесён по правилу рейтинга.
- Запас `0.001f` нужен, чтобы работало «достигнуто после округления». В фикстуре рейтинг `1.1006066990976857` при лимите `1.0` считается достигнутым, и `0.9999` тоже считается достигнутым (Sonarr `QBittorrentFixture.cs:715-737`, Radarr `:714-736`).

`HasReachedSeedingTimeLimit` (`:655-717`):

```csharp
if (torrent.SeedingTimeLimit >= 0)        { seedingTimeLimit = torrent.SeedingTimeLimit * 60; }        // minutes -> seconds
else if (torrent.SeedingTimeLimit == -2 && config.MaxSeedingTimeEnabled) { seedingTimeLimit = config.MaxSeedingTime * 60; }
else                                      { return false; }
```

затем он использует `torrent.SeedingTime`, если его передал list API (`:672-676`). Если нет, он смотрит в кэш на 5 минут и, при промахе, вызывает **`torrents/properties`** за `seeding_time` (`:678-716`, `:739-744`). `HasReachedInactiveSeedingTimeLimit` (`:719-737`) устроен так же, но сравнивает `now - last_activity` с `inactive_seeding_time_limit` (или с глобальным значением) и никогда не требует второго вызова.

### 3.3 Что решает `CanMoveFiles` {#33-what-canmovefiles-decides}

`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, series, importItem)`
(`CompletedDownloadService.cs:148-151`), а потом две места читают `CanMoveFiles`:

```csharp
// src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152
bool copyOnly;
switch (importMode)
{
    default:
    case ImportMode.Auto: copyOnly = downloadClientItem is { CanMoveFiles: false }; break;   // :144
    case ImportMode.Move: copyOnly = false; break;
    case ImportMode.Copy: copyOnly = true;  break;
}
```

(Radarr: `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, идентично.)

```csharp
// src/NzbDrone.Core/MediaFiles/DownloadedEpisodesImportService.cs:204-207
if (importMode == ImportMode.Auto)
{
    importMode = (downloadClientItem == null || downloadClientItem.CanMoveFiles) ? ImportMode.Move : ImportMode.Copy;
}
```

(Radarr: `DownloadedMovieImportService.cs:221-224`.)

`copyOnly == false` → `TransferMode.Move`
(`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`); `copyOnly == true` →
`TransferMode.HardLinkOrCopy`, если включена опция "Use Hardlinks instead of Copy", иначе `TransferMode.Copy`
(`:103`, `:107`). `TransferMode` — это `[Flags] None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy=Copy|HardLink`
(`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`).

**Неудачный Move никогда не откатывается к Copy.** Полное обоснование, с номерами строк, есть в
[sabnzbd-client-contract.md §5.5](sabnzbd-client-contract.md); `DiskTransferService.cs` общий и побайтово идентичен в обоих репозиториях. Коротко: ветка Move в `TransferFile` (`src/NzbDrone.Common/Disk/DiskTransferService.cs:360-389`) имеет ровно один путь копирования, который выбирается заранее по `targetMount.DriveFormat == "cifs"` (`:342`, `:378-385`), а не как реакция на сбой; `TryMoveFileVerified` пробрасывает исключение (`:487-503`), а `VerifyFile` бросает `IOException("File move incomplete, data loss may have occurred. …")`, когда размер назначения не совпадает с размером источника (`:505-524`).

### 3.4 С настройками qBittorrent по умолчанию импорт — это **копирование** {#34-with-qbittorrents-own-defaults-the-import-is-a-copy}

Возьмём торрент, который шим сообщает наивно, то есть с настройками qBittorrent по умолчанию, которые совпадают и с дефолтами модели:

| Field | Value | Effect |
|---|---|---|
| `state` | `stoppedUP` | второе условие ✓ |
| `ratio_limit` | `-2` (по умолчанию, `QBittorrentTorrent.cs:33`) | переходит к глобальной ветке |
| `max_ratio_enabled` | `false` (собственное значение qBittorrent по умолчанию; пример тела из вики `:684`) | глобальная ветка не проходит |
| `seeding_time_limit` | `-2` | нужен `max_seeding_time_enabled` |
| `max_seeding_time_enabled` | `false` (вики `:686`) | не проходит |
| `inactive_seeding_time_limit` | `-2` | нужен `max_inactive_seeding_time_enabled` |
| `max_inactive_seeding_time_enabled` | `false` | не проходит |

⇒ `HasReachedSeedLimit` равен false ⇒ `CanMoveFiles` равен false ⇒ `copyOnly` равен true ⇒ `TransferMode.Copy` ⇒ **\*arr читает каждый байт релиза с маунта и записывает его обратно.** На debrid-маунте это как раз тот исход, ради которого вся схема и существует, и он проходит молча: ничего не предупреждает, импорт просто тянется часами и забивает диск.

Фикстура фиксирует именно этот случай:
`should_not_be_removable_and_should_not_allow_move_files_if_max_ratio_is_not_set`
(Sonarr `QBittorrentFixture.cs:691-701`, Radarr `:690-700`) — глобальные лимиты выключены, торрент на паузе, ratio 1.0, `CanMoveFiles == false`.

### 3.5 Порядок действий {#35-the-recipe}

Для каждого торрента, который shim хочет импортировать методом **move**:

```json
{
  "state": "pausedUP",
  "ratio": 0,
  "ratio_limit": 0,
  "seeding_time_limit": -2,
  "inactive_seeding_time_limit": -2,
  "last_activity": 1756252800
}
```

`ratio_limit: 0` идёт по первой ветке (`0 >= 0` и `0 - 0 <= 0.001`), и глобальные настройки вообще не проверяются. Поэтому `max_ratio_enabled` может оставаться `false`, и проверка состояния `DownloadClientRemovesCompletedDownloadsCheck` молчит. Подойдёт любое `ratio_limit >= ratio` с разницей в пределах `0.001`, но `0`/`0` — самый простой вариант, который не требует согласования настроек.

Про `pausedUP` и `stoppedUP`: **в develop они обрабатываются одинаково**, и в проверке `CanMoveFiles` (`:244`), и в таблице статусов (`:266-267`). Все фикстуры для seed-лимитов написаны парами `[TestCase]` для обоих значений. `stoppedUP` — это написание из qBittorrent 5 (`serialize_torrent.cpp:54-55`), в master `pausedUP` уже нет. Но `pausedUP` безопаснее для выпущенных сборок \*arr: ветка с `stoppedUP` появилась вместе с qBittorrent 5, а старые Sonarr v4 и Radarr v5 знают только `pausedUP`. Последнее — это предположение о старых тегах, которое исходники develop сами по себе не подтверждают.

И то, что не зависит от shim: **«Remove Completed» в настройках клиента загрузки в \*arr должен оставаться включённым.** По умолчанию он включён (`DownloadClientDefinition.cs:17`). Обязательно напишите об этом в документации, потому что если его выключить, каждый импорт молча превратится в полную загрузку.

## 4. `OutputPath` — откуда \*arr должен импортировать {#4-outputpath--where-the-arr-is-told-to-import-from}

### 4.1 Путь для 2.6.1+: `content_path` {#41-the-261-path-content_path}

`QBittorrent.cs:314-325`:

```csharp
if (version >= new Version("2.6.1") && item.Status == DownloadItemStatus.Completed)
{
    if (torrent.ContentPath != torrent.SavePath)
    {
        item.OutputPath = _remotePathMappingService.RemapRemoteToLocal(Settings.Host, new OsPath(torrent.ContentPath));
    }
    else
    {
        item.Status = DownloadItemStatus.Warning;
        item.Message = _localizationService.GetLocalizedString("DownloadClientQbittorrentTorrentStatePathError");
    }
}
```

Текст предупреждения (`src/NzbDrone.Core/Localization/Core/en.json`):

> Unable to Import. Path matches client base download directory, it's possible 'Keep top-level folder'
> is disabled for this torrent or 'Torrent Content Layout' is NOT set to 'Original' or 'Create Subfolder'?

Правила, которым должна отвечать прослойка:

- `content_path` **не должен совпадать** с `save_path`. Совпадение — это ошибка, а не запасной вариант: элемент становится Warning и никогда не импортируется.
- `content_path` должен быть **абсолютным и корректным для той ОС, на которой работает \*arr**. `CompletedDownloadService.ValidatePath`
  (`CompletedDownloadService.cs:295-313`) иначе отклонит его с сообщением
  "[{0}] is not a valid local path. You may need a Remote Path Mapping."
- Он должен существовать на хосте \*arr как **папка или файл**. `ProcessPath`
  (`DownloadedEpisodesImportService.cs:80-105`) сначала проверяет `FolderExists`, потом `FileExists`, а если ни то, ни другое не сработало, уходит в `LogInaccessiblePathError` и возвращает пустой результат.
- Не отправляйте пустой `content_path`. Он "отличается" от непустого `save_path`, поэтому `OutputPath` становится пустым `OsPath`, и `GetImportItem` уходит на обход `torrents/files` (§4.2), потому что `item.OutputPath.IsEmpty` равно true (`:341-344`).
- Этот блок выполняется только для элементов в состоянии **Completed**, так что `content_path` важен только тогда, когда состояние входит в набор Completed из §2.

Что реально пишет настоящий qBittorrent — `TorrentImpl::contentPath()`
(`qBittorrent/src/base/bittorrent/torrentimpl.cpp:577-587`):

```cpp
Path TorrentImpl::contentPath() const
{
    if (!hasMetadata())    return {};
    if (filesCount() == 1) return (actualStorageLocation() / filePath(0));   // the FILE, not a folder
    const Path rootPath = this->rootPath();
    return (rootPath.isEmpty() ? actualStorageLocation() : rootPath);
}
```

где `rootPath()` = `actualStorageLocation() / Path::findRootFolder(filePaths())` (`:565-575`). Итак: у торрента из **одного файла** `content_path` — это сам файл; у многофайлового торрента с общей корневой папкой — эта папка; у многофайлового торрента **без** общего корня — `save_path`, и именно этот случай и вызывает предупреждение клиента о том, что `content_path == save_path`.

`RemapRemoteToLocal(Settings.Host, …)` применяет Remote Path Mappings пользователя, привязанные к настроенной строке **Host**. Если \*arr работает в контейнере, а прослойка отдаёт путь хоста, оператору нужен маппинг; см. [sabnzbd.md](../guides/sonarr-radarr.md#8-if-your-arr-is-in-docker), здесь всё применимо без изменений.

### 4.2 Путь для версий до 2.6.1: `GetImportItem` проходит по `torrents/files` {#42-the-pre-261-path-getimportitem-walks-torrentsfiles}

`QBittorrent.cs:338-370`:

```csharp
if (!item.OutputPath.IsEmpty) { return item; }                       // :341-344  already set by §4.1

var files = Proxy.GetTorrentFiles(item.DownloadId.ToLower(), Settings);
if (!files.Any()) { _logger.Debug(...); return item; }               // :346-351

var properties = Proxy.GetTorrentProperties(item.DownloadId.ToLower(), Settings);
var savePath = new OsPath(properties.SavePath);                      // :353-354

var result = item.Clone();

// get the first subdirectory - QBittorrent returns `/` path separators even on windows...
var relativePath = new OsPath(files[0].Name);
while (!relativePath.Directory.IsEmpty) { relativePath = relativePath.Directory; }   // :359-363

var outputPath = savePath + relativePath.FileName;                   // :365
result.OutputPath = _remotePathMappingService.RemapRemoteToLocal(Settings.Host, outputPath);
return result;
```

Он берёт **только `files[0].name`**, поднимается до самого верхнего компонента пути и присоединяет его к `properties.save_path`. Фикстура фиксирует все три варианта (Sonarr `QBittorrentFixture.cs:317-421`, Radarr `:296-400`):

| `files[0].name` | `save_path` | `OutputPath` |
|---|---|---|
| `Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` |
| `Folder/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Folder` |
| `Droned.S01.12/E01.mkv` (+ `E02.mkv`) | `/Torrents` | `/Torrents/Droned.S01.12` |

Обрати внимание на третью строку: берётся корень `files[0]`, а не вычисляемый общий корень, поэтому **шим на этом пути должен отдавать файлы в таком порядке, чтобы первый элемент содержал папку релиза**. Шим, который сообщает webapi `>= 2.6.1`, сюда вообще не попадает, и это ещё одна причина указывать `2.11.2`.

`previousImportAttempt` — это параметр `GetImportItem` (`:338`), и эта реализация **его никогда не читает**. Информация о неудачной попытке нигде не сохраняется.

### 4.3 Когда путь неверный и как часто выполняется повтор {#43-when-the-path-is-wrong-and-how-often-it-is-retried}

Здесь нет ни отката (backoff), ни лимита попыток.

- `CompletedDownloadService.Check` запускается для каждой отслеживаемой загрузки в состоянии `Downloading` или `ImportBlocked` при каждом обновлении
  (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:125-129`).
- `Check` **первым делом** вызывает `SetImportItem` (`CompletedDownloadService.cs:73`), то есть `_provideImportItemService.ProvideImportItem(...)` → `client.GetImportItem(...)`
  (`:290-293`, `src/NzbDrone.Core/Download/ProvideImportItemService.cs:17-22`). Значит, `OutputPath` пересчитывается заново из *текущей* строки `torrents/info` при каждом опросе.
- Ошибки `ValidatePath` (`:295-313`) дают Warning и оставляют состояние `Downloading`, поэтому следующий опрос начинает всё с нуля:
  - пустой путь вывода → "Download doesn't contain intermediate path, Skipping."
  - путь для другой ОС → "[{0}] is not a valid local path. You may need a Remote Path Mapping. …"
- `Import` тоже вызывает `SetImportItem` при входе (`:130`), прежде чем заново прочитать `trackedDownload.ImportItem.OutputPath.FullPath` (`:147`). Запускает его `DownloadProcessingService` из состояния `ImportPending`
  (`src/NzbDrone.Core/Download/DownloadProcessingService.cs:61-63`). Неудачный импорт оставляет состояние `ImportPending` (`:158`) или переводит его в `ImportBlocked` (`:196`). Обработка повторяется в обоих случаях.
- Если путь существует, но в нём нет ничего, что можно импортировать, появляется сообщение "No files found are eligible for import in {0}" (`:162`), и состояние остаётся `ImportPending`.

**Что это значит для шима: `content_path` некоторое время может быть неправильным.** Пока папка реально не появилась и размеры её файлов не финальные, отдавай торрент как Downloading (или Queued). Тогда клиент просто продолжит опрашивать. Если сообщить Completed слишком рано, импорт потратит попытку на папку, которая ещё не готова. Хуже того, \*arr может переместить файл с неполным размером, а потом упасть на `VerifyFile`, уже опустошив источник. Та же ловушка описана для SAB-эндпоинта ([sabnzbd.md](../guides/sonarr-radarr.md), *What happens on a grab*, шаг 5).

## 5. Последовательность действий после импорта {#5-the-post-import-sequence}

### 5.1 Что срабатывает и в каком порядке {#51-what-fires-in-order}

`DownloadEventHub.Handle(DownloadCompletedEvent)`
(`src/NzbDrone.Core/Download/DownloadEventHub.cs:48-69`):

```csharp
MarkItemAsImported(trackedDownload, downloadClient);                       // :54  ALWAYS, first

if (trackedDownload.DownloadItem.Removed ||
    !trackedDownload.DownloadItem.CanBeRemoved ||
    trackedDownload.DownloadItem.Status == DownloadItemStatus.Downloading) { return; }   // :56-61

if (!definition.RemoveCompletedDownloads) { return; }                      // :63-66

RemoveFromDownloadClient(message.TrackedDownload, downloadClient);         // :68
```

а `RemoveFromDownloadClient` (`:87-103`) выглядит так:

```csharp
_logger.Debug("[{0}] Removing download from {1} history", ...);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);             // :92  deleteData: TRUE
trackedDownload.DownloadItem.Removed = true;
```

Итак, последовательность запросов после успешного импорта такая:

1. **`POST /api/v2/torrents/setCategory`** — выполняется только если настроена категория после импорта
   (`QBittorrent.cs:52-69`). По умолчанию пропускается.
2. Раньше этих шагов и полностью вне торрент-клиента: **\*arr перемещает файл**, после чего
   `ProcessFolder` может **удалить исходную папку** (`DownloadedEpisodesImportService.cs:209-223`, Radarr `DownloadedMovieImportService.cs:226-240`):

   ```csharp
   if (importMode == ImportMode.Move &&
       importResults.Any(i => i.Result == ImportResultType.Imported) &&
       ShouldDeleteFolder(directoryInfo, series))
   {
       _diskProvider.DeleteFolder(directoryInfo.FullName, true);   // recursive
   }
   ```

   `ShouldDeleteFolder` (`:108-153`) отказывается удалять папку, если в ней осталось видеофайл, который парсится и не является
   сэмплом (`:117-133`), или если осталась `.rar`-часть больше 10 МБ (`:135-139`). После успешного
   перемещения одного файла ни одно из этих условий не выполняется, поэтому папка **удаляется**. `IOException` перехватывается и
   пишется в лог на уровне Debug (`:219-222`).
3. **`POST /api/v2/torrents/delete`** с `hashes=<lowercase hash>&deleteFiles=true`
   (`QBittorrent.cs:335`, `QBittorrentProxyV2.cs:190-202`).

Ещё два события попадают в тот же `RemoveFromDownloadClient(…, true)`:

- `DownloadFailedEvent` (`DownloadEventHub.cs:26-46`), который зависит от настройки клиента
  `RemoveFailedDownloads` (по умолчанию `true`, `DownloadClientDefinition.cs:18`). Обратите внимание: `TrackedDownload.Fail()`
  безусловно выставляет `DownloadItem.CanBeRemoved = true` (`src/NzbDrone.Core/Download/TrackedDownloads/TrackedDownload.cs:39-46`, комментарий: "Set CanBeRemoved
  to allow the failed item to be removed from the client") — **поэтому неудачная загрузка удаляется, даже если проверка seed-лимита решает иначе.**
- `DownloadCanBeRemovedEvent` (`:71-85`).

`NotSupportedException`, выброшенное из `RemoveItem`, заменяется на
"Removing item not supported by your download client ({0})." (`:95-98`). Любое другое исключение записывается в лог как ошибка, и элемент *не* помечается как Removed, поэтому попытка повторится при следующем опросе (`:99-102`).

### 5.2 Что шим должен делать с `deleteFiles=true` {#52-what-the-shim-must-do-with-deletefilestrue}

Это то же решение, что `internal/sabnzbd` уже приняло для `mode=history&name=delete`, и по той же причине. Вот код из `internal/sabnzbd/api.go:596-609`:

```go
// deleteFromHistory drops the job record and nothing else.
//
// del_files is ignored on purpose. The clients send it as 1 after every
// successful import, meaning "the job folder is yours again" — but on zurg
// the imported file is still served out of that NZB, and deleting it would
// take away the very thing that was just imported. The job folder the client
// wanted gone is gone: it deleted that itself, through the mount, as a
// __magic__ tombstone.
```

С qBittorrent то же самое, но с одной оговоркой: в этом API удаление данных — работа *клиента*, а не \*arr, потому что `RemoveItem` **не** вызывает `DeleteItemData` (§1.15). Но \*arr уже сам удалил папку на шаге 2 выше, через монтирование. При `__magic__` это записывает маркер удаления: запись исчезает из `__magic__`, но остаётся на своём месте в `__all__`, во всех папках фильтров и на аккаунте дебрид-сервиса ([magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)).

Итак:

- **`torrents/delete` удаляет *запись* о торренте, которую прослойка хранит для \*arr.** Отвечаем 200.
- **`deleteFiles` не должен удалять торрент у провайдера.** Релиз, который \*arr только что импортировал, всё ещё отдаётся из него. Удалив торрент, мы уничтожим то, что было импортировано. Единственное место, где настоящее удаление было бы честным, — торрент, из которого ничего не импортировалось, то есть путь неудачной загрузки. Но и там торрент в дебрид-сервисе — это общее состояние библиотеки, а не временная загрузка, поэтому безопасное поведение по умолчанию такое: **никогда не удалять торрент у провайдера, только ставить маркер удаления.** Скажите об этом в документации для пользователей, как это сделано в [sabnzbd.md](../guides/sonarr-radarr.md) в разделе *What works, and what does not*.
- Для `torrents/delete` с **неизвестным хешем** всё равно должен быть ответ 200. Настоящий qBittorrent так и делает (вики, *Delete torrents*: "200 | All scenarios"). А ошибка здесь запишется в лог как ошибка и будет повторяться при каждом опросе навсегда.

### 5.3 `MarkItemAsImported` и категория после импорта {#53-markitemasimported-and-the-post-import-category}

`QBittorrent.cs:52-69` устанавливает категорию после импорта, если заданы `TvImportedCategory` /
`MovieImportedCategory` и они отличаются от основной категории. Вызывается это для **каждого**
завершённого импорта (`DownloadEventHub.cs:54`), до решения об удалении.

Если шим принимает `setCategory` и реально переносит торрент из опрашиваемой категории, торрент пропадает из следующего `torrents/info?category=…`. Ради этого настройка и нужна, и именно это UI показывает как `DownloadClientHasPostImportCategory`
(`src/NzbDrone.Core/Queue/QueueService.cs:84`, берётся из `DownloadClientItemClientInfo.HasPostImportCategory`, `QBittorrent.cs:234`). Принять вызов и записать новую категорию — правильное поведение. Отказ даёт только предупреждение (`:62-67`).

## 6. `Test()` — каждая проверка по порядку и её сообщение {#6-test--every-check-in-order-and-its-message}

`DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`) оборачивает
всё целиком: **любое исключение, которое выходит наружу, превращается в**
`ValidationFailure("", "Test was aborted due to an error: " + ex.Message)`.

`QBittorrent.Test(List<ValidationFailure>)` (`:418-429`):

```csharp
failures.AddIfNotNull(TestConnection());
if (failures.HasErrors()) { return; }     // a *warning* does not stop the rest
failures.AddIfNotNull(TestCategory());
failures.AddIfNotNull(TestPrioritySupport());
failures.AddIfNotNull(TestGetTorrents());
```

### 6.1 `TestConnection` (`:431-509`)

Каждая ветка **возвращает результат**, поэтому из метода выходит не более одной ошибки.

| Порядок | Условие | Свойство | Сообщение |
|---|---|---|---|
| 1 | `_proxySelector.GetProxy(Settings, force: true).GetApiVersion(Settings)` — принудительно заново определяет версию (`:435`) | | |
| 2 | версия `< 1.5` (`:436`) | `Host` | "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| 3 | версия `< 1.6` **и** категория задана (`:445-455`) | `Category` | "Category is not supported" / подробно "Categories are not supported until qBittorrent version 3.3.0. Please upgrade or try again with an empty Category." |
| 4 | версия `>= 1.6` **и** категория пустая (`:456-464`) | `TvCategory` / `MovieCategory` | **Предупреждение** — "Category is recommended" / "{appName} will not attempt to import completed downloads without a category." |
| 5 | `GetConfig`, затем `RemovesCompletedDownloads(config)` (`:467-474`) | `""` | "qBittorrent is configured to remove torrents when they reach their Share Ratio Limit" / подробно с указанием Options → BitTorrent → Share Ratio Limiting |

Перехват исключений (`:476-506`):

| Перехвачено | Свойство | Сообщение |
|---|---|---|
| `DownloadClientAuthenticationException` | `ApiKey`, если задан API-ключ, иначе `Username` | "Authentication Failure" / "Please verify your credentials. Also verify if the host running {appName} isn't blocked from accessing {clientName} by WhiteList limitations…" |
| `WebException` со `Status == ConnectFailure` | `Host` | "Unable to connect to qBittorrent" / "Please verify the hostname and port." |
| любой другой `WebException` | `""` | "Unknown exception: {message}" |
| любой другой `Exception` | `Host` | "Unable to connect to qBittorrent", `DetailedDescription = ex.Message` |

Обратите внимание: случай 4 — это **предупреждение**, а `failures.HasErrors()` в `:421` для предупреждений возвращает false. Поэтому настройка без категории всё равно выполнит остальные три проверки.

### 6.2 `TestCategory` (`:511-556`) — сценарий «category does not exist» {#62-testcategory-511-556--the-category-does-not-exist-flow}

```csharp
if (Settings.TvCategory.IsNullOrWhiteSpace() && Settings.TvImportedCategory.IsNullOrWhiteSpace()) { return null; }   // :513-516

// api v1 doesn't need to check/add categories as it's done on set
var version = _proxySelector.GetProxy(Settings, true).GetApiVersion(Settings);   // :519  forces AGAIN
if (version < Version.Parse("2.0")) { return null; }                              // :520-523

var labels = Proxy.GetLabels(Settings);                                           // :525

if (Settings.TvCategory.IsNotNullOrWhiteSpace() && !labels.ContainsKey(Settings.TvCategory))
{
    Proxy.AddLabel(Settings.TvCategory, Settings);                                // :529  createCategory
    labels = Proxy.GetLabels(Settings);                                           // :530  re-read
    if (!labels.ContainsKey(Settings.TvCategory)) { return failure; }             // :532-538
}
// …identical block for TvImportedCategory at :541-553
```

Ошибка: свойство `TvCategory` / `MovieCategory` (или `TvImportedCategory` / `MovieImportedCategory`),
message "Configuration of category failed", detail "{appName} was unable to add the label to
qBittorrent."

Итак, у shim есть выбор: либо заранее отдать настроенные категории, чтобы `torrents/categories` уже их содержал, либо принять `createCategory` и отразить его в самом следующем ответе `torrents/categories`. **Третьего варианта нет**: клиент перечитывает список и выдаёт ошибку, если ключа всё ещё нет. Имена категорий сравниваются **точно**, с учётом регистра (`Dictionary<string, …>.ContainsKey` с обычным порядковым сравнением по умолчанию).

Обратите внимание на обработку `TvImportedCategory`: категория после импорта тоже проверяется и создаётся здесь, хотя используется только после импорта. Если оператор её задал, она должна существовать.

`QBittorrentSettingsValidator` (`QBittorrentSettings.cs:23-24`) уже отклоняет имена категорий, которые соответствуют `^([^\\\/](\/?[^\\\/])*)?$` — без обратного слеша, без `//`, без `/` в начале или в конце — до того, как отправляется какой-либо запрос.

### 6.3 `TestPrioritySupport` (`:558-597`) — проверка здоровья `queueing` {#63-testprioritysupport-558-597--the-queueing-health-check}

```csharp
var recentPriorityDefault = Settings.RecentTvPriority == (int)QBittorrentPriority.Last;
var olderPriorityDefault  = Settings.OlderTvPriority  == (int)QBittorrentPriority.Last;
if (olderPriorityDefault && recentPriorityDefault) { return null; }   // :563-566  the default: nothing checked

var config = Proxy.GetConfig(Settings);
if (!config.QueueingEnabled) { … }                                    // :572-588
```

Свойство ошибки — `nameof(Settings.RecentTvPriority)` или `nameof(Settings.OlderTvPriority)`
(проверяется в этом порядке), сообщение «Queueing Not Enabled», подробности «Torrent Queueing is not enabled in
your qBittorrent settings. Enable it in qBittorrent or select 'Last' as priority.»

Исключение здесь превращается в `("", "Unknown exception: {message}")` (`:590-594`).

`queueing_enabled` по умолчанию равен **`true`** в модели (`QBittorrentPreferences.cs:41`), поэтому шим, который не передаёт этот ключ, пройдёт проверку, но это обман, если `topPrio` ничего не делает. Честно указать `queueing_enabled: false`, и тогда эта ошибка появится **только** если оператор поменял настройку приоритета с `Last`.

### 6.4 `TestGetTorrents` (`:599-612`)

`Proxy.GetTorrents(Settings)`; any exception becomes `("", "Failed to get the list of torrents:
{exceptionMessage}")`. This is the check that catches a malformed `torrents/info` body — a JSON object
instead of an array, a bad enum, a non-numeric `size`.

### 6.5 Проверка `dht` {#65-the-dht-check}

There is **no** dedicated DHT check in `Test()`. `dht` is consulted at grab time
(`:73-76`, magnets without trackers) and at poll time (`:288`, the `metaDL` branch). A shim reporting
`dht: false` passes the connection test and then refuses every trackerless magnet with
`ReleaseDownloadException("Magnet not supported by download client. …")`
(`TorrentClientBase.cs:115`). **Report `dht: true`.**

## 7. Парсинг и последствия для импорта, которые стоит знать шиму {#7-parsing-and-import-consequences-a-shim-should-know}

### 7.1 `name` становится `Title`, и `Title` используется для трёх разных вещей {#71-name-becomes-title-and-title-is-used-for-three-different-things}

`DownloadClientItem.Title = torrent.Name` (`QBittorrent.cs:232`). Дальше это используется так:

1. **Определение сериала/фильма.** `CompletedDownloadService.Check` вызывает `_parsingService.GetSeries(trackedDownload.DownloadItem.Title)` (`CompletedDownloadService.cs:95`). Если результат null, он переходит к **истории захватов** по `DownloadId` (`:99-102`). Если и её нет, появляется сообщение "Series title mismatch; automatic import is not possible." и `ImportBlocked` (`:104-110`). Аналог в Radarr находится в `ProcessFolder`: там читается `_historyService.FindByDownloadId(downloadClientItem?.DownloadId ?? "")` (`DownloadedMovieImportService.cs:193-194`).
   **Поэтому shim должен искать по точному infohash, который вычислил \*arr (§1.7).** Резервный путь работает по `DownloadId`, так что при несовпадении хеша пропадают и путь по названию, и запасной вариант.
2. **Разбор релиза для решения об импорте.** `downloadClientItemInfo = Parser.Parser.ParseTitle(downloadClientItem.Title)` (Sonarr `ImportDecisionMaker.cs:80`; Radarr `ParseMovieTitle`, `:80`). Результат попадает в `LocalEpisode.DownloadClientEpisodeInfo` / `LocalMovie.DownloadClientMovieInfo` (`:94` / `:92`).
3. **Строки логов и интерфейс очереди.**

**Ограничение Sonarr на использование названия из клиента.** `AggregateEpisodes.GetBestEpisodeInfo` (`src/NzbDrone.Core/MediaFiles/EpisodeImport/Aggregation/Aggregators/AggregateEpisodes.cs:29-57`):

```csharp
var parsedEpisodeInfo = localEpisode.FileEpisodeInfo;

if (!localEpisode.OtherVideoFiles && !SceneChecker.IsSceneTitle(Path.GetFileNameWithoutExtension(localEpisode.Path)))
{
    if (downloadClientEpisodeInfo != null && !downloadClientEpisodeInfo.FullSeason &&
        PreferOtherEpisodeInfo(parsedEpisodeInfo, downloadClientEpisodeInfo))
    {
        parsedEpisodeInfo = localEpisode.DownloadClientEpisodeInfo;        // :41
    }
    else if (folderEpisodeInfo != null && !folderEpisodeInfo.FullSeason &&
             PreferOtherEpisodeInfo(parsedEpisodeInfo, folderEpisodeInfo))
    {
        parsedEpisodeInfo = localEpisode.FolderEpisodeInfo;                // :47
    }
}
```

Название из клиента вместо имени файла используется только при трёх условиях: `!OtherVideoFiles`, имя файла само не является scene-названием и название из клиента не разбирается как полный сезон. То есть название торрента спасает только релиз из одного файла с не-scene именем.

В Radarr такого единого ограничения, которое выбирает единственного победителя, нет. `LocalMovie.OtherVideoFiles` существует (`src/NzbDrone.Core/Parser/Model/LocalMovie.cs:36`), но разобранная информация о фильме объединяется цепочкой аугментеров, отсортированных по уверенности, а не выбирается один вариант (`AggregateQuality.cs:25-121`). Название из клиента передаётся в эти аугментеры, а идентичность фильма берётся из разбора имени папки и истории захватов (`DownloadedMovieImportService.cs:192-195`).

**`OtherVideoFiles`** (`ImportDecisionMaker.cs:85`, `:100`, Radarr `:83`, `:98`):

```csharp
var nonSampleVideoFileCount = sceneSource ? GetNonSampleVideoFileCount(newFiles, series, downloadClientItemInfo, folderInfo) : videoFiles.Count;
…
OtherVideoFiles = nonSampleVideoFileCount > 1
```

`ProcessFolder` всегда передаёт `sceneSource: true` (`DownloadedEpisodesImportService.cs:201`). Поэтому если в папке два и более видеофайла, не являющихся сэмплами, выставляется `OtherVideoFiles`, и название из клиента перестаёт учитываться для каждого файла в ней.

**Почему это важно на zurg.** Real-Debrid переписывает имена релизов, которые задевают его фильтр имён файлов: `WEB-DL`, `WEB.x264` и `WEB.H264` (только в этом конкретном случае), а также `WEBRip`, `BDRip`, `HDRip`, `DVDRip`, `HDTV.x264`, `HDTV.XviD`, `BluRay.x264` и `p.BluRay.DTS` в любом регистре. Это зафиксировано 2026-10-14. Кроме того, zurg добавляет суффикс, если два релиза сталкиваются по имени. Из-за любого из этих случаев `torrent.name` может перестать разбираться как исходный релиз. Подробности в разделе RD 451 в `CLAUDE.md` монорепозитория. Последствия по порядку: определение идёт через историю захватов (всё в порядке, если хеш совпадает); разбор имени файла Sonarr берёт на себя (нормально для хорошо названного файла внутри папки); а имя папки под `__magic__`, которое читает `Parser.ParseTitle(directoryInfo.Name)` в `DownloadedEpisodesImportService.cs:184`, становится ещё одним местом, которое должно оставаться разбираемым.

### 7.2 Сканирование папки импорта пропускает целые поддеревья {#72-the-import-folder-scan-drops-whole-subtrees}

`DiskScanService.FilterPaths` (`src/NzbDrone.Core/MediaFiles/DiskScanService.cs:232-246`), применяемый к папке загрузки в `DownloadedEpisodesImportService.cs:185` (Radarr: `DownloadedMovieImportService.cs:202`) с `filterExtras: true`:

```csharp
private static readonly Regex ExcludedExtrasSubFolderRegex = new Regex(@"(?:\\|\/|^)(?:extras|extrafanart|behind the scenes|deleted scenes|featurettes|interviews|other|scenes|samples|shorts|trailers)(?:\\|\/)", …IgnoreCase);   // :72
private static readonly Regex ExcludedSubFoldersRegex      = new Regex(@"(?:\\|\/|^)(?:@eadir|\.@__thumb|plex versions|\.[^\\/]+)(?:\\|\/)", …IgnoreCase);   // :73
private static readonly Regex ExcludedExtraFilesRegex      = new Regex(@"(-(trailer|other|behindthescenes|deleted|featurette|interview|scene|short)\.[^.]+$)", …IgnoreCase);   // :74
private static readonly Regex ExcludedFilesRegex           = new Regex(@"^\.(_|unmanic|DS_Store$)|^Thumbs\.db$", …IgnoreCase);   // :75
```

**Регулярка для extras в Radarr отличается одной альтернативой**: `sample[s]?` вместо `samples` (Radarr `DiskScanService.cs:72`), поэтому Radarr отбрасывает и папку `sample/`, а Sonarr только `samples/`. Всё остальное в четырёх регулярках одинаково в обоих репозиториях.

Обрати внимание на альтернативу `\.[^\\/]+` в `ExcludedSubFoldersRegex`: **любой компонент пути, начинающийся с точки, отбрасывается** на любой глубине. Совпадение ищется по `basePath.GetRelativePath(path)`, то есть только внутри папки импорта, так что точка в родительской папке монтирования никак не влияет.

Только файлы с расширением из `MediaFileExtensions.Extensions` вообще попадают в этот фильтр (`DiskScanService.GetVideoFiles`, `:202-215`).

### 7.3 Определение сэмплов читает файл {#73-sample-detection-reads-the-file}

`GetNonSampleVideoFileCount` (`ImportDecisionMaker.cs:216-234`) вызывает `_detectSample.IsSample(...)` для **каждого** видеофайла в папке. `DetectSample.IsSample` (`src/NzbDrone.Core/MediaFiles/EpisodeImport/DetectSample.cs:27-45`) пропускает проверку только для specials, `.flv` и `.strm` (`:78-101`). Во всех остальных случаях он вызывает `_videoFileInfoReader.GetRunTime(path)` — **ffprobe, на файл, через маунт** — и сравнивает результат с минимумом, вычисленным из ожидаемой длительности (`:103-121`). Длительность ровно 0 считается **сэмплом** (`:107-111`), а если длительность не получена, в лог пишется "Failed to get runtime from the file, make sure ffprobe is available" и возвращается Indeterminate (`:38-42`).

`ShouldDeleteFolder` (`DownloadedEpisodesImportService.cs:117-133`) запускает ту же проверку ещё раз, но уже для всего, что осталось после перемещения.

Итого импорт релиза из N файлов стоит минимум N открытий через ffprobe к бэкенду дебрид-сервиса ещё до того, как что-либо будет перемещено. На zurg-маунте это реальные затраты, и со стороны клиента их не обойти.

### 7.4 Отказы в `ProcessFolder` / `ProcessFile` {#74-the-refusals-in-processfolder--processfile}

| Условие | Результат | Строка (Sonarr) |
|---|---|---|
| путь импорта является папкой сериала/фильма | `ImportRejectionReason.SeriesFolder` — "Import path is mapped to a series folder" (Radarr: `MovieFolder`, "…a movie folder") | `:175-182` (Radarr `:183-190`) |
| имя папки не соответствует известному сериалу/фильму | `UnknownSeriesResult("Unknown Series")` | `:160-168` |
| имя файла начинается с `._` | `InvalidFilePath` | `:251-259` |
| расширение входит в `FileExtensions.DangerousExtensions` | `DangerousFile` | `:263-271` |
| расширение входит в `FileExtensions.ExecutableExtensions` | `ExecutableFile` | `:273-281` |
| расширение не входит в `MediaFileExtensions.Extensions` | `UnsupportedExtension` | `:283-293` |

**`SeriesPathExists` / `MoviePathExists` — это то, что ломает раскладку `__magic__`.** Если корневая папка \*arr — `/mnt/zurg/__magic__/tv`, а папка сериала — `/mnt/zurg/__magic__/tv/The Show`, то путь импорта, который оказался папкой сериала, отклоняется сразу. Поэтому папка загрузки (`content_path`) должна лежать рядом с корневыми папками, а не внутри них. Именно такую схему рекомендует [sabnzbd.md](../guides/sonarr-radarr.md): `save_path` = `/mnt/zurg/__magic__/__all__`, корневые папки `/mnt/zurg/__magic__/tv` и `/mnt/zurg/__magic__/movies`, релизы лежат в `/mnt/zurg/__magic__/__all__/<release>`.

`_UNPACK_` и `_FAILED_` удаляются из имени папки перед разбором (`GetCleanedUpFolderName`, `:311-317`).

`IsFileLocked` **полностью пропускается, если есть элемент из клиента загрузок** (`:187-199`, `:295-304`). Проверка блокировки выполняется только при ручном сканировании или сканировании корневой папки. Шиму об этом беспокоиться не нужно.

---

## 8. Проверки здоровья {#8-the-health-checks}

Все три разделяются с SAB-клиентом и разобраны в [sabnzbd-client-contract.md §6](sabnzbd-client-contract.md). Что специфично для qBittorrent:

- **`RemotePathMappingCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs:59-173`)
  проходит по `client.GetStatus().OutputRootFolders`. Для qBittorrent это одна папка, которая вычисляется в
  `QBittorrent.cs:377-407`: глобальный `save_path`, который переопределяется или дополняется `savePath`
  настроенной категории (§1.5). Путь должен быть корректным **для ОС, на которой работает \*arr** (`:68-113`),
  и он должен **существовать на хосте \*arr** (`:115-158`). Писать в него не обязательно.
  `IsLocalhost` равен `Settings.Host == "127.0.0.1" || Settings.Host == "localhost"` (`:406`) и влияет только на то,
  какое из трёх сообщений об ошибке будет показано.
- **`DownloadClientRemovesCompletedDownloadsCheck`**
  (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:33-66`) выдаёт предупреждение, когда
  `GetStatus().RemovesCompletedDownloads` равно true, то есть всегда, когда вычисленный флаг из §1.4 равен true. Если
  `max_ratio_enabled` и `max_seeding_time_enabled` оставить выключенными (это уже делает рецепт из §3.5), проверка
  молчит.
- **`DownloadClientRootFolderCheck`** — единственное место, где два репозитория реально different. Sonarr
  предупреждает только тогда, когда корневая папка *совпадает* с выходной папкой, а Radarr также тогда, когда корневая папка
  *содержит* выходную. Полный разбор в [sabnzbd-client-contract.md §6.1](sabnzbd-client-contract.md). Практическое правило то же:
  не ставьте корневую папку на путь save path или выше него и не ставьте её внутрь него. Например, `/mnt/zurg/__magic__/tv`
  является соседней папкой для `/mnt/zurg/__magic__/__all__`.

## 9. Sonarr и Radarr — полная разница {#9-sonarr-vs-radarr--the-complete-diff}

Проверено попарным сравнением загруженных файлов (BOM и CRLF нормализованы).

| Файл | Различие |
|---|---|
| `QBittorrent.cs` | `TvCategory`→`MovieCategory`, `TvImportedCategory`→`MovieImportedCategory`, `RecentTvPriority`→`RecentMoviePriority`, `OlderTvPriority`→`OlderMoviePriority`, `RemoteEpisode`→`RemoteMovie`; `remoteEpisode.IsRecentEpisode()` → `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` (`:80`, `:137`). **Номера строк совпадают один к одному.** |
| `QBittorrentSettings.cs` | те же переименования; категория по умолчанию `"tv-sonarr"` → `"radarr"` (`:36`); токен в тексте подсказки `…EpisodeHelpText` → `…MovieHelpText`. Номера строк совпадают. |
| `QBittorrentProxyV2.cs` | переименование категории; `new[] { HttpStatusCode.Forbidden }` → `[HttpStatusCode.Forbidden]` (collection expression, Sonarr `:401` / Radarr `:400`); в Sonarr есть лишняя пустая строка на 13-й строке → **Sonarr N = Radarr N−1 для N ≥ 14**. |
| `QBittorrentProxyV1.cs` | переименование категории; то же смещение из-за пустой строки. |
| `QBittorrentProxySelector.cs` | лишний двойной пробел в конструкторе Sonarr (`:46`); пустая строка на 3-й строке → Sonarr N = Radarr N−1 для N ≥ 4. |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **побайтово идентичны.** |
| `TorrentClientBase.cs` | `RemoteEpisode`→`RemoteMovie` везде; Radarr при загрузке `.torrent` обрабатывает HTTP **410 Gone** так же, как 404 (`:175`), Sonarr обрабатывает только 404. В обоих файлах по 274 строки. |
| `QBittorrentFixture.cs` | те же тесты, но в другом порядке: `missingFiles_item_should_have_required_properties` находится в Sonarr `:296-315` и Radarr `:402-420`, и **у копии в Radarr нет атрибута `[Test]`** (`:401` пустая), поэтому там она никогда не запускается. Sonarr `:318-421` = Radarr `:297-400`; начиная с Sonarr `:423` Radarr = Sonarr − 1. В Sonarr 1000 строк, в Radarr 998. |
| `DiskScanService.cs` | `ExcludedExtrasSubFolderRegex`: в Radarr `sample[s]?`, в Sonarr `samples` (`:72` в обоих). Остальные три регулярных выражения идентичны. |
| сервисы импорта | `Series`/`Episode` против `Movie`; у Sonarr гейт выбора заголовка в `AggregateEpisodes` не имеет аналога в Radarr (§7.1). Оба отказываются принимать путь импорта, если это папка библиотеки, ещё до всего остального (Sonarr `:175-182`, Radarr `:183-190`), и разбирают имя папки уже после (Sonarr `:184`, Radarr `:195`); Radarr дополнительно ищет историю граббинга по `DownloadId` в этом месте (`:193-194`). |
| `ImportApprovedEpisodes.cs` / `ImportApprovedMovie.cs` | switch для `copyOnly` идентичен: Sonarr `:139-152` / Radarr `:116-129`. |
| `DiskTransferService.cs`, `DownloadClientBase.cs`, `DownloadEventHub.cs`, `Json.cs`, `HttpClient.cs`, `HttpRequestBuilder.cs` | общие, побайтово идентичные. |

Всё остальное в этом документе **побайтово идентично с точностью до Series/Movie** и относится к обоим файлам в одной и той же строке.

---

(Предыдущий перевод был отклонён: соотношение длины 0,07. Сохраните структуру в точности.)

## 10. Минимальные, но полные примеры payload {#10-minimal-but-complete-example-payloads}

### 10.1 `GET /api/v2/app/webapiVersion`

```
2.11.2
```

`Content-Type: text/plain`. Не JSON, без кавычек, перенос строки в конце не нужен.

### 10.2 `POST /api/v2/auth/login`

Тело запроса: `username=sonarr&password=hunter2`, `application/x-www-form-urlencoded`.

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8
Set-Cookie: SID=8f3c1c0e9a1f4d2f9c0b7a5e3d1f6b2a; path=/

Ok.
```

Неверные учётные данные: всё равно **200**, тело `Fails.`. Никогда не 401.

### 10.3 `GET /api/v2/app/preferences`

Читаются только десять ключей из §1.4; можно присылать и больше, они будут проигнорированы.

```json
{
  "save_path": "/mnt/zurg/__magic__/__all__",
  "queueing_enabled": true,
  "dht": true,
  "max_ratio_enabled": false,
  "max_ratio": -1,
  "max_ratio_act": 0,
  "max_seeding_time_enabled": false,
  "max_seeding_time": -1,
  "max_inactive_seeding_time_enabled": false,
  "max_inactive_seeding_time": -1
}
```

Жёсткие требования:

- `save_path` должен существовать как каталог **на хосте Sonarr/Radarr** (`RemotePathMappingCheck`, §8).
- `max_ratio_enabled: false` + `max_seeding_time_enabled: false` оставляет
  `RemovesCompletedDownloads` равным false, и это не даёт тесту подключения (§6.1, случай 5) и
  проверке состояния ругаться.
- `dht: true`, иначе магнет-ссылки без трекеров будут отклоняться на стороне клиента (§6.5).
- `max_ratio_act` должен быть **целым числом** (§0.6).

### 10.4 `GET /api/v2/torrents/categories`

```json
{
  "tv": { "name": "tv", "savePath": "" },
  "movies": { "name": "movies", "savePath": "" }
}
```

JSON **объект**, `savePath` в **camelCase**, никогда не начинается с `//` (§1.5). Пустой `savePath`
оставляет корневую папку вывода в глобальном `save_path`.

### 10.5 `GET /api/v2/torrents/info?category=tv` — один загружается, один готов к импорту {#105-get-apiv2torrentsinfocategorytv--one-downloading-one-importable}

```json
[
  {
    "hash": "cbc2f069fe8bb2f544eae707d75bcd3de9dcf951",
    "name": "Some.Show.S01E02.1080p.WEB.h264-GRP",
    "size": 1073741824,
    "progress": 0.0,
    "eta": 8640000,
    "state": "metaDL",
    "category": "tv",
    "save_path": "/mnt/zurg/__magic__/__all__",
    "content_path": "",
    "ratio": 0,
    "ratio_limit": 0,
    "seeding_time_limit": -2,
    "inactive_seeding_time_limit": -2,
    "last_activity": 1756252800,
    "added_on": 1756252800,
    "completion_on": 0,
    "amount_left": 1073741824,
    "downloaded": 0,
    "uploaded": 0,
    "dlspeed": 0,
    "upspeed": 0,
    "num_seeds": 0,
    "num_leechs": 0,
    "priority": 0,
    "force_start": false,
    "seq_dl": false,
    "f_l_piece_prio": false,
    "super_seeding": false,
    "auto_tmm": false,
    "tags": ""
  },
  {
    "hash": "3b1a1469c180f447b77021074dbbccaef62611e7",
    "name": "Some.Show.S01E03.1080p.WEB.h264-GRP",
    "size": 1073741824,
    "progress": 1.0,
    "eta": 8640000,
    "state": "pausedUP",
    "category": "tv",
    "save_path": "/mnt/zurg/__magic__/__all__",
    "content_path": "/mnt/zurg/__magic__/__all__/Some.Show.S01E03.1080p.WEB.h264-GRP",
    "ratio": 0,
    "ratio_limit": 0,
    "seeding_time_limit": -2,
    "inactive_seeding_time_limit": -2,
    "last_activity": 1756252800,
    "added_on": 1756252200,
    "completion_on": 1756252800,
    "amount_left": 0,
    "downloaded": 1073741824,
    "uploaded": 0,
    "dlspeed": 0,
    "upspeed": 0,
    "num_seeds": 0,
    "num_leechs": 0,
    "priority": 0,
    "force_start": false,
    "seq_dl": false,
    "f_l_piece_prio": false,
    "super_seeding": false,
    "auto_tmm": false,
    "tags": ""
  }
]
```

Жёсткие требования:

- JSON-**массив** (`List<QBittorrentTorrent>`); объект выбрасывает исключение внутри `GetTorrents` и проваливает
  `TestGetTorrents` (§6.4).
- `hash` в **нижнем регистре** (§1.8) и точно совпадать с infohash, который \*arr вычислил из magnet-ссылки или
  `.torrent` (§1.7).
- `size` в **байтах**; `progress` — доля от 0 до 1. `RemainingSize = size × (1 − progress)`.
- `eta: 8640000` читается как «unknown» и даёт null в `RemainingTime` (`:622-625`); элемент со статусом Completed
  всё равно получает `TimeSpan.Zero` (`:273`).
- `state` берётся из таблицы §2, регистр точно такой же.
- `content_path` на элементах Completed должен быть **абсолютным, существующим и ≠ `save_path`** (§4.1). Он может быть пустым,
  пока элемент не в состоянии Completed.
- `ratio_limit: 0` + `ratio: 0` — это рецепт перемещения (§3.5).
- `category` должна совпадать с настроенной в клиенте категорией; клиент повторно не фильтрует, поэтому учитывайте
  параметр запроса.
- `seeding_time` можно вообще не возвращать — клиент откатывается к `torrents/properties`, и только
  когда действительно действует ограничение по времени раздачи.

### 10.6 `GET /api/v2/torrents/properties?hash=<hash>`

```json
{
  "hash": "3b1a1469c180f447b77021074dbbccaef62611e7",
  "save_path": "/mnt/zurg/__magic__/__all__",
  "seeding_time": 0,
  "total_size": 1073741824,
  "addition_date": 1756252200,
  "completion_date": 1756252800,
  "eta": 8640000,
  "dl_limit": -1,
  "up_limit": -1
}
```

Читаются только `save_path` и `seeding_time` (§1.8). **404 для неизвестного хеша** — так `IsTorrentLoaded` сообщает «пока нет» (`:110-126`).

### 10.7 `GET /api/v2/torrents/files?hash=<hash>`

```json
[
  { "index": 0, "name": "Some.Show.S01E03.1080p.WEB.h264-GRP/ep3.mkv", "size": 1073741824, "progress": 1, "priority": 1, "is_seed": true, "piece_range": [0, 2047], "availability": 1 }
]
```

Читается только `name`, относительно `save_path`, с разделителями `/` (§1.13). Порядок важен для пути до 2.6.1: верхний компонент `files[0]` становится выходной папкой.

### 10.8 `POST /api/v2/torrents/add`

Запрос, urlencoded-форма (длинный magnet приходит как multipart, см. §0.3):

```
urls=magnet%3A%3Fxt%3Durn%3Abtih%3A3B1A...&category=tv&stopped=False
```

Ответ:

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8

Ok.
```

Любой ответ, кроме буквального `Fails.`, означает успех (§1.7). Пустое тело ответа с кодом 200 тоже работает.

### 10.9 `POST /api/v2/torrents/delete`

Запрос: `hashes=3b1a1469c180f447b77021074dbbccaef62611e7&deleteFiles=true`

Ответ: `HTTP/1.1 200 OK`, пустое тело. **200 и для неизвестного хеша тоже** (§5.2).

### 10.10 `POST /api/v2/torrents/createCategory`, `setCategory`, `setShareLimits`, `topPrio`, `setForceStart`

Все принимают данные в формате urlencoded и отвечают `200` с пустым телом. `topPrio` может ответить **409**, что означает «очередь отключена». Клиент проглатывает именно этот статус (§1.10). `setShareLimits` может ответить **404**, что означает «не поддерживается». Этот статус тоже проглатывается (§1.9).

## 11. Отличия от настоящего qBittorrent — где модель zurg уже или шире {#11-differences-from-real-qbittorrent--where-zurgs-model-is-narrower-or-wider}

### 11.1 Раздачи нет, поэтому ограничение по seed-limit нужно имитировать {#111-there-is-no-seeding-so-the-seed-limit-gate-has-to-be-faked}

Настоящий qBittorrent вычисляет `ratio` по байтам, которые реально были отданы, и позволяет пользователю задать глобальный или
индивидуальный лимит для торрента. Защита `CanMoveFiles` в клиенте нужна, чтобы не выдернуть файлы из-под торрента, который ещё отрабатывает свой лимит рейтинга (`QBittorrent.cs:240-241`). Бэкенд дебрида не отдаёт ничего, никогда. Поэтому shim объявляет `ratio: 0, ratio_limit: 0`, то есть индивидуальный лимит уже выполнен. Это честно в единственном смысле, в котором это поле здесь вообще может быть честным, и при этом глобальные настройки в него не попадают вовсе (§3.5).

### 11.2 `content_path` всегда папка, никогда не файл {#112-content_path-is-always-a-folder-never-a-file}

Настоящий `contentPath()` в qBittorrent возвращает **путь к файлу** для торрента из одного файла (`torrentimpl.cpp:582-583`). При `__magic__` каждый релиз — это папка с его файлами ([magic.md](../guides/magic.md#with-nothing-stored-it-is-__all__s-releases-as-real-folders)), в том числе релиз из одного файла.

Последствия, и все они в пользу клиента:

- `ProcessPath` всегда идёт по ветке для **папки** (`DownloadedEpisodesImportService.cs:80-90`) и никогда по ветке для файла (`:92-102`). Ветка для папки применяет `FilterPaths`, `ShouldDeleteFolder` и разбор имени папки, так что фильтр экстрас и запасной вариант с названием из папки всегда работают.
- Отказы `ProcessFile` для отдельных файлов (опасное, исполняемое или неподдерживаемое расширение, префикс `._`; §7.4) всё ещё возможны, но теперь через фильтр расширений в `GetVideoFiles`, а не через верхнюю ветку.
- Старый обход `GetImportItem` до версии 2.6.1 (§4.2) тоже сработал бы, так как `files[0].name` всегда содержит папку релиза, но нет причин указывать такую старую версию.

Одно, что важно понять: поскольку это всегда папка, `content_path` всегда равен `save_path + "/" + <release folder>` и поэтому никогда не совпадает с `save_path`. Предупреждение `DownloadClientQbittorrentTorrentStatePathError` (§4.1) структурно недостижимо, и это правильный результат, а не случайность, на которую стоит полагаться.

### 11.3 `name` — это не название раздачи, и оно может меняться {#113-name-is-not-the-grabbed-title-and-it-can-change}

Настоящий qBittorrent берёт имя из метаданных торрента, и оно не меняется. Имя zurg берётся из библиотеки:

- Real-Debrid переименовывает релизы, в именах которых срабатывает его блокировка 451 (`WEB-DL`, теги `Rip` и несколько пар источник-кодек через точку, по замерам на 2026-10-14). См. раздел RD 451 в монорепозитории `CLAUDE.md`.
- zurg добавляет суффикс, если два релиза сталкиваются по одному имени, а восстановление пересобирает релиз под новым id торрента.
- Имя читается из библиотеки при каждом опросе, поэтому оно может измениться **между опросами** для id, который \*arr уже отслеживает.

Ничто из этого не ломает отслеживание, потому что оно привязано к `DownloadId` (инфохешу), а не к имени. А вот путь разбора названий из §7.1 как раз ломается. Отсюда два правила:

1. **Привязывайтесь к инфохешу, который вычислил \*arr**, и никогда не к тому, что внутреннее для zurg. Это единственная связка между захватом, историей захватов и опросом.
2. **Следите, чтобы имя папки `__magic__` оставалось разбираемым**, потому что это запасной вариант, который читает ветка по папкам (`DownloadedEpisodesImportService.cs:184`).

### 11.4 Нет прогресса и нет фазы метаданных {#114-there-is-no-progress-and-no-metadata-phase}

Здесь нечего скачивать, поэтому нет смысла в `progress`, `eta`, `dlspeed` или `metaDL`. Это то же ограничение, что описано для эндпоинта SAB ([sabnzbd.md](../guides/sonarr-radarr.md), *What works, and what does not*: «No progress. A job is queued or it is completed»). Логичное соответствие такое: **Queued** (`queuedDL`), пока библиотека ещё не показывает релиз, и **Completed** (`pausedUP`), когда он появился *и размеры файлов устаканились*. Значение `size` берём из того, что сообщает бэкенд, чтобы запись в очереди не была пустой.

Не используйте `metaDL` для состояния ожидания, если только не передано `dht: true`. Только в этом случае это Queued (`:288-297`). `queuedDL` ставится безусловно и без сообщения.

Не используйте `stalledDL`, `error` или `missingFiles` для временного ожидания: все три относятся к **Предупреждениям** (§2) и попадают в очередь как проблемы.

### 11.5 Удаление скрывает, а не уничтожает {#115-deleting-hides-it-does-not-destroy}

`torrents/delete?deleteFiles=true` на настоящем qBittorrent удаляет торрент и делает `rm -rf` над его данными.
Здесь он должен удалить только запись: релиз по-прежнему отдаётся из торрента у провайдера, а
папка, которую хотел получить \*arr, уже сама себя пометила как tombstone через монтирование (§5.2,
[magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)). Именно такой ход мысли зафиксирован в `internal/sabnzbd`, в функции `deleteFromHistory`: `internal/sabnzbd/api.go:596-609`.

### 11.6 Всё, что клиент может запросить, но к чему нечего применить {#116-everything-the-client-can-ask-for-that-has-nothing-to-apply-to}

`sequentialDownload`, `firstLastPiecePrio`, `contentLayout`, `stopped`/`paused`, `setForceStart`,
`topPrio`, `setShareLimits`, `dlLimit`/`upLimit`: принимаем их, отвечаем 200, ничего не применяем. Только два
имеют заметные последствия, если их отклонить: `topPrio` (409 молча проглатывается, остальные коды дают предупреждение)
и `setShareLimits` (404 молча проглатывается). Ни один из них не блокирует граб.

Пара слов про `contentLayout`: эта настройка в \*arr нужна именно для того, чтобы заставить qBittorrent
оставлять папку верхнего уровня, чтобы `content_path != save_path`. При `__magic__` раскладка всегда
папочная в любом случае (§11.2), так что параметр ничего не делает, и оператор может оставить его на Default.

---

## 12. Чеклист реализации (14 пунктов) {#12-implementation-checklist-14-points}

1. **Только API v2.** Отвечай на `/api/v2/app/webapiVersion` значением `2.11.2`, а на `/version/api` возвращай **404**, чтобы проверка v1 чисто проваливалась.
2. **Авторизация:** принимай заголовок `Authorization: Bearer <key>`, упреждающий `Authorization: Basic`, куку `SID` или вообще ничего. На `POST /api/v2/auth/login` отвечай **200 + `Ok.` + `Set-Cookie: SID=…`**. При неверных данных отвечай `Fails.` (тоже с 200), а не 401. Не требуй `Referer` и `Origin`.
3. **Ошибки это HTTP-статусы, а не JSON.** 403 означает «войди заново», и запрос повторяется один раз. Второй 403 должен попадать наверх как ошибка соединения, а не ошибка авторизации. 404 имеет смысл для `torrents/properties` (неизвестный hash) и `torrents/setShareLimits` (не поддерживается). 409 имеет смысл для `torrents/topPrio` (очередь выключена). Всё остальное должно возвращать 200.
4. **Разбирай обе кодировки формы в `torrents/add`:** urlencoded и multipart (когда какое-то значение больше 1024 байт или загружается `.torrent`). Принимай `True`/`False`, а также `true`/`false`, для каждого булева значения.
5. **`torrents/info` возвращает массив, `torrents/categories` возвращает объект** с camelCase `savePath`. Уважай query-параметр `category`, клиент повторно не фильтрует.
6. **Hash: в любом ответе строчными, в любом запросе сравнивай без учёта регистра**, и это всегда тот infohash, который \*arr посчитал из magnet или `.torrent`. `torrents/properties` единственный маршрут, который может получить hash в том регистре, в котором его вернул `torrents/info`.
7. **Рецепт перемещения:** `state: "pausedUP"`, `ratio: 0`, `ratio_limit: 0`, `seeding_time_limit: -2`, `inactive_seeding_time_limit: -2`. Если поставить меньше, импорт станет **копированием**, то есть полной загрузкой релиза. Обязательно напиши в документации, что настройка \*arr "Remove Completed" должна оставаться включённой, потому что шим не может это компенсировать.
8. **`content_path` должен быть абсолютным, существовать на хосте \*arr и не совпадать с `save_path`.** Задавай его, только когда релиз действительно готов к импорту: он перечислен, а размеры файлов устоялись. Пока этого нет, возвращай `queuedDL` и дай клиенту продолжать опрос. Лимита на повторы нет.
9. **`save_path`** (из `app/preferences` плюс любой `savePath` категории) должен существовать как каталог на хосте \*arr, иначе `RemotePathMappingCheck` выдаст ошибку. Писать в него не обязательно. Никогда не выдавай `savePath`, который начинается с `//`.
10. **Держи тест соединения зелёным:** `dht: true`, `queueing_enabled: true`, `max_ratio_enabled: false`, `max_seeding_time_enabled: false`, `max_ratio_act: 0` (целое число). Либо заранее создай настроенные категории, либо обрабатывай `createCategory` и отражай его в самом следующем ответе `torrents/categories`.
11. **`torrents/delete` удаляет только запись и ничего больше.** Игнорируй `deleteFiles` для торрента провайдера, точно так же как `deleteFromHistory` в `internal/sabnzbd` игнорирует `del_files` (`internal/sabnzbd/api.go:596-609`). На неизвестный hash отвечай 200. Принимай `setCategory` и записывай новую категорию.
12. **Жди, что \*arr сам выполнит `rm -rf` папки релиза** после импорта Move (`DownloadedEpisodesImportService.cs:209-223`). Эта папка превратится в `__magic__`-tombstone. После этого \*arr вызовет `torrents/delete`. Оба действия нормальны, ничего при этом не уничтожается.
13. **Используй только имена состояний из §2, с точным регистром.** Неизвестное имя здесь не вызывает исключение (в отличие от SAB), но пишется в лог и по умолчанию считается Downloading. Никогда не используй `stalledDL`, `error` или `missingFiles` для временного ожидания: все три это Warnings.
14. **Не ставь корневую папку на уровень выше выходной папки или на саму выходную папку.** Если `save_path` = `/mnt/zurg/__magic__/__all__`, используй `/mnt/zurg/__magic__/tv` и `/mnt/zurg/__magic__/movies` как корневые папки, а релизы держи в `/mnt/zurg/__magic__/__all__/<release>`. Иначе `SeriesPathExists`/`MoviePathExists` сразу откажет в импорте (§7.4), а `DownloadClientRootFolderCheck` в Radarr будет ругаться при каждом запуске.
