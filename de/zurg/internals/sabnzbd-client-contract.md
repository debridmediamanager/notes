# SABnzbd-API-Vertrag, wie Sonarr und Radarr ihn verwenden (develop) {#sabnzbd-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Quelle der Wahrheit: Dateien, abgerufen von `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...` am **2026-08-22**. Jede Zeilennummer unten wurde aus diesen Dateien abgelesen.

Ich halte das hier fest, damit nachvollziehbar bleibt, warum `internal/sabnzbd` in genau diesen Formen antwortet. In diesem Paket sollte nichts geändert werden, ohne dass der Absatz hier erklärt, was der Client mit dem Feld macht. Ein falsches Struct-Tag schlägt nicht fehl, sondern lässt den Client einfach eine Null lesen. Ein falscher Enum-Wert wirft dagegen im Deserializer eine Exception und reißt die ganze Abfrage mit. Wie du Sonarr oder Radarr auf zurg zeigen lässt, steht in [sabnzbd.md](../guides/sonarr-radarr.md).

Sofern ein Abschnitt nichts anderes sagt, **sind die SAB-Dateien der beiden Repos byte-identisch, bis auf ein UTF-8-BOM und die Umbenennung `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie`. Die Zeilennummern stimmen eins zu eins überein.** Jede `Sabnzbd*`-Angabe gilt deshalb für beide Repos in derselben Zeile. Die Pfade lauten in beiden `src/NzbDrone.Core/Download/Clients/Sabnzbd/...`. Geprüfte Unterschiede stehen in §6.

Hier geht es nicht um Spekulation über SAB selbst. Jede Aussage beschreibt, was der *Client* tut. Wo ich Newtonsoft.Json- oder .NET-Runtime-Verhalten beschreibe (nicht Sonarr-Code), sage ich das ausdrücklich.

---

## 0. Regeln auf Transportebene (diese fallen zuerst auf) {#0-transport-level-rules-these-bite-first}

### 0.1 Form der URL {#01-url-shape}

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

- Basis-URL: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-66`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; `UrlBase` bekommt ein führendes `/`, falls es fehlt.
  Der Endpunkt ist das plus `/api` (`SabnzbdProxy.cs:38-44`).
- Suffix-Parameter landen immer am Ende, also sind **`apikey` (oder `ma_username`+`ma_password`) und `output=json`
  die letzten Query-Parameter** (`HttpRequestBuilder.cs:82` — `QueryParams.Concat(SuffixQueryParams)`).
- `Accept: application/json` bei jedem Aufruf. `output=json` bei jedem Aufruf. Es gibt nirgendwo einen
  `output=xml`-Pfad.
- API-Key und Benutzername/Passwort **schließen sich gegenseitig aus**: Ein API-Key unterdrückt `ma_username`/`ma_password`.

### 0.2 Immer HTTP 200 antworten, auch bei Fehlern {#02-always-answer-http-200--even-for-errors}

`HttpClient.Execute` wirft bei jedem Status >= 400 eine Exception (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`;
`HttpResponse.cs:54` — `HasHttpError => (int)StatusCode >= 400`; 429 wird zu `TooManyRequestsException`).
`SabnzbdProxy.ProcessRequest` (`SabnzbdProxy.cs:199-215`) wandelt das in
`DownloadClientException("Unable to connect to SABnzbd, {0}")` um.

Die Message von `HttpException` ist `"HTTP request failed: [401:Unauthorized] [GET] at [url]"`
(`src/NzbDrone.Common/Http/HttpException.cs:18`) — **der Body steht nicht in der Message**. Ein 401 mit
`{"error":"API Key Incorrect"}` wird also von `TestAuthentication` nicht erkannt
(`Sabnzbd.cs:424,429` vergleicht mit `ex.Message`), und der Verbindungstest meldet stattdessen den allgemeinen
"Test was aborted due to an error". **SAB nachbilden: HTTP 200 + `{"status": false, "error": "..."}`.**

### 0.3 Deserializer-Einstellungen (bestimmen alle Fragen zu Feldnamen und Typen) {#03-deserializer-settings-drives-every-field-name-and-type-question}

Alle SAB-Payloads laufen über `NzbDrone.Common.Serializer.Json`
(`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`), **Newtonsoft**, nicht System.Text.Json:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Konsequenzen (Newtonsoft-Semantik, nicht Sonarr-Code):

| Einstellung | Auswirkung auf einen Emulator |
|---|---|
| `CamelCasePropertyNamesContractResolver` | C#-`Storage` bindet `storage`, `PP` bindet `pp`, `Misc` bindet `misc`. Newtonsoft fällt außerdem auf einen Abgleich der Property-Namen ohne Beachtung der Groß-/Kleinschreibung zurück, daher binden SABs echte snake_case-/Kleinbuchstaben-Schlüssel so oder so. |
| `StringEnumConverter` (global) | Gilt für `SabnzbdDownloadStatus`, das **keinen** eigenen Converter pro Property hat. Unbekannte Enum-Namen werfen eine `JsonSerializationException`. Ganzzahlen werden ebenfalls akzeptiert (`AllowIntegerValues` ist standardmäßig true). |
| `NullValueHandling.Ignore` | Gilt auch **beim Lesen**: Ein JSON-`null` lässt das C#-Member auf seinem Konstruktorwert. Also bleibt bei `"categories": null` die leere Liste aus dem Konstruktor erhalten, aber bei `"misc": null` bleibt `Misc` null (kein Standardwert im Konstruktor) → NRE, siehe §3.4. |
| `MissingMemberHandling` (Standard `Ignore`) | Zusätzliche Felder in deinem Payload sind harmlos. Schick den vollständigen echten SAB-Body. |
| `Culture` (Standard `InvariantCulture`) | Numerische Strings wie `"1024.00"` müssen `.` als Dezimaltrennzeichen verwenden und keine Tausendertrennzeichen enthalten. |

`Json.Deserialize<T>` wirft nur `JsonReaderException` mit einer freundlicheren Meldung erneut (`Json.cs:39-50`);
`Json.TryDeserialize<T>` schluckt **nur** `JsonReaderException` und `JsonSerializationException`
(`Json.cs:99-117`). Alles andere (z. B. eine `ArgumentException` aus dem Timeleft-Converter oder eine NRE
aus dem Priority-Converter) wird weitergereicht.

---

## 1. Jeder Modus, jeder Parameter, jedes verwendete Feld {#1-every-mode-every-parameter-every-field-consumed}

### 1.1 `mode=version` — `SabnzbdProxy.GetVersion` (`SabnzbdProxy.cs:85-95`)

**Anfrage:** `GET /api?mode=version&apikey=KEY&output=json`

Antwortmodell `SabnzbdVersionResponse` (`Responses/SabnzbdVersionResponse.cs:5`):

| JSON-Schlüssel | C#-Typ | Hinweise |
|---|---|---|
| `version` | `string` | Das einzige Feld, das gelesen wird. |

Wird über `Json.TryDeserialize` gelesen. Schlägt das Parsen fehl, ist `Version == null` (`SabnzbdProxy.cs:89-92`).

Parsing (`Sabnzbd.cs:334-366`), Regex in `Sabnzbd.cs:38`:

```csharp
// patch can be a number (releases) or 'x' (git)
private static readonly Regex VersionRegex = new Regex(@"(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+|x)", RegexOptions.Compiled);
```

- Nicht verankert, daher werden `4.5.0RC1` und `2.0.0beta1` erkannt (Fixture `SabnzbdFixture.cs:523,553`).
- `patch` darf das Literal `x` sein (Git-Builds). Es wird durch `0` ersetzt (`Sabnzbd.cs:351`).
- Eine Version mit **zwei Komponenten** (`"4.5"`) passt nicht. Das ergibt `null` und damit einen Validierungsfehler.
- Der exakte String `"develop"` (ohne Beachtung der Groß-/Kleinschreibung) wird speziell behandelt und zu `3.0.0` gemacht (`Sabnzbd.cs:355-362`). Dabei gibt es eine *Warnung*, aber keinen Fehler (`Sabnzbd.cs:380-387`).

Die Version wird von `HasVersion` (`Sabnzbd.cs:294-332`) erneut abgefragt, also ein zweiter `mode=version`-Aufruf. Sie wird **nicht zwischengespeichert**.

### 1.2 `mode=get_config` — `SabnzbdProxy.GetConfig` (`SabnzbdProxy.cs:97-104`)

Anfrage: `GET /api?mode=get_config&apikey=KEY&output=json`

Verwendet `Json.Deserialize` (**nicht** Try). Ein fehlerhafter Body löst in `GetConfig` eine Exception aus.
Die oberste Ebene muss `{"config": {...}}` sein (`Responses/SabnzbdConfigResponse.cs:5`). Die Felder stehen in §3.

### 1.3 `mode=fullstatus` — `SabnzbdProxy.GetFullStatus` (`SabnzbdProxy.cs:106-114`)

**Anfrage:** `GET /api?mode=fullstatus&skip_dashboard=1&apikey=KEY&output=json`

Oberste Ebene `{"status": {...}}` (`Responses/SabnzbdFullStatusResponse.cs:5`). Nur ein Feld wird gelesen:

| JSON-Schlüssel | C# | Quelle |
|---|---|---|
| `completedir` | `string CompleteDir` | `SabnzbdFullStatus.cs:9-10`. Achtung: **`completedir`, ohne Unterstrich** |

Dieser Aufruf erfolgt **nur**, wenn `config.misc.complete_dir` **nicht** absolut ist **und** die SAB-Version >= 2.0
ist (`Sabnzbd.cs:220-226`). Mit einem absoluten `complete_dir` wird dieser Endpunkt nie aufgerufen. Implementiere ihn trotzdem.

Eine Eigenheit, die man kennen sollte: Da der eigentliche Body `{"status": {...}}` ist und `SabnzbdJsonError.Status` ein
`string` ist, schlägt `TryDeserialize<SabnzbdJsonError>` in `CheckForError` mit einer `JsonSerializationException` fehl. Dann greift der
Klartext-Zweig, der `Status = "true"` setzt (`SabnzbdProxy.cs:224-240`). Das ist harmlos, bedeutet aber, dass fullstatus über den JSON-Pfad nie einen Fehler melden kann.

