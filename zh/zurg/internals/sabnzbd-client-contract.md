# SABnzbd API 协议（Sonarr 和 Radarr 所用，develop 分支） {#sabnzbd-api-contract-as-consumed-by-sonarr-and-radarr-develop}

来源依据：2026-08-22 从 `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...` 获取的文件。下面每个行号都是从这些文件里读出来的。

这里保留这些内容，用来说明 `internal/sabnzbd` 为什么要以现在的结构返回数据。在没看过这里对应的段落、弄清楚客户端如何处理该字段之前，请不要修改这个包里的任何内容。标签写错不会报错，只会让客户端读到零值；枚举值写错则会在它的反序列化器里抛出异常，连带让整次轮询中断。关于如何让 Sonarr 或 Radarr 指向 zurg，请参阅 [sabnzbd.md](../guides/sonarr-radarr.md)。

除非某个小节另有说明，**两个仓库中的 SAB 文件除了 UTF-8 BOM 以及 `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` 的重命名之外，字节完全一致，行号也一一对应。** 因此，每一条 `Sabnzbd*` 引用都同时适用于两个仓库的同一行。两个仓库中的路径都是 `src/NzbDrone.Core/Download/Clients/Sabnzbd/...`。已核实的差异记录在 §6 中。

这里没有任何关于 SAB 本身的推测：每一条论断都描述的是*客户端*的行为。凡是涉及 Newtonsoft.Json 或 .NET 运行时语义（而不是 Sonarr 代码）的地方，我都会明确说明。

## 0. 传输层规则（这些规则最先生效） {#0-transport-level-rules-these-bite-first}

### 0.1 URL 结构 {#01-url-shape}

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

- 基础 URL：`HttpRequestBuilder.BuildBaseUrl`（`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-66`）
  = `{http|https}://{Host}:{Port}{UrlBase}`；如果 `UrlBase` 前面没有 `/`，会自动加上。
  接口端点就是它加上 `/api`（`SabnzbdProxy.cs:38-44`）。
- 后缀参数总是排在最后，所以 **`apikey`（或 `ma_username`+`ma_password`）和 `output=json`
  是最后的查询参数**（`HttpRequestBuilder.cs:82` — `QueryParams.Concat(SuffixQueryParams)`）。
- 每次调用都带 `Accept: application/json`，也都带 `output=json`。任何地方都没有 `output=xml` 的分支。
- API key 和用户名/密码是**互斥的**：只要有 api key，就会忽略 `ma_username`/`ma_password`。

### 0.2 始终返回 HTTP 200，即使出错也是如此 {#02-always-answer-http-200--even-for-errors}

`HttpClient.Execute` 会对任何 >= 400 的状态码抛出异常（`src/NzbDrone.Common/Http/HttpClient.cs:106-121`；
`HttpResponse.cs:54` — `HasHttpError => (int)StatusCode >= 400`；429 会变成 `TooManyRequestsException`）。
`SabnzbdProxy.ProcessRequest`（`SabnzbdProxy.cs:199-215`）会把它转换成 `DownloadClientException("Unable to connect to SABnzbd, {0}")`。

`HttpException` 的消息是 `"HTTP request failed: [401:Unauthorized] [GET] at [url]"`（`src/NzbDrone.Common/Http/HttpException.cs:18`），**消息里不包含响应体**。所以返回 `{"error":"API Key Incorrect"}` 的 401 不会被 `TestAuthentication` 识别（`Sabnzbd.cs:424,429` 是通过 `ex.Message` 来匹配的），连接测试会改为显示通用的 "Test was aborted due to an error"。

**模拟 SAB：返回 HTTP 200 加上 `{"status": false, "error": "..."}`。**

### 0.3 反序列化器设置（决定所有字段名和类型的问题） {#03-deserializer-settings-drives-every-field-name-and-type-question}

所有 SAB 负载都经过 `NzbDrone.Common.Serializer.Json`（`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`）处理。注意是 **Newtonsoft**，不是 System.Text.Json：

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

这意味着以下后果（都是 Newtonsoft 的行为，不是 Sonarr 代码本身的逻辑）：

| 设置 | 对模拟器的影响 |
|---|---|
| `CamelCasePropertyNamesContractResolver` | C# 的 `Storage` 会绑定 `storage`，`PP` 绑定 `pp`，`Misc` 绑定 `misc`。Newtonsoft 还会退回到不区分大小写的属性匹配，所以 SAB 真正的 snake_case/小写键两种方式都能绑定上。 |
| `StringEnumConverter`（全局） | 作用于 `SabnzbdDownloadStatus`，它**没有**单独的属性级转换器。无法识别的枚举名会抛出 `JsonSerializationException`。整数也可以接受（`AllowIntegerValues` 默认为 true）。 |
| `NullValueHandling.Ignore` | 读取时也生效：JSON 的 `null` 会让 C# 成员保持构造函数中的值。所以 `"categories": null` 会保留构造函数里的空列表，但 `"misc": null` 会让 `Misc` 保持为 null（没有构造函数默认值）→ NRE，见 §3.4。 |
| `MissingMemberHandling`（默认 `Ignore`） | 负载里多出来的字段没有影响。请发送完整的真实 SAB 响应体。 |
| `Culture`（默认 `InvariantCulture`） | 像 `"1024.00"` 这样的数字字符串必须用 `.` 作为小数点，且不能带千位分隔符。 |

`Json.Deserialize<T>` 只会把 `JsonReaderException` 重新抛出，并附带更友好的提示信息（`Json.cs:39-50`）；
`Json.TryDeserialize<T>` **只**会吞掉 `JsonReaderException` 和 `JsonSerializationException`（`Json.cs:99-117`）。其他异常（比如 timeleft 转换器抛出的 `ArgumentException`，或优先级转换器抛出的 NRE）都会直接往外抛。

---

## 1. 每种模式、每个参数、每个被使用的字段 {#1-every-mode-every-parameter-every-field-consumed}

### 1.1 `mode=version` — `SabnzbdProxy.GetVersion`（`SabnzbdProxy.cs:85-95`） {#11-modeversion--sabnzbdproxygetversion-sabnzbdproxycs85-95}

请求：`GET /api?mode=version&apikey=KEY&output=json`

响应模型 `SabnzbdVersionResponse`（`Responses/SabnzbdVersionResponse.cs:5`）：

| JSON key | C# type | Notes |
|---|---|---|
| `version` | `string` | 唯一会被读取的字段。 |

通过 `Json.TryDeserialize` 读取；解析失败时 `Version == null`（`SabnzbdProxy.cs:89-92`）。

解析逻辑（`Sabnzbd.cs:334-366`），正则在 `Sabnzbd.cs:38`：

```csharp
// patch can be a number (releases) or 'x' (git)
private static readonly Regex VersionRegex = new Regex(@"(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+|x)", RegexOptions.Compiled);
```

- 正则没有锚定（unanchored），所以 `4.5.0RC1` 和 `2.0.0beta1` 也能解析（测试数据 `SabnzbdFixture.cs:523,553`）。
- `patch` 可能是字面量 `x`（git 构建版本），会被替换成 `0`（`Sabnzbd.cs:351`）。
- **只有两段的版本**（`"4.5"`）匹配不上，返回 `null`，然后校验失败。
- 字符串 `"develop"`（不区分大小写）会被特殊处理，当作 `3.0.0`（`Sabnzbd.cs:355-362`），并且只会给出一个*警告*，不会导致失败（`Sabnzbd.cs:380-387`）。

`HasVersion`（`Sabnzbd.cs:294-332`）会再次获取版本（再发一次 `mode=version` 请求），**这个结果没有缓存**。

### 1.2 `mode=get_config` — `SabnzbdProxy.GetConfig`（`SabnzbdProxy.cs:97-104`） {#12-modeget_config--sabnzbdproxygetconfig-sabnzbdproxycs97-104}

请求：`GET /api?mode=get_config&apikey=KEY&output=json`

这里使用的是 `Json.Deserialize`（**不是** Try）。如果请求体格式错误，异常会从 `GetConfig` 中直接抛出。
顶层必须是 `{"config": {...}}`（见 `Responses/SabnzbdConfigResponse.cs:5`）。字段说明见 §3。

### 1.3 `mode=fullstatus` — `SabnzbdProxy.GetFullStatus`（`SabnzbdProxy.cs:106-114`） {#13-modefullstatus--sabnzbdproxygetfullstatus-sabnzbdproxycs106-114}

请求：`GET /api?mode=fullstatus&skip_dashboard=1&apikey=KEY&output=json`

顶层是 `{"status": {...}}`（`Responses/SabnzbdFullStatusResponse.cs:5`）。只读取一个字段：

| JSON 键 | C# | 来源 |
|---|---|---|
| `completedir` | `string CompleteDir` | `SabnzbdFullStatus.cs:9-10` — 注意：是 **`completedir`，没有下划线** |

只有在 `config.misc.complete_dir` **不是**根路径，并且 SAB 版本 >= 2.0 时才会调用此接口（`Sabnzbd.cs:220-226`）。如果 `complete_dir` 是绝对路径，就永远不会调用这个接口，但还是要实现它。

