# qBittorrent Web API contract as consumed by Sonarr and Radarr (develop)

المصدر المعتمد: ملفات تم جلبها من `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...` ومن `qbittorrent/qBittorrent/master` بتاريخ **2026-08-27**. كل أرقام الأسطر أدناه قُرئت من تلك الملفات.

هذا المستند هو النظير الخاص بالتورنت لـ [sabnzbd-client-contract.md](sabnzbd-client-contract.md). ذلك المستند يوثّق *لماذا* يرد `internal/sabnzbd` بالأشكال التي يرد بها؛ أما هذا فهو المواصفة التي يجب أن يلبّيها شيم qBittorrent *قبل* كتابته، حتى تعمل عملية الإضافة (grab) والاستطلاع (poll) والاستيراد **كنقل** (move) والتنظيف بعد الاستيراد في العميلين معًا. وحيث يتشارك العميلان في الآليات (طبقة HTTP، ومُسلسِل JSON، و`DiskTransferService`، وفحوصات الصحة)، يستشهد هذا المستند بالأسطر نفسها ويحيل إليها بدلًا من تكرار التحليل.

ما لم يذكر قسم خلاف ذلك، **ملفات qBittorrent في المستودعين متطابقة باستثناء إعادة تسمية `Tv*` ← `Movie*`**، و:

| الملف | أرقام الأسطر |
|---|---|
| `QBittorrent.cs` (746 سطرًا في المستودعين) | **تتطابق سطرًا بسطر** |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **متطابقة بايتًا بايت**، وتتطابق سطرًا بسطر |
| `QBittorrentSettings.cs` (91 سطرًا في المستودعين) | تتطابق سطرًا بسطر |
| `QBittorrentProxyV2.cs`, `QBittorrentProxyV1.cs` | في Sonarr سطر فارغ عند السطر 13 غير موجود في Radarr (تحققنا: السطر `:12` في Sonarr هو تعليق `// API https://…`، والسطر `:13` فارغ، والسطر `:14` هو `public class QBittorrentProxyV2`؛ أما تصريح الصف في Radarr فهو في السطر `:13`). **السطر N في Sonarr = السطر N−1 في Radarr لكل N ≥ 14.** |
| `QBittorrentProxySelector.cs` | الشيء نفسه، ابتداءً من السطر 3 |
| `QBittorrentFixture.cs` | أُعيد ترتيبه ولم يُزَح، لذا يُستشهد به لكل مستودع على حدة |

المسارات هي `src/NzbDrone.Core/Download/Clients/QBittorrent/...` في المستودعين. الاستشهادات أدناه أرقام أسطر **Sonarr** ما لم يُذكر خلاف ذلك. الفرق الكامل موجود في §9.

لا شيء هنا تكهّن حول qBittorrent نفسه: كل ادعاء يصف ما يفعله *العميل*. وحيث يتعلق الادعاء بسلوك qBittorrent نفسه، يستشهد بـ `qbittorrent/qBittorrent` في فرع master، وحيث يتعلق بسلوك وقت تشغيل .NET أو Newtonsoft يُذكر ذلك صراحةً.

---

## 0. قواعد على مستوى النقل (هذه أول ما يسبب المشاكل) {#0-transport-level-rules-these-bite-first}

### 0.1 يختار العميل v1 أو v2 قبل أن يفعل أي شيء آخر {#01-the-client-picks-v1-or-v2-before-it-does-anything-else}

`QBittorrentProxySelector.FetchProxy` (`QBittorrentProxySelector.cs:80-95`):

```csharp
if (_proxyV2.IsApiSupported(settings)) { return Tuple.Create(_proxyV2, _proxyV2.GetApiVersion(settings)); }
if (_proxyV1.IsApiSupported(settings)) { return Tuple.Create(_proxyV1, _proxyV1.GetApiVersion(settings)); }
throw new DownloadClientException("Unable to determine qBittorrent API version");
```

`QBittorrentProxyV2.IsApiSupported` (`QBittorrentProxyV2.cs:28-70`) يُرسل طلب **بدون مصادقة**
`GET /api/v2/app/webapiVersion` مع `SuppressHttpError = true`، ويقرّر حسب الرد:

| الرد | النتيجة |
|---|---|
| `404` | ليس v2 ← يتم الانتقال إلى v1 |
| `403` | **v2 مدعوم** (`:44-47`)، وهذا هو الرد "لم تسجّل الدخول بعد" |
| `401` | `DownloadClientException("Failed to connect to qBittorrent. Check your settings and qBittorrent configuration.")` (`:49-52`) |
| أي `>= 400` آخر | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` (`:54-57`) |
| `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to qBittorrent, certificate validation failed.")` (`:63-66`) |
| `200` | v2 مدعوم |

`QBittorrentProxyV1.IsApiSupported` (`QBittorrentProxyV1.cs:27-59`) يعمل بالطريقة نفسها ضد
`GET /version/api`. لاحظ **عدم وجود `/api/v2` في البداية**، والرد 401 *لا* يُعامَل بشكل خاص هنا.

الزوج `(proxy, version)` يُخزَّن مؤقتاً لمدة **10 دقائق** بمفتاح `{Host}_{Port}`
(`QBittorrentProxySelector.cs:68-78`). `GetProxy(settings, force: true)` يحذفه من الذاكرة المؤقتة، وهذا ما يفعله اختبار الاتصال تماماً (`QBittorrent.cs:435`، `:519`)، والذي تتحقق منه الـ fixture (Sonarr `QBittorrentFixture.cs:986-998`، Radarr `:984-996`).

**يجب أن ترد طبقة الـ shim على `/api/v2/app/webapiVersion` ولا تكشف مسارات v1 أبداً.** v1 هي واجهة ما قبل الإصدار 4.1 (`/version/api`، `/query/torrents`، `/command/download`، …)، وهي عبء لا فائدة منه لأي تطبيق جديد. ولا يمكنها تلبية مسار الاستيراد أصلاً، لأن `GetLabels` يرمي `NotSupportedException("qBittorrent api v1 does not support getting all torrent categories")` (`QBittorrentProxyV1.cs:236-239`)، و`SetTorrentSeedingConfiguration` لا تفعل شيئاً (`:241-244`). بقية هذا المستند يخص API v2 فقط، ويسرد القسم §1.17 خريطة مسارات v1 للاكتمال.

### 0.2 شكل الرابط {#02-url-shape}

`QBittorrentProxyV2.BuildRequest` (`QBittorrentProxyV2.cs:341-359`):

```csharp
var requestBuilder = new HttpRequestBuilder(settings.UseSsl, settings.Host, settings.Port, settings.UrlBase)
{
    LogResponseContent = true,
    StoreRequestCookie = false
};
```

- عنوان URL الأساسي: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-65`)
  = `{http|https}://{Host}:{Port}{UrlBase}`؛ يُضاف `/` في بداية `UrlBase` إذا كانت غير موجودة.
- تقوم `Resource("/api/v2/…")` (`HttpRequestBuilder.cs:244-256`) بحذف `/` الأولى وإلحاق الباقي، بحيث يصبح عنوان URL الكامل هكذا: `{scheme}://{host}:{port}{urlBase}/api/v2/{group}/{method}`.
- **لا توجد ترويسة `Accept`.** لا تستدعي `BuildRequest` الدالة `.Accept(...)` أبدًا، ودالة الإنشاء (constructor) الخاصة بـ `HttpRequest` لا تضبط `Headers.Accept` إلا عندما يكون `httpAccept != null` (`src/NzbDrone.Common/Http/HttpRequest.cs:14,30-32`). لذلك لا تعتمد على `Accept` كشرط.
- `StoreRequestCookie = false`: يتم إدارة مخزن الكوكيز (cookie jar) بواسطة الوكيل (proxy)، وليس بواسطة طبقة HTTP.

### 0.3 GET مع query مقابل POST مع form — ومتى يتحول الـ form إلى multipart {#03-get-with-query-vs-post-with-form--and-when-the-form-becomes-multipart}

تستخدم الاستدعاءات للقراءة فقط `AddQueryParam` (`HttpRequestBuilder.cs:306-317`) مع طلب GET. أما الاستدعاءات التي تُعدّل البيانات فتستخدم
`.Post()` مع `AddFormParameter` / `AddFormUpload`.

تختار `ApplyFormData` (`HttpRequestBuilder.cs:150-242`) ترميز البيانات:

```csharp
var shouldSendAsMultipart = FormData.Any(v => v.ContentType != null || v.FileName != null || v.ContentData.Length > 1024);
```

- أي `AddFormUpload` (الذي يضبط `FileName` و`ContentType`) يفرض **`multipart/form-data`**
  (`:379-395`، `:220`).
- **أي قيمة حقل واحدة أطول من 1024 بايت تفرض multipart أيضًا** (`:162`). رابط magnet فيه قائمة طويلة من المتتبعات (trackers) يتجاوز هذا الحد، لذلك يصل `POST /api/v2/torrents/add` بصيغة `application/x-www-form-urlencoded` *أو* `multipart/form-data` حسب رابط الـ magnet.
  **يجب على الطبقة الوسيطة (shim) أن تحلل الصيغتين في هذا المسار.**
- غير ذلك: `application/x-www-form-urlencoded`، وتُرمَّز القيم باستخدام
  `Uri.EscapeDataString(Encoding.UTF8.GetString(...))` (`:230`).

كاتب multipart مكتوب يدويًا (`:164-227`) ويكتب `Content-Disposition: form-data; name="…"` (مع `; filename="…"` وسطر `Content-Type:` للملفات المرفوعة)، ثم سطرًا فارغًا، ثم البايتات الخام، ثم `\r\n`. الـ boundary هو `-----------------------------{ticks:x14}` (`:166`).

**تنسيق القيم المنطقية فخ.** يخزن `AddFormParameter` القيمة باستخدام `Convert.ToString(value, CultureInfo.InvariantCulture)` (`HttpRequestBuilder.cs:373`)، و`Convert.ToString(bool)` في .NET يُنتج **`"True"` / `"False"`، بحرف كبير**. لذلك فإن `request.AddFormParameter("stopped", false)` (`QBittorrentProxyV2.cs:258`) يرسل `stopped=False` على الشبكة، وليس `stopped=false`. يتعامل qBittorrent الحقيقي مع ذلك لأن `Utils::String::parseBool` (`src/base/utils/string.cpp:108-116`) يقارن دون النظر إلى حالة الأحرف. **يجب على الـ shim أن يقبل `True`/`False` إلى جانب `true`/`false`.** وحين يكتب العميل النص يدويًا فإنه يستخدم الحروف الصغيرة، فقيمة `deleteFiles` هي `"true"` (`QBittorrentProxyV2.cs:198`)، وقيمة `value` في `setForceStart` هي `"true"`/`"false"` (`:337`)، لذا تظهر الصيغتان فعلاً.

تمر الأرقام عبر المسار نفسه الخاص بـ invariant culture، لذلك يستخدم `ratioLimit=1.5` دائمًا النقطة `.` كفاصل عشري (`QBittorrentProxyV2.cs:234`، `HttpRequestBuilder.cs:373`).

### 0.4 المصادقة — ثلاث طبقات، وكلها يمكن أن تكون فعالة في وقت واحد {#04-authentication--three-layers-all-of-which-can-be-live-at-once}

`BuildRequest` (`QBittorrentProxyV2.cs:349-356`):

```csharp
if (settings.ApiKey.IsNotNullOrWhiteSpace())
    requestBuilder.Headers["Authorization"] = $"Bearer {settings.ApiKey}";
else if (settings.Username.IsNotNullOrWhiteSpace() || settings.Password.IsNotNullOrWhiteSpace())
    requestBuilder.NetworkCredential = new BasicNetworkCredential(settings.Username, settings.Password);
```

1. **مفتاح API** ← `Authorization: Bearer <key>` في كل طلب، و`ProcessRequest` يسلك مسارًا مختصرًا لا يسجّل الدخول أبدًا (`:371-395`). يمنع `QBittorrentSettingsValidator` وضع اسم المستخدم وكلمة المرور مع مفتاح API (`QBittorrentSettings.cs:16-21`).
2. **اسم المستخدم/كلمة المرور** ← `BasicNetworkCredential`، الذي يحوّله `ManagedHttpDispatcher` إلى ترويسة `Authorization: Basic base64(user:pass)` **استباقية** في كل طلب، بما في ذلك `auth/login` نفسه (`src/NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:81-89`، والتعليق: "Manually set header to avoid initial challenge response").
3. **جلسة ملف تعريف الارتباط (Cookie)** ← `AuthenticateClient` (`QBittorrentProxyV2.cs:430-494`).

`AuthenticateClient`، بالضبط:

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

نتائج ذلك بالنسبة إلى الطبقة الوسيطة (shim):

- `POST /api/v2/auth/login`، بجسم الطلب `username=…&password=…`، وبنوع المحتوى `application/x-www-form-urlencoded`.
- أجب بـ **HTTP 200** مع جسم يساوي تمامًا `Ok.` وترويسة `Set-Cookie: SID=…`، وهو الشكل الذي تستخدمه نسخة qBittorrent الحقيقية (الويكي، *Login*: "Upon success, the response will contain a cookie with your SID").
- **الجسم الفارغ مقبول أيضًا** (`:479` يتجاوز الفحص عبر `IsNotNullOrWhiteSpace`). أما أي شيء آخر، مثل `"Fails."` أو `"ok"` أو JSON، فيُعدّ فشلًا في المصادقة. نسخة الـ proxy الأولى (v1) أكثر صرامة وتطلب `Ok.` بالضبط (`QBittorrentProxyV1.cs:371`).
- عند حدوث خطأ HTTP من `auth/login`: 401 أو 403 ← `DownloadClientAuthenticationException`، وأي رمز آخر ← `DownloadClientException` (`:463-473`). أما `WebException` فيتحول إلى `DownloadClientUnavailableException`.
- يُخزَّن ملف تعريف الارتباط مؤقتًا لكل `{baseUrl}:{user}:{pass}` طوال عمر مدخل الذاكرة المؤقتة للعملية، ولا يُجدَّد إلا عندما يعود أي طلب برمز 403 (§0.5).
- **لا يُرسَل `Referer` ولا `Origin` أبدًا.** يوصي الويكي مستخدمي الـ API بضبطهما ("Note: Set `Referer` or `Origin` header to the exact same domain and port as used in the HTTP query `Host` header")، و Sonarr لا يفعل ذلك. يجب ألا تشترط الطبقة الوسيطة وجودهما.
- إذا **لم تُضبط أي بيانات اعتماد إطلاقًا**، يعود `AuthenticateClient` فورًا ولا يرسل شيئًا: لا تسجيل دخول، ولا ملف تعريف ارتباط، ولا `Authorization`. الطبقة الوسيطة غير المصادَقة تعمل.

### 0.5 أي حالات HTTP تُعامل كأخطاء {#05-which-http-statuses-are-treated-as-errors}

