# عقد واجهة SABnzbd API كما تستخدمه Sonarr وRadarr (develop) {#sabnzbd-api-contract-as-consumed-by-sonarr-and-radarr-develop}

المصدر الموثوق: الملفات التي جُلبت من `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...`
بتاريخ **2026-08-22**. كل رقم سطر وارد أدناه قُرئ من تلك الملفات.

نحتفظ بهذا هنا كسجلّ لسبب رد `internal/sabnzbd` بالأشكال التي يرد بها. لا ينبغي تغيير أي شيء في تلك الحزمة من دون الفقرة الموجودة هنا التي تشرح ما يفعله العميل بالحقل. وسم بنية (struct tag) خاطئ لا يُفشل شيئًا، بل يترك العميل يقرأ صفرًا، وقيمة تعداد (enum) خاطئة ترمي استثناءً داخل مُحلِّل البيانات الخاص به فتُسقط الاستطلاع كله معها. أما كيفية توجيه Sonarr أو Radarr نحو zurg، فانظر [sabnzbd.md](../guides/sonarr-radarr.md).

ما لم يذكر قسم غير ذلك، **ملفات SAB في المستودعين متطابقة بايت بايت، باستثناء BOM بترميز UTF-8 وإعادة التسمية `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie`، وأرقام الأسطر متطابقة سطرًا بسطر.** لذلك ينطبق كل استشهاد `Sabnzbd*` على المستودعين معًا عند السطر نفسه. المسارات هي `src/NzbDrone.Core/Download/Clients/Sabnzbd/...` في الاثنين. الفروق المتحقق منها مسجلة في §6.

لا شيء هنا تخمين عن SAB نفسه: كل ادعاء يصف ما يفعله *العميل*. وحيثما أذكر سلوك Newtonsoft.Json أو وقت تشغيل .NET (وليس كود Sonarr)، أذكر ذلك صراحةً.

(رُفضت ترجمة سابقة لأن أكواد المقاطع (code spans) كانت مختلفة. حافظ على البنية تمامًا.)

## 0. قواعد على مستوى النقل (هذه أول ما يسبب المشاكل) {#0-transport-level-rules-these-bite-first}

### 0.1 شكل الرابط URL {#01-url-shape}

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

- عنوان URL الأساسي: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-66`)
  = `{http|https}://{Host}:{Port}{UrlBase}`؛ تُضاف `/` في البداية إلى `UrlBase` إذا كانت مفقودة.
  نقطة النهاية هي هذا العنوان + `/api` (`SabnzbdProxy.cs:38-44`).
- تأتي معاملات اللاحقة (Suffix params) دائماً في الآخر، لذلك **`apikey` (أو `ma_username`+`ma_password`) و`output=json` هما آخر معاملات الاستعلام** (`HttpRequestBuilder.cs:82` — `QueryParams.Concat(SuffixQueryParams)`).
- `Accept: application/json` في كل استدعاء. و`output=json` في كل استدعاء. لا يوجد مسار `output=xml` في أي مكان.
- مفتاح API واسم المستخدم/كلمة المرور **لا يجتمعان**: وجود مفتاح API يلغي `ma_username`/`ma_password`.

### 0.2 دائماً يرد بـ HTTP 200 حتى عند الأخطاء {#02-always-answer-http-200--even-for-errors}

