# qBittorrent-Web-API-Vertrag, wie Sonarr und Radarr ihn nutzen (develop) {#qbittorrent-web-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Quelle der Wahrheit: Dateien, die von `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...` und von `qbittorrent/qBittorrent/master` am **2026-08-27** abgerufen wurden. Jede Zeilennummer unten wurde aus diesen Dateien abgelesen.

Das ist das Gegenstück zu [sabnzbd-client-contract.md](sabnzbd-client-contract.md). Dort steht, warum `internal/sabnzbd` so antwortet, wie es antwortet. Dieses Dokument ist die Spezifikation, die ein qBittorrent-Shim erfüllen muss, *bevor* er geschrieben wird. So funktionieren ein Grab, ein Poll, ein Import **als Verschieben** und die Bereinigung nach dem Import in beiden Clients. Wo sich die beiden Clients Technik teilen (die HTTP-Schicht, der JSON-Serializer, `DiskTransferService`, die Health-Checks), verweist dieses Dokument auf dieselben Zeilen, statt die Analyse zu wiederholen.

Sofern ein Abschnitt nichts anderes sagt, **sind die qBittorrent-Dateien der beiden Repos identisch, abgesehen von der Umbenennung `Tv*` → `Movie*`**, und:

| Datei | Zeilennummern |
|---|---|
| `QBittorrent.cs` (in beiden 746 Zeilen) | **stimmen Zeile für Zeile überein** |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **byte-identisch**, stimmen Zeile für Zeile überein |
| `QBittorrentSettings.cs` (in beiden 91 Zeilen) | stimmen Zeile für Zeile überein |
| `QBittorrentProxyV2.cs`, `QBittorrentProxyV1.cs` | Sonarr hat in Zeile 13 eine Leerzeile, die Radarr fehlt (geprüft: Sonarr `:12` ist der Kommentar `// API https://…`, `:13` ist leer, `:14` ist `public class QBittorrentProxyV2`; die Klassendeklaration bei Radarr steht in `:13`). **Sonarr-Zeile N = Radarr-Zeile N−1 für N ≥ 14.** |
| `QBittorrentProxySelector.cs` | gleich, ab Zeile 3 |
| `QBittorrentFixture.cs` | umsortiert, nicht verschoben, daher pro Repo angegeben |

Die Pfade lauten in beiden `src/NzbDrone.Core/Download/Clients/QBittorrent/...`. Die Zitate unten sind **Sonarr-Zeilennummern**, sofern nicht anders gekennzeichnet. Den vollständigen Diff findest du in §9.

Hier geht es nirgends um Spekulation über qBittorrent selbst. Jede Aussage beschreibt, was der *Client* tut. Wo eine Aussage das eigene Verhalten von qBittorrent betrifft, wird auf `qbittorrent/qBittorrent` master verwiesen. Wo es um die Laufzeitsemantik von .NET oder Newtonsoft geht, steht das ausdrücklich dabei.

---

## 0. Regeln auf Transportebene (diese fallen zuerst auf) {#0-transport-level-rules-these-bite-first}

### 0.1 Der Client wählt vor allem anderen v1 oder v2 {#01-the-client-picks-v1-or-v2-before-it-does-anything-else}

`QBittorrentProxySelector.FetchProxy` (`QBittorrentProxySelector.cs:80-95`):

```csharp
if (_proxyV2.IsApiSupported(settings)) { return Tuple.Create(_proxyV2, _proxyV2.GetApiVersion(settings)); }
if (_proxyV1.IsApiSupported(settings)) { return Tuple.Create(_proxyV1, _proxyV1.GetApiVersion(settings)); }
throw new DownloadClientException("Unable to determine qBittorrent API version");
```

`QBittorrentProxyV2.IsApiSupported` (`QBittorrentProxyV2.cs:28-70`) sendet eine **nicht authentifizierte**
`GET /api/v2/app/webapiVersion`-Anfrage mit `SuppressHttpError = true` und entscheidet dann:

| Antwort | Ergebnis |
|---|---|
| `404` | nicht v2 → weiter zu v1 |
| `403` | **v2 wird unterstützt** (`:44-47`). Das ist die Antwort für „noch nicht eingeloggt“. |
| `401` | `DownloadClientException("Failed to connect to qBittorrent. Check your settings and qBittorrent configuration.")` (`:49-52`) |
| jeder andere Wert `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` (`:54-57`) |
| `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to qBittorrent, certificate validation failed.")` (`:63-66`) |
| `200` | v2 wird unterstützt |

`QBittorrentProxyV1.IsApiSupported` (`QBittorrentProxyV1.cs:27-59`) macht dasselbe gegen
`GET /version/api`. Beachte: **ohne führendes `/api/v2`**, und 401 wird dort *nicht* gesondert behandelt.

Das Paar `(proxy, version)` wird **10 Minuten** lang zwischengespeichert, mit `{Host}_{Port}` als Schlüssel
(`QBittorrentProxySelector.cs:68-78`). `GetProxy(settings, force: true)` entfernt es aus dem Cache. Genau das macht
der Verbindungstest (`QBittorrent.cs:435`, `:519`), und das prüft die Fixture (Sonarr `QBittorrentFixture.cs:986-998`, Radarr `:984-996`).

**Ein Shim sollte `/api/v2/app/webapiVersion` beantworten und niemals die v1-Routen anbieten.** v1 ist die
API vor 4.1 (`/version/api`, `/query/torrents`, `/command/download`, …). Für eine neue Implementierung ist sie nur unnötiger Ballast.
Außerdem kann sie den Import-Pfad gar nicht bedienen: `GetLabels` wirft `NotSupportedException("qBittorrent api v1 does not support getting all torrent categories")`
(`QBittorrentProxyV1.cs:236-239`), und `SetTorrentSeedingConfiguration` ist ein No-Op (`:241-244`).
Der Rest dieses Dokuments betrifft nur API v2. Die v1-Routenübersicht steht zur Vollständigkeit in §1.17.

### 0.2 Aufbau der URL {#02-url-shape}

`QBittorrentProxyV2.BuildRequest` (`QBittorrentProxyV2.cs:341-359`):

```csharp
var requestBuilder = new HttpRequestBuilder(settings.UseSsl, settings.Host, settings.Port, settings.UrlBase)
{
    LogResponseContent = true,
    StoreRequestCookie = false
};
```

- Basis-URL: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-65`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; `UrlBase` bekommt einen führenden `/`, falls keiner vorhanden ist.
- `Resource("/api/v2/…")` (`HttpRequestBuilder.cs:244-256`) entfernt den führenden `/` und hängt den Rest an. Die vollständige URL sieht also so aus: `{scheme}://{host}:{port}{urlBase}/api/v2/{group}/{method}`.
- **Kein `Accept`-Header.** `BuildRequest` ruft nie `.Accept(...)` auf, und der Konstruktor von `HttpRequest` setzt `Headers.Accept` nur, wenn `httpAccept != null` ist (`src/NzbDrone.Common/Http/HttpRequest.cs:14,30-32`). Mach das nicht von `Accept` abhängig.
- `StoreRequestCookie = false`: Der Cookie-Speicher wird vom Proxy verwaltet, nicht von der HTTP-Schicht.

### 0.3 GET mit Query vs. POST mit Formular — und wann das Formular zu multipart wird {#03-get-with-query-vs-post-with-form--and-when-the-form-becomes-multipart}

Reine Leseaufrufe verwenden `AddQueryParam` (`HttpRequestBuilder.cs:306-317`) bei einem GET. Schreibende Aufrufe verwenden `.Post()` plus `AddFormParameter` / `AddFormUpload`.

`ApplyFormData` (`HttpRequestBuilder.cs:150-242`) wählt die Kodierung aus:

```csharp
var shouldSendAsMultipart = FormData.Any(v => v.ContentType != null || v.FileName != null || v.ContentData.Length > 1024);
```

- Jeder `AddFormUpload` (der `FileName` und `ContentType` setzt) erzwingt **`multipart/form-data`**
  (`:379-395`, `:220`).
- **Jeder einzelne Formularwert, der länger als 1024 Bytes ist, erzwingt ebenfalls Multipart** (`:162`). Ein Magnet-URI mit einer langen Tracker-Liste überschreitet diese Grenze, daher kommt `POST /api/v2/torrents/add` je nach Magnet entweder als `application/x-www-form-urlencoded` *oder* `multipart/form-data` an.
  **Ein Shim muss auf dieser Route beide Varianten parsen.**
- Sonst: `application/x-www-form-urlencoded`, Werte werden mit `Uri.EscapeDataString(Encoding.UTF8.GetString(...))` escaped (`:230`).

Der Multipart-Writer ist selbst gebaut (`:164-227`) und schreibt `Content-Disposition: form-data; name="…"` (plus `; filename="…"` und eine `Content-Type:`-Zeile bei Uploads), eine Leerzeile, die rohen Bytes und dann `\r\n`. Die Boundary ist `-----------------------------{ticks:x14}` (`:166`).

**Die Formatierung von Booleans ist eine Falle.** `AddFormParameter` speichert `Convert.ToString(value, CultureInfo.InvariantCulture)` (`HttpRequestBuilder.cs:373`), und `Convert.ToString(bool)` von .NET liefert **`"True"` / `"False"`, großgeschrieben**. Also landet `request.AddFormParameter("stopped", false)` (`QBittorrentProxyV2.cs:258`) als `stopped=False` auf der Leitung, nicht als `stopped=false`. Das echte qBittorrent kommt damit klar, weil `Utils::String::parseBool` (`src/base/utils/string.cpp:108-116`) ohne Beachtung der Groß-/Kleinschreibung vergleicht. **Ein Shim muss `True`/`False` genauso akzeptieren wie `true`/`false`.** Wo der Client den String fest einträgt, ist er kleingeschrieben — `deleteFiles` ist `"true"` (`QBittorrentProxyV2.cs:198`) und der `value` von `setForceStart` ist `"true"`/`"false"` (`:337`) — daher tauchen wirklich beide Schreibweisen auf.

Zahlen laufen über denselben Invariant-Culture-Pfad, daher verwendet `ratioLimit=1.5` immer `.` als Dezimaltrennzeichen (`QBittorrentProxyV2.cs:234`, `HttpRequestBuilder.cs:373`).

### 0.4 Authentifizierung — drei Ebenen, die alle gleichzeitig aktiv sein können {#04-authentication--three-layers-all-of-which-can-be-live-at-once}

`BuildRequest` (`QBittorrentProxyV2.cs:349-356`):

```csharp
if (settings.ApiKey.IsNotNullOrWhiteSpace())
    requestBuilder.Headers["Authorization"] = $"Bearer {settings.ApiKey}";
else if (settings.Username.IsNotNullOrWhiteSpace() || settings.Password.IsNotNullOrWhiteSpace())
    requestBuilder.NetworkCredential = new BasicNetworkCredential(settings.Username, settings.Password);
```

1. **API-Key** → `Authorization: Bearer <key>` bei jeder Anfrage. `ProcessRequest` nimmt außerdem einen Kurzschluss-Pfad, bei dem sich nie angemeldet wird (`:371-395`). `QBittorrentSettingsValidator` verbietet Benutzername/Passwort zusammen mit einem Key (`QBittorrentSettings.cs:16-21`).
2. **Benutzername/Passwort** → `BasicNetworkCredential`. `ManagedHttpDispatcher` macht daraus einen **vorab gesendeten** (preemptive) `Authorization: Basic base64(user:pass)`-Header bei *jeder* Anfrage, auch bei `auth/login` selbst (`src/NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:81-89`, Kommentar: "Manually set header to avoid initial challenge response").
3. **Cookie-Sitzung** → `AuthenticateClient` (`QBittorrentProxyV2.cs:430-494`).

`AuthenticateClient`, genau so:

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

Was das für einen Shim bedeutet:

- `POST /api/v2/auth/login`, Body `username=…&password=…`, `application/x-www-form-urlencoded`.
- Antworte mit **HTTP 200** und genau dem Body `Ok.` sowie einem `Set-Cookie: SID=…`-Header. So macht es auch das echte qBittorrent (Wiki, *Login*: "Upon success, the response will contain a cookie with your SID").
- **Ein leerer Body wird auch akzeptiert** (`:479` überspringt bei `IsNotNullOrWhiteSpace`). Alles andere, also `"Fails."`, `"ok"` oder JSON, ist ein Authentifizierungsfehler. Der v1-Proxy ist strenger und verlangt genau `Ok.` (`QBittorrentProxyV1.cs:371`).
- Bei einem HTTP-Fehler von `auth/login` gilt: 401 oder 403 → `DownloadClientAuthenticationException`, alles andere → `DownloadClientException` (`:463-473`). Eine `WebException` → `DownloadClientUnavailableException`.
- Das Cookie wird pro `{baseUrl}:{user}:{pass}` für die Lebensdauer des Cache-Eintrags des Prozesses zwischengespeichert. Erneuert wird es nur, wenn eine Anfrage mit 403 zurückkommt (§0.5).
- **`Referer` und `Origin` werden nie gesendet.** Das Wiki sagt API-Nutzern, dass sie diese setzen sollen ("Note: Set `Referer` or `Origin` header to the exact same domain and port as used in the HTTP query `Host` header"), Sonarr macht das aber nicht. Ein Shim darf sie nicht voraussetzen.
- Wenn **gar keine Zugangsdaten konfiguriert** sind, kehrt `AuthenticateClient` sofort zurück und es wird nichts gesendet: kein Login, kein Cookie, kein `Authorization`. Ein Shim ohne Authentifizierung funktioniert also.

### 0.5 Welche HTTP-Statuscodes als Fehler gelten {#05-which-http-statuses-are-treated-as-errors}

