# Antarmuka Web API qBittorrent yang dipakai Sonarr dan Radarr (develop) {#qbittorrent-web-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Sumber kebenaran: file yang diambil dari `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...` dan dari `qbittorrent/qBittorrent/master` pada **2026-08-27**. Setiap nomor baris di bawah dibaca langsung dari file-file tersebut.

Ini adalah versi torrent dari [kontrak klien sabnzbd](sabnzbd-client-contract.md). Dokumen itu mencatat alasan `internal/sabnzbd` menjawab dengan bentuk-bentuk tertentu; dokumen ini adalah spesifikasi yang harus dipenuhi oleh shim qBittorrent *sebelum* ditulis, supaya grab, poll, import **sebagai move**, dan cleanup setelah import berfungsi di kedua klien. Jika kedua klien memakai mekanisme yang sama (lapisan HTTP, serializer JSON, `DiskTransferService`, health check), dokumen ini mengutip baris yang sama dan merujuk kembali, tanpa mengulang analisisnya.

Kecuali disebutkan lain di sebuah bagian, **file qBittorrent di kedua repo identik, hanya berbeda pada rename `Tv*` → `Movie*`**, dengan ketentuan:

| File | Nomor baris |
|---|---|
| `QBittorrent.cs` (746 baris di keduanya) | **cocok satu per satu** |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **identik byte per byte**, cocok satu per satu |
| `QBittorrentSettings.cs` (91 baris di keduanya) | cocok satu per satu |
| `QBittorrentProxyV2.cs`, `QBittorrentProxyV1.cs` | Sonarr punya baris kosong di baris 13 yang tidak ada di Radarr (terverifikasi: Sonarr `:12` adalah komentar `// API https://…`, `:13` kosong, `:14` adalah `public class QBittorrentProxyV2`; deklarasi class di Radarr ada di `:13`). **Baris Sonarr N = baris Radarr N−1 untuk N ≥ 14.** |
| `QBittorrentProxySelector.cs` | sama, mulai dari baris 3 |
| `QBittorrentFixture.cs` | urutannya diubah, bukan digeser; dikutip per repo |

Path-nya adalah `src/NzbDrone.Core/Download/Clients/QBittorrent/...` di kedua repo. Kutipan di bawah memakai nomor baris **Sonarr** kecuali ditandai lain. Diff lengkapnya ada di §9.

Tidak ada yang di sini berupa tebakan tentang qBittorrent itu sendiri: setiap klaim adalah apa yang dilakukan *klien*. Jika klaim menyangkut perilaku qBittorrent sendiri, dokumen ini mengutip `qbittorrent/qBittorrent` master. Jika menyangkut semantik runtime .NET atau Newtonsoft, dokumen ini menyebutkannya secara eksplisit.

## 0. Aturan tingkat transport (ini yang pertama kena) {#0-transport-level-rules-these-bite-first}

### 0.1 Klien memilih v1 atau v2 sebelum melakukan hal lain {#01-the-client-picks-v1-or-v2-before-it-does-anything-else}

`QBittorrentProxySelector.FetchProxy` (`QBittorrentProxySelector.cs:80-95`):

```csharp
if (_proxyV2.IsApiSupported(settings)) { return Tuple.Create(_proxyV2, _proxyV2.GetApiVersion(settings)); }
if (_proxyV1.IsApiSupported(settings)) { return Tuple.Create(_proxyV1, _proxyV1.GetApiVersion(settings)); }
throw new DownloadClientException("Unable to determine qBittorrent API version");
```

`QBittorrentProxyV2.IsApiSupported` (`QBittorrentProxyV2.cs:28-70`) melakukan **tanpa autentikasi**
`GET /api/v2/app/webapiVersion` dengan `SuppressHttpError = true`, lalu memutuskan:

| Response | Result |
|---|---|
| `404` | bukan v2 → lanjut ke v1 |
| `403` | **v2 didukung** (`:44-47`) — ini jawaban "belum login" |
| `401` | `DownloadClientException("Failed to connect to qBittorrent. Check your settings and qBittorrent configuration.")` (`:49-52`) |
| any other `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` (`:54-57`) |
| `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to qBittorrent, certificate validation failed.")` (`:63-66`) |
| `200` | v2 didukung |

`QBittorrentProxyV1.IsApiSupported` (`QBittorrentProxyV1.cs:27-59`) melakukan hal yang sama terhadap
`GET /version/api` — perhatikan **tidak ada `/api/v2` di depannya**, dan 401 *tidak* ditangani secara khusus di sana.

Pasangan `(proxy, version)` disimpan di cache selama **10 menit** dengan kunci `{Host}_{Port}`
(`QBittorrentProxySelector.cs:68-78`). `GetProxy(settings, force: true)` menghapus cache tersebut; tes koneksi melakukan itu
(`QBittorrent.cs:435`, `:519`), dan fixture memverifikasinya (Sonarr `QBittorrentFixture.cs:986-998`, Radarr `:984-996`).

**Sebuah shim sebaiknya menjawab `/api/v2/app/webapiVersion` dan tidak pernah mengekspos rute v1.** v1 adalah API
pra-4.1 (`/version/api`, `/query/torrents`, `/command/download`, …); untuk implementasi baru ini hanya membebani saja, dan
v1 sama sekali tidak bisa memenuhi jalur import, karena `GetLabels` melempar `NotSupportedException("qBittorrent api v1 does not support getting all torrent categories")`
(`QBittorrentProxyV1.cs:236-239`) dan `SetTorrentSeedingConfiguration` tidak melakukan apa-apa (`:241-244`).
Sisa dokumen ini hanya membahas API v2; §1.17 berisi peta rute v1 untuk kelengkapan.

### 0.2 Bentuk URL {#02-url-shape}

`QBittorrentProxyV2.BuildRequest` (`QBittorrentProxyV2.cs:341-359`):

```csharp
var requestBuilder = new HttpRequestBuilder(settings.UseSsl, settings.Host, settings.Port, settings.UrlBase)
{
    LogResponseContent = true,
    StoreRequestCookie = false
};
```

- URL dasar: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-65`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; `UrlBase` akan diberi `/` di depan jika belum ada.
- `Resource("/api/v2/…")` (`HttpRequestBuilder.cs:244-256`) menghapus `/` di depan lalu menambahkannya,
  jadi URL lengkapnya adalah `{scheme}://{host}:{port}{urlBase}/api/v2/{group}/{method}`.
- **Tidak ada header `Accept`.** `BuildRequest` tidak pernah memanggil `.Accept(...)`, dan constructor `HttpRequest` hanya mengatur `Headers.Accept` jika `httpAccept != null`
  (`src/NzbDrone.Common/Http/HttpRequest.cs:14,30-32`). Jangan membatasi logika berdasarkan `Accept`.
- `StoreRequestCookie = false`: cookie dikelola oleh proxy, bukan oleh lapisan HTTP.

### 0.3 GET dengan query vs POST dengan form — dan kapan form berubah jadi multipart {#03-get-with-query-vs-post-with-form--and-when-the-form-becomes-multipart}

Panggilan read-only memakai `AddQueryParam` (`HttpRequestBuilder.cs:306-317`) pada GET. Panggilan yang mengubah data memakai `.Post()` ditambah `AddFormParameter` / `AddFormUpload`.

`ApplyFormData` (`HttpRequestBuilder.cs:150-242`) memilih encoding-nya:

```csharp
var shouldSendAsMultipart = FormData.Any(v => v.ContentType != null || v.FileName != null || v.ContentData.Length > 1024);
```

- Setiap `AddFormUpload` (yang mengatur `FileName` dan `ContentType`) memaksa **`multipart/form-data`**
  (`:379-395`, `:220`).
- **Satu nilai form yang lebih panjang dari 1024 byte juga memaksa multipart** (`:162`). Magnet URI dengan daftar tracker yang panjang melewati batas itu, jadi `POST /api/v2/torrents/add` datang sebagai `application/x-www-form-urlencoded` *atau* `multipart/form-data`, tergantung magnet-nya.
  **Shim harus bisa mem-parse keduanya di rute itu.**
- Selain itu: `application/x-www-form-urlencoded`, nilai di-escape dengan `Uri.EscapeDataString(Encoding.UTF8.GetString(...))` (`:230`).

Writer multipart ditulis sendiri (`:164-227`) dan menulis `Content-Disposition: form-data; name="…"` (ditambah `; filename="…"` dan baris `Content-Type:` untuk upload), satu baris kosong, byte mentah, lalu `\r\n`. Boundary-nya adalah `-----------------------------{ticks:x14}` (`:166`).

**Format boolean itu jebakan.** `AddFormParameter` menyimpan `Convert.ToString(value, CultureInfo.InvariantCulture)` (`HttpRequestBuilder.cs:373`), dan `Convert.ToString(bool)` di .NET menghasilkan **`"True"` / `"False"`, dengan huruf kapital**. Jadi `request.AddFormParameter("stopped", false)` (`QBittorrentProxyV2.cs:258`) mengirim `stopped=False` ke jaringan, bukan `stopped=false`. qBittorrent asli tetap jalan karena `Utils::String::parseBool` (`src/base/utils/string.cpp:108-116`) membandingkan tanpa memperhatikan huruf besar-kecil. **Shim harus menerima `True`/`False` maupun `true`/`false`.** Kalau client menulis string-nya langsung di kode, hurufnya kecil semua — `deleteFiles` berisi `"true"` (`QBittorrentProxyV2.cs:198`) dan `value` dari `setForceStart` berisi `"true"`/`"false"` (`:337`) — jadi kedua penulisan itu memang muncul.

Angka melewati jalur invariant-culture yang sama, jadi `ratioLimit=1.5` selalu memakai `.` sebagai pemisah desimal (`QBittorrentProxyV2.cs:234`, `HttpRequestBuilder.cs:373`).

### 0.4 Autentikasi — tiga lapisan, yang semuanya bisa aktif sekaligus {#04-authentication--three-layers-all-of-which-can-be-live-at-once}

`BuildRequest` (`QBittorrentProxyV2.cs:349-356`):

```csharp
if (settings.ApiKey.IsNotNullOrWhiteSpace())
    requestBuilder.Headers["Authorization"] = $"Bearer {settings.ApiKey}";
else if (settings.Username.IsNotNullOrWhiteSpace() || settings.Password.IsNotNullOrWhiteSpace())
    requestBuilder.NetworkCredential = new BasicNetworkCredential(settings.Username, settings.Password);
```

1. **API key** → `Authorization: Bearer <key>` di setiap request, dan `ProcessRequest` memakai jalur pintas yang tidak pernah login (`:371-395`). `QBittorrentSettingsValidator` melarang username/password dipakai bersama API key (`QBittorrentSettings.cs:16-21`).
2. **Username/password** → `BasicNetworkCredential`, yang diubah oleh `ManagedHttpDispatcher` menjadi header **preemptive** `Authorization: Basic base64(user:pass)` di *setiap* request, termasuk `auth/login` itu sendiri (`src/NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:81-89`, komentar: "Manually set header to avoid initial challenge response").
3. **Cookie session** → `AuthenticateClient` (`QBittorrentProxyV2.cs:430-494`).

`AuthenticateClient`, persis seperti ini:

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

Konsekuensi untuk shim:

- `POST /api/v2/auth/login`, body `username=…&password=…`, `application/x-www-form-urlencoded`.
- Balas dengan **HTTP 200** dan body persis `Ok.` serta header `Set-Cookie: SID=…`. Ini bentuk yang dipakai qBittorrent asli (wiki, *Login*: "Upon success, the response will contain a cookie with your SID").
- **Body kosong juga diterima** (`:479` short-circuit pada `IsNotNullOrWhiteSpace`). Selain itu, seperti `"Fails."`, `"ok"`, atau JSON, dianggap gagal autentikasi. Proxy v1 lebih ketat dan mewajibkan persis `Ok.` (`QBittorrentProxyV1.cs:371`).
- Jika ada error HTTP dari `auth/login`: 401 atau 403 → `DownloadClientAuthenticationException`; selain itu → `DownloadClientException` (`:463-473`). `WebException` → `DownloadClientUnavailableException`.
- Cookie di-cache per `{baseUrl}:{user}:{pass}` selama masa hidup cache entry proses, dan hanya di-refresh saat request mengembalikan 403 (§0.5).
- **`Referer` dan `Origin` tidak pernah dikirim.** Wiki menyarankan konsumen API untuk mengatur keduanya ("Note: Set `Referer` or `Origin` header to the exact same domain and port as used in the HTTP query `Host` header"), tapi Sonarr tidak melakukannya. Shim tidak boleh mewajibkan keduanya.
- Jika **tidak ada kredensial sama sekali**, `AuthenticateClient` langsung return dan tidak mengirim apa pun: tidak ada login, tidak ada cookie, tidak ada `Authorization`. Shim tanpa autentikasi tetap berfungsi.

### 0.5 Status HTTP mana yang dianggap error {#05-which-http-statuses-are-treated-as-errors}

