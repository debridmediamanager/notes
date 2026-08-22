# SABnzbd API contract as consumed by Sonarr and Radarr (develop)

Source of truth: files fetched from `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...`
on **2026-08-22**. Every line number below was read out of those files.

Kept here as the record of why `internal/sabnzbd` answers in the shapes it does. Nothing in that
package should be changed without the paragraph here that explains what the client does with the
field — a wrong struct tag does not fail, it leaves the client reading a zero, and a wrong enum
value throws inside its deserializer and takes the whole poll with it. For how to point Sonarr or
Radarr at zurg, see [sabnzbd.md](../guides/sabnzbd.md).

Unless a section says otherwise, **the two repos' SAB files are byte-identical apart from a UTF-8 BOM
and the `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` rename, and line numbers match
one-for-one.** Every `Sabnzbd*` citation therefore applies to both repos at the same line.
Paths are `src/NzbDrone.Core/Download/Clients/Sabnzbd/...` in both. Verified diffs are recorded in §6.

Nothing here is speculation about SAB itself: every claim is what the *client* does. Where I state
Newtonsoft.Json or .NET runtime semantics (not Sonarr code) I say so explicitly.

---

## 0. Transport-level rules (these bite first)

### 0.1 URL shape

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

- Base URL: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-66`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; `UrlBase` gets a leading `/` if missing.
  The endpoint is that + `/api` (`SabnzbdProxy.cs:38-44`).
- Suffix params always land last, so **`apikey` (or `ma_username`+`ma_password`) and `output=json`
  are the final query params** (`HttpRequestBuilder.cs:82` — `QueryParams.Concat(SuffixQueryParams)`).
- `Accept: application/json` on every call. `output=json` on every call. There is no
  `output=xml` path anywhere.
- API key and username/password are **mutually exclusive**: an api key suppresses `ma_username`/`ma_password`.

### 0.2 Always answer HTTP 200 — even for errors

`HttpClient.Execute` throws on any status >= 400 (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`;
`HttpResponse.cs:54` — `HasHttpError => (int)StatusCode >= 400`; 429 becomes `TooManyRequestsException`).
`SabnzbdProxy.ProcessRequest` (`SabnzbdProxy.cs:199-215`) converts that into
`DownloadClientException("Unable to connect to SABnzbd, {0}")`.

`HttpException`'s message is `"HTTP request failed: [401:Unauthorized] [GET] at [url]"`
(`src/NzbDrone.Common/Http/HttpException.cs:18`) — **the body is not in the message**. So a 401 with
`{"error":"API Key Incorrect"}` will *not* be recognised by `TestAuthentication`
(`Sabnzbd.cs:424,429` match on `ex.Message`), and the connection test reports the generic
"Test was aborted due to an error" instead. **Emulate SAB: HTTP 200 + `{"status": false, "error": "..."}`.**

### 0.3 Deserializer settings (drives every field-name and type question)

All SAB payloads go through `NzbDrone.Common.Serializer.Json`
(`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`) — **Newtonsoft**, not System.Text.Json:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Consequences (Newtonsoft semantics, not Sonarr code):

| Setting | Effect on an emulator |
|---|---|
| `CamelCasePropertyNamesContractResolver` | C# `Storage` binds `storage`, `PP` binds `pp`, `Misc` binds `misc`. Newtonsoft also falls back to a case-insensitive property match, so SAB's real snake_case/lowercase keys bind either way. |
| `StringEnumConverter` (global) | Applies to `SabnzbdDownloadStatus`, which has **no** per-property converter. Unknown enum names throw `JsonSerializationException`. Integers are also accepted (`AllowIntegerValues` defaults true). |
| `NullValueHandling.Ignore` | On **read** too: a JSON `null` leaves the C# member at its constructor value. So `"categories": null` keeps the ctor's empty list, but `"misc": null` leaves `Misc` null (no ctor default) → NRE, see §3.4. |
| `MissingMemberHandling` (default `Ignore`) | Extra fields in your payload are harmless. Send the full real SAB body. |
| `Culture` (default `InvariantCulture`) | Numeric strings like `"1024.00"` must use `.` as the decimal separator and no thousands separators. |

`Json.Deserialize<T>` rethrows only `JsonReaderException` with a nicer message (`Json.cs:39-50`);
`Json.TryDeserialize<T>` swallows **only** `JsonReaderException` and `JsonSerializationException`
(`Json.cs:99-117`). Anything else (e.g. an `ArgumentException` from the timeleft converter, or an NRE
from the priority converter) escapes.

---

## 1. Every mode, every parameter, every field consumed

### 1.1 `mode=version` — `SabnzbdProxy.GetVersion` (`SabnzbdProxy.cs:85-95`)

Request: `GET /api?mode=version&apikey=KEY&output=json`

Response model `SabnzbdVersionResponse` (`Responses/SabnzbdVersionResponse.cs:5`):

| JSON key | C# type | Notes |
|---|---|---|
| `version` | `string` | The only field read. |

Read via `Json.TryDeserialize`; a parse failure yields `Version == null` (`SabnzbdProxy.cs:89-92`).

Parsing (`Sabnzbd.cs:334-366`), regex at `Sabnzbd.cs:38`:

```csharp
// patch can be a number (releases) or 'x' (git)
private static readonly Regex VersionRegex = new Regex(@"(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+|x)", RegexOptions.Compiled);
```

- Unanchored, so `4.5.0RC1` and `2.0.0beta1` parse (fixture `SabnzbdFixture.cs:523,553`).
- `patch` may be the literal `x` (git builds), replaced with `0` (`Sabnzbd.cs:351`).
- A **two-component** version (`"4.5"`) does not match → `null` → validation failure.
- The exact string `"develop"` (case-insensitive) is special-cased to `3.0.0` (`Sabnzbd.cs:355-362`)
  and produces a *warning*, not a failure (`Sabnzbd.cs:380-387`).

Version is fetched again (a second `mode=version` round-trip) by `HasVersion` at
`Sabnzbd.cs:294-332` — it is **not cached**.

### 1.2 `mode=get_config` — `SabnzbdProxy.GetConfig` (`SabnzbdProxy.cs:97-104`)

Request: `GET /api?mode=get_config&apikey=KEY&output=json`

Uses `Json.Deserialize` (**not** Try) — a malformed body throws out of `GetConfig`.
Top level must be `{"config": {...}}` (`Responses/SabnzbdConfigResponse.cs:5`). See §3 for the fields.

### 1.3 `mode=fullstatus` — `SabnzbdProxy.GetFullStatus` (`SabnzbdProxy.cs:106-114`)

Request: `GET /api?mode=fullstatus&skip_dashboard=1&apikey=KEY&output=json`

Top level `{"status": {...}}` (`Responses/SabnzbdFullStatusResponse.cs:5`). Only one field is read:

| JSON key | C# | Source |
|---|---|---|
| `completedir` | `string CompleteDir` | `SabnzbdFullStatus.cs:9-10` — note: **`completedir`, no underscore** |

Called **only** when `config.misc.complete_dir` is *not* rooted **and** the SAB version is >= 2.0
(`Sabnzbd.cs:220-226`). With an absolute `complete_dir` this endpoint is never hit — implement it anyway.

Quirk worth knowing: because the real body is `{"status": {...}}` and `SabnzbdJsonError.Status` is a
`string`, `CheckForError`'s `TryDeserialize<SabnzbdJsonError>` fails with a `JsonSerializationException`
and falls into the plain-text branch, which sets `Status = "true"` (`SabnzbdProxy.cs:224-240`). Benign,
but it means fullstatus can never report an error through the JSON path.

