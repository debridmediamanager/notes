# API de SABnzbd tal como la consumen Sonarr y Radarr (develop) {#sabnzbd-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Fuente de verdad: archivos obtenidos de `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...`
el **2026-08-22**. Cada número de línea de abajo se leyó de esos archivos.

Se deja aquí como registro de por qué `internal/sabnzbd` responde con las formas que tiene. No se debe cambiar nada de ese paquete sin antes leer el párrafo de aquí que explica qué hace el cliente con el campo: una etiqueta de struct mal puesta no falla, sino que deja al cliente leyendo un cero, y un valor de enum incorrecto lanza una excepción dentro de su deserializador y tumba todo el sondeo. Para saber cómo apuntar Sonarr o Radarr a zurg, consulta [sabnzbd.md](../guides/sonarr-radarr.md).

Salvo que una sección diga lo contrario, **los archivos SAB de los dos repos son idénticos byte a byte, salvo por un BOM UTF-8 y el renombrado `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie`, y los números de línea coinciden uno a uno.** Por tanto, cada cita `Sabnzbd*` aplica a ambos repos en la misma línea. Las rutas son `src/NzbDrone.Core/Download/Clients/Sabnzbd/...` en ambos. Las diferencias verificadas están registradas en §6.

Nada de esto es especulación sobre SAB en sí: cada afirmación describe lo que hace el *cliente*. Cuando digo Newtonsoft.Json o el comportamiento del runtime de .NET (y no código de Sonarr), lo indico explícitamente.

---

(Una traducción anterior fue rechazada: los fragmentos de código no coincidían. Mantén la estructura exactamente.)

## 0. Reglas a nivel de transporte (estas muerden primero) {#0-transport-level-rules-these-bite-first}

### 0.1 Forma de la URL {#01-url-shape}

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

- URL base: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-66`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; a `UrlBase` le pone una `/` al principio si le falta.
  El endpoint es esa dirección + `/api` (`SabnzbdProxy.cs:38-44`).
- Los parámetros de sufijo siempre van al final, así que **`apikey` (o `ma_username`+`ma_password`) y `output=json` son los últimos parámetros de la query** (`HttpRequestBuilder.cs:82` — `QueryParams.Concat(SuffixQueryParams)`).
- `Accept: application/json` en cada llamada. `output=json` en cada llamada. No existe ninguna ruta con `output=xml` en ningún sitio.
- La API key y el usuario/contraseña son **mutuamente excluyentes**: si hay una API key, se omiten `ma_username`/`ma_password`.

### 0.2 Siempre responde HTTP 200, incluso con errores {#02-always-answer-http-200--even-for-errors}

`HttpClient.Execute` lanza una excepción en cualquier estado >= 400 (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`;
`HttpResponse.cs:54` — `HasHttpError => (int)StatusCode >= 400`; 429 se convierte en `TooManyRequestsException`).
`SabnzbdProxy.ProcessRequest` (`SabnzbdProxy.cs:199-215`) convierte eso en
`DownloadClientException("Unable to connect to SABnzbd, {0}")`.

El mensaje de `HttpException` es `"HTTP request failed: [401:Unauthorized] [GET] at [url]"` (`src/NzbDrone.Common/Http/HttpException.cs:18`) — **el cuerpo no aparece en el mensaje**. Así que un 401 con `{"error":"API Key Incorrect"}` no será reconocido por `TestAuthentication` (`Sabnzbd.cs:424,429` comparan con `ex.Message`), y la prueba de conexión mostrará en su lugar el mensaje genérico "Test was aborted due to an error". **Imita a SAB: HTTP 200 + `{"status": false, "error": "..."}`.**

### 0.3 Configuración del deserializador (determina todas las preguntas sobre nombres de campos y tipos) {#03-deserializer-settings-drives-every-field-name-and-type-question}

Todas las cargas de SAB pasan por `NzbDrone.Common.Serializer.Json`
(`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`) — **Newtonsoft**, no System.Text.Json:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Consecuencias (semántica de Newtonsoft, no código de Sonarr):

| Ajuste | Efecto en un emulador |
|---|---|
| `CamelCasePropertyNamesContractResolver` | La propiedad C# `Storage` enlaza con `storage`, `PP` con `pp`, `Misc` con `misc`. Newtonsoft también recurre a una coincidencia de propiedad sin distinguir mayúsculas, así que las claves reales de SAB en snake_case/minúsculas enlazan de cualquier forma. |
| `StringEnumConverter` (global) | Se aplica a `SabnzbdDownloadStatus`, que **no** tiene un convertidor por propiedad. Los nombres de enum desconocidos lanzan `JsonSerializationException`. Los enteros también se aceptan (`AllowIntegerValues` es true por defecto). |
| `NullValueHandling.Ignore` | También al **leer**: un `null` en JSON deja el miembro C# con el valor del constructor. Así que `"categories": null` mantiene la lista vacía del constructor, pero `"misc": null` deja `Misc` en null (sin valor por defecto en el constructor) → NRE, ver §3.4. |
| `MissingMemberHandling` (por defecto `Ignore`) | Los campos extra en tu payload no hacen daño. Envía el cuerpo completo y real de SAB. |
| `Culture` (por defecto `InvariantCulture`) | Las cadenas numéricas como `"1024.00"` deben usar `.` como separador decimal y sin separadores de miles. |

`Json.Deserialize<T>` solo vuelve a lanzar `JsonReaderException` con un mensaje más claro (`Json.cs:39-50`);
`Json.TryDeserialize<T>` traga **solo** `JsonReaderException` y `JsonSerializationException`
(`Json.cs:99-117`). Cualquier otra cosa (por ejemplo, un `ArgumentException` del convertidor de timeleft, o un NRE
del convertidor de prioridad) sale sin capturar.

---

## 1. Cada modo, cada parámetro, cada campo consumido {#1-every-mode-every-parameter-every-field-consumed}

### 1.1 `mode=version`: `SabnzbdProxy.GetVersion` (`SabnzbdProxy.cs:85-95`) {#11-modeversion--sabnzbdproxygetversion-sabnzbdproxycs85-95}

Petición: `GET /api?mode=version&apikey=KEY&output=json`

Modelo de respuesta `SabnzbdVersionResponse` (`Responses/SabnzbdVersionResponse.cs:5`):

| Clave JSON | Tipo C# | Notas |
|---|---|---|
| `version` | `string` | El único campo que se lee. |

Se lee con `Json.TryDeserialize`; si el análisis falla, queda `Version == null` (`SabnzbdProxy.cs:89-92`).

Análisis (`Sabnzbd.cs:334-366`), regex en `Sabnzbd.cs:38`:

```csharp
// patch can be a number (releases) or 'x' (git)
private static readonly Regex VersionRegex = new Regex(@"(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+|x)", RegexOptions.Compiled);
```

- Sin anclar, así que `4.5.0RC1` y `2.0.0beta1` sí se analizan (fixture `SabnzbdFixture.cs:523,553`).
- `patch` puede ser la letra literal `x` (compilaciones de git), que se reemplaza por `0` (`Sabnzbd.cs:351`).
- Una versión de **dos componentes** (`"4.5"`) no coincide → `null` → fallo de validación.
- La cadena exacta `"develop"` (sin distinguir mayúsculas) tiene un caso especial y se trata como `3.0.0` (`Sabnzbd.cs:355-362`). Esto produce una *advertencia*, no un fallo (`Sabnzbd.cs:380-387`).

La versión se vuelve a pedir (una segunda petición `mode=version`) mediante `HasVersion` en
`Sabnzbd.cs:294-332`. **No** se guarda en caché.

### 1.2 `mode=get_config`: `SabnzbdProxy.GetConfig` (`SabnzbdProxy.cs:97-104`) {#12-modeget_config--sabnzbdproxygetconfig-sabnzbdproxycs97-104}

Solicitud: `GET /api?mode=get_config&apikey=KEY&output=json`

Usa `Json.Deserialize` (**no** Try): si el cuerpo está mal formado, se lanza una excepción desde `GetConfig`.
El nivel superior debe ser `{"config": {...}}` (`Responses/SabnzbdConfigResponse.cs:5`). Consulta §3 para ver los campos.

### 1.3 `mode=fullstatus`: `SabnzbdProxy.GetFullStatus` (`SabnzbdProxy.cs:106-114`) {#13-modefullstatus--sabnzbdproxygetfullstatus-sabnzbdproxycs106-114}

**Solicitud:** `GET /api?mode=fullstatus&skip_dashboard=1&apikey=KEY&output=json`

Nivel superior `{"status": {...}}` (`Responses/SabnzbdFullStatusResponse.cs:5`). Solo se lee un campo:

| Clave JSON | C# | Origen |
|---|---|---|
| `completedir` | `string CompleteDir` | `SabnzbdFullStatus.cs:9-10` — ojo: **`completedir`, sin guion bajo** |

Se llama **solo** cuando `config.misc.complete_dir` **no** es una ruta absoluta **y** la versión de SAB es >= 2.0
(`Sabnzbd.cs:220-226`). Con un `complete_dir` absoluto, este endpoint nunca se usa, pero implementalo igualmente.