`HttpClient.Execute` (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`) melempar exception saat `response.HasHttpError` bernilai benar, yaitu `(int)StatusCode >= 400` (`src/NzbDrone.Common/Http/HttpResponse.cs:54`), kecuali `SuppressHttpError` diset atau status-nya ada di `SuppressHttpErrorStatusCodes`. 429 menjadi `TooManyRequestsException` (`:115`), dan selebihnya menjadi `HttpException` (`:119`).

`QBittorrentProxyV2.ProcessRequest` (`:369-428`) lalu membungkusnya. Ada dua jalur yang berbeda:

**Jalur API-key** (`:371-395`):

| Status | Hasil |
|---|---|
| 401, 403 | `DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.")` |
| status lain `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` |
| error lain yang dilempar | `DownloadClientException("Failed to connect to qBittorrent, please check your settings.")` |

**Jalur cookie** (`:397-427`):

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

- **403 berarti "sesi sudah habis, login lagi"**. Status ini ditekan satu kali, lalu client login ulang dan mencoba lagi. Ini adalah loop yang muncul dari sesi kedaluwarsa bawaan qBittorrent, dan shim bisa memakainya dengan cara yang sama.
- **Request ulang dibuat dari builder**, dan builder itu tidak membawa `SuppressHttpErrorStatusCodes`. Field tersebut diset pada *request* di `:401`, bukan pada builder. Jadi 403 kedua akan melempar `HttpException` dan muncul sebagai `DownloadClientException("Failed to connect to qBittorrent, check your settings.")`, **bukan** kegagalan autentikasi. Shim yang selalu menjawab 403 akan menghasilkan error koneksi yang membingungkan di UI, bukan "Authentication Failure".
- Jika tidak ada kredensial yang dikonfigurasi, percobaan login ulang di `:411` langsung melempar `DownloadClientAuthenticationException` (`:434-437`).

**Setiap panggilan yang sukses harus HTTP 200 dengan body persis seperti yang diharapkan client.** API ini tidak punya amplop JSON untuk error di mana pun. Berbeda dengan SAB, error di sini selalu berupa status HTTP.

### 0.6 Pengaturan deserializer {#06-deserializer-settings}

Semua payload qBittorrent melewati `NzbDrone.Common.Serializer.Json` (`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`), yaitu **Newtonsoft**, instance yang sama dengan yang dipakai client SAB. Jadi [sabnzbd-client-contract.md §0.3](sabnzbd-client-contract.md) berlaku sama persis:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Artinya untuk model qBittorrent:

| Anggota model | Terikat ke | Alasan |
|---|---|---|
| `QBittorrentTorrent.Hash/Name/Size/Progress/Eta/State/Label/Category/Ratio` | `hash`, `name`, `size`, `progress`, `eta`, `state`, `label`, `category`, `ratio` | resolver camelCase; Newtonsoft juga mencocokkan tanpa membedakan huruf besar-kecil |
| `SavePath`, `ContentPath`, `RatioLimit`, `SeedingTime`, `SeedingTimeLimit`, `InactiveSeedingTimeLimit`, `LastActivity` | `save_path`, `content_path`, `ratio_limit`, `seeding_time`, `seeding_time_limit`, `inactive_seeding_time_limit`, `last_activity` | `[JsonProperty]` eksplisit (`QBittorrentTorrent.cs:24-45`) |
| `QBittorrentLabel.Name/SavePath` | `name`, `savePath` | **tanpa** `[JsonProperty]`, pakai resolver camelCase. `torrents/categories` di qBittorrent memang memakai camelCase di sini, berbeda dengan endpoint lain |
| `QBittorrentPreferences.*` | semua `[JsonProperty]` eksplisit dalam snake_case (`QBittorrentPreferences.cs:16-44`) | |
| `QBittorrentMaxRatioAction` | `max_ratio_act` | tidak ada converter per-properti, jadi `StringEnumConverter` global yang berlaku. `AllowIntegerValues` default-nya true, jadi **kirim integer**, seperti yang dilakukan qBittorrent asli. String harus camelCase (`"pause"`, `"remove"`), dan nama yang tidak dikenal akan throw |

`NullValueHandling.Ignore` juga berlaku saat **membaca**: JSON `null` membiarkan member tetap pada nilai dari constructor-nya. Digabung dengan default yang dideklarasikan di model, field yang **tidak ada atau null** tidak sama dengan nol:

| Field | Default jika tidak ada/null | Referensi |
|---|---|---|
| `ratio_limit` | `-2f` | `QBittorrentTorrent.cs:33` |
| `seeding_time_limit` | `-2` | `:39` |
| `inactive_seeding_time_limit` | `-2` | `:42` |
| `seeding_time` | `null` (`long?`) | `:36` |
| `queueing_enabled` | **`true`** | `QBittorrentPreferences.cs:41` |
| lainnya | CLR default (`0`, `false`, `null`) | |

`Eta` adalah `System.Numerics.BigInteger` (`QBittorrentTorrent.cs:17`, dengan komentar "QBit contains a bug exceeding ulong limits"). Fixture Sonarr memastikan `18446744073709335000` tetap bisa di-parse (Sonarr `QBittorrentFixture.cs:974-984`, Radarr `:973-982`).

`Json.Deserialize<T>` melempar ulang `JsonReaderException` dengan pesan yang lebih rapi (`Json.cs:39-50`). Tidak ada panggilan proxy qBittorrent yang memakai `TryDeserialize`, jadi **body yang rusak atau bentuknya salah akan throw keluar dari proxy** dan menjadi unhandled exception di tempat pemanggilan. Untuk `GetItems()`, itu menghentikan seluruh poll.

### 0.7 Setiap gerbang `version >=`, dalam satu tempat {#07-every-version--gate-in-one-place}

`ProxyApiVersion` adalah `_proxySelector.GetApiVersion(Settings)` (`QBittorrent.cs:50`), yaitu cache dari `app/webapiVersion`. Gate-gatenya:

| Gate | Lokasi | Efek di bawah ambang |
|---|---|---|
| `>= 1.5` | `QBittorrent.cs:436` | Test gagal: "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| `>= 1.6` | `:445` | Test gagal jika kategori dikonfigurasi: "Category is not supported" |
| `>= 2.0` | `:379` (`GetStatus`), `:520` (`TestCategory`) | `savePath` kategori tidak dibaca, dan kategori tidak dicek maupun dibuat |
| `>= 2.6.1` | `:314` | `OutputPath` **tidak** diambil dari `content_path`; `GetImportItem` malah membaca `torrents/files` (§4.2) |
| `>= 2.8.1` | `:79`, `:136` | batas share tidak bisa ikut di `torrents/add`; batas itu diterapkan setelahnya dengan `torrents/setShareLimits` |
| `>= 2.11.0` | `QBittorrentProxyV2.cs:253` | `torrents/add` mengirim `paused=` sebagai ganti `stopped=` |

`Version.Parse` (`QBittorrentProxyV2.cs:75`) butuh **minimal `major.minor`**. Angka `"2"` saja akan melempar `FormatException`, dan exception itu dilempar di luar setiap `try` di proxy, jadi lolos begitu saja dari `GetApiVersion`. Isi sesuatu seperti `2.11.2`.

**Nilai yang disarankan untuk shim: `2.11.2`.** Nilai ini melewati semua gate, menaruh `content_path` di jalur `torrents/info` (satu-satunya rute impor yang masuk akal), dan memilih penulisan `stopped=` dari qBittorrent 5.x saat add.

## 1. Setiap endpoint, sesuai urutan yang dipanggil klien {#1-every-endpoint-in-the-order-the-client-calls-them}

Antarmuka: `IQBittorrentProxy` (`QBittorrentProxySelector.cs:9-30`). Implementasinya: `QBittorrentProxyV2`. Setiap pemanggilan di `QBittorrent.cs` tercantum di `:49-741`.

### 1.1 `GET /api/v2/app/webapiVersion` — `GetApiVersion` (`QBittorrentProxyV2.cs:72-78`)

Permintaan: tanpa parameter. Dikirim tanpa autentikasi dulu (sebagai probe, §0.1), baru kemudian dengan autentikasi.

Respons: **teks biasa**, string versi yang di-parse oleh `Version.Parse`. Bukan JSON, tanpa tanda kutip.

Dipanggil oleh: probe proxy (`:31`), `GetItems` (`QBittorrent.cs:220`), `GetStatus` (`:374`),
`TestConnection` (`:435`), `TestCategory` (`:519`), dan — yang gampang terlewat — 
`AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:253`). Artinya **setiap `torrents/add` didahului oleh round trip `app/webapiVersion`-nya sendiri** kalau status awalnya Start atau Stop (jadi hampir selalu, kecuali user memilih Force Start).

### 1.2 `GET /api/v2/app/version` — `GetVersion` (`QBittorrentProxyV2.cs:80-87`)

Response: teks biasa, `v` di depan dihapus (`:83`). Komentar: `// eg "4.2alpha"`.

**Tidak pernah dipanggil.** Method ini ada di interface (`QBittorrentProxySelector.cs:13`) tapi tidak ada yang memanggilnya di `QBittorrent.cs` (sudah dicek terhadap setiap referensi `Proxy.` dan `_proxySelector.`, `:49-741`). Tetap implementasikan — tidak ada ruginya, dan orang yang mengutak-atik shim ini kemungkinan akan mencarinya.

### 1.3 `POST /api/v2/auth/login`

Dijelaskan di §0.4. Formulir: `username`, `password`. Jawabannya `200` + `Ok.` + `Set-Cookie: SID=…`.

### 1.4 `GET /api/v2/app/preferences` — `GetConfig` (`QBittorrentProxyV2.cs:89-95`)

Request: tanpa parameter. Response: satu objek JSON, di-deserialize ke `QBittorrentPreferences`.

**Setiap kunci yang dibaca client** (`QBittorrentPreferences.cs:14-45`). Bagian lain dari body tidak dibaca, dan kunci ekstra diabaikan:

| Kunci JSON | C# | Tipe | Dibaca oleh |
|---|---|---|---|
| `save_path` | `SavePath` | `string` | `GetStatus` → `OutputRootFolders` (`QBittorrent.cs:377`) |
| `max_ratio_enabled` | `MaxRatioEnabled` | `bool` | `HasReachedSeedLimit` (`:639`), `RemovesCompletedDownloads` (`:415`) |
| `max_ratio` | `MaxRatio` | `float` | `HasReachedSeedLimit` (`:641`) |
| `max_seeding_time_enabled` | `MaxSeedingTimeEnabled` | `bool` | `HasReachedSeedingTimeLimit` (`:663`), `RemovesCompletedDownloads` (`:415`) |
| `max_seeding_time` | `MaxSeedingTime` | `long`, **menit** | `:665`, `:415` |
| `max_inactive_seeding_time_enabled` | `MaxInactiveSeedingTimeEnabled` | `bool` | `HasReachedInactiveSeedingTimeLimit` (`:727`) |
| `max_inactive_seeding_time` | `MaxInactiveSeedingTime` | `long`, **menit** | `:729` |
| `max_ratio_act` | `MaxRatioAction` | enum sebagai int: `Pause=0, Remove=1, EnableSuperSeeding=2, DeleteFiles=3` (`QBittorrentPreferences.cs:5-11`) | `RemovesCompletedDownloads` (`:415`) |
| `queueing_enabled` | `QueueingEnabled` | `bool`, **default `true`** | `TestPrioritySupport` (`:572`) |
| `dht` | `DhtEnabled` | `bool` | `AddFromMagnetLink` (`:73`), cabang `metaDL` (`:288`) |

Dipanggil oleh: `AddFromMagnetLink` (`:73`), `GetItems` (`:221`), `GetStatus` (`:375`), `TestConnection`
(`:467`), `TestPrioritySupport` (`:570`). Data ini **tidak** di-cache, jadi diambil ulang setiap kali polling.

`RemovesCompletedDownloads` (`QBittorrent.cs:412-416`) adalah flag turunan:

```csharp
var minimumRetention = 60 * 24 * 14; // 14 days in minutes
return (config.MaxRatioEnabled || (config.MaxSeedingTimeEnabled && config.MaxSeedingTime < minimumRetention))
    && (config.MaxRatioAction == QBittorrentMaxRatioAction.Remove || config.MaxRatioAction == QBittorrentMaxRatioAction.DeleteFiles);
```

Flag ini dipakai untuk tes koneksi (`:468`) dan health check
`DownloadClientRemovesCompletedDownloadsCheck` (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:44-53`). Dengan
`max_ratio_enabled: false` dan `max_seeding_time_enabled: false`, nilainya tetap false apa pun isi `max_ratio_act`, tapi tetap kirim `max_ratio_act: 0`.

### 1.5 `GET /api/v2/torrents/categories` — `GetLabels` (`QBittorrentProxyV2.cs:221-225`)

**Request:** tanpa parameter.

**Response:** sebuah **objek** JSON, `{"<name>": {"name": "...", "savePath": "..."}}`, yang di-deserialize ke `Dictionary<string, QBittorrentLabel>`. Perhatikan **`savePath` dalam camelCase**, sesuai §0.6 dan contoh *Get all categories* di wiki. Jika yang dikembalikan array, akan error.

Baca untuk dua hal:

1. `TestCategory` (`QBittorrent.cs:525-553`) hanya untuk memeriksa keberadaan key (§6.3).
2. `GetStatus` (`:379-402`): `savePath` dari kategori yang dikonfigurasi menjadi root folder output download client:

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

`savePath` yang **relatif** akan ditambahkan ke `save_path` global; yang berupa path absolut akan menggantikannya. `savePath` yang diawali `//` akan diubah menjadi path UNC dengan backslash. Fixture Sonarr memastikan `"//server/store/downloads"` menjadi `\\server\store\downloads` (Sonarr `QBittorrentFixture.cs:563-589`, Radarr `:562-588`). **Jangan pernah mengeluarkan `//` di awal.** Jawaban paling aman adalah `"savePath": ""`, yang membiarkan root folder mengikuti `save_path` global.

### 1.6 `POST /api/v2/torrents/createCategory` — `AddLabel` (`QBittorrentProxyV2.cs:213-219`)

Form: `category=<name>`. **`savePath` tidak dikirim** — klien tidak pernah mengatur save path untuk kategori.
Isi response diabaikan; yang penting hanya status yang tidak error.

Dipanggil hanya dari `TestCategory` (`QBittorrent.cs:529`, `:543`), saat kategorinya belum ada.
`torrents/editCategory` dan `torrents/removeCategories` **tidak pernah dipanggil**.

### 1.7 `POST /api/v2/torrents/add` — `AddTorrentFromUrl` / `AddTorrentFromFile`

`AddTorrentFromUrl` (`QBittorrentProxyV2.cs:146-166`): field form **`urls`** = URI magnet.
`AddTorrentFromFile` (`:168-188`): unggahan form **`torrents`**, nama file
`{CleanFileName(release title)}.torrent` (`TorrentClientBase.cs:199`),
`Content-Type: application/octet-stream` (`HttpRequestBuilder.cs:379`).

Keduanya lalu menambahkan `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:243-284`):

| Field form | Nilai | Kondisi | Baris |
|---|---|---|---|
| `category` | `Settings.TvCategory` / `MovieCategory` | category tidak kosong | `:245-248` |
| `stopped` (webapi `>= 2.11.0`) atau `paused` (di bawahnya) | `False` untuk Start, `True` untuk Stop | `InitialState` adalah Start atau Stop — **Force Start tidak mengirim keduanya** | `:251-264` |
| `sequentialDownload` | `True` | setting `SequentialOrder` aktif | `:266-269` |
| `firstLastPiecePrio` | `True` | setting `FirstAndLast` aktif | `:271-274` |
| `contentLayout` | `"Original"` atau `"Subfolder"` | setting `ContentLayout` adalah Original atau Subfolder; **Default tidak mengirim apa pun** | `:276-283` |

dan, jika share limit diatur *dan* webapi `>= 2.8.1` (`QBittorrent.cs:79`, `:136`),
`AddTorrentSeedingFormParameters(request, seedConfiguration)` (`QBittorrentProxyV2.cs:227-241`) juga dipanggil:

| Field form | Nilai | Kondisi |
|---|---|---|
| `ratioLimit` | `seedConfiguration.Ratio` atau `-2` | hanya jika bukan `-2` (`:232`) |
| `seedingTimeLimit` | `seedConfiguration.SeedTime.TotalMinutes` atau `-2` | hanya jika bukan `-2` (`:237`) |

