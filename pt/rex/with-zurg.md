# rex com zurg {#rex-with-zurg}

[rex](https://rex.debridmediamanager.com/pt/) é um servidor de mídia para os apps oficiais do Plex que não guarda nenhum arquivo. Os apps oficiais do Plex o veem como um servidor Plex normal. Qualquer app pode alimentá-lo ([rex com seu próprio app](any-source.md)). Esta página o configura com o zurg, que envia a sua biblioteca do debrid para ele. Quando você aperta play, o rex transmite o arquivo direto do zurg. Nada é baixado antes.

Esta página leva você do zero até assistir a um filme, um passo de cada vez. Cada passo explica o que ele faz, por que importa e o que você deve ver antes de seguir. Se o que você vir não bater com o descrito, pare ali: o próximo passo não vai resolver.

![o zurg se registra no rex e envia a biblioteca para ele; os apps do Plex reproduzem pelo rex, que lê cada arquivo do zurg](../assets/rex/how-it-fits.svg)

Quatro coisas para saber antes de começar:

- **O zurg é a parte que conversa com o seu serviço de debrid.** Ele lista o que está na sua conta e entrega os arquivos.
- **O rex é a parte com a qual os seus apps do Plex conversam.** Ele não guarda arquivos e não precisa de disco para a mídia. Não precisa de rclone nem de montagem.
- **O zurg avisa o rex sobre si mesmo.** Você dá ao zurg o endereço do rex, e o zurg faz o resto. Você nunca digita os dados do zurg no rex.
- **O zurg e o DMM decidem o que cada arquivo é; o Plex descreve.** O zurg pergunta ao DMM qual filme ou episódio é cada arquivo, e o rex mostra esse título com os pôsteres e as sinopses que os próprios metadados do Plex fornecem, assim que o rex estiver em uma conta do Plex. O rex nunca adivinha pelo nome do arquivo.

O rex é gratuito para uso pessoal (PolyForm Noncommercial): não há nível de patrocinador e você não precisa de conta para baixá-lo. A versão nightly do zurg, que este guia usa, continua sendo uma versão para patrocinadores; o [rex com seu próprio app](any-source.md) executa o rex sem ela.

## Antes de começar {#before-you-start}

| Você precisa | Por quê |
|---|---|
| Uma máquina que fique ligada: Linux (Ubuntu 22.04 ou mais novo), macOS ou Windows (64 bits). Um LXC do Proxmox funciona, sem privilégios também serve, desde que o FUSE esteja ativado para ele (Options > Features > FUSE): o instalador do zurg para se não houver `/dev/fuse` | rex e zurg são servidores: seus apps do Plex os acessam sempre que você aperta play. Onde os comandos mudam, um passo tem uma aba para cada sistema. [Docker](#run-rex-in-docker) aparece mais abaixo, para Linux |
| 1 GB de RAM | Com 4.062 filmes e 656 séries (34.678 episódios), o rex usou menos de 500 MB enquanto iniciava e cerca de 730 MB ao navegar pela biblioteca; converter vídeo exige mais. O zurg precisa de pouco |
| Uma conta de debrid (Real-Debrid, TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud) ou Usenet | É ali que seus filmes e séries realmente ficam |
| Uma conta do GitHub com acesso às releases de patrocinador do zurg | A nightly do zurg é uma release privada no GitHub. O [gatekeeper](https://gatekeeper.debridmediamanager.com/) dá acesso à sua conta quando você patrocina. O instalador do zurg faz login uma vez |
| Sua chave de API do DMM, obtida no [gatekeeper](https://gatekeeper.debridmediamanager.com/) depois que você patrocina (opcional) | O zurg pergunta ao DMM o que é cada arquivo. Sem ela, o zurg descobre pelo nome da release, usando a busca gratuita de títulos do DMM: menos títulos são encontrados, e um anime numerado ao longo da série inteira continua na ordem dos arquivos |
| Uma conta nova do Plex, criada só para o rex | O rex pega de the Plex todo título, pôster, sinopse e nome de episódio assim que ela for [adicionada a uma conta do Plex](#step-3-add-it-to-a-plex-account). Até lá, os títulos mantêm os nomes dos arquivos e não têm pôsteres |

Esta página precisa do rex nightly **2026.10.25 ou mais novo** e do zurg nightly **2026.10.27 ou mais novo**.

## Passo 1. Instale o zurg {#step-1-install-zurg}

**O que faz.** Baixa o zurg, pede a sua conta de debrid e inicia o zurg como um serviço que volta a funcionar depois de reiniciar o computador.

**Por que importa.** Tudo o que o rex mostra vem do zurg. Se o zurg não conseguir ver a sua biblioteca, o rex nunca vai conseguir.

**No Windows e no macOS, instale o zurg com o instalador abaixo, não no Docker Desktop.** O rex lê cada arquivo do endereço que o zurg informa, e ele não consegue acessar um zurg dentro do Docker Desktop: os títulos apareceriam, mas nada tocaria.

+++ Linux
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
sudo loginctl enable-linger "$USER"
```

O zurg vai para `~/zurg`. A segunda linha mantém os seus serviços rodando quando você sai da sessão.
+++ macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

O zurg vai para `~/zurg`. O instalador também instala o macFUSE, e o macOS pode pedir que você o permita em **System Settings**, **Privacy & Security**, seguido de uma reinicialização: [zurg no macOS](../zurg/setup/macos.md).
+++ Windows
No PowerShell:

```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```

O zurg vai para `$HOME\zurg` (`C:\Users\you\zurg`). O instalador também instala o WinFsp, pedindo aprovação de administrador, e inicia o zurg sempre que você fizer login no Windows: [zurg no Windows](../zurg/setup/windows.md).
+++

O instalador pergunta quais serviços você usa (digite `1` para Real-Debrid) e depois pede o seu token de API. O token fica oculto enquanto você o cola.

**O que você deve ver.** O instalador termina com uma lista de linhas `PASS` e `==> zurg is installed in` com a pasta do zurg. Em seguida, o zurg carrega a sua biblioteca: alguns segundos para uma conta pequena, cerca de dez minutos para uma com mil lançamentos no Real-Debrid. Abra o painel do zurg em `http://<this machine>:9999`: **Library Size** mostra a contagem dos seus itens assim que terminar.

Já tem o zurg rodando? Atualize e reinicie com `cd ~/zurg && ./zurg update && ./zurg service restart` (no Windows, `cd $HOME\zurg; .\zurg.exe update; .\zurg.exe service restart`).

## Passo 2. Instale o rex {#step-2-install-rex}

**O que ele faz.** Baixa o rex para `~/rex` (`$HOME\rex` no Windows) e o inicia como serviço, com tudo que os próximos passos precisam. Os passos seguintes não precisam de reinício; só as seções opcionais mais abaixo precisam.

**Por que isso importa.** O rex é com quem os seus apps do Plex conversam. A primeira inicialização cria o `rex.db`, que guarda suas bibliotecas, tudo que o zurg envia e seu histórico de exibição.

No Linux, você pode rodar o zurg e o rex no Docker: veja [Rodar o rex no Docker](#run-rex-in-docker).

+++ Linux and macOS
```bash
mkdir -p ~/rex && cd ~/rex
TAG=$(curl -fsSL 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1' | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
P=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -fL "https://github.com/debridmediamanager/rex/releases/download/$TAG/rex-$TAG-$P.tar.gz" | tar xz --strip-components=1
```
+++ Windows
No PowerShell:

```powershell
New-Item -ItemType Directory -Force $HOME\rex | Out-Null; cd $HOME\rex
$tag = (Invoke-RestMethod 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1')[0].tag_name
curl.exe -fLO "https://github.com/debridmediamanager/rex/releases/download/$tag/rex-$tag-windows-amd64.zip"
tar -xf "rex-$tag-windows-amd64.zip" --strip-components=1; Remove-Item "rex-$tag-windows-amd64.zip"
```
+++

Isso baixa a build mais nova do rex, normalmente uma nightly, para a sua máquina.

Descubra o IP da rede local do rex, o endereço dele na sua rede de casa. No Linux, `hostname -I` mostra vários: pegue o da sua rede de casa, não um que começa com `172.17.` (Docker) ou `100.` (Tailscale). No macOS, `ipconfig getifaddr en0` mostra (use `en1` se essa não mostrar nada). No Windows, `ipconfig` lista como **IPv4 Address** no adaptador Wi-Fi ou Ethernet. **Esta página escreve `192.168.1.20` em todo lugar: coloque o seu no lugar.** Os apps do Plex, o zurg e os seus próprios comandos falam com o rex por esse endereço.

**O Plex Media Server roda na mesma máquina?** Termine o comando de início do rex abaixo com `--port 32500` e use `32500` onde um comando ou configuração disser `32400`, incluindo a regra do firewall do Windows. O Plex já usa a porta 32400 e as portas que os apps usam para encontrar servidores; em qualquer outra porta, o rex deixa essas portas para o Plex. Assim, seus apps vão listar dois servidores com o nome da máquina: o rex é o que foi compartilhado com você, com o nome da conta nova ao lado. Quando o rex estiver na conta do Plex ([passo 3](#step-3-add-it-to-a-plex-account)), você pode renomeá-lo: entre no Plex com essa conta, abra **Settings** do rex, **General**, troque **Friendly name** e salve, depois reinicie o rex como abaixo. Os apps do Plex mostram o novo nome depois do reinício.

Agora, transforme ele em serviço:

+++ Linux
Crie `~/.config/systemd/user/rex.service`:

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/rex.service
```

```ini
[Unit]
Description=rex
After=network-online.target

[Service]
WorkingDirectory=%h/rex
EnvironmentFile=-%h/rex/rex.env
ExecStart=%h/rex/rex
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
journalctl --user -u rex -f
```

A **start command** do rex é a linha `ExecStart`, e as chaves vão em `~/rex/rex.env`, uma `NAME=value` por linha. Depois de uma mudança, `systemctl --user daemon-reload && systemctl --user restart rex` reinicia o rex. `journalctl --user -u rex -f` mostra o log.
+++ macOS
`run.sh` inicia o rex na pasta dele, e um LaunchAgent inicia o `run.sh` quando você faz login:

```bash
cp ~/rex/examples/run.sh.example ~/rex/run.sh
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.rex.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.rex</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$HOME/rex/run.sh</string></array>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$HOME/rex/rex.log</string>
  <key>StandardErrorPath</key><string>$HOME/rex/rex.log</string>
</dict></plist>
PLIST
launchctl load ~/Library/LaunchAgents/com.rex.plist
tail -F ~/rex/rex.log
```

A **start command** do rex é a última linha de `~/rex/run.sh`, e as chaves vão em `~/rex/rex.env`, uma `NAME=value` por linha. Depois de uma mudança, `launchctl kickstart -k gui/$(id -u)/com.rex` reinicia o rex. `tail -f ~/rex/rex.log` mostra o log.

O rex roda enquanto você estiver logado no Mac. Para um Mac que reinicia sozinho, ative o login automático (**System Settings**, **Users & Groups**). Se o firewall do macOS estiver ligado, permita o rex quando o macOS perguntar, ou adicione `~/rex/rex` em **Options** do firewall.
+++ Windows
Abra o PowerShell **como administrador** e vá para a pasta do rex com `cd $HOME\rex`. Primeiro crie o `run.cmd`, que inicia o rex na pasta dele e grava o log em `rex.log`. O Bloco de Notas oferece criar o arquivo:

```powershell
notepad run.cmd
```

```bat
@echo off
cd /d "%~dp0"
rex.exe 2>> rex.log
```

Salve. Depois, libere o seu rede no Firewall do Windows para a porta do rex e para as duas portas de descoberta, e inicie o rex agora e sempre que você fizer login:

```powershell
New-NetFirewallRule -DisplayName rex -Protocol TCP -LocalPort 32400
New-NetFirewallRule -DisplayName "rex discovery" -Protocol UDP -LocalPort 32410,32414
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask rex -Action (New-ScheduledTaskAction -Execute "$HOME\rex\run.cmd") -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) -Settings $settings
Start-ScheduledTask rex; Start-Sleep 3
Get-Content rex.log -Wait
```

A **start command** do rex é a linha `rex.exe` do `run.cmd`, e as chaves vão acima dela, uma `set NAME=value` por linha. Depois de uma mudança, `Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex` reinicia o rex. `Get-Content $HOME\rex\rex.log -Wait` mostra o log.

Iniciou o rex na mão no PowerShell? Então o log fica só naquela janela, sem `rex.log`, e nenhuma tarefa o inicia depois de reiniciar o PC. O rex guarda o banco de dados e a reivindicação na pasta de onde ele inicia, então um rex iniciado de outra pasta é um servidor novo e sem dono. Pare com Ctrl+C e inicie de novo a partir da pasta do rex com as mesmas flags ou, melhor ainda, configure a tarefa acima.

O rex roda enquanto você estiver logado no Windows, em uma janela própria: deixe-a aberta. No PowerShell, digite `curl.exe` onde esta página disser `curl`: o `curl` do próprio Windows PowerShell é outro comando.
+++

**O que você deve ver.** Entre as primeiras linhas:

```
INFO    seeded rex.db: an empty library named yourhost, machine=...
INFO    no source yet: a source registers itself once pointed at this server (PUT /rex/sources/{name}, docs/feed-api.md)
INFO    claim state: unclaimed
INFO    rex on http://192.168.1.20:32400  machine=...  items=0  parts=proxy
```

O rex se nomeia com o nome da máquina; seus apps do Plex mostram esse nome. `no source yet` é o esperado: o zurg ainda não foi avisado sobre o rex. Deixe o log aberto.

## Passo 3. Adicione a uma conta Plex {#step-3-add-it-to-a-plex-account}

**O que faz.** Registra o rex em uma conta do Plex, como você faria com um Plex Media Server de verdade, e compartilha com a sua própria conta.

**Por que importa.** O rex pega o nome, o pôster, a sinopse e os nomes dos episódios de cada título a partir dos metadados do próprio Plex, e só pode pedir isso depois que estiver em uma conta. Os títulos que o zurg enviou antes da vinculação recebem nome assim que ela acontece. Também faz o Fix Match funcionar, remove o aviso de "unclaimed" e é necessário antes de [usar o rex fora da sua casa](#use-it-outside-your-home-optional).

**Use uma conta nova do Plex para isso, não a sua.** O rex não é feito pelo Plex, e o Plex pode tomar alguma medida contra uma conta que registre o rex. Mantenha a sua conta principal, com o histórico de exibição, os amigos e qualquer Plex Pass, fora disso: crie uma conta gratuita nova em [plex.tv](https://www.plex.tv) com um endereço de e-mail que você não use em outro lugar, registre o rex nessa conta e compartilhe o rex com a sua conta principal. Assim você assiste logado como você mesmo, do mesmo jeito que assistiria ao servidor de um amigo. O rex não reproduz nada enquanto essa etapa não estiver concluída.

### Registre o rex na conta nova {#register-rex-on-the-fresh-account}

1. Entre no [plex.tv](https://www.plex.tv) **com a conta nova**, abra o [plex.tv/claim](https://www.plex.tv/claim) e copie o código. Ele expira em cerca de cinco minutos.
2. Na máquina do rex (`curl.exe` no Windows):

   ```bash
   curl -X POST "http://192.168.1.20:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://192.168.1.20:32400/identity
   ```

**O que você deve ver.** O segundo comando mostra `claimed="1"`, e o arquivo `claim_state.json` existe na pasta do rex. Faça backup desse arquivo: sem ele, você precisa fazer o claim de novo com um código novo. Enquanto ele existir, o rex recusa um segundo claim.

### Compartilhe com sua própria conta {#share-it-with-your-own-account}

1. Ainda logado com a conta nova, abra [app.plex.tv](https://app.plex.tv), depois **Settings** (a chave inglesa), **Manage Library Access** e **Grant Library Access**.
2. Digite o nome de usuário ou e-mail da sua própria conta, escolha o servidor rex e as duas bibliotecas, **Movies** e **TV Shows**, e envie o convite.
3. Saia da conta, entre como **você mesmo** e aceite o convite. Ele chega por e-mail e no app.plex.tv.

![Manage Library Access nas configurações do app.plex.tv, com o botão Grant Library Access](../assets/rex/20-plex-manage-library-access.webp)

![A caixa de diálogo Grant Library Access com Movies e TV Shows do servidor rex marcados](../assets/rex/21-plex-grant-library-access.webp)

**O que você deve ver.** Logado como você mesmo, os apps do Plex listam o servidor rex ao lado dos seus próprios servidores, com as duas bibliotecas, vazias até o próximo passo. O seu histórico de exibição no rex é só seu: ele fica separado do da conta nova. Compartilhe da mesma forma com qualquer outra pessoa da sua casa.

## Passo 4. Conecte o zurg ao rex {#step-4-connect-zurg-to-rex}

**O que faz.** Diz ao zurg onde o rex está. O zurg se apresenta ao rex, envia a biblioteca inteira, lê os detalhes de vídeo e áudio de cada arquivo, envia esses detalhes também e, depois, envia cada mudança conforme acontece.

**Por que importa.** Este é o único elo entre os dois. O rex não tem configuração para o zurg: se `rex_url` estiver faltando, o rex fica vazio. `rex_url` é sempre o endereço `http://` simples do rex na sua rede, nunca um endereço HTTPS de [Usar fora da sua casa](#use-it-outside-your-home-optional): o rex aceita os envios do zurg apenas das suas próprias redes ([Mantenha a porta privada](#keep-the-port-private)). Sua chave do DMM permite que o zurg pergunte ao DMM qual filme ou episódio é cada arquivo. Sem ela, o zurg descobre pelo nome, e menos títulos batem.

O zurg não inicia com a mesma chave duas vezes, e o painel do zurg grava `dmm_api_key` na configuração quando você digita sua chave ali. Sem chave do DMM, deixe `dmm_api_key` de fora.

+++ Linux e macOS
Primeiro, verifique se a configuração do zurg já tem alguma dessas linhas:

```bash
grep -n '^rex_url:\|^dmm_api_key:' ~/zurg/config.yml
```

Se ela imprimir uma linha, essa chave já está definida: altere-a lá com `nano ~/zurg/config.yml` e deixe-a de fora do `printf` abaixo.

```bash
printf '\nrex_url: http://192.168.1.20:32400\ndmm_api_key: your_dmm_key\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
Abra a configuração do zurg com `notepad $HOME\zurg\config.yml`. Se ela já tiver uma linha `rex_url:` ou `dmm_api_key:`, altere essa linha; adicione as outras no final:

```yaml
rex_url: http://192.168.1.20:32400
dmm_api_key: your_dmm_key
```

Salve e reinicie o zurg:

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++

**O que você deve ver.** Quando o zurg carregar a biblioteca de novo, o log do zurg (`~/zurg/logs/zurg.log`, no Windows `$HOME\zurg\logs\zurg.log`) vai mostrar `DMM placed N releases` (sem chave do DMM: `Placed N releases by their names (no DMM sponsor key)`), e o log do rex vai mostrar:

```
INFO    SOURCES zurg registered at http://192.168.1.20:9999/dav
INFO    SOURCES PUT /rex/sources/zurg -> 200
INFO    FEED zurg upsert: 0 created, 0 updated, 200 held, 0 unchanged, 0 rejected
INFO    FEED identified "Sintel.mp4" -> movie tmdb:45745 (placed)
INFO    FEED zurg upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

O rex lê cada arquivo do endereço na linha `registered at`, então ele precisa conseguir chegar ao zurg ali. O rex registra essa linha de novo somente quando o endereço muda.

`held` significa que o zurg ainda não leu os detalhes daquele arquivo. O zurg começa a lê-los assim que a biblioteca dele carrega, um release por vez, e os episódios de um season pack chegam juntos. Com uma chave do DMM, até cerca de 20 releases por minuto vêm dos detalhes armazenados no DMM. Uma biblioteca grande leva várias horas para encher. Cada título aparece no rex conforme os detalhes chegam. Qualquer coisa que você adicionar depois à sua conta de debrid aparece sozinha assim que o zurg a tiver lido.

**Se não**.

- Nada no log do rex: o zurg ainda está carregando a biblioteca, o zurg está desatualizado (atualize-o como no [passo 1](#step-1-install-zurg)), ou `rex_url` tem um erro de digitação. `grep 'rex feed' ~/zurg/logs/zurg.log | tail -n 5` mostra o lado do zurg (no Windows, `Select-String 'rex feed' $HOME\zurg\logs\zurg.log | Select-Object -Last 5`). Sem a linha `rex feed: pushing the library to ...`, o zurg não leu o `rex_url`. Já `rex feed: snapshot failed, retrying in ...` significa que ele não consegue chegar ao rex naquele endereço.
- Um título continua `held` e o zurg registra `Cannot probe file ...`: a primeira leitura do serviço de debrid falhou. O zurg tenta de novo sozinho, mas **Analyze & Tag Library**, em **Utilities** no painel do zurg, tenta na hora.

  ![Card Library Management do zurg na página Utilities, com Analyze & Tag Library](../assets/rex/72-zurg-analyze-tag.webp)

- Os títulos chegam, mas não aparecem linhas `identified`: o zurg não conseguiu casá-los pelo nome. Com `dmm_api_key` definida, ele registra `DMM refused the API key for placement` quando a chave não é de um patrocinador. Nesse caso, o zurg casa pelo nome e tenta a chave de novo um dia depois, ou na hora quando reiniciar.
- Os títulos aparecem, mas nada toca: o rex não consegue chegar ao zurg no endereço `registered at`. A linha `upstream failed` de [Quando algo está errado](#when-something-is-wrong) verifica isso.

Executando vários zurgs (um por serviço de debrid)? Dê a cada um um nome próprio com uma linha extra, como `rex_source: rd`, `rex_source: tb` e assim por diante. Eles preenchem as mesmas bibliotecas.

### Por que o DMM coloca os arquivos {#why-dmm-places-the-files}

DMM sabe onde cada arquivo realmente pertence. Os nomes dos arquivos muitas vezes numeram os episódios de forma diferente das listas de episódios que os apps do Plex mostram:

| Release | Nomeado | Onde ele realmente está |
|---|---|---|
| `[Erai-raws] Hibike Euphonium 3 - 01` | temporada 1, episódio 1 | Sound! Euphonium temporada 3, episódio 1 |
| `[HorribleSubs] One Piece - 486` | episódio 486 | temporada 13, episódio 486 |
| `Firefly.S01E02.The.Train.Job` (ordem de DVD) | episódio 2 | episódio 1, "The Train Job" |

Um arquivo que o zurg não consegue posicionar fica sem correspondência: um filme com o título do próprio arquivo, ou um episódio de uma série com o nome do release, numerado na ordem dos arquivos. Com uma chave do DMM, o zurg pergunta ao DMM de novo um dia depois. Você também pode corrigir na mão com **Fix Match** em um app do Plex, logado com a conta nova que é dona do rex (o rex recusa esse arquivo para as contas com as quais ele é compartilhado). Um título que você corrigiu com Fix Match continua do jeito que você definiu.

![Menu ⋯ de um filme em um app do Plex, com Fix Match nele](../assets/rex/30-plex-fix-match-menu.webp)

![A caixa de diálogo Fix Match com o resultado da busca para escolher](../assets/rex/31-plex-fix-match-results.webp)

O painel do zurg mostra o que ele fez com cada release: abra o release em **Torrent Manager** e veja **Placement**. **Place again** pede ao DMM mais uma vez, e um id do IMDb digitado em **External ID** posiciona o arquivo por esse id.

![Uma página de release no Torrent Manager do zurg, com o External ID e a seção Placement](../assets/rex/70-zurg-placement-row.webp)

## Passo 5. Assista algo {#step-5-watch-something}

**O que faz.** Abre o rex em um app do Plex, do mesmo jeito que você abriria qualquer servidor Plex.

**Por que importa.** Este é o ponto de toda a configuração. Também comprova o último elo: o rex lendo um arquivo do zurg enquanto você assiste.

Abra um app do Plex (não um navegador) em um celular, TV ou computador **na mesma rede doméstica**. O rex aparece com o nome da máquina, com **Movies** e **TV Shows**. Escolha um filme e aperte play.

![Um app do Plex mostrando as bibliotecas Movies e TV Shows do servidor rex na barra lateral, ao lado de uma grade de filmes](../assets/rex/10-plex-server-libraries.webp)

Em casa, não é preciso mais nada: os apps do Plex encontram o rex pela descoberta local do próprio Plex e se conectam a ele pela sua rede. Para isso, o dispositivo precisa estar na mesma rede que o rex (não em uma rede de visitantes nem em uma VLAN separada). A descoberta usa as portas UDP 32410 e 32414, então um firewall na máquina do rex precisa liberá-las (no Windows, as regras de firewall do passo 2 já fazem isso). O rex responde à descoberta quando usa a porta 32400. Se você mudou o rex para a 32500 porque o Plex roda na mesma máquina, a descoberta fica com o Plex, e os apps encontram o rex pela conta do Plex com a qual ele está [compartilhado](#share-it-with-your-own-account). O app.plex.tv em um navegador também funciona em casa, pelo endereço HTTPS que o [rex-direct](#rex-direct) dá ao rex depois que ele é reivindicado (rex nightly 2026.11.02 ou mais novo). Na primeira vez, o Chrome pergunta se o app.plex.tv pode acessar dispositivos da sua rede local: permita. `http://192.168.1.20:32400/web` não é o Plex Web: o rex não tem app web próprio, e essa página só informa se o rex foi reivindicado e onde assistir.

**O que você deve ver.** Pôsteres, títulos e anos como em qualquer servidor Plex, e o filme toca.

Duas coisas que você pode encontrar:

- **"yourhost server is unclaimed and not secure".** Um app do Plex diz isso sobre qualquer servidor que não está em uma conta Plex, e o rex não reproduz nada até que ele esteja em uma. Faça o [passo 3](#step-3-add-it-to-a-plex-account). Não aperte **Claim it now** enquanto estiver logado como você mesmo: isso registra o rex na sua própria conta.
- **"This server is not powerful enough to convert video".** Se todos os títulos falham em todos os dispositivos, olhe o log do rex logo depois que você aperta Play: `upstream failed` ou `502` ali significam que o rex não consegue alcançar o zurg, e o FFmpeg não resolve isso. A linha `upstream failed` de [Quando algo dá errado](#when-something-is-wrong) diz o que fazer. Se só alguns arquivos falham, muitas vezes só em um navegador, o dispositivo não consegue reproduzi-los como estão, em geral por causa de som AC3 ou DTS. Os apps do Plex em TVs e celulares reproduzem a maioria dos arquivos sem conversão. Para reproduzir tudo em todos os lugares, configure a [Conversão de vídeo](#converting-video-optional).

As pastas do zurg além de `movies` e `shows`, como `anime`, não precisam de nada: cada arquivo vai para **Movies** ou **TV Shows** conforme o que o zurg diz que ele é. Um arquivo que o zurg não consegue identificar como episódio fica em **Movies**.

Para dar a uma dessas pastas bibliotecas próprias, adicione `rex_movies` abaixo dela no `config.yml` do zurg para uma pasta de filmes, `rex_shows` para uma pasta de séries, e os dois somente quando ela tiver ambos, ao lado de seus filtros, e depois reinicie o zurg como no [passo 4](#step-4-connect-zurg-to-rex). Cada um cria uma biblioteca, mesmo vazia: uma pasta de filmes com `rex_shows` gera uma biblioteca de TV vazia. O DMM coloca parte dos arquivos de uma pasta como filmes e parte como episódios, e o tipo sem título próprio vai para **Movies** ou **TV Shows**:

```yaml
directories:
  anime:
    rex_shows: Anime
    rex_movies: Anime Movies
  films:
    rex_movies: Films
```

Quando o zurg carregar, o rex cria **Anime**, **Anime Movies** e **Films** e move para elas o que já estava exibindo vindo de `anime`, do jeito que estava: histórico de exibição, Fix Match e edições incluídos. Um Plex Web aberto lista essas bibliotecas de imediato em **More** na barra lateral, onde você pode fixá-las. Compartilhe-as com a sua conta como no [passo 3](#share-it-with-your-own-account). Renomeie-as em um app do Plex como quiser. Se você apagar uma, ela continua apagada, e seus arquivos voltam para **Movies** ou **TV Shows**, até que você a adicione de novo com **Add Library**, cuja lista de pastas mostra as pastas do zurg. Se você tirar `rex_shows` ou `rex_movies` da configuração do zurg depois, a biblioteca que o rex criou para ela fica, vazia ou não: apague-a em um app do Plex, logado com a conta nova. Se uma biblioteca não aparecer, o log do zurg ou o do rex diz por quê.

![Seletor de pastas do Add Library listando as pastas da fonte anime, kids e movies](../assets/rex/14-plex-add-library-folders.webp)

!!!warning Apagar em um app do Plex apaga da sua conta debrid
Logado com a conta nova, **Delete** em um filme ou episódio também apaga o arquivo no zurg, e o zurg remove o torrent da sua conta debrid assim que nenhum dos arquivos dele sobrar. As contas com as quais o rex está compartilhado, a sua inclusive, não podem apagar. Para desligar a exclusão: no app.plex.tv, logado com a conta nova, abra **Settings**, a **Library** do servidor rex, **Show Advanced**, desmarque **Allow media deletion** e salve. O rex então recusa todas as exclusões.
!!!

![As configurações de Library do servidor rex com Show Advanced aberto e Allow media deletion destacado](../assets/rex/32-plex-allow-media-deletion.webp)

Um título que sai da sua conta debrid pelo outro lado, removido lá ou pelo zurg, vai para a lixeira da biblioteca no rex, como faria no Plex: ele fica, indisponível, com seu histórico de exibição, e volta como estava se o zurg o tiver de novo. **Empty Trash** na biblioteca o remove para sempre, e **Empty trash automatically after every scan** (Settings, Library) faz isso sozinho; essa opção vem desligada.

**Faça backup** do `rex.db` na pasta do rex (ele guarda sua biblioteca, seu histórico de exibição e o login do zurg, então mantenha-o privado) e, depois que existirem, do `claim_state.json` e do `rex-direct.json` (a reivindicação e a chave do certificado do rex-direct):

+++ Linux e macOS
```bash
sudo apt install -y sqlite3    # once, on Linux; macOS has it
mkdir -p ~/rex-backup
sqlite3 ~/rex/rex.db ".backup $HOME/rex-backup/rex.db"
cp ~/rex/*.json ~/rex-backup/
```
+++ Windows
O Windows não tem `sqlite3`, então pare o rex por um momento e copie o `rex.db` junto com os dois arquivos ao lado dele que começam do mesmo jeito:

```powershell
Stop-Process -Name rex; Start-Sleep 1
New-Item -ItemType Directory -Force $HOME\rex-backup | Out-Null
Copy-Item $HOME\rex\rex.db*, $HOME\rex\*.json $HOME\rex-backup
Start-ScheduledTask rex
```
+++

No Docker, os arquivos ficam em `~/rex/config`, legíveis apenas pelo root. Faça o backup de dentro do container com `docker exec rex sqlite3 /config/rex.db ".backup /config/rex.db.bak"`, depois `mkdir -p ~/rex-backup && sudo cp ~/rex/config/rex.db.bak ~/rex/config/*.json ~/rex-backup/`.

[Restaurar um backup](#restore-a-backup) os devolve ao lugar.

Pronto, você terminou. As seções abaixo são opcionais.

## Use fora da sua casa (opcional) {#use-it-outside-your-home-optional}

**O que faz.** Dá ao rex um endereço HTTPS que os apps do Plex fora de casa conseguem acessar, e informa o plex.tv sobre ele.

**Por que importa.** Fora de casa, o app.plex.tv só se conecta a um endereço HTTPS, e os outros apps do Plex dão preferência a esse tipo. Um servidor Plex de verdade pode recorrer ao relay do Plex; o rex não consegue, então você escolhe como ele será acessado. O rex precisa ser [claimed](#step-3-add-it-to-a-plex-account) primeiro, e um proxy voltado para a internet precisa bloquear `/rex/` ([Keep the port private](#keep-the-port-private)).

**Plex Pass.** O Plex Web reproduz fora de casa sem um Plex Pass ou Remote Watch Pass em nenhuma das contas. Os outros apps do Plex não foram testados fora de casa.

Seja qual for a opção escolhida, cada byte que você assistir fora de casa sai pela velocidade de **upload** da sua conexão de casa. Um upload de 20 Mbit/s aguenta bem um 1080p WEB-DL, mas não um remux.

### Qual usar {#which-one-to-use}

| Sua situação | Use | Por quê |
|---|---|---|
| Seu roteador tem IP público e você consegue fazer port forward | **[rex-direct](#rex-direct)** (o mais simples) | Ativado por padrão: um único port forward. O DMM dá um nome e um certificado para o rex e mantém o nome apontado para o seu IP residencial |
| Você consegue instalar o Tailscale nos dispositivos em que assiste | **[Tailscale serve](#tailscale-serve)** (o melhor) | Nada para abrir no roteador, e funciona atrás de qualquer conexão de internet. O certificado se renova sozinho, e ninguém fora da sua tailnet consegue acessar o rex |
| Dispositivos sem Tailscale (a TV de um amigo, um hotel), e seu roteador tem IP público | **[Caddy](#caddy)** com seu próprio domínio, ou com um nome `sslip.io` gratuito | Uma conexão direta, sem ninguém no meio, e um certificado gratuito que se renova sozinho. Você faz port forward da porta 443 |
| Sua conexão não tem IPv4 público (CGNAT ou DS-Lite, comum em provedores de cabo, móvel e algumas fibras) mas tem IPv6 | **[rex-direct over IPv6](#rex-direct-over-ipv6)** | Sem port forward e sem nada para alugar: você libera a porta 32400 no IPv6. Os dispositivos em que você assiste também precisam de IPv6, o que a maioria das redes móveis oferece |
| Sua conexão não tem IP público, ou você assiste em redes sem IPv6, e dispositivos sem Tailscale | **[Um VPS pequeno](#a-small-vps)** | O rex não tem relay e não vai ter um. Um VPS alugado tem o IP público e um túnel leva tudo até o rex, com a largura de banda total do VPS |

Não recomendado:

- **Túnel da Cloudflare.** Cada byte passa pela Cloudflare, que também descarta o `Range` da primeira leitura de um arquivo, então cada início de reprodução baixa o arquivo inteiro do seu serviço de debrid.
- **Tailscale Funnel, ngrok e outros túneis hospedados.** Eles limitam a largura de banda ou o volume mensal de dados, que um filme consome rapidamente. O Tailscale Funnel também publica todo o rex, inclusive a API para a qual o zurg envia dados: qualquer pessoa na internet poderia adicionar ou apagar itens dessa biblioteca.
- **Liberar a porta 32400 sem rex-direct ou sem um certificado próprio.** Os apps do Plex receberiam um endereço HTTP simples, que o app.plex.tv recusa.

### rex-direct

rex-direct é a resposta do DMM para o plex.direct, e vem ativado por padrão. No seu roteador, encaminhe a porta 32400 (TCP) para a máquina do rex. É só isso, sem precisar reiniciar nada.

Depois de reivindicado, o rex recebe dois nomes do DMM: `<hash>.rex-direct.debridmediamanager.com`, apontando para o IP público da sua casa, e `lan.<hash>.rex-direct.debridmediamanager.com`, apontando para o IP da LAN do rex, com um certificado para os dois. O primeiro certificado leva alguns minutos; o log do rex avisa que ele está sendo emitido e depois mostra cada nome em uma linha `rex-direct:`. Um novo IP de casa e as renovações de certificado são detectados automaticamente. Uma conta do Plex pode ter até dez nomes rex-direct. Em casa, os apps do Plex, inclusive o app.plex.tv, podem usar o nome `lan.`, que chega ao rex direto pela sua rede, então o encaminhamento de porta só é necessário para quando você estiver fora de casa. No app.plex.tv, permita o acesso a dispositivos na sua rede local quando o Chrome perguntar; caso contrário, ele usa o nome público, que precisa do encaminhamento de porta. [O que você deve ver](#what-you-should-see) verifica os dois nomes.

Se o seu roteador encaminhar uma porta externa diferente para o rex, adicione a chave `REX_DIRECT_PORT=<that port>` como mostra o [passo 2](#step-2-install-rex) para o seu sistema e reinicie o rex. O encaminhamento de porta não abre a API que o zurg envia: veja [Mantenha a porta privada](#keep-the-port-private).

### rex-direct sobre IPv6 {#rex-direct-over-ipv6}

Para uma conexão sem IPv4 público (CGNAT ou DS-Lite) que tenha IPv6. Quando o DMM se conectar ao rex pelo endereço IPv6 e encontrar o mesmo servidor ali, ele também aponta o nome rex-direct do rex para esse endereço. Você precisa do rex nightly 2026.11.08 ou mais recente e, no Docker, do modo de rede host.

O IPv6 não tem port forward nem port mapping: o rex precisa usar a mesma porta por dentro e por fora, então deixe `REX_DIRECT_PORT` sem definir. No firewall do seu roteador, permita conexões TCP de entrada na porta 32400 para a máquina do rex pelo IPv6. O rex publica o seu IPv6 um minuto depois de iniciar (ou de ser reivindicado) e, depois, a cada 6 horas. Por isso, adicione a regra antes de iniciar o rex, ou reinicie o rex depois de adicioná-la. Um minuto depois, mais ou menos, o log dele mostra os dois endereços:

```
rex-direct: https://<hash>.rex-direct.debridmediamanager.com:32400 -> <IPv4> and <IPv6>
```

Se nenhuma linha com `and <IPv6>` aparecer em alguns minutos, o DMM não conseguiu alcançar o rex por IPv6. Verifique a regra do firewall e se o rex no Docker está usando o modo de rede host. No Windows, o rex publica o endereço IPv6 temporário do Windows, que o sistema troca cerca de uma vez por dia. Para desligar os endereços temporários, rode `netsh interface ipv6 set privacy state=disabled` em um PowerShell como administrador e depois reinicie o rex para que ele publique o endereço estável. O `<IPv4>` dessa linha é o endereço compartilhado da sua operadora e não alcança o rex, então os dispositivos de onde você assiste também precisam de IPv6. A maioria das redes móveis tem IPv6. Uma rede de hotel ou de escritório só com IPv4 não consegue alcançar o rex dessa forma.

### Tailscale serve

Instale o [Tailscale](https://tailscale.com/download) na máquina do rex e nos dispositivos em que você assiste, entrando na mesma conta. Depois, na máquina do rex:

```bash
sudo tailscale serve --bg 32400
```

No Windows, execute no PowerShell como administrador, sem `sudo`. No macOS, use a [ferramenta de linha de comando](https://tailscale.com/kb/1080/cli) do app do Tailscale, sem `sudo`.

Ele mostra o endereço, por exemplo `https://myhost.tailnet.ts.net`. Informe-o ao rex com `:443` no final: acrescente `--announce-url https://myhost.tailnet.ts.net:443` ao final do comando de inicialização do rex do [passo 2](#step-2-install-rex) e reinicie o rex.

O Tailscale conecta seus dispositivos entre si diretamente, então o stream não passa pelos servidores do Tailscale, exceto em redes que bloqueiam isso.

### Caddy

Você precisa encaminhar a porta 443 do seu roteador para a máquina do rex, e também de um nome para o IP da sua casa:

- **Seu próprio domínio:** um registro `A`, como `rex.example.com`, apontando para o IP da sua casa.
- **Sem domínio:** use `1-2-3-4.sslip.io` com os números do seu IP público (`curl -s ifconfig.me` mostra ele). Ele sempre resolve para esse IP. Se o seu IP mudar, atualize o nome.

Instale o [Caddy](https://caddyserver.com/docs/install) e dê a ele este Caddyfile (`/etc/caddy/Caddyfile` com o pacote do Caddy para Linux; no macOS e no Windows, um arquivo chamado `Caddyfile` em uma pasta só dele, que o `caddy run` lê dentro dessa pasta):

```
rex.example.com {
	respond /rex/* 403
	reverse_proxy 192.168.1.20:32400
}
```

`respond /rex/* 403` mantém fora da internet a API para onde o zurg envia dados. O zurg ainda acessa ela em `http://192.168.1.20:32400`. Depois, recarregue o Caddy (`sudo systemctl reload caddy` com o pacote para Linux). No macOS e no Windows, em vez disso, inicie o `caddy run` na pasta dele e deixe rodando do jeito que o [passo 2](#step-2-install-rex) deixa o rex rodando; no Windows, também libere a porta TCP 443 no firewall, como o passo 2 faz para a 32400.

O Caddy busca um certificado quando carrega o arquivo e o renova sozinho. Termine o comando de início do rex com `--announce-url https://rex.example.com:443` e reinicie o rex.

### Um VPS pequeno {#a-small-vps}

Para uma conexão sem IP público nenhum, ou quando você assiste em redes sem IPv6: o VPS passa a carregar todos os streams, no lugar do [rex-direct sobre IPv6](#rex-direct-over-ipv6). O rex não tem relay e não vai ganhar um, então um servidor alugado faz o papel do seu roteador: ele tem o IP público, e um túnel a partir da máquina do rex leva tudo até o rex. Qualquer VPS com IPv4 público funciona, por alguns euros por mês. **Escolha um cujo tráfego mensal cubra o que você assiste fora de casa:** cada byte passa por ele, e um plano com limite de dados baixo vai acabar.

Você precisa do IP do VPS (`1.2.3.4` abaixo), das portas 443, 80 e 7000 abertas nele, e de uma string aleatória longa para o túnel (`openssl rand -hex 32`).

**No VPS**, instale o [frp](https://github.com/fatedier/frp/releases) (o programa `frps`) e o [Caddy](https://caddyserver.com/docs/install). Crie o `frps.toml`:

```toml
bindPort = 7000
auth.token = "your-long-random-string"
proxyBindAddr = "127.0.0.1"
```

`proxyBindAddr` mantém a ponta do túnel no loopback do VPS, então a internet só chega ao rex através do Caddy. Crie o `/etc/caddy/Caddyfile`, usando o IP do VPS como `1-2-3-4.sslip.io` (um nome gratuito que sempre aponta para esse IP) ou o seu próprio domínio apontando para ele:

```
1-2-3-4.sslip.io {
	respond /rex/* 403
	reverse_proxy 127.0.0.1:32400
}
```

`respond /rex/* 403` impede que a API para a qual o zurg envia dados fique acessível pela internet. Inicie `frps -c frps.toml` como um serviço e execute `sudo systemctl reload caddy`.

**Na máquina do rex**, instale também o frp (o programa `frpc`) e crie o `frpc.toml`:

```toml
serverAddr = "1.2.3.4"
serverPort = 7000
auth.token = "your-long-random-string"

[[proxies]]
name = "rex"
type = "tcp"
localIP = "192.168.1.20"
localPort = 32400
remotePort = 32400
```

Rode como serviço: no Linux, por exemplo, `~/.config/systemd/user/frpc.service` com `ExecStart=%h/frp/frpc -c %h/frp/frpc.toml` e `Restart=always`; no macOS e no Windows, inicie `frpc -c frpc.toml` do mesmo jeito que o [passo 2](#step-2-install-rex) inicia o rex. Depois, termine o comando de início do rex com `--announce-url https://1-2-3-4.sslip.io:443`, adicione a chave `REX_DIRECT_URL=off` (atrás de CGNAT, o IPv4 do nome rex-direct não alcança o rex, então o plex.tv não deve listá-lo) e reinicie o rex. Com isso, o app.plex.tv em casa também passa pelo VPS; os outros apps do Plex em casa continuam se conectando ao rex diretamente.

### O que você deve ver {#what-you-should-see}

```bash
curl -s https://lan.<hash>.rex-direct.debridmediamanager.com:32400/identity
```

mostra uma página XML curta com o `machineIdentifier` do rex em um computador em casa; o `curl` não mostra nada quando o endereço ou o certificado dele está errado. Use o seu próprio endereço: o rex registra ele na inicialização como `rex-direct: https://lan.<hash>.rex-direct.debridmediamanager.com:32400 -> 192.168.1.20 (LAN)` (com `REX_DIRECT_URL=off` não aparece nenhuma linha). Abra o seu endereço externo com `/identity` no final, no navegador de um celular com o Wi-Fi desligado: com o rex-direct, use a outra linha `rex-direct:` que o rex mostra; com o Tailscale serve, use `https://myhost.tailnet.ts.net`, que o celular só abre com o Tailscale ligado. Ela mostra uma página XML curta, sem aviso de certificado.

Se o celular falhar, a porta não está encaminhada (ou, [em IPv6](#rex-direct-over-ipv6), não está liberada), a sua conexão está atrás de CGNAT sem IPv6, o rex só é alcançado por IPv6 e a rede do celular não tem IPv6, ou o certificado do rex-direct ainda está sendo emitido (o log do rex avisa quando isso acontece).

O log do rex mostra os endereços que ele anuncia:

```
INFO    heartbeat every 600s for machine ... -> https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

O rex imprime isso a cada inicialização. Problemas aparecem depois como `heartbeat failed` ou `announced but NOT visible`. Caso contrário, o servidor lista esses endereços no plex.tv, e o app do Plex fora de casa escolhe o que conseguir alcançar. Se o rex registrar `waiting for a claim`, faça antes o [passo 3](#step-3-add-it-to-a-plex-account).

## Seu histórico de exibição de outro servidor Plex (opcional) {#your-watch-history-from-another-plex-server-optional}

Já assistiu no outro servidor Plex antes? Depois que sua biblioteca estiver no rex, [Traga seu histórico de exibição](import-watched.md) copia o que você assistiu, onde parou e suas avaliações com estrelas de lá, para cada pessoa separadamente.

## Sonarr, Radarr e Bazarr (opcional) {#sonarr-radarr-and-bazarr-optional}

rex não precisa de mount, mas Sonarr e Radarr precisam: eles importam para o mount do zurg, em `__magic__`. Configure-os com o zurg seguindo [Sonarr e Radarr para torrents](../zurg/guides/sonarr-radarr-torrents.md) ou [para Usenet](../zurg/guides/sonarr-radarr.md); o que eles baixam chega ao rex pelo zurg, como qualquer outro conteúdo. As legendas que o Bazarr salva junto a essas importações aparecem no rex em cerca de um minuto: [Legendas com Bazarr](../zurg/guides/subtitles.md). Um único zurg pode reunir sua conta de debrid e seu Usenet em uma só biblioteca ([Usenet](../zurg/guides/usenet.md)), e duas cópias de um mesmo filme são um único título no rex, com uma versão para cada uma.

## Convertendo vídeo (opcional) {#converting-video-optional}

**O que faz.** Faz o rex converter o que um dispositivo não consegue reproduzir, do mesmo jeito que o Plex faz.

**Por que importa.** Sem ele, um dispositivo que não consegue reproduzir um arquivo como ele está mostra "This server is not powerful enough to convert video". Navegadores são os que mais dão esse erro, por exemplo com som AC3 ou DTS. Quando todos os títulos falham em todos os dispositivos, a causa é outra: veja o [passo 5](#step-5-watch-something).

Instale o **jellyfin-ffmpeg** 8, e não o `ffmpeg` que vem no seu sistema. Ele é a versão com a qual o rex é medido e é o único que converte todos os arquivos Dolby Vision, faz tonemapping de HDR na placa de vídeo e desenha as legendas por lá. Outro FFmpeg converte vídeo comum, e o log do rex diz o que falta nele (o do próprio Ubuntu 22.04 também erra o ponto de busca em alguns segundos). O rex encontra o pacote sozinho.

+++ Linux
O pacote vai para `/usr/lib/jellyfin-ffmpeg`, ao lado de qualquer outro FFmpeg. A primeira linha escolhe a versão certa para o seu sistema: existem builds para Ubuntu 22.04, 24.04 e 26.04 e Debian 12 e 13, em amd64 ou arm64. Em qualquer outro sistema, o `curl` para com um erro.

```bash
DEB=jellyfin-ffmpeg8_8.1.3-1-$(. /etc/os-release; echo "$VERSION_CODENAME")_$(dpkg --print-architecture).deb
curl -fLO "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/$DEB"
sudo apt install -y "./$DEB" && rm "$DEB"
systemctl --user restart rex
```

Em outro Linux, extraia o build portátil do jellyfin-ffmpeg em `~/rex/ffmpeg`, onde o rex procura, e reinicie o rex. Ele usa o driver de vídeo do seu próprio sistema, então em um sistema mais antigo ele converte só no processador. Use o pacote sempre que houver um para a sua distro.

```bash
B=$( [ "$(uname -m)" = aarch64 ] && echo linuxarm64 || echo linux64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
```

Com uma placa de vídeo Intel ou AMD, rode também `sudo usermod -aG render "$USER"` e reinicie a máquina para que o serviço pegue o grupo. Em um LXC, passe a GPU para dentro dele. A placa deixa a conversão rápida; sem ela, o rex usa o processador. Sem chip Intel ou AMD, o rex também tenta o encoder de uma placa NVIDIA. Na Intel, `sudo apt install intel-opencl-icd` também faz a conversão de HDR e Dolby Vision na placa, em tempo quase real para 4K em uma Intel pequena. Sem ele, esses arquivos são convertidos no processador, e uma Intel de baixo consumo não dá conta disso em tempo real em 4K.
+++ macOS
O build portátil vai para `~/rex/ffmpeg`, onde o rex procura:

```bash
B=$( [ "$(uname -m)" = arm64 ] && echo macarm64 || echo mac64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
launchctl kickstart -k gui/$(id -u)/com.rex
```

Em um Mac, o rex sempre converte no processador: ele não tem como usar a placa de vídeo do Mac.
+++ Windows
O build portátil vai para uma pasta `ffmpeg` dentro da pasta do rex, onde ele procura:

```powershell
cd $HOME\rex
curl.exe -fLO https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Expand-Archive jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip ffmpeg
Remove-Item jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex
```

No Windows, o rex converte no encoder de uma placa NVIDIA quando ela existe, e no processador caso contrário.
+++

**O que você deve ver.** O log do rex tem uma linha `transcoder:` com o nome do FFmpeg e o hardware que ele encontrou (`hardware none` quer dizer processador). `transcoder off` no início quer dizer que ele não encontrou nenhum. Um arquivo que falhava antes agora toca, e o log mostra o que foi convertido, por exemplo `video=copy h264 audio=ac3->aac 6ch`.

Legendas em um arquivo convertido: uma legenda de imagem é queimada na imagem, e uma legenda que você enviou vem junto. O Plex para Android e iOS também mantém uma legenda de texto como faixa; nos outros apps ela é desenhada na imagem. Downloads offline convertidos continuam sem as legendas de texto.

## Legendas {#subtitles}

**O que faz.** Search Subtitles em um app do Plex encontra legendas do provedor próprio do Plex depois que o rex é reivindicado. O rex verifica a que você escolher contra o arquivo e corrige o tempo dela quando ela está atrasada ou foi feita para outra taxa de quadros. Quando sua conta do Plex está configurada para mostrar legendas e um título não tem nenhuma no seu idioma, o rex procura uma por até 3 segundos antes de começar.

**Por que importa.** O primeiro resultado do próprio Plex costuma estar fora de sincronia com o arquivo.

![A caixa de diálogo Subtitles search em um app do Plex, listando resultados em inglês para Sintel](../assets/rex/51-plex-search-subtitles.webp)

Não há nada para configurar. O rex verifica uma legenda contra o texto de legenda do próprio arquivo, quando ele tem um. Um arquivo sem esse texto é verificado pelo som dele quando você aperta play, o que exige que [Converting video](#converting-video-optional) esteja configurado e lê seis pedaços de 90 segundos do arquivo.

**O que você deve ver.** O log do rex tem uma linha `SUBTITLE measured` para cada legenda que ele verifica, e `SUBTITLE applied ... corrected by` quando ele corrigiu uma.

## Recursos de filmes e séries {#movie-and-tv-capabilities}

Downloads, skip de intro e dos créditos, miniaturas da barra de progresso e as outras configurações do servidor estão no [guia de configuração do rex](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities). Música e TV ao vivo vêm de fontes que as enviam ([limites do rex](https://github.com/debridmediamanager/rex#limits)), como o [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) para canais ao vivo. Não há DVR, então nada é gravado. Fotos vêm só de uma fonte que envie imagens: o zurg envia quadrinhos de uma pasta com [`rex_photos`](../zurg/reference/config.md#directory-options). O Plex Web mostra essas fotos; o Plex para Android não mostra biblioteca de fotos.

Mantenha o modo proxy padrão para reprodução compartilhada do debrid. O Real-Debrid registra o IP público de cada downloader; usar vários IPs com uma mesma conta gera um aviso de compartilhamento, mesmo quando os downloads funcionam. As URLs de download do TorBox contêm a chave de API completa, então redirecionar dá acesso a todos os clientes e contas de usuário compartilhadas, inclusive para excluir arquivos. Leia os [riscos do redirecionamento e a configuração](direct-download.md#before-you-start) antes de deixar os apps baixarem direto do provedor.

## Execute o rex no Docker {#run-rex-in-docker}

A mesma configuração com zurg e rex em contêineres em uma única máquina Linux. Os passos são os mesmos de cima; só muda a forma de iniciar cada parte. No macOS e no Windows, o Docker Desktop executa os contêineres dentro de uma máquina virtual, então o host networking, a descoberta na LAN e a placa de vídeo não funcionam ali como no Linux, e o rex não consegue acessar o zurg nesses sistemas ([passo 1](#step-1-install-zurg)): use os passos de cima.

### D1. Instale o zurg no Docker {#d1-install-zurg-in-docker}

**O que faz.** Roda o zurg em um contêiner cujo mount aparece na máquina em `/zurg_mnt/zurg`.

**Por que importa.** Como no passo 1, tudo que o rex mostra vem do zurg.

Siga a [configuração do zurg com Docker](../zurg/setup/docker.md). O instalador de uma linha de comando lá faz tudo, e pode antes pedir que você aprove os escopos `read:packages` e `repo` para o seu login no GitHub, com um código de uso único no navegador. Os passos manuais da mesma página fazem o mesmo trabalho na mão.

**O que você deve ver.** `docker compose exec zurg /app/zurg doctor --working-dir /config` termina com linhas `PASS` (`WARN service zurg is not installed` é esperado: o Docker reinicia o zurg, não o systemd), e

```bash
ls /zurg_mnt/zurg/movies /zurg_mnt/zurg/shows
```

lista a sua biblioteca.

Já roda o zurg no Docker? Atualize: `cd ~/zurg && docker compose pull zurg && docker compose up -d zurg`. Se `ZURG_TAG` em `~/zurg/.env` tiver uma build com data, troque para `latest` antes.

### D2. Inicie o rex no Docker {#d2-start-rex-in-docker}

**O que faz.** Roda o rex a partir da sua imagem, guardando tudo o que ele salva em uma pasta ao lado do arquivo compose.

**Por que importa.** É o [passo 2](#step-2-install-rex) em um arquivo só: a imagem é o programa, e o Docker o mantém rodando.

Se `docker ps` mostrar permission denied, coloque `sudo` antes de cada comando `docker` desta página.

Crie uma pasta, por exemplo `~/rex`, com este `compose.yml`:

```yaml
services:
  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./config:/config
```

- `network_mode: host` permite que os apps do Plex na sua rede encontrem o rex sozinhos, e também que o rex alcance o contêiner do zurg.
- Placa de vídeo Intel ou AMD? Adicione `devices: ["/dev/dri:/dev/dri"]` para que o rex converta vídeo por ela.
- `./config` recebe o `rex.db` e, depois, o `claim_state.json`. Só o root consegue ler esses arquivos, porque o `rex.db` guarda o login do zurg.
- Plex Media Server na mesma máquina? Adicione `command: --port 32500` e use `32500` em todo lugar onde um comando ou configuração diz `32400`.

```bash
docker compose up -d
docker compose logs -f rex
```

**O que você deve ver.** As mesmas linhas do [passo 2](#step-2-install-rex), com `seeded /config/rex.db` e `no source yet`. Deixe o log aberto.

### D3. Adicione a uma conta do Plex {#d3-add-it-to-a-plex-account}

**O que faz.** [Passo 3](#step-3-add-it-to-a-plex-account) para o container, feito antes do zurg enviar qualquer coisa para que os títulos cheguem com seus pôsteres.

Siga o passo 3: seus comandos `curl` funcionam como estão nesta máquina. `claim_state.json` aparece em `~/rex/config`.

### D4. Conecte o zurg ao rex {#d4-connect-zurg-to-rex}

**O que faz.** Igual ao [passo 4](#step-4-connect-zurg-to-rex). A config do zurg fica na pasta do compose do zurg e pertence ao root. Verifique primeiro, como no passo 4:

```bash
cd ~/zurg
sudo grep -n '^rex_url:\|^dmm_api_key:' config.yml
```

Se imprimir alguma linha, mude essa chave ali com `sudo nano config.yml` e deixe ela fora do `printf`. Depois:

```bash
printf '\nrex_url: http://192.168.1.20:32400\ndmm_api_key: your_dmm_key\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```

**O que você deve ver.** `SOURCES PUT /rex/sources/zurg -> 200` no log do rex, e `curl -s http://192.168.1.20:32400/rex/sources` mostra o zurg no endereço do **container**, por exemplo `http://172.18.0.2:9999/dav`. No Linux isso está certo: o rex roda na mesma máquina e alcança o container por ali.

**zurg e rex em máquinas diferentes?** O rex não consegue alcançar esse endereço do container. Coloque `network_mode: host` no container do zurg (e remova as linhas `ports:`) para que ele registre o IP da LAN da máquina.

### D5. Assista {#d5-watch}

rex mostra no log o nome de cada título como o zurg o lê, como em [passo 4](#step-4-connect-zurg-to-rex). Abra um app do Plex na sua rede, como no [passo 5](#step-5-watch-something).

**O que você deve ver.** Os títulos aparecem em **Movies** e **TV Shows**, e `docker compose restart rex` os traz de volta com `state file /config/rex.db: restored` e `source zurg: registered`.

### D6. Atualize {#d6-update}

```bash
cd ~/rex && docker compose pull && docker compose up -d
```

O rex volta com a mesma biblioteca. Para o zurg, veja [Gerenciando e atualizando o zurg](../zurg/setup/docker.md#managing-and-updating-zurg).

A imagem traz o jellyfin-ffmpeg, então [convertendo vídeo](#converting-video-optional) só precisa que o chip de vídeo seja repassado. O HTTPS funciona como acima: Tailscale, Caddy e frp rodam na própria máquina, e `--announce-url ...` vai no `command:` do arquivo compose.

## Mantenha a porta privada {#keep-the-port-private}

rex-direct, a API de feed do rex, que o zurg envia dados, não pede senha. Ela só responde a partir desta máquina, da sua rede doméstica e do Tailscale, então encaminhar a porta do rex para o [rex-direct](#rex-direct), ou deixar entrar por IPv6, não a deixa aberta. Um roteador que dá aos visitantes de fora o próprio endereço faz eles parecerem locais, e isso abre o feed para a internet. Um proxy na máquina do rex parece local para o rex, então mantenha `/rex/*` bloqueado em qualquer proxy voltado para a internet, como faz o exemplo do [Caddy](#caddy).

## Atualizando {#updating}

- **zurg:** como no [passo 1](#step-1-install-zurg).
- **rex:** o rex nunca se atualiza sozinho. Execute de novo o bloco de download do [passo 2](#step-2-install-rex) (ele substitui o programa e a pasta `data/`, e deixa o `rex.db`, suas chaves, o `claim_state.json` e o `rex-direct.json` intactos), depois reinicie o rex como o passo 2 mostra. No Windows, execute `Stop-Process -Name rex` antes do bloco de download, porque o Windows não deixa substituir um `rex.exe` em execução, e `Start-ScheduledTask rex` depois dele. Se o rex então sair com `unrecognized arguments`, apague das opções de inicialização do rex as flags que ele indicar: o rex não as usa mais.

## Depois: restaurar, mover, remover {#later-restore-move-remove}

### Restaure um backup {#restore-a-backup}

Pare o rex, apague `rex.db` e os arquivos `rex.db-wal` e `rex.db-shm` que estão ao lado dele, coloque os arquivos do seu backup na pasta do rex e inicie o rex de novo. Deixar o `rex.db-wal` antigo no lugar desfaz a restauração.

+++ Linux
```bash
systemctl --user stop rex
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
systemctl --user start rex
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
launchctl load ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
```powershell
Stop-Process -Name rex; Start-Sleep 1
Remove-Item $HOME\rex\rex.db*
Copy-Item $HOME\rex-backup\* $HOME\rex
Start-ScheduledTask rex
```
+++ Docker
```bash
cd ~/rex && docker compose down
sudo rm -f config/rex.db config/rex.db-wal config/rex.db-shm
sudo cp ~/rex-backup/rex.db.bak config/rex.db && sudo cp ~/rex-backup/*.json config/
docker compose up -d
```
+++

### Mova o rex para outra máquina {#move-rex-to-another-machine}

Faça um backup, como no [passo 5](#step-5-watch-something), e depois pare o rex na máquina antiga de vez, como faz o primeiro bloco de [Remover rex](#remove-rex). Na nova, faça o [passo 2](#step-2-install-rex), mas copie os arquivos do seu backup para a pasta do rex antes de transformá-lo em serviço. Para os seus apps do Plex, é o mesmo servidor, ainda vinculado e compartilhado. Depois:

- Coloque o novo IP da LAN no `rex_url` do zurg e reinicie o zurg ([passo 4](#step-4-connect-zurg-to-rex)).
- Mova o redirecionamento de porta do seu roteador para a nova máquina, ou a regra do firewall IPv6, antes de o rex iniciar lá. O nome rex-direct continua o mesmo e segue um novo IP público sozinho. O Tailscale serve e o Caddy são configurados de novo na nova máquina.

### Mova o rex para outra conta Plex {#move-rex-to-another-plex-account}

Se a conta com que o rex foi vinculado for perdida ou banida, ou se você quiser usar o rex em outra conta, crie uma conta nova, pare o rex, apague `claim_state.json` na pasta do rex, inicie o rex e refaça o [passo 3](#step-3-add-it-to-a-plex-account): vincular e depois compartilhar de novo com todo mundo. Se você ainda conseguir entrar na conta antiga, remova o rex por lá também: em app.plex.tv, abra **Settings**, **Authorized Devices**, filtre por **Servers** e remova o rex. Esses dois passos são todo o processo de desvincular. O rex não tem sign-out: a requisição de sign-out do Plex (`DELETE /myplex/account`) responde 200 e deixa o rex vinculado. A biblioteca, o Fix Match, as edições e o nome rex-direct continuam, e o histórico de exibição de cada pessoa volta assim que o rex for compartilhado de novo com a conta dela.

### Qual rex eu executo? {#which-rex-do-i-run}

rex não tem um comando de versão. A data da versão nightly está no nome do download (`2026.10.30.0040-nightly`), e o arquivo do programa traz a mesma data: `ls -l ~/rex/rex` (no Windows, `(Get-Item $HOME\rex\rex.exe).LastWriteTime`). A versão do Plex que os seus apps mostram não é a do rex: o rex informa de propósito a versão atual do Plex Media Server, para que os apps a tratem como atualizada, e o **Check for Updates** sempre diz que está.

### Comece do zero {#start-over}

Para preencher a biblioteca de novo a partir do zurg, mantendo o claim e os compartilhamentos: remova o zurg como fonte (`curl -s -X DELETE http://192.168.1.20:32400/rex/sources/zurg`, depois um `DELETE` no caminho `confirm` que ele responder, em até cinco minutos) e reinicie o zurg. Isso apaga o histórico de exibição do que o zurg enviou. Para começar do zero, pare o rex, apague `rex.db`, `rex.db-wal`, `rex.db-shm`, `claim_state.json` e `rex-direct.json`, inicie o rex, remova o servidor antigo da conta nova como descrito abaixo, faça o [passo 3](#step-3-add-it-to-a-plex-account) e reinicie o zurg.

### Remova o rex {#remove-rex}

Pare o rex de vez:

+++ Linux
```bash
systemctl --user disable --now rex && rm ~/.config/systemd/user/rex.service
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist && rm ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
No PowerShell como administrador:

```powershell
Unregister-ScheduledTask rex -Confirm:$false; Stop-Process -Name rex
Remove-NetFirewallRule -DisplayName rex, "rex discovery"
```
+++ Docker
```bash
cd ~/rex && docker compose down
```
+++

Depois, apague a linha `rex_url` do `config.yml` do zurg e reinicie o zurg. No app.plex.tv, com a conta nova, abra **Settings**, **Authorized Devices**, filtre por **Servers** e remova o rex. Remova o redirecionamento de porta do seu roteador (ou a regra de firewall IPv6) e apague a pasta do rex.

### Obtendo ajuda {#getting-help}

Pergunte no fórum **rex-support** do [Discord](https://discord.com/invite/7u4YjMThXP) do DMM: [Pedindo ajuda](../guides/remote-help.md) explica o que incluir, e como os patrocinadores recebem ajuda remota.

## Quando algo está errado {#when-something-is-wrong}

| O que você vê | O que fazer |
|---|---|
| `/rex/sources` continua `{"size":0}` | O zurg está desatualizado, o `rex_url` está errado, ou a biblioteca do zurg ainda está carregando. Atualize o zurg como no [passo 1](#step-1-install-zurg) e veja o final do log do zurg ([passo 4](#step-4-connect-zurg-to-rex)) |
| O log do rex mostra `held ... no media_info yet` e a biblioteca continua vazia | O zurg ainda não leu os arquivos. Espere a biblioteca do zurg carregar; se o zurg mostrar `segmentation fault`, atualize e reinicie o zurg como no [passo 1](#step-1-install-zurg) |
| Os títulos mostram nomes de arquivo e não têm pôsteres | O rex não está em uma conta do Plex: faça o [passo 3](#step-3-add-it-to-a-plex-account). Se você o reivindicou depois que o zurg enviou os títulos, eles ganham o nome certo sozinhos assim que a reivindicação for concluída |
| Um filme aparece com o nome do arquivo, ou um episódio fica em uma série com o nome do release | O zurg não conseguiu identificar. Sem `dmm_api_key`, isso é um nome que a busca de títulos não encontrou; com ela, o DMM ainda não identificou e o zurg pergunta de novo um dia depois. O painel do zurg mostra qual é o caso: a página do release em **Torrent Manager** tem uma linha **Placement** (**Unplaced**, **Not asked yet**) e o botão **Place again**, e um release não identificado pode receber o id do IMDb ali. **Fix Match** corrige manualmente |
| Um título está na série errada ou associado ao filme errado | O DMM identificou errado. Com `dmm_api_key` definida, o zurg pergunta de novo ao DMM uma vez por semana, o que ajuda quando o DMM já aprendeu melhor. Até lá, e sempre sem a chave, use **Fix Match** em um app do Plex, logado com a conta nova que é dona do rex; o rex recusa (403) para as contas com as quais ele é compartilhado |
| Todos os títulos falham em todos os dispositivos, muitas vezes com "This server is not powerful enough to convert video", e o log do rex mostra `upstream failed` ou `502` logo depois de você apertar Play (com o FFmpeg configurado, `TRANSCODE ... exited` com uma conexão recusada ou com tempo esgotado) | O rex não consegue alcançar o zurg no endereço que o zurg informou, e o FFmpeg não resolve isso. `curl -s http://192.168.1.20:32400/rex/sources` mostra esse endereço como `url` do zurg. Na máquina do rex, rode `curl -I` nele: qualquer resposta HTTP, inclusive `401`, está ok; `Failed to connect` significa que o rex não consegue alcançar o zurg ali. Um endereço `172.` é de um container. zurg no Docker Desktop no Windows ou macOS: remova e instale o zurg como no [passo 1](#step-1-install-zurg). zurg no Docker no Linux com o rex em outra máquina: dê ao container `network_mode: host` como em [D4](#d4-connect-zurg-to-rex). Versões mais novas dizem isso claramente: o rex registra `SOURCES zurg: cannot reach ... from this machine`, e o zurg registra `rex feed: rex cannot reach zurg at ...` |
| O log do rex mostra `upstream failed: no source ... configured` | O rex não tem um registro do zurg. Reinicie o zurg ([passo 4](#step-4-connect-zurg-to-rex)) para ele se registrar de novo |
| O log do rex mostra `part ... is unavailable upstream` | O zurg não tem esse arquivo agora: ele ainda está carregando a biblioteca, ou o release saiu da sua conta de debrid |
| Nada toca e o log do rex mostra `PART ... upstream 401` ou `403` | O zurg foi recusado no próprio login. Reinicie o zurg ([passo 4](#step-4-connect-zurg-to-rex)) para ele enviar ao rex o login atual |
| Só alguns arquivos falham com "This server is not powerful enough to convert video", muitas vezes só em um navegador web | O dispositivo não consegue tocar o arquivo do jeito que ele está. Tente um app do Plex em uma TV ou celular, ou configure a [Conversão de vídeo](#converting-video-optional) |
| Um arquivo Dolby Vision falha e o log do rex diz `DoVi (Profile 5) color space is not supported` | O rex não tem FFmpeg, ou tem um que não é o jellyfin-ffmpeg. Instale o jellyfin-ffmpeg como mostra [Conversão de vídeo](#converting-video-optional) e mantenha **Enable HDR tone mapping** ativado (Settings, Transcoder) |
| O rex sai com `cannot bind ...:32400 (another rex or Plex on this port? ...)` | Outro programa está usando a porta. Plex Media Server nesta máquina: use `--port 32500` como diz o [passo 2](#step-2-install-rex). Outro rex, como um que você iniciou manualmente: pare esse |
| Um dispositivo em casa não consegue conectar, e a linha `heartbeat ... ->` do rex não mostra `http://192.168.1.20:32400` | O rex anuncia o endereço privado da rede pela qual ele chega à internet; atrás de uma VPN ou de um exit node do Tailscale, essa não é a sua rede de casa. Termine o comando de início do rex ([passo 2](#step-2-install-rex)) com `--announce-url http://192.168.1.20:32400` e reinicie o rex |
| Em casa, app.plex.tv não alcança o rex, e o endereço `lan.` de [O que você deve ver](#what-you-should-see) não responde | Alguns roteadores e filtros de DNS bloqueiam um nome público que aponta para um endereço de casa (proteção contra DNS rebinding). Permita `rex-direct.debridmediamanager.com` aí, como os usuários do Plex permitem `plex.direct` |
| Outra máquina não consegue alcançar o rex no Windows, mesmo com as regras de firewall do passo 2 | Se você alguma vez clicou em **Cancel** quando o Windows perguntou se deveria permitir o rex, o Windows salvou uma regra que bloqueia, e ela tem prioridade sobre as regras de porta. Remova no PowerShell como administrador: <code>Get-NetFirewallApplicationFilter -Program "$HOME\rex\rex.exe" &#124; Get-NetFirewallRule &#124; Where-Object Action -eq Block &#124; Remove-NetFirewallRule</code> (com o rex em outro lugar, use o caminho dele) |
| O rex não aparece nos apps do Plex fora de casa | Não reivindicado, ou o dispositivo não alcança o endereço HTTPS (um endereço só da tailnet precisa do Tailscale nesse dispositivo; [rex-direct sobre IPv6](#rex-direct-over-ipv6) precisa de IPv6 na rede desse dispositivo) |
| O log diz `waiting for a claim` | Faça o [passo 3](#step-3-add-it-to-a-plex-account) |
| O rex sai com `argument --announce-url: '...' is not an http:// or https:// address` | Passe para `--announce-url` só o endereço, como `https://myhost.tailnet.ts.net:443`: sem colchetes, aspas ou link em volta |
| O zurg para quando você sai da sessão | No Linux, rode `sudo loginctl enable-linger "$USER"` (passo 1) |
| O zurg não inicia depois que você editou o `config.yml` | A chave já estava no arquivo e o zurg mostra `mapping key "..." already defined`: apague uma das duas |
