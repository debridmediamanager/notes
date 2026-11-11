# Passer de Plex à rex {#move-from-plex-to-rex}

Vous faites tourner Plex Media Server et vous voulez essayer rex. Vos applications Plex restent les mêmes. La source de la bibliothèque et l'adresse du serveur, elles, changent.

## Ce qui change {#what-changes}

| | Plex Media Server | rex |
|---|---|---|
| Where the library comes from | Plex scans folders on a disk or a mount | A source (your own app, rex-stremio or zurg) tells rex what it has. rex never scans a folder and needs no mount |
| What each file is | Plex matches it from its file name | The source works it out and tells rex. rex never reads a file name |
| A wrong match | Fix Match on the server | **Fix Match** in a Plex app, signed in as the account that owns rex. rex keeps your pick, and a source can take it back and keep it, as zurg does ([why titles are placed as they are](with-zurg.md#why-dmm-places-the-files)) |
| The account the server is on | Usually your own | A fresh Plex account made for rex, shared with your own |
| Music, Live TV and photos | From folders and a tuner | Only from a source that sends them, such as an addon ([Building rex addons](addons.md#music)) or zurg's comic books. Plex Web shows photos; Plex for Android does not |
| Recording TV | Yes | No |

## Choisir une méthode {#pick-a-way}

| | À côté de Plex | À la place de Plex |
|---|---|---|
| Ce que tu obtiens | rex à côté de ton Plex. Tes applis affichent les deux serveurs | rex seul, sur le port habituel de Plex |
| Idéal pour | Tester rex, garder Plex pour les photos ou la musique sur un disque, ou pour enregistrer la TV | Passer définitivement à rex |
| Sur la même machine que Plex | rex tourne sur le port `32500`, et tes applis le trouvent via le compte Plex avec lequel il est partagé | Plex est arrêté, rex prend le port `32400` et les applis à la maison le trouvent toutes seules |

Commence à côté de Plex, même si tu comptes le remplacer : copier ton historique de visionnage nécessite que ton ancien serveur Plex tourne. Fais les étapes 1 à 3, utilise rex un moment, et fais l'étape 4 quand tu es prêt.

## Étape 1. Installer rex à côté de Plex {#step-1-set-up-rex-beside-plex}

Configure rex avec la source qui va le remplir, comme dans [rex avec ta propre app](any-source.md), [rex avec tes addons Stremio](stremio.md) ou [rex avec zurg](with-zurg.md), jusqu'à regarder quelque chose. Tu fais déjà tourner zurg pour Plex ? Passe l'installation et mets-le à jour comme l'étape 1 de rex avec zurg le montre : zurg alimente rex à partir de la nightly **2026.10.27**.

- **Plex tourne sur la même machine ?** Mets rex sur le port `32500`, comme l'indique [Installer rex](any-source.md#step-1-install-rex) pour ce cas, et donne ce port aussi à ta source. Tes applis affichent alors deux serveurs avec le nom de la machine : rex est celui partagé avec toi, avec le nom du nouveau compte à côté. [Installer rex](any-source.md#step-1-install-rex) explique comment le renommer.
- **Enregistre rex sur un compte Plex neuf,** pas celui sur lequel ton serveur Plex est, comme l'explique [Ajouter rex à un compte Plex](any-source.md#step-3-add-it-to-a-plex-account).
- **Loin de chez toi avec rex-direct ?** Le port 32400 de ton routeur mène déjà à Plex. Redirige aussi le port `32500` vers la machine rex, ou, [en IPv6](any-source.md#rex-direct-over-ipv6), autorise `32500` à atteindre cette machine.

Tu utilises zurg ? Tant que les deux tournent, zurg alimente les deux. Laisse tout ce que zurg a pour Plex tel quel (`plex_server_url`, `plex_token`, ton montage rclone et ton éventuel script de scan) : Plex continue de fonctionner comme avant, et `rex_url` ajoute rex.

## Étape 2. Reprendre votre historique de visionnage {#step-2-bring-your-watch-history}

Une fois ta bibliothèque dans rex, [importe ton historique de visionnage](import-watched.md) : il copie ce que tu as regardé, l'endroit où tu t'es arrêté et tes notes en étoiles depuis ton serveur Plex. Fais-le pendant que Plex tourne encore. Chaque personne avec qui tu partages le fait pour son propre historique.

## Étape 3. Réinviter vos proches {#step-3-invite-your-people-again}

Tes amis et ta famille ont été invités sur ton serveur Plex, pas sur rex. rex est un nouveau serveur, sur le nouveau compte, donc invite-les depuis là et ils acceptent comme pour n'importe quel partage : [Partager rex avec la famille et les amis](sharing.md).

## Étape 4. Mettre Plex à la retraite (facultatif) {#step-4-retire-plex-optional}

Seulement pour remplacer Plex. Ignore cette partie pour garder les deux.

**Arrête Plex pour de bon.** Sous Linux, `sudo systemctl disable --now plexmediaserver`. Avec Docker, arrête son conteneur et retire-le de ton fichier compose. Sous Windows et macOS, quitte Plex Media Server et retire-le des applications qui démarrent à la connexion.

**Déplace rex sur le port 32400** s'il était sur `32500`, à côté de Plex sur la même machine :

1. Retire `--port 32500` de la commande de démarrage de rex (ou de la ligne `command:` en Docker) et redémarre rex, comme le montre [Installer rex](any-source.md#step-1-install-rex) pour ton système. Sous Windows, laisse passer le port 32400 et les deux ports de découverte à travers le pare-feu, comme dans cette étape.
2. Donne à ta source la nouvelle adresse de rex, `http://192.168.1.20:32400` (IP LAN de rex), et redémarre-la : `rex_url` dans zurg, ou **rex's address** dans la page de réglages de rex-stremio.
3. Remplace `32500` par `32400` partout où tu as donné l'adresse de rex, par exemple dans Kometa.
4. Avec rex-direct, fais pointer la redirection du port 32400 de ton routeur vers la machine de rex et supprime celle du `32500`. En IPv6, change la règle du pare-feu de `32500` à `32400` et redémarre rex, pour qu'il propose son IPv6 sur le nouveau port.

rex répond alors sur le port 32400, et les applis Plex à la maison le trouvent toutes seules sur ton réseau.

**Tu utilises zurg ? Nettoie ses réglages Plex.** La config de zurg pointe peut-être encore vers le Plex que tu as arrêté :

| Dans `config.yml` de zurg | Quoi faire |
|---|---|
| `plex_server_url` et `plex_token` | Supprime les deux, ou appuie sur **Remove** à côté de Plex sur le tableau de bord de zurg (page de config, **Media Server Integration**). Tu utilises la [liste de suivi Plex](../zurg/guides/plex-watchlist.md) de zurg ? Supprime seulement `plex_server_url` : la liste est lue sur plex.tv avec `plex_token` et n'a pas besoin de serveur Plex. Tu peux aussi les faire pointer vers rex : appuie sur **Re-Auth** là, connecte-toi avec le nouveau compte et choisis rex. zurg 2026.10.27 et plus récent voit que le serveur est rex et ne lui envoie ni scans, ni correspondances Plex, ni corrections de saison, ni vérifications des réglages Plex. Le token est alors celui du nouveau compte, donc une liste de suivi Plex suivrait ce compte |
| `on_library_update` lançant un scan Plex, comme `plex_update.sh` | Supprime-le. rex est prévenu de chaque changement directement par zurg |
| `plex_database_path`, `plex_scan_check_url` et `plex_scan_check_token` | Supprime-les. Ils désignent le Plex que tu as arrêté |
| Ton montage rclone (`rclone_enabled: true`, ou rclone que tu lances toi-même) | Garde-le si Sonarr, Radarr, Bazarr ou autre chose lit les fichiers là-bas. Si Plex était le seul lecteur, tu peux le désactiver : rex lit chaque fichier directement depuis zurg |

Redémarre zurg après avoir modifié sa config.

## Ce qui est transféré et ce qui ne l'est pas {#what-comes-along-and-what-does-not}

| Vient avec | Comment |
|---|---|
| Vos films et séries | Votre source les envoie à rex. Avec zurg, ils viennent du même compte debrid que Plex lit |
| Ce que vous avez regardé, où vous vous êtes arrêté, vos notes sur les films et épisodes | [Importez votre historique de visionnage](import-watched.md), chaque personne de son côté |

| Ne vient pas | Pourquoi |
|---|---|
| Les correspondances corrigées sur Plex | rex n'utilise pas les correspondances de Plex. Votre source indique ce que contient chaque fichier ; corrigez ce qui est faux avec **Fix Match** dans rex |
| Collections | Non copiées. [Kometa avec rex](kometa.md) les recrée à partir de votre config Kometa |
| Affiches et illustrations que vous avez choisies | Restent uniquement sur l'ancien serveur |
| Listes de lecture, et la liste d'historique de lecture du serveur | Restent uniquement sur l'ancien serveur |
| Les accès de vos amis | Ils ont été invités sur l'ancien serveur. Invitez-les sur rex ([étape 3](#step-3-invite-your-people-again)) |
| Musique et photos sur un disque, TV en direct depuis un tuner, et enregistrements | rex n'a pas de tuner et n'enregistre rien ; la musique, les photos et les chaînes en direct viennent uniquement d'une source qui les envoie. Gardez Plex à côté de rex pour ces contenus |
| Fichiers sur un disque local | rex ne scanne aucun dossier. Une application doit les servir et les signaler à rex : [rex avec votre propre application](any-source.md) |
