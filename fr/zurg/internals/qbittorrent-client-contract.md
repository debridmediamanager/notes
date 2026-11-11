# API qBittorrent telle qu'utilisée par Sonarr et Radarr (develop) {#qbittorrent-web-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Source de vérité : fichiers récupérés depuis `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...`
et depuis `qbittorrent/qBittorrent/master` le **2026-08-27**. Tous les numéros de ligne ci-dessous ont été relevés dans
ces fichiers.

C'est la contrepartie torrent de [contrat client sabnzbd](sabnzbd-client-contract.md). Ce document explique pourquoi `internal/sabnzbd` répond avec les formats qu'il utilise ; celui-ci est la spécification qu'une couche d'adaptation qBittorrent doit respecter **avant** d'être écrite, pour qu'un grab, un poll, un import **en déplacement** et le nettoyage après import fonctionnent dans les deux clients. Quand les deux clients partagent les mêmes mécanismes (la couche HTTP, le sérialiseur JSON, `DiskTransferService`, les vérifications de santé), ce document cite les mêmes lignes et renvoie vers eux au lieu de répéter l'analyse.

Sauf indication contraire dans une section, **les fichiers qBittorrent des deux dépôts sont identiques à part le renommage `Tv*` → `Movie*`**, et :

| Fichier | Numéros de ligne |
|---|---|
| `QBittorrent.cs` (746 lignes dans les deux) | **correspondent ligne à ligne** |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **octet par octet identiques**, correspondent ligne à ligne |
| `QBittorrentSettings.cs` (91 lignes dans les deux) | correspondent ligne à ligne |
| `QBittorrentProxyV2.cs`, `QBittorrentProxyV1.cs` | Sonarr a une ligne vide à la ligne 13 que Radarr n'a pas (vérifié : Sonarr `:12` est le commentaire `// API https://…`, `:13` est vide, `:14` est `public class QBittorrentProxyV2` ; la déclaration de classe Radarr est en `:13`). **Ligne N de Sonarr = ligne N−1 de Radarr pour N ≥ 14.** |
| `QBittorrentProxySelector.cs` | identique, à partir de la ligne 3 |
| `QBittorrentFixture.cs` | réordonné, pas décalé — cité par dépôt |

Les chemins sont `src/NzbDrone.Core/Download/Clients/QBittorrent/...` dans les deux. Les citations ci-dessous sont
les numéros de ligne de **Sonarr**, sauf mention contraire. Le diff complet est en §9.

Rien ici n'est une supposition sur qBittorrent lui-même : chaque affirmation décrit ce que fait le *client*. Quand
une affirmation porte sur le comportement de qBittorrent, elle cite `qbittorrent/qBittorrent` master ; quand elle porte
sur le runtime .NET ou Newtonsoft, elle le dit.

---

## 0. Règles au niveau du transport (elles piègent en premier) {#0-transport-level-rules-these-bite-first}

### 0.1 Le client choisit v1 ou v2 avant tout le reste {#01-the-client-picks-v1-or-v2-before-it-does-anything-else}

`QBittorrentProxySelector.FetchProxy` (`QBittorrentProxySelector.cs:80-95`) :

```csharp
if (_proxyV2.IsApiSupported(settings)) { return Tuple.Create(_proxyV2, _proxyV2.GetApiVersion(settings)); }
if (_proxyV1.IsApiSupported(settings)) { return Tuple.Create(_proxyV1, _proxyV1.GetApiVersion(settings)); }
throw new DownloadClientException("Unable to determine qBittorrent API version");
```

`QBittorrentProxyV2.IsApiSupported` (`QBittorrentProxyV2.cs:28-70`) fait une requête **non authentifiée**
`GET /api/v2/app/webapiVersion` avec `SuppressHttpError = true`, et décide :

| Réponse | Résultat |
|---|---|
| `404` | pas v2 → on passe à v1 |
| `403` | **v2 supportée** (`:44-47`) — c'est la réponse « pas encore connecté » |
| `401` | `DownloadClientException("Failed to connect to qBittorrent. Check your settings and qBittorrent configuration.")` (`:49-52`) |
| tout autre `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` (`:54-57`) |
| `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to qBittorrent, certificate validation failed.")` (`:63-66`) |
| `200` | v2 supportée |

`QBittorrentProxyV1.IsApiSupported` (`QBittorrentProxyV1.cs:27-59`) fait la même chose sur
`GET /version/api`. À noter : **pas de `/api/v2` devant**, et le 401 n'est *pas* traité à part ici.

La paire `(proxy, version)` est mise en cache pendant **10 minutes**, indexée sur `{Host}_{Port}`
(`QBittorrentProxySelector.cs:68-78`). `GetProxy(settings, force: true)` la supprime. Le test de connexion fait exactement ça (`QBittorrent.cs:435`, `:519`), et c'est ce que vérifie le fixture (Sonarr `QBittorrentFixture.cs:986-998`, Radarr `:984-996`).

**Un shim doit répondre à `/api/v2/app/webapiVersion` et ne jamais exposer les routes v1.** v1 est l'API d'avant la 4.1 (`/version/api`, `/query/torrents`, `/command/download`, …). C'est un poids mort pour une nouvelle implémentation, et elle ne peut pas du tout satisfaire le chemin d'import : `GetLabels` lève `NotSupportedException("qBittorrent api v1 does not support getting all torrent categories")` (`QBittorrentProxyV1.cs:236-239`), et `SetTorrentSeedingConfiguration` ne fait rien (`:241-244`).
Le reste de ce document ne concerne que l'API v2 ; la §1.17 donne la liste complète des routes v1.

### 0.2 Forme des URL {#02-url-shape}

`QBittorrentProxyV2.BuildRequest` (`QBittorrentProxyV2.cs:341-359`) :

```csharp
var requestBuilder = new HttpRequestBuilder(settings.UseSsl, settings.Host, settings.Port, settings.UrlBase)
{
    LogResponseContent = true,
    StoreRequestCookie = false
};
```

- URL de base : `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-65`)
  = `{http|https}://{Host}:{Port}{UrlBase}` ; `UrlBase` reçoit un `/` au début s'il en manque un.
- `Resource("/api/v2/…")` (`HttpRequestBuilder.cs:244-256`) retire le `/` du début et ajoute la suite,
  donc l'URL complète est `{scheme}://{host}:{port}{urlBase}/api/v2/{group}/{method}`.
- **Pas d'en-tête `Accept`.** `BuildRequest` n'appelle jamais `.Accept(...)`, et le constructeur de `HttpRequest` ne définit `Headers.Accept` que si `httpAccept != null`
  (`src/NzbDrone.Common/Http/HttpRequest.cs:14,30-32`). Ne conditionne pas sur `Accept`.
- `StoreRequestCookie = false` : le stockage des cookies est géré par le proxy, pas par la couche HTTP.

### 0.3 GET avec query vs POST avec formulaire — et quand le formulaire devient multipart {#03-get-with-query-vs-post-with-form--and-when-the-form-becomes-multipart}

Les appels en lecture seule utilisent `AddQueryParam` (`HttpRequestBuilder.cs:306-317`) sur un GET. Les appels qui modifient des données utilisent `.Post()` plus `AddFormParameter` / `AddFormUpload`.

`ApplyFormData` (`HttpRequestBuilder.cs:150-242`) choisit l'encodage :

```csharp
var shouldSendAsMultipart = FormData.Any(v => v.ContentType != null || v.FileName != null || v.ContentData.Length > 1024);
```

- Tout `AddFormUpload` (qui définit `FileName` et `ContentType`) force **`multipart/form-data`** (`:379-395`, `:220`).
- **Toute valeur de formulaire unique de plus de 1024 octets force aussi le multipart** (`:162`). Un URI magnet avec une longue liste de trackers dépasse cette limite, donc `POST /api/v2/torrents/add` arrive en `application/x-www-form-urlencoded` *ou* en `multipart/form-data` selon le magnet. **Une couche de compatibilité doit analyser les deux sur cette route.**
- Sinon : `application/x-www-form-urlencoded`, avec les valeurs échappées par `Uri.EscapeDataString(Encoding.UTF8.GetString(...))` (`:230`).

Le writer multipart est écrit à la main (`:164-227`) et écrit `Content-Disposition: form-data; name="…"` (plus `; filename="…"` et une ligne `Content-Type:` pour les uploads), une ligne vide, les octets bruts, puis `\r\n`. La frontière est `-----------------------------{ticks:x14}` (`:166`).

**Le formatage des booléens est un piège.** `AddFormParameter` stocke `Convert.ToString(value, CultureInfo.InvariantCulture)` (`HttpRequestBuilder.cs:373`), et `Convert.ToString(bool)` de .NET donne **`"True"` / `"False"`, avec la majuscule**. Donc `request.AddFormParameter("stopped", false)` (`QBittorrentProxyV2.cs:258`) envoie `stopped=False` sur le fil, et non `stopped=false`. Le vrai qBittorrent s'en sort parce que `Utils::String::parseBool` (`src/base/utils/string.cpp:108-116`) compare sans tenir compte de la casse. **Une couche de compatibilité doit accepter `True`/`False` autant que `true`/`false`.** Là où le client écrit la chaîne en dur, elle est en minuscules : `deleteFiles` vaut `"true"` (`QBittorrentProxyV2.cs:198`) et `value` dans `setForceStart` vaut `"true"`/`"false"` (`:337`). Les deux orthographes apparaissent donc vraiment.

Les nombres passent par le même chemin de culture invariante, donc `ratioLimit=1.5` utilise toujours `.` comme séparateur décimal (`QBittorrentProxyV2.cs:234`, `HttpRequestBuilder.cs:373`).

### 0.4 Authentification — trois couches, qui peuvent toutes être actives en même temps {#04-authentication--three-layers-all-of-which-can-be-live-at-once}

`BuildRequest` (`QBittorrentProxyV2.cs:349-356`) :

```csharp
if (settings.ApiKey.IsNotNullOrWhiteSpace())
    requestBuilder.Headers["Authorization"] = $"Bearer {settings.ApiKey}";
else if (settings.Username.IsNotNullOrWhiteSpace() || settings.Password.IsNotNullOrWhiteSpace())
    requestBuilder.NetworkCredential = new BasicNetworkCredential(settings.Username, settings.Password);
```

1. **API key** → `Authorization: Bearer <key>` sur chaque requête, et `ProcessRequest` emprunte un chemin court-circuité qui ne se connecte jamais (`:371-395`). `QBittorrentSettingsValidator` interdit username/password en même temps qu'une clé (`QBittorrentSettings.cs:16-21`).
2. **Username/password** → `BasicNetworkCredential`, que `ManagedHttpDispatcher` transforme en en-tête **préemptif** `Authorization: Basic base64(user:pass)` sur *chaque* requête, y compris `auth/login` lui-même (`src/NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:81-89`, commentaire : « Définir l'en-tête manuellement pour éviter la réponse de challenge initiale »).
3. **Cookie session** → `AuthenticateClient` (`QBittorrentProxyV2.cs:430-494`).

`AuthenticateClient`, exactement :

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

Conséquences pour un shim :

- `POST /api/v2/auth/login`, corps `username=…&password=…`, `application/x-www-form-urlencoded`.
- Répondre **HTTP 200** avec un corps exactement `Ok.` et un en-tête `Set-Cookie: SID=…`, la forme qu'utilise le vrai qBittorrent (wiki, *Login* : « En cas de succès, la réponse contiendra un cookie avec votre SID »).
- **Un corps vide est aussi accepté** (`:479` court-circuite sur `IsNotNullOrWhiteSpace`). Tout le reste (`"Fails."`, `"ok"`, du JSON) est un échec d'authentification. Le proxy v1 est plus strict et exige exactement `Ok.` (`QBittorrentProxyV1.cs:371`).
- En cas d'erreur HTTP sur `auth/login` : 401 ou 403 → `DownloadClientAuthenticationException` ; tout autre code → `DownloadClientException` (`:463-473`). Une `WebException` → `DownloadClientUnavailableException`.
- Le cookie est mis en cache par `{baseUrl}:{user}:{pass}` pour la durée de vie de l'entrée de cache du processus, et n'est rafraîchi que lorsqu'une requête revient avec un 403 (§0.5).
- **`Referer` et `Origin` ne sont jamais envoyés.** Le wiki demande aux consommateurs de l'API de les définir (« Note : définissez `Referer` ou `Origin` sur exactement le même domaine et port que ceux utilisés dans l'en-tête `Host` de la requête HTTP ») et Sonarr ne le fait pas. Un shim ne doit pas les exiger.
- Sans **aucun identifiant configuré**, `AuthenticateClient` retourne immédiatement et rien n'est envoyé : ni login, ni cookie, ni `Authorization`. Un shim sans authentification fonctionne.

### 0.5 Quels codes HTTP sont traités comme des erreurs {#05-which-http-statuses-are-treated-as-errors}

`HttpClient.Execute` (`src/NzbDrone.Common/Http/HttpClient.cs:106-121`) lève une exception lorsque
`response.HasHttpError` — `(int)StatusCode >= 400` (`src/NzbDrone.Common/Http/HttpResponse.cs:54`) —
sauf si `SuppressHttpError` est défini ou si le statut figure dans `SuppressHttpErrorStatusCodes`. Un 429 devient
`TooManyRequestsException` (`:115`) ; tout le reste devient `HttpException` (`:119`).

`QBittorrentProxyV2.ProcessRequest` (`:369-428`) encapsule ensuite cette exception. Il existe deux chemins distincts :

**Chemin par clé API** (`:371-395`) :

| Statut | Résultat |
|---|---|
| 401, 403 | `DownloadClientAuthenticationException("Failed to authenticate with qBittorrent.")` |
| tout autre `>= 400` | `DownloadClientException("Failed to connect to qBittorrent, check your settings.")` |
| toute autre exception levée | `DownloadClientException("Failed to connect to qBittorrent, please check your settings.")` |

**Chemin par cookie** (`:397-427`) :

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

- **Un 403 signifie « session expirée, reconnectez-vous »** : il est supprimé une fois, le client se reconnecte et relance la requête. C'est la boucle que produit l'expiration de session de qBittorrent lui-même, et un shim peut s'en servir de la même façon.
- La **requête de relance est reconstruite à partir du builder**, qui ne transporte pas `SuppressHttpErrorStatusCodes`. Ce champ était défini sur la *requête* à `:401`, pas sur le builder. Donc un second 403 lève `HttpException` et remonte sous la forme `DownloadClientException("Failed to connect to qBittorrent, check your settings.")`, **et non** comme un échec d'authentification. Un shim qui répond 403 en permanence produit donc une erreur de connexion déroutante, et non « Authentication Failure » dans l'interface.
- Sans identifiants configurés, la tentative de reconnexion à `:411` lève tout de suite `DownloadClientAuthenticationException` (`:434-437`).

