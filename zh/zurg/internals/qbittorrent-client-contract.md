# qBittorrent Web API 约定（Sonarr 和 Radarr 所用，develop 分支） {#qbittorrent-web-api-contract-as-consumed-by-sonarr-and-radarr-develop}

事实依据：从 `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...` 以及 `qbittorrent/qBittorrent/master` 获取的文件，获取日期为 **2026-08-27**。下面每个行号都是从这些文件中读出的。

这是 [sabnzbd 客户端契约文档](sabnzbd-client-contract.md) 的 torrent 对应文档。该文档记录了 `internal/sabnzbd` 为什么要以现在的结构返回响应；本文则是在编写 qBittorrent shim *之前*它必须满足的规格，以确保抓取、轮询、**以移动方式**导入，以及导入后的清理，在两个客户端中都能正常工作。两个客户端共用的机制（HTTP 层、JSON 序列化器、`DiskTransferService`、健康检查）在本文中引用相同的行号并回指原文，而不重复分析。

除非某个小节另有说明，**两个仓库的 qBittorrent 文件除了 `Tv*` → `Movie*` 的重命名外完全相同**，并且：

| 文件 | 行号 |
|---|---|
| `QBittorrent.cs`（两边都是 746 行） | **逐行一一对应** |
| `QBittorrentPreferences.cs`、`QBittorrentTorrent.cs`、`QBittorrentState.cs`、`QBittorrentLabel.cs`、`QBittorrentPriority.cs`、`QBittorrentContentLayout.cs` | **字节完全相同**，逐行一一对应 |
| `QBittorrentSettings.cs`（两边都是 91 行） | 逐行一一对应 |
| `QBittorrentProxyV2.cs`、`QBittorrentProxyV1.cs` | Sonarr 在第 13 行有一个空行，Radarr 没有（已核实：Sonarr 的 `:12` 是 `// API https://…` 注释，`:13` 为空行，`:14` 是 `public class QBittorrentProxyV2`；Radarr 的类声明在 `:13`）。**对于 N ≥ 14，Sonarr 第 N 行 = Radarr 第 N−1 行。** |
| `QBittorrentProxySelector.cs` | 同上，从第 3 行开始 |
| `QBittorrentFixture.cs` | 顺序不同，但不是行号偏移——按仓库分别引用 |

两边的路径都是 `src/NzbDrone.Core/Download/Clients/QBittorrent/...`。除非另有标注，下面的引用均为 **Sonarr** 行号。完整差异见 §9。

这里没有关于 qBittorrent 本身的猜测：每一条论断都是*客户端*的实际行为。如果论断涉及 qBittorrent 自身的行为，会引用 `qbittorrent/qBittorrent` master；如果涉及 .NET 或 Newtonsoft 运行时的语义，会明确说明。

---

## 0. 传输层规则（这些规则最先生效） {#0-transport-level-rules-these-bite-first}

### 0.1 客户端在做任何事之前先选择 v1 或 v2 {#01-the-client-picks-v1-or-v2-before-it-does-anything-else}

`QBittorrentProxySelector.FetchProxy`（`QBittorrentProxySelector.cs:80-95`）：

```csharp
if (_proxyV2.IsApiSupported(settings)) { return Tuple.Create(_proxyV2, _proxyV2.GetApiVersion(settings)); }
if (_proxyV1.IsApiSupported(settings)) { return Tuple.Create(_proxyV1, _proxyV1.GetApiVersion(settings)); }
throw new DownloadClientException("Unable to determine qBittorrent API version");
```

`QBittorrentProxyV2.IsApiSupported`（`QBittorrentProxyV2.cs:28-70`）会发一个**未认证**的 `GET /api/v2/app/webapiVersion`，并设置 `SuppressHttpError = true`，然后根据结果判断：

| 响应 | 结果 |
|---|---|
| `404` | 不是 v2 → 回退到 v1 |
| `403` | **支持 v2**（`:44-47`）。这是"还没登录"的回应 |
| `401` | `DownloadClientException("Failed to connect to qBittorrent. Check your settings and qBittorrent configuration.")`（`:49-52`） |
| 其他任何 `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")`（`:54-57`） |
| `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to qBittorrent, certificate validation failed.")`（`:63-66`） |
| `200` | 支持 v2 |

`QBittorrentProxyV1.IsApiSupported`（`QBittorrentProxyV1.cs:27-59`）做的事情相同，只是请求的是 `GET /version/api`。注意这里**没有开头的 `/api/v2`**，而且 401 在 v1 里**没有**被特殊处理。

这一对 `(proxy, version)` 会以 `{Host}_{Port}` 为键缓存 **10 分钟**（`QBittorrentProxySelector.cs:68-78`）。`GetProxy(settings, force: true)` 会清掉这个缓存。连接测试就是这样做的（`QBittorrent.cs:435`、`:519`），Sonarr 和 Radarr 的 fixture 也对此做了断言（Sonarr `QBittorrentFixture.cs:986-998`，Radarr `:984-996`）。

**shim 应该响应 `/api/v2/app/webapiVersion`，并且永远不要暴露 v1 路由。** v1 是 4.1 之前的 API（`/version/api`、`/query/torrents`、`/command/download`、…）。对新的实现来说它只是累赘，而且它根本无法满足导入流程：`GetLabels` 会抛出 `NotSupportedException("qBittorrent api v1 does not support getting all torrent categories")`（`QBittorrentProxyV1.cs:236-239`），`SetTorrentSeedingConfiguration` 则是个空操作（`:241-244`）。本文档其余部分只讲 API v2。§1.17 列出了 v1 路由表，供参考。

### 0.2 URL 结构 {#02-url-shape}

`QBittorrentProxyV2.BuildRequest` (`QBittorrentProxyV2.cs:341-359`):

```csharp
var requestBuilder = new HttpRequestBuilder(settings.UseSsl, settings.Host, settings.Port, settings.UrlBase)
{
    LogResponseContent = true,
    StoreRequestCookie = false
};
```

- 基础 URL：`HttpRequestBuilder.BuildBaseUrl`（`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-65`）
  = `{http|https}://{Host}:{Port}{UrlBase}`；如果缺少前导 `/`，就会给 `UrlBase` 自动补上。
- `Resource("/api/v2/…")`（`HttpRequestBuilder.cs:244-256`）会去掉前导 `/` 再拼接，所以完整 URL 是 `{scheme}://{host}:{port}{urlBase}/api/v2/{group}/{method}`。
- **没有 `Accept` 请求头。** `BuildRequest` 从不调用 `.Accept(...)`，而 `HttpRequest` 的构造函数只有在 `httpAccept != null` 时才会设置 `Headers.Accept`（`src/NzbDrone.Common/Http/HttpRequest.cs:14,30-32`）。不要把 `Accept` 当作判断条件。
- `StoreRequestCookie = false`：Cookie 存储由代理管理，而不是由 HTTP 层管理。

### 0.3 GET 带查询参数 与 POST 带表单 — 以及何时表单变为 multipart {#03-get-with-query-vs-post-with-form--and-when-the-form-becomes-multipart}

只读调用会在 GET 上使用 `AddQueryParam`（`HttpRequestBuilder.cs:306-317`）。会修改数据的调用则使用
`.Post()` 加上 `AddFormParameter` / `AddFormUpload`。

`ApplyFormData`（`HttpRequestBuilder.cs:150-242`）负责选择编码方式：

```csharp
var shouldSendAsMultipart = FormData.Any(v => v.ContentType != null || v.FileName != null || v.ContentData.Length > 1024);
```

- 只要用了 `AddFormUpload`（它会设置 `FileName` 和 `ContentType`），就会强制使用 **`multipart/form-data`**（`:379-395`、`:220`）。
- **只要某个表单值超过 1024 字节，同样会强制使用 multipart**（`:162`）。tracker 列表很长的磁力链接就会超过这个限制，所以 `POST /api/v2/torrents/add` 到达时的格式取决于磁力链接本身，可能是 `application/x-www-form-urlencoded`，*也可能是* `multipart/form-data`。**在这条路由上，shim 必须两种格式都能解析。**
- 其他情况：使用 `application/x-www-form-urlencoded`，值通过 `Uri.EscapeDataString(Encoding.UTF8.GetString(...))` 转义（`:230`）。

multipart 写入器是手写的（`:164-227`），它会写入 `Content-Disposition: form-data; name="…"`（上传时还会加上 `; filename="…"` 和一行 `Content-Type:`），然后是一个空行、原始字节，最后是 `\r\n`。分隔符是 `-----------------------------{ticks:x14}`（`:166`）。

**布尔值的格式很容易踩坑。** `AddFormParameter` 存储的是 `Convert.ToString(value, CultureInfo.InvariantCulture)`（`HttpRequestBuilder.cs:373`），而 .NET 的 `Convert.ToString(bool)` 输出的是 **`"True"` / `"False"`，首字母大写**。所以 `request.AddFormParameter("stopped", false)`（`QBittorrentProxyV2.cs:258`）实际发出去的是 `stopped=False`，而不是 `stopped=false`。真正的 qBittorrent 能正常处理，是因为 `Utils::String::parseBool`（`src/base/utils/string.cpp:108-116`）是不区分大小写比较的。**shim 必须同时接受 `True`/`False` 和 `true`/`false`。** 客户端硬编码字符串的地方是小写的：`deleteFiles` 是 `"true"`（`QBittorrentProxyV2.cs:198`），`setForceStart` 的 `value` 是 `"true"`/`"false"`（`:337`）。所以两种写法确实都会出现。

数字走的是同样的 invariant-culture 路径，所以 `ratioLimit=1.5` 的小数点始终是 `.`（`QBittorrentProxyV2.cs:234`、`HttpRequestBuilder.cs:373`）。

### 0.4 身份验证 — 三层，可以同时生效 {#04-authentication--three-layers-all-of-which-can-be-live-at-once}

`BuildRequest`（`QBittorrentProxyV2.cs:349-356`）：

```csharp
if (settings.ApiKey.IsNotNullOrWhiteSpace())
    requestBuilder.Headers["Authorization"] = $"Bearer {settings.ApiKey}";
else if (settings.Username.IsNotNullOrWhiteSpace() || settings.Password.IsNotNullOrWhiteSpace())
    requestBuilder.NetworkCredential = new BasicNetworkCredential(settings.Username, settings.Password);
```

1. **API key** → 每个请求都会带上 `Authorization: Bearer <key>`。`ProcessRequest` 还有一条短路路径，完全不会登录（`:371-395`）。`QBittorrentSettingsValidator` 不允许同时填写 username/password 和 key（`QBittorrentSettings.cs:16-21`）。
2. **Username/password** → `BasicNetworkCredential` 会被 `ManagedHttpDispatcher` 转成**预先发送**的 `Authorization: Basic base64(user:pass)` 头。每个请求都会带上，包括 `auth/login` 本身（`src/NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:81-89`，注释原文："Manually set header to avoid initial challenge response"）。
3. **Cookie 会话** → `AuthenticateClient`（`QBittorrentProxyV2.cs:430-494`）。

`AuthenticateClient` 的完整代码如下：

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

对 shim 来说，有以下几点影响：

- `POST /api/v2/auth/login`，请求体是 `username=…&password=…`，类型为 `application/x-www-form-urlencoded`。
- 返回 **HTTP 200**，响应体正好是 `Ok.`，并带上 `Set-Cookie: SID=…` 头。这和真正的 qBittorrent 一样（wiki 的 *Login* 页面写道："Upon success, the response will contain a cookie with your SID"）。
- **空响应体也可以接受**（`:479` 会通过 `IsNotNullOrWhiteSpace` 直接跳过）。其他任何内容（`"Fails."`、`"ok"`、JSON）都会被当作认证失败。v1 代理更严格，要求必须正好是 `Ok.`（`QBittorrentProxyV1.cs:371`）。
- `auth/login` 返回 HTTP 错误时：401 或 403 会抛出 `DownloadClientAuthenticationException`，其他情况抛出 `DownloadClientException`（`:463-473`）。`WebException` 则抛出 `DownloadClientUnavailableException`。
- cookie 会按 `{baseUrl}:{user}:{pass}` 缓存。缓存条目在进程的生命周期内有效，只有请求返回 403 时才会刷新（§0.5）。
- **从不发送 `Referer` 和 `Origin`。** wiki 让 API 调用方设置它们（"Note: Set `Referer` or `Origin` header to the exact same domain and port as used in the HTTP query `Host` header"），但 Sonarr 并没有设置。shim 不能要求它们。
- 如果**完全没有配置任何凭据**，`AuthenticateClient` 会直接返回，什么都不会发送：没有登录、没有 cookie，也没有 `Authorization`。不带认证的 shim 也能正常工作。

### 0.5 哪些 HTTP 状态码被视为错误 {#05-which-http-statuses-are-treated-as-errors}

`HttpClient.Execute`（`src/NzbDrone.Common/Http/HttpClient.cs:106-121`）在 `response.HasHttpError` 为真时抛出异常，即 `(int)StatusCode >= 400`（`src/NzbDrone.Common/Http/HttpResponse.cs:54`），除非设置了 `SuppressHttpError`，或者状态码在 `SuppressHttpErrorStatusCodes` 里。429 会变成 `TooManyRequestsException`（`:115`）；其他情况都是 `HttpException`（`:119`）。

`QBittorrentProxyV2.ProcessRequest`（`:369-428`）随后会把它包装一层。有两条不同的路径：

**API 密钥路径**（`:371-395`）：

| 状态码 | 结果 |
|---|---|
| 401、403 | `DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.")` |
| 其他任何 `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` |
| 其他任何抛出的异常 | `DownloadClientException("Failed to connect to qBittorrent, please check your settings.")` |

**Cookie 路径**（`:397-427`）：

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

- **403 的意思是“会话过期，请重新登录”**。它会被抑制一次，客户端重新登录后再重试。这正是 qBittorrent 自己会话过期时的循环，shim 也可以照这个方式利用它。
- **重试请求是从 builder 重新构建的**，而 builder 上没有 `SuppressHttpErrorStatusCodes`。这个字段是在 `:401` 设置在*请求*上的，不是 builder 上的。所以第二次 403 会抛出 `HttpException`，最终变成 `DownloadClientException("Failed to connect to qBittorrent, check your settings.")`，**而不是认证失败**。如果 shim 一直返回 403，界面上显示的会是令人困惑的连接错误，而不是“Authentication Failure”。
- 如果没有配置凭据，`:411` 的重新登录尝试会直接抛出 `DownloadClientAuthenticationException`（`:434-437`）。

