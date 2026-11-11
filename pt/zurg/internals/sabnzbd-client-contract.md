# Contrato da API do SABnzbd como usado pelo Sonarr e Radarr (develop) {#sabnzbd-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Fonte de verdade: arquivos obtidos de `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...`
em **2026-08-22**. Todos os números de linha abaixo foram lidos desses arquivos.

Mantido aqui como registro do motivo de `internal/sabnzbd` responder nos formatos que responde. Nada nesse pacote deve ser alterado sem o parágrafo aqui que explica o que o cliente faz com o campo. Uma tag de struct errada não gera erro, ela deixa o cliente lendo um zero. Um valor de enum errado lança exceção dentro do desserializador e derruba a consulta inteira. Para saber como apontar o Sonarr ou o Radarr para o zurg, veja [sabnzbd.md](../guides/sonarr-radarr.md).

A menos que uma seção diga o contrário, **os arquivos SAB dos dois repositórios são idênticos byte a byte, exceto pelo BOM UTF-8 e pela renomeação `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie`, e os números de linha coincidem um a um.** Portanto, toda citação `Sabnzbd*` se aplica aos dois repositórios na mesma linha. Os caminhos são `src/NzbDrone.Core/Download/Clients/Sabnzbd/...` nos dois. Os diffs verificados estão registrados na §6.

Nada aqui é especulação sobre o próprio SAB: cada afirmação diz o que o *cliente* faz. Quando eu afirmo semântica do Newtonsoft.Json ou do runtime do .NET (e não código do Sonarr), eu digo isso explicitamente.

---

## 0. Regras de nível de transporte (estas pegam primeiro) {#0-transport-level-rules-these-bite-first}

### 0.1 Formato da URL {#01-url-shape}

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
  = `{http|https}://{Host}:{Port}{UrlBase}`; `UrlBase` ganha um `/` no início se não tiver.
  O endpoint é isso + `/api` (`SabnzbdProxy.cs:38-44`).
- Os parâmetros de sufixo sempre ficam por último, então **`apikey` (ou `ma_username`+`ma_password`) e `output=json`
  são os últimos parâmetros da query** (`HttpRequestBuilder.cs:82` — `QueryParams.Concat(SuffixQueryParams)`).
- `Accept: application/json` em todas as chamadas. `output=json` em todas as chamadas. Não existe nenhum caminho com `output=xml` em lugar nenhum.
- API key e usuário/senha são **mutuamente exclusivos**: quando há uma api key, ela anula `ma_username`/`ma_password`.

### 0.2 Sempre responde HTTP 200 — mesmo em erros {#02-always-answer-http-200--even-for-errors}

