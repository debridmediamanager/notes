# L'addon Stremio {#the-stremio-addon}

zurg peut répondre à Stremio en tant qu'addon. Stremio demande par identifiant IMDb. zurg cherche sur tes indexeurs Newznab et récupère le NZB de la release choisie dans le backend Usenet. Il la lit ensuite et la répare comme n'importe quelle autre release zurg.
Tout ce qui est lu de cette façon se retrouve aussi dans la bibliothèque et apparaît dans Plex.

## Configuration

L'addon a besoin d'un compte NZB, `nzb` ou
[`torbox_nzb`](../providers/torbox-nzb.md), qui fournit les données, et
d'au moins un indexeur. Avec `torbox_nzb`, une release que TorBox a déjà
démarre pendant le délai d'attente de l'addon si aucun autre post NZB n'attend. Une release non mise en cache doit
d'abord se terminer sur TorBox, ce qui prend plus de temps qu'un lecteur n'attend.

```yaml
stremio:
  enabled: true
  # token: ""            # generated and kept in data/stremio-token when empty
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_KEY
    - name: second-indexer
      url: https://second-indexer.example
      api_key: YOUR_KEY
      api_path: /api/v1/api   # for an indexer that 404s the default /api
```

Tout se règle sur la page de configuration, sous **Stremio Addon** : l'interrupteur, la
liste des indexeurs et la limite de résultats. L'URL de l'addon y est affichée avec un
bouton de copie, construite à partir de l'adresse que tu as utilisée pour ouvrir le tableau de bord. C'est
cette adresse qu'il faut utiliser : voir [Installer sur un autre appareil](#installing-it-on-another-device).

Au démarrage, zurg écrit l'URL de l'addon dans les logs :

```
<zurg>/stremio/<token>/manifest.json
```

Colle-la dans Stremio (Addons → la barre de recherche accepte une URL). Le token dans le chemin
est toute l'autorisation : les clients Stremio n'envoient pas d'authentification propre, donc les routes
sont placées en dehors de l'authentification basique, comme le sont celles du point d'accès SABnzbd. Traite l'URL
comme un mot de passe : les liens de lecture qu'elle génère contiennent tes clés API d'indexeur, et
quiconque la possède peut consommer tes téléchargements d'indexeur et tes connexions au serveur de news.

## Installer sur un autre appareil {#installing-it-on-another-device}

Stremio n'accepte un addon en `http` simple que sur l'ordinateur où Stremio tourne lui-même. Ça veut dire `http://127.0.0.1` ou `http://localhost` sur la machine qui fait tourner zurg. Partout ailleurs, il faut du `https`. Une TV, un téléphone ou un second ordinateur affiche **failed to load manifest** pour une adresse `http://`, même quand il peut très bien joindre zurg. Ça vaut aussi pour une adresse LAN ou une adresse Tailscale. La page de configuration le signale juste à côté de l'URL de l'addon si tu l'as ouverte en `http` simple sur une adresse de ce type.

zurg ne sert pas de `https` tout seul. Mets devant lui quelque chose qui le fait. Ensuite, ouvre la page de configuration sur l'adresse `https` et copie l'URL de l'addon depuis là. zurg construit l'URL de l'addon et chaque lien de lecture à partir de l'adresse sur laquelle chaque requête est arrivée. Il n'y a pas de réglage d'URL publique, et `base_url` n'est pas utilisé ici. Un seul zurg peut servir en même temps un lecteur sur le LAN et un lecteur à distance.

Ce qui se trouve devant doit donner deux informations à zurg. Le nom vient de l'en-tête `Host` ou de `X-Forwarded-Host`. Le schéma vient de `X-Forwarded-Proto: https`. Sans cet en-tête, l'addon se charge, mais les liens de lecture reviennent en `http://` et la lecture échoue. Chaque option ci-dessous envoie les deux.

Stremio utilise deux chemins. `/stremio/` est l'addon. `/strm/e/` est l'endroit où le bouton lecture envoie le lecteur pour la vidéo. Les deux fonctionnent sans le mot de passe de zurg, parce que Stremio ne peut pas en envoyer un. C'est le token dans l'URL de l'addon qui les protège. Quand zurg est exposé sur internet, ne publie que ces deux chemins. Le reste, c'est ton tableau de bord et ta bibliothèque.

### Tailscale Serve

La solution la plus simple quand chaque appareil qui utilise Stremio peut faire tourner Tailscale. zurg reste hors d'internet.

1. Dans la console d'administration Tailscale, active MagicDNS et HTTPS certificates.
2. Lance ceci sur la machine zurg. Utilise ton propre port si zurg n'est pas sur 9999.

   ```bash
   tailscale serve --bg 9999
   ```

   Sur Windows, lance la même commande dans PowerShell et, si elle répond access denied, dans un PowerShell ouvert en administrateur. Sous Linux, ajoute `sudo` devant, sauf si tu t'es défini comme opérateur Tailscale (`sudo tailscale set --operator=$USER`). Sur macOS, si `tailscale` renvoie not found, la copie de l'application Tailscale est `/Applications/Tailscale.app/Contents/MacOS/Tailscale`.

