# rex pour Android : politique de confidentialité {#rex-for-android-privacy-policy}

*Dernière mise à jour : 16 novembre 2026.*

rex pour Android fait tourner un serveur multimédia sur votre appareil. Il n'y a pas de compte chez nous, pas de publicités et pas d'analyses, et il ne nous envoie ni votre bibliothèque, ni ce que vous regardez, ni rien d'autre vous concernant, sauf pour rex-direct et les journaux que vous choisissez de nous envoyer, tous deux décrits ci-dessous.

## Ce qui quitte votre appareil, et où ça va {#what-leaves-your-device-and-where-it-goes}

| Où | Quoi | Quand |
|---|---|---|
| **plex.tv** (Plex, Inc.) | Une demande de code de connexion (sur un téléphone ou une tablette, un second pour la page de connexion de Plex) avec un identifiant d'application aléatoire et le nom de ce serveur ; puis, une fois que vous en approuvez un, une demande ponctuelle de code de réclamation | Quand vous choisissez Sign in to Plex |
| **plex.tv** | Le nom du serveur, son identifiant, sa version et les adresses auxquelles les applications Plex peuvent l'atteindre | Pendant que rex tourne et est connecté, comme tout serveur Plex se déclare |
| **Le service de métadonnées de Plex** | Les identifiants des titres ajoutés par vos addons, pour récupérer les affiches et les descriptions | Pendant que rex tourne et est connecté |
| **debridmediamanager.com** (rex-direct) | L'identifiant du serveur, le jeton de serveur que Plex lui a donné, ses adresses IP locale et publique ainsi que son port | Une fois connecté, puis toutes les 6 heures, pour que les applications Plex puissent joindre rex en HTTPS hors de la maison |
| **logs.debridmediamanager.com** (journaux de support) | Les versions de l'application et de rex, le modèle de l'appareil, la version d'Android et le type de processeur, le port et l'état de rex, le nom, la version, le dépôt, l'état, le nombre de titres, la dernière synchronisation et la dernière erreur de chaque addon, le décalage du fuseau horaire, ainsi que les journaux de l'application pour cette exécution et la précédente, avec les jetons, clés, mots de passe et les deux derniers blocs des adresses IP publiques masqués. Jamais vos paramètres d'addon, votre compte Plex ni vos jetons | Uniquement quand vous appuyez sur Send sous Send logs to support, après avoir tout vu. Vous recevez un code à donner au support ; seul le personnel du support peut le lire, et il est supprimé au bout de 7 jours |
| **Dépôts d'addons que vous ajoutez** (comme github.com) | Une demande du contenu du dépôt | Quand vous ajoutez ou actualisez un dépôt |
| **Les sites de chaque addon** | Ce que l'addon demande, comme une requête de catalogue vers archive.org | Quand un addon se synchronise ou qu'un titre se lance |

Votre mot de passe de compte Plex ne passe jamais par l'application : vous vous connectez sur la page de Plex elle-même. Le
jeton de compte que cette connexion donne à l'application sert une seule fois à réclamer le serveur, puis il est jeté. rex
ne garde que le jeton de serveur que Plex lui délivre.

## Ce qui reste sur votre appareil {#what-stays-on-your-device}

Vos bibliothèques, votre historique de visionnage, les réglages des addons (y compris les clés que vous saisissez) et les journaux. L'application conserve les journaux de cette session et de la précédente, afin qu'un plantage ne fasse pas perdre les données. Les journaux masquent les jetons, les clés, les mots de passe et la fin des adresses IP publiques, et ils ne quittent l'appareil que si vous choisissez Share ou Send logs to support sur l'écran Logs. Désinstaller l'application supprime tout cela.

## Modules complémentaires {#addons}

Un addon est du code écrit par quelqu'un d'autre, installé depuis un dépôt que vous avez ajouté. Il s'exécute isolé du reste de votre appareil et ne peut joindre que les sites qu'il nomme, ce que rex vous montre avant l'installation. N'installez des addons que de personnes en qui vous avez confiance.

Un addon qui demande un compte sur son site se connecte avec un code : vous le saisissez sur la page de ce site, si bien que votre mot de passe ne passe jamais par l'application. Le jeton que le site remet ensuite à l'addon reste sur votre appareil et ne retourne que vers ce site. Supprimer l'addon efface ce jeton.

## Enfants {#children}

L'application n'est pas destinée aux enfants.

## Contact

support@debridmediamanager.com