### 1.4 `mode=queue` (read) — `SabnzbdProxy.GetQueue` (`SabnzbdProxy.cs:116-130`)

Request: `GET /api?mode=queue&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- `category` is added **only if** the configured category is non-blank (`SabnzbdProxy.cs:122-125`).
- Callers: `Sabnzbd.GetQueue()` uses `start=0, limit=0` (`Sabnzbd.cs:57`) — SAB reads `limit=0` as "all";
  `Sabnzbd.GetCategories()` uses `start=0, limit=1` on the pre-2.0 path (`Sabnzbd.cs:229`);
  `Sabnzbd.RemoveItem()` calls it once more to decide queue-vs-history (`Sabnzbd.cs:199`).
- Extraction: `Json.Deserialize<SabnzbdQueue>(JObject.Parse(response).SelectToken("queue").ToString())`
  (`SabnzbdProxy.cs:129`) — **a missing top-level `queue` key NREs**.

`SabnzbdQueue` (`SabnzbdQueue.cs`):

| JSON key | C# | Type | Used for |
|---|---|---|---|
| `my_home` | `DefaultRootFolder` | `string` | Only on SAB < 2.0 to resolve a relative `complete_dir` (`Sabnzbd.cs:230`). Comment at `SabnzbdQueue.cs:8`: "Removed in Sabnzbd 2.0.0, see mode=fullstatus instead." |
| `paused` | `Paused` | `bool` | Global pause; combined with the slot's priority (`Sabnzbd.cs:78`). |
| `slots` | `Items` | `List<SabnzbdQueueItem>` | |

`SabnzbdQueueItem` (`SabnzbdQueueItem.cs`):

| JSON key | C# member | C# type | SAB's real JSON type | Notes |
|---|---|---|---|---|
| `status` | `Status` | `SabnzbdDownloadStatus` | string | Global `StringEnumConverter`. Unknown value ⇒ `JsonSerializationException` ⇒ the whole `GetQueue` throws. |
| `index` | `Index` | `int` | number | Read, never used. |
| `timeleft` | `Timeleft` | `TimeSpan` via `SabnzbdQueueTimeConverter` | string | See §1.4.1. |
| `mb` | `Size` | `decimal` | **string** (`"1024.00"`) | **Megabytes.** `TotalSize = (long)(Size * 1024 * 1024)` (`Sabnzbd.cs:72`). |
| `mbleft` | `Sizeleft` | `decimal` | **string** | **Megabytes.** `RemainingSize = (long)(Sizeleft * 1024 * 1024)` (`Sabnzbd.cs:73`). |
| `filename` | `Title` | `string` | string | Becomes `DownloadClientItem.Title` (`Sabnzbd.cs:71`). |
| `priority` | `Priority` | `SabnzbdPriority` via `SabnzbdPriorityTypeConverter` | string (`"Normal"`) | See §2. |
| `cat` | `Category` | `string` | string | **`cat` in the queue, `category` in the history.** |
| `mbleft`/`percentage` | `Percentage` | `int` | **string** (`"50"`) | Read, never used. |
| `nzo_id` | `Id` | `string` | string | The download id Sonarr/Radarr key everything on. |

#### 1.4.1 `timeleft` format — `SabnzbdQueueTimeConverter` (`JsonConverters/SabnzbdQueueTimeConverter.cs:15-28`)

```csharp
var split = reader.Value.ToString().Split(':').Select(int.Parse).ToArray();
switch (split.Length)
{
    case 4: return new TimeSpan((split[0] * 24) + split[1], split[2], split[3]);   // d:h:m:s
    case 3: return new TimeSpan(split[0], split[1], split[2]);                     // h:m:s
    default: throw new ArgumentException("Expected either 0:0:0:0 or 0:0:0 format, but received: " + reader.Value);
}
```

- **Exactly 3 or 4 colon-separated integers.** `"0:08:32"`, `"40:12:14"`, `"1:16:12:14"` all fine
  (fixture `SabnzbdQueueTimeConverterFixture.cs:14-20`); `"1"`, `"0:1"`, `"0:0:0:0:1"` throw
  (`:28-35`). Leading zeros are fine (`int.Parse`).
- The thrown `ArgumentException` is **not** caught by `Json.TryDeserialize` and not by `Json.Deserialize`.
- An **empty string** `""` splits to `[""]` → `int.Parse` throws `FormatException`. Never emit `""`.
- Omitting `timeleft` entirely is safe: the converter is not invoked and `Timeleft` stays `TimeSpan.Zero`.

### 1.5 `mode=queue&name=delete` — `SabnzbdProxy.RemoveFromQueue` (`SabnzbdProxy.cs:64-72`)

```
GET /api?mode=queue&name=delete&del_files={0|1}&value={nzo_id}&apikey=KEY&output=json
```

`del_files = deleteData ? 1 : 0` (`SabnzbdProxy.cs:68`). **No `archive` param on the queue path.**
Response body is only run through `CheckForError`; nothing is deserialized.

### 1.6 `mode=history` (read) — `SabnzbdProxy.GetHistory` (`SabnzbdProxy.cs:132-146`)

Request: `GET /api?mode=history&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- Caller: `Sabnzbd.GetHistory()` with `start=0, limit=_configService.DownloadClientHistoryLimit`
  (`Sabnzbd.cs:110`). Default **60** in both repos
  (Sonarr `src/NzbDrone.Core/Configuration/ConfigService.cs:184`, Radarr `:236`).
- Extraction: `SelectToken("history")` (`SabnzbdProxy.cs:145`) — top level must be `{"history": {...}}`.

`SabnzbdHistory` (`SabnzbdHistory.cs`): `paused` (`bool`, unused), `slots` → `Items`.

`SabnzbdHistoryItem` (`SabnzbdHistoryItem.cs`):

| JSON key | C# member | C# type | Notes |
|---|---|---|---|
| `fail_message` | `FailMessage` | `string` | Becomes `DownloadClientItem.Message` (`Sabnzbd.cs:132`) and drives the Warning special case (§1.6.1). |
| `bytes` | `Size` | `long` | **BYTES, not MB** — `TotalSize = sabHistoryItem.Size` verbatim (`Sabnzbd.cs:128`). This is the single biggest asymmetry with `mode=queue`. |
| `category` | `Category` | `string` | Note: `category`, whereas the queue uses `cat`. |
| `nzb_name` | `NzbName` | `string` | Read, never used. |
| `download_time` | `DownloadTime` | `int` (seconds) | Read, never used. |
| `storage` | `Storage` | `string` | The output path. See §1.6.2 — this is what gets `rm -rf`'d. |
| `status` | `Status` | `SabnzbdDownloadStatus` | Global `StringEnumConverter`. |
| `nzo_id` | `Id` | `string` | |
| `name` | `Title` | `string` | |

**No `DateTime`-typed member exists anywhere in the SAB models, so no date format is constrained.**
`completed` / `last_history_update` (unix epoch in real SAB) are never read. The only time-shaped
values that matter are `timeleft` (§1.4.1) and `download_time` (an unread integer of seconds).

#### 1.6.1 History status → `DownloadItemStatus` (`Sabnzbd.cs:116-158`)