### 1.4 `mode=queue` (lesend) — `SabnzbdProxy.GetQueue` (`SabnzbdProxy.cs:116-130`) {#14-modequeue-read--sabnzbdproxygetqueue-sabnzbdproxycs116-130}

Anfrage: `GET /api?mode=queue&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- `category` wird **nur dann** hinzugefügt, wenn die konfigurierte Kategorie nicht leer ist (`SabnzbdProxy.cs:122-125`).
- Aufrufer: `Sabnzbd.GetQueue()` verwendet `start=0, limit=0` (`Sabnzbd.cs:57`). SAB liest `limit=0` als "alle".
  `Sabnzbd.GetCategories()` verwendet `start=0, limit=1` im Pfad für Versionen vor 2.0 (`Sabnzbd.cs:229`).
  `Sabnzbd.RemoveItem()` ruft es noch einmal auf, um zu entscheiden, ob es sich um Queue oder History handelt (`Sabnzbd.cs:199`).
- Extraktion: `Json.Deserialize<SabnzbdQueue>(JObject.Parse(response).SelectToken("queue").ToString())` (`SabnzbdProxy.cs:129`). **Ein fehlender oberster `queue`-Schlüssel führt zu einer NRE.**

`SabnzbdQueue` (`SabnzbdQueue.cs`):

| JSON-Schlüssel | C#-Name | Typ | Verwendet für |
|---|---|---|---|
| `my_home` | `DefaultRootFolder` | `string` | Nur bei SAB < 2.0, um ein relatives `complete_dir` aufzulösen (`Sabnzbd.cs:230`). Kommentar bei `SabnzbdQueue.cs:8`: "Removed in Sabnzbd 2.0.0, see mode=fullstatus instead." |
| `paused` | `Paused` | `bool` | Globale Pause. Wird mit der Priorität des Slots kombiniert (`Sabnzbd.cs:78`). |
| `slots` | `Items` | `List<SabnzbdQueueItem>` | |

`SabnzbdQueueItem` (`SabnzbdQueueItem.cs`):

| JSON-Schlüssel | C#-Member | C#-Typ | Echter JSON-Typ bei SAB | Hinweise |
|---|---|---|---|---|
| `status` | `Status` | `SabnzbdDownloadStatus` | string | Globaler `StringEnumConverter`. Unbekannter Wert ⇒ `JsonSerializationException` ⇒ der gesamte `GetQueue` wirft eine Exception. |
| `index` | `Index` | `int` | number | Wird gelesen, aber nie verwendet. |
| `timeleft` | `Timeleft` | `TimeSpan` über `SabnzbdQueueTimeConverter` | string | Siehe §1.4.1. |
| `mb` | `Size` | `decimal` | **string** (`"1024.00"`) | **Megabyte.** `TotalSize = (long)(Size * 1024 * 1024)` (`Sabnzbd.cs:72`). |
| `mbleft` | `Sizeleft` | `decimal` | **string** | **Megabyte.** `RemainingSize = (long)(Sizeleft * 1024 * 1024)` (`Sabnzbd.cs:73`). |
| `filename` | `Title` | `string` | string | Wird zu `DownloadClientItem.Title` (`Sabnzbd.cs:71`). |
| `priority` | `Priority` | `SabnzbdPriority` über `SabnzbdPriorityTypeConverter` | string (`"Normal"`) | Siehe §2. |
| `cat` | `Category` | `string` | string | **`cat` in der Queue, `category` in der History.** |
| `mbleft`/`percentage` | `Percentage` | `int` | **string** (`"50"`) | Wird gelesen, aber nie verwendet. |
| `nzo_id` | `Id` | `string` | string | Die Download-ID, über die Sonarr/Radarr alles zuordnen. |

#### 1.4.1 Format von `timeleft` — `SabnzbdQueueTimeConverter` (`JsonConverters/SabnzbdQueueTimeConverter.cs:15-28`) {#141-timeleft-format--sabnzbdqueuetimeconverter-jsonconverterssabnzbdqueuetimeconvertercs15-28}

```csharp
var split = reader.Value.ToString().Split(':').Select(int.Parse).ToArray();
switch (split.Length)
{
    case 4: return new TimeSpan((split[0] * 24) + split[1], split[2], split[3]);   // d:h:m:s
    case 3: return new TimeSpan(split[0], split[1], split[2]);                     // h:m:s
    default: throw new ArgumentException("Expected either 0:0:0:0 or 0:0:0 format, but received: " + reader.Value);
}
```

- **Genau 3 oder 4 durch Doppelpunkte getrennte Ganzzahlen.** `"0:08:32"`, `"40:12:14"`, `"1:16:12:14"` sind alle in Ordnung
  (Fixture `SabnzbdQueueTimeConverterFixture.cs:14-20`); `"1"`, `"0:1"`, `"0:0:0:0:1"` lösen eine Exception aus
  (`:28-35`). Führende Nullen sind kein Problem (`int.Parse`).
- Die ausgelöste `ArgumentException` wird **weder** von `Json.TryDeserialize` **noch** von `Json.Deserialize` abgefangen.
- Ein **leerer String** `""` wird zu `[""]` gesplittet → `int.Parse` wirft `FormatException`. Gib niemals `""` aus.
- Wenn du `timeleft` ganz weglässt, ist das sicher: Der Converter wird nicht aufgerufen und `Timeleft` bleibt `TimeSpan.Zero`.

### 1.5 `mode=queue&name=delete` — `SabnzbdProxy.RemoveFromQueue` (`SabnzbdProxy.cs:64-72`)

```
GET /api?mode=queue&name=delete&del_files={0|1}&value={nzo_id}&apikey=KEY&output=json
```

`del_files = deleteData ? 1 : 0` (`SabnzbdProxy.cs:68`). **Kein `archive`-Parameter im Queue-Pfad.**
Der Response-Body wird nur durch `CheckForError` geleitet; es wird nichts deserialisiert.

### 1.6 `mode=history` (lesend) — `SabnzbdProxy.GetHistory` (`SabnzbdProxy.cs:132-146`) {#16-modehistory-read--sabnzbdproxygethistory-sabnzbdproxycs132-146}

Anfrage: `GET /api?mode=history&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- Aufrufer: `Sabnzbd.GetHistory()` mit `start=0, limit=_configService.DownloadClientHistoryLimit`
  (`Sabnzbd.cs:110`). Standard **60** in beiden Repos
  (Sonarr `src/NzbDrone.Core/Configuration/ConfigService.cs:184`, Radarr `:236`).
- Extraktion: `SelectToken("history")` (`SabnzbdProxy.cs:145`). Die oberste Ebene muss `{"history": {...}}` sein.

`SabnzbdHistory` (`SabnzbdHistory.cs`): `paused` (`bool`, ungenutzt), `slots` → `Items`.

`SabnzbdHistoryItem` (`SabnzbdHistoryItem.cs`):

| JSON-Schlüssel | C#-Member | C#-Typ | Hinweise |
|---|---|---|---|
| `fail_message` | `FailMessage` | `string` | Wird zu `DownloadClientItem.Message` (`Sabnzbd.cs:132`) und steuert den Warning-Sonderfall (§1.6.1). |
| `bytes` | `Size` | `long` | **BYTES, nicht MB**. `TotalSize = sabHistoryItem.Size` wird unverändert übernommen (`Sabnzbd.cs:128`). Das ist die größte Abweichung zu `mode=queue`. |
| `category` | `Category` | `string` | Hinweis: `category`, während die Queue `cat` verwendet. |
| `nzb_name` | `NzbName` | `string` | Wird gelesen, aber nie verwendet. |
| `download_time` | `DownloadTime` | `int` (Sekunden) | Wird gelesen, aber nie verwendet. |
| `storage` | `Storage` | `string` | Der Ausgabepfad. Siehe §1.6.2. Genau dieser Pfad wird mit `rm -rf` gelöscht. |
| `status` | `Status` | `SabnzbdDownloadStatus` | Globaler `StringEnumConverter`. |
| `nzo_id` | `Id` | `string` | |
| `name` | `Title` | `string` | |

**In den SAB-Modellen gibt es nirgends einen `DateTime`-typisierten Member, daher ist kein Datumsformat festgelegt.**
`completed` / `last_history_update` (Unix-Epoche in echtem SAB) werden nie gelesen. Die einzigen zeitartigen Werte, die wirklich zählen, sind `timeleft` (§1.4.1) und `download_time` (eine ungelesene Ganzzahl in Sekunden).

#### 1.6.1 History-Status → `DownloadItemStatus` (`Sabnzbd.cs:116-158`) {#161-history-status--downloaditemstatus-sabnzbdcs116-158}

```
Deleted                                   -> skipped entirely (Sabnzbd.cs:116-119)
Failed  + fail_message == "Unpacking failed, write error or disk is full?"
        (InvariantCultureIgnoreCase)      -> DownloadItemStatus.Warning     (:140-144)
Failed  (any other message)               -> DownloadItemStatus.Failed      (:147)
Completed                                 -> DownloadItemStatus.Completed   (:152)
anything else (Verifying/Moving/...)      -> DownloadItemStatus.Downloading (:157)
```

Jeder Verlaufseintrag bekommt `RemainingSize = 0`, `RemainingTime = TimeSpan.Zero`, `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:129-135`).

Die `DownloadItemStatus` selbst (`src/NzbDrone.Core/Download/DownloadItemStatus.cs:3-11`): `Queued=0, Paused=1, Downloading=2, Completed=3, Failed=4, Warning=5`.

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

Die Schleife läuft **bis ganz nach oben zur Wurzel** und behält den *höchsten* Vorfahren, dessen letztes Segment gleich `name` ist. Zweck: Wenn `storage` auf eine Datei im Job-Ordner zeigt, geht es zurück zum Job-Ordner (Fixture `SabnzbdFixture.cs:376-391`). Wenn `storage` schon der Job-Ordner ist, gibt es keinen passenden Vorfahren und `OutputPath == storage`. Genau das willst du.

