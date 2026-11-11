# Serveur de news ElfHosted {#elfhosted-news-server}

ElfHosted regroupe un compte Usenet avec ses offres d'addon Stremio et l'appelle Usenet Essential. Cette
page décrit ce que ce serveur est. Tout ce qui suit a été mesuré le 2026-09-04 depuis un seul hôte. Le
compte lui-même n'a pas pu être mesuré, parce que le seul identifiant qu'ElfHosted a jamais publié ne
fonctionne plus, et c'est la première découverte.

## Ce qui répond sur le réseau {#what-answers-on-the-wire}

`news.elfhosted.com` résout vers `94.232.116.124` et parle NNTP sur TLS 1.3 via le port 563, derrière un certificat Let's Encrypt pour `news.elfhosted.com`. Le certificat ne porte que ce nom et rien d'autre, et il a été émis le 2026-08-17. Le même serveur répond en clair sur le port 119 avec le même message d'accueil. Ce message est `200 Welcome to elfhosted`.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
AUTHINFO USER
```

C'est la même chaîne `nntpswitch2` que celle signalée par le [lecteur TorBox](torbox-news-server.md). Cette liste est celle sans authentification, donc elle s'arrête à `AUTHINFO USER` et non à `POST`. `HELP` répond sans identifiants et liste l'ensemble complet des commandes, y compris `POST`, `IHAVE`, `XPAT` et `XGTITLE`. L'absence de `POST` vient donc de la session et non du serveur.

Trois commandes fonctionnent avant l'authentification, et aucune autre.

| Commande | Réponse |
|---|---|
| `DATE` | `111 20260903225242` |
| `HELP` | `100 Help follows.` |
| `CAPABILITIES` | `101 Capabilities.` |
| `MODE READER` | `480 Authentication required for command.` |
| `GROUP` et `LIST` et `STAT` et `POST` | `480 Authentication required for command.` |

## Qui le gère {#who-runs-it}

Le page TorBox devait déduire l'opérateur à partir de la proximité. Ici ce n'est pas le cas. `news.elfhosted.com` se trouve à l'intérieur même du bloc de lecteurs d'Abavia.

`94.232.116.124` fait partie de `94.232.112.0/21`, `AS48345 AS-ABAVIA`, enregistré au nom d'Abavia S.r.l., à Saint-Marin. Un balayage inverse de `94.232.116.0/24` renvoie 79 noms. Quarante-cinq d'entre eux répondent en NNTP sur le port 563, et les quarante-cinq annoncent `nntpswitch2 (local-dev)` avec des listes de capacités identiques octet pour octet, dans le même ordre. Les routeurs de bordure d'Abavia se trouvent dans le même /24, tout comme les alimentations XS News, le serveur web et le serveur de noms.

| Adresse | Lecteur | Message d'accueil |
|---|---|---|
| `94.232.116.122` | `reader2.newsxs.nl` | `200 Welcome to Newsxs` |
| `94.232.116.124` | `news.elfhosted.com` | `200 Welcome to elfhosted` |
| `94.232.116.125` | `reader.spotnews.nl` | `200 Welcome to Spotnews` |
| `94.232.116.128` | `reader.easyusenet.nl` | `200 Welcome to Easyusenet` |
| `94.232.116.131` | `reader.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.135` | `reader-usenetfarm.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.136` | `reader.torrentclaw.com` | `200 Welcome to TorrentClaw` |
| `94.232.116.140` | `reader.usenet.nl` | `200 Usenet.nl S.r.l.` |
| `94.232.116.147` | `giganews.hostredirects.com` | `200 Welcome to giganews` |
| `94.232.116.150` | `news.usenext.de` | `200 Welcome to Aviteo Ltd DE` |
| `94.232.116.174` | `news.hitnews.com` | `200 Welcome to Hitnews` |

ElfHosted se trouve à quatre adresses de Easyusenet, à sept de XS News et à douze de TorrentClaw, qui est un autre addon Stremio s'appuyant sur la même plateforme.

Il n'y a pas de multiplexage par nom. Se connecter à l'adresse avec un servername `reader.xsnews.nl`, ou avec un nom qui n'existe pas du tout, renvoie le même certificat et le même message d'accueil `200 Welcome to elfhosted`. Une adresse par marque.

TorBox n'est pas dans ce bloc. Il se trouve sur `78.152.55.171`, dans `AS3257 GTT`, aux Pays-Bas. L'attribution à ElfHosted est donc la plus solide des deux. TorBox fait tourner le même logiciel à côté d'une marque de cette famille. ElfHosted le fait tourner dans l'espace d'adressage propre à Abavia.

**Mesuré** désigne l'empreinte logicielle, la propriété des adresses, le certificat et l'absence de multiplexage par nom. **Déduit** désigne le fait que le spool derrière tout cela appartient à Abavia et n'est pas un mélange assemblé par ElfHosted. Rien sur le réseau ne permet de distinguer ces deux points sans identifiants.

## L'identifiant publié ne fonctionne plus {#the-published-credential-is-dead}

Le 2025-12-20, ElfHosted a annoncé un accès NNTP inclus avec NzbDav, dans le cadre d'une preuve de concept de deux mois, avec un fournisseur d'infrastructure Usenet non nommé. Ils ont aussi publié un identifiant partagé dans l'annonce.

| Champ | Tel que publié, 2025-12-20 |
|---|---|
| Hôte | `news.elfhosted.com` |
| Port | 563 SSL |
| Nom d'utilisateur | `elfie` |
| Mot de passe | `elfie` |
| Connexions | 100 |
| Coût | aucun jusqu'en février 2026 |

Il était préconfiguré dans NzbDav pour les nouveaux utilisateurs. L'annonce indiquait que l'accord serait réexaminé à la fin de la preuve de concept. C'est ce qui s'est passé, et l'identifiant n'authentifie plus.

```
200 Welcome to elfhosted
381 Need more.
482 Invalid username or password
```

Sur ce logiciel, `482 Invalid username or password` est bien la réponse d'un identifiant mort, et non la limite de connexions, qui renvoie plutôt `482 too many connections for your user`. Le timing confirme cela. Cinq tentatives avec un nom d'utilisateur qui n'a jamais existé et deux tentatives avec `elfie` donnent le même refus dans la même enveloppe.

| Tentative | Réponse | Temps |
|---|---|---|
| Nom d'utilisateur aléatoire, cinq tentatives | `482 Invalid username or password` | médiane 2066 ms, plage de 2043 à 2070 ms |
| `elfie` et `elfie`, deux tentatives | `482 Invalid username or password` | 2043 ms et 2212 ms |

Ici, un identifiant retiré et un nom d'utilisateur jamais attribué sont impossibles à distinguer, aussi bien dans le code que dans le timing. Environ deux secondes, c'est le temps que met ce logiciel pour dire non, ce que fait aussi le lecteur TorBox.

Le chiffre de 100 connexions correspond donc à une offre terminée. C'est le seul chiffre qu'ElfHosted ait jamais publié pour ce serveur, et il ne s'applique à rien que vous puissiez acheter aujourd'hui. Le forfait payant Usenet Essential délivre probablement un identifiant par client, mais on ne peut pas le vérifier depuis l'extérieur.

La même annonce publiait aussi un endpoint Newznab interne à `elfhosted-internal.zyclops`, qui accepte n'importe quelle clé API et peut être filtré pour ne garder que les résultats sains connus pour un backbone donné. C'est ce qu'entend la boutique ElfHosted lorsqu'elle dit qu'un forfait Usenet inclut l'indexeur. Cet endpoint fournit des signaux de disponibilité et de santé, pas du contenu, et leur propre formulation le présente comme une boule de cristal pour la santé de l'infrastructure, et non comme une carte au trésor. Un forfait a quand même besoin d'un vrai indexeur en plus.

## Ce qui n'a pas pu être mesuré {#what-could-not-be-measured}

Tout ce qui permet de savoir si un emplacement chez le fournisseur vaut la peine d'être rempli. Tout cela nécessite des identifiants.

| Property | State |
|---|---|
| Connection cap | inconnue, le 100 ne s'applique qu'à l'ancienne preuve de concept |
| Retention | jamais publiée |
| Groups in `LIST ACTIVE` | nécessite une authentification |
| Article number window | nécessite une authentification |
| Coverage against other backbones | nécessite une authentification |
| Single connection throughput | nécessite une authentification |
| Posting | le serveur propose `POST`, le compte est inconnu |

Un essai de sept jours coûte un dollar et permet d'obtenir l'identifiant. Lancer le même balayage de 531 message ids que celui utilisé sur la
[page TorBox](torbox-news-server.md#what-it-actually-holds), pendant cette semaine, répondrait à chaque ligne du tableau ci-dessus.

## Ce que la plateforme vous indique déjà {#what-the-platform-already-tells-you}

Deux points restent valables d'après les mesures faites sur TorBox, et un ne l'est pas.

Restent valables : la sémantique et le moment des refus. C'est le même logiciel, donc les mêmes réponses. Ainsi, `482 Invalid username or password` signifie ici aussi un identifiant mort, et la limite est une autre chaîne de caractères.

Reste valable : la fenêtre des numéros d'article. Un lecteur `nntpswitch2` génère les numéros d'article sur une courte fenêtre, donc tout ce qui parcourt les numéros plutôt que les message ids voit une quinzaine de jours de Usenet. C'est une propriété de la plateforme, pas d'un seul compte. Les lectures faites avec un NZB, qui passent par les message ids, ne sont pas touchées.

Ne reste pas valable : la couverture. Le lecteur TorBox a été mesuré comme un sous-ensemble strict d'un compte Omicron, à 71.2 pour cent, avec zéro article à lui sur 531. C'était le point de terminaison de TorBox, pas celui-ci, et TorBox ne fait même pas partie de ce bloc. C'est l'a priori le plus proche, sur le même logiciel et le même opérateur, mais ce n'est pas une mesure d'ElfHosted. Considérez-le comme l'hypothèse à vérifier, et non comme la réponse.

## Configuration dans zurg {#configuring-it-in-zurg}

Si un identifiant est obtenu, c'est une entrée de serveur `type: nzb` ordinaire, à côté du principal.

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
        - name: elfhosted-news
          host: news.elfhosted.com
          port: 563
          tls: true
          username: YOUR_ELFHOSTED_USERNAME
          password: YOUR_ELFHOSTED_PASSWORD
          connections: 8
          backbone: abavia
          backup: true
```

