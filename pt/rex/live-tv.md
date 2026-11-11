# TV ao vivo com o rex {#live-tv-with-rex}

rex mostra canais de addons na Live TV do Plex Web e do Plex para Android, com guia e What's On. Escolha um
canal e ele começa a tocar na hora. [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) está pronto
para usar com um servidor de esportes ao vivo. Para uma lista M3U de IPTV e um guia XMLTV, veja [Tutorial: um addon de IPTV](addon-iptv.md).

O que você recebe:

- **Um guia.** Todos os canais com o seu número, com o que está passando agora e o que vem depois.
- **What's On.** O que está passando agora, o que começa mais tarde e os filmes que vêm por aí.
- **Busca.** O nome de um programa encontra ele na Live TV e também nas suas bibliotecas.
- **Assistir.** Escolha um canal e ele toca ao vivo. Um canal não guarda ponto de retomada e nunca é marcado como assistido.
- **Uma grade, como a de uma operadora de TV.** O rex-live-sports começa com a grade dos EUA: cerca de 30 canais de esporte em números que nunca mudam (ESPN é 2, CBS é 7), a programação da ESPN com os jogos que passam neles, e canais de slot (`NFL 1`, `NBA 1` e assim por diante) que listam os jogos do dia antes de começarem e tocam cada um ao vivo. Também há uma grade do Reino Unido e uma da Alemanha.
- **A biblioteca também.** Os canais ficam na sua própria biblioteca **Live Sports**, organizados em uma coleção por grupo.

## Antes de começar {#before-you-start}