`HttpClient.Execute` ترمي استثناءً عند أي حالة >= 400 (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`؛
`HttpResponse.cs:54` — `HasHttpError => (int)StatusCode >= 400`؛ ويتحول 429 إلى `TooManyRequestsException`).
`SabnzbdProxy.ProcessRequest` (`SabnzbdProxy.cs:199-215`) يحوّل ذلك إلى
`DownloadClientException("Unable to connect to SABnzbd, {0}")`.

رسالة `HttpException` هي `"HTTP request failed: [401:Unauthorized] [GET] at [url]"`
(`src/NzbDrone.Common/Http/HttpException.cs:18`) — **نص الاستجابة غير موجود في الرسالة**. لذلك فإن 401 مع
`{"error":"API Key Incorrect"}` **لن** يتعرف عليه `TestAuthentication`
(`Sabnzbd.cs:424,429` تطابق على `ex.Message`)، وفحص الاتصال يعرض الرسالة العامة
"Test was aborted due to an error" بدلاً منها. **قلّد SAB: HTTP 200 + `{"status": false, "error": "..."}`.**

### 0.3 إعدادات فك الترميز (Deserializer) التي تحدد كل أسئلة أسماء الحقول والأنواع {#03-deserializer-settings-drives-every-field-name-and-type-question}

جميع حمولات SAB (SABnzbd) تمر عبر `NzbDrone.Common.Serializer.Json`
(`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`) — **Newtonsoft**، وليس System.Text.Json:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

النتائج (هذه دلالات Newtonsoft، وليست كود Sonarr):

| الإعداد | التأثير على المحاكي |
|---|---|
| `CamelCasePropertyNamesContractResolver` | خاصية `Storage` في C# تربط `storage`، و`PP` تربط `pp`، و`Misc` تربط `misc`. كما أن Newtonsoft يبحث عن الخاصية بدون تمييز بين الحروف الكبيرة والصغيرة، لذلك تُربط مفاتيح SAB الفعلية بصيغة snake_case أو بالحروف الصغيرة في الحالتين. |
| `StringEnumConverter` (عام) | يُطبَّق على `SabnzbdDownloadStatus`، الذي **ليس له** محوِّل خاص بكل خاصية. أسماء التعداد غير المعروفة تسبب `JsonSerializationException`. القيم الصحيحة مقبولة أيضاً (`AllowIntegerValues` قيمته الافتراضية true). |
| `NullValueHandling.Ignore` | ينطبق أيضاً عند **القراءة**: إذا كانت القيمة `null` في JSON، يبقى العضو في C# على القيمة التي وضعها الباني (constructor). لذا `"categories": null` يُبقي القائمة الفارغة التي وضعها الباني، لكن `"misc": null` يترك `Misc` فارغة (لا توجد قيمة افتراضية في الباني) فيحدث NRE، انظر §3.4. |
| `MissingMemberHandling` (الافتراضي `Ignore`) | الحقول الزائدة في الحمولة لا تسبب مشكلة. أرسل جسم SAB الكامل والحقيقي. |
| `Culture` (الافتراضي `InvariantCulture`) | السلاسل الرقمية مثل `"1024.00"` يجب أن تستخدم `.` كفاصل عشري، ومن دون فواصل آلاف. |

`Json.Deserialize<T>` يعيد رمي `JsonReaderException` فقط برسالة أوضح (`Json.cs:39-50`)؛
أما `Json.TryDeserialize<T>` فيتجاهل **فقط** `JsonReaderException` و`JsonSerializationException` (`Json.cs:99-117`). أي استثناء آخر (مثلاً `ArgumentException` من محوِّل timeleft، أو NRE من محوِّل priority) يخرج دون أن يُلتقط.

---

## 1. كل وضع (mode) وكل معامل (parameter) وكل حقل يُستهلك {#1-every-mode-every-parameter-every-field-consumed}

### 1.1 `mode=version` — `SabnzbdProxy.GetVersion` (`SabnzbdProxy.cs:85-95`)

الطلب: `GET /api?mode=version&apikey=KEY&output=json`

نموذج الاستجابة `SabnzbdVersionResponse` (`Responses/SabnzbdVersionResponse.cs:5`):

| مفتاح JSON | نوع C# | ملاحظات |
|---|---|---|
| `version` | `string` | الحقل الوحيد الذي يُقرأ. |

يُقرأ عبر `Json.TryDeserialize`؛ وإذا فشل التحليل يصبح `Version == null` (`SabnzbdProxy.cs:89-92`).

التحليل (`Sabnzbd.cs:334-366`)، والتعبير النمطي في `Sabnzbd.cs:38`:

```csharp
// patch can be a number (releases) or 'x' (git)
private static readonly Regex VersionRegex = new Regex(@"(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+|x)", RegexOptions.Compiled);
```

- بدون مرساة، لذلك يتطابق `4.5.0RC1` و`2.0.0beta1` (ملف الاختبار `SabnzbdFixture.cs:523,553`).
- قد يكون `patch` الحرف `x` حرفيًا (بناءات git)، فيُستبدل بـ `0` (`Sabnzbd.cs:351`).
- الإصدار المكوَّن من **مكوِّنين** (`"4.5"`) لا يتطابق ← `null` ← يفشل التحقق.
- النص الدقيق `"develop"` (غير حساس لحالة الأحرف) يُعامل معاملة خاصة ويصبح `3.0.0` (`Sabnzbd.cs:355-362`)
  وينتج *تحذيرًا* وليس فشلًا (`Sabnzbd.cs:380-387`).

يُجلب الإصدار مرة أخرى (طلب `mode=version` ثانٍ) بواسطة `HasVersion` في
`Sabnzbd.cs:294-332` — ولا يُخزَّن مؤقتًا **إطلاقًا**.

### 1.2 `mode=get_config` — `SabnzbdProxy.GetConfig` (`SabnzbdProxy.cs:97-104`)

**الطلب:** `GET /api?mode=get_config&apikey=KEY&output=json`

يستخدم `Json.Deserialize` (**وليس** Try) — إذا كان الجسم غير صالح، يُرمى استثناء من `GetConfig`.
يجب أن يكون المستوى الأعلى `{"config": {...}}` (`Responses/SabnzbdConfigResponse.cs:5`). راجع §3 للحقول.

### 1.3 `mode=fullstatus` — `SabnzbdProxy.GetFullStatus` (`SabnzbdProxy.cs:106-114`)

الطلب: `GET /api?mode=fullstatus&skip_dashboard=1&apikey=KEY&output=json`

المستوى الأعلى `{"status": {...}}` (`Responses/SabnzbdFullStatusResponse.cs:5`). يُقرأ حقل واحد فقط:

| مفتاح JSON | C# | المصدر |
|---|---|---|
| `completedir` | `string CompleteDir` | `SabnzbdFullStatus.cs:9-10` — ملاحظة: **`completedir`، بدون شرطة سفلية** |

يُستدعى **فقط** عندما لا يكون `config.misc.complete_dir` *مساراً مطلقاً* **و** يكون إصدار SAB >= 2.0 (`Sabnzbd.cs:220-226`). مع `complete_dir` مطلق لا يُستدعى هذا الطلب أبداً، لكن نفّذه على كل حال.

شيء مفيد أن تعرفه: لأن الجسم الفعلي هو `{"status": {...}}` و`SabnzbdJsonError.Status` من نوع `string`، فإن `TryDeserialize<SabnzbdJsonError>` في `CheckForError` يفشل برمي `JsonSerializationException` وينتقل إلى فرع النص العادي، الذي يضبط `Status = "true"` (`SabnzbdProxy.cs:224-240`). الأمر غير ضار، لكنه يعني أن fullstatus لا يمكنه أبداً الإبلاغ عن خطأ عبر مسار JSON.

### 1.4 `mode=queue` (قراءة) — `SabnzbdProxy.GetQueue` (`SabnzbdProxy.cs:116-130`) {#14-modequeue-read--sabnzbdproxygetqueue-sabnzbdproxycs116-130}

الطلب: `GET /api?mode=queue&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- تُضاف `category` **فقط إذا** كانت الفئة المضبوطة غير فارغة (`SabnzbdProxy.cs:122-125`).
- المستدعون: تستخدم `Sabnzbd.GetQueue()` القيمتين `start=0, limit=0` (`Sabnzbd.cs:57`)، ويقرأ SAB القيمة `limit=0` على أنها "الكل"؛ وتستخدم `Sabnzbd.GetCategories()` القيمتين `start=0, limit=1` في المسار الخاص بالإصدارات الأقدم من 2.0 (`Sabnzbd.cs:229`)؛ وتستدعيه `Sabnzbd.RemoveItem()` مرة إضافية لتحديد هل العنصر موجود في الطابور أم في السجل (`Sabnzbd.cs:199`).
- الاستخراج: `Json.Deserialize<SabnzbdQueue>(JObject.Parse(response).SelectToken("queue").ToString())` (`SabnzbdProxy.cs:129`). **غياب المفتاح العلوي `queue` يسبب NRE.**

`SabnzbdQueue` (`SabnzbdQueue.cs`):

| مفتاح JSON | عضو C# | النوع | يُستخدم في |
|---|---|---|---|
| `my_home` | `DefaultRootFolder` | `string` | فقط في SAB الأقدم من 2.0 لحل `complete_dir` النسبي (`Sabnzbd.cs:230`). التعليق في `SabnzbdQueue.cs:8`: "أُزيل في Sabnzbd 2.0.0، استخدم mode=fullstatus بدلاً منه." |
| `paused` | `Paused` | `bool` | الإيقاف المؤقت العام؛ يُدمج مع أولوية العنصر (`Sabnzbd.cs:78`). |
| `slots` | `Items` | `List<SabnzbdQueueItem>` | |

`SabnzbdQueueItem` (`SabnzbdQueueItem.cs`):

| مفتاح JSON | عضو C# | نوع C# | نوع JSON الفعلي في SAB | ملاحظات |
|---|---|---|---|---|
| `status` | `Status` | `SabnzbdDownloadStatus` | string | `StringEnumConverter` عام. أي قيمة غير معروفة ⇒ `JsonSerializationException` ⇒ يرمي `GetQueue` كله استثناءً. |
| `index` | `Index` | `int` | number | يُقرأ ولا يُستخدم أبداً. |
| `timeleft` | `Timeleft` | `TimeSpan` عبر `SabnzbdQueueTimeConverter` | string | انظر §1.4.1. |
| `mb` | `Size` | `decimal` | **string** (`"1024.00"`) | **ميغابايت.** `TotalSize = (long)(Size * 1024 * 1024)` (`Sabnzbd.cs:72`). |
| `mbleft` | `Sizeleft` | `decimal` | **string** | **ميغابايت.** `RemainingSize = (long)(Sizeleft * 1024 * 1024)` (`Sabnzbd.cs:73`). |
| `filename` | `Title` | `string` | string | يصبح `DownloadClientItem.Title` (`Sabnzbd.cs:71`). |
| `priority` | `Priority` | `SabnzbdPriority` عبر `SabnzbdPriorityTypeConverter` | string (`"Normal"`) | انظر §2. |
| `cat` | `Category` | `string` | string | **`cat` في الطابور، و`category` في السجل.** |
| `mbleft`/`percentage` | `Percentage` | `int` | **string** (`"50"`) | يُقرأ ولا يُستخدم أبداً. |
| `nzo_id` | `Id` | `string` | string | معرّف التنزيل الذي يعتمد عليه Sonarr/Radarr في كل شيء. |

#### 1.4.1 صيغة `timeleft` — `SabnzbdQueueTimeConverter` (`JsonConverters/SabnzbdQueueTimeConverter.cs:15-28`) {#141-timeleft-format--sabnzbdqueuetimeconverter-jsonconverterssabnzbdqueuetimeconvertercs15-28}

```csharp
var split = reader.Value.ToString().Split(':').Select(int.Parse).ToArray();
switch (split.Length)
{
    case 4: return new TimeSpan((split[0] * 24) + split[1], split[2], split[3]);   // d:h:m:s
    case 3: return new TimeSpan(split[0], split[1], split[2]);                     // h:m:s
    default: throw new ArgumentException("Expected either 0:0:0:0 or 0:0:0 format, but received: " + reader.Value);
}
```

- **يجب أن تكون 3 أو 4 أعداد صحيحة مفصولة بنقطتين بالضبط.** `"0:08:32"` و`"40:12:14"` و`"1:16:12:14"` كلها صالحة (fixture `SabnzbdQueueTimeConverterFixture.cs:14-20`)؛ أما `"1"` و`"0:1"` و`"0:0:0:0:1"` فترمي استثناءً (`:28-35`). الأصفار البادئة لا تسبب مشكلة (`int.Parse`).
- الاستثناء `ArgumentException` المرمي **لا** يلتقطه `Json.TryDeserialize` ولا `Json.Deserialize`.
- السلسلة **الفارغة** `""` تنقسم إلى `[""]`، فيرمي `int.Parse` استثناء `FormatException`. لذلك لا ترسل `""` أبدًا.
- إذا حذفت `timeleft` تمامًا فلا بأس، لأن المحوِّل لن يُستدعى وستبقى قيمة `Timeleft` هي `TimeSpan.Zero`.

### 1.5 `mode=queue&name=delete` — `SabnzbdProxy.RemoveFromQueue` (`SabnzbdProxy.cs:64-72`)

```
GET /api?mode=queue&name=delete&del_files={0|1}&value={nzo_id}&apikey=KEY&output=json
```

`del_files = deleteData ? 1 : 0` (`SabnzbdProxy.cs:68`). **لا يوجد معامل `archive` في مسار الطابور.**
يُمرَّر جسم الاستجابة عبر `CheckForError` فقط، ولا يتم فك تسلسل أي شيء منه.

### 1.6 `mode=history` (قراءة) — `SabnzbdProxy.GetHistory` (`SabnzbdProxy.cs:132-146`) {#16-modehistory-read--sabnzbdproxygethistory-sabnzbdproxycs132-146}

**الطلب:** `GET /api?mode=history&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- المستدعي: `Sabnzbd.GetHistory()` مع `start=0, limit=_configService.DownloadClientHistoryLimit`
  (`Sabnzbd.cs:110`). الافتراضي **60** في المستودعين (Sonarr `src/NzbDrone.Core/Configuration/ConfigService.cs:184`، وRadarr `:236`).
- الاستخراج: `SelectToken("history")` (`SabnzbdProxy.cs:145`). يجب أن يكون المستوى الأعلى بالشكل `{"history": {...}}`.

`SabnzbdHistory` (`SabnzbdHistory.cs`): `paused` (`bool`، غير مستخدم)، و`slots` ← `Items`.

`SabnzbdHistoryItem` (`SabnzbdHistoryItem.cs`):

| مفتاح JSON | عضو C# | نوع C# | ملاحظات |
|---|---|---|---|
| `fail_message` | `FailMessage` | `string` | يصبح `DownloadClientItem.Message` (`Sabnzbd.cs:132`) ويقود الحالة الخاصة Warning (§1.6.1). |
| `bytes` | `Size` | `long` | **بايت، وليس ميغابايت**. يُنقل `TotalSize = sabHistoryItem.Size` كما هو تماماً (`Sabnzbd.cs:128`). هذا أكبر فرق بين هذا الطلب و`mode=queue`. |
| `category` | `Category` | `string` | ملاحظة: `category`، في حين أن الطابور يستخدم `cat`. |
| `nzb_name` | `NzbName` | `string` | تتم قراءته، ولا يُستخدم أبداً. |
| `download_time` | `DownloadTime` | `int` (بالثواني) | تتم قراءته، ولا يُستخدم أبداً. |
| `storage` | `Storage` | `string` | مسار الإخراج. راجع §1.6.2، فهذا هو المسار الذي يُحذف بالأمر `rm -rf`. |
| `status` | `Status` | `SabnzbdDownloadStatus` | `StringEnumConverter` عام. |
| `nzo_id` | `Id` | `string` | |
| `name` | `Title` | `string` | |

**لا يوجد عضو من نوع `DateTime` في أي مكان في نماذج SAB، لذلك لا يُفرض أي تنسيق تاريخ.**
لا تتم قراءة `completed` / `last_history_update` (بصيغة unix epoch في SAB الفعلي) أبداً. القيم الزمنية الوحيدة المهمة هي `timeleft` (§1.4.1) و`download_time` (عدد صحيح من الثواني لا يُقرأ).

#### 1.6.1 حالة السجل ← `DownloadItemStatus` (`Sabnzbd.cs:116-158`) {#161-history-status--downloaditemstatus-sabnzbdcs116-158}

```
Deleted                                   -> skipped entirely (Sabnzbd.cs:116-119)
Failed  + fail_message == "Unpacking failed, write error or disk is full?"
        (InvariantCultureIgnoreCase)      -> DownloadItemStatus.Warning     (:140-144)
Failed  (any other message)               -> DownloadItemStatus.Failed      (:147)
Completed                                 -> DownloadItemStatus.Completed   (:152)
anything else (Verifying/Moving/...)      -> DownloadItemStatus.Downloading (:157)
```

كل عنصر في السجل يحصل على `RemainingSize = 0`، و`RemainingTime = TimeSpan.Zero`، و`CanBeRemoved = true`، و`CanMoveFiles = true` (`Sabnzbd.cs:129-135`).

الـ `DownloadItemStatus` نفسه (`src/NzbDrone.Core/Download/DownloadItemStatus.cs:3-11`): `Queued=0, Paused=1, Downloading=2, Completed=3, Failed=4, Warning=5`.

#### 1.6.2 `storage` ← `OutputPath` (`Sabnzbd.cs:160-176`) {#162-storage--outputpath-sabnzbdcs160-176}

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

تمرّ الحلقة **حتى الجذر** وتحتفظ بأعلى سلف يكون آخر مقطع فيه مساوياً لـ `name`. الغرض من ذلك: إذا كان `storage` يشير إلى ملف داخل مجلد المهمة، يرجع الكود إلى مجلد المهمة (تركيبة الاختبار `SabnzbdFixture.cs:376-391`). أما إذا كان `storage` هو مجلد المهمة نفسه، فلن يتطابق أي سلف، ويبقى `OutputPath == storage`، وهذا هو المطلوب.

**التوصية للمحاكي: اضبط `storage` على مسار مجلد المهمة نفسه.**

إذا كان `storage` فارغاً، يبقى `OutputPath` فارغاً، فتظهر من `CompletedDownloadService.ValidatePath` التحذيرة "Download doesn't contain intermediate path, Skipping." (Sonarr `CompletedDownloadService.cs:299-303`).

### 1.7 `mode=history&name=delete` — `SabnzbdProxy.RemoveFromHistory` (`SabnzbdProxy.cs:74-83`)

```
GET /api?mode=history&name=delete&del_files={0|1}&value={nzo_id}&archive={0|1}&apikey=KEY&output=json
```

```csharp
request.AddQueryParam("del_files", deleteData ? 1 : 0);          // :78
request.AddQueryParam("value", id);                              // :79
request.AddQueryParam("archive", deletePermanently ? 0 : 1);     // :80   <-- inverted
```

والاستدعاء في `Sabnzbd.cs:208`:

```csharp
_proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
```

إذن `deletePermanently == (status is Failed)`، وبالتالي:

| حالة العنصر | `del_files` | `archive` |
|---|---|---|
| Completed | 1 | **1** (أرشفته) |
| Failed | 1 | **0** (حذف نهائي) |

صحيح أن هذا يبدو معكوسًا للوهلة الأولى، لكن هذا بالضبط ما يفعله الكود.

### 1.8 `mode=addfile` — `SabnzbdProxy.DownloadNzb` (`SabnzbdProxy.cs:46-62`)

```
POST /api?mode=addfile&cat={category}&priority={int}&apikey=KEY&output=json
Content-Type: multipart/form-data; boundary=...
  part: Content-Disposition: form-data; name="name"; filename="<CleanFileName(Release.Title)>.nzb"
        Content-Type: application/x-nzb
```

- حقل multipart هو `name` حرفياً، والجزء يحمل `filename` (`SabnzbdProxy.cs:53`،
  `HttpRequestBuilder.cs:379-395`، ويُرسل عند `:180-195`).
- يأتي اسم الملف من `FileNameBuilder.CleanFileName(release.Title) + ".nzb"`
  (Sonarr `src/NzbDrone.Core/Download/UsenetClientBase.cs:43`، Radarr `:43`).
- **`cat` يتجاهل معامل `category` الخاص بالدالة** ويقرأ الإعدادات مباشرةً
  (`SabnzbdProxy.cs:50`: `request.AddQueryParam("cat", settings.TvCategory);` — في Radarr: `settings.MovieCategory`). الأمر لا يضر، لأن المستدعي يمرر القيمة نفسها.
- `priority` هو القيمة الخام من نوع `int` القادمة من `SabnzbdPriority` (انظر §2)، وتُختار حسب حداثة المحتوى:
  Sonarr `Sabnzbd.cs:43` `remoteEpisode.IsRecentEpisode() ? Settings.RecentTvPriority : Settings.OlderTvPriority`؛
  Radarr `Sabnzbd.cs:43` `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie ? RecentMoviePriority : OlderMoviePriority`.
- الاستجابة `SabnzbdAddResponse` (`Responses/SabnzbdAddResponse.cs`):

| مفتاح JSON | C# | النوع |
|---|---|---|
| `status` | `Status` | `bool` — يُحلَّل، ثم **لا يُقرأ أبداً** |
| `nzo_ids` | `Ids` | `List<string>`، تُهيَّأ في المُنشئ كقائمة فارغة |

  تُقرأ بواسطة `TryDeserialize`؛ وعند الفشل يُستخدم كائن وهمي `{Status=true, Ids=[]}` (`SabnzbdProxy.cs:55-59`).
  ثم `Sabnzbd.cs:47-52`:

```csharp
if (response == null || response.Ids.Empty())
{
    throw new DownloadClientRejectedReleaseException(remoteEpisode.Release, "SABnzbd rejected the NZB for an unknown reason");
}

return response.Ids.First();
```

  **يجب أن يكون `nzo_ids` مصفوفة نصوص غير فارغة.** القيمة `"nzo_ids": null` تعادل غيابه تماماً (`NullValueHandling.Ignore` يُبقي القائمة الفارغة التي يُنشئها المُنشئ)، وتفشل بالطريقة نفسها.

### 1.9 حالة الطابور ← `DownloadItemStatus` (`Sabnzbd.cs:60-103`) {#19-queue-status--downloaditemstatus-sabnzbdcs60-103}

```
Deleted                                       -> skipped (Sabnzbd.cs:62-65)
(queue.paused && slot.priority != Force) || slot.status == Paused
                                              -> Paused, and RemainingTime forced to null (:78-84)
Queued | Grabbing | Propagating               -> Queued        (:85-90)
everything else                               -> Downloading   (:93)
```

وأيضاً في `Sabnzbd.cs:96-100`: أي عنوان يبدأ بالنص الحرفي `"ENCRYPTED /"` يُزال منه هذه الأحرف
11 ويُعلَّم العنصر بـ `IsEncrypted = true`.

كل عنصر في الطابور يحصل على `CanBeRemoved = true` و`CanMoveFiles = true` (`Sabnzbd.cs:75-76`).

### 1.10 فلتر الفئات من جهة العميل (`Sabnzbd.cs:186-195`) {#110-client-side-category-filter-sabnzbdcs186-195}

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

مقارنة النص بشكل حرفي (ordinal). العنصر الذي فئته `*` يُقبل فقط عندما تكون الفئة المُعدّة فارغة.

### 1.11 أوضاع موجودة في الـ proxy لكنها لا تُستدعى أبداً {#111-modes-that-exist-in-the-proxy-but-are-never-called}

- `mode=retry&value={id}` (`SabnzbdProxy.cs:148-160`، الاستجابة `{status, nzo_id}` → `Responses/SabnzbdRetryResponse.cs`). `ISabnzbdProxy.RetryDownload` **ما عنده أي مستدعٍ** في أي من المستودعين.
- `Responses/SabnzbdCategoryResponse.cs` (`{"categories": [...]}`، يعني `mode=get_cats`) **غير مستخدم تماماً** في المستودعين كليهما.
- `Sabnzbd.ValidatePath` (`Sabnzbd.cs:576-592`) دالة خاصة (private) وما حدا بيناديها أبداً (كود ميت).

---

## 2. `SabnzbdDownloadStatus` و`SabnzbdPriority` — الأعضاء بالضبط ومعالجة القيم غير المعروفة أو null {#2-sabnzbddownloadstatus-and-sabnzbdpriority--exact-members-unknownnull-handling}

### 2.1 `SabnzbdPriority.cs` (الملف كاملاً) {#21-sabnzbdprioritycs-complete-file}

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

- `Enum.TryParse<T>(string, out T)` هي النسخة **الحساسة لحالة الأحرف** (حسب دلالات .NET).
  `"Normal"` تُحلَّل بنجاح، لكن `"normal"` **لا** تُحلَّل. وعند الفشل تكون قيمة `output` هي `default(SabnzbdPriority) == 0 == Normal`، أي أن حالة الأحرف الخاطئة تُنزل القيمة إلى Normal بصمت.
  `"Force"` مهمة (§1.9)، أما `"force"` فلا تعمل.
- السلاسل الرقمية تُحلَّل أيضًا: `"2"` تصبح `Force`، و`"-100"` تصبح `Default`. ورقم JSON `2` يعمل كذلك (`reader.Value.ToString()` تساوي `"2"`).
- **`"priority": null` يرمي `NullReferenceException`** (لأن `reader.Value.ToString()` تُستدعى على null). هذا الخطأ **لا** يُلتقط بواسطة `Json.TryDeserialize`. احذف المفتاح أو أرسل قيمة حقيقية.
- حذف `priority` آمن: لا يُستدعى المحوّل، ويبقى العضو على `Normal` (0).
- المحوّل مسجَّل فقط على `SabnzbdQueueItem.Priority` (`SabnzbdQueueItem.cs:21`)، وعناصر السجل ليس لها أولوية.
- هذه الأعداد الصحيحة نفسها هي ما يرسله Sonarr/Radarr مرة أخرى كـ `&priority=` في `mode=addfile`. (`SabnzbdSettings.cs` يضبط القيم الافتراضية لكل من `Recent*Priority` و`Older*Priority` على `(int)SabnzbdPriority.Default` = `-100`).

### 2.2 `SabnzbdDownloadStatus.cs` (الملف كاملاً)، ترتيب التصريح هو القيم الضمنية 0..15 {#22-sabnzbddownloadstatuscs-complete-file-declaration-order--implicit-values-015}

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

- **لا يوجد محوّل لكل خاصية.** المحوّل `StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }` المسجّل عالمياً (`Json.cs:32`) يتولى ذلك.
- **الاسم غير المعروف يسبب خطأً.** (`EnumUtils.ParseEnum` في Newtonsoft يرمي `JsonSerializationException`)، ولأن `GetQueue`/`GetHistory` يستخدمان `Json.Deserialize` (وليس Try)، فإن استدعاء الطابور أو السجل كله يفشل. **لا ترسل أبداً حالةً خارج هذه القائمة.**
- أرسل الصيغ القياسية لـ SAB تماماً كما هي أعلاه (`"Downloading"`، `"QuickCheck"`، `"Completed"`، `"Failed"`، `"Propagating"`، ...). مطابقة الـ enum في Newtonsoft تتراجع إلى المقارنة غير الحساسة لحالة الأحرف، لكن الحالة الدقيقة هي الشيء الوحيد الذي يستحق الاعتماد عليه.
- الأرقام الصحيحة مقبولة أيضاً (`AllowIntegerValues` القيمة الافتراضية فيه true)، لكن لا تستخدمها.
- قيمة JSON من نوع `null` للحقل `status` يتم تجاهلها بسبب `NullValueHandling.Ignore`، ويبقى العضو على `Grabbing` (0)، أي أن خانة الطابور تتحول بصمت إلى `Queued`، وخانة السجل تتحول بصمت إلى `Downloading`. أرسل دائماً حالة صريحة.

## 3. `get_config`: ما الذي يُقرأ بالضبط، وقواعد التحقق {#3-get_config-exactly-what-is-read-and-the-validation-rules}

### 3.1 النموذج — `SabnzbdCategory.cs` {#31-the-model--sabnzbdcategorycs}

هذا الملف الواحد يحتوي على `SabnzbdConfig` و`SabnzbdConfigMisc` و`SabnzbdCategory` **و** `SabnzbdSorter`.
لا يوجد **ملف `SabnzbdConfig.cs`** في أي من المستودعين (تأكدنا من ذلك عبر قائمة محتويات GitHub API الخاصة بالمسار `src/NzbDrone.Core/Download/Clients/Sabnzbd`).

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

### 3.2 `config.misc.*` — المجموعة الكاملة من المفاتيح المقروءة (`SabnzbdCategory.cs:23-37`) {#32-configmisc--the-complete-set-of-keys-read-sabnzbdcategorycs23-37}

| مفتاح JSON | نوع C# | يُقرأ في | الغرض |
|---|---|---|---|
| `complete_dir` | `string` | `Sabnzbd.cs:218` | الأساس لكل مسارات الفئات. |
| `tv_categories` | `string[]` | `Sabnzbd.cs:265, 493` | |
| `enable_tv_sorting` | `bool` | `Sabnzbd.cs:265, 493` | |
| `movie_categories` | `string[]` | `Sabnzbd.cs:269, 502` | |
| `enable_movie_sorting` | `bool` | `Sabnzbd.cs:269, 502` | |
| `date_categories` | `string[]` **عبر `SabnzbdStringArrayConverter`** | `Sabnzbd.cs:273, 511` | |
| `enable_date_sorting` | `bool` | `Sabnzbd.cs:273, 511` | |
| `pre_check` | `bool` | `Sabnzbd.cs:443` | |
| `history_retention` | `string` | `Sabnzbd.cs:540, 561-573` | قديم، SAB أقل من 4.3. |
| `history_retention_option` | `string` | `Sabnzbd.cs:541, 544` | SAB >= 4.3. |
| `history_retention_number` | `int` | `Sabnzbd.cs:542, 553` | SAB >= 4.3. |

`SabnzbdStringArrayConverter` (`JsonConverters/SabnzbdStringArrayConverter.cs:25-39`) — يُطبَّق فقط على
`date_categories` (`SabnzbdCategory.cs:30`):

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

تتحول **السلسلة النصية** في JSON إلى مصفوفة من عنصر واحد؛ و**القيمة null** تتحول إلى `[null]` (مصفوفة من عنصر واحد تحتوي على null)؛ أما **المصفوفة** فتُفكّ بشكل طبيعي؛ وأي شيء آخر (رقم أو كائن) يرمي استثناءً. تعليق التوثيق عند `:7-9`: "في بعض الخصائص، يُسلسل sab المصفوفة ذات العنصر الواحد كسلسلة نصية عادية."

### 3.3 `config.categories[]` — `SabnzbdCategory` (`SabnzbdCategory.cs:39-48`)

| مفتاح JSON | C# | يُقرأ في |
|---|---|---|
| `priority` | `int Priority` | لا يُقرأ أبداً |
| `pp` | `string PP` | لا يُقرأ أبداً (camelCase لـ `PP` هو `pp`) |
| `name` | `string Name` | `Sabnzbd.cs:251, 255, 458` |
| `script` | `string Script` | لا يُقرأ أبداً |
| `dir` | `string Dir` | `Sabnzbd.cs:238` (`Dir.TrimEnd('*')`), `Sabnzbd.cs:462` (`Dir.EndsWith("*")`) |

`FullPath` (`OsPath`) يُحسب، ولا يُستخرج من JSON.

تجميع المسار — `Sabnzbd.GetCategories` (`Sabnzbd.cs:216-244`):

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

يُرجع `OsPath.operator+` (`src/NzbDrone.Common/Disk/OsPath.cs:420-448`) القيمة `left` عندما يكون `right.IsEmpty`، لذلك فإن `dir: ""` يعطي `FullPath == complete_dir` بالضبط.
قيمة `IsRooted` لمسار من نوع Unix هي `_path.StartsWith("/")` (`OsPath.cs:142-145`). يُستنتج نوع المسار من النص نفسه (`OsPath.cs:43-60`): إذا بدأ بـ `/` فهو Unix، وإذا احتوى على `\` أو حرف محرك أقراص فهو Windows. مسار من نوع Unix يُمرَّر إلى Sonarr مستضاف على Windows يفشل في `CompletedDownloadService.ValidatePath` (`:305-310`).

### 3.4 فخّا الـ NRE الاثنان (وما هو آمن فعلاً) {#34-the-two-nre-landmines-and-what-is-actually-safe}

| شكل البيانات | النتيجة |
|---|---|
| **`"misc"` غائب أو `null`** | يبقى `Misc` فارغاً (لا توجد قيمة افتراضية في الباني، و`NullValueHandling.Ignore` عند القراءة) ← **NullReferenceException عند `Sabnzbd.cs:218`**، ويظهر كرسالة "Test was aborted due to an error: …" وكخطأ مسجّل في فحوصات الصحة (health checks). |
| **فئة (category) لا يوجد فيها `"dir"` أو قيمتها `null`** | يصبح `Dir` فارغاً ← **NullReferenceException عند `Sabnzbd.cs:238`** (`category.Dir.TrimEnd('*')`) ومرة أخرى عند `:462` (`category.Dir.EndsWith("*")`). |
| `"categories": null` أو غائبة | آمن. قائمة الباني الفارغة تبقى كما هي. عندها `GetStatus` لا يجد أي فئة، ويبقى `OutputRootFolders` فارغاً. |
| `"sorters": null` أو غائبة | آمن. قائمة الباني فارغة، و`config.Sorters.Any(...)` في `Sabnzbd.cs:484` تعمل بشكل صحيح. |
| `"servers": null` أو غائبة | آمن، ولا يتم قراءتها أبداً (`List<object>`، `SabnzbdCategory.cs:19`). |
| `"tv_categories"/"movie_categories"/"date_categories": null` | آمن: `ContainsCategory` تُرجع `true` للقيم null أو الفارغة (§3.5)، لكن هذا يهم فقط إذا كان `enable_*_sorting` المقابل مفعّلاً. |

**القاعدة: أرسل دائماً `misc` ككائن (object)، وكل فئة (category) بقيمة `dir` نصية (استخدم `""`).**

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

تم التأكد من ذلك في تجهيزات الاختبار: `enable_tv_sorting=true` + `tv_categories=null` **يفشل**
(`SabnzbdFixture.cs:636-645`)، وكذلك + `tv_categories=[]` **يفشل** أيضًا
(`:647-656`).
`TvCategory=null` + `tv_categories=["Default"]` يفشل (`:680-691`).

### 3.6 `Test()` — الترتيب الدقيق والقواعد (`Sabnzbd.cs:286-292`) {#36-test--the-exact-order-and-rules-sabnzbdcs286-292}

```csharp
protected override void Test(List<ValidationFailure> failures)
{
    failures.AddIfNotNull(TestConnectionAndVersion());
    failures.AddIfNotNull(TestAuthentication());
    failures.AddIfNotNull(TestGlobalConfig());
    failures.AddIfNotNull(TestCategory());
}
```

يُلفّ بواسطة `DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`)، الذي يلتقط أي استثناء يفلت منه ويضيف `"Test was aborted due to an error: " + ex.Message`.

**`TestConnectionAndVersion()` (`Sabnzbd.cs:368-414`)** — 1 × `mode=version`:

1. رقم إصدار غير قابل للتحليل → فشل في الحقل `Version` (`DownloadClientSabnzbdValidationUnknownVersion`).
2. `rawVersion == "develop"` (بدون اعتبار لحالة الأحرف) → **تحذير** على `Version`، و`IsValid` يبقى true (التركيبة في `SabnzbdFixture.cs:566-577`).
3. `version.Major >= 1` → نجاح (`:389-392`).
4. وإلا، `version.Minor >= 7` → نجاح (`:394-397`).
5. وإلا فشل: الإصدار المطلوب هو `"0.7.0"` (`:399-404`).
   جدول التركيبات (`SabnzbdFixture.cs:549-564`): `0.6.9`→false، و`0.7.0`/`0.8.0`/`1.0.0`/`1.0.0RC1`/`1.1.x`→true.
6. أي استثناء → فشل في الحقل `Host` ("unable to connect")، والتفاصيل هي `ex.Message` (`:406-413`).

**`TestAuthentication()` (`Sabnzbd.cs:416-438`)** — 1 × `mode=get_config`. يلتقط الاستثناء، ثم يطابق `ex.Message` باستخدام `ContainsIgnoreCase`:

| النص المطابق | الحقل الذي يفشل |
|---|---|
| `API Key Incorrect` | `APIKey` — `DownloadClientValidationApiKeyIncorrect` |
| `API Key Required` | `APIKey` — `DownloadClientValidationApiKeyRequired` |
| أي شيء آخر | **يُعاد رميه** → رسالة عامة "Test was aborted due to an error: …" |

لأن `CheckForError` يغلّف الجسم بالشكل `"Error response received from SABnzbd: {error}"` (`SabnzbdProxy.cs:244`)، فالمطابقة تنجح عندما يحتوي نص `error` الخاص بك على `API Key Incorrect` أو `API Key Required`، وهي العبارات الأصلية من SAB.

**`TestGlobalConfig()` (`Sabnzbd.cs:440-453`)** — 1 × `mode=get_config`، بالإضافة إلى 1 × `mode=version` فقط إذا كان `pre_check` يساوي true:

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

العتبة: **SAB >= 1.1.0** (`HasVersion(major:1, minor:1, patch:0)`، `Sabnzbd.cs:294-332`). تعيين `pre_check: false` يتجنب الفرع كله، بما في ذلك طلب `mode=version` الإضافي.

**`TestCategory()` (`Sabnzbd.cs:455-521`)** — 1 × `mode=get_config` (وهو الثالث)، بالإضافة إلى أي طلبات يحتاجها `GetCategories`. تُنفَّذ الفحوص بهذا الترتيب، وأول تطابق يفوز:

1. فئة مطابقة (`Name == Settings.TvCategory` / `MovieCategory`) يكون حقل `dir` الخاص بها **ينتهي بـ `*`** → تحذير على `TvCategory`/`MovieCategory` "enable job folders"، مع InfoLink هو `config/categories/` (`:460-469`).
2. لا توجد فئة مطابقة **و** الفئة المضبوطة غير فارغة → تحذير `DownloadClientValidationCategoryMissing`، مع InfoLink هو `config/categories/` (`:471-481`).
3. `config.Sorters.Any(s => s.is_active && ContainsCategory(s.sort_cats, cat))` → تحذير، مع InfoLink هو `config/sorting/` (`:483-491`). تعليق الكود في `:483` يقول: *"New in SABnzbd 4.1, but on older versions this will be empty and not apply"*.
4. `misc.enable_tv_sorting && ContainsCategory(misc.tv_categories, cat)` → تحذير (`:493-500`).
5. `misc.enable_movie_sorting && ContainsCategory(misc.movie_categories, cat)` → تحذير (`:502-509`).
6. `misc.enable_date_sorting && ContainsCategory(misc.date_categories, cat)` → تحذير (`:511-518`).

`SabnzbdSorter` (`SabnzbdCategory.cs:50-66`) — يُقرأ منه: `sort_cats` (`List<string>`، يُهيَّأ فارغاً في الـ ctor)، و`is_active` (`bool`). موجود في النموذج لكنه لا يُقرأ أبداً: `name`، `order`، `min_size`، `multipart_label`، `sort_string`، `sort_type` (`List<int>`).

**ملاحظة عن عدد الطلبات:** كل الدوال الأربع `Test*` تُجري استدعاءاتها الخاصة، ولا شيء يُخزَّن مؤقتاً، لذلك اختبار اتصال واحد يرسل تقريباً **2 × `mode=version` و3 × `mode=get_config`** (واستدعاء version رابع إذا كان `pre_check` يساوي true).

### 3.7 الاحتفاظ بسجل `config.misc` ← `RemovesCompletedDownloads` (`Sabnzbd.cs:538-574`) {#37-configmisc-history-retention--removescompleteddownloads-sabnzbdcs538-574}

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

`true` يُظهر **تحذيرًا** من فحص الصحة
(`HealthCheck/Checks/DownloadClientRemovesCompletedDownloadsCheck.cs:44-53`).
تغطية الـ fixture في `SabnzbdFixture.cs:455-510`: القيم القديمة `"0"`/`""`/`null`/`"15d"` ← false؛
`"-1"`/`"15"`/`"3"`/`"3d"` ← true.

**أنظف إجابة للمحاكي: `history_retention_option: "all"`، و`history_retention_number: 0`، و`history_retention: "0"`.**

### 3.8 `SortingMode` وفحص الصحة الخاص به (`Sabnzbd.cs:263-279`) {#38-sortingmode-and-its-health-check-sabnzbdcs263-279}

تقوم `GetStatus` بتعيين `SortingMode` إلى `"TV"` أو `"Movie"` أو `"Date"` باستخدام نفس الشروط `enable_*_sorting && ContainsCategory(...)`. أي قيمة غير فارغة تُظهر تحذيراً في `HealthCheck/Checks/DownloadClientSortingCheck.cs:45-55`. أبقِ الثلاثة `enable_*_sorting` على القيمة false.

### 3.9 `IsLocalhost` (`Sabnzbd.cs:260`)

```csharp
IsLocalhost = Settings.Host == "127.0.0.1" || Settings.Host == "localhost"
```

ترتيبي، وحساس لحالة الأحرف؛ `::1` و`Localhost` وأي اسم مضيف **لا** تُحتسب. هذا يغيّر الرسالة التي تظهر لك من `RemotePathMappingCheck` (انظر §6.2).

---

## 4. معالجة الأخطاء — `CheckForError` (`SabnzbdProxy.cs:222-246`) {#4-error-handling--checkforerror-sabnzbdproxycs222-246}

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

`SabnzbdJsonError` (`SabnzbdJsonError.cs`، كاملة):

```csharp
public string Status { get; set; }
public string Error  { get; set; }

