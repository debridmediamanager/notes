# Importer votre historique de visionnage dans rex {#bring-your-watch-history-to-rex}

rex démarre sans historique de visionnage. Il peut copier les titres vus, les points de reprise et les notes d'étoiles depuis un autre serveur Plex.
Les titres vus restent vus. Les titres partiellement vus reviennent dans **Continue Watching**. Les séries et les saisons recomptent leurs épisodes.

Lancez-le une fois depuis n'importe quel ordinateur à la maison. Chaque personne qui utilise rex peut importer son propre historique.

## Avant de commencer {#before-you-start}

| Vous avez besoin de | Pourquoi |
|---|---|
| rex installé, avec votre bibliothèque dedans, comme dans [rex avec votre propre application](any-source.md), [rex avec vos addons Stremio](stremio.md) ou [rex avec zurg](with-zurg.md) | rex ne copie l'historique que sur les titres qu'il a déjà. Si votre bibliothèque est encore en cours de remplissage, relancez l'import plus tard : il n'ajoute que ce qui est nouveau |
| rex nightly **2026.10.31 ou plus récent** | Mettez à jour comme dans la section [Updating de rex](any-source.md#updating) |
| Votre ancien serveur Plex, en marche | rex lit l'historique depuis lui. Redémarrez-le si vous l'avez arrêté lors de votre passage à rex |
| Un ordinateur sur votre réseau local, avec `curl` | L'import ne fonctionne que depuis votre réseau local. Windows 10 et 11, macOS et Linux ont tous `curl` |

## 1. Copiez l'adresse de votre ancien serveur {#1-copy-your-old-servers-address}

1. Ouvrez [app.plex.tv](https://app.plex.tv) dans un navigateur et connectez-vous en tant que **vous-même**, avec le compte dont vous voulez récupérer l'historique.
2. Choisissez votre ancien serveur et ouvrez n'importe quel film dessus.
3. Cliquez sur **⋯** (More), puis sur **Get Info**.
4. Cliquez sur **View XML** en bas à gauche de la boîte **Media Info** qui s'ouvre. Un nouvel onglet s'ouvre, plein de texte.

   ![La boîte Media Info qu'ouvre Get Info, avec View XML en bas à gauche](../assets/rex/40-plex-get-info.webp)
5. Copiez **l'adresse complète** depuis la barre d'adresse de cet onglet.

Elle ressemble à ceci, tout sur une seule ligne, et elle se termine par `X-Plex-Token=` suivi d'un code :

```
https://192-168-1-5.0123456789abcdef.plex.direct:32400/library/metadata/1234?checkFiles=1&includeAllConcerts=1&X-Plex-Token=AbCdEfGh1234567890xy
```

Ce code est votre **Plex token** pour ce serveur. Il fonctionne comme un mot de passe pour votre compte Plex : ne le collez jamais dans Discord, dans un message d'aide ou dans une capture d'écran.

**Pas de View XML à l'étape 4 ?** Plex Web ne l'affiche que pour un serveur que vous possédez, donc un serveur qu'on a partagé avec vous n'en a pas. Utilisez plutôt les outils de développement du navigateur sur votre ancien serveur, comme à l'[étape 2](#2-get-your-token-on-rex), et choisissez une requête vers votre ancien serveur (son adresse contient `plex.direct`). Faites un clic droit dessus et copiez son adresse : **Copy**, **Copy URL** dans Chrome et Edge, **Copy Value**, **Copy URL** dans Firefox. Cette adresse est celle qu'il vous faut. Elle contient `X-Plex-Token=` et le code, parmi d'autres éléments `X-Plex-` : collez le tout.

## 2. Récupérez votre token sur rex {#2-get-your-token-on-rex}

rex est partagé avec vous, donc **Get Info** sur rex n'affiche pas **View XML** : Plex Web ne le montre qu'au propriétaire d'un serveur. Lisez plutôt le jeton dans votre navigateur, tel qu'app.plex.tv l'envoie à rex :

1. Dans app.plex.tv, toujours connecté avec votre compte, ouvrez les outils de développement du navigateur : **F12**, ou **⌥ ⌘ I** sur Mac. Dans Safari, activez d'abord **Show features for web developers** dans **Settings**, **Advanced**.
2. Ouvrez l'onglet **Network** et tapez `X-Plex-Token` dans son champ de filtre.
3. Ouvrez un film quelconque sur le serveur **rex**. La liste se remplit de requêtes.
4. Cliquez sur une requête dont l'adresse est celle de rex : en rex-direct, elle contient `rex-direct.debridmediamanager.com`, ou c'est l'adresse HTTPS que vous avez configurée vous-même. Pas une requête vers `plex.tv`.
5. Copiez la valeur de `X-Plex-Token` : Chrome et Edge l'affichent sous **Payload**, Firefox sous **Request**. Vous pouvez aussi copier l'adresse de la requête et prendre la partie après `X-Plex-Token=`, jusqu'au prochain `&`.

Ce n'est pas le même code que celui de l'étape 1 : chaque serveur donne à votre compte le sien. rex l'utilise pour savoir à qui appartient l'historique.

## 3. Lancez l'import {#3-run-the-import}

Sur un ordinateur chez toi, lance ceci en y collant tes deux valeurs.

```bash
curl -d "ADDRESS-FROM-STEP-1" "http://192.168.1.20:32400/rex/import-watched?X-Plex-Token=TOKEN-FROM-STEP-2"
```

`192.168.1.20` représente l'IP LAN de rex, comme dans les guides d'installation : mets la tienne à sa place.

Sous Windows, ouvre **PowerShell** et tape `curl.exe` au lieu de `curl`. Garde les deux paires de guillemets doubles : l'adresse de l'étape 1 contient des caractères `&`, qui cassent la commande sans eux.

Ça prend quelques secondes, plus pour une grosse bibliothèque : rex lit chaque film et chaque épisode sur l'ancien serveur.

**Ce que tu dois voir.** Une ligne comme celle-ci :

```json
{"watched":412,"inProgress":7,"rated":38,"alreadyHere":0,"notInRex":55}
```

| Nombre | Signification |
|---|---|
| `watched` | Titres que rex a marqués comme vus, avec le nombre de lectures et la date de l'ancien serveur |
| `inProgress` | Titres que tu avais commencés à moitié : ils reprennent là où tu t'étais arrêté |
| `rated` | Titres qui ont reçu leur note en étoiles |
| `alreadyHere` | Titres que tu avais déjà vus ou commencés sur rex. rex garde ce qu'il a et ne change rien là-dessus |
| `notInRex` | Titres pour lesquels l'ancien serveur a un historique que rex n'a pas, ou pas sous le même titre |

Rouvre ton application Plex (ou recharge app.plex.tv) pour le voir.

## Relancez-le quand vous voulez {#run-it-again-any-time}

Relancer la commande ne change rien à ce que vous avez déjà, donc lancez-la chaque fois qu'une partie de votre bibliothèque supplémentaire est arrivée. Une seconde exécution juste après la première affiche `"watched":0` et les précédents sous `alreadyHere`.

## Ce qui n'est pas copié {#what-is-not-copied}

- L'historique des autres personnes de ton ancien serveur. Chaque personne lance l'import avec ses propres deux tokens.
- La liste d'historique de lecture du serveur, les playlists et les collections.
- Les notes en étoiles sur les séries et les saisons entières. Les notes sur les films et les épisodes sont copiées.
- Les titres d'une bibliothèque dont l'agent sur l'ancien serveur n'est pas **Plex Movie** ou **Plex TV Series** (les anciens agents, comme Plex Movie (Legacy) et TheTVDB). rex retrouve un titre grâce à l'id que les agents actuels de Plex lui donnent, et les anciens lui en donnent un autre. Ces titres sont donc comptés sous `notInRex`.

## Si ça ne fonctionne pas {#if-it-does-not-work}

| Ce que tu vois | Quoi faire |
|---|---|
| `that address has no X-Plex-Token: copy it whole from the tab View XML opens` | L'adresse collée s'arrête avant le token. Copie-la à nouveau, depuis la barre d'adresse ou les outils de développement, et colle-la en entier |
| `send the address View XML opens on your old Plex server, starting http:// or https://` | Autre chose que l'adresse a été mise entre les guillemets après `-d` |
| `... refused the token: copy the address from View XML again` | L'ancien serveur n'a pas accepté le token. Refais l'étape 1, avec les outils de développement si le serveur est partagé avec toi |
| `could not reach https://...` | rex n'a pas pu se connecter à ton ancien serveur. Il doit être lancé, et **la machine de rex** doit pouvoir l'atteindre : c'est rex qui lit depuis lui, pas ton ordinateur |
| `run the import from your home network` | Tu as envoyé la commande à l'adresse externe de rex. Utilise l'IP locale de rex (LAN), comme à l'étape 3 |
| Une page `Unauthorized` | rex n'a pas accepté le token de l'étape 2. Copie-le à nouveau, depuis une requête vers rex, et non vers `plex.tv` |
| `notInRex` est beaucoup plus élevé que prévu | La plus grande partie de ta bibliothèque n'est pas encore dans rex, ou ton ancienne bibliothèque utilise un des anciens agents de Plex. Relance l'opération une fois ta bibliothèque arrivée |

Toujours bloqué ? Demande sur le forum **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) indique ce qu'il faut inclure.