**每一次成功的调用都必须返回 HTTP 200，并且响应体要完全符合客户端的预期。** 这个 API 中没有任何 JSON 错误信封。和 SAB 不同，这里的错误全部通过 HTTP 状态码体现。

### 0.6 反序列化器设置 {#06-deserializer-settings}

所有 qBittorrent 的数据负载都经过 `NzbDrone.Common.Serializer.Json`（`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`），用的是 **Newtonsoft**，和 SAB 客户端用的是同一个实例，所以 [SAB 客户端契约 §0.3](sabnzbd-client-contract.md) 完全适用：

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

对 qBittorrent 模型来说，具体含义如下：

| 模型成员 | 绑定到 | 原因 |
|---|---|---|
| `QBittorrentTorrent.Hash/Name/Size/Progress/Eta/State/Label/Category/Ratio` | `hash`、`name`、`size`、`progress`、`eta`、`state`、`label`、`category`、`ratio` | camelCase 解析器；Newtonsoft 也会忽略大小写进行匹配 |
| `SavePath`、`ContentPath`、`RatioLimit`、`SeedingTime`、`SeedingTimeLimit`、`InactiveSeedingTimeLimit`、`LastActivity` | `save_path`、`content_path`、`ratio_limit`、`seeding_time`、`seeding_time_limit`、`inactive_seeding_time_limit`、`last_activity` | 显式的 `[JsonProperty]`（`QBittorrentTorrent.cs:24-45`） |
| `QBittorrentLabel.Name/SavePath` | `name`、`savePath` | **没有** `[JsonProperty]`，走 camelCase 解析器。qBittorrent 的 `torrents/categories` 接口在这里确实用的是 camelCase，和其他接口都不一样 |
| `QBittorrentPreferences.*` | 全部是显式的 `[JsonProperty]` snake_case（`QBittorrentPreferences.cs:16-44`） | |
| `QBittorrentMaxRatioAction` | `max_ratio_act` | 没有单独的属性转换器，所以全局的 `StringEnumConverter` 会生效。`AllowIntegerValues` 默认为 true，所以**要发送整数**，和真正的 qBittorrent 一样。如果发字符串，就得用 camelCase（`"pause"`、`"remove"`），而且遇到不认识的名称会直接抛异常 |

`NullValueHandling.Ignore` 在**读取**时也生效：JSON 里的 `null` 会让成员保留构造函数里设定的值。加上模型里声明的默认值，**缺失或为 null 的字段**和值为 0 是不一样的：

| 字段 | 缺失或为 null 时的默认值 | 出处 |
|---|---|---|
| `ratio_limit` | `-2f` | `QBittorrentTorrent.cs:33` |
| `seeding_time_limit` | `-2` | `:39` |
| `inactive_seeding_time_limit` | `-2` | `:42` |
| `seeding_time` | `null`（`long?`） | `:36` |
| `queueing_enabled` | **`true`** | `QBittorrentPreferences.cs:41` |
| 其他所有字段 | CLR 默认值（`0`、`false`、`null`） | |

`Eta` 的类型是 `System.Numerics.BigInteger`（`QBittorrentTorrent.cs:17`，注释写着 "QBit contains a bug exceeding ulong limits"）。Sonarr 的测试夹具里固定了 `18446744073709335000` 可以被正常解析（Sonarr `QBittorrentFixture.cs:974-984`，Radarr `:973-982`）。

`Json.Deserialize<T>` 会重新抛出 `JsonReaderException`，但消息更友好（`Json.cs:39-50`）。所有 qBittorrent 代理调用都没有使用 `TryDeserialize`，所以**格式错误或结构不对的响应体会直接从代理里抛出**，在调用处变成未处理的异常。以 `GetItems()` 为例，这会让整个轮询直接中断。

### 0.7 所有 `version >=` 判断，集中一览 {#07-every-version--gate-in-one-place}

`ProxyApiVersion` 就是 `_proxySelector.GetApiVersion(Settings)`（`QBittorrent.cs:50`），也就是缓存的 `app/webapiVersion`。各个判断条件如下：

| 门槛 | 位置 | 低于门槛时的影响 |
|---|---|---|
| `>= 1.5` | `QBittorrent.cs:436` | 测试失败："qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| `>= 1.6` | `:445` | 如果配置了分类，测试失败："Category is not supported" |
| `>= 2.0` | `:379`（`GetStatus`）、`:520`（`TestCategory`） | 不会读取分类的 `savePath`，分类也不会被检查或创建 |
| `>= 2.6.1` | `:314` | `OutputPath` **不会**从 `content_path` 获取；`GetImportItem` 改为遍历 `torrents/files`（见 §4.2） |
| `>= 2.8.1` | `:79`、`:136` | 分享限制无法随 `torrents/add` 一起提交，只能之后通过 `torrents/setShareLimits` 应用 |
| `>= 2.11.0` | `QBittorrentProxyV2.cs:253` | `torrents/add` 发送的是 `paused=`，而不是 `stopped=` |

`Version.Parse`（`QBittorrentProxyV2.cs:75`）至少需要 **`major.minor`** 格式。如果只给一个 `"2"`，会抛出 `FormatException`。这个异常是在代理里所有 `try` 之外抛出的，所以会直接穿透 `GetApiVersion`。建议填写类似 `2.11.2` 的版本号。

**shim 的推荐值：`2.11.2`。** 它能通过所有门槛判断，让 `content_path` 走 `torrents/info` 这条导入路径（这是唯一合理的导入方式），并在添加时使用 qBittorrent 5.x 的 `stopped=` 写法。

## 1. 所有端点，按客户端的调用顺序列出 {#1-every-endpoint-in-the-order-the-client-calls-them}

接口：`IQBittorrentProxy`（`QBittorrentProxySelector.cs:9-30`）。实现：`QBittorrentProxyV2`。`QBittorrent.cs` 中的每个调用位置都列在 `:49-741`。

### 1.1 `GET /api/v2/app/webapiVersion` — `GetApiVersion`（`QBittorrentProxyV2.cs:72-78`） {#11-get-apiv2appwebapiversion--getapiversion-qbittorrentproxyv2cs72-78}

请求:无参数。先以未认证方式发送(作为探测,见 §0.1),然后再以已认证方式发送。

响应:**纯文本**,即由 `Version.Parse` 解析的版本字符串。不是 JSON,也没有引号。

调用方:代理探测(`:31`)、`GetItems`(`QBittorrent.cs:220`)、`GetStatus`(`:374`),
`TestConnection`(`:435`)、`TestCategory`(`:519`),以及一个很容易漏掉的调用方——
`AddTorrentDownloadFormParameters`(`QBittorrentProxyV2.cs:253`)。这意味着只要初始状态是 Start 或 Stop(也就是几乎总是如此,除非用户选择了 Force Start),**每次 `torrents/add` 之前都会先多走一次 `app/webapiVersion` 往返请求**。

### 1.2 `GET /api/v2/app/version` — `GetVersion`（`QBittorrentProxyV2.cs:80-87`） {#12-get-apiv2appversion--getversion-qbittorrentproxyv2cs80-87}

**返回：** 纯文本，去掉开头的 `v`（`:83`）。注释：`// eg "4.2alpha"`。

**从来没有被调用。** 它在接口里（`QBittorrentProxySelector.cs:13`），但 `QBittorrent.cs` 里没有任何地方调用它（已对照每一处 `Proxy.`/`_proxySelector.` 引用核实，`:49-741`）。还是实现它吧，反正也不费事，而且真有人去摆弄这个 shim 时，很可能会想用它。

### 1.3 `POST /api/v2/auth/login`

详见 §0.4。表单字段:`username`、`password`。返回 `200`,内容为 `Ok.`,并带有 `Set-Cookie: SID=…`。

### 1.4 `GET /api/v2/app/preferences` — `GetConfig`（`QBittorrentProxyV2.cs:89-95`） {#14-get-apiv2apppreferences--getconfig-qbittorrentproxyv2cs89-95}

请求没有参数。响应是一个 JSON 对象，会被反序列化为 `QBittorrentPreferences`。

**客户端会读取的每个键**（`QBittorrentPreferences.cs:14-45`）。响应体中的其他内容都不会被读取，多出来的键会被忽略：

| JSON 键 | C# | 类型 | 读取位置 |
|---|---|---|---|
| `save_path` | `SavePath` | `string` | `GetStatus` → `OutputRootFolders`（`QBittorrent.cs:377`） |
| `max_ratio_enabled` | `MaxRatioEnabled` | `bool` | `HasReachedSeedLimit`（`:639`），`RemovesCompletedDownloads`（`:415`） |
| `max_ratio` | `MaxRatio` | `float` | `HasReachedSeedLimit`（`:641`） |
| `max_seeding_time_enabled` | `MaxSeedingTimeEnabled` | `bool` | `HasReachedSeedingTimeLimit`（`:663`），`RemovesCompletedDownloads`（`:415`） |
| `max_seeding_time` | `MaxSeedingTime` | `long`，单位是**分钟** | `:665`，`:415` |
| `max_inactive_seeding_time_enabled` | `MaxInactiveSeedingTimeEnabled` | `bool` | `HasReachedInactiveSeedingTimeLimit`（`:727`） |
| `max_inactive_seeding_time` | `MaxInactiveSeedingTime` | `long`，单位是**分钟** | `:729` |
| `max_ratio_act` | `MaxRatioAction` | 以整数表示的枚举：`Pause=0, Remove=1, EnableSuperSeeding=2, DeleteFiles=3`（`QBittorrentPreferences.cs:5-11`） | `RemovesCompletedDownloads`（`:415`） |
| `queueing_enabled` | `QueueingEnabled` | `bool`，**默认为 `true`** | `TestPrioritySupport`（`:572`） |
| `dht` | `DhtEnabled` | `bool` | `AddFromMagnetLink`（`:73`），`metaDL` 分支（`:288`） |

调用方：`AddFromMagnetLink`（`:73`）、`GetItems`（`:221`）、`GetStatus`（`:375`）、`TestConnection`（`:467`）、`TestPrioritySupport`（`:570`）。它**不会被缓存**，所以每次轮询都会重新获取。

`RemovesCompletedDownloads`（`QBittorrent.cs:412-416`）是由上面这些值推导出的标志：

```csharp
var minimumRetention = 60 * 24 * 14; // 14 days in minutes
return (config.MaxRatioEnabled || (config.MaxSeedingTimeEnabled && config.MaxSeedingTime < minimumRetention))
    && (config.MaxRatioAction == QBittorrentMaxRatioAction.Remove || config.MaxRatioAction == QBittorrentMaxRatioAction.DeleteFiles);
```

它会同时影响连接测试（`:468`）和 `DownloadClientRemovesCompletedDownloadsCheck` 健康检查（`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:44-53`）。如果 `max_ratio_enabled: false` 且 `max_seeding_time_enabled: false`，无论 `max_ratio_act` 是什么值，它都是 false。不过仍然要发送 `max_ratio_act: 0`。

### 1.5 `GET /api/v2/torrents/categories` — `GetLabels`（`QBittorrentProxyV2.cs:221-225`） {#15-get-apiv2torrentscategories--getlabels-qbittorrentproxyv2cs221-225}

**请求：** 无参数。

**响应：** 一个 JSON **对象**，`{"<name>": {"name": "...", "savePath": "..."}}`，反序列化为 `Dictionary<string, QBittorrentLabel>`。注意是 **驼峰命名的 `savePath`**，见 §0.6 和 wiki 中的 *Get all categories* 示例。这里如果是数组就会抛出异常。

请重点看两处：

1. `TestCategory`（`QBittorrent.cs:525-553`）：只需要检查键是否存在（见 §6.3）。
2. `GetStatus`（`:379-402`）：配置的分类中的 `savePath` 会成为下载客户端的输出根文件夹：

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

**相对路径**的 `savePath` 会追加到全局的 `save_path` 后面；**绝对路径**则会替换掉它。以 `//` 开头的 `savePath` 会被转换成反斜杠的 UNC 路径。Sonarr 的测试样例（`QBittorrentFixture.cs:563-589`，Radarr 的是 `:562-588`）固定了这一行为：`"//server/store/downloads"` → `\\server\store\downloads`。**绝对不要输出以 `//` 开头的路径。**

最简单的正确做法是 `"savePath": ""`，这样根文件夹就保持为全局的 `save_path`。

### 1.6 `POST /api/v2/torrents/createCategory` — `AddLabel`（`QBittorrentProxyV2.cs:213-219`） {#16-post-apiv2torrentscreatecategory--addlabel-qbittorrentproxyv2cs213-219}

表单：`category=<name>`。**不会发送 `savePath`**，客户端从不设置分类的保存路径。
响应正文会被忽略，只看状态码是否为非错误。

仅在分类缺失时，由 `TestCategory`（`QBittorrent.cs:529`、`:543`）调用。
`torrents/editCategory` 和 `torrents/removeCategories` **从不被调用**。

### 1.7 `POST /api/v2/torrents/add` — `AddTorrentFromUrl` / `AddTorrentFromFile`

`AddTorrentFromUrl`（`QBittorrentProxyV2.cs:146-166`）：表单字段 **`urls`** 的值是 magnet URI。

`AddTorrentFromFile`（`:168-188`）：表单上传 **`torrents`**，文件名为 `{CleanFileName(release title)}.torrent`（`TorrentClientBase.cs:199`），`Content-Type: application/octet-stream`（`HttpRequestBuilder.cs:379`）。

两者随后都会添加 `AddTorrentDownloadFormParameters`（`QBittorrentProxyV2.cs:243-284`）中的参数：

| 表单字段 | 值 | 条件 | 行号 |
|---|---|---|---|
| `category` | `Settings.TvCategory` / `MovieCategory` | category 非空白 | `:245-248` |
| `stopped`（webapi `>= 2.11.0`）或 `paused`（更低版本） | Start 时为 `False`，Stop 时为 `True` | `InitialState` 为 Start 或 Stop；**Force Start 两者都不发送** | `:251-264` |
| `sequentialDownload` | `True` | `SequentialOrder` 设置已开启 | `:266-269` |
| `firstLastPiecePrio` | `True` | `FirstAndLast` 设置已开启 | `:271-274` |
| `contentLayout` | `"Original"` 或 `"Subfolder"` | `ContentLayout` 设置为 Original 或 Subfolder；**Default 不发送任何值** | `:276-283` |

