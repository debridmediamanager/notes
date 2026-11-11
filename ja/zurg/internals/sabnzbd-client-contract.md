# SABnzbd API 規約（Sonarr と Radarr が使う形、develop） {#sabnzbd-api-contract-as-consumed-by-sonarr-and-radarr-develop}

`internal/sabnzbd` がこの形で応答する理由を残しておくための記録です。このパッケージは、クライアントがそのフィールドをどう扱うかを説明しているここの段落を確認せずに変更しないでください。構造体タグを間違えてもエラーにはならず、クライアントはゼロを読んでしまいます。enum の値を間違えると、デシリアライザの中で例外が発生し、ポーリング全体が止まってしまいます。Sonarr や Radarr を zurg に向ける方法は [sabnzbd.md](../guides/sonarr-radarr.md) を見てください。

正とする情報源: `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...` から取得したファイル
**2026-08-22** に取得。以下の行番号はすべて、これらのファイルから読み取ったものです。

セクションに別の記載がない限り、**2つのリポジトリの SAB ファイルは、UTF-8 BOM と `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` の名前変更を除けば完全に同一で、行番号も1対1で一致します。** そのため、`Sabnzbd*` の参照はどちらのリポジトリにも同じ行で当てはまります。パスは両方とも `src/NzbDrone.Core/Download/Clients/Sabnzbd/...` です。確認済みの差分は §6 に記録しています。

ここに書いてあることは SAB 自体についての推測ではありません。どの主張も *クライアント* の動作についてです。Newtonsoft.Json や .NET ランタイムの挙動（Sonarr のコードではないもの）について述べる場合は、その旨を明記しています。

---

## 0. 通信レベルのルール（最初にハマるところ） {#0-transport-level-rules-these-bite-first}

### 0.1 URL の形 {#01-url-shape}

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

- ベースURL: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-66`)
  = `{http|https}://{Host}:{Port}{UrlBase}`。`UrlBase` に先頭の `/` がなければ付きます。
  エンドポイントは、それに `/api` を足したものです (`SabnzbdProxy.cs:38-44`)。
- suffix パラメータは必ず最後に付くので、**`apikey`（または `ma_username`+`ma_password`）と `output=json`
  が最後のクエリパラメータ**になります (`HttpRequestBuilder.cs:82` — `QueryParams.Concat(SuffixQueryParams)`)。
- すべての呼び出しで `Accept: application/json` と `output=json` が付きます。`output=xml` の経路はどこにもありません。
- APIキーとユーザー名/パスワードは**どちらか一方だけ**使います。APIキーがあると、`ma_username`/`ma_password` は無視されます。

### 0.2 エラーでも常に HTTP 200 を返す {#02-always-answer-http-200--even-for-errors}

`HttpClient.Execute` は、ステータスが 400 以上だと例外を投げます（`src/NzbDrone.Common/Http/HttpClient.cs:106-121`;
`HttpResponse.cs:54` — `HasHttpError => (int)StatusCode >= 400`。429 の場合は `TooManyRequestsException` になります）。
`SabnzbdProxy.ProcessRequest`（`SabnzbdProxy.cs:199-215`）は、それを `DownloadClientException("Unable to connect to SABnzbd, {0}")` に変換します。

`HttpException` のメッセージは `"HTTP request failed: [401:Unauthorized] [GET] at [url]"` です（`src/NzbDrone.Common/Http/HttpException.cs:18`）。**メッセージにはボディが含まれていません**。そのため、`{"error":"API Key Incorrect"}` を返す 401 は `TestAuthentication` で認識されず（`Sabnzbd.cs:424,429` は `ex.Message` で照合しています）、接続テストは一般的な "Test was aborted due to an error" を報告してしまいます。 **SAB を模倣しましょう: HTTP 200 と `{"status": false, "error": "..."}` を返します。**

### 0.3 デシリアライザの設定（フィールド名と型に関するすべての判断の基準） {#03-deserializer-settings-drives-every-field-name-and-type-question}

すべての SAB ペイロードは `NzbDrone.Common.Serializer.Json` を通ります（`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`）。使われているのは **System.Text.Json ではなく Newtonsoft** です。

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

これは Newtonsoft の動作によるもので、Sonarr 独自のコードではありません。

| 設定 | エミュレーターへの影響 |
|---|---|
| `CamelCasePropertyNamesContractResolver` | C# の `Storage` は `storage` に、`PP` は `pp`、`Misc` は `misc` にバインドされます。Newtonsoft は大文字小文字を区別しないプロパティ照合にもフォールバックするため、SAB の実際の snake_case や小文字のキーは、どちらの場合でもバインドされます。 |
| `StringEnumConverter`（グローバル） | `SabnzbdDownloadStatus` に適用されます。こちらには個別のプロパティ用コンバーターがありません。不明な列挙名は `JsonSerializationException` を投げます。整数も受け付けます（`AllowIntegerValues` はデフォルトで true）。 |
| `NullValueHandling.Ignore` | 読み取り時にも効きます。JSON の `null` は、C# のメンバーをコンストラクターで設定された値のままにします。そのため `"categories": null` ならコンストラクターの空リストが残ります。一方 `"misc": null` だと `Misc` は null のままになります（コンストラクターによるデフォルト値がないため）。そうなると NRE が発生します。§3.4 を参照してください。 |
| `MissingMemberHandling`（デフォルトは `Ignore`） | ペイロードに余分なフィールドがあっても問題ありません。本物の SAB のボディを全部送ることをおすすめします。 |
| `Culture`（デフォルトは `InvariantCulture`） | `"1024.00"` のような数値の文字列は、小数点に `.` を使い、桁区切りを入れない必要があります。 |

`Json.Deserialize<T>` が再スローするのは、わかりやすいメッセージに包み直した `JsonReaderException` だけです（`Json.cs:39-50`）。
`Json.TryDeserialize<T>` が握りつぶすのは **`JsonReaderException` と `JsonSerializationException` だけ** です（`Json.cs:99-117`）。それ以外の例外（たとえば timeleft コンバーターからの `ArgumentException` や、priority コンバーターからの NRE）はそのまま外に抜けます。

---

## 1. 使われるすべてのモード、すべてのパラメータ、すべてのフィールド {#1-every-mode-every-parameter-every-field-consumed}

### 1.1 `mode=version` — `SabnzbdProxy.GetVersion`（`SabnzbdProxy.cs:85-95`） {#11-modeversion--sabnzbdproxygetversion-sabnzbdproxycs85-95}

**リクエスト:** `GET /api?mode=version&apikey=KEY&output=json`

**レスポンスモデル** `SabnzbdVersionResponse` (`Responses/SabnzbdVersionResponse.cs:5`):

| JSON キー | C# 型 | 備考 |
|---|---|---|
| `version` | `string` | 読み取る唯一のフィールドです。 |

`Json.TryDeserialize` で読み込みます。パースに失敗すると `Version == null` になります (`SabnzbdProxy.cs:89-92`)。

パース処理 (`Sabnzbd.cs:334-366`)。正規表現は `Sabnzbd.cs:38` にあります:

```csharp
// patch can be a number (releases) or 'x' (git)
private static readonly Regex VersionRegex = new Regex(@"(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+|x)", RegexOptions.Compiled);
```

- アンカーなしなので、`4.5.0RC1` や `2.0.0beta1` もパースできます (フィクスチャ `SabnzbdFixture.cs:523,553`)。
- `patch` が文字どおりの `x` の場合 (git ビルド) は、`0` に置き換えられます (`Sabnzbd.cs:351`)。
- **2 要素**のバージョン (`"4.5"`) はマッチしないので、`null` になり、検証失敗になります。
- 完全一致の `"develop"` (大文字小文字は区別しません) は特別扱いされ、`3.0.0` として扱われます (`Sabnzbd.cs:355-362`)。失敗ではなく、*警告* が出ます (`Sabnzbd.cs:380-387`)。

バージョンは `HasVersion` (`Sabnzbd.cs:294-332`) で、もう一度取得されます (`mode=version` へのリクエストが 2 回目になります)。**キャッシュはされません**。

### 1.2 `mode=get_config` — `SabnzbdProxy.GetConfig`（`SabnzbdProxy.cs:97-104`） {#12-modeget_config--sabnzbdproxygetconfig-sabnzbdproxycs97-104}

`GET /api?mode=get_config&apikey=KEY&output=json`

`Json.Deserialize` を使っています（**Try** ではありません）。不正なボディがあると `GetConfig` から例外が投げられます。

トップレベルは `{"config": {...}}` である必要があります（`Responses/SabnzbdConfigResponse.cs:5`）。フィールドについては §3 を参照してください。

### 1.3 `mode=fullstatus` — `SabnzbdProxy.GetFullStatus`（`SabnzbdProxy.cs:106-114`） {#13-modefullstatus--sabnzbdproxygetfullstatus-sabnzbdproxycs106-114}

リクエスト: `GET /api?mode=fullstatus&skip_dashboard=1&apikey=KEY&output=json`

最上位は `{"status": {...}}` です（`Responses/SabnzbdFullStatusResponse.cs:5`）。読み取るフィールドは1つだけです:

| JSONキー | C# | ソース |
|---|---|---|
| `completedir` | `string CompleteDir` | `SabnzbdFullStatus.cs:9-10` — 注意: **`completedir`、アンダースコアなし** |

このエンドポイントは、`config.misc.complete_dir` が*ルート指定されておらず*、かつ**SAB のバージョンが >= 2.0**のときにのみ呼ばれます（`Sabnzbd.cs:220-226`）。`complete_dir` が絶対パスの場合、このエンドポイントは呼ばれることはありません。それでも実装はしておきましょう。

