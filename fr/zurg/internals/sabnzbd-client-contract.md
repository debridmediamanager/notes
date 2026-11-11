# Contrat de l'API SABnzbd tel qu'utilisé par Sonarr et Radarr (develop) {#sabnzbd-api-contract-as-consumed-by-sonarr-and-radarr-develop}

Source de référence : fichiers récupérés depuis `raw.githubusercontent.com/{Sonarr/Sonarr,Radarr/Radarr}/develop/...`
le **2026-08-22**. Chaque numéro de ligne indiqué ci-dessous a été relevé dans ces fichiers.

Gardé ici pour expliquer pourquoi `internal/sabnzbd` répond sous la forme qu'il a. Rien dans ce package ne doit être modifié sans le paragraphe ici qui explique ce que le client fait du champ : une mauvaise balise de structure ne fait pas échouer, elle laisse le client lire un zéro, et une mauvaise valeur d'énumération lève une erreur dans son désérialiseur et fait tomber toute l'interrogation. Pour savoir comment pointer Sonarr ou Radarr vers zurg, voir [sabnzbd.md](../guides/sonarr-radarr.md).

Sauf indication contraire dans une section, **les fichiers SAB des deux dépôts sont identiques octet pour octet, à part un BOM UTF-8 et le renommage `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie`, et les numéros de ligne correspondent un à un.** Chaque citation `Sabnzbd*` s'applique donc aux deux dépôts, à la même ligne. Les chemins sont `src/NzbDrone.Core/Download/Clients/Sabnzbd/...` dans les deux cas. Les différences vérifiées sont consignées au §6.

Rien ici n'est une supposition sur SAB lui-même : chaque affirmation décrit ce que fait le *client*. Lorsque j'énonce la sémantique de Newtonsoft.Json ou du runtime .NET (et non du code de Sonarr), je le dis explicitement.

---

## 0. Règles au niveau du transport (elles piègent en premier) {#0-transport-level-rules-these-bite-first}

### 0.1 Forme de l'URL {#01-url-shape}

`SabnzbdProxy.BuildRequest` (`SabnzbdProxy.cs:162-185`) :

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

- URL de base : `HttpRequestBuilder.BuildBaseUrl` (`src/NzbDrone.Common/Http/HttpRequestBuilder.cs:56-66`)
  = `{http|https}://{Host}:{Port}{UrlBase}`. `UrlBase` reçoit un `/` au début s'il n'en a pas.
  Le point de terminaison, c'est cette URL + `/api` (`SabnzbdProxy.cs:38-44`).
- Les paramètres suffixes arrivent toujours en dernier. Donc **`apikey` (ou `ma_username`+`ma_password`) et `output=json`
  sont les derniers paramètres de requête** (`HttpRequestBuilder.cs:82` — `QueryParams.Concat(SuffixQueryParams)`).
- `Accept: application/json` sur chaque appel. `output=json` sur chaque appel. Il n'existe nulle part de chemin `output=xml`.
- La clé API et le nom d'utilisateur/mot de passe sont **mutuellement exclusifs** : une clé API supprime `ma_username`/`ma_password`.

### 0.2 Répondre toujours HTTP 200, même en cas d'erreur {#02-always-answer-http-200--even-for-errors}

`HttpClient.Execute` lève une exception pour tout statut >= 400 (`src/NzbDrone.Common/Http/HttpClient.cs:106-121` ;
`HttpResponse.cs:54` — `HasHttpError => (int)StatusCode >= 400` ; un 429 devient `TooManyRequestsException`).
`SabnzbdProxy.ProcessRequest` (`SabnzbdProxy.cs:199-215`) transforme cela en
`DownloadClientException("Unable to connect to SABnzbd, {0}")`.

Le message de `HttpException` est `"HTTP request failed: [401:Unauthorized] [GET] at [url]"`
(`src/NzbDrone.Common/Http/HttpException.cs:18`) — **le corps de la réponse n'est pas dans le message**. Donc un 401 avec
`{"error":"API Key Incorrect"}` ne sera *pas* reconnu par `TestAuthentication`
(`Sabnzbd.cs:424,429` compare `ex.Message`), et le test de connexion affiche à la place le message générique "Test was aborted due to an error".  **Il faut imiter SAB : HTTP 200 + `{"status": false, "error": "..."}`.**

### 0.3 Paramètres du désérialiseur (gouvernent toutes les questions de noms de champs et de types) {#03-deserializer-settings-drives-every-field-name-and-type-question}

Toutes les charges utiles SAB passent par `NzbDrone.Common.Serializer.Json` (`src/NzbDrone.Common/Serializer/Newtonsoft.Json/Json.cs:21-37`), avec **Newtonsoft** et non System.Text.Json :

```csharp
DateTimeZoneHandling  = DateTimeZoneHandling.Utc,
NullValueHandling     = NullValueHandling.Ignore,
Formatting            = Formatting.Indented,
DefaultValueHandling  = DefaultValueHandling.Include,
ContractResolver      = new CamelCasePropertyNamesContractResolver()
Converters: StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }, VersionConverter, HttpUriConverter
```

Conséquences (comportement de Newtonsoft, pas du code Sonarr) :

| Réglage | Effet sur un émulateur |
|---|---|
| `CamelCasePropertyNamesContractResolver` | Les propriétés C# `Storage` se lient à `storage`, `PP` à `pp` et `Misc` à `misc`. Newtonsoft revient aussi à une correspondance de propriété insensible à la casse, donc les vraies clés snake_case ou en minuscules de SAB se lient dans les deux cas. |
| `StringEnumConverter` (global) | S'applique à `SabnzbdDownloadStatus`, qui n'a **aucun** convertisseur par propriété. Les noms d'enum inconnus lèvent `JsonSerializationException`. Les entiers sont aussi acceptés (`AllowIntegerValues` vaut true par défaut). |
| `NullValueHandling.Ignore` | Aussi à la **lecture** : un `null` JSON laisse le membre C# à la valeur de son constructeur. Donc `"categories": null` garde la liste vide du constructeur, mais `"misc": null` laisse `Misc` à null (pas de valeur par défaut dans le constructeur), ce qui donne une NRE, voir §3.4. |
| `MissingMemberHandling` (par défaut `Ignore`) | Les champs en trop dans ta charge utile sont sans danger. Envoie le corps SAB réel complet. |
| `Culture` (par défaut `InvariantCulture`) | Les chaînes numériques comme `"1024.00"` doivent utiliser `.` comme séparateur décimal et aucun séparateur de milliers. |

`Json.Deserialize<T>` ne relance que `JsonReaderException`, avec un message plus clair (`Json.cs:39-50`) ;
`Json.TryDeserialize<T>` avale **uniquement** `JsonReaderException` et `JsonSerializationException` (`Json.cs:99-117`). Tout le reste (par exemple une `ArgumentException` venant du convertisseur timeleft, ou une NRE venant du convertisseur priority) remonte sans être attrapé.

---

## 1. Chaque mode, chaque paramètre, chaque champ consommé {#1-every-mode-every-parameter-every-field-consumed}

### 1.1 `mode=version` — `SabnzbdProxy.GetVersion` (`SabnzbdProxy.cs:85-95`)

Requête : `GET /api?mode=version&apikey=KEY&output=json`

Modèle de réponse `SabnzbdVersionResponse` (`Responses/SabnzbdVersionResponse.cs:5`) :

| Clé JSON | Type C# | Remarques |
|---|---|---|
| `version` | `string` | Le seul champ lu. |

Lu via `Json.TryDeserialize` ; un échec d'analyse donne `Version == null` (`SabnzbdProxy.cs:89-92`).

Analyse (`Sabnzbd.cs:334-366`), regex à `Sabnzbd.cs:38` :

```csharp
// patch can be a number (releases) or 'x' (git)
private static readonly Regex VersionRegex = new Regex(@"(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+|x)", RegexOptions.Compiled);
```

- Sans ancrage, donc `4.5.0RC1` et `2.0.0beta1` passent (fixture `SabnzbdFixture.cs:523,553`).
- `patch` peut valoir littéralement `x` (builds git), remplacé par `0` (`Sabnzbd.cs:351`).
- Une version à **deux composantes** (`"4.5"`) ne correspond pas → `null` → échec de validation.
- La chaîne exacte `"develop"` (insensible à la casse) est traitée à part et devient `3.0.0` (`Sabnzbd.cs:355-362`)
  et produit un *avertissement*, pas un échec (`Sabnzbd.cs:380-387`).

La version est de nouveau récupérée (un second aller-retour `mode=version`) par `HasVersion` à
`Sabnzbd.cs:294-332` — elle n'est **pas mise en cache**.

### 1.2 `mode=get_config` — `SabnzbdProxy.GetConfig` (`SabnzbdProxy.cs:97-104`)

**Requête :** `GET /api?mode=get_config&apikey=KEY&output=json`

Utilise `Json.Deserialize` (**pas** Try) : un corps mal formé lève une exception depuis `GetConfig`.
Le niveau supérieur doit être `{"config": {...}}` (`Responses/SabnzbdConfigResponse.cs:5`). Voir §3 pour les champs.

### 1.3 `mode=fullstatus` — `SabnzbdProxy.GetFullStatus` (`SabnzbdProxy.cs:106-114`)

Requête : `GET /api?mode=fullstatus&skip_dashboard=1&apikey=KEY&output=json`

Niveau supérieur `{"status": {...}}` (`Responses/SabnzbdFullStatusResponse.cs:5`). Un seul champ est lu :

| Clé JSON | C# | Source |
|---|---|---|
| `completedir` | `string CompleteDir` | `SabnzbdFullStatus.cs:9-10` — attention : **`completedir`, sans underscore** |

