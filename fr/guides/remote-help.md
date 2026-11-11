# Obtenir de l'aide pour zurg et rex {#getting-help-with-zurg-and-rex}

## Demander sur Discord {#ask-in-discord}

Poste dans le forum [Discord](https://discord.com/invite/7u4YjMThXP) ce que tu utilises : **zurg-support**, **rex-support** ou **dmm-support**. Ouvre un fil par problème. Dis ce que tu as fait, ce que tu attendais et ce qui s'est passé. Ajoute les détails ci-dessous.

**Pour zurg**, clique sur **Export Logs** dans le tableau de bord de zurg et colle les liens qu'il te donne. Il envoie le log et la config de zurg, sans tes tokens, mots de passe et clés API. Si l'envoi ne marche pas, **Download Logs** te donne la même chose sous forme de fichier à joindre. Colle aussi ce que `zurg doctor` affiche :

| zurg tourne en tant que | Commande |
|---|---|
| Le binaire sous Linux ou macOS | `./zurg doctor` dans le dossier de zurg |
| Le binaire sous Windows | `.\zurg.exe doctor` dans le dossier de zurg |
| Docker | `docker compose exec zurg /app/zurg doctor --working-dir /config` |

**Pour rex**, appuie une fois sur Play sur ce qui échoue, puis colle la fin du log de rex. rex masque les tokens Plex dedans.

| rex tourne en tant que | Commande |
|---|---|
| Un service systemd sous Linux | `journalctl --user -u rex -n 200 --no-pager` |
| launchd sous macOS | `tail -n 200 ~/rex/rex.log` |
| Le planificateur de tâches sous Windows | `Get-Content $HOME\rex\rex.log -Tail 200` |
| Docker | `docker compose logs --tail=200 rex` |
| Une fenêtre de terminal | Les 200 dernières lignes de cette fenêtre |

Dans un long log, les lignes les plus importantes sont les erreurs, les avertissements et ce que rex a décidé pour chaque lecture. Ajoute `| grep -E 'ERROR|WARN|upstream|DECISION'` à la commande Linux, macOS ou Docker pour n'afficher que ces lignes. Sous Windows, lance plutôt `Select-String 'ERROR|WARN|upstream|DECISION' $HOME\rex\rex.log | Select-Object -Last 50`.

## Aide à distance pour les sponsors {#remote-help-for-sponsors}

Quand un fil ne règle pas le problème, un helper peut taper dans votre terminal pendant que vous regardez. **L'aide à distance pour zurg et rex est réservée aux sponsors et elle est gratuite.** [Devenez sponsor sur gatekeeper](https://gatekeeper.debridmediamanager.com/). Connectez Discord là-bas pour obtenir le rôle sponsor, puis posez votre question dans votre fil de support.

Cette page vous explique comment la mettre en place avec [upterm](https://github.com/owenthereal/upterm) via `upterm.debridmediamanager.com`. Ça marche sous Linux, macOS et Windows.

Vous n'avez besoin ni de mot de passe de compte, ni de changer quoi que ce soit sur votre routeur, ni d'installer quoi que ce soit au préalable. Les commandes téléchargent et lancent upterm. Suivez chaque commande dans le même terminal. Tapez `exit` pour terminer la session.

### 1. Choisissez la machine {#1-pick-the-machine}

Lancez upterm sur la machine qui fait tourner zurg ou rex. Il peut s'agir d'un serveur et non de l'ordinateur devant vous.

| Où ça tourne | Que faire |
|---|---|
| Cet ordinateur | Ouvrez un terminal ici et passez à l'étape 2. |
| Un serveur cloud comme Hetzner, Oracle ou un VPS | Connectez-vous d'abord en SSH. Ensuite, utilisez la ligne Linux de l'étape 2 dans cette fenêtre SSH. |
| Un NAS ou un serveur à la maison comme Synology ou Unraid | Ouvrez son terminal. Ensuite, utilisez la ligne Linux de l'étape 2 là-bas. |
| Docker | Utilisez la machine qui fait tourner Docker et non un conteneur. |

Vous pouvez aussi utiliser SSH depuis Windows. PowerShell intègre déjà `ssh`.

```bash
ssh you@your-server
```

**Synology** a SSH désactivé par défaut. Activez-le dans Panneau de configuration > Terminal et SNMP > Activer le service SSH. Connectez-vous ensuite avec un compte administrateur. Utilisez l'adresse du NAS indiquée par votre routeur ou par Synology Assistant.

Si l'étape 2 affiche `cannot create directory` sur Synology, activez Panneau de configuration > Utilisateur et groupe > Avancé > Activer le service de répertoire personnel utilisateur, puis relancez la commande.

**Unraid** dispose d'un terminal dans sa page web. Cliquez sur l'icône `>_` en haut à droite.

### 2. Démarrez une session {#2-start-a-session}

Collez la ligne du système que vous avez choisi à l'étape 1.

#### Linux et macOS {#linux-and-macos}

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

#### Windows

Ouvrez PowerShell. Il n'est pas nécessaire de l'exécuter en tant qu'administrateur.

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz" -UseBasicParsing; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

Sur un ordinateur portable ARM comme une Surface Pro X, remplacez `amd64` par `arm64`.

La première fois, upterm vous demande si vous voulez faire confiance à `upterm.debridmediamanager.com`. Tapez `yes`. L'empreinte affichée doit être celle-ci.

```
SHA256:r1LtSiydnfetLGxGt8hy+ULyqtN2KgnZSHtRgHzDr58
```

### 3. Envoyez la ligne SSH à votre aidant {#3-send-the-ssh-line-to-your-helper}

upterm affiche quelques lignes. Copie celle qui se trouve sous **SSH**, qui ressemble à ceci.

```
ssh AbCdEfGhIjKlMnOpQrSt:dXB0ZXJt...@upterm.debridmediamanager.com -p 2222
```

**Envoie-la en message privé.** Ne la publie jamais dans un canal public. Quiconque la possède peut taper sur ta machine.

Ensuite, laisse la fenêtre ouverte et ne clique pas dedans : sous Windows, un clic dans une fenêtre PowerShell peut mettre en pause ce qui s'y exécute tant que tu n'as pas appuyé sur `Esc`. Tu vois tout ce que ton aide tape dans cette fenêtre au fur et à mesure qu'il le tape.

### 4. Terminez-la {#4-end-it}

**Tapez `exit` dans cette fenêtre quand vous avez terminé.** La session se termine et la ligne cesse de fonctionner immédiatement.

Fermer la fenêtre ne suffit pas : la session continue de tourner. Si vous l'avez fermée, ouvrez un nouveau terminal, lancez `~/upterm/upterm session list` (sous Windows `& "$env:LOCALAPPDATA\upterm\upterm.exe" session list`), puis le même programme avec `session stop` et le nom qu'il affiche.

Pour obtenir de l'aide plus tard, collez à nouveau la ligne de l'étape 2. Chaque session reçoit une nouvelle ligne.

## Pour les aidants {#for-helpers}

Lancez la ligne SSH que vous avez reçue. N'importe quelle clé SSH convient ; si vous n'en avez pas, exécutez d'abord une fois `ssh-keygen -t ed25519`. Vous arrivez dans leur terminal : PowerShell sous Windows, leur shell habituel sous Linux et macOS.

Pour copier un fichier, le `:` de l'ID de session perturbe `scp`. Passez-le donc comme utilisateur à la place : `scp -P 2222 -o User=<everything before the @> file upterm.debridmediamanager.com:file`.

Demandez-leur de taper `exit` quand vous avez terminé.