**Chaque appel réussi doit renvoyer HTTP 200 avec le corps exact attendu par le client.** Cette API n'a aucune enveloppe d'erreur en JSON. Contrairement à SAB, ici les erreurs sont signalées par des statuts HTTP.

### 0.6 Réglages du désérialiseur {#06-deserializer-settings}

Toutes les charges utiles qBittorrent passent par `NzbDrone.Common.Serializer.Json` (`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`), **Newtonsoft**, la même instance que celle utilisée par le client SAB. Donc [sabnzbd-client-contract.md §0.3](sabnzbd-client-contract.md) s'applique tel quel :

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Ce que cela signifie pour les modèles qBittorrent en particulier :

| Membre du modèle | Liée à | Pourquoi |
|---|---|---|
| `QBittorrentTorrent.Hash/Name/Size/Progress/Eta/State/Label/Category/Ratio` | `hash`, `name`, `size`, `progress`, `eta`, `state`, `label`, `category`, `ratio` | résolveur en camelCase ; Newtonsoft fait aussi la correspondance sans tenir compte de la casse |
| `SavePath`, `ContentPath`, `RatioLimit`, `SeedingTime`, `SeedingTimeLimit`, `InactiveSeedingTimeLimit`, `LastActivity` | `save_path`, `content_path`, `ratio_limit`, `seeding_time`, `seeding_time_limit`, `inactive_seeding_time_limit`, `last_activity` | `[JsonProperty]` explicite (`QBittorrentTorrent.cs:24-45`) |
| `QBittorrentLabel.Name/SavePath` | `name`, `savePath` | **aucun** `[JsonProperty]` : résolveur en camelCase. Contrairement à tout le reste, `torrents/categories` de qBittorrent utilise bien le camelCase ici |
| `QBittorrentPreferences.*` | tous en snake_case via `[JsonProperty]` explicite (`QBittorrentPreferences.cs:16-44`) | |
| `QBittorrentMaxRatioAction` | `max_ratio_act` | pas de convertisseur propre à la propriété, donc le `StringEnumConverter` global s'applique. `AllowIntegerValues` vaut true par défaut, donc **envoie l'entier**, comme le fait le vrai qBittorrent. Une chaîne devrait être en camelCase (`"pause"`, `"remove"`) et un nom inconnu provoque une exception |

`NullValueHandling.Ignore` s'applique aussi à la **lecture** : un `null` en JSON laisse le membre à sa valeur du constructeur. Combiné aux valeurs par défaut déclarées dans les modèles, un champ **absent ou null** n'équivaut pas à zéro :

| Champ | Valeur par défaut si absent/null | Référence |
|---|---|---|
| `ratio_limit` | `-2f` | `QBittorrentTorrent.cs:33` |
| `seeding_time_limit` | `-2` | `:39` |
| `inactive_seeding_time_limit` | `-2` | `:42` |
| `seeding_time` | `null` (`long?`) | `:36` |
| `queueing_enabled` | **`true`** | `QBittorrentPreferences.cs:41` |
| tout le reste | valeur par défaut du CLR (`0`, `false`, `null`) | |

`Eta` est un `System.Numerics.BigInteger` (`QBittorrentTorrent.cs:17`, commentaire "QBit contains a bug exceeding ulong limits"). Le jeu de test de Sonarr vérifie que `18446744073709335000` peut être lu (Sonarr `QBittorrentFixture.cs:974-984`, Radarr `:973-982`).

`Json.Deserialize<T>` relance une `JsonReaderException` avec un message plus clair (`Json.cs:39-50`). Aucun des appels proxy de qBittorrent n'utilise `TryDeserialize`. Donc **un corps mal formé ou au mauvais format lève une exception depuis le proxy** et devient une exception non gérée à l'endroit de l'appel. Pour `GetItems()`, cela fait planter toute la boucle d'interrogation.

### 0.7 Toutes les conditions `version >=`, au même endroit {#07-every-version--gate-in-one-place}

`ProxyApiVersion` vaut `_proxySelector.GetApiVersion(Settings)` (`QBittorrent.cs:50`), c'est-à-dire la valeur en cache de `app/webapiVersion`. Les seuils :

| Gate | Emplacement | Effet sous le seuil |
|---|---|---|
| `>= 1.5` | `QBittorrent.cs:436` | Le test échoue : "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| `>= 1.6` | `:445` | Le test échoue si une catégorie est configurée : "Category is not supported" |
| `>= 2.0` | `:379` (`GetStatus`), `:520` (`TestCategory`) | le `savePath` de la catégorie n'est pas lu, et les catégories ne sont ni vérifiées ni créées |
| `>= 2.6.1` | `:314` | `OutputPath` n'est **pas** pris depuis `content_path` ; `GetImportItem` parcourt `torrents/files` à la place (§4.2) |
| `>= 2.8.1` | `:79`, `:136` | les limites de partage ne peuvent pas passer par `torrents/add` ; elles sont appliquées ensuite avec `torrents/setShareLimits` |
| `>= 2.11.0` | `QBittorrentProxyV2.cs:253` | `torrents/add` envoie `paused=` au lieu de `stopped=` |

`Version.Parse` (`QBittorrentProxyV2.cs:75`) a besoin d'au moins `major.minor` : un simple `"2"` lève une `FormatException`, et cette exception est levée en dehors de tous les `try` du proxy, donc elle sort de `GetApiVersion` sans être attrapée. Renvoyez quelque chose comme `2.11.2`.

**Valeur recommandée pour un shim : `2.11.2`.** Elle passe tous les seuils, met `content_path` sur le chemin `torrents/info` (la seule route d'import correcte), et sélectionne la syntaxe `stopped=` de qBittorrent 5.x pour l'ajout.

## 1. Chaque endpoint, dans l'ordre où le client les appelle {#1-every-endpoint-in-the-order-the-client-calls-them}

Interface : `IQBittorrentProxy` (`QBittorrentProxySelector.cs:9-30`). Implémentation : `QBittorrentProxyV2`. Chaque appel dans `QBittorrent.cs` est listé à `:49-741`.

### 1.1 `GET /api/v2/app/webapiVersion` — `GetApiVersion` (`QBittorrentProxyV2.cs:72-78`)

Requête : aucun paramètre. Envoyée d'abord sans authentification (la sonde de proxy, §0.1), puis avec authentification.

Réponse : **texte brut**, une chaîne de version analysée par `Version.Parse`. Ni JSON, ni guillemets.

Appelée par : la sonde de proxy (`:31`), `GetItems` (`QBittorrent.cs:220`), `GetStatus` (`:374`),
`TestConnection` (`:435`), `TestCategory` (`:519`), et — celle qu'on oublie facilement —
`AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:253`), ce qui veut dire que **chaque `torrents/add` est précédé de son propre aller-retour `app/webapiVersion`** dès que l'état initial est Start ou Stop (c'est-à-dire toujours, sauf si l'utilisateur a choisi Force Start).

### 1.2 `GET /api/v2/app/version` — `GetVersion` (`QBittorrentProxyV2.cs:80-87`)

Réponse : texte brut, le `v` retiré au début (`:83`). Commentaire : `// eg "4.2alpha"`.

**Jamais appelée.** Elle figure dans l'interface (`QBittorrentProxySelector.cs:13`) sans aucun appel nulle part dans
`QBittorrent.cs` (vérifié sur chaque référence `Proxy.`/`_proxySelector.`, `:49-741`). Implémente-la
quand même : ça ne coûte rien, et quelqu'un qui bidouille le shim finira par en avoir besoin.

### 1.3 `POST /api/v2/auth/login`

Couvert au §0.4. Formulaire : `username`, `password`. Réponse `200` + `Ok.` + `Set-Cookie: SID=…`.

### 1.4 `GET /api/v2/app/preferences` — `GetConfig` (`QBittorrentProxyV2.cs:89-95`)

Requête : aucun paramètre. Réponse : un objet JSON, désérialisé dans `QBittorrentPreferences`.

**Chaque clé que le client lit** (`QBittorrentPreferences.cs:14-45`). Le reste du corps n'est pas lu, et les clés en trop sont ignorées :

| Clé JSON | C# | Type | Lu par |
|---|---|---|---|
| `save_path` | `SavePath` | `string` | `GetStatus` → `OutputRootFolders` (`QBittorrent.cs:377`) |
| `max_ratio_enabled` | `MaxRatioEnabled` | `bool` | `HasReachedSeedLimit` (`:639`), `RemovesCompletedDownloads` (`:415`) |
| `max_ratio` | `MaxRatio` | `float` | `HasReachedSeedLimit` (`:641`) |
| `max_seeding_time_enabled` | `MaxSeedingTimeEnabled` | `bool` | `HasReachedSeedingTimeLimit` (`:663`), `RemovesCompletedDownloads` (`:415`) |
| `max_seeding_time` | `MaxSeedingTime` | `long`, **minutes** | `:665`, `:415` |
| `max_inactive_seeding_time_enabled` | `MaxInactiveSeedingTimeEnabled` | `bool` | `HasReachedInactiveSeedingTimeLimit` (`:727`) |
| `max_inactive_seeding_time` | `MaxInactiveSeedingTime` | `long`, **minutes** | `:729` |
| `max_ratio_act` | `MaxRatioAction` | enum sous forme d'entier : `Pause=0, Remove=1, EnableSuperSeeding=2, DeleteFiles=3` (`QBittorrentPreferences.cs:5-11`) | `RemovesCompletedDownloads` (`:415`) |
| `queueing_enabled` | `QueueingEnabled` | `bool`, **valeur par défaut `true`** | `TestPrioritySupport` (`:572`) |
| `dht` | `DhtEnabled` | `bool` | `AddFromMagnetLink` (`:73`), la branche `metaDL` (`:288`) |

Appelé par : `AddFromMagnetLink` (`:73`), `GetItems` (`:221`), `GetStatus` (`:375`), `TestConnection` (`:467`), `TestPrioritySupport` (`:570`). Ce n'est **pas** mis en cache, donc il est récupéré à chaque interrogation.

`RemovesCompletedDownloads` (`QBittorrent.cs:412-416`) est le drapeau dérivé :

```csharp
var minimumRetention = 60 * 24 * 14; // 14 days in minutes
return (config.MaxRatioEnabled || (config.MaxSeedingTimeEnabled && config.MaxSeedingTime < minimumRetention))
    && (config.MaxRatioAction == QBittorrentMaxRatioAction.Remove || config.MaxRatioAction == QBittorrentMaxRatioAction.DeleteFiles);
```