Appelé **uniquement** lorsque `config.misc.complete_dir` n'est *pas* un chemin absolu **et** que la version de SAB est >= 2.0
(`Sabnzbd.cs:220-226`). Avec un `complete_dir` absolu, cet endpoint n'est jamais appelé, mais implémentez-le quand même.

Particularité à connaître : comme le corps réel est `{"status": {...}}` et que `SabnzbdJsonError.Status` est une `string`, `TryDeserialize<SabnzbdJsonError>` dans `CheckForError` échoue avec une `JsonSerializationException` et bascule dans la branche texte brut, qui met `Status = "true"` (`SabnzbdProxy.cs:224-240`). Sans gravité, mais cela signifie que fullstatus ne peut jamais signaler d'erreur par le chemin JSON.

### 1.4 `mode=queue` (lecture) — `SabnzbdProxy.GetQueue` (`SabnzbdProxy.cs:116-130`) {#14-modequeue-read--sabnzbdproxygetqueue-sabnzbdproxycs116-130}

**Requête :** `GET /api?mode=queue&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- `category` est ajouté **uniquement si** la catégorie configurée n'est pas vide (`SabnzbdProxy.cs:122-125`).
- Appelants : `Sabnzbd.GetQueue()` utilise `start=0, limit=0` (`Sabnzbd.cs:57`). SAB lit `limit=0` comme « tous » ;
  `Sabnzbd.GetCategories()` utilise `start=0, limit=1` sur le chemin pré-2.0 (`Sabnzbd.cs:229`) ;
  `Sabnzbd.RemoveItem()` l'appelle une fois de plus pour décider entre file d'attente et historique (`Sabnzbd.cs:199`).
- Extraction : `Json.Deserialize<SabnzbdQueue>(JObject.Parse(response).SelectToken("queue").ToString())`
  (`SabnzbdProxy.cs:129`). **Une clé `queue` absente au premier niveau provoque une NRE.**

`SabnzbdQueue` (`SabnzbdQueue.cs`) :

| Clé JSON | Membre C# | Type | Utilisé pour |
|---|---|---|---|
| `my_home` | `DefaultRootFolder` | `string` | Uniquement sur SAB < 2.0, pour résoudre un `complete_dir` relatif (`Sabnzbd.cs:230`). Commentaire à `SabnzbdQueue.cs:8` : "Removed in Sabnzbd 2.0.0, see mode=fullstatus instead." |
| `paused` | `Paused` | `bool` | Pause globale ; combinée avec la priorité du slot (`Sabnzbd.cs:78`). |
| `slots` | `Items` | `List<SabnzbdQueueItem>` | |

`SabnzbdQueueItem` (`SabnzbdQueueItem.cs`) :

| Clé JSON | Membre C# | Type C# | Type JSON réel de SAB | Notes |
|---|---|---|---|---|
| `status` | `Status` | `SabnzbdDownloadStatus` | string | `StringEnumConverter` global. Valeur inconnue ⇒ `JsonSerializationException` ⇒ tout `GetQueue` lève une exception. |
| `index` | `Index` | `int` | number | Lu, jamais utilisé. |
| `timeleft` | `Timeleft` | `TimeSpan` via `SabnzbdQueueTimeConverter` | string | Voir §1.4.1. |
| `mb` | `Size` | `decimal` | **string** (`"1024.00"`) | **Mégaoctets.** `TotalSize = (long)(Size * 1024 * 1024)` (`Sabnzbd.cs:72`). |
| `mbleft` | `Sizeleft` | `decimal` | **string** | **Mégaoctets.** `RemainingSize = (long)(Sizeleft * 1024 * 1024)` (`Sabnzbd.cs:73`). |
| `filename` | `Title` | `string` | string | Devient `DownloadClientItem.Title` (`Sabnzbd.cs:71`). |
| `priority` | `Priority` | `SabnzbdPriority` via `SabnzbdPriorityTypeConverter` | string (`"Normal"`) | Voir §2. |
| `cat` | `Category` | `string` | string | **`cat` dans la file d'attente, `category` dans l'historique.** |
| `mbleft`/`percentage` | `Percentage` | `int` | **string** (`"50"`) | Lu, jamais utilisé. |
| `nzo_id` | `Id` | `string` | string | L'identifiant de téléchargement sur lequel Sonarr/Radarr s'appuient pour tout. |

#### 1.4.1 Format de `timeleft` — `SabnzbdQueueTimeConverter` (`JsonConverters/SabnzbdQueueTimeConverter.cs:15-28`) {#141-timeleft-format--sabnzbdqueuetimeconverter-jsonconverterssabnzbdqueuetimeconvertercs15-28}

```csharp
var split = reader.Value.ToString().Split(':').Select(int.Parse).ToArray();
switch (split.Length)
{
    case 4: return new TimeSpan((split[0] * 24) + split[1], split[2], split[3]);   // d:h:m:s
    case 3: return new TimeSpan(split[0], split[1], split[2]);                     // h:m:s
    default: throw new ArgumentException("Expected either 0:0:0:0 or 0:0:0 format, but received: " + reader.Value);
}
```

- **Exactement 3 ou 4 entiers séparés par des deux-points.** `"0:08:32"`, `"40:12:14"`, `"1:16:12:14"` sont tous valides
  (fixture `SabnzbdQueueTimeConverterFixture.cs:14-20`) ; `"1"`, `"0:1"`, `"0:0:0:0:1"` lèvent une exception (`:28-35`). Les zéros en début de valeur sont acceptés (`int.Parse`).
- L'`ArgumentException` levée n'est **pas** interceptée par `Json.TryDeserialize`, ni par `Json.Deserialize`.
- Une **chaîne vide** `""` se découpe en `[""]` → `int.Parse` lève `FormatException`. Ne produisez jamais `""`.
- Omettre complètement `timeleft` est sans risque : le convertisseur n'est pas appelé et `Timeleft` reste à `TimeSpan.Zero`.

### 1.5 `mode=queue&name=delete` — `SabnzbdProxy.RemoveFromQueue` (`SabnzbdProxy.cs:64-72`)

```
GET /api?mode=queue&name=delete&del_files={0|1}&value={nzo_id}&apikey=KEY&output=json
```

`del_files = deleteData ? 1 : 0` (`SabnzbdProxy.cs:68`). **Aucun paramètre `archive` sur le chemin de la file d'attente.**
Le corps de la réponse passe uniquement par `CheckForError` ; rien n'est désérialisé.

### 1.6 `mode=history` (lecture) — `SabnzbdProxy.GetHistory` (`SabnzbdProxy.cs:132-146`) {#16-modehistory-read--sabnzbdproxygethistory-sabnzbdproxycs132-146}

**Requête :** `GET /api?mode=history&start={start}&limit={limit}[&category={cat}]&apikey=KEY&output=json`

- Appelant : `Sabnzbd.GetHistory()` avec `start=0, limit=_configService.DownloadClientHistoryLimit`
  (`Sabnzbd.cs:110`). Valeur par défaut **60** dans les deux dépôts
  (Sonarr `src/NzbDrone.Core/Configuration/ConfigService.cs:184`, Radarr `:236`).
- Extraction : `SelectToken("history")` (`SabnzbdProxy.cs:145`) — le niveau racine doit être `{"history": {...}}`.

`SabnzbdHistory` (`SabnzbdHistory.cs`) : `paused` (`bool`, inutilisé), `slots` → `Items`.

`SabnzbdHistoryItem` (`SabnzbdHistoryItem.cs`) :

| Clé JSON | Membre C# | Type C# | Remarques |
|---|---|---|---|
| `fail_message` | `FailMessage` | `string` | Devient `DownloadClientItem.Message` (`Sabnzbd.cs:132`) et déclenche le cas particulier Warning (§1.6.1). |
| `bytes` | `Size` | `long` | **OCTETS, pas des Mo** — `TotalSize = sabHistoryItem.Size` tel quel (`Sabnzbd.cs:128`). C'est la plus grosse différence avec `mode=queue`. |
| `category` | `Category` | `string` | Attention : `category`, alors que la file d'attente utilise `cat`. |
| `nzb_name` | `NzbName` | `string` | Lu, jamais utilisé. |
| `download_time` | `DownloadTime` | `int` (secondes) | Lu, jamais utilisé. |
| `storage` | `Storage` | `string` | Le chemin de sortie. Voir §1.6.2 — c'est ce qui est supprimé avec `rm -rf`. |
| `status` | `Status` | `SabnzbdDownloadStatus` | `StringEnumConverter` global. |
| `nzo_id` | `Id` | `string` | |
| `name` | `Title` | `string` | |

**Aucun membre de type `DateTime` n'existe dans les modèles SAB, donc aucun format de date n'est imposé.**
`completed` / `last_history_update` (époque unix dans le vrai SAB) ne sont jamais lus. Les seules valeurs liées au temps qui comptent sont `timeleft` (§1.4.1) et `download_time` (un entier non lu, en secondes).

#### 1.6.1 Statut de l'historique → `DownloadItemStatus` (`Sabnzbd.cs:116-158`) {#161-history-status--downloaditemstatus-sabnzbdcs116-158}

```
Deleted                                   -> skipped entirely (Sabnzbd.cs:116-119)
Failed  + fail_message == "Unpacking failed, write error or disk is full?"
        (InvariantCultureIgnoreCase)      -> DownloadItemStatus.Warning     (:140-144)
