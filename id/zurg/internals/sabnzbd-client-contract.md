# SABnzbd API-kontrak seperti yang digunakan oleh Sonarr dan Radarr (develop) {#sabnzbd-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Sumber kebenaran: file yang diambil dari `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...`
pada **2026-08-22**. Setiap nomor baris di bawah ini dibaca langsung dari file-file tersebut.

Disimpan di sini sebagai catatan mengapa `internal/sabnzbd` menjawab dengan bentuk seperti sekarang. Jangan ubah apa pun di package itu tanpa paragraf di sini yang menjelaskan apa yang dilakukan client terhadap field tersebut. Tag struct yang salah tidak akan memunculkan error, tapi client akan membaca nol. Nilai enum yang salah akan error di deserializer-nya dan ikut menggagalkan seluruh poll. Untuk cara mengarahkan Sonarr atau Radarr ke zurg, lihat [sabnzbd.md](../guides/sonarr-radarr.md).

Kecuali ada bagian yang menyatakan lain, **file SAB di kedua repo identik byte per byte, kecuali BOM UTF-8 dan rename `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie`, dan nomor baris sama persis satu per satu.** Jadi setiap sitasi `Sabnzbd*` berlaku untuk kedua repo di baris yang sama. Path-nya `src/NzbDrone.Core/Download/Clients/Sabnzbd/...` di kedua repo. Diff yang sudah diverifikasi dicatat di §6.

Tidak ada yang di sini spekulasi tentang SAB itu sendiri. Setiap klaim adalah apa yang dilakukan *client*. Jika saya menyebut perilaku Newtonsoft.Json atau runtime .NET (bukan kode Sonarr), saya akan menulisnya secara eksplisit.

---

## 0. Aturan tingkat transport (ini yang pertama kena) {#0-transport-level-rules-these-bite-first}

### 0.1 Bentuk URL {#01-url-shape}

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

- URL dasar: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-66`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; `UrlBase` otomatis diberi `/` di depan kalau belum ada.
  Endpoint-nya adalah hasil itu + `/api` (`SabnzbdProxy.cs:38-44`).
- Parameter suffix selalu ditaruh paling akhir, jadi **`apikey` (atau `ma_username`+`ma_password`) dan `output=json`**
  adalah parameter query terakhir (`HttpRequestBuilder.cs:82` — `QueryParams.Concat(SuffixQueryParams)`).
- `Accept: application/json` dikirim di setiap panggilan. `output=json` juga di setiap panggilan. Tidak ada jalur `output=xml` di mana pun.
- API key dan username/password **tidak bisa dipakai bersamaan**: kalau pakai api key, `ma_username`/`ma_password` diabaikan.

### 0.2 Selalu jawab HTTP 200 — bahkan untuk error {#02-always-answer-http-200--even-for-errors}

`HttpClient.Execute` melempar exception untuk status apa pun >= 400 (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`;
`HttpResponse.cs:54` — `HasHttpError => (int)StatusCode >= 400`; 429 berubah menjadi `TooManyRequestsException`).
`SabnzbdProxy.ProcessRequest` (`SabnzbdProxy.cs:199-215`) mengubahnya menjadi
`DownloadClientException("Unable to connect to SABnzbd, {0}")`.

Pesan `HttpException` berbunyi `"HTTP request failed: [401:Unauthorized] [GET] at [url]"` (`src/NzbDrone.Common/Http/HttpException.cs:18`) — **isi body tidak ada di dalam pesan itu**. Jadi 401 dengan `{"error":"API Key Incorrect"}` tidak akan dikenali oleh `TestAuthentication` (`Sabnzbd.cs:424,429` mencocokkan `ex.Message`), dan tes koneksi malah menampilkan pesan umum "Test was aborted due to an error". **Tiru SAB: HTTP 200 + `{"status": false, "error": "..."}`.**

### 0.3 Pengaturan deserializer (menentukan setiap pertanyaan soal nama field dan tipe) {#03-deserializer-settings-drives-every-field-name-and-type-question}

Semua payload SAB lewat `NzbDrone.Common.Serializer.Json`
(`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`), **Newtonsoft**, bukan System.Text.Json:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Konsekuensinya (semantik Newtonsoft, bukan kode Sonarr):

| Pengaturan | Efek pada emulator |
|---|---|
| `CamelCasePropertyNamesContractResolver` | Properti C# `Storage` terhubung ke `storage`, `PP` ke `pp`, dan `Misc` ke `misc`. Newtonsoft juga mencoba pencocokan properti tanpa membedakan huruf besar/kecil, jadi key SAB yang asli (snake_case/huruf kecil) tetap cocok dengan keduanya. |
| `StringEnumConverter` (global) | Berlaku untuk `SabnzbdDownloadStatus`, yang **tidak** punya converter per-properti. Nama enum yang tidak dikenal akan melempar `JsonSerializationException`. Angka integer juga diterima (`AllowIntegerValues` defaultnya true). |
| `NullValueHandling.Ignore` | Saat **membaca** juga: JSON `null` membiarkan member C# tetap pada nilai constructor-nya. Jadi `"categories": null` mempertahankan list kosong dari ctor, tetapi `"misc": null` membuat `Misc` tetap null (tidak ada default di ctor) → NRE, lihat §3.4. |
| `MissingMemberHandling` (default `Ignore`) | Field ekstra di payload kamu tidak berbahaya. Kirim body SAB yang lengkap dan asli. |
| `Culture` (default `InvariantCulture`) | String angka seperti `"1024.00"` harus pakai `.` sebagai pemisah desimal dan tanpa pemisah ribuan. |

`Json.Deserialize<T>` hanya melempar ulang `JsonReaderException` dengan pesan yang lebih rapi (`Json.cs:39-50`);
`Json.TryDeserialize<T>` hanya menelan **`JsonReaderException` dan `JsonSerializationException`** (`Json.cs:99-117`). Selain itu (misalnya `ArgumentException` dari converter timeleft, atau NRE dari converter priority) akan lolos begitu saja.

---

## 1. Setiap mode, setiap parameter, setiap field yang dipakai {#1-every-mode-every-parameter-every-field-consumed}

### 1.1 `mode=version` — `SabnzbdProxy.GetVersion` (`SabnzbdProxy.cs:85-95`)

Request: `GET /api?mode=version&apikey=KEY&output=json`

Model response `SabnzbdVersionResponse` (`Responses/SabnzbdVersionResponse.cs:5`):

| JSON key | C# type | Catatan |
|---|---|---|
| `version` | `string` | Satu-satunya field yang dibaca. |

Dibaca lewat `Json.TryDeserialize`. Kalau parse gagal, `Version == null` (`SabnzbdProxy.cs:89-92`).

Parsing (`Sabnzbd.cs:334-366`), regex di `Sabnzbd.cs:38`:

```csharp
// patch can be a number (releases) or 'x' (git)
private static readonly Regex VersionRegex = new Regex(@"(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+|x)", RegexOptions.Compiled);
```

- Tidak di-anchor, jadi `4.5.0RC1` dan `2.0.0beta1` tetap ter-parse (fixture `SabnzbdFixture.cs:523,553`).
- `patch` bisa berupa huruf `x` (build git), dan akan diganti jadi `0` (`Sabnzbd.cs:351`).
- Versi **dua komponen** (`"4.5"`) tidak match → `null` → validasi gagal.
- String `"develop"` persis (tidak case-sensitive) diperlakukan khusus jadi `3.0.0` (`Sabnzbd.cs:355-362`)
  dan menghasilkan *warning*, bukan kegagalan (`Sabnzbd.cs:380-387`).

Version diambil lagi (round-trip `mode=version` kedua) oleh `HasVersion` di
`Sabnzbd.cs:294-332` — hasilnya **tidak di-cache**.

### 1.2 `mode=get_config` — `SabnzbdProxy.GetConfig` (`SabnzbdProxy.cs:97-104`)

Permintaan: `GET /api?mode=get_config&apikey=KEY&output=json`

Menggunakan `Json.Deserialize` (**bukan** Try). Body yang rusak akan melempar exception dari `GetConfig`.
Level paling atas harus `{"config": {...}}` (`Responses/SabnzbdConfigResponse.cs:5`). Lihat §3 untuk daftar field-nya.

### 1.3 `mode=fullstatus` — `SabnzbdProxy.GetFullStatus` (`SabnzbdProxy.cs:106-114`)

Permintaan: `GET /api?mode=fullstatus&skip_dashboard=1&apikey=KEY&output=json`

Level teratas `{"status": {...}}` (`Responses/SabnzbdFullStatusResponse.cs:5`). Hanya satu field yang dibaca:

| Kunci JSON | C# | Sumber |
|---|---|---|
| `completedir` | `string CompleteDir` | `SabnzbdFullStatus.cs:9-10` — perhatikan: **`completedir`, tanpa underscore** |

Dipanggil **hanya** ketika `config.misc.complete_dir` *tidak* rooted **dan** versi SAB >= 2.0
(`Sabnzbd.cs:220-226`). Dengan `complete_dir` berupa absolut, endpoint ini tidak pernah dipanggil, tapi tetap implementasikan.

Hal unik yang perlu diketahui: karena body yang sebenarnya adalah `{"status": {...}}` dan `SabnzbdJsonError.Status` berupa `string`, `TryDeserialize<SabnzbdJsonError>` di `CheckForError` gagal dengan `JsonSerializationException` lalu jatuh ke cabang plain-text, yang mengatur `Status = "true"` (`SabnzbdProxy.cs:224-240`). Tidak berbahaya, tapi artinya fullstatus tidak akan pernah melaporkan error lewat jalur JSON.