Il alimente à la fois le test de connexion (`:468`) et le contrôle de santé `DownloadClientRemovesCompletedDownloadsCheck` (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:44-53`). Avec `max_ratio_enabled: false` et `max_seeding_time_enabled: false`, il vaut false quelle que soit la valeur de `max_ratio_act`, mais envoie quand même `max_ratio_act: 0`.

### 1.5 `GET /api/v2/torrents/categories` — `GetLabels` (`QBittorrentProxyV2.cs:221-225`)

Requête : aucun paramètre.

Réponse : un **objet** JSON, `{"<name>": {"name": "...", "savePath": "..."}}`, désérialisé dans
`Dictionary<string, QBittorrentLabel>`. Attention, **`savePath` en camelCase**, voir §0.6 et l'exemple *Get all categories* du wiki. Un tableau provoque une erreur ici.

Lisez attentivement deux points :

1. `TestCategory` (`QBittorrent.cs:525-553`) : seule la présence de la clé compte (§6.3).
2. `GetStatus` (`:379-402`) : le `savePath` de la catégorie configurée devient le dossier racine de sortie du client de téléchargement :

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

Un `savePath` **relatif** est ajouté au `save_path` global ; un chemin absolu le remplace. Un `savePath` qui commence par `//` est transformé en chemin UNC avec antislashs. Le fixture de Sonarr fixe `"//server/store/downloads"` → `\\server\store\downloads` (Sonarr `QBittorrentFixture.cs:563-589`, Radarr `:562-588`). **Ne produisez jamais de `//` en début de valeur.**
La réponse la plus simple et correcte est `"savePath": ""`, qui laisse le dossier racine sur le `save_path` global.

(Une traduction précédente a été rejetée : les blocs de code ne correspondaient pas. Gardez la structure exactement telle quelle.)

### 1.6 `POST /api/v2/torrents/createCategory` — `AddLabel` (`QBittorrentProxyV2.cs:213-219`)

Forme : `category=<name>`. **`savePath` n'est pas envoyé** : le client ne définit jamais de chemin de sauvegarde pour la catégorie.
Le corps de la réponse est ignoré ; seul un statut sans erreur compte.

Appelé uniquement depuis `TestCategory` (`QBittorrent.cs:529`, `:543`), quand la catégorie est absente.
`torrents/editCategory` et `torrents/removeCategories` ne sont **jamais appelés**.

### 1.7 `POST /api/v2/torrents/add` — `AddTorrentFromUrl` / `AddTorrentFromFile`

`AddTorrentFromUrl` (`QBittorrentProxyV2.cs:146-166`) : champ de formulaire **`urls`** = l'URI magnet.
`AddTorrentFromFile` (`:168-188`) : upload de formulaire **`torrents`**, nom de fichier
`{CleanFileName(release title)}.torrent` (`TorrentClientBase.cs:199`),
`Content-Type: application/octet-stream` (`HttpRequestBuilder.cs:379`).

Les deux ajoutent ensuite `AddTorrentDownloadFormParameters` (`QBittorrentProxyV2.cs:243-284`) :

| Champ de formulaire | Valeur | Condition | Ligne |
|---|---|---|---|
| `category` | `Settings.TvCategory` / `MovieCategory` | category non vide | `:245-248` |
| `stopped` (webapi `>= 2.11.0`) ou `paused` (en dessous) | `False` pour Start, `True` pour Stop | `InitialState` est Start ou Stop — **Force Start n'envoie aucun des deux** | `:251-264` |
| `sequentialDownload` | `True` | paramètre `SequentialOrder` activé | `:266-269` |
| `firstLastPiecePrio` | `True` | paramètre `FirstAndLast` activé | `:271-274` |
| `contentLayout` | `"Original"` ou `"Subfolder"` | paramètre `ContentLayout` sur Original ou Subfolder ; **Default n'envoie rien** | `:276-283` |

et, quand des share limits sont configurées *et* webapi `>= 2.8.1` (`QBittorrent.cs:79`, `:136`),
`AddTorrentSeedingFormParameters(request, seedConfiguration)` (`QBittorrentProxyV2.cs:227-241`) :

| Champ de formulaire | Valeur | Condition |
|---|---|---|
| `ratioLimit` | `seedConfiguration.Ratio` ou `-2` | seulement si ce n'est pas `-2` (`:232`) |
| `seedingTimeLimit` | `seedConfiguration.SeedTime.TotalMinutes` ou `-2` | seulement si ce n'est pas `-2` (`:237`) |

**Tout le reste que le wiki documente pour `torrents/add` n'est jamais envoyé** : ni `savepath`, ni `cookie`,
ni `tags`, ni `skip_checking`, ni `root_folder`, ni `rename`, ni `upLimit`, ni `dlLimit`, ni
`autoTMM`. Il n'existe pas de paramètre `priority` à l'ajout : la priorité dans la file est un appel séparé, `topPrio` (§1.10).

Gestion de la réponse (`:159-165`, `:181-187`) :

```csharp
var result = ProcessRequest(request, settings);
// Note: Older qbit versions returned nothing, so we can't do != "Ok." here.
if (result == "Fails.") { throw new DownloadClientException("Download client failed to add torrent by url"); }
```

Donc : **une réponse 200 avec n'importe quel corps, sauf le texte exact `Fails.`, est un succès.** `Ok.` est la réponse habituelle.
Un HTTP 415 (« torrent file is not valid » dans le wiki) devient une `DownloadClientException` via `:389`.

**L'id du téléchargement ne vient pas de cet appel.** Il est calculé côté client, avant la requête :

- magnet → `MagnetLink.Parse(magnetUrl).InfoHash.ToHex()` (`TorrentClientBase.cs:224`)
- `.torrent` → `_torrentFileInfoReader.GetHashFromTorrentFile(torrentFile)` (`:200`)

Et `AddFromMagnetLink` / `AddFromTorrentFile` renvoient ce même `hash`, sans le modifier
(`QBittorrent.cs:130`, `:187`). **Le shim doit indexer le torrent sur exactement cet infohash**, sinon Sonarr perd la trace de la capture. `TorrentClientBase.cs:206-212` et `:238-244` ne font que consigner une ligne de log Debug à ce sujet. Pour les magnets, la précondition DHT est vérifiée en premier :

```csharp
if (!Proxy.GetConfig(Settings).DhtEnabled && !magnetLink.Contains("&tr="))
    throw new NotSupportedException("Magnet Links without trackers not supported if DHT is disabled");   // :73-76
```

que l'appelant transforme en `ReleaseDownloadException("Magnet not supported by download client…")` quand il n'existe pas de solution de repli `.torrent` (`TorrentClientBase.cs:111-119`). **Indique `dht: true`.**

Après l'ajout, `WaitForTorrent` (`QBittorrent.cs:190-214`) interroge `IsTorrentLoaded` **10 fois avec une pause de 100 ms**, mais seulement s'il reste un travail à faire (share limits après l'ajout, top priority ou force start ; `:86`, `:143`). Son message d'échec parle de « within 500 ms », alors que la boucle fait en réalité 10 × 100 ms. Dans les deux cas, il abandonne et renvoie le hash (`:212-213`).

### 1.7a Combien de temps le client attend `torrents/add` — **100 secondes**, mesuré le 2026-08-30 {#17a-how-long-the-client-waits-for-torrentsadd--100-seconds-measured-2026-08-30}

Relevé dans `Sonarr/Sonarr@32a5d492` et `Radarr/Radarr@40bb746c` (les deux sur `develop`) le 2026-08-30. Cela fixe la limite de tout ce qu'un shim fait de façon synchrone dans l'appel d'ajout, donc il vaut la peine de le citer plutôt que de le supposer.

Rien sur le chemin qBittorrent ne définit de timeout : la valeur traverse donc quatre couches jusqu'à une limite fixe de 100 s :

| Étape | Sonarr `path:line` | Radarr `path:line` | Ce qu'elle fait |
|---|---|---|---|
| l'appel d'ajout | `QBittorrentProxyV2.cs:146-150`, `:168-172` | `:145-149`, `:167-171` | construit la requête, ne définit aucun timeout |
| le builder | `NzbDrone.Common/Http/HttpRequestBuilder.cs:104-116` | même fichier `:104-116` | `Apply()` n'a pas de ligne `RequestTimeout`, et la classe n'a pas de propriété de ce nom |
| la valeur par défaut du champ | `NzbDrone.Common/Http/HttpRequest.cs:52` | `:54` | auto-property jamais assignée dans le constructeur, donc `TimeSpan.Zero` |
| le dispatcher | `NzbDrone.Common/Http/Dispatchers/ManagedHttpDispatcher.cs:70-79` | `:68-77` | `Zero` devient `cts.CancelAfter(TimeSpan.FromSeconds(100))` |

```csharp
using var cts = new CancellationTokenSource();
if (request.RequestTimeout != TimeSpan.Zero) { cts.CancelAfter(request.RequestTimeout); }
else { /* The default for System.Net.Http.HttpClient */ cts.CancelAfter(TimeSpan.FromSeconds(100)); }
```

`RequestTimeout` et `Timeout` n'apparaissent nulle part sous `src/NzbDrone.Core/Download/Clients/QBittorrent/` dans aucun des deux dépôts, et `HttpRequestBuilder` n'expose aucun moyen d'en définir un ; un shim ne peut donc pas obtenir plus de temps par configuration.

Cinq choses en découlent.

- **Les 100 s viennent du jeton d'annulation de Sonarr, pas du timer de .NET.** Le handler sous-jacent est construit avec `Timeout = Timeout.InfiniteTimeSpan` (`ManagedHttpDispatcher.cs:183` pour Sonarr, `:180` pour Radarr), donc le jeton est la seule limite. Il est passé à la fois à `SendAsync` et à `ReadAsByteArrayAsync` (`:115`, `:127`), ce qui signifie qu'il couvre la connexion, le corps de la requête, les en-têtes de réponse et le corps de la réponse.
- **Un timeout est présenté à l'utilisateur comme une erreur de connexion.** À expiration, il lève `new WebException("Http request timed out", …)` (`:142-145`), que `ProcessRequest` enveloppe dans `DownloadClientException("Failed to connect to qBittorrent, please check your settings.", ex)` (`QBittorrentProxyV2.cs:424-427`). Un shim qui bloque plus de 100 s a donc l'air mal configuré plutôt que lent, et le *arr ne apprend jamais que l'ajout était encore en cours.
- **Il n'y a ni timeout de connexion séparé ni budget plus large pour un envoi multipart.** `SocketsHttpHandler.ConnectTimeout` n'est jamais défini. La seule exception est un plafond de 2 s sur la première tentative IPv6 de la durée de vie du processus (`ManagedHttpDispatcher.cs:23`, `:288-295`), qui bascule ensuite sur IPv4 dans les mêmes 100 s. Un envoi de `.torrent` est mis en mémoire tampon en entier dans un tableau d'octets (`HttpRequestBuilder.cs:220-221`, `ManagedHttpDispatcher.cs:103`) et envoyé avec le même jeton.
- **Les 300 s existent, mais sur un autre chemin.** `HttpClient.cs:285` définit `request.RequestTimeout = TimeSpan.FromSeconds(300)` dans `DownloadFileAsync`, qui récupère le `.torrent` auprès de l'indexeur. Cela n'atteint jamais un appel au client de téléchargement.
- **Deluge prouve que la surcharge existe, et qBittorrent ne la met pas en place.** `DelugeProxy.cs:222` fait `requestBuilder.PostProcess += r => r.RequestTimeout = TimeSpan.FromSeconds(15)`. `BuildRequest` de qBittorrent n'a pas cette ligne, ce qui est la preuve directe que les 100 s sont hérités et non choisis.

**Radarr est identique.** Une comparaison du bloc de timeout (Radarr `:68-78` contre Sonarr `:70-80`) donne un résultat strictement identique, et la seule différence dans la chaîne est que Radarr passe `ex` là où Sonarr passe `ex.InnerException` dans le `WebException`.

**Conséquence pour le shim.** Chaque décision synchrone prise dans `torrents/add` partage un seul budget de 100 s, et le *arr n'a aucun moyen de distinguer « encore en train de travailler » de « injoignable ». Le délai par tentative multiplié par le nombre de fournisseurs essayés, plus toute fenêtre de sonde en cache seulement, doit rester bien en dessous. Les latences mesurées des fournisseurs sur lesquelles ce budget est construit se trouvent dans [torrent-lifecycle.md](torrent-lifecycle.md).

Une dernière note, pour être complet. Les 100 s s'appliquent par appel au dispatcher, donc chaque saut d'une chaîne de redirections automatiques reçoit un budget neuf (`HttpClient.cs:43` limite la chaîne à 5). La stratégie de réessai à `DownloadClientBase.cs:30-44` ne s'applique **pas** ici ; elle n'est utilisée que pour récupérer le `.torrent` auprès de l'indexeur (`TorrentClientBase.cs:142-144`).

### 1.8 `GET /api/v2/torrents/properties?hash=<hash>` — `IsTorrentLoaded` / `GetTorrentProperties`

`IsTorrentLoaded` (`QBittorrentProxyV2.cs:110-126`) l'appelle avec `LogHttpError = false` et considère **toute** exception comme « pas chargé ».

`GetTorrentProperties` (`:128-135`) désérialise dans `QBittorrentTorrentProperties` (`QBittorrentTorrent.cs:48-57`) — **trois champs, dont seuls deux sont utilisés** :

| Clé JSON | C# | Utilisé pour |
|---|---|---|
| `hash` | `Hash` | lu, jamais utilisé |
| `save_path` | `SavePath` | chemin de `GetImportItem` avant la 2.6.1 (`QBittorrent.cs:354`) |
| `seeding_time` | `SeedingTime` (`long`, **en secondes**) | `FetchTorrentDetails` (`:739-744`) |

**La casse des hashes est incohérente ici, et ça compte.** Tous les autres appels passent le hash en minuscules (`item.DownloadId.ToLower()` aux lignes `:335`, `:346`, `:353` ; `hash.ToLower()` aux lignes `:97`, `:109`, `:121`, `:198`), mais `FetchTorrentDetails` transmet `torrent.Hash` **tel quel** (`:741`), c'est-à-dire ce que le shim a mis dans `torrents/info`. Le vrai qBittorrent renvoie des hashes en minuscules, donc ça ne pose jamais problème avec lui. Le fixture de Sonarr fige cette asymétrie : il simule `GetTorrentProperties("HASH", …)` avec la valeur en majuscules (Sonarr `QBittorrentFixture.cs:669-675`, Radarr `:668-674`). **Renvoie donc des hashes en minuscules depuis `torrents/info`, et fais correspondre `?hash=` sans tenir compte de la casse.**

`FetchTorrentDetails` n'est appelé que depuis `HasReachedSeedingTimeLimit` (`:700`), qui n'est atteint que lorsqu'une limite de temps de seeding est réellement appliquée. Donc un shim qui ne déclare aucune limite de temps de seeding ne voit jamais cet appel pendant le polling. Il reste néanmoins nécessaire pour `IsTorrentLoaded`, la sonde de disponibilité après l'ajout : **404 pour un hash inconnu, 200 + JSON pour un hash connu.**

Le résultat est mis en cache pendant 5 minutes par `{Host}{Port}{Hash}` (`:678`, `:689`, `:695`, `:708`), et le fixture vérifie qu'il n'est récupéré qu'une fois, et non deux, sur deux polls (Sonarr `QBittorrentFixture.cs:905-920`, Radarr `:904-919`).

### 1.9 `POST /api/v2/torrents/setShareLimits` — `SetTorrentSeedingConfiguration` (`:286-308`)

Forme : `hashes=<lowercase hash>`, puis `AddTorrentSeedingFormParameters(request, seedConfiguration, always: true)`
— avec `always: true`, **`ratioLimit` et `seedingTimeLimit` sont toujours envoyés**, même lorsqu'ils valent `-2` (`:232`, `:237`). `inactiveSeedingTimeLimit` n'est jamais envoyé.

Une **404** est avalée (`:298-307`, commentaire : « setShareLimits a été ajouté dans l'api v2.0.1 »). Toute autre erreur est propagée, mais l'appel intercepte l'erreur et journalise un avertissement (`QBittorrent.cs:95-102`, `:152-159`).

Cette route n'est atteinte que si l'indexeur fournit une configuration de seed *et* que webapi est `< 2.8.1`. Sur un shim qui annonce `2.11.2`, les limites de partage passent plutôt par `torrents/add` et cette route n'est jamais utilisée pour un grab. Implémentez-la comme un no-op qui renvoie 200.

### 1.10 `POST /api/v2/torrents/topPrio` — `MoveTorrentToTopInQueue` (`:310-330`)

Format : `hashes=<lowercase hash>`.

Un **409 Conflict** est avalé (`:320-329`, commentaire : « qBittorrent rejects all Prio commands with 409:
Conflict if Options -> BitTorrent -> Torrent Queueing is not enabled »). Le proxy v1 avale un **403**
à la place (`QBittorrentProxyV1.cs:255-264`). Toute autre erreur est interceptée et journalisée en avertissement
au niveau de l'appel (`QBittorrent.cs:107-114`, `:164-171`). Le fixture vérifie qu'un échec ici ne fait pas échouer le grab
(Sonarr `QBittorrentFixture.cs:525-542`, Radarr `:524-541`).

Cela n'est appelé que lorsque le paramètre de priorité Recent/Older est sur `First` (`QBittorrentPriority.First = 1`,
`QBittorrentPriority.cs:5-6`). La valeur par défaut est `Last = 0`.

### 1.11 `POST /api/v2/torrents/setForceStart` — `SetForceStart` (`:332-339`)

Forme : `hashes=<lowercase hash>`, `value=true` (la chaîne minuscule littérale, `:337`).

Appelé uniquement quand `InitialState` vaut `ForceStart` (`QBittorrentState.cs:10-11`, `QBittorrent.cs:82`, `:117-127`). Les erreurs sont interceptées et loguées en avertissement (`:123-126`).

### 1.12 `GET /api/v2/torrents/info[?category=<cat>]` — `GetTorrents` (`:97-108`)

Le seul paramètre envoyé est `category`, et seulement quand le réglage n'est pas vide
(`:100-103`). Pas de `filter`, pas de `hashes`, pas de `sort`, pas de `reverse`, pas de `limit`, pas de `offset`, pas de `tag`.
Le client ne filtre **pas** à nouveau par catégorie ensuite, contrairement au client SAB, qui filtre deux fois. Donc un shim qui ignore `category` donnera à Radarr les torrents de Sonarr.

Le champ `category` de la réponse compte pour une deuxième raison : un torrent pour lequel le \*arr n'a **aucun historique de capture** est ignoré d'office, sauf s'il en porte une —
`CompletedDownloadService.Check` (`CompletedDownloadService.cs:84-88`) :

```csharp
if (historyItem == null && trackedDownload.DownloadItem.Category.IsNullOrWhiteSpace())
{
    trackedDownload.Warn("Download wasn't grabbed by Sonarr and not in a category, Skipping.");
    return;
}
```

`Category` vaut `category` s'il n'est pas vide, sinon `label` (`QBittorrent.cs:231`).

Réponse : un **tableau** JSON. Chaque champ utilisé, et ce qu'il devient :

| Clé JSON | Type C# | Unités | Devient |
|---|---|---|---|
| `hash` | `string` | | `DownloadId = torrent.Hash.ToUpper()` (`QBittorrent.cs:230`) — **mis en majuscules**, et renvoyé en minuscules à chaque appel suivant |
| `name` | `string` | | `Title = torrent.Name` (`:232`) — voir §7.1 pour tout ce qu'il pilote |
| `size` | `long` | octets | `TotalSize` (`:233`) ; aussi `RemainingSize = (long)(size * (1.0 - progress))` (`:235`) |
| `progress` | `double` | 0..1 | `RemainingSize` (`:235`) |
| `eta` | `BigInteger` | secondes | `RemainingTime` via `GetRemainingTime` (`:236`, `:614-628`) |
| `state` | `string` | | `Status`, `Message`, et la moitié de la condition `CanMoveFiles` (`:242-312`) — §2 |
| `category` | `string` | | `Category`, en priorité (`:231`) |
| `label` | `string` | | `Category`, de secours quand `category` est vide (`:231`). Champ d'avant la 3.3.5 ; qBittorrent 5 ne l'émet plus |
| `ratio` | `float` | | `SeedRatio` (`:237`), `HasReachedSeedLimit` (`:634`, `:641`) |
| `ratio_limit` | `float`, par défaut `-2` | | `HasReachedSeedLimit` (`:632-645`) |
| `seeding_time_limit` | `long`, par défaut `-2` | **minutes** | `HasReachedSeedingTimeLimit` (`:659-670`) |
| `inactive_seeding_time_limit` | `long`, par défaut `-2` | **minutes** | `HasReachedInactiveSeedingTimeLimit` (`:723-736`) |
| `last_activity` | `long` | **secondes unix** | `HasReachedInactiveSeedingTimeLimit` (`:736`) |
| `seeding_time` | `long?`, par défaut null | secondes | `HasReachedSeedingTimeLimit` (`:672-676`) — le commentaire à `QBittorrentTorrent.cs:36` dit qu'il est « pas fourni par la list api », mais le client s'en sert s'il est présent, ce qui évite un aller-retour `torrents/properties` |
| `save_path` | `string` | | comparé à `content_path` (`:316`) |
| `content_path` | `string` | | `OutputPath` sur webapi `>= 2.6.1` (`:318`) — §4 |

`GetRemainingTime` (`:614-628`) :

```csharp
if (torrent.Eta < 0 || torrent.Eta > 365 * 24 * 3600) { return null; }   // > 31,536,000 s
if (torrent.Eta == 8640000) { return null; }                            // qBittorrent's "unknown"
return TimeSpan.FromSeconds((int)torrent.Eta);
```

et un élément Completed voit ensuite son `RemainingTime` forcé à `TimeSpan.Zero` (`:273`).

`torrents/info` est récupéré à chaque `RefreshMonitoredDownloads`
(`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:94`), ce qui est aussi temporisé (debounce) dans la file de commandes 5 s après les événements pertinents (`:53`).

### 1.13 `GET /api/v2/torrents/files?hash=<hash>` — `GetTorrentFiles` (`:137-144`)

Réponse : un tableau JSON désérialisé dans `List<QBittorrentTorrentFile>`, qui ne contient **qu'un seul
membre** : `Name` (`QBittorrentTorrent.cs:59-62`), lié à `name`. C'est le chemin du fichier **relatif au
chemin de sauvegarde**, avec des séparateurs `/` sur tous les systèmes (« QBittorrent renvoie des séparateurs `/` même sous windows », `QBittorrent.cs:358`).

Appelé uniquement depuis `GetImportItem` (`:346`), et seulement quand `OutputPath` est toujours vide. Cela arrive sur webapi `< 2.6.1`, ou quand `content_path` est revenu vide. `index`, `size`, `progress`, `priority`, `is_seed`, `piece_range` et `availability` sont tous ignorés.

Un **tableau vide** est géré : `_logger.Debug("No files found for torrent {0} in qBittorrent")` est appelé et l'élément est renvoyé sans changement (`:347-351`). Il échoue ensuite à `ValidatePath`.

### 1.14 `POST /api/v2/torrents/setCategory` — `SetTorrentLabel` (`:204-211`)

Forme : `hashes=<lowercase hash>`, `category=<post-import category>`.

Appelée uniquement depuis `MarkItemAsImported` (`QBittorrent.cs:52-69`), et seulement quand le paramètre facultatif
`TvImportedCategory` / `MovieImportedCategory` n'est pas vide et est différent de la catégorie principale. Une `DownloadClientException` est interceptée et un avertissement est affiché :
"Failed to set post-import torrent label \"{0}\" for {1} in qBittorrent. Does the label exist?"
(`:62-67`). §5.1.

### 1.15 `POST /api/v2/torrents/delete` — `RemoveTorrent` (`:190-202`)

Forme : `hashes=<lowercase hash>`, plus `deleteFiles=true` **uniquement quand `removeData` vaut true**
(`:196-199`) — la chaîne littérale en minuscules, et non `Convert.ToString(bool)`.

`QBittorrent.RemoveItem` (`:333-336`) est l'implémentation complète :

```csharp
public override void RemoveItem(DownloadClientItem item, bool deleteData)
{
    Proxy.RemoveTorrent(item.DownloadId.ToLower(), deleteData, Settings);
}
```

**Il n'appelle pas `DeleteItemData`.** C'est la différence avec le client SAB, qui supprime lui-même le dossier du job via le système de fichiers
(`src/NzbDrone.Core/Download/DownloadClientBase.cs:110-146` ; voir [sabnzbd-client-contract.md §5.3](sabnzbd-client-contract.md)). Ici, la suppression des données relève entièrement du client de téléchargement. §5.

### 1.16 Endpoints que le client ne touche jamais {#116-endpoints-the-client-never-touches}

Absents de l'interface, donc jamais appelés : `torrents/pause`, `torrents/resume`, `torrents/stop`,
`torrents/start`, `torrents/setLocation`, `torrents/rename`, `torrents/recheck`,
`torrents/reannounce`, `torrents/filePrio`, `torrents/setDownloadLimit`, `torrents/setUploadLimit`,
`torrents/toggleSequentialDownload`, `torrents/setAutoManagement`, `torrents/editCategory`,
`torrents/removeCategories`, les tags, le RSS, la recherche, `app/setPreferences`, `app/defaultSavePath`,
`app/shutdown`, `sync/maindata`, `transfer/*`, `auth/logout`. La pause et la reprise n'existent que sous forme du champ de formulaire `paused=`/`stopped=` sur `torrents/add`.

Présents dans l'interface mais jamais appelés depuis `QBittorrent.cs` : `GetVersion` (§1.2).

### 1.17 La table de routes v1 (pour être complet ; à ne pas implémenter) {#117-the-v1-route-map-for-completeness-do-not-implement}

`QBittorrentProxyV1.cs` : `/version/api` (`:30`, `:64` — le client ajoute `"1."` devant tout ce qui
est renvoyé, `:65`), `/version/qbittorrent` (`:73`), `/query/preferences` (`:81`),
`/query/torrents?label=&category=` (`:89-94` — **les deux** paramètres), `/query/propertiesGeneral/{hash}`
(`:103`, `:120`), `/query/propertiesFiles/{hash}` (`:128`), `/command/download` (`:136`),
`/command/upload` (`:166`), `/command/delete` ou `/command/deletePerm` (`:196` — la distinction delete/deleteFiles
correspond à deux routes différentes, et non à un paramètre), `/command/setCategory` avec un
repli sur `/command/setLabel` en cas de 404 (`:205-225`), `/command/addCategory` (`:230`),
`/command/topPrio` (`:248`), `/command/setForceStart` (`:269`), `/login` (`:345`).

## 2. `state` → `DownloadItemStatus`

`QBittorrent.GetItems` (`:247-312`). Les états sont les chaînes propres à qBittorrent, produites par `torrentStateToString` (`qBittorrent/src/webui/api/serialize/serialize_torrent.cpp:44-87`).

| `state` | `DownloadItemStatus` | `Message` | Ligne |
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
| `metaDL` | Queued **si `dht: true`**, sinon Warning | "qBittorrent is downloading metadata" / "qBittorrent cannot resolve magnet link with DHT disabled" | `:286-299` |
| `forcedMetaDL` | identique à `metaDL` | identique | `:287` |
| `forcedDL` | Downloading | — | `:301` |
| `moving` | Downloading | — | `:302` |
| `downloading` | Downloading | — | `:303` |
| **tout autre** | **Downloading** | "Unknown download state: {state}" | `:307-311` |

Remarques sur lesquelles un shim doit agir :

- **Un état inconnu ne lève pas d'exception.** Il journalise `_logger.Info($"Unknown download state: {torrent.State}")` et retombe sur Downloading (`:307-311`). C'est l'inverse du client SAB, où un nom de statut inconnu lève une exception dans le désérialiseur et fait planter tout le poll. Malgré tout, n'envoyez que des noms présents dans ce tableau.
- **Les états Completed sont les seuls qui peuvent être importés.** `CompletedDownloadService.Check` retourne immédiatement sauf si `Status == Completed` (`src/NzbDrone.Core/Download/CompletedDownloadService.cs:68-71`).
- **Chaque état Completed remet `RemainingTime` à zéro** (`:273`, commentaire "qBittorrent sends eta=8640000 for completed torrents").
- `metaDL` / `forcedMetaDL` correspond à la phase « magnet, pas encore de métadonnées ». Le client n'a **aucun délai d'expiration** : l'état reste Queued tant que le shim continue d'envoyer `metaDL`, et il ne passe jamais en échec tout seul. Seul `dht: false` dans `app/preferences` (`:288`) le transforme en Warning. La gestion des téléchargements échoués de Sonarr se base sur l'ancienneté du grab, pas sur cet état.
- `stalledDL` est l'*avertissement* que voit l'utilisateur pour un torrent qui ne bouge pas. Un shim sans notion de pairs ne devrait jamais l'utiliser : un Warning sur un téléchargement suivi apparaît dans la file comme un problème, et c'est précisément ce que `FailedDownloadService` inspecte.
- `error` et `missingFiles` sont des Warnings volontairement, "so failed download handling isn't triggered" (`:249`). Si un shim veut que Sonarr mette en liste noire le release et relance la recherche, un Warning n'est **pas** le bon moyen de le demander.

## 3. Déplacer ou copier — la condition exacte, et la marche à suivre {#3-move-vs-copy--the-exact-condition-and-the-recipe}

### 3.1 La condition d'entrée {#31-the-gate}

`QBittorrent.cs:240-245`, verbatim, y compris le commentaire qui l'explique :

```csharp
// Avoid removing torrents that haven't reached the global max ratio.
// Removal also requires the torrent to be paused, in case a higher max ratio was set on the torrent itself (which is not exposed by the api).
item.CanMoveFiles = item.CanBeRemoved =
    item.DownloadClientInfo.RemoveCompletedDownloads &&
    torrent.State is "pausedUP" or "stoppedUP" &&
    HasReachedSeedLimit(torrent, config);
```

Trois conditions, toutes obligatoires :

1. **`RemoveCompletedDownloads`** : le paramètre propre à chaque client côté *arr, qui n'a rien à voir avec ce que qBittorrent renvoie.
   `DownloadClientDefinition.RemoveCompletedDownloads` vaut **`true`** par défaut
   (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17`), affiché dans l'interface sous
   le nom « Remove Completed ». Si l'utilisateur le désactive, **les imports deviennent des copies** et aucun shim n'y peut rien. (Un Move devient une copie pour une deuxième raison, que le shim ne voit pas non plus : le conteneur du \*arr accède au dossier de téléchargement et au dossier racine via deux volumes, où `rename()` répond `EXDEV` et où `File.Move` de .NET copie puis supprime. zurg lit ces deux éléments depuis l'API d'une source d'acquisition et adopte ensuite la copie ; voir `internal/arrlayout` et `internal/handlers/magic_copies.go`.)
2. **`state` vaut exactement `pausedUP` ou `stoppedUP`.** `uploading`, `stalledUP`, `queuedUP` et `forcedUP` sont Completed mais non déplaçables : la fixture le vérifie (Sonarr `QBittorrentFixture.cs:680-689`, Radarr `:679-688`).
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

- Un **`ratio_limit >= 0` par torrent** l'emporte directement et le global n'est pas consulté. `ratio_limit`
  vaut `-2` pour « utiliser le global » et `-1` pour « illimité » dans le modèle propre à qBittorrent
  (`QBittorrentTorrent.cs:32` ; wiki, *Set torrent share limit*).
- `-1` (illimité) ne satisfait aucune des deux branches : `-1 >= 0` est faux et `-1 == -2` est faux. Un torrent illimité n'est donc **jamais** déplaçable par la règle de ratio.
- La marge de `0.001f` sert à faire marcher « atteint après arrondi ». Le fixture considère comme atteint le ratio `1.1006066990976857` face à la limite `1.0`, et aussi `0.9999` (Sonarr `QBittorrentFixture.cs:715-737`, Radarr `:714-736`).

`HasReachedSeedingTimeLimit` (`:655-717`) :

```csharp
if (torrent.SeedingTimeLimit >= 0)        { seedingTimeLimit = torrent.SeedingTimeLimit * 60; }        // minutes -> seconds
else if (torrent.SeedingTimeLimit == -2 && config.MaxSeedingTimeEnabled) { seedingTimeLimit = config.MaxSeedingTime * 60; }
else                                      { return false; }
```

il utilise ensuite `torrent.SeedingTime` si l'API de liste l'a fourni (`:672-676`). Sinon, il consulte un cache de 5 minutes et, en cas d'absence, appelle **`torrents/properties`** pour `seeding_time` (`:678-716`, `:739-744`). `HasReachedInactiveSeedingTimeLimit` (`:719-737`) a la même structure, mais compare `now - last_activity` à `inactive_seeding_time_limit` (ou au global) et n'a jamais besoin d'un second appel.

(Une traduction précédente a été rejetée : les placeholders ne correspondaient pas. Garde la structure exactement telle quelle.)

### 3.3 Ce que décide `CanMoveFiles` {#33-what-canmovefiles-decides}

`CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, series, importItem)` (`CompletedDownloadService.cs:148-151`), puis deux endroits lisent `CanMoveFiles` :

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

(Radarr : `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, identique.)

```csharp
// src/NzbDrone.Core/MediaFiles/DownloadedEpisodesImportService.cs:204-207
if (importMode == ImportMode.Auto)
{
    importMode = (downloadClientItem == null || downloadClientItem.CanMoveFiles) ? ImportMode.Move : ImportMode.Copy;
}
```

(Radarr : `DownloadedMovieImportService.cs:221-224`.)

`copyOnly == false` → `TransferMode.Move` (`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`) ; `copyOnly == true` → `TransferMode.HardLinkOrCopy` si "Use Hardlinks instead of Copy" est activé, sinon `TransferMode.Copy` (`:103`, `:107`). `TransferMode` est `[Flags] None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy=Copy|HardLink` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`).

**Un Move échoué ne revient jamais à une Copy.** L'argumentaire complet, avec les numéros de ligne, est dans [sabnzbd-client-contract.md §5.5](sabnzbd-client-contract.md) ; `DiskTransferService.cs` est partagé et strictement identique entre les deux dépôts. En bref : la branche Move de `TransferFile` (`src/NzbDrone.Common/Disk/DiskTransferService.cs:360-389`) n'a qu'un seul chemin de copie, choisi à l'avance à partir de `targetMount.DriveFormat == "cifs"` (`:342`, `:378-385`), jamais en réaction à un échec ; `TryMoveFileVerified` relance l'exception (`:487-503`), et `VerifyFile` lève `IOException("File move incomplete, data loss may have occurred. …")` quand la taille de la destination ne correspond pas à celle de la source (`:505-524`).

### 3.4 Avec les valeurs par défaut de qBittorrent, l'import est une **copie** {#34-with-qbittorrents-own-defaults-the-import-is-a-copy}

Prenons un torrent qu'un shim signale de façon naïve, avec les valeurs par défaut de qBittorrent, qui sont aussi celles du modèle :

| Champ | Valeur | Effet |
|---|---|---|
| `state` | `stoppedUP` | conjonction 2 ✓ |
| `ratio_limit` | `-2` (par défaut, `QBittorrentTorrent.cs:33`) | on tombe sur la branche globale |
| `max_ratio_enabled` | `false` (valeur par défaut de qBittorrent elle-même ; corps de l'exemple du wiki `:684`) | la branche globale échoue |
| `seeding_time_limit` | `-2` | il faut `max_seeding_time_enabled` |
| `max_seeding_time_enabled` | `false` (wiki `:686`) | échoue |
| `inactive_seeding_time_limit` | `-2` | il faut `max_inactive_seeding_time_enabled` |
| `max_inactive_seeding_time_enabled` | `false` | échoue |

⇒ `HasReachedSeedLimit` false ⇒ `CanMoveFiles` false ⇒ `copyOnly` true ⇒ `TransferMode.Copy` ⇒ **le
\*arr lit chaque octet de la release sur le montage et le réécrit.** Sur un montage debrid, c'est exactement le seul résultat que toute cette conception existe pour éviter, et il échoue en silence : rien n'avertit, l'import prend simplement des heures et remplit un disque.

La fixture reprend exactement ce cas :
`should_not_be_removable_and_should_not_allow_move_files_if_max_ratio_is_not_set`
(Sonarr `QBittorrentFixture.cs:691-701`, Radarr `:690-700`) — limites globales désactivées, torrent en pause, ratio 1.0, `CanMoveFiles == false`.

### 3.5 La marche à suivre {#35-the-recipe}

Pour chaque torrent qu'un shim veut importer en mode **move** :

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

`ratio_limit: 0` prend la première branche (`0 >= 0`, et `0 - 0 <= 0.001`) et les préférences globales ne sont jamais consultées. Donc `max_ratio_enabled` peut rester à `false`, et la vérification de santé `DownloadClientRemovesCompletedDownloadsCheck` reste silencieuse. Tout `ratio_limit >= ratio` qui se trouve à `0.001` près fonctionne ; `0`/`0` est le seul cas qui ne demande aucune coordination.

Sur `pausedUP` vs `stoppedUP` : **la branche develop les traite de la même façon**, aussi bien dans le garde-fou `CanMoveFiles` (`:244`) que dans la table de correspondance des statuts (`:266-267`), et chaque fixture de limite de seed est une paire de `[TestCase]` qui couvre les deux. `stoppedUP` est l'écriture de qBittorrent 5 (`serialize_torrent.cpp:54-55` ; `pausedUP` n'existe plus dans master). `pausedUP` est le choix le plus sûr avec les builds *publiées* de \*arr, car la branche `stoppedUP` a été ajoutée à la sortie de qBittorrent 5, et les anciens builds de Sonarr v4 / Radarr v5 ne connaissent que `pausedUP`. Ce dernier point est une déduction sur les anciens tags, et non quelque chose que les sources develop ci-dessus prouvent.

Et ce qui ne dépend pas du shim : **« Remove Completed » doit rester activé dans les paramètres de download client de \*arr.** Il est activé par défaut (`DownloadClientDefinition.cs:17`). Documentez-le, car le désactiver transforme silencieusement chaque import en téléchargement complet.

## 4. `OutputPath` — d'où le \*arr est invité à importer {#4-outputpath--where-the-arr-is-told-to-import-from}

### 4.1 Le chemin 2.6.1+ : `content_path` {#41-the-261-path-content_path}

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

Le texte de l'avertissement (`src/NzbDrone.Core/Localization/Core/en.json`) :

> Unable to Import. Path matches client base download directory, it's possible 'Keep top-level folder'
> is disabled for this torrent or 'Torrent Content Layout' is NOT set to 'Original' or 'Create Subfolder'?

Règles que le shim doit respecter :

- `content_path` **ne doit pas être égal** à `save_path`. L'égalité est l'échec, pas une solution de repli : l'élément passe en Warning et n'est jamais importé.
- `content_path` doit être **absolu et valide pour le système d'exploitation sur lequel tourne le \*arr**. `CompletedDownloadService.ValidatePath` (`CompletedDownloadService.cs:295-313`) le rejette sinon, avec le message
"[{0}] is not a valid local path. You may need a Remote Path Mapping."
- Il doit exister sur l'hôte du \*arr en tant que **dossier ou fichier** ; `ProcessPath` (`DownloadedEpisodesImportService.cs:80-105`) teste d'abord `FolderExists`, puis `FileExists`, et si aucun des deux ne correspond, il appelle `LogInaccessiblePathError` et renvoie un résultat vide.
- N'envoyez pas de `content_path` vide. Il « diffère » d'un `save_path` non vide, donc `OutputPath` est défini sur un `OsPath` vide, et `GetImportItem` passe alors au parcours de `torrents/files` (§4.2) car `item.OutputPath.IsEmpty` vaut true (`:341-344`).
- Ce bloc n'est exécuté que pour les éléments **Completed**, donc `content_path` ne compte vraiment qu'une fois que l'état fait partie de l'ensemble Completed de §2.

Ce que qBittorrent réel y met — `TorrentImpl::contentPath()` (`qBittorrent/src/base/bittorrent/torrentimpl.cpp:577-587`) :

```cpp
Path TorrentImpl::contentPath() const
{
    if (!hasMetadata())    return {};
    if (filesCount() == 1) return (actualStorageLocation() / filePath(0));   // the FILE, not a folder
    const Path rootPath = this->rootPath();
    return (rootPath.isEmpty() ? actualStorageLocation() : rootPath);
}
```

avec `rootPath()` = `actualStorageLocation() / Path::findRootFolder(filePaths())` (`:565-575`). Donc : le `content_path` d'un torrent à **fichier unique** est le fichier lui-même ; un torrent multi-fichiers avec un dossier racine commun reçoit ce dossier ; un torrent multi-fichiers **sans** racine commune reçoit `save_path`. C'est exactement le cas que vise l'avertissement du client sur `content_path == save_path`.

`RemapRemoteToLocal(Settings.Host, …)` applique les Remote Path Mappings de l'utilisateur, indexés sur la chaîne **Host** configurée. Si le \*arr tourne dans un conteneur et que le shim renvoie le chemin de l'hôte, l'utilisateur doit créer un mapping. Voir [sabnzbd.md](../guides/sonarr-radarr.md#8-if-your-arr-is-in-docker), qui s'applique sans changement.

### 4.2 Le chemin pré-2.6.1 : `GetImportItem` parcourt `torrents/files` {#42-the-pre-261-path-getimportitem-walks-torrentsfiles}

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

Il prend **uniquement `files[0].name`**, remonte jusqu'à son composant de chemin le plus haut, et l'ajoute à
`properties.save_path`. La fixture couvre les trois formes (Sonarr `QBittorrentFixture.cs:317-421`,
Radarr `:296-400`) :

| `files[0].name` | `save_path` | `OutputPath` |
|---|---|---|
| `Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` |
| `Folder/Droned.S01E01.Tests.1080p.WEB-DL-DRONE.mkv` | `/Torrents` | `/Torrents/Folder` |
| `Droned.S01.12/E01.mkv` (+ `E02.mkv`) | `/Torrents` | `/Torrents/Droned.S01.12` |

Remarque : la troisième ligne prend la racine de `files[0]`, et non une racine commune calculée. Donc **une shim sur ce chemin doit lister les fichiers dans un ordre dont la première entrée contient le dossier de la release**. Une shim qui annonce webapi `>= 2.6.1` n'arrive jamais jusqu'ici, ce qui est une raison de plus de déclarer `2.11.2`.

`previousImportAttempt` est un paramètre de `GetImportItem` (`:338`) et **n'est jamais lu** par cette implémentation. Rien sur une tentative échouée n'est retenu.

### 4.3 Quand le chemin est faux, et à quelle fréquence on réessaie {#43-when-the-path-is-wrong-and-how-often-it-is-retried}

Il n'y a ni temporisation ni limite de tentatives sur ce chemin.

- `CompletedDownloadService.Check` s'exécute pour chaque téléchargement suivi dans l'état `Downloading` ou
  `ImportBlocked`, à chaque actualisation
  (`src/NzbDrone.Core/Download/TrackedDownloads/DownloadMonitoringService.cs:125-129`).
- `Check` appelle **d'abord** `SetImportItem` (`CompletedDownloadService.cs:73`), qui exécute
  `_provideImportItemService.ProvideImportItem(...)` → `client.GetImportItem(...)`
  (`:290-293`, `src/NzbDrone.Core/Download/ProvideImportItemService.cs:17-22`). Donc `OutputPath` est
  recalculé à partir de la ligne `torrents/info` *actuelle* à chaque polling.
- Les échecs de `ValidatePath` (`:295-313`) produisent un Warning et laissent l'état à `Downloading`, donc le
  prochain polling réessaie depuis le début :
  - chemin de sortie vide → "Download doesn't contain intermediate path, Skipping."
  - chemin d'un mauvais OS → "[{0}] is not a valid local path. You may need a Remote Path Mapping. …"
- `Import` appelle aussi `SetImportItem` à l'entrée (`:130`) avant de relire
  `trackedDownload.ImportItem.OutputPath.FullPath` (`:147`), et il est déclenché depuis l'état `ImportPending`
  par `DownloadProcessingService`
  (`src/NzbDrone.Core/Download/DownloadProcessingService.cs:61-63`). Un import raté laisse l'état à `ImportPending`
  (`:158`) ou le fait passer à `ImportBlocked` (`:196`). Dans les deux cas, il est retraité.
- Un chemin qui existe mais ne donne rien d'importable produit
  "No files found are eligible for import in {0}" (`:162`) et reste en `ImportPending`.

**Conséquence pour un shim : `content_path` peut rester faux pendant un moment.** Signalez le torrent comme
Downloading (ou Queued) tant que le dossier n'existe pas vraiment et que la taille de ses fichiers n'est pas
définitive. Le client continuera simplement à interroger le shim. Signaler Completed trop tôt coûte une tentative
d'import sur un dossier pas prêt. Pire, le \*arr peut alors déplacer un fichier de taille partielle puis échouer sur
`VerifyFile`, après avoir déjà vidé la source. C'est le même piège que celui documenté pour l'endpoint SAB
([sabnzbd.md](../guides/sonarr-radarr.md), *What happens on a grab*, étape 5).

## 5. La séquence après import {#5-the-post-import-sequence}

### 5.1 Ce qui se déclenche, dans l'ordre {#51-what-fires-in-order}

`DownloadEventHub.Handle(DownloadCompletedEvent)`
(`src/NzbDrone.Core/Download/DownloadEventHub.cs:48-69`) :

```csharp
MarkItemAsImported(trackedDownload, downloadClient);                       // :54  ALWAYS, first

if (trackedDownload.DownloadItem.Removed ||
    !trackedDownload.DownloadItem.CanBeRemoved ||
    trackedDownload.DownloadItem.Status == DownloadItemStatus.Downloading) { return; }   // :56-61

if (!definition.RemoveCompletedDownloads) { return; }                      // :63-66

RemoveFromDownloadClient(message.TrackedDownload, downloadClient);         // :68
```

et `RemoveFromDownloadClient` (`:87-103`) est :

```csharp
_logger.Debug("[{0}] Removing download from {1} history", ...);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);             // :92  deleteData: TRUE
trackedDownload.DownloadItem.Removed = true;
```

Donc la séquence des requêtes après un import réussi est :

1. **`POST /api/v2/torrents/setCategory`** : seulement si une catégorie post-import est configurée
   (`QBittorrent.cs:52-69`). Ignorée par défaut.
2. Avant l'une ou l'autre de ces étapes, et en dehors du client de téléchargement : **le \*arr déplace le fichier**, puis
   `ProcessFolder` peut **supprimer le dossier source lui-même**
   (`DownloadedEpisodesImportService.cs:209-223`, Radarr `DownloadedMovieImportService.cs:226-240`) :

   ```csharp
   if (importMode == ImportMode.Move &&
       importResults.Any(i => i.Result == ImportResultType.Imported) &&
       ShouldDeleteFolder(directoryInfo, series))
   {
       _diskProvider.DeleteFolder(directoryInfo.FullName, true);   // recursive
   }
   ```

   `ShouldDeleteFolder` (`:108-153`) refuse si un fichier vidéo restant dans le dossier est analysable et n'est pas
   un échantillon (`:117-133`), ou si un `.rar` de plus de 10 Mo reste présent (`:135-139`). Après un déplacement réussi d'un fichier unique, aucune de ces conditions ne s'applique, donc le dossier **est** supprimé. Une `IOException` est interceptée et journalisée au niveau Debug (`:219-222`).
3. **`POST /api/v2/torrents/delete`** avec `hashes=<lowercase hash>&deleteFiles=true`
   (`QBittorrent.cs:335`, `QBittorrentProxyV2.cs:190-202`).

Deux autres événements atteignent le même `RemoveFromDownloadClient(…, true)` :

- `DownloadFailedEvent` (`DownloadEventHub.cs:26-46`), conditionné par `RemoveFailedDownloads` propre à chaque client (par défaut `true`, `DownloadClientDefinition.cs:18`). Notez que `TrackedDownload.Fail()` définit `DownloadItem.CanBeRemoved = true` sans condition
   (`src/NzbDrone.Core/Download/TrackedDownloads/TrackedDownload.cs:39-46`, commentaire : "Set CanBeRemoved to allow the failed item to be removed from the client") — **donc un téléchargement échoué est supprimé même lorsque la condition de limite de seed dit le contraire.**
- `DownloadCanBeRemovedEvent` (`:71-85`).

Une `NotSupportedException` levée par `RemoveItem` est rétrogradée en
"Removing item not supported by your download client ({0})." (`:95-98`) ; toute autre exception est journalisée comme erreur et l'élément n'est *pas* marqué Removed, il sera donc réessayé au prochain polling (`:99-102`).

### 5.2 Ce que le shim doit faire avec `deleteFiles=true` {#52-what-the-shim-must-do-with-deletefilestrue}

C'est la même décision que `internal/sabnzbd` a déjà prise pour `mode=history&name=delete`, pour la même raison. Voici `internal/sabnzbd/api.go:596-609` :

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

Le cas de qBittorrent suit la même logique, avec une petite différence : avec cette API, la suppression des données est le travail *du client*, pas celui du \*arr, parce que `RemoveItem` n'appelle **pas** `DeleteItemData` (§1.15). Mais le \*arr a déjà supprimé le dossier lui-même à l'étape 2 ci-dessus, via le montage. Sous `__magic__`, cela écrit un marqueur de suppression (tombstone) : l'entrée disparaît de `__magic__` mais reste exactement à sa place dans `__all__`, dans chaque répertoire de filtre, et sur le compte debrid ([magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)).

Donc :

- **`torrents/delete` supprime l'*enregistrement* du torrent que le shim garde pour le \*arr.** Répondre 200.
- **`deleteFiles` ne doit pas supprimer le torrent chez le fournisseur.** La release que le \*arr vient d'importer est toujours servie depuis ce torrent ; le supprimer détruirait ce qui a été importé. Le seul cas où une vraie suppression serait honnête est un torrent dont rien n'a jamais été importé, c'est-à-dire le chemin de téléchargement échoué. Et même là, un torrent debrid fait partie de la bibliothèque partagée, pas d'un téléchargement temporaire. Le choix par défaut le plus sûr est donc : **ne jamais supprimer le torrent chez le fournisseur, marquer seulement.** Le dire dans la doc destinée aux utilisateurs, comme [sabnzbd.md](../guides/sonarr-radarr.md) le fait sous *Ce qui fonctionne, et ce qui ne fonctionne pas*.
- Un `torrents/delete` pour un **hash inconnu** doit quand même répondre 200. La vraie API qBittorrent le fait (wiki, *Delete torrents* : « 200 | All scenarios »), et une erreur ici serait journalisée comme une erreur et réessayée à chaque cycle, pour toujours.

### 5.3 `MarkItemAsImported` et la catégorie après import {#53-markitemasimported-and-the-post-import-category}

`QBittorrent.cs:52-69` définit la catégorie post-import lorsque `TvImportedCategory` /
`MovieImportedCategory` est configurée et différente de la catégorie principale. Elle est appelée pour **chaque**
import terminé (`DownloadEventHub.cs:54`), avant la décision de suppression.

Si un shim respecte `setCategory` en déplaçant réellement le torrent hors de la catégorie interrogée, le torrent
disparaît du prochain `torrents/info?category=…`, ce qui est *précisément* ce pour quoi le paramètre existe. L'interface l'affiche
sous la forme `DownloadClientHasPostImportCategory`
(`src/NzbDrone.Core/Queue/QueueService.cs:84`, issu de
`DownloadClientItemClientInfo.HasPostImportCategory`, `QBittorrent.cs:234`). Accepter l'appel et
enregistrer la nouvelle catégorie est le comportement correct ; le refuser ne produit qu'un avertissement
(`:62-67`).

## 6. `Test()` — chaque vérification, dans l'ordre, et son message {#6-test--every-check-in-order-and-its-message}

`DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`) englobe tout le processus : **toute exception qui n'est pas interceptée devient**
`ValidationFailure("", "Test was aborted due to an error: " + ex.Message)`.

`QBittorrent.Test(List<ValidationFailure>)` (`:418-429`) :

```csharp
failures.AddIfNotNull(TestConnection());
if (failures.HasErrors()) { return; }     // a *warning* does not stop the rest
failures.AddIfNotNull(TestCategory());
failures.AddIfNotNull(TestPrioritySupport());
failures.AddIfNotNull(TestGetTorrents());
```

### 6.1 `TestConnection` (`:431-509`)

Chaque branche **retourne**, donc cette méthode ne remonte qu'une seule erreur au maximum.

| Ordre | Condition | Propriété | Message |
|---|---|---|---|
| 1 | `_proxySelector.GetProxy(Settings, force: true).GetApiVersion(Settings)` — force la nouvelle détection (`:435`) | | |
| 2 | version `< 1.5` (`:436`) | `Host` | "qBittorrent version should be at least 3.2.4. Version reported is {v}" |
| 3 | version `< 1.6` **et** catégorie définie (`:445-455`) | `Category` | "Category is not supported" / détail "Categories are not supported until qBittorrent version 3.3.0. Please upgrade or try again with an empty Category." |
| 4 | version `>= 1.6` **et** catégorie vide (`:456-464`) | `TvCategory` / `MovieCategory` | **Avertissement** — "Category is recommended" / "{appName} will not attempt to import completed downloads without a category." |
| 5 | `GetConfig` puis `RemovesCompletedDownloads(config)` (`:467-474`) | `""` | "qBittorrent is configured to remove torrents when they reach their Share Ratio Limit" / détail qui mentionne Options → BitTorrent → Share Ratio Limiting |

Correspondance des exceptions (`:476-506`) :

| Exception capturée | Propriété | Message |
|---|---|---|
| `DownloadClientAuthenticationException` | `ApiKey` si une clé API est définie, sinon `Username` | "Authentication Failure" / "Please verify your credentials. Also verify if the host running {appName} isn't blocked from accessing {clientName} by WhiteList limitations…" |
| `WebException` avec `Status == ConnectFailure` | `Host` | "Unable to connect to qBittorrent" / "Please verify the hostname and port." |
| toute autre `WebException` | `""` | "Unknown exception: {message}" |
| toute autre `Exception` | `Host` | "Unable to connect to qBittorrent", `DetailedDescription = ex.Message` |

Remarque : le cas 4 est un **avertissement**, et `failures.HasErrors()` à `:421` renvoie false pour les avertissements. Une configuration sans catégorie exécute donc quand même les trois autres vérifications.

### 6.2 `TestCategory` (`:511-556`) — le flux « category does not exist » {#62-testcategory-511-556--the-category-does-not-exist-flow}

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

Échec : propriété `TvCategory` / `MovieCategory` (ou `TvImportedCategory` / `MovieImportedCategory`),
message "Configuration of category failed", détail "{appName} was unable to add the label to
qBittorrent."

Donc un shim a le choix : soit livrer les catégories configurées dès le départ pour que `torrents/categories` les contienne déjà, soit accepter `createCategory` et le répercuter dans la toute prochaine réponse de `torrents/categories`. **Il n'existe pas de troisième option** : le client relit la liste et échoue si la clé est toujours absente. Les noms de catégories sont comparés **exactement**, en tenant compte de la casse (`Dictionary<string, …>.ContainsKey` avec le comparateur ordinal par défaut).

Remarquez la gestion de `TvImportedCategory` : la catégorie post-import est vérifiée et créée ici aussi, même si elle n'est utilisée qu'après un import. Si l'opérateur la définit, elle doit exister.

`QBittorrentSettingsValidator` (`QBittorrentSettings.cs:23-24`) refuse déjà les noms de catégories qui correspondent à `^([^\\\/](\/?[^\\\/])*)?$` : pas de backslash, pas de `//`, pas de `/` en début ou en fin. Cela se fait avant toute requête.