Failed  (any other message)               -> DownloadItemStatus.Failed      (:147)
Completed                                 -> DownloadItemStatus.Completed   (:152)
anything else (Verifying/Moving/...)      -> DownloadItemStatus.Downloading (:157)
```

Chaque élément de l'historique reçoit `RemainingSize = 0`, `RemainingTime = TimeSpan.Zero`, `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:129-135`).

`DownloadItemStatus` lui-même (`src/NzbDrone.Core/Download/DownloadItemStatus.cs:3-11`) : `Queued=0, Paused=1, Downloading=2, Completed=3, Failed=4, Warning=5`.

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

La boucle remonte **jusqu'à la racine** et garde l'ancêtre *le plus haut* dont le dernier segment est égal à `name`. Le but : si `storage` pointe vers un fichier à l'intérieur du dossier de la tâche, on remonte jusqu'au dossier de la tâche (fixture `SabnzbdFixture.cs:376-391`). Si `storage` est déjà le dossier de la tâche, aucun ancêtre ne correspond et `OutputPath == storage`, ce qui est exactement ce qu'on veut.

**Conseil pour l'émulateur : mettez `storage` directement sur le chemin du dossier de la tâche.**

Si `storage` est vide ⇒ `OutputPath` reste vide ⇒ `CompletedDownloadService.ValidatePath` affiche l'avertissement "Download doesn't contain intermediate path, Skipping." (Sonarr `CompletedDownloadService.cs:299-303`).

### 1.7 `mode=history&name=delete` — `SabnzbdProxy.RemoveFromHistory` (`SabnzbdProxy.cs:74-83`)

```
GET /api?mode=history&name=delete&del_files={0|1}&value={nzo_id}&archive={0|1}&apikey=KEY&output=json
```

```csharp
request.AddQueryParam("del_files", deleteData ? 1 : 0);          // :78
request.AddQueryParam("value", id);                              // :79
request.AddQueryParam("archive", deletePermanently ? 0 : 1);     // :80   <-- inverted
```

et l'appelant (`Sabnzbd.cs:208`) :

```csharp
_proxy.RemoveFromHistory(item.DownloadId, deleteData, item.Status == DownloadItemStatus.Failed, Settings);
```

Donc `deletePermanently == (status is Failed)`, et par conséquent :

| Statut de l'élément | `del_files` | `archive` |
|---|---|---|
| Completed | 1 | **1** (on l'archive) |
| Failed | 1 | **0** (suppression définitive) |

Oui, ça paraît à l'envers au premier coup d'œil, mais c'est bien ce que fait le code.

### 1.8 `mode=addfile` — `SabnzbdProxy.DownloadNzb` (`SabnzbdProxy.cs:46-62`)

```
POST /api?mode=addfile&cat={category}&priority={int}&apikey=KEY&output=json
Content-Type: multipart/form-data; boundary=...
  part: Content-Disposition: form-data; name="name"; filename="<CleanFileName(Release.Title)>.nzb"
        Content-Type: application/x-nzb
```

- Le champ multipart s'appelle littéralement `name`, et la partie porte un `filename` (`SabnzbdProxy.cs:53`, `HttpRequestBuilder.cs:379-395`, émis aux lignes `:180-195`).
- Le nom de fichier vient de `FileNameBuilder.CleanFileName(release.Title) + ".nzb"` (Sonarr `src/NzbDrone.Core/Download/UsenetClientBase.cs:43`, Radarr `:43`).
- **`cat` ignore l'argument `category` de la méthode** et lit directement les paramètres (`SabnzbdProxy.cs:50` : `request.AddQueryParam("cat", settings.TvCategory);`, dans Radarr : `settings.MovieCategory`). Pas grave, car l'appelant passe la même valeur.
- `priority` est le `int` brut venant de `SabnzbdPriority` (voir §2), choisi selon la récence :
  Sonarr `Sabnzbd.cs:43` `remoteEpisode.IsRecentEpisode() ? Settings.RecentTvPriority : Settings.OlderTvPriority` ;
  Radarr `Sabnzbd.cs:43` `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie ? RecentMoviePriority : OlderMoviePriority`.
- Réponse `SabnzbdAddResponse` (`Responses/SabnzbdAddResponse.cs`) :

| Clé JSON | C# | Type |
|---|---|---|
| `status` | `Status` | `bool` : parsé, puis **jamais lu** |
| `nzo_ids` | `Ids` | `List<string>`, initialisé à vide par le constructeur |

  Lu avec `TryDeserialize` ; en cas d'échec, un objet synthétique `{Status=true, Ids=[]}` est utilisé (`SabnzbdProxy.cs:55-59`).
  Puis `Sabnzbd.cs:47-52` :

```csharp
if (response == null || response.Ids.Empty())
{
    throw new DownloadClientRejectedReleaseException(remoteEpisode.Release, "SABnzbd rejected the NZB for an unknown reason");
}

return response.Ids.First();
```

  **`nzo_ids` doit être un tableau non vide de chaînes.** `"nzo_ids": null` équivaut à une clé absente (`NullValueHandling.Ignore` conserve la liste vide du constructeur) et échoue de la même façon.

### 1.9 Statut de la file → `DownloadItemStatus` (`Sabnzbd.cs:60-103`) {#19-queue-status--downloaditemstatus-sabnzbdcs60-103}

```
Deleted                                       -> skipped (Sabnzbd.cs:62-65)
(queue.paused && slot.priority != Force) || slot.status == Paused
                                              -> Paused, and RemainingTime forced to null (:78-84)