有个值得注意的小问题：真正的响应体是 `{"status": {...}}`，而 `SabnzbdJsonError.Status` 是 `string` 类型，所以 `CheckForError` 里的 `TryDeserialize<SabnzbdJsonError>` 会抛出 `JsonSerializationException`，然后走到纯文本分支，把 `Status = "true"` 设上（`SabnzbdProxy.cs:224-240`）。这个影响不大，但也意味着 fullstatus 永远无法通过 JSON 路径报告错误。

### 1.4 `mode=queue`（读取）— `SabnzbdProxy.GetQueue`（`SabnzbdProxy.cs:116-130`） {#14-modequeue-read--sabnzbdproxygetqueue-sabnzbdproxycs116-130}

请求：`GET /api?mode=queue&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- 只有在配置的分类不为空白时，才会添加 `category`（`SabnzbdProxy.cs:122-125`）。
- 调用方：
  - `Sabnzbd.GetQueue()` 使用 `start=0, limit=0`（`Sabnzbd.cs:57`）。SAB 会把 `limit=0` 理解为“全部”。
  - `Sabnzbd.GetCategories()` 在 2.0 之前的路径上使用 `start=0, limit=1`（`Sabnzbd.cs:229`）。
  - `Sabnzbd.RemoveItem()` 会再调用一次，用来判断条目在队列还是历史记录中（`Sabnzbd.cs:199`）。
- 解析：`Json.Deserialize<SabnzbdQueue>(JObject.Parse(response).SelectToken("queue").ToString())`（`SabnzbdProxy.cs:129`）。**如果顶层缺少 `queue` 键，就会出现 NRE。**

`SabnzbdQueue`（`SabnzbdQueue.cs`）：

| JSON 键 | C# | 类型 | 用途 |
|---|---|---|---|
| `my_home` | `DefaultRootFolder` | `string` | 仅在 SAB < 2.0 上使用，用来解析相对路径的 `complete_dir`（`Sabnzbd.cs:230`）。`SabnzbdQueue.cs:8` 处的注释：“在 Sabnzbd 2.0.0 中已移除，请改用 mode=fullstatus。” |
| `paused` | `Paused` | `bool` | 全局暂停，会与条目（slot）的优先级结合使用（`Sabnzbd.cs:78`）。 |
| `slots` | `Items` | `List<SabnzbdQueueItem>` | |

`SabnzbdQueueItem`（`SabnzbdQueueItem.cs`）：

| JSON 键 | C# 成员 | C# 类型 | SAB 实际的 JSON 类型 | 说明 |
|---|---|---|---|---|
| `status` | `Status` | `SabnzbdDownloadStatus` | 字符串 | 全局 `StringEnumConverter`。遇到未知值 ⇒ `JsonSerializationException` ⇒ 整个 `GetQueue` 抛出异常。 |
| `index` | `Index` | `int` | 数字 | 已读取，但从未使用。 |
| `timeleft` | `Timeleft` | 通过 `SabnzbdQueueTimeConverter` 转换的 `TimeSpan` | 字符串 | 参见 §1.4.1。 |
| `mb` | `Size` | `decimal` | **字符串**（`"1024.00"`） | **单位为兆字节（MB）。** `TotalSize = (long)(Size * 1024 * 1024)`（`Sabnzbd.cs:72`）。 |
| `mbleft` | `Sizeleft` | `decimal` | **字符串** | **单位为兆字节（MB）。** `RemainingSize = (long)(Sizeleft * 1024 * 1024)`（`Sabnzbd.cs:73`）。 |
| `filename` | `Title` | `string` | 字符串 | 会变成 `DownloadClientItem.Title`（`Sabnzbd.cs:71`）。 |
| `priority` | `Priority` | 通过 `SabnzbdPriorityTypeConverter` 转换的 `SabnzbdPriority` | 字符串（`"Normal"`） | 参见 §2。 |
| `cat` | `Category` | `string` | 字符串 | **队列中为 `cat`，历史记录中为 `category`。** |
| `mbleft`/`percentage` | `Percentage` | `int` | **字符串**（`"50"`） | 已读取，但从未使用。 |
| `nzo_id` | `Id` | `string` | 字符串 | Sonarr/Radarr 用来关联所有内容的下载 ID。 |

#### 1.4.1 `timeleft` 格式 — `SabnzbdQueueTimeConverter`（`JsonConverters/SabnzbdQueueTimeConverter.cs:15-28`） {#141-timeleft-format--sabnzbdqueuetimeconverter-jsonconverterssabnzbdqueuetimeconvertercs15-28}

```csharp
var split = reader.Value.ToString().Split(':').Select(int.Parse).ToArray();
switch (split.Length)
{
    case 4: return new TimeSpan((split[0] * 24) + split[1], split[2], split[3]);   // d:h:m:s
    case 3: return new TimeSpan(split[0], split[1], split[2]);                     // h:m:s
    default: throw new ArgumentException("Expected either 0:0:0:0 or 0:0:0 format, but received: " + reader.Value);
}
```

- **必须是 3 或 4 个用冒号分隔的整数。** `"0:08:32"`、`"40:12:14"`、`"1:16:12:14"` 都可以
  （测试夹具 `SabnzbdQueueTimeConverterFixture.cs:14-20`）；`"1"`、`"0:1"`、`"0:0:0:0:1"` 会抛出异常
  （见 `:28-35`）。前导零没问题（`int.Parse`）。
- 抛出的 `ArgumentException` **不会**被 `Json.TryDeserialize` 捕获，`Json.Deserialize` 也不会捕获。
- **空字符串** `""` 拆分后得到 `[""]`，然后 `int.Parse` 会抛出 `FormatException`。绝对不要输出 `""`。
- 完全省略 `timeleft` 是安全的：不会调用转换器，`Timeleft` 保持为 `TimeSpan.Zero`。

### 1.5 `mode=queue&name=delete` — `SabnzbdProxy.RemoveFromQueue`（`SabnzbdProxy.cs:64-72`） {#15-modequeuenamedelete--sabnzbdproxyremovefromqueue-sabnzbdproxycs64-72}

```
GET /api?mode=queue&name=delete&del_files={0|1}&value={nzo_id}&apikey=KEY&output=json
```

`del_files = deleteData ? 1 : 0`（`SabnzbdProxy.cs:68`）。**队列路径上没有 `archive` 参数。**
响应体只经过 `CheckForError` 检查，不做任何反序列化。

### 1.6 `mode=history`（读取）— `SabnzbdProxy.GetHistory`（`SabnzbdProxy.cs:132-146`） {#16-modehistory-read--sabnzbdproxygethistory-sabnzbdproxycs132-146}

请求：`GET /api?mode=history&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- 调用方：`Sabnzbd.GetHistory()`，参数为 `start=0, limit=_configService.DownloadClientHistoryLimit`
  (`Sabnzbd.cs:110`)。两个仓库的默认值都是 **60**
  （Sonarr `src/NzbDrone.Core/Configuration/ConfigService.cs:184`，Radarr `:236`）。
- 提取：`SelectToken("history")`（`SabnzbdProxy.cs:145`）。顶层必须是 `{"history": {...}}`。

`SabnzbdHistory`（`SabnzbdHistory.cs`）：`paused`（`bool`，未使用），`slots` → `Items`。

`SabnzbdHistoryItem`（`SabnzbdHistoryItem.cs`）：

| JSON 键 | C# 成员 | C# 类型 | 说明 |
|---|---|---|---|
| `fail_message` | `FailMessage` | `string` | 会变成 `DownloadClientItem.Message`（`Sabnzbd.cs:132`），并触发 Warning 的特殊处理（§1.6.1）。 |
| `bytes` | `Size` | `long` | **单位是字节，不是 MB**。`TotalSize = sabHistoryItem.Size` 直接原样使用（`Sabnzbd.cs:128`）。这是它与 `mode=queue` 最大的区别。 |
| `category` | `Category` | `string` | 注意：这里用的是 `category`，队列用的则是 `cat`。 |
| `nzb_name` | `NzbName` | `string` | 会读取，但从不使用。 |
| `download_time` | `DownloadTime` | `int`（秒） | 会读取，但从不使用。 |
| `storage` | `Storage` | `string` | 输出路径。见 §1.6.2，这就是会被 `rm -rf` 掉的路径。 |
| `status` | `Status` | `SabnzbdDownloadStatus` | 使用全局的 `StringEnumConverter`。 |
| `nzo_id` | `Id` | `string` | |
| `name` | `Title` | `string` | |

**SAB 的模型里没有任何 `DateTime` 类型的成员，所以对日期格式没有任何约束。**
`completed` / `last_history_update`（真实的 SAB 里是 unix 时间戳）从不读取。真正与时间有关的值只有 `timeleft`（§1.4.1），以及 `download_time`（一个没被读取的秒数整数）。

#### 1.6.1 历史状态 → `DownloadItemStatus`（`Sabnzbd.cs:116-158`） {#161-history-status--downloaditemstatus-sabnzbdcs116-158}

```
Deleted                                   -> skipped entirely (Sabnzbd.cs:116-119)
Failed  + fail_message == "Unpacking failed, write error or disk is full?"
        (InvariantCultureIgnoreCase)      -> DownloadItemStatus.Warning     (:140-144)
Failed  (any other message)               -> DownloadItemStatus.Failed      (:147)
Completed                                 -> DownloadItemStatus.Completed   (:152)
anything else (Verifying/Moving/...)      -> DownloadItemStatus.Downloading (:157)
```

Every history item gets `RemainingSize = 0`, `RemainingTime = TimeSpan.Zero`, `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:129-135`).