当配置了分享限制**并且** webapi `>= 2.8.1`（`QBittorrent.cs:79`，`:136`）时，还会添加 `AddTorrentSeedingFormParameters(request, seedConfiguration)`（`QBittorrentProxyV2.cs:227-241`）中的参数：

| 表单字段 | 值 | 条件 |
|---|---|---|
| `ratioLimit` | `seedConfiguration.Ratio` 或 `-2` | 仅当不为 `-2` 时（`:232`） |
| `seedingTimeLimit` | `seedConfiguration.SeedTime.TotalMinutes` 或 `-2` | 仅当不为 `-2` 时（`:237`） |

wiki 中为 `torrents/add` 记录的其他参数**一律不会发送**：没有 `savepath`、没有 `cookie`、没有 `tags`、没有 `skip_checking`、没有 `root_folder`、没有 `rename`、没有 `upLimit`、没有 `dlLimit`、没有 `autoTMM`。添加时没有 `priority` 参数，队列优先级是单独的 `topPrio` 调用（§1.10）。

响应处理（`:159-165`，`:181-187`）：

```csharp
var result = ProcessRequest(request, settings);
// Note: Older qbit versions returned nothing, so we can't do != "Ok." here.
if (result == "Fails.") { throw new DownloadClientException("Download client failed to add torrent by url"); }
```

所以：**除了字面内容为 `Fails.` 之外，返回 200 和任何响应体都算成功。** 通常的返回是 `Ok.`。HTTP 415（wiki 中的 "torrent file is not valid"）会通过 `:389` 变成 `DownloadClientException`。

下载 ID 并不来自这次调用。它是在发送请求之前由客户端计算出来的：

- magnet → `MagnetLink.Parse(magnetUrl).InfoHash.ToHex()`（`TorrentClientBase.cs:224`）
- `.torrent` → `_torrentFileInfoReader.GetHashFromTorrentFile(torrentFile)`（`:200`）

而 `AddFromMagnetLink` / `AddFromTorrentFile` 会原样返回同一个 `hash`（`QBittorrent.cs:130`，`:187`）。**shim 必须用这个 infohash 作为种子的键**，否则 Sonarr 会丢失这次抓取的记录。`TorrentClientBase.cs:206-212` 和 `:238-244` 只会为此输出一行 Debug 日志。

对于 magnet，会先检查 DHT 前提条件：

```csharp
if (!Proxy.GetConfig(Settings).DhtEnabled && !magnetLink.Contains("&tr="))
    throw new NotSupportedException("Magnet Links without trackers not supported if DHT is disabled");   // :73-76
```

在没有 `.torrent` 备用方案时，调用方会将其转换为 `ReleaseDownloadException("Magnet not supported by download client…")`（`TorrentClientBase.cs:111-119`）。**请报告 `dht: true`。**

添加之后，`WaitForTorrent`（`QBittorrent.cs:190-214`）会轮询 `IsTorrentLoaded`，**每次间隔 100 ms，共 10 次**，但只有在还有后续工作要做时才会这样（添加后的分享限制、顶部优先级或 force start；`:86`，`:143`）。它的失败信息写的是 "within 500 ms"，而循环实际是 10 × 100 ms。无论如何，它都会放弃等待并返回 hash（`:212-213`）。

### 1.7a 客户端等待 `torrents/add` 的时长 — **100 秒**，测试于 2026-08-30 {#17a-how-long-the-client-waits-for-torrentsadd--100-seconds-measured-2026-08-30}

从 `Sonarr/Sonarr@32a5d492` 和 `Radarr/Radarr@40bb746c`（都是 `develop` 分支）于 2026-08-30 读取。这决定了 shim 在 add 调用内同步执行的所有操作的时长上限，所以值得引用源码出处，而不是凭感觉假设。

qBittorrent 这条路径上没有设置任何超时，所以这个值会穿过四层，最终落到固定的 100 秒：

| 步骤 | Sonarr `path:line` | Radarr `path:line` | 作用 |
|---|---|---|---|
| add 调用 | `QBittorrentProxyV2.cs:146-150`, `:168-172` | `:145-149`, `:167-171` | 构造请求，不设置超时 |
| 构建器 | `NzbDrone.Common/Http/HttpRequestBuilder.cs:104-116` | 同一文件 `:104-116` | `Apply()` 里没有 `RequestTimeout` 这一行，这个类也没有对应属性 |
| 字段默认值 | `NzbDrone.Common/Http/HttpRequest.cs:52` | `:54` | 自动属性在构造函数里从未赋值，所以是 `TimeSpan.Zero` |
| 分发器 | `NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:70-79` | `:68-77` | `Zero` 变成 `cts.CancelAfter(TimeSpan.FromSeconds(100))` |

```csharp
using var cts = new CancellationTokenSource();
if (request.RequestTimeout != TimeSpan.Zero) { cts.CancelAfter(request.RequestTimeout); }
else { /* The default for System.Net.Http.HttpClient */ cts.CancelAfter(TimeSpan.FromSeconds(100)); }
```

在两个仓库的 `src/NzbDrone.Core/Download/Clients/QBittorrent/` 下，`RequestTimeout` 和 `Timeout` 都没有出现，而且 `HttpRequestBuilder` 也没有提供设置它的方式，所以 shim 无法通过配置获得更多时间。

由此得出五点：

- **这 100 秒来自 Sonarr 自己的取消令牌，而不是 .NET 的计时器。** 底层 handler 是用 `Timeout = Timeout.InfiniteTimeSpan` 构建的（Sonarr 是 `ManagedHttpDispatcher.cs:183`，Radarr 是 `:180`），所以只有这个令牌在起约束作用。它同时传给了 `SendAsync` 和 `ReadAsByteArrayAsync`（`:115`、`:127`），这意味着它覆盖了连接、请求体、响应头和响应体的全部时间。
- **超时会以连接故障的形式报告给用户。** 超时触发时会抛出 `new WebException("Http request timed out", …)`（`:142-145`），`ProcessRequest` 再把它包装成 `DownloadClientException("Failed to connect to qBittorrent, please check your settings.", ex)`（`QBittorrentProxyV2.cs:424-427`）。因此，一个阻塞超过 100 秒的 shim 看起来像是配置有问题，而不是慢；*arr 也无从得知 add 其实还在进行中。
- **没有单独的连接超时，也没有为 multipart 上传预留更长的时间。** `SocketsHttpHandler.ConnectTimeout` 从未设置。唯一的例外是进程生命周期内第一次 IPv6 尝试会被限制在 2 秒（`ManagedHttpDispatcher.cs:23`、`:288-295`），之后会在同一个 100 秒内回退到 IPv4。`.torrent` 上传会整体缓冲成一个字节数组（`HttpRequestBuilder.cs:220-221`、`ManagedHttpDispatcher.cs:103`），并在同一个令牌下发送。
- **300 秒确实存在，但走的是另一条路径。** `HttpClient.cs:285` 在 `DownloadFileAsync` 里设置了 `request.RequestTimeout = TimeSpan.FromSeconds(300)`，这个方法用来从索引器抓取 `.torrent`。它永远不会进入下载客户端的调用。
- **Deluge 证明了覆盖是可行的，而 qBittorrent 没有这样做。** `DelugeProxy.cs:222` 执行了 `requestBuilder.PostProcess += r => r.RequestTimeout = TimeSpan.FromSeconds(15)`。qBittorrent 的 `BuildRequest` 里没有这样的代码，这直接说明 100 秒是继承来的，而不是特意选定的。

**Radarr 完全一样。** 对超时代码块做 diff（Radarr `:68-78` 对比 Sonarr `:70-80`），结果逐字节相同。整条链路上唯一的区别是：往 `WebException` 里传入的是 `ex`（Radarr），而 Sonarr 传入的是 `ex.InnerException`。

**对 shim 的影响。** 在 `torrents/add` 内部做出的每一个同步决策，都共用同一个 100 秒预算，而 *arr 没有办法区分"还在处理"和"无法连接"。每次尝试的截止时间乘以尝试过的 provider 数量，再加上任何仅缓存探测的时间窗口，必须明显低于这个上限。构成这个预算的 provider 实测延迟，见 [torrent-lifecycle.md](torrent-lifecycle.md)。

补充一点说明。100 秒是按每次分发器调用计算的，所以自动重定向链的每一跳都会获得一份新的预算（`HttpClient.cs:43` 把链长限制在 5 跳）。`DownloadClientBase.cs:30-44` 的重试策略**不**适用于这里；它只用于从索引器抓取 `.torrent`（`TorrentClientBase.cs:142-144`）。

### 1.8 `GET /api/v2/torrents/properties?hash=<hash>` — `IsTorrentLoaded` / `GetTorrentProperties`

`IsTorrentLoaded`（`QBittorrentProxyV2.cs:110-126`）调用它时传入 `LogHttpError = false`，并且把**任何**异常都当成"未加载"。

`GetTorrentProperties`（`:128-135`）会反序列化为 `QBittorrentTorrentProperties`（`QBittorrentTorrent.cs:48-57`）—— **三个字段，只用了两个**：

| JSON 键 | C# | 用途 |
|---|---|---|
| `hash` | `Hash` | 会读取，但从不使用 |
| `save_path` | `SavePath` | `GetImportItem` 在 2.6.1 之前的路径（`QBittorrent.cs:354`） |
| `seeding_time` | `SeedingTime`（`long`，**秒**） | `FetchTorrentDetails`（`:739-744`） |

**这里的哈希大小写不一致，而且很重要。** 其他所有调用都会把哈希转成小写（`item.DownloadId.ToLower()` 在 `:335`、`:346`、`:353`；`hash.ToLower()` 在 `:97`、`:109`、`:121`、`:198`），但 `FetchTorrentDetails` 会**原样**传递 `torrent.Hash`（`:741`）—— 也就是 shim 在 `torrents/info` 里返回什么就用什么。真正的 qBittorrent 返回的是小写哈希，所以这个问题不会暴露；但 Sonarr 的测试夹具通过用大写值模拟 `GetTorrentProperties("HASH", …)` 把这种不对称固定了下来（Sonarr `QBittorrentFixture.cs:669-675`，Radarr `:668-674`）。**请从 `torrents/info` 返回小写哈希，并且对 `?hash=` 做大小写不敏感的匹配。**

`FetchTorrentDetails` 只会从 `HasReachedSeedingTimeLimit`（`:700`）调用，而这个方法只有在确实设置了做种时间上限时才会走到。所以，如果 shim 没有声明任何做种时间上限，轮询期间就根本不会触发这个调用。不过它对 `IsTorrentLoaded` 仍然必不可少，因为后者是添加之后的就绪探测：**哈希未知返回 404，哈希已知则返回 200 加 JSON。**

结果会按 `{Host}{Port}{Hash}` 缓存 5 分钟（`:678`、`:689`、`:695`、`:708`），测试夹具也断言两次轮询之间只会获取一次，而不是两次（Sonarr `QBittorrentFixture.cs:905-920`，Radarr `:904-919`）。

### 1.9 `POST /api/v2/torrents/setShareLimits` — `SetTorrentSeedingConfiguration`（`:286-308`） {#19-post-apiv2torrentssetsharelimits--settorrentseedingconfiguration-286-308}

形式：`hashes=<lowercase hash>`，然后 `AddTorrentSeedingFormParameters(request, seedConfiguration, always: true)`
— 当 `always: true` 时，即使值为 `-2`，**`ratioLimit` 和 `seedingTimeLimit` 两者**都会被发送（`:232`、`:237`）。`inactiveSeedingTimeLimit` 从不发送。

**404** 会被忽略（`:298-307`，注释：“setShareLimits 是在 api v2.0.1 中添加的”）。其他错误会继续向上抛出，但调用处会捕获并记录警告（`QBittorrent.cs:95-102`、`:152-159`）。

只有在索引器提供了种子配置，并且 webapi 版本 `< 2.8.1` 时才会走到这里。如果 兼容层（shim）报告的版本是 `2.11.2`，分享限制改为随 `torrents/add` 一起发送，抓取时从不使用此路由。将其实现为空操作，返回 200。

### 1.10 `POST /api/v2/torrents/topPrio` — `MoveTorrentToTopInQueue`（`:310-330`） {#110-post-apiv2torrentstopprio--movetorrenttotopinqueue-310-330}

格式：`hashes=<lowercase hash>`。

**409 Conflict** 会被吞掉（`:320-329`，注释写道："qBittorrent rejects all Prio commands with 409: Conflict if Options -> BitTorrent -> Torrent Queueing is not enabled"）。v1 代理则会吞掉 **403**（`QBittorrentProxyV1.cs:255-264`）。其他错误都会在调用处被捕获并记录警告（`QBittorrent.cs:107-114`、`:164-171`）。测试夹具会断言这里的失败不会导致抓取失败（Sonarr `QBittorrentFixture.cs:525-542`，Radarr `:524-541`）。

只有当 Recent/Older 优先级设置为 `First` 时才会调用（`QBittorrentPriority.First = 1`，`QBittorrentPriority.cs:5-6`）；默认值是 `Last = 0`。

### 1.11 `POST /api/v2/torrents/setForceStart` — `SetForceStart`（`:332-339`） {#111-post-apiv2torrentssetforcestart--setforcestart-332-339}

形式：`hashes=<lowercase hash>`，`value=true`（字面量小写字符串，`:337`）。

仅当 `InitialState` 为 `ForceStart` 时才会调用（`QBittorrentState.cs:10-11`、`QBittorrent.cs:82`、`:117-127`）。错误会被捕获并记录为警告（`:123-126`）。

### 1.12 `GET /api/v2/torrents/info[?category=<cat>]` — `GetTorrents`（`:97-108`） {#112-get-apiv2torrentsinfocategorycat--gettorrents-97-108}

**唯一会发送的参数是 `category`，且只在该设置非空白时才发送**
(`:100-103`)。不会发送 `filter`、`hashes`、`sort`、`reverse`、`limit`、`offset` 或 `tag`。
客户端之后**不会**再按分类过滤一次，这与会二次过滤的 SAB 客户端不同。因此，如果适配层（shim）忽略了 `category`，Radarr 就会拿到 Sonarr 的种子。