`HttpClient.Execute` lança exceção para qualquer status >= 400 (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`;
`HttpResponse.cs:54` — `HasHttpError => (int)StatusCode >= 400`; 429 vira `TooManyRequestsException`).
`SabnzbdProxy.ProcessRequest` (`SabnzbdProxy.cs:199-215`) converte isso em
`DownloadClientException("Unable to connect to SABnzbd, {0}")`.

A mensagem de `HttpException` é `"HTTP request failed: [401:Unauthorized] [GET] at [url]"`
(`src/NzbDrone.Common/Http/HttpException.cs:18`) — **o corpo não entra na mensagem**. Então um 401 com
`{"error":"API Key Incorrect"}` **não** será reconhecido por `TestAuthentication`
(`Sabnzbd.cs:424,429` comparam com `ex.Message`), e o teste de conexão mostra a mensagem genérica
"Test was aborted due to an error" no lugar. **Emule o SAB: HTTP 200 + `{"status": false, "error": "..."}`.**

### 0.3 Configurações do deserializador (determinam todas as dúvidas sobre nomes de campos e tipos) {#03-deserializer-settings-drives-every-field-name-and-type-question}

All SAB payloads go through `NzbDrone.Common.Serializer.Json`
(`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`) — **Newtonsoft**, não System.Text.Json:

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Consequências (semântica do Newtonsoft, não código do Sonarr):

| Configuração | Efeito em um emulador |
|---|---|
| `CamelCasePropertyNamesContractResolver` | A propriedade C# `Storage` liga com `storage`, `PP` liga com `pp`, `Misc` liga com `misc`. O Newtonsoft também faz uma correspondência de propriedade sem diferenciar maiúsculas de minúsculas, então as chaves reais do SAB em snake_case/minúsculas ligam de qualquer forma. |
| `StringEnumConverter` (global) | Vale para `SabnzbdDownloadStatus`, que **não** tem conversor por propriedade. Nomes de enum desconhecidos geram `JsonSerializationException`. Inteiros também são aceitos (`AllowIntegerValues` vem true por padrão). |
| `NullValueHandling.Ignore` | Também na **leitura**: um `null` em JSON deixa o membro C# com o valor do construtor. Assim, `"categories": null` mantém a lista vazia do construtor, mas `"misc": null` deixa `Misc` como null (sem valor padrão no construtor) → NRE, veja §3.4. |
| `MissingMemberHandling` (padrão `Ignore`) | Campos extras no seu payload são inofensivos. Envie o corpo completo e real do SAB. |
| `Culture` (padrão `InvariantCulture`) | Strings numéricas como `"1024.00"` precisam usar `.` como separador decimal e sem separadores de milhar. |

`Json.Deserialize<T>` relança apenas `JsonReaderException` com uma mensagem mais clara (`Json.cs:39-50`);
`Json.TryDeserialize<T>` engole **apenas** `JsonReaderException` e `JsonSerializationException`
(`Json.cs:99-117`). Qualquer outra coisa (por exemplo, um `ArgumentException` do conversor de timeleft, ou um NRE
do conversor de priority) escapa.

---

## 1. Todos os modos, todos os parâmetros, todos os campos consumidos {#1-every-mode-every-parameter-every-field-consumed}

### 1.1 `mode=version` — `SabnzbdProxy.GetVersion` (`SabnzbdProxy.cs:85-95`)

Request: `GET /api?mode=version&apikey=KEY&output=json`

Response model `SabnzbdVersionResponse` (`Responses/SabnzbdVersionResponse.cs:5`):

| Chave JSON | Tipo C# | Observações |
|---|---|---|
| `version` | `string` | O único campo lido. |

Lido via `Json.TryDeserialize`; uma falha de parse resulta em `Version == null` (`SabnzbdProxy.cs:89-92`).

Parsing (`Sabnzbd.cs:334-366`), regex em `Sabnzbd.cs:38`:

```csharp
// patch can be a number (releases) or 'x' (git)
private static readonly Regex VersionRegex = new Regex(@"(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+|x)", RegexOptions.Compiled);
```

- Sem âncora, então `4.5.0RC1` e `2.0.0beta1` são parseados (fixture `SabnzbdFixture.cs:523,553`).
- `patch` pode ser o literal `x` (builds do git), que é substituído por `0` (`Sabnzbd.cs:351`).
- Uma versão com **dois componentes** (`"4.5"`) não bate com a regex → `null` → falha de validação.
- A string exata `"develop"` (sem diferenciar maiúsculas e minúsculas) é tratada como caso especial e vira `3.0.0` (`Sabnzbd.cs:355-362`), gerando um *aviso*, não uma falha (`Sabnzbd.cs:380-387`).

A versão é buscada de novo (mais uma ida e volta com `mode=version`) pelo `HasVersion` em `Sabnzbd.cs:294-332`. Ela **não é armazenada em cache**.

### 1.2 `mode=get_config` — `SabnzbdProxy.GetConfig` (`SabnzbdProxy.cs:97-104`)

Requisição: `GET /api?mode=get_config&apikey=KEY&output=json`

Usa `Json.Deserialize` (**não** Try). Um corpo malformado lança uma exceção para fora de `GetConfig`.
O nível superior deve ser `{"config": {...}}` (`Responses/SabnzbdConfigResponse.cs:5`). Veja §3 para os campos.

### 1.3 `mode=fullstatus` — `SabnzbdProxy.GetFullStatus` (`SabnzbdProxy.cs:106-114`)

Requisição: `GET /api?mode=fullstatus&skip_dashboard=1&apikey=KEY&output=json`

Nível superior `{"status": {...}}` (`Responses/SabnzbdFullStatusResponse.cs:5`). Só um campo é lido:

| Chave JSON | C# | Origem |
|---|---|---|
| `completedir` | `string CompleteDir` | `SabnzbdFullStatus.cs:9-10` — obs: **`completedir`, sem underscore** |

Chamado **somente quando** `config.misc.complete_dir` *não* é absoluto **e** a versão do SAB é >= 2.0
(`Sabnzbd.cs:220-226`). Com um `complete_dir` absoluto, este endpoint nunca é chamado, mas implemente mesmo assim.

Detalhe que vale saber: como o corpo real é `{"status": {...}}` e `SabnzbdJsonError.Status` é uma
`string`, o `TryDeserialize<SabnzbdJsonError>` do `CheckForError` falha com um `JsonSerializationException`
e cai no ramo de texto simples, que define `Status = "true"` (`SabnzbdProxy.cs:224-240`). Isso é inofensivo,
mas significa que o fullstatus nunca consegue reportar um erro pelo caminho JSON.

### 1.4 `mode=queue` (leitura) — `SabnzbdProxy.GetQueue` (`SabnzbdProxy.cs:116-130`) {#14-modequeue-read--sabnzbdproxygetqueue-sabnzbdproxycs116-130}

**Requisição:** `GET /api?mode=queue&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- `category` só é adicionado **se** a categoria configurada não estiver em branco (`SabnzbdProxy.cs:122-125`).
- Chamadores: `Sabnzbd.GetQueue()` usa `start=0, limit=0` (`Sabnzbd.cs:57`). O SAB lê `limit=0` como "todos";
  `Sabnzbd.GetCategories()` usa `start=0, limit=1` no caminho para versões anteriores à 2.0 (`Sabnzbd.cs:229`);
  `Sabnzbd.RemoveItem()` chama isso mais uma vez para decidir se o item está na fila ou no histórico (`Sabnzbd.cs:199`).
- Extração: `Json.Deserialize<SabnzbdQueue>(JObject.Parse(response).SelectToken("queue").ToString())`
  (`SabnzbdProxy.cs:129`). **Se a chave `queue` de nível superior não existir, ocorre um NRE.**

`SabnzbdQueue` (`SabnzbdQueue.cs`):

| Chave JSON | Membro C# | Tipo | Usado para |
|---|---|---|---|
| `my_home` | `DefaultRootFolder` | `string` | Só no SAB < 2.0, para resolver um `complete_dir` relativo (`Sabnzbd.cs:230`). Comentário em `SabnzbdQueue.cs:8`: "Removed in Sabnzbd 2.0.0, see mode=fullstatus instead." |
| `paused` | `Paused` | `bool` | Pausa global; combinada com a prioridade do slot (`Sabnzbd.cs:78`). |
| `slots` | `Items` | `List<SabnzbdQueueItem>` | |

`SabnzbdQueueItem` (`SabnzbdQueueItem.cs`):

| Chave JSON | Membro C# | Tipo C# | Tipo JSON real do SAB | Observações |
|---|---|---|---|---|
| `status` | `Status` | `SabnzbdDownloadStatus` | string | `StringEnumConverter` global. Valor desconhecido ⇒ `JsonSerializationException` ⇒ o `GetQueue` inteiro lança exceção. |
| `index` | `Index` | `int` | number | Lido, nunca usado. |
| `timeleft` | `Timeleft` | `TimeSpan` via `SabnzbdQueueTimeConverter` | string | Veja §1.4.1. |
| `mb` | `Size` | `decimal` | **string** (`"1024.00"`) | **Megabytes.** `TotalSize = (long)(Size * 1024 * 1024)` (`Sabnzbd.cs:72`). |
| `mbleft` | `Sizeleft` | `decimal` | **string** | **Megabytes.** `RemainingSize = (long)(Sizeleft * 1024 * 1024)` (`Sabnzbd.cs:73`). |
| `filename` | `Title` | `string` | string | Vira `DownloadClientItem.Title` (`Sabnzbd.cs:71`). |
| `priority` | `Priority` | `SabnzbdPriority` via `SabnzbdPriorityTypeConverter` | string (`"Normal"`) | Veja §2. |
| `cat` | `Category` | `string` | string | **`cat` na fila, `category` no histórico.** |
| `mbleft`/`percentage` | `Percentage` | `int` | **string** (`"50"`) | Lido, nunca usado. |
| `nzo_id` | `Id` | `string` | string | O id do download no qual Sonarr/Radarr baseiam tudo. |

#### 1.4.1 Formato do `timeleft` — `SabnzbdQueueTimeConverter` (`JsonConverters/SabnzbdQueueTimeConverter.cs:15-28`) {#141-timeleft-format--sabnzbdqueuetimeconverter-jsonconverterssabnzbdqueuetimeconvertercs15-28}

```csharp
var split = reader.Value.ToString().Split(':').Select(int.Parse).ToArray();
switch (split.Length)
{
    case 4: return new TimeSpan((split[0] * 24) + split[1], split[2], split[3]);   // d:h:m:s
    case 3: return new TimeSpan(split[0], split[1], split[2]);                     // h:m:s
    default: throw new ArgumentException("Expected either 0:0:0:0 or 0:0:0 format, but received: " + reader.Value);
}
```

- **Exatamente 3 ou 4 inteiros separados por dois-pontos.** `"0:08:32"`, `"40:12:14"`, `"1:16:12:14"` são todos válidos
  (fixture `SabnzbdQueueTimeConverterFixture.cs:14-20`); `"1"`, `"0:1"`, `"0:0:0:0:1"` lançam exceção (`:28-35`). Zeros à esquerda são aceitos (`int.Parse`).
- A `ArgumentException` lançada **não** é capturada por `Json.TryDeserialize` nem por `Json.Deserialize`.
- Uma **string vazia** `""` é dividida em `[""]` → `int.Parse` lança `FormatException`. Nunca emita `""`.
- Omitir `timeleft` por completo é seguro: o conversor não é invocado e `Timeleft` continua como `TimeSpan.Zero`.

### 1.5 `mode=queue&name=delete` — `SabnzbdProxy.RemoveFromQueue` (`SabnzbdProxy.cs:64-72`)

```
GET /api?mode=queue&name=delete&del_files={0|1}&value={nzo_id}&apikey=KEY&output=json
```

`del_files = deleteData ? 1 : 0` (`SabnzbdProxy.cs:68`). **Não há parâmetro `archive` no caminho da fila.**
O corpo da resposta só passa pelo `CheckForError`; nada é desserializado.

### 1.6 `mode=history` (leitura) — `SabnzbdProxy.GetHistory` (`SabnzbdProxy.cs:132-146`) {#16-modehistory-read--sabnzbdproxygethistory-sabnzbdproxycs132-146}

**Requisição:** `GET /api?mode=history&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- Chamador: `Sabnzbd.GetHistory()` com `start=0, limit=_configService.DownloadClientHistoryLimit`
  (`Sabnzbd.cs:110`). Padrão **60** nos dois repositórios
  (Sonarr `src/NzbDrone.Core/Configuration/ConfigService.cs:184`, Radarr `:236`).
- Extração: `SelectToken("history")` (`SabnzbdProxy.cs:145`). O nível superior precisa ser `{"history": {...}}`.

`SabnzbdHistory` (`SabnzbdHistory.cs`): `paused` (`bool`, não usado), `slots` → `Items`.

`SabnzbdHistoryItem` (`SabnzbdHistoryItem.cs`):

| Chave JSON | Membro C# | Tipo C# | Observações |
|---|---|---|---|
| `fail_message` | `FailMessage` | `string` | Vira `DownloadClientItem.Message` (`Sabnzbd.cs:132`) e dispara o caso especial de Warning (§1.6.1). |
| `bytes` | `Size` | `long` | **BYTES, não MB**. `TotalSize = sabHistoryItem.Size` sem alteração (`Sabnzbd.cs:128`). Esta é a maior assimetria em relação ao `mode=queue`. |
| `category` | `Category` | `string` | Observação: `category`, enquanto a fila usa `cat`. |
| `nzb_name` | `NzbName` | `string` | Lido, nunca usado. |
| `download_time` | `DownloadTime` | `int` (segundos) | Lido, nunca usado. |
| `storage` | `Storage` | `string` | O caminho de saída. Veja §1.6.2: é esse caminho que sofre `rm -rf`. |
| `status` | `Status` | `SabnzbdDownloadStatus` | `StringEnumConverter` global. |
| `nzo_id` | `Id` | `string` | |
| `name` | `Title` | `string` | |

**Não existe nenhum membro do tipo `DateTime` em lugar nenhum dos modelos do SAB, então nenhum formato de data é restringido.**
`completed` / `last_history_update` (epoch unix no SAB real) nunca são lidos. Os únicos valores de tempo que importam são `timeleft` (§1.4.1) e `download_time` (um inteiro não lido, em segundos).

#### 1.6.1 Status do histórico → `DownloadItemStatus` (`Sabnzbd.cs:116-158`) {#161-history-status--downloaditemstatus-sabnzbdcs116-158}

```
Deleted                                   -> skipped entirely (Sabnzbd.cs:116-119)
Failed  + fail_message == "Unpacking failed, write error or disk is full?"
        (InvariantCultureIgnoreCase)      -> DownloadItemStatus.Warning     (:140-144)
Failed  (any other message)               -> DownloadItemStatus.Failed      (:147)
Completed                                 -> DownloadItemStatus.Completed   (:152)
anything else (Verifying/Moving/...)      -> DownloadItemStatus.Downloading (:157)
```

Todo item do histórico recebe `RemainingSize = 0`, `RemainingTime = TimeSpan.Zero`, `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:129-135`).

`DownloadItemStatus` em si (`src/NzbDrone.Core/Download/DownloadItemStatus.cs:3-11`): `Queued=0, Paused=1, Downloading=2, Completed=3, Failed=4, Warning=5`.

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

O loop vai **até a raiz** e guarda o ancestral *mais alto* cujo último segmento é igual a
`name`. A ideia é esta: se `storage` aponta para um arquivo dentro da pasta do job, ele sobe até a pasta do job (fixture `SabnzbdFixture.cs:376-391`). Se `storage` já for a pasta do job, nenhum ancestral combina e `OutputPath == storage`, que é o que você quer.

**Recomendação para o emulador: defina `storage` com o próprio caminho da pasta do job.**

Se `storage` estiver vazio, `OutputPath` continua vazio, e `CompletedDownloadService.ValidatePath` mostra o aviso "Download doesn't contain intermediate path, Skipping." (Sonarr `CompletedDownloadService.cs:299-303`).

### 1.7 `mode=history&name=delete` — `SabnzbdProxy.RemoveFromHistory` (`SabnzbdProxy.cs:74-83`)

```
GET /api?mode=history&name=delete&del_files={0|1}&value={nzo_id}&archive={0|1}&apikey=KEY&output=json
```

```csharp
request.AddQueryParam("del_files", deleteData ? 1 : 0);          // :78
request.AddQueryParam("value", id);                              // :79
request.AddQueryParam("archive", deletePermanently ? 0 : 1);     // :80   <-- inverted
```

e o chamador (`Sabnzbd.cs:208`):

```csharp
_proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
```

Então `deletePermanently == (status is Failed)`, e portanto:

| Status do item | `del_files` | `archive` |
|---|---|---|
| Completed | 1 | **1** (arquiva) |
| Failed | 1 | **0** (exclusão permanente) |

Sim, à primeira vista parece ao contrário, mas é exatamente isso que o código faz.

### 1.8 `mode=addfile` — `SabnzbdProxy.DownloadNzb` (`SabnzbdProxy.cs:46-62`)

```
POST /api?mode=addfile&cat={category}&priority={int}&apikey=KEY&output=json
Content-Type: multipart/form-data; boundary=...
  part: Content-Disposition: form-data; name="name"; filename="<CleanFileName(Release.Title)>.nzb"
        Content-Type: application/x-nzb
```

- O campo multipart se chama literalmente `name`, e a parte carrega um `filename` (`SabnzbdProxy.cs:53`,
  `HttpRequestBuilder.cs:379-395`, emitido em `:180-195`).
- O nome do arquivo vem de `FileNameBuilder.CleanFileName(release.Title) + ".nzb"`
  (Sonarr `src/NzbDrone.Core/Download/UsenetClientBase.cs:43`, Radarr `:43`).
- **`cat` ignora o argumento `category` do método** e lê as configurações diretamente
  (`SabnzbdProxy.cs:50`: `request.AddQueryParam("cat", settings.TvCategory);` — Radarr: `settings.MovieCategory`).
  Não tem problema, já que quem chama passa o mesmo valor.
- `priority` é o `int` bruto de `SabnzbdPriority` (veja §2), escolhido conforme o conteúdo é recente:
  Sonarr `Sabnzbd.cs:43` `remoteEpisode.IsRecentEpisode() ? Settings.RecentTvPriority : Settings.OlderTvPriority`;
  Radarr `Sabnzbd.cs:43` `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie ? RecentMoviePriority : OlderMoviePriority`.
- Resposta `SabnzbdAddResponse` (`Responses/SabnzbdAddResponse.cs`):

| Chave JSON | C# | Tipo |
|---|---|---|
| `status` | `Status` | `bool` — interpretado, mas **nunca lido** |
| `nzo_ids` | `Ids` | `List<string>`, inicializado vazio no construtor |

  Lido com `TryDeserialize`; se falhar, usa-se um `{Status=true, Ids=[]}` sintético (`SabnzbdProxy.cs:55-59`).
  Depois, `Sabnzbd.cs:47-52`:

```csharp
if (response == null || response.Ids.Empty())
{
    throw new DownloadClientRejectedReleaseException(remoteEpisode.Release, "SABnzbd rejected the NZB for an unknown reason");
}

return response.Ids.First();
```

  **`nzo_ids` precisa ser um array de strings não vazio.** `"nzo_ids": null` equivale a ausente
  (`NullValueHandling.Ignore` mantém a lista vazia do construtor) e falha do mesmo jeito.

(Uma tradução anterior foi rejeitada: os trechos de código estavam diferentes. Mantenha a estrutura exatamente como está.)

### 1.9 Status da fila → `DownloadItemStatus` (`Sabnzbd.cs:60-103`) {#19-queue-status--downloaditemstatus-sabnzbdcs60-103}

```
Deleted                                       -> skipped (Sabnzbd.cs:62-65)
(queue.paused && slot.priority != Force) || slot.status == Paused
                                              -> Paused, and RemainingTime forced to null (:78-84)
Queued | Grabbing | Propagating               -> Queued        (:85-90)
everything else                               -> Downloading   (:93)
```

Também `Sabnzbd.cs:96-100`: um título que começa com o texto literal `"ENCRYPTED /"` tem esses
11 caracteres removidos e o item é marcado com `IsEncrypted = true`.

Todo item da fila recebe `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:75-76`).

### 1.10 Filtro de categoria no lado do cliente (`Sabnzbd.cs:186-195`) {#110-client-side-category-filter-sabnzbdcs186-195}

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

Igualdade de string ordinal. Um item na categoria `*` só é aceito quando a categoria configurada está em branco.

### 1.11 Modos que existem no proxy mas nunca são chamados {#111-modes-that-exist-in-the-proxy-but-are-never-called}

- `mode=retry&value={id}` (`SabnzbdProxy.cs:148-160`, resposta `{status, nzo_id}` →
  `Responses/SabnzbdRetryResponse.cs`). `ISabnzbdProxy.RetryDownload` **não tem nenhum caller** em nenhum dos dois repositórios.
- `Responses/SabnzbdCategoryResponse.cs` (`{"categories": [...]}`, ou seja, `mode=get_cats`) está **totalmente sem referência** nos dois repositórios.
- `Sabnzbd.ValidatePath` (`Sabnzbd.cs:576-592`) é privado e nunca é chamado (código morto).

## 2. `SabnzbdDownloadStatus` e `SabnzbdPriority` — membros exatos, tratamento de desconhecido/nulo {#2-sabnzbddownloadstatus-and-sabnzbdpriority--exact-members-unknownnull-handling}

### 2.1 `SabnzbdPriority.cs` (arquivo completo) {#21-sabnzbdprioritycs-complete-file}

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

- `Enum.TryParse<T>(string, out T)` é a sobrecarga **que diferencia maiúsculas de minúsculas** (semântica do .NET).
  `"Normal"` funciona; `"normal"` **não** funciona. Em caso de falha, `output` fica com `default(SabnzbdPriority) == 0 == Normal`, então um caso errado cai silenciosamente para Normal.
  `"Force"` importa (§1.9); `"force"` não funciona.
- Strings numéricas também funcionam: `"2"` vira `Force` e `"-100"` vira `Default`. Um número JSON `2` também funciona (`reader.Value.ToString()` == `"2"`).
- **`"priority": null` gera um `NullReferenceException`** (`reader.Value.ToString()` com null).
  Isso *não* é capturado por `Json.TryDeserialize`. Omita a chave ou envie um valor real.
- Omitir `priority` é seguro: o conversor não é chamado e o membro continua `Normal` (0).
- O conversor está registrado apenas em `SabnzbdQueueItem.Priority` (`SabnzbdQueueItem.cs:21`);
  itens do histórico não têm prioridade.
- Esses mesmos inteiros são o que Sonarr/Radarr enviam de volta como `&priority=` em `mode=addfile`
  (`SabnzbdSettings.cs` define como padrão ambos `Recent*Priority` e `Older*Priority` como
  `(int)SabnzbdPriority.Default` = `-100`).

### 2.2 `SabnzbdDownloadStatus.cs` (arquivo completo), a ordem de declaração = valores implícitos 0..15 {#22-sabnzbddownloadstatuscs-complete-file-declaration-order--implicit-values-015}

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

- **Nenhum conversor por propriedade.** O `StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }` registrado globalmente (`Json.cs:32`) cuida disso.
- Um **nome desconhecido gera exceção** (Newtonsoft `EnumUtils.ParseEnum` → `JsonSerializationException`), e como `GetQueue`/`GetHistory` usam `Json.Deserialize` (e não Try), a chamada inteira de fila ou histórico falha. **Nunca envie um status fora desta lista.**
- Envie os nomes canônicos do SAB exatamente como acima (`"Downloading"`, `"QuickCheck"`, `"Completed"`, `"Failed"`, `"Propagating"`, ...). O casamento de enum do Newtonsoft até aceita sem diferenciar maiúsculas de minúsculas, mas a grafia exata é a única coisa em que vale a pena confiar.
- Inteiros também são aceitos (`AllowIntegerValues` é true por padrão), mas não os use.
- Um `null` em JSON para `status` é ignorado por causa do `NullValueHandling.Ignore` e o membro continua como `Grabbing` (0): um slot da fila vira `Queued` silenciosamente, e um slot do histórico vira `Downloading` silenciosamente. Sempre envie um status explícito.

## 3. `get_config`: exatamente o que é lido, e as regras de validação {#3-get_config-exactly-what-is-read-and-the-validation-rules}

### 3.1 O modelo — `SabnzbdCategory.cs` {#31-the-model--sabnzbdcategorycs}

Este arquivo contém `SabnzbdConfig`, `SabnzbdConfigMisc`, `SabnzbdCategory` **e** `SabnzbdSorter`.
Não existe **nenhum `SabnzbdConfig.cs`** em nenhum dos dois repositórios (confirmado pela listagem da API de conteúdo do GitHub em `src/NzbDrone.Core/Download/Clients/Sabnzbd`).

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

### 3.2 `config.misc.*` — o conjunto completo de chaves lidas (`SabnzbdCategory.cs:23-37`) {#32-configmisc--the-complete-set-of-keys-read-sabnzbdcategorycs23-37}

| Chave JSON | Tipo C# | Lido em | Finalidade |
|---|---|---|---|
| `complete_dir` | `string` | `Sabnzbd.cs:218` | Base para todos os caminhos de categoria. |
| `tv_categories` | `string[]` | `Sabnzbd.cs:265, 493` | |
| `enable_tv_sorting` | `bool` | `Sabnzbd.cs:265, 493` | |
| `movie_categories` | `string[]` | `Sabnzbd.cs:269, 502` | |
| `enable_movie_sorting` | `bool` | `Sabnzbd.cs:269, 502` | |
| `date_categories` | `string[]` **via `SabnzbdStringArrayConverter`** | `Sabnzbd.cs:273, 511` | |
| `enable_date_sorting` | `bool` | `Sabnzbd.cs:273, 511` | |
| `pre_check` | `bool` | `Sabnzbd.cs:443` | |
| `history_retention` | `string` | `Sabnzbd.cs:540, 561-573` | Legado, SAB < 4.3. |
| `history_retention_option` | `string` | `Sabnzbd.cs:541, 544` | SAB >= 4.3. |
| `history_retention_number` | `int` | `Sabnzbd.cs:542, 553` | SAB >= 4.3. |

`SabnzbdStringArrayConverter` (`JsonConverters/SabnzbdStringArrayConverter.cs:25-39`) — aplicado apenas
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

Uma string JSON vira um array de 1 elemento; um **null** vira `[null]` (um array de 1 elemento contendo
null); um **array** é desserializado normalmente; qualquer outra coisa (um número, um objeto) gera exceção. Comentário de documentação em `:7-9`: "On some properties sab serializes array of single item as plain string."

### 3.3 `config.categories[]` — `SabnzbdCategory` (`SabnzbdCategory.cs:39-48`)

| Chave JSON | C# | Lido em |
|---|---|---|
| `priority` | `int Priority` | nunca lido |
| `pp` | `string PP` | nunca lido (o camelCase de `PP` é `pp`) |
| `name` | `string Name` | `Sabnzbd.cs:251, 255, 458` |
| `script` | `string Script` | nunca lido |
| `dir` | `string Dir` | `Sabnzbd.cs:238` (`Dir.TrimEnd('*')`), `Sabnzbd.cs:462` (`Dir.EndsWith("*")`) |

`FullPath` (`OsPath`) é calculado, não desserializado.

Montagem do caminho — `Sabnzbd.GetCategories` (`Sabnzbd.cs:216-244`):

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

`OsPath.operator+` (`src/NzbDrone.Common/Disk/OsPath.cs:420-448`) retorna `left` quando `right.IsEmpty`,
então `dir: ""` resulta exatamente em `FullPath == complete_dir`. `IsRooted` para um caminho do tipo Unix
é `_path.StartsWith("/")` (`OsPath.cs:142-145`); o tipo do caminho é identificado pela string
(`OsPath.cs:43-60`): um `/` no início ⇒ Unix, um `\` ou letra de unidade ⇒ Windows. Um caminho do tipo Unix
passado para um Sonarr hospedado no Windows falha em `CompletedDownloadService.ValidatePath` (`:305-310`).

### 3.4 As duas armadilhas de NRE (e o que é realmente seguro) {#34-the-two-nre-landmines-and-what-is-actually-safe}

| Formato do payload | Resultado |
|---|---|
| **`"misc"` ausente ou `null`** | `Misc` fica null (sem valor padrão no construtor; `NullValueHandling.Ignore` na leitura) → **NullReferenceException em `Sabnzbd.cs:218`**, aparecendo como "Test was aborted due to an error: …" e como erro registrado nas verificações de saúde. |
| **uma categoria com `"dir"` ausente ou `null`** | `Dir` fica null → **NullReferenceException em `Sabnzbd.cs:238`** (`category.Dir.TrimEnd('*')`) e de novo em `:462` (`category.Dir.EndsWith("*")`). |
| `"categories": null` ou ausente | Seguro: a lista vazia do construtor continua valendo. `GetStatus` então não encontra categoria e `OutputRootFolders` fica vazio. |
| `"sorters": null` ou ausente | Seguro: lista vazia do construtor; `config.Sorters.Any(...)` em `Sabnzbd.cs:484` funciona. |
| `"servers": null` ou ausente | Seguro e nunca lido (`List<object>`, `SabnzbdCategory.cs:19`). |
| `"tv_categories"/"movie_categories"/"date_categories": null` | Seguro: `ContainsCategory` retorna `true` para null/vazio (§3.5), mas isso só importa se o `enable_*_sorting` correspondente estiver true. |

**Regra: sempre envie `misc` como objeto e toda categoria com um `dir` do tipo string (use `""`).**

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

Confirmado pelos fixtures: `enable_tv_sorting=true` + `tv_categories=null` **falha**
(`SabnzbdFixture.cs:636-645`), e + `tv_categories=[]` também **falha** (`:647-656`).
`TvCategory=null` + `tv_categories=["Default"]` falha (`:680-691`).

### 3.6 `Test()` — a ordem exata e as regras (`Sabnzbd.cs:286-292`) {#36-test--the-exact-order-and-rules-sabnzbdcs286-292}

```csharp
protected override void Test(List<ValidationFailure> failures)
{
    failures.AddIfNotNull(TestConnectionAndVersion());
    failures.AddIfNotNull(TestAuthentication());
    failures.AddIfNotNull(TestGlobalConfig());
    failures.AddIfNotNull(TestCategory());
}
```

Envolvido por `DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`),
que captura qualquer exceção que escape e adiciona `"Test was aborted due to an error: " + ex.Message`.

**`TestConnectionAndVersion()` (`Sabnzbd.cs:368-414`)** — 1 × `mode=version`:

1. versão não interpretável → falha no campo `Version` (`DownloadClientSabnzbdValidationUnknownVersion`).
2. `rawVersion == "develop"` (ignorando maiúsculas) → **aviso** no `Version`, `IsValid` continua true
   (fixture `SabnzbdFixture.cs:566-577`).
3. `version.Major >= 1` → passa (`:389-392`).
4. senão, `version.Minor >= 7` → passa (`:394-397`).
5. senão, falha: versão necessária `"0.7.0"` (`:399-404`).
   Tabela da fixture (`SabnzbdFixture.cs:549-564`): `0.6.9`→false, `0.7.0`/`0.8.0`/`1.0.0`/`1.0.0RC1`/`1.1.x`→true.
6. Qualquer exceção → falha no campo `Host` ("unable to connect"), detalhe = `ex.Message` (`:406-413`).

**`TestAuthentication()` (`Sabnzbd.cs:416-438`)** — 1 × `mode=get_config`. Captura a exceção e então verifica
`ex.Message` com `ContainsIgnoreCase`:

| Texto encontrado | Campo da falha |
|---|---|
| `API Key Incorrect` | `APIKey` — `DownloadClientValidationApiKeyIncorrect` |
| `API Key Required` | `APIKey` — `DownloadClientValidationApiKeyRequired` |
| qualquer outro caso | **relançada** → mensagem genérica "Test was aborted due to an error: …" |

Como `CheckForError` envolve o corpo como `"Error response received from SABnzbd: {error}"`
(`SabnzbdProxy.cs:244`), a verificação funciona quando sua string `error` *contém* `API Key Incorrect` /
`API Key Required`, que é o texto original do próprio SAB.

**`TestGlobalConfig()` (`Sabnzbd.cs:440-453`)** — 1 × `mode=get_config`, mais 1 × `mode=version`
somente se `pre_check` for true:

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

Limite: **SAB >= 1.1.0** (`HasVersion(major:1, minor:1, patch:0)`, `Sabnzbd.cs:294-332`).
`pre_check: false` evita todo esse bloco, incluindo a chamada extra de `mode=version`.

**`TestCategory()` (`Sabnzbd.cs:455-521`)** — 1 × `mode=get_config` (uma *terceira* vez), mais o que
`GetCategories` precisar. As verificações rodam nesta ordem, e a primeira que bater vence:

1. categoria encontrada (`Name == Settings.TvCategory` / `MovieCategory`) cujo `dir` **termina com `*`**
   → aviso em `TvCategory`/`MovieCategory` "enable job folders", InfoLink `config/categories/` (`:460-469`).
2. nenhuma categoria encontrada **e** a categoria configurada não está em branco → aviso
   `DownloadClientValidationCategoryMissing`, InfoLink `config/categories/` (`:471-481`).
3. `config.Sorters.Any(s => s.is_active && ContainsCategory(s.sort_cats, cat))` → aviso, InfoLink
   `config/sorting/` (`:483-491`). Comentário no código, em `:483`: *"New in SABnzbd 4.1, but on older versions
   this will be empty and not apply"*.
4. `misc.enable_tv_sorting && ContainsCategory(misc.tv_categories, cat)` → aviso (`:493-500`).
5. `misc.enable_movie_sorting && ContainsCategory(misc.movie_categories, cat)` → aviso (`:502-509`).
6. `misc.enable_date_sorting && ContainsCategory(misc.date_categories, cat)` → aviso (`:511-518`).

`SabnzbdSorter` (`SabnzbdCategory.cs:50-66`) — lidos: `sort_cats` (`List<string>`, vazio no construtor),
`is_active` (`bool`). Presentes no modelo, mas nunca lidos: `name`, `order`, `min_size`,
`multipart_label`, `sort_string`, `sort_type` (`List<int>`).

**Nota sobre tráfego:** os quatro métodos `Test*` fazem as próprias chamadas, e nada fica em cache. Um
teste de conexão único faz cerca de **2 × `mode=version` e 3 × `mode=get_config`** (uma 4ª chamada de versão se
`pre_check` for true).

### 3.7 Retenção do histórico em `config.misc` → `RemovesCompletedDownloads` (`Sabnzbd.cs:538-574`) {#37-configmisc-history-retention--removescompleteddownloads-sabnzbdcs538-574}

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

`true` dispara um **aviso** de verificação de saúde
(`HealthCheck/Checks/DownloadClientRemovesCompletedDownloadsCheck.cs:44-53`).
Cobertura do fixture `SabnzbdFixture.cs:455-510`: legado `"0"`/`""`/`null`/`"15d"` → false;
`"-1"`/`"15"`/`"3"`/`"3d"` → true.

**Melhor resposta para o emulador: `history_retention_option: "all"`, `history_retention_number: 0`,
`history_retention: "0"`.**

### 3.8 `SortingMode` e sua verificação de saúde (`Sabnzbd.cs:263-279`) {#38-sortingmode-and-its-health-check-sabnzbdcs263-279}

`GetStatus` define `SortingMode` como `"TV"`, `"Movie"` ou `"Date"` usando os mesmos predicados `enable_*_sorting && ContainsCategory(...)`. Qualquer valor não vazio dispara um aviso em `HealthCheck/Checks/DownloadClientSortingCheck.cs:45-55`. Mantenha os três `enable_*_sorting` como false.

### 3.9 `IsLocalhost` (`Sabnzbd.cs:260`)

```csharp
IsLocalhost = Settings.Host == "127.0.0.1" || Settings.Host == "localhost"
```

Ordinal, diferencia maiúsculas e minúsculas; `::1`, `Localhost` e qualquer hostname **não** contam. Isso muda qual mensagem de `RemotePathMappingCheck` você recebe (veja §6.2).

---

## 4. Tratamento de erros — `CheckForError` (`SabnzbdProxy.cs:222-246`) {#4-error-handling--checkforerror-sabnzbdproxycs222-246}

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

Regras, em detalhes:

- `CheckForError` roda em **toda** resposta, antes de qualquer desserialização específica do modo
  (`SabnzbdProxy.cs:217`).
- `Status` é tipado como `string`, mas o SAB envia um **booleano** JSON. O Newtonsoft converte `false` → `"False"`, e `Failed` compara sem diferenciar maiúsculas de minúsculas. Tanto `false` (booleano) quanto `"false"` (string) funcionam.
- Uma resposta **sem `status` no nível superior** (ex.: `{"version": …}`, `{"queue": {...}}`, `{"history": {...}}`, `{"config": {...}}`) deixa `Status` como null → `Failed` falso → sem erro.
- `status: true` → `"True"` → não falhou.
- **Corpo que não é JSON**: `TryDeserialize` retorna false (ele captura `JsonReaderException` e
  `JsonSerializationException`, `Json.cs:107-116`) e o ramo de texto simples é executado. Um corpo que começa
  com `error` (sem diferenciar maiúsculas de minúsculas) → `Status = "false"` → lança
  `DownloadClientException("Error response received from SABnzbd: {body with 'error: ' stripped}")`.
  Qualquer outro corpo que não seja JSON → `Status = "true"` → **tratado como sucesso**, e a desserialização específica do modo
  então falha por conta própria.
- Um **corpo JSON cujo `status` é um objeto** (`mode=fullstatus`) também cai no ramo de texto simples,
  porque um token `StartObject` não consegue preencher uma propriedade `string` — `Status` passa a ser `"true"`.
- Observe a atribuição redundante `result.Error = …` na linha `:239`: `Error` é definido mesmo no ramo de sucesso. Ela não tem efeito (nada lê `Error` a não ser que `Failed` seja verdadeiro).

Mapeamento de exceções em `ProcessRequest` (`SabnzbdProxy.cs:187-220`):

| Capturada | Lançada |
|---|---|
| `HttpException` (qualquer não 2xx, inclusive 401/403/404/500) | `DownloadClientException("Unable to connect to SABnzbd, {0}")` |
| `HttpRequestException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |
| `WebException` com `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, certificate validation failed.")` |
| outra `WebException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |

**As strings exatas de falha de autenticação verificadas** (`Sabnzbd.cs:424, 429`, literais exatos, comparados com
`ContainsIgnoreCase` contra a mensagem da exceção):

- `"API Key Incorrect"`
- `"API Key Required"`

Nada além disso é classificado. Emita-as exatamente como estão, como o valor de `error` de uma resposta **HTTP 200**.

**Por que nunca se deve retornar um não-200:** `HttpClient.Execute` lança exceção antes de `CheckForError` sequer rodar
(`HttpClient.cs:106-121`), a mensagem de `HttpException` resultante contém apenas status/método/URL e
não o corpo (`HttpException.cs:18`), então a comparação de `"API Key Incorrect"` / `"API Key Required"`
nunca dispara. O usuário vê "Unable to connect to SABnzbd" ou "Test was aborted due to an error"
em vez de uma mensagem útil, e toda verificação de saúde trata o cliente como inacessível.

---

## 5. A sequência pós-importação {#5-the-post-import-sequence}

### 5.1 Quem chama `RemoveItem`, e com quais parâmetros {#51-who-calls-removeitem-and-with-what}

`DownloadEventHub` (`src/NzbDrone.Core/Download/DownloadEventHub.cs`, idêntico nos dois repositórios, exceto pelo BOM):

- `Handle(DownloadCompletedEvent)` (`:48-69`): chama `MarkItemAsImported` (o SAB lança `NotSupportedException` — `DownloadClientBase.cs:189-192` — que é registrada em nível debug e ignorada), depois sai cedo se o item já estiver `Removed`, `!CanBeRemoved` ou ainda `Downloading`, e então sai cedo, a menos que `definition.RemoveCompletedDownloads` esteja ativo.
- `Handle(DownloadFailedEvent)` (`:26-46`): condicionado a `definition.RemoveFailedDownloads`.
- `Handle(DownloadCanBeRemovedEvent)` (`:71-85`): condicionado a `definition.RemoveCompletedDownloads`.
- Todos os três passam por `RemoveFromDownloadClient` (`:87-103`):

```csharp
_logger.Debug("[{0}] Removing download from {1} history", …);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);   // :92 -- deleteData is ALWAYS true
trackedDownload.DownloadItem.Removed = true;
```

Valores padrão de `DownloadClientDefinition` (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17-18`):