```
Deleted                                   -> skipped entirely (Sabnzbd.cs:116-119)
Failed  + fail_message == "Unpacking failed, write error or disk is full?"
        (InvariantCultureIgnoreCase)      -> DownloadItemStatus.Warning     (:140-144)
Failed  (any other message)               -> DownloadItemStatus.Failed      (:147)
Completed                                 -> DownloadItemStatus.Completed   (:152)
anything else (Verifying/Moving/...)      -> DownloadItemStatus.Downloading (:157)
```

Every history item gets `RemainingSize = 0`, `RemainingTime = TimeSpan.Zero`,
`CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:129-135`).

`DownloadItemStatus` itself (`src/NzbDrone.Core/Download/DownloadItemStatus.cs:3-11`):
`Queued=0, Paused=1, Downloading=2, Completed=3, Failed=4, Warning=5`.

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

The loop walks **all the way to the root** and keeps the *highest* ancestor whose last segment equals
`name`. Purpose: if `storage` points at a file inside the job folder, back out to the job folder
(fixture `SabnzbdFixture.cs:376-391`). If `storage` is already the job folder, no ancestor matches and
`OutputPath == storage` — which is what you want.

**Recommendation for the emulator: set `storage` to the job folder path itself.**

Empty `storage` ⇒ `OutputPath` stays empty ⇒ `CompletedDownloadService.ValidatePath` warns
"Download doesn't contain intermediate path, Skipping." (Sonarr `CompletedDownloadService.cs:299-303`).

### 1.7 `mode=history&name=delete` — `SabnzbdProxy.RemoveFromHistory` (`SabnzbdProxy.cs:74-83`)

```
GET /api?mode=history&name=delete&del_files={0|1}&value={nzo_id}&archive={0|1}&apikey=KEY&output=json
```

```csharp
request.AddQueryParam("del_files", deleteData ? 1 : 0);          // :78
request.AddQueryParam("value", id);                              // :79
request.AddQueryParam("archive", deletePermanently ? 0 : 1);     // :80   <-- inverted
```

and the caller (`Sabnzbd.cs:208`):

```csharp
_proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
```

So `deletePermanently == (status is Failed)`, and therefore:

| Item status | `del_files` | `archive` |
|---|---|---|
| Completed | 1 | **1** (archive it) |
| Failed | 1 | **0** (permanent delete) |

Yes, that reads backwards at first glance — it is what the code does.

### 1.8 `mode=addfile` — `SabnzbdProxy.DownloadNzb` (`SabnzbdProxy.cs:46-62`)

```
POST /api?mode=addfile&cat={category}&priority={int}&apikey=KEY&output=json
Content-Type: multipart/form-data; boundary=...
  part: Content-Disposition: form-data; name="name"; filename="<CleanFileName(Release.Title)>.nzb"
        Content-Type: application/x-nzb
```

- The multipart field is literally `name` and the part carries a `filename` (`SabnzbdProxy.cs:53`,
  `HttpRequestBuilder.cs:379-395`, emitted at `:180-195`).
- Filename comes from `FileNameBuilder.CleanFileName(release.Title) + ".nzb"`
  (Sonarr `src/NzbDrone.Core/Download/UsenetClientBase.cs:43`, Radarr `:43`).
- **`cat` ignores the method's `category` argument** and reads settings directly
  (`SabnzbdProxy.cs:50`: `request.AddQueryParam("cat", settings.TvCategory);` — Radarr: `settings.MovieCategory`).
  Harmless, since the caller passes the same value.
- `priority` is the raw `int` from `SabnzbdPriority` (see §2), chosen by recency:
  Sonarr `Sabnzbd.cs:43` `remoteEpisode.IsRecentEpisode() ? Settings.RecentTvPriority : Settings.OlderTvPriority`;
  Radarr `Sabnzbd.cs:43` `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie ? RecentMoviePriority : OlderMoviePriority`.
- Response `SabnzbdAddResponse` (`Responses/SabnzbdAddResponse.cs`):

| JSON key | C# | Type |
|---|---|---|
| `status` | `Status` | `bool` — parsed, then **never read** |
| `nzo_ids` | `Ids` | `List<string>`, ctor-initialised to empty |

  Read with `TryDeserialize`; on failure a synthetic `{Status=true, Ids=[]}` is used (`SabnzbdProxy.cs:55-59`).
  Then `Sabnzbd.cs:47-52`:

```csharp
if (response == null || response.Ids.Empty())
{
    throw new DownloadClientRejectedReleaseException(remoteEpisode.Release, "SABnzbd rejected the NZB for an unknown reason");
}

return response.Ids.First();
```

  **`nzo_ids` must be a non-empty array of strings.** `"nzo_ids": null` is equivalent to absent
  (`NullValueHandling.Ignore` keeps the ctor's empty list) and fails the same way.

### 1.9 Queue status → `DownloadItemStatus` (`Sabnzbd.cs:60-103`)

```
Deleted                                       -> skipped (Sabnzbd.cs:62-65)
(queue.paused && slot.priority != Force) || slot.status == Paused
                                              -> Paused, and RemainingTime forced to null (:78-84)
Queued | Grabbing | Propagating               -> Queued        (:85-90)
everything else                               -> Downloading   (:93)
```

Also `Sabnzbd.cs:96-100`: a title beginning with the literal `"ENCRYPTED /"` is stripped of those
11 characters and the item is flagged `IsEncrypted = true`.

Every queue item gets `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:75-76`).

### 1.10 Client-side category filter (`Sabnzbd.cs:186-195`)

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

Ordinal string equality. An item in category `*` is only accepted when the configured category is blank.

### 1.11 Modes that exist in the proxy but are never called

- `mode=retry&value={id}` (`SabnzbdProxy.cs:148-160`, response `{status, nzo_id}` →
  `Responses/SabnzbdRetryResponse.cs`). `ISabnzbdProxy.RetryDownload` has **no caller** in either repo.
- `Responses/SabnzbdCategoryResponse.cs` (`{"categories": [...]}`, i.e. `mode=get_cats`) is
  **entirely unreferenced** in both repos.
- `Sabnzbd.ValidatePath` (`Sabnzbd.cs:576-592`) is private and never called (dead).

---

## 2. `SabnzbdDownloadStatus` and `SabnzbdPriority` — exact members, unknown/null handling

### 2.1 `SabnzbdPriority.cs` (complete file)

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

- `Enum.TryParse<T>(string, out T)` is the **case-sensitive** overload (.NET semantics).
  `"Normal"` parses; `"normal"` does **not** — and on failure `output` is
  `default(SabnzbdPriority) == 0 == Normal`, so a bad case silently degrades to Normal.
  `"Force"` matters (§1.9), `"force"` does not work.
- Numeric strings also parse: `"2"` → `Force`, `"-100"` → `Default`. A JSON number `2` works too
  (`reader.Value.ToString()` == `"2"`).
- **`"priority": null` throws a `NullReferenceException`** (`reader.Value.ToString()` on null).
  This is *not* caught by `Json.TryDeserialize`. Omit the key or send a real value.
- Omitting `priority` is safe: the converter is not invoked, member stays `Normal` (0).
- The converter is registered only on `SabnzbdQueueItem.Priority` (`SabnzbdQueueItem.cs:21`);
  history items have no priority.
- These same integers are what Sonarr/Radarr send back as `&priority=` on `mode=addfile`
  (`SabnzbdSettings.cs` defaults both `Recent*Priority` and `Older*Priority` to
  `(int)SabnzbdPriority.Default` = `-100`).

### 2.2 `SabnzbdDownloadStatus.cs` (complete file), declaration order = implicit values 0..15

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