Detalle a tener en cuenta: como el cuerpo real es `{"status": {...}}` y `SabnzbdJsonError.Status` es una
`string`, `TryDeserialize<SabnzbdJsonError>` de `CheckForError` falla con una `JsonSerializationException` y
cae en la rama de texto plano, que asigna `Status = "true"` (`SabnzbdProxy.cs:224-240`). Es inofensivo, pero
significa que fullstatus nunca puede informar un error por la ruta JSON.

### 1.4 `mode=queue` (lectura): `SabnzbdProxy.GetQueue` (`SabnzbdProxy.cs:116-130`) {#14-modequeue-read--sabnzbdproxygetqueue-sabnzbdproxycs116-130}

**Petición:** `GET /api?mode=queue&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- `category` se añade **solo si** la categoría configurada no está en blanco (`SabnzbdProxy.cs:122-125`).
- Quién lo llama:
  - `Sabnzbd.GetQueue()` usa `start=0, limit=0` (`Sabnzbd.cs:57`). SAB interpreta `limit=0` como "todos".
  - `Sabnzbd.GetCategories()` usa `start=0, limit=1` en la ruta para SAB anterior a 2.0 (`Sabnzbd.cs:229`).
  - `Sabnzbd.RemoveItem()` lo llama una vez más para decidir si el elemento está en la cola o en el historial (`Sabnzbd.cs:199`).
- Extracción: `Json.Deserialize<SabnzbdQueue>(JObject.Parse(response).SelectToken("queue").ToString())` (`SabnzbdProxy.cs:129`). **Si falta la clave `queue` de nivel superior, se produce un NRE.**

`SabnzbdQueue` (`SabnzbdQueue.cs`):

| Clave JSON | C# | Tipo | Se usa para |
|---|---|---|---|
| `my_home` | `DefaultRootFolder` | `string` | Solo en SAB < 2.0, para resolver un `complete_dir` relativo (`Sabnzbd.cs:230`). Comentario en `SabnzbdQueue.cs:8`: "Removed in Sabnzbd 2.0.0, see mode=fullstatus instead." |
| `paused` | `Paused` | `bool` | Pausa global; se combina con la prioridad del slot (`Sabnzbd.cs:78`). |
| `slots` | `Items` | `List<SabnzbdQueueItem>` | |

`SabnzbdQueueItem` (`SabnzbdQueueItem.cs`):

| Clave JSON | Miembro C# | Tipo C# | Tipo JSON real de SAB | Notas |
|---|---|---|---|---|
| `status` | `Status` | `SabnzbdDownloadStatus` | string | `StringEnumConverter` global. Un valor desconocido ⇒ `JsonSerializationException` ⇒ todo `GetQueue` lanza una excepción. |
| `index` | `Index` | `int` | number | Se lee, nunca se usa. |
| `timeleft` | `Timeleft` | `TimeSpan` mediante `SabnzbdQueueTimeConverter` | string | Ver §1.4.1. |
| `mb` | `Size` | `decimal` | **string** (`"1024.00"`) | **Megabytes.** `TotalSize = (long)(Size * 1024 * 1024)` (`Sabnzbd.cs:72`). |
| `mbleft` | `Sizeleft` | `decimal` | **string** | **Megabytes.** `RemainingSize = (long)(Sizeleft * 1024 * 1024)` (`Sabnzbd.cs:73`). |
| `filename` | `Title` | `string` | string | Pasa a ser `DownloadClientItem.Title` (`Sabnzbd.cs:71`). |
| `priority` | `Priority` | `SabnzbdPriority` mediante `SabnzbdPriorityTypeConverter` | string (`"Normal"`) | Ver §2. |
| `cat` | `Category` | `string` | string | **`cat` en la cola, `category` en el historial.** |
| `mbleft`/`percentage` | `Percentage` | `int` | **string** (`"50"`) | Se lee, nunca se usa. |
| `nzo_id` | `Id` | `string` | string | El id de descarga con el que Sonarr/Radarr identifican todo. |

#### 1.4.1 Formato de `timeleft`: `SabnzbdQueueTimeConverter` (`JsonConverters/SabnzbdQueueTimeConverter.cs:15-28`) {#141-timeleft-format--sabnzbdqueuetimeconverter-jsonconverterssabnzbdqueuetimeconvertercs15-28}

```csharp
var split = reader.Value.ToString().Split(':').Select(int.Parse).ToArray();
switch (split.Length)
{
    case 4: return new TimeSpan((split[0] * 24) + split[1], split[2], split[3]);   // d:h:m:s
    case 3: return new TimeSpan(split[0], split[1], split[2]);                     // h:m:s
    default: throw new ArgumentException("Expected either 0:0:0:0 or 0:0:0 format, but received: " + reader.Value);
}
```

- **Exactamente 3 o 4 enteros separados por dos puntos.** `"0:08:32"`, `"40:12:14"`, `"1:16:12:14"` están todos bien
  (fixture `SabnzbdQueueTimeConverterFixture.cs:14-20`); `"1"`, `"0:1"`, `"0:0:0:0:1"` lanzan excepción (`:28-35`). Los ceros a la izquierda están bien (`int.Parse`).
- La `ArgumentException` lanzada **no** la captura `Json.TryDeserialize` ni `Json.Deserialize`.
- Una **cadena vacía** `""` se divide en `[""]` → `int.Parse` lanza `FormatException`. Nunca devuelvas `""`.
- Omitir `timeleft` por completo es seguro: el convertidor no se invoca y `Timeleft` se queda en `TimeSpan.Zero`.

### 1.5 `mode=queue&name=delete`: `SabnzbdProxy.RemoveFromQueue` (`SabnzbdProxy.cs:64-72`) {#15-modequeuenamedelete--sabnzbdproxyremovefromqueue-sabnzbdproxycs64-72}

```
GET /api?mode=queue&name=delete&del_files={0|1}&value={nzo_id}&apikey=KEY&output=json
```

`del_files = deleteData ? 1 : 0` (`SabnzbdProxy.cs:68`). **No hay parámetro `archive` en la ruta de la cola.**
El cuerpo de la respuesta solo pasa por `CheckForError`; no se deserializa nada.

### 1.6 `mode=history` (lectura): `SabnzbdProxy.GetHistory` (`SabnzbdProxy.cs:132-146`) {#16-modehistory-read--sabnzbdproxygethistory-sabnzbdproxycs132-146}

Petición: `GET /api?mode=history&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- Llamante: `Sabnzbd.GetHistory()` con `start=0, limit=_configService.DownloadClientHistoryLimit`
  (`Sabnzbd.cs:110`). Por defecto **60** en ambos repos
  (Sonarr `src/NzbDrone.Core/Configuration/ConfigService.cs:184`, Radarr `:236`).
- Extracción: `SelectToken("history")` (`SabnzbdProxy.cs:145`); el nivel superior debe ser `{"history": {...}}`.

`SabnzbdHistory` (`SabnzbdHistory.cs`): `paused` (`bool`, sin uso), `slots` → `Items`.

`SabnzbdHistoryItem` (`SabnzbdHistoryItem.cs`):

| Clave JSON | Miembro C# | Tipo C# | Notas |
|---|---|---|---|
| `fail_message` | `FailMessage` | `string` | Pasa a ser `DownloadClientItem.Message` (`Sabnzbd.cs:132`) y activa el caso especial de Warning (§1.6.1). |
| `bytes` | `Size` | `long` | **BYTES, no MB**. Se asigna `TotalSize = sabHistoryItem.Size` tal cual (`Sabnzbd.cs:128`). Es la mayor diferencia respecto a `mode=queue`. |
| `category` | `Category` | `string` | Ojo: `category`, mientras que la cola usa `cat`. |
| `nzb_name` | `NzbName` | `string` | Se lee, pero nunca se usa. |
| `download_time` | `DownloadTime` | `int` (segundos) | Se lee, pero nunca se usa. |
| `storage` | `Storage` | `string` | La ruta de salida. Ver §1.6.2: es lo que se elimina con `rm -rf`'d. |
| `status` | `Status` | `SabnzbdDownloadStatus` | `StringEnumConverter` global. |
| `nzo_id` | `Id` | `string` | |
| `name` | `Title` | `string` | |

**No existe ningún miembro de tipo `DateTime` en los modelos de SAB, así que ningún formato de fecha está restringido.**
Nunca se leen `completed` ni `last_history_update` (epoch unix en SAB real). Los únicos valores de tiempo que importan son `timeleft` (§1.4.1) y `download_time` (un entero en segundos que no se lee).

#### 1.6.1 Estado del historial → `DownloadItemStatus` (`Sabnzbd.cs:116-158`) {#161-history-status--downloaditemstatus-sabnzbdcs116-158}

```
Deleted                                   -> skipped entirely (Sabnzbd.cs:116-119)
Failed  + fail_message == "Unpacking failed, write error or disk is full?"
        (InvariantCultureIgnoreCase)      -> DownloadItemStatus.Warning     (:140-144)
Failed  (any other message)               -> DownloadItemStatus.Failed      (:147)
Completed                                 -> DownloadItemStatus.Completed   (:152)
anything else (Verifying/Moving/...)      -> DownloadItemStatus.Downloading (:157)
```

Cada elemento del historial recibe `RemainingSize = 0`, `RemainingTime = TimeSpan.Zero`, `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:129-135`).

El propio `DownloadItemStatus` (`src/NzbDrone.Core/Download/DownloadItemStatus.cs:3-11`):
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

