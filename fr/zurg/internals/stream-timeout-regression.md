# Régression du délai d'attente des flux proxifiés {#proxied-stream-timeout-regression}

## Résumé {#summary}

zurg utilisait `download_timeout_secs` comme délai global (wall-clock) pour les téléchargements HTTP proxifiés. Sa valeur par défaut est de 15 secondes, donc toute réponse en amont dont le corps mettait plus de 15 secondes à se terminer était coupée, même pendant que les octets arrivaient normalement.

Le bug a été signalé sur Discord le 2026-08-21 avec `2026.08.21.0151-nightly` (`fc2a21f`). Des requêtes répétées de 2 Go avec plage (ranged) passant par zurg se terminaient à 15.001 secondes après avoir livré environ 1.26 Go à 84 Mo/s. La même plage terminait sans souci directement depuis Real-Debrid, et passer `download_timeout_secs` à 3600 permettait à la requête de finir via zurg en 25.8 secondes.

Il s'agit bien d'une régression de zurg, et non d'un filtrage de contenu, d'une panne du CDN ni d'une régression dans `fc2a21f`. Le commit `6edeaa8c` (`Optimize client`, 2024-11-17) l'a introduite. Le chemin de service proxifié classique a été corrigé par `41db7245`, puis `eff972b8` a rendu cette même erreur difficile à reproduire à la frontière de l'API des fournisseurs.

## Impact pour l'utilisateur {#user-impact}

Le chemin concerné était toute réponse que zurg proxyfiait depuis un fournisseur debrid basé sur HTTP et qui restait ouverte plus longtemps que `download_timeout_secs`.
Real-Debrid était touché depuis novembre 2024. TorBox et AllDebrid ont hérité du même comportement lorsque ces fournisseurs ont été ajoutés. Les lectures de NZB servis localement ne passaient jamais par le client de téléchargement HTTP et n'étaient donc pas touchées.

Les symptômes visibles par l'utilisateur étaient les suivants :

- Infuse ou un autre client WebDAV direct qui se bloque pendant la lecture ;
- une lecture qui échoue après un seek qui ouvre une nouvelle requête par plage ;
- un téléchargement qui se termine trop tôt alors qu'il reçoit un HTTP `206 Partial Content` ; et
- des erreurs client qui semblaient venir du fichier média ou du CDN alors qu'une requête directe se terminait normalement.

Le lecteur ne tombait pas forcément en erreur 15 secondes après le début de la lecture. À 84 MB/s, zurg transférait environ 1,26 GB avant l'échéance. Un lecteur pouvait consommer ce tampon pendant plusieurs minutes avant de se vider, ce qui transformait une coupure réseau exacte de 15 secondes en un gel de lecture apparemment aléatoire.

## Cause racine {#root-cause}

Le `http.Client.Timeout` de Go est une deadline pour tout le cycle de vie de la requête. Ce n'est pas un timeout d'inactivité ni de blocage. L'horloge démarre quand la requête commence et continue de tourner pendant la lecture du corps de la réponse, que des données circulent ou non.

Avant `6edeaa8c`, le client de téléchargement lui-même n'avait pas de timeout sur la requête entière :

```go
client: &http.Client{}
```

`download_timeout_secs` limitait les phases de connexion et d'en-têtes de réponse, via le dialer du transport et `ResponseHeaderTimeout`. Une fois le corps de la réponse arrivé, le chemin de service pouvait continuer à lire aussi longtemps que le client en aval en avait besoin.

`6edeaa8c` a réorganisé le transport HTTP et a ajouté le timeout configuré directement au client, tout en supprimant `ResponseHeaderTimeout` :

```go
client.client = &http.Client{
    Transport: transport,
    Timeout:   time.Duration(timeoutSecs) * time.Second,
}
```

Cela a changé le sens de la valeur existante de 15 secondes. Elle protégeait toujours la phase de connexion, mais elle imposait désormais aussi une deadline absolue sur le corps de la réponse. Le chemin de service récupérait déjà les médias via ce client, donc la régression est devenue visible dès que ce changement a été intégré.

La panne était discrète. zurg envoyait le statut et les en-têtes amont réussis avant de copier le corps vers le lecteur. Quand la deadline du client interrompait le corps, l'opération de copie renvoyait une erreur, mais le chemin de service ignorait cette erreur :

```go
n, _ = copyBuffered(resp, body)
```

