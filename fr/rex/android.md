# rex pour Android {#rex-for-android}

rex est un serveur média pour les applications Plex qui ne possède aucun fichier. rex pour Android le fait tourner sur un téléphone, une tablette, Android TV, Google TV ou Fire TV, sans ordinateur. Les applications Plex de vos appareils le trouvent comme n'importe quel serveur Plex et lisent depuis lui.

Ce qu'il lit provient d'**addons**. Il commence avec les films du domaine public de l'Internet Archive. D'autres addons, comme vos addons Stremio, YouTube et Spotify, s'installent depuis l'application une fois que vous ajoutez leur dépôt.

rex pour Android est gratuit. Vous voulez aussi y intégrer vos comptes debrid et Usenet ? zurg+rex, un serveur Plex sur votre téléphone avec zurg intégré, est proposé avec un système de parrainage : voir [zurg+rex pour Android](../zurg/guides/android.md).

## Avant de commencer {#before-you-start}

| Il vous faut | Pourquoi |
|---|---|
| Un appareil Android 8.0 ou plus récent | Téléphone, tablette, Android TV, Google TV ou Fire TV. Les Fire TV sous Vega OS, comme la Fire TV Stick 4K Select, n'exécutent aucune application Android |
| Un compte Plex | rex apparaît dans les applications Plex connectées à ce compte. Un compte gratuit suffit |
| Une application Plex sur l'appareil que vous utilisez pour regarder | Plex pour Android, Android TV, iPhone, une smart TV, Plex Web, Plexamp |

## Étape 1. Installer l'application {#step-1-get-the-app}

Choisissez une seule façon. Chacune met rex à jour à sa manière.