El bucle recorre **todo el camino hasta la raíz** y se queda con el ancestro *más alto* cuyo último segmento coincide con
`name`. Su propósito: si `storage` apunta a un archivo dentro de la carpeta del trabajo, sube hasta la carpeta del trabajo (fixture `SabnzbdFixture.cs:376-391`). Si `storage` ya es la carpeta del trabajo, ningún ancestro coincide y `OutputPath == storage`, que es justo lo que quieres.

**Recomendación para el emulador: pon `storage` en la ruta de la carpeta del trabajo.**

Si `storage` está vacío ⇒ `OutputPath` se queda vacío ⇒ `CompletedDownloadService.ValidatePath` muestra la advertencia "Download doesn't contain intermediate path, Skipping." (Sonarr `CompletedDownloadService.cs:299-303`).

### 1.7 `mode=history&name=delete`: `SabnzbdProxy.RemoveFromHistory` (`SabnzbdProxy.cs:74-83`) {#17-modehistorynamedelete--sabnzbdproxyremovefromhistory-sabnzbdproxycs74-83}

```
GET /api?mode=history&name=delete&del_files={0|1}&value={nzo_id}&archive={0|1}&apikey=KEY&output=json
```

```csharp
request.AddQueryParam("del_files", deleteData ? 1 : 0);          // :78
request.AddQueryParam("value", id);                              // :79
request.AddQueryParam("archive", deletePermanently ? 0 : 1);     // :80   <-- inverted
```

y el que lo llama (`Sabnzbd.cs:208`):

```csharp
_proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
```

Así que `deletePermanently == (status is Failed)`, y por tanto:

| Estado del elemento | `del_files` | `archive` |
|---|---|---|
| Completed | 1 | **1** (lo archiva) |
| Failed | 1 | **0** (borrado permanente) |

Sí, a primera vista parece al revés, pero es lo que hace el código.

### 1.8 `mode=addfile`: `SabnzbdProxy.DownloadNzb` (`SabnzbdProxy.cs:46-62`) {#18-modeaddfile--sabnzbdproxydownloadnzb-sabnzbdproxycs46-62}

```
POST /api?mode=addfile&cat={category}&priority={int}&apikey=KEY&output=json
Content-Type: multipart/form-data; boundary=...
  part: Content-Disposition: form-data; name="name"; filename="<CleanFileName(Release.Title)>.nzb"
        Content-Type: application/x-nzb
```

- El campo multipart se llama literalmente `name` y la parte lleva un `filename` (`SabnzbdProxy.cs:53`,
  `HttpRequestBuilder.cs:379-395`, emitido en `:180-195`).
- El filename sale de `FileNameBuilder.CleanFileName(release.Title) + ".nzb"`
  (Sonarr `src/NzbDrone.Core/Download/UsenetClientBase.cs:43`, Radarr `:43`).
- **`cat` ignora el argumento `category` del método** y lee los ajustes directamente
  (`SabnzbdProxy.cs:50`: `request.AddQueryParam("cat", settings.TvCategory);` — Radarr: `settings.MovieCategory`).
  No pasa nada, porque quien llama pasa el mismo valor.
- `priority` es el `int` sin procesar de `SabnzbdPriority` (ver §2), elegido según la antigüedad:
  Sonarr `Sabnzbd.cs:43` `remoteEpisode.IsRecentEpisode() ? Settings.RecentTvPriority : Settings.OlderTvPriority`;
  Radarr `Sabnzbd.cs:43` `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie ? RecentMoviePriority : OlderMoviePriority`.
- Respuesta `SabnzbdAddResponse` (`Responses/SabnzbdAddResponse.cs`):

| Clave JSON | C# | Tipo |
|---|---|---|
| `status` | `Status` | `bool` — se parsea y luego **nunca se lee** |
| `nzo_ids` | `Ids` | `List<string>`, inicializado vacío en el constructor |

  Se lee con `TryDeserialize`; si falla, se usa un `{Status=true, Ids=[]}` sintético (`SabnzbdProxy.cs:55-59`).
  Luego `Sabnzbd.cs:47-52`:

```csharp
if (response == null || response.Ids.Empty())
{
    throw new DownloadClientRejectedReleaseException(remoteEpisode.Release, "SABnzbd rejected the NZB for an unknown reason");
}

return response.Ids.First();
```

  **`nzo_ids` debe ser un array no vacío de strings.** `"nzo_ids": null` es lo mismo que no enviarlo
  (`NullValueHandling.Ignore` deja la lista vacía del constructor) y falla igual.

### 1.9 Estado de la cola → `DownloadItemStatus` (`Sabnzbd.cs:60-103`) {#19-queue-status--downloaditemstatus-sabnzbdcs60-103}

```
Deleted                                       -> skipped (Sabnzbd.cs:62-65)
(queue.paused && slot.priority != Force) || slot.status == Paused
                                              -> Paused, and RemainingTime forced to null (:78-84)
Queued | Grabbing | Propagating               -> Queued        (:85-90)
everything else                               -> Downloading   (:93)
```

Además, `Sabnzbd.cs:96-100`: un título que empieza con el texto literal `"ENCRYPTED /"` se le quitan esos
11 caracteres y el elemento se marca con `IsEncrypted = true`.

Cada elemento de la cola recibe `CanBeRemoved = true` y `CanMoveFiles = true` (`Sabnzbd.cs:75-76`).

### 1.10 Filtro de categoría en el cliente (`Sabnzbd.cs:186-195`) {#110-client-side-category-filter-sabnzbdcs186-195}

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

Igualdad de cadenas ordinal. Un elemento en la categoría `*` solo se acepta cuando la categoría configurada está en blanco.

### 1.11 Modos que existen en el proxy pero nunca se llaman {#111-modes-that-exist-in-the-proxy-but-are-never-called}

- `mode=retry&value={id}` (`SabnzbdProxy.cs:148-160`, response `{status, nzo_id}` →
  `Responses/SabnzbdRetryResponse.cs`). `ISabnzbdProxy.RetryDownload` no tiene **ningún caller** en ninguno de los dos repos.
- `Responses/SabnzbdCategoryResponse.cs` (`{"categories": [...]}`, o sea `mode=get_cats`) está **completamente sin referencias** en ambos repos.
- `Sabnzbd.ValidatePath` (`Sabnzbd.cs:576-592`) es privado y nunca se llama (código muerto).

## 2. `SabnzbdDownloadStatus` y `SabnzbdPriority`: miembros exactos, manejo de valores desconocidos o nulos {#2-sabnzbddownloadstatus-and-sabnzbdpriority--exact-members-unknownnull-handling}

### 2.1 `SabnzbdPriority.cs` (archivo completo) {#21-sabnzbdprioritycs-complete-file}

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

- `Enum.TryParse<T>(string, out T)` es la sobrecarga **sensible a mayúsculas** (semántica de .NET).
  `"Normal"` se parsea; `"normal"` **no** — y si falla, `output` queda en
  `default(SabnzbdPriority) == 0 == Normal`, así que un caso incorrecto degrada en silencio a Normal.
  `"Force"` importa (§1.9), `"force"` no funciona.
- Las cadenas numéricas también se parsean: `"2"` → `Force`, `"-100"` → `Default`. Un número JSON `2` también funciona
  (`reader.Value.ToString()` == `"2"`).
- **`"priority": null` lanza una `NullReferenceException`** (`reader.Value.ToString()` sobre null).
  Esto *no* lo atrapa `Json.TryDeserialize`. Omite la clave o envía un valor real.
- Omitir `priority` es seguro: el converter no se invoca, el miembro se queda en `Normal` (0).
- El converter solo está registrado en `SabnzbdQueueItem.Priority` (`SabnzbdQueueItem.cs:21`);
  los elementos del historial no tienen prioridad.
- Estos mismos enteros son los que Sonarr/Radarr envían de vuelta como `&priority=` en `mode=addfile`
  (`SabnzbdSettings.cs` pone por defecto tanto `Recent*Priority` como `Older*Priority` en
  `(int)SabnzbdPriority.Default` = `-100`).

### 2.2 `SabnzbdDownloadStatus.cs` (archivo completo); el orden de declaración da los valores implícitos 0..15 {#22-sabnzbddownloadstatuscs-complete-file-declaration-order--implicit-values-015}

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

- **No hay un converter por propiedad.** El `StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }` registrado globalmente (`Json.cs:32`) se encarga de eso.
- Un **nombre desconocido lanza una excepción** (Newtonsoft `EnumUtils.ParseEnum` → `JsonSerializationException`), y como `GetQueue`/`GetHistory` usan `Json.Deserialize` (no Try), la llamada completa de la cola o del historial falla. **Nunca envíes un estado que no esté en esta lista.**
- Envía los nombres canónicos de SAB exactamente como aparecen arriba (`"Downloading"`, `"QuickCheck"`, `"Completed"`, `"Failed"`, `"Propagating"`, ...). El emparejamiento de enums de Newtonsoft sí recurre a una comparación sin distinguir mayúsculas, pero lo único que vale la pena es confiar en la capitalización exacta.
- Los enteros también se aceptan (`AllowIntegerValues` es true por defecto), pero no los uses.
- Un `null` de JSON para `status` se ignora por `NullValueHandling.Ignore` y el miembro sigue siendo `Grabbing` (0): un slot de la cola se convierte en silencio en `Queued`, y un slot del historial en `Downloading`. Envía siempre un estado explícito.

