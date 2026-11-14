# rex pour Android {#rex-for-android}

rex est un serveur média pour les applications Plex qui ne possède aucun fichier. rex pour Android le fait tourner sur un téléphone, une tablette, Android TV, Google TV ou Fire TV, sans ordinateur. Les applications Plex de vos appareils le trouvent comme n'importe quel serveur Plex et lisent depuis lui.

Ce qu'il lit provient d'**addons**. Il commence avec les films du domaine public de l'Internet Archive. D'autres addons, comme vos addons Stremio, YouTube et Spotify, s'installent depuis l'application une fois que vous ajoutez leur dépôt.

rex pour Android est gratuit. Vous voulez aussi y intégrer vos comptes debrid et Usenet ? zurg+rex, un serveur Plex sur votre téléphone avec zurg intégré, est proposé avec un système de parrainage : voir [zurg+rex pour Android](../zurg/guides/android.md).

## Avant de commencer {#before-you-start}

| Vous avez besoin de | Pourquoi |
|---|---|
| Un appareil avec Android 8.0 ou plus récent | Téléphone, tablette, Android TV, Google TV ou Fire TV |
| Un compte Plex | rex apparaît dans les applications Plex connectées à ce compte. Un compte gratuit suffit |
| Une application Plex sur l'appareil que tu utilises pour regarder | Plex pour Android, Android TV, iPhone, une smart TV, Plex Web, Plexamp |

Elle n'est pas encore sur Google Play. Tu installes toi-même le fichier de l'application (APK).

## Étape 1. Téléchargez-le {#step-1-download-it}

Sur l'appareil, téléchargez le fichier correspondant à son processeur. Chaque lien pointe toujours vers la dernière version :

| Votre appareil | Téléchargement |
|---|---|
| La plupart des téléphones, tablettes et boîtiers TV (64 bits) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| Boîtiers 32 bits plus anciens ou bas de gamme, dont les Fire TV Stick | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| Émulateurs sur PC | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