public bool Failed => !string.IsNullOrWhiteSpace(Status) &&
                      Status.Equals("false", StringComparison.InvariantCultureIgnoreCase);
```

القواعد بالتفصيل:

- `CheckForError` يشتغل على **كل** رد، قبل أي deserialization خاص بالـ mode
  (`SabnzbdProxy.cs:217`).
- `Status` معرّف كـ `string` لكن SAB يبعت قيمة **boolean** في JSON. Newtonsoft يحوّل `false` لـ `"False"`، و`Failed` تطابقها من غير ما تفرق بين الحروف الكبيرة والصغيرة. الاتنين `false` (boolean) و`"false"` (string) شغالين.
- الرد اللي **مفيهوش `status`** على المستوى الأعلى (مثلاً `{"version": …}`، `{"queue": {...}}`، `{"history": {...}}`، `{"config": {...}}`) يخلي `Status` فاضي (null)، فتبقى `Failed` false، يعني مفيش خطأ.
- `status: true` بتتحول لـ `"True"`، فمش بتتعتبر فشل.
- **body مش JSON**: `TryDeserialize` بترجع false (بتلتقط `JsonReaderException` و`JsonSerializationException`، `Json.cs:107-116`) ويشتغل فرع النص العادي. لو الـ body بيبدأ بـ `error` (من غير فرق بين الحروف الكبيرة والصغيرة) يبقى `Status = "false"` ويترمي `DownloadClientException("Error response received from SABnzbd: {body with 'error: ' stripped}")`. أي body مش JSON تاني يبقى `Status = "true"` ويتعامل على إنه **نجاح**، وبعدين الـ deserialization الخاص بالـ mode يفشل بطريقته.
- **body JSON** فيه `status` كـ object (`mode=fullstatus`) برضه بياخد فرع النص العادي، لأن توكن `StartObject` مايقدرش يملا خاصية `string`، فـ `Status` تبقى `"true"`.
- خد بالك من السطر الزايد `result.Error = …` في `:239`: `Error` بتتحط حتى في فرع النجاح. ومالوش أي تأثير (محدش بيقرا `Error` إلا لو `Failed`).

Mapping للاستثناءات في `ProcessRequest` (`SabnzbdProxy.cs:187-220`):

| الاستثناء الملتقط | الاستثناء اللي بيترمي |
|---|---|
| `HttpException` (أي رد مش 2xx، بما فيها 401/403/404/500) | `DownloadClientException("Unable to connect to SABnzbd, {0}")` |
| `HttpRequestException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |
| `WebException` بـ `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, certificate validation failed.")` |
| أي `WebException` تاني | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |

**رسايل فشل المصادقة اللي بتتطابق بالظبط** (`Sabnzbd.cs:424, 429`، نصوص حرفية بالظبط، وبتتطابق بـ `ContainsIgnoreCase` مع رسالة الاستثناء):

- `"API Key Incorrect"`
- `"API Key Required"`

مفيش حاجة تانية بتتصنّف. ابعتهم زي ما هما كقيمة `error` لرد **HTTP 200**.

**ليه ممنوع أبداً نرجع رد غير 200:** `HttpClient.Execute` بيرمي الاستثناء قبل ما `CheckForError` يشتغل أصلاً (`HttpClient.cs:106-121`)، ورسالة `HttpException` الناتجة فيها الحالة والميثود والـ URL بس، ومافيهاش الـ body (`HttpException.cs:18`)، يعني المطابقة مع `"API Key Incorrect"` / `"API Key Required"` مش هتشتغل أبداً. المستخدم هيشوف "Unable to connect to SABnzbd" أو "Test was aborted due to an error" بدل رسالة يقدر يتصرف على أساسها، وكل health check هيعتبر الكلاينت مش متاح.

---

## 5. تسلسل ما بعد الاستيراد {#5-the-post-import-sequence}

### 5.1 من يستدعي `RemoveItem`، وبأي شكل {#51-who-calls-removeitem-and-with-what}