| Você precisa | Por quê |
|---|---|
| Um nightly do rex com data 2026.11.02 ou mais recente | A TV ao vivo veio nessa versão |
| rex configurado como em [rex com seu próprio app](any-source.md), com [Conversão de vídeo](any-source.md#converting-video-optional) | O rex converte cada canal enquanto você assiste (uma cópia, barata) |
| Um servidor de esportes ao vivo, na máquina do rex ou na sua rede doméstica | O rex-live-sports pega os canais dele |
| Docker | Roda o live-sports no Passo 2. O [README](https://github.com/yowmamasita/live-sports-public) dele tem as outras formas |
| Python 3.9 ou mais recente, `git`, `ffmpeg` e `ffprobe` na máquina do rex | O rex-live-sports verifica o stream de cada canal com o ffprobe e desenha o pôster dele com o ffmpeg |

## Passo 1. Instale o rex e adicione-o a uma conta do Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Siga [rex com seu próprio app](any-source.md):

1. [Passo 1. Instale o rex](any-source.md#step-1-install-rex), incluindo como descobrir o IP do rex na LAN. Esta página o escreve como `192.168.1.20`: coloque o seu no lugar.
2. [Passo 3. Adicione ao uma conta do Plex](any-source.md#step-3-add-it-to-a-plex-account): registre o rex na conta nova e compartilhe com a sua.
3. [Convertendo vídeo](any-source.md#converting-video-optional).

Pule os passos 2 e 4 ali: o rex-live-sports é o seu app.

## Passo 2. Inicie um servidor de esportes ao vivo {#step-2-start-a-live-sports-server}

**O que faz.** Roda o live-sports, que encontra canais de esportes e verifica a cada poucos minutos quais deles estão no ar.

```bash
docker run -d --name live-sports --restart unless-stopped -p 8765:8765 ghcr.io/yowmamasita/live-sports:latest
```

**O que você deve ver.** `http://192.168.1.20:8765` mostra o painel do live-sports no navegador. A primeira verificação de cada canal leva alguns minutos.

## Passo 3. Instale o rex-live-sports {#step-3-install-rex-live-sports}

**O que faz.** Baixa o rex-live-sports para `~/rex-live-sports` na máquina do rex e o inicia.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

No `config.json`, defina `live_sports_url` como `http://192.168.1.20:8765` e `rex_url` como `http://192.168.1.20:32400`. Depois:

```bash
mkdir -p ~/.config/systemd/user
cp ~/rex-live-sports/rex-live-sports.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-live-sports
journalctl --user -u rex-live-sports -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

No `config.json`, defina `live_sports_url` como `http://192.168.1.20:8765` e `rex_url` como `http://192.168.1.20:32400`. Depois:

```bash
python3 rex_live_sports.py
```

Ele fica rodando enquanto a janela do Terminal estiver aberta.
+++

**O que você deve ver.** Uma linha parecida com:

```
INFO relay on http://127.0.0.1:9983/, live-sports at http://192.168.1.20:8765, rex at http://192.168.1.20:32400
```

Até a primeira checagem do live-sports terminar, ele registra `live-sports lists no channel that plays yet`. Depois, a primeira sincronização verifica o stream de cada canal da grade que o live-sports tem, cerca de um minuto para 30, e registra:

```
INFO pushed 38 of 30 channels, 38 with their Live TV channel: ...
```

São os 30 canais da grade que o live-sports tem, mais os slots com um jogo naquele dia. Ele sincroniza de novo a cada cinco minutos e verifica só os canais que ainda não viu naquele dia.

## Passo 4. Compartilhe a biblioteca e abra a TV ao vivo {#step-4-share-the-library-and-open-live-tv}

The **Live Sports** biblioteca é nova, então ainda não está no compartilhamento de ninguém. Logado na conta nova, adicione ela ao compartilhamento da sua conta e ao de todo mundo em **Manage Library Access** ([Share rex](sharing.md)). Um compartilhamento permite que a conta assista Live TV, a menos que você tenha desativado isso para ela.

Depois, abra um app do Plex como você mesmo:

- **Plex Web**: **Live TV & DVR** fica na barra lateral, com as bibliotecas do rex.
- **Plex for Android**: a aba **Live TV** fica na parte de baixo, com o rex selecionado no topo; **Live TV & DVR** também aparece listada com as bibliotecas do rex.

**O que você deve ver.** **Guide** e **What's On** no topo. O guia lista cada canal pelo número, com o que está passando nele. Escolha um programa e aperte **Watch Now**.

## Canais, números e guias {#channels-numbers-and-guides}

`config.json` define a grade: `lineups/us.json` como copiado, `lineups/uk.json` ou `lineups/de.json` para as redes do Reino Unido ou da Alemanha. Um canal da grade fica no seu número, enquanto o live-sports tem uma cópia dele que toca.

Uma rede dos EUA recebe os jogos da agenda da ESPN (`Chicago Bears at Seattle Seahawks`, a partir do horário de início pela duração habitual do esporte; NFL, futebol americano universitário, NBA, NHL, MLB, as grandes ligas europeias, MLS e F1). A ESPN só nomeia emissoras dos EUA, então as redes do Reino Unido e da Alemanha recebem o guia que o [epgshare01](https://epgshare01.online/) tem para um canal com o mesmo nome. Como todo canal faz em volta dos seus jogos. Um canal que nenhum guia lista mostra o próprio nome em blocos de seis horas.

Os slots vêm depois das redes: `NFL 1` a `NFL 10` em `700.1` a `700.10`, `NBA 1` a `NBA 6` em `701.1` em diante, depois NHL, MLB, Soccer e F1. Cada jogo do dia vai para o primeiro slot livre do seu esporte, então o guia mostra o jogo antes de ele começar. A partir de 15 minutos antes do início até o fim, o slot toca o stream do live-sports que tem o jogo, encontrado pelos nomes das duas equipes. Entre os jogos, o slot não toca nada. Um slot aparece na primeira vez que toca um jogo.

Sem uma grade (`"lineup": ""` no `config.json`), todos os canais dos grupos `Live:` e `Sports` do live-sports entram no lugar, numerados por grupo: `100.1`, `100.2` para o primeiro grupo, `101.1` para o próximo, fora dos números baixos que um sintonizador ou outra fonte usa. Um canal mantém o seu número enquanto o live-sports o listar pelo menos uma vez por semana. Os canais da Pluto TV recebem a própria programação da Pluto TV e ficam de fora a menos que você peça: `"groups": ["Live:", "Sports", "Pluto:"]`. Todas as configurações estão no [README](https://github.com/debridmediamanager/rex-live-sports#settings) do rex-live-sports.

## Atualizando {#updating}

```bash
cd ~/rex-live-sports && git pull && systemctl --user restart rex-live-sports
```

No macOS, pare com Ctrl+C, rode `git pull` em `~/rex-live-sports` e inicie de novo.

## O que ele não consegue fazer {#what-it-cannot-do}

- **Nada grava.** O Plex Web e o Plex para Android não mostram botão de Gravar.
- **Os guias são associados pelo nome.** Um canal pode receber o guia de outro feed da mesma marca, e muitos canais de eventos não têm guia nenhum.
- **Um slot encontra o stream de um jogo pelos times no nome dele.** Um stream com outro nome (`nfl ravens`) não é encontrado, e um jogo que nenhum stream tem aparece no guia mas não toca.
- **O Plex classifica como filme uma programação sem número de episódio, como faz com qualquer guia de TV, então os jogos também aparecem em Filmes em Cartaz (What's On).**
- **A TV ao vivo foi testada no Plex Web e no Plex para Android.** Os outros apps do Plex não foram testados.
- **Qualquer pessoa que consiga acessar o endereço do rex-live-sports pode reproduzir por ele.** Mantenha `listen` em `127.0.0.1`.

Para trazer canais próprios, com um guia que você já tem, veja [Criando addons do rex](addons.md#live-tv).