3. Ouvre `https://<machine>.<tailnet>.ts.net/config/` et copie l'URL de l'addon depuis la carte **Stremio Addon**.

Tailscale obtient le certificat et envoie les deux en-têtes. `tailscale serve reset` le désactive à nouveau.

Un appareil qui ne peut pas faire tourner Tailscale peut utiliser Tailscale Funnel à la place. Il met la même adresse sur internet. Ne publie que ce dont Stremio a besoin.

```bash
tailscale funnel --bg --set-path /stremio http://127.0.0.1:9999/stremio
tailscale funnel --bg --set-path /strm/e http://127.0.0.1:9999/strm/e
```

La page de configuration n'est pas sur cette adresse. Copie l'URL de l'addon depuis la page comme tu l'ouvres d'habitude, et remplace le début par `https://<machine>.<tailnet>.ts.net`. Tailscale limite la bande passante d'un Funnel. Un remux 4K risque de saccader.

### Votre propre reverse proxy {#your-own-reverse-proxy}

Vous avez déjà un reverse proxy avec un domaine et un certificat ? Ajoutez-y zurg.
Caddy conserve l'en-tête `Host` et envoie `X-Forwarded-Proto` de lui-même.
Cela ne publie que les deux chemins Stremio, et rien d'autre.

```
zurg.example.com {
    handle /stremio/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle /strm/e/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle {
        respond 404
    }
}
```

nginx n'envoie aucun des deux en-têtes, sauf si vous les demandez tous les deux.

```nginx
location ~ ^/(stremio|strm/e)/ {
    proxy_pass http://127.0.0.1:9999;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
}
```

Placez cela dans le bloc `server` qui écoute déjà sur le 443 avec votre certificat. `proxy_buffering off` permet au flux vidéo de passer directement, sans passer par les tampons de nginx.

### Cloudflare Tunnel

Un tunnel nommé donne à zurg une adresse `https` sur un domaine que tu as sur Cloudflare, sans ouvrir de port. Cloudflare garde l'en-tête `Host` et envoie `X-Forwarded-Proto` de son côté. Ne route que les chemins Stremio dans le `config.yml` du tunnel.

```yaml
ingress:
  - hostname: zurg.example.com
    path: ^/(stremio|strm/e)/
    service: http://127.0.0.1:9999
  - service: http_status:404
```

Deux choses à savoir d'abord. Cloudflare abandonne une requête au bout de 100 secondes. La première lecture d'une release peut prendre plus de temps que ça. Appuie de nouveau sur lecture et ça démarre. Et les conditions de Cloudflare lui permettent de limiter les comptes qui envoient beaucoup de vidéo via son réseau sans forfait payant. Chaque lecture passe par le tunnel.

## Ce que fait une lecture {#what-a-play-does}

