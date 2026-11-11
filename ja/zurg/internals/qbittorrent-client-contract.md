# qBittorrent Web API の契約（Sonarr と Radarr から見た形、develop） {#qbittorrent-web-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Source of truth: files fetched from `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...`
and from `qbittorrent/qBittorrent/master` on **2026-08-27**. 以下のすべての行番号は、これらのファイルから読み取ったものです。

これは [sabnzbd-client-contract.md](sabnzbd-client-contract.md) の qBittorrent 版です。そちらは `internal/sabnzbd` がなぜそのような形式で応答するのかを記録したものです。この文書は、qBittorrent シムを書く前に満たすべき仕様です。これにより、grab、poll、**移動としての**インポート、インポート後のクリーンアップが、両方のクライアントで動作します。HTTP レイヤー、JSON シリアライザー、`DiskTransferService`、ヘルスチェックなど、2 つのクライアントで共通する部分については、この文書では同じ行を引用し、分析を繰り返さずに元の箇所を示します。

特に断りがない限り、**2 つのリポジトリの qBittorrent 関連ファイルは `Tv*` → `Movie*` の名前変更を除いて同一**であり、次のとおりです。

| File | Line numbers |
|---|---|
| `QBittorrent.cs` (両方とも 746 行) | **1 対 1 で一致** |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **バイト単位で同一**、1 対 1 で一致 |
| `QBittorrentSettings.cs` (両方とも 91 行) | 1 対 1 で一致 |
| `QBittorrentProxyV2.cs`, `QBittorrentProxyV1.cs` | Sonarr には 13 行目に空行がありますが、Radarr にはありません（確認済み：Sonarr の `:12` は `// API https://…` のコメント、`:13` は空行、`:14` は `public class QBittorrentProxyV2`。Radarr のクラス宣言は `:13`）。**N ≥ 14 の場合、Sonarr の N 行目 = Radarr の N−1 行目。** |
| `QBittorrentProxySelector.cs` | 3 行目以降は同じ |
| `QBittorrentFixture.cs` | 順序が入れ替わっているだけで、ずれはない。リポジトリごとに引用 |

パスは両方とも `src/NzbDrone.Core/Download/Clients/QBittorrent/...` です。以下の引用は、特に明記がない限り **Sonarr** の行番号です。完全な差分は §9 にあります。

ここに書かれているのは qBittorrent 自体についての推測ではありません。すべての記述は *クライアント* がどう動くかを示したものです。qBittorrent 自身の動作に関する記述は `qbittorrent/qBittorrent` master を引用し、.NET や Newtonsoft ランタイムの挙動に関する記述はその旨を明記します。

---

(An earlier translation was rejected: length ratio 0.14. Keep the structure exactly.)

（以前の翻訳は却下されました：長さの比率が 0.14 でした。構造はそのまま維持してください。）

## 0. 通信レベルのルール（最初にハマるところ） {#0-transport-level-rules-these-bite-first}

### 0.1 クライアントは何より先に v1 か v2 かを選ぶ {#01-the-client-picks-v1-or-v2-before-it-does-anything-else}

`QBittorrentProxySelector.FetchProxy`（`QBittorrentProxySelector.cs:80-95`）:

```csharp
if (_proxyV2.IsApiSupported(settings)) { return Tuple.Create(_proxyV2, _proxyV2.GetApiVersion(settings)); }
if (_proxyV1.IsApiSupported(settings)) { return Tuple.Create(_proxyV1, _proxyV1.GetApiVersion(settings)); }
throw new DownloadClientException("Unable to determine qBittorrent API version");
```

`QBittorrentProxyV2.IsApiSupported`（`QBittorrentProxyV2.cs:28-70`）は、**認証なし**で
`GET /api/v2/app/webapiVersion` を呼び出します。`SuppressHttpError = true` を指定し、次の表のように結果を判断します。

| 応答 | 結果 |
|---|---|
| `404` | v2 ではない → v1 にフォールバック |
| `403` | **v2 対応**（`:44-47`）。これは「まだログインしていない」という応答です |
| `401` | `DownloadClientException("Failed to connect to qBittorrent. Check your settings and qBittorrent configuration.")`（`:49-52`） |
| それ以外の `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")`（`:54-57`） |
| `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to qBittorrent, certificate validation failed.")`（`:63-66`） |
| `200` | v2 対応 |

`QBittorrentProxyV1.IsApiSupported`（`QBittorrentProxyV1.cs:27-59`）も同じことを `GET /version/api` に対して行います。ただし、**先頭の `/api/v2` はありません**。また、401 は *特別扱いされていません*。

`(proxy, version)` の組は、`{Host}_{Port}` をキーにして **10 分間** キャッシュされます（`QBittorrentProxySelector.cs:68-78`）。`GetProxy(settings, force: true)` でこれを削除します。接続テストもまさにそれを行っており（`QBittorrent.cs:435`, `:519`）、フィクスチャでもそれが検証されています（Sonarr `QBittorrentFixture.cs:986-998`, Radarr `:984-996`）。

**shim は `/api/v2/app/webapiVersion` に応答し、v1 のルートは決して公開しないようにしてください。** v1 は 4.1 より前の API（`/version/api`, `/query/torrents`, `/command/download`, …）です。新しい実装には不要で、インポートの処理にはまったく対応できません。`GetLabels` が `NotSupportedException("qBittorrent api v1 does not support getting all torrent categories")` を投げ（`QBittorrentProxyV1.cs:236-239`）、`SetTorrentSeedingConfiguration` は何もしない no-op だからです（`:241-244`）。

このドキュメントの残りは API v2 のみを扱います。§1.17 に、参考として v1 のルートマップを載せています。

### 0.2 URL の形 {#02-url-shape}

`QBittorrentProxyV2.BuildRequest`（`QBittorrentProxyV2.cs:341-359`）：

```csharp
var requestBuilder = new HttpRequestBuilder(settings.UseSsl, settings.Host, settings.Port, settings.UrlBase)
{
    LogResponseContent = true,
    StoreRequestCookie = false
};
```

- ベースURL: `HttpRequestBuilder.BuildBaseUrl`（`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-65`）
  = `{http|https}://{Host}:{Port}{UrlBase}`。`UrlBase` に先頭の `/` がない場合は、自動で付きます。
- `Resource("/api/v2/…")`（`HttpRequestBuilder.cs:244-256`）は先頭の `/` を取り除いてから追加します。
  そのため、完全なURLは `{scheme}://{host}:{port}{urlBase}/api/v2/{group}/{method}` になります。
- **`Accept` ヘッダーはありません。** `BuildRequest` は `.Accept(...)` を一度も呼ばず、`HttpRequest` のコンストラクターは `httpAccept != null` の場合にだけ `Headers.Accept` を設定します（`src/NzbDrone.Common/Http/HttpRequest.cs:14,30-32`）。`Accept` の有無で処理を分けないでください。
- `StoreRequestCookie = false`: cookie の保管はHTTP層ではなく、プロキシ側で管理されます。

### 0.3 GET（クエリ）と POST（フォーム）、そしてフォームがマルチパートになるとき {#03-get-with-query-vs-post-with-form--and-when-the-form-becomes-multipart}

読み取り専用の呼び出しは、GET に対して `AddQueryParam`（`HttpRequestBuilder.cs:306-317`）を使います。変更を伴う呼び出しは
`.Post()` と `AddFormParameter` / `AddFormUpload` を使います。

`ApplyFormData`（`HttpRequestBuilder.cs:150-242`）がエンコーディングを選びます:

```csharp
var shouldSendAsMultipart = FormData.Any(v => v.ContentType != null || v.FileName != null || v.ContentData.Length > 1024);
```

- `AddFormUpload` を使うと（`FileName` と `ContentType` が設定されます）、必ず **`multipart/form-data`** になります
  （`:379-395`、`:220`）。
- **1024 バイトを超えるフォーム値が1つでもあると、これも multipart になります**（`:162`）。トラッカーがたくさん入った長いマグネット URI はこの境界を超えるため、`POST /api/v2/torrents/add` は、マグネットの内容に応じて `application/x-www-form-urlencoded` *または* `multipart/form-data` で届きます。
  **このルートではシムが両方を解析できる必要があります。**
- それ以外の場合は `application/x-www-form-urlencoded` になり、値は `Uri.EscapeDataString(Encoding.UTF8.GetString(...))`（`:230`）でエスケープされます。

multipart ライターは自前実装です（`:164-227`）。`Content-Disposition: form-data; name="…"` を書き（アップロードの場合は `; filename="…"` と `Content-Type:` 行も加えます）、空行、生のバイト列、最後に `\r\n` を書きます。境界は `-----------------------------{ticks:x14}`（`:166`）です。

**真偽値の書式は落とし穴です。** `AddFormParameter` は `Convert.ToString(value, CultureInfo.InvariantCulture)`（`HttpRequestBuilder.cs:373`）を保存しますが、.NET の `Convert.ToString(bool)` は **`"True"` / `"False"`**（先頭大文字）を返します。そのため `request.AddFormParameter("stopped", false)`（`QBittorrentProxyV2.cs:258`）は、`stopped=false` ではなく `stopped=False` として送信されます。実際の qBittorrent は `Utils::String::parseBool`（`src/base/utils/string.cpp:108-116`）が大文字小文字を区別せず比較するので問題ありません。**シムは `true`/`false` だけでなく `True`/`False` も受け付ける必要があります。** クライアント側で文字列を直接固定している箇所は小文字です。`deleteFiles` は `"true"`（`QBittorrentProxyV2.cs:198`）、`setForceStart` の `value` は `"true"`/`"false"`（`:337`）なので、両方の表記が実際に出てきます。

数値も同じインバリアントカルチャの経路を通るため、`ratioLimit=1.5` は常に `.` を小数点として使います（`QBittorrentProxyV2.cs:234`、`HttpRequestBuilder.cs:373`）。

### 0.4 認証 — 3 つの層があり、同時に有効になりうる {#04-authentication--three-layers-all-of-which-can-be-live-at-once}

`BuildRequest`（`QBittorrentProxyV2.cs:349-356`）:

```csharp
if (settings.ApiKey.IsNotNullOrWhiteSpace())
    requestBuilder.Headers["Authorization"] = $"Bearer {settings.ApiKey}";
else if (settings.Username.IsNotNullOrWhiteSpace() || settings.Password.IsNotNullOrWhiteSpace())
    requestBuilder.NetworkCredential = new BasicNetworkCredential(settings.Username, settings.Password);
```

1. **API key** → すべてのリクエストに `Authorization: Bearer <key>` を付けます。`ProcessRequest` にはログインしない近道があります（`:371-395`）。`QBittorrentSettingsValidator` は、API key と一緒に username/password を設定することを禁止しています（`QBittorrentSettings.cs:16-21`）。
2. **Username/password** → `BasicNetworkCredential` を使います。`ManagedHttpDispatcher` がこれを**先回りの** `Authorization: Basic base64(user:pass)` ヘッダーに変えて、`auth/login` を含むすべてのリクエストに付けます（`src/NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:81-89`。コメントには "Manually set header to avoid initial challenge response" とあります）。
3. **Cookie session** → `AuthenticateClient` を使います（`QBittorrentProxyV2.cs:430-494`）。

`AuthenticateClient` の中身はこうです:

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

shim を作るときの注意点です:

- `POST /api/v2/auth/login` を受け付けます。ボディは `username=…&password=…` で、`application/x-www-form-urlencoded` です。
- 成功したら、**HTTP 200** とボディ `Ok.` を返し、`Set-Cookie: SID=…` ヘッダーも付けます。本物の qBittorrent も同じ形で返します（wiki の *Login* には "Upon success, the response will contain a cookie with your SID" と書かれています）。
- **空のボディも受け付けます**（`:479` で `IsNotNullOrWhiteSpace` を見て抜けます）。それ以外、たとえば `"Fails."`、`"ok"`、JSON などは認証失敗になります。v1 proxy はもっと厳しく、`Ok.` と完全一致することを求めます（`QBittorrentProxyV1.cs:371`）。
- `auth/login` が HTTP エラーを返したときは、401 または 403 なら `DownloadClientAuthenticationException`、それ以外なら `DownloadClientException` になります（`:463-473`）。`WebException` の場合は `DownloadClientUnavailableException` です。
- Cookie は `{baseUrl}:{user}:{pass}` ごとにキャッシュされます。キャッシュエントリが生きている間はずっと使われ、リクエストが 403 で返ってきたときだけ更新されます（§0.5）。
- **`Referer` と `Origin` は送られません。** wiki では API を使う側に設定するよう書かれています（"Note: Set `Referer` or `Origin` header to the exact same domain and port as used in the HTTP query `Host` header"）。でも Sonarr は設定しません。shim はこれらを必須にしてはいけません。
- 認証情報が**まったく設定されていない**場合、`AuthenticateClient` はすぐに戻ります。ログインも Cookie も `Authorization` も何も送られません。認証なしの shim でも動きます。

### 0.5 どの HTTP ステータスをエラーとして扱うか {#05-which-http-statuses-are-treated-as-errors}

`HttpClient.Execute`（`src/NzbDrone.Common/Http/HttpClient.cs:106-121`）は、`response.HasHttpError`（`(int)StatusCode >= 400`、`src/NzbDrone.Common/Http/HttpResponse.cs:54`）が真になると例外を投げます。ただし、`SuppressHttpError` が設定されているか、ステータスが `SuppressHttpErrorStatusCodes` に入っている場合は投げません。429 の場合は `TooManyRequestsException`（`:115`）になり、それ以外は `HttpException`（`:119`）になります。

`QBittorrentProxyV2.ProcessRequest`（`:369-428`）がその例外を包みます。経路は2つあります。

**APIキーの経路**（`:371-395`）:

| ステータス | 結果 |
|---|---|
| 401, 403 | `DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.")` |
| それ以外の `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` |
| それ以外で例外が投げられた場合 | `DownloadClientException("Failed to connect to qBittorrent, please check your settings.")` |

**Cookieの経路**（`:397-427`）:

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

- **403 は「セッションが切れたので、もう一度ログインして」という意味です。** 1回だけ抑制されて、クライアントが再ログインしてリクエストをやり直します。qBittorrent 自身のセッション期限切れでも同じループが起きるので、シムでも同じ方法を使えます。
- **再試行のリクエストはビルダーから作り直されます。** ビルダーには `SuppressHttpErrorStatusCodes` が入っていません。このフィールドは `:401` でビルダーではなく*リクエスト*に設定されていたからです。そのため、2回目の 403 は `HttpException` を投げ、`DownloadClientException("Failed to connect to qBittorrent, check your settings.")` として表に出ます。認証失敗ではありません。いつまでも 403 を返すシムだと、UIには "Authentication Failure" ではなく、わかりにくい接続エラーが表示されます。
- 認証情報が設定されていない場合、`:411` の再ログイン試行が `:434-437` で即座に `DownloadClientAuthenticationException` を投げます。

