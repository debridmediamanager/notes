# Usenet

`type: nzb`

Usenet est un type de fournisseur, pas un service debrid. Il n'y a ni jeton d'API ni bibliothèque distante. Vous déposez des fichiers `.nzb` dans un dossier de surveillance et zurg transforme chacun d'eux en une release. Les articles sont récupérés depuis votre serveur de news et décodés au moment où un lecteur demande ces octets.

Cette page ne couvre que l'entrée du fournisseur et les particularités Docker. Tout le reste sur l'utilisation d'Usenet avec zurg se trouve dans [Usenet with zurg](../guides/usenet.md). C'est le guide complet, avec les comptes de news, les NZB, le montage et Plex. C'est la page à lire en deuxième.

## La configurer {#configure-it}

Il n'y a pas de `token`. Ce qui rend une entrée valide, c'est un bloc `nntp` avec un host.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
mount_path: "/zurg_mnt/zurg"
```

Réglez `connections` sur ce que votre abonnement autorise réellement. zurg lit avec ce nombre parce qu'une connexion ne transporte qu'une fraction du débit d'un abonnement. Le streaming utilise toute la capacité autorisée plutôt que de récupérer un article à la fois. Dépasser ce que l'abonnement permet entraîne des connexions refusées.

Sur une installation fraîche d'un conteneur, la configuration vous demandera tout ça.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb
```

Pour une installation sans surveillance, le mot de passe vient d'un fichier et tout le reste vient des options en ligne de commande.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb \
  --nntp-host news.example.com \
  --nntp-username YOUR_USENET_USERNAME \
  --nntp-password-file /config/secrets/nntp \
  --nntp-connections 8
```

`--nntp-tls` vaut true par défaut et `--nntp-port` vaut 563 avec TLS, ou 119 sans TLS.

Sur une installation qui a déjà un `config.yml`, utilisez **Add provider** dans le Dashboard à l'adresse `http://localhost:9999/config/`, ou modifiez le fichier. Dans les deux cas, redémarrez.

```bash
docker compose restart zurg
```

## Où vont les NZB dans un conteneur {#where-the-nzbs-go-in-a-container}

Le dossier de surveillance est `nzbs/`, à côté de la configuration. Cela correspond à `~/zurg/nzbs/` sur l'hôte et à `/config/nzbs/` dans le conteneur. C'est le même dossier. Dépose les fichiers depuis l'hôte.

```bash
mkdir -p ~/zurg/nzbs
cp /path/to/some.nzb ~/zurg/nzbs/
ls /zurg_mnt/zurg/__all__/
```

Avec un seul compte, son propre dossier `__nzb__` n'apparaît pas dans la liste racine du montage. Cherche donc dans `__all__`. Le dossier de surveillance est pris en compte toutes les 15 secondes environ. Comme il se trouve dans le montage `./:/config`, il survit à un `docker compose pull` et à une recréation du conteneur, comme le reste.

## Règles propres à ce type {#rules-specific-to-this-type}

- **Une seule entrée `nzb` activée.** Deux entrées analyseraient le même dossier et dupliqueraient chaque release. D'autres serveurs de news se placent sous le `nntp.servers` de cette unique entrée. Ils servent ainsi la même bibliothèque au lieu d'en fournir une deuxième copie. Une entrée `nzb` à côté d'une entrée [`torbox_nzb`](torbox-nzb.md) est refusée pour la même raison.
- **`watchlist: true` est refusé.** Un serveur de news ne reçoit jamais de torrent.
- **`add_torrents` est ignoré** et le démarrage affiche un avertissement à ce sujet, pour la même raison.
- **`download_tokens` et `strm_link_token` ne font rien.** Il n'y a pas d'identifiant à faire tourner.
- **Le dossier s'appelle `__nzb__`** parce que le nom reprend par défaut le type. Définissez `name: usenet` sur l'entrée si vous préférez parcourir `__usenet__`.

## Un second serveur de news vaut plus qu'il n'y paraît {#a-second-news-server-is-worth-more-than-it-looks}

La rétention est propre à chaque fournisseur. Un article qu'un serveur a déjà expiré est très souvent
encore disponible sur un autre. Sans second compte, la seule façon de récupérer un article mort est PAR2, et cela demande de lire **toute la release**. Donc un second
serveur fait la différence entre récupérer un seul article et tout relire.

Les comptes supplémentaires vont dans `nntp.servers` de cette entrée, plutôt que dans une seconde entrée `nzb`. `priority`, `backup` et `backbone` décident qui est interrogé et dans quel ordre. Les lectures sont gérées selon la capacité combinée des comptes qui ne sont pas marqués `backup`. La config complète et ce que chaque clé apporte sont expliqués dans [Usenet avec zurg](../guides/usenet.md#more-than-one-usenet-provider).

## Vérifier que ça fonctionne {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/nzb/test
docker compose logs --tail=100 zurg
ls /zurg_mnt/zurg/__all__/
```

Avec un seul compte, son propre dossier est exclu de la liste racine du montage, donc le montage affiche les mêmes fichiers sous `__all__`.

La sonde ici s'authentifie auprès du serveur de news en utilisant au plus une connexion du pool existant. Il n'y a pas d'API de compte à interroger.

## Quand ça ne marche pas {#when-it-goes-wrong}

Deux symptômes concernent l'entrée du fournisseur elle-même plutôt que la bibliothèque.

**Les lectures se coupent et zurg ne fait plus passer qu'un article à la fois.** `pipeline_depth` est plus élevé que ce que le serveur supporte. zurg le réduit tout seul et affiche un avertissement. Mets-le explicitement à `1` pour un serveur qui ne peut pas gérer plusieurs commandes en même temps.

**Le débit est faible sur une liaison à forte latence.** Laisse `socket_receive_buffer_kb` non défini. Un tampon figé est un tampon que le noyau cesse d'ajuster. Sous Linux, cela maintient la fenêtre de réception autour de 64 KiB et coûte l'essentiel du débit du compte.

Tout le reste a une ligne dans le tableau de dépannage de [Usenet avec zurg](../guides/usenet.md#troubleshooting). Les connexions refusées, le streaming lent, un fournisseur qui n'est jamais sollicité et une modification du Dashboard qui a supprimé `nntp.servers` y figurent tous.