`DownloadItemStatus` 本身（`src/NzbDrone.Core/Download/DownloadItemStatus.cs:3-11`）：`Queued=0, Paused=1, Downloading=2, Completed=3, Failed=4, Warning=5`。

#### 1.6.2 `storage` → `OutputPath`（`Sabnzbd.cs:160-176`） {#162-storage--outputpath-sabnzbdcs160-176}

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

该循环会一直走到根目录，并保留最高层的祖先，其最后一段与 `name` 相同。目的是：如果 `storage` 指向任务文件夹内的某个文件，就退回到任务文件夹（fixture `SabnzbdFixture.cs:376-391`）。如果 `storage` 本身已经是任务文件夹，则不会有祖先匹配，`OutputPath == storage`，这正是你想要的结果。

**给模拟器的建议：把 `storage` 设为任务文件夹本身的路径。**

如果 `storage` 为空，`OutputPath` 就会保持为空，`CompletedDownloadService.ValidatePath` 会输出警告 "Download doesn't contain intermediate path, Skipping."（Sonarr `CompletedDownloadService.cs:299-303`）。

### 1.7 `mode=history&name=delete` — `SabnzbdProxy.RemoveFromHistory`（`SabnzbdProxy.cs:74-83`） {#17-modehistorynamedelete--sabnzbdproxyremovefromhistory-sabnzbdproxycs74-83}

```
GET /api?mode=history&name=delete&del_files={0|1}&value={nzo_id}&archive={0|1}&apikey=KEY&output=json
```

```csharp
request.AddQueryParam("del_files", deleteData ? 1 : 0);          // :78
request.AddQueryParam("value", id);                              // :79
request.AddQueryParam("archive", deletePermanently ? 0 : 1);     // :80   <-- inverted
```

调用方（`Sabnzbd.cs:208`）：

```csharp
_proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
```

所以 `deletePermanently == (status is Failed)`，因此：

| 条目状态 | `del_files` | `archive` |
|---|---|---|
| Completed | 1 | **1**（归档） |
| Failed | 1 | **0**（永久删除） |

是的，乍一看有点反直觉，但代码就是这样写的。

### 1.8 `mode=addfile` — `SabnzbdProxy.DownloadNzb`（`SabnzbdProxy.cs:46-62`） {#18-modeaddfile--sabnzbdproxydownloadnzb-sabnzbdproxycs46-62}

```
POST /api?mode=addfile&cat={category}&priority={int}&apikey=KEY&output=json
Content-Type: multipart/form-data; boundary=...
  part: Content-Disposition: form-data; name="name"; filename="<CleanFileName(Release.Title)>.nzb"
        Content-Type: application/x-nzb
```

- multipart 字段的名字就是 `name`，这个 part 带有 `filename`（`SabnzbdProxy.cs:53`，`HttpRequestBuilder.cs:379-395`，在 `:180-195` 输出）。
- 文件名来自 `FileNameBuilder.CleanFileName(release.Title) + ".nzb"`（Sonarr `src/NzbDrone.Core/Download/UsenetClientBase.cs:43`，Radarr `:43`）。
- **`cat` 会忽略方法的 `category` 参数**，直接读取设置（`SabnzbdProxy.cs:50`：`request.AddQueryParam("cat", settings.TvCategory);`，Radarr 用的是 `settings.MovieCategory`）。没有问题，因为调用方传的是同一个值。
- `priority` 是 `SabnzbdPriority` 里的原始 `int`（见 §2），根据发布时间决定用哪个值：
  Sonarr `Sabnzbd.cs:43` 为 `remoteEpisode.IsRecentEpisode() ? Settings.RecentTvPriority : Settings.OlderTvPriority`；
  Radarr `Sabnzbd.cs:43` 为 `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie ? RecentMoviePriority : OlderMoviePriority`。
- 响应 `SabnzbdAddResponse`（`Responses/SabnzbdAddResponse.cs`）：

| JSON 键 | C# | 类型 |
|---|---|---|
| `status` | `Status` | `bool`，会被解析，但**从来不读取** |
| `nzo_ids` | `Ids` | `List<string>`，构造函数初始化为空列表 |

  用 `TryDeserialize` 读取；如果失败，就使用一个模拟的 `{Status=true, Ids=[]}`（`SabnzbdProxy.cs:55-59`）。
  然后是 `Sabnzbd.cs:47-52`：

```csharp
if (response == null || response.Ids.Empty())
{
    throw new DownloadClientRejectedReleaseException(remoteEpisode.Release, "SABnzbd rejected the NZB for an unknown reason");
}

return response.Ids.First();
```

  **`nzo_ids` 必须是非空的字符串数组。** `"nzo_ids": null` 和没有这个字段是一样的（`NullValueHandling.Ignore` 会保留构造函数里的空列表），同样会失败。

### 1.9 队列状态 → `DownloadItemStatus`（`Sabnzbd.cs:60-103`） {#19-queue-status--downloaditemstatus-sabnzbdcs60-103}

```
Deleted                                       -> skipped (Sabnzbd.cs:62-65)
(queue.paused && slot.priority != Force) || slot.status == Paused
                                              -> Paused, and RemainingTime forced to null (:78-84)
Queued | Grabbing | Propagating               -> Queued        (:85-90)
everything else                               -> Downloading   (:93)
```

另外 `Sabnzbd.cs:96-100`：标题以字面量 `"ENCRYPTED /"` 开头的条目会被去掉这 11 个字符，并且该条目会被标记为 `IsEncrypted = true`。

每个队列条目都会设置 `CanBeRemoved = true` 和 `CanMoveFiles = true`（`Sabnzbd.cs:75-76`）。

### 1.10 客户端分类过滤（`Sabnzbd.cs:186-195`） {#110-client-side-category-filter-sabnzbdcs186-195}

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

字符串序号相等。分类为 `*` 的条目只有在配置的分类为空时才会被接受。

### 1.11 代理中存在但从未被调用的模式 {#111-modes-that-exist-in-the-proxy-but-are-never-called}

- `mode=retry&value={id}` (`SabnzbdProxy.cs:148-160`, response `{status, nzo_id}` →
  `Responses/SabnzbdRetryResponse.cs`). `ISabnzbdProxy.RetryDownload` has **no caller** in either repo.
- `Responses/SabnzbdCategoryResponse.cs` (`{"categories": [...]}`, i.e. `mode=get_cats`) is
  **entirely unreferenced** in both repos.
- `Sabnzbd.ValidatePath` (`Sabnzbd.cs:576-592`) is private and never called (dead).

## 2. `SabnzbdDownloadStatus` 和 `SabnzbdPriority` — 确切成员，未知值和 null 的处理 {#2-sabnzbddownloadstatus-and-sabnzbdpriority--exact-members-unknownnull-handling}

### 2.1 `SabnzbdPriority.cs`（完整文件） {#21-sabnzbdprioritycs-complete-file}

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

- `Enum.TryParse<T>(string, out T)` 是**区分大小写**的重载（.NET 语义）。
  `"Normal"` 能解析，但 `"normal"` **不行**。解析失败时 `output` 会变成 `default(SabnzbdPriority) == 0 == Normal`，所以大小写写错会悄悄退化成 Normal。
  `"Force"` 很重要（见 §1.9），`"force"` 不起作用。
- 数字字符串也能解析：`"2"` → `Force`，`"-100"` → `Default`。JSON 数字 `2` 也行（`reader.Value.ToString()` == `"2"`）。
- **`"priority": null` 会抛出 `NullReferenceException`**（在 null 上调用了 `reader.Value.ToString()`）。这个异常**不会**被 `Json.TryDeserialize` 捕获。要么省略这个键，要么发送一个真实的值。
- 省略 `priority` 是安全的：不会调用转换器，成员保持 `Normal`（0）。
- 转换器只注册在 `SabnzbdQueueItem.Priority` 上（`SabnzbdQueueItem.cs:21`）；历史记录项没有优先级。
- Sonarr/Radarr 在 `mode=addfile` 里通过 `&priority=` 发回的正是这些整数（`SabnzbdSettings.cs` 中 `Recent*Priority` 和 `Older*Priority` 的默认值都是 `(int)SabnzbdPriority.Default` = `-100`）。

### 2.2 `SabnzbdDownloadStatus.cs`（完整文件），按声明顺序隐式赋值 0..15 {#22-sabnzbddownloadstatuscs-complete-file-declaration-order--implicit-values-015}

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

- **No per-property converter.** The globally registered
  `StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }` (`Json.cs:32`) handles it.
- An **unknown name throws** (Newtonsoft `EnumUtils.ParseEnum` → `JsonSerializationException`),
  and because `GetQueue`/`GetHistory` use `Json.Deserialize` (not Try), the *entire* queue or history
  call fails. **Never emit a status outside this list.**
- Emit SAB's canonical spellings exactly as above (`"Downloading"`, `"QuickCheck"`, `"Completed"`,
  `"Failed"`, `"Propagating"`, ...). Newtonsoft's enum matching does fall back to case-insensitive,
  but exact case is the only thing worth relying on.
- Integers are accepted too (`AllowIntegerValues` default true), but don't use them.
- A JSON `null` for `status` is ignored by `NullValueHandling.Ignore` and the member stays
  `Grabbing` (0) — a queue slot silently becomes `Queued`, a history slot silently becomes
  `Downloading`. Always send an explicit status.

