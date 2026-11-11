# API de qBittorrent (contrato Web API) tal como lo usan Sonarr y Radarr (develop) {#qbittorrent-web-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Fuente de verdad: archivos descargados de `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...` y de `qbittorrent/qBittorrent/master` el **2026-08-27**. Todos los números de línea que aparecen abajo se leyeron de esos archivos.

Este documento es la contraparte para torrents de [sabnzbd-client-contract.md](sabnzbd-client-contract.md). Ese documento explica por qué `internal/sabnzbd` responde con las formas que responde; este es la especificación que un shim de qBittorrent tiene que cumplir *antes* de escribirse, para que una descarga, una consulta de estado, una importación **como movimiento** y la limpieza posterior a la importación funcionen en ambos clientes. Cuando los dos clientes comparten mecanismos (la capa HTTP, el serializador JSON, `DiskTransferService`, las comprobaciones de salud), este documento cita las mismas líneas y remite a ellas en lugar de repetir el análisis.

Salvo que una sección diga lo contrario, **los archivos de qBittorrent de los dos repositorios son idénticos excepto por el cambio de nombre `Tv*` → `Movie*`**, y:

| Archivo | Números de línea |
|---|---|
| `QBittorrent.cs` (746 líneas en ambos) | **coinciden línea por línea** |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **byte a byte idénticos**, coinciden línea por línea |
| `QBittorrentSettings.cs` (91 líneas en ambos) | coinciden línea por línea |
| `QBittorrentProxyV2.cs`, `QBittorrentProxyV1.cs` | Sonarr tiene una línea en blanco en la 13 que Radarr no tiene (verificado: en Sonarr `:12` es el comentario `// API https://…`, `:13` está en blanco y `:14` es `public class QBittorrentProxyV2`; en Radarr la declaración de la clase está en `:13`). **Línea N de Sonarr = línea N−1 de Radarr para N ≥ 14.** |
| `QBittorrentProxySelector.cs` | igual, desde la línea 3 |
| `QBittorrentFixture.cs` | reordenado, no desplazado; se cita por repositorio |

Las rutas son `src/NzbDrone.Core/Download/Clients/QBittorrent/...` en ambos. Las citas de abajo son números de línea de **Sonarr** salvo que se indique otra cosa. El diff completo está en §9.

Nada de lo que aparece aquí es una suposición sobre qBittorrent en sí: cada afirmación describe lo que hace el *cliente*. Cuando una afirmación se refiere al comportamiento de qBittorrent, cita `qbittorrent/qBittorrent` en master; cuando se refiere a la semántica de ejecución de .NET o Newtonsoft, lo dice explícitamente.

---

## 0. Reglas a nivel de transporte (estas muerden primero) {#0-transport-level-rules-these-bite-first}

### 0.1 El cliente elige v1 o v2 antes de hacer cualquier otra cosa {#01-the-client-picks-v1-or-v2-before-it-does-anything-else}

`QBittorrentProxySelector.FetchProxy` (`QBittorrentProxySelector.cs:80-95`):

```csharp
if (_proxyV2.IsApiSupported(settings)) { return Tuple.Create(_proxyV2, _proxyV2.GetApiVersion(settings)); }
if (_proxyV1.IsApiSupported(settings)) { return Tuple.Create(_proxyV1, _proxyV1.GetApiVersion(settings)); }
throw new DownloadClientException("Unable to determine qBittorrent API version");
```

`QBittorrentProxyV2.IsApiSupported` (`QBittorrentProxyV2.cs:28-70`) hace una **sin autenticar**
`GET /api/v2/app/webapiVersion` con `SuppressHttpError = true`, y decide así:

| Respuesta | Resultado |
|---|---|
| `404` | no es v2 → pasa a v1 |
| `403` | **v2 soportado** (`:44-47`); esta es la respuesta de "todavía no has iniciado sesión" |
| `401` | `DownloadClientException("Failed to connect to qBittorrent. Check your settings and qBittorrent configuration.")` (`:49-52`) |
| cualquier otro `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` (`:54-57`) |
| `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to qBittorrent, certificate validation failed.")` (`:63-66`) |
| `200` | v2 soportado |

`QBittorrentProxyV1.IsApiSupported` (`QBittorrentProxyV1.cs:27-59`) hace lo mismo contra
`GET /version/api`. Ojo: **no lleva `/api/v2` delante**, y el 401 *no* tiene un tratamiento especial ahí.

La pareja `(proxy, version)` se guarda en caché durante **10 minutos**, con la clave `{Host}_{Port}`
(`QBittorrentProxySelector.cs:68-78`). `GetProxy(settings, force: true)` la elimina; la prueba de conexión
hace exactamente eso (`QBittorrent.cs:435`, `:519`), y el fixture lo comprueba
(Sonarr `QBittorrentFixture.cs:986-998`, Radarr `:984-996`).

**Un shim debería responder a `/api/v2/app/webapiVersion` y nunca exponer las rutas v1.** v1 es la
API anterior a la 4.1 (`/version/api`, `/query/torrents`, `/command/download`, …); es peso muerto para una
implementación nueva, y ni siquiera puede satisfacer la ruta de importación, porque `GetLabels` lanza
`NotSupportedException("qBittorrent api v1 does not support getting all torrent categories")`
(`QBittorrentProxyV1.cs:236-239`) y `SetTorrentSeedingConfiguration` no hace nada (`:241-244`).
El resto de este documento es solo de la API v2; §1.17 incluye el mapa de rutas v1 por completitud.

### 0.2 Forma de la URL {#02-url-shape}

`QBittorrentProxyV2.BuildRequest` (`QBittorrentProxyV2.cs:341-359`):

```csharp
var requestBuilder = new HttpRequestBuilder(settings.UseSsl, settings.Host, settings.Port, settings.UrlBase)
{
    LogResponseContent = true,
    StoreRequestCookie = false
};
```

- URL base: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-65`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; a `UrlBase` se le añade un `/` al principio si no lo tiene.
- `Resource("/api/v2/…")` (`HttpRequestBuilder.cs:244-256`) quita el `/` inicial y añade el resto,
  así que la URL completa es `{scheme}://{host}:{port}{urlBase}/api/v2/{group}/{method}`.
- **Sin cabecera `Accept`.** `BuildRequest` nunca llama a `.Accept(...)`, y el constructor de `HttpRequest`
  solo define `Headers.Accept` cuando `httpAccept != null`
  (`src/NzbDrone.Common/Http/HttpRequest.cs:14,30-32`). No condiciones nada en `Accept`.
- `StoreRequestCookie = false`: el almacén de cookies lo gestiona el proxy, no la capa HTTP.

### 0.3 GET con query vs POST con formulario — y cuándo el formulario pasa a multipart {#03-get-with-query-vs-post-with-form--and-when-the-form-becomes-multipart}

Las llamadas de solo lectura usan `AddQueryParam` (`HttpRequestBuilder.cs:306-317`) en un GET. Las llamadas que modifican datos usan `.Post()` más `AddFormParameter` / `AddFormUpload`.

`ApplyFormData` (`HttpRequestBuilder.cs:150-242`) elige la codificación:

```csharp
var shouldSendAsMultipart = FormData.Any(v => v.ContentType != null || v.FileName != null || v.ContentData.Length > 1024);
```

- Cualquier `AddFormUpload` (que establece `FileName` y `ContentType`) fuerza **`multipart/form-data`** (`:379-395`, `:220`).
- **Cualquier valor de formulario de más de 1024 bytes también fuerza multipart** (`:162`). Un URI magnet con una lista larga de trackers supera ese límite, así que `POST /api/v2/torrents/add` llega como `application/x-www-form-urlencoded` *o* como `multipart/form-data`, según el magnet. **Un shim tiene que poder leer ambos en esa ruta.**
- En los demás casos: `application/x-www-form-urlencoded`, con los valores escapados mediante `Uri.EscapeDataString(Encoding.UTF8.GetString(...))` (`:230`).

El escritor de multipart está hecho a mano (`:164-227`) y escribe `Content-Disposition: form-data; name="…"` (más `; filename="…"` y una línea `Content-Type:` en las subidas), una línea en blanco, los bytes sin procesar y después `\r\n`. El boundary es `-----------------------------{ticks:x14}` (`:166`).

**El formato de los booleanos es una trampa.** `AddFormParameter` guarda `Convert.ToString(value, CultureInfo.InvariantCulture)` (`HttpRequestBuilder.cs:373`), y `Convert.ToString(bool)` de .NET devuelve **`"True"` / `"False"`, con mayúscula inicial**. Así que `request.AddFormParameter("stopped", false)` (`QBittorrentProxyV2.cs:258`) envía `stopped=False` por la red, no `stopped=false`. qBittorrent real no se queja porque `Utils::String::parseBool` (`src/base/utils/string.cpp:108-116`) compara sin distinguir mayúsculas. **Un shim tiene que aceptar tanto `True`/`False` como `true`/`false`.** Donde el cliente escribe la cadena a mano, va en minúsculas: `deleteFiles` es `"true"` (`QBittorrentProxyV2.cs:198`) y el `value` de `setForceStart` es `"true"`/`"false"` (`:337`), así que las dos formas aparecen de verdad.

Los números pasan por la misma ruta con cultura invariante, así que `ratioLimit=1.5` siempre usa `.` como separador decimal (`QBittorrentProxyV2.cs:234`, `HttpRequestBuilder.cs:373`).

### 0.4 Autenticación — tres capas, todas pueden estar activas a la vez {#04-authentication--three-layers-all-of-which-can-be-live-at-once}

`BuildRequest` (`QBittorrentProxyV2.cs:349-356`):

```csharp
if (settings.ApiKey.IsNotNullOrWhiteSpace())
    requestBuilder.Headers["Authorization"] = $"Bearer {settings.ApiKey}";
else if (settings.Username.IsNotNullOrWhiteSpace() || settings.Password.IsNotNullOrWhiteSpace())
    requestBuilder.NetworkCredential = new BasicNetworkCredential(settings.Username, settings.Password);
```

1. **Clave de API** → `Authorization: Bearer <key>` en cada solicitud, y `ProcessRequest` toma un atajo que nunca inicia sesión (`:371-395`). `QBittorrentSettingsValidator` prohíbe username/password junto con una clave (`QBittorrentSettings.cs:16-21`).
2. **Usuario/contraseña** → `BasicNetworkCredential`, que `ManagedHttpDispatcher` convierte en un header **preventivo** `Authorization: Basic base64(user:pass)` en *cada* solicitud, incluida la propia `auth/login` (`src/NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:81-89`, comentario: "Establecer el header manualmente para evitar la respuesta de desafío inicial").
3. **Sesión por cookie** → `AuthenticateClient` (`QBittorrentProxyV2.cs:430-494`).

`AuthenticateClient`, exactamente:

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

Consecuencias para un shim:

- `POST /api/v2/auth/login`, cuerpo `username=…&password=…`, `application/x-www-form-urlencoded`.
- Responde **HTTP 200** con el cuerpo exactamente `Ok.` y un header `Set-Cookie: SID=…`, la forma que usa qBittorrent real (wiki, *Login*: "Si tiene éxito, la respuesta contendrá una cookie con tu SID").
- **Un cuerpo vacío también se acepta** (`:479` hace un atajo con `IsNotNullOrWhiteSpace`). Cualquier otra cosa (`"Fails."`, `"ok"`, JSON) es un fallo de autenticación. El proxy v1 es más estricto y exige exactamente `Ok.` (`QBittorrentProxyV1.cs:371`).
- Ante un error HTTP en `auth/login`: 401 o 403 → `DownloadClientAuthenticationException`; cualquier otro → `DownloadClientException` (`:463-473`). Una `WebException` → `DownloadClientUnavailableException`.
- La cookie se guarda en caché por `{baseUrl}:{user}:{pass}` durante la vida de la entrada de caché del proceso, y solo se renueva cuando una solicitud devuelve 403 (§0.5).
- **`Referer` y `Origin` nunca se envían.** La wiki indica a los consumidores de la API que los configuren ("Nota: Establece el header `Referer` u `Origin` exactamente con el mismo dominio y puerto que se usan en el header `Host` de la consulta HTTP"), pero Sonarr no lo hace. Un shim no debe exigirlos.
- Si **no hay credenciales configuradas**, `AuthenticateClient` retorna de inmediato y no se envía nada: ni login, ni cookie, ni `Authorization`. Un shim sin autenticación funciona.

### 0.5 Qué códigos HTTP se tratan como error {#05-which-http-statuses-are-treated-as-errors}