`HttpClient.Execute` (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`) wirft, wenn
`response.HasHttpError` — `(int)StatusCode >= 400` (`src/NzbDrone.Common/Http/HttpResponse.cs:54`) —
außer `SuppressHttpError` ist gesetzt oder der Status steht in `SuppressHttpErrorStatusCodes`. 429 wird zu `TooManyRequestsException` (`:115`); alles andere wird zu `HttpException` (`:119`).

`QBittorrentProxyV2.ProcessRequest` (`:369-428`) umhüllt das dann. Es gibt zwei getrennte Pfade:

**API-Key-Pfad** (`:371-395`):

| Status | Ergebnis |
|---|---|
| 401, 403 | `DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.")` |
| jeder andere `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` |
| alles andere, was geworfen wird | `DownloadClientException("Failed to connect to qBittorrent, please check your settings.")` |

**Cookie-Pfad** (`:397-427`):

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

- **403 bedeutet „Sitzung abgelaufen, neu anmelden“** — es wird einmal unterdrückt, der Client meldet sich neu an und versucht es erneut. Das ist die Schleife, die der Sitzungsablauf von qBittorrent selbst erzeugt, und ein Shim kann sie genauso nutzen.
- Die **Wiederholungsanfrage wird aus dem Builder neu aufgebaut, und der trägt kein `SuppressHttpErrorStatusCodes`** — dieses Feld wurde bei `:401` auf der *Anfrage* gesetzt, nicht auf dem Builder. Ein zweites 403 wirft also `HttpException` und landet als `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` — **nicht** als Authentifizierungsfehler. Ein Shim, der dauerhaft 403 antwortet, erzeugt in der UI einen verwirrenden Verbindungsfehler statt „Authentication Failure“.
- Wenn keine Zugangsdaten konfiguriert sind, wirft der erneute Login-Versuch bei `:411` sofort `DownloadClientAuthenticationException` (`:434-437`).

**Jeder erfolgreiche Aufruf muss HTTP 200 mit genau dem Body sein, den der Client erwartet.** Diese API hat nirgendwo eine JSON-Fehlerhülle; anders als bei SAB sind Fehler hier HTTP-Statuscodes.

### 0.6 Einstellungen des Deserializers {#06-deserializer-settings}

Alle qBittorrent-Payloads laufen über `NzbDrone.Common.Serializer.Json` (`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`) — **Newtonsoft**, dieselbe Instanz, die der SAB-Client nutzt. Deshalb gilt [sabnzbd-client-contract.md §0.3](sabnzbd-client-contract.md) wortwörtlich:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Was das für die qBittorrent-Modelle konkret bedeutet:

| Modellelement | Bindet an | Warum |
|---|---|---|
| `QBittorrentTorrent.Hash/Name/Size/Progress/Eta/State/Label/Category/Ratio` | `hash`, `name`, `size`, `progress`, `eta`, `state`, `label`, `category`, `ratio` | camelCase-Resolver; Newtonsoft passt außerdem ohne Berücksichtigung der Groß-/Kleinschreibung |
| `SavePath`, `ContentPath`, `RatioLimit`, `SeedingTime`, `SeedingTimeLimit`, `InactiveSeedingTimeLimit`, `LastActivity` | `save_path`, `content_path`, `ratio_limit`, `seeding_time`, `seeding_time_limit`, `inactive_seeding_time_limit`, `last_activity` | explizites `[JsonProperty]` (`QBittorrentTorrent.cs:24-45`) |
| `QBittorrentLabel.Name/SavePath` | `name`, `savePath` | **kein** `[JsonProperty]` — camelCase-Resolver. qBittorrents `torrents/categories` verwendet hier wirklich camelCase, anders als alles andere |
| `QBittorrentPreferences.*` | alle explizit `[JsonProperty]` in snake_case (`QBittorrentPreferences.cs:16-44`) | |
| `QBittorrentMaxRatioAction` | `max_ratio_act` | kein Converter pro Property, daher gilt der globale `StringEnumConverter`. `AllowIntegerValues` ist standardmäßig true, also **den Integer senden**, so wie es echtes qBittorrent macht. Ein String müsste camelCase sein (`"pause"`, `"remove"`), und ein unbekannter Name wirft eine Exception |

`NullValueHandling.Ignore` gilt auch beim **Lesen**: Ein JSON-`null` lässt das Member auf seinem Konstruktorwert. Zusammen mit den Standardwerten in den Modellen ist ein **fehlendes oder null**-Feld nicht dasselbe wie eine 0:

| Feld | Standardwert bei fehlendem/null-Wert | Quelle |
|---|---|---|
| `ratio_limit` | `-2f` | `QBittorrentTorrent.cs:33` |
| `seeding_time_limit` | `-2` | `:39` |
| `inactive_seeding_time_limit` | `-2` | `:42` |
| `seeding_time` | `null` (`long?`) | `:36` |
| `queueing_enabled` | **`true`** | `QBittorrentPreferences.cs:41` |
| alles andere | CLR-Standardwert (`0`, `false`, `null`) | |

`Eta` ist ein `System.Numerics.BigInteger` (`QBittorrentTorrent.cs:17`, Kommentar "QBit contains a bug exceeding ulong limits"). Sonarrs Fixture legt `18446744073709335000` als parsebar fest (Sonarr `QBittorrentFixture.cs:974-984`, Radarr `:973-982`).

`Json.Deserialize<T>` wirft die `JsonReaderException` erneut, aber mit einer freundlicheren Meldung (`Json.cs:39-50`). Keiner der qBittorrent-Proxy-Aufrufe nutzt `TryDeserialize`. Also **wirft ein fehlerhafter oder falsch aufgebauter Body eine Exception aus dem Proxy** und wird an der Aufrufstelle zu einer unbehandelten Exception. Bei `GetItems()` bricht dadurch der gesamte Poll ab.

### 0.7 Jedes `version >=`-Gate an einer Stelle {#07-every-version--gate-in-one-place}

`ProxyApiVersion` ist `_proxySelector.GetApiVersion(Settings)` (`QBittorrent.cs:50`), also die gecachte `app/webapiVersion`. Die Gates:

| Gate | Wo | Wirkung unterhalb der Schwelle |
|---|---|---|
| `>= 1.5` | `QBittorrent.cs:436` | Test schlägt fehl: "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| `>= 1.6` | `:445` | Test schlägt fehl, wenn eine Kategorie konfiguriert ist: "Category is not supported" |
| `>= 2.0` | `:379` (`GetStatus`), `:520` (`TestCategory`) | Die `savePath` der Kategorie wird nicht gelesen, und Kategorien werden weder geprüft noch angelegt |
| `>= 2.6.1` | `:314` | `OutputPath` wird **nicht** aus `content_path` übernommen; `GetImportItem` geht stattdessen `torrents/files` durch (§4.2) |
| `>= 2.8.1` | `:79`, `:136` | Share-Limits können nicht über `torrents/add` laufen; sie werden danach mit `torrents/setShareLimits` gesetzt |
| `>= 2.11.0` | `QBittorrentProxyV2.cs:253` | `torrents/add` sendet `paused=` statt `stopped=` |

`Version.Parse` (`QBittorrentProxyV2.cs:75`) braucht mindestens `major.minor`. Eine nackte `"2"` wirft eine `FormatException`, und diese Exception wird außerhalb jedes `try` im Proxy ausgelöst. Sie entkommt also komplett aus `GetApiVersion`. Melde etwas wie `2.11.2`.

**Empfohlener Wert für einen Shim: `2.11.2`.** Damit werden alle Gates passiert, `content_path` landet auf dem `torrents/info`-Pfad (die einzig sinnvolle Import-Route), und beim Hinzufügen wird die Schreibweise `stopped=` von qBittorrent 5.x verwendet.

## 1. Jeder Endpunkt, in der Reihenfolge, in der der Client sie aufruft {#1-every-endpoint-in-the-order-the-client-calls-them}

Schnittstelle: `IQBittorrentProxy` (`QBittorrentProxySelector.cs:9-30`). Implementierung: `QBittorrentProxyV2`. Jeder Aufruf in `QBittorrent.cs` ist unter `:49-741` aufgelistet.

### 1.1 `GET /api/v2/app/webapiVersion` — `GetApiVersion` (`QBittorrentProxyV2.cs:72-78`)

Anfrage: keine Parameter. Wird zuerst unauthentifiziert gesendet (als Probe, §0.1), dann authentifiziert.

Antwort: **Klartext**, eine Versionszeichenfolge, die von `Version.Parse` geparst wird. Kein JSON, keine Anführungszeichen.

Aufgerufen von: die Proxy-Probe (`:31`), `GetItems` (`QBittorrent.cs:220`), `GetStatus` (`:374`),
`TestConnection` (`:435`), `TestCategory` (`:519`) und — der, den man leicht übersieht —
`AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:253`). Das heißt, **jedem `torrents/add` geht ein eigener `app/webapiVersion`-Aufruf voraus**, wenn der Anfangsstatus Start oder Stop ist (also immer, außer der Nutzer hat Force Start gewählt).

### 1.2 `GET /api/v2/app/version` — `GetVersion` (`QBittorrentProxyV2.cs:80-87`)

Antwort: Klartext, `v` vorne abgeschnitten (`:83`). Kommentar: `// eg "4.2alpha"`.

**Wird nie aufgerufen.** Sie steht im Interface (`QBittorrentProxySelector.cs:13`), aber nirgends in
`QBittorrent.cs` wird sie aufgerufen (geprüft gegen jede `Proxy.`/`_proxySelector.`-Referenz, `:49-741`). Implementier sie trotzdem. Das kostet nichts, und wer den Shim später mal anfasst, greift bestimmt danach.

### 1.3 `POST /api/v2/auth/login`

Siehe §0.4. Formular: `username`, `password`. Antwort `200` + `Ok.` + `Set-Cookie: SID=…`.

### 1.4 `GET /api/v2/app/preferences` — `GetConfig` (`QBittorrentProxyV2.cs:89-95`)

Anfrage: keine Parameter. Antwort: ein JSON-Objekt, das in `QBittorrentPreferences` deserialisiert wird.

**Jeder Schlüssel, den der Client liest** (`QBittorrentPreferences.cs:14-45`). Alles andere im Body wird nicht angeschaut, und zusätzliche Schlüssel werden ignoriert:

| JSON-Schlüssel | C# | Typ | Gelesen von |
|---|---|---|---|
| `save_path` | `SavePath` | `string` | `GetStatus` → `OutputRootFolders` (`QBittorrent.cs:377`) |
| `max_ratio_enabled` | `MaxRatioEnabled` | `bool` | `HasReachedSeedLimit` (`:639`), `RemovesCompletedDownloads` (`:415`) |
| `max_ratio` | `MaxRatio` | `float` | `HasReachedSeedLimit` (`:641`) |
| `max_seeding_time_enabled` | `MaxSeedingTimeEnabled` | `bool` | `HasReachedSeedingTimeLimit` (`:663`), `RemovesCompletedDownloads` (`:415`) |
| `max_seeding_time` | `MaxSeedingTime` | `long`, **Minuten** | `:665`, `:415` |
| `max_inactive_seeding_time_enabled` | `MaxInactiveSeedingTimeEnabled` | `bool` | `HasReachedInactiveSeedingTimeLimit` (`:727`) |
| `max_inactive_seeding_time` | `MaxInactiveSeedingTime` | `long`, **Minuten** | `:729` |
| `max_ratio_act` | `MaxRatioAction` | Enum als Ganzzahl: `Pause=0, Remove=1, EnableSuperSeeding=2, DeleteFiles=3` (`QBittorrentPreferences.cs:5-11`) | `RemovesCompletedDownloads` (`:415`) |
| `queueing_enabled` | `QueueingEnabled` | `bool`, **Standardwert `true`** | `TestPrioritySupport` (`:572`) |
| `dht` | `DhtEnabled` | `bool` | `AddFromMagnetLink` (`:73`), der `metaDL`-Zweig (`:288`) |

Aufgerufen von: `AddFromMagnetLink` (`:73`), `GetItems` (`:221`), `GetStatus` (`:375`), `TestConnection` (`:467`), `TestPrioritySupport` (`:570`). Es wird **nicht** gecacht, also wird es bei jeder Abfrage neu geholt.

`RemovesCompletedDownloads` (`QBittorrent.cs:412-416`) ist das abgeleitete Flag:

```csharp
var minimumRetention = 60 * 24 * 14; // 14 days in minutes
return (config.MaxRatioEnabled || (config.MaxSeedingTimeEnabled && config.MaxSeedingTime < minimumRetention))
    && (config.MaxRatioAction == QBittorrentMaxRatioAction.Remove || config.MaxRatioAction == QBittorrentMaxRatioAction.DeleteFiles);
```

Es fließt sowohl in den Verbindungstest (`:468`) als auch in den Health Check `DownloadClientRemovesCompletedDownloadsCheck` (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:44-53`) ein. Wenn `max_ratio_enabled: false` und `max_seeding_time_enabled: false` gesetzt sind, ist es egal, was `max_ratio_act` sagt, das Flag ist immer false. Sende `max_ratio_act: 0` trotzdem mit.

### 1.5 `GET /api/v2/torrents/categories` — `GetLabels` (`QBittorrentProxyV2.cs:221-225`)

Anfrage: keine Parameter.

Antwort: ein JSON-**Objekt**, `{"<name>": {"name": "...", "savePath": "..."}}`, das in
`Dictionary<string, QBittorrentLabel>` deserialisiert wird. Achte auf das **camelCase `savePath`**, siehe §0.6 und das Beispiel *Get all categories* im Wiki. Ein Array führt hier zu einem Fehler.

Lies zwei Stellen genau:

1. `TestCategory` (`QBittorrent.cs:525-553`), nur die Zugehörigkeit des Schlüssels (§6.3).
2. `GetStatus` (`:379-402`). Der `savePath` der konfigurierten Kategorie wird zum Stammordner für die Ausgabe des Download-Clients:

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

Ein **relativer** `savePath` wird an den globalen `save_path` angehängt. Ein absoluter Pfad ersetzt ihn. Ein `savePath`, der mit `//` beginnt, wird in einen UNC-Pfad mit Backslashes umgewandelt. Sonarrs Fixture legt `"//server/store/downloads"` → `\\server\store\downloads` fest (Sonarr `QBittorrentFixture.cs:563-589`, Radarr `:562-588`). **Gib niemals ein führendes `//` aus.** Die einfachste korrekte Lösung ist `"savePath": ""`. Dann bleibt der Stammordner beim globalen `save_path`.

### 1.6 `POST /api/v2/torrents/createCategory` — `AddLabel` (`QBittorrentProxyV2.cs:213-219`)

Form: `category=<name>`. **`savePath` wird nicht gesendet**. Der Client setzt nie einen Speicherpfad für die Kategorie.
Der Response-Body wird ignoriert. Nur ein Status ohne Fehler zählt.

Wird nur von `TestCategory` aufgerufen (`QBittorrent.cs:529`, `:543`), wenn die Kategorie fehlt.
`torrents/editCategory` und `torrents/removeCategories` werden **nie aufgerufen**.

### 1.7 `POST /api/v2/torrents/add` — `AddTorrentFromUrl` / `AddTorrentFromFile`

`AddTorrentFromUrl` (`QBittorrentProxyV2.cs:146-166`): Formularfeld **`urls`** = der Magnet-URI.
`AddTorrentFromFile` (`:168-188`): Formular-Upload **`torrents`**, Dateiname
`{CleanFileName(release title)}.torrent` (`TorrentClientBase.cs:199`),
`Content-Type: application/octet-stream` (`HttpRequestBuilder.cs:379`).

Beide hängen danach `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:243-284`) an:

| Formularfeld | Wert | Bedingung | Zeile |
|---|---|---|---|
| `category` | `Settings.TvCategory` / `MovieCategory` | Kategorie nicht leer | `:245-248` |
| `stopped` (webapi `>= 2.11.0`) oder `paused` (darunter) | `False` für Start, `True` für Stop | `InitialState` ist Start oder Stop — **Force Start sendet keins von beiden** | `:251-264` |
| `sequentialDownload` | `True` | Einstellung `SequentialOrder` aktiv | `:266-269` |
| `firstLastPiecePrio` | `True` | Einstellung `FirstAndLast` aktiv | `:271-274` |
| `contentLayout` | `"Original"` oder `"Subfolder"` | Einstellung `ContentLayout` ist Original oder Subfolder; **Default sendet nichts** | `:276-283` |

und, wenn Share-Limits konfiguriert sind *und* webapi `>= 2.8.1` (`QBittorrent.cs:79`, `:136`), zusätzlich `AddTorrentSeedingFormParameters(request, seedConfiguration)` (`QBittorrentProxyV2.cs:227-241`):

| Formularfeld | Wert | Bedingung |
|---|---|---|
| `ratioLimit` | `seedConfiguration.Ratio` oder `-2` | nur wenn nicht `-2` (`:232`) |
| `seedingTimeLimit` | `seedConfiguration.SeedTime.TotalMinutes` oder `-2` | nur wenn nicht `-2` (`:237`) |