Queued | Grabbing | Propagating               -> Queued        (:85-90)
everything else                               -> Downloading   (:93)
```

Aussi `Sabnzbd.cs:96-100` : un titre qui commence par le texte littéral `"ENCRYPTED /"` est débarrassé de ces
11 caractères et l'élément est marqué `IsEncrypted = true`.

Chaque élément de la file reçoit `CanBeRemoved = true`, `CanMoveFiles = true` (`Sabnzbd.cs:75-76`).

### 1.10 Filtre de catégorie côté client (`Sabnzbd.cs:186-195`) {#110-client-side-category-filter-sabnzbdcs186-195}

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

Égalité de chaîne ordinale. Un élément de catégorie `*` n'est accepté que si la catégorie configurée est vide.

### 1.11 Modes présents dans le proxy mais jamais appelés {#111-modes-that-exist-in-the-proxy-but-are-never-called}

- `mode=retry&value={id}` (`SabnzbdProxy.cs:148-160`, réponse `{status, nzo_id}` →
  `Responses/SabnzbdRetryResponse.cs`). `ISabnzbdProxy.RetryDownload` n'a **aucun appelant** dans aucun des deux dépôts.
- `Responses/SabnzbdCategoryResponse.cs` (`{"categories": [...]}`, c'est-à-dire `mode=get_cats`) est **totalement non référencé** dans les deux dépôts.
- `Sabnzbd.ValidatePath` (`Sabnzbd.cs:576-592`) est privée et n'est jamais appelée (code mort).

## 2. `SabnzbdDownloadStatus` et `SabnzbdPriority` — membres exacts, gestion des valeurs inconnues et null {#2-sabnzbddownloadstatus-and-sabnzbdpriority--exact-members-unknownnull-handling}

### 2.1 `SabnzbdPriority.cs` (fichier complet) {#21-sabnzbdprioritycs-complete-file}

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

- `Enum.TryParse<T>(string, out T)` est la surcharge **sensible à la casse** (sémantique .NET).
  `"Normal"` fonctionne ; `"normal"` ne fonctionne **pas**. En cas d'échec, `output` vaut
  `default(SabnzbdPriority) == 0 == Normal`, donc une mauvaise casse repasse silencieusement en Normal.
  `"Force"` compte (§1.9), `"force"` ne marche pas.
- Les chaînes numériques marchent aussi : `"2"` → `Force`, `"-100"` → `Default`. Un nombre JSON `2` marche aussi
  (`reader.Value.ToString()` == `"2"`).
- **`"priority": null` lève une `NullReferenceException`** (`reader.Value.ToString()` sur null).
  Ce cas n'est *pas* intercepté par `Json.TryDeserialize`. Omets la clé ou envoie une vraie valeur.
- Omettre `priority` ne pose pas de problème : le convertisseur n'est pas appelé, le membre reste `Normal` (0).
- Le convertisseur n'est enregistré que sur `SabnzbdQueueItem.Priority` (`SabnzbdQueueItem.cs:21`) ;
  les éléments de l'historique n'ont pas de priorité.
- Ce sont ces mêmes entiers que Sonarr/Radarr renvoient dans `&priority=` sur `mode=addfile`
  (`SabnzbdSettings.cs` met par défaut `Recent*Priority` et `Older*Priority` à
  `(int)SabnzbdPriority.Default` = `-100`).

### 2.2 `SabnzbdDownloadStatus.cs` (fichier complet), l'ordre de déclaration donne les valeurs implicites 0..15 {#22-sabnzbddownloadstatuscs-complete-file-declaration-order--implicit-values-015}

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

- **Pas de convertisseur par propriété.** Le `StringEnumConverter { NamingStrategy = CamelCaseNamingStrategy }` enregistré globalement (`Json.cs:32`) s'en charge.
- Un **nom inconnu lève une exception** (`EnumUtils.ParseEnum` de Newtonsoft → `JsonSerializationException`). Comme `GetQueue`/`GetHistory` utilisent `Json.Deserialize` (et non Try), l'appel *entier* à la file ou à l'historique échoue. **N'émets jamais un statut en dehors de cette liste.**
- Émets les orthographes canoniques de SAB exactement comme ci-dessus (`"Downloading"`, `"QuickCheck"`, `"Completed"`, `"Failed"`, `"Propagating"`, ...). La correspondance des enums de Newtonsoft retombe bien sur une comparaison insensible à la casse, mais la casse exacte est la seule chose sur laquelle il vaut vraiment la peine de compter.
- Les entiers sont aussi acceptés (`AllowIntegerValues` vaut true par défaut), mais n'en utilise pas.
- Un `null` JSON pour `status` est ignoré par `NullValueHandling.Ignore` et le membre reste `Grabbing` (0). Un emplacement de la file devient alors silencieusement `Queued`, et un emplacement de l'historique devient silencieusement `Downloading`. Envoie toujours un statut explicite.

---

## 3. `get_config` : exactement ce qui est lu, et les règles de validation {#3-get_config-exactly-what-is-read-and-the-validation-rules}

### 3.1 Le modèle — `SabnzbdCategory.cs` {#31-the-model--sabnzbdcategorycs}

Ce fichier contient `SabnzbdConfig`, `SabnzbdConfigMisc`, `SabnzbdCategory` **et** `SabnzbdSorter`.
Il n'existe **pas de `SabnzbdConfig.cs`** dans aucun des deux dépôts (vérifié via la liste de l'API de contenus GitHub de `src/NzbDrone.Core/Download/Clients/Sabnzbd`).

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

### 3.2 `config.misc.*` — l'ensemble complet des clés lues (`SabnzbdCategory.cs:23-37`) {#32-configmisc--the-complete-set-of-keys-read-sabnzbdcategorycs23-37}

| Clé JSON | Type C# | Lu à | Rôle |
|---|---|---|---|
| `complete_dir` | `string` | `Sabnzbd.cs:218` | Base de chaque chemin de catégorie. |
| `tv_categories` | `string[]` | `Sabnzbd.cs:265, 493` | |
| `enable_tv_sorting` | `bool` | `Sabnzbd.cs:265, 493` | |
| `movie_categories` | `string[]` | `Sabnzbd.cs:269, 502` | |
| `enable_movie_sorting` | `bool` | `Sabnzbd.cs:269, 502` | |
| `date_categories` | `string[]` **via `SabnzbdStringArrayConverter`** | `Sabnzbd.cs:273, 511` | |
| `enable_date_sorting` | `bool` | `Sabnzbd.cs:273, 511` | |
| `pre_check` | `bool` | `Sabnzbd.cs:443` | |
| `history_retention` | `string` | `Sabnzbd.cs:540, 561-573` | Ancien, SAB < 4.3. |
| `history_retention_option` | `string` | `Sabnzbd.cs:541, 544` | SAB >= 4.3. |
| `history_retention_number` | `int` | `Sabnzbd.cs:542, 553` | SAB >= 4.3. |

`SabnzbdStringArrayConverter` (`JsonConverters/SabnzbdStringArrayConverter.cs:25-39`) — appliqué uniquement
à `date_categories` (`SabnzbdCategory.cs:30`) :

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

Une **chaîne** JSON devient un tableau à 1 élément ; un **null** devient `[null]` (un tableau à 1 élément contenant
null) ; un **tableau** se désérialise normalement ; tout le reste (un nombre, un objet) provoque une exception. Commentaire de doc à `:7-9` :
« On some properties sab serializes array of single item as plain string. » (Sur certaines propriétés, sab sérialise un tableau d'un seul élément sous forme de chaîne simple.)

### 3.3 `config.categories[]` — `SabnzbdCategory` (`SabnzbdCategory.cs:39-48`)

| Clé JSON | C# | Lu à |
|---|---|---|
| `priority` | `int Priority` | jamais lu |
| `pp` | `string PP` | jamais lu (le camelCase de `PP` donne `pp`) |
| `name` | `string Name` | `Sabnzbd.cs:251, 255, 458` |
| `script` | `string Script` | jamais lu |
| `dir` | `string Dir` | `Sabnzbd.cs:238` (`Dir.TrimEnd('*')`), `Sabnzbd.cs:462` (`Dir.EndsWith("*")`) |

`FullPath` (`OsPath`) est calculé, pas désérialisé.

Assemblage du chemin — `Sabnzbd.GetCategories` (`Sabnzbd.cs:216-244`) :

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

`OsPath.operator+` (`src/NzbDrone.Common/Disk/OsPath.cs:420-448`) renvoie `left` quand `right.IsEmpty`,
donc `dir: ""` donne exactement `FullPath == complete_dir`. `IsRooted` pour un chemin de type Unix vaut
`_path.StartsWith("/")` (`OsPath.cs:142-145`) ; le type de chemin est déduit de la chaîne
(`OsPath.cs:43-60`) — un `/` en début ⇒ Unix, un `\` ou une lettre de lecteur ⇒ Windows. Un chemin de type Unix passé à un Sonarr hébergé sous Windows échoue dans `CompletedDownloadService.ValidatePath` (`:305-310`).

### 3.4 Les deux pièges de NRE (et ce qui est vraiment sûr) {#34-the-two-nre-landmines-and-what-is-actually-safe}

| Forme de la charge utile | Résultat |
|---|---|
| **`"misc"` absent ou `null`** | `Misc` reste null (pas de valeur par défaut dans le constructeur ; `NullValueHandling.Ignore` à la lecture) → **NullReferenceException à `Sabnzbd.cs:218`**, qui apparaît sous la forme "Test was aborted due to an error: …" et comme erreur journalisée dans les vérifications de santé. |
| **une catégorie avec `"dir"` absent ou `null`** | `Dir` est null → **NullReferenceException à `Sabnzbd.cs:238`** (`category.Dir.TrimEnd('*')`), puis encore à `:462` (`category.Dir.EndsWith("*")`). |
| `"categories": null` ou absent | Sans risque : la liste vide du constructeur est conservée. `GetStatus` ne trouve alors aucune catégorie et `OutputRootFolders` reste vide. |
| `"sorters": null` ou absent | Sans risque : liste vide du constructeur ; `config.Sorters.Any(...)` à `Sabnzbd.cs:484` fonctionne. |
| `"servers": null` ou absent | Sans risque, et jamais lu (`List<object>`, `SabnzbdCategory.cs:19`). |
| `"tv_categories"/"movie_categories"/"date_categories": null` | Sans risque : `ContainsCategory` renvoie `true` pour null/vide (§3.5), mais cela n'a d'importance que si le `enable_*_sorting` correspondant est à true. |

**Règle : émettez toujours `misc` sous forme d'objet, et chaque catégorie avec une chaîne `dir` (utilisez `""`).**

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

Confirmé par les fixtures : `enable_tv_sorting=true` + `tv_categories=null` **échoue**
(`SabnzbdFixture.cs:636-645`), et + `tv_categories=[]` **échoue** aussi (`:647-656`).
`TvCategory=null` + `tv_categories=["Default"]` échoue (`:680-691`).

### 3.6 `Test()` — l'ordre exact et les règles (`Sabnzbd.cs:286-292`) {#36-test--the-exact-order-and-rules-sabnzbdcs286-292}

```csharp
protected override void Test(List<ValidationFailure> failures)
{
    failures.AddIfNotNull(TestConnectionAndVersion());
    failures.AddIfNotNull(TestAuthentication());
    failures.AddIfNotNull(TestGlobalConfig());
    failures.AddIfNotNull(TestCategory());
}
```

Encapsulé par `DownloadClientBase.Test()` (`src/NzbDrone.Core/Download/DownloadClientBase.cs:148-163`),
qui intercepte toute exception qui remonte et ajoute `"Test was aborted due to an error: " + ex.Message`.

**`TestConnectionAndVersion()` (`Sabnzbd.cs:368-414`)** — 1 × `mode=version` :

1. version non analysable → échec sur le champ `Version` (`DownloadClientSabnzbdValidationUnknownVersion`).
2. `rawVersion == "develop"` (sans tenir compte de la casse) → **avertissement** sur `Version`, `IsValid` reste à true
   (fixture `SabnzbdFixture.cs:566-577`).
3. `version.Major >= 1` → réussite (`:389-392`).
4. sinon `version.Minor >= 7` → réussite (`:394-397`).
5. sinon échec : version requise `"0.7.0"` (`:399-404`).
   Tableau des fixtures (`SabnzbdFixture.cs:549-564`) : `0.6.9`→false, `0.7.0`/`0.8.0`/`1.0.0`/`1.0.0RC1`/`1.1.x`→true.
6. Toute exception → échec sur le champ `Host` ("unable to connect"), détail = `ex.Message` (`:406-413`).

**`TestAuthentication()` (`Sabnzbd.cs:416-438`)** — 1 × `mode=get_config`. Il intercepte l'exception, puis compare
`ex.Message` avec `ContainsIgnoreCase` :

| Sous-chaîne trouvée | Champ en échec |
|---|---|
| `API Key Incorrect` | `APIKey` — `DownloadClientValidationApiKeyIncorrect` |
| `API Key Required` | `APIKey` — `DownloadClientValidationApiKeyRequired` |
| n'importe quoi d'autre | **relancée** → message générique "Test was aborted due to an error: …" |

Comme `CheckForError` encapsule le corps sous la forme `"Error response received from SABnzbd: {error}"`
(`SabnzbdProxy.cs:244`), la comparaison fonctionne si ta chaîne `error` *contient* `API Key Incorrect` /
`API Key Required` — le texte d'origine de SAB.

**`TestGlobalConfig()` (`Sabnzbd.cs:440-453`)** — 1 × `mode=get_config`, plus 1 × `mode=version`
seulement si `pre_check` vaut true :

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

Seuil : **SAB >= 1.1.0** (`HasVersion(major:1, minor:1, patch:0)`, `Sabnzbd.cs:294-332`).
`pre_check: false` évite toute la branche, y compris l'aller-retour `mode=version` en plus.

**`TestCategory()` (`Sabnzbd.cs:455-521`)** — 1 × `mode=get_config` (une *troisième* fois), plus tout ce dont
`GetCategories` a besoin. Les contrôles s'exécutent dans cet ordre, le premier résultat l'emporte :

1. catégorie trouvée (`Name == Settings.TvCategory` / `MovieCategory`) dont `dir` **se termine par `*`**
   → avertissement sur `TvCategory`/`MovieCategory` "enable job folders", InfoLink `config/categories/` (`:460-469`).
2. aucune catégorie trouvée **et** la catégorie configurée n'est pas vide → avertissement
   `DownloadClientValidationCategoryMissing`, InfoLink `config/categories/` (`:471-481`).
3. `config.Sorters.Any(s => s.is_active && ContainsCategory(s.sort_cats, cat))` → avertissement, InfoLink
   `config/sorting/` (`:483-491`). Commentaire dans le code à `:483` : *"New in SABnzbd 4.1, but on older versions
   this will be empty and not apply"*.
4. `misc.enable_tv_sorting && ContainsCategory(misc.tv_categories, cat)` → avertissement (`:493-500`).
5. `misc.enable_movie_sorting && ContainsCategory(misc.movie_categories, cat)` → avertissement (`:502-509`).
6. `misc.enable_date_sorting && ContainsCategory(misc.date_categories, cat)` → avertissement (`:511-518`).

`SabnzbdSorter` (`SabnzbdCategory.cs:50-66`) — lus : `sort_cats` (`List<string>`, vide dans le constructeur),
`is_active` (`bool`). Présents dans le modèle mais jamais lus : `name`, `order`, `min_size`,
`multipart_label`, `sort_string`, `sort_type` (`List<int>`).

**Note sur le trafic :** les quatre méthodes `Test*` font chacune leurs propres appels, rien n'est mis en cache — un seul test de connexion envoie à peu près **2 × `mode=version` et 3 × `mode=get_config`** (un 4e appel version si `pre_check` vaut true).

### 3.7 Rétention de l'historique dans `config.misc` → `RemovesCompletedDownloads` (`Sabnzbd.cs:538-574`) {#37-configmisc-history-retention--removescompleteddownloads-sabnzbdcs538-574}

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

`true` déclenche un **avertissement** de contrôle de santé
(`HealthCheck/Checks/DownloadClientRemovesCompletedDownloadsCheck.cs:44-53`).
Couverture des tests `SabnzbdFixture.cs:455-510` : les anciennes valeurs `"0"`/`""`/`null`/`"15d"` → false ;
`"-1"`/`"15"`/`"3"`/`"3d"` → true.

**La réponse la plus propre pour l'émulateur : `history_retention_option: "all"`, `history_retention_number: 0`,
`history_retention: "0"`.**

### 3.8 `SortingMode` et son contrôle de santé (`Sabnzbd.cs:263-279`) {#38-sortingmode-and-its-health-check-sabnzbdcs263-279}

`GetStatus` définit `SortingMode` à `"TV"`, `"Movie"` ou `"Date"` en utilisant les mêmes
prédicats `enable_*_sorting && ContainsCategory(...)`. Toute valeur non vide déclenche un avertissement dans
`HealthCheck/Checks/DownloadClientSortingCheck.cs:45-55`. Gardez les trois `enable_*_sorting` à false.

### 3.9 `IsLocalhost` (`Sabnzbd.cs:260`)

```csharp
IsLocalhost = Settings.Host == "127.0.0.1" || Settings.Host == "localhost"
```

Ordinal, sensible à la casse ; `::1`, `Localhost` et n'importe quel nom d'hôte ne comptent **pas**. Cela change le message `RemotePathMappingCheck` que vous obtenez (voir §6.2).

---

## 4. Gestion des erreurs — `CheckForError` (`SabnzbdProxy.cs:222-246`) {#4-error-handling--checkforerror-sabnzbdproxycs222-246}

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

`SabnzbdJsonError` (`SabnzbdJsonError.cs`, complet) :

```csharp
public string Status { get; set; }
public string Error  { get; set; }