`HttpClient.Execute` (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`) lanza una excepción cuando `response.HasHttpError` es verdadero, es decir, `(int)StatusCode >= 400` (`src/NzbDrone.Common/Http/HttpResponse.cs:54`), a menos que esté activo `SuppressHttpError` o el estado esté en `SuppressHttpErrorStatusCodes`. El 429 se convierte en `TooManyRequestsException` (`:115`); cualquier otro error pasa a ser `HttpException` (`:119`).

`QBittorrentProxyV2.ProcessRequest` (`:369-428`) envuelve esa excepción. Hay dos caminos distintos:

**Camino de la API key** (`:371-395`):

| Estado | Resultado |
|---|---|
| 401, 403 | `DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.")` |
| cualquier otro `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` |
| cualquier otra excepción | `DownloadClientException("Failed to connect to qBittorrent, please check your settings.")` |

**Camino de la cookie** (`:397-427`):

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

- **El 403 significa "la sesión caducó, vuelve a iniciar sesión"**. Se suprime una vez, el cliente vuelve a iniciar sesión y reintenta la petición. Es el mismo bucle que produce la caducidad de sesión de qBittorrent, y un shim puede usarlo de la misma forma.
- La **petición de reintento se reconstruye desde el builder**, que no lleva `SuppressHttpErrorStatusCodes`. Ese campo se puso en la *petición* en `:401`, no en el builder. Así que un segundo 403 lanza `HttpException` y termina como `DownloadClientException("Failed to connect to qBittorrent, check your settings.")`, **no** como un fallo de autenticación. Un shim que responda 403 siempre dará un error de conexión confuso en la UI, no "Authentication Failure".
- Si no hay credenciales configuradas, el intento de nuevo login en `:411` lanza `DownloadClientAuthenticationException` directamente (`:434-437`).

**Cada llamada correcta tiene que devolver HTTP 200 con el cuerpo exacto que espera el cliente.** En esta API no hay ningún sobre de error en JSON. A diferencia de SAB, aquí los errores son códigos de estado HTTP.

### 0.6 Configuración del deserializador {#06-deserializer-settings}

Todas las cargas útiles de qBittorrent pasan por `NzbDrone.Common.Serializer.Json` (`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`), que usa **Newtonsoft**, la misma instancia que usa el cliente SAB. Por eso [sabnzbd-client-contract.md §0.3](sabnzbd-client-contract.md) se aplica tal cual:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Esto significa, en concreto, para los modelos de qBittorrent:

| Miembro del modelo | Se enlaza a | Por qué |
|---|---|---|
| `QBittorrentTorrent.Hash/Name/Size/Progress/Eta/State/Label/Category/Ratio` | `hash`, `name`, `size`, `progress`, `eta`, `state`, `label`, `category`, `ratio` | resolvedor camelCase; Newtonsoft también compara sin distinguir mayúsculas |
| `SavePath`, `ContentPath`, `RatioLimit`, `SeedingTime`, `SeedingTimeLimit`, `InactiveSeedingTimeLimit`, `LastActivity` | `save_path`, `content_path`, `ratio_limit`, `seeding_time`, `seeding_time_limit`, `inactive_seeding_time_limit`, `last_activity` | `[JsonProperty]` explícito (`QBittorrentTorrent.cs:24-45`) |
| `QBittorrentLabel.Name/SavePath` | `name`, `savePath` | **sin** `[JsonProperty]`, usa el resolvedor camelCase. `torrents/categories` de qBittorrent sí usa camelCase aquí, a diferencia de todo lo demás |
| `QBittorrentPreferences.*` | todos con `[JsonProperty]` explícito en snake_case (`QBittorrentPreferences.cs:16-44`) | |
| `QBittorrentMaxRatioAction` | `max_ratio_act` | no tiene conversor por propiedad, así que se aplica el `StringEnumConverter` global. `AllowIntegerValues` es true por defecto, así que **envía el entero**, como hace qBittorrent real. Una cadena tendría que ir en camelCase (`"pause"`, `"remove"`) y un nombre desconocido lanza una excepción |

`NullValueHandling.Ignore` también se aplica al **leer**: un `null` en JSON deja el miembro con el valor de su constructor. Junto con los valores por defecto declarados en los modelos, un campo **ausente o null** no es lo mismo que un cero:

| Campo | Valor por defecto si falta o es null | Referencia |
|---|---|---|
| `ratio_limit` | `-2f` | `QBittorrentTorrent.cs:33` |
| `seeding_time_limit` | `-2` | `:39` |
| `inactive_seeding_time_limit` | `-2` | `:42` |
| `seeding_time` | `null` (`long?`) | `:36` |
| `queueing_enabled` | **`true`** | `QBittorrentPreferences.cs:41` |
| el resto | valor por defecto de CLR (`0`, `false`, `null`) | |

`Eta` es un `System.Numerics.BigInteger` (`QBittorrentTorrent.cs:17`, con el comentario "QBit contains a bug exceeding ulong limits"). El fixture de Sonarr confirma que `18446744073709335000` se puede parsear (Sonarr `QBittorrentFixture.cs:974-984`, Radarr `:973-982`).

`Json.Deserialize<T>` vuelve a lanzar `JsonReaderException` con un mensaje más claro (`Json.cs:39-50`). Ninguna de las llamadas proxy de qBittorrent usa `TryDeserialize`, así que **un cuerpo mal formado o con una forma incorrecta lanza una excepción desde el proxy** y se convierte en una excepción no controlada en el punto de llamada. En `GetItems()`, eso tumba todo el sondeo.

### 0.7 Todos los `version >=` en un solo lugar {#07-every-version--gate-in-one-place}

`ProxyApiVersion` es `_proxySelector.GetApiVersion(Settings)` (`QBittorrent.cs:50`), es decir, la `app/webapiVersion` guardada en caché. Los filtros:

| Filtro | Dónde | Efecto por debajo del umbral |
|---|---|---|
| `>= 1.5` | `QBittorrent.cs:436` | La prueba falla: "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| `>= 1.6` | `:445` | La prueba falla si hay una categoría configurada: "Category is not supported" |
| `>= 2.0` | `:379` (`GetStatus`), `:520` (`TestCategory`) | No se lee el `savePath` de la categoría, y las categorías no se comprueban ni se crean |
| `>= 2.6.1` | `:314` | `OutputPath` **no** se toma de `content_path`; `GetImportItem` recorre `torrents/files` en su lugar (§4.2) |
| `>= 2.8.1` | `:79`, `:136` | los límites de compartición no pueden ir en `torrents/add`; se aplican después con `torrents/setShareLimits` |
| `>= 2.11.0` | `QBittorrentProxyV2.cs:253` | `torrents/add` envía `paused=` en lugar de `stopped=` |

`Version.Parse` (`QBittorrentProxyV2.cs:75`) necesita **al menos `major.minor`**. Un simple `"2"` lanza `FormatException`, y esa excepción se produce fuera de todos los `try` del proxy, así que se escapa de `GetApiVersion` por completo. Reporta algo como `2.11.2`.

**Valor recomendado para un shim: `2.11.2`.** Supera todos los filtros, pone `content_path` en la ruta de `torrents/info` (la única ruta de importación sensata) y elige la forma `stopped=` de qBittorrent 5.x al añadir.

## 1. Cada endpoint, en el orden en que los llama el cliente {#1-every-endpoint-in-the-order-the-client-calls-them}

Interfaz: `IQBittorrentProxy` (`QBittorrentProxySelector.cs:9-30`). Implementación:
`QBittorrentProxyV2`. Cada punto de llamada en `QBittorrent.cs` está listado en `:49-741`.

### 1.1 `GET /api/v2/app/webapiVersion` — `GetApiVersion` (`QBittorrentProxyV2.cs:72-78`)

Solicitud: sin parámetros. Se envía primero sin autenticar (como sonda del proxy, §0.1) y luego autenticada.

Respuesta: **texto plano**, una cadena de versión que se analiza con `Version.Parse`. No es JSON, sin comillas.

Llamado por: la sonda del proxy (`:31`), `GetItems` (`QBittorrent.cs:220`), `GetStatus` (`:374`), `TestConnection` (`:435`), `TestCategory` (`:519`), y, el que es fácil de pasar por alto, `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:253`). Esto significa que **cada `torrents/add` va precedido de su propia ida y vuelta a `app/webapiVersion`** siempre que el estado inicial sea Start o Stop (es decir, siempre, salvo que el usuario haya elegido Force Start).

### 1.2 `GET /api/v2/app/version` — `GetVersion` (`QBittorrentProxyV2.cs:80-87`)

Respuesta: texto plano, sin la `v` al principio (`:83`). Comentario: `// eg "4.2alpha"`.

**Nunca se llama.** Está en la interfaz (`QBittorrentProxySelector.cs:13`) sin ningún llamador en
`QBittorrent.cs` (verificado contra cada referencia a `Proxy.` y `_proxySelector.`, `:49-741`). Implémentalo
igualmente: no cuesta nada, y una persona que toque el shim va a buscarlo.

(Una traducción anterior fue rechazada: los fragmentos de código no coincidían. Mantén la estructura exactamente.)

### 1.3 `POST /api/v2/auth/login`

Cubierto en §0.4. Formulario: `username`, `password`. Respuesta `200` + `Ok.` + `Set-Cookie: SID=…`.

### 1.4 `GET /api/v2/app/preferences` — `GetConfig` (`QBittorrentProxyV2.cs:89-95`)

Petición: sin parámetros. Respuesta: un objeto JSON, deserializado en `QBittorrentPreferences`.

**Cada clave que lee el cliente** (`QBittorrentPreferences.cs:14-45`). Nada más del cuerpo se revisa, y las claves extra se ignoran:

| Clave JSON | C# | Tipo | Leído por |
|---|---|---|---|
| `save_path` | `SavePath` | `string` | `GetStatus` → `OutputRootFolders` (`QBittorrent.cs:377`) |
| `max_ratio_enabled` | `MaxRatioEnabled` | `bool` | `HasReachedSeedLimit` (`:639`), `RemovesCompletedDownloads` (`:415`) |
| `max_ratio` | `MaxRatio` | `float` | `HasReachedSeedLimit` (`:641`) |
| `max_seeding_time_enabled` | `MaxSeedingTimeEnabled` | `bool` | `HasReachedSeedingTimeLimit` (`:663`), `RemovesCompletedDownloads` (`:415`) |
| `max_seeding_time` | `MaxSeedingTime` | `long`, **minutos** | `:665`, `:415` |
| `max_inactive_seeding_time_enabled` | `MaxInactiveSeedingTimeEnabled` | `bool` | `HasReachedInactiveSeedingTimeLimit` (`:727`) |
| `max_inactive_seeding_time` | `MaxInactiveSeedingTime` | `long`, **minutos** | `:729` |
| `max_ratio_act` | `MaxRatioAction` | enum como entero: `Pause=0, Remove=1, EnableSuperSeeding=2, DeleteFiles=3` (`QBittorrentPreferences.cs:5-11`) | `RemovesCompletedDownloads` (`:415`) |
| `queueing_enabled` | `QueueingEnabled` | `bool`, **por defecto `true`** | `TestPrioritySupport` (`:572`) |
| `dht` | `DhtEnabled` | `bool` | `AddFromMagnetLink` (`:73`), la rama `metaDL` (`:288`) |

Llamado por: `AddFromMagnetLink` (`:73`), `GetItems` (`:221`), `GetStatus` (`:375`), `TestConnection`
(`:467`), `TestPrioritySupport` (`:570`). **No** se guarda en caché, así que se pide en cada consulta.

`RemovesCompletedDownloads` (`QBittorrent.cs:412-416`) es la marca derivada:

```csharp
var minimumRetention = 60 * 24 * 14; // 14 days in minutes
return (config.MaxRatioEnabled || (config.MaxSeedingTimeEnabled && config.MaxSeedingTime < minimumRetention))
    && (config.MaxRatioAction == QBittorrentMaxRatioAction.Remove || config.MaxRatioAction == QBittorrentMaxRatioAction.DeleteFiles);
```

Alimenta tanto la prueba de conexión (`:468`) como la comprobación de estado
`DownloadClientRemovesCompletedDownloadsCheck` (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:44-53`). Con
`max_ratio_enabled: false` y `max_seeding_time_enabled: false` es false sin importar lo que diga `max_ratio_act`, pero envía `max_ratio_act: 0` de todos modos.

### 1.5 `GET /api/v2/torrents/categories` — `GetLabels` (`QBittorrentProxyV2.cs:221-225`)

**Solicitud:** sin parámetros.

**Respuesta:** un **objeto** JSON, `{"<name>": {"name": "...", "savePath": "..."}}`, que se deserializa en `Dictionary<string, QBittorrentLabel>`. Ojo con **`savePath` en camelCase**, según §0.6 y el ejemplo *Get all categories* de la wiki. Un array aquí lanza una excepción.

Fíjate en dos cosas:

1. `TestCategory` (`QBittorrent.cs:525-553`): solo la pertenencia de la clave (§6.3).
2. `GetStatus` (`:379-402`): el `savePath` de la categoría configurada se convierte en la carpeta raíz de salida del cliente de descargas:

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

Un `savePath` **relativo** se añade al `save_path` global; uno con raíz lo reemplaza. Un `savePath` que empieza por `//` se convierte en una ruta UNC con barras invertidas. El fixture de Sonarr fija `"//server/store/downloads"` → `\\server\store\downloads` (Sonarr `QBittorrentFixture.cs:563-589`, Radarr `:562-588`). **Nunca generes un `//` al principio.**

La respuesta más simple y correcta es `"savePath": ""`, que deja la carpeta raíz en el `save_path` global.

### 1.6 `POST /api/v2/torrents/createCategory` — `AddLabel` (`QBittorrentProxyV2.cs:213-219`)

Formato: `category=<name>`. **`savePath` no se envía**: el cliente nunca establece una ruta de guardado para la categoría.
El cuerpo de la respuesta se ignora; solo importa que el estado no sea de error.

Se llama únicamente desde `TestCategory` (`QBittorrent.cs:529`, `:543`), cuando la categoría no existe.
`torrents/editCategory` y `torrents/removeCategories` **nunca se llaman**.

### 1.7 `POST /api/v2/torrents/add` — `AddTorrentFromUrl` / `AddTorrentFromFile`

`AddTorrentFromUrl` (`QBittorrentProxyV2.cs:146-166`): campo de formulario **`urls`** = la URI magnet.
`AddTorrentFromFile` (`:168-188`): subida de formulario **`torrents`**, con el nombre de archivo
`{CleanFileName(release title)}.torrent` (`TorrentClientBase.cs:199`) y `Content-Type: application/octet-stream` (`HttpRequestBuilder.cs:379`).

Ambos añaden después `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:243-284`):

| Campo de formulario | Valor | Condición | Línea |
|---|---|---|---|
| `category` | `Settings.TvCategory` / `MovieCategory` | categoría no vacía | `:245-248` |
| `stopped` (webapi `>= 2.11.0`) o `paused` (versiones anteriores) | `False` para Start, `True` para Stop | `InitialState` es Start o Stop; **Force Start no envía ninguno de los dos** | `:251-264` |
| `sequentialDownload` | `True` | ajuste `SequentialOrder` activado | `:266-269` |
| `firstLastPiecePrio` | `True` | ajuste `FirstAndLast` activado | `:271-274` |
| `contentLayout` | `"Original"` o `"Subfolder"` | ajuste `ContentLayout` es Original o Subfolder; **Default no envía nada** | `:276-283` |

