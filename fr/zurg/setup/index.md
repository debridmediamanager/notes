# Configuration {#setup}

L'installeur binaire est le chemin le plus court sous Linux, macOS et Windows. Docker reste disponible sur un hôte Linux lorsqu'un conteneur convient mieux. Docker Desktop sur macOS et Windows exécute les conteneurs dans une VM, donc le montage ne peut pas apparaître dans le Finder ou l'Explorateur, et rex ne peut pas atteindre zurg : utilisez le binaire dans ce cas.

## Installateurs en une ligne {#one-line-convenience-installers}

Les installateurs téléchargent une version nightly réservée aux sponsors. Devenez d'abord sponsor sur [gatekeeper](https://gatekeeper.debridmediamanager.com/). Cela donne accès à votre compte GitHub.

Pour une première installation sponsor, choisissez la commande correspondant à votre système :

+++ Linux et macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```
+++ Docker sous Linux
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```
+++ Windows
Dans PowerShell :
```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```
+++

Le bootstrap vérifie les prérequis de la plateforme, se connecte à GitHub pour l'accès sponsor, télécharge la version correspondante et lance le sélecteur de fournisseur. Les binaires et configurations existants sont conservés. Chaque guide ci-dessous décrit aussi la méthode manuelle complète.

- [Linux](linux.md)
- [Docker](docker.md) (hôtes Linux)
- [macOS](macos.md)
- [Windows](windows.md)

Une fois zurg installé, [Fournisseurs](../providers/index.md) explique comment le relier à un compte. Il y a une page par service, avec les identifiants, l'entrée `config.yml` et ce que ce service fait différemment. Ces pages sont écrites pour Docker. Avec une installation par binaire, l'entrée `config.yml` du fournisseur et les étapes du Dashboard sont les mêmes, mais `./zurg service restart` (`.\zurg.exe service restart` sous Windows) remplace `docker compose restart zurg`. La ligne `docker compose run --rm zurg setup` devient `./zurg setup` (`.\zurg.exe setup` sous Windows), avec les mêmes options, sauf `--no-service --skip-downloads --mount-path /zurg_mnt/zurg` qui sont propres au conteneur. Un drapeau `--…-file` désigne alors un fichier sur votre machine au lieu d'un fichier situé sous `/config`.