**Semua parameter lain yang didokumentasikan wiki untuk `torrents/add` tidak pernah dikirim**: tidak ada `savepath`, tidak ada `cookie`,
tidak ada `tags`, tidak ada `skip_checking`, tidak ada `root_folder`, tidak ada `rename`, tidak ada `upLimit`, tidak ada `dlLimit`, tidak ada
`autoTMM`. Tidak ada parameter `priority` saat add — prioritas antrean adalah panggilan `topPrio` terpisah (§1.10).

Penanganan respons (`:159-165`, `:181-187`):

```csharp
var result = ProcessRequest(request, settings);
// Note: Older qbit versions returned nothing, so we can't do != "Ok." here.
if (result == "Fails.") { throw new DownloadClientException("Download client failed to add torrent by url"); }
```

Jadi: **200 dengan body apa pun selain `Fails.` berarti sukses.** `Ok.` adalah jawaban yang lazim.
HTTP 415 (yang di wiki disebut "torrent file is not valid") menjadi `DownloadClientException` lewat `:389`.

**ID download tidak berasal dari panggilan ini.** ID itu dihitung di sisi klien, sebelum request dikirim:

- magnet → `MagnetLink.Parse(magnetUrl).InfoHash.ToHex()` (`TorrentClientBase.cs:224`)
- `.torrent` → `_torrentFileInfoReader.GetHashFromTorrentFile(torrentFile)` (`:200`)

Dan `AddFromMagnetLink` / `AddFromTorrentFile` mengembalikan `hash` yang sama tanpa diubah (`QBittorrent.cs:130`, `:187`). **Shim harus menyimpan torrent dengan infohash persis itu**, kalau tidak Sonarr kehilangan jejak grab — `TorrentClientBase.cs:206-212` dan `:238-244` hanya mencatat baris Debug tentang hal ini.
Prasyarat DHT dicek lebih dulu untuk magnet:

```csharp
if (!Proxy.GetConfig(Settings).DhtEnabled && !magnetLink.Contains("&tr="))
    throw new NotSupportedException("Magnet Links without trackers not supported if DHT is disabled");   // :73-76
```

yang oleh pemanggil diubah menjadi `ReleaseDownloadException("Magnet not supported by download client…")` jika tidak ada fallback `.torrent` (`TorrentClientBase.cs:111-119`). **Laporkan `dht: true`.**

Setelah add, `WaitForTorrent` (`QBittorrent.cs:190-214`) memanggil `IsTorrentLoaded` **10 kali dengan jeda 100 ms** — tapi hanya kalau ada pekerjaan lanjutan (share limit setelah add, top priority, atau force start; `:86`, `:143`). Pesan gagalnya bilang "within 500 ms", padahal loop-nya sebenarnya 10 × 100 ms; bagaimanapun juga, ia menyerah dan mengembalikan hash (`:212-213`).

### 1.7a Berapa lama klien menunggu `torrents/add` — **100 detik**, diukur 2026-08-30 {#17a-how-long-the-client-waits-for-torrentsadd--100-seconds-measured-2026-08-30}

Dibaca dari `Sonarr/Sonarr@32a5d492` dan `Radarr/Radarr@40bb746c` (keduanya `develop`) pada 2026-08-30. Ini membatasi semua yang dilakukan shim secara sinkron di dalam panggilan add, jadi layak dikutip daripada diasumsikan.

Tidak ada yang di jalur qBittorrent mengatur timeout, jadi nilainya turun melalui empat lapisan ke angka tetap 100 s:

| Langkah | Sonarr `path:line` | Radarr `path:line` | Yang dilakukannya |
|---|---|---|---|
| panggilan add | `QBittorrentProxyV2.cs:146-150`, `:168-172` | `:145-149`, `:167-171` | membangun request, tidak mengatur timeout |
| builder | `NzbDrone.Common/Http/HttpRequestBuilder.cs:104-116` | file yang sama `:104-116` | `Apply()` tidak punya baris `RequestTimeout`, dan class-nya tidak punya properti seperti itu |
| default field | `NzbDrone.Common/Http/HttpRequest.cs:52` | `:54` | auto-property tidak pernah diisi di constructor, jadi `TimeSpan.Zero` |
| dispatcher | `NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:70-79` | `:68-77` | `Zero` menjadi `cts.CancelAfter(TimeSpan.FromSeconds(100))` |

```csharp
using var cts = new CancellationTokenSource();
if (request.RequestTimeout != TimeSpan.Zero) { cts.CancelAfter(request.RequestTimeout); }
else { /* The default for System.Net.Http.HttpClient */ cts.CancelAfter(TimeSpan.FromSeconds(100)); }
```

`RequestTimeout` dan `Timeout` tidak muncul di mana pun di bawah `src/NzbDrone.Core/Download/Clients/QBittorrent/` di kedua repo, dan `HttpRequestBuilder` tidak menyediakan cara untuk mengaturnya. Jadi shim tidak bisa diberi waktu lebih lama lewat konfigurasi.

Ada lima hal yang bisa disimpulkan dari sini.

- **100 s itu token pembatalan milik Sonarr sendiri, bukan timer .NET.** Handler di bawahnya dibuat dengan `Timeout = Timeout.InfiniteTimeSpan` (`ManagedHttpDispatcher.cs:183` Sonarr, `:180` Radarr), jadi token itulah satu-satunya batas. Token ini diteruskan ke `SendAsync` dan `ReadAsByteArrayAsync` (`:115`, `:127`), artinya token ini mencakup koneksi, isi request, header response, dan isi response.
- **Timeout dilaporkan ke pengguna sebagai masalah koneksi.** Saat waktu habis, dilempar `new WebException("Http request timed out", …)` (`:142-145`), yang dibungkus `ProcessRequest` menjadi `DownloadClientException("Failed to connect to qBittorrent, please check your settings.", ex)` (`QBittorrentProxyV2.cs:424-427`). Jadi shim yang memblokir lebih dari 100 s akan terlihat seperti salah konfigurasi, bukan lambat, dan *arr tidak pernah tahu bahwa add masih berjalan.
- **Tidak ada connect timeout terpisah dan tidak ada anggaran lebih besar untuk upload multipart.** `SocketsHttpHandler.ConnectTimeout` tidak pernah diatur. Satu-satunya pengecualian adalah batas 2 s untuk percobaan IPv6 pertama selama proses berjalan (`ManagedHttpDispatcher.cs:23`, `:288-295`), yang lalu lanjut ke IPv4 dalam 100 s yang sama. File `.torrent` yang diunggah disimpan utuh di dalam byte array (`HttpRequestBuilder.cs:220-221`, `ManagedHttpDispatcher.cs:103`) dan dikirim dengan token yang sama.
- **Ada 300 s, tapi itu jalur yang berbeda.** `HttpClient.cs:285` mengatur `request.RequestTimeout = TimeSpan.FromSeconds(300)` di dalam `DownloadFileAsync`, yang mengambil file `.torrent` dari indexer. Nilai itu tidak pernah sampai ke panggilan download client.
- **Deluge membuktikan bahwa override itu ada, dan qBittorrent tidak memakainya.** `DelugeProxy.cs:222` melakukan `requestBuilder.PostProcess += r => r.RequestTimeout = TimeSpan.FromSeconds(15)`. `BuildRequest` milik qBittorrent tidak punya baris seperti itu, dan ini bukti langsung bahwa 100 s itu diwarisi, bukan dipilih.

**Radarr identik.** Perbandingan blok timeout (Radarr `:68-78` dengan Sonarr `:70-80`) menghasilkan byte yang sama persis. Satu-satunya perbedaan dalam rantai ini adalah Radarr meneruskan `ex`, sedangkan Sonarr meneruskan `ex.InnerException` ke `WebException`.

**Konsekuensi untuk shim.** Setiap keputusan sinkron yang diambil di dalam `torrents/add` memakai satu anggaran 100 s yang sama, dan *arr tidak punya cara untuk membedakan "masih bekerja" dari "tidak bisa dijangkau". Batas waktu per percobaan dikali jumlah provider yang dicoba, ditambah jendela probe cached-only apa pun, harus tetap jauh di bawah 100 s. Latensi provider yang dipakai untuk menyusun anggaran itu ada di [torrent-lifecycle.md](torrent-lifecycle.md).

Satu catatan tambahan. 100 s berlaku per panggilan dispatcher, jadi setiap hop dalam rantai auto-redirect mendapat anggaran baru (`HttpClient.cs:43` membatasi rantai hingga 5). Strategi retry di `DownloadClientBase.cs:30-44` **tidak** berlaku di sini. Strategi itu hanya dipakai saat mengambil file `.torrent` dari indexer (`TorrentClientBase.cs:142-144`).

### 1.8 `GET /api/v2/torrents/properties?hash=<hash>` — `IsTorrentLoaded` / `GetTorrentProperties`

`IsTorrentLoaded` (`QBittorrentProxyV2.cs:110-126`) memanggilnya dengan `LogHttpError = false` dan menganggap **semua** exception sebagai "belum loaded".

`GetTorrentProperties` (`:128-135`) melakukan deserialisasi ke `QBittorrentTorrentProperties` (`QBittorrentTorrent.cs:48-57`). **Ada tiga field, dan hanya dua yang dipakai**:

| JSON key | C# | Dipakai untuk |
|---|---|---|
| `hash` | `Hash` | dibaca, tapi tidak pernah dipakai |
| `save_path` | `SavePath` | jalur `GetImportItem` untuk versi pra-2.6.1 (`QBittorrent.cs:354`) |
| `seeding_time` | `SeedingTime` (`long`, **detik**) | `FetchTorrentDetails` (`:739-744`) |

**Penulisan huruf hash di sini tidak konsisten, dan ini penting.** Pemanggilan lain selalu mengubah hash ke huruf kecil (`item.DownloadId.ToLower()` di `:335`, `:346`, `:353`; `hash.ToLower()` di `:97`, `:109`, `:121`, `:198`), tapi `FetchTorrentDetails` meneruskan `torrent.Hash` apa adanya (`:741`), yaitu apa pun yang dikirim shim di `torrents/info`. qBittorrent asli selalu mengembalikan hash huruf kecil, jadi masalah ini tidak pernah muncul di sana. Fixture Sonarr memastikan perbedaan ini dengan me-mock `GetTorrentProperties("HASH", …)` memakai nilai huruf besar (Sonarr `QBittorrentFixture.cs:669-675`, Radarr `:668-674`). **Kembalikan hash huruf kecil dari `torrents/info`, dan cocokkan `?hash=` tanpa membedakan huruf besar dan kecil.**

`FetchTorrentDetails` hanya dipanggil dari `HasReachedSeedingTimeLimit` (`:700`), dan itu hanya terjadi kalau batas seeding-time memang aktif. Jadi shim yang tidak menerapkan batas seeding-time sama sekali tidak akan pernah melihat pemanggilan ini saat polling. Meski begitu, fungsi ini tetap dibutuhkan untuk `IsTorrentLoaded`, yaitu probe kesiapan setelah add: **404 untuk hash yang tidak dikenal, 200 + JSON untuk hash yang dikenal.**

Hasilnya di-cache selama 5 menit per `{Host}{Port}{Hash}` (`:678`, `:689`, `:695`, `:708`). Fixture juga memastikan data itu hanya diambil sekali, bukan dua kali, di antara dua polling (Sonarr `QBittorrentFixture.cs:905-920`, Radarr `:904-919`).

### 1.9 `POST /api/v2/torrents/setShareLimits` — `SetTorrentSeedingConfiguration` (`:286-308`)

Form: `hashes=<lowercase hash>`, lalu `AddTorrentSeedingFormParameters(request, seedConfiguration, always: true)`
— dengan `always: true`, **kedua** `ratioLimit` dan `seedingTimeLimit` selalu dikirim, meskipun nilainya `-2` (`:232`, `:237`). `inactiveSeedingTimeLimit` tidak pernah dikirim.

Error **404** diabaikan (`:298-307`, komentar: "setShareLimits was added in api v2.0.1"). Error lain diteruskan, tetapi titik pemanggilan menangkapnya dan mencatat warning (`QBittorrent.cs:95-102`, `:152-159`).

Route ini hanya dipanggil saat indexer memberikan konfigurasi seed *dan* webapi `< 2.8.1`. Pada shim yang melaporkan `2.11.2`, share limits dikirim lewat `torrents/add` dan route ini tidak pernah dipakai untuk grab. Implementasikan sebagai no-op yang mengembalikan 200.

### 1.10 `POST /api/v2/torrents/topPrio` — `MoveTorrentToTopInQueue` (`:310-330`)

Form: `hashes=<lowercase hash>`.