知っておくと良いちょっとしたクセがひとつあります。実際のボディは `{"status": {...}}` で、`SabnzbdJsonError.Status` は `string` なので、`CheckForError` の `TryDeserialize<SabnzbdJsonError>` は `JsonSerializationException` で失敗し、プレーンテキストの分岐に入ります。そこで `Status = "true"` が設定されます（`SabnzbdProxy.cs:224-240`）。害はありませんが、fullstatus が JSON 経由でエラーを報告することは決してない、という意味になります。

### 1.4 `mode=queue`（読み取り）— `SabnzbdProxy.GetQueue`（`SabnzbdProxy.cs:116-130`） {#14-modequeue-read--sabnzbdproxygetqueue-sabnzbdproxycs116-130}

リクエスト: `GET /api?mode=queue&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- `category` は、設定されたカテゴリが空白でない場合**のみ**追加されます (`SabnzbdProxy.cs:122-125`)。
- 呼び出し元:
  - `Sabnzbd.GetQueue()` は `start=0, limit=0` を使います (`Sabnzbd.cs:57`)。SAB は `limit=0` を「すべて」として扱います。
  - `Sabnzbd.GetCategories()` は、SAB 2.0 より前のパスで `start=0, limit=1` を使います (`Sabnzbd.cs:229`)。
  - `Sabnzbd.RemoveItem()` は、キューか履歴かを判断するためにもう一度これを呼び出します (`Sabnzbd.cs:199`)。
- 抽出: `Json.Deserialize<SabnzbdQueue>(JObject.Parse(response).SelectToken("queue").ToString())` (`SabnzbdProxy.cs:129`)。**トップレベルに `queue` キーがないと NRE になります。**

`SabnzbdQueue` (`SabnzbdQueue.cs`):

| JSON キー | C# | 型 | 用途 |
|---|---|---|---|
| `my_home` | `DefaultRootFolder` | `string` | SAB 2.0 より前のバージョンでのみ、相対的な `complete_dir` を解決するために使います (`Sabnzbd.cs:230`)。`SabnzbdQueue.cs:8` のコメント: "Removed in Sabnzbd 2.0.0, see mode=fullstatus instead." |
| `paused` | `Paused` | `bool` | グローバルの一時停止。スロットの優先度と組み合わせて使います (`Sabnzbd.cs:78`)。 |
| `slots` | `Items` | `List<SabnzbdQueueItem>` | |

`SabnzbdQueueItem` (`SabnzbdQueueItem.cs`):

| JSON キー | C# メンバー | C# 型 | SAB の実際の JSON 型 | 注記 |
|---|---|---|---|---|
| `status` | `Status` | `SabnzbdDownloadStatus` | 文字列 | グローバルの `StringEnumConverter` を使います。不明な値 ⇒ `JsonSerializationException` ⇒ `GetQueue` 全体が例外を投げます。 |
| `index` | `Index` | `int` | 数値 | 読み取るだけで、使っていません。 |
| `timeleft` | `Timeleft` | `SabnzbdQueueTimeConverter` 経由の `TimeSpan` | 文字列 | §1.4.1 を参照してください。 |
| `mb` | `Size` | `decimal` | **文字列** (`"1024.00"`) | **メガバイト**です。`TotalSize = (long)(Size * 1024 * 1024)` (`Sabnzbd.cs:72`)。 |
| `mbleft` | `Sizeleft` | `decimal` | **文字列** | **メガバイト**です。`RemainingSize = (long)(Sizeleft * 1024 * 1024)` (`Sabnzbd.cs:73`)。 |
| `filename` | `Title` | `string` | 文字列 | `DownloadClientItem.Title` になります (`Sabnzbd.cs:71`)。 |
| `priority` | `Priority` | `SabnzbdPriorityTypeConverter` 経由の `SabnzbdPriority` | 文字列 (`"Normal"`) | §2 を参照してください。 |
| `cat` | `Category` | `string` | 文字列 | キューでは `cat`、履歴では `category` です。 |
| `mbleft`/`percentage` | `Percentage` | `int` | **文字列** (`"50"`) | 読み取るだけで、使っていません。 |
| `nzo_id` | `Id` | `string` | 文字列 | Sonarr/Radarr がすべてのキーにするダウンロード ID です。 |

#### 1.4.1 `timeleft` の形式 — `SabnzbdQueueTimeConverter`（`JsonConverters/SabnzbdQueueTimeConverter.cs:15-28`） {#141-timeleft-format--sabnzbdqueuetimeconverter-jsonconverterssabnzbdqueuetimeconvertercs15-28}

```csharp
var split = reader.Value.ToString().Split(':').Select(int.Parse).ToArray();
switch (split.Length)
{
    case 4: return new TimeSpan((split[0] * 24) + split[1], split[2], split[3]);   // d:h:m:s
    case 3: return new TimeSpan(split[0], split[1], split[2]);                     // h:m:s
    default: throw new ArgumentException("Expected either 0:0:0:0 or 0:0:0 format, but received: " + reader.Value);
}
```

- **コロンで区切られた整数が 3 つか 4 つ。** `"0:08:32"`、`"40:12:14"`、`"1:16:12:14"` はすべて OK です
  (フィクスチャ `SabnzbdQueueTimeConverterFixture.cs:14-20`)。`"1"`、`"0:1"`、`"0:0:0:0:1"` は例外を投げます (`:28-35`)。先頭のゼロは問題ありません (`int.Parse`)。
- 投げられる `ArgumentException` は `Json.TryDeserialize` でも `Json.Deserialize` でもキャッチされません。
- **空文字列** `""` は `[""]` に分割され、`int.Parse` が `FormatException` を投げます。`""` は絶対に出力しないでください。
- `timeleft` を丸ごと省略するのは安全です。コンバーターは呼ばれず、`Timeleft` は `TimeSpan.Zero` のままです。

### 1.5 `mode=queue&name=delete` — `SabnzbdProxy.RemoveFromQueue`（`SabnzbdProxy.cs:64-72`） {#15-modequeuenamedelete--sabnzbdproxyremovefromqueue-sabnzbdproxycs64-72}

```
GET /api?mode=queue&name=delete&del_files={0|1}&value={nzo_id}&apikey=KEY&output=json
```

`del_files = deleteData ? 1 : 0`（`SabnzbdProxy.cs:68`）。**キューのパスには `archive` パラメータがありません。**
レスポンスの本文は `CheckForError` に通すだけで、デシリアライズはしていません。

### 1.6 `mode=history`（読み取り）— `SabnzbdProxy.GetHistory`（`SabnzbdProxy.cs:132-146`） {#16-modehistory-read--sabnzbdproxygethistory-sabnzbdproxycs132-146}

**リクエスト:** `GET /api?mode=history&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- 呼び出し元: `Sabnzbd.GetHistory()` で `start=0, limit=_configService.DownloadClientHistoryLimit` を渡しています（`Sabnzbd.cs:110`）。既定値は両リポジトリとも **60** です（Sonarr `src/NzbDrone.Core/Configuration/ConfigService.cs:184`、Radarr `:236`）。
- 抽出: `SelectToken("history")`（`SabnzbdProxy.cs:145`）を使うので、トップレベルは `{"history": {...}}` の形になっている必要があります。

`SabnzbdHistory`（`SabnzbdHistory.cs`）: `paused`（`bool`、未使用）、`slots` → `Items`。

`SabnzbdHistoryItem`（`SabnzbdHistoryItem.cs`）:

| JSON キー | C# メンバー | C# 型 | 備考 |
|---|---|---|---|
| `fail_message` | `FailMessage` | `string` | `DownloadClientItem.Message` になり（`Sabnzbd.cs:132`）、Warning の特別扱い（§1.6.1）の判断にも使われます。 |
| `bytes` | `Size` | `long` | **バイト単位で、MB ではありません**。`TotalSize = sabHistoryItem.Size` としてそのまま入ります（`Sabnzbd.cs:128`）。`mode=queue` との一番大きな違いです。 |
| `category` | `Category` | `string` | queue では `cat` を使いますが、こちらは `category` です。 |
| `nzb_name` | `NzbName` | `string` | 読み取るだけで、使われていません。 |
| `download_time` | `DownloadTime` | `int`（秒） | 読み取るだけで、使われていません。 |
| `storage` | `Storage` | `string` | 出力先のパスです。§1.6.2 を参照してください。これが `rm -rf` で削除される対象です。 |
| `status` | `Status` | `SabnzbdDownloadStatus` | グローバルの `StringEnumConverter` を使います。 |
| `nzo_id` | `Id` | `string` | |
| `name` | `Title` | `string` | |

**SAB のモデルには `DateTime` 型のメンバーが一つもないため、日付の形式に制約はありません。**
`completed` / `last_history_update`（実際の SAB では unix エポック）は一切読み取られていません。時刻や時間に関係する値で重要なのは、`timeleft`（§1.4.1）と `download_time`（秒単位の整数で、読み取られていない）だけです。

#### 1.6.1 履歴のステータス → `DownloadItemStatus`（`Sabnzbd.cs:116-158`） {#161-history-status--downloaditemstatus-sabnzbdcs116-158}

```
Deleted                                   -> skipped entirely (Sabnzbd.cs:116-119)
Failed  + fail_message == "Unpacking failed, write error or disk is full?"
        (InvariantCultureIgnoreCase)      -> DownloadItemStatus.Warning     (:140-144)
Failed  (any other message)               -> DownloadItemStatus.Failed      (:147)
Completed                                 -> DownloadItemStatus.Completed   (:152)
anything else (Verifying/Moving/...)      -> DownloadItemStatus.Downloading (:157)
```

履歴の各項目には `RemainingSize = 0`、`RemainingTime = TimeSpan.Zero`、`CanBeRemoved = true`、`CanMoveFiles = true` が設定されます（`Sabnzbd.cs:129-135`）。