**Empfehlung für den Emulator: Setze `storage` direkt auf den Pfad des Job-Ordners.**

Leeres `storage` ⇒ `OutputPath` bleibt leer ⇒ `CompletedDownloadService.ValidatePath` gibt die Warnung "Download doesn't contain intermediate path, Skipping." aus (Sonarr `CompletedDownloadService.cs:299-303`).

### 1.7 `mode=history&name=delete` — `SabnzbdProxy.RemoveFromHistory` (`SabnzbdProxy.cs:74-83`)

```
GET /api?mode=history&name=delete&del_files={0|1}&value={nzo_id}&archive={0|1}&apikey=KEY&output=json
```

```csharp
request.AddQueryParam("del_files", deleteData ? 1 : 0);          // :78
request.AddQueryParam("value", id);                              // :79
request.AddQueryParam("archive", deletePermanently ? 0 : 1);     // :80   <-- inverted
```

und der Aufrufer (`Sabnzbd.cs:208`):

```csharp
_proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
```

Also gilt `deletePermanently == (status is Failed)`, und daher:

| Item-Status | `del_files` | `archive` |
|---|---|---|
| Completed | 1 | **1** (archivieren) |
| Failed | 1 | **0** (endgültig löschen) |

Auf den ersten Blick wirkt das verkehrt herum, aber so macht es der Code nun mal.

### 1.8 `mode=addfile` — `SabnzbdProxy.DownloadNzb` (`SabnzbdProxy.cs:46-62`)

```
POST /api?mode=addfile&cat={category}&priority={int}&apikey=KEY&output=json
Content-Type: multipart/form-data; boundary=...
  part: Content-Disposition: form-data; name="name"; filename="<CleanFileName(Release.Title)>.nzb"
        Content-Type: application/x-nzb
```

- Das multipart-Feld heißt wörtlich `name`, und der Part trägt ein `filename` (`SabnzbdProxy.cs:53`, `HttpRequestBuilder.cs:379-395`, ausgegeben bei `:180-195`).
- Der Dateiname kommt von `FileNameBuilder.CleanFileName(release.Title) + ".nzb"` (Sonarr `src/NzbDrone.Core/Download/UsenetClientBase.cs:43`, Radarr `:43`).
- **`cat` ignoriert das Argument `category` der Methode** und liest die Einstellungen direkt (`SabnzbdProxy.cs:50`: `request.AddQueryParam("cat", settings.TvCategory);` — Radarr: `settings.MovieCategory`). Unproblematisch, weil der Aufrufer denselben Wert übergibt.
- `priority` ist der rohe `int` aus `SabnzbdPriority` (siehe §2), je nachdem wie aktuell die Veröffentlichung ist:
  Sonarr `Sabnzbd.cs:43` `remoteEpisode.IsRecentEpisode() ? Settings.RecentTvPriority : Settings.OlderTvPriority`;
  Radarr `Sabnzbd.cs:43` `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie ? RecentMoviePriority : OlderMoviePriority`.
- Antwort `SabnzbdAddResponse` (`Responses/SabnzbdAddResponse.cs`):

| JSON-Schlüssel | C# | Typ |
|---|---|---|
| `status` | `Status` | `bool` — geparst, danach aber **nie gelesen** |
| `nzo_ids` | `Ids` | `List<string>`, im Konstruktor mit leerer Liste initialisiert |

  Gelesen wird mit `TryDeserialize`. Schlägt das fehl, wird ein künstliches `{Status=true, Ids=[]}` verwendet (`SabnzbdProxy.cs:55-59`). Danach `Sabnzbd.cs:47-52`:

```csharp
if (response == null || response.Ids.Empty())
{
    throw new DownloadClientRejectedReleaseException(remoteEpisode.Release, "SABnzbd rejected the NZB for an unknown reason");
}

return response.Ids.First();
```

  **`nzo_ids` muss ein nicht leeres Array aus Strings sein.** `"nzo_ids": null` ist dasselbe wie fehlend (`NullValueHandling.Ignore` behält die leere Liste aus dem Konstruktor) und schlägt genauso fehl.

### 1.9 Queue-Status → `DownloadItemStatus` (`Sabnzbd.cs:60-103`) {#19-queue-status--downloaditemstatus-sabnzbdcs60-103}

```
Deleted                                       -> skipped (Sabnzbd.cs:62-65)
(queue.paused && slot.priority != Force) || slot.status == Paused
                                              -> Paused, and RemainingTime forced to null (:78-84)
Queued | Grabbing | Propagating               -> Queued        (:85-90)
everything else                               -> Downloading   (:93)
```

Außerdem `Sabnzbd.cs:96-100`: Ein Titel, der mit dem wörtlichen `"ENCRYPTED /"` beginnt, wird um diese
11 Zeichen gekürzt, und der Eintrag wird mit `IsEncrypted = true` markiert.

Jeder Queue-Eintrag bekommt `CanBeRemoved = true` und `CanMoveFiles = true` (`Sabnzbd.cs:75-76`).

### 1.10 Clientseitiger Kategorie-Filter (`Sabnzbd.cs:186-195`) {#110-client-side-category-filter-sabnzbdcs186-195}

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

Ordinale Zeichenketten-Gleichheit. Ein Element in der Kategorie `*` wird nur akzeptiert, wenn die konfigurierte Kategorie leer ist.

### 1.11 Modi, die im Proxy existieren, aber nie aufgerufen werden {#111-modes-that-exist-in-the-proxy-but-are-never-called}

- `mode=retry&value={id}` (`SabnzbdProxy.cs:148-160`, Antwort `{status, nzo_id}` →
  `Responses/SabnzbdRetryResponse.cs`). `ISabnzbdProxy.RetryDownload` hat **keinen Aufrufer** in beiden Repos.
- `Responses/SabnzbdCategoryResponse.cs` (`{"categories": [...]}`, also `mode=get_cats`) ist **komplett unreferenziert** in beiden Repos.
- `Sabnzbd.ValidatePath` (`Sabnzbd.cs:576-592`) ist privat und wird nie aufgerufen (toter Code).

## 2. `SabnzbdDownloadStatus` und `SabnzbdPriority` — genaue Mitglieder, Behandlung von unbekannten Werten und null {#2-sabnzbddownloadstatus-and-sabnzbdpriority--exact-members-unknownnull-handling}

### 2.1 `SabnzbdPriority.cs` (komplette Datei) {#21-sabnzbdprioritycs-complete-file}

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

- `Enum.TryParse<T>(string, out T)` ist die **groß-/kleinschreibungsabhängige** Überladung (.NET-Semantik).
  `"Normal"` wird geparst, `"normal"` **nicht**. Bei einem Fehler ist `output`
  `default(SabnzbdPriority) == 0 == Normal`, d. h. eine falsche Schreibweise wird stillschweigend zu Normal.
  `"Force"` ist wichtig (§1.9), `"force"` funktioniert nicht.
- Numerische Strings werden ebenfalls geparst: `"2"` → `Force`, `"-100"` → `Default`. Eine JSON-Zahl `2` funktioniert auch (`reader.Value.ToString()` == `"2"`).
- **`"priority": null` wirft eine `NullReferenceException`** (`reader.Value.ToString()` auf null). Das wird *nicht* von `Json.TryDeserialize` abgefangen. Lass den Schlüssel weg oder sende einen echten Wert.
- Ein weggelassenes `priority` ist unproblematisch: Der Converter wird nicht aufgerufen, das Mitglied bleibt `Normal` (0).
- Der Converter ist nur auf `SabnzbdQueueItem.Priority` registriert (`SabnzbdQueueItem.cs:21`). Verlaufseinträge haben keine Priorität.
- Dieselben Ganzzahlen schicken Sonarr/Radarr als `&priority=` bei `mode=addfile` zurück (die Standardwerte für `Recent*Priority` und `Older*Priority` in `SabnzbdSettings.cs` sind beide `(int)SabnzbdPriority.Default` = `-100`).

### 2.2 `SabnzbdDownloadStatus.cs` (komplette Datei), Deklarationsreihenfolge = implizite Werte 0..15 {#22-sabnzbddownloadstatuscs-complete-file-declaration-order--implicit-values-015}

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

- **Kein Konverter pro Eigenschaft.** Der global registrierte
  `StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }` (`Json.cs:32`) übernimmt das.
- Ein **unbekannter Name wirft eine Exception** (Newtonsoft `EnumUtils.ParseEnum` → `JsonSerializationException`).
  Und weil `GetQueue`/`GetHistory` `Json.Deserialize` verwenden (nicht Try), schlägt der *gesamte* Queue- oder History-Aufruf fehl. **Sende niemals einen Status, der nicht in dieser Liste steht.**
- Schreib SABs kanonische Schreibweisen genau so wie oben (`"Downloading"`, `"QuickCheck"`, `"Completed"`,
  `"Failed"`, `"Propagating"`, ...). Newtonsofts Enum-Zuordnung fällt zwar auf Groß-/Kleinschreibung-egal zurück,
  aber nur die exakte Schreibweise solltest du dir wirklich zunutze machen.
- Ganzzahlen werden auch akzeptiert (`AllowIntegerValues` ist standardmäßig true), aber verwende sie nicht.
- Ein JSON-`null` für `status` wird von `NullValueHandling.Ignore` ignoriert und das Mitglied bleibt `Grabbing` (0). Ein Queue-Slot wird dann stillschweigend zu `Queued`, ein History-Slot stillschweigend zu `Downloading`. Sende immer einen expliziten Status.

## 3. `get_config`: genau was gelesen wird und die Validierungsregeln {#3-get_config-exactly-what-is-read-and-the-validation-rules}

### 3.1 Das Modell — `SabnzbdCategory.cs` {#31-the-model--sabnzbdcategorycs}

