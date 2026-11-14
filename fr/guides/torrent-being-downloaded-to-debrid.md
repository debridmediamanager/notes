# Ce que signifie « Torrent is being downloaded to debrid » {#what-torrent-is-being-downloaded-to-debrid-means}

L'écran vert **Torrent is being downloaded to debrid...** signifie que la version que tu as choisie n'est pas encore en cache sur ton service debrid. Torrentio, l'addon Stremio qui affiche ce résultat, vient d'ajouter ce torrent à ton compte Real-Debrid, TorBox ou autre compte debrid, et le service est en train de le télécharger. Une fois que c'est fini, le même résultat se lance comme les autres.

## Que faire {#what-to-do}

1. **Choisis plutôt un résultat en cache.** Dans la liste de Torrentio, `[RD+]` (ou `[TB+]`, `[AD+]`, `[PM+]`) veut dire que le fichier est en cache, donc il se lance tout de suite. `[RD download]` veut dire qu'il n'est pas en cache. Ceux-là viennent après les résultats en cache.
2. **Ou attends quelques minutes, puis appuie à nouveau sur le même résultat.** Tant qu'il est encore en train de se télécharger, tu revois l'écran vert. Une fois le téléchargement fini, ça se lance.
3. **Suis le téléchargement** sur la [page des torrents de Real-Debrid](https://real-debrid.com/torrents), ton [tableau de bord TorBox](https://torbox.app/dashboard) ou la [bibliothèque DMM](https://debridmediamanager.com/library). DMM affiche le pourcentage, les seeders et la vitesse de chaque téléchargement non terminé.
4. **Bloqué à 0 % sans seeders ?** Personne ne partage cette version pour l'instant, elle ne terminera peut-être jamais. Choisis-en une autre.
5. **Tu ne veux pas du tout de ces résultats ?** Ouvre la [page de configuration de Torrentio](https://torrentio.strem.fun/configure), renseigne ton service debrid et ta clé comme avant, coche **Don't show download to debrid links** sous **Options** et appuie sur **INSTALL**. Tu ne verras que les résultats en cache.

## Voir ce qui est en cache avant d'appuyer sur lecture {#see-whats-cached-before-you-press-play}

Connecte-toi à [DMM](https://debridmediamanager.com/) avec ton service debrid et cherche le titre. Sur sa page, un bouton vert **Instant RD** signifie que Real-Debrid a cette version en cache, donc elle se lance tout de suite. **DL with RD** signifie qu'elle n'est pas en cache et qu'elle doit d'abord se télécharger. Appuie sur la puce **RD** au-dessus des résultats pour masquer tout ce qui n'est pas en cache. TorBox, AllDebrid, Premiumize et Offcloud ont les mêmes boutons (**Instant TB**, **DL with TB** et ainsi de suite).

## Questions

### Combien de temps ça prend ? {#how-long-does-it-take}

Ça dépend du nombre de personnes qui partagent ce torrent. Une version populaire est généralement prête en quelques minutes : dans notre test sur Premiumize, un film de 1,5 Go était prêt cinq minutes après le premier clic, en téléchargeant depuis trois pairs. Un torrent peu partagé peut être lent, et un torrent que personne ne partage peut ne jamais se terminer. La page des torrents ou le tableau de bord affiche la vitesse et le nombre de seeds trouvés.

### Pourquoi ça arrive sur certains résultats et pas sur d'autres ? {#why-does-it-happen-on-some-results-and-not-others}

Les services debrid conservent ce que leurs utilisateurs téléchargent. Si quelqu'un a déjà récupéré cette version exacte, elle est en cache et se lance instantanément. Si personne ne l'a fait, ou si le service l'a supprimée depuis, ton compte doit d'abord la télécharger. C'est la différence entre `[RD+]` et `[RD download]`. TorBox [explique comment fonctionne son cache](https://support.torbox.app/en/articles/9923071-how-does-the-torbox-cache-work).

### Pourquoi un résultat `[RD+]` l'a-t-il affiché ? {#why-did-an-rd-result-show-it}

Real-Debrid ne permet pas aux addons de demander ce qui est en cache. Donc sur Real-Debrid, le `+` de Torrentio signifie que la release a été lue pour quelqu'un récemment, et non que Real-Debrid l'a confirmé à l'instant. Si Real-Debrid l'a supprimée depuis, elle se re-télécharge. Choisis un autre résultat avec `+` ou attends.

### Mon debrid est-il cassé ? {#is-my-debrid-broken}

Non. L'écran vert signifie que ton service a pris le torrent et qu'il est en train de le traiter. Quand il y a un vrai problème, Torrentio affiche un écran rouge ou jaune avec d'autres mots, comme « Access denied » ou « Some usage limit exceeded ».

### Mon addon affiche autre chose {#my-addon-says-something-else}

Les mots exacts viennent de Torrentio et de ses copies auto-hébergées. Les autres addons disent la même chose à leur façon. AIOStreams affiche "The file is being downloaded to your debrid. Try again later", Comet "The media you tried to play is not cached yet on this debrid service" et StremThru "Downloading to Store". Même cause, même solution.