`DownloadItemStatus` 自体（`src/NzbDrone.Core/Download/DownloadItemStatus.cs:3-11`）は次のとおりです：
`Queued=0, Paused=1, Downloading=2, Completed=3, Failed=4, Warning=5`。

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

ループは**ルートまで**たどり、`name`と最後のセグメントが一致する*最も上位の*祖先を残します。目的は、`storage`がジョブフォルダ内のファイルを指している場合に、ジョブフォルダまで戻ることです
(フィクスチャ `SabnzbdFixture.cs:376-391`)。`storage`がすでにジョブフォルダである場合は、一致する祖先がなく、`OutputPath == storage`になります。これが望ましい動作です。

**エミュレーター向けのおすすめ: `storage`にはジョブフォルダのパスそのものを設定してください。**

空の`storage` ⇒ `OutputPath`は空のまま ⇒ `CompletedDownloadService.ValidatePath`が
"Download doesn't contain intermediate path, Skipping." という警告を出します (Sonarr `CompletedDownloadService.cs:299-303`)。

### 1.7 `mode=history&name=delete` — `SabnzbdProxy.RemoveFromHistory`（`SabnzbdProxy.cs:74-83`） {#17-modehistorynamedelete--sabnzbdproxyremovefromhistory-sabnzbdproxycs74-83}

```
GET /api?mode=history&name=delete&del_files={0|1}&value={nzo_id}&archive={0|1}&apikey=KEY&output=json
```

```csharp
request.AddQueryParam("del_files", deleteData ? 1 : 0);          // :78
request.AddQueryParam("value", id);                              // :79
request.AddQueryParam("archive", deletePermanently ? 0 : 1);     // :80   <-- inverted
```

そして呼び出し元（`Sabnzbd.cs:208`）:

```csharp
_proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
```

つまり `deletePermanently == (status is Failed)` となり、結果は次のとおりです:

| Item status | `del_files` | `archive` |
|---|---|---|
| Completed | 1 | **1** (archive it) |
| Failed | 1 | **0** (permanent delete) |

最初に見ると逆に思えるかもしれませんが、これがコードの実際の動作です。

### 1.8 `mode=addfile` — `SabnzbdProxy.DownloadNzb`（`SabnzbdProxy.cs:46-62`） {#18-modeaddfile--sabnzbdproxydownloadnzb-sabnzbdproxycs46-62}

```
POST /api?mode=addfile&cat={category}&priority={int}&apikey=KEY&output=json
Content-Type: multipart/form-data; boundary=...
  part: Content-Disposition: form-data; name="name"; filename="<CleanFileName(Release.Title)>.nzb"
        Content-Type: application/x-nzb
```

- マルチパートのフィールドは文字どおり `name` で、そのパートには `filename` が付きます（`SabnzbdProxy.cs:53`、
  `HttpRequestBuilder.cs:379-395`、出力箇所は `:180-195`）。
- ファイル名は `FileNameBuilder.CleanFileName(release.Title) + ".nzb"` から作られます
  （Sonarr `src/NzbDrone.Core/Download/UsenetClientBase.cs:43`、Radarr `:43`）。
- **`cat` はメソッドの `category` 引数を無視**して、設定から直接値を読みます
  （`SabnzbdProxy.cs:50`: `request.AddQueryParam("cat", settings.TvCategory);` — Radarr: `settings.MovieCategory`）。
  呼び出し元が同じ値を渡しているので、実害はありません。
- `priority` は `SabnzbdPriority` から来る生の `int` で（§2 参照）、新しさによって選ばれます：
  Sonarr `Sabnzbd.cs:43` `remoteEpisode.IsRecentEpisode() ? Settings.RecentTvPriority : Settings.OlderTvPriority`；
  Radarr `Sabnzbd.cs:43` `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie ? RecentMoviePriority : OlderMoviePriority`。
- レスポンス `SabnzbdAddResponse`（`Responses/SabnzbdAddResponse.cs`）：

| JSON キー | C# | 型 |
|---|---|---|
| `status` | `Status` | `bool` — パースされるが、**一度も読まれません** |
| `nzo_ids` | `Ids` | `List<string>`、コンストラクタで空に初期化 |

  `TryDeserialize` で読み込みます。失敗した場合は、代わりに合成した `{Status=true, Ids=[]}` が使われます（`SabnzbdProxy.cs:55-59`）。
  その後 `Sabnzbd.cs:47-52`：

```csharp
if (response == null || response.Ids.Empty())
{
    throw new DownloadClientRejectedReleaseException(remoteEpisode.Release, "SABnzbd rejected the NZB for an unknown reason");
}

return response.Ids.First();
```

  **`nzo_ids` は空でない文字列の配列である必要があります。** `"nzo_ids": null` は存在しない場合と同じ扱いになります
  （`NullValueHandling.Ignore` によってコンストラクタの空リストが残ります）。そして同じように失敗します。

### 1.9 キューのステータス → `DownloadItemStatus`（`Sabnzbd.cs:60-103`） {#19-queue-status--downloaditemstatus-sabnzbdcs60-103}

```
Deleted                                       -> skipped (Sabnzbd.cs:62-65)
(queue.paused && slot.priority != Force) || slot.status == Paused
                                              -> Paused, and RemainingTime forced to null (:78-84)
Queued | Grabbing | Propagating               -> Queued        (:85-90)
everything else                               -> Downloading   (:93)
```

また、`Sabnzbd.cs:96-100` では、先頭が文字どおりの `"ENCRYPTED /"` で始まるタイトルから、その11文字を取り除き、アイテムに `IsEncrypted = true` のフラグを立てます。

キューのすべてのアイテムには、`CanBeRemoved = true` と `CanMoveFiles = true` が設定されます（`Sabnzbd.cs:75-76`）。

### 1.10 クライアント側のカテゴリフィルター（`Sabnzbd.cs:186-195`） {#110-client-side-category-filter-sabnzbdcs186-195}

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

ordinal（序数）による文字列の完全一致です。カテゴリが `*` のアイテムは、設定されたカテゴリが空欄の場合だけ受け入れられます。

### 1.11 プロキシには存在するが、一度も呼ばれないモード {#111-modes-that-exist-in-the-proxy-but-are-never-called}

- `mode=retry&value={id}` (`SabnzbdProxy.cs:148-160`、レスポンス `{status, nzo_id}` → `Responses/SabnzbdRetryResponse.cs`)。`ISabnzbdProxy.RetryDownload` は、どちらのリポジトリにも**呼び出し元がありません**。
- `Responses/SabnzbdCategoryResponse.cs`（`{"categories": [...]}`、つまり `mode=get_cats`）は、どちらのリポジトリでも**完全に参照されていません**。
- `Sabnzbd.ValidatePath`（`Sabnzbd.cs:576-592`）は private で、一度も呼ばれていません（デッドコード）。

## 2. `SabnzbdDownloadStatus` と `SabnzbdPriority` — 正確なメンバーと unknown/null の扱い {#2-sabnzbddownloadstatus-and-sabnzbdpriority--exact-members-unknownnull-handling}

### 2.1 `SabnzbdPriority.cs`（ファイル全体） {#21-sabnzbdprioritycs-complete-file}

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

- `Enum.TryParse<T>(string, out T)` は **大文字小文字を区別する** オーバーロードです（.NET の仕様）。
  `"Normal"` は解析できますが、`"normal"` は **解析できません**。しかも失敗すると `output` は
  `default(SabnzbdPriority) == 0 == Normal` になるので、大文字小文字を間違えると黙って Normal になってしまいます。
  `"Force"` は §1.9 で重要ですが、`"force"` は動きません。
- 数字の文字列も解析できます。`"2"` は `Force`、`"-100"` は `Default` になります。JSON の数値 `2` も動きます（`reader.Value.ToString()` が `"2"` になるため）。
- **`"priority": null` は `NullReferenceException` を投げます**（null に対して `reader.Value.ToString()` を呼ぶため）。
  これは `Json.TryDeserialize` では **キャッチされません**。キーを省略するか、実際の値を送ってください。
- `priority` を省略するのは安全です。コンバーターは呼ばれず、メンバーは `Normal` (0) のままです。
- コンバーターは `SabnzbdQueueItem.Priority`（`SabnzbdQueueItem.cs:21`）にだけ登録されています。履歴のアイテムには priority がありません。
- Sonarr/Radarr が `mode=addfile` の `&priority=` として送り返してくるのも、この同じ整数値です（`SabnzbdSettings.cs` では `Recent*Priority` と `Older*Priority` の両方が `(int)SabnzbdPriority.Default` = `-100` にデフォルト設定されています）。

### 2.2 `SabnzbdDownloadStatus.cs`（ファイル全体）。宣言順が暗黙の値 0〜15 になる {#22-sabnzbddownloadstatuscs-complete-file-declaration-order--implicit-values-015}

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

- **プロパティごとのコンバーターはありません。** グローバルに登録された `StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }`（`Json.cs:32`）がこれを処理します。
- **知らない名前は例外を投げます**（Newtonsoft の `EnumUtils.ParseEnum` → `JsonSerializationException`）。`GetQueue`/`GetHistory` は `Json.Deserialize` を使う（Try ではない）ので、キューや履歴の呼び出し全体が失敗します。**このリストにないステータスは絶対に出さないでください。**
- 上に書いた SAB の正式なスペル（`"Downloading"`, `"QuickCheck"`, `"Completed"`, `"Failed"`, `"Propagating"`, ...）をそのまま出してください。Newtonsoft の enum マッチングは大文字小文字を区別しないフォールバックがありますが、当てにしてよいのは正確な大文字小文字だけです。
- 整数も受け付けます（`AllowIntegerValues` はデフォルトで true）が、使わないでください。
- `status` に JSON の `null` を入れると `NullValueHandling.Ignore` で無視され、そのメンバーは `Grabbing`（0）のままになります。キューのスロットは黙って `Queued` になり、履歴のスロットは黙って `Downloading` になります。必ず明示的にステータスを送ってください。

