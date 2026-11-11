# API de contrato do qBittorrent consumida pelo Sonarr e Radarr (develop) {#qbittorrent-web-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Fonte de referência: arquivos obtidos de `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...` e de `qbittorrent/qBittorrent/master` em **2026-08-27**. Todos os números de linha abaixo foram lidos desses arquivos.

Este documento é a contraparte para torrent do [sabnzbd-client-contract.md](sabnzbd-client-contract.md). Aquele registra por que `internal/sabnzbd` responde nos formatos que responde. Este é a especificação que um shim para qBittorrent precisa atender *antes* de ser escrito, para que uma captura (grab), uma consulta (poll), uma importação **como movimentação** e a limpeza pós-importação funcionem nos dois clientes. Quando os dois clientes compartilham mecanismos (a camada HTTP, o serializador JSON, `DiskTransferService`, as verificações de saúde), este documento cita as mesmas linhas e remete a eles em vez de repetir a análise.

Salvo indicação em contrário, **os arquivos do qBittorrent dos dois repositórios são idênticos, exceto pela renomeação `Tv*` → `Movie*`**, e:

| Arquivo | Números de linha |
|---|---|
| `QBittorrent.cs` (746 linhas nos dois) | **correspondem linha a linha** |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **idênticos byte a byte**, correspondem linha a linha |
| `QBittorrentSettings.cs` (91 linhas nos dois) | correspondem linha a linha |
| `QBittorrentProxyV2.cs`, `QBittorrentProxyV1.cs` | O Sonarr tem uma linha em branco na linha 13 que o Radarr não tem (verificado: a linha `:12` do Sonarr é o comentário `// API https://…`, a `:13` está em branco e a `:14` é `public class QBittorrentProxyV2`; a declaração da classe no Radarr está na `:13`). **Linha N do Sonarr = linha N−1 do Radarr para N ≥ 14.** |
| `QBittorrentProxySelector.cs` | igual, a partir da linha 3 |
| `QBittorrentFixture.cs` | reordenado, não deslocado; citado por repositório |

Os caminhos são `src/NzbDrone.Core/Download/Clients/QBittorrent/...` nos dois. As citações abaixo são números de linha do **Sonarr**, salvo quando marcadas de outra forma. O diff completo está na §9.

Nada aqui é especulação sobre o próprio qBittorrent: cada afirmação diz o que o *cliente* faz. Quando for sobre o comportamento do próprio qBittorrent, cito `qbittorrent/qBittorrent` master. Quando for sobre a semântica do runtime do .NET ou do Newtonsoft, eu digo isso.

---

## 0. Regras de nível de transporte (estas pegam primeiro) {#0-transport-level-rules-these-bite-first}

### 0.1 O cliente escolhe v1 ou v2 antes de fazer qualquer outra coisa {#01-the-client-picks-v1-or-v2-before-it-does-anything-else}

`QBittorrentProxySelector.FetchProxy` (`QBittorrentProxySelector.cs:80-95`):

```csharp
if (_proxyV2.IsApiSupported(settings)) { return Tuple.Create(_proxyV2, _proxyV2.GetApiVersion(settings)); }
if (_proxyV1.IsApiSupported(settings)) { return Tuple.Create(_proxyV1, _proxyV1.GetApiVersion(settings)); }
throw new DownloadClientException("Unable to determine qBittorrent API version");
```

`QBittorrentProxyV2.IsApiSupported` (`QBittorrentProxyV2.cs:28-70`) faz um **GET não autenticado**
para `GET /api/v2/app/webapiVersion` com `SuppressHttpError = true`, e decide:

| Resposta | Resultado |
|---|---|
| `404` | não é v2 → cai para v1 |
| `403` | **v2 suportado** (`:44-47`) — esta é a resposta de "ainda não fez login" |
| `401` | `DownloadClientException("Failed to connect to qBittorrent. Check your settings and qBittorrent configuration.")` (`:49-52`) |
| qualquer outro `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` (`:54-57`) |
| `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to qBittorrent, certificate validation failed.")` (`:63-66`) |
| `200` | v2 suportado |

`QBittorrentProxyV1.IsApiSupported` (`QBittorrentProxyV1.cs:27-59`) faz o mesmo em
`GET /version/api` — repare que **sem o `/api/v2` no início**, e o 401 *não* tem tratamento especial ali.

O par `(proxy, version)` fica em cache por **10 minutos**, indexado por `{Host}_{Port}`
(`QBittorrentProxySelector.cs:68-78`). `GetProxy(settings, force: true)` remove esse cache; o teste de conexão faz exatamente isso (`QBittorrent.cs:435`, `:519`), o que o fixture verifica (Sonarr `QBittorrentFixture.cs:986-998`, Radarr `:984-996`).

**Um shim deve responder a `/api/v2/app/webapiVersion` e nunca expor as rotas v1.** v1 é a API anterior à 4.1 (`/version/api`, `/query/torrents`, `/command/download`, …); para uma implementação nova ela só atrapalha, e nem consegue atender o caminho de importação, porque `GetLabels` lança `NotSupportedException("qBittorrent api v1 does not support getting all torrent categories")` (`QBittorrentProxyV1.cs:236-239`) e `SetTorrentSeedingConfiguration` não faz nada (`:241-244`). O resto deste documento fala só da API v2; a §1.17 traz o mapa de rotas v1 só para referência.

### 0.2 Formato da URL {#02-url-shape}

`QBittorrentProxyV2.BuildRequest` (`QBittorrentProxyV2.cs:341-359`):

```csharp
var requestBuilder = new HttpRequestBuilder(settings.UseSsl, settings.Host, settings.Port, settings.UrlBase)
{
    LogResponseContent = true,
    StoreRequestCookie = false
};
```

- URL base: `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-65`)
  = `{http|https}://{Host}:{Port}{UrlBase}`; `UrlBase` recebe um `/` no início se não tiver.
- `Resource("/api/v2/…")` (`HttpRequestBuilder.cs:244-256`) remove o `/` do início e acrescenta o restante,
  então a URL completa fica `{scheme}://{host}:{port}{urlBase}/api/v2/{group}/{method}`.
- **Sem header `Accept`.** `BuildRequest` nunca chama `.Accept(...)`, e o construtor de `HttpRequest`
  só define `Headers.Accept` quando `httpAccept != null`
  (`src/NzbDrone.Common/Http/HttpRequest.cs:14,30-32`). Não condicione nada ao `Accept`.
- `StoreRequestCookie = false`: o jar de cookies é gerenciado pelo proxy, não pela camada HTTP.

### 0.3 GET com query vs POST com form — e quando o form vira multipart {#03-get-with-query-vs-post-with-form--and-when-the-form-becomes-multipart}

Chamadas somente leitura usam `AddQueryParam` (`HttpRequestBuilder.cs:306-317`) em um GET. Chamadas que alteram dados usam `.Post()` mais `AddFormParameter` / `AddFormUpload`.

`ApplyFormData` (`HttpRequestBuilder.cs:150-242`) escolhe a codificação:

```csharp
var shouldSendAsMultipart = FormData.Any(v => v.ContentType != null || v.FileName != null || v.ContentData.Length > 1024);
```

- Qualquer `AddFormUpload` (que define `FileName` e `ContentType`) força **`multipart/form-data`** (`:379-395`, `:220`).
- **Qualquer valor de formulário com mais de 1024 bytes também força multipart** (`:162`). Um magnet URI com uma lista longa de trackers ultrapassa esse limite, então `POST /api/v2/torrents/add` chega como `application/x-www-form-urlencoded` *ou* `multipart/form-data`, dependendo do magnet. **Um shim precisa interpretar os dois nessa rota.**
- Caso contrário: `application/x-www-form-urlencoded`, com os valores escapados via `Uri.EscapeDataString(Encoding.UTF8.GetString(...))` (`:230`).

O escritor de multipart é feito à mão (`:164-227`) e escreve `Content-Disposition: form-data; name="…"` (mais `; filename="…"` e uma linha `Content-Type:` para uploads), uma linha em branco, os bytes brutos e depois `\r\n`. O boundary é `-----------------------------{ticks:x14}` (`:166`).

**Formatação de booleanos é uma armadilha.** `AddFormParameter` guarda `Convert.ToString(value, CultureInfo.InvariantCulture)` (`HttpRequestBuilder.cs:373`), e o `Convert.ToString(bool)` do .NET gera **`"True"` / `"False"`, com a primeira letra maiúscula**. Então `request.AddFormParameter("stopped", false)` (`QBittorrentProxyV2.cs:258`) envia `stopped=False` na requisição, não `stopped=false`. O qBittorrent de verdade lida com isso porque `Utils::String::parseBool` (`src/base/utils/string.cpp:108-116`) compara sem diferenciar maiúsculas de minúsculas. **Um shim precisa aceitar `True`/`False` assim como `true`/`false`.** Onde o cliente escreve a string fixa, ela está em minúsculas — `deleteFiles` é `"true"` (`QBittorrentProxyV2.cs:198`) e o `value` do `setForceStart` é `"true"`/`"false"` (`:337`) — então as duas grafias realmente aparecem.

Números passam pelo mesmo caminho de cultura invariante, então `ratioLimit=1.5` sempre usa `.` como separador decimal (`QBittorrentProxyV2.cs:234`, `HttpRequestBuilder.cs:373`).

### 0.4 Autenticação — três camadas, todas podem estar ativas ao mesmo tempo {#04-authentication--three-layers-all-of-which-can-be-live-at-once}

`BuildRequest` (`QBittorrentProxyV2.cs:349-356`):

```csharp
if (settings.ApiKey.IsNotNullOrWhiteSpace())
    requestBuilder.Headers["Authorization"] = $"Bearer {settings.ApiKey}";
else if (settings.Username.IsNotNullOrWhiteSpace() || settings.Password.IsNotNullOrWhiteSpace())
    requestBuilder.NetworkCredential = new BasicNetworkCredential(settings.Username, settings.Password);
```

1. **API key** → `Authorization: Bearer <key>` em toda requisição, e `ProcessRequest` segue um caminho de atalho que nunca faz login (`:371-395`). `QBittorrentSettingsValidator` proíbe username/password junto com uma key (`QBittorrentSettings.cs:16-21`).
2. **Username/password** → `BasicNetworkCredential`, que o `ManagedHttpDispatcher` transforma em um header `Authorization: Basic base64(user:pass)` **preemptivo** em *toda* requisição, incluindo o próprio `auth/login` (`src/NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:81-89`, comentário: "Manually set header to avoid initial challenge response").
3. **Sessão por cookie** → `AuthenticateClient` (`QBittorrentProxyV2.cs:430-494`).

`AuthenticateClient`, exatamente:

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

Consequências para um shim:

- `POST /api/v2/auth/login`, corpo `username=…&password=…`, `application/x-www-form-urlencoded`.
- Responda com **HTTP 200**, corpo exatamente `Ok.` e um header `Set-Cookie: SID=…`, que é o formato que o qBittorrent real usa (wiki, *Login*: "Em caso de sucesso, a resposta vai conter um cookie com seu SID").
- **Corpo vazio também é aceito** (`:479` faz atalho com `IsNotNullOrWhiteSpace`). Qualquer outra coisa (`"Fails."`, `"ok"`, JSON) é falha de autenticação. O proxy v1 é mais rigoroso e exige exatamente `Ok.` (`QBittorrentProxyV1.cs:371`).
- Em erro HTTP no `auth/login`: 401 ou 403 → `DownloadClientAuthenticationException`; qualquer outro → `DownloadClientException` (`:463-473`). Um `WebException` → `DownloadClientUnavailableException`.
- O cookie fica em cache por `{baseUrl}:{user}:{pass}` durante toda a vida da entrada de cache do processo, e só é renovado quando uma requisição volta com 403 (§0.5).
- **`Referer` e `Origin` nunca são enviados.** A wiki diz aos consumidores da API para definir esses headers ("Obs.: defina `Referer` ou `Origin` com exatamente o mesmo domínio e porta usados no header `Host` da query HTTP"), e o Sonarr não faz isso. Um shim não pode exigir esses headers.
- Com **nenhuma credencial configurada**, `AuthenticateClient` retorna na hora e nada é enviado: sem login, sem cookie, sem `Authorization`. Um shim sem autenticação funciona.

### 0.5 Quais códigos HTTP são tratados como erro {#05-which-http-statuses-are-treated-as-errors}