**Alles andere, was das Wiki für `torrents/add` dokumentiert, wird nie gesendet**: kein `savepath`, kein `cookie`, kein `tags`, kein `skip_checking`, kein `root_folder`, kein `rename`, kein `upLimit`, kein `dlLimit` und kein `autoTMM`. Beim Hinzufügen gibt es keinen `priority`-Parameter — die Warteschlangen-Priorität läuft über einen separaten `topPrio`-Aufruf (§1.10).

Antwortbehandlung (`:159-165`, `:181-187`):

```csharp
var result = ProcessRequest(request, settings);
// Note: Older qbit versions returned nothing, so we can't do != "Ok." here.
if (result == "Fails.") { throw new DownloadClientException("Download client failed to add torrent by url"); }
```

Also: **Eine 200 mit beliebigem Body außer dem wörtlichen `Fails.` gilt als Erfolg.** `Ok.` ist die übliche Antwort.
Ein HTTP 415 (laut Wiki „torrent file is not valid“) wird über `:389` zu einer `DownloadClientException`.

**Die Download-ID kommt nicht aus diesem Aufruf.** Sie wird client-seitig berechnet, bevor die Anfrage gesendet wird:

- Magnet → `MagnetLink.Parse(magnetUrl).InfoHash.ToHex()` (`TorrentClientBase.cs:224`)
- `.torrent` → `_torrentFileInfoReader.GetHashFromTorrentFile(torrentFile)` (`:200`)

und `AddFromMagnetLink` / `AddFromTorrentFile` geben genau diesen `hash` unverändert zurück (`QBittorrent.cs:130`, `:187`). **Der Shim muss den Torrent genau unter diesem Infohash ablegen**, sonst verliert Sonarr den Grab — `TorrentClientBase.cs:206-212` und `:238-244` loggen dazu nur eine Debug-Zeile.
Bei Magneten wird zuerst die DHT-Voraussetzung geprüft:

```csharp
if (!Proxy.GetConfig(Settings).DhtEnabled && !magnetLink.Contains("&tr="))
    throw new NotSupportedException("Magnet Links without trackers not supported if DHT is disabled");   // :73-76
```

Der Aufrufer macht daraus `ReleaseDownloadException("Magnet not supported by download client…")`, wenn kein `.torrent`-Fallback existiert (`TorrentClientBase.cs:111-119`). **Melde `dht: true`.**

Nach dem Hinzufügen fragt `WaitForTorrent` (`QBittorrent.cs:190-214`) `IsTorrentLoaded` **10-mal mit 100 ms Pause** ab — aber nur, wenn noch Folgearbeit anfällt (Share-Limits nach dem Hinzufügen, Topp-Priorität oder Force Start; `:86`, `:143`). Die Fehlermeldung sagt „within 500 ms“, die Schleife läuft aber tatsächlich 10 × 100 ms. So oder so gibt sie auf und liefert den Hash zurück (`:212-213`).

### 1.7a Wie lange der Client auf `torrents/add` wartet — **100 Sekunden**, gemessen am 30.08.2026 {#17a-how-long-the-client-waits-for-torrentsadd--100-seconds-measured-2026-08-30}

Ausgelesen aus `Sonarr/Sonarr@32a5d492` und `Radarr/Radarr@40bb746c` (beide `develop`) am 2026-08-30.
Das begrenzt alles, was ein Shim synchron im Add-Aufruf macht. Deshalb lohnt es sich, das zu belegen und nicht einfach anzunehmen.

Auf dem qBittorrent-Pfad setzt nichts ein Timeout. Der Wert wird deshalb über vier Ebenen durchgereicht und landet bei festen 100 s:

| Schritt | Sonarr `path:line` | Radarr `path:line` | Was passiert |
|---|---|---|---|
| der Add-Aufruf | `QBittorrentProxyV2.cs:146-150`, `:168-172` | `:145-149`, `:167-171` | baut die Anfrage und setzt kein Timeout |
| der Builder | `NzbDrone.Common/Http/HttpRequestBuilder.cs:104-116` | gleiche Datei `:104-116` | `Apply()` hat keine `RequestTimeout`-Zeile, und die Klasse hat keine solche Property |
| der Feld-Default | `NzbDrone.Common/Http/HttpRequest.cs:52` | `:54` | Auto-Property wird im Konstruktor nie gesetzt, also `TimeSpan.Zero` |
| der Dispatcher | `NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:70-79` | `:68-77` | aus `Zero` wird `cts.CancelAfter(TimeSpan.FromSeconds(100))` |

```csharp
using var cts = new CancellationTokenSource();
if (request.RequestTimeout != TimeSpan.Zero) { cts.CancelAfter(request.RequestTimeout); }
else { /* The default for System.Net.Http.HttpClient */ cts.CancelAfter(TimeSpan.FromSeconds(100)); }
```

`RequestTimeout` und `Timeout` tauchen in beiden Repos nirgends unter
`src/NzbDrone.Core/Download/Clients/QBittorrent/` auf, und `HttpRequestBuilder` bietet keine Möglichkeit, einen Wert zu setzen. Ein Shim kann sich also per Konfiguration keine zusätzliche Zeit verschaffen.

Daraus folgen fünf Dinge.

- **Die 100 s stammen vom Abbruch-Token von Sonarr, nicht vom Timer von .NET.** Der zugrunde liegende Handler wird mit `Timeout = Timeout.InfiniteTimeSpan` gebaut (`ManagedHttpDispatcher.cs:183` bei Sonarr, `:180` bei Radarr). Das Token ist also die einzige Grenze. Es wird sowohl an `SendAsync` als auch an `ReadAsByteArrayAsync` übergeben (`:115`, `:127`). Es deckt damit Verbindungsaufbau, Request-Body, Response-Header und Response-Body ab.
- **Ein Timeout wird dem Nutzer als Verbindungsfehler gemeldet.** Bei Ablauf wird `new WebException("Http request timed out", …)` ausgelöst (`:142-145`). `ProcessRequest` verpackt das als `DownloadClientException("Failed to connect to qBittorrent, please check your settings.", ex)` (`QBittorrentProxyV2.cs:424-427`). Ein Shim, der länger als 100 s blockiert, sieht also falsch konfiguriert aus statt langsam. Und die *arrs erfahren nie, dass der Add noch lief.
- **Es gibt kein separates Connect-Timeout und kein größeres Budget für einen Multipart-Upload.** `SocketsHttpHandler.ConnectTimeout` wird nie gesetzt. Eine Ausnahme gibt es: Der erste IPv6-Versuch im Prozesslebenslauf ist auf 2 s begrenzt (`ManagedHttpDispatcher.cs:23`, `:288-295`). Danach wird innerhalb derselben 100 s auf IPv4 gewechselt. Eine `.torrent`-Datei wird komplett in ein Byte-Array gepuffert (`HttpRequestBuilder.cs:220-221`, `ManagedHttpDispatcher.cs:103`) und unter demselben Token gesendet.
- **300 s gibt es, aber auf einem anderen Pfad.** `HttpClient.cs:285` setzt `request.RequestTimeout = TimeSpan.FromSeconds(300)` innerhalb von `DownloadFileAsync`. Diese Methode holt die `.torrent`-Datei vom Indexer. Sie erreicht nie einen Aufruf an einen Download-Client.
- **Deluge zeigt, dass es die Überschreibung gibt, und qBittorrent verzichtet darauf.** `DelugeProxy.cs:222` macht `requestBuilder.PostProcess += r => r.RequestTimeout = TimeSpan.FromSeconds(15)`. `BuildRequest` von qBittorrent hat keine solche Zeile. Das ist der direkte Beleg dafür, dass die 100 s geerbt und nicht gewählt sind.

**Radarr ist identisch.** Ein Diff des Timeout-Blocks (Radarr `:68-78` gegen Sonarr `:70-80`) ist byte-identisch. Der einzige Unterschied in der Kette ist, dass Radarr `ex` an die `WebException` übergibt, Sonarr dagegen `ex.InnerException`.

**Konsequenz für den Shim.** Jede synchrone Entscheidung innerhalb von `torrents/add` teilt sich ein einziges 100-s-Budget. Die *arrs können nicht unterscheiden, ob etwas noch arbeitet oder nicht erreichbar ist. Die Deadline pro Versuch, multipliziert mit der Anzahl der versuchten Provider, plus jedes Zeitfenster für eine Cache-only-Prüfung, muss deshalb deutlich darunter bleiben. Die gemessenen Latenzen der Provider, aus denen dieses Budget gebaut wird, stehen in [torrent-lifecycle.md](torrent-lifecycle.md).

Eine Anmerkung zur Vollständigkeit: Die 100 s gelten pro Dispatcher-Aufruf. Jeder Hop einer automatischen Weiterleitungskette bekommt also ein frisches Budget (`HttpClient.cs:43` begrenzt die Kette auf 5). Die Retry-Strategie in `DownloadClientBase.cs:30-44` gilt hier **nicht**. Sie wird nur beim Holen der `.torrent`-Datei vom Indexer verwendet (`TorrentClientBase.cs:142-144`).

### 1.8 `GET /api/v2/torrents/properties?hash=<hash>` — `IsTorrentLoaded` / `GetTorrentProperties`

`IsTorrentLoaded` (`QBittorrentProxyV2.cs:110-126`) ruft sie mit `LogHttpError = false` auf und behandelt **jede** Exception als "nicht geladen".

`GetTorrentProperties` (`:128-135`) deserialisiert in `QBittorrentTorrentProperties` (`QBittorrentTorrent.cs:48-57`). **Drei Felder, und nur zwei davon werden verwendet:**

| JSON key | C# | Verwendet für |
|---|---|---|
| `hash` | `Hash` | wird gelesen, aber nie verwendet |
| `save_path` | `SavePath` | der Pfad vor 2.6.1 in `GetImportItem` (`QBittorrent.cs:354`) |
| `seeding_time` | `SeedingTime` (`long`, **Sekunden**) | `FetchTorrentDetails` (`:739-744`) |

**Die Schreibweise der Hashes ist hier uneinheitlich, und das ist wichtig.** Alle anderen Aufrufe wandeln in Kleinschreibung um (`item.DownloadId.ToLower()` bei `:335`, `:346`, `:353`; `hash.ToLower()` bei `:97`, `:109`, `:121`, `:198`). `FetchTorrentDetails` übergibt `torrent.Hash` aber **unverändert** (`:741`), also genau das, was der Shim in `torrents/info` zurückgibt. Echtes qBittorrent liefert Hashes in Kleinschreibung, deshalb tritt das dort nie auf. Sonarrs Fixture hält diese Asymmetrie fest, indem sie `GetTorrentProperties("HASH", …)` mit dem Wert in Großschreibung mockt (Sonarr `QBittorrentFixture.cs:669-675`, Radarr `:668-674`). **Gib Hashes in `torrents/info` in Kleinschreibung zurück, und vergleiche `?hash=` ohne Beachtung der Groß- und Kleinschreibung.**

`FetchTorrentDetails` wird nur aus `HasReachedSeedingTimeLimit` (`:700`) aufgerufen. Das passiert nur, wenn tatsächlich ein Seeding-Zeitlimit gilt. Ein Shim, der keine Seeding-Zeitlimits deklariert, sieht diesen Aufruf beim Polling also gar nicht. Gebraucht wird er trotzdem für `IsTorrentLoaded`, die Bereitschafts-Probe nach dem Hinzufügen: **404 für einen unbekannten Hash, 200 + JSON für einen bekannten.**

Das Ergebnis wird pro `{Host}{Port}{Hash}` 5 Minuten lang gecacht (`:678`, `:689`, `:695`, `:708`). Das Fixture prüft, dass es beim Abfragen zweimal hintereinander nur einmal abgerufen und nicht zweimal geholt wird (Sonarr `QBittorrentFixture.cs:905-920`, Radarr `:904-919`).

### 1.9 `POST /api/v2/torrents/setShareLimits` — `SetTorrentSeedingConfiguration` (`:286-308`)

Formular: `hashes=<lowercase hash>`, dann `AddTorrentSeedingFormParameters(request, seedConfiguration, always: true)`
— mit `always: true` werden **immer** sowohl `ratioLimit` als auch `seedingTimeLimit` gesendet, auch wenn der Wert `-2` ist
(`:232`, `:237`). `inactiveSeedingTimeLimit` wird nie gesendet.

Ein **404** wird verschluckt (`:298-307`, Kommentar: "setShareLimits was added in api v2.0.1"). Jeder andere Fehler wird weitergereicht, aber die Aufrufstelle fängt ihn ab und schreibt eine Warnung ins Log (`QBittorrent.cs:95-102`, `:152-159`).

Das wird nur aufgerufen, wenn der Indexer eine Seed-Konfiguration liefert *und* die webapi-Version `< 2.8.1` ist. Bei einem shim mit `2.11.2` werden Share-Limits stattdessen über `torrents/add` übertragen, und diese Route wird für einen Grab nie genutzt. Implementiere sie als No-op, die 200 zurückgibt.

### 1.10 `POST /api/v2/torrents/topPrio` — `MoveTorrentToTopInQueue` (`:310-330`)

Form: `hashes=<lowercase hash>`.