---

## 3. `get_config`：具体读取哪些内容，以及校验规则 {#3-get_config-exactly-what-is-read-and-the-validation-rules}

### 3.1 模型 — `SabnzbdCategory.cs` {#31-the-model--sabnzbdcategorycs}

这个文件同时包含 `SabnzbdConfig`、`SabnzbdConfigMisc`、`SabnzbdCategory` **和** `SabnzbdSorter`。
两个仓库中都**没有 `SabnzbdConfig.cs`**（已通过 GitHub contents API 查看 `src/NzbDrone.Core/Download/Clients/Sabnzbd` 目录列表确认）。

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

### 3.2 `config.misc.*` — 读取的全部键（`SabnzbdCategory.cs:23-37`） {#32-configmisc--the-complete-set-of-keys-read-sabnzbdcategorycs23-37}

| JSON 键 | C# 类型 | 读取位置 | 用途 |
|---|---|---|---|
| `complete_dir` | `string` | `Sabnzbd.cs:218` | 所有分类路径的基础目录。 |
| `tv_categories` | `string[]` | `Sabnzbd.cs:265, 493` | |
| `enable_tv_sorting` | `bool` | `Sabnzbd.cs:265, 493` | |
| `movie_categories` | `string[]` | `Sabnzbd.cs:269, 502` | |
| `enable_movie_sorting` | `bool` | `Sabnzbd.cs:269, 502` | |
| `date_categories` | `string[]` **通过 `SabnzbdStringArrayConverter`** | `Sabnzbd.cs:273, 511` | |
| `enable_date_sorting` | `bool` | `Sabnzbd.cs:273, 511` | |
| `pre_check` | `bool` | `Sabnzbd.cs:443` | |
| `history_retention` | `string` | `Sabnzbd.cs:540, 561-573` | 旧版，SAB < 4.3。 |
| `history_retention_option` | `string` | `Sabnzbd.cs:541, 544` | SAB >= 4.3。 |
| `history_retention_number` | `int` | `Sabnzbd.cs:542, 553` | SAB >= 4.3。 |

`SabnzbdStringArrayConverter`（`JsonConverters/SabnzbdStringArrayConverter.cs:25-39`）——只应用于
`date_categories`（`SabnzbdCategory.cs:30`）：

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

JSON 的 **字符串** 会变成只有 1 个元素的数组；**null** 会变成 `[null]`（一个包含 null 的 1 元素数组）；**数组** 会正常反序列化；其他任何值（数字、对象）都会抛出异常。文档注释在 `:7-9`："On some properties sab serializes array of single item as plain string."（有些属性中，sab 会把只有一个元素的数组序列化成普通字符串。）

### 3.3 `config.categories[]` — `SabnzbdCategory`（`SabnzbdCategory.cs:39-48`） {#33-configcategories--sabnzbdcategory-sabnzbdcategorycs39-48}

| JSON 键 | C# | 读取位置 |
|---|---|---|
| `priority` | `int Priority` | 从未读取 |
| `pp` | `string PP` | 从未读取（`PP` 的 camelCase 形式是 `pp`） |
| `name` | `string Name` | `Sabnzbd.cs:251, 255, 458` |
| `script` | `string Script` | 从未读取 |
| `dir` | `string Dir` | `Sabnzbd.cs:238`（`Dir.TrimEnd('*')`），`Sabnzbd.cs:462`（`Dir.EndsWith("*")`） |

`FullPath`（`OsPath`）是计算得出的，不是反序列化得到的。

路径拼接，`Sabnzbd.GetCategories`（`Sabnzbd.cs:216-244`）：

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

`OsPath.operator+`（`src/NzbDrone.Common/Disk/OsPath.cs:420-448`）在 `right.IsEmpty` 时返回 `left`，
所以 `dir: ""` 会精确地得到 `FullPath == complete_dir`。Unix 类型路径的 `IsRooted` 就是 `_path.StartsWith("/")`（`OsPath.cs:142-145`）；路径类型是从字符串中嗅探出来的（`OsPath.cs:43-60`），以 `/` 开头就是 Unix，`\` 或盘符就是 Windows。把 Unix 类型的路径交给运行在 Windows 上的 Sonarr 时，`CompletedDownloadService.ValidatePath`（`:305-310`）会校验失败。

### 3.4 两个 NRE 陷阱（以及真正安全的做法） {#34-the-two-nre-landmines-and-what-is-actually-safe}

| 载荷结构 | 结果 |
|---|---|
| **`"misc"` 缺失或为 `null`** | `Misc` 保持为 null（构造函数中没有默认值；读取时使用 `NullValueHandling.Ignore`）→ 在 `Sabnzbd.cs:218` 处抛出 **NullReferenceException**，表现为 "Test was aborted due to an error: …"，并在健康检查中记录为错误日志。 |
| **某个分类的 `"dir"` 缺失或为 `null`** | `Dir` 为 null → 在 `Sabnzbd.cs:238` 处抛出 **NullReferenceException**（`category.Dir.TrimEnd('*')`），并在 `:462` 处再次抛出（`category.Dir.EndsWith("*")`）。 |
| `"categories": null` 或缺失 | 安全。构造函数中的空列表会保留。`GetStatus` 随后找不到任何分类，`OutputRootFolders` 保持为空。 |
| `"sorters": null` 或缺失 | 安全。构造函数中的空列表；`Sabnzbd.cs:484` 处的 `config.Sorters.Any(...)` 可以正常运行。 |
| `"servers": null` 或缺失 | 安全，且从不读取（`List<object>`，`SabnzbdCategory.cs:19`）。 |
| `"tv_categories"/"movie_categories"/"date_categories": null` | 安全：`ContainsCategory` 对 null 或空值返回 `true`（§3.5），但这只在对应的 `enable_*_sorting` 为 true 时才有影响。 |

**规则：始终将 `misc` 输出为对象，并且每个分类都要有字符串类型的 `dir`（使用 `""`）。**

### 3.5 `ContainsCategory`（`Sabnzbd.cs:523-536`） {#35-containscategory-sabnzbdcs523-536}

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

由测试夹具确认：`enable_tv_sorting=true` + `tv_categories=null` **会失败**
(`SabnzbdFixture.cs:636-645`)，加上 `tv_categories=[]` 同样 **会失败** (`:647-656`)。
`TvCategory=null` + `tv_categories=["Default"]` 会失败 (`:680-691`)。

### 3.6 `Test()` — 确切的顺序和规则（`Sabnzbd.cs:286-292`） {#36-test--the-exact-order-and-rules-sabnzbdcs286-292}

```csharp
protected override void Test(List<ValidationFailure> failures)
{
    failures.AddIfNotNull(TestConnectionAndVersion());
    failures.AddIfNotNull(TestAuthentication());
    failures.AddIfNotNull(TestGlobalConfig());
    failures.AddIfNotNull(TestCategory());
}
```

由 `DownloadClientBase.Test()`（`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`）包装，它会捕获所有向外抛出的异常，并添加 `"Test was aborted due to an error: " + ex.Message`。

**`TestConnectionAndVersion()`（`Sabnzbd.cs:368-414`）**：调用 1 次 `mode=version`：

1. 版本号无法解析 → 在 `Version` 字段上失败（`DownloadClientSabnzbdValidationUnknownVersion`）。
2. `rawVersion == "develop"`（忽略大小写）→ 在 `Version` 上给出**警告**，`IsValid` 保持为 true（fixture `SabnzbdFixture.cs:566-577`）。
3. `version.Major >= 1` → 通过（`:389-392`）。
4. 否则，如果 `version.Minor >= 7` → 通过（`:394-397`）。
5. 否则判定失败：要求的版本为 `"0.7.0"`（`:399-404`）。
   测试样例表（`SabnzbdFixture.cs:549-564`）：`0.6.9`→false，`0.7.0`/`0.8.0`/`1.0.0`/`1.0.0RC1`/`1.1.x`→true。
6. 任何异常 → 在 `Host` 字段上失败（"unable to connect"），详情为 `ex.Message`（`:406-413`）。

**`TestAuthentication()`（`Sabnzbd.cs:416-438`）**：调用 1 次 `mode=get_config`。捕获异常后，用 `ContainsIgnoreCase` 匹配 `ex.Message`：

| 匹配的子串 | 失败字段 |
|---|---|
| `API Key Incorrect` | `APIKey` — `DownloadClientValidationApiKeyIncorrect` |
| `API Key Required` | `APIKey` — `DownloadClientValidationApiKeyRequired` |
| 其他情况 | **重新抛出**，显示通用的 "Test was aborted due to an error: …" |

由于 `CheckForError` 会把响应体包装成 `"Error response received from SABnzbd: {error}"`（`SabnzbdProxy.cs:244`），所以只要你的 `error` 字符串*包含* `API Key Incorrect` / `API Key Required`（也就是 SAB 自己的措辞），匹配就能生效。

**`TestGlobalConfig()`（`Sabnzbd.cs:440-453`）**：调用 1 次 `mode=get_config`，只有当 `pre_check` 为 true 时，才额外调用 1 次 `mode=version`：

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

阈值：**SAB >= 1.1.0**（`HasVersion(major:1, minor:1, patch:0)`，`Sabnzbd.cs:294-332`）。
`pre_check: false` 会跳过整个分支，包括多出来的那次 `mode=version` 请求。

**`TestCategory()`（`Sabnzbd.cs:455-521`）**：调用 1 次 `mode=get_config`（这是*第三次*），外加 `GetCategories` 需要的请求。检查按以下顺序执行，命中第一个即停止：

1. 匹配到的分类（`Name == Settings.TvCategory` / `MovieCategory`），其 `dir` **以 `*` 结尾**
   → 在 `TvCategory`/`MovieCategory` 上给出警告 "enable job folders"，InfoLink 为 `config/categories/`（`:460-469`）。
2. 没有匹配的分类，**并且**配置的分类不为空
   → 警告 `DownloadClientValidationCategoryMissing`，InfoLink 为 `config/categories/`（`:471-481`）。
3. `config.Sorters.Any(s => s.is_active && ContainsCategory(s.sort_cats, cat))` → 警告，InfoLink 为 `config/sorting/`（`:483-491`）。`:483` 处的代码注释：*"New in SABnzbd 4.1, but on older versions this will be empty and not apply"*。
4. `misc.enable_tv_sorting && ContainsCategory(misc.tv_categories, cat)` → 警告（`:493-500`）。
5. `misc.enable_movie_sorting && ContainsCategory(misc.movie_categories, cat)` → 警告（`:502-509`）。
6. `misc.enable_date_sorting && ContainsCategory(misc.date_categories, cat)` → 警告（`:511-518`）。

`SabnzbdSorter`（`SabnzbdCategory.cs:50-66`）读取的字段：`sort_cats`（`List<string>`，构造函数中为空）、`is_active`（`bool`）。模型中存在但从未读取的字段：`name`、`order`、`min_size`、`multipart_label`、`sort_string`、`sort_type`（`List<int>`）。

**请求次数说明：**四个 `Test*` 方法各自发起自己的请求，没有任何缓存。一次连接测试大约会发出 **2 次 `mode=version` 和 3 次 `mode=get_config`**（如果 `pre_check` 为 true，则还会多出 1 次 version 调用）。

### 3.7 `config.misc` 历史保留 → `RemovesCompletedDownloads`（`Sabnzbd.cs:538-574`） {#37-configmisc-history-retention--removescompleteddownloads-sabnzbdcs538-574}

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

`true` 会触发健康检查**警告**
(`HealthCheck/Checks/DownloadClientRemovesCompletedDownloadsCheck.cs:44-53`)。
夹具覆盖范围 `SabnzbdFixture.cs:455-510`:旧版 `"0"`/`""`/`null`/`"15d"` → false;
`"-1"`/`"15"`/`"3"`/`"3d"` → true。

**最干净的模拟器方案:`history_retention_option: "all"`、`history_retention_number: 0`、
`history_retention: "0"`。**

### 3.8 `SortingMode` 及其健康检查（`Sabnzbd.cs:263-279`） {#38-sortingmode-and-its-health-check-sabnzbdcs263-279}

`GetStatus` 使用相同的 `enable_*_sorting && ContainsCategory(...)` 判断条件，把 `SortingMode` 设为 `"TV"`、`"Movie"` 或 `"Date"`。只要值不是空白，`HealthCheck/Checks/DownloadClientSortingCheck.cs:45-55` 就会触发一条警告。三个 `enable_*_sorting` 都请保持为 false。

### 3.9 `IsLocalhost`（`Sabnzbd.cs:260`） {#39-islocalhost-sabnzbdcs260}

```csharp
IsLocalhost = Settings.Host == "127.0.0.1" || Settings.Host == "localhost"
```

按序号、区分大小写;`::1`、`Localhost` 以及任何主机名都**不**算。这会影响你会看到的 `RemotePathMappingCheck` 提示信息(见 §6.2)。

---

## 4. 错误处理 — `CheckForError`（`SabnzbdProxy.cs:222-246`） {#4-error-handling--checkforerror-sabnzbdproxycs222-246}

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

`SabnzbdJsonError`（`SabnzbdJsonError.cs`，完整）：

```csharp
public string Status { get; set; }
public string Error  { get; set; }