---

## 3. `get_config`: qué se lee exactamente y las reglas de validación {#3-get_config-exactly-what-is-read-and-the-validation-rules}

### 3.1 El modelo: `SabnzbdCategory.cs` {#31-the-model--sabnzbdcategorycs}

Este archivo contiene `SabnzbdConfig`, `SabnzbdConfigMisc`, `SabnzbdCategory` **y** `SabnzbdSorter`.
No existe **ningún** `SabnzbdConfig.cs` en ninguno de los dos repositorios (confirmado con el listado de la API de contenidos de GitHub de `src/NzbDrone.Core/Download/Clients/Sabnzbd`).

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

### 3.2 `config.misc.*`: el conjunto completo de claves leídas (`SabnzbdCategory.cs:23-37`) {#32-configmisc--the-complete-set-of-keys-read-sabnzbdcategorycs23-37}

| Clave JSON | Tipo C# | Leído en | Propósito |
|---|---|---|---|
| `complete_dir` | `string` | `Sabnzbd.cs:218` | Base para cada ruta de categoría. |
| `tv_categories` | `string[]` | `Sabnzbd.cs:265, 493` | |
| `enable_tv_sorting` | `bool` | `Sabnzbd.cs:265, 493` | |
| `movie_categories` | `string[]` | `Sabnzbd.cs:269, 502` | |
| `enable_movie_sorting` | `bool` | `Sabnzbd.cs:269, 502` | |
| `date_categories` | `string[]` **mediante `SabnzbdStringArrayConverter`** | `Sabnzbd.cs:273, 511` | |
| `enable_date_sorting` | `bool` | `Sabnzbd.cs:273, 511` | |
| `pre_check` | `bool` | `Sabnzbd.cs:443` | |
| `history_retention` | `string` | `Sabnzbd.cs:540, 561-573` | Heredado (legacy), SAB < 4.3. |
| `history_retention_option` | `string` | `Sabnzbd.cs:541, 544` | SAB >= 4.3. |
| `history_retention_number` | `int` | `Sabnzbd.cs:542, 553` | SAB >= 4.3. |

`SabnzbdStringArrayConverter` (`JsonConverters/SabnzbdStringArrayConverter.cs:25-39`) — se aplica solo
a `date_categories` (`SabnzbdCategory.cs:30`):

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

Un **string** de JSON se convierte en un array de 1 elemento; un **null** se convierte en `[null]` (un array de 1 elemento que contiene
null); un **array** se deserializa normalmente; cualquier otra cosa (un número, un objeto) lanza una excepción. Comentario de documentación en `:7-9`: "En algunas propiedades, sab serializa un array de un solo elemento como un string simple."

### 3.3 `config.categories[]`: `SabnzbdCategory` (`SabnzbdCategory.cs:39-48`) {#33-configcategories--sabnzbdcategory-sabnzbdcategorycs39-48}

| Clave JSON | C# | Se lee en |
|---|---|---|
| `priority` | `int Priority` | nunca se lee |
| `pp` | `string PP` | nunca se lee (la versión camelCase de `PP` es `pp`) |
| `name` | `string Name` | `Sabnzbd.cs:251, 255, 458` |
| `script` | `string Script` | nunca se lee |
| `dir` | `string Dir` | `Sabnzbd.cs:238` (`Dir.TrimEnd('*')`), `Sabnzbd.cs:462` (`Dir.EndsWith("*")`) |

`FullPath` (`OsPath`) se calcula, no se deserializa.

Ensamblado de rutas — `Sabnzbd.GetCategories` (`Sabnzbd.cs:216-244`):

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

`OsPath.operator+` (`src/NzbDrone.Common/Disk/OsPath.cs:420-448`) devuelve `left` cuando `right.IsEmpty`,
así que `dir: ""` da exactamente `FullPath == complete_dir`. `IsRooted` para una ruta de tipo Unix es
`_path.StartsWith("/")` (`OsPath.cs:142-145`). El tipo de ruta se deduce a partir de la cadena
(`OsPath.cs:43-60`): una `/` al inicio ⇒ Unix, una `\` o una letra de unidad ⇒ Windows. Una ruta de tipo Unix
pasada a un Sonarr alojado en Windows falla en `CompletedDownloadService.ValidatePath` (`:305-310`).

### 3.4 Las dos trampas de NRE (y qué es realmente seguro) {#34-the-two-nre-landmines-and-what-is-actually-safe}

| Forma del payload | Resultado |
|---|---|
| **`"misc"` ausente o `null`** | `Misc` queda en null (el constructor no pone valor por defecto; `NullValueHandling.Ignore` al leer) → **NullReferenceException en `Sabnzbd.cs:218`**, que aparece como "Test was aborted due to an error: …" y como un error registrado en los health checks. |
| **una categoría con `"dir"` ausente o `null`** | `Dir` es null → **NullReferenceException en `Sabnzbd.cs:238`** (`category.Dir.TrimEnd('*')`) y otra vez en `:462` (`category.Dir.EndsWith("*")`). |
| `"categories": null` o ausente | Seguro: la lista vacía del constructor se mantiene. `GetStatus` entonces no encuentra ninguna categoría y `OutputRootFolders` se queda vacío. |
| `"sorters": null` o ausente | Seguro: lista vacía del constructor; `config.Sorters.Any(...)` en `Sabnzbd.cs:484` funciona. |
| `"servers": null` o ausente | Seguro y nunca se lee (`List<object>`, `SabnzbdCategory.cs:19`). |
| `"tv_categories"/"movie_categories"/"date_categories": null` | Seguro: `ContainsCategory` devuelve `true` para null/vacío (§3.5), pero eso solo importa si el `enable_*_sorting` correspondiente está en true. |

**Regla: envía siempre `misc` como objeto y cada categoría con un `dir` de tipo string (usa `""`).**

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

Confirmado por los fixtures: `enable_tv_sorting=true` + `tv_categories=null` **falla**
(`SabnzbdFixture.cs:636-645`), y + `tv_categories=[]` también **falla** (`:647-656`).
`TvCategory=null` + `tv_categories=["Default"]` falla (`:680-691`).

### 3.6 `Test()`: el orden exacto y las reglas (`Sabnzbd.cs:286-292`) {#36-test--the-exact-order-and-rules-sabnzbdcs286-292}

```csharp
protected override void Test(List<ValidationFailure> failures)
{
    failures.AddIfNotNull(TestConnectionAndVersion());
    failures.AddIfNotNull(TestAuthentication());
    failures.AddIfNotNull(TestGlobalConfig());
    failures.AddIfNotNull(TestCategory());
}
```

Lo envuelve `DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`),
que captura cualquier excepción que se escape y añade `"Test was aborted due to an error: " + ex.Message`.

**`TestConnectionAndVersion()` (`Sabnzbd.cs:368-414`)** — 1 × `mode=version`:

1. versión no interpretable → fallo en el campo `Version` (`DownloadClientSabnzbdValidationUnknownVersion`).
2. `rawVersion == "develop"` (sin distinguir mayúsculas) → **advertencia** en `Version`, `IsValid` sigue en true
   (fixture `SabnzbdFixture.cs:566-577`).
3. `version.Major >= 1` → pasa (`:389-392`).
4. si no, `version.Minor >= 7` → pasa (`:394-397`).
5. si no, fallo: versión requerida `"0.7.0"` (`:399-404`).
   Tabla del fixture (`SabnzbdFixture.cs:549-564`): `0.6.9`→false, `0.7.0`/`0.8.0`/`1.0.0`/`1.0.0RC1`/`1.1.x`→true.
6. Cualquier excepción → fallo en el campo `Host` ("unable to connect"), detalle = `ex.Message` (`:406-413`).

**`TestAuthentication()` (`Sabnzbd.cs:416-438`)** — 1 × `mode=get_config`. Captura la excepción y luego compara
`ex.Message` con `ContainsIgnoreCase`:

| Subcadena que coincide | Campo del fallo |
|---|---|
| `API Key Incorrect` | `APIKey` — `DownloadClientValidationApiKeyIncorrect` |
| `API Key Required` | `APIKey` — `DownloadClientValidationApiKeyRequired` |
| cualquier otra cosa | **se vuelve a lanzar** → el genérico "Test was aborted due to an error: …" |

Como `CheckForError` envuelve el cuerpo como `"Error response received from SABnzbd: {error}"`
(`SabnzbdProxy.cs:244`), la comparación funciona cuando tu `error` *contiene* `API Key Incorrect` /
`API Key Required`, que es el texto propio de SAB.

**`TestGlobalConfig()` (`Sabnzbd.cs:440-453`)** — 1 × `mode=get_config`, más 1 × `mode=version`
solo si `pre_check` es true:

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

Umbral: **SAB >= 1.1.0** (`HasVersion(major:1, minor:1, patch:0)`, `Sabnzbd.cs:294-332`).
`pre_check: false` evita todo el bloque, incluida la llamada extra a `mode=version`.

**`TestCategory()` (`Sabnzbd.cs:455-521`)** — 1 × `mode=get_config` (una *tercera*), más lo que necesite
`GetCategories`. Las comprobaciones se hacen en este orden y gana la primera que coincida:

1. categoría coincidente (`Name == Settings.TvCategory` / `MovieCategory`) cuyo `dir` **termina en `*`**
   → advertencia en `TvCategory`/`MovieCategory` "enable job folders", InfoLink `config/categories/` (`:460-469`).
2. ninguna categoría coincidente **y** la categoría configurada no está en blanco → advertencia
   `DownloadClientValidationCategoryMissing`, InfoLink `config/categories/` (`:471-481`).
3. `config.Sorters.Any(s => s.is_active && ContainsCategory(s.sort_cats, cat))` → advertencia, InfoLink
   `config/sorting/` (`:483-491`). Comentario del código en `:483`: *"Nuevo en SABnzbd 4.1, pero en versiones
   anteriores esto estará vacío y no se aplicará"*.
4. `misc.enable_tv_sorting && ContainsCategory(misc.tv_categories, cat)` → advertencia (`:493-500`).
5. `misc.enable_movie_sorting && ContainsCategory(misc.movie_categories, cat)` → advertencia (`:502-509`).
6. `misc.enable_date_sorting && ContainsCategory(misc.date_categories, cat)` → advertencia (`:511-518`).

`SabnzbdSorter` (`SabnzbdCategory.cs:50-66`) — se leen: `sort_cats` (`List<string>`, vacío en el constructor),
`is_active` (`bool`). Están en el modelo pero nunca se leen: `name`, `order`, `min_size`,
`multipart_label`, `sort_string`, `sort_type` (`List<int>`).

**Nota sobre el tráfico:** los cuatro métodos `Test*` hacen sus propias llamadas y no se cachea nada. Una prueba
de conexión lanza más o menos **2 × `mode=version` y 3 × `mode=get_config`** (una cuarta llamada de versión si
`pre_check` es true).

### 3.7 Retención del historial en `config.misc` → `RemovesCompletedDownloads` (`Sabnzbd.cs:538-574`) {#37-configmisc-history-retention--removescompleteddownloads-sabnzbdcs538-574}

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

`true` activa una **advertencia** de comprobación de estado
(`HealthCheck/Checks/DownloadClientRemovesCompletedDownloadsCheck.cs:44-53`).
Cobertura del fixture `SabnzbdFixture.cs:455-510`: los valores heredados `"0"`/`""`/`null`/`"15d"` → false;
`"-1"`/`"15"`/`"3"`/`"3d"` → true.

**La respuesta más limpia para el emulador: `history_retention_option: "all"`, `history_retention_number: 0`,
`history_retention: "0"`.**

### 3.8 `SortingMode` y su comprobación de salud (`Sabnzbd.cs:263-279`) {#38-sortingmode-and-its-health-check-sabnzbdcs263-279}

`GetStatus` establece `SortingMode` en `"TV"`, `"Movie"` o `"Date"` usando los mismos predicados `enable_*_sorting && ContainsCategory(...)`. Cualquier valor que no esté en blanco genera una advertencia en `HealthCheck/Checks/DownloadClientSortingCheck.cs:45-55`. Mantén los tres `enable_*_sorting` en false.

### 3.9 `IsLocalhost` (`Sabnzbd.cs:260`)

```csharp
IsLocalhost = Settings.Host == "127.0.0.1" || Settings.Host == "localhost"
```

Ordinal, distingue mayúsculas y minúsculas; `::1`, `Localhost` y cualquier nombre de host **no** cuentan. Esto cambia qué mensaje de `RemotePathMappingCheck` verás (ver §6.2).

---

## 4. Manejo de errores: `CheckForError` (`SabnzbdProxy.cs:222-246`) {#4-error-handling--checkforerror-sabnzbdproxycs222-246}

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

`SabnzbdJsonError` (`SabnzbdJsonError.cs`, completo):

```csharp
public string Status { get; set; }
public string Error  { get; set; }