Diese Datei enthält `SabnzbdConfig`, `SabnzbdConfigMisc`, `SabnzbdCategory` **und** `SabnzbdSorter`.
Es gibt **kein `SabnzbdConfig.cs`** in beiden Repos (bestätigt über die Auflistung der GitHub-Contents-API für `src/NzbDrone.Core/Download/Clients/Sabnzbd`).

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

### 3.2 `config.misc.*` — die vollständige Liste der gelesenen Schlüssel (`SabnzbdCategory.cs:23-37`) {#32-configmisc--the-complete-set-of-keys-read-sabnzbdcategorycs23-37}

| Schlüssel (JSON) | C#-Typ | Gelesen bei | Zweck |
|---|---|---|---|
| `complete_dir` | `string` | `Sabnzbd.cs:218` | Basis für jeden Kategoriepfad. |
| `tv_categories` | `string[]` | `Sabnzbd.cs:265, 493` | |
| `enable_tv_sorting` | `bool` | `Sabnzbd.cs:265, 493` | |
| `movie_categories` | `string[]` | `Sabnzbd.cs:269, 502` | |
| `enable_movie_sorting` | `bool` | `Sabnzbd.cs:269, 502` | |
| `date_categories` | `string[]` **über `SabnzbdStringArrayConverter`** | `Sabnzbd.cs:273, 511` | |
| `enable_date_sorting` | `bool` | `Sabnzbd.cs:273, 511` | |
| `pre_check` | `bool` | `Sabnzbd.cs:443` | |
| `history_retention` | `string` | `Sabnzbd.cs:540, 561-573` | Veraltet, SAB < 4.3. |
| `history_retention_option` | `string` | `Sabnzbd.cs:541, 544` | SAB >= 4.3. |
| `history_retention_number` | `int` | `Sabnzbd.cs:542, 553` | SAB >= 4.3. |

`SabnzbdStringArrayConverter` (`JsonConverters/SabnzbdStringArrayConverter.cs:25-39`) — wird nur
auf `date_categories` angewendet (`SabnzbdCategory.cs:30`):

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

Ein JSON-**String** wird zu einem Array mit einem Element; ein **null** wird zu `[null]` (ein Array mit einem Element, das null ist); ein **Array** wird normal deserialisiert; alles andere (eine Zahl, ein Objekt) wirft eine Exception. Doc-Kommentar bei `:7-9`: "On some properties sab serializes array of single item as plain string."

### 3.3 `config.categories[]` — `SabnzbdCategory` (`SabnzbdCategory.cs:39-48`)

| JSON-Schlüssel | C# | Gelesen bei |
|---|---|---|
| `priority` | `int Priority` | wird nie gelesen |
| `pp` | `string PP` | wird nie gelesen (camelCase von `PP` ist `pp`) |
| `name` | `string Name` | `Sabnzbd.cs:251, 255, 458` |
| `script` | `string Script` | wird nie gelesen |
| `dir` | `string Dir` | `Sabnzbd.cs:238` (`Dir.TrimEnd('*')`), `Sabnzbd.cs:462` (`Dir.EndsWith("*")`) |

`FullPath` (`OsPath`) wird berechnet, nicht deserialisiert.

Pfadzusammenbau — `Sabnzbd.GetCategories` (`Sabnzbd.cs:216-244`):

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

`OsPath.operator+` (`src/NzbDrone.Common/Disk/OsPath.cs:420-448`) gibt `left` zurück, wenn `right.IsEmpty` ist,
also ergibt `dir: ""` genau `FullPath == complete_dir`. `IsRooted` für einen Pfad vom Typ Unix ist
`_path.StartsWith("/")` (`OsPath.cs:142-145`). Der Pfadtyp wird aus dem String abgeleitet
(`OsPath.cs:43-60`): ein führendes `/` ergibt Unix, ein `\` oder ein Laufwerksbuchstabe ergibt Windows. Ein Pfad vom Typ Unix, der an eine auf Windows laufende Sonarr-Instanz übergeben wird, schlägt bei `CompletedDownloadService.ValidatePath` (`:305-310`) fehl.

### 3.4 Die zwei NRE-Fallen (und was tatsächlich sicher ist) {#34-the-two-nre-landmines-and-what-is-actually-safe}

| Payload-Aufbau | Ergebnis |
|---|---|
| **`"misc"` fehlt oder ist `null`** | `Misc` bleibt null (kein Standardwert im Konstruktor; `NullValueHandling.Ignore` beim Lesen) → **NullReferenceException bei `Sabnzbd.cs:218`**. Das zeigt sich als "Test was aborted due to an error: …" und als geloggter Fehler in den Health-Checks. |
| **eine Kategorie, bei der `"dir"` fehlt oder `null` ist** | `Dir` ist null → **NullReferenceException bei `Sabnzbd.cs:238`** (`category.Dir.TrimEnd('*')`) und nochmal bei `:462` (`category.Dir.EndsWith("*")`). |
| `"categories": null` oder fehlt | Sicher. Die leere Liste aus dem Konstruktor bleibt erhalten. `GetStatus` findet dann keine Kategorie, und `OutputRootFolders` bleibt leer. |
| `"sorters": null` oder fehlt | Sicher. Leere Liste aus dem Konstruktor; `config.Sorters.Any(...)` bei `Sabnzbd.cs:484` funktioniert. |
| `"servers": null` oder fehlt | Sicher und wird nie gelesen (`List<object>`, `SabnzbdCategory.cs:19`). |
| `"tv_categories"/"movie_categories"/"date_categories": null` | Sicher: `ContainsCategory` gibt für null/leer `true` zurück (§3.5). Das ist aber nur relevant, wenn das passende `enable_*_sorting` auf true steht. |

**Regel: Gib `misc` immer als Objekt aus und jede Kategorie mit einem String-`dir` (verwende `""`).**

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

Durch die Fixtures bestätigt: `enable_tv_sorting=true` + `tv_categories=null` **schlägt fehl**
(`SabnzbdFixture.cs:636-645`), und + `tv_categories=[]` schlägt auch fehl (`:647-656`).
`TvCategory=null` + `tv_categories=["Default"]` schlägt fehl (`:680-691`).

### 3.6 `Test()` — die genaue Reihenfolge und Regeln (`Sabnzbd.cs:286-292`) {#36-test--the-exact-order-and-rules-sabnzbdcs286-292}

```csharp
protected override void Test(List<ValidationFailure> failures)
{
    failures.AddIfNotNull(TestConnectionAndVersion());
    failures.AddIfNotNull(TestAuthentication());
    failures.AddIfNotNull(TestGlobalConfig());
    failures.AddIfNotNull(TestCategory());
}
```

Umschlossen von `DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`),
das jede durchkommende Exception abfängt und `"Test was aborted due to an error: " + ex.Message` anhängt.

**`TestConnectionAndVersion()` (`Sabnzbd.cs:368-414`)** — 1 × `mode=version`:

1. Version nicht lesbar → Fehler im Feld `Version` (`DownloadClientSabnzbdValidationUnknownVersion`).
2. `rawVersion == "develop"` (Groß-/Kleinschreibung egal) → **Warnung** im Feld `Version`, `IsValid` bleibt true
   (Fixture `SabnzbdFixture.cs:566-577`).
3. `version.Major >= 1` → bestanden (`:389-392`).
4. sonst `version.Minor >= 7` → bestanden (`:394-397`).
5. sonst Fehler: benötigte Version `"0.7.0"` (`:399-404`).
   Fixture-Tabelle (`SabnzbdFixture.cs:549-564`): `0.6.9`→false, `0.7.0`/`0.8.0`/`1.0.0`/`1.0.0RC1`/`1.1.x`→true.
6. Jede Exception → Fehler im Feld `Host` ("unable to connect"), Detail = `ex.Message` (`:406-413`).

**`TestAuthentication()` (`Sabnzbd.cs:416-438`)** — 1 × `mode=get_config`. Fängt die Exception ab und vergleicht
`ex.Message` mit `ContainsIgnoreCase`:

| Gefundener Teilstring | Fehlerfeld |
|---|---|
| `API Key Incorrect` | `APIKey` — `DownloadClientValidationApiKeyIncorrect` |
| `API Key Required` | `APIKey` — `DownloadClientValidationApiKeyRequired` |
| alles andere | **erneut ausgelöst** → generisches "Test was aborted due to an error: …" |

Weil `CheckForError` den Body als `"Error response received from SABnzbd: {error}"` verpackt
(`SabnzbdProxy.cs:244`), klappt der Vergleich nur, wenn dein `error`-String `API Key Incorrect` bzw.
`API Key Required` **enthält** — also SABs eigene Formulierung.

**`TestGlobalConfig()` (`Sabnzbd.cs:440-453`)** — 1 × `mode=get_config`, plus 1 × `mode=version`
nur dann, wenn `pre_check` true ist:

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

Schwelle: **SAB >= 1.1.0** (`HasVersion(major:1, minor:1, patch:0)`, `Sabnzbd.cs:294-332`).
`pre_check: false` umgeht den ganzen Zweig, inklusive des zusätzlichen `mode=version`-Aufrufs.

**`TestCategory()` (`Sabnzbd.cs:455-521`)** — 1 × `mode=get_config` (ein *dritter*), plus alles, was
`GetCategories` braucht. Die Prüfungen laufen in dieser Reihenfolge, der erste Treffer gewinnt:

1. Passende Kategorie (`Name == Settings.TvCategory` / `MovieCategory`), deren `dir` **auf `*` endet**
   → Warnung bei `TvCategory`/`MovieCategory` "enable job folders", InfoLink `config/categories/` (`:460-469`).
2. Keine passende Kategorie **und** die konfigurierte Kategorie ist nicht leer → Warnung
   `DownloadClientValidationCategoryMissing`, InfoLink `config/categories/` (`:471-481`).
3. `config.Sorters.Any(s => s.is_active && ContainsCategory(s.sort_cats, cat))` → Warnung, InfoLink
   `config/sorting/` (`:483-491`). Code-Kommentar in `:483`: *"New in SABnzbd 4.1, but on older versions
   this will be empty and not apply"* (Neu in SABnzbd 4.1; auf älteren Versionen ist das leer und greift nicht).
4. `misc.enable_tv_sorting && ContainsCategory(misc.tv_categories, cat)` → Warnung (`:493-500`).
5. `misc.enable_movie_sorting && ContainsCategory(misc.movie_categories, cat)` → Warnung (`:502-509`).
6. `misc.enable_date_sorting && ContainsCategory(misc.date_categories, cat)` → Warnung (`:511-518`).

`SabnzbdSorter` (`SabnzbdCategory.cs:50-66`) — gelesen werden: `sort_cats` (`List<string>`, im Konstruktor leer),
`is_active` (`bool`). Im Modell vorhanden, wird aber nie gelesen: `name`, `order`, `min_size`,
`multipart_label`, `sort_string`, `sort_type` (`List<int>`).

**Traffic-Hinweis:** Alle vier `Test*`-Methoden machen ihre eigenen Aufrufe, nichts wird zwischengespeichert. Ein
einzelner Verbindungstest sendet also etwa **2 × `mode=version` und 3 × `mode=get_config`** (ein 4. Version-Aufruf,
wenn `pre_check` true ist).

### 3.7 `config.misc` Verlaufsaufbewahrung → `RemovesCompletedDownloads` (`Sabnzbd.cs:538-574`) {#37-configmisc-history-retention--removescompleteddownloads-sabnzbdcs538-574}

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

`true` löst eine Health-Check-**Warnung** aus
(`HealthCheck/Checks/DownloadClientRemovesCompletedDownloadsCheck.cs:44-53`).
Fixture-Abdeckung `SabnzbdFixture.cs:455-510`: alte Werte `"0"`/`""`/`null`/`"15d"` → false;
`"-1"`/`"15"`/`"3"`/`"3d"` → true.

**Die sauberste Lösung für den Emulator: `history_retention_option: "all"`, `history_retention_number: 0`,
`history_retention: "0"`.**

### 3.8 `SortingMode` und sein Health-Check (`Sabnzbd.cs:263-279`) {#38-sortingmode-and-its-health-check-sabnzbdcs263-279}

`GetStatus` setzt `SortingMode` auf `"TV"`, `"Movie"` oder `"Date"` und verwendet dabei dieselben `enable_*_sorting && ContainsCategory(...)`-Prüfungen. Jeder nicht leere Wert löst eine Warnung in `HealthCheck/Checks/DownloadClientSortingCheck.cs:45-55` aus. Lass alle drei `enable_*_sorting` auf false.

### 3.9 `IsLocalhost` (`Sabnzbd.cs:260`)

```csharp
IsLocalhost = Settings.Host == "127.0.0.1" || Settings.Host == "localhost"
```

Ordinal, groß-/kleinschreibungssensitiv; `::1`, `Localhost` und jeder Hostname zählen **nicht**. Dadurch ändert sich, welche `RemotePathMappingCheck`-Meldung du bekommst (siehe §6.2).

---

## 4. Fehlerbehandlung — `CheckForError` (`SabnzbdProxy.cs:222-246`) {#4-error-handling--checkforerror-sabnzbdproxycs222-246}

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

`SabnzbdJsonError` (`SabnzbdJsonError.cs`, vollständig):

```csharp
public string Status { get; set; }
public string Error  { get; set; }

