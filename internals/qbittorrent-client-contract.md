# qBittorrent Web API contract as consumed by Sonarr and Radarr (develop)

Source of truth: files fetched from `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...`
and from `qbittorrent/qBittorrent/master` on **2026-08-27**. Every line number below was read out of
those files.

This is the torrent counterpart to [sabnzbd-client-contract.md](sabnzbd-client-contract.md). That
document records why `internal/sabnzbd` answers in the shapes it does; this one is the specification
a qBittorrent shim has to satisfy *before* it is written, so that a grab, a poll, an import **as a
move**, and the post-import cleanup all work in both clients. Where the two clients share machinery
(the HTTP layer, the JSON serializer, `DiskTransferService`, the health checks) this document cites
the same lines and points back rather than repeating the analysis.

Unless a section says otherwise, **the two repos' qBittorrent files are identical apart from the
`Tv*` → `Movie*` rename**, and:

| File | Line numbers |
|---|---|
| `QBittorrent.cs` (746 lines in both) | **match one-for-one** |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **byte-identical**, match one-for-one |
| `QBittorrentSettings.cs` (91 lines in both) | match one-for-one |
| `QBittorrentProxyV2.cs`, `QBittorrentProxyV1.cs` | Sonarr has a blank line at 13 that Radarr lacks (verified: Sonarr `:12` is the `// API https://…` comment, `:13` is blank, `:14` is `public class QBittorrentProxyV2`; Radarr's class declaration is `:13`). **Sonarr line N = Radarr line N−1 for N ≥ 14.** |
| `QBittorrentProxySelector.cs` | same, from line 3 |
| `QBittorrentFixture.cs` | reordered, not offset — cited per repo |

Paths are `src/NzbDrone.Core/Download/Clients/QBittorrent/...` in both. Citations below are **Sonarr**
line numbers unless marked. The full diff is in §9.

Nothing here is speculation about qBittorrent itself: every claim is what the *client* does. Where a
claim is about qBittorrent's own behaviour it cites `qbittorrent/qBittorrent` master, and where it is
about .NET or Newtonsoft runtime semantics it says so.

---

## 0. Transport-level rules (these bite first)

### 0.1 The client picks v1 or v2 before it does anything else

`QBittorrentProxySelector.FetchProxy` (`QBittorrentProxySelector.cs:80-95`):

```csharp
if (_proxyV2.IsApiSupported(settings)) { return Tuple.Create(_proxyV2, _proxyV2.GetApiVersion(settings)); }
if (_proxyV1.IsApiSupported(settings)) { return Tuple.Create(_proxyV1, _proxyV1.GetApiVersion(settings)); }
throw new DownloadClientException("Unable to determine qBittorrent API version");
```

`QBittorrentProxyV2.IsApiSupported` (`QBittorrentProxyV2.cs:28-70`) does an **unauthenticated**
`GET /api/v2/app/webapiVersion` with `SuppressHttpError = true`, and decides:

| Response | Result |
|---|---|
| `404` | not v2 → fall through to v1 |
| `403` | **v2 supported** (`:44-47`) — this is the "not logged in yet" answer |
| `401` | `DownloadClientException("Failed to connect to qBittorrent. Check your settings and qBittorrent configuration.")` (`:49-52`) |
| any other `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` (`:54-57`) |
| `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to qBittorrent, certificate validation failed.")` (`:63-66`) |
| `200` | v2 supported |

`QBittorrentProxyV1.IsApiSupported` (`QBittorrentProxyV1.cs:27-59`) does the same against
`GET /version/api` — note **no leading `/api/v2`**, and 401 is *not* special-cased there.

The pair `(proxy, version)` is cached for **10 minutes** keyed on `{Host}_{Port}`
(`QBittorrentProxySelector.cs:68-78`). `GetProxy(settings, force: true)` evicts it; the connection
test does exactly that (`QBittorrent.cs:435`, `:519`), which the fixture asserts
(Sonarr `QBittorrentFixture.cs:986-998`, Radarr `:984-996`).

**A shim should answer `/api/v2/app/webapiVersion` and never expose the v1 routes.** v1 is the
pre-4.1 API (`/version/api`, `/query/torrents`, `/command/download`, …); it is dead weight for a new
implementation and it cannot satisfy the import path at all, because `GetLabels` throws
`NotSupportedException("qBittorrent api v1 does not support getting all torrent categories")`
(`QBittorrentProxyV1.cs:236-239`) and `SetTorrentSeedingConfiguration` is a no-op (`:241-244`).
The rest of this document is API v2 only; §1.17 lists the v1 route map for completeness.

### 0.2 URL shape

`QBittorrentProxyV2.BuildRequest` (`QBittorrentProxyV2.cs:341-359`):

```csharp
var requestBuilder = new HttpRequestBuilder(settings.UseSsl, settings.Host, settings.Port, settings.UrlBase)
{
    LogResponseContent = true,
    StoreRequestCookie = false
};
```

- Base URL: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-65`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; `UrlBase` gets a leading `/` if missing.
- `Resource("/api/v2/…")` (`HttpRequestBuilder.cs:244-256`) trims the leading `/` and appends,
  so the full URL is `{scheme}://{host}:{port}{urlBase}/api/v2/{group}/{method}`.
- **No `Accept` header.** `BuildRequest` never calls `.Accept(...)`, and `HttpRequest`'s constructor
  only sets `Headers.Accept` when `httpAccept != null`
  (`src/NzbDrone.Common/Http/HttpRequest.cs:14,30-32`). Do not gate on `Accept`.
- `StoreRequestCookie = false`: the cookie jar is managed by the proxy, not the HTTP layer.

### 0.3 GET-with-query vs POST-with-form — and when the form becomes multipart

Read-only calls use `AddQueryParam` (`HttpRequestBuilder.cs:306-317`) on a GET. Mutating calls use
`.Post()` plus `AddFormParameter` / `AddFormUpload`.

`ApplyFormData` (`HttpRequestBuilder.cs:150-242`) picks the encoding:

```csharp
var shouldSendAsMultipart = FormData.Any(v => v.ContentType != null || v.FileName != null || v.ContentData.Length > 1024);
```

- Any `AddFormUpload` (which sets `FileName` and `ContentType`) forces **`multipart/form-data`**
  (`:379-395`, `:220`).
- **Any single form value longer than 1024 bytes also forces multipart** (`:162`). A magnet URI with a
  long tracker list crosses that line, so `POST /api/v2/torrents/add` arrives as
  `application/x-www-form-urlencoded` *or* `multipart/form-data` depending on the magnet.
  **A shim must parse both on that route.**
- Otherwise: `application/x-www-form-urlencoded`, values escaped with
  `Uri.EscapeDataString(Encoding.UTF8.GetString(...))` (`:230`).

The multipart writer is hand-rolled (`:164-227`) and writes
`Content-Disposition: form-data; name="…"` (plus `; filename="…"` and a `Content-Type:` line for
uploads), a blank line, the raw bytes, then `\r\n`. Boundary is
`-----------------------------{ticks:x14}` (`:166`).

**Boolean formatting is a trap.** `AddFormParameter` stores
`Convert.ToString(value, CultureInfo.InvariantCulture)` (`HttpRequestBuilder.cs:373`), and .NET's
`Convert.ToString(bool)` yields **`"True"` / `"False"`, capitalised**. So
`request.AddFormParameter("stopped", false)` (`QBittorrentProxyV2.cs:258`) puts `stopped=False` on the
wire, not `stopped=false`. Real qBittorrent copes because `Utils::String::parseBool`
(`src/base/utils/string.cpp:108-116`) compares case-insensitively. **A shim must accept
`True`/`False` as well as `true`/`false`.** Where the client hard-codes the string it is lowercase —
`deleteFiles` is `"true"` (`QBittorrentProxyV2.cs:198`) and `setForceStart`'s `value` is
`"true"`/`"false"` (`:337`) — so both spellings genuinely appear.

Numbers go through the same invariant-culture path, so `ratioLimit=1.5` always uses `.` as the
decimal separator (`QBittorrentProxyV2.cs:234`, `HttpRequestBuilder.cs:373`).

### 0.4 Authentication — three layers, all of which can be live at once

`BuildRequest` (`QBittorrentProxyV2.cs:349-356`):

```csharp
if (settings.ApiKey.IsNotNullOrWhiteSpace())
    requestBuilder.Headers["Authorization"] = $"Bearer {settings.ApiKey}";
else if (settings.Username.IsNotNullOrWhiteSpace() || settings.Password.IsNotNullOrWhiteSpace())
    requestBuilder.NetworkCredential = new BasicNetworkCredential(settings.Username, settings.Password);
```

1. **API key** → `Authorization: Bearer <key>` on every request, and `ProcessRequest` takes a
   short-circuit path that never logs in (`:371-395`). `QBittorrentSettingsValidator` forbids
   username/password alongside a key (`QBittorrentSettings.cs:16-21`).
2. **Username/password** → `BasicNetworkCredential`, which `ManagedHttpDispatcher` turns into a
   **preemptive** `Authorization: Basic base64(user:pass)` header on *every* request, including
   `auth/login` itself (`src/NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:81-89`,
   comment: "Manually set header to avoid initial challenge response").
3. **Cookie session** → `AuthenticateClient` (`QBittorrentProxyV2.cs:430-494`).

`AuthenticateClient`, exactly:

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

Consequences for a shim:

- `POST /api/v2/auth/login`, body `username=…&password=…`, `application/x-www-form-urlencoded`.
- Answer **HTTP 200** with body exactly `Ok.` and a `Set-Cookie: SID=…` header — the shape real
  qBittorrent uses (wiki, *Login*: "Upon success, the response will contain a cookie with your SID").
- **An empty body is also accepted** (`:479` short-circuits on `IsNotNullOrWhiteSpace`). Anything else
  — `"Fails."`, `"ok"`, JSON — is an authentication failure. The v1 proxy is stricter and demands
  exactly `Ok.` (`QBittorrentProxyV1.cs:371`).
- On an HTTP error from `auth/login`: 401 or 403 → `DownloadClientAuthenticationException`; anything
  else → `DownloadClientException` (`:463-473`). A `WebException` → `DownloadClientUnavailableException`.
- The cookie is cached per `{baseUrl}:{user}:{pass}` for the lifetime of the process's cache entry
  and only refreshed when a request comes back 403 (§0.5).
- **`Referer` and `Origin` are never sent.** The wiki tells API consumers to set them
  ("Note: Set `Referer` or `Origin` header to the exact same domain and port as used in the HTTP
  query `Host` header") and Sonarr does not. A shim must not require them.
- With **no credentials configured at all**, `AuthenticateClient` returns immediately and nothing is
  sent — no login, no cookie, no `Authorization`. An unauthenticated shim works.

### 0.5 Which HTTP statuses are treated as errors

`HttpClient.Execute` (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`) throws when
`response.HasHttpError` — `(int)StatusCode >= 400` (`src/NzbDrone.Common/Http/HttpResponse.cs:54`) —
unless `SuppressHttpError` or the status is in `SuppressHttpErrorStatusCodes`. 429 becomes
`TooManyRequestsException` (`:115`); everything else `HttpException` (`:119`).

`QBittorrentProxyV2.ProcessRequest` (`:369-428`) then wraps it. Two distinct paths:

**API-key path** (`:371-395`):

| Status | Result |
|---|---|
| 401, 403 | `DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.")` |
| any other `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` |
| anything else thrown | `DownloadClientException("Failed to connect to qBittorrent, please check your settings.")` |

**Cookie path** (`:397-427`):

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

- **403 means "session expired, log in again"** — it is suppressed once, the client re-logs-in and
  retries. This is the loop qBittorrent's own session expiry produces, and a shim can use it the
  same way.
- The **retry request is rebuilt from the builder**, which carries no
  `SuppressHttpErrorStatusCodes` — that field was set on the *request* at `:401`, not on the builder.
  So a second 403 throws `HttpException` and surfaces as
  `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` — **not** an
  authentication failure. A shim that answers 403 forever produces a confusing connection error, not
  "Authentication Failure", in the UI.
- With no credentials configured, the re-login attempt at `:411` throws
  `DownloadClientAuthenticationException` straight away (`:434-437`).

**Every successful call must be HTTP 200 with the exact body the client expects.** There is no
JSON error envelope anywhere in this API; unlike SAB, errors here are HTTP statuses.

### 0.6 Deserializer settings

All qBittorrent payloads go through `NzbDrone.Common.Serializer.Json`
(`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`) — **Newtonsoft**, the same instance
the SAB client uses, so [sabnzbd-client-contract.md §0.3](sabnzbd-client-contract.md) applies verbatim:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

What that means for the qBittorrent models specifically:

| Model member | Binds to | Why |
|---|---|---|
| `QBittorrentTorrent.Hash/Name/Size/Progress/Eta/State/Label/Category/Ratio` | `hash`, `name`, `size`, `progress`, `eta`, `state`, `label`, `category`, `ratio` | camelCase resolver; Newtonsoft also matches case-insensitively |
| `SavePath`, `ContentPath`, `RatioLimit`, `SeedingTime`, `SeedingTimeLimit`, `InactiveSeedingTimeLimit`, `LastActivity` | `save_path`, `content_path`, `ratio_limit`, `seeding_time`, `seeding_time_limit`, `inactive_seeding_time_limit`, `last_activity` | explicit `[JsonProperty]` (`QBittorrentTorrent.cs:24-45`) |
| `QBittorrentLabel.Name/SavePath` | `name`, `savePath` | **no** `[JsonProperty]` — camelCase resolver. qBittorrent's `torrents/categories` really does use camelCase here, unlike everything else |
| `QBittorrentPreferences.*` | all explicit `[JsonProperty]` snake_case (`QBittorrentPreferences.cs:16-44`) | |
| `QBittorrentMaxRatioAction` | `max_ratio_act` | no per-property converter, so the global `StringEnumConverter` applies. `AllowIntegerValues` defaults true, so **send the integer**, as real qBittorrent does. A string would have to be camelCase (`"pause"`, `"remove"`) and an unknown name throws |

`NullValueHandling.Ignore` applies on **read** too: a JSON `null` leaves the member at its constructor
value. Combined with the defaults declared in the models, an **absent or null** field is not the same
as a zero:

| Field | Default if absent/null | Citation |
|---|---|---|
| `ratio_limit` | `-2f` | `QBittorrentTorrent.cs:33` |
| `seeding_time_limit` | `-2` | `:39` |
| `inactive_seeding_time_limit` | `-2` | `:42` |
| `seeding_time` | `null` (`long?`) | `:36` |
| `queueing_enabled` | **`true`** | `QBittorrentPreferences.cs:41` |
| everything else | CLR default (`0`, `false`, `null`) | |

`Eta` is a `System.Numerics.BigInteger` (`QBittorrentTorrent.cs:17`, comment "QBit contains a bug
exceeding ulong limits"); Sonarr's fixture pins `18446744073709335000` as parseable
(Sonarr `QBittorrentFixture.cs:974-984`, Radarr `:973-982`).

`Json.Deserialize<T>` rethrows `JsonReaderException` with a nicer message (`Json.cs:39-50`). None of
the qBittorrent proxy calls use `TryDeserialize`, so **a malformed or wrong-shaped body throws out of
the proxy** and becomes an unhandled exception at the call site — for `GetItems()` that kills the whole
poll.

### 0.7 Every `version >=` gate, in one place

`ProxyApiVersion` is `_proxySelector.GetApiVersion(Settings)` (`QBittorrent.cs:50`), i.e. the cached
`app/webapiVersion`. The gates:

| Gate | Where | Effect below the threshold |
|---|---|---|
| `>= 1.5` | `QBittorrent.cs:436` | Test fails: "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| `>= 1.6` | `:445` | Test fails if a category is configured: "Category is not supported" |
| `>= 2.0` | `:379` (`GetStatus`), `:520` (`TestCategory`) | category `savePath` is not read, and categories are neither checked nor created |
| `>= 2.6.1` | `:314` | `OutputPath` is **not** taken from `content_path`; `GetImportItem` walks `torrents/files` instead (§4.2) |
| `>= 2.8.1` | `:79`, `:136` | share limits cannot ride on `torrents/add`; they are applied afterwards with `torrents/setShareLimits` |
| `>= 2.11.0` | `QBittorrentProxyV2.cs:253` | `torrents/add` sends `paused=` instead of `stopped=` |

`Version.Parse` (`QBittorrentProxyV2.cs:75`) needs **at least `major.minor`** — a bare `"2"` throws
`FormatException`, and that exception is raised outside every `try` in the proxy, so it escapes
`GetApiVersion` entirely. Report something like `2.11.2`.

**Recommended value for a shim: `2.11.2`.** That clears every gate, puts `content_path` on the
`torrents/info` path (the only sane import route), and selects the qBittorrent 5.x `stopped=`
spelling on add.

---

## 1. Every endpoint, in the order the client calls them

Interface: `IQBittorrentProxy` (`QBittorrentProxySelector.cs:9-30`). Implementation:
`QBittorrentProxyV2`. Every call site in `QBittorrent.cs` is listed at `:49-741`.

### 1.1 `GET /api/v2/app/webapiVersion` — `GetApiVersion` (`QBittorrentProxyV2.cs:72-78`)

Request: no parameters. Sent unauthenticated first (as the probe, §0.1), then authenticated.

Response: **plain text**, a version string parsed by `Version.Parse`. Not JSON, no quotes.

Called by: the proxy probe (`:31`), `GetItems` (`QBittorrent.cs:220`), `GetStatus` (`:374`),
`TestConnection` (`:435`), `TestCategory` (`:519`), and — the one that is easy to miss —
`AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:253`), which means **every
`torrents/add` is preceded by its own `app/webapiVersion` round trip** whenever the initial state is
Start or Stop (i.e. always, unless the user picked Force Start).

### 1.2 `GET /api/v2/app/version` — `GetVersion` (`QBittorrentProxyV2.cs:80-87`)

Response: plain text, `v` stripped from the front (`:83`). Comment: `// eg "4.2alpha"`.

**Never called.** It is on the interface (`QBittorrentProxySelector.cs:13`) with no caller anywhere in
`QBittorrent.cs` (verified against every `Proxy.`/`_proxySelector.` reference, `:49-741`). Implement it
anyway — it costs nothing and a human poking the shim will reach for it.

### 1.3 `POST /api/v2/auth/login`

Covered in §0.4. Form: `username`, `password`. Answer `200` + `Ok.` + `Set-Cookie: SID=…`.

### 1.4 `GET /api/v2/app/preferences` — `GetConfig` (`QBittorrentProxyV2.cs:89-95`)

Request: no parameters. Response: one JSON object, deserialized into `QBittorrentPreferences`.

**Every key the client reads** (`QBittorrentPreferences.cs:14-45`) — nothing else in the body is
looked at, and extra keys are ignored:

| JSON key | C# | Type | Read by |
|---|---|---|---|
| `save_path` | `SavePath` | `string` | `GetStatus` → `OutputRootFolders` (`QBittorrent.cs:377`) |
| `max_ratio_enabled` | `MaxRatioEnabled` | `bool` | `HasReachedSeedLimit` (`:639`), `RemovesCompletedDownloads` (`:415`) |
| `max_ratio` | `MaxRatio` | `float` | `HasReachedSeedLimit` (`:641`) |
| `max_seeding_time_enabled` | `MaxSeedingTimeEnabled` | `bool` | `HasReachedSeedingTimeLimit` (`:663`), `RemovesCompletedDownloads` (`:415`) |
| `max_seeding_time` | `MaxSeedingTime` | `long`, **minutes** | `:665`, `:415` |
| `max_inactive_seeding_time_enabled` | `MaxInactiveSeedingTimeEnabled` | `bool` | `HasReachedInactiveSeedingTimeLimit` (`:727`) |
| `max_inactive_seeding_time` | `MaxInactiveSeedingTime` | `long`, **minutes** | `:729` |
| `max_ratio_act` | `MaxRatioAction` | enum-as-int: `Pause=0, Remove=1, EnableSuperSeeding=2, DeleteFiles=3` (`QBittorrentPreferences.cs:5-11`) | `RemovesCompletedDownloads` (`:415`) |
| `queueing_enabled` | `QueueingEnabled` | `bool`, **defaults `true`** | `TestPrioritySupport` (`:572`) |
| `dht` | `DhtEnabled` | `bool` | `AddFromMagnetLink` (`:73`), the `metaDL` branch (`:288`) |

Called by: `AddFromMagnetLink` (`:73`), `GetItems` (`:221`), `GetStatus` (`:375`), `TestConnection`
(`:467`), `TestPrioritySupport` (`:570`). It is **not** cached, so it is fetched on every poll.

`RemovesCompletedDownloads` (`QBittorrent.cs:412-416`) is the derived flag:

```csharp
var minimumRetention = 60 * 24 * 14; // 14 days in minutes
return (config.MaxRatioEnabled || (config.MaxSeedingTimeEnabled && config.MaxSeedingTime < minimumRetention))
    && (config.MaxRatioAction == QBittorrentMaxRatioAction.Remove || config.MaxRatioAction == QBittorrentMaxRatioAction.DeleteFiles);
```

It feeds both the connection test (`:468`) and the
`DownloadClientRemovesCompletedDownloadsCheck` health check
(`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:44-53`). With
`max_ratio_enabled: false` and `max_seeding_time_enabled: false` it is false whatever `max_ratio_act`
says — but send `max_ratio_act: 0` anyway.

### 1.5 `GET /api/v2/torrents/categories` — `GetLabels` (`QBittorrentProxyV2.cs:221-225`)

Request: no parameters.

Response: a JSON **object**, `{"<name>": {"name": "...", "savePath": "..."}}`, deserialized into
`Dictionary<string, QBittorrentLabel>` — note **camelCase `savePath`**, per §0.6 and the wiki's
*Get all categories* example. An array here throws.

Read for two things:

1. `TestCategory` (`QBittorrent.cs:525-553`) — key membership only (§6.3).
2. `GetStatus` (`:379-402`) — the configured category's `savePath` becomes the download client's
   output root folder:

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

A **relative** `savePath` is appended to the global `save_path`; a rooted one replaces it. A
`savePath` starting with `//` is turned into a backslash UNC path — Sonarr's fixture pins
`"//server/store/downloads"` → `\\server\store\downloads`
(Sonarr `QBittorrentFixture.cs:563-589`, Radarr `:562-588`). **Never emit a leading `//`.**
The simplest correct answer is `"savePath": ""`, which leaves the root folder at the global
`save_path`.

### 1.6 `POST /api/v2/torrents/createCategory` — `AddLabel` (`QBittorrentProxyV2.cs:213-219`)

Form: `category=<name>`. **`savePath` is not sent** — the client never sets a category save path.
Response body is ignored; only a non-error status matters.

Called only from `TestCategory` (`QBittorrent.cs:529`, `:543`), when the category is missing.
`torrents/editCategory` and `torrents/removeCategories` are **never called**.

### 1.7 `POST /api/v2/torrents/add` — `AddTorrentFromUrl` / `AddTorrentFromFile`

`AddTorrentFromUrl` (`QBittorrentProxyV2.cs:146-166`): form field **`urls`** = the magnet URI.
`AddTorrentFromFile` (`:168-188`): form upload **`torrents`**, filename
`{CleanFileName(release title)}.torrent` (`TorrentClientBase.cs:199`),
`Content-Type: application/octet-stream` (`HttpRequestBuilder.cs:379`).

Both then add `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:243-284`):

| Form field | Value | Condition | Line |
|---|---|---|---|
| `category` | `Settings.TvCategory` / `MovieCategory` | category non-blank | `:245-248` |
| `stopped` (webapi `>= 2.11.0`) or `paused` (below) | `False` for Start, `True` for Stop | `InitialState` is Start or Stop — **Force Start sends neither** | `:251-264` |
| `sequentialDownload` | `True` | `SequentialOrder` setting on | `:266-269` |
| `firstLastPiecePrio` | `True` | `FirstAndLast` setting on | `:271-274` |
| `contentLayout` | `"Original"` or `"Subfolder"` | `ContentLayout` setting is Original or Subfolder; **Default sends nothing** | `:276-283` |

and, when share limits are configured *and* webapi `>= 2.8.1` (`QBittorrent.cs:79`, `:136`),
`AddTorrentSeedingFormParameters(request, seedConfiguration)` (`QBittorrentProxyV2.cs:227-241`):

| Form field | Value | Condition |
|---|---|---|
| `ratioLimit` | `seedConfiguration.Ratio` or `-2` | only when it is not `-2` (`:232`) |
| `seedingTimeLimit` | `seedConfiguration.SeedTime.TotalMinutes` or `-2` | only when it is not `-2` (`:237`) |

**Everything else the wiki documents for `torrents/add` is never sent**: no `savepath`, no `cookie`,
no `tags`, no `skip_checking`, no `root_folder`, no `rename`, no `upLimit`, no `dlLimit`, no
`autoTMM`. There is no `priority` parameter on add — queue priority is a separate `topPrio` call
(§1.10).

Response handling (`:159-165`, `:181-187`):

```csharp
var result = ProcessRequest(request, settings);
// Note: Older qbit versions returned nothing, so we can't do != "Ok." here.
if (result == "Fails.") { throw new DownloadClientException("Download client failed to add torrent by url"); }
```

So: **200 with any body except the literal `Fails.` is success.** `Ok.` is the conventional answer.
An HTTP 415 (the wiki's "torrent file is not valid") becomes a `DownloadClientException` via `:389`.

**The download id does not come from this call.** It is computed client-side, before the request:

- magnet → `MagnetLink.Parse(magnetUrl).InfoHash.ToHex()` (`TorrentClientBase.cs:224`)
- `.torrent` → `_torrentFileInfoReader.GetHashFromTorrentFile(torrentFile)` (`:200`)

and `AddFromMagnetLink` / `AddFromTorrentFile` return that same `hash` unchanged
(`QBittorrent.cs:130`, `:187`). **The shim must key the torrent on exactly that infohash**, or Sonarr
loses track of the grab — `TorrentClientBase.cs:206-212` and `:238-244` only log a Debug line about it.
The DHT precondition is checked first for magnets:

```csharp
if (!Proxy.GetConfig(Settings).DhtEnabled && !magnetLink.Contains("&tr="))
    throw new NotSupportedException("Magnet Links without trackers not supported if DHT is disabled");   // :73-76
```

which the caller turns into `ReleaseDownloadException("Magnet not supported by download client…")`
when there is no `.torrent` fallback (`TorrentClientBase.cs:111-119`). **Report `dht: true`.**

After the add, `WaitForTorrent` (`QBittorrent.cs:190-214`) polls `IsTorrentLoaded` **10 times with a
100 ms sleep** — but only when there is follow-up work to do (post-add share limits, top priority, or
force start; `:86`, `:143`). Its failure message says "within 500 ms" and the loop is actually 10 ×
100 ms; either way it gives up and returns the hash (`:212-213`).

### 1.7a How long the client waits for `torrents/add` — **100 seconds**, measured 2026-08-30

Read out of `Sonarr/Sonarr@32a5d492` and `Radarr/Radarr@40bb746c` (both `develop`) on 2026-08-30.
This bounds everything a shim does synchronously inside the add call, so it is worth citing rather
than assuming.

Nothing on the qBittorrent path sets a timeout, so the value falls through four layers to a flat 100 s:

| Step | Sonarr `path:line` | Radarr `path:line` | What it does |
|---|---|---|---|
| the add call | `QBittorrentProxyV2.cs:146-150`, `:168-172` | `:145-149`, `:167-171` | builds the request, sets no timeout |
| the builder | `NzbDrone.Common/Http/HttpRequestBuilder.cs:104-116` | same file `:104-116` | `Apply()` has no `RequestTimeout` line, and the class has no such property |
| the field default | `NzbDrone.Common/Http/HttpRequest.cs:52` | `:54` | auto-property never assigned in the constructor, so `TimeSpan.Zero` |
| the dispatcher | `NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:70-79` | `:68-77` | `Zero` becomes `cts.CancelAfter(TimeSpan.FromSeconds(100))` |

```csharp
using var cts = new CancellationTokenSource();
if (request.RequestTimeout != TimeSpan.Zero) { cts.CancelAfter(request.RequestTimeout); }
else { /* The default for System.Net.Http.HttpClient */ cts.CancelAfter(TimeSpan.FromSeconds(100)); }
```

`RequestTimeout` and `Timeout` appear nowhere under
`src/NzbDrone.Core/Download/Clients/QBittorrent/` in either repo, and `HttpRequestBuilder` exposes no
way to set one, so a shim cannot be granted more time by configuration.

Five things follow.

- **The 100 s is Sonarr's own cancellation token, not .NET's timer.** The underlying handler is built
  with `Timeout = Timeout.InfiniteTimeSpan` (`ManagedHttpDispatcher.cs:183` Sonarr, `:180` Radarr), so
  the token is the only bound. It is passed to both `SendAsync` and `ReadAsByteArrayAsync` (`:115`,
  `:127`), which means it covers connect plus request body plus response headers plus response body.
- **A timeout is reported to the user as a connection fault.** Expiry raises
  `new WebException("Http request timed out", …)` (`:142-145`), which `ProcessRequest` wraps as
  `DownloadClientException("Failed to connect to qBittorrent, please check your settings.", ex)`
  (`QBittorrentProxyV2.cs:424-427`). A shim that blocks past 100 s therefore looks misconfigured
  rather than slow, and the *arr never learns that the add was still in flight.
- **There is no separate connect timeout and no larger budget for a multipart upload.**
  `SocketsHttpHandler.ConnectTimeout` is never set. The one exception is a 2 s cap on the first
  IPv6 attempt in the process lifetime (`ManagedHttpDispatcher.cs:23`, `:288-295`), which falls
  through to IPv4 inside the same 100 s. A `.torrent` upload is buffered whole into a byte array
  (`HttpRequestBuilder.cs:220-221`, `ManagedHttpDispatcher.cs:103`) and sent under the same token.
- **300 s exists but is a different path.** `HttpClient.cs:285` sets
  `request.RequestTimeout = TimeSpan.FromSeconds(300)` inside `DownloadFileAsync`, which fetches the
  `.torrent` from the indexer. It never reaches a download client call.
- **Deluge proves the override exists and qBittorrent declines it.** `DelugeProxy.cs:222` does
  `requestBuilder.PostProcess += r => r.RequestTimeout = TimeSpan.FromSeconds(15)`. qBittorrent's
  `BuildRequest` has no such line, which is the direct evidence that 100 s is inherited rather than
  chosen.

**Radarr is identical.** A diff of the timeout block (Radarr `:68-78` against Sonarr `:70-80`) comes
back byte-identical, and the only difference in the chain is that Radarr passes `ex` where Sonarr
passes `ex.InnerException` into the `WebException`.

**Consequence for the shim.** Every synchronous decision taken inside `torrents/add` shares one 100 s
budget, and the *arr has no way to distinguish "still working" from "unreachable". The
per-attempt deadline times the number of providers tried, plus any cached-only probe window, must
stay well under it. The measured provider latencies that budget is built from are in
torrent-lifecycle.md in the zurg repository.

One footnote for completeness. The 100 s is per dispatcher call, so each hop of an auto-redirect
chain gets a fresh budget (`HttpClient.cs:43` caps the chain at 5). The retry strategy at
`DownloadClientBase.cs:30-44` does **not** apply here; it is only used when fetching the `.torrent`
from the indexer (`TorrentClientBase.cs:142-144`).

### 1.8 `GET /api/v2/torrents/properties?hash=<hash>` — `IsTorrentLoaded` / `GetTorrentProperties`

`IsTorrentLoaded` (`QBittorrentProxyV2.cs:110-126`) calls it with `LogHttpError = false` and treats
**any** exception as "not loaded".

`GetTorrentProperties` (`:128-135`) deserializes into `QBittorrentTorrentProperties`
(`QBittorrentTorrent.cs:48-57`) — **three fields, and only two are used**:

| JSON key | C# | Used for |
|---|---|---|
| `hash` | `Hash` | read, never used |
| `save_path` | `SavePath` | `GetImportItem`'s pre-2.6.1 path (`QBittorrent.cs:354`) |
| `seeding_time` | `SeedingTime` (`long`, **seconds**) | `FetchTorrentDetails` (`:739-744`) |

**Hash casing is inconsistent here and it matters.** Every other call lowercases
(`item.DownloadId.ToLower()` at `:335`, `:346`, `:353`; `hash.ToLower()` at `:97`, `:109`, `:121`,
`:198`), but `FetchTorrentDetails` passes `torrent.Hash` through **verbatim** (`:741`) — whatever the
shim put in `torrents/info`. Real qBittorrent returns lowercase hashes so this never bites it, and
Sonarr's fixture pins the asymmetry by mocking `GetTorrentProperties("HASH", …)` with the uppercase
value (Sonarr `QBittorrentFixture.cs:669-675`, Radarr `:668-674`). **Return lowercase hashes from `torrents/info`, and
match `?hash=` case-insensitively.**

`FetchTorrentDetails` is called only from `HasReachedSeedingTimeLimit` (`:700`), which is only reached
when a seeding-time limit is actually in force — so a shim that declares no seeding-time limits never
sees this call at all during polling. It is still needed for `IsTorrentLoaded`, which is the
post-add readiness probe: **404 for an unknown hash, 200 + JSON for a known one.**

The result is cached for 5 minutes per `{Host}{Port}{Hash}` (`:678`, `:689`, `:695`, `:708`), and the
fixture asserts it is fetched once, not twice, across two polls
(Sonarr `QBittorrentFixture.cs:905-920`, Radarr `:904-919`).

### 1.9 `POST /api/v2/torrents/setShareLimits` — `SetTorrentSeedingConfiguration` (`:286-308`)

Form: `hashes=<lowercase hash>`, then `AddTorrentSeedingFormParameters(request, seedConfiguration, always: true)`
— with `always: true` **both** `ratioLimit` and `seedingTimeLimit` are always sent, even when `-2`
(`:232`, `:237`). `inactiveSeedingTimeLimit` is never sent.

A **404** is swallowed (`:298-307`, comment: "setShareLimits was added in api v2.0.1"). Any other
error propagates, but the call site catches and logs a warning
(`QBittorrent.cs:95-102`, `:152-159`).

Only reached when the indexer supplies a seed configuration *and* webapi `< 2.8.1`. On a shim
reporting `2.11.2`, share limits ride on `torrents/add` instead and this route is never used for a
grab. Implement it as a no-op that returns 200.

### 1.10 `POST /api/v2/torrents/topPrio` — `MoveTorrentToTopInQueue` (`:310-330`)

Form: `hashes=<lowercase hash>`.

A **409 Conflict** is swallowed (`:320-329`, comment: "qBittorrent rejects all Prio commands with 409:
Conflict if Options -> BitTorrent -> Torrent Queueing is not enabled"). The v1 proxy swallows **403**
instead (`QBittorrentProxyV1.cs:255-264`). Anything else is caught and warned at the call site
(`QBittorrent.cs:107-114`, `:164-171`) — the fixture asserts a failure here does not fail the grab
(Sonarr `QBittorrentFixture.cs:525-542`, Radarr `:524-541`).

Only called when the Recent/Older priority setting is `First` (`QBittorrentPriority.First = 1`,
`QBittorrentPriority.cs:5-6`); the default is `Last = 0`.

### 1.11 `POST /api/v2/torrents/setForceStart` — `SetForceStart` (`:332-339`)

Form: `hashes=<lowercase hash>`, `value=true` (the literal lowercase string, `:337`).

Only called when `InitialState` is `ForceStart` (`QBittorrentState.cs:10-11`,
`QBittorrent.cs:82`, `:117-127`). Errors are caught and warned (`:123-126`).

### 1.12 `GET /api/v2/torrents/info[?category=<cat>]` — `GetTorrents` (`:97-108`)

**The only parameter ever sent is `category`, and only when the setting is non-blank**
(`:100-103`). No `filter`, no `hashes`, no `sort`, no `reverse`, no `limit`, no `offset`, no `tag`.
The client does **not** filter by category again afterwards — unlike the SAB client, which
double-filters. So a shim that ignores `category` will hand Radarr Sonarr's torrents.

The `category` field on the response matters for a second reason: a torrent the \*arr has **no
grab history for** is skipped outright unless it carries one —
`CompletedDownloadService.Check` (`CompletedDownloadService.cs:84-88`):

```csharp
if (historyItem == null && trackedDownload.DownloadItem.Category.IsNullOrWhiteSpace())
{
    trackedDownload.Warn("Download wasn't grabbed by Sonarr and not in a category, Skipping.");
    return;
}
```

`Category` is `category` if non-blank, else `label` (`QBittorrent.cs:231`).

Response: a JSON **array**. Every field consumed, and what it becomes:

| JSON key | C# type | Units | Becomes |
|---|---|---|---|
| `hash` | `string` | | `DownloadId = torrent.Hash.ToUpper()` (`QBittorrent.cs:230`) — **uppercased**, and passed back down lowercased on every subsequent call |
| `name` | `string` | | `Title = torrent.Name` (`:232`) — see §7.1 for everything this drives |
| `size` | `long` | bytes | `TotalSize` (`:233`); also `RemainingSize = (long)(size * (1.0 - progress))` (`:235`) |
| `progress` | `double` | 0..1 | `RemainingSize` (`:235`) |
| `eta` | `BigInteger` | seconds | `RemainingTime` via `GetRemainingTime` (`:236`, `:614-628`) |
| `state` | `string` | | `Status`, `Message`, and half of the `CanMoveFiles` gate (`:242-312`) — §2 |
| `category` | `string` | | `Category`, preferred (`:231`) |
| `label` | `string` | | `Category`, fallback when `category` is blank (`:231`). Pre-3.3.5 field; qBittorrent 5 does not emit it |
| `ratio` | `float` | | `SeedRatio` (`:237`), `HasReachedSeedLimit` (`:634`, `:641`) |
| `ratio_limit` | `float`, default `-2` | | `HasReachedSeedLimit` (`:632-645`) |
| `seeding_time_limit` | `long`, default `-2` | **minutes** | `HasReachedSeedingTimeLimit` (`:659-670`) |
| `inactive_seeding_time_limit` | `long`, default `-2` | **minutes** | `HasReachedInactiveSeedingTimeLimit` (`:723-736`) |
| `last_activity` | `long` | **unix seconds** | `HasReachedInactiveSeedingTimeLimit` (`:736`) |
| `seeding_time` | `long?`, default null | seconds | `HasReachedSeedingTimeLimit` (`:672-676`) — comment at `QBittorrentTorrent.cs:36` says it is "not provided by the list api", but the client uses it if present, which saves a `torrents/properties` round trip |
| `save_path` | `string` | | compared against `content_path` (`:316`) |
| `content_path` | `string` | | `OutputPath` on webapi `>= 2.6.1` (`:318`) — §4 |

`GetRemainingTime` (`:614-628`):

```csharp
if (torrent.Eta < 0 || torrent.Eta > 365 * 24 * 3600) { return null; }   // > 31,536,000 s
if (torrent.Eta == 8640000) { return null; }                            // qBittorrent's "unknown"
return TimeSpan.FromSeconds((int)torrent.Eta);
```

and a Completed item has `RemainingTime` forced to `TimeSpan.Zero` afterwards (`:273`).

`torrents/info` is fetched on every `RefreshMonitoredDownloads`
(`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:94`), which is also
debounced onto the command queue 5 s after relevant events (`:53`).

### 1.13 `GET /api/v2/torrents/files?hash=<hash>` — `GetTorrentFiles` (`:137-144`)

Response: a JSON array deserialized into `List<QBittorrentTorrentFile>`, which has **exactly one
member**: `Name` (`QBittorrentTorrent.cs:59-62`), binding `name` — the file path **relative to the
save path**, with `/` separators on every OS ("QBittorrent returns `/` path separators even on
windows", `QBittorrent.cs:358`).

Called only from `GetImportItem` (`:346`) and only when `OutputPath` is still empty — i.e. on webapi
`< 2.6.1`, or when `content_path` came back empty. `index`, `size`, `progress`, `priority`, `is_seed`,
`piece_range` and `availability` are all ignored.

An **empty array** is handled: `_logger.Debug("No files found for torrent {0} in qBittorrent")` and the
item is returned unchanged (`:347-351`), which then fails `ValidatePath`.

### 1.14 `POST /api/v2/torrents/setCategory` — `SetTorrentLabel` (`:204-211`)

Form: `hashes=<lowercase hash>`, `category=<post-import category>`.

Called only from `MarkItemAsImported` (`QBittorrent.cs:52-69`), and only when the optional
`TvImportedCategory` / `MovieImportedCategory` setting is non-blank and different from the main
category. A `DownloadClientException` is caught and warned:
"Failed to set post-import torrent label \"{0}\" for {1} in qBittorrent. Does the label exist?"
(`:62-67`). §5.1.

### 1.15 `POST /api/v2/torrents/delete` — `RemoveTorrent` (`:190-202`)

Form: `hashes=<lowercase hash>`, plus `deleteFiles=true` **only when `removeData` is true**
(`:196-199`) — the literal lowercase string, not `Convert.ToString(bool)`.

`QBittorrent.RemoveItem` (`:333-336`) is the whole implementation:

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    Proxy.RemoveTorrent(item.DownloadId.ToLower(), deleteData, Settings);
}
```

**It does not call `DeleteItemData`.** That is the difference from the SAB client, which deletes the
job folder itself through the filesystem
(`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`; see
[sabnzbd-client-contract.md §5.3](sabnzbd-client-contract.md)). Here the data delete is entirely the
download client's job. §5.

### 1.16 Endpoints the client never touches

Not on the interface at all, so never called: `torrents/pause`, `torrents/resume`, `torrents/stop`,
`torrents/start`, `torrents/setLocation`, `torrents/rename`, `torrents/recheck`,
`torrents/reannounce`, `torrents/filePrio`, `torrents/setDownloadLimit`, `torrents/setUploadLimit`,
`torrents/toggleSequentialDownload`, `torrents/setAutoManagement`, `torrents/editCategory`,
`torrents/removeCategories`, tags, RSS, search, `app/setPreferences`, `app/defaultSavePath`,
`app/shutdown`, `sync/maindata`, `transfer/*`, `auth/logout`. Pausing and resuming exist only as the
`paused=`/`stopped=` form field on `torrents/add`.

On the interface but never called from `QBittorrent.cs`: `GetVersion` (§1.2).

### 1.17 The v1 route map (for completeness; do not implement)

`QBittorrentProxyV1.cs`: `/version/api` (`:30`, `:64` — the client prefixes `"1."` to whatever comes
back, `:65`), `/version/qbittorrent` (`:73`), `/query/preferences` (`:81`),
`/query/torrents?label=&category=` (`:89-94` — **both** params), `/query/propertiesGeneral/{hash}`
(`:103`, `:120`), `/query/propertiesFiles/{hash}` (`:128`), `/command/download` (`:136`),
`/command/upload` (`:166`), `/command/delete` or `/command/deletePerm` (`:196` — the delete/deleteFiles
distinction is two different routes, not a parameter), `/command/setCategory` with a
`/command/setLabel` fallback on 404 (`:205-225`), `/command/addCategory` (`:230`),
`/command/topPrio` (`:248`), `/command/setForceStart` (`:269`), `/login` (`:345`).

---

## 2. `state` → `DownloadItemStatus`

`QBittorrent.GetItems` (`:247-312`). The states are qBittorrent's own strings, produced by
`torrentStateToString` (`qBittorrent/src/webui/api/serialize/serialize_torrent.cpp:44-87`).

| `state` | `DownloadItemStatus` | `Message` | Line |
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
| `metaDL` | Queued **if `dht: true`**, else Warning | "qBittorrent is downloading metadata" / "qBittorrent cannot resolve magnet link with DHT disabled" | `:286-299` |
| `forcedMetaDL` | same as `metaDL` | same | `:287` |
| `forcedDL` | Downloading | — | `:301` |
| `moving` | Downloading | — | `:302` |
| `downloading` | Downloading | — | `:303` |
| **anything else** | **Downloading** | "Unknown download state: {state}" | `:307-311` |

Notes a shim must act on:

- **An unknown state does not throw.** It logs `_logger.Info($"Unknown download state: {torrent.State}")`
  and falls through to Downloading (`:307-311`). This is the opposite of the SAB client, where an
  unknown status name throws inside the deserializer and kills the whole poll. Still: only send names
  from this table.
- **The Completed states are the only ones that can be imported.** `CompletedDownloadService.Check`
  returns immediately unless `Status == Completed`
  (`src/NzbDrone.Core/Download/CompletedDownloadService.cs:68-71`).
- **Every Completed state resets `RemainingTime` to zero** (`:273`, comment "qBittorrent sends
  eta=8640000 for completed torrents").
- `metaDL` / `forcedMetaDL` is the "magnet, no metadata yet" phase. There is **no timeout** in the
  client: it is Queued for as long as the shim keeps saying `metaDL`, and it never escalates to a
  failure by itself. The only thing that turns it into a Warning is `dht: false` in
  `app/preferences` (`:288`). Sonarr's failed-download handling escalates on grab age, not on this
  state.
- `stalledDL` is the *warning* the operator sees for a torrent that is not moving. A shim with no
  peers concept should never use it — a Warning on a tracked download surfaces in the queue as a
  problem and is what `FailedDownloadService` inspects.
- `error` and `missingFiles` are Warnings deliberately, "so failed download handling isn't triggered"
  (`:249`). If a shim wants Sonarr to blocklist and re-grab, a Warning is **not** how to ask.

---

## 3. Move vs copy — the exact condition, and the recipe

### 3.1 The gate

`QBittorrent.cs:240-245`, verbatim including the comment that explains it:

```csharp
// Avoid removing torrents that haven't reached the global max ratio.
// Removal also requires the torrent to be paused, in case a higher max ratio was set on the torrent itself (which is not exposed by the api).
item.CanMoveFiles = item.CanBeRemoved =
    item.DownloadClientInfo.RemoveCompletedDownloads &&
    torrent.State is "pausedUP" or "stoppedUP" &&
    HasReachedSeedLimit(torrent, config);
```

Three conjuncts, all required:

1. **`RemoveCompletedDownloads`** — the *arr-side per-client setting, not anything qBittorrent says.
   `DownloadClientDefinition.RemoveCompletedDownloads` defaults to **`true`**
   (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17`), surfaced in the UI as
   "Remove Completed". If the user turns it off, **imports become copies** and there is nothing a shim
   can do about it.
2. **`state` is exactly `pausedUP` or `stoppedUP`.** `uploading`, `stalledUP`, `queuedUP` and
   `forcedUP` are Completed but not movable — the fixture pins that
   (Sonarr `QBittorrentFixture.cs:680-689`, Radarr `:679-688`).
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

- A **per-torrent `ratio_limit >= 0`** wins outright and the global is not consulted. `ratio_limit`
  is `-2` = "use global" and `-1` = "unlimited" in qBittorrent's own model
  (`QBittorrentTorrent.cs:32`; wiki, *Set torrent share limit*).
- `-1` (unlimited) satisfies neither branch — `-1 >= 0` is false and `-1 == -2` is false — so an
  unlimited torrent is **never** movable by the ratio rule.
- The `0.001f` slack is what makes "reached after rounding" work; the fixture pins ratio
  `1.1006066990976857` against limit `1.0` as reached, and `0.9999` as reached too
  (Sonarr `QBittorrentFixture.cs:715-737`, Radarr `:714-736`).

`HasReachedSeedingTimeLimit` (`:655-717`):

```csharp
if (torrent.SeedingTimeLimit >= 0)        { seedingTimeLimit = torrent.SeedingTimeLimit * 60; }        // minutes -> seconds
else if (torrent.SeedingTimeLimit == -2 && config.MaxSeedingTimeEnabled) { seedingTimeLimit = config.MaxSeedingTime * 60; }
else                                      { return false; }
```

then it uses `torrent.SeedingTime` if the list API supplied it (`:672-676`), otherwise it consults a
5-minute cache and, on a miss, calls **`torrents/properties`** for `seeding_time`
(`:678-716`, `:739-744`). `HasReachedInactiveSeedingTimeLimit` (`:719-737`) is the same shape but
compares `now - last_activity` against `inactive_seeding_time_limit` (or the global) and never needs
a second call.

### 3.3 What `CanMoveFiles` decides

`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, series, importItem)`
(`CompletedDownloadService.cs:148-151`), and then two places read `CanMoveFiles`:

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

(Radarr: `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, identical.)

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
`TransferMode.HardLinkOrCopy` if "Use Hardlinks instead of Copy" is on, else `TransferMode.Copy`
(`:103`, `:107`). `TransferMode` is `[Flags] None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy=Copy|HardLink`
(`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`).

**A failed Move never falls back to a Copy.** The full argument, with line numbers, is in
[sabnzbd-client-contract.md §5.5](sabnzbd-client-contract.md); `DiskTransferService.cs` is shared and
byte-identical between the two repos. The short form: `TransferFile`'s Move branch
(`src/NzbDrone.Common/Disk/DiskTransferService.cs:360-389`) has exactly one copy path, chosen up front
from `targetMount.DriveFormat == "cifs"` (`:342`, `:378-385`), never as a reaction to a failure;
`TryMoveFileVerified` rethrows (`:487-503`), and `VerifyFile` throws
`IOException("File move incomplete, data loss may have occurred. …")` when the destination size
disagrees with the source (`:505-524`).

### 3.4 With qBittorrent's own defaults, the import is a **copy**

Take a torrent a shim reports naively — the qBittorrent defaults, which are also the model defaults:

| Field | Value | Effect |
|---|---|---|
| `state` | `stoppedUP` | conjunct 2 ✓ |
| `ratio_limit` | `-2` (default, `QBittorrentTorrent.cs:33`) | falls to the global branch |
| `max_ratio_enabled` | `false` (qBittorrent's own default; wiki example body `:684`) | global branch fails |
| `seeding_time_limit` | `-2` | needs `max_seeding_time_enabled` |
| `max_seeding_time_enabled` | `false` (wiki `:686`) | fails |
| `inactive_seeding_time_limit` | `-2` | needs `max_inactive_seeding_time_enabled` |
| `max_inactive_seeding_time_enabled` | `false` | fails |

⇒ `HasReachedSeedLimit` false ⇒ `CanMoveFiles` false ⇒ `copyOnly` true ⇒ `TransferMode.Copy` ⇒ **the
\*arr reads every byte of the release off the mount and writes it back.** On a debrid mount that is
the one outcome the whole design exists to avoid, and it fails silently — nothing warns, the import
just takes hours and fills a disk.

The fixture pins this exact case:
`should_not_be_removable_and_should_not_allow_move_files_if_max_ratio_is_not_set`
(Sonarr `QBittorrentFixture.cs:691-701`, Radarr `:690-700`) — global limits off, torrent paused,
ratio 1.0, `CanMoveFiles == false`.

### 3.5 The recipe

For every torrent a shim wants imported by **move**:

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

`ratio_limit: 0` takes the first branch (`0 >= 0`, and `0 - 0 <= 0.001`) and the global preferences
are never consulted, so `max_ratio_enabled` can stay `false` and the
`DownloadClientRemovesCompletedDownloadsCheck` health check stays quiet. Any `ratio_limit >= ratio`
within `0.001` works; `0`/`0` is the one that needs no coordination.

On `pausedUP` vs `stoppedUP`: **develop treats them identically** — both in the `CanMoveFiles` gate
(`:244`) and in the status map (`:266-267`) — and every seed-limit fixture is a `[TestCase]` pair over
both. `stoppedUP` is qBittorrent 5's spelling (`serialize_torrent.cpp:54-55`; `pausedUP` no longer
exists in master). `pausedUP` is the safer choice against *released* \*arr builds, since the
`stoppedUP` arm was added when qBittorrent 5 landed and older Sonarr v4 / Radarr v5 builds only know
`pausedUP` — that last point is an inference about older tags, not something the develop sources
above prove.

And the thing that is not in the shim's hands: **"Remove Completed" must stay on in the \*arr's
download-client settings.** It is on by default (`DownloadClientDefinition.cs:17`). Document it, because
turning it off silently converts every import into a full download.

---

## 4. `OutputPath` — where the \*arr is told to import from

### 4.1 The 2.6.1+ path: `content_path`

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

The warning text (`src/NzbDrone.Core/Localization/Core/en.json`):

> Unable to Import. Path matches client base download directory, it's possible 'Keep top-level folder'
> is disabled for this torrent or 'Torrent Content Layout' is NOT set to 'Original' or 'Create Subfolder'?

Rules a shim must satisfy:

- `content_path` **must not equal** `save_path`. Equality is the failure, not a fallback: the item
  becomes a Warning and never imports.
- `content_path` must be **absolute and valid for the OS the \*arr runs on**. `CompletedDownloadService.ValidatePath`
  (`CompletedDownloadService.cs:295-313`) rejects it otherwise with
  "[{0}] is not a valid local path. You may need a Remote Path Mapping."
- It must exist on the \*arr host as a **folder or a file**; `ProcessPath`
  (`DownloadedEpisodesImportService.cs:80-105`) branches on `FolderExists` then `FileExists`, and
  falls through to `LogInaccessiblePathError` + an empty result if neither.
- Do not send an empty `content_path`. It "differs" from a non-empty `save_path`, so `OutputPath`
  is set to an empty `OsPath`, and `GetImportItem` then falls through to the `torrents/files` walk
  (§4.2) because `item.OutputPath.IsEmpty` is true (`:341-344`).
- This block only runs for **Completed** items, so `content_path` is only load-bearing once the state
  is one of §2's Completed set.

What real qBittorrent puts there — `TorrentImpl::contentPath()`
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

with `rootPath()` = `actualStorageLocation() / Path::findRootFolder(filePaths())` (`:565-575`). So:
a **single-file** torrent's `content_path` is the file itself; a multi-file torrent with a common root
folder gets that folder; a multi-file torrent **without** a common root gets `save_path` — which is
exactly the case the client's `content_path == save_path` warning is about.

`RemapRemoteToLocal(Settings.Host, …)` applies the user's Remote Path Mappings, keyed on the
configured **Host** string. If the \*arr runs in a container and the shim reports the host's path,
the operator needs a mapping; see [sabnzbd.md\](../guides/sonarr-radarr.md#remote-path-mapping), which applies
unchanged.

### 4.2 The pre-2.6.1 path: `GetImportItem` walks `torrents/files`

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

It takes **`files[0].name` only**, walks up to its topmost path component, and joins that onto
`properties.save_path`. The fixture pins all three shapes (Sonarr `QBittorrentFixture.cs:317-421`,
Radarr `:296-400`):

| `files[0].name` | `save_path` | `OutputPath` |
|---|---|---|
| `Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` |
| `Folder/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Folder` |
| `Droned.S01.12/E01.mkv` (+ `E02.mkv`) | `/Torrents` | `/Torrents/Droned.S01.12` |

Note the third row: it is `files[0]`'s root, not a computed common root, so **a shim on this path must
list the files in an order whose first entry carries the release folder**. A shim reporting webapi
`>= 2.6.1` never reaches here, which is one more reason to report `2.11.2`.

`previousImportAttempt` is a parameter of `GetImportItem` (`:338`) and **is never read** by this
implementation. Nothing about a failed attempt is remembered.

### 4.3 When the path is wrong, and how often it is retried

There is no backoff and no attempt limit anywhere in this path.

- `CompletedDownloadService.Check` runs for every tracked download in state `Downloading` or
  `ImportBlocked`, on every refresh
  (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:125-129`).
- `Check` calls `SetImportItem` **first** (`CompletedDownloadService.cs:73`), which is
  `_provideImportItemService.ProvideImportItem(...)` → `client.GetImportItem(...)`
  (`:290-293`, `src/NzbDrone.Core/Download/ProvideImportItemService.cs:17-22`). So `OutputPath` is
  re-derived from the *current* `torrents/info` row on every poll.
- `ValidatePath` failures (`:295-313`) produce a Warning and leave the state at `Downloading`, so the
  next poll tries again from scratch:
  - empty output path → "Download doesn't contain intermediate path, Skipping."
  - wrong-OS path → "[{0}] is not a valid local path. You may need a Remote Path Mapping. …"
- `Import` also calls `SetImportItem` on entry (`:130`) before re-reading
  `trackedDownload.ImportItem.OutputPath.FullPath` (`:147`), and is driven from state `ImportPending`
  by `DownloadProcessingService`
  (`src/NzbDrone.Core/Download/DownloadProcessingService.cs:61-63`). A failed import leaves the state
  at `ImportPending` (`:158`) or moves it to `ImportBlocked` (`:196`) — both are re-processed.
- A path that exists but yields nothing importable gives
  "No files found are eligible for import in {0}" (`:162`) and stays `ImportPending`.

**Consequence for a shim: `content_path` is allowed to be wrong for a while.** Report the torrent as
Downloading (or Queued) until the folder actually exists and its file sizes are final, and the client
will simply keep polling. Reporting Completed too early costs an import attempt against a folder that
is not ready — and, worse, the \*arr may move a partially-sized file and then fail `VerifyFile`,
having already emptied the source. That is the same trap documented for the SAB endpoint
([sabnzbd.md\](../guides/sonarr-radarr.md), *What happens on a grab*, step 5).

---

## 5. The post-import sequence

### 5.1 What fires, in order

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

and `RemoveFromDownloadClient` (`:87-103`) is:

```csharp
_logger.Debug("[{0}] Removing download from {1} history", ...);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);             // :92  deleteData: TRUE
trackedDownload.DownloadItem.Removed = true;
```

So the wire sequence after a successful import is:

1. **`POST /api/v2/torrents/setCategory`** — only if a post-import category is configured
   (`QBittorrent.cs:52-69`). Skipped by default.
2. Before either of those, and outside the download client entirely: **the \*arr moves the file**, then
   `ProcessFolder` may **delete the source folder itself**
   (`DownloadedEpisodesImportService.cs:209-223`, Radarr `DownloadedMovieImportService.cs:226-240`):

   ```csharp
   if (importMode == ImportMode.Move &&
       importResults.Any(i => i.Result == ImportResultType.Imported) &&
       ShouldDeleteFolder(directoryInfo, series))
   {
       _diskProvider.DeleteFolder(directoryInfo.FullName, true);   // recursive
   }
   ```

   `ShouldDeleteFolder` (`:108-153`) refuses when any video file left in the folder parses and is not
   a sample (`:117-133`), or when a `.rar` larger than 10 MB remains (`:135-139`). After a successful
   single-file move, neither applies, so the folder **is** removed. An `IOException` is caught and
   logged at Debug (`:219-222`).
3. **`POST /api/v2/torrents/delete`** with `hashes=<lowercase hash>&deleteFiles=true`
   (`QBittorrent.cs:335`, `QBittorrentProxyV2.cs:190-202`).

Two other events reach the same `RemoveFromDownloadClient(…, true)`:

- `DownloadFailedEvent` (`DownloadEventHub.cs:26-46`), gated on the per-client
  `RemoveFailedDownloads` (default `true`, `DownloadClientDefinition.cs:18`). Note
  `TrackedDownload.Fail()` sets `DownloadItem.CanBeRemoved = true` unconditionally
  (`src/NzbDrone.Core/Download/TrackedDownloads/TrackedDownload.cs:39-46`, comment: "Set CanBeRemoved
  to allow the failed item to be removed from the client") — **so a failed download is deleted even
  when the seed-limit gate says otherwise.**
- `DownloadCanBeRemovedEvent` (`:71-85`).

`NotSupportedException` out of `RemoveItem` is downgraded to
"Removing item not supported by your download client ({0})." (`:95-98`); any other exception is logged
as an error and the item is *not* marked Removed, so it will be retried next poll (`:99-102`).

### 5.2 What the shim must do with `deleteFiles=true`

This is the same decision `internal/sabnzbd` already made for `mode=history&name=delete`, for the same
reason. From `internal/sabnzbd/api.go:596-609`:

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

The qBittorrent case is the same shape with one wrinkle: on this API the data delete is the *client's*
job, not the \*arr's, because `RemoveItem` does **not** call `DeleteItemData` (§1.15). But the \*arr
has already deleted the folder itself in step 2 above — through the mount, which under `__magic__`
writes a tombstone: the entry disappears from `__magic__` and stays exactly where it was in `__all__`,
in every filter directory, and on the debrid account
([magic.md\](../guides/magic.md#deleting-hides-it-does-not-destroy)).

So:

- **`torrents/delete` drops the torrent *record* the shim keeps for the \*arr.** Answer 200.
- **`deleteFiles` must not delete the provider torrent.** The release the \*arr just imported is still
  served out of it; deleting it destroys the thing that was imported. The one place a real delete
  would be honest is a torrent nothing ever imported from — the failed-download path — and even there
  a debrid torrent is shared library state, not a scratch download, so the safe default is: **never
  delete the provider torrent, tombstone only.** Say so in the user-facing doc, the way
  [sabnzbd.md\](../guides/sonarr-radarr.md) does under *What works, and what does not*.
- A `torrents/delete` for an **unknown hash** should still answer 200. Real qBittorrent does (wiki,
  *Delete torrents*: "200 | All scenarios"), and an error here is logged as an error and retried
  every poll for ever.

### 5.3 `MarkItemAsImported` and the post-import category

`QBittorrent.cs:52-69` sets the post-import category when `TvImportedCategory` /
`MovieImportedCategory` is configured and different from the main category. It is called for **every**
completed import (`DownloadEventHub.cs:54`), before the removal decision.

If a shim honours `setCategory` by actually moving the torrent out of the polled category, the torrent
vanishes from the next `torrents/info?category=…` — which is what the setting is *for*, and what the
UI surfaces as `DownloadClientHasPostImportCategory`
(`src/NzbDrone.Core/Queue/QueueService.cs:84`, sourced from
`DownloadClientItemClientInfo.HasPostImportCategory`, `QBittorrent.cs:234`). Accepting the call and
recording the new category is the correct behaviour; refusing it produces only a warning
(`:62-67`).

---

## 6. `Test()` — every check, in order, and its message

`DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`) wraps the
whole thing: **any exception that escapes becomes**
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

Each branch **returns**, so at most one failure comes out of this method.

| Order | Condition | Property | Message |
|---|---|---|---|
| 1 | `_proxySelector.GetProxy(Settings, force: true).GetApiVersion(Settings)` — forces re-detection (`:435`) | | |
| 2 | version `< 1.5` (`:436`) | `Host` | "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| 3 | version `< 1.6` **and** category set (`:445-455`) | `Category` | "Category is not supported" / detail "Categories are not supported until qBittorrent version 3.3.0. Please upgrade or try again with an empty Category." |
| 4 | version `>= 1.6` **and** category blank (`:456-464`) | `TvCategory` / `MovieCategory` | **Warning** — "Category is recommended" / "{appName} will not attempt to import completed downloads without a category." |
| 5 | `GetConfig` then `RemovesCompletedDownloads(config)` (`:467-474`) | `""` | "qBittorrent is configured to remove torrents when they reach their Share Ratio Limit" / detail naming Options → BitTorrent → Share Ratio Limiting |

Exception mapping (`:476-506`):

| Caught | Property | Message |
|---|---|---|
| `DownloadClientAuthenticationException` | `ApiKey` if an api key is set, else `Username` | "Authentication Failure" / "Please verify your credentials. Also verify if the host running {appName} isn't blocked from accessing {clientName} by WhiteList limitations…" |
| `WebException` with `Status == ConnectFailure` | `Host` | "Unable to connect to qBittorrent" / "Please verify the hostname and port." |
| any other `WebException` | `""` | "Unknown exception: {message}" |
| any other `Exception` | `Host` | "Unable to connect to qBittorrent", `DetailedDescription = ex.Message` |

Note case 4 is a **warning**, and `failures.HasErrors()` at `:421` is false for warnings — so a
category-less setup still runs the remaining three checks.

### 6.2 `TestCategory` (`:511-556`) — the "category does not exist" flow

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

Failure: property `TvCategory` / `MovieCategory` (or `TvImportedCategory` / `MovieImportedCategory`),
message "Configuration of category failed", detail "{appName} was unable to add the label to
qBittorrent."

So a shim has a choice: either ship the configured categories up front so `torrents/categories`
already contains them, or accept `createCategory` and reflect it in the very next
`torrents/categories` response. **There is no third option** — the client re-reads and fails if the
key is still missing. Category names are matched **exactly**, case-sensitively
(`Dictionary<string, …>.ContainsKey` with the default ordinal comparer).

Note the `TvImportedCategory` handling: the post-import category is checked and created here too, even
though it is only used after an import. If the operator sets it, it must exist.

`QBittorrentSettingsValidator` (`QBittorrentSettings.cs:23-24`) already refuses category names
matching `^([^\\\/](\/?[^\\\/])*)?$` — no backslash, no `//`, no leading or trailing `/` — before any
request is made.

### 6.3 `TestPrioritySupport` (`:558-597`) — the `queueing` health check

```csharp
var recentPriorityDefault = Settings.RecentTvPriority == (int)QBittorrentPriority.Last;
var olderPriorityDefault  = Settings.OlderTvPriority  == (int)QBittorrentPriority.Last;
if (olderPriorityDefault && recentPriorityDefault) { return null; }   // :563-566  the default: nothing checked

var config = Proxy.GetConfig(Settings);
if (!config.QueueingEnabled) { … }                                    // :572-588
```

Failure property is `nameof(Settings.RecentTvPriority)` or `nameof(Settings.OlderTvPriority)`
(checked in that order), message "Queueing Not Enabled", detail "Torrent Queueing is not enabled in
your qBittorrent settings. Enable it in qBittorrent or select 'Last' as priority."

An exception here becomes `("", "Unknown exception: {message}")` (`:590-594`).

`queueing_enabled` defaults to **`true`** in the model (`QBittorrentPreferences.cs:41`), so a shim
that omits the key passes — but omitting it is a lie if `topPrio` is a no-op. Reporting
`queueing_enabled: false` is honest and produces this failure **only** if the operator changed the
priority setting away from `Last`.

### 6.4 `TestGetTorrents` (`:599-612`)

`Proxy.GetTorrents(Settings)`; any exception becomes `("", "Failed to get the list of torrents:
{exceptionMessage}")`. This is the check that catches a malformed `torrents/info` body — a JSON object
instead of an array, a bad enum, a non-numeric `size`.

### 6.5 The `dht` check

There is **no** dedicated DHT check in `Test()`. `dht` is consulted at grab time
(`:73-76`, magnets without trackers) and at poll time (`:288`, the `metaDL` branch). A shim reporting
`dht: false` passes the connection test and then refuses every trackerless magnet with
`ReleaseDownloadException("Magnet not supported by download client. …")`
(`TorrentClientBase.cs:115`). **Report `dht: true`.**

---

## 7. Parsing and import consequences a shim should know

### 7.1 `name` becomes `Title`, and `Title` is used for three different things

`DownloadClientItem.Title = torrent.Name` (`QBittorrent.cs:232`). Downstream:

1. **Series/movie identification.** `CompletedDownloadService.Check` does
   `_parsingService.GetSeries(trackedDownload.DownloadItem.Title)`
   (`CompletedDownloadService.cs:95`). If that returns null it falls back to the **grab history**
   keyed on `DownloadId` (`:99-102`) — and if that is also missing:
   "Series title mismatch; automatic import is not possible." + `ImportBlocked` (`:104-110`).
   Radarr's equivalent lives in `ProcessFolder`, which reads
   `_historyService.FindByDownloadId(downloadClientItem?.DownloadId ?? "")`
   (`DownloadedMovieImportService.cs:193-194`).
   **This is the second reason the shim must key on the exact infohash the \*arr computed**
   (§1.7): the history fallback is `DownloadId`-keyed, so a mismatched hash loses both the title path
   and the fallback.
2. **Release parsing for the import decision.**
   `downloadClientItemInfo = Parser.Parser.ParseTitle(downloadClientItem.Title)`
   (Sonarr `ImportDecisionMaker.cs:80`; Radarr `ParseMovieTitle`, `:80`), assigned to
   `LocalEpisode.DownloadClientEpisodeInfo` / `LocalMovie.DownloadClientMovieInfo` (`:94` / `:92`).
3. **Log lines and the queue UI.**

**Sonarr's title-fallback gate.** `AggregateEpisodes.GetBestEpisodeInfo`
(`src/NzbDrone.Core/MediaFiles/EpisodeImport/Aggregation/Aggregators/AggregateEpisodes.cs:29-57`):

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

Three gates on using the download-client title instead of the filename: `!OtherVideoFiles`,
the filename is not itself a scene title, and the client title is not a full-season parse. So the
torrent name only rescues a single-file, non-scene-named release.

Radarr has **no equivalent single-winner gate**. `LocalMovie.OtherVideoFiles` exists
(`src/NzbDrone.Core/Parser/Model/LocalMovie.cs:36`) but the movie's parsed info is merged by a
confidence-ranked augmenter chain rather than chosen (`AggregateQuality.cs:25-121`); the download-client
title feeds those augmenters, and movie identity comes from the folder parse plus grab history
(`DownloadedMovieImportService.cs:192-195`).

**`OtherVideoFiles`** (`ImportDecisionMaker.cs:85`, `:100`, Radarr `:83`, `:98`):

```csharp
var nonSampleVideoFileCount = sceneSource ? GetNonSampleVideoFileCount(newFiles, series, downloadClientItemInfo, folderInfo) : videoFiles.Count;
…
OtherVideoFiles = nonSampleVideoFileCount > 1
```

`ProcessFolder` always passes `sceneSource: true` (`DownloadedEpisodesImportService.cs:201`), so a
folder with two or more non-sample videos sets `OtherVideoFiles` and the download-client title is out
of the running for every file in it.

**Why this matters on zurg.** Real-Debrid rewrites release names that trip its filename block —
`WEB-DL`, `WEBRip`, `BDRip`, `HDRip`, `DVDRip`, and a source tag dot-adjacent to an old codec — and
zurg appends a suffix when two releases collide on a name. Either can make `torrent.name` stop
parsing as the grabbed release. See the RD 451 section of the monorepo `CLAUDE.md`. The
consequences, in order: identification falls back to grab history (still fine, if the hash matches);
Sonarr's per-file parse takes over (fine for a well-named file inside the folder); and the folder name
under `__magic__` — which is what `Parser.ParseTitle(directoryInfo.Name)` reads at
`DownloadedEpisodesImportService.cs:184` — becomes the other thing that has to stay parseable.

### 7.2 The import folder scan drops whole subtrees

`DiskScanService.FilterPaths` (`src/NzbDrone.Core/MediaFiles/DiskScanService.cs:232-246`), applied to
the download folder at `DownloadedEpisodesImportService.cs:185` (Radarr
`DownloadedMovieImportService.cs:202`) with `filterExtras: true`:

```csharp
private static readonly Regex ExcludedExtrasSubFolderRegex = new Regex(@"(?:\\|\/|^)(?:extras|extrafanart|behind the scenes|deleted scenes|featurettes|interviews|other|scenes|samples|shorts|trailers)(?:\\|\/)", …IgnoreCase);   // :72
private static readonly Regex ExcludedSubFoldersRegex      = new Regex(@"(?:\\|\/|^)(?:@eadir|\.@__thumb|plex versions|\.[^\\/]+)(?:\\|\/)", …IgnoreCase);   // :73
private static readonly Regex ExcludedExtraFilesRegex      = new Regex(@"(-(trailer|other|behindthescenes|deleted|featurette|interview|scene|short)\.[^.]+$)", …IgnoreCase);   // :74
private static readonly Regex ExcludedFilesRegex           = new Regex(@"^\.(_|unmanic|DS_Store$)|^Thumbs\.db$", …IgnoreCase);   // :75
```

**Radarr's extras regex differs by one alternative**: `sample[s]?` instead of `samples`
(Radarr `DiskScanService.cs:72`), so Radarr also drops a `sample/` folder where Sonarr only drops
`samples/`. Everything else in the four regexes is identical between the repos.

Note `ExcludedSubFoldersRegex`'s `\.[^\\/]+` alternative: **any dot-prefixed directory component is
dropped**, at any depth. And the match is against `basePath.GetRelativePath(path)`, so it is scoped to
below the import folder — a dot in an ancestor of the mount is harmless.

Only files whose extension is in `MediaFileExtensions.Extensions` reach the filter in the first place
(`DiskScanService.GetVideoFiles`, `:202-215`).

### 7.3 Sample detection reads the file

`GetNonSampleVideoFileCount` (`ImportDecisionMaker.cs:216-234`) calls `_detectSample.IsSample(...)`
for **every** video file in the folder. `DetectSample.IsSample`
(`src/NzbDrone.Core/MediaFiles/EpisodeImport/DetectSample.cs:27-45`) short-circuits only for
specials, `.flv` and `.strm` (`:78-101`); otherwise it calls
`_videoFileInfoReader.GetRunTime(path)` — **ffprobe, on the file, through the mount** — and compares
against a minimum derived from the expected runtime (`:103-121`). A runtime of exactly 0 is treated as
a **sample** (`:107-111`), and a missing runtime logs "Failed to get runtime from the file, make sure
ffprobe is available" and returns Indeterminate (`:38-42`).

`ShouldDeleteFolder` (`DownloadedEpisodesImportService.cs:117-133`) runs the same check again over
whatever is left after the move.

So an import of an N-file release costs at least N ffprobe opens against the debrid backend before
anything is moved. That is a real cost on a zurg mount, and it is unavoidable from the client side.

### 7.4 The refusals in `ProcessFolder` / `ProcessFile`

| Condition | Result | Line (Sonarr) |
|---|---|---|
| the import path is a series/movie folder | `ImportRejectionReason.SeriesFolder` — "Import path is mapped to a series folder" (Radarr: `MovieFolder`, "…a movie folder") | `:175-182` (Radarr `:183-190`) |
| folder name does not resolve to a known series/movie | `UnknownSeriesResult("Unknown Series")` | `:160-168` |
| filename starts with `._` | `InvalidFilePath` | `:251-259` |
| extension in `FileExtensions.DangerousExtensions` | `DangerousFile` | `:263-271` |
| extension in `FileExtensions.ExecutableExtensions` | `ExecutableFile` | `:273-281` |
| extension not in `MediaFileExtensions.Extensions` | `UnsupportedExtension` | `:283-293` |

**`SeriesPathExists` / `MoviePathExists` is the one that bites a `__magic__` layout.** If the \*arr's
root folder is `/mnt/zurg/__magic__/tv` and a series folder is
`/mnt/zurg/__magic__/tv/The Show`, then an import path that happens to *be* a series folder is
refused outright. It is why the download folder (`content_path`) must be a sibling of the root
folders, not inside one — which is the arrangement [sabnzbd.md\](../guides/sonarr-radarr.md) already prescribes:
`save_path` = `/mnt/zurg/__magic__`, root folders `/mnt/zurg/__magic__/tv` and
`/mnt/zurg/__magic__/movies`, releases at `/mnt/zurg/__magic__/<release>`.

`_UNPACK_` and `_FAILED_` are stripped from the folder name before parsing
(`GetCleanedUpFolderName`, `:311-317`).

`IsFileLocked` is **skipped entirely when a download client item is present** (`:187-199`, `:295-304`)
— the lock probe only runs for manual/root-folder scans. A shim never has to worry about it.

---

## 8. The health checks

All three are shared with the SAB client and analysed in
[sabnzbd-client-contract.md §6](sabnzbd-client-contract.md). What is qBittorrent-specific:

- **`RemotePathMappingCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs:59-173`)
  walks `client.GetStatus().OutputRootFolders` — for qBittorrent that is the single folder computed at
  `QBittorrent.cs:377-407`: the global `save_path`, overridden or extended by the configured
  category's `savePath` (§1.5). It must be a valid path **for the OS the \*arr runs on** (`:68-113`)
  and it must **exist on the \*arr host** (`:115-158`). It does not need to be writable.
  `IsLocalhost` is `Settings.Host == "127.0.0.1" || Settings.Host == "localhost"` (`:406`) and only
  changes which of three error messages is produced.
- **`DownloadClientRemovesCompletedDownloadsCheck`**
  (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:33-66`) warns whenever
  `GetStatus().RemovesCompletedDownloads` is true — i.e. whenever §1.4's derived flag is true. Keep
  `max_ratio_enabled` and `max_seeding_time_enabled` false (which §3.5's recipe already does) and it
  stays quiet.
- **`DownloadClientRootFolderCheck`** is the one place the two repos genuinely differ — Sonarr warns
  only when a root folder *equals* an output folder, Radarr also when a root folder *contains* one.
  Full analysis in [sabnzbd-client-contract.md §6.1](sabnzbd-client-contract.md); the practical rule is
  the same here: do not put a root folder at or above `/mnt/zurg/__magic__`.

---

## 9. Sonarr vs Radarr — the complete diff

Verified by diffing the fetched files pairwise (BOM and CRLF normalised).

| File | Difference |
|---|---|
| `QBittorrent.cs` | `TvCategory`→`MovieCategory`, `TvImportedCategory`→`MovieImportedCategory`, `RecentTvPriority`→`RecentMoviePriority`, `OlderTvPriority`→`OlderMoviePriority`, `RemoteEpisode`→`RemoteMovie`; `remoteEpisode.IsRecentEpisode()` → `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` (`:80`, `:137`). **Line numbers match one-for-one.** |
| `QBittorrentSettings.cs` | the same renames; default category `"tv-sonarr"` → `"radarr"` (`:36`); help-text token `…EpisodeHelpText` → `…MovieHelpText`. Line numbers match. |
| `QBittorrentProxyV2.cs` | the category rename; `new[] { HttpStatusCode.Forbidden }` → `[HttpStatusCode.Forbidden]` (collection expression, Sonarr `:401` / Radarr `:400`); Sonarr has an extra blank line at 13 → **Sonarr N = Radarr N−1 for N ≥ 14**. |
| `QBittorrentProxyV1.cs` | the category rename; same blank-line offset. |
| `QBittorrentProxySelector.cs` | a stray double space in Sonarr's constructor (`:46`); blank line at 3 → Sonarr N = Radarr N−1 for N ≥ 4. |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **byte-identical.** |
| `TorrentClientBase.cs` | `RemoteEpisode`→`RemoteMovie` throughout; Radarr also treats HTTP **410 Gone** like 404 when fetching a `.torrent` (`:175`), Sonarr only 404. Both 274 lines. |
| `QBittorrentFixture.cs` | same tests, reordered: `missingFiles_item_should_have_required_properties` sits at Sonarr `:296-315` and Radarr `:402-420`, and **Radarr's copy carries no `[Test]` attribute** (`:401` is blank), so it never runs there. Sonarr `:318-421` = Radarr `:297-400`; from Sonarr `:423` on, Radarr = Sonarr − 1. Sonarr 1000 lines, Radarr 998. |
| `DiskScanService.cs` | `ExcludedExtrasSubFolderRegex` — Radarr has `sample[s]?`, Sonarr `samples` (`:72` in both). The other three regexes are identical. |
| import services | `Series`/`Episode` vs `Movie`; Sonarr's `AggregateEpisodes` title-preference gate has no Radarr counterpart (§7.1). Both refuse an import path that is a library folder before doing anything else (Sonarr `:175-182`, Radarr `:183-190`) and parse the folder name after (Sonarr `:184`, Radarr `:195`); Radarr additionally looks up grab history by `DownloadId` there (`:193-194`). |
| `ImportApprovedEpisodes.cs` / `ImportApprovedMovie.cs` | `copyOnly` switch identical, Sonarr `:139-152` / Radarr `:116-129`. |
| `DiskTransferService.cs`, `DownloadClientBase.cs`, `DownloadEventHub.cs`, `Json.cs`, `HttpClient.cs`, `HttpRequestBuilder.cs` | shared, byte-identical. |

Everything else in this document is **byte-identical modulo Series/Movie** and applies to both at the
same line.

---

## 10. Minimal-but-complete example payloads

### 10.1 `GET /api/v2/app/webapiVersion`

```
2.11.2
```

`Content-Type: text/plain`. Not JSON, no quotes, no trailing newline needed.

### 10.2 `POST /api/v2/auth/login`

Request body: `username=sonarr&password=hunter2`, `application/x-www-form-urlencoded`.

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8
Set-Cookie: SID=8f3c1c0e9a1f4d2f9c0b7a5e3d1f6b2a; path=/

Ok.
```

Bad credentials: still **200**, body `Fails.` — never a 401.

### 10.3 `GET /api/v2/app/preferences`

Only the ten keys of §1.4 are read; send more if you like, they are ignored.

```json
{
  "save_path": "/mnt/zurg/__magic__",
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

Hard requirements:

- `save_path` must exist as a directory **on the Sonarr/Radarr host** (`RemotePathMappingCheck`, §8).
- `max_ratio_enabled: false` + `max_seeding_time_enabled: false` keeps
  `RemovesCompletedDownloads` false, which keeps both the connection test (§6.1 case 5) and the
  health check quiet.
- `dht: true`, or trackerless magnets are refused client-side (§6.5).
- `max_ratio_act` is an **integer** (§0.6).

### 10.4 `GET /api/v2/torrents/categories`

```json
{
  "tv": { "name": "tv", "savePath": "" },
  "movies": { "name": "movies", "savePath": "" }
}
```

A JSON **object**, `savePath` in **camelCase**, never starting with `//` (§1.5). An empty `savePath`
leaves the output root folder at the global `save_path`.

### 10.5 `GET /api/v2/torrents/info?category=tv` — one downloading, one importable

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
    "save_path": "/mnt/zurg/__magic__",
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
    "save_path": "/mnt/zurg/__magic__",
    "content_path": "/mnt/zurg/__magic__/Some.Show.S01E03.1080p.WEB.h264-GRP",
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

Hard requirements:

- A JSON **array** (`List<QBittorrentTorrent>`); an object throws inside `GetTorrents` and fails
  `TestGetTorrents` (§6.4).
- `hash` **lowercase** (§1.8) and exactly the infohash the \*arr computed from the magnet or
  `.torrent` (§1.7).
- `size` in **bytes**; `progress` a fraction 0..1. `RemainingSize = size × (1 − progress)`.
- `eta: 8640000` reads as "unknown" and yields a null `RemainingTime` (`:622-625`); a Completed item
  gets `TimeSpan.Zero` regardless (`:273`).
- `state` from §2's table, exact case.
- `content_path` **absolute, existing, and ≠ `save_path`** on Completed items (§4.1). It may be empty
  while the item is not Completed.
- `ratio_limit: 0` + `ratio: 0` is the move recipe (§3.5).
- `category` must match the client's configured category; the client does not re-filter, so honour the
  query parameter.
- `seeding_time` may be omitted entirely — the client falls back to `torrents/properties`, and only
  when a seeding-time limit is actually in force.

### 10.6 `GET /api/v2/torrents/properties?hash=<hash>`

```json
{
  "hash": "3b1a1469c180f447b77021074dbbccaef62611e7",
  "save_path": "/mnt/zurg/__magic__",
  "seeding_time": 0,
  "total_size": 1073741824,
  "addition_date": 1756252200,
  "completion_date": 1756252800,
  "eta": 8640000,
  "dl_limit": -1,
  "up_limit": -1
}
```

Only `save_path` and `seeding_time` are read (§1.8). **404 for an unknown hash** — that is how
`IsTorrentLoaded` says "not there yet" (`:110-126`).

### 10.7 `GET /api/v2/torrents/files?hash=<hash>`

```json
[
  { "index": 0, "name": "Some.Show.S01E03.1080p.WEB.h264-GRP/ep3.mkv", "size": 1073741824, "progress": 1, "priority": 1, "is_seed": true, "piece_range": [0, 2047], "availability": 1 }
]
```

Only `name` is read, relative to `save_path`, with `/` separators (§1.13). Order matters on the
pre-2.6.1 path: `files[0]`'s topmost component becomes the output folder.

### 10.8 `POST /api/v2/torrents/add`

Request, urlencoded form (a long magnet arrives as multipart instead — §0.3):

```
urls=magnet%3A%3Fxt%3Durn%3Abtih%3A3B1A...&category=tv&stopped=False
```

Response:

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8

Ok.
```

Anything except the literal `Fails.` is success (§1.7). An empty 200 body also works.

### 10.9 `POST /api/v2/torrents/delete`

Request: `hashes=3b1a1469c180f447b77021074dbbccaef62611e7&deleteFiles=true`

Response: `HTTP/1.1 200 OK`, empty body. **200 for an unknown hash too** (§5.2).

### 10.10 `POST /api/v2/torrents/createCategory`, `setCategory`, `setShareLimits`, `topPrio`, `setForceStart`

All take urlencoded forms and all answer `200` with an empty body. `topPrio` may answer **409** to
mean "queueing is disabled" — the client swallows exactly that status (§1.10). `setShareLimits` may
answer **404** to mean "not supported" — also swallowed (§1.9).

---

## 11. Differences from real qBittorrent — where zurg's model is narrower or wider

### 11.1 There is no seeding, so the seed-limit gate has to be faked

Real qBittorrent computes `ratio` from bytes actually uploaded and lets the user set a global or
per-torrent limit; the client's `CanMoveFiles` gate exists to avoid yanking files out from under a
torrent that is still fulfilling a ratio obligation (`QBittorrent.cs:240-241`). A debrid backend
uploads nothing, ever. So the shim declares `ratio: 0, ratio_limit: 0` — a per-torrent limit already
met — which is truthful in the only sense the field can be truthful here, and which keeps the global
preferences out of it entirely (§3.5).

### 11.2 `content_path` is always a folder, never a file

Real qBittorrent's `contentPath()` returns the **file path** for a single-file torrent
(`torrentimpl.cpp:582-583`). Under `__magic__` every release is a folder holding its files
([magic.md\](../guides/magic.md#with-nothing-stored-it-is-__all__)), including a single-file release.

Consequences, all in the client's favour:

- `ProcessPath` always takes the **folder** branch (`DownloadedEpisodesImportService.cs:80-90`),
  never the file branch (`:92-102`). The folder branch is the one that applies `FilterPaths`,
  `ShouldDeleteFolder`, and the folder-name parse — so the extras filter and the folder-title
  fallback are always live.
- `ProcessFile`'s per-file refusals (dangerous/executable/unsupported extension, `._` prefix; §7.4)
  are still reachable, but via `GetVideoFiles`' extension filter rather than the top-level branch.
- The pre-2.6.1 `GetImportItem` walk (§4.2) would also work, since `files[0].name` always carries the
  release folder — but there is no reason to report a version that old.

The one thing to get right: because it is always a folder, `content_path` is always
`save_path + "/" + <release folder>` and therefore never equal to `save_path`. The
`DownloadClientQbittorrentTorrentStatePathError` warning (§4.1) is structurally unreachable, which is
the correct outcome, not an accident to rely on.

### 11.3 `name` is not the grabbed title, and it can change

Real qBittorrent reports the name from the torrent's metadata, and it does not change. Zurg's name
comes from the library:

- Real-Debrid renames releases whose filename trips its 451 block (`WEB-DL`, `WEBRip`, `BDRip`,
  `HDRip`, `DVDRip`, and a source tag dot-adjacent to an old codec) — see the RD 451 section of the
  monorepo `CLAUDE.md`.
- zurg appends a suffix when two releases collide on a name, and a repair rebuilds a release under a
  new torrent id.
- The name is read off the library at every poll, so it can change **between polls** for an id the
  \*arr is already tracking.

None of that breaks tracking, because tracking is keyed on `DownloadId` — the infohash — and not on
the name. What it does break is the title-parsing path of §7.1. Two rules follow:

1. **Key on the infohash the \*arr computed**, never on anything zurg-internal. It is the only join
   between the grab, the grab history, and the poll.
2. **Keep the `__magic__` folder name parseable**, because it is the fallback the folder branch reads
   (`DownloadedEpisodesImportService.cs:184`).

### 11.4 There is no progress and no metadata phase

There is nothing to download, so there is no meaningful `progress`, `eta`, `dlspeed`, or `metaDL`
period — the same limitation the SAB endpoint documents ([sabnzbd.md\](../guides/sonarr-radarr.md), *What works, and
what does not*: "No progress. A job is queued or it is completed"). The natural mapping is: **Queued**
(`queuedDL`) while the library does not list the release yet, **Completed** (`pausedUP`) once it does
*and its file sizes have settled*, with `size` taken from whatever the backend declares so the queue
entry is not blank.

Do not use `metaDL` for the waiting state unless `dht: true` is also reported — it is Queued only in
that case (`:288-297`). `queuedDL` is unconditional and carries no message.

Do not use `stalledDL`, `error` or `missingFiles` for a transient wait: all three are **Warnings**
(§2) and surface in the queue as problems.

### 11.5 Deleting hides; it does not destroy

`torrents/delete?deleteFiles=true` on real qBittorrent removes the torrent and `rm -rf`s its data.
Here it must drop only the record: the release is still served out of the provider torrent, and the
folder the \*arr wanted gone it already tombstoned itself, through the mount (§5.2,
[magic.md\](../guides/magic.md#deleting-hides-it-does-not-destroy)). This is exactly the reasoning
`internal/sabnzbd`'s `deleteFromHistory` records at `internal/sabnzbd/api.go:596-609`.

### 11.6 Everything the client can ask for that has nothing to apply to

`sequentialDownload`, `firstLastPiecePrio`, `contentLayout`, `stopped`/`paused`, `setForceStart`,
`topPrio`, `setShareLimits`, `dlLimit`/`upLimit`: accept them, answer 200, apply nothing. Only two
have observable consequences if refused — `topPrio` (409 is swallowed, anything else warns) and
`setShareLimits` (404 is swallowed) — and neither blocks a grab.

`contentLayout` deserves a note: the setting exists in the \*arr precisely to force qBittorrent to
keep a top-level folder so that `content_path != save_path`. Under `__magic__` the layout is always a
folder regardless (§11.2), so the parameter is inert and the operator can leave it at Default.

---

## 12. Implementation checklist (14 points)

1. **API v2 only.** Answer `/api/v2/app/webapiVersion` with `2.11.2`; return **404** on
   `/version/api` so the v1 probe fails cleanly.
2. **Auth:** accept an `Authorization: Bearer <key>` header, a preemptive
   `Authorization: Basic`, a `SID` cookie, or nothing at all. Answer `POST /api/v2/auth/login`
   with **200 + `Ok.` + `Set-Cookie: SID=…`**; answer `Fails.` (still 200) for bad credentials, never
   a 401. Do not require `Referer` or `Origin`.
3. **Errors are HTTP statuses, not JSON.** 403 means "log in again" and is retried once; a second 403
   surfaces as a connection error, not an auth error. 404 is meaningful on
   `torrents/properties` (unknown hash) and on `torrents/setShareLimits` (unsupported); 409 is
   meaningful on `torrents/topPrio` (queueing off). Everything else must be 200.
4. **Parse both form encodings on `torrents/add`** — urlencoded, and multipart when any value exceeds
   1024 bytes or a `.torrent` is uploaded — and accept `True`/`False` as well as `true`/`false` for
   every boolean.
5. **`torrents/info` returns an array; `torrents/categories` returns an object** with camelCase
   `savePath`. Honour the `category` query parameter — the client does not re-filter.
6. **Hashes: lowercase in every response, matched case-insensitively in every request**, and always
   the infohash the \*arr computed from the magnet or `.torrent`. `torrents/properties` is the one
   route that may receive the hash in whatever case `torrents/info` used.
7. **The move recipe:** `state: "pausedUP"`, `ratio: 0`, `ratio_limit: 0`,
   `seeding_time_limit: -2`, `inactive_seeding_time_limit: -2`. Anything less and the import is a
   **copy** — a full download of the release. Document that the \*arr's "Remove Completed" setting
   must stay on, because the shim cannot compensate for it.
8. **`content_path` must be absolute, must exist on the \*arr host, and must not equal `save_path`.**
   Set it only once the release is genuinely importable — listed, and with its file sizes settled.
   Until then report `queuedDL` and let the client keep polling; there is no retry limit.
9. **`save_path`** (from `app/preferences`, plus any category `savePath`) must exist as a directory on
   the \*arr host or `RemotePathMappingCheck` raises an error. It does not need to be writable. Never
   emit a `savePath` starting with `//`.
10. **Keep the connection test green:** `dht: true`, `queueing_enabled: true`,
    `max_ratio_enabled: false`, `max_seeding_time_enabled: false`, `max_ratio_act: 0` (integer), and
    either pre-create the configured categories or honour `createCategory` and reflect it in the very
    next `torrents/categories` response.
11. **`torrents/delete` drops the record and nothing else.** Ignore `deleteFiles` for the provider
    torrent, exactly as `internal/sabnzbd`'s `deleteFromHistory` ignores `del_files`
    (`internal/sabnzbd/api.go:596-609`). Answer 200 for an unknown hash. Accept `setCategory` and
    record the new category.
12. **Expect the \*arr to `rm -rf` the release folder itself** after a Move import
    (`DownloadedEpisodesImportService.cs:209-223`) — that becomes a `__magic__` tombstone — and to
    call `torrents/delete` afterwards. Both are normal; neither destroys anything.
13. **Only use state names from §2**, exact case. An unknown name does not throw here (unlike SAB) but
    it does log and default to Downloading. Never use `stalledDL`, `error` or `missingFiles` for a
    transient wait — all three are Warnings.
14. **Do not put a root folder at or above the output folder.** With `save_path` =
    `/mnt/zurg/__magic__`, use `/mnt/zurg/__magic__/tv` and `/mnt/zurg/__magic__/movies` as root
    folders, and keep releases as siblings at `/mnt/zurg/__magic__/<release>` — otherwise
    `SeriesPathExists`/`MoviePathExists` refuses the import outright (§7.4) and Radarr's
    `DownloadClientRootFolderCheck` complains on every start.