Toutes les versions et leurs modifications sont sur [la page des releases](https://github.com/debridmediamanager/rex-android/releases).

Vous ne savez pas ? Essayez d'abord `arm64-v8a`. Un seul fichier fonctionne aussi bien sur les téléphones que sur les TV.

## Étape 2. Installez-le {#step-2-install-it}

Ouvre le fichier téléchargé. Android te demande d'abord :

1. Il indique qu'il **n'est pas autorisé à installer des applications inconnues depuis cette source**. Appuie sur **Settings**, active **Allow from this source** et reviens en arrière.
2. Appuie sur **Install**.

Sur une box TV sans navigateur, télécharge le fichier avec une application de téléchargement capable d'ouvrir les APK.

**Ce que tu dois voir.** **rex** dans ta liste d'applications.

## Étape 3. Lancez rex {#step-3-start-rex}

Ouvre **rex**. Le premier écran affiche **Welcome to rex.**

1. Appuie sur **Allow notifications**, puis sur **Allow**. rex tourne en arrière-plan avec une notification qui permet de l'arrêter.
2. Appuie sur **Let rex keep running in the background**. Dans la liste qui s'ouvre, choisis **rex** puis **Don't optimize**. Sur les versions récentes d'Android, c'est **Allow background usage**, puis **Unrestricted**. Reviens dans rex. Les deux boutons commencent maintenant par un ✓.
3. **Name** est le nom que les applis Plex donnent à ce serveur. Change-le si tu veux.
4. Laisse **Port** à `32400`. Si un autre serveur Plex tourne déjà sur cet appareil, rex affiche **Another app here already uses this port, maybe a Plex server. Try 32500.** Tape `32500`.
5. Appuie sur **Start rex**.

**Ce que tu devrais voir.** **2 / 2** et **Sign in to Plex.**

| Le premier écran | La page du film dans l'appli Plex (étape 5) |
|---|---|
| ![Le premier écran de rex pour Android, avec les champs name et port et le bouton Start rex](../assets/rex/android-setup.webp) | ![Un film muet de 1916 de l'Internet Archive sur sa page dans Plex pour Android](../assets/rex/android-plex-film.webp) |

## Étape 4. Connectez-vous à Plex {#step-4-sign-in-to-plex}

Appuyez sur **Sign in to Plex**. rex affiche un code : **On any phone or computer, go to plex.tv/link and enter** it.

- **Sur un téléphone ou une tablette**, votre navigateur ouvre aussi une page Plex indiquant **rex for Android would like to sign in to your Plex account**. Connectez-vous là.
- **Sur une TV**, allez sur [plex.tv/link](https://plex.tv/link) depuis votre téléphone ou votre ordinateur, connectez-vous et saisissez le code.

Utilisez le compte avec lequel vos applications Plex sont connectées. Vous pouvez appuyer sur **Skip for now** et vous connecter plus tard depuis **Status**.

![rex for Android sur une TV affichant le code à saisir sur plex.tv/link](../assets/rex/android-tv-signin.webp)

**Ce que vous devriez voir.** **Signed in. rex shows up in the Plex apps as** suivi du nom de votre serveur. Appuyez sur **Done**. **Status** affiche **RUNNING** et **Ready for the Plex apps.**

## Étape 5. Regardez dans une appli Plex {#step-5-watch-in-a-plex-app}

Ouvrez n'importe quelle application Plex connectée au même compte. Si Plex est sur cet appareil, **Status** affiche un bouton **Open Plex**.

Dans Plex pour Android, ouvrez **Libraries**, puis **All Libraries**, puis **Movies** sous le nom de votre serveur. Les autres applications Plex affichent aussi la bibliothèque sous le nom du serveur.

La première synchronisation d'Internet Archive prend un moment : environ une demi-heure sur notre appareil de test, le temps que rex vérifie chaque film. **Status** affiche **Syncing** jusqu'à la fin, puis le nombre, comme **Ready · 97 titles**. Lancez la lecture de n'importe quel film.

![L'application Plex sur une TV lisant un court métrage de Chaplin de 1914 provenant de rex sur la même TV](../assets/rex/android-tv-playing.webp)

## Modules complémentaires {#addons}

**Addons** liste ce que vous avez installé. Chacun affiche ses titres et la date de sa dernière synchronisation. Ses boutons sont **Sync now**, **Settings**, **Log** et **Remove** ; sur un téléphone, faites glisser la rangée de boutons vers la gauche ou la droite pour tous les voir. L'interrupteur **Enabled** désactive un addon sans le supprimer.

Les addons viennent de **repositories** : des dépôts git qui contiennent des addons. L'application ajoute déjà [rex-addons](https://github.com/debridmediamanager/rex-addons) au départ, qui propose les films du domaine public d'Internet Archive, installés dès le début. Pour en avoir davantage, ajoutez [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons) (voir **Add a repository** plus bas), qui propose :

| Addon | Ce qu'il apporte |
|---|---|
| Stremio addons | Les catalogues de films et de séries de vos addons Stremio, lus depuis les flux que vos addons de flux fournissent |
| YouTube | Vos playlists YouTube. Vous vous connectez avec un code |
| Spotify | Votre bibliothèque Spotify, en musique pour Plex et Plexamp. Nécessite l'addon YouTube, connecté |

**Installer un addon.** Sous **Repositories**, appuyez sur **Addons** à côté d'un repository, puis sur **Install** sous l'addon. rex affiche les sites web qu'il peut joindre et vous demande une dernière fois confirmation, puis lance la synchronisation.

**Se connecter.** Un addon qui a besoin de votre compte affiche **Sign in to start.** Appuyez sur son bouton **Sign in** : rendez-vous sur la page indiquée depuis n'importe quel appareil et saisissez le code affiché.

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

- **Ça marche à la maison.** En dehors de chez vous, les applis Plex ont besoin d'une adresse HTTPS qui atteint l'appareil, ce qui demande une redirection de port vers celui-ci sur votre box. Voir [Utiliser-le en dehors de chez vous](any-source.md#use-it-outside-your-home-optional).
- **L'appareil fait office de serveur.** Gardez-le allumé, connecté en Wi-Fi ou en Ethernet, et branché sur le secteur. La conversion de vidéos pour un lecteur qui ne peut pas lire un fichier utilise le matériel de l'appareil et peut être lente sur un boîtier bas de gamme.
- **Uniquement ce que vos addons apportent.** Il n'a pas de bibliothèque de fichiers sur l'appareil lui-même.
- **Pas encore sur Google Play.** Pour mettre à jour, installez le nouveau fichier depuis [les releases](https://github.com/debridmediamanager/rex-android/releases/latest) par-dessus l'ancien, et rex redémarre tout seul. Votre connexion et vos addons restent en place.

## Dépannage {#troubleshooting}

| What you see | What to do |
|---|---|
| **App not installed as app isn't compatible with your phone.** | Tu as choisi le mauvais fichier pour le processeur. Essaie l'autre de la table de l'Étape 1 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | Tape `32500` comme port |
| **Use a number from 1024 to 65535** | Le port doit être un nombre dans cette plage |
| Le serveur n'apparaît pas dans l'app Plex | Connecte l'app Plex avec le même compte que celui de l'Étape 4, et garde les deux appareils sur le même réseau domestique |
| La bibliothèque est vide | La première synchronisation tourne encore : attends que **Status** affiche un nombre de titres |
| **Sign in needed** under an addon | Appuie sur son bouton **Sign in** et saisis le code |
| **That isn't a repository link. Try github.com/user/repo.** | Tape le lien du dépôt, par exemple `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | Le lien est faux ou le dépôt est privé. Vérifie-le dans un navigateur |
| rex s'arrête quand l'écran est éteint | Refais le réglage d'arrière-plan de l'Étape 3, et regarde [Ne tue pas mon app](https://dontkillmyapp.com/) |

**Logs** affiche ce que rex et les addons ont dit récemment, clés et mots de passe masqués. Si le support demande des logs, appuie sur **Send logs to support** : tu vois tout avant l'envoi, puis appuie sur **Send** et poste le code que tu reçois.

Ce que l'app envoie et où est expliqué dans sa [politique de confidentialité](android-privacy.md).

Bloqué ? Demande sur le forum **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP).