Ein **409 Conflict** wird stillschweigend geschluckt (`:320-329`, Kommentar: "qBittorrent rejects all Prio commands with 409:
Conflict if Options -> BitTorrent -> Torrent Queueing is not enabled"). Der v1-Proxy schluckt stattdessen **403**
(`QBittorrentProxyV1.cs:255-264`). Alles andere wird abgefangen und am Aufrufort als Warnung protokolliert
(`QBittorrent.cs:107-114`, `:164-171`). Das Fixture prüft, dass ein Fehler hier den Grab nicht zum Scheitern bringt
(Sonarr `QBittorrentFixture.cs:525-542`, Radarr `:524-541`).

Wird nur aufgerufen, wenn die Priority-Einstellung für Recent/Older auf `First` steht (`QBittorrentPriority.First = 1`,
`QBittorrentPriority.cs:5-6`). Der Standardwert ist `Last = 0`.

### 1.11 `POST /api/v2/torrents/setForceStart` — `SetForceStart` (`:332-339`)

Form: `hashes=<lowercase hash>`, `value=true` (der wörtliche Kleinbuchstaben-String, `:337`).

Nur aufgerufen, wenn `InitialState` `ForceStart` ist (`QBittorrentState.cs:10-11`, `QBittorrent.cs:82`, `:117-127`). Fehler werden abgefangen und als Warnung ausgegeben (`:123-126`).

### 1.12 `GET /api/v2/torrents/info[?category=<cat>]` — `GetTorrents` (`:97-108`)

**Der einzige Parameter, der jemals gesendet wird, ist `category`, und nur wenn die Einstellung nicht leer ist**
(`:100-103`). Kein `filter`, kein `hashes`, kein `sort`, kein `reverse`, kein `limit`, kein `offset`, kein `tag`.
Der Client filtert danach **nicht** noch einmal nach Kategorie, anders als der SAB-Client, der doppelt filtert. Ein Shim, der `category` ignoriert, gibt Radarr also Sonarrs Torrents zurück.

Das Feld `category` in der Antwort ist aus einem zweiten Grund wichtig: Ein Torrent, für den der \*arr **keine Grab-Historie hat**, wird komplett übersprungen, außer er hat eine. Siehe `CompletedDownloadService.Check` (`CompletedDownloadService.cs:84-88`):

```csharp
if (historyItem == null && trackedDownload.DownloadItem.Category.IsNullOrWhiteSpace())
{
    trackedDownload.Warn("Download wasn't grabbed by Sonarr and not in a category, Skipping.");
    return;
}
```

`Category` ist `category`, wenn nicht leer, sonst `label` (`QBittorrent.cs:231`).

Antwort: ein JSON-**Array**. Jedes verwendete Feld und was daraus wird:

| JSON-Schlüssel | C#-Typ | Einheiten | Wird zu |
|---|---|---|---|
| `hash` | `string` | | `DownloadId = torrent.Hash.ToUpper()` (`QBittorrent.cs:230`) — **in Großbuchstaben**, und bei jedem weiteren Aufruf klein geschrieben zurückgegeben |
| `name` | `string` | | `Title = torrent.Name` (`:232`) — siehe §7.1 für alles, was davon gesteuert wird |
| `size` | `long` | Bytes | `TotalSize` (`:233`); außerdem `RemainingSize = (long)(size * (1.0 - progress))` (`:235`) |
| `progress` | `double` | 0..1 | `RemainingSize` (`:235`) |
| `eta` | `BigInteger` | Sekunden | `RemainingTime` über `GetRemainingTime` (`:236`, `:614-628`) |
| `state` | `string` | | `Status`, `Message` und die eine Hälfte der `CanMoveFiles`-Bedingung (`:242-312`) — §2 |
| `category` | `string` | | `Category`, bevorzugt (`:231`) |
| `label` | `string` | | `Category`, Ersatz, wenn `category` leer ist (`:231`). Feld vor 3.3.5; qBittorrent 5 liefert es nicht mehr |
| `ratio` | `float` | | `SeedRatio` (`:237`), `HasReachedSeedLimit` (`:634`, `:641`) |
| `ratio_limit` | `float`, Standard `-2` | | `HasReachedSeedLimit` (`:632-645`) |
| `seeding_time_limit` | `long`, Standard `-2` | Minuten | `HasReachedSeedingTimeLimit` (`:659-670`) |
| `inactive_seeding_time_limit` | `long`, Standard `-2` | Minuten | `HasReachedInactiveSeedingTimeLimit` (`:723-736`) |
| `last_activity` | `long` | Unix-Sekunden | `HasReachedInactiveSeedingTimeLimit` (`:736`) |
| `seeding_time` | `long?`, Standard null | Sekunden | `HasReachedSeedingTimeLimit` (`:672-676`) — der Kommentar in `QBittorrentTorrent.cs:36` sagt, dass er "not provided by the list api" ist, aber der Client nutzt ihn, wenn vorhanden, was einen `torrents/properties`-Aufruf spart |
| `save_path` | `string` | | mit `content_path` verglichen (`:316`) |
| `content_path` | `string` | | `OutputPath` bei webapi `>= 2.6.1` (`:318`) — §4 |

`GetRemainingTime` (`:614-628`):

```csharp
if (torrent.Eta < 0 || torrent.Eta > 365 * 24 * 3600) { return null; }   // > 31,536,000 s
if (torrent.Eta == 8640000) { return null; }                            // qBittorrent's "unknown"
return TimeSpan.FromSeconds((int)torrent.Eta);
```

Und ein Completed-Eintrag hat danach `RemainingTime` auf `TimeSpan.Zero` gesetzt (`:273`).

`torrents/info` wird bei jedem `RefreshMonitoredDownloads` abgerufen (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:94`). Das wird außerdem 5 s nach relevanten Ereignissen entprellt in die Befehlswarteschlange eingereiht (`:53`).

### 1.13 `GET /api/v2/torrents/files?hash=<hash>` — `GetTorrentFiles` (`:137-144`)

Antwort: ein JSON-Array, das in `List<QBittorrentTorrentFile>` deserialisiert wird. Die Klasse hat **genau ein
Feld**: `Name` (`QBittorrentTorrent.cs:59-62`), das an `name` gebunden ist. Es enthält den Dateipfad **relativ zum
Speicherpfad**, mit `/` als Trennzeichen auf jedem Betriebssystem ("QBittorrent liefert `/` als Pfadtrenner auch unter
Windows", `QBittorrent.cs:358`).

Wird nur von `GetImportItem` (`:346`) aufgerufen, und nur dann, wenn `OutputPath` noch leer ist, also bei webapi
`< 2.6.1` oder wenn `content_path` leer zurückkommt. `index`, `size`, `progress`, `priority`, `is_seed`,
`piece_range` und `availability` werden alle ignoriert.

Ein **leeres Array** wird behandelt: `_logger.Debug("No files found for torrent {0} in qBittorrent")`, und das Item wird
unverändert zurückgegeben (`:347-351`). Dadurch schlägt dann `ValidatePath` fehl.

### 1.14 `POST /api/v2/torrents/setCategory` — `SetTorrentLabel` (`:204-211`)

Form: `hashes=<lowercase hash>`, `category=<post-import category>`.

Das wird nur von `MarkItemAsImported` (`QBittorrent.cs:52-69`) aufgerufen, und nur wenn die optionale
`TvImportedCategory` / `MovieImportedCategory`-Einstellung nicht leer ist und sich von der Hauptkategorie unterscheidet. Eine `DownloadClientException` wird abgefangen und als Warnung ausgegeben:
"Failed to set post-import torrent label \"{0}\" for {1} in qBittorrent. Does the label exist?"
(`:62-67`). §5.1.

### 1.15 `POST /api/v2/torrents/delete` — `RemoveTorrent` (`:190-202`)

Form: `hashes=<lowercase hash>`, plus `deleteFiles=true` **nur wenn `removeData` true ist**
(`:196-199`), also der wörtliche Kleinbuchstaben-String und nicht `Convert.ToString(bool)`.

`QBittorrent.RemoveItem` (`:333-336`) ist die gesamte Implementierung:

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    Proxy.RemoveTorrent(item.DownloadId.ToLower(), deleteData, Settings);
}
```

**Es ruft `DeleteItemData` nicht auf.** Das ist der Unterschied zum SAB-Client, der den Job-Ordner selbst über das Dateisystem löscht
(`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`; siehe
[sabnzbd-client-contract.md §5.3](sabnzbd-client-contract.md)). Hier ist das Löschen der Daten komplett Aufgabe des Download-Clients. §5.

### 1.16 Endpunkte, die der Client nie anfasst {#116-endpoints-the-client-never-touches}

Gar nicht in der Oberfläche vorhanden, werden also nie aufgerufen: `torrents/pause`, `torrents/resume`, `torrents/stop`,
`torrents/start`, `torrents/setLocation`, `torrents/rename`, `torrents/recheck`,
`torrents/reannounce`, `torrents/filePrio`, `torrents/setDownloadLimit`, `torrents/setUploadLimit`,
`torrents/toggleSequentialDownload`, `torrents/setAutoManagement`, `torrents/editCategory`,
`torrents/removeCategories`, Tags, RSS, Suche, `app/setPreferences`, `app/defaultSavePath`,
`app/shutdown`, `sync/maindata`, `transfer/*`, `auth/logout`. Pausieren und Fortsetzen gibt es nur als
`paused=`/`stopped=`-Formularfeld bei `torrents/add`.

In der Oberfläche vorhanden, aber nie aus `QBittorrent.cs` aufgerufen: `GetVersion` (§1.2).

### 1.17 Die v1-Routenübersicht (der Vollständigkeit halber; nicht implementieren) {#117-the-v1-route-map-for-completeness-do-not-implement}

`QBittorrentProxyV1.cs`: `/version/api` (`:30`, `:64`, der Client stellt `"1."` vor das, was zurückkommt, `:65`), `/version/qbittorrent` (`:73`), `/query/preferences` (`:81`),
`/query/torrents?label=&category=` (`:89-94`, **beide** Parameter), `/query/propertiesGeneral/{hash}`
(`:103`, `:120`), `/query/propertiesFiles/{hash}` (`:128`), `/command/download` (`:136`),
`/command/upload` (`:166`), `/command/delete` oder `/command/deletePerm` (`:196`, die Unterscheidung delete/deleteFiles sind zwei verschiedene Routen, kein Parameter),
`/command/setCategory` mit einem Fallback auf `/command/setLabel` bei 404 (`:205-225`), `/command/addCategory` (`:230`),
`/command/topPrio` (`:248`), `/command/setForceStart` (`:269`), `/login` (`:345`).

## 2. `state` → `DownloadItemStatus`

`QBittorrent.GetItems` (`:247-312`). Die Zustände sind die eigenen Strings von qBittorrent, erzeugt von `torrentStateToString` (`qBittorrent/src/webui/api/serialize/serialize_torrent.cpp:44-87`).

| `state` | `DownloadItemStatus` | `Message` | Zeile |
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
| `metaDL` | Queued **wenn `dht: true`**, sonst Warning | "qBittorrent is downloading metadata" / "qBittorrent cannot resolve magnet link with DHT disabled" | `:286-299` |
| `forcedMetaDL` | wie `metaDL` | wie oben | `:287` |
| `forcedDL` | Downloading | — | `:301` |
| `moving` | Downloading | — | `:302` |
| `downloading` | Downloading | — | `:303` |
| **alles andere** | **Downloading** | "Unknown download state: {state}" | `:307-311` |

Notes, auf die ein Shim achten muss:

- **Ein unbekannter Zustand wirft keine Exception.** Er schreibt `_logger.Info($"Unknown download state: {torrent.State}")`
  und fällt auf Downloading zurück (`:307-311`). Das ist das Gegenteil vom SAB-Client, wo ein unbekannter
  Statusname im Deserializer eine Exception wirft und den ganzen Poll abbricht. Trotzdem: Schick nur Namen
  aus dieser Tabelle.
- **Nur die Completed-Zustände können importiert werden.** `CompletedDownloadService.Check` kehrt sofort
  zurück, außer `Status == Completed` (`src/NzbDrone.Core/Download/CompletedDownloadService.cs:68-71`).
- **Jeder Completed-Zustand setzt `RemainingTime` auf null** (`:273`, Kommentar "qBittorrent sends
  eta=8640000 for completed torrents").
- `metaDL` / `forcedMetaDL` ist die Phase "Magnet, noch keine Metadaten". Im Client gibt es **kein Timeout**:
  Er bleibt Queued, solange der Shim `metaDL` meldet, und wird von selbst nie zu einem Fehler. Nur
  `dht: false` in `app/preferences` macht daraus eine Warning (`:288`). Die Behandlung fehlgeschlagener
  Downloads in Sonarr eskaliert nach dem Alter des Grabs, nicht nach diesem Zustand.
- `stalledDL` ist die *Warning*, die der Operator bei einem Torrent sieht, der sich nicht bewegt. Ein Shim
  ohne Peer-Konzept sollte es nie verwenden. Eine Warning bei einem verfolgten Download taucht in der Queue
  als Problem auf, und genau das prüft `FailedDownloadService`.
- `error` und `missingFiles` sind absichtlich Warnings, "so failed download handling isn't triggered"
  (`:249`). Wenn ein Shim will, dass Sonarr den Release auf die Blocklist setzt und neu grabbt, ist eine
  Warning **nicht** der richtige Weg dafür.

## 3. Verschieben vs. kopieren — die genaue Bedingung und das Rezept {#3-move-vs-copy--the-exact-condition-and-the-recipe}

### 3.1 Das Gate {#31-the-gate}

`QBittorrent.cs:240-245`, wortwörtlich mit dem Kommentar, der es erklärt:

```csharp
// Avoid removing torrents that haven't reached the global max ratio.
// Removal also requires the torrent to be paused, in case a higher max ratio was set on the torrent itself (which is not exposed by the api).
item.CanMoveFiles = item.CanBeRemoved =
    item.DownloadClientInfo.RemoveCompletedDownloads &&
    torrent.State is "pausedUP" or "stoppedUP" &&
    HasReachedSeedLimit(torrent, config);
```

Drei Bedingungen, alle müssen erfüllt sein:

1. **`RemoveCompletedDownloads`** — die *arr-seitige Einstellung pro Client, nicht etwas, das qBittorrent meldet.
   `DownloadClientDefinition.RemoveCompletedDownloads` ist standardmäßig **`true`**
   (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17`) und wird in der UI als
   „Remove Completed“ angezeigt. Wenn der Nutzer das abschaltet, **werden Importe zu Kopien**, und ein Shim kann dagegen nichts tun. (Ein Move wird aus einem zweiten Grund zu einer Kopie, den der Shim ebenfalls nicht sehen kann: Der Container der \*arr greift über zwei Volumes auf den Download-Ordner und den Root-Ordner zu, wobei `rename()` mit `EXDEV` antwortet und .NET's `File.Move` kopiert und dann löscht. zurg liest beides über die API einer Beschaffungsquelle ab und übernimmt die Kopie danach; siehe `internal/arrlayout` und `internal/handlers/magic_copies.go`.)
2. **`state` ist genau `pausedUP` oder `stoppedUP`.** `uploading`, `stalledUP`, `queuedUP` und `forcedUP` sind zwar Completed, aber nicht verschiebbar — das Fixture hält das fest (Sonarr `QBittorrentFixture.cs:680-689`, Radarr `:679-688`).
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

- Ein **torrent-spezifisches `ratio_limit >= 0`** gewinnt direkt, und das globale Limit wird nicht geprüft. `ratio_limit` ist im eigenen Modell von qBittorrent `-2` = "use global" und `-1` = "unlimited" (`QBittorrentTorrent.cs:32`; Wiki, *Set torrent share limit*).
- `-1` (unlimited) erfüllt keinen der beiden Zweige: `-1 >= 0` ist falsch und `-1 == -2` ist ebenfalls falsch. Ein Torrent ohne Limit kann deshalb durch die Ratio-Regel **nie** verschoben werden.
- Der `0.001f`-Puffer sorgt dafür, dass "reached after rounding" funktioniert. Das Fixture legt fest, dass Ratio `1.1006066990976857` bei Limit `1.0` als erreicht gilt, und ebenso `0.9999` (Sonarr `QBittorrentFixture.cs:715-737`, Radarr `:714-736`).

`HasReachedSeedingTimeLimit` (`:655-717`):

```csharp
if (torrent.SeedingTimeLimit >= 0)        { seedingTimeLimit = torrent.SeedingTimeLimit * 60; }        // minutes -> seconds
else if (torrent.SeedingTimeLimit == -2 && config.MaxSeedingTimeEnabled) { seedingTimeLimit = config.MaxSeedingTime * 60; }
else                                      { return false; }
```

Dann verwendet sie `torrent.SeedingTime`, wenn die Listen-API den Wert mitgeliefert hat (`:672-676`). Andernfalls prüft sie einen 5-Minuten-Cache und ruft bei einem Cache-Miss **`torrents/properties`** für `seeding_time` auf (`:678-716`, `:739-744`). `HasReachedInactiveSeedingTimeLimit` (`:719-737`) hat den gleichen Aufbau, vergleicht aber `now - last_activity` mit `inactive_seeding_time_limit` (oder dem globalen Wert). Dafür braucht sie nie einen zweiten Aufruf.

### 3.3 Was `CanMoveFiles` entscheidet {#33-what-canmovefiles-decides}

`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, series, importItem)`
(`CompletedDownloadService.cs:148-151`), und dann lesen zwei Stellen `CanMoveFiles`:

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

(Radarr: `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, identisch.)

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
`TransferMode.HardLinkOrCopy`, wenn "Use Hardlinks instead of Copy" aktiviert ist, sonst `TransferMode.Copy`
(`:103`, `:107`). `TransferMode` ist `[Flags] None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy=Copy|HardLink`
(`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`).

**Ein fehlgeschlagenes Move fällt nie auf ein Copy zurück.** Die komplette Begründung mit Zeilennummern steht in [sabnzbd-client-contract.md §5.5](sabnzbd-client-contract.md); `DiskTransferService.cs` wird geteilt und ist in beiden Repos byte-identisch. Die Kurzfassung: Der Move-Zweig von `TransferFile` (`src/NzbDrone.Common/Disk/DiskTransferService.cs:360-389`) hat genau einen Copy-Pfad. Dieser wird vorab anhand von `targetMount.DriveFormat == "cifs"` gewählt (`:342`, `:378-385`), nie als Reaktion auf einen Fehler. `TryMoveFileVerified` wirft die Exception weiter (`:487-503`), und `VerifyFile` wirft `IOException("File move incomplete, data loss may have occurred. …")`, wenn die Zielgröße nicht mit der Quellgröße übereinstimmt (`:505-524`).

### 3.4 Mit den Standardwerten von qBittorrent ist der Import ein **Kopiervorgang** {#34-with-qbittorrents-own-defaults-the-import-is-a-copy}

Nimm einen Torrent, den ein Shim naiv meldet – die qBittorrent-Standards, die auch die Modell-Standards sind:

| Feld | Wert | Wirkung |
|---|---|---|
| `state` | `stoppedUP` | Bedingung 2 ✓ |
| `ratio_limit` | `-2` (Standard, `QBittorrentTorrent.cs:33`) | fällt auf den globalen Zweig zurück |
| `max_ratio_enabled` | `false` (qBittorrents eigener Standard; Beispielteil im Wiki `:684`) | globaler Zweig schlägt fehl |
| `seeding_time_limit` | `-2` | braucht `max_seeding_time_enabled` |
| `max_seeding_time_enabled` | `false` (Wiki `:686`) | schlägt fehl |
| `inactive_seeding_time_limit` | `-2` | braucht `max_inactive_seeding_time_enabled` |
| `max_inactive_seeding_time_enabled` | `false` | schlägt fehl |

⇒ `HasReachedSeedLimit` false ⇒ `CanMoveFiles` false ⇒ `copyOnly` true ⇒ `TransferMode.Copy` ⇒ **der
\*arr liest jedes Byte des Releases vom Mount und schreibt es wieder zurück.** Auf einem Debrid-Mount ist
das genau das Ergebnis, das das ganze Design verhindern soll, und es schlägt still fehl – niemand warnt, der Import
dauert einfach Stunden und füllt eine Festplatte.

Das Fixture sichert genau diesen Fall ab:
`should_not_be_removable_and_should_not_allow_move_files_if_max_ratio_is_not_set`
(Sonarr `QBittorrentFixture.cs:691-701`, Radarr `:690-700`) – globale Limits aus, Torrent pausiert, Ratio 1.0, `CanMoveFiles == false`.

### 3.5 Das Rezept {#35-the-recipe}

Für jeden Torrent, den ein Shim per **move** importiert haben will:

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

`ratio_limit: 0` nimmt den ersten Zweig (`0 >= 0` und `0 - 0 <= 0.001`), und die globalen Einstellungen werden nie abgefragt. Deshalb kann `max_ratio_enabled` auf `false` bleiben, und der Health Check `DownloadClientRemovesCompletedDownloadsCheck` bleibt still. Jedes `ratio_limit >= ratio` innerhalb von `0.001` funktioniert; `0`/`0` ist die Variante, die keine Abstimmung braucht.

Zu `pausedUP` vs. `stoppedUP`: **develop behandelt beide gleich**, sowohl im `CanMoveFiles`-Gate (`:244`) als auch in der Status-Map (`:266-267`), und jede Seed-Limit-Fixture ist ein `[TestCase]`-Paar über beide. `stoppedUP` ist die Schreibweise von qBittorrent 5 (`serialize_torrent.cpp:54-55`; `pausedUP` existiert in master nicht mehr). `pausedUP` ist die sicherere Wahl gegenüber *veröffentlichten* \*arr-Builds, denn der `stoppedUP`-Zweig kam mit qBittorrent 5 dazu, und ältere Sonarr-v4- / Radarr-v5-Builds kennen nur `pausedUP`. Dieser letzte Punkt ist eine Schlussfolgerung über ältere Tags und nichts, was die develop-Quellen oben belegen.

Und das liegt nicht in der Hand des Shims: **„Remove Completed“ muss in den Download-Client-Einstellungen des \*arr eingeschaltet bleiben.** Standardmäßig ist es an (`DownloadClientDefinition.cs:17`). Dokumentier das bitte, denn wenn man es ausschaltet, wird jeder Import stillschweigend zu einem vollständigen Download.

## 4. `OutputPath` — woher der \*arr den Import holen soll {#4-outputpath--where-the-arr-is-told-to-import-from}

### 4.1 Der Pfad ab 2.6.1: `content_path` {#41-the-261-path-content_path}

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

Der Warnungstext (`src/NzbDrone.Core/Localization/Core/en.json`):

> Unable to Import. Path matches client base download directory, it's possible 'Keep top-level folder'
> is disabled for this torrent or 'Torrent Content Layout' is NOT set to 'Original' or 'Create Subfolder'?

Regeln, die ein Shim erfüllen muss:

- `content_path` **darf nicht gleich** `save_path` sein. Gleichheit ist der Fehlerfall, kein Fallback: Der Eintrag wird zu einer Warning und wird nie importiert.
- `content_path` muss **absolut und gültig für das Betriebssystem sein, auf dem der \*arr läuft**. `CompletedDownloadService.ValidatePath` (`CompletedDownloadService.cs:295-313`) lehnt alles andere ab, mit der Meldung "[{0}] is not a valid local path. You may need a Remote Path Mapping."
- Der Pfad muss auf dem \*arr-Host als **Ordner oder Datei** existieren. `ProcessPath` (`DownloadedEpisodesImportService.cs:80-105`) prüft zuerst `FolderExists`, dann `FileExists`, und wenn keines zutrifft, landet man bei `LogInaccessiblePathError` und einem leeren Ergebnis.
- Sende keinen leeren `content_path`. Er "unterscheidet sich" von einem nicht leeren `save_path`, daher wird `OutputPath` auf ein leeres `OsPath` gesetzt. `GetImportItem` fällt dann auf den `torrents/files`-Durchlauf (§4.2) zurück, weil `item.OutputPath.IsEmpty` true ist (`:341-344`).
- Dieser Block läuft nur für **Completed**-Einträge. `content_path` ist also erst dann wichtig, wenn der Status zu den Completed-Zuständen aus §2 gehört.

Was echtes qBittorrent dort einträgt, steht in `TorrentImpl::contentPath()` (`qBittorrent/src/base/bittorrent/torrentimpl.cpp:577-587`):

```cpp
Path TorrentImpl::contentPath() const
{
    if (!hasMetadata())    return {};
    if (filesCount() == 1) return (actualStorageLocation() / filePath(0));   // the FILE, not a folder
    const Path rootPath = this->rootPath();
    return (rootPath.isEmpty() ? actualStorageLocation() : rootPath);
}
```

mit `rootPath()` = `actualStorageLocation() / Path::findRootFolder(filePaths())` (`:565-575`). Das heißt: Bei einem Torrent mit **einer einzigen Datei** ist `content_path` die Datei selbst. Bei einem Torrent mit mehreren Dateien und einem gemeinsamen Hauptordner ist es dieser Ordner. Bei einem Torrent mit mehreren Dateien **ohne** gemeinsamen Hauptordner ist es `save_path`. Genau dieser Fall ist es, vor dem die Warnung des Clients mit `content_path == save_path` warnt.

`RemapRemoteToLocal(Settings.Host, …)` wendet die Remote Path Mappings des Nutzers an, die anhand des konfigurierten **Host**-Strings zugeordnet werden. Läuft der \*arr in einem Container und meldet der Shim den Pfad des Hosts, braucht der Betreiber ein Mapping. Siehe dazu [sabnzbd.md](../guides/sonarr-radarr.md#8-if-your-arr-is-in-docker), das unverändert gilt.

### 4.2 Der Pfad vor 2.6.1: `GetImportItem` durchläuft `torrents/files` {#42-the-pre-261-path-getimportitem-walks-torrentsfiles}

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

Er nimmt **nur `files[0].name`**, geht bis zur obersten Pfadkomponente hoch und hängt diese an `properties.save_path` an. Das Fixture prüft alle drei Formen (Sonarr `QBittorrentFixture.cs:317-421`, Radarr `:296-400`):

| `files[0].name` | `save_path` | `OutputPath` |
|---|---|---|
| `Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` |
| `Folder/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Folder` |
| `Droned.S01.12/E01.mkv` (+ `E02.mkv`) | `/Torrents` | `/Torrents/Droned.S01.12` |

Beachte die dritte Zeile: Hier zählt die Wurzel von `files[0]`, nicht eine berechnete gemeinsame Wurzel. Deshalb muss ein Shim auf diesem Pfad die Dateien so auflisten, dass der erste Eintrag den Release-Ordner enthält. Ein Shim, der webapi `>= 2.6.1` meldet, kommt hier gar nicht erst an. Das ist ein weiterer Grund, `2.11.2` zu melden.

`previousImportAttempt` ist ein Parameter von `GetImportItem` (`:338`) und **wird von dieser Implementierung nie gelesen**. Ein fehlgeschlagener Versuch wird nirgends gemerkt.

### 4.3 Wenn der Pfad falsch ist, und wie oft er erneut versucht wird {#43-when-the-path-is-wrong-and-how-often-it-is-retried}

Auf diesem Pfad gibt es weder Backoff noch Versuchslimit.

- `CompletedDownloadService.Check` läuft bei jedem Refresh für jeden verfolgten Download im Status `Downloading` oder
  `ImportBlocked` (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:125-129`).
- `Check` ruft **zuerst** `SetImportItem` auf (`CompletedDownloadService.cs:73`). Das ist `_provideImportItemService.ProvideImportItem(...)` → `client.GetImportItem(...)`
  (`:290-293`, `src/NzbDrone.Core/Download/ProvideImportItemService.cs:17-22`). Dadurch wird `OutputPath` bei jedem Poll neu aus der *aktuellen* `torrents/info`-Zeile abgeleitet.
- Fehler in `ValidatePath` (`:295-313`) erzeugen eine Warnung und lassen den Status auf `Downloading`. Der nächste Poll fängt also wieder von vorne an:
  - leerer Output-Pfad → "Download doesn't contain intermediate path, Skipping."
  - Pfad mit dem falschen Betriebssystem → "[{0}] is not a valid local path. You may need a Remote Path Mapping. …"
- `Import` ruft beim Start ebenfalls `SetImportItem` auf (`:130`), bevor `trackedDownload.ImportItem.OutputPath.FullPath` erneut gelesen wird (`:147`). Angestoßen wird es aus dem Status `ImportPending` heraus durch `DownloadProcessingService`
  (`src/NzbDrone.Core/Download/DownloadProcessingService.cs:61-63`). Ein fehlgeschlagener Import lässt den Status auf `ImportPending` (`:158`) oder setzt ihn auf `ImportBlocked` (`:196`). In beiden Fällen wird erneut verarbeitet.
- Ein Pfad, der existiert, aber nichts Importierbares enthält, erzeugt "No files found are eligible for import in {0}" (`:162`) und bleibt auf `ImportPending`.

**Folge für einen Shim: `content_path` darf eine Zeit lang falsch sein.** Melde den Torrent als Downloading (oder Queued), bis der Ordner tatsächlich existiert und die Dateigrößen endgültig sind. Dann fragt der Client einfach weiter ab. Ein zu früh gemeldetes Completed kostet einen Importversuch gegen einen Ordner, der noch nicht bereit ist. Schlimmer noch: Der \*arr könnte eine nur teilweise geschriebene Datei verschieben und danach an `VerifyFile` scheitern, nachdem die Quelle bereits leer geräumt wurde. Genau diese Falle ist auch für den SAB-Endpunkt dokumentiert ([sabnzbd.md](../guides/sonarr-radarr.md), *What happens on a grab*, Schritt 5).

## 5. Die Abfolge nach dem Import {#5-the-post-import-sequence}

### 5.1 Was wann ausgelöst wird, in dieser Reihenfolge {#51-what-fires-in-order}

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

und `RemoveFromDownloadClient` (`:87-103`) lautet:

```csharp
_logger.Debug("[{0}] Removing download from {1} history", ...);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);             // :92  deleteData: TRUE
trackedDownload.DownloadItem.Removed = true;
```

Die Reihenfolge der Aufrufe nach einem erfolgreichen Import sieht also so aus:

1. **`POST /api/v2/torrents/setCategory`** — nur wenn eine Kategorie nach dem Import konfiguriert ist
   (`QBittorrent.cs:52-69`). Standardmäßig wird er übersprungen.
2. Vor beiden und komplett außerhalb des Download-Clients: **der \*arr verschiebt die Datei**, danach kann `ProcessFolder` **den Quellordner selbst löschen**
   (`DownloadedEpisodesImportService.cs:209-223`, Radarr `DownloadedMovieImportService.cs:226-240`):

   ```csharp
   if (importMode == ImportMode.Move &&
       importResults.Any(i => i.Result == ImportResultType.Imported) &&
       ShouldDeleteFolder(directoryInfo, series))
   {
       _diskProvider.DeleteFolder(directoryInfo.FullName, true);   // recursive
   }
   ```

   `ShouldDeleteFolder` (`:108-153`) bricht ab, wenn im Ordner noch eine Videodatei liegt, die erkannt wird und kein Sample ist (`:117-133`), oder wenn eine `.rar` größer als 10 MB übrig ist (`:135-139`). Nach einem erfolgreichen Verschieben einer einzelnen Datei greift keines davon, der Ordner **wird** also entfernt. Eine `IOException` wird abgefangen und auf Debug-Level geloggt (`:219-222`).
3. **`POST /api/v2/torrents/delete`** mit `hashes=<lowercase hash>&deleteFiles=true`
   (`QBittorrent.cs:335`, `QBittorrentProxyV2.cs:190-202`).

Zwei weitere Ereignisse landen beim selben `RemoveFromDownloadClient(…, true)`:

- `DownloadFailedEvent` (`DownloadEventHub.cs:26-46`), abhängig von der Einstellung `RemoveFailedDownloads` pro Client (Standard `true`, `DownloadClientDefinition.cs:18`). Beachte: `TrackedDownload.Fail()` setzt `DownloadItem.CanBeRemoved = true` ohne Bedingung (`src/NzbDrone.Core/Download/TrackedDownloads/TrackedDownload.cs:39-46`, Kommentar: "Set CanBeRemoved to allow the failed item to be removed from the client") — **also wird ein fehlgeschlagener Download gelöscht, auch wenn das Seed-Limit-Gate etwas anderes sagt.**
- `DownloadCanBeRemovedEvent` (`:71-85`).

Eine `NotSupportedException` aus `RemoveItem` wird zu "Removing item not supported by your download client ({0})." herabgestuft (`:95-98`). Jede andere Exception wird als Fehler geloggt, und das Element wird *nicht* als Removed markiert, es wird also beim nächsten Poll erneut versucht (`:99-102`).

### 5.2 Was der Shim bei `deleteFiles=true` tun muss {#52-what-the-shim-must-do-with-deletefilestrue}

Das ist dieselbe Entscheidung, die `internal/sabnzbd` schon für `mode=history&name=delete` getroffen hat, aus demselben Grund. Aus `internal/sabnzbd/api.go:596-609`:

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

Der qBittorrent-Fall hat dieselbe Form, mit einem Haken: Bei dieser API ist das Löschen der Daten Aufgabe des *Clients* und nicht des \*arr, weil `RemoveItem` **nicht** `DeleteItemData` aufruft (§1.15). Der \*arr hat aber den Ordner selbst schon in Schritt 2 oben gelöscht, und zwar über den Mount. Unter `__magic__` schreibt das einen Tombstone: Der Eintrag verschwindet aus `__magic__`, bleibt aber genau dort in `__all__`, in jedem Filterverzeichnis und auf dem Debrid-Konto erhalten ([magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)).

Also:

- **`torrents/delete` entfernt den *Datensatz* des Torrents, den der Shim für den \*arr führt.** Antwort 200.
- **`deleteFiles` darf den Torrent beim Provider nicht löschen.** Die Version, die der \*arr gerade importiert hat, wird weiterhin aus diesem Torrent ausgeliefert. Löschen würde genau das zerstören, was importiert wurde. Der einzige Fall, in dem ein echtes Löschen ehrlich wäre, ist ein Torrent, aus dem nie etwas importiert wurde, also der Pfad bei fehlgeschlagenem Download. Aber auch dort ist ein Debrid-Torrent gemeinsamer Bibliotheksstand und kein temporärer Download. Der sichere Standard lautet deshalb: **den Provider-Torrent nie löschen, nur tombstonen.** Das sollte so in der Doku für Nutzer stehen, so wie [sabnzbd.md](../guides/sonarr-radarr.md) es unter *What works, and what does not* macht.
- Ein `torrents/delete` für einen **unbekannten Hash** sollte trotzdem 200 antworten. Das echte qBittorrent tut das (Wiki, *Delete torrents*: "200 | All scenarios"). Ein Fehler würde hier als Fehler geloggt und bei jedem Poll für immer wiederholt.

### 5.3 `MarkItemAsImported` und die Kategorie nach dem Import {#53-markitemasimported-and-the-post-import-category}

`QBittorrent.cs:52-69` setzt die Kategorie nach dem Import, wenn `TvImportedCategory` /
`MovieImportedCategory` konfiguriert und von der Hauptkategorie verschieden ist. Die Funktion wird bei **jedem**
abgeschlossenen Import aufgerufen (`DownloadEventHub.cs:54`), noch vor der Entscheidung über das Entfernen.

Wenn ein Shim `setCategory` tatsächlich umsetzt und den Torrent aus der abgefragten Kategorie verschiebt, verschwindet der Torrent bei der nächsten Abfrage von `torrents/info?category=…`. Genau dafür ist die Einstellung gedacht, und die UI zeigt das als `DownloadClientHasPostImportCategory` an
(`src/NzbDrone.Core/Queue/QueueService.cs:84`, stammt von `DownloadClientItemClientInfo.HasPostImportCategory`, `QBittorrent.cs:234`). Den Aufruf anzunehmen und die neue Kategorie zu speichern ist das richtige Verhalten. Ihn abzulehnen erzeugt nur eine Warnung (`:62-67`).

## 6. `Test()` — jede Prüfung, in Reihenfolge, und ihre Meldung {#6-test--every-check-in-order-and-its-message}

`DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`) umschließt das
Ganze: **jede Exception, die nach außen dringt, wird zu**
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

Jeder Zweig **gibt zurück**, also kommt aus dieser Methode höchstens ein Fehler heraus.

| Reihenfolge | Bedingung | Eigenschaft | Meldung |
|---|---|---|---|
| 1 | `_proxySelector.GetProxy(Settings, force: true).GetApiVersion(Settings)` erzwingt eine neue Erkennung (`:435`) | | |
| 2 | Version `< 1.5` (`:436`) | `Host` | "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| 3 | Version `< 1.6` **und** Kategorie gesetzt (`:445-455`) | `Category` | "Category is not supported" / Detail "Categories are not supported until qBittorrent version 3.3.0. Please upgrade or try again with an empty Category." |
| 4 | Version `>= 1.6` **und** Kategorie leer (`:456-464`) | `TvCategory` / `MovieCategory` | **Warnung** — "Category is recommended" / "{appName} will not attempt to import completed downloads without a category." |
| 5 | `GetConfig` und dann `RemovesCompletedDownloads(config)` (`:467-474`) | `""` | "qBittorrent is configured to remove torrents when they reach their Share Ratio Limit" / Detail mit Nennung von Options → BitTorrent → Share Ratio Limiting |

Zuordnung der Ausnahmen (`:476-506`):

| Abgefangen | Eigenschaft | Meldung |
|---|---|---|
| `DownloadClientAuthenticationException` | `ApiKey`, wenn ein API-Key gesetzt ist, sonst `Username` | "Authentication Failure" / "Please verify your credentials. Also verify if the host running {appName} isn't blocked from accessing {clientName} by WhiteList limitations…" |
| `WebException` mit `Status == ConnectFailure` | `Host` | "Unable to connect to qBittorrent" / "Please verify the hostname and port." |
| jede andere `WebException` | `""` | "Unknown exception: {message}" |
| jede andere `Exception` | `Host` | "Unable to connect to qBittorrent", `DetailedDescription = ex.Message` |

Beachte: Fall 4 ist eine **Warnung**, und `failures.HasErrors()` in `:421` ist bei Warnungen falsch. Eine Einrichtung ohne Kategorie führt also trotzdem die übrigen drei Prüfungen aus.

### 6.2 `TestCategory` (`:511-556`) — der Ablauf bei „category does not exist“ {#62-testcategory-511-556--the-category-does-not-exist-flow}

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

Fehler: Eigenschaft `TvCategory` / `MovieCategory` (oder `TvImportedCategory` / `MovieImportedCategory`),
message "Configuration of category failed", detail "{appName} was unable to add the label to
qBittorrent."

Ein Shim hat also zwei Möglichkeiten: Entweder liefert er die konfigurierten Kategorien von Anfang an, sodass `torrents/categories` sie bereits enthält, oder er akzeptiert `createCategory` und zeigt die Kategorie in der allernächsten Antwort von `torrents/categories` an. **Eine dritte Option gibt es nicht.** Der Client liest erneut nach und schlägt fehl, wenn der Schlüssel immer noch fehlt. Kategorienamen werden **exakt** und groß-/kleinschreibungssensitiv verglichen (`Dictionary<string, …>.ContainsKey` mit dem Standard-Ordinal-Comparer).

Beachte die Behandlung von `TvImportedCategory`: Die Kategorie nach dem Import wird auch hier geprüft und angelegt, obwohl sie erst nach einem Import verwendet wird. Wenn der Betreiber sie setzt, muss sie existieren.

`QBittorrentSettingsValidator` (`QBittorrentSettings.cs:23-24`) lehnt Kategorienamen, die `^([^\\\/](\/?[^\\\/])*)?$` entsprechen, bereits ab, bevor eine Anfrage gestellt wird. Das heißt: kein Backslash, kein `//`, kein führendes oder abschließendes `/`.

### 6.3 `TestPrioritySupport` (`:558-597`) — der `queueing`-Health-Check {#63-testprioritysupport-558-597--the-queueing-health-check}

```csharp
var recentPriorityDefault = Settings.RecentTvPriority == (int)QBittorrentPriority.Last;
var olderPriorityDefault  = Settings.OlderTvPriority  == (int)QBittorrentPriority.Last;
if (olderPriorityDefault && recentPriorityDefault) { return null; }   // :563-566  the default: nothing checked

var config = Proxy.GetConfig(Settings);
if (!config.QueueingEnabled) { … }                                    // :572-588
```

Die Failure-Property ist `nameof(Settings.RecentTvPriority)` oder `nameof(Settings.OlderTvPriority)` (in dieser Reihenfolge geprüft), mit der Meldung "Queueing Not Enabled" und dem Detail "Torrent Queueing is not enabled in
your qBittorrent settings. Enable it in qBittorrent or select 'Last' as priority."

Eine Exception hier wird zu `("", "Unknown exception: {message}")` (`:590-594`).

`queueing_enabled` ist im Model standardmäßig **`true`** (`QBittorrentPreferences.cs:41`). Ein Shim, der den Schlüssel weglässt, besteht also die Prüfung. Das ist aber eine Lüge, wenn `topPrio` ein No-Op ist. Wenn du `queueing_enabled: false` meldest, ist das ehrlich, und es erzeugt diesen Fehler **nur**, wenn der Betreiber die Priority-Einstellung von `Last` weg geändert hat.

### 6.4 `TestGetTorrents` (`:599-612`)

`Proxy.GetTorrents(Settings)`; any exception becomes `("", "Failed to get the list of torrents:
{exceptionMessage}")`. This is the check that catches a malformed `torrents/info` body — a JSON object
instead of an array, a bad enum, a non-numeric `size`.

### 6.5 Die `dht`-Prüfung {#65-the-dht-check}

Es gibt **keine** eigene DHT-Prüfung in `Test()`. `dht` wird beim Abruf geprüft
(`:73-76`, Magnets ohne Tracker) und bei der Abfrage (`:288`, der `metaDL`-Zweig). Ein Shim, der
`dht: false` meldet, besteht den Verbindungstest und lehnt dann jeden Magnet ohne Tracker ab
mit `ReleaseDownloadException("Magnet not supported by download client. …")`
(`TorrentClientBase.cs:115`). **Melde `dht: true`.**

## 7. Parsing und Import-Folgen, die ein Shim kennen sollte {#7-parsing-and-import-consequences-a-shim-should-know}

### 7.1 `name` wird zu `Title`, und `Title` wird für drei verschiedene Dinge verwendet {#71-name-becomes-title-and-title-is-used-for-three-different-things}

**`DownloadClientItem.Title = torrent.Name`** (`QBittorrent.cs:232`). Weiter unten:

1. **Serien-/Film-Identifikation.** `CompletedDownloadService.Check` ruft `_parsingService.GetSeries(trackedDownload.DownloadItem.Title)` auf (`CompletedDownloadService.cs:95`). Gibt das null zurück, greift er auf den **Grab-Verlauf** zurück, der über `DownloadId` gesucht wird (`:99-102`). Fehlt der auch: "Series title mismatch; automatic import is not possible." + `ImportBlocked` (`:104-110`).
   Das Radarr-Gegenstück steckt in `ProcessFolder`, das `_historyService.FindByDownloadId(downloadClientItem?.DownloadId ?? "")` liest (`DownloadedMovieImportService.cs:193-194`).
   **Das ist der zweite Grund, warum der Shim genau den Infohash verwenden muss, den die \*arr berechnet haben (§1.7):** Der Verlauf-Fallback sucht über `DownloadId`, also verliert ein falscher Hash sowohl den Titel-Weg als auch den Fallback.
2. **Release-Parsing für die Import-Entscheidung.** `downloadClientItemInfo = Parser.Parser.ParseTitle(downloadClientItem.Title)` (Sonarr `ImportDecisionMaker.cs:80`; Radarr `ParseMovieTitle`, `:80`), zugewiesen an `LocalEpisode.DownloadClientEpisodeInfo` / `LocalMovie.DownloadClientMovieInfo` (`:94` / `:92`).
3. **Log-Zeilen und die Queue-UI.**

**Sonarrs Titel-Fallback-Gate.** `AggregateEpisodes.GetBestEpisodeInfo` (`src/NzbDrone.Core/MediaFiles/EpisodeImport/Aggregation/Aggregators/AggregateEpisodes.cs:29-57`):

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

Drei Gates entscheiden, ob der Titel des Download-Clients statt des Dateinamens verwendet wird: `!OtherVideoFiles`, der Dateiname ist selbst kein Scene-Titel, und der Client-Titel ist kein vollständiger Staffel-Parse. Der Torrent-Name rettet also nur ein einzelnes Release mit einer Datei, das nicht nach Scene-Konvention benannt ist.

Radarr hat **kein gleichwertiges Gate, das einen einzelnen Gewinner wählt**. `LocalMovie.OtherVideoFiles` gibt es (`src/NzbDrone.Core/Parser/Model/LocalMovie.cs:36`), aber die geparsten Infos des Films werden durch eine nach Konfidenz sortierte Augmenter-Kette zusammengeführt statt ausgewählt (`AggregateQuality.cs:25-121`). Der Titel des Download-Clients speist diese Augmenter, und die Film-Identität kommt aus dem Ordner-Parse plus Grab-Verlauf (`DownloadedMovieImportService.cs:192-195`).

**`OtherVideoFiles`** (`ImportDecisionMaker.cs:85`, `:100`, Radarr `:83`, `:98`):

```csharp
var nonSampleVideoFileCount = sceneSource ? GetNonSampleVideoFileCount(newFiles, series, downloadClientItemInfo, folderInfo) : videoFiles.Count;
…
OtherVideoFiles = nonSampleVideoFileCount > 1
```

`ProcessFolder` übergibt immer `sceneSource: true` (`DownloadedEpisodesImportService.cs:201`). Enthält ein Ordner also zwei oder mehr Videos, die keine Samples sind, wird `OtherVideoFiles` gesetzt, und der Titel des Download-Clients fällt für jede Datei darin raus.

**Warum das auf zurg wichtig ist.** Real-Debrid schreibt Release-Namen um, die an dessen Dateinamen-Sperre hängen bleiben: `WEB-DL`, `WEB.x264` und `WEB.H264` aber nur in genau dieser Schreibweise, `WEBRip`, `BDRip`, `HDRip`, `DVDRip`, `HDTV.x264`, `HDTV.XviD`, `BluRay.x264` und `p.BluRay.DTS` in jeder Schreibweise (wie am 2026-10-14 gemessen). Zurg hängt außerdem ein Suffix an, wenn zwei Releases denselben Namen bekommen. Beides kann dazu führen, dass `torrent.name` nicht mehr als das gegriffene Release parst. Siehe den Abschnitt RD 451 in der `CLAUDE.md` des Monorepos. Die Folgen, der Reihe nach:

- Die Identifikation fällt auf den Grab-Verlauf zurück (weiterhin ok, wenn der Hash passt).
- Sonarrs Parse pro Datei übernimmt (ok für eine korrekt benannte Datei im Ordner).
- Der Ordnername unter `__magic__` — den `Parser.ParseTitle(directoryInfo.Name)` bei `DownloadedEpisodesImportService.cs:184` liest — wird zum zweiten Punkt, der parsbar bleiben muss.

### 7.2 Der Import-Ordnerscan überspringt ganze Unterbäume {#72-the-import-folder-scan-drops-whole-subtrees}

`DiskScanService.FilterPaths` (`src/NzbDrone.Core/MediaFiles/DiskScanService.cs:232-246`), angewendet auf den Download-Ordner bei `DownloadedEpisodesImportService.cs:185` (Radarr `DownloadedMovieImportService.cs:202`) mit `filterExtras: true`:

```csharp
private static readonly Regex ExcludedExtrasSubFolderRegex = new Regex(@"(?:\\|\/|^)(?:extras|extrafanart|behind the scenes|deleted scenes|featurettes|interviews|other|scenes|samples|shorts|trailers)(?:\\|\/)", …IgnoreCase);   // :72
private static readonly Regex ExcludedSubFoldersRegex      = new Regex(@"(?:\\|\/|^)(?:@eadir|\.@__thumb|plex versions|\.[^\\/]+)(?:\\|\/)", …IgnoreCase);   // :73
private static readonly Regex ExcludedExtraFilesRegex      = new Regex(@"(-(trailer|other|behindthescenes|deleted|featurette|interview|scene|short)\.[^.]+$)", …IgnoreCase);   // :74
private static readonly Regex ExcludedFilesRegex           = new Regex(@"^\.(_|unmanic|DS_Store$)|^Thumbs\.db$", …IgnoreCase);   // :75
```

**Der Extras-Regex von Radarr unterscheidet sich in einer Alternative**: `sample[s]?` statt `samples` (Radarr `DiskScanService.cs:72`). Radarr wirft also auch einen `sample/`-Ordner weg, wo Sonarr nur `samples/` entfernt. Alles andere in den vier Regexes ist in beiden Repos gleich.

Achte auf die Alternative `\.[^\\/]+` im `ExcludedSubFoldersRegex`: **jede Verzeichniskomponente mit einem Punkt am Anfang wird entfernt**, egal wie tief sie liegt. Der Abgleich läuft gegen `basePath.GetRelativePath(path)`, also nur unterhalb des Import-Ordners. Ein Punkt in einem übergeordneten Pfad des Mounts ist deshalb harmlos.

Nur Dateien, deren Endung in `MediaFileExtensions.Extensions` steht, kommen überhaupt bis zum Filter (`DiskScanService.GetVideoFiles`, `:202-215`).

### 7.3 Die Sample-Erkennung liest die Datei {#73-sample-detection-reads-the-file}

`GetNonSampleVideoFileCount` (`ImportDecisionMaker.cs:216-234`) ruft für **jede** Videodatei im Ordner `_detectSample.IsSample(...)` auf. `DetectSample.IsSample` (`src/NzbDrone.Core/MediaFiles/EpisodeImport/DetectSample.cs:27-45`) bricht nur bei Specials, `.flv` und `.strm` ab (`:78-101`). Ansonsten ruft sie `_videoFileInfoReader.GetRunTime(path)` auf, also **ffprobe, auf die Datei, über den Mount**, und vergleicht das Ergebnis mit einem Minimum, das aus der erwarteten Laufzeit abgeleitet wird (`:103-121`). Eine Laufzeit von genau 0 wird als **Sample** behandelt (`:107-111`). Fehlt die Laufzeit, wird die Meldung "Failed to get runtime from the file, make sure ffprobe is available" geloggt und Indeterminate zurückgegeben (`:38-42`).

`ShouldDeleteFolder` (`DownloadedEpisodesImportService.cs:117-133`) führt dieselbe Prüfung noch einmal aus, und zwar für alles, was nach dem Verschieben übrig ist.

Ein Import eines Releases mit N Dateien kostet also mindestens N ffprobe-Zugriffe auf das Debrid-Backend, bevor irgendetwas verschoben wird. Auf einem zurg-Mount ist das ein echter Aufwand, und von der Client-Seite aus lässt er sich nicht vermeiden.

### 7.4 Die Ablehnungen in `ProcessFolder` / `ProcessFile` {#74-the-refusals-in-processfolder--processfile}

| Bedingung | Ergebnis | Zeile (Sonarr) |
|---|---|---|
| der Import-Pfad ist ein Serien-/Film-Ordner | `ImportRejectionReason.SeriesFolder` – "Import path is mapped to a series folder" (Radarr: `MovieFolder`, "…a movie folder") | `:175-182` (Radarr `:183-190`) |
| Ordnername lässt sich keiner bekannten Serie/keinem bekannten Film zuordnen | `UnknownSeriesResult("Unknown Series")` | `:160-168` |
| Dateiname beginnt mit `._` | `InvalidFilePath` | `:251-259` |
| Endung ist in `FileExtensions.DangerousExtensions` enthalten | `DangerousFile` | `:263-271` |
| Endung ist in `FileExtensions.ExecutableExtensions` enthalten | `ExecutableFile` | `:273-281` |
| Endung ist nicht in `MediaFileExtensions.Extensions` enthalten | `UnsupportedExtension` | `:283-293` |

**`SeriesPathExists` / `MoviePathExists` ist die Prüfung, die bei einem `__magic__`-Layout Probleme macht.** Wenn der Root-Ordner des \*arr `/mnt/zurg/__magic__/tv` ist und ein Serien-Ordner `/mnt/zurg/__magic__/tv/The Show` heißt, wird ein Import-Pfad, der *selbst* ein Serien-Ordner ist, einfach abgelehnt. Deshalb muss der Download-Ordner (`content_path`) neben den Root-Ordnern liegen und nicht in einem davon – so wie es [sabnzbd.md](../guides/sonarr-radarr.md) bereits vorgibt:
`save_path` = `/mnt/zurg/__magic__/__all__`, Root-Ordner `/mnt/zurg/__magic__/tv` und `/mnt/zurg/__magic__/movies`, Releases unter `/mnt/zurg/__magic__/__all__/<release>`.

`_UNPACK_` und `_FAILED_` werden vor dem Parsen aus dem Ordnernamen entfernt (`GetCleanedUpFolderName`, `:311-317`).

`IsFileLocked` wird **komplett übersprungen, wenn ein Download-Client-Eintrag vorhanden ist** (`:187-199`, `:295-304`) – die Lock-Prüfung läuft nur bei manuellen Scans bzw. Root-Ordner-Scans. Ein Shim muss sich darum nie Gedanken machen.

---

## 8. Die Health-Checks {#8-the-health-checks}

All three are shared with the SAB client and analysed in
[sabnzbd-client-contract.md §6](sabnzbd-client-contract.md). What is qBittorrent-specific:

- **`RemotePathMappingCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs:59-173`)
  geht `client.GetStatus().OutputRootFolders` durch — bei qBittorrent ist das der einzelne Ordner, der in
  `QBittorrent.cs:377-407` berechnet wird: der globale `save_path`, überschrieben oder erweitert durch den
  `savePath` der konfigurierten Kategorie (§1.5). Er muss ein gültiger Pfad sein **für das Betriebssystem, auf dem der \*arr läuft** (`:68-113`),
  und er muss **auf dem \*arr-Host existieren** (`:115-158`). Beschreibbar muss er nicht sein.
  `IsLocalhost` ist `Settings.Host == "127.0.0.1" || Settings.Host == "localhost"` (`:406`) und bestimmt nur,
  welche von drei Fehlermeldungen ausgegeben wird.
- **`DownloadClientRemovesCompletedDownloadsCheck`**
  (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:33-66`) warnt immer dann, wenn
  `GetStatus().RemovesCompletedDownloads` true ist — also immer dann, wenn das abgeleitete Flag aus §1.4 true ist. Lässt du
  `max_ratio_enabled` und `max_seeding_time_enabled` auf false (was das Rezept aus §3.5 ohnehin so macht), bleibt er still.
- **`DownloadClientRootFolderCheck`** ist die eine Stelle, an der sich die beiden Repos wirklich unterscheiden — Sonarr warnt
  nur, wenn ein Root-Ordner *gleich* einem Output-Ordner ist, Radarr auch dann, wenn ein Root-Ordner *einen* Output-Ordner *enthält*.
  Die vollständige Analyse steht in [sabnzbd-client-contract.md §6.1](sabnzbd-client-contract.md); die praktische Regel ist hier
  dieselbe: Lege keinen Root-Ordner auf oder über den Save-Path, und auch keinen darin — `/mnt/zurg/__magic__/tv` ist ein Geschwister von `/mnt/zurg/__magic__/__all__`.

---

## 9. Sonarr vs. Radarr — der vollständige Unterschied {#9-sonarr-vs-radarr--the-complete-diff}

Verifiziert, indem die abgerufenen Dateien paarweise verglichen wurden (BOM und CRLF vereinheitlicht).

| Datei | Unterschied |
|---|---|
| `QBittorrent.cs` | `TvCategory`→`MovieCategory`, `TvImportedCategory`→`MovieImportedCategory`, `RecentTvPriority`→`RecentMoviePriority`, `OlderTvPriority`→`OlderMoviePriority`, `RemoteEpisode`→`RemoteMovie`; `remoteEpisode.IsRecentEpisode()` → `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` (`:80`, `:137`). **Die Zeilennummern stimmen eins zu eins überein.** |
| `QBittorrentSettings.cs` | dieselben Umbenennungen; Standardkategorie `"tv-sonarr"` → `"radarr"` (`:36`); Hilfetext-Token `…EpisodeHelpText` → `…MovieHelpText`. Zeilennummern stimmen überein. |
| `QBittorrentProxyV2.cs` | die Kategorie-Umbenennung; `new[] { HttpStatusCode.Forbidden }` → `[HttpStatusCode.Forbidden]` (Collection Expression, Sonarr `:401` / Radarr `:400`); Sonarr hat eine zusätzliche Leerzeile bei 13 → **Sonarr N = Radarr N−1 für N ≥ 14**. |
| `QBittorrentProxyV1.cs` | die Kategorie-Umbenennung; derselbe Zeilenversatz durch Leerzeilen. |
| `QBittorrentProxySelector.cs` | ein überflüssiges doppeltes Leerzeichen im Konstruktor von Sonarr (`:46`); Leerzeile bei 3 → Sonarr N = Radarr N−1 für N ≥ 4. |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **byte-identisch.** |
| `TorrentClientBase.cs` | `RemoteEpisode`→`RemoteMovie` durchgehend; Radarr behandelt beim Abrufen einer `.torrent`-Datei HTTP **410 Gone** genauso wie 404 (`:175`), Sonarr nur 404. Beide haben 274 Zeilen. |
| `QBittorrentFixture.cs` | dieselben Tests, nur anders angeordnet: `missingFiles_item_should_have_required_properties` steht bei Sonarr `:296-315` und bei Radarr `:402-420`, und **die Radarr-Kopie hat kein `[Test]`-Attribut** (`:401` ist leer), deshalb läuft sie dort nie. Sonarr `:318-421` = Radarr `:297-400`; ab Sonarr `:423` gilt Radarr = Sonarr − 1. Sonarr hat 1000 Zeilen, Radarr 998. |
| `DiskScanService.cs` | `ExcludedExtrasSubFolderRegex`: Radarr hat `sample[s]?`, Sonarr `samples` (in beiden `:72`). Die anderen drei Regexes sind identisch. |
| Import-Services | `Series`/`Episode` vs. `Movie`; das `AggregateEpisodes`-Titelpräferenz-Gate von Sonarr hat kein Gegenstück bei Radarr (§7.1). Beide lehnen einen Import-Pfad, der ein Bibliotheksordner ist, ab, bevor sie etwas anderes tun (Sonarr `:175-182`, Radarr `:183-190`), und parsen danach den Ordnernamen (Sonarr `:184`, Radarr `:195`); Radarr sucht dort zusätzlich den Grab-Verlauf über `DownloadId` nach (`:193-194`). |
| `ImportApprovedEpisodes.cs` / `ImportApprovedMovie.cs` | die `copyOnly`-Switch ist identisch, Sonarr `:139-152` / Radarr `:116-129`. |
| `DiskTransferService.cs`, `DownloadClientBase.cs`, `DownloadEventHub.cs`, `Json.cs`, `HttpClient.cs`, `HttpRequestBuilder.cs` | gemeinsam genutzt, byte-identisch. |

Alles andere in diesem Dokument ist **byte-identisch bis auf Series/Movie** und gilt für beide an derselben Zeile.

---

## 10. Minimale, aber vollständige Beispiel-Payloads {#10-minimal-but-complete-example-payloads}

### 10.1 `GET /api/v2/app/webapiVersion`

```
2.11.2
```

`Content-Type: text/plain`. Kein JSON, keine Anführungszeichen, kein abschließender Zeilenumbruch nötig.

### 10.2 `POST /api/v2/auth/login`

Request-Body: `username=sonarr&password=hunter2`, `application/x-www-form-urlencoded`.

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8
Set-Cookie: SID=8f3c1c0e9a1f4d2f9c0b7a5e3d1f6b2a; path=/

Ok.
```

Falsche Zugangsdaten: trotzdem **200**, Body `Fails.` — niemals ein 401.

### 10.3 `GET /api/v2/app/preferences`

Nur die zehn Schlüssel aus §1.4 werden gelesen. Du kannst gerne mehr senden, sie werden ignoriert.

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

Harte Anforderungen:

- `save_path` muss als Verzeichnis **auf dem Sonarr/Radarr-Host** existieren (`RemotePathMappingCheck`, §8).
- `max_ratio_enabled: false` + `max_seeding_time_enabled: false` sorgt dafür, dass
  `RemovesCompletedDownloads` auf false bleibt. Dadurch bleiben sowohl der Verbindungstest (§6.1, Fall 5) als auch der Health-Check ruhig.
- `dht: true`, sonst werden Magnets ohne Tracker clientseitig abgelehnt (§6.5).
- `max_ratio_act` ist eine **Ganzzahl** (§0.6).

### 10.4 `GET /api/v2/torrents/categories`

```json
{
  "tv": { "name": "tv", "savePath": "" },
  "movies": { "name": "movies", "savePath": "" }
}
```

Ein JSON-**Objekt**, `savePath` in **camelCase**, darf nie mit `//` beginnen (§1.5). Ein leerer `savePath` lässt den Ausgabe-Stammordner beim globalen `save_path`.

### 10.5 `GET /api/v2/torrents/info?category=tv` — einer lädt herunter, einer ist importierbar {#105-get-apiv2torrentsinfocategorytv--one-downloading-one-importable}

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

Harte Anforderungen:

- Ein JSON-**Array** (`List<QBittorrentTorrent>`). Ein Objekt wirft eine Exception in `GetTorrents` und lässt
  `TestGetTorrents` (§6.4) fehlschlagen.
- `hash` **klein geschrieben** (§1.8) und genau der Infohash, den der \*arr aus dem Magnet oder der
  `.torrent` berechnet hat (§1.7).
- `size` in **Bytes**; `progress` ein Anteil zwischen 0 und 1. `RemainingSize = size × (1 − progress)`.
- `eta: 8640000` gilt als „unknown“ und ergibt ein null `RemainingTime` (`:622-625`). Ein Completed-Element bekommt
  unabhängig davon `TimeSpan.Zero` (`:273`).
- `state` aus der Tabelle in §2, genau in der Groß- und Kleinschreibung.
- `content_path` **absolut, vorhanden und ≠ `save_path`** bei Completed-Elementen (§4.1). Es darf leer sein, solange das Element nicht Completed ist.
- `ratio_limit: 0` + `ratio: 0` ist das Rezept zum Verschieben (§3.5).
- `category` muss mit der konfigurierten Kategorie des Clients übereinstimmen. Der Client filtert nicht nach, also den Query-Parameter beachten.
- `seeding_time` darf ganz weggelassen werden. Der Client greift dann auf `torrents/properties` zurück, aber nur, wenn tatsächlich ein Seeding-Zeit-Limit gilt.

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

Nur `save_path` und `seeding_time` werden gelesen (§1.8). **404 bei einem unbekannten Hash** — so sagt `IsTorrentLoaded` „noch nicht da“ (`:110-126`).

### 10.7 `GET /api/v2/torrents/files?hash=<hash>`

```json
[
  { "index": 0, "name": "Some.Show.S01E03.1080p.WEB.h264-GRP/ep3.mkv", "size": 1073741824, "progress": 1, "priority": 1, "is_seed": true, "piece_range": [0, 2047], "availability": 1 }
]
```

Nur `name` wird gelesen, relativ zu `save_path`, mit `/` als Trennzeichen (§1.13). Die Reihenfolge ist beim Pfad vor 2.6.1 wichtig: Die oberste Komponente von `files[0]` wird zum Ausgabeordner.

### 10.8 `POST /api/v2/torrents/add`

Anfrage, als URL-kodiertes Formular (ein langer Magnet kommt stattdessen als multipart — §0.3):

```
urls=magnet%3A%3Fxt%3Durn%3Abtih%3A3B1A...&category=tv&stopped=False
```

Antwort:

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8

Ok.
```

Alles außer dem wörtlichen `Fails.` gilt als Erfolg (§1.7). Ein leerer 200er-Body funktioniert auch.

### 10.9 `POST /api/v2/torrents/delete`

Anfrage: `hashes=3b1a1469c180f447b77021074dbbccaef62611e7&deleteFiles=true`

Antwort: `HTTP/1.1 200 OK`, leerer Body. **Auch bei einem unbekannten Hash kommt 200 zurück** (§5.2).

### 10.10 `POST /api/v2/torrents/createCategory`, `setCategory`, `setShareLimits`, `topPrio`, `setForceStart`

Alle nehmen urlencodierte Formulare entgegen und antworten mit `200` und einem leeren Body. `topPrio` kann mit **409** antworten, was „Queueing ist deaktiviert“ bedeutet. Der Client ignoriert genau diesen Status (§1.10). `setShareLimits` kann mit **404** antworten, was „nicht unterstützt“ bedeutet. Auch diesen Status ignoriert der Client (§1.9).

## 11. Unterschiede zu echtem qBittorrent — wo zurgs Modell enger oder weiter ist {#11-differences-from-real-qbittorrent--where-zurgs-model-is-narrower-or-wider}

### 11.1 Es gibt kein Seeding, also muss das Seed-Limit-Gate nachgebildet werden {#111-there-is-no-seeding-so-the-seed-limit-gate-has-to-be-faked}

Das echte qBittorrent berechnet `ratio` aus den Bytes, die tatsächlich hochgeladen wurden, und erlaubt dem Nutzer ein globales oder pro Torrent festgelegtes Limit. Das `CanMoveFiles`-Gate im Client soll verhindern, dass Dateien unter einem Torrent weggezogen werden, der noch eine Ratio-Vorgabe erfüllt (`QBittorrent.cs:240-241`). Ein Debrid-Backend lädt dagegen nie etwas hoch. Deshalb setzt der Shim `ratio: 0, ratio_limit: 0`. Das ist ein pro-Torrent-Limit, das schon erreicht ist. Im einzigen Sinn, in dem das Feld hier ehrlich sein kann, stimmt das also, und die globalen Einstellungen bleiben komplett außen vor (§3.5).

### 11.2 `content_path` ist immer ein Ordner, nie eine Datei {#112-content_path-is-always-a-folder-never-a-file}

Echtes qBittorrents `contentPath()` gibt bei einem Torrent mit nur einer Datei den **Dateipfad** zurück
(`torrentimpl.cpp:582-583`). Unter `__magic__` ist jede Veröffentlichung ein Ordner mit ihren Dateien
([magic.md](../guides/magic.md#with-nothing-stored-it-is-__all__s-releases-as-real-folders)), auch eine Veröffentlichung mit nur einer Datei.

Die Folgen, alle zugunsten des Clients:

- `ProcessPath` nimmt immer den **Ordner**-Zweig (`DownloadedEpisodesImportService.cs:80-90`),
  nie den Datei-Zweig (`:92-102`). Der Ordner-Zweig ist der, der `FilterPaths`,
  `ShouldDeleteFolder` und das Parsen des Ordnernamens anwendet. Der Extras-Filter und der
  Fallback für den Titel aus dem Ordnernamen sind also immer aktiv.
- Die Ablehnungen pro Datei in `ProcessFile` (gefährliche, ausführbare oder nicht unterstützte Endung, Präfix `._`; §7.4)
  sind weiterhin erreichbar, aber über den Endungsfilter von `GetVideoFiles` statt über den obersten Zweig.
- Die `GetImportItem`-Durchsuchung vor Version 2.6.1 (§4.2) würde ebenfalls funktionieren, da `files[0].name` immer den
  Veröffentlichungsordner enthält. Es gibt aber keinen Grund, eine so alte Version anzugeben.

Das Wichtigste: Da es immer ein Ordner ist, ist `content_path` immer `save_path + "/" + <release folder>` und daher nie gleich `save_path`. Die Warnung `DownloadClientQbittorrentTorrentStatePathError` (§4.1) ist strukturell nicht erreichbar. Das ist das richtige Ergebnis und kein Zufall, auf den man sich verlassen sollte.

### 11.3 `name` ist nicht der übernommene Titel, und er kann sich ändern {#113-name-is-not-the-grabbed-title-and-it-can-change}

Der echte qBittorrent übernimmt den Namen aus den Metadaten des Torrents, und der ändert sich nicht. Der Name von zurg kommt aus der Bibliothek:

- Real-Debrid benennt Releases um, deren Dateiname die 451-Sperre auslöst (`WEB-DL`, die `Rip`-Tags und ein paar Quell-Punkt-Codec-Paare, Stand 2026-10-14 gemessen). Siehe dazu den Abschnitt RD 451 in der `CLAUDE.md` des Monorepos.
- zurg hängt ein Suffix an, wenn zwei Releases auf denselben Namen kollidieren. Eine Reparatur baut ein Release unter einer neuen Torrent-ID neu auf.
- Der Name wird bei jeder Abfrage aus der Bibliothek gelesen. Er kann sich deshalb **zwischen den Abfragen** ändern, und zwar bei einer ID, die der \*arr schon verfolgt.

Nichts davon bricht das Tracking, denn das Tracking läuft über `DownloadId`, also den Infohash, und nicht über den Namen. Kaputt geht dabei der Titel-Parsing-Pfad aus §7.1. Daraus folgen zwei Regeln:

1. **Auf den vom \*arr berechneten Infohash schlüsseln**, niemals auf etwas, das nur intern in zurg existiert. Er ist die einzige Verbindung zwischen dem Grab, der Grab-Historie und der Abfrage.
2. **Den Ordnernamen `__magic__` parsebar halten**, denn er ist der Fallback, den der Ordner-Zweig liest (`DownloadedEpisodesImportService.cs:184`).

### 11.4 Es gibt keine Fortschritts- und keine Metadatenphase {#114-there-is-no-progress-and-no-metadata-phase}

Es gibt nichts herunterzuladen, daher gibt es keinen sinnvollen `progress`, `eta`, `dlspeed` oder `metaDL`
— das ist dieselbe Einschränkung, die der SAB-Endpunkt dokumentiert ([sabnzbd.md](../guides/sonarr-radarr.md), *Was funktioniert, und
was nicht*: "No progress. A job is queued or it is completed"). Die naheliegende Zuordnung ist: **Queued**
(`queuedDL`), solange die Bibliothek das Release noch nicht auflistet, **Completed** (`pausedUP`), sobald sie es tut
*und seine Dateigrößen sich eingependelt haben*. Dabei wird `size` aus dem genommen, was das Backend angibt, damit der Queue-Eintrag nicht leer ist.

Verwende `metaDL` für den Wartezustand nur, wenn außerdem `dht: true` gemeldet wird. Nur dann ist es Queued (`:288-297`). `queuedDL` gilt immer und enthält keine Meldung.

Verwende `stalledDL`, `error` oder `missingFiles` nicht für eine vorübergehende Wartezeit. Alle drei sind **Warnungen** (§2) und erscheinen in der Queue als Probleme.

### 11.5 Löschen versteckt nur; es zerstört nichts {#115-deleting-hides-it-does-not-destroy}

`torrents/delete?deleteFiles=true` auf echtem qBittorrent entfernt den Torrent und führt `rm -rf` auf seine Daten aus.
Hier muss nur der Eintrag entfernt werden: Das Release wird weiterhin aus dem Provider-Torrent ausgeliefert, und den Ordner, den der \*arr entfernt haben wollte, hat er über den Mount schon selbst als gelöscht markiert (§5.2, [magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)). Genau diese Überlegung ist auch in `deleteFromHistory` in `internal/sabnzbd` festgehalten, `internal/sabnzbd/api.go:596-609`.

### 11.6 Alles, was der Client anfordern kann, aber nichts zum Anwenden hat {#116-everything-the-client-can-ask-for-that-has-nothing-to-apply-to}

Akzeptiere `sequentialDownload`, `firstLastPiecePrio`, `contentLayout`, `stopped`/`paused`, `setForceStart`,
`topPrio`, `setShareLimits`, `dlLimit`/`upLimit`: Nimm sie an, antworte mit 200, wende aber nichts davon an. Nur zwei haben sichtbare Folgen, wenn sie abgelehnt werden: `topPrio` (409 wird geschluckt, alles andere gibt eine Warnung aus) und `setShareLimits` (404 wird geschluckt). Keines von beiden blockiert einen Grab.

`contentLayout` ist einen Hinweis wert: Die Einstellung gibt es im \*arr genau dafür, damit qBittorrent einen Ordner auf oberster Ebene behält, sodass `content_path != save_path` gilt. Unter `__magic__` ist das Layout aber immer ein Ordner (§11.2). Der Parameter bleibt also wirkungslos, und du kannst ihn auf Default lassen.

---

## 12. Checkliste zur Umsetzung (14 Punkte) {#12-implementation-checklist-14-points}

1. **Nur API v2.** Antworte auf `/api/v2/app/webapiVersion` mit `2.11.2`, und gib auf
   `/version/api` **404** zurück, damit die v1-Prüfung sauber fehlschlägt.
2. **Auth:** Akzeptiere einen `Authorization: Bearer <key>`-Header, ein vorab gesendetes
   `Authorization: Basic`, ein `SID`-Cookie oder gar nichts. Antworte auf `POST /api/v2/auth/login`
   mit **200 + `Ok.` + `Set-Cookie: SID=…`**. Bei falschen Zugangsdaten antwortest du mit `Fails.` (ebenfalls 200), niemals
   mit 401. Verlange kein `Referer` und kein `Origin`.
3. **Fehler sind HTTP-Statuscodes, kein JSON.** 403 bedeutet "neu anmelden" und wird einmal erneut versucht. Ein zweites 403
   wird als Verbindungsfehler gemeldet, nicht als Authentifizierungsfehler. 404 ist bei `torrents/properties` (unbekannter Hash) und bei `torrents/setShareLimits` (nicht unterstützt) sinnvoll. 409 ist bei `torrents/topPrio` sinnvoll (Queueing aus). Alles andere muss 200 sein.
4. **Beide Form-Kodierungen bei `torrents/add` parsen**, also urlencoded und multipart. Multipart brauchst du, wenn ein Wert größer als 1024 Bytes ist oder eine `.torrent`-Datei hochgeladen wird. Akzeptiere bei jedem Boolean sowohl `True`/`False` als auch `true`/`false`.
5. **`torrents/info` gibt ein Array zurück, `torrents/categories` gibt ein Objekt** mit camelCase-`savePath` zurück. Berücksichtige den Query-Parameter `category`. Der Client filtert nicht noch einmal nach.
6. **Hashes: in jeder Antwort klein geschrieben, in jeder Anfrage case-insensitive abgeglichen.** Es ist immer der Infohash, den der \*arr aus dem Magnet oder der `.torrent` berechnet hat. `torrents/properties` ist die einzige Route, die den Hash in der Schreibweise bekommen darf, die `torrents/info` verwendet hat.
7. **Das Move-Rezept:** `state: "pausedUP"`, `ratio: 0`, `ratio_limit: 0`, `seeding_time_limit: -2`, `inactive_seeding_time_limit: -2`. Wenn du weniger setzt, wird der Import zu einer **Kopie**, also einem vollständigen Download des Releases. Dokumentiere, dass die Einstellung "Remove Completed" im \*arr eingeschaltet bleiben muss, denn der Shim kann das nicht ausgleichen.
8. **`content_path` muss absolut sein, auf dem \*arr-Host existieren und darf nicht gleich `save_path` sein.** Setze ihn erst, wenn das Release wirklich importierbar ist, also aufgelistet und die Dateigrößen stabil. Bis dahin meldest du `queuedDL` und lässt den Client weiter pollen. Es gibt kein Retry-Limit.
9. **`save_path`** (aus `app/preferences`, plus jeder `savePath` einer Kategorie) muss als Verzeichnis auf dem \*arr-Host existieren, sonst wirft `RemotePathMappingCheck` einen Fehler. Beschreibbar muss es nicht sein. Gib niemals einen `savePath` aus, der mit `//` beginnt.
10. **Halte den Verbindungstest grün:** `dht: true`, `queueing_enabled: true`, `max_ratio_enabled: false`, `max_seeding_time_enabled: false`, `max_ratio_act: 0` (als Integer). Lege entweder die konfigurierten Kategorien vorab an, oder berücksichtige `createCategory` und zeige es in der allernächsten `torrents/categories`-Antwort an.
11. **`torrents/delete` entfernt nur den Eintrag, sonst nichts.** Ignoriere `deleteFiles` für den Provider-Torrent. Genau so ignoriert `deleteFromHistory` in `internal/sabnzbd` `del_files` (`internal/sabnzbd/api.go:596-609`). Antworte mit 200 für einen unbekannten Hash. Akzeptiere `setCategory` und speichere die neue Kategorie.
12. **Rechne damit, dass der \*arr nach einem Move-Import den Release-Ordner selbst mit `rm -rf` löscht** (`DownloadedEpisodesImportService.cs:209-223`). Dadurch entsteht ein `__magic__`-Tombstone. Danach ruft er `torrents/delete` auf. Beides ist normal, und nichts davon zerstört etwas.
13. **Verwende nur Statusnamen aus §2, exakt in dieser Schreibweise.** Ein unbekannter Name wirft hier keinen Fehler (anders als bei SAB), wird aber geloggt und fällt auf Downloading zurück. Verwende niemals `stalledDL`, `error` oder `missingFiles` für eine vorübergehende Wartezeit. Alle drei sind Warnings.
14. **Lege keinen Root-Ordner auf oder über dem Output-Ordner an.** Bei `save_path` = `/mnt/zurg/__magic__/__all__` verwendest du `/mnt/zurg/__magic__/tv` und `/mnt/zurg/__magic__/movies` als Root-Ordner. Releases behältst du unter `/mnt/zurg/__magic__/__all__/<release>`. Sonst verweigern `SeriesPathExists`/`MoviePathExists` den Import komplett (§7.4), und Radarrs `DownloadClientRootFolderCheck` beschwert sich bei jedem Start.