`DownloadEventHub` (`src/NzbDrone.Core/Download/DownloadEventHub.cs`، متطابق في المستودعين باستثناء BOM):

- `Handle(DownloadCompletedEvent)` (`:48-69`): يستدعي `MarkItemAsImported` (ترمي SAB الاستثناء `NotSupportedException` — `DownloadClientBase.cs:189-192` — ويُسجَّل على مستوى debug ثم يُتجاهل)، ثم يخرج مبكرًا إذا كان العنصر `Removed` أو `!CanBeRemoved` أو ما زال `Downloading`، ثم يخرج مبكرًا ما لم يكن `definition.RemoveCompletedDownloads` مفعّلًا.
- `Handle(DownloadFailedEvent)` (`:26-46`): مشروط بـ `definition.RemoveFailedDownloads`.
- `Handle(DownloadCanBeRemovedEvent)` (`:71-85`): مشروط بـ `definition.RemoveCompletedDownloads`.
- الثلاثة كلها تمرر الطلب إلى `RemoveFromDownloadClient` (`:87-103`):

```csharp
_logger.Debug("[{0}] Removing download from {1} history", …);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);   // :92 -- deleteData is ALWAYS true
trackedDownload.DownloadItem.Removed = true;
```

القيم الافتراضية في `DownloadClientDefinition` (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17-18`):

```csharp
public bool RemoveCompletedDownloads { get; set; } = true;
public bool RemoveFailedDownloads    { get; set; } = true;
```

مسار الـ API اليدوي `DELETE /api/v3/queue/{id}?removeFromClient=true` يمرر `true` هو الآخر (Sonarr `src/Sonarr.Api.V3/Queue/QueueController.cs:342`). **لا يوجد أي مستدعٍ في أي مكان يمرر `deleteData: false`.**

### 5.2 `Sabnzbd.RemoveItem` (`Sabnzbd.cs:197-214`) — التسلسل الدقيق {#52-sabnzbdremoveitem-sabnzbdcs197-214--the-exact-sequence}

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

إذن تسلسل الطلبات بعد الاستيراد مقابل المحاكي هو:

1. `GET /api?mode=queue&start=0&limit=0&category=tv&apikey=…&output=json` (لتحديد هل العنصر في قائمة الانتظار أم في السجل)
2. **حذف محلي من نظام الملفات لمجلد الإخراج** (§5.3) — قبل أي طلب HTTP آخر
3. `GET /api?mode=history&name=delete&del_files=1&value={nzo_id}&archive=1&apikey=…&output=json`

بالنسبة إلى عنصر **فاشل**: لا يحدث حذف محلي (الحالة هي `Failed`، وليست `Completed`)، و**`archive=0`** —
المنطق المعكوس في `SabnzbdProxy.cs:80` (`archive = deletePermanently ? 0 : 1`، حيث `deletePermanently == (status is Failed)`).

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

- **نعم، يحذف مجلد الإخراج بشكل متكرر.** `DeleteFolder(path, recursive: true)` عند `:129`.
- `OutputPath` هنا هو قيمة `storage` الخاصة بعنصر السجل بعد إعادة ربط المسار البعيد وصعود مجلد المهمة (§1.6.2). بالنسبة إلى دليل magic مسطّح، يعني هذا `rm -rf /mnt/zurg/__magic__/__all__/<Title>`.
- الإعداد الذي يتحكم في ذلك هو مفتاح **Remove Completed Downloads** في عميل التنزيل
  (`DownloadClientDefinition.RemoveCompletedDownloads`، والقيمة الافتراضية **true**)، *وليس* إعدادًا في SAB
  ولا `del_files`. لا يوجد مفتاح منفصل باسم "delete data" في الواجهة.
- تُتجاهل الأخطاء مع تحذير. يسجّل التركيب للقراءة فقط ضجيجًا في السجل، لكنه لا يوقف الاستيراد.
- تغطية تجهيزات الاختبار (fixture) في `SabnzbdFixture.cs:693-803`: يُحذف المجلد بشكل متكرر، ويُحذف الملف، ولا يحدث شيء عندما لا يوجد المسار، ولا يحدث أي شيء على الإطلاق (ولا حتى استعلام `FolderExists`) عندما يكون `deleteData` بقيمة false.

### 5.4 وضع النقل: هل يُنقل الملف أم يُنسخ؟ {#54-transfer-mode-is-the-file-moved-or-copied}

`Sabnzbd` يضبط `CanMoveFiles = true` على **كل** عنصر، سواء في القائمة (`Sabnzbd.cs:76`) أو في السجل (`Sabnzbd.cs:135`). مسار الاستيراد التلقائي هو `CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, …)` (Sonarr `CompletedDownloadService.cs:148-151`)، ثم:

Sonarr `src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152`
(Radarr `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`، والمنطق نفسه):

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

`CanMoveFiles: true` ⇒ `copyOnly == false` ⇒ **`TransferMode.Move`** (`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`). أما استيراد `copyOnly` فسيستخدم بدلاً من ذلك `TransferMode.HardLinkOrCopy` إذا كان خيار "Use Hardlinks instead of Copy" مفعّلاً، وإلا فسيستخدم `TransferMode.Copy` (`:94-108`).

`TransferMode` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`) وهي تعداد (enum) بسمة `[Flags]`: `None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy = Copy|HardLink`.