y, cuando hay límites de compartición configurados *y* webapi `>= 2.8.1` (`QBittorrent.cs:79`, `:136`), se llama a
`AddTorrentSeedingFormParameters(request, seedConfiguration)` (`QBittorrentProxyV2.cs:227-241`):

| Campo de formulario | Valor | Condición |
|---|---|---|
| `ratioLimit` | `seedConfiguration.Ratio` o `-2` | solo cuando no es `-2` (`:232`) |
| `seedingTimeLimit` | `seedConfiguration.SeedTime.TotalMinutes` o `-2` | solo cuando no es `-2` (`:237`) |

**Todo lo demás que la wiki documenta para `torrents/add` nunca se envía**: ni `savepath`, ni `cookie`, ni
`tags`, ni `skip_checking`, ni `root_folder`, ni `rename`, ni `upLimit`, ni `dlLimit`, ni
`autoTMM`. Al añadir no existe ningún parámetro `priority`: la prioridad en la cola se cambia con una llamada aparte, `topPrio` (§1.10).

Manejo de la respuesta (`:159-165`, `:181-187`):

```csharp
var result = ProcessRequest(request, settings);
// Note: Older qbit versions returned nothing, so we can't do != "Ok." here.
if (result == "Fails.") { throw new DownloadClientException("Download client failed to add torrent by url"); }
```

Así que: **un 200 con cualquier cuerpo que no sea exactamente `Fails.` es un éxito.** `Ok.` es la respuesta habitual.
Un HTTP 415 (lo que la wiki llama "torrent file is not valid") se convierte en un `DownloadClientException` mediante `:389`.

**El id de descarga no sale de esta llamada.** Se calcula en el cliente, antes de la petición:

- magnet → `MagnetLink.Parse(magnetUrl).InfoHash.ToHex()` (`TorrentClientBase.cs:224`)
- `.torrent` → `_torrentFileInfoReader.GetHashFromTorrentFile(torrentFile)` (`:200`)

Y `AddFromMagnetLink` / `AddFromTorrentFile` devuelven ese mismo `hash` sin cambios (`QBittorrent.cs:130`, `:187`).
**El shim tiene que asociar el torrent exactamente a ese infohash**, o Sonarr pierde la pista del grab.
`TorrentClientBase.cs:206-212` y `:238-244` solo registran una línea de Debug al respecto.
En los magnets, la precondición de DHT se comprueba primero:

```csharp
if (!Proxy.GetConfig(Settings).DhtEnabled && !magnetLink.Contains("&tr="))
    throw new NotSupportedException("Magnet Links without trackers not supported if DHT is disabled");   // :73-76
```

Si no hay un `.torrent` de respaldo, el llamador lo convierte en `ReleaseDownloadException("Magnet not supported by download client…")` (`TorrentClientBase.cs:111-119`). **Informa `dht: true`.**

Tras añadirlo, `WaitForTorrent` (`QBittorrent.cs:190-214`) consulta `IsTorrentLoaded` **10 veces con una pausa de 100 ms**, pero solo cuando hay trabajo pendiente: límites de compartición tras añadir, prioridad superior o force start (`:86`, `:143`). Su mensaje de error dice "within 500 ms", pero el bucle en realidad es de 10 × 100 ms. En cualquier caso, cuando se agota el tiempo devuelve el hash (`:212-213`).

### 1.7a Cuánto espera el cliente a `torrents/add` — **100 segundos**, medido el 2026-08-30 {#17a-how-long-the-client-waits-for-torrentsadd--100-seconds-measured-2026-08-30}

Leído de `Sonarr/Sonarr@32a5d492` y `Radarr/Radarr@40bb746c` (ambos `develop`) el 2026-08-30.
Esto limita todo lo que un shim hace de forma síncrona dentro de la llamada add, así que merece citarse
en lugar de asumirse.

Nada en la ruta de qBittorrent establece un timeout, así que el valor pasa por cuatro capas hasta quedar fijo en 100 s:

| Paso | Sonarr `path:line` | Radarr `path:line` | Qué hace |
|---|---|---|---|
| la llamada add | `QBittorrentProxyV2.cs:146-150`, `:168-172` | `:145-149`, `:167-171` | construye la petición, no establece timeout |
| el builder | `NzbDrone.Common/Http/HttpRequestBuilder.cs:104-116` | mismo archivo `:104-116` | `Apply()` no tiene ninguna línea `RequestTimeout`, y la clase no tiene esa propiedad |
| el valor por defecto del campo | `NzbDrone.Common/Http/HttpRequest.cs:52` | `:54` | la auto-propiedad nunca se asigna en el constructor, así que es `TimeSpan.Zero` |
| el dispatcher | `NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:70-79` | `:68-77` | `Zero` se convierte en `cts.CancelAfter(TimeSpan.FromSeconds(100))` |

```csharp
using var cts = new CancellationTokenSource();
if (request.RequestTimeout != TimeSpan.Zero) { cts.CancelAfter(request.RequestTimeout); }
else { /* The default for System.Net.Http.HttpClient */ cts.CancelAfter(TimeSpan.FromSeconds(100)); }
```

`RequestTimeout` y `Timeout` no aparecen en ningún lugar de
`src/NzbDrone.Core/Download/Clients/QBittorrent/` en ninguno de los dos repos, y `HttpRequestBuilder` no
expone forma de establecer uno, así que un shim no puede obtener más tiempo mediante configuración.

Se deducen cinco cosas.

- **Los 100 s son el token de cancelación propio de Sonarr, no el temporizador de .NET.** El handler
  subyacente se crea con `Timeout = Timeout.InfiniteTimeSpan` (`ManagedHttpDispatcher.cs:183` en Sonarr, `:180` en Radarr),
  así que el token es el único límite. Se pasa tanto a `SendAsync` como a `ReadAsByteArrayAsync` (`:115`,
  `:127`), lo que significa que cubre la conexión, el cuerpo de la petición, las cabeceras de respuesta y el cuerpo de la respuesta.
- **Un timeout se le muestra al usuario como un fallo de conexión.** Al expirar se lanza
  `new WebException("Http request timed out", …)` (`:142-145`), que `ProcessRequest` envuelve como
  `DownloadClientException("Failed to connect to qBittorrent, please check your settings.", ex)`
  (`QBittorrentProxyV2.cs:424-427`). Un shim que se bloquea más de 100 s parece mal configurado
  en lugar de lento, y el *arr nunca se entera de que el add seguía en curso.
- **No hay un timeout de conexión aparte ni un presupuesto mayor para una subida multipart.**
  `SocketsHttpHandler.ConnectTimeout` nunca se establece. La única excepción es un límite de 2 s en el primer
  intento IPv6 durante la vida del proceso (`ManagedHttpDispatcher.cs:23`, `:288-295`), que cae a IPv4
  dentro de los mismos 100 s. Un archivo `.torrent` se sube completo en un array de bytes (`HttpRequestBuilder.cs:220-221`,
  `ManagedHttpDispatcher.cs:103`) y se envía con el mismo token.
- **Existen 300 s, pero es otra ruta.** `HttpClient.cs:285` establece
  `request.RequestTimeout = TimeSpan.FromSeconds(300)` dentro de `DownloadFileAsync`, que descarga el
  `.torrent` desde el indexador. Nunca llega a una llamada al cliente de descarga.
- **Deluge demuestra que la sobrescritura existe y qBittorrent no la usa.** `DelugeProxy.cs:222` hace
  `requestBuilder.PostProcess += r => r.RequestTimeout = TimeSpan.FromSeconds(15)`. `BuildRequest` de qBittorrent
  no tiene esa línea, que es la prueba directa de que los 100 s se heredan y no se eligen.

**Radarr es idéntico.** Un diff del bloque de timeout (Radarr `:68-78` contra Sonarr `:70-80`)
sale idéntico byte a byte, y la única diferencia en la cadena es que Radarr pasa `ex` donde Sonarr
pasa `ex.InnerException` al `WebException`.

**Consecuencia para el shim.** Cada decisión síncrona tomada dentro de `torrents/add` comparte un único presupuesto de 100 s,
y el *arr no tiene forma de distinguir entre "sigue trabajando" e "inalcanzable". El
plazo por intento multiplicado por el número de proveedores probados, más cualquier ventana de sondeo solo para caché,
debe quedarse bien por debajo de ese límite. Las latencias medidas de los proveedores con las que se construye ese presupuesto están en
[torrent-lifecycle.md](torrent-lifecycle.md).

Una nota al pie para completar. Los 100 s se aplican por llamada al dispatcher, así que cada salto de una cadena de redirecciones automáticas
tiene un presupuesto nuevo (`HttpClient.cs:43` limita la cadena a 5). La estrategia de reintentos en `DownloadClientBase.cs:30-44`
**no** se aplica aquí; solo se usa al descargar el `.torrent` desde el indexador (`TorrentClientBase.cs:142-144`).

### 1.8 `GET /api/v2/torrents/properties?hash=<hash>` — `IsTorrentLoaded` / `GetTorrentProperties`

`IsTorrentLoaded` (`QBittorrentProxyV2.cs:110-126`) lo llama con `LogHttpError = false` y trata **cualquier** excepción como "no cargado".

`GetTorrentProperties` (`:128-135`) deserializa en `QBittorrentTorrentProperties` (`QBittorrentTorrent.cs:48-57`): **tres campos, y solo se usan dos**:

| Clave JSON | C# | Se usa para |
|---|---|---|
| `hash` | `Hash` | se lee, nunca se usa |
| `save_path` | `SavePath` | la ruta de `GetImportItem` antes de 2.6.1 (`QBittorrent.cs:354`) |
| `seeding_time` | `SeedingTime` (`long`, **segundos**) | `FetchTorrentDetails` (`:739-744`) |

**La capitalización del hash aquí no es consistente, y eso importa.** Todas las demás llamadas pasan el hash a minúsculas (`item.DownloadId.ToLower()` en `:335`, `:346`, `:353`; `hash.ToLower()` en `:97`, `:109`, `:121`, `:198`), pero `FetchTorrentDetails` pasa `torrent.Hash` **tal cual** (`:741`), es decir, lo que el shim haya puesto en `torrents/info`. El qBittorrent real devuelve hashes en minúsculas, así que esto nunca le afecta. Los fixtures de Sonarr marcan esta asimetría al simular `GetTorrentProperties("HASH", …)` con el valor en mayúsculas (Sonarr `QBittorrentFixture.cs:669-675`, Radarr `:668-674`). **Devuelve hashes en minúsculas desde `torrents/info`, y compara `?hash=` sin distinguir mayúsculas de minúsculas.**

`FetchTorrentDetails` solo se llama desde `HasReachedSeedingTimeLimit` (`:700`), que solo se ejecuta cuando hay un límite de tiempo de seeding activo. Así que un shim que no declare límites de seeding nunca recibe esta llamada durante el polling. Aun así, sigue siendo necesaria para `IsTorrentLoaded`, que es la comprobación de disponibilidad que se hace después de añadir el torrent: **404 para un hash desconocido, 200 + JSON para uno conocido.**

El resultado se guarda en caché durante 5 minutos por `{Host}{Port}{Hash}` (`:678`, `:689`, `:695`, `:708`), y el fixture comprueba que se obtiene una sola vez, no dos, entre dos polls (Sonarr `QBittorrentFixture.cs:905-920`, Radarr `:904-919`).

### 1.9 `POST /api/v2/torrents/setShareLimits` — `SetTorrentSeedingConfiguration` (`:286-308`)

Formulario: `hashes=<lowercase hash>`, y luego `AddTorrentSeedingFormParameters(request, seedConfiguration, always: true)`
— con `always: true` se envían **siempre** `ratioLimit` y `seedingTimeLimit`, incluso cuando valen `-2`
(`:232`, `:237`). `inactiveSeedingTimeLimit` nunca se envía.

Un **404** se ignora en silencio (`:298-307`, comentario: "setShareLimits was added in api v2.0.1"). Cualquier otro error se propaga, pero el punto de llamada lo captura y registra un aviso (`QBittorrent.cs:95-102`, `:152-159`).

Solo se llega aquí cuando el indexador proporciona una configuración de seed *y* la webapi es `< 2.8.1`. En un shim que reporta `2.11.2`, los límites de compartición viajan en `torrents/add` en su lugar y esta ruta nunca se usa para un grab. Impleméntala como un no-op que devuelve 200.

### 1.10 `POST /api/v2/torrents/topPrio` — `MoveTorrentToTopInQueue` (`:310-330`)

Forma: `hashes=<lowercase hash>`.