---

## 3. `get_config`：読み取る内容と検証ルール {#3-get_config-exactly-what-is-read-and-the-validation-rules}

### 3.1 モデル — `SabnzbdCategory.cs` {#31-the-model--sabnzbdcategorycs}

このファイルには `SabnzbdConfig`、`SabnzbdConfigMisc`、`SabnzbdCategory` **と** `SabnzbdSorter` が入っています。
どちらのリポジトリにも **`SabnzbdConfig.cs` は存在しません**（`src/NzbDrone.Core/Download/Clients/Sabnzbd` の GitHub contents API の一覧で確認済みです）。

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

### 3.2 `config.misc.*` — 読み取るキーの全一覧（`SabnzbdCategory.cs:23-37`） {#32-configmisc--the-complete-set-of-keys-read-sabnzbdcategorycs23-37}

| JSON キー | C# 型 | 読み込み位置 | 用途 |
|---|---|---|---|
| `complete_dir` | `string` | `Sabnzbd.cs:218` | すべてのカテゴリパスの基準になります。 |
| `tv_categories` | `string[]` | `Sabnzbd.cs:265, 493` | |
| `enable_tv_sorting` | `bool` | `Sabnzbd.cs:265, 493` | |
| `movie_categories` | `string[]` | `Sabnzbd.cs:269, 502` | |
| `enable_movie_sorting` | `bool` | `Sabnzbd.cs:269, 502` | |
| `date_categories` | `string[]` **via `SabnzbdStringArrayConverter`** | `Sabnzbd.cs:273, 511` | |
| `enable_date_sorting` | `bool` | `Sabnzbd.cs:273, 511` | |
| `pre_check` | `bool` | `Sabnzbd.cs:443` | |
| `history_retention` | `string` | `Sabnzbd.cs:540, 561-573` | 旧バージョン向け。SAB < 4.3。 |
| `history_retention_option` | `string` | `Sabnzbd.cs:541, 544` | SAB >= 4.3。 |
| `history_retention_number` | `int` | `Sabnzbd.cs:542, 553` | SAB >= 4.3。 |

`SabnzbdStringArrayConverter`（`JsonConverters/SabnzbdStringArrayConverter.cs:25-39`）は、
`date_categories`（`SabnzbdCategory.cs:30`）にだけ適用されます:

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

JSON の**文字列**は要素が1つの配列になります。**null** は `[null]`（null を1つ含む配列）になります。**配列**はふつうどおりデシリアライズされます。それ以外（数値、オブジェクト）は例外が発生します。

ドキュメントコメント（`:7-9`）: "On some properties sab serializes array of single item as plain string."

### 3.3 `config.categories[]` — `SabnzbdCategory`（`SabnzbdCategory.cs:39-48`） {#33-configcategories--sabnzbdcategory-sabnzbdcategorycs39-48}

| JSON key | C# | 読み込み箇所 |
|---|---|---|
| `priority` | `int Priority` | 読み込まれない |
| `pp` | `string PP` | 読み込まれない（`PP` の camelCase は `pp`） |
| `name` | `string Name` | `Sabnzbd.cs:251, 255, 458` |
| `script` | `string Script` | 読み込まれない |
| `dir` | `string Dir` | `Sabnzbd.cs:238`（`Dir.TrimEnd('*')`）、`Sabnzbd.cs:462`（`Dir.EndsWith("*")`） |

`FullPath`（`OsPath`）は逆シリアル化されず、計算で求められます。

パスの組み立て — `Sabnzbd.GetCategories`（`Sabnzbd.cs:216-244`）:

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

`right.IsEmpty` のとき `OsPath.operator+`（`src/NzbDrone.Common/Disk/OsPath.cs:420-448`）は `left` を返すので、`dir: ""` の場合は `FullPath` がそのまま `complete_dir` になります。Unix 系のパスの `IsRooted` は `_path.StartsWith("/")`（`OsPath.cs:142-145`）です。パスの種類は文字列から判定されます（`OsPath.cs:43-60`）。先頭が `/` なら Unix、`\` やドライブレターなら Windows です。Unix 系のパスを Windows 上で動いている Sonarr に渡すと、`CompletedDownloadService.ValidatePath`（`:305-310`）で失敗します。

（以前の翻訳は、コードスパンが異なるとして却下されました（`FullPath == complete_dir`）。構造はそのまま維持してください。）

### 3.4 NRE の 2 つの落とし穴（と実際に安全な部分） {#34-the-two-nre-landmines-and-what-is-actually-safe}

| ペイロードの形 | 結果 |
|---|---|
| **`"misc"` が存在しない、または `null`** | `Misc` は null のまま（コンストラクタの既定値なし。読み込み時は `NullValueHandling.Ignore`）→ **`Sabnzbd.cs:218` で NullReferenceException**。"Test was aborted due to an error: …" と表示され、ヘルスチェックにもエラーとしてログが残ります。 |
| **`"dir"` が存在しない、または `null` のカテゴリ** | `Dir` が null → **`Sabnzbd.cs:238`**（`category.Dir.TrimEnd('*')`）と、もう一度 **`:462`**（`category.Dir.EndsWith("*")`）で NullReferenceException。 |
| `"categories": null` または存在しない | 安全。コンストラクタの空リストがそのまま残ります。その後 `GetStatus` はカテゴリを見つけられず、`OutputRootFolders` は空のままです。 |
| `"sorters": null` または存在しない | 安全。コンストラクタの空リストが残り、`Sabnzbd.cs:484` の `config.Sorters.Any(...)` は問題なく動きます。 |
| `"servers": null` または存在しない | 安全。そもそも読み込まれません（`List<object>`、`SabnzbdCategory.cs:19`）。 |
| `"tv_categories"/"movie_categories"/"date_categories": null` | 安全。`ContainsCategory` は null/空に対して `true` を返しますが（§3.5）、対応する `enable_*_sorting` が true のときだけ影響します。 |

**ルール: `misc` は必ずオブジェクトとして出力し、すべてのカテゴリに文字列の `dir` を入れてください（空なら `""`）。**

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

フィクスチャで確認済みです。`enable_tv_sorting=true` かつ `tv_categories=null` の場合は **失敗します**
(`SabnzbdFixture.cs:636-645`)。`tv_categories=[]` の場合も **失敗します** (`:647-656`)。
`TvCategory=null` かつ `tv_categories=["Default"]` の場合は失敗します (`:680-691`)。

### 3.6 `Test()` — 正確な順序とルール（`Sabnzbd.cs:286-292`） {#36-test--the-exact-order-and-rules-sabnzbdcs286-292}

```csharp
protected override void Test(List<ValidationFailure> failures)
{
    failures.AddIfNotNull(TestConnectionAndVersion());
    failures.AddIfNotNull(TestAuthentication());
    failures.AddIfNotNull(TestGlobalConfig());
    failures.AddIfNotNull(TestCategory());
}
```

`DownloadClientBase.Test()`（`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`）でラップされていて、
外に漏れた例外をキャッチし、`"Test was aborted due to an error: " + ex.Message` を追加します。

**`TestConnectionAndVersion()`（`Sabnzbd.cs:368-414`）**：`mode=version` を 1 回呼びます。

1. バージョンを解析できない → `Version` フィールドで失敗（`DownloadClientSabnzbdValidationUnknownVersion`）。
2. `rawVersion == "develop"`（大文字小文字を区別しない）→ `Version` で**警告**。`IsValid` は true のまま（フィクスチャ `SabnzbdFixture.cs:566-577`）。
3. `version.Major >= 1` → 合格（`:389-392`）。
4. それ以外で `version.Minor >= 7` → 合格（`:394-397`）。
5. それ以外は失敗。必要なバージョンは `"0.7.0"`（`:399-404`）。
   フィクスチャの表（`SabnzbdFixture.cs:549-564`）：`0.6.9` → false、`0.7.0`/`0.8.0`/`1.0.0`/`1.0.0RC1`/`1.1.x` → true。
6. 例外が出たら `Host` フィールドで失敗（"unable to connect"）。詳細は `ex.Message`（`:406-413`）。

**`TestAuthentication()`（`Sabnzbd.cs:416-438`）**：`mode=get_config` を 1 回呼びます。例外をキャッチしたあと、
`ex.Message` を `ContainsIgnoreCase` で照合します。

| 一致する部分文字列 | 失敗フィールド |
|---|---|
| `API Key Incorrect` | `APIKey` — `DownloadClientValidationApiKeyIncorrect` |
| `API Key Required` | `APIKey` — `DownloadClientValidationApiKeyRequired` |
| それ以外 | **再スロー**される → 汎用の "Test was aborted due to an error: …" |

`CheckForError` は本文を `"Error response received from SABnzbd: {error}"` でラップします（`SabnzbdProxy.cs:244`）。
そのため、照合が成功するのは `error` の文字列に `API Key Incorrect` / `API Key Required` が*含まれている*場合です。これは SAB 自身の文言です。

**`TestGlobalConfig()`（`Sabnzbd.cs:440-453`）**：`mode=get_config` を 1 回呼びます。`pre_check` が true のときだけ `mode=version` も 1 回呼びます。

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

しきい値は **SAB >= 1.1.0** です（`HasVersion(major:1, minor:1, patch:0)`、`Sabnzbd.cs:294-332`）。
`pre_check: false` にすると、追加の `mode=version` の往復も含めて、この分岐全体を飛ばせます。

**`TestCategory()`（`Sabnzbd.cs:455-521`）**：`mode=get_config` をもう 1 回（3 回目）呼びます。さらに `GetCategories` が必要とする呼び出しも行います。チェックは次の順に実行され、最初に引っかかったものが採用されます。

1. 一致したカテゴリ（`Name == Settings.TvCategory` / `MovieCategory`）の `dir` が **`*` で終わる** → `TvCategory`/`MovieCategory` で警告 "enable job folders"。InfoLink は `config/categories/`（`:460-469`）。
2. 一致するカテゴリがなく、**かつ** 設定されたカテゴリが空白でない → 警告 `DownloadClientValidationCategoryMissing`。InfoLink は `config/categories/`（`:471-481`）。
3. `config.Sorters.Any(s => s.is_active && ContainsCategory(s.sort_cats, cat))` → 警告。InfoLink は `config/sorting/`（`:483-491`）。コード内のコメント（`:483`）は *"SABnzbd 4.1 で新しく追加された。古いバージョンでは空になり、適用されない"* です。
4. `misc.enable_tv_sorting && ContainsCategory(misc.tv_categories, cat)` → 警告（`:493-500`）。
5. `misc.enable_movie_sorting && ContainsCategory(misc.movie_categories, cat)` → 警告（`:502-509`）。
6. `misc.enable_date_sorting && ContainsCategory(misc.date_categories, cat)` → 警告（`:511-518`）。

`SabnzbdSorter`（`SabnzbdCategory.cs:50-66`）で読み取るのは `sort_cats`（`List<string>`、コンストラクタで空）と `is_active`（`bool`）です。モデルには存在するものの、読み取られていないのは `name`、`order`、`min_size`、`multipart_label`、`sort_string`、`sort_type`（`List<int>`）です。

**通信量の注意：** 4 つの `Test*` メソッドはそれぞれ独自に呼び出しを行い、何もキャッシュされません。そのため、接続テスト 1 回で `mode=version` が約 **2 回**、`mode=get_config` が **3 回**発生します（`pre_check` が true なら version の呼び出しがもう 1 回増えます）。

### 3.7 `config.misc` の履歴保持 → `RemovesCompletedDownloads`（`Sabnzbd.cs:538-574`） {#37-configmisc-history-retention--removescompleteddownloads-sabnzbdcs538-574}

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

`true` だと ヘルスチェックの**警告**が出ます
(`HealthCheck/Checks/DownloadClientRemovesCompletedDownloadsCheck.cs:44-53`)。
フィクスチャのテスト範囲 `SabnzbdFixture.cs:455-510`: 旧形式の `"0"`/`""`/`null`/`"15d"` → false;
`"-1"`/`"15"`/`"3"`/`"3d"` → true。

**エミュレーターでの一番すっきりした設定: `history_retention_option: "all"`, `history_retention_number: 0`, `history_retention: "0"`。**

### 3.8 `SortingMode` とそのヘルスチェック（`Sabnzbd.cs:263-279`） {#38-sortingmode-and-its-health-check-sabnzbdcs263-279}

`GetStatus` は、同じ
`enable_*_sorting && ContainsCategory(...)` の条件式を使って、`SortingMode` を `"TV"`、`"Movie"`、`"Date"` のいずれかに設定します。
空白以外の値があると、`HealthCheck/Checks/DownloadClientSortingCheck.cs:45-55` で警告が出ます。
3つの `enable_*_sorting` は、すべて false のままにしておいてください。

### 3.9 `IsLocalhost`（`Sabnzbd.cs:260`） {#39-islocalhost-sabnzbdcs260}

```csharp
IsLocalhost = Settings.Host == "127.0.0.1" || Settings.Host == "localhost"
```

Ordinal（順序比較）で、大文字と小文字を区別します。`::1`、`Localhost`、そしてどのホスト名も**対象外**です。これにより、表示される
`RemotePathMappingCheck` のメッセージが変わります（§6.2 を参照）。

---

## 4. エラー処理 — `CheckForError`（`SabnzbdProxy.cs:222-246`） {#4-error-handling--checkforerror-sabnzbdproxycs222-246}

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

`SabnzbdJsonError`（`SabnzbdJsonError.cs`、全体）:

```csharp
public string Status { get; set; }
public string Error  { get; set; }

