# Listes de hash DMM : ajouter la bibliothèque de quelqu'un à la vôtre {#dmm-hash-lists-add-someones-library-to-yours}

Une hash list est une liste de releases qu'une personne a partagées depuis sa bibliothèque debrid via DMM. Ouvrez-en une, connectez-vous à DMM avec votre service debrid et appuyez sur le bouton de votre service : les releases sont ajoutées à votre propre compte. Les listes partagées se trouvent sur [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com), et vous pouvez partager la vôtre depuis **Library** dans DMM avec **Share List**.

Une liste contient les noms des releases, leurs hashes et leurs tailles. Aucun fichier et aucun compte.

## Trouver une liste {#find-a-list}

- Sur la page d'accueil de DMM, appuyez sur **Hash lists**. Cela ouvre [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com) avec une liste aléatoire. **Previous hash list**, **Random hash list** et **Next hash list** permettent de passer d'une liste à l'autre.
- Les gens publient des listes dans le forum **hashlists** sur [Discord](https://discord.com/invite/7u4YjMThXP). Chacune est un lien du type `https://hashlists.debridmediamanager.com/<id>.html`. En l'ouvrant, la liste s'affiche dans DMM.

## Ajouter une liste à votre bibliothèque {#add-a-list-to-your-library}

1. Ouvrez la liste. Si elle affiche **Login to RD/AD/TB/PM/OC/DL to download**, connectez-vous d'abord à [DMM](https://debridmediamanager.com) dans le même navigateur (voir [comment se connecter](index.md#sign-in)), puis rouvrez la liste.
2. DMM vérifie quelles versions votre service a déjà. Il n'affiche que celles-ci et laisse de côté ce qui se trouve déjà dans votre bibliothèque. La case verte **hidden** indique combien d'éléments ont été laissés de côté.
3. Affinez si vous le souhaitez :
   - **Movies** et **TV Shows** n'affichent qu'un type. Les chiffres comptent des titres, pas des fichiers.
   - **One per title** garde la meilleure version de chaque titre.
   - La puce verte **other files** à côté d'un titre affiche toutes ses versions.
   - **quick search on filename, hash, or id; supports regex** permet de chercher dans la liste.
4. Appuyez sur le bouton d'une ligne (**RD**, **TB**, **AD**, **PM**, **OC** ou **DL**) pour ajouter cette seule version.
5. Ou appuyez sur **RD Download** (**TB Download**, **PM Download** et ainsi de suite) pour ajouter toutes les versions affichées. Le chiffre sur le bouton indique leur nombre. DMM demande d'abord, par exemple **Add 11 releases to Premiumize?** : appuyez sur **Add 11** pour lancer.

![A shared hash list of open movies in DMM, signed in with Premiumize](../assets/dmm-hashlists/01-hash-list.webp)

**Show All** affiche aussi les versions que votre service n'a pas, et **Show Instant** revient aux versions en cache.

**RD Download** n'ajoute que les versions que Real-Debrid a déjà, une par minute, car Real-Debrid suspend les comptes qui ajoutent trop vite. Soixante versions prennent environ une heure. Les ajouts se font dans la page, donc gardez l'onglet ouvert jusqu'à ce qu'il affiche **Started 60 downloads.** TorBox et AllDebrid ignorent tout ce qui n'est pas en cache chez eux.

## Partager votre propre bibliothèque {#share-your-own-library}

1. Sur la page d'accueil de DMM, appuyez sur **Library**.
2. Recherchez ou cochez les versions que vous voulez partager. Si rien n'est coché, tout ce qui est affiché est partagé.
3. Appuyez sur **Share List** (le bouton affiche **Share (3)** si vous en avez coché trois). Saisissez un nom dans **Enter a title for the hash list** puis appuyez sur **OK**.
4. DMM ouvre la nouvelle adresse de votre liste sur hashlists.debridmediamanager.com. Elle peut afficher une erreur 404 pendant une minute ou deux, le temps de la publication. Actualisez la page, puis partagez cette adresse.

![The title prompt after pressing Share List](../assets/dmm-hashlists/02-share-list.webp)

Les listes partagées sont publiques. Toute personne qui possède l'adresse peut les ouvrir, et **Random hash list** peut montrer la vôtre à des inconnus. Seuls les noms, les hashes et les tailles sont inclus : jamais votre compte, votre clé ni une adresse de tracker.

Pour partager une seule version sans rien publier, appuyez sur l'icône de partage à la fin de sa ligne dans la bibliothèque (ou sur **Hashlist** dans ses détails). DMM ouvre une liste d'une seule version. Copiez l'adresse de cette page et envoyez-la.

## Quand quelque chose ne va pas {#when-something-is-wrong}

| Ce que vous voyez | Ce qu'il faut faire |
|---|---|
| **Login to RD/AD/TB/PM/OC/DL to download** | Vous n'êtes pas connecté à DMM dans ce navigateur. Connectez-vous, puis rouvrez la liste. |
| Tout est **hidden** et la liste semble vide | Les lignes masquées sont déjà dans votre bibliothèque, ou votre service ne les a pas. Appuyez sur **Show All**. |
| **This hash list is still being published; refresh in a minute or two.** | La liste vient d'être partagée. Attendez une minute ou deux, puis actualisez. |
| **0 files** et aucune ligne | Cette liste est vide. Appuyez sur **Next hash list** ou **Random hash list**. |
| **Everything already downloaded** | Toutes les versions affichées sont déjà dans votre bibliothèque. |
| **Torrent not instant in TorBox; skipped.** ou **Torrent not instant in AD; skipped.** | Votre service n'a pas ce torrent en cache, donc DMM l'a ignoré au lieu de lancer un téléchargement. |
| **Skipping 3 items with no info hash — they cannot be shared.** | Ces lignes (les téléchargements web de TorBox, par exemple) n'ont pas de hash à partager. Le reste de la liste est partagé. |
| **Failed to generate hash list; try again soon.** | La publication de la liste a échoué. Réessayez plus tard. |

Vous bloquez ? Posez votre question dans le forum **dmm-support** sur [Discord](https://discord.com/invite/7u4YjMThXP).

## Questions

### Comment ajouter des listes de hash à ma propre bibliothèque ? {#how-do-i-add-hash-lists-to-my-own-library}

Ouvrez la liste, connectez-vous à DMM avec votre service debrid, puis appuyez sur le bouton de votre service sur une ligne, ou sur **RD Download** (ou **Download** de votre service) pour tout ce qui est affiché. Voir [Add a list to your library](#add-a-list-to-your-library).

### Pourquoi tous les éléments de ma liste de hash sont-ils masqués ? {#why-are-all-the-items-in-my-hash-list-hidden}

DMM masque ce qui est déjà dans ta bibliothèque et ce que ton service n'a pas en cache. La case **hidden** indique combien il y en a. **Show All** affiche le reste.

### Pourquoi les séries TV n'apparaissent-elles pas dans une liste de hash ? {#why-dont-tv-shows-show-up-in-a-hash-list}

Cliquez sur **TV Shows** en haut de la liste. Si elle affiche **0 TV Shows**, cette liste ne contient aucune série : la plupart des listes partagées sont des films. Les séries que votre service n'a pas sont aussi masquées, alors essayez **Show All**.

### Pourquoi l'ajout d'une liste de hash est-il si lent ? {#why-is-adding-a-hash-list-so-slow}

Sur Real-Debrid, DMM ajoute une version par minute pour que Real-Debrid ne suspende pas votre compte. Les autres services vont plus vite.

### Existe-t-il une API pour interroger les listes de hash ? {#is-there-an-api-to-query-the-hash-lists}

Il n'y a pas d'API de recherche. Chaque liste partagée est un fichier dans le [dépôt hashlists public](https://github.com/debridmediamanager/hashlists) sur GitHub. Chaque page pointe vers DMM avec la liste intégrée au lien après `#` (JSON compressé avec lz-string, contenant les noms, les hash et les tailles). Une très grande liste se trouve à côté, sous forme de `lists/<id>.txt`.

### Le partage d'une liste partage-t-il mon compte ? {#does-sharing-a-list-share-my-account}

Je n'ai pas encore de texte à traduire. Pourriez-vous me envoyer la page ou le passage en anglais ?