public bool Failed => !string.IsNullOrWhiteSpace(Status) &&
                      Status.Equals("false", StringComparison.InvariantCultureIgnoreCase);
```

Die Regeln, genau:

- `CheckForError` läuft bei **jeder** Antwort, noch vor jeder modusspezifischen Deserialisierung
  (`SabnzbdProxy.cs:217`).
- `Status` ist als `string` typisiert, SAB sendet aber einen JSON-**Boolean**. Newtonsoft macht aus `false` → `"False"`,
  und `Failed` vergleicht ohne Groß-/Kleinschreibung. Sowohl `false` (Boolean) als auch `"false"` (String) funktionieren.
- Eine Antwort **ohne** oberstes `status`-Feld (z. B. `{"version": …}`, `{"queue": {...}}`,
  `{"history": {...}}`, `{"config": {...}}`) lässt `Status` null → `Failed` ist false → kein Fehler.
- `status: true` → `"True"` → nicht fehlgeschlagen.
- **Kein JSON im Body**: `TryDeserialize` gibt false zurück (es fängt `JsonReaderException` und
  `JsonSerializationException` ab, `Json.cs:107-116`), und der Textzweig läuft. Beginnt der Body mit
  `error` (ohne Berücksichtigung der Groß-/Kleinschreibung), wird `Status = "false"` gesetzt und es wird
  `DownloadClientException("Error response received from SABnzbd: {body with 'error: ' stripped}")` geworfen.
  Jeder andere Nicht-JSON-Body setzt `Status = "true"` → wird **als Erfolg behandelt**, und die
  modusspezifische Deserialisierung schlägt dann auf eigene Faust fehl.
- Ein **JSON-Body, dessen `status` ein Objekt ist** (`mode=fullstatus`), landet ebenfalls im Textzweig,
  weil ein `StartObject`-Token keine `string`-Property füllen kann. `Status` wird dann `"true"`.
- Beachte die überflüssige Zuweisung `result.Error = …` bei `:239`: `Error` wird auch im Erfolgszweig gesetzt. Sie hat
  keine Wirkung (nichts liest `Error`, außer wenn `Failed` true ist).

Exception-Zuordnung in `ProcessRequest` (`SabnzbdProxy.cs:187-220`):

| Gefangen | Geworfen |
|---|---|
| `HttpException` (jeder Non-2xx-Status, inkl. 401/403/404/500) | `DownloadClientException("Unable to connect to SABnzbd, {0}")` |
| `HttpRequestException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |
| `WebException` mit `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, certificate validation failed.")` |
| andere `WebException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |

**Die genau abgeglichenen Auth-Fehlertexte** (`Sabnzbd.cs:424, 429`, exakte Literale, abgeglichen mit
`ContainsIgnoreCase` gegen die Exception-Meldung):

- `"API Key Incorrect"`
- `"API Key Required"`

Alles andere wird nicht klassifiziert. Gib sie unverändert als `error`-Wert einer **HTTP 200**-Antwort aus.

**Warum niemals ein Non-200 zurückgegeben werden darf:** `HttpClient.Execute` wirft, bevor `CheckForError` überhaupt läuft
(`HttpClient.cs:106-121`). Die daraus resultierende `HttpException`-Meldung enthält nur Status/Methode/URL und
nicht den Body (`HttpException.cs:18`). Deshalb kann das Abgleichen auf `"API Key Incorrect"` / `"API Key Required"`
nie greifen. Der Nutzer sieht dann „Unable to connect to SABnzbd" oder „Test was aborted due to an error“
statt einer verwertbaren Meldung, und jede Health-Prüfung behandelt den Client als nicht erreichbar.

---

## 5. Die Abfolge nach dem Import {#5-the-post-import-sequence}

### 5.1 Wer ruft `RemoveItem` auf, und mit welchen Werten {#51-who-calls-removeitem-and-with-what}

`DownloadEventHub` (`src/NzbDrone.Core/Download/DownloadEventHub.cs`, identisch in beiden Repos außer
dem BOM):

- `Handle(DownloadCompletedEvent)` (`:48-69`): ruft `MarkItemAsImported` auf (SAB wirft
  `NotSupportedException` — `DownloadClientBase.cs:189-192` — wird auf debug geloggt und ignoriert), kehrt dann früh zurück, wenn das Item schon `Removed`, `!CanBeRemoved` oder noch `Downloading` ist, und kehrt danach früh zurück, außer `definition.RemoveCompletedDownloads` ist gesetzt.
- `Handle(DownloadFailedEvent)` (`:26-46`): hängt von `definition.RemoveFailedDownloads` ab.
- `Handle(DownloadCanBeRemovedEvent)` (`:71-85`): hängt von `definition.RemoveCompletedDownloads` ab.
- Alle drei laufen in `RemoveFromDownloadClient` (`:87-103`) zusammen:

```csharp
_logger.Debug("[{0}] Removing download from {1} history", …);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);   // :92 -- deleteData is ALWAYS true
trackedDownload.DownloadItem.Removed = true;
```

Die Standardwerte in `DownloadClientDefinition` (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17-18`):

```csharp
public bool RemoveCompletedDownloads { get; set; } = true;
public bool RemoveFailedDownloads    { get; set; } = true;
```

Der manuelle API-Pfad `DELETE /api/v3/queue/{id}?removeFromClient=true` übergibt ebenfalls `true` (Sonarr `src/Sonarr.Api.V3/Queue/QueueController.cs:342`). **Es gibt keine Stelle im Code, die `deleteData: false` übergibt.**

### 5.2 `Sabnzbd.RemoveItem` (`Sabnzbd.cs:197-214`) — die genaue Abfolge {#52-sabnzbdremoveitem-sabnzbdcs197-214--the-exact-sequence}

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

Der Ablauf der HTTP-Aufrufe nach dem Import gegen den Emulator sieht so aus:

1. `GET /api?mode=queue&start=0&limit=0&category=tv&apikey=…&output=json` (um zu entscheiden, ob Queue oder History)
2. **lokales Löschen des Ausgabeordners im Dateisystem** (§5.3) — vor jedem weiteren HTTP-Aufruf
3. `GET /api?mode=history&name=delete&del_files=1&value={nzo_id}&archive=1&apikey=…&output=json`

Bei einem **fehlgeschlagenen** Eintrag gibt es kein lokales Löschen (Status ist `Failed`, nicht `Completed`), und **`archive=0`** wird gesetzt —
die Umkehrung in `SabnzbdProxy.cs:80` (`archive = deletePermanently ? 0 : 1`, wobei `deletePermanently == (status is Failed)`).

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