### 6.3 `TestPrioritySupport` (`:558-597`) — la vérification de santé `queueing` {#63-testprioritysupport-558-597--the-queueing-health-check}

```csharp
var recentPriorityDefault = Settings.RecentTvPriority == (int)QBittorrentPriority.Last;
var olderPriorityDefault  = Settings.OlderTvPriority  == (int)QBittorrentPriority.Last;
if (olderPriorityDefault && recentPriorityDefault) { return null; }   // :563-566  the default: nothing checked

var config = Proxy.GetConfig(Settings);
if (!config.QueueingEnabled) { … }                                    // :572-588
```

La propriété d'échec est `nameof(Settings.RecentTvPriority)` ou `nameof(Settings.OlderTvPriority)`
(vérifiées dans cet ordre), message "Queueing Not Enabled", détail "Torrent Queueing is not enabled in
your qBittorrent settings. Enable it in qBittorrent or select 'Last' as priority."

Une exception ici devient `("", "Unknown exception: {message}")` (`:590-594`).

`queueing_enabled` a pour valeur par défaut **`true`** dans le modèle (`QBittorrentPreferences.cs:41`), donc un shim qui omet la clé passe. Mais l'omettre est un mensonge si `topPrio` ne fait rien. Renvoyer `queueing_enabled: false` est honnête et ne produit cet échec **que** si l'opérateur a changé le réglage de priorité par rapport à `Last`.