`HttpClient.Execute` (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`) ترمي استثناءً عندما يكون `response.HasHttpError` — أي `(int)StatusCode >= 400` (`src/NzbDrone.Common/Http/HttpResponse.cs:54`) — ما لم يكن `SuppressHttpError` مفعّلاً أو كانت الحالة موجودة في `SuppressHttpErrorStatusCodes`. الحالة 429 تتحول إلى `TooManyRequestsException` (`:115`)، وأي حالة أخرى إلى `HttpException` (`:119`).

ثم تلفّ `QBittorrentProxyV2.ProcessRequest` (`:369-428`) هذا الاستثناء. هناك مساران مختلفان:

**مسار مفتاح الـ API** (`:371-395`):

| الحالة | النتيجة |
|---|---|
| 401, 403 | `DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.")` |
| أي حالة أخرى `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` |
| أي استثناء آخر | `DownloadClientException("Failed to connect to qBittorrent, please check your settings.")` |

**مسار الكوكي** (`:397-427`):

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

- **الحالة 403 تعني "انتهت الجلسة، سجّل الدخول من جديد"** — يُتجاهل هذا الخطأ مرة واحدة، فيعيد العميل تسجيل الدخول ثم يعيد المحاولة. هذه هي الحلقة نفسها التي تنتج عن انتهاء جلسة qBittorrent نفسها، ويمكن لـ shim أن يستخدمها بالطريقة نفسها.
- **طلب إعادة المحاولة يُبنى من الـ builder**، والـ builder لا يحمل `SuppressHttpErrorStatusCodes` — فهذا الحقل مضبوط على *الطلب* في `:401`، وليس على الـ builder. لذلك الحالة 403 الثانية ترمي `HttpException` وتظهر على أنها `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` — **وليست** فشل مصادقة. أي shim يرد بالحالة 403 دائماً سيُظهر خطأ اتصال مربكاً في الواجهة، وليس "Authentication Failure".
- إذا لم تكن هناك بيانات اعتماد مضبوطة، فإن محاولة إعادة تسجيل الدخول في `:411` ترمي `DownloadClientAuthenticationException` فوراً (`:434-437`).

**يجب أن يكون كل استدعاء ناجح بحالة HTTP 200 ومع الجسم بالضبط كما يتوقعه العميل.** لا يوجد أي غلاف أخطاء بصيغة JSON في هذا الـ API؛ على عكس SAB، الأخطاء هنا تأتي على شكل حالات HTTP.

### 0.6 إعدادات الـ Deserializer {#06-deserializer-settings}

تمر كل حمولات qBittorrent عبر `NzbDrone.Common.Serializer.Json` (`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`)، وهي **Newtonsoft**، وهي نفس النسخة التي يستخدمها عميل SAB. لذلك ينطبق [sabnzbd-client-contract.md §0.3](sabnzbd-client-contract.md) حرفيًا:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

وهذا ما يعنيه بالنسبة لنماذج qBittorrent تحديدًا:

| عضو النموذج | يرتبط بـ | السبب |
|---|---|---|
| `QBittorrentTorrent.Hash/Name/Size/Progress/Eta/State/Label/Category/Ratio` | `hash`، `name`، `size`، `progress`، `eta`، `state`، `label`، `category`، `ratio` | محلل camelCase؛ كما أن Newtonsoft يطابق الأسماء بغض النظر عن حالة الأحرف |
| `SavePath`، `ContentPath`، `RatioLimit`، `SeedingTime`، `SeedingTimeLimit`، `InactiveSeedingTimeLimit`، `LastActivity` | `save_path`، `content_path`، `ratio_limit`، `seeding_time`، `seeding_time_limit`، `inactive_seeding_time_limit`، `last_activity` | `[JsonProperty]` صريح (`QBittorrentTorrent.cs:24-45`) |
| `QBittorrentLabel.Name/SavePath` | `name`، `savePath` | **بدون** `[JsonProperty]`، لذا يستخدم محلل camelCase. تستخدم `torrents/categories` في qBittorrent فعلًا camelCase هنا، على عكس باقي الواجهات |
| `QBittorrentPreferences.*` | كلها snake_case صريحة عبر `[JsonProperty]` (`QBittorrentPreferences.cs:16-44`) | |
| `QBittorrentMaxRatioAction` | `max_ratio_act` | لا يوجد محول خاص بكل خاصية، لذا يُطبّق `StringEnumConverter` العام. قيمة `AllowIntegerValues` الافتراضية هي true، لذلك **أرسل الرقم الصحيح**، كما يفعل qBittorrent الحقيقي. إذا أرسلت نصًا فيجب أن يكون بصيغة camelCase (`"pause"`، `"remove"`)، واسم غير معروف يسبب استثناءً |

ينطبق `NullValueHandling.Ignore` أيضًا عند **القراءة**. إذا كانت قيمة JSON هي `null` تبقى الخاصية على القيمة التي تُعيَّن في المُنشئ. ومع القيم الافتراضية المُعلنة في النماذج، فإن الحقل **الغائب أو null** ليس مثل الصفر:

| الحقل | القيمة الافتراضية إذا كان غائبًا/null | المرجع |
|---|---|---|
| `ratio_limit` | `-2f` | `QBittorrentTorrent.cs:33` |
| `seeding_time_limit` | `-2` | `:39` |
| `inactive_seeding_time_limit` | `-2` | `:42` |
| `seeding_time` | `null` (`long?`) | `:36` |
| `queueing_enabled` | **`true`** | `QBittorrentPreferences.cs:41` |
| كل ما عدا ذلك | القيمة الافتراضية لـ CLR (`0`، `false`، `null`) | |

`Eta` من نوع `System.Numerics.BigInteger` (`QBittorrentTorrent.cs:17`، مع التعليق "QBit contains a bug exceeding ulong limits")، وملف الاختبار في Sonarr يثبّت القيمة `18446744073709335000` على أنها قابلة للتحليل (Sonarr `QBittorrentFixture.cs:974-984`، Radarr `:973-982`).

تُعيد `Json.Deserialize<T>` رمي `JsonReaderException` برسالة أوضح (`Json.cs:39-50`). لا يستخدم أي من استدعاءات الوكيل لـ qBittorrent `TryDeserialize`، لذلك **إذا كان الجسم مشوّهًا أو بشكل خاطئ فإنه يسبب استثناءً يخرج من الوكيل** ويتحول إلى استثناء غير معالج في مكان الاستدعاء. بالنسبة إلى `GetItems()` هذا يوقف الاستطلاع بالكامل.

### 0.7 كل بوابة `version >=` في مكان واحد {#07-every-version--gate-in-one-place}

`ProxyApiVersion` هو `_proxySelector.GetApiVersion(Settings)` (`QBittorrent.cs:50`)، أي القيمة المخزّنة مؤقتاً لـ `app/webapiVersion`. البوابات:

| البوابة | الموقع | التأثير تحت العتبة |
|---|---|---|
| `>= 1.5` | `QBittorrent.cs:436` | يفشل الاختبار: "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| `>= 1.6` | `:445` | يفشل الاختبار إذا كانت هناك فئة مُعدّة: "Category is not supported" |
| `>= 2.0` | `:379` (`GetStatus`)، `:520` (`TestCategory`) | لا يُقرأ `savePath` الخاص بالفئة، ولا يتم فحص الفئات أو إنشاؤها |
| `>= 2.6.1` | `:314` | لا يُؤخذ `OutputPath` من `content_path`؛ بل تمر `GetImportItem` على `torrents/files` بدلاً من ذلك (§4.2) |
| `>= 2.8.1` | `:79`، `:136` | لا يمكن إضافة حدود المشاركة مع `torrents/add`؛ بل تُطبَّق لاحقاً باستخدام `torrents/setShareLimits` |
| `>= 2.11.0` | `QBittorrentProxyV2.cs:253` | يُرسل `torrents/add` القيمة `paused=` بدلاً من `stopped=` |

تحتاج `Version.Parse` (`QBittorrentProxyV2.cs:75`) إلى `major.minor` على الأقل. فالرقم `"2"` وحده يُسبب `FormatException`، وهذا الاستثناء يُطلق خارج كل كتلة `try` في الـ proxy، فيخرج من `GetApiVersion` بالكامل. أدخل شيئاً مثل `2.11.2`.

**القيمة الموصى بها لطبقة وسيطة (shim): `2.11.2`.** تتجاوز هذه القيمة كل البوابات، وتضع `content_path` على مسار `torrents/info` (وهو مسار الاستيراد الوحيد المعقول)، وتختار صيغة `stopped=` الخاصة بـ qBittorrent 5.x عند الإضافة.

## 1. كل نقطة نهاية، بالترتيب الذي يستدعيها به العميل {#1-every-endpoint-in-the-order-the-client-calls-them}

الواجهة: `IQBittorrentProxy` (`QBittorrentProxySelector.cs:9-30`). التنفيذ:
`QBittorrentProxyV2`. كل نقطة استدعاء في `QBittorrent.cs` مدرجة في `:49-741`.

### 1.1 `GET /api/v2/app/webapiVersion` — `GetApiVersion` (`QBittorrentProxyV2.cs:72-78`)

**الطلب:** لا توجد معاملات. يُرسل أولاً بدون مصادقة (كاختبار أولي، §0.1)، ثم يُرسل بعد ذلك مع المصادقة.

**الاستجابة:** **نص عادي**، وهو سلسلة تمثل رقم الإصدار، ويحلّلها `Version.Parse`. ليست JSON، ولا توجد علامات اقتباس.

**يُستدعى من:** اختبار الوكيل (`:31`)، و`GetItems` (`QBittorrent.cs:220`)، و`GetStatus` (`:374`)،
و`TestConnection` (`:435`)، و`TestCategory` (`:519`)، والاستدعاء الذي يسهل نسيانه، وهو `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:253`). وهذا يعني أن **كل طلب `torrents/add` يسبقه طلب `app/webapiVersion` خاص به** كلما كانت الحالة الأولية Start أو Stop، أي دائماً ما لم يختر المستخدم Force Start.

### 1.2 `GET /api/v2/app/version` — `GetVersion` (`QBittorrentProxyV2.cs:80-87`)

الاستجابة: نص عادي، مع حذف الحرف `v` من بدايتها (`:83`). التعليق: `// eg "4.2alpha"`.

**لا يُستدعى أبدًا.** وهو موجود في الواجهة (`QBittorrentProxySelector.cs:13`) دون أي استدعاء له في
`QBittorrent.cs` (تم التحقق من ذلك عبر كل مراجع `Proxy.`/`_proxySelector.` في `:49-741`). نفّذه على أي حال، فهذا لا يكلّف شيئًا، وسيلجأ إليه الشخص الذي يعبث بالطبقة الوسيطة.

### 1.3 `POST /api/v2/auth/login`

مذكور في §0.4. النموذج: `username`، `password`. الاستجابة `200` + `Ok.` + `Set-Cookie: SID=…`.

### 1.4 `GET /api/v2/app/preferences` — `GetConfig` (`QBittorrentProxyV2.cs:89-95`)

الطلب: بلا معاملات. الاستجابة: كائن JSON واحد يُحوَّل إلى `QBittorrentPreferences`.

**كل مفتاح يقرؤه العميل** (`QBittorrentPreferences.cs:14-45`). لا يُنظر إلى أي شيء آخر في الجسم، والمفاتيح الزائدة تُتجاهل:

| مفتاح JSON | C# | النوع | يقرؤه |
|---|---|---|---|
| `save_path` | `SavePath` | `string` | `GetStatus` ← `OutputRootFolders` (`QBittorrent.cs:377`) |
| `max_ratio_enabled` | `MaxRatioEnabled` | `bool` | `HasReachedSeedLimit` (`:639`)، و`RemovesCompletedDownloads` (`:415`) |
| `max_ratio` | `MaxRatio` | `float` | `HasReachedSeedLimit` (`:641`) |
| `max_seeding_time_enabled` | `MaxSeedingTimeEnabled` | `bool` | `HasReachedSeedingTimeLimit` (`:663`)، و`RemovesCompletedDownloads` (`:415`) |
| `max_seeding_time` | `MaxSeedingTime` | `long`، **بالدقائق** | `:665`، و`:415` |
| `max_inactive_seeding_time_enabled` | `MaxInactiveSeedingTimeEnabled` | `bool` | `HasReachedInactiveSeedingTimeLimit` (`:727`) |
| `max_inactive_seeding_time` | `MaxInactiveSeedingTime` | `long`، **بالدقائق** | `:729` |
| `max_ratio_act` | `MaxRatioAction` | enum يُرسل كعدد صحيح: `Pause=0, Remove=1, EnableSuperSeeding=2, DeleteFiles=3` (`QBittorrentPreferences.cs:5-11`) | `RemovesCompletedDownloads` (`:415`) |
| `queueing_enabled` | `QueueingEnabled` | `bool`، **القيمة الافتراضية `true`** | `TestPrioritySupport` (`:572`) |
| `dht` | `DhtEnabled` | `bool` | `AddFromMagnetLink` (`:73`)، وفرع `metaDL` (`:288`) |

تستدعيه: `AddFromMagnetLink` (`:73`)، و`GetItems` (`:221`)، و`GetStatus` (`:375`)، و`TestConnection` (`:467`)، و`TestPrioritySupport` (`:570`). **لا يُخزَّن مؤقتاً**، لذلك يُجلب في كل استطلاع.

الدالة `RemovesCompletedDownloads` (`QBittorrent.cs:412-416`) هي العلامة المشتقة:

```csharp
var minimumRetention = 60 * 24 * 14; // 14 days in minutes
return (config.MaxRatioEnabled || (config.MaxSeedingTimeEnabled && config.MaxSeedingTime < minimumRetention))
    && (config.MaxRatioAction == QBittorrentMaxRatioAction.Remove || config.MaxRatioAction == QBittorrentMaxRatioAction.DeleteFiles);
```

تُغذّي هذه العلامة كلاً من اختبار الاتصال (`:468`) وفحص الصحة `DownloadClientRemovesCompletedDownloadsCheck` (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:44-53`). مع `max_ratio_enabled: false` و`max_seeding_time_enabled: false` تكون القيمة false مهما كان `max_ratio_act`، لكن أرسل `max_ratio_act: 0` على أي حال.

### 1.5 `GET /api/v2/torrents/categories` — `GetLabels` (`QBittorrentProxyV2.cs:221-225`)

الطلب: بدون معاملات.

الاستجابة: **كائن** JSON، `{"<name>": {"name": "...", "savePath": "..."}}`، يُفكّك إلى
`Dictionary<string, QBittorrentLabel>`. لاحظ أن **الحقل `savePath` بصيغة camelCase**، حسب §0.6 ومثال *Get all categories* في الويكي. المصفوفة هنا ستؤدي إلى خطأ.

اقرأ لأمرين:

1. `TestCategory` (`QBittorrent.cs:525-553`): عضوية المفتاح فقط (§6.3).
2. `GetStatus` (`:379-402`): يصبح `savePath` الخاص بالفئة المُعدّة هو مجلد الجذر لمخرجات عميل التنزيل:

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

إذا كان `savePath` **نسبيًا**، فإنه يُلحَق بالقيمة العامة `save_path`. أما إذا كان **مطلقًا** (rooted)، فإنه يحل محلها. يتم تحويل `savePath` الذي يبدأ بـ `//` إلى مسار UNC بشرطات مائلة عكسية. يثبّت ملف fixture في Sonarr القيمة `"//server/store/downloads"` إلى `\\server\store\downloads` (Sonarr `QBittorrentFixture.cs:563-589`، Radarr `:562-588`). **لا تُخرج أبدًا `//` في البداية.**

أبسط إجابة صحيحة هي `"savePath": ""`، وهذا يُبقي مجلد الجذر على `save_path` العام.

### 1.6 `POST /api/v2/torrents/createCategory` — `AddLabel` (`QBittorrentProxyV2.cs:213-219`)

الشكل: `category=<name>`. **لا يُرسَل `savePath`** — العميل لا يضبط أبدًا مسار حفظ للفئة.
يُتجاهل نص الاستجابة؛ الشيء الوحيد المهم هو أن تكون الحالة غير خطأ.

تُستدعى هذه الدالة فقط من `TestCategory` (`QBittorrent.cs:529`، `:543`)، وذلك عندما تكون الفئة مفقودة.
لا يتم استدعاء `torrents/editCategory` و`torrents/removeCategories` **أبدًا**.

### 1.7 `POST /api/v2/torrents/add` — `AddTorrentFromUrl` / `AddTorrentFromFile`

`AddTorrentFromUrl` (`QBittorrentProxyV2.cs:146-166`): حقل النموذج **`urls`** = الـ magnet URI.

`AddTorrentFromFile` (`:168-188`): رفع نموذج باسم **`torrents`**، واسم الملف
`{CleanFileName(release title)}.torrent` (`TorrentClientBase.cs:199`)،
`Content-Type: application/octet-stream` (`HttpRequestBuilder.cs:379`).

كلتا الدالتين تضيفان بعد ذلك `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:243-284`):

| حقل النموذج | القيمة | الشرط | السطر |
|---|---|---|---|
| `category` | `Settings.TvCategory` / `MovieCategory` | الفئة غير فارغة | `:245-248` |
| `stopped` (webapi `>= 2.11.0`) أو `paused` (أدنى من ذلك) | `False` لـ Start، و`True` لـ Stop | `InitialState` هو Start أو Stop — **Force Start لا يُرسل أيًا منهما** | `:251-264` |
| `sequentialDownload` | `True` | إعداد `SequentialOrder` مفعّل | `:266-269` |
| `firstLastPiecePrio` | `True` | إعداد `FirstAndLast` مفعّل | `:271-274` |
| `contentLayout` | `"Original"` أو `"Subfolder"` | إعداد `ContentLayout` هو Original أو Subfolder؛ **Default لا يُرسل شيئًا** | `:276-283` |

وعندما تكون حدود المشاركة مُعدّة *وفي الوقت نفسه* webapi بإصدار `>= 2.8.1` (`QBittorrent.cs:79`، `:136`)، تُضاف `AddTorrentSeedingFormParameters(request, seedConfiguration)` (`QBittorrentProxyV2.cs:227-241`):

| حقل النموذج | القيمة | الشرط |
|---|---|---|
| `ratioLimit` | `seedConfiguration.Ratio` أو `-2` | فقط عندما لا تكون `-2` (`:232`) |
| `seedingTimeLimit` | `seedConfiguration.SeedTime.TotalMinutes` أو `-2` | فقط عندما لا تكون `-2` (`:237`) |