### 1.4 `mode=queue` (baca) — `SabnzbdProxy.GetQueue` (`SabnzbdProxy.cs:116-130`) {#14-modequeue-read--sabnzbdproxygetqueue-sabnzbdproxycs116-130}

Permintaan: `GET /api?mode=queue&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- `category` hanya ditambahkan **jika** kategori yang dikonfigurasi tidak kosong (`SabnzbdProxy.cs:122-125`).
- Pemanggil: `Sabnzbd.GetQueue()` memakai `start=0, limit=0` (`Sabnzbd.cs:57`). SAB membaca `limit=0` sebagai "semua";
  `Sabnzbd.GetCategories()` memakai `start=0, limit=1` pada jalur pra-2.0 (`Sabnzbd.cs:229`);
  `Sabnzbd.RemoveItem()` memanggilnya sekali lagi untuk memutuskan apakah item ada di queue atau history (`Sabnzbd.cs:199`).
- Ekstraksi: `Json.Deserialize<SabnzbdQueue>(JObject.Parse(response).SelectToken("queue").ToString())` (`SabnzbdProxy.cs:129`). **Jika kunci `queue` di level atas tidak ada, akan terjadi NRE.**

`SabnzbdQueue` (`SabnzbdQueue.cs`):

| Kunci JSON | C# | Tipe | Digunakan untuk |
|---|---|---|---|
| `my_home` | `DefaultRootFolder` | `string` | Hanya di SAB < 2.0 untuk menyelesaikan `complete_dir` relatif (`Sabnzbd.cs:230`). Komentar di `SabnzbdQueue.cs:8`: "Removed in Sabnzbd 2.0.0, see mode=fullstatus instead." |
| `paused` | `Paused` | `bool` | Jeda global; digabung dengan prioritas slot (`Sabnzbd.cs:78`). |
| `slots` | `Items` | `List<SabnzbdQueueItem>` | |

`SabnzbdQueueItem` (`SabnzbdQueueItem.cs`):

| Kunci JSON | Anggota C# | Tipe C# | Tipe JSON asli SAB | Catatan |
|---|---|---|---|---|
| `status` | `Status` | `SabnzbdDownloadStatus` | string | `StringEnumConverter` global. Nilai yang tidak dikenal ⇒ `JsonSerializationException` ⇒ seluruh `GetQueue` melempar exception. |
| `index` | `Index` | `int` | number | Dibaca, tidak pernah dipakai. |
| `timeleft` | `Timeleft` | `TimeSpan` lewat `SabnzbdQueueTimeConverter` | string | Lihat §1.4.1. |
| `mb` | `Size` | `decimal` | **string** (`"1024.00"`) | **Megabyte.** `TotalSize = (long)(Size * 1024 * 1024)` (`Sabnzbd.cs:72`). |
| `mbleft` | `Sizeleft` | `decimal` | **string** | **Megabyte.** `RemainingSize = (long)(Sizeleft * 1024 * 1024)` (`Sabnzbd.cs:73`). |
| `filename` | `Title` | `string` | string | Menjadi `DownloadClientItem.Title` (`Sabnzbd.cs:71`). |
| `priority` | `Priority` | `SabnzbdPriority` lewat `SabnzbdPriorityTypeConverter` | string (`"Normal"`) | Lihat §2. |
| `cat` | `Category` | `string` | string | **`cat` di queue, `category` di history.** |
| `mbleft`/`percentage` | `Percentage` | `int` | **string** (`"50"`) | Dibaca, tidak pernah dipakai. |
| `nzo_id` | `Id` | `string` | string | ID unduhan yang dijadikan kunci utama oleh Sonarr/Radarr. |

#### 1.4.1 Format `timeleft` — `SabnzbdQueueTimeConverter` (`JsonConverters/SabnzbdQueueTimeConverter.cs:15-28`) {#141-timeleft-format--sabnzbdqueuetimeconverter-jsonconverterssabnzbdqueuetimeconvertercs15-28}

```csharp
var split = reader.Value.ToString().Split(':').Select(int.Parse).ToArray();
switch (split.Length)
{
    case 4: return new TimeSpan((split[0] * 24) + split[1], split[2], split[3]);   // d:h:m:s
    case 3: return new TimeSpan(split[0], split[1], split[2]);                     // h:m:s
    default: throw new ArgumentException("Expected either 0:0:0:0 or 0:0:0 format, but received: " + reader.Value);
}
```

- **Harus berisi tepat 3 atau 4 bilangan bulat yang dipisahkan titik dua.** `"0:08:32"`, `"40:12:14"`, `"1:16:12:14"` semuanya oke (fixture `SabnzbdQueueTimeConverterFixture.cs:14-20`); `"1"`, `"0:1"`, `"0:0:0:0:1"` akan melempar error (`:28-35`). Angka nol di depan tidak masalah (`int.Parse`).
- `ArgumentException` yang dilempar **tidak** ditangkap oleh `Json.TryDeserialize` maupun `Json.Deserialize`.
- String **kosong** `""` akan di-split jadi `[""]` → `int.Parse` melempar `FormatException`. Jangan pernah kirim `""`.
- Kalau `timeleft` dihilangkan sama sekali, itu aman: converter tidak dipanggil dan `Timeleft` tetap `TimeSpan.Zero`.

### 1.5 `mode=queue&name=delete` — `SabnzbdProxy.RemoveFromQueue` (`SabnzbdProxy.cs:64-72`)

```
GET /api?mode=queue&name=delete&del_files={0|1}&value={nzo_id}&apikey=KEY&output=json
```

`del_files = deleteData ? 1 : 0` (`SabnzbdProxy.cs:68`). **Tidak ada parameter `archive` pada jalur antrean.**
Isi respons hanya diproses melalui `CheckForError`; tidak ada yang dideserialisasi.

### 1.6 `mode=history` (baca) — `SabnzbdProxy.GetHistory` (`SabnzbdProxy.cs:132-146`) {#16-modehistory-read--sabnzbdproxygethistory-sabnzbdproxycs132-146}

Permintaan: `GET /api?mode=history&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- Pemanggil: `Sabnzbd.GetHistory()` dengan `start=0, limit=_configService.DownloadClientHistoryLimit`
  (`Sabnzbd.cs:110`). Default **60** di kedua repo
  (Sonarr `src/NzbDrone.Core/Configuration/ConfigService.cs:184`, Radarr `:236`).
- Ekstraksi: `SelectToken("history")` (`SabnzbdProxy.cs:145`) — level teratas harus berupa `{"history": {...}}`.

`SabnzbdHistory` (`SabnzbdHistory.cs`): `paused` (`bool`, tidak dipakai), `slots` → `Items`.

`SabnzbdHistoryItem` (`SabnzbdHistoryItem.cs`):

| Kunci JSON | Anggota C# | Tipe C# | Catatan |
|---|---|---|---|
| `fail_message` | `FailMessage` | `string` | Jadi `DownloadClientItem.Message` (`Sabnzbd.cs:132`) dan memicu kasus khusus Warning (§1.6.1). |
| `bytes` | `Size` | `long` | **BYTES, bukan MB** — `TotalSize = sabHistoryItem.Size` apa adanya (`Sabnzbd.cs:128`). Ini perbedaan terbesar dengan `mode=queue`. |
| `category` | `Category` | `string` | Catatan: `category`, sedangkan queue memakai `cat`. |
| `nzb_name` | `NzbName` | `string` | Dibaca, tidak pernah dipakai. |
| `download_time` | `DownloadTime` | `int` (detik) | Dibaca, tidak pernah dipakai. |
| `storage` | `Storage` | `string` | Path output. Lihat §1.6.2 — path inilah yang nanti kena `rm -rf`. |
| `status` | `Status` | `SabnzbdDownloadStatus` | `StringEnumConverter` global. |
| `nzo_id` | `Id` | `string` | |
| `name` | `Title` | `string` | |

**Tidak ada anggota bertipe `DateTime` di model SAB, jadi tidak ada format tanggal yang dibatasi.**
`completed` / `last_history_update` (unix epoch di SAB asli) tidak pernah dibaca.
Nilai waktu yang benar-benar penting hanya `timeleft` (§1.4.1) dan `download_time` (integer detik yang tidak dibaca).

#### 1.6.1 Status history → `DownloadItemStatus` (`Sabnzbd.cs:116-158`) {#161-history-status--downloaditemstatus-sabnzbdcs116-158}

```
Deleted                                   -> skipped entirely (Sabnzbd.cs:116-119)
Failed  + fail_message == "Unpacking failed, write error or disk is full?"
        (InvariantCultureIgnoreCase)      -> DownloadItemStatus.Warning     (:140-144)
Failed  (any other message)               -> DownloadItemStatus.Failed      (:147)
Completed                                 -> DownloadItemStatus.Completed   (:152)
anything else (Verifying/Moving/...)      -> DownloadItemStatus.Downloading (:157)
```

Setiap item riwayat mendapat `RemainingSize = 0`, `RemainingTime = TimeSpan.Zero`, `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:129-135`).

`DownloadItemStatus` sendiri (`src/NzbDrone.Core/Download/DownloadItemStatus.cs:3-11`): `Queued=0, Paused=1, Downloading=2, Completed=3, Failed=4, Warning=5`.

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

Loop-nya jalan **sampai ke root** dan menyimpan leluhur *paling tinggi* yang segmen terakhirnya sama dengan
`name`. Tujuannya: kalau `storage` menunjuk ke file di dalam folder job, loop akan mundur ke folder job (fixture `SabnzbdFixture.cs:376-391`). Kalau `storage` sudah berupa folder job, tidak ada leluhur yang cocok dan `OutputPath == storage`, dan itu memang yang kamu mau.