- **Ja, es löscht den Ausgabeordner rekursiv.** `DeleteFolder(path, recursive: true)` bei `:129`.
- `OutputPath` ist hier der `storage` des Verlaufseintrags nach dem Umschreiben des Remote-Pfads und dem Aufstieg zum Job-Ordner (§1.6.2). Bei einem flachen Magic-Verzeichnis heißt das `rm -rf /mnt/zurg/__magic__/__all__/<Title>`.
- Maßgeblich ist der Schalter **Remove Completed Downloads** des Download-Clients (`DownloadClientDefinition.RemoveCompletedDownloads`, Standard **true**), *nicht* eine Einstellung in SABnzbd und *nicht* `del_files`. Es gibt keinen separaten Schalter „delete data“ in der Oberfläche.
- Fehler werden mit einer Warnung verschluckt. Ein schreibgeschützter Mount erzeugt zwar Lärm im Log, bricht den Import aber nicht ab.
- Fixture-Abdeckung `SabnzbdFixture.cs:693-803`: Ordner wird rekursiv gelöscht, Datei wird gelöscht, nichts, wenn der Pfad nicht existiert, und überhaupt nichts (nicht einmal eine `FolderExists`-Prüfung), wenn `deleteData` false ist.

### 5.4 Übertragungsmodus: wird die Datei verschoben oder kopiert? {#54-transfer-mode-is-the-file-moved-or-copied}

`Sabnzbd` setzt `CanMoveFiles = true` bei **jedem** Eintrag, in der Warteschlange (`Sabnzbd.cs:76`) und im Verlauf (`Sabnzbd.cs:135`). Der automatische Importpfad ist `CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, …)` (Sonarr `CompletedDownloadService.cs:148-151`), und dann:

Sonarr `src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152` (Radarr `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, identische Logik):

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

`CanMoveFiles: true` ⇒ `copyOnly == false` ⇒ **`TransferMode.Move`** (`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`). Ein `copyOnly`-Import würde stattdessen `TransferMode.HardLinkOrCopy` verwenden, wenn "Use Hardlinks instead of Copy" aktiv ist, sonst `TransferMode.Copy` (`:94-108`).

`TransferMode` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`) ist `[Flags]`: `None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy = Copy|HardLink`.

### 5.5 Greift bei einem fehlgeschlagenen Move ein Kopieren als Fallback? — **Nein. Ein fehlgeschlagener Move ist ein fehlgeschlagener Import.** {#55-does-a-failed-move-fall-back-to-a-copy--no-a-failed-move-is-a-failed-import}

`src/NzbDrone.Common/Disk/DiskTransferService.cs` (byte-identisch zwischen den beiden Repos, geprüft).
`TransferFile`, `:256-392`; der `TransferMode.Move`-Zweig bei `:360-389`:

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

- Der **einzige** Kopier-Fallback ist der `isCifs && !isSameMount`-Sonderfall bei `:378-385`, ausgelöst über `targetMount.DriveFormat == "cifs"` (`:342`). Er wird *vorab* anhand des Drive-Formats gewählt, nie als Reaktion auf einen Fehler.
- `TryMoveFileVerified` (`:487-503`) fängt Fehler ab, ruft `RollbackPartialMove` auf (außer die Exception ist `FileAlreadyExistsException`) und **wirft sie erneut**:

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

- `VerifyFile` (`:505-524`) vergleicht die Zielgröße mit der Quellgröße, wartet 3 s (`WaitForIO`, `:467-471`), prüft noch einmal und wirft dann `IOException("File move incomplete, data loss may have occurred. [{target}] was {n} bytes long instead of the expected {m}.")`.
- Diese `IOException` wandert weiter nach oben, durch `EpisodeFileMovingService.TransferFile` (`:151`), bis in das allgemeine `catch (Exception e)` in `ImportApprovedEpisodes.cs:218-222` (Radarr `:197-201`). Dort erzeugt sie `ImportResult(importDecision, "Failed to import episode")` bzw. `"Failed to import movie"`. **Es wird kein Kopiervorgang versucht.**
- Weitere `IOException`s vorab in derselben Methode: Quelle == Ziel (`:270`, `:277`) und "Destination cannot be a child of the source" (`:312-315`).

Hinweis, und der betrifft die .NET-Laufzeit und nicht den Sonarr-Code: `DiskProviderBase.MoveFileInternal` (`src/NzbDrone.Common/Disk/DiskProviderBase.cs:293-301`) ist ein einfaches `File.Move`, und .NET fällt unter Unix auf Kopieren und Löschen zurück, wenn `rename()` `EXDEV` zurückgibt. Ein Verschieben über Dateisystemgrenzen klappt also meist trotzdem, als *Laufzeit*-Fallback und nicht als Sonarr-Fallback. Nicht toleriert wird dagegen ein Ziel, dessen Größe von der Quelle abweicht, oder jede Exception, die `File.Move` selbst meldet (EACCES, EPERM, EROFS auf der Quelle, …).

`TransferFolder` (`:44-137`) wird von anderen Codepfaden verwendet. Beachte `:124-131`: Nach einem Ordner-Move löscht es die Quelle nicht, wenn noch mehr als 100 MB Dateien übrig sind (`IOException("Large files still exist in {sourcePath} after folder move, not deleting source folder")`).

---

## 6. Die zwei Health-Checks {#6-the-two-health-checks}

### 6.1 `DownloadClientRootFolderCheck` — **die einzige Stelle, an der sich Sonarr und Radarr wirklich unterscheiden** {#61-downloadclientrootfoldercheck--the-one-place-sonarr-and-radarr-genuinely-differ}

Sonarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = status.OutputRootFolders.Where(folder => rootFolders.Any(r => r.Path.PathEquals(folder.FullPath)));
```

Radarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = rootFolders.Where(r => status.OutputRootFolders.Any(folder => r.Path.PathEquals(folder.FullPath) || r.Path.IsParentPath(folder.FullPath)));
```

`IsParentPath` (`src/NzbDrone.Common/Extensions/PathExtensions.cs:123-140`) läuft vom Kind aus **nach oben**:

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

Also ist `r.Path.IsParentPath(folder.FullPath)` wahr, wenn **der Stammordner ein Vorfahre des Download-Ausgabeordners ist**, also wenn der Ausgabeordner *innerhalb* eines Stammordners liegt. Es ist ein strenger Vorfahren-Test (er beginnt bei `child.Directory`). Gleichheit wird separat über `PathEquals` geprüft.

**Die Frage nach dem Prädikat direkt beantwortet:**

| Beziehung (Ausgabeordner O zu Stammordner R) | Sonarr | Radarr |
|---|---|---|
| O == R | **warnt** | **warnt** |
| O innerhalb von R (R ist Vorfahre von O) | keine Warnung | **warnt** |
| O ist der Überordner von R (O ist Vorfahre von R) | keine Warnung | **keine Warnung** |
| nicht verwandt | keine Warnung | keine Warnung |

Mit `complete_dir = /mnt/zurg/__magic__/__all__` und `dir: ""` (also `OutputRootFolders == ["/mnt/zurg/__magic__/__all__"]`):

- Sonarr warnt nur, wenn ein Stammordner genau `/mnt/zurg/__magic__/__all__` ist.
- Radarr warnt, wenn ein Stammordner `/mnt/zurg/__magic__/__all__`, `/mnt/zurg/__magic__`, `/mnt/zurg` oder `/mnt` ist.
- Keine der beiden warnt, wenn ein Stammordner `/mnt/zurg/__magic__/tv` ist. Der Spiegel und die Stammordner sind Geschwister, das Paar ist also nicht verwandt, und keine Regel greift. Ein Stammordner *innerhalb* des Ausgabeordners (`/mnt/zurg/__magic__/__all__/anything`) würde hier ebenfalls still bleiben. Der Namespace lässt aber auf dieser Tiefe nichts speichern, also kann diese Anordnung gar nicht entstehen.

`PathEquals` (`PathExtensions.cs:55-73`) normalisiert Unicode, verwendet `DiskProviderBase.PathStringComparison` (`OrdinalIgnoreCase` unter Windows, `Ordinal` sonst – `src/NzbDrone.Common/Disk/DiskProviderBase.cs:17-23`) und prüft erneut mit `CleanFilePath()` (unempfindlich gegenüber einem abschließenden Schrägstrich).

Beide Versionen werden bei `ProviderUpdatedEvent` / `ProviderDeletedEvent` / `ModelEvent<RootFolder>` / `ModelEvent<RemotePathMapping>` erneut ausgeführt. Radarr fügt bei `:17` zusätzlich `[CheckOn(typeof(ProviderAddedEvent<IDownloadClient>))]` hinzu. Das Ergebnis ist `HealthCheckResult.Warning` mit dem Anker `#downloads-in-root-folder`. Die Meldung setzt in Sonarr `folder.FullPath` und in Radarr `folder.Path` ein (jeweils `:60`). Beide schlucken `DownloadClientException` und `HttpRequestException` stillschweigend (Debug-Log) und protokollieren jede andere Exception als Fehler.

### 6.2 `RemotePathMappingCheck` — der lokale Client-Pfad (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs`) {#62-remotepathmappingcheck--the-local-client-path-srcnzbdronecorehealthcheckchecksremotepathmappingcheckcs}

Kurzschluss bei `:51-54`: Wenn `EnableCompletedDownloadHandling` ausgeschaltet ist, macht die Prüfung nichts.

Für jeden `folder` in `client.GetStatus().OutputRootFolders`:

1. **`!folder.IsValid`** (`:68`): `OsPath.IsValid` = `_path.IsPathValid(PathValidationType.CurrentOs)` (`OsPath.cs:228`). Auf Nicht-Windows-Systemen läuft das auf `path.StartsWith("/")` plus eine Prüfung mit `Path.GetInvalidPathChars()` hinaus (`PathExtensions.cs:143-182`, `:403-411`). Fehler, in dieser Reihenfolge:
   - `!status.IsLocalhost` → `RemotePathMappingWrongOSPathHealthCheckMessage` (Radarr-Schlüssel: `RemotePathMappingCheckWrongOSPath`), Anker `#bad-remote-path-mapping`
   - `_osInfo.IsDocker` → …`BadDockerPath`, Anker `#docker-bad-remote-path-mapping`
   - sonst → …`LocalWrongOSPath`, Anker `#bad-download-client-settings`