À ce moment-là, la réponse `206` était déjà envoyée et ne pouvait plus être remplacée par un code d'erreur. Avec la journalisation des requêtes désactivée, rien n'indiquait pourquoi le corps était tronqué. Le client en aval a donc reçu une réponse de contenu partiel apparemment réussie, dont le corps s'arrêtait avant la longueur annoncée.

## Historique de la régression {#regression-history}

Les commits concernés forment une chaîne plus longue que la nightly où le problème a été signalé :

| Date | Commit | Effet |
|---|---|---|
| 2024-06-28 | `c3aea427` | A fait passer la lecture de diffusion existante par `DownloadFile`. Le comportement n'a pas changé, car le client de téléchargement n'avait encore aucun délai d'expiration pour la requête entière. |
| 2024-11-17 | `6edeaa8c` | A ajouté `http.Client.Timeout` au client de téléchargement. C'est la régression qui a commencé à tronquer les corps de réponse proxifiés classiques. |
| 2026-02-26 | `dea98d34` | A bien identifié la même coupure à 15 secondes pour la lecture des archives RAR, a ajouté un client de streaming sans délai d'expiration et n'a migré que le chemin RAR vers ce client. La diffusion de fichiers classique est restée sur `DownloadFile`. |
| 2026-08-02 | `e9318e66` | A déplacé les téléchargements derrière l'interface multi-fournisseurs `debrid.Provider` et a repris l'appel de diffusion classique sans modification. Il n'a pas créé le bug Real-Debrid, mais les nouveaux fournisseurs basés sur HTTP ont hérité de la méthode dangereuse. |
| 2026-08-21 | `fc2a21f` | La nightly utilisée dans le rapport. Elle contenait le bug sans l'avoir introduit. |
| 2026-08-21 | `41db7245` | A fait passer la lecture proxifiée classique sur `DownloadFileStreaming` et a ajouté le premier test de régression de bout en bout sur le délai d'expiration. |
| 2026-08-21 | `eff972b8` | A rendu sans délai d'expiration le `DownloadFile` de chaque fournisseur HTTP, comme garde-fou structurel, et étendu la couverture à Real-Debrid, AllDebrid, TorBox et à un témoin NZB. |

Le correctif RAR de février est le quasi-accident important. Son message de commit indique explicitement que `http.Client.Timeout` couvre le corps de la réponse et que le délai par défaut de 15 secondes coupait les flux RAR. Le diagnostic était juste, mais le correctif n'a été appliqué qu'au lecteur RAR. Garder deux méthodes séparées, `DownloadFile` et `DownloadFileStreaming`, a permis au chemin de diffusion classique de conserver ce choix dangereux pendant encore six mois.

## Pourquoi elle est restée cachée {#why-it-stayed-hidden}

Plusieurs effets ont masqué la régression pendant environ 21 mois :

1. La plupart des déploiements de serveurs multimédias lisent zurg via rclone plutôt que directement en WebDAV. rclone utilise des requêtes par plages (ranged) bornées. Les valeurs par défaut actuelles du montage géré commencent à 4 Mo et montent jusqu'à une limite de 512 Mo, donc sur une connexion rapide, beaucoup de requêtes amont individuelles se terminent en moins de 15 secondes. Cela réduisait l'exposition, mais ne rendait pas le chemin sûr, surtout sur les liaisons plus lentes.
2. Les clients WebDAV directs comme Infuse peuvent demander de grandes plages ou des plages ouvertes. Ces requêtes gardent une réponse amont ouverte assez longtemps pour atteindre la limite de temps à coup sûr, ce qui explique pourquoi la reproduction sur Discord était exacte pour trois décalages différents.
3. La mise en mémoire tampon de la lecture masquait la cause derrière le symptôme. La requête amont s'arrêtait à 15 secondes, mais la lecture ne s'arrêtait qu'une fois que le lecteur avait consommé les octets déjà reçus. Le délai visible variait selon le débit, la mise en mémoire tampon et les recherches (seeks).
4. La réponse semblait réussie. Le CDN renvoyait un `206` valide, zurg le transmettait, et l'erreur de copie du corps était ignorée une fois les en-têtes envoyés. Les tests directs sur le CDN restaient sains et les journaux normaux ne contenaient aucune erreur de délai d'attente.
5. Augmenter le paramètre semblait résoudre le problème. Le défaut paraissait donc être une valeur de réglage trop petite, et non un délai d'attente rattaché à la mauvaise abstraction.
6. Les tests existants utilisaient des corps ou des plages qui se terminaient dans le délai configuré. Aucun test ne gardait volontairement un corps de réponse en cours de transfert au-delà de la limite, puis ne vérifiait la longueur complète et la somme de contrôle via le chemin de service.
7. Le correctif ciblé pour RAR a supprimé la manifestation la plus évidente, sans retirer le défaut dangereux pour les téléchargements ordinaires.