## 3. `get_config`: exactly what is read, and the validation rules

### 3.1 The model — `SabnzbdCategory.cs`

This one file holds `SabnzbdConfig`, `SabnzbdConfigMisc`, `SabnzbdCategory` **and** `SabnzbdSorter`.
There is **no `SabnzbdConfig.cs`** in either repo (confirmed via the GitHub contents API listing of
`src/NzbDrone.Core/Download/Clients/Sabnzbd`).

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

### 3.2 `config.misc.*` — the complete set of keys read (`SabnzbdCategory.cs:23-37`)

| JSON key | C# type | Read at | Purpose |
|---|---|---|---|
| `complete_dir` | `string` | `Sabnzbd.cs:218` | Base for every category path. |
| `tv_categories` | `string[]` | `Sabnzbd.cs:265, 493` | |
| `enable_tv_sorting` | `bool` | `Sabnzbd.cs:265, 493` | |
| `movie_categories` | `string[]` | `Sabnzbd.cs:269, 502` | |
| `enable_movie_sorting` | `bool` | `Sabnzbd.cs:269, 502` | |
| `date_categories` | `string[]` **via `SabnzbdStringArrayConverter`** | `Sabnzbd.cs:273, 511` | |
| `enable_date_sorting` | `bool` | `Sabnzbd.cs:273, 511` | |
| `pre_check` | `bool` | `Sabnzbd.cs:443` | |
| `history_retention` | `string` | `Sabnzbd.cs:540, 561-573` | Legacy, SAB < 4.3. |
| `history_retention_option` | `string` | `Sabnzbd.cs:541, 544` | SAB >= 4.3. |
| `history_retention_number` | `int` | `Sabnzbd.cs:542, 553` | SAB >= 4.3. |

`SabnzbdStringArrayConverter` (`JsonConverters/SabnzbdStringArrayConverter.cs:25-39`) — applied only
to `date_categories` (`SabnzbdCategory.cs:30`):

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

A JSON **string** becomes a 1-element array; a **null** becomes `[null]` (a 1-element array containing
null); an **array** deserialises normally; anything else (a number, an object) throws. Doc comment at
`:7-9`: "On some properties sab serializes array of single item as plain string."

### 3.3 `config.categories[]` — `SabnzbdCategory` (`SabnzbdCategory.cs:39-48`)

| JSON key | C# | Read at |
|---|---|---|
| `priority` | `int Priority` | never read |
| `pp` | `string PP` | never read (camelCase of `PP` is `pp`) |
| `name` | `string Name` | `Sabnzbd.cs:251, 255, 458` |
| `script` | `string Script` | never read |
| `dir` | `string Dir` | `Sabnzbd.cs:238` (`Dir.TrimEnd('*')`), `Sabnzbd.cs:462` (`Dir.EndsWith("*")`) |

`FullPath` (`OsPath`) is computed, not deserialized.

Path assembly — `Sabnzbd.GetCategories` (`Sabnzbd.cs:216-244`):

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

`OsPath.operator+` (`src/NzbDrone.Common/Disk/OsPath.cs:420-448`) returns `left` when `right.IsEmpty`,
so `dir: ""` gives `FullPath == complete_dir` exactly. `IsRooted` for a Unix-kind path is
`_path.StartsWith("/")` (`OsPath.cs:142-145`); path kind is sniffed from the string
(`OsPath.cs:43-60`) — a leading `/` ⇒ Unix, a `\` or drive letter ⇒ Windows. A Unix-kind path handed
to a Windows-hosted Sonarr fails `CompletedDownloadService.ValidatePath` (`:305-310`).

### 3.4 The two NRE landmines (and what is actually safe)

| Payload shape | Result |
|---|---|
| **`"misc"` absent or `null`** | `Misc` stays null (no ctor default; `NullValueHandling.Ignore` on read) → **NullReferenceException at `Sabnzbd.cs:218`**, surfacing as "Test was aborted due to an error: …" and as a logged error in the health checks. |
| **a category with `"dir"` absent or `null`** | `Dir` is null → **NullReferenceException at `Sabnzbd.cs:238`** (`category.Dir.TrimEnd('*')`) and again at `:462` (`category.Dir.EndsWith("*")`). |
| `"categories": null` or absent | Safe — the ctor's empty list survives. `GetStatus` then finds no category and `OutputRootFolders` stays empty. |
| `"sorters": null` or absent | Safe — ctor empty list; `config.Sorters.Any(...)` at `Sabnzbd.cs:484` works. |
| `"servers": null` or absent | Safe and never read (`List<object>`, `SabnzbdCategory.cs:19`). |
| `"tv_categories"/"movie_categories"/"date_categories": null` | Safe: `ContainsCategory` returns `true` for null/empty (§3.5), but that only matters if the matching `enable_*_sorting` is true. |

**Rule: always emit `misc` as an object and every category with a string `dir` (use `""`).**

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

Confirmed by fixtures: `enable_tv_sorting=true` + `tv_categories=null` **fails**
(`SabnzbdFixture.cs:636-645`), and + `tv_categories=[]` also **fails** (`:647-656`).
`TvCategory=null` + `tv_categories=["Default"]` fails (`:680-691`).

### 3.6 `Test()` — the exact order and rules (`Sabnzbd.cs:286-292`)

```csharp
protected override void Test(List<ValidationFailure> failures)
{
    failures.AddIfNotNull(TestConnectionAndVersion());
    failures.AddIfNotNull(TestAuthentication());
    failures.AddIfNotNull(TestGlobalConfig());
    failures.AddIfNotNull(TestCategory());
}
```

Wrapped by `DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`),
which catches any escaping exception and adds `"Test was aborted due to an error: " + ex.Message`.

**`TestConnectionAndVersion()` (`Sabnzbd.cs:368-414`)** — 1 × `mode=version`:

1. unparseable version → failure on field `Version` (`DownloadClientSabnzbdValidationUnknownVersion`).
2. `rawVersion == "develop"` (ignore case) → **warning** on `Version`, `IsValid` stays true
   (fixture `SabnzbdFixture.cs:566-577`).
3. `version.Major >= 1` → pass (`:389-392`).
4. else `version.Minor >= 7` → pass (`:394-397`).
5. else failure: required version `"0.7.0"` (`:399-404`).
   Fixture table (`SabnzbdFixture.cs:549-564`): `0.6.9`→false, `0.7.0`/`0.8.0`/`1.0.0`/`1.0.0RC1`/`1.1.x`→true.
6. Any exception → failure on field `Host` ("unable to connect"), detail = `ex.Message` (`:406-413`).

**`TestAuthentication()` (`Sabnzbd.cs:416-438`)** — 1 × `mode=get_config`. Catches, then matches
`ex.Message` with `ContainsIgnoreCase`:

| Substring matched | Failure field |
|---|---|
| `API Key Incorrect` | `APIKey` — `DownloadClientValidationApiKeyIncorrect` |
| `API Key Required` | `APIKey` — `DownloadClientValidationApiKeyRequired` |
| anything else | **rethrown** → generic "Test was aborted due to an error: …" |

Because `CheckForError` wraps the body as `"Error response received from SABnzbd: {error}"`
(`SabnzbdProxy.cs:244`), matching works when your `error` string *contains* `API Key Incorrect` /
`API Key Required` — SAB's own wording.

**`TestGlobalConfig()` (`Sabnzbd.cs:440-453`)** — 1 × `mode=get_config`, plus 1 × `mode=version`
only if `pre_check` is true:

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

Threshold: **SAB >= 1.1.0** (`HasVersion(major:1, minor:1, patch:0)`, `Sabnzbd.cs:294-332`).
`pre_check: false` avoids the whole branch, including the extra `mode=version` round-trip.

**`TestCategory()` (`Sabnzbd.cs:455-521`)** — 1 × `mode=get_config` (a *third* one), plus whatever
`GetCategories` needs. Checks run in this order, first hit wins:

1. matched category (`Name == Settings.TvCategory` / `MovieCategory`) whose `dir` **ends with `*`**
   → warning on `TvCategory`/`MovieCategory` "enable job folders", InfoLink `config/categories/` (`:460-469`).
2. no matched category **and** the configured category is non-blank → warning
   `DownloadClientValidationCategoryMissing`, InfoLink `config/categories/` (`:471-481`).
3. `config.Sorters.Any(s => s.is_active && ContainsCategory(s.sort_cats, cat))` → warning, InfoLink
   `config/sorting/` (`:483-491`). Code comment at `:483`: *"New in SABnzbd 4.1, but on older versions
   this will be empty and not apply"*.
4. `misc.enable_tv_sorting && ContainsCategory(misc.tv_categories, cat)` → warning (`:493-500`).
5. `misc.enable_movie_sorting && ContainsCategory(misc.movie_categories, cat)` → warning (`:502-509`).
6. `misc.enable_date_sorting && ContainsCategory(misc.date_categories, cat)` → warning (`:511-518`).

`SabnzbdSorter` (`SabnzbdCategory.cs:50-66`) — read: `sort_cats` (`List<string>`, ctor-empty),
`is_active` (`bool`). Present in the model but never read: `name`, `order`, `min_size`,
`multipart_label`, `sort_string`, `sort_type` (`List<int>`).

**Traffic note:** all four `Test*` methods make their own calls, nothing is cached — a single
connection test issues roughly **2 × `mode=version` and 3 × `mode=get_config`** (a 4th version call if
`pre_check` is true).

### 3.7 `config.misc` history retention → `RemovesCompletedDownloads` (`Sabnzbd.cs:538-574`)

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

`true` raises a health-check **warning**
(`HealthCheck/Checks/DownloadClientRemovesCompletedDownloadsCheck.cs:44-53`).
Fixture coverage `SabnzbdFixture.cs:455-510`: legacy `"0"`/`""`/`null`/`"15d"` → false;
`"-1"`/`"15"`/`"3"`/`"3d"` → true.

**Cleanest emulator answer: `history_retention_option: "all"`, `history_retention_number: 0`,
`history_retention: "0"`.**

### 3.8 `SortingMode` and its health check (`Sabnzbd.cs:263-279`)

`GetStatus` sets `SortingMode` to `"TV"`, `"Movie"` or `"Date"` using the same
`enable_*_sorting && ContainsCategory(...)` predicates. Any non-blank value raises a warning in
`HealthCheck/Checks/DownloadClientSortingCheck.cs:45-55`. Keep all three `enable_*_sorting` false.

### 3.9 `IsLocalhost` (`Sabnzbd.cs:260`)

```csharp
IsLocalhost = Settings.Host == "127.0.0.1" || Settings.Host == "localhost"
```

Ordinal, case-sensitive; `::1`, `Localhost` and any hostname do **not** count. This changes which
`RemotePathMappingCheck` message you get (see §6.2).

---

## 4. Error handling — `CheckForError` (`SabnzbdProxy.cs:222-246`)

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

`SabnzbdJsonError` (`SabnzbdJsonError.cs`, complete):

```csharp
public string Status { get; set; }
public string Error  { get; set; }