`HttpClient.Execute` (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`) lança exceção quando
`response.HasHttpError` — `(int)StatusCode >= 400` (`src/NzbDrone.Common/Http/HttpResponse.cs:54`) —
a menos que `SuppressHttpError` ou o status esteja em `SuppressHttpErrorStatusCodes`. 429 vira
`TooManyRequestsException` (`:115`); todo o resto vira `HttpException` (`:119`).

`QBittorrentProxyV2.ProcessRequest` (`:369-428`) então encapsula isso. São dois caminhos distintos:

**Caminho da chave de API** (`:371-395`):

| Status | Resultado |
|---|---|
| 401, 403 | `DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.")` |
| qualquer outro `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` |
| qualquer outra exceção lançada | `DownloadClientException("Failed to connect to qBittorrent, please check your settings.")` |

**Caminho do cookie** (`:397-427`):

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

- **403 significa "sessão expirada, faça login de novo"** — ele é suprimido uma vez, o cliente faz
  login de novo e tenta outra vez. Esse é o mesmo ciclo que a expiração de sessão do próprio
  qBittorrent provoca, e um shim pode usá-lo do mesmo jeito.
- A **requisição de nova tentativa é recriada a partir do builder**, que não carrega
  `SuppressHttpErrorStatusCodes` — esse campo foi definido na *requisição* em `:401`, não no builder.
  Então um segundo 403 lança `HttpException` e aparece como
  `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` — **não** como
  falha de autenticação. Um shim que responde 403 para sempre gera um erro de conexão confuso na UI,
  não "Authentication Failure".
- Se não houver credenciais configuradas, a tentativa de login de novo em `:411` lança
  `DownloadClientAuthenticationException` na hora (`:434-437`).

**Toda chamada bem-sucedida precisa ser HTTP 200 com exatamente o corpo que o cliente espera.** Não
existe envelope de erro JSON em lugar nenhum desta API; diferente do SAB, aqui os erros são status
HTTP.

### 0.6 Configurações do deserializador {#06-deserializer-settings}

Todos os payloads do qBittorrent passam por `NzbDrone.Common.Serializer.Json` (`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`), que usa **Newtonsoft**, a mesma instância que o cliente SAB usa. Então [sabnzbd-client-contract.md §0.3](sabnzbd-client-contract.md) se aplica sem mudanças:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

O que isso significa para os modelos do qBittorrent especificamente:

| Membro do modelo | Mapeia para | Por quê |
|---|---|---|
| `QBittorrentTorrent.Hash/Name/Size/Progress/Eta/State/Label/Category/Ratio` | `hash`, `name`, `size`, `progress`, `eta`, `state`, `label`, `category`, `ratio` | resolver camelCase; o Newtonsoft também casa sem diferenciar maiúsculas/minúsculas |
| `SavePath`, `ContentPath`, `RatioLimit`, `SeedingTime`, `SeedingTimeLimit`, `InactiveSeedingTimeLimit`, `LastActivity` | `save_path`, `content_path`, `ratio_limit`, `seeding_time`, `seeding_time_limit`, `inactive_seeding_time_limit`, `last_activity` | `[JsonProperty]` explícito (`QBittorrentTorrent.cs:24-45`) |
| `QBittorrentLabel.Name/SavePath` | `name`, `savePath` | **sem** `[JsonProperty]` — resolver camelCase. O `torrents/categories` do qBittorrent realmente usa camelCase aqui, diferente de todo o resto |
| `QBittorrentPreferences.*` | todos com `[JsonProperty]` explícito em snake_case (`QBittorrentPreferences.cs:16-44`) | |
| `QBittorrentMaxRatioAction` | `max_ratio_act` | não tem conversor por propriedade, então vale o `StringEnumConverter` global. `AllowIntegerValues` vem como true por padrão, então **envie o inteiro**, como o qBittorrent real faz. Uma string teria que estar em camelCase (`"pause"`, `"remove"`) e um nome desconhecido gera exceção |

`NullValueHandling.Ignore` vale também na **leitura**: um `null` do JSON deixa o membro com o valor do construtor. Junto com os padrões declarados nos modelos, um campo **ausente ou null** não é o mesmo que zero:

| Campo | Padrão se ausente/null | Referência |
|---|---|---|
| `ratio_limit` | `-2f` | `QBittorrentTorrent.cs:33` |
| `seeding_time_limit` | `-2` | `:39` |
| `inactive_seeding_time_limit` | `-2` | `:42` |
| `seeding_time` | `null` (`long?`) | `:36` |
| `queueing_enabled` | **`true`** | `QBittorrentPreferences.cs:41` |
| todo o resto | padrão do CLR (`0`, `false`, `null`) | |

`Eta` é um `System.Numerics.BigInteger` (`QBittorrentTorrent.cs:17`, comentário "QBit contains a bug exceeding ulong limits"); o fixture do Sonarr fixa `18446744073709335000` como algo parseável (Sonarr `QBittorrentFixture.cs:974-984`, Radarr `:973-982`).

`Json.Deserialize<T>` relança `JsonReaderException` com uma mensagem mais clara (`Json.cs:39-50`). Nenhuma das chamadas de proxy do qBittorrent usa `TryDeserialize`, então **um corpo malformado ou com formato errado sai do proxy com exceção** e vira uma exceção não tratada no ponto de chamada — no caso de `GetItems()`, isso derruba a consulta inteira.

### 0.7 Todo gate `version >=`, em um só lugar {#07-every-version--gate-in-one-place}

`ProxyApiVersion` é `_proxySelector.GetApiVersion(Settings)` (`QBittorrent.cs:50`), ou seja, o `app/webapiVersion` em cache. As verificações:

| Verificação | Onde | Efeito abaixo do limite |
|---|---|---|
| `>= 1.5` | `QBittorrent.cs:436` | Teste falha: "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| `>= 1.6` | `:445` | O teste falha se uma categoria estiver configurada: "Category is not supported" |
| `>= 2.0` | `:379` (`GetStatus`), `:520` (`TestCategory`) | O `savePath` da categoria não é lido, e as categorias não são verificadas nem criadas |
| `>= 2.6.1` | `:314` | O `OutputPath` **não** é obtido de `content_path`; o `GetImportItem` percorre `torrents/files` em vez disso (§4.2) |
| `>= 2.8.1` | `:79`, `:136` | Os limites de compartilhamento não podem ir junto no `torrents/add`; eles são aplicados depois com `torrents/setShareLimits` |
| `>= 2.11.0` | `QBittorrentProxyV2.cs:253` | O `torrents/add` envia `paused=` em vez de `stopped=` |

O `Version.Parse` (`QBittorrentProxyV2.cs:75`) precisa de **pelo menos `major.minor`**. Um `"2"` puro lança `FormatException`, e essa exceção é disparada fora de todo `try` no proxy, então ela escapa de `GetApiVersion` por completo. Informe algo como `2.11.2`.

**Valor recomendado para um shim: `2.11.2`.** Ele passa por todas as verificações, coloca o `content_path` no caminho do `torrents/info` (a única rota de importação que faz sentido) e seleciona a grafia `stopped=` do qBittorrent 5.x na adição.

---

## 1. Todos os endpoints, na ordem em que o cliente os chama {#1-every-endpoint-in-the-order-the-client-calls-them}

Interface: `IQBittorrentProxy` (`QBittorrentProxySelector.cs:9-30`). Implementação: `QBittorrentProxyV2`. Todos os pontos de chamada em `QBittorrent.cs` estão listados em `:49-741`.

### 1.1 `GET /api/v2/app/webapiVersion` — `GetApiVersion` (`QBittorrentProxyV2.cs:72-78`)

Requisição: sem parâmetros. Enviada primeiro sem autenticação (como sondagem, §0.1) e depois com autenticação.

Resposta: **texto puro**, uma string de versão analisada por `Version.Parse`. Não é JSON, sem aspas.

Chamada por: a sondagem do proxy (`:31`), `GetItems` (`QBittorrent.cs:220`), `GetStatus` (`:374`), `TestConnection` (`:435`), `TestCategory` (`:519`) e — a que é fácil de passar despercebida — `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:253`), o que significa que **cada `torrents/add` é precedido pelo seu próprio round trip de `app/webapiVersion`** sempre que o estado inicial for Start ou Stop (ou seja, sempre, a menos que o usuário tenha escolhido Force Start).

### 1.2 `GET /api/v2/app/version` — `GetVersion` (`QBittorrentProxyV2.cs:80-87`)

Resposta: texto simples, sem o `v` do início (`:83`). Comentário: `// eg "4.2alpha"`.

**Nunca é chamado.** Ele está na interface (`QBittorrentProxySelector.cs:13`), mas não há nenhum chamador em
`QBittorrent.cs` (verificado em todas as referências a `Proxy.`/`_proxySelector.`, `:49-741`). Implemente mesmo assim: não custa nada, e quem mexer no shim vai acabar procurando por ele.

### 1.3 `POST /api/v2/auth/login`

Coberto em §0.4. Formulário: `username`, `password`. Resposta `200` + `Ok.` + `Set-Cookie: SID=…`.

### 1.4 `GET /api/v2/app/preferences` — `GetConfig` (`QBittorrentProxyV2.cs:89-95`)

Requisição: sem parâmetros. Resposta: um objeto JSON, desserializado em `QBittorrentPreferences`.

**Toda chave que o cliente lê** (`QBittorrentPreferences.cs:14-45`). Nada mais no corpo é analisado, e chaves extras são ignoradas:

| Chave JSON | C# | Tipo | Lido por |
|---|---|---|---|
| `save_path` | `SavePath` | `string` | `GetStatus` → `OutputRootFolders` (`QBittorrent.cs:377`) |
| `max_ratio_enabled` | `MaxRatioEnabled` | `bool` | `HasReachedSeedLimit` (`:639`), `RemovesCompletedDownloads` (`:415`) |
| `max_ratio` | `MaxRatio` | `float` | `HasReachedSeedLimit` (`:641`) |
| `max_seeding_time_enabled` | `MaxSeedingTimeEnabled` | `bool` | `HasReachedSeedingTimeLimit` (`:663`), `RemovesCompletedDownloads` (`:415`) |
| `max_seeding_time` | `MaxSeedingTime` | `long`, **minutos** | `:665`, `:415` |
| `max_inactive_seeding_time_enabled` | `MaxInactiveSeedingTimeEnabled` | `bool` | `HasReachedInactiveSeedingTimeLimit` (`:727`) |
| `max_inactive_seeding_time` | `MaxInactiveSeedingTime` | `long`, **minutos** | `:729` |
| `max_ratio_act` | `MaxRatioAction` | enum como int: `Pause=0, Remove=1, EnableSuperSeeding=2, DeleteFiles=3` (`QBittorrentPreferences.cs:5-11`) | `RemovesCompletedDownloads` (`:415`) |
| `queueing_enabled` | `QueueingEnabled` | `bool`, **padrão `true`** | `TestPrioritySupport` (`:572`) |
| `dht` | `DhtEnabled` | `bool` | `AddFromMagnetLink` (`:73`), ramo `metaDL` (`:288`) |

Chamado por: `AddFromMagnetLink` (`:73`), `GetItems` (`:221`), `GetStatus` (`:375`), `TestConnection`
(`:467`), `TestPrioritySupport` (`:570`). Não é armazenado em cache, então é buscado a cada consulta.

`RemovesCompletedDownloads` (`QBittorrent.cs:412-416`) é a flag derivada:

```csharp
var minimumRetention = 60 * 24 * 14; // 14 days in minutes
return (config.MaxRatioEnabled || (config.MaxSeedingTimeEnabled && config.MaxSeedingTime < minimumRetention))
    && (config.MaxRatioAction == QBittorrentMaxRatioAction.Remove || config.MaxRatioAction == QBittorrentMaxRatioAction.DeleteFiles);
```

Ela alimenta tanto o teste de conexão (`:468`) quanto a verificação de saúde `DownloadClientRemovesCompletedDownloadsCheck`
(`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:44-53`). Com `max_ratio_enabled: false` e `max_seeding_time_enabled: false`, ela é false independentemente do que `max_ratio_act` diz, mas envie `max_ratio_act: 0` mesmo assim.

### 1.5 `GET /api/v2/torrents/categories` — `GetLabels` (`QBittorrentProxyV2.cs:221-225`)

Requisição: sem parâmetros.

Resposta: um **objeto** JSON, `{"<name>": {"name": "...", "savePath": "..."}}`, desserializado em
`Dictionary<string, QBittorrentLabel>`. Observe o **camelCase `savePath`**, conforme §0.6 e o exemplo *Get all categories* da wiki. Um array aqui gera uma exceção.

Leia com dois objetivos:

1. `TestCategory` (`QBittorrent.cs:525-553`): apenas a presença da chave (§6.3).
2. `GetStatus` (`:379-402`): o `savePath` da categoria configurada vira a pasta raiz de saída do cliente de download:

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

Um `savePath` **relativo** é anexado ao `save_path` global; um caminho com raiz o substitui. Um `savePath` que começa com `//` é convertido em caminho UNC com barra invertida. O fixture do Sonarr fixa `"//server/store/downloads"` → `\\server\store\downloads` (Sonarr `QBittorrentFixture.cs:563-589`, Radarr `:562-588`). **Nunca gere um `//` no início.** A resposta mais simples e correta é `"savePath": ""`, que deixa a pasta raiz no `save_path` global.

(Uma tradução anterior foi rejeitada: os trechos de código estavam diferentes. Mantenha a estrutura exatamente como está.)

### 1.6 `POST /api/v2/torrents/createCategory` — `AddLabel` (`QBittorrentProxyV2.cs:213-219`)

Forma: `category=<name>`. **`savePath` não é enviado** — o cliente nunca define um caminho de salvamento para a categoria.
O corpo da resposta é ignorado; só importa se o status não é de erro.

Chamado somente a partir de `TestCategory` (`QBittorrent.cs:529`, `:543`), quando a categoria não existe.
`torrents/editCategory` e `torrents/removeCategories` **nunca são chamados**.

### 1.7 `POST /api/v2/torrents/add` — `AddTorrentFromUrl` / `AddTorrentFromFile`

`AddTorrentFromUrl` (`QBittorrentProxyV2.cs:146-166`): campo de formulário **`urls`** = a URI magnet.
`AddTorrentFromFile` (`:168-188`): upload de formulário **`torrents`**, nome de arquivo
`{CleanFileName(release title)}.torrent` (`TorrentClientBase.cs:199`),
`Content-Type: application/octet-stream` (`HttpRequestBuilder.cs:379`).

Os dois então adicionam `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:243-284`):

| Campo de formulário | Valor | Condição | Linha |
|---|---|---|---|
| `category` | `Settings.TvCategory` / `MovieCategory` | categoria não vazia | `:245-248` |
| `stopped` (webapi `>= 2.11.0`) ou `paused` (abaixo) | `False` para Start, `True` para Stop | `InitialState` é Start ou Stop — **Force Start não envia nenhum dos dois** | `:251-264` |
| `sequentialDownload` | `True` | configuração `SequentialOrder` ativada | `:266-269` |
| `firstLastPiecePrio` | `True` | configuração `FirstAndLast` ativada | `:271-274` |
| `contentLayout` | `"Original"` ou `"Subfolder"` | configuração `ContentLayout` é Original ou Subfolder; **Default não envia nada** | `:276-283` |