**成功した呼び出しはすべて HTTP 200 で、クライアントが期待する正確なボディを返す必要があります。** この API には JSON のエラーエンベロープがどこにもありません。SAB と違って、ここでのエラーはすべて HTTP ステータスで表されます。

### 0.6 デシリアライザの設定 {#06-deserializer-settings}

qBittorrent のペイロードはすべて `NzbDrone.Common.Serializer.Json`（`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`）を通ります。これは **Newtonsoft** で、SAB クライアントと同じインスタンスです。そのため [sabnzbd-client-contract.md §0.3](sabnzbd-client-contract.md) の内容がそのまま当てはまります:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

qBittorrent のモデルにとって、これは具体的に次の意味を持ちます:

| モデルのメンバー | バインド先 | 理由 |
|---|---|---|
| `QBittorrentTorrent.Hash/Name/Size/Progress/Eta/State/Label/Category/Ratio` | `hash`, `name`, `size`, `progress`, `eta`, `state`, `label`, `category`, `ratio` | camelCase リゾルバーを使用。Newtonsoft は大文字小文字を区別せずにも一致させます |
| `SavePath`, `ContentPath`, `RatioLimit`, `SeedingTime`, `SeedingTimeLimit`, `InactiveSeedingTimeLimit`, `LastActivity` | `save_path`, `content_path`, `ratio_limit`, `seeding_time`, `seeding_time_limit`, `inactive_seeding_time_limit`, `last_activity` | 明示的な `[JsonProperty]`（`QBittorrentTorrent.cs:24-45`） |
| `QBittorrentLabel.Name/SavePath` | `name`, `savePath` | **`[JsonProperty]` なし** — camelCase リゾルバー。qBittorrent の `torrents/categories` は、ほかと違ってここだけ本当に camelCase を使います |
| `QBittorrentPreferences.*` | すべて明示的な `[JsonProperty]` の snake_case（`QBittorrentPreferences.cs:16-44`） | |
| `QBittorrentMaxRatioAction` | `max_ratio_act` | プロパティごとのコンバーターはないため、グローバルの `StringEnumConverter` が適用されます。`AllowIntegerValues` は既定で true なので、本物の qBittorrent と同じく **整数を送ってください**。文字列にする場合は camelCase（`"pause"`、`"remove"`）である必要があり、知らない名前だと例外が投げられます |

`NullValueHandling.Ignore` は**読み取り時**にも適用されます。JSON の `null` が来ると、メンバーはコンストラクターで設定された値のまま残ります。モデルで宣言された既定値と組み合わさるため、**欠けているフィールド、または null のフィールド**は、0 と同じではありません:

| フィールド | 省略時/null の既定値 | 出典 |
|---|---|---|
| `ratio_limit` | `-2f` | `QBittorrentTorrent.cs:33` |
| `seeding_time_limit` | `-2` | `:39` |
| `inactive_seeding_time_limit` | `-2` | `:42` |
| `seeding_time` | `null`（`long?`） | `:36` |
| `queueing_enabled` | **`true`** | `QBittorrentPreferences.cs:41` |
| それ以外すべて | CLR の既定値（`0`、`false`、`null`） | |

`Eta` は `System.Numerics.BigInteger` です（`QBittorrentTorrent.cs:17`、コメントには "QBit contains a bug exceeding ulong limits" とあります）。Sonarr のフィクスチャでは `18446744073709335000` が解析可能であることを固定しています（Sonarr `QBittorrentFixture.cs:974-984`、Radarr `:973-982`）。

`Json.Deserialize<T>` は、もっとわかりやすいメッセージを付けて `JsonReaderException` を投げ直します（`Json.cs:39-50`）。qBittorrent のプロキシ呼び出しはどれも `TryDeserialize` を使っていないので、**形式が不正な本文、または形の違う本文はプロキシの外へ例外として投げられ**、呼び出し元で未処理の例外になります。`GetItems()` の場合、これでポーリング全体が止まってしまいます。

### 0.7 すべての `version >=` 判定をひとまとめに {#07-every-version--gate-in-one-place}

`ProxyApiVersion` は `_proxySelector.GetApiVersion(Settings)`（`QBittorrent.cs:50`）の値、つまりキャッシュされた `app/webapiVersion` です。判定箇所は次のとおりです。

| Gate | Where | 閾値未満のときの動作 |
|---|---|---|
| `>= 1.5` | `QBittorrent.cs:436` | テストが失敗する: "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| `>= 1.6` | `:445` | カテゴリが設定されている場合、テストが失敗する: "Category is not supported" |
| `>= 2.0` | `:379`（`GetStatus`）、`:520`（`TestCategory`） | カテゴリの `savePath` が読み込まれず、カテゴリのチェックも作成も行われない |
| `>= 2.6.1` | `:314` | `OutputPath` は `content_path` から取得されない。代わりに `GetImportItem` が `torrents/files` をたどる（§4.2） |
| `>= 2.8.1` | `:79`、`:136` | シェア制限を `torrents/add` に載せられない。代わりに `torrents/setShareLimits` で後から適用される |
| `>= 2.11.0` | `QBittorrentProxyV2.cs:253` | `torrents/add` が `stopped=` ではなく `paused=` を送る |

`Version.Parse`（`QBittorrentProxyV2.cs:75`）は少なくとも `major.minor` の形式を必要とします。`"2"` のような値だと `FormatException` が投げられます。しかもこの例外はプロキシ内のどの `try` の外で発生するため、`GetApiVersion` の外まで漏れてしまいます。`2.11.2` のような値を報告してください。

**shim 向けの推奨値: `2.11.2`**。これならすべての判定をクリアできます。`content_path` が `torrents/info` の経路に乗り（インポートにはこの経路が唯一まともです）、追加時には qBittorrent 5.x の `stopped=` の書き方が選ばれます。

---

## 1. クライアントが呼び出す順番どおりの全エンドポイント {#1-every-endpoint-in-the-order-the-client-calls-them}

インターフェース: `IQBittorrentProxy` (`QBittorrentProxySelector.cs:9-30`)。実装:
`QBittorrentProxyV2`。`QBittorrent.cs` 内のすべての呼び出し箇所は `:49-741` に載っています。

### 1.1 `GET /api/v2/app/webapiVersion` — `GetApiVersion`（`QBittorrentProxyV2.cs:72-78`） {#11-get-apiv2appwebapiversion--getapiversion-qbittorrentproxyv2cs72-78}

リクエストはパラメーターなしです。まず認証なしで送信し（プローブ、§0.1）、その後に認証ありで送信します。

レスポンスは**プレーンテキスト**で、`Version.Parse` で解析されるバージョン文字列です。JSON ではなく、引用符もありません。

呼び出し元: プロキシのプローブ（`:31`）、`GetItems`（`QBittorrent.cs:220`）、`GetStatus`（`:374`）、
`TestConnection`（`:435`）、`TestCategory`（`:519`）、そして見落としやすいのが
`AddTorrentDownloadFormParameters`（`QBittorrentProxyV2.cs:253`）です。つまり、初期状態が Start または Stop の場合（ユーザーが Force Start を選んでいない限り、ほぼ常に）、**`torrents/add` のたびに、その前に必ず独自の `app/webapiVersion` のラウンドトリップが1回入る**ということです。

### 1.2 `GET /api/v2/app/version` — `GetVersion`（`QBittorrentProxyV2.cs:80-87`） {#12-get-apiv2appversion--getversion-qbittorrentproxyv2cs80-87}

レスポンスはプレーンテキストで、先頭の `v` は取り除きます (`:83`)。コメント: `// eg "4.2alpha"`。

**一度も呼ばれていません。** インターフェース (`QBittorrentProxySelector.cs:13`) に定義されていますが、`QBittorrent.cs` のどこからも呼び出されていません (`:49-741` の `Proxy.` / `_proxySelector.` の参照をすべて確認済み)。それでも実装しておきましょう。コストはかからないし、シムをいじる人は必ずこれを使おうとするので。

### 1.3 `POST /api/v2/auth/login`

§0.4 で説明しています。フォームは `username` と `password`。レスポンスは `200` と `Ok.`、それに `Set-Cookie: SID=…` が返ってきます。

### 1.4 `GET /api/v2/app/preferences` — `GetConfig`（`QBittorrentProxyV2.cs:89-95`） {#14-get-apiv2apppreferences--getconfig-qbittorrentproxyv2cs89-95}

リクエスト: パラメータはありません。レスポンス: 1 つの JSON オブジェクトで、`QBittorrentPreferences` にデシリアライズされます。

**クライアントが読み取るキーはすべて**（`QBittorrentPreferences.cs:14-45`）。ボディにある他の内容は参照されず、余分なキーは無視されます:

| JSON キー | C# | 型 | 読み取り元 |
|---|---|---|---|
| `save_path` | `SavePath` | `string` | `GetStatus` → `OutputRootFolders`（`QBittorrent.cs:377`） |
| `max_ratio_enabled` | `MaxRatioEnabled` | `bool` | `HasReachedSeedLimit`（`:639`）、`RemovesCompletedDownloads`（`:415`） |
| `max_ratio` | `MaxRatio` | `float` | `HasReachedSeedLimit`（`:641`） |
| `max_seeding_time_enabled` | `MaxSeedingTimeEnabled` | `bool` | `HasReachedSeedingTimeLimit`（`:663`）、`RemovesCompletedDownloads`（`:415`） |
| `max_seeding_time` | `MaxSeedingTime` | `long`、**分** | `:665`、`:415` |
| `max_inactive_seeding_time_enabled` | `MaxInactiveSeedingTimeEnabled` | `bool` | `HasReachedInactiveSeedingTimeLimit`（`:727`） |
| `max_inactive_seeding_time` | `MaxInactiveSeedingTime` | `long`、**分** | `:729` |
| `max_ratio_act` | `MaxRatioAction` | int で表した enum: `Pause=0, Remove=1, EnableSuperSeeding=2, DeleteFiles=3`（`QBittorrentPreferences.cs:5-11`） | `RemovesCompletedDownloads`（`:415`） |
| `queueing_enabled` | `QueueingEnabled` | `bool`、**既定値は `true`** | `TestPrioritySupport`（`:572`） |
| `dht` | `DhtEnabled` | `bool` | `AddFromMagnetLink`（`:73`）、`metaDL` の分岐（`:288`） |

呼び出し元: `AddFromMagnetLink`（`:73`）、`GetItems`（`:221`）、`GetStatus`（`:375`）、`TestConnection`（`:467`）、`TestPrioritySupport`（`:570`）。キャッシュは **されません**。そのため、ポーリングのたびに取得されます。

`RemovesCompletedDownloads`（`QBittorrent.cs:412-416`）は派生フラグです:

```csharp
var minimumRetention = 60 * 24 * 14; // 14 days in minutes
return (config.MaxRatioEnabled || (config.MaxSeedingTimeEnabled && config.MaxSeedingTime < minimumRetention))
    && (config.MaxRatioAction == QBittorrentMaxRatioAction.Remove || config.MaxRatioAction == QBittorrentMaxRatioAction.DeleteFiles);
```

このフラグは接続テスト（`:468`）と `DownloadClientRemovesCompletedDownloadsCheck` ヘルスチェック（`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:44-53`）の両方に使われます。`max_ratio_enabled: false` かつ `max_seeding_time_enabled: false` の場合は、`max_ratio_act` の値に関係なく false になります。とはいえ、`max_ratio_act: 0` は送っておいてください。

（以前の翻訳は却下されました: 長さの比率 0.09。構造はそのまま維持してください。）

### 1.5 `GET /api/v2/torrents/categories` — `GetLabels`（`QBittorrentProxyV2.cs:221-225`） {#15-get-apiv2torrentscategories--getlabels-qbittorrentproxyv2cs221-225}

リクエスト: パラメータなし。

レスポンス: JSON の**オブジェクト**。`{"<name>": {"name": "...", "savePath": "..."}}` の形で、`Dictionary<string, QBittorrentLabel>` にデシリアライズされます。**camelCase の `savePath`** になる点に注意してください（§0.6 と wiki の *Get all categories* の例を参照）。ここで配列を返すと例外になります。

確認すべき点は2つです:

1. `TestCategory`（`QBittorrent.cs:525-553`）— キーの所属確認だけを見ます（§6.3）。
2. `GetStatus`（`:379-402`）— 設定されたカテゴリの `savePath` が、ダウンロードクライアントの出力ルートフォルダになります:

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

**相対パス**の `savePath` はグローバルの `save_path` に追加されます。ルートから始まる（絶対）パスの場合は、それで置き換えられます。`//` で始まる `savePath` はバックスラッシュの UNC パスに変換されます。Sonarr のフィクスチャでは `"//server/store/downloads"` が `\\server\store\downloads` になることが固定されています（Sonarr `QBittorrentFixture.cs:563-589`、Radarr `:562-588`）。**先頭に `//` を出力しないでください。** 一番シンプルで正しい答えは `"savePath": ""` です。これでルートフォルダはグローバルの `save_path` のままになります。

### 1.6 `POST /api/v2/torrents/createCategory` — `AddLabel`（`QBittorrentProxyV2.cs:213-219`） {#16-post-apiv2torrentscreatecategory--addlabel-qbittorrentproxyv2cs213-219}

フォーム: `category=<name>`。**`savePath` は送信されません**。クライアントがカテゴリの保存パスを設定することはありません。

レスポンスの本文は無視されます。見るのはエラーではないステータスだけです。

`TestCategory`（`QBittorrent.cs:529`、`:543`）からのみ呼ばれ、カテゴリが存在しないときに実行されます。
`torrents/editCategory` と `torrents/removeCategories` は**一度も呼ばれません**。

### 1.7 `POST /api/v2/torrents/add` — `AddTorrentFromUrl` / `AddTorrentFromFile`

`AddTorrentFromUrl` (`QBittorrentProxyV2.cs:146-166`): フォームフィールド **`urls`** には magnet URI を入れます。
`AddTorrentFromFile` (`:168-188`): フォームのアップロード **`torrents`**。ファイル名は
`{CleanFileName(release title)}.torrent` (`TorrentClientBase.cs:199`)、
`Content-Type: application/octet-stream` (`HttpRequestBuilder.cs:379`) です。

どちらの場合も、そのあとに `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:243-284`) が次のフォームパラメータを追加します:

| フォームフィールド | 値 | 条件 | 行 |
|---|---|---|---|
| `category` | `Settings.TvCategory` / `MovieCategory` | category が空白でない | `:245-248` |
| `stopped` (webapi `>= 2.11.0`) または `paused` (それより前) | Start なら `False`、Stop なら `True` | `InitialState` が Start または Stop の場合。**Force Start では どちらも送りません** | `:251-264` |
| `sequentialDownload` | `True` | `SequentialOrder` 設定がオン | `:266-269` |
| `firstLastPiecePrio` | `True` | `FirstAndLast` 設定がオン | `:271-274` |
| `contentLayout` | `"Original"` または `"Subfolder"` | `ContentLayout` 設定が Original または Subfolder の場合。**Default では何も送りません** | `:276-283` |

さらに、シェア制限が設定されていて *かつ* webapi が `>= 2.8.1` (`QBittorrent.cs:79`、`:136`) の場合は、`AddTorrentSeedingFormParameters(request, seedConfiguration)` (`QBittorrentProxyV2.cs:227-241`) も呼ばれ、次を追加します:

| フォームフィールド | 値 | 条件 |
|---|---|---|
| `ratioLimit` | `seedConfiguration.Ratio` または `-2` | `-2` でない場合のみ (`:232`) |
| `seedingTimeLimit` | `seedConfiguration.SeedTime.TotalMinutes` または `-2` | `-2` でない場合のみ (`:237`) |

**wiki に `torrents/add` として書かれているそれ以外のものは、一切送信されません**: `savepath`、`cookie`、`tags`、`skip_checking`、`root_folder`、`rename`、`upLimit`、`dlLimit`、`autoTMM` はどれも送られません。add には `priority` パラメータもありません。キューの優先度は、別の `topPrio` 呼び出しで設定します (§1.10)。

レスポンスの扱い (`:159-165`、`:181-187`):

```csharp
var result = ProcessRequest(request, settings);
// Note: Older qbit versions returned nothing, so we can't do != "Ok." here.
if (result == "Fails.") { throw new DownloadClientException("Download client failed to add torrent by url"); }
```

つまり、**`Fails.` という文字列以外のボディを持つ 200 は成功扱いです。** 慣例としての応答は `Ok.` です。HTTP 415 (wiki の「torrent file is not valid」) は `:389` を経由して `DownloadClientException` になります。

**ダウンロード ID はこの呼び出しからは得られません。** リクエストの前に、クライアント側で計算されます:

- magnet → `MagnetLink.Parse(magnetUrl).InfoHash.ToHex()` (`TorrentClientBase.cs:224`)
- `.torrent` → `_torrentFileInfoReader.GetHashFromTorrentFile(torrentFile)` (`:200`)

`AddFromMagnetLink` と `AddFromTorrentFile` は、その同じ `hash` をそのまま返します (`QBittorrent.cs:130`、`:187`)。**シムは、必ずその infohash でトレントを管理しなければなりません。** さもないと Sonarr が grab を追跡できなくなります。`TorrentClientBase.cs:206-212` と `:238-244` は、この点について Debug 行を出力するだけです。magnet の場合は、まず DHT の前提条件がチェックされます:

```csharp
if (!Proxy.GetConfig(Settings).DhtEnabled && !magnetLink.Contains("&tr="))
    throw new NotSupportedException("Magnet Links without trackers not supported if DHT is disabled");   // :73-76
```

これが失敗し、`.torrent` のフォールバックがない場合は、呼び出し元がそれを `ReleaseDownloadException("Magnet not supported by download client…")` に変換します (`TorrentClientBase.cs:111-119`)。**`dht: true` を返してください。**

追加のあと、`WaitForTorrent` (`QBittorrent.cs:190-214`) は `IsTorrentLoaded` を **100 ms の sleep を挟んで 10 回** ポーリングします。ただしこれは、後続の作業 (追加後のシェア制限、top priority、force start) がある場合に限ります (`:86`、`:143`)。その失敗メッセージは「within 500 ms」と書いていますが、実際のループは 10 × 100 ms です。どちらにしても、最終的には諦めて hash を返します (`:212-213`)。

### 1.7a クライアントが `torrents/add` を待つ時間 — **100 秒**（2026-08-30 に計測） {#17a-how-long-the-client-waits-for-torrentsadd--100-seconds-measured-2026-08-30}

2026-08-30 時点で、`develop` ブランチの `Sonarr/Sonarr@32a5d492` と `Radarr/Radarr@40bb746c` を読んで確認しました。shim が add 呼び出しの中で同期的に行う処理の上限を決めるので、推測せず根拠を示しておく価値があります。

qBittorrent の経路ではタイムアウトが設定されていないため、値は 4 つの層を順にたどり、最終的に固定の 100 秒になります。

| 手順 | Sonarr `path:line` | Radarr `path:line` | 内容 |
|---|---|---|---|
| 追加呼び出し | `QBittorrentProxyV2.cs:146-150`, `:168-172` | `:145-149`, `:167-171` | リクエストを組み立てるが、タイムアウトは設定しない |
| ビルダー | `NzbDrone.Common/Http/HttpRequestBuilder.cs:104-116` | 同じファイル `:104-116` | `Apply()` に `RequestTimeout` の行がなく、クラスにもそのプロパティがない |
| フィールドの既定値 | `NzbDrone.Common/Http/HttpRequest.cs:52` | `:54` | 自動プロパティがコンストラクタで代入されないため `TimeSpan.Zero` |
| ディスパッチャー | `NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:70-79` | `:68-77` | `Zero` は `cts.CancelAfter(TimeSpan.FromSeconds(100))` になる |

```csharp
using var cts = new CancellationTokenSource();
if (request.RequestTimeout != TimeSpan.Zero) { cts.CancelAfter(request.RequestTimeout); }
else { /* The default for System.Net.Http.HttpClient */ cts.CancelAfter(TimeSpan.FromSeconds(100)); }
```

両リポジトリの `src/NzbDrone.Core/Download/Clients/QBittorrent/` 以下には `RequestTimeout` も `Timeout` も一切出てきません。また `HttpRequestBuilder` にはそれを設定する手段がないため、shim は設定でより長い時間をもらうことができません。

以上から次の 5 点が言えます。

- **100 秒は .NET のタイマーではなく、Sonarr 独自のキャンセルトークンによるものです。** 下層のハンドラーは `Timeout = Timeout.InfiniteTimeSpan`（Sonarr は `ManagedHttpDispatcher.cs:183`、Radarr は `:180`）で作られているため、上限はこのトークンだけです。トークンは `SendAsync` と `ReadAsByteArrayAsync`（`:115`、`:127`）の両方に渡されるので、接続、リクエスト本文、レスポンスヘッダー、レスポンス本文のすべてが対象になります。
- **タイムアウトはユーザーには接続エラーとして報告されます。** 時間切れになると `new WebException("Http request timed out", …)`（`:142-145`）が発生し、それを `ProcessRequest` が `DownloadClientException("Failed to connect to qBittorrent, please check your settings.", ex)`（`QBittorrentProxyV2.cs:424-427`）で包みます。そのため、100 秒を超えてブロックする shim は、遅いのではなく設定ミスのように見えます。そして *arr は、追加がまだ処理中だったことを知ることができません。
- **接続タイムアウトは別に用意されておらず、マルチパートアップロード用に大きな時間枠もありません。** `SocketsHttpHandler.ConnectTimeout` は設定されていません。例外は、プロセスの生存期間中で最初の IPv6 接続試行に対する 2 秒の上限（`ManagedHttpDispatcher.cs:23`、`:288-295`）だけです。この場合は同じ 100 秒の中で IPv4 にフォールバックします。`.torrent` のアップロードはバイト配列に丸ごとバッファされ（`HttpRequestBuilder.cs:220-221`、`ManagedHttpDispatcher.cs:103`）、同じトークンで送信されます。
- **300 秒という値は存在しますが、別の経路で使われます。** `HttpClient.cs:285` は `DownloadFileAsync` の中で `request.RequestTimeout = TimeSpan.FromSeconds(300)` を設定します。このメソッドはインデクサーから `.torrent` を取得する処理です。ダウンロードクライアントの呼び出しには届きません。
- **Deluge を見ると上書きは可能だとわかり、qBittorrent はそれをしていません。** `DelugeProxy.cs:222` は `requestBuilder.PostProcess += r => r.RequestTimeout = TimeSpan.FromSeconds(15)` を実行しています。qBittorrent の `BuildRequest` にはそのような行がなく、100 秒は選ばれた値ではなく引き継がれた値であることの直接的な証拠です。

**Radarr も同じです。** タイムアウト部分の差分（Radarr の `:68-78` と Sonarr の `:70-80`）を比べると、バイト単位で完全に一致します。チェーンで違うのは、`WebException` に渡す値だけです。Radarr は `ex` を渡し、Sonarr は `ex.InnerException` を渡します。

**shim への影響。** `torrents/add` の中で同期的に行われる判断はすべて、100 秒の枠を共有します。*arr には「まだ処理中」と「接続できない」を区別する方法がありません。試行ごとの期限に試したプロバイダーの数を掛けたものに、キャッシュのみのプローブ時間を足した合計が、100 秒よりずっと小さくなければなりません。この枠の元になった、計測したプロバイダーの応答時間は [torrent-lifecycle.md](torrent-lifecycle.md) にあります。

補足として。100 秒はディスパッチャーの呼び出しごとに適用されるので、自動リダイレクトの各ホップが新しい枠を得ます（`HttpClient.cs:43` でチェーンは 5 回まで）。`DownloadClientBase.cs:30-44` のリトライ戦略はここには**適用されません**。インデクサーから `.torrent` を取得するときにだけ使われます（`TorrentClientBase.cs:142-144`）。

### 1.8 `GET /api/v2/torrents/properties?hash=<hash>` — `IsTorrentLoaded` / `GetTorrentProperties`

`IsTorrentLoaded`（`QBittorrentProxyV2.cs:110-126`）は `LogHttpError = false` を付けて呼び出し、**どんな**例外が出ても「読み込まれていない」として扱います。

`GetTorrentProperties`（`:128-135`）は `QBittorrentTorrentProperties`（`QBittorrentTorrent.cs:48-57`）にデシリアライズします。**フィールドは3つですが、使われるのは2つだけです。**

| JSON キー | C# | 用途 |
|---|---|---|
| `hash` | `Hash` | 読み取るだけで未使用 |
| `save_path` | `SavePath` | `GetImportItem` の 2.6.1 より前のパス（`QBittorrent.cs:354`） |
| `seeding_time` | `SeedingTime`（`long`、**秒**） | `FetchTorrentDetails`（`:739-744`） |

**ここではハッシュの大文字・小文字の扱いが一貫しておらず、これは重要です。** ほかの呼び出しはすべて小文字に変換しています（`:335`、`:346`、`:353` の `item.DownloadId.ToLower()`、`:97`、`:109`、`:121`、`:198` の `hash.ToLower()`）。ところが `FetchTorrentDetails` は `torrent.Hash` を**そのまま**渡します（`:741`）。つまり、シムが `torrents/info` に入れた値がそのまま使われます。実際の qBittorrent は小文字のハッシュを返すので、本物では問題になりません。Sonarr のフィクスチャは、この非対称な挙動を大文字の値を使った `GetTorrentProperties("HASH", …)` のモックで固定しています（Sonarr `QBittorrentFixture.cs:669-675`、Radarr `:668-674`）。**`torrents/info` からは小文字のハッシュを返し、`?hash=` の照合は大文字・小文字を区別しないようにしてください。**

`FetchTorrentDetails` が呼ばれるのは `HasReachedSeedingTimeLimit`（`:700`）からだけで、そこに到達するのはシーディング時間の上限が実際に設定されている場合だけです。そのため、シーディング時間の上限を一切宣言しないシムは、ポーリング中にこの呼び出しを見ることがありません。ただし `IsTorrentLoaded` では今も必要です。これは追加直後の準備完了を確認するプローブで、**未知のハッシュには 404、既知のハッシュには 200 と JSON** を返します。

結果は `{Host}{Port}{Hash}` ごとに 5 分間キャッシュされます（`:678`、`:689`、`:695`、`:708`）。フィクスチャでは、2 回のポーリングをまたいでも取得は 1 回だけであることを確認しています（Sonarr `QBittorrentFixture.cs:905-920`、Radarr `:904-919`）。

### 1.9 `POST /api/v2/torrents/setShareLimits` — `SetTorrentSeedingConfiguration`（`:286-308`） {#19-post-apiv2torrentssetsharelimits--settorrentseedingconfiguration-286-308}

形式: `hashes=<lowercase hash>` の後に `AddTorrentSeedingFormParameters(request, seedConfiguration, always: true)`
— `always: true` を指定すると、`-2` の場合でも `ratioLimit` と `seedingTimeLimit` は **両方とも** 常に送信されます (`:232`, `:237`)。`inactiveSeedingTimeLimit` は一切送信されません。

**404** は無視されます (`:298-307`。コメント: "setShareLimits was added in api v2.0.1")。それ以外のエラーは呼び出し元に伝わりますが、呼び出し箇所では警告としてキャッチされ、ログに出力されます (`QBittorrent.cs:95-102`, `:152-159`)。

このルートが使われるのは、インデクサーがシードの設定を提供していて、かつ webapi のバージョンが `< 2.8.1` の場合だけです。`2.11.2` を報告するシム (shim) では、シェアリミットは代わりに `torrents/add` で送信されるため、グラブ (grab) でこのルートが使われることはありません。no-op として実装し、200 を返すようにしてください。

### 1.10 `POST /api/v2/torrents/topPrio` — `MoveTorrentToTopInQueue`（`:310-330`） {#110-post-apiv2torrentstopprio--movetorrenttotopinqueue-310-330}

形式: `hashes=<lowercase hash>`。

**409 Conflict** は無視されます（`:320-329`、コメント: "qBittorrent rejects all Prio commands with 409:
Conflict if Options -> BitTorrent -> Torrent Queueing is not enabled"）。v1 プロキシーは代わりに **403** を無視します（`QBittorrentProxyV1.cs:255-264`）。それ以外のエラーは呼び出し元でキャッチされ、警告が出ます（`QBittorrent.cs:107-114`、`:164-171`）。フィクスチャでは、ここでの失敗がグラブを失敗させないことを検証しています（Sonarr `QBittorrentFixture.cs:525-542`、Radarr `:524-541`）。

この処理は、Recent/Older の優先度設定が `First` の場合にのみ呼び出されます（`QBittorrentPriority.First = 1`、`QBittorrentPriority.cs:5-6`）。デフォルトは `Last = 0` です。

### 1.11 `POST /api/v2/torrents/setForceStart` — `SetForceStart`（`:332-339`） {#111-post-apiv2torrentssetforcestart--setforcestart-332-339}

フォームの中身は `hashes=<lowercase hash>` と `value=true` です（小文字のリテラル文字列、`:337`）。

