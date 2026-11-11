# Torrents

Real-Debrid permet de télécharger un nombre illimité de fichiers torrent et de liens magnet, ainsi que de choisir les fichiers à télécharger à l'intérieur.
Si le fichier torrent ou le lien magnet a déjà été téléchargé par un autre utilisateur, il est considéré comme « caché » (cached) et Real-Debrid vous fournit directement le lien déjà disponible.
Sinon, il essaie de télécharger le lien magnet depuis les trackers publics ou via DHT/PEX.
Si c'est un fichier torrent contenant les infos du tracker, il utilise ces infos, ce qui est utile pour les trackers privés (malheureusement, beaucoup de trackers privés bloquent les serveurs de téléchargement de Real-Debrid).
Si le torrent n'a plus de seeders ni de leechers et qu'il est impossible de télécharger toutes les pièces du torrent, une erreur se produit.
Une fois téléchargé, vous obtenez aussi des liens cachés qui ressemblent à https://real-debrid.com/d/DOWNLOADCODE
DOWNLOADCODE est un identifiant unique de exactement 13 caractères pour le fichier concerné (tout ce qui suit le 13e caractère est ignoré).

# Sélection des fichiers {#selecting-files}

Comme indiqué, il est possible de sélectionner uniquement les fichiers que vous voulez télécharger à l'intérieur d'un torrent.
Si un torrent contient les fichiers A, B et C et que vous sélectionnez A et B, seuls A et B seront téléchargés.
Le statut « cached » d'un torrent dépend en fait de cette sélection unique de fichiers.
Pour revenir au torrent contenant les fichiers A, B et C, il existe différents statuts cached pour A, pour B ou pour B (seul), A+B, B+C, A+C (paire), ou A+B+C (tous les fichiers).
Chaque sélection unique télécharge à nouveau le torrent depuis les trackers et renvoie un lien mis en cache différent, même pour le même fichier.

# Liens en cache {#cached-links}

Les liens en cache ne sont pas téléchargeables et servent simplement de conteneur pour les CODES DE TÉLÉCHARGEMENT sur Real-Debrid.
Il faut les « unrestrict » ou les convertir en un vrai lien téléchargeable ou streamable depuis Real-Debrid, qui expire au bout de 7 jours.
Les liens en cache durent plus de 7 jours. Si un torrent a des liens en cache qui fonctionnent (c'est-à-dire qu'ils peuvent être unrestrict avec succès), cela veut dire que le torrent est toujours en cache sur Real-Debrid.
Ce n'est pas confirmé, mais il est très probable que le statut de cache d'un torrent puisse être prolongé si davantage d'utilisateurs unrestrict un lien en cache.

Gardez à l'esprit que la seule façon de vérifier qu'un lien en cache fonctionne est de le unrestrict puis de vérifier le premier octet du lien unrestrict à l'aide de l'en-tête HTTP Range.
zurg prend en charge deux méthodes de vérification : HEAD (par défaut, rapide) et basée sur Range (GET bytes=0-0, plus approfondie) via l'option de configuration use_range_verification.

# Partage des liens en cache entre comptes (mesuré le 2026-08-19) {#cached-link-sharing-across-accounts-measured-2026-08-19}

RD renvoie des ID de lien en deux longueurs : 13 caractères (~70 %) et 16 caractères (~30 %). Les 3 caractères en plus changent QUI peut débloquer le lien :
- Tronqué aux 13 premiers caractères, un lien /d/ se débloque avec N'IMPORTE QUEL compte premium, pas seulement celui qui l'a généré. La bibliothèque de torrents de l'appelant n'est pas touchée ; le seul effet de bord est une entrée dans l'historique des téléchargements de l'appelant.
- Envoyé avec son ID complet de 16 caractères, le même lien ne se débloque QUE depuis le compte qui l'a généré. Tous les autres comptes reçoivent "unavailable_file", même quand le torrent d'origine est toujours actif, même si l'appelant a le même infohash dans sa propre bibliothèque, et quelle que soit la valeur du paramètre ip.

Donc tronque toujours à 13 caractères avant de débloquer un lien enregistré. Tester avec des ID non tronqués « prouve » faussement que le partage de liens est impossible.

Les liens mis en cache survivent à la suppression du torrent par le compte qui les a générés, mais ils meurent avec le temps. Relevé à grande échelle : les liens créés il y a 1 à 2 mois se débloquaient tous encore entre comptes ; les liens plus vieux que ~3 mois renvoyaient tous "hoster_unavailable". À part ça, RD peut retirer le contenu lui-même de son cache (un hash prouvé en cache un mois peut être en downloading-from-0-seeders le mois suivant). Le lien renvoie alors "unavailable_file" pour tout le monde, y compris pour le compte qui l'a généré.

Décoder une erreur de déblocage sur un lien mis en cache enregistré :
- Lien de 13 caractères + hoster_unavailable -> le lien a expiré ; re-ajouter le torrent avec la même sélection génère de nouveaux liens (voir la réparation plus bas)
- Lien de 13 caractères + unavailable_file -> RD a complètement retiré le contenu ; de nouveaux liens exigent un vrai re-téléchargement depuis les seeders
- Lien de 16 caractères + unavailable_file -> ne dit rien sur la disponibilité : tu n'es simplement pas le compte qui a généré le lien ; tronque-le et réessaie

