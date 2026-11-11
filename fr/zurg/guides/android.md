# zurg+rex pour Android et Google TV {#zurgrex-for-android-and-google-tv}

L'application Android fait tourner un moteur zurg sur l'appareil, avec rex à côté : votre propre serveur Plex sur votre téléphone ou votre boîtier TV, pour les applications Plex. Une seule application fonctionne sur les téléphones, les tablettes, Android TV et Google TV.
Android 8.0 ou plus récent est requis. Fire TV peut installer le même APK en sideload. Utilisez un lecteur WebDAV lorsqu'il n'a pas d'application Fichiers système. Usenet nécessite Android 64 bits ; les NZB hébergés par TorBox (`torbox_nzb`) ne sont pas disponibles sur Android.

## Installer et configurer {#install-and-set-up}

Télécharge un APK depuis la release nightly du dépôt privé réservé aux sponsors.
Choisis `arm64-v8a` pour la plupart des téléphones et des boîtiers TV, `armeabi-v7a` pour les anciens appareils 32 bits, ou `x86_64` pour un émulateur ou un Chromebook compatible.
Chaque APK inclut les interfaces téléphone et TV.

L'appli ne contient pas zurg lui-même. Une fois connecté à GitHub, tu installes le moteur depuis l'appli. Un compte sponsor est obligatoire. Sponsorise [gatekeeper](https://gatekeeper.debridmediamanager.com/) pour donner accès à ton compte GitHub. Setup te guide pas à pas.

Autorise l'installation depuis l'appli utilisée pour ouvrir l'APK. Android ou Play Protect peuvent te demander de confirmer le sideloading. L'identifiant de l'application est `com.debridmediamanager.zurg`. Les mises à jour doivent conserver la même identité de signature de release.

1. Ouvre zurg et connecte-toi à GitHub, puis installe une version du moteur. L'appli ne peut pas démarrer une bibliothèque tant qu'aucun moteur n'est installé.
2. Ajoute tes comptes fournisseurs et teste les identifiants. Les noms de compte permettent de distinguer plusieurs comptes chez le même fournisseur. Les limites de connexions Usenet comptent toutes les autres utilisations de ce compte.
3. Choisis Phone, Tablet, TV box ou TV stick. Les profils définissent la cible de mémoire du moteur et la taille du cache disque. Une cible de heap Go n'est pas une limite RSS stricte.
4. Autorise les notifications et le fonctionnement en arrière-plan. Active start after reboot si cet appareil doit toujours servir la bibliothèque.
5. Démarre la bibliothèque. Le premier chargement d'un gros compte peut prendre plusieurs minutes. La notification et l'écran Status indiquent quand les dossiers sont prêts.

## Regarder sur cet appareil {#watch-on-this-device}

Utilise Library pour parcourir les dossiers et lire un fichier. More propose un autre lecteur ou une URI de document Android. Le lecteur choisi peut devenir ton lecteur préféré.
Files et les sélecteurs de fichiers affichent la même bibliothèque sous la racine de stockage zurg.
Les fichiers sont diffusés en accès aléatoire ; ils ne sont pas téléchargés entièrement d'abord.
Ouvre ton lecteur une fois et termine sa configuration avant de le choisir depuis Files.

Pour les lecteurs WebDAV, ajoute `http://127.0.0.1:9999/dav/` comme source. Utilise le port affiché dans Status si tu l'as modifié. VLC, Kodi et Nova peuvent parcourir une source WebDAV ; les lecteurs qui n'acceptent que des URL individuelles peuvent être lancés depuis Library. Sur TV, utilise le D-pad et Select pour déplacer et activer les contrôles, Back pour revenir en arrière, et Menu ou More pour les actions sur la release. Sélectionne un champ de texte pour le modifier, puis appuie sur Back pour revenir à la navigation. Un appui long ouvre aussi More sur un téléphone.

Repair, rename, tags, show all files et delete agissent sur la release entière à laquelle appartient le fichier. La suppression demande une confirmation et supprime depuis ton compte chez le fournisseur.
MediaInfo utilise le ffprobe inclus et affiche les détails des pistes vidéo, audio et sous-titres dans le tableau de bord. Aucune installation d'outil média séparée n'est nécessaire.

## Regarder dans les applications Plex {#watch-in-the-plex-apps}

Depuis la nightly du 10 novembre 2026, l'application lance aussi rex (sur les appareils 64 bits de cette nightly, puis sur tous les appareils pris en charge à partir de la nightly du 11 novembre), un serveur multimédia pour les applications Plex, et lui indique zurg. Votre bibliothèque apparaît ainsi dans les applications Plex officielles et dans Plezy, sur cet appareil et sur les autres de votre foyer. Une fois votre bibliothèque lancée, Statut affiche **rex pour les applications Plex** : choisissez **Sign in to Plex** et validez la connexion (sur une TV, saisissez le code sur plex.tv/link). Le serveur apparaît dans Plex sous le nom de cet appareil. rex convertit ce qu'un lecteur ne peut pas lire grâce à l'encodeur matériel de l'appareil. Pour désactiver rex, allez dans Settings, Connection : zurg arrête alors de lui transmettre le contenu.

## Partager sur le réseau local {#share-over-the-local-network}

Dans Réglages, active **Expose on local network**. zurg génère des identifiants et affiche l'adresse WebDAV LAN de l'appareil. Saisis cette adresse et ces identifiants dans un lecteur sur l'autre appareil. Garde l'hôte Android alimenté et en marche. L'authentification HTTP basic ne chiffre pas le trafic ; utilise un réseau local de confiance. Loopback est la valeur par défaut. Les intents du lecteur ne contiennent jamais ton mot de passe de serveur.

## Réglages, sauvegardes et mises à jour {#settings-backups-and-updates}

Settings regroupe la connexion, les fournisseurs, la bibliothèque, la réparation, les ressources et la journalisation.
Advanced accepte du YAML brut et demande au moteur installé de le valider avant de l'enregistrer. Settings n'a pas de champ pour votre clé API DMM : ajoutez `dmm_api_key: YOUR_DMM_API_KEY` dans Advanced pour la [liste de souhaits DMM](dmm-wanted.md) et pour le nommage des sorties de DMM. Lorsque vous enregistrez une configuration pendant que le serveur tourne, l'application vous demande confirmation avant de redémarrer le serveur.
Web dashboard ouvre le tableau de bord local pour les réglages d'intégration au bureau.

Logs affiche la sortie récente du moteur et les 200 dernières lignes du superviseur.
Les journaux partagés masquent les secrets et les URL configurés. Les sauvegardes contiennent des identifiants et l'état de la bibliothèque, donc conservez-les en lieu sûr. Arrêtez zurg avant de restaurer. Android refuse les liens de sauvegarde et les fichiers spéciaux, et restaure d'abord sur loopback.

Updates vérifie le dépôt privé du sponsor. La connexion par code d'appareil GitHub demande le scope `repo`, car les fichiers de publication sont privés. Les jetons GitHub sont chiffrés avec les préférences adossées à Android Keystore. Un jeton saisi manuellement, avec un accès en lecture au dépôt, est aussi pris en charge. Si Android ne peut plus déchiffrer une connexion enregistrée, Updates vous demande de vous reconnecter et conserve la configuration de votre bibliothèque. Les mises à jour téléchargées doivent correspondre à l'ID d'application et à la clé de signature, et avoir un code de version plus récent. L'installeur Android vous demande confirmation avant de remplacer l'application.

Si vous mettez à jour depuis une version qui embarquait son propre moteur, l'application n'en aura plus. Installez un moteur depuis Updates une seule fois : vos fournisseurs et les réglages de bibliothèque seront conservés tels quels.

L'application et le moteur se mettent à jour séparément. Updates liste les versions du moteur parmi les 30 publications les plus récentes du dépôt du sponsor, marque celle que vous avez, et permet d'installer n'importe laquelle. Si une nouvelle version nightly pose problème sur votre appareil, installez celle qui fonctionnait pour vous. Arrêtez votre bibliothèque dans Status avant de changer de moteur. L'application n'exécute qu'un paquet de moteur signé avec sa propre clé, et elle vérifie à nouveau cette signature à chaque démarrage.

La notification persistante possède une action Stop. Une tuile Quick Settings permet aussi de démarrer ou d'arrêter le serveur. L'exemption de batterie aide contre les limites de veille d'Android ; les gestionnaires de tâches propres à certains fabricants peuvent nécessiter des réglages supplémentaires, décrits sur [Ne tuez pas mon application](https://dontkillmyapp.com/).