2. **`!_diskProvider.FolderExists(folder.FullPath)`** (`:115`):
   - `_osInfo.IsDocker` → …`DockerFolderMissing`, `#docker-bad-remote-path-mapping`
   - `!status.IsLocalhost` → …`LocalFolderMissing`, `#bad-remote-path-mapping`
   - sonst → …`GenericPermissions`, `#permissions-error`

**Für einen lokalen Client (`IsLocalhost` true, nicht Docker) bleiben damit genau zwei Anforderungen übrig:** Der gemeldete Output-Root-Ordner muss ein absoluter Pfad *für das Betriebssystem sein, auf dem Sonarr/Radarr läuft*, und er muss **auf dem Sonarr/Radarr-Host als Verzeichnis existieren**. `/mnt/zurg/__magic__/__all__` muss für den *arr-Prozess sichtbar sein, nicht nur für den Emulator. **Eine Schreibbarkeitsprüfung gibt es hier nicht.**

Der ereignisgesteuerte Overload (`:178-368`) wird bei `EpisodeImportFailedEvent` ausgelöst (Radarr: `MovieImportFailedEvent`). Er ruft außerdem, das ist wichtig, `client.GetItems()` erneut auf, um den `OutputPath` des fehlgeschlagenen Downloads nachzuschlagen (`:232`).

Kein Health Check verlangt, dass der Output-Ordner *beschreibbar* ist. `FolderWritable` (`DiskProviderBase.cs:126-143` bei Sonarr / `:127-144` bei Radarr), das `sonarr_write_test.txt` bzw. `radarr_write_test.txt` schreibt und wieder löscht, wird von `RootFolderService.Add` (Sonarr `src/NzbDrone.Core/RootFolders/RootFolderService.cs:117-120`) und von `DownloadClientBase.TestFolder` (`:167-187`) verwendet. **`TestFolder` wird vom SAB-Client aber nie aufgerufen.**

## 7. Sonarr vs. Radarr — der vollständige Unterschied {#7-sonarr-vs-radarr--the-complete-diff}

Jede abgerufene Datei wurde mit diff verglichen. Ergebnisse:

**Byte-identisch, bis auf eine UTF-8-BOM bei den Sonarr-Kopien (Zeilennummern stimmen daher exakt überein):**

`SabnzbdCategory.cs` (auf beiden Seiten kein BOM, wirklich identisch), `SabnzbdDownloadStatus.cs`,
`SabnzbdPriority.cs`, `SabnzbdFullStatus.cs`, `SabnzbdJsonError.cs`, `SabnzbdQueue.cs`,
`SabnzbdQueueItem.cs`, `SabnzbdHistory.cs`, `SabnzbdHistoryItem.cs`,
`JsonConverters/*.cs` (alle drei), `Responses/*.cs` (alle sechs),
`src/NzbDrone.Common/Disk/DiskTransferService.cs`, `src/NzbDrone.Core/Download/DownloadEventHub.cs`.

**Unterscheiden sich nur durch die Umbenennung `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` (keine Änderung der Zeilenanzahl, gleiche Zeilennummern):**

- `Sabnzbd.cs` — `:40-52` (`AddFromNzbFile`; Radarrs Aktualitätstest ist
  `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` statt Sonarrs `remoteEpisode.IsRecentEpisode()`), `:190`, `:251`, `:265/269/273`, `:458`, sowie alle `NzbDroneValidationFailure`-Feldnamen in
  `TestCategory` (`"TvCategory"` → `"MovieCategory"`).
- `SabnzbdProxy.cs` — `:50`, `:122-124`, `:138-140`.
- `SabnzbdSettings.cs` — Standardwerte `TvCategory = "tv"` vs. `MovieCategory = "movies"`;
  `RecentTvPriority`/`OlderTvPriority` vs. `RecentMoviePriority`/`OlderMoviePriority`
  (beide Standard `(int)SabnzbdPriority.Default`). Der Validator ist sonst identisch: `Host` gültig,
  `Port` 1–65535, `ApiKey` erforderlich, wenn Username leer ist, `Username`/`Password` erforderlich, wenn ApiKey
  leer ist, Kategorie `NotEmpty` **als Warnung**.
- `UsenetClientBase.cs` — Radarr setzt zusätzlich `request.AllowAutoRedirect = true` (`:51`) und
  behandelt HTTP `410 Gone` wie `404` (`:63`), wenn die NZB vom Indexer geholt wird. **Das betrifft den Indexer, nicht SAB.**
- `DownloadClientBase.cs` — nur das wörtliche "Sonarr"/"Radarr" im Detailtext von `TestFolder`.
- `RemotePathMappingCheck.cs` — Namen der Lokalisierungsschlüssel (`RemotePathMapping*HealthCheckMessage` vs. `RemotePathMappingCheck*`), `EpisodeImportFailedEvent` vs. `MovieImportFailedEvent`, plus Radarrs zusätzliches `[CheckOn(ProviderAddedEvent<IDownloadClient>)]`.
  **Die Prädikate sind identisch.**
- `DiskProviderBase.cs` — Probedatei von `FolderWritable`: `sonarr_write_test.txt` vs. `radarr_write_test.txt`
  (Sonarr `:132`, Radarr `:133`).

**Echter Verhaltensunterschied — genau einer:**

- **`DownloadClientRootFolderCheck.cs:51`.** Sonarr warnt nur bei `PathEquals`; Radarr warnt zusätzlich, wenn ein Root-Ordner ein übergeordneter Ordner des Ausgabeordners ist. Vollständige Tabelle in §6.1.

Alles andere — Modi, Parameter, JSON-Formate, Enums, Converter, `CheckForError`, `RemoveItem`,
`DeleteItemData`, Transfermodus, `DiskTransferService` — ist identisch. **Ein Emulator bedient beide.**

Konfigurationsstandards in beiden identisch: `DownloadClientHistoryLimit = 60`,
`RemoveCompletedDownloads = true`, `RemoveFailedDownloads = true`.

## 8. Minimale, aber vollständige Beispiel-Payloads {#8-minimal-but-complete-example-payloads}

Gegeben: `complete_dir = /mnt/zurg/__magic__/__all__`; Kategorien `*`, `tv`, `movies`, alle mit `dir: ""`.
Jede Antwort ist **HTTP 200** mit `Content-Type: application/json`.

Daraus ergeben sich die `OutputRootFolders`: `dir: ""` ⇒ `FullPath == complete_dir` ⇒ `/mnt/zurg/__magic__/__all__`
für Sonarr (Kategorie `tv`) und für Radarr (Kategorie `movies`).

### 8.1 `mode=version`

```json
{
  "version": "4.3.3"
}
```

Muss `major.minor.(patch|x)` sein. `4` ≥ 1 erfüllt `TestConnectionAndVersion` (`Sabnzbd.cs:389-392`);
≥ 2.0 würde außerdem bedeuten, dass `GetCategories` `fullstatus` statt `queue.my_home` nutzt, falls `complete_dir` relativ wäre (ist es aber nicht).

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

Warum jeder Wert:

- `misc` als Objekt vorhanden: **erforderlich**, sonst NRE (§3.4).
- jede Kategorie hat ein **string** `dir`: **erforderlich**, sonst NRE bei `Sabnzbd.cs:238` und `:462`.
- `dir` endet **nicht** mit `*`, sonst kommt die Warnung "enable job folders" (`Sabnzbd.cs:462-469`).
- alle drei `enable_*_sorting: false`: das beseitigt sowohl die `TestCategory`-Warnungen (`Sabnzbd.cs:493-518`) als auch `DownloadClientSortingCheck`. Beachte: `tv_categories: []` zusammen mit `enable_tv_sorting: true` würde **fehlschlagen**, weil `ContainsCategory` bei einer leeren Liste true zurückgibt (`Sabnzbd.cs:525-528`, Fixture `SabnzbdFixture.cs:647-656`).
- `sorters: []`: `config.Sorters.Any(s => s.is_active && …)` ist false (`Sabnzbd.cs:484`).
- `pre_check: false`: überspringt den `HasVersion(1,1)`-Round-Trip in `TestGlobalConfig` (`Sabnzbd.cs:443`).
- `history_retention_option: "all"` → `RemovesCompletedDownloads == false` (`Sabnzbd.cs:546-547`) → keine Health-Check-Warnung.
- `complete_dir` absolut → `IsRooted` ist true → `mode=fullstatus` / `queue.my_home` wird nie abgefragt (`Sabnzbd.cs:220`).

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

Nur `completedir` wird gelesen (`SabnzbdFullStatus.cs:9-10`). Der Wrapper-Schlüssel **muss** `status` sein
(`Responses/SabnzbdFullStatusResponse.cs:5`).

### 8.4 `mode=addfile`-Antwort {#84-modeaddfile-response}

```json
{
  "status": true,
  "nzo_ids": ["SABnzbd_nzo_abc12345"]
}
```

`nzo_ids` muss ein **nicht leeres Array aus Strings** sein (`Sabnzbd.cs:47-52`). `status` wird geparst (`Responses/SabnzbdAddResponse.cs:13`), aber nie gelesen; lass es auf `true`, damit `CheckForError` `"True"` sieht.

### 8.5 `mode=queue&start=0&limit=0&category=tv` — ein Downloading-Slot {#85-modequeuestart0limit0categorytv--one-downloading-slot}

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

Harte Anforderungen:

- Oberster Schlüssel `queue` (`SabnzbdProxy.cs:129`, `SelectToken("queue")`).
- `slots[].status` ∈ die 16 `SabnzbdDownloadStatus`-Namen, exakt in dieser Schreibweise.
- `slots[].mb` / `mbleft` sind **Megabyte**, Dezimalzahlen im invariant culture. Strings und Zahlen funktionieren beide (Newtonsoft wandelt um); echtes SAB schickt Strings.
- `slots[].timeleft` ist genau `h:m:s` oder `d:h:m:s` — niemals `""`.
- `slots[].priority` — `"Normal"`, `"High"`, `"Low"`, `"Force"`, `"Paused"`, `"Default"` (groß- und kleinschreibungsabhängig) oder das numerische Äquivalent. **Niemals `null`** (NRE).
- `slots[].cat` (nicht `category`) muss der konfigurierten Kategorie des Clients entsprechen, sonst wird der Eintrag bei `Sabnzbd.cs:190` herausgefiltert.
- `queue.paused` muss `false` sein, außer du meinst wirklich pausiert. `true` markiert jeden Slot außer `Force` als Paused und setzt die ETA auf null (`Sabnzbd.cs:78-84`).

Resultierendes `DownloadClientItem`: `TotalSize = 1024 * 1024 * 1024`, `RemainingSize = 512 * 1024 * 1024`, `RemainingTime = 00:08:32`, `Status = Downloading`, `CanBeRemoved = CanMoveFiles = true`.

### 8.6 `mode=history&start=0&limit=60&category=tv` — ein Completed- und ein Failed-Slot {#86-modehistorystart0limit60categorytv--one-completed-and-one-failed-slot}

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

Harte Anforderungen:

- Oberster Schlüssel `history` (`SabnzbdProxy.cs:145`).
- `slots[].bytes` ist **BYTES** (eine JSON-Zahl → `long`). Hier kein MB senden. Die Queue nutzt MB, die
  History nutzt Bytes (`Sabnzbd.cs:72-73` vs `:128`).
- `slots[].category` (nicht `cat`).
- `slots[].storage` ist der Job-Ordner selbst. Er wird zu `OutputPath`, und bei einem Completed-Element ist er
  genau das, was `DeleteItemData` rekursiv löscht (§5.3). Er muss ein absoluter Pfad sein, der auf dem Betriebssystem gültig ist, auf dem Sonarr/Radarr läuft, und dort existieren (`RemotePathMappingCheck`, §6.2).
- `slots[].status` in exakter Schreibweise. `Deleted`-Elemente werden komplett verworfen (`Sabnzbd.cs:116-119`).
- `fail_message` exakt `"Unpacking failed, write error or disk is full?"` stuft ein Failed-Element auf `Warning` statt `Failed` herab (`Sabnzbd.cs:140-144`). Für einen echten Fehler nimm etwas anderes.
- Radarr: `category` muss `movies` sein (oder was auch immer konfiguriert ist), und `name` sollte sich als Film parsen lassen.

### 8.7 Fehlerantwort (jeder Modus) {#87-error-response-any-mode}

```json
{
  "status": false,
  "error": "API Key Incorrect"
}
```

**HTTP 200.** `status` kann der boolesche Wert `false` oder der String `"false"` sein; beide erfüllen
`SabnzbdJsonError.Failed` (`SabnzbdJsonError.cs:10-11`). Der Client löst
`DownloadClientException("Error response received from SABnzbd: API Key Incorrect")` aus
(`SabnzbdProxy.cs:244`), den `TestAuthentication` erkennt (`Sabnzbd.cs:424`).
Verwende `"API Key Required"`, wenn kein Schlüssel angegeben wurde (`Sabnzbd.cs:429`). Jeder andere `error`-String wird
wörtlich gemeldet, aber nicht eingeordnet.

---

## 9. Umsetzungs-Checkliste (12 Punkte) {#9-implementation-checklist-12-points}

1. Eine Route: `GET|POST {UrlBase}/api`, Verteilung anhand von `mode`. **Immer HTTP 200, immer JSON.**
2. Implementiere `version`, `get_config`, `queue` (lesen + `name=delete`), `history` (lesen + `name=delete`), `addfile`, `fullstatus`. Optional `retry` (heute toter Code). `get_cats` wird nie aufgerufen.
3. Akzeptiere Authentifizierung entweder als `apikey=` **oder** `ma_username=`+`ma_password=`. Lehne mit 200 + `{"status":false,"error":"API Key Incorrect"}` / `"API Key Required"` ab, niemals mit 401/403.
4. Berücksichtige `category=` bei `queue`/`history` (die Clients filtern außerdem clientseitig per exaktem Stringvergleich, `Sabnzbd.cs:190`).
5. `queue`-Größen in **MB** (`mb`, `mbleft`); `history`-Größen in **BYTES** (`bytes`). Verwechsle sie nie. Queue nutzt `cat`, history nutzt `category`.
6. `timeleft` ist immer `h:m:s` oder `d:h:m:s`, nie leer und nie als leerer String fehlend.
   Kein Datumsfeld wird irgendwo geparst, daher sind Epoch-Felder frei gestaltbar.
7. `status`-Werte müssen aus der 16-teiligen Liste `SabnzbdDownloadStatus` stammen, exakt in der Schreibweise (ein unbekannter Name wirft eine Exception und bringt den gesamten queue-/history-Aufruf zum Absturz). `priority` muss ein Name aus `SabnzbdPriority` (exakte Schreibweise) oder dessen Ganzzahl sein; **niemals `null`** (NRE im Converter).
8. `config.misc` muss ein Objekt sein; jede Kategorie muss ein **nicht-null String-`dir`** haben, der nicht mit `*` endet. `categories`/`sorters`/`servers` dürfen null sein oder fehlen, `misc` und `dir` dagegen nicht.
9. Lass `enable_tv_sorting`, `enable_movie_sorting`, `enable_date_sorting` und `pre_check` alle auf `false`, und `history_retention_option: "all"`, damit der Verbindungstest und alle Health-Checks sauber durchlaufen.
10. `storage` eines Completed-history-Slots ist der Job-Ordner. Rechne damit, dass der *arr ihn nach einem erfolgreichen Import mit `rm -rf` löscht (Standardeinstellungen), und dass die Mediendatei vorher **verschoben** wird. Ist das Magic-Verzeichnis schreibgeschützt, schlägt das Löschen stillschweigend fehl (nur eine Warnung im Log). Das *Verschieben* der importierten Datei muss trotzdem klappen, sonst schlägt der Import komplett fehl (§5.5).
11. Lege keinen *arr-Root-Ordner auf oder unterhalb von `/mnt/zurg/__magic__/__all__` ab, wenn Radarrs `DownloadClientRootFolderCheck` ruhig bleiben soll (Sonarr prüft nur auf exakte Gleichheit). Lege sie stattdessen neben dem Mirror ab, z. B. `/mnt/zurg/__magic__/tv` und `/mnt/zurg/__magic__/movies`. Sie liegen dann weder darüber noch darunter, sondern sind vom Ausgabeordner unabhängig.
12. `/mnt/zurg/__magic__/__all__` muss als Verzeichnis **auf dem Sonarr/Radarr-Host** existieren, nicht nur dort, wo der Emulator läuft, sonst wirft `RemotePathMappingCheck` einen Fehler. Es muss nicht beschreibbar sein.

## Ein größeres Abschlussfenster konfigurieren {#configuring-a-larger-completion-window}

Beide Clients setzen `DownloadClientHistoryLimit` standardmäßig auf 60. zurg spiegelt dieses Fenster, wenn es abgeschlossene Überläufer in `queue` behält. Würdest du nur das Client-Limit erhöhen, würden manche Jobs sowohl in queue als auch in history gemeldet, und dann gewinnt queue.

Bei einem großen Rückstau setzt du `sabnzbd.history_limit` in zurg und `DownloadClientHistoryLimit` in den Clients auf denselben Wert, zum Beispiel 500. So werden pro Poll mehr abgeschlossene und fehlgeschlagene Jobs angezeigt. Wenn mehrere Clients unterschiedliche Werte nutzen, lass zurg auf dem kleinsten Client-Limit. Diese erweiterte Client-Einstellung ist in der Download-Client-Konfigurations-API von Sonarr v4 nicht verfügbar. Bevor du die gespeicherte Konfiguration des Clients bearbeitest, sichere sie und stoppe den Client.

```yaml
sabnzbd:
  enabled: true
  history_limit: 500
```

Der Standardwert bleibt 60; Null und negative Werte verwenden diesen Standardwert. Eine Diagnose-Abfrage der History mit einem anderen Limit ändert das eingestellte Fenster nie. Warnungen, die der Client nicht auflösen kann, musst du weiterhin prüfen. Ein größeres Fenster lässt andere Jobs zum Import durch, auch wenn diese Warnungen Plätze in der History belegen.

Die Verfügbarkeitsprüfung vor dem Abschluss prüft die ersten sechzehn Artikel und den letzten Artikel jeder Mediendatei. So wird ein fehlender Artikel im Medien-Header erkannt, den der frühere Canary mit dem ersten Artikel übersehen hat. Dabei wird der erste Artikel jeder Mediendatei übertragen. Das prüft die Artikel-Identität und ob der Body noch ausgeliefert wird; ein Provider kann auf STAT mit Ja antworten, obwohl er den Body entfernt hat. Hinzu kommen zufällig gezogene Artikel, bis zu sechzehn Bodys für ein Release mit weniger Dateien, und höchstens vierundsechzig Bodys insgesamt. Ein Body, den der Artikel-Cache schon hat, wird nicht erneut geholt. STAT deckt den Rest der Stichprobe ab. Es werden nicht alle Artikel geprüft, und es ist nicht bewiesen, dass sich die Mediendatei abspielen lässt. STAT-Anfragen werden pro Datei gebündelt, sodass die Stichprobe eine Pool-Reservierung statt siebzehn braucht, ohne das Verbindungslimit des Accounts zu erhöhen. Ist ein Bündel unbrauchbar, fallen die Anfragen auf einzelne STATs zurück. Server-Fehler lassen den Job zum erneuten Versuch in der Warteschlange. Bestätigt fehlende Artikel führen zu einem fehlgeschlagenen Download, bevor die erste Abschlussbenachrichtigung kommt.