响应中的 `category` 字段还有第二个作用：如果 \*arr 对某个种子**没有抓取历史记录**，除非它带有分类字段，否则会直接跳过。见 `CompletedDownloadService.Check`（`CompletedDownloadService.cs:84-88`）：

```csharp
if (historyItem == null && trackedDownload.DownloadItem.Category.IsNullOrWhiteSpace())
{
    trackedDownload.Warn("Download wasn't grabbed by Sonarr and not in a category, Skipping.");
    return;
}
```

`Category` 取 `category`（若非空白），否则取 `label`（`QBittorrent.cs:231`）。

响应是一个 JSON **数组**。每个被读取的字段及其对应的含义如下：

| JSON 键 | C# 类型 | 单位 | 对应为 |
|---|---|---|---|
| `hash` | `string` | | `DownloadId = torrent.Hash.ToUpper()`（`QBittorrent.cs:230`）。**转为大写**，之后每次调用都以小写形式传回 |
| `name` | `string` | | `Title = torrent.Name`（`:232`）。它驱动的内容见 §7.1 |
| `size` | `long` | 字节 | `TotalSize`（`:233`）；同时用于 `RemainingSize = (long)(size * (1.0 - progress))`（`:235`） |
| `progress` | `double` | 0..1 | `RemainingSize`（`:235`） |
| `eta` | `BigInteger` | 秒 | 通过 `GetRemainingTime` 得到 `RemainingTime`（`:236`，`:614-628`） |
| `state` | `string` | | `Status`、`Message`，以及 `CanMoveFiles` 判断条件的一部分（`:242-312`）。见 §2 |
| `category` | `string` | | `Category`，优先使用（`:231`） |
| `label` | `string` | | `Category`，当 `category` 为空白时作为后备（`:231`）。这是 3.3.5 之前的字段，qBittorrent 5 不再返回它 |
| `ratio` | `float` | | `SeedRatio`（`:237`），`HasReachedSeedLimit`（`:634`，`:641`） |
| `ratio_limit` | `float`，默认 `-2` | | `HasReachedSeedLimit`（`:632-645`） |
| `seeding_time_limit` | `long`，默认 `-2` | **分钟** | `HasReachedSeedingTimeLimit`（`:659-670`） |
| `inactive_seeding_time_limit` | `long`，默认 `-2` | **分钟** | `HasReachedInactiveSeedingTimeLimit`（`:723-736`） |
| `last_activity` | `long` | **Unix 秒** | `HasReachedInactiveSeedingTimeLimit`（`:736`） |
| `seeding_time` | `long?`，默认为 null | 秒 | `HasReachedSeedingTimeLimit`（`:672-676`）。`QBittorrentTorrent.cs:36` 的注释称它"列表 API 不提供"，但如果存在，客户端仍会使用它，从而省去一次 `torrents/properties` 请求 |
| `save_path` | `string` | | 与 `content_path` 比较（`:316`） |
| `content_path` | `string` | | webapi `>= 2.6.1` 时作为 `OutputPath`（`:318`）。见 §4 |

`GetRemainingTime`（`:614-628`）：

```csharp
if (torrent.Eta < 0 || torrent.Eta > 365 * 24 * 3600) { return null; }   // > 31,536,000 s
if (torrent.Eta == 8640000) { return null; }                            // qBittorrent's "unknown"
return TimeSpan.FromSeconds((int)torrent.Eta);
```

并且状态为 Completed 的项目，之后会把 `RemainingTime` 强制设为 `TimeSpan.Zero`（`:273`）。

`torrents/info` 会在每次 `RefreshMonitoredDownloads` 时获取（`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:94`）。相关事件发生后 5 秒，它还会经过防抖（debounce）处理，被放入命令队列（`:53`）。

### 1.13 `GET /api/v2/torrents/files?hash=<hash>` — `GetTorrentFiles`（`:137-144`） {#113-get-apiv2torrentsfileshashhash--gettorrentfiles-137-144}

返回的是一个 JSON 数组，反序列化为 `List<QBittorrentTorrentFile>`，其中**只有一个成员**：`Name`（`QBittorrentTorrent.cs:59-62`），绑定 `name` 字段。它是相对于**保存路径**的文件路径，在所有操作系统上都使用 `/` 作为分隔符（"QBittorrent returns `/` path separators even on
windows"，`QBittorrent.cs:358`）。

只有在 `GetImportItem`（`:346`）中调用，并且仅当 `OutputPath` 仍为空时才会调用。也就是说，webapi 版本低于 `< 2.6.1`，或者 `content_path` 返回为空时才会走这里。`index`、`size`、`progress`、`priority`、`is_seed`、`piece_range` 和 `availability` 都会被忽略。

空数组会被处理：会执行 `_logger.Debug("No files found for torrent {0} in qBittorrent")`，然后原样返回该条目（`:347-351`）。之后它会在 `ValidatePath` 处失败。

### 1.14 `POST /api/v2/torrents/setCategory` — `SetTorrentLabel`（`:204-211`） {#114-post-apiv2torrentssetcategory--settorrentlabel-204-211}

格式：`hashes=<lowercase hash>`，`category=<post-import category>`。

仅由 `MarkItemAsImported`（`QBittorrent.cs:52-69`）调用，并且只有在可选设置 `TvImportedCategory` / `MovieImportedCategory` 非空白且与主分类不同时才会调用。`DownloadClientException` 会被捕获，并发出警告：
"Failed to set post-import torrent label \"{0}\" for {1} in qBittorrent. Does the label exist?"（`:62-67`）。§5.1。

### 1.15 `POST /api/v2/torrents/delete` — `RemoveTorrent`（`:190-202`） {#115-post-apiv2torrentsdelete--removetorrent-190-202}

表单格式为：`hashes=<lowercase hash>`，并且**仅当 `removeData` 为 true 时**才加上 `deleteFiles=true`（`:196-199`）。这里使用的是字面的小写字符串，而不是 `Convert.ToString(bool)`。

