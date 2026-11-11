# Le point de terminaison MCP {#the-mcp-endpoint}

zurg peut répondre à un agent IA via le [Model Context Protocol](https://modelcontextprotocol.io) :
le client demande quels outils existent, zurg les décrit, et l'agent les appelle pour lire la bibliothèque, comprendre pourquoi une release ne se lit pas, la réparer ou piloter les serveurs multimédias. Ce sont les mêmes opérations que celles exposées par le tableau de bord et la CLI, sous forme d'outils typés avec des schémas, plutôt que sous forme de HTML et de redirections 303.

Le point d'accès est désactivé par défaut. Il est protégé par la même authentification basique que le tableau de bord, et zurg refuse de le servir du tout si aucun nom d'utilisateur n'est configuré. Avec un nom vide, toutes les routes du serveur sont publiques, et ces outils suppriment des releases.

## Configuration

```yaml
mcp:
  enabled: true
```

C'est tout ce qu'il faut pour une installation normale. Le reste a des valeurs par défaut qui valent le coup d'être connues :

```yaml
mcp:
  enabled: true
  toolsets: [library, releases, repair]   # the default; see below
  read_only: false                        # withhold every tool that changes anything
  allow_unauthenticated: false            # serve /mcp with no username set
  allow_lifecycle: false                  # admit the tools that stop zurg or its mount
  page_limit: 50                          # items a listing returns by default; 500 is the cap
  max_result_kb: 256                      # ceiling on one result; a page over it is trimmed
  session_timeout_mins: 30                # -1 keeps sessions for the life of the process
```

Comme les autres blocs de fonctionnalités, celui-ci n'est lu qu'une fois au démarrage : pour qu'un changement soit pris en compte, il faut redémarrer.

## Connexion {#connecting}

### Via HTTP {#over-http}

L'endpoint est `/mcp` sur le port habituel de zurg, avec le transport Streamable HTTP. Pointez un client vers `http://<host>:9999/mcp` avec les identifiants du tableau de bord.

```bash
npx @modelcontextprotocol/inspector
# Transport:  Streamable HTTP
# URL:        http://localhost:9999/mcp
# Header:     Authorization: Basic <base64 of user:password>
```

### Via stdio {#over-stdio}

Les clients qui ne parlent que stdio utilisent la sous-commande `zurg mcp`, qui fait le pont avec une instance de zurg déjà en cours d'exécution :

```json
{
  "mcpServers": {
    "zurg": {
      "command": "/path/to/zurg",
      "args": ["mcp"],
      "cwd": "/path/to/your/zurg/directory"
    }
  }
}
```

Le `cwd` compte : tous les chemins de zurg sont résolus par rapport au répertoire de travail, et c'est là que `zurg mcp` lit `config.yml` pour le port et les identifiants. Avec ça, aucun argument n'est nécessaire. `--username` et `--password` remplacent les identifiants locaux. Une `--url` personnalisée n'hérite jamais des identifiants de la config locale : passez les deux options d'identifiants explicitement si ce point de terminaison en a besoin, pour qu'un mot de passe local ne soit pas envoyé à un autre hôte par accident.

Elle ne démarre pas de seconde instance. Une seconde zurg chargerait toute la bibliothèque, prendrait un second jeu de slots chez le fournisseur (des comptes facturés à l'usage), et se battrait avec la première pour le montage. La commande n'est donc qu'un tube vers le daemon, et elle ne sert rien quand le daemon n'est pas lancé. Ses diagnostics vont sur stderr, car stdout transporte le protocole.

Une limite : une notification que le serveur émet en dehors de tout appel ne traverse pas le pont. Les lignes de progression et de log émises *pendant* un appel voyagent dans la réponse de cet appel et arrivent normalement, ce qui couvre tout ce que zurg envoie.

## Jeux d'outils {#toolsets}

L'ensemble complet des outils de zurg compte quelques centaines d'outils, ce qui est plus qu'un client ne gère bien. Au-delà d'environ quatre-vingts, un modèle choisit plus souvent le mauvais outil, et les schémas seuls coûtent des dizaines de milliers de jetons. Donc `toolsets` sélectionne des groupes, et la valeur par défaut est un sous-ensemble utilisable plutôt que tout.

| Groupe | Par défaut | Ce qu'il couvre |
|---|:-:|---|
| `library` | oui | Recherche, listings de répertoires, nombre de tags |
| `releases` | oui | Une release en détail : fichiers, copies par compte, ce qui peut servir chaque fichier |
| `repair` | oui | Ce qui est cassé, si la réparation va l'atteindre, forcer une réparation |
| `releases_write` | | Supprimer, renommer, taguer, forcer l'affichage, écrire des fichiers `.strm` |
| `magic` | | L'espace de noms `__magic__` : la disposition stockée, ses lignes, et le déplacement des éléments |
| `plex` | | Plex, Jellyfin et Emby : statut, correspondance et analyse protégée |
| `providers` | | Les comptes configurés : ce que chacun peut faire, s'il est joignable, ce qu'il a dépensé |
| `usenet` | | Le backend NZB : comptes news, sondes d'articles, dégâts et cache des articles |
| `clients` | | Les points de terminaison SABnzbd, qBittorrent et Stremio auxquels Sonarr et Radarr se connectent |
| `diagnostics` | | Le journal, les compteurs d'octets, la mémoire et les goroutines |
| `config` | | Lire la configuration, détecter les dérives et écrire un ensemble choisi de clés |
| `mount` | | Le montage rclone : statut, oublier les listings en cache, le redémarrer |
| `system` | | Informations sur la build, `doctor`, le service, les sauvegardes et les mises à jour |

`toolsets: [all]` active tous les groupes. Un nom précédé de `-` le retire, donc `[all, -config, -system]` donne tout le périmètre sans les deux groupes qui modifient la machine plutôt que la bibliothèque. Un nom non reconnu génère un avertissement au démarrage et est ignoré : une faute de frappe ne doit pas supprimer le point de terminaison.

Les outils qui arrêtent zurg, contrôlent son service ou redémarrent le montage ne forment pas un groupe à part : ils se trouvent dans `system` et `mount`, et restent masqués tant que `allow_lifecycle` n'est pas activé, quelle que soit la valeur de `toolsets`.

Un petit groupe `server` — ce qu'est cette build et si la bibliothèque a fini de charger — est toujours enregistré, quelle que soit la valeur de `toolsets`. Le masquer laisserait un client incapable de savoir que toutes les autres réponses sont actuellement partielles.

## Ce qu'il ne fera pas sans demande explicite {#what-it-will-not-do-without-being-asked}

**Confirmation.** Un outil qui retire quelque chose décrit ce qu'il ferait
et renvoie un jeton ; il n'agit que lorsqu'on le rappelle avec ce jeton. Le
jeton est dérivé du plan, donc une confirmation ne peut pas valoir pour un
autre plan : si la bibliothèque a changé entre-temps, le second appel se
contente de décrire au lieu d'agir. Les jetons ne sont utilisables qu'une
fois, durent deux minutes et ne survivent pas à un redémarrage.

**`read_only`.** Un seul interrupteur qui retire tous les outils qui modifient
quoi que ce soit, quel que soit le contenu de `toolsets`. La question que se
pose vraiment l'administrateur est « est-ce que ça peut casser ma
bibliothèque ? », pas « lequel de ces outils écrit ? ». Ces outils sont
omis de `tools/list`, afin qu'un client ne puisse pas sélectionner une
capacité que ce point d'accès n'acceptera jamais. Le contrôle au moment de
l'appel reste en place en défense en profondeur, au cas où le réglage en
cours d'exécution changerait après la construction du serveur.

**`allow_lifecycle`.** Les outils qui arrêtent zurg, contrôlent son service ou
relancent le montage sont retirés de la même façon, derrière un interrupteur
distinct. Chacun peut faire disparaître d'un coup toute la bibliothèque, et
les actions sur le processus ou le service ne peuvent pas rendre compte de
leur propre résultat, car elles peuvent mettre fin au processus qui répond à
l'appel.

**Secrets.** Aucun résultat d'outil ne contient un jeton de fournisseur, une
clé d'API, un mot de passe de serveur Usenet, un lien CDN résolu ni une URL
`.strm` signée. Les journaux sont caviardés à la sortie. Quiconque détient un
lien résolu peut l'utiliser sur le compte qui l'a généré, et une transcription
n'est pas un endroit où le mettre.

**Taille.** Chaque liste est limitée deux fois : par une limite de pages et
par un plafond sur le résultat sérialisé. Un compte mesuré à l'aune de cette
règle compte 84 000 versions, soit environ douze mégaoctets de noms avant
même que le moindre fichier ne soit listé. Un résultat qui dépasse le plafond
est tronqué, et le résultat indique qu'il a été tronqué.

## Notes

Le point de terminaison hérite de l'authentification basique du tableau de bord, puisqu'il est enregistré à l'intérieur de celui-ci.
Une requête d'origine croisée est refusée : `/mcp` est destiné à un agent local, pas à une page web.
Un reverse proxy placé devant zurg fonctionne. Le contrôle DNS-rebinding de la bibliothèque du protocole rejetterait sinon un proxy qui transmet son propre `Host` tout en se connectant à `127.0.0.1`. zurg désactive donc ce contrôle et laisse la protection à l'authentification basique.

`zurg mcp --help` liste les options du pont. `zurg doctor` vérifie si le point de terminaison répond.