e, quando os limites de compartilhamento estão configurados *e* a webapi é `>= 2.8.1` (`QBittorrent.cs:79`, `:136`),
`AddTorrentSeedingFormParameters(request, seedConfiguration)` (`QBittorrentProxyV2.cs:227-241`):

| Campo de formulário | Valor | Condição |
|---|---|---|
| `ratioLimit` | `seedConfiguration.Ratio` ou `-2` | só quando não for `-2` (`:232`) |
| `seedingTimeLimit` | `seedConfiguration.SeedTime.TotalMinutes` ou `-2` | só quando não for `-2` (`:237`) |

**Todo o resto que a wiki documenta para `torrents/add` nunca é enviado**: sem `savepath`, sem `cookie`,
sem `tags`, sem `skip_checking`, sem `root_folder`, sem `rename`, sem `upLimit`, sem `dlLimit`, sem
`autoTMM`. Não existe parâmetro `priority` na adição — a prioridade na fila é uma chamada separada, `topPrio` (§1.10).

Tratamento da resposta (`:159-165`, `:181-187`):

```csharp
var result = ProcessRequest(request, settings);
// Note: Older qbit versions returned nothing, so we can't do != "Ok." here.
if (result == "Fails.") { throw new DownloadClientException("Download client failed to add torrent by url"); }
```

Então: **200 com qualquer corpo, exceto o texto literal `Fails.`, é sucesso.** `Ok.` é a resposta convencional.
Um HTTP 415 (o "torrent file is not valid" da wiki) vira um `DownloadClientException` via `:389`.

**O ID do download não vem dessa chamada.** Ele é calculado no cliente, antes da requisição:

- magnet → `MagnetLink.Parse(magnetUrl).InfoHash.ToHex()` (`TorrentClientBase.cs:224`)
- `.torrent` → `_torrentFileInfoReader.GetHashFromTorrentFile(torrentFile)` (`:200`)

e `AddFromMagnetLink` / `AddFromTorrentFile` devolvem esse mesmo `hash`, sem alterações (`QBittorrent.cs:130`, `:187`). **O shim precisa indexar o torrent exatamente por esse infohash**, senão o Sonarr perde o rastro do grab — `TorrentClientBase.cs:206-212` e `:238-244` só registram uma linha de Debug sobre isso.
A pré-condição de DHT é verificada primeiro para magnets:

```csharp
if (!Proxy.GetConfig(Settings).DhtEnabled && !magnetLink.Contains("&tr="))
    throw new NotSupportedException("Magnet Links without trackers not supported if DHT is disabled");   // :73-76
```

o que o chamador transforma em `ReleaseDownloadException("Magnet not supported by download client…")` quando não há fallback `.torrent` (`TorrentClientBase.cs:111-119`). **Informe `dht: true`.**

Depois da adição, `WaitForTorrent` (`QBittorrent.cs:190-214`) consulta `IsTorrentLoaded` **10 vezes, com 100 ms de espera entre elas** — mas só quando há trabalho posterior a fazer (limites de compartilhamento pós-adição, top priority ou force start; `:86`, `:143`). A mensagem de falha diz "within 500 ms", mas o loop na verdade é 10 × 100 ms; de qualquer forma ele desiste e devolve o hash (`:212-213`).

### 1.7a Quanto tempo o cliente espera por `torrents/add` — **100 segundos**, medido em 2026-08-30 {#17a-how-long-the-client-waits-for-torrentsadd--100-seconds-measured-2026-08-30}

Lido em `Sonarr/Sonarr@32a5d492` e `Radarr/Radarr@40bb746c` (ambos `develop`) em 2026-08-30. Isso limita tudo que um shim faz de forma síncrona dentro da chamada de add, então vale citar a fonte em vez de presumir.

Nada no caminho do qBittorrent define um timeout, então o valor passa por quatro camadas até chegar a um 100 s fixo:

| Etapa | Sonarr `path:line` | Radarr `path:line` | O que faz |
|---|---|---|---|
| a chamada de add | `QBittorrentProxyV2.cs:146-150`, `:168-172` | `:145-149`, `:167-171` | monta a requisição, não define timeout |
| o builder | `NzbDrone.Common/Http/HttpRequestBuilder.cs:104-116` | mesmo arquivo `:104-116` | `Apply()` não tem linha de `RequestTimeout`, e a classe não tem essa propriedade |
| o valor padrão do campo | `NzbDrone.Common/Http/HttpRequest.cs:52` | `:54` | a auto-property nunca é atribuída no construtor, então fica `TimeSpan.Zero` |
| o dispatcher | `NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:70-79` | `:68-77` | `Zero` vira `cts.CancelAfter(TimeSpan.FromSeconds(100))` |

```csharp
using var cts = new CancellationTokenSource();
if (request.RequestTimeout != TimeSpan.Zero) { cts.CancelAfter(request.RequestTimeout); }
else { /* The default for System.Net.Http.HttpClient */ cts.CancelAfter(TimeSpan.FromSeconds(100)); }
```

`RequestTimeout` e `Timeout` não aparecem em lugar nenhum em `src/NzbDrone.Core/Download/Clients/QBittorrent/`, nos dois repositórios, e `HttpRequestBuilder` não oferece forma de definir um. Ou seja, um shim não pode ganhar mais tempo por configuração.

Cinco coisas decorrem disso.

- **Os 100 s vêm do token de cancelamento do próprio Sonarr, não do timer do .NET.** O handler por baixo é criado com `Timeout = Timeout.InfiniteTimeSpan` (`ManagedHttpDispatcher.cs:183` no Sonarr, `:180` no Radarr), então o token é o único limite. Ele é passado tanto para `SendAsync` quanto para `ReadAsByteArrayAsync` (`:115`, `:127`), o que significa que cobre conexão, corpo da requisição, cabeçalhos da resposta e corpo da resposta.
- **Um timeout é reportado ao usuário como falha de conexão.** Ao expirar, é lançado `new WebException("Http request timed out", …)` (`:142-145`), que `ProcessRequest` embrulha como `DownloadClientException("Failed to connect to qBittorrent, please check your settings.", ex)` (`QBittorrentProxyV2.cs:424-427`). Um shim que bloqueia além de 100 s, portanto, parece mal configurado em vez de lento, e o *arr nunca fica sabendo que o add ainda estava em andamento.
- **Não existe timeout de conexão separado nem orçamento maior para upload multipart.** `SocketsHttpHandler.ConnectTimeout` nunca é definido. A única exceção é um limite de 2 s na primeira tentativa de IPv6 durante o tempo de vida do processo (`ManagedHttpDispatcher.cs:23`, `:288-295`), que cai para IPv4 dentro dos mesmos 100 s. Um upload de `.torrent` é armazenado inteiro em um array de bytes (`HttpRequestBuilder.cs:220-221`, `ManagedHttpDispatcher.cs:103`) e enviado sob o mesmo token.
- **Existe um limite de 300 s, mas em outro caminho.** `HttpClient.cs:285` define `request.RequestTimeout = TimeSpan.FromSeconds(300)` dentro de `DownloadFileAsync`, que busca o `.torrent` no indexador. Ele nunca chega a uma chamada de download client.
- **O Deluge prova que existe um override, e o qBittorrent não o usa.** `DelugeProxy.cs:222` faz `requestBuilder.PostProcess += r => r.RequestTimeout = TimeSpan.FromSeconds(15)`. O `BuildRequest` do qBittorrent não tem essa linha, e essa é a prova direta de que os 100 s são herdados e não escolhidos.

**O Radarr é idêntico.** Um diff do bloco de timeout (Radarr `:68-78` contra Sonarr `:70-80`) volta byte a byte igual, e a única diferença na cadeia é que o Radarr passa `ex` onde o Sonarr passa `ex.InnerException` para o `WebException`.

**Consequência para o shim.** Toda decisão síncrona tomada dentro de `torrents/add` compartilha um único orçamento de 100 s, e o *arr não tem como diferenciar "ainda trabalhando" de "inacessível". O deadline por tentativa multiplicado pelo número de provedores tentados, somado a qualquer janela de sondagem somente-em-cache, precisa ficar bem abaixo disso. As latências medidas dos provedores que formam esse orçamento estão em [torrent-lifecycle.md](torrent-lifecycle.md).

Uma observação complementar, para completar. Os 100 s valem por chamada do dispatcher, então cada salto de uma cadeia de redirecionamento automático recebe um orçamento novo (`HttpClient.cs:43` limita a cadeia em 5). A estratégia de retry em `DownloadClientBase.cs:30-44` **não** se aplica aqui; ela só é usada ao buscar o `.torrent` no indexador (`TorrentClientBase.cs:142-144`).

### 1.8 `GET /api/v2/torrents/properties?hash=<hash>` — `IsTorrentLoaded` / `GetTorrentProperties`

`IsTorrentLoaded` (`QBittorrentProxyV2.cs:110-126`) chama o método com `LogHttpError = false` e trata **qualquer** exceção como "não carregado".

`GetTorrentProperties` (`:128-135`) desserializa para `QBittorrentTorrentProperties` (`QBittorrentTorrent.cs:48-57`) — **três campos, e só dois são usados**:

| Chave JSON | C# | Usado para |
|---|---|---|
| `hash` | `Hash` | lido, nunca usado |
| `save_path` | `SavePath` | caminho pré-2.6.1 do `GetImportItem` (`QBittorrent.cs:354`) |
| `seeding_time` | `SeedingTime` (`long`, **segundos**) | `FetchTorrentDetails` (`:739-744`) |

**A capitalização do hash é inconsistente aqui e isso importa.** Todas as outras chamadas deixam o hash em minúsculas (`item.DownloadId.ToLower()` em `:335`, `:346`, `:353`; `hash.ToLower()` em `:97`, `:109`, `:121`, `:198`), mas `FetchTorrentDetails` passa `torrent.Hash` **sem alterar** (`:741`) — seja lá o que o shim colocou em `torrents/info`. O qBittorrent real devolve hashes em minúsculas, então isso nunca dá problema com ele. O fixture do Sonarr fixa essa assimetria ao simular `GetTorrentProperties("HASH", …)` com o valor em maiúsculas (Sonarr `QBittorrentFixture.cs:669-675`, Radarr `:668-674`). **Devolva hashes em minúsculas em `torrents/info` e faça a comparação de `?hash=` sem diferenciar maiúsculas de minúsculas.**

`FetchTorrentDetails` só é chamado por `HasReachedSeedingTimeLimit` (`:700`), que só é executado quando um limite de tempo de seeding está de fato ativo. Então, um shim que não declara limites de tempo de seeding nunca recebe essa chamada durante o polling. Mesmo assim, ela é necessária para `IsTorrentLoaded`, que é a verificação de prontidão logo após a adição: **404 para um hash desconhecido, 200 + JSON para um conhecido.**

O resultado fica em cache por 5 minutos para cada `{Host}{Port}{Hash}` (`:678`, `:689`, `:695`, `:708`), e o fixture verifica que ele é buscado uma vez, e não duas, em duas consultas seguidas (Sonarr `QBittorrentFixture.cs:905-920`, Radarr `:904-919`).

### 1.9 `POST /api/v2/torrents/setShareLimits` — `SetTorrentSeedingConfiguration` (`:286-308`)

Formato: `hashes=<lowercase hash>`, depois `AddTorrentSeedingFormParameters(request, seedConfiguration, always: true)`
— com `always: true`, **ambos** `ratioLimit` e `seedingTimeLimit` são sempre enviados, mesmo quando for `-2`
(`:232`, `:237`). `inactiveSeedingTimeLimit` nunca é enviado.

Um **404** é ignorado silenciosamente (`:298-307`, comentário: "setShareLimits was added in api v2.0.1"). Qualquer outro erro se propaga, mas o ponto de chamada captura e registra um aviso (`QBittorrent.cs:95-102`, `:152-159`).

Só é executado quando o indexador fornece uma configuração de seeding *e* a webapi é `< 2.8.1`. Em um shim que informa `2.11.2`, os limites de compartilhamento vão no `torrents/add`, e essa rota nunca é usada para um grab. Implemente-a como um no-op que retorna 200.

### 1.10 `POST /api/v2/torrents/topPrio` — `MoveTorrentToTopInQueue` (`:310-330`)

Forma: `hashes=<lowercase hash>`.