```csharp
public bool RemoveCompletedDownloads { get; set; } = true;
public bool RemoveFailedDownloads    { get; set; } = true;
```

O caminho manual da API `DELETE /api/v3/queue/{id}?removeFromClient=true` também passa `true`
(Sonarr `src/Sonarr.Api.V3/Queue/QueueController.cs:342`). **Não existe nenhum ponto de chamada em lugar algum que passe `deleteData: false`.**

### 5.2 `Sabnzbd.RemoveItem` (`Sabnzbd.cs:197-214`) — a sequência exata {#52-sabnzbdremoveitem-sabnzbdcs197-214--the-exact-sequence}

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

Então, a sequência pós-importação contra o emulador fica assim:

1. `GET /api?mode=queue&start=0&limit=0&category=tv&apikey=…&output=json` (para decidir entre fila e histórico)
2. **exclusão local da pasta de saída** (§5.3) — antes de qualquer outra chamada HTTP
3. `GET /api?mode=history&name=delete&del_files=1&value={nzo_id}&archive=1&apikey=…&output=json`

Para um item **com falha**: sem exclusão local (o status é `Failed`, não `Completed`), e **`archive=0`** — a inversão em `SabnzbdProxy.cs:80` (`archive = deletePermanently ? 0 : 1`, onde `deletePermanently == (status is Failed)`).

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

