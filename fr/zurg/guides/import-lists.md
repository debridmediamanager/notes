# Suivre une liste dans Sonarr et Radarr {#following-a-list-in-sonarr-and-radarr}

Sonarr et Radarr peuvent suivre une liste de séries ou de films. Chaque titre de la liste est ajouté et recherché. Avec zurg comme client de téléchargement, chaque récupération atterrit sur votre compte debrid et est importée dans `__magic__` comme les autres. Une liste est donc une section de bibliothèque complète qui se remplit toute seule. Une liste d'horreur vous donne une section horreur, et les nouveaux titres apparaissent au fur et à mesure que la liste s'allonge.

Cette page suppose que les \*arrs récupèrent déjà via zurg. Si ce n'est pas encore le cas, commencez par [Sonarr & Radarr pour les torrents](sonarr-radarr-torrents.md).

## Utilisez MDBList et non IMDb {#use-mdblist-and-not-imdb}

Les deux applications affichent encore un type de liste IMDb, mais aucune ne fonctionne plus avec une liste IMDb classique.

- Radarr refuse un ID de liste de la forme `ls12345678`. Il accepte seulement `top250`, `popular` ou une watchlist utilisateur `ur12345678`.
- Sonarr accepte l'ID, puis reçoit une réponse vide d'IMDb. Le bouton Test affiche `Imdb call resulted in an unexpected StatusCode [Accepted]`.

[MDBList](https://mdblist.com) permet de contourner ces deux problèmes. Il publie n'importe quelle liste sous forme de flux JSON que les deux applications lisent avec leur type de liste Custom. Les films et les séries sont sur des listes séparées, donc vous en ajoutez une à chaque application.

## 1. Choisir une liste {#1-pick-a-list}

Les listes publiques ne demandent pas de compte. Cherchez le genre qui vous intéresse sur MDBList et ouvrez une liste. Deux listes d'horreur qui fonctionnent en octobre 2026 :

| Liste | Contient | URL du flux |
|---|---|---|
| Horror | films | `https://mdblist.com/lists/garycrawfordgc/horror/json` |
| Horror Shows | séries | `https://mdblist.com/lists/garycrawfordgc/horror-shows/json` |

L'URL du flux, c'est l'URL de la page de la liste avec `/json` à la fin. Ouvrez-la d'abord dans un navigateur. Vous devriez voir une page de texte qui commence par `[{"id":`.

Pour créer votre propre liste, connectez-vous à MDBList et créez-en une. Elle peut suivre des filtres, comme un genre et une note minimale, ou copier une liste IMDb que vous avez déjà. L'URL du flux fonctionne de la même façon.

## 2. L'ajouter à Radarr {#2-add-it-to-radarr}

**Settings → Import Lists → + → Custom Lists**

| Field | Value |
|---|---|
| Name | ce que vous voulez, par exemple `Horror` |
| Enable | activé |
| Enable Automatic Add | activé |
| Search on Add | lisez d'abord l'avertissement ci-dessous |
| Monitor | Movie Only |
| Root Folder | votre dossier de films dans `__magic__`, par exemple `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` sur macOS, `Z:\__magic__\movies` sur Windows) |
| Quality Profile | celui que vous utilisez |
| List URL | l'URL du flux de films |

Appuyez sur **Test**, puis sur **Save**.

## 3. L'ajouter à Sonarr {#3-add-it-to-sonarr}

**Settings → Import Lists → + → Custom List**

| Champ | Valeur |
|---|---|
| Name | n'importe quoi, par exemple `Horror Shows` |
| Enable Automatic Add | activé |
| Monitor | All Episodes, ou Pilot Episode pour tester une série d'abord |
| Root Folder | ton dossier TV dans `__magic__`, par exemple `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` sous macOS, `Z:\__magic__\tv` sous Windows) |
| Quality Profile | celui que tu utilises |
| Series Type | Standard |
| Season Folder | activé |
| Search for Missing Episodes | lis d'abord l'avertissement ci-dessous |
| List URL | l'URL du flux de la série |

Appuie sur **Test** puis sur **Save**.

## Les grosses listes récupèrent tout d'un coup {#big-lists-grab-everything-at-once}

Une liste avec search on add activé récupère chaque titre dès qu'elle se synchronise. La liste de films ci-dessus contient 400 titres, et la liste de séries 148 séries avec tous leurs épisodes. Ça fait beaucoup de grabs d'un coup. Ton compte debrid et tes indexeurs vont le sentir, et un indexeur avec une limite de débit va commencer à refuser les recherches.

Il y a deux façons plus douces de procéder.

- Laisse search on add désactivé. Les titres sont ajoutés et surveillés, mais rien n'est recherché. Cherche ceux que tu veux depuis les pages Movies ou Series.
- Commence avec une petite liste. Ajoute la grosse une fois que le premier lot est arrivé.

Les apps synchronisent aussi les listes selon leur propre planning. **System → Tasks → Import List Sync** en lance une tout de suite.

## Supprimer une liste {#removing-a-list}

La suppression d'une liste empêche l'arrivée de nouveaux titres. Ce qui a déjà été ajouté reste en place. Sous **Settings → Import Lists**, le **Clean Library Level** détermine ce qui arrive aux titres qui sortent d'une liste. Laissez-le sur Disabled, sauf si vous voulez que les applications suppriment des éléments à votre place.