Choisir un flux, c'est un grab : zurg télécharge le NZB depuis l'indexeur, le dépose dans `nzbs/` (avec les mêmes règles de nommage que l'endpoint SABnzbd, donc une release récupérée deux fois, ou déjà récupérée par un *arr, est retrouvée et non dupliquée), attend que la bibliothèque la liste, puis redirige le lecteur vers l'endpoint signé `/strm/e/` que chaque fichier `.strm` utilise déjà pour la lecture : lectures par plages, bascule de compte, intérieurs RAR/7z.

La première lecture d'une release prend donc plus de temps qu'un flux debrid : le NZB doit être récupéré et analysé, et l'intérieur d'une archive doit être lu. Cela prend en général quelques secondes, et jusqu'à une minute ou deux pour un post obfusqué dont la passe de renommage doit tourner. Une lecture qui dépasse le délai d'attente répond 503 avec un Retry-After. Appuyer de nouveau sur lecture tombe alors sur le chemin rapide. Chaque lecture suivante est immédiate.

Une release qui apparaît dans la liste mais ne contient rien de lisible (en général une release sortie du spool, dont chaque fichier a été marqué cassé par la vérification du serveur de news) ne met pas fin au clic. L'URL de lecture porte la requête pour laquelle elle a été générée, donc zurg reclasse les releases du titre et essaie les lignes situées après celle choisie, chacune par le même chemin grab-et-liste. La première qui se lit est celle vers laquelle le lecteur est redirigé. Zurg parcourt toute la réponse, et pas seulement les lignes affichées : `max_results` représente ce qu'une personne veut faire défiler. Si on laissait aussi cette valeur borner la récupération, un titre affiché à dix lignes de profondeur ne pourrait essayer que neuf releases, même si la recherche en avait trouvé davantage. Les lignes *après* le choix sont là exprès : elles ont la même résolution et sont plus petites, ou ont la résolution inférieure. Jamais une release plus grosse que celle que l'utilisateur a laissé passer. Un repli qui est lui-même encore en cours d'ingestion répond le même 503, et appuyer de nouveau sur lecture le résout : la release refusée est refusée tout de suite, et le repli est trouvé sur le chemin rapide. Seul ce refus final passe au suivant ; un 503 ne passe jamais au suivant. Chaque essai consomme un grab de l'indexeur et laisse sa release dans la bibliothèque comme tout autre grab. La chaîne est donc bornée par un budget de vingt-cinq secondes et un plafond de six essais. Le budget est le facteur limitant, car les essais ne coûtent pas le même prix : une release sortie du spool est refusée en moins d'une seconde, alors qu'une release qui s'ingère et ouvre une archive avant de se révéler vide peut à elle seule consommer la plus grande partie du budget. Quand toutes les lignes essayées sont refusées, la réponse est le 404 qu'elle a toujours été. Chaque repli est journalisé au niveau info, avec la release refusée et la release essayée ensuite.

Mesuré par rapport à trois autres addons Stremio adossés à Usenet, le 7 septembre 2026 : stremio-addon-findings-2026-09-07.md.
En bref, le plafond par résolution a corrigé ce que le cycle précédent avait trouvé, mais la couverture a quand même été divisée par deux. Un compartiment de cinq entrées n'a nulle part où aller quand sa première entrée lisible est une release sortie du spool. Le repli décrit plus haut est le premier correctif issu de ce cycle. Le compartiment est depuis passé de cinq à dix entrées.

## Comportement de la recherche {#search-behaviour}

- Films : recherche `t=movie`, épisodes `t=tvsearch` avec `season`/`ep`, tous deux par
  `imdbid`, en chiffres seuls, car plusieurs indexeurs renvoient zéro résultat avec la forme `tt`.
- Chaque indexeur est interrogé pour `search_limit` releases (100 par défaut). Chaque limite ci-dessous choisit parmi ce qui a été demandé, donc elle constitue le plafond de la réponse.
- Les indexeurs sont interrogés en parallèle. Si l'un refuse (limite de rafale, clé morte), il coûte ses résultats, pas la liste entière. Les refus sont journalisés par indexeur.
- Les résultats sont dédoublonnés par nom de release, classés par résolution d'abord puis par taille, et limités à `max_results` (10 par défaut) *par résolution*. Le plafond se compte par résolution parce que le tri commence par 2160p : un titre populaire a plus de releases UHD sous le plafond de taille que n'importe quel plafond. Si on comptait sur toute la liste, chaque titre populaire n'aurait que des remux, quoi que la recherche ait trouvé d'autre.
- Ce que chaque résolution garde, c'est un éventail de ses tailles, et non ses plus grosses : des choix régulièrement espacés, de la release la plus lourde à la plus légère, les deux extrémités étant toujours incluses. Si on ne gardait que le haut, un palier 1080p de cinq serait cinq remux entre 19 et 30 Go, et l'encodage de 4 Go qu'un téléphone ou un ordinateur portable lit directement serait justement ce que le plafond supprime. Mesuré le 7 septembre 2026, trois des quinze entrées de zurg pour The Shawshank Redemption faisaient moins de 6 Go, contre quarante releases de ce type sur les mêmes indexeurs. La liste reste triée par taille décroissante au sein d'une résolution. Une release dont l'indexeur n'a pas indiqué la taille n'a pas de place sur cet axe ; elle ne remplit que la place que laissent les releases dimensionnées.
- La description de chaque stream indique le nom de la release, sa taille, l'indexeur qui l'a trouvée, et depuis combien de temps elle a été publiée (`3d`, `126d`, `2y`) quand l'indexeur le donne. Le vieillissement sur le serveur de news était la cause la plus fréquente d'échec de lecture lors du test du 7 septembre, et la date de publication est le seul signal qui permet au spectateur de l'éviter.
- Les releases plus lourdes que `max_size_gb` sont écartées avant le classement, pour un lecteur qui ne peut pas lire un remux. Il n'y a pas de limite par défaut : l'éventail ci-dessus affiche déjà la plus petite release de chaque résolution à côté de ses remux. Les tailles non indiquées par l'indexeur sont conservées. Le filtre s'applique à l'affichage de la liste, donc changer le plafond prend effet aussi sur les titres en cache.
- Les résultats sont mis en cache sur le disque (`data/stremio-cache/`, un fichier par titre), donc rouvrir un titre ne coûte aucun appel aux indexeurs. Ils ont souvent un quota journalier, et Treasure Maps refuse après environ six requêtes rapprochées. La durée de vie d'une réponse dépend de ce que la recherche a trouvé : une liste maigre indique que les envois arrivent encore ou qu'un indexeur était en panne. Un résultat vit une heure, deux vivent deux heures, jusqu'à quatre ; cinq ou plus est une réponse définitive et vit `cache_hours` (24 par défaut, le seul palier configurable). Une réponse vide n'est jamais mise en cache. Une liste de streams en cache porte en bas un élément **refresh** qui indique son âge. L'ouvrir (il s'ouvre dans un navigateur, pas dans le lecteur) vide le cache de ce titre, et rouvrir le titre relance une recherche. Le cache survit aux redémarrages, et les entrées expirées se nettoient toutes seules.
- La saison 0 (spéciaux) est refusée plutôt que mal recherchée, et la couverture de la recherche par identifiant dépend de l'indexeur : une release que l'indexeur ne trouve que par recherche textuelle n'apparaîtra pas.
