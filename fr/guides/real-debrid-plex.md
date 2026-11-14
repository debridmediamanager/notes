# Une bibliothèque Real-Debrid dans Plex avec zurg {#a-real-debrid-library-in-plex-with-zurg}

zurg affiche tout ce qui se trouve dans votre compte Real-Debrid sous forme de dossiers sur votre ordinateur, déjà triés dans `movies` et `shows`. Ajoutez ces deux dossiers à Plex Media Server et toute votre bibliothèque Real-Debrid s'affiche dans toutes les applications Plex, diffusée depuis Real-Debrid sans rien télécharger au préalable. Vous installez zurg une seule fois ; il embarque son propre rclone, donc il n'y a rien d'autre à configurer.

Vous préférez ne pas faire tourner Plex Media Server ni monter un lecteur ? [rex avec zurg](../rex/with-zurg.md) montre la même bibliothèque aux applications Plex sans l'un ni l'autre.

## Ce dont vous avez besoin {#what-you-need}

- **Un parrainage.** La version nightly de zurg est réservée aux sponsors. Devenez sponsor sur [gatekeeper](https://gatekeeper.debridmediamanager.com/) et cela donne à votre compte GitHub accès au téléchargement. [Ce qu'apporte un parrainage](sponsorship.md) détaille le reste.
- **Un compte premium Real-Debrid** et son jeton API : [Votre jeton API Real-Debrid](real-debrid-api-token.md) indique où le trouver.
- **Plex Media Server sur le même ordinateur que zurg.** Plex lit les fichiers dans les dossiers de zurg, il doit donc pouvoir les voir. Ensuite, n'importe quelle application Plex peut lire les contenus.
- **Un ordinateur qui reste allumé** : Windows 10 ou 11, Linux, un Mac, ou une machine Linux avec Docker.

## 1. Installer zurg {#1-install-zurg}

Chaque page d'installation commence par un installateur d'une seule ligne. Quand il affiche `Choose one or more providers in priority order:`, tapez `1` pour Real-Debrid, puis collez votre token.

| Votre ordinateur | Installer avec | Votre bibliothèque apparaît dans |
|---|---|---|
| Windows | [zurg on Windows](../zurg/setup/windows.md) | `Z:\movies` et `Z:\shows` |
| Linux | [zurg on Linux](../zurg/setup/linux.md) | `/mnt/zurg/movies` et `/mnt/zurg/shows` |
| Mac | [zurg on macOS](../zurg/setup/macos.md) | `/Volumes/Zurg/movies` et `/Volumes/Zurg/shows` |
| Linux avec Docker | [Un seul fichier Docker Compose](../zurg/guides/docker-compose.md), qui fait tourner Plex Media Server à côté de zurg | `/zurg_mnt/zurg/movies` et `/zurg_mnt/zurg/shows` |

L'installateur se termine par `zurg doctor`, une liste de lignes `PASS`.

## 2. Vérifier les dossiers {#2-check-the-folders}

Ouvrez le dossier ou le lecteur de zurg. Vous devriez voir `movies`, `shows`, `__all__`, `__downloads__`, `__unplayable__` et `version.txt`.

Au tout premier démarrage, zurg lit l'intégralité de votre compte Real-Debrid. Tant que ce n'est pas terminé, les dossiers restent vides. Pour vérifier, ouvrez `http://localhost:9999/ready` dans un navigateur : il affiche `ready` une fois que votre bibliothèque est bien chargée.

## 3. Ajouter les dossiers dans Plex {#3-add-the-folders-in-plex}

Dans Plex Web, cliquez sur **Add Library**, le bouton à côté du nom de votre serveur dans la barre latérale :

1. Choisissez **Movies** puis cliquez sur **Next**.
2. Cliquez sur **Browse for media folder** et sélectionnez le dossier `movies` de zurg indiqué dans le tableau ci-dessus, par exemple `Z:\movies` sous Windows.
3. Cliquez sur **Add Library**.

Faites de même avec **TV Shows** et le dossier `shows`. Plex analyse ensuite les deux dossiers et récupère les affiches et les titres.

## 4. Laisser zurg prévenir Plex des nouveautés {#4-let-zurg-tell-plex-about-new-things}

Plex ne remarque pas quand un nouveau fichier arrive dans votre compte Real-Debrid. zurg peut le lui signaler. Ouvrez le tableau de bord de zurg à l'adresse `http://localhost:9999/config/`, allez dans **Media Server Integration** et cliquez sur **Login with Plex**. Connectez-vous à Plex et choisissez votre serveur.

![La section Media Server Integration du tableau de bord de zurg, avec le bouton Login with Plex](../assets/real-debrid-plex/01-zurg-login-with-plex.webp)

Ensuite, zurg demande à Plex de scanner chaque dossier qui change. Il désactive aussi quelques paramètres de Plex qui sont risqués pour une bibliothèque en streaming, comme **Empty trash automatically after every scan** : [Paramètres Plex recommandés](../zurg/guides/plex.md#recommended-plex-settings) les liste.

## Quand quelque chose ne va pas {#when-something-is-wrong}

| Ce que vous voyez | Ce qu'il faut faire |
|---|---|
| Plex ne trouve rien, ou les dossiers de zurg sont vides | zurg est encore en train de lire votre compte. Attendez que `http://localhost:9999/ready` affiche `ready`, puis relancez l'analyse dans Plex. |
| Sous Windows, il n'y a pas de lecteur `Z:`, ou Plex ne trouve pas `Z:\movies` | `Z:` appartient à votre session de bureau Windows, et l'installateur de zurg démarre zurg dans cette session à votre connexion. Un PowerShell ouvert en administrateur ne le voit pas non plus. [Quand quelque chose ne va pas sous Windows](../zurg/setup/windows.md#when-something-is-wrong) détaille chaque cas. |
| Sous Linux, Plex voit un dossier vide ou n'arrive pas à l'ouvrir, et `./zurg doctor` affiche `user_allow_other is not enabled in /etc/fuse.conf; the mount will be visible only to the zurg service user` | Plex tourne avec un autre utilisateur que zurg. Autorisez les autres utilisateurs avec <code>echo user_allow_other &#124; sudo tee -a /etc/fuse.conf</code>, puis lancez `./zurg service restart` dans le dossier de zurg. |
| Dans Docker, les bibliothèques de Plex se vident après un redémarrage de zurg, et `docker exec plex ls /zurg_mnt/zurg` affiche `Transport endpoint is not connected` | Donnez au conteneur de Plex le dossier de zurg avec `rslave` : `/zurg_mnt:/zurg_mnt:rslave`. [Un fichier Docker Compose complet](../zurg/guides/docker-compose.md) contient cette option. |
| De nouveaux éléments apparaissent dans les dossiers de zurg mais pas dans Plex | Faites l'étape 4. En attendant, appuyez sur **Scan Library Files** sur la bibliothèque dans Plex. |
| zurg affiche `bad_token` | Le jeton Real-Debrid est faux ou incomplet. [Votre jeton d'API Real-Debrid](real-debrid-api-token.md#when-something-is-wrong) explique la marche à suivre. |
| Votre disque se remplit | zurg garde une copie de ce que vous lisez, jusqu'à 256G par défaut. Limitez-la comme l'indiquent [Garder le cache petit](../zurg/setup/windows.md#keeping-the-cache-small) (Windows) ou [Espace disque utilisé par le montage](../zurg/setup/linux.md#disk-the-mount-uses) (Linux). |

Toujours bloqué ? Posez votre question dans le forum **zurg-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](remote-help.md) indique quoi inclure.

## Questions

### Existe-t-il un guide pour configurer DMM, zurg et rclone et streamer dans Plex ? {#is-there-a-guide-to-set-up-dmm-zurg-and-rclone-to-stream-in-plex}

Cette page. Vous n'installez pas rclone vous-même : l'installateur de zurg le télécharge et zurg le fait tourner. DMM sert à trouver des releases et à les ajouter à votre compte Real-Debrid ([Ce qu'est DMM et comment l'utiliser](../dmm/index.md)). zurg les affiche ensuite dans ses dossiers, et Plex les récupère.

### Les films se téléchargent-ils sur mon ordinateur ? {#do-the-movies-download-to-my-computer}

Non. Plex lit chaque fichier de Real-Debrid via zurg au moment où vous appuyez sur lecture. zurg garde un cache de ce qui a été lu, et celui-ci peut devenir gros : voir la ligne sur le disque ci-dessus.

### Puis-je me passer de Plex Media Server ? {#can-i-skip-plex-media-server}

Oui, avec rex. [rex avec zurg](../rex/with-zurg.md) affiche ta bibliothèque zurg dans les applications Plex, sans Plex Media Server et sans montage. Tu peux aussi faire tourner les deux : [Un seul fichier Docker Compose](../zurg/guides/docker-compose.md) fait tourner zurg, Plex Media Server et rex sur une même machine.

### Ça marche aussi avec TorBox ou Usenet ? {#does-it-work-with-torbox-or-usenet-too}

Oui. L'installateur de zurg propose aussi TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud et Usenet, et les range tous dans les mêmes dossiers `movies` et `shows`. [Fournisseurs](../zurg/providers/index.md) a une page pour chacun.