public bool Failed => !string.IsNullOrWhiteSpace(Status) &&
                      Status.Equals("false", StringComparison.InvariantCultureIgnoreCase);
```

Rules, precisely:

- `CheckForError` runs on **every** response, before any mode-specific deserialization
  (`SabnzbdProxy.cs:217`).
- `Status` is typed `string` but SAB sends a JSON **boolean**. Newtonsoft coerces `false` → `"False"`,
  which `Failed` matches case-insensitively. Both `false` (boolean) and `"false"` (string) work.
- A response with **no top-level `status`** (e.g. `{"version": …}`, `{"queue": {...}}`,
  `{"history": {...}}`, `{"config": {...}}`) leaves `Status` null → `Failed` false → no error.
- `status: true` → `"True"` → not failed.
- **Non-JSON body**: `TryDeserialize` returns false (it catches `JsonReaderException` and
  `JsonSerializationException`, `Json.cs:107-116`) and the plain-text branch runs. A body starting
  with `error` (case-insensitive) → `Status = "false"` → throws
  `DownloadClientException("Error response received from SABnzbd: {body with 'error: ' stripped}")`.
  Any other non-JSON body → `Status = "true"` → **treated as success**, and the mode-specific
  deserialization then fails on its own terms.
- A **JSON body whose `status` is an object** (`mode=fullstatus`) also takes the plain-text branch,
  because a `StartObject` token cannot fill a `string` property — `Status` becomes `"true"`.
- Note the redundant `result.Error = …` at `:239`: `Error` is set even on the success branch. It has
  no effect (nothing reads `Error` unless `Failed`).

Exception mapping in `ProcessRequest` (`SabnzbdProxy.cs:187-220`):

| Caught | Thrown |
|---|---|
| `HttpException` (any non-2xx, incl. 401/403/404/500) | `DownloadClientException("Unable to connect to SABnzbd, {0}")` |
| `HttpRequestException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |
| `WebException` with `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, certificate validation failed.")` |
| other `WebException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |

**The exact auth-failure strings matched** (`Sabnzbd.cs:424, 429`, exact literals, matched with
`ContainsIgnoreCase` against the exception message):

- `"API Key Incorrect"`
- `"API Key Required"`

Nothing else is classified. Emit them verbatim as the `error` value of an **HTTP 200** response.

**Why a non-200 must never be returned:** `HttpClient.Execute` throws before `CheckForError` ever runs
(`HttpClient.cs:106-121`), the resulting `HttpException` message contains only status/method/URL and
not the body (`HttpException.cs:18`), so the `"API Key Incorrect"` / `"API Key Required"` matching
cannot fire. The user sees "Unable to connect to SABnzbd" or "Test was aborted due to an error"
instead of an actionable message, and every health check treats the client as unreachable.

---

## 5. The post-import sequence

### 5.1 Who calls `RemoveItem`, and with what

`DownloadEventHub` (`src/NzbDrone.Core/Download/DownloadEventHub.cs`, identical in both repos except
the BOM):

- `Handle(DownloadCompletedEvent)` (`:48-69`): calls `MarkItemAsImported` (SAB throws
  `NotSupportedException` — `DownloadClientBase.cs:189-192` — logged at debug and ignored), then
  returns early if the item is already `Removed`, `!CanBeRemoved`, or still `Downloading`, then
  returns early unless `definition.RemoveCompletedDownloads`.
- `Handle(DownloadFailedEvent)` (`:26-46`): gated on `definition.RemoveFailedDownloads`.
- `Handle(DownloadCanBeRemovedEvent)` (`:71-85`): gated on `definition.RemoveCompletedDownloads`.
- All three funnel into `RemoveFromDownloadClient` (`:87-103`):

```csharp
_logger.Debug("[{0}] Removing download from {1} history", …);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);   // :92 -- deleteData is ALWAYS true
trackedDownload.DownloadItem.Removed = true;
```

`DownloadClientDefinition` defaults (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17-18`):