- **Sim, ele apaga recursivamente a pasta de saída.** `DeleteFolder(path, recursive: true)` na linha `:129`.
- O `OutputPath` aqui é o `storage` do item do histórico depois do remapeamento do caminho remoto e da subida até a pasta do job (§1.6.2). Para um diretório magic plano, isso significa `rm -rf /mnt/zurg/__magic__/__all__/<Title>`.
- A configuração que manda nisso é o botão **Remove Completed Downloads** do cliente de download (`DownloadClientDefinition.RemoveCompletedDownloads`, padrão **true**), *não* uma configuração do lado do SAB e *não* `del_files`. Não existe uma opção separada de "apagar dados" na interface.
- Falhas são engolidas com um aviso. Um mount somente leitura gera ruído no log, mas não quebra a importação.
- Cobertura do fixture `SabnzbdFixture.cs:693-803`: pasta apagada recursivamente, arquivo apagado, nada quando o caminho não existe, e nada de nada (nem mesmo uma checagem de `FolderExists`) quando `deleteData` é false.

### 5.4 Modo de transferência: o arquivo é movido ou copiado? {#54-transfer-mode-is-the-file-moved-or-copied}

`Sabnzbd` define `CanMoveFiles = true` em **todo** item, tanto na fila (`Sabnzbd.cs:76`) quanto no histórico (`Sabnzbd.cs:135`). O caminho de importação automática é `CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, …)` (Sonarr `CompletedDownloadService.cs:148-151`), e depois:

Sonarr `src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152`
(Radarr `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, lógica idêntica):

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
(`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`). Uma importação com `copyOnly` usaria, em vez disso, `TransferMode.HardLinkOrCopy` quando "Use Hardlinks instead of Copy" estiver ativado; caso contrário, `TransferMode.Copy` (`:94-108`).

`TransferMode` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`) é `[Flags]`:
`None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy = Copy|HardLink`.

### 5.5 Uma falha no Move volta para uma cópia? — **Não. Uma falha no Move é uma falha na importação.** {#55-does-a-failed-move-fall-back-to-a-copy--no-a-failed-move-is-a-failed-import}

`src/NzbDrone.Common/Disk/DiskTransferService.cs` (idêntico byte a byte entre os dois repositórios — verificado).
`TransferFile`, `:256-392`; o branch `TransferMode.Move` em `:360-389`:

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

- O **único** fallback de cópia é o caso especial `isCifs && !isSameMount` em `:378-385`, baseado em `targetMount.DriveFormat == "cifs"` (`:342`). Ele é escolhido *logo no início* a partir do formato do drive, nunca como reação a uma falha.
- `TryMoveFileVerified` (`:487-503`) captura a exceção, chama `RollbackPartialMove` (a não ser que a exceção seja `FileAlreadyExistsException`) e **relança** a exceção:

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