Um **409 Conflict** é ignorado (`:320-329`, comentário: "qBittorrent rejects all Prio commands with 409:
Conflict if Options -> BitTorrent -> Torrent Queueing is not enabled"). O proxy v1 ignora um **403** em vez disso (`QBittorrentProxyV1.cs:255-264`). Qualquer outro erro é capturado e gera um aviso no ponto de chamada (`QBittorrent.cs:107-114`, `:164-171`) — o fixture verifica que uma falha aqui não faz o grab falhar (Sonarr `QBittorrentFixture.cs:525-542`, Radarr `:524-541`).

Só é chamado quando a configuração de prioridade Recent/Older está em `First` (`QBittorrentPriority.First = 1`, `QBittorrentPriority.cs:5-6`); o padrão é `Last = 0`.

### 1.11 `POST /api/v2/torrents/setForceStart` — `SetForceStart` (`:332-339`)

Forma: `hashes=<lowercase hash>`, `value=true` (a string literal em minúsculas, `:337`).

Só é chamado quando `InitialState` é `ForceStart` (`QBittorrentState.cs:10-11`, `QBittorrent.cs:82`, `:117-127`). Os erros são capturados e registrados como aviso (`:123-126`).

### 1.12 `GET /api/v2/torrents/info[?category=<cat>]` — `GetTorrents` (`:97-108`)

**O único parâmetro enviado é `category`, e só quando a configuração não está em branco**
(`:100-103`). Nada de `filter`, `hashes`, `sort`, `reverse`, `limit`, `offset` ou `tag`.
O cliente **não** filtra por categoria de novo depois, diferente do cliente SAB, que filtra duas vezes. Então um shim que ignore `category` vai entregar ao Radarr os torrents do Sonarr.

O campo `category` na resposta importa por um segundo motivo: um torrent para o qual o \*arr **não tem histórico de grab** é ignorado logo de cara, a menos que tenha um. Veja `CompletedDownloadService.Check` (`CompletedDownloadService.cs:84-88`):

```csharp
if (historyItem == null && trackedDownload.DownloadItem.Category.IsNullOrWhiteSpace())
{
    trackedDownload.Warn("Download wasn't grabbed by Sonarr and not in a category, Skipping.");
    return;
}
```

`Category` é `category` se não estiver em branco, senão `label` (`QBittorrent.cs:231`).

Resposta: um **array** JSON. Cada campo consumido e o que ele vira:

| Chave JSON | Tipo C# | Unidades | Vira |
|---|---|---|---|
| `hash` | `string` | | `DownloadId = torrent.Hash.ToUpper()` (`QBittorrent.cs:230`) — **em maiúsculas**, e enviado de volta em minúsculas em toda chamada seguinte |
| `name` | `string` | | `Title = torrent.Name` (`:232`) — veja §7.1 para tudo o que isso controla |
| `size` | `long` | bytes | `TotalSize` (`:233`); também `RemainingSize = (long)(size * (1.0 - progress))` (`:235`) |
| `progress` | `double` | 0..1 | `RemainingSize` (`:235`) |
| `eta` | `BigInteger` | segundos | `RemainingTime` via `GetRemainingTime` (`:236`, `:614-628`) |
| `state` | `string` | | `Status`, `Message` e metade da condição `CanMoveFiles` (`:242-312`) — §2 |
| `category` | `string` | | `Category`, preferido (`:231`) |
| `label` | `string` | | `Category`, usado como fallback quando `category` está em branco (`:231`). Campo da versão anterior à 3.3.5; o qBittorrent 5 não o envia |
| `ratio` | `float` | | `SeedRatio` (`:237`), `HasReachedSeedLimit` (`:634`, `:641`) |
| `ratio_limit` | `float`, padrão `-2` | | `HasReachedSeedLimit` (`:632-645`) |
| `seeding_time_limit` | `long`, padrão `-2` | **minutos** | `HasReachedSeedingTimeLimit` (`:659-670`) |
| `inactive_seeding_time_limit` | `long`, padrão `-2` | **minutos** | `HasReachedInactiveSeedingTimeLimit` (`:723-736`) |
| `last_activity` | `long` | **segundos unix** | `HasReachedInactiveSeedingTimeLimit` (`:736`) |
| `seeding_time` | `long?`, padrão null | segundos | `HasReachedSeedingTimeLimit` (`:672-676`) — o comentário em `QBittorrentTorrent.cs:36` diz que ele "not provided by the list api", mas o cliente o usa se estiver presente, o que economiza uma ida e volta a `torrents/properties` |
| `save_path` | `string` | | comparado com `content_path` (`:316`) |
| `content_path` | `string` | | `OutputPath` na webapi `>= 2.6.1` (`:318`) — §4 |

`GetRemainingTime` (`:614-628`):

```csharp
if (torrent.Eta < 0 || torrent.Eta > 365 * 24 * 3600) { return null; }   // > 31,536,000 s
if (torrent.Eta == 8640000) { return null; }                            // qBittorrent's "unknown"
return TimeSpan.FromSeconds((int)torrent.Eta);
```

e um item Completed tem `RemainingTime` forçado para `TimeSpan.Zero` depois (`:273`).

`torrents/info` é buscado a cada `RefreshMonitoredDownloads` (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:94`), que também é agrupado (debounce) na fila de comandos 5 s depois de eventos relevantes (`:53`).

### 1.13 `GET /api/v2/torrents/files?hash=<hash>` — `GetTorrentFiles` (`:137-144`)

Resposta: um array JSON desserializado em `List<QBittorrentTorrentFile>`, que tem **exatamente um
membro**: `Name` (`QBittorrentTorrent.cs:59-62`), ligado ao campo `name`. É o caminho do arquivo **relativo ao save path**, com separadores `/` em todos os sistemas operacionais ("QBittorrent retorna separadores `/` mesmo no windows", `QBittorrent.cs:358`).

Chamado só por `GetImportItem` (`:346`) e só quando `OutputPath` ainda está vazio, ou seja, na webapi `< 2.6.1` ou quando `content_path` veio vazio. Os campos `index`, `size`, `progress`, `priority`, `is_seed`, `piece_range` e `availability` são todos ignorados.

Um **array vazio** é tratado: `_logger.Debug("No files found for torrent {0} in qBittorrent")` e o item é retornado sem mudanças (`:347-351`), o que depois falha em `ValidatePath`.

### 1.14 `POST /api/v2/torrents/setCategory` — `SetTorrentLabel` (`:204-211`)

Formato: `hashes=<lowercase hash>`, `category=<post-import category>`.

Chamado somente por `MarkItemAsImported` (`QBittorrent.cs:52-69`), e somente quando a configuração opcional
`TvImportedCategory` / `MovieImportedCategory` não está em branco e é diferente da categoria principal. Uma `DownloadClientException` é capturada e gera um aviso:
"Failed to set post-import torrent label \"{0}\" for {1} in qBittorrent. Does the label exist?"
(`:62-67`). §5.1.

### 1.15 `POST /api/v2/torrents/delete` — `RemoveTorrent` (`:190-202`)

Formato: `hashes=<lowercase hash>`, mais `deleteFiles=true` **somente quando `removeData` for true**
(`:196-199`) — a string literal em minúsculas, não `Convert.ToString(bool)`.

`QBittorrent.RemoveItem` (`:333-336`) é a implementação inteira:

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    Proxy.RemoveTorrent(item.DownloadId.ToLower(), deleteData, Settings);
}
```

**Ele não chama `DeleteItemData`.** Essa é a diferença em relação ao cliente SAB, que apaga a pasta do job por conta própria, pelo sistema de arquivos
(`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146`; veja [sabnzbd-client-contract.md §5.3](sabnzbd-client-contract.md)). Aqui a remoção dos dados fica inteiramente por conta do cliente de download. §5.

(Uma tradução anterior foi recusada: os trechos de código ficaram diferentes. Mantenha a estrutura exatamente como está.)

### 1.16 Endpoints que o cliente nunca usa {#116-endpoints-the-client-never-touches}

Não estão na interface de jeito nenhum, então nunca são chamados: `torrents/pause`, `torrents/resume`, `torrents/stop`,
`torrents/start`, `torrents/setLocation`, `torrents/rename`, `torrents/recheck`,
`torrents/reannounce`, `torrents/filePrio`, `torrents/setDownloadLimit`, `torrents/setUploadLimit`,
`torrents/toggleSequentialDownload`, `torrents/setAutoManagement`, `torrents/editCategory`,
`torrents/removeCategories`, tags, RSS, pesquisa, `app/setPreferences`, `app/defaultSavePath`,
`app/shutdown`, `sync/maindata`, `transfer/*`, `auth/logout`. Pausar e retomar existem apenas como o campo de formulário `paused=`/`stopped=` em `torrents/add`.

Estão na interface, mas nunca são chamados a partir de `QBittorrent.cs`: `GetVersion` (§1.2).

### 1.17 O mapa de rotas v1 (por completude; não implemente) {#117-the-v1-route-map-for-completeness-do-not-implement}

`QBittorrentProxyV1.cs`: `/version/api` (`:30`, `:64` — o cliente coloca `"1."` na frente de qualquer coisa que volta, `:65`), `/version/qbittorrent` (`:73`), `/query/preferences` (`:81`), `/query/torrents?label=&category=` (`:89-94` — **ambos** os parâmetros), `/query/propertiesGeneral/{hash}` (`:103`, `:120`), `/query/propertiesFiles/{hash}` (`:128`), `/command/download` (`:136`), `/command/upload` (`:166`), `/command/delete` ou `/command/deletePerm` (`:196` — a distinção entre delete e deleteFiles são duas rotas diferentes, não um parâmetro), `/command/setCategory` com um fallback para `/command/setLabel` em caso de 404 (`:205-225`), `/command/addCategory` (`:230`), `/command/topPrio` (`:248`), `/command/setForceStart` (`:269`), `/login` (`:345`).

## 2. `state` → `DownloadItemStatus`

`QBittorrent.GetItems` (`:247-312`). Os estados são as strings próprias do qBittorrent, produzidas por `torrentStateToString` (`qBittorrent/src/webui/api/serialize/serialize_torrent.cpp:44-87`).

| `state` | `DownloadItemStatus` | `Message` | Linha |
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
| `metaDL` | Queued **se `dht: true`**, senão Warning | "qBittorrent is downloading metadata" / "qBittorrent cannot resolve magnet link with DHT disabled" | `:286-299` |
| `forcedMetaDL` | igual a `metaDL` | igual | `:287` |
| `forcedDL` | Downloading | — | `:301` |
| `moving` | Downloading | — | `:302` |
| `downloading` | Downloading | — | `:303` |
| **qualquer outro** | **Downloading** | "Unknown download state: {state}" | `:307-311` |

Pontos que um shim precisa respeitar:

- **Um estado desconhecido não lança exceção.** Ele registra `_logger.Info($"Unknown download state: {torrent.State}")` e cai em Downloading (`:307-311`). É o oposto do cliente SAB, onde um nome de status desconhecido lança exceção dentro do deserializador e derruba a consulta inteira. Ainda assim, envie apenas nomes que estejam nesta tabela.
- **Só os estados Completed podem ser importados.** `CompletedDownloadService.Check` retorna logo de cara, a menos que `Status == Completed` (`src/NzbDrone.Core/Download/CompletedDownloadService.cs:68-71`).
- **Todo estado Completed zera o `RemainingTime`** (`:273`, com o comentário "qBittorrent sends eta=8640000 for completed torrents").
- `metaDL` / `forcedMetaDL` é a fase "magnet, ainda sem metadados". **Não existe timeout** no cliente: ele fica em Queued enquanto o shim continuar mandando `metaDL`, e nunca vira falha sozinho. A única coisa que transforma isso em Warning é `dht: false` em `app/preferences` (`:288`). O tratamento de downloads com falha do Sonarr escala pela idade do grab, não por este estado.
- `stalledDL` é o *aviso* que o operador vê para um torrent que não está andando. Um shim sem conceito de peers nunca deve usá-lo: um Warning em um download rastreado aparece na fila como problema e é o que o `FailedDownloadService` inspeciona.
- `error` e `missingFiles` são Warnings de propósito, "so failed download handling isn't triggered" (`:249`). Se um shim quiser que o Sonarr coloque na blocklist e busque de novo, Warning **não** é o jeito de pedir isso.

## 3. Mover vs copiar — a condição exata e a receita {#3-move-vs-copy--the-exact-condition-and-the-recipe}

### 3.1 O gate {#31-the-gate}

`QBittorrent.cs:240-245`, verbatim including the comment que explica isso:

```csharp
// Avoid removing torrents that haven't reached the global max ratio.
// Removal also requires the torrent to be paused, in case a higher max ratio was set on the torrent itself (which is not exposed by the api).
item.CanMoveFiles = item.CanBeRemoved =
    item.DownloadClientInfo.RemoveCompletedDownloads &&
    torrent.State is "pausedUP" or "stoppedUP" &&
    HasReachedSeedLimit(torrent, config);
```

Três condições, todas obrigatórias:

1. **`RemoveCompletedDownloads`** — a configuração por cliente do lado do *arr, e não algo que o qBittorrent informa.
   O padrão de `DownloadClientDefinition.RemoveCompletedDownloads` é **`true`**
   (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17`), que aparece na interface como "Remove Completed". Se o usuário desligar essa opção, **as importações viram cópias** e o shim não tem nada que possa fazer a respeito. (Um Move também vira cópia por um segundo motivo, que o shim também não consegue ver: o container do \*arr acessa a pasta de downloads e a pasta raiz por meio de dois volumes, aí `rename()` responde `EXDEV` e o `File.Move` do .NET copia e apaga. O zurg lê os dois dados a partir da API de uma fonte de aquisição e depois adota a cópia; veja `internal/arrlayout` e `internal/handlers/magic_copies.go`.)
2. **`state` tem que ser exatamente `pausedUP` ou `stoppedUP`.** `uploading`, `stalledUP`, `queuedUP` e `forcedUP` estão Completed, mas não são movíveis — o fixture garante isso (Sonarr `QBittorrentFixture.cs:680-689`, Radarr `:679-688`).
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

- Um **`ratio_limit >= 0` por torrent** vence de vez e o global nem é consultado. `ratio_limit`
  é `-2` = "usar global" e `-1` = "ilimitado" no próprio modelo do qBittorrent
  (`QBittorrentTorrent.cs:32`; wiki, *Set torrent share limit*).
- `-1` (ilimitado) não satisfaz nenhum dos dois ramos — `-1 >= 0` é falso e `-1 == -2` é falso — então um torrent ilimitado **nunca** pode ser movido pela regra de ratio.
- A folga de `0.001f` é o que faz o "alcançado após arredondamento" funcionar; o fixture crava o ratio `1.1006066990976857` contra o limite `1.0` como alcançado, e `0.9999` também como alcançado (Sonarr `QBittorrentFixture.cs:715-737`, Radarr `:714-736`).

`HasReachedSeedingTimeLimit` (`:655-717`):

```csharp
if (torrent.SeedingTimeLimit >= 0)        { seedingTimeLimit = torrent.SeedingTimeLimit * 60; }        // minutes -> seconds
else if (torrent.SeedingTimeLimit == -2 && config.MaxSeedingTimeEnabled) { seedingTimeLimit = config.MaxSeedingTime * 60; }
else                                      { return false; }
```

depois usa `torrent.SeedingTime` se a API da lista tiver fornecido (`:672-676`); caso contrário, consulta um cache de 5 minutos e, em caso de falta, chama **`torrents/properties`** para `seeding_time` (`:678-716`, `:739-744`). `HasReachedInactiveSeedingTimeLimit` (`:719-737`) tem a mesma estrutura, mas compara `now - last_activity` com `inactive_seeding_time_limit` (ou o global) e nunca precisa de uma segunda chamada.

### 3.3 O que `CanMoveFiles` decide {#33-what-canmovefiles-decides}

`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, series, importItem)` (`CompletedDownloadService.cs:148-151`), e aí dois lugares leem `CanMoveFiles`:

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

(Radarr: `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, idêntico.)

```csharp
// src/NzbDrone.Core/MediaFiles/DownloadedEpisodesImportService.cs:204-207
if (importMode == ImportMode.Auto)
{
    importMode = (downloadClientItem == null || downloadClientItem.CanMoveFiles) ? ImportMode.Move : ImportMode.Copy;
}
```

(Radarr: `DownloadedMovieImportService.cs:221-224`.)

`copyOnly == false` → `TransferMode.Move` (`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`); `copyOnly == true` → `TransferMode.HardLinkOrCopy` se a opção "Use Hardlinks instead of Copy" estiver ligada, senão `TransferMode.Copy` (`:103`, `:107`). `TransferMode` é `[Flags] None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy=Copy|HardLink` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`).

**Um Move que falhou nunca cai para um Copy.** O argumento completo, com números de linha, está em [sabnzbd-client-contract.md §5.5](sabnzbd-client-contract.md); `DiskTransferService.cs` é compartilhado e byte a byte idêntico entre os dois repositórios. A versão curta: o ramo Move de `TransferFile` (`src/NzbDrone.Common/Disk/DiskTransferService.cs:360-389`) tem exatamente um caminho de cópia, escolhido logo no início a partir de `targetMount.DriveFormat == "cifs"` (`:342`, `:378-385`), nunca como reação a uma falha; `TryMoveFileVerified` relança a exceção (`:487-503`), e `VerifyFile` lança `IOException("File move incomplete, data loss may have occurred. …")` quando o tamanho do destino não bate com o da origem (`:505-524`).

### 3.4 Com os padrões do próprio qBittorrent, a importação é uma **cópia** {#34-with-qbittorrents-own-defaults-the-import-is-a-copy}

Pegue um torrent que um shim reporta de forma ingênua, com os padrões do qBittorrent, que também são os padrões do modelo:

| Campo | Valor | Efeito |
|---|---|---|
| `state` | `stoppedUP` | conjunto 2 ✓ |
| `ratio_limit` | `-2` (padrão, `QBittorrentTorrent.cs:33`) | cai no ramo global |
| `max_ratio_enabled` | `false` (padrão do próprio qBittorrent; corpo do exemplo da wiki `:684`) | o ramo global falha |
| `seeding_time_limit` | `-2` | precisa de `max_seeding_time_enabled` |
| `max_seeding_time_enabled` | `false` (wiki `:686`) | falha |
| `inactive_seeding_time_limit` | `-2` | precisa de `max_inactive_seeding_time_enabled` |
| `max_inactive_seeding_time_enabled` | `false` | falha |

⇒ `HasReachedSeedLimit` falso ⇒ `CanMoveFiles` falso ⇒ `copyOnly` verdadeiro ⇒ `TransferMode.Copy` ⇒ **o \*arr lê cada byte do release do mount e grava de volta.** Num mount de debrid, esse é justamente o resultado que todo o design existe para evitar, e ele falha em silêncio: nada avisa, a importação simplesmente leva horas e enche um disco.

O fixture crava exatamente este caso:
`should_not_be_removable_and_should_not_allow_move_files_if_max_ratio_is_not_set`
(Sonarr `QBittorrentFixture.cs:691-701`, Radarr `:690-700`) — limites globais desligados, torrent pausado, ratio 1.0, `CanMoveFiles == false`.

### 3.5 A receita {#35-the-recipe}

Para cada torrent que um shim quer importar com **move**:

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

`ratio_limit: 0` pega o primeiro ramo (`0 >= 0`, e `0 - 0 <= 0.001`) e as preferências globais nunca são consultadas. Por isso `max_ratio_enabled` pode ficar `false` e o health check `DownloadClientRemovesCompletedDownloadsCheck` fica quieto. Qualquer `ratio_limit >= ratio` dentro de `0.001` funciona; `0`/`0` é o único que não precisa de coordenação.

Sobre `pausedUP` vs `stoppedUP`: **o develop trata os dois de forma idêntica**, tanto no gate `CanMoveFiles` (`:244`) quanto no mapa de status (`:266-267`), e todo fixture de seed-limit é um par de `[TestCase]` que cobre os dois. `stoppedUP` é a grafia do qBittorrent 5 (`serialize_torrent.cpp:54-55`; `pausedUP` não existe mais no master). `pausedUP` é a escolha mais segura para builds de \*arr *lançadas*, porque o ramo `stoppedUP` foi adicionado quando o qBittorrent 5 chegou, e as versões mais antigas do Sonarr v4 / Radarr v5 só conhecem `pausedUP`. Esse último ponto é uma inferência sobre tags mais antigas, não algo que as fontes do develop acima comprovam.

E tem uma coisa que não está nas mãos do shim: **"Remove Completed" precisa continuar ligado nas configurações de download-client do \*arr.** Ele já vem ligado por padrão (`DownloadClientDefinition.cs:17`). Documente isso, porque desligá-lo converte silenciosamente cada importação em um download completo.

## 4. `OutputPath` — de onde o \*arr é instruído a importar {#4-outputpath--where-the-arr-is-told-to-import-from}

### 4.1 O caminho 2.6.1+: `content_path` {#41-the-261-path-content_path}

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

O texto do aviso (`src/NzbDrone.Core/Localization/Core/en.json`):

> Unable to Import. Path matches client base download directory, it's possible 'Keep top-level folder'
> is disabled for this torrent or 'Torrent Content Layout' is NOT set to 'Original' or 'Create Subfolder'?

Regras que um shim precisa cumprir:

- `content_path` **não pode ser igual** a `save_path`. A igualdade é a falha, não um fallback: o item vira um Warning e nunca é importado.
- `content_path` precisa ser absoluto e válido para o SO em que o \*arr roda. `CompletedDownloadService.ValidatePath` (`CompletedDownloadService.cs:295-313`) rejeita caso contrário, com "[{0}] is not a valid local path. You may need a Remote Path Mapping."
- Ele precisa existir no host do \*arr como **pasta ou arquivo**. `ProcessPath` (`DownloadedEpisodesImportService.cs:80-105`) verifica primeiro `FolderExists` e depois `FileExists`, e cai em `LogInaccessiblePathError` + resultado vazio se nenhum dos dois existir.
- Não envie um `content_path` vazio. Ele "difere" de um `save_path` não vazio, então `OutputPath` é definido como um `OsPath` vazio, e `GetImportItem` então cai na varredura de `torrents/files` (§4.2), porque `item.OutputPath.IsEmpty` é verdadeiro (`:341-344`).
- Este bloco só roda para itens **Completed**, então `content_path` só importa quando o estado está em um dos estados Completed de §2.

O que o qBittorrent real coloca ali é `TorrentImpl::contentPath()` (`qBittorrent/src/base/bittorrent/torrentimpl.cpp:577-587`):

```cpp
Path TorrentImpl::contentPath() const
{
    if (!hasMetadata())    return {};
    if (filesCount() == 1) return (actualStorageLocation() / filePath(0));   // the FILE, not a folder
    const Path rootPath = this->rootPath();
    return (rootPath.isEmpty() ? actualStorageLocation() : rootPath);
}
```

com `rootPath()` = `actualStorageLocation() / Path::findRootFolder(filePaths())` (`:565-575`). Ou seja: o `content_path` de um torrent de **arquivo único** é o próprio arquivo; um torrent com vários arquivos e uma pasta raiz comum recebe essa pasta; um torrent com vários arquivos **sem** raiz comum recebe o `save_path`, exatamente o caso que o aviso de `content_path == save_path` do cliente trata.

`RemapRemoteToLocal(Settings.Host, …)` aplica os Remote Path Mappings do usuário, usando como chave a string de **Host** configurada. Se o \*arr roda em um container e o shim informa o caminho do host, o operador precisa de um mapeamento. Veja [sabnzbd.md](../guides/sonarr-radarr.md#8-if-your-arr-is-in-docker), que se aplica sem mudanças.

### 4.2 O caminho pré-2.6.1: `GetImportItem` percorre `torrents/files` {#42-the-pre-261-path-getimportitem-walks-torrentsfiles}

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

Ele usa **somente `files[0].name`**, sobe até o componente de caminho mais alto e junta isso a
`properties.save_path`. O fixture cobre os três formatos (Sonarr `QBittorrentFixture.cs:317-421`,
Radarr `:296-400`):

| `files[0].name` | `save_path` | `OutputPath` |
|---|---|---|
| `Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` |
| `Folder/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Folder` |
| `Droned.S01.12/E01.mkv` (+ `E02.mkv`) | `/Torrents` | `/Torrents/Droned.S01.12` |

Repare na terceira linha: o resultado é a raiz de `files[0]`, não uma raiz comum calculada, então **um shim nesse caminho precisa
listar os arquivos em uma ordem em que a primeira entrada tenha a pasta do lançamento**. Um shim que informa webapi
`>= 2.6.1` nunca chega aqui, o que é mais um motivo para informar `2.11.2`.

`previousImportAttempt` é um parâmetro de `GetImportItem` (`:338`) e **nunca é lido** por esta
implementação. Nada sobre uma tentativa com falha fica guardado.

### 4.3 Quando o caminho está errado, e com que frequência ele é tentado de novo {#43-when-the-path-is-wrong-and-how-often-it-is-retried}

Não há backoff nem limite de tentativas em nenhum ponto deste caminho.

- `CompletedDownloadService.Check` roda para cada download rastreado nos estados `Downloading` ou `ImportBlocked`, a cada refresh
  (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:125-129`).
