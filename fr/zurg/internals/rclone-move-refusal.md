# Imports vides après un déplacement refusé {#empty-imports-after-a-refused-move}

Reproduit avec rclone 1.72.0, une union local-first, le cache VFS complet et le `File.Move(source, destination)` de .NET 6 utilisé par Sonarr 4.0.19.2979.

Quand le backend refuse un MOVE, `vfs.File.rename` de rclone laisse le répertoire et le nom du fichier pointer vers la destination tentée. .NET passe alors à une copie. La création de sa destination crée une entrée de cache VFS vide. L'ouverture de la source atteint cette même entrée, donc la copie lit EOF et annonce un succès. La reproduction attendait 4096 octets et n'en a reçu aucun. Passer le refus WebDAV de 409 à 422 n'a rien changé au résultat.

Le patch `scripts/patches/rclone-v1.72.0-rename.patch` restaure le répertoire et le nom d'origine quand le rename immédiat échoue. Il inclut un test de régression VFS upstream. Le test de montage exerce tout le chemin WebDAV, union, FUSE et .NET avec une fausse archive et sans identifiants de fournisseur. Son verdict de dommage est injecté pendant que les octets de la fixture restent lisibles : .NET peut copier ces octets avec succès, mais ne doit pas en faire un fichier vide.

Pour construire un nouveau binaire à côté de celui installé :

```sh
./scripts/build-rclone-move-fix.sh /absolute/path/to/rclone-fixed
RCLONE_TEST_BIN=/absolute/path/to/rclone-fixed ./integration/magic_move_refusal.sh
```

Le build fixe le commit upstream `38ab3dd5b1df946aecf5bd085c671c86f46f68eb` (1.72.0). Il lance les tests de rename VFS avant de compiler. Le test de montage nécessite FUSE sous Linux et Docker, ou un `DOTNET_MOVE_PROBE_BIN` autonome construit depuis `integration/dotnet-move-probe`. Il échoue volontairement avec le binaire non patché. `make integration-test` inclut cette vérification ; pointe `RCLONE_TEST_BIN` et `RCLONE_BIN` vers le binaire corrigé pour lancer la suite.

L'installation demande de redémarrer le montage en utilisant les garde-fous media-server habituels de ton déploiement. Garde l'ancien binaire pour pouvoir revenir en arrière. Les fichiers vides existants sur l'upstream local d'une union survivent à un redémarrage du montage ; ne conserve et ne supprime que les fichiers d'import vides dont tu es certain. Redémarrer efface les nœuds VFS obsolètes, mais ne répare pas les articles Usenet manquants.

Cette correction ne supprime pas le repli de .NET sur la copie et ne rend pas lisible un contenu endommagé. La vérification de disponibilité de zurg avant la fin de SABnzbd et le MOVE refusé restent des protections distinctes. L'échantillonnage de disponibilité n'est pas une vérification complète du fichier ; voir `sabnzbd-client-contract.md`.

Le patch figé embarque aussi la correction d'alias de fichier utilisée par l'union embarquée. Avec `action_policy: all`, le local et le WebDAV peuvent tous deux recevoir une opération sur un fichier. Un Move ou Remove local réussi couplé à un 404 WebDAV n'est accepté qu'après une nouvelle recherche qui prouve que la source de l'upstream en échec a disparu. Les opérations où tout a échoué, une source encore présente, un répertoire parent de destination manquant, et les autres erreurs d'I/O ou de permissions restent des échecs. Le binaire obtenu annonce `v1.72.0-zurg-rename-sidecar-fix`, pour le distinguer du build VFS seul d'origine.