**Rekomendasi untuk emulator: isi `storage` dengan path folder job itu sendiri.**

`storage` kosong ⇒ `OutputPath` tetap kosong ⇒ `CompletedDownloadService.ValidatePath` memberi peringatan "Download doesn't contain intermediate path, Skipping." (Sonarr `CompletedDownloadService.cs:299-303`).

### 1.7 `mode=history&name=delete` — `SabnzbdProxy.RemoveFromHistory` (`SabnzbdProxy.cs:74-83`)

```
GET /api?mode=history&name=delete&del_files={0|1}&value={nzo_id}&archive={0|1}&apikey=KEY&output=json
```

```csharp
request.AddQueryParam("del_files", deleteData ? 1 : 0);          // :78
request.AddQueryParam("value", id);                              // :79
request.AddQueryParam("archive", deletePermanently ? 0 : 1);     // :80   <-- inverted
```

dan pemanggilnya (`Sabnzbd.cs:208`):

```csharp
_proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
```

Jadi `deletePermanently == (status is Failed)`, dan oleh karena itu:

| Status item | `del_files` | `archive` |
|---|---|---|
| Completed | 1 | **1** (arsipkan) |
| Failed | 1 | **0** (hapus permanen) |

Ya, sekilas memang terbaca terbalik, tapi begitulah cara kerja kodenya.

### 1.8 `mode=addfile` — `SabnzbdProxy.DownloadNzb` (`SabnzbdProxy.cs:46-62`)

```
POST /api?mode=addfile&cat={category}&priority={int}&apikey=KEY&output=json
Content-Type: multipart/form-data; boundary=...
  part: Content-Disposition: form-data; name="name"; filename="<CleanFileName(Release.Title)>.nzb"
        Content-Type: application/x-nzb
```

- Field multipart-nya memang bernama `name`, dan bagiannya membawa `filename` (`SabnzbdProxy.cs:53`, `HttpRequestBuilder.cs:379-395`, dihasilkan di `:180-195`).
- Nama file berasal dari `FileNameBuilder.CleanFileName(release.Title) + ".nzb"` (Sonarr `src/NzbDrone.Core/Download/UsenetClientBase.cs:43`, Radarr `:43`).
- **`cat` mengabaikan argumen `category` dari method** dan langsung membaca setting (`SabnzbdProxy.cs:50`: `request.AddQueryParam("cat", settings.TvCategory);` — Radarr: `settings.MovieCategory`). Tidak masalah, karena pemanggil mengirim nilai yang sama.
- `priority` adalah `int` mentah dari `SabnzbdPriority` (lihat §2), dipilih berdasarkan kebaruan:
  Sonarr `Sabnzbd.cs:43` `remoteEpisode.IsRecentEpisode() ? Settings.RecentTvPriority : Settings.OlderTvPriority`;
  Radarr `Sabnzbd.cs:43` `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie ? RecentMoviePriority : OlderMoviePriority`.
- Respons `SabnzbdAddResponse` (`Responses/SabnzbdAddResponse.cs`):

| Kunci JSON | C# | Tipe |
|---|---|---|
| `status` | `Status` | `bool` — di-parse, lalu **tidak pernah dibaca** |
| `nzo_ids` | `Ids` | `List<string>`, di-inisialisasi kosong di konstruktor |

  Dibaca dengan `TryDeserialize`; jika gagal, dipakai `{Status=true, Ids=[]}` sintetis (`SabnzbdProxy.cs:55-59`). Lalu `Sabnzbd.cs:47-52`:

```csharp
if (response == null || response.Ids.Empty())
{
    throw new DownloadClientRejectedReleaseException(remoteEpisode.Release, "SABnzbd rejected the NZB for an unknown reason");
}

return response.Ids.First();
```

  **`nzo_ids` harus berupa array string yang tidak kosong.** `"nzo_ids": null` sama saja dengan tidak ada (`NullValueHandling.Ignore` mempertahankan daftar kosong dari konstruktor) dan juga gagal dengan cara yang sama.

### 1.9 Status queue → `DownloadItemStatus` (`Sabnzbd.cs:60-103`) {#19-queue-status--downloaditemstatus-sabnzbdcs60-103}

```
Deleted                                       -> skipped (Sabnzbd.cs:62-65)
(queue.paused && slot.priority != Force) || slot.status == Paused
                                              -> Paused, and RemainingTime forced to null (:78-84)
Queued | Grabbing | Propagating               -> Queued        (:85-90)
everything else                               -> Downloading   (:93)
```

Juga `Sabnzbd.cs:96-100`: judul yang diawali dengan teks harfiah `"ENCRYPTED /"` akan dihapus 11 karakter tersebut, dan item itu ditandai `IsEncrypted = true`.

Setiap item antrean mendapat `CanBeRemoved = true` dan `CanMoveFiles = true` (`Sabnzbd.cs:75-76`).

### 1.10 Filter kategori sisi klien (`Sabnzbd.cs:186-195`) {#110-client-side-category-filter-sabnzbdcs186-195}

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

Kesetaraan string ordinal. Item di kategori `*` hanya diterima kalau kategori yang dikonfigurasi kosong.

### 1.11 Mode yang ada di proxy tapi tidak pernah dipanggil {#111-modes-that-exist-in-the-proxy-but-are-never-called}

- `mode=retry&value={id}` (`SabnzbdProxy.cs:148-160`, response `{status, nzo_id}` →
  `Responses/SabnzbdRetryResponse.cs`). `ISabnzbdProxy.RetryDownload` tidak punya **pemanggil** di kedua repo.
- `Responses/SabnzbdCategoryResponse.cs` (`{"categories": [...]}`, yaitu `mode=get_cats`) sepenuhnya **tidak dipakai** di kedua repo.
- `Sabnzbd.ValidatePath` (`Sabnzbd.cs:576-592`) bersifat private dan tidak pernah dipanggil (mati).

## 2. `SabnzbdDownloadStatus` dan `SabnzbdPriority` — anggota persis, penanganan unknown/null {#2-sabnzbddownloadstatus-and-sabnzbdpriority--exact-members-unknownnull-handling}

### 2.1 `SabnzbdPriority.cs` (file lengkap) {#21-sabnzbdprioritycs-complete-file}

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

- `Enum.TryParse<T>(string, out T)` adalah overload yang **case-sensitive** (semantik .NET).
  `"Normal"` berhasil di-parse; `"normal"` **tidak**. Saat gagal, `output` berisi
  `default(SabnzbdPriority) == 0 == Normal`, jadi huruf kapital yang salah diam-diam jadi Normal.
  `"Force"` itu penting (§1.9), `"force"` tidak akan jalan.
- String angka juga bisa di-parse: `"2"` → `Force`, `"-100"` → `Default`. Angka JSON `2` juga jalan
  (`reader.Value.ToString()` == `"2"`).
- **`"priority": null` akan melempar `NullReferenceException`** (`reader.Value.ToString()` pada null).
  Ini *tidak* ditangkap oleh `Json.TryDeserialize`. Hilangkan key-nya atau kirim nilai yang sebenarnya.
- Menghilangkan `priority` itu aman: converter tidak dipanggil, member tetap `Normal` (0).
- Converter hanya didaftarkan di `SabnzbdQueueItem.Priority` (`SabnzbdQueueItem.cs:21`);
  item history tidak punya priority.
- Integer yang sama ini juga yang dikirim balik oleh Sonarr/Radarr sebagai `&priority=` pada `mode=addfile`
  (`SabnzbdSettings.cs` men-default `Recent*Priority` dan `Older*Priority` ke
  `(int)SabnzbdPriority.Default` = `-100`).

### 2.2 `SabnzbdDownloadStatus.cs` (file lengkap), urutan deklarasi = nilai implisit 0..15 {#22-sabnzbddownloadstatuscs-complete-file-declaration-order--implicit-values-015}

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

- **Tidak ada converter per-property.** `StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }` yang didaftarkan secara global (`Json.cs:32`) yang menanganinya.
- **Nama yang tidak dikenal akan melempar error** (Newtonsoft `EnumUtils.ParseEnum` → `JsonSerializationException`). Karena `GetQueue`/`GetHistory` memakai `Json.Deserialize` (bukan Try), seluruh panggilan queue atau history ikut gagal. **Jangan pernah mengirim status di luar daftar ini.**
- Kirim penulisan SAB yang kanonik persis seperti di atas (`"Downloading"`, `"QuickCheck"`, `"Completed"`, `"Failed"`, `"Propagating"`, ...). Pencocokan enum Newtonsoft memang jatuh ke pencocokan tanpa memedulikan huruf besar-kecil, tapi huruf yang persis sama adalah satu-satunya hal yang layak diandalkan.
- Integer juga diterima (`AllowIntegerValues` default true), tapi jangan dipakai.
- JSON `null` untuk `status` diabaikan oleh `NullValueHandling.Ignore`, dan anggotanya tetap `Grabbing` (0). Slot queue diam-diam jadi `Queued`, slot history diam-diam jadi `Downloading`. Selalu kirim status yang eksplisit.

---

## 3. `get_config`: apa saja yang dibaca, dan aturan validasinya {#3-get_config-exactly-what-is-read-and-the-validation-rules}

### 3.1 Model — `SabnzbdCategory.cs` {#31-the-model--sabnzbdcategorycs}

