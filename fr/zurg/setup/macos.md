# Tutoriel macOS {#macos-tutorial}

## Option en une ligne {#one-line-option}

Le bootstrap optionnel pour sponsors installe macFUSE si besoin, télécharge la version Intel ou Apple silicon et lance
le sélecteur de fournisseur et les diagnostics :

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Il utilise la connexion GitHub via le navigateur. macOS peut encore demander une approbation dans **System Settings > Privacy & Security**, ainsi qu'un redémarrage. Les binaires et configs existants restent en place. Continuez plus bas pour la méthode manuelle.

## Étape 1 : Installer macFUSE {#step-1-install-macfuse}

macFUSE permet à rclone de monter le système de fichiers virtuel de zurg comme un vrai répertoire sur votre Mac.

1. Téléchargez la dernière version du `.dmg` depuis [macfuse.io](https://macfuse.io)
2. Ouvrez le `.dmg` et lancez l'installateur
3. Pendant l'installation, macOS bloquera l'extension système. Allez dans **System Settings > Privacy & Security**, faites défiler la page et cliquez sur **Allow**
4. **Redémarrez votre Mac** (nécessaire pour que l'extension du noyau se charge)

Après le redémarrage, ouvrez **Terminal** (appuyez sur `Cmd + Space`, tapez « Terminal », puis appuyez sur Entrée) et vérifiez que macOS chargera macFUSE. C'est la même vérification que fait `zurg setup` :

```bash
/Library/Filesystems/macfuse.fs/Contents/Resources/load_macfuse && echo "macFUSE is ready"
```

Si `macFUSE is ready` n'apparaît pas, macOS n'a pas encore autorisé l'extension. Sur Apple silicon, activez les extensions du noyau tierces dans Recovery, autorisez macFUSE dans **System Settings > Privacy & Security**, puis redémarrez et vérifiez à nouveau.

## Étape 2 : Télécharger zurg {#step-2-download-zurg}

Ouvre [GitHub Releases](https://github.com/debridmediamanager/zurg/releases) dans un navigateur où tu es connecté avec le compte GitHub qui a accès à zurg. Prends la dernière nightly. C'est la pré-version tout en haut de la liste. Prends son zip `darwin-arm64`, ou `darwin-amd64` sur un Mac Intel. Ne prends pas la release que GitHub marque **Latest**. C'est la v1.0.0. Elle est plus ancienne que `zurg setup` et répond `unknown command`.

Les nightlies sont réservées aux sponsors. Tant que ton compte GitHub n'a pas accès, cette page renvoie 404. Deviens sponsor sur [gatekeeper](https://gatekeeper.debridmediamanager.com/) pour lui donner accès. La build publique gratuite est la v1.0.0, disponible sur [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). Elle n'a pas de `zurg setup`. Configure-la à la main comme l'explique [son README](https://github.com/debridmediamanager/zurg-public#readme), au lieu de suivre les étapes ci-dessous.

Ensuite, décompresse-le.

```bash
mkdir -p ~/zurg && cd ~/zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
```

Vérifie :

```bash
./zurg version
```

## Recommandé : laisser zurg terminer la configuration {#recommended-let-zurg-finish-the-setup}

Depuis le répertoire extrait, lance :

```bash
./zurg setup
./zurg doctor
```

`setup` te demande quels fournisseurs configurer. Choisis-en un ou plusieurs parmi Real-Debrid, TorBox, AllDebrid, Usenet, Premiumize, Debrid-Link et Offcloud, dans l'ordre de priorité. Par exemple, saisis `2,4` pour TorBox puis Usenet. Il ne demande que les identifiants des fournisseurs choisis, crée `config.yml` avec le mode `0600`, télécharge rclone (et ffprobe, sauf si l'un des deux est déjà dans ton PATH), prépare `/Volumes/Zurg` et installe le démarrage automatique.

Il choisit un LaunchAgent si l'utilisateur actuel dispose d'un domaine launchd GUI. Sur un Mac sans écran et sans utilisateur GUI connecté, il installe un LaunchDaemon système qui exécute quand même zurg avec l'utilisateur actuel. Cette méthode ne nécessite pas de connexion automatique.

La vérification des prérequis fait la différence entre le paquet macFUSE installé et une extension que macOS peut réellement charger. Sur Apple silicon, la toute première installation de macFUSE peut encore demander une modification unique de sécurité dans le mode de récupération, une approbation dans **System Settings > Privacy & Security** et un redémarrage. Aucun installateur ne peut contourner ces confirmations.

Tu peux relancer `setup` sans risque. Il met à jour le service launchd généré, mais ne remplace pas un `config.yml` existant.

Avant de streamer via le point de montage, ouvre `config.yml` ou le Dashboard à l'adresse `http://localhost:9999/config/` et définis `--vfs-cache-max-size` et `--vfs-cache-min-free-space` sous `rclone_extra_args`. Garde la taille maximale sous la moitié de l'espace disque libre actuel, et réserve au moins `20G` avec le réglage d'espace libre minimum. Lance ensuite `./zurg service restart`.

Le reste de cette page explique la configuration et la mise en place de Plex. Les étapes 3, 4, 5 et 7 correspondent à la méthode manuelle et peuvent être ignorées une fois `zurg setup` terminé avec succès.

## Étape 3 : Configurer zurg manuellement {#step-3-configure-zurg-manually}

Crée un fichier de config avec ton token API Real-Debrid :

```bash
cd ~/zurg
cat > config.yml << 'EOF'
# Minimal config - use Dashboard at http://localhost:9999/config/ for more settings
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN_HERE

rclone_enabled: true
mount_path: /Volumes/Zurg

rclone_extra_args:
  - "--vfs-cache-max-size"
  - "100G"
  - "--vfs-cache-min-free-space"
  - "20G"

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
EOF
```

Remplace le token d'exemple par ton vrai token, que tu trouves sur [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354) :

```bash
sed -i '' "s|YOUR_RD_API_TOKEN_HERE|PASTE_YOUR_TOKEN_HERE|g" ~/zurg/config.yml
```

> **Ne supprime pas `mount_path`.** Sans lui, rclone utiliserait `/Volumes/Zurg` sur macOS, mais l'analyse du serveur multimédia n'est activée que si `mount_path` est défini explicitement. Si tu l'omets, Plex ne sera jamais prévenu de se rafraîchir (étape 6).

> **La taille du cache est essentielle.** Le cache VFS stocke des morceaux des fichiers streamés sur ton disque local. S'il remplit ton disque, les performances de macOS vont fortement chuter : Spotlight, Plex, et même le système lui-même peuvent ne plus répondre. Règle toujours **les deux** limites :
>
> - `--vfs-cache-max-size` — plafond strict de la taille totale du cache. Règle-la sur **50 % de l'espace libre maximum de ton disque**. Vérifie avec `df -h /`.
> - `--vfs-cache-min-free-space` — arrête la mise en cache quand l'espace libre descend en dessous de cette valeur. Garde-la à **20G ou plus** comme filet de sécurité.
>
> Par exemple, sur un disque de 256GB avec 100GB libres, utilise `50G` pour la taille max et `20G` pour l'espace libre minimum.

## Étape 4 : Télécharger les dépendances manuellement {#step-4-download-dependencies-manually}

zurg a une commande intégrée qui télécharge rclone et ffprobe et met à jour `config.yml` avec leurs chemins :

```bash
cd ~/zurg
./zurg download-requirements
```

Crée le point de montage et le répertoire de logs. `/Volumes` appartient à root, donc zurg ne peut pas créer `/Volumes/Zurg` tout seul. Le répertoire de logs doit exister avant que launchd ouvre ses fichiers de sortie à l'étape 7 :

```bash
sudo mkdir -p /Volumes/Zurg
sudo chown "$(whoami)" /Volumes/Zurg
mkdir -p ~/zurg/logs
```

Consulte [la référence de configuration](../reference/config.md) pour toutes les options disponibles, ou utilise le Dashboard web sur `http://localhost:9999/config/` après avoir démarré zurg.

## Étape 5 : Tester zurg manuellement {#step-5-test-zurg-manually}

Avant de configurer le démarrage automatique, vérifiez que tout fonctionne :

```bash
cd ~/zurg && ./zurg
```

Vous devriez voir dans les logs zurg démarrer, se connecter à Real-Debrid et monter le point de montage via rclone. Dans une autre fenêtre de terminal, vérifiez :

```bash
# Check the HTTP endpoint
curl -s http://localhost:9999/http/version.txt

# Check the mount
ls /Volumes/Zurg/
# Expected: __all__  __downloads__  __unplayable__  movies  shows  version.txt
```

Si tout semble correct, arrêtez zurg avec `Ctrl+C`.

## Étape 6 : Installer Plex Media Server {#step-6-install-plex-media-server}

1. Téléchargez depuis [plex.tv/media-server-downloads](https://www.plex.tv/media-server-downloads/) — sélectionnez **macOS** (Universal)
2. Ouvrez le `.dmg` et glissez **Plex Media Server** dans `/Applications`
3. Lancez Plex Media Server depuis Applications (ou Spotlight : `Cmd + Space` → « Plex Media Server »)
4. Votre navigateur devrait s'ouvrir sur l'assistant de configuration de Plex — suivez-le pour associer votre serveur
5. **Activer le démarrage automatique :** faites un clic droit sur l'icône de Plex dans la barre de menus et cochez **Launch at Login**
6. Récupérez votre token Plex — le plus simple :
   - Ouvrez n'importe quel média dans Plex Web
   - Cliquez sur **Get Info** (ou **...** → **Get Info**)
   - Cliquez sur **View XML**
   - Cherchez `X-Plex-Token=` dans la barre d'adresse

Ajoutez le token Plex à votre configuration zurg en modifiant `config.yml` :

```yaml
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
```

## Étape 7 : Configurer le démarrage automatique de zurg manuellement {#step-7-set-up-zurg-auto-start-manually}

macOS LaunchAgents démarrent automatiquement les services à votre connexion. Plex gère déjà son propre démarrage automatique (étape 6), donc nous n'avons besoin d'un LaunchAgent que pour zurg.

### LaunchAgent de zurg {#zurg-launchagent}

```bash
cat > ~/Library/LaunchAgents/com.zurg.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zurg</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/zurg/zurg</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${HOME}/zurg</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME}/zurg/logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME}/zurg/logs/launchd-stderr.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST
```

Paramètres clés :
- **RunAtLoad** — démarre zurg quand vous vous connectez
- **KeepAlive / SuccessfulExit: false** — si zurg plante, launchd le redémarre automatiquement
- **ThrottleInterval: 10** — attend 10 secondes entre deux tentatives de redémarrage

### Charger le LaunchAgent {#load-the-launchagent}

```bash
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Vérifie qu'il est bien enregistré :

```bash
launchctl list | grep zurg
# Should show com.zurg with a PID
```

## Étape 8 : Configurer les bibliothèques Plex {#step-8-configure-plex-libraries}

Maintenant que zurg tourne et que le montage est actif :

1. Ouvrez [http://localhost:32400/web](http://localhost:32400/web)
2. Allez dans **Settings** (icône de clé à molette) → **Manage** → **Libraries**
3. Cliquez sur **Add Library**

**Ajouter la bibliothèque Movies :**
- Type : **Movies**
- Cliquez sur **Browse for media folder**
- Naviguez jusqu'à `/Volumes/Zurg/movies`
- Cliquez sur **Add Library**

**Ajouter la bibliothèque TV Shows :**
- Type : **TV Shows**
- Cliquez sur **Browse for media folder**
- Naviguez jusqu'à `/Volumes/Zurg/shows`
- Cliquez sur **Add Library**

**Réglages recommandés de la bibliothèque** (dans Edit → Advanced de chaque bibliothèque) :
- Décochez **Empty trash automatically after every scan** : zurg gère le cycle de vie du contenu
- Décochez **Generate video preview thumbnails** : ça économise de la bande passante, car les fichiers sont diffusés depuis Real-Debrid

## Étape 9 : Vérifier que tout fonctionne {#step-9-verify-everything-works}

```bash
# 1. zurg is running
curl -s http://localhost:9999/http/version.txt && echo " - zurg is up"

# 2. Mount is active
ls /Volumes/Zurg/movies > /dev/null 2>&1 && echo "Mount is active"

# 3. Plex is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:32400/identity && echo " - Plex is up"

# 4. Processes
ps -eo pid,command | grep -E "[z]urg|[r]clone.*mount|[P]lex Media Server" | head -5

# 5. zurg service (for the manual LaunchAgent from Step 7: launchctl list | grep com.zurg)
cd ~/zurg && ./zurg service status
```

## Étape 10 : Activer la connexion automatique (facultatif) {#step-10-enable-auto-login-optional}

Ceci n'est nécessaire que pour la méthode manuelle avec LaunchAgent. Un LaunchAgent exige qu'un utilisateur se connecte après chaque redémarrage. L'installateur intégré utilise plutôt un LaunchDaemon sur un Mac sans écran.

Si vous utilisez volontairement le LaunchAgent manuel sur un serveur sans écran, activez la connexion automatique pour qu'il démarre sans intervention :

1. Ouvrez **Réglages Système**
2. Allez dans **Utilisateurs et groupes**
3. Cliquez sur **Connexion automatique** et sélectionnez votre utilisateur
4. Saisissez votre mot de passe

> **Note de sécurité :** la connexion automatique signifie que toute personne ayant un accès physique au Mac peut accéder à votre compte. Ne l'utilisez que sur des machines situées dans un lieu de confiance.

---

## Gérer les services {#managing-the-services}

Pour une installation créée par `zurg setup`, utilisez les mêmes commandes sur toutes les plateformes :

```bash
cd ~/zurg
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` supprime seulement le démarrage automatique. Il laisse en place le binaire, la configuration, les données, les logs et le cache. Les commandes launchctl ci-dessous concernent le LaunchAgent manuel de l'étape 7 (`com.zurg`). `zurg setup` utilise son propre nom, `com.zurg.zurg`.

### Démarrer / Arrêter / Redémarrer {#start--stop--restart}

```bash
# Stop zurg (and its rclone child process)
launchctl stop com.zurg

# Start zurg
launchctl start com.zurg

# Restart zurg
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Voir les journaux {#view-logs}

```bash
# zurg logs
tail -50 ~/zurg/logs/zurg.log

# Rclone logs
tail -50 ~/zurg/logs/rclone.log
```

### Recharger après une modification de la configuration {#reload-after-config-change}

Si vous modifiez un fichier `.plist` :

```bash
launchctl unload ~/Library/LaunchAgents/com.zurg.plist
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Si vous modifiez `config.yml`, redémarrez simplement zurg :

```bash
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Mettre à jour zurg {#update-zurg}

Une build sponsor se remplace elle-même :

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` récupère la nightly la plus récente. Il la télécharge, vérifie que le nouveau binaire affiche bien la version attendue, puis le met en place par renommage, si bien que le processus en cours d'exécution n'est jamais écrasé. Si la build installée est déjà la plus récente, il te le dit et ne change rien.

`update` se connecte à GitHub avec le compte que tu as utilisé pour l'installation. L'installeur garde pour cela la GitHub CLI dans `~/zurg/bin`. Si `update` te dit qu'il n'a trouvé aucun identifiant GitHub, c'est que ton installation est antérieure à ce changement. Lance une fois la mise à jour depuis l'installeur, et toutes les commandes `zurg update` suivantes fonctionneront. La même commande met aussi à jour une build trop ancienne pour avoir `zurg update`.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

Tu peux aussi définir `GITHUB_TOKEN` à la place. Utilise un jeton classique avec le scope `repo`, depuis le compte GitHub qui a accès à zurg.

À la main, télécharge le nouveau zip `darwin-arm64` (`darwin-amd64` sur un Mac Intel) depuis [Releases](https://github.com/debridmediamanager/zurg/releases) de la même façon qu'à l'étape 2, puis :

```bash
cd ~/zurg
./zurg service stop && sleep 2     # manual LaunchAgent: launchctl stop com.zurg
rm -f zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
./zurg service start               # manual LaunchAgent: launchctl start com.zurg
```

Supprime l'ancien binaire plutôt que de l'écraser sur place. Réécrire le fichier conserve le même inode et invalide sa signature de code ad hoc, et macOS tue alors la nouvelle build au moment de l'exécution. Le symptôme : une sortie immédiate, sans aucun message. C'est exactement pour cette raison que `zurg update` procède par renommage.

## Dépannage {#troubleshooting}

### « Operation not permitted » lors du montage {#operation-not-permitted-when-mounting}

macFUSE doit être approuvé dans Réglages Système :
1. Allez dans **Réglages Système > Confidentialité et sécurité**
2. Faites défiler vers le bas et cherchez un message indiquant qu'une extension système a été bloquée
3. Cliquez sur **Autoriser**, puis **redémarrez**

### Le montage affiche « not a directory » ou reste bloqué {#mount-shows-as-not-a-directory-or-hangs}

Le point de montage est peut-être resté coincé suite à un ancien plantage :

```bash
umount -f /Volumes/Zurg 2>/dev/null
diskutil unmount force /Volumes/Zurg 2>/dev/null
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### zurg redémarre sans arrêt (boucle de plantage) {#zurg-keeps-restarting-crash-loop}

Consulte les logs pour trouver l'erreur :

```bash
tail -100 ~/zurg/logs/service-stderr.log   # manual LaunchAgent: launchd-stderr.log
```

Causes courantes :
- Syntaxe `config.yml` invalide : vérifie-la en lançant `cd ~/zurg && ./zurg` à la main
- Token Real-Debrid expiré : récupères-en un nouveau sur [real-debrid.com/apitoken](http://real-debrid.com/?id=20476410)
- `/Volumes/Zurg` absent ou qui n'appartient pas à ton utilisateur : zurg ne peut pas le créer et échoue avec `ensure mount path: permission denied` (étape 4)
- Port 9999 déjà utilisé : vérifie avec `lsof -i :9999`

### macFUSE ne fonctionne plus après une mise à jour de macOS {#macfuse-breaks-after-macos-update}

Les mises à jour majeures de macOS peuvent parfois invalider l'extension noyau. Réinstallez macFUSE :
1. Téléchargez la dernière version depuis [macfuse.io](https://macfuse.io)
2. Installez-la
3. Approuvez l'extension dans **Réglages Système > Confidentialité et sécurité**
4. Redémarrez

### Tout fonctionnait mais s'est arrêté après un redémarrage {#everything-was-working-but-stopped-after-reboot}

Si vous avez installé le LaunchAgent manuel et que la connexion automatique n'est pas activée, vous devez vous connecter avant son démarrage. Vous pouvez soit :

- Activer la connexion automatique (voir l'étape 10)
- Vous connecter en SSH : les LaunchAgents seront déjà chargés dès que la session utilisateur existe
- Utiliser VNC/Partage d'écran pour vous connecter à distance

Une installation créée par `zurg setup` sur un Mac sans écran utilise un LaunchDaemon et n'a pas besoin d'une connexion graphique. Vérifiez-le avec `cd ~/zurg && ./zurg service status`.

Toujours bloqué ? Posez votre question dans le forum **zurg-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) indique ce qu'il faut inclure.

## Vue d'ensemble de l'architecture {#architecture-overview}

```
launchd (PID 1)

  com.zurg LaunchAgent
    └── ./zurg
          ├── HTTP/WebDAV server (:9999)
          ├── Dashboard UI (:9999/config/)
          ├── Real-Debrid API client
          └── rclone mount (child process)
                └── /Volumes/Zurg/
                      ├── movies/
                      └── shows/

  Plex Media Server (:32400)  — Launch at Login via menu bar
    ├── Movies library  → /Volumes/Zurg/movies
    └── Shows library   → /Volumes/Zurg/shows

  macFUSE kernel extension
    └── Enables FUSE mounts for rclone
```

## Référence rapide {#quick-reference}

Exécutez-les dans `~/zurg`. Les lignes `zurg service` concernent une installation faite avec `zurg setup` ; le LaunchAgent manuel utilise les commandes launchctl décrites dans [Managing the Services](#managing-the-services).

| Action | Commande |
|--------|---------|
| Démarrer zurg | `./zurg service start` |
| Arrêter zurg | `./zurg service stop` |
| Redémarrer zurg | `./zurg service restart` |
| Vérifier l'installation | `./zurg doctor` |
| Supprimer le démarrage automatique | `./zurg service uninstall` |
| Voir les journaux de zurg | `tail -f ~/zurg/logs/zurg.log` |
| Voir les journaux de rclone | `tail -f ~/zurg/logs/rclone.log` |
| Vérifier le montage | `ls /Volumes/Zurg/` |
| Vérifier que zurg répond | `curl http://localhost:9999/http/version.txt` |
| Vérifier que Plex répond | `curl http://localhost:32400/identity` |
| Tableau de bord | `open http://localhost:9999/config/` |
| Forcer le démontage | `umount -f /Volumes/Zurg` |