これは `InitialState` が `ForceStart` のときだけ呼ばれます（`QBittorrentState.cs:10-11`、`QBittorrent.cs:82`、`:117-127`）。エラーは捕まえて警告を出すだけです（`:123-126`）。

### 1.12 `GET /api/v2/torrents/info[?category=<cat>]` — `GetTorrents`（`:97-108`） {#112-get-apiv2torrentsinfocategorycat--gettorrents-97-108}

**送られるパラメータは `category` だけで、設定が空白でない場合にのみ送られます**
(`:100-103`)。`filter`、`hashes`、`sort`、`reverse`、`limit`、`offset`、`tag` は送られません。
クライアントは、その後もう一度カテゴリでフィルタリング**しません**。二重にフィルタリングする SAB クライアントとは違います。そのため、`category` を無視する shim は Radarr に Sonarr のトレントを渡してしまいます。

レスポンスの `category` フィールドは、もう一つの理由でも重要です。\*arr が**グラブ履歴を持たない**トレントは、ある条件を満たさない限り即座にスキップされます。その条件は `CompletedDownloadService.Check`（`CompletedDownloadService.cs:84-88`）で判定されます:

```csharp
if (historyItem == null && trackedDownload.DownloadItem.Category.IsNullOrWhiteSpace())
{
    trackedDownload.Warn("Download wasn't grabbed by Sonarr and not in a category, Skipping.");
    return;
}
```

`Category` は、`category` が空白でなければその値、そうでなければ `label` の値になります（`QBittorrent.cs:231`）。

レスポンスは JSON **配列**です。使われるフィールドと、その変換先は次のとおりです:

| JSON キー | C# 型 | 単位 | 変換先 |
|---|---|---|---|
| `hash` | `string` | | `DownloadId = torrent.Hash.ToUpper()`（`QBittorrent.cs:230`）。**大文字化**され、以降の呼び出しでは小文字に戻して渡されます |
| `name` | `string` | | `Title = torrent.Name`（`:232`）。これが何に影響するかは §7.1 を参照してください |
| `size` | `long` | バイト | `TotalSize`（`:233`）。また `RemainingSize = (long)(size * (1.0 - progress))`（`:235`）にも使われます |
| `progress` | `double` | 0..1 | `RemainingSize`（`:235`） |
| `eta` | `BigInteger` | 秒 | `GetRemainingTime` 経由の `RemainingTime`（`:236`、`:614-628`） |
| `state` | `string` | | `Status`、`Message`、そして `CanMoveFiles` 判定の片方（`:242-312`）。§2 を参照してください |
| `category` | `string` | | `Category`。こちらが優先されます（`:231`） |
| `label` | `string` | | `category` が空白のときに使われる `Category` のフォールバック（`:231`）。3.3.5 より前のフィールドです。qBittorrent 5 では出力されません |
| `ratio` | `float` | | `SeedRatio`（`:237`）、`HasReachedSeedLimit`（`:634`、`:641`） |
| `ratio_limit` | `float`、デフォルト `-2` | | `HasReachedSeedLimit`（`:632-645`） |
| `seeding_time_limit` | `long`、デフォルト `-2` | **分** | `HasReachedSeedingTimeLimit`（`:659-670`） |
| `inactive_seeding_time_limit` | `long`、デフォルト `-2` | **分** | `HasReachedInactiveSeedingTimeLimit`（`:723-736`） |
| `last_activity` | `long` | **Unix 秒** | `HasReachedInactiveSeedingTimeLimit`（`:736`） |
| `seeding_time` | `long?`、デフォルト null | 秒 | `HasReachedSeedingTimeLimit`（`:672-676`）。`QBittorrentTorrent.cs:36` のコメントには「リスト API からは提供されない」とありますが、クライアントは存在すればこれを使います。そのため `torrents/properties` への問い合わせを 1 回省けます |
| `save_path` | `string` | | `content_path` と比較されます（`:316`） |
| `content_path` | `string` | | webapi `>= 2.6.1` では `OutputPath`（`:318`）。§4 を参照してください |

`GetRemainingTime`（`:614-628`）:

```csharp
if (torrent.Eta < 0 || torrent.Eta > 365 * 24 * 3600) { return null; }   // > 31,536,000 s
if (torrent.Eta == 8640000) { return null; }                            // qBittorrent's "unknown"
return TimeSpan.FromSeconds((int)torrent.Eta);
```

完了したアイテムは、その後 `RemainingTime` が強制的に `TimeSpan.Zero` になります（`:273`）。

`torrents/info` は、`RefreshMonitoredDownloads` が実行されるたびに取得されます（`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:94`）。関連するイベントの 5 秒後には、コマンドキューにデバウンスされて載せられることもあります（`:53`）。

### 1.13 `GET /api/v2/torrents/files?hash=<hash>` — `GetTorrentFiles`（`:137-144`） {#113-get-apiv2torrentsfileshashhash--gettorrentfiles-137-144}

JSON配列を`List<QBittorrentTorrentFile>`にデシリアライズします。このクラスのメンバーは**1つだけ**で、`Name`（`QBittorrentTorrent.cs:59-62`）です。これは`name`にバインドされ、**save pathからの相対パス**を表します。区切り文字はどのOSでも`/`です（"QBittorrent returns `/` path separators even on windows"、`QBittorrent.cs:358`）。

呼び出されるのは`GetImportItem`（`:346`）からだけで、`OutputPath`がまだ空の場合に限ります。つまり、webapiが`< 2.6.1`の場合か、`content_path`が空で返ってきた場合です。`index`、`size`、`progress`、`priority`、`is_seed`、`piece_range`、`availability`は、すべて無視されます。

**空の配列**の場合は、`_logger.Debug("No files found for torrent {0} in qBittorrent")`が実行され、アイテムは変更されずに返されます（`:347-351`）。その結果、`ValidatePath`で失敗します。

### 1.14 `POST /api/v2/torrents/setCategory` — `SetTorrentLabel`（`:204-211`） {#114-post-apiv2torrentssetcategory--settorrentlabel-204-211}

形式: `hashes=<lowercase hash>`, `category=<post-import category>`。

呼び出されるのは `MarkItemAsImported` (`QBittorrent.cs:52-69`) からだけで、しかもオプションの
`TvImportedCategory` / `MovieImportedCategory` 設定が空白でなく、メインのカテゴリとも異なる場合だけです。
`DownloadClientException` を捕まえると、次の警告を出します:
"Failed to set post-import torrent label \"{0}\" for {1} in qBittorrent. Does the label exist?"
(`:62-67`)。§5.1。

### 1.15 `POST /api/v2/torrents/delete` — `RemoveTorrent`（`:190-202`） {#115-post-apiv2torrentsdelete--removetorrent-190-202}

形式: `hashes=<lowercase hash>`。さらに `removeData` が true の場合**だけ** `deleteFiles=true` を付けます（`:196-199`）。値は小文字の文字列そのものです。`Convert.ToString(bool)` ではありません。