Un **409 Conflict** se ignora (`:320-329`, comentario: "qBittorrent rechaza todos los comandos Prio con 409:
Conflict si Options -> BitTorrent -> Torrent Queueing no está activado"). El proxy v1 ignora un **403**
en su lugar (`QBittorrentProxyV1.cs:255-264`). Cualquier otro error se captura y se registra como advertencia en el punto de llamada
(`QBittorrent.cs:107-114`, `:164-171`). El fixture comprueba que un fallo aquí no hace que la captura falle
(Sonarr `QBittorrentFixture.cs:525-542`, Radarr `:524-541`).

Solo se llama cuando el ajuste de prioridad Recent/Older está en `First` (`QBittorrentPriority.First = 1`,
`QBittorrentPriority.cs:5-6`); el valor por defecto es `Last = 0`.

### 1.11 `POST /api/v2/torrents/setForceStart` — `SetForceStart` (`:332-339`)

Forma: `hashes=<lowercase hash>`, `value=true` (la cadena literal en minúsculas, `:337`).

Solo se llama cuando `InitialState` es `ForceStart` (`QBittorrentState.cs:10-11`, `QBittorrent.cs:82`, `:117-127`). Los errores se capturan y se muestran como advertencia (`:123-126`).

### 1.12 `GET /api/v2/torrents/info[?category=<cat>]` — `GetTorrents` (`:97-108`)

**El único parámetro que se envía es `category`, y solo cuando el ajuste no está vacío**
(`:100-103`). Nada de `filter`, `hashes`, `sort`, `reverse`, `limit`, `offset` ni `tag`.
El cliente **no** vuelve a filtrar por categoría después, a diferencia del cliente SAB, que filtra dos veces. Así que un shim que ignore `category` le pasará a Radarr los torrents de Sonarr.

El campo `category` de la respuesta importa por una segunda razón: un torrent que el \*arr **no tiene en su historial de grab** se omite directamente, a menos que lo tenga.
`CompletedDownloadService.Check` (`CompletedDownloadService.cs:84-88`):

```csharp
if (historyItem == null && trackedDownload.DownloadItem.Category.IsNullOrWhiteSpace())
{
    trackedDownload.Warn("Download wasn't grabbed by Sonarr and not in a category, Skipping.");
    return;
}
```

`Category` es `category` si no está vacío; si no, usa `label` (`QBittorrent.cs:231`).

Respuesta: un array JSON. Cada campo que se consume y en qué se convierte:

| Clave JSON | Tipo C# | Unidades | Se convierte en |
|---|---|---|---|
| `hash` | `string` | | `DownloadId = torrent.Hash.ToUpper()` (`QBittorrent.cs:230`) — **en mayúsculas**, y se devuelve en minúsculas en cada llamada posterior |
| `name` | `string` | | `Title = torrent.Name` (`:232`) — mira §7.1 para todo lo que depende de él |
| `size` | `long` | bytes | `TotalSize` (`:233`); también `RemainingSize = (long)(size * (1.0 - progress))` (`:235`) |
| `progress` | `double` | 0..1 | `RemainingSize` (`:235`) |
| `eta` | `BigInteger` | segundos | `RemainingTime` mediante `GetRemainingTime` (`:236`, `:614-628`) |
| `state` | `string` | | `Status`, `Message` y la mitad de la condición `CanMoveFiles` (`:242-312`) — §2 |
| `category` | `string` | | `Category`, preferido (`:231`) |
| `label` | `string` | | `Category`, alternativa cuando `category` está vacío (`:231`). Campo anterior a 3.3.5; qBittorrent 5 no lo envía |
| `ratio` | `float` | | `SeedRatio` (`:237`), `HasReachedSeedLimit` (`:634`, `:641`) |
| `ratio_limit` | `float`, por defecto `-2` | | `HasReachedSeedLimit` (`:632-645`) |
| `seeding_time_limit` | `long`, por defecto `-2` | **minutos** | `HasReachedSeedingTimeLimit` (`:659-670`) |
| `inactive_seeding_time_limit` | `long`, por defecto `-2` | **minutos** | `HasReachedInactiveSeedingTimeLimit` (`:723-736`) |
| `last_activity` | `long` | **segundos unix** | `HasReachedInactiveSeedingTimeLimit` (`:736`) |
| `seeding_time` | `long?`, por defecto null | segundos | `HasReachedSeedingTimeLimit` (`:672-676`). El comentario en `QBittorrentTorrent.cs:36` dice que es "not provided by the list api", pero el cliente lo usa si está presente, lo que ahorra una ida y vuelta a `torrents/properties` |
| `save_path` | `string` | | se compara con `content_path` (`:316`) |
| `content_path` | `string` | | `OutputPath` en webapi `>= 2.6.1` (`:318`) — §4 |

`GetRemainingTime` (`:614-628`):

```csharp
if (torrent.Eta < 0 || torrent.Eta > 365 * 24 * 3600) { return null; }   // > 31,536,000 s
if (torrent.Eta == 8640000) { return null; }                            // qBittorrent's "unknown"
return TimeSpan.FromSeconds((int)torrent.Eta);
```

Y un elemento Completed tiene `RemainingTime` forzado a `TimeSpan.Zero` después (`:273`).

`torrents/info` se pide en cada `RefreshMonitoredDownloads` (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:94`), que además se encola en la cola de comandos con un retardo (debounce) de 5 s tras eventos relevantes (`:53`).

### 1.13 `GET /api/v2/torrents/files?hash=<hash>` — `GetTorrentFiles` (`:137-144`)

Una matriz JSON deserializada en `List<QBittorrentTorrentFile>`, que tiene **exactamente un miembro**: `Name` (`QBittorrentTorrent.cs:59-62`), que se enlaza con `name`. Es la ruta del archivo **relativa a la ruta de guardado**, con separadores `/` en todos los sistemas operativos ("QBittorrent devuelve separadores `/` incluso en windows", `QBittorrent.cs:358`).

Solo se llama desde `GetImportItem` (`:346`) y solo cuando `OutputPath` sigue vacío, es decir, en webapi `< 2.6.1`, o cuando `content_path` llega vacío. `index`, `size`, `progress`, `priority`, `is_seed`, `piece_range` y `availability` se ignoran todos.

Un **array vacío** se gestiona así: `_logger.Debug("No files found for torrent {0} in qBittorrent")` y el elemento se devuelve sin cambios (`:347-351`), lo que después hace que falle `ValidatePath`.

### 1.14 `POST /api/v2/torrents/setCategory` — `SetTorrentLabel` (`:204-211`)

Formato: `hashes=<lowercase hash>`, `category=<post-import category>`.

Solo se llama desde `MarkItemAsImported` (`QBittorrent.cs:52-69`), y solo cuando la configuración opcional `TvImportedCategory` / `MovieImportedCategory` no está vacía y es distinta de la categoría principal. Se captura una `DownloadClientException` y se muestra una advertencia:
"Failed to set post-import torrent label \"{0}\" for {1} in qBittorrent. Does the label exist?"
(`:62-67`). §5.1.

### 1.15 `POST /api/v2/torrents/delete` — `RemoveTorrent` (`:190-202`)

Formato: `hashes=<lowercase hash>`, y `deleteFiles=true` **solo cuando `removeData` es true** (`:196-199`). Es la cadena literal en minúsculas, no `Convert.ToString(bool)`.

`QBittorrent.RemoveItem` (`:333-336`) es toda la implementación:

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    Proxy.RemoveTorrent(item.DownloadId.ToLower(), deleteData, Settings);
}
```

**No llama a `DeleteItemData`.** Esa es la diferencia con el cliente de SAB, que borra por sí mismo la carpeta del trabajo a través del sistema de archivos (`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`; ver [sabnzbd-client-contract.md §5.3](sabnzbd-client-contract.md)). Aquí, borrar los datos es responsabilidad por completo del cliente de descarga. §5.

### 1.16 Endpoints que el cliente nunca toca {#116-endpoints-the-client-never-touches}

Ni siquiera aparecen en la interfaz, así que nunca se llaman: `torrents/pause`, `torrents/resume`, `torrents/stop`,
`torrents/start`, `torrents/setLocation`, `torrents/rename`, `torrents/recheck`,
`torrents/reannounce`, `torrents/filePrio`, `torrents/setDownloadLimit`, `torrents/setUploadLimit`,
`torrents/toggleSequentialDownload`, `torrents/setAutoManagement`, `torrents/editCategory`,
`torrents/removeCategories`, etiquetas, RSS, búsqueda, `app/setPreferences`, `app/defaultSavePath`,
`app/shutdown`, `sync/maindata`, `transfer/*`, `auth/logout`. Pausar y reanudar solo existen como el campo de formulario `paused=`/`stopped=` en `torrents/add`.

Presentes en la interfaz pero nunca llamados desde `QBittorrent.cs`: `GetVersion` (§1.2).

### 1.17 El mapa de rutas de v1 (por completitud; no implementar) {#117-the-v1-route-map-for-completeness-do-not-implement}

`QBittorrentProxyV1.cs`: `/version/api` (`:30`, `:64`: el cliente antepone `"1."` a lo que venga de vuelta, `:65`), `/version/qbittorrent` (`:73`), `/query/preferences` (`:81`), `/query/torrents?label=&category=` (`:89-94`: **ambos** parámetros), `/query/propertiesGeneral/{hash}` (`:103`, `:120`), `/query/propertiesFiles/{hash}` (`:128`), `/command/download` (`:136`), `/command/upload` (`:166`), `/command/delete` o `/command/deletePerm` (`:196`: la distinción entre delete y deleteFiles son dos rutas distintas, no un parámetro), `/command/setCategory` con un fallback a `/command/setLabel` si da 404 (`:205-225`), `/command/addCategory` (`:230`), `/command/topPrio` (`:248`), `/command/setForceStart` (`:269`), `/login` (`:345`).

## 2. `state` → `DownloadItemStatus`

`QBittorrent.GetItems` (`:247-312`). Los estados son las cadenas propias de qBittorrent, generadas por `torrentStateToString` (`qBittorrent/src/webui/api/serialize/serialize_torrent.cpp:44-87`).

| `state` | `DownloadItemStatus` | `Message` | Línea |
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
| `metaDL` | Queued **si `dht: true`**, si no Warning | "qBittorrent is downloading metadata" / "qBittorrent cannot resolve magnet link with DHT disabled" | `:286-299` |
| `forcedMetaDL` | igual que `metaDL` | igual | `:287` |
| `forcedDL` | Downloading | — | `:301` |
| `moving` | Downloading | — | `:302` |
| `downloading` | Downloading | — | `:303` |
| **cualquier otro** | **Downloading** | "Unknown download state: {state}" | `:307-311` |

Notas que un shim debe tener en cuenta:

- **Un estado desconocido no lanza excepción.** Registra `_logger.Info($"Unknown download state: {torrent.State}")` y pasa a Downloading (`:307-311`). Esto es lo contrario del cliente SAB, donde un nombre de estado desconocido lanza una excepción dentro del deserializador y tumba todo el sondeo. Aun así, envía solo nombres de esta tabla.
- **Solo los estados Completed pueden importarse.** `CompletedDownloadService.Check` retorna de inmediato a menos que `Status == Completed` (`src/NzbDrone.Core/Download/CompletedDownloadService.cs:68-71`).
- **Todos los estados Completed ponen `RemainingTime` a cero** (`:273`, con el comentario "qBittorrent sends eta=8640000 for completed torrents").
- `metaDL` / `forcedMetaDL` es la fase de "magnet, sin metadatos todavía". El cliente **no tiene timeout**: está en Queued mientras el shim siga diciendo `metaDL`, y nunca pasa a fallo por sí solo. Lo único que lo convierte en Warning es `dht: false` en `app/preferences` (`:288`). El manejo de descargas fallidas de Sonarr se basa en la antigüedad del grab, no en este estado.
- `stalledDL` es la *advertencia* que ve el operador para un torrent que no avanza. Un shim sin concepto de peers nunca debería usarlo: un Warning en una descarga rastreada aparece en la cola como problema y es lo que inspecciona `FailedDownloadService`.
- `error` y `missingFiles` son Warning a propósito, "so failed download handling isn't triggered" (`:249`). Si un shim quiere que Sonarr ponga la release en la lista negra y la vuelva a buscar, un Warning **no** es la forma de pedirlo.

## 3. Mover vs copiar — la condición exacta y la receta {#3-move-vs-copy--the-exact-condition-and-the-recipe}

### 3.1 La compuerta {#31-the-gate}

`QBittorrent.cs:240-245`, textualmente incluido el comentario que lo explica:

```csharp
// Avoid removing torrents that haven't reached the global max ratio.
// Removal also requires the torrent to be paused, in case a higher max ratio was set on the torrent itself (which is not exposed by the api).
item.CanMoveFiles = item.CanBeRemoved =
    item.DownloadClientInfo.RemoveCompletedDownloads &&
    torrent.State is "pausedUP" or "stoppedUP" &&
    HasReachedSeedLimit(torrent, config);
```

Tres condiciones, todas necesarias:

1. **`RemoveCompletedDownloads`**: el ajuste por cliente del lado de *arr, no algo que qBittorrent diga. `DownloadClientDefinition.RemoveCompletedDownloads` tiene **`true`** por defecto (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17`), y en la interfaz aparece como "Remove Completed". Si el usuario lo desactiva, **las importaciones pasan a ser copias** y el shim no puede hacer nada al respecto. (Un Move se convierte en copia por una segunda razón que el shim tampoco ve: el contenedor de *arr accede a la carpeta de descargas y a la carpeta raíz a través de dos volúmenes, donde `rename()` responde `EXDEV` y `File.Move` de .NET copia y luego borra. zurg lee ambos datos de la API de una fuente de adquisición y adopta la copia después; ver `internal/arrlayout` e `internal/handlers/magic_copies.go`.)
2. **`state` es exactamente `pausedUP` o `stoppedUP`.** `uploading`, `stalledUP`, `queuedUP` y `forcedUP` son Completed pero no se pueden mover; el fixture lo fija así (Sonarr `QBittorrentFixture.cs:680-689`, Radarr `:679-688`).
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

- Un **`ratio_limit >= 0` por torrent** gana directamente y no se consulta el global. `ratio_limit`
  es `-2` = "usar global" y `-1` = "ilimitado" en el propio modelo de qBittorrent
  (`QBittorrentTorrent.cs:32`; wiki, *Set torrent share limit*).
- `-1` (ilimitado) no cumple ninguna de las dos ramas: `-1 >= 0` es falso y `-1 == -2` es falso, así que un torrent ilimitado **nunca** puede ser movido por la regla de ratio.
- El margen de `0.001f` es lo que hace que "alcanzado tras redondeo" funcione; el fixture fija el ratio `1.1006066990976857` contra el límite `1.0` como alcanzado, y también `0.9999` como alcanzado
  (Sonarr `QBittorrentFixture.cs:715-737`, Radarr `:714-736`).

`HasReachedSeedingTimeLimit` (`:655-717`):

```csharp
if (torrent.SeedingTimeLimit >= 0)        { seedingTimeLimit = torrent.SeedingTimeLimit * 60; }        // minutes -> seconds
else if (torrent.SeedingTimeLimit == -2 && config.MaxSeedingTimeEnabled) { seedingTimeLimit = config.MaxSeedingTime * 60; }
else                                      { return false; }
```

luego usa `torrent.SeedingTime` si la API de lista lo proporcionó (`:672-676`); si no, consulta una caché de 5 minutos y, en caso de fallo, llama a **`torrents/properties`** para `seeding_time`
(`:678-716`, `:739-744`). `HasReachedInactiveSeedingTimeLimit` (`:719-737`) tiene la misma forma, pero compara `now - last_activity` con `inactive_seeding_time_limit` (o el global) y nunca necesita una segunda llamada.

### 3.3 Qué decide `CanMoveFiles` {#33-what-canmovefiles-decides}

`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, series, importItem)`
(`CompletedDownloadService.cs:148-151`), y luego dos sitios leen `CanMoveFiles`:

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

(Radarr: `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, idéntico.)

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
`TransferMode.HardLinkOrCopy` si "Use Hardlinks instead of Copy" está activado, si no `TransferMode.Copy`
(`:103`, `:107`). `TransferMode` es `[Flags] None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy=Copy|HardLink`
(`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`).

**Un Move fallido nunca recurre a un Copy.** El argumento completo, con números de línea, está en
[sabnzbd-client-contract.md §5.5](sabnzbd-client-contract.md); `DiskTransferService.cs` es compartido y byte a byte idéntico entre los dos repos. La versión corta: la rama Move de `TransferFile`
(`src/NzbDrone.Common/Disk/DiskTransferService.cs:360-389`) tiene exactamente una ruta de copia, elegida de antemano a partir de `targetMount.DriveFormat == "cifs"` (`:342`, `:378-385`), nunca como reacción a un fallo; `TryMoveFileVerified` vuelve a lanzar la excepción (`:487-503`), y `VerifyFile` lanza `IOException("File move incomplete, data loss may have occurred. …")` cuando el tamaño del destino no coincide con el del origen (`:505-524`).

### 3.4 Con los valores por defecto de qBittorrent, la importación es una **copia** {#34-with-qbittorrents-own-defaults-the-import-is-a-copy}

Tome un torrent que un shim reporta de forma ingenua, con los valores por defecto de qBittorrent, que también son los del modelo:

| Field | Value | Effect |
|---|---|---|
| `state` | `stoppedUP` | conjunct 2 ✓ |
| `ratio_limit` | `-2` (default, `QBittorrentTorrent.cs:33`) | falls to the global branch |
| `max_ratio_enabled` | `false` (qBittorrent's own default; wiki example body `:684`) | global branch fails |
| `seeding_time_limit` | `-2` | needs `max_seeding_time_enabled` |
| `max_seeding_time_enabled` | `false` (wiki `:686`) | fails |
| `inactive_seeding_time_limit` | `-2` | needs `max_inactive_seeding_time_enabled` |
| `max_inactive_seeding_time_enabled` | `false` | fails |

⇒ `HasReachedSeedLimit` false ⇒ `CanMoveFiles` false ⇒ `copyOnly` true ⇒ `TransferMode.Copy` ⇒ **el
\*arr lee cada byte del release desde el montaje y lo vuelve a escribir.** En un montaje de debrid, ese es justo el resultado que todo el diseño existe para evitar, y falla en silencio: nada avisa, la importación tarda horas y llena un disco.

El fixture fija exactamente este caso:
`should_not_be_removable_and_should_not_allow_move_files_if_max_ratio_is_not_set`
(Sonarr `QBittorrentFixture.cs:691-701`, Radarr `:690-700`): límites globales desactivados, torrent pausado, ratio 1.0, `CanMoveFiles == false`.

### 3.5 La receta {#35-the-recipe}

Para cada torrent que un shim quiere importar con **move**:

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

`ratio_limit: 0` toma la primera rama (`0 >= 0`, y `0 - 0 <= 0.001`) y las preferencias globales nunca se consultan, así que `max_ratio_enabled` puede quedarse en `false` y el health check `DownloadClientRemovesCompletedDownloadsCheck` no da problemas. Cualquier `ratio_limit >= ratio` dentro de `0.001` funciona; `0`/`0` es el único caso que no necesita coordinación.

Sobre `pausedUP` vs `stoppedUP`: **develop los trata igual**, tanto en la condición `CanMoveFiles` (`:244`) como en el mapa de estados (`:266-267`), y cada fixture de seed-limit es un par de `[TestCase]` que los cubre a los dos. `stoppedUP` es la forma de qBittorrent 5 (`serialize_torrent.cpp:54-55`; `pausedUP` ya no existe en master). `pausedUP` es la opción más segura frente a builds *publicados* de \*arr, porque la rama de `stoppedUP` se añadió cuando llegó qBittorrent 5, y las versiones antiguas de Sonarr v4 / Radarr v5 solo conocen `pausedUP`. Ese último punto es una inferencia sobre etiquetas antiguas, no algo que las fuentes de develop de arriba demuestren.

Y lo que no depende del shim: **"Remove Completed" tiene que seguir activado en la configuración de download client de \*arr.** Viene activado por defecto (`DownloadClientDefinition.cs:17`). Documéntalo, porque desactivarlo convierte en silencio cada importación en una descarga completa.

## 4. `OutputPath` — de dónde le dice el \*arr que importe {#4-outputpath--where-the-arr-is-told-to-import-from}

### 4.1 La ruta de 2.6.1 en adelante: `content_path` {#41-the-261-path-content_path}

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

El texto de la advertencia (`src/NzbDrone.Core/Localization/Core/en.json`):

> Unable to Import. Path matches client base download directory, it's possible 'Keep top-level folder'
> is disabled for this torrent or 'Torrent Content Layout' is NOT set to 'Original' or 'Create Subfolder'?

Reglas que debe cumplir un shim:

- `content_path` **no debe ser igual** a `save_path`. La igualdad es el fallo, no un respaldo: el elemento pasa a ser un Warning y nunca se importa.
- `content_path` debe ser **absoluta y válida para el SO en el que se ejecuta el \*arr**. `CompletedDownloadService.ValidatePath` (`CompletedDownloadService.cs:295-313`) la rechaza si no lo es, con el mensaje "[{0}] is not a valid local path. You may need a Remote Path Mapping."
- Debe existir en el host del \*arr como **carpeta o archivo**; `ProcessPath` (`DownloadedEpisodesImportService.cs:80-105`) comprueba primero `FolderExists` y luego `FileExists`, y si no existe ninguno de los dos, cae en `LogInaccessiblePathError` y devuelve un resultado vacío.
- No envíes un `content_path` vacío. Se considera "differs" respecto a un `save_path` no vacío, así que `OutputPath` se establece como un `OsPath` vacío, y entonces `GetImportItem` pasa al recorrido de `torrents/files` (§4.2) porque `item.OutputPath.IsEmpty` es verdadero (`:341-344`).
- Este bloque solo se ejecuta para elementos **Completed**, así que `content_path` solo es determinante cuando el estado está dentro del conjunto Completed de §2.

Lo que qBittorrent real pone ahí — `TorrentImpl::contentPath()` (`qBittorrent/src/base/bittorrent/torrentimpl.cpp:577-587`):

```cpp
Path TorrentImpl::contentPath() const
{
    if (!hasMetadata())    return {};
    if (filesCount() == 1) return (actualStorageLocation() / filePath(0));   // the FILE, not a folder
    const Path rootPath = this->rootPath();
    return (rootPath.isEmpty() ? actualStorageLocation() : rootPath);
}
```

con `rootPath()` = `actualStorageLocation() / Path::findRootFolder(filePaths())` (`:565-575`). Así que: el `content_path` de un torrent de **un solo archivo** es el propio archivo; un torrent de varios archivos con una carpeta raíz común recibe esa carpeta; un torrent de varios archivos **sin** raíz común recibe `save_path`, que es exactamente el caso al que se refiere la advertencia del cliente `content_path == save_path`.

`RemapRemoteToLocal(Settings.Host, …)` aplica las Remote Path Mappings del usuario, indexadas por la cadena **Host** configurada. Si el \*arr se ejecuta en un contenedor y el shim informa la ruta del host, el usuario necesita un mapeo; consulta [sabnzbd.md](../guides/sonarr-radarr.md#8-if-your-arr-is-in-docker), que se aplica sin cambios.

### 4.2 La ruta anterior a 2.6.1: `GetImportItem` recorre `torrents/files` {#42-the-pre-261-path-getimportitem-walks-torrentsfiles}

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

Solo usa **`files[0].name`**, sube hasta el componente de ruta más alto y lo une a `properties.save_path`. El fixture fija las tres formas (Sonarr `QBittorrentFixture.cs:317-421`, Radarr `:296-400`):

| `files[0].name` | `save_path` | `OutputPath` |
|---|---|---|
| `Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` |
| `Folder/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Folder` |
| `Droned.S01.12/E01.mkv` (+ `E02.mkv`) | `/Torrents` | `/Torrents/Droned.S01.12` |

Fíjate en la tercera fila: es la raíz de `files[0]`, no una raíz común calculada, así que **un shim en esta ruta debe listar los archivos en un orden donde la primera entrada lleve la carpeta del release**. Un shim que reporte webapi `>= 2.6.1` nunca llega aquí, y es una razón más para reportar `2.11.2`.

`previousImportAttempt` es un parámetro de `GetImportItem` (`:338`) y **nunca se lee** en esta implementación. No se guarda nada sobre un intento fallido.

### 4.3 Cuándo la ruta es incorrecta y con qué frecuencia se reintenta {#43-when-the-path-is-wrong-and-how-often-it-is-retried}

No hay backoff ni límite de intentos en esta ruta.

- `CompletedDownloadService.Check` se ejecuta para cada descarga rastreada en estado `Downloading` o
  `ImportBlocked`, en cada actualización
  (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:125-129`).
- `Check` llama primero a `SetImportItem` **(`CompletedDownloadService.cs:73`)**, que es
  `_provideImportItemService.ProvideImportItem(...)` → `client.GetImportItem(...)`
  (`:290-293`, `src/NzbDrone.Core/Download/ProvideImportItemService.cs:17-22`). Por eso `OutputPath` se vuelve a calcular desde la fila actual de `torrents/info` en cada consulta.
- Los fallos de `ValidatePath` (`:295-313`) generan un Warning y dejan el estado en `Downloading`, así que la siguiente consulta lo intenta de nuevo desde cero:
  - ruta de salida vacía → "Download doesn't contain intermediate path, Skipping."
  - ruta de un sistema operativo distinto → "[{0}] is not a valid local path. You may need a Remote Path Mapping. …"
- `Import` también llama a `SetImportItem` al entrar (`:130`) antes de volver a leer
  `trackedDownload.ImportItem.OutputPath.FullPath` (`:147`), y lo dispara `DownloadProcessingService` desde el estado `ImportPending`
  (`src/NzbDrone.Core/Download/DownloadProcessingService.cs:61-63`). Si una importación falla, el estado se queda en `ImportPending` (`:158`) o pasa a `ImportBlocked` (`:196`); en ambos casos se vuelve a procesar.
- Una ruta que existe pero no da nada importable produce "No files found are eligible for import in {0}" (`:162`) y se queda en `ImportPending`.

**Consecuencia para un shim: `content_path` puede estar mal durante un rato.** Informa el torrent como Downloading (o Queued) hasta que la carpeta exista de verdad y los tamaños de sus archivos sean definitivos. Así el cliente seguirá consultando. Si informas Completed demasiado pronto, gastas un intento de importación contra una carpeta que no está lista. Y peor aún: el \*arr puede mover un archivo con tamaño parcial y luego fallar en `VerifyFile`, después de haber vaciado ya el origen. Es la misma trampa que está documentada para el endpoint de SAB ([sabnzbd.md](../guides/sonarr-radarr.md), *Qué pasa en un grab*, paso 5).

## 5. La secuencia posterior a la importación {#5-the-post-import-sequence}

### 5.1 Qué se dispara, y en qué orden {#51-what-fires-in-order}

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

y `RemoveFromDownloadClient` (`:87-103`) es:

```csharp
_logger.Debug("[{0}] Removing download from {1} history", ...);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);             // :92  deleteData: TRUE
trackedDownload.DownloadItem.Removed = true;
```

Así que la secuencia de llamadas tras una importación exitosa es:

1. **`POST /api/v2/torrents/setCategory`** — solo si hay configurada una categoría post-importación
   (`QBittorrent.cs:52-69`). Se omite por defecto.
2. Antes de cualquiera de esos, y fuera del cliente de descargas por completo: **el \*arr mueve el archivo**, y luego
   `ProcessFolder` puede **borrar la propia carpeta de origen**
   (`DownloadedEpisodesImportService.cs:209-223`, Radarr `DownloadedMovieImportService.cs:226-240`):

   ```csharp
   if (importMode == ImportMode.Move &&
       importResults.Any(i => i.Result == ImportResultType.Imported) &&
       ShouldDeleteFolder(directoryInfo, series))
   {
       _diskProvider.DeleteFolder(directoryInfo.FullName, true);   // recursive
   }
   ```

   `ShouldDeleteFolder` (`:108-153`) se niega cuando algún archivo de vídeo que queda en la carpeta se parsea y no es
   una muestra (`:117-133`), o cuando queda un `.rar` de más de 10 MB (`:135-139`). Tras un movimiento exitoso
   de un solo archivo, ninguna de las dos cosas aplica, así que la carpeta **sí** se elimina. Una `IOException` se captura y
   se registra en Debug (`:219-222`).
3. **`POST /api/v2/torrents/delete`** con `hashes=<lowercase hash>&deleteFiles=true`
   (`QBittorrent.cs:335`, `QBittorrentProxyV2.cs:190-202`).

Otros dos eventos llegan al mismo `RemoveFromDownloadClient(…, true)`:

- `DownloadFailedEvent` (`DownloadEventHub.cs:26-46`), condicionado por `RemoveFailedDownloads` de cada cliente
  (por defecto `true`, `DownloadClientDefinition.cs:18`). Ojo: `TrackedDownload.Fail()` pone `DownloadItem.CanBeRemoved = true` sin condiciones
  (`src/NzbDrone.Core/Download/TrackedDownloads/TrackedDownload.cs:39-46`, comentario: "Set CanBeRemoved
  to allow the failed item to be removed from the client") — **así que una descarga fallida se borra incluso cuando el control de límite de seed dice lo contrario.**
- `DownloadCanBeRemovedEvent` (`:71-85`).

Una `NotSupportedException` que sale de `RemoveItem` se degrada a
"Removing item not supported by your download client ({0})." (`:95-98`); cualquier otra excepción se registra
como error y el elemento *no* se marca como Removed, así que se reintentará en el siguiente sondeo (`:99-102`).

### 5.2 Qué debe hacer el shim con `deleteFiles=true` {#52-what-the-shim-must-do-with-deletefilestrue}

Es la misma decisión que `internal/sabnzbd` ya tomó para `mode=history&name=delete`, por la misma razón. Desde `internal/sabnzbd/api.go:596-609`:

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

El caso de qBittorrent tiene la misma forma, con un detalle: en esta API, borrar los datos es trabajo del *cliente*, no del \*arr, porque `RemoveItem` **no** llama a `DeleteItemData` (§1.15). Pero el \*arr ya borró la carpeta en el paso 2 de arriba, a través del mount. Con `__magic__`, eso escribe un tombstone: la entrada desaparece de `__magic__` pero se mantiene exactamente donde estaba en `__all__`, en cada directorio de filtros y en la cuenta del debrid ([magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)).

Entonces:

- **`torrents/delete` borra el *registro* del torrent que el shim guarda para el \*arr.** Responde 200.
- **`deleteFiles` no debe borrar el torrent en el proveedor.** La versión que el \*arr acaba de importar sigue sirviéndose desde ese torrent; borrarlo destruye lo que se importó. El único caso en que un borrado real sería honesto es un torrent del que nunca se importó nada, es decir, la ruta de descarga fallida. Incluso ahí, un torrent de debrid es estado de biblioteca compartido, no una descarga temporal, así que el valor por defecto seguro es: **nunca borrar el torrent en el proveedor, solo tombstone.** Díselo al usuario en la documentación, igual que hace [sabnzbd.md](../guides/sonarr-radarr.md) en *Lo que funciona, y lo que no*.
- Un `torrents/delete` para un **hash desconocido** debería seguir respondiendo 200. El qBittorrent real lo hace (wiki, *Delete torrents*: "200 | All scenarios"), y un error aquí se registra como error y se reintenta en cada sondeo para siempre.

### 5.3 `MarkItemAsImported` y la categoría posterior a la importación {#53-markitemasimported-and-the-post-import-category}

`QBittorrent.cs:52-69` establece la categoría posterior a la importación cuando `TvImportedCategory` / `MovieImportedCategory` está configurada y es distinta de la categoría principal. Se llama para **cada** importación completada (`DownloadEventHub.cs:54`), antes de decidir si se elimina.

Si un shim respeta `setCategory` y mueve de verdad el torrent fuera de la categoría consultada, el torrent desaparece de la siguiente consulta a `torrents/info?category=…`. Eso es justamente para lo que sirve el ajuste, y lo que la UI muestra como `DownloadClientHasPostImportCategory` (`src/NzbDrone.Core/Queue/QueueService.cs:84`, obtenido de `DownloadClientItemClientInfo.HasPostImportCategory`, `QBittorrent.cs:234`). Aceptar la llamada y registrar la nueva categoría es el comportamiento correcto; rechazarla solo produce una advertencia (`:62-67`).

## 6. `Test()`: cada comprobación, en orden, y su mensaje {#6-test--every-check-in-order-and-its-message}

`DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`) envuelve todo el proceso: **cualquier excepción que escape se convierte en** `ValidationFailure("", "Test was aborted due to an error: " + ex.Message)`.

`QBittorrent.Test(List<ValidationFailure>)` (`:418-429`):

```csharp
failures.AddIfNotNull(TestConnection());
if (failures.HasErrors()) { return; }     // a *warning* does not stop the rest
failures.AddIfNotNull(TestCategory());
failures.AddIfNotNull(TestPrioritySupport());
failures.AddIfNotNull(TestGetTorrents());
```

### 6.1 `TestConnection` (`:431-509`)

Cada rama **retorna**, así que como máximo sale un fallo de este método.

| Orden | Condición | Propiedad | Mensaje |
|---|---|---|---|
| 1 | `_proxySelector.GetProxy(Settings, force: true).GetApiVersion(Settings)` — fuerza la nueva detección (`:435`) | | |
| 2 | versión `< 1.5` (`:436`) | `Host` | "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| 3 | versión `< 1.6` **y** categoría definida (`:445-455`) | `Category` | "Category is not supported" / detalle "Categories are not supported until qBittorrent version 3.3.0. Please upgrade or try again with an empty Category." |
| 4 | versión `>= 1.6` **y** categoría vacía (`:456-464`) | `TvCategory` / `MovieCategory` | **Warning** — "Category is recommended" / "{appName} will not attempt to import completed downloads without a category." |
| 5 | `GetConfig` y luego `RemovesCompletedDownloads(config)` (`:467-474`) | `""` | "qBittorrent is configured to remove torrents when they reach their Share Ratio Limit" / detalle que menciona Options → BitTorrent → Share Ratio Limiting |

Mapeo de excepciones (`:476-506`):

| Capturada | Propiedad | Mensaje |
|---|---|---|
| `DownloadClientAuthenticationException` | `ApiKey` si hay una api key definida, si no `Username` | "Authentication Failure" / "Please verify your credentials. Also verify if the host running {appName} isn't blocked from accessing {clientName} by WhiteList limitations…" |
| `WebException` con `Status == ConnectFailure` | `Host` | "Unable to connect to qBittorrent" / "Please verify the hostname and port." |
| cualquier otra `WebException` | `""` | "Unknown exception: {message}" |
| cualquier otra `Exception` | `Host` | "Unable to connect to qBittorrent", `DetailedDescription = ex.Message` |

Ojo: el caso 4 es un **warning**, y `failures.HasErrors()` en `:421` es false para los warnings, así que una configuración sin categoría igualmente ejecuta las otras tres comprobaciones.

### 6.2 `TestCategory` (`:511-556`): el flujo de "category does not exist" {#62-testcategory-511-556--the-category-does-not-exist-flow}

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

Fallo: propiedad `TvCategory` / `MovieCategory` (o `TvImportedCategory` / `MovieImportedCategory`),
mensaje "Configuration of category failed", detalle "{appName} was unable to add the label to
qBittorrent."

Así que un shim tiene dos opciones: o incluye desde el principio las categorías configuradas para que `torrents/categories` ya las contenga, o acepta `createCategory` y lo refleja en la siguiente respuesta de `torrents/categories`. **No hay una tercera opción**: el cliente vuelve a leer y falla si la clave sigue sin aparecer.

Los nombres de categoría se comparan **exactamente**, distinguiendo mayúsculas y minúsculas (`Dictionary<string, …>.ContainsKey` con el comparador ordinal por defecto).

Ojo con el manejo de `TvImportedCategory`: la categoría posterior a la importación también se comprueba y se crea aquí, aunque solo se use después de una importación. Si el operador la configura, tiene que existir.

`QBittorrentSettingsValidator` (`QBittorrentSettings.cs:23-24`) ya rechaza los nombres de categoría que coincidan con `^([^\\\/](\/?[^\\\/])*)?$`: sin barra invertida, sin `//`, sin `/` al principio ni al final, antes de hacer ninguna petición.

### 6.3 `TestPrioritySupport` (`:558-597`): la comprobación de salud `queueing` {#63-testprioritysupport-558-597--the-queueing-health-check}

```csharp
var recentPriorityDefault = Settings.RecentTvPriority == (int)QBittorrentPriority.Last;
var olderPriorityDefault  = Settings.OlderTvPriority  == (int)QBittorrentPriority.Last;
if (olderPriorityDefault && recentPriorityDefault) { return null; }   // :563-566  the default: nothing checked

var config = Proxy.GetConfig(Settings);
if (!config.QueueingEnabled) { … }                                    // :572-588
```

La propiedad del fallo es `nameof(Settings.RecentTvPriority)` o `nameof(Settings.OlderTvPriority)`
(se comprueban en ese orden), con el mensaje "Queueing Not Enabled" y el detalle "Torrent Queueing is not enabled in
your qBittorrent settings. Enable it in qBittorrent or select 'Last' as priority."

Una excepción aquí se convierte en `("", "Unknown exception: {message}")` (`:590-594`).

`queueing_enabled` tiene por defecto **`true`** en el modelo (`QBittorrentPreferences.cs:41`), así que un shim que omite la clave pasa la comprobación, pero omitirla es mentir si `topPrio` no hace nada. Reportar `queueing_enabled: false` es honesto y solo produce este fallo **si** el operador cambió la configuración de prioridad para que deje de ser `Last`.

### 6.4 `TestGetTorrents` (`:599-612`)

`Proxy.GetTorrents(Settings)`; any exception becomes `("", "Failed to get the list of torrents:
{exceptionMessage}")`. This is the check that catches a malformed `torrents/info` body — a JSON object
instead of an array, a bad enum, a non-numeric `size`.

### 6.5 La comprobación `dht` {#65-the-dht-check}

There is **no** dedicated DHT check in `Test()`. `dht` is consulted at grab time
(`:73-76`, magnets without trackers) and at poll time (`:288`, the `metaDL` branch). A shim reporting
`dht: false` passes the connection test and then refuses every trackerless magnet with
`ReleaseDownloadException("Magnet not supported by download client. …")`
(`TorrentClientBase.cs:115`). **Report `dht: true`.**

## 7. Análisis e importación: consecuencias que un shim debe conocer {#7-parsing-and-import-consequences-a-shim-should-know}

### 7.1 `name` se convierte en `Title`, y `Title` se usa para tres cosas distintas {#71-name-becomes-title-and-title-is-used-for-three-different-things}

`DownloadClientItem.Title = torrent.Name` (`QBittorrent.cs:232`). Aguas abajo:

1. **Identificación de serie/película.** `CompletedDownloadService.Check` hace `_parsingService.GetSeries(trackedDownload.DownloadItem.Title)` (`CompletedDownloadService.cs:95`). Si devuelve null, recurre al **historial de grab** usando `DownloadId` (`:99-102`). Y si tampoco aparece ahí, muestra "Series title mismatch; automatic import is not possible." y pone `ImportBlocked` (`:104-110`). El equivalente de Radarr está en `ProcessFolder`, que lee `_historyService.FindByDownloadId(downloadClientItem?.DownloadId ?? "")` (`DownloadedMovieImportService.cs:193-194`).
   **Esta es la segunda razón por la que el shim tiene que usar exactamente el infohash que calculó el \*arr** (§1.7): el respaldo del historial se basa en `DownloadId`, así que un hash que no coincide pierde tanto la ruta del título como el respaldo.
2. **Parseo del release para la decisión de importación.**
   `downloadClientItemInfo = Parser.Parser.ParseTitle(downloadClientItem.Title)` (Sonarr `ImportDecisionMaker.cs:80`; Radarr `ParseMovieTitle`, `:80`), que se asigna a `LocalEpisode.DownloadClientEpisodeInfo` / `LocalMovie.DownloadClientMovieInfo` (`:94` / `:92`).
3. **Líneas de log y la UI de la cola.**

**La puerta de respaldo de título de Sonarr.** `AggregateEpisodes.GetBestEpisodeInfo`
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

Hay tres condiciones para usar el título del cliente de descarga en lugar del nombre del archivo: `!OtherVideoFiles`, que el nombre del archivo no sea en sí un título scene, y que el título del cliente no sea un parseo de temporada completa. Así que el nombre del torrent solo sirve de rescate en un release de un único archivo y sin nombre scene.

Radarr **no tiene** una puerta equivalente de ganador único. `LocalMovie.OtherVideoFiles` existe (`src/NzbDrone.Core/Parser/Model/LocalMovie.cs:36`), pero la información parseada de la película se combina mediante una cadena de aumentadores ordenada por confianza en lugar de elegir una sola (`AggregateQuality.cs:25-121`). El título del cliente de descarga alimenta esos aumentadores, y la identidad de la película sale del parseo de la carpeta más el historial de grab (`DownloadedMovieImportService.cs:192-195`).

**`OtherVideoFiles`** (`ImportDecisionMaker.cs:85`, `:100`, Radarr `:83`, `:98`):

```csharp
var nonSampleVideoFileCount = sceneSource ? GetNonSampleVideoFileCount(newFiles, series, downloadClientItemInfo, folderInfo) : videoFiles.Count;
…
OtherVideoFiles = nonSampleVideoFileCount > 1
```

`ProcessFolder` siempre pasa `sceneSource: true` (`DownloadedEpisodesImportService.cs:201`), así que una carpeta con dos o más videos que no sean muestras activa `OtherVideoFiles` y el título del cliente de descarga queda fuera de juego para todos los archivos que contiene.

**Por qué esto importa en zurg.** Real-Debrid reescribe los nombres de release que activan su bloqueo de nombres de archivo: `WEB-DL`, `WEB.x264` y `WEB.H264` en ese caso exacto, `WEBRip`, `BDRip`, `HDRip`, `DVDRip`, `HDTV.x264`, `HDTV.XviD`, `BluRay.x264` y `p.BluRay.DTS` en cualquier capitalización, según se midió el 2026-10-14. Además, zurg añade un sufijo cuando dos releases chocan por nombre. Cualquiera de las dos cosas puede hacer que `torrent.name` deje de parsearse como el release que se capturó. Consulta la sección RD 451 del `CLAUDE.md` del monorepo. Las consecuencias, en orden: la identificación recurre al historial de grab (sigue funcionando si el hash coincide); el parseo por archivo de Sonarr toma el relevo (bien para un archivo con nombre correcto dentro de la carpeta); y el nombre de la carpeta bajo `__magic__`, que es lo que lee `Parser.ParseTitle(directoryInfo.Name)` en `DownloadedEpisodesImportService.cs:184`, pasa a ser lo otro que tiene que seguir siendo parseable.

### 7.2 El escaneo de la carpeta de importación descarta subárboles completos {#72-the-import-folder-scan-drops-whole-subtrees}

`DiskScanService.FilterPaths` (`src/NzbDrone.Core/MediaFiles/DiskScanService.cs:232-246`), aplicado a la carpeta de descargas en `DownloadedEpisodesImportService.cs:185` (Radarr `DownloadedMovieImportService.cs:202`) con `filterExtras: true`:

```csharp
private static readonly Regex ExcludedExtrasSubFolderRegex = new Regex(@"(?:\\|\/|^)(?:extras|extrafanart|behind the scenes|deleted scenes|featurettes|interviews|other|scenes|samples|shorts|trailers)(?:\\|\/)", …IgnoreCase);   // :72
private static readonly Regex ExcludedSubFoldersRegex      = new Regex(@"(?:\\|\/|^)(?:@eadir|\.@__thumb|plex versions|\.[^\\/]+)(?:\\|\/)", …IgnoreCase);   // :73
private static readonly Regex ExcludedExtraFilesRegex      = new Regex(@"(-(trailer|other|behindthescenes|deleted|featurette|interview|scene|short)\.[^.]+$)", …IgnoreCase);   // :74
private static readonly Regex ExcludedFilesRegex           = new Regex(@"^\.(_|unmanic|DS_Store$)|^Thumbs\.db$", …IgnoreCase);   // :75
```

**La regex de extras de Radarr difiere en una alternativa**: `sample[s]?` en lugar de `samples` (Radarr `DiskScanService.cs:72`), así que Radarr también descarta una carpeta `sample/` donde Sonarr solo descarta `samples/`. Lo demás de las cuatro regex es idéntico entre los dos repos.

Ojo con la alternativa `\.[^\\/]+` de `ExcludedSubFoldersRegex`: **cualquier componente de directorio que empiece por punto se descarta**, a cualquier profundidad. Y la comparación se hace contra `basePath.GetRelativePath(path)`, así que solo afecta a lo que hay dentro de la carpeta de importación. Un punto en una carpeta superior al montaje no da problemas.

Solo llegan al filtro los archivos cuya extensión está en `MediaFileExtensions.Extensions` (`DiskScanService.GetVideoFiles`, `:202-215`).

### 7.3 La detección de muestras lee el archivo {#73-sample-detection-reads-the-file}

`GetNonSampleVideoFileCount` (`ImportDecisionMaker.cs:216-234`) llama a `_detectSample.IsSample(...)` para **cada** archivo de vídeo de la carpeta. `DetectSample.IsSample` (`src/NzbDrone.Core/MediaFiles/EpisodeImport/DetectSample.cs:27-45`) solo se salta la comprobación en los casos de especiales, `.flv` y `.strm` (`:78-101`). En el resto, llama a `_videoFileInfoReader.GetRunTime(path)` —**ffprobe, sobre el archivo, a través del mount**— y compara con un mínimo calculado a partir de la duración esperada (`:103-121`). Una duración de exactamente 0 se trata como **muestra** (`:107-111`), y si falta la duración, se registra el mensaje "Failed to get runtime from the file, make sure ffprobe is available" y se devuelve Indeterminate (`:38-42`).

`ShouldDeleteFolder` (`DownloadedEpisodesImportService.cs:117-133`) repite la misma comprobación sobre lo que queda después del movimiento.

Así que importar una release de N archivos cuesta al menos N aperturas de ffprobe contra el backend de debrid antes de mover nada. Eso es un coste real en un mount de zurg, y desde el lado del cliente no hay forma de evitarlo.

### 7.4 Los rechazos en `ProcessFolder` / `ProcessFile` {#74-the-refusals-in-processfolder--processfile}

| Condición | Resultado | Línea (Sonarr) |
|---|---|---|
| la ruta de importación es una carpeta de serie/película | `ImportRejectionReason.SeriesFolder` — "Import path is mapped to a series folder" (Radarr: `MovieFolder`, "…a movie folder") | `:175-182` (Radarr `:183-190`) |
| el nombre de la carpeta no coincide con ninguna serie/película conocida | `UnknownSeriesResult("Unknown Series")` | `:160-168` |
| el nombre del archivo empieza por `._` | `InvalidFilePath` | `:251-259` |
| la extensión está en `FileExtensions.DangerousExtensions` | `DangerousFile` | `:263-271` |
| la extensión está en `FileExtensions.ExecutableExtensions` | `ExecutableFile` | `:273-281` |
| la extensión no está en `MediaFileExtensions.Extensions` | `UnsupportedExtension` | `:283-293` |

**`SeriesPathExists` / `MoviePathExists` es el que da problemas con una estructura `__magic__`.** Si la root folder del *arr es `/mnt/zurg/__magic__/tv` y una carpeta de serie es `/mnt/zurg/__magic__/tv/The Show`, entonces una ruta de importación que resulta ser una carpeta de serie se rechaza directamente. Por eso la carpeta de descargas (`content_path`) tiene que estar al mismo nivel que las root folders, no dentro de una, que es la configuración que ya indica [sabnzbd.md](../guides/sonarr-radarr.md):
`save_path` = `/mnt/zurg/__magic__/__all__`, root folders `/mnt/zurg/__magic__/tv` y `/mnt/zurg/__magic__/movies`, releases en `/mnt/zurg/__magic__/__all__/<release>`.

`_UNPACK_` y `_FAILED_` se quitan del nombre de la carpeta antes de parsearlo (`GetCleanedUpFolderName`, `:311-317`).

`IsFileLocked` se **omite por completo cuando hay un item del download client** (`:187-199`, `:295-304`): la comprobación de bloqueo solo se ejecuta en escaneos manuales o de root folder. Un shim nunca tiene que preocuparse por ello.

---

## 8. Las comprobaciones de salud {#8-the-health-checks}

Las tres son compartidas con el cliente SAB y se analizan en [sabnzbd-client-contract.md §6](sabnzbd-client-contract.md). Lo específico de qBittorrent:

- **`RemotePathMappingCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs:59-173`) recorre `client.GetStatus().OutputRootFolders`. En qBittorrent es la única carpeta calculada en `QBittorrent.cs:377-407`: el `save_path` global, sobrescrito o ampliado por el `savePath` de la categoría configurada (§1.5). Debe ser una ruta válida para el SO **en el que corre el \*arr** (`:68-113`) y debe existir **en el host del \*arr** (`:115-158`). No hace falta que tenga permisos de escritura. `IsLocalhost` es `Settings.Host == "127.0.0.1" || Settings.Host == "localhost"` (`:406`) y solo cambia cuál de los tres mensajes de error se muestra.
- **`DownloadClientRemovesCompletedDownloadsCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:33-66`) avisa siempre que `GetStatus().RemovesCompletedDownloads` es true, es decir, siempre que el flag derivado de §1.4 sea true. Mantén `max_ratio_enabled` y `max_seeding_time_enabled` en false (lo que ya hace la receta de §3.5) y no mostrará nada.
- **`DownloadClientRootFolderCheck`** es el único punto en el que los dos repos realmente difieren: Sonarr avisa solo cuando una carpeta raíz es igual a una carpeta de salida; Radarr también cuando una carpeta raíz contiene una. El análisis completo está en [sabnzbd-client-contract.md §6.1](sabnzbd-client-contract.md). La regla práctica es la misma aquí: no pongas una carpeta raíz igual a la ruta de guardado ni por encima de ella, y tampoco dentro de ella. `/mnt/zurg/__magic__/tv` es una carpeta hermana de `/mnt/zurg/__magic__/__all__`.

## 9. Sonarr frente a Radarr: la diferencia completa {#9-sonarr-vs-radarr--the-complete-diff}

Verificado comparando por pares los archivos descargados (BOM y CRLF normalizados).

| Archivo | Diferencia |
|---|---|
| `QBittorrent.cs` | `TvCategory`→`MovieCategory`, `TvImportedCategory`→`MovieImportedCategory`, `RecentTvPriority`→`RecentMoviePriority`, `OlderTvPriority`→`OlderMoviePriority`, `RemoteEpisode`→`RemoteMovie`; `remoteEpisode.IsRecentEpisode()` → `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` (`:80`, `:137`). **Los números de línea coinciden uno a uno.** |
| `QBittorrentSettings.cs` | los mismos renombres; categoría por defecto `"tv-sonarr"` → `"radarr"` (`:36`); token del texto de ayuda `…EpisodeHelpText` → `…MovieHelpText`. Los números de línea coinciden. |
| `QBittorrentProxyV2.cs` | el renombre de la categoría; `new[] { HttpStatusCode.Forbidden }` → `[HttpStatusCode.Forbidden]` (expresión de colección, Sonarr `:401` / Radarr `:400`); Sonarr tiene una línea en blanco extra en la 13 → **Sonarr N = Radarr N−1 para N ≥ 14**. |
| `QBittorrentProxyV1.cs` | el renombre de la categoría; el mismo desfase por línea en blanco. |
| `QBittorrentProxySelector.cs` | un doble espacio sobrante en el constructor de Sonarr (`:46`); línea en blanco en la 3 → Sonarr N = Radarr N−1 para N ≥ 4. |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **idénticos byte a byte.** |
| `TorrentClientBase.cs` | `RemoteEpisode`→`RemoteMovie` en todo el archivo; Radarr también trata el HTTP **410 Gone** igual que el 404 al descargar un `.torrent` (`:175`), Sonarr solo el 404. Ambos tienen 274 líneas. |
| `QBittorrentFixture.cs` | los mismos tests, en otro orden: `missingFiles_item_should_have_required_properties` está en Sonarr `:296-315` y en Radarr `:402-420`, y **la copia de Radarr no tiene el atributo `[Test]`** (`:401` está en blanco), así que nunca se ejecuta allí. Sonarr `:318-421` = Radarr `:297-400`; desde Sonarr `:423` en, Radarr = Sonarr − 1. Sonarr tiene 1000 líneas, Radarr 998. |
| `DiskScanService.cs` | `ExcludedExtrasSubFolderRegex`: Radarr tiene `sample[s]?`, Sonarr `samples` (`:72` en ambos). Las otras tres regex son idénticas. |
| servicios de importación | `Series`/`Episode` frente a `Movie`; el filtro de preferencia de título de `AggregateEpisodes` de Sonarr no tiene equivalente en Radarr (§7.1). Ambos rechazan una ruta de importación que sea una carpeta de la biblioteca antes de hacer nada más (Sonarr `:175-182`, Radarr `:183-190`) y luego analizan el nombre de la carpeta (Sonarr `:184`, Radarr `:195`); Radarr además busca el historial de grab por `DownloadId` ahí (`:193-194`). |
| `ImportApprovedEpisodes.cs` / `ImportApprovedMovie.cs` | el switch de `copyOnly` es idéntico, Sonarr `:139-152` / Radarr `:116-129`. |
| `DiskTransferService.cs`, `DownloadClientBase.cs`, `DownloadEventHub.cs`, `Json.cs`, `HttpClient.cs`, `HttpRequestBuilder.cs` | compartidos, **idénticos byte a byte**. |

Todo lo demás en este documento es idéntico byte a byte salvo por Series/Movie, y aplica a ambos en la misma línea.

---

## 10. Ejemplos de payloads mínimos pero completos {#10-minimal-but-complete-example-payloads}

### 10.1 `GET /api/v2/app/webapiVersion`

```
2.11.2
```

`Content-Type: text/plain`. No es JSON, sin comillas, y no hace falta salto de línea al final.

### 10.2 `POST /api/v2/auth/login`

Cuerpo de la petición: `username=sonarr&password=hunter2`, `application/x-www-form-urlencoded`.

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8
Set-Cookie: SID=8f3c1c0e9a1f4d2f9c0b7a5e3d1f6b2a; path=/

Ok.
```

Credenciales incorrectas: sigue devolviendo **200**, con el cuerpo `Fails.`. Nunca devuelve un 401.

### 10.3 `GET /api/v2/app/preferences`

Solo se leen las diez claves de §1.4; puedes enviar más si quieres, se ignorarán.

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

Requisitos imprescindibles:

- `save_path` debe existir como directorio **en el host de Sonarr/Radarr** (`RemotePathMappingCheck`, §8).
- `max_ratio_enabled: false` + `max_seeding_time_enabled: false` mantiene
  `RemovesCompletedDownloads` en false, lo que evita que fallen tanto la prueba de conexión (§6.1, caso 5) como la comprobación de estado.
- `dht: true`, o los magnet sin trackers se rechazan en el cliente (§6.5).
- `max_ratio_act` es un **entero** (§0.6).

### 10.4 `GET /api/v2/torrents/categories`

```json
{
  "tv": { "name": "tv", "savePath": "" },
  "movies": { "name": "movies", "savePath": "" }
}
```

Un **objeto** JSON, `savePath` en **camelCase**, que nunca empieza con `//` (§1.5). Un `savePath` vacío
deja la carpeta raíz de salida en el `save_path` global.

### 10.5 `GET /api/v2/torrents/info?category=tv`: uno descargando, otro importable {#105-get-apiv2torrentsinfocategorytv--one-downloading-one-importable}

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

Requisitos obligatorios:

- Un **array** JSON (`List<QBittorrentTorrent>`); si devuelves un objeto, `GetTorrents` lanza una excepción y `TestGetTorrents` (§6.4) falla.
- `hash` en **minúsculas** (§1.8) y exactamente el infohash que el \*arr calculó a partir del magnet o del `.torrent` (§1.7).
- `size` en **bytes**; `progress` es una fracción de 0 a 1. `RemainingSize = size × (1 − progress)`.
- `eta: 8640000` significa "desconocido" y produce un `RemainingTime` nulo (`:622-625`); un elemento Completed recibe `TimeSpan.Zero` en cualquier caso (`:273`).
- `state` según la tabla de §2, con las mayúsculas y minúsculas exactas.
- `content_path` debe ser **absoluto, existir y ser ≠ `save_path`** en los elementos Completed (§4.1). Puede estar vacío mientras el elemento no esté Completed.
- `ratio_limit: 0` + `ratio: 0` es la receta para mover (§3.5).
- `category` debe coincidir con la categoría configurada en el cliente; el cliente no vuelve a filtrar, así que respeta el parámetro de la consulta.
- `seeding_time` puede omitirse por completo: el cliente recurre a `torrents/properties`, y solo cuando realmente hay un límite de tiempo de seeding activo.

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

Solo se leen `save_path` y `seeding_time` (§1.8). **404 para un hash desconocido**: así es como
`IsTorrentLoaded` indica «todavía no está» (`:110-126`).

### 10.7 `GET /api/v2/torrents/files?hash=<hash>`

```json
[
  { "index": 0, "name": "Some.Show.S01E03.1080p.WEB.h264-GRP/ep3.mkv", "size": 1073741824, "progress": 1, "priority": 1, "is_seed": true, "piece_range": [0, 2047], "availability": 1 }
]
```

Solo se lee `name`, relativo a `save_path`, con separadores `/` (§1.13). El orden importa en la ruta anterior a la 2.6.1: el componente superior de `files[0]` se convierte en la carpeta de salida.

### 10.8 `POST /api/v2/torrents/add`

Petición, en formato urlencoded (un magnet largo llega como multipart en su lugar — §0.3):

```
urls=magnet%3A%3Fxt%3Durn%3Abtih%3A3B1A...&category=tv&stopped=False
```

Respuesta:

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8

Ok.
```

Cualquier cosa que no sea el texto literal `Fails.` es un éxito (§1.7). Un cuerpo 200 vacío también funciona.

### 10.9 `POST /api/v2/torrents/delete`

Solicitud: `hashes=3b1a1469c180f447b77021074dbbccaef62611e7&deleteFiles=true`

Respuesta: `HTTP/1.1 200 OK`, cuerpo vacío. **También devuelve 200 para un hash desconocido** (§5.2).

### 10.10 `POST /api/v2/torrents/createCategory`, `setCategory`, `setShareLimits`, `topPrio`, `setForceStart`

Todos aceptan formularios urlencoded y todos responden `200` con un cuerpo vacío. `topPrio` puede responder **409** para indicar que "la cola está deshabilitada". El cliente ignora solo ese estado (§1.10). `setShareLimits` puede responder **404** para indicar que "no está soportado". También se ignora (§1.9).

---

## 11. Diferencias con qBittorrent real: dónde el modelo de zurg es más estrecho o más amplio {#11-differences-from-real-qbittorrent--where-zurgs-model-is-narrower-or-wider}

### 11.1 No hay seeding, así que la compuerta del límite de seed hay que simularla {#111-there-is-no-seeding-so-the-seed-limit-gate-has-to-be-faked}

El qBittorrent real calcula `ratio` a partir de los bytes que de verdad ha subido, y deja al usuario definir un límite global o por torrent. La comprobación `CanMoveFiles` del cliente existe para no sacar archivos de debajo de un torrent que todavía está cumpliendo una obligación de ratio (`QBittorrent.cs:240-241`). Un backend de debrid no sube nada, nunca. Por eso el shim declara `ratio: 0, ratio_limit: 0`, es decir, un límite por torrent ya cumplido. Eso es veraz en el único sentido en que este campo puede serlo aquí, y además deja los ajustes globales completamente fuera (§3.5).

### 11.2 `content_path` siempre es una carpeta, nunca un archivo {#112-content_path-is-always-a-folder-never-a-file}

En qBittorrent real, `contentPath()` devuelve la **ruta del archivo** para un torrent de un solo archivo
(`torrentimpl.cpp:582-583`). Con `__magic__`, cada release es una carpeta que contiene sus archivos
([magic.md](../guides/magic.md#with-nothing-stored-it-is-__all__s-releases-as-real-folders)), incluso un release de un solo archivo.

Consecuencias, todas a favor del cliente:

- `ProcessPath` siempre toma la rama de **carpeta** (`DownloadedEpisodesImportService.cs:80-90`),
  nunca la rama de archivo (`:92-102`). La rama de carpeta es la que aplica `FilterPaths`,
  `ShouldDeleteFolder` y el parseo del nombre de carpeta, así que el filtro de extras y el
  fallback del título de carpeta están siempre activos.
- Los rechazos por archivo de `ProcessFile` (extensión peligrosa, ejecutable o no soportada, prefijo `._`; §7.4)
  siguen siendo alcanzables, pero a través del filtro de extensión de `GetVideoFiles` en vez de la rama de nivel superior.
- El recorrido `GetImportItem` anterior a 2.6.1 (§4.2) también funcionaría, ya que `files[0].name` siempre lleva el
  nombre de la carpeta del release, pero no hay motivo para reportar una versión tan antigua.

Lo único que hay que hacer bien: como siempre es una carpeta, `content_path` es siempre
`save_path + "/" + <release folder>` y por tanto nunca es igual a `save_path`. La
advertencia `DownloadClientQbittorrentTorrentStatePathError` (§4.1) es estructuralmente inalcanzable, lo cual es
el resultado correcto, no un accidente en el que confiar.

### 11.3 `name` no es el título capturado, y puede cambiar {#113-name-is-not-the-grabbed-title-and-it-can-change}

Qbittorrent real informa el nombre a partir de los metadatos del torrent, y ese nombre no cambia. El nombre de zurg
viene de la biblioteca:

- Real-Debrid renombra los releases cuyo nombre de archivo activa su bloqueo 451 (`WEB-DL`, las etiquetas `Rip` y unos
  cuantos pares fuente-codec con punto, según se midió el 2026-10-14). Mira la sección RD 451 del
  `CLAUDE.md` del monorepo.
- zurg añade un sufijo cuando dos releases chocan con el mismo nombre, y una reparación reconstruye un release con
  un nuevo id de torrent.
- El nombre se lee de la biblioteca en cada consulta, así que puede cambiar **entre consultas** para un id que
  el \*arr ya está siguiendo.

Nada de eso rompe el seguimiento, porque el seguimiento se indexa por `DownloadId` (el infohash) y no por el nombre. Lo que sí rompe es la ruta de análisis de títulos de §7.1. De ahí salen dos reglas:

1. **Indexa por el infohash que calculó el \*arr**, nunca por nada interno de zurg. Es la única unión entre el grab, el historial de grabs y la consulta.
2. **Mantén parseable el nombre de la carpeta `__magic__`**, porque es el respaldo que lee la rama de carpetas (`DownloadedEpisodesImportService.cs:184`).

### 11.4 No hay progreso ni fase de metadatos {#114-there-is-no-progress-and-no-metadata-phase}

There is nothing to download, so there is no meaningful `progress`, `eta`, `dlspeed`, or `metaDL`
period — the same limitation the SAB endpoint documents ([sabnzbd.md](../guides/sonarr-radarr.md), *Lo que funciona, y
lo que no*: "No progress. A job is queued or it is completed"). The natural mapping is: **Queued**
(`queuedDL`) while the library does not list the release yet, **Completed** (`pausedUP`) once it does
*and its file sizes have settled*, with `size` taken from whatever the backend declares so the queue
entry is not blank.

No uses `metaDL` para el estado de espera a menos que `dht: true` también se reporte: solo es Queued en
ese caso (`:288-297`). `queuedDL` es incondicional y no lleva ningún mensaje.

No uses `stalledDL`, `error` ni `missingFiles` para una espera transitoria: los tres son **Warnings**
(§2) y aparecen en la cola como problemas.

### 11.5 Borrar oculta; no destruye {#115-deleting-hides-it-does-not-destroy}

`torrents/delete?deleteFiles=true` en qBittorrent real elimina el torrent y ejecuta `rm -rf` sobre sus datos.
Aquí solo debe borrar el registro: el release sigue sirviéndose desde el torrent del proveedor, y la
carpeta que quería el \*arr ya desapareció sola, porque se marcó a sí misma como eliminada a través del mount (§5.2,
[magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)). Este es justo el razonamiento que
registra `deleteFromHistory` de `internal/sabnzbd` en `internal/sabnzbd/api.go:596-609`.

### 11.6 Todo lo que el cliente puede pedir y que no tiene nada a lo que aplicarse {#116-everything-the-client-can-ask-for-that-has-nothing-to-apply-to}

`sequentialDownload`, `firstLastPiecePrio`, `contentLayout`, `stopped`/`paused`, `setForceStart`,
`topPrio`, `setShareLimits`, `dlLimit`/`upLimit`: acéptalos, responde 200 y no apliques nada. Solo dos
tienen consecuencias observables si se rechazan: `topPrio` (el 409 se ignora, cualquier otro código avisa) y
`setShareLimits` (el 404 se ignora), y ninguno de los dos bloquea una descarga.

`contentLayout` merece una nota: el ajuste existe en las *arr precisamente para obligar a qBittorrent a
mantener una carpeta de nivel superior, de modo que `content_path != save_path`. Con `__magic__` el layout
siempre es una carpeta de todas formas (§11.2), así que el parámetro no tiene efecto y el operador puede dejarlo en Default.

## 12. Lista de verificación de implementación (14 puntos) {#12-implementation-checklist-14-points}

1. **Solo API v2.** Responde a `/api/v2/app/webapiVersion` con `2.11.2`, y devuelve **404** en `/version/api` para que la sonda v1 falle limpiamente.
2. **Autenticación:** acepta una cabecera `Authorization: Bearer <key>`, un `Authorization: Basic` enviado de antemano, una cookie `SID` o no requiere nada. Responde a `POST /api/v2/auth/login` con **200 + `Ok.` + `Set-Cookie: SID=…`**; responde `Fails.` (sigue siendo 200) si las credenciales son incorrectas, nunca con un 401. No exijas `Referer` ni `Origin`.
3. **Los errores son códigos HTTP, no JSON.** 403 significa "volver a iniciar sesión" y se reintenta una vez; un segundo 403 aparece como un error de conexión, no de autenticación. 404 tiene significado en `torrents/properties` (hash desconocido) y en `torrents/setShareLimits` (no soportado); 409 tiene significado en `torrents/topPrio` (colas desactivadas). Todo lo demás debe devolver 200.
4. **Analiza ambas codificaciones de formulario en `torrents/add`:** urlencoded, y multipart cuando algún valor supera los 1024 bytes o se sube un `.torrent`. Acepta `True`/`False` además de `true`/`false` en todos los booleanos.
5. **`torrents/info` devuelve un array; `torrents/categories` devuelve un objeto** con `savePath` en camelCase. Respeta el parámetro de consulta `category`, porque el cliente no vuelve a filtrar.
6. **Hashes: en minúsculas en todas las respuestas y comparados sin distinguir mayúsculas en todas las peticiones**, y siempre el infohash que calculó el \*arr a partir del magnet o del `.torrent`. `torrents/properties` es la única ruta que puede recibir el hash con las mismas mayúsculas que usó `torrents/info`.
7. **La receta de mover:** `state: "pausedUP"`, `ratio: 0`, `ratio_limit: 0`, `seeding_time_limit: -2`, `inactive_seeding_time_limit: -2`. Con menos que esto, la importación es una **copia**: una descarga completa de la release. Documenta que la opción "Remove Completed" del \*arr debe quedar activada, porque el shim no puede compensarla.
8. **`content_path` debe ser absoluto, debe existir en el host del \*arr y no puede ser igual a `save_path`.** Defínelo solo cuando la release sea realmente importable: listada y con sus tamaños de archivo estables. Hasta entonces, informa `queuedDL` y deja que el cliente siga consultando; no hay límite de reintentos.
9. **`save_path`** (de `app/preferences`, además de cualquier `savePath` de categoría) debe existir como directorio en el host del \*arr, o `RemotePathMappingCheck` lanzará un error. No necesita ser escribible. Nunca emitas un `savePath` que empiece por `//`.
10. **Mantén verde la prueba de conexión:** `dht: true`, `queueing_enabled: true`, `max_ratio_enabled: false`, `max_seeding_time_enabled: false`, `max_ratio_act: 0` (entero), y o bien crea previamente las categorías configuradas, o respeta `createCategory` y refléjalo en la siguiente respuesta de `torrents/categories`.
11. **`torrents/delete` elimina solo el registro y nada más.** Ignora `deleteFiles` para el torrent del proveedor, exactamente igual que `deleteFromHistory` de `internal/sabnzbd` ignora `del_files` (`internal/sabnzbd/api.go:596-609`). Responde 200 para un hash desconocido. Acepta `setCategory` y registra la nueva categoría.
12. **Espera que el \*arr ejecute él mismo `rm -rf` sobre la carpeta de la release** tras una importación con Move (`DownloadedEpisodesImportService.cs:209-223`). Eso se convierte en un tombstone `__magic__`, y después llamará a `torrents/delete`. Ambas cosas son normales; ninguna destruye nada.
13. **Usa solo los nombres de estado de §2, con las mayúsculas exactas.** Un nombre desconocido no lanza una excepción aquí (a diferencia de SAB), pero sí registra un log y se asume Downloading. Nunca uses `stalledDL`, `error` ni `missingFiles` para una espera transitoria: los tres son Warnings.
14. **No pongas una carpeta raíz en la carpeta de salida ni por encima de ella.** Con `save_path` = `/mnt/zurg/__magic__/__all__`, usa `/mnt/zurg/__magic__/tv` y `/mnt/zurg/__magic__/movies` como carpetas raíz, y guarda las releases en `/mnt/zurg/__magic__/__all__/<release>`. Si no, `SeriesPathExists`/`MoviePathExists` rechaza la importación directamente (§7.4) y `DownloadClientRootFolderCheck` de Radarr se queja en cada inicio.