public bool Failed => !string.IsNullOrWhiteSpace(Status) &&
                      Status.Equals("false", StringComparison.InvariantCultureIgnoreCase);
```

Reglas, con precisión:

- `CheckForError` se ejecuta en **cada** respuesta, antes de cualquier deserialización específica del modo
  (`SabnzbdProxy.cs:217`).
- `Status` está tipado como `string`, pero SAB envía un **booleano** de JSON. Newtonsoft convierte `false` → `"False"`,
  que `Failed` compara sin distinguir mayúsculas. Tanto `false` (booleano) como `"false"` (cadena) funcionan.
- Una respuesta **sin `status` de nivel superior** (p. ej. `{"version": …}`, `{"queue": {...}}`,
  `{"history": {...}}`, `{"config": {...}}`) deja `Status` en null → `Failed` en false → no hay error.
- `status: true` → `"True"` → no es fallo.
- **Cuerpo que no es JSON**: `TryDeserialize` devuelve false (captura `JsonReaderException` y
  `JsonSerializationException`, `Json.cs:107-116`) y se ejecuta la rama de texto plano. Un cuerpo que empieza
  por `error` (sin distinguir mayúsculas) → `Status = "false"` → lanza
  `DownloadClientException("Error response received from SABnzbd: {body with 'error: ' stripped}")`.
  Cualquier otro cuerpo que no sea JSON → `Status = "true"` → **se trata como éxito**, y la deserialización específica
  del modo falla por su cuenta.
- Un **cuerpo JSON cuyo `status` es un objeto** (`mode=fullstatus`) también entra en la rama de texto plano,
  porque un token `StartObject` no puede asignarse a una propiedad `string` → `Status` pasa a ser `"true"`.
- Ojo con la asignación redundante `result.Error = …` en `:239`: `Error` se asigna incluso en la rama de éxito. No tiene
  efecto (nada lee `Error` salvo que `Failed` sea true).

Mapeo de excepciones en `ProcessRequest` (`SabnzbdProxy.cs:187-220`):

| Capturado | Lanzado |
|---|---|
| `HttpException` (cualquier no 2xx, incl. 401/403/404/500) | `DownloadClientException("Unable to connect to SABnzbd, {0}")` |
| `HttpRequestException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |
| `WebException` con `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, certificate validation failed.")` |
| otra `WebException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |

**Las cadenas exactas de fallo de autenticación que se comparan** (`Sabnzbd.cs:424, 429`, literales exactos, comparados con
`ContainsIgnoreCase` contra el mensaje de la excepción):

- `"API Key Incorrect"`
- `"API Key Required"`

No se clasifica nada más. Devuélvelas tal cual como el valor de `error` en una respuesta **HTTP 200**.

**Por qué nunca se debe devolver un código que no sea 200:** `HttpClient.Execute` lanza la excepción antes de que `CheckForError` llegue a ejecutarse
(`HttpClient.cs:106-121`), y el mensaje de la `HttpException` resultante solo contiene el estado, el método y la URL, no el cuerpo
(`HttpException.cs:18`), así que la comparación con `"API Key Incorrect"` / `"API Key Required"` nunca se activa. El usuario ve
"Unable to connect to SABnzbd" o "Test was aborted due to an error" en lugar de un mensaje útil, y cada comprobación de estado
trata el cliente como inalcanzable.

---

## 5. La secuencia posterior a la importación {#5-the-post-import-sequence}

### 5.1 Quién llama a `RemoveItem` y con qué parámetros {#51-who-calls-removeitem-and-with-what}

`DownloadEventHub` (`src/NzbDrone.Core/Download/DownloadEventHub.cs`, idéntico en ambos repos salvo
el BOM):

- `Handle(DownloadCompletedEvent)` (`:48-69`): llama a `MarkItemAsImported` (SAB lanza
  `NotSupportedException` — `DownloadClientBase.cs:189-192` — que se registra en debug y se ignora), luego
  sale temprano si el elemento ya está `Removed`, `!CanBeRemoved` o todavía `Downloading`, y después sale
  temprano si no se cumple `definition.RemoveCompletedDownloads`.
- `Handle(DownloadFailedEvent)` (`:26-46`): depende de `definition.RemoveFailedDownloads`.
- `Handle(DownloadCanBeRemovedEvent)` (`:71-85`): depende de `definition.RemoveCompletedDownloads`.
- Los tres pasan por `RemoveFromDownloadClient` (`:87-103`):

```csharp
_logger.Debug("[{0}] Removing download from {1} history", …);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);   // :92 -- deleteData is ALWAYS true
trackedDownload.DownloadItem.Removed = true;
```

Valores por defecto de `DownloadClientDefinition` (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17-18`):

```csharp
public bool RemoveCompletedDownloads { get; set; } = true;
public bool RemoveFailedDownloads    { get; set; } = true;
```

La ruta manual de la API `DELETE /api/v3/queue/{id}?removeFromClient=true` también pasa `true`
(Sonarr `src/Sonarr.Api.V3/Queue/QueueController.cs:342`). **No hay ningún punto de llamada que pase
`deleteData: false`.**

### 5.2 `Sabnzbd.RemoveItem` (`Sabnzbd.cs:197-214`): la secuencia exacta {#52-sabnzbdremoveitem-sabnzbdcs197-214--the-exact-sequence}

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

Así que la secuencia de cables posterior a la importación contra el emulador es:

1. `GET /api?mode=queue&start=0&limit=0&category=tv&apikey=…&output=json` (para decidir cola o historial)
2. **borrado local del directorio de salida** (§5.3) — antes de cualquier otra llamada HTTP
3. `GET /api?mode=history&name=delete&del_files=1&value={nzo_id}&archive=1&apikey=…&output=json`

Para un elemento **fallido**: no hay borrado local (el estado es `Failed`, no `Completed`), y **`archive=0`** —
la inversión en `SabnzbdProxy.cs:80` (`archive = deletePermanently ? 0 : 1`, donde
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

- **Sí, borra la carpeta de salida de forma recursiva.** `DeleteFolder(path, recursive: true)` en `:129`.
- `OutputPath` aquí es el `storage` del elemento del historial después de la reasignación de rutas remotas y del recorrido hacia arriba de la carpeta del trabajo (§1.6.2). Para un directorio mágico plano, eso significa `rm -rf /mnt/zurg/__magic__/__all__/<Title>`.
- El ajuste que manda es el interruptor **Remove Completed Downloads** del cliente de descargas (`DownloadClientDefinition.RemoveCompletedDownloads`, por defecto **true**), *no* un ajuste de SAB y *no* `del_files`. En la interfaz no hay un interruptor aparte para "borrar datos".
- Los fallos se ignoran con un aviso: un montaje de solo lectura deja ruido en el log, pero no rompe la importación.
- La cobertura de fixtures en `SabnzbdFixture.cs:693-803` comprueba: la carpeta se borra de forma recursiva, el archivo se borra, no pasa nada cuando la ruta no existe, y no pasa absolutamente nada (ni siquiera una comprobación de `FolderExists`) cuando `deleteData` es false.

### 5.4 Modo de transferencia: ¿el archivo se mueve o se copia? {#54-transfer-mode-is-the-file-moved-or-copied}

`Sabnzbd` establece `CanMoveFiles = true` en **cada** elemento, tanto en la cola (`Sabnzbd.cs:76`) como en el historial (`Sabnzbd.cs:135`). La ruta de importación automática es `CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, …)` (Sonarr `CompletedDownloadService.cs:148-151`), y después:

Sonarr `src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152`
(Radarr `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, con lógica idéntica):

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
(`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`). Una importación con `copyOnly` usaría en cambio `TransferMode.HardLinkOrCopy` si "Use Hardlinks instead of Copy" está activado, y si no, `TransferMode.Copy` (`:94-108`).

`TransferMode` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`) es `[Flags]`:
`None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy = Copy|HardLink`.

### 5.5 ¿Si falla un Move se hace una copia? **No. Si falla un Move, la importación falla.** {#55-does-a-failed-move-fall-back-to-a-copy--no-a-failed-move-is-a-failed-import}

`src/NzbDrone.Common/Disk/DiskTransferService.cs` (idéntico byte a byte entre los dos repos, verificado).
`TransferFile`, `:256-392`; la rama `TransferMode.Move` en `:360-389`:

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

- El **único** fallback de copia es el caso especial `isCifs && !isSameMount` en `:378-385`, basado en `targetMount.DriveFormat == "cifs"` (`:342`). Se elige *de antemano* según el formato de la unidad, nunca como reacción a un fallo.
- `TryMoveFileVerified` (`:487-503`) captura la excepción, llama a `RollbackPartialMove` (salvo que la excepción sea `FileAlreadyExistsException`) y **la relanza**:

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

- `VerifyFile` (`:505-524`) compara el tamaño del destino con el del origen, espera 3 s (`WaitForIO`, `:467-471`), vuelve a comprobar y luego lanza `IOException("File move incomplete, data loss may have occurred. [{target}] was {n} bytes long instead of the expected {m}.")`.
- Esa `IOException` sube a través de `EpisodeFileMovingService.TransferFile` (`:151`) hasta el `catch (Exception e)` genérico en `ImportApprovedEpisodes.cs:218-222` (Radarr `:197-201`), y produce `ImportResult(importDecision, "Failed to import episode")` / `"Failed to import movie"`. **No se intenta ninguna copia.**
- Otras `IOException` de comprobación previa en el mismo método: origen == destino (`:270`, `:277`) y "Destination cannot be a child of the source" (`:312-315`).

Ojo, y es un hecho del runtime de .NET, no código de Sonarr: `DiskProviderBase.MoveFileInternal` (`src/NzbDrone.Common/Disk/DiskProviderBase.cs:293-301`) es un `File.Move` simple, y .NET en Unix recurre a copiar y borrar cuando `rename()` devuelve `EXDEV`. Así que un movimiento entre sistemas de archivos normalmente sigue funcionando, pero como fallback *en tiempo de ejecución*, no de Sonarr. Lo que **no** se tolera es un destino cuyo tamaño difiera del origen, o cualquier excepción que `File.Move` lance (EACCES, EPERM, EROFS en el origen, …).

`TransferFolder` (`:44-137`) lo usan otras rutas de código; ojo a `:124-131`: tras un Move de carpeta, se niega a borrar el origen si quedan más de 100 MB de archivos (`IOException("Large files still exist in {sourcePath} after folder move, not deleting source folder")`).

---

## 6. Las dos comprobaciones de salud {#6-the-two-health-checks}

### 6.1 `DownloadClientRootFolderCheck`: **el único punto donde Sonarr y Radarr realmente difieren** {#61-downloadclientrootfoldercheck--the-one-place-sonarr-and-radarr-genuinely-differ}

Sonarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = status.OutputRootFolders.Where(folder => rootFolders.Any(r => r.Path.PathEquals(folder.FullPath)));
```

Radarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = rootFolders.Where(r => status.OutputRootFolders.Any(folder => r.Path.PathEquals(folder.FullPath) || r.Path.IsParentPath(folder.FullPath)));
```

`IsParentPath` (`src/NzbDrone.Common/Extensions/PathExtensions.cs:123-140`) sube **hacia arriba** desde el hijo:

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

Así que `r.Path.IsParentPath(folder.FullPath)` es verdadero cuando **la carpeta raíz es un ancestro de la
carpeta de salida de descargas**, es decir, la carpeta de salida está *dentro* de una carpeta raíz. Es una prueba de ancestro estricta
(empieza desde `child.Directory`); la igualdad se maneja por separado con `PathEquals`.

**Respondiendo directamente a la pregunta del predicado:**

| Relación (carpeta de salida O vs carpeta raíz R) | Sonarr | Radarr |
|---|---|---|
| O == R | **avisa** | **avisa** |
| O dentro de R (R es ancestro de O) | sin aviso | **avisa** |
| O es el PADRE de R (O es ancestro de R) | sin aviso | **sin aviso** |
| sin relación | sin aviso | sin aviso |

Con `complete_dir = /mnt/zurg/__magic__/__all__` y `dir: ""` (así que
`OutputRootFolders == ["/mnt/zurg/__magic__/__all__"]`):

- Sonarr solo avisa si una carpeta raíz es exactamente `/mnt/zurg/__magic__/__all__`.
- Radarr avisa si una carpeta raíz es `/mnt/zurg/__magic__/__all__`, `/mnt/zurg/__magic__`, `/mnt/zurg` o `/mnt`.
- Ninguno avisa si una carpeta raíz es `/mnt/zurg/__magic__/tv`: el espejo y las carpetas raíz son
  hermanas, así que el par no tiene relación y ninguna regla se activa. Una carpeta raíz *dentro* de la carpeta de salida
  (`/mnt/zurg/__magic__/__all__/anything`) también quedaría en silencio aquí, pero el namespace no permite guardar nada a esa profundidad, así que no es una disposición que pueda existir.

`PathEquals` (`PathExtensions.cs:55-73`) normaliza Unicode, usa `DiskProviderBase.PathStringComparison`
(`OrdinalIgnoreCase` en Windows, `Ordinal` en el resto — `src/NzbDrone.Common/Disk/DiskProviderBase.cs:17-23`), y reintenta con `CleanFilePath()` (que no distingue la barra final).

Ambas versiones se vuelven a ejecutar con `ProviderUpdatedEvent` / `ProviderDeletedEvent` / `ModelEvent<RootFolder>` / `ModelEvent<RemotePathMapping>`; Radarr añade `[CheckOn(typeof(ProviderAddedEvent<IDownloadClient>))]`
en `:17`. El resultado es `HealthCheckResult.Warning` con el ancla `#downloads-in-root-folder`. El mensaje
interpola `folder.FullPath` en Sonarr y `folder.Path` en Radarr (`:60` en ambas). Ambas ignoran en silencio `DownloadClientException` y `HttpRequestException` (registro de depuración) y registran cualquier otra excepción
como error.

### 6.2 `RemotePathMappingCheck` — la ruta del cliente local (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs`) {#62-remotepathmappingcheck--the-local-client-path-srcnzbdronecorehealthcheckchecksremotepathmappingcheckcs}

Cortocircuito en `:51-54`: si `EnableCompletedDownloadHandling` está desactivado, la comprobación no hace nada.

Para cada `folder` en `client.GetStatus().OutputRootFolders`:

1. **`!folder.IsValid`** (`:68`): `OsPath.IsValid` = `_path.IsPathValid(PathValidationType.CurrentOs)`
   (`OsPath.cs:228`). En sistemas que no son Windows, esto se reduce a `path.StartsWith("/")` más un
   recorrido con `Path.GetInvalidPathChars()` (`PathExtensions.cs:143-182`, `:403-411`). Errores, en orden:
   - `!status.IsLocalhost` → `RemotePathMappingWrongOSPathHealthCheckMessage` (clave en Radarr:
     `RemotePathMappingCheckWrongOSPath`), ancla `#bad-remote-path-mapping`
   - `_osInfo.IsDocker` → …`BadDockerPath`, ancla `#docker-bad-remote-path-mapping`
   - en cualquier otro caso → …`LocalWrongOSPath`, ancla `#bad-download-client-settings`
2. **`!_diskProvider.FolderExists(folder.FullPath)`** (`:115`):
   - `_osInfo.IsDocker` → …`DockerFolderMissing`, `#docker-bad-remote-path-mapping`
   - `!status.IsLocalhost` → …`LocalFolderMissing`, `#bad-remote-path-mapping`
   - en cualquier otro caso → …`GenericPermissions`, `#permissions-error`

**Para un cliente local (`IsLocalhost` en true, sin Docker) esto se reduce a exactamente dos requisitos:**
la ruta de la carpeta raíz de salida que reporta el cliente debe ser una ruta absoluta *para el sistema operativo en el que corre Sonarr/Radarr*, y
debe **existir en el host de Sonarr/Radarr** como directorio. `/mnt/zurg/__magic__/__all__` tiene que ser visible para
el proceso de los *arr, no solo para el emulador. **Aquí no hay ninguna comprobación de escritura.**

El overload dirigido por eventos (`:178-368`) se dispara con `EpisodeImportFailedEvent` (en Radarr:
`MovieImportFailedEvent`) y, lo más importante, vuelve a llamar a `client.GetItems()` para buscar el `OutputPath`
de la descarga fallida (`:232`).

Ninguna comprobación de salud exige que la carpeta de salida sea *escribible*. `FolderWritable`
(`DiskProviderBase.cs:126-143` en Sonarr / `:127-144` en Radarr), que escribe y borra `sonarr_write_test.txt` / `radarr_write_test.txt`, se usa en
`RootFolderService.Add` (Sonarr `src/NzbDrone.Core/RootFolders/RootFolderService.cs:117-120`) y en
`DownloadClientBase.TestFolder` (`:167-187`), y **`TestFolder` nunca lo llama el cliente SAB**.

## 7. Sonarr vs Radarr — el diff completo {#7-sonarr-vs-radarr--the-complete-diff}

Se comparó con diff cada archivo descargado. Resultados:

**Idénticos byte a byte salvo por un BOM UTF-8 en las copias de Sonarr** (por tanto, los números de línea coinciden exactamente):

`SabnzbdCategory.cs` (sin BOM en ninguno de los dos lados, realmente idénticos), `SabnzbdDownloadStatus.cs`,
`SabnzbdPriority.cs`, `SabnzbdFullStatus.cs`, `SabnzbdJsonError.cs`, `SabnzbdQueue.cs`,
`SabnzbdQueueItem.cs`, `SabnzbdHistory.cs`, `SabnzbdHistoryItem.cs`,
`JsonConverters/*.cs` (las tres), `Responses/*.cs` (las seis),
`src/NzbDrone.Common/Disk/DiskTransferService.cs`, `src/NzbDrone.Core/Download/DownloadEventHub.cs`.

**Solo difieren por el renombrado de `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` (sin cambio en el número de líneas, mismos números de línea):**

- `Sabnzbd.cs` — `:40-52` (`AddFromNzbFile`; la prueba de recencia de Radarr es `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` frente a `remoteEpisode.IsRecentEpisode()` de Sonarr), `:190`, `:251`, `:265/269/273`, `:458`, y cada nombre de campo `NzbDroneValidationFailure` en `TestCategory` (`"TvCategory"` → `"MovieCategory"`).
- `SabnzbdProxy.cs` — `:50`, `:122-124`, `:138-140`.
- `SabnzbdSettings.cs` — valores por defecto `TvCategory = "tv"` frente a `MovieCategory = "movies"`; `RecentTvPriority`/`OlderTvPriority` frente a `RecentMoviePriority`/`OlderMoviePriority` (ambos por defecto a `(int)SabnzbdPriority.Default`). El validador es idéntico en lo demás: `Host` válido, `Port` 1–65535, `ApiKey` obligatorio cuando el nombre de usuario está vacío, `Username`/`Password` obligatorios cuando ApiKey está vacío, categoría `NotEmpty` **como advertencia**.
- `UsenetClientBase.cs` — Radarr además establece `request.AllowAutoRedirect = true` (`:51`) y trata el HTTP `410 Gone` igual que `404` (`:63`) al descargar el NZB del indexador. **Esto es sobre el indexador, no sobre SAB.**
- `DownloadClientBase.cs` — solo los literales "Sonarr"/"Radarr" en el texto de detalle de `TestFolder`.
- `RemotePathMappingCheck.cs` — nombres de las claves de localización (`RemotePathMapping*HealthCheckMessage` frente a `RemotePathMappingCheck*`), `EpisodeImportFailedEvent` frente a `MovieImportFailedEvent`, y el `[CheckOn(ProviderAddedEvent<IDownloadClient>)]` extra de Radarr. **Los predicados son idénticos.**
- `DiskProviderBase.cs` — archivo de prueba de `FolderWritable`: `sonarr_write_test.txt` frente a `radarr_write_test.txt` (Sonarr `:132`, Radarr `:133`).

**Diferencia de comportamiento real — solo una:**

- **`DownloadClientRootFolderCheck.cs:51`.** Sonarr solo advierte con `PathEquals`; Radarr también advierte cuando una carpeta raíz es ancestro de la carpeta de salida. Tabla completa en §6.1.

Todo lo demás — modos, parámetros, formas de JSON, enumeraciones, conversores, `CheckForError`, `RemoveItem`, `DeleteItemData`, modo de transferencia, `DiskTransferService` — es idéntico. **Un solo emulador sirve para ambos.**

Los valores por defecto de configuración son idénticos en ambos:
`DownloadClientHistoryLimit = 60`,
`RemoveCompletedDownloads = true`, `RemoveFailedDownloads = true`.

---

## 8. Payloads de ejemplo mínimos pero completos {#8-minimal-but-complete-example-payloads}

Dado: `complete_dir = /mnt/zurg/__magic__/__all__`; categorías `*`, `tv`, `movies`, todas con `dir: ""`.
Todas las respuestas son **HTTP 200** con `Content-Type: application/json`.

Resultado en `OutputRootFolders`: `dir: ""` ⇒ `FullPath == complete_dir` ⇒ `/mnt/zurg/__magic__/__all__`
para Sonarr (categoría `tv`) y para Radarr (categoría `movies`).

### 8.1 `mode=version`

```json
{
  "version": "4.3.3"
}
```

Debe ser `major.minor.(patch|x)`. `4` ≥ 1 cumple `TestConnectionAndVersion` (`Sabnzbd.cs:389-392`);
≥ 2.0 también significaría que `GetCategories` usaría `fullstatus` en lugar de `queue.my_home` si `complete_dir`
fuera relativo (no lo es).

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

Por qué cada valor:

- `misc` presente como objeto — **obligatorio**, si no, NRE (§3.4).
- cada categoría tiene un `dir` de tipo **string** — **obligatorio**, si no, NRE en `Sabnzbd.cs:238` y `:462`.
- `dir` **no** termina en `*` — si no, sale la advertencia "enable job folders" (`Sabnzbd.cs:462-469`).
- los tres `enable_*_sorting: false` — eliminan tanto las advertencias de `TestCategory` (`Sabnzbd.cs:493-518`) como `DownloadClientSortingCheck`. Ojo: `tv_categories: []` combinado con `enable_tv_sorting: true` daría **error**, porque `ContainsCategory` devuelve true para una lista vacía (`Sabnzbd.cs:525-528`, fixture `SabnzbdFixture.cs:647-656`).
- `sorters: []` — `config.Sorters.Any(s => s.is_active && …)` es false (`Sabnzbd.cs:484`).
- `pre_check: false` — se salta la ida y vuelta `HasVersion(1,1)` en `TestGlobalConfig` (`Sabnzbd.cs:443`).
- `history_retention_option: "all"` → `RemovesCompletedDownloads == false` (`Sabnzbd.cs:546-547`) → no aparece la advertencia de health-check.
- `complete_dir` absoluto → `IsRooted` es true → nunca se consultan `mode=fullstatus` ni `queue.my_home` (`Sabnzbd.cs:220`).

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

Solo se lee `completedir` (`SabnzbdFullStatus.cs:9-10`). La clave envolvente **debe** ser `status`
(`Responses/SabnzbdFullStatusResponse.cs:5`).

### 8.4 Respuesta de `mode=addfile` {#84-modeaddfile-response}

```json
{
  "status": true,
  "nzo_ids": ["SABnzbd_nzo_abc12345"]
}
```

`nzo_ids` debe ser un **array no vacío de strings** (`Sabnzbd.cs:47-52`). `status` se parsea (`Responses/SabnzbdAddResponse.cs:13`) pero nunca se lee; déjalo en `true` para que `CheckForError` vea `"True"`.

### 8.5 `mode=queue&start=0&limit=0&category=tv` — una ranura Downloading {#85-modequeuestart0limit0categorytv--one-downloading-slot}

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

Requisitos obligatorios:

- clave de nivel superior `queue` (`SabnzbdProxy.cs:129`, `SelectToken("queue")`).
- `slots[].status` ∈ los 16 nombres de `SabnzbdDownloadStatus`, con las mayúsculas exactas.
- `slots[].mb` / `mbleft` son **megabytes**, decimales en cultura invariante. Valen tanto strings como números (Newtonsoft los convierte); el SAB real envía strings.
- `slots[].timeleft` debe ser exactamente `h:m:s` o `d:h:m:s`, nunca `""`.
- `slots[].priority` — `"Normal"`, `"High"`, `"Low"`, `"Force"`, `"Paused"`, `"Default"` (distingue mayúsculas) o el equivalente numérico. **Nunca `null`** (NRE).
- `slots[].cat` (no `category`) debe ser igual a la categoría configurada en el cliente, o el elemento se filtra en `Sabnzbd.cs:190`.
- `queue.paused` debe ser `false` salvo que realmente quieras pausado; `true` marca todos los slots que no son `Force` como Paused con un ETA nulo (`Sabnzbd.cs:78-84`).

Resultado en el `DownloadClientItem`: `TotalSize = 1024 * 1024 * 1024`, `RemainingSize = 512 * 1024 * 1024`,
`RemainingTime = 00:08:32`, `Status = Downloading`, `CanBeRemoved = CanMoveFiles = true`.

### 8.6 `mode=history&start=0&limit=60&category=tv` — una ranura Completed y una Failed {#86-modehistorystart0limit60categorytv--one-completed-and-one-failed-slot}

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

Requisitos obligatorios:

- clave de nivel superior `history` (`SabnzbdProxy.cs:145`).
- `slots[].bytes` está en **BYTES** (un número JSON → `long`). No envíes MB aquí: la cola usa MB, el historial usa bytes (`Sabnzbd.cs:72-73` frente a `:128`).
- `slots[].category` (no `cat`).
- `slots[].storage` es la propia carpeta del trabajo; se convierte en `OutputPath`, y para un elemento Completed es lo que `DeleteItemData` borra recursivamente (§5.3). Debe ser una ruta absoluta válida para el sistema operativo donde corren Sonarr/Radarr y debe existir allí (`RemotePathMappingCheck`, §6.2).
- `slots[].status` exacto en mayúsculas y minúsculas; los elementos `Deleted` se descartan por completo (`Sabnzbd.cs:116-119`).
- `fail_message` exactamente `"Unpacking failed, write error or disk is full?"` degrada un elemento Failed a `Warning` en lugar de `Failed` (`Sabnzbd.cs:140-144`); usa otro texto para un fallo real.
- Radarr: `category` debe ser `movies` (o el que tengas configurado) y `name` debería poder parsearse como una película.

### 8.7 Respuesta de error (cualquier modo) {#87-error-response-any-mode}

```json
{
  "status": false,
  "error": "API Key Incorrect"
}
```

**HTTP 200.** `status` puede ser el booleano `false` o la cadena `"false"`; ambos cumplen
`SabnzbdJsonError.Failed` (`SabnzbdJsonError.cs:10-11`). El cliente lanza
`DownloadClientException("Error response received from SABnzbd: API Key Incorrect")`
(`SabnzbdProxy.cs:244`), que `TestAuthentication` reconoce (`Sabnzbd.cs:424`).
Usa `"API Key Required"` cuando no se haya proporcionado ninguna clave (`Sabnzbd.cs:429`). Cualquier otra cadena de `error` se muestra tal cual, pero no se clasifica.

---

## 9. Lista de verificación de implementación (12 puntos) {#9-implementation-checklist-12-points}

1. Una sola ruta: `GET|POST {UrlBase}/api`, se despacha según `mode`. **Siempre HTTP 200, siempre JSON.**
2. Implementa `version`, `get_config`, `queue` (lectura + `name=delete`), `history` (lectura + `name=delete`), `addfile` y `fullstatus`. Opcionalmente `retry` (código muerto por ahora). `get_cats` nunca se llama.
3. Acepta autenticación con `apikey=` **o** con `ma_username=`+`ma_password=`. Rechaza con 200 + `{"status":false,"error":"API Key Incorrect"}` / `"API Key Required"`; nunca un 401/403.
4. Respeta `category=` en `queue`/`history` (los clientes también filtran del lado del cliente por coincidencia exacta de cadena, `Sabnzbd.cs:190`).
5. Los tamaños de `queue` van en **MB** (`mb`, `mbleft`); los de `history` van en **BYTES** (`bytes`). Nunca los mezcles. Queue usa `cat`, history usa `category`.
6. `timeleft` siempre es `h:m:s` o `d:h:m:s`, nunca vacío ni una cadena vacía en lugar de ausente. En ningún sitio se analiza un campo de fecha, así que los campos epoch son de formato libre.
7. Los valores de `status` deben venir de la lista `SabnzbdDownloadStatus` de 16 miembros, con mayúsculas y minúsculas exactas (un nombre desconocido lanza una excepción y tumba toda la llamada a queue/history). `priority` debe ser un nombre de `SabnzbdPriority` (con mayúsculas y minúsculas exactas) o su entero; **nunca `null`** (NRE en el convertidor).
8. `config.misc` debe ser un objeto; cada categoría debe tener un **`dir` de tipo string no nulo** que no termine en `*`. `categories`/`sorters`/`servers` pueden ser null o estar ausentes; `misc` y `dir` no.
9. Mantén `enable_tv_sorting`, `enable_movie_sorting`, `enable_date_sorting` y `pre_check` todos en `false`, y `history_retention_option: "all"`, para que la prueba de conexión y todas las comprobaciones de estado salgan limpias.
10. `storage` en una entrada Completed del historial = la carpeta del trabajo. Espera que el *arr haga `rm -rf` sobre ella tras una importación correcta (ajustes por defecto), y espera que el archivo multimedia se **mueva** antes fuera de ella. Si el directorio mágico es de solo lectura, el borrado falla en silencio (solo un aviso en el log), pero el *movimiento* del archivo importado debe completarse o la importación fallará por completo (§5.5).
11. No coloques ninguna carpeta raíz de *arr en `/mnt/zurg/__magic__/__all__` ni por encima de ella si quieres que `DownloadClientRootFolderCheck` de Radarr no dé problemas (a Sonarr solo le importa la igualdad exacta). Colócalas al lado del espejo, en `/mnt/zurg/__magic__/tv` y `/mnt/zurg/__magic__/movies`, que no tienen relación con la carpeta de salida ni están por encima ni por debajo de ella.
12. `/mnt/zurg/__magic__/__all__` debe existir como directorio **en el host de Sonarr/Radarr**, no solo donde se ejecuta el emulador, o `RemotePathMappingCheck` dará un error. No hace falta que tenga permisos de escritura.

## Configurar una ventana de finalización más grande {#configuring-a-larger-completion-window}

Ambos clientes usan por defecto `DownloadClientHistoryLimit` con un valor de 60. zurg replica esa ventana cuando guarda en `queue` las descargas completadas que sobran. Si solo subes el límite del cliente, algunos trabajos aparecerían tanto en queue como en historial, y en ese caso queue gana.

Si tienes un backlog grande, pon `sabnzbd.history_limit` en zurg y `DownloadClientHistoryLimit` en los clientes con el mismo valor, por ejemplo 500. Así se muestran más trabajos completados y fallidos en cada consulta. Si varios clientes usan valores distintos, deja zurg con el límite de cliente más pequeño. Esta opción avanzada del cliente no aparece en el recurso de configuración de cliente de descarga de la API de Sonarr v4, así que haz una copia de seguridad y detén el cliente antes de editar su configuración guardada.

```yaml
sabnzbd:
  enabled: true
  history_limit: 500
```

El valor por defecto sigue siendo 60; los valores cero y negativos usan ese valor por defecto. Una petición de diagnóstico de historial con otro límite nunca cambia la ventana configurada. Las advertencias que el cliente no puede resolver siguen necesitando revisión; una ventana más grande permite que otros trabajos lleguen a la importación mientras esas advertencias ocupan espacios en el historial.

La comprobación de disponibilidad previa a la finalización toma muestras de los primeros dieciséis artículos y del último artículo de cada archivo de contenido. Así se detecta un artículo que falta en la cabecera del archivo multimedia, algo que el antiguo centinela del primer artículo no detectaba. Descarga el primer artículo de cada archivo de contenido, lo que verifica la identidad del artículo y que el cuerpo sigue disponible en el servidor (un proveedor puede responder a STAT para un artículo cuyo cuerpo ha retirado), además de artículos elegidos al azar hasta dieciséis cuerpos para un release con menos archivos que eso, con un máximo de sesenta y cuatro cuerpos en total. Un cuerpo que ya esté en la caché de artículos no se vuelve a descargar. STAT cubre el resto de la muestra. No valida todos los artículos ni demuestra que el medio se pueda decodificar.

Las peticiones STAT se agrupan por archivo, así que la muestra usa una sola reserva del pool en lugar de diecisiete, sin subir el límite de conexiones de tu cuenta. Si un lote no sirve, se recurre a STAT individuales.
Los fallos del servidor dejan el trabajo en cola para reintentarlo; los artículos que se confirma que faltan generan una descarga fallida antes de la primera notificación de finalización.