- `VerifyFile` (`:505-524`) compara o tamanho do destino com o tamanho da origem, espera 3 s (`WaitForIO`, `:467-471`), verifica de novo e então lança `IOException("File move incomplete, data loss may have occurred. [{target}] was {n} bytes long instead of the expected {m}.")`.
- Essa `IOException` sobe por `EpisodeFileMovingService.TransferFile` (`:151`) até o `catch (Exception e)` genérico em `ImportApprovedEpisodes.cs:218-222` (Radarr `:197-201`), gerando `ImportResult(importDecision, "Failed to import episode")` / `"Failed to import movie"`. **Nenhuma cópia é tentada.**
- Outras `IOException`s de verificação prévia no mesmo método: origem == destino (`:270`, `:277`) e "Destination cannot be a child of the source" (`:312-315`).

Uma ressalva, e ela é um fato do runtime do .NET, não código do Sonarr: `DiskProviderBase.MoveFileInternal` (`src/NzbDrone.Common/Disk/DiskProviderBase.cs:293-301`) é um `File.Move` simples, e o .NET no Unix faz fallback para copiar e apagar quando `rename()` retorna `EXDEV`. Ou seja, um move entre sistemas de arquivos diferentes geralmente ainda funciona — como fallback em *tempo de execução*, não do Sonarr. O que **não** é tolerado é um destino com tamanho diferente da origem, ou qualquer exceção que o próprio `File.Move` lance (EACCES, EPERM, EROFS na origem, …).

`TransferFolder` (`:44-137`) é usado por outros caminhos de código; repare em `:124-131` — depois de um Move de pasta, ele se recusa a apagar a origem se ainda restarem mais de 100 MB de arquivos (`IOException("Large files still exist in {sourcePath} after folder move, not deleting source folder")`).

## 6. As duas verificações de saúde {#6-the-two-health-checks}

### 6.1 `DownloadClientRootFolderCheck` — **o único ponto em que Sonarr e Radarr realmente diferem** {#61-downloadclientrootfoldercheck--the-one-place-sonarr-and-radarr-genuinely-differ}

Sonarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = status.OutputRootFolders.Where(folder => rootFolders.Any(r => r.Path.PathEquals(folder.FullPath)));
```

Radarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51`:

```csharp
var folders = rootFolders.Where(r => status.OutputRootFolders.Any(folder => r.Path.PathEquals(folder.FullPath) || r.Path.IsParentPath(folder.FullPath)));
```

`IsParentPath` (`src/NzbDrone.Common/Extensions/PathExtensions.cs:123-140`) sobe **para cima** a partir do filho:

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

Então `r.Path.IsParentPath(folder.FullPath)` é verdadeiro quando **a root folder é um ancestral da
pasta de saída do download**, ou seja, a pasta de saída fica *dentro* de uma root folder. É um teste de ancestral estrito
(ele começa em `child.Directory`); a igualdade é tratada separadamente por `PathEquals`.

**Respondendo diretamente à questão do predicado:**

| Relação (pasta de saída O vs root folder R) | Sonarr | Radarr |
|---|---|---|
| O == R | **aviso** | **aviso** |
| O dentro de R (R é ancestral de O) | sem aviso | **aviso** |
| O é o PAI de R (O é ancestral de R) | sem aviso | **sem aviso** |
| não relacionadas | sem aviso | sem aviso |

Com `complete_dir = /mnt/zurg/__magic__/__all__` e `dir: ""` (então `OutputRootFolders == ["/mnt/zurg/__magic__/__all__"]`):

- O Sonarr só avisa se uma root folder for exatamente `/mnt/zurg/__magic__/__all__`.
- O Radarr avisa se uma root folder for `/mnt/zurg/__magic__/__all__`, `/mnt/zurg/__magic__`, `/mnt/zurg` ou `/mnt`.
- Nenhum dos dois avisa se uma root folder for `/mnt/zurg/__magic__/tv` — o espelho e as root folders são
  irmãos, então o par não tem relação e nenhuma regra dispara. Uma root folder *dentro* da pasta de saída
  (`/mnt/zurg/__magic__/__all__/anything`) também ficaria quieta aqui, mas o namespace não deixa guardar nada nessa profundidade, então não é um arranjo que pode existir.

`PathEquals` (`PathExtensions.cs:55-73`) normaliza Unicode, usa `DiskProviderBase.PathStringComparison`
(`OrdinalIgnoreCase` no Windows, `Ordinal` nos demais — `src/NzbDrone.Common/Disk/DiskProviderBase.cs:17-23`), e tenta de novo com `CleanFilePath()` (ignora a barra final).

As duas versões rodam de novo em `ProviderUpdatedEvent` / `ProviderDeletedEvent` / `ModelEvent<RootFolder>` / `ModelEvent<RemotePathMapping>`; o Radarr adiciona `[CheckOn(typeof(ProviderAddedEvent<IDownloadClient>))]`
na linha `:17`. O resultado é `HealthCheckResult.Warning` com a âncora `#downloads-in-root-folder`. A mensagem
interpola `folder.FullPath` no Sonarr e `folder.Path` no Radarr (`:60` nos dois). Ambas ignoram silenciosamente `DownloadClientException` e `HttpRequestException` (log de debug) e registram qualquer outra exceção
como erro.

(Uma tradução anterior foi rejeitada: os trechos de código não batiam. Mantenha a estrutura exatamente como está.)

### 6.2 `RemotePathMappingCheck` — o caminho do cliente local (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs`) {#62-remotepathmappingcheck--the-local-client-path-srcnzbdronecorehealthcheckchecksremotepathmappingcheckcs}

Curto-circuito em `:51-54`: se `EnableCompletedDownloadHandling` estiver desligado, a verificação não faz nada.

Para cada `folder` em `client.GetStatus().OutputRootFolders`:

1. **`!folder.IsValid`** (`:68`) — `OsPath.IsValid` = `_path.IsPathValid(PathValidationType.CurrentOs)`
   (`OsPath.cs:228`). Fora do Windows, isso se reduz a `path.StartsWith("/")` mais uma verificação de `Path.GetInvalidPathChars()` (`PathExtensions.cs:143-182`, `:403-411`). Erros, nesta ordem:
   - `!status.IsLocalhost` → `RemotePathMappingWrongOSPathHealthCheckMessage` (chave no Radarr: `RemotePathMappingCheckWrongOSPath`), âncora `#bad-remote-path-mapping`
   - `_osInfo.IsDocker` → …`BadDockerPath`, âncora `#docker-bad-remote-path-mapping`
   - caso contrário → …`LocalWrongOSPath`, âncora `#bad-download-client-settings`
