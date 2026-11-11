# Serveur de news TorBox {#torbox-news-server}

Un abonnement TorBox Pro inclut un compte Usenet. C'est un vrai serveur NNTP, et zurg peut l'utiliser comme un fournisseur `type: nzb` classique. Cette page décrit ce serveur et ce qu'il vaut comme emplacement de fournisseur. Tout ce qui suit a été mesuré les 2026-09-02 et 2026-09-03 depuis deux machines sur des réseaux distincts.

## Ce qui répond sur le réseau {#what-answers-on-the-wire}

`nntp.torbox.app:563` parle NNTP sur TLS 1.3, derrière un certificat Let's Encrypt pour
`nntp.torbox.app`. Le message d'accueil est `200 Welcome to TorBox`. La liste des capacités indique le logiciel.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
POST
```

Cette chaîne d'implémentation n'est ni INN, ni Diablo, ni le `nntpd` que certains fournisseurs annoncent.
C'est un logiciel maison, et son nom dit ce qu'il fait. Un switch se trouve devant un ou plusieurs spools d'articles.

## Qui le gère {#who-runs-it}

Quarante noms d'hôtes de serveurs publics ont été testés pour cette chaîne d'implémentation. Trente-deux ont répondu en NNTP
et six d'entre eux annoncent `nntpswitch2`. Les six renvoient des listes de capacités identiques, dans le même ordre.

| Lecteur | Adresse | Accueil |
|---|---|---|
| `nntp.torbox.app` | 78.152.55.171 | `200 Welcome to TorBox` |
| `news.cheapnews.eu` | 78.152.55.164 | `200 Welcome to Cheapnews` |
| `reader.xsnews.nl` | 94.232.116.131 | `200 Welcome to XS News` |
| `news.easyusenet.nl` | 94.232.116.128 | `200 Welcome to Easyusenet` |
| `news.hitnews.com` | 94.232.116.174 | `200 Welcome to Hitnews` |
| `news.usenext.de` | 94.232.116.150 | `200 Welcome to Aviteo Ltd DE` |

Tout le reste a répondu autrement. Ça inclut les marques Omicron, Eweka, Frugal, UsenetExpress, Giganews et Usenet.Farm.

Les adresses règlent le reste. `94.232.112.0/21` est enregistré au nom d'Abavia S.r.l., de Saint-Marin, avec `abuse@abavia.com` dans le registre. Une recherche inverse sur `94.232.116.0/24` renvoie plus de soixante noms de serveurs de lecture, rien que dans ce bloc. XS News, Easyusenet, Hitnews et UseNeXT s'y trouvent, à côté de dizaines de petites marques. Le voisin `94.232.117.0/24` est entièrement du nommage d'hôtes XS News.

TorBox n'est pas dans ce bloc. Il se trouve dans une plage d'Amsterdam, à sept adresses de `news.cheapnews.eu`.

**Mesuré** désigne l'empreinte logicielle, la propriété des adresses et leur proximité. **Déduit** désigne l'arrangement commercial. TorBox décrit son Usenet comme un mélange de haute qualité de fournisseurs Usenet, et le logiciel de bascule est cohérent avec cela. Donc la formulation prudente est que TorBox fait office de façade pour la même plateforme de lecture que celle qu'utilisent les marques Abavia et XS News, et non que TorBox revend un spool précis et nommé.

## Ce que le compte vous donne {#what-the-account-gives-you}

| Propriété | Valeur |
|---|---|
| Hôte | `nntp.torbox.app:563` TLS, répond aussi sur 119 |
| Groupes dans `LIST ACTIVE` | 103,415 |
| Connexions | 10, une limite stricte comptée exactement, poignée de main en cours incluse |
| Rétention | 3900+ jours annoncés par TorBox pour ce serveur |
| Publication | autorisée, `POST` renvoie `340 Start posting` |
| Champs de vue d'ensemble | Subject, From, Date, Message-ID, References, Bytes, Lines, Xref:full |
| Compression | `XZVER` et `XZHDR` tous deux proposés |
| Bande passante | illimitée, mais comptée dans le chiffre d'utilisation du tableau de bord TorBox |

Les identifiants viennent de torbox.app, dans tools, puis View Usenet Connection Details. Le nom d'utilisateur est l'auth id du compte. Le mot de passe n'est affiché qu'une seule fois. Toute réinitialisation invalide le précédent, donc une réinitialisation casse chaque client déjà configuré.

Deux messages de refus comptent quand quelque chose tourne mal. `482 too many connections for your user` correspond à la limite, et elle se libère dès qu'une connexion est rendue. `482 Invalid username or password` indique un identifiant vraiment mort. Les deux sont des échecs lents, autour de deux secondes. Une authentification réussie est beaucoup plus rapide : elle a été mesurée entre 64 ms et 592 ms sur une journée de connexions en production.

## La fenêtre de numéros d'article fait deux semaines {#the-article-number-window-is-two-weeks-wide}

`GROUP` sur un groupe binaire très fréquenté renvoie un nombre exactement égal à la limite haute moins la limite basse. Les vrais spools ont des trous, donc cette égalité est la signature d'une numérotation synthétique. La fenêtre est aussi courte.

| Groupe | Limite basse | Limite haute | Numéros dans la fenêtre |
|---|---|---|---|
| `alt.binaries.boneless` | 148068410000 | 150053594960 | 1,985,184,960 |
| `alt.binaries.teevee` | 2992135000 | 3392153099 | 400,018,099 |
| `alt.binaries.multimedia` | 31901685000 | 32301734812 | 400,049,812 |

En lisant les plus anciens numéros de `alt.binaries.boneless`, on obtient des articles publiés le 2026-08-19. C'était quatorze jours avant l'écriture de ce texte. Tout ce qui est plus ancien n'a pas de numéro sur ce serveur.

Cela n'affecte pas zurg. Un NZB pointe les articles par identifiant de message, et une recherche par identifiant de message atteint des articles bien plus anciens que la fenêtre. En revanche, cela touche tout ce qui parcourt les numéros d'articles. Un téléchargeur d'en-têtes ou un indexeur pointé vers ce serveur ne voit que quinze jours d'Usenet et rien avant.

## Est-ce qu'il relaie votre requête vers d'autres fournisseurs {#is-it-proxying-your-request-to-other-providers}

Non. Trois mesures montrent que la réponse vient d'un spool que la plateforme possède déjà.

**Il refuse plus vite qu'il ne pourrait interroger qui que ce soit.** Vingt-cinq identifiants de messages qui n'ont jamais existé nulle part ont été soumis à trois serveurs.

| Serveur | `STAT` sur un hit | `STAT` sur un identifiant qui n'a jamais existé |
|---|---|---|
| `nntp.torbox.app` | 37 ms | **43 ms** |
| `news.eweka.nl` | 20 ms | 471 ms |
| `newshosting.tweaknews.eu` | 44 ms | 909 ms |

Un serveur qui interroge les sources amont avant de répondre est le plus lent quand la réponse est non, puisque chaque source amont doit d'abord répondre. Celui-ci dit non dans le même temps qu'il met à confirmer un oui. C'est un index local qui répond.

**Il n'y a pas de pénalité au premier accès.** Dix articles de 2012 à 2018 ont été récupérés à froid, puis immédiatement de nouveau sur la même connexion.

| Serveur | médiane à froid | médiane à chaud |
|---|---|---|
| `nntp.torbox.app` | 49.6 ms | 30.9 ms |
| `news.eweka.nl` | 98.0 ms | 78.1 ms |

Le ratio froid/chaud est de 1.6 ici, contre 1.25 sur un spool classique. Cela correspond à TCP et au cache de pages. Une récupération auprès d'un tiers lors de la première requête coûterait bien plus cher et ne se verrait que lors du passage à froid. Un article de 792 KB arrivé à froid en 49 à 73 ms, soit environ 11 à 16 MB/s, ne laisse aucune place à un aller-retour vers un autre fournisseur.

**Un mélange ne peut pas être un sous-ensemble de l'un de ses membres.** C'est l'argument décisif. Si le serveur fusionnait plusieurs backbones, sa couverture serait l'union de ces derniers, et il contiendrait des articles qu'au moins un membre ne possède pas. Or il n'en contient aucun. C'est un sous-ensemble strict du compte Omicron, à 71.2 %. Fusionner des fournisseurs ne peut pas produire cela.

Un détail utile si vous cherchez à retracer la source : les en-têtes sont renvoyés normalisés plutôt que tels quels. L'ordre des champs change et la casse est réécrite, donc `X-Received-Body-CRC` devient `X-Received-Body-Crc` et `Message-ID` devient `Message-Id`. `Path` vaut `not-for-mail` sur chaque article vérifié. Un spool classique peut conserver la chaîne réelle, alors qu'un des serveurs ci-dessus renvoie `news.tweak-news.eu!spooler.pl1!...!feed.tweaknews.nl!path-stripped` pour le même article. Les en-têtes sont donc reconstruits à partir de champs analysés, et le chemin d'alimentation ne peut pas en être retrouvé.

## Configuration dans zurg {#configuring-it-in-zurg}

Le compte est une entrée de serveur `type: nzb` classique. Deux clés comptent plus que les autres.

```yaml
providers:
  - type: nzb
    nntp:
      host: your-primary.example.com
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 40
      backbone: primary-backbone
      servers:
        - name: torbox-news
          host: nntp.torbox.app
          port: 563
          tls: true
          username: YOUR_TORBOX_AUTH_ID
          password: YOUR_TORBOX_NEWS_PASSWORD
          connections: 8
          backbone: torbox
          backup: true