- `Check` chama `SetImportItem` **primeiro** (`CompletedDownloadService.cs:73`), que é `_provideImportItemService.ProvideImportItem(...)` → `client.GetImportItem(...)`
  (`:290-293`, `src/NzbDrone.Core/Download/ProvideImportItemService.cs:17-22`). Ou seja, `OutputPath` é recalculado a partir da linha *atual* de `torrents/info` a cada poll.
- Falhas no `ValidatePath` (`:295-313`) geram um Warning e deixam o estado em `Downloading`, então o próximo poll tenta de novo do zero:
  - output path vazio → "Download doesn't contain intermediate path, Skipping."
  - caminho do SO errado → "[{0}] is not a valid local path. You may need a Remote Path Mapping. …"
- `Import` também chama `SetImportItem` logo na entrada (`:130`), antes de reler `trackedDownload.ImportItem.OutputPath.FullPath` (`:147`), e é disparado a partir do estado `ImportPending` pelo `DownloadProcessingService`
  (`src/NzbDrone.Core/Download/DownloadProcessingService.cs:61-63`). Uma importação que falha deixa o estado em `ImportPending` (`:158`) ou o move para `ImportBlocked` (`:196`). Os dois são processados de novo.
- Um caminho que existe mas não tem nada importável gera "No files found are eligible for import in {0}" (`:162`) e continua em `ImportPending`.

**Consequência para um shim: `content_path` pode ficar errado por um tempo.** Reporte o torrent como Downloading (ou Queued) até que a pasta realmente exista e os tamanhos dos arquivos estejam finais, e o cliente vai continuar fazendo polling. Reportar Completed cedo demais gasta uma tentativa de importação em cima de uma pasta que não está pronta e, pior, o \*arr pode mover um arquivo com tamanho parcial e depois falhar no `VerifyFile`, já tendo esvaziado a origem. É a mesma armadilha documentada para o endpoint do SAB ([sabnzbd.md](../guides/sonarr-radarr.md), *O que acontece em um grab*, passo 5).

## 5. A sequência pós-importação {#5-the-post-import-sequence}

### 5.1 O que dispara, em ordem {#51-what-fires-in-order}

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

e `RemoveFromDownloadClient` (`:87-103`) é:

```csharp
_logger.Debug("[{0}] Removing download from {1} history", ...);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);             // :92  deleteData: TRUE
trackedDownload.DownloadItem.Removed = true;
```

Então a sequência de chamadas depois de uma importação bem-sucedida é:

1. **`POST /api/v2/torrents/setCategory`**: só se uma categoria pós-importação estiver configurada
   (`QBittorrent.cs:52-69`). Fica de fora por padrão.
2. Antes de qualquer uma dessas, e fora do cliente de download: **o \*arr move o arquivo** e, depois, o
   `ProcessFolder` pode **apagar a própria pasta de origem**
   (`DownloadedEpisodesImportService.cs:209-223`, Radarr `DownloadedMovieImportService.cs:226-240`):

   ```csharp
   if (importMode == ImportMode.Move &&
       importResults.Any(i => i.Result == ImportResultType.Imported) &&
       ShouldDeleteFolder(directoryInfo, series))
   {
       _diskProvider.DeleteFolder(directoryInfo.FullName, true);   // recursive
   }
   ```

   O `ShouldDeleteFolder` (`:108-153`) recusa quando algum arquivo de vídeo que sobrou na pasta é reconhecido e não é uma amostra (`:117-133`), ou quando sobra um `.rar` maior que 10 MB (`:135-139`). Depois de uma movimentação bem-sucedida de um arquivo único, nenhuma dessas condições se aplica, então a pasta **é** removida. Uma `IOException` é capturada e registrada no log como Debug (`:219-222`).