public bool Failed => !string.IsNullOrWhiteSpace(Status) &&
                      Status.Equals("false", StringComparison.InvariantCultureIgnoreCase);
```

Les règles, précisément :

- `CheckForError` s'exécute sur **chaque** réponse, avant toute désérialisation propre au mode
  (`SabnzbdProxy.cs:217`).
- `Status` est typé `string`, mais SAB envoie un **booléen** JSON. Newtonsoft convertit `false` en `"False"`,
  et `Failed` le reconnaît sans tenir compte de la casse. Donc `false` (booléen) et `"false"` (chaîne) fonctionnent tous les deux.
- Une réponse **sans `status` de premier niveau** (par ex. `{"version": …}`, `{"queue": {...}}`,
  `{"history": {...}}`, `{"config": {...}}`) laisse `Status` à null, donc `Failed` vaut false et il n'y a pas d'erreur.
- `status: true` devient `"True"`, donc pas d'échec.
- **Corps non JSON** : `TryDeserialize` renvoie false (il intercepte `JsonReaderException` et
  `JsonSerializationException`, `Json.cs:107-116`) et la branche texte brut s'exécute. Un corps qui commence
  par `error` (sans tenir compte de la casse) donne `Status = "false"` et lève
  `DownloadClientException("Error response received from SABnzbd: {body with 'error: ' stripped}")`.
  Tout autre corps non JSON donne `Status = "true"` et est **traité comme un succès** ; c'est ensuite la
  désérialisation propre au mode qui échoue, selon ses propres règles.
- Un **corps JSON dont `status` est un objet** (`mode=fullstatus`) prend aussi la branche texte brut,
  car un jeton `StartObject` ne peut pas remplir une propriété `string`. `Status` vaut alors `"true"`.
- Notez la ligne redondante `result.Error = …` à `:239` : `Error` est défini même dans la branche succès. Cela n'a
  aucun effet (rien ne lit `Error` sauf si `Failed` est vrai).

Correspondance des exceptions dans `ProcessRequest` (`SabnzbdProxy.cs:187-220`) :

| Interceptée | Levée |
|---|---|
| `HttpException` (tout code non 2xx, y compris 401/403/404/500) | `DownloadClientException("Unable to connect to SABnzbd, {0}")` |
| `HttpRequestException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |
| `WebException` avec `WebExceptionStatus.TrustFailure` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, certificate validation failed.")` |
| autre `WebException` | `DownloadClientUnavailableException("Unable to connect to SABnzbd, {0}")` |

**Les chaînes exactes d'échec d'authentification reconnues** (`Sabnzbd.cs:424, 429`, littéraux exacts, comparés avec
`ContainsIgnoreCase` au message de l'exception) :

- `"API Key Incorrect"`
- `"API Key Required"`

Rien d'autre n'est classé. Renvoyez-les tels quels comme valeur `error` d'une réponse **HTTP 200**.

**Pourquoi un code non 200 ne doit jamais être renvoyé :** `HttpClient.Execute` lève une exception avant que `CheckForError` ne s'exécute
(`HttpClient.cs:106-121`). Le message de l'`HttpException` qui en résulte ne contient que le statut, la méthode et l'URL,
pas le corps (`HttpException.cs:18`). La reconnaissance de `"API Key Incorrect"` / `"API Key Required"` ne peut donc
jamais se déclencher. L'utilisateur voit « Unable to connect to SABnzbd » ou « Test was aborted due to an error »
au lieu d'un message exploitable, et chaque vérification de santé considère le client comme injoignable.

---

## 5. La séquence après import {#5-the-post-import-sequence}

### 5.1 Qui appelle `RemoveItem`, et avec quels paramètres {#51-who-calls-removeitem-and-with-what}

`DownloadEventHub` (`src/NzbDrone.Core/Download/DownloadEventHub.cs`, identique dans les deux dépôts sauf pour le BOM) :

- `Handle(DownloadCompletedEvent)` (`:48-69`) : appelle `MarkItemAsImported` (SAB lève `NotSupportedException` — `DownloadClientBase.cs:189-192` — journalisée en debug et ignorée), puis retourne tôt si l'élément est déjà `Removed`, `!CanBeRemoved` ou encore `Downloading`, puis retourne tôt sauf si `definition.RemoveCompletedDownloads` est activé.
- `Handle(DownloadFailedEvent)` (`:26-46`) : conditionné par `definition.RemoveFailedDownloads`.
- `Handle(DownloadCanBeRemovedEvent)` (`:71-85`) : conditionné par `definition.RemoveCompletedDownloads`.
- Les trois mènent à `RemoveFromDownloadClient` (`:87-103`) :

```csharp
_logger.Debug("[{0}] Removing download from {1} history", …);
downloadClient.RemoveItem(trackedDownload.DownloadItem, true);   // :92 -- deleteData is ALWAYS true
trackedDownload.DownloadItem.Removed = true;
```

Valeurs par défaut de `DownloadClientDefinition` (`src/NzbDrone.Core/Download/DownloadClientDefinition.cs:17-18`) :

```csharp
public bool RemoveCompletedDownloads { get; set; } = true;
public bool RemoveFailedDownloads    { get; set; } = true;
```

Le chemin de l'API manuelle `DELETE /api/v3/queue/{id}?removeFromClient=true` passe aussi `true` (Sonarr `src/Sonarr.Api.V3/Queue/QueueController.cs:342`). **Il n'existe aucun appelant qui passe `deleteData: false`.**

### 5.2 `Sabnzbd.RemoveItem` (`Sabnzbd.cs:197-214`) — la séquence exacte {#52-sabnzbdremoveitem-sabnzbdcs197-214--the-exact-sequence}

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

Donc, la séquence des appels réseau après l'import face à l'émulateur est :

1. `GET /api?mode=queue&start=0&limit=0&category=tv&apikey=…&output=json` (pour savoir si l'élément est dans la file ou dans l'historique)
2. **suppression locale du dossier de sortie sur le système de fichiers** (§5.3), **avant tout autre appel HTTP**
3. `GET /api?mode=history&name=delete&del_files=1&value={nzo_id}&archive=1&apikey=…&output=json`

Pour un élément **en échec** : pas de suppression locale (le statut est `Failed`, pas `Completed`), et **`archive=0`** —
l'inversion dans `SabnzbdProxy.cs:80` (`archive = deletePermanently ? 0 : 1`, où
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

- **Oui, ça supprime récursivement le dossier de sortie.** `DeleteFolder(path, recursive: true)` à `:129`.
- `OutputPath` ici correspond au `storage` de l'élément d'historique, après le remappage du chemin distant et la remontée jusqu'au dossier du job (§1.6.2). Pour un dossier magic à plat, ça donne `rm -rf /mnt/zurg/__magic__/__all__/<Title>`.
- Le réglage qui décide est l'option **Remove Completed Downloads** du client de téléchargement (`DownloadClientDefinition.RemoveCompletedDownloads`, par défaut **true**), et non un réglage côté SAB ni `del_files`. Il n'existe pas d'autre interrupteur « supprimer les données » dans l'interface.
- Les erreurs sont ignorées avec un simple avertissement. Un montage en lecture seule remplit les logs de bruit, mais ça ne casse pas l'import.
- Couverture des fixtures `SabnzbdFixture.cs:693-803` : dossier supprimé récursivement, fichier supprimé, rien si le chemin n'existe pas, et rien du tout (pas même une sonde `FolderExists`) quand `deleteData` vaut false.

### 5.4 Mode de transfert : le fichier est-il déplacé ou copié ? {#54-transfer-mode-is-the-file-moved-or-copied}

`Sabnzbd` définit `CanMoveFiles = true` sur **chaque** élément, dans la file d'attente (`Sabnzbd.cs:76`) comme dans l'historique (`Sabnzbd.cs:135`). Le chemin d'import automatique est `CompletedDownloadService.Import` → `ProcessPath(outputPath, ImportMode.Auto, …)` (Sonarr `CompletedDownloadService.cs:148-151`), puis :

Sonarr `src/NzbDrone.Core/MediaFiles/EpisodeImport/ImportApprovedEpisodes.cs:139-152` (Radarr `src/NzbDrone.Core/MediaFiles/MovieImport/ImportApprovedMovie.cs:116-129`, logique identique) :

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

`CanMoveFiles: true` ⇒ `copyOnly == false` ⇒ **`TransferMode.Move`** (`src/NzbDrone.Core/MediaFiles/EpisodeFileMovingService.cs:91`). Un import `copyOnly` utiliserait à la place `TransferMode.HardLinkOrCopy` si « Use Hardlinks instead of Copy » est activé, sinon `TransferMode.Copy` (`:94-108`).

`TransferMode` (`src/NzbDrone.Common/Disk/TransferMode.cs:5-15`) est `[Flags]` : `None=0, Move=1, Copy=2, HardLink=4, HardLinkOrCopy = Copy|HardLink`.

### 5.5 Un Move échoué revient-il à une copie ? — **Non. Un Move échoué est un import échoué.** {#55-does-a-failed-move-fall-back-to-a-copy--no-a-failed-move-is-a-failed-import}

`src/NzbDrone.Common/Disk/DiskTransferService.cs` (identique octet pour octet entre les deux dépôts, vérifié).
`TransferFile`, `:256-392` ; la branche `TransferMode.Move` en `:360-389` :

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

- Le **seul** repli de copie est le cas particulier `isCifs && !isSameMount` en `:378-385`, déterminé par `targetMount.DriveFormat == "cifs"` (`:342`). Il est choisi *à l'avance*, d'après le format du lecteur, jamais en réaction à un échec.
- `TryMoveFileVerified` (`:487-503`) intercepte l'exception, appelle `RollbackPartialMove` (sauf si l'exception est `FileAlreadyExistsException`) et **relance** l'exception :

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