Berkas ini memuat `SabnzbdConfig`, `SabnzbdConfigMisc`, `SabnzbdCategory` **dan** `SabnzbdSorter`.
Tidak ada **`SabnzbdConfig.cs`** di kedua repo (sudah saya cek lewat daftar konten GitHub API untuk `src/NzbDrone.Core/Download/Clients/Sabnzbd`).

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

### 3.2 `config.misc.*` — kumpulan lengkap key yang dibaca (`SabnzbdCategory.cs:23-37`) {#32-configmisc--the-complete-set-of-keys-read-sabnzbdcategorycs23-37}

| Kunci JSON | Tipe C# | Dibaca di | Fungsi |
|---|---|---|---|
| `complete_dir` | `string` | `Sabnzbd.cs:218` | Dasar untuk setiap path kategori. |
| `tv_categories` | `string[]` | `Sabnzbd.cs:265, 493` | |
| `enable_tv_sorting` | `bool` | `Sabnzbd.cs:265, 493` | |
| `movie_categories` | `string[]` | `Sabnzbd.cs:269, 502` | |
| `enable_movie_sorting` | `bool` | `Sabnzbd.cs:269, 502` | |
| `date_categories` | `string[]` **via `SabnzbdStringArrayConverter`** | `Sabnzbd.cs:273, 511` | |
| `enable_date_sorting` | `bool` | `Sabnzbd.cs:273, 511` | |
| `pre_check` | `bool` | `Sabnzbd.cs:443` | |
| `history_retention` | `string` | `Sabnzbd.cs:540, 561-573` | Format lama, SAB < 4.3. |
| `history_retention_option` | `string` | `Sabnzbd.cs:541, 544` | SAB >= 4.3. |
| `history_retention_number` | `int` | `Sabnzbd.cs:542, 553` | SAB >= 4.3. |

`SabnzbdStringArrayConverter` (`JsonConverters/SabnzbdStringArrayConverter.cs:25-39`) — hanya dipakai untuk `date_categories` (`SabnzbdCategory.cs:30`):

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

Sebuah **string** JSON akan jadi array dengan 1 elemen; **null** jadi `[null]` (array 1 elemen yang isinya null); **array** akan di-deserialize seperti biasa; selain itu (angka, objek) akan melempar error. Komentar dokumentasi di `:7-9`: "Pada beberapa properti, sab men-serialize array berisi satu item sebagai string biasa."

### 3.3 `config.categories[]` — `SabnzbdCategory` (`SabnzbdCategory.cs:39-48`)

| Kunci JSON | C# | Dibaca di |
|---|---|---|
| `priority` | `int Priority` | tidak pernah dibaca |
| `pp` | `string PP` | tidak pernah dibaca (camelCase dari `PP` adalah `pp`) |
| `name` | `string Name` | `Sabnzbd.cs:251, 255, 458` |
| `script` | `string Script` | tidak pernah dibaca |
| `dir` | `string Dir` | `Sabnzbd.cs:238` (`Dir.TrimEnd('*')`), `Sabnzbd.cs:462` (`Dir.EndsWith("*")`) |

`FullPath` (`OsPath`) dihitung, bukan di-deserialize.

Perakitan path — `Sabnzbd.GetCategories` (`Sabnzbd.cs:216-244`):

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

`OsPath.operator+` (`src/NzbDrone.Common/Disk/OsPath.cs:420-448`) mengembalikan `left` saat `right.IsEmpty`,
jadi `dir: ""` memberi `FullPath == complete_dir` persis. `IsRooted` untuk path bertipe Unix
adalah `_path.StartsWith("/")` (`OsPath.cs:142-145`). Tipe path ditebak dari string
(`OsPath.cs:43-60`): awalan `/` berarti Unix, `\` atau huruf drive berarti Windows. Path bertipe Unix
yang diberikan ke Sonarr yang berjalan di Windows akan gagal di `CompletedDownloadService.ValidatePath` (`:305-310`).

### 3.4 Dua jebakan NRE (dan mana yang sebenarnya aman) {#34-the-two-nre-landmines-and-what-is-actually-safe}

| Bentuk payload | Hasil |
|---|---|
| **`"misc"` tidak ada atau `null`** | `Misc` tetap null (tidak ada default di ctor; `NullValueHandling.Ignore` saat membaca) → **NullReferenceException di `Sabnzbd.cs:218`**, muncul sebagai "Test was aborted due to an error: …" dan sebagai error yang tercatat di pemeriksaan kesehatan. |
| **kategori dengan `"dir"` tidak ada atau `null`** | `Dir` jadi null → **NullReferenceException di `Sabnzbd.cs:238`** (`category.Dir.TrimEnd('*')`) dan lagi di `:462` (`category.Dir.EndsWith("*")`). |
| `"categories": null` atau tidak ada | Aman. List kosong dari ctor tetap ada. `GetStatus` lalu tidak menemukan kategori dan `OutputRootFolders` tetap kosong. |
| `"sorters": null` atau tidak ada | Aman. List kosong dari ctor; `config.Sorters.Any(...)` di `Sabnzbd.cs:484` tetap berjalan. |
| `"servers": null` atau tidak ada | Aman dan tidak pernah dibaca (`List<object>`, `SabnzbdCategory.cs:19`). |
| `"tv_categories"/"movie_categories"/"date_categories": null` | Aman: `ContainsCategory` mengembalikan `true` untuk null/kosong (§3.5), tetapi itu baru berpengaruh jika `enable_*_sorting` yang sesuai bernilai true. |

**Aturan: selalu kirim `misc` sebagai objek dan setiap kategori dengan `dir` berupa string (gunakan `""`).**

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

Dikonfirmasi oleh fixture: `enable_tv_sorting=true` + `tv_categories=null` **gagal**
(`SabnzbdFixture.cs:636-645`), dan + `tv_categories=[]` juga **gagal** (`:647-656`).
`TvCategory=null` + `tv_categories=["Default"]` gagal (`:680-691`).

### 3.6 `Test()` — urutan dan aturan persisnya (`Sabnzbd.cs:286-292`) {#36-test--the-exact-order-and-rules-sabnzbdcs286-292}

```csharp
protected override void Test(List<ValidationFailure> failures)
{
    failures.AddIfNotNull(TestConnectionAndVersion());
    failures.AddIfNotNull(TestAuthentication());
    failures.AddIfNotNull(TestGlobalConfig());
    failures.AddIfNotNull(TestCategory());
}
```

Dibungkus oleh `DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`), yang menangkap exception apa pun yang lolos dan menambahkan `"Test was aborted due to an error: " + ex.Message`.

**`TestConnectionAndVersion()` (`Sabnzbd.cs:368-414`)** — 1 × `mode=version`:

1. Versi tidak bisa di-parse → gagal pada field `Version` (`DownloadClientSabnzbdValidationUnknownVersion`).
2. `rawVersion == "develop"` (abaikan huruf besar/kecil) → **warning** pada `Version`, `IsValid` tetap true (fixture `SabnzbdFixture.cs:566-577`).
3. `version.Major >= 1` → lulus (`:389-392`).
4. Selain itu, `version.Minor >= 7` → lulus (`:394-397`).
5. Selain itu, gagal: versi yang dibutuhkan `"0.7.0"` (`:399-404`).
   Tabel fixture (`SabnzbdFixture.cs:549-564`): `0.6.9`→false, `0.7.0`/`0.8.0`/`1.0.0`/`1.0.0RC1`/`1.1.x`→true.
6. Exception apa pun → gagal pada field `Host` ("unable to connect"), detail = `ex.Message` (`:406-413`).

**`TestAuthentication()` (`Sabnzbd.cs:416-438`)** — 1 × `mode=get_config`. Menangkap exception, lalu mencocokkan `ex.Message` dengan `ContainsIgnoreCase`:

| Substring yang cocok | Field kegagalan |
|---|---|
| `API Key Incorrect` | `APIKey` — `DownloadClientValidationApiKeyIncorrect` |
| `API Key Required` | `APIKey` — `DownloadClientValidationApiKeyRequired` |
| selain itu | **dilempar ulang** → "Test was aborted due to an error: …" generik |

Karena `CheckForError` membungkus body sebagai `"Error response received from SABnzbd: {error}"` (`SabnzbdProxy.cs:244`), pencocokan akan berhasil jika string `error`-mu *mengandung* `API Key Incorrect` / `API Key Required`, yaitu kata-kata bawaan SAB sendiri.

**`TestGlobalConfig()` (`Sabnzbd.cs:440-453`)** — 1 × `mode=get_config`, ditambah 1 × `mode=version` hanya jika `pre_check` bernilai true:

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

Batas minimum: **SAB >= 1.1.0** (`HasVersion(major:1, minor:1, patch:0)`, `Sabnzbd.cs:294-332`). `pre_check: false` melewati seluruh cabang ini, termasuk round-trip `mode=version` tambahan.

**`TestCategory()` (`Sabnzbd.cs:455-521`)** — 1 × `mode=get_config` (yang *ketiga*), ditambah apa pun yang dibutuhkan `GetCategories`. Pengecekan dijalankan berurutan, dan hasil pertama yang cocok langsung dipakai:

1. Kategori yang cocok (`Name == Settings.TvCategory` / `MovieCategory`) dan `dir`-nya **berakhir dengan `*`** → warning pada `TvCategory`/`MovieCategory` "enable job folders", InfoLink `config/categories/` (`:460-469`).
2. Tidak ada kategori yang cocok **dan** kategori yang dikonfigurasi tidak kosong → warning `DownloadClientValidationCategoryMissing`, InfoLink `config/categories/` (`:471-481`).
3. `config.Sorters.Any(s => s.is_active && ContainsCategory(s.sort_cats, cat))` → warning, InfoLink `config/sorting/` (`:483-491`). Komentar kode di `:483`: *"Baru di SABnzbd 4.1, tapi di versi lebih lama ini akan kosong dan tidak berlaku"*.
4. `misc.enable_tv_sorting && ContainsCategory(misc.tv_categories, cat)` → warning (`:493-500`).
5. `misc.enable_movie_sorting && ContainsCategory(misc.movie_categories, cat)` → warning (`:502-509`).
6. `misc.enable_date_sorting && ContainsCategory(misc.date_categories, cat)` → warning (`:511-518`).

`SabnzbdSorter` (`SabnzbdCategory.cs:50-66`): yang dibaca adalah `sort_cats` (`List<string>`, kosong saat konstruksi) dan `is_active` (`bool`). Yang ada di model tapi tidak pernah dibaca: `name`, `order`, `min_size`, `multipart_label`, `sort_string`, `sort_type` (`List<int>`).

**Catatan lalu lintas:** keempat method `Test*` membuat panggilannya sendiri, dan tidak ada yang di-cache. Jadi satu test koneksi biasanya mengirim sekitar **2 × `mode=version` dan 3 × `mode=get_config`** (panggilan version ke-4 jika `pre_check` true).

### 3.7 Retensi history `config.misc` → `RemovesCompletedDownloads` (`Sabnzbd.cs:538-574`) {#37-configmisc-history-retention--removescompleteddownloads-sabnzbdcs538-574}

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

`true` memunculkan **peringatan** health-check
(`HealthCheck/Checks/DownloadClientRemovesCompletedDownloadsCheck.cs:44-53`).
Cakupan fixture `SabnzbdFixture.cs:455-510`: nilai lama `"0"`/`""`/`null`/`"15d"` → false;
`"-1"`/`"15"`/`"3"`/`"3d"` → true.

**Jawaban emulator yang paling bersih: `history_retention_option: "all"`, `history_retention_number: 0`,
`history_retention: "0"`.**

### 3.8 `SortingMode` dan health check-nya (`Sabnzbd.cs:263-279`) {#38-sortingmode-and-its-health-check-sabnzbdcs263-279}

`GetStatus` mengatur `SortingMode` ke `"TV"`, `"Movie"`, atau `"Date"` dengan
predikat yang sama, yaitu `enable_*_sorting && ContainsCategory(...)`. Nilai apa pun yang tidak kosong akan
memunculkan peringatan di `HealthCheck/Checks/DownloadClientSortingCheck.cs:45-55`. Pastikan ketiga `enable_*_sorting` tetap `false`.

### 3.9 `IsLocalhost` (`Sabnzbd.cs:260`)

```csharp
IsLocalhost = Settings.Host == "127.0.0.1" || Settings.Host == "localhost"
```

Ordinal, case-sensitive; `::1`, `Localhost` dan hostname apa pun **tidak** dihitung. Ini mengubah pesan
`RemotePathMappingCheck` yang kamu dapatkan (lihat §6.2).

---

## 4. Penanganan error — `CheckForError` (`SabnzbdProxy.cs:222-246`) {#4-error-handling--checkforerror-sabnzbdproxycs222-246}

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

`SabnzbdJsonError` (`SabnzbdJsonError.cs`, lengkap):

```csharp
public string Status { get; set; }
public string Error  { get; set; }