3. **`POST /api/v2/torrents/delete`** com `hashes=<lowercase hash>&deleteFiles=true`
   (`QBittorrent.cs:335`, `QBittorrentProxyV2.cs:190-202`).

Outros dois eventos chegam ao mesmo `RemoveFromDownloadClient(…, true)`:

- `DownloadFailedEvent` (`DownloadEventHub.cs:26-46`), controlado pelo `RemoveFailedDownloads` de cada cliente (padrão `true`, `DownloadClientDefinition.cs:18`). Atenção: `TrackedDownload.Fail()` define `DownloadItem.CanBeRemoved = true` sem nenhuma condição (`src/NzbDrone.Core/Download/TrackedDownloads/TrackedDownload.cs:39-46`, comentário: "Set CanBeRemoved to allow the failed item to be removed from the client"). **Ou seja, um download com falha é apagado mesmo quando o controle de limite de seed diria o contrário.**
- `DownloadCanBeRemovedEvent` (`:71-85`).

Uma `NotSupportedException` vinda de `RemoveItem` vira apenas o aviso "Removing item not supported by your download client ({0})." (`:95-98`). Qualquer outra exceção é registrada como erro e o item *não* é marcado como Removed, então ele será tentado de novo na próxima consulta (`:99-102`).

### 5.2 O que o shim deve fazer com `deleteFiles=true` {#52-what-the-shim-must-do-with-deletefilestrue}

Esta é a mesma decisão que o `internal/sabnzbd` já tomou para `mode=history&name=delete`, pelo mesmo motivo. De `internal/sabnzbd/api.go:596-609`:

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

O caso do qBittorrent tem a mesma forma, com uma diferença: nessa API, apagar os dados é trabalho do *cliente*, não do \*arr, porque `RemoveItem` **não** chama `DeleteItemData` (§1.15). Mas o \*arr já apagou a pasta em si no passo 2 acima, pelo mount. Sob `__magic__`, isso grava uma lápide (tombstone): a entrada some de `__magic__`, mas continua exatamente onde estava em `__all__`, em todos os diretórios de filtro e na conta do debrid ([magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)).

Então:

- **`torrents/delete` remove o *registro* do torrent que o shim guarda para o \*arr.** Responda 200.
- **`deleteFiles` não pode apagar o torrent no provedor.** O release que o \*arr acabou de importar ainda é servido por ele, e apagá-lo destrói justamente o que foi importado. O único caso em que uma exclusão de verdade seria honesta é um torrent do qual nada foi importado, como no caminho de download com falha. Mesmo ali, um torrent de debrid é estado compartilhado da biblioteca, não um download temporário, então o padrão seguro é: **nunca apagar o torrent no provedor, só gerar a lápide.** Diga isso no documento voltado ao usuário, do jeito que [sabnzbd.md](../guides/sonarr-radarr.md) faz em *O que funciona, e o que não funciona*.
- Um `torrents/delete` para um **hash desconhecido** ainda deve responder 200. O qBittorrent real responde assim (wiki, *Excluir torrents*: "200 | Todos os cenários"), e um erro aqui seria registrado como erro e repetido a cada ciclo de polling para sempre.

### 5.3 `MarkItemAsImported` e a categoria pós-importação {#53-markitemasimported-and-the-post-import-category}

`QBittorrent.cs:52-69` define a categoria pós-importação quando `TvImportedCategory` / `MovieImportedCategory` está configurada e é diferente da categoria principal. Ela é chamada para **cada** importação concluída (`DownloadEventHub.cs:54`), antes da decisão de remoção.

Se um shim aceitar o `setCategory` e mover de fato o torrent para fora da categoria consultada, o torrent some na próxima chamada a `torrents/info?category=…`. Esse é justamente o objetivo da configuração, e é o que a UI mostra como `DownloadClientHasPostImportCategory` (`src/NzbDrone.Core/Queue/QueueService.cs:84`, obtido de `DownloadClientItemClientInfo.HasPostImportCategory`, `QBittorrent.cs:234`). Aceitar a chamada e registrar a nova categoria é o comportamento correto. Recusá-la gera apenas um aviso (`:62-67`).

## 6. `Test()` — cada verificação, em ordem, e sua mensagem {#6-test--every-check-in-order-and-its-message}

`DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`) envolve tudo: **qualquer exceção que escapa vira**
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

Cada ramo **retorna**, então no máximo uma falha sai deste método.

| Ordem | Condição | Propriedade | Mensagem |
|---|---|---|---|
| 1 | `_proxySelector.GetProxy(Settings, force: true).GetApiVersion(Settings)` — força a nova detecção (`:435`) | | |
| 2 | versão `< 1.5` (`:436`) | `Host` | "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| 3 | versão `< 1.6` **e** categoria definida (`:445-455`) | `Category` | "Category is not supported" / detalhe "Categories are not supported until qBittorrent version 3.3.0. Please upgrade or try again with an empty Category." |
| 4 | versão `>= 1.6` **e** categoria vazia (`:456-464`) | `TvCategory` / `MovieCategory` | **Warning** — "Category is recommended" / "{appName} will not attempt to import completed downloads without a category." |
| 5 | `GetConfig` e depois `RemovesCompletedDownloads(config)` (`:467-474`) | `""` | "qBittorrent is configured to remove torrents when they reach their Share Ratio Limit" / detalhe que cita Options → BitTorrent → Share Ratio Limiting |

Mapeamento de exceções (`:476-506`):

| Capturada | Propriedade | Mensagem |
|---|---|---|
| `DownloadClientAuthenticationException` | `ApiKey` se uma api key estiver definida, senão `Username` | "Authentication Failure" / "Please verify your credentials. Also verify if the host running {appName} isn't blocked from accessing {clientName} by WhiteList limitations…" |
| `WebException` com `Status == ConnectFailure` | `Host` | "Unable to connect to qBittorrent" / "Please verify the hostname and port." |
| qualquer outra `WebException` | `""` | "Unknown exception: {message}" |
| qualquer outra `Exception` | `Host` | "Unable to connect to qBittorrent", `DetailedDescription = ex.Message` |

Observe que o caso 4 é um **warning**, e `failures.HasErrors()` em `:421` retorna falso para warnings. Ou seja, uma configuração sem categoria ainda executa as outras três verificações.

### 6.2 `TestCategory` (`:511-556`) — o fluxo de "category does not exist" {#62-testcategory-511-556--the-category-does-not-exist-flow}

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

Falha: propriedade `TvCategory` / `MovieCategory` (ou `TvImportedCategory` / `MovieImportedCategory`),
mensagem "Configuration of category failed", detalhe "{appName} was unable to add the label to
qBittorrent."

Então um shim tem duas opções: ou envia as categorias configuradas logo de início para que `torrents/categories` já as contenha, ou aceita `createCategory` e reflete isso na próxima resposta de `torrents/categories`. **Não existe uma terceira opção**: o cliente lê de novo e falha se a chave ainda estiver ausente. Os nomes das categorias são comparados **exatamente**, diferenciando maiúsculas de minúsculas (`Dictionary<string, …>.ContainsKey` com o comparador ordinal padrão).

Observe o tratamento de `TvImportedCategory`: a categoria pós-importação também é verificada e criada aqui, mesmo que só seja usada depois de uma importação. Se o operador a definir, ela precisa existir.

`QBittorrentSettingsValidator` (`QBittorrentSettings.cs:23-24`) já recusa nomes de categoria que correspondam a `^([^\\\/](\/?[^\\\/])*)?$` (sem barra invertida, sem `//`, sem `/` no início ou no fim) antes de qualquer requisição ser feita.

### 6.3 `TestPrioritySupport` (`:558-597`) — a verificação de saúde `queueing` {#63-testprioritysupport-558-597--the-queueing-health-check}

```csharp
var recentPriorityDefault = Settings.RecentTvPriority == (int)QBittorrentPriority.Last;
var olderPriorityDefault  = Settings.OlderTvPriority  == (int)QBittorrentPriority.Last;
if (olderPriorityDefault && recentPriorityDefault) { return null; }   // :563-566  the default: nothing checked

var config = Proxy.GetConfig(Settings);
if (!config.QueueingEnabled) { … }                                    // :572-588
```

A propriedade de falha é `nameof(Settings.RecentTvPriority)` ou `nameof(Settings.OlderTvPriority)`
(verificadas nessa ordem), com a mensagem "Queueing Not Enabled" e o detalhe "Torrent Queueing is not enabled in
your qBittorrent settings. Enable it in qBittorrent or select 'Last' as priority."

Uma exceção aqui vira `("", "Unknown exception: {message}")` (`:590-594`).

`queueing_enabled` tem como padrão **`true`** no modelo (`QBittorrentPreferences.cs:41`), então um shim
que omite a chave passa, mas omitir é uma mentira se `topPrio` não fizer nada. Informar `queueing_enabled: false`
é honesto e só produz essa falha se o operador tiver mudado a configuração de prioridade para algo diferente de `Last`.

### 6.4 `TestGetTorrents` (`:599-612`)

`Proxy.GetTorrents(Settings)`; any exception becomes `("", "Failed to get the list of torrents:
{exceptionMessage}")`. This is the check that catches a malformed `torrents/info` body — a JSON object
instead of an array, a bad enum, a non-numeric `size`.

### 6.5 A verificação `dht` {#65-the-dht-check}

Não existe uma verificação de DHT dedicada em `Test()`. `dht` é consultado no momento do grab (`:73-76`, magnets sem trackers) e no momento do poll (`:288`, o ramo `metaDL`). Um shim que informa `dht: false` passa no teste de conexão e depois recusa todo magnet sem trackers com `ReleaseDownloadException("Magnet not supported by download client. …")` (`TorrentClientBase.cs:115`). **Informe `dht: true`.**

## 7. Análise e consequências da importação que um shim deve conhecer {#7-parsing-and-import-consequences-a-shim-should-know}

### 7.1 `name` vira `Title`, e `Title` é usado para três coisas diferentes {#71-name-becomes-title-and-title-is-used-for-three-different-things}

`DownloadClientItem.Title = torrent.Name` (`QBittorrent.cs:232`). Downstream:

1. **Identificação de série/filme.** `CompletedDownloadService.Check` faz `_parsingService.GetSeries(trackedDownload.DownloadItem.Title)` (`CompletedDownloadService.cs:95`). Se isso retornar null, ele cai para o **histórico de captura** indexado por `DownloadId` (`:99-102`), e se também faltar: "Series title mismatch; automatic import is not possible." + `ImportBlocked` (`:104-110`). O equivalente do Radarr fica em `ProcessFolder`, que lê `_historyService.FindByDownloadId(downloadClientItem?.DownloadId ?? "")` (`DownloadedMovieImportService.cs:193-194`).
   **Este é o segundo motivo pelo qual o shim precisa usar exatamente o infohash que o \*arr calculou** (§1.7): o fallback do histórico usa `DownloadId` como chave, então um hash diferente perde tanto o caminho pelo título quanto o fallback.
2. **Parsing do release para a decisão de importação.**
   `downloadClientItemInfo = Parser.Parser.ParseTitle(downloadClientItem.Title)`
   (Sonarr `ImportDecisionMaker.cs:80`; Radarr `ParseMovieTitle`, `:80`), atribuído a
   `LocalEpisode.DownloadClientEpisodeInfo` / `LocalMovie.DownloadClientMovieInfo` (`:94` / `:92`).
3. **Linhas de log e a interface da fila.**

**Gate de fallback de título do Sonarr.** `AggregateEpisodes.GetBestEpisodeInfo`
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

Três gates para usar o título do cliente de download em vez do nome do arquivo: `!OtherVideoFiles`,
o nome do arquivo não é ele próprio um título scene, e o título do cliente não é um parse de temporada completa. Então o
nome do torrent só salva um release de arquivo único, sem nome scene.

O Radarr **não tem um gate equivalente de vencedor único**. `LocalMovie.OtherVideoFiles` existe
(`src/NzbDrone.Core/Parser/Model/LocalMovie.cs:36`), mas as informações parseadas do filme são mescladas por uma cadeia de augmenters ordenada por confiança, em vez de escolher uma (`AggregateQuality.cs:25-121`); o título do cliente de download alimenta esses augmenters, e a identidade do filme vem do parse da pasta mais o histórico de captura (`DownloadedMovieImportService.cs:192-195`).

**`OtherVideoFiles`** (`ImportDecisionMaker.cs:85`, `:100`, Radarr `:83`, `:98`):

```csharp
var nonSampleVideoFileCount = sceneSource ? GetNonSampleVideoFileCount(newFiles, series, downloadClientItemInfo, folderInfo) : videoFiles.Count;
…
OtherVideoFiles = nonSampleVideoFileCount > 1
```

`ProcessFolder` sempre passa `sceneSource: true` (`DownloadedEpisodesImportService.cs:201`), então uma pasta com dois ou mais vídeos que não são sample define `OtherVideoFiles`, e o título do cliente de download fica fora da disputa para todos os arquivos dela.

**Por que isso importa no zurg.** A Real-Debrid reescreve nomes de release que caem no filtro de nome de arquivo dela: `WEB-DL`, `WEB.x264` e `WEB.H264` exatamente com essa capitalização, `WEBRip`, `BDRip`, `HDRip`, `DVDRip`, `HDTV.x264`, `HDTV.XviD`, `BluRay.x264` e `p.BluRay.DTS` em qualquer capitalização, conforme medido em 2026-10-14. Além disso, o zurg adiciona um sufixo quando dois releases colidem no mesmo nome. Qualquer um dos dois pode fazer o `torrent.name` deixar de parsear como o release capturado. Veja a seção RD 451 do `CLAUDE.md` do monorepo. As consequências, em ordem: a identificação cai para o histórico de captura (continua ok, se o hash bater); o parse por arquivo do Sonarr assume (ok para um arquivo com nome bem formado dentro da pasta); e o nome da pasta sob `__magic__`, que é o que `Parser.ParseTitle(directoryInfo.Name)` lê em `DownloadedEpisodesImportService.cs:184`, vira a outra coisa que precisa continuar parseável.