### 6.4 `TestGetTorrents` (`:599-612`)

`Proxy.GetTorrents(Settings)`; any exception becomes `("", "Failed to get the list of torrents:
{exceptionMessage}")`. This is the check that catches a malformed `torrents/info` body — a JSON object
instead of an array, a bad enum, a non-numeric `size`.

### 6.5 La vérification `dht` {#65-the-dht-check}

Il n'y a **pas** de vérification DHT dédiée dans `Test()`. `dht` est consulté au moment de la récupération (`:73-76`, magnets sans trackers) et au moment de l'interrogation (`:288`, la branche `metaDL`). Un shim qui renvoie `dht: false` passe le test de connexion, puis refuse chaque magnet sans tracker avec `ReleaseDownloadException("Magnet not supported by download client. …")` (`TorrentClientBase.cs:115`). **Renvoie `dht: true`.**

## 7. Analyse et conséquences sur l'import que le shim doit connaître {#7-parsing-and-import-consequences-a-shim-should-know}

### 7.1 `name` devient `Title`, et `Title` sert à trois choses différentes {#71-name-becomes-title-and-title-is-used-for-three-different-things}

`DownloadClientItem.Title = torrent.Name` (`QBittorrent.cs:232`). En aval :

1. **Identification de la série/du film.** `CompletedDownloadService.Check` fait `_parsingService.GetSeries(trackedDownload.DownloadItem.Title)` (`CompletedDownloadService.cs:95`). Si ça renvoie null, il revient à l'**historique des grabs** indexé sur `DownloadId` (`:99-102`). Et si celui-ci manque aussi : "Series title mismatch; automatic import is not possible." + `ImportBlocked` (`:104-110`).
   L'équivalent dans Radarr se trouve dans `ProcessFolder`, qui lit `_historyService.FindByDownloadId(downloadClientItem?.DownloadId ?? "")` (`DownloadedMovieImportService.cs:193-194`).
   **C'est la deuxième raison pour laquelle le shim doit indexer sur l'infohash exact calculé par les \*arr** (§1.7) : le repli sur l'historique est indexé sur `DownloadId`, donc un hash qui ne correspond pas fait perdre à la fois le chemin par titre et le repli.