**كل شيء آخر يوثّقه الويكي لـ `torrents/add` لا يُرسل أبدًا**: لا `savepath`، ولا `cookie`، ولا `tags`، ولا `skip_checking`، ولا `root_folder`، ولا `rename`، ولا `upLimit`، ولا `dlLimit`، ولا `autoTMM`. لا يوجد معامل `priority` عند الإضافة؛ أولوية الطابور تُضبط عبر استدعاء منفصل هو `topPrio` (§1.10).

معالجة الاستجابة (`:159-165`، `:181-187`):

```csharp
var result = ProcessRequest(request, settings);
// Note: Older qbit versions returned nothing, so we can't do != "Ok." here.
if (result == "Fails.") { throw new DownloadClientException("Download client failed to add torrent by url"); }
```

إذن: **الاستجابة 200 مع أي محتوى عدا النص الحرفي `Fails.` تعني نجاحًا.** وكلمة `Ok.` هي الرد المعتاد. خطأ HTTP 415 (وهو "torrent file is not valid" في الويكي) يتحول إلى `DownloadClientException` عبر `:389`.

**معرّف التنزيل لا يأتي من هذا الاستدعاء.** يُحسب على جانب العميل، قبل إرسال الطلب:

- magnet → `MagnetLink.Parse(magnetUrl).InfoHash.ToHex()` (`TorrentClientBase.cs:224`)
- `.torrent` → `_torrentFileInfoReader.GetHashFromTorrentFile(torrentFile)` (`:200`)

وتعيد `AddFromMagnetLink` و`AddFromTorrentFile` القيمة `hash` نفسها دون تغيير (`QBittorrent.cs:130`، `:187`). **يجب أن يعتمد الوسيط (shim) على الـ infohash نفسه تمامًا**، وإلا سيفقد Sonarr أثر عملية الالتقاط (grab) — `TorrentClientBase.cs:206-212` و`:238-244` تكتفي بتسجيل سطر Debug حول ذلك فقط.

يُفحص شرط DHT أولًا للـ magnet:

```csharp
if (!Proxy.GetConfig(Settings).DhtEnabled && !magnetLink.Contains("&tr="))
    throw new NotSupportedException("Magnet Links without trackers not supported if DHT is disabled");   // :73-76
```

وهذا ما يحوّله المستدعي إلى `ReleaseDownloadException("Magnet not supported by download client…")` عندما لا يوجد بديل `.torrent` (`TorrentClientBase.cs:111-119`). **أعد `dht: true`.**

بعد الإضافة، يستعلم `WaitForTorrent` (`QBittorrent.cs:190-214`) بشكل متكرر عن `IsTorrentLoaded` **10 مرات مع فاصل 100 ms** — لكن فقط عندما يكون هناك عمل لاحق يجب إنجازه (حدود المشاركة بعد الإضافة، أو الأولوية العليا، أو Force Start؛ `:86`، `:143`). رسالة الفشل فيه تقول "within 500 ms"، والحلقة فعليًا 10 × 100 ms؛ وفي كل الأحوال يتوقف ويعيد الـ hash (`:212-213`).

### 1.7a المدة التي ينتظرها العميل قبل `torrents/add` — **100 ثانية**، تم قياسها في 2026-08-30 {#17a-how-long-the-client-waits-for-torrentsadd--100-seconds-measured-2026-08-30}

قرأتُ القيم من `Sonarr/Sonarr@32a5d492` و`Radarr/Radarr@40bb746c` (كلاهما على الفرع `develop`) بتاريخ 2026-08-30.
هذا يحدد كل ما يفعله الـ shim بشكل متزامن داخل استدعاء الإضافة، لذا يستحق الاستشهاد به بدلاً من افتراضه.

لا يضبط أي شيء في مسار qBittorrent مهلةً زمنية، لذلك تنتقل القيمة عبر أربع طبقات حتى تستقر عند 100 ث ثابتة.

| الخطوة | `path:line` في Sonarr | `path:line` في Radarr | ما الذي يفعله |
|---|---|---|---|
| استدعاء الإضافة | `QBittorrentProxyV2.cs:146-150`, `:168-172` | `:145-149`, `:167-171` | يبني الطلب ولا يضبط أي مهلة |
| أداة البناء | `NzbDrone.Common/Http/HttpRequestBuilder.cs:104-116` | الملف نفسه `:104-116` | `Apply()` لا يحتوي على سطر `RequestTimeout`، والصنف لا يملك أي خاصية من هذا النوع |
| القيمة الافتراضية للحقل | `NzbDrone.Common/Http/HttpRequest.cs:52` | `:54` | الخاصية التلقائية لا تُسند لها قيمة في الباني، فتكون `TimeSpan.Zero` |
| الموزّع | `NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:70-79` | `:68-77` | تتحول `Zero` إلى `cts.CancelAfter(TimeSpan.FromSeconds(100))` |

```csharp
using var cts = new CancellationTokenSource();
if (request.RequestTimeout != TimeSpan.Zero) { cts.CancelAfter(request.RequestTimeout); }
else { /* The default for System.Net.Http.HttpClient */ cts.CancelAfter(TimeSpan.FromSeconds(100)); }
```

`RequestTimeout` و`Timeout` لا يظهران في أي مكان ضمن `src/NzbDrone.Core/Download/Clients/QBittorrent/` في المستودعين، و`HttpRequestBuilder` لا يوفر أي طريقة لضبطهما، لذلك لا يمكن منح الـ shim وقتاً أطول عبر الإعدادات.

الأمور الخمسة التالية تترتب على ذلك.

- **الـ 100 ث هي رمز الإلغاء الخاص بـ Sonarr، وليست مؤقت .NET.** المعالج الأساسي مبني بقيمة `Timeout = Timeout.InfiniteTimeSpan` (`ManagedHttpDispatcher.cs:183` في Sonarr و`:180` في Radarr)، لذلك يكون الرمز هو الحد الوحيد. يُمرَّر إلى كل من `SendAsync` و`ReadAsByteArrayAsync` (`:115`، `:127`)، وهذا يعني أنه يغطي الاتصال وجسم الطلب وترويسات الاستجابة ومحتواها معاً.
- **يُبلَّغ المستخدم عن انتهاء المهلة كخطأ في الاتصال.** عند انتهاء المهلة يُطلق `new WebException("Http request timed out", …)` (`:142-145`)، ويغلّفه `ProcessRequest` كـ `DownloadClientException("Failed to connect to qBittorrent, please check your settings.", ex)` (`QBittorrentProxyV2.cs:424-427`). لذلك فإن الـ shim الذي يتجاوز 100 ث يبدو وكأن الإعدادات خاطئة لا بطيئة، و*arr لا يعرف أن عملية الإضافة ما زالت قيد التنفيذ.
- **لا توجد مهلة اتصال منفصلة ولا ميزانية أكبر لرفع الملفات المتعددة الأجزاء.** `SocketsHttpHandler.ConnectTimeout` لا يُضبط أبداً. الاستثناء الوحيد هو حد 2 ث على أول محاولة IPv6 في عمر العملية (`ManagedHttpDispatcher.cs:23`، `:288-295`)، ثم ينتقل إلى IPv4 ضمن الـ 100 ث نفسها. يُخزَّن ملف `.torrent` المرفوع كاملاً في مصفوفة بايتات (`HttpRequestBuilder.cs:220-221`، `ManagedHttpDispatcher.cs:103`) ويُرسل تحت الرمز نفسه.
- **الـ 300 ث موجودة لكنها في مسار مختلف.** `HttpClient.cs:285` يضبط `request.RequestTimeout = TimeSpan.FromSeconds(300)` داخل `DownloadFileAsync`، وهذه الدالة تجلب ملف `.torrent` من الفهرس (indexer). ولا تصل أبداً إلى استدعاء عميل التنزيل.
- **Deluge يثبت أن التجاوز ممكن، وqBittorrent يرفضه.** يفعل `DelugeProxy.cs:222` التالي: `requestBuilder.PostProcess += r => r.RequestTimeout = TimeSpan.FromSeconds(15)`. ولا يحتوي `BuildRequest` في qBittorrent على سطر كهذا، وهذا دليل مباشر على أن الـ 100 ث موروثة وليست مختارة.

**Radarr مطابق تماماً.** فرق كتلة المهلة (Radarr `:68-78` مقابل Sonarr `:70-80`) يعطي نتيجة متطابقة بايت بايت، والفرق الوحيد في السلسلة أن Radarr يمرر `ex` بينما يمرر Sonarr `ex.InnerException` إلى `WebException`.

**النتيجة بالنسبة للـ shim.** كل قرار متزامن يُتخذ داخل `torrents/add` يتشارك ميزانية 100 ث واحدة، و*arr ليس لديه طريقة للتمييز بين "ما زال يعمل" و"غير قابل للوصول". يجب أن تبقى المهلة لكل محاولة مضروبة في عدد المزودين الذين جُرّبوا، إضافةً إلى أي نافذة فحص للنسخ المخزنة مؤقتاً فقط، أقل بكثير من هذا الحد. أما أزمنة استجابة المزودين المقاسة التي بُنيت عليها هذه الميزانية فموجودة في [دورة حياة التورنت](torrent-lifecycle.md).

ملاحظة ختامية للاكتمال. الـ 100 ث تُطبّق لكل استدعاء للموزّع، لذلك يحصل كل قفزة في سلسلة إعادة التوجيه التلقائي على ميزانية جديدة (`HttpClient.cs:43` يحدد السلسلة بـ 5 قفزات). استراتيجية إعادة المحاولة في `DownloadClientBase.cs:30-44` **لا** تنطبق هنا؛ فهي تُستخدم فقط عند جلب ملف `.torrent` من الفهرس (`TorrentClientBase.cs:142-144`).

### 1.8 `GET /api/v2/torrents/properties?hash=<hash>` — `IsTorrentLoaded` / `GetTorrentProperties`

`IsTorrentLoaded` (`QBittorrentProxyV2.cs:110-126`) تستدعيه مع `LogHttpError = false` وتعامل **أي** استثناء على أنه "غير محمّل".

`GetTorrentProperties` (`:128-135`) يفكّك الـJSON إلى `QBittorrentTorrentProperties` (`QBittorrentTorrent.cs:48-57`) — **ثلاثة حقول، ويُستخدم منها اثنان فقط**:

| مفتاح JSON | C# | يُستخدم في |
|---|---|---|
| `hash` | `Hash` | يُقرأ ولا يُستخدم أبدًا |
| `save_path` | `SavePath` | مسار `GetImportItem` قبل الإصدار 2.6.1 (`QBittorrent.cs:354`) |
| `seeding_time` | `SeedingTime` (`long`, **بالثواني**) | `FetchTorrentDetails` (`:739-744`) |

**حالة الأحرف في الـhash غير متسقة هنا، وهذا مهم.** كل استدعاء آخر يحوّل الـhash إلى أحرف صغيرة (`item.DownloadId.ToLower()` في `:335`، `:346`، `:353`؛ و`hash.ToLower()` في `:97`، `:109`، `:121`، `:198`)، لكن `FetchTorrentDetails` يمرّر `torrent.Hash` **كما هو تمامًا** (`:741`) — أي ما تضعه الـshim في `torrents/info`. qBittorrent الحقيقي يُرجع hashes بأحرف صغيرة، لذلك لا تظهر هذه المشكلة معه أبدًا. أما ملف الـfixture الخاص بـSonarr فيثبّت هذا التباين بمحاكاة `GetTorrentProperties("HASH", …)` بالقيمة بأحرف كبيرة (Sonarr `QBittorrentFixture.cs:669-675`، وRadarr `:668-674`). **أرجِع الـhashes بأحرف صغيرة من `torrents/info`، وطابِق `?hash=` دون التفريق بين الحالة.**

تُستدعى `FetchTorrentDetails` من `HasReachedSeedingTimeLimit` فقط (`:700`)، وهذه الدالة لا تُنفَّذ إلا عندما يكون حد وقت الseeding مفعّلًا فعلًا. لذلك الـshim الذي لا يعلن عن أي حدود لوقت الseeding لن يرى هذا الاستدعاء أبدًا أثناء الاستطلاع. ومع ذلك نحتاجه لـ`IsTorrentLoaded`، وهو فحص الجاهزية بعد الإضافة: **404 لـhash غير معروف، و200 + JSON لـhash معروف.**

النتيجة تُخزَّن مؤقتًا لمدة 5 دقائق لكل `{Host}{Port}{Hash}` (`:678`، `:689`، `:695`، `:708`)، والـfixture يتحقق من أن البيانات تُجلب مرة واحدة فقط، لا مرتين، عبر استطلاعين (Sonarr `QBittorrentFixture.cs:905-920`، وRadarr `:904-919`).

### 1.9 `POST /api/v2/torrents/setShareLimits` — `SetTorrentSeedingConfiguration` (`:286-308`)

الصيغة: `hashes=<lowercase hash>`، ثم `AddTorrentSeedingFormParameters(request, seedConfiguration, always: true)`

مع `always: true` يُرسَل **كلٌّ من** `ratioLimit` و`seedingTimeLimit` دائماً، حتى عندما تكون القيمة `-2` (`:232`، `:237`). ولا يُرسَل `inactiveSeedingTimeLimit` أبداً.

يُتجاهل الخطأ **404** (`:298-307`، التعليق: "setShareLimits was added in api v2.0.1"). أما أي خطأ آخر فيُمرَّر إلى الأعلى، لكن موقع الاستدعاء يلتقطه ويسجّل تحذيراً (`QBittorrent.cs:95-102`، `:152-159`).

لا يُستدعى هذا المسار إلا عندما يوفّر الفهرس إعداد seed *و* يكون webapi بإصدار `< 2.8.1`. أما على shim يُبلغ عن الإصدار `2.11.2`، فتُرسَل حدود المشاركة ضمن `torrents/add` بدلاً من ذلك، ولا يُستخدم هذا المسار أبداً في عملية الجلب. نفّذه كدالة فارغة (no-op) تُعيد 200.

### 1.10 `POST /api/v2/torrents/topPrio` — `MoveTorrentToTopInQueue` (`:310-330`)

الصيغة: `hashes=<lowercase hash>`.