public bool Failed => !string.IsNullOrWhiteSpace(Status) &&
                      Status.Equals("false", StringComparison.InvariantCultureIgnoreCase);
```

Aturan, lebih tepatnya:

- `CheckForError` jalan di **setiap** respons, sebelum deserialisasi khusus mode apa pun
  (`SabnzbdProxy.cs:217`).
- `Status` bertipe `string`, tapi SAB mengirim **boolean** JSON. Newtonsoft mengubah `false` → `"False"`, yang dicocokkan `Failed` tanpa memedulikan huruf besar-kecil. Baik `false` (boolean) maupun `"false"` (string) sama-sama berfungsi.
- Respons tanpa `status` di level atas (mis. `{"version": …}`, `{"queue": {...}}`,
  `{"history": {...}}`, `{"config": {...}}`) membuat `Status` null → `Failed` false → tidak ada error.
- `status: true` → `"True"` → tidak gagal.
- **Body non-JSON**: `TryDeserialize` mengembalikan false (ia menangkap `JsonReaderException` dan
  `JsonSerializationException`, `Json.cs:107-116`) lalu cabang teks biasa dijalankan. Body yang diawali `error` (tidak peka huruf besar-kecil) → `Status = "false"` → melempar
  `DownloadClientException("Error response received from SABnzbd: {body with 'error: ' stripped}")`.
  Body non-JSON lainnya → `Status = "true"` → **dianggap sukses**, lalu deserialisasi khusus mode itu gagal dengan caranya sendiri.
- **Body JSON yang `status`-nya berupa objek** (`mode=fullstatus`) juga masuk ke cabang teks biasa, karena token `StartObject` tidak bisa mengisi properti `string` — `Status` menjadi `"true"`.
- Perhatikan `result.Error = …` yang berlebihan di `:239`: `Error` tetap diisi di cabang sukses. Ini tidak berpengaruh apa-apa (tidak ada yang membaca `Error` kecuali `Failed`).

Pemetaan exception di `ProcessRequest` (`SabnzbdProxy.cs:187-220`):

| Ditangkap | Dilempar |
|---|---|
| `HttpException` (semua non-2xx, termasuk 401/403/404/500) | `DownloadClientException("Unable to connect to SABnzbd, {0}")` |
| `HttpRequestException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |
| `WebException` dengan `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, certificate validation failed.")` |
| `WebException` lainnya | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |

**String kegagalan autentikasi yang persis dicocokkan** (`Sabnzbd.cs:424, 429`, literal persis, dicocokkan dengan `ContainsIgnoreCase` terhadap pesan exception):

- `"API Key Incorrect"`
- `"API Key Required"`

Tidak ada yang lain yang diklasifikasikan. Keluarkan persis apa adanya sebagai nilai `error` dari respons **HTTP 200**.

**Kenapa respons non-200 tidak boleh pernah dikembalikan:** `HttpClient.Execute` melempar exception sebelum `CheckForError` sempat berjalan (`HttpClient.cs:106-121`), pesan `HttpException` yang dihasilkan hanya berisi status/method/URL dan bukan body (`HttpException.cs:18`), jadi pencocokan `"API Key Incorrect"` / `"API Key Required"` tidak akan pernah terpicu. Pengguna malah melihat "Unable to connect to SABnzbd" atau "Test was aborted due to an error" alih-alih pesan yang bisa ditindaklanjuti, dan setiap health check menganggap klien tidak bisa dijangkau.

---

## 5. Urutan setelah impor {#5-the-post-import-sequence}

### 5.1 Siapa yang memanggil `RemoveItem`, dan dengan apa {#51-who-calls-removeitem-and-with-what}

`DownloadEventHub` (`src/NzbDrone.Core/Download/DownloadEventHub.cs`, identik di kedua repo kecuali BOM-nya):

- `Handle(DownloadCompletedEvent)` (`:48-69`): memanggil `MarkItemAsImported` (SAB melempar `NotSupportedException` — `DownloadClientBase.cs:189-192` — dicatat di level debug lalu diabaikan), kemudian langsung return jika item sudah `Removed`, `!CanBeRemoved`, atau masih `Downloading`, lalu langsung return jika `definition.RemoveCompletedDownloads` tidak aktif.
- `Handle(DownloadFailedEvent)` (`:26-46`): bergantung pada `definition.RemoveFailedDownloads`.
- `Handle(DownloadCanBeRemovedEvent)` (`:71-85`): bergantung pada `definition.RemoveCompletedDownloads`.
- Ketiganya berakhir di `RemoveFromDownloadClient` (`:87-103`):

```csharp
_logger.Debug("[{0}] Removing download from {1} history", …);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);   // :92 -- deleteData is ALWAYS true
trackedDownload.DownloadItem.Removed = true;
```