`QBittorrent.RemoveItem`（`:333-336`）的完整实现如下：

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    Proxy.RemoveTorrent(item.DownloadId.ToLower(), deleteData, Settings);
}
```

**它不会调用 `DeleteItemData`。** 这和 SAB 客户端不同：SAB 客户端会通过文件系统自己删除任务文件夹（`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`；参见 [sabnzbd-client-contract.md §5.3](sabnzbd-client-contract.md)）。在这里，删除数据完全是下载客户端的工作。§5.

### 1.16 客户端从不调用的端点 {#116-endpoints-the-client-never-touches}

以下接口在界面上完全没有，因此从不调用：`torrents/pause`、`torrents/resume`、`torrents/stop`、`torrents/start`、`torrents/setLocation`、`torrents/rename`、`torrents/recheck`、`torrents/reannounce`、`torrents/filePrio`、`torrents/setDownloadLimit`、`torrents/setUploadLimit`、`torrents/toggleSequentialDownload`、`torrents/setAutoManagement`、`torrents/editCategory`、`torrents/removeCategories`、标签、RSS、搜索、`app/setPreferences`、`app/defaultSavePath`、`app/shutdown`、`sync/maindata`、`transfer/*`、`auth/logout`。暂停和恢复只能通过 `torrents/add` 上的 `paused=`/`stopped=` 表单字段来实现。

界面上有但 `QBittorrent.cs` 从未调用的接口：`GetVersion`（§1.2）。

### 1.17 v1 路由映射（仅供参考，不需实现） {#117-the-v1-route-map-for-completeness-do-not-implement}

`QBittorrentProxyV1.cs`：`/version/api`（`:30`、`:64` —— 客户端会在任何返回内容前面加上 `"1."`，
见 `:65`），`/version/qbittorrent`（`:73`），`/query/preferences`（`:81`），`/query/torrents?label=&category=`（`:89-94` —— **两个**参数都要有），`/query/propertiesGeneral/{hash}`（`:103`、`:120`），`/query/propertiesFiles/{hash}`（`:128`），`/command/download`（`:136`），`/command/upload`（`:166`），`/command/delete` 或 `/command/deletePerm`（`:196` —— delete 和 deleteFiles 的区别是两条不同的路由，而不是一个参数），`/command/setCategory`，在 404 时回退到 `/command/setLabel`（`:205-225`），`/command/addCategory`（`:230`），`/command/topPrio`（`:248`），`/command/setForceStart`（`:269`），`/login`（`:345`）。

## 2. `state` → `DownloadItemStatus`

`QBittorrent.GetItems`（`:247-312`）。状态字符串是 qBittorrent 自己的，由 `torrentStateToString`（`qBittorrent/src/webui/api/serialize/serialize_torrent.cpp:44-87`）生成。

| `state` | `DownloadItemStatus` | `Message` | 行 |
|---|---|---|---|
| `error` | **Warning** | "qBittorrent is reporting an error" | `:249-252` |
| `stoppedDL` | Paused | — | `:254` |
| `pausedDL` | Paused | — | `:255`（qBittorrent < 5） |
| `queuedDL` | Queued | — | `:259` |
| `checkingDL` | Queued | — | `:260` |
| `checkingUP` | Queued | — | `:261` |
| `checkingResumeData` | Queued | — | `:262` |
| `pausedUP` | **Completed** | — | `:266`（qBittorrent < 5） |
| `stoppedUP` | **Completed** | — | `:267` |
| `uploading` | Completed | — | `:268` |
| `stalledUP` | Completed | — | `:269` |
| `queuedUP` | Completed | — | `:270` |
| `forcedUP` | Completed | — | `:271` |
| `stalledDL` | **Warning** | "The download is stalled with no connections" | `:276-279` |
| `missingFiles` | **Warning** | "qBittorrent is reporting missing files" | `:281-284` |
| `metaDL` | Queued **如果 `dht: true`**，否则为 Warning | "qBittorrent is downloading metadata" / "qBittorrent cannot resolve magnet link with DHT disabled" | `:286-299` |
| `forcedMetaDL` | 与 `metaDL` 相同 | 与 `metaDL` 相同 | `:287` |
| `forcedDL` | Downloading | — | `:301` |
| `moving` | Downloading | — | `:302` |
| `downloading` | Downloading | — | `:303` |
| **其他任何状态** | **Downloading** | "Unknown download state: {state}" | `:307-311` |

shim 需要注意的几点：

- **未知状态不会抛出异常。** 它会记录 `_logger.Info($"Unknown download state: {torrent.State}")`，然后落到 Downloading（`:307-311`）。这与 SAB 客户端正好相反：在 SAB 中，未知的状态名会在反序列化器里抛出异常，导致整个轮询中断。不过还是要注意：只发送这个表里列出的名称。
- **只有 Completed 状态的下载才能被导入。** 除非 `Status == Completed`，否则 `CompletedDownloadService.Check` 会直接返回（`src/NzbDrone.Core/Download/CompletedDownloadService.cs:68-71`）。
- **每个 Completed 状态都会把 `RemainingTime` 重置为零**（`:273`，注释写的是 "qBittorrent sends eta=8640000 for completed torrents"）。
- `metaDL` / `forcedMetaDL` 是"磁力链接、还没有元数据"的阶段。客户端里**没有超时**：只要 shim 一直返回 `metaDL`，它就一直是 Queued，本身也不会升级为失败。唯一会把它变成 Warning 的是 `app/preferences` 里的 `dht: false`（`:288`）。Sonarr 的下载失败处理看的是抓取时间的长短，而不是这个状态。
- `stalledDL` 是运维人员在看到一个没有动静的种子时会看到的*警告*。如果 shim 没有 peers 的概念，就永远不要使用它。对一个被跟踪的下载来说，Warning 会在队列中显示为问题，而 `FailedDownloadService` 正是检查这个状态的。
- `error` 和 `missingFiles` 被刻意设为 Warning，"so failed download handling isn't triggered"（`:249`）。如果 shim 想让 Sonarr 把这个下载加入黑名单并重新抓取，那么用 Warning **不是**正确的做法。

## 3. 移动还是复制 — 确切条件与操作方法 {#3-move-vs-copy--the-exact-condition-and-the-recipe}

### 3.1 判断条件 {#31-the-gate}

`QBittorrent.cs:240-245`，逐字照抄，包括解释它的注释：

```csharp
// Avoid removing torrents that haven't reached the global max ratio.
// Removal also requires the torrent to be paused, in case a higher max ratio was set on the torrent itself (which is not exposed by the api).
item.CanMoveFiles = item.CanBeRemoved =
    item.DownloadClientInfo.RemoveCompletedDownloads &&
    torrent.State is "pausedUP" or "stoppedUP" &&
    HasReachedSeedLimit(torrent, config);
```

三个条件，全部必须满足：

1. **`RemoveCompletedDownloads`** —— 这是 *arr 端每个客户端的设置，而不是 qBittorrent 说的内容。
   `DownloadClientDefinition.RemoveCompletedDownloads` 默认为 **`true`**
   (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17`)，在界面上显示为
   "Remove Completed"。如果用户把它关掉，**导入就会变成复制**，而 shim 对此无能为力。（Move 变成 copy 还有第二个原因，shim 同样看不到：*arr 的容器通过两个卷访问下载目录和根目录，此时 `rename()` 返回 `EXDEV`，.NET 的 `File.Move` 就会复制然后删除。zurg 会从获取来源的 API 读取这两者，并在之后接管这份复制；参见 `internal/arrlayout` 和 `internal/handlers/magic_copies.go`。）
2. **`state` 必须恰好是 `pausedUP` 或 `stoppedUP`。** `uploading`、`stalledUP`、`queuedUP` 和 `forcedUP` 也是 Completed，但不能移动，fixture 对此有明确约定（Sonarr `QBittorrentFixture.cs:680-689`，Radarr `:679-688`）。
3. **`HasReachedSeedLimit(torrent, config)`**。

### 3.2 `HasReachedSeedLimit`（`:630-653`） {#32-hasreachedseedlimit-630-653}

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

- 每个 torrent 的 **`ratio_limit >= 0`** 会直接生效，不再看全局设置。在 qBittorrent 自己的模型里，`ratio_limit` 为 `-2` 表示“使用全局设置”，`-1` 表示“无限制”（`QBittorrentTorrent.cs:32`；维基，*Set torrent share limit*）。
- `-1`（无限制）两个分支都不满足：`-1 >= 0` 为假，`-1 == -2` 也为假。所以无限制的 torrent **永远**不会被分享率规则移动。
- `0.001f` 的容差正是让“四舍五入后达到”能成立的原因。测试夹具里，分享率 `1.1006066990976857` 对比上限 `1.0` 会被判定为已达到，`0.9999` 同样会被判定为已达到（Sonarr `QBittorrentFixture.cs:715-737`，Radarr `:714-736`）。

`HasReachedSeedingTimeLimit`（`:655-717`）：

```csharp
if (torrent.SeedingTimeLimit >= 0)        { seedingTimeLimit = torrent.SeedingTimeLimit * 60; }        // minutes -> seconds
else if (torrent.SeedingTimeLimit == -2 && config.MaxSeedingTimeEnabled) { seedingTimeLimit = config.MaxSeedingTime * 60; }
else                                      { return false; }
```

然后，如果列表 API 提供了 `torrent.SeedingTime`，就直接用它（`:672-676`）。否则会先查看一个 5 分钟的缓存，缓存未命中时调用 **`torrents/properties`** 获取 `seeding_time`（`:678-716`，`:739-744`）。`HasReachedInactiveSeedingTimeLimit`（`:719-737`）结构相同，但它比较的是 `now - last_activity` 和 `inactive_seeding_time_limit`（或全局值），而且从来不需要第二次调用。

### 3.3 `CanMoveFiles` 的判断依据 {#33-what-canmovefiles-decides}

`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, series, importItem)`（`CompletedDownloadService.cs:148-151`），然后有两处读取 `CanMoveFiles`：

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

（Radarr：`src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`，完全相同。）

```csharp
// src/NzbDrone.Core/MediaFiles/DownloadedEpisodesImportService.cs:204-207
if (importMode == ImportMode.Auto)
{
    importMode = (downloadClientItem == null || downloadClientItem.CanMoveFiles) ? ImportMode.Move : ImportMode.Copy;
}
```

（Radarr：`DownloadedMovieImportService.cs:221-224`。）

`copyOnly == false` → `TransferMode.Move`（`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`）；`copyOnly == true` 时，如果开启了 "Use Hardlinks instead of Copy"，则为 `TransferMode.HardLinkOrCopy`，否则为 `TransferMode.Copy`（`:103`、`:107`）。`TransferMode` 是 `[Flags] None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy=Copy|HardLink`（`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`）。

**失败的 Move 永远不会回退到 Copy。** 完整论证及行号见 [sabnzbd-client-contract.md §5.5](sabnzbd-client-contract.md)；`DiskTransferService.cs` 是共享的，两个仓库中的字节级完全相同。简单来说：`TransferFile` 的 Move 分支（`src/NzbDrone.Common/Disk/DiskTransferService.cs:360-389`）只有一条复制路径，它是事先根据 `targetMount.DriveFormat == "cifs"`（`:342`、`:378-385`）选定的，而不是对某次失败的反应。`TryMoveFileVerified` 会重新抛出异常（`:487-503`）；`VerifyFile` 在目标文件大小与源文件不一致时，会抛出 `IOException("File move incomplete, data loss may have occurred. …")`（`:505-524`）。

### 3.4 使用 qBittorrent 默认设置时，导入是**复制** {#34-with-qbittorrents-own-defaults-the-import-is-a-copy}

| 字段 | 值 | 效果 |
|---|---|---|
| `state` | `stoppedUP` | 条件 2 ✓ |
| `ratio_limit` | `-2`（默认值，`QBittorrentTorrent.cs:33`） | 落到全局分支 |
| `max_ratio_enabled` | `false`（qBittorrent 自身的默认值；wiki 示例正文 `:684`） | 全局分支不成立 |
| `seeding_time_limit` | `-2` | 需要 `max_seeding_time_enabled` |
| `max_seeding_time_enabled` | `false`（wiki `:686`） | 不成立 |
| `inactive_seeding_time_limit` | `-2` | 需要 `max_inactive_seeding_time_enabled` |
| `max_inactive_seeding_time_enabled` | `false` | 不成立 |

⇒ `HasReachedSeedLimit` 为 false ⇒ `CanMoveFiles` 为 false ⇒ `copyOnly` 为 true ⇒ `TransferMode.Copy` ⇒ **\*arr 会把这个发布的每个字节从挂载点读出来，再整个写回去。** 在 debrid 挂载上，这正是整个设计要避免的结果，而且它是无声失败的：没有任何警告，导入只会耗上好几个小时，还会把磁盘填满。

这个 fixture 正好覆盖了这种情况：
`should_not_be_removable_and_should_not_allow_move_files_if_max_ratio_is_not_set`
（Sonarr `QBittorrentFixture.cs:691-701`，Radarr `:690-700`）。全局限制关闭，种子处于暂停状态，ratio 为 1.0，`CanMoveFiles == false`。

### 3.5 操作方法 {#35-the-recipe}

对于 shim 想要用 **move** 方式导入的每个种子：

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

`ratio_limit: 0` 会走第一个分支（`0 >= 0`，并且 `0 - 0 <= 0.001`），全局偏好设置根本不会被读取。所以 `max_ratio_enabled` 可以保持 `false`，`DownloadClientRemovesCompletedDownloadsCheck` 健康检查也会保持安静。只要 `ratio_limit >= ratio` 且差值在 `0.001` 以内，都可以工作；`0`/`0` 是不需要任何协调的那一组。

关于 `pausedUP` 和 `stoppedUP`：**develop 分支对它们的处理完全一样**，无论是在 `CanMoveFiles` 检查（`:244`）里，还是在状态映射（`:266-267`）里，而且每个 seed-limit 测试夹具都是同时覆盖这两种状态的 `[TestCase]` 组合。`stoppedUP` 是 qBittorrent 5 的写法（`serialize_torrent.cpp:54-55`；master 分支里已经没有 `pausedUP` 了）。如果要兼容*已发布*的 \*arr 版本，`pausedUP` 更稳妥，因为 `stoppedUP` 分支是在 qBittorrent 5 发布时才加入的，较旧的 Sonarr v4 / Radarr v5 版本只认识 `pausedUP`。最后这一点是对旧标签的推断，上面引用的 develop 源码并不能直接证明。

还有一件不在 shim 控制范围内的事：**\*arr 的下载客户端设置里，"Remove Completed" 必须保持开启。** 它默认就是开启的（`DownloadClientDefinition.cs:17`）。请一定把这点写进文档，因为一旦关掉，每次导入都会变成完整下载。

## 4. `OutputPath` — 告诉 \*arr 从哪里导入 {#4-outputpath--where-the-arr-is-told-to-import-from}

### 4.1 2.6.1 及以上版本：`content_path` {#41-the-261-path-content_path}

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

警告文本（`src/NzbDrone.Core/Localization/Core/en.json`）：

> Unable to Import. Path matches client base download directory, it's possible 'Keep top-level folder'
> is disabled for this torrent or 'Torrent Content Layout' is NOT set to 'Original' or 'Create Subfolder'?

shim 必须满足以下规则：

- `content_path` **不能等于** `save_path`。相等才是失败，而不是一种回退方案：该条目会变成 Warning，永远无法导入。
- `content_path` 必须是**绝对路径，并且对 \*arr 所运行的操作系统有效**。否则 `CompletedDownloadService.ValidatePath`（`CompletedDownloadService.cs:295-313`）会拒绝它，并报出 "[{0}] is not a valid local path. You may need a Remote Path Mapping."
- 它必须在 \*arr 主机上作为**文件夹或文件**存在。`ProcessPath`（`DownloadedEpisodesImportService.cs:80-105`）会先判断 `FolderExists`，再判断 `FileExists`；两者都不满足时，就会走到 `LogInaccessiblePathError`，并返回空结果。
- 不要发送空的 `content_path`。它和非空的 `save_path` 不一样，所以 `OutputPath` 会被设成空的 `OsPath`。因为 `item.OutputPath.IsEmpty` 为 true（`:341-344`），`GetImportItem` 会接着落到 `torrents/files` 遍历（§4.2）。
- 这段逻辑只对 **Completed** 条目运行，所以只有当状态属于 §2 里的 Completed 集合时，`content_path` 才真正起作用。

真正的 qBittorrent 会在这里填入的内容是 `TorrentImpl::contentPath()`（`qBittorrent/src/base/bittorrent/torrentimpl.cpp:577-587`）：

```cpp
Path TorrentImpl::contentPath() const
{
    if (!hasMetadata())    return {};
    if (filesCount() == 1) return (actualStorageLocation() / filePath(0));   // the FILE, not a folder
    const Path rootPath = this->rootPath();
    return (rootPath.isEmpty() ? actualStorageLocation() : rootPath);
}
```

其中 `rootPath()` 为 `actualStorageLocation() / Path::findRootFolder(filePaths())`（`:565-575`）。所以：单文件种子的 `content_path` 就是这个文件本身；多文件且有共同根文件夹的种子会得到那个文件夹；没有共同根文件夹的多文件种子则得到 `save_path`，这正是客户端 `content_path == save_path` 警告所针对的情况。

`RemapRemoteToLocal(Settings.Host, …)` 会应用用户配置的 Remote Path Mappings，映射依据是配置好的 **Host** 字符串。如果 \*arr 运行在容器里，而 shim 报告的是宿主机路径，用户就需要添加一条映射，具体做法见 [sabnzbd.md](../guides/sonarr-radarr.md#8-if-your-arr-is-in-docker)，同样适用。

### 4.2 2.6.1 之前的版本：`GetImportItem` 遍历 `torrents/files` {#42-the-pre-261-path-getimportitem-walks-torrentsfiles}

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

它**只读取 `files[0].name`**，向上找到最顶层的路径组件，然后把它拼接到 `properties.save_path` 上。测试夹具（fixture）固定了这三种情况（Sonarr `QBittorrentFixture.cs:317-421`，Radarr `:296-400`）：

| `files[0].name` | `save_path` | `OutputPath` |
|---|---|---|
| `Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` |
| `Folder/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Folder` |
| `Droned.S01.12/E01.mkv` (+ `E02.mkv`) | `/Torrents` | `/Torrents/Droned.S01.12` |

注意第三行：它取的是 `files[0]` 的根目录，而不是计算出来的公共根目录，所以**在这条路径上的 shim 必须按一定顺序列出文件，并且第一个条目要带有发布文件夹**。报告 webapi `>= 2.6.1` 的 shim 永远走不到这里，这也是要报告 `2.11.2` 的另一个原因。

`previousImportAttempt` 是 `GetImportItem`（`:338`）的一个参数，但这个实现里**从来不读取它**。失败的尝试不会被记住。

### 4.3 路径错误时的情况，以及重试频率 {#43-when-the-path-is-wrong-and-how-often-it-is-retried}

这条路径里没有任何退避机制，也没有尝试次数上限。

- `CompletedDownloadService.Check` 会在每次刷新时，对每个状态为 `Downloading` 或 `ImportBlocked` 的被跟踪下载运行一次（`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:125-129`）。
- `Check` **先**调用 `SetImportItem`（`CompletedDownloadService.cs:73`），它会执行 `_provideImportItemService.ProvideImportItem(...)` → `client.GetImportItem(...)`（`:290-293`，`src/NzbDrone.Core/Download/ProvideImportItemService.cs:17-22`）。也就是说，每次轮询都会根据*当前的* `torrents/info` 行重新推导 `OutputPath`。
- `ValidatePath` 失败（`:295-313`）会产生一条 Warning，并且状态保持在 `Downloading`，所以下一次轮询会从头再试：
  - 输出路径为空 → "Download doesn't contain intermediate path, Skipping."
  - 路径的操作系统格式不对 → "[{0}] is not a valid local path. You may need a Remote Path Mapping. …"
- `Import` 入口处同样会先调用 `SetImportItem`（`:130`），然后才重新读取 `trackedDownload.ImportItem.OutputPath.FullPath`（`:147`）。它由 `DownloadProcessingService` 在状态 `ImportPending` 时触发（`src/NzbDrone.Core/Download/DownloadProcessingService.cs:61-63`）。导入失败会让状态停留在 `ImportPending`（`:158`），或者转为 `ImportBlocked`（`:196`），两种情况都会被重新处理。
- 如果路径存在，但里面没有可导入的内容，会输出 "No files found are eligible for import in {0}"（`:162`），状态保持 `ImportPending`。

**对适配层（shim）来说的影响：`content_path` 在一段时间内出错是可以接受的。** 在文件夹真正存在、且文件大小已经稳定之前，都应把种子报告为 Downloading（或 Queued）。这样客户端会继续轮询。如果过早报告 Completed，就会对一个还没准备好的文件夹发起一次导入尝试。更糟的是，\*arr 可能会移动一个大小还不完整的文件，然后在 `VerifyFile` 校验时失败，而源文件此时可能已经被清空了。这和 SAB 端点的陷阱是同一个问题，记录在 [sabnzbd.md](../guides/sonarr-radarr.md) 的*抓取时会发生什么*第 5 步中。

---

## 5. 导入后的流程 {#5-the-post-import-sequence}

### 5.1 触发顺序 {#51-what-fires-in-order}

`DownloadEventHub.Handle(DownloadCompletedEvent)`
(`src/NzbDrone.Core/Download/DownloadEventHub.cs:48-69`)：

```csharp
MarkItemAsImported(trackedDownload, downloadClient);                       // :54  ALWAYS, first

if (trackedDownload.DownloadItem.Removed ||
    !trackedDownload.DownloadItem.CanBeRemoved ||
    trackedDownload.DownloadItem.Status == DownloadItemStatus.Downloading) { return; }   // :56-61

if (!definition.RemoveCompletedDownloads) { return; }                      // :63-66

RemoveFromDownloadClient(message.TrackedDownload, downloadClient);         // :68
```

`RemoveFromDownloadClient`（`:87-103`）的代码如下：

```csharp
_logger.Debug("[{0}] Removing download from {1} history", ...);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);             // :92  deleteData: TRUE
trackedDownload.DownloadItem.Removed = true;
```

所以导入成功之后，发给下载客户端的请求顺序是：

1. **`POST /api/v2/torrents/setCategory`** — 只有配置了导入后的分类时才会执行
   （`QBittorrent.cs:52-69`）。默认跳过。
2. 在这两步之前，而且完全不经过下载客户端：**\*arr 会移动文件**，然后
   `ProcessFolder` 可能会**删除源文件夹本身**
   （`DownloadedEpisodesImportService.cs:209-223`，Radarr 的是 `DownloadedMovieImportService.cs:226-240`）：

   ```csharp
   if (importMode == ImportMode.Move &&
       importResults.Any(i => i.Result == ImportResultType.Imported) &&
       ShouldDeleteFolder(directoryInfo, series))
   {
       _diskProvider.DeleteFolder(directoryInfo.FullName, true);   // recursive
   }
   ```

   `ShouldDeleteFolder`（`:108-153`）在以下情况会拒绝删除：文件夹里还留有能被解析且不是样本的视频文件（`:117-133`），或者剩下一个大于 10 MB 的 `.rar`（`:135-139`）。单文件移动成功之后，这两种情况都不会出现，所以文件夹**会**被删除。`IOException` 会被捕获，并以 Debug 级别记录日志（`:219-222`）。
3. **`POST /api/v2/torrents/delete`**，参数为 `hashes=<lowercase hash>&deleteFiles=true`
   （`QBittorrent.cs:335`，`QBittorrentProxyV2.cs:190-202`）。

还有两个事件也会调用同一个 `RemoveFromDownloadClient(…, true)`：

- `DownloadFailedEvent`（`DownloadEventHub.cs:26-46`），受每个客户端的 `RemoveFailedDownloads` 控制（默认 `true`，`DownloadClientDefinition.cs:18`）。注意 `TrackedDownload.Fail()` 会无条件地设置 `DownloadItem.CanBeRemoved = true`（`src/NzbDrone.Core/Download/TrackedDownloads/TrackedDownload.cs:39-46`，注释为："Set CanBeRemoved
  to allow the failed item to be removed from the client"）——**所以即使做种限制的门控另有规定，失败的下载也会被删除。**
- `DownloadCanBeRemovedEvent`（`:71-85`）。

`RemoveItem` 抛出的 `NotSupportedException` 会降级为提示 "Removing item not supported by your download client ({0})."（`:95-98`）；其他异常会以 error 级别记录日志，而且该条目**不会**被标记为 Removed，所以下次轮询时会重试（`:99-102`）。

### 5.2 shim 在 `deleteFiles=true` 时必须做什么 {#52-what-the-shim-must-do-with-deletefilestrue}

这和 `internal/sabnzbd` 对 `mode=history&name=delete` 做的决定一样，原因也相同。来自 `internal/sabnzbd/api.go:596-609`：

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

qBittorrent 的情况形式相同，只有一点不同：在这个 API 上，删除数据是*客户端*的事，不是 \*arr 的事，因为 `RemoveItem` 不会调用 `DeleteItemData`（§1.15）。但上面第 2 步中 \*arr 已经通过挂载点把文件夹删掉了。在 `__magic__` 下，这一操作会写入一个墓碑标记：条目从 `__magic__` 里消失，但在 `__all__` 里保持原样，在每个过滤目录里也都还在，在调试服务商账户上同样还在（[magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)）。

所以：

- **`torrents/delete` 只删除 shim 为 \*arr 保留的 torrent *记录*。** 返回 200。
- **`deleteFiles` 不能删除服务商那边的 torrent。** \*arr 刚导入的版本仍然是从它那里提供的，删掉它就等于毁掉了被导入的东西。真正删除才说得通的地方，是那些从来没有被导入过的 torrent，也就是下载失败的那条路径。但即使在那里，debrid torrent 也是共享的库状态，而不是临时下载，所以安全的默认做法是：**永远不删除服务商的 torrent，只写墓碑。** 在面向用户的文档里要把这点说清楚，就像 [sabnzbd.md](../guides/sonarr-radarr.md) 在 *What works, and what does not* 下面做的那样。
- 对于**未知 hash** 的 `torrents/delete`，仍然应该返回 200。真正的 qBittorrent 就是这样（wiki，*Delete torrents*："200 | All scenarios"）。如果这里返回错误，就会被记录为错误，并且每次轮询都会一直重试下去。

### 5.3 `MarkItemAsImported` 与导入后的分类 {#53-markitemasimported-and-the-post-import-category}

`QBittorrent.cs:52-69` 会在配置了 `TvImportedCategory` / `MovieImportedCategory` 且与主分类不同时设置导入后的分类。它会在**每一次**导入完成时调用（`DownloadEventHub.cs:54`），且在删除决定之前。

如果某个兼容层真的执行了 `setCategory`，把种子移出了被轮询的分类，那么种子就会从下一次 `torrents/info?category=…` 的结果中消失。这正是该设置的用途，也是 UI 显示 `DownloadClientHasPostImportCategory` 的原因（`src/NzbDrone.Core/Queue/QueueService.cs:84`，数据来源于 `DownloadClientItemClientInfo.HasPostImportCategory`，`QBittorrent.cs:234`）。接受该调用并记录新分类是正确的做法；拒绝它只会产生一条警告（`:62-67`）。

## 6. `Test()` —— 每项检查（按顺序）及其消息 {#6-test--every-check-in-order-and-its-message}

`DownloadClientBase.Test()`（`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`）包住了整个流程：**任何从里面逃出来的异常都会变成**
`ValidationFailure("", "Test was aborted due to an error: " + ex.Message)`。

`QBittorrent.Test(List<ValidationFailure>)`（`:418-429`）：

```csharp
failures.AddIfNotNull(TestConnection());
if (failures.HasErrors()) { return; }     // a *warning* does not stop the rest
failures.AddIfNotNull(TestCategory());
failures.AddIfNotNull(TestPrioritySupport());
failures.AddIfNotNull(TestGetTorrents());
```

### 6.1 `TestConnection`（`:431-509`） {#61-testconnection-431-509}

每个分支都会 **return**，因此此方法最多只返回一个失败项。

| 顺序 | 条件 | 属性 | 消息 |
|---|---|---|---|
| 1 | `_proxySelector.GetProxy(Settings, force: true).GetApiVersion(Settings)`，强制重新检测（`:435`） | | |
| 2 | 版本 `< 1.5`（`:436`） | `Host` | "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| 3 | 版本 `< 1.6` **且**已设置 category（`:445-455`） | `Category` | "Category is not supported" / 详情 "Categories are not supported until qBittorrent version 3.3.0. Please upgrade or try again with an empty Category." |
| 4 | 版本 `>= 1.6` **且** category 为空（`:456-464`） | `TvCategory` / `MovieCategory` | **警告**，"Category is recommended" / "{appName} will not attempt to import completed downloads without a category." |
| 5 | 先调用 `GetConfig`，再调用 `RemovesCompletedDownloads(config)`（`:467-474`） | `""` | "qBittorrent is configured to remove torrents when they reach their Share Ratio Limit" / 详情中提到 Options → BitTorrent → Share Ratio Limiting |

异常映射（`:476-506`）：

| 捕获的异常 | 属性 | 消息 |
|---|---|---|
| `DownloadClientAuthenticationException` | 如果设置了 api key，则为 `ApiKey`，否则为 `Username` | "Authentication Failure" / "Please verify your credentials. Also verify if the host running {appName} isn't blocked from accessing {clientName} by WhiteList limitations…" |
| `WebException` 且 `Status == ConnectFailure` | `Host` | "Unable to connect to qBittorrent" / "Please verify the hostname and port." |
| 其他任何 `WebException` | `""` | "Unknown exception: {message}" |
| 其他任何 `Exception` | `Host` | "Unable to connect to qBittorrent"，`DetailedDescription = ex.Message` |

注意，第 4 种情况是 **警告**。`:421` 处的 `failures.HasErrors()` 对警告返回 false，所以没有设置 category 时，其余三项检查仍会继续运行。

### 6.2 `TestCategory`（`:511-556`）——"category does not exist" 流程 {#62-testcategory-511-556--the-category-does-not-exist-flow}

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

失败:属性 `TvCategory` / `MovieCategory`(或 `TvImportedCategory` / `MovieImportedCategory`),
message "Configuration of category failed",detail "{appName} was unable to add the label to
qBittorrent."

所以 shim 有两种选择:要么预先把配置好的分类都放进去,让 `torrents/categories` 里已经包含它们;要么接受 `createCategory`,并在紧接着的下一次 `torrents/categories` 响应里体现出来。**没有第三种选择**。客户端会重新读取,如果键还是缺失就会失败。分类名称是**精确**匹配的,区分大小写(使用默认序号比较器的 `Dictionary<string, …>.ContainsKey`)。

注意 `TvImportedCategory` 的处理:导入后的分类在这里也会被检查和创建,即使它只在导入之后才会用到。如果你设置了它,它就必须存在。

`QBittorrentSettingsValidator`(`QBittorrentSettings.cs:23-24`)在发出任何请求之前,就already会拒绝不匹配正则 `^([^\\\/](\/?[^\\\/])*)?$` 的分类名称,也就是不能有反斜杠、不能有 `//`,也不能以 `/` 开头或结尾。

### 6.3 `TestPrioritySupport`（`:558-597`）——`queueing` 健康检查 {#63-testprioritysupport-558-597--the-queueing-health-check}

```csharp
var recentPriorityDefault = Settings.RecentTvPriority == (int)QBittorrentPriority.Last;
var olderPriorityDefault  = Settings.OlderTvPriority  == (int)QBittorrentPriority.Last;
if (olderPriorityDefault && recentPriorityDefault) { return null; }   // :563-566  the default: nothing checked

var config = Proxy.GetConfig(Settings);
if (!config.QueueingEnabled) { … }                                    // :572-588
```

失败属性是 `nameof(Settings.RecentTvPriority)` 或 `nameof(Settings.OlderTvPriority)`（按这个顺序检查），消息为 "Queueing Not Enabled"，详情为 "Torrent Queueing is not enabled in
your qBittorrent settings. Enable it in qBittorrent or select 'Last' as priority."

这里的异常会变成 `("", "Unknown exception: {message}")`（`:590-594`）。

模型中 `queueing_enabled` 默认为 **`true`**（`QBittorrentPreferences.cs:41`），所以省略该键的 shim 会通过检查。但如果 `topPrio` 是空操作，这样省略就等于撒谎。报告 `queueing_enabled: false` 是诚实的做法，而且只有当操作者把优先级设置改成了 `Last` 以外的值时，才会产生这个失败。

### 6.4 `TestGetTorrents`（`:599-612`） {#64-testgettorrents-599-612}

`Proxy.GetTorrents(Settings)`; any exception becomes `("", "Failed to get the list of torrents:
{exceptionMessage}")`. This is the check that catches a malformed `torrents/info` body — a JSON object
instead of an array, a bad enum, a non-numeric `size`.

### 6.5 `dht` 检查 {#65-the-dht-check}

There is **no** dedicated DHT check in `Test()`. `dht` is consulted at grab time
(`:73-76`, magnets without trackers) and at poll time (`:288`, the `metaDL` branch). A shim reporting
`dht: false` passes the connection test and then refuses every trackerless magnet with
`ReleaseDownloadException("Magnet not supported by download client. …")`
(`TorrentClientBase.cs:115`). **Report `dht: true`.**

## 7. shim 应当了解的解析与导入影响 {#7-parsing-and-import-consequences-a-shim-should-know}

### 7.1 `name` 变为 `Title`，而 `Title` 用于三件不同的事 {#71-name-becomes-title-and-title-is-used-for-three-different-things}

`DownloadClientItem.Title = torrent.Name`（`QBittorrent.cs:232`）。下游会用到它：

1. **剧集/电影识别。** `CompletedDownloadService.Check` 会执行 `_parsingService.GetSeries(trackedDownload.DownloadItem.Title)`（`CompletedDownloadService.cs:95`）。如果返回 null，它会回退到按 `DownloadId` 查找抓取历史（`:99-102`）。如果连这个也找不到，就会报 "Series title mismatch; automatic import is not possible." 并设置 `ImportBlocked`（`:104-110`）。Radarr 的对应逻辑在 `ProcessFolder` 里，它读取 `_historyService.FindByDownloadId(downloadClientItem?.DownloadId ?? "")`（`DownloadedMovieImportService.cs:193-194`）。
   **这就是 shim 必须按 \*arr 计算出的精确 infohash 来匹配的第二个原因**（§1.7）。历史回退是按 `DownloadId` 匹配的，所以哈希不一致时，标题路径和回退路径都会失效。
2. **用于导入决策的发布名解析。** `downloadClientItemInfo = Parser.Parser.ParseTitle(downloadClientItem.Title)`（Sonarr `ImportDecisionMaker.cs:80`；Radarr 的 `ParseMovieTitle`，`:80`），结果分别赋给 `LocalEpisode.DownloadClientEpisodeInfo` 和 `LocalMovie.DownloadClientMovieInfo`（`:94` / `:92`）。
3. **日志行和队列 UI。**

**Sonarr 的标题回退门槛。** `AggregateEpisodes.GetBestEpisodeInfo`（`src/NzbDrone.Core/MediaFiles/EpisodeImport/Aggregation/Aggregators/AggregateEpisodes.cs:29-57`）：

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

使用下载客户端标题代替文件名需要通过三道门槛：`!OtherVideoFiles`、文件名本身不是 scene 标题、客户端标题不是整季解析。也就是说，只有单文件、且不是 scene 命名的发布，种子名才能起到补救作用。

Radarr **没有**对应的单一胜出门槛。`LocalMovie.OtherVideoFiles` 确实存在（`src/NzbDrone.Core/Parser/Model/LocalMovie.cs:36`），但电影的解析信息不是挑选出来的，而是通过按置信度排序的增强器链合并而成（`AggregateQuality.cs:25-121`）。下载客户端标题会输入这些增强器，而电影身份来自文件夹解析加抓取历史（`DownloadedMovieImportService.cs:192-195`）。

**`OtherVideoFiles`**（`ImportDecisionMaker.cs:85`、`:100`，Radarr 为 `:83`、`:98`）：

```csharp
var nonSampleVideoFileCount = sceneSource ? GetNonSampleVideoFileCount(newFiles, series, downloadClientItemInfo, folderInfo) : videoFiles.Count;
…
OtherVideoFiles = nonSampleVideoFileCount > 1
```

`ProcessFolder` 始终传入 `sceneSource: true`（`DownloadedEpisodesImportService.cs:201`）。因此，只要文件夹里有两个或以上的非样本视频，就会设置 `OtherVideoFiles`，该文件夹中的每个文件都会被排除在下载客户端标题的考虑范围之外。

**为什么这在 zurg 上很重要。** Real-Debrid 会改写会触发其文件名屏蔽规则的发布名，包括 `WEB-DL`、`WEB.x264` 和 `WEB.H264`（仅限这种大小写形式），以及任意大小写的 `WEBRip`、`BDRip`、`HDRip`、`DVDRip`、`HDTV.x264`、`HDTV.XviD`、`BluRay.x264` 和 `p.BluRay.DTS`（截至 2026-10-14 的测试结果）。另外，当两个发布名冲突时，zurg 会追加后缀。这两种情况都可能导致 `torrent.name` 不再解析为抓取的那个发布。详见单仓库 `CLAUDE.md` 中的 RD 451 章节。后果按顺序如下：识别会回退到抓取历史（如果哈希匹配，这仍然可以）；Sonarr 的逐文件解析接管（对文件夹内命名良好的文件来说没问题）；而 `__magic__` 下的文件夹名称，也就是 `DownloadedEpisodesImportService.cs:184` 处 `Parser.ParseTitle(directoryInfo.Name)` 读取的内容，则成了另一个必须保持可解析的东西。

### 7.2 导入文件夹扫描会丢弃整个子树 {#72-the-import-folder-scan-drops-whole-subtrees}

`DiskScanService.FilterPaths`（`src/NzbDrone.Core/MediaFiles/DiskScanService.cs:232-246`），用在
下载文件夹上，位置是 `DownloadedEpisodesImportService.cs:185`（Radarr 对应的是
`DownloadedMovieImportService.cs:202`），并设置 `filterExtras: true`：

```csharp
private static readonly Regex ExcludedExtrasSubFolderRegex = new Regex(@"(?:\\|\/|^)(?:extras|extrafanart|behind the scenes|deleted scenes|featurettes|interviews|other|scenes|samples|shorts|trailers)(?:\\|\/)", …IgnoreCase);   // :72
private static readonly Regex ExcludedSubFoldersRegex      = new Regex(@"(?:\\|\/|^)(?:@eadir|\.@__thumb|plex versions|\.[^\\/]+)(?:\\|\/)", …IgnoreCase);   // :73
private static readonly Regex ExcludedExtraFilesRegex      = new Regex(@"(-(trailer|other|behindthescenes|deleted|featurette|interview|scene|short)\.[^.]+$)", …IgnoreCase);   // :74
private static readonly Regex ExcludedFilesRegex           = new Regex(@"^\.(_|unmanic|DS_Store$)|^Thumbs\.db$", …IgnoreCase);   // :75
```

**Radarr 的 extras 正则只有一处不同**：它用的是 `sample[s]?`，而不是 `samples`
（Radarr `DiskScanService.cs:72`），所以 Radarr 会丢弃 `sample/` 文件夹，而 Sonarr 只会丢弃
`samples/`。四个正则里的其余部分在两个仓库中完全一致。

注意 `ExcludedSubFoldersRegex` 里的 `\.[^\\/]+` 这一项：**任何以点开头的目录部分都会被丢弃，
不管嵌套多深**。匹配时用的是 `basePath.GetRelativePath(path)`，所以它只作用于导入文件夹
内部的路径。挂载点的上级目录里有点号也没关系，不会有影响。

只有扩展名在 `MediaFileExtensions.Extensions` 中的文件才会进入这个过滤器
（`DiskScanService.GetVideoFiles`，`:202-215`）。

### 7.3 样本检测会读取文件 {#73-sample-detection-reads-the-file}

`GetNonSampleVideoFileCount`（`ImportDecisionMaker.cs:216-234`）会对文件夹中的**每一个**视频文件调用 `_detectSample.IsSample(...)`。`DetectSample.IsSample`（`src/NzbDrone.Core/MediaFiles/EpisodeImport/DetectSample.cs:27-45`）只会对特殊集、`.flv` 和 `.strm` 直接短路返回（`:78-101`）。其他文件则会调用 `_videoFileInfoReader.GetRunTime(path)`，也就是通过挂载点对文件运行 **ffprobe**，然后与根据预期时长推导出的最小时长做比较（`:103-121`）。运行时长恰好为 0 会被当作**样本**（`:107-111`）。如果读不到时长，就会记录日志 "Failed to get runtime from the file, make sure ffprobe is available"，并返回 Indeterminate（`:38-42`）。

`ShouldDeleteFolder`（`DownloadedEpisodesImportService.cs:117-133`）会在移动之后，对剩下的文件再做一遍同样的检查。

所以导入一个包含 N 个文件的发布，在移动任何文件之前，至少要对 debrid 后端打开 N 次 ffprobe。在 zurg 挂载上，这是实实在在的开销，而且从客户端这一侧无法避免。

### 7.4 `ProcessFolder` / `ProcessFile` 中的拒绝逻辑 {#74-the-refusals-in-processfolder--processfile}

| 条件 | 结果 | 行号（Sonarr） |
|---|---|---|
| 导入路径是剧集/电影文件夹 | `ImportRejectionReason.SeriesFolder` — "Import path is mapped to a series folder"（Radarr 为 `MovieFolder`，"…a movie folder"） | `:175-182`（Radarr `:183-190`） |
| 文件夹名无法匹配到已知的剧集/电影 | `UnknownSeriesResult("Unknown Series")` | `:160-168` |
| 文件名以 `._` 开头 | `InvalidFilePath` | `:251-259` |
| 扩展名在 `FileExtensions.DangerousExtensions` 中 | `DangerousFile` | `:263-271` |
| 扩展名在 `FileExtensions.ExecutableExtensions` 中 | `ExecutableFile` | `:273-281` |
| 扩展名不在 `MediaFileExtensions.Extensions` 中 | `UnsupportedExtension` | `:283-293` |

**`SeriesPathExists` / `MoviePathExists` 是最容易坑 `__magic__` 布局的那个。** 如果 \*arr 的根文件夹是 `/mnt/zurg/__magic__/tv`，而某个剧集文件夹是 `/mnt/zurg/__magic__/tv/The Show`，那么恰好*就是*剧集文件夹的导入路径会被直接拒绝。所以下载文件夹（`content_path`）必须和根文件夹是同级关系，而不能放在根文件夹里面。这也是 [sabnzbd.md](../guides/sonarr-radarr.md) 里已经规定的做法：`save_path` = `/mnt/zurg/__magic__/__all__`，根文件夹为 `/mnt/zurg/__magic__/tv` 和 `/mnt/zurg/__magic__/movies`，下载内容位于 `/mnt/zurg/__magic__/__all__/<release>`。

`_UNPACK_` 和 `_FAILED_` 会在解析前从文件夹名中去掉（`GetCleanedUpFolderName`，`:311-317`）。

当下载客户端中存在对应项目时，`IsFileLocked` 会被**完全跳过**（`:187-199`，`:295-304`）。文件锁检测只会在手动扫描或根文件夹扫描时运行，所以垫片完全不用担心它。

## 8. 健康检查 {#8-the-health-checks}

这三项都与 SAB 客户端共用,并在
[sabnzbd-client-contract.md §6](sabnzbd-client-contract.md)中分析。下面是 qBittorrent 特有的部分:

- **`RemotePathMappingCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs:59-173`)
  会遍历 `client.GetStatus().OutputRootFolders`。对 qBittorrent 来说,这里只有一个文件夹,由 `QBittorrent.cs:377-407` 计算得出:先取全局的 `save_path`,再被所配分类的 `savePath` 覆盖或扩展(§1.5)。这个路径必须是**运行 \*arr 的操作系统**下的有效路径(`:68-113`),并且必须**在 \*arr 所在的主机上存在**(`:115-158`)。它不需要可写。
  `IsLocalhost` 的判断条件是 `Settings.Host == "127.0.0.1" || Settings.Host == "localhost"`(`:406`),它只决定会显示三条错误信息中的哪一条。
- **`DownloadClientRemovesCompletedDownloadsCheck`**
  (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:33-66`)只要 `GetStatus().RemovesCompletedDownloads` 为 true(也就是 §1.4 推导出的标志为 true),就会发出警告。只要 `max_ratio_enabled` 和 `max_seeding_time_enabled` 保持为 false(§3.5 的配方已经这样设置),它就不会出声。
- **`DownloadClientRootFolderCheck`** 是两个仓库真正存在差异的地方:Sonarr 只在根文件夹*等于*输出文件夹时发出警告,Radarr 还会在根文件夹*包含*输出文件夹时发出警告。完整分析见 [sabnzbd-client-contract.md §6.1](sabnzbd-client-contract.md)。实际规则在这里是一样的:不要把根文件夹设在保存路径本身或其上层,也不要放在其内部。比如 `/mnt/zurg/__magic__/tv` 与 `/mnt/zurg/__magic__/__all__` 是同级目录。

---

## 9. Sonarr 与 Radarr —— 完整差异 {#9-sonarr-vs-radarr--the-complete-diff}

| 文件 | 差异 |
|---|---|
| `QBittorrent.cs` | `TvCategory`→`MovieCategory`、`TvImportedCategory`→`MovieImportedCategory`、`RecentTvPriority`→`RecentMoviePriority`、`OlderTvPriority`→`OlderMoviePriority`、`RemoteEpisode`→`RemoteMovie`；`remoteEpisode.IsRecentEpisode()` → `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie`（`:80`、`:137`）。**行号一一对应。** |
| `QBittorrentSettings.cs` | 同样的重命名；默认分类从 `"tv-sonarr"` 改为 `"radarr"`（`:36`）；帮助文本标记从 `…EpisodeHelpText` 改为 `…MovieHelpText`。行号一致。 |
| `QBittorrentProxyV2.cs` | 分类重命名；`new[] { HttpStatusCode.Forbidden }` → `[HttpStatusCode.Forbidden]`（集合表达式，Sonarr `:401` / Radarr `:400`）；Sonarr 在第 13 行多一个空行 → **对于 N ≥ 14，Sonarr 第 N 行 = Radarr 第 N−1 行**。 |
| `QBittorrentProxyV1.cs` | 分类重命名；同样的空行偏移。 |
| `QBittorrentProxySelector.cs` | Sonarr 的构造函数中有一个多余的双空格（`:46`）；第 3 行多一个空行 → 对于 N ≥ 4，Sonarr 第 N 行 = Radarr 第 N−1 行。 |
| `QBittorrentPreferences.cs`、`QBittorrentTorrent.cs`、`QBittorrentState.cs`、`QBittorrentLabel.cs`、`QBittorrentPriority.cs`、`QBittorrentContentLayout.cs` | **字节完全相同。** |
| `TorrentClientBase.cs` | 全文 `RemoteEpisode`→`RemoteMovie`；获取 `.torrent` 时，Radarr 还会把 HTTP **410 Gone** 和 404 一样处理（`:175`），Sonarr 只处理 404。两者都是 274 行。 |
| `QBittorrentFixture.cs` | 测试内容相同，但顺序不同：`missingFiles_item_should_have_required_properties` 在 Sonarr 的 `:296-315` 和 Radarr 的 `:402-420`。**Radarr 的副本没有 `[Test]` 特性**（`:401` 为空行），所以在 Radarr 中它永远不会运行。Sonarr `:318-421` = Radarr `:297-400`；从 Sonarr `:423` 开始，Radarr 行号 = Sonarr 行号 − 1。Sonarr 共 1000 行，Radarr 共 998 行。 |
| `DiskScanService.cs` | `ExcludedExtrasSubFolderRegex`：Radarr 使用 `sample[s]?`，Sonarr 使用 `samples`（两者都在 `:72`）。其他三个正则表达式相同。 |
| 导入服务 | `Series`/`Episode` 对应 `Movie`；Sonarr 的 `AggregateEpisodes` 标题优先级判断没有 Radarr 对应项（§7.1）。两者都会先拒绝导入路径本身就是媒体库文件夹的情况（Sonarr `:175-182`，Radarr `:183-190`），然后再解析文件夹名（Sonarr `:184`，Radarr `:195`）；Radarr 还会在该处通过 `DownloadId` 查询抓取历史（`:193-194`）。 |
| `ImportApprovedEpisodes.cs` / `ImportApprovedMovie.cs` | `copyOnly` 开关相同，Sonarr `:139-152` / Radarr `:116-129`。 |
| `DiskTransferService.cs`、`DownloadClientBase.cs`、`DownloadEventHub.cs`、`Json.cs`、`HttpClient.cs`、`HttpRequestBuilder.cs` | 共享文件，字节完全相同。 |

除 Series/Movie 的差别外，本文档中的其他所有内容都**字节完全相同**，并且同样适用于两者的相同行号。

---

（之前的译文被拒绝：长度比为 0.04。请严格保持结构。）

## 10. 最小但完整的示例负载 {#10-minimal-but-complete-example-payloads}

### 10.1 `GET /api/v2/app/webapiVersion`

```
2.11.2
```

`Content-Type: text/plain`。不是 JSON，不需要引号，也不需要结尾换行。

### 10.2 `POST /api/v2/auth/login`

请求体：`username=sonarr&password=hunter2`，`application/x-www-form-urlencoded`。

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8
Set-Cookie: SID=8f3c1c0e9a1f4d2f9c0b7a5e3d1f6b2a; path=/

Ok.
```

凭据错误时仍然返回 **200**，响应体是 `Fails.`，从来不会返回 401。

### 10.3 `GET /api/v2/app/preferences`

只读取 §1.4 中的十个键；如果你愿意，可以多发几个，它们会被忽略。

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

硬性要求：

- `save_path` 必须在 **Sonarr/Radarr 所在的主机上** 作为目录存在（`RemotePathMappingCheck`，§8）。
- 同时设置 `max_ratio_enabled: false` 和 `max_seeding_time_enabled: false`，可以让
  `RemovesCompletedDownloads` 保持为 false，这样连接测试（§6.1 第 5 种情况）和健康检查都不会报错。
- 必须设置 `dht: true`，否则客户端会拒绝没有 tracker 的磁力链接（§6.5）。
- `max_ratio_act` 必须是**整数**（§0.6）。

### 10.4 `GET /api/v2/torrents/categories`

```json
{
  "tv": { "name": "tv", "savePath": "" },
  "movies": { "name": "movies", "savePath": "" }
}
```

一个 JSON **对象**，`savePath` 使用 **camelCase** 命名，且不能以 `//` 开头（§1.5）。`savePath` 为空时，输出根文件夹会保持为全局的 `save_path`。

### 10.5 `GET /api/v2/torrents/info?category=tv` —— 一个下载中，一个可导入 {#105-get-apiv2torrentsinfocategorytv--one-downloading-one-importable}

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

硬性要求：

- 一个 JSON **数组**（`List<QBittorrentTorrent>`）；如果是对象，`GetTorrents` 内部会抛出异常，
  导致 `TestGetTorrents`（§6.4）失败。
- `hash` 必须是**小写**（§1.8），并且与 \*arr 从磁力链接或
  `.torrent` 计算出的 infohash 完全一致（§1.7）。
- `size` 单位为**字节**；`progress` 为 0..1 的小数。`RemainingSize = size × (1 − progress)`。
- `eta: 8640000` 表示“未知”，会得到空的 `RemainingTime`（`:622-625`）；Completed 条目
  无论如何都会得到 `TimeSpan.Zero`（`:273`）。
- `state` 取自 §2 的表格，大小写必须完全一致。
- 在 Completed 条目上，`content_path` 必须是**绝对路径、确实存在，且 ≠ `save_path`**（§4.1）。条目未处于 Completed 状态时，它可以为空。
- `ratio_limit: 0` + `ratio: 0` 就是移动方案（§3.5）。
- `category` 必须与客户端配置的分类一致；客户端不会再次过滤，所以要遵守
  查询参数。
- `seeding_time` 可以完全省略——客户端会回退到 `torrents/properties`，
  并且只有在确实生效了做种时间限制时才会这样。

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

只读取 `save_path` 和 `seeding_time`（见 §1.8）。**对未知哈希返回 404**，这就是 `IsTorrentLoaded` 表示"还没加载"的方式（`:110-126`）。

### 10.7 `GET /api/v2/torrents/files?hash=<hash>`

```json
[
  { "index": 0, "name": "Some.Show.S01E03.1080p.WEB.h264-GRP/ep3.mkv", "size": 1073741824, "progress": 1, "priority": 1, "is_seed": true, "piece_range": [0, 2047], "availability": 1 }
]
```

只会读取 `name`，它相对于 `save_path`，并使用 `/` 作为分隔符（§1.13）。在 pre-2.6.1 路径上，顺序很重要：`files[0]` 的最顶层组件会变成输出文件夹。

### 10.8 `POST /api/v2/torrents/add`

请求，urlencoded 表单（如果磁力链接很长，则会以 multipart 形式发送，见 §0.3）：

```
urls=magnet%3A%3Fxt%3Durn%3Abtih%3A3B1A...&category=tv&stopped=False
```

响应：

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8

Ok.
```

除了字面值 `Fails.` 之外的任何内容都算成功（见 §1.7）。空的 200 响应体也可以。

### 10.9 `POST /api/v2/torrents/delete`

请求：`hashes=3b1a1469c180f447b77021074dbbccaef62611e7&deleteFiles=true`

响应：`HTTP/1.1 200 OK`，响应体为空。**哈希未知时也返回 200**（§5.2）。

### 10.10 `POST /api/v2/torrents/createCategory`、`setCategory`、`setShareLimits`、`topPrio`、`setForceStart` {#1010-post-apiv2torrentscreatecategory-setcategory-setsharelimits-topprio-setforcestart}

All of them take urlencoded forms and all answer `200` with an empty body. `topPrio` may answer **409** to mean "queueing is disabled", and the client swallows exactly that status (§1.10). `setShareLimits` may answer **404** to mean "not supported", which is also swallowed (§1.9).

## 11. 与真实 qBittorrent 的差异 —— zurg 模型在哪些地方更窄或更宽 {#11-differences-from-real-qbittorrent--where-zurgs-model-is-narrower-or-wider}

### 11.1 没有做种，因此必须伪造做种限制的判断 {#111-there-is-no-seeding-so-the-seed-limit-gate-has-to-be-faked}

真正的 qBittorrent 会根据实际上传的字节数计算 `ratio`，用户也可以设置全局或单个种子的限制。客户端里的 `CanMoveFiles` 检查，是为了避免在种子还要满足分享率要求时，把文件从它底下抽走（`QBittorrent.cs:240-241`）。debrid 后端从来不上传任何东西。所以 shim 直接声明 `ratio: 0, ratio_limit: 0`，也就是单个种子的限制已经达到。在这个字段能保持真实的唯一意义上，这样写是诚实的，而且全局偏好设置完全不会牵扯进来（§3.5）。

### 11.2 `content_path` 始终是文件夹，绝不是文件 {#112-content_path-is-always-a-folder-never-a-file}

在真实的 qBittorrent 中,单文件种子的 `contentPath()` 返回的是 **文件路径**(`torrentimpl.cpp:582-583`)。在 `__magic__` 下,每个发布都是一个文件夹,里面放着它的文件([magic.md](../guides/magic.md#with-nothing-stored-it-is-__all__s-releases-as-real-folders)),单文件发布也不例外。

结果都对客户端有利:

- `ProcessPath` 总是走 **文件夹** 分支(`DownloadedEpisodesImportService.cs:80-90`),从不走文件分支(`:92-102`)。文件夹分支负责应用 `FilterPaths`、`ShouldDeleteFolder` 以及文件夹名解析,所以额外内容过滤和文件夹标题回退始终生效。
- `ProcessFile` 的逐文件拒绝规则(危险/可执行/不支持的扩展名、`._` 前缀;§7.4)仍然可以触发,只是通过 `GetVideoFiles` 的扩展名过滤触发,而不是通过顶层分支。
- 2.6.1 之前的 `GetImportItem` 遍历(§4.2)也能用,因为 `files[0].name` 总是带着发布文件夹名,但没必要报告这么旧的版本。

需要注意的一点:因为它总是文件夹,`content_path` 始终是 `save_path + "/" + <release folder>`,因此永远不会等于 `save_path`。`DownloadClientQbittorrentTorrentStatePathError` 警告(§4.1)在结构上不可能触发,这是正确的结果,而不是可以依赖的意外。

### 11.3 `name` 不是抓取时的标题，而且可能会变 {#113-name-is-not-the-grabbed-title-and-it-can-change}

真正的 qBittorrent 会使用种子元数据中的名称，而且这个名称不会变。zurg 的名称则来自库：

- Real-Debrid 会重命名文件名触发其 451 拦截的版本（`WEB-DL`、`Rip` 标签，以及几种 source 点 codec 组合，2026-10-14 实测），参见单仓库 `CLAUDE.md` 中的 RD 451 章节。
- 两个版本的名称冲突时，zurg 会追加后缀；修复时，版本会以新的种子 id 重建。
- 名称在每次轮询时都会从库中读取，因此对于 \*arr 已经在跟踪的 id，名称**可能在两次轮询之间发生变化**。

这些都不会破坏跟踪，因为跟踪是以 `DownloadId`（即 infohash）为键，而不是以名称为键。真正会被破坏的是 §7.1 的标题解析路径。由此得出两条规则：

1. **以 \*arr 计算出的 infohash 为键**，绝不要以 zurg 内部的任何东西为键。它是抓取记录、抓取历史和轮询之间唯一的连接点。
2. **保持 `__magic__` 文件夹名可解析**，因为它是文件夹分支读取的回退方案（`DownloadedEpisodesImportService.cs:184`）。

### 11.4 没有进度，也没有元数据阶段 {#114-there-is-no-progress-and-no-metadata-phase}

这里没有可下载的内容，所以 `progress`、`eta`、`dlspeed` 和 `metaDL` 都没有实际意义。这与 SAB 端点文档中记载的限制相同（[sabnzbd.md](../guides/sonarr-radarr.md)，*哪些可用，哪些不可用*：“没有进度。任务要么在排队，要么已完成”）。自然的映射方式是：库中尚未列出该版本时为 **Queued**（`queuedDL`）；一旦列出，*且其文件大小已稳定*，则为 **Completed**（`pausedUP`）。`size` 取后端声明的任何值，以免队列条目显示为空白。

除非同时报告 `dht: true`，否则不要将 `metaDL` 用于等待状态。只有在这种情况下它才是 Queued（`:288-297`）。`queuedDL` 无条件生效，也不附带任何消息。

不要为短暂的等待使用 `stalledDL`、`error` 或 `missingFiles`：这三者都是 **Warnings**（§2），会在队列中以问题的形式显示出来。

### 11.5 删除只是隐藏，不会真正销毁 {#115-deleting-hides-it-does-not-destroy}

`torrents/delete?deleteFiles=true` 在真正的 qBittorrent 上会移除种子，并执行 `rm -rf` 删除它的数据。
这里它只删除记录。这个版本仍然通过服务商的种子提供资源，而 \*arr 想删掉的那个文件夹，已经通过挂载点自己打上了墓碑标记（§5.2，[magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)）。这和 `internal/sabnzbd/api.go:596-609` 中 `internal/sabnzbd` 的 `deleteFromHistory` 所记录的思路完全一致。

### 11.6 客户端可能请求、但没有对应功能可施加的所有操作 {#116-everything-the-client-can-ask-for-that-has-nothing-to-apply-to}

`sequentialDownload`、`firstLastPiecePrio`、`contentLayout`、`stopped`/`paused`、`setForceStart`、
`topPrio`、`setShareLimits`、`dlLimit`/`upLimit`：接受这些请求，返回 200，但什么都不做。只有两个在被拒绝时会产生可观察的影响：`topPrio`（409 会被忽略，其他错误会输出警告）和 `setShareLimits`（404 会被忽略）。而且这两个都不会阻止抓取。

`contentLayout` 值得说明一下。这个设置存在于 \*arr 中，目的就是强制 qBittorrent 保留一个顶层文件夹，从而让 `content_path != save_path`。在 `__magic__` 模式下，无论如何内容布局都是文件夹（见 §11.2），所以这个参数实际上不起作用，操作者可以保持 Default。

---

## 12. 实现检查清单（14 点） {#12-implementation-checklist-14-points}

1. **仅支持 API v2。** 对 `/api/v2/app/webapiVersion` 返回 `2.11.2`；对 `/version/api` 返回 **404**，让 v1 探测干净地失败。

2. **认证：** 接受 `Authorization: Bearer <key>` 请求头、预先发送的 `Authorization: Basic`、`SID` cookie，或者什么都不带。对 `POST /api/v2/auth/login` 返回 **200 + `Ok.` + `Set-Cookie: SID=…`**；凭据错误时返回 `Fails.`（仍为 200），绝不返回 401。不要要求 `Referer` 或 `Origin`。

3. **错误用 HTTP 状态码表示，而不是 JSON。** 403 表示"重新登录"，会重试一次；第二次 403 要以连接错误的形式抛出，而不是认证错误。404 在 `torrents/properties`（未知 hash）和 `torrents/setShareLimits`（不支持）上有意义；409 在 `torrents/topPrio`（队列功能关闭）上有意义。其他所有情况都必须返回 200。

4. **`torrents/add` 要同时解析两种表单编码**：urlencoded，以及当任一值超过 1024 字节或上传了 `.torrent` 文件时使用的 multipart。每个布尔值都要同时接受 `True`/`False` 和 `true`/`false`。

5. **`torrents/info` 返回数组；`torrents/categories` 返回对象**，字段名为驼峰式的 `savePath`。遵守 `category` 查询参数，客户端不会再次过滤。

6. **hash 在所有响应中都用小写，在所有请求中都不区分大小写匹配**，并且始终使用 \*arr 从 magnet 或 `.torrent` 计算出的 infohash。`torrents/properties` 是唯一可能收到 `torrents/info` 所用任意大小写形式 hash 的路由。

7. **移动配方：** `state: "pausedUP"`、`ratio: 0`、`ratio_limit: 0`、`seeding_time_limit: -2`、`inactive_seeding_time_limit: -2`。少了任何一项，导入就会变成**复制**，也就是整个发布内容都会被完整下载。需要说明的是，\*arr 的 "Remove Completed" 设置必须保持开启，因为这个 shim 无法替它补偿。

8. **`content_path` 必须是绝对路径，必须存在于 \*arr 主机上，并且不能等于 `save_path`。** 只有在发布内容真正可以导入时才设置它，也就是已被列出，且文件大小已稳定。在此之前，报告 `queuedDL`，让客户端继续轮询；没有重试次数限制。

9. **`save_path`**（来自 `app/preferences`，加上任何分类的 `savePath`）必须作为目录存在于 \*arr 主机上，否则 `RemotePathMappingCheck` 会报错。它不需要可写。绝不要输出以 `//` 开头的 `savePath`。

10. **保持连接测试通过：** `dht: true`、`queueing_enabled: true`、`max_ratio_enabled: false`、`max_seeding_time_enabled: false`、`max_ratio_act: 0`（整数）。要么预先创建已配置的分类，要么遵守 `createCategory`，并在紧接着的下一次 `torrents/categories` 响应中体现出来。

11. **`torrents/delete` 只删除记录，不做其他操作。** 对于 provider 的 torrent，忽略 `deleteFiles`，正如 `internal/sabnzbd` 的 `deleteFromHistory` 忽略 `del_files` 一样（`internal/sabnzbd/api.go:596-609`）。对未知 hash 返回 200。接受 `setCategory` 并记录新的分类。

12. **预计 \*arr 在 Move 导入后会自行 `rm -rf` 发布文件夹**（`DownloadedEpisodesImportService.cs:209-223`）。这会变成一个 `__magic__` 墓碑，之后它还会调用 `torrents/delete`。这两者都是正常的，都不会破坏任何东西。

13. **只使用 §2 中的状态名，大小写必须完全一致。** 未知的状态名在这里不会抛出异常（不像 SAB），但会记录日志并默认为 Downloading。对于临时等待，绝不要使用 `stalledDL`、`error` 或 `missingFiles`，这三个都会被视为警告（Warnings）。

14. **不要把根文件夹设在输出文件夹本身或其上级。** 当 `save_path` 为 `/mnt/zurg/__magic__/__all__` 时，应使用 `/mnt/zurg/__magic__/tv` 和 `/mnt/zurg/__magic__/movies` 作为根文件夹，并把发布内容保存在 `/mnt/zurg/__magic__/__all__/<release>` 下。否则 `SeriesPathExists`/`MoviePathExists` 会直接拒绝导入（§7.4），而 Radarr 的 `DownloadClientRootFolderCheck` 每次启动都会报错。