### 5.5 هل ينتقل النقل الفاشل إلى نسخ؟ — **لا. النقل الفاشل يعني فشل الاستيراد.** {#55-does-a-failed-move-fall-back-to-a-copy--no-a-failed-move-is-a-failed-import}

`src/NzbDrone.Common/Disk/DiskTransferService.cs` (متطابق بايت بايت بين المستودعين، وقد تم التحقق من ذلك).
`TransferFile`، `:256-392`؛ فرع `TransferMode.Move` في `:360-389`:

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

- نسخة الاحتياط **الوحيدة** هي الحالة الخاصة `isCifs && !isSameMount` في `:378-385`، وتُحدَّد بناءً على `targetMount.DriveFormat == "cifs"` (`:342`). يُختار هذا **مسبقاً** من تنسيق القرص، وليس كرد فعل على فشل.
- تلتقط `TryMoveFileVerified` (`:487-503`) الاستثناء، وتستدعي `RollbackPartialMove` (إلا إذا كان الاستثناء من نوع `FileAlreadyExistsException`)، ثم **تعيد رميه**:

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

- تقارن `VerifyFile` (`:505-524`) حجم الوجهة بحجم المصدر، وتنتظر 3 ثوانٍ (`WaitForIO`، `:467-471`)، ثم تتحقق مرة أخرى، ثم ترمي
  `IOException("File move incomplete, data loss may have occurred. [{target}] was {n} bytes long instead of the expected {m}.")`.
- ينتقل هذا `IOException` إلى الأعلى عبر `EpisodeFileMovingService.TransferFile` (`:151`) وصولاً إلى كتلة `catch (Exception e)` العامة في `ImportApprovedEpisodes.cs:218-222` (وفي Radarr `:197-201`)، فينتج `ImportResult(importDecision, "Failed to import episode")` أو `"Failed to import movie"`.
  **لا تُجرى أي محاولة نسخ.**
- الاستثناءات `IOException` الأخرى التي تُرمى في الفحص المسبق داخل الدالة نفسها: تطابق المصدر والوجهة (`:270`، `:277`)، و"Destination cannot be a child of the source" (`:312-315`).

تحذير، وهو حقيقة تخص وقت تشغيل .NET وليس كود Sonarr: تستدعي `DiskProviderBase.MoveFileInternal` (`src/NzbDrone.Common/Disk/DiskProviderBase.cs:293-301`) الدالة `File.Move` مباشرة، وفي أنظمة Unix يلجأ .NET إلى النسخ ثم الحذف عندما يعيد `rename()` القيمة `EXDEV`. لذلك تنجح عملية النقل بين أنظمة الملفات عادةً، لكن كاستراتيجية احتياطية في وقت التشغيل، وليست احتياطية من Sonarr. ما **لن** يُتسامح معه هو وجهة يختلف حجمها عن حجم المصدر، أو أي استثناء يُطلقه `File.Move` نفسه (EACCES، EPERM، EROFS على المصدر، …).

تُستخدم `TransferFolder` (`:44-137`) في مسارات كود أخرى. لاحظ `:124-131`: بعد عملية نقل مجلد، ترفض الدالة حذف المصدر إذا بقي أكثر من 100 MB من الملفات (`IOException("Large files still exist in {sourcePath} after folder move, not deleting source folder")`).

---

## 6. فحصا الصحة {#6-the-two-health-checks}

### 6.1 `DownloadClientRootFolderCheck` — **المكان الوحيد الذي تختلف فيه Sonarr وRadarr فعلاً** {#61-downloadclientrootfoldercheck--the-one-place-sonarr-and-radarr-genuinely-differ}

Sonarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = status.OutputRootFolders.Where(folder => rootFolders.Any(r => r.Path.PathEquals(folder.FullPath)));
```

Radarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = rootFolders.Where(r => status.OutputRootFolders.Any(folder => r.Path.PathEquals(folder.FullPath) || r.Path.IsParentPath(folder.FullPath)));
```

`IsParentPath` (`src/NzbDrone.Common/Extensions/PathExtensions.cs:123-140`) يسير **للأعلى** بدءاً من المسار الفرعي:

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

إذن يكون `r.Path.IsParentPath(folder.FullPath)` صحيحاً عندما يكون **مجلد الجذر سلفاً لمجلد مخرجات التنزيل**، أي أن مجلد المخرجات يقع *داخل* مجلد جذر. وهو اختبار سلف صارم (يبدأ من `child.Directory`)، أما المساواة فيتم التعامل معها بشكل منفصل عبر `PathEquals`.

**الإجابة المباشرة عن سؤال الشرط:**

| العلاقة (مجلد المخرجات O مقابل مجلد الجذر R) | Sonarr | Radarr |
|---|---|---|
| O == R | **تحذير** | **تحذير** |
| O داخل R (R هو سلف O) | لا تحذير | **تحذير** |
| O هو الأب لـ R (O هو سلف R) | لا تحذير | **لا تحذير** |
| غير مرتبطين | لا تحذير | لا تحذير |

مع `complete_dir = /mnt/zurg/__magic__/__all__` و `dir: ""` (أي أن `OutputRootFolders == ["/mnt/zurg/__magic__/__all__"]`):

- يحذّر Sonarr فقط إذا كان أحد مجلدات الجذر هو `/mnt/zurg/__magic__/__all__` تماماً.
- يحذّر Radarr إذا كان مجلد الجذر هو `/mnt/zurg/__magic__/__all__` أو `/mnt/zurg/__magic__` أو `/mnt/zurg` أو `/mnt`.
- لا يحذّر أيٌّ منهما إذا كان مجلد الجذر هو `/mnt/zurg/__magic__/tv` — فالمرآة ومجلدات الجذر أشقاء، أي أن الزوج غير مرتبط ولا تنطبق أي من القاعدتين. ومجلد جذر *داخل* مجلد المخرجات (`/mnt/zurg/__magic__/__all__/anything`) كان سيبقى صامتاً هنا أيضاً، لكن مساحة الأسماء ترفض تخزين أي شيء على هذا العمق، لذا فهذا ترتيب لا يمكن أن يوجد.

تقوم `PathEquals` (`PathExtensions.cs:55-73`) بتطبيع Unicode، وتستخدم `DiskProviderBase.PathStringComparison`
(`OrdinalIgnoreCase` على Windows، و`Ordinal` على غيره — `src/NzbDrone.Common/Disk/DiskProviderBase.cs:17-23`)،
ثم تعيد المحاولة باستخدام `CleanFilePath()` (التي لا تهتم بالشرطة المائلة الأخيرة).

يُعاد تشغيل الإصدارين عند `ProviderUpdatedEvent` / `ProviderDeletedEvent` / `ModelEvent<RootFolder>` / `ModelEvent<RemotePathMapping>`، ويضيف Radarr `[CheckOn(typeof(ProviderAddedEvent<IDownloadClient>))]` في السطر `:17`. تكون النتيجة `HealthCheckResult.Warning` مع المرساة `#downloads-in-root-folder`. تُدرج الرسالة `folder.FullPath` في Sonarr و`folder.Path` في Radarr (السطر `:60` في الاثنين). يتجاهل الإصدارين بصمت `DownloadClientException` و`HttpRequestException` (مع سجل debug) ويسجّلان أي استثناء آخر كخطأ.

### 6.2 `RemotePathMappingCheck` — مسار العميل المحلي (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs`) {#62-remotepathmappingcheck--the-local-client-path-srcnzbdronecorehealthcheckchecksremotepathmappingcheckcs}

القفز المختصر عند `:51-54`: إذا كان `EnableCompletedDownloadHandling` مُعطّلاً، فإن الفحص لا يفعل شيئاً.

لكل `folder` في `client.GetStatus().OutputRootFolders`:

1. **`!folder.IsValid`** (`:68`): `OsPath.IsValid` = `_path.IsPathValid(PathValidationType.CurrentOs)`
   (`OsPath.cs:228`). على أنظمة غير Windows يتلخص هذا في `path.StartsWith("/")` مع فحص لـ `Path.GetInvalidPathChars()` (`PathExtensions.cs:143-182`، و `:403-411`). الأخطاء، بالترتيب:
   - `!status.IsLocalhost` ← `RemotePathMappingWrongOSPathHealthCheckMessage` (مفتاح Radarr: `RemotePathMappingCheckWrongOSPath`)، والرابط `#bad-remote-path-mapping`
   - `_osInfo.IsDocker` ← …`BadDockerPath`، والرابط `#docker-bad-remote-path-mapping`
   - غير ذلك ← …`LocalWrongOSPath`، والرابط `#bad-download-client-settings`
2. **`!_diskProvider.FolderExists(folder.FullPath)`** (`:115`):
   - `_osInfo.IsDocker` ← …`DockerFolderMissing`، والرابط `#docker-bad-remote-path-mapping`
   - `!status.IsLocalhost` ← …`LocalFolderMissing`، والرابط `#bad-remote-path-mapping`
   - غير ذلك ← …`GenericPermissions`، والرابط `#permissions-error`