2. **Analyse de la release pour la décision d'import.** `downloadClientItemInfo = Parser.Parser.ParseTitle(downloadClientItem.Title)` (Sonarr `ImportDecisionMaker.cs:80` ; Radarr `ParseMovieTitle`, `:80`), assigné à `LocalEpisode.DownloadClientEpisodeInfo` / `LocalMovie.DownloadClientMovieInfo` (`:94` / `:92`).
3. **Lignes de log et interface de la file.**

**Le filtre de repli sur le titre de Sonarr.** `AggregateEpisodes.GetBestEpisodeInfo`
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

Trois conditions pour utiliser le titre du client de téléchargement à la place du nom de fichier : `!OtherVideoFiles`,
le nom de fichier n'est pas lui-même un titre scene, et le titre du client n'est pas un parse de saison complète. Donc le
nom du torrent ne sauve qu'une release à fichier unique, sans nom scene.

Radarr n'a **pas d'équivalent à ce filtre à gagnant unique**. `LocalMovie.OtherVideoFiles` existe
(`src/NzbDrone.Core/Parser/Model/LocalMovie.cs:36`) mais les infos analysées du film sont fusionnées par une
chaîne d'augmenteurs classée par confiance au lieu d'être choisies (`AggregateQuality.cs:25-121`) ; le titre du client de téléchargement
alimente ces augmenteurs, et l'identité du film vient de l'analyse du dossier plus l'historique des grabs
(`DownloadedMovieImportService.cs:192-195`).

**`OtherVideoFiles`** (`ImportDecisionMaker.cs:85`, `:100`, Radarr `:83`, `:98`) :

```csharp
var nonSampleVideoFileCount = sceneSource ? GetNonSampleVideoFileCount(newFiles, series, downloadClientItemInfo, folderInfo) : videoFiles.Count;
…
OtherVideoFiles = nonSampleVideoFileCount > 1
```

`ProcessFolder` passe toujours `sceneSource: true` (`DownloadedEpisodesImportService.cs:201`), donc un
dossier avec deux vidéos ou plus (hors échantillons) active `OtherVideoFiles` et le titre du client de téléchargement est écarté
pour chaque fichier du dossier.

**Pourquoi c'est important avec zurg.** Real-Debrid réécrit les noms de release qui déclenchent son blocage de nom de fichier —
`WEB-DL`, `WEB.x264` et `WEB.H264` uniquement dans ce cas précis, `WEBRip`, `BDRip`, `HDRip`, `DVDRip`, `HDTV.x264`, `HDTV.XviD`, `BluRay.x264` et `p.BluRay.DTS` quelle que soit la casse, mesuré le 2026-10-14 — et zurg ajoute un suffixe quand deux releases entrent en collision sur un même nom. L'un ou l'autre peut faire que `torrent.name` cesse d'être analysé comme la release récupérée. Voir la section RD 451 du monorepo `CLAUDE.md`. Les
conséquences, dans l'ordre : l'identification revient à l'historique des grabs (toujours bon, si le hash correspond) ;
l'analyse par fichier de Sonarr prend le relais (bon pour un fichier bien nommé dans le dossier) ; et le nom du dossier
sous `__magic__` — que lit `Parser.ParseTitle(directoryInfo.Name)` à
`DownloadedEpisodesImportService.cs:184` — devient l'autre élément qui doit rester analysable.