```csharp
public bool RemoveCompletedDownloads { get; set; } = true;
public bool RemoveFailedDownloads    { get; set; } = true;
```

The manual API path `DELETE /api/v3/queue/{id}?removeFromClient=true` also passes `true`
(Sonarr `src/Sonarr.Api.V3/Queue/QueueController.cs:342`). **There is no caller anywhere that passes
`deleteData: false`.**

### 5.2 `Sabnzbd.RemoveItem` (`Sabnzbd.cs:197-214`) — the exact sequence

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

So the post-import wire sequence against the emulator is:

1. `GET /api?mode=queue&start=0&limit=0&category=tv&apikey=…&output=json` (to decide queue vs history)
2. **local filesystem delete of the output folder** (§5.3) — before any further HTTP call
3. `GET /api?mode=history&name=delete&del_files=1&value={nzo_id}&archive=1&apikey=…&output=json`

For a **failed** item: no local delete (status is `Failed`, not `Completed`), and **`archive=0`** —
the inversion in `SabnzbdProxy.cs:80` (`archive = deletePermanently ? 0 : 1`, where
`deletePermanently == (status is Failed)`).

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

- **Yes, it recursively deletes the output folder.** `DeleteFolder(path, recursive: true)` at `:129`.
- `OutputPath` here is the history item's `storage` after remote-path remapping and the job-folder
  walk-up (§1.6.2). For a flat magic directory that means `rm -rf /mnt/zurg/__magic__/<Title>`.
- The governing setting is the download client's **Remove Completed Downloads** toggle
  (`DownloadClientDefinition.RemoveCompletedDownloads`, default **true**), *not* a SAB-side setting
  and not `del_files`. There is no separate "delete data" switch in the UI.
- Failures are swallowed with a warning — a read-only mount logs noise but does not break the import.
- Fixture coverage `SabnzbdFixture.cs:693-803`: folder deleted recursively, file deleted, nothing when
  the path doesn't exist, and nothing at all (not even a `FolderExists` probe) when `deleteData` is false.

### 5.4 Transfer mode: is the file moved or copied?

`Sabnzbd` sets `CanMoveFiles = true` on **every** item, queue (`Sabnzbd.cs:76`) and history
(`Sabnzbd.cs:135`). The automatic-import path is
`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, …)`
(Sonarr `CompletedDownloadService.cs:148-151`), and then:

Sonarr `src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152`
(Radarr `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, identical logic):

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
(`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`). A `copyOnly` import would instead use
`TransferMode.HardLinkOrCopy` when "Use Hardlinks instead of Copy" is on, else `TransferMode.Copy`
(`:94-108`).

`TransferMode` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`) is `[Flags]`:
`None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy = Copy|HardLink`.

### 5.5 Does a failed Move fall back to a copy? — **No. A failed Move is a failed import.**

`src/NzbDrone.Common/Disk/DiskTransferService.cs` (byte-identical between the two repos — verified).
`TransferFile`, `:256-392`; the `TransferMode.Move` branch at `:360-389`:

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

- The **only** copy fallback is the `isCifs && !isSameMount` special case at `:378-385`, keyed on
  `targetMount.DriveFormat == "cifs"` (`:342`). It is chosen *up front* from the drive format, never
  as a reaction to a failure.
- `TryMoveFileVerified` (`:487-503`) catches, calls `RollbackPartialMove` (unless the exception is
  `FileAlreadyExistsException`), and **rethrows**:

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

- `VerifyFile` (`:505-524`) compares destination size to source size, sleeps 3 s
  (`WaitForIO`, `:467-471`), re-checks, then throws
  `IOException("File move incomplete, data loss may have occurred. [{target}] was {n} bytes long instead of the expected {m}.")`.
- That `IOException` propagates up through `EpisodeFileMovingService.TransferFile` (`:151`) into the
  generic `catch (Exception e)` in `ImportApprovedEpisodes.cs:218-222` (Radarr `:197-201`), producing
  `ImportResult(importDecision, "Failed to import episode")` / `"Failed to import movie"`.
  **No copy is attempted.**
- Other pre-flight `IOException`s in the same method: source == target (`:270`, `:277`), and
  "Destination cannot be a child of the source" (`:312-315`).

Caveat, and it is a .NET-runtime fact rather than Sonarr code: `DiskProviderBase.MoveFileInternal`
(`src/NzbDrone.Common/Disk/DiskProviderBase.cs:293-301`) is a plain `File.Move`, and .NET on Unix
falls back to copy+delete when `rename()` returns `EXDEV`. So a cross-filesystem move usually still
succeeds — as a *runtime* fallback, not a Sonarr one. What will **not** be tolerated is a destination
whose size differs from the source, or any exception `File.Move` itself surfaces (EACCES, EPERM,
EROFS on the source, …).

`TransferFolder` (`:44-137`) is used by other code paths; note `:124-131` — after a folder Move it
refuses to delete the source if more than 100 MB of files remain
(`IOException("Large files still exist in {sourcePath} after folder move, not deleting source folder")`).

---

## 6. The two health checks

### 6.1 `DownloadClientRootFolderCheck` — **the one place Sonarr and Radarr genuinely differ**

Sonarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = status.OutputRootFolders.Where(folder => rootFolders.Any(r => r.Path.PathEquals(folder.FullPath)));
```

Radarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = rootFolders.Where(r => status.OutputRootFolders.Any(folder => r.Path.PathEquals(folder.FullPath) || r.Path.IsParentPath(folder.FullPath)));
```

`IsParentPath` (`src/NzbDrone.Common/Extensions/PathExtensions.cs:123-140`) walks **up** from the child:

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

So `r.Path.IsParentPath(folder.FullPath)` is true when **the root folder is an ancestor of the
download output folder**, i.e. the output folder lives *inside* a root folder. It is a strict
ancestor test (it starts from `child.Directory`); equality is handled separately by `PathEquals`.

**Answering the predicate question directly:**