## Pourquoi un délai plus long semblait la corriger {#why-a-higher-timeout-appeared-to-fix-it}

Changer le paramètre à 3600 secondes n'a pas modifié ce que couvrait le délai d'expiration. Il a seulement repoussé assez loin l'échéance (wall-clock) pour que le transfert signalé de 25.8 secondes puisse se terminer :

```text
15 seconds   < 25.8-second transfer < 3600 seconds
```

Il s'agissait d'un contournement, pas d'une correction sûre. Tout délai d'expiration fini sur la requête entière peut encore couper un corps suffisamment long, y compris avec un client lent ou une connexion suspendue. Ce paramètre alimente aussi le délai de connexion (dial timeout) du client de téléchargement et les requêtes de vérification bornées, donc le passer à une heure peut faire mettre beaucoup plus de temps à un hôte injoignable pour échouer. Les versions corrigées doivent utiliser la valeur configurée normale : elle ne limite plus un corps de média relayé.

## Correctif et garde-fous {#fix-and-guardrails}

La correction immédiate dans `41db7245` a fait passer `streamFileToResponse` par `Provider.DownloadFileStreaming`. Ce client partage le même transport, mais il n'a pas de `http.Client.Timeout`. La durée du corps de la réponse n'est donc plus liée à `download_timeout_secs`. La requête utilise toujours le contexte de la requête en aval : si le lecteur se déconnecte, la lecture amont est annulée. L'établissement de la connexion et la négociation TLS restent limités par le transport.

`eff972b8` a ensuite supprimé le fait de devoir compter sur le choix, par chaque appelant, d'une méthode dont le nom contient « Streaming » :

- `DownloadFile` de Real-Debrid utilise maintenant `DoStreaming`.
- L'helper partagé `debrid.DownloadRanged` accepte `StreamingDoer`, qui n'expose que `DoStreaming`. AllDebrid et TorBox utilisent cet helper.
- Les deux méthodes de téléchargement des providers sont donc désormais sûres pour un corps de réponse long.
- Les lectures bornées hors lecture, comme les deux lectures de 64 KiB utilisées pour le hash OpenSubtitles, reçoivent leur propre deadline explicite sur le contexte, au lieu d'emprunter un timeout de corps global au client, qui n'est pas sûr.

Les tests de non-régression dans `internal/universal/stream_timeout_test.go` utilisent un serveur local qui envoie un corps de 1,6 Mo en 16 morceaux, sur environ 1,6 seconde, alors que le timeout configuré est d'une seconde. Ils vérifient à la fois la taille complète et la somme de contrôle :

- directement via les deux méthodes de téléchargement des providers, pour Real-Debrid, AllDebrid et TorBox ;
- de bout en bout via `streamFileToResponse`, pour les trois providers basés sur HTTP ;
- et via un provider local au format NZB, servant de témoin non concerné.

L'invariant est maintenant explicite : une méthode qui renvoie un corps de téléchargement ne doit jamais utiliser un timeout appliqué à toute la requête. Les sondes courtes et les lectures de métadonnées doivent porter une deadline sur leur propre contexte. Les corps de streaming, eux, doivent rester ouverts jusqu'à la fin, jusqu'à l'annulation côté aval, ou jusqu'à une vraie erreur de transport.

## Limitée par la progression, pas par le temps {#bounded-by-progress-not-by-time}