### 7.2 Le scan du dossier d'import ignore des sous-arborescences entières {#72-the-import-folder-scan-drops-whole-subtrees}

`DiskScanService.FilterPaths` (`src/NzbDrone.Core/MediaFiles/DiskScanService.cs:232-246`), appliqué au dossier de téléchargement à `DownloadedEpisodesImportService.cs:185` (Radarr `DownloadedMovieImportService.cs:202`) avec `filterExtras: true` :

```csharp
private static readonly Regex ExcludedExtrasSubFolderRegex = new Regex(@"(?:\\|\/|^)(?:extras|extrafanart|behind the scenes|deleted scenes|featurettes|interviews|other|scenes|samples|shorts|trailers)(?:\\|\/)", …IgnoreCase);   // :72
private static readonly Regex ExcludedSubFoldersRegex      = new Regex(@"(?:\\|\/|^)(?:@eadir|\.@__thumb|plex versions|\.[^\\/]+)(?:\\|\/)", …IgnoreCase);   // :73
private static readonly Regex ExcludedExtraFilesRegex      = new Regex(@"(-(trailer|other|behindthescenes|deleted|featurette|interview|scene|short)\.[^.]+$)", …IgnoreCase);   // :74
private static readonly Regex ExcludedFilesRegex           = new Regex(@"^\.(_|unmanic|DS_Store$)|^Thumbs\.db$", …IgnoreCase);   // :75
```

**La regex des extras de Radarr ne diffère que par une alternative** : `sample[s]?` au lieu de `samples` (Radarr `DiskScanService.cs:72`), donc Radarr supprime aussi un dossier `sample/` là où Sonarr ne supprime que `samples/`. Tout le reste des quatre regex est identique entre les deux dépôts.

Notez l'alternative `\.[^\\/]+` de `ExcludedSubFoldersRegex` : **tout composant de dossier qui commence par un point est écarté**, quelle que soit la profondeur. Et la correspondance porte sur `basePath.GetRelativePath(path)`, donc elle se limite au contenu situé sous le dossier d'import. Un point dans un dossier parent du point de montage est sans effet.

Seuls les fichiers dont l'extension figure dans `MediaFileExtensions.Extensions` arrivent au filtre (`DiskScanService.GetVideoFiles`, `:202-215`).

### 7.3 La détection d'échantillon lit le fichier {#73-sample-detection-reads-the-file}

`GetNonSampleVideoFileCount` (`ImportDecisionMaker.cs:216-234`) appelle `_detectSample.IsSample(...)` pour **chaque** fichier vidéo du dossier. `DetectSample.IsSample` (`src/NzbDrone.Core/MediaFiles/EpisodeImport/DetectSample.cs:27-45`) ne court-circuite que pour les specials, les `.flv` et les `.strm` (`:78-101`). Sinon, il appelle `_videoFileInfoReader.GetRunTime(path)`, c'est-à-dire **ffprobe, sur le fichier, à travers le montage**, puis compare le résultat à un minimum calculé à partir de la durée attendue (`:103-121`). Une durée égale à exactement 0 est considérée comme un **sample** (`:107-111`). Si la durée est absente, le log affiche « Failed to get runtime from the file, make sure ffprobe is available » et renvoie Indeterminate (`:38-42`).

`ShouldDeleteFolder` (`DownloadedEpisodesImportService.cs:117-133`) refait la même vérification sur ce qui reste après le déplacement.

Donc, un import d'une release de N fichiers coûte au minimum N ouvertures ffprobe sur le backend debrid avant que quoi que ce soit ne soit déplacé. C'est un vrai coût sur un montage zurg, et il est inévitable côté client.

### 7.4 Les refus dans `ProcessFolder` / `ProcessFile` {#74-the-refusals-in-processfolder--processfile}

| Condition | Result | Ligne (Sonarr) |
|---|---|---|
| le chemin d'importation est un dossier de série/film | `ImportRejectionReason.SeriesFolder` — "Import path is mapped to a series folder" (Radarr : `MovieFolder`, "…a movie folder") | `:175-182` (Radarr `:183-190`) |
| le nom du dossier ne correspond à aucune série/aucun film connu | `UnknownSeriesResult("Unknown Series")` | `:160-168` |
| le nom de fichier commence par `._` | `InvalidFilePath` | `:251-259` |
| l'extension figure dans `FileExtensions.DangerousExtensions` | `DangerousFile` | `:263-271` |
| l'extension figure dans `FileExtensions.ExecutableExtensions` | `ExecutableFile` | `:273-281` |
| l'extension ne figure pas dans `MediaFileExtensions.Extensions` | `UnsupportedExtension` | `:283-293` |

**`SeriesPathExists` / `MoviePathExists`, c'est celui qui pose problème avec une arborescence `__magic__`.** Si le dossier racine de l'\*arr est `/mnt/zurg/__magic__/tv` et qu'un dossier de série est
`/mnt/zurg/__magic__/tv/The Show`, alors un chemin d'importation qui *est* un dossier de série est
refusé directement. C'est pourquoi le dossier de téléchargement (`content_path`) doit être au même niveau que les dossiers racines, et non à l'intérieur de l'un d'eux, ce que [sabnzbd.md](../guides/sonarr-radarr.md) prévoit déjà :
`save_path` = `/mnt/zurg/__magic__/__all__`, dossiers racines `/mnt/zurg/__magic__/tv` et
`/mnt/zurg/__magic__/movies`, et les releases dans `/mnt/zurg/__magic__/__all__/<release>`.

`_UNPACK_` et `_FAILED_` sont retirés du nom du dossier avant l'analyse (`GetCleanedUpFolderName`, `:311-317`).

`IsFileLocked` est **complètement ignoré lorsqu'un élément du client de téléchargement est présent** (`:187-199`, `:295-304`)
— la vérification de verrouillage n'est lancée que pour les analyses manuelles ou des dossiers racines. Un shim n'a jamais à s'en soucier.

---

## 8. Les vérifications de santé {#8-the-health-checks}

Ces trois points sont partagés avec le client SAB et analysés dans
[sabnzbd-client-contract.md §6](sabnzbd-client-contract.md). Ce qui est propre à qBittorrent :

