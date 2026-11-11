# Boutons DMM dans Safari {#dmm-buttons-in-safari}

Le navigateur extension DMM ajoute un bouton **DMM🔎** sur les sites de films et de séries. Il ouvre le titre sur DMM. À côté des liens magnet, il ajoute un bouton **DMM🧲** qui envoie le torrent dans ta bibliothèque DMM.

Sur Chrome et Firefox, installe l'[extension Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm) ou l'[module complémentaire Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/). Safari utilise le même code sous forme de [script utilisateur Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager), avec un gestionnaire de scripts utilisateur.

Choisis un gestionnaire :

| Gestionnaire | Prix | Fonctionne sur | Mise à jour du script |
|---|---|---|---|
| [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) | Gratuit | Mac, iPhone, iPad | Quand tu appuies sur **Update** dans sa fenêtre |
| [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) | 2,99 $ | Mac, iPhone, iPad | Automatiquement |

## Avec Userscripts {#with-userscripts}

1. Installez [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) depuis l'App Store et ouvrez-le une fois.
2. Activez l'extension :
   - **Mac :** Safari > **Réglages** > **Extensions**, cochez **Userscripts**.
   - **iPhone et iPad :** **Réglages** > **Apps** > **Safari** > **Extensions** > **Userscripts**, activez **Allow Extension**.
3. Laissez-la s'exécuter sur tous les sites. Les liens magnet peuvent se trouver sur n'importe quel site, donc le script doit pouvoir tourner partout.
   - **Mac :** dans le même volet **Extensions**, cliquez sur **Edit Websites…** et réglez **When visiting other websites** sur **Allow**.
   - **iPhone et iPad :** sur le même écran **Userscripts**, réglez **All Websites** sur **Allow**.
4. Dans Safari, ouvrez le [fichier du script DMM](https://update.greasyfork.org/scripts/463268/Debrid%20Media%20Manager.user.js). Il s'affiche en texte brut.
5. Ouvrez le popup de Userscripts : son bouton dans la barre d'outils sur Mac, ou le bouton **aA** dans la barre d'adresse sur iPhone. Appuyez sur l'invite d'installation qu'il affiche et confirmez.

Pour mettre à jour plus tard, ouvrez le popup de Userscripts et appuyez sur **Update** lorsqu'il affiche le script DMM.

## Avec Tampermonkey {#with-tampermonkey}

1. Installez [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) depuis l'App Store.
2. Activez-le et laissez-le fonctionner sur tous les sites, comme aux étapes 2 et 3 ci-dessus, avec **Tampermonkey** à la place de **Userscripts**.
3. Dans Safari, ouvrez la [page Greasy Fork du script](https://greasyfork.org/en/scripts/463268-debrid-media-manager) et cliquez sur **Install this script**.
4. Tampermonkey ouvre sa page d'installation. Cliquez sur **Install**.

Tampermonkey vérifie une nouvelle version une fois par jour.

## Vérifie que ça fonctionne {#check-it-works}

Ouvrez [Dune: Part Two sur Letterboxd](https://letterboxd.com/film/dune-part-two/). Un bouton **DMM🔎** turquoise apparaît à côté du titre, et il ouvre le film sur DMM.

Pas de bouton ? Vérifiez ces points :

- La fenêtre du gestionnaire liste **Debrid Media Manager** et son interrupteur est activé.
- Safari autorise le gestionnaire à s'exécuter sur ce site. Quand il le demande, choisissez **Always Allow on Every Website**.
- La page a fini de charger. Des sites comme TMDB, Wikipedia et AniList affichent le bouton un peu après la page.