| Façon | Idéal pour |
|---|---|
| Google Play | Téléphones, tablettes, Android TV et Google TV. Bientôt disponible |
| [Amazon Appstore](https://www.amazon.com/dp/B0HRQM5GGW) | Fire TV et tablettes Fire |
| [Obtainium](#with-obtainium) | Téléphones et tablettes. Il vous prévient quand une mise à jour sort |
| [Downloader](#with-downloader-on-fire-tv) | Fire TV et boîtiers TV |
| [Le fichier depuis GitHub](#the-file-from-github) | Tous les appareils. Vous installez les mises à jour vous-même |

**Les façons ne se mélangent pas.** Google Play, l'Amazon Appstore et le fichier depuis GitHub (que Obtainium et Downloader installent aussi) sont signés différemment, donc l'une ne peut pas mettre à jour une autre. Pour changer, désinstallez rex, refaites les étapes 2 et 3, puis réinstallez vos addons.

**Elles ne démarrent pas avec les mêmes addons.** Le fichier depuis GitHub démarre avec le dépôt [rex-addons](https://github.com/debridmediamanager/rex-addons) déjà ajouté. Les versions du store commencent uniquement avec l'addon Internet Archive ; ajoutez rex-addons vous-même (voir [Modules complémentaires](#addons)) si vous le voulez.

### Avec Obtainium {#with-obtainium}

[Obtainium](https://obtainium.imranr.dev/) installe des applications depuis GitHub et les tient à jour.

1. Installe Obtainium et ouvre-le une fois.
2. Sur le même appareil, ouvre [rex.debridmediamanager.com/obtainium](https://rex.debridmediamanager.com/fr/obtainium). Obtainium s'ouvre et demande **Import app**. Appuie sur **Continue**.
3. Appuie sur **rex**, puis sur **Install**. Obtainium choisit le fichier adapté au processeur de ton appareil.
4. La première fois, Android ouvre **Install unknown apps** pour Obtainium. Active **Allow from this source** puis reviens en arrière.
5. Appuie sur **Install**. Si Play Protect affiche **App scan recommended**, appuie sur **Scan app**, puis sur **Install**.

Quand une nouvelle version sort, Obtainium affiche **Update** à côté de rex.

### Avec Downloader sur Fire TV {#with-downloader-on-fire-tv}

1. Sur le Fire TV, installe **Downloader** de AFTVnews depuis l'Appstore.
2. Ouvre-le, sélectionne la zone d'adresse et tape le code `6291659` (ou `rex.debridmediamanager.com/tv`). Appuie sur **Next**. Il télécharge `rex-android-armeabi-v7a.apk`.
3. Appuie sur **Install**. La première fois, le Fire TV ouvre **Developer options** à la place. Sélectionne **Install unknown apps**, puis **Downloader** pour que ça affiche **ON**. Appuie deux fois sur Retour et appuie à nouveau sur **Install**.
4. Appuie sur **Install**, puis sur **Open**.

Pour mettre à jour, refais les étapes 2 à 4.

### Le fichier depuis GitHub {#the-file-from-github}

Sur l'appareil, téléchargez le fichier correspondant à son processeur. Chaque lien pointe toujours vers la dernière version :

| Votre appareil | Téléchargement |
|---|---|
| La plupart des téléphones, tablettes et boîtiers TV (64 bits) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| Fire TV, et les boîtiers 32 bits plus anciens ou moins chers | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| Émulateurs sur un PC | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

Toutes les versions et leurs modifications sont sur [la page des versions](https://github.com/debridmediamanager/rex-android/releases). Vous ne savez pas ? Essayez d'abord `arm64-v8a`. Un seul fichier fonctionne sur les téléphones comme sur les TV.

Ouvrez le fichier téléchargé. Android indique qu'il **n'est pas autorisé à installer des applications inconnues depuis cette source**. Appuyez sur **Settings**, activez **Allow from this source**, revenez en arrière et appuyez sur **Install**.

Pour mettre à jour, installez le nouveau fichier par-dessus l'ancien. rex redémarre tout seul et votre connexion ainsi que vos addons restent en place.

**Ce que vous devriez voir.** **rex** dans votre liste d'applications.

## Étape 2. Lancer rex {#step-2-start-rex}

Ouvrez **rex**. Le premier écran affiche **Welcome to rex.**

1. Appuyez sur **Allow notifications**, puis sur **Allow**. rex fonctionne en arrière-plan avec une notification qui permet de l'arrêter.
2. Appuyez sur **Let rex keep running in the background**. Dans la liste qui s'ouvre, choisissez **rex** puis **Don't optimize**. Sur les versions récentes d'Android, il s'agit de **Allow background usage**, puis **Unrestricted**. Revenez dans rex. Les deux boutons commencent maintenant par un ✓.
3. **Name** est le nom que les applications Plex affichent pour ce serveur. Modifiez-le si vous le souhaitez.
4. Laissez **Port** sur `32400`. Si un autre serveur Plex tourne déjà sur cet appareil, rex affiche **Another app here already uses this port, maybe a Plex server. Try 32500.** Saisissez `32500`.
5. Appuyez sur **Start rex**.

**Ce que vous devez voir.** **2 / 2** et **Sign in to Plex.**

| Le premier écran | La page du film dans l'application Plex (étape 4) |
|---|---|
| ![Le premier écran de rex pour Android, avec les champs de nom et de port et le bouton Start rex](../assets/rex/android-setup.webp) | ![Un film muet de 1916 de l'Internet Archive sur sa page dans Plex pour Android](../assets/rex/android-plex-film.webp) |

## Étape 3. Se connecter à Plex {#step-3-sign-in-to-plex}

Appuyez sur **Sign in to Plex**. rex affiche un code : **On any phone or computer, go to plex.tv/link and enter** it.

- **Sur un téléphone ou une tablette**, votre navigateur ouvre aussi une page Plex indiquant **rex for Android would like to sign in to your Plex account**. Connectez-vous là.
- **Sur une TV**, allez sur [plex.tv/link](https://plex.tv/link) depuis votre téléphone ou votre ordinateur, connectez-vous et saisissez le code.

Utilisez le compte avec lequel vos applications Plex sont connectées. Vous pouvez appuyer sur **Skip for now** et vous connecter plus tard depuis **Status**.

![rex for Android sur une TV affichant le code à saisir sur plex.tv/link](../assets/rex/android-tv-signin.webp)

**Ce que vous devriez voir.** **Signed in. rex shows up in the Plex apps as** suivi du nom de votre serveur. Appuyez sur **Done**. **Status** affiche **RUNNING** et **Ready for the Plex apps.**

## Étape 4. Regarder dans une application Plex {#step-4-watch-in-a-plex-app}

Ouvrez n'importe quelle application Plex connectée au même compte. Si Plex est sur cet appareil, **Status** affiche un bouton **Open Plex**.

Dans Plex pour Android, ouvrez **Libraries**, puis **All Libraries**, puis **Movies** sous le nom de votre serveur. Les autres applications Plex affichent aussi la bibliothèque sous le nom du serveur.

La première synchronisation d'Internet Archive prend un moment : environ une demi-heure sur notre appareil de test, le temps que rex vérifie chaque film. **Status** affiche **Syncing** jusqu'à la fin, puis le nombre, comme **Ready · 97 titles**. Lancez la lecture de n'importe quel film.

![L'application Plex sur une TV lisant un court métrage de Chaplin de 1914 provenant de rex sur la même TV](../assets/rex/android-tv-playing.webp)

## Modules complémentaires {#addons}

**Addons** liste ce que vous avez installé. Chacun affiche ses titres et la date de sa dernière synchronisation. Ses boutons sont **Sync now**, **Settings**, **Log** et **Remove** ; sur téléphone, faites glisser la rangée de boutons vers la gauche ou la droite pour tous les voir. L'interrupteur **Enabled** désactive un addon sans le supprimer.

Les addons viennent de **repositories** : des dépôts git qui contiennent des addons. L'addon Internet Archive est déjà installé. Pour en avoir davantage, ajoutez [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons) (voir **Add a repository** plus bas), qui propose :

| Addon | Ce qu'il apporte |
|---|---|
| Stremio addons | Les catalogues de films et de séries de vos addons Stremio, lus à partir des flux fournis par vos addons de flux |
| YouTube | Vos playlists YouTube. Vous vous connectez avec un code |
| Spotify | Votre bibliothèque Spotify sous forme de musique pour Plex et Plexamp. Nécessite l'addon YouTube, connecté |

**Installer un addon.** Sous **Repositories**, appuyez sur **Addons** à côté d'un repository, puis sur **Install** sous l'addon. rex affiche les sites web auxquels il peut accéder et vous demande une dernière fois confirmation, puis lance la synchronisation.

**Se connecter.** Un addon qui a besoin de votre compte affiche **Sign in to start.** Appuyez sur son bouton **Sign in** : rendez-vous sur la page indiquée sur n'importe quel appareil et saisissez le code affiché.

**Ajouter un repository.** Sous **Add a repository**, tapez son lien (`github.com/user/repo` suffit) et appuyez sur **Add**. N'installez que des addons de personnes en qui vous avez confiance. Pour écrire votre propre addon, consultez [rex-addons](https://github.com/debridmediamanager/rex-addons).

## Regardez sur d'autres appareils à la maison {#watch-on-other-devices-at-home}

Chaque application Plex connectée au même compte trouve rex sur votre réseau domestique grâce à son nom : votre téléviseur, un autre téléphone, Plex Web sur un ordinateur. **Status** affiche l'adresse de rex à la maison, comme `http://192.168.1.20:32400`.

Pour permettre à votre famille de regarder avec son propre compte Plex, consultez [Partager rex avec la famille et les amis](sharing.md).

## Gardez-le en marche {#keep-it-running}

- rex tourne tant que l'appareil est allumé. La notification **Stop** l'arrête ; **Status** propose **Start**, **Stop** et **Restart**.
- Dans **Settings**, activez **Start when this device turns on**. Sinon, ouvrez rex et appuyez sur **Start** après un redémarrage.
- Certains téléphones arrêtent encore les applis en arrière-plan. [Don't kill my app](https://dontkillmyapp.com/) explique ce dont la vôtre a besoin.
- Pour renommer le serveur, ouvrez **Settings**, **General** dans une appli Plex et modifiez **Friendly name**.

## Limites {#limits}

- **Ça marche à la maison.** En dehors de chez vous, les applis Plex ont besoin d'une adresse HTTPS qui atteint l'appareil, ce qui demande une redirection de port sur votre routeur vers celui-ci. Voir [Utiliser depuis l'extérieur de chez vous](any-source.md#use-it-outside-your-home-optional).
- **L'appareil est le serveur.** Gardez-le allumé, en Wi-Fi ou en Ethernet, et branché. Convertir une vidéo pour un lecteur qui ne sait pas la lire utilise le matériel de l'appareil lui-même, et ça peut être lent sur un petit boîtier bon marché.
- **Uniquement ce que fournissent les addons.** Il n'y a pas de bibliothèque de fichiers sur l'appareil lui-même.

## Dépannage {#troubleshooting}

| Ce que vous voyez | Que faire |
|---|---|
| **App not installed as app isn't compatible with your phone.** | Vous avez choisi le mauvais fichier pour le processeur. Essayez l'autre fichier du tableau sous [Le fichier depuis GitHub](#the-file-from-github) |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | Tapez `32500` comme port |
| **Use a number from 1024 to 65535** | Le port doit être un nombre compris dans cette plage |
| Le serveur n'apparaît pas dans l'application Plex | Connectez l'application Plex avec le même compte que celui de l'étape 3, et gardez les deux appareils sur le même réseau domestique |
| La bibliothèque est vide | La première synchronisation est toujours en cours : attendez que **Status** affiche un nombre de titres |
| **Sign in needed** sous un addon | Appuyez sur son bouton **Sign in** et saisissez le code |
| **Needs an update** sous un addon | Cette version de l'application ne peut plus faire tourner cette copie de l'addon. Actualisez son dépôt puis appuyez sur **Update**. Ses titres restent disponibles en attendant |
| **That isn't a repository link. Try github.com/user/repo.** | Tapez le lien du dépôt, par exemple `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | Le lien est incorrect ou le dépôt est privé. Vérifiez-le dans un navigateur |
| rex s'arrête quand l'écran est éteint | Refaites le réglage d'arrière-plan de l'étape 2, et consultez [Don't kill my app](https://dontkillmyapp.com/) |

**Logs** affiche ce que rex et les addons ont signalé récemment, avec les clés et mots de passe masqués. Si le support demande les logs, appuyez sur **Send logs to support** : vous voyez tout avant l'envoi, puis appuyez sur **Send** et publiez le code que vous obtenez.

Ce que l'application envoie et où l'envoie se trouve dans sa [politique de confidentialité](android-privacy.md).

Bloqué ? Demandez sur le forum **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP).