public bool Failed => !string.IsNullOrWhiteSpace(Status) &&
                      Status.Equals("false", StringComparison.InvariantCultureIgnoreCase);
```

ルールを正確に説明すると:

- `CheckForError` は、モード固有のデシリアライズより前に、**すべての**レスポンスで実行されます（`SabnzbdProxy.cs:217`）。
- `Status` の型は `string` ですが、SAB は JSON の**真偽値**を送ってきます。Newtonsoft は `false` を `"False"` に変換し、それを `Failed` が大文字小文字を区別せずに照合します。そのため、`false`（真偽値）と `"false"`（文字列）のどちらでも動きます。
- トップレベルに `status` がないレスポンス（例: `{"version": …}`、`{"queue": {...}}`、`{"history": {...}}`、`{"config": {...}}`）では `Status` が null になり、`Failed` は false になるので、エラーにはなりません。
- `status: true` は `"True"` になり、失敗扱いにはなりません。
- **JSON 以外のボディ**: `TryDeserialize` は false を返し（`JsonReaderException` と `JsonSerializationException` を捕まえます。`Json.cs:107-116`）、プレーンテキストの分岐が動きます。`error`（大文字小文字は区別しない）で始まるボディは `Status = "false"` になり、`DownloadClientException("Error response received from SABnzbd: {body with 'error: ' stripped}")` をスローします。それ以外の JSON ではないボディは `Status = "true"` になり、**成功扱い**になります。その後、モード固有のデシリアライズが独自の理由で失敗します。
- `status` がオブジェクトの **JSON ボディ**（`mode=fullstatus`）も、プレーンテキストの分岐に入ります。`StartObject` トークンは `string` プロパティに入れられないため、`Status` は `"true"` になります。
- `:239` の `result.Error = …` は無駄です。成功の分岐でも `Error` が設定されますが、効果はありません。`Failed` が true でない限り、何も `Error` を読まないからです。

`ProcessRequest`（`SabnzbdProxy.cs:187-220`）での例外の対応表:

| Caught | Thrown |
|---|---|
| `HttpException`（2xx 以外すべて。401/403/404/500 を含む） | `DownloadClientException("Unable to connect to SABnzbd, {0}")` |
| `HttpRequestException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |
| `WebException` で `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, certificate validation failed.")` |
| その他の `WebException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |

**認証失敗として照合される正確な文字列**（`Sabnzbd.cs:424, 429`。正確なリテラルで、例外メッセージに対して `ContainsIgnoreCase` で照合します）:

- `"API Key Incorrect"`
- `"API Key Required"`

これ以外は分類されません。これらは **HTTP 200** レスポンスの `error` の値として、そのまま出力してください。

**非 200 を返してはいけない理由:** `HttpClient.Execute` は `CheckForError` が実行される前に例外をスローします（`HttpClient.cs:106-121`）。その結果生じる `HttpException` のメッセージには、ステータス、メソッド、URL しか含まれず、ボディは含まれません（`HttpException.cs:18`）。そのため `"API Key Incorrect"` / `"API Key Required"` の照合は発動できません。ユーザーには、対処法の分かるメッセージではなく「Unable to connect to SABnzbd」や「Test was aborted due to an error」が表示され、すべてのヘルスチェックがクライアントを到達不能として扱ってしまいます。

---

## 5. インポート後の処理の流れ {#5-the-post-import-sequence}

### 5.1 `RemoveItem` を呼ぶのは誰か、そして何を渡すか {#51-who-calls-removeitem-and-with-what}

`DownloadEventHub`（`src/NzbDrone.Core/Download/DownloadEventHub.cs`、BOM 以外は両リポジトリで同一）:

- `Handle(DownloadCompletedEvent)`（`:48-69`）: まず `MarkItemAsImported` を呼びます。SAB は `NotSupportedException` を投げますが（`DownloadClientBase.cs:189-192`）、これは debug レベルでログに出され、無視されます。その後、アイテムがすでに `Removed`、`!CanBeRemoved`、または まだ `Downloading` なら早期 return します。さらに `definition.RemoveCompletedDownloads` が有効でなければ、ここでも早期 return します。
- `Handle(DownloadFailedEvent)`（`:26-46`）: `definition.RemoveFailedDownloads` が条件になっています。
- `Handle(DownloadCanBeRemovedEvent)`（`:71-85`）: `definition.RemoveCompletedDownloads` が条件になっています。
- 3 つすべてが `RemoveFromDownloadClient`（`:87-103`）に流れ込みます:

```csharp
_logger.Debug("[{0}] Removing download from {1} history", …);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);   // :92 -- deleteData is ALWAYS true
trackedDownload.DownloadItem.Removed = true;
```

`DownloadClientDefinition` のデフォルト値（`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17-18`）:

```csharp
public bool RemoveCompletedDownloads { get; set; } = true;
public bool RemoveFailedDownloads    { get; set; } = true;
```

手動 API の経路 `DELETE /api/v3/queue/{id}?removeFromClient=true` も `true` を渡します（Sonarr `src/Sonarr.Api.V3/Queue/QueueController.cs:342`）。**`deleteData: false` を渡している呼び出し元は、どこにもありません。**

### 5.2 `Sabnzbd.RemoveItem`（`Sabnzbd.cs:197-214`）— 正確な手順 {#52-sabnzbdremoveitem-sabnzbdcs197-214--the-exact-sequence}

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

インポート後に、エミュレーターへ送られる通信の流れは次のとおりです:

1. `GET /api?mode=queue&start=0&limit=0&category=tv&apikey=…&output=json`（queue と history のどちらを使うかを判断するため）
2. **出力フォルダのローカルファイル削除**（§5.3）。それ以降の HTTP 呼び出しより前に行います
3. `GET /api?mode=history&name=delete&del_files=1&value={nzo_id}&archive=1&apikey=…&output=json`

**失敗した**アイテムの場合は、ローカル削除は行いません（status は `Completed` ではなく `Failed`）。また **`archive=0`** になります。
これは `SabnzbdProxy.cs:80` の反転によるものです（`archive = deletePermanently ? 0 : 1`。ここで `deletePermanently == (status is Failed)` です）。

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

- **はい、出力フォルダーを再帰的に削除します。** `DeleteFolder(path, recursive: true)` が `:129` にあります。
- ここでの `OutputPath` は、リモートパスの再マッピングとジョブフォルダーの遡り処理(§1.6.2)を経た後の履歴項目の `storage` です。フラットなマジックディレクトリの場合、これは `rm -rf /mnt/zurg/__magic__/__all__/<Title>` を意味します。
- 動作を決めるのは、ダウンロードクライアントの **Remove Completed Downloads** トグル(`DownloadClientDefinition.RemoveCompletedDownloads`、デフォルトは **true**)です。SAB側の設定でも `del_files` でもありません。UIに「データを削除」という別のスイッチはありません。
- 失敗は警告とともに無視されます。読み取り専用のマウントだとログにノイズが出ますが、インポート自体は壊れません。
- フィクスチャのカバレッジ `SabnzbdFixture.cs:693-803` では、次の点を確認しています。フォルダーが再帰的に削除されること、ファイルが削除されること、パスが存在しない場合は何もしないこと、そして `deleteData` が false の場合は(`FolderExists` の確認すら含めて)何も行わないこと。

### 5.4 転送モード：ファイルは移動されるか、コピーされるか？ {#54-transfer-mode-is-the-file-moved-or-copied}

`Sabnzbd` は、キュー（`Sabnzbd.cs:76`）と履歴（`Sabnzbd.cs:135`）のすべてのアイテムに対して `CanMoveFiles = true` を設定します。自動インポートの流れは `CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, …)` です（Sonarr `CompletedDownloadService.cs:148-151`）。そのあと、次のようになります:

Sonarr `src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152`
（Radarr `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129` も同じロジックです）:

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

`CanMoveFiles: true` は `copyOnly == false` になるので、**`TransferMode.Move`**（`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`）が使われます。`copyOnly` のインポートだと、「Use Hardlinks instead of Copy」がオンなら `TransferMode.HardLinkOrCopy`、オフなら `TransferMode.Copy` になります（`:94-108`）。

`TransferMode`（`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`）は `[Flags]` 属性付きで、`None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy = Copy|HardLink` と定義されています。

### 5.5 Move が失敗したらコピーにフォールバックするか？ — **いいえ。Move が失敗したらインポートも失敗です。** {#55-does-a-failed-move-fall-back-to-a-copy--no-a-failed-move-is-a-failed-import}

`src/NzbDrone.Common/Disk/DiskTransferService.cs`（2つのリポジトリ間でバイト単位で同一。確認済み）。
`TransferFile`、`:256-392`。`TransferMode.Move` ブランチは `:360-389`:

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

- **唯一**のコピーフォールバックは `:378-385` の `isCifs && !isSameMount` の特別扱いです。判定は `targetMount.DriveFormat == "cifs"`（`:342`）に基づきます。これは失敗への反応ではなく、ドライブのフォーマットから *事前に* 選ばれます。
- `TryMoveFileVerified`（`:487-503`）は例外を捕捉し、（例外が `FileAlreadyExistsException` でない限り）`RollbackPartialMove` を呼び出してから **再スロー**します:

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

- `VerifyFile`（`:505-524`）は移動先のサイズを移動元のサイズと比較し、3 秒スリープ（`WaitForIO`、`:467-471`）してから再チェックし、その後 `IOException("File move incomplete, data loss may have occurred. [{target}] was {n} bytes long instead of the expected {m}.")` を投げます。
- この `IOException` は `EpisodeFileMovingService.TransferFile`（`:151`）を経由して、`ImportApprovedEpisodes.cs:218-222`（Radarr では `:197-201`）の汎用 `catch (Exception e)` まで伝播し、`ImportResult(importDecision, "Failed to import episode")` / `"Failed to import movie"` を生成します。**コピーは試みられません。**
- 同じメソッド内にあるその他の事前チェック用 `IOException`: 移動元と移動先が同じ（`:270`、`:277`）、および "Destination cannot be a child of the source"（`:312-315`）。

注意点ですが、これは Sonarr のコードではなく .NET ランタイムの仕様です。`DiskProviderBase.MoveFileInternal`（`src/NzbDrone.Common/Disk/DiskProviderBase.cs:293-301`）は単純な `File.Move` で、Unix 上の .NET は `rename()` が `EXDEV` を返すとコピーしてから削除（copy+delete）にフォールバックします。そのため、ファイルシステムをまたぐ移動も通常は成功します。ただしこれは *ランタイムの* フォールバックであり、Sonarr 独自のものではありません。許容されないのは、サイズが移動元と異なる移動先、または `File.Move` 自体が投げる例外（EACCES、EPERM、移動元の EROFS など）です。

`TransferFolder`（`:44-137`）は他のコードパスでも使われます。`:124-131` に注意してください。フォルダの Move 後に 100 MB を超えるファイルが残っている場合、移動元フォルダの削除を拒否します（`IOException("Large files still exist in {sourcePath} after folder move, not deleting source folder")`）。

---

## 6. 2 つのヘルスチェック {#6-the-two-health-checks}

### 6.1 `DownloadClientRootFolderCheck` — **Sonarr と Radarr が実際に異なる唯一の箇所** {#61-downloadclientrootfoldercheck--the-one-place-sonarr-and-radarr-genuinely-differ}

Sonarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = status.OutputRootFolders.Where(folder => rootFolders.Any(r => r.Path.PathEquals(folder.FullPath)));
```

Radarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = rootFolders.Where(r => status.OutputRootFolders.Any(folder => r.Path.PathEquals(folder.FullPath) || r.Path.IsParentPath(folder.FullPath)));
```

`IsParentPath` (`src/NzbDrone.Common/Extensions/PathExtensions.cs:123-140`) は、子から**上に向かって**たどっていきます:

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

つまり `r.Path.IsParentPath(folder.FullPath)` は、**ルートフォルダが出力フォルダの祖先になっている**とき、つまり出力フォルダがルートフォルダの*中*にあるときに true になります。これは厳密な祖先判定です(`child.Directory` から開始します)。同じパスかどうかは `PathEquals` で別に判定されます。

**述語の判定を直接まとめると:**

| 関係(出力フォルダ O とルートフォルダ R) | Sonarr | Radarr |
|---|---|---|
| O == R | **warn** | **warn** |
| O が R の中にある(R は O の祖先) | 警告なし | **warn** |
| O が R の親である(O は R の祖先) | 警告なし | **警告なし** |
| 無関係 | 警告なし | 警告なし |

`complete_dir = /mnt/zurg/__magic__/__all__` かつ `dir: ""` の場合(つまり `OutputRootFolders == ["/mnt/zurg/__magic__/__all__"]`)は次のようになります:

- Sonarr は、ルートフォルダがちょうど `/mnt/zurg/__magic__/__all__` のときだけ警告します。
- Radarr は、ルートフォルダが `/mnt/zurg/__magic__/__all__`、`/mnt/zurg/__magic__`、`/mnt/zurg`、`/mnt` のいずれかだと警告します。
- ルートフォルダが `/mnt/zurg/__magic__/tv` の場合は、どちらも警告しません。ミラーとルートフォルダは兄弟の関係で、無関係な組み合わせなので、どちらのルールも発動しないからです。出力フォルダの中にあるルートフォルダ(`/mnt/zurg/__magic__/__all__/anything`)も、ここでは警告されません。ただし、その深さには名前空間側がものを保存させないので、そもそもそうした配置は存在しえません。

`PathEquals`(`PathExtensions.cs:55-73`)は、Unicode を正規化し、`DiskProviderBase.PathStringComparison`(Windows では `OrdinalIgnoreCase`、それ以外では `Ordinal`。`src/NzbDrone.Common/Disk/DiskProviderBase.cs:17-23`)を使い、`CleanFilePath()` で再試行します(末尾のスラッシュは区別しません)。

どちらのバージョンも、`ProviderUpdatedEvent` / `ProviderDeletedEvent` / `ModelEvent<RootFolder>` / `ModelEvent<RemotePathMapping>` の発生時に再実行されます。Radarr は `:17` で `[CheckOn(typeof(ProviderAddedEvent<IDownloadClient>))]` も追加しています。結果は `HealthCheckResult.Warning` で、アンカーは `#downloads-in-root-folder` です。メッセージには、Sonarr では `folder.FullPath`、Radarr では `folder.Path` が埋め込まれます(どちらも `:60`)。両方とも `DownloadClientException` と `HttpRequestException` は黙って握りつぶし(デバッグログのみ)、それ以外の例外はエラーとしてログに残します。

### 6.2 `RemotePathMappingCheck` — ローカルクライアントのパス (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs`) {#62-remotepathmappingcheck--the-local-client-path-srcnzbdronecorehealthcheckchecksremotepathmappingcheckcs}

`:51-54` で早期リターンします。`EnableCompletedDownloadHandling` がオフの場合、このチェックは何もしません。

`client.GetStatus().OutputRootFolders` の各 `folder` について:

1. **`!folder.IsValid`** (`:68`): `OsPath.IsValid` = `_path.IsPathValid(PathValidationType.CurrentOs)` (`OsPath.cs:228`)。Windows 以外では、`path.StartsWith("/")` の確認と `Path.GetInvalidPathChars()` のスキャンに相当します (`PathExtensions.cs:143-182`, `:403-411`)。エラーは次の順に判定されます:
   - `!status.IsLocalhost` → `RemotePathMappingWrongOSPathHealthCheckMessage` (Radarr のキー: `RemotePathMappingCheckWrongOSPath`)、アンカー `#bad-remote-path-mapping`
   - `_osInfo.IsDocker` → …`BadDockerPath`、アンカー `#docker-bad-remote-path-mapping`
   - それ以外 → …`LocalWrongOSPath`、アンカー `#bad-download-client-settings`