public bool Failed => !string.IsNullOrWhiteSpace(Status) &&
                      Status.Equals("false", StringComparison.InvariantCultureIgnoreCase);
```

规则，具体如下：

- `CheckForError` 会在**每一个**响应上运行，并且早于任何特定模式的反序列化（`SabnzbdProxy.cs:217`）。
- `Status` 的类型是 `string`，但 SAB 发送的是 JSON **布尔值**。Newtonsoft 会把 `false` 转换为 `"False"`，而 `Failed` 会不区分大小写地匹配它。布尔值 `false` 和字符串 `"false"` 都能正常工作。
- 如果响应中**没有顶层 `status`**（例如 `{"version": …}`、`{"queue": {...}}`、`{"history": {...}}`、`{"config": {...}}`），`Status` 就为 null，`Failed` 为 false，因此不会报错。
- `status: true` → `"True"` → 不算失败。
- **非 JSON 响应体**：`TryDeserialize` 返回 false（它会捕获 `JsonReaderException` 和 `JsonSerializationException`，`Json.cs:107-116`），然后走纯文本分支。如果响应体以 `error` 开头（不区分大小写），则 `Status = "false"`，并抛出 `DownloadClientException("Error response received from SABnzbd: {body with 'error: ' stripped}")`。其他任何非 JSON 响应体都会使 `Status = "true"`，**被视为成功**，之后特定模式的反序列化会因其自身的原因失败。
- 如果 **JSON 响应体的 `status` 是一个对象**（`mode=fullstatus`），同样会走纯文本分支，因为 `StartObject` 令牌无法填充 `string` 属性，`Status` 会变成 `"true"`。
- 注意 `:239` 处多余的 `result.Error = …`：即使在成功分支上也会设置 `Error`。它没有任何作用（除非 `Failed`，否则没有任何代码读取 `Error`）。

`ProcessRequest`（`SabnzbdProxy.cs:187-220`）中的异常映射：

| 捕获 | 抛出 |
|---|---|
| `HttpException`（任何非 2xx 响应，包括 401/403/404/500） | `DownloadClientException("Unable to connect to SABnzbd, {0}")` |
| `HttpRequestException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |
| `WebException` 且 `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, certificate validation failed.")` |
| 其他 `WebException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |

**匹配的确切认证失败字符串**（`Sabnzbd.cs:424, 429`，精确字面值，通过 `ContainsIgnoreCase` 与异常消息进行匹配）：

- `"API Key Incorrect"`
- `"API Key Required"`

其他情况都不会被归类。将它们原样作为 **HTTP 200** 响应的 `error` 值返回。

**为什么绝不能返回非 200 状态码：** `HttpClient.Execute` 会在 `CheckForError` 运行之前就抛出异常（`HttpClient.cs:106-121`），由此产生的 `HttpException` 消息只包含状态码、方法和 URL，不包含响应体（`HttpException.cs:18`），因此 `"API Key Incorrect"` / `"API Key Required"` 的匹配永远不会触发。用户看到的是 "Unable to connect to SABnzbd" 或 "Test was aborted due to an error"，而不是可操作的提示，并且每个健康检查都会把客户端视为无法连接。

---

## 5. 导入后的流程 {#5-the-post-import-sequence}

### 5.1 谁调用 `RemoveItem`，以及传入什么 {#51-who-calls-removeitem-and-with-what}

`DownloadEventHub`（`src/NzbDrone.Core/Download/DownloadEventHub.cs`，两个仓库中除 BOM 外完全相同）：

- `Handle(DownloadCompletedEvent)`（`:48-69`）：调用 `MarkItemAsImported`（SAB 会抛出 `NotSupportedException`，见 `DownloadClientBase.cs:189-192`，这时会以 debug 级别记录并忽略）。之后，如果条目已经是 `Removed`、`!CanBeRemoved` 或仍在 `Downloading`，就提前返回。接着，如果 `definition.RemoveCompletedDownloads` 不成立，也会提前返回。
- `Handle(DownloadFailedEvent)`（`:26-46`）：由 `definition.RemoveFailedDownloads` 控制。
- `Handle(DownloadCanBeRemovedEvent)`（`:71-85`）：由 `definition.RemoveCompletedDownloads` 控制。
- 这三个方法最终都会调用 `RemoveFromDownloadClient`（`:87-103`）：

```csharp
_logger.Debug("[{0}] Removing download from {1} history", …);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);   // :92 -- deleteData is ALWAYS true
trackedDownload.DownloadItem.Removed = true;
```

`DownloadClientDefinition` 的默认值（`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17-18`）：

```csharp
public bool RemoveCompletedDownloads { get; set; } = true;
public bool RemoveFailedDownloads    { get; set; } = true;
```

手动 API 路径 `DELETE /api/v3/queue/{id}?removeFromClient=true` 也会传入 `true`（Sonarr `src/Sonarr.Api.V3/Queue/QueueController.cs:342`）。**代码中没有任何地方会传入 `deleteData: false`。**

### 5.2 `Sabnzbd.RemoveItem`（`Sabnzbd.cs:197-214`）— 确切的执行顺序 {#52-sabnzbdremoveitem-sabnzbdcs197-214--the-exact-sequence}

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

所以导入后对模拟器发出的请求顺序是：

1. `GET /api?mode=queue&start=0&limit=0&category=tv&apikey=…&output=json`（用来判断是在队列还是历史记录里）
2. **在本地文件系统上删除输出文件夹**（§5.3）——在发出任何其他 HTTP 请求之前
3. `GET /api?mode=history&name=delete&del_files=1&value={nzo_id}&archive=1&apikey=…&output=json`

对于**失败**的项目：不做本地删除（状态是 `Failed`，不是 `Completed`），并且 **`archive=0`**——
这是 `SabnzbdProxy.cs:80` 里的取反逻辑（`archive = deletePermanently ? 0 : 1`，其中 `deletePermanently == (status is Failed)`）。

### 5.3 `DeleteItemData`（`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`） {#53-deleteitemdata-srcnzbdronecoredownloaddownloadclientbasecs110-146}

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

- **是的，它会递归删除输出文件夹。** `DeleteFolder(path, recursive: true)` 位于 `:129`。
- 这里的 `OutputPath` 是历史记录项的 `storage`，经过远程路径重映射和任务文件夹向上查找（§1.6.2）之后的结果。对于扁平的 magic 目录，也就是 `rm -rf /mnt/zurg/__magic__/__all__/<Title>`。
- 起决定作用的是下载客户端的 **Remove Completed Downloads** 开关（`DownloadClientDefinition.RemoveCompletedDownloads`，默认 **true**），*而不是* SAB 端的设置，也不是 `del_files`。界面里没有单独的“删除数据”开关。
- 失败会被静默吞掉并记录一条警告。只读挂载会产生一些日志噪音，但不会中断导入。
- 测试覆盖 `SabnzbdFixture.cs:693-803`：递归删除文件夹、删除文件、路径不存在时不做任何操作，以及 `deleteData` 为 false 时完全不做任何操作（连 `FolderExists` 检查都不执行）。

### 5.4 转移模式：文件是移动还是复制？ {#54-transfer-mode-is-the-file-moved-or-copied}

`Sabnzbd` 在每个条目上都设置了 `CanMoveFiles = true`，包括队列（`Sabnzbd.cs:76`）和历史记录（`Sabnzbd.cs:135`）。自动导入路径是 `CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, …)`（Sonarr `CompletedDownloadService.cs:148-151`），然后：

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

Sonarr `src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152`（Radarr `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`，逻辑完全相同）

`CanMoveFiles: true` ⇒ `copyOnly == false` ⇒ **`TransferMode.Move`**（`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`）。如果是 `copyOnly` 导入，那么在开启 "Use Hardlinks instead of Copy" 时会使用 `TransferMode.HardLinkOrCopy`，否则使用 `TransferMode.Copy`（`:94-108`）。

`TransferMode`（`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`）是 `[Flags]` 枚举：`None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy = Copy|HardLink`。

### 5.5 移动失败时会回退为复制吗？ — **不会。移动失败就是导入失败。** {#55-does-a-failed-move-fall-back-to-a-copy--no-a-failed-move-is-a-failed-import}

`src/NzbDrone.Common/Disk/DiskTransferService.cs`（两个仓库中的内容逐字节相同，已核对）。
`TransferFile`，`:256-392`；`TransferMode.Move` 分支位于 `:360-389`：

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

- **唯一**的复制回退是 `:378-385` 处的 `isCifs && !isSameMount` 特殊情况，它依据 `targetMount.DriveFormat == "cifs"`（`:342`）判断。这个分支是*事先*根据驱动器格式选定的，而不是对失败做出的反应。

- `TryMoveFileVerified`（`:487-503`）会捕获异常，调用 `RollbackPartialMove`（如果异常是 `FileAlreadyExistsException` 则除外），然后**重新抛出**：

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

- `VerifyFile`（`:505-524`）会比较目标文件大小和源文件大小，休眠 3 秒（`WaitForIO`，`:467-471`），再检查一次，然后抛出 `IOException("File move incomplete, data loss may have occurred. [{target}] was {n} bytes long instead of the expected {m}.")`。
- 这个 `IOException` 会经 `EpisodeFileMovingService.TransferFile`（`:151`）向上传播，进入 `ImportApprovedEpisodes.cs:218-222` 中的通用 `catch (Exception e)`（Radarr 中是 `:197-201`），生成 `ImportResult(importDecision, "Failed to import episode")` 或 `"Failed to import movie"`。**不会尝试复制。**
- 同一方法中的其他预检 `IOException`：源路径与目标路径相同（`:270`、`:277`），以及 "Destination cannot be a child of the source"（`:312-315`）。

注意，这是 .NET 运行时的特性，而不是 Sonarr 的代码：`DiskProviderBase.MoveFileInternal`（`src/NzbDrone.Common/Disk/DiskProviderBase.cs:293-301`）只是普通的 `File.Move`，而在 Unix 上，当 `rename()` 返回 `EXDEV` 时，.NET 会回退为复制后删除。所以跨文件系统的移动通常仍会成功，但这是*运行时*的回退，而不是 Sonarr 的回退。真正不会被容忍的是目标大小与源大小不一致，或者 `File.Move` 本身抛出的任何异常（EACCES、EPERM、源端的 EROFS 等）。

`TransferFolder`（`:44-137`）被其他代码路径使用；注意 `:124-131`：文件夹移动之后，如果仍有超过 100 MB 的文件留在源目录中，它会拒绝删除源文件夹（`IOException("Large files still exist in {sourcePath} after folder move, not deleting source folder")`）。

---

（之前的译文被拒绝了：长度比例只有 0.12。请保持结构完全不变。）

## 6. 两项健康检查 {#6-the-two-health-checks}

### 6.1 `DownloadClientRootFolderCheck` — **Sonarr 和 Radarr 真正有差异的唯一地方** {#61-downloadclientrootfoldercheck--the-one-place-sonarr-and-radarr-genuinely-differ}

Sonarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`：