**بالنسبة لعميل محلي (`IsLocalhost` صحيح، وليس Docker) يتلخص هذا في شرطين فقط:**
يجب أن يكون مجلد جذر الإخراج المُبلَّغ عنه مساراً مطلقاً *حسب نظام التشغيل الذي تعمل عليه Sonarr/Radarr*، ويجب أن **يكون موجوداً كمجلد على جهاز Sonarr/Radarr**. يجب أن يكون `/mnt/zurg/__magic__/__all__` مرئياً لعملية *arr، وليس للمحاكي فقط. **لا يوجد هنا أي فحص لقابلية الكتابة.**

يعمل الإصدار المعتمد على الأحداث (`:178-368`) عند `EpisodeImportFailedEvent` (في Radarr: `MovieImportFailedEvent`)، والأهم أنه يستدعي `client.GetItems()` مرة أخرى ليبحث عن `OutputPath` الخاص بالتحميل الفاشل (`:232`).

لا يشترط أي فحص صحي أن يكون مجلد الإخراج *قابلاً للكتابة*. تُستخدم `FolderWritable` (`DiskProviderBase.cs:126-143` في Sonarr، و `:127-144` في Radarr)، والتي تكتب ملف `sonarr_write_test.txt` / `radarr_write_test.txt` ثم تحذفه، من قِبل `RootFolderService.Add` (Sonarr `src/NzbDrone.Core/RootFolders/RootFolderService.cs:117-120`) ومن قِبل `DownloadClientBase.TestFolder` (`:167-187`)، و**لا يستدعي عميل SAB أبداً `TestFolder`**.

---

## 7. Sonarr مقابل Radarr — الفرق الكامل {#7-sonarr-vs-radarr--the-complete-diff}

**متطابقة بايت لبايت ما عدا BOM بترميز UTF-8 في نسخ Sonarr (لذلك تتطابق أرقام الأسطر تماماً):**

`SabnzbdCategory.cs` (بدون BOM في الجهتين، متطابق تماماً)، `SabnzbdDownloadStatus.cs`،
`SabnzbdPriority.cs`، `SabnzbdFullStatus.cs`، `SabnzbdJsonError.cs`، `SabnzbdQueue.cs`،
`SabnzbdQueueItem.cs`، `SabnzbdHistory.cs`، `SabnzbdHistoryItem.cs`،
`JsonConverters/*.cs` (الثلاثة كلها)، `Responses/*.cs` (الستة كلها)،
`src/NzbDrone.Common/Disk/DiskTransferService.cs`، `src/NzbDrone.Core/Download/DownloadEventHub.cs`.

**تختلف فقط بسبب إعادة التسمية `TvCategory` ← `MovieCategory` و `RemoteEpisode` ← `RemoteMovie` (دون تغيير في عدد الأسطر، والأرقام نفسها):**

- `Sabnzbd.cs` — `:40-52` (`AddFromNzbFile`؛ اختبار الحداثة في Radarr هو `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` مقابل `remoteEpisode.IsRecentEpisode()` في Sonarr)، `:190`، `:251`، `:265/269/273`، `:458`، وكل أسماء حقول `NzbDroneValidationFailure` في `TestCategory` (`"TvCategory"` ← `"MovieCategory"`).
- `SabnzbdProxy.cs` — `:50`، `:122-124`، `:138-140`.
- `SabnzbdSettings.cs` — القيم الافتراضية `TvCategory = "tv"` مقابل `MovieCategory = "movies"`؛ و `RecentTvPriority`/`OlderTvPriority` مقابل `RecentMoviePriority`/`OlderMoviePriority` (القيمتان الافتراضيتان هما `(int)SabnzbdPriority.Default`). المدقق متطابق في الباقي: `Host` صالح، و `Port` بين 1 و 65535، و `ApiKey` مطلوب عندما يكون اسم المستخدم فارغاً، و `Username`/`Password` مطلوبان عندما يكون ApiKey فارغاً، والتحقق من الفئة `NotEmpty` **كتحذير**.
- `UsenetClientBase.cs` — تضيف Radarr أيضاً `request.AllowAutoRedirect = true` (`:51`) وتعامل رمز HTTP `410 Gone` مثل `404` (`:63`) عند جلب ملف NZB من المفهرس. **هذا يخص المفهرس، وليس SAB.**
- `DownloadClientBase.cs` — الفرق الوحيد هو كلمتا "Sonarr"/"Radarr" الحرفيتان في نص تفاصيل `TestFolder`.
- `RemotePathMappingCheck.cs` — أسماء مفاتيح الترجمة (`RemotePathMapping*HealthCheckMessage` مقابل `RemotePathMappingCheck*`)، و `EpisodeImportFailedEvent` مقابل `MovieImportFailedEvent`، بالإضافة إلى `[CheckOn(ProviderAddedEvent<IDownloadClient>)]` الإضافي في Radarr. **المسندات (Predicates) متطابقة.**
- `DiskProviderBase.cs` — ملف الاختبار لـ `FolderWritable` هو `sonarr_write_test.txt` مقابل `radarr_write_test.txt` (Sonarr `:132`، Radarr `:133`).

**فرق سلوكي حقيقي — واحد فقط:**

- **`DownloadClientRootFolderCheck.cs:51`.** يحذّر Sonarr فقط عند `PathEquals`، بينما يحذّر Radarr أيضاً عندما يكون مجلد الجذر أحد الأسلاف لمجلد الإخراج. الجدول الكامل في §6.1.

كل شيء آخر — الأوضاع، والمعاملات، وأشكال JSON، والتعدادات، والمحوّلات، و`CheckForError`، و`RemoveItem`، و`DeleteItemData`، ووضع النقل، و`DiskTransferService` — متطابق. **محاكٍ واحد يخدم الاثنين.**

الإعدادات الافتراضية متطابقة في الاثنين: `DownloadClientHistoryLimit = 60`،
`RemoveCompletedDownloads = true`، `RemoveFailedDownloads = true`.

---

## 8. نماذج بيانات مختصرة لكن كاملة {#8-minimal-but-complete-example-payloads}

المعطيات: `complete_dir = /mnt/zurg/__magic__/__all__`؛ والفئات `*` و`tv` و`movies`، وكلها بـ `dir: ""`.
كل استجابة هي **HTTP 200** مع `Content-Type: application/json`.

النتيجة في `OutputRootFolders`: `dir: ""` ⇒ `FullPath == complete_dir` ⇒ `/mnt/zurg/__magic__/__all__`
لـ Sonarr (الفئة `tv`) ولـ Radarr (الفئة `movies`).

### 8.1 `mode=version`

```json
{
  "version": "4.3.3"
}
```

يجب أن يكون بالشكل `major.minor.(patch|x)`. الإصدار `4` ≥ 1 يحقق `TestConnectionAndVersion` (`Sabnzbd.cs:389-392`)؛
و≥ 2.0 يعني أيضاً أن `GetCategories` سيستخدم `fullstatus` بدلاً من `queue.my_home` لو كان `complete_dir` نسبياً
(وهو ليس كذلك).

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

سبب كل قيمة:

- `misc` موجود ككائن — **مطلوب**، وإلا ستحدث NRE (§3.4).
- كل فئة لها `dir` من نوع **string** — **مطلوب**، وإلا ستحدث NRE في `Sabnzbd.cs:238` و `:462`.
- `dir` **لا** ينتهي بـ `*` — وإلا ستظهر تحذير "enable job folders" (`Sabnzbd.cs:462-469`).
- جميع القيم الثلاث `enable_*_sorting: false` — تُلغي تحذيرات `TestCategory` (`Sabnzbd.cs:493-518`)
  و `DownloadClientSortingCheck` معاً. انتبه إلى أن `tv_categories: []` مع `enable_tv_sorting: true` سيؤدي إلى **فشل**، لأن `ContainsCategory` تُرجع true للقائمة الفارغة (`Sabnzbd.cs:525-528`، التجهيز `SabnzbdFixture.cs:647-656`).
- `sorters: []` — يعطي `config.Sorters.Any(s => s.is_active && …)` القيمة false (`Sabnzbd.cs:484`).
- `pre_check: false` — يتخطى جولة `HasVersion(1,1)` في `TestGlobalConfig` (`Sabnzbd.cs:443`).
- `history_retention_option: "all"` → `RemovesCompletedDownloads == false` (`Sabnzbd.cs:546-547`) → لا يظهر تحذير فحص الصحة.
- `complete_dir` مطلق → `IsRooted` تكون true → لا يتم الرجوع أبداً إلى `mode=fullstatus` / `queue.my_home` (`Sabnzbd.cs:220`).

(تم رفض ترجمة سابقة: الأكواد البرمجية داخل النص مختلفة. حافظ على البنية تماماً.)

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
لا يُقرأ سوى `completedir` (`SabnzbdFullStatus.cs:9-10`). مفتاح الغلاف **يجب** أن يكون `status`
(`Responses/SabnzbdFullStatusResponse.cs:5`).

### 8.4 استجابة `mode=addfile` {#84-modeaddfile-response}

```json
{
  "status": true,
  "nzo_ids": ["SABnzbd_nzo_abc12345"]
}
```

يجب أن يكون `nzo_ids` **مصفوفة غير فارغة من النصوص** (`Sabnzbd.cs:47-52`). يتم تحليل `status` (`Responses/SabnzbdAddResponse.cs:13`) لكنه لا يُقرأ أبدًا، لذا اتركه `true` حتى يرى `CheckForError` القيمة `"True"`.

### 8.5 `mode=queue&start=0&limit=0&category=tv` — خانة واحدة قيد التنزيل {#85-modequeuestart0limit0categorytv--one-downloading-slot}

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

متطلبات صارمة:

- المفتاح الأعلى مستوى `queue` (`SabnzbdProxy.cs:129`, `SelectToken("queue")`).
- `slots[].status` يجب أن يكون واحداً من الأسماء الـ 16 في `SabnzbdDownloadStatus`، بنفس حالة الأحرف بالضبط.
- `slots[].mb` و `mbleft` بالـ **ميغابايت**، وبأرقام عشرية بثقافة invariant. النصوص والأرقام الاثنان مقبولان (Newtonsoft يحوّلهما تلقائياً)، لكن SAB الحقيقي يرسل نصوصاً.
- `slots[].timeleft` يجب أن يكون بالضبط `h:m:s` أو `d:h:m:s`، ولا يكون أبداً `""`.
- `slots[].priority` يجب أن يكون `"Normal"` أو `"High"` أو `"Low"` أو `"Force"` أو `"Paused"` أو `"Default"` (حساس لحالة الأحرف)، أو ما يعادلها بالأرقام. **لا يكون أبداً `null`** (NRE).
- `slots[].cat` (وليس `category`) يجب أن يطابق الفئة المضبوطة في العميل، وإلا سيُستبعد العنصر عند `Sabnzbd.cs:190`.
- يجب أن تكون `queue.paused` بقيمة `false` إلا إذا كنت تقصد الإيقاف فعلاً. القيمة `true` تضع كل خانة ليست `Force` كحالة Paused مع ETA فارغ (`Sabnzbd.cs:78-84`).