### 7.2 A varredura da pasta de importação descarta subárvores inteiras {#72-the-import-folder-scan-drops-whole-subtrees}

`DiskScanService.FilterPaths` (`src/NzbDrone.Core/MediaFiles/DiskScanService.cs:232-246`), aplicado à
pasta de download em `DownloadedEpisodesImportService.cs:185` (Radarr
`DownloadedMovieImportService.cs:202`) com `filterExtras: true`:

```csharp
private static readonly Regex ExcludedExtrasSubFolderRegex = new Regex(@"(?:\\|\/|^)(?:extras|extrafanart|behind the scenes|deleted scenes|featurettes|interviews|other|scenes|samples|shorts|trailers)(?:\\|\/)", …IgnoreCase);   // :72
private static readonly Regex ExcludedSubFoldersRegex      = new Regex(@"(?:\\|\/|^)(?:@eadir|\.@__thumb|plex versions|\.[^\\/]+)(?:\\|\/)", …IgnoreCase);   // :73
private static readonly Regex ExcludedExtraFilesRegex      = new Regex(@"(-(trailer|other|behindthescenes|deleted|featurette|interview|scene|short)\.[^.]+$)", …IgnoreCase);   // :74
private static readonly Regex ExcludedFilesRegex           = new Regex(@"^\.(_|unmanic|DS_Store$)|^Thumbs\.db$", …IgnoreCase);   // :75
```

**A regex de extras do Radarr difere em uma alternativa**: `sample[s]?` em vez de `samples`
(Radarr `DiskScanService.cs:72`), então o Radarr também descarta uma pasta `sample/` onde o Sonarr só descarta
`samples/`. Todo o resto das quatro regexes é idêntico entre os repositórios.

Repare que a alternativa `\.[^\\/]+` da `ExcludedSubFoldersRegex`: **qualquer componente de diretório que começa com ponto é descartado**, em qualquer profundidade. E a comparação é feita contra `basePath.GetRelativePath(path)`, então ela vale só para o que fica abaixo da pasta de importação. Um ponto em um ancestral do mount não causa problema.

Só os arquivos cuja extensão está em `MediaFileExtensions.Extensions` chegam ao filtro, para começo de conversa (`DiskScanService.GetVideoFiles`, `:202-215`).

### 7.3 A detecção de amostra lê o arquivo {#73-sample-detection-reads-the-file}

`GetNonSampleVideoFileCount` (`ImportDecisionMaker.cs:216-234`) chama `_detectSample.IsSample(...)` para **cada** arquivo de vídeo da pasta. `DetectSample.IsSample` (`src/NzbDrone.Core/MediaFiles/EpisodeImport/DetectSample.cs:27-45`) só pula a checagem para specials, `.flv` e `.strm` (`:78-101`). Nos outros casos, ele chama `_videoFileInfoReader.GetRunTime(path)`, ou seja, **ffprobe, no arquivo, pelo mount**, e compara com um mínimo calculado a partir da duração esperada (`:103-121`). Uma duração de exatamente 0 é tratada como **sample** (`:107-111`). Se não conseguir pegar a duração, ele loga "Failed to get runtime from the file, make sure ffprobe is available" e retorna Indeterminate (`:38-42`).

`ShouldDeleteFolder` (`DownloadedEpisodesImportService.cs:117-133`) faz a mesma checagem de novo, no que sobrou depois da movimentação.

Então, importar um release com N arquivos custa pelo menos N aberturas de ffprobe no backend do debrid, antes de qualquer coisa ser movida. Isso pesa de verdade num mount do zurg, e do lado do cliente não tem como evitar.

### 7.4 As recusas em `ProcessFolder` / `ProcessFile` {#74-the-refusals-in-processfolder--processfile}

| Condição | Resultado | Linha (Sonarr) |
|---|---|---|
| o caminho de importação é uma pasta de série/filme | `ImportRejectionReason.SeriesFolder` — "Import path is mapped to a series folder" (Radarr: `MovieFolder`, "…a movie folder") | `:175-182` (Radarr `:183-190`) |
| o nome da pasta não corresponde a uma série/filme conhecido | `UnknownSeriesResult("Unknown Series")` | `:160-168` |
| o nome do arquivo começa com `._` | `InvalidFilePath` | `:251-259` |
| extensão em `FileExtensions.DangerousExtensions` | `DangerousFile` | `:263-271` |
| extensão em `FileExtensions.ExecutableExtensions` | `ExecutableFile` | `:273-281` |
| extensão não está em `MediaFileExtensions.Extensions` | `UnsupportedExtension` | `:283-293` |

**`SeriesPathExists` / `MoviePathExists` é o que dá problema num layout `__magic__`.** Se a pasta raiz do \*arr for `/mnt/zurg/__magic__/tv` e uma pasta de série for `/mnt/zurg/__magic__/tv/The Show`, então um caminho de importação que por acaso *seja* uma pasta de série é recusado logo de cara. É por isso que a pasta de download (`content_path`) precisa ficar ao lado das pastas raiz, e não dentro de uma delas — que é a configuração que [sabnzbd.md](../guides/sonarr-radarr.md) já recomenda: `save_path` = `/mnt/zurg/__magic__/__all__`, pastas raiz `/mnt/zurg/__magic__/tv` e `/mnt/zurg/__magic__/movies`, e os releases em `/mnt/zurg/__magic__/__all__/<release>`.

`_UNPACK_` e `_FAILED_` são removidos do nome da pasta antes da análise (`GetCleanedUpFolderName`, `:311-317`).

`IsFileLocked` é **ignorado por completo quando há um item do cliente de download** (`:187-199`, `:295-304`) — a verificação de bloqueio só roda em varreduras manuais ou de pasta raiz. Um shim nunca precisa se preocupar com isso.

## 8. As verificações de saúde {#8-the-health-checks}

Os três são compartilhados com o cliente SAB e analisados em [sabnzbd-client-contract.md §6](sabnzbd-client-contract.md). O que é específico do qBittorrent:

- **`RemotePathMappingCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs:59-173`) percorre `client.GetStatus().OutputRootFolders`. No qBittorrent, essa é a única pasta calculada em `QBittorrent.cs:377-407`: o `save_path` global, substituído ou complementado pelo `savePath` da categoria configurada (§1.5). Ela precisa ser um caminho válido para o SO em que o \*arr roda (`:68-113`) e precisa **existir no host do \*arr** (`:115-158`). Não precisa ser gravável. `IsLocalhost` é `Settings.Host == "127.0.0.1" || Settings.Host == "localhost"` (`:406`) e só muda qual das três mensagens de erro é exibida.
- **`DownloadClientRemovesCompletedDownloadsCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:33-66`) avisa sempre que `GetStatus().RemovesCompletedDownloads` é true, ou seja, sempre que a flag derivada do §1.4 é true. Mantenha `max_ratio_enabled` e `max_seeding_time_enabled` como false (o que a receita do §3.5 já faz) e ele continua em silêncio.
- **`DownloadClientRootFolderCheck`** é o único ponto em que os dois repositórios realmente diferem. O Sonarr avisa só quando uma pasta raiz *é igual* a uma pasta de saída; o Radarr também avisa quando uma pasta raiz *contém* uma delas. Análise completa em [sabnzbd-client-contract.md §6.1](sabnzbd-client-contract.md). A regra prática é a mesma aqui: não coloque uma pasta raiz igual ou acima do save path, e também não coloque uma dentro dele. `/mnt/zurg/__magic__/tv` é uma pasta irmã de `/mnt/zurg/__magic__/__all__`.

## 9. Sonarr vs Radarr — o diff completo {#9-sonarr-vs-radarr--the-complete-diff}

| Arquivo | Diferença |
|---|---|
| `QBittorrent.cs` | `TvCategory`→`MovieCategory`, `TvImportedCategory`→`MovieImportedCategory`, `RecentTvPriority`→`RecentMoviePriority`, `OlderTvPriority`→`OlderMoviePriority`, `RemoteEpisode`→`RemoteMovie`; `remoteEpisode.IsRecentEpisode()` → `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` (`:80`, `:137`). **Os números de linha batem um a um.** |
| `QBittorrentSettings.cs` | as mesmas renomeações; categoria padrão `"tv-sonarr"` → `"radarr"` (`:36`); token do texto de ajuda `…EpisodeHelpText` → `…MovieHelpText`. Os números de linha batem. |
| `QBittorrentProxyV2.cs` | a renomeação de categoria; `new[] { HttpStatusCode.Forbidden }` → `[HttpStatusCode.Forbidden]` (expressão de coleção, Sonarr `:401` / Radarr `:400`); o Sonarr tem uma linha em branco a mais na linha 13 → **Sonarr N = Radarr N−1 para N ≥ 14**. |
| `QBittorrentProxyV1.cs` | a renomeação de categoria; mesmo deslocamento de linha em branco. |
| `QBittorrentProxySelector.cs` | um espaço duplo sobrando no construtor do Sonarr (`:46`); linha em branco na linha 3 → Sonarr N = Radarr N−1 para N ≥ 4. |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **idênticos byte a byte.** |
| `TorrentClientBase.cs` | `RemoteEpisode`→`RemoteMovie` em todo o arquivo; o Radarr também trata HTTP **410 Gone** como 404 ao buscar um `.torrent` (`:175`), o Sonarr só trata 404. Ambos têm 274 linhas. |
| `QBittorrentFixture.cs` | os mesmos testes, em ordem diferente: `missingFiles_item_should_have_required_properties` fica no Sonarr `:296-315` e no Radarr `:402-420`, e **a cópia do Radarr não tem o atributo `[Test]`** (`:401` está em branco), então ela nunca roda ali. Sonarr `:318-421` = Radarr `:297-400`; a partir do Sonarr `:423`, Radarr = Sonarr − 1. Sonarr com 1000 linhas, Radarr com 998. |
| `DiskScanService.cs` | `ExcludedExtrasSubFolderRegex` — o Radarr tem `sample[s]?`, o Sonarr tem `samples` (`:72` nos dois). As outras três regexes são idênticas. |
| serviços de importação | `Series`/`Episode` vs `Movie`; o bloqueio de preferência de título do `AggregateEpisodes` do Sonarr não tem equivalente no Radarr (§7.1). Ambos recusam um caminho de importação que seja uma pasta da biblioteca antes de qualquer outra coisa (Sonarr `:175-182`, Radarr `:183-190`) e analisam o nome da pasta depois (Sonarr `:184`, Radarr `:195`); o Radarr também busca o histórico de captura pelo `DownloadId` ali (`:193-194`). |
| `ImportApprovedEpisodes.cs` / `ImportApprovedMovie.cs` | o switch de `copyOnly` é idêntico, Sonarr `:139-152` / Radarr `:116-129`. |
| `DiskTransferService.cs`, `DownloadClientBase.cs`, `DownloadEventHub.cs`, `Json.cs`, `HttpClient.cs`, `HttpRequestBuilder.cs` | compartilhados, idênticos byte a byte. |

Todo o resto deste documento é idêntico byte a byte, exceto por Series/Movie, e se aplica aos dois na mesma linha.

---

## 10. Payloads de exemplo mínimos, mas completos {#10-minimal-but-complete-example-payloads}

### 10.1 `GET /api/v2/app/webapiVersion`

```
2.11.2
```

`Content-Type: text/plain`. Não é JSON, sem aspas, não precisa de quebra de linha no final.

### 10.2 `POST /api/v2/auth/login`

Corpo da requisição: `username=sonarr&password=hunter2`, `application/x-www-form-urlencoded`.

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8
Set-Cookie: SID=8f3c1c0e9a1f4d2f9c0b7a5e3d1f6b2a; path=/

Ok.
```

Credenciais erradas: continua **200**, corpo `Fails.` — nunca um 401.

### 10.3 `GET /api/v2/app/preferences`

Só as dez chaves de §1.4 são lidas; pode mandar mais se quiser, elas são ignoradas.

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

Requisitos obrigatórios:

- `save_path` precisa existir como diretório **no host do Sonarr/Radarr** (`RemotePathMappingCheck`, §8).
- `max_ratio_enabled: false` + `max_seeding_time_enabled: false` mantém
  `RemovesCompletedDownloads` como false, o que deixa silenciosos tanto o teste de conexão (§6.1 caso 5) quanto a verificação de saúde.
- `dht: true`, senão magnets sem tracker são recusados do lado do cliente (§6.5).
- `max_ratio_act` é um **inteiro** (§0.6).

### 10.4 `GET /api/v2/torrents/categories`

```json
{
  "tv": { "name": "tv", "savePath": "" },
  "movies": { "name": "movies", "savePath": "" }
}
```

Um **objeto** JSON, com `savePath` em **camelCase**, que nunca começa com `//` (§1.5). Um `savePath` vazio
deixa a pasta raiz de saída no `save_path` global.

### 10.5 `GET /api/v2/torrents/info?category=tv` — um baixando, um pronto para importar {#105-get-apiv2torrentsinfocategorytv--one-downloading-one-importable}

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

**Requisitos obrigatórios:**