```csharp
var folders = status.OutputRootFolders.Where(folder => rootFolders.Any(r => r.Path.PathEquals(folder.FullPath)));
```

Radarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`：

```csharp
var folders = rootFolders.Where(r => status.OutputRootFolders.Any(folder => r.Path.PathEquals(folder.FullPath) || r.Path.IsParentPath(folder.FullPath)));
```

`IsParentPath`（`src/NzbDrone.Common/Extensions/PathExtensions.cs:123-140`）从子路径开始**向上**逐级查找：

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

所以，当 **根文件夹是下载输出文件夹的祖先目录** 时，`r.Path.IsParentPath(folder.FullPath)` 的结果为 true，也就是说输出文件夹位于某个根文件夹*内部*。这是一个严格的祖先判断（它从 `child.Directory` 开始）；相等的情况由 `PathEquals` 单独处理。

**直接回答这个判断的结果：**

| 关系（输出文件夹 O 与根文件夹 R） | Sonarr | Radarr |
|---|---|---|
| O == R | **警告** | **警告** |
| O 位于 R 内部（R 是 O 的祖先） | 无警告 | **警告** |
| O 是 R 的父级（O 是 R 的祖先） | 无警告 | **无警告** |
| 无关 | 无警告 | 无警告 |

在 `complete_dir = /mnt/zurg/__magic__/__all__` 且 `dir: ""` 的情况下（因此 `OutputRootFolders == ["/mnt/zurg/__magic__/__all__"]`）：

- 只有根文件夹恰好是 `/mnt/zurg/__magic__/__all__` 时，Sonarr 才会发出警告。
- 只要根文件夹是 `/mnt/zurg/__magic__/__all__`、`/mnt/zurg/__magic__`、`/mnt/zurg` 或 `/mnt`，Radarr 就会发出警告。
- 如果根文件夹是 `/mnt/zurg/__magic__/tv`，两者都不会警告——镜像和根文件夹是同级关系，所以这一对是无关的，两条规则都不会触发。位于输出文件夹*内部*的根文件夹（`/mnt/zurg/__magic__/__all__/anything`）在这里也不会触发，但命名空间不允许在这个深度存储任何内容，所以这种布局根本不可能存在。

`PathEquals`（`PathExtensions.cs:55-73`）会对 Unicode 做规范化，使用 `DiskProviderBase.PathStringComparison`（Windows 上为 `OrdinalIgnoreCase`，其他系统为 `Ordinal`——`src/NzbDrone.Common/Disk/DiskProviderBase.cs:17-23`），并在失败后用 `CleanFilePath()` 重试（不区分末尾斜杠）。

两个版本都会在 `ProviderUpdatedEvent` / `ProviderDeletedEvent` / `ModelEvent<RootFolder>` /
`ModelEvent<RemotePathMapping>` 事件时重新运行；Radarr 还在 `:17` 行添加了 `[CheckOn(typeof(ProviderAddedEvent<IDownloadClient>))]`。结果为 `HealthCheckResult.Warning`，锚点为 `#downloads-in-root-folder`。消息中，Sonarr 插入 `folder.FullPath`，Radarr 插入 `folder.Path`（两者都在 `:60` 行）。两个版本都会静默忽略 `DownloadClientException` 和 `HttpRequestException`（仅记录 debug 日志），其他异常则作为错误记录。

（之前的译文被拒绝：代码片段不一致。请完全保持结构。）

### 6.2 `RemotePathMappingCheck` — 本地客户端路径（`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs`） {#62-remotepathmappingcheck--the-local-client-path-srcnzbdronecorehealthcheckchecksremotepathmappingcheckcs}

在 `:51-54` 处直接短路返回：如果 `EnableCompletedDownloadHandling` 关闭，这个检查什么都不做。