2. Se **`!_diskProvider.FolderExists(folder.FullPath)`** (`:115`):
   - `_osInfo.IsDocker` → …`DockerFolderMissing`, `#docker-bad-remote-path-mapping`
   - `!status.IsLocalhost` → …`LocalFolderMissing`, `#bad-remote-path-mapping`
   - caso contrário → …`GenericPermissions`, `#permissions-error`

**Para um cliente local (`IsLocalhost` verdadeiro, sem Docker), isso se reduz a exatamente dois requisitos:**
a pasta raiz de saída informada precisa ser um caminho absoluto *para o sistema operacional em que o Sonarr/Radarr roda*, e ela precisa **existir no host do Sonarr/Radarr** como um diretório. `/mnt/zurg/__magic__/__all__` precisa estar visível para o processo do *arr, não só para o emulador. **Não existe verificação de permissão de escrita aqui.**

A sobrecarga orientada a eventos (`:178-368`) dispara em `EpisodeImportFailedEvent` (no Radarr: `MovieImportFailedEvent`) e, o que é importante, chama `client.GetItems()` de novo para buscar o `OutputPath` do download que falhou (`:232`).

Nenhuma verificação de saúde exige que a pasta de saída seja *gravável*. `FolderWritable` (`DiskProviderBase.cs:126-143` no Sonarr / `:127-144` no Radarr) — que grava e apaga `sonarr_write_test.txt` / `radarr_write_test.txt` — é usada por `RootFolderService.Add` (Sonarr `src/NzbDrone.Core/RootFolders/RootFolderService.cs:117-120`) e por `DownloadClientBase.TestFolder` (`:167-187`), e **`TestFolder` nunca é chamada pelo cliente SAB.**

## 7. Sonarr vs Radarr — o diff completo {#7-sonarr-vs-radarr--the-complete-diff}

Todos os arquivos baixados foram comparados com diff. Resultados:

**Idênticos byte a byte, exceto por um BOM UTF-8 nas cópias do Sonarr** (os números de linha, portanto, batem exatamente):

`SabnzbdCategory.cs` (sem BOM em nenhum dos lados, realmente idêntico), `SabnzbdDownloadStatus.cs`,
`SabnzbdPriority.cs`, `SabnzbdFullStatus.cs`, `SabnzbdJsonError.cs`, `SabnzbdQueue.cs`,
`SabnzbdQueueItem.cs`, `SabnzbdHistory.cs`, `SabnzbdHistoryItem.cs`,
`JsonConverters/*.cs` (os três), `Responses/*.cs` (todos os seis),
`src/NzbDrone.Common/Disk/DiskTransferService.cs`, `src/NzbDrone.Core/Download/DownloadEventHub.cs`.

**Diferem apenas pela renomeação `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` (sem mudança no número de linhas, mesmos números de linha):**

- `Sabnzbd.cs` — `:40-52` (`AddFromNzbFile`; o teste de recência do Radarr é `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie`, enquanto o do Sonarr é `remoteEpisode.IsRecentEpisode()`), `:190`, `:251`, `:265/269/273`, `:458`, e todos os nomes de campo `NzbDroneValidationFailure` em `TestCategory` (`"TvCategory"` → `"MovieCategory"`).
- `SabnzbdProxy.cs` — `:50`, `:122-124`, `:138-140`.
- `SabnzbdSettings.cs` — padrões `TvCategory = "tv"` vs `MovieCategory = "movies"`; `RecentTvPriority`/`OlderTvPriority` vs `RecentMoviePriority`/`OlderMoviePriority` (ambos com padrão `(int)SabnzbdPriority.Default`). Fora isso, o validador é idêntico: `Host` válido, `Port` de 1 a 65535, `ApiKey` obrigatório quando o username está em branco, `Username`/`Password` obrigatórios quando o ApiKey está em branco, categoria `NotEmpty` **como aviso**.
- `UsenetClientBase.cs` — o Radarr também define `request.AllowAutoRedirect = true` (`:51`) e trata HTTP `410 Gone` como `404` (`:63`) ao buscar o NZB no indexador. **Isso diz respeito ao indexador, não ao SAB.**
- `DownloadClientBase.cs` — apenas o texto literal "Sonarr"/"Radarr" no texto de detalhe de `TestFolder`.
- `RemotePathMappingCheck.cs` — nomes das chaves de localização (`RemotePathMapping*HealthCheckMessage` vs `RemotePathMappingCheck*`), `EpisodeImportFailedEvent` vs `MovieImportFailedEvent`, mais o `[CheckOn(ProviderAddedEvent<IDownloadClient>)]` extra do Radarr. **Os predicados são idênticos.**
- `DiskProviderBase.cs` — o arquivo de teste do `FolderWritable` é `sonarr_write_test.txt` vs `radarr_write_test.txt` (Sonarr `:132`, Radarr `:133`).

**Diferença real de comportamento — exatamente uma:**

- **`DownloadClientRootFolderCheck.cs:51`.** O Sonarr avisa apenas em `PathEquals`; o Radarr também avisa quando uma pasta raiz é ancestral da pasta de saída. Tabela completa na §6.1.

Todo o resto — modos, parâmetros, formatos JSON, enums, conversores, `CheckForError`, `RemoveItem`, `DeleteItemData`, modo de transferência, `DiskTransferService` — é idêntico. **Um único emulador atende aos dois.**

Padrões de configuração idênticos nos dois: `DownloadClientHistoryLimit = 60`, `RemoveCompletedDownloads = true`, `RemoveFailedDownloads = true`.

## 8. Exemplos de payloads mínimos mas completos {#8-minimal-but-complete-example-payloads}

Dado: `complete_dir = /mnt/zurg/__magic__/__all__`; categorias `*`, `tv`, `movies`, todas com `dir: ""`.
Toda resposta é **HTTP 200** com `Content-Type: application/json`.

`OutputRootFolders` resultante: `dir: ""` ⇒ `FullPath == complete_dir` ⇒ `/mnt/zurg/__magic__/__all__`
para o Sonarr (categoria `tv`) e para o Radarr (categoria `movies`).

### 8.1 `mode=version`

```json
{
  "version": "4.3.3"
}
```

Deve ser `major.minor.(patch|x)`. `4` ≥ 1 atende `TestConnectionAndVersion` (`Sabnzbd.cs:389-392`);
≥ 2.0 também significa que `GetCategories` usaria `fullstatus` em vez de `queue.my_home` se `complete_dir`
fosse relativo (não é).

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

Por que cada valor:

- `misc` presente como objeto — **obrigatório**, senão NRE (§3.4).
- toda categoria tem um `dir` do tipo **string** — **obrigatório**, senão NRE em `Sabnzbd.cs:238` e `:462`.
- `dir` **não** termina com `*` — senão aparece o aviso "enable job folders" (`Sabnzbd.cs:462-469`).
- os três `enable_*_sorting: false` — eliminam tanto os avisos do `TestCategory` (`Sabnzbd.cs:493-518`) quanto o `DownloadClientSortingCheck`. Repare que `tv_categories: []` combinado com `enable_tv_sorting: true` daria **falha**, porque `ContainsCategory` retorna true para lista vazia (`Sabnzbd.cs:525-528`, fixture `SabnzbdFixture.cs:647-656`).
- `sorters: []` — `config.Sorters.Any(s => s.is_active && …)` dá false (`Sabnzbd.cs:484`).
- `pre_check: false` — pula a ida e volta do `HasVersion(1,1)` no `TestGlobalConfig` (`Sabnzbd.cs:443`).
- `history_retention_option: "all"` → `RemovesCompletedDownloads == false` (`Sabnzbd.cs:546-547`) → sem aviso de health-check.
- `complete_dir` absoluto → `IsRooted` true → `mode=fullstatus` / `queue.my_home` nunca são consultados (`Sabnzbd.cs:220`).

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

Só o `completedir` é lido (`SabnzbdFullStatus.cs:9-10`). A chave wrapper **precisa** ser `status` (`Responses/SabnzbdFullStatusResponse.cs:5`).

### 8.4 Resposta de `mode=addfile` {#84-modeaddfile-response}

```json
{
  "status": true,
  "nzo_ids": ["SABnzbd_nzo_abc12345"]
}
```

`nzo_ids` deve ser um **array não vazio de strings** (`Sabnzbd.cs:47-52`). `status` é lido (`Responses/SabnzbdAddResponse.cs:13`), mas nunca é usado; mantenha `true` para que `CheckForError` veja `"True"`.

### 8.5 `mode=queue&start=0&limit=0&category=tv` — um slot Downloading {#85-modequeuestart0limit0categorytv--one-downloading-slot}

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

Requisitos obrigatórios:

- chave de nível superior `queue` (`SabnzbdProxy.cs:129`, `SelectToken("queue")`).
- `slots[].status` ∈ os 16 nomes de `SabnzbdDownloadStatus`, com maiúsculas e minúsculas exatamente iguais.
- `slots[].mb` / `mbleft` são **megabytes**, com decimais no formato de cultura invariante. Strings ou números funcionam (o Newtonsoft faz a conversão); o SAB real envia strings.
- `slots[].timeleft` deve ser exatamente `h:m:s` ou `d:h:m:s` — nunca `""`.
- `slots[].priority` — `"Normal"`, `"High"`, `"Low"`, `"Force"`, `"Paused"`, `"Default"` (diferencia maiúsculas de minúsculas) ou o equivalente numérico. **Nunca `null`** (NRE).
- `slots[].cat` (não `category`) deve ser igual à categoria configurada no cliente, senão o item é filtrado em `Sabnzbd.cs:190`.
- `queue.paused` deve ser `false`, a não ser que você realmente queira pausado — `true` marca todo slot que não seja `Force` como Paused, com ETA nulo (`Sabnzbd.cs:78-84`).

Resultante `DownloadClientItem`: `TotalSize = 1024 * 1024 * 1024`, `RemainingSize = 512 * 1024 * 1024`,
`RemainingTime = 00:08:32`, `Status = Downloading`, `CanBeRemoved = CanMoveFiles = true`.

### 8.6 `mode=history&start=0&limit=60&category=tv` — um slot Completed e um slot Failed {#86-modehistorystart0limit60categorytv--one-completed-and-one-failed-slot}

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

Requisitos obrigatórios:

- chave de nível superior `history` (`SabnzbdProxy.cs:145`).
- `slots[].bytes` é **BYTES** (um número JSON → `long`). Não envie MB aqui: a fila usa MB, o histórico usa bytes (`Sabnzbd.cs:72-73` vs `:128`).
- `slots[].category` (não `cat`).
- `slots[].storage` = a própria pasta do job; ela vira `OutputPath`, e, para um item Completed, é o que `DeleteItemData` apaga recursivamente (§5.3). Precisa ser um caminho absoluto válido no SO em que o Sonarr/Radarr roda e precisa existir lá (`RemotePathMappingCheck`, §6.2).
- `slots[].status` com caixa exata; itens `Deleted` são descartados por completo (`Sabnzbd.cs:116-119`).
- `fail_message` exatamente `"Unpacking failed, write error or disk is full?"` rebaixa um item Failed para `Warning` em vez de `Failed` (`Sabnzbd.cs:140-144`). Use outra mensagem para uma falha de verdade.
- Radarr: `category` precisa ser `movies` (ou o que estiver configurado) e `name` deve ser interpretado como um filme.

### 8.7 Resposta de erro (qualquer mode) {#87-error-response-any-mode}

```json
{
  "status": false,
  "error": "API Key Incorrect"
}
```

**HTTP 200.** `status` pode ser o booleano `false` ou a string `"false"`; ambos satisfazem
`SabnzbdJsonError.Failed` (`SabnzbdJsonError.cs:10-11`). O cliente lança
`DownloadClientException("Error response received from SABnzbd: API Key Incorrect")`
(`SabnzbdProxy.cs:244`), que `TestAuthentication` reconhece (`Sabnzbd.cs:424`).
Use `"API Key Required"` quando nenhuma chave for fornecida (`Sabnzbd.cs:429`). Qualquer outra string de `error` é
exibida exatamente como veio, mas não é classificada.

---

## 9. Checklist de implementação (12 pontos) {#9-implementation-checklist-12-points}

1. Uma rota: `GET|POST {UrlBase}/api`, que despacha pelo `mode`. **Sempre HTTP 200, sempre JSON.**
2. Implemente `version`, `get_config`, `queue` (leitura + `name=delete`), `history` (leitura + `name=delete`), `addfile` e `fullstatus`. Opcionalmente, `retry` (código morto hoje). `get_cats` nunca é chamado.
3. Aceite autenticação por `apikey=` **ou** por `ma_username=` + `ma_password=`. Rejeite com 200 + `{"status":false,"error":"API Key Incorrect"}` / `"API Key Required"`. **Nunca** use 401/403.
4. Respeite `category=` em `queue`/`history` (os clientes também filtram do lado deles por correspondência exata de string, `Sabnzbd.cs:190`).
5. Tamanhos em `queue` são em **MB** (`mb`, `mbleft`); tamanhos em `history` são em **BYTES** (`bytes`). Nunca misture os dois. Queue usa `cat`, history usa `category`.
6. `timeleft` é sempre `h:m:s` ou `d:h:m:s`, nunca vazio e nunca ausente como string vazia. Nenhum campo de data é parseado em lugar nenhum, então os campos de epoch podem ter formato livre.
7. Os valores de `status` precisam vir da lista `SabnzbdDownloadStatus`, com 16 membros, com maiúsculas e minúsculas exatas (um nome desconhecido lança exceção e derruba a chamada inteira de queue/history). `priority` precisa ser um nome de `SabnzbdPriority` (com maiúsculas e minúsculas exatas) ou o seu inteiro; **nunca `null`** (NRE no conversor).
8. `config.misc` precisa ser um objeto; toda categoria precisa ter um `dir` string **não nulo** que não termine em `*`. `categories`/`sorters`/`servers` podem ser null ou ausentes, mas `misc` e `dir` não podem.
9. Mantenha `enable_tv_sorting`, `enable_movie_sorting`, `enable_date_sorting` e `pre_check` todos em `false`, e `history_retention_option: "all"`, para manter o teste de conexão e todas as verificações de saúde limpos.
10. `storage` de um slot de histórico Completed = a pasta do job. Espere que o *arr execute `rm -rf` nela depois de uma importação bem-sucedida (configurações padrão), e espere que o arquivo de mídia seja **movido** para fora dela antes disso. Se o diretório mágico for somente leitura, a exclusão falha silenciosamente (só aparece um aviso no log), mas o *move* do arquivo importado ainda precisa dar certo, senão a importação falha por completo (§5.5).
11. Não coloque nenhuma pasta raiz do *arr em `/mnt/zurg/__magic__/__all__` nem acima dela, se quiser que o `DownloadClientRootFolderCheck` do Radarr fique quieto (o Sonarr só se importa com igualdade exata). Coloque as pastas ao lado do espelho, como `/mnt/zurg/__magic__/tv` e `/mnt/zurg/__magic__/movies`, que não têm relação com a pasta de saída, nem acima nem abaixo dela.
12. `/mnt/zurg/__magic__/__all__` precisa existir como diretório **no host do Sonarr/Radarr**, e não só onde o emulador roda, senão o `RemotePathMappingCheck` gera um erro. Não precisa ser gravável.

## Configurando uma janela de conclusão maior {#configuring-a-larger-completion-window}

Os dois clientes usam 60 como padrão para `DownloadClientHistoryLimit`. O zurg espelha essa janela quando guarda o excedente já concluído na `queue`. Se você aumentar só o limite do cliente, alguns jobs vão aparecer tanto na fila quanto no histórico, e a fila é que prevalece.

Para uma fila grande, defina `sabnzbd.history_limit` no zurg e `DownloadClientHistoryLimit` nos clientes com o mesmo valor, por exemplo 500. Isso expõe mais jobs concluídos e com falha a cada consulta. Deixe o zurg no menor limite do cliente quando vários clientes usam valores diferentes. Essa configuração avançada do cliente não é exposta no recurso de configuração de download-client da API do Sonarr v4; faça backup e pare o cliente antes de editar a configuração salva dele.

```yaml
sabnzbd:
  enabled: true
  history_limit: 500
```

O padrão continua sendo 60; valores zero e negativos usam esse padrão. Uma requisição de histórico de diagnóstico com um limite diferente nunca altera a janela configurada. Avisos que o cliente não consegue resolver ainda precisam de revisão; uma janela maior permite que outros jobs cheguem à importação enquanto esses avisos ocupam espaços no histórico.

A verificação de disponibilidade antes da conclusão amostra os primeiros dezesseis artigos e o último artigo de cada arquivo de conteúdo. Isso pega um artigo faltando no cabeçalho da mídia, que o antigo canário do primeiro artigo deixava passar. Ela baixa o primeiro artigo de cada arquivo de conteúdo, o que confere a identidade do artigo e se o corpo ainda está disponível (um provedor pode responder STAT para um artigo cujo corpo ele já removeu), mais artigos sorteados aleatoriamente até dezesseis corpos para um release com menos arquivos que isso, e no máximo sessenta e quatro corpos no total. Um corpo que o cache de artigos já tem não é baixado de novo. O STAT cobre o restante da amostra. Ela não valida todos os artigos nem prova que a mídia decodifica.

As requisições STAT são agrupadas por arquivo, então a amostra usa uma reserva do pool em vez de dezessete, sem aumentar o limite de conexões da conta. Se um lote não puder ser usado, cai para STATs individuais.
Falhas do servidor deixam o job na fila para nova tentativa; artigos ausentes confirmados geram um download com falha antes da primeira notificação de conclusão.