Default `DownloadClientDefinition` (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17-18`):

```csharp
public bool RemoveCompletedDownloads { get; set; } = true;
public bool RemoveFailedDownloads    { get; set; } = true;
```

Jalur API manual `DELETE /api/v3/queue/{id}?removeFromClient=true` juga mengirim `true` (Sonarr `src/Sonarr.Api.V3/Queue/QueueController.cs:342`). **Tidak ada pemanggil di mana pun yang mengirim `deleteData: false`.**

### 5.2 `Sabnzbd.RemoveItem` (`Sabnzbd.cs:197-214`) — urutan persisnya {#52-sabnzbdremoveitem-sabnzbdcs197-214--the-exact-sequence}

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

Jadi urutan request setelah import ke emulator adalah:

1. `GET /api?mode=queue&start=0&limit=0&category=tv&apikey=…&output=json` (untuk memutuskan antara queue dan history)
2. **hapus folder output di filesystem lokal** (§5.3) — sebelum request HTTP lainnya
3. `GET /api?mode=history&name=delete&del_files=1&value={nzo_id}&archive=1&apikey=…&output=json`

Untuk item yang **gagal**: tidak ada hapus lokal (status-nya `Failed`, bukan `Completed`), dan **`archive=0`** —
inversi di `SabnzbdProxy.cs:80` (`archive = deletePermanently ? 0 : 1`, dengan `deletePermanently == (status is Failed)`).

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

- **Ya, ini menghapus folder output secara rekursif.** `DeleteFolder(path, recursive: true)` di `:129`.
- `OutputPath` di sini adalah `storage` dari item riwayat setelah remapping path remote dan penelusuran naik ke folder job (§1.6.2). Untuk direktori magic yang datar, artinya `rm -rf /mnt/zurg/__magic__/__all__/<Title>`.
- Pengaturan yang menentukan adalah toggle **Remove Completed Downloads** di download client (`DownloadClientDefinition.RemoveCompletedDownloads`, default **true**), *bukan* pengaturan di sisi SAB dan bukan `del_files`. Tidak ada saklar "delete data" terpisah di UI.
- Kegagalan diabaikan dengan peringatan. Mount read-only memang akan mencatat log yang berisik, tapi tidak merusak proses import.
- Cakupan fixture `SabnzbdFixture.cs:693-803`: folder dihapus secara rekursif, file dihapus, tidak ada yang terjadi saat path tidak ada, dan benar-benar tidak ada apa pun (bahkan probe `FolderExists`) saat `deleteData` bernilai false.

### 5.4 Mode transfer: file dipindah atau disalin? {#54-transfer-mode-is-the-file-moved-or-copied}

`Sabnzbd` mengatur `CanMoveFiles = true` pada **setiap** item, baik di antrean (`Sabnzbd.cs:76`) maupun di riwayat (`Sabnzbd.cs:135`). Jalur impor otomatis adalah `CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, …)` (Sonarr `CompletedDownloadService.cs:148-151`), lalu:

Sonarr `src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152`
(Radarr `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, logikanya sama persis):

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

`CanMoveFiles: true` ⇒ `copyOnly == false` ⇒ **`TransferMode.Move`** (`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`). Impor dengan `copyOnly` justru akan memakai `TransferMode.HardLinkOrCopy` jika "Use Hardlinks instead of Copy" aktif, dan jika tidak, memakai `TransferMode.Copy` (`:94-108`).

`TransferMode` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`) adalah `[Flags]`: `None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy = Copy|HardLink`.

### 5.5 Apakah Move yang gagal kembali ke copy? — **Tidak. Move yang gagal berarti impor gagal.** {#55-does-a-failed-move-fall-back-to-a-copy--no-a-failed-move-is-a-failed-import}

`src/NzbDrone.Common/Disk/DiskTransferService.cs` (identik byte-per-byte antara kedua repo, sudah diverifikasi).
`TransferFile`, `:256-392`; cabang `TransferMode.Move` di `:360-389`:

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

- **Satu-satunya** fallback copy adalah kasus khusus `isCifs && !isSameMount` di `:378-385`, yang dipicu oleh `targetMount.DriveFormat == "cifs"` (`:342`). Kasus ini dipilih *di awal* berdasarkan drive format, bukan sebagai reaksi terhadap kegagalan.
- `TryMoveFileVerified` (`:487-503`) menangkap exception, memanggil `RollbackPartialMove` (kecuali exception-nya `FileAlreadyExistsException`), lalu **melempar ulang** exception tersebut:

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

- `VerifyFile` (`:505-524`) membandingkan ukuran tujuan dengan ukuran sumber, menunggu 3 detik (`WaitForIO`, `:467-471`), memeriksa ulang, lalu melempar `IOException("File move incomplete, data loss may have occurred. [{target}] was {n} bytes long instead of the expected {m}.")`.
- `IOException` itu merambat ke atas lewat `EpisodeFileMovingService.TransferFile` (`:151`) ke blok `catch (Exception e)` generik di `ImportApprovedEpisodes.cs:218-222` (Radarr `:197-201`), lalu menghasilkan `ImportResult(importDecision, "Failed to import episode")` / `"Failed to import movie"`. **Tidak ada copy yang dicoba.**
- `IOException` pre-flight lainnya di method yang sama: sumber == target (`:270`, `:277`), dan "Destination cannot be a child of the source" (`:312-315`).

Catatan penting, dan ini adalah fakta runtime .NET, bukan kode Sonarr: `DiskProviderBase.MoveFileInternal` (`src/NzbDrone.Common/Disk/DiskProviderBase.cs:293-301`) hanya `File.Move` biasa, dan .NET di Unix akan beralih ke copy+delete saat `rename()` mengembalikan `EXDEV`. Jadi pemindahan lintas filesystem biasanya tetap berhasil, sebagai fallback *runtime*, bukan fallback Sonarr. Yang **tidak** ditoleransi adalah tujuan yang ukurannya berbeda dari sumber, atau exception apa pun yang dilempar oleh `File.Move` itu sendiri (EACCES, EPERM, EROFS di sumber, …).

`TransferFolder` (`:44-137`) dipakai oleh jalur kode lain; perhatikan `:124-131`. Setelah Move folder, method ini menolak menghapus sumber jika masih ada lebih dari 100 MB file yang tersisa (`IOException("Large files still exist in {sourcePath} after folder move, not deleting source folder")`).

---

## 6. Dua health check {#6-the-two-health-checks}

### 6.1 `DownloadClientRootFolderCheck` — **satu-satunya tempat Sonarr dan Radarr benar-benar berbeda** {#61-downloadclientrootfoldercheck--the-one-place-sonarr-and-radarr-genuinely-differ}

Sonarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = status.OutputRootFolders.Where(folder => rootFolders.Any(r => r.Path.PathEquals(folder.FullPath)));
```

Radarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = rootFolders.Where(r => status.OutputRootFolders.Any(folder => r.Path.PathEquals(folder.FullPath) || r.Path.IsParentPath(folder.FullPath)));
```

`IsParentPath` (`src/NzbDrone.Common/Extensions/PathExtensions.cs:123-140`) berjalan **ke atas** dari child:

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

Jadi `r.Path.IsParentPath(folder.FullPath)` bernilai true ketika **root folder adalah leluhur dari
folder output download**, artinya folder output ada *di dalam* root folder. Ini uji leluhur yang ketat
(dimulai dari `child.Directory`). Kesamaan ditangani terpisah oleh `PathEquals`.

**Menjawab pertanyaan predikat secara langsung:**

| Hubungan (folder output O vs root folder R) | Sonarr | Radarr |
|---|---|---|
| O == R | **peringatan** | **peringatan** |
| O di dalam R (R adalah leluhur O) | tidak ada peringatan | **peringatan** |
| O adalah PARENT dari R (O adalah leluhur R) | tidak ada peringatan | **tidak ada peringatan** |
| tidak berhubungan | tidak ada peringatan | tidak ada peringatan |

Dengan `complete_dir = /mnt/zurg/__magic__/__all__` dan `dir: ""` (sehingga
`OutputRootFolders == ["/mnt/zurg/__magic__/__all__"]`):

- Sonarr hanya memberi peringatan jika root folder persis `/mnt/zurg/__magic__/__all__`.
- Radarr memberi peringatan jika root folder adalah `/mnt/zurg/__magic__/__all__`, `/mnt/zurg/__magic__`, `/mnt/zurg`, atau `/mnt`.
- Keduanya tidak memberi peringatan jika root folder adalah `/mnt/zurg/__magic__/tv`. Mirror dan root folder
  adalah saudara setingkat, jadi pasangannya tidak berhubungan dan kedua aturan tidak terpicu. Root folder *di dalam*
  folder output (`/mnt/zurg/__magic__/__all__/anything`) juga tidak akan memberi peringatan di sini, tetapi
  namespace menolak menyimpan apa pun di kedalaman itu, jadi susunan seperti ini memang tidak mungkin ada.

`PathEquals` (`PathExtensions.cs:55-73`) menormalisasi Unicode, memakai `DiskProviderBase.PathStringComparison`
(`OrdinalIgnoreCase` di Windows, `Ordinal` di platform lain, lihat `src/NzbDrone.Common/Disk/DiskProviderBase.cs:17-23`),
dan mencoba lagi dengan `CleanFilePath()` (tidak peka terhadap trailing slash).

Kedua versi dijalankan ulang saat `ProviderUpdatedEvent` / `ProviderDeletedEvent` / `ModelEvent<RootFolder>` /
`ModelEvent<RemotePathMapping>`. Radarr menambahkan `[CheckOn(typeof(ProviderAddedEvent<IDownloadClient>))]`
di baris `:17`. Hasilnya `HealthCheckResult.Warning` dengan anchor `#downloads-in-root-folder`. Pesannya menyisipkan `folder.FullPath` di Sonarr dan `folder.Path` di Radarr (baris `:60` di keduanya). Keduanya diam-diam mengabaikan `DownloadClientException` dan `HttpRequestException` (dicatat sebagai debug log), dan mencatat exception lain sebagai error.

### 6.2 `RemotePathMappingCheck` — jalur klien lokal (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs`) {#62-remotepathmappingcheck--the-local-client-path-srcnzbdronecorehealthcheckchecksremotepathmappingcheckcs}

Short-circuit di `:51-54`: kalau `EnableCompletedDownloadHandling` mati, pengecekannya tidak melakukan apa-apa.

Untuk setiap `folder` di `client.GetStatus().OutputRootFolders`:

1. **`!folder.IsValid`** (`:68`): `OsPath.IsValid` = `_path.IsPathValid(PathValidationType.CurrentOs)`
   (`OsPath.cs:228`). Di non-Windows, ini hanya berarti cek `path.StartsWith("/")` ditambah pemindaian `Path.GetInvalidPathChars()` (`PathExtensions.cs:143-182`, `:403-411`). Error-nya, sesuai urutan:
   - `!status.IsLocalhost` → `RemotePathMappingWrongOSPathHealthCheckMessage` (key Radarr: `RemotePathMappingCheckWrongOSPath`), anchor `#bad-remote-path-mapping`
   - `_osInfo.IsDocker` → …`BadDockerPath`, anchor `#docker-bad-remote-path-mapping`
   - selain itu → …`LocalWrongOSPath`, anchor `#bad-download-client-settings`