对 `client.GetStatus().OutputRootFolders` 中的每个 `folder`：

1. **`!folder.IsValid`**（`:68`）— `OsPath.IsValid` 即 `_path.IsPathValid(PathValidationType.CurrentOs)`（`OsPath.cs:228`）。在非 Windows 系统上，它实际上就是检查 `path.StartsWith("/")`，外加一次 `Path.GetInvalidPathChars()` 扫描（`PathExtensions.cs:143-182`、`:403-411`）。依次报的错误如下：
   - `!status.IsLocalhost` → `RemotePathMappingWrongOSPathHealthCheckMessage`（Radarr 中的键名：`RemotePathMappingCheckWrongOSPath`），锚点 `#bad-remote-path-mapping`
   - `_osInfo.IsDocker` → …`BadDockerPath`，锚点 `#docker-bad-remote-path-mapping`
   - 其他情况 → …`LocalWrongOSPath`，锚点 `#bad-download-client-settings`
2. **`!_diskProvider.FolderExists(folder.FullPath)`**（`:115`）：
   - `_osInfo.IsDocker` → …`DockerFolderMissing`，`#docker-bad-remote-path-mapping`
   - `!status.IsLocalhost` → …`LocalFolderMissing`，`#bad-remote-path-mapping`
   - 其他情况 → …`GenericPermissions`，`#permissions-error`

**对于本地客户端（`IsLocalhost` 为 true，且不在 Docker 中），这实际上只有两个要求：** 上报的输出根文件夹必须是 *Sonarr/Radarr 所运行的操作系统* 上的绝对路径，而且它必须 **在 Sonarr/Radarr 所在主机上作为目录存在**。`/mnt/zurg/__magic__/__all__` 必须对 *arr 进程可见，而不只是对模拟器可见。**这里没有可写性检查。**

事件驱动的重载（`:178-368`）会在 `EpisodeImportFailedEvent` 触发（Radarr 中为 `MovieImportFailedEvent`），而且值得注意的是，它会再次调用 `client.GetItems()`，以查找失败下载的 `OutputPath`（`:232`）。

没有任何健康检查要求输出文件夹 *可写*。`FolderWritable`（Sonarr 中为 `DiskProviderBase.cs:126-143`，Radarr 中为 `:127-144`）——它会写入并删除 `sonarr_write_test.txt` / `radarr_write_test.txt`——它被用于 `RootFolderService.Add`（Sonarr 的 `src/NzbDrone.Core/RootFolders/RootFolderService.cs:117-120`）以及 `DownloadClientBase.TestFolder`（`:167-187`）。**SAB 客户端从不调用 `TestFolder`。**

## 7. Sonarr 与 Radarr — 完整差异对比 {#7-sonarr-vs-radarr--the-complete-diff}

**除了 Sonarr 副本带有 UTF-8 BOM 之外，字节完全相同**（因此行号完全对应）：

`SabnzbdCategory.cs`（两边都没有 BOM，真正完全相同）、`SabnzbdDownloadStatus.cs`、
`SabnzbdPriority.cs`、`SabnzbdFullStatus.cs`、`SabnzbdJsonError.cs`、`SabnzbdQueue.cs`、
`SabnzbdQueueItem.cs`、`SabnzbdHistory.cs`、`SabnzbdHistoryItem.cs`、
`JsonConverters/*.cs`（全部三个）、`Responses/*.cs`（全部六个）、
`src/NzbDrone.Common/Disk/DiskTransferService.cs`、`src/NzbDrone.Core/Download/DownloadEventHub.cs`。

**仅因 `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` 重命名而不同（行数不变，行号相同）：**

- `Sabnzbd.cs` — `:40-52`（`AddFromNzbFile`；Radarr 的近期判断是 `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie`，Sonarr 则是 `remoteEpisode.IsRecentEpisode()`）、`:190`、`:251`、`:265/269/273`、`:458`，以及 `TestCategory` 中每个 `NzbDroneValidationFailure` 的字段名（`"TvCategory"` → `"MovieCategory"`）。
- `SabnzbdProxy.cs` — `:50`、`:122-124`、`:138-140`。
- `SabnzbdSettings.cs` — 默认值 `TvCategory = "tv"` 与 `MovieCategory = "movies"`；`RecentTvPriority`/`OlderTvPriority` 与 `RecentMoviePriority`/`OlderMoviePriority`（两者默认都是 `(int)SabnzbdPriority.Default`）。验证器其他部分相同：`Host` 有效，`Port` 为 1–65535，`ApiKey` 在 username 为空时必填，`Username`/`Password` 在 ApiKey 为空时必填，category 的 `NotEmpty` **作为警告**。
- `UsenetClientBase.cs` — Radarr 在从索引器获取 NZB 时还会设置 `request.AllowAutoRedirect = true`（`:51`），并把 HTTP `410 Gone` 当作 `404` 处理（`:63`）。**这与索引器有关，与 SAB 无关。**
- `DownloadClientBase.cs` — 仅 `TestFolder` 详细文本中字面的 "Sonarr"/"Radarr" 不同。
- `RemotePathMappingCheck.cs` — 本地化键名（`RemotePathMapping*HealthCheckMessage` 与 `RemotePathMappingCheck*`）、`EpisodeImportFailedEvent` 与 `MovieImportFailedEvent`，以及 Radarr 额外的 `[CheckOn(ProviderAddedEvent<IDownloadClient>)]`。**谓词完全相同。**
- `DiskProviderBase.cs` — `FolderWritable` 的探测文件名为 `sonarr_write_test.txt` 与 `radarr_write_test.txt`（Sonarr 在 `:132`，Radarr 在 `:133`）。

**真正的行为差异——只有一处：**

- **`DownloadClientRootFolderCheck.cs:51`。** Sonarr 只在 `PathEquals` 时发出警告；Radarr 还会在某个根文件夹是输出文件夹的祖先时发出警告。完整对照表见 §6.1。

除上述之外的一切——模式、参数、JSON 结构、枚举、转换器、`CheckForError`、`RemoveItem`、`DeleteItemData`、传输模式、`DiskTransferService`——都相同。**一个模拟器同时服务两者。**

两者的配置默认值相同：`DownloadClientHistoryLimit = 60`、`RemoveCompletedDownloads = true`、`RemoveFailedDownloads = true`。

## 8. 最小但完整的示例负载 {#8-minimal-but-complete-example-payloads}

给定: `complete_dir = /mnt/zurg/__magic__/__all__`；分类 `*`、`tv`、`movies`，都设置 `dir: ""`。
每个响应都是 **HTTP 200**，`Content-Type: application/json`。

最终的 `OutputRootFolders`：`dir: ""` ⇒ `FullPath == complete_dir` ⇒ `/mnt/zurg/__magic__/__all__`
对于 Sonarr（分类 `tv`）和 Radarr（分类 `movies`）都是这个结果。

### 8.1 `mode=version`

```json
{
  "version": "4.3.3"
}
```

必须是 `major.minor.(patch|x)` 格式。`4` ≥ 1 满足 `TestConnectionAndVersion`（`Sabnzbd.cs:389-392`）；
如果 `complete_dir` 是相对路径（实际不是），≥ 2.0 还意味着 `GetCategories` 会使用 `fullstatus` 而不是 `queue.my_home`。

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

各个值的作用：

- `misc` 必须是对象，**必需**，否则会 NRE（§3.4）。
- 每个分类都必须有一个**字符串**类型的 `dir`，**必需**，否则会在 `Sabnzbd.cs:238` 和 `:462` 处出现 NRE。
- `dir` 不能以 `*` 结尾，否则会出现 "enable job folders" 警告（`Sabnzbd.cs:462-469`）。
- 三个 `enable_*_sorting: false` 都要设为 false，这样既能消除 `TestCategory` 的警告（`Sabnzbd.cs:493-518`），也能避开 `DownloadClientSortingCheck`。注意，如果把 `tv_categories: []` 和 `enable_tv_sorting: true` 放在一起，会**失败**，因为 `ContainsCategory` 对空列表会返回 true（`Sabnzbd.cs:525-528`，测试数据见 `SabnzbdFixture.cs:647-656`）。
- `sorters: []`：`config.Sorters.Any(s => s.is_active && …)` 的结果为 false（`Sabnzbd.cs:484`）。
- `pre_check: false` 会跳过 `TestGlobalConfig` 里的 `HasVersion(1,1)` 往返检查（`Sabnzbd.cs:443`）。
- `history_retention_option: "all"` 会让 `RemovesCompletedDownloads == false`（`Sabnzbd.cs:546-547`），所以不会出现健康检查警告。
- `complete_dir` 是绝对路径，`IsRooted` 为 true，因此永远不会去检查 `mode=fullstatus` 或 `queue.my_home`（`Sabnzbd.cs:220`）。

（之前的译文被拒绝了：代码片段不一致（`enable_*_sorting: false`）。请保持结构完全一致。）

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

只会读取 `completedir`（`SabnzbdFullStatus.cs:9-10`）。外层的包装键**必须**是 `status`（`Responses/SabnzbdFullStatusResponse.cs:5`）。

### 8.4 `mode=addfile` 响应 {#84-modeaddfile-response}

```json
{
  "status": true,
  "nzo_ids": ["SABnzbd_nzo_abc12345"]
}
```

