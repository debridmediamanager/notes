# Installation du binaire Linux {#linux-binary-setup}

## Option en une ligne {#one-line-option}

L'amorçage optionnel du sponsor installe les paquets système, télécharge le bon build pour votre processeur, puis lance la configuration et les diagnostics :

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Il vous connecte via GitHub et installe dans `~/zurg`. Les binaires et configs existants restent en place. Continuez ci-dessous pour la méthode manuelle ou un chemin personnalisé.

Le binaire zurg peut installer le reste lui-même. Il écrit la config, télécharge la bonne version de rclone (et ffprobe, sauf si l'un des deux est déjà dans votre PATH) pour la machine, crée le point de montage et enregistre un service systemd activé.

Ce parcours a été vérifié le 4 septembre 2026 sur des serveurs Ubuntu 24.04 ARM64 et x86_64 fraîchement installés.

## 1. Installer FUSE 3 {#1-install-fuse-3}

Sur Debian, Ubuntu et leurs dérivés :

```bash
sudo apt-get update
sudo apt-get install -y fuse3
```

Les autres distributions appellent aussi le paquet `fuse3` : `sudo dnf install fuse3` sur Fedora, `sudo pacman -S fuse3` sur Arch, `sudo zypper install fuse3` sur openSUSE.

Vérifie que l'outil d'aide et le périphérique sont bien présents :

```bash
command -v fusermount3
test -c /dev/fuse
```

Si Plex, Jellyfin ou un autre processus tourne sous un autre utilisateur Unix, active `allow_other` une seule fois :

```bash
echo user_allow_other | sudo tee -a /etc/fuse.conf
```

Sans ce réglage, le montage fonctionne quand même, mais seul le compte qui exécute zurg peut y accéder. `zurg doctor` signale la différence.

## 2. Télécharger zurg {#2-download-zurg}

Téléchargez l'archive Linux correspondante depuis les [releases sponsor](https://github.com/debridmediamanager/zurg/releases). Choisissez `linux-amd64` pour une machine Intel ou AMD, et `linux-arm64` pour une machine ARM.

Prenez la dernière nightly. C'est la pré-version en haut de la liste. Ne prenez pas la release que GitHub marque **Latest**. C'est v1.0.0. Elle est plus ancienne que `zurg setup` et répond `unknown command` à cette commande.

Les nightlies sont réservées aux sponsors. Tant que votre compte GitHub n'y a pas accès, cette page répond 404. Devenez sponsor sur [gatekeeper](https://gatekeeper.debridmediamanager.com/) pour obtenir l'accès. La version publique gratuite est v1.0.0, disponible sur [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). Elle n'a pas de `zurg setup`. Configurez-la à la main comme l'explique [son README](https://github.com/debridmediamanager/zurg-public#readme), au lieu de suivre les étapes ci-dessous.

Décompressez-la dans le répertoire qui doit contenir toute l'installation :

```bash
mkdir -p ~/zurg
cd ~/zurg
# Put the downloaded zurg binary here, then:
chmod +x zurg
```

Tout ce que zurg conserve reste à côté de ce binaire : `config.yml`, les helpers téléchargés, l'état de la bibliothèque, les logs et le cache rclone.

## 3. Lancer la configuration {#3-run-setup}

```bash
cd ~/zurg
./zurg setup
```

Setup vous demande quels fournisseurs configurer. Choisissez-en un ou plusieurs, par ordre de priorité :

```text
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
```

Par exemple, saisissez `2,4` pour TorBox suivi de Usenet. Setup ne demande que les identifiants des fournisseurs sélectionnés. Il effectue ensuite les étapes suivantes :

1. Crée et valide `config.yml`.
2. Restreint le fichier de configuration à son propriétaire avec le mode `0600`.
3. Télécharge une version native de rclone dans `bin/`, ainsi que ffprobe, à moins que ffprobe ne soit déjà présent dans votre PATH.
4. Active le montage rclone sur `/mnt/zurg`.
5. Installe et démarre un service systemd activé.

Si vous n'avez pas la permission de créer `/mnt/zurg`, utilisez un montage dans votre répertoire personnel :

```bash
./zurg setup --mount-path "$HOME/zurg-mount"
```

Vous pouvez relancer Setup sans risque. Il met à jour le service généré, mais ne remplace pas un `config.yml` existant.

### Choisir la portée systemd {#choosing-the-systemd-scope}

With a working systemd user manager, the default `auto` scope installs `~/.config/systemd/user/zurg.service`. Otherwise, setup installs `/etc/systemd/system/zurg.service` and asks sudo to run it as the current user.

Choose explicitly when needed:

```bash
./zurg setup --service-scope user
./zurg setup --service-scope system --service-user "$USER"
```

For a user service to start before the first login after a reboot, enable lingering:

```bash
loginctl show-user "$USER" -p Linger
sudo loginctl enable-linger "$USER"
```

Running setup as `root` on a server selects a system service owned by root.

## 4. Vérifier l'installation {#4-verify-the-install}

```bash
./zurg doctor
curl -fsS http://127.0.0.1:9999/http/version.txt
ls /mnt/zurg/version.txt
```

`doctor` vérifie la config et ses permissions, les deux outils téléchargés, FUSE, l'unité systemd, le point de terminaison HTTP et le montage signalé par zurg.

Une grosse bibliothèque Real-Debrid prend du temps à se construire lors du premier lancement. Le service peut déjà être actif alors que la première liste du montage attend la fin de ce scan.

`version.txt` répond dès que zurg tourne. Une grosse bibliothèque continue de charger après ça. Ses dossiers apparaissent vides ou avec `Input/output error` tant que ce n'est pas fini. `/ready` te dit quand c'est terminé.

```bash
curl -fsS http://127.0.0.1:9999/ready
```

## Disque utilisé par le montage {#disk-the-mount-uses}

Le montage met en cache chaque fichier qu'il lit dans `~/zurg/data/rclone-cache`. Il conserve le fichier entier une fois la lecture terminée. Si rien n'est fait, ce cache grossit jusqu'à **256G** et y reste. Il n'est pas vidé quand une vidéo s'arrête. La limite d'âge de 72h ne vous sauvera pas non plus. rclone considère qu'un fichier a été consulté dès que quelque chose le lit, et le passage de maintenance nocturne d'un serveur multimédia lit toute la bibliothèque.

Vérifiez ce qu'il contient.

```bash
du -sh ~/zurg/data/rclone-cache
```

Si 256G dépassent l'espace disque que vous pouvez accorder, réduisez la limite dans `config.yml`.

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Redémarrez zurg ensuite. Pour le vider à la main, arrêtez d'abord zurg, puis exécutez ceci.

```bash
rm -rf ~/zurg/data/rclone-cache/vfs/* ~/zurg/data/rclone-cache/vfsMeta/*
```

Déplacer le répertoire de zurg renomme le cache et laisse l'ancienne copie en place. zurg récupère ces copies au prochain démarrage et consigne l'espace libéré. Les détails et la désactivation sont dans [la référence de configuration](../reference/config.md#disk-the-mount-uses).

## Gérer zurg {#managing-zurg}

Exécutez ces commandes depuis le répertoire zurg :

```bash
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` supprime uniquement le démarrage automatique. Le binaire, la configuration, les données, les journaux et le cache restent en place.

Pour suivre les journaux d'un service utilisateur :

```bash
journalctl --user -u zurg.service -f
```

Pour un service système :

```bash
sudo journalctl -u zurg.service -f
```

## Mettre à jour zurg {#updating-zurg}

Une build sponsor se remplace elle-même :

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` récupère la nightly la plus récente. Il la télécharge, vérifie que le nouveau binaire renvoie la version attendue, puis le remplace par renommage, pour que le processus en cours ne soit jamais écrasé. Si la build installée est déjà la plus récente, il le signale et ne change rien.

`update` se connecte à GitHub avec le compte que tu as utilisé pour l'installation. L'installateur garde la GitHub CLI dans `~/zurg/bin` pour cela. Si `update` indique qu'il n'a trouvé aucun identifiant GitHub, ton installation est plus ancienne que ce changement. Lance une fois la mise à jour de l'installateur, et chaque `zurg update` ensuite fonctionnera. Cette même commande met aussi à jour une build trop ancienne pour avoir `zurg update`. Elle remplace seulement le binaire et ne touche à rien d'autre.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

Un serveur sans la GitHub CLI peut définir `GITHUB_TOKEN` à la place. Utilise un token classique avec le scope `repo`, créé depuis le compte GitHub qui a accès à zurg.

## Configurations existantes et sans surveillance {#existing-and-unattended-configs}

La configuration ne remplace jamais un `config.yml` existant. Pour une installation sans interaction, répétez `--provider` et fournissez les options correspondantes de fichier de jeton ou `--nntp-*`. Les variables `REALDEBRID_TOKEN`, `TORBOX_TOKEN`, `ALLDEBRID_TOKEN` et les variables `NNTP_*` fonctionnent aussi. Lancez `./zurg setup --help` pour la liste complète.

Consultez la [référence de configuration](../reference/config.md) pour tous les réglages.

Toujours bloqué ? Posez votre question dans le forum **zurg-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](../../guides/remote-help.md) indique ce qu'il faut inclure.

## Voir aussi {#see-also}

- [Docker](docker.md) — configuration du conteneur et propagation du montage FUSE
- [macOS](macos.md) — le même installeur binaire avec macFUSE et launchd
- [Windows](windows.md) — le même installeur binaire avec WinFsp et une tâche planifiée interactive