- Um **array** JSON (`List<QBittorrentTorrent>`); se vier um objeto, `GetTorrents` gera exceção e `TestGetTorrents` falha (§6.4).
- `hash` em **minúsculas** (§1.8) e exatamente o infohash que o \*arr calculou a partir do magnet ou do `.torrent` (§1.7).
- `size` em **bytes**; `progress` é uma fração de 0 a 1. `RemainingSize = size × (1 − progress)`.
- `eta: 8640000` é lido como "unknown" e resulta em um `RemainingTime` nulo (`:622-625`); um item Completed sempre recebe `TimeSpan.Zero` (`:273`).
- `state` conforme a tabela do §2, com exatamente a mesma capitalização.
- `content_path` **absoluto, existente e ≠ `save_path`** em itens Completed (§4.1). Pode ficar vazio enquanto o item não estiver Completed.
- `ratio_limit: 0` + `ratio: 0` é a receita de movimentação (§3.5).
- `category` deve ser igual à categoria configurada no cliente; o cliente não filtra de novo, então respeite o parâmetro da query.
- `seeding_time` pode ser omitido por completo: o cliente recorre a `torrents/properties`, e só quando um limite de tempo de seeding estiver de fato em vigor.

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

Só `save_path` e `seeding_time` são lidos (§1.8). **404 para um hash desconhecido** — é assim que
`IsTorrentLoaded` diz "ainda não chegou" (`:110-126`).

### 10.7 `GET /api/v2/torrents/files?hash=<hash>`

```json
[
  { "index": 0, "name": "Some.Show.S01E03.1080p.WEB.h264-GRP/ep3.mkv", "size": 1073741824, "progress": 1, "priority": 1, "is_seed": true, "piece_range": [0, 2047], "availability": 1 }
]
```

Só o `name` é lido, relativo ao `save_path`, com separadores `/` (§1.13). A ordem importa no caminho pré-2.6.1: o componente mais alto de `files[0]` vira a pasta de saída.

### 10.8 `POST /api/v2/torrents/add`

Requisição, em formulário urlencoded (um magnet longo chega como multipart — §0.3):

```
urls=magnet%3A%3Fxt%3Durn%3Abtih%3A3B1A...&category=tv&stopped=False
```

Resposta:

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8

Ok.
```

Qualquer coisa diferente do texto literal `Fails.` é sucesso (§1.7). Um corpo vazio com 200 também funciona.

### 10.9 `POST /api/v2/torrents/delete`

Requisição: `hashes=3b1a1469c180f447b77021074dbbccaef62611e7&deleteFiles=true`

Resposta: `HTTP/1.1 200 OK`, corpo vazio. **200 também para um hash desconhecido** (§5.2).

### 10.10 `POST /api/v2/torrents/createCategory`, `setCategory`, `setShareLimits`, `topPrio`, `setForceStart`

Todas aceitam formulários urlencoded e respondem `200` com corpo vazio. `topPrio` pode responder **409** para indicar que a fila está desativada — o cliente ignora exatamente esse status (§1.10). `setShareLimits` pode responder **404** para indicar que não é suportado — também ignorado (§1.9).

---

## 11. Diferenças em relação ao qBittorrent real — onde o modelo do zurg é mais restrito ou mais amplo {#11-differences-from-real-qbittorrent--where-zurgs-model-is-narrower-or-wider}

### 11.1 Não há seeding, então a trava de limite de seed precisa ser simulada {#111-there-is-no-seeding-so-the-seed-limit-gate-has-to-be-faked}

O qBittorrent real calcula o `ratio` a partir dos bytes realmente enviados e deixa o usuário definir um limite global ou por torrent. A trava `CanMoveFiles` do cliente existe para evitar arrancar arquivos de um torrent que ainda está cumprindo uma obrigação de ratio (`QBittorrent.cs:240-241`). Um backend debrid não envia nada, nunca. Por isso o shim declara `ratio: 0, ratio_limit: 0`, um limite por torrent já atingido, o que é verdadeiro no único sentido em que o campo pode ser verdadeiro aqui, e mantém as preferências globais totalmente fora disso (§3.5).

### 11.2 `content_path` é sempre uma pasta, nunca um arquivo {#112-content_path-is-always-a-folder-never-a-file}

Na prática, o `contentPath()` do qBittorrent real retorna o **caminho do arquivo** para um torrent de arquivo único (`torrentimpl.cpp:582-583`). Com `__magic__`, cada release é uma pasta que guarda os seus arquivos ([magic.md](../guides/magic.md#with-nothing-stored-it-is-__all__s-releases-as-real-folders)), inclusive um release de arquivo único.

Consequências, todas a favor do cliente:

- O `ProcessPath` sempre segue pelo ramo de **pasta** (`DownloadedEpisodesImportService.cs:80-90`), nunca pelo ramo de arquivo (`:92-102`). O ramo de pasta é o que aplica `FilterPaths`, `ShouldDeleteFolder` e a leitura do nome da pasta, então o filtro de extras e o fallback do título pela pasta ficam sempre ativos.
- As recusas por arquivo do `ProcessFile` (extensão perigosa, executável ou não suportada, prefixo `._`; §7.4) continuam acessíveis, mas pelo filtro de extensão do `GetVideoFiles` em vez do ramo de nível superior.
- A varredura do `GetImportItem` anterior à 2.6.1 (§4.2) também funcionaria, já que `files[0].name` sempre traz a pasta do release, mas não há motivo para relatar uma versão tão antiga.

Um ponto que precisa estar certo: como é sempre uma pasta, `content_path` é sempre `save_path + "/" + <release folder>` e, por isso, nunca é igual a `save_path`. O aviso `DownloadClientQbittorrentTorrentStatePathError` (§4.1) é estruturalmente inalcançável, e esse é o resultado correto, não um acidente em que se deva confiar.

### 11.3 `name` não é o título pedido, e pode mudar {#113-name-is-not-the-grabbed-title-and-it-can-change}

O qBittorrent real informa o nome a partir dos metadados do torrent, e esse nome não muda. O nome do zurg vem da biblioteca:

- O Real-Debrid renomeia releases cujo nome de arquivo cai no bloqueio 451 dele (`WEB-DL`, as tags `Rip` e alguns pares fonte-codec com ponto, medidos em 2026-10-14). Veja a seção RD 451 do `CLAUDE.md` do monorepo.
- O zurg acrescenta um sufixo quando duas releases colidem no mesmo nome, e um reparo reconstrói uma release sob um novo id de torrent.
- O nome é lido da biblioteca a cada consulta, então ele pode mudar **entre consultas** para um id que o \*arr já está acompanhando.

Nada disso quebra o acompanhamento, porque ele é feito pelo `DownloadId` (o infohash) e não pelo nome. O que quebra é o caminho de parsing de título da §7.1. Disso saem duas regras:

1. **Use como chave o infohash que o \*arr calculou**, nunca algo interno do zurg. Ele é o único elo entre o grab, o histórico de grabs e a consulta.
2. **Mantenha o nome da pasta `__magic__` parseável**, porque é o fallback que o ramo de pasta lê (`DownloadedEpisodesImportService.cs:184`).

### 11.4 Não há progresso nem fase de metadados {#114-there-is-no-progress-and-no-metadata-phase}

Não há nada para baixar, então não existe nenhum `progress`, `eta`, `dlspeed` ou `metaDL` que faça sentido
— a mesma limitação que o endpoint SAB documenta ([sabnzbd.md](../guides/sonarr-radarr.md), *O que funciona, e
o que não*: "Sem progresso. Um job está na fila ou está concluído"). O mapeamento natural é: **Queued**
(`queuedDL`) enquanto a biblioteca ainda não lista o release, **Completed** (`pausedUP`) assim que ela lista
*e os tamanhos dos arquivos já estabilizaram*, com `size` tirado do que o backend declarar, para que a entrada da fila não fique em branco.

Não use `metaDL` para o estado de espera a menos que `dht: true` também seja reportado — ele só vira Queued
nesse caso (`:288-297`). `queuedDL` é incondicional e não traz mensagem.

Não use `stalledDL`, `error` ou `missingFiles` para uma espera transitória: os três são **Warnings**
(§2) e aparecem na fila como problemas.

### 11.5 Excluir oculta; não destrói {#115-deleting-hides-it-does-not-destroy}

`torrents/delete?deleteFiles=true` no qBittorrent real remove o torrent e dá um `rm -rf` nos dados dele.
Aqui ele precisa remover só o registro: o release continua sendo servido a partir do torrent no provedor, e a pasta que o \*arr queria sumir já se marcou como removida sozinha, pelo mount (§5.2, [magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)). É exatamente o raciocínio que `deleteFromHistory` do `internal/sabnzbd` registra em `internal/sabnzbd/api.go:596-609`.

### 11.6 Tudo o que o cliente pode pedir e que não tem nada a aplicar {#116-everything-the-client-can-ask-for-that-has-nothing-to-apply-to}

`sequentialDownload`, `firstLastPiecePrio`, `contentLayout`, `stopped`/`paused`, `setForceStart`,
`topPrio`, `setShareLimits`, `dlLimit`/`upLimit`: aceitam, respondem 200 e não aplicam nada. Só dois
têm consequências observáveis se forem recusados: `topPrio` (um 409 é ignorado, qualquer outro gera aviso) e
`setShareLimits` (um 404 é ignorado). Nenhum dos dois bloqueia um grab.

`contentLayout` merece uma observação: a configuração existe no \*arr justamente para forçar o qBittorrent a
manter uma pasta de nível superior, para que `content_path != save_path`. Com `__magic__`, o layout é sempre
uma pasta independentemente disso (§11.2), então o parâmetro não tem efeito e o operador pode deixá-lo em Default.

## 12. Checklist de implementação (14 pontos) {#12-implementation-checklist-14-points}

1. **Somente API v2.** Responda `/api/v2/app/webapiVersion` com `2.11.2`; retorne **404** em `/version/api` para que a verificação de v1 falhe de forma limpa.
2. **Autenticação:** aceite um cabeçalho `Authorization: Bearer <key>`, um `Authorization: Basic` enviado antecipadamente, um cookie `SID` ou nenhum dos dois. Responda `POST /api/v2/auth/login` com **200 + `Ok.` + `Set-Cookie: SID=…`**; responda `Fails.` (também com 200) para credenciais inválidas, nunca um 401. Não exija `Referer` nem `Origin`.
3. **Erros são códigos HTTP, não JSON.** 403 significa "faça login de novo" e é repetido uma vez; um segundo 403 aparece como erro de conexão, não como erro de autenticação. 404 tem significado em `torrents/properties` (hash desconhecido) e em `torrents/setShareLimits` (não suportado); 409 tem significado em `torrents/topPrio` (fila desativada). Todo o resto deve ser 200.
4. **Leia as duas codificações de formulário em `torrents/add`**: urlencoded e multipart, quando algum valor passar de 1024 bytes ou um `.torrent` for enviado. Aceite `True`/`False` assim como `true`/`false` em todos os booleanos.
5. **`torrents/info` retorna um array; `torrents/categories` retorna um objeto** com `savePath` em camelCase. Respeite o parâmetro de query `category`: o cliente não filtra de novo.
6. **Hashes: em minúsculas em todas as respostas, comparados sem diferenciar maiúsculas e minúsculas em todas as requisições**, e sempre o infohash que o \*arr calculou a partir do magnet ou do `.torrent`. `torrents/properties` é a única rota que pode receber o hash com a mesma capitalização usada em `torrents/info`.
7. **A receita de Move:** `state: "pausedUP"`, `ratio: 0`, `ratio_limit: 0`, `seeding_time_limit: -2`, `inactive_seeding_time_limit: -2`. Com menos que isso, a importação vira uma **cópia**, ou seja, um download completo da release. Documente que a configuração "Remove Completed" do \*arr precisa continuar ativada, porque o shim não consegue compensar isso.
8. **`content_path` precisa ser absoluto, precisa existir no host do \*arr e não pode ser igual a `save_path`.** Defina-o somente quando a release estiver de fato importável: listada e com os tamanhos dos arquivos estabilizados. Até lá, informe `queuedDL` e deixe o cliente continuar consultando; não há limite de tentativas.
9. **`save_path`** (de `app/preferences`, além do `savePath` de qualquer categoria) precisa existir como diretório no host do \*arr, senão `RemotePathMappingCheck` gera um erro. Não precisa ser gravável. Nunca emita um `savePath` que comece com `//`.
10. **Mantenha o teste de conexão verde:** `dht: true`, `queueing_enabled: true`, `max_ratio_enabled: false`, `max_seeding_time_enabled: false`, `max_ratio_act: 0` (inteiro), e então ou crie previamente as categorias configuradas, ou respeite `createCategory` e reflita isso na resposta seguinte de `torrents/categories`.
11. **`torrents/delete` remove só o registro e nada mais.** Ignore `deleteFiles` para o torrent do provedor, exatamente como `deleteFromHistory` do `internal/sabnzbd` ignora `del_files` (`internal/sabnzbd/api.go:596-609`). Responda 200 para um hash desconhecido. Aceite `setCategory` e registre a nova categoria.
12. **Espere que o \*arr execute `rm -rf` na própria pasta da release** após uma importação Move (`DownloadedEpisodesImportService.cs:209-223`). Isso vira um `__magic__` tombstone, e depois ele chama `torrents/delete`. Ambas as coisas são normais; nenhuma delas destrói nada.
13. **Use apenas nomes de estado da §2, com a capitalização exata.** Um nome desconhecido não gera exceção aqui (diferente do SAB), mas gera um log e assume Downloading por padrão. Nunca use `stalledDL`, `error` ou `missingFiles` para uma espera temporária: as três são Warnings.
14. **Não coloque uma pasta raiz no nível do diretório de saída nem acima dele.** Com `save_path` = `/mnt/zurg/__magic__/__all__`, use `/mnt/zurg/__magic__/tv` e `/mnt/zurg/__magic__/movies` como pastas raiz, e mantenha as releases em `/mnt/zurg/__magic__/__all__/<release>`. Caso contrário, `SeriesPathExists`/`MoviePathExists` recusa a importação de imediato (§7.4) e o `DownloadClientRootFolderCheck` do Radarr reclama a cada inicialização.