`nzo_ids` 必须是**非空的字符串数组**（`Sabnzbd.cs:47-52`）。`status` 会被解析（`Responses/SabnzbdAddResponse.cs:13`），但从来不会被读取。所以保持它为 `true` 就行，这样 `CheckForError` 才能看到 `"True"`。

### 8.5 `mode=queue&start=0&limit=0&category=tv` — 一个下载中的任务槽 {#85-modequeuestart0limit0categorytv--one-downloading-slot}

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

硬性要求:

- 顶层键 `queue`(`SabnzbdProxy.cs:129`,`SelectToken("queue")`)。
- `slots[].status` 必须是 16 个 `SabnzbdDownloadStatus` 名称之一,大小写须完全一致。
- `slots[].mb` / `mbleft` 的单位是 **兆字节(MB)**,小数格式使用与区域无关的 invariant culture。字符串或数字都可以(Newtonsoft 会自动转换);真实的 SAB 返回的是字符串。
- `slots[].timeleft` 必须严格为 `h:m:s` 或 `d:h:m:s` 格式,绝不能为 `""`。
- `slots[].priority` 取值为 `"Normal"`、`"High"`、`"Low"`、`"Force"`、`"Paused"`、`"Default"`(区分大小写)之一,或对应的数字值。**绝不能为 `null`**(会引发 NRE)。
- `slots[].cat`(不是 `category`)必须与客户端配置的分类一致,否则该条目会在 `Sabnzbd.cs:190` 处被过滤掉。
- 除非你确实想暂停,否则 `queue.paused` 必须为 `false`。设为 `true` 会把每个非 `Force` 的 slot 都标记为 Paused,且 ETA 为 null(`Sabnzbd.cs:78-84`)。

生成的 `DownloadClientItem` 为:`TotalSize = 1024 * 1024 * 1024`、`RemainingSize = 512 * 1024 * 1024`、`RemainingTime = 00:08:32`、`Status = Downloading`、`CanBeRemoved = CanMoveFiles = true`。

### 8.6 `mode=history&start=0&limit=60&category=tv` — 一个已完成和一个失败的任务槽 {#86-modehistorystart0limit60categorytv--one-completed-and-one-failed-slot}

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

硬性要求：

- 顶层键 `history`（`SabnzbdProxy.cs:145`）。
- `slots[].bytes` 是 **BYTES**（JSON 数字 → `long`）。这里不要发送 MB。队列用的是 MB，history 用的是字节（`Sabnzbd.cs:72-73` 对比 `:128`）。
- 字段名是 `slots[].category`（不是 `cat`）。
- `slots[].storage` 就是作业文件夹本身。它会变成 `OutputPath`，对于 Completed 的项目，`DeleteItemData` 会递归删除它（§5.3）。它必须是 Sonarr/Radarr 所在操作系统上有效的绝对路径，并且在那里真实存在（`RemotePathMappingCheck`，§6.2）。
- `slots[].status` 要区分大小写，必须完全一致。`Deleted` 的项目会被直接丢弃（`Sabnzbd.cs:116-119`）。
- `fail_message` 如果恰好是 `"Unpacking failed, write error or disk is full?"`，会把 Failed 项目降级为 `Warning`，而不是 `Failed`（`Sabnzbd.cs:140-144`）。真正的失败请使用其他文本。
- Radarr：`category` 必须是 `movies`（或你配置的其他名称），`name` 应该能被解析为一部电影。

### 8.7 错误响应（任意 mode） {#87-error-response-any-mode}

```json
{
  "status": false,
  "error": "API Key Incorrect"
}
```

**HTTP 200。** `status` 可以是布尔值 `false`，也可以是字符串 `"false"`，两者都会匹配 `SabnzbdJsonError.Failed`（`SabnzbdJsonError.cs:10-11`）。客户端会抛出 `DownloadClientException("Error response received from SABnzbd: API Key Incorrect")`（`SabnzbdProxy.cs:244`），`TestAuthentication` 会识别这个错误（`Sabnzbd.cs:424`）。如果没有提供 key，则使用 `"API Key Required"`（`Sabnzbd.cs:429`）。其他任何 `error` 字符串都会原样显示，但不会被归类。

---

## 9. 实现检查清单（12 项） {#9-implementation-checklist-12-points}

1. 一条路由：`GET|POST {UrlBase}/api`，根据 `mode` 分发。**始终返回 HTTP 200，始终返回 JSON。**
2. 实现 `version`、`get_config`、`queue`（读取 + `name=delete`）、`history`（读取 + `name=delete`）、`addfile`、`fullstatus`。可选实现 `retry`（目前是死代码）。`get_cats` 从来不会被调用。
3. 认证可以用 `apikey=`，**也可以用** `ma_username=` + `ma_password=`。拒绝时返回 200 + `{"status":false,"error":"API Key Incorrect"}` / `"API Key Required"`，永远不要返回 401/403。
4. 在 `queue`/`history` 上支持 `category=`（客户端还会按完全相同的字符串做客户端过滤，`Sabnzbd.cs:190`）。
5. `queue` 的大小单位是 **MB**（`mb`、`mbleft`）；`history` 的大小单位是 **字节**（`bytes`）。千万别搞混。queue 用 `cat`，history 用 `category`。
6. `timeleft` 必须始终是 `h:m:s` 或 `d:h:m:s` 格式，不能为空，也不能是空字符串形式的缺省。没有任何地方解析日期字段，所以时间戳字段可以随意填写。
7. `status` 的值必须来自 16 个成员的 `SabnzbdDownloadStatus` 列表，大小写完全一致（名字不对会抛出异常，导致整个 queue/history 调用失败）。`priority` 必须是 `SabnzbdPriority` 的名称（大小写一致）或其整数值；**绝不能为 `null`**（会在转换器里触发 NRE）。
8. `config.misc` 必须是对象；每个分类都必须有一个**非 null 的字符串 `dir`**，且不能以 `*` 结尾。`categories`/`sorters`/`servers` 可以为 null 或不存在，但 `misc` 和 `dir` 不行。
9. 保持 `enable_tv_sorting`、`enable_movie_sorting`、`enable_date_sorting` 和 `pre_check` 都为 `false`，以及 `history_retention_option: "all"`，这样连接测试和所有健康检查都能顺利通过。
10. 已完成的历史记录项的 `storage` = 任务文件夹。预计 *arr 在成功导入后会对它执行 `rm -rf`（默认设置），并且预计媒体文件会先被**移出**该文件夹。如果 magic 目录是只读的，删除会静默失败（只会输出警告日志），但导入文件的*移动*操作必须成功，否则导入会直接失败（见 §5.5）。
11. 如果希望 Radarr 的 `DownloadClientRootFolderCheck` 保持安静，不要把任何 *arr 的根文件夹放在 `/mnt/zurg/__magic__/__all__` 或其上级目录中（Sonarr 只关心完全相等的情况）。应把它们放在镜像旁边——`/mnt/zurg/__magic__/tv`、`/mnt/zurg/__magic__/movies`——与输出文件夹无关，既不在它之上，也不在它之下。
12. `/mnt/zurg/__magic__/__all__` 必须作为目录存在于 **Sonarr/Radarr 所在的主机上**，而不仅仅是模拟器运行的地方，否则 `RemotePathMappingCheck` 会报错。它不需要可写。

## 配置更大的完成窗口 {#configuring-a-larger-completion-window}

两个客户端的 `DownloadClientHistoryLimit` 默认值都是 60。zurg 在 `queue` 中保留已完成的溢出任务时，会沿用这个窗口。如果只调大客户端的限制，有些任务会同时出现在 queue 和历史记录中，此时以 queue 为准。

如果积压的任务很多，请把 zurg 中的 `sabnzbd.history_limit` 和各客户端的 `DownloadClientHistoryLimit` 设成同一个值，例如 500。这样每次轮询能看到更多已完成和失败的任务。如果几个客户端使用不同的值，就让 zurg 保持最小的客户端限制值。这个高级客户端设置没有出现在 Sonarr v4 的下载客户端配置 API 资源中，所以修改已保存的配置前，请先备份并停止该客户端。

```yaml
sabnzbd:
  enabled: true
  history_limit: 500
```

默认值仍是 60；零和负值同样使用默认值。诊断性的历史请求即使使用了不同的限制值，也不会改变已配置的窗口。客户端无法解析的警告仍然需要人工检查；窗口调大后，其他任务可以在这些警告占用历史记录位时进入导入流程。

完成前的可用性检查会抽样每个内容文件的前 16 篇文章和最后一篇文章。这样就能发现媒体文件头中缺失的文章，而之前只检查第一篇文章的 canary 会漏掉这种情况。它会获取每个内容文件的第一篇文章，以检查文章标识以及正文是否仍可提供（服务商可能对已下架正文的文章仍然回应 STAT）。对于文件数少于 16 个的发布，还会随机抽取文章，使正文数最多达到 16 篇；所有样本的正文总数最多为 64 篇。文章缓存中已有的正文不会重复获取。其余样本只做 STAT 检查。它不会验证每一篇文章，也不能证明媒体可以解码。STAT 请求按文件分批发送，因此整个抽样只占用一次连接池预留，而不是 17 次，同时也不会提高账户的连接上限。如果某个批次不可用，就回退为逐个 STAT。服务器故障会让任务保持排队以便重试；确认缺失的文章则会在第一条完成通知发出之前，生成一个失败的下载。