يُتجاهل خطأ **409 Conflict** (`:320-329`، والتعليق: "qBittorrent rejects all Prio commands with 409:
Conflict if Options -> BitTorrent -> Torrent Queueing is not enabled"). أما الـ v1 proxy فيتجاهل **403** بدلاً منه (`QBittorrentProxyV1.cs:255-264`). أي خطأ آخر يُلتقط ويُسجَّل كتحذير في موقع الاستدعاء (`QBittorrent.cs:107-114`، `:164-171`). والـ fixture يتحقق من أن الفشل هنا لا يُفشل عملية الـ grab (Sonarr `QBittorrentFixture.cs:525-542`، Radarr `:524-541`).

لا يُستدعى هذا إلا عندما تكون إعدادات الأولوية Recent/Older مضبوطة على `First` (`QBittorrentPriority.First = 1`، `QBittorrentPriority.cs:5-6`). والقيمة الافتراضية هي `Last = 0`.

### 1.11 `POST /api/v2/torrents/setForceStart` — `SetForceStart` (`:332-339`)

النموذج: `hashes=<lowercase hash>`، و`value=true` (السلسلة الحرفية بحروف صغيرة، `:337`).

لا يُستدعى إلا عندما تكون `InitialState` بالقيمة `ForceStart` (`QBittorrentState.cs:10-11`، `QBittorrent.cs:82`، `:117-127`). تُلتقط الأخطاء ويُعرض تحذير بها (`:123-126`).

### 1.12 `GET /api/v2/torrents/info[?category=<cat>]` — `GetTorrents` (`:97-108`)

**المعامل الوحيد الذي يُرسَل هو `category`، ويُرسَل فقط عندما يكون الإعداد غير فارغ**
(`:100-103`). لا يُرسَل `filter`، ولا `hashes`، ولا `sort`، ولا `reverse`، ولا `limit`، ولا `offset`، ولا `tag`.
العميل **لا** يفلتر حسب الفئة مرة أخرى بعد ذلك، على عكس عميل SAB الذي يفلتر مرتين. لذلك أي طبقة وسيطة (shim) تتجاهل `category` ستسلّم Radarr تورنتات Sonarr.

حقل `category` في الاستجابة مهم لسبب ثانٍ: أي تورنت لا يملك **سجل التقاط** لدى \*arr يُتخطّى تماماً ما لم يحمل هذا الحقل — `CompletedDownloadService.Check` (`CompletedDownloadService.cs:84-88`):

```csharp
if (historyItem == null && trackedDownload.DownloadItem.Category.IsNullOrWhiteSpace())
{
    trackedDownload.Warn("Download wasn't grabbed by Sonarr and not in a category, Skipping.");
    return;
}
```

قيمة `Category` هي `category` إذا كانت غير فارغة، وإلا فهي `label` (`QBittorrent.cs:231`).

الاستجابة: مصفوفة JSON **مصفوفة**. كل حقل يُستهلك، وما يصبح عليه:

| مفتاح JSON | نوع C# | الوحدات | يصبح |
|---|---|---|---|
| `hash` | `string` | | `DownloadId = torrent.Hash.ToUpper()` (`QBittorrent.cs:230`) — **يُحوَّل إلى أحرف كبيرة**، ويُمرَّر مرة أخرى بأحرف صغيرة في كل استدعاء لاحق |
| `name` | `string` | | `Title = torrent.Name` (`:232`) — راجع §7.1 لمعرفة كل ما يتحكم فيه |
| `size` | `long` | بايت | `TotalSize` (`:233`)؛ وأيضاً `RemainingSize = (long)(size * (1.0 - progress))` (`:235`) |
| `progress` | `double` | 0..1 | `RemainingSize` (`:235`) |
| `eta` | `BigInteger` | ثوانٍ | `RemainingTime` عبر `GetRemainingTime` (`:236`, `:614-628`) |
| `state` | `string` | | `Status` و`Message`، ونصف بوابة `CanMoveFiles` (`:242-312`) — §2 |
| `category` | `string` | | `Category`، وهو المفضَّل (`:231`) |
| `label` | `string` | | `Category`، كخيار احتياطي عندما يكون `category` فارغاً (`:231`). حقل من ما قبل 3.3.5؛ لا يُرسله qBittorrent 5 |
| `ratio` | `float` | | `SeedRatio` (`:237`)، و`HasReachedSeedLimit` (`:634`, `:641`) |
| `ratio_limit` | `float`، الافتراضي `-2` | | `HasReachedSeedLimit` (`:632-645`) |
| `seeding_time_limit` | `long`، الافتراضي `-2` | **دقائق** | `HasReachedSeedingTimeLimit` (`:659-670`) |
| `inactive_seeding_time_limit` | `long`، الافتراضي `-2` | **دقائق** | `HasReachedInactiveSeedingTimeLimit` (`:723-736`) |
| `last_activity` | `long` | **ثوانٍ يونكس** | `HasReachedInactiveSeedingTimeLimit` (`:736`) |
| `seeding_time` | `long?`، الافتراضي null | ثوانٍ | `HasReachedSeedingTimeLimit` (`:672-676`) — التعليق في `QBittorrentTorrent.cs:36` يقول إنه "not provided by the list api"، لكن العميل يستخدمه إن وُجد، وهذا يوفّر جولة `torrents/properties` إضافية |
| `save_path` | `string` | | يُقارَن بـ `content_path` (`:316`) |
| `content_path` | `string` | | `OutputPath` على webapi `>= 2.6.1` (`:318`) — §4 |

دالة `GetRemainingTime` (`:614-628`):

```csharp
if (torrent.Eta < 0 || torrent.Eta > 365 * 24 * 3600) { return null; }   // > 31,536,000 s
if (torrent.Eta == 8640000) { return null; }                            // qBittorrent's "unknown"
return TimeSpan.FromSeconds((int)torrent.Eta);
```

وبعد ذلك يُجبَر `RemainingTime` على `TimeSpan.Zero` لأي عنصر بحالة Completed (`:273`).

يُجلَب `torrents/info` في كل مرة يُستدعى فيها `RefreshMonitoredDownloads`
(`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:94`)، وهو أيضاً يُؤجَّل إلى قائمة الأوامر بعد 5 ثوانٍ من الأحداث ذات الصلة (`:53`).

### 1.13 `GET /api/v2/torrents/files?hash=<hash>` — `GetTorrentFiles` (`:137-144`)

مصفوفة JSON تُحوَّل إلى `List<QBittorrentTorrentFile>`، وفيها **حقل واحد فقط**: `Name` (`QBittorrentTorrent.cs:59-62`)، ويُربط بالمفتاح `name`. وهو مسار الملف **نسبةً إلى save path**، مع فواصل `/` على كل نظام تشغيل ("QBittorrent يُرجع فواصل المسار `/` حتى على windows"، `QBittorrent.cs:358`).

لا يُستدعى إلا من `GetImportItem` (`:346`) وفقط عندما يكون `OutputPath` ما زال فارغاً، أي على webapi من نسخة `< 2.6.1`، أو عندما يرجع `content_path` فارغاً. وكل من `index` و`size` و`progress` و`priority` و`is_seed` و`piece_range` و`availability` يتم تجاهلها.

تتم معالجة **المصفوفة الفارغة** هكذا: `_logger.Debug("No files found for torrent {0} in qBittorrent")` ثم
يُعاد العنصر كما هو بدون تغيير (`:347-351`)، وهذا بدوره يفشل في `ValidatePath`.

### 1.14 `POST /api/v2/torrents/setCategory` — `SetTorrentLabel` (`:204-211`)

الصيغة: `hashes=<lowercase hash>`، `category=<post-import category>`.

تُستدعى هذه الدالة فقط من `MarkItemAsImported` (`QBittorrent.cs:52-69`)، وفقط عندما يكون الإعداد الاختياري `TvImportedCategory` / `MovieImportedCategory` غير فارغ ومختلفًا عن الفئة الرئيسية. إذا حدث `DownloadClientException` يتم التقاطه ويظهر كتحذير:
"Failed to set post-import torrent label \"{0}\" for {1} in qBittorrent. Does the label exist?"
(`:62-67`). §5.1.

### 1.15 `POST /api/v2/torrents/delete` — `RemoveTorrent` (`:190-202`)

الصيغة: `hashes=<lowercase hash>`، مع إضافة `deleteFiles=true` **فقط عندما تكون `removeData` قيمتها true** (`:196-199`)، أي النص الحرفي بأحرف صغيرة، وليس `Convert.ToString(bool)`.

التنفيذ الكامل لـ `QBittorrent.RemoveItem` (`:333-336`) هو:

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    Proxy.RemoveTorrent(item.DownloadId.ToLower(), deleteData, Settings);
}
```

**هو لا يستدعي `DeleteItemData`.** وهذا هو الفرق عن عميل SAB، الذي يحذف مجلد المهمة بنفسه عبر نظام الملفات
(`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`؛ انظر [sabnzbd-client-contract.md §5.3](sabnzbd-client-contract.md)). هنا يتولى عميل التنزيل حذف البيانات بالكامل. §5.

### 1.16 نقاط النهاية التي لا يستخدمها العميل أبداً {#116-endpoints-the-client-never-touches}

غير موجودة في الواجهة إطلاقاً، لذلك لا تُستدعى أبداً:
`torrents/pause`, `torrents/resume`, `torrents/stop`,
`torrents/start`, `torrents/setLocation`, `torrents/rename`, `torrents/recheck`,
`torrents/reannounce`, `torrents/filePrio`, `torrents/setDownloadLimit`, `torrents/setUploadLimit`,
`torrents/toggleSequentialDownload`, `torrents/setAutoManagement`, `torrents/editCategory`,
`torrents/removeCategories`, الوسوم، وRSS، والبحث، `app/setPreferences`, `app/defaultSavePath`,
`app/shutdown`, `sync/maindata`, `transfer/*`, `auth/logout`. الإيقاف المؤقت والاستئناف موجودان فقط كحقل النموذج `paused=`/`stopped=` في `torrents/add`.

موجودة في الواجهة لكنها لا تُستدعى أبداً من `QBittorrent.cs`: `GetVersion` (§1.2).

### 1.17 خريطة مسارات v1 (للاكتمال؛ لا تنفذها) {#117-the-v1-route-map-for-completeness-do-not-implement}

`QBittorrentProxyV1.cs`: `/version/api` (`:30`, `:64` — العميل يضيف `"1."` إلى أي قيمة ترجع
back, `:65`), `/version/qbittorrent` (`:73`), `/query/preferences` (`:81`),
`/query/torrents?label=&category=` (`:89-94` — **كلا المعاملين**), `/query/propertiesGeneral/{hash}`
(`:103`, `:120`), `/query/propertiesFiles/{hash}` (`:128`), `/command/download` (`:136`),
`/command/upload` (`:166`), `/command/delete` or `/command/deletePerm` (`:196` — الفرق بين delete/deleteFiles
هو مساران مختلفان، وليس معاملاً), `/command/setCategory` مع
احتياطي إلى `/command/setLabel` عند 404 (`:205-225`), `/command/addCategory` (`:230`),
`/command/topPrio` (`:248`), `/command/setForceStart` (`:269`), `/login` (`:345`).

## 2. `state` ← `DownloadItemStatus` {#2-state--downloaditemstatus}

`QBittorrent.GetItems` (`:247-312`). الحالات هي سلاسل qBittorrent نفسها، وتُنتجها `torrentStateToString` (`qBittorrent/src/webui/api/serialize/serialize_torrent.cpp:44-87`).

| `state` | `DownloadItemStatus` | `Message` | السطر |
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
| `metaDL` | Queued **إذا كان `dht: true`**، وإلا Warning | "qBittorrent is downloading metadata" / "qBittorrent cannot resolve magnet link with DHT disabled" | `:286-299` |
| `forcedMetaDL` | نفسها `metaDL` | نفسها | `:287` |
| `forcedDL` | Downloading | — | `:301` |
| `moving` | Downloading | — | `:302` |
| `downloading` | Downloading | — | `:303` |
| **أي حالة أخرى** | **Downloading** | "Unknown download state: {state}" | `:307-311` |

ملاحظات يجب على الـ shim أن يتعامل معها:

- **الحالة غير المعروفة لا تسبب استثناءً.** تُسجَّل في السجل عبر `_logger.Info($"Unknown download state: {torrent.State}")` ثم تنتقل إلى Downloading (`:307-311`). هذا عكس عميل SAB، حيث يسبب اسم الحالة غير المعروف استثناءً داخل الـ deserializer فيوقف الاستطلاع كله. ومع ذلك: أرسل فقط أسماء من هذا الجدول.
- **حالات Completed هي الوحيدة القابلة للاستيراد.** تعود `CompletedDownloadService.Check` فوراً ما لم تكن `Status == Completed` (`src/NzbDrone.Core/Download/CompletedDownloadService.cs:68-71`).
- **كل حالة Completed تُصفّر `RemainingTime`** (`:273`، والتعليق "qBittorrent sends eta=8640000 for completed torrents").
- `metaDL` / `forcedMetaDL` هي مرحلة "magnet, no metadata yet". **لا توجد مهلة زمنية** في العميل: تبقى في Queued طالما يواصل الـ shim إرسال `metaDL`، ولا تتحول إلى فشل من تلقاء نفسها. الشيء الوحيد الذي يحوّلها إلى Warning هو `dht: false` في `app/preferences` (`:288`). تتصعّد معالجة فشل التنزيل في Sonarr بحسب عمر الـ grab، لا بحسب هذه الحالة.
- `stalledDL` هو *التحذير* الذي يراه المشغّل لتورنت متوقف عن الحركة. لا ينبغي لـ shim لا يملك مفهوم الـ peers أن يستخدمها أبداً، فالتحذير على تنزيل متتبَّع يظهر في الطابور كمشكلة، وهو ما يفحصه `FailedDownloadService`.
- `error` و`missingFiles` تحذيرات عن قصد، "so failed download handling isn't triggered" (`:249`). إذا أراد shim أن يطلب من Sonarr الإدراج في القائمة السوداء وإعادة الـ grab، فالتحذير **ليس** الطريقة لذلك.

## 3. النقل مقابل النسخ — الشرط الدقيق، والوصفة {#3-move-vs-copy--the-exact-condition-and-the-recipe}

### 3.1 البوابة {#31-the-gate}

`QBittorrent.cs:240-245`، كما هو بالضبط بما في ذلك التعليق الذي يشرحه:

```csharp
// Avoid removing torrents that haven't reached the global max ratio.
// Removal also requires the torrent to be paused, in case a higher max ratio was set on the torrent itself (which is not exposed by the api).
item.CanMoveFiles = item.CanBeRemoved =
    item.DownloadClientInfo.RemoveCompletedDownloads &&
    torrent.State is "pausedUP" or "stoppedUP" &&
    HasReachedSeedLimit(torrent, config);
```

هناك ثلاثة شروط، ويجب أن تتحقق كلها:

1. **`RemoveCompletedDownloads`** — إعداد على جانب *arr لكل عميل، وليس شيئًا يقوله qBittorrent. القيمة الافتراضية لـ`DownloadClientDefinition.RemoveCompletedDownloads` هي **`true`** (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17`)، وتظهر في الواجهة باسم "Remove Completed". إذا أوقف المستخدم هذا الخيار، **تصبح عمليات الاستيراد نسخًا**، ولا يستطيع الـshim فعل أي شيء حيال ذلك. (تتحول عملية Move إلى نسخ لسبب ثانٍ لا يراه الـshim أيضًا: أن حاوية *arr تصل إلى مجلد التنزيل ومجلد الجذر عبر volumes منفصلة، فيرد `rename()` بالخطأ `EXDEV`، ويقوم `File.Move` في .NET بالنسخ ثم الحذف. يقرأ zurg الاثنين من واجهة برمجة مصدر الحصول، ثم يتبنى النسخة لاحقًا؛ راجع `internal/arrlayout` و`internal/handlers/magic_copies.go`.)
2. **`state` يجب أن تكون بالضبط `pausedUP` أو `stoppedUP`.** `uploading` و`stalledUP` و`queuedUP` و`forcedUP` تعني Completed لكنها غير قابلة للنقل، وهذا ما يثبّته الـfixture (Sonarr `QBittorrentFixture.cs:680-689`، Radarr `:679-688`).
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

- قيمة **`ratio_limit >= 0`** لكل تورنت على حدة تتغلب تماماً ولا يُرجَع إلى الإعداد العام. في نموذج qBittorrent نفسه، القيمة `ratio_limit` هي `-2` تعني "استخدم العام" و`-1` تعني "غير محدود" (`QBittorrentTorrent.cs:32`؛ ويكي، *Set torrent share limit*).
- القيمة `-1` (غير محدود) لا تحقق أيّاً من الفرعين، لأن `-1 >= 0` خطأ و`-1 == -2` خطأ أيضاً، فالتورنت غير المحدود **لا يُنقل أبداً** بقاعدة النسبة.
- هامش `0.001f` هو ما يجعل "الوصول بعد التقريب" ممكناً. الاختبار المثبَّت يعتبر النسبة `1.1006066990976857` مقابل الحد `1.0` قد بلغت الحد، ويعتبر `0.9999` قد بلغته أيضاً (Sonarr `QBittorrentFixture.cs:715-737`، Radarr `:714-736`).

`HasReachedSeedingTimeLimit` (`:655-717`):

```csharp
if (torrent.SeedingTimeLimit >= 0)        { seedingTimeLimit = torrent.SeedingTimeLimit * 60; }        // minutes -> seconds
else if (torrent.SeedingTimeLimit == -2 && config.MaxSeedingTimeEnabled) { seedingTimeLimit = config.MaxSeedingTime * 60; }
else                                      { return false; }
```

ثم يستخدم `torrent.SeedingTime` إذا كانت واجهة القائمة قد زوّدت بها (`:672-676`)، وإلا فإنه يتحقق من ذاكرة مؤقتة مدتها 5 دقائق، وعند عدم وجود القيمة فيها يستدعي **`torrents/properties`** للحصول على `seeding_time` (`:678-716`، `:739-744`). و`HasReachedInactiveSeedingTimeLimit` (`:719-737`) له البنية نفسها، لكنه يقارن `now - last_activity` بالقيمة `inactive_seeding_time_limit` (أو بالإعداد العام)، ولا يحتاج أبداً إلى استدعاء ثانٍ.

### 3.3 ما الذي تقرره `CanMoveFiles` {#33-what-canmovefiles-decides}

`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, series, importItem)` (`CompletedDownloadService.cs:148-151`)، وبعد ذلك يُقرأ `CanMoveFiles` في مكانين:

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

(في Radarr: `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`، والكود مطابق تماماً.)

```csharp
// src/NzbDrone.Core/MediaFiles/DownloadedEpisodesImportService.cs:204-207
if (importMode == ImportMode.Auto)
{
    importMode = (downloadClientItem == null || downloadClientItem.CanMoveFiles) ? ImportMode.Move : ImportMode.Copy;
}
```

(في Radarr: `DownloadedMovieImportService.cs:221-224`.)

`copyOnly == false` → `TransferMode.Move` (`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`)؛ و`copyOnly == true` → `TransferMode.HardLinkOrCopy` إذا كان خيار "Use Hardlinks instead of Copy" مفعّلاً، وإلا فـ `TransferMode.Copy` (`:103`، `:107`). و`TransferMode` هو `[Flags] None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy=Copy|HardLink` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`).

**عملية Move الفاشلة لا تتحول أبداً إلى Copy.** الشرح الكامل مع أرقام الأسطر موجود في [sabnzbd-client-contract.md §5.5](sabnzbd-client-contract.md)؛ والملف `DiskTransferService.cs` مشترك ومتطابق تماماً بين المستودعين. الخلاصة باختصار: فرع Move في `TransferFile` (`src/NzbDrone.Common/Disk/DiskTransferService.cs:360-389`) يحتوي على مسار نسخ واحد فقط، ويُختار مسبقاً من `targetMount.DriveFormat == "cifs"` (`:342`، `:378-385`)، ولا يُختار أبداً كردّ فعل على فشل. و`TryMoveFileVerified` يعيد رمي الاستثناء (`:487-503`)، و`VerifyFile` يرمي `IOException("File move incomplete, data loss may have occurred. …")` إذا لم يتطابق حجم الوجهة مع حجم المصدر (`:505-524`).

### 3.4 مع الإعدادات الافتراضية لـ qBittorrent، يكون الاستيراد **نسخاً** {#34-with-qbittorrents-own-defaults-the-import-is-a-copy}

خذ تورنتاً أبلغ عنه shim بشكل ساذج، أي بالإعدادات الافتراضية لـqBittorrent، وهي أيضاً الإعدادات الافتراضية للنموذج:

| الحقل | القيمة | التأثير |
|---|---|---|
| `state` | `stoppedUP` | الشرط 2 ✓ |
| `ratio_limit` | `-2` (الافتراضي، `QBittorrentTorrent.cs:33`) | ينتقل إلى الفرع العام |
| `max_ratio_enabled` | `false` (الافتراضي في qBittorrent نفسه؛ نص مثال الويكي `:684`) | يفشل الفرع العام |
| `seeding_time_limit` | `-2` | يحتاج إلى `max_seeding_time_enabled` |
| `max_seeding_time_enabled` | `false` (الويكي `:686`) | يفشل |
| `inactive_seeding_time_limit` | `-2` | يحتاج إلى `max_inactive_seeding_time_enabled` |
| `max_inactive_seeding_time_enabled` | `false` | يفشل |

⇒ `HasReachedSeedLimit` تصبح false ⇒ `CanMoveFiles` تصبح false ⇒ `copyOnly` تصبح true ⇒ `TransferMode.Copy` ⇒ **\*arr
يقرأ كل بايت من الإصدار من التركيب ويكتبه مجدداً.** على تركيبة debrid، هذه هي النتيجة الوحيدة التي صُمم النظام كله لتجنبها، وهي تفشل بصمت. لا يوجد أي تحذير، فقط يستغرق الاستيراد ساعات ويملأ القرص.

الـ fixture يثبّت هذه الحالة بالضبط: `should_not_be_removable_and_should_not_allow_move_files_if_max_ratio_is_not_set` (Sonarr `QBittorrentFixture.cs:691-701`، Radarr `:690-700`). الحدود العامة معطّلة، والتورنت متوقف مؤقتاً، والنسبة 1.0، و`CanMoveFiles == false`.

### 3.5 الوصفة {#35-the-recipe}

لكل تورنت تريد الطبقة الوسيطة استيراده بطريقة **move**:

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

`ratio_limit: 0` يسلك الفرع الأول (`0 >= 0` و`0 - 0 <= 0.001`)، فلا يُستشار الإعداد العام أبدًا. لذلك يمكن أن يبقى `max_ratio_enabled` على `false`، ويبقى فحص الصحة `DownloadClientRemovesCompletedDownloadsCheck` ساكتًا. أي قيمة `ratio_limit >= ratio` ضمن `0.001` تعمل، و`0`/`0` هي الوحيدة التي لا تحتاج إلى أي تنسيق.

أما الفرق بين `pausedUP` و`stoppedUP`: **يتعامل develop معهما بالطريقة نفسها**، سواء في بوابة `CanMoveFiles` (`:244`) أو في خريطة الحالات (`:266-267`)، وكل اختبار لحدود السيدنج هو زوج `[TestCase]` يغطي الاثنين. `stoppedUP` هي التسمية في qBittorrent 5 (`serialize_torrent.cpp:54-55`)، و`pausedUP` لم يعد موجودًا في master. لكن `pausedUP` هو الخيار الأأمن مع إصدارات *arr المنشورة، لأن الفرع الخاص بـ`stoppedUP` أُضيف مع إطلاق qBittorrent 5، والإصدارات الأقدم من Sonarr v4 وRadarr v5 تعرف `pausedUP` فقط. هذه النقطة الأخيرة استنتاج عن الوسوم القديمة، وليست شيئًا تثبته مصادر develop المذكورة أعلاه.

وهناك أمر ليس في يد الطبقة الوسيطة: **يجب أن يبقى "Remove Completed" مفعّلًا في إعدادات عميل التنزيل داخل \*arr.** وهو مفعّل افتراضيًا (`DownloadClientDefinition.cs:17`). وثّق ذلك، لأن إيقافه يحوّل كل عملية استيراد بصمت إلى تنزيل كامل.

## 4. `OutputPath` — المكان الذي يُخبر فيه \*arr بالاستيراد منه {#4-outputpath--where-the-arr-is-told-to-import-from}

### 4.1 المسار في الإصدار 2.6.1 وما بعده: `content_path` {#41-the-261-path-content_path}

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

نص التحذير (`src/NzbDrone.Core/Localization/Core/en.json`):

> Unable to Import. Path matches client base download directory, it's possible 'Keep top-level folder'
> is disabled for this torrent or 'Torrent Content Layout' is NOT set to 'Original' or 'Create Subfolder'?

القواعد التي يجب أن تلتزم بها الـ shim:

- يجب ألا يساوي `content_path` القيمة `save_path`. التساوي هو الخطأ نفسه وليس حالة احتياطية: يتحول العنصر إلى **Warning** ولا يُستورد أبدًا.
- يجب أن يكون `content_path` **مسارًا مطلقًا وصالحًا لنظام التشغيل الذي يعمل عليه \*arr**. وإلا فإن `CompletedDownloadService.ValidatePath` (`CompletedDownloadService.cs:295-313`) يرفضه برسالة "[{0}] is not a valid local path. You may need a Remote Path Mapping."
- ويجب أن يكون موجودًا على مضيف \*arr كمجلد **أو** كملف؛ إذ تتفرع `ProcessPath` (`DownloadedEpisodesImportService.cs:80-105`) أولًا على `FolderExists` ثم على `FileExists`، وإذا لم يتحقق أي منهما تنتقل إلى `LogInaccessiblePathError` وتعيد نتيجة فارغة.
- لا ترسل `content_path` فارغًا. فهو "differs" عن `save_path` غير الفارغ، فيُضبط `OutputPath` على `OsPath` فارغ، وعندها تنتقل `GetImportItem` إلى مرحلة المرور على `torrents/files` (§4.2) لأن `item.OutputPath.IsEmpty` تصبح صحيحة (`:341-344`).
- لا يعمل هذا الجزء إلا مع العناصر **Completed**، لذلك لا يكون `content_path` ذا أهمية حاسمة إلا عندما تكون الحالة واحدة من مجموعة Completed في §2.

ما الذي يضعه qBittorrent الحقيقي هناك — `TorrentImpl::contentPath()` (`qBittorrent/src/base/bittorrent/torrentimpl.cpp:577-587`):

```cpp
Path TorrentImpl::contentPath() const
{
    if (!hasMetadata())    return {};
    if (filesCount() == 1) return (actualStorageLocation() / filePath(0));   // the FILE, not a folder
    const Path rootPath = this->rootPath();
    return (rootPath.isEmpty() ? actualStorageLocation() : rootPath);
}
```

مع `rootPath()` = `actualStorageLocation() / Path::findRootFolder(filePaths())` (`:565-575`). إذن: **الملف الواحد** يكون `content_path` فيه هو الملف نفسه؛ والتورنت متعدد الملفات الذي له مجلد جذر مشترك يحصل على ذلك المجلد؛ والتورنت متعدد الملفات **بدون** جذر مشترك يحصل على `save_path`، وهذه تحديدًا الحالة التي يتعلق بها تحذير العميل `content_path == save_path`.

يطبّق `RemapRemoteToLocal(Settings.Host, …)` تعيينات Remote Path Mapping الخاصة بالمستخدم، ويعتمد على سلسلة **Host** المُعدّة. إذا كان \*arr يعمل داخل حاوية وأبلغ الشيم عن مسار المضيف، فيحتاج المشغّل إلى تعيين؛ انظر [sabnzbd.md](../guides/sonarr-radarr.md#8-if-your-arr-is-in-docker)، ويسري هذا دون تغيير.

### 4.2 المسار قبل 2.6.1: `GetImportItem` يمر على `torrents/files` {#42-the-pre-261-path-getimportitem-walks-torrentsfiles}

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

يأخذ **`files[0].name` فقط**، ويصعد إلى أعلى مكوّن في المسار، ثم يضمّه إلى `properties.save_path`. يثبّت الـ fixture الأشكال الثلاثة كلها (Sonarr `QBittorrentFixture.cs:317-421`، Radarr `:296-400`):

| `files[0].name` | `save_path` | `OutputPath` |
|---|---|---|
| `Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` |
| `Folder/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Folder` |
| `Droned.S01.12/E01.mkv` (+ `E02.mkv`) | `/Torrents` | `/Torrents/Droned.S01.12` |

لاحظ الصف الثالث: الجذر هنا هو جذر `files[0]`، وليس جذراً مشتركاً محسوباً، لذلك **يجب أن يسرد الـ shim على هذا المسار الملفات بترتيب يكون فيه أول عنصر حاملاً لمجلد الإصدار**. الـ shim الذي يُبلغ عن webapi بقيمة `>= 2.6.1` لا يصل إلى هنا أبداً، وهذا سبب إضافي لأن يُبلغ عن `2.11.2`.

`previousImportAttempt` هو معامل في `GetImportItem` (`:338`) و**لا يُقرأ أبداً** في هذا التنفيذ. لا يُحفظ أي شيء عن المحاولة الفاشلة.

### 4.3 متى يكون المسار خاطئاً، وكم مرة يُعاد المحاولة {#43-when-the-path-is-wrong-and-how-often-it-is-retried}

لا يوجد أي تأخير متزايد بين المحاولات ولا حد أقصى لعددها في هذا المسار.

- يعمل `CompletedDownloadService.Check` على كل تنزيل متتبَّع في الحالة `Downloading` أو `ImportBlocked`، في كل تحديث (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:125-129`).
- يستدعي `Check` الدالة `SetImportItem` **أولاً** (`CompletedDownloadService.cs:73`)، وهي `_provideImportItemService.ProvideImportItem(...)` → `client.GetImportItem(...)` (`:290-293`، `src/NzbDrone.Core/Download/ProvideImportItemService.cs:17-22`). لذلك يُعاد حساب `OutputPath` من صف `torrents/info` *الحالي* في كل استطلاع.
- فشل `ValidatePath` (`:295-313`) يُنتج تحذيراً ويُبقي الحالة على `Downloading`، فيحاول الاستطلاع التالي من البداية:
  - مسار إخراج فارغ ← "Download doesn't contain intermediate path, Skipping."
  - مسار بنظام تشغيل خاطئ ← "[{0}] is not a valid local path. You may need a Remote Path Mapping. …"
- يستدعي `Import` الدالة `SetImportItem` عند الدخول (`:130`) قبل إعادة قراءة `trackedDownload.ImportItem.OutputPath.FullPath` (`:147`). ويُشغَّل من الحالة `ImportPending` بواسطة `DownloadProcessingService` (`src/NzbDrone.Core/Download/DownloadProcessingService.cs:61-63`). إذا فشل الاستيراد تبقى الحالة على `ImportPending` (`:158`) أو تنتقل إلى `ImportBlocked` (`:196`)، وكلتاهما تُعاد معالجتهما.
- المسار الموجود لكنه لا يحتوي على أي شيء قابل للاستيراد يُعطي "No files found are eligible for import in {0}" (`:162`) ويبقى في `ImportPending`.

**النتيجة بالنسبة إلى طبقة الـshim: يُسمح لـ `content_path` بأن يكون خاطئاً لفترة.** أبلِغ عن التورنت بحالة Downloading (أو Queued) إلى أن يوجد المجلد فعلاً وتصبح أحجام ملفاته نهائية، وعندها سيواصل العميل الاستطلاع ببساطة. الإبلاغ عن Completed مبكراً يكلّف محاولة استيراد ضد مجلد غير جاهز. والأسوأ أن \*arr قد ينقل ملفاً ما زال حجمه غير مكتمل ثم يفشل في `VerifyFile`، بعد أن يكون قد أفرغ المصدر. هذا هو الفخ نفسه الموثّق في نقطة نهاية SAB ([sabnzbd.md](../guides/sonarr-radarr.md)، *ماذا يحدث عند الالتقاط*، الخطوة 5).

## 5. تسلسل ما بعد الاستيراد {#5-the-post-import-sequence}

### 5.1 ما الذي يُستدعى وبأي ترتيب {#51-what-fires-in-order}

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

و`RemoveFromDownloadClient` (`:87-103`) هي:

```csharp
_logger.Debug("[{0}] Removing download from {1} history", ...);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);             // :92  deleteData: TRUE
trackedDownload.DownloadItem.Removed = true;
```

إذن، تسلسل الطلبات بعد الاستيراد الناجح يكون كالتالي:

1. **`POST /api/v2/torrents/setCategory`** — فقط إذا كانت هناك فئة يتم تعيينها بعد الاستيراد
   (`QBittorrent.cs:52-69`). يتم تخطيها افتراضيًا.
2. قبل أيٍّ منهما، وخارج برنامج التنزيل تمامًا: **تقوم \*arr بنقل الملف**، ثم قد تقوم `ProcessFolder` بـ**حذف مجلد المصدر نفسه**
   (`DownloadedEpisodesImportService.cs:209-223`، وفي Radarr `DownloadedMovieImportService.cs:226-240`):

   ```csharp
   if (importMode == ImportMode.Move &&
       importResults.Any(i => i.Result == ImportResultType.Imported) &&
       ShouldDeleteFolder(directoryInfo, series))
   {
       _diskProvider.DeleteFolder(directoryInfo.FullName, true);   // recursive
   }
   ```

   ترفض `ShouldDeleteFolder` (`:108-153`) الحذف إذا بقي في المجلد أي ملف فيديو يمكن تحليله وليس
   عينةً (`:117-133`)، أو عندما يبقى ملف `.rar` أكبر من 10 MB (`:135-139`). بعد نقل ملف واحد ناجح لا ينطبق أيٌّ من الشرطين، لذا يُحذف المجلد **فعلًا**. يُلتقط الاستثناء `IOException` ويُسجَّل
   على مستوى Debug (`:219-222`).
3. **`POST /api/v2/torrents/delete`** مع `hashes=<lowercase hash>&deleteFiles=true`
   (`QBittorrent.cs:335`, `QBittorrentProxyV2.cs:190-202`).

هناك حدثان آخران يصلان إلى نفس `RemoveFromDownloadClient(…, true)`:

- `DownloadFailedEvent` (`DownloadEventHub.cs:26-46`)، ويعتمد على الإعداد `RemoveFailedDownloads` لكل عميل
  (الافتراضي `true`، `DownloadClientDefinition.cs:18`). انتبه إلى أن
  `TrackedDownload.Fail()` يضبط `DownloadItem.CanBeRemoved = true` بلا شرط
  (`src/NzbDrone.Core/Download/TrackedDownloads/TrackedDownload.cs:39-46`، والتعليق: "اضبط CanBeRemoved
  للسماح بإزالة العنصر الفاشل من العميل") — **لذا تُحذف عملية التنزيل الفاشلة حتى عندما يقول شرط حد الزرع (seed-limit) غير ذلك.**
- `DownloadCanBeRemovedEvent` (`:71-85`).

إذا رمى `RemoveItem` الاستثناء `NotSupportedException`، يُخفَّض إلى الرسالة "Removing item not supported by your download client ({0})." (`:95-98`). أما أي استثناء آخر فيُسجَّل كخطأ، ولا يُعلَّم العنصر على أنه Removed، لذا سيُعاد المحاولة في الاستطلاع (poll) التالي (`:99-102`).

### 5.2 ما يجب أن تفعله الطبقة الوسيطة مع `deleteFiles=true` {#52-what-the-shim-must-do-with-deletefilestrue}

هذا هو نفس القرار الذي اتخذه `internal/sabnzbd` لـ `mode=history&name=delete`، ولنفس السبب. من `internal/sabnzbd/api.go:596-609`:

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

حالة qBittorrent تشبه هذه الحالة مع اختلاف واحد: في هذه الواجهة، حذف البيانات مهمة *العميل* وليس مهمة \*arr، لأن `RemoveItem` **لا** يستدعي `DeleteItemData` (§1.15). لكن \*arr حذف المجلد نفسه بالفعل في الخطوة 2 أعلاه، عبر الـ mount. وتحت `__magic__` يكتب الـ mount علامة حذف: يختفي الإدخال من `__magic__` ويبقى في مكانه تماماً في `__all__`، وفي كل مجلد تصفية، وفي حساب الخدمة السحابية ([magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)).

لذلك:

- **يحذف `torrents/delete` *سجل* التورنت الذي تحتفظ به الطبقة الوسيطة للـ \*arr.** أعد 200.
- **يجب ألا يحذف `deleteFiles` التورنت من المزوّد.** الإصدار الذي استوردته \*arr للتو لا يزال يُبَثّ منه، وحذفه يدمّر الشيء الذي تم استيراده. المكان الوحيد الذي يكون فيه الحذف الحقيقي صادقاً هو تورنت لم يُستورد منه أي شيء قط، أي مسار التنزيلات الفاشلة. وحتى هناك، التورنت في الخدمة السحابية حالة مكتبة مشتركة وليس تنزيلاً مؤقتاً، لذا الافتراض الآمن هو: **لا تحذف التورنت من المزوّد أبداً، ضع علامة حذف فقط.** قل ذلك في الوثائق الموجهة للمستخدم، بالطريقة التي يفعلها [sabnzbd.md](../guides/sonarr-radarr.md) تحت *What works, and what does not*.
- يجب أن يُرجع `torrents/delete` لـ **hash غير معروف** 200 أيضاً. هذا ما تفعله qBittorrent الحقيقية (الويكي، *Delete torrents*: "200 | All scenarios")، والخطأ هنا يُسجَّل كخطأ ويُعاد محاولته في كل استطلاع إلى الأبد.

### 5.3 `MarkItemAsImported` وفئة ما بعد الاستيراد {#53-markitemasimported-and-the-post-import-category}

`QBittorrent.cs:52-69` يضبط الفئة بعد الاستيراد عندما تكون `TvImportedCategory` /
`MovieImportedCategory` مُعدّة ومختلفة عن الفئة الرئيسية. تُستدعى هذه الدالة مع **كل**
عملية استيراد مكتملة (`DownloadEventHub.cs:54`)، وذلك قبل قرار الإزالة.

إذا كان shim يلتزم بـ `setCategory` فينقل التورنت فعليًا خارج الفئة التي يُستعلم عنها، فيختفي التورنت من الاستعلام التالي `torrents/info?category=…`. وهذا بالضبط ما يُفترض أن يفعله هذا الإعداد، وما تعرضه الواجهة باسم `DownloadClientHasPostImportCategory` (`src/NzbDrone.Core/Queue/QueueService.cs:84`، ويأتي من `DownloadClientItemClientInfo.HasPostImportCategory`، `QBittorrent.cs:234`). قبول الاستدعاء وتسجيل الفئة الجديدة هو السلوك الصحيح، أما رفضه فيؤدي فقط إلى تحذير (`:62-67`).

## 6. `Test()` — كل فحص، بالترتيب، ورسالته {#6-test--every-check-in-order-and-its-message}

`DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`) يلفّ الدالة كلها: **أي استثناء (exception) يطلع منها يتحول إلى** `ValidationFailure("", "Test was aborted due to an error: " + ex.Message)`.

`QBittorrent.Test(List<ValidationFailure>)` (`:418-429`):

```csharp
failures.AddIfNotNull(TestConnection());
if (failures.HasErrors()) { return; }     // a *warning* does not stop the rest
failures.AddIfNotNull(TestCategory());
failures.AddIfNotNull(TestPrioritySupport());
failures.AddIfNotNull(TestGetTorrents());
```

### 6.1 `TestConnection` (`:431-509`)

كل فرع **يُرجع** قيمة، لذلك لا يخرج من هذه الدالة إلا فشل واحد على الأكثر.

| الترتيب | الشرط | الخاصية | الرسالة |
|---|---|---|---|
| 1 | `_proxySelector.GetProxy(Settings, force: true).GetApiVersion(Settings)` — يفرض إعادة الكشف (`:435`) | | |
| 2 | الإصدار `< 1.5` (`:436`) | `Host` | "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| 3 | الإصدار `< 1.6` **و** الفئة مضبوطة (`:445-455`) | `Category` | "Category is not supported" / التفصيل "Categories are not supported until qBittorrent version 3.3.0. Please upgrade or try again with an empty Category." |
| 4 | الإصدار `>= 1.6` **و** الفئة فارغة (`:456-464`) | `TvCategory` / `MovieCategory` | **تحذير** — "Category is recommended" / "{appName} will not attempt to import completed downloads without a category." |
| 5 | `GetConfig` ثم `RemovesCompletedDownloads(config)` (`:467-474`) | `""` | "qBittorrent is configured to remove torrents when they reach their Share Ratio Limit" / التفصيل الذي يذكر Options → BitTorrent → Share Ratio Limiting |

تعيين الاستثناءات (`:476-506`):

| الاستثناء الملتقط | الخاصية | الرسالة |
|---|---|---|
| `DownloadClientAuthenticationException` | `ApiKey` إذا كان مفتاح API مضبوطًا، وإلا `Username` | "Authentication Failure" / "Please verify your credentials. Also verify if the host running {appName} isn't blocked from accessing {clientName} by WhiteList limitations…" |
| `WebException` مع `Status == ConnectFailure` | `Host` | "Unable to connect to qBittorrent" / "Please verify the hostname and port." |
| أي `WebException` آخر | `""` | "Unknown exception: {message}" |
| أي `Exception` آخر | `Host` | "Unable to connect to qBittorrent"، مع `DetailedDescription = ex.Message` |

لاحظ أن الحالة 4 هي **تحذير**، و`failures.HasErrors()` في `:421` تُرجع false للتحذيرات. لذلك فإن الإعداد بدون فئة ما زال يشغّل الفحوص الثلاثة المتبقية.

### 6.2 `TestCategory` (`:511-556`) — مسار "category does not exist" {#62-testcategory-511-556--the-category-does-not-exist-flow}

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

الفشل: الخاصية `TvCategory` / `MovieCategory` (أو `TvImportedCategory` / `MovieImportedCategory`)،
الرسالة "Configuration of category failed"، والتفاصيل "{appName} was unable to add the label to
qBittorrent."

إذن على الطبقة الوسيطة (shim) أن تختار: إما أن ترسل الفئات المهيأة من البداية بحيث تكون موجودة أصلاً في `torrents/categories`، أو أن تقبل `createCategory` وتعكسها في الرد التالي مباشرة من `torrents/categories`. **لا يوجد خيار ثالث**، لأن العميل يعيد القراءة ويفشل إذا بقي المفتاح مفقوداً.

تُطابَق أسماء الفئات **بدقة** ومع مراعاة حالة الأحرف (`Dictionary<string, …>.ContainsKey` مع المقارن الترتيبي (ordinal) الافتراضي).

انتبه إلى التعامل مع `TvImportedCategory`: الفئة التي تُستخدم بعد الاستيراد تُفحص وتُنشأ هنا أيضاً، حتى مع أنها لا تُستخدم إلا بعد عملية استيراد. إذا حدّد المشغّل قيمة لها، يجب أن تكون موجودة.

يرفض `QBittorrentSettingsValidator` (`QBittorrentSettings.cs:23-24`) أسماء الفئات التي تطابق التعبير النمطي `^([^\\\/](\/?[^\\\/])*)?$`، أي التي تحتوي على شرطة مائلة عكسية، أو `//`، أو `/` في البداية أو النهاية، وذلك قبل إرسال أي طلب.

### 6.3 `TestPrioritySupport` (`:558-597`) — فحص الصحة `queueing` {#63-testprioritysupport-558-597--the-queueing-health-check}

```csharp
var recentPriorityDefault = Settings.RecentTvPriority == (int)QBittorrentPriority.Last;
var olderPriorityDefault  = Settings.OlderTvPriority  == (int)QBittorrentPriority.Last;
if (olderPriorityDefault && recentPriorityDefault) { return null; }   // :563-566  the default: nothing checked

var config = Proxy.GetConfig(Settings);
if (!config.QueueingEnabled) { … }                                    // :572-588
```

خاصية الفشل هي `nameof(Settings.RecentTvPriority)` أو `nameof(Settings.OlderTvPriority)` (يتم فحصهما بهذا الترتيب)، والرسالة "Queueing Not Enabled"، والتفاصيل "Torrent Queueing is not enabled in your qBittorrent settings. Enable it in qBittorrent or select 'Last' as priority."

يتحول أي استثناء هنا إلى `("", "Unknown exception: {message}")` (`:590-594`).

القيمة الافتراضية لـ `queueing_enabled` هي **`true`** في النموذج (`QBittorrentPreferences.cs:41`)، لذا فإن الـ shim الذي لا يتضمن هذا المفتاح سينجح، لكن حذفه يُعدّ كذبة إذا كان `topPrio` لا يفعل شيئاً. الإبلاغ عن `queueing_enabled: false` صادق، وهو لا يُنتج هذا الفشل **إلا** إذا غيّر المشغّل إعداد الأولوية بعيداً عن `Last`.

### 6.4 `TestGetTorrents` (`:599-612`)

`Proxy.GetTorrents(Settings)`; any exception becomes `("", "Failed to get the list of torrents:
{exceptionMessage}")`. This is the check that catches a malformed `torrents/info` body — a JSON object
instead of an array, a bad enum, a non-numeric `size`.

### 6.5 فحص `dht` {#65-the-dht-check}

أما **لا يوجد** فحص مخصص لـ DHT داخل `Test()`. يُستشار `dht` وقت الالتقاط (`:73-76`، للـ magnets التي لا تحتوي على trackers) وكذلك وقت الاستطلاع (`:288`، فرع `metaDL`). إذا أرجع الـ shim القيمة `dht: false`، فإنه يجتاز اختبار الاتصال، ثم يرفض كل magnet بلا trackers مع `ReleaseDownloadException("Magnet not supported by download client. …")` (`TorrentClientBase.cs:115`). **أرجِع `dht: true`.**

## 7. التحليل وعواقب الاستيراد التي ينبغي لطبقة الوسيط أن تعرفها {#7-parsing-and-import-consequences-a-shim-should-know}

### 7.1 يصبح `name` هو `Title`، ويُستخدم `Title` لثلاثة أغراض مختلفة {#71-name-becomes-title-and-title-is-used-for-three-different-things}

`DownloadClientItem.Title = torrent.Name` (`QBittorrent.cs:232`). بعد ذلك:

1. **تحديد المسلسل/الفيلم.** `CompletedDownloadService.Check` ينفذ `_parsingService.GetSeries(trackedDownload.DownloadItem.Title)` (`CompletedDownloadService.cs:95`). إذا رجع null يلجأ إلى **سجل الـ grab** المفتاح فيه `DownloadId` (`:99-102`)، وإذا كان هذا مفقوداً أيضاً تظهر الرسالة "Series title mismatch; automatic import is not possible." مع `ImportBlocked` (`:104-110`). المعادل في Radarr موجود في `ProcessFolder`، اللي يقرأ `_historyService.FindByDownloadId(downloadClientItem?.DownloadId ?? "")` (`DownloadedMovieImportService.cs:193-194`).
   **هذا هو السبب الثاني لأن الـ shim لازم يطابق الـ infohash بالضبط كما حسبه الـ \*arr** (§1.7): الاحتياط من السجل يعتمد على `DownloadId`، فلو الـ hash مختلف نخسر مسار العنوان والاحتياط معاً.
2. **تحليل الإصدار لقرار الاستيراد.** `downloadClientItemInfo = Parser.Parser.ParseTitle(downloadClientItem.Title)` (Sonarr `ImportDecisionMaker.cs:80`؛ Radarr `ParseMovieTitle`، `:80`)، وتتعيّن إلى `LocalEpisode.DownloadClientEpisodeInfo` / `LocalMovie.DownloadClientMovieInfo` (`:94` / `:92`).
3. **سطور السجل وواجهة الطابور.**

**بوابة الاحتياط بالعنوان في Sonarr.** `AggregateEpisodes.GetBestEpisodeInfo` (`src/NzbDrone.Core/MediaFiles/EpisodeImport/Aggregation/Aggregators/AggregateEpisodes.cs:29-57`):

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

ثلاث بوابات تمنع استخدام عنوان الـ download client بدل اسم الملف: `!OtherVideoFiles`، واسم الملف نفسه ليس عنوان scene، وعنوان الـ client ليس تحليل موسم كامل. يعني اسم الـ torrent لا ينقذ إلا الإصدار اللي فيه ملف واحد وما له اسم scene.

Radarr ما عنده بوابة "فائز واحد" مماثلة. `LocalMovie.OtherVideoFiles` موجود (`src/NzbDrone.Core/Parser/Model/LocalMovie.cs:36`)، لكن المعلومات المحللة للفيلم تُدمج عبر سلسلة من المُعززات (augmenters) مرتبة حسب الثقة بدل ما يُختار واحد منها (`AggregateQuality.cs:25-121`). عنوان الـ download client يغذي هذه المُعززات، وهوية الفيلم تأتي من تحليل اسم المجلد مع سجل الـ grab (`DownloadedMovieImportService.cs:192-195`).

**`OtherVideoFiles`** (`ImportDecisionMaker.cs:85`، `:100`، Radarr `:83`، `:98`):

```csharp
var nonSampleVideoFileCount = sceneSource ? GetNonSampleVideoFileCount(newFiles, series, downloadClientItemInfo, folderInfo) : videoFiles.Count;
…
OtherVideoFiles = nonSampleVideoFileCount > 1
```

`ProcessFolder` يمرر دائماً `sceneSource: true` (`DownloadedEpisodesImportService.cs:201`)، فالمجلد اللي فيه فيديوهان أو أكثر (غير العينات) يضبط `OtherVideoFiles`، ويخرج عنوان الـ download client من الحسبة لكل ملف فيه.

**ليش هذا مهم على zurg.** Real-Debrid يعيد كتابة أسماء الإصدارات اللي تصطدم بفلتر الملفات عنده: `WEB-DL`، و`WEB.x264` و`WEB.H264` بالحالة الدقيقة فقط، و`WEBRip`، `BDRip`، `HDRip`، `DVDRip`، `HDTV.x264`، `HDTV.XviD`، `BluRay.x264` و`p.BluRay.DTS` بأي حالة، حسب القياس بتاريخ 2026-10-14. وzurg يضيف لاحقة لما إصدارين يتصادمان على نفس الاسم. أي واحد من هذين يقدر يخلي `torrent.name` يتوقف عن تحليله كنفس الإصدار اللي تم grab له. انظر قسم RD 451 في `CLAUDE.md` الخاص بالمستودع الأحادي (monorepo). النتائج بالترتيب: التعرف يرجع لسجل الـ grab (لا بأس إذا تطابق الـ hash)؛ وتحليل Sonarr لكل ملف يتولى الأمر (تمام لملف باسم واضح داخل المجلد)؛ واسم المجلد تحت `__magic__`، اللي يقرأه `Parser.ParseTitle(directoryInfo.Name)` في `DownloadedEpisodesImportService.cs:184`، يصير الشي الثاني اللي لازم يبقى قابل للتحليل.

### 7.2 يتجاهل فحص مجلد الاستيراد الأشجار الفرعية كاملةً {#72-the-import-folder-scan-drops-whole-subtrees}

`DiskScanService.FilterPaths` (`src/NzbDrone.Core/MediaFiles/DiskScanService.cs:232-246`)، يُطبَّق على مجلد التنزيل في `DownloadedEpisodesImportService.cs:185` (وفي Radarr: `DownloadedMovieImportService.cs:202`) مع `filterExtras: true`:

```csharp
private static readonly Regex ExcludedExtrasSubFolderRegex = new Regex(@"(?:\\|\/|^)(?:extras|extrafanart|behind the scenes|deleted scenes|featurettes|interviews|other|scenes|samples|shorts|trailers)(?:\\|\/)", …IgnoreCase);   // :72
private static readonly Regex ExcludedSubFoldersRegex      = new Regex(@"(?:\\|\/|^)(?:@eadir|\.@__thumb|plex versions|\.[^\\/]+)(?:\\|\/)", …IgnoreCase);   // :73
private static readonly Regex ExcludedExtraFilesRegex      = new Regex(@"(-(trailer|other|behindthescenes|deleted|featurette|interview|scene|short)\.[^.]+$)", …IgnoreCase);   // :74
private static readonly Regex ExcludedFilesRegex           = new Regex(@"^\.(_|unmanic|DS_Store$)|^Thumbs\.db$", …IgnoreCase);   // :75
```

**تعبير الملفات الإضافية (extras) النمطي في Radarr يختلف ببند واحد**: `sample[s]?` بدلاً من `samples` (Radarr `DiskScanService.cs:72`)، لذلك يتجاهل Radarr مجلد `sample/` أيضاً، بينما يتجاهل Sonarr مجلد `samples/` فقط. كل شيء آخر في التعبيرات الأربعة متطابق بين المستودعين.

انتبه إلى البند `\.[^\\/]+` في `ExcludedSubFoldersRegex`: **أي مكوّن مجلد يبدأ بنقطة يُستبعد**، في أي عمق كان. والمطابقة تتم مع `basePath.GetRelativePath(path)`، أي أنها محصورة ضمن ما تحت مجلد الاستيراد، فوجود نقطة في مجلد أعلى من نقطة التركيب لا يضر.

لا تصل إلى الفلتر أصلاً إلا الملفات التي امتدادها موجود في `MediaFileExtensions.Extensions` (`DiskScanService.GetVideoFiles`, `:202-215`).

### 7.3 يقرأ اكتشاف العينات الملف {#73-sample-detection-reads-the-file}

تستدعي `GetNonSampleVideoFileCount` (`ImportDecisionMaker.cs:216-234`) الدالة `_detectSample.IsSample(...)` لـ**كل** ملف فيديو داخل المجلد.
لا تتخطى `DetectSample.IsSample`
(`src/NzbDrone.Core/MediaFiles/EpisodeImport/DetectSample.cs:27-45`) الفحص إلا للحلقات الخاصة وملفات `.flv` و`.strm` (`:78-101`). غير ذلك، تستدعي `_videoFileInfoReader.GetRunTime(path)` — **ffprobe على الملف، عبر الـ mount** — وتقارن النتيجة بحد أدنى مشتق من المدة المتوقعة (`:103-121`).
أي مدة تساوي 0 بالضبط تُعامَل على أنها **عينة** (`:107-111`)، وإذا لم تُعرف المدة يُسجَّل السطر "Failed to get runtime from the file, make sure ffprobe is available" ويُرجَع Indeterminate (`:38-42`).

تُشغّل `ShouldDeleteFolder` (`DownloadedEpisodesImportService.cs:117-133`) الفحص نفسه مرة أخرى على ما يتبقى بعد عملية النقل.

إذن، استيراد إصدار مكوّن من N ملفاً يكلّف على الأقل N عملية فتح بواسطة ffprobe على الخلفية الخاصة بالـ debrid قبل نقل أي شيء. وهذه تكلفة حقيقية على mount من نوع zurg، ولا يمكن تجنّبها من جهة العميل.

### 7.4 عمليات الرفض في `ProcessFolder` / `ProcessFile` {#74-the-refusals-in-processfolder--processfile}

| الشرط | النتيجة | السطر (Sonarr) |
|---|---|---|
| مسار الاستيراد هو مجلد مسلسل/فيلم | `ImportRejectionReason.SeriesFolder` — "Import path is mapped to a series folder" (Radarr: `MovieFolder`, "…a movie folder") | `:175-182` (Radarr `:183-190`) |
| اسم المجلد لا يطابق أي مسلسل/فيلم معروف | `UnknownSeriesResult("Unknown Series")` | `:160-168` |
| اسم الملف يبدأ بـ `._` | `InvalidFilePath` | `:251-259` |
| الامتداد موجود في `FileExtensions.DangerousExtensions` | `DangerousFile` | `:263-271` |
| الامتداد موجود في `FileExtensions.ExecutableExtensions` | `ExecutableFile` | `:273-281` |
| الامتداد غير موجود في `MediaFileExtensions.Extensions` | `UnsupportedExtension` | `:283-293` |

**`SeriesPathExists` / `MoviePathExists` هو الشرط الذي يسبب المشاكل مع تخطيط `__magic__`.** إذا كان المجلد الجذري لـ \*arr هو `/mnt/zurg/__magic__/tv` وكان مجلد المسلسل هو `/mnt/zurg/__magic__/tv/The Show`، فإن مسار استيراد *يكون* مجلد مسلسل بالصدفة يُرفض فوراً. ولهذا السبب يجب أن يكون مجلد التنزيل (`content_path`) بجوار المجلدات الجذرية، وليس داخلها، وهو الترتيب الذي يوصي به [sabnzbd.md](../guides/sonarr-radarr.md) أصلاً:
`save_path` = `/mnt/zurg/__magic__/__all__`، والمجلدات الجذرية `/mnt/zurg/__magic__/tv` و`/mnt/zurg/__magic__/movies`، والإصدارات في `/mnt/zurg/__magic__/__all__/<release>`.

تتم إزالة `_UNPACK_` و`_FAILED_` من اسم المجلد قبل التحليل (`GetCleanedUpFolderName`، `:311-317`).

يتم **تجاهل `IsFileLocked` تماماً عندما يوجد عنصر في download client** (`:187-199`، `:295-304`). فحص القفل يعمل فقط مع عمليات المسح اليدوي أو المسح عبر المجلد الجذري. الـ shim لا يحتاج أبداً للقلق بشأنه.

---

## 8. فحوصات الصحة {#8-the-health-checks}

الثلاثة كلها مشتركة مع عميل SAB، وتم تحليلها في [sabnzbd-client-contract.md §6](sabnzbd-client-contract.md). أما ما يخص qBittorrent تحديدًا فهو:

- **`RemotePathMappingCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs:59-173`) يمرّ على `client.GetStatus().OutputRootFolders`. في qBittorrent يكون هذا هو المجلد الوحيد المحسوب في `QBittorrent.cs:377-407`: قيمة `save_path` العامة، تُستبدل أو تُوسَّع بقيمة `savePath` الخاصة بالفئة المُعدّة (§1.5). يجب أن يكون مسارًا صالحًا **لنظام التشغيل الذي يعمل عليه \*arr** (`:68-113`)، ويجب أن يكون **موجودًا على جهاز \*arr** (`:115-158`). لا يلزم أن يكون قابلًا للكتابة. أما `IsLocalhost`، وهو `Settings.Host == "127.0.0.1" || Settings.Host == "localhost"` (`:406`)، فلا يغيّر إلا أيّ رسالة خطأ من الرسائل الثلاث ستظهر.
- **`DownloadClientRemovesCompletedDownloadsCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:33-66`) يُصدر تحذيرًا كلما كانت `GetStatus().RemovesCompletedDownloads` صحيحة، أي كلما كان العلم المُشتق في §1.4 صحيحًا. أبقِ `max_ratio_enabled` و`max_seeding_time_enabled` معطّلتين (وهذا ما تفعله وصفة §3.5 أصلًا)، وسيبقى التحذير صامتًا.
- **`DownloadClientRootFolderCheck`** هو المكان الوحيد الذي يختلف فيه المستودعان فعلًا: Sonarr يحذّر فقط عندما يكون المجلد الجذر *مساويًا* لمجلد الإخراج، أما Radarr فيحذّر أيضًا عندما يكون المجلد الجذر *يحتوي* على أحدها. التحليل الكامل في [sabnzbd-client-contract.md §6.1](sabnzbd-client-contract.md). والقاعدة العملية هنا هي نفسها: لا تضع مجلدًا جذريًا مساويًا لمسار الحفظ أو أعلى منه، ولا تضعه داخله. فمثلًا `/mnt/zurg/__magic__/tv` مجلد شقيق لـ `/mnt/zurg/__magic__/__all__`.

---

## 9. Sonarr مقابل Radarr — الفرق الكامل {#9-sonarr-vs-radarr--the-complete-diff}

تم التحقق بمقارنة الملفات المجلوبة زوجًا بزوج (بعد توحيد BOM وCRLF)

| الملف | الفرق |
|---|---|
| `QBittorrent.cs` | `TvCategory`→`MovieCategory`، `TvImportedCategory`→`MovieImportedCategory`، `RecentTvPriority`→`RecentMoviePriority`، `OlderTvPriority`→`OlderMoviePriority`، `RemoteEpisode`→`RemoteMovie`؛ و`remoteEpisode.IsRecentEpisode()` → `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` (`:80`، `:137`). **أرقام الأسطر تتطابق سطرًا بسطر.** |
| `QBittorrentSettings.cs` | نفس عمليات إعادة التسمية؛ الفئة الافتراضية `"tv-sonarr"` → `"radarr"` (`:36`)؛ والرمز في نص المساعدة `…EpisodeHelpText` → `…MovieHelpText`. أرقام الأسطر تتطابق. |
| `QBittorrentProxyV2.cs` | إعادة تسمية الفئة؛ و`new[] { HttpStatusCode.Forbidden }` → `[HttpStatusCode.Forbidden]` (تعبير المجموعة collection expression، Sonarr `:401` / Radarr `:400`)؛ وفي Sonarr سطر فارغ إضافي عند السطر 13 ← **Sonarr N = Radarr N−1 لكل N ≥ 14**. |
| `QBittorrentProxyV1.cs` | إعادة تسمية الفئة؛ نفس إزاحة الأسطر الفارغة. |
| `QBittorrentProxySelector.cs` | مسافة مزدوجة زائدة في منشئ Sonarr (`:46`)؛ وسطر فارغ عند السطر 3 ← **Sonarr N = Radarr N−1 لكل N ≥ 4**. |
| `QBittorrentPreferences.cs`، `QBittorrentTorrent.cs`، `QBittorrentState.cs`، `QBittorrentLabel.cs`، `QBittorrentPriority.cs`، `QBittorrentContentLayout.cs` | **متطابقة بايت لبايت.** |
| `TorrentClientBase.cs` | `RemoteEpisode`→`RemoteMovie` في كل الملف؛ وRadarr يعامل أيضًا استجابة HTTP **410 Gone** مثل 404 عند جلب ملف `.torrent` (`:175`)، أما Sonarr فيعامل 404 فقط. الملفان 274 سطرًا. |
| `QBittorrentFixture.cs` | نفس الاختبارات لكن بترتيب مختلف: الاختبار `missingFiles_item_should_have_required_properties` يقع في Sonarr `:296-315` وفي Radarr `:402-420`، و**نسخة Radarr لا تحمل السمة `[Test]`** (`:401` فارغ)، لذلك لا تُنفَّذ هناك أبدًا. Sonarr `:318-421` = Radarr `:297-400`؛ ومن Sonarr `:423` فصاعدًا يكون Radarr = Sonarr − 1. عدد أسطر Sonarr 1000، وعدد أسطر Radarr 998. |
| `DiskScanService.cs` | `ExcludedExtrasSubFolderRegex`: في Radarr التعبير `sample[s]?`، وفي Sonarr `samples` (`:72` في الملفين). التعابير الثلاثة الأخرى متطابقة. |
| خدمات الاستيراد | `Series`/`Episode` مقابل `Movie`؛ وبوابة تفضيل العنوان في `AggregateEpisodes` في Sonarr لا مقابل لها في Radarr (§7.1). كلاهما يرفض مسار استيراد إذا كان مجلد مكتبة قبل أي شيء آخر (Sonarr `:175-182`، Radarr `:183-190`)، ويحلل اسم المجلد بعد ذلك (Sonarr `:184`، Radarr `:195`)؛ وRadarr يبحث أيضًا عن سجل الإصدارات بواسطة `DownloadId` هناك (`:193-194`). |
| `ImportApprovedEpisodes.cs` / `ImportApprovedMovie.cs` | مفتاح `copyOnly` المتبدل switch متطابق، Sonarr `:139-152` / Radarr `:116-129`. |
| `DiskTransferService.cs`، `DownloadClientBase.cs`، `DownloadEventHub.cs`، `Json.cs`، `HttpClient.cs`، `HttpRequestBuilder.cs` | مشتركة ومتطابقة بايت لبايت. |

كل ما عدا ذلك في هذه الوثيقة **متطابق بايت لبايت باستثناء Series/Movie**، وينطبق على الملفين عند السطر نفسه.

## 10. حمولات مثال دنيا لكنها كاملة {#10-minimal-but-complete-example-payloads}

### 10.1 `GET /api/v2/app/webapiVersion`

```
2.11.2
```

`Content-Type: text/plain`. ليس JSON، ولا يلزم وضع علامات اقتباس، ولا يلزم إضافة سطر جديد في النهاية.

### 10.2 `POST /api/v2/auth/login`

جسم الطلب: `username=sonarr&password=hunter2`، و`application/x-www-form-urlencoded`.

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8
Set-Cookie: SID=8f3c1c0e9a1f4d2f9c0b7a5e3d1f6b2a; path=/

Ok.
```

بيانات الاعتماد غير الصحيحة: يبقى الرد **200**، ويكون المحتوى `Fails.` — ولا يُرجَع 401 أبداً.

### 10.3 `GET /api/v2/app/preferences`

لا يُقرأ إلا المفاتيح العشرة في §1.4؛ يمكنك إرسال غيرها إن أردت، فهي تُتجاهل.

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

المتطلبات الصارمة:

- يجب أن يكون `save_path` موجودًا كمجلد **على جهاز Sonarr/Radarr المضيف** (`RemotePathMappingCheck`، §8).
- يُبقي `max_ratio_enabled: false` و`max_seeding_time_enabled: false` القيمة
  `RemovesCompletedDownloads` على false، وهذا يُبقي اختبار الاتصال (§6.1 الحالة 5) وفحص الصحة بلا تحذيرات.
- `dht: true`، وإلا فإن الروابط المغناطيسية بدون متتبّع ستُرفض من جهة العميل (§6.5).
- يجب أن يكون `max_ratio_act` **عددًا صحيحًا** (§0.6).

### 10.4 `GET /api/v2/torrents/categories`

```json
{
  "tv": { "name": "tv", "savePath": "" },
  "movies": { "name": "movies", "savePath": "" }
}
```

يجب أن يكون **كائن JSON**، وأن يكون `savePath` بصيغة **camelCase**، ولا يبدأ أبدًا بـ `//` (§1.5). إذا كانت قيمة `savePath` فارغة، يبقى مجلد الإخراج الجذري على القيمة العامة `save_path`.

### 10.5 `GET /api/v2/torrents/info?category=tv` — واحد قيد التنزيل، وواحد جاهز للاستيراد {#105-get-apiv2torrentsinfocategorytv--one-downloading-one-importable}

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

متطلبات صارمة:

- يجب أن تكون **مصفوفة** JSON (`List<QBittorrentTorrent>`)؛ فالكائن يسبب خطأً داخل `GetTorrents` ويُفشل `TestGetTorrents` (§6.4).
- يجب أن يكون `hash` **بأحرف صغيرة** (§1.8)، وأن يطابق بالضبط الـ infohash الذي حسبه \*arr من الـ magnet أو
  `.torrent` (§1.7).
- يكون `size` بوحدة **بايت**، و`progress` كسراً بين 0 و1. `RemainingSize = size × (1 − progress)`.
- القيمة `eta: 8640000` تُقرأ على أنها "unknown" فتُرجع `RemainingTime` بقيمة null (`:622-625`)؛ والعنصر Completed يحصل على `TimeSpan.Zero` في كل الأحوال (`:273`).
- قيمة `state` تُؤخذ من جدول §2، وبنفس حالة الأحرف تماماً.
- يجب أن يكون `content_path` **مساراً مطلقاً وموجوداً، ومختلفاً عن `save_path`** في العناصر Completed (§4.1). ويجوز أن يكون فارغاً
  عندما لا يكون العنصر Completed.
- الإعداد `ratio_limit: 0` مع `ratio: 0` هو وصفة النقل (§3.5).
- يجب أن تطابق `category` الفئة المضبوطة في العميل؛ فالعميل لا يُعيد الفلترة، لذلك احترم
  معامل الاستعلام (query parameter).
- يجوز حذف `seeding_time` تماماً؛ فالعميل يلجأ إلى `torrents/properties`، ولا يفعل ذلك إلا
  عندما يكون حد وقت البذر (seeding-time) مفعّلاً فعلاً.

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

تُقرأ فقط القيمتان `save_path` و`seeding_time` (§1.8). **الرد 404 لأي hash غير معروف**، وهكذا تعبّر الدالة `IsTorrentLoaded` عن أن الملف "غير موجود بعد" (`:110-126`).

### 10.7 `GET /api/v2/torrents/files?hash=<hash>`

```json
[
  { "index": 0, "name": "Some.Show.S01E03.1080p.WEB.h264-GRP/ep3.mkv", "size": 1073741824, "progress": 1, "priority": 1, "is_seed": true, "piece_range": [0, 2047], "availability": 1 }
]
```

يُقرأ فقط الحقل `name`، بالنسبة إلى `save_path`، مع فواصل `/` (§1.13). الترتيب مهم في المسار الذي يسبق الإصدار 2.6.1: أعلى مكوّن في `files[0]` يصبح مجلد الإخراج.

### 10.8 `POST /api/v2/torrents/add`

الطلب، بصيغة urlencoded (أما الـ magnet الطويل فيُرسل بصيغة multipart بدلاً من ذلك — §0.3):

```
urls=magnet%3A%3Fxt%3Durn%3Abtih%3A3B1A...&category=tv&stopped=False
```

الاستجابة:

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8

Ok.
```

أي رد غير النص الحرفي `Fails.` يعني نجاحاً (§1.7). وجسم الرد الفارغ مع الحالة 200 يعمل أيضاً.

### 10.9 `POST /api/v2/torrents/delete`

الطلب: `hashes=3b1a1469c180f447b77021074dbbccaef62611e7&deleteFiles=true`

الرد: `HTTP/1.1 200 OK`، والجسم فارغ. **يرجع 200 حتى مع hash غير معروف** (§5.2).

### 10.10 `POST /api/v2/torrents/createCategory`، و`setCategory`، و`setShareLimits`، و`topPrio`، و`setForceStart` {#1010-post-apiv2torrentscreatecategory-setcategory-setsharelimits-topprio-setforcestart}

كلها تقبل نماذج urlencoded وكلها ترد بالحالة `200` مع جسم فارغ. قد ترد `topPrio` بالحالة **409** لتعني "الطابور معطّل"، والعميل يتجاهل هذه الحالة تحديدًا فقط (§1.10). وقد ترد `setShareLimits` بالحالة **404** لتعني "غير مدعوم"، وهذه أيضًا يتم تجاهلها (§1.9).

---

## 11. الاختلافات عن qBittorrent الحقيقي — حيث يكون نموذج zurg أضيق أو أوسع {#11-differences-from-real-qbittorrent--where-zurgs-model-is-narrower-or-wider}

### 11.1 لا توجد مشاركة (seeding)، لذا يجب محاكاة بوابة حد المشاركة {#111-there-is-no-seeding-so-the-seed-limit-gate-has-to-be-faked}

قبل أن نصل إلى الجزء الخاص بـ debrid، يحسب qBittorrent الحقيقي قيمة `ratio` من البايتات التي رفعها فعلاً، ويتيح للمستخدم ضبط حد عام أو حد لكل torrent على حدة. والغرض من البوابة `CanMoveFiles` في العميل هو منع نقل الملفات من تحت torrent ما زال يستوفي التزام الـ ratio (`QBittorrent.cs:240-241`). أما الخلفية الخاصة بـ debrid فلا ترفع أي شيء، أبداً. لذلك تُصرّح الطبقة الوسيطة (shim) بالقيمتين `ratio: 0, ratio_limit: 0`، أي أن حد كل torrent قد تحقق بالفعل. وهذا صادق بالمعنى الوحيد الذي يمكن أن يكون فيه هذا الحقل صادقاً هنا، ويُبقي الإعدادات العامة بعيدة عنه تماماً (§3.5).

### 11.2 `content_path` دائماً مجلد، وليس ملفاً أبداً {#112-content_path-is-always-a-folder-never-a-file}

تُرجع دالة `contentPath()` في qBittorrent الحقيقي **مسار الملف** لتورنت فيه ملف واحد فقط (`torrentimpl.cpp:582-583`). وفي ظل `__magic__`، يكون كل إصدار مجلدًا يحتوي على ملفاته ([magic.md](../guides/magic.md#with-nothing-stored-it-is-__all__s-releases-as-real-folders))، حتى لو كان الإصدار ملفًا واحدًا.

وكل هذه النتائج تصبّ في مصلحة العميل:

- `ProcessPath` يسلك دائمًا فرع **المجلد** (`DownloadedEpisodesImportService.cs:80-90`)، ولا يسلك أبدًا فرع **الملف** (`:92-102`). وفرع المجلد هو الذي يطبّق `FilterPaths` و`ShouldDeleteFolder` وتحليل اسم المجلد، لذلك يبقى فلتر الملفات الإضافية وخيار الرجوع إلى عنوان المجلد مفعّلين دائمًا.
- ما زالت عمليات الرفض لكل ملف في `ProcessFile` (الامتدادات الخطرة أو القابلة للتنفيذ أو غير المدعومة، والبادئة `._`؛ §7.4) قابلة للوصول، لكن عبر فلتر الامتداد في `GetVideoFiles` بدلًا من الفرع على المستوى الأعلى.
- ستعمل أيضًا عملية `GetImportItem` القديمة قبل الإصدار 2.6.1 (§4.2)، لأن `files[0].name` يحمل دائمًا مجلد الإصدار، لكن لا يوجد سبب لاستخدام إصدار قديم إلى هذا الحد.

والشيء الوحيد الذي يجب الانتباه إليه: بما أنه يكون دائمًا مجلدًا، فإن `content_path` يكون دائمًا `save_path + "/" + <release folder>`، ولذلك لا يساوي `save_path` أبدًا. تحذير `DownloadClientQbittorrentTorrentStatePathError` (§4.1) مستحيل الحدوث من الناحية البنيوية، وهذه هي النتيجة الصحيحة، وليست أمرًا يجب الاعتماد عليه بالصدفة.

### 11.3 `name` ليس العنوان الذي أُضيف، ويمكن أن يتغير {#113-name-is-not-the-grabbed-title-and-it-can-change}

qBittorrent الحقيقي يعرض الاسم من البيانات الوصفية (metadata) الخاصة بالتورنت، ولا يتغير هذا الاسم. أما اسم zurg فيأتي من المكتبة:

- يعيد Real-Debrid تسمية الإصدارات التي يتعارض اسم ملفها مع حظر 451 الخاص به (`WEB-DL`، ووسوم `Rip`، وبعض أزواج المصدر-الترميز المفصولة بنقطة)، كما قيس بتاريخ 2026-10-14. انظر قسم RD 451 في `CLAUDE.md` الخاص بالمستودع الأحادي (monorepo).
- يضيف zurg لاحقة عندما يتصادم إصداران على الاسم نفسه، وتعيد عملية الإصلاح بناء الإصدار تحت معرّف تورنت جديد.
- يُقرأ الاسم من المكتبة في كل استطلاع (poll)، لذلك قد يتغير **بين الاستطلاعات** لمعرّف يتتبعه \*arr بالفعل.

لا يكسر أيٌّ من ذلك التتبع، لأن التتبع مبني على `DownloadId`، وهو الـ infohash، وليس على الاسم. لكنه يكسر مسار تحليل العنوان في §7.1. وينتج عن ذلك قاعدتان:

1. **اعتمد على الـ infohash الذي حسبه \*arr**، ولا تعتمد أبداً على أي شيء داخلي خاص بـ zurg. فهو الرابط الوحيد بين الالتقاط وسجل الالتقاطات والاستطلاع.
2. **حافظ على إمكانية تحليل اسم المجلد `__magic__`**، لأنه الخيار الاحتياطي الذي يقرأه فرع المجلدات (`DownloadedEpisodesImportService.cs:184`).

### 11.4 لا يوجد تقدّم ولا مرحلة بيانات وصفية {#114-there-is-no-progress-and-no-metadata-phase}

لا يوجد شيء لتنزيله، لذلك لا توجد قيمة ذات معنى لـ `progress` أو `eta` أو `dlspeed` أو `metaDL`، وهو القيد نفسه الذي توثّقه نقطة نهاية SAB ([sabnzbd.md](../guides/sonarr-radarr.md)، *ما يعمل وما لا يعمل*: "No progress. A job is queued or it is completed"). والتعيين الطبيعي هو: **Queued** (`queuedDL`) طالما لم تُدرج المكتبة الإصدار بعد، و**Completed** (`pausedUP`) بمجرد أن تدرجه *وتستقر أحجام ملفاته*، مع أخذ `size` مما تصرّح به الواجهة الخلفية، حتى لا يبقى مدخل الطابور فارغاً.

لا تستخدم `metaDL` لحالة الانتظار إلا إذا أُبلغ أيضاً عن `dht: true`، فعندها فقط يكون Queued (`:288-297`). أما `queuedDL` فهو غير مشروط ولا يحمل أي رسالة.

لا تستخدم `stalledDL` أو `error` أو `missingFiles` لانتظار عابر، فالثلاثة كلها **تحذيرات** (§2) وتظهر في الطابور كمشكلات.

### 11.5 الحذف يُخفي ولا يُتلف {#115-deleting-hides-it-does-not-destroy}

`torrents/delete?deleteFiles=true` على qBittorrent الحقيقي يحذف التورنت و`rm -rf` لبياناته.
هنا يجب أن يحذف السجل فقط: الإصدار ما زال يُقدَّم من تورنت المزوّد، والمجلد الذي كان الـ\*arr يريده اختفى بالفعل لأنه وضع علامة حذف على نفسه عبر نقطة التركيب (mount) (§5.2، [magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)). هذا هو بالضبط المنطق الذي يوثّقه `deleteFromHistory` في `internal/sabnzbd` عند `internal/sabnzbd/api.go:596-609`.

### 11.6 كل ما قد يطلبه العميل ولا يوجد ما يُطبَّق عليه {#116-everything-the-client-can-ask-for-that-has-nothing-to-apply-to}

`sequentialDownload`، `firstLastPiecePrio`، `contentLayout`، `stopped`/`paused`، `setForceStart`،
`topPrio`، `setShareLimits`، `dlLimit`/`upLimit`: تقبلها كلها وترد بـ 200، ولا تطبّق أي شيء منها. فقط اثنتان لهما تأثير ملحوظ لو رُفضتا: `topPrio` (الـ 409 يُتجاهل، وأي رد آخر يطلع تحذير) و`setShareLimits` (الـ 404 يُتجاهل)، ولا واحدة منهما تمنع عملية الـ grab.

`contentLayout` يستحق ملاحظة: الإعداد موجود في الـ \*arr تحديدًا ليُجبر qBittorrent على الاحتفاظ بمجلد على المستوى الأعلى، بحيث يكون `content_path != save_path`. وتحت `__magic__` يكون التخطيط دائمًا مجلدًا بغض النظر عن ذلك (§11.2)، فالمعامل ده ما لهوش أي تأثير، ويقدر المشغّل يسيبه على Default.

## 12. قائمة التحقق من التنفيذ (14 نقطة) {#12-implementation-checklist-14-points}

1. **واجهة API v2 فقط.** أجب على `/api/v2/app/webapiVersion` بالقيمة `2.11.2`، وأرجع **404** على `/version/api` حتى يفشل فحص v1 بشكل نظيف.
2. **المصادقة:** اقبل ترويسة `Authorization: Bearer <key>`، أو `Authorization: Basic` استباقية، أو كوكي `SID`، أو لا شيء على الإطلاق. أجب على `POST /api/v2/auth/login` بـ **200 + `Ok.` + `Set-Cookie: SID=…`**، وأجب بـ `Fails.` (مع بقاء الحالة 200) عند بيانات اعتماد خاطئة، ولا ترجع أبدًا 401. لا تشترط `Referer` ولا `Origin`.
3. **الأخطاء هي حالات HTTP، وليست JSON.** تعني 403 "سجّل الدخول من جديد" وتُعاد المحاولة مرة واحدة؛ وإذا تكررت 403 فإنها تظهر كخطأ اتصال، لا كخطأ مصادقة. الحالة 404 لها معنى في `torrents/properties` (هاش غير معروف) وفي `torrents/setShareLimits` (غير مدعوم)؛ والحالة 409 لها معنى في `torrents/topPrio` (الطابور معطل). كل ما عدا ذلك يجب أن يكون 200.
4. **حلّل الترميزين الاثنين في `torrents/add`** (urlencoded، وmultipart عندما تتجاوز أي قيمة 1024 بايت أو عند رفع ملف `.torrent`)، واقبل `True`/`False` إلى جانب `true`/`false` لكل قيمة منطقية.
5. **`torrents/info` يعيد مصفوفة، و`torrents/categories` يعيد كائنًا** بحقل `savePath` بصيغة camelCase. احترم معامل الاستعلام `category`، فالعميل لا يعيد الفلترة.
6. **الهاشات: بحروف صغيرة في كل استجابة، وتُطابق دون حساسية لحالة الأحرف في كل طلب**، ودائمًا يكون هو infohash الذي حسبه الـ \*arr من الـ magnet أو ملف `.torrent`. `torrents/properties` هو المسار الوحيد الذي قد يستقبل الهاش بأي حالة أحرف استخدمها `torrents/info`.
7. **وصفة النقل:** `state: "pausedUP"`، و`ratio: 0`، و`ratio_limit: 0`، و`seeding_time_limit: -2`، و`inactive_seeding_time_limit: -2`. أي قيمة أقل من ذلك تجعل الاستيراد **نسخًا**، أي تنزيلًا كاملًا للإصدار. وثّق أن إعداد "Remove Completed" في الـ \*arr يجب أن يبقى مفعّلًا، لأن الـ shim لا يستطيع تعويض ذلك.
8. **يجب أن يكون `content_path` مطلقًا، وأن يكون موجودًا على مضيف الـ \*arr، وألا يساوي `save_path`.** ولا تُعيّنه إلا بعد أن يصبح الإصدار قابلًا للاستيراد فعلًا، أي مدرجًا وأحجام ملفاته مستقرة. وحتى ذلك الحين أبلغ عن `queuedDL` ودع العميل يستمر في الاستعلام؛ لا يوجد حد لإعادة المحاولة.
9. **يجب أن يكون `save_path`** (من `app/preferences`، إضافةً إلى أي `savePath` للفئة) موجودًا كمجلد على مضيف الـ \*arr، وإلا سيرفع `RemotePathMappingCheck` خطأ. لا يلزم أن يكون قابلًا للكتابة. ولا تُرسل أبدًا `savePath` يبدأ بـ `//`.
10. **حافظ على نجاح اختبار الاتصال:** `dht: true`، و`queueing_enabled: true`، و`max_ratio_enabled: false`، و`max_seeding_time_enabled: false`، و`max_ratio_act: 0` (عدد صحيح)، وإما أن تُنشئ الفئات المُعدّة مسبقًا، أو تحترم `createCategory` وتعكسها في استجابة `torrents/categories` التالية مباشرة.
11. **`torrents/delete` يحذف السجل فقط ولا يفعل غيره.** تجاهل `deleteFiles` للتورنت التابع للمزوّد، تمامًا كما يتجاهل `deleteFromHistory` في `internal/sabnzbd` المعامل `del_files` (`internal/sabnzbd/api.go:596-609`). أجب بـ 200 لهاش غير معروف. واقبل `setCategory` وسجّل الفئة الجديدة.
12. **توقّع أن يقوم الـ \*arr بتنفيذ `rm -rf` على مجلد الإصدار بنفسه** بعد استيراد Move (`DownloadedEpisodesImportService.cs:209-223`)، فيصبح ذلك شاهد قبر `__magic__`، ثم يستدعي `torrents/delete` بعد ذلك. الأمران طبيعيان، ولا يدمّر أيٌّ منهما شيئًا.
13. **استخدم فقط أسماء الحالات من §2، وبنفس حالة الأحرف تمامًا.** الاسم غير المعروف لا يُسبب استثناءً هنا (على عكس SAB)، لكنه يسجّل تحذيرًا ويعود افتراضيًا إلى Downloading. لا تستخدم أبدًا `stalledDL` أو `error` أو `missingFiles` للانتظار المؤقت، فكلها تُعد تحذيرات.
14. **لا تضع مجلد جذر في مستوى مجلد الإخراج أو أعلى منه.** مع `save_path` = `/mnt/zurg/__magic__/__all__`، استخدم `/mnt/zurg/__magic__/tv` و`/mnt/zurg/__magic__/movies` كمجلدات جذر، واحتفظ بالإصدارات في `/mnt/zurg/__magic__/__all__/<release>`. وإلا فإن `SeriesPathExists`/`MoviePathExists` ستمنع الاستيراد تمامًا (§7.4)، وسيشتكي `DownloadClientRootFolderCheck` في Radarr عند كل تشغيل.