| Relationship (output folder O vs root folder R) | Sonarr | Radarr |
|---|---|---|
| O == R | **warn** | **warn** |
| O inside R (R is O's ancestor) | no warning | **warn** |
| O is the PARENT of R (O is R's ancestor) | no warning | **no warning** |
| unrelated | no warning | no warning |

With `complete_dir = /mnt/zurg/__magic__` and `dir: ""` (so `OutputRootFolders == ["/mnt/zurg/__magic__"]`):

- Sonarr warns only if a root folder is exactly `/mnt/zurg/__magic__`.
- Radarr warns if a root folder is `/mnt/zurg/__magic__`, `/mnt/zurg`, or `/mnt`.
- Neither warns if a root folder is `/mnt/zurg/__magic__/anything` (output folder as parent).

`PathEquals` (`PathExtensions.cs:55-73`) normalises Unicode, uses `DiskProviderBase.PathStringComparison`
(`OrdinalIgnoreCase` on Windows, `Ordinal` elsewhere — `src/NzbDrone.Common/Disk/DiskProviderBase.cs:17-23`),
and retries with `CleanFilePath()` (trailing-slash-insensitive).

Both versions re-run on `ProviderUpdatedEvent` / `ProviderDeletedEvent` / `ModelEvent<RootFolder>` /
`ModelEvent<RemotePathMapping>`; Radarr adds `[CheckOn(typeof(ProviderAddedEvent<IDownloadClient>))]`
at `:17`. Result is `HealthCheckResult.Warning` with anchor `#downloads-in-root-folder`. The message
interpolates `folder.FullPath` in Sonarr and `folder.Path` in Radarr (`:60` in both). Both silently
swallow `DownloadClientException` and `HttpRequestException` (debug log) and log any other exception
as an error.

### 6.2 `RemotePathMappingCheck` — the local-client path (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs`)

Short-circuit at `:51-54`: if `EnableCompletedDownloadHandling` is off, the check is a no-op.

For every `folder` in `client.GetStatus().OutputRootFolders`:

1. **`!folder.IsValid`** (`:68`) — `OsPath.IsValid` = `_path.IsPathValid(PathValidationType.CurrentOs)`
   (`OsPath.cs:228`). On non-Windows that reduces to `path.StartsWith("/")` plus a
   `Path.GetInvalidPathChars()` scan (`PathExtensions.cs:143-182`, `:403-411`). Errors, in order:
   - `!status.IsLocalhost` → `RemotePathMappingWrongOSPathHealthCheckMessage` (Radarr key:
     `RemotePathMappingCheckWrongOSPath`), anchor `#bad-remote-path-mapping`
   - `_osInfo.IsDocker` → …`BadDockerPath`, anchor `#docker-bad-remote-path-mapping`
   - otherwise → …`LocalWrongOSPath`, anchor `#bad-download-client-settings`
2. **`!_diskProvider.FolderExists(folder.FullPath)`** (`:115`):
   - `_osInfo.IsDocker` → …`DockerFolderMissing`, `#docker-bad-remote-path-mapping`
   - `!status.IsLocalhost` → …`LocalFolderMissing`, `#bad-remote-path-mapping`
   - otherwise → …`GenericPermissions`, `#permissions-error`

**For a local client (`IsLocalhost` true, not Docker) this reduces to exactly two requirements:**
the reported output root folder must be an absolute path *for the OS Sonarr/Radarr runs on*, and it
must **exist on the Sonarr/Radarr host** as a directory. `/mnt/zurg/__magic__` must be visible to the
*arr process, not just to the emulator. **There is no writability check here.**

The event-driven overload (`:178-368`) fires on `EpisodeImportFailedEvent` (Radarr:
`MovieImportFailedEvent`) and, notably, calls `client.GetItems()` again to look up the failed
download's `OutputPath` (`:232`).

No health check requires the output folder to be *writable*. `FolderWritable`
(`DiskProviderBase.cs:126-143` Sonarr / `:127-144` Radarr) — which writes and deletes
`sonarr_write_test.txt` / `radarr_write_test.txt` — is used by
`RootFolderService.Add` (Sonarr `src/NzbDrone.Core/RootFolders/RootFolderService.cs:117-120`) and by
`DownloadClientBase.TestFolder` (`:167-187`), and **`TestFolder` is never called by the SAB client.**

---

## 7. Sonarr vs Radarr — the complete diff

Every fetched file was diffed. Results:

**Byte-identical apart from a UTF-8 BOM on the Sonarr copies** (line numbers therefore match exactly):

`SabnzbdCategory.cs` (no BOM either side — truly identical), `SabnzbdDownloadStatus.cs`,
`SabnzbdPriority.cs`, `SabnzbdFullStatus.cs`, `SabnzbdJsonError.cs`, `SabnzbdQueue.cs`,
`SabnzbdQueueItem.cs`, `SabnzbdHistory.cs`, `SabnzbdHistoryItem.cs`,
`JsonConverters/*.cs` (all three), `Responses/*.cs` (all six),
`src/NzbDrone.Common/Disk/DiskTransferService.cs`, `src/NzbDrone.Core/Download/DownloadEventHub.cs`.

**Differ only by the `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` rename
(no line-count change, same line numbers):**

- `Sabnzbd.cs` — `:40-52` (`AddFromNzbFile`; Radarr's recency test is
  `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` vs Sonarr's `remoteEpisode.IsRecentEpisode()`),
  `:190`, `:251`, `:265/269/273`, `:458`, and every `NzbDroneValidationFailure` field name in
  `TestCategory` (`"TvCategory"` → `"MovieCategory"`).
- `SabnzbdProxy.cs` — `:50`, `:122-124`, `:138-140`.
- `SabnzbdSettings.cs` — defaults `TvCategory = "tv"` vs `MovieCategory = "movies"`;
  `RecentTvPriority`/`OlderTvPriority` vs `RecentMoviePriority`/`OlderMoviePriority`
  (both default to `(int)SabnzbdPriority.Default`). Validator is otherwise identical: `Host` valid,
  `Port` 1–65535, `ApiKey` required when username blank, `Username`/`Password` required when ApiKey
  blank, category `NotEmpty` **as a warning**.
- `UsenetClientBase.cs` — Radarr additionally sets `request.AllowAutoRedirect = true` (`:51`) and
  treats HTTP `410 Gone` like `404` (`:63`) when fetching the NZB from the indexer. **This is about
  the indexer, not about SAB.**
- `DownloadClientBase.cs` — only the literal "Sonarr"/"Radarr" in `TestFolder`'s detail text.
- `RemotePathMappingCheck.cs` — localization key names
  (`RemotePathMapping*HealthCheckMessage` vs `RemotePathMappingCheck*`), `EpisodeImportFailedEvent`
  vs `MovieImportFailedEvent`, plus Radarr's extra `[CheckOn(ProviderAddedEvent<IDownloadClient>)]`.
  **Predicates are identical.**
- `DiskProviderBase.cs` — `FolderWritable` probe file `sonarr_write_test.txt` vs `radarr_write_test.txt`
  (Sonarr `:132`, Radarr `:133`).

**Real behavioural difference — exactly one:**

- **`DownloadClientRootFolderCheck.cs:51`.** Sonarr warns only on `PathEquals`; Radarr also warns when
  a root folder is an ancestor of the output folder. Full table in §6.1.

Everything else — modes, params, JSON shapes, enums, converters, `CheckForError`, `RemoveItem`,
`DeleteItemData`, transfer mode, `DiskTransferService` — is identical. **One emulator serves both.**

Config defaults identical in both: `DownloadClientHistoryLimit = 60`,
`RemoveCompletedDownloads = true`, `RemoveFailedDownloads = true`.

---

## 8. Minimal-but-complete example payloads

Given: `complete_dir = /mnt/zurg/__magic__`; categories `*`, `tv`, `movies`, all with `dir: ""`.
Every response is **HTTP 200** with `Content-Type: application/json`.

Resulting `OutputRootFolders`: `dir: ""` ⇒ `FullPath == complete_dir` ⇒ `/mnt/zurg/__magic__`
for Sonarr (category `tv`) and for Radarr (category `movies`).

### 8.1 `mode=version`

```json
{
  "version": "4.3.3"
}
```

Must be `major.minor.(patch|x)`. `4` ≥ 1 satisfies `TestConnectionAndVersion` (`Sabnzbd.cs:389-392`);
≥ 2.0 also means `GetCategories` would use `fullstatus` rather than `queue.my_home` if `complete_dir`
were relative (it isn't).

### 8.2 `mode=get_config`

```json
{
  "config": {
    "misc": {
      "complete_dir": "/mnt/zurg/__magic__",
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

Why each value:

- `misc` present as an object — **required**, else NRE (§3.4).
- every category has a **string** `dir` — **required**, else NRE at `Sabnzbd.cs:238` and `:462`.
- `dir` does **not** end with `*` — else the "enable job folders" warning (`Sabnzbd.cs:462-469`).
- all three `enable_*_sorting: false` — kills both the `TestCategory` warnings (`Sabnzbd.cs:493-518`)
  and `DownloadClientSortingCheck`. Note that `tv_categories: []` combined with
  `enable_tv_sorting: true` would **fail**, because `ContainsCategory` returns true for empty
  (`Sabnzbd.cs:525-528`, fixture `SabnzbdFixture.cs:647-656`).
- `sorters: []` — `config.Sorters.Any(s => s.is_active && …)` is false (`Sabnzbd.cs:484`).
- `pre_check: false` — skips the `HasVersion(1,1)` round-trip in `TestGlobalConfig` (`Sabnzbd.cs:443`).
- `history_retention_option: "all"` → `RemovesCompletedDownloads == false` (`Sabnzbd.cs:546-547`)
  → no health-check warning.
- `complete_dir` absolute → `IsRooted` true → `mode=fullstatus` / `queue.my_home` never consulted
  (`Sabnzbd.cs:220`).

### 8.3 `mode=fullstatus&skip_dashboard=1`

```json
{
  "status": {
    "completedir": "/mnt/zurg/__magic__",
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

Only `completedir` is read (`SabnzbdFullStatus.cs:9-10`). The wrapper key **must** be `status`
(`Responses/SabnzbdFullStatusResponse.cs:5`).

### 8.4 `mode=addfile` response

```json
{
  "status": true,
  "nzo_ids": ["SABnzbd_nzo_abc12345"]
}
```

`nzo_ids` must be a **non-empty array of strings** (`Sabnzbd.cs:47-52`). `status` is parsed
(`Responses/SabnzbdAddResponse.cs:13`) but never read; keep it `true` so `CheckForError` sees `"True"`.

### 8.5 `mode=queue&start=0&limit=0&category=tv` — one Downloading slot

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

Hard requirements:

- top-level key `queue` (`SabnzbdProxy.cs:129`, `SelectToken("queue")`).
- `slots[].status` ∈ the 16 `SabnzbdDownloadStatus` names, exact case.
- `slots[].mb` / `mbleft` are **megabytes**, invariant-culture decimals. Strings or numbers both work
  (Newtonsoft coerces); real SAB sends strings.
- `slots[].timeleft` is exactly `h:m:s` or `d:h:m:s` — never `""`.
- `slots[].priority` — `"Normal"`, `"High"`, `"Low"`, `"Force"`, `"Paused"`, `"Default"`
  (case-sensitive) or the numeric equivalent. **Never `null`** (NRE).
- `slots[].cat` (not `category`) must equal the client's configured category, or the item is filtered
  out at `Sabnzbd.cs:190`.
- `queue.paused` must be `false` unless you actually mean paused — `true` marks every non-`Force`
  slot as Paused with a null ETA (`Sabnzbd.cs:78-84`).

Resulting `DownloadClientItem`: `TotalSize = 1024 * 1024 * 1024`, `RemainingSize = 512 * 1024 * 1024`,
`RemainingTime = 00:08:32`, `Status = Downloading`, `CanBeRemoved = CanMoveFiles = true`.

### 8.6 `mode=history&start=0&limit=60&category=tv` — one Completed and one Failed slot

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
        "storage": "/mnt/zurg/__magic__/Some.Show.S01E02.1080p.WEB-DL.H264-GRP",
        "path": "/mnt/zurg/__magic__/Some.Show.S01E02.1080p.WEB-DL.H264-GRP",
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

Hard requirements:

- top-level key `history` (`SabnzbdProxy.cs:145`).
- `slots[].bytes` is **BYTES** (a JSON number → `long`). Do not send MB here — the queue uses MB, the
  history uses bytes (`Sabnzbd.cs:72-73` vs `:128`).
- `slots[].category` (not `cat`).
- `slots[].storage` = the job folder itself; it becomes `OutputPath`, and for a Completed item it is
  what `DeleteItemData` recursively deletes (§5.3). It must be an absolute path valid for the OS
  Sonarr/Radarr runs on and must exist there (`RemotePathMappingCheck`, §6.2).
- `slots[].status` exact-case; `Deleted` items are dropped entirely (`Sabnzbd.cs:116-119`).
- `fail_message` exactly `"Unpacking failed, write error or disk is full?"` downgrades a Failed item
  to `Warning` instead of `Failed` (`Sabnzbd.cs:140-144`) — use something else for a genuine failure.
- Radarr: `category` must be `movies` (or whatever is configured) and `name` should parse as a movie.

### 8.7 Error response (any mode)

```json
{
  "status": false,
  "error": "API Key Incorrect"
}
```

**HTTP 200.** `status` may be the boolean `false` or the string `"false"`; both satisfy
`SabnzbdJsonError.Failed` (`SabnzbdJsonError.cs:10-11`). The client raises
`DownloadClientException("Error response received from SABnzbd: API Key Incorrect")`
(`SabnzbdProxy.cs:244`), which `TestAuthentication` recognises (`Sabnzbd.cs:424`).
Use `"API Key Required"` when no key was supplied (`Sabnzbd.cs:429`). Any other `error` string is
reported verbatim but not classified.

---

## 9. Implementation checklist (12 points)

1. One route: `GET|POST {UrlBase}/api`, dispatch on `mode`. **Always HTTP 200, always JSON.**
2. Implement `version`, `get_config`, `queue` (read + `name=delete`), `history` (read + `name=delete`),
   `addfile`, `fullstatus`. Optionally `retry` (dead code today). `get_cats` is never called.
3. Accept auth as either `apikey=` **or** `ma_username=`+`ma_password=`. Reject with 200 +
   `{"status":false,"error":"API Key Incorrect"}` / `"API Key Required"` — never a 401/403.
4. Honour `category=` on `queue`/`history` (the clients also filter client-side by exact string match,
   `Sabnzbd.cs:190`).
5. `queue` sizes in **MB** (`mb`, `mbleft`); `history` sizes in **BYTES** (`bytes`). Never mix them up.
   Queue uses `cat`, history uses `category`.
6. `timeleft` is always `h:m:s` or `d:h:m:s`, never empty, never absent-as-empty-string.
   No date field is parsed anywhere, so epoch fields are free-form.
7. `status` values must come from the 16-member `SabnzbdDownloadStatus` list, exact case (an unknown
   name throws and kills the whole queue/history call). `priority` must be a `SabnzbdPriority` name
   (exact case) or its integer; **never `null`** (NRE in the converter).
8. `config.misc` must be an object; every category must carry a **non-null string `dir`** that does
   not end in `*`. `categories`/`sorters`/`servers` may be null or absent, `misc` and `dir` may not.
9. Keep `enable_tv_sorting`, `enable_movie_sorting`, `enable_date_sorting` and `pre_check` all `false`,
   and `history_retention_option: "all"`, to keep the connection test and all health checks clean.
10. `storage` on a Completed history slot = the job folder. Expect the *arr to `rm -rf` it after a
    successful import (default settings), and expect the media file to be **moved** out of it first.
    If the magic directory is read-only the delete fails silently (warning log only), but the *move*
    of the imported file must still succeed or the import fails outright (§5.5).
11. Do not place any *arr root folder at or above `/mnt/zurg/__magic__` if you want Radarr's
    `DownloadClientRootFolderCheck` to stay quiet (Sonarr only cares about exact equality).
12. `/mnt/zurg/__magic__` must exist as a directory **on the Sonarr/Radarr host**, not just where the
    emulator runs, or `RemotePathMappingCheck` raises an error. It does not need to be writable.