النتيجة في `DownloadClientItem`: `TotalSize = 1024 * 1024 * 1024`، و`RemainingSize = 512 * 1024 * 1024`، و`RemainingTime = 00:08:32`، و`Status = Downloading`، و`CanBeRemoved = CanMoveFiles = true`.

### 8.6 `mode=history&start=0&limit=60&category=tv` — خانة مكتملة وأخرى فاشلة {#86-modehistorystart0limit60categorytv--one-completed-and-one-failed-slot}

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

المتطلبات الصارمة:

- مفتاح `history` على المستوى الأعلى (`SabnzbdProxy.cs:145`).
- `slots[].bytes` هو **بايت** (رقم JSON ← `long`). لا ترسل MB هنا. قائمة الانتظار تستخدم MB، أما السجل فيستخدم البايت (`Sabnzbd.cs:72-73` مقابل `:128`).
- `slots[].category` (وليس `cat`).
- `slots[].storage` هو مجلد المهمة نفسه؛ يصبح `OutputPath`، وبالنسبة لعنصر Completed فهو المجلد الذي يحذفه `DeleteItemData` بشكل متكرر (§5.3). يجب أن يكون مسارًا مطلقًا صالحًا لنظام التشغيل الذي يعمل عليه Sonarr/Radarr، ويجب أن يكون موجودًا هناك (`RemotePathMappingCheck`, §6.2).
- `slots[].status` يجب أن تطابق حالة الأحرف تمامًا؛ تُحذف العناصر `Deleted` بالكامل (`Sabnzbd.cs:116-119`).
- إذا كانت قيمة `fail_message` بالضبط `"Unpacking failed, write error or disk is full?"` فإن العنصر الذي حالته Failed يتحول إلى `Warning` بدلًا من `Failed` (`Sabnzbd.cs:140-144`). استخدم رسالة أخرى للفشل الحقيقي.
- Radarr: يجب أن تكون `category` هي `movies` (أو أي قيمة مضبوطة في الإعدادات)، ويجب أن يُفسَّر `name` كفيلم.

### 8.7 استجابة الخطأ (أي وضع) {#87-error-response-any-mode}

```json
{
  "status": false,
  "error": "API Key Incorrect"
}
```

**HTTP 200.** قد تكون قيمة `status` القيمة المنطقية `false` أو النص `"false"`، وكلاهما يطابق `SabnzbdJsonError.Failed` (`SabnzbdJsonError.cs:10-11`). يرفع العميل الاستثناء `DownloadClientException("Error response received from SABnzbd: API Key Incorrect")` (`SabnzbdProxy.cs:244`)، و`TestAuthentication` يتعرف عليه (`Sabnzbd.cs:424`). استخدم `"API Key Required"` إذا لم يتم تقديم أي مفتاح (`Sabnzbd.cs:429`). أما أي نص آخر في `error` فيُعرض كما هو دون تصنيف.

---

## 9. قائمة التحقق للتنفيذ (12 نقطة) {#9-implementation-checklist-12-points}

1. مسار واحد: `GET|POST {UrlBase}/api`، وجّه الطلب حسب `mode`. **دائماً HTTP 200، ودائماً JSON.**
2. نفّذ `version` و`get_config` و`queue` (قراءة + `name=delete`) و`history` (قراءة + `name=delete`)،
   و`addfile` و`fullstatus`. واختيارياً `retry` (كود ميت حالياً). `get_cats` لا يُستدعى أبداً.
3. اقبل المصادقة إما بـ `apikey=` **أو** بـ `ma_username=`+`ma_password=`. ارفض بـ 200 +
   `{"status":false,"error":"API Key Incorrect"}` / `"API Key Required"` — لا 401 ولا 403 أبداً.
4. احترم `category=` في `queue`/`history` (العملاء يفلترون أيضاً من جهتهم بمطابقة نصية تامة،
   `Sabnzbd.cs:190`).
5. أحجام `queue` بوحدة **MB** (`mb`, `mbleft`)؛ أحجام `history` بوحدة **BYTES** (`bytes`). لا تخلطهما أبداً. Queue تستخدم `cat`، وhistory تستخدم `category`.
6. يكون `timeleft` دائماً `h:m:s` أو `d:h:m:s`، ولا يكون فارغاً أبداً، ولا غائباً كنص فارغ. لا يُحلَّل أي حقل تاريخ في أي مكان، لذا حقول epoch حرة الشكل.
7. يجب أن تأتي قيم `status` من قائمة `SabnzbdDownloadStatus` المكوّنة من 16 عنصراً، بحالة أحرف مطابقة تماماً (الاسم المجهول يرمي استثناءً ويُسقط استدعاء queue/history كله). يجب أن يكون `priority` اسماً من `SabnzbdPriority` (بحالة أحرف مطابقة) أو قيمته الصحيحة؛ **لا يكون أبداً `null`** (NRE في المحوّل).
8. يجب أن يكون `config.misc` كائناً (object)؛ ويجب أن تحمل كل فئة **`dir` نصياً غير null** لا ينتهي بـ `*`. يجوز أن تكون `categories`/`sorters`/`servers` فارغة (null) أو غائبة، أما `misc` و`dir` فلا يجوز.
9. أبقِ `enable_tv_sorting` و`enable_movie_sorting` و`enable_date_sorting` و`pre_check` كلها على `false`، وأبقِ `history_retention_option: "all"`، حتى يبقى اختبار الاتصال وكل فحوص الصحة نظيفة.
10. `storage` في خانة history بحالة Completed = مجلد المهمة. توقّع أن يقوم *arr بتنفيذ `rm -rf` عليه بعد الاستيراد الناجح (الإعدادات الافتراضية)، وتوقّع أن يتم **نقل** ملف الوسائط خارجه أولاً.
    إذا كان مجلد magic للقراءة فقط، يفشل الحذف بصمت (سجل تحذير فقط)، لكن *النقل*
    للملف المستورد يجب أن ينجح وإلا يفشل الاستيراد تماماً (§5.5).
11. لا تضع أي مجلد جذر لـ *arr في `/mnt/zurg/__magic__/__all__` أو أعلى منه إذا أردت أن يبقى `DownloadClientRootFolderCheck` في Radarr هادئاً (Sonarr يهتم فقط بالتطابق التام). ضعها بجانب المرآة بدلاً من ذلك — `/mnt/zurg/__magic__/tv`، `/mnt/zurg/__magic__/movies` — وهذه لا علاقة لها بمجلد الإخراج، لا أعلى منه ولا أسفل منه.
12. يجب أن يوجد `/mnt/zurg/__magic__/__all__` كمجلد **على جهاز Sonarr/Radarr**، وليس فقط حيث يعمل المحاكي، وإلا يرمي `RemotePathMappingCheck` خطأ. لا يلزم أن يكون قابلاً للكتابة.

(رُفضت ترجمة سابقة: الـ code spans لم تتطابق. حافظ على البنية تماماً كما هي.)

## ضبط نافذة اكتمال أكبر {#configuring-a-larger-completion-window}

كلا العميلين يستخدمان القيمة الافتراضية `DownloadClientHistoryLimit` وهي 60. يعكس zurg هذه النافذة نفسها عندما يحتفظ بالمهام المكتملة الزائدة في `queue`. أما زيادة حد العميل وحده فستجعل بعض المهام تظهر في الطابور والسجل معاً، وعندها تكون الأولوية للطابور.

للمكتبات الكبيرة المتراكمة، اضبط `sabnzbd.history_limit` في zurg و`DownloadClientHistoryLimit` في العملاء على القيمة نفسها، مثلاً 500. يتيح ذلك عرض عدد أكبر من المهام المكتملة والفاشلة في كل استطلاع. وإذا كانت لديك عدة عملاء بقيم مختلفة، فاترك zurg على أصغر حد بين العملاء. هذا الإعداد المتقدم للعميل غير متاح في مورد API الخاص بإعدادات عميل التحميل في Sonarr v4، لذلك خذ نسخة احتياطية وأوقف العميل قبل تعديل إعداداته المحفوظة.

```yaml
sabnzbd:
  enabled: true
  history_limit: 500
```

تبقى القيمة الافتراضية 60، والقيم صفر أو السالبة تستخدم هذه القيمة الافتراضية. كما أن طلب السجل التشخيصي بحد مختلف لا يغيّر النافذة المضبوطة أبداً. التحذيرات التي لا يستطيع العميل حلّها ما زالت تحتاج إلى مراجعة، ونافذة أكبر تتيح للمهام الأخرى الوصول إلى الاستيراد، حتى لو كانت هذه التحذيرات تشغل خانات في السجل.

يفحص التحقق من توفر الملفات قبل الإكمال أول ستة عشر مقالاً من كل ملف محتوى، إضافة إلى آخر مقال فيه. وهذا يلتقط المقال المفقود في ترويسة الوسائط الذي كان فحص المقال الأول القديم يفوته. ويُنزَّل أول مقال من كل ملف محتوى، للتحقق من هوية المقال وأن محتواه ما زال متاحاً من الخادم، لأن مزوداً قد يجيب على أمر STAT لمقال سحب محتواه. ويُضاف إليه مقالات مختارة عشوائياً حتى ستة عشر محتوى للإصدار الذي يحتوي على ملفات أقل من ذلك، ولا يتجاوز الإجمالي أربعة وستين محتوى. أما المحتوى الذي تحتفظ به ذاكرة المقالات مسبقاً فلا يُعاد جلبه. ويغطي أمر STAT بقية العينة. هذا الفحص لا يتحقق من كل مقال، ولا يثبت أن الوسائط قابلة لفك الترميز. تُجمَّع طلبات STAT لكل ملف، فتستهلك العينة حجز مجموعة اتصالات واحداً بدلاً من سبعة عشر، دون رفع سقف الاتصالات المسموح به للحساب. وإذا فشلت الدفعة، يُعاد الفحص مقالاً مقالاً. أما أعطال الخادم فتُبقي المهمة في الطابور لإعادة المحاولة، بينما المقالات المفقودة المؤكدة تنتج تنزيلاً فاشلاً قبل إرسال أول إشعار إكمال.