2. **`!_diskProvider.FolderExists(folder.FullPath)`** (`:115`):
   - `_osInfo.IsDocker` → …`DockerFolderMissing`、`#docker-bad-remote-path-mapping`
   - `!status.IsLocalhost` → …`LocalFolderMissing`、`#bad-remote-path-mapping`
   - それ以外 → …`GenericPermissions`、`#permissions-error`

**ローカルのクライアント (`IsLocalhost` が true で Docker ではない) の場合、要件は実質この 2 つだけです。** 報告された出力ルートフォルダは、Sonarr/Radarr が動く OS にとっての絶対パスであること、そして Sonarr/Radarr のホスト上にディレクトリとして **存在すること** です。`/mnt/zurg/__magic__/__all__` は、エミュレーターからだけでなく、*arr のプロセスからも見えている必要があります。**ここには書き込み可能かどうかのチェックはありません。**

イベント駆動のオーバーロード (`:178-368`) は `EpisodeImportFailedEvent` (Radarr では `MovieImportFailedEvent`) で発火します。特に、失敗したダウンロードの `OutputPath` を探すために `client.GetItems()` をもう一度呼び出します (`:232`)。

出力フォルダが *書き込み可能* であることを要求するヘルスチェックはありません。`FolderWritable` (Sonarr は `DiskProviderBase.cs:126-143`、Radarr は `:127-144`) は `sonarr_write_test.txt` / `radarr_write_test.txt` を書き込んで削除しますが、これは `RootFolderService.Add` (Sonarr の `src/NzbDrone.Core/RootFolders/RootFolderService.cs:117-120`) と `DownloadClientBase.TestFolder` (`:167-187`) から使われています。そして **`TestFolder` は SAB クライアントからは一度も呼ばれません。**

## 7. Sonarr と Radarr — 完全な差分 {#7-sonarr-vs-radarr--the-complete-diff}

**Sonarr 版のコピーにだけ UTF-8 BOM が付いている以外は、バイト単位で同一でした**（そのため行番号も完全に一致します）:

`SabnzbdCategory.cs`（両方とも BOM なしで、本当に同一）、`SabnzbdDownloadStatus.cs`、
`SabnzbdPriority.cs`、`SabnzbdFullStatus.cs`、`SabnzbdJsonError.cs`、`SabnzbdQueue.cs`、
`SabnzbdQueueItem.cs`、`SabnzbdHistory.cs`、`SabnzbdHistoryItem.cs`、
`JsonConverters/*.cs`（3 つすべて）、`Responses/*.cs`（6 つすべて）、
`src/NzbDrone.Common/Disk/DiskTransferService.cs`、`src/NzbDrone.Core/Download/DownloadEventHub.cs`。

**`TvCategory` → `MovieCategory` と `RemoteEpisode` → `RemoteMovie` の名前変更だけが違うもの**（行数は変わらず、行番号も同じ）:

- `Sabnzbd.cs` — `:40-52`（`AddFromNzbFile`。Radarr の新しさの判定は `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie`、Sonarr は `remoteEpisode.IsRecentEpisode()`）、`:190`、`:251`、`:265/269/273`、`:458`、そして `TestCategory` 内のすべての `NzbDroneValidationFailure` のフィールド名（`"TvCategory"` → `"MovieCategory"`）。
- `SabnzbdProxy.cs` — `:50`、`:122-124`、`:138-140`。
- `SabnzbdSettings.cs` — デフォルト値は `TvCategory = "tv"` と `MovieCategory = "movies"`。`RecentTvPriority`/`OlderTvPriority` と `RecentMoviePriority`/`OlderMoviePriority`（どちらもデフォルトは `(int)SabnzbdPriority.Default`）。バリデーターはそれ以外同じです: `Host` が有効、`Port` は 1〜65535、`ApiKey` は username が空のときに必須、`Username`/`Password` は ApiKey が空のときに必須、カテゴリの `NotEmpty` は **警告**として扱われます。
- `UsenetClientBase.cs` — Radarr は、インデクサーから NZB を取得するときに `request.AllowAutoRedirect = true`（`:51`）も設定し、HTTP `410 Gone` を `404` と同じように扱います（`:63`）。**これはインデクサーの話で、SAB の話ではありません。**
- `DownloadClientBase.cs` — `TestFolder` の詳細テキスト内の、リテラルの "Sonarr"/"Radarr" だけ。
- `RemotePathMappingCheck.cs` — ローカライズキーの名前（`RemotePathMapping*HealthCheckMessage` と `RemotePathMappingCheck*`）、`EpisodeImportFailedEvent` と `MovieImportFailedEvent`、さらに Radarr 独自の `[CheckOn(ProviderAddedEvent<IDownloadClient>)]`。**判定ロジックは同一です。**
- `DiskProviderBase.cs` — `FolderWritable` のプローブファイルが `sonarr_write_test.txt` と `radarr_write_test.txt`（Sonarr は `:132`、Radarr は `:133`）。

**動作上の違いは、実質ひとつだけです:**

- **`DownloadClientRootFolderCheck.cs:51`。** Sonarr は `PathEquals` のときだけ警告しますが、Radarr は、ルートフォルダーが出力フォルダーの祖先にあたる場合も警告します。詳しい表は §6.1 にあります。

それ以外（モード、パラメーター、JSON の形、列挙型、コンバーター、`CheckForError`、`RemoveItem`、`DeleteItemData`、転送モード、`DiskTransferService`）はすべて同一です。**一つのエミュレーターで両方に対応できます。**

両方の設定のデフォルト値も同じです: `DownloadClientHistoryLimit = 60`、`RemoveCompletedDownloads = true`、`RemoveFailedDownloads = true`。

---

## 8. 最小限でも完全なサンプルペイロード {#8-minimal-but-complete-example-payloads}

前提: `complete_dir = /mnt/zurg/__magic__/__all__`。カテゴリは `*`、`tv`、`movies` で、いずれも `dir: ""` です。
すべてのレスポンスは **HTTP 200** で `Content-Type: application/json` です。

結果の `OutputRootFolders`: `dir: ""` ⇒ `FullPath == complete_dir` ⇒ `/mnt/zurg/__magic__/__all__`
Sonarr（カテゴリ `tv`）と Radarr（カテゴリ `movies`）の両方でこの値になります。

### 8.1 `mode=version`

```json
{
  "version": "4.3.3"
}
```

`major.minor.(patch|x)`の形式である必要があります。`4` ≥ 1 は `TestConnectionAndVersion`（`Sabnzbd.cs:389-392`）の条件を満たします；
≥ 2.0 であれば、`complete_dir` が相対パスだった場合に `GetCategories` が `queue.my_home` ではなく `fullstatus` を使うことも意味します
（実際にはそうではありません）。

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

各値の理由：

- `misc` はオブジェクトとして存在すること（**必須**）。ないと NRE（§3.4）。
- すべてのカテゴリに**文字列**の `dir` があること（**必須**）。ないと `Sabnzbd.cs:238` と `:462` で NRE。
- `dir` の末尾が `*` で**ない**こと。そうでないと「enable job folders」の警告が出ます（`Sabnzbd.cs:462-469`）。
- 3つすべての `enable_*_sorting: false`。これで `TestCategory` の警告（`Sabnzbd.cs:493-518`）と `DownloadClientSortingCheck` の両方が出なくなります。注意：`tv_categories: []` と `enable_tv_sorting: true` を組み合わせると**失敗**します。空のとき `ContainsCategory` は true を返すためです（`Sabnzbd.cs:525-528`、フィクスチャ `SabnzbdFixture.cs:647-656`）。
- `sorters: []`。`config.Sorters.Any(s => s.is_active && …)` が false になります（`Sabnzbd.cs:484`）。
- `pre_check: false`。`TestGlobalConfig` 内の `HasVersion(1,1)` の往復処理をスキップします（`Sabnzbd.cs:443`）。
- `history_retention_option: "all"`。`RemovesCompletedDownloads == false` になります（`Sabnzbd.cs:546-547`）。そのためヘルスチェックの警告は出ません。
- `complete_dir` が絶対パス。`IsRooted` が true になるので、`mode=fullstatus` と `queue.my_home` は参照されません（`Sabnzbd.cs:220`）。

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

読み取られるのは `completedir` だけです（`SabnzbdFullStatus.cs:9-10`）。ラッパーのキーは **必ず** `status` にしてください（`Responses/SabnzbdFullStatusResponse.cs:5`）。

### 8.4 `mode=addfile` のレスポンス {#84-modeaddfile-response}

```json
{
  "status": true,
  "nzo_ids": ["SABnzbd_nzo_abc12345"]
}
```

`nzo_ids` は **空ではない文字列の配列** でなければなりません (`Sabnzbd.cs:47-52`)。`status` は解析されています (`Responses/SabnzbdAddResponse.cs:13`) が、一度も読まれていません。`CheckForError` が `"True"` を見られるように、`true` のままにしておいてください。

### 8.5 `mode=queue&start=0&limit=0&category=tv` — Downloading のスロットが1つ {#85-modequeuestart0limit0categorytv--one-downloading-slot}

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

必須要件:

- トップレベルのキーは `queue` です (`SabnzbdProxy.cs:129`、`SelectToken("queue")`)。
- `slots[].status` は、16 個ある `SabnzbdDownloadStatus` の名前のどれかにしてください。大文字と小文字も完全に一致させる必要があります。
- `slots[].mb` と `mbleft` は **メガバイト** 単位で、小数点はインバリアントカルチャの形式にしてください。文字列でも数値でも大丈夫です (Newtonsoft が変換してくれます)。実際の SAB は文字列を返します。
- `slots[].timeleft` は必ず `h:m:s` か `d:h:m:s` の形式にしてください。`""` は絶対に入れないでください。
- `slots[].priority` は `"Normal"`、`"High"`、`"Low"`、`"Force"`、`"Paused"`、`"Default"` のどれか (大文字と小文字を区別します) か、対応する数値にしてください。**`null` は絶対に入れないでください** (NRE になります)。
- `slots[].cat` (`category` ではなく) は、クライアントに設定したカテゴリと一致させてください。一致しないと、`Sabnzbd.cs:190` でアイテムがフィルタリングされて消えてしまいます。
- `queue.paused` は、本当に一時停止したいとき以外は `false` にしてください。`true` にすると、`Force` 以外のすべてのスロットが ETA なしの Paused になります (`Sabnzbd.cs:78-84`)。

結果として得られる `DownloadClientItem` は次のようになります: `TotalSize = 1024 * 1024 * 1024`、`RemainingSize = 512 * 1024 * 1024`、`RemainingTime = 00:08:32`、`Status = Downloading`、`CanBeRemoved = CanMoveFiles = true`。

### 8.6 `mode=history&start=0&limit=60&category=tv` — Completed と Failed のスロットが1つずつ {#86-modehistorystart0limit60categorytv--one-completed-and-one-failed-slot}

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

必須要件:

- トップレベルのキー `history`（`SabnzbdProxy.cs:145`）。
- `slots[].bytes` は **BYTES**（JSON の数値 → `long`）です。ここで MB を送らないでください。キューは MB を使い、
  履歴は bytes を使います（`Sabnzbd.cs:72-73` と `:128`）。
- `slots[].category`（`cat` ではなく）。
- `slots[].storage` は、ジョブのフォルダそのものです。これが `OutputPath` になり、Completed のアイテムの場合は `DeleteItemData` が再帰的に削除する対象になります（§5.3）。Sonarr/Radarr が動作している OS で有効な絶対パスである必要があり、そこに存在している必要があります（`RemotePathMappingCheck`、§6.2）。
- `slots[].status` は大文字小文字を正確に一致させてください。`Deleted` のアイテムは完全に除外されます（`Sabnzbd.cs:116-119`）。
- `fail_message` が正確に `"Unpacking failed, write error or disk is full?"` の場合、Failed のアイテムは `Failed` ではなく `Warning` に格下げされます（`Sabnzbd.cs:140-144`）。本当の失敗の場合は、別のメッセージを使ってください。
- Radarr: `category` は `movies`（または設定されている値）である必要があり、`name` は映画として解析できるべきです。

### 8.7 エラーレスポンス (どのモードでも) {#87-error-response-any-mode}

```json
{
  "status": false,
  "error": "API Key Incorrect"
}
```

**HTTP 200。** `status` は boolean の `false` でも文字列の `"false"` でも構いません。どちらも `SabnzbdJsonError.Failed`（`SabnzbdJsonError.cs:10-11`）に当てはまります。クライアントは `DownloadClientException("Error response received from SABnzbd: API Key Incorrect")`（`SabnzbdProxy.cs:244`）を投げ、それを `TestAuthentication` が認識します（`Sabnzbd.cs:424`）。API キーが渡されていない場合は `"API Key Required"` を使います（`Sabnzbd.cs:429`）。それ以外の `error` 文字列はそのまま報告されますが、分類はされません。

---

## 9. 実装チェックリスト (12項目) {#9-implementation-checklist-12-points}

1. ルートは1つだけです: `GET|POST {UrlBase}/api`。`mode` で処理を振り分けます。**常に HTTP 200 を返し、常に JSON を返します。**
2. `version`、`get_config`、`queue`（読み取り + `name=delete`）、`history`（読み取り + `name=delete`）、`addfile`、`fullstatus` を実装します。`retry` は任意です（今は使われていないコードです）。`get_cats` は呼ばれることがありません。
3. 認証は `apikey=` **または** `ma_username=` + `ma_password=` のどちらでも受け付けてください。拒否するときは 200 と
   `{"status":false,"error":"API Key Incorrect"}` / `"API Key Required"` を返します。401 や 403 は決して返さないでください。
4. `queue` と `history` では `category=` に対応してください（クライアントも `Sabnzbd.cs:190` で、完全一致の文字列比較によってクライアント側でフィルタリングします）。
5. `queue` のサイズは **MB**（`mb`、`mbleft`）、`history` のサイズは **BYTES**（`bytes`）です。絶対に取り違えないでください。queue は `cat`、history は `category` を使います。
6. `timeleft` は必ず `h:m:s` か `d:h:m:s` の形式にしてください。空にしたり、空文字列として省略したりしてはいけません。日付フィールドはどこでも解析されないので、エポック系のフィールドは自由な形式で構いません。
7. `status` の値は、16 メンバーの `SabnzbdDownloadStatus` リストから、大文字と小文字を含めて完全に一致させてください（未知の名前は例外を投げて、queue/history の呼び出し全体を失敗させます）。`priority` は `SabnzbdPriority` の名前（大文字と小文字を含めて完全一致）か、その整数にしてください。**絶対に `null` にしないでください**（コンバーターで NRE になります）。
8. `config.misc` はオブジェクトでなければなりません。すべてのカテゴリは、`*` で終わらない **null ではない文字列の `dir`** を必ず持ってください。`categories`/`sorters`/`servers` は null でも省略されていても構いませんが、`misc` と `dir` はだめです。
9. `enable_tv_sorting`、`enable_movie_sorting`、`enable_date_sorting`、`pre_check` はすべて `false` のままにし、`history_retention_option: "all"` を設定してください。接続テストとすべてのヘルスチェックをエラーなしに保つためです。
10. Completed の history スロットの `storage` はジョブフォルダーです。*arr は（デフォルト設定では）インポートが成功した後にそれを `rm -rf` で削除すると考えてください。その前に、メディアファイルがそこから **移動** されることも想定してください。magic ディレクトリが読み取り専用だと削除は静かに失敗します（警告ログが出るだけです）。ただし、インポートされたファイルの *移動* は成功しなければなりません。失敗するとインポートも完全に失敗します（§5.5）。
11. Radarr の `DownloadClientRootFolderCheck` を静かに保ちたい場合は、*arr のルートフォルダーを `/mnt/zurg/__magic__/__all__` と同じか、その上の階層に置かないでください（Sonarr は完全一致のみを気にします）。代わりに、ミラーの横に置いてください（`/mnt/zurg/__magic__/tv`、`/mnt/zurg/__magic__/movies`）。これらは出力フォルダーの上にも下にもなく、無関係な場所です。
12. `/mnt/zurg/__magic__/__all__` は、エミュレーターが動いている場所だけでなく、**Sonarr/Radarr のホスト上に** ディレクトリとして存在している必要があります。そうしないと `RemotePathMappingCheck` がエラーを出します。書き込み可能である必要はありません。

(前回の翻訳は、コードスパンが一致しないため却下されました（`history_retention_option: "all"`）。構造はそのまま正確に保ってください。)

## 完了ウィンドウを大きくする {#configuring-a-larger-completion-window}

2つのクライアントはどちらも `DownloadClientHistoryLimit` の初期値が60です。zurgは完了したあぶれ分を `queue` に残すとき、この範囲に合わせます。クライアントの上限だけを増やすと、一部のジョブがキューと履歴の両方に表示されてしまい、その場合はキューが優先されます。

ジョブが大量にたまっている場合は、zurgの `sabnzbd.history_limit` と各クライアントの `DownloadClientHistoryLimit` を同じ値（たとえば500）に設定してください。そうすると、1回のポーリングで完了・失敗したジョブをより多く表示できます。複数のクライアントで異なる値を使っている場合は、zurgの値を最も小さいクライアント上限のままにしておきます。この詳細なクライアント設定は、Sonarr v4のダウンロードクライアント設定APIリソースでは公開されていません。保存されている設定を編集する前に、クライアントをバックアップして停止してください。

```yaml
sabnzbd:
  enabled: true
  history_limit: 500
```

初期値は60のままです。0や負の値を指定すると、この初期値が使われます。異なる上限を指定した診断用の履歴リクエストが、設定済みの表示範囲を変えることはありません。クライアントが解決できない警告は、引き続き確認が必要です。範囲を広げると、そうした警告が履歴の枠を使っている間も、他のジョブがインポートまで進めるようになります。

完了前の可用性チェックでは、各コンテンツファイルの先頭16記事と最後の記事をサンプリングします。これにより、以前の先頭記事のカナリア方式では見逃していたメディアヘッダー内の欠落記事を検出できます。チェックでは、各コンテンツファイルの先頭記事を転送して、記事の識別子と、本文がまだ提供されているかを確認します（プロバイダーが本文を削除していても、記事に対してSTATで応答することがあるためです）。さらに、ファイル数がその数に満たないリリースでは、ランダムに選んだ記事を最大16本文まで追加で取得します。全体では最大64本文までです。記事キャッシュにすでにある本文は、再度取得しません。残りのサンプルはSTATで確認します。すべての記事を検証するわけでも、メディアがデコードできることを証明するわけでもありません。

STATリクエストはファイルごとにまとめて送るため、サンプル全体で17回ではなく1回のプール予約で済みます。アカウントの接続数の上限は変わりません。まとめて送ったバッチが使えない場合は、個別のSTATに切り替えます。
サーバー側の障害では、ジョブはキューに残り再試行されます。欠落記事が確定した場合は、完了通知が出る前に失敗したダウンロードとして扱われます。