Error **409 Conflict** akan diabaikan (`:320-329`, komentarnya: "qBittorrent rejects all Prio commands with 409:
Conflict if Options -> BitTorrent -> Torrent Queueing is not enabled"). Proxy v1 mengabaikan **403**
sebagai gantinya (`QBittorrentProxyV1.cs:255-264`). Error lain akan ditangkap dan dicatat sebagai peringatan di tempat pemanggilan
(`QBittorrent.cs:107-114`, `:164-171`). Fixture memastikan bahwa kegagalan di sini tidak menggagalkan grab
(Sonarr `QBittorrentFixture.cs:525-542`, Radarr `:524-541`).

Fungsi ini hanya dipanggil saat pengaturan prioritas Recent/Older diatur ke `First` (`QBittorrentPriority.First = 1`,
`QBittorrentPriority.cs:5-6`). Nilai default-nya adalah `Last = 0`.

### 1.11 `POST /api/v2/torrents/setForceStart` — `SetForceStart` (`:332-339`)

Form: `hashes=<lowercase hash>`, `value=true` (string huruf kecil harfiah, `:337`).

Ini hanya dipanggil saat `InitialState` adalah `ForceStart` (`QBittorrentState.cs:10-11`, `QBittorrent.cs:82`, `:117-127`). Error ditangkap dan dicatat sebagai peringatan (`:123-126`).

### 1.12 `GET /api/v2/torrents/info[?category=<cat>]` — `GetTorrents` (`:97-108`)

**Satu-satunya parameter yang pernah dikirim adalah `category`, dan hanya jika pengaturannya tidak kosong**
(`:100-103`). Tidak ada `filter`, `hashes`, `sort`, `reverse`, `limit`, `offset`, atau `tag`.
Client ini **tidak** memfilter ulang berdasarkan category setelahnya, berbeda dengan client SAB yang
memfilter dua kali. Jadi shim yang mengabaikan `category` akan memberi Radarr torrent milik Sonarr.

Field `category` di response penting karena alasan kedua: torrent yang **tidak punya riwayat grab** di \*arr akan dilewati begitu saja, kecuali torrent itu membawa salah satunya:
`CompletedDownloadService.Check` (`CompletedDownloadService.cs:84-88`):

```csharp
if (historyItem == null && trackedDownload.DownloadItem.Category.IsNullOrWhiteSpace())
{
    trackedDownload.Warn("Download wasn't grabbed by Sonarr and not in a category, Skipping.");
    return;
}
```

`Category` adalah `category` jika tidak kosong, jika tidak maka `label` (`QBittorrent.cs:231`).

Response: sebuah **array** JSON. Setiap field yang dibaca, dan hasilnya:

| Kunci JSON | Tipe C# | Satuan | Menjadi |
|---|---|---|---|
| `hash` | `string` | | `DownloadId = torrent.Hash.ToUpper()` (`QBittorrent.cs:230`) — **dijadikan huruf besar**, dan dikirim kembali dalam huruf kecil pada setiap panggilan berikutnya |
| `name` | `string` | | `Title = torrent.Name` (`:232`) — lihat §7.1 untuk semua yang dipengaruhinya |
| `size` | `long` | byte | `TotalSize` (`:233`); juga `RemainingSize = (long)(size * (1.0 - progress))` (`:235`) |
| `progress` | `double` | 0..1 | `RemainingSize` (`:235`) |
| `eta` | `BigInteger` | detik | `RemainingTime` lewat `GetRemainingTime` (`:236`, `:614-628`) |
| `state` | `string` | | `Status`, `Message`, dan separuh gerbang `CanMoveFiles` (`:242-312`) — §2 |
| `category` | `string` | | `Category`, diutamakan (`:231`) |
| `label` | `string` | | `Category`, cadangan jika `category` kosong (`:231`). Field versi lama sebelum 3.3.5; qBittorrent 5 tidak mengirimkannya |
| `ratio` | `float` | | `SeedRatio` (`:237`), `HasReachedSeedLimit` (`:634`, `:641`) |
| `ratio_limit` | `float`, default `-2` | | `HasReachedSeedLimit` (`:632-645`) |
| `seeding_time_limit` | `long`, default `-2` | **menit** | `HasReachedSeedingTimeLimit` (`:659-670`) |
| `inactive_seeding_time_limit` | `long`, default `-2` | **menit** | `HasReachedInactiveSeedingTimeLimit` (`:723-736`) |
| `last_activity` | `long` | **detik unix** | `HasReachedInactiveSeedingTimeLimit` (`:736`) |
| `seeding_time` | `long?`, default null | detik | `HasReachedSeedingTimeLimit` (`:672-676`) — komentar di `QBittorrentTorrent.cs:36` menyebut field ini "tidak disediakan oleh list api", tetapi client tetap memakainya jika ada, sehingga menghemat satu round trip `torrents/properties` |
| `save_path` | `string` | | dibandingkan dengan `content_path` (`:316`) |
| `content_path` | `string` | | `OutputPath` pada webapi `>= 2.6.1` (`:318`) — §4 |

`GetRemainingTime` (`:614-628`):

```csharp
if (torrent.Eta < 0 || torrent.Eta > 365 * 24 * 3600) { return null; }   // > 31,536,000 s
if (torrent.Eta == 8640000) { return null; }                            // qBittorrent's "unknown"
return TimeSpan.FromSeconds((int)torrent.Eta);
```

dan item yang Completed akan dipaksa `RemainingTime` menjadi `TimeSpan.Zero` setelahnya (`:273`).

`torrents/info` diambil pada setiap `RefreshMonitoredDownloads`
(`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:94`), yang juga di-debounce ke antrean perintah 5 detik setelah event terkait (`:53`).

### 1.13 `GET /api/v2/torrents/files?hash=<hash>` — `GetTorrentFiles` (`:137-144`)

Respons: sebuah JSON array yang di-deserialize ke `List<QBittorrentTorrentFile>`, yang hanya punya **satu member**: `Name` (`QBittorrentTorrent.cs:59-62`), yang di-bind ke `name`. Isinya path file **relatif terhadap save path**, dengan pemisah `/` di semua OS ("QBittorrent returns `/` path separators even on windows", `QBittorrent.cs:358`).

Hanya dipanggil dari `GetImportItem` (`:346`) dan hanya ketika `OutputPath` masih kosong, yaitu pada webapi `< 2.6.1`, atau ketika `content_path` kembali kosong. `index`, `size`, `progress`, `priority`, `is_seed`, `piece_range` dan `availability` semuanya diabaikan.

Array kosong juga ditangani: `_logger.Debug("No files found for torrent {0} in qBittorrent")` dipanggil dan item dikembalikan tanpa perubahan (`:347-351`). Akibatnya item itu gagal di `ValidatePath`.

(Terjemahan sebelumnya ditolak: code span-nya berbeda (`ValidatePath`). Pertahankan struktur persis.)

### 1.14 `POST /api/v2/torrents/setCategory` — `SetTorrentLabel` (`:204-211`)

Form: `hashes=<lowercase hash>`, `category=<post-import category>`.

Dipanggil hanya dari `MarkItemAsImported` (`QBittorrent.cs:52-69`), dan hanya saat pengaturan opsional
`TvImportedCategory` / `MovieImportedCategory` tidak kosong dan berbeda dari kategori utama. Jika terjadi `DownloadClientException`, error itu ditangkap dan ditampilkan sebagai peringatan:
"Failed to set post-import torrent label \"{0}\" for {1} in qBittorrent. Does the label exist?"
(`:62-67`). §5.1.

### 1.15 `POST /api/v2/torrents/delete` — `RemoveTorrent` (`:190-202`)

Formatnya: `hashes=<lowercase hash>`, plus `deleteFiles=true` **hanya ketika `removeData` bernilai true**
(`:196-199`). Nilainya string huruf kecil literal, bukan `Convert.ToString(bool)`.

`QBittorrent.RemoveItem` (`:333-336`) adalah seluruh implementasinya:

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    Proxy.RemoveTorrent(item.DownloadId.ToLower(), deleteData, Settings);
}
```

**Fungsi ini tidak memanggil `DeleteItemData`.** Di sinilah bedanya dengan klien SAB, yang menghapus folder job sendiri lewat filesystem
(`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`; lihat [sabnzbd-client-contract.md §5.3](sabnzbd-client-contract.md)). Di sini, penghapusan data sepenuhnya menjadi tugas download client. §5.

### 1.16 Endpoint yang tidak pernah disentuh klien {#116-endpoints-the-client-never-touches}

Tidak ada di interface sama sekali, jadi tidak pernah dipanggil: `torrents/pause`, `torrents/resume`, `torrents/stop`,
`torrents/start`, `torrents/setLocation`, `torrents/rename`, `torrents/recheck`,
`torrents/reannounce`, `torrents/filePrio`, `torrents/setDownloadLimit`, `torrents/setUploadLimit`,
`torrents/toggleSequentialDownload`, `torrents/setAutoManagement`, `torrents/editCategory`,
`torrents/removeCategories`, tag, RSS, pencarian, `app/setPreferences`, `app/defaultSavePath`,
`app/shutdown`, `sync/maindata`, `transfer/*`, `auth/logout`. Pause dan resume hanya ada sebagai field form `paused=`/`stopped=` pada `torrents/add`.

Ada di interface tapi tidak pernah dipanggil dari `QBittorrent.cs`: `GetVersion` (§1.2).

### 1.17 Peta rute v1 (untuk kelengkapan; jangan diimplementasikan) {#117-the-v1-route-map-for-completeness-do-not-implement}

`QBittorrentProxyV1.cs`: `/version/api` (`:30`, `:64`. Klien menambahkan awalan `"1."` pada apa pun yang dikembalikan, `:65`), `/version/qbittorrent` (`:73`), `/query/preferences` (`:81`),
`/query/torrents?label=&category=` (`:89-94`. **Kedua** parameter), `/query/propertiesGeneral/{hash}`
(`:103`, `:120`), `/query/propertiesFiles/{hash}` (`:128`), `/command/download` (`:136`),
`/command/upload` (`:166`), `/command/delete` atau `/command/deletePerm` (`:196`. Pembedaan delete/deleteFiles adalah dua rute yang berbeda, bukan parameter), `/command/setCategory` dengan cadangan `/command/setLabel` jika terjadi 404 (`:205-225`), `/command/addCategory` (`:230`),
`/command/topPrio` (`:248`), `/command/setForceStart` (`:269`), `/login` (`:345`).

## 2. `state` → `DownloadItemStatus`

`QBittorrent.GetItems` (`:247-312`). State-state ini adalah string bawaan qBittorrent sendiri, yang dihasilkan oleh `torrentStateToString` (`qBittorrent/src/webui/api/serialize/serialize_torrent.cpp:44-87`).

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
| `metaDL` | Queued **jika `dht: true`**, selain itu Warning | "qBittorrent is downloading metadata" / "qBittorrent cannot resolve magnet link with DHT disabled" | `:286-299` |
| `forcedMetaDL` | sama seperti `metaDL` | sama | `:287` |
| `forcedDL` | Downloading | — | `:301` |
| `moving` | Downloading | — | `:302` |
| `downloading` | Downloading | — | `:303` |
| **apa pun selain itu** | **Downloading** | "Unknown download state: {state}" | `:307-311` |

Catatan yang harus diperhatikan shim:

- **State yang tidak dikenal tidak melempar error.** Cuma mencatat `_logger.Info($"Unknown download state: {torrent.State}")` lalu lanjut ke Downloading (`:307-311`). Ini kebalikan dari client SAB, di mana nama status yang tidak dikenal bikin deserializer melempar error dan mematikan seluruh poll. Tapi tetap saja: kirim cuma nama-nama dari tabel ini.
- **State Completed adalah satu-satunya yang bisa diimpor.** `CompletedDownloadService.Check` langsung return kecuali `Status == Completed` (`src/NzbDrone.Core/Download/CompletedDownloadService.cs:68-71`).
- **Setiap state Completed mereset `RemainingTime` ke nol** (`:273`, komentarnya "qBittorrent sends eta=8640000 for completed torrents").
- `metaDL` / `forcedMetaDL` adalah fase "magnet, belum ada metadata". Tidak ada timeout di client: statusnya Queued selama shim terus mengirim `metaDL`, dan tidak pernah naik jadi failure dengan sendirinya. Satu-satunya yang mengubahnya jadi Warning adalah `dht: false` di `app/preferences` (`:288`). Penanganan failed-download Sonarr naik berdasarkan umur grab, bukan berdasarkan state ini.
- `stalledDL` adalah *warning* yang dilihat operator untuk torrent yang tidak bergerak. Shim yang tidak punya konsep peer sebaiknya jangan pernah pakai ini. Warning pada download yang sedang dilacak akan muncul di queue sebagai masalah, dan itulah yang diperiksa oleh `FailedDownloadService`.
- `error` dan `missingFiles` sengaja dibuat Warning, "so failed download handling isn't triggered" (`:249`). Kalau shim ingin Sonarr memasukkan item ke blocklist dan grab ulang, Warning **bukan** cara untuk memintanya.

---

## 3. Pindah vs salin — kondisi persisnya, dan caranya {#3-move-vs-copy--the-exact-condition-and-the-recipe}

### 3.1 Gerbangnya {#31-the-gate}

`QBittorrent.cs:240-245`, persis termasuk komentar yang menjelaskannya:

```csharp
// Avoid removing torrents that haven't reached the global max ratio.
// Removal also requires the torrent to be paused, in case a higher max ratio was set on the torrent itself (which is not exposed by the api).
item.CanMoveFiles = item.CanBeRemoved =
    item.DownloadClientInfo.RemoveCompletedDownloads &&
    torrent.State is "pausedUP" or "stoppedUP" &&
    HasReachedSeedLimit(torrent, config);
```

Ada tiga kondisi, semuanya wajib:

1. **`RemoveCompletedDownloads`** — pengaturan per-klien di sisi *arr, bukan sesuatu yang dikatakan qBittorrent.
   `DownloadClientDefinition.RemoveCompletedDownloads` default-nya **`true`**
   (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17`), muncul di UI sebagai
   "Remove Completed". Kalau pengguna mematikannya, **impor jadi salinan** dan shim tidak bisa berbuat apa-apa. (Move juga bisa jadi salinan karena alasan kedua yang juga tidak bisa dilihat shim: container \*arr mengakses folder download dan root folder lewat dua volume, di mana `rename()` mengembalikan `EXDEV` dan `File.Move` milik .NET menyalin lalu menghapus. zurg membaca keduanya dari API sumber akuisisi dan mengadopsi salinan itu setelahnya; lihat `internal/arrlayout` dan `internal/handlers/magic_copies.go`.)
2. **`state` harus persis `pausedUP` atau `stoppedUP`.** `uploading`, `stalledUP`, `queuedUP`, dan `forcedUP` memang Completed tapi tidak bisa dipindah — fixture-nya mengunci itu
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

- **`ratio_limit >= 0` per torrent** menang langsung dan global tidak dicek. Di model qBittorrent sendiri, `ratio_limit` berarti `-2` = "use global" dan `-1` = "unlimited" (`QBittorrentTorrent.cs:32`; wiki, *Set torrent share limit*).
- `-1` (unlimited) tidak memenuhi kedua cabang: `-1 >= 0` salah dan `-1 == -2` juga salah. Jadi torrent unlimited **tidak pernah** bisa dipindahkan oleh aturan ratio.
- Toleransi `0.001f` itulah yang membuat "reached after rounding" bekerja. Fixture mengunci ratio `1.1006066990976857` terhadap limit `1.0` sebagai reached, dan `0.9999` juga sebagai reached (Sonarr `QBittorrentFixture.cs:715-737`, Radarr `:714-736`).

`HasReachedSeedingTimeLimit` (`:655-717`):

```csharp
if (torrent.SeedingTimeLimit >= 0)        { seedingTimeLimit = torrent.SeedingTimeLimit * 60; }        // minutes -> seconds
else if (torrent.SeedingTimeLimit == -2 && config.MaxSeedingTimeEnabled) { seedingTimeLimit = config.MaxSeedingTime * 60; }
else                                      { return false; }
```

lalu pakai `torrent.SeedingTime` kalau list API sudah memberikannya (`:672-676`). Kalau tidak, dia cek cache 5 menit dan, kalau tidak ketemu, memanggil **`torrents/properties`** untuk `seeding_time` (`:678-716`, `:739-744`). `HasReachedInactiveSeedingTimeLimit` (`:719-737`) bentuknya sama, tapi membandingkan `now - last_activity` dengan `inactive_seeding_time_limit` (atau global), dan tidak pernah butuh panggilan kedua.

### 3.3 Apa yang diputuskan `CanMoveFiles` {#33-what-canmovefiles-decides}

`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, series, importItem)`
(`CompletedDownloadService.cs:148-151`), lalu ada dua tempat yang membaca `CanMoveFiles`:

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

(Radarr: `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, sama persis.)

```csharp
// src/NzbDrone.Core/MediaFiles/DownloadedEpisodesImportService.cs:204-207
if (importMode == ImportMode.Auto)
{
    importMode = (downloadClientItem == null || downloadClientItem.CanMoveFiles) ? ImportMode.Move : ImportMode.Copy;
}
```

(Radarr: `DownloadedMovieImportService.cs:221-224`.)

`copyOnly == false` → `TransferMode.Move`
(`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`); kalau `copyOnly == true` →
`TransferMode.HardLinkOrCopy` jika "Use Hardlinks instead of Copy" aktif, kalau tidak `TransferMode.Copy`
(`:103`, `:107`). `TransferMode` adalah `[Flags] None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy=Copy|HardLink`
(`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`).

**Move yang gagal tidak pernah beralih ke Copy.** Argumen lengkapnya, dengan nomor baris, ada di [sabnzbd-client-contract.md §5.5](sabnzbd-client-contract.md);
`DiskTransferService.cs` dipakai bersama dan identik byte per byte di kedua repo. Singkatnya: cabang Move di `TransferFile`
(`src/NzbDrone.Common/Disk/DiskTransferService.cs:360-389`) hanya punya satu jalur copy, yang dipilih di awal dari `targetMount.DriveFormat == "cifs"` (`:342`, `:378-385`), bukan sebagai reaksi terhadap kegagalan;
`TryMoveFileVerified` melempar ulang exception (`:487-503`), dan `VerifyFile` melempar `IOException("File move incomplete, data loss may have occurred. …")` kalau ukuran tujuan tidak cocok dengan sumber (`:505-524`).

### 3.4 Dengan default bawaan qBittorrent, impor adalah **salin** {#34-with-qbittorrents-own-defaults-the-import-is-a-copy}

Ambil torrent yang dilaporkan shim secara naif, yaitu default qBittorrent, yang juga merupakan default model:

| Field | Nilai | Efek |
|---|---|---|
| `state` | `stoppedUP` | konjungsi 2 ✓ |
| `ratio_limit` | `-2` (default, `QBittorrentTorrent.cs:33`) | jatuh ke cabang global |
| `max_ratio_enabled` | `false` (default qBittorrent sendiri; contoh body wiki `:684`) | cabang global gagal |
| `seeding_time_limit` | `-2` | butuh `max_seeding_time_enabled` |
| `max_seeding_time_enabled` | `false` (wiki `:686`) | gagal |
| `inactive_seeding_time_limit` | `-2` | butuh `max_inactive_seeding_time_enabled` |
| `max_inactive_seeding_time_enabled` | `false` | gagal |

⇒ `HasReachedSeedLimit` false ⇒ `CanMoveFiles` false ⇒ `copyOnly` true ⇒ `TransferMode.Copy` ⇒ **the
\*arr membaca setiap byte rilis dari mount lalu menuliskannya kembali.** Pada debrid mount, inilah satu-satunya hasil yang ingin dihindari oleh seluruh desain ini, dan kegagalannya terjadi diam-diam. Tidak ada peringatan sama sekali, impor hanya memakan waktu berjam-jam dan memenuhi disk.

Fixture mengunci kasus persis ini:
`should_not_be_removable_and_should_not_allow_move_files_if_max_ratio_is_not_set`
(Sonarr `QBittorrentFixture.cs:691-701`, Radarr `:690-700`) — batas global dimatikan, torrent dijeda,
ratio 1.0, `CanMoveFiles == false`.

### 3.5 Langkahnya {#35-the-recipe}

Untuk setiap torrent yang ingin di-import oleh shim dengan **move**:

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

`ratio_limit: 0` masuk ke cabang pertama (`0 >= 0`, dan `0 - 0 <= 0.001`) dan preferensi global tidak pernah dicek, jadi `max_ratio_enabled` bisa tetap `false` dan health check `DownloadClientRemovesCompletedDownloadsCheck` tetap diam. Nilai `ratio_limit >= ratio` apa pun yang selisihnya dalam `0.001` juga bisa dipakai; `0`/`0` adalah yang paling simpel karena tidak perlu koordinasi.

Soal `pausedUP` vs `stoppedUP`: **branch develop memperlakukan keduanya sama** — baik di gerbang `CanMoveFiles` (`:244`) maupun di status map (`:266-267`) — dan setiap fixture seed-limit adalah pasangan `[TestCase]` untuk keduanya. `stoppedUP` adalah penulisan dari qBittorrent 5 (`serialize_torrent.cpp:54-55`; `pausedUP` sudah tidak ada di master). `pausedUP` adalah pilihan yang lebih aman untuk build \*arr yang sudah *released*, karena cabang `stoppedUP` ditambahkan saat qBittorrent 5 rilis, dan build Sonarr v4 / Radarr v5 yang lebih lama hanya mengenal `pausedUP` — poin terakhir itu adalah inferensi tentang tag lama, bukan sesuatu yang dibuktikan oleh sumber develop di atas.

Dan yang di luar kendali shim: **"Remove Completed" harus tetap aktif di pengaturan download client \*arr.** Secara default ini sudah aktif (`DownloadClientDefinition.cs:17`). Tulis ini di dokumentasi, karena kalau dimatikan, setiap import diam-diam berubah jadi download penuh.

---

## 4. `OutputPath` — tempat *arr diberi tahu untuk mengimpor {#4-outputpath--where-the-arr-is-told-to-import-from}

### 4.1 Jalur 2.6.1+: `content_path` {#41-the-261-path-content_path}

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

Teks peringatannya (`src/NzbDrone.Core/Localization/Core/en.json`):

> Unable to Import. Path matches client base download directory, it's possible 'Keep top-level folder'
> is disabled for this torrent or 'Torrent Content Layout' is NOT set to 'Original' or 'Create Subfolder'?

Aturan yang harus dipenuhi shim:

- `content_path` **tidak boleh sama dengan** `save_path`. Kesamaan itu justru penyebab gagalnya, bukan fallback: item jadi Warning dan tidak pernah ter-import.
- `content_path` harus **absolut dan valid untuk OS tempat \*arr berjalan**. `CompletedDownloadService.ValidatePath` (`CompletedDownloadService.cs:295-313`) akan menolaknya kalau tidak valid, dengan pesan "[{0}] is not a valid local path. You may need a Remote Path Mapping."
- Path itu harus ada di host \*arr sebagai **folder atau file**. `ProcessPath` (`DownloadedEpisodesImportService.cs:80-105`) mengecek `FolderExists` dulu lalu `FileExists`, dan kalau keduanya tidak ketemu akan jatuh ke `LogInaccessiblePathError` dengan hasil kosong.
- Jangan kirim `content_path` kosong. Nilai kosong dianggap "berbeda" dari `save_path` yang tidak kosong, jadi `OutputPath` diset ke `OsPath` kosong. Akibatnya `GetImportItem` jatuh ke penelusuran `torrents/files` (§4.2), karena `item.OutputPath.IsEmpty` bernilai true (`:341-344`).
- Blok ini hanya jalan untuk item **Completed**, jadi `content_path` baru benar-benar berpengaruh saat statusnya termasuk dalam kumpulan Completed di §2.

Apa yang sebenarnya diisi qBittorrent asli, yaitu `TorrentImpl::contentPath()` (`qBittorrent/src/base/bittorrent/torrentimpl.cpp:577-587`):

```cpp
Path TorrentImpl::contentPath() const
{
    if (!hasMetadata())    return {};
    if (filesCount() == 1) return (actualStorageLocation() / filePath(0));   // the FILE, not a folder
    const Path rootPath = this->rootPath();
    return (rootPath.isEmpty() ? actualStorageLocation() : rootPath);
}
```

dengan `rootPath()` = `actualStorageLocation() / Path::findRootFolder(filePaths())` (`:565-575`). Jadi: `content_path` torrent **single-file** adalah file itu sendiri. Torrent multi-file yang punya folder root bersama mendapat folder tersebut. Torrent multi-file **tanpa** root bersama mendapat `save_path`, dan justru kasus inilah yang diperingatkan client lewat pengecekan `content_path == save_path`.

`RemapRemoteToLocal(Settings.Host, …)` menerapkan Remote Path Mappings milik pengguna, yang dicocokkan dengan string **Host** yang dikonfigurasi. Kalau \*arr berjalan di container dan shim melaporkan path milik host, operator perlu membuat mapping. Lihat [sabnzbd.md](../guides/sonarr-radarr.md#8-if-your-arr-is-in-docker), yang berlaku tanpa perubahan.

### 4.2 Jalur sebelum 2.6.1: `GetImportItem` menelusuri `torrents/files` {#42-the-pre-261-path-getimportitem-walks-torrentsfiles}

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

Fungsi ini hanya memakai **`files[0].name`**, naik ke komponen path paling atas, lalu menggabungkannya ke `properties.save_path`. Fixture-nya mencakup ketiga bentuk ini (Sonarr `QBittorrentFixture.cs:317-421`, Radarr `:296-400`):

| `files[0].name` | `save_path` | `OutputPath` |
|---|---|---|
| `Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` |
| `Folder/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Folder` |
| `Droned.S01.12/E01.mkv` (+ `E02.mkv`) | `/Torrents` | `/Torrents/Droned.S01.12` |

Perhatikan baris ketiga: yang dipakai adalah root dari `files[0]`, bukan root bersama yang dihitung. Jadi **shim di jalur ini harus membuat daftar file dengan urutan yang entri pertamanya memuat folder rilis**. Shim yang melaporkan webapi `>= 2.6.1` tidak pernah sampai ke sini, dan ini salah satu alasan lagi untuk melaporkan `2.11.2`.

`previousImportAttempt` adalah parameter dari `GetImportItem` (`:338`) dan **tidak pernah dibaca** oleh implementasi ini. Tidak ada yang diingat tentang percobaan yang gagal.

### 4.3 Kapan path salah, dan seberapa sering dicoba ulang {#43-when-the-path-is-wrong-and-how-often-it-is-retried}

Tidak ada backoff dan tidak ada batas percobaan di jalur ini.

- `CompletedDownloadService.Check` dijalankan untuk setiap download yang dilacak dalam state `Downloading` atau
  `ImportBlocked`, pada setiap refresh
  (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:125-129`).
- `Check` memanggil `SetImportItem` **terlebih dahulu** (`CompletedDownloadService.cs:73`), yaitu `_provideImportItemService.ProvideImportItem(...)` → `client.GetImportItem(...)`
  (`:290-293`, `src/NzbDrone.Core/Download/ProvideImportItemService.cs:17-22`). Jadi `OutputPath` dihitung ulang dari baris `torrents/info` yang *terkini* pada setiap polling.
- Kegagalan `ValidatePath` (`:295-313`) menghasilkan Warning dan state tetap `Downloading`, sehingga polling berikutnya mencoba lagi dari awal:
  - output path kosong → "Download doesn't contain intermediate path, Skipping."
  - path dengan OS yang salah → "[{0}] is not a valid local path. You may need a Remote Path Mapping. …"
- `Import` juga memanggil `SetImportItem` saat masuk (`:130`) sebelum membaca ulang `trackedDownload.ImportItem.OutputPath.FullPath` (`:147`), dan dipicu dari state `ImportPending`
  oleh `DownloadProcessingService`
  (`src/NzbDrone.Core/Download/DownloadProcessingService.cs:61-63`). Import yang gagal membiarkan state di `ImportPending` (`:158`) atau memindahkannya ke `ImportBlocked` (`:196`). Keduanya akan diproses ulang.
- Path yang ada tetapi tidak menghasilkan apa pun yang bisa diimpor memberi "No files found are eligible for import in {0}" (`:162`) dan tetap di `ImportPending`.

**Konsekuensinya untuk shim: `content_path` boleh salah untuk sementara waktu.** Laporkan torrent sebagai Downloading (atau Queued) sampai folder benar-benar ada dan ukuran file-nya sudah final. Dengan begitu client akan terus melakukan polling. Melaporkan Completed terlalu cepat berarti membuang satu percobaan import ke folder yang belum siap. Lebih buruk lagi, \*arr bisa memindahkan file yang ukurannya belum lengkap lalu gagal di `VerifyFile`, padahal sumbernya sudah terlanjur dikosongkan. Ini jebakan yang sama seperti yang didokumentasikan untuk endpoint SAB ([sabnzbd.md](../guides/sonarr-radarr.md), *What happens on a grab*, langkah 5).

---

## 5. Urutan setelah impor {#5-the-post-import-sequence}

### 5.1 Apa yang terpicu, secara berurutan {#51-what-fires-in-order}

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

dan `RemoveFromDownloadClient` (`:87-103`) adalah:

```csharp
_logger.Debug("[{0}] Removing download from {1} history", ...);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);             // :92  deleteData: TRUE
trackedDownload.DownloadItem.Removed = true;
```

Jadi urutan request ke wire setelah impor berhasil adalah:

1. **`POST /api/v2/torrents/setCategory`**: hanya jika kategori pasca-impor diatur (`QBittorrent.cs:52-69`). Secara default dilewati.
2. Sebelum itu, dan di luar download client sepenuhnya: **\*arr memindahkan file**, lalu `ProcessFolder` bisa **menghapus folder sumbernya sendiri** (`DownloadedEpisodesImportService.cs:209-223`, Radarr `DownloadedMovieImportService.cs:226-240`):

   ```csharp
   if (importMode == ImportMode.Move &&
       importResults.Any(i => i.Result == ImportResultType.Imported) &&
       ShouldDeleteFolder(directoryInfo, series))
   {
       _diskProvider.DeleteFolder(directoryInfo.FullName, true);   // recursive
   }
   ```

   `ShouldDeleteFolder` (`:108-153`) menolak jika ada file video yang tersisa di folder, bisa di-parse, dan bukan sample (`:117-133`), atau jika ada file `.rar` yang lebih besar dari 10 MB (`:135-139`). Setelah pemindahan satu file yang berhasil, kedua kondisi itu tidak berlaku, jadi folder **memang** dihapus. `IOException` ditangkap dan dicatat di level Debug (`:219-222`).
3. **`POST /api/v2/torrents/delete`** dengan `hashes=<lowercase hash>&deleteFiles=true` (`QBittorrent.cs:335`, `QBittorrentProxyV2.cs:190-202`).

Dua event lain juga masuk ke `RemoveFromDownloadClient(…, true)` yang sama:

- `DownloadFailedEvent` (`DownloadEventHub.cs:26-46`), dibatasi oleh `RemoveFailedDownloads` per-client (default `true`, `DownloadClientDefinition.cs:18`). Perhatikan bahwa `TrackedDownload.Fail()` selalu mengatur `DownloadItem.CanBeRemoved = true` (`src/NzbDrone.Core/Download/TrackedDownloads/TrackedDownload.cs:39-46`, komentar: "Set CanBeRemoved to allow the failed item to be removed from the client"). **Jadi download yang gagal tetap dihapus meskipun gerbang batas seed bilang sebaliknya.**
- `DownloadCanBeRemovedEvent` (`:71-85`).

`NotSupportedException` dari `RemoveItem` diturunkan menjadi "Removing item not supported by your download client ({0})." (`:95-98`). Exception lain dicatat sebagai error dan item *tidak* ditandai Removed, sehingga akan dicoba lagi pada poll berikutnya (`:99-102`).

### 5.2 Apa yang harus dilakukan shim dengan `deleteFiles=true` {#52-what-the-shim-must-do-with-deletefilestrue}

Ini keputusan yang sama dengan yang sudah diambil `internal/sabnzbd` untuk `mode=history&name=delete`, dengan alasan yang sama. Dari `internal/sabnzbd/api.go:596-609`:

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

Kasus qBittorrent bentuknya sama, dengan satu perbedaan: di API ini, penghapusan data adalah tugas *client*, bukan tugas \*arr, karena `RemoveItem` **tidak** memanggil `DeleteItemData` (§1.15). Tapi \*arr sudah menghapus folder itu sendiri di langkah 2 di atas, lewat mount. Di bawah `__magic__`, itu menulis tombstone: entri hilang dari `__magic__` tapi tetap berada persis di tempat semula di `__all__`, di setiap direktori filter, dan di akun debrid
([magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)).

Jadi:

- **`torrents/delete` menghapus *catatan* torrent yang disimpan shim untuk \*arr.** Jawab dengan 200.
- **`deleteFiles` tidak boleh menghapus torrent di provider.** Rilis yang baru saja diimpor \*arr masih disajikan dari torrent itu. Kalau dihapus, hal yang sudah diimpor ikut hancur. Satu-satunya tempat penghapusan sungguhan masuk akal adalah torrent yang tidak pernah diimpor, yaitu jalur download gagal. Tapi bahkan di sana, torrent debrid adalah state library bersama, bukan download sementara, jadi default yang aman adalah: **jangan pernah hapus torrent di provider, cukup tombstone.** Tulis ini di dokumen untuk pengguna, seperti yang dilakukan [sabnzbd.md](../guides/sonarr-radarr.md) di bagian *Yang berhasil, dan yang tidak*.
- Permintaan `torrents/delete` untuk **hash yang tidak dikenal** tetap harus dijawab 200. qBittorrent yang asli melakukannya (wiki, *Delete torrents*: "200 | All scenarios"). Kalau di sini errornya, akan dicatat sebagai error lalu dicoba ulang setiap poll, selamanya.

### 5.3 `MarkItemAsImported` dan kategori pasca-impor {#53-markitemasimported-and-the-post-import-category}

`QBittorrent.cs:52-69` menetapkan kategori pasca-impor saat `TvImportedCategory` / `MovieImportedCategory` sudah diatur dan berbeda dari kategori utama. Fungsi ini dipanggil untuk **setiap** impor yang selesai (`DownloadEventHub.cs:54`), sebelum keputusan penghapusan.

Jika shim mematuhi `setCategory` dan benar-benar memindahkan torrent keluar dari kategori yang di-poll, torrent akan hilang dari `torrents/info?category=…` berikutnya. Itulah tujuan pengaturan ini, dan yang ditampilkan UI sebagai `DownloadClientHasPostImportCategory` (`src/NzbDrone.Core/Queue/QueueService.cs:84`, berasal dari `DownloadClientItemClientInfo.HasPostImportCategory`, `QBittorrent.cs:234`). Menerima panggilan itu dan mencatat kategori baru adalah perilaku yang benar. Jika ditolak, hanya muncul peringatan (`:62-67`).

---

## 6. `Test()` — setiap pemeriksaan, berurutan, dan pesannya {#6-test--every-check-in-order-and-its-message}

`DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`) membungkus
seluruh prosesnya: **setiap exception yang lolos akan berubah menjadi**
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

Setiap cabang **return**, jadi paling banyak satu kegagalan yang keluar dari method ini.

| Urutan | Kondisi | Properti | Pesan |
|---|---|---|---|
| 1 | `_proxySelector.GetProxy(Settings, force: true).GetApiVersion(Settings)` — memaksa deteksi ulang (`:435`) | | |
| 2 | version `< 1.5` (`:436`) | `Host` | "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| 3 | version `< 1.6` **dan** category diisi (`:445-455`) | `Category` | "Category is not supported" / detail "Categories are not supported until qBittorrent version 3.3.0. Please upgrade or try again with an empty Category." |
| 4 | version `>= 1.6` **dan** category kosong (`:456-464`) | `TvCategory` / `MovieCategory` | **Warning** — "Category is recommended" / "{appName} will not attempt to import completed downloads without a category." |
| 5 | `GetConfig` lalu `RemovesCompletedDownloads(config)` (`:467-474`) | `""` | "qBittorrent is configured to remove torrents when they reach their Share Ratio Limit" / detail yang menyebut Options → BitTorrent → Share Ratio Limiting |

Pemetaan exception (`:476-506`):

| Ditangkap | Properti | Pesan |
|---|---|---|
| `DownloadClientAuthenticationException` | `ApiKey` jika api key diisi, jika tidak `Username` | "Authentication Failure" / "Please verify your credentials. Also verify if the host running {appName} isn't blocked from accessing {clientName} by WhiteList limitations…" |
| `WebException` dengan `Status == ConnectFailure` | `Host` | "Unable to connect to qBittorrent" / "Please verify the hostname and port." |
| `WebException` lainnya | `""` | "Unknown exception: {message}" |
| `Exception` lainnya | `Host` | "Unable to connect to qBittorrent", `DetailedDescription = ex.Message` |

Perhatikan bahwa kasus 4 adalah **warning**, dan `failures.HasErrors()` di `:421` bernilai false untuk warning. Jadi setup tanpa category tetap menjalankan tiga pengecekan lainnya.

### 6.2 `TestCategory` (`:511-556`) — alur "category does not exist" {#62-testcategory-511-556--the-category-does-not-exist-flow}

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
Kegagalan: properti `TvCategory` / `MovieCategory` (atau `TvImportedCategory` / `MovieImportedCategory`),
pesan "Configuration of category failed", detail "{appName} was unable to add the label to
qBittorrent."

Jadi shim punya dua pilihan: langsung menyediakan kategori yang dikonfigurasi supaya `torrents/categories` sudah berisi kategori tersebut, atau menerima `createCategory` dan memastikan kategori itu muncul di respons `torrents/categories` berikutnya. **Tidak ada pilihan ketiga** — client akan membaca ulang dan gagal kalau key-nya masih belum ada. Nama kategori dicocokkan **persis**, peka huruf besar-kecil (`Dictionary<string, …>.ContainsKey` dengan default ordinal comparer).

Perhatikan penanganan `TvImportedCategory`: kategori pasca-impor juga dicek dan dibuat di sini, walaupun hanya dipakai setelah impor. Kalau operator mengaturnya, kategori itu harus sudah ada.

`QBittorrentSettingsValidator` (`QBittorrentSettings.cs:23-24`) sudah menolak nama kategori yang cocok dengan `^([^\\\/](\/?[^\\\/])*)?$` — tidak boleh ada backslash, tidak boleh `//`, dan tidak boleh diawali atau diakhiri `/` — sebelum request apa pun dikirim.

### 6.3 `TestPrioritySupport` (`:558-597`) — pemeriksaan kesehatan `queueing` {#63-testprioritysupport-558-597--the-queueing-health-check}

```csharp
var recentPriorityDefault = Settings.RecentTvPriority == (int)QBittorrentPriority.Last;
var olderPriorityDefault  = Settings.OlderTvPriority  == (int)QBittorrentPriority.Last;
if (olderPriorityDefault && recentPriorityDefault) { return null; }   // :563-566  the default: nothing checked

var config = Proxy.GetConfig(Settings);
if (!config.QueueingEnabled) { … }                                    // :572-588
```

Properti failure-nya adalah `nameof(Settings.RecentTvPriority)` atau `nameof(Settings.OlderTvPriority)`
(dicek sesuai urutan itu), message "Queueing Not Enabled", detail "Torrent Queueing is not enabled in
your qBittorrent settings. Enable it in qBittorrent or select 'Last' as priority."

Exception di sini menjadi `("", "Unknown exception: {message}")` (`:590-594`).

`queueing_enabled` defaultnya **`true`** di model (`QBittorrentPreferences.cs:41`), jadi shim yang tidak menyertakan key itu lolos. Tapi tidak menyertakannya itu kebohongan jika `topPrio` tidak melakukan apa-apa. Melaporkan `queueing_enabled: false` itu jujur, dan failure ini hanya muncul **jika** operator mengubah setting priority dari `Last`.

### 6.4 `TestGetTorrents` (`:599-612`)

`Proxy.GetTorrents(Settings)`; any exception becomes `("", "Failed to get the list of torrents:
{exceptionMessage}")`. This is the check that catches a malformed `torrents/info` body — a JSON object
instead of an array, a bad enum, a non-numeric `size`.

### 6.5 Pemeriksaan `dht` {#65-the-dht-check}

Tidak ada pemeriksaan DHT khusus di `Test()`. `dht` diperiksa saat grab (`:73-76`, magnet tanpa tracker) dan saat poll (`:288`, cabang `metaDL`). Shim yang melaporkan `dht: false` lolos tes koneksi, lalu menolak setiap magnet tanpa tracker dengan `ReleaseDownloadException("Magnet not supported by download client. …")` (`TorrentClientBase.cs:115`). **Laporkan `dht: true`.**

## 7. Parsing dan konsekuensi impor yang perlu diketahui shim {#7-parsing-and-import-consequences-a-shim-should-know}

### 7.1 `name` menjadi `Title`, dan `Title` dipakai untuk tiga hal berbeda {#71-name-becomes-title-and-title-is-used-for-three-different-things}

`DownloadClientItem.Title = torrent.Name` (`QBittorrent.cs:232`). Dampaknya ke bagian lain:

1. **Identifikasi series/film.** `CompletedDownloadService.Check` menjalankan
   `_parsingService.GetSeries(trackedDownload.DownloadItem.Title)`
   (`CompletedDownloadService.cs:95`). Jika hasilnya null, ia kembali ke **grab history** yang dicocokkan dengan `DownloadId` (`:99-102`). Jika itu juga tidak ada: "Series title mismatch; automatic import is not possible." + `ImportBlocked` (`:104-110`). Padanannya di Radarr ada di `ProcessFolder`, yang membaca `_historyService.FindByDownloadId(downloadClientItem?.DownloadId ?? "")` (`DownloadedMovieImportService.cs:193-194`).
   **Inilah alasan kedua mengapa shim harus mencocokkan infohash yang persis sama dengan yang dihitung \*arr** (§1.7). Fallback history memakai `DownloadId`, jadi hash yang tidak cocok membuat jalur judul dan fallback sama-sama gagal.
2. **Parsing rilis untuk keputusan impor.** `downloadClientItemInfo = Parser.Parser.ParseTitle(downloadClientItem.Title)` (Sonarr `ImportDecisionMaker.cs:80`; Radarr `ParseMovieTitle`, `:80`), lalu di-assign ke `LocalEpisode.DownloadClientEpisodeInfo` / `LocalMovie.DownloadClientMovieInfo` (`:94` / `:92`).
3. **Baris log dan UI antrean.**

**Gerbang fallback judul Sonarr.** `AggregateEpisodes.GetBestEpisodeInfo`
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

Ada tiga gerbang untuk memakai judul download-client sebagai pengganti nama file: `!OtherVideoFiles`, nama file itu sendiri bukan judul scene, dan judul client bukan parse satu season penuh. Jadi judul torrent hanya bisa menyelamatkan rilis yang berupa satu file dan tidak bernama scene.

Radarr **tidak punya** gerbang pemenang tunggal yang setara. `LocalMovie.OtherVideoFiles` memang ada (`src/NzbDrone.Core/Parser/Model/LocalMovie.cs:36`), tetapi info parse film digabungkan oleh rantai augmenter yang diurutkan berdasarkan tingkat keyakinan, bukan dipilih satu. Lihat `AggregateQuality.cs:25-121`. Judul download-client masuk ke augmenter tersebut, dan identitas film berasal dari parse folder ditambah grab history (`DownloadedMovieImportService.cs:192-195`).

**`OtherVideoFiles`** (`ImportDecisionMaker.cs:85`, `:100`, Radarr `:83`, `:98`):

```csharp
var nonSampleVideoFileCount = sceneSource ? GetNonSampleVideoFileCount(newFiles, series, downloadClientItemInfo, folderInfo) : videoFiles.Count;
…
OtherVideoFiles = nonSampleVideoFileCount > 1
```

`ProcessFolder` selalu mengirim `sceneSource: true` (`DownloadedEpisodesImportService.cs:201`). Artinya, folder dengan dua atau lebih video non-sample akan mengatur `OtherVideoFiles`, dan judul download-client langsung tidak ikut dipertimbangkan untuk setiap file di dalamnya.

**Mengapa ini penting di zurg.** Real-Debrid menulis ulang nama rilis yang terkena blokir nama file miliknya. Contohnya `WEB-DL`, `WEB.x264`, dan `WEB.H264` (persis dengan huruf kapital tersebut), `WEBRip`, `BDRip`, `HDRip`, `DVDRip`, `HDTV.x264`, `HDTV.XviD`, `BluRay.x264`, dan `p.BluRay.DTS` (huruf kapital apa pun), sesuai pengukuran per 2026-10-14. Selain itu, zurg menambahkan suffix saat dua rilis bertabrakan namanya. Keduanya bisa membuat `torrent.name` berhenti ter-parse sebagai rilis yang diambil. Lihat bagian RD 451 di `CLAUDE.md` monorepo. Konsekuensinya, berurutan: identifikasi jatuh ke grab history (tetap aman, asalkan hash-nya cocok); parse per-file Sonarr mengambil alih (aman untuk file dengan nama yang benar di dalam folder); dan nama folder di bawah `__magic__`, yang dibaca `Parser.ParseTitle(directoryInfo.Name)` di `DownloadedEpisodesImportService.cs:184`, menjadi satu hal lagi yang harus tetap bisa di-parse.

### 7.2 Pemindaian folder impor membuang seluruh subtree {#72-the-import-folder-scan-drops-whole-subtrees}

`DiskScanService.FilterPaths` (`src/NzbDrone.Core/MediaFiles/DiskScanService.cs:232-246`), diterapkan ke
folder download di `DownloadedEpisodesImportService.cs:185` (Radarr
`DownloadedMovieImportService.cs:202`) dengan `filterExtras: true`:

```csharp
private static readonly Regex ExcludedExtrasSubFolderRegex = new Regex(@"(?:\\|\/|^)(?:extras|extrafanart|behind the scenes|deleted scenes|featurettes|interviews|other|scenes|samples|shorts|trailers)(?:\\|\/)", …IgnoreCase);   // :72
private static readonly Regex ExcludedSubFoldersRegex      = new Regex(@"(?:\\|\/|^)(?:@eadir|\.@__thumb|plex versions|\.[^\\/]+)(?:\\|\/)", …IgnoreCase);   // :73
private static readonly Regex ExcludedExtraFilesRegex      = new Regex(@"(-(trailer|other|behindthescenes|deleted|featurette|interview|scene|short)\.[^.]+$)", …IgnoreCase);   // :74
private static readonly Regex ExcludedFilesRegex           = new Regex(@"^\.(_|unmanic|DS_Store$)|^Thumbs\.db$", …IgnoreCase);   // :75
```

**Regex extras Radarr berbeda satu alternatif**: `sample[s]?` alih-alih `samples`
(Radarr `DiskScanService.cs:72`), jadi Radarr juga membuang folder `sample/` sedangkan Sonarr hanya membuang `samples/`. Semua yang lain di empat regex itu sama antara kedua repo.

Perhatikan alternatif `\.[^\\/]+` di `ExcludedSubFoldersRegex`: **komponen direktori apa pun yang diawali titik akan dibuang**, di kedalaman berapa pun. Pencocokannya dilakukan terhadap `basePath.GetRelativePath(path)`, jadi cakupannya hanya di bawah folder import. Titik di folder induk mount tidak berpengaruh.

Hanya file yang ekstensinya ada di `MediaFileExtensions.Extensions` yang sampai ke filter ini (`DiskScanService.GetVideoFiles`, `:202-215`).

### 7.3 Deteksi sampel membaca file {#73-sample-detection-reads-the-file}

`GetNonSampleVideoFileCount` (`ImportDecisionMaker.cs:216-234`) memanggil `_detectSample.IsSample(...)`
untuk **setiap** file video di folder. `DetectSample.IsSample`
(`src/NzbDrone.Core/MediaFiles/EpisodeImport/DetectSample.cs:27-45`) hanya langsung melewati
file specials, `.flv`, dan `.strm` (`:78-101`). Selain itu, ia memanggil `_videoFileInfoReader.GetRunTime(path)`, yaitu **ffprobe pada file itu, lewat mount**, lalu membandingkannya dengan durasi minimum yang dihitung dari durasi yang diharapkan (`:103-121`). Runtime tepat 0 dianggap sebagai **sampel** (`:107-111`). Jika runtime tidak bisa didapat, sistem mencatat log "Failed to get runtime from the file, make sure ffprobe is available" dan mengembalikan Indeterminate (`:38-42`).

`ShouldDeleteFolder` (`DownloadedEpisodesImportService.cs:117-133`) menjalankan pengecekan yang sama sekali lagi terhadap sisa file setelah proses pemindahan.

Jadi, impor rilisan dengan N file minimal memakan N kali pembukaan ffprobe ke backend debrid sebelum ada file yang dipindahkan. Ini biaya nyata di mount zurg, dan dari sisi klien memang tidak bisa dihindari.

### 7.4 Penolakan di `ProcessFolder` / `ProcessFile` {#74-the-refusals-in-processfolder--processfile}

| Kondisi | Hasil | Baris (Sonarr) |
|---|---|---|
| jalur impor adalah folder series/film | `ImportRejectionReason.SeriesFolder` — "Import path is mapped to a series folder" (Radarr: `MovieFolder`, "…a movie folder") | `:175-182` (Radarr `:183-190`) |
| nama folder tidak cocok dengan series/film yang dikenal | `UnknownSeriesResult("Unknown Series")` | `:160-168` |
| nama file diawali `._` | `InvalidFilePath` | `:251-259` |
| ekstensi ada di `FileExtensions.DangerousExtensions` | `DangerousFile` | `:263-271` |
| ekstensi ada di `FileExtensions.ExecutableExtensions` | `ExecutableFile` | `:273-281` |
| ekstensi tidak ada di `MediaFileExtensions.Extensions` | `UnsupportedExtension` | `:283-293` |

**`SeriesPathExists` / `MoviePathExists` adalah yang bikin masalah pada tata letak `__magic__`.** Jika root folder \*arr adalah `/mnt/zurg/__magic__/tv` dan folder series adalah `/mnt/zurg/__magic__/tv/The Show`, maka jalur impor yang kebetulan *adalah* folder series akan langsung ditolak. Itulah alasan download folder (`content_path`) harus berada sejajar dengan root folder, bukan di dalamnya. Tata letak ini juga yang sudah dianjurkan di [sabnzbd.md](../guides/sonarr-radarr.md): `save_path` = `/mnt/zurg/__magic__/__all__`, root folder `/mnt/zurg/__magic__/tv` dan `/mnt/zurg/__magic__/movies`, serta release ada di `/mnt/zurg/__magic__/__all__/<release>`.

`_UNPACK_` dan `_FAILED_` dihapus dari nama folder sebelum di-parse (`GetCleanedUpFolderName`, `:311-317`).

`IsFileLocked` **dilewati sepenuhnya jika ada item download client** (`:187-199`, `:295-304`). Pengecekan lock hanya berjalan untuk scan manual/root-folder. Shim tidak perlu khawatir soal ini.

---

## 8. Pemeriksaan kesehatan {#8-the-health-checks}

Ketiganya dipakai bersama dengan client SAB dan dibahas di [sabnzbd-client-contract.md §6](sabnzbd-client-contract.md). Yang khusus untuk qBittorrent adalah:

- **`RemotePathMappingCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs:59-173`) menelusuri `client.GetStatus().OutputRootFolders`. Untuk qBittorrent, isinya hanya satu folder yang dihitung di `QBittorrent.cs:377-407`: `save_path` global, yang ditimpa atau diperpanjang oleh `savePath` dari kategori yang dikonfigurasi (§1.5). Path itu harus valid untuk **OS tempat \*arr berjalan** (`:68-113`) dan harus **ada di host \*arr** (`:115-158`). Path itu tidak perlu bisa ditulisi.
  `IsLocalhost` adalah `Settings.Host == "127.0.0.1" || Settings.Host == "localhost"` (`:406`) dan hanya menentukan salah satu dari tiga pesan error yang muncul.
- **`DownloadClientRemovesCompletedDownloadsCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:33-66`) memberi peringatan setiap kali `GetStatus().RemovesCompletedDownloads` bernilai true, yaitu setiap kali flag turunan di §1.4 bernilai true. Selama `max_ratio_enabled` dan `max_seeding_time_enabled` tetap false (yang memang sudah dilakukan resep di §3.5), check ini tetap diam.
- **`DownloadClientRootFolderCheck`** adalah satu-satunya tempat kedua repo benar-benar berbeda. Sonarr hanya memberi peringatan jika root folder *sama dengan* output folder, sedangkan Radarr juga memberi peringatan jika root folder *berisi* output folder. Analisis lengkapnya ada di [sabnzbd-client-contract.md §6.1](sabnzbd-client-contract.md). Aturan praktisnya sama di sini: jangan taruh root folder sama dengan atau di atas save path, dan jangan taruh root folder di dalamnya. `/mnt/zurg/__magic__/tv` itu saudara sejajar dari `/mnt/zurg/__magic__/__all__`.

## 9. Sonarr vs Radarr — perbedaan lengkap {#9-sonarr-vs-radarr--the-complete-diff}

Sudah diverifikasi dengan membandingkan file-file yang diambil satu per satu (BOM dan CRLF sudah dinormalisasi).

| File | Perbedaan |
|---|---|
| `QBittorrent.cs` | `TvCategory`→`MovieCategory`, `TvImportedCategory`→`MovieImportedCategory`, `RecentTvPriority`→`RecentMoviePriority`, `OlderTvPriority`→`OlderMoviePriority`, `RemoteEpisode`→`RemoteMovie`; `remoteEpisode.IsRecentEpisode()` → `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` (`:80`, `:137`). **Nomor baris sama persis satu-satu.** |
| `QBittorrentSettings.cs` | Perubahan nama yang sama; kategori default `"tv-sonarr"` → `"radarr"` (`:36`); token teks bantuan `…EpisodeHelpText` → `…MovieHelpText`. Nomor baris sama. |
| `QBittorrentProxyV2.cs` | Perubahan nama kategori; `new[] { HttpStatusCode.Forbidden }` → `[HttpStatusCode.Forbidden]` (collection expression, Sonarr `:401` / Radarr `:400`); Sonarr punya baris kosong ekstra di baris 13 → **Sonarr N = Radarr N−1 untuk N ≥ 14**. |
| `QBittorrentProxyV1.cs` | Perubahan nama kategori; offset baris kosong yang sama. |
| `QBittorrentProxySelector.cs` | Ada spasi ganda yang tidak perlu di constructor Sonarr (`:46`); baris kosong di baris 3 → **Sonarr N = Radarr N−1 untuk N ≥ 4**. |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **identik byte per byte.** |
| `TorrentClientBase.cs` | `RemoteEpisode`→`RemoteMovie` di seluruh file; Radarr juga memperlakukan HTTP **410 Gone** seperti 404 saat mengambil `.torrent` (`:175`), Sonarr hanya 404. Keduanya 274 baris. |
| `QBittorrentFixture.cs` | Tes yang sama, urutannya diubah: `missingFiles_item_should_have_required_properties` ada di Sonarr `:296-315` dan Radarr `:402-420`, dan **salinan Radarr tidak punya atribut `[Test]`** (`:401` kosong), jadi tidak pernah dijalankan di sana. Sonarr `:318-421` = Radarr `:297-400`; mulai dari Sonarr `:423`, Radarr = Sonarr − 1. Sonarr 1000 baris, Radarr 998. |
| `DiskScanService.cs` | `ExcludedExtrasSubFolderRegex` — Radarr punya `sample[s]?`, Sonarr `samples` (`:72` di keduanya). Tiga regex lainnya identik. |
| import services | `Series`/`Episode` vs `Movie`; gerbang title-preference `AggregateEpisodes` milik Sonarr tidak punya padanan di Radarr (§7.1). Keduanya menolak path impor yang merupakan folder library sebelum melakukan hal lain (Sonarr `:175-182`, Radarr `:183-190`) dan mem-parse nama folder setelahnya (Sonarr `:184`, Radarr `:195`); Radarr juga mencari riwayat grab berdasarkan `DownloadId` di sana (`:193-194`). |
| `ImportApprovedEpisodes.cs` / `ImportApprovedMovie.cs` | switch `copyOnly` identik, Sonarr `:139-152` / Radarr `:116-129`. |
| `DiskTransferService.cs`, `DownloadClientBase.cs`, `DownloadEventHub.cs`, `Json.cs`, `HttpClient.cs`, `HttpRequestBuilder.cs` | bersama, identik byte per byte. |

Semua bagian lain dalam dokumen ini **identik byte per byte kecuali Series/Movie** dan berlaku untuk keduanya di baris yang sama.

---

(Terjemahan sebelumnya ditolak: rasio panjang 0,10. Pertahankan struktur persis seperti aslinya.)

## 10. Contoh payload minimal tapi lengkap {#10-minimal-but-complete-example-payloads}

### 10.1 `GET /api/v2/app/webapiVersion`

```
2.11.2
```

`Content-Type: text/plain`. Bukan JSON, tanpa tanda kutip, tidak perlu baris baru di akhir.

### 10.2 `POST /api/v2/auth/login`

Body request: `username=sonarr&password=hunter2`, `application/x-www-form-urlencoded`.

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8
Set-Cookie: SID=8f3c1c0e9a1f4d2f9c0b7a5e3d1f6b2a; path=/

Ok.
```

Kredensial salah: tetap **200**, body `Fails.`, tidak pernah 401.

### 10.3 `GET /api/v2/app/preferences`

Hanya sepuluh kunci dari §1.4 yang dibaca; boleh kirim lebih, nanti diabaikan.

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

Syarat wajib:

- `save_path` harus ada sebagai direktori **di host Sonarr/Radarr** (`RemotePathMappingCheck`, §8).
- `max_ratio_enabled: false` + `max_seeding_time_enabled: false` membuat
  `RemovesCompletedDownloads` tetap false, sehingga tes koneksi (§6.1 kasus 5) dan health check tetap tenang.
- `dht: true`, atau magnet tanpa tracker akan ditolak di sisi klien (§6.5).
- `max_ratio_act` harus berupa **integer** (§0.6).

### 10.4 `GET /api/v2/torrents/categories`

```json
{
  "tv": { "name": "tv", "savePath": "" },
  "movies": { "name": "movies", "savePath": "" }
}
```

Sebuah **objek** JSON, `savePath` dalam **camelCase**, tidak pernah diawali dengan `//` (§1.5). Kalau `savePath` kosong,
folder root output tetap mengikuti `save_path` global.

### 10.5 `GET /api/v2/torrents/info?category=tv` — satu sedang diunduh, satu siap diimpor {#105-get-apiv2torrentsinfocategorytv--one-downloading-one-importable}

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

Persyaratan wajib:

- Harus berupa **array** JSON (`List<QBittorrentTorrent>`). Jika berupa object, akan error di dalam `GetTorrents` dan gagal di
  `TestGetTorrents` (§6.4).
- `hash` harus **huruf kecil** (§1.8) dan persis sama dengan infohash yang dihitung \*arr dari magnet atau
  `.torrent` (§1.7).
- `size` dalam **byte**; `progress` berupa pecahan 0..1. `RemainingSize = size × (1 − progress)`.
- `eta: 8640000` dibaca sebagai "unknown" dan menghasilkan `RemainingTime` bernilai null (`:622-625`). Item dengan `Completed` tetap mendapat `TimeSpan.Zero` apa pun kondisinya (`:273`).
- `state` mengikuti tabel di §2, dan huruf besar-kecilnya harus persis sama.
- `content_path` harus **absolut, sudah ada, dan ≠ `save_path`** pada item Completed (§4.1). Boleh kosong
  selama item belum Completed.
- `ratio_limit: 0` + `ratio: 0` adalah resep pemindahan (§3.5).
- `category` harus sama dengan kategori yang dikonfigurasi di client. Client tidak memfilter ulang, jadi hormati query parameter.
- `seeding_time` boleh dihilangkan sama sekali. Client akan kembali ke `torrents/properties`, dan hanya jika batas seeding-time memang sedang berlaku.

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

Hanya `save_path` dan `seeding_time` yang dibaca (§1.8). **404 untuk hash yang tidak dikenal**. Begitulah cara `IsTorrentLoaded` memberi tahu bahwa torrent-nya "belum ada" (`:110-126`).

### 10.7 `GET /api/v2/torrents/files?hash=<hash>`

```json
[
  { "index": 0, "name": "Some.Show.S01E03.1080p.WEB.h264-GRP/ep3.mkv", "size": 1073741824, "progress": 1, "priority": 1, "is_seed": true, "piece_range": [0, 2047], "availability": 1 }
]
```

Hanya `name` yang dibaca, relatif terhadap `save_path`, dengan pemisah `/` (§1.13). Urutan itu penting pada jalur pra-2.6.1: komponen paling atas dari `files[0]` menjadi folder output.

### 10.8 `POST /api/v2/torrents/add`

Permintaan, form urlencoded (magnet yang panjang justru dikirim sebagai multipart, lihat §0.3):

```
urls=magnet%3A%3Fxt%3Durn%3Abtih%3A3B1A...&category=tv&stopped=False
```

Respons:

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8

Ok.
```

Apa pun selain teks harfiah `Fails.` dianggap berhasil (§1.7). Body 200 yang kosong juga berhasil.

### 10.9 `POST /api/v2/torrents/delete`

Request: `hashes=3b1a1469c180f447b77021074dbbccaef62611e7&deleteFiles=true`

Response: `HTTP/1.1 200 OK`, body kosong. **Tetap 200 untuk hash yang tidak dikenal** (§5.2).

### 10.10 `POST /api/v2/torrents/createCategory`, `setCategory`, `setShareLimits`, `topPrio`, `setForceStart`

Semua menerima form urlencoded dan semuanya membalas `200` dengan body kosong. `topPrio` bisa membalas **409** yang artinya "queueing is disabled" — client hanya mengabaikan status itu (§1.10). `setShareLimits` bisa membalas **404** yang artinya "not supported" — itu juga diabaikan (§1.9).

---

## 11. Perbedaan dengan qBittorrent asli — di mana model zurg lebih sempit atau lebih luas {#11-differences-from-real-qbittorrent--where-zurgs-model-is-narrower-or-wider}

### 11.1 Tidak ada seeding, jadi gerbang seed-limit harus dipalsukan {#111-there-is-no-seeding-so-the-seed-limit-gate-has-to-be-faked}

qBittorrent asli menghitung `ratio` dari byte yang benar-benar di-upload, dan pengguna bisa mengatur batas global atau batas per-torrent. Gerbang `CanMoveFiles` di client ada supaya file tidak ditarik dari bawah torrent yang masih memenuhi kewajiban ratio (`QBittorrent.cs:240-241`). Backend debrid tidak meng-upload apa pun, tidak pernah. Jadi shim menyatakan `ratio: 0, ratio_limit: 0`, artinya batas per-torrent sudah terpenuhi. Ini jujur dalam satu-satunya arti yang bisa dipakai field ini di sini, dan pengaturan global tetap tidak ikut campur sama sekali (§3.5).

### 11.2 `content_path` selalu folder, bukan file {#112-content_path-is-always-a-folder-never-a-file}

Di qBittorrent asli, `contentPath()` mengembalikan **file path** untuk torrent yang hanya berisi satu file (`torrentimpl.cpp:582-583`). Di bawah `__magic__`, setiap release adalah folder yang berisi file-filenya ([magic.md](../guides/magic.md#with-nothing-stored-it-is-__all__s-releases-as-real-folders)), termasuk release yang hanya berisi satu file.

Konsekuensinya, semuanya menguntungkan sisi client:

- `ProcessPath` selalu memakai cabang **folder** (`DownloadedEpisodesImportService.cs:80-90`), tidak pernah cabang file (`:92-102`). Cabang folder inilah yang menerapkan `FilterPaths`, `ShouldDeleteFolder`, dan parse nama folder, jadi filter extras dan fallback judul dari nama folder selalu aktif.
- Penolakan per-file dari `ProcessFile` (ekstensi berbahaya/executable/tidak didukung, prefix `._`; §7.4) tetap bisa terjadi, tapi lewat filter ekstensi di `GetVideoFiles`, bukan lewat cabang level atas.
- Walk `GetImportItem` versi pra-2.6.1 (§4.2) juga akan tetap jalan, karena `files[0].name` selalu membawa folder release. Tapi tidak ada alasan untuk melaporkan versi selama itu.

Yang perlu dipahami dengan benar: karena selalu berupa folder, `content_path` selalu `save_path + "/" + <release folder>` dan karena itu tidak pernah sama dengan `save_path`. Peringatan `DownloadClientQbittorrentTorrentStatePathError` (§4.1) secara struktur tidak mungkin terjadi. Ini hasil yang benar, bukan kebetulan yang sebaiknya kamu andalkan.

### 11.3 `name` bukan judul yang diambil, dan bisa berubah {#113-name-is-not-the-grabbed-title-and-it-can-change}

Qbittorrent yang asli melaporkan nama dari metadata torrent, dan nama itu tidak berubah. Nama zurg berasal dari library:

- Real-Debrid mengganti nama rilis yang nama filenya kena blokir 451 (`WEB-DL`, tag `Rip`, dan beberapa pasangan source-titik-codec, sesuai pengukuran 2026-10-14). Lihat bagian RD 451 di `CLAUDE.md` pada monorepo.
- zurg menambahkan sufiks saat dua rilis punya nama yang sama, dan repair membangun ulang sebuah rilis dengan torrent id baru.
- Nama dibaca dari library di setiap poll, jadi nama bisa berubah **di antara poll** untuk id yang sudah dilacak \*arr.

Semua itu tidak merusak pelacakan, karena pelacakan memakai `DownloadId`, yaitu infohash, bukan nama. Yang rusak adalah jalur parsing judul di §7.1. Ada dua aturan dari situ:

1. **Gunakan infohash yang dihitung \*arr sebagai kunci**, jangan pernah sesuatu yang internal ke zurg. Infohash itulah satu-satunya penghubung antara grab, riwayat grab, dan poll.
2. **Pastikan nama folder `__magic__` tetap bisa di-parse**, karena itu fallback yang dibaca oleh cabang folder (`DownloadedEpisodesImportService.cs:184`).

### 11.4 Tidak ada progres dan tidak ada fase metadata {#114-there-is-no-progress-and-no-metadata-phase}

Tidak ada yang perlu diunduh, jadi tidak ada `progress`, `eta`, `dlspeed`, atau `metaDL` yang berarti. Batasannya sama seperti yang didokumentasikan endpoint SAB ([sabnzbd.md](../guides/sonarr-radarr.md), *Apa yang berfungsi, dan apa yang tidak*: "Tidak ada progress. Sebuah job masuk antrean atau sudah selesai"). Pemetaan yang paling masuk akal adalah: **Queued** (`queuedDL`) selama library belum mencantumkan rilisnya, dan **Completed** (`pausedUP`) begitu rilisnya sudah tercantum *dan ukuran file-nya sudah stabil*. Untuk `size`, ambil nilai dari apa pun yang dideklarasikan backend supaya entri antrean tidak kosong.

Jangan pakai `metaDL` untuk kondisi menunggu kecuali `dht: true` juga dilaporkan. Hanya dalam kasus itu statusnya Queued (`:288-297`). `queuedDL` tidak bersyarat dan tidak membawa pesan apa pun.

Jangan pakai `stalledDL`, `error`, atau `missingFiles` untuk masa tunggu sementara. Ketiganya adalah **Warnings** (§2) dan akan muncul di antrean sebagai masalah.

### 11.5 Menghapus hanya menyembunyikan; tidak menghancurkan {#115-deleting-hides-it-does-not-destroy}

`torrents/delete?deleteFiles=true` di qBittorrent asli menghapus torrent-nya dan menjalankan `rm -rf` pada datanya.
Di sini, endpoint ini harus hanya menghapus catatannya: rilisnya tetap disajikan dari torrent penyedia, dan
folder yang memang ingin dihapus oleh \*arr sudah ditandai sendiri lewat mount (§5.2,
[magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)). Ini persis alasan yang dicatat `deleteFromHistory` di `internal/sabnzbd/api.go:596-609`.

(Terjemahan sebelumnya ditolak: code span berbeda (`internal/sabnzbd`). Pertahankan struktur persis seperti aslinya.)

### 11.6 Semua yang bisa diminta klien tapi tidak punya apa-apa untuk diterapkan {#116-everything-the-client-can-ask-for-that-has-nothing-to-apply-to}

`sequentialDownload`, `firstLastPiecePrio`, `contentLayout`, `stopped`/`paused`, `setForceStart`,
`topPrio`, `setShareLimits`, `dlLimit`/`upLimit`: terima semuanya, balas 200, tapi tidak menerapkan apa-apa. Hanya dua yang punya dampak nyata jika ditolak: `topPrio` (409 diabaikan, selain itu muncul peringatan) dan `setShareLimits` (404 diabaikan). Keduanya tidak memblokir grab.

`contentLayout` perlu dicatat. Pengaturan ini ada di \*arr justru untuk memaksa qBittorrent menyimpan folder tingkat atas sehingga `content_path != save_path`. Di bawah `__magic__`, layout selalu berupa folder apa pun yang terjadi (§11.2), jadi parameter ini tidak berpengaruh dan operator bisa membiarkannya di Default.

---

## 12. Daftar periksa implementasi (14 poin) {#12-implementation-checklist-14-points}

1. **Hanya API v2.** Jawab `/api/v2/app/webapiVersion` dengan `2.11.2`, dan kembalikan **404** untuk `/version/api` supaya probe v1 gagal dengan bersih.

2. **Auth:** terima header `Authorization: Bearer <key>`, `Authorization: Basic` yang dikirim lebih dulu (preemptive), cookie `SID`, atau tanpa auth sama sekali. Jawab `POST /api/v2/auth/login` dengan **200 + `Ok.` + `Set-Cookie: SID=…`**. Untuk kredensial yang salah, jawab `Fails.` (tetap 200), jangan pernah 401. Jangan wajibkan `Referer` atau `Origin`.

3. **Error berupa status HTTP, bukan JSON.** 403 berarti "login lagi" dan akan dicoba ulang sekali. 403 kedua muncul sebagai connection error, bukan auth error. 404 bermakna pada `torrents/properties` (hash tidak dikenal) dan pada `torrents/setShareLimits` (tidak didukung). 409 bermakna pada `torrents/topPrio` (queueing mati). Selain itu semuanya harus 200.

4. **Parse kedua encoding form pada `torrents/add`:** urlencoded, dan multipart jika ada nilai yang lebih dari 1024 byte atau `.torrent` diunggah. Terima `True`/`False` selain `true`/`false` untuk setiap boolean.

5. **`torrents/info` mengembalikan array, `torrents/categories` mengembalikan objek** dengan `savePath` dalam camelCase. Hormati parameter query `category`. Client tidak memfilter ulang.

6. **Hash: huruf kecil di setiap response, dan dicocokkan tanpa memedulikan huruf besar-kecil di setiap request.** Selalu gunakan infohash yang dihitung \*arr dari magnet atau `.torrent`. `torrents/properties` adalah satu-satunya route yang boleh menerima hash dalam kapitalisasi apa pun yang dipakai `torrents/info`.

7. **Resep move:** `state: "pausedUP"`, `ratio: 0`, `ratio_limit: 0`, `seeding_time_limit: -2`, `inactive_seeding_time_limit: -2`. Kalau kurang dari ini, impor jadi **salinan**, yaitu download penuh dari release. Dokumentasikan bahwa pengaturan "Remove Completed" di \*arr harus tetap aktif, karena shim tidak bisa mengompensasinya.

8. **`content_path` harus absolut, harus ada di host \*arr, dan tidak boleh sama dengan `save_path`.** Set hanya setelah release benar-benar bisa diimpor, yaitu sudah tercantum dan ukuran file-nya sudah stabil. Sampai saat itu, laporkan `queuedDL` dan biarkan client terus polling. Tidak ada batas retry.

9. **`save_path`** (dari `app/preferences`, ditambah `savePath` kategori mana pun) harus ada sebagai direktori di host \*arr. Kalau tidak, `RemotePathMappingCheck` akan memunculkan error. Direktorinya tidak harus bisa ditulis. Jangan pernah mengeluarkan `savePath` yang diawali `//`.

10. **Jaga connection test tetap hijau:** `dht: true`, `queueing_enabled: true`, `max_ratio_enabled: false`, `max_seeding_time_enabled: false`, dan `max_ratio_act: 0` (integer). Lalu pilih salah satu: buat dulu kategori yang sudah dikonfigurasi, atau hormati `createCategory` dan tampilkan hasilnya di response `torrents/categories` berikutnya.

11. **`torrents/delete` hanya menghapus record-nya, tidak ada yang lain.** Abaikan `deleteFiles` untuk torrent provider, sama seperti `deleteFromHistory` di `internal/sabnzbd` mengabaikan `del_files` (`internal/sabnzbd/api.go:596-609`). Jawab 200 untuk hash yang tidak dikenal. Terima `setCategory` dan catat kategori barunya.

12. **Harapkan \*arr menjalankan `rm -rf` sendiri pada folder release** setelah impor Move (`DownloadedEpisodesImportService.cs:209-223`). Folder itu akan menjadi tombstone `__magic__`. Setelahnya \*arr juga memanggil `torrents/delete`. Keduanya normal, dan tidak ada yang rusak.

13. **Hanya pakai nama state dari §2, dengan huruf persis.** Nama yang tidak dikenal tidak akan melempar error di sini (berbeda dengan SAB), tetapi akan dicatat ke log dan default ke Downloading. Jangan pernah pakai `stalledDL`, `error`, atau `missingFiles` untuk jeda sementara. Ketiganya adalah Warning.

14. **Jangan taruh root folder sama dengan atau di atas folder output.** Dengan `save_path` = `/mnt/zurg/__magic__/__all__`, gunakan `/mnt/zurg/__magic__/tv` dan `/mnt/zurg/__magic__/movies` sebagai root folder, dan simpan release di `/mnt/zurg/__magic__/__all__/<release>`. Kalau tidak, `SeriesPathExists`/`MoviePathExists` akan langsung menolak impor (§7.4), dan `DownloadClientRootFolderCheck` di Radarr akan mengeluh setiap kali start.
