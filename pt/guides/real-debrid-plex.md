# Uma biblioteca do Real-Debrid no Plex com o zurg {#a-real-debrid-library-in-plex-with-zurg}

zurg mostra tudo o que existe na sua conta do Real-Debrid como pastas no seu computador, já organizadas em `movies` e `shows`. Adicione essas duas pastas ao Plex Media Server e toda a sua biblioteca do Real-Debrid aparece em todos os apps do Plex, transmitida direto do Real-Debrid, sem baixar nada antes. Você instala o zurg uma vez só; ele já traz o próprio rclone, então não há mais nada para configurar.

Não quer rodar o Plex Media Server nem um drive montado? [rex com zurg](../rex/with-zurg.md) mostra a mesma biblioteca para os apps do Plex sem precisar de nenhum dos dois.

## O que você precisa {#what-you-need}

- **Um patrocínio.** A versão nightly do zurg é só para patrocinadores. Patrocine pelo [gatekeeper](https://gatekeeper.debridmediamanager.com/) e ele dá à sua conta do GitHub acesso ao download. [O que um patrocínio te dá](sponsorship.md) tem o resto.
- **Uma conta premium do Real-Debrid** e o seu token de API: [Seu token de API do Real-Debrid](real-debrid-api-token.md) mostra onde encontrá-lo.
- **Plex Media Server no mesmo computador que o zurg.** O Plex lê os arquivos das pastas do zurg, então precisa conseguir vê-los. Depois disso, qualquer app do Plex pode assistir.
- **Um computador que fique ligado**: Windows 10 ou 11, Linux, um Mac, ou uma máquina Linux com Docker.

## 1. Instale o zurg {#1-install-zurg}

Cada página de configuração começa com um instalador de uma linha. Quando aparecer `Choose one or more providers in priority order:`, digite `1` para Real-Debrid e depois cole o seu token.

| Seu computador | Instale com | Sua biblioteca aparece em |
|---|---|---|
| Windows | [zurg no Windows](../zurg/setup/windows.md) | `Z:\movies` e `Z:\shows` |
| Linux | [zurg no Linux](../zurg/setup/linux.md) | `/mnt/zurg/movies` e `/mnt/zurg/shows` |
| Mac | [zurg no macOS](../zurg/setup/macos.md) | `/Volumes/Zurg/movies` e `/Volumes/Zurg/shows` |
| Linux com Docker | [Um único arquivo Docker Compose](../zurg/guides/docker-compose.md), que roda o Plex Media Server junto com o zurg | `/zurg_mnt/zurg/movies` e `/zurg_mnt/zurg/shows` |

O instalador termina com `zurg doctor`, uma lista de linhas `PASS`.

## 2. Verifique as pastas {#2-check-the-folders}

Abra a pasta ou o drive do zurg. Você deve ver `movies`, `shows`, `__all__`, `__downloads__`, `__unplayable__` e `version.txt`.

A primeira inicialização lê toda a sua conta do Real-Debrid. Até isso terminar, as pastas ficam vazias. Para conferir, abra `http://localhost:9999/ready` no navegador: ele mostra `ready` quando sua biblioteca já estiver carregada.

## 3. Adicione as pastas no Plex {#3-add-the-folders-in-plex}

No Plex Web, clique em **Add Library**, o botão ao lado do nome do seu servidor na barra lateral:

1. Escolha **Movies** e clique em **Next**.
2. Clique em **Browse for media folder** e escolha a pasta `movies` do zurg que aparece na tabela acima, como `Z:\movies` no Windows.
3. Clique em **Add Library**.

Faça o mesmo com **TV Shows** e a pasta `shows`. Em seguida, o Plex escaneia as duas e preenche os pôsteres e os títulos.

## 4. Deixe o zurg avisar o Plex sobre coisas novas {#4-let-zurg-tell-plex-about-new-things}

Plex não percebe quando algo novo chega na sua conta do Real-Debrid. O zurg pode avisar o Plex. Abra o painel do zurg em `http://localhost:9999/config/`, vá em **Media Server Integration** e clique em **Login with Plex**. Entre na sua conta do Plex e escolha o seu servidor.

![A seção Media Server Integration do painel do zurg, com o botão Login with Plex](../assets/real-debrid-plex/01-zurg-login-with-plex.webp)

A partir daí, o zurg pede ao Plex para escanear cada pasta que muda. Ele também desliga algumas configurações do Plex que são arriscadas em uma biblioteca de streaming, como **Empty trash automatically after every scan**: [Configurações recomendadas do Plex](../zurg/guides/plex.md#recommended-plex-settings) lista todas elas.

## Quando algo está errado {#when-something-is-wrong}

| O que você vê | O que fazer |
|---|---|
| O Plex não encontra nada, ou as pastas do zurg estão vazias | O zurg ainda está lendo sua conta. Espere até que `http://localhost:9999/ready` diga `ready`, depois escaneie de novo no Plex. |
| No Windows não existe a unidade `Z:`, ou o Plex não encontra `Z:\movies` | A `Z:` pertence à sessão da sua área de trabalho do Windows, e o instalador do zurg inicia o zurg ali quando você faz login. Um PowerShell aberto como administrador também não a enxerga. [Quando algo está errado no Windows](../zurg/setup/windows.md#when-something-is-wrong) cobre cada caso. |
| No Linux, o Plex vê uma pasta vazia ou não consegue abri-la, e `./zurg doctor` diz `user_allow_other is not enabled in /etc/fuse.conf; the mount will be visible only to the zurg service user` | O Plex roda com um usuário diferente do zurg. Libere o acesso para outros usuários com <code>echo user_allow_other &#124; sudo tee -a /etc/fuse.conf</code>, depois rode `./zurg service restart` na pasta do zurg. |
| No Docker, as bibliotecas do Plex ficam vazias depois que o zurg reinicia, e `docker exec plex ls /zurg_mnt/zurg` diz `Transport endpoint is not connected` | Dê à pasta do zurg para o container do Plex usando `rslave`: `/zurg_mnt:/zurg_mnt:rslave`. [Um arquivo do Docker Compose](../zurg/guides/docker-compose.md) já tem isso. |
| Coisas novas aparecem nas pastas do zurg, mas não no Plex | Faça o passo 4. Até lá, clique em **Scan Library Files** na biblioteca no Plex. |
| O zurg diz `bad_token` | O token da API do Real-Debrid está errado ou cortado. [Seu token da API do Real-Debrid](real-debrid-api-token.md#when-something-is-wrong) tem a solução. |
| Seu disco enche | O zurg guarda uma cópia do que você assiste, até 256G por padrão. Limite isso como mostram [Mantendo o cache pequeno](../zurg/setup/windows.md#keeping-the-cache-small) (Windows) ou [Disco que o mount usa](../zurg/setup/linux.md#disk-the-mount-uses) (Linux). |

Ainda travado? Pergunte no fórum **zurg-support** do [Discord](https://discord.com/invite/7u4YjMThXP). [Pedindo ajuda](remote-help.md) explica o que incluir.

## Perguntas {#questions}

### Existe um guia para configurar o DMM, o zurg e o rclone para fazer streaming no Plex? {#is-there-a-guide-to-set-up-dmm-zurg-and-rclone-to-stream-in-plex}

Esta página. Você não configura o rclone manualmente: o instalador do zurg baixa e o zurg executa. O DMM é onde você encontra os lançamentos e os adiciona à sua conta do Real-Debrid ([O que é o DMM e como usar](../dmm/index.md)). Depois, o zurg mostra eles nas suas pastas e o Plex os encontra.

### Os filmes são baixados para o meu computador? {#do-the-movies-download-to-my-computer}

Não. O Plex lê cada arquivo do Real-Debrid através do zurg quando você aperta play. O zurg mantém um cache do que foi reproduzido, e ele pode crescer bastante: veja a linha de disco acima.

### Posso pular o Plex Media Server? {#can-i-skip-plex-media-server}

Sim, com o rex. [rex com o zurg](../rex/with-zurg.md) mostra sua biblioteca do zurg nos apps do Plex, sem Plex Media Server e sem mount. Você também pode rodar os dois: [Um arquivo Docker Compose](../zurg/guides/docker-compose.md) roda o zurg, o Plex Media Server e o rex em uma única máquina.

### Também funciona com TorBox ou Usenet? {#does-it-work-with-torbox-or-usenet-too}

Sim. O instalador do zurg também oferece TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud e Usenet, e coloca todos eles nas mesmas pastas `movies` e `shows`. A [Provedores](../zurg/providers/index.md) tem uma página para cada um.