- `VerifyFile` (`:505-524`) compare la taille de la destination à celle de la source, attend 3 s (`WaitForIO`, `:467-471`), vérifie à nouveau, puis lève `IOException("File move incomplete, data loss may have occurred. [{target}] was {n} bytes long instead of the expected {m}.")`.
- Cette `IOException` remonte à travers `EpisodeFileMovingService.TransferFile` (`:151`) jusque dans le `catch (Exception e)` générique de `ImportApprovedEpisodes.cs:218-222` (Radarr `:197-201`), ce qui produit `ImportResult(importDecision, "Failed to import episode")` / `"Failed to import movie"`. **Aucune copie n'est tentée.**
- Les autres `IOException` de pré-vérification dans la même méthode : source == cible (`:270`, `:277`), et « Destination cannot be a child of the source » (`:312-315`).

Point à noter, et c'est un fait du runtime .NET plutôt que du code de Sonarr : `DiskProviderBase.MoveFileInternal` (`src/NzbDrone.Common/Disk/DiskProviderBase.cs:293-301`) est un simple `File.Move`, et sous Unix .NET se rabat sur copie puis suppression lorsque `rename()` renvoie `EXDEV`. Donc un déplacement entre systèmes de fichiers réussit en général quand même, mais comme repli *à l'exécution*, pas comme repli de Sonarr. Ce qui n'est **pas** toléré, c'est une destination dont la taille diffère de celle de la source, ou toute exception que `File.Move` lui-même remonte (EACCES, EPERM, EROFS sur la source, …).

`TransferFolder` (`:44-137`) est utilisé par d'autres chemins de code ; à noter `:124-131` : après un Move de dossier, il refuse de supprimer la source si plus de 100 Mo de fichiers subsistent (`IOException("Large files still exist in {sourcePath} after folder move, not deleting source folder")`).

---

## 6. Les deux contrôles de santé {#6-the-two-health-checks}

### 6.1 `DownloadClientRootFolderCheck` — **le seul endroit où Sonarr et Radarr diffèrent vraiment** {#61-downloadclientrootfoldercheck--the-one-place-sonarr-and-radarr-genuinely-differ}

Sonarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51` :

```csharp
var folders = status.OutputRootFolders.Where(folder => rootFolders.Any(r => r.Path.PathEquals(folder.FullPath)));
```

Radarr `src/NzbDrone.Core/HealthCheck/Checks/DownloadClientRootFolderCheck.cs:51` :

```csharp
var folders = rootFolders.Where(r => status.OutputRootFolders.Any(folder => r.Path.PathEquals(folder.FullPath) || r.Path.IsParentPath(folder.FullPath)));
```

`IsParentPath` (`src/NzbDrone.Common/Extensions/PathExtensions.cs:123-140`) remonte **vers le haut** à partir de l'enfant :

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

Donc `r.Path.IsParentPath(folder.FullPath)` est vrai quand **le dossier racine est un ancêtre du
dossier de sortie des téléchargements**, c'est-à-dire que le dossier de sortie se trouve *à l'intérieur* d'un dossier racine. C'est un test d'ancêtre strict
(il part de `child.Directory`) ; l'égalité est gérée à part par `PathEquals`.

**Répondre directement à la question du prédicat :**

| Relation (dossier de sortie O vs dossier racine R) | Sonarr | Radarr |
|---|---|---|
| O == R | **avertit** | **avertit** |
| O à l'intérieur de R (R est un ancêtre de O) | pas d'avertissement | **avertit** |
| O est le PARENT de R (O est un ancêtre de R) | pas d'avertissement | **pas d'avertissement** |
| sans lien | pas d'avertissement | pas d'avertissement |

Avec `complete_dir = /mnt/zurg/__magic__/__all__` et `dir: ""` (donc
`OutputRootFolders == ["/mnt/zurg/__magic__/__all__"]`) :

- Sonarr n'avertit que si un dossier racine est exactement `/mnt/zurg/__magic__/__all__`.
- Radarr avertit si un dossier racine est `/mnt/zurg/__magic__/__all__`, `/mnt/zurg/__magic__`, `/mnt/zurg` ou `/mnt`.
- Aucun des deux n'avertit si un dossier racine est `/mnt/zurg/__magic__/tv` : le miroir et les dossiers racines sont des frères, donc la paire n'a aucun lien et aucune règle ne se déclenche. Un dossier racine *à l'intérieur* du dossier de sortie (`/mnt/zurg/__magic__/__all__/anything`) resterait aussi silencieux ici, mais le namespace refuse de stocker quoi que ce soit à ce niveau, donc ce cas ne peut pas exister.

`PathEquals` (`PathExtensions.cs:55-73`) normalise l'Unicode, utilise `DiskProviderBase.PathStringComparison`
(`OrdinalIgnoreCase` sous Windows, `Ordinal` ailleurs — `src/NzbDrone.Common/Disk/DiskProviderBase.cs:17-23`),
et réessaie avec `CleanFilePath()` (insensible à la barre oblique finale).

Les deux versions se réexécutent sur `ProviderUpdatedEvent` / `ProviderDeletedEvent` / `ModelEvent<RootFolder>` /
`ModelEvent<RemotePathMapping>` ; Radarr ajoute `[CheckOn(typeof(ProviderAddedEvent<IDownloadClient>))]`
à `:17`. Le résultat est `HealthCheckResult.Warning` avec l'ancre `#downloads-in-root-folder`. Le message
insère `folder.FullPath` dans Sonarr et `folder.Path` dans Radarr (`:60` dans les deux). Les deux ignorent silencieusement `DownloadClientException` et `HttpRequestException` (log de debug) et journalisent toute autre exception comme une erreur.

### 6.2 `RemotePathMappingCheck` — le chemin du client local (`src/NzbDrone.Core/HealthCheck/Checks/RemotePathMappingCheck.cs`) {#62-remotepathmappingcheck--the-local-client-path-srcnzbdronecorehealthcheckchecksremotepathmappingcheckcs}

Court-circuit en `:51-54` : si `EnableCompletedDownloadHandling` est désactivé, la vérification ne fait rien.

Pour chaque `folder` dans `client.GetStatus().OutputRootFolders` :