- **`RemotePathMappingCheck`** (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs:59-173`)
  parcourt `client.GetStatus().OutputRootFolders` — pour qBittorrent, c'est le seul dossier calculé à
  `QBittorrent.cs:377-407` : le `save_path` global, remplacé ou complété par le `savePath` de la catégorie configurée (§1.5). Il doit être un chemin valide **pour le système d'exploitation sur lequel tourne le \*arr** (`:68-113`) et il doit **exister sur l'hôte du \*arr** (`:115-158`). Il n'a pas besoin d'être accessible en écriture.
  `IsLocalhost` vaut `Settings.Host == "127.0.0.1" || Settings.Host == "localhost"` (`:406`) et change seulement lequel des trois messages d'erreur est affiché.
- **`DownloadClientRemovesCompletedDownloadsCheck`**
  (`src/NzbDrone.Core/HealthCheck/Checks/RemovesCompletedCheck.cs:33-66`) avertit dès que `GetStatus().RemovesCompletedDownloads` vaut true, c'est-à-dire dès que le flag dérivé de §1.4 est à true. Gardez `max_ratio_enabled` et `max_seeding_time_enabled` à false (ce que fait déjà la recette de §3.5) et il reste silencieux.
- **`DownloadClientRootFolderCheck`** est le seul endroit où les deux dépôts diffèrent vraiment : Sonarr avertit seulement quand un dossier racine *est égal* à un dossier de sortie, Radarr avertit aussi quand un dossier racine *contient* un dossier de sortie. Analyse complète dans [sabnzbd-client-contract.md §6.1](sabnzbd-client-contract.md) ; la règle pratique est la même ici : ne mettez pas un dossier racine au niveau du chemin de sauvegarde ou au-dessus, et ne mettez pas non plus un dossier racine à l'intérieur de celui-ci — `/mnt/zurg/__magic__/tv` est au même niveau que `/mnt/zurg/__magic__/__all__`.

---

## 9. Sonarr vs Radarr — le diff complet {#9-sonarr-vs-radarr--the-complete-diff}

Vérifié en comparant deux à deux les fichiers récupérés (BOM et CRLF normalisés).

| Fichier | Différence |
|---|---|
| `QBittorrent.cs` | `TvCategory`→`MovieCategory`, `TvImportedCategory`→`MovieImportedCategory`, `RecentTvPriority`→`RecentMoviePriority`, `OlderTvPriority`→`OlderMoviePriority`, `RemoteEpisode`→`RemoteMovie` ; `remoteEpisode.IsRecentEpisode()` → `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` (`:80`, `:137`). **Les numéros de ligne correspondent un pour un.** |
| `QBittorrentSettings.cs` | les mêmes renommages ; catégorie par défaut `"tv-sonarr"` → `"radarr"` (`:36`) ; jeton du texte d'aide `…EpisodeHelpText` → `…MovieHelpText`. Les numéros de ligne correspondent. |
| `QBittorrentProxyV2.cs` | le renommage de catégorie ; `new[] { HttpStatusCode.Forbidden }` → `[HttpStatusCode.Forbidden]` (expression de collection, Sonarr `:401` / Radarr `:400`) ; Sonarr a une ligne vide en plus à 13 → **Sonarr N = Radarr N−1 pour N ≥ 14**. |
| `QBittorrentProxyV1.cs` | le renommage de catégorie ; même décalage de ligne vide. |
| `QBittorrentProxySelector.cs` | un double espace parasite dans le constructeur de Sonarr (`:46`) ; ligne vide à 3 → **Sonarr N = Radarr N−1 pour N ≥ 4**. |
| `QBittorrentPreferences.cs`, `QBittorrentTorrent.cs`, `QBittorrentState.cs`, `QBittorrentLabel.cs`, `QBittorrentPriority.cs`, `QBittorrentContentLayout.cs` | **octet pour octet identiques.** |
| `TorrentClientBase.cs` | `RemoteEpisode`→`RemoteMovie` partout ; Radarr traite aussi le HTTP **410 Gone** comme un 404 lors de la récupération d'un `.torrent` (`:175`), Sonarr seulement le 404. Les deux font 274 lignes. |
| `QBittorrentFixture.cs` | mêmes tests, dans un ordre différent : `missingFiles_item_should_have_required_properties` se trouve à Sonarr `:296-315` et Radarr `:402-420`, et **la copie de Radarr n'a pas d'attribut `[Test]`** (`:401` est vide), donc elle ne s'exécute jamais là-bas. Sonarr `:318-421` = Radarr `:297-400` ; à partir de Sonarr `:423`, Radarr = Sonarr − 1. Sonarr 1000 lignes, Radarr 998. |
| `DiskScanService.cs` | `ExcludedExtrasSubFolderRegex` — Radarr a `sample[s]?`, Sonarr `samples` (`:72` dans les deux). Les trois autres regex sont identiques. |
| services d'import | `Series`/`Episode` contre `Movie` ; la porte de préférence de titre de `AggregateEpisodes` de Sonarr n'a pas d'équivalent dans Radarr (§7.1). Les deux refusent un chemin d'import qui est un dossier de bibliothèque avant toute autre action (Sonarr `:175-182`, Radarr `:183-190`) et analysent ensuite le nom du dossier (Sonarr `:184`, Radarr `:195`) ; Radarr cherche en plus l'historique de téléchargement par `DownloadId` à cet endroit (`:193-194`). |
| `ImportApprovedEpisodes.cs` / `ImportApprovedMovie.cs` | le switch `copyOnly` est identique, Sonarr `:139-152` / Radarr `:116-129`. |
| `DiskTransferService.cs`, `DownloadClientBase.cs`, `DownloadEventHub.cs`, `Json.cs`, `HttpClient.cs`, `HttpRequestBuilder.cs` | partagés, **octet pour octet identiques**. |

Tout le reste de ce document est **octet pour octet identique, à part Series/Movie**, et s'applique aux deux à la même ligne.

---

## 10. Exemples de payloads minimaux mais complets {#10-minimal-but-complete-example-payloads}

### 10.1 `GET /api/v2/app/webapiVersion`

```
2.11.2
```

`Content-Type: text/plain`. Pas de JSON, pas de guillemets, pas besoin de saut de ligne final.

### 10.2 `POST /api/v2/auth/login`

Corps de la requête : `username=sonarr&password=hunter2`, `application/x-www-form-urlencoded`.

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8
Set-Cookie: SID=8f3c1c0e9a1f4d2f9c0b7a5e3d1f6b2a; path=/

Ok.
```

Identifiants incorrects : toujours **200**, corps `Fails.` — jamais un 401.

### 10.3 `GET /api/v2/app/preferences`

Seules les dix clés de §1.4 sont lues ; tu peux en envoyer davantage si tu veux, elles seront ignorées.

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

Exigences strictes :

- `save_path` doit exister en tant que répertoire **sur l'hôte Sonarr/Radarr** (`RemotePathMappingCheck`, §8).
- `max_ratio_enabled: false` + `max_seeding_time_enabled: false` garde `RemovesCompletedDownloads` à false, ce qui laisse le test de connexion (§6.1, cas 5) et le health check silencieux.
- `dht: true`, sinon les magnets sans tracker sont refusés côté client (§6.5).
- `max_ratio_act` est un **entier** (§0.6).

### 10.4 `GET /api/v2/torrents/categories`

```json
{
  "tv": { "name": "tv", "savePath": "" },
  "movies": { "name": "movies", "savePath": "" }
}
```

Un **objet** JSON, `savePath` en **camelCase**, qui ne commence jamais par `//` (§1.5). Un `savePath` vide
laisse le dossier racine de sortie sur le `save_path` global.

### 10.5 `GET /api/v2/torrents/info?category=tv` — un en cours de téléchargement, un importable {#105-get-apiv2torrentsinfocategorytv--one-downloading-one-importable}

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

Exigences impératives :

- Un **tableau** JSON (`List<QBittorrentTorrent>`) ; un objet lève une exception dans `GetTorrents` et fait échouer `TestGetTorrents` (§6.4).
- `hash` en **minuscules** (§1.8) et exactement l'infohash que le \*arr a calculé à partir du magnet ou du `.torrent` (§1.7).
- `size` en **octets** ; `progress` une fraction de 0 à 1. `RemainingSize = size × (1 − progress)`.
- `eta: 8640000` est lu comme « inconnu » et donne un `RemainingTime` null (`:622-625`) ; un élément Completed reçoit `TimeSpan.Zero` dans tous les cas (`:273`).
- `state` d'après le tableau du §2, casse exacte.
- `content_path` **absolu, existant, et ≠ `save_path`** sur les éléments Completed (§4.1). Il peut être vide tant que l'élément n'est pas Completed.
- `ratio_limit: 0` + `ratio: 0` est la recette du déplacement (§3.5).
- `category` doit correspondre à la catégorie configurée dans le client ; le client ne filtre pas à nouveau, donc il faut respecter le paramètre de requête.
- `seeding_time` peut être omis complètement : le client se rabat sur `torrents/properties`, et seulement quand une limite de temps de seed est réellement en vigueur.

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

Seuls `save_path` et `seeding_time` sont lus (§1.8). **404 pour un hash inconnu** : c'est ainsi que `IsTorrentLoaded` indique « pas encore là » (`:110-126`).

### 10.7 `GET /api/v2/torrents/files?hash=<hash>`

```json
[
  { "index": 0, "name": "Some.Show.S01E03.1080p.WEB.h264-GRP/ep3.mkv", "size": 1073741824, "progress": 1, "priority": 1, "is_seed": true, "piece_range": [0, 2047], "availability": 1 }
]
```

Seul `name` est lu, par rapport à `save_path`, avec des séparateurs `/` (§1.13). L'ordre compte sur le chemin antérieur à 2.6.1 : le composant le plus haut de `files[0]` devient le dossier de sortie.

### 10.8 `POST /api/v2/torrents/add`

Requête, au format urlencoded (un magnet long arrive plutôt en multipart, voir §0.3) :

```
urls=magnet%3A%3Fxt%3Durn%3Abtih%3A3B1A...&category=tv&stopped=False
```

Réponse :

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=UTF-8

Ok.
```

Tout sauf le texte exact `Fails.` signifie un succès (§1.7). Un corps de réponse vide avec un code 200 fonctionne aussi.

### 10.9 `POST /api/v2/torrents/delete`

Requête : `hashes=3b1a1469c180f447b77021074dbbccaef62611e7&deleteFiles=true`

Réponse : `HTTP/1.1 200 OK`, corps vide. **200 aussi pour un hash inconnu** (§5.2).

### 10.10 `POST /api/v2/torrents/createCategory`, `setCategory`, `setShareLimits`, `topPrio`, `setForceStart`

Toutes acceptent des formulaires urlencoded et répondent `200` avec un corps vide. `topPrio` peut répondre **409** pour signifier « la mise en file d'attente est désactivée » : le client ignore uniquement ce statut (§1.10). `setShareLimits` peut répondre **404** pour signifier « non pris en charge », également ignoré (§1.9).

## 11. Différences avec le vrai qBittorrent — là où le modèle de zurg est plus restreint ou plus large {#11-differences-from-real-qbittorrent--where-zurgs-model-is-narrower-or-wider}

### 11.1 Il n'y a pas de seeding, donc la vérification de la limite de seed doit être simulée {#111-there-is-no-seeding-so-the-seed-limit-gate-has-to-be-faked}

Le qBittorrent réel calcule `ratio` à partir des octets réellement envoyés, et l'utilisateur peut définir une limite globale ou par torrent. La porte `CanMoveFiles` du client existe pour éviter de retirer des fichiers sous les pieds d'un torrent qui doit encore remplir une obligation de ratio (`QBittorrent.cs:240-241`). Un backend debrid n'envoie jamais rien. Le shim déclare donc `ratio: 0, ratio_limit: 0`, c'est-à-dire une limite par torrent déjà atteinte. C'est vrai dans le seul sens où ce champ peut l'être ici, et cela garde les préférences globales complètement à l'écart (§3.5).

### 11.2 `content_path` est toujours un dossier, jamais un fichier {#112-content_path-is-always-a-folder-never-a-file}

Le `contentPath()` de qBittorrent renvoie le **chemin du fichier** pour un torrent à fichier unique (`torrentimpl.cpp:582-583`). Avec `__magic__`, chaque release est un dossier contenant ses fichiers ([magic.md](../guides/magic.md#with-nothing-stored-it-is-__all__s-releases-as-real-folders)), y compris une release à fichier unique.

Conséquences, toutes à l'avantage du client :

- `ProcessPath` prend toujours la branche **dossier** (`DownloadedEpisodesImportService.cs:80-90`), jamais la branche fichier (`:92-102`). La branche dossier est celle qui applique `FilterPaths`, `ShouldDeleteFolder` et l'analyse du nom de dossier. Le filtre des extras et le repli sur le titre du dossier sont donc toujours actifs.
- Les refus par fichier de `ProcessFile` (extension dangereuse/exécutable/non prise en charge, préfixe `._` ; §7.4) restent atteignables, mais via le filtre d'extension de `GetVideoFiles` plutôt que par la branche de premier niveau.
- L'ancienne marche `GetImportItem` d'avant la 2.6.1 (§4.2) fonctionnerait aussi, puisque `files[0].name` contient toujours le dossier de la release. Mais il n'y a aucune raison de signaler une version aussi ancienne.

Un point à bien comprendre : comme c'est toujours un dossier, `content_path` vaut toujours `save_path + "/" + <release folder>` et n'est donc jamais égal à `save_path`. L'avertissement `DownloadClientQbittorrentTorrentStatePathError` (§4.1) est structurellement inatteignable, et c'est le bon résultat, pas un accident sur lequel il faudrait compter.

### 11.3 `name` n'est pas le titre demandé, et il peut changer {#113-name-is-not-the-grabbed-title-and-it-can-change}

Le nom que qBittorrent affiche vient des métadonnées du torrent, et il ne change pas. Le nom de zurg vient de la bibliothèque :

- Real-Debrid renomme les releases dont le nom de fichier déclenche son blocage 451 (`WEB-DL`, les tags `Rip` et quelques paires source.codec, mesurés le 2026-10-14). Voir la section RD 451 du `CLAUDE.md` du monorepo.
- zurg ajoute un suffixe quand deux releases tombent sur le même nom, et une réparation reconstruit une release sous un nouvel id de torrent.
- Le nom est relu depuis la bibliothèque à chaque poll, donc il peut changer **entre deux polls** pour un id que le \*arr suit déjà.

Rien de tout ça ne casse le suivi, car le suivi se fait sur `DownloadId`, c'est-à-dire l'infohash, et non sur le nom. Ce qui casse, c'est le chemin de parsing du titre décrit au §7.1. Deux règles en découlent :

1. **Indexer sur l'infohash calculé par le \*arr**, jamais sur quoi que ce soit d'interne à zurg. C'est le seul lien entre le grab, l'historique des grabs et le poll.
2. **Garder le nom du dossier `__magic__` parsable**, car c'est le fallback que lit la branche dossier (`DownloadedEpisodesImportService.cs:184`).

### 11.4 Il n'y a pas de progression ni de phase de métadonnées {#114-there-is-no-progress-and-no-metadata-phase}

Il n'y a rien à télécharger, donc il n'y a pas de vraies valeurs pour `progress`, `eta`, `dlspeed` ou `metaDL`
— la même limite que celle que documente l'endpoint SAB ([sabnzbd.md](../guides/sonarr-radarr.md), *What works, and
what does not* : « No progress. A job is queued or it is completed »). La correspondance la plus logique est : **Queued**
(`queuedDL`) tant que la bibliothèque ne liste pas encore la release, **Completed** (`pausedUP`) dès qu'elle la liste
*et que ses tailles de fichiers se sont stabilisées*, avec `size` pris de ce que le backend déclare, pour que l'entrée de la file ne soit pas vide.

N'utilise pas `metaDL` pour l'attente, sauf si `dht: true` est aussi renvoyé. C'est seulement dans ce cas qu'il correspond à Queued (`:288-297`). `queuedDL` est sans condition et n'affiche aucun message.

N'utilise pas `stalledDL`, `error` ou `missingFiles` pour une attente temporaire : les trois sont des **Warnings** (§2) et apparaissent dans la file comme des problèmes.

### 11.5 Supprimer cache, ça ne détruit pas {#115-deleting-hides-it-does-not-destroy}

`torrents/delete?deleteFiles=true` sur un vrai qBittorrent supprime le torrent et fait un `rm -rf` sur ses données.
Ici, il doit seulement supprimer l'enregistrement : la release continue d'être servie depuis le torrent chez le fournisseur, et le
dossier que le \*arr voulait voir disparaître s'est déjà marqué comme supprimé tout seul, via le montage (§5.2,
[magic.md](../guides/magic.md#deleting-hides-it-does-not-destroy)). C'est exactement le raisonnement
que consigne `deleteFromHistory` dans `internal/sabnzbd`, à `internal/sabnzbd/api.go:596-609`.

### 11.6 Tout ce que le client peut demander et qui n'a rien à appliquer {#116-everything-the-client-can-ask-for-that-has-nothing-to-apply-to}

`sequentialDownload`, `firstLastPiecePrio`, `contentLayout`, `stopped`/`paused`, `setForceStart`,
`topPrio`, `setShareLimits`, `dlLimit`/`upLimit` : on les accepte, on répond 200, et on n'applique rien. Seuls deux ont des conséquences observables s'ils sont refusés : `topPrio` (le 409 est ignoré, toute autre erreur déclenche un avertissement) et `setShareLimits` (le 404 est ignoré). Et aucun des deux ne bloque un téléchargement.

`contentLayout` mérite une remarque : ce réglage existe dans les \*arr justement pour forcer qBittorrent à garder un dossier de premier niveau, afin que `content_path != save_path`. Avec `__magic__`, la disposition est de toute façon toujours un dossier (§11.2). Le paramètre n'a donc aucun effet, et on peut le laisser sur Default.

## 12. Checklist d'implémentation (14 points) {#12-implementation-checklist-14-points}

1. **API v2 uniquement.** Réponds à `/api/v2/app/webapiVersion` avec `2.11.2`, et renvoie **404** sur `/version/api` pour que la sonde v1 échoue proprement.

2. **Authentification :** accepte un en-tête `Authorization: Bearer <key>`, un `Authorization: Basic` envoyé en amont, un cookie `SID`, ou rien du tout. Réponds à `POST /api/v2/auth/login` avec **200 + `Ok.` + `Set-Cookie: SID=…`** ; réponds `Fails.` (toujours en 200) pour des identifiants incorrects, jamais un 401. N'exige pas `Referer` ni `Origin`.

3. **Les erreurs sont des codes HTTP, pas du JSON.** 403 signifie « reconnecte-toi » et est réessayé une fois ; un second 403 remonte comme une erreur de connexion, pas comme une erreur d'authentification. 404 a un sens sur `torrents/properties` (hash inconnu) et sur `torrents/setShareLimits` (non pris en charge) ; 409 a un sens sur `torrents/topPrio` (file d'attente désactivée). Tout le reste doit renvoyer 200.

4. **Accepte les deux encodages de formulaire sur `torrents/add`** — urlencoded, et multipart quand une valeur dépasse 1024 octets ou qu'un `.torrent` est envoyé — et accepte `True`/`False` en plus de `true`/`false` pour chaque booléen.

5. **`torrents/info` renvoie un tableau ; `torrents/categories` renvoie un objet** avec `savePath` en camelCase. Respecte le paramètre de requête `category` — le client ne refiltre pas.

6. **Hashes : en minuscules dans chaque réponse, comparés sans tenir compte de la casse dans chaque requête**, et toujours l'infohash calculé par le \*arr à partir du magnet ou du `.torrent`. `torrents/properties` est la seule route qui peut recevoir le hash dans la casse utilisée par `torrents/info`.

7. **La recette de déplacement :** `state: "pausedUP"`, `ratio: 0`, `ratio_limit: 0`, `seeding_time_limit: -2`, `inactive_seeding_time_limit: -2`. Sinon l'import devient une **copie** — un téléchargement complet de la release. Documente que le réglage « Remove Completed » du \*arr doit rester activé, car le shim ne peut pas compenser.

8. **`content_path` doit être absolu, doit exister sur l'hôte du \*arr, et ne doit pas être égal à `save_path`.** Ne le définis qu'une fois la release réellement importable — listée, et avec ses tailles de fichiers stabilisées. Jusque-là, signale `queuedDL` et laisse le client continuer à interroger ; il n'y a pas de limite de tentatives.

9. **`save_path`** (depuis `app/preferences`, plus le `savePath` de chaque catégorie) doit exister comme répertoire sur l'hôte du \*arr, sinon `RemotePathMappingCheck` lève une erreur. Il n'a pas besoin d'être accessible en écriture. N'émets jamais de `savePath` commençant par `//`.

10. **Garde le test de connexion au vert :** `dht: true`, `queueing_enabled: true`, `max_ratio_enabled: false`, `max_seeding_time_enabled: false`, `max_ratio_act: 0` (entier), et soit crée à l'avance les catégories configurées, soit honore `createCategory` et reflète-le dans la toute prochaine réponse de `torrents/categories`.

11. **`torrents/delete` supprime l'enregistrement et rien d'autre.** Ignore `deleteFiles` pour le torrent du fournisseur, exactement comme `deleteFromHistory` de `internal/sabnzbd` ignore `del_files` (`internal/sabnzbd/api.go:596-609`). Réponds 200 pour un hash inconnu. Accepte `setCategory` et enregistre la nouvelle catégorie.

12. **Attends-toi à ce que le \*arr supprime lui-même le dossier de la release avec `rm -rf`** après un import en mode Move (`DownloadedEpisodesImportService.cs:209-223`) — cela devient un marqueur `__magic__` tombstone — puis à ce qu'il appelle `torrents/delete` ensuite. Les deux sont normaux ; aucun ne détruit quoi que ce soit.

13. **N'utilise que les noms d'état du §2, casse exacte.** Un nom inconnu ne lève pas d'exception ici (contrairement à SAB), mais il est journalisé et passe par défaut à Downloading. N'utilise jamais `stalledDL`, `error` ou `missingFiles` pour une attente transitoire — les trois sont des Warnings.

14. **Ne mets pas de dossier racine au niveau ou au-dessus du dossier de sortie.** Avec `save_path` = `/mnt/zurg/__magic__/__all__`, utilise `/mnt/zurg/__magic__/tv` et `/mnt/zurg/__magic__/movies` comme dossiers racine, et garde les releases dans `/mnt/zurg/__magic__/__all__/<release>` — sinon `SeriesPathExists`/`MoviePathExists` refuse l'import directement (§7.4) et `DownloadClientRootFolderCheck` de Radarr se plaint à chaque démarrage.
