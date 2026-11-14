# TorBox dans DMM {#torbox-in-dmm}

DMM fonctionne avec un abonnement TorBox payant : Essential, Standard ou Pro. Collez votre clé API depuis [torbox.app/settings](https://torbox.app/settings) sur la page **Connect Torbox** de DMM, puis lancez une recherche : les releases déjà présentes chez TorBox sont marquées **Instant TB**. Le forfait gratuit n'a pas d'accès à l'API, donc DMM ne peut pas l'utiliser, et l'envoi de releases Usenet vers TorBox nécessite le forfait Pro.

## Se connecter {#sign-in}

1. Sur [debridmediamanager.com](https://debridmediamanager.com), appuyez sur **Login with Torbox**. Déjà connecté avec un autre service ? Ouvrez **Debrid services** sur la page d'accueil et appuyez sur **Torbox Login**.
2. Appuyez sur **Get API Key from Torbox**. Cela ouvre [torbox.app/settings](https://torbox.app/settings), où se trouve votre clé API.
3. Collez la clé dans **API Key** et appuyez sur **Save API Key**.

![Page Connect Torbox de DMM refusant une clé du forfait gratuit, clé floutée](../assets/dmm-torbox/01-free-plan.webp)

Une fois connecté, la page d'accueil affiche **Cast for TB** et **Requests**, et **Debrid services** liste votre compte TorBox avec un ✓. Appuyez dessus pour voir votre forfait et sa date d'expiration, ou pour **Add another account** ou **Logout**.

## Ce que chaque offre permet {#what-each-plan-can-do}

| | Gratuit | Essential ou Standard | Pro |
|---|---|---|---|
| Se connecter à DMM | Non | Oui | Oui |
| **Instant TB**, **DL with TB**, la bibliothèque et **Cast (TB)** | Non | Oui | Oui |
| Envoyer les releases Usenet vers TorBox | Non | Non | Oui |
| Téléchargements simultanés (slots actifs de TorBox) | 1 | 3 ou 5 | 10 |

Connectez-vous avec une clé du plan gratuit et DMM affiche **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** La [page tarifs](https://torbox.app/pricing) de TorBox indique que l'accès API n'est pas inclus dans le plan Gratuit, et que Usenet n'est disponible que sur le plan Pro.

## Trouver ce que TorBox a déjà {#find-what-torbox-already-has}

1. Recherche un film ou une série et ouvre-le.
2. DMM demande à TorBox quelles releases il a déjà en cache. Elles affichent **Instant TB** et **Cast (TB)** et sont listées en premier. Le chip **TB ✓** au-dessus des résultats n'affiche que celles-là. Il écrit `is:tb` dans la zone de filtre ; clique à nouveau dessus pour tout afficher.
3. Clique sur **Instant TB**. La release est tout de suite dans ta bibliothèque TorBox.

![Night of the Living Dead (1968) sur DMM avec TorBox : Instant TB, Cast (TB) et DL with TB](../assets/dmm-torbox/02-results.webp)

Les releases que TorBox n'a pas affichent **DL with TB**. En cliquant dessus, TorBox télécharge d'abord la release, ce qui utilise un de tes slots actifs pendant le téléchargement. **No seeders** à côté de la taille veut dire que personne ne la partage pour l'instant, donc elle risque de ne jamais se terminer. TorBox ajoute toujours la release complète : impossible de choisir des fichiers individuels.

## Ta bibliothèque {#your-library}

Appuyez sur **Library**. Elle affiche vos torrents et téléchargements web TorBox.

- **TB Add** ouvre **Add to your TB library**. Collez des liens magnet, importez des fichiers `.torrent` ou collez des liens de téléchargement direct, que TorBox récupère comme téléchargements web.
- **Backup** enregistre votre liste dans un fichier. **TB Restore** rajoute une liste sauvegardée.
- Le reste fonctionne comme pour n'importe quel service : voir [your library](index.md#your-library).

Les téléchargements Usenet que vous avez envoyés à TorBox ne sont pas dans la bibliothèque de DMM. Retrouvez-les sur le site de TorBox, dans la ligne **DMM TB Library** de DMM Cast dans Stremio, ou via [TorBox hosted Usenet](../zurg/providers/torbox-nzb.md) de zurg.

## Regarder dans Stremio {#watch-in-stremio}

Appuyez sur **Cast for TB** sur la page d'accueil et installez l'addon à partir de là. Ensuite, appuyez sur **Cast (TB)** sur n'importe quelle release que TorBox a en cache. Toutes les étapes sont décrites dans [DMM in Stremio](stremio.md).

Dans Stremio, l'addon s'appelle **DMM Cast for TorBox**. Sa ligne **DMM TB Library** affiche vos torrents TorBox ainsi que vos téléchargements web et Usenet terminés.

## Envoyer les releases Usenet vers TorBox (Pro) {#send-usenet-releases-to-torbox-pro}

1. Ouvrez un film ou une série et appuyez sur l'onglet **Usenet**.
2. Avec TorBox Pro, la liste est intitulée **Send to TorBox** et chaque version a un bouton **TorBox**. Appuyez dessus.
3. DMM vous indique ce que TorBox en a fait :
   - **Usenet → TorBox: TorBox already had it, it is ready in your TorBox Usenet downloads.**
   - **Usenet → TorBox: TorBox is downloading it, usually ready within a few minutes.**
   - **Usenet → TorBox: queued, it starts when one of your TorBox active slots frees up.**

![Onglet Usenet de DMM avec TorBox Pro : Send to TorBox](../assets/dmm-torbox/03-usenet-tab.webp)

Vous êtes aussi connecté à Real-Debrid ? La liste est intitulée **Send to Real-Debrid or TorBox** et affiche les deux boutons. L'icône de fichier à la fin d'une ligne enregistre plutôt le NZB. Vous débutez avec Usenet ? Commencez par [Usenet pour les débutants](../guides/usenet-for-beginners.md).

TorBox supprime un téléchargement Usenet 30 jours après l'avoir mis en cache. Renvoyez-le pour le récupérer.

## Remplir les demandes avec TorBox {#fill-requests-with-torbox}

Les utilisateurs de Real-Debrid demandent des releases sur le [tableau des demandes](https://debridmediamanager.com/requests) de DMM. Appuyez sur **Requests** sur la page d'accueil, puis sur **Fulfil** pour une release que TorBox a en cache. Elle passe de votre TorBox à leur Real-Debrid. Chaque tranche de 10 envois vous rapporte 7 jours d'avantages sponsor DMM : voir [gagner sans payer](../guides/sponsorship.md#earn-it-without-paying).

## Quand quelque chose ne va pas {#when-something-is-wrong}

| Ce que vous voyez | Quoi faire |
|---|---|
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Cette clé correspond au forfait gratuit de TorBox. Passez à un forfait payant ou renouvelez-le sur TorBox, puis reconnectez-vous. |
| **Failed to refresh torbox: Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Votre forfait payant a expiré depuis votre connexion. Renouvelez-le sur TorBox. |
| **API Error: Request failed with status code 403. Status: 403** | TorBox n'a pas accepté cette clé. Copiez-la de nouveau depuis [torbox.app/settings](https://torbox.app/settings), en entier. |
| Aucun bouton **TorBox** dans l'onglet Usenet | L'envoi des releases Usenet vers TorBox nécessite Pro. Essential et Standard n'ont pas ce bouton. |
| **Usenet → TorBox: TorBox Usenet needs a Pro plan** | TorBox a refusé le NZB parce que le forfait n'est pas Pro. |
| Seulement **DL with TB**, pas de **Instant TB** | TorBox n'a mis en cache aucune de ces releases. Lancez-en une et attendez qu'elle se télécharge, ou choisissez une autre release. |
| Seules les releases **Instant TB** s'affichent | Le chip **TB ✓** est activé (`is:tb` dans la zone de filtre). Appuyez à nouveau dessus, ou appuyez sur **Reset**. |
| **No torrents found yet. Use Want above to have zurg fetch it once one turns up, or try the Usenet tab.** | DMM n'a pas encore de torrents pour ce titre. Les nouveaux épisodes peuvent mettre un certain temps à arriver. Essayez l'onglet **Usenet** ou revenez plus tard. |
| Dans Stremio : **⚠️ TorBox refused your account** | TorBox accepte la clé de l'addon mais refuse de servir le compte, généralement parce que le forfait a expiré. Vérifiez sur [torbox.app/settings](https://torbox.app/settings). Rien ne doit être modifié sur DMM. |
| zurg : `Acquisition: dmm-torbox refused the search: No TorBox key linked.` | Le feed sponsor `tb/cached` de la [page Torznab](https://debridmediamanager.com/torznab) de DMM a besoin de votre clé TorBox, à lier sous **Link a provider key** sur cette page. Être connecté à TorBox sur DMM ne suffit pas. Le `api_key` dans zurg reste votre clé API DMM. |

TorBox est-il en panne ou est-ce moi ? Consultez [Is TorBox Down Or Just Me?](https://debridmediamanager.com/is-torbox-down-or-just-me). Bloqué ? Demandez sur le forum **dmm-support** du [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](../guides/remote-help.md) indique quoi inclure.

## Questions

### Le support de TorBox n'est-il pas disponible avec l'offre gratuite de zurg ? {#is-torbox-support-not-on-the-free-tier-of-zurg}

Bon, la version publique gratuite de zurg ne gère que Real-Debrid. TorBox, les autres services et Usenet sont dans les builds nightly de zurg, réservées aux sponsors. Ton forfait TorBox doit aussi être payant, car zurg ne peut pas lire un compte gratuit. Configure-le avec [TorBox avec zurg](../zurg/providers/torbox.md).

### Zurg utilise la mauvaise offre TorBox ? {#zurg-uses-the-wrong-torbox-plan}

Les nightlies de zurg antérieures au 3 octobre 2026 traitent l'offre Pro de TorBox comme Standard et autorisent 5 téléchargements simultanés au lieu de 10. Mettez zurg à jour. Les [limites de TorBox avec zurg](../zurg/providers/torbox-limits.md) détaillent le reste.

### Aucun résultat de recherche avec TB ? {#no-search-results-with-tb}

DMM a le même moteur de recherche quel que soit le service avec lequel vous vous connectez. TorBox détermine seulement quelles versions affichent **Instant TB**. Si vous ne voyez rien, vérifiez que le chip **TB ✓** est désactivé, rechargez la page, ou appuyez sur **Show More Results** en bas. Un épisode tout récent n'a peut-être pas encore de torrents sur DMM : essayez l'onglet **Usenet**.

### Puis-je utiliser TorBox et Real-Debrid ensemble ? {#can-i-use-torbox-and-real-debrid-together}

Oui. Connecte-toi aux deux services et chaque release affiche les boutons des deux. Une release que TorBox a en cache et que Real-Debrid n'a pas reçoit un bouton **TB → RD**, qui l'envoie de TorBox vers ton Real-Debrid.

### Quelle offre TorBox me faut-il pour DMM ? {#which-torbox-plan-do-i-need-for-dmm}

N'importe quel forfait payant. Choisissez Pro si vous voulez envoyer des releases Usenet à TorBox ou lancer 10 téléchargements en même temps.