Jusqu'à la fin, il restait une façon pour une lecture de ne jamais se terminer : un nœud de livraison qui garde la réponse ouverte sans plus rien envoyer, ou qui ne répond jamais. En septembre 2026, un scan Plex est resté onze heures bloqué sur un seul fichier Real-Debrid dont la lecture n'avait jamais échoué. Ce client n'avait aucune limite pour l'abandonner, et l'option `--timeout` de rclone est une limite d'inactivité : zurg transmet le corps par écritures de 256 KiB, donc un nœud qui livre 256 KiB toutes les cinq minutes, soit moins de 1 Ko/s, la réinitialise indéfiniment. Un nœud plus lent déclenche bien la limite, mais rclone renvoie alors la même requête au même nœud, en journalisant une erreur pour trois délais d'attente. Mesuré sur zen avec rclone 1.75 et les options propres au montage, le 2026-10-03, un lecteur sur un tel nœud était toujours bloqué après 30 minutes.

`internal/universal/starved_read.go` coupe désormais une lecture proxifiée dès que le nœud a livré moins de 1 MiB sur 30 secondes pendant lesquelles zurg attendait après lui. Seul le temps d'attente sur le nœud compte : depuis le moment où la requête obtient une connexion jusqu'à l'arrivée de ses en-têtes, et le temps passé dans chaque lecture du corps. Le temps d'écriture vers le client ne compte pas, donc la propriété décrite plus haut tient toujours, et un client en pause ou lent peut garder un flux ouvert aussi longtemps qu'il le souhaite. Un fichier coupé reçoit une réponse `503` pendant deux minutes, afin que les nouvelles tentatives de rclone s'arrêtent tout de suite au lieu d'attendre chacune une autre fenêtre. Les lectures d'un NZB servies localement ne sont pas surveillées.

Les lectures de fichiers à l'intérieur d'une archive ne passaient jamais par `streamFileToResponse`, elles échappaient donc à cette limite jusqu'à la carte 204. Leurs octets viennent de portions de chaque volume, récupérées par le même client via `providerDoer.Do` et lues par l'analyseur RAR. Un nœud pouvait donc en retenir une aussi longtemps qu'il gardait la connexion ouverte. Chaque récupération de volume est maintenant surveillée par ce même plancher, l'entrée est refusée pendant deux minutes lorsqu'une récupération est coupée, et une coupure pendant le listage de l'archive fait échouer ce listage, au lieu de laisser l'analyseur omettre le volume comme s'il était endommagé. Sur un jeu réel de cinq volumes, ce comportement servait l'entrée sur toute sa longueur mais avec de mauvais octets à partir du deuxième volume.

La carte 222 a révélé le même problème derrière toutes les autres façons dont un nœud peut faire échouer une lecture de volume : une erreur 5xx, un 429, une connexion interrompue en plein milieu des en-têtes. L'analyseur les prenait pour un volume endommagé et listait l'archive sans lui. Comme ce listage était mis en cache, sur le même jeu un 503 sur le volume 3 servait de mauvais octets à partir de l'offset 16 057, et continuait à les servir après le rétablissement du nœud. L'analyseur distingue désormais un volume dont les octets n'ont pas pu être analysés d'un volume dont les octets ne sont jamais arrivés (`rarstream.ErrVolumeUnavailable`). Ce marquage est posé par `HTTPSrc` pour les statuts qu'il voit, par `providerDoer` pour toutes les erreurs de lecture distante, et par le corps NZB pour ce que son lecteur classe comme erreur de transport. Le second cas fait échouer le listage, y compris pour un jeu imbriqué ou un regroupement par en-tête de volume. L'échec reçoit une réponse `503` avec un `Retry-After`, n'est jamais mis en cache comme échec d'archive, n'est jamais enregistré comme verdict, et n'est jamais servi lors d'un parcours avec les volumes bruts à la place du contenu de l'archive. Les volumes endommagés ou absents sont toujours contournés comme auparavant.

Les écritures de 256 KiB évoquées plus haut ont également été corrigées dans la carte 204. La copie remplit toujours son tampon tant qu'un nœud est rapide, donc un corps rapide part toujours par tampons entiers. Mais elle envoie désormais les premiers octets dès leur arrivée et ne retient jamais un octet plus de 250 ms (`defaultCopyFlushAfter` dans `internal/universal/downloader.go`), en vidant la réponse avec eux. Un nœud lent n'empêche plus le client de recevoir ses en-têtes. Auparavant, sur zen, avec rclone et les options propres au montage, une entrée d'archive sur un nœud qui envoyait 64 KiB puis 16 KiB toutes les quatre minutes n'envoyait rien du tout à rclone lorsque celui-ci abandonnait exactement à cinq minutes, et cela trois fois de suite : tout ce que le nœud avait envoyé restait dans le tampon.