1. **`!folder.IsValid`** (`:68`) — `OsPath.IsValid` = `_path.IsPathValid(PathValidationType.CurrentOs)`
   (`OsPath.cs:228`). Hors Windows, cela se réduit à `path.StartsWith("/")` plus un contrôle des caractères avec `Path.GetInvalidPathChars()` (`PathExtensions.cs:143-182`, `:403-411`). Erreurs, dans l'ordre :
   - `!status.IsLocalhost` → `RemotePathMappingWrongOSPathHealthCheckMessage` (clé Radarr :
     `RemotePathMappingCheckWrongOSPath`), ancre `#bad-remote-path-mapping`
   - `_osInfo.IsDocker` → …`BadDockerPath`, ancre `#docker-bad-remote-path-mapping`
   - sinon → …`LocalWrongOSPath`, ancre `#bad-download-client-settings`
2. **`!_diskProvider.FolderExists(folder.FullPath)`** (`:115`) :
   - `_osInfo.IsDocker` → …`DockerFolderMissing`, `#docker-bad-remote-path-mapping`
   - `!status.IsLocalhost` → …`LocalFolderMissing`, `#bad-remote-path-mapping`
   - sinon → …`GenericPermissions`, `#permissions-error`

**Pour un client local (`IsLocalhost` vrai, pas Docker), cela se réduit à exactement deux exigences :**
le dossier racine de sortie signalé doit être un chemin absolu *pour le système d'exploitation sur lequel tourne Sonarr/Radarr*, et il doit **exister sur l'hôte de Sonarr/Radarr** en tant que dossier. `/mnt/zurg/__magic__/__all__` doit être visible par le processus *arr, pas seulement par l'émulateur. Il n'y a aucune vérification d'écriture ici.**

La surcharge pilotée par événements (`:178-368`) se déclenche sur `EpisodeImportFailedEvent` (Radarr : `MovieImportFailedEvent`) et, point important, rappelle `client.GetItems()` pour chercher le `OutputPath` du téléchargement en échec (`:232`).

Aucun health check n'exige que le dossier de sortie soit *accessible en écriture*. `FolderWritable` (`DiskProviderBase.cs:126-143` Sonarr / `:127-144` Radarr) — qui écrit puis supprime `sonarr_write_test.txt` / `radarr_write_test.txt` — est utilisé par `RootFolderService.Add` (Sonarr `src/NzbDrone.Core/RootFolders/RootFolderService.cs:117-120`) et par `DownloadClientBase.TestFolder` (`:167-187`), et **`TestFolder` n'est jamais appelé par le client SAB.**

---

## 7. Sonarr vs Radarr — le diff complet {#7-sonarr-vs-radarr--the-complete-diff}

**Identiques octet par octet, à part un BOM UTF-8 sur les copies Sonarr** (les numéros de ligne correspondent donc exactement) :

`SabnzbdCategory.cs` (pas de BOM des deux côtés, donc vraiment identique), `SabnzbdDownloadStatus.cs`,
`SabnzbdPriority.cs`, `SabnzbdFullStatus.cs`, `SabnzbdJsonError.cs`, `SabnzbdQueue.cs`,
`SabnzbdQueueItem.cs`, `SabnzbdHistory.cs`, `SabnzbdHistoryItem.cs`,
`JsonConverters/*.cs` (les trois), `Responses/*.cs` (les six),
`src/NzbDrone.Common/Disk/DiskTransferService.cs`, `src/NzbDrone.Core/Download/DownloadEventHub.cs`.

**Ne diffèrent que par le renommage `TvCategory` → `MovieCategory` / `RemoteEpisode` → `RemoteMovie` (aucun changement du nombre de lignes, mêmes numéros de ligne) :**

- `Sabnzbd.cs` — `:40-52` (`AddFromNzbFile` ; le test de récence de Radarr est
  `remoteMovie.Movie.MovieMetadata.Value.IsRecentMovie` contre `remoteEpisode.IsRecentEpisode()` de Sonarr), `:190`, `:251`, `:265/269/273`, `:458`, et chaque nom de champ `NzbDroneValidationFailure` dans `TestCategory` (`"TvCategory"` → `"MovieCategory"`).
- `SabnzbdProxy.cs` — `:50`, `:122-124`, `:138-140`.
- `SabnzbdSettings.cs` — valeurs par défaut `TvCategory = "tv"` contre `MovieCategory = "movies"` ;
  `RecentTvPriority`/`OlderTvPriority` contre `RecentMoviePriority`/`OlderMoviePriority`
  (les deux ont pour valeur par défaut `(int)SabnzbdPriority.Default`). Le validateur est par ailleurs identique : `Host` valide,
  `Port` de 1 à 65535, `ApiKey` requis quand le nom d'utilisateur est vide, `Username`/`Password` requis quand ApiKey
  est vide, catégorie `NotEmpty` **en tant qu'avertissement**.
- `UsenetClientBase.cs` — Radarr définit en plus `request.AllowAutoRedirect = true` (`:51`) et
  traite le code HTTP `410 Gone` comme un `404` (`:63`) lorsqu'il récupère le NZB auprès de l'indexeur. **Cela concerne l'indexeur, pas SAB.**
- `DownloadClientBase.cs` — uniquement les mots "Sonarr"/"Radarr" écrits en dur dans le texte de détail de `TestFolder`.
- `RemotePathMappingCheck.cs` — noms des clés de localisation (`RemotePathMapping*HealthCheckMessage` contre `RemotePathMappingCheck*`), `EpisodeImportFailedEvent`
  contre `MovieImportFailedEvent`, plus le `[CheckOn(ProviderAddedEvent<IDownloadClient>)]` supplémentaire de Radarr. **Les prédicats sont identiques.**
- `DiskProviderBase.cs` — le fichier de test `FolderWritable` `sonarr_write_test.txt` contre `radarr_write_test.txt`
  (Sonarr `:132`, Radarr `:133`).

**Véritable différence de comportement — une seule :**

- **`DownloadClientRootFolderCheck.cs:51`.** Sonarr n'avertit que sur `PathEquals` ; Radarr avertit aussi lorsqu'un dossier racine est un ancêtre du dossier de sortie. Tableau complet au §6.1.

Tout le reste — modes, paramètres, formes JSON, énumérations, convertisseurs, `CheckForError`, `RemoveItem`,
`DeleteItemData`, mode de transfert, `DiskTransferService` — est identique. **Un seul émulateur sert aux deux.**

Valeurs de configuration par défaut identiques dans les deux : `DownloadClientHistoryLimit = 60`,
`RemoveCompletedDownloads = true`, `RemoveFailedDownloads = true`.

---

(Une traduction précédente a été rejetée : les portions de code diffèrent. Garde la structure exactement telle quelle.)

## 8. Exemples de charges utiles minimales mais complètes {#8-minimal-but-complete-example-payloads}

Étant donné : `complete_dir = /mnt/zurg/__magic__/__all__` ; catégories `*`, `tv`, `movies`, toutes avec `dir: ""`.
Chaque réponse est **HTTP 200** avec `Content-Type: application/json`.

`OutputRootFolders` obtenu : `dir: ""` ⇒ `FullPath == complete_dir` ⇒ `/mnt/zurg/__magic__/__all__`
pour Sonarr (catégorie `tv`) et pour Radarr (catégorie `movies`).

### 8.1 `mode=version`

```json
{
  "version": "4.3.3"
}
```