`QBittorrent.RemoveItem`（`:333-336`）の実装は、これが全部です:

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    Proxy.RemoveTorrent(item.DownloadId.ToLower(), deleteData, Settings);
}
```

**`DeleteItemData` は呼び出しません。** ここが SAB クライアントとの違いです。SAB クライアントは、ファイルシステム経由でジョブフォルダーを自分で削除します（`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`; 参照: [sabnzbd-client-contract.md §5.3](sabnzbd-client-contract.md)）。ここでは、データの削除はダウンロードクライアントの仕事として完全に任されています。§5。

### 1.16 クライアントが一切使わないエンドポイント {#116-endpoints-the-client-never-touches}

インターフェースには一切ないので、以下は一度も呼び出されません: `torrents/pause`, `torrents/resume`, `torrents/stop`,
`torrents/start`, `torrents/setLocation`, `torrents/rename`, `torrents/recheck`,
`torrents/reannounce`, `torrents/filePrio`, `torrents/setDownloadLimit`, `torrents/setUploadLimit`,
`torrents/toggleSequentialDownload`, `torrents/setAutoManagement`, `torrents/editCategory`,
`torrents/removeCategories`, タグ, RSS, 検索, `app/setPreferences`, `app/defaultSavePath`,
`app/shutdown`, `sync/maindata`, `transfer/*`, `auth/logout`。一時停止と再開は、`torrents/add` の `paused=`/`stopped=` フォームフィールドとしてのみ存在します。

インターフェースにはあるものの、`QBittorrent.cs` からは一度も呼び出されないもの: `GetVersion`（§1.2）

### 1.17 v1 のルートマップ（参考用、実装は不要） {#117-the-v1-route-map-for-completeness-do-not-implement}

`QBittorrentProxyV1.cs`: `/version/api`（`:30`、`:64` — クライアントは返ってきた値の前に `"1."` を付けます。`:65`）、`/version/qbittorrent`（`:73`）、`/query/preferences`（`:81`）、`/query/torrents?label=&category=`（`:89-94` — **両方**のパラメータ）、`/query/propertiesGeneral/{hash}`（`:103`、`:120`）、`/query/propertiesFiles/{hash}`（`:128`）、`/command/download`（`:136`）、`/command/upload`（`:166`）、`/command/delete` または `/command/deletePerm`（`:196` — delete と deleteFiles の違いはパラメータではなく、2つの別々のルートです）、`/command/setCategory`（`:205-225` — 404 のときは `/command/setLabel` にフォールバックします）、`/command/addCategory`（`:230`）、`/command/topPrio`（`:248`）、`/command/setForceStart`（`:269`）、`/login`（`:345`）。

## 2. `state` → `DownloadItemStatus`

`QBittorrent.GetItems`（`:247-312`）。states は qBittorrent 自身の文字列で、`torrentStateToString`（`qBittorrent/src/webui/api/serialize/serialize_torrent.cpp:44-87`）によって生成されます。

| `state` | `DownloadItemStatus` | `Message` | 行 |
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
| `metaDL` | Queued **`dht: true` の場合**、それ以外は Warning | "qBittorrent is downloading metadata" / "qBittorrent cannot resolve magnet link with DHT disabled" | `:286-299` |
| `forcedMetaDL` | `metaDL` と同じ | 同じ | `:287` |
| `forcedDL` | Downloading | — | `:301` |
| `moving` | Downloading | — | `:302` |
| `downloading` | Downloading | — | `:303` |
| **それ以外すべて** | **Downloading** | "Unknown download state: {state}" | `:307-311` |

shim が気をつけるべき点:

- **未知の state では例外は投げられません。** 代わりに `_logger.Info($"Unknown download state: {torrent.State}")` でログを出し、Downloading として扱います（`:307-311`）。これは SAB クライアントとは逆です。SAB では、未知のステータス名がデシリアライザ内で例外を投げ、ポーリング全体が止まってしまいます。ただし、送るのはこの表にある名前だけにしてください。
- **インポートできるのは Completed の状態だけです。** `Status == Completed` でない限り、`CompletedDownloadService.Check` はすぐに戻ります（`src/NzbDrone.Core/Download/CompletedDownloadService.cs:68-71`）。
- **Completed の状態はすべて `RemainingTime` を 0 にリセットします**（`:273`、コメント "qBittorrent sends eta=8640000 for completed torrents"）。
- `metaDL` / `forcedMetaDL` は「マグネットリンクはあるが、メタデータがまだ無い」段階です。クライアントにタイムアウトはありません。shim が `metaDL` を返し続けるかぎり Queued のままで、それだけで失敗に切り替わることはありません。Warning になるのは `app/preferences` の `dht: false` の場合だけです（`:288`）。Sonarr の失敗ダウンロード処理は、この状態ではなく grab からの経過時間で判断します。
- `stalledDL` は、動いていない torrent についてオペレーターに見せる *警告* です。ピアの概念を持たない shim は、これを使うべきではありません。追跡中のダウンロードに Warning が付くと、キューで問題として表示され、`FailedDownloadService` の検査対象にもなってしまいます。
- `error` と `missingFiles` は、「failed download handling が起動しないように」（`:249`）わざと Warning にしています。shim が Sonarr にブロックリスト登録と再 grab をさせたいなら、Warning ではその意図を伝えられません。

---

## 3. 移動かコピーか — 正確な条件と手順 {#3-move-vs-copy--the-exact-condition-and-the-recipe}

### 3.1 ゲート {#31-the-gate}

`QBittorrent.cs:240-245`、コメントも含めてそのまま:

```csharp
// Avoid removing torrents that haven't reached the global max ratio.
// Removal also requires the torrent to be paused, in case a higher max ratio was set on the torrent itself (which is not exposed by the api).
item.CanMoveFiles = item.CanBeRemoved =
    item.DownloadClientInfo.RemoveCompletedDownloads &&
    torrent.State is "pausedUP" or "stoppedUP" &&
    HasReachedSeedLimit(torrent, config);
```

条件は3つあり、どれも必要です:

1. **`RemoveCompletedDownloads`** — qBittorrent 側ではなく、*arr 側のクライアントごとの設定です。
   `DownloadClientDefinition.RemoveCompletedDownloads` のデフォルトは **`true`**
   (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17`)で、UI では
   "Remove Completed" と表示されます。これをオフにすると、**インポートはコピーになり**、shim 側ではどうにもできません。(Move がコピーになる理由はもう1つあり、これも shim からは見えません。*arr のコンテナが、ダウンロードフォルダとルートフォルダを2つのボリュームでマウントしている場合です。その場合 `rename()` は `EXDEV` を返し、.NET の `File.Move` はコピーしてから削除します。zurg は取得元の API からこの状態を読み取り、後からそのコピーを取り込みます。`internal/arrlayout` と `internal/handlers/magic_copies.go` を参照してください。)
2. **`state` が `pausedUP` または `stoppedUP` のどちらかと完全一致すること。** `uploading`、`stalledUP`、`queuedUP`、`forcedUP` も完了扱いですが、移動はできません。これはフィクスチャがそのように固定しています (Sonarr `QBittorrentFixture.cs:680-689`、Radarr `:679-688`)。
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

- **torrentごとの `ratio_limit >= 0`** が最優先され, グローバル設定は参照されません。`ratio_limit` は qBittorrent 自体のモデルで、`-2` が「グローバル設定を使う」、`-1` が「無制限」です（`QBittorrentTorrent.cs:32`、wiki の *Set torrent share limit*）。
- `-1`（無制限）はどちらの分岐にも当てはまりません。`-1 >= 0` は false、`-1 == -2` も false なので、無制限の torrent は ratio のルールでは**決して**移動されません。
- `0.001f` の余裕があるおかげで「丸めのあとで到達した」が成り立ちます。フィクスチャでは、ratio `1.1006066990976857` は上限 `1.0` に対して到達済み、`0.9999` も到達済みとして扱われます（Sonarr `QBittorrentFixture.cs:715-737`、Radarr `:714-736`）。

`HasReachedSeedingTimeLimit`（`:655-717`）:

```csharp
if (torrent.SeedingTimeLimit >= 0)        { seedingTimeLimit = torrent.SeedingTimeLimit * 60; }        // minutes -> seconds
else if (torrent.SeedingTimeLimit == -2 && config.MaxSeedingTimeEnabled) { seedingTimeLimit = config.MaxSeedingTime * 60; }
else                                      { return false; }
```

その後、リスト API から `torrent.SeedingTime` が渡されていればそれを使います（`:672-676`）。なければ 5 分間のキャッシュを確認し、キャッシュになければ `seeding_time` を取得するために **`torrents/properties`** を呼び出します（`:678-716`、`:739-744`）。`HasReachedInactiveSeedingTimeLimit`（`:719-737`）も同じ形ですが、`now - last_activity` を `inactive_seeding_time_limit`（またはグローバル設定）と比較し、2 回目の呼び出しは必要ありません。

（以前の翻訳は却下されました：プレースホルダーが一致していませんでした。構造をそのまま維持してください。）

### 3.3 `CanMoveFiles` の判定内容 {#33-what-canmovefiles-decides}

`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, series, importItem)`
(`CompletedDownloadService.cs:148-151`)。そのあと、2か所で `CanMoveFiles` を読んでいます:

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

(Radarr: `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`、同一。)

```csharp
// src/NzbDrone.Core/MediaFiles/DownloadedEpisodesImportService.cs:204-207
if (importMode == ImportMode.Auto)
{
    importMode = (downloadClientItem == null || downloadClientItem.CanMoveFiles) ? ImportMode.Move : ImportMode.Copy;
}
```

(Radarr: `DownloadedMovieImportService.cs:221-224`。)

`copyOnly == false` → `TransferMode.Move`
(`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`)。`copyOnly == true` の場合は、"Use Hardlinks instead of Copy" がオンなら `TransferMode.HardLinkOrCopy`、そうでなければ `TransferMode.Copy` になります(`:103`、`:107`)。`TransferMode` は `[Flags] None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy=Copy|HardLink` です(`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`)。

**失敗した Move が Copy にフォールバックすることは決してありません。** 行番号つきの詳しい説明は [sabnzbd-client-contract.md §5.5](sabnzbd-client-contract.md) にあります。`DiskTransferService.cs` は共有されていて、2つのリポジトリでバイト単位で同一です。要点だけ言うと: `TransferFile` の Move 分岐(`src/NzbDrone.Common/Disk/DiskTransferService.cs:360-389`)にはコピー経路が1つしかなく、それは `targetMount.DriveFormat == "cifs"`(`:342`、`:378-385`)から最初に決まります。失敗への反応として後から選ばれることはありません。`TryMoveFileVerified` は例外を再スローし(`:487-503`)、`VerifyFile` は移動先のサイズが元と一致しないと `IOException("File move incomplete, data loss may have occurred. …")` を投げます(`:505-524`)。

### 3.4 qBittorrent の既定値のままだと、インポートは**コピー**になる {#34-with-qbittorrents-own-defaults-the-import-is-a-copy}

qBittorrent のデフォルト値のままの（モデルのデフォルトでもある）、shim が素直に報告するトレントを考えてみます：

| フィールド | 値 | 効果 |
|---|---|---|
| `state` | `stoppedUP` | 条件 2 ✓ |
| `ratio_limit` | `-2`（デフォルト、`QBittorrentTorrent.cs:33`） | グローバル側の分岐に落ちる |
| `max_ratio_enabled` | `false`（qBittorrent 自体のデフォルト。wiki の例の本文 `:684`） | グローバル側の分岐が失敗 |
| `seeding_time_limit` | `-2` | `max_seeding_time_enabled` が必要 |
| `max_seeding_time_enabled` | `false`（wiki `:686`） | 失敗 |
| `inactive_seeding_time_limit` | `-2` | `max_inactive_seeding_time_enabled` が必要 |
| `max_inactive_seeding_time_enabled` | `false` | 失敗 |

⇒ `HasReachedSeedLimit` が false ⇒ `CanMoveFiles` が false ⇒ `copyOnly` が true ⇒ `TransferMode.Copy` ⇒ **
\*arr がリリースのすべてのバイトをマウントから読み出して、そのまま書き戻します。** debrid マウントでは、これこそこの設計が避けるために存在する結果です。しかも静かに失敗します。何も警告が出ず、インポートに何時間もかかり、ディスクを埋めてしまいます。

フィクスチャは、この正確なケースを固定しています：
`should_not_be_removable_and_should_not_allow_move_files_if_max_ratio_is_not_set`
（Sonarr の `QBittorrentFixture.cs:691-701`、Radarr の `:690-700`） — グローバル制限はオフ、トレントは一時停止、ratio 1.0、`CanMoveFiles == false`。

### 3.5 手順 {#35-the-recipe}

**move** で import したい torrent ごとに:

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

`ratio_limit: 0` は最初の分岐に入ります（`0 >= 0` かつ `0 - 0 <= 0.001`）。そのため global preferences は参照されず、`max_ratio_enabled` は `false` のままで大丈夫です。`DownloadClientRemovesCompletedDownloadsCheck` のヘルスチェックも静かなままです。`ratio_limit >= ratio` が `0.001` 以内なら何でも動きますが、`0`/`0` は調整が一切要らない一番楽な設定です。

`pausedUP` と `stoppedUP` について: **develop ではどちらも同じように扱われます**。`CanMoveFiles` の判定（`:244`）でも status map（`:266-267`）でも同じで、seed limit のフィクスチャはすべて両方を対象にした `[TestCase]` のペアになっています。`stoppedUP` は qBittorrent 5 の書き方です（`serialize_torrent.cpp:54-55`）。master にはもう `pausedUP` は存在しません。ただ、リリース済みの \*arr ビルドを相手にするなら `pausedUP` のほうが安全です。`stoppedUP` の分岐は qBittorrent 5 が出た時に追加されたもので、古い Sonarr v4 / Radarr v5 のビルドは `pausedUP` しか知らないからです。最後の点は古いタグについての推測であり、上に挙げた develop のソースで証明されているわけではありません。

それから、shim 側ではどうにもできないことがあります。**"Remove Completed" は \*arr のダウンロードクライアント設定でオンのままにしておいてください。** これはデフォルトでオンになっています（`DownloadClientDefinition.cs:17`）。これをオフにすると、import のたびに黙ってフルダウンロードになってしまうので、必ず書いておいてください。

---

## 4. `OutputPath` — \*arr にどこからインポートさせるか {#4-outputpath--where-the-arr-is-told-to-import-from}

### 4.1 2.6.1 以降のパス: `content_path` {#41-the-261-path-content_path}

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

警告テキスト（`src/NzbDrone.Core/Localization/Core/en.json`）:

> Unable to Import. Path matches client base download directory, it's possible 'Keep top-level folder'
> is disabled for this torrent or 'Torrent Content Layout' is NOT set to 'Original' or 'Create Subfolder'?

シムが満たすべきルールは次のとおりです:

- `content_path` は **`save_path` と同じであってはいけません**。同じ値は「フォールバック」ではなく失敗です。そのアイテムは Warning になり、インポートされることはありません。
- `content_path` は **\*arr が動作している OS で有効な絶対パス**である必要があります。そうでない場合、`CompletedDownloadService.ValidatePath`（`CompletedDownloadService.cs:295-313`）によって拒否され、"[{0}] is not a valid local path. You may need a Remote Path Mapping." と表示されます。
- \*arr ホスト上に **フォルダまたはファイル**として存在している必要があります。`ProcessPath`（`DownloadedEpisodesImportService.cs:80-105`）は `FolderExists`、次に `FileExists` で分岐し、どちらでもない場合は `LogInaccessiblePathError` を出力して空の結果になります。
- 空の `content_path` は送らないでください。空の値は空でない `save_path` と「異なる」と判定されるため、`OutputPath` が空の `OsPath` に設定されます。その結果 `item.OutputPath.IsEmpty` が true になり、`GetImportItem` は `torrents/files` の走査（§4.2）にフォールスルーします（`:341-344`）。
- このブロックは **Completed** のアイテムに対してのみ実行されるため、`content_path` が重要になるのは、状態が §2 の Completed セットのいずれかになったときだけです。

実際の qBittorrent がそこに入れる値は、`TorrentImpl::contentPath()`（`qBittorrent/src/base/bittorrent/torrentimpl.cpp:577-587`）で決まります:

```cpp
Path TorrentImpl::contentPath() const
{
    if (!hasMetadata())    return {};
    if (filesCount() == 1) return (actualStorageLocation() / filePath(0));   // the FILE, not a folder
    const Path rootPath = this->rootPath();
    return (rootPath.isEmpty() ? actualStorageLocation() : rootPath);
}
```

`rootPath()` は `actualStorageLocation() / Path::findRootFolder(filePaths())`（`:565-575`）です。つまり:

**単一ファイル**のトレントでは `content_path` はそのファイル自体になります。共通のルートフォルダを持つ複数ファイルのトレントでは、そのフォルダが入ります。共通のルートを**持たない**複数ファイルのトレントでは `save_path` になります。まさにこのケースが、クライアントの `content_path == save_path` 警告の対象です。

`RemapRemoteToLocal(Settings.Host, …)` は、設定された **Host** の文字列をキーにしてユーザーの Remote Path Mappings を適用します。\*arr がコンテナ内で動いていて、シムがホスト側のパスを報告する場合は、マッピングが必要です。[sabnzbd.md](../guides/sonarr-radarr.md#8-if-your-arr-is-in-docker) を参照してください。そこで説明している内容はそのまま当てはまります。

### 4.2 2.6.1 より前のパス: `GetImportItem` が `torrents/files` をたどる {#42-the-pre-261-path-getimportitem-walks-torrentsfiles}

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

処理では **`files[0].name` だけ** を使い、そのパスの最上位のコンポーネントまでたどって、それを `properties.save_path` に結合します。フィクスチャーは3つのパターンすべてを固定しています（Sonarr `QBittorrentFixture.cs:317-421`、Radarr `:296-400`）:

| `files[0].name` | `save_path` | `OutputPath` |
|---|---|---|
| `Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` |
| `Folder/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Folder` |
| `Droned.S01.12/E01.mkv` (+ `E02.mkv`) | `/Torrents` | `/Torrents/Droned.S01.12` |

3行目に注意してください。ここで使われるのは `files[0]` のルートであり、計算された共通のルートではありません。そのため、このパスで動く shim は、最初のエントリにリリースフォルダが含まれる順番でファイルを一覧にする必要があります。webapi `>= 2.6.1` を報告する shim はここまで到達しません。これも `2.11.2` を報告すべき理由のひとつです。

`previousImportAttempt` は `GetImportItem`（`:338`）の引数ですが、この実装では **一度も読み取られません**。失敗した試行については何も記憶されません。

### 4.3 パスが間違っているとき、どれくらいの頻度で再試行されるか {#43-when-the-path-is-wrong-and-how-often-it-is-retried}

このパスには、バックオフも試行回数の上限もどこにもありません。

- `CompletedDownloadService.Check` は、状態が `Downloading` または `ImportBlocked` の追跡中のダウンロードすべてに対して、リフレッシュのたびに実行されます（`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:125-129`）。
- `Check` は最初に `SetImportItem` を呼び出します（`CompletedDownloadService.cs:73`）。これは `_provideImportItemService.ProvideImportItem(...)` → `client.GetImportItem(...)` を実行します（`:290-293`、`src/NzbDrone.Core/Download/ProvideImportItemService.cs:17-22`）。つまり `OutputPath` は、ポーリングのたびに *現在の* `torrents/info` の行から導き直されます。
- `ValidatePath` が失敗すると（`:295-313`）、Warning が出て状態は `Downloading` のままになります。そのため、次のポーリングで最初からやり直します。
  - 出力パスが空 → "Download doesn't contain intermediate path, Skipping."
  - OS が違うパス → "[{0}] is not a valid local path. You may need a Remote Path Mapping. …"
- `Import` も開始時に `SetImportItem` を呼び出し（`:130`）、その後 `trackedDownload.ImportItem.OutputPath.FullPath` を読み直します（`:147`）。また、`DownloadProcessingService` によって状態 `ImportPending` から実行されます（`src/NzbDrone.Core/Download/DownloadProcessingService.cs:61-63`）。インポートに失敗すると、状態は `ImportPending` のまま（`:158`）になるか、`ImportBlocked` に移ります（`:196`）。どちらの場合も、もう一度処理されます。
- パスは存在するけれど、インポートできるものが何もない場合は、"No files found are eligible for import in {0}"（`:162`）が出て、状態は `ImportPending` のままになります。

**shim にとっての影響：`content_path` がしばらく間違った値のままになるのは仕方ありません。** フォルダが実際に存在し、ファイルサイズが確定するまでは、torrent を Downloading（または Queued）として報告してください。そうすれば、クライアントは単にポーリングを続けます。Completed を早すぎるタイミングで報告すると、準備ができていないフォルダに対してインポートを試みることになり、無駄になります。さらに悪いことに、\*arr が中途半端なサイズのファイルを移動してから `VerifyFile` で失敗し、その時点で元の場所はすでに空になっている可能性があります。これは SAB エンドポイントについて文書化されている同じ罠です（[sabnzbd.md](../guides/sonarr-radarr.md)、*grab時に起きること*、手順 5）。

---

## 5. インポート後の処理の流れ {#5-the-post-import-sequence}

### 5.1 発火する順序 {#51-what-fires-in-order}

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

そして`RemoveFromDownloadClient`（`:87-103`）は次のとおりです：

```csharp
_logger.Debug("[{0}] Removing download from {1} history", ...);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);             // :92  deleteData: TRUE
trackedDownload.DownloadItem.Removed = true;
```

つまり、インポートが成功した後の通信の順序は次のとおりです：

1. **`POST /api/v2/torrents/setCategory`** — インポート後のカテゴリが設定されている場合のみ（`QBittorrent.cs:52-69`）。デフォルトではスキップされます。
2. その前に、ダウンロードクライアントの外側で: **\*arr がファイルを移動し**、その後 `ProcessFolder` がソースフォルダ自体を**削除することがあります**（`DownloadedEpisodesImportService.cs:209-223`、Radarr の `DownloadedMovieImportService.cs:226-240`）:

   ```csharp
   if (importMode == ImportMode.Move &&
       importResults.Any(i => i.Result == ImportResultType.Imported) &&
       ShouldDeleteFolder(directoryInfo, series))
   {
       _diskProvider.DeleteFolder(directoryInfo.FullName, true);   // recursive
   }
   ```

   `ShouldDeleteFolder`（`:108-153`）は、フォルダに残っている動画ファイルのうち、解析できてサンプルでないものがあると削除を拒否します（`:117-133`）。また、10 MB を超える `.rar` が残っている場合も拒否します（`:135-139`）。単一ファイルの移動が成功した後はどちらも当てはまらないので、フォルダは**削除されます**。`IOException` は捕捉されて Debug レベルでログに記録されます（`:219-222`）。
3. **`POST /api/v2/torrents/delete`**。パラメータは `hashes=<lowercase hash>&deleteFiles=true` です（`QBittorrent.cs:335`、`QBittorrentProxyV2.cs:190-202`）。

同じ `RemoveFromDownloadClient(…, true)` を呼ぶイベントが他に2つあります：

- `DownloadFailedEvent`（`DownloadEventHub.cs:26-46`）。クライアントごとの `RemoveFailedDownloads`（デフォルトは `true`、`DownloadClientDefinition.cs:18`）でゲートされます。`TrackedDownload.Fail()` は無条件に `DownloadItem.CanBeRemoved = true` を設定することに注意してください（`src/NzbDrone.Core/Download/TrackedDownloads/TrackedDownload.cs:39-46`、コメント: "Set CanBeRemoved to allow the failed item to be removed from the client"）。**つまり、シード制限のゲートがそうでないと判断しても、失敗したダウンロードは削除されます。**
- `DownloadCanBeRemovedEvent`（`:71-85`）。

`RemoveItem` から出た `NotSupportedException` は "Removing item not supported by your download client ({0})." に格下げされます（`:95-98`）。それ以外の例外はエラーとしてログに記録され、アイテムは Removed にマークされません。そのため次回のポーリングで再試行されます（`:99-102`）。

### 5.2 シムが `deleteFiles=true` で行うべきこと {#52-what-the-shim-must-do-with-deletefilestrue}

これは `internal/sabnzbd` が `mode=history&name=delete` について、同じ理由ですでに下した判断と同じです。`internal/sabnzbd/api.go:596-609` より:

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

qBittorrent の場合も形は同じですが、一点違いがあります。この API では、データの削除を行うのは *クライアント* の仕事で、\*arr の仕事ではありません。`RemoveItem` は `DeleteItemData` を呼ばないからです（§1.15）。ただ、\*arr は上の手順 2 ですでにフォルダ自体を削除しています。マウント経由での削除ですが、`__magic__` の下では tombstone が書き込まれます。エントリは `__magic__` から消えますが、`__all__` ではそのまま残り、どのフィルタディレクトリにも、debrid アカウント上にも残ります（[magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)）。

そのため:

- **`torrents/delete` は、shim が \*arr 向けに保持している torrent *レコード* を削除します。** 応答は 200 です。
- **`deleteFiles` でプロバイダー側の torrent を削除してはいけません。** \*arr がインポートしたばかりのリリースは、まだその torrent から配信されています。削除すると、インポートされたものそのものが壊れます。本当の削除が正しいと言えるのは、何もインポートしていない torrent、つまり失敗したダウンロードの場合だけです。ただ、そこでも debrid の torrent は作業用の一時ダウンロードではなく、共有ライブラリの状態なので、安全な既定の動作は次のとおりです: **プロバイダー側の torrent は決して削除せず、tombstone だけにする。** これは、[sabnzbd.md](../guides/sonarr-radarr.md) の *What works, and what does not* でやっているのと同じ形で、ユーザー向けのドキュメントにもそのまま書いてください。

存在しない hash に対する `torrents/delete` も、引き続き 200 を返すべきです。本物の qBittorrent も同じ動きをします（wiki の *Delete torrents*、「200 | All scenarios」）。ここでエラーを返すと、エラーとしてログに残り、ポーリングのたびに永遠に再試行されてしまいます。

### 5.3 `MarkItemAsImported` とインポート後のカテゴリ {#53-markitemasimported-and-the-post-import-category}

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

## 6. `Test()` — すべてのチェックを順番に、そのメッセージ付きで {#6-test--every-check-in-order-and-its-message}

`DownloadClientBase.Test()`（`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`）は処理全体をラップしています。**外に漏れた例外はすべて** `ValidationFailure("", "Test was aborted due to an error: " + ex.Message)` になります。

`QBittorrent.Test(List<ValidationFailure>)`（`:418-429`）:

```csharp
failures.AddIfNotNull(TestConnection());
if (failures.HasErrors()) { return; }     // a *warning* does not stop the rest
failures.AddIfNotNull(TestCategory());
failures.AddIfNotNull(TestPrioritySupport());
failures.AddIfNotNull(TestGetTorrents());
```

### 6.1 `TestConnection` (`:431-509`)

どの分岐も**returns**するので、このメソッドから返される失敗は最大1つです。

| 順序 | 条件 | プロパティ | メッセージ |
|---|---|---|---|
| 1 | `_proxySelector.GetProxy(Settings, force: true).GetApiVersion(Settings)` で強制的にバージョンを再検出します (`:435`) | | |
| 2 | バージョンが `< 1.5` のとき (`:436`) | `Host` | "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| 3 | バージョンが `< 1.6` **かつ** カテゴリーが設定されているとき (`:445-455`) | `Category` | "Category is not supported" / 詳細: "Categories are not supported until qBittorrent version 3.3.0. Please upgrade or try again with an empty Category." |
| 4 | バージョンが `>= 1.6` **かつ** カテゴリーが空のとき (`:456-464`) | `TvCategory` / `MovieCategory` | **Warning** — "Category is recommended" / "{appName} will not attempt to import completed downloads without a category." |
| 5 | `GetConfig` を呼び、次に `RemovesCompletedDownloads(config)` を確認します (`:467-474`) | `""` | "qBittorrent is configured to remove torrents when they reach their Share Ratio Limit" / 詳細には Options → BitTorrent → Share Ratio Limiting の場所が書かれています |

例外の対応 (`:476-506`):

| 捕捉された例外 | プロパティ | メッセージ |
|---|---|---|
| `DownloadClientAuthenticationException` | APIキーが設定されていれば `ApiKey`、なければ `Username` | "Authentication Failure" / "Please verify your credentials. Also verify if the host running {appName} isn't blocked from accessing {clientName} by WhiteList limitations…" |
| `Status == ConnectFailure` の `WebException` | `Host` | "Unable to connect to qBittorrent" / "Please verify the hostname and port." |
| その他の `WebException` | `""` | "Unknown exception: {message}" |
| その他の `Exception` | `Host` | "Unable to connect to qBittorrent"、`DetailedDescription = ex.Message` |

ケース4は**警告**です。`:421` の `failures.HasErrors()` は警告に対して false を返すので、カテゴリーが未設定の構成でも、残りの3つのチェックは実行されます。

### 6.2 `TestCategory` (`:511-556`) — 「category does not exist」の流れ {#62-testcategory-511-556--the-category-does-not-exist-flow}

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
失敗: プロパティ `TvCategory` / `MovieCategory`（または `TvImportedCategory` / `MovieImportedCategory`）、
メッセージ "Configuration of category failed"、詳細 "{appName} was unable to add the label to
qBittorrent."

なので shim には選択肢が2つあります。設定されたカテゴリを最初から用意して、`torrents/categories` に最初から含まれている状態にするか、`createCategory` を受け付けて、次の `torrents/categories` のレスポンスにすぐ反映するかです。**選択肢はこれだけです**。クライアントは再読み込みして、キーがまだ無ければ失敗します。カテゴリ名は**完全一致・大文字小文字を区別**して照合されます（デフォルトの序数比較子を使う `Dictionary<string, …>.ContainsKey`）。

`TvImportedCategory` の扱いに注意してください。インポート後のカテゴリもここでチェックされ、必要なら作成もされます。インポート後にしか使われないとしても同じです。オペレーターがこれを設定した場合は、必ず存在している必要があります。

`QBittorrentSettingsValidator`（`QBittorrentSettings.cs:23-24`）は、リクエストを送る前に、`^([^\\\/](\/?[^\\\/])*)?$` に一致しないカテゴリ名をすでに弾いています。つまり、バックスラッシュ、`//`、先頭または末尾の `/` は使えません。

### 6.3 `TestPrioritySupport` (`:558-597`) — `queueing` のヘルスチェック {#63-testprioritysupport-558-597--the-queueing-health-check}

```csharp
var recentPriorityDefault = Settings.RecentTvPriority == (int)QBittorrentPriority.Last;
var olderPriorityDefault  = Settings.OlderTvPriority  == (int)QBittorrentPriority.Last;
if (olderPriorityDefault && recentPriorityDefault) { return null; }   // :563-566  the default: nothing checked

var config = Proxy.GetConfig(Settings);
if (!config.QueueingEnabled) { … }                                    // :572-588
```

失敗プロパティは `nameof(Settings.RecentTvPriority)` または `nameof(Settings.OlderTvPriority)` です
(この順番でチェックされます)。メッセージは "Queueing Not Enabled"、詳細は "Torrent Queueing is not enabled in
your qBittorrent settings. Enable it in qBittorrent or select 'Last' as priority." です。

ここで例外が発生すると、`("", "Unknown exception: {message}")` になります (`:590-594`)。

`queueing_enabled` はモデルでデフォルトが **`true`** です (`QBittorrentPreferences.cs:41`)。そのため、キーを省略したシムでもチェックは通ります。ただ、`topPrio` が何もしないなら、キーを省略するのは嘘になります。`queueing_enabled: false` と報告するのが正直なやり方です。この場合、オペレーターが優先度の設定を `Last` から変えていたときだけ、この失敗になります。

### 6.4 `TestGetTorrents` (`:599-612`)

`Proxy.GetTorrents(Settings)`; any exception becomes `("", "Failed to get the list of torrents:
{exceptionMessage}")`. This is the check that catches a malformed `torrents/info` body — a JSON object
instead of an array, a bad enum, a non-numeric `size`.

### 6.5 `dht` のチェック {#65-the-dht-check}

There is **no** dedicated DHT check in `Test()`. `dht` is consulted at grab time
(`:73-76`, magnets without trackers) and at poll time (`:288`, the `metaDL` branch). A shim reporting
`dht: false` passes the connection test and then refuses every trackerless magnet with
`ReleaseDownloadException("Magnet not supported by download client. …")`
(`TorrentClientBase.cs:115`). **Report `dht: true`.**

## 7. シムが知っておくべき解析とインポートへの影響 {#7-parsing-and-import-consequences-a-shim-should-know}

### 7.1 `name` は `Title` になり、`Title` は3つの用途で使われる {#71-name-becomes-title-and-title-is-used-for-three-different-things}

`DownloadClientItem.Title = torrent.Name` (`QBittorrent.cs:232`)。この値は次の場面で使われます:

1. **シリーズ/映画の特定。** `CompletedDownloadService.Check` は `_parsingService.GetSeries(trackedDownload.DownloadItem.Title)` を呼びます (`CompletedDownloadService.cs:95`)。null が返ると、`DownloadId` をキーにした**取得履歴**にフォールバックします (`:99-102`)。それでも見つからなければ、"Series title mismatch; automatic import is not possible." と `ImportBlocked` になります (`:104-110`)。Radarr の相当する処理は `ProcessFolder` にあり、`_historyService.FindByDownloadId(downloadClientItem?.DownloadId ?? "")` を読みます (`DownloadedMovieImportService.cs:193-194`)。
   **これが、シムが \*arr の計算した正確な infohash をキーにしなければならない二つ目の理由です** (§1.7)。履歴のフォールバックは `DownloadId` をキーにしているため、ハッシュが一致しないと、タイトル経由もフォールバックも両方失われます。
2. **インポート判定のためのリリース解析。** `downloadClientItemInfo = Parser.Parser.ParseTitle(downloadClientItem.Title)` (Sonarr `ImportDecisionMaker.cs:80`、Radarr は `ParseMovieTitle` の `:80`)。結果はそれぞれ `LocalEpisode.DownloadClientEpisodeInfo` / `LocalMovie.DownloadClientMovieInfo` に代入されます (`:94` / `:92`)。
3. **ログ行とキューの UI。**

**Sonarr のタイトルフォールバックのゲート。** `AggregateEpisodes.GetBestEpisodeInfo` (`src/NzbDrone.Core/MediaFiles/EpisodeImport/Aggregation/Aggregators/AggregateEpisodes.cs:29-57`):

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

ファイル名の代わりにダウンロードクライアントのタイトルを使うには、三つのゲートを通す必要があります: `!OtherVideoFiles`、ファイル名自体がシーンタイトルでないこと、そしてクライアントのタイトルがシーズン全体の解析結果でないこと。つまり、torrent 名が救えるのは、単一ファイルでシーン名ではないリリースだけです。

Radarr には、一つの勝者を選ぶこのようなゲートはありません。`LocalMovie.OtherVideoFiles` は存在します (`src/NzbDrone.Core/Parser/Model/LocalMovie.cs:36`) が、映画の解析情報は選ばれるのではなく、信頼度順のオーグメンター連鎖によってマージされます (`AggregateQuality.cs:25-121`)。ダウンロードクライアントのタイトルはそのオーグメンターに渡され、映画の識別はフォルダ解析と取得履歴から得られます (`DownloadedMovieImportService.cs:192-195`)。

**`OtherVideoFiles`** (`ImportDecisionMaker.cs:85`、`:100`、Radarr は `:83`、`:98`):

```csharp
var nonSampleVideoFileCount = sceneSource ? GetNonSampleVideoFileCount(newFiles, series, downloadClientItemInfo, folderInfo) : videoFiles.Count;
…
OtherVideoFiles = nonSampleVideoFileCount > 1
```

`ProcessFolder` は常に `sceneSource: true` を渡します (`DownloadedEpisodesImportService.cs:201`)。そのため、サンプル以外の動画が二つ以上あるフォルダでは `OtherVideoFiles` が設定され、そのフォルダ内のすべてのファイルについて、ダウンロードクライアントのタイトルは候補から外れます。

**zurg で問題になる理由。** Real-Debrid は、ファイル名ブロックに引っかかるリリース名を書き換えます。`WEB-DL`、`WEB.x264`、`WEB.H264` は（その大文字小文字のとおりの場合のみ）、`WEBRip`、`BDRip`、`HDRip`、`DVDRip`、`HDTV.x264`、`HDTV.XviD`、`BluRay.x264`、`p.BluRay.DTS` は（大文字小文字を問わず）書き換えられます。これは 2026-10-14 時点で確認されたものです。さらに、二つのリリースが同じ名前で衝突すると、zurg はサフィックスを付けます。どちらの場合も、`torrent.name` が取得したリリースとして解析されなくなる可能性があります。詳しくはモノレポの `CLAUDE.md` の RD 451 セクションを参照してください。結果は次の順で現れます: 識別は取得履歴にフォールバックします（ハッシュが一致していれば問題ありません）。Sonarr のファイルごとの解析が引き継ぎます（フォルダ内の名前の良いファイルなら問題ありません）。そして `__magic__` 配下のフォルダ名も解析可能に保つ必要が出てきます。これは `DownloadedEpisodesImportService.cs:184` で `Parser.ParseTitle(directoryInfo.Name)` が読むものです。

### 7.2 インポート用フォルダのスキャンでサブツリーごと除外される {#72-the-import-folder-scan-drops-whole-subtrees}

`filterExtras: true` を付けて、ダウンロードフォルダーに対して適用される `DiskScanService.FilterPaths`（`src/NzbDrone.Core/MediaFiles/DiskScanService.cs:232-246`）。呼び出し元は `DownloadedEpisodesImportService.cs:185`（Radarr では `DownloadedMovieImportService.cs:202`）です:

```csharp
private static readonly Regex ExcludedExtrasSubFolderRegex = new Regex(@"(?:\\|\/|^)(?:extras|extrafanart|behind the scenes|deleted scenes|featurettes|interviews|other|scenes|samples|shorts|trailers)(?:\\|\/)", …IgnoreCase);   // :72
private static readonly Regex ExcludedSubFoldersRegex      = new Regex(@"(?:\\|\/|^)(?:@eadir|\.@__thumb|plex versions|\.[^\\/]+)(?:\\|\/)", …IgnoreCase);   // :73
private static readonly Regex ExcludedExtraFilesRegex      = new Regex(@"(-(trailer|other|behindthescenes|deleted|featurette|interview|scene|short)\.[^.]+$)", …IgnoreCase);   // :74
private static readonly Regex ExcludedFilesRegex           = new Regex(@"^\.(_|unmanic|DS_Store$)|^Thumbs\.db$", …IgnoreCase);   // :75
```

**Radarr の extras 用正規表現は選択肢が1つ違います**: `samples` の代わりに `sample[s]?`（Radarr `DiskScanService.cs:72`）を使うので、Sonarr では `samples/` だけが除外されるところを、Radarr では `sample/` フォルダーも除外します。4つの正規表現のうち、それ以外はリポジトリ間で同じです。

`ExcludedSubFoldersRegex` の `\.[^\\/]+` の選択肢に注意してください。**ドットで始まるディレクトリ名は、どの階層でも除外されます**。また、照合対象は `basePath.GetRelativePath(path)` なので、インポートフォルダーより下の部分だけが対象になります。マウントの上位階層にあるドットは影響しません。

そもそも `MediaFileExtensions.Extensions` に含まれる拡張子のファイルだけが、このフィルターに届きます（`DiskScanService.GetVideoFiles`、`:202-215`）。

### 7.3 サンプル検出はファイルを読む {#73-sample-detection-reads-the-file}

`GetNonSampleVideoFileCount`（`ImportDecisionMaker.cs:216-234`）は、フォルダ内の**すべての**動画ファイルに対して `_detectSample.IsSample(...)` を呼び出します。`DetectSample.IsSample`（`src/NzbDrone.Core/MediaFiles/EpisodeImport/DetectSample.cs:27-45`）が早期に返すのは、スペシャル、`.flv`、`.strm` の場合だけです（`:78-101`）。それ以外の場合は `_videoFileInfoReader.GetRunTime(path)` を呼び出します。これは、**マウント経由でファイルに対して ffprobe を実行する**ということです。そのうえで、想定されるランタイムから導いた最小値（`:103-121`）と比較します。ランタイムがちょうど 0 の場合は**サンプル**として扱われます（`:107-111`）。ランタイムが取得できない場合は "Failed to get runtime from the file, make sure ffprobe is available" とログに出力され、Indeterminate を返します（`:38-42`）。

`ShouldDeleteFolder`（`DownloadedEpisodesImportService.cs:117-133`）は、移動後に残ったファイルに対して同じチェックをもう一度実行します。

つまり、N 個のファイルからなるリリースをインポートすると、何かを移動する前に、debrid バックエンドに対して少なくとも N 回の ffprobe が走ることになります。zurg マウントではこれは実際のコストで、クライアント側からは避けられません。

### 7.4 `ProcessFolder` / `ProcessFile` での拒否 {#74-the-refusals-in-processfolder--processfile}

| 条件 | 結果 | 行 (Sonarr) |
|---|---|---|
| the import path is a series/movie folder | `ImportRejectionReason.SeriesFolder` — "Import path is mapped to a series folder" (Radarr: `MovieFolder`, "…a movie folder") | `:175-182` (Radarr `:183-190`) |
| folder name does not resolve to a known series/movie | `UnknownSeriesResult("Unknown Series")` | `:160-168` |
| filename starts with `._` | `InvalidFilePath` | `:251-259` |
| extension in `FileExtensions.DangerousExtensions` | `DangerousFile` | `:263-271` |
| extension in `FileExtensions.ExecutableExtensions` | `ExecutableFile` | `:273-281` |
| extension not in `MediaFileExtensions.Extensions` | `UnsupportedExtension` | `:283-293` |

**`SeriesPathExists` / `MoviePathExists` は `__magic__` のレイアウトで一番引っかかる部分です。** \*arr のルートフォルダが `/mnt/zurg/__magic__/tv` で、シリーズフォルダが `/mnt/zurg/__magic__/tv/The Show` だとします。すると、インポートパスがたまたまシリーズフォルダ*そのもの*になっている場合、問答無用で拒否されます。だからダウンロードフォルダ (`content_path`) は、ルートフォルダの中ではなく、ルートフォルダと同じ階層に置く必要があります。これは [sabnzbd.md](../guides/sonarr-radarr.md) ですでに案内している構成です。
`save_path` = `/mnt/zurg/__magic__/__all__`、ルートフォルダは `/mnt/zurg/__magic__/tv` と `/mnt/zurg/__magic__/movies`、リリースは `/mnt/zurg/__magic__/__all__/<release>` に置かれます。

`_UNPACK_` と `_FAILED_` は、解析前にフォルダ名から取り除かれます (`GetCleanedUpFolderName`、`:311-317`)。

`IsFileLocked` は、ダウンロードクライアントのアイテムがある場合**完全にスキップされます** (`:187-199`、`:295-304`)。ロックのチェックは手動スキャンやルートフォルダのスキャン時にだけ実行されます。shim がこれを気にする必要はありません。

---

## 8. ヘルスチェック {#8-the-health-checks}

3つとも SAB クライアントと共通で、[sabnzbd-client-contract.md §6](sabnzbd-client-contract.md) で分析しています。qBittorrent 固有の部分は以下のとおりです。

- **`RemotePathMappingCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs:59-173`)
  `client.GetStatus().OutputRootFolders` を順にたどります。qBittorrent の場合、これは `QBittorrent.cs:377-407` で計算される1つのフォルダだけです。グローバルな `save_path` を、設定したカテゴリの `savePath`（§1.5）で上書き、または拡張したものです。このパスは **\*arr が動いている OS** 上で有効である必要があり（`:68-113`）、\*arr のホスト上に存在している必要があります（`:115-158`）。書き込み可能である必要はありません。`IsLocalhost` は `Settings.Host == "127.0.0.1" || Settings.Host == "localhost"`（`:406`）で、表示される3つのエラーメッセージのどれを出すかを切り替えるだけです。
- **`DownloadClientRemovesCompletedDownloadsCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:33-66`)
  `GetStatus().RemovesCompletedDownloads` が true のとき（つまり §1.4 で導出されたフラグが true のとき）、常に警告を出します。`max_ratio_enabled` と `max_seeding_time_enabled` を false のままにしておけば（§3.5 のレシピではすでにそうなっています）、警告は出ません。
- **`DownloadClientRootFolderCheck`** は、2つのリポジトリが実際に異なる唯一の箇所です。Sonarr はルートフォルダが出力フォルダと*等しい*場合のみ警告しますが、Radarr は、ルートフォルダが出力フォルダを*含む*場合にも警告します。詳しい分析は [sabnzbd-client-contract.md §6.1](sabnzbd-client-contract.md) にあります。実用的なルールはここでも同じです。ルートフォルダを保存パスと同じ場所や、その上位に置かないこと、そしてその中にも置かないことです。たとえば `/mnt/zurg/__magic__/tv` は `/mnt/zurg/__magic__/__all__` の兄弟フォルダです。

---

## 9. Sonarr と Radarr — 完全な差分 {#9-sonarr-vs-radarr--the-complete-diff}

| ファイル | 相違点 |
|---|---|
| `QBittorrent.cs` | `TvCategory`→`MovieCategory`、`TvImportedCategory`→`MovieImportedCategory`、`RecentTvPriority`→`RecentMoviePriority`、`OlderTvPriority`→`OlderMoviePriority`、`RemoteEpisode`→`RemoteMovie`。`remoteEpisode.IsRecentEpisode()` → `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie`（`:80`、`:137`）。**行番号は1対1で一致。** |
| `QBittorrentSettings.cs` | 同じ名前の変更。デフォルトカテゴリは `"tv-sonarr"` → `"radarr"`（`:36`）。ヘルプテキストのトークン `…EpisodeHelpText` → `…MovieHelpText`。行番号は一致。 |
| `QBittorrentProxyV2.cs` | カテゴリ名の変更。`new[] { HttpStatusCode.Forbidden }` → `[HttpStatusCode.Forbidden]`（コレクション式。Sonarr `:401` / Radarr `:400`）。Sonarr は13行目に余分な空行がある → **N ≥ 14 で Sonarr の N行目 = Radarr の N−1行目**。 |
| `QBittorrentProxyV1.cs` | カテゴリ名の変更。同じ空行によるずれあり。 |
| `QBittorrentProxySelector.cs` | Sonarr のコンストラクタ（`:46`）に余分なスペースが1つ。3行目に空行があり → **N ≥ 4 で Sonarr の N行目 = Radarr の N−1行目**。 |
| `QBittorrentPreferences.cs`、`QBittorrentTorrent.cs`、`QBittorrentState.cs`、`QBittorrentLabel.cs`、`QBittorrentPriority.cs`、`QBittorrentContentLayout.cs` | **バイト単位で同一。** |
| `TorrentClientBase.cs` | `RemoteEpisode`→`RemoteMovie` を全体で変更。Radarr は `.torrent` 取得時に HTTP **410 Gone** も 404 と同じように扱う（`:175`）。Sonarr は 404 のみ。どちらも274行。 |
| `QBittorrentFixture.cs` | 同じテストだが順序が入れ替わっている。`missingFiles_item_should_have_required_properties` は Sonarr の `:296-315` と Radarr の `:402-420` にある。**Radarr 側のコピーには `[Test]` 属性がない**（`:401` は空行）ため、そこでは実行されない。Sonarr `:318-421` = Radarr `:297-400`。Sonarr `:423` 以降は Radarr = Sonarr − 1。Sonarr は1000行、Radarr は998行。 |
| `DiskScanService.cs` | `ExcludedExtrasSubFolderRegex` — Radarr は `sample[s]?`、Sonarr は `samples`（どちらも `:72`）。他の3つの正規表現は同一。 |
| インポートサービス | `Series`/`Episode` と `Movie` の違い。Sonarr の `AggregateEpisodes` にあるタイトル優先のゲートは Radarr には対応するものがない（§7.1）。どちらもインポートパスがライブラリフォルダの場合は、他の処理より前に拒否する（Sonarr `:175-182`、Radarr `:183-190`）。フォルダ名の解析はその後に行う（Sonarr `:184`、Radarr `:195`）。Radarr はさらにそこで `DownloadId` によりグラブ履歴を検索する（`:193-194`）。 |
| `ImportApprovedEpisodes.cs` / `ImportApprovedMovie.cs` | `copyOnly` の switch は同一。Sonarr `:139-152` / Radarr `:116-129`。 |
| `DiskTransferService.cs`、`DownloadClientBase.cs`、`DownloadEventHub.cs`、`Json.cs`、`HttpClient.cs`、`HttpRequestBuilder.cs` | 共通。バイト単位で同一。 |

その他、この文書の残りの内容は**Series/Movie を除きバイト単位で同一**で、両方とも同じ行に当てはまります。

---

## 10. 最小限かつ完全なサンプルペイロード {#10-minimal-but-complete-example-payloads}

### 10.1 `GET /api/v2/app/webapiVersion`

```
2.11.2
```

`Content-Type: text/plain`。JSONではありません。引用符は不要で、末尾の改行も必要ありません。

### 10.2 `POST /api/v2/auth/login`

リクエストボディ: `username=sonarr&password=hunter2`、`application/x-www-form-urlencoded`

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8
Set-Cookie: SID=8f3c1c0e9a1f4d2f9c0b7a5e3d1f6b2a; path=/

Ok.
```

認証情報が間違っていても、ステータスは **200** のままで、ボディは `Fails.` になります。401 が返ることはありません。

### 10.3 `GET /api/v2/app/preferences`

§1.4 の10個のキーだけが読み込まれます。他のキーを送っても構いませんが、無視されます。

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

Hard requirements:

- `save_path` は **Sonarr/Radarr のホスト上で** ディレクトリとして存在している必要があります (`RemotePathMappingCheck`、§8)。
- `max_ratio_enabled: false` と `max_seeding_time_enabled: false` にすると `RemovesCompletedDownloads` が false のままになり、接続テスト (§6.1 のケース 5) とヘルスチェックの両方で警告が出ないままになります。
- `dht: true` にしてください。そうしないと、トラッカーなしのマグネットリンクはクライアント側で拒否されます (§6.5)。
- `max_ratio_act` は **整数** である必要があります (§0.6)。

### 10.4 `GET /api/v2/torrents/categories`

```json
{
  "tv": { "name": "tv", "savePath": "" },
  "movies": { "name": "movies", "savePath": "" }
}
```

JSON の **オブジェクト** で、`savePath` は **camelCase** です。`//` で始まらないようにしてください（§1.5）。`savePath` を空にすると、出力先のルートフォルダはグローバルの `save_path` のままになります。

### 10.5 `GET /api/v2/torrents/info?category=tv` — ダウンロード中のものと、インポート可能なもの {#105-get-apiv2torrentsinfocategorytv--one-downloading-one-importable}

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

要件（必ず守ってください）:

- JSON の**配列**（`List<QBittorrentTorrent>`）にしてください。オブジェクトだと `GetTorrents` 内で例外になり、`TestGetTorrents`（§6.4）が失敗します。

- `hash` は**小文字**（§1.8）で、\*arr がマグネットリンクや `.torrent` から計算した infohash と完全に一致させてください（§1.7）。

- `size` は**バイト単位**、`progress` は 0〜1 の割合です。`RemainingSize = size × (1 − progress)` で計算されます。

- `eta: 8640000` は「不明」として扱われ、`RemainingTime` は null になります（`:622-625`）。Completed の項目は、この値に関係なく `TimeSpan.Zero` になります（`:273`）。

- `state` は §2 の表から、大文字小文字を含めてそのまま使ってください。

- Completed の項目では、`content_path` は**絶対パスで、実際に存在し、`save_path` とは異なる**必要があります（§4.1）。Completed 以外の間は空でも構いません。

- `ratio_limit: 0` と `ratio: 0` の組み合わせが、移動用の設定です（§3.5）。

- `category` はクライアントに設定されたカテゴリと一致している必要があります。クライアント側では再フィルタリングしないので、クエリパラメータの指定どおりに返してください。

- `seeding_time` は省略しても構いません。その場合、クライアントは `torrents/properties` を参照します。これはシーディング時間の制限が実際に有効な場合のみです。

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

`save_path` と `seeding_time` だけが読み取られます（§1.8）。**未知のハッシュには 404** を返しますが、これは
`IsTorrentLoaded` が「まだ無い」と判断するときの仕組みです（`:110-126`）。

### 10.7 `GET /api/v2/torrents/files?hash=<hash>`

```json
[
  { "index": 0, "name": "Some.Show.S01E03.1080p.WEB.h264-GRP/ep3.mkv", "size": 1073741824, "progress": 1, "priority": 1, "is_seed": true, "piece_range": [0, 2047], "availability": 1 }
]
```

`name` だけが読まれ、`save_path` からの相対パスとして扱われます。区切りは `/` です（§1.13 を参照）。pre-2.6.1 の経路では順番が大事です。`files[0]` の一番上のコンポーネントが出力フォルダになります。

### 10.8 `POST /api/v2/torrents/add`

リクエスト（urlencoded 形式。長い magnet の場合は代わりに multipart で届きます — §0.3）:

```
urls=magnet%3A%3Fxt%3Durn%3Abtih%3A3B1A...&category=tv&stopped=False
```

レスポンス:

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8

Ok.
```

`Fails.` という文字列以外はすべて成功です（§1.7）。本文が空の 200 でも動作します。

### 10.9 `POST /api/v2/torrents/delete`

リクエスト: `hashes=3b1a1469c180f447b77021074dbbccaef62611e7&deleteFiles=true`

レスポンス: `HTTP/1.1 200 OK`、ボディは空です。**存在しないハッシュでも200が返ります**（§5.2）。

### 10.10 `POST /api/v2/torrents/createCategory`、`setCategory`、`setShareLimits`、`topPrio`、`setForceStart` {#1010-post-apiv2torrentscreatecategory-setcategory-setsharelimits-topprio-setforcestart}

すべて urlencoded フォームを受け付け、どれも空のボディで `200` を返します。`topPrio` は「キューイングが無効」という意味で **409** を返すことがあります。クライアントはこのステータスだけを無視します（§1.10）。`setShareLimits` は「サポートされていない」という意味で **404** を返すことがあります。これも無視されます（§1.9）。

## 11. 本物の qBittorrent との違い — zurg のモデルが狭い、または広いところ {#11-differences-from-real-qbittorrent--where-zurgs-model-is-narrower-or-wider}

### 11.1 シーディングがないので、シードリミットの判定を偽装する必要がある {#111-there-is-no-seeding-so-the-seed-limit-gate-has-to-be-faked}

本物の qBittorrent は、実際にアップロードしたバイト数から `ratio` を計算し、ユーザーがグローバルまたはトレントごとの上限を設定できるようにしています。クライアントの `CanMoveFiles` ゲートは、まだ共有比率の義務を果たしている途中のトレントからファイルを引き抜いてしまわないためにあります（`QBittorrent.cs:240-241`）。debrid バックエンドは、何もアップロードしません。一度もです。
そこでシムは `ratio: 0, ratio_limit: 0` と宣言します。これは、トレントごとの上限がすでに満たされている、という意味です。このフィールドがここで正直でいられる唯一の意味では、これは正直な値ですし、グローバル設定をまったく関わらせずに済みます（§3.5）。

### 11.2 `content_path` は常にフォルダで、ファイルになることはない {#112-content_path-is-always-a-folder-never-a-file}

qBittorrentの`contentPath()`は、単一ファイルのtorrentの場合は**ファイルパス**を返します（`torrentimpl.cpp:582-583`）。`__magic__`では、単一ファイルのリリースも含めて、すべてのリリースが実ファイルを入れたフォルダになります（[magic.md](../guides/magic.md#with-nothing-stored-it-is-__all__s-releases-as-real-folders)）。

その結果、どれもクライアント側に有利になります:

- `ProcessPath`は常に**フォルダ**の分岐を通り（`DownloadedEpisodesImportService.cs:80-90`）、ファイルの分岐（`:92-102`）は通りません。フォルダの分岐では`FilterPaths`、`ShouldDeleteFolder`、フォルダ名の解析が適用されるので、extrasフィルターとフォルダ名からのタイトル補完が常に有効です。
- `ProcessFile`での個別ファイルの拒否（危険・実行可能・未対応の拡張子、`._`プレフィックス。§7.4）は、まだ到達できます。ただし、トップレベルの分岐ではなく、`GetVideoFiles`の拡張子フィルターを経由します。
- 2.6.1より前の`GetImportItem`の走査（§4.2）も動きます。`files[0].name`は常にリリースのフォルダを含むためです。ただ、それほど古いバージョンを報告する理由はありません。

ひとつ注意点があります。常にフォルダになるので、`content_path`は必ず`save_path + "/" + <release folder>`となり、`save_path`と等しくなることはありません。そのため`DownloadClientQbittorrentTorrentStatePathError`の警告（§4.1）は構造的に発生しません。これは偶然ではなく、正しい結果です。

### 11.3 `name` は取得したタイトルではなく、変わることもある {#113-name-is-not-the-grabbed-title-and-it-can-change}

本物のqBittorrentは、トレントのメタデータから名前を取得し、その名前は変わりません。zurgの名前はライブラリから来ます:

- Real-Debridは、ファイル名が451ブロック（`WEB-DL`、`Rip`タグ、いくつかのソース・ドット・コーデックの組み合わせ。2026-10-14時点で確認）に引っかかるリリースの名前を変更します。詳しくはモノレポの`CLAUDE.md`にあるRD 451のセクションを見てください。
- zurgは、2つのリリースが同じ名前で衝突すると接尾辞を付けます。また、修復（repair）では新しいトレントIDでリリースを作り直します。
- 名前はポーリングのたびにライブラリから読み取られるため、\*arrがすでに追跡しているIDでも**ポーリングとポーリングの間に**名前が変わることがあります。

どれもトラッキングを壊すことはありません。トラッキングは名前ではなく`DownloadId`（infohash）をキーにしているからです。壊れるのは§7.1のタイトル解析の経路です。そこから次の2つのルールが導かれます:

1. \*arrが計算したinfohashをキーにしてください。zurg内部の値は絶対に使わないでください。infohashは、grab、grab履歴、ポーリングをつなぐ唯一の結合点です。
2. `__magic__`フォルダ名を解析可能な状態に保ってください。フォルダ分岐が読み取るフォールバックだからです（`DownloadedEpisodesImportService.cs:184`）。

### 11.4 進捗やメタデータの段階がない {#114-there-is-no-progress-and-no-metadata-phase}

何もダウンロードしないので、意味のある `progress`、`eta`、`dlspeed`、`metaDL` はありません。これは SAB エンドポイントにも書かれている制限と同じです（[sabnzbd.md](../guides/sonarr-radarr.md)、*何が動いて、何が動かないか* の「進捗なし。ジョブはキューに入っているか、完了しているかのどちらか」）。自然な対応付けは次のとおりです。ライブラリにまだそのリリースが出てこない間は **Queued**（`queuedDL`）、出てきて *ファイルサイズが落ち着いたら* **Completed**（`pausedUP`）。`size` は、キューのエントリが空欄にならないように、バックエンドが宣言している値を使います。

`metaDL` は、`dht: true` も報告されている場合にだけ待機状態に使ってください。その場合のみ Queued です（`:288-297`）。`queuedDL` は無条件で、メッセージは付きません。

一時的な待機に `stalledDL`、`error`、`missingFiles` を使わないでください。この3つはすべて **Warnings**（§2）で、キューに問題として表示されてしまいます。

### 11.5 削除は隠すだけで、消すわけではない {#115-deleting-hides-it-does-not-destroy}

`torrents/delete?deleteFiles=true` は、本物の qBittorrent では、トレントを消したうえに `rm -rf` でデータも消します。
ここでは、レコードだけを消すべきです。リリースは引き続きプロバイダーのトレントから配信されていますし、
\*arr が消えてほしかったフォルダは、マウント経由ですでに自分で墓標（tombstone）になっています（§5.2、
[magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)）。
これは、`internal/sabnzbd/api.go:596-609` の `internal/sabnzbd` にある `deleteFromHistory` に記録されている考え方とまったく同じです。

### 11.6 クライアントが求めてくるが、適用先がないもの全般 {#116-everything-the-client-can-ask-for-that-has-nothing-to-apply-to}

`sequentialDownload`、`firstLastPiecePrio`、`contentLayout`、`stopped`/`paused`、`setForceStart`、`topPrio`、`setShareLimits`、`dlLimit`/`upLimit`: これらは受け付けて、200 を返します。ただし何も適用しません。拒否された場合に目に見える影響があるのは 2 つだけです。`topPrio` は 409 を無視し、それ以外のエラーでは警告を出します。`setShareLimits` は 404 を無視します。どちらも grab をブロックすることはありません。

`contentLayout` について補足します。この設定は、\*arr で qBittorrent に最上位のフォルダを必ず残させ、`content_path != save_path` にするためにあります。`__magic__` では、レイアウトは常にフォルダになります（§11.2）。そのためこのパラメーターは効果がなく、オペレーターは Default のままにしておいて大丈夫です。

---

## 12. 実装チェックリスト（14項目） {#12-implementation-checklist-14-points}

1. **API v2 のみ。** `/api/v2/app/webapiVersion` には `2.11.2` を返します。`/version/api` には **404** を返して、v1 のプローブが綺麗に失敗するようにします。
2. **認証:** `Authorization: Bearer <key>` ヘッダー、事前送信される `Authorization: Basic`、`SID` Cookie、または何もない場合を受け付けます。`POST /api/v2/auth/login` には **200 + `Ok.` + `Set-Cookie: SID=…`** で応答します。認証情報が不正な場合は、401 ではなく 200 のまま `Fails.` を返します。`Referer` と `Origin` は必須にしないでください。
3. **エラーは JSON ではなく HTTP ステータスで返します。** 403 は「再ログインせよ」を意味し、1 回だけ再試行されます。2 回目の 403 は認証エラーではなく接続エラーとして扱われます。404 は `torrents/properties`（不明なハッシュ）と `torrents/setShareLimits`（非対応）で意味を持ちます。409 は `torrents/topPrio`（キューイング無効）で意味を持ちます。それ以外はすべて 200 にしてください。
4. **`torrents/add` では両方のフォーム形式を解析してください。** urlencoded と、いずれかの値が 1024 バイトを超える場合または `.torrent` がアップロードされた場合の multipart です。真偽値はすべて、`true`/`false` だけでなく `True`/`False` も受け付けてください。
5. **`torrents/info` は配列を返し、`torrents/categories` は camelCase の `savePath` を持つオブジェクトを返します。** `category` クエリパラメータには必ず対応してください。クライアント側では再フィルタリングしません。
6. **ハッシュは、すべてのレスポンスで小文字、すべてのリクエストで大文字小文字を区別せずに照合します。** 常に \*arr が magnet または `.torrent` から計算した infohash を使います。`torrents/properties` だけは、`torrents/info` が使ったのと同じ大文字小文字の形式でハッシュを受け取る場合があります。
7. **移動のレシピ:** `state: "pausedUP"`、`ratio: 0`、`ratio_limit: 0`、`seeding_time_limit: -2`、`inactive_seeding_time_limit: -2`。これより緩い設定だと、インポートは **コピー** になり、リリース全体を再ダウンロードすることになります。\*arr の「Remove Completed」設定はオンのままにしてください。shim ではこれを補えません。
8. **`content_path` は絶対パスで、\*arr ホスト上に存在し、`save_path` と同じであってはなりません。** リリースが本当にインポートできる状態になってから（一覧に表示され、ファイルサイズが確定してから）設定してください。それまでは `queuedDL` を報告し、クライアントにポーリングを続けさせます。再試行の上限はありません。
9. **`save_path`**（`app/preferences` から、加えてカテゴリの `savePath`）は、\*arr ホスト上にディレクトリとして存在している必要があります。存在しないと `RemotePathMappingCheck` がエラーを出します。書き込み可能である必要はありません。`//` で始まる `savePath` は絶対に出さないでください。
10. **接続テストを緑のままにしてください:** `dht: true`、`queueing_enabled: true`、`max_ratio_enabled: false`、`max_seeding_time_enabled: false`、`max_ratio_act: 0`（整数）。さらに、設定したカテゴリを事前に作成するか、`createCategory` に対応して、次の `torrents/categories` のレスポンスに必ず反映してください。
11. **`torrents/delete` はレコードだけを削除し、それ以外は何もしません。** プロバイダーのトレントについては `deleteFiles` を無視してください。これは `internal/sabnzbd` の `deleteFromHistory` が `del_files` を無視しているのと同じです（`internal/sabnzbd/api.go:596-609`）。不明なハッシュには 200 を返してください。`setCategory` を受け付け、新しいカテゴリを記録してください。
12. **Move インポートの後、\*arr がリリースのフォルダを自分で `rm -rf` することが想定されます**（`DownloadedEpisodesImportService.cs:209-223`）。これは `__magic__` のトゥームストーンになり、その後 `torrents/delete` が呼ばれます。どちらも正常な動作で、何も壊しません。
13. **§2 の状態名だけを、大文字小文字も含めて正確に使ってください。** 未知の名前は、ここでは例外を投げません（SAB と違って）。ただし、ログに記録されて Downloading にデフォルト設定されます。一時的な待ち状態に `stalledDL`、`error`、`missingFiles` を使わないでください。この 3 つはどれも Warning になります。
14. **出力フォルダと同じか、その上位のフォルダをルートフォルダにしないでください。** `save_path` が `/mnt/zurg/__magic__/__all__` の場合は、ルートフォルダとして `/mnt/zurg/__magic__/tv` と `/mnt/zurg/__magic__/movies` を使い、リリースは `/mnt/zurg/__magic__/__all__/<release>` に置いてください。そうしないと、`SeriesPathExists`/`MoviePathExists` によってインポートが即座に拒否され（§7.4）、Radarr の `DownloadClientRootFolderCheck` が起動のたびに警告を出します。