2. **`!_diskProvider.FolderExists(folder.FullPath)`** (`:115`):
   - `_osInfo.IsDocker` → …`DockerFolderMissing`, `#docker-bad-remote-path-mapping`
   - `!status.IsLocalhost` → …`LocalFolderMissing`, `#bad-remote-path-mapping`
   - selain itu → …`GenericPermissions`, `#permissions-error`

**Untuk client lokal (`IsLocalhost` true, bukan Docker), ini cuma menyisakan dua syarat:**
output root folder yang dilaporkan harus berupa path absolut *untuk OS tempat Sonarr/Radarr berjalan*, dan harus **ada di host Sonarr/Radarr** sebagai direktori. `/mnt/zurg/__magic__/__all__` harus terlihat oleh proses *arr, bukan cuma oleh emulator. **Di sini tidak ada pengecekan writable.**

Overload yang berbasis event (`:178-368`) jalan saat `EpisodeImportFailedEvent` (Radarr: `MovieImportFailedEvent`) dan, yang penting, memanggil `client.GetItems()` lagi untuk mencari `OutputPath` dari download yang gagal (`:232`).

Tidak ada health check yang mewajibkan output folder *writable*. `FolderWritable` (`DiskProviderBase.cs:126-143` Sonarr / `:127-144` Radarr), yang menulis lalu menghapus `sonarr_write_test.txt` / `radarr_write_test.txt`, dipakai oleh `RootFolderService.Add` (Sonarr `src/NzbDrone.Core/RootFolders/RootFolderService.cs:117-120`) dan oleh `DownloadClientBase.TestFolder` (`:167-187`), dan **`TestFolder` tidak pernah dipanggil oleh SAB client.**

---

## 7. Sonarr vs Radarr — perbedaan lengkap {#7-sonarr-vs-radarr--the-complete-diff}

Setiap file yang diambil sudah di-diff. Hasilnya:

**Identik byte per byte, kecuali UTF-8 BOM di salinan Sonarr** (jadi nomor baris persis sama):

`SabnzbdCategory.cs` (tanpa BOM di kedua sisi, benar-benar identik), `SabnzbdDownloadStatus.cs`,
`SabnzbdPriority.cs`, `SabnzbdFullStatus.cs`, `SabnzbdJsonError.cs`, `SabnzbdQueue.cs`,
`SabnzbdQueueItem.cs`, `SabnzbdHistory.cs`, `SabnzbdHistoryItem.cs`,
`JsonConverters/*.cs` (ketiganya), `Responses/*.cs` (semua enam),
`src/NzbDrone.Common/Disk/DiskTransferService.cs`, `src/NzbDrone.Core/Download/DownloadEventHub.cs`.

**Hanya berbeda karena rename `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` (tidak ada perubahan jumlah baris, nomor baris sama):**

- `Sabnzbd.cs` — `:40-52` (`AddFromNzbFile`; tes kebaruan Radarr adalah `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` vs `remoteEpisode.IsRecentEpisode()` milik Sonarr), `:190`, `:251`, `:265/269/273`, `:458`, dan setiap nama field `NzbDroneValidationFailure` di `TestCategory` (`"TvCategory"` → `"MovieCategory"`).
- `SabnzbdProxy.cs` — `:50`, `:122-124`, `:138-140`.
- `SabnzbdSettings.cs` — default `TvCategory = "tv"` vs `MovieCategory = "movies"`; `RecentTvPriority`/`OlderTvPriority` vs `RecentMoviePriority`/`OlderMoviePriority` (keduanya default ke `(int)SabnzbdPriority.Default`). Validator-nya selain itu identik: `Host` valid, `Port` 1–65535, `ApiKey` wajib jika username kosong, `Username`/`Password` wajib jika ApiKey kosong, kategori `NotEmpty` **sebagai peringatan**.
- `UsenetClientBase.cs` — Radarr juga menetapkan `request.AllowAutoRedirect = true` (`:51`) dan memperlakukan HTTP `410 Gone` seperti `404` (`:63`) saat mengambil NZB dari indexer. **Ini soal indexer, bukan soal SAB.**
- `DownloadClientBase.cs` — hanya string literal "Sonarr"/"Radarr" di teks detail `TestFolder`.
- `RemotePathMappingCheck.cs` — nama key lokalisasi (`RemotePathMapping*HealthCheckMessage` vs `RemotePathMappingCheck*`), `EpisodeImportFailedEvent` vs `MovieImportFailedEvent`, ditambah `[CheckOn(ProviderAddedEvent<IDownloadClient>)]` ekstra milik Radarr. **Predikatnya identik.**
- `DiskProviderBase.cs` — file probe `FolderWritable` `sonarr_write_test.txt` vs `radarr_write_test.txt` (Sonarr `:132`, Radarr `:133`).

**Perbedaan perilaku yang nyata, hanya satu:**

- `DownloadClientRootFolderCheck.cs:51`. Sonarr memberi peringatan hanya pada `PathEquals`; Radarr juga memberi peringatan ketika root folder adalah induk dari output folder. Tabel lengkapnya ada di §6.1.

Selebihnya (mode, params, bentuk JSON, enum, converter, `CheckForError`, `RemoveItem`, `DeleteItemData`, transfer mode, `DiskTransferService`) sama persis. **Satu emulator melayani keduanya.**

Default config sama di kedua aplikasi: `DownloadClientHistoryLimit = 60`, `RemoveCompletedDownloads = true`, `RemoveFailedDownloads = true`.

---

## 8. Contoh payload minimal tetapi lengkap {#8-minimal-but-complete-example-payloads}

Diberikan: `complete_dir = /mnt/zurg/__magic__/__all__`; kategori `*`, `tv`, `movies`, semuanya dengan `dir: ""`.
Setiap respons adalah **HTTP 200** dengan `Content-Type: application/json`.

`OutputRootFolders` yang dihasilkan: `dir: ""` ⇒ `FullPath == complete_dir` ⇒ `/mnt/zurg/__magic__/__all__`
untuk Sonarr (kategori `tv`) dan untuk Radarr (kategori `movies`).

### 8.1 `mode=version`

```json
{
  "version": "4.3.3"
}
```

Harus berupa `major.minor.(patch|x)`. `4` ≥ 1 memenuhi `TestConnectionAndVersion` (`Sabnzbd.cs:389-392`);
≥ 2.0 juga berarti `GetCategories` akan memakai `fullstatus`, bukan `queue.my_home`, jika `complete_dir`
ternyata relatif (padahal tidak).

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

Alasan tiap nilai:

- `misc` ada sebagai objek — **wajib**, kalau tidak akan terjadi NRE (§3.4).
- setiap kategori punya `dir` berupa **string** — **wajib**, kalau tidak akan terjadi NRE di `Sabnzbd.cs:238` dan `:462`.
- `dir` tidak diakhiri `*` — kalau iya, muncul peringatan "enable job folders" (`Sabnzbd.cs:462-469`).
- ketiga `enable_*_sorting: false` — menghilangkan kedua peringatan `TestCategory` (`Sabnzbd.cs:493-518`) dan `DownloadClientSortingCheck`. Perhatikan bahwa `tv_categories: []` digabung dengan `enable_tv_sorting: true` akan **gagal**, karena `ContainsCategory` mengembalikan true untuk daftar kosong (`Sabnzbd.cs:525-528`, fixture `SabnzbdFixture.cs:647-656`).
- `sorters: []` — `config.Sorters.Any(s => s.is_active && …)` akan bernilai false (`Sabnzbd.cs:484`).
- `pre_check: false` — melewati round-trip `HasVersion(1,1)` di `TestGlobalConfig` (`Sabnzbd.cs:443`).
- `history_retention_option: "all"` → `RemovesCompletedDownloads == false` (`Sabnzbd.cs:546-547`) → tidak ada peringatan health-check.
- `complete_dir` berupa path absolut → `IsRooted` bernilai true → `mode=fullstatus` / `queue.my_home` tidak pernah dicek (`Sabnzbd.cs:220`).

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

Hanya `completedir` yang dibaca (`SabnzbdFullStatus.cs:9-10`). Kunci pembungkus **harus** `status`
(`Responses/SabnzbdFullStatusResponse.cs:5`).

### 8.4 Respons `mode=addfile` {#84-modeaddfile-response}

```json
{
  "status": true,
  "nzo_ids": ["SABnzbd_nzo_abc12345"]
}
```

`nzo_ids` harus berupa **array string yang tidak kosong** (`Sabnzbd.cs:47-52`). `status` diparsing
(`Responses/SabnzbdAddResponse.cs:13`) tapi tidak pernah dibaca, jadi biarkan `true` supaya `CheckForError` menerima `"True"`.

### 8.5 `mode=queue&start=0&limit=0&category=tv` — satu slot Downloading {#85-modequeuestart0limit0categorytv--one-downloading-slot}

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

Syarat wajib:

- kunci tingkat atas `queue` (`SabnzbdProxy.cs:129`, `SelectToken("queue")`).
- `slots[].status` harus salah satu dari 16 nama `SabnzbdDownloadStatus`, huruf besar-kecilnya harus persis sama.
- `slots[].mb` / `mbleft` adalah **megabyte**, desimal dengan invariant culture. String atau angka sama-sama bisa dipakai (Newtonsoft mengonversinya); SAB asli mengirim string.
- `slots[].timeleft` harus tepat `h:m:s` atau `d:h:m:s`, jangan pernah `""`.
- `slots[].priority` harus `"Normal"`, `"High"`, `"Low"`, `"Force"`, `"Paused"`, atau `"Default"` (peka huruf besar-kecil), atau padanan numeriknya. **Jangan pernah `null`** (NRE).
- `slots[].cat` (bukan `category`) harus sama dengan kategori yang dikonfigurasi di klien, atau item akan disaring di `Sabnzbd.cs:190`.
- `queue.paused` harus `false` kecuali memang ingin dijeda. Jika `true`, setiap slot non-`Force` akan ditandai Paused dengan ETA null (`Sabnzbd.cs:78-84`).

Hasil `DownloadClientItem`: `TotalSize = 1024 * 1024 * 1024`, `RemainingSize = 512 * 1024 * 1024`, `RemainingTime = 00:08:32`, `Status = Downloading`, `CanBeRemoved = CanMoveFiles = true`.

### 8.6 `mode=history&start=0&limit=60&category=tv` — satu slot Completed dan satu slot Failed {#86-modehistorystart0limit60categorytv--one-completed-and-one-failed-slot}

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

Persyaratan wajib:

- kunci tingkat atas `history` (`SabnzbdProxy.cs:145`).
- `slots[].bytes` harus dalam **BYTES** (angka JSON → `long`). Jangan kirim MB di sini. Antrean memakai MB, sedangkan riwayat memakai bytes (`Sabnzbd.cs:72-73` vs `:128`).
- `slots[].category` (bukan `cat`).
- `slots[].storage` = folder job itu sendiri. Nilai ini menjadi `OutputPath`, dan untuk item Completed, inilah yang dihapus secara rekursif oleh `DeleteItemData` (§5.3). Path harus absolut, valid untuk OS tempat Sonarr/Radarr berjalan, dan harus ada di sana (`RemotePathMappingCheck`, §6.2).
- `slots[].status` harus persis sama huruf besarnya. Item `Deleted` dibuang sepenuhnya (`Sabnzbd.cs:116-119`).
- `fail_message` persis `"Unpacking failed, write error or disk is full?"` akan menurunkan item Failed menjadi `Warning`, bukan `Failed` (`Sabnzbd.cs:140-144`). Pakai pesan lain untuk kegagalan yang sebenarnya.
- Radarr: `category` harus `movies` (atau apa pun yang dikonfigurasi), dan `name` sebaiknya bisa di-parse sebagai film.

### 8.7 Respons error (mode apa pun) {#87-error-response-any-mode}

```json
{
  "status": false,
  "error": "API Key Incorrect"
}
```

**HTTP 200.** `status` bisa berupa boolean `false` atau string `"false"`; keduanya memenuhi
`SabnzbdJsonError.Failed` (`SabnzbdJsonError.cs:10-11`). Client akan melempar
`DownloadClientException("Error response received from SABnzbd: API Key Incorrect")`
(`SabnzbdProxy.cs:244`), yang dikenali oleh `TestAuthentication` (`Sabnzbd.cs:424`).
Gunakan `"API Key Required"` jika tidak ada key yang diberikan (`Sabnzbd.cs:429`). String `error` lain akan ditampilkan apa adanya, tapi tidak diklasifikasikan.

---

## 9. Daftar periksa implementasi (12 poin) {#9-implementation-checklist-12-points}

1. Satu rute: `GET|POST {UrlBase}/api`, dispatch berdasarkan `mode`. **Selalu HTTP 200, selalu JSON.**
2. Implementasikan `version`, `get_config`, `queue` (baca + `name=delete`), `history` (baca + `name=delete`), `addfile`, `fullstatus`. Opsional `retry` (dead code saat ini). `get_cats` tidak pernah dipanggil.
3. Terima autentikasi baik sebagai `apikey=` **atau** `ma_username=`+`ma_password=`. Tolak dengan 200 + `{"status":false,"error":"API Key Incorrect"}` / `"API Key Required"`, jangan pernah 401/403.
4. Hormati `category=` pada `queue`/`history` (klien juga memfilter di sisi klien dengan pencocokan string persis, `Sabnzbd.cs:190`).
5. Ukuran `queue` dalam **MB** (`mb`, `mbleft`); ukuran `history` dalam **BYTES** (`bytes`). Jangan sampai tertukar. Queue memakai `cat`, history memakai `category`.
6. `timeleft` selalu `h:m:s` atau `d:h:m:s`, tidak pernah kosong, dan tidak pernah berupa string kosong atau tidak ada. Tidak ada field tanggal yang di-parse di mana pun, jadi field epoch bebas formatnya.
7. Nilai `status` harus berasal dari daftar 16 anggota `SabnzbdDownloadStatus`, dengan huruf besar-kecil persis sama (nama yang tidak dikenal akan throw dan menggagalkan seluruh pemanggilan queue/history). `priority` harus berupa nama `SabnzbdPriority` (huruf besar-kecil persis sama) atau integernya; **jangan pernah `null`** (NRE di converter).
8. `config.misc` harus berupa objek; setiap kategori harus punya **string `dir` non-null** yang tidak diakhiri `*`. `categories`/`sorters`/`servers` boleh null atau tidak ada, tetapi `misc` dan `dir` tidak boleh.
9. Biarkan `enable_tv_sorting`, `enable_movie_sorting`, `enable_date_sorting` dan `pre_check` semuanya `false`, dan `history_retention_option: "all"`, supaya tes koneksi dan semua health check tetap bersih.
10. `storage` pada slot history Completed adalah folder job. Bersiap bahwa *arr akan `rm -rf` folder itu setelah impor berhasil (pengaturan default), dan bersiap juga bahwa file media akan **dipindahkan** keluar dari folder itu lebih dulu. Jika magic directory read-only, penghapusan akan gagal diam-diam (hanya muncul log peringatan), tetapi *pemindahan* file yang diimpor harus tetap berhasil atau impor gagal total (§5.5).
11. Jangan letakkan root folder *arr di `/mnt/zurg/__magic__/__all__` atau di atasnya jika ingin `DownloadClientRootFolderCheck` Radarr tetap tenang. (Sonarr hanya peduli kesamaan persis.) Letakkan di samping mirror saja, yaitu `/mnt/zurg/__magic__/tv` dan `/mnt/zurg/__magic__/movies`, yang tidak berhubungan dengan folder output, bukan di atas atau di bawahnya.
12. `/mnt/zurg/__magic__/__all__` harus ada sebagai direktori **di host Sonarr/Radarr**, bukan hanya di tempat emulator berjalan, atau `RemotePathMappingCheck` akan memunculkan error. Folder ini tidak perlu bisa ditulis.

## Mengonfigurasi jendela penyelesaian yang lebih besar {#configuring-a-larger-completion-window}

Kedua klien secara default mengatur `DownloadClientHistoryLimit` ke 60. zurg ikut menyesuaikan jendela ini saat menyimpan kelebihan job yang sudah selesai di `queue`. Kalau hanya menaikkan limit di klien, beberapa job akan muncul di queue dan history sekaligus, dan queue yang diutamakan.

Untuk backlog yang besar, atur `sabnzbd.history_limit` di zurg dan `DownloadClientHistoryLimit` di klien ke nilai yang sama, misalnya 500. Dengan begitu, lebih banyak job yang selesai dan gagal ditampilkan per poll. Kalau beberapa klien memakai nilai yang berbeda, biarkan zurg di limit klien yang paling kecil. Setting klien lanjutan ini tidak tersedia di resource konfigurasi download-client Sonarr v4 API, jadi backup dan hentikan klien dulu sebelum mengedit konfigurasi yang tersimpan.

```yaml
sabnzbd:
  enabled: true
  history_limit: 500
```

Default tetap 60; nilai nol dan negatif memakai default itu. Permintaan riwayat diagnostik dengan limit yang berbeda tidak pernah mengubah jendela yang sudah dikonfigurasi. Peringatan yang tidak bisa diselesaikan klien tetap perlu dicek. Jendela yang lebih besar membuat job lain bisa sampai ke import, tapi peringatan itu tetap memakan slot riwayat.

Pengecekan ketersediaan sebelum penyelesaian mengambil sampel dari enam belas artikel pertama dan artikel terakhir di setiap file konten. Ini menangkap artikel yang hilang di header media, yang terlewat oleh canary artikel pertama yang lama. Pengecekan ini mengunduh artikel pertama dari setiap file konten untuk memastikan identitas artikel dan bahwa body-nya masih disajikan (provider bisa menjawab STAT untuk artikel yang body-nya sudah mereka turunkan). Selain itu, artikel acak ditambahkan sampai enam belas body untuk rilis dengan file yang lebih sedikit dari itu, dengan maksimal enam puluh empat body secara total. Body yang sudah ada di cache artikel tidak diambil lagi. STAT mencakup sisa sampelnya. Pengecekan ini tidak memvalidasi setiap artikel dan tidak membuktikan bahwa media bisa di-decode. Permintaan STAT dibatch per file, jadi sampel hanya memakai satu reservasi pool, bukan tujuh belas, tanpa menaikkan batas koneksi akun. Batch yang tidak bisa dipakai akan kembali ke STAT satu per satu. Kegagalan server membuat job tetap queued untuk dicoba lagi. Artikel yang terkonfirmasi hilang menghasilkan download gagal sebelum notifikasi penyelesaian pertama.