```

`backup: true` réserve les dix connexions aux articles que tous les autres comptes ont déjà refusés. Un primaire chargé ne bascule pas vers lui. Seul un vrai *no such article* le fait. Voir [les clés des fournisseurs](../reference/config.md) pour savoir comment `backup` et `backbone` se comportent.

Configurez 8 plutôt que 10. La limite compte aussi les connexions encore en cours de poignée de main (handshake), donc un pool qui atteint la limite se refusera lui-même lors d'un démarrage à froid. Garder deux connexions libres laisse aussi de la marge pour lancer une vérification à la main sans faire tomber la production. Ne pointez jamais un second client vers les mêmes identifiants. Deux consommateurs d'un compte à dix connexions se priveront mutuellement de connexions, et le serveur refuse le plus ancien détenteur plutôt que le plus récent.

## Ce qu'il contient vraiment {#what-it-actually-holds}

La couverture a été mesurée par rapport à trois autres serveurs sur les mêmes identifiants d'articles. L'échantillon comporte 177 releases tirées d'une bibliothèque NZB zurg en service. Les dates de publication vont de 2011 à 2026. Trois articles ont été prélevés dans chaque release, à intervalles réguliers dans le fichier. Cela donne 531 identifiants de message. Chaque identifiant a été demandé à quatre comptes, avec une connexion chacun. Les trois autres sont un compte Omicron passant par Tweaknews, un compte Eweka et un compte Frugal.

| Année de publication | ids | `nntp.torbox.app` | `newshosting.tweaknews.eu` | `news.eweka.nl` | `newswest.frugalusenet.com` |
|---|---|---|---|---|---|
| 2011 | 9 | 0 | 9 | 0 | 0 |
| 2012 | 21 | 16 | 21 | 21 | 21 |
| 2013 | 36 | 30 | 33 | 33 | 33 |
| 2014 | 36 | 33 | 36 | 36 | 36 |
| 2015 | 33 | 17 | 31 | 24 | 26 |
| 2016 | 36 | 31 | 36 | 36 | 36 |
| 2017 | 36 | 21 | 33 | 27 | 19 |
| 2018 | 36 | 16 | 36 | 24 | 24 |
| 2019 | 36 | 30 | 36 | 36 | 36 |
| 2020 | 36 | 34 | 36 | 36 | 36 |
| 2021 | 36 | 25 | 36 | 33 | 30 |
| 2022 | 36 | 29 | 36 | 27 | 27 |
| 2023 | 36 | 15 | 29 | 22 | 16 |
| 2024 | 36 | 23 | 35 | 32 | 33 |
| 2025 | 36 | 28 | 36 | 31 | 31 |
| 2026 | 36 | 30 | 36 | 30 | 30 |
| **Total** | **531** | **378 (71.2%)** | **515 (97.0%)** | **448 (84.4%)** | **434 (81.7%)** |

TorBox a répondu pour moins de cette bibliothèque que n'importe lequel des trois serveurs payants.

Le chiffre qui décide si l'emplacement mérite sa place est un autre. **TorBox n'avait rien que les autres n'avaient pas.** Pas un seul article sur 531. Comparé au compte Omicron, c'est un sous-ensemble strict, sans aucun article qui lui soit propre. Il avait 9 articles que Frugal n'avait pas et 6 qu'Eweka n'avait pas. Tous étaient aussi chez Omicron. En revanche, le compte Omicron seul avait 61 articles qu'aucun autre serveur n'avait.

Un échec sur ce serveur est réel, ce n'est pas un serveur occupé qui répond mal. Les 153 échecs ont été redemandés sur une nouvelle connexion quelques minutes plus tard, et aucun n'a abouti. Une exécution antérieure de même forme a redemandé 77 échecs et en a récupéré 1. Donc environ 1 pour cent d'une réponse négative est du bruit, et le reste est une absence.

Un succès est réel aussi. Vingt articles que les quatre serveurs annonçaient ont ensuite été récupérés en entier avec `BODY`. Les quatre ont livré 20 sur 20. Un `STAT` sur ce serveur peut être considéré comme signifiant que les données arriveront.

Le débit d'une seule connexion a été mesuré dans les mêmes exécutions, mais il n'est pas indiqué ici car il n'était pas stable. Trois séries depuis un même hôte placent TorBox entre 1,6 et 7,4 Mo/s, les trois autres se chevauchant dans cette plage sans ordre constant. Pour dimensionner un pool, mesurez depuis votre propre hôte.

Trois réserves accompagnent le tableau. L'échantillon provient de la bibliothèque d'un seul opérateur, il reflète donc ce que cette bibliothèque collecte. Trois articles d'une même release ne sont pas indépendants les uns des autres, donc une cellule par année représente en réalité douze releases et non trente-six. Et une réponse `STAT` est une affirmation sur un article, pas un verdict sur une release entière.

## Vaut-il une place ? {#is-it-worth-a-slot}

Le compte ne coûte rien de plus parce qu'il est inclus avec Pro. C'est son argument le plus fort.

Ce n'est pas un backbone de rétention, et le configurer comme tel vous décevra. Sur une bibliothèque réelle, il a répondu pour moins d'articles que les trois comptes payants auxquels il a été comparé, et il n'a produit aucun article qu'un autre compte n'avait pas déjà refusé. Une pile qui a déjà un compte Omicron ne gagne rien à en ajouter un de plus.

Il reste deux usages honnêtes. Une configuration à un seul fournisseur gagne un second avis gratuit, et n'importe quel second avis vaut mieux qu'aucun. Et `backup: true` rend une mauvaise supposition peu coûteuse, car un compte de secours n'est sollicité qu'après que tous les comptes principaux ont répondu qu'il n'existe aucun article de ce type.