Commence à 8 connexions et ne les augmente qu'après avoir mesuré la vraie limite. Le 100 publié est
retiré, et un pool qui ouvre au-delà d'une limite inconnue se refusera lui-même lors d'un démarrage à froid. Mets
`backbone: abavia` plutôt qu'un nom de marque, parce que XS News, Easyusenet, Hitnews, UseNeXT
et celui-ci sont la même plateforme. Les traiter comme des backbones distincts permettrait à un pool de compter
un seul spool comme plusieurs. `backup: true` le garde pour les articles que tous les principaux ont déjà refusés.

Ne connecte jamais un second client à un même identifiant. Le serveur refuse l'ancien détenteur plutôt que le
nouveau, donc un second consommateur te coûte le premier.

## Vaut-il une place ? {#is-it-worth-a-slot}

Il ne peut pas être acheté seul. Il arrive avec un forfait Stremio à neuf dollars par mois, qui
inclut aussi un addon hébergé, une instance NzbDav et un compte TorBox Essentials. Comme simple ligne
dans ce forfait, il ne coûte rien de plus, et c'est le meilleur argument en sa faveur sans
identifiant.

Face à une pile qui comprend déjà un compte Omicron, Eweka et Frugal, ajouter un quatrième lecteur
venant de cette plateforme revient au même pari que celui de la page TorBox, un pari perdu. Ce pari n'a pas été mesuré
ici, donc c'est une hypothèse de départ et non un verdict. Ce qui tranchera, c'est un dollar et une semaine, ainsi que le balayage d'identifiants 531.