Les liens débloqués (les URL d'hôte *.download) sont liés à une IP par un suivi côté serveur, pas par un refus :
le CDN sert volontiers une IP étrangère avec un 206, mais Real-Debrid enregistre les IP de téléchargement, et l'utilisation multi-IP des liens d'un même compte vaut un avertissement de partage de compte. Passe l'IP du téléchargeur à unrestrict/link (le paramètre ip) pour que le lien soit généré pour l'IP qui va récupérer les octets.

# Réparation des liens en cache cassés {#repairing-broken-cached-links}

Parfois, un lien mis en cache, voire le lien débridé d'un fichier à l'intérieur d'un torrent ne fonctionne plus.
Cela peut venir d'une erreur de l'API unrestrict ou du fait que le lien débridé renvoie une réponse d'erreur HTTP.
Pour régler ça, il faut re-télécharger le torrent et générer de nouveaux liens mis en cache, tout frais.
Tu peux essayer de re-télécharger le torrent avec exactement la même sélection de fichiers, et voir si ça génère de nouveaux liens mis en cache, tout frais.
Si ça ne marche pas, il faut faire une sélection de fichiers différente sur ce torrent.
Par exemple, si un seul fichier est cassé dans un torrent qui en contient plusieurs, sélectionne juste ce fichier cassé.
Si ça renvoie toujours un lien mis en cache cassé, essaie d'ajouter un autre fichier à la sélection.
Tu fais ça jusqu'à obtenir un lien mis en cache frais qui fonctionne.

# Comportement avec les RAR {#rar-behavior}

Real-Debrid a ce comportement de stocker les torrents dans des fichiers RAR (sans compression) si vous sélectionnez un type de fichier non pris en charge qui ne peut pas être diffusé en streaming.
Types de fichiers vidéo confirmés : .avi .flv .m2ts .m4v .mkv .mov .mp4 .mpg .mpeg .ts .webm .wmv
Types de fichiers audio confirmés : .mp3 .flac .m4a
Ces types de fichiers, lorsqu'ils sont sélectionnés, donnent sur Real-Debrid des liens individuels vers chaque fichier, qui sont diffusables en streaming.
Si vous sélectionnez autre chose, Real-Debrid stockera à coup sûr le tout dans une archive RAR.
Si vous sélectionnez une vidéo .mkv et un sous-titre .sub, le tout sera mis en RAR.
Idem si vous sélectionnez seulement l'affiche .jpg : elle sera mise en RAR.

Un torrent, même avec plusieurs fichiers, s'il est mis en RAR ne renverra qu'un seul lien en cache (qui pointe vers le fichier RAR).
Si vous ne sélectionnez que des types de fichiers vidéo/audio confirmés, il ne sera pas mis en RAR et vous obtiendrez un lien en cache pour chaque fichier sélectionné.

# Supprimer une ligne de la liste des téléchargements révoque l'URL qu'elle a générée {#deleting-a-downloads-list-row-revokes-the-url-it-minted}

Mesuré le 2026-08-22 sur le compte de test, un unrestrict par cas.

Un unrestrict crée une ligne dans /downloads et une URL sur un hôte numéroté, par exemple
https://124-4.download.real-debrid.com/d/<13-char code>/<filename>. Le code
n'est pas lié à un hôte : avant la suppression de la ligne, le même code répond 200 sur
44-4, 125-4 et sur son propre 124-4. Le segment final du nom de fichier est facultatif
partout ; zurg le retire et les deux formes répondent de la même façon.

DELETE /downloads/delete/<id> révoque ce code, et ce qui survit dépend des hôtes
qui l'ont déjà servi :

  - Ligne supprimée avec l'URL jamais récupérée : chaque hôte répond 404 avec
    X-Error: invalid_download_code. Toujours 404 30 secondes plus tard, donc ça ne se stabilise pas.
  - Ligne supprimée après une récupération via 44-4 : 44-4 continue de répondre 200, alors que
    l'hôte d'origine 124-4 et un 125-4 non utilisé répondent tous deux 404 invalid_download_code.

Donc une récupération active le code sur l'hôte qui l'a servi, et c'est la ligne qui permet à
tous les autres hôtes de continuer à servir. C'est l'inverse de l'hypothèse sur laquelle le nettoyage
de la liste des downloads a été écrit, et c'est important parce que zurg choisit l'hôte de
téléchargement à chaque requête (ensureReachableDownloadServer réécrit vers l'un des N hôtes
les plus rapides) : l'hôte touché par un HEAD de vérification n'est pas celui que la requête suivante
choisit. Une résolution laissée dans le cache de liens après la suppression de sa ligne
répond donc 404 invalid_download_code à presque toutes les requêtes suivantes, ce qui ressemble à un lien
pourri et marque une release saine comme cassée.

Refaire un unrestrict du même lien après une suppression finit par créer un nouvel id sur un nouvel hôte
et fonctionne normalement. Les ids ne sont jamais réutilisés.

Mais pas tout de suite. La première mesure disait « non affecté » parce qu'elle avait été faite
quelques minutes plus tard. Remesuré le 2026-08-23 sur le compte de test : après
DELETE /downloads/delete/<id>, unrestrict/link a continué à renvoyer le *même id mort* pendant 75 secondes, et
n'en a créé un nouveau qu'à t+81s.

Deux conséquences en découlent, et les deux sont dans le code. downloadsCleanupMinAge garde une ligne
pendant deux minutes avant de la retirer, donc une autre instance qui résout le même lien dans cette fenêtre
obtient un code valide. Et la chaîne de re-unrestrict du chemin de service (quatre tentatives en
environ six secondes) tient entièrement dans la fenêtre. L'épuiser ne dit donc rien sur le fichier : quand chaque
résolution revient avec l'URL qui vient de répondre 404, zurg refuse la lecture avec un Retry-After au lieu de
marquer la release comme cassée.