Doit être `major.minor.(patch|x)`. `4` ≥ 1 satisfait `TestConnectionAndVersion` (`Sabnzbd.cs:389-392`) ;
≥ 2.0 signifie aussi que `GetCategories` utiliserait `fullstatus` plutôt que `queue.my_home` si `complete_dir`
était relatif (ce n'est pas le cas).

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

Pourquoi chaque valeur :

- `misc` présent sous forme d'objet — **obligatoire**, sinon NRE (§3.4).
- chaque catégorie a un `dir` de type **chaîne** — **obligatoire**, sinon NRE à `Sabnzbd.cs:238` et `:462`.
- `dir` ne se termine **pas** par `*` — sinon l'avertissement « enable job folders » (`Sabnzbd.cs:462-469`).
- les trois `enable_*_sorting: false` — supprime à la fois les avertissements `TestCategory` (`Sabnzbd.cs:493-518`) et `DownloadClientSortingCheck`. Attention : `tv_categories: []` combiné à `enable_tv_sorting: true` ferait **échouer** le test, car `ContainsCategory` renvoie true pour une liste vide (`Sabnzbd.cs:525-528`, fixture `SabnzbdFixture.cs:647-656`).
- `sorters: []` — `config.Sorters.Any(s => s.is_active && …)` est faux (`Sabnzbd.cs:484`).
- `pre_check: false` — évite l'aller-retour `HasVersion(1,1)` dans `TestGlobalConfig` (`Sabnzbd.cs:443`).
- `history_retention_option: "all"` → `RemovesCompletedDownloads == false` (`Sabnzbd.cs:546-547`) → pas d'avertissement de vérification de santé.
- `complete_dir` absolu → `IsRooted` vaut true → `mode=fullstatus` / `queue.my_home` ne sont jamais consultés (`Sabnzbd.cs:220`).

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

Seul `completedir` est lu (`SabnzbdFullStatus.cs:9-10`). La clé englobante **doit** être `status`
(`Responses/SabnzbdFullStatusResponse.cs:5`).

### 8.4 Réponse de `mode=addfile` {#84-modeaddfile-response}

```json
{
  "status": true,
  "nzo_ids": ["SABnzbd_nzo_abc12345"]
}
```

`nzo_ids` doit être un **tableau non vide de chaînes** (`Sabnzbd.cs:47-52`). `status` est analysé
(`Responses/SabnzbdAddResponse.cs:13`) mais n'est jamais lu ; gardez-le à `true` pour que `CheckForError` voie `"True"`.

### 8.5 `mode=queue&start=0&limit=0&category=tv` — un emplacement Downloading {#85-modequeuestart0limit0categorytv--one-downloading-slot}

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

Exigences strictes :

- clé de premier niveau `queue` (`SabnzbdProxy.cs:129`, `SelectToken("queue")`).
- `slots[].status` ∈ les 16 noms de `SabnzbdDownloadStatus`, casse exacte.
- `slots[].mb` / `mbleft` sont des **mégaoctets**, avec des décimales au format invariant. Les chaînes comme les nombres fonctionnent (Newtonsoft convertit) ; le vrai SAB envoie des chaînes.
- `slots[].timeleft` doit être exactement `h:m:s` ou `d:h:m:s`, jamais `""`.
- `slots[].priority` : `"Normal"`, `"High"`, `"Low"`, `"Force"`, `"Paused"`, `"Default"` (sensibles à la casse) ou l'équivalent numérique. **Jamais `null`** (NRE).
- `slots[].cat` (pas `category`) doit être égal à la catégorie configurée dans le client, sinon l'élément est filtré à `Sabnzbd.cs:190`.
- `queue.paused` doit rester `false`, sauf si vous voulez vraiment une pause : `true` marque chaque slot qui n'est pas `Force` comme Paused, avec un ETA nul (`Sabnzbd.cs:78-84`).

`DownloadClientItem` obtenu : `TotalSize = 1024 * 1024 * 1024`, `RemainingSize = 512 * 1024 * 1024`, `RemainingTime = 00:08:32`, `Status = Downloading`, `CanBeRemoved = CanMoveFiles = true`.

### 8.6 `mode=history&start=0&limit=60&category=tv` — un emplacement Completed et un emplacement Failed {#86-modehistorystart0limit60categorytv--one-completed-and-one-failed-slot}

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

Exigences strictes :

- clé de premier niveau `history` (`SabnzbdProxy.cs:145`).
- `slots[].bytes` est en **OCTETS** (un nombre JSON → `long`). N'envoyez pas de MB ici : la file utilise MB, et
  l'historique utilise des octets (`Sabnzbd.cs:72-73` vs `:128`).
- `slots[].category` (pas `cat`).
- `slots[].storage` = le dossier de la tâche lui-même ; il devient `OutputPath`, et pour un élément Completed, c'est ce que `DeleteItemData` supprime récursivement (§5.3). Il doit être un chemin absolu valide pour le système d'exploitation sur lequel Sonarr/Radarr s'exécute, et il doit exister à cet endroit (`RemotePathMappingCheck`, §6.2).
- `slots[].status` respecte la casse exacte ; les éléments `Deleted` sont totalement ignorés (`Sabnzbd.cs:116-119`).
- `fail_message` exactement `"Unpacking failed, write error or disk is full?"` fait passer un élément Failed à `Warning` au lieu de `Failed` (`Sabnzbd.cs:140-144`). Utilisez autre chose pour un vrai échec.
- Radarr : `category` doit être `movies` (ou ce qui est configuré), et `name` doit pouvoir être analysé comme un film.

### 8.7 Réponse d'erreur (tous les modes) {#87-error-response-any-mode}

```json
{
  "status": false,
  "error": "API Key Incorrect"
}
```

**HTTP 200.** `status` peut être le booléen `false` ou la chaîne `"false"` ; les deux correspondent à `SabnzbdJsonError.Failed` (`SabnzbdJsonError.cs:10-11`). Le client lève `DownloadClientException("Error response received from SABnzbd: API Key Incorrect")` (`SabnzbdProxy.cs:244`), que `TestAuthentication` reconnaît (`Sabnzbd.cs:424`). Utilisez `"API Key Required"` lorsqu'aucune clé n'a été fournie (`Sabnzbd.cs:429`). Toute autre chaîne `error` est affichée telle quelle mais n'est pas classée.

---

## 9. Liste de contrôle de l'implémentation (12 points) {#9-implementation-checklist-12-points}

1. Une seule route : `GET|POST {UrlBase}/api`, qui dispatche selon `mode`. **Toujours HTTP 200, toujours du JSON.**
2. Implémente `version`, `get_config`, `queue` (lecture + `name=delete`), `history` (lecture + `name=delete`),
   `addfile`, `fullstatus`. Optionnel : `retry` (code mort pour l'instant). `get_cats` n'est jamais appelé.
3. Accepte l'authentification soit par `apikey=`, **soit** par `ma_username=`+`ma_password=`. Refuse avec 200 +
   `{"status":false,"error":"API Key Incorrect"}` / `"API Key Required"`, jamais de 401/403.
4. Respecte `category=` sur `queue`/`history` (les clients filtrent aussi côté client par correspondance exacte de la chaîne,
   `Sabnzbd.cs:190`).
5. Les tailles de `queue` sont en **MB** (`mb`, `mbleft`) ; celles de `history` sont en **BYTES** (`bytes`). Ne les mélange jamais.
   La queue utilise `cat`, l'historique utilise `category`.
6. `timeleft` est toujours au format `h:m:s` ou `d:h:m:s`, jamais vide, jamais absent ou chaîne vide.
   Aucun champ de date n'est analysé nulle part, donc les champs epoch sont libres.
7. Les valeurs de `status` doivent venir de la liste `SabnzbdDownloadStatus` à 16 membres, casse exacte (un nom inconnu lève une exception et fait tomber tout l'appel queue/history). `priority` doit être un nom `SabnzbdPriority` (casse exacte) ou sa valeur entière ; **jamais `null`** (NRE dans le convertisseur).
8. `config.misc` doit être un objet ; chaque catégorie doit avoir une **chaîne `dir` non nulle** qui ne se termine pas par `*`. `categories`/`sorters`/`servers` peuvent être null ou absents, mais `misc` et `dir` ne peuvent pas l'être.
9. Laisse `enable_tv_sorting`, `enable_movie_sorting`, `enable_date_sorting` et `pre_check` tous à `false`, et `history_retention_option: "all"`, pour que le test de connexion et tous les contrôles de santé restent propres.
10. `storage` d'un slot d'historique Completed = le dossier du job. Attends-toi à ce que les *arr fassent un `rm -rf` dessus après un import réussi (paramètres par défaut), et à ce que le fichier média en soit **déplacé** d'abord. Si le dossier magic est en lecture seule, la suppression échoue silencieusement (simple log d'avertissement), mais le *déplacement* du fichier importé doit quand même réussir, sinon l'import échoue complètement (§5.5).
11. Ne place aucun dossier racine *arr au niveau de `/mnt/zurg/__magic__/__all__` ou au-dessus, si tu veux que le `DownloadClientRootFolderCheck` de Radarr reste silencieux (Sonarr ne vérifie que l'égalité exacte). Mets-les plutôt à côté du miroir : `/mnt/zurg/__magic__/tv`, `/mnt/zurg/__magic__/movies`. Ces dossiers n'ont aucun lien avec le dossier de sortie, ni au-dessus ni en dessous de lui.
12. `/mnt/zurg/__magic__/__all__` doit exister comme dossier **sur l'hôte Sonarr/Radarr**, pas seulement là où tourne l'émulateur, sinon `RemotePathMappingCheck` lève une erreur. Il n'a pas besoin d'être accessible en écriture.

## Configurer une fenêtre de complétion plus grande {#configuring-a-larger-completion-window}

Les deux clients ont 60 comme valeur par défaut pour `DownloadClientHistoryLimit`. zurg reprend cette fenêtre quand il garde les tâches terminées en trop dans `queue`. Si tu n'augmentes que la limite du client, certaines tâches apparaîtraient à la fois dans queue et dans l'historique, et c'est queue qui l'emporte.

Si tu as un gros retard, mets `sabnzbd.history_limit` dans zurg et `DownloadClientHistoryLimit` des clients à la même valeur, par exemple 500. Cela expose plus de tâches terminées et échouées à chaque interrogation. Si plusieurs clients utilisent des valeurs différentes, laisse zurg à la plus petite limite de client. Ce paramètre avancé du client n'est pas exposé dans la ressource API de configuration du client de téléchargement de Sonarr v4 ; sauvegarde et arrête le client avant de modifier sa configuration enregistrée.

```yaml
sabnzbd:
  enabled: true
  history_limit: 500
```

La valeur par défaut reste 60 ; zéro et les valeurs négatives utilisent cette valeur par défaut. Une requête de diagnostic sur l'historique avec une autre limite ne modifie jamais la fenêtre configurée. Les avertissements que le client ne peut pas résoudre demandent toujours une vérification ; une fenêtre plus grande permet aux autres tâches d'arriver jusqu'à l'import pendant que ces avertissements occupent des emplacements dans l'historique.

La vérification de disponibilité avant la fin du téléchargement examine les seize premiers articles et le dernier article de chaque fichier de contenu. Elle attrape un article manquant dans l'en-tête du média, que l'ancien canari du premier article ne détectait pas. Elle télécharge le premier article de chaque fichier de contenu, ce qui vérifie l'identité de l'article et que le corps est toujours servi (un fournisseur peut répondre à STAT pour un article dont il a retiré le corps), plus des articles tirés au hasard jusqu'à seize corps pour une release de moins de seize fichiers, et au maximum soixante-quatre corps au total ; un corps déjà présent dans le cache d'articles n'est pas téléchargé à nouveau. STAT couvre le reste de l'échantillon. Cela ne valide pas chaque article et ne prouve pas que le média se décode. Les requêtes STAT sont regroupées par fichier, pour que l'échantillon ne prenne qu'une réservation du pool au lieu de dix-sept, sans augmenter la limite de connexions du compte. Si un lot n'est pas utilisable, on revient à des STAT individuels.
Les échecs serveur laissent la tâche en file d'attente pour une nouvelle tentative ; les articles manquants confirmés produisent un téléchargement échoué avant la première notification de fin.
